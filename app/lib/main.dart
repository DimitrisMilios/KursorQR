import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'repositories/auth_repository.dart';
import 'repositories/qr_link_repository.dart';
import 'services/qr_render_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'views/dashboard_screen.dart';
import 'views/landing_page.dart';
import 'views/verify_email_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  try {
    await Firebase.initializeApp(options: AppConfig.firebaseWebOptions);
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
    return MaterialApp(
      title: 'KursorQR — Free GDPR-Compliant Dynamic QR Codes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: initError != null
          ? _FirebaseInitErrorScreen(error: initError!)
          : const _AppShell(),
    );
  }
}

/// Composition root wiring MVVM Repositories, Services, and ViewModels cleanly.
class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  late final AuthRepository _authRepository;
  late final QrLinkRepository _qrLinkRepository;
  late final QrRenderService _qrRenderService;
  late final AuthViewModel _authViewModel;

  DashboardViewModel? _dashboardViewModel;
  String? _activeDashboardUid;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _qrLinkRepository = QrLinkRepository();
    _qrRenderService = QrRenderService();
    _authViewModel = AuthViewModel(
      authRepository: _authRepository,
      qrLinkRepository: _qrLinkRepository,
    );
  }

  @override
  void dispose() {
    _dashboardViewModel?.dispose();
    _authViewModel.dispose();
    super.dispose();
  }

  DashboardViewModel _ensureDashboardViewModel(String uid, String email) {
    if (_dashboardViewModel == null || _activeDashboardUid != uid) {
      _dashboardViewModel?.dispose();
      _activeDashboardUid = uid;
      _dashboardViewModel = DashboardViewModel(
        repository: _qrLinkRepository,
        ownerId: uid,
        ownerEmail: email,
      );
    }
    return _dashboardViewModel!;
  }

  void _clearDashboardViewModelIfNeeded() {
    if (_dashboardViewModel != null) {
      _dashboardViewModel?.dispose();
      _dashboardViewModel = null;
      _activeDashboardUid = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authViewModel,
      builder: (context, _) {
        if (_authViewModel.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = _authViewModel.user;
        if (user == null) {
          _clearDashboardViewModelIfNeeded();
          return LandingPage(
            authViewModel: _authViewModel,
            renderService: _qrRenderService,
          );
        }

        // Enforce email verification for Email/Password signups (Google Sign-In is verified automatically).
        if (!user.emailVerified) {
          _clearDashboardViewModelIfNeeded();
          return VerifyEmailScreen(authViewModel: _authViewModel);
        }

        final dashVm = _ensureDashboardViewModel(
          user.uid,
          user.email ?? 'My Account',
        );

        return DashboardScreen(
          authViewModel: _authViewModel,
          dashboardViewModel: dashVm,
          renderService: _qrRenderService,
        );
      },
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
                    'AppConfig.firebaseWebOptions in app/lib/core/app_config.dart.',
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
