import 'package:flutter/material.dart';

/// Material 3 commercial theme for KursorQR.
class AppTheme {
  const AppTheme._();

  static const Color brandPrimary = Color(0xFF4F46E5);
  static const Color surfaceCanvas = Color(0xFFF8FAFC);
  static const Color inkDark = Color(0xFF0F172A);
  static const Color inkMuted = Color(0xFF475569);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandPrimary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceCanvas,
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCanvas,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
