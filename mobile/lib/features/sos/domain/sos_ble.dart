import 'dart:typed_data';

import 'sos_draft.dart';

const sosBleProtocolVersion = 1;
const sosBleGridSizeDegrees = 0.01;
const sosBleTtlMinutes = 10;
const sosBleEpochMinutes = 1_704_067_200 ~/ 60;

enum SosBleLocationStatus { current, lastKnown, unavailable }

enum SosBleBroadcastStatus { idle, starting, active, stopped, expired, failed }

final class SosBleEvent {
  const SosBleEvent({
    required this.eventId,
    required this.createdAt,
    required this.locationStatus,
    required this.batteryPercent,
    this.latitude,
    this.longitude,
    this.rssi,
  });

  final String eventId;
  final DateTime createdAt;
  final SosBleLocationStatus locationStatus;
  final int? batteryPercent;
  final double? latitude;
  final double? longitude;
  final int? rssi;

  bool get hasLocation => latitude != null && longitude != null;

  bool get isExpired =>
      DateTime.now().toUtc().difference(createdAt.toUtc()) >
      const Duration(minutes: sosBleTtlMinutes);

  static SosBleEvent fromDraft({
    required String draftId,
    required DateTime createdAt,
    required SosLocationSnapshot? location,
    required int? batteryPercent,
  }) {
    final normalizedId = draftId.replaceAll('-', '').toLowerCase();
    if (normalizedId.length < 16 ||
        !RegExp(r'^[0-9a-f]+$').hasMatch(normalizedId)) {
      throw const FormatException('SOS draft ID is not a hexadecimal UUID.');
    }
    return SosBleEvent(
      eventId: normalizedId.substring(0, 16),
      createdAt: createdAt.toUtc(),
      locationStatus: location == null
          ? SosBleLocationStatus.unavailable
          : location.isLastKnown
          ? SosBleLocationStatus.lastKnown
          : SosBleLocationStatus.current,
      batteryPercent: _validBattery(batteryPercent) ? batteryPercent : null,
      latitude: location?.latitude,
      longitude: location?.longitude,
    );
  }
}

final class SosBlePayloadCodec {
  const SosBlePayloadCodec();

  // The manufacturer payload stays below the legacy 31-byte advertisement limit.
  Uint8List encode(SosBleEvent event) {
    final eventId = _decodeEventId(event.eventId);
    final hasLocation = event.latitude != null && event.longitude != null;
    if (event.locationStatus == SosBleLocationStatus.unavailable &&
        hasLocation) {
      throw const FormatException(
        'Unavailable SOS BLE location must not contain coordinates.',
      );
    }
    if (event.locationStatus != SosBleLocationStatus.unavailable &&
        !hasLocation) {
      throw const FormatException(
        'SOS BLE location status requires coordinates.',
      );
    }
    if (!_validBattery(event.batteryPercent)) {
      throw const FormatException('Invalid SOS BLE battery value.');
    }
    final createdMinutes =
        event.createdAt.toUtc().millisecondsSinceEpoch ~/ 60000;
    final relativeMinutes = createdMinutes - sosBleEpochMinutes;
    if (relativeMinutes < 0 || relativeMinutes > 0xffffff) {
      throw const FormatException(
        'SOS event timestamp is outside protocol range.',
      );
    }
    final bytes = Uint8List(22);
    bytes[0] = 0x53;
    bytes[1] = sosBleProtocolVersion;
    bytes[2] = SosBleLocationStatus.values.indexOf(event.locationStatus);
    bytes[3] = sosBleTtlMinutes;
    bytes.setRange(4, 12, eventId);
    bytes[12] = (relativeMinutes >> 16) & 0xff;
    bytes[13] = (relativeMinutes >> 8) & 0xff;
    bytes[14] = relativeMinutes & 0xff;
    final latitude = _gridValue(event.latitude);
    final longitude = _gridValue(event.longitude);
    _writeInt16(bytes, 15, latitude);
    _writeInt16(bytes, 17, longitude);
    bytes[19] = event.batteryPercent ?? 0xff;
    final checksum = _crc16(bytes, 0, 20);
    bytes[20] = checksum >> 8;
    bytes[21] = checksum & 0xff;
    return bytes;
  }

  SosBleEvent decode(Uint8List bytes, {int? rssi}) {
    if (bytes.length != 22 || bytes[0] != 0x53) {
      throw const FormatException('Invalid SOS BLE payload length or marker.');
    }
    if (bytes[1] != sosBleProtocolVersion) {
      throw const FormatException('Unsupported SOS BLE protocol version.');
    }
    final expected = (bytes[20] << 8) | bytes[21];
    if (_crc16(bytes, 0, 20) != expected) {
      throw const FormatException('Invalid SOS BLE payload checksum.');
    }
    final statusIndex = bytes[2];
    if (statusIndex >= SosBleLocationStatus.values.length || bytes[3] == 0) {
      throw const FormatException('Invalid SOS BLE payload status.');
    }
    final relativeMinutes = (bytes[12] << 16) | (bytes[13] << 8) | bytes[14];
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      (sosBleEpochMinutes + relativeMinutes) * 60000,
      isUtc: true,
    );
    final battery = bytes[19] == 0xff ? null : bytes[19];
    if (battery != null && battery > 100) {
      throw const FormatException('Invalid SOS BLE battery value.');
    }
    final latitude = _gridCoordinate(bytes, 15);
    final longitude = _gridCoordinate(bytes, 17);
    final hasLocation =
        statusIndex !=
        SosBleLocationStatus.values.indexOf(SosBleLocationStatus.unavailable);
    if (hasLocation && (latitude == null || longitude == null)) {
      throw const FormatException('SOS BLE location is missing.');
    }
    if (!hasLocation && (latitude != null || longitude != null)) {
      throw const FormatException('Unavailable SOS BLE location is populated.');
    }
    return SosBleEvent(
      eventId: _hex(bytes.sublist(4, 12)),
      createdAt: createdAt,
      locationStatus: SosBleLocationStatus.values[statusIndex],
      batteryPercent: battery,
      latitude: latitude,
      longitude: longitude,
      rssi: rssi,
    );
  }

  Uint8List _decodeEventId(String value) {
    if (value.length != 16 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(value)) {
      throw const FormatException('SOS BLE event ID must contain 8 bytes.');
    }
    final bytes = Uint8List(8);
    for (var index = 0; index < 8; index++) {
      bytes[index] = int.parse(
        value.substring(index * 2, index * 2 + 2),
        radix: 16,
      );
    }
    return bytes;
  }
}

abstract interface class SosBlePlatformService {
  Stream<Uint8List> get payloadStream;

  Future<bool> isSupported();

  Future<bool> requestPermissions();

  Future<int?> batteryPercent();

  Future<void> startBroadcast(Uint8List payload);

  Future<void> stopBroadcast();

  Future<void> startScan();

  Future<void> stopScan();
}

bool _validBattery(int? value) => value == null || (value >= 0 && value <= 100);

int _gridValue(double? value) {
  if (value == null) return 0;
  final scaled = (value / sosBleGridSizeDegrees).round();
  if (scaled < -32768 || scaled > 32767) {
    throw const FormatException('Location is outside SOS BLE grid range.');
  }
  return scaled;
}

double? _gridCoordinate(Uint8List bytes, int offset) {
  final value = _readInt16(bytes, offset);
  return value == 0 ? null : value * sosBleGridSizeDegrees;
}

void _writeInt16(Uint8List bytes, int offset, int value) {
  final unsigned = value < 0 ? value + 0x10000 : value;
  bytes[offset] = unsigned >> 8;
  bytes[offset + 1] = unsigned & 0xff;
}

int _readInt16(Uint8List bytes, int offset) {
  final value = (bytes[offset] << 8) | bytes[offset + 1];
  return value >= 0x8000 ? value - 0x10000 : value;
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

String _hex(List<int> bytes) =>
    bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
