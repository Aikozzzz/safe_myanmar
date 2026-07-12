import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class CachedEarthquakes extends Table {
  TextColumn get id => text()();
  TextColumn get provider => text()();
  TextColumn get providerEventId => text()();
  TextColumn get kind => text()();
  TextColumn get title => text()();
  TextColumn get place => text()();
  RealColumn get magnitude => real()();
  RealColumn get depthKm => real()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get eventAt => integer()();
  IntColumn get providerUpdatedAt => integer()();
  IntColumn get retrievedAt => integer()();
  TextColumn get reviewStatus => text().nullable()();
  TextColumn get sourceUrl => text()();
  IntColumn get version => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {provider, providerEventId},
  ];
}

class AlertSyncMetadata extends Table {
  TextColumn get provider => text()();
  TextColumn get dataStatus => text().customConstraint(
    "NOT NULL CHECK (data_status IN ('current', 'stale'))",
  )();
  IntColumn get lastSuccessfulRefreshAt => integer()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {provider};
}

@DriftDatabase(tables: [CachedEarthquakes, AlertSyncMetadata])
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.open() : this(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (migrator) => migrator.createAll());
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(path.join(directory.path, 'safe_myanmar.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
