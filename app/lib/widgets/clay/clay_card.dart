import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'clay_decoration.dart';
import 'clay_pressable.dart';

/// Interactive clay card that lifts on hover (+6–8 px) and gently squashes on
/// press. Wrapped in a [RepaintBoundary] for 60 fps web performance.
class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppDimensions.cardPadding),
    this.radius = AppDimensions.radiusClayLg,
    this.lift = AppDimensions.clayLift,
    this.color = AppColors.clay,
    this.width,
    this.height,
    this.clipBehavior = Clip.none,
    this.hoverBuilder,
    this.emphasised = false,
    this.hoverLift = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double lift;
  final Color color;
  final double? width;
  final double? height;
  final Clip clipBehavior;
  final Widget Function(BuildContext context, double hover, Widget child)?
      hoverBuilder;
  final bool emphasised;
  final bool hoverLift;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClayPressable(
        onTap: onTap,
        enabled: hoverLift || onTap != null,
        squash: onTap != null ? 0.03 : 0,
        cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: child,
        builder: (context, hover, press, child) {
          final h = hoverLift ? hover.clamp(0.0, 1.0) : 0.0;
          final p = press.clamp(0.0, 1.0);
          final baseLift = emphasised ? lift + 4 : lift;
          Widget inner = child!;
          if (hoverBuilder != null) inner = hoverBuilder!(context, h, inner);
          return Transform.scale(
            scale: 1 + 0.012 * h - 0.025 * p,
            child: Container(
              width: width,
              height: height,
              padding: padding,
              clipBehavior: clipBehavior,
              decoration: ClayDecoration(
                color: color,
                radius: radius,
                depth: AppDimensions.clayDepth,
                lift: ui.lerpDouble(baseLift, baseLift + 7, h)!,
                pressed: p * 0.4,
                shadowOpacity: ui.lerpDouble(0.18, 0.24, h)!,
              ),
              child: inner,
            ),
          );
        },
      ),
    );
  }
}
