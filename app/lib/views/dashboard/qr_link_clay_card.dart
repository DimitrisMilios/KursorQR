import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/qr_icon_catalog.dart';
import '../../models/qr_link.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/brand_icons.dart';

/// Tactile clay card for a single dynamic QR link.
class QrLinkClayCard extends StatelessWidget {
  const QrLinkClayCard({
    super.key,
    required this.link,
    required this.onCopyUrl,
    required this.onOpenStudio,
    required this.onEdit,
    required this.onDelete,
  });

  final QrLink link;
  final VoidCallback onCopyUrl;
  final VoidCallback onOpenStudio;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final iconOption = QrIconCatalog.findById(link.design.iconId);
    final swatchGradient = link.design.useGradient
        ? LinearGradient(
            begin: link.design.gradientDirection.begin,
            end: link.design.gradientDirection.end,
            colors: [link.design.fgColor, link.design.fgColorEnd],
          )
        : null;

    return ClayCard(
      radius: AppDimensions.radiusClayLg,
      padding: const EdgeInsets.all(24),
      lift: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: ClayDecoration(
                      color: link.design.fgColor,
                      gradient: swatchGradient,
                      radius: 14,
                      depth: 3.5,
                      lift: 6,
                      shadowOpacity: 0.22,
                      highlightOpacity: 0.55,
                      shadeOpacity: 0.4,
                    ),
                    child: iconOption != null
                        ? iconOption.buildGlyph(size: 20, color: Colors.white)
                        : const Icon(
                            Icons.qr_code_2_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: link.isActive
                                  ? AppColors.sage
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            link.isActive ? 'Active' : 'Paused',
                            style: TextStyle(
                              color: link.isActive
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              fontSize: AppDimensions.fontSm,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ClayButton.primary(
                    label: 'QR Studio',
                    icon: Icons.qr_code_2_rounded,
                    size: ClayButtonSize.compact,
                    onPressed: onOpenStudio,
                  ),
                  ClayButton.neutral(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    size: ClayButtonSize.compact,
                    onPressed: onEdit,
                  ),
                  ClayIconButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete link and free slot',
                    danger: true,
                    size: 36,
                    iconSize: 18,
                    radius: 18,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interactive copyable short URL well
          ClayPressable(
            onTap: onCopyUrl,
            squash: 0.03,
            builder: (context, hover, press, _) {
              final h = hover.clamp(0.0, 1.0);
              return ClayWell(
                color: Color.lerp(AppColors.clayDeep, AppColors.mint, 0.45 * h)!,
                radius: AppDimensions.radiusClaySm,
                depth: 4,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        link.redirectUrl,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.copy_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Route destinations
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              _RouteDestination(
                leading: const Icon(
                  Icons.language_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                label: 'Web',
                url: link.webUrl,
              ),
              if (link.iosUrl.isNotEmpty)
                _RouteDestination(
                  leading: const BrandVectorIcon(
                    BrandIconKind.apple,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                  label: 'iOS',
                  url: link.iosUrl,
                ),
              if (link.androidUrl.isNotEmpty)
                _RouteDestination(
                  leading: const BrandVectorIcon(
                    BrandIconKind.googlePlay,
                    size: 14,
                    color: AppColors.textMuted,
                    multicolor: true,
                  ),
                  label: 'Android',
                  url: link.androidUrl,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Single sunken well holding tabular anonymous scan counts
          ClayWell(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            radius: AppDimensions.radiusClaySm,
            depth: 4,
            child: Wrap(
              spacing: 22,
              runSpacing: 8,
              children: [
                _ScanStat(
                  leading: const Icon(
                    Icons.bar_chart_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  label: 'Total',
                  count: link.totalScans,
                ),
                _ScanStat(
                  leading: const BrandVectorIcon(
                    BrandIconKind.apple,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  label: 'iOS',
                  count: link.iosScans,
                ),
                _ScanStat(
                  leading: const BrandVectorIcon(
                    BrandIconKind.googlePlay,
                    size: 14,
                    color: AppColors.primary,
                    multicolor: true,
                  ),
                  label: 'Android',
                  count: link.androidScans,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteDestination extends StatelessWidget {
  const _RouteDestination({
    required this.leading,
    required this.label,
    required this.url,
  });

  final Widget leading;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: AppDimensions.fontSm,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              url,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppDimensions.fontSm,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanStat extends StatelessWidget {
  const _ScanStat({
    required this.leading,
    required this.label,
    required this.count,
  });

  final Widget leading;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
        const SizedBox(width: 6),
        Text(
          '$label ',
          style: const TextStyle(
            fontSize: AppDimensions.fontSm,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: AppDimensions.fontMd,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
