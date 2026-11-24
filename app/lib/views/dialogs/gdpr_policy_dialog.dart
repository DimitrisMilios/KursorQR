import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/clay_asset_icon.dart';

/// Claymorphism GDPR Privacy Policy & Cookie Transparency disclosure dialog.
class GdprPolicyDialog extends StatelessWidget {
  const GdprPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ClayDialog(
      width: 640,
      title: 'GDPR Privacy & Cookie Transparency',
      subtitle: 'Privacy by architecture — zero cookies, zero IP logging.',
      headerIcon: const ClayAssetIcon(
        asset: 'assets/clay/icon_shield.png',
        fallbackIcon: Icons.verified_user_rounded,
        size: 32,
      ),
      actions: [
        ClayButton.primary(
          label: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClayWell.mint(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.cookie_outlined,
                  color: AppColors.primaryDeep,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Zero advertising cookies, zero analytics cookies, zero third-party trackers, and zero IP logging — by architecture.',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDeep,
                      fontSize: AppDimensions.fontBody,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          _PolicySection(
            title: '1. For People Scanning QR Codes (/r/<slug>)',
            bullets: [
              'Zero cookies, zero localStorage, zero sessionStorage, and zero IndexedDB writes.',
              'Zero IP addresses, zero device fingerprints, and zero User-Agent strings are stored.',
              'OS detection (iOS vs. Android vs. Web) executes ephemerally in memory solely to choose the correct App Store, Play Store, or web destination.',
              'Only three anonymous aggregate integer counters are incremented: totalScans, iosScans, and androidScans.',
              'Referrer-Policy is set to "no-referrer" so redirect handoffs never leak scan origin details.',
            ],
          ),
          _PolicySection(
            title: '2. For KursorQR Account Holders (kursorqr.web.app)',
            bullets: [
              'Strictly Necessary Session Storage (ePrivacy Art. 5(3) exempt): When you sign in, Firebase Authentication uses essential browser session storage solely to keep you logged into your dashboard.',
              'Data Stored in EU Cloud Firestore (eur3): Your Firebase user ID, your dynamic QR slugs and URLs, optional QR visual styling (colors, gradient, built-in icon ID), and anonymous scan counters.',
              'Custom Uploaded Logos: Processed 100% locally in your browser memory to generate PNG exports — never uploaded to our servers or Cloud Storage.',
              'Sub-processor: Google Firebase (Hosting, Authentication, EU Cloud Firestore).',
            ],
          ),
          _PolicySection(
            title: '3. Your GDPR Rights (Articles 15–20)',
            bullets: [
              'Right of Access & Portability (Art. 15 & 20): Export all your account QR links, styles, and anonymous counters anytime as JSON from Account & Privacy Settings.',
              'Right to Rectification (Art. 16): Edit or pause any QR destination immediately from your dashboard.',
              'Right to Erasure (Art. 17): Permanently delete individual QR codes or wipe your entire account, quota ledger, and all links in one click from Account & Privacy Settings.',
            ],
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.bullets});

  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppDimensions.fontMd,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 10),
                    child: SizedBox(
                      width: 6,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      bullet,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppDimensions.fontBody,
                        fontWeight: FontWeight.w500,
                        height: 1.48,
                      ),
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
