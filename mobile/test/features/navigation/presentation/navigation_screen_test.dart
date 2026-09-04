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
  late ProviderContainer container;

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

  Future<void> pumpScreen(
    WidgetTester tester, {
    double textScale = 1,
    Locale locale = const Locale('en'),
  }) async {
    container = ProviderContainer(
      overrides: [
        locationRepositoryProvider.overrideWithValue(locationRepository),
        locationPermissionPromptStoreProvider.overrideWithValue(promptStore),
        navigationRepositoryProvider.overrideWithValue(navigationRepository),
        mapboxPublicAccessTokenProvider.overrideWithValue(
          MapboxPublicAccessToken.fromRaw(''),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: MaterialApp(
            theme: SafeTheme.light(),
            locale: locale,
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
    final areas = container.read(navigationControllerProvider).contextAreas;
    expect(areas, isNotNull);
    expect(areas!.items, isNotEmpty);
    final controller = container.read(navigationControllerProvider.notifier);
    controller.selectContextArea(areas.items.first.id);
    await tester.pumpAndSettle();
    final currentLocation = container
        .read(foregroundLocationControllerProvider)
        .location;
    expect(currentLocation, isNotNull);
    await controller.requestRoutes(currentLocation!);
    await tester.pumpAndSettle();
  }

  Future<void> selectContextArea(WidgetTester tester, int index) async {
    final areas = container.read(navigationControllerProvider).contextAreas;
    expect(areas, isNotNull);
    expect(index, lessThan(areas!.items.length));
    container
        .read(navigationControllerProvider.notifier)
        .selectContextArea(areas.items[index].id);
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

  testWidgets('analysis keeps suggested-area route UI in map details', (
    tester,
  ) async {
    await pumpScreen(tester);
    await enableLocation(tester);

    expect(find.byType(MapWidget), findsNothing);
    expect(find.text('Map configuration unavailable'), findsOneWidget);
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('pre-map-route-preferences')))
          .dy,
      lessThan(
        tester.getTopLeft(find.text('Map configuration unavailable')).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.text('Disaster type')).dy,
      lessThan(tester.getTopLeft(find.text('Earthquake context')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Earthquake context')).dy,
      lessThan(tester.getTopLeft(find.text('Travel profile')).dy),
    );
    expect(find.byKey(const ValueKey('map-layer-legend')), findsNothing);
    expect(find.text('Hazard summary'), findsNothing);
    expect(find.text('Shelter and hazard information'), findsNothing);
    expect(find.text('Test Hazard'), findsOneWidget);
    expect(find.text('SIMULATION'), findsNothing);
    expect(
      find.textContaining('Demonstration data is shown here'),
      findsNothing,
    );
    expect(find.text('Disaster type'), findsOneWidget);
    expect(find.text('Earthquake context'), findsOneWidget);
    expect(find.text('Travel profile'), findsOneWidget);
    expect(find.text('Request route suggestions'), findsNothing);

    await analyzeContext(tester);

    expect(find.text('Top lower-exposure suggestions'), findsNothing);
    expect(find.text('Suggestion 1'), findsNothing);
    expect(find.text('Context summary'), findsOneWidget);
    expect(
      find.text(
        'No mapped hazards found. This does not confirm the area is safe.',
      ),
      findsNothing,
    );
    expect(find.text('Disaster type'), findsOneWidget);
    expect(find.text('Earthquake context'), findsOneWidget);
    expect(find.text('Travel profile'), findsOneWidget);
    expect(find.text('Show route to the suggested area'), findsNothing);
  });

  testWidgets('shows named earthquake candidates and mapped metrics', (
    tester,
  ) async {
    navigationRepository.contextAreas = NavigationResource(
      data: ContextAreaCollectionDto.fromJson(
        contextAreaResponseJson(
          name: "People's Park",
          candidateNames: [
            "People's Park",
            'Bogyoke Sports Field',
            "People's Square",
          ],
          source: 'OpenStreetMap via Overpass',
          simulation: false,
          uncertaintyNotice:
              'OpenStreetMap coverage may be incomplete; missing mapped features are not confirmed absent.',
          rationale: [
            'Named park polygon from mapped place data',
            'Open space comparison after shaking',
          ],
        ),
      ).toDomain(),
      isCached: false,
      remoteFailed: false,
    );

    await pumpScreen(tester);
    await enableLocation(tester);
    await analyzeContext(tester);

    expect(find.text('Top lower-exposure suggestions'), findsNothing);
    expect(find.text('Suggestion 1'), findsNothing);
    expect(find.text('Suggestion 2'), findsNothing);
    expect(find.text('Suggestion 3'), findsNothing);
    await selectContextArea(tester, 0);
    final candidate = find.text("People's Park").first;
    await tester.ensureVisible(candidate);
    expect(find.text("People's Park"), findsWidgets);
    expect(find.text('Mapped comparison metrics'), findsWidgets);
    expect(
      find.text('Building clearance: 120 m; tree clearance: 90 m'),
      findsWidgets,
    );
    expect(find.text('Mapped building density: 10%'), findsWidgets);
    expect(find.text('Mapped tree density: 20%'), findsWidgets);
    expect(find.text('Mapped hazard intersections: 0'), findsWidgets);
    expect(find.text('Why this area is listed'), findsWidgets);
    expect(
      find.text('Named park polygon from mapped place data'),
      findsWidgets,
    );
    expect(find.text('Source: OpenStreetMap via Overpass'), findsWidgets);
    expect(find.text('© OpenStreetMap contributors'), findsWidgets);
    expect(find.textContaining('Analysis data:'), findsWidgets);
    expect(
      find.textContaining('OpenStreetMap coverage may be incomplete'),
      findsWidgets,
    );
    expect(find.bySemanticsLabel(RegExp("People's Park")), findsWidgets);

    await selectContextArea(tester, 1);
    expect(find.text('Bogyoke Sports Field'), findsWidgets);
    expect(find.text('Selected candidate'), findsWidgets);
    expect(find.text('Show route to the suggested area'), findsNothing);
  });

  testWidgets('shows flood elevation and omits earthquake-only metrics', (
    tester,
  ) async {
    final earthquake = ContextAreaCollectionDto.fromJson(
      contextAreaResponseJson(
        name: "People's Park",
        source: 'OpenStreetMap via Overpass',
        simulation: false,
        uncertaintyNotice: 'Mapped earthquake data may be incomplete.',
      ),
    ).toDomain();
    final flood = ContextAreaCollectionDto.fromJson(
      contextAreaResponseJson(
        name: 'Yangon City Golf Course',
        disasterType: 'flood',
        scenario: 'general',
        source: 'OpenTopoData',
        simulation: false,
        metrics: {
          'building_clearance_m': 2.0,
          'tree_clearance_m': 3.0,
          'relative_elevation_m': 7.5,
          'building_density': 0.8,
          'tree_density': 0.7,
          'hazard_intersections': 0,
        },
        rationale: ['About 7.5 m higher than the current location'],
        uncertaintyNotice:
            'Terrain elevation is not a flood forecast; mapped conditions may be incomplete.',
      ),
    ).toDomain();
    var response = earthquake;
    navigationRepository.contextAreasHandler = (_) async => NavigationResource(
      data: response,
      isCached: false,
      remoteFailed: false,
    );

    await pumpScreen(tester);
    await enableLocation(tester);
    await analyzeContext(tester);

    container
        .read(navigationControllerProvider.notifier)
        .selectDisasterType(DisasterType.flood);
    response = flood;
    await analyzeContext(tester);
    await selectContextArea(tester, 0);

    final candidate = find.text('Yangon City Golf Course').first;
    await tester.scrollUntilVisible(candidate, 200);
    await tester.ensureVisible(candidate);
    expect(find.text('Relative elevation: 7.5 m'), findsWidgets);
    expect(find.text('Mapped hazard intersections: 0'), findsWidgets);
    expect(find.textContaining('Mapped building density:'), findsNothing);
    expect(find.textContaining('Mapped tree density:'), findsNothing);
    expect(find.textContaining('Building clearance:'), findsNothing);
  });

  testWidgets('keeps empty analysis transparent without claiming no hazards', (
    tester,
  ) async {
    navigationRepository.contextAreas = NavigationResource(
      data: ContextAreaCollection(
        items: const [],
        dataAt: DateTime.utc(2026, 8, 17, 13, 42),
        source: 'OpenStreetMap via Overpass',
        uncertaintyNotice:
            'Mapped environment data is incomplete; no candidate was returned.',
      ),
      isCached: false,
      remoteFailed: false,
    );

    await pumpScreen(tester);
    await enableLocation(tester);
    await analyzeContext(tester);

    expect(find.text('Data, source, and limits'), findsOneWidget);
    expect(find.text('Source: OpenStreetMap via Overpass'), findsOneWidget);
    expect(
      find.textContaining('Mapped environment data is incomplete'),
      findsWidgets,
    );
    expect(
      find.text(
        'No mapped hazards found. This does not confirm the area is safe.',
      ),
      findsNothing,
    );
    expect(find.text('Show route to the suggested area'), findsNothing);
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
    expect(find.text('Top lower-exposure suggestions'), findsNothing);
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
    expect(find.text('Top lower-exposure suggestions'), findsNothing);
    expect(
      find.text('Building clearance: 120 m; tree clearance: 90 m'),
      findsNothing,
    );
    expect(locationRepository.permissionChecks, 0);
    await enableLocation(tester);
    await analyzeContext(tester);
    expect(find.text('Context summary'), findsOneWidget);
  });

  testWidgets('route request keeps ranked options and selection in state', (
    tester,
  ) async {
    navigationRepository.routes = NavigationResource(
      data: routeSuggestions(
        optionCount: 3,
        source: 'Verified shelter registry',
        simulation: false,
        uncertaintyNotice: 'Map and hazard data may be incomplete.',
      ),
      isCached: false,
      remoteFailed: false,
    );
    await pumpScreen(tester);
    await enableLocation(tester);
    await analyzeContext(tester);
    await requestRoutes(tester);

    final state = container.read(navigationControllerProvider);
    expect(state.routes?.options, hasLength(3));
    expect(state.selectedRouteId, state.routes?.options.first.id);
    container
        .read(navigationControllerProvider.notifier)
        .selectRoute(state.routes!.options.last.id);
    expect(
      container.read(navigationControllerProvider).selectedRouteId,
      state.routes!.options.last.id,
    );
    expect(find.byKey(const ValueKey('route-card-real-route-3')), findsNothing);
  });

  testWidgets('routing failure keeps shelter data and route state', (
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

    expect(find.text('Top lower-exposure suggestions'), findsNothing);
    expect(container.read(navigationControllerProvider).routeFailed, isTrue);
    expect(find.text('Retry route to the suggested area'), findsNothing);
  });

  testWidgets('empty routing keeps the selected candidates visible', (
    tester,
  ) async {
    navigationRepository.routes = NavigationResource(
      data: routeSuggestions(optionCount: 0),
      isCached: false,
      remoteFailed: false,
    );

    await pumpScreen(tester);
    await enableLocation(tester);
    await analyzeContext(tester);
    await requestRoutes(tester);

    expect(find.text('Top lower-exposure suggestions'), findsNothing);
    expect(find.text('Lower-exposure area 1'), findsOneWidget);
    expect(
      container.read(navigationControllerProvider).routes?.options,
      isEmpty,
    );
    expect(find.text('The server returned no route options.'), findsNothing);
  });

  testWidgets('cached routes remain visible with stale metadata', (
    tester,
  ) async {
    navigationRepository.routes = NavigationResource(
      data: routeSuggestions(optionCount: 2),
      isCached: true,
      remoteFailed: true,
      cachedAt: DateTime.utc(2026, 7, 23, 12, 30),
    );

    await pumpScreen(tester);
    await enableLocation(tester);
    await analyzeContext(tester);
    await requestRoutes(tester);

    final state = container.read(navigationControllerProvider);
    expect(state.routeFailed, isTrue);
    expect(state.routeCached, isTrue);
    expect(state.routeCachedAt, DateTime.utc(2026, 7, 23, 12, 30));
    expect(state.routes?.options, hasLength(2));
    expect(
      find.text('Route saved at: Jul 23, 2026 12:30:00 UTC'),
      findsNothing,
    );
    expect(find.text('Suggested'), findsNothing);
  });

  testWidgets('suggested-area route panel fits 390x844 at 200 percent text', (
    tester,
  ) async {
    navigationRepository.contextAreas = NavigationResource(
      data: ContextAreaCollectionDto.fromJson(
        contextAreaResponseJson(
          candidateNames: [
            'Lower-exposure area 1',
            'Lower-exposure area 2',
            'Lower-exposure area 3',
          ],
        ),
      ).toDomain(),
      isCached: false,
      remoteFailed: false,
    );
    navigationRepository.routes = NavigationResource(
      data: routeSuggestions(optionCount: 3),
      isCached: false,
      remoteFailed: false,
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(tester, textScale: 2);
    await enableLocation(tester);
    await analyzeContext(tester);
    await requestRoutes(tester);

    expect(find.text('Suggestion 1'), findsNothing);
    expect(find.text('Suggestion 2'), findsNothing);
    expect(find.text('Suggestion 3'), findsNothing);

    final routeState = container.read(navigationControllerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            theme: SafeTheme.light(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: SuggestedAreaRoutePanel(
                  state: routeState,
                  onRequestRoutes: () async {},
                  onRouteSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Disaster type'), findsNothing);
    expect(find.text('Travel profile'), findsNothing);
    expect(find.text('Earthquake context'), findsNothing);
    expect(find.text('Show route to the suggested area'), findsOneWidget);
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
    final routeSemantics = tester.getSemantics(
      find.byKey(const ValueKey('route-card-simulation-route-1')),
    );
    expect(routeSemantics.label, contains('Source: SafeMyanmar'));
    expect(routeSemantics.label, contains('Hazard data:'));
  });

  testWidgets('Map chrome uses reviewed Burmese labels', (tester) async {
    await pumpScreen(tester, locale: const Locale('my'));
    await tester.pumpAndSettle();

    expect(find.text('မြေပုံ'), findsWidgets);
    expect(find.text('ကျွန်ုပ်၏တည်နေရာကို အသုံးပြုရန်'), findsOneWidget);
  });
}

final location = ForegroundLocation(
  latitude: 21.95,
  longitude: 96.08,
  timestamp: DateTime.utc(2026, 7, 23, 12),
  precision: LocationPrecision.precise,
);
