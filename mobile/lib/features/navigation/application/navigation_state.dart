import '../domain/navigation_models.dart';

const _notProvided = Object();

final class NavigationState {
  const NavigationState({
    this.loadingMapData = false,
    this.shelters,
    this.hazards,
    this.mapDataFailed = false,
    this.mapDataCached = false,
    this.mapDataCachedAt,
    this.selectedShelterId,
    this.disasterType = DisasterType.earthquake,
    this.profile = RouteProfile.walking,
    this.loadingRoutes = false,
    this.routes,
    this.routeFailed = false,
    this.routeCached = false,
    this.routeCachedAt,
    this.selectedRouteId,
    this.routeRequest,
  });

  final bool loadingMapData;
  final ShelterCollection? shelters;
  final HazardCollection? hazards;
  final bool mapDataFailed;
  final bool mapDataCached;
  final DateTime? mapDataCachedAt;
  final String? selectedShelterId;
  final DisasterType disasterType;
  final RouteProfile profile;
  final bool loadingRoutes;
  final RouteSuggestions? routes;
  final bool routeFailed;
  final bool routeCached;
  final DateTime? routeCachedAt;
  final String? selectedRouteId;
  final RouteSuggestionRequest? routeRequest;

  List<Hazard> get relevantHazards => List.unmodifiable(
    hazards?.items.where((item) => item.disasterType == disasterType) ??
        const <Hazard>[],
  );

  NavigationState copyWith({
    bool? loadingMapData,
    Object? shelters = _notProvided,
    Object? hazards = _notProvided,
    bool? mapDataFailed,
    bool? mapDataCached,
    Object? mapDataCachedAt = _notProvided,
    Object? selectedShelterId = _notProvided,
    DisasterType? disasterType,
    RouteProfile? profile,
    bool? loadingRoutes,
    Object? routes = _notProvided,
    bool? routeFailed,
    bool? routeCached,
    Object? routeCachedAt = _notProvided,
    Object? selectedRouteId = _notProvided,
    Object? routeRequest = _notProvided,
  }) => NavigationState(
    loadingMapData: loadingMapData ?? this.loadingMapData,
    shelters: identical(shelters, _notProvided)
        ? this.shelters
        : shelters as ShelterCollection?,
    hazards: identical(hazards, _notProvided)
        ? this.hazards
        : hazards as HazardCollection?,
    mapDataFailed: mapDataFailed ?? this.mapDataFailed,
    mapDataCached: mapDataCached ?? this.mapDataCached,
    mapDataCachedAt: identical(mapDataCachedAt, _notProvided)
        ? this.mapDataCachedAt
        : mapDataCachedAt as DateTime?,
    selectedShelterId: identical(selectedShelterId, _notProvided)
        ? this.selectedShelterId
        : selectedShelterId as String?,
    disasterType: disasterType ?? this.disasterType,
    profile: profile ?? this.profile,
    loadingRoutes: loadingRoutes ?? this.loadingRoutes,
    routes: identical(routes, _notProvided)
        ? this.routes
        : routes as RouteSuggestions?,
    routeFailed: routeFailed ?? this.routeFailed,
    routeCached: routeCached ?? this.routeCached,
    routeCachedAt: identical(routeCachedAt, _notProvided)
        ? this.routeCachedAt
        : routeCachedAt as DateTime?,
    selectedRouteId: identical(selectedRouteId, _notProvided)
        ? this.selectedRouteId
        : selectedRouteId as String?,
    routeRequest: identical(routeRequest, _notProvided)
        ? this.routeRequest
        : routeRequest as RouteSuggestionRequest?,
  );
}
