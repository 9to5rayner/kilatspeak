import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/language.dart';
import '../services/secure_storage_service.dart';

/// Combined state for the Launch screen — the kie.ai API key and the
/// user's chosen spoken language. Ported from LaunchActivity.kt's two
/// SecurePrefs values, which were always saved together on "Continue".
class LaunchSettings {
  const LaunchSettings({
    required this.apiKey,
    required this.myLanguage,
  });

  final String apiKey;
  final Language myLanguage;

  LaunchSettings copyWith({String? apiKey, Language? myLanguage}) {
    return LaunchSettings(
      apiKey: apiKey ?? this.apiKey,
      myLanguage: myLanguage ?? this.myLanguage,
    );
  }
}

/// Riverpod 3.x AsyncNotifier — the current recommended pattern, replacing
/// the older StateNotifier. build() runs once, asynchronously, to load
/// the persisted values from secure storage before the UI needs them.
///
/// Usage in a widget:
///   final settingsAsync = ref.watch(launchSettingsProvider);
///   settingsAsync.when(
///     data: (settings) => ...,
///     loading: () => CircularProgressIndicator(),
///     error: (e, st) => Text('Error: $e'),
///   );
///
///   // To save:
///   await ref.read(launchSettingsProvider.notifier).save(
///     apiKey: 'new-key',
///     language: Language.english,
///   );
class LaunchSettingsNotifier extends AsyncNotifier<LaunchSettings> {
  final _storage = SecureStorageService();

  @override
  Future<LaunchSettings> build() async {
    final apiKey = await _storage.getApiKey() ?? '';
    final languageName = await _storage.getMyLanguage();
    return LaunchSettings(
      apiKey: apiKey,
      myLanguage: Language.fromName(languageName),
    );
  }

  /// Persists both values to secure storage and updates state —
  /// mirrors LaunchActivity's single prefs.edit().putString(...).apply()
  /// call that saved both api_key and my_language together.
  Future<void> save({
    required String apiKey,
    required Language language,
  }) async {
    await _storage.setApiKey(apiKey);
    await _storage.setMyLanguage(language.name);
    state = AsyncData(LaunchSettings(apiKey: apiKey, myLanguage: language));
  }
}

final launchSettingsProvider =
    AsyncNotifierProvider<LaunchSettingsNotifier, LaunchSettings>(
  LaunchSettingsNotifier.new,
);
