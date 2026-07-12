import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilatspeak/crypto/room_crypto.dart';

void main() {
  group('RoomCrypto.forRoomCode (ephemeral rooms)', () {
    test('encrypt then decrypt returns the original plaintext', () async {
      final crypto = RoomCrypto.forRoomCode('AB3KZ');
      const original = 'Hello, this is a test message!';

      final encrypted = await crypto.encrypt(original);
      final decrypted = await crypto.decrypt(encrypted);

      expect(decrypted, equals(original));
    });

    test('same room code produces a crypto instance that can decrypt its own output repeatedly', () async {
      final crypto = RoomCrypto.forRoomCode('ROOM1');
      const message1 = 'First message';
      const message2 = 'Second message';

      final enc1 = await crypto.encrypt(message1);
      final enc2 = await crypto.encrypt(message2);

      expect(await crypto.decrypt(enc1), equals(message1));
      expect(await crypto.decrypt(enc2), equals(message2));
    });

    test('two instances with the same room code can decrypt each other\'s output', () async {
      // Simulates two devices in the same ephemeral room — this is the
      // real-world scenario RoomCrypto exists for.
      final deviceA = RoomCrypto.forRoomCode('SHARED');
      final deviceB = RoomCrypto.forRoomCode('SHARED');

      const message = 'Message from device A';
      final encrypted = await deviceA.encrypt(message);
      final decrypted = await deviceB.decrypt(encrypted);

      expect(decrypted, equals(message));
    });

    test('room code is case-insensitive and trimmed, matching Kotlin behavior', () async {
      final cryptoLower = RoomCrypto.forRoomCode('ab3kz');
      final cryptoUpper = RoomCrypto.forRoomCode('AB3KZ');
      final cryptoPadded = RoomCrypto.forRoomCode('  AB3KZ  ');

      const message = 'Case sensitivity test';
      final encrypted = await cryptoLower.encrypt(message);

      expect(await cryptoUpper.decrypt(encrypted), equals(message));
      expect(await cryptoPadded.decrypt(encrypted), equals(message));
    });

    test('wrong room code fails to decrypt (returns null, not garbage)', () async {
      final correctCrypto = RoomCrypto.forRoomCode('CORRECT');
      final wrongCrypto = RoomCrypto.forRoomCode('WRONGCODE');

      final encrypted = await correctCrypto.encrypt('Secret message');
      final decrypted = await wrongCrypto.decrypt(encrypted);

      expect(decrypted, isNull);
    });
  });

  group('RoomCrypto.forRawKey (direct/contact rooms)', () {
    test('encrypt then decrypt returns the original plaintext', () async {
      final keyBytes = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final crypto = RoomCrypto.forRawKey(keyBytes);
      const original = 'Direct room message';

      final encrypted = await crypto.encrypt(original);
      final decrypted = await crypto.decrypt(encrypted);

      expect(decrypted, equals(original));
    });

    test('matches the DirectRoom.generateEncryptionKey() + decodeEncryptionKey() flow', () async {
      // Mirrors exactly how DirectRoom's static methods would be used
      // together with RoomCrypto in the real repository layer (Phase 5).
      final base64Key = base64.encode(
        Uint8List.fromList(List<int>.generate(32, (i) => (i * 7) % 256)),
      );
      final decodedKeyBytes = base64.decode(base64Key);

      final crypto = RoomCrypto.forRawKey(decodedKeyBytes);
      const message = 'Testing the full DirectRoom key flow';

      final encrypted = await crypto.encrypt(message);
      final decrypted = await crypto.decrypt(encrypted);

      expect(decrypted, equals(message));
    });

    test('different raw keys cannot decrypt each other\'s output', () async {
      final keyA = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final keyB = Uint8List.fromList(List<int>.generate(32, (i) => 255 - i));

      final cryptoA = RoomCrypto.forRawKey(keyA);
      final cryptoB = RoomCrypto.forRawKey(keyB);

      final encrypted = await cryptoA.encrypt('Confidential');
      final decrypted = await cryptoB.decrypt(encrypted);

      expect(decrypted, isNull);
    });
  });

  group('Tamper detection (GCM authentication)', () {
    test('modifying a single byte of ciphertext causes decryption to fail', () async {
      final crypto = RoomCrypto.forRoomCode('TAMPER-TEST');
      final encrypted = await crypto.encrypt('Original untampered message');

      final bytes = base64.decode(encrypted);
      // Flip a byte somewhere in the middle (past the 12-byte IV, so
      // we're definitely tampering with ciphertext/tag, not the nonce).
      final tampered = Uint8List.fromList(bytes);
      tampered[bytes.length - 1] = tampered[bytes.length - 1] ^ 0xFF;
      final tamperedToken = base64.encode(tampered);

      final decrypted = await crypto.decrypt(tamperedToken);
      expect(decrypted, isNull);
    });
  });

  group('Malformed input handling', () {
    test('garbage base64 returns null instead of throwing', () async {
      final crypto = RoomCrypto.forRoomCode('TEST');
      final decrypted = await crypto.decrypt('not-valid-base64!!!');
      expect(decrypted, isNull);
    });

    test('valid base64 but too short (no room for IV) returns null', () async {
      final crypto = RoomCrypto.forRoomCode('TEST');
      final shortToken = base64.encode([1, 2, 3]);
      final decrypted = await crypto.decrypt(shortToken);
      expect(decrypted, isNull);
    });

    test('empty string plaintext round-trips correctly', () async {
      final crypto = RoomCrypto.forRoomCode('EMPTY-TEST');
      final encrypted = await crypto.encrypt('');
      final decrypted = await crypto.decrypt(encrypted);
      expect(decrypted, equals(''));
    });
  });
}
