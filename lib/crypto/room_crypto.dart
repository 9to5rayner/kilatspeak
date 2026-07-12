import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Symmetric encryption for room messages, ported from RoomCrypto.kt.
///
/// TWO CONSTRUCTION MODES — unchanged from Kotlin:
///
/// 1. RoomCrypto.forRoomCode(roomCode) — Ephemeral rooms.
///    The room code is used as the password input to PBKDF2-HMAC-SHA256
///    (100,000 iterations), producing a 256-bit AES key. Derivation is
///    lazy: it only runs on the first call to encrypt()/decrypt(), and the
///    result is cached (via a memoized Future) for all subsequent calls.
///
/// 2. RoomCrypto.forRawKey(rawKeyBytes) — Direct (contact-to-contact) rooms.
///    A pre-existing 256-bit random key (from
///    DirectRoom.generateEncryptionKey()) is used directly — no PBKDF2,
///    since the key is already full-entropy random.
///
/// COMPATIBILITY NOTE: PBKDF2 password handling here uses standard UTF-8
/// encoding of the room code string. This is NOT guaranteed to produce
/// byte-identical output to the old Kotlin app's javax.crypto.spec.PBEKeySpec
/// char[] handling (JVM-provider-specific). Since KilatSpeak is a fresh
/// rewrite, this port is self-consistent within Dart only — it does not
/// aim to decrypt messages that were encrypted by the old Kotlin app.
///
/// WIRE FORMAT — unchanged from Kotlin:
///   Base64( IV[12 bytes] || GCM-ciphertext[n bytes] || GCM-tag[16 bytes] )
///
/// Uses AesGcm.with256bits() from package:cryptography, which defaults to
/// a 12-byte (96-bit) nonce and 16-byte (128-bit) MAC — matching the
/// Kotlin version's AES/GCM/NoPadding with GCM_TAG_BITS=128 exactly.
class RoomCrypto {
  RoomCrypto._(this._secretKeyFuture);

  /// Ephemeral room constructor — key derivation is deferred until the
  /// Future is first awaited (inside encrypt()/decrypt()), and Dart's
  /// Future memoization means _deriveKey() only actually runs once even
  /// if multiple calls happen concurrently.
  factory RoomCrypto.forRoomCode(String roomCode) {
    return RoomCrypto._(_deriveKeyFromRoomCode(roomCode));
  }

  /// Direct room constructor — wraps a pre-existing raw key immediately,
  /// no derivation needed.
  factory RoomCrypto.forRawKey(Uint8List rawKeyBytes) {
    final secretKey = SecretKeyData(rawKeyBytes);
    return RoomCrypto._(Future.value(secretKey));
  }

  final Future<SecretKeyData> _secretKeyFuture;

  static final AesGcm _algorithm = AesGcm.with256bits();

  static const int _pbkdf2Iterations = 100000;
  static const int _keyLengthBits = 256;

  /// Same salt constant as the Kotlin app's RoomCrypto.SALT — kept
  /// unchanged (not renamed to reference the new package name) since it's
  /// an internal cryptographic parameter, never shown to users, and
  /// changing it would just be churn with no benefit.
  static final Uint8List _salt =
      Uint8List.fromList(utf8.encode('com.example.groqtranscriber.roomkey'));

  static Future<SecretKeyData> _deriveKeyFromRoomCode(String roomCode) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: _keyLengthBits,
    );
    final normalizedPassword = roomCode.trim().toUpperCase();
    final newSecretKey = await pbkdf2.deriveKeyFromPassword(
      password: normalizedPassword,
      nonce: _salt,
    );
    return await newSecretKey.extract();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Encrypts [plaintext] and returns a Base64-encoded token safe for
  /// storage in Firebase. Never returns null.
  Future<String> encrypt(String plaintext) async {
    final secretKey = await _secretKeyFuture;
    final nonce = _algorithm.newNonce();

    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );

    // concatenation() returns nonce + cipherText + mac — exactly the
    // IV || ciphertext || tag wire format the Kotlin version used.
    return base64.encode(secretBox.concatenation());
  }

  /// Decrypts a token produced by [encrypt].
  /// Returns the original plaintext, or **null** on any failure:
  ///   - Wrong key (ephemeral: wrong room code; direct: key mismatch)
  ///   - Tampered ciphertext (GCM authentication tag mismatch)
  ///   - Malformed Base64
  ///   - Truncated payload
  Future<String?> decrypt(String token) async {
    try {
      final payload = base64.decode(token);
      if (payload.length <= _algorithm.nonceLength) return null;

      final secretBox = SecretBox.fromConcatenation(
        payload,
        nonceLength: _algorithm.nonceLength,
        macLength: _algorithm.macAlgorithm.macLength,
      );

      final secretKey = await _secretKeyFuture;
      final clearTextBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      return utf8.decode(clearTextBytes);
    } catch (_) {
      // Covers SecretBoxAuthenticationError (tampered/wrong key),
      // FormatException (malformed base64), and any other failure —
      // matches the Kotlin version's blanket try/catch returning null.
      return null;
    }
  }
}
