import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/alerts/domain/alert_repository.dart';
import 'package:mobile/features/alerts/domain/earthquake.dart';

void main() {
  group('Earthquake', () {
    test('constructs with exact field values', () {
      final eventAt = DateTime.utc(2026, 7, 13, 1, 2, 3);
      final providerUpdatedAt = DateTime.utc(2026, 7, 13, 1, 3, 4);
      final retrievedAt = DateTime.utc(2026, 7, 13, 1, 4, 5);
      final earthquake = earthquakeFixture(
        eventAt: eventAt,
        providerUpdatedAt: providerUpdatedAt,
        retrievedAt: retrievedAt,
      );

      expect(earthquake.id, 'usgs:example');
      expect(earthquake.provider, 'usgs');
      expect(earthquake.providerEventId, 'example');
      expect(earthquake.kind, 'earthquake_information');
      expect(earthquake.title, 'M 5.2 - Myanmar');
      expect(earthquake.place, 'Myanmar');
      expect(earthquake.magnitude, 5.2);
      expect(earthquake.depthKm, 12.5);
      expect(earthquake.latitude, 20.5);
      expect(earthquake.longitude, 96.25);
      expect(earthquake.eventAt, same(eventAt));
      expect(earthquake.providerUpdatedAt, same(providerUpdatedAt));
      expect(earthquake.retrievedAt, same(retrievedAt));
      expect(earthquake.reviewStatus, 'reviewed');
      expect(earthquake.sourceUrl, 'https://earthquake.usgs.gov/example');
      expect(earthquake.version, 1);
    });

    test('uses value equality and matching hash codes', () {
      final first = earthquakeFixture();
      final second = earthquakeFixture();

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(earthquakeFixture(version: 2)));
    });

    test('supports nullable and populated review status', () {
      expect(earthquakeFixture(reviewStatus: null).reviewStatus, isNull);
      expect(
        earthquakeFixture(reviewStatus: 'reviewed').reviewStatus,
        'reviewed',
      );
    });

    test('accepts UTC values for every timestamp', () {
      expect(
        () => earthquakeFixture(
          eventAt: DateTime.utc(2026),
          providerUpdatedAt: DateTime.utc(2026, 2),
          retrievedAt: DateTime.utc(2026, 3),
        ),
        returnsNormally,
      );
    });

    for (final timestamp in <String, Earthquake Function(DateTime)>{
      'eventAt': (value) => earthquakeFixture(eventAt: value),
      'providerUpdatedAt': (value) =>
          earthquakeFixture(providerUpdatedAt: value),
      'retrievedAt': (value) => earthquakeFixture(retrievedAt: value),
    }.entries) {
      test('rejects non-UTC ${timestamp.key}', () {
        expect(
          () => timestamp.value(DateTime(2026, 7, 13)),
          throwsAssertionError,
        );
      });
    }

    test('rejects invalid identity and source values', () {
      expect(() => earthquakeFixture(id: 'example'), throwsAssertionError);
      expect(() => earthquakeFixture(provider: 'other'), throwsAssertionError);
      expect(() => earthquakeFixture(kind: 'earthquake'), throwsAssertionError);
      expect(
        () => earthquakeFixture(sourceUrl: 'http://example.com'),
        throwsAssertionError,
      );
    });

    test('rejects invalid coordinates and non-finite numbers', () {
      expect(() => earthquakeFixture(latitude: -90.1), throwsAssertionError);
      expect(() => earthquakeFixture(latitude: 90.1), throwsAssertionError);
      expect(() => earthquakeFixture(longitude: -180.1), throwsAssertionError);
      expect(() => earthquakeFixture(longitude: 180.1), throwsAssertionError);
      expect(
        () => earthquakeFixture(magnitude: double.nan),
        throwsAssertionError,
      );
      expect(
        () => earthquakeFixture(depthKm: double.infinity),
        throwsAssertionError,
      );
      expect(
        () => earthquakeFixture(latitude: double.negativeInfinity),
        throwsAssertionError,
      );
      expect(
        () => earthquakeFixture(longitude: double.nan),
        throwsAssertionError,
      );
    });

    test('rejects non-positive versions', () {
      expect(() => earthquakeFixture(version: 0), throwsAssertionError);
      expect(() => earthquakeFixture(version: -1), throwsAssertionError);
    });

    test('does not expose a severity property', () {
      final dynamic earthquake = earthquakeFixture();

      expect(() => earthquake.severity, throwsNoSuchMethodError);
    });
  });

  group('AlertSnapshot', () {
    test('preserves status and requires a UTC refresh timestamp', () {
      final refreshedAt = DateTime.utc(2026, 7, 13);
      final snapshot = AlertSnapshot(
        items: const [],
        dataStatus: AlertDataStatus.stale,
        lastSuccessfulRefreshAt: refreshedAt,
      );

      expect(snapshot.dataStatus, AlertDataStatus.stale);
      expect(snapshot.lastSuccessfulRefreshAt, same(refreshedAt));
      expect(
        () => AlertSnapshot(
          items: const [],
          dataStatus: AlertDataStatus.current,
          lastSuccessfulRefreshAt: DateTime(2026, 7, 13),
        ),
        throwsAssertionError,
      );
    });

    test('defensively freezes its item list', () {
      final original = <Earthquake>[earthquakeFixture()];
      final snapshot = AlertSnapshot(
        items: original,
        dataStatus: AlertDataStatus.current,
        lastSuccessfulRefreshAt: DateTime.utc(2026, 7, 13),
      );

      original.clear();

      expect(snapshot.items, hasLength(1));
      expect(
        () => snapshot.items.add(earthquakeFixture(version: 2)),
        throwsUnsupportedError,
      );
    });
  });

  test('repository fake implements the exact contract', () async {
    final repository = FakeAlertRepository();

    expect(await repository.watchCached().first, isEmpty);
    expect((await repository.refresh()).dataStatus, AlertDataStatus.current);
    expect(await repository.getById('usgs:missing'), isNull);
  });
}

Earthquake earthquakeFixture({
  String id = 'usgs:example',
  String provider = 'usgs',
  String kind = 'earthquake_information',
  double magnitude = 5.2,
  double depthKm = 12.5,
  double latitude = 20.5,
  double longitude = 96.25,
  DateTime? eventAt,
  DateTime? providerUpdatedAt,
  DateTime? retrievedAt,
  String? reviewStatus = 'reviewed',
  String sourceUrl = 'https://earthquake.usgs.gov/example',
  int version = 1,
}) {
  return Earthquake(
    id: id,
    provider: provider,
    providerEventId: 'example',
    kind: kind,
    title: 'M 5.2 - Myanmar',
    place: 'Myanmar',
    magnitude: magnitude,
    depthKm: depthKm,
    latitude: latitude,
    longitude: longitude,
    eventAt: eventAt ?? DateTime.utc(2026, 7, 13, 1, 2, 3),
    providerUpdatedAt: providerUpdatedAt ?? DateTime.utc(2026, 7, 13, 1, 3, 4),
    retrievedAt: retrievedAt ?? DateTime.utc(2026, 7, 13, 1, 4, 5),
    reviewStatus: reviewStatus,
    sourceUrl: sourceUrl,
    version: version,
  );
}

final class FakeAlertRepository implements AlertRepository {
  @override
  Future<Earthquake?> getById(String id) async => null;

  @override
  Future<AlertSnapshot> refresh() async => AlertSnapshot(
    items: const [],
    dataStatus: AlertDataStatus.current,
    lastSuccessfulRefreshAt: DateTime.utc(2026, 7, 13),
  );

  @override
  Stream<List<Earthquake>> watchCached() => Stream.value(const []);
}
