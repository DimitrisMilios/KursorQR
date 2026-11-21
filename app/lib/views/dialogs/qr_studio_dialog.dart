import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../core/qr_icon_catalog.dart';
import '../../models/qr_design_config.dart';
import '../../models/qr_link.dart';
import '../../services/qr_render_service.dart';
import '../../viewmodels/qr_studio_viewmodel.dart';

/// Full Branded QR Studio dialog featuring Solid & Linear Gradients, 16 built-in
/// vector center icons, local browser-only PNG/JPG logo upload, design persistence,
/// and 512/1024/2048px PNG download.
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Downloaded $fileName')));
    }
  }

  Future<void> _handleSaveDesign() async {
    final saved = await _vm.runSaveDesign(widget.onSaveDesign);
    if (saved && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('QR style saved to your link!')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final design = _vm.design;

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.qr_code_2_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Studio · ${widget.link.title}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.link.redirectUrl,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: SizedBox(
            width: 820,
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final previewColumn = Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 270,
                        height: 270,
                        decoration: BoxDecoration(
                          color: design.bgColor,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: PrettyQrView.data(
                          data: _vm.data,
                          errorCorrectLevel: _vm.effectiveErrorLevel,
                          decoration: _vm.currentDecoration,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_vm.hasAnyCenterLogo)
                        Container(
                          width: 270,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _vm.hasCustomLogo
                                      ? 'Custom logo (${_vm.customLogoName}) stays 100% local in your browser. Error correction locked to H (30%).'
                                      : 'Center icon enabled — error correction auto-boosted to H (30%) for crisp scanning.',
                                  style: const TextStyle(fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (design.hasLowContrast) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: 270,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Colors.amber.shade900,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Low contrast between foreground and background may hurt camera scanning.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_vm.statusError != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: 270,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _vm.statusError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );

                  final controlsColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Solid vs Linear Gradient Fill
                      Text('Foreground Fill', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.format_color_fill_rounded, size: 16),
                            label: Text('Solid Color'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.gradient_rounded, size: 16),
                            label: Text('Linear Gradient'),
                          ),
                        ],
                        selected: {design.useGradient},
                        onSelectionChanged: (sel) =>
                            _vm.setUseGradient(sel.first),
                      ),
                      const SizedBox(height: 12),

                      if (design.useGradient) ...[
                        // Quick Gradient Presets
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final preset
                                in QrStudioViewModel.gradientPresets)
                              ActionChip(
                                avatar: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [preset.start, preset.end],
                                    ),
                                  ),
                                ),
                                label: Text(
                                  preset.label,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () {
                                  _vm.applyGradientPreset(preset);
                                  _syncHexControllers();
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gradient Start Color',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: 6),
                        _ColorSwatchRow(
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
                        const SizedBox(height: 10),
                        Text(
                          'Gradient End Color',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: 6),
                        _ColorSwatchRow(
                          swatches: QrStudioViewModel.fgSwatches,
                          selected: design.fgColorEnd,
                          hexController: _fgEndHexController,
                          onSelect: (c) {
                            _vm.setFgColorEnd(c);
                            _fgEndHexController.text =
                                QrStudioViewModel.toHex(c);
                          },
                          onHexChanged: (t) {
                            final parsed = QrStudioViewModel.parseHex(t);
                            if (parsed != null) _vm.setFgColorEnd(parsed);
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<QrGradientDirection>(
                          initialValue: design.gradientDirection,
                          decoration: const InputDecoration(
                            labelText: 'Gradient Direction',
                            isDense: true,
                          ),
                          items: [
                            for (final dir in QrGradientDirection.values)
                              DropdownMenuItem(
                                value: dir,
                                child: Text(dir.label),
                              ),
                          ],
                          onChanged: (d) {
                            if (d != null) _vm.setGradientDirection(d);
                          },
                        ),
                      ] else ...[
                        _ColorSwatchRow(
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

                      const SizedBox(height: 16),

                      // 2. Background Color
                      Text(
                        'Background Color',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      _ColorSwatchRow(
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

                      const SizedBox(height: 16),

                      // 3. Module Shape
                      Text('Module Style', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 8),
                      SegmentedButton<QrModuleStyle>(
                        segments: [
                          for (final s in QrModuleStyle.values)
                            ButtonSegment(value: s, label: Text(s.label)),
                        ],
                        selected: {design.style},
                        onSelectionChanged: (sel) => _vm.setStyle(sel.first),
                      ),

                      const SizedBox(height: 16),

                      // 4. Center Icon or Local Logo Upload
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Center Icon or Local Logo',
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _vm.pickCustomLogo,
                            icon: const Icon(Icons.upload_file_rounded, size: 16),
                            label: const Text('Upload Logo (Local)'),
                          ),
                          if (_vm.hasAnyCenterLogo) ...[
                            const SizedBox(width: 6),
                            TextButton(
                              onPressed: _vm.clearCenterImage,
                              child: const Text('Clear'),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ChoiceChip(
                            label: const Text('None'),
                            selected: !_vm.hasAnyCenterLogo,
                            onSelected: (_) => _vm.clearCenterImage(),
                          ),
                          for (final item in QrIconCatalog.all)
                            ChoiceChip(
                              avatar: Icon(item.icon, size: 16),
                              label: Text(
                                item.label,
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected:
                                  !_vm.hasCustomLogo && design.iconId == item.id,
                              onSelected: (_) => _vm.selectBuiltInIcon(item.id),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 5. Error Correction & Resolution
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _vm.effectiveErrorLevel,
                              decoration: const InputDecoration(
                                labelText: 'Error Correction',
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: QrErrorCorrectLevel.M,
                                  child: Text('M (15%)'),
                                ),
                                DropdownMenuItem(
                                  value: QrErrorCorrectLevel.Q,
                                  child: Text('Q (25%)'),
                                ),
                                DropdownMenuItem(
                                  value: QrErrorCorrectLevel.H,
                                  child: Text('H (30% · Best)'),
                                ),
                              ],
                              onChanged: _vm.hasAnyCenterLogo
                                  ? null
                                  : (v) {
                                      if (v != null) _vm.setErrorLevel(v);
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _vm.exportSize,
                              decoration: const InputDecoration(
                                labelText: 'PNG Resolution',
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 512,
                                  child: Text('512 × 512 px'),
                                ),
                                DropdownMenuItem(
                                  value: 1024,
                                  child: Text('1024 × 1024 px'),
                                ),
                                DropdownMenuItem(
                                  value: 2048,
                                  child: Text('2048 × 2048 px'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) _vm.setExportSize(v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );

                  if (constraints.maxWidth < 680) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        previewColumn,
                        const SizedBox(height: 20),
                        controlsColumn,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      previewColumn,
                      const SizedBox(width: 28),
                      Expanded(child: controlsColumn),
                    ],
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            OutlinedButton.icon(
              onPressed: _vm.isSavingDesign ? null : _handleSaveDesign,
              icon: _vm.isSavingDesign
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save Style'),
            ),
            FilledButton.icon(
              onPressed: _vm.isExporting ? null : _handleDownload,
              icon: _vm.isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text('Download PNG (${_vm.exportSize}px)'),
            ),
          ],
        );
      },
    );
  }
}

class _ColorSwatchRow extends StatelessWidget {
  const _ColorSwatchRow({
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
    final borderColor = Theme.of(context).colorScheme.outlineVariant;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final color in swatches)
          InkWell(
            onTap: () => onSelect(color),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.toARGB32() == selected.toARGB32()
                      ? Theme.of(context).colorScheme.primary
                      : borderColor,
                  width: color.toARGB32() == selected.toARGB32() ? 3 : 1.2,
                ),
              ),
            ),
          ),
        SizedBox(
          width: 112,
          child: TextField(
            controller: hexController,
            onChanged: onHexChanged,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              hintText: '#0F172A',
            ),
          ),
        ),
      ],
    );
  }
}
