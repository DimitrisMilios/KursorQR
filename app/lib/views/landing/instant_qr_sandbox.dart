import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/qr_icon_catalog.dart';
import '../../models/qr_design_config.dart';
import '../../viewmodels/landing_viewmodel.dart';
import '../../viewmodels/qr_studio_viewmodel.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/clay_asset_icon.dart';

/// Public no-login instant QR Studio showcase built with tactile clay controls.
class InstantQrSandbox extends StatefulWidget {
  const InstantQrSandbox({
    super.key,
    required this.sandboxVm,
    required this.onMakeDynamic,
  });

  final QrStudioViewModel sandboxVm;
  final VoidCallback onMakeDynamic;

  @override
  State<InstantQrSandbox> createState() => _InstantQrSandboxState();
}

class _InstantQrSandboxState extends State<InstantQrSandbox> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.sandboxVm.data);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _downloadPng() async {
    final fileName = await widget.sandboxVm.downloadPng();
    if (fileName != null && mounted) {
      ClayToast.show(context, 'Downloaded $fileName');
    } else if (widget.sandboxVm.statusError != null && mounted) {
      ClayToast.show(context, widget.sandboxVm.statusError!, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sandboxVm,
      builder: (context, _) {
        final vm = widget.sandboxVm;
        final design = vm.design;
        final previewData = vm.data.trim().isEmpty
            ? LandingViewModel.defaultSandboxUrl
            : vm.data.trim();

        final previewColumn = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClayWell(
              padding: const EdgeInsets.all(20),
              radius: AppDimensions.radiusClayLg,
              child: RepaintBoundary(
                child: Container(
                  width: 224,
                  height: 224,
                  decoration: BoxDecoration(
                    color: design.bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: PrettyQrView.data(
                    data: previewData,
                    errorCorrectLevel: vm.effectiveErrorLevel,
                    decoration: vm.currentDecoration,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ClayButton.primary(
                  label: 'Download PNG',
                  busyLabel: 'Rendering...',
                  icon: Icons.download_rounded,
                  busy: vm.isExporting,
                  onPressed: _downloadPng,
                ),
                ClayButton.gold(
                  label: 'Make dynamic',
                  icon: Icons.dynamic_feed_rounded,
                  onPressed: widget.onMakeDynamic,
                ),
              ],
            ),
          ],
        );

        final controlsColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClayField(
              controller: _urlController,
              label: 'Destination URL',
              hint: 'https://yourdomain.com',
              keyboardType: TextInputType.url,
              onChanged: vm.updateData,
              prefix: const Icon(
                Icons.link_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            const ClayLabel(
              'Palette & Gradient',
              padding: EdgeInsets.only(left: 4, bottom: 10),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final preset in QrStudioViewModel.gradientPresets)
                  ClayColorKnob(
                    color: preset.start,
                    gradientEnd: preset.end,
                    tooltip: preset.label,
                    selected: design.useGradient &&
                        design.fgColor.toARGB32() == preset.start.toARGB32() &&
                        design.fgColorEnd.toARGB32() == preset.end.toARGB32(),
                    onTap: () => vm.applyGradientPreset(preset),
                  ),
                ClayColorKnob(
                  color: AppColors.primary,
                  tooltip: 'Classic Deep Rust',
                  selected: !design.useGradient,
                  onTap: () {
                    vm.setUseGradient(false);
                    vm.setFgColor(AppColors.primary);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const ClayLabel(
              'Center Icon',
              padding: EdgeInsets.only(left: 4, bottom: 10),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ClayTile(
                  selected: design.iconId.isEmpty,
                  onTap: vm.clearCenterImage,
                  child: const Text(
                    'None',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppDimensions.fontSm,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                for (final iconOpt in QrIconCatalog.all.take(4))
                  ClayTile(
                    selected: design.iconId == iconOpt.id,
                    onTap: () => vm.selectBuiltInIcon(iconOpt.id),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        iconOpt.buildGlyph(
                          size: 16,
                          color: AppColors.textPrimary,
                          multicolorBrand: true,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          iconOpt.label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppDimensions.fontSm,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const ClayLabel(
              'Module Style',
              padding: EdgeInsets.only(left: 4, bottom: 10),
            ),
            ClaySegmented<QrModuleStyle>(
              expand: true,
              selected: design.style,
              puckColor: AppColors.gold,
              selectedForeground: AppColors.textPrimary,
              onChanged: vm.setStyle,
              segments: [
                for (final style in QrModuleStyle.values)
                  ClaySegment(value: style, label: style.label),
              ],
            ),
          ],
        );

        return ClayPanel(
          radius: AppDimensions.radiusClayXl,
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: const ClayDecoration.well(
                      radius: AppDimensions.radiusClaySm,
                      depth: 4,
                    ),
                    child: const ClayAssetIcon(
                      asset: 'assets/clay/icon_studio.png',
                      fallbackIcon: Icons.auto_awesome_rounded,
                      size: 32,
                      wobbleOnHover: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Try the QR studio',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Style a QR code right here and export a crisp PNG — no account required.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppDimensions.fontMd,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 780) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: previewColumn),
                        const SizedBox(height: 28),
                        controlsColumn,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      previewColumn,
                      const SizedBox(width: 36),
                      Expanded(child: controlsColumn),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
