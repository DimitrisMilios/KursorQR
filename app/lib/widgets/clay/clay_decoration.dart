import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/motion/clay_motion.dart';

/// Tactile claymorphism [Decoration]. Paints inside a rounded rectangle:
///
/// 1. Outer floating shadow (skipped when [sunken]);
/// 2. Solid (or gradient) fill, darkened 6% when [pressed];
/// 3. Clipped inner top-left highlight and bottom-right shade (inverted when
///    [pressed] or [sunken]).
///
/// Performance: paints strictly with analytic `RRect` primitives and constant
/// blur sigmas — animating only offsets and alpha per frame.
class ClayDecoration extends Decoration {
  final Color color;
  final Gradient? gradient;
  final double radius;
  final double depth;
  final double lift;
  final double pressed;
  final bool sunken;
  final double shadowOpacity;
  final double highlightOpacity;
  final double shadeOpacity;
  final double edgeOpacity;
  final Color highlightColor;
  final Color shadeColor;
  final Color shadowColor;
  final double rippleTime;
  final double rippleAmp;

  const ClayDecoration({
    this.color = AppColors.clay,
    this.gradient,
    this.radius = AppDimensions.radiusClay,
    this.depth = AppDimensions.clayDepth,
    this.lift = AppDimensions.clayLift,
    this.pressed = 0.0,
    this.sunken = false,
    this.shadowOpacity = 0.20,
    this.highlightOpacity = 0.9,
    this.shadeOpacity = 0.16,
    this.edgeOpacity = 0.0,
    this.highlightColor = AppColors.clayLight,
    this.shadeColor = AppColors.clayShade,
    this.shadowColor = AppColors.clayShadow,
    this.rippleTime = -1,
    this.rippleAmp = 3.0,
  });

  /// Raised forest-green clay surface (primary actions).
  const ClayDecoration.primary({
    this.radius = AppDimensions.radiusClay,
    this.depth = 5,
    this.lift = 14,
    this.pressed = 0.0,
    this.rippleTime = -1,
    this.rippleAmp = 3.0,
    this.edgeOpacity = 0.25,
  })  : color = AppColors.primary,
        gradient = null,
        sunken = false,
        shadowOpacity = 0.28,
        highlightOpacity = 0.55,
        shadeOpacity = 0.55,
        highlightColor = AppColors.primaryLight,
        shadeColor = AppColors.primaryDeep,
        shadowColor = AppColors.primaryDeep;

  /// Raised gold clay surface (selected states & highlight CTAs).
  const ClayDecoration.gold({
    this.radius = AppDimensions.radiusClay,
    this.depth = 5,
    this.lift = 14,
    this.pressed = 0.0,
    this.rippleTime = -1,
    this.rippleAmp = 3.0,
    this.edgeOpacity = 0.25,
  })  : color = AppColors.gold,
        gradient = null,
        sunken = false,
        shadowOpacity = 0.30,
        highlightOpacity = 0.75,
        shadeOpacity = 0.6,
        highlightColor = AppColors.goldLight,
        shadeColor = AppColors.goldDeep,
        shadowColor = AppColors.goldDeep;

  /// Raised coral clay surface (destructive actions).
  const ClayDecoration.danger({
    this.radius = AppDimensions.radiusClay,
    this.depth = 5,
    this.lift = 14,
    this.pressed = 0.0,
    this.rippleTime = -1,
    this.rippleAmp = 3.0,
    this.edgeOpacity = 0.25,
  })  : color = AppColors.coral,
        gradient = null,
        sunken = false,
        shadowOpacity = 0.30,
        highlightOpacity = 0.6,
        shadeOpacity = 0.6,
        highlightColor = const Color(0xFFFFC2B8),
        shadeColor = AppColors.coralDeep,
        shadowColor = AppColors.coralDeep;

  /// Sunken inset well (inputs, stat strips, tracks, preview stages).
  const ClayDecoration.well({
    this.color = AppColors.clayDeep,
    this.radius = AppDimensions.radiusClaySm,
    this.depth = 5,
    this.shadeOpacity = 0.14,
    this.highlightOpacity = 0.8,
  })  : gradient = null,
        lift = 0,
        pressed = 0,
        sunken = true,
        shadowOpacity = 0,
        edgeOpacity = 0,
        highlightColor = AppColors.clayLight,
        shadeColor = AppColors.clayShade,
        shadowColor = AppColors.clayShadow,
        rippleTime = -1,
        rippleAmp = 0;

  ClayDecoration get hidden => copyWith(
        color: color.withValues(alpha: 0),
        lift: 0,
        shadowOpacity: 0,
        highlightOpacity: 0,
        shadeOpacity: 0,
        edgeOpacity: 0,
      );

  ClayDecoration copyWith({
    Color? color,
    Gradient? gradient,
    double? radius,
    double? depth,
    double? lift,
    double? pressed,
    bool? sunken,
    double? shadowOpacity,
    double? highlightOpacity,
    double? shadeOpacity,
    double? edgeOpacity,
    Color? highlightColor,
    Color? shadeColor,
    Color? shadowColor,
    double? rippleTime,
    double? rippleAmp,
  }) {
    return ClayDecoration(
      color: color ?? this.color,
      gradient: gradient ?? this.gradient,
      radius: radius ?? this.radius,
      depth: depth ?? this.depth,
      lift: lift ?? this.lift,
      pressed: pressed ?? this.pressed,
      sunken: sunken ?? this.sunken,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      highlightOpacity: highlightOpacity ?? this.highlightOpacity,
      shadeOpacity: shadeOpacity ?? this.shadeOpacity,
      edgeOpacity: edgeOpacity ?? this.edgeOpacity,
      highlightColor: highlightColor ?? this.highlightColor,
      shadeColor: shadeColor ?? this.shadeColor,
      shadowColor: shadowColor ?? this.shadowColor,
      rippleTime: rippleTime ?? this.rippleTime,
      rippleAmp: rippleAmp ?? this.rippleAmp,
    );
  }

  static ClayDecoration? lerp(ClayDecoration? a, ClayDecoration? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b!.hidden._lerpTo(b, t);
    if (b == null) return a._lerpTo(a.hidden, t);
    return a._lerpTo(b, t);
  }

  ClayDecoration _lerpTo(ClayDecoration b, double t) {
    return ClayDecoration(
      color: Color.lerp(color, b.color, t)!,
      gradient: Gradient.lerp(gradient, b.gradient, t),
      radius: ui.lerpDouble(radius, b.radius, t)!,
      depth: ui.lerpDouble(depth, b.depth, t)!,
      lift: ui.lerpDouble(lift, b.lift, t)!,
      pressed: ui.lerpDouble(pressed, b.pressed, t)!,
      sunken: t < 0.5 ? sunken : b.sunken,
      shadowOpacity: ui.lerpDouble(shadowOpacity, b.shadowOpacity, t)!,
      highlightOpacity: ui.lerpDouble(highlightOpacity, b.highlightOpacity, t)!,
      shadeOpacity: ui.lerpDouble(shadeOpacity, b.shadeOpacity, t)!,
      edgeOpacity: ui.lerpDouble(edgeOpacity, b.edgeOpacity, t)!,
      highlightColor: Color.lerp(highlightColor, b.highlightColor, t)!,
      shadeColor: Color.lerp(shadeColor, b.shadeColor, t)!,
      shadowColor: Color.lerp(shadowColor, b.shadowColor, t)!,
      rippleTime: t < 0.5 ? rippleTime : b.rippleTime,
      rippleAmp: ui.lerpDouble(rippleAmp, b.rippleAmp, t)!,
    );
  }

  @override
  ClayDecoration? lerpFrom(Decoration? a, double t) {
    if (a is ClayDecoration?) return ClayDecoration.lerp(a, this, t);
    return super.lerpFrom(a, t) as ClayDecoration?;
  }

  @override
  ClayDecoration? lerpTo(Decoration? b, double t) {
    if (b is ClayDecoration?) return ClayDecoration.lerp(this, b, t);
    return super.lerpTo(b, t) as ClayDecoration?;
  }

  @override
  EdgeInsetsGeometry get padding => EdgeInsets.zero;

  @override
  bool get isComplex => true;

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) =>
      Path()..addRRect(_rrect(rect));

  @override
  bool hitTest(Size size, Offset position, {TextDirection? textDirection}) =>
      _rrect(Offset.zero & size).contains(position);

  RRect _rrect(Rect rect) {
    final r = math.min(radius, math.min(rect.width, rect.height) / 2);
    return RRect.fromRectAndRadius(rect, Radius.circular(r));
  }

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _ClayBoxPainter(this, onChanged);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClayDecoration &&
        other.color == color &&
        other.gradient == gradient &&
        other.radius == radius &&
        other.depth == depth &&
        other.lift == lift &&
        other.pressed == pressed &&
        other.sunken == sunken &&
        other.shadowOpacity == shadowOpacity &&
        other.highlightOpacity == highlightOpacity &&
        other.shadeOpacity == shadeOpacity &&
        other.edgeOpacity == edgeOpacity &&
        other.highlightColor == highlightColor &&
        other.shadeColor == shadeColor &&
        other.shadowColor == shadowColor &&
        other.rippleTime == rippleTime &&
        other.rippleAmp == rippleAmp;
  }

  @override
  int get hashCode => Object.hash(
        color,
        gradient,
        radius,
        depth,
        lift,
        pressed,
        sunken,
        shadowOpacity,
        highlightOpacity,
        shadeOpacity,
        edgeOpacity,
        highlightColor,
        shadeColor,
        shadowColor,
        rippleTime,
        rippleAmp,
      );
}

class _ClayBoxPainter extends BoxPainter {
  _ClayBoxPainter(this.d, super.onChanged);

  final ClayDecoration d;

  static const double _outerSigma = 14.0;
  static const double _edgeSigma = 4.0;
  static const MaskFilter _outerBlur =
      MaskFilter.blur(BlurStyle.normal, _outerSigma);
  static const MaskFilter _edgeBlur =
      MaskFilter.blur(BlurStyle.normal, _edgeSigma);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null || size.isEmpty) return;
    final rect = offset & size;
    final shape = _shape(rect);

    final press = d.pressed.clamp(0.0, 1.0);
    final invert = d.sunken ? 1.0 : press;

    // 1. Outer floating shadows.
    if (!d.sunken && d.shadowOpacity > 0.001) {
      final lift = ui.lerpDouble(d.lift, 2.0, press)!;
      final opacity = d.shadowOpacity * (1 - 0.6 * press);
      canvas.drawRRect(
        shape.shift(Offset(0, lift)),
        Paint()
          ..color = d.shadowColor.withValues(alpha: opacity.clamp(0, 1))
          ..maskFilter = _outerBlur,
      );
      if (d.edgeOpacity > 0.001) {
        canvas.drawRRect(
          shape.shift(Offset(0, ui.lerpDouble(4, 1, press)!)),
          Paint()
            ..color = d.shadowColor
                .withValues(alpha: (d.edgeOpacity * (1 - press)).clamp(0, 1))
            ..maskFilter = _edgeBlur,
        );
      }
    }

    // 2. Fill (solid or gradient).
    final fillPaint = Paint();
    if (d.gradient != null) {
      fillPaint.shader = d.gradient!.createShader(rect);
    } else {
      fillPaint.color =
          press > 0 ? Color.lerp(d.color, _darken(d.color, 0.06), press)! : d.color;
    }
    canvas.drawRRect(shape, fillPaint);

    // 3. Clipped inner lighting (top-left highlight, bottom-right shade).
    final depth = d.depth;
    final highlight = d.highlightOpacity > 0.001;
    final shade = d.shadeOpacity > 0.001;
    if (depth <= 0.01 || (!highlight && !shade)) return;

    final offsetAmount = depth * (1 - 2 * invert);
    final blur = MaskFilter.blur(BlurStyle.normal, depth);
    canvas.save();
    canvas.clipRRect(shape);
    if (highlight) {
      canvas.drawRRect(
        shape.shift(Offset(-offsetAmount, -offsetAmount)),
        _stroke(
          depth,
          d.highlightColor.withValues(alpha: d.highlightOpacity.clamp(0, 1)),
          blur,
        ),
      );
    }
    if (shade) {
      canvas.drawRRect(
        shape.shift(Offset(offsetAmount, offsetAmount)),
        _stroke(
          depth,
          d.shadeColor.withValues(alpha: d.shadeOpacity.clamp(0, 1)),
          blur,
        ),
      );
    }
    canvas.restore();
  }

  static Paint _stroke(double depth, Color color, MaskFilter blur) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = depth * 2
    ..color = color
    ..maskFilter = blur;

  RRect _shape(Rect rect) {
    final r = math.min(d.radius, math.min(rect.width, rect.height) / 2);
    if (d.rippleTime <= 0 || d.rippleAmp <= 0) {
      return RRect.fromRectAndRadius(rect, Radius.circular(r));
    }
    final a = rippleAt(d.rippleTime, amp: d.rippleAmp);
    final b = rippleAt(d.rippleTime + 0.08, amp: d.rippleAmp);
    final wobbled = Rect.fromLTRB(
      rect.left + a,
      rect.top - b,
      rect.right - a,
      rect.bottom + b,
    );
    final rad = math.min(r + a, math.min(wobbled.width, wobbled.height) / 2);
    return RRect.fromRectAndRadius(wobbled, Radius.circular(rad));
  }

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
