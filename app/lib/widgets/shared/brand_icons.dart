import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Custom crisp vector brand glyphs rendered via [Canvas] so they stay sharp at
/// every DPI (UI pills, dashboard rows, and 256×256 QR center badges) with zero
/// external network requests.
enum BrandIconKind {
  apple,
  googlePlay,
  googleG,
}

/// Paints a [BrandIconKind] onto any [Canvas] inside [bounds].
/// Used both by [BrandVectorIcon] widgets and by `QrRenderService` PNG exports.
void paintBrandIcon(
  Canvas canvas,
  Rect bounds,
  BrandIconKind kind, {
  required Color color,
  bool multicolor = false,
}) {
  canvas.save();
  canvas.translate(bounds.left, bounds.top);
  final scale = math.min(bounds.width, bounds.height) / 24.0;
  canvas.scale(scale, scale);

  switch (kind) {
    case BrandIconKind.apple:
      _paintApple(canvas, color);
    case BrandIconKind.googlePlay:
      _paintGooglePlay(canvas, color, multicolor: multicolor);
    case BrandIconKind.googleG:
      _paintGoogleG(canvas, color, multicolor: multicolor);
  }

  canvas.restore();
}

void _paintApple(Canvas canvas, Color color) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  // Classic bitten apple silhouette in a 24x24 viewBox.
  final body = Path()
    ..moveTo(15.72, 12.66)
    ..cubicTo(15.70, 10.42, 17.55, 9.33, 17.64, 9.27)
    ..cubicTo(16.59, 7.74, 14.96, 7.53, 14.39, 7.46)
    ..cubicTo(13.02, 7.32, 11.70, 8.27, 11.00, 8.27)
    ..cubicTo(10.30, 8.27, 9.23, 7.48, 8.08, 7.50)
    ..cubicTo(6.59, 7.52, 5.20, 8.37, 4.44, 9.70)
    ..cubicTo(2.87, 12.42, 4.04, 16.44, 5.55, 18.63)
    ..cubicTo(6.30, 19.71, 7.18, 20.92, 8.34, 20.87)
    ..cubicTo(9.47, 20.82, 9.90, 20.15, 11.26, 20.15)
    ..cubicTo(12.61, 20.15, 13.00, 20.87, 14.18, 20.85)
    ..cubicTo(15.39, 20.83, 16.16, 19.75, 16.89, 18.67)
    ..cubicTo(17.76, 17.41, 18.11, 16.18, 18.13, 16.12)
    ..cubicTo(18.10, 16.10, 15.75, 15.20, 15.72, 12.66)
    ..close();

  // Tilted leaf above the cleft.
  final leaf = Path()
    ..moveTo(13.48, 6.08)
    ..cubicTo(14.10, 5.32, 14.52, 4.28, 14.40, 3.22)
    ..cubicTo(13.50, 3.26, 12.39, 3.82, 11.75, 4.56)
    ..cubicTo(11.18, 5.21, 10.68, 6.28, 10.82, 7.31)
    ..cubicTo(11.82, 7.39, 12.85, 6.82, 13.48, 6.08)
    ..close();

  canvas.drawPath(body, paint);
  canvas.drawPath(leaf, paint);
}

void _paintGooglePlay(Canvas canvas, Color color, {required bool multicolor}) {
  // Rounded Play prism outline (24x24 viewBox).
  final clip = Path()
    ..moveTo(4.6, 3.35)
    ..cubicTo(4.2, 3.62, 3.95, 4.10, 3.95, 4.72)
    ..lineTo(3.95, 19.28)
    ..cubicTo(3.95, 19.90, 4.20, 20.38, 4.60, 20.65)
    ..cubicTo(5.02, 20.92, 5.58, 20.90, 6.18, 20.56)
    ..lineTo(19.55, 13.06)
    ..cubicTo(20.42, 12.57, 20.42, 11.43, 19.55, 10.94)
    ..lineTo(6.18, 3.44)
    ..cubicTo(5.58, 3.10, 5.02, 3.08, 4.60, 3.35)
    ..close();

  canvas.save();
  canvas.clipPath(clip);

  // Crossing center point of the 4 Google Play facets.
  const cx = 13.85;
  const cy = 12.0;

  if (multicolor) {
    // Blue left triangle
    final left = Path()
      ..moveTo(3.5, 2.5)
      ..lineTo(cx, cy)
      ..lineTo(3.5, 21.5)
      ..close();
    canvas.drawPath(left, Paint()..color = const Color(0xFF4285F4));

    // Green top wedge
    final top = Path()
      ..moveTo(3.5, 2.5)
      ..lineTo(21.0, 9.0)
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(top, Paint()..color = const Color(0xFF34A853));

    // Red bottom wedge
    final bottom = Path()
      ..moveTo(3.5, 21.5)
      ..lineTo(cx, cy)
      ..lineTo(21.0, 15.0)
      ..close();
    canvas.drawPath(bottom, Paint()..color = const Color(0xFFEA4335));

    // Yellow right tip
    final right = Path()
      ..moveTo(cx, cy)
      ..lineTo(21.0, 9.0)
      ..lineTo(21.5, 12.0)
      ..lineTo(21.0, 15.0)
      ..close();
    canvas.drawPath(right, Paint()..color = const Color(0xFFFBBC05));
  } else {
    // Crisp monochrome prism with subtle shaded facets so it reads unmistakably
    // as Google Play even in single-color Deep Rust or espresso ink.
    canvas.drawPath(clip, Paint()..color = color);

    final seam = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawLine(const Offset(4.4, 3.4), const Offset(16.9, 15.2), seam);
    canvas.drawLine(const Offset(4.4, 20.6), const Offset(16.9, 8.8), seam);
  }

  canvas.restore();
}

void _paintGoogleG(Canvas canvas, Color color, {required bool multicolor}) {
  const center = Offset(12.0, 12.0);
  const radius = 7.4;
  const stroke = 3.6;

  if (!multicolor) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.68,
      5.55,
      false,
      p,
    );
    canvas.drawLine(
      const Offset(12.0, 12.0),
      const Offset(19.6, 12.0),
      p..strokeWidth = 3.2,
    );
    return;
  }

  final rect = Rect.fromCircle(center: center, radius: radius);
  Paint arcPaint(Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.butt
    ..isAntiAlias = true;

  // Red top-left arc
  canvas.drawArc(rect, -2.52, 1.84, false, arcPaint(const Color(0xFFEA4335)));
  // Yellow left arc
  canvas.drawArc(rect, 2.52, 1.26, false, arcPaint(const Color(0xFFFBBC05)));
  // Green bottom arc
  canvas.drawArc(rect, 0.76, 1.78, false, arcPaint(const Color(0xFF34A853)));
  // Blue bottom-right arc
  canvas.drawArc(rect, -0.02, 0.80, false, arcPaint(const Color(0xFF4285F4)));

  // Blue horizontal crossbar
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(12.0, 10.35, 7.6, 3.3),
      const Radius.circular(1.0),
    ),
    Paint()
      ..color = const Color(0xFF4285F4)
      ..isAntiAlias = true,
  );
}

/// Widget wrapper rendering a [BrandIconKind] cleanly at [size].
class BrandVectorIcon extends StatelessWidget {
  const BrandVectorIcon(
    this.kind, {
    super.key,
    this.size = 18,
    this.color = Colors.black,
    this.multicolor = false,
  });

  final BrandIconKind kind;
  final double size;
  final Color color;
  final bool multicolor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandIconPainter(
          kind: kind,
          color: color,
          multicolor: multicolor,
        ),
      ),
    );
  }
}

class _BrandIconPainter extends CustomPainter {
  const _BrandIconPainter({
    required this.kind,
    required this.color,
    required this.multicolor,
  });

  final BrandIconKind kind;
  final Color color;
  final bool multicolor;

  @override
  void paint(Canvas canvas, Size size) {
    paintBrandIcon(
      canvas,
      Offset.zero & size,
      kind,
      color: color,
      multicolor: multicolor,
    );
  }

  @override
  bool shouldRepaint(_BrandIconPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.color != color ||
      oldDelegate.multicolor != multicolor;
}
