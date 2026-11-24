import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../clay/jelly_transform.dart';

/// DPR-aware, cached 3D Blender clay icon with graceful Material icon fallback
/// and optional hover rotate wobble.
class ClayAssetIcon extends StatefulWidget {
  const ClayAssetIcon({
    super.key,
    required this.asset,
    required this.fallbackIcon,
    this.size = 40,
    this.fallbackColor = AppColors.primary,
    this.wobbleOnHover = false,
    this.semanticLabel,
  });

  final String asset;
  final IconData fallbackIcon;
  final double size;
  final Color fallbackColor;
  final bool wobbleOnHover;
  final String? semanticLabel;

  @override
  State<ClayAssetIcon> createState() => _ClayAssetIconState();
}

class _ClayAssetIconState extends State<ClayAssetIcon> {
  final JellyController _jelly = JellyController();

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final decodePx = math.min((widget.size * dpr).round(), (widget.size * 2).round());

    Widget img = Image.asset(
      widget.asset,
      width: widget.size,
      height: widget.size,
      cacheWidth: decodePx > 0 ? decodePx : null,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: widget.semanticLabel,
      errorBuilder: (_, __, ___) => Icon(
        widget.fallbackIcon,
        size: widget.size * 0.62,
        color: widget.fallbackColor,
      ),
    );

    if (!widget.wobbleOnHover) return img;

    return MouseRegion(
      onEnter: (_) => _jelly.wobble(radians: 0.1),
      child: JellyTransform(
        controller: _jelly,
        child: img,
      ),
    );
  }
}
