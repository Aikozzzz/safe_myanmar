// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/app.dart';
import 'package:mobile/features/alerts/application/providers.dart';

import 'support/fake_alert_repository.dart';

void main() {
  testWidgets('SafeMyanmar app starts on the Home screen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    final repository = FakeAlertRepository()..queueRefresh();
    addTearDown(repository.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [alertRepositoryProvider.overrideWithValue(repository)],
        child: SafeMyanmarApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}
