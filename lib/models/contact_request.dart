/// A contact request between two users, ported from ContactRequest.kt.
/// Stored at /contactRequests/{recipientUid}/{senderUid}/.
///
/// State machine (unchanged from Kotlin):
///   pending  -> recipient hasn't responded
///   accepted -> recipient accepted; both sides get a ContactEntry
///   declined -> recipient declined; sender may re-send (node overwritten)
class ContactRequest {
  const ContactRequest({
    this.senderUid = '',
    this.senderName = '',
    this.senderEmail = '',
    this.recipientUid = '',
    this.recipientName = '',
    this.recipientEmail = '',
    this.status = statusPending,
    this.timestamp = 0,
  });

  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusDeclined = 'declined';

  final String senderUid;
  final String senderName;
  final String senderEmail;
  final String recipientUid;
  final String recipientName;
  final String recipientEmail;
  final String status;
  final int timestamp;

  Map<String, dynamic> toMap() => {
        'senderUid': senderUid,
        'senderName': senderName,
        'senderEmail': senderEmail,
        'recipientUid': recipientUid,
        'recipientName': recipientName,
        'recipientEmail': recipientEmail,
        'status': status,
        'timestamp': timestamp,
      };

  factory ContactRequest.fromMap(Map<dynamic, dynamic> map) {
    return ContactRequest(
      senderUid: map['senderUid'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      senderEmail: map['senderEmail'] as String? ?? '',
      recipientUid: map['recipientUid'] as String? ?? '',
      recipientName: map['recipientName'] as String? ?? '',
      recipientEmail: map['recipientEmail'] as String? ?? '',
      status: map['status'] as String? ?? statusPending,
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }
}

/// The sender's local record of a request they sent, stored at
/// /users/{senderUid}/sentRequests/{recipientUid}/. Ported from the
/// companion SentRequest class in ContactRequest.kt — kept in the same
/// file here too, matching the original's grouping.
class SentRequest {
  const SentRequest({
    this.recipientUid = '',
    this.recipientName = '',
    this.recipientEmail = '',
    this.timestamp = 0,
    this.status = ContactRequest.statusPending,
  });

  final String recipientUid;
  final String recipientName;
  final String recipientEmail;
  final int timestamp;
  final String status;

  Map<String, dynamic> toMap() => {
        'recipientUid': recipientUid,
        'recipientName': recipientName,
        'recipientEmail': recipientEmail,
        'timestamp': timestamp,
        'status': status,
      };

  factory SentRequest.fromMap(Map<dynamic, dynamic> map) {
    return SentRequest(
      recipientUid: map['recipientUid'] as String? ?? '',
      recipientName: map['recipientName'] as String? ?? '',
      recipientEmail: map['recipientEmail'] as String? ?? '',
      timestamp: map['timestamp'] as int? ?? 0,
      status: map['status'] as String? ?? ContactRequest.statusPending,
    );
  }
}
