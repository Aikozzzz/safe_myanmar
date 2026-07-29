import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/alerts/presentation/presentation_formatters.dart';
import 'package:mobile/l10n/app_localizations.dart';

void main() {
  testWidgets('uses locale skeletons and the localized UTC wrapper', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'GB'),
        supportedLocales: const [Locale('en', 'GB')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            final strings = AppLocalizations.of(context)!;
            result = formatUtcTimestamp(
              context,
              strings,
              DateTime.utc(2026, 7, 13, 1, 2, 3),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(result, '13 Jul 2026 01:02:03 UTC');
    expect(
      AppLocalizations.of(
        tester.element(find.byType(SizedBox)),
      )!.utcTimestamp('localized value'),
      'localized value UTC',
    );
  });
}
