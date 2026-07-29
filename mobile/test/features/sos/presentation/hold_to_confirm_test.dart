import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sos/presentation/hold_to_confirm.dart';

void main() {
  Future<void> pumpControl(
    WidgetTester tester, {
    required VoidCallback onConfirmed,
    required VoidCallback onAccessible,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HoldToConfirm(
          label: 'Hold for 3 seconds',
          progressLabel: (percent) => 'Keep holding: $percent%',
          cancelledLabel: 'Hold cancelled',
          semanticsHint: 'Hold continuously or activate confirmation',
          accessibleLabel: 'Use dialogs',
          onConfirmed: () async => onConfirmed(),
          onAccessibleConfirm: () async => onAccessible(),
        ),
      ),
    ),
  );

  testWidgets('requires three seconds of continuous press', (tester) async {
    var confirmations = 0;
    await pumpControl(
      tester,
      onConfirmed: () => confirmations++,
      onAccessible: () {},
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Hold for 3 seconds')),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2, milliseconds: 900));
    expect(confirmations, 0);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1));
    expect(confirmations, 1);
    await gesture.up();
  });

  testWidgets('releasing early cancels and resets visible progress', (
    tester,
  ) async {
    var confirmations = 0;
    await pumpControl(
      tester,
      onConfirmed: () => confirmations++,
      onAccessible: () {},
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Hold for 3 seconds')),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Keep holding:'), findsOneWidget);
    await gesture.up();
    await tester.pump();

    expect(confirmations, 0);
    expect(find.text('Hold cancelled'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0,
    );
  });

  testWidgets('exposes an accessible activation path', (tester) async {
    var accessibleActivations = 0;
    final semantics = tester.ensureSemantics();
    await pumpControl(
      tester,
      onConfirmed: () {},
      onAccessible: () => accessibleActivations++,
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Hold for 3 seconds')),
      matchesSemantics(
        label: 'Hold for 3 seconds',
        hint: 'Hold continuously or activate confirmation',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.text('Use dialogs'));
    await tester.pump();
    expect(accessibleActivations, 1);
    semantics.dispose();
  });
}
