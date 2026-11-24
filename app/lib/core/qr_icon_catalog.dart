import 'package:flutter/material.dart';

import '../widgets/shared/brand_icons.dart';

/// Represents a built-in center icon option rendered cleanly inside QR codes.
@immutable
class QrCenterIconOption {
  const QrCenterIconOption({
    required this.id,
    required this.label,
    required this.icon,
    this.brandIcon,
  });

  final String id;
  final String label;
  final IconData icon;
  final BrandIconKind? brandIcon;

  /// Builds the visual glyph for UI controls (chips, cards, studio tiles).
  Widget buildGlyph({
    double size = 16,
    required Color color,
    bool multicolorBrand = false,
  }) {
    if (brandIcon != null) {
      return BrandVectorIcon(
        brandIcon!,
        size: size,
        color: color,
        multicolor: multicolorBrand,
      );
    }
    return Icon(icon, size: size, color: color);
  }
}

/// Curated set of 16 crisp vector center icons (zero external assets, 100% offline/GDPR).
class QrIconCatalog {
  const QrIconCatalog._();

  static const List<QrCenterIconOption> all = [
    QrCenterIconOption(
      id: 'app_store',
      label: 'Apple / iOS',
      icon: Icons.phone_iphone_rounded,
      brandIcon: BrandIconKind.apple,
    ),
    QrCenterIconOption(
      id: 'android',
      label: 'Google Play',
      icon: Icons.android_rounded,
      brandIcon: BrandIconKind.googlePlay,
    ),
    QrCenterIconOption(
      id: 'download',
      label: 'Download',
      icon: Icons.download_rounded,
    ),
    QrCenterIconOption(
      id: 'web',
      label: 'Website',
      icon: Icons.language_rounded,
    ),
    QrCenterIconOption(
      id: 'link',
      label: 'Link',
      icon: Icons.link_rounded,
    ),
    QrCenterIconOption(
      id: 'shop',
      label: 'Shop',
      icon: Icons.shopping_bag_rounded,
    ),
    QrCenterIconOption(
      id: 'menu',
      label: 'Menu',
      icon: Icons.restaurant_menu_rounded,
    ),
    QrCenterIconOption(
      id: 'coffee',
      label: 'Cafe',
      icon: Icons.local_cafe_rounded,
    ),
    QrCenterIconOption(
      id: 'wifi',
      label: 'Wi-Fi',
      icon: Icons.wifi_rounded,
    ),
    QrCenterIconOption(
      id: 'mail',
      label: 'Email',
      icon: Icons.mail_rounded,
    ),
    QrCenterIconOption(
      id: 'phone',
      label: 'Call',
      icon: Icons.call_rounded,
    ),
    QrCenterIconOption(
      id: 'location',
      label: 'Map',
      icon: Icons.location_on_rounded,
    ),
    QrCenterIconOption(
      id: 'play',
      label: 'Video',
      icon: Icons.play_arrow_rounded,
    ),
    QrCenterIconOption(
      id: 'star',
      label: 'Review',
      icon: Icons.star_rounded,
    ),
    QrCenterIconOption(
      id: 'heart',
      label: 'Favorite',
      icon: Icons.favorite_rounded,
    ),
    QrCenterIconOption(
      id: 'bolt',
      label: 'Promo',
      icon: Icons.bolt_rounded,
    ),
  ];

  static QrCenterIconOption? findById(String id) {
    if (id.isEmpty) return null;
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }
}
