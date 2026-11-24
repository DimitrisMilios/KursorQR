import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/qr_design_config.dart';
import '../services/qr_render_service.dart';
import 'qr_studio_viewmodel.dart';

/// MVVM ViewModel for the public Landing Page, managing the floating GDPR
/// transparency banner and the instant no-login QR Studio sandbox.
class LandingViewModel extends ChangeNotifier {
  LandingViewModel({required QrRenderService renderService})
      : sandboxViewModel = QrStudioViewModel(
          renderService: renderService,
          data: defaultSandboxUrl,
          initialDesign: const QrDesignConfig(
            useGradient: true,
            fgColor: AppColors.primaryDeep,
            fgColorEnd: AppColors.primaryLight,
            gradientDirection: QrGradientDirection.diagonalDown,
            style: QrModuleStyle.smooth,
            iconId: 'app_store',
          ),
          slugForFilename: 'instant',
        );

  static const String defaultSandboxUrl = 'https://kursorqr.web.app';

  final QrStudioViewModel sandboxViewModel;

  bool _showGdprBanner = true;

  bool get showGdprBanner => _showGdprBanner;

  void dismissGdprBanner() {
    if (!_showGdprBanner) return;
    _showGdprBanner = false;
    notifyListeners();
  }

  @override
  void dispose() {
    sandboxViewModel.dispose();
    super.dispose();
  }
}
