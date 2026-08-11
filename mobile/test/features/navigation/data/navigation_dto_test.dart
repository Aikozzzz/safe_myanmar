import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/navigation/data/navigation_dto.dart';
import 'package:mobile/features/navigation/domain/navigation_models.dart';

import '../../../support/navigation_fixtures.dart';

void main() {
  test('strictly parses all navigation response types', () {
    final shelters = ShelterCollectionDto.fromJson(shelterResponseJson());
    final hazards = HazardCollectionDto.fromJson(hazardResponseJson());
    final contextAreas = ContextAreaCollectionDto.fromJson(
      contextAreaResponseJson(),
    );
    final routes = RouteSuggestionsDto.fromJson(
      routeResponseJson(optionCount: 3),
    );

    expect(shelters.toDomain().items.single.id, 'simulation-shelter-1');
    expect(
      hazards.toDomain().items.single.disasterType,
      DisasterType.earthquake,
    );
    expect(routes.toDomain().options, hasLength(3));
    expect(routes.toDomain().options.first.recommended, isTrue);
    expect(
      contextAreas.toDomain().items.single.scenario,
      ContextScenario.outdoorsAfterShaking,
    );
  });

  test('rejects extra fields and false simulation markers', () {
    final extra = shelterResponseJson()..['unexpected'] = true;
    final notSimulation = hazardResponseJson()..['simulation'] = false;

    expect(
      () => ShelterCollectionDto.fromJson(extra),
      throwsA(isA<NavigationProtocolException>()),
    );
    expect(
      () => HazardCollectionDto.fromJson(notSimulation),
      throwsA(isA<NavigationProtocolException>()),
    );
  });

  test('rejects wrong coordinate types, bounds, geometry, and route count', () {
    final integerCoordinate = shelterResponseJson();
    (integerCoordinate['items']! as List).cast<Map>().single['coordinate'] = {
      'latitude': 21,
      'longitude': 96.091,
    };
    final invalidBounds = hazardResponseJson();
    final hazard = (invalidBounds['items']! as List).cast<Map>().single;
    ((hazard['geometry'] as Map)['coordinates'] as List).first = [
      [181.0, 21.95],
    ];

    expect(
      () => ShelterCollectionDto.fromJson(integerCoordinate),
      throwsA(isA<NavigationProtocolException>()),
    );
    expect(
      () => HazardCollectionDto.fromJson(invalidBounds),
      throwsA(isA<NavigationProtocolException>()),
    );
    expect(
      () => RouteSuggestionsDto.fromJson(routeResponseJson(optionCount: 4)),
      throwsA(isA<NavigationProtocolException>()),
    );
  });

  test('rejects open polygons and inconsistent route envelope metadata', () {
    final openPolygon = hazardResponseJson();
    final ring =
        ((((openPolygon['items']! as List).single as Map)["geometry"]
                        as Map)['coordinates']
                    as List)
                .single
            as List;
    ring.removeLast();
    final inconsistentProfile = routeResponseJson(optionCount: 1);
    inconsistentProfile['profile'] = 'driving';
    final missingRecommendation = routeResponseJson(optionCount: 1);
    ((missingRecommendation['options']! as List).single as Map)['recommended'] =
        false;

    expect(
      () => HazardCollectionDto.fromJson(openPolygon),
      throwsA(isA<NavigationProtocolException>()),
    );
    expect(
      () => RouteSuggestionsDto.fromJson(inconsistentProfile),
      throwsA(isA<NavigationProtocolException>()),
    );
    expect(
      () => RouteSuggestionsDto.fromJson(missingRecommendation),
      throwsA(isA<NavigationProtocolException>()),
    );
  });
}
