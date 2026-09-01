import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/safe_theme.dart';
import 'package:mobile/features/navigation/presentation/app_shell.dart';
import 'package:mobile/l10n/app_localizations.dart';

void main() {
  testWidgets('Home cards expose accessible buttons at narrow widths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester);

    for (final key in _homeCardKeys) {
      final card = find.byKey(ValueKey(key));
      await tester.ensureVisible(card);

      expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(card),
        matchesSemantics(isButton: true, hasTapAction: true),
      );
      expect(tester.getSemantics(card).label, isNotEmpty);
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('Home cards use one column on a narrow screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester);

    final alerts = tester.getRect(find.byKey(ValueKey(_homeCardKeys[0])));
    final map = tester.getRect(find.byKey(ValueKey(_homeCardKeys[1])));

    expect(map.left, closeTo(alerts.left, 0.1));
    expect(map.top, greaterThan(alerts.bottom));
  });

  testWidgets('Home cards invoke only their explicit navigation callbacks', (
    tester,
  ) async {
    var alertsOpens = 0;
    var mapOpens = 0;
    var sosOpens = 0;
    var guideOpens = 0;

    await _pumpHome(
      tester,
      onOpenEarthquakeInformation: () => alertsOpens++,
      onOpenMap: () => mapOpens++,
      onOpenSos: () => sosOpens++,
      onOpenGuide: () => guideOpens++,
    );

    expect(alertsOpens, 0);
    expect(mapOpens, 0);
    expect(sosOpens, 0);
    expect(guideOpens, 0);

    for (final entry in <String, VoidCallback>{
      _homeCardKeys[0]: () => alertsOpens++,
      _homeCardKeys[1]: () => mapOpens++,
      _homeCardKeys[2]: () => sosOpens++,
      _homeCardKeys[3]: () => guideOpens++,
    }.entries) {
      final card = find.byKey(ValueKey(entry.key));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pump();
    }

    expect(alertsOpens, 1);
    expect(mapOpens, 1);
    expect(sosOpens, 1);
    expect(guideOpens, 1);
  });

  testWidgets('Home cards use two columns when space allows', (tester) async {
    await tester.binding.setSurfaceSize(const Size(720, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpHome(tester);

    final alerts = tester.getRect(find.byKey(ValueKey(_homeCardKeys[0])));
    final map = tester.getRect(find.byKey(ValueKey(_homeCardKeys[1])));

    expect(map.left, greaterThan(alerts.left));
    expect(map.top, closeTo(alerts.top, 0.1));
  });

  testWidgets('Home chrome uses reviewed Burmese labels', (tester) async {
    await _pumpHome(tester, locale: const Locale('my'));

    expect(find.text('ဘေးကင်းရေးစင်တာ'), findsOneWidget);
    expect(find.text('တိုက်ရိုက်ငလျင်အချက်အလက်'), findsOneWidget);
    expect(find.text('မြေပုံဖွင့်ရန်'), findsOneWidget);
    expect(find.text('SOS ပြင်ဆင်မှုဖွင့်ရန်'), findsOneWidget);
    expect(find.text('လမ်းညွှန်ဖွင့်ရန်'), findsOneWidget);
  });
}

const _homeCardKeys = <String>[
  'home-alerts-card',
  'home-map-card',
  'home-sos-card',
  'home-guide-card',
];

Future<void> _pumpHome(
  WidgetTester tester, {
  VoidCallback? onOpenEarthquakeInformation,
  VoidCallback? onOpenMap,
  VoidCallback? onOpenSos,
  VoidCallback? onOpenGuide,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
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
        onOpenMap: onOpenMap ?? () {},
        onOpenSos: onOpenSos ?? () {},
        onOpenGuide: onOpenGuide ?? () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}
