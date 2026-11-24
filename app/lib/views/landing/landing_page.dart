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

/// Public landing page with a true floating clay navbar layered over the
/// full-height scrollable content (so scrolled sections glide underneath).
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
  static const double _navbarClearance = 112;

  late final LandingViewModel _landingVm;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _sandboxKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _landingVm = LandingViewModel(renderService: widget.renderService);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    final ctx = _sandboxKey.currentContext;
    if (ctx == null || !_scrollController.hasClients) return;
    final box = ctx.findRenderObject();
    final scrollable = Scrollable.of(ctx).context.findRenderObject();
    if (box is! RenderBox || scrollable is! RenderBox) return;
    final top = box.localToGlobal(Offset.zero, ancestor: scrollable).dy;
    final target = (_scrollController.offset + top - _navbarClearance + 8)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    if (!ClayMotion.of(context).enabled) {
      _scrollController.jumpTo(target);
      return;
    }
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 480),
      curve: ClaySpringCurve.gentle,
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
              // 1. Full-height scrollable page gliding underneath the floating navbar
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    top: _navbarClearance,
                    left: 24,
                    right: 24,
                    bottom: 24,
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
                          const SizedBox(height: AppDimensions.spacingSection),
                          KeyedSubtree(
                            key: _sandboxKey,
                            child: InstantQrSandbox(
                              sandboxVm: _landingVm.sandboxViewModel,
                              onMakeDynamic: () =>
                                  _openAuth(startInSignUp: true),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingSection),
                          const LandingFeaturesSection(),
                          const SizedBox(height: 36),
                          LandingFooter(onOpenPrivacy: _openPrivacyPolicy),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Sticky floating clay navbar on top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LandingNavbar(
                  onOpenPrivacy: _openPrivacyPolicy,
                  onSignIn: () => _openAuth(startInSignUp: false),
                  onStartFree: () => _openAuth(startInSignUp: true),
                ),
              ),

              // 3. Floating bottom GDPR transparency banner
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
