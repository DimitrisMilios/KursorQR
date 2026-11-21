import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/qr_link.dart';
import '../../viewmodels/dashboard_viewmodel.dart';

/// Modal form to create or edit a dynamic QR link (delegates writes to DashboardViewModel).
class QrLinkFormDialog extends StatefulWidget {
  const QrLinkFormDialog({
    super.key,
    required this.dashboardViewModel,
    this.existing,
  });

  final DashboardViewModel dashboardViewModel;
  final QrLink? existing;

  @override
  State<QrLinkFormDialog> createState() => _QrLinkFormDialogState();
}

class _QrLinkFormDialogState extends State<QrLinkFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _slugController;
  late final TextEditingController _titleController;
  late final TextEditingController _webUrlController;
  late final TextEditingController _iosUrlController;
  late final TextEditingController _androidUrlController;

  late bool _isActive;
  bool _isSaving = false;
  String? _errorText;

  bool get _isEditing => widget.existing != null;

  static String _generateRandomSlug() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final rng = Random.secure();
    return List.generate(7, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _slugController = TextEditingController(
      text: existing?.slug ?? _generateRandomSlug(),
    );
    _titleController = TextEditingController(text: existing?.title ?? '');
    _webUrlController = TextEditingController(text: existing?.webUrl ?? '');
    _iosUrlController = TextEditingController(text: existing?.iosUrl ?? '');
    _androidUrlController = TextEditingController(text: existing?.androidUrl ?? '');
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _slugController.dispose();
    _titleController.dispose();
    _webUrlController.dispose();
    _iosUrlController.dispose();
    _androidUrlController.dispose();
    super.dispose();
  }

  String? _validateRequiredUrl(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return 'Fallback Web URL is required';
    if (!RegExp(r'^https?:\/\/.+', caseSensitive: false).hasMatch(trimmed)) {
      return 'Must start with https:// or http://';
    }
    if (trimmed.length > 2048) return 'URL is too long (max 2048 characters)';
    return null;
  }

  String? _validateOptionalStoreUrl(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (!RegExp(
      r'^(https?:\/\/|itms-apps:\/\/|market:\/\/).+',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return 'Must start with https://, http://, itms-apps://, or market://';
    }
    if (trimmed.length > 2048) return 'URL is too long (max 2048 characters)';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final slug = _slugController.text.trim().toLowerCase();

    try {
      if (_isEditing) {
        await widget.dashboardViewModel.updateLink(
          slug: slug,
          title: _titleController.text,
          webUrl: _webUrlController.text,
          iosUrl: _iosUrlController.text,
          androidUrl: _androidUrlController.text,
          isActive: _isActive,
        );
      } else {
        await widget.dashboardViewModel.createLink(
          slug: slug,
          title: _titleController.text,
          webUrl: _webUrlController.text,
          iosUrl: _iosUrlController.text,
          androidUrl: _androidUrlController.text,
          isActive: _isActive,
        );
      }

      if (mounted) Navigator.of(context).pop(slug);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Dynamic QR Link' : 'Create Dynamic QR Link'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                TextFormField(
                  controller: _slugController,
                  enabled: !_isEditing,
                  decoration: InputDecoration(
                    labelText: 'Short Link Slug',
                    hintText: 'e.g. my-app',
                    prefixText: 'kursorqr.web.app/r/',
                    suffixIcon: _isEditing
                        ? null
                        : IconButton(
                            tooltip: 'Generate random unique slug',
                            onPressed: () => setState(
                              () => _slugController.text = _generateRandomSlug(),
                            ),
                            icon: const Icon(Icons.shuffle_rounded),
                          ),
                    helperText: _isEditing
                        ? 'Short link path is permanent so printed QR codes never break.'
                        : 'Lowercase a-z, 0-9, "-" or "_" (1–64 chars).',
                  ),
                  validator: (value) {
                    final slug = value?.trim().toLowerCase() ?? '';
                    if (slug.isEmpty) return 'Slug is required';
                    if (!RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$').hasMatch(slug)) {
                      return 'Use 1–64 chars: lowercase a-z, 0-9, "-" or "_"';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleController,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Campaign / Link Name',
                    hintText: 'e.g. App Store Launch Poster',
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a display name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _webUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Fallback Web URL (Required)',
                    hintText: 'https://yourdomain.com/download',
                    prefixIcon: Icon(Icons.language_rounded),
                  ),
                  validator: _validateRequiredUrl,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _iosUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'iOS App Store URL (Optional)',
                    hintText: 'https://apps.apple.com/app/id000000000',
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                  ),
                  validator: _validateOptionalStoreUrl,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _androidUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Android Play Store URL (Optional)',
                    hintText:
                        'https://play.google.com/store/apps/details?id=com.example.app',
                    prefixIcon: Icon(Icons.android_rounded),
                  ),
                  validator: _validateOptionalStoreUrl,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text(
                    'Turn off to pause redirection without deleting your QR code.',
                  ),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save Changes' : 'Create Link'),
        ),
      ],
    );
  }
}
