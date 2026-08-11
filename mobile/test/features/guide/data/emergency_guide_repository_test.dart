import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/guide/data/drift_emergency_guide_repository.dart';

void main() {
  test(
    'v2 to v5 preserves alert and navigation cache data and seeds',
    () async {
      final directory = await Directory.systemTemp.createTemp('guide-v2-v3-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}${Platform.pathSeparator}v2.sqlite');
      final database = AppDatabase(
        NativeDatabase(
          file,
          setup: (raw) {
            raw.execute(_v2AlertTable);
            raw.execute(_v2MetadataTable);
            raw.execute(_v2ShelterTable);
            raw.execute(_v2HazardTable);
            raw.execute(_v2RouteTable);
            raw.execute(_alertInsert);
            raw.execute(_shelterInsert);
            raw.execute('PRAGMA user_version = 2');
          },
        ),
      );
      addTearDown(database.close);

      final alert = await database
          .customSelect(
            "SELECT title FROM cached_earthquakes WHERE id = 'usgs:kept'",
          )
          .getSingle();
      final shelter = await database
          .customSelect(
            'SELECT payload FROM cached_shelter_responses WHERE id = 1',
          )
          .getSingle();
      final articles = await DriftEmergencyGuideRepository(database).search();

      expect(database.schemaVersion, 5);
      expect(alert.read<String>('title'), 'Preserved alert');
      expect(shelter.read<String>('payload'), '{"kept":true}');
      expect(articles, hasLength(5));
    },
  );

  test(
    'seeds fixed versions, dates, exact sources, and bilingual retrieval',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = DriftEmergencyGuideRepository(database);

      final articles = await repository.search();
      final earthquake = await repository.getById('earthquake-drop-cover-hold');
      final burmese = await repository.search(query: 'ငလျင်');
      final firstAid = await repository.getById('first-aid-assessment');

      expect(articles, hasLength(5));
      expect(articles.every((article) => article.contentVersion == 1), isTrue);
      expect(earthquake!.sourceName, 'Ready.gov');
      expect(earthquake.sourceUrl, 'https://www.ready.gov/earthquakes');
      expect(earthquake.sourceUpdatedAt, DateTime.utc(2026, 4, 29));
      expect(earthquake.reviewedAt, DateTime.utc(2026, 7, 23));
      expect(earthquake.titleMy, isNotEmpty);
      expect(burmese.map((article) => article.id), contains(earthquake.id));
      expect(firstAid!.sourceName, 'American Red Cross');
      expect(firstAid.sourceUpdatedAt, isNull);
    },
  );
}

const _v2AlertTable = '''
CREATE TABLE cached_earthquakes (
 id TEXT NOT NULL PRIMARY KEY, provider TEXT NOT NULL,
 provider_event_id TEXT NOT NULL, kind TEXT NOT NULL, title TEXT NOT NULL,
 place TEXT NOT NULL, magnitude REAL NOT NULL, depth_km REAL NOT NULL,
 latitude REAL NOT NULL, longitude REAL NOT NULL, event_at INTEGER NOT NULL,
 provider_updated_at INTEGER NOT NULL, retrieved_at INTEGER NOT NULL,
 review_status TEXT NULL, source_url TEXT NOT NULL, version INTEGER NOT NULL,
 UNIQUE(provider, provider_event_id))
''';
const _v2MetadataTable = '''
CREATE TABLE alert_sync_metadata (
 provider TEXT NOT NULL PRIMARY KEY, data_status TEXT NOT NULL,
 last_successful_refresh_at INTEGER NOT NULL, cached_at INTEGER NOT NULL)
''';
const _v2ShelterTable = '''
CREATE TABLE cached_shelter_responses (
 id INTEGER NOT NULL DEFAULT 1 PRIMARY KEY, payload TEXT NOT NULL,
 data_at INTEGER NOT NULL, cached_at INTEGER NOT NULL)
''';
const _v2HazardTable = '''
CREATE TABLE cached_hazard_responses (
 id INTEGER NOT NULL DEFAULT 1 PRIMARY KEY, payload TEXT NOT NULL,
 data_at INTEGER NOT NULL, cached_at INTEGER NOT NULL)
''';
const _v2RouteTable = '''
CREATE TABLE cached_route_responses (
 id INTEGER NOT NULL DEFAULT 1 PRIMARY KEY, payload TEXT NOT NULL,
 generated_at INTEGER NOT NULL, cached_at INTEGER NOT NULL)
''';
const _alertInsert = '''
INSERT INTO cached_earthquakes VALUES (
 'usgs:kept', 'usgs', 'kept', 'earthquake_information', 'Preserved alert',
 'Myanmar', 4.0, 10.0, 20.0, 96.0, 1, 1, 1, NULL,
 'https://earthquake.usgs.gov/earthquakes/eventpage/kept', 1)
''';
const _shelterInsert = '''
INSERT INTO cached_shelter_responses VALUES (1, '{"kept":true}', 1, 1)
''';
