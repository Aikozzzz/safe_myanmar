import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/ai/native_ai_platform_service.dart';
import 'package:mobile/features/guide/application/providers.dart';
import 'package:mobile/features/guide/presentation/assistant_screen.dart';
import 'package:mobile/features/settings/application/providers.dart';
import 'package:mobile/features/settings/domain/app_language.dart';
import 'package:mobile/l10n/app_localizations.dart';

import '../../../support/fake_emergency_guide_repository.dart';
import '../../../support/fake_language_preference_repository.dart';
import '../../../support/fake_native_ai_service.dart';

void main() {
  testWidgets('assistant screen omits implementation status details', (
    tester,
  ) async {
    await tester.pumpWidget(_app(FakeNativeAiService()));
    await tester.pumpAndSettle();

    expect(find.text('Suggested questions'), findsOneWidget);
    expect(find.textContaining('Deterministic offline'), findsNothing);
    expect(find.textContaining('Optional ONNX'), findsNothing);
    expect(find.textContaining('Optional local Gemma'), findsNothing);
  });

  testWidgets('additional wording stays separate from exact guidance', (
    tester,
  ) async {
    final nativeAi = FakeNativeAiService(
      capabilitiesResult: availableNativeAiCapabilities,
      rewriteResult: const NativeAiResult.success(
        NativeVerifiedRewrite('Simpler wording.'),
      ),
    );
    await tester.pumpWidget(_app(nativeAi));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'What should I do during an earthquake?',
    );
    await tester.tap(find.byTooltip('Send question'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Additional guidance'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('APPROVED EARTHQUAKE ANSWER'), findsOneWidget);
    expect(find.text('Additional guidance'), findsOneWidget);
    expect(find.text('Simpler wording.'), findsOneWidget);
    expect(
      find.textContaining('Compare this wording with the approved guidance'),
      findsOneWidget,
    );
    expect(find.textContaining('model'), findsNothing);
    expect(find.textContaining('confidence'), findsNothing);
    expect(find.text('Source: Ready.gov'), findsOneWidget);
    expect(find.text('Content version: 1'), findsOneWidget);
    expect(
      find.textContaining('Burmese translations require review'),
      findsNothing,
    );
    expect(
      tester.getSemantics(find.text('Additional guidance')),
      matchesSemantics(
        label:
            'Additional guidance. Simpler wording. Compare this wording with the approved guidance above.',
      ),
    );
    expect(find.textContaining('model-generated'), findsNothing);
    expect(find.textContaining('confidence'), findsNothing);
  });

  testWidgets('ONNX action response never navigates without a user tap', (
    tester,
  ) async {
    final nativeAi = FakeNativeAiService(
      capabilitiesResult: availableNativeAiCapabilities,
      classificationResult: const NativeAiResult.success(
        NativeIntentClassification(intent: 'safe_route', confidence: 0.95),
      ),
    );
    final router = GoRouter(
      initialLocation: '/assistant',
      routes: [
        GoRoute(path: '/assistant', builder: (_, _) => const AssistantScreen()),
        GoRoute(
          path: '/map',
          builder: (_, _) => const Scaffold(
            body: Text('MAP DESTINATION', key: Key('map-destination')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(_routerApp(nativeAi, router));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Where should I go now?');
    await tester.tap(find.byTooltip('Send question'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Open Map'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Open Map'), findsOneWidget);
    expect(find.byKey(const Key('map-destination')), findsNothing);
  });

  testWidgets('assistant chrome and answers stay Burmese at 200 percent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        FakeNativeAiService(),
        locale: const Locale('my'),
        language: AppLanguage.burmese,
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pump();

    expect(find.text('အော့ဖ်လိုင်းအကူ'), findsOneWidget);
    expect(find.text('အရေးပေါ်မေးခွန်း'), findsOneWidget);
    expect(
      tester.getSize(find.byTooltip('မေးခွန်းပေးပို့ရန်')).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.text('ငလျင်လှုပ်နေစဉ် ဘာလုပ်ရမလဲ။'));
    await tester.pumpAndSettle();

    expect(find.text('အတည်ပြုထားသော အဖြေ'), findsOneWidget);
    expect(find.text('APPROVED EARTHQUAKE ANSWER'), findsNothing);
  });
}

Widget _app(
  FakeNativeAiService nativeAi, {
  Locale locale = const Locale('en'),
  AppLanguage language = AppLanguage.english,
}) => ProviderScope(
  overrides: [
    emergencyGuideRepositoryProvider.overrideWithValue(
      FakeEmergencyGuideRepository(),
    ),
    nativeAiServiceProvider.overrideWithValue(nativeAi),
    languagePreferenceRepositoryProvider.overrideWithValue(
      FakeLanguagePreferenceRepository()..language = language,
    ),
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
    home: const AssistantScreen(),
  ),
);

Widget _routerApp(FakeNativeAiService nativeAi, GoRouter router) =>
    ProviderScope(
      overrides: [
        emergencyGuideRepositoryProvider.overrideWithValue(
          FakeEmergencyGuideRepository(),
        ),
        nativeAiServiceProvider.overrideWithValue(nativeAi),
        languagePreferenceRepositoryProvider.overrideWithValue(
          FakeLanguagePreferenceRepository(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
