import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_database/firebase_database.dart';

import '../models/app_notification.dart';

/// Reads and manages the current user's notification queue in Firebase
/// RTDB, ported from NotificationRepository.kt. Path:
/// /notifications/{myUid}/{notificationId}/.
///
/// WHY RTDB INSTEAD OF FCM — see AppNotification.dart's doc comment and
/// PROGRESS.md's Phase 10 notes: this avoids requiring the Firebase Blaze
/// plan during the free-tier development phase. The tradeoff (no
/// background delivery, especially on iOS) is deliberate and documented.
///
/// STREAM VS CHILDEVENTLISTENER: Kotlin used a ChildEventListener
/// specifically (not ValueEventListener) so historical notifications
/// (predating listener attachment) are suppressed and each notification
/// fires exactly once. Dart's onChildAdded stream gives the same
/// semantics — we replicate the attachedAt-timestamp filtering here too.
class NotificationRepository {
  NotificationRepository(this._myUid)
      : _notifRef = FirebaseDatabase.instance.ref('notifications/$_myUid');

  final String _myUid;
  final DatabaseReference _notifRef;

  StreamSubscription<DatabaseEvent>? _childAddedSubscription;

  // ── Listen ────────────────────────────────────────────────────────────────

  /// Attaches a listener to /notifications/{myUid}/.
  ///
  /// [onNotification] is called for every NEW notification that arrives
  /// after this listener is attached. Notifications whose timestamp
  /// predates attachment are silently deleted (not delivered) — this
  /// prevents stale notifications from re-triggering on every app open,
  /// matching the Kotlin version exactly.
  ///
  /// Safe to call multiple times — detaches any previous listener first.
  void listenForNotifications(
    void Function(AppNotification notification) onNotification,
  ) {
    stopListening();
    final attachedAt = DateTime.now().millisecondsSinceEpoch;

    _childAddedSubscription = _notifRef.onChildAdded.listen(
      (DatabaseEvent event) {
        final value = event.snapshot.value;
        if (value is! Map) return;

        final notification = AppNotification.fromMap(value);

        // Suppress stale notifications from before this session — delete
        // them so they don't accumulate indefinitely.
        if (notification.timestamp < attachedAt) {
          event.snapshot.ref.remove();
          return;
        }

        developer.log(
          'Notification received: type=${notification.type} from=${notification.fromName}',
          name: 'NotificationRepository',
        );
        onNotification(notification);
      },
      onError: (Object error) {
        developer.log(
          'Notification listener cancelled: $error',
          name: 'NotificationRepository',
        );
      },
    );

    developer.log(
      'Notification listener attached for uid=$_myUid',
      name: 'NotificationRepository',
    );
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  /// Deletes a notification from RTDB after it has been acted on.
  /// Fire-and-forget — failures are logged but not propagated.
  void clearNotification(String notificationId) {
    _notifRef.child(notificationId).remove().catchError((Object e) {
      developer.log(
        'Failed to clear notification $notificationId: $e',
        name: 'NotificationRepository',
      );
    });
  }

  /// Clears ALL notifications for this user.
  void clearAllNotifications() {
    _notifRef.remove().catchError((Object e) {
      developer.log(
        'Failed to clear all notifications: $e',
        name: 'NotificationRepository',
      );
    });
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  /// Detaches the Firebase listener. Must be called when the owning
  /// widget/service is disposed.
  void stopListening() {
    if (_childAddedSubscription != null) {
      _childAddedSubscription?.cancel();
      _childAddedSubscription = null;
      developer.log(
        'Notification listener detached for uid=$_myUid',
        name: 'NotificationRepository',
      );
    }
  }
}
