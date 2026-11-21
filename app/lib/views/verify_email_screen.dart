import 'package:flutter/material.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'dialogs/gdpr_policy_dialog.dart';

/// Shown to newly registered Email/Password users until they verify their email
/// (matches `firestore.rules` anti-spam guard on the free Spark tier).
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key, required this.authViewModel});

  final AuthViewModel authViewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: authViewModel,
      builder: (context, _) {
        final email = authViewModel.user?.email ?? 'your email address';

        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.mark_email_unread_rounded,
                            color: theme.colorScheme.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Verify Your Email',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We sent a verification link to $email. Click the link '
                          'to activate your free KursorQR workspace (up to 10 dynamic QR codes).',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (authViewModel.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              authViewModel.errorMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                        if (authViewModel.infoMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              authViewModel.infoMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                        FilledButton.icon(
                          onPressed: authViewModel.isBusy
                              ? null
                              : authViewModel.checkEmailVerificationStatus,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: authViewModel.isBusy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline_rounded),
                          label: const Text("I've Verified — Open Dashboard"),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: authViewModel.isBusy
                              ? null
                              : authViewModel.resendVerificationEmail,
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Resend Verification Email'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => const GdprPolicyDialog(),
                              ),
                              child: const Text('Privacy Policy'),
                            ),
                            TextButton.icon(
                              onPressed: authViewModel.isBusy
                                  ? null
                                  : authViewModel.signOut,
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: const Text('Sign Out'),
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
