import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'clay_container.dart';
import 'clay_decoration.dart';
import 'jelly_transform.dart';

/// Large raised clay surface: navbars, showcase panels, dialogs, quota card.
/// Wrapped in a [RepaintBoundary] so outer shadows stay cached on the GPU.
class ClayPanel extends StatelessWidget {
  const ClayPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingLg),
    this.margin,
    this.radius = AppDimensions.radiusClayLg,
    this.lift = AppDimensions.clayLift,
    this.depth = AppDimensions.clayDepth,
    this.color = AppColors.clay,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.none,
    this.ripple = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double lift;
  final double depth;
  final Color color;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final bool ripple;

  @override
  Widget build(BuildContext context) {
    final rippleTime = ripple ? JellyRipple.of(context) : -1.0;
    return RepaintBoundary(
      child: ClayContainer(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        alignment: alignment,
        clipBehavior: clipBehavior,
        decoration: ClayDecoration(
          color: color,
          radius: radius,
          lift: lift,
          depth: depth,
          rippleTime: rippleTime,
        ),
        child: child,
      ),
    );
  }
}
