import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/network/api_config.dart';
import 'package:mobile/features/navigation/data/navigation_local_source.dart';
import 'package:mobile/features/navigation/data/navigation_remote_source.dart';
import 'package:mobile/features/navigation/data/navigation_repository_impl.dart';
import 'package:mobile/features/navigation/domain/navigation_models.dart';

import '../../../support/navigation_fixtures.dart';

void main() {
  test('returns latest cached shelters when remote is unavailable', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = DriftNavigationLocalSource(database);
    final firstRemote = NavigationRemoteSource(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(shelterResponseJson()),
          200,
          headers: const {'content-type': 'application/json'},
        ),
      ),
      config: ApiConfig.fromRaw('https://api.example.test', isProduction: true),
    );
    final now = DateTime.utc(2026, 7, 23, 13);
    final online = NavigationRepositoryImpl(
      localSource: local,
      remoteSource: firstRemote,
      now: () => now,
      allowSimulationData: true,
    );

    final fresh = await online.loadShelters();
    expect(fresh.isCached, isFalse);

    final offline = NavigationRepositoryImpl(
      localSource: local,
      remoteSource: NavigationRemoteSource(
        client: MockClient((_) async => throw http.ClientException('offline')),
        config: ApiConfig.fromRaw(
          'https://api.example.test',
          isProduction: true,
        ),
      ),
      allowSimulationData: true,
    );
    final fallback = await offline.loadShelters();

    expect(fallback.data?.items.single.id, 'simulation-shelter-1');
    expect(fallback.isCached, isTrue);
    expect(fallback.remoteFailed, isTrue);
    expect(fallback.cachedAt, now);
  });

  test('does not show cached simulation data in real mode', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = DriftNavigationLocalSource(database);
    final online = NavigationRepositoryImpl(
      localSource: local,
      remoteSource: NavigationRemoteSource(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(shelterResponseJson()),
            200,
            headers: const {'content-type': 'application/json'},
          ),
        ),
        config: ApiConfig.fromRaw(
          'https://api.example.test',
          isProduction: true,
        ),
      ),
      allowSimulationData: true,
    );
    await online.loadShelters();

    final offline = NavigationRepositoryImpl(
      localSource: local,
      remoteSource: NavigationRemoteSource(
        client: MockClient((_) async => throw http.ClientException('offline')),
        config: ApiConfig.fromRaw(
          'https://api.example.test',
          isProduction: true,
        ),
      ),
    );

    final result = await offline.loadShelters();

    expect(result.data, isNull);
    expect(result.isCached, isFalse);
    expect(result.remoteFailed, isTrue);
  });

  test('rejects mixed simulation analysis in real mode', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = NavigationRepositoryImpl(
      localSource: DriftNavigationLocalSource(database),
      remoteSource: NavigationRemoteSource(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(
              contextAreaResponseJson(
                source:
                    'Yangon snapshot; SafeMyanmar Demo simulation analysis data',
                simulation: true,
              ),
            ),
            200,
            headers: const {'content-type': 'application/json'},
          ),
        ),
        config: ApiConfig.fromRaw(
          'https://api.example.test',
          isProduction: true,
        ),
      ),
    );

    final result = await repository.findContextAreas(
      const ContextAreaRequest(
        origin: NavigationCoordinate(latitude: 21.95, longitude: 96.08),
        disasterType: DisasterType.earthquake,
        scenario: ContextScenario.outdoorsAfterShaking,
      ),
    );

    expect(result.data, isNull);
    expect(result.isCached, isFalse);
    expect(result.remoteFailed, isTrue);
  });

  test(
    'falls back to a matching real route cache with an explicit stale result',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final local = DriftNavigationLocalSource(database);
      const request = RouteSuggestionRequest(
        origin: NavigationCoordinate(latitude: 16.856152, longitude: 96.130522),
        shelterId: 'mapped-context-area',
        contextAreaId: 'mapped-context-area',
        disasterType: DisasterType.earthquake,
        scenario: ContextScenario.outdoorsAfterShaking,
        profile: RouteProfile.walking,
      );
      final online = NavigationRepositoryImpl(
        localSource: local,
        remoteSource: NavigationRemoteSource(
          client: MockClient(
            (_) async => http.Response(
              jsonEncode(
                routeResponseJson(
                  source: 'Verified shelter registry',
                  simulation: false,
                  uncertaintyNotice: 'Route data may be incomplete.',
                ),
              ),
              200,
              headers: const {'content-type': 'application/json'},
            ),
          ),
          config: ApiConfig.fromRaw(
            'https://api.example.test',
            isProduction: true,
          ),
        ),
        now: () => DateTime.utc(2026, 8, 17, 13),
      );

      final fetched = await online.suggestRoutes(request);
      final offline = NavigationRepositoryImpl(
        localSource: local,
        remoteSource: NavigationRemoteSource(
          client: MockClient(
            (_) async => throw http.ClientException('offline'),
          ),
          config: ApiConfig.fromRaw(
            'https://api.example.test',
            isProduction: true,
          ),
        ),
      );
      final fallback = await offline.suggestRoutes(request);

      expect(fetched.data?.simulation, isFalse);
      expect(fallback.data?.source, 'Verified shelter registry');
      expect(fallback.data?.options, hasLength(1));
      expect(fallback.isCached, isTrue);
      expect(fallback.remoteFailed, isTrue);
      expect(fallback.cachedAt, DateTime.utc(2026, 8, 17, 13));
    },
  );

  test(
    'never returns a cached route for a different request context',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final local = DriftNavigationLocalSource(database);
      final online = NavigationRepositoryImpl(
        localSource: local,
        remoteSource: NavigationRemoteSource(
          client: MockClient(
            (_) async => http.Response(
              jsonEncode(routeResponseJson()),
              200,
              headers: const {'content-type': 'application/json'},
            ),
          ),
          config: ApiConfig.fromRaw(
            'https://api.example.test',
            isProduction: true,
          ),
        ),
        now: () => DateTime.utc(2026, 7, 23, 13),
        allowSimulationData: true,
      );
      const original = RouteSuggestionRequest(
        origin: NavigationCoordinate(latitude: 21.95, longitude: 96.08),
        shelterId: 'simulation-shelter-1',
        disasterType: DisasterType.earthquake,
        profile: RouteProfile.walking,
      );
      await online.suggestRoutes(original);
      final offline = NavigationRepositoryImpl(
        localSource: local,
        remoteSource: NavigationRemoteSource(
          client: MockClient(
            (_) async => throw http.ClientException('offline'),
          ),
          config: ApiConfig.fromRaw(
            'https://api.example.test',
            isProduction: true,
          ),
        ),
      );

      final mismatch = await offline.suggestRoutes(
        const RouteSuggestionRequest(
          origin: NavigationCoordinate(latitude: 21.95, longitude: 96.08),
          shelterId: 'simulation-shelter-1',
          disasterType: DisasterType.flood,
          profile: RouteProfile.walking,
        ),
      );

      expect(mismatch.data, isNull);
      expect(mismatch.isCached, isFalse);
      expect(mismatch.remoteFailed, isTrue);
    },
  );

  test('late route response cannot overwrite newer request cache', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = DriftNavigationLocalSource(database);
    final first = Completer<http.Response>();
    final second = Completer<http.Response>();
    var requests = 0;
    final repository = NavigationRepositoryImpl(
      localSource: local,
      remoteSource: NavigationRemoteSource(
        client: MockClient((_) {
          requests++;
          return requests == 1 ? first.future : second.future;
        }),
        config: ApiConfig.fromRaw(
          'https://api.example.test',
          isProduction: true,
        ),
      ),
      now: () => DateTime.utc(2026, 7, 23, 13),
      allowSimulationData: true,
    );
    const olderRequest = RouteSuggestionRequest(
      origin: NavigationCoordinate(latitude: 21.95, longitude: 96.08),
      shelterId: 'simulation-shelter-1',
      disasterType: DisasterType.earthquake,
      profile: RouteProfile.walking,
    );
    const newerRequest = RouteSuggestionRequest(
      origin: NavigationCoordinate(latitude: 21.95, longitude: 96.08),
      shelterId: 'simulation-shelter-1',
      disasterType: DisasterType.flood,
      profile: RouteProfile.driving,
    );

    final older = repository.suggestRoutes(olderRequest);
    final newer = repository.suggestRoutes(newerRequest);
    second.complete(
      http.Response(
        jsonEncode(routeResponseJson(profile: 'driving')),
        200,
        headers: const {'content-type': 'application/json'},
      ),
    );
    await newer;
    first.complete(
      http.Response(
        jsonEncode(routeResponseJson()),
        200,
        headers: const {'content-type': 'application/json'},
      ),
    );
    await older;

    expect(
      (await local.readRoutes(newerRequest))?.value.profile,
      RouteProfile.driving,
    );
    expect(await local.readRoutes(olderRequest), isNull);
    expect(
      (await local.readRoutes(newerRequest))?.value.profile,
      RouteProfile.driving,
    );
  });
}
