import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_database/firebase_database.dart';

import '../models/app_notification.dart';
import '../models/contact_entry.dart';
import '../models/contact_request.dart';
import '../models/direct_room.dart';
import '../models/user_profile.dart';

/// All Firebase Realtime Database reads/writes for the contacts feature,
/// ported from ContactRepository.kt.
///
/// DATABASE PATHS — unchanged from Kotlin:
///   /users/{uid}/                          — public profile (read-only here)
///   /usersByEmail/{encodedEmail}/uid       — email -> uid index (read-only)
///   /users/{myUid}/contacts/{contactUid}/ — my accepted contacts (read/write)
///   /users/{myUid}/sentRequests/{uid}/    — requests I sent (read/write)
///   /contactRequests/{myUid}/{senderUid}/ — requests sent TO me (read/write)
///   /directRooms/{roomId}/               — shared room + encryption key (read/write)
///   /notifications/{uid}/{id}/           — outbound notifications (write-only here)
///
/// SECURITY BOUNDARY: every write here targets either the caller's own
/// node or a shared node the caller is a participant of. No write ever
/// touches another user's /contacts/ or /sentRequests/ node. RTDB security
/// rules (ported separately, not part of the Dart codebase) enforce this
/// server-side.
///
/// FUTURES VS SUSPEND FUNCTIONS: Kotlin's suspend functions bridged via
/// suspendCancellableCoroutine become plain async/await Futures in Dart —
/// there's no equivalent bridging step needed since Dart's Future/async
/// model maps directly onto what the Kotlin code was doing.
class ContactRepository {
  ContactRepository({
    required this._myUid,
    required this._myName,
    required this._myEmail,
  }) : _db = FirebaseDatabase.instance;

  final String _myUid;
  final String _myName;
  final String _myEmail;
  final FirebaseDatabase _db;

  StreamSubscription<DatabaseEvent>? _contactsSubscription;
  StreamSubscription<DatabaseEvent>? _incomingRequestsSubscription;
  StreamSubscription<DatabaseEvent>? _sentRequestsSubscription;

  // ── Email lookup ──────────────────────────────────────────────────────────

  /// Looks up a [UserProfile] by Gmail address. Returns null if no user
  /// with that email has ever signed into the app.
  Future<UserProfile?> lookupUserByEmail(String email) async {
    try {
      final encodedEmail = UserProfile.encodeEmail(email.trim());
      final uidSnapshot =
          await _db.ref('usersByEmail/$encodedEmail/uid').get();

      final uid = uidSnapshot.value as String?;
      if (uid == null || uid.isEmpty) return null;

      final profileSnapshot = await _db.ref('users/$uid').get();
      if (!profileSnapshot.exists) return null;

      final value = profileSnapshot.value;
      if (value is! Map) return null;
      return UserProfile.fromMap(value);
    } catch (e) {
      developer.log('Email lookup failed: $e', name: 'ContactRepository');
      return null;
    }
  }

  // ── Direct profile lookup by uid ─────────────────────────────────────────

  /// Fetches a [UserProfile] directly by uid — used when only a uid is
  /// known (e.g. from an AppNotification's fromUid) and there's no email
  /// available to resolve through lookupUserByEmail's index.
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final snapshot = await _db.ref('users/$uid').get();
      if (!snapshot.exists) return null;
      final value = snapshot.value;
      if (value is! Map) return null;
      return UserProfile.fromMap(value);
    } catch (e) {
      developer.log('Failed to fetch profile for uid $uid: $e', name: 'ContactRepository');
      return null;
    }
  }

  // ── Send contact request ──────────────────────────────────────────────────

  /// Sends a contact request to [toProfile].
  ///
  /// Guards, checked in order (first failure returns immediately):
  ///   1. Cannot add yourself.
  ///   2. Already an accepted contact.
  ///   3. A pending request already exists (a previously declined request
  ///      CAN be re-sent — the node is overwritten).
  ///
  /// Returns a Result-like pair: null on success, or an error message
  /// string on failure. (Dart has no built-in `Result` generic type like
  /// Kotlin's stdlib — using a nullable error-message return keeps this
  /// simple without pulling in a functional-programming package for one
  /// method.)
  Future<String?> sendContactRequest(UserProfile toProfile) async {
    // Guard 1 — self-add
    if (toProfile.uid == _myUid) {
      return 'You cannot add yourself as a contact.';
    }

    try {
      // Guard 2 — already a contact
      final contactSnapshot =
          await _db.ref('users/$_myUid/contacts/${toProfile.uid}').get();
      if (contactSnapshot.exists) {
        return '${toProfile.displayName} is already in your contacts.';
      }

      // Guard 3 — pending request already exists
      final existingReqSnapshot =
          await _db.ref('contactRequests/${toProfile.uid}/$_myUid').get();
      if (existingReqSnapshot.exists) {
        final existingValue = existingReqSnapshot.value;
        if (existingValue is Map) {
          final existing = ContactRequest.fromMap(existingValue);
          if (existing.status == ContactRequest.statusPending) {
            return 'You already have a pending request to ${toProfile.displayName}.';
          }
        }
      }

      // All guards passed — write the request.
      final now = DateTime.now().millisecondsSinceEpoch;
      final request = ContactRequest(
        senderUid: _myUid,
        senderName: _myName,
        senderEmail: _myEmail,
        recipientUid: toProfile.uid,
        recipientName: toProfile.displayName,
        recipientEmail: toProfile.email,
        status: ContactRequest.statusPending,
        timestamp: now,
      );
      final sentRecord = SentRequest(
        recipientUid: toProfile.uid,
        recipientName: toProfile.displayName,
        recipientEmail: toProfile.email,
        timestamp: now,
        status: ContactRequest.statusPending,
      );
      final notification = AppNotification(
        id: _generateId(),
        type: AppNotification.typeContactRequest,
        fromUid: _myUid,
        fromName: _myName,
        fromEmail: _myEmail,
        timestamp: now,
      );

      // Write 1: the request under the recipient's node
      await _db
          .ref('contactRequests/${toProfile.uid}/$_myUid')
          .set(request.toMap());

      // Write 2: sender's own tracking index — non-critical, failure here
      // doesn't invalidate the request itself (matches Kotlin behavior).
      try {
        await _db
            .ref('users/$_myUid/sentRequests/${toProfile.uid}')
            .set(sentRecord.toMap());
      } catch (e) {
        developer.log('sentRequests write failed: $e', name: 'ContactRepository');
      }

      // Write 3: notification to recipient — fire-and-forget.
      unawaited(
        _db
            .ref('notifications/${toProfile.uid}/${notification.id}')
            .set(notification.toMap()),
      );

      return null; // success
    } catch (e) {
      return 'Failed to send request: $e';
    }
  }

  // ── Accept contact request ────────────────────────────────────────────────

  /// Accepts an incoming [ContactRequest]. Returns null on success, or an
  /// error message on failure.
  ///
  /// Sequence (from the acceptor's perspective — "I am B"):
  ///   1. Update /contactRequests/{myUid}/{senderUid}/status -> "accepted"
  ///   2. Write /users/{myUid}/contacts/{senderUid}/ — B's contact entry for A
  ///   3. Generate roomId + encryptionKey; write /directRooms/{roomId}/
  ///   4. Send TYPE_CONTACT_ACCEPTED notification to the original sender (A)
  ///
  /// A's own contact entry is written by A's app on receiving the
  /// notification — see [writeAcceptedContactEntry].
  Future<String?> acceptContactRequest(ContactRequest request) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final roomId = DirectRoom.computeRoomId(_myUid, request.senderUid);
      final encKey = DirectRoom.generateEncryptionKey();

      final directRoom = DirectRoom(
        roomId: roomId,
        participant1: request.senderUid,
        participant2: _myUid,
        encryptionKey: encKey,
        createdAt: now,
      );
      final myContactEntry = ContactEntry(
        uid: request.senderUid,
        displayName: request.senderName,
        email: request.senderEmail,
        addedAt: now,
      );
      final notification = AppNotification(
        id: _generateId(),
        type: AppNotification.typeContactAccepted,
        fromUid: _myUid,
        fromName: _myName,
        timestamp: now,
      );

      // Step 1: mark request as accepted
      await _db
          .ref('contactRequests/$_myUid/${request.senderUid}/status')
          .set(ContactRequest.statusAccepted);

      // Step 2: write MY contact entry for the sender
      await _db
          .ref('users/$_myUid/contacts/${request.senderUid}')
          .set(myContactEntry.toMap());

      // Step 3: write the shared direct room + key
      await _db.ref('directRooms/$roomId').set(directRoom.toMap());

      // Step 4: notify the original sender — fire-and-forget.
      unawaited(
        _db
            .ref('notifications/${request.senderUid}/${notification.id}')
            .set(notification.toMap()),
      );

      return null; // success
    } catch (e) {
      return 'Failed to accept request: $e';
    }
  }

  // ── Decline contact request ───────────────────────────────────────────────

  /// Declines an incoming [ContactRequest]. The request node is NOT
  /// deleted — it stays "declined" so [sendContactRequest] can detect a
  /// prior decline and allow a re-send.
  Future<String?> declineContactRequest(ContactRequest request) async {
    try {
      final notification = AppNotification(
        id: _generateId(),
        type: AppNotification.typeContactDeclined,
        fromUid: _myUid,
        fromName: _myName,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await _db
          .ref('contactRequests/$_myUid/${request.senderUid}/status')
          .set(ContactRequest.statusDeclined);

      unawaited(
        _db
            .ref('notifications/${request.senderUid}/${notification.id}')
            .set(notification.toMap()),
      );

      return null; // success
    } catch (e) {
      return 'Failed to decline request: $e';
    }
  }

  // ── Get direct room ───────────────────────────────────────────────────────

  /// Fetches the [DirectRoom] for a direct chat with [contactUid]. The
  /// room must already exist (created by [acceptContactRequest]). Returns
  /// null if it doesn't exist or the read fails.
  Future<DirectRoom?> getDirectRoom(String contactUid) async {
    try {
      final roomId = DirectRoom.computeRoomId(_myUid, contactUid);
      final snapshot = await _db.ref('directRooms/$roomId').get();
      if (!snapshot.exists) return null;
      final value = snapshot.value;
      if (value is! Map) return null;
      return DirectRoom.fromMap(value);
    } catch (e) {
      developer.log('Failed to fetch DirectRoom for $contactUid: $e', name: 'ContactRepository');
      return null;
    }
  }

  // ── Write accepted contact (called by A when notification arrives) ─────────

  /// Writes A's own contact entry for B after receiving a
  /// TYPE_CONTACT_ACCEPTED notification. Fire-and-forget — failures are
  /// logged but not thrown, since the notification listener calling this
  /// (Phase 10) can't usefully propagate exceptions.
  void writeAcceptedContactEntry({
    required String contactUid,
    required String contactName,
    required String contactEmail,
  }) {
    final entry = ContactEntry(
      uid: contactUid,
      displayName: contactName,
      email: contactEmail,
      addedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _db.ref('users/$_myUid/contacts/$contactUid').set(entry.toMap()).catchError(
      (Object e) {
        developer.log(
          'Failed to write accepted contact entry for $contactUid: $e',
          name: 'ContactRepository',
        );
      },
    );
  }

  /// Updates the status of a sent request in the sender's own index.
  void updateSentRequestStatus(String recipientUid, String newStatus) {
    _db
        .ref('users/$_myUid/sentRequests/$recipientUid/status')
        .set(newStatus)
        .catchError((Object e) {
      developer.log(
        'Failed to update sentRequest status for $recipientUid: $e',
        name: 'ContactRepository',
      );
    });
  }

  /// Writes a TYPE_CHAT_INVITE notification to the contact's notification
  /// queue. Fire-and-forget — the chat is launched on the sender's side
  /// regardless of whether this write succeeds.
  void sendChatInviteNotification({
    required String contactUid,
    required String roomId,
  }) {
    final notification = AppNotification(
      id: _generateId(),
      type: AppNotification.typeChatInvite,
      fromUid: _myUid,
      fromName: _myName,
      fromEmail: '',
      roomId: roomId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _db
        .ref('notifications/$contactUid/${notification.id}')
        .set(notification.toMap())
        .catchError((Object e) {
      developer.log(
        'Failed to send chat invite notification to $contactUid: $e',
        name: 'ContactRepository',
      );
    });
  }

  // ── Realtime listeners ────────────────────────────────────────────────────

  /// Listens to /users/{myUid}/contacts/ and delivers a full updated list
  /// every time a child is added, changed, or removed. Delivers the
  /// current snapshot immediately on attach, then on every subsequent
  /// change. Sorted by displayName. Call [stopListening] to detach.
  void listenToMyContacts(void Function(List<ContactEntry> contacts) onUpdate) {
    final ref = _db.ref('users/$_myUid/contacts');
    _contactsSubscription = ref.onValue.listen(
      (DatabaseEvent event) {
        final contacts = <ContactEntry>[];
        final value = event.snapshot.value;
        if (value is Map) {
          for (final child in value.values) {
            if (child is Map) {
              try {
                contacts.add(ContactEntry.fromMap(child));
              } catch (e) {
                developer.log('Failed to parse ContactEntry: $e', name: 'ContactRepository');
              }
            }
          }
        }
        contacts.sort(
          (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
        );
        onUpdate(contacts);
      },
      onError: (Object error) {
        developer.log('contacts listener cancelled: $error', name: 'ContactRepository');
      },
    );
  }

  /// Listens to /contactRequests/{myUid}/ for incoming requests
  /// (pending only — accepted/declined entries are filtered out).
  void listenToIncomingRequests(
    void Function(List<ContactRequest> requests) onUpdate,
  ) {
    final ref = _db.ref('contactRequests/$_myUid');
    _incomingRequestsSubscription = ref.onValue.listen(
      (DatabaseEvent event) {
        final requests = <ContactRequest>[];
        final value = event.snapshot.value;
        if (value is Map) {
          for (final child in value.values) {
            if (child is Map) {
              try {
                final req = ContactRequest.fromMap(child);
                if (req.status == ContactRequest.statusPending) {
                  requests.add(req);
                }
              } catch (e) {
                developer.log('Failed to parse ContactRequest: $e', name: 'ContactRepository');
              }
            }
          }
        }
        requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        onUpdate(requests);
      },
      onError: (Object error) {
        developer.log('incomingRequests listener cancelled: $error', name: 'ContactRepository');
      },
    );
  }

  /// Listens to /users/{myUid}/sentRequests/ for the sender's own pending
  /// requests (status == pending only).
  void listenToSentRequests(void Function(List<SentRequest> sent) onUpdate) {
    final ref = _db.ref('users/$_myUid/sentRequests');
    _sentRequestsSubscription = ref.onValue.listen(
      (DatabaseEvent event) {
        final sent = <SentRequest>[];
        final value = event.snapshot.value;
        if (value is Map) {
          for (final child in value.values) {
            if (child is Map) {
              try {
                final req = SentRequest.fromMap(child);
                if (req.status == ContactRequest.statusPending) {
                  sent.add(req);
                }
              } catch (e) {
                developer.log('Failed to parse SentRequest: $e', name: 'ContactRepository');
              }
            }
          }
        }
        sent.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        onUpdate(sent);
      },
      onError: (Object error) {
        developer.log('sentRequests listener cancelled: $error', name: 'ContactRepository');
      },
    );
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  /// Detaches all active Firebase listeners. Must be called when the
  /// owning widget is disposed.
  void stopListening() {
    _contactsSubscription?.cancel();
    _contactsSubscription = null;
    _incomingRequestsSubscription?.cancel();
    _incomingRequestsSubscription = null;
    _sentRequestsSubscription?.cancel();
    _sentRequestsSubscription = null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Generates a unique ID for notifications. Kotlin used
  /// UUID.randomUUID().toString() — Dart's firebase_database offers
  /// ref.push().key for a similarly-unique, sortable key. We use that
  /// here rather than pulling in a separate uuid package, since it's
  /// already available via the database reference itself.
  String _generateId() {
    return _db.ref().push().key ?? DateTime.now().microsecondsSinceEpoch.toString();
  }
}
