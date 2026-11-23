import 'package:flutter/material.dart';

/// Centralized claymorphism colour design tokens for KursorQR.
///
/// Rules of thumb: selected = gold, action = green, danger = coral.
class AppColors {
  const AppColors._();

  // Base warm clay surfaces
  static const Color sand = Color(0xFFEFE8D6); // page background
  static const Color sandDeep = Color(0xFFE6DEC8); // dialog barrier & deep backdrop
  static const Color clay = Color(0xFFFBF6EA); // default raised clay surface
  static const Color clayDeep = Color(0xFFF1EAD8); // sunken wells, inputs, tracks

  // Clay lighting (used by ClayDecoration, never directly by views)
  static const Color clayLight = Color(0xFFFFFFFF); // inner highlight, top-left
  static const Color clayShade = Color(0xFF1A4731); // inner shade, bottom-right
  static const Color clayShadow = Color(0xFF1A4731); // outer floating shadow

  // Brand clay (primary actions)
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryDeep = Color(0xFF1A4731);
  static const Color primaryLight = Color(0xFF52B788);
  static const Color mint = Color(0xFFCDE7D6);

  // Gold accent (selected states, hero highlights)
  static const Color gold = Color(0xFFE8C464);
  static const Color goldDeep = Color(0xFFC9A440);
  static const Color goldLight = Color(0xFFFFE79A);
  static const Color butter = Color(0xFFFFF0C2);

  // Semantic clay
  static const Color coral = Color(0xFFF08A7E);
  static const Color coralDeep = Color(0xFFD9675B);
  static const Color coralSoft = Color(0xFFFCE2DE);
  static const Color sage = Color(0xFF8FBF9F);

  // Typography (warm forest ink)
  static const Color textPrimary = Color(0xFF1F3A2E);
  static const Color textSecondary = Color(0xFF3F6350);
  static const Color textMuted = Color(0xFF7A917F);
  static const Color textOnPrimary = Colors.white;
}
