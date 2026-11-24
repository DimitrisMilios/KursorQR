import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/brand_logo.dart';

/// Floating clay top navbar for the public Landing Page.
class LandingNavbar extends StatelessWidget {
  const LandingNavbar({
    super.key,
    required this.onOpenPrivacy,
    required this.onSignIn,
    required this.onStartFree,
  });

  final VoidCallback onOpenPrivacy;
  final VoidCallback onSignIn;
  final VoidCallback onStartFree;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 8),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
          child: ClayPanel(
            height: AppDimensions.navbarHeight,
            radius: AppDimensions.radiusClayXl,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingXxl,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showWordmark = constraints.maxWidth >= 340;
                final showPrivacy = constraints.maxWidth >= 600;
                final showSignIn = constraints.maxWidth >= 460;
                final showStartLabel = constraints.maxWidth >= 420;

                return Row(
                  children: [
                    const BrandLogo(size: 40, radius: AppDimensions.radiusMd),
                    if (showWordmark) ...[
                      const SizedBox(width: AppDimensions.spacingMd),
                      const Text(
                        AppConfig.appName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppDimensions.fontXl,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (showPrivacy) ...[
                      ClayButton.text(
                        label: 'Privacy',
                        onPressed: onOpenPrivacy,
                      ),
                      const SizedBox(width: AppDimensions.spacingXs),
                    ],
                    if (showSignIn) ...[
                      ClayButton.text(
                        label: 'Sign in',
                        onPressed: onSignIn,
                      ),
                      const SizedBox(width: AppDimensions.spacingSm),
                    ],
                    if (showStartLabel)
                      ClayButton.gold(
                        label: 'Start free',
                        icon: Icons.rocket_launch_rounded,
                        onPressed: onStartFree,
                      )
                    else
                      ClayIconButton(
                        icon: Icons.rocket_launch_rounded,
                        tooltip: 'Start free',
                        color: AppColors.gold,
                        size: 44,
                        radius: 22,
                        onPressed: onStartFree,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
