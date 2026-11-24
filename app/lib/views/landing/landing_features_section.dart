import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/clay_asset_icon.dart';

/// Three staggered clay feature cards backed by 3D Blender clay icons.
class LandingFeaturesSection extends StatelessWidget {
  const LandingFeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _FeatureSpec(
        asset: 'assets/clay/feature_routing.png',
        fallbackIcon: Icons.devices_rounded,
        title: 'Smart store routing',
        description:
            'One QR code detects iOS, Android, or desktop in memory and sends '
            'scanners straight to the App Store, Google Play, or your site.',
      ),
      _FeatureSpec(
        asset: 'assets/clay/feature_studio.png',
        fallbackIcon: Icons.palette_outlined,
        title: 'Gradients & local logos',
        description:
            'Design codes with two-color linear gradients, 16 built-in vector '
            'icons, or your own PNG logo — exported up to 2048 px locally.',
      ),
      _FeatureSpec(
        asset: 'assets/clay/feature_gdpr.png',
        fallbackIcon: Icons.shield_outlined,
        title: 'GDPR-native & free',
        description:
            'Zero cookies, zero IP logging, anonymous aggregate counters only, '
            'EU Cloud Firestore storage, and one-click JSON export or erasure.',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          for (var i = 0; i < items.length; i++)
            ClayStagger(
              index: i,
              child: _FeatureClayCard(spec: items[i]),
            ),
        ];

        if (constraints.maxWidth < 820) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i < cards.length - 1) const SizedBox(height: 18),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 20),
            ],
          ],
        );
      },
    );
  }
}

class _FeatureSpec {
  const _FeatureSpec({
    required this.asset,
    required this.fallbackIcon,
    required this.title,
    required this.description,
  });

  final String asset;
  final IconData fallbackIcon;
  final String title;
  final String description;
}

class _FeatureClayCard extends StatelessWidget {
  const _FeatureClayCard({required this.spec});

  final _FeatureSpec spec;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const ClayDecoration.well(
              radius: AppDimensions.radiusClay,
              depth: 4,
            ),
            child: ClayAssetIcon(
              asset: spec.asset,
              fallbackIcon: spec.fallbackIcon,
              size: 46,
              wobbleOnHover: true,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            spec.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            spec.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppDimensions.fontMd,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
