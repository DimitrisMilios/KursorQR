import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/clay_asset_icon.dart';

/// Floating spring-animated clay GDPR transparency banner (replaces dark bar).
///
/// Slides down and fades out smoothly on dismiss, then unmounts completely so
/// zero hit targets or GPU layers remain once dismissed.
class GdprFloatingBanner extends StatefulWidget {
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
  State<GdprFloatingBanner> createState() => _GdprFloatingBannerState();
}

class _GdprFloatingBannerState extends State<GdprFloatingBanner> {
  bool _removed = false;

  @override
  void didUpdateWidget(GdprFloatingBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && _removed) {
      _removed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _removed) return const SizedBox.shrink();

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClayButton.text(
          label: 'Privacy & cookies',
          size: ClayButtonSize.compact,
          onPressed: widget.onOpenPolicy,
        ),
        const SizedBox(width: 8),
        ClayButton.neutral(
          label: 'Got it',
          size: ClayButtonSize.compact,
          onPressed: widget.onDismiss,
        ),
      ],
    );

    const message = Row(
      children: [
        ClayAssetIcon(
          asset: 'assets/clay/feature_gdpr.png',
          fallbackIcon: Icons.verified_user_rounded,
          size: 30,
        ),
        SizedBox(width: 12),
        Expanded(
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
    );

    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOutCubic,
        offset: widget.visible ? Offset.zero : const Offset(0, 1.35),
        onEnd: () {
          if (!widget.visible && mounted) {
            setState(() => _removed = true);
          }
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: widget.visible ? 1 : 0,
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 700) {
                          return Row(
                            children: [
                              const Expanded(child: message),
                              const SizedBox(width: 16),
                              actions,
                            ],
                          );
                        }
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            message,
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: actions,
                            ),
                          ],
                        );
                      },
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
