import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/brand_logo.dart';

/// Floating clay navbar for the authenticated Dashboard workspace.
class DashboardNavbar extends StatelessWidget {
  const DashboardNavbar({
    super.key,
    required this.ownerEmail,
    required this.isLoading,
    required this.isQuotaReached,
    required this.maxQuota,
    required this.lastRefreshedLabel,
    required this.onRefresh,
    required this.onCreateLink,
    required this.onOpenAccount,
    required this.onOpenPrivacy,
    required this.onSignOut,
  });

  final String ownerEmail;
  final bool isLoading;
  final bool isQuotaReached;
  final int maxQuota;
  final String lastRefreshedLabel;
  final VoidCallback onRefresh;
  final VoidCallback onCreateLink;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onSignOut;

  Future<void> _openAccountMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final picked = await showClayMenu<String>(
      context: context,
      anchorRect: rect,
      width: 248,
      items: [
        ClayMenuItem<String>.header(
          label: 'Signed in as',
          subtitle: ownerEmail,
        ),
        const ClayMenuItem<String>.divider(),
        const ClayMenuItem<String>(
          value: 'account',
          label: 'Account & GDPR',
          icon: Icons.manage_accounts_rounded,
        ),
        const ClayMenuItem<String>(
          value: 'privacy',
          label: 'Privacy & cookies',
          icon: Icons.shield_outlined,
        ),
        const ClayMenuItem<String>.divider(),
        const ClayMenuItem<String>(
          value: 'signout',
          label: 'Sign out',
          icon: Icons.logout_rounded,
          danger: true,
        ),
      ],
    );
    switch (picked) {
      case 'account':
        onOpenAccount();
      case 'privacy':
        onOpenPrivacy();
      case 'signout':
        onSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        ownerEmail.isNotEmpty ? ownerEmail[0].toUpperCase() : 'K';

    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 8),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
          child: ClayPanel(
            height: AppDimensions.navbarHeight,
            radius: AppDimensions.radiusClayXl,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingXxl,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showWordmark = constraints.maxWidth >= 360;
                final showNewLabel = constraints.maxWidth >= 500;

                return Row(
                  children: [
                    const BrandLogo(size: 40, radius: AppDimensions.radiusMd),
                    if (showWordmark) ...[
                      const SizedBox(width: AppDimensions.spacingMd),
                      const Text(
                        AppConfig.appName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppDimensions.fontXl,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                    const Spacer(),
                    ClayIconButton(
                      icon: Icons.refresh_rounded,
                      busy: isLoading,
                      tooltip: lastRefreshedLabel.isNotEmpty
                          ? 'Refresh stats (updated $lastRefreshedLabel)'
                          : 'Refresh scan stats',
                      size: 42,
                      radius: 21,
                      onPressed: isLoading ? null : onRefresh,
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    if (showNewLabel)
                      ClayButton.primary(
                        label: isQuotaReached
                            ? 'Limit ($maxQuota/$maxQuota)'
                            : 'New QR link',
                        icon: Icons.add_rounded,
                        onPressed: isQuotaReached ? null : onCreateLink,
                      )
                    else
                      ClayIconButton(
                        icon: Icons.add_rounded,
                        tooltip: 'New QR link',
                        color: AppColors.primary,
                        iconColor: AppColors.textOnPrimary,
                        size: 42,
                        radius: 21,
                        onPressed: isQuotaReached ? null : onCreateLink,
                      ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Builder(
                      builder: (avatarCtx) => Tooltip(
                        message: ownerEmail,
                        child: ClayPressable(
                          onTap: () => _openAccountMenu(avatarCtx),
                          squash: 0.09,
                          builder: (context, hover, press, _) => Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: ClayDecoration.gold(
                              radius: 21,
                              depth: 4,
                              lift: 8 + 4 * hover.clamp(0.0, 1.0),
                              pressed: press.clamp(0.0, 1.0),
                            ),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
