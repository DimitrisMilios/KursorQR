import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/clay/clay.dart';
import 'hero_qr_render.dart';

/// Two-column claymorphism Hero section: calm editorial copy & CTAs left,
/// interactive 3D Blender clay QR + phones composition right.
class LandingHeroSection extends StatelessWidget {
  const LandingHeroSection({
    super.key,
    required this.onCreateAccount,
    required this.onTrySandbox,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onTrySandbox;

  static const double _twoColumnBreakpoint = 940;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _twoColumnBreakpoint;
        final copy = _HeroCopy(
          centered: !wide,
          onCreateAccount: onCreateAccount,
          onTrySandbox: onTrySandbox,
        );

        if (wide) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: copy),
                const SizedBox(width: 36),
                const Expanded(flex: 6, child: HeroQrRender()),
              ],
            ),
          );
        }

        return Column(
          children: [
            const SizedBox(height: 12),
            copy,
            const SizedBox(height: 28),
            const FractionallySizedBox(
              widthFactor: 0.78,
              child: HeroQrRender(),
            ),
          ],
        );
      },
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.centered,
    required this.onCreateAccount,
    required this.onTrySandbox,
  });

  final bool centered;
  final VoidCallback onCreateAccount;
  final VoidCallback onTrySandbox;

  @override
  Widget build(BuildContext context) {
    final align = centered ? TextAlign.center : TextAlign.start;
    final cross = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'One QR code,\nevery app store.',
          textAlign: align,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppDimensions.fontDisplay,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: const Text(
            'Print a branded QR code once, then update destinations anytime. '
            'Route iOS to the App Store, Android to Google Play, and desktop to '
            'your site — free for ${AppConfig.maxQrLinksPerAccount} dynamic links, '
            'open source, and zero tracking cookies.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: AppDimensions.spacingLg,
          runSpacing: AppDimensions.spacingMd,
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ClayButton.primary(
              label: 'Create free account',
              icon: Icons.arrow_forward_rounded,
              size: ClayButtonSize.large,
              ripple: true,
              onPressed: onCreateAccount,
            ),
            ClayButton.text(
              label: 'Try the studio',
              icon: Icons.arrow_downward_rounded,
              onPressed: onTrySandbox,
            ),
          ],
        ),
      ],
    );
  }
}
