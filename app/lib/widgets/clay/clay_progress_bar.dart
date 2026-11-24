import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/motion/clay_motion.dart';
import 'clay_decoration.dart';

/// Sunken clay track with a spring-animated raised clay fill bar.
class ClayProgressBar extends StatefulWidget {
  const ClayProgressBar({
    super.key,
    required this.value,
    this.height = 12,
    this.fillColor = AppColors.primary,
  });

  final double value;
  final double height;
  final Color fillColor;

  @override
  State<ClayProgressBar> createState() => _ClayProgressBarState();
}

class _ClayProgressBarState extends State<ClayProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(
      vsync: this,
      value: widget.value.clamp(0.0, 1.0),
    );
  }

  @override
  void didUpdateWidget(ClayProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _ctrl.springTo(
        widget.value.clamp(0.0, 1.0),
        spring: ClayMotion.of(context).gentle,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.height / 2;
    final hsl = HSLColor.fromColor(widget.fillColor);
    final light =
        hsl.withLightness((hsl.lightness + 0.18).clamp(0.0, 1.0)).toColor();
    final dark =
        hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(2),
      decoration: ClayDecoration.well(
        color: AppColors.clayDeep,
        radius: radius,
        depth: 3,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final frac = _ctrl.value.clamp(0.0, 1.0);
              final fillW = constraints.maxWidth * frac;
              if (fillW < 1) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: fillW.clamp(widget.height - 4, constraints.maxWidth),
                  height: widget.height - 4,
                  decoration: ClayDecoration(
                    color: widget.fillColor,
                    radius: (widget.height - 4) / 2,
                    depth: 2.5,
                    lift: 2,
                    shadowOpacity: 0.18,
                    highlightColor: light,
                    highlightOpacity: 0.6,
                    shadeColor: dark,
                    shadeOpacity: 0.45,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
