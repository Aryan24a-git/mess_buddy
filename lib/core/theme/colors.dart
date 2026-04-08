import 'package:flutter/material.dart';

class AppColors {
  // Brand / Primary
  static const Color primary = Color(0xFFC4C0FF); // Primary Accent
  static const Color primaryContainer = Color(0xFF8781FF); // For Gradients
  static const Color onPrimary = Color(0xFF2000A4);
  
  // Secondary / Tertiary
  static const Color secondary = Color(0xFFA2E7FF); // Secondary Accent
  static const Color tertiary = Color(0xFFFFB785); // Warning / Debt
  static const Color accent = secondary; // Compatibility alias
  static const Color surfaceTranslucent = Color(0x33FFFFFF); // Compatibility alias
  
  // Surfaces (The "No-Line" Architecture)
  static const Color background = Color(0xFF111317); // Core Background
  static const Color surface = Color(0xFF111317); // Base Surface
  static const Color surfaceContainerLow = Color(0xFF1A1C20); // Level 1 Sections
  static const Color surfaceContainerHighest = Color(0xFF333539); // Level 2 Cards
  static const Color surfaceVariant = Color(0xFF333539);
  static const Color surfaceBright = Color(0xFF37393E); // Left-accent bars
  
  // Glassmorphism & Translucency
  static const Color glassBase = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color ghostBorder = Color(0x26C4C0FF); // primary at 15% opacity
  
  // Text Colors (Editorial Authority)
  static const Color textPrimary = Color(0xFFE2E2E8); // on-surface
  static const Color textSecondary = Color(0xFFC7C4D8); // on-surface-variant
  static const Color textMuted = Color(0xFFC7C4D8);
  
  // Accents & Signals
  static const Color success = Color(0xFFA2E7FF); // Using secondary for growth
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
}
