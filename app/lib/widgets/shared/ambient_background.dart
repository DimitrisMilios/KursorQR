import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Flat warm sand page canvas with a 2% seamless paper grain overlay.
///
/// Uses `Image.opacity` directly on the image draw inside a [RepaintBoundary]
/// so no offscreen compositing layer is allocated per frame. Safe if the grain
/// asset is absent.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.grain = true,
    this.color = AppColors.sand,
  });

  static const String grainAsset = 'assets/clay/grain_tile.png';

  final Widget child;
  final bool grain;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: color),
        if (grain)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: Image.asset(
                  grainAsset,
                  repeat: ImageRepeat.repeat,
                  opacity: const AlwaysStoppedAnimation(0.02),
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}
