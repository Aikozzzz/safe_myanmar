import '../domain/navigation_models.dart';
import '../domain/navigation_repository.dart';
import 'navigation_local_source.dart';
import 'navigation_remote_source.dart';
import 'navigation_dto.dart';

final class NavigationRepositoryImpl implements NavigationRepository {
  NavigationRepositoryImpl({
    required NavigationLocalSource localSource,
    required NavigationRemoteSource remoteSource,
    DateTime Function()? now,
    this.allowSimulationData = false,
  }) : _local = localSource,
       _remote = remoteSource,
       _now = now ?? DateTime.now;

  final NavigationLocalSource _local;
  final NavigationRemoteSource _remote;
  final DateTime Function() _now;
  final bool allowSimulationData;
  var _routeRequestGeneration = 0;

  @override
  Future<NavigationResource<ShelterCollection>> loadCachedShelters() async {
    try {
      final cached = await _local.readShelters();
      if (cached != null &&
          !_usableSource(cached.value.source, cached.value.simulation)) {
        return const NavigationResource(
          data: null,
          isCached: false,
          remoteFailed: false,
        );
      }
      return NavigationResource(
        data: cached?.value.toDomain(),
        isCached: cached != null,
        remoteFailed: false,
        cachedAt: cached?.cachedAt,
      );
    } catch (_) {
      return const NavigationResource(
        data: null,
        isCached: false,
        remoteFailed: false,
      );
    }
  }

  @override
  Future<NavigationResource<HazardCollection>> loadCachedHazards() async {
    try {
      final cached = await _local.readHazards();
      if (cached != null &&
          !_usableSource(cached.value.source, cached.value.simulation)) {
        return const NavigationResource(
          data: null,
          isCached: false,
          remoteFailed: false,
        );
      }
      return NavigationResource(
        data: cached?.value.toDomain(),
        isCached: cached != null,
        remoteFailed: false,
        cachedAt: cached?.cachedAt,
      );
    } catch (_) {
      return const NavigationResource(
        data: null,
        isCached: false,
        remoteFailed: false,
      );
    }
  }

  @override
  Future<NavigationResource<ShelterCollection>> loadShelters() async {
    try {
      final value = await _remote.fetchShelters();
      _requireUsableSource(value.source, value.simulation);
      await _tryCache(() => _local.replaceShelters(value, _now().toUtc()));
      return NavigationResource(
        data: value.toDomain(),
        isCached: false,
        remoteFailed: false,
      );
    } catch (_) {
      try {
        final cached = await _local.readShelters();
        if (cached != null &&
            !_usableSource(cached.value.source, cached.value.simulation)) {
          return const NavigationResource(
            data: null,
            isCached: false,
            remoteFailed: true,
          );
        }
        return NavigationResource(
          data: cached?.value.toDomain(),
          isCached: cached != null,
          remoteFailed: true,
          cachedAt: cached?.cachedAt,
        );
      } catch (_) {
        return const NavigationResource(
          data: null,
          isCached: false,
          remoteFailed: true,
        );
      }
    }
  }

  @override
  Future<NavigationResource<HazardCollection>> loadHazards() async {
    try {
      final value = await _remote.fetchHazards();
      _requireUsableSource(value.source, value.simulation);
      await _tryCache(() => _local.replaceHazards(value, _now().toUtc()));
      return NavigationResource(
        data: value.toDomain(),
        isCached: false,
        remoteFailed: false,
      );
    } catch (_) {
      try {
        final cached = await _local.readHazards();
        if (cached != null &&
            !_usableSource(cached.value.source, cached.value.simulation)) {
          return const NavigationResource(
            data: null,
            isCached: false,
            remoteFailed: true,
          );
        }
        return NavigationResource(
          data: cached?.value.toDomain(),
          isCached: cached != null,
          remoteFailed: true,
          cachedAt: cached?.cachedAt,
        );
      } catch (_) {
        return const NavigationResource(
          data: null,
          isCached: false,
          remoteFailed: true,
        );
      }
    }
  }

  @override
  Future<NavigationResource<ContextAreaCollection>> findContextAreas(
    ContextAreaRequest request,
  ) async {
    try {
      final value = await _remote.findContextAreas(request);
      _requireUsableSource(value.source, value.simulation);
      await _tryCache(
        () => _local.replaceContextAreas(value, request, _now().toUtc()),
      );
      return NavigationResource(
        data: value.toDomain(),
        isCached: false,
        remoteFailed: false,
      );
    } catch (_) {
      try {
        final cached = await _local.readContextAreas(request);
        if (cached != null &&
            !_usableSource(cached.value.source, cached.value.simulation)) {
          return const NavigationResource(
            data: null,
            isCached: false,
            remoteFailed: true,
          );
        }
        return NavigationResource(
          data: cached?.value.toDomain(),
          isCached: cached != null,
          remoteFailed: true,
          cachedAt: cached?.cachedAt,
        );
      } catch (_) {
        return const NavigationResource(
          data: null,
          isCached: false,
          remoteFailed: true,
        );
      }
    }
  }

  @override
  Future<NavigationResource<ContextAreaCollection>> loadCachedContextAreas(
    ContextAreaRequest request,
  ) async {
    try {
      final cached = await _local.readContextAreas(request);
      if (cached != null &&
          !_usableSource(cached.value.source, cached.value.simulation)) {
        return const NavigationResource(
          data: null,
          isCached: false,
          remoteFailed: false,
        );
      }
      return NavigationResource(
        data: cached?.value.toDomain(),
        isCached: cached != null,
        remoteFailed: false,
        cachedAt: cached?.cachedAt,
      );
    } catch (_) {
      return const NavigationResource(
        data: null,
        isCached: false,
        remoteFailed: false,
      );
    }
  }

  @override
  Future<NavigationResource<RouteSuggestions>> suggestRoutes(
    RouteSuggestionRequest request,
  ) async {
    final generation = ++_routeRequestGeneration;
    try {
      final value = await _remote.fetchRouteSuggestions(request);
      _requireUsableSource(value.source, value.simulation);
      if (generation == _routeRequestGeneration) {
        await _tryCache(
          () => _local.replaceRoutes(value, request, _now().toUtc()),
        );
      }
      return NavigationResource(
        data: value.toDomain(),
        isCached: false,
        remoteFailed: false,
      );
    } catch (_) {
      try {
        final cached = await _local.readRoutes(request);
        if (cached != null &&
            !_usableSource(cached.value.source, cached.value.simulation)) {
          return const NavigationResource(
            data: null,
            isCached: false,
            remoteFailed: true,
          );
        }
        return NavigationResource(
          data: cached?.value.toDomain(),
          isCached: cached != null,
          remoteFailed: true,
          cachedAt: cached?.cachedAt,
        );
      } catch (_) {
        return const NavigationResource(
          data: null,
          isCached: false,
          remoteFailed: true,
        );
      }
    }
  }

  @override
  Future<NavigationResource<RouteSuggestions>> suggestSosRoute(
    SosRouteRequest request,
  ) async {
    try {
      final value = await _remote.fetchSosRouteSuggestions(request);
      _requireUsableSource(value.source, value.simulation);
      return NavigationResource(
        data: value.toDomain(),
        isCached: false,
        remoteFailed: false,
      );
    } catch (_) {
      return const NavigationResource(
        data: null,
        isCached: false,
        remoteFailed: true,
      );
    }
  }

  bool _usableSource(String source, bool simulation) =>
      allowSimulationData || (!simulation && source != 'SafeMyanmar Demo');

  void _requireUsableSource(String source, bool simulation) {
    if (!_usableSource(source, simulation)) {
      throw NavigationProtocolException();
    }
  }

  Future<void> _tryCache(Future<void> Function() write) async {
    try {
      await write();
    } catch (_) {
      // Fresh data remains usable when the optional offline cache cannot write.
    }
  }
}
