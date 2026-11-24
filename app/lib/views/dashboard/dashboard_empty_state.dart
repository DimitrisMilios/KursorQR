import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/clay_asset_icon.dart';

/// Empty dashboard illustration panel with 3D Blender clay artwork.
class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({super.key, required this.onCreateLink});

  final VoidCallback onCreateLink;

  @override
  Widget build(BuildContext context) {
    return ClayPanel(
      radius: AppDimensions.radiusClayLg,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ClayAssetIcon(
            asset: 'assets/clay/empty_qr_links.png',
            fallbackIcon: Icons.qr_code_2_rounded,
            size: 168,
            wobbleOnHover: true,
          ),
          const SizedBox(height: 18),
          const Text(
            'Create your first QR link',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: const Text(
              'Style with gradients and center icons, route iOS, Android, and web '
              'automatically, and track anonymous scan counts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppDimensions.fontMd,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ClayButton.primary(
            label: 'New QR link',
            icon: Icons.add_rounded,
            size: ClayButtonSize.large,
            onPressed: onCreateLink,
          ),
        ],
      ),
    );
  }
}
