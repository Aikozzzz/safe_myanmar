import 'package:mobile/features/navigation/domain/navigation_models.dart';
import 'package:mobile/features/navigation/domain/navigation_repository.dart';

import 'navigation_fixtures.dart';

final class FakeNavigationRepository implements NavigationRepository {
  NavigationResource<ShelterCollection> shelters = NavigationResource(
    data: shelterCollection(),
    isCached: false,
    remoteFailed: false,
  );
  NavigationResource<HazardCollection> hazards = NavigationResource(
    data: hazardCollection(),
    isCached: false,
    remoteFailed: false,
  );
  NavigationResource<RouteSuggestions> routes = NavigationResource(
    data: routeSuggestions(),
    isCached: false,
    remoteFailed: false,
  );
  NavigationResource<ContextAreaCollection> contextAreas =
      const NavigationResource(
        data: null,
        isCached: false,
        remoteFailed: false,
      );
  final List<RouteSuggestionRequest> requests = [];
  Future<NavigationResource<RouteSuggestions>> Function(
    RouteSuggestionRequest request,
  )?
  routesHandler;
  Future<NavigationResource<ShelterCollection>> Function()? sheltersHandler;
  Future<NavigationResource<HazardCollection>> Function()? hazardsHandler;
  Future<NavigationResource<ContextAreaCollection>> Function(
    ContextAreaRequest request,
  )?
  contextAreasHandler;
  NavigationResource<ShelterCollection> cachedShelters =
      const NavigationResource(
        data: null,
        isCached: false,
        remoteFailed: false,
      );
  NavigationResource<HazardCollection> cachedHazards = const NavigationResource(
    data: null,
    isCached: false,
    remoteFailed: false,
  );

  @override
  Future<NavigationResource<HazardCollection>> loadCachedHazards() async =>
      cachedHazards;

  @override
  Future<NavigationResource<ShelterCollection>> loadCachedShelters() async =>
      cachedShelters;

  @override
  Future<NavigationResource<HazardCollection>> loadHazards() async =>
      hazardsHandler?.call() ?? hazards;

  @override
  Future<NavigationResource<ContextAreaCollection>> findContextAreas(
    ContextAreaRequest request,
  ) async => contextAreasHandler?.call(request) ?? contextAreas;

  @override
  Future<NavigationResource<ContextAreaCollection>> loadCachedContextAreas(
    ContextAreaRequest request,
  ) async => const NavigationResource(
    data: null,
    isCached: false,
    remoteFailed: false,
  );

  @override
  Future<NavigationResource<ShelterCollection>> loadShelters() async =>
      sheltersHandler?.call() ?? shelters;

  @override
  Future<NavigationResource<RouteSuggestions>> suggestRoutes(
    RouteSuggestionRequest request,
  ) async {
    requests.add(request);
    return routesHandler?.call(request) ?? routes;
  }
}
