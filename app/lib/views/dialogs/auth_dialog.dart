import 'package:flutter/material.dart';

import '../../viewmodels/auth_viewmodel.dart';
import 'gdpr_policy_dialog.dart';

/// Public Sign-In & Free Account Registration modal (Google + Email/Password).
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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late bool _isSignUp;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
    widget.authViewModel.clearMessages();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onGoogle() async {
    final ok = await widget.authViewModel.signInWithGoogle();
    if (ok && mounted) Navigator.of(context).pop();
  }

  Future<void> _onEmailSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = _isSignUp
        ? await widget.authViewModel.signUpWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          )
        : await widget.authViewModel.signInWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );
    if (ok && mounted) Navigator.of(context).pop();
  }

  Future<void> _onForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Enter your email address first to reset your password.'),
          ),
        );
      return;
    }
    await widget.authViewModel.sendPasswordReset(email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = widget.authViewModel;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isSignUp ? 'Create Free Account' : 'Sign In to KursorQR',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: SizedBox(
            width: 410,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Sign In')),
                      ButtonSegment(value: true, label: Text('Create Account')),
                    ],
                    selected: {_isSignUp},
                    onSelectionChanged: (sel) {
                      setState(() => _isSignUp = sel.first);
                      vm.clearMessages();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (vm.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        vm.errorMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                  if (vm.infoMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        vm.infoMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                  FilledButton.icon(
                    onPressed: vm.isBusy ? null : _onGoogle,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Continue with Google (Instant)'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or with email',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: (v) {
                            final trimmed = v?.trim() ?? '';
                            if (trimmed.isEmpty || !trimmed.contains('@')) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: _isSignUp
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          onFieldSubmitted: (_) => _onEmailSubmit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your password';
                            }
                            if (_isSignUp && v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        if (_isSignUp) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Email sign-ups receive a quick verification link to prevent bot abuse on the free plan. Each free account includes up to 10 dynamic QR codes.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ] else
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: vm.isBusy ? null : _onForgotPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                        OutlinedButton(
                          onPressed: vm.isBusy ? null : _onEmailSubmit,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: vm.isBusy
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_isSignUp ? 'Create Free Account' : 'Sign In'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const GdprPolicyDialog(),
                      ),
                      icon: const Icon(Icons.shield_outlined, size: 16),
                      label: const Text('GDPR Privacy & Cookie Disclosure'),
                    ),
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
