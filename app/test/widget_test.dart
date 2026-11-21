import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kursorqr/main.dart';

void main() {
  testWidgets('Renders Firebase init error screen when initError is supplied',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const KursorQrApp(initError: 'Test init error'),
    );

    expect(find.text('Firebase Initialization Error'), findsOneWidget);
    expect(find.text('Test init error'), findsOneWidget);
  });

  testWidgets('Renders public KursorQR landing page & instant QR sandbox',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: LandingPage()));

    expect(find.text('KursorQR'), findsOneWidget);
    expect(find.text('Try Instant QR Generator'), findsOneWidget);
    expect(find.text('Create Free Dynamic QR'), findsOneWidget);
  });
}
