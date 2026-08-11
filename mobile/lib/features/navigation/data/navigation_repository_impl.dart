import '../domain/navigation_models.dart';
import '../domain/navigation_repository.dart';
import 'navigation_local_source.dart';
import 'navigation_remote_source.dart';

final class NavigationRepositoryImpl implements NavigationRepository {
  NavigationRepositoryImpl({
    required NavigationLocalSource localSource,
    required NavigationRemoteSource remoteSource,
    DateTime Function()? now,
  }) : _local = localSource,
       _remote = remoteSource,
       _now = now ?? DateTime.now;

  final NavigationLocalSource _local;
  final NavigationRemoteSource _remote;
  final DateTime Function() _now;
  var _routeRequestGeneration = 0;

  @override
  Future<NavigationResource<ShelterCollection>> loadCachedShelters() async {
    try {
      final cached = await _local.readShelters();
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
      await _tryCache(() => _local.replaceShelters(value, _now().toUtc()));
      return NavigationResource(
        data: value.toDomain(),
        isCached: false,
        remoteFailed: false,
      );
    } catch (_) {
      try {
        final cached = await _local.readShelters();
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
      await _tryCache(() => _local.replaceHazards(value, _now().toUtc()));
      return NavigationResource(
        data: value.toDomain(),
        isCached: false,
        remoteFailed: false,
      );
    } catch (_) {
      try {
        final cached = await _local.readHazards();
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

  Future<void> _tryCache(Future<void> Function() write) async {
    try {
      await write();
    } catch (_) {
      // Fresh data remains usable when the optional offline cache cannot write.
    }
  }
}
