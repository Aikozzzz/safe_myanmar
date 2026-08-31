import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/theme/safe_theme.dart';
import 'package:mobile/features/guide/application/providers.dart';
import 'package:mobile/features/guide/presentation/guide_screens.dart';
import 'package:mobile/l10n/app_localizations.dart';

import '../../../support/fake_emergency_guide_repository.dart';

void main() {
  testWidgets('Guide exposes curated quick choices and next steps', (
    tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(_location(router), '/guide');
    expect(
      find.byKey(const Key('guide-quick-action-earthquake')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('guide-quick-action-flood')), findsOneWidget);
    expect(find.byKey(const Key('guide-quick-action-fire')), findsOneWidget);
    expect(
      find.byKey(const Key('guide-quick-action-first-aid')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('guide-quick-action-map')), findsOneWidget);
    expect(find.byKey(const Key('guide-quick-action-sos')), findsOneWidget);
    expect(find.byKey(const Key('guide-next-step-map')), findsOneWidget);
    expect(find.byKey(const Key('guide-next-step-sos')), findsOneWidget);
    expect(find.byKey(const Key('guide-next-step-assistant')), findsOneWidget);
  });

  testWidgets('article quick choices open only after a user tap', (
    tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    const articleActions = <String, String>{
      'guide-quick-action-earthquake': 'earthquake-drop-cover-hold',
      'guide-quick-action-flood': 'flood-avoidance',
      'guide-quick-action-fire': 'fire-escape',
      'guide-quick-action-first-aid': 'first-aid-assessment',
    };

    for (final entry in articleActions.entries) {
      router.go('/guide');
      await tester.pumpAndSettle();

      expect(_location(router), '/guide');
      final action = find.byKey(Key(entry.key));
      await _revealInGuide(tester, action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(find.text('ARTICLE ${entry.value}'), findsOneWidget);
    }
  });

  testWidgets('Map, SOS, and assistant next steps require a tap', (
    tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    const nextSteps = <String, String>{
      'guide-quick-action-map': '/map',
      'guide-quick-action-sos': '/sos',
      'guide-next-step-map': '/map',
      'guide-next-step-sos': '/sos',
      'guide-next-step-assistant': '/guide/assistant',
    };

    for (final entry in nextSteps.entries) {
      router.go('/guide');
      await tester.pumpAndSettle();

      expect(_location(router), '/guide');
      final action = find.byKey(Key(entry.key));
      await _revealInGuide(tester, action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      if (entry.value == '/guide/assistant') {
        expect(find.text('ASSISTANT'), findsOneWidget);
      } else {
        expect(_location(router), entry.value);
      }
    }
  });

  testWidgets(
    'quick actions retain accessible targets at 200 percent text scale',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = _createRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(_app(router, textScale: 2));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final key in [
        'guide-quick-action-earthquake',
        'guide-quick-action-flood',
        'guide-quick-action-fire',
        'guide-quick-action-first-aid',
        'guide-quick-action-map',
        'guide-quick-action-sos',
        'guide-next-step-map',
        'guide-next-step-sos',
        'guide-next-step-assistant',
      ]) {
        final action = find.byKey(Key(key));
        await _revealInGuide(tester, action);
        expect(tester.getSize(action.first).height, greaterThanOrEqualTo(48));
      }
    },
  );
}

Widget _app(GoRouter router, {double textScale = 1}) => ProviderScope(
  overrides: [
    emergencyGuideRepositoryProvider.overrideWithValue(
      FakeEmergencyGuideRepository(),
    ),
  ],
  child: MaterialApp.router(
    routerConfig: router,
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
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
  ),
);

GoRouter _createRouter() => GoRouter(
  initialLocation: '/guide',
  routes: [
    GoRoute(
      path: '/guide',
      builder: (_, _) => const GuideScreen(),
      routes: [
        GoRoute(
          path: 'article/:articleId',
          builder: (_, state) => Scaffold(
            body: Center(
              child: Text('ARTICLE ${state.pathParameters['articleId']}'),
            ),
          ),
        ),
        GoRoute(
          path: 'assistant',
          builder: (_, _) => const Scaffold(body: Text('ASSISTANT')),
        ),
      ],
    ),
    GoRoute(
      path: '/map',
      builder: (_, _) => const Scaffold(body: Text('MAP')),
    ),
    GoRoute(
      path: '/sos',
      builder: (_, _) => const Scaffold(body: Text('SOS')),
    ),
  ],
);

String _location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

Future<void> _revealInGuide(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable).first;
    final state = tester.state<ScrollableState>(scrollable);
    state.position.jumpTo(0);
    await tester.pump();

    for (
      var attempt = 0;
      attempt < 20 && target.evaluate().isEmpty;
      attempt++
    ) {
      final position = state.position;
      if (position.pixels >= position.maxScrollExtent) {
        break;
      }
      position.jumpTo(
        (position.pixels + 240).clamp(0, position.maxScrollExtent).toDouble(),
      );
      await tester.pump();
    }
  }

  expect(target, findsWidgets);
  await tester.ensureVisible(target.first);
  await tester.pumpAndSettle();
}
