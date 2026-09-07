import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/safe_theme.dart';
import 'package:mobile/features/alerts/application/providers.dart';
import 'package:mobile/features/alerts/domain/earthquake.dart';
import 'package:mobile/features/navigation/presentation/app_shell.dart';
import 'package:mobile/features/alerts/presentation/widgets/data_status_banner.dart';
import 'package:mobile/l10n/app_localizations.dart';

import '../../../support/alert_fixtures.dart';
import '../../../support/fake_alert_repository.dart';

void main() {
  testWidgets(
    'Home alert action exposes an accessible target at narrow widths',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpHome(tester);

      final action = find.byKey(const ValueKey('home-alerts-card'));
      await tester.ensureVisible(action);

      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(action),
        matchesSemantics(isButton: true, hasTapAction: true),
      );
      expect(tester.getSemantics(action).label, isNotEmpty);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home leaves Map, SOS, and Guide to the bottom navigation', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.byKey(const ValueKey('home-map-card')), findsNothing);
    expect(find.byKey(const ValueKey('home-sos-card')), findsNothing);
    expect(find.byKey(const ValueKey('home-guide-card')), findsNothing);
  });

  testWidgets('Home displays the latest live earthquake and opens its detail', (
    tester,
  ) async {
    String? selectedId;
    final harness = await _pumpHome(
      tester,
      onOpenEarthquake: (id) => selectedId = id,
    );
    final latest = earthquakeFixture();
    await _finishInitialRefresh(
      tester,
      harness,
      snapshot: _snapshot(items: [latest]),
    );

    expect(find.text('Magnitude 5.2'), findsOneWidget);
    expect(find.text('Location: Myanmar'), findsOneWidget);
    expect(
      find.text('Event time: Jul 13, 2026 07:32:03 MMT (UTC+06:30)'),
      findsOneWidget,
    );
    expect(find.text('Live information'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('home-latest-earthquake-card')),
      findsOneWidget,
    );

    final statusBanner = tester.getRect(find.byType(DataStatusBanner));
    final latestCard = tester.getRect(
      find.byKey(const ValueKey('home-latest-earthquake-card')),
    );
    final listAction = tester.getRect(
      find.byKey(const ValueKey('home-alerts-card')),
    );
    expect(latestCard.top - statusBanner.bottom, greaterThanOrEqualTo(12));
    expect(listAction.top - latestCard.bottom, greaterThanOrEqualTo(12));

    await tester.ensureVisible(
      find.byKey(const ValueKey('home-latest-earthquake-card')),
    );
    await tester.tap(find.byKey(const ValueKey('home-latest-earthquake-card')));

    expect(selectedId, latest.id);
  });

  testWidgets('Home keeps successful empty results cautious', (tester) async {
    final harness = await _pumpHome(tester);
    await _finishInitialRefresh(tester, harness, snapshot: _snapshot());

    expect(
      find.text(
        'No recent earthquakes were found in the covered area. '
        'This does not guarantee there is no danger.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-latest-earthquake-card')),
      findsNothing,
    );
  });

  testWidgets('Home shows unavailable data with a refresh action', (
    tester,
  ) async {
    final harness = await _pumpHome(tester);
    await _finishInitialRefresh(
      tester,
      harness,
      error: StateError('private exception'),
    );

    expect(find.text('Live earthquake data unavailable.'), findsOneWidget);
    expect(find.textContaining('private exception'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Refresh'), findsOneWidget);
  });

  testWidgets('Home chrome uses reviewed Burmese labels', (tester) async {
    await _pumpHome(tester, locale: const Locale('my'));

    expect(find.text('ဘေးကင်းရေးစင်တာ'), findsOneWidget);
    expect(find.text('တိုက်ရိုက်ငလျင်အချက်အလက်'), findsOneWidget);
    expect(find.text('ငလျင်အချက်အလက်ကြည့်ရန်'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-map-card')), findsNothing);
    expect(find.byKey(const ValueKey('home-sos-card')), findsNothing);
    expect(find.byKey(const ValueKey('home-guide-card')), findsNothing);
  });
}

final class _HomeHarness {
  const _HomeHarness({required this.repository, required this.container});

  final FakeAlertRepository repository;
  final ProviderContainer container;
}

Future<_HomeHarness> _pumpHome(
  WidgetTester tester, {
  VoidCallback? onOpenEarthquakeInformation,
  ValueChanged<String>? onOpenEarthquake,
  Locale locale = const Locale('en'),
}) async {
  final repository = FakeAlertRepository()..queueRefresh();
  final container = ProviderContainer(
    overrides: [alertRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(() async {
    container.dispose();
    await repository.close();
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: SafeTheme.light(),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(
          onOpenEarthquakeInformation: onOpenEarthquakeInformation ?? () {},
          onOpenEarthquake: onOpenEarthquake,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _HomeHarness(repository: repository, container: container);
}

Future<void> _finishInitialRefresh(
  WidgetTester tester,
  _HomeHarness harness, {
  AlertSnapshot? snapshot,
  Object? error,
}) async {
  harness.repository.emit(null);
  final refresh = harness.container
      .read(alertListControllerProvider.notifier)
      .refresh();
  if (error != null) harness.repository.failNextSynchronously(error);
  await tester.pump();
  await tester.runAsync(() async {
    if (error == null) {
      harness.repository.completeNext(snapshot!);
    }
    await refresh;
  });
  await tester.pump();
}

AlertSnapshot _snapshot({
  List<Earthquake> items = const <Earthquake>[],
  AlertDataStatus status = AlertDataStatus.current,
}) => AlertSnapshot(
  items: items,
  dataStatus: status,
  lastSuccessfulRefreshAt: DateTime.utc(2026, 7, 13, 1, 5, 6),
);
