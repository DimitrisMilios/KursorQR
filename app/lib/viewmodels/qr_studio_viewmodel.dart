import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../core/app_config.dart';
import '../models/qr_design_config.dart';
import '../services/file_downloader.dart';
import '../services/local_image_picker.dart';
import '../services/qr_render_service.dart';

/// Curated linear gradient presets for one-click designer QR codes.
@immutable
class QrGradientPreset {
  const QrGradientPreset({
    required this.label,
    required this.start,
    required this.end,
  });

  final String label;
  final Color start;
  final Color end;
}

/// MVVM ViewModel for the Branded QR Studio (used both on the Landing Sandbox
/// and inside the per-link QR Studio dialog).
class QrStudioViewModel extends ChangeNotifier {
  QrStudioViewModel({
    required QrRenderService renderService,
    required String data,
    QrDesignConfig initialDesign = const QrDesignConfig(),
    this.slugForFilename = 'instant',
  })  : _renderService = renderService,
        _data = data,
        _design = initialDesign {
    _refreshIconBadge();
  }

  static const List<Color> fgSwatches = [
    Color(0xFF1A4731),
    Color(0xFF2D6A4F),
    Color(0xFF0F172A),
    Color(0xFF4F46E5),
    Color(0xFF1D4ED8),
    Color(0xFFBE123C),
    Color(0xFF7C3AED),
  ];

  static const List<Color> bgSwatches = [
    Color(0xFFFFFFFF),
    Color(0xFFFBF6EA),
    Color(0xFFEFE8D6),
    Color(0xFFECFDF5),
    Color(0xFFFFFBEB),
    Color(0xFF1A4731),
  ];

  static const List<QrGradientPreset> gradientPresets = [
    QrGradientPreset(
      label: 'Forest → Emerald',
      start: Color(0xFF1A4731),
      end: Color(0xFF52B788),
    ),
    QrGradientPreset(
      label: 'Forest → Gold',
      start: Color(0xFF1A4731),
      end: Color(0xFFC9A440),
    ),
    QrGradientPreset(
      label: 'Indigo → Ocean',
      start: Color(0xFF4F46E5),
      end: Color(0xFF0284C7),
    ),
    QrGradientPreset(
      label: 'Violet → Rose',
      start: Color(0xFF7C3AED),
      end: Color(0xFFE11D48),
    ),
  ];

  final QrRenderService _renderService;
  final String slugForFilename;

  String _data;
  QrDesignConfig _design;
  int _exportSize = 1024;
  Uint8List? _renderedIconBytes;
  Uint8List? _customLogoBytes;
  String? _customLogoName;
  bool _isExporting = false;
  bool _isSavingDesign = false;
  String? _statusError;
  int _iconRenderEpoch = 0;

  String get data => _data;
  QrDesignConfig get design => _design;
  int get exportSize => _exportSize;
  Uint8List? get customLogoBytes => _customLogoBytes;
  String? get customLogoName => _customLogoName;
  bool get hasCustomLogo => _customLogoBytes != null;
  bool get hasAnyCenterLogo => hasCustomLogo || _design.iconId.isNotEmpty;
  bool get isExporting => _isExporting;
  bool get isSavingDesign => _isSavingDesign;
  String? get statusError => _statusError;

  int get effectiveErrorLevel =>
      hasAnyCenterLogo ? QrErrorCorrectLevel.H : _design.errorLevel;

  PrettyQrDecoration get currentDecoration => _renderService.buildDecoration(
        design: _design,
        centerImageBytes: _customLogoBytes ?? _renderedIconBytes,
      );

  void updateData(String nextData) {
    if (_data == nextData) return;
    _data = nextData;
    notifyListeners();
  }

  void setUseGradient(bool enabled) {
    if (_design.useGradient == enabled) return;
    _design = _design.copyWith(useGradient: enabled);
    notifyListeners();
    _refreshIconBadge();
  }

  void applyGradientPreset(QrGradientPreset preset) {
    _design = _design.copyWith(
      useGradient: true,
      fgColor: preset.start,
      fgColorEnd: preset.end,
    );
    notifyListeners();
    _refreshIconBadge();
  }

  void setFgColor(Color color) {
    if (_design.fgColor.toARGB32() == color.toARGB32()) return;
    _design = _design.copyWith(fgColor: color);
    notifyListeners();
    _refreshIconBadge();
  }

  void setFgColorEnd(Color color) {
    if (_design.fgColorEnd.toARGB32() == color.toARGB32()) return;
    _design = _design.copyWith(fgColorEnd: color);
    notifyListeners();
    _refreshIconBadge();
  }

  void setGradientDirection(QrGradientDirection direction) {
    if (_design.gradientDirection == direction) return;
    _design = _design.copyWith(gradientDirection: direction);
    notifyListeners();
    _refreshIconBadge();
  }

  void setBgColor(Color color) {
    if (_design.bgColor.toARGB32() == color.toARGB32()) return;
    _design = _design.copyWith(bgColor: color);
    notifyListeners();
    _refreshIconBadge();
  }

  void setStyle(QrModuleStyle style) {
    if (_design.style == style) return;
    _design = _design.copyWith(style: style);
    notifyListeners();
  }

  void setErrorLevel(int level) {
    if (_design.errorLevel == level) return;
    _design = _design.copyWith(errorLevel: level);
    notifyListeners();
  }

  void setExportSize(int sizePx) {
    if (_exportSize == sizePx) return;
    _exportSize = sizePx;
    notifyListeners();
  }

  /// Selects a built-in center icon (or empty string to clear). Clears custom logo.
  void selectBuiltInIcon(String iconId) {
    _customLogoBytes = null;
    _customLogoName = null;
    _statusError = null;
    _design = _design.copyWith(
      iconId: iconId,
      errorLevel: iconId.isNotEmpty ? QrErrorCorrectLevel.H : _design.errorLevel,
    );
    notifyListeners();
    _refreshIconBadge();
  }

  void clearCenterImage() {
    _customLogoBytes = null;
    _customLogoName = null;
    _renderedIconBytes = null;
    _statusError = null;
    _design = _design.copyWith(iconId: '');
    notifyListeners();
  }

  /// Picks a local PNG/JPG/WebP logo strictly in browser memory (never uploaded).
  Future<void> pickCustomLogo() async {
    _statusError = null;
    notifyListeners();
    try {
      final picked = await pickLocalLogoImage(
        maxBytes: AppConfig.maxLocalLogoBytes,
      );
      if (picked == null) return;
      _customLogoBytes = picked.bytes;
      _customLogoName = picked.fileName;
      _design = _design.copyWith(
        iconId: '',
        errorLevel: QrErrorCorrectLevel.H,
      );
      notifyListeners();
    } catch (e) {
      _statusError = e.toString();
      notifyListeners();
    }
  }

  Future<String?> downloadPng() async {
    final targetData = _data.trim();
    if (targetData.isEmpty) {
      _statusError = 'Enter a destination URL first.';
      notifyListeners();
      return null;
    }

    _isExporting = true;
    _statusError = null;
    notifyListeners();

    try {
      final bytes = await _renderService.exportPngBytes(
        data: targetData,
        design: _design,
        sizePx: _exportSize,
        customLogoBytes: _customLogoBytes,
      );
      final fileName = 'kursorqr-$slugForFilename-${_exportSize}px.png';
      downloadBytes(
        bytes: bytes,
        fileName: fileName,
        mimeType: 'image/png',
      );
      return fileName;
    } catch (e) {
      _statusError = 'PNG export failed: $e';
      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<bool> runSaveDesign(Future<void> Function(QrDesignConfig) onSave) async {
    _isSavingDesign = true;
    _statusError = null;
    notifyListeners();
    try {
      await onSave(_design);
      return true;
    } catch (e) {
      _statusError = 'Failed to save style: $e';
      return false;
    } finally {
      _isSavingDesign = false;
      notifyListeners();
    }
  }

  Future<void> _refreshIconBadge() async {
    if (_design.iconId.isEmpty) {
      if (_renderedIconBytes != null) {
        _renderedIconBytes = null;
        notifyListeners();
      }
      return;
    }

    final epoch = ++_iconRenderEpoch;
    try {
      final bytes = await _renderService.renderBuiltInIconBadge(_design);
      if (epoch == _iconRenderEpoch) {
        _renderedIconBytes = bytes;
        notifyListeners();
      }
    } catch (_) {
      // Ignore off-screen test environment rendering errors gracefully.
    }
  }

  static String toHex(Color color) {
    final argb = color.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static Color? parseHex(String raw) {
    final cleaned = raw.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(cleaned)) return null;
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
