import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../clay/clay_decoration.dart';
import 'clay_asset_icon.dart';

/// KursorQR 3D clay emblem seated inside a floating clay tile, Hero-tagged so
/// it glides smoothly between the Landing and Dashboard navbars.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 42,
    this.radius = AppDimensions.radiusMd,
    this.hero = true,
  });

  static const String logoAsset = 'assets/clay/kursorqr_logo_3d.png';
  static const String heroTag = 'kursorqr-brand-logo';

  final double size;
  final double radius;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      alignment: Alignment.center,
      decoration: ClayDecoration(
        color: AppColors.primaryDeep,
        radius: radius,
        depth: 4,
        lift: 8,
        shadowOpacity: 0.22,
        highlightColor: AppColors.primaryLight,
        highlightOpacity: 0.45,
        shadeColor: AppColors.primaryDeep,
        shadeOpacity: 0.5,
      ),
      child: ClayAssetIcon(
        asset: logoAsset,
        fallbackIcon: Icons.qr_code_2_rounded,
        fallbackColor: AppColors.gold,
        size: size * 0.84,
        semanticLabel: 'KursorQR logo',
      ),
    );

    if (!hero) return tile;
    return Hero(tag: heroTag, child: tile);
  }
}
