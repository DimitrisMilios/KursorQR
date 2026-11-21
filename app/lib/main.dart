import 'dart:math';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'utils/file_downloader.dart';

// =============================================================================
// KURSORQR CONFIGURATION (Firebase Spark Plan — Unified Domain)
// =============================================================================

/// Public base URL for short dynamic QR redirects (`/r/<slug>`).
/// Served by the <15KB vanilla `web/r.html` engine on the same domain.
const String kRedirectBaseUrl = 'https://kursorqr.web.app/r';

/// Web Firebase config for the `kursorqr` Spark Plan project.
const FirebaseOptions kFirebaseWebOptions = FirebaseOptions(
  apiKey: 'AIzaSyDxcSD5L1rG5yIKPJkhXNvvp-VR0FwIsaA',
  appId: '1:212947339529:web:6b27aba595ea67ab54abd8',
  messagingSenderId: '212947339529',
  projectId: 'kursorqr',
  authDomain: 'kursorqr.firebaseapp.com',
  storageBucket: 'kursorqr.firebasestorage.app',
);

const String kQrLinksCollection = 'qr_links';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  try {
    await Firebase.initializeApp(options: kFirebaseWebOptions);
  } catch (e) {
    initError = e.toString();
  }

  runApp(KursorQrApp(initError: initError));
}

class KursorQrApp extends StatelessWidget {
  const KursorQrApp({super.key, this.initError});

  final String? initError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'KursorQR — Free GDPR-Compliant Dynamic QR Codes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: initError != null
          ? _FirebaseInitErrorScreen(error: initError!)
          : const AppRoot(),
    );
  }
}

class _FirebaseInitErrorScreen extends StatelessWidget {
  const _FirebaseInitErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Firebase Initialization Error',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to initialize Firebase for KursorQR. Please verify '
                    'kFirebaseWebOptions in app/lib/main.dart.',
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    error,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
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

// =============================================================================
// DATA MODEL
// =============================================================================

class QrLink {
  const QrLink({
    required this.slug,
    required this.ownerId,
    required this.title,
    required this.webUrl,
    required this.iosUrl,
    required this.androidUrl,
    required this.isActive,
    required this.totalScans,
    required this.iosScans,
    required this.androidScans,
    this.createdAt,
    this.updatedAt,
  });

  final String slug;
  final String ownerId;
  final String title;
  final String webUrl;
  final String iosUrl;
  final String androidUrl;
  final bool isActive;
  final int totalScans;
  final int iosScans;
  final int androidScans;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get redirectUrl {
    final normalizedBase = kRedirectBaseUrl.endsWith('/')
        ? kRedirectBaseUrl.substring(0, kRedirectBaseUrl.length - 1)
        : kRedirectBaseUrl;
    return '$normalizedBase/$slug';
  }

  factory QrLink.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return QrLink(
      slug: doc.id,
      ownerId: (data['ownerId'] as String?) ?? '',
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : doc.id,
      webUrl: (data['webUrl'] as String?) ?? '',
      iosUrl: (data['iosUrl'] as String?) ?? '',
      androidUrl: (data['androidUrl'] as String?) ?? '',
      isActive: (data['isActive'] as bool?) ?? true,
      totalScans: (data['totalScans'] as num?)?.toInt() ?? 0,
      iosScans: (data['iosScans'] as num?)?.toInt() ?? 0,
      androidScans: (data['androidScans'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

enum QrModuleStyle { smooth, dots, squares }

// =============================================================================
// APP ROOT — PUBLIC LANDING PAGE OR AUTHENTICATED WORKSPACE
// =============================================================================

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LandingPage();
        }

        return DashboardScreen(user: user);
      },
    );
  }
}

// =============================================================================
// PUBLIC COMMERCIAL LANDING PAGE + INSTANT FREE QR SANDBOX
// =============================================================================

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _sandboxUrlController = TextEditingController(
    text: 'https://kursorqr.web.app',
  );
  Color _sandboxFg = const Color(0xFF0F172A);
  QrModuleStyle _sandboxStyle = QrModuleStyle.smooth;
  bool _isExportingSandbox = false;

  static const _quickColors = [
    Color(0xFF0F172A),
    Color(0xFF4F46E5),
    Color(0xFF047857),
    Color(0xFFBE123C),
    Color(0xFF7C3AED),
  ];

  @override
  void dispose() {
    _sandboxUrlController.dispose();
    super.dispose();
  }

  Future<void> _openAuthDialog({required bool startInSignUp}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AuthDialog(initialIsSignUp: startInSignUp),
    );
  }

  PrettyQrDecoration _sandboxDecoration() {
    final shape = switch (_sandboxStyle) {
      QrModuleStyle.smooth => PrettyQrSmoothSymbol(color: _sandboxFg),
      QrModuleStyle.dots => PrettyQrDotsSymbol(color: _sandboxFg),
      QrModuleStyle.squares => PrettyQrSquaresSymbol(color: _sandboxFg),
    };
    return PrettyQrDecoration(
      background: Colors.white,
      quietZone: PrettyQrQuietZone.standard,
      shape: shape,
    );
  }

  Future<void> _downloadSandboxPng() async {
    final data = _sandboxUrlController.text.trim();
    if (data.isEmpty) return;

    setState(() => _isExportingSandbox = true);
    try {
      final qrImage = QrImage(
        QrCode.fromData(
          data: data,
          errorCorrectLevel: QrErrorCorrectLevel.H,
        ),
      );
      final bytes = await qrImage.toImageAsBytes(
        size: 1024,
        format: ui.ImageByteFormat.png,
        decoration: _sandboxDecoration(),
      );
      if (bytes != null) {
        downloadPngBytes(
          bytes.buffer.asUint8List(),
          'kursorqr-instant-1024px.png',
        );
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Downloaded kursorqr-instant-1024px.png')),
            );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExportingSandbox = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sandboxText = _sandboxUrlController.text.trim().isEmpty
        ? 'https://kursorqr.web.app'
        : _sandboxUrlController.text.trim();

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
              'KursorQR',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                'Free · 100% GDPR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _openAuthDialog(startInSignUp: false),
            child: const Text('Sign In'),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: FilledButton(
              onPressed: () => _openAuthDialog(startInSignUp: true),
              child: const Text('Start Free'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero + Live Instant QR Sandbox
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 860;
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
                                    'Open-Source · Zero Cookies · Zero IP Logging',
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
                            'Print one QR code and update its destination anytime. '
                            'Automatically route iOS scanners to the App Store, '
                            'Android users to Google Play, and desktop visitors to your website — '
                            'with instant <15KB redirects and privacy-first anonymous scan counters.',
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
                                onPressed: () => _openAuthDialog(startInSignUp: true),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                                icon: const Icon(Icons.rocket_launch_rounded),
                                label: const Text(
                                  'Create Free Dynamic QR',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _openAuthDialog(startInSignUp: false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 16,
                                  ),
                                ),
                                icon: const Icon(Icons.login_rounded),
                                label: const Text('Sign In to Dashboard'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 18,
                            runSpacing: 8,
                            children: const [
                              _TrustBullet(text: 'Free to use'),
                              _TrustBullet(text: 'EU cloud storage'),
                              _TrustBullet(text: 'No tracking cookies'),
                              _TrustBullet(text: 'High-res PNG export'),
                            ],
                          ),
                        ],
                      );

                      final sandboxCard = Card(
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
                                  Text(
                                    'Try Instant QR Generator',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _sandboxUrlController,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Destination URL',
                                  hintText: 'https://yourdomain.com',
                                  prefixIcon: Icon(Icons.link_rounded),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: Container(
                                  width: 210,
                                  height: 210,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: PrettyQrView.data(
                                    data: sandboxText,
                                    errorCorrectLevel: QrErrorCorrectLevel.H,
                                    decoration: _sandboxDecoration(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  for (final color in _quickColors)
                                    InkWell(
                                      onTap: () => setState(() => _sandboxFg = color),
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: color.toARGB32() ==
                                                    _sandboxFg.toARGB32()
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.outlineVariant,
                                            width: color.toARGB32() ==
                                                    _sandboxFg.toARGB32()
                                                ? 3
                                                : 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SegmentedButton<QrModuleStyle>(
                                segments: const [
                                  ButtonSegment(
                                    value: QrModuleStyle.smooth,
                                    label: Text('Smooth'),
                                  ),
                                  ButtonSegment(
                                    value: QrModuleStyle.dots,
                                    label: Text('Dots'),
                                  ),
                                  ButtonSegment(
                                    value: QrModuleStyle.squares,
                                    label: Text('Classic'),
                                  ),
                                ],
                                selected: {_sandboxStyle},
                                onSelectionChanged: (s) =>
                                    setState(() => _sandboxStyle = s.first),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isExportingSandbox
                                          ? null
                                          : _downloadSandboxPng,
                                      icon: _isExportingSandbox
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.download_rounded, size: 18),
                                      label: const Text('Download PNG'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.tonalIcon(
                                      onPressed: () =>
                                          _openAuthDialog(startInSignUp: true),
                                      icon: const Icon(Icons.dynamic_feed_rounded, size: 18),
                                      label: const Text('Make Dynamic'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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

                  const SizedBox(height: 56),

                  // 3 Feature Cards
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
                          icon: Icons.shield_outlined,
                          title: '100% GDPR-Compliant Analytics',
                          description:
                              'Zero cookies, zero IP addresses, zero personal data collected from scanners. Only anonymous aggregate counters (Total, iOS, Android) are incremented.',
                        ),
                        _FeatureCard(
                          icon: Icons.bolt_rounded,
                          title: 'Instant <15KB Redirect Engine',
                          description:
                              'QR scans hit a pure vanilla HTML/JS micro-redirector at /r/<slug> — no heavy web app bundle, near-instant handoff even on slow mobile networks.',
                        ),
                      ];

                      if (constraints.maxWidth < 800) {
                        return Column(
                          children: [
                            for (var i = 0; i < features.length; i++) ...[
                              features[i],
                              if (i < features.length - 1) const SizedBox(height: 14),
                            ],
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < features.length; i++) ...[
                            Expanded(child: features[i]),
                            if (i < features.length - 1) const SizedBox(width: 16),
                          ],
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 48),
                  Divider(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 8,
                    children: [
                      Text(
                        'KursorQR — Open-source, privacy-first dynamic QR platform.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Zero Cookies · Zero IP Logging · Anonymous Counters Only',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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

// =============================================================================
// AUTH DIALOG (OPEN PUBLIC SIGN IN / SIGN UP: GOOGLE + EMAIL/PASSWORD)
// =============================================================================

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key, this.initialIsSignUp = false});

  final bool initialIsSignUp;

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late bool _isSignUp;
  bool _isBusy = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      await FirebaseAuth.instance.signInWithPopup(provider);
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message ?? 'Google Sign-In failed (${e.code}).');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Google Sign-In failed: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isSignUp) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message ?? 'Authentication failed (${e.code}).');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Authentication failed: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Enter your email address first to reset your password.');
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() => _infoMessage = 'Password reset link sent to $email.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message ?? 'Could not send reset email.');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.qr_code_2_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isSignUp ? 'Create Free Account' : 'Sign In to KursorQR',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Sign In')),
                  ButtonSegment(value: true, label: Text('Create Account')),
                ],
                selected: {_isSignUp},
                onSelectionChanged: (sel) => setState(() {
                  _isSignUp = sel.first;
                  _errorMessage = null;
                  _infoMessage = null;
                }),
              ),
              const SizedBox(height: 18),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
              if (_infoMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    _infoMessage!,
                    style: TextStyle(fontSize: 13, color: Colors.green.shade900),
                  ),
                ),
              ],
              FilledButton.icon(
                onPressed: _isBusy ? null : _continueWithGoogle,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or with email',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 18),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty || !trimmed.contains('@')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: _isSignUp
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submitEmailAuth(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password';
                        }
                        if (_isSignUp && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isBusy ? null : _sendPasswordReset,
                          child: const Text('Forgot password?'),
                        ),
                      )
                    else
                      const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: _isBusy ? null : _submitEmailAuth,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isBusy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isSignUp ? 'Create Free Account' : 'Sign In'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MULTI-TENANT USER WORKSPACE DASHBOARD
// =============================================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.user});

  final User user;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  CollectionReference<Map<String, dynamic>> get _linksCollection =>
      FirebaseFirestore.instance.collection(kQrLinksCollection);

  /// Queries ONLY the currently signed-in user's QR links (`ownerId == uid`).
  Query<Map<String, dynamic>> get _userLinksQuery =>
      _linksCollection.where('ownerId', isEqualTo: widget.user.uid);

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

  Future<void> _openCreateOrEditDialog({QrLink? existing}) async {
    final savedSlug = await showDialog<String>(
      context: context,
      builder: (_) => QrLinkFormDialog(
        linksCollection: _linksCollection,
        ownerId: widget.user.uid,
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

  Future<void> _openQrGeneratorDialog(QrLink link) async {
    await showDialog<void>(
      context: context,
      builder: (_) => QrCodeGeneratorDialog(link: link),
    );
  }

  Future<void> _confirmDelete(QrLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete QR Link?'),
        content: Text(
          'Are you sure you want to permanently delete "${link.title}" (/r/${link.slug})?\n\n'
          'Any printed QR codes pointing to this link will stop redirecting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _linksCollection.doc(link.slug).delete();
      _showSnackBar('Deleted "/r/${link.slug}"');
    } catch (e) {
      _showSnackBar('Failed to delete link: $e');
    }
  }

  Future<void> _copyRedirectUrl(QrLink link) async {
    await Clipboard.setData(ClipboardData(text: link.redirectUrl));
    _showSnackBar('Copied ${link.redirectUrl}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayEmail = widget.user.email ?? 'My Account';

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
              'KursorQR',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                '100% GDPR Anonymous',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilledButton.icon(
              onPressed: () => _openCreateOrEditDialog(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New QR Link'),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: displayEmail,
            onSelected: (value) {
              if (value == 'signout') {
                FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Signed in as',
                      style: TextStyle(fontSize: 11),
                    ),
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
                  displayEmail.isNotEmpty ? displayEmail[0].toUpperCase() : 'U',
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _userLinksQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 40,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load your QR links',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          '${snapshot.error}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allLinks = (snapshot.data?.docs ?? [])
              .map(QrLink.fromDoc)
              .toList()
            ..sort((a, b) {
              final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final cmp = bTime.compareTo(aTime);
              return cmp != 0 ? cmp : a.slug.compareTo(b.slug);
            });

          final query = _searchQuery.trim().toLowerCase();
          final filteredLinks = query.isEmpty
              ? allLinks
              : allLinks.where((link) {
                  return link.slug.toLowerCase().contains(query) ||
                      link.title.toLowerCase().contains(query) ||
                      link.webUrl.toLowerCase().contains(query) ||
                      link.iosUrl.toLowerCase().contains(query) ||
                      link.androidUrl.toLowerCase().contains(query);
                }).toList();

          final totalScans =
              allLinks.fold<int>(0, (acc, link) => acc + link.totalScans);
          final iosScans =
              allLinks.fold<int>(0, (acc, link) => acc + link.iosScans);
          final androidScans =
              allLinks.fold<int>(0, (acc, link) => acc + link.androidScans);
          final activeCount = allLinks.where((e) => e.isActive).length;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Workspace Header
                  Text(
                    'My Dynamic QR Links',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Every scan is routed instantly via /r/<slug> with zero cookies and anonymous aggregate counters.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Aggregate Anonymous KPI Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 720;
                      final cards = [
                        _MetricCard(
                          label: 'Active QR Links',
                          value: '$activeCount / ${allLinks.length}',
                          icon: Icons.link_rounded,
                          accentColor: theme.colorScheme.primary,
                        ),
                        _MetricCard(
                          label: 'Total Scans',
                          value: '$totalScans',
                          icon: Icons.qr_code_scanner_rounded,
                          accentColor: const Color(0xFF0F766E),
                        ),
                        _MetricCard(
                          label: 'iOS Scans',
                          value: '$iosScans',
                          icon: Icons.phone_iphone_rounded,
                          accentColor: const Color(0xFF1D4ED8),
                        ),
                        _MetricCard(
                          label: 'Android Scans',
                          value: '$androidScans',
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
                            if (i < cards.length - 1) const SizedBox(width: 14),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),

                  // Search
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search your links by slug, name, or destination URL…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // List or Empty State
                  if (allLinks.isEmpty)
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
                              color: theme.colorScheme.primary.withValues(alpha: 0.7),
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
                              'Route iOS, Android, and desktop users from a single customizable QR code — '
                              'editable anytime with zero cookies or tracking.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => _openCreateOrEditDialog(),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('New QR Link'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (filteredLinks.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No QR links match "$_searchQuery".',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    )
                  else
                    ...filteredLinks.map(
                      (link) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _QrLinkCard(
                          link: link,
                          onCopyUrl: () => _copyRedirectUrl(link),
                          onOpenQr: () => _openQrGeneratorDialog(link),
                          onEdit: () => _openCreateOrEditDialog(existing: link),
                          onDelete: () => _confirmDelete(link),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
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
    required this.onOpenQr,
    required this.onEdit,
    required this.onDelete,
  });

  final QrLink link;
  final VoidCallback onCopyUrl;
  final VoidCallback onOpenQr;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      onPressed: onOpenQr,
                      icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                      label: const Text('QR Studio'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                    IconButton(
                      tooltip: 'Delete QR link',
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

// =============================================================================
// CREATE / EDIT QR LINK MODAL FORM (WITH RANDOM SLUG GENERATOR)
// =============================================================================

class QrLinkFormDialog extends StatefulWidget {
  const QrLinkFormDialog({
    super.key,
    required this.linksCollection,
    required this.ownerId,
    this.existing,
  });

  final CollectionReference<Map<String, dynamic>> linksCollection;
  final String ownerId;
  final QrLink? existing;

  @override
  State<QrLinkFormDialog> createState() => _QrLinkFormDialogState();
}

class _QrLinkFormDialogState extends State<QrLinkFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _slugController;
  late final TextEditingController _titleController;
  late final TextEditingController _webUrlController;
  late final TextEditingController _iosUrlController;
  late final TextEditingController _androidUrlController;

  late bool _isActive;
  bool _isSaving = false;
  String? _errorText;

  bool get _isEditing => widget.existing != null;

  static String _generateRandomSlug() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final rng = Random.secure();
    return List.generate(7, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _slugController = TextEditingController(
      text: existing?.slug ?? _generateRandomSlug(),
    );
    _titleController = TextEditingController(text: existing?.title ?? '');
    _webUrlController = TextEditingController(text: existing?.webUrl ?? '');
    _iosUrlController = TextEditingController(text: existing?.iosUrl ?? '');
    _androidUrlController = TextEditingController(text: existing?.androidUrl ?? '');
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _slugController.dispose();
    _titleController.dispose();
    _webUrlController.dispose();
    _iosUrlController.dispose();
    _androidUrlController.dispose();
    super.dispose();
  }

  String? _validateRequiredUrl(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return 'Fallback Web URL is required';
    if (!RegExp(r'^https?:\/\/.+', caseSensitive: false).hasMatch(trimmed)) {
      return 'Must start with https:// or http://';
    }
    if (trimmed.length > 2048) return 'URL is too long (max 2048 characters)';
    return null;
  }

  String? _validateOptionalStoreUrl(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (!RegExp(
      r'^(https?:\/\/|itms-apps:\/\/|market:\/\/).+',
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      return 'Must start with https://, http://, itms-apps://, or market://';
    }
    if (trimmed.length > 2048) return 'URL is too long (max 2048 characters)';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final slug = _slugController.text.trim().toLowerCase();
    final title = _titleController.text.trim();
    final webUrl = _webUrlController.text.trim();
    final iosUrl = _iosUrlController.text.trim();
    final androidUrl = _androidUrlController.text.trim();

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final docRef = widget.linksCollection.doc(slug);

      if (_isEditing) {
        await docRef.update({
          'title': title,
          'webUrl': webUrl,
          'iosUrl': iosUrl,
          'androidUrl': androidUrl,
          'isActive': _isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final existingDoc = await docRef.get();
        if (existingDoc.exists) {
          setState(() {
            _errorText =
                'Slug "$slug" is already taken. Try another slug or click the shuffle icon.';
            _isSaving = false;
          });
          return;
        }

        await docRef.set({
          'ownerId': widget.ownerId,
          'title': title,
          'webUrl': webUrl,
          'iosUrl': iosUrl,
          'androidUrl': androidUrl,
          'isActive': _isActive,
          'totalScans': 0,
          'iosScans': 0,
          'androidScans': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) Navigator.of(context).pop(slug);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = 'Could not save QR link: $e';
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Dynamic QR Link' : 'Create Dynamic QR Link'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                TextFormField(
                  controller: _slugController,
                  enabled: !_isEditing,
                  decoration: InputDecoration(
                    labelText: 'Short Link Slug',
                    hintText: 'e.g. my-app',
                    prefixText: 'kursorqr.web.app/r/',
                    suffixIcon: _isEditing
                        ? null
                        : IconButton(
                            tooltip: 'Generate random unique slug',
                            onPressed: () => setState(
                              () => _slugController.text = _generateRandomSlug(),
                            ),
                            icon: const Icon(Icons.shuffle_rounded),
                          ),
                    helperText: _isEditing
                        ? 'Short link path is permanent so printed QR codes never break.'
                        : 'Use lowercase a-z, 0-9, "-" or "_" (1–64 chars).',
                  ),
                  validator: (value) {
                    final slug = value?.trim().toLowerCase() ?? '';
                    if (slug.isEmpty) return 'Slug is required';
                    if (!RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$').hasMatch(slug)) {
                      return 'Use 1–64 chars: lowercase a-z, 0-9, "-" or "_"';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleController,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Campaign / Link Name',
                    hintText: 'e.g. App Store Launch Poster',
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a display name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _webUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Fallback Web URL (Required)',
                    hintText: 'https://yourdomain.com/download',
                    prefixIcon: Icon(Icons.language_rounded),
                  ),
                  validator: _validateRequiredUrl,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _iosUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'iOS App Store URL (Optional)',
                    hintText: 'https://apps.apple.com/app/id000000000',
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                  ),
                  validator: _validateOptionalStoreUrl,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _androidUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Android Play Store URL (Optional)',
                    hintText: 'https://play.google.com/store/apps/details?id=com.example.app',
                    prefixIcon: Icon(Icons.android_rounded),
                  ),
                  validator: _validateOptionalStoreUrl,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text(
                    'Turn off to pause redirection without deleting your QR code.',
                  ),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save Changes' : 'Create Link'),
        ),
      ],
    );
  }
}

// =============================================================================
// LIVE BRANDED QR STUDIO & ONE-CLICK WEB PNG DOWNLOAD
// =============================================================================

class QrCodeGeneratorDialog extends StatefulWidget {
  const QrCodeGeneratorDialog({super.key, required this.link});

  final QrLink link;

  @override
  State<QrCodeGeneratorDialog> createState() => _QrCodeGeneratorDialogState();
}

class _QrCodeGeneratorDialogState extends State<QrCodeGeneratorDialog> {
  static const List<Color> _fgSwatches = [
    Color(0xFF0F172A),
    Color(0xFF000000),
    Color(0xFF4F46E5),
    Color(0xFF1D4ED8),
    Color(0xFF047857),
    Color(0xFFBE123C),
    Color(0xFF7C3AED),
  ];

  static const List<Color> _bgSwatches = [
    Color(0xFFFFFFFF),
    Color(0xFFF8FAFC),
    Color(0xFFEEF2FF),
    Color(0xFFECFDF5),
    Color(0xFFFFFBEB),
    Color(0xFF0F172A),
  ];

  Color _fgColor = const Color(0xFF0F172A);
  Color _bgColor = const Color(0xFFFFFFFF);
  QrModuleStyle _moduleStyle = QrModuleStyle.smooth;
  int _errorCorrectLevel = QrErrorCorrectLevel.H;
  int _exportSize = 1024;
  bool _isExporting = false;

  late final TextEditingController _fgHexController;
  late final TextEditingController _bgHexController;

  @override
  void initState() {
    super.initState();
    _fgHexController = TextEditingController(text: _toHex(_fgColor));
    _bgHexController = TextEditingController(text: _toHex(_bgColor));
  }

  @override
  void dispose() {
    _fgHexController.dispose();
    _bgHexController.dispose();
    super.dispose();
  }

  String _toHex(Color color) {
    final argb = color.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Color? _parseHexColor(String raw) {
    final cleaned = raw.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(cleaned)) return null;
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  PrettyQrDecoration _buildDecoration() {
    final PrettyQrShape shape = switch (_moduleStyle) {
      QrModuleStyle.smooth => PrettyQrSmoothSymbol(color: _fgColor),
      QrModuleStyle.dots => PrettyQrDotsSymbol(color: _fgColor),
      QrModuleStyle.squares => PrettyQrSquaresSymbol(color: _fgColor),
    };

    return PrettyQrDecoration(
      background: _bgColor,
      quietZone: PrettyQrQuietZone.standard,
      shape: shape,
    );
  }

  bool get _hasLowContrast {
    final l1 = _fgColor.computeLuminance();
    final l2 = _bgColor.computeLuminance();
    final brightest = l1 > l2 ? l1 : l2;
    final darkest = l1 > l2 ? l2 : l1;
    final contrastRatio = (brightest + 0.05) / (darkest + 0.05);
    return contrastRatio < 3.5;
  }

  Future<void> _downloadPng() async {
    setState(() => _isExporting = true);
    try {
      final qrCode = QrCode.fromData(
        data: widget.link.redirectUrl,
        errorCorrectLevel: _errorCorrectLevel,
      );
      final qrImage = QrImage(qrCode);
      final byteData = await qrImage.toImageAsBytes(
        size: _exportSize,
        format: ui.ImageByteFormat.png,
        decoration: _buildDecoration(),
      );

      if (byteData == null) {
        throw StateError('QR renderer returned empty bytes.');
      }

      final bytes = byteData.buffer.asUint8List();
      final fileName = 'kursorqr-${widget.link.slug}-${_exportSize}px.png';
      downloadPngBytes(bytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Downloaded $fileName')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('PNG export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = _buildDecoration();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.qr_code_2_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.link.title),
                Text(
                  widget.link.redirectUrl,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final preview = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: PrettyQrView.data(
                      data: widget.link.redirectUrl,
                      errorCorrectLevel: _errorCorrectLevel,
                      decoration: decoration,
                    ),
                  ),
                  if (_hasLowContrast) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Low color contrast may make scanning unreliable.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );

              final controls = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Module Color', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  _ColorSwatchRow(
                    swatches: _fgSwatches,
                    selected: _fgColor,
                    hexController: _fgHexController,
                    onSelect: (color) {
                      setState(() {
                        _fgColor = color;
                        _fgHexController.text = _toHex(color);
                      });
                    },
                    onHexChanged: (text) {
                      final parsed = _parseHexColor(text);
                      if (parsed != null) setState(() => _fgColor = parsed);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Background Color', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  _ColorSwatchRow(
                    swatches: _bgSwatches,
                    selected: _bgColor,
                    hexController: _bgHexController,
                    onSelect: (color) {
                      setState(() {
                        _bgColor = color;
                        _bgHexController.text = _toHex(color);
                      });
                    },
                    onHexChanged: (text) {
                      final parsed = _parseHexColor(text);
                      if (parsed != null) setState(() => _bgColor = parsed);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Module Style', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<QrModuleStyle>(
                    segments: const [
                      ButtonSegment(
                        value: QrModuleStyle.smooth,
                        label: Text('Smooth'),
                      ),
                      ButtonSegment(
                        value: QrModuleStyle.dots,
                        label: Text('Dots'),
                      ),
                      ButtonSegment(
                        value: QrModuleStyle.squares,
                        label: Text('Classic'),
                      ),
                    ],
                    selected: {_moduleStyle},
                    onSelectionChanged: (selection) =>
                        setState(() => _moduleStyle = selection.first),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _errorCorrectLevel,
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
                              child: Text('H (30%)'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _errorCorrectLevel = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _exportSize,
                          decoration: const InputDecoration(
                            labelText: 'PNG Resolution',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 512, child: Text('512 × 512 px')),
                            DropdownMenuItem(value: 1024, child: Text('1024 × 1024 px')),
                            DropdownMenuItem(value: 2048, child: Text('2048 × 2048 px')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _exportSize = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );

              if (constraints.maxWidth < 620) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    preview,
                    const SizedBox(height: 20),
                    controls,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  preview,
                  const SizedBox(width: 28),
                  Expanded(child: controls),
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
        FilledButton.icon(
          onPressed: _isExporting ? null : _downloadPng,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_rounded),
          label: Text('Download PNG (${_exportSize}px)'),
        ),
      ],
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
