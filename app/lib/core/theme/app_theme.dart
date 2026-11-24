import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../widgets/clay/clay_decoration.dart';

/// Claymorphism theme factory for KursorQR.
///
/// Surfaces are painted by the clay kit, so this theme strips Material's
/// default chrome: no ink splashes, no borders, no elevation, warm sand canvas,
/// and rounded Nunito typography.
class AppTheme {
  const AppTheme._();

  static TextTheme textTheme() {
    final base = GoogleFonts.nunitoTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.2,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: base.labelSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static ThemeData light({Decoration? tooltipDecoration}) {
    final text = textTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.sand,
      canvasColor: AppColors.sand,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.gold,
        surface: AppColors.clay,
        error: AppColors.coralDeep,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: text,
      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
          color: AppColors.textMuted,
          fontSize: AppDimensions.fontBody,
        ),
        hintStyle: TextStyle(
          color: AppColors.textMuted,
          fontSize: AppDimensions.fontBody,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.gold.withValues(alpha: 0.45),
        selectionHandleColor: AppColors.primary,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: tooltipDecoration ??
            const ClayDecoration(
              color: AppColors.clay,
              radius: AppDimensions.radiusClaySm,
              depth: 3,
              lift: 8,
              shadowOpacity: 0.18,
            ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.all(8),
        waitDuration: const Duration(milliseconds: 450),
        textStyle: text.labelMedium?.copyWith(
          color: AppColors.textPrimary,
          fontSize: AppDimensions.fontSm,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.clay,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusClaySm),
        ),
        textStyle: text.bodyMedium?.copyWith(fontSize: AppDimensions.fontMd),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.clay,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusClay),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        space: 16,
        thickness: 0,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );
  }
}
