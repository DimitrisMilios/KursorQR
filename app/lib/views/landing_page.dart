import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../core/app_config.dart';
import '../core/qr_icon_catalog.dart';
import '../models/qr_design_config.dart';
import '../services/qr_render_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/qr_studio_viewmodel.dart';
import 'dialogs/auth_dialog.dart';
import 'dialogs/gdpr_policy_dialog.dart';

/// Public commercial landing page with an interactive free QR sandbox
/// (supports linear gradients & center icons with zero login) and a
/// non-intrusive GDPR zero-tracking transparency notice.
class LandingPage extends StatefulWidget {
  const LandingPage({
    super.key,
    required this.authViewModel,
    required this.renderService,
  });

  final AuthViewModel authViewModel;
  final QrRenderService renderService;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late final TextEditingController _urlController;
  late final QrStudioViewModel _sandboxVm;
  bool _showGdprNotice = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: 'https://kursorqr.web.app');
    _sandboxVm = QrStudioViewModel(
      renderService: widget.renderService,
      data: 'https://kursorqr.web.app',
      initialDesign: const QrDesignConfig(
        useGradient: true,
        fgColor: Color(0xFF4F46E5),
        fgColorEnd: Color(0xFF0284C7),
        gradientDirection: QrGradientDirection.diagonalDown,
        style: QrModuleStyle.smooth,
        iconId: 'app_store',
      ),
      slugForFilename: 'instant',
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _sandboxVm.dispose();
    super.dispose();
  }

  Future<void> _openAuth({required bool startInSignUp}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AuthDialog(
        authViewModel: widget.authViewModel,
        initialIsSignUp: startInSignUp,
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const GdprPolicyDialog(),
    );
  }

  Future<void> _downloadSandboxPng() async {
    final fileName = await _sandboxVm.downloadPng();
    if (fileName != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Downloaded $fileName')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              width: 36,
              height: 36,
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
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  'Free · 100% GDPR',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _openPrivacyPolicy,
            child: const Text('Privacy'),
          ),
          TextButton(
            onPressed: () => _openAuth(startInSignUp: false),
            child: const Text('Sign In'),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: FilledButton(
              onPressed: () => _openAuth(startInSignUp: true),
              child: const Text('Start Free'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _showGdprNotice
          ? Material(
              elevation: 4,
              color: const Color(0xFF0F172A),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 10,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                size: 18,
                                color: Color(0xFF4ADE80),
                              ),
                              SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  'Zero tracking cookies · Zero IP logging. QR scans store no personal data; strictly necessary session storage is used only when you sign in.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: _openPrivacyPolicy,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF93C5FD),
                                ),
                                child: const Text('Privacy & Cookies'),
                              ),
                              const SizedBox(width: 6),
                              FilledButton.tonal(
                                onPressed: () =>
                                    setState(() => _showGdprNotice = false),
                                child: const Text('Got it'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 880;
                      final heroCopy = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Open-Source · Zero Cookies · EU Cloud Firestore',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Dynamic QR Codes &\nSmart App Store Redirects.',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                              letterSpacing: -0.8,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Print one branded QR code with linear gradients and a center icon, '
                            'then update destinations anytime. Automatically send iOS scanners '
                            'to the App Store, Android users to Google Play, and desktop visitors '
                            'to your website — free for up to ${AppConfig.maxQrLinksPerAccount} dynamic QR codes per account.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.icon(
                                onPressed: () => _openAuth(startInSignUp: true),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                                icon: const Icon(Icons.rocket_launch_rounded),
                                label: const Text(
                                  'Create Free Account (10 QRs)',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _openAuth(startInSignUp: false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 16,
                                  ),
                                ),
                                icon: const Icon(Icons.login_rounded),
                                label: const Text('Sign In'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Wrap(
                            spacing: 18,
                            runSpacing: 8,
                            children: [
                              _TrustBullet(text: '10 free dynamic QRs / account'),
                              _TrustBullet(text: 'Linear gradients & center icons'),
                              _TrustBullet(text: 'Zero tracking cookies'),
                              _TrustBullet(text: '1-click GDPR export & erase'),
                            ],
                          ),
                        ],
                      );

                      final sandboxCard = ListenableBuilder(
                        listenable: _sandboxVm,
                        builder: (context, _) {
                          final design = _sandboxVm.design;
                          final previewData = _sandboxVm.data.trim().isEmpty
                              ? 'https://kursorqr.web.app'
                              : _sandboxVm.data.trim();

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Try Instant QR Generator',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _urlController,
                                    onChanged: _sandboxVm.updateData,
                                    decoration: const InputDecoration(
                                      labelText: 'Destination URL',
                                      hintText: 'https://yourdomain.com',
                                      prefixIcon: Icon(Icons.link_rounded),
                                      isDense: true,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: Container(
                                      width: 214,
                                      height: 214,
                                      decoration: BoxDecoration(
                                        color: design.bgColor,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color:
                                              theme.colorScheme.outlineVariant,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: PrettyQrView.data(
                                        data: previewData,
                                        errorCorrectLevel:
                                            _sandboxVm.effectiveErrorLevel,
                                        decoration:
                                            _sandboxVm.currentDecoration,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Gradient & solid quick presets
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final preset
                                          in QrStudioViewModel.gradientPresets)
                                        InkWell(
                                          onTap: () => _sandboxVm
                                              .applyGradientPreset(preset),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          child: Tooltip(
                                            message: preset.label,
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    preset.start,
                                                    preset.end,
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: design.useGradient &&
                                                          design.fgColor
                                                                  .toARGB32() ==
                                                              preset.start
                                                                  .toARGB32()
                                                      ? theme
                                                          .colorScheme.primary
                                                      : theme.colorScheme
                                                          .outlineVariant,
                                                  width: design.useGradient &&
                                                          design.fgColor
                                                                  .toARGB32() ==
                                                              preset.start
                                                                  .toARGB32()
                                                      ? 3
                                                      : 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      InkWell(
                                        onTap: () {
                                          _sandboxVm.setUseGradient(false);
                                          _sandboxVm.setFgColor(
                                            const Color(0xFF0F172A),
                                          );
                                        },
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: Tooltip(
                                          message: 'Classic Slate',
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(0xFF0F172A),
                                              border: Border.all(
                                                color: !design.useGradient
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme
                                                        .outlineVariant,
                                                width: !design.useGradient
                                                    ? 3
                                                    : 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Quick center icon toggles
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      ChoiceChip(
                                        label: const Text(
                                          'No Icon',
                                          style: TextStyle(fontSize: 11.5),
                                        ),
                                        selected: design.iconId.isEmpty,
                                        onSelected: (_) =>
                                            _sandboxVm.clearCenterImage(),
                                      ),
                                      for (final iconOpt
                                          in QrIconCatalog.all.take(4))
                                        ChoiceChip(
                                          avatar: Icon(iconOpt.icon, size: 15),
                                          label: Text(
                                            iconOpt.label,
                                            style:
                                                const TextStyle(fontSize: 11.5),
                                          ),
                                          selected:
                                              design.iconId == iconOpt.id,
                                          onSelected: (_) => _sandboxVm
                                              .selectBuiltInIcon(iconOpt.id),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  SegmentedButton<QrModuleStyle>(
                                    segments: [
                                      for (final s in QrModuleStyle.values)
                                        ButtonSegment(
                                          value: s,
                                          label: Text(s.label),
                                        ),
                                    ],
                                    selected: {design.style},
                                    onSelectionChanged: (sel) =>
                                        _sandboxVm.setStyle(sel.first),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _sandboxVm.isExporting
                                              ? null
                                              : _downloadSandboxPng,
                                          icon: _sandboxVm.isExporting
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.download_rounded,
                                                  size: 18,
                                                ),
                                          label: const Text('Download PNG'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton.tonalIcon(
                                          onPressed: () =>
                                              _openAuth(startInSignUp: true),
                                          icon: const Icon(
                                            Icons.dynamic_feed_rounded,
                                            size: 18,
                                          ),
                                          label: const Text('Make Dynamic'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      if (!isWide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            heroCopy,
                            const SizedBox(height: 32),
                            sandboxCard,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 6, child: heroCopy),
                          const SizedBox(width: 40),
                          Expanded(flex: 5, child: sandboxCard),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 52),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const features = [
                        _FeatureCard(
                          icon: Icons.devices_rounded,
                          title: 'Smart iOS & Android Routing',
                          description:
                              'One QR code automatically detects iOS, Android, or desktop in memory and redirects scanners straight to the App Store, Play Store, or web fallback.',
                        ),
                        _FeatureCard(
                          icon: Icons.palette_outlined,
                          title: 'Linear Gradients & Center Logos',
                          description:
                              'Customize QR codes with 2-color linear gradients, 16 built-in vector icons, or your own local PNG/JPG logo — exported up to 2048px without uploading images.',
                        ),
                        _FeatureCard(
                          icon: Icons.shield_outlined,
                          title: '100% GDPR-Native & Free Forever',
                          description:
                              'Zero cookies, zero IP addresses, anonymous aggregate scan counters only, EU Cloud Firestore storage, and 1-click GDPR data export or full account erasure.',
                        ),
                      ];

                      if (constraints.maxWidth < 800) {
                        return Column(
                          children: [
                            for (var i = 0; i < features.length; i++) ...[
                              features[i],
                              if (i < features.length - 1)
                                const SizedBox(height: 14),
                            ],
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < features.length; i++) ...[
                            Expanded(child: features[i]),
                            if (i < features.length - 1)
                              const SizedBox(width: 16),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 44),
                  Divider(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 8,
                    children: [
                      Text(
                        'KursorQR — Open-source, privacy-first dynamic QR platform (EU Cloud Firestore).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openPrivacyPolicy,
                        icon: const Icon(Icons.shield_outlined, size: 15),
                        label: const Text('GDPR Privacy & Cookie Policy'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustBullet extends StatelessWidget {
  const _TrustBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 16, color: Colors.green.shade600),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.55,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
