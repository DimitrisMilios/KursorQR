import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/qr_icon_catalog.dart';
import '../../models/qr_design_config.dart';
import '../../models/qr_link.dart';
import '../../services/qr_render_service.dart';
import '../../viewmodels/qr_studio_viewmodel.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/clay_asset_icon.dart';

/// Claymorphism Branded QR Studio dialog featuring solid & linear gradients,
/// 16 built-in vector center icons, local browser-only PNG/JPG logo upload,
/// design persistence, and 512/1024/2048 px PNG download.
class QrStudioDialog extends StatefulWidget {
  const QrStudioDialog({
    super.key,
    required this.link,
    required this.renderService,
    required this.onSaveDesign,
  });

  final QrLink link;
  final QrRenderService renderService;
  final Future<void> Function(QrDesignConfig design) onSaveDesign;

  @override
  State<QrStudioDialog> createState() => _QrStudioDialogState();
}

class _QrStudioDialogState extends State<QrStudioDialog> {
  late final QrStudioViewModel _vm;
  late final TextEditingController _fgHexController;
  late final TextEditingController _fgEndHexController;
  late final TextEditingController _bgHexController;

  @override
  void initState() {
    super.initState();
    _vm = QrStudioViewModel(
      renderService: widget.renderService,
      data: widget.link.redirectUrl,
      initialDesign: widget.link.design,
      slugForFilename: widget.link.slug,
    );
    _fgHexController =
        TextEditingController(text: QrStudioViewModel.toHex(_vm.design.fgColor));
    _fgEndHexController = TextEditingController(
      text: QrStudioViewModel.toHex(_vm.design.fgColorEnd),
    );
    _bgHexController =
        TextEditingController(text: QrStudioViewModel.toHex(_vm.design.bgColor));
  }

  @override
  void dispose() {
    _vm.dispose();
    _fgHexController.dispose();
    _fgEndHexController.dispose();
    _bgHexController.dispose();
    super.dispose();
  }

  void _syncHexControllers() {
    _fgHexController.text = QrStudioViewModel.toHex(_vm.design.fgColor);
    _fgEndHexController.text = QrStudioViewModel.toHex(_vm.design.fgColorEnd);
    _bgHexController.text = QrStudioViewModel.toHex(_vm.design.bgColor);
  }

  Future<void> _handleDownload() async {
    final fileName = await _vm.downloadPng();
    if (fileName != null && mounted) {
      ClayToast.show(context, 'Downloaded $fileName');
    } else if (_vm.statusError != null && mounted) {
      ClayToast.show(context, _vm.statusError!, error: true);
    }
  }

  Future<void> _handleSaveDesign() async {
    final saved = await _vm.runSaveDesign(widget.onSaveDesign);
    if (saved && mounted) {
      ClayToast.show(context, 'Style saved.');
    } else if (_vm.statusError != null && mounted) {
      ClayToast.show(context, _vm.statusError!, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final design = _vm.design;

        return ClayDialog(
          width: 880,
          title: 'QR Studio · ${widget.link.title}',
          subtitle: widget.link.redirectUrl,
          subtitleMonospace: true,
          headerIcon: const ClayAssetIcon(
            asset: 'assets/clay/icon_studio.png',
            fallbackIcon: Icons.qr_code_2_rounded,
            size: 32,
          ),
          actions: [
            ClayButton.text(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
            ClayButton.neutral(
              label: 'Save style',
              busyLabel: 'Saving...',
              icon: Icons.save_outlined,
              busy: _vm.isSavingDesign,
              onPressed: _vm.isSavingDesign ? null : _handleSaveDesign,
            ),
            ClayButton.primary(
              label: 'Download PNG (${_vm.exportSize} px)',
              busyLabel: 'Rendering...',
              icon: Icons.download_rounded,
              busy: _vm.isExporting,
              onPressed: _vm.isExporting ? null : _handleDownload,
            ),
          ],
          child: LayoutBuilder(
            builder: (context, constraints) {
              final previewColumn = SizedBox(
                width: 292,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClayWell(
                      padding: const EdgeInsets.all(16),
                      radius: AppDimensions.radiusClayLg,
                      child: RepaintBoundary(
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            color: design.bgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: PrettyQrView.data(
                            data: _vm.data,
                            errorCorrectLevel: _vm.effectiveErrorLevel,
                            decoration: _vm.currentDecoration,
                          ),
                        ),
                      ),
                    ),
                    if (_vm.hasAnyCenterLogo) ...[
                      const SizedBox(height: 12),
                      ClayWell.mint(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColors.primaryDeep,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _vm.hasCustomLogo
                                    ? 'Custom logo (${_vm.customLogoName}) stays 100% local in your browser. Error correction locked to H (30%).'
                                    : 'Center icon enabled — error correction auto-boosted to H (30%) for reliable scanning.',
                                style: const TextStyle(
                                  color: AppColors.primaryDeep,
                                  fontSize: AppDimensions.fontSm,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (design.hasLowContrast) ...[
                      const SizedBox(height: 10),
                      const ClayWell.butter(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: AppColors.goldDeep,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Low contrast between foreground and background may reduce camera scan speed.',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: AppDimensions.fontSm,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_vm.statusError != null) ...[
                      const SizedBox(height: 10),
                      ClayWell.coral(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _vm.statusError!,
                          style: const TextStyle(
                            color: AppColors.coralDeep,
                            fontSize: AppDimensions.fontSm,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );

              final controlsColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ClayLabel(
                    'Foreground Fill',
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                  ),
                  ClaySegmented<bool>(
                    expand: true,
                    selected: design.useGradient,
                    puckColor: AppColors.gold,
                    selectedForeground: AppColors.textPrimary,
                    onChanged: _vm.setUseGradient,
                    segments: const [
                      ClaySegment(
                        value: false,
                        icon: Icons.format_color_fill_rounded,
                        label: 'Solid',
                      ),
                      ClaySegment(
                        value: true,
                        icon: Icons.gradient_rounded,
                        label: 'Linear gradient',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (design.useGradient) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final preset in QrStudioViewModel.gradientPresets)
                          ClayTile(
                            selected: design.fgColor.toARGB32() ==
                                    preset.start.toARGB32() &&
                                design.fgColorEnd.toARGB32() ==
                                    preset.end.toARGB32(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            onTap: () {
                              _vm.applyGradientPreset(preset);
                              _syncHexControllers();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [preset.start, preset.end],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  preset.label,
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
                    const SizedBox(height: 14),
                    const ClayLabel(
                      'Gradient Start',
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                    ),
                    _ColorKnobRow(
                      swatches: QrStudioViewModel.fgSwatches,
                      selected: design.fgColor,
                      hexController: _fgHexController,
                      onSelect: (c) {
                        _vm.setFgColor(c);
                        _fgHexController.text = QrStudioViewModel.toHex(c);
                      },
                      onHexChanged: (t) {
                        final parsed = QrStudioViewModel.parseHex(t);
                        if (parsed != null) _vm.setFgColor(parsed);
                      },
                    ),
                    const SizedBox(height: 14),
                    const ClayLabel(
                      'Gradient End',
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                    ),
                    _ColorKnobRow(
                      swatches: QrStudioViewModel.fgSwatches,
                      selected: design.fgColorEnd,
                      hexController: _fgEndHexController,
                      onSelect: (c) {
                        _vm.setFgColorEnd(c);
                        _fgEndHexController.text = QrStudioViewModel.toHex(c);
                      },
                      onHexChanged: (t) {
                        final parsed = QrStudioViewModel.parseHex(t);
                        if (parsed != null) _vm.setFgColorEnd(parsed);
                      },
                    ),
                    const SizedBox(height: 14),
                    ClayDropdown<QrGradientDirection>(
                      label: 'Gradient Direction',
                      value: design.gradientDirection,
                      onChanged: _vm.setGradientDirection,
                      items: [
                        for (final dir in QrGradientDirection.values)
                          ClayDropdownItem(value: dir, label: dir.label),
                      ],
                    ),
                  ] else ...[
                    _ColorKnobRow(
                      swatches: QrStudioViewModel.fgSwatches,
                      selected: design.fgColor,
                      hexController: _fgHexController,
                      onSelect: (c) {
                        _vm.setFgColor(c);
                        _fgHexController.text = QrStudioViewModel.toHex(c);
                      },
                      onHexChanged: (t) {
                        final parsed = QrStudioViewModel.parseHex(t);
                        if (parsed != null) _vm.setFgColor(parsed);
                      },
                    ),
                  ],
                  const SizedBox(height: 18),
                  const ClayLabel(
                    'Background Color',
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                  ),
                  _ColorKnobRow(
                    swatches: QrStudioViewModel.bgSwatches,
                    selected: design.bgColor,
                    hexController: _bgHexController,
                    onSelect: (c) {
                      _vm.setBgColor(c);
                      _bgHexController.text = QrStudioViewModel.toHex(c);
                    },
                    onHexChanged: (t) {
                      final parsed = QrStudioViewModel.parseHex(t);
                      if (parsed != null) _vm.setBgColor(parsed);
                    },
                  ),
                  const SizedBox(height: 18),
                  const ClayLabel(
                    'Module Style',
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                  ),
                  ClaySegmented<QrModuleStyle>(
                    expand: true,
                    selected: design.style,
                    puckColor: AppColors.gold,
                    selectedForeground: AppColors.textPrimary,
                    onChanged: _vm.setStyle,
                    segments: [
                      for (final s in QrModuleStyle.values)
                        ClaySegment(value: s, label: s.label),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: ClayLabel(
                          'Center Icon or Local Logo',
                          padding: EdgeInsets.only(left: 4),
                        ),
                      ),
                      ClayButton.neutral(
                        label: 'Upload logo (local)',
                        icon: Icons.upload_file_rounded,
                        size: ClayButtonSize.compact,
                        onPressed: _vm.pickCustomLogo,
                      ),
                      if (_vm.hasAnyCenterLogo) ...[
                        const SizedBox(width: 6),
                        ClayButton.text(
                          label: 'Clear',
                          size: ClayButtonSize.compact,
                          danger: true,
                          onPressed: _vm.clearCenterImage,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ClayTile(
                        selected: !_vm.hasAnyCenterLogo,
                        onTap: _vm.clearCenterImage,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        child: const Text(
                          'None',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppDimensions.fontSm,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      for (final item in QrIconCatalog.all)
                        ClayTile(
                          selected:
                              !_vm.hasCustomLogo && design.iconId == item.id,
                          onTap: () => _vm.selectBuiltInIcon(item.id),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                size: 15,
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                item.label,
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ClayDropdown<int>(
                          label: 'Error Correction',
                          value: _vm.effectiveErrorLevel,
                          onChanged:
                              _vm.hasAnyCenterLogo ? null : _vm.setErrorLevel,
                          items: const [
                            ClayDropdownItem(
                              value: QrErrorCorrectLevel.M,
                              label: 'M (15%)',
                            ),
                            ClayDropdownItem(
                              value: QrErrorCorrectLevel.Q,
                              label: 'Q (25%)',
                            ),
                            ClayDropdownItem(
                              value: QrErrorCorrectLevel.H,
                              label: 'H (30% · Best)',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ClayDropdown<int>(
                          label: 'PNG Resolution',
                          value: _vm.exportSize,
                          onChanged: _vm.setExportSize,
                          items: const [
                            ClayDropdownItem(value: 512, label: '512 × 512 px'),
                            ClayDropdownItem(
                              value: 1024,
                              label: '1024 × 1024 px',
                            ),
                            ClayDropdownItem(
                              value: 2048,
                              label: '2048 × 2048 px',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );

              if (constraints.maxWidth < 700) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(child: previewColumn),
                    const SizedBox(height: 24),
                    controlsColumn,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  previewColumn,
                  const SizedBox(width: 30),
                  Expanded(child: controlsColumn),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ColorKnobRow extends StatelessWidget {
  const _ColorKnobRow({
    required this.swatches,
    required this.selected,
    required this.hexController,
    required this.onSelect,
    required this.onHexChanged,
  });

  final List<Color> swatches;
  final Color selected;
  final TextEditingController hexController;
  final ValueChanged<Color> onSelect;
  final ValueChanged<String> onHexChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final color in swatches)
          ClayColorKnob(
            color: color,
            size: 32,
            selected: color.toARGB32() == selected.toARGB32(),
            onTap: () => onSelect(color),
          ),
        SizedBox(
          width: 112,
          child: ClayField(
            controller: hexController,
            onChanged: onHexChanged,
            monospace: true,
            hint: '#1A4731',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          ),
        ),
      ],
    );
  }
}
