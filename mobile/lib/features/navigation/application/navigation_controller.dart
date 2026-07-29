import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../location/domain/foreground_location.dart';
import '../domain/navigation_models.dart';
import '../domain/navigation_repository.dart';
import 'navigation_state.dart';
import 'providers.dart';

final class NavigationController extends Notifier<NavigationState> {
  NavigationRepository? _repository;
  Future<void>? _mapLoad;
  Future<void>? _routeLoad;
  var _routeGeneration = 0;

  @override
  NavigationState build() {
    return const NavigationState();
  }

  Future<void> loadMapData({bool force = false}) {
    if (!force && (state.shelters != null || state.loadingMapData)) {
      return _mapLoad ?? Future.value();
    }
    final active = _mapLoad;
    if (active != null) return active;
    late Future<void> request;
    request = _loadMapData().whenComplete(() {
      if (identical(_mapLoad, request)) _mapLoad = null;
    });
    _mapLoad = request;
    return request;
  }

  void selectShelter(String shelterId) {
    if (state.shelters?.items.any((item) => item.id == shelterId) != true) {
      return;
    }
    if (state.selectedShelterId == shelterId) return;
    state = state.copyWith(selectedShelterId: shelterId);
    _invalidateRoutes();
  }

  void selectDisasterType(DisasterType value) {
    if (state.disasterType == value) return;
    state = state.copyWith(disasterType: value);
    _invalidateRoutes();
  }

  void selectProfile(RouteProfile value) {
    if (state.profile == value) return;
    state = state.copyWith(profile: value);
    _invalidateRoutes();
  }

  void updateLocation(ForegroundLocation? location) {
    final request = state.routeRequest;
    if (request == null || location == null) {
      if (location == null && request != null) _invalidateRoutes();
      return;
    }
    final next = RouteSuggestionRequest(
      origin: NavigationCoordinate(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
      shelterId: request.shelterId,
      disasterType: request.disasterType,
      profile: request.profile,
    );
    if (!request.matches(next)) _invalidateRoutes();
  }

  void selectRoute(String routeId) {
    if (state.routes?.options.any((item) => item.id == routeId) != true) return;
    state = state.copyWith(selectedRouteId: routeId);
  }

  Future<void> requestRoutes(ForegroundLocation location) {
    final shelterId = state.selectedShelterId;
    if (shelterId == null) return Future.value();
    final routeRequest = RouteSuggestionRequest(
      origin: NavigationCoordinate(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
      shelterId: shelterId,
      disasterType: state.disasterType,
      profile: state.profile,
    );
    final generation = ++_routeGeneration;
    late Future<void> request;
    request = _requestRoutes(routeRequest, generation).whenComplete(() {
      if (identical(_routeLoad, request)) _routeLoad = null;
    });
    _routeLoad = request;
    return request;
  }

  Future<void> _loadMapData() async {
    state = state.copyWith(loadingMapData: true, mapDataFailed: false);
    late final NavigationRepository repository;
    try {
      _repository ??= ref.read(navigationRepositoryProvider);
      repository = _repository!;
    } catch (_) {
      state = state.copyWith(loadingMapData: false, mapDataFailed: true);
      return;
    }
    final results = await Future.wait([
      repository.loadCachedShelters(),
      repository.loadCachedHazards(),
    ]);
    _applyMapResults(results, loading: true);

    final remoteResults = await Future.wait([
      repository.loadShelters(),
      repository.loadHazards(),
    ]);
    _applyMapResults(remoteResults, loading: false);
  }

  void _applyMapResults(
    List<NavigationResource<Object>> results, {
    required bool loading,
  }) {
    final shelters = results[0] as NavigationResource<ShelterCollection>;
    final hazards = results[1] as NavigationResource<HazardCollection>;
    final shelterData = shelters.data ?? state.shelters;
    final hazardData = hazards.data ?? state.hazards;
    final remoteFailed = shelters.remoteFailed || hazards.remoteFailed;
    var selectedShelterId = state.selectedShelterId;
    if (shelterData != null &&
        !shelterData.items.any((item) => item.id == selectedShelterId)) {
      selectedShelterId = shelterData.items.firstOrNull?.id;
    }
    final shelterChanged = selectedShelterId != state.selectedShelterId;
    state = state.copyWith(
      loadingMapData: loading,
      shelters: shelterData,
      hazards: hazardData,
      selectedShelterId: selectedShelterId,
      mapDataFailed: remoteFailed,
      mapDataCached:
          shelters.isCached ||
          hazards.isCached ||
          (remoteFailed && (shelterData != null || hazardData != null)),
      mapDataCachedAt:
          _latest(shelters.cachedAt, hazards.cachedAt) ??
          (remoteFailed ? state.mapDataCachedAt : null),
    );
    if (shelterChanged && state.routes != null) _invalidateRoutes();
  }

  Future<void> _requestRoutes(
    RouteSuggestionRequest routeRequest,
    int generation,
  ) async {
    final sameContext = state.routeRequest?.matches(routeRequest) == true;
    state = state.copyWith(
      loadingRoutes: true,
      routeFailed: false,
      routes: sameContext ? state.routes : null,
      routeCached: sameContext && state.routeCached,
      routeCachedAt: sameContext ? state.routeCachedAt : null,
      selectedRouteId: sameContext ? state.selectedRouteId : null,
      routeRequest: routeRequest,
    );
    late final NavigationRepository repository;
    try {
      _repository ??= ref.read(navigationRepositoryProvider);
      repository = _repository!;
    } catch (_) {
      if (generation != _routeGeneration) return;
      state = state.copyWith(loadingRoutes: false, routeFailed: true);
      return;
    }
    final result = await repository.suggestRoutes(routeRequest);
    if (generation != _routeGeneration ||
        state.routeRequest?.matches(routeRequest) != true) {
      return;
    }
    final existingRoutes = state.routeRequest?.matches(routeRequest) == true
        ? state.routes
        : null;
    final routes = result.data ?? existingRoutes;
    final staleRoutes = result.remoteFailed && routes != null;
    final currentSelection = state.selectedRouteId;
    final selectedRouteId =
        routes?.options.any((item) => item.id == currentSelection) == true
        ? currentSelection
        : routes?.options.firstOrNull?.id;
    state = state.copyWith(
      loadingRoutes: false,
      routes: routes,
      routeFailed: result.remoteFailed,
      routeCached: result.isCached || staleRoutes,
      routeCachedAt:
          result.cachedAt ?? (staleRoutes ? state.routeCachedAt : null),
      selectedRouteId: selectedRouteId,
      routeRequest: routeRequest,
    );
  }

  void _invalidateRoutes() {
    _routeGeneration++;
    _routeLoad = null;
    state = state.copyWith(
      loadingRoutes: false,
      routes: null,
      routeFailed: false,
      routeCached: false,
      routeCachedAt: null,
      selectedRouteId: null,
      routeRequest: null,
    );
  }

  DateTime? _latest(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isAfter(second) ? first : second;
  }
}
