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
  Future<void>? _contextLoad;
  var _routeGeneration = 0;
  var _contextGeneration = 0;

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
    state = state.copyWith(
      disasterType: value,
      contextScenario: value == DisasterType.earthquake
          ? ContextScenario.outdoorsAfterShaking
          : ContextScenario.general,
      contextAreas: null,
      contextAnalysisRequested: false,
      selectedContextAreaId: null,
      contextRequest: null,
    );
    _invalidateRoutes();
  }

  void selectContextScenario(ContextScenario value) {
    if (state.contextScenario == value) return;
    state = state.copyWith(
      contextScenario: value,
      contextAreas: null,
      contextAnalysisRequested: false,
      selectedContextAreaId: null,
      contextRequest: null,
    );
    _invalidateRoutes();
  }

  void selectContextArea(String areaId) {
    if (state.contextAreas?.items.any((item) => item.id == areaId) != true) {
      return;
    }
    state = state.copyWith(selectedContextAreaId: areaId);
    _invalidateRoutes();
  }

  Future<void> analyzeContext(ForegroundLocation location) {
    final request = ContextAreaRequest(
      origin: NavigationCoordinate(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
      disasterType: state.disasterType,
      scenario: state.disasterType == DisasterType.earthquake
          ? state.contextScenario
          : ContextScenario.general,
    );
    final generation = ++_contextGeneration;
    late Future<void> pending;
    pending = _analyzeContext(request, generation).whenComplete(() {
      if (identical(_contextLoad, pending)) _contextLoad = null;
    });
    _contextLoad = pending;
    return pending;
  }

  void selectProfile(RouteProfile value) {
    if (state.profile == value) return;
    state = state.copyWith(profile: value);
    _invalidateRoutes();
  }

  void updateLocation(ForegroundLocation? location) {
    if (location == null && state.contextRequest != null) {
      _contextGeneration++;
      state = state.copyWith(
        contextAreas: null,
        contextAnalysisRequested: false,
        selectedContextAreaId: null,
        contextRequest: null,
      );
    }
    if (location != null && state.contextRequest != null) {
      final nextContext = ContextAreaRequest(
        origin: NavigationCoordinate(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
        disasterType: state.contextRequest!.disasterType,
        scenario: state.contextRequest!.scenario,
        searchRadiusM: state.contextRequest!.searchRadiusM,
      );
      if (!state.contextRequest!.matches(nextContext)) {
        _contextGeneration++;
        state = state.copyWith(
          contextAreas: null,
          contextAnalysisRequested: false,
          selectedContextAreaId: null,
          contextRequest: null,
        );
      }
    }
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
      contextAreaId: request.contextAreaId,
      disasterType: request.disasterType,
      profile: request.profile,
      scenario: request.scenario,
      searchRadiusM: request.searchRadiusM,
    );
    if (!request.matches(next)) _invalidateRoutes();
  }

  void selectRoute(String routeId) {
    if (state.routes?.options.any((item) => item.id == routeId) != true) return;
    state = state.copyWith(selectedRouteId: routeId);
  }

  Future<void> requestRoutes(ForegroundLocation location) {
    final contextAreaId = state.selectedContextAreaId;
    final destinationId = contextAreaId ?? state.selectedShelterId;
    if (destinationId == null) return Future.value();
    final scenario = state.disasterType == DisasterType.earthquake
        ? state.contextScenario
        : ContextScenario.general;
    final routeRequest = RouteSuggestionRequest(
      origin: NavigationCoordinate(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
      shelterId: destinationId,
      contextAreaId: contextAreaId,
      disasterType: state.disasterType,
      profile: state.profile,
      scenario: scenario,
      searchRadiusM: state.contextRequest?.searchRadiusM ?? 1000,
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

  Future<void> _analyzeContext(
    ContextAreaRequest request,
    int generation,
  ) async {
    state = state.copyWith(
      contextAnalysisLoading: true,
      contextAnalysisFailed: false,
      contextAnalysisRequested: true,
      contextAreas: null,
      selectedContextAreaId: null,
    );
    late final NavigationRepository repository;
    try {
      _repository ??= ref.read(navigationRepositoryProvider);
      repository = _repository!;
    } catch (_) {
      if (generation == _contextGeneration) {
        state = state.copyWith(
          contextAnalysisLoading: false,
          contextAnalysisFailed: true,
          contextRequest: request,
        );
      }
      return;
    }
    final cached = await repository.loadCachedContextAreas(request);
    if (generation != _contextGeneration) return;
    state = state.copyWith(
      contextAreas: cached.data,
      contextRequest: request,
      selectedContextAreaId: cached.data?.items.firstOrNull?.id,
    );
    final result = await repository.findContextAreas(request);
    if (generation != _contextGeneration) return;
    final areas = result.data;
    state = state.copyWith(
      contextAnalysisLoading: false,
      contextAnalysisFailed: result.remoteFailed,
      contextAreas: areas,
      contextRequest: request,
      selectedContextAreaId: areas?.items.firstOrNull?.id,
    );
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
