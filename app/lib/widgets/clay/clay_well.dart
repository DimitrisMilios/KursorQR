import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'clay_container.dart';
import 'clay_decoration.dart';

/// Sunken inset well for grouping: QR preview stage, scan stat strips,
/// copyable URL pill, warning/info callouts, and progress tracks.
class ClayWell extends StatelessWidget {
  const ClayWell({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingMd),
    this.margin,
    this.radius = AppDimensions.radiusClaySm,
    this.depth = 5,
    this.color = AppColors.clayDeep,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.none,
  });

  /// Soft sage/mint well for positive disclosures and active info.
  const ClayWell.mint({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingMd),
    this.margin,
    this.radius = AppDimensions.radiusClaySm,
    this.depth = 4,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.none,
  }) : color = AppColors.mint;

  /// Soft butter well for quota alerts and contrast warnings.
  const ClayWell.butter({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingMd),
    this.margin,
    this.radius = AppDimensions.radiusClaySm,
    this.depth = 4,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.none,
  }) : color = AppColors.butter;

  /// Soft coral well for errors and danger zones.
  const ClayWell.coral({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingMd),
    this.margin,
    this.radius = AppDimensions.radiusClaySm,
    this.depth = 4,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.none,
  }) : color = AppColors.coralSoft;

  final Widget? child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double depth;
  final Color color;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final dark = color.computeLuminance() < 0.3;
    return ClayContainer(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      alignment: alignment,
      clipBehavior: clipBehavior,
      decoration: ClayDecoration.well(
        color: color,
        radius: radius,
        depth: depth,
        shadeOpacity: dark ? 0.5 : 0.14,
        highlightOpacity: dark ? 0.12 : 0.8,
      ),
      child: child,
    );
  }
}
