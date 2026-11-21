import 'package:flutter/material.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import 'gdpr_policy_dialog.dart';

/// Account & GDPR Data Controls modal (Art. 20 JSON Export + Art. 17 Account Deletion).
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Permanently Delete Account & All Data?'),
        content: const Text(
          'This GDPR Right to Erasure action will immediately and permanently delete:\n\n'
          '• All of your dynamic QR links (printed codes will stop redirecting)\n'
          '• Your quota ledger in Firestore\n'
          '• Your Firebase Authentication account\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
              foregroundColor: Theme.of(dialogCtx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Yes, Erase Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final deleted = await widget.authViewModel.deleteAccountAndAllData();
    if (deleted && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authVm = widget.authViewModel;
    final dashVm = widget.dashboardViewModel;

    return ListenableBuilder(
      listenable: Listenable.merge([authVm, dashVm]),
      builder: (context, _) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.manage_accounts_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Account & GDPR Privacy',
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
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dashVm.ownerEmail,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Chip(
                              avatar: Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              label: const Text('Verified Account'),
                              visualDensity: VisualDensity.compact,
                            ),
                            Chip(
                              avatar: const Icon(Icons.qr_code_2_rounded, size: 16),
                              label: Text(
                                'Free Quota: ${dashVm.usedQuota}/${dashVm.maxQuota}',
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (authVm.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        authVm.errorMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                  Text(
                    'GDPR Data Rights',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: authVm.isBusy
                        ? null
                        : () {
                            dashVm.exportMyDataAsJson();
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text('Exported kursorqr-gdpr-export.json'),
                                ),
                              );
                          },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export My Data as JSON (GDPR Art. 20)'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const GdprPolicyDialog(),
                    ),
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('View Privacy & Cookie Policy'),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 14),
                  Text(
                    'Danger Zone (GDPR Art. 17 Right to Erasure)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Deletes all your QR links, quota ledger, and authentication account permanently.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    onPressed: authVm.isBusy ? null : _confirmAndDeleteAccount,
                    icon: authVm.isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.delete_forever_rounded),
                    label: const Text('Delete My Account & All Data'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
