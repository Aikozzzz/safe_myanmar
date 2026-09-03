import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/navigation/data/navigation_dto.dart';
import 'package:mobile/features/navigation/domain/navigation_models.dart';

import '../../../support/navigation_fixtures.dart';

void main() {
  test('strictly parses all navigation response types', () {
    final shelters = ShelterCollectionDto.fromJson(shelterResponseJson());
    final hazards = HazardCollectionDto.fromJson(hazardResponseJson());
    final contextAreas = ContextAreaCollectionDto.fromJson(
      contextAreaResponseJson(
        name: 'Maha Bandula Park',
        source: 'OpenStreetMap via Overpass',
        simulation: false,
        uncertaintyNotice: 'Mapped coverage may be incomplete.',
        rationale: ['Named mapped park polygon', 'Open area comparison'],
      ),
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
    final area = contextAreas.toDomain().items.single;
    expect(area.name, 'Maha Bandula Park');
    expect(area.source, 'OpenStreetMap via Overpass');
    expect(area.simulation, isFalse);
    expect(area.metrics.buildingClearanceM, 120);
    expect(area.metrics.treeClearanceM, 90);
    expect(area.metrics.buildingDensity, 0.1);
    expect(area.metrics.treeDensity, 0.2);
    expect(area.metrics.hazardIntersections, 0);
    expect(area.rationale, [
      'Named mapped park polygon',
      'Open area comparison',
    ]);
  });

  test('preserves explicit simulation metadata for mixed analysis', () {
    final dto = ContextAreaCollectionDto.fromJson(
      contextAreaResponseJson(
        source: 'Yangon snapshot; SafeMyanmar Demo simulation analysis data',
        simulation: true,
      ),
    );

    expect(dto.simulation, isTrue);
    expect(dto.items.single.simulation, isTrue);
    expect(dto.toJson()['simulation'], isTrue);
    expect((dto.toJson()['items']! as List).single['simulation'], isTrue);
  });

  test('parses real route source and simulation metadata', () {
    final dto = RouteSuggestionsDto.fromJson(
      routeResponseJson(
        optionCount: 3,
        source: 'Verified shelter registry',
        directionsProvider: 'Mapbox Directions',
        simulation: false,
        uncertaintyNotice: 'Map and hazard data may be incomplete.',
      ),
    );
    final routes = dto.toDomain();

    expect(routes.simulation, isFalse);
    expect(routes.source, 'Verified shelter registry');
    expect(routes.directionsProvider, 'Mapbox Directions');
    expect(routes.options, hasLength(3));
    expect(routes.options.first.simulation, isFalse);
    expect(routes.options.first.source, 'Verified shelter registry');
    expect(dto.toJson()['simulation'], isFalse);
  });

  test('accepts an empty route result without inventing an alternative', () {
    final dto = RouteSuggestionsDto.fromJson(routeResponseJson(optionCount: 0));

    expect(dto.options, isEmpty);
    expect(dto.toDomain().options, isEmpty);
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
    expect(
      () => ContextAreaCollectionDto.fromJson(
        contextAreaResponseJson(
          candidateNames: ['Area 1', 'Area 2', 'Area 3', 'Area 4'],
        ),
      ),
      throwsA(isA<NavigationProtocolException>()),
    );
  });

  test('rejects inconsistent route option metadata', () {
    final mismatchedSource = routeResponseJson(optionCount: 1);
    ((mismatchedSource['options']! as List).single as Map)['source'] =
        'Other route source';
    final mismatchedProvider = routeResponseJson(optionCount: 1);
    ((mismatchedProvider['options']! as List).single
            as Map)['directions_provider'] =
        'Other directions provider';

    expect(
      () => RouteSuggestionsDto.fromJson(mismatchedSource),
      throwsA(isA<NavigationProtocolException>()),
    );
    expect(
      () => RouteSuggestionsDto.fromJson(mismatchedProvider),
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

  test('navigation payloads stay language-neutral after encode and decode', () {
    final shelters = ShelterCollectionDto.fromJson(shelterResponseJson());
    final hazards = HazardCollectionDto.fromJson(hazardResponseJson());
    final routes = RouteSuggestionsDto.fromJson(
      routeResponseJson(optionCount: 3),
    );

    for (final payload in [
      shelters.toJson(),
      hazards.toJson(),
      routes.toJson(),
    ]) {
      expect(payload.containsKey('language'), isFalse);
      expect(payload.containsKey('locale'), isFalse);
    }
    expect(shelters.toDomain().items.single.name, 'SIMULATION: Test Shelter');
    expect(
      ShelterCollectionDto.fromJson(
        shelters.toJson(),
      ).toDomain().items.single.name,
      shelters.toDomain().items.single.name,
    );
  });
}
