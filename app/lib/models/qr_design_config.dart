import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

enum QrModuleStyle {
  smooth('smooth', 'Smooth'),
  dots('dots', 'Dots'),
  squares('squares', 'Classic');

  const QrModuleStyle(this.storageKey, this.label);
  final String storageKey;
  final String label;

  static QrModuleStyle fromKey(String? key) {
    for (final value in values) {
      if (value.storageKey == key) return value;
    }
    return QrModuleStyle.smooth;
  }
}

enum QrGradientDirection {
  horizontal(
    'horizontal',
    'Horizontal →',
    Alignment.centerLeft,
    Alignment.centerRight,
  ),
  vertical(
    'vertical',
    'Vertical ↓',
    Alignment.topCenter,
    Alignment.bottomCenter,
  ),
  diagonalDown(
    'diagonalDown',
    'Diagonal ↘',
    Alignment.topLeft,
    Alignment.bottomRight,
  ),
  diagonalUp(
    'diagonalUp',
    'Diagonal ↗',
    Alignment.bottomLeft,
    Alignment.topRight,
  );

  const QrGradientDirection(this.storageKey, this.label, this.begin, this.end);
  final String storageKey;
  final String label;
  final Alignment begin;
  final Alignment end;

  static QrGradientDirection fromKey(String? key) {
    for (final value in values) {
      if (value.storageKey == key) return value;
    }
    return QrGradientDirection.diagonalDown;
  }
}

/// Immutable QR visual design configuration persisted on each `qr_links/{slug}` doc.
@immutable
class QrDesignConfig {
  const QrDesignConfig({
    this.useGradient = false,
    this.fgColor = const Color(0xFF0F172A),
    this.fgColorEnd = const Color(0xFF4F46E5),
    this.gradientDirection = QrGradientDirection.diagonalDown,
    this.bgColor = const Color(0xFFFFFFFF),
    this.style = QrModuleStyle.smooth,
    this.iconId = '',
    this.errorLevel = QrErrorCorrectLevel.H,
  });

  final bool useGradient;
  final Color fgColor;
  final Color fgColorEnd;
  final QrGradientDirection gradientDirection;
  final Color bgColor;
  final QrModuleStyle style;

  /// Empty string means no built-in center icon.
  final String iconId;
  final int errorLevel;

  /// Checks whether either the primary or gradient-end foreground color has low
  /// contrast against [bgColor] (< 3.5 WCAG ratio).
  bool get hasLowContrast {
    return _contrastRatio(fgColor, bgColor) < 3.5 ||
        (useGradient && _contrastRatio(fgColorEnd, bgColor) < 3.5);
  }

  static double _contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final brightest = l1 > l2 ? l1 : l2;
    final darkest = l1 > l2 ? l2 : l1;
    return (brightest + 0.05) / (darkest + 0.05);
  }

  QrDesignConfig copyWith({
    bool? useGradient,
    Color? fgColor,
    Color? fgColorEnd,
    QrGradientDirection? gradientDirection,
    Color? bgColor,
    QrModuleStyle? style,
    String? iconId,
    int? errorLevel,
  }) {
    return QrDesignConfig(
      useGradient: useGradient ?? this.useGradient,
      fgColor: fgColor ?? this.fgColor,
      fgColorEnd: fgColorEnd ?? this.fgColorEnd,
      gradientDirection: gradientDirection ?? this.gradientDirection,
      bgColor: bgColor ?? this.bgColor,
      style: style ?? this.style,
      iconId: iconId ?? this.iconId,
      errorLevel: errorLevel ?? this.errorLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'useGradient': useGradient,
      'fgColor': fgColor.toARGB32(),
      'fgColorEnd': fgColorEnd.toARGB32(),
      'gradientDirection': gradientDirection.storageKey,
      'bgColor': bgColor.toARGB32(),
      'style': style.storageKey,
      'iconId': iconId,
      'errorLevel': errorLevel,
    };
  }

  factory QrDesignConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const QrDesignConfig();
    final rawError = (map['errorLevel'] as num?)?.toInt();
    final validError = (rawError == QrErrorCorrectLevel.L ||
            rawError == QrErrorCorrectLevel.M ||
            rawError == QrErrorCorrectLevel.Q ||
            rawError == QrErrorCorrectLevel.H)
        ? rawError!
        : QrErrorCorrectLevel.H;

    return QrDesignConfig(
      useGradient: (map['useGradient'] as bool?) ?? false,
      fgColor: map['fgColor'] is num
          ? Color((map['fgColor'] as num).toInt())
          : const Color(0xFF0F172A),
      fgColorEnd: map['fgColorEnd'] is num
          ? Color((map['fgColorEnd'] as num).toInt())
          : const Color(0xFF4F46E5),
      gradientDirection: QrGradientDirection.fromKey(
        map['gradientDirection'] as String?,
      ),
      bgColor: map['bgColor'] is num
          ? Color((map['bgColor'] as num).toInt())
          : const Color(0xFFFFFFFF),
      style: QrModuleStyle.fromKey(map['style'] as String?),
      iconId: (map['iconId'] as String?) ?? '',
      errorLevel: validError,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is QrDesignConfig &&
        other.useGradient == useGradient &&
        other.fgColor.toARGB32() == fgColor.toARGB32() &&
        other.fgColorEnd.toARGB32() == fgColorEnd.toARGB32() &&
        other.gradientDirection == gradientDirection &&
        other.bgColor.toARGB32() == bgColor.toARGB32() &&
        other.style == style &&
        other.iconId == iconId &&
        other.errorLevel == errorLevel;
  }

  @override
  int get hashCode => Object.hash(
        useGradient,
        fgColor.toARGB32(),
        fgColorEnd.toARGB32(),
        gradientDirection,
        bgColor.toARGB32(),
        style,
        iconId,
        errorLevel,
      );
}
