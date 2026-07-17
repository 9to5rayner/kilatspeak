import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/language.dart';
import '../providers/launch_settings_provider.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';

/// Real Launch screen, ported from LaunchActivity.kt.
/// API key entry + spoken-language picker, both persisted via
/// SecureStorageService (through launchSettingsProvider).
///
/// Not styled as WhatsApp-inspired — this is an app-specific onboarding/
/// settings gate with no real WhatsApp equivalent. The WhatsApp-inspired
/// direction applies starting with the Room screen (Phase 6b) and
/// especially the chat/Recording screen (Phase 9), where it's actually
/// relevant to the messaging experience.
class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({super.key});

  @override
  ConsumerState<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends ConsumerState<LaunchScreen> {
  final _apiKeyController = TextEditingController();
  Language _selectedLanguage = Language.indonesian;
  bool _hasInitializedFromSettings = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid kie.ai API key')),
      );
      return;
    }

    setState(() => _isSaving = true);

    await ref.read(launchSettingsProvider.notifier).save(
          apiKey: apiKey,
          language: _selectedLanguage,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);
    context.go(AppRoutes.room);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(launchSettingsProvider);

    // Prefill the form once, the first time settings finish loading —
    // avoids overwriting the user's in-progress edits on every rebuild.
    settingsAsync.whenData((settings) {
      if (!_hasInitializedFromSettings) {
        _hasInitializedFromSettings = true;
        _apiKeyController.text = settings.apiKey;
        _selectedLanguage = settings.myLanguage;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        child: settingsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.goldPrimary),
          ),
          error: (error, stack) => Center(
            child: Text('Failed to load settings: $error'),
          ),
          data: (_) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildApiKeyCard(),
                const SizedBox(height: 16),
                _buildLanguageCard(),
                const SizedBox(height: 32),
                _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.navyDeep,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.bolt, color: AppColors.goldPrimary, size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'KilatSpeak',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time Business Translation',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildApiKeyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KIE.AI API KEY',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: false,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Paste your kie.ai API key here',
                hintStyle: const TextStyle(color: AppColors.textHint),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.navyDeep, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'I WILL SPEAK',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your speech is transcribed in this language and translated '
              'into the other for your partner.',
              style: TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.3),
            ),
            const SizedBox(height: 12),
            Row(
              children: Language.values.map((language) {
                final isSelected = _selectedLanguage == language;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: language == Language.values.first ? 8 : 0,
                      left: language == Language.values.last ? 8 : 0,
                    ),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _selectedLanguage = language),
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            isSelected ? AppColors.navyDeep : Colors.transparent,
                        foregroundColor:
                            isSelected ? AppColors.creamCard : AppColors.navyDeep,
                        side: BorderSide(
                          color: isSelected ? AppColors.navyDeep : AppColors.divider,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('${language.flag} ${language.displayName}'),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _handleContinue,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.goldPrimary,
        foregroundColor: AppColors.navyDeep,
        minimumSize: const Size(double.infinity, 56),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      child: _isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyDeep),
            )
          : const Text('Continue'),
    );
  }
}
