import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' show MapWidget;
import 'package:mobile/app/theme/safe_theme.dart';
import 'package:mobile/core/network/mapbox_public_access_token.dart';
import 'package:mobile/features/location/application/providers.dart';
import 'package:mobile/features/location/domain/foreground_location.dart';
import 'package:mobile/features/location/presentation/location_screen.dart';
import 'package:mobile/features/navigation/application/providers.dart';
import 'package:mobile/features/navigation/data/navigation_dto.dart';
import 'package:mobile/features/navigation/domain/navigation_models.dart';
import 'package:mobile/features/navigation/domain/navigation_repository.dart';
import 'package:mobile/l10n/app_localizations.dart';

import '../../../support/fake_location_permission_prompt_store.dart';
import '../../../support/fake_location_repository.dart';
import '../../../support/fake_navigation_repository.dart';
import '../../../support/navigation_fixtures.dart';

void main() {
  late FakeLocationRepository locationRepository;
  late FakeNavigationRepository navigationRepository;
  late FakeLocationPermissionPromptStore promptStore;

  setUp(() {
    locationRepository = FakeLocationRepository()..currentLocation = location;
    navigationRepository = FakeNavigationRepository();
    promptStore = FakeLocationPermissionPromptStore();
    navigationRepository.contextAreas = NavigationResource(
      data: ContextAreaCollectionDto.fromJson(
        contextAreaResponseJson(),
      ).toDomain(),
      isCached: false,
      remoteFailed: false,
    );
  });

  Future<void> pumpScreen(WidgetTester tester, {double textScale = 1}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationRepositoryProvider.overrideWithValue(locationRepository),
          locationPermissionPromptStoreProvider.overrideWithValue(promptStore),
          navigationRepositoryProvider.overrideWithValue(navigationRepository),
          mapboxPublicAccessTokenProvider.overrideWithValue(
            MapboxPublicAccessToken.fromRaw(''),
          ),
        ],
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: MaterialApp(
            theme: SafeTheme.light(),
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LocationScreen(),
          ),
        ),
      ),
    );
  }

  Future<void> enableLocation(WidgetTester tester) async {
    final action = find.widgetWithText(FilledButton, 'Use my location');
    await tester.scrollUntilVisible(action, 200);
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  Future<void> requestRoutes(WidgetTester tester) async {
    final action = find.widgetWithText(
      FilledButton,
      'Request route suggestions',
    );
    await tester.scrollUntilVisible(action, 200);
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  Future<void> analyzeContext(WidgetTester tester) async {
    final action = find.widgetWithText(OutlinedButton, 'Analyze nearby areas');
    await tester.scrollUntilVisible(action, 200);
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
  }

  testWidgets('analysis reveals controls and route action', (tester) async {
    await pumpScreen(tester);
    await enableLocation(tester);

    expect(find.byType(MapWidget), findsNothing);
    expect(find.text('Map configuration unavailable'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-layer-legend')), findsNothing);
    expect(find.text('Hazard summary'), findsOneWidget);
    expect(find.text('SIMULATION: Test Hazard'), findsOneWidget);
    expect(find.text('SIMULATION'), findsWidgets);
    expect(find.text('Disaster type'), findsNothing);
    expect(find.text('Earthquake context'), findsNothing);
    expect(find.text('Travel profile'), findsNothing);
    expect(find.text('Request route suggestions'), findsNothing);

    await analyzeContext(tester);

    expect(find.text('Nearby lower-exposure areas'), findsOneWidget);
    expect(find.text('Context summary'), findsOneWidget);
    expect(
      find.text(
        'No mapped hazards found. This does not confirm the area is safe.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Building clearance: 120 m; tree clearance: 90 m'),
      findsWidgets,
    );
    expect(find.text('Disaster type'), findsOneWidget);
    expect(find.text('Earthquake context'), findsOneWidget);
    expect(find.text('Travel profile'), findsOneWidget);
    expect(find.text('Request route suggestions'), findsOneWidget);
  });

  testWidgets('context summary exposes cached status and cache time', (
    tester,
  ) async {
    final cached = NavigationResource<ContextAreaCollection>(
      data: navigationRepository.contextAreas.data,
      isCached: true,
      remoteFailed: true,
      cachedAt: DateTime.utc(2026, 7, 23, 12, 30),
    );
    navigationRepository.cachedContextAreas = cached;
    navigationRepository.contextAreas = cached;

    await pumpScreen(tester);
    await enableLocation(tester);
    await analyzeContext(tester);

    expect(
      find.text(
        'Previously loaded information remains visible and may be stale.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Saved for offline use: Jul 23, 2026 12:30:00 UTC'),
      findsOneWidget,
    );
  });

  testWidgets('cached shelter details load before permission or GPS', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('Location access is off'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Nearby lower-exposure areas'),
      200,
    );
    expect(find.text('Nearby lower-exposure areas'), findsOneWidget);
    expect(
      find.text('No lower-exposure area was identified for this scenario.'),
      findsNothing,
    );
    expect(locationRepository.permissionChecks, 0);
    expect(locationRepository.currentLocationRequests, 0);
    expect(find.byType(MapWidget), findsNothing);
  });

  testWidgets('cached shelters stay visible during background refresh', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.scrollUntilVisible(
      find.text('Nearby lower-exposure areas'),
      200,
    );
    expect(find.text('Nearby lower-exposure areas'), findsOneWidget);
    expect(
      find.text('Building clearance: 120 m; tree clearance: 90 m'),
      findsNothing,
    );
    expect(locationRepository.permissionChecks, 0);
    await enableLocation(tester);
    await analyzeContext(tester);
    expect(
      find.text('Building clearance: 120 m; tree clearance: 90 m'),
      findsWidgets,
    );
  });

  testWidgets('cards identify status without color and selection changes', (
    tester,
  ) async {
    navigationRepository.routes = NavigationResource(
      data: routeSuggestions(optionCount: 3),
      isCached: false,
      remoteFailed: false,
    );
    await pumpScreen(tester);
    await enableLocation(tester);
    await analyzeContext(tester);
    await requestRoutes(tester);

    expect(find.text('Suggested'), findsOneWidget);
    expect(find.text('Alternative 1'), findsOneWidget);
    expect(find.text('Alternative 2'), findsOneWidget);
    expect(find.text('Selected route'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));

    final alternative = find.byKey(
      const ValueKey('route-card-simulation-route-3'),
    );
    await tester.scrollUntilVisible(alternative, 200);
    await tester.ensureVisible(alternative);
    await tester.pumpAndSettle();
    await tester.tap(alternative);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    expect(
      tester
          .getSemantics(alternative)
          .flagsCollection
          .isSelected
          .toBoolOrNull(),
      isTrue,
    );
  });

  testWidgets('routing failure keeps shelter data and explains retry', (
    tester,
  ) async {
    navigationRepository.routes = const NavigationResource(
      data: null,
      isCached: false,
      remoteFailed: true,
    );
    await pumpScreen(tester);
    await enableLocation(tester);
    await analyzeContext(tester);
    await requestRoutes(tester);

    expect(find.text('Nearby lower-exposure areas'), findsOneWidget);
    expect(
      find.textContaining('Shelters and hazards remain visible; try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry route suggestions'), findsOneWidget);
  });

  testWidgets('map controls and route cards fit 390x844 at 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(tester, textScale: 2);
    await enableLocation(tester);
    await analyzeContext(tester);
    await requestRoutes(tester);

    await tester.scrollUntilVisible(find.text('Suggested'), 200);
    expect(tester.takeException(), isNull);
    final routeButton = find.ancestor(
      of: find.text('Suggested'),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(routeButton).height, greaterThanOrEqualTo(48));
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('route-card-simulation-route-1')),
          )
          .flagsCollection
          .isSelected
          .toBoolOrNull(),
      isTrue,
    );
  });
}

final location = ForegroundLocation(
  latitude: 21.95,
  longitude: 96.08,
  timestamp: DateTime.utc(2026, 7, 23, 12),
  precision: LocationPrecision.precise,
);
