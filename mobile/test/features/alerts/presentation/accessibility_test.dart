import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/router.dart';
import 'package:mobile/app/theme/safe_theme.dart';
import 'package:mobile/features/alerts/application/providers.dart';
import 'package:mobile/features/alerts/domain/earthquake.dart';
import 'package:mobile/features/alerts/presentation/alert_detail_screen.dart';
import 'package:mobile/features/alerts/presentation/alert_list_screen.dart';
import 'package:mobile/features/alerts/presentation/source_launcher.dart';
import 'package:mobile/features/alerts/presentation/widgets/data_status_banner.dart';
import 'package:mobile/features/alerts/presentation/widgets/earthquake_card.dart';
import 'package:mobile/l10n/app_localizations.dart';

import '../../../support/alert_fixtures.dart';
import '../../../support/fake_alert_repository.dart';

void main() {
  late FakeAlertRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeAlertRepository()..queueRefresh();
    container = ProviderContainer(
      overrides: [
        alertRepositoryProvider.overrideWithValue(repository),
        sourceLauncherProvider.overrideWithValue((_) async => true),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await repository.close();
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    ThemeData? theme,
    double textScale = 2,
    Size size = const Size(320, 640),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: theme ?? SafeTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
  }

  Future<void> finishList(
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

  void expectNoOverflow(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    }
  }

  testWidgets('loading list wraps at 200 percent on a narrow phone', (
    tester,
  ) async {
    await pumpScreen(tester, const AlertListScreen());

    expect(find.text('Updating earthquake information'), findsOneWidget);
    expectNoOverflow(tester);
  });

  testWidgets('unavailable list wraps at 200 percent on a narrow phone', (
    tester,
  ) async {
    await pumpScreen(tester, const AlertListScreen());
    repository.emit(null);
    await finishList(tester, error: StateError('private path'));

    expect(find.text('Live earthquake data unavailable.'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
    expectNoOverflow(tester);
  });

  testWidgets('empty list keeps exact caution at 200 percent', (tester) async {
    await pumpScreen(tester, const AlertListScreen());
    repository.emit(null);
    await finishList(tester, snapshot: _snapshot(items: const []));

    expect(
      find.text(
        'No recent earthquakes were found in the covered area. '
        'This does not guarantee there is no danger.',
      ),
      findsOneWidget,
    );
    expectNoOverflow(tester);
  });

  testWidgets('populated list preserves essential text at 200 percent', (
    tester,
  ) async {
    await pumpScreen(tester, const AlertListScreen());
    repository.emit(null);
    await finishList(tester, snapshot: _snapshot());

    expect(find.text('Magnitude 5.2'), findsOneWidget);
    expect(find.text('Location: Myanmar'), findsOneWidget);
    expect(find.text('Event time: Jul 13, 2026 01:02:03 UTC'), findsOneWidget);
    expect(find.text('Source: USGS'), findsOneWidget);
    expectNoOverflow(tester);
  });

  testWidgets('detail preserves every essential field at 200 percent', (
    tester,
  ) async {
    repository.lookupResult = earthquakeFixture();
    await pumpScreen(
      tester,
      const AlertDetailScreen(earthquakeId: 'usgs:example'),
    );
    await tester.pumpAndSettle();

    for (final text in <String>[
      'Earthquake information',
      'Magnitude 5.2',
      'Location: Myanmar',
      'Depth: 12.5 km',
      'Event time: Jul 13, 2026 01:02:03 UTC',
      'Provider update: Jul 13, 2026 01:03:04 UTC',
      'Retrieved: Jul 13, 2026 01:04:05 UTC',
      'Review status: reviewed',
      'Source: USGS',
      'Preliminary earthquake values may change.',
      'Open USGS source',
    ]) {
      final matches = find.text(text);
      final target = matches.evaluate().length > 1 ? matches.last : matches;
      await tester.scrollUntilVisible(target, 120);
      expect(find.text(text), findsWidgets);
    }
    expectNoOverflow(tester);
  });

  testWidgets('cards and actions expose complete semantics and 48 dp targets', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      AlertListScreen(onOpenEarthquake: (_) {}),
      textScale: 1,
    );
    repository.emit(null);
    await finishList(tester, snapshot: _snapshot());

    expect(
      tester.getSemantics(find.byType(EarthquakeCard)),
      matchesSemantics(
        label:
            'Earthquake information. Magnitude 5.2. Location: Myanmar. '
            'Event time: Jul 13, 2026 01:02:03 UTC. Live information. '
            'Source: USGS',
        hint: 'Open earthquake information details',
        isButton: true,
        hasTapAction: true,
      ),
    );
    final refresh = find.widgetWithText(OutlinedButton, 'Refresh');
    expect(
      tester.getSemantics(refresh),
      matchesSemantics(
        label: 'Refresh',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasFocusAction: true,
        hasTapAction: true,
      ),
    );
    for (final target in [refresh, find.byType(EarthquakeCard)]) {
      final size = tester.getSize(target);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }

    repository.lookupResult = earthquakeFixture();
    await pumpScreen(
      tester,
      const AlertDetailScreen(earthquakeId: 'usgs:example'),
      textScale: 1,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Open USGS source'), 120);
    final sourceAction = find.widgetWithText(
      OutlinedButton,
      'Open USGS source',
    );
    expect(
      tester.getSemantics(sourceAction),
      matchesSemantics(
        label: 'Open USGS source',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasFocusAction: true,
        hasTapAction: true,
      ),
    );
    final sourceSize = tester.getSize(sourceAction);
    expect(sourceSize.width, greaterThanOrEqualTo(48));
    expect(sourceSize.height, greaterThanOrEqualTo(48));
  });

  testWidgets(
    'cached status and updating state are announced with disabled target size',
    (tester) async {
      await pumpScreen(tester, const AlertListScreen(), textScale: 1);
      repository.emit(_snapshot());
      await tester.pump();

      expect(
        tester.getSemantics(find.byType(DataStatusBanner)),
        matchesSemantics(
          label:
              'Cached information. Last successful update: '
              'Jul 13, 2026 01:05:06 UTC',
          isLiveRegion: true,
        ),
      );
      expect(
        tester.getSemantics(find.byType(CircularProgressIndicator)),
        matchesSemantics(
          label: 'Updating earthquake information',
          isLiveRegion: true,
        ),
      );
      final refresh = find.widgetWithText(OutlinedButton, 'Refresh');
      expect(tester.widget<OutlinedButton>(refresh).onPressed, isNull);
      final size = tester.getSize(refresh);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      await tester.tap(refresh);
      await tester.pump();
      expect(repository.refreshCalls, 1);
    },
  );

  testWidgets('detail semantics expose required labels in traversal order', (
    tester,
  ) async {
    repository.lookupResult = earthquakeFixture();
    await pumpScreen(
      tester,
      const AlertDetailScreen(earthquakeId: 'usgs:example'),
      textScale: 1,
      size: const Size(420, 1200),
    );
    await tester.pumpAndSettle();

    final labels = <String>[
      'Magnitude 5.2',
      'Location: Myanmar',
      'Depth: 12.5 km',
      'Event time: Jul 13, 2026 01:02:03 UTC',
      'Provider update: Jul 13, 2026 01:03:04 UTC',
      'Retrieved: Jul 13, 2026 01:04:05 UTC',
      'Review status: reviewed',
      'Source: USGS',
      'Preliminary earthquake values may change.',
      'Open USGS source',
    ];
    expect(find.bySemanticsLabel('Earthquake information'), findsWidgets);
    for (final label in labels) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }

    final positions = labels
        .map((label) => tester.getTopLeft(find.text(label)).dy)
        .toList();
    expect(positions, orderedEquals([...positions]..sort()));
  });

  testWidgets('routed detail standard back target is at least 48 dp', (
    tester,
  ) async {
    final event = earthquakeFixture();
    repository.lookupResult = event;
    final router = createRouter(initialLocation: '/alerts');
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: SafeMyanmarApp(router: router),
      ),
    );
    repository.emit(null);
    await finishList(tester, snapshot: _snapshot(items: [event]));

    await tester.tap(find.text('Magnitude 5.2'));
    await tester.pumpAndSettle();

    final back = find.byType(BackButton);
    expect(back, findsOneWidget);
    final size = tester.getSize(back);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  for (final entry in <String, ThemeData>{
    'light': SafeTheme.light(),
    'dark': SafeTheme.dark(),
  }.entries) {
    testWidgets('${entry.key} theme renders the localized list', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const AlertListScreen(),
        theme: entry.value,
        textScale: 1,
      );

      expect(
        Theme.of(tester.element(find.byType(AlertListScreen))).brightness,
        entry.value.brightness,
      );
      expect(find.text('Earthquake information'), findsOneWidget);
      expectNoOverflow(tester);
    });
  }
}

final _refreshedAt = DateTime.utc(2026, 7, 13, 1, 5, 6);

AlertSnapshot _snapshot({List<Earthquake>? items}) => AlertSnapshot(
  items: items ?? [earthquakeFixture()],
  dataStatus: AlertDataStatus.current,
  lastSuccessfulRefreshAt: _refreshedAt,
);
