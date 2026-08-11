import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/alerts/data/alert_local_source.dart';
import 'package:mobile/features/navigation/data/navigation_dto.dart';
import 'package:mobile/features/navigation/data/navigation_local_source.dart';
import 'package:mobile/features/navigation/domain/navigation_models.dart';

import '../../../support/navigation_fixtures.dart';

void main() {
  test(
    'v1 to v2 migration preserves alerts and creates navigation caches',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'safe-myanmar-navigation-migration-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}${Platform.pathSeparator}v1.sqlite');
      final database = AppDatabase(
        NativeDatabase(
          file,
          setup: (raw) {
            raw.execute(_v1EarthquakesSql);
            raw.execute(_v1MetadataSql);
            raw.execute(_v1AlertInsertSql);
            raw.execute(_v1MetadataInsertSql);
            raw.execute('PRAGMA user_version = 1');
          },
        ),
      );
      addTearDown(database.close);

      final alert = await DriftAlertLocalSource(
        database,
      ).getById('usgs:preserved');
      final navigation = DriftNavigationLocalSource(database);

      expect(alert?.title, 'Preserved v1 alert');
      expect(await navigation.readShelters(), isNull);
      expect(await navigation.readHazards(), isNull);
      expect(await navigation.readRoutes(routeRequest), isNull);
      expect(database.schemaVersion, 5);
    },
  );

  test('keeps only the latest envelope for each navigation resource', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final source = DriftNavigationLocalSource(database);
    final firstAt = DateTime.utc(2026, 7, 23, 1);
    final latestAt = DateTime.utc(2026, 7, 23, 2);
    final firstShelters = ShelterCollectionDto.fromJson(shelterResponseJson());
    final latestShelterJson = shelterResponseJson();
    ((latestShelterJson['items']! as List).single as Map)['name'] =
        'SIMULATION: Latest Shelter';
    final latestShelters = ShelterCollectionDto.fromJson(latestShelterJson);

    await source.replaceShelters(firstShelters, firstAt);
    await source.replaceShelters(latestShelters, latestAt);
    await source.replaceHazards(
      HazardCollectionDto.fromJson(hazardResponseJson()),
      latestAt,
    );
    await source.replaceRoutes(
      RouteSuggestionsDto.fromJson(routeResponseJson(optionCount: 3)),
      routeRequest,
      latestAt,
    );

    expect(
      (await source.readShelters())?.value.toDomain().items.single.name,
      'SIMULATION: Latest Shelter',
    );
    expect((await source.readShelters())?.cachedAt, latestAt);
    expect((await source.readHazards())?.value.toDomain().items, hasLength(1));
    expect(
      (await source.readRoutes(routeRequest))?.value.toDomain().options,
      hasLength(3),
    );
    expect(
      await source.readRoutes(
        RouteSuggestionRequest(
          origin: const NavigationCoordinate(
            latitude: 21.95002,
            longitude: 96.08,
          ),
          shelterId: routeRequest.shelterId,
          disasterType: routeRequest.disasterType,
          profile: routeRequest.profile,
        ),
      ),
      isNull,
      reason: 'a materially different origin must not reuse a cached route',
    );
    for (final table in [
      'cached_shelter_responses',
      'cached_hazard_responses',
    ]) {
      final row = await database
          .customSelect('SELECT COUNT(*) AS count FROM $table')
          .getSingle();
      expect(row.read<int>('count'), 1, reason: table);
    }
    final routeCount = await database
        .customSelect('SELECT COUNT(*) AS count FROM cached_route_responses')
        .getSingle();
    expect(
      routeCount.read<int>('count'),
      1,
      reason: 'a mismatched request must not delete another request cache',
    );
    final locationTables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE '%location%'",
        )
        .get();
    expect(locationTables, isEmpty);
  });

  test(
    'v3 to v4 migration preserves old route payload but ignores it',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'safe-myanmar-route-v4-migration-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}${Platform.pathSeparator}v3.sqlite');
      final database = AppDatabase(
        NativeDatabase(
          file,
          setup: (raw) {
            raw.execute(_v3RoutesSql);
            raw.execute(
              'INSERT INTO cached_route_responses VALUES '
              "(1, '{\"preserved\":true}', 1784808000000000, 1784808000000000)",
            );
            raw.execute('PRAGMA user_version = 3');
          },
        ),
      );
      addTearDown(database.close);

      final preserved = await database
          .customSelect(
            'SELECT payload, origin_latitude_e5 FROM cached_route_responses',
          )
          .getSingle();

      expect(preserved.read<String>('payload'), '{"preserved":true}');
      expect(preserved.readNullable<int>('origin_latitude_e5'), isNull);
      expect(
        await DriftNavigationLocalSource(database).readRoutes(routeRequest),
        isNull,
      );
      final routeCount = await database
          .customSelect('SELECT COUNT(*) AS count FROM cached_route_responses')
          .getSingle();
      expect(routeCount.read<int>('count'), 0);
    },
  );

  test(
    'every route request field is cache-bound without deleting other context',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final source = DriftNavigationLocalSource(database);
      final routes = RouteSuggestionsDto.fromJson(routeResponseJson());
      final mismatches = [
        const RouteSuggestionRequest(
          origin: NavigationCoordinate(latitude: 21.95002, longitude: 96.08),
          shelterId: 'simulation-shelter-1',
          disasterType: DisasterType.earthquake,
          profile: RouteProfile.walking,
        ),
        const RouteSuggestionRequest(
          origin: NavigationCoordinate(latitude: 21.95, longitude: 96.08002),
          shelterId: 'simulation-shelter-1',
          disasterType: DisasterType.earthquake,
          profile: RouteProfile.walking,
        ),
        const RouteSuggestionRequest(
          origin: NavigationCoordinate(latitude: 21.95, longitude: 96.08),
          shelterId: 'simulation-shelter-2',
          disasterType: DisasterType.earthquake,
          profile: RouteProfile.walking,
        ),
        const RouteSuggestionRequest(
          origin: NavigationCoordinate(latitude: 21.95, longitude: 96.08),
          shelterId: 'simulation-shelter-1',
          disasterType: DisasterType.flood,
          profile: RouteProfile.walking,
        ),
        const RouteSuggestionRequest(
          origin: NavigationCoordinate(latitude: 21.95, longitude: 96.08),
          shelterId: 'simulation-shelter-1',
          disasterType: DisasterType.earthquake,
          profile: RouteProfile.driving,
        ),
      ];

      for (final mismatch in mismatches) {
        await source.replaceRoutes(
          routes,
          routeRequest,
          DateTime.utc(2026, 7, 23, 2),
        );

        expect(
          await source.readRoutes(mismatch),
          isNull,
          reason: mismatch.toString(),
        );
        final count = await database
            .customSelect(
              'SELECT COUNT(*) AS count FROM cached_route_responses',
            )
            .getSingle();
        expect(count.read<int>('count'), 1, reason: mismatch.toString());
      }
    },
  );
}

const routeRequest = RouteSuggestionRequest(
  origin: NavigationCoordinate(latitude: 21.95, longitude: 96.08),
  shelterId: 'simulation-shelter-1',
  disasterType: DisasterType.earthquake,
  profile: RouteProfile.walking,
);

const _v3RoutesSql = '''
CREATE TABLE cached_route_responses (
  id INTEGER NOT NULL DEFAULT 1 PRIMARY KEY,
  payload TEXT NOT NULL,
  generated_at INTEGER NOT NULL,
  cached_at INTEGER NOT NULL
)
''';

const _v1EarthquakesSql = '''
CREATE TABLE cached_earthquakes (
  id TEXT NOT NULL PRIMARY KEY,
  provider TEXT NOT NULL,
  provider_event_id TEXT NOT NULL,
  kind TEXT NOT NULL,
  title TEXT NOT NULL,
  place TEXT NOT NULL,
  magnitude REAL NOT NULL,
  depth_km REAL NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  event_at INTEGER NOT NULL,
  provider_updated_at INTEGER NOT NULL,
  retrieved_at INTEGER NOT NULL,
  review_status TEXT NULL,
  source_url TEXT NOT NULL,
  version INTEGER NOT NULL,
  UNIQUE(provider, provider_event_id)
)
''';

const _v1MetadataSql = '''
CREATE TABLE alert_sync_metadata (
  provider TEXT NOT NULL PRIMARY KEY,
  data_status TEXT NOT NULL,
  last_successful_refresh_at INTEGER NOT NULL,
  cached_at INTEGER NOT NULL
)
''';

const _v1AlertInsertSql = '''
INSERT INTO cached_earthquakes VALUES (
  'usgs:preserved', 'usgs', 'preserved', 'earthquake_information',
  'Preserved v1 alert', 'Myanmar', 4.0, 10.0, 20.0, 96.0,
  1784764800000000, 1784764800000000, 1784764800000000,
  NULL, 'https://earthquake.usgs.gov/earthquakes/eventpage/preserved', 1
)
''';

const _v1MetadataInsertSql = '''
INSERT INTO alert_sync_metadata VALUES (
  'usgs', 'current', 1784764800000000, 1784764800000000
)
''';
