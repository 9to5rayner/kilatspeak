/// A confirmed contact relationship, stored at /users/{myUid}/contacts/{contactUid}/.
/// Ported directly from ContactEntry.kt — see that file's doc comment for
/// the security rationale (each user only ever writes their own /contacts/
/// node).
class ContactEntry {
  const ContactEntry({
    this.uid = '',
    this.displayName = '',
    this.email = '',
    this.addedAt = 0,
  });

  final String uid;
  final String displayName;
  final String email;
  final int addedAt;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'addedAt': addedAt,
      };

  factory ContactEntry.fromMap(Map<dynamic, dynamic> map) {
    return ContactEntry(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      addedAt: map['addedAt'] as int? ?? 0,
    );
  }
}
