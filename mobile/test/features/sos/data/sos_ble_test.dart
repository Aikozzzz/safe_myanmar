import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/location/domain/foreground_location.dart';
import 'package:mobile/features/sos/domain/sos_ble.dart';
import 'package:mobile/features/sos/domain/sos_draft.dart';

void main() {
  const codec = SosBlePayloadCodec();

  test('encodes a compact approximate current-location payload', () {
    final event = SosBleEvent(
      eventId: '0011223344556677',
      createdAt: DateTime.utc(2026, 7, 23, 1, 2),
      locationStatus: SosBleLocationStatus.current,
      batteryPercent: 73,
      latitude: 21.951,
      longitude: 96.081,
    );

    final bytes = codec.encode(event);
    final decoded = codec.decode(bytes);

    expect(bytes, hasLength(22));
    expect(decoded.eventId, event.eventId);
    expect(decoded.createdAt, event.createdAt);
    expect(decoded.locationStatus, SosBleLocationStatus.current);
    expect(decoded.batteryPercent, 73);
    expect(decoded.latitude, closeTo(21.95, 0.005));
    expect(decoded.longitude, closeTo(96.08, 0.005));
  });

  test('preserves unavailable location and unknown battery', () {
    final event = SosBleEvent.fromDraft(
      draftId: '00112233-4455-6677-8899-aabbccddeeff',
      createdAt: DateTime.utc(2026, 7, 23),
      location: null,
      batteryPercent: null,
    );

    final decoded = codec.decode(codec.encode(event));

    expect(decoded.locationStatus, SosBleLocationStatus.unavailable);
    expect(decoded.hasLocation, isFalse);
    expect(decoded.batteryPercent, isNull);
  });

  test('last-known status is encoded without exact coordinates', () {
    final event = SosBleEvent.fromDraft(
      draftId: '00112233-4455-6677-8899-aabbccddeeff',
      createdAt: DateTime.utc(2026, 7, 23),
      location: SosLocationSnapshot(
        latitude: 21.951,
        longitude: 96.081,
        timestamp: DateTime.utc(2026, 7, 23),
        precision: LocationPrecision.approximate,
        isLastKnown: true,
      ),
      batteryPercent: 0,
    );

    final decoded = codec.decode(codec.encode(event));

    expect(decoded.locationStatus, SosBleLocationStatus.lastKnown);
    expect(decoded.batteryPercent, 0);
    expect(decoded.latitude, closeTo(21.95, 0.005));
  });

  test('rejects a changed payload checksum and unsupported version', () {
    final event = SosBleEvent(
      eventId: '0011223344556677',
      createdAt: DateTime.utc(2026, 7, 23),
      locationStatus: SosBleLocationStatus.unavailable,
      batteryPercent: 50,
    );
    final payload = codec.encode(event);

    final changed = Uint8List.fromList(payload)..[5] ^= 1;
    expect(() => codec.decode(changed), throwsFormatException);

    final unsupported = Uint8List.fromList(payload)..[1] = 2;
    expect(() => codec.decode(unsupported), throwsFormatException);
  });
}
