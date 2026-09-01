import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/alerts/data/alert_dto.dart';
import 'package:mobile/features/alerts/domain/earthquake.dart';

import '../../../support/alert_fixtures.dart';

void main() {
  group('AlertEnvelopeDto', () {
    test('decodes a populated envelope and maps every item field', () {
      final dto = AlertEnvelopeDto.fromJson(validEnvelopeJson());
      final item = dto.items.single;
      final domain = item.toDomain();

      expect(dto.dataStatus, AlertDataStatus.current);
      expect(
        dto.lastSuccessfulRefreshAt,
        DateTime.utc(2026, 7, 13, 1, 5, 6, 0, 7),
      );
      expect(dto.provider, 'usgs');
      expect(domain.id, 'usgs:example');
      expect(domain.provider, 'usgs');
      expect(domain.providerEventId, 'example');
      expect(domain.kind, 'earthquake_information');
      expect(domain.title, 'M 5.2 - Myanmar');
      expect(domain.place, 'Myanmar');
      expect(domain.magnitude, 5.2);
      expect(domain.depthKm, 12.5);
      expect(domain.latitude, 20.5);
      expect(domain.longitude, 96.25);
      expect(domain.eventAt, DateTime.utc(2026, 7, 13, 1, 2, 3, 0, 4));
      expect(
        domain.providerUpdatedAt,
        DateTime.utc(2026, 7, 13, 1, 3, 4, 0, 5),
      );
      expect(domain.retrievedAt, DateTime.utc(2026, 7, 13, 1, 4, 5, 0, 6));
      expect(domain.reviewStatus, 'reviewed');
      expect(domain.sourceUrl, 'https://earthquake.usgs.gov/example');
      expect(domain.version, 1);
      expect(domain.eventAt.isUtc, isTrue);
    });

    test('decodes empty stale envelope and nullable review status', () {
      final empty = AlertEnvelopeDto.fromJson(
        validEnvelopeJson(items: const [], dataStatus: 'stale'),
      );
      final itemJson = validAlertJson()..['review_status'] = null;

      expect(empty.items, isEmpty);
      expect(empty.dataStatus, AlertDataStatus.stale);
      expect(AlertDto.fromJson(itemJson).reviewStatus, isNull);
    });

    for (final key in <String>{
      'items',
      'data_status',
      'last_successful_refresh_at',
      'provider',
    }) {
      test('rejects envelope missing $key', () {
        expect(
          () => AlertEnvelopeDto.fromJson(validEnvelopeJson()..remove(key)),
          throwsA(isA<AlertProtocolException>()),
        );
      });
    }

    test('rejects extra envelope keys', () {
      expect(
        () => AlertEnvelopeDto.fromJson(validEnvelopeJson()..['extra'] = true),
        throwsA(isA<AlertProtocolException>()),
      );
    });
  });

  group('AlertDto strict validation', () {
    final requiredKeys = validAlertJson().keys.toList();
    for (final key in requiredKeys) {
      test('rejects item missing $key', () {
        expect(
          () => AlertDto.fromJson(validAlertJson()..remove(key)),
          throwsA(isA<AlertProtocolException>()),
        );
      });
    }

    test('rejects extra item keys and exposes no severity', () {
      expect(
        () => AlertDto.fromJson(validAlertJson()..['severity'] = 'high'),
        throwsA(isA<AlertProtocolException>()),
      );
      final dynamic dto = AlertDto.fromJson(validAlertJson());
      expect(() => dto.severity, throwsNoSuchMethodError);
    });

    final invalidValues = <String, Object?>{
      'provider': 'other',
      'kind': 'other',
      'id': 'usgs:wrong',
      'magnitude': double.nan,
      'depth_km': double.infinity,
      'latitude': 90.1,
      'longitude': -180.1,
      'version': 0,
      'title': '',
      'place': '  ',
      'provider_event_id': '',
      'review_status': '',
      'source_url': 'http://earthquake.usgs.gov/example',
      'event_at': '2026-07-13T01:02:03+00:00',
      'provider_updated_at': 'not-a-dateZ',
      'retrieved_at': '2026-07-13T01:02:03',
    };
    for (final entry in invalidValues.entries) {
      test('rejects invalid ${entry.key}', () {
        expect(
          () => AlertDto.fromJson(validAlertJson()..[entry.key] = entry.value),
          throwsA(isA<AlertProtocolException>()),
        );
      });
    }

    test('rejects non-integer version and unsafe USGS lookalike host', () {
      for (final value in <Object?>[
        1.0,
        '1',
        'https://earthquake.usgs.gov.example.com/event',
      ]) {
        final json = validAlertJson();
        if (value is String && value.startsWith('https')) {
          json['source_url'] = value;
        } else {
          json['version'] = value;
        }
        expect(
          () => AlertDto.fromJson(json),
          throwsA(isA<AlertProtocolException>()),
        );
      }
    });

    test(
      'accepts a trusted USGS subdomain and numeric integers as doubles',
      () {
        final json = validAlertJson()
          ..['source_url'] = 'https://events.earthquake.usgs.gov/event'
          ..['magnitude'] = 5
          ..['depth_km'] = 12;

        expect(AlertDto.fromJson(json).magnitude, 5.0);
      },
    );

    test('rejects malformed root field types and envelope values', () {
      expect(
        () => AlertEnvelopeDto.fromJson(validEnvelopeJson()..['items'] = 'bad'),
        throwsA(isA<AlertProtocolException>()),
      );
      for (final mutation in <void Function(Map<String, Object?>)>[
        (json) => json['provider'] = 'other',
        (json) => json['data_status'] = 'unknown',
        (json) => json['last_successful_refresh_at'] = null,
      ]) {
        final json = validEnvelopeJson();
        mutation(json);
        expect(
          () => AlertEnvelopeDto.fromJson(json),
          throwsA(isA<AlertProtocolException>()),
        );
      }
    });
  });

  test('alert payloads stay language-neutral after parse', () {
    final json = validEnvelopeJson();
    final envelope = AlertEnvelopeDto.fromJson(json);
    final domain = envelope.items.single.toDomain();

    expect(json.containsKey('language'), isFalse);
    expect(json.containsKey('locale'), isFalse);
    expect(
      ((json['items']! as List).single as Map).containsKey('language'),
      isFalse,
    );
    expect(domain.title, 'M 5.2 - Myanmar');
    expect(domain.place, 'Myanmar');
    expect(
      AlertEnvelopeDto.fromJson(Map<String, Object?>.from(json))
          .items
          .single
          .toDomain()
          .title,
      domain.title,
    );
  });
}
