/// An in-app notification delivered via Firebase RTDB, ported from
/// AppNotification.kt. Stored at /notifications/{recipientUid}/{id}/.
///
/// See AppNotification.kt's doc comment for the full rationale on why RTDB
/// is used instead of FCM (avoiding the Blaze plan requirement) — that
/// reasoning still applies to the Flutter port; see PROGRESS.md's notes on
/// the Phase 10 foreground-only notification strategy.
class AppNotification {
  const AppNotification({
    this.id = '',
    this.type = '',
    this.fromUid = '',
    this.fromName = '',
    this.fromEmail = '',
    this.roomId = '',
    this.timestamp = 0,
  });

  static const String typeContactRequest = 'contact_request';
  static const String typeContactAccepted = 'contact_accepted';
  static const String typeContactDeclined = 'contact_declined';
  static const String typeChatInvite = 'chat_invite';

  final String id;
  final String type;
  final String fromUid;
  final String fromName;
  final String fromEmail; // typeContactRequest only; '' otherwise
  final String roomId; // typeChatInvite only; '' otherwise
  final int timestamp;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'fromUid': fromUid,
        'fromName': fromName,
        'fromEmail': fromEmail,
        'roomId': roomId,
        'timestamp': timestamp,
      };

  factory AppNotification.fromMap(Map<dynamic, dynamic> map) {
    return AppNotification(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? '',
      fromUid: map['fromUid'] as String? ?? '',
      fromName: map['fromName'] as String? ?? '',
      fromEmail: map['fromEmail'] as String? ?? '',
      roomId: map['roomId'] as String? ?? '',
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }
}
