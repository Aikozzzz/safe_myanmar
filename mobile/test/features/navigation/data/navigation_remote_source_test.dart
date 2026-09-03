import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/network/api_config.dart';
import 'package:mobile/features/navigation/data/navigation_dto.dart';
import 'package:mobile/features/navigation/data/navigation_remote_source.dart';
import 'package:mobile/features/navigation/domain/navigation_models.dart';

import '../../../support/navigation_fixtures.dart';

void main() {
  final config = ApiConfig.fromRaw(
    'https://api.example.test',
    isProduction: true,
  );

  test(
    'uses contract URI and sends the explicit selected destination',
    () async {
      late http.Request captured;
      final source = NavigationRemoteSource(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode(routeResponseJson(profile: 'driving')),
            200,
          );
        }),
        config: config,
      );

      await source.fetchRouteSuggestions(
        const RouteSuggestionRequest(
          origin: NavigationCoordinate(latitude: 21.95, longitude: 96.08),
          shelterId: 'legacy-shelter',
          contextAreaId: 'mapped-context-area',
          disasterType: DisasterType.flood,
          profile: RouteProfile.driving,
        ),
      );

      expect(captured.url, config.routeSuggestionsUri);
      expect(captured.method, 'POST');
      final body = jsonDecode(captured.body) as Map<String, Object?>;
      expect(body, containsPair('profile', 'driving'));
      expect(body, containsPair('disaster_type', 'flood'));
      expect(body, containsPair('shelter_id', 'legacy-shelter'));
      expect(body, containsPair('context_area_id', 'mapped-context-area'));
    },
  );

  test('rejects a route response for a different requested profile', () async {
    final source = NavigationRemoteSource(
      client: MockClient(
        (_) async => http.Response(jsonEncode(routeResponseJson()), 200),
      ),
      config: config,
    );

    await expectLater(
      source.fetchRouteSuggestions(
        const RouteSuggestionRequest(
          origin: NavigationCoordinate(latitude: 21.95, longitude: 96.08),
          shelterId: 'simulation-shelter-1',
          disasterType: DisasterType.earthquake,
          profile: RouteProfile.driving,
        ),
      ),
      throwsA(isA<NavigationProtocolException>()),
    );
  });

  test(
    'uses the SOS coordinate route endpoint and sends both coordinates',
    () async {
      late http.Request captured;
      final source = NavigationRemoteSource(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode(routeResponseJson(profile: 'walking')),
            200,
          );
        }),
        config: config,
      );

      await source.fetchSosRouteSuggestions(
        const SosRouteRequest(
          eventId: '1122334455667788',
          origin: NavigationCoordinate(latitude: 21.95, longitude: 96.08),
          destination: NavigationCoordinate(
            latitude: 21.958,
            longitude: 96.091,
          ),
          profile: RouteProfile.walking,
        ),
      );

      expect(captured.url, config.sosRouteUri);
      expect(captured.method, 'POST');
      final body = jsonDecode(captured.body) as Map<String, Object?>;
      expect(body, containsPair('profile', 'walking'));
      expect(body['origin'], {'latitude': 21.95, 'longitude': 96.08});
      expect(body['destination'], {'latitude': 21.958, 'longitude': 96.091});
    },
  );

  test('maps 503 and transport failures to unavailable', () async {
    final unavailable = NavigationRemoteSource(
      client: MockClient((_) async => http.Response('{}', 503)),
      config: config,
    );
    final transport = NavigationRemoteSource(
      client: MockClient((_) async => throw http.ClientException('offline')),
      config: config,
    );

    await expectLater(
      unavailable.fetchShelters(),
      throwsA(isA<NavigationRemoteUnavailable>()),
    );
    await expectLater(
      transport.fetchHazards(),
      throwsA(isA<NavigationRemoteUnavailable>()),
    );
  });

  test(
    'preserves HTTP status and rejects malformed success payloads',
    () async {
      final failure = NavigationRemoteSource(
        client: MockClient((_) async => http.Response('{}', 404)),
        config: config,
      );
      final malformed = NavigationRemoteSource(
        client: MockClient((_) async => http.Response('[]', 200)),
        config: config,
      );

      await expectLater(
        failure.fetchShelters(),
        throwsA(
          isA<NavigationRemoteException>().having(
            (error) => error.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
      await expectLater(
        malformed.fetchHazards(),
        throwsA(isA<NavigationProtocolException>()),
      );
    },
  );
}
