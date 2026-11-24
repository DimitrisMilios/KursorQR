import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/qr_link.dart';
import '../../services/qr_render_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/ambient_background.dart';
import '../dialogs/account_settings_dialog.dart';
import '../dialogs/confirm_danger_dialog.dart';
import '../dialogs/gdpr_policy_dialog.dart';
import '../dialogs/qr_link_form_dialog.dart';
import '../dialogs/qr_studio_dialog.dart';
import 'dashboard_empty_state.dart';
import 'dashboard_navbar.dart';
import 'metric_clay_card.dart';
import 'qr_link_clay_card.dart';
import 'quota_meter_panel.dart';

/// Multi-tenant user dashboard strictly wired to [DashboardViewModel] and
/// [AuthViewModel] with granular [Selector] rebuild scoping.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.authViewModel,
    required this.dashboardViewModel,
    required this.renderService,
  });

  final AuthViewModel authViewModel;
  final DashboardViewModel dashboardViewModel;
  final QrRenderService renderService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  DashboardViewModel get _vm => widget.dashboardViewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_vm.hasLoadedOnce) _vm.refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateOrEdit({QrLink? existing}) async {
    if (existing == null && _vm.isQuotaReached) {
      ClayToast.show(
        context,
        'Free limit reached (${_vm.maxQuota}/${_vm.maxQuota}). Delete an unused link first.',
        error: true,
      );
      return;
    }

    final savedSlug = await showClayDialog<String>(
      context: context,
      builder: (_) => QrLinkFormDialog(
        dashboardViewModel: _vm,
        existing: existing,
      ),
    );
    if (savedSlug != null && mounted) {
      ClayToast.show(
        context,
        existing == null
            ? 'Created /r/$savedSlug'
            : 'Updated /r/$savedSlug',
      );
    }
  }

  Future<void> _openQrStudio(QrLink link) async {
    await showClayDialog<void>(
      context: context,
      builder: (_) => QrStudioDialog(
        link: link,
        renderService: widget.renderService,
        onSaveDesign: (design) => _vm.saveLinkDesign(
          slug: link.slug,
          design: design,
        ),
      ),
    );
  }

  Future<void> _openAccountSettings() async {
    await showClayDialog<void>(
      context: context,
      builder: (_) => AccountSettingsDialog(
        authViewModel: widget.authViewModel,
        dashboardViewModel: _vm,
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    await showClayDialog<void>(
      context: context,
      builder: (_) => const GdprPolicyDialog(),
    );
  }

  Future<void> _confirmDelete(QrLink link) async {
    final confirmed = await showClayDialog<bool>(
      context: context,
      builder: (_) => ConfirmDangerDialog(
        title: 'Delete QR link',
        message:
            'Permanently delete "${link.title}" (/r/${link.slug})?\n\n'
            'Printed QR codes pointing to this link will stop redirecting, and '
            'this frees 1 of your ${_vm.maxQuota} free QR slots.',
        confirmLabel: 'Delete & free slot',
      ),
    );
    if (confirmed != true) return;

    try {
      await _vm.deleteLink(link.slug);
      if (mounted) ClayToast.show(context, 'Deleted /r/${link.slug}');
    } catch (e) {
      if (mounted) ClayToast.show(context, 'Failed to delete link: $e', error: true);
    }
  }

  Future<void> _copyRedirectUrl(QrLink link) async {
    await _vm.copyRedirectUrl(link);
    if (mounted) ClayToast.show(context, 'Copied ${link.redirectUrl}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: Stack(
          children: [
            // 1. Full-height workspace list gliding underneath the floating navbar
            Positioned.fill(
              child: Selector<DashboardViewModel, (bool, bool)>(
                selector: (_, vm) => (vm.hasLoadedOnce, vm.isLoading),
                builder: (context, loadState, _) {
                  if (!loadState.$1 && loadState.$2) {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        color: AppColors.primary,
                      ),
                    );
                  }
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppDimensions.maxContentWidth,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 112, 24, 48),
                        children: [
                          // Title + Quota Meter
                          Selector<DashboardViewModel,
                              (String, int, int, double, bool)>(
                            selector: (_, vm) => (
                              vm.formattedLastRefreshed,
                              vm.usedQuota,
                              vm.maxQuota,
                              vm.quotaProgress,
                              vm.isQuotaReached,
                            ),
                            builder: (context, s, _) => Wrap(
                              spacing: 16,
                              runSpacing: 14,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'My QR links',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.9,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      s.$1.isNotEmpty
                                          ? 'Updated ${s.$1} · Refresh anytime for the latest anonymous scan counts.'
                                          : 'Every scan routes via <15 KB /r/<slug> with zero cookies.',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: AppDimensions.fontBody,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                QuotaMeterPanel(
                                  usedQuota: s.$2,
                                  maxQuota: s.$3,
                                  progress: s.$4,
                                  isReached: s.$5,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Error & quota-reached wells
                          Selector<DashboardViewModel, (String?, bool)>(
                            selector: (_, vm) =>
                                (vm.errorMessage, vm.isQuotaReached),
                            builder: (context, alerts, _) => Column(
                              children: [
                                if (alerts.$1 != null) ...[
                                  ClayWell.coral(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: AppColors.coralDeep,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            alerts.$1!,
                                            style: const TextStyle(
                                              color: AppColors.coralDeep,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        ClayButton.text(
                                          label: 'Retry',
                                          size: ClayButtonSize.compact,
                                          danger: true,
                                          onPressed: _vm.refresh,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (alerts.$2) ...[
                                  ClayWell.butter(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline_rounded,
                                          color: AppColors.goldDeep,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'All ${_vm.maxQuota} free QR slots are in use. You can edit any existing link anytime, or delete one to free a slot.',
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: AppDimensions.fontBody,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                          ),

                          // KPI row
                          Selector<DashboardViewModel,
                              (int, int, int, int, int)>(
                            selector: (_, vm) => (
                              vm.activeCount,
                              vm.allLinks.length,
                              vm.totalScans,
                              vm.iosScans,
                              vm.androidScans,
                            ),
                            builder: (context, kpis, _) {
                              final cards = [
                                MetricClayCard(
                                  label: 'Active links',
                                  value: '${kpis.$1} / ${kpis.$2}',
                                  asset: 'assets/clay/metric_links.png',
                                  fallbackIcon: Icons.link_rounded,
                                ),
                                MetricClayCard(
                                  label: 'Total scans',
                                  value: '${kpis.$3}',
                                  asset: 'assets/clay/metric_scans.png',
                                  fallbackIcon: Icons.qr_code_scanner_rounded,
                                ),
                                MetricClayCard(
                                  label: 'iOS scans',
                                  value: '${kpis.$4}',
                                  asset: 'assets/clay/metric_ios.png',
                                  fallbackIcon: Icons.phone_iphone_rounded,
                                ),
                                MetricClayCard(
                                  label: 'Android scans',
                                  value: '${kpis.$5}',
                                  asset: 'assets/clay/metric_android.png',
                                  fallbackIcon: Icons.android_rounded,
                                ),
                              ];

                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth < 760) {
                                    return Wrap(
                                      spacing: 14,
                                      runSpacing: 14,
                                      children: [
                                        for (var i = 0; i < cards.length; i++)
                                          SizedBox(
                                            width:
                                                (constraints.maxWidth - 14) / 2,
                                            child: ClayStagger(
                                              index: i,
                                              child: cards[i],
                                            ),
                                          ),
                                      ],
                                    );
                                  }
                                  return Row(
                                    children: [
                                      for (var i = 0; i < cards.length; i++) ...[
                                        Expanded(
                                          child: ClayStagger(
                                            index: i,
                                            child: cards[i],
                                          ),
                                        ),
                                        if (i < cards.length - 1)
                                          const SizedBox(width: 16),
                                      ],
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Search field + Refresh button
                          Selector<DashboardViewModel, (String, bool)>(
                            selector: (_, vm) => (vm.searchQuery, vm.isLoading),
                            builder: (context, searchState, _) => Row(
                              children: [
                                Expanded(
                                  child: ClayField(
                                    controller: _searchController,
                                    hint:
                                        'Search by slug, name, or destination URL...',
                                    onChanged: _vm.setSearchQuery,
                                    prefix: const Icon(
                                      Icons.search_rounded,
                                      size: 19,
                                      color: AppColors.textMuted,
                                    ),
                                    suffix: searchState.$1.isNotEmpty
                                        ? ClayIconButton(
                                            icon: Icons.close_rounded,
                                            flat: true,
                                            size: 32,
                                            iconSize: 16,
                                            onPressed: () {
                                              _searchController.clear();
                                              _vm.setSearchQuery('');
                                            },
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                ClayButton.neutral(
                                  label: 'Refresh stats',
                                  icon: Icons.refresh_rounded,
                                  busy: searchState.$2,
                                  onPressed:
                                      searchState.$2 ? null : _vm.refresh,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Filtered links list (isolated rebuild scope!)
                          Selector<DashboardViewModel,
                              (bool, List<QrLink>, String)>(
                            selector: (_, vm) => (
                              vm.allLinks.isEmpty,
                              vm.filteredLinks,
                              vm.searchQuery,
                            ),
                            builder: (context, listState, _) {
                              if (listState.$1) {
                                return DashboardEmptyState(
                                  onCreateLink: _openCreateOrEdit,
                                );
                              }
                              if (listState.$2.isEmpty) {
                                return ClayPanel(
                                  padding: const EdgeInsets.all(40),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'No QR links match "${listState.$3}".',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: AppDimensions.fontLg,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (var i = 0;
                                      i < listState.$2.length;
                                      i++) ...[
                                    ClayStagger(
                                      index: i,
                                      child: QrLinkClayCard(
                                        link: listState.$2[i],
                                        onCopyUrl: () =>
                                            _copyRedirectUrl(listState.$2[i]),
                                        onOpenStudio: () =>
                                            _openQrStudio(listState.$2[i]),
                                        onEdit: () => _openCreateOrEdit(
                                          existing: listState.$2[i],
                                        ),
                                        onDelete: () =>
                                            _confirmDelete(listState.$2[i]),
                                      ),
                                    ),
                                    if (i < listState.$2.length - 1)
                                      const SizedBox(height: 16),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2. Sticky floating clay navbar on top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Selector<DashboardViewModel, (bool, bool, String)>(
                selector: (_, vm) => (
                  vm.isLoading,
                  vm.isQuotaReached,
                  vm.formattedLastRefreshed,
                ),
                builder: (context, state, _) => DashboardNavbar(
                  ownerEmail: _vm.ownerEmail,
                  isLoading: state.$1,
                  isQuotaReached: state.$2,
                  maxQuota: _vm.maxQuota,
                  lastRefreshedLabel: state.$3,
                  onRefresh: _vm.refresh,
                  onCreateLink: _openCreateOrEdit,
                  onOpenAccount: _openAccountSettings,
                  onOpenPrivacy: _openPrivacyPolicy,
                  onSignOut: widget.authViewModel.signOut,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
