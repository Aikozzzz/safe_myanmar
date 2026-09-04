import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/guide/presentation/local_emergency_contacts_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';

void main() {
  testWidgets('shows Yangon emergency numbers and source metadata', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Yangon emergency contacts'), findsOneWidget);
    expect(find.text('192'), findsOneWidget);
    expect(find.text('191'), findsOneWidget);
    expect(find.text('199'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('01 256112'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('01 256112'), findsOneWidget);
    expect(find.text('01 265131'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Source: Yangon Directory'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Source: Yangon Directory'), findsOneWidget);
    expect(
      find.text('https://www.yangondirectory.com/emergency.html'),
      findsOneWidget,
    );
  });

  testWidgets('call buttons require an explicit tap', (tester) async {
    final calls = <Uri>[];
    await tester.pumpWidget(
      _app(
        launchPhone: (uri) async {
          calls.add(uri);
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(calls, isEmpty);
    await tester.tap(
      find.byKey(const ValueKey('yangon-emergency-call-ambulance-192')),
    );
    await tester.pumpAndSettle();

    expect(calls, [Uri(scheme: 'tel', path: '192')]);
  });

  testWidgets('contact buttons remain accessible at 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(textScale: 2));
    await tester.pumpAndSettle();

    for (final key in [
      'yangon-emergency-call-ambulance-192',
      'yangon-emergency-call-fire-191',
      'yangon-emergency-call-police-199',
      'yangon-emergency-call-yangonGeneralHospital-01256112',
      'yangon-emergency-call-yangonGeneralHospital-01265131',
    ]) {
      final button = find.byKey(ValueKey(key));
      await tester.scrollUntilVisible(
        button,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });
}

Widget _app({double textScale = 1, EmergencyPhoneLauncher? launchPhone}) =>
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: YangonEmergencyContactsScreen(
          launchPhone: launchPhone ?? (_) async => true,
        ),
      ),
    );
