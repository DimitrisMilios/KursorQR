import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'clay_decoration.dart';

/// Convenience box painted with [ClayDecoration].
class ClayContainer extends StatelessWidget {
  const ClayContainer({
    super.key,
    this.child,
    this.decoration = const ClayDecoration(),
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.constraints,
    this.clipBehavior = Clip.none,
  });

  ClayContainer.raised({
    super.key,
    this.child,
    Color color = AppColors.clay,
    double radius = AppDimensions.radiusClay,
    double depth = AppDimensions.clayDepth,
    double lift = AppDimensions.clayLift,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.constraints,
    this.clipBehavior = Clip.none,
  }) : decoration = ClayDecoration(
          color: color,
          radius: radius,
          depth: depth,
          lift: lift,
        );

  ClayContainer.sunken({
    super.key,
    this.child,
    Color color = AppColors.clayDeep,
    double radius = AppDimensions.radiusClaySm,
    double depth = 5,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.constraints,
    this.clipBehavior = Clip.none,
  }) : decoration = ClayDecoration.well(
          color: color,
          radius: radius,
          depth: depth,
        );

  final Widget? child;
  final ClayDecoration decoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      alignment: alignment,
      constraints: constraints,
      clipBehavior: clipBehavior,
      decoration: decoration,
      child: child,
    );
  }
}
