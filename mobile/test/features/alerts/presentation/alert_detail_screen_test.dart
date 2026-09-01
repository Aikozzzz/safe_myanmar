import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/alerts/application/providers.dart';
import 'package:mobile/features/alerts/domain/earthquake.dart';
import 'package:mobile/features/alerts/presentation/alert_detail_screen.dart';
import 'package:mobile/features/alerts/presentation/source_launcher.dart';
import 'package:mobile/l10n/app_localizations.dart';

import '../../../support/alert_fixtures.dart';
import '../../../support/fake_alert_repository.dart';

void main() {
  late FakeAlertRepository repository;
  late List<Uri> launchedUris;
  late Future<bool> Function(Uri) launcher;

  setUp(() {
    repository = FakeAlertRepository();
    launchedUris = [];
    launcher = (uri) async {
      launchedUris.add(uri);
      return true;
    };
  });

  tearDown(() => repository.close());

  Future<void> pumpDetail(
    WidgetTester tester, {
    String id = 'usgs:example',
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertRepositoryProvider.overrideWithValue(repository),
          sourceLauncherProvider.overrideWithValue(launcher),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AlertDetailScreen(earthquakeId: id),
        ),
      ),
    );
  }

  testWidgets('loads by exact ID without refreshing and shows all fields', (
    tester,
  ) async {
    repository.lookupResult = earthquakeFixture();

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(repository.lookupIds, ['usgs:example']);
    expect(repository.refreshCalls, 0);
    expect(find.text('Earthquake information'), findsWidgets);
    expect(find.text('Magnitude 5.2'), findsOneWidget);
    expect(find.text('Location: Myanmar'), findsOneWidget);
    expect(find.text('Depth: 12.5 km'), findsOneWidget);
    expect(find.text('Event time: Jul 13, 2026 01:02:03 UTC'), findsOneWidget);
    expect(
      find.text('Provider update: Jul 13, 2026 01:03:04 UTC'),
      findsOneWidget,
    );
    expect(find.text('Retrieved: Jul 13, 2026 01:04:05 UTC'), findsOneWidget);
    expect(find.text('Review status: reviewed'), findsOneWidget);
    expect(find.text('Source: USGS'), findsOneWidget);
    expect(
      find.text('Preliminary earthquake values may change.'),
      findsOneWidget,
    );
    expect(find.text('Open USGS source'), findsOneWidget);
  });

  testWidgets('loading and not-found states use localized safe copy', (
    tester,
  ) async {
    repository.lookupCompleter = Completer<Earthquake?>();
    await pumpDetail(tester, id: 'usgs:missing');
    await tester.pump();

    expect(find.text('Updating earthquake information'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(CircularProgressIndicator)),
      matchesSemantics(label: 'Updating earthquake information'),
    );

    repository.lookupCompleter!.complete(null);
    await tester.pumpAndSettle();

    expect(repository.lookupIds, ['usgs:missing']);
    expect(find.text('Earthquake information was not found.'), findsOneWidget);
  });

  testWidgets('valid source action invokes injected launcher with exact URI', (
    tester,
  ) async {
    repository.lookupResult = earthquakeFixture();
    await pumpDetail(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open USGS source'));
    await tester.pumpAndSettle();

    expect(launchedUris, [Uri.parse('https://earthquake.usgs.gov/example')]);
  });

  testWidgets('trusted USGS subdomain invokes the injected launcher', (
    tester,
  ) async {
    repository.lookupResult = earthquakeFixture(
      sourceUrl: 'https://events.earthquake.usgs.gov/example',
    );
    await pumpDetail(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open USGS source'));
    await tester.pumpAndSettle();

    expect(launchedUris, [
      Uri.parse('https://events.earthquake.usgs.gov/example'),
    ]);
  });

  for (final failure in <String, Future<bool> Function(Uri)>{
    'false result': (_) async => false,
    'exception': (_) => Future<bool>.error(StateError('platform secret')),
  }.entries) {
    testWidgets('${failure.key} shows non-sensitive launch feedback', (
      tester,
    ) async {
      repository.lookupResult = earthquakeFixture();
      launcher = failure.value;
      await pumpDetail(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open USGS source'));
      await tester.pumpAndSettle();

      expect(find.text('Could not open USGS source.'), findsOneWidget);
      expect(find.textContaining('platform secret'), findsNothing);
    });
  }

  testWidgets('rejects unsafe source hosts without invoking launcher', (
    tester,
  ) async {
    for (final sourceUrl in <String>[
      'https://example.com/event',
      'https://earthquake.usgs.gov.example.com/event',
      'https://evilearthquake.usgs.gov/event',
    ]) {
      repository.lookupResult = earthquakeFixture(sourceUrl: sourceUrl);
      await pumpDetail(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open USGS source'));
      await tester.pumpAndSettle();

      expect(launchedUris, isEmpty);
      expect(find.text('Could not open USGS source.'), findsOneWidget);
    }
  });

  testWidgets('omits absent review status and prohibited classifications', (
    tester,
  ) async {
    repository.lookupResult = earthquakeFixture(reviewStatus: null);
    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('Review status:'), findsNothing);
    final visibleText = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data ?? '')
        .join(' ');
    expect(_prohibitedCopy.hasMatch(visibleText), isFalse);
  });

  testWidgets('Burmese detail keeps provider place names as original text', (
    tester,
  ) async {
    repository.lookupResult = earthquakeFixture();
    await pumpDetail(tester, locale: const Locale('my'));
    await tester.pumpAndSettle();

    expect(find.text('ငလျင်အချက်အလက်'), findsWidgets);
    expect(find.textContaining('Myanmar'), findsOneWidget);
    expect(
      find.textContaining(
        'ရင်းမြစ်က ပေးထားသော အမည်များနှင့် တိုက်ရိုက်သတိပေးစာသား',
      ),
      findsOneWidget,
    );
  });
}

final _prohibitedCopy = RegExp(
  r'\b(?:demo|simulation|warning|prediction|severity)\b|'
  r'\bguarante(?:e|es|ed)\s+(?:safe|safety)\b',
  caseSensitive: false,
);
