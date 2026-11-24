import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_dimensions.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/clay/clay.dart';
import '../widgets/shared/ambient_background.dart';
import '../widgets/shared/clay_asset_icon.dart';
import 'dialogs/gdpr_policy_dialog.dart';

/// Claymorphism email verification gate shown to newly registered
/// Email/Password accounts before entering the Dashboard workspace.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key, required this.authViewModel});

  final AuthViewModel authViewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authViewModel,
      builder: (context, _) {
        final email = authViewModel.user?.email ?? 'your email address';

        return Scaffold(
          body: AmbientBackground(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ClayPanel(
                    radius: AppDimensions.radiusClayLg,
                    padding: const EdgeInsets.all(34),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 104,
                            height: 104,
                            alignment: Alignment.center,
                            decoration: const ClayDecoration.well(
                              radius: AppDimensions.radiusClay,
                              depth: 5,
                            ),
                            child: const ClayAssetIcon(
                              asset: 'assets/clay/verify_envelope.png',
                              fallbackIcon: Icons.mark_email_unread_rounded,
                              size: 80,
                              wobbleOnHover: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Verify your email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'We sent a verification link to $email. Open the link '
                          'to activate your free KursorQR workspace (up to '
                          '${AppConfig.maxQrLinksPerAccount} dynamic QR links).',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppDimensions.fontMd,
                            fontWeight: FontWeight.w500,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (authViewModel.errorMessage != null) ...[
                          ClayWell.coral(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              authViewModel.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.coralDeep,
                                fontSize: AppDimensions.fontBody,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (authViewModel.infoMessage != null) ...[
                          ClayWell.mint(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              authViewModel.infoMessage!,
                              style: const TextStyle(
                                color: AppColors.primaryDeep,
                                fontSize: AppDimensions.fontBody,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ClayButton.primary(
                          label: "I've verified",
                          busyLabel: 'Checking...',
                          icon: Icons.check_circle_outline_rounded,
                          size: ClayButtonSize.large,
                          expand: true,
                          busy: authViewModel.isBusy,
                          onPressed: authViewModel.isBusy
                              ? null
                              : authViewModel.checkEmailVerificationStatus,
                        ),
                        const SizedBox(height: 12),
                        ClayButton.neutral(
                          label: 'Resend email',
                          icon: Icons.send_rounded,
                          expand: true,
                          onPressed: authViewModel.isBusy
                              ? null
                              : authViewModel.resendVerificationEmail,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ClayButton.text(
                              label: 'Privacy & cookies',
                              size: ClayButtonSize.compact,
                              onPressed: () => showClayDialog<void>(
                                context: context,
                                builder: (_) => const GdprPolicyDialog(),
                              ),
                            ),
                            ClayButton.text(
                              label: 'Sign out',
                              icon: Icons.logout_rounded,
                              size: ClayButtonSize.compact,
                              danger: true,
                              onPressed: authViewModel.isBusy
                                  ? null
                                  : authViewModel.signOut,
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
        );
      },
    );
  }
}
