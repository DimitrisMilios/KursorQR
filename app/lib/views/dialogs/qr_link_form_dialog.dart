import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/qr_link.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/qr_link_form_viewmodel.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/brand_icons.dart';
import '../../widgets/shared/clay_asset_icon.dart';

/// Claymorphism modal form to create or edit a dynamic QR link, strictly bound
/// to [QrLinkFormViewModel].
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
  late final QrLinkFormViewModel _vm;
  late final TextEditingController _slugController;
  late final TextEditingController _titleController;
  late final TextEditingController _webUrlController;
  late final TextEditingController _iosUrlController;
  late final TextEditingController _androidUrlController;

  @override
  void initState() {
    super.initState();
    _vm = QrLinkFormViewModel(
      dashboardViewModel: widget.dashboardViewModel,
      existing: widget.existing,
    );
    _slugController = TextEditingController(text: _vm.slug);
    _titleController = TextEditingController(text: _vm.title);
    _webUrlController = TextEditingController(text: _vm.webUrl);
    _iosUrlController = TextEditingController(text: _vm.iosUrl);
    _androidUrlController = TextEditingController(text: _vm.androidUrl);
  }

  @override
  void dispose() {
    _vm.dispose();
    _slugController.dispose();
    _titleController.dispose();
    _webUrlController.dispose();
    _iosUrlController.dispose();
    _androidUrlController.dispose();
    super.dispose();
  }

  void _shuffleSlug() {
    final next = _vm.regenerateSlug();
    _slugController.text = next;
  }

  Future<void> _save() async {
    final savedSlug = await _vm.submit();
    if (savedSlug != null && mounted) {
      Navigator.of(context).pop(savedSlug);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return ClayDialog(
          width: 540,
          title: _vm.isEditing ? 'Edit dynamic QR link' : 'New dynamic QR link',
          subtitle: _vm.isEditing
              ? 'Update destinations anytime without reprinting.'
              : 'Set a short slug and optional store redirects.',
          headerIcon: const ClayAssetIcon(
            asset: 'assets/clay/icon_link.png',
            fallbackIcon: Icons.link_rounded,
            size: 32,
          ),
          actions: [
            ClayButton.text(
              label: 'Cancel',
              onPressed: _vm.isSaving ? null : () => Navigator.of(context).pop(),
            ),
            ClayButton.primary(
              label: _vm.isEditing ? 'Save changes' : 'Create link',
              busyLabel: 'Saving...',
              busy: _vm.isSaving,
              onPressed: _vm.isSaving ? null : _save,
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_vm.submitError != null) ...[
                ClayWell.coral(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _vm.submitError!,
                    style: const TextStyle(
                      color: AppColors.coralDeep,
                      fontSize: AppDimensions.fontBody,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ClayField(
                controller: _slugController,
                enabled: !_vm.isEditing,
                label: 'Short link slug',
                hint: 'my-app',
                prefixText: 'kursorqr.web.app/r/',
                monospace: true,
                errorText: _vm.slugError,
                helperText: _vm.isEditing
                    ? 'Slug is permanent so printed QR codes never break.'
                    : 'Lowercase a-z, 0-9, "-" or "_" (1-64 chars).',
                onChanged: _vm.setSlug,
                suffix: _vm.isEditing
                    ? null
                    : ClayIconButton(
                        icon: Icons.shuffle_rounded,
                        tooltip: 'Generate random slug',
                        flat: true,
                        size: 32,
                        iconSize: 18,
                        onPressed: _shuffleSlug,
                      ),
              ),
              const SizedBox(height: 16),
              ClayField(
                controller: _titleController,
                label: 'Campaign / link name',
                hint: 'App Store launch poster',
                maxLength: 120,
                errorText: _vm.titleError,
                onChanged: _vm.setTitle,
              ),
              const SizedBox(height: 16),
              ClayField(
                controller: _webUrlController,
                label: 'Fallback web URL (required)',
                hint: 'https://yourdomain.com/download',
                keyboardType: TextInputType.url,
                errorText: _vm.webUrlError,
                onChanged: _vm.setWebUrl,
                prefix: const Icon(
                  Icons.language_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              ClayField(
                controller: _iosUrlController,
                label: 'iOS App Store URL (optional)',
                hint: 'https://apps.apple.com/app/id000000000',
                keyboardType: TextInputType.url,
                errorText: _vm.iosUrlError,
                onChanged: _vm.setIosUrl,
                prefix: const Center(
                  widthFactor: 1,
                  child: BrandVectorIcon(
                    BrandIconKind.apple,
                    size: 17,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClayField(
                controller: _androidUrlController,
                label: 'Android Play Store URL (optional)',
                hint: 'https://play.google.com/store/apps/details?id=com.example.app',
                keyboardType: TextInputType.url,
                errorText: _vm.androidUrlError,
                onChanged: _vm.setAndroidUrl,
                prefix: const Center(
                  widthFactor: 1,
                  child: BrandVectorIcon(
                    BrandIconKind.googlePlay,
                    size: 16,
                    color: AppColors.textMuted,
                    multicolor: true,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ClayWell(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: ClayToggle(
                  value: _vm.isActive,
                  label: 'Active',
                  subtitle: 'Turn off to pause redirects without deleting the QR.',
                  onChanged: _vm.setActive,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
