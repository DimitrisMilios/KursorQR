import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/clay_asset_icon.dart';

/// Floating spring-animated clay GDPR transparency banner (replaces dark bar).
class GdprFloatingBanner extends StatelessWidget {
  const GdprFloatingBanner({
    super.key,
    required this.visible,
    required this.onOpenPolicy,
    required this.onDismiss,
  });

  final bool visible;
  final VoidCallback onOpenPolicy;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: TickerMode(
        enabled: visible,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 360),
          curve: ClaySpringCurve.gentle,
          offset: visible ? Offset.zero : const Offset(0, 1.35),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: visible ? 1 : 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppDimensions.maxContentWidth,
                    ),
                    child: ClayPanel(
                      radius: AppDimensions.radiusClay,
                      lift: 16,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClayAssetIcon(
                                asset: 'assets/clay/feature_gdpr.png',
                                fallbackIcon: Icons.verified_user_rounded,
                                size: 30,
                              ),
                              SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'Zero tracking cookies · Zero IP logging. QR scans store no personal data; essential session storage is used only when you sign in.',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: AppDimensions.fontBody,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClayButton.text(
                                label: 'Privacy & cookies',
                                size: ClayButtonSize.compact,
                                onPressed: onOpenPolicy,
                              ),
                              const SizedBox(width: 8),
                              ClayButton.neutral(
                                label: 'Got it',
                                size: ClayButtonSize.compact,
                                onPressed: onDismiss,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
