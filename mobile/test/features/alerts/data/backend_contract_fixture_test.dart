import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/alerts/data/alert_dto.dart';
import 'package:mobile/features/alerts/domain/earthquake.dart';

void main() {
  test('mobile DTO accepts the normalized backend integration response', () {
    final decoded = jsonDecode(
      File('test/fixtures/live_alerts_response.json').readAsStringSync(),
    );
    final dto = AlertEnvelopeDto.fromJson(
      (decoded as Map).cast<String, Object?>(),
    );
    final item = dto.items.single;

    expect(dto.provider, 'usgs');
    expect(dto.dataStatus, AlertDataStatus.current);
    expect(item.id, 'usgs:integration-fixture-001');
    expect(item.providerEventId, 'integration-fixture-001');
    expect(item.place, contains('integration-fixture-001'));
    expect(item.reviewStatus, 'reviewed');
    expect(item.toDomain().eventAt.isUtc, isTrue);
  });
}
