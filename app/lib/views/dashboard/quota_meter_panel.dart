import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/clay/clay.dart';

/// Tactile 10-QR free quota meter using [ClayProgressBar] and tabular figures.
class QuotaMeterPanel extends StatelessWidget {
  const QuotaMeterPanel({
    super.key,
    required this.usedQuota,
    required this.maxQuota,
    required this.progress,
    required this.isReached,
  });

  final int usedQuota;
  final int maxQuota;
  final double progress;
  final bool isReached;

  @override
  Widget build(BuildContext context) {
    final fillColor = isReached
        ? AppColors.coral
        : usedQuota >= (maxQuota - 2)
            ? AppColors.goldDeep
            : AppColors.primary;

    return ClayPanel(
      width: 264,
      radius: AppDimensions.radiusClay,
      lift: 12,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ClayLabel('Free Quota'),
              Text(
                '$usedQuota / $maxQuota',
                style: TextStyle(
                  color: fillColor,
                  fontSize: AppDimensions.fontMd,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClayProgressBar(
            value: progress,
            height: 12,
            fillColor: fillColor,
          ),
        ],
      ),
    );
  }
}
