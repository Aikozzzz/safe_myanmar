import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/safe_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';

void main() {
  group('SafeTheme', () {
    test('uses Material 3 with exact light color roles', () {
      final theme = SafeTheme.light();

      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.surface, const Color(0xFFFDFCFC));
      expect(theme.colorScheme.onSurface, const Color(0xFF201D1D));
      expect(theme.colorScheme.primary, const Color(0xFF0056B3));
      expect(theme.colorScheme.onPrimary, const Color(0xFFFDFCFC));
      expect(theme.colorScheme.error, const Color(0xFFB42318));
      expect(theme.colorScheme.onError, const Color(0xFFFDFCFC));
    });

    test('uses Material 3 with dedicated dark color roles', () {
      final theme = SafeTheme.dark();

      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.surface, const Color(0xFF201D1D));
      expect(theme.colorScheme.onSurface, const Color(0xFFFDFCFC));
      expect(theme.colorScheme.primary, const Color(0xFF9CCAFF));
      expect(theme.colorScheme.onPrimary, const Color(0xFF002B5C));
      expect(theme.colorScheme.error, const Color(0xFFFFB4AB));
      expect(theme.colorScheme.onError, const Color(0xFF690005));
    });

    for (final themeFactory in <String, ThemeData Function()>{
      'light': SafeTheme.light,
      'dark': SafeTheme.dark,
    }.entries) {
      test('${themeFactory.key} uses accessible control sizing', () {
        final theme = themeFactory.value();

        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
        for (final style in <ButtonStyle?>[
          theme.elevatedButtonTheme.style,
          theme.filledButtonTheme.style,
          theme.outlinedButtonTheme.style,
          theme.textButtonTheme.style,
        ]) {
          final size = minimumSize(style);
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
      });

      test('${themeFactory.key} uses system-default font fallback', () {
        final theme = themeFactory.value();

        expect(theme.textTheme.bodyLarge?.fontFamily, isNull);
        expect(theme.textTheme.bodyMedium?.fontFamily, isNull);
        expect(theme.textTheme.bodySmall?.fontFamily, isNull);
        expect(theme.textTheme.titleLarge?.fontFamily, isNull);
        expect(theme.textTheme.labelLarge?.fontFamily, isNull);
      });

      testWidgets(
        '${themeFactory.key} localized controls support 200% text scale',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            MaterialApp(
              theme: themeFactory.value(),
              locale: const Locale('en'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: const _LocalizedButtonExamples(),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          for (final type in <Type>[
            ElevatedButton,
            FilledButton,
            OutlinedButton,
            TextButton,
          ]) {
            final size = tester.getSize(find.byType(type));
            expect(size.width, greaterThanOrEqualTo(48));
            expect(size.height, greaterThanOrEqualTo(48));
          }
        },
      );

      test('${themeFactory.key} named color pairs meet AA contrast', () {
        final colors = themeFactory.value().colorScheme;

        expect(
          contrastRatio(colors.onSurface, colors.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(colors.onPrimary, colors.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(colors.onError, colors.error),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });
}

Size minimumSize(ButtonStyle? style) {
  return style?.minimumSize?.resolve(<WidgetState>{}) ?? Size.zero;
}

double contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = identical(lighter, foreground) ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

class _LocalizedButtonExamples extends StatelessWidget {
  const _LocalizedButtonExamples();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.info_outline),
                label: Text(strings.earthquakeInformation),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh),
                label: Text(strings.loadingEarthquakes),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.warning_amber),
                label: Text(strings.preliminaryNotice),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.public),
                label: Text(strings.dataSourceUsGS),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
