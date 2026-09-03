import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/safe_theme.dart';
import 'package:mobile/features/guide/application/providers.dart';
import 'package:mobile/features/guide/presentation/assistant_screen.dart';
import 'package:mobile/features/guide/presentation/guide_screens.dart';
import 'package:mobile/l10n/app_localizations.dart';

import '../../../support/fake_emergency_guide_repository.dart';
import '../../../support/fake_native_ai_service.dart';

void main() {
  testWidgets('Guide fits 390x844 at 200 percent with accessible targets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emergencyGuideRepositoryProvider.overrideWithValue(
            FakeEmergencyGuideRepository(),
          ),
          nativeAiServiceProvider.overrideWithValue(FakeNativeAiService()),
        ],
        child: MaterialApp(
          theme: SafeTheme.light(),
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
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const GuideScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Offline verified-content retrieval'), findsOneWidget);
    expect(
      find.textContaining('Burmese translations require review'),
      findsNothing,
    );
    expect(
      tester.getSemantics(find.text('Offline verified-content retrieval')),
      matchesSemantics(label: 'Offline verified-content retrieval'),
    );
    final search = find.byTooltip('Search');
    await _revealInGuide(tester, search);
    expect(search, findsOneWidget);
    expect(tester.getSize(search).height, greaterThanOrEqualTo(48));
  });

  testWidgets('assistant input fits 390x844 at 200 percent', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emergencyGuideRepositoryProvider.overrideWithValue(
            FakeEmergencyGuideRepository(),
          ),
          nativeAiServiceProvider.overrideWithValue(FakeNativeAiService()),
        ],
        child: MaterialApp(
          theme: SafeTheme.light(),
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
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const AssistantScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Emergency question'), findsOneWidget);
    final send = find.byTooltip('Send question');
    expect(tester.getSize(send).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(send).height, greaterThanOrEqualTo(48));
  });

  testWidgets('Burmese article sources show the translation boundary', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('my'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ArticleSourceCard(article: guideArticleFixtures().first),
          ),
        ),
      ),
    );

    expect(find.textContaining('မြန်မာဘာသာပြန်'), findsOneWidget);
  });

  testWidgets('Guide chrome uses reviewed Burmese labels', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emergencyGuideRepositoryProvider.overrideWithValue(
            FakeEmergencyGuideRepository(),
          ),
          nativeAiServiceProvider.overrideWithValue(FakeNativeAiService()),
        ],
        child: const MaterialApp(
          locale: Locale('my'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: GuideScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('လမ်းညွှန်'), findsWidgets);
    expect(
      find.text('အော့ဖ်လိုင်းစစ်ဆေးပြီး အကြောင်းအရာရယူမှု'),
      findsOneWidget,
    );
    expect(find.text('ဝပ်၊ ကာကွယ်၊ ကိုင်ထားပါ'), findsOneWidget);
  });
}

Future<void> _revealInGuide(WidgetTester tester, Finder target) async {
  final scrollable = find.byType(Scrollable).first;
  final state = tester.state<ScrollableState>(scrollable);

  for (var attempt = 0; attempt < 20 && target.evaluate().isEmpty; attempt++) {
    final position = state.position;
    if (position.pixels >= position.maxScrollExtent) {
      break;
    }
    position.jumpTo(
      (position.pixels + 240).clamp(0, position.maxScrollExtent).toDouble(),
    );
    await tester.pump();
  }

  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}
