import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/location/domain/foreground_location.dart';
import 'package:mobile/features/sos/domain/sos_ble.dart';
import 'package:mobile/features/sos/domain/sos_draft.dart';

void main() {
  const codec = SosBlePayloadCodec();

  test('verified details require both alias and location', () {
    final complete = SosBleEvent(
      eventId: '0011223344556677',
      createdAt: DateTime.utc(2026, 7, 23, 1, 2),
      locationStatus: SosBleLocationStatus.current,
      batteryPercent: 73,
      latitude: 21.951,
      longitude: 96.081,
      alias: 'Aung',
    );
    final noAlias = SosBleEvent(
      eventId: complete.eventId,
      createdAt: complete.createdAt,
      locationStatus: complete.locationStatus,
      batteryPercent: complete.batteryPercent,
      latitude: complete.latitude,
      longitude: complete.longitude,
    );
    final noLocation = SosBleEvent(
      eventId: complete.eventId,
      createdAt: complete.createdAt,
      locationStatus: SosBleLocationStatus.unavailable,
      batteryPercent: complete.batteryPercent,
      alias: complete.alias,
    );

    expect(complete.hasVerifiedDetails, isTrue);
    expect(noAlias.hasVerifiedDetails, isFalse);
    expect(noLocation.hasVerifiedDetails, isFalse);
  });

  test('encodes exact current coordinates in a compact payload', () {
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

    expect(bytes, hasLength(26));
    expect(decoded.eventId, event.eventId);
    expect(decoded.createdAt, event.createdAt);
    expect(decoded.locationStatus, SosBleLocationStatus.current);
    expect(decoded.batteryPercent, 73);
    expect(decoded.latitude, 21.951);
    expect(decoded.longitude, 96.081);
    expect(decoded.protocolVersion, sosBleProtocolVersion);
    expect(decoded.ttlMinutes, sosBleTtlMinutes);
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

  test('last-known status preserves exact coordinates', () {
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
    expect(decoded.latitude, 21.951);
    expect(decoded.longitude, 96.081);
  });

  test('supports an older approximate v2 frame', () {
    final event = SosBleEvent(
      eventId: '0011223344556677',
      createdAt: DateTime.utc(2026, 7, 23, 1, 2),
      locationStatus: SosBleLocationStatus.current,
      batteryPercent: 50,
      latitude: 21.951,
      longitude: 96.081,
    );
    final payload = Uint8List.fromList(codec.encode(event).sublist(0, 22))
      ..[1] = sosBleApproximateProtocolVersion
      ..[15] = 0x08
      ..[16] = 0x93
      ..[17] = 0x25
      ..[18] = 0x88
      ..[19] = 50;
    final checksum = _crc16(payload, 0, 20);
    payload[20] = checksum >> 8;
    payload[21] = checksum & 0xff;

    final decoded = codec.decode(payload);

    expect(decoded.protocolVersion, sosBleApproximateProtocolVersion);
    expect(decoded.latitude, closeTo(21.95, 0.005));
    expect(decoded.longitude, closeTo(96.08, 0.005));
  });

  test('creates a Google Maps query for an exact location', () {
    final event = SosBleEvent(
      eventId: '0011223344556677',
      createdAt: DateTime.utc(2026, 7, 23),
      locationStatus: SosBleLocationStatus.current,
      batteryPercent: 50,
      latitude: 21.951,
      longitude: 96.081,
    );

    expect(
      sosBleGoogleMapsUrl(event),
      'https://maps.google.com/?q=21.951000,96.081000',
    );
  });

  test('uses the advertised TTL when determining expiry', () {
    final event = SosBleEvent(
      eventId: '0011223344556677',
      createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
      locationStatus: SosBleLocationStatus.unavailable,
      batteryPercent: 50,
      ttlMinutes: 1,
    );

    expect(event.isExpired, isTrue);
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

    final unsupported = Uint8List.fromList(payload)..[1] = 4;
    expect(() => codec.decode(unsupported), throwsFormatException);
  });

  test('rejects truncated and out-of-range coordinate payloads safely', () {
    expect(() => codec.decode(Uint8List(0)), throwsFormatException);
    expect(
      () => codec.decode(Uint8List.fromList([0x53])),
      throwsFormatException,
    );

    final event = SosBleEvent(
      eventId: '0011223344556677',
      createdAt: DateTime.utc(2026, 7, 23),
      locationStatus: SosBleLocationStatus.current,
      batteryPercent: 50,
      latitude: 21.951,
      longitude: 96.081,
    );
    final payload = codec.encode(event);
    payload[15] = 0x7f;
    payload[16] = 0xff;
    payload[17] = 0xff;
    payload[18] = 0xff;
    final checksum = _crc16(payload, 0, 24);
    payload[24] = checksum >> 8;
    payload[25] = checksum & 0xff;

    expect(() => codec.decode(payload), throwsFormatException);
  });

  test('encodes and decodes one relay hop', () {
    final event = SosBleEvent(
      eventId: '0011223344556677',
      createdAt: DateTime.utc(2026, 7, 23, 1, 2),
      locationStatus: SosBleLocationStatus.unavailable,
      batteryPercent: 50,
      hopCount: 1,
    );

    final decoded = codec.decode(codec.encode(event));

    expect(decoded.hopCount, 1);
    expect(decoded.isRelayed, isTrue);
  });

  test('accepts legacy protocol frames as original events', () {
    final event = SosBleEvent(
      eventId: '0011223344556677',
      createdAt: DateTime.utc(2026, 7, 23, 1, 2),
      locationStatus: SosBleLocationStatus.unavailable,
      batteryPercent: 50,
    );
    final payload = Uint8List.fromList(codec.encode(event).sublist(0, 22))
      ..[1] = 1
      ..[19] = 50;
    final checksum = _crc16(payload, 0, 20);
    payload[20] = checksum >> 8;
    payload[21] = checksum & 0xff;

    final decoded = codec.decode(payload);
    expect(decoded.hopCount, 0);
    expect(decoded.protocolVersion, sosBleLegacyProtocolVersion);
    expect(decoded.ttlMinutes, sosBleTtlMinutes);
  });

  test('encodes and reassembles optional BLE alias and message fragments', () {
    final event = SosBleEvent(
      eventId: '0011223344556677',
      createdAt: DateTime.now().toUtc(),
      locationStatus: SosBleLocationStatus.current,
      batteryPercent: 73,
      latitude: 21.951,
      longitude: 96.081,
      alias: 'Aung',
      message: 'Trapped upstairs.',
    );

    final frames = codec.encodeFrames(event);
    final fragments = [
      for (final frame in frames.skip(1)) codec.decodeMetadataFrame(frame),
    ];
    final metadata = codec.decodeMetadata(fragments.reversed);

    expect(frames.first, hasLength(26));
    expect(fragments.length, greaterThan(1));
    expect(metadata.alias, 'Aung');
    expect(metadata.message, 'Trapped upstairs.');
    expect(
      fragments.every((fragment) => fragment.eventId == event.eventId),
      isTrue,
    );
  });

  test('rejects BLE text that exceeds its byte limits', () {
    final event = SosBleEvent(
      eventId: '0011223344556677',
      createdAt: DateTime.now().toUtc(),
      locationStatus: SosBleLocationStatus.unavailable,
      batteryPercent: 50,
      alias: 'A' * (maxSosBleAliasBytes + 1),
    );

    expect(() => codec.encodeMetadataFrames(event), throwsFormatException);
    expect(
      () => codec.encodeMetadataFrames(
        SosBleEvent(
          eventId: event.eventId,
          createdAt: event.createdAt,
          locationStatus: event.locationStatus,
          batteryPercent: event.batteryPercent,
          message: 'M' * (maxSosBleMessageBytes + 1),
        ),
      ),
      throwsFormatException,
    );
  });

  test('rejects malformed UTF-8 in BLE metadata', () {
    final fragment = SosBleMetadataFragment(
      eventId: '0011223344556677',
      createdAt: DateTime.now().toUtc(),
      hopCount: 0,
      ttlMinutes: sosBleTtlMinutes,
      index: 0,
      total: 1,
      totalDataLength: 3,
      data: Uint8List.fromList([1, 0xc3, 0]),
    );

    expect(() => codec.decodeMetadata([fragment]), throwsFormatException);
  });
}

int _crc16(Uint8List bytes, int start, int end) {
  var crc = 0xffff;
  for (var index = start; index < end; index++) {
    crc ^= bytes[index] << 8;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1;
      crc &= 0xffff;
    }
  }
  return crc;
}
