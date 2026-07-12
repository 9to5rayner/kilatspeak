import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Drop-in equivalent of the Kotlin app's SecurePrefs.kt.
///
/// flutter_secure_storage wraps the Android Keystore on Android (same
/// underlying mechanism EncryptedSharedPreferences used) and the Keychain
/// on iOS. Unlike the Kotlin version, we don't need the manual
/// "wipe-and-retry-once" self-healing logic — flutter_secure_storage
/// handles Keystore invalidation more gracefully internally. If we ever
/// see evidence otherwise on a real device, we can add that safety net
/// back in here.
///
/// Usage:
///   final storage = SecureStorageService();
///   final key = await storage.getApiKey();
///   await storage.setApiKey('new-key-value');
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _keyApiKey = 'api_key';
  static const _keyMyLanguage = 'my_language';

  // ── kie.ai API key ──────────────────────────────────────────────────────

  Future<String?> getApiKey() => _storage.read(key: _keyApiKey);

  Future<void> setApiKey(String value) =>
      _storage.write(key: _keyApiKey, value: value);

  // ── Chosen spoken language (persisted across launches) ─────────────────

  Future<String?> getMyLanguage() => _storage.read(key: _keyMyLanguage);

  Future<void> setMyLanguage(String languageName) =>
      _storage.write(key: _keyMyLanguage, value: languageName);

  // ── Utility ──────────────────────────────────────────────────────────────

  /// Clears all stored values. Used on sign-out, mirroring the Kotlin app's
  /// behavior of not persisting sensitive data across accounts.
  Future<void> clearAll() => _storage.deleteAll();
}
