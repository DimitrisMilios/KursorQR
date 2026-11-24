import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_dimensions.dart';
import '../../services/qr_render_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/landing_viewmodel.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/ambient_background.dart';
import '../dialogs/auth_dialog.dart';
import '../dialogs/gdpr_policy_dialog.dart';
import 'gdpr_floating_banner.dart';
import 'instant_qr_sandbox.dart';
import 'landing_features_section.dart';
import 'landing_footer.dart';
import 'landing_hero_section.dart';
import 'landing_navbar.dart';

/// Public landing page composed strictly of declarative clay widgets wired to
/// [LandingViewModel] and [AuthViewModel].
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
  late final LandingViewModel _landingVm;
  final GlobalKey _sandboxKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _landingVm = LandingViewModel(renderService: widget.renderService);
  }

  @override
  void dispose() {
    _landingVm.dispose();
    super.dispose();
  }

  Future<void> _openAuth({required bool startInSignUp}) async {
    await showClayDialog<void>(
      context: context,
      builder: (_) => AuthDialog(
        authViewModel: widget.authViewModel,
        initialIsSignUp: startInSignUp,
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    await showClayDialog<void>(
      context: context,
      builder: (_) => const GdprPolicyDialog(),
    );
  }

  void _scrollToSandbox() {
    final target = _sandboxKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 520),
      curve: ClaySpringCurve.gentle,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LandingViewModel>.value(
      value: _landingVm,
      child: Scaffold(
        body: AmbientBackground(
          child: Stack(
            children: [
              Column(
                children: [
                  LandingNavbar(
                    onOpenPrivacy: _openPrivacyPolicy,
                    onSignIn: () => _openAuth(startInSignUp: false),
                    onStartFree: () => _openAuth(startInSignUp: true),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppDimensions.maxContentWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LandingHeroSection(
                                onCreateAccount: () =>
                                    _openAuth(startInSignUp: true),
                                onTrySandbox: _scrollToSandbox,
                              ),
                              const SizedBox(
                                height: AppDimensions.spacingSection,
                              ),
                              KeyedSubtree(
                                key: _sandboxKey,
                                child: InstantQrSandbox(
                                  sandboxVm: _landingVm.sandboxViewModel,
                                  onMakeDynamic: () =>
                                      _openAuth(startInSignUp: true),
                                ),
                              ),
                              const SizedBox(
                                height: AppDimensions.spacingSection,
                              ),
                              const LandingFeaturesSection(),
                              const SizedBox(height: 36),
                              LandingFooter(
                                onOpenPrivacy: _openPrivacyPolicy,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Selector<LandingViewModel, bool>(
                  selector: (_, vm) => vm.showGdprBanner,
                  builder: (context, visible, _) => GdprFloatingBanner(
                    visible: visible,
                    onOpenPolicy: _openPrivacyPolicy,
                    onDismiss: _landingVm.dismissGdprBanner,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
