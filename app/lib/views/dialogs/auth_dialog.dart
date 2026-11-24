import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../viewmodels/auth_form_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/brand_logo.dart';
import 'gdpr_policy_dialog.dart';

/// Claymorphism Sign-In & Free Account modal strictly bound to [AuthFormViewModel].
class AuthDialog extends StatefulWidget {
  const AuthDialog({
    super.key,
    required this.authViewModel,
    this.initialIsSignUp = false,
  });

  final AuthViewModel authViewModel;
  final bool initialIsSignUp;

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  late final AuthFormViewModel _formVm;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _formVm = AuthFormViewModel(
      authViewModel: widget.authViewModel,
      initialIsSignUp: widget.initialIsSignUp,
    );
  }

  @override
  void dispose() {
    _formVm.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onGoogle() async {
    final ok = await _formVm.submitGoogle();
    if (ok && mounted) Navigator.of(context).pop();
  }

  Future<void> _onEmailSubmit() async {
    final ok = await _formVm.submitEmail();
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.authViewModel, _formVm]),
      builder: (context, _) {
        return ClayDialog(
          width: 450,
          title: _formVm.isSignUp
              ? 'Create free account'
              : 'Sign in to KursorQR',
          subtitle: _formVm.isSignUp
              ? 'Includes ${AppConfig.maxQrLinksPerAccount} free dynamic QR links.'
              : 'Welcome back to your workspace.',
          headerIcon: const BrandLogo(size: 36, radius: 10, hero: false),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClaySegmented<bool>(
                expand: true,
                selected: _formVm.isSignUp,
                puckColor: AppColors.gold,
                selectedForeground: AppColors.textPrimary,
                onChanged: _formVm.setSignUpMode,
                segments: const [
                  ClaySegment(value: false, label: 'Sign in'),
                  ClaySegment(value: true, label: 'Create account'),
                ],
              ),
              const SizedBox(height: 18),
              if (_formVm.errorMessage != null) ...[
                ClayWell.coral(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _formVm.errorMessage!,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontBody,
                      fontWeight: FontWeight.w700,
                      color: AppColors.coralDeep,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (_formVm.infoMessage != null) ...[
                ClayWell.mint(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _formVm.infoMessage!,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontBody,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              ClayButton.gold(
                label: 'Continue with Google',
                icon: Icons.login_rounded,
                expand: true,
                busy: _formVm.isBusy,
                onPressed: _formVm.isBusy ? null : _onGoogle,
              ),
              const SizedBox(height: 18),
              const Center(
                child: ClayLabel('or with email'),
              ),
              const SizedBox(height: 14),
              ClayField(
                controller: _emailController,
                label: 'Email',
                hint: 'you@domain.com',
                errorText: _formVm.emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: _formVm.setEmail,
                prefix: const Icon(
                  Icons.mail_outline_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              ClayField(
                controller: _passwordController,
                label: 'Password',
                hint: _formVm.isSignUp ? 'At least 6 characters' : 'Your password',
                errorText: _formVm.passwordError,
                obscureText: _formVm.obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: _formVm.isSignUp
                    ? const [AutofillHints.newPassword]
                    : const [AutofillHints.password],
                onChanged: _formVm.setPassword,
                onSubmitted: (_) => _onEmailSubmit(),
                prefix: const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                suffix: ClayIconButton(
                  icon: _formVm.obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  flat: true,
                  size: 32,
                  iconSize: 18,
                  onPressed: _formVm.togglePasswordVisibility,
                ),
              ),
              if (_formVm.isSignUp) ...[
                const SizedBox(height: 12),
                const Text(
                  'Email sign-ups receive a quick verification link to prevent bot abuse on the free tier.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
              ] else ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: ClayButton.text(
                    label: 'Forgot password?',
                    size: ClayButtonSize.compact,
                    onPressed: _formVm.isBusy ? null : _formVm.sendPasswordReset,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              ClayButton.primary(
                label: _formVm.isSignUp ? 'Create free account' : 'Sign in',
                busyLabel: 'Please wait...',
                expand: true,
                busy: _formVm.isBusy,
                onPressed: _formVm.isBusy ? null : _onEmailSubmit,
              ),
              const SizedBox(height: 14),
              Center(
                child: ClayButton.text(
                  label: 'GDPR privacy & cookie disclosure',
                  icon: Icons.shield_outlined,
                  size: ClayButtonSize.compact,
                  onPressed: () => showClayDialog<void>(
                    context: context,
                    builder: (_) => const GdprPolicyDialog(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
