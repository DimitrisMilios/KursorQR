import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'clay_decoration.dart';
import 'clay_pressable.dart';

/// Tactile round clay color bead supporting solid colors or linear gradients.
/// Selected state elevates with a subtle gold ring highlight and check mark.
class ClayColorKnob extends StatelessWidget {
  const ClayColorKnob({
    super.key,
    required this.color,
    this.gradientEnd,
    this.selected = false,
    this.tooltip,
    this.size = 34,
    this.onTap,
  });

  final Color color;
  final Color? gradientEnd;
  final bool selected;
  final String? tooltip;
  final double size;
  final VoidCallback? onTap;

  static Color _lighter(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + 0.28).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.85).clamp(0.0, 1.0))
        .toColor();
  }

  static Color _darker(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.28).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final checkColor =
        color.computeLuminance() > 0.55 ? AppColors.textPrimary : Colors.white;
    final gradient = gradientEnd != null
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, gradientEnd!],
          )
        : null;

    Widget knob = ClayPressable(
      onTap: onTap,
      squash: 0.10,
      builder: (context, hover, press, _) {
        final h = hover.clamp(0.0, 1.0);
        final p = press.clamp(0.0, 1.0);
        return Transform.scale(
          scale: (selected ? 1.12 : 1.0) + 0.05 * h - 0.06 * p,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: ClayDecoration(
              color: color,
              gradient: gradient,
              radius: size / 2,
              depth: (size * 0.14).clamp(3.0, 5.5),
              lift: (selected ? 10 : 6) + 4 * h,
              pressed: p,
              shadowOpacity: selected ? 0.30 : 0.20,
              edgeOpacity: 0.14,
              highlightColor: _lighter(color),
              highlightOpacity: 0.85,
              shadeColor: _darker(gradientEnd ?? color),
              shadeOpacity: 0.55,
              shadowColor: selected
                  ? AppColors.goldDeep
                  : _darker(gradientEnd ?? color),
            ),
            child: selected
                ? Icon(Icons.check_rounded, size: size * 0.5, color: checkColor)
                : null,
          ),
        );
      },
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      knob = Tooltip(message: tooltip!, child: knob);
    }
    return knob;
  }
}
