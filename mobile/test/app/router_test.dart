import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/router.dart';
import 'package:mobile/features/alerts/application/providers.dart';
import 'package:mobile/features/guide/application/providers.dart';
import 'package:mobile/features/navigation/presentation/app_shell.dart';
import 'package:mobile/features/profile/application/providers.dart';
import 'package:mobile/features/sos/application/providers.dart';
import 'package:mobile/features/sos/data/native_sms_composer.dart';

import '../support/fake_alert_repository.dart';
import '../support/fake_emergency_guide_repository.dart';
import '../support/fake_local_profile_repository.dart';
import '../support/fake_sos_draft_repository.dart';

void main() {
  testWidgets('default route shows the five-tab Home shell', (tester) async {
    final router = createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: SafeMyanmarApp(router: router)),
    );
    await tester.pumpAndSettle();

    expect(routerLocation(router), '/home');
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    for (final label in ['Home', 'Map', 'SOS', 'Guide', 'More']) {
      expect(_navigationLabel(label), findsOneWidget);
    }
    expect(find.text('View earthquake information'), findsOneWidget);
  });

  testWidgets('tabs navigate and SOS selection performs no SOS action', (
    tester,
  ) async {
    final profileRepository = FakeLocalProfileRepository();
    final draftRepository = FakeSosDraftRepository();
    final composer = _CountingComposer();
    final router = createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emergencyGuideRepositoryProvider.overrideWithValue(
            FakeEmergencyGuideRepository(),
          ),
          localProfileRepositoryProvider.overrideWithValue(profileRepository),
          sosDraftRepositoryProvider.overrideWithValue(draftRepository),
          nativeSmsComposerProvider.overrideWithValue(composer),
        ],
        child: SafeMyanmarApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_navigationLabel('Map'));
    await tester.pumpAndSettle();
    expect(routerLocation(router), '/map');
    expect(find.text('Location access is off'), findsOneWidget);
    final locationAction = find.widgetWithText(FilledButton, 'Use my location');
    await tester.scrollUntilVisible(locationAction, 200);
    expect(locationAction, findsOneWidget);

    await tester.tap(_navigationLabel('SOS'));
    await tester.pumpAndSettle();
    expect(routerLocation(router), '/sos');
    expect(find.byType(SosScreen), findsOneWidget);
    expect(find.text('No contacts selected'), findsOneWidget);
    expect(draftRepository.writes, 0);
    expect(composer.calls, 0);

    await tester.tap(_navigationLabel('Guide'));
    await tester.pumpAndSettle();
    expect(routerLocation(router), '/guide');
    expect(find.text('Offline verified-content retrieval'), findsOneWidget);

    await tester.tap(_navigationLabel('More'));
    await tester.pumpAndSettle();
    expect(routerLocation(router), '/more');
    expect(find.text('Display name not set'), findsNWidgets(2));
    expect(find.text('Manage contacts'), findsOneWidget);
  });

  testWidgets('Home opens the retained alerts route', (tester) async {
    final repository = FakeAlertRepository()..queueRefresh();
    addTearDown(repository.close);
    final router = createRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [alertRepositoryProvider.overrideWithValue(repository)],
        child: SafeMyanmarApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-alerts-card')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Updating earthquake information'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('alert detail deep links preserve encoded identifiers', (
    tester,
  ) async {
    final repository = FakeAlertRepository();
    final router = createRouter(
      initialLocation: '/alerts/usgs%3Aid%2Fwith%20space',
    );
    addTearDown(repository.close);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [alertRepositoryProvider.overrideWithValue(repository)],
        child: SafeMyanmarApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.lookupIds, ['usgs:id/with space']);
    expect(find.text('Earthquake information was not found.'), findsOneWidget);
  });

  testWidgets('More child deep links remain inside the shell branch', (
    tester,
  ) async {
    final profileRepository = FakeLocalProfileRepository();
    final router = createRouter(initialLocation: '/more/contacts');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localProfileRepositoryProvider.overrideWithValue(profileRepository),
        ],
        child: SafeMyanmarApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(routerLocation(router), '/more/contacts');
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('Emergency contacts'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('More Settings deep links remain inside the shell branch', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/more/settings');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: SafeMyanmarApp(router: router)),
    );
    await tester.pumpAndSettle();

    expect(routerLocation(router), '/more/settings');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('switching tabs preserves the More branch child route', (
    tester,
  ) async {
    final profileRepository = FakeLocalProfileRepository();
    final router = createRouter(initialLocation: '/more/profile');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localProfileRepositoryProvider.overrideWithValue(profileRepository),
        ],
        child: SafeMyanmarApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(routerLocation(router), '/more/profile');

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(routerLocation(router), '/home');

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(routerLocation(router), '/more/profile');
    expect(find.text('Display name'), findsOneWidget);
  });

  testWidgets('Guide article and assistant routes remain inside shell state', (
    tester,
  ) async {
    final repository = FakeEmergencyGuideRepository();
    final router = createRouter(
      initialLocation: '/guide/article/earthquake-drop-cover-hold',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emergencyGuideRepositoryProvider.overrideWithValue(repository),
        ],
        child: SafeMyanmarApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(routerLocation(router), '/guide/article/earthquake-drop-cover-hold');
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('APPROVED EARTHQUAKE ANSWER'), findsOneWidget);

    router.go('/guide/assistant');
    await tester.pumpAndSettle();
    expect(routerLocation(router), '/guide/assistant');
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Suggested questions'), findsOneWidget);
  });

  testWidgets('assistant action routes require a tap and never activate SOS', (
    tester,
  ) async {
    final profileRepository = FakeLocalProfileRepository();
    final draftRepository = FakeSosDraftRepository();
    final composer = _CountingComposer();
    final router = createRouter(initialLocation: '/guide/assistant');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emergencyGuideRepositoryProvider.overrideWithValue(
            FakeEmergencyGuideRepository(),
          ),
          localProfileRepositoryProvider.overrideWithValue(profileRepository),
          sosDraftRepositoryProvider.overrideWithValue(draftRepository),
          nativeSmsComposerProvider.overrideWithValue(composer),
        ],
        child: SafeMyanmarApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'send SOS emergency message',
    );
    await tester.tap(find.byTooltip('Send question'));
    await tester.pumpAndSettle();

    expect(routerLocation(router), '/guide/assistant');
    expect(draftRepository.writes, 0);
    expect(composer.calls, 0);
    final sosAction = find.text('Open SOS for user review');
    await tester.ensureVisible(sosAction);
    await tester.pumpAndSettle();
    await tester.tap(sosAction);
    await tester.pumpAndSettle();

    expect(routerLocation(router), '/sos');
    expect(draftRepository.writes, 0);
    expect(composer.calls, 0);
  });

  testWidgets('assistant delegates route and shelter requests to Map', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/guide/assistant');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emergencyGuideRepositoryProvider.overrideWithValue(
            FakeEmergencyGuideRepository(),
          ),
        ],
        child: SafeMyanmarApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'show a safe route');
    await tester.tap(find.byTooltip('Send question'));
    await tester.pumpAndSettle();
    final mapAction = find.text('Open Map');
    await tester.ensureVisible(mapAction);
    await tester.pumpAndSettle();
    await tester.tap(mapAction);
    await tester.pumpAndSettle();

    expect(routerLocation(router), '/map');
  });
}

Finder _navigationLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

String routerLocation(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

final class _CountingComposer implements NativeSmsComposer {
  int calls = 0;

  @override
  Future<bool> open({
    required List<String> recipients,
    required String body,
  }) async {
    calls++;
    return true;
  }
}
