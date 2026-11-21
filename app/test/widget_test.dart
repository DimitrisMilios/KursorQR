import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kursorqr/core/qr_icon_catalog.dart';
import 'package:kursorqr/main.dart';
import 'package:kursorqr/models/qr_design_config.dart';
import 'package:kursorqr/services/qr_render_service.dart';
import 'package:kursorqr/viewmodels/qr_studio_viewmodel.dart';
import 'package:kursorqr/views/dialogs/gdpr_policy_dialog.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

void main() {
  testWidgets('Renders Firebase init error screen when initError is supplied',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const KursorQrApp(initError: 'Test init error'),
    );

    expect(find.text('Firebase Initialization Error'), findsOneWidget);
    expect(find.text('Test init error'), findsOneWidget);
  });

  testWidgets('Renders GDPR Privacy & Cookie Transparency dialog',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: GdprPolicyDialog()));

    expect(find.text('GDPR Privacy & Cookie Transparency'), findsOneWidget);
    expect(find.textContaining('Zero advertising cookies'), findsOneWidget);
    expect(find.textContaining('Right to Erasure'), findsOneWidget);
  });

  test('QrDesignConfig serializes and restores linear gradients & iconId cleanly',
      () {
    const original = QrDesignConfig(
      useGradient: true,
      fgColor: Color(0xFF4F46E5),
      fgColorEnd: Color(0xFFE11D48),
      gradientDirection: QrGradientDirection.horizontal,
      bgColor: Color(0xFFFFFFFF),
      style: QrModuleStyle.dots,
      iconId: 'app_store',
      errorLevel: QrErrorCorrectLevel.H,
    );

    final restored = QrDesignConfig.fromMap(original.toMap());
    expect(restored, equals(original));
    expect(restored.hasLowContrast, isFalse);
  });

  test('QrStudioViewModel switches gradients, icons, and boosts error level to H',
      () {
    final vm = QrStudioViewModel(
      renderService: QrRenderService(),
      data: 'https://kursorqr.web.app/r/demo',
      initialDesign: const QrDesignConfig(
        errorLevel: QrErrorCorrectLevel.M,
      ),
    );
    addTearDown(vm.dispose);

    expect(vm.design.useGradient, isFalse);
    expect(vm.effectiveErrorLevel, QrErrorCorrectLevel.M);

    vm.applyGradientPreset(QrStudioViewModel.gradientPresets.first);
    expect(vm.design.useGradient, isTrue);

    vm.selectBuiltInIcon(QrIconCatalog.all.first.id);
    expect(vm.hasAnyCenterLogo, isTrue);
    expect(vm.effectiveErrorLevel, QrErrorCorrectLevel.H);

    vm.clearCenterImage();
    expect(vm.hasAnyCenterLogo, isFalse);
  });
}
