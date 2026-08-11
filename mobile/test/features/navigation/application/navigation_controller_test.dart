import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/location/domain/foreground_location.dart';
import 'package:mobile/features/navigation/application/providers.dart';
import 'package:mobile/features/navigation/domain/navigation_models.dart';
import 'package:mobile/features/navigation/domain/navigation_repository.dart';

import '../../../support/fake_navigation_repository.dart';
import '../../../support/navigation_fixtures.dart';

void main() {
  for (final count in [0, 1, 2, 3]) {
    test('keeps exactly $count server route options', () async {
      final repository = FakeNavigationRepository()
        ..routes = NavigationResource(
          data: routeSuggestions(optionCount: count),
          isCached: false,
          remoteFailed: false,
        );
      final container = ProviderContainer(
        overrides: [navigationRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(navigationControllerProvider.notifier);

      await controller.loadMapData();
      await controller.requestRoutes(location);

      expect(
        container.read(navigationControllerProvider).routes?.options,
        hasLength(count),
      );
      if (count == 0) {
        expect(
          container.read(navigationControllerProvider).selectedRouteId,
          isNull,
        );
      }
    });
  }

  test(
    'selection and profile override update state and backend request',
    () async {
      final repository = FakeNavigationRepository()
        ..routes = NavigationResource(
          data: routeSuggestions(optionCount: 3),
          isCached: false,
          remoteFailed: false,
        );
      final container = ProviderContainer(
        overrides: [navigationRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(navigationControllerProvider.notifier);

      await controller.loadMapData();
      controller.selectProfile(RouteProfile.driving);
      controller.selectDisasterType(DisasterType.flood);
      await controller.requestRoutes(location);
      controller.selectRoute('simulation-route-3');

      final request = repository.requests.single;
      expect(request.profile, RouteProfile.driving);
      expect(request.disasterType, DisasterType.flood);
      expect(request.origin.latitude, location.latitude);
      expect(
        container.read(navigationControllerProvider).selectedRouteId,
        'simulation-route-3',
      );
    },
  );

  test('routing failure preserves shelters and previous routes', () async {
    final repository = FakeNavigationRepository();
    final container = ProviderContainer(
      overrides: [navigationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(navigationControllerProvider.notifier);
    await controller.loadMapData();
    await controller.requestRoutes(location);
    repository.routes = const NavigationResource(
      data: null,
      isCached: false,
      remoteFailed: true,
    );

    await controller.requestRoutes(location);

    final state = container.read(navigationControllerProvider);
    expect(state.routeFailed, isTrue);
    expect(state.routeCached, isTrue);
    expect(state.shelters?.items, isNotEmpty);
    expect(state.routes?.options, hasLength(1));
  });

  test(
    'active earthquake scenario preserves immediate safety guidance',
    () async {
      final repository = FakeNavigationRepository()
        ..contextAreas = NavigationResource(
          data: ContextAreaCollection(
            items: const [],
            dataAt: DateTime.utc(2026, 7, 23, 12),
            source: 'SafeMyanmar Demo',
            uncertaintyNotice:
                'During active shaking, use Drop, Cover, and Hold On.',
          ),
          isCached: false,
          remoteFailed: false,
        );
      final container = ProviderContainer(
        overrides: [navigationRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(navigationControllerProvider.notifier);

      controller.selectContextScenario(ContextScenario.general);
      await controller.analyzeContext(location);

      final state = container.read(navigationControllerProvider);
      expect(state.contextRequest?.scenario, ContextScenario.general);
      expect(state.contextAreas?.items, isEmpty);
      expect(
        state.contextAreas?.uncertaintyNotice,
        'During active shaking, use Drop, Cover, and Hold On.',
      );
    },
  );

  test(
    'changing route inputs immediately clears prior route context',
    () async {
      final repository = FakeNavigationRepository();
      final container = ProviderContainer(
        overrides: [navigationRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(navigationControllerProvider.notifier);
      await controller.loadMapData();
      await controller.requestRoutes(location);

      controller.selectDisasterType(DisasterType.flood);

      final state = container.read(navigationControllerProvider);
      expect(state.routes, isNull);
      expect(state.routeRequest, isNull);
      expect(state.selectedRouteId, isNull);
    },
  );

  test('late route response is discarded after a newer request', () async {
    final first = Completer<NavigationResource<RouteSuggestions>>();
    final second = Completer<NavigationResource<RouteSuggestions>>();
    final repository = FakeNavigationRepository()
      ..routesHandler = (request) => request.disasterType == DisasterType.flood
          ? second.future
          : first.future;
    final container = ProviderContainer(
      overrides: [navigationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(navigationControllerProvider.notifier);
    await controller.loadMapData();

    final oldRequest = controller.requestRoutes(location);
    controller.selectDisasterType(DisasterType.flood);
    final newRequest = controller.requestRoutes(location);
    second.complete(
      NavigationResource(
        data: routeSuggestions(optionCount: 2),
        isCached: false,
        remoteFailed: false,
      ),
    );
    await newRequest;
    first.complete(
      NavigationResource(
        data: routeSuggestions(optionCount: 1),
        isCached: false,
        remoteFailed: false,
      ),
    );
    await oldRequest;

    final state = container.read(navigationControllerProvider);
    expect(state.routeRequest?.disasterType, DisasterType.flood);
    expect(state.routes?.options, hasLength(2));
  });

  test(
    'material location change clears routes and rejects late response',
    () async {
      final response = Completer<NavigationResource<RouteSuggestions>>();
      final repository = FakeNavigationRepository()
        ..routesHandler = (_) => response.future;
      final container = ProviderContainer(
        overrides: [navigationRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(navigationControllerProvider.notifier);
      await controller.loadMapData();

      final pending = controller.requestRoutes(location);
      controller.updateLocation(
        ForegroundLocation(
          latitude: 21.951,
          longitude: 96.08,
          timestamp: location.timestamp.add(const Duration(minutes: 1)),
          precision: LocationPrecision.precise,
        ),
      );
      response.complete(
        NavigationResource(
          data: routeSuggestions(),
          isCached: false,
          remoteFailed: false,
        ),
      );
      await pending;

      final state = container.read(navigationControllerProvider);
      expect(state.routes, isNull);
      expect(state.routeRequest, isNull);
      expect(state.loadingRoutes, isFalse);
    },
  );
}

final location = ForegroundLocation(
  latitude: 21.95,
  longitude: 96.08,
  timestamp: DateTime.utc(2026, 7, 23, 12),
  precision: LocationPrecision.precise,
);
