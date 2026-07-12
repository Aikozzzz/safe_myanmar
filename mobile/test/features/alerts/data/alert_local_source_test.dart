import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/alerts/data/alert_local_source.dart';
import 'package:mobile/features/alerts/domain/earthquake.dart';

import '../../../support/alert_fixtures.dart';

void main() {
  late AppDatabase database;
  late DriftAlertLocalSource source;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    source = DriftAlertLocalSource(database);
  });

  tearDown(() => database.close());

  test('schema version one starts without rows or metadata', () async {
    expect(database.schemaVersion, 1);
    expect(await source.readSnapshot(), isNull);
    expect(await source.getById('usgs:missing'), isNull);
    final count = await database
        .customSelect('SELECT COUNT(*) AS count FROM cached_earthquakes')
        .getSingle();
    expect(count.read<int>('count'), 0);
  });

  test('round-trips every field and exact UTC microseconds', () async {
    final item = earthquakeFixture();
    final snapshot = _snapshot([item]);
    final cachedAt = DateTime.utc(2026, 7, 13, 2, 3, 4, 5, 8);

    await source.replaceSnapshot(snapshot, cachedAt);
    final result = await source.readSnapshot();

    expect(result, isNotNull);
    expect(result!.items.single, item);
    expect(result.dataStatus, AlertDataStatus.current);
    expect(result.lastSuccessfulRefreshAt, snapshot.lastSuccessfulRefreshAt);
    expect(result.cachedAt, cachedAt);
    expect(
      result.items.single.eventAt.microsecondsSinceEpoch,
      item.eventAt.microsecondsSinceEpoch,
    );
    expect(result.cachedAt.isUtc, isTrue);
    expect(() => result.items.add(item), throwsUnsupportedError);
  });

  test(
    'atomically replaces and orders event descending then ID ascending',
    () async {
      final sameTime = DateTime.utc(2026, 7, 13, 3);
      final old = earthquakeFixture(
        id: 'usgs:old',
        providerEventId: 'old',
        eventAt: DateTime.utc(2026, 7, 12),
      );
      await source.replaceSnapshot(_snapshot([old]), DateTime.utc(2026, 7, 13));
      final a = earthquakeFixture(
        id: 'usgs:a',
        providerEventId: 'a',
        eventAt: sameTime,
      );
      final b = earthquakeFixture(
        id: 'usgs:b',
        providerEventId: 'b',
        eventAt: sameTime,
      );

      await source.replaceSnapshot(
        _snapshot([b, a]),
        DateTime.utc(2026, 7, 13, 1),
      );

      expect((await source.readSnapshot())!.items.map((item) => item.id), [
        'usgs:a',
        'usgs:b',
      ]);
      expect(await source.getById('usgs:old'), isNull);
    },
  );

  test(
    'valid empty replacement clears USGS items and keeps metadata',
    () async {
      await source.replaceSnapshot(
        _snapshot([earthquakeFixture()]),
        DateTime.utc(2026, 7, 13),
      );
      final empty = AlertSnapshot(
        items: const [],
        dataStatus: AlertDataStatus.stale,
        lastSuccessfulRefreshAt: DateTime.utc(2026, 7, 13, 4),
      );

      await source.replaceSnapshot(empty, DateTime.utc(2026, 7, 13, 5));

      final result = await source.readSnapshot();
      expect(result, isNotNull);
      expect(result!.items, isEmpty);
      expect(result.dataStatus, AlertDataStatus.stale);
      expect(result.lastSuccessfulRefreshAt, empty.lastSuccessfulRefreshAt);
    },
  );

  test('older and equal updates retain the exact newer cached row', () async {
    final updatedAt = DateTime.utc(2026, 7, 13, 3);
    final current = earthquakeFixture(
      title: 'current',
      providerUpdatedAt: updatedAt,
    );
    await source.replaceSnapshot(
      _snapshot([current]),
      DateTime.utc(2026, 7, 13),
    );

    for (final incoming in <Earthquake>[
      earthquakeFixture(
        title: 'older',
        providerUpdatedAt: updatedAt.subtract(const Duration(microseconds: 1)),
      ),
      earthquakeFixture(title: 'equal', providerUpdatedAt: updatedAt),
    ]) {
      await source.replaceSnapshot(
        _snapshot([incoming]),
        DateTime.utc(2026, 7, 13, 1),
      );
      expect((await source.getById(current.id))!.title, 'current');
    }
  });

  test('rolls back items and metadata when an item operation fails', () async {
    final original = _snapshot([earthquakeFixture()]);
    final originalCachedAt = DateTime.utc(2026, 7, 13);
    await source.replaceSnapshot(original, originalCachedAt);
    final duplicateProviderId = earthquakeFixture(
      id: 'usgs:different-id',
      title: 'conflict',
    );

    await expectLater(
      source.replaceSnapshot(
        _snapshot([earthquakeFixture(), duplicateProviderId]),
        DateTime.utc(2026, 7, 14),
      ),
      throwsA(anything),
    );

    final result = await source.readSnapshot();
    expect(result!.items, [earthquakeFixture()]);
    expect(result.lastSuccessfulRefreshAt, original.lastSuccessfulRefreshAt);
    expect(result.cachedAt, originalCachedAt);
  });

  test('keeps future-provider rows and scopes USGS detail reads', () async {
    await _insertFutureProvider(database);

    await source.replaceSnapshot(
      _snapshot([earthquakeFixture()]),
      DateTime.utc(2026, 7, 13),
    );

    final count = await database
        .customSelect(
          "SELECT COUNT(*) AS count FROM cached_earthquakes WHERE provider = 'future'",
        )
        .getSingle();
    expect(count.read<int>('count'), 1);
    expect(await source.getById('future:event'), isNull);
    expect(await source.getById('usgs:example'), earthquakeFixture());
  });

  test('watch emits null before metadata then emits replacements', () async {
    final emissions = source.watchSnapshot().take(2).toList();
    await Future<void>.delayed(Duration.zero);

    await source.replaceSnapshot(
      _snapshot([earthquakeFixture()]),
      DateTime.utc(2026, 7, 13),
    );

    final values = await emissions;
    expect(values.first, isNull);
    expect(values.last!.items, [earthquakeFixture()]);
  });

  test('rejects a non-UTC cached timestamp', () async {
    await expectLater(
      source.replaceSnapshot(_snapshot(const []), DateTime(2026, 7, 13)),
      throwsArgumentError,
    );
  });

  test('file-backed database survives close and reopen', () async {
    await database.close();
    final directory = await Directory.systemTemp.createTemp(
      'safe-myanmar-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File(
      '${directory.path}${Platform.pathSeparator}alerts.sqlite',
    );
    final firstDatabase = AppDatabase(NativeDatabase(file));
    final firstSource = DriftAlertLocalSource(firstDatabase);
    await firstSource.replaceSnapshot(
      _snapshot([earthquakeFixture()]),
      DateTime.utc(2026, 7, 13),
    );
    await firstDatabase.close();

    final secondDatabase = AppDatabase(NativeDatabase(file));
    addTearDown(secondDatabase.close);
    final result = await DriftAlertLocalSource(secondDatabase).readSnapshot();

    expect(result!.items, [earthquakeFixture()]);
  });
}

AlertSnapshot _snapshot(List<Earthquake> items) => AlertSnapshot(
  items: items,
  dataStatus: AlertDataStatus.current,
  lastSuccessfulRefreshAt: DateTime.utc(2026, 7, 13, 6, 7, 8, 9, 10),
);

Future<void> _insertFutureProvider(AppDatabase database) {
  return database.customStatement(
    '''
      INSERT INTO cached_earthquakes (
        id, provider, provider_event_id, kind, title, place, magnitude,
        depth_km, latitude, longitude, event_at, provider_updated_at,
        retrieved_at, review_status, source_url, version
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      'future:event',
      'future',
      'event',
      'earthquake_information',
      'Future provider event',
      'Myanmar',
      1.0,
      2.0,
      20.0,
      96.0,
      DateTime.utc(2026).microsecondsSinceEpoch,
      DateTime.utc(2026).microsecondsSinceEpoch,
      DateTime.utc(2026).microsecondsSinceEpoch,
      null,
      'https://example.com/event',
      1,
    ],
  );
}
