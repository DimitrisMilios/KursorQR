import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kursorqr/views/dialogs/confirm_danger_dialog.dart';
import 'package:kursorqr/widgets/clay/clay.dart';

Widget _wrapReducedMotion(Widget child) {
  return MaterialApp(
    home: ClayMotionScope(
      motion: const ClayMotion(enabled: false),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('ClayButton fires callback on tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrapReducedMotion(
        ClayButton.primary(
          label: 'Create link',
          onPressed: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Create link'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('ClaySegmented switches active option on tap', (tester) async {
    var selected = 'a';
    await tester.pumpWidget(
      _wrapReducedMotion(
        StatefulBuilder(
          builder: (context, setState) => ClaySegmented<String>(
            selected: selected,
            onChanged: (v) => setState(() => selected = v),
            segments: const [
              ClaySegment(value: 'a', label: 'Solid'),
              ClaySegment(value: 'b', label: 'Gradient'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Gradient'));
    await tester.pumpAndSettle();
    expect(selected, 'b');
  });

  testWidgets('ClayToggle flips boolean state on tap', (tester) async {
    var value = true;
    await tester.pumpWidget(
      _wrapReducedMotion(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 300,
            child: ClayToggle(
              value: value,
              label: 'Active',
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ClayToggle));
    await tester.pumpAndSettle();
    expect(value, isFalse);
  });

  testWidgets('ClayField shows inline validation error text', (tester) async {
    await tester.pumpWidget(
      _wrapReducedMotion(
        const SizedBox(
          width: 320,
          child: ClayField(
            label: 'Email',
            errorText: 'Enter a valid email address',
          ),
        ),
      ),
    );

    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('ConfirmDangerDialog returns true when confirmed', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: ClayMotionScope(
          motion: const ClayMotion(enabled: false),
          child: Scaffold(
            body: Builder(
              builder: (context) => ClayButton.danger(
                label: 'Open',
                onPressed: () async {
                  result = await showClayDialog<bool>(
                    context: context,
                    builder: (_) => const ConfirmDangerDialog(
                      title: 'Delete link',
                      message: 'This cannot be undone.',
                      confirmLabel: 'Delete',
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete link'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
