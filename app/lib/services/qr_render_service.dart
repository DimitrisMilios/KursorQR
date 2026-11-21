import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../core/qr_icon_catalog.dart';
import '../models/qr_design_config.dart';

/// Stateless/cached rendering service for PrettyQR linear gradients, built-in
/// vector center icons, local custom logo badges, and high-res PNG exports.
class QrRenderService {
  final Map<String, Uint8List> _iconBadgeCache = {};

  /// Builds the foreground brush (solid or 2-color linear gradient).
  Color buildForegroundColor(QrDesignConfig design) {
    if (!design.useGradient) return design.fgColor;
    return PrettyQrBrush.gradient(
      gradient: LinearGradient(
        begin: design.gradientDirection.begin,
        end: design.gradientDirection.end,
        colors: [design.fgColor, design.fgColorEnd],
      ),
    );
  }

  /// Renders a built-in Material icon into a crisp 256x256 PNG badge in memory
  /// with a protective background halo so phone cameras scan reliably.
  Future<Uint8List?> renderBuiltInIconBadge(QrDesignConfig design) async {
    final option = QrIconCatalog.findById(design.iconId);
    if (option == null) return null;

    final cacheKey =
        '${option.id}_${design.fgColor.toARGB32()}_${design.fgColorEnd.toARGB32()}_${design.useGradient}_${design.bgColor.toARGB32()}';
    final cached = _iconBadgeCache[cacheKey];
    if (cached != null) return cached;

    const int dim = 256;
    const double size = 256.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    // Outer solid backdrop matching QR background so adjacent modules stay crisp.
    final outerRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, size, size),
      const Radius.circular(60),
    );
    canvas.drawRRect(
      outerRect,
      Paint()
        ..color = design.bgColor
        ..isAntiAlias = true,
    );

    // Inner subtle brand pill.
    final innerRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(18, 18, size - 36, size - 36),
      const Radius.circular(46),
    );
    final innerPaint = Paint()..isAntiAlias = true;
    if (design.useGradient) {
      innerPaint.shader = LinearGradient(
        begin: design.gradientDirection.begin,
        end: design.gradientDirection.end,
        colors: [
          design.fgColor.withValues(alpha: 0.14),
          design.fgColorEnd.withValues(alpha: 0.14),
        ],
      ).createShader(innerRect.outerRect);
    } else {
      innerPaint.color = design.fgColor.withValues(alpha: 0.12);
    }
    canvas.drawRRect(innerRect, innerPaint);

    // Draw the crisp vector icon centered inside the badge.
    final iconColor = design.useGradient
        ? Color.lerp(design.fgColor, design.fgColorEnd, 0.35)!
        : design.fgColor;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(option.icon.codePoint),
        style: TextStyle(
          fontSize: 136,
          fontFamily: option.icon.fontFamily,
          package: option.icon.fontPackage,
          color: iconColor,
        ),
      ),
    )..layout();

    final offset = Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);

    final picture = recorder.endRecording();
    final image = await picture.toImage(dim, dim);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) return null;
    final bytes = byteData.buffer.asUint8List();

    // Keep cache bounded so browser memory stays tiny.
    if (_iconBadgeCache.length > 48) {
      _iconBadgeCache.clear();
    }
    _iconBadgeCache[cacheKey] = bytes;
    return bytes;
  }

  /// Builds a [PrettyQrDecoration] using [design] plus optional center image bytes
  /// (either a rendered built-in icon badge or a locally picked custom logo).
  PrettyQrDecoration buildDecoration({
    required QrDesignConfig design,
    Uint8List? centerImageBytes,
  }) {
    final fg = buildForegroundColor(design);
    final PrettyQrShape shape = switch (design.style) {
      QrModuleStyle.smooth => PrettyQrSmoothSymbol(color: fg),
      QrModuleStyle.dots => PrettyQrDotsSymbol(color: fg),
      QrModuleStyle.squares => PrettyQrSquaresSymbol(color: fg),
    };

    PrettyQrDecorationImage? centerImage;
    if (centerImageBytes != null && centerImageBytes.isNotEmpty) {
      centerImage = PrettyQrDecorationImage(
        image: MemoryImage(centerImageBytes),
        scale: 0.22,
        padding: const EdgeInsets.all(6),
        position: PrettyQrDecorationImagePosition.embedded,
      );
    }

    return PrettyQrDecoration(
      background: design.bgColor,
      quietZone: PrettyQrQuietZone.standard,
      shape: shape,
      image: centerImage,
    );
  }

  /// Exports a print-ready PNG (`512`, `1024`, or `2048` px) including gradients
  /// and embedded center icons/logos.
  Future<Uint8List> exportPngBytes({
    required String data,
    required QrDesignConfig design,
    required int sizePx,
    Uint8List? customLogoBytes,
  }) async {
    final effectiveErrorLevel =
        (customLogoBytes != null || design.iconId.isNotEmpty)
            ? QrErrorCorrectLevel.H
            : design.errorLevel;

    final centerBytes =
        customLogoBytes ?? await renderBuiltInIconBadge(design);

    final decoration = buildDecoration(
      design: design,
      centerImageBytes: centerBytes,
    );

    final qrImage = QrImage(
      QrCode.fromData(
        data: data,
        errorCorrectLevel: effectiveErrorLevel,
      ),
    );

    final byteData = await qrImage.toImageAsBytes(
      size: sizePx,
      format: ui.ImageByteFormat.png,
      decoration: decoration,
    );

    if (byteData == null) {
      throw StateError('QR renderer returned empty PNG bytes.');
    }
    return byteData.buffer.asUint8List();
  }
}
