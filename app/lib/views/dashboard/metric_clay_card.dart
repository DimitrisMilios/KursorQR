import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/clay_asset_icon.dart';

/// Dashboard KPI metric card with a 3D Blender clay icon and tabular numeral.
class MetricClayCard extends StatelessWidget {
  const MetricClayCard({
    super.key,
    required this.label,
    required this.value,
    required this.asset,
    required this.fallbackIcon,
  });

  final String label;
  final String value;
  final String asset;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppDimensions.radiusClay,
      padding: const EdgeInsets.all(18),
      lift: 14,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: const ClayDecoration.well(
              radius: AppDimensions.radiusClaySm,
              depth: 4,
            ),
            child: ClayAssetIcon(
              asset: asset,
              fallbackIcon: fallbackIcon,
              size: 34,
              wobbleOnHover: true,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClayLabel(label),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
