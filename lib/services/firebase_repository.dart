import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';

import '../crypto/room_crypto.dart';
import '../models/chat_message.dart';

/// All Firebase Realtime Database reads/writes for the walkie-talkie
/// feature, ported from FirebaseRepository.kt.
///
/// TWO ROOM MODES — unchanged from Kotlin, via factory constructors:
///
///   Ephemeral room -> FirebaseRepository.forEphemeralRoom()
///     Path: /rooms/{roomCode}/messages/
///     Key:  derived via PBKDF2 from the room code (RoomCrypto.forRoomCode)
///
///   Direct room -> FirebaseRepository.forDirectRoom()
///     Path: /directRooms/{roomId}/messages/
///     Key:  pre-existing 256-bit random key (RoomCrypto.forRawKey)
///
/// ENCRYPTION: every originalText/translatedText is AES-256-GCM encrypted
/// before writing, decrypted immediately after reading. Firebase stores
/// only ciphertext. Messages that fail to decrypt are silently dropped
/// and logged — matches the Kotlin version exactly.
///
/// STREAM VS CALLBACK: Dart's firebase_database uses Streams
/// (ref.onChildAdded) instead of Kotlin's ChildEventListener callback
/// interface, but the semantics are the same — we still filter to only
/// NEW messages that arrive after the listener attaches, and only from
/// other senders.
class FirebaseRepository {
  /// Private constructor using initializing formals (this._fieldName) for
  /// the two simple field assignments, per Dart lint convention. Note that
  /// even though the fields are private (_myDeviceId, _crypto), Dart
  /// exposes the call-site parameter names WITHOUT the leading underscore
  /// (myDeviceId, crypto) — that's just how initializing formals work,
  /// and is what the factory constructors below actually call with.
  FirebaseRepository._({
    required this._myDeviceId,
    required this._crypto,
    required String messagesPath,
  }) : _messagesRef = FirebaseDatabase.instance.ref(messagesPath);

  final String _myDeviceId;
  final RoomCrypto _crypto;
  final DatabaseReference _messagesRef;

  StreamSubscription<DatabaseEvent>? _childAddedSubscription;

  // ── Factory constructors ─────────────────────────────────────────────────

  /// Ephemeral room (room-code flow). Messages stored at
  /// /rooms/{roomCode}/messages/. Key derived via PBKDF2 from [roomCode].
  factory FirebaseRepository.forEphemeralRoom({
    required String roomCode,
    required String myDeviceId,
  }) {
    return FirebaseRepository._(
      myDeviceId: myDeviceId,
      crypto: RoomCrypto.forRoomCode(roomCode),
      messagesPath: 'rooms/$roomCode/messages',
    );
  }

  /// Direct (contact-to-contact) room. Messages stored at
  /// /directRooms/{roomId}/messages/. [rawKeyBytes] must be the 32-byte
  /// AES key decoded from DirectRoom.encryptionKey via
  /// DirectRoom.decodeEncryptionKey() (which already returns a Uint8List).
  factory FirebaseRepository.forDirectRoom({
    required String roomId,
    required Uint8List rawKeyBytes,
    required String myDeviceId,
  }) {
    return FirebaseRepository._(
      myDeviceId: myDeviceId,
      crypto: RoomCrypto.forRawKey(rawKeyBytes),
      messagesPath: 'directRooms/$roomId/messages',
    );
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  /// Encrypts the text fields of [message] and writes it to Firebase under
  /// its own [ChatMessage.id] key.
  ///
  /// [onSuccess] is called when the write is confirmed.
  /// [onFailure] is called with a human-readable reason on any error.
  Future<void> sendMessage({
    required ChatMessage message,
    required void Function() onSuccess,
    required void Function(String reason) onFailure,
  }) async {
    try {
      final encryptedOriginal = await _crypto.encrypt(message.originalText);
      final encryptedTranslated = await _crypto.encrypt(message.translatedText);

      final encryptedMessage = message.copyWith(
        originalText: encryptedOriginal,
        translatedText: encryptedTranslated,
      );

      await _messagesRef.child(encryptedMessage.id).set(encryptedMessage.toMap());
      onSuccess();
    } catch (e) {
      onFailure(e.toString());
    }
  }

  // ── Listen ────────────────────────────────────────────────────────────────

  /// Attaches a listener to the messages node.
  ///
  /// Delivers only NEW messages from other senders (senderId != myDeviceId)
  /// that arrive after this listener is attached. Own messages and
  /// historical messages are suppressed — matches the Kotlin version's
  /// attachedAt-timestamp filtering.
  ///
  /// Messages that cannot be decrypted are silently dropped (logged via
  /// dart:developer, visible in `flutter run` / DevTools logs).
  ///
  /// Safe to call multiple times — detaches any previous listener first.
  /// Call [stopListening] when done (e.g. in a widget's dispose()) to
  /// avoid leaks.
  void listenForMessages(void Function(ChatMessage message) onMessage) {
    stopListening();

    final attachedAt = DateTime.now().millisecondsSinceEpoch;

    _childAddedSubscription = _messagesRef.onChildAdded.listen(
      (DatabaseEvent event) async {
        final rawValue = event.snapshot.value;
        if (rawValue is! Map) return;

        final raw = ChatMessage.fromMap(rawValue);

        if (raw.senderId == _myDeviceId) return;
        if (raw.timestampMs < attachedAt) return;

        final decryptedOriginal = await _crypto.decrypt(raw.originalText);
        final decryptedTranslation = await _crypto.decrypt(raw.translatedText);

        if (decryptedOriginal == null || decryptedTranslation == null) {
          developer.log(
            'Dropped message ${raw.id}: decryption failed '
            '(wrong key or corrupted data)',
            name: 'FirebaseRepository',
          );
          return;
        }

        onMessage(
          raw.copyWith(
            originalText: decryptedOriginal,
            translatedText: decryptedTranslation,
            isIncoming: true,
          ),
        );
      },
      onError: (Object error) {
        developer.log(
          'Message listener error: $error',
          name: 'FirebaseRepository',
        );
      },
    );
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  void stopListening() {
    _childAddedSubscription?.cancel();
    _childAddedSubscription = null;
  }
}
