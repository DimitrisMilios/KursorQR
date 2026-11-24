import 'package:flutter/material.dart';

/// Centralized claymorphism colour design tokens for KursorQR: Deep Rust & Pearl.
///
/// Anchors: Deep Rust (#8B3103) primary + Pearl (#EAE0C8) canvas.
/// Rules of thumb: selected = amber gold, action = deep rust, danger = crimson coral.
class AppColors {
  const AppColors._();

  // Base Pearl clay surfaces
  static const Color sand = Color(0xFFEAE0C8); // Pearl page background
  static const Color sandDeep = Color(0xFFDFD3B6); // dialog barrier & deep backdrop
  static const Color clay = Color(0xFFF7F1E3); // luminous pearl clay surface
  static const Color clayDeep = Color(0xFFE3D7BC); // sunken wells, inputs, tracks

  // Clay lighting (used by ClayDecoration, never directly by views)
  static const Color clayLight = Color(0xFFFFFFFF); // inner highlight, top-left
  static const Color clayShade = Color(0xFF5C1F02); // warm burnt-rust inner shade
  static const Color clayShadow = Color(0xFF5C1F02); // outer floating shadow

  // Brand clay (Deep Rust primary actions)
  static const Color primary = Color(0xFF8B3103); // Deep Rust
  static const Color primaryDeep = Color(0xFF5C1F02); // dark kiln rust
  static const Color primaryLight = Color(0xFFC45722); // warm terracotta highlight
  static const Color mint = Color(0xFFF0D6C4); // warm blush-apricot hover & info well

  // Warm honey-gold accent (selected states, hero highlights)
  static const Color gold = Color(0xFFDFA94B);
  static const Color goldDeep = Color(0xFFB88329);
  static const Color goldLight = Color(0xFFFAD284);
  static const Color butter = Color(0xFFF9EAC8);

  // Semantic clay
  static const Color coral = Color(0xFFD9534F); // crimson danger actions
  static const Color coralDeep = Color(0xFFB53531);
  static const Color coralSoft = Color(0xFFF9D8D6);
  static const Color sage = Color(0xFF5C8D6B); // earthy olive-sage active/success

  // Typography (warm espresso-umber ink)
  static const Color textPrimary = Color(0xFF2C1608);
  static const Color textSecondary = Color(0xFF5E3A24);
  static const Color textMuted = Color(0xFF8E6E58);
  static const Color textOnPrimary = Colors.white;
}
