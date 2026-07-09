import 'package:flutter/material.dart';
import 'app_colors.dart';

/// The overall Material theme for KilatSpeak, built from AppColors.
/// Mirrors the intent of the original Theme.GroqTranscriber Android theme:
/// navy app bars/buttons, cream backgrounds, gold accents, rounded cards.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.creamBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navyDeep,
        primary: AppColors.navyDeep,
        secondary: AppColors.goldPrimary,
        surface: AppColors.creamCard,
        error: AppColors.recordingRed,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navyDeep,
        foregroundColor: AppColors.creamCard,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.creamCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyDeep,
          foregroundColor: AppColors.creamCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navyDeep,
          side: const BorderSide(color: AppColors.navyDeep),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        labelSmall: TextStyle(
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textPrimary,
        ),
      ),
      dividerColor: AppColors.divider,
    );
  }
}
