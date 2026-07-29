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
      tester.getSemantics(find.text('Offline verified-content retrieval')),
      matchesSemantics(label: 'Offline verified-content retrieval'),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final search = find.byTooltip('Search');
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
}
