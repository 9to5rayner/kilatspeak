import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// A persistent direct-chat room between two confirmed contacts, ported
/// from DirectRoom.kt. Stored at /directRooms/{roomId}/.
///
/// ROOM ID DERIVATION — unchanged from Kotlin:
///   hex( SHA-256( sorted(uid1) + ":" + sorted(uid2) ) )
///   Deterministic, order-invariant, RTDB-key-safe, collision-resistant.
///
/// ENCRYPTION KEY — unchanged from Kotlin: a pre-generated 256-bit random
/// key (not PBKDF2-derived, since it's already full-entropy random),
/// stored as a Base64 string. Generated once by the accepting user at
/// contact-accept time.
class DirectRoom {
  const DirectRoom({
    this.roomId = '',
    this.participant1 = '',
    this.participant2 = '',
    this.encryptionKey = '',
    this.createdAt = 0,
  });

  final String roomId;
  final String participant1; // uid of the user who sent the request
  final String participant2; // uid of the user who accepted the request
  final String encryptionKey; // Base64(32 random bytes) — AES-256 raw key
  final int createdAt;

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'participant1': participant1,
        'participant2': participant2,
        'encryptionKey': encryptionKey,
        'createdAt': createdAt,
      };

  factory DirectRoom.fromMap(Map<dynamic, dynamic> map) {
    return DirectRoom(
      roomId: map['roomId'] as String? ?? '',
      participant1: map['participant1'] as String? ?? '',
      participant2: map['participant2'] as String? ?? '',
      encryptionKey: map['encryptionKey'] as String? ?? '',
      createdAt: map['createdAt'] as int? ?? 0,
    );
  }

  /// Computes the deterministic room ID for the pair (uid1, uid2).
  /// Order-invariant: computeRoomId(a, b) == computeRoomId(b, a).
  /// Returns a 64-character lowercase hex string.
  static String computeRoomId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    final payload = '${sorted[0]}:${sorted[1]}';
    final digest = sha256.convert(utf8.encode(payload));
    return digest.toString(); // package:crypto's Digest.toString() is lowercase hex
  }

  /// Generates a cryptographically random 256-bit AES key, Base64-encoded.
  /// Random.secure() is Dart's equivalent of Android's SecureRandom —
  /// both draw from the OS's cryptographically secure RNG.
  static String generateEncryptionKey() {
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    return base64.encode(keyBytes);
  }

  /// Decodes a Base64-encoded encryptionKey string back into raw bytes,
  /// for use with RoomCrypto (Phase 4b).
  static Uint8List decodeEncryptionKey(String base64Key) {
    return base64.decode(base64Key);
  }
}
