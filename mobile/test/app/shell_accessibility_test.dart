import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/router.dart';

void main() {
  testWidgets('shell fits 390x844 at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: SafeMyanmarApp(router: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('View earthquake information'), findsOneWidget);
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byType(Scaffold).first),
      ).scale(10),
      20,
    );
    final destinations = find.byType(NavigationDestination);
    expect(destinations, findsNWidgets(5));
    for (var index = 0; index < 5; index++) {
      final size = tester.getSize(destinations.at(index));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();

    expect(find.text('Location access is off'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Use my location'), 100);
    expect(find.text('Use my location'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
