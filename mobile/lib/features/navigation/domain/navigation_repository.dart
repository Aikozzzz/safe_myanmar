import 'navigation_models.dart';

final class NavigationResource<T> {
  const NavigationResource({
    required this.data,
    required this.isCached,
    required this.remoteFailed,
    this.cachedAt,
  });

  final T? data;
  final bool isCached;
  final bool remoteFailed;
  final DateTime? cachedAt;
}

abstract interface class NavigationRepository {
  Future<NavigationResource<ShelterCollection>> loadCachedShelters();
  Future<NavigationResource<HazardCollection>> loadCachedHazards();
  Future<NavigationResource<ShelterCollection>> loadShelters();
  Future<NavigationResource<HazardCollection>> loadHazards();
  Future<NavigationResource<ContextAreaCollection>> findContextAreas(
    ContextAreaRequest request,
  );
  Future<NavigationResource<ContextAreaCollection>> loadCachedContextAreas(
    ContextAreaRequest request,
  );
  Future<NavigationResource<RouteSuggestions>> suggestRoutes(
    RouteSuggestionRequest request,
  );
  Future<NavigationResource<RouteSuggestions>> suggestSosRoute(
    SosRouteRequest request,
  );
}
