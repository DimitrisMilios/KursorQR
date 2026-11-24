import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/clay_asset_icon.dart';
import 'confirm_danger_dialog.dart';
import 'gdpr_policy_dialog.dart';

/// Account & GDPR Data Controls modal (Art. 20 JSON Export + Art. 17 Erasure).
class AccountSettingsDialog extends StatefulWidget {
  const AccountSettingsDialog({
    super.key,
    required this.authViewModel,
    required this.dashboardViewModel,
  });

  final AuthViewModel authViewModel;
  final DashboardViewModel dashboardViewModel;

  @override
  State<AccountSettingsDialog> createState() => _AccountSettingsDialogState();
}

class _AccountSettingsDialogState extends State<AccountSettingsDialog> {
  Future<void> _confirmAndDeleteAccount() async {
    final confirmed = await showClayDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDangerDialog(
        title: 'Erase account and all data',
        message:
            'This GDPR Right to Erasure action permanently deletes:\n\n'
            '• All of your dynamic QR links (printed codes will stop redirecting)\n'
            '• Your quota ledger in EU Cloud Firestore\n'
            '• Your Firebase Authentication account\n\n'
            'This cannot be undone.',
        confirmLabel: 'Erase everything',
      ),
    );
    if (confirmed != true || !mounted) return;

    final deleted = await widget.authViewModel.deleteAccountAndAllData();
    if (deleted && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = widget.authViewModel;
    final dashVm = widget.dashboardViewModel;

    return ListenableBuilder(
      listenable: Listenable.merge([authVm, dashVm]),
      builder: (context, _) {
        return ClayDialog(
          width: 500,
          title: 'Account & GDPR privacy',
          subtitle: 'Export your data or erase your account anytime.',
          headerIcon: const ClayAssetIcon(
            asset: 'assets/clay/icon_account.png',
            fallbackIcon: Icons.manage_accounts_rounded,
            size: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Account metadata well (replaces bordered card + Material Chips)
              ClayWell(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dashVm.ownerEmail,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 18,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.sage,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Verified account',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: AppDimensions.fontSm,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.qr_code_2_rounded,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Free quota ${dashVm.usedQuota} / ${dashVm.maxQuota}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: AppDimensions.fontSm,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (authVm.errorMessage != null) ...[
                ClayWell.coral(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    authVm.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.coralDeep,
                      fontSize: AppDimensions.fontBody,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const ClayLabel(
                'GDPR Data Rights',
                padding: EdgeInsets.only(left: 4, bottom: 10),
              ),
              ClayButton.neutral(
                label: 'Export data as JSON (Art. 20)',
                icon: Icons.download_rounded,
                expand: true,
                onPressed: authVm.isBusy
                    ? null
                    : () {
                        dashVm.exportMyDataAsJson();
                        ClayToast.show(
                          context,
                          'Exported kursorqr-gdpr-export.json',
                        );
                      },
              ),
              const SizedBox(height: 10),
              ClayButton.neutral(
                label: 'View privacy & cookie policy',
                icon: Icons.shield_outlined,
                expand: true,
                onPressed: () => showClayDialog<void>(
                  context: context,
                  builder: (_) => const GdprPolicyDialog(),
                ),
              ),
              const SizedBox(height: 22),
              ClayWell.coral(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ClayLabel(
                      'Danger Zone · GDPR Art. 17 Right to Erasure',
                      color: AppColors.coralDeep,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Deletes all your QR links, quota ledger, and authentication account permanently.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppDimensions.fontSm,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClayButton.danger(
                      label: 'Delete account and all data',
                      busyLabel: 'Erasing...',
                      icon: Icons.delete_forever_rounded,
                      expand: true,
                      busy: authVm.isBusy,
                      onPressed: authVm.isBusy ? null : _confirmAndDeleteAccount,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
