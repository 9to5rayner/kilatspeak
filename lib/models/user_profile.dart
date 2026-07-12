/// A user's public profile, ported from UserProfile.kt.
/// Stored at /users/{uid}/, written on every successful sign-in.
class UserProfile {
  const UserProfile({
    this.uid = '',
    this.displayName = '',
    this.email = '',
  });

  final String uid;
  final String displayName;
  final String email;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
      };

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }

  /// Encodes a Gmail address into a string safe for use as a Firebase RTDB
  /// key. Illegal RTDB key characters: . $ # [ ] /
  ///   '.' -> ','
  ///   '@' -> '_at_'
  /// Unchanged from UserProfile.kt's encodeEmail().
  static String encodeEmail(String email) {
    return email.toLowerCase().replaceAll('.', ',').replaceAll('@', '_at_');
  }

  /// Reverses encodeEmail().
  static String decodeEmail(String encoded) {
    return encoded.replaceAll('_at_', '@').replaceAll(',', '.');
  }
}
