import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'repositories/auth_repository.dart';
import 'repositories/qr_link_repository.dart';
import 'services/clipboard_service.dart';
import 'services/qr_render_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'views/dashboard_screen.dart';
import 'views/landing_page.dart';
import 'views/verify_email_screen.dart';
import 'widgets/clay/clay.dart';
import 'widgets/shared/ambient_background.dart';

/// Root application widget wiring MVVM dependencies via [MultiProvider],
/// exposing [ClayMotionScope] for reduced-motion support, and painting the
/// warm claymorphism theme.
class KursorQrApp extends StatelessWidget {
  const KursorQrApp({super.key, this.initError});

  final String? initError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KursorQR — Free GDPR-Compliant Dynamic QR Codes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) => ClayMotionScope.fromMediaQuery(
        child: child ?? const SizedBox.shrink(),
      ),
      home: initError != null
          ? FirebaseInitErrorScreen(error: initError!)
          : const _AppCompositionRoot(),
    );
  }
}

class _AppCompositionRoot extends StatefulWidget {
  const _AppCompositionRoot();

  @override
  State<_AppCompositionRoot> createState() => _AppCompositionRootState();
}

class _AppCompositionRootState extends State<_AppCompositionRoot> {
  late final AuthRepository _authRepository;
  late final QrLinkRepository _qrLinkRepository;
  late final QrRenderService _qrRenderService;
  late final ClipboardService _clipboardService;
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _qrLinkRepository = QrLinkRepository();
    _qrRenderService = QrRenderService();
    _clipboardService = const ClipboardService();
    _authViewModel = AuthViewModel(
      authRepository: _authRepository,
      qrLinkRepository: _qrLinkRepository,
    );
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<QrLinkRepository>.value(value: _qrLinkRepository),
        Provider<QrRenderService>.value(value: _qrRenderService),
        Provider<ClipboardService>.value(value: _clipboardService),
        ChangeNotifierProvider<AuthViewModel>.value(value: _authViewModel),
      ],
      child: const _AuthRouteGate(),
    );
  }
}

class _AuthRouteGate extends StatefulWidget {
  const _AuthRouteGate();

  @override
  State<_AuthRouteGate> createState() => _AuthRouteGateState();
}

class _AuthRouteGateState extends State<_AuthRouteGate> {
  DashboardViewModel? _dashboardViewModel;
  String? _activeDashboardUid;

  @override
  void dispose() {
    _dashboardViewModel?.dispose();
    super.dispose();
  }

  DashboardViewModel _ensureDashboardViewModel(
    BuildContext context,
    String uid,
    String email,
  ) {
    if (_dashboardViewModel == null || _activeDashboardUid != uid) {
      _dashboardViewModel?.dispose();
      _activeDashboardUid = uid;
      _dashboardViewModel = DashboardViewModel(
        repository: context.read<QrLinkRepository>(),
        clipboardService: context.read<ClipboardService>(),
        ownerId: uid,
        ownerEmail: email,
      );
    }
    return _dashboardViewModel!;
  }

  void _clearDashboardIfNeeded() {
    if (_dashboardViewModel != null) {
      _dashboardViewModel?.dispose();
      _dashboardViewModel = null;
      _activeDashboardUid = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final renderService = context.read<QrRenderService>();

    if (authVm.isInitializing) {
      return const Scaffold(
        body: AmbientBackground(
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    final user = authVm.user;
    if (user == null) {
      _clearDashboardIfNeeded();
      return LandingPage(
        authViewModel: authVm,
        renderService: renderService,
      );
    }

    if (!user.emailVerified) {
      _clearDashboardIfNeeded();
      return VerifyEmailScreen(authViewModel: authVm);
    }

    final dashVm = _ensureDashboardViewModel(
      context,
      user.uid,
      user.email ?? 'My Account',
    );

    return ChangeNotifierProvider<DashboardViewModel>.value(
      value: dashVm,
      child: DashboardScreen(
        authViewModel: authVm,
        dashboardViewModel: dashVm,
        renderService: renderService,
      ),
    );
  }
}

/// Claymorphism fallback shown if Firebase fails to initialize.
class FirebaseInitErrorScreen extends StatelessWidget {
  const FirebaseInitErrorScreen({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ClayPanel(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: const ClayDecoration.well(
                            color: AppColors.coralSoft,
                            radius: 14,
                            depth: 4,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.coralDeep,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Firebase Initialization Error',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to initialize Firebase for KursorQR. Verify '
                      'AppConfig.firebaseWebOptions in app/lib/core/app_config.dart.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClayWell.coral(
                      child: SelectableText(
                        error,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          color: AppColors.coralDeep,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
