import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_config.dart';
import '../core/qr_icon_catalog.dart';
import '../models/qr_link.dart';
import '../services/qr_render_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import 'dialogs/account_settings_dialog.dart';
import 'dialogs/gdpr_policy_dialog.dart';
import 'dialogs/qr_link_form_dialog.dart';
import 'dialogs/qr_studio_dialog.dart';

/// Multi-tenant user dashboard strictly consuming [DashboardViewModel] and [AuthViewModel].
/// Uses Spark-optimized on-demand loading + Refresh Stats button + 10-QR quota bar.
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
  final _searchController = TextEditingController();

  DashboardViewModel get _vm => widget.dashboardViewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_vm.hasLoadedOnce) {
        _vm.refresh();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreateOrEdit({QrLink? existing}) async {
    if (existing == null && _vm.isQuotaReached) {
      _showSnackBar(
        'Free limit reached (${_vm.maxQuota}/${_vm.maxQuota} QR codes). Delete an unused link to create a new one.',
      );
      return;
    }

    final savedSlug = await showDialog<String>(
      context: context,
      builder: (_) => QrLinkFormDialog(
        dashboardViewModel: _vm,
        existing: existing,
      ),
    );
    if (savedSlug != null) {
      _showSnackBar(
        existing == null
            ? 'Created dynamic QR "/r/$savedSlug"'
            : 'Updated dynamic QR "/r/$savedSlug"',
      );
    }
  }

  Future<void> _openQrStudio(QrLink link) async {
    await showDialog<void>(
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

  Future<void> _confirmDelete(QrLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete QR Link?'),
        content: Text(
          'Permanently delete "${link.title}" (/r/${link.slug})?\n\n'
          'Printed QR codes pointing to this link will stop redirecting, and this will free 1 of your ${_vm.maxQuota} free QR slots.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
              foregroundColor: Theme.of(dialogCtx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete & Free Slot'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _vm.deleteLink(link.slug);
      _showSnackBar('Deleted "/r/${link.slug}" (slot freed)');
    } catch (e) {
      _showSnackBar('Failed to delete link: $e');
    }
  }

  Future<void> _copyRedirectUrl(QrLink link) async {
    await Clipboard.setData(ClipboardData(text: link.redirectUrl));
    _showSnackBar('Copied ${link.redirectUrl}');
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final displayEmail = _vm.ownerEmail;
        final quotaColor = _vm.isQuotaReached
            ? theme.colorScheme.error
            : _vm.usedQuota >= 8
                ? Colors.amber.shade800
                : theme.colorScheme.primary;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  AppConfig.appName,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      '100% GDPR Anonymous',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: _vm.lastRefreshedAt != null
                    ? 'Refresh scan stats (last updated ${_formatTime(_vm.lastRefreshedAt)})'
                    : 'Refresh scan stats',
                onPressed: _vm.isLoading ? null : _vm.refresh,
                icon: _vm.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FilledButton.icon(
                  onPressed: _vm.isQuotaReached
                      ? null
                      : () => _openCreateOrEdit(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    _vm.isQuotaReached
                        ? 'Limit (${_vm.maxQuota}/${_vm.maxQuota})'
                        : 'New QR Link',
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: displayEmail,
                onSelected: (value) {
                  switch (value) {
                    case 'account':
                      showDialog<void>(
                        context: context,
                        builder: (_) => AccountSettingsDialog(
                          authViewModel: widget.authViewModel,
                          dashboardViewModel: _vm,
                        ),
                      );
                    case 'privacy':
                      showDialog<void>(
                        context: context,
                        builder: (_) => const GdprPolicyDialog(),
                      );
                    case 'signout':
                      widget.authViewModel.signOut();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Signed in as', style: TextStyle(fontSize: 11)),
                        Text(
                          displayEmail,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'account',
                    child: Row(
                      children: [
                        Icon(Icons.manage_accounts_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Account & GDPR Rights'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'privacy',
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Privacy & Cookie Policy'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'signout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Sign out'),
                      ],
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      displayEmail.isNotEmpty
                          ? displayEmail[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: !_vm.hasLoadedOnce && _vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1160),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Header + Free Account Quota Progress
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Dynamic QR Links',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _vm.lastRefreshedAt != null
                                      ? 'Updated at ${_formatTime(_vm.lastRefreshedAt)} · Click Refresh to fetch the latest anonymous scan counts.'
                                      : 'Every scan routes via <15KB /r/<slug> with zero cookies and anonymous aggregate counters.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 260,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Free Account Quota',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${_vm.usedQuota} / ${_vm.maxQuota}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: quotaColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: _vm.quotaProgress,
                                      minHeight: 7,
                                      color: quotaColor,
                                      backgroundColor: theme
                                          .colorScheme.surfaceContainerHighest,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        if (_vm.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _vm.errorMessage!,
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _vm.refresh,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_vm.isQuotaReached) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.amber.shade900,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'You are using all 10 of your free dynamic QR slots. You can still edit any existing QR link anytime, or delete an unused link to free up a slot.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // KPI Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 720;
                            final cards = [
                              _MetricCard(
                                label: 'Active QR Links',
                                value:
                                    '${_vm.activeCount} / ${_vm.allLinks.length}',
                                icon: Icons.link_rounded,
                                accentColor: theme.colorScheme.primary,
                              ),
                              _MetricCard(
                                label: 'Total Scans',
                                value: '${_vm.totalScans}',
                                icon: Icons.qr_code_scanner_rounded,
                                accentColor: const Color(0xFF0F766E),
                              ),
                              _MetricCard(
                                label: 'iOS Scans',
                                value: '${_vm.iosScans}',
                                icon: Icons.phone_iphone_rounded,
                                accentColor: const Color(0xFF1D4ED8),
                              ),
                              _MetricCard(
                                label: 'Android Scans',
                                value: '${_vm.androidScans}',
                                icon: Icons.android_rounded,
                                accentColor: const Color(0xFF15803D),
                              ),
                            ];

                            if (isCompact) {
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: cards
                                    .map(
                                      (card) => SizedBox(
                                        width: (constraints.maxWidth - 12) / 2,
                                        child: card,
                                      ),
                                    )
                                    .toList(),
                              );
                            }

                            return Row(
                              children: [
                                for (var i = 0; i < cards.length; i++) ...[
                                  Expanded(child: cards[i]),
                                  if (i < cards.length - 1)
                                    const SizedBox(width: 14),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Search bar + Refresh button
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: _vm.setSearchQuery,
                                decoration: InputDecoration(
                                  hintText:
                                      'Search your links by slug, name, or destination URL…',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _vm.searchQuery.isNotEmpty
                                      ? IconButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            _vm.setSearchQuery('');
                                          },
                                          icon: const Icon(Icons.close_rounded),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _vm.isLoading ? null : _vm.refresh,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Refresh Stats'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        if (_vm.allLinks.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 56,
                                horizontal: 24,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 56,
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Create Your First Dynamic QR Code',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Customize with linear gradients and center icons, route iOS/Android/Web automatically, and track anonymous scans.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  FilledButton.icon(
                                    onPressed: () => _openCreateOrEdit(),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('New QR Link'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_vm.filteredLinks.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Center(
                                child: Text(
                                  'No QR links match "${_vm.searchQuery}".',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._vm.filteredLinks.map(
                            (link) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _QrLinkCard(
                                link: link,
                                onCopyUrl: () => _copyRedirectUrl(link),
                                onOpenStudio: () => _openQrStudio(link),
                                onEdit: () => _openCreateOrEdit(existing: link),
                                onDelete: () => _confirmDelete(link),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrLinkCard extends StatelessWidget {
  const _QrLinkCard({
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
    final theme = Theme.of(context);
    final iconOption = QrIconCatalog.findById(link.design.iconId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Live miniature swatch of this link's saved QR fill
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: link.design.useGradient
                            ? LinearGradient(
                                begin: link.design.gradientDirection.begin,
                                end: link.design.gradientDirection.end,
                                colors: [
                                  link.design.fgColor,
                                  link.design.fgColorEnd,
                                ],
                              )
                            : null,
                        color:
                            link.design.useGradient ? null : link.design.fgColor,
                      ),
                      child: Icon(
                        iconOption?.icon ?? Icons.qr_code_2_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      link.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: link.isActive
                            ? Colors.green.shade50
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        link.isActive ? 'Active' : 'Paused',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: link.isActive
                              ? Colors.green.shade800
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: onOpenStudio,
                      icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                      label: const Text('QR Studio'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                    IconButton(
                      tooltip: 'Delete QR link & free slot',
                      onPressed: onDelete,
                      color: theme.colorScheme.error,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: onCopyUrl,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        link.redirectUrl,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _RouteLabel(
                  icon: Icons.language_rounded,
                  label: 'Web',
                  url: link.webUrl,
                ),
                if (link.iosUrl.isNotEmpty)
                  _RouteLabel(
                    icon: Icons.phone_iphone_rounded,
                    label: 'iOS',
                    url: link.iosUrl,
                  ),
                if (link.androidUrl.isNotEmpty)
                  _RouteLabel(
                    icon: Icons.android_rounded,
                    label: 'Android',
                    url: link.androidUrl,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _ScanBadge(
                  icon: Icons.bar_chart_rounded,
                  label: 'Total',
                  count: link.totalScans,
                  color: const Color(0xFF0F766E),
                ),
                _ScanBadge(
                  icon: Icons.phone_iphone_rounded,
                  label: 'iOS',
                  count: link.iosScans,
                  color: const Color(0xFF1D4ED8),
                ),
                _ScanBadge(
                  icon: Icons.android_rounded,
                  label: 'Android',
                  count: link.androidScans,
                  color: const Color(0xFF15803D),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLabel extends StatelessWidget {
  const _RouteLabel({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: muted),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
          Flexible(
            child: Text(
              url,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanBadge extends StatelessWidget {
  const _ScanBadge({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12.5,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
