import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/router.dart';
import 'package:mobile/features/alerts/application/providers.dart';
import 'package:mobile/features/alerts/domain/earthquake.dart';
import 'package:mobile/features/alerts/presentation/alert_list_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';

import '../../../support/alert_fixtures.dart';
import '../../../support/fake_alert_repository.dart';

void main() {
  late FakeAlertRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeAlertRepository();
    repository.queueRefresh();
    container = ProviderContainer(
      overrides: [alertRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() async {
    container.dispose();
    await repository.close();
  });

  Future<void> pumpList(
    WidgetTester tester, {
    ValueChanged<String>? onOpenEarthquake,
  }) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AlertListScreen(onOpenEarthquake: onOpenEarthquake),
        ),
      ),
    );
  }

  Future<void> finishInitialRefresh(
    WidgetTester tester, {
    AlertSnapshot? snapshot,
    Object? error,
  }) async {
    final refresh = container
        .read(alertListControllerProvider.notifier)
        .refresh();
    if (error != null) repository.failNextSynchronously(error);
    await tester.pump();
    await tester.runAsync(() async {
      if (error == null) repository.completeNext(snapshot!);
      await refresh;
    });
    await tester.pump();
  }

  testWidgets('loading without cache has localized progress semantics', (
    tester,
  ) async {
    await pumpList(tester);

    expect(find.text('Updating earthquake information'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(CircularProgressIndicator)),
      matchesSemantics(label: 'Updating earthquake information'),
    );
  });

  testWidgets('live list displays required content in earthquake order', (
    tester,
  ) async {
    final first = earthquakeFixture();
    final second = earthquakeFixture(
      id: 'usgs:id/with space',
      providerEventId: 'id/with space',
      title: 'unused title',
    );
    await pumpList(tester);
    repository.emit(null);
    await finishInitialRefresh(
      tester,
      snapshot: _snapshot(items: [first, second]),
    );

    expect(container.read(alertListControllerProvider).items, [first, second]);
    expect(find.text('Earthquake information'), findsNWidgets(3));
    expect(find.text('Magnitude 5.2'), findsNWidgets(2));
    expect(find.text('Location: Myanmar'), findsNWidgets(2));
    expect(
      find.text('Event time: Jul 13, 2026, 01:02:03 UTC'),
      findsNWidgets(2),
    );
    expect(find.text('Live information'), findsNWidgets(3));
    expect(find.text('Source: USGS'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('Magnitude 5.2').at(0)).dy,
      lessThan(tester.getTopLeft(find.text('Magnitude 5.2').at(1)).dy),
    );
  });

  testWidgets('cached data stays visible while refresh is pending', (
    tester,
  ) async {
    await pumpList(tester);
    repository.emit(_snapshot());
    await tester.pump();

    expect(find.text('Magnitude 5.2'), findsOneWidget);
    expect(find.text('Cached information'), findsNWidgets(2));
    expect(find.text('Updating earthquake information'), findsOneWidget);
    final refresh = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Refresh'),
    );
    expect(refresh.onPressed, isNull);
  });

  testWidgets('stale data keeps saved information and safe failure copy', (
    tester,
  ) async {
    await pumpList(tester);
    repository.emit(_snapshot());
    await finishInitialRefresh(
      tester,
      error: StateError('database path secret'),
    );

    expect(find.text('Stale information'), findsNWidgets(2));
    expect(find.text('Could not update live information.'), findsOneWidget);
    expect(
      find.text('Previously saved information remains available below.'),
      findsOneWidget,
    );
    expect(find.textContaining('secret'), findsNothing);
  });

  testWidgets('current empty data uses exact cautious wording', (tester) async {
    await pumpList(tester);
    repository.emit(null);
    await finishInitialRefresh(tester, snapshot: _snapshot(items: const []));

    expect(
      find.text(
        'No recent earthquakes were found in the covered area. '
        'This does not guarantee there is no danger.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('stale empty data never implies successful live absence', (
    tester,
  ) async {
    await pumpList(tester);
    repository.emit(_snapshot(items: const [], status: AlertDataStatus.stale));
    await tester.pump();

    expect(find.text('Stale information'), findsOneWidget);
    expect(find.textContaining('No recent earthquakes'), findsNothing);
    expect(
      find.text('Previously saved information remains available below.'),
      findsOneWidget,
    );
  });

  testWidgets('unavailable state has exact copy and no empty reassurance', (
    tester,
  ) async {
    await pumpList(tester);
    repository.emit(null);
    await finishInitialRefresh(tester, error: StateError('private exception'));

    expect(find.text('Live earthquake data unavailable.'), findsOneWidget);
    expect(find.textContaining('No recent earthquakes'), findsNothing);
    expect(find.textContaining('private exception'), findsNothing);
    final size = tester.getSize(find.widgetWithText(OutlinedButton, 'Refresh'));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('refresh coalesces and card returns encoded route identifier', (
    tester,
  ) async {
    String? selectedId;
    final event = earthquakeFixture(
      id: 'usgs:id/with space',
      providerEventId: 'id/with space',
    );
    await pumpList(
      tester,
      onOpenEarthquake: (id) => selectedId = Uri.encodeComponent(id),
    );
    repository.emit(null);
    await finishInitialRefresh(tester, snapshot: _snapshot(items: [event]));
    repository.queueRefresh();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
    await tester.pump();
    expect(repository.refreshCalls, 2);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Refresh'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.ancestor(
        of: find.text('Magnitude 5.2'),
        matching: find.byType(Card),
      ),
    );
    expect(selectedId, 'usgs%3Aid%2Fwith%20space');
  });

  testWidgets('presentation excludes unsafe and internal classification copy', (
    tester,
  ) async {
    await pumpList(tester);
    repository.emit(null);
    await finishInitialRefresh(tester, snapshot: _snapshot());

    final visibleText = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data ?? '')
        .join(' ')
        .toLowerCase();
    expect(visibleText, isNot(contains('simulation')));
    expect(visibleText, isNot(contains('warning')));
    expect(visibleText, isNot(contains('prediction')));
    expect(visibleText, isNot(contains('severity')));
  });

  testWidgets('app starts on list and card navigation preserves encoded ID', (
    tester,
  ) async {
    final event = earthquakeFixture(
      id: 'usgs:id/with space',
      providerEventId: 'id/with space',
    );
    repository.lookupResult = event;
    final router = createRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: SafeMyanmarApp(router: router),
      ),
    );
    repository.emit(null);
    await finishInitialRefresh(tester, snapshot: _snapshot(items: [event]));

    await tester.tap(
      find.ancestor(
        of: find.text('Magnitude 5.2'),
        matching: find.byType(Card),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.lookupIds, ['usgs:id/with space']);
    expect(find.text('Depth: 12.5 km'), findsOneWidget);
  });

  testWidgets('unknown route has localized 48 dp recovery action', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/missing');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: SafeMyanmarApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Earthquake information was not found.'), findsOneWidget);
    final action = find.widgetWithText(
      OutlinedButton,
      'Back to earthquake information',
    );
    final size = tester.getSize(action);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));

    await tester.tap(action);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Updating earthquake information'), findsOneWidget);
  });
}

final _refreshedAt = DateTime.utc(2026, 7, 13, 1, 5, 6);

AlertSnapshot _snapshot({
  List<Earthquake>? items,
  AlertDataStatus status = AlertDataStatus.current,
}) => AlertSnapshot(
  items: items ?? [earthquakeFixture()],
  dataStatus: status,
  lastSuccessfulRefreshAt: _refreshedAt,
);
