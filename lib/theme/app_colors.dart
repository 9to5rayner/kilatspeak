import 'package:flutter/material.dart';

/// Color palette ported directly from the original Kotlin app's colors.xml.
/// Deep navy + warm gold, evoking printed scripture and reverence.
class AppColors {
  AppColors._();

  // Primary palette
  static const Color navyDeep = Color(0xFF1A2744);
  static const Color navyMid = Color(0xFF243258);
  static const Color navySurface = Color(0xFF2D3E6B);
  static const Color goldPrimary = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFE8C96A);
  static const Color goldPale = Color(0xFFF5E9C4);

  // Incoming-message accent (partner's bubbles)
  static const Color tealDeep = Color(0xFF2E6B5E);
  static const Color lavenderPale = Color(0xFFE6E0F5);
  static const Color lavenderStroke = Color(0xFFA893C9);

  // Neutrals
  static const Color creamBg = Color(0xFFF8F5EE);
  static const Color creamCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2744);
  static const Color textSecondary = Color(0xFF5A6A8A);
  static const Color textHint = Color(0xFF9AAAC0);
  static const Color divider = Color(0xFFE4DDD0);

  // Status
  static const Color recordingRed = Color(0xFFE03B3B);
  static const Color pausedAmber = Color(0xFFE09A2B);
  static const Color successGreen = Color(0xFF2E7D52);
}
