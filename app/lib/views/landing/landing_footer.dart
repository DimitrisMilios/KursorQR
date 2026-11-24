import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/clay/clay.dart';

/// Clean borderless claymorphism footer with editorial spacing.
class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key, required this.onOpenPrivacy});

  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 84),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          const Text(
            'KursorQR · free, open source, zero tracking · EU Cloud Firestore',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: AppDimensions.fontBody,
              fontWeight: FontWeight.w600,
            ),
          ),
          ClayButton.text(
            label: 'Privacy & cookie policy',
            icon: Icons.shield_outlined,
            size: ClayButtonSize.compact,
            onPressed: onOpenPrivacy,
          ),
        ],
      ),
    );
  }
}
