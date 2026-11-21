import 'package:flutter/material.dart';

/// Comprehensive GDPR Privacy Policy & Cookie Transparency Disclosure dialog.
class GdprPolicyDialog extends StatelessWidget {
  const GdprPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.verified_user_rounded, color: Colors.green.shade700),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'GDPR Privacy & Cookie Transparency',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cookie_outlined, color: Colors.green.shade800),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Zero advertising cookies, zero analytics cookies, zero third-party trackers, and zero IP logging — by architecture.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _PolicySection(
                title: '1. For People Scanning QR Codes (/r/<slug>)',
                bullets: const [
                  'Zero cookies, zero localStorage, zero sessionStorage, and zero IndexedDB writes.',
                  'Zero IP addresses, zero device fingerprints, and zero User-Agent strings are stored.',
                  'OS detection (iOS vs. Android vs. Web) executes ephemerally in memory solely to choose the correct App Store / Play Store / Web destination.',
                  'Only three anonymous aggregate integer counters are incremented: totalScans, iosScans, and androidScans.',
                  'Referrer-Policy is set to "no-referrer" so redirect handoffs never leak scan origin details.',
                ],
                theme: theme,
              ),
              _PolicySection(
                title: '2. For KursorQR Account Holders (kursorqr.web.app)',
                bullets: const [
                  'Strictly Necessary Session Storage (ePrivacy Art. 5(3) exempt): When you sign in, Firebase Authentication uses essential browser session storage solely to keep you logged into your dashboard.',
                  'Data Stored in EU Cloud Firestore (eur3): Your Firebase user ID, your dynamic QR slugs/URLs, optional QR visual styling (colors, gradient, built-in icon ID), and anonymous scan counters.',
                  'Custom Uploaded Logos: Processed 100% locally in your browser memory to generate PNG exports — NEVER uploaded to our servers or Cloud Storage.',
                  'Sub-processor: Google Firebase (Hosting, Authentication, EU Cloud Firestore).',
                ],
                theme: theme,
              ),
              _PolicySection(
                title: '3. Your GDPR Rights (Articles 15–20)',
                bullets: const [
                  'Right of Access & Portability (Art. 15 & 20): Export all your account QR links, styles, and anonymous counters anytime as JSON from Account & Privacy Settings.',
                  'Right to Rectification (Art. 16): Edit or pause any QR destination immediately from your dashboard.',
                  'Right to Erasure (Art. 17): Permanently delete individual QR codes or wipe your entire account, quota ledger, and all links in one click from Account & Privacy Settings.',
                ],
                theme: theme,
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.bullets,
    required this.theme,
  });

  final String title;
  final List<String> bullets;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(fontWeight: FontWeight.w700)),
                  Expanded(
                    child: Text(
                      bullet,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
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
