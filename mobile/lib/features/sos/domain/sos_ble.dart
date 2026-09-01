import 'dart:typed_data';

import 'sos_draft.dart';

const sosBleProtocolVersion = 3;
const sosBleLegacyProtocolVersion = 1;
const sosBleApproximateProtocolVersion = 2;
const sosBleMaxRelayHops = 1;
const sosBleGridSizeDegrees = 0.01;
const sosBleCoordinateScale = 1000000;
const sosBleTtlMinutes = 10;
const sosBleRelayDurationSeconds = 5;
const sosBleEpochMinutes = 1_704_067_200 ~/ 60;
const sosBleStructuredIdentityMarker = 0xa5;
const sosBleStructuredIdentityVersion = 0x5a;
const sosBleSenderTokenLength = 8;
const sosBleEventSequenceMaximum = 0xffff;
const sosBleMaximumRetainedEvents = 64;

enum SosBleLocationStatus { current, lastKnown, unavailable }

enum SosBleBroadcastStatus { idle, starting, active, stopped, expired, failed }

final class SosBleSenderMetadata {
  const SosBleSenderMetadata({
    required this.senderToken,
    required this.eventSequence,
  });

  final String senderToken;
  final int eventSequence;

  String get eventId =>
      '${sosBleStructuredIdentityMarker.toRadixString(16).padLeft(2, '0')}'
      '${sosBleStructuredIdentityVersion.toRadixString(16).padLeft(2, '0')}'
      '$senderToken${eventSequence.toRadixString(16).padLeft(4, '0')}';

  static SosBleSenderMetadata? tryParseEventId(String eventId) {
    if (eventId.length != 16 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(eventId)) {
      return null;
    }
    final normalized = eventId.toLowerCase();
    if (int.parse(normalized.substring(0, 2), radix: 16) !=
            sosBleStructuredIdentityMarker ||
        int.parse(normalized.substring(2, 4), radix: 16) !=
            sosBleStructuredIdentityVersion) {
      return null;
    }
    final senderToken = normalized.substring(4, 12);
    final eventSequence = int.parse(normalized.substring(12), radix: 16);
    return SosBleSenderMetadata(
      senderToken: senderToken,
      eventSequence: eventSequence,
    );
  }
}

enum SosBlePermissionIssue {
  ready,
  unsupported,
  bluetoothDisabled,
  scanDenied,
  advertiseDenied,
  notificationDenied,
}

final class SosBlePermissionState {
  const SosBlePermissionState({
    required this.supported,
    required this.bluetoothEnabled,
    required this.scanGranted,
    required this.advertiseGranted,
    required this.notificationGranted,
  });

  final bool supported;
  final bool bluetoothEnabled;
  final bool scanGranted;
  final bool advertiseGranted;
  final bool notificationGranted;

  bool get canReceive => supported && bluetoothEnabled && scanGranted;

  bool get canBroadcast => supported && bluetoothEnabled && advertiseGranted;

  bool get canBackgroundReceive => canReceive && notificationGranted;

  SosBlePermissionIssue get issue {
    if (!supported) return SosBlePermissionIssue.unsupported;
    if (!bluetoothEnabled) return SosBlePermissionIssue.bluetoothDisabled;
    if (!scanGranted) return SosBlePermissionIssue.scanDenied;
    if (!advertiseGranted) return SosBlePermissionIssue.advertiseDenied;
    if (!notificationGranted) return SosBlePermissionIssue.notificationDenied;
    return SosBlePermissionIssue.ready;
  }
}

final class SosBleEvent {
  const SosBleEvent({
    required this.eventId,
    required this.createdAt,
    required this.locationStatus,
    required this.batteryPercent,
    this.latitude,
    this.longitude,
    this.rssi,
    this.hopCount = 0,
    this.protocolVersion = sosBleProtocolVersion,
    this.ttlMinutes = sosBleTtlMinutes,
    this.senderToken,
    this.eventSequence,
  });

  final String eventId;
  final DateTime createdAt;
  final SosBleLocationStatus locationStatus;
  final int? batteryPercent;
  final double? latitude;
  final double? longitude;
  final int? rssi;
  final int hopCount;
  final int protocolVersion;
  final int ttlMinutes;
  final String? senderToken;
  final int? eventSequence;

  bool get hasLocation => latitude != null && longitude != null;

  bool get isRelayed => hopCount > 0;

  bool get isExpired =>
      DateTime.now().toUtc().difference(createdAt.toUtc()) >
      Duration(minutes: ttlMinutes);

  static SosBleEvent fromDraft({
    required String draftId,
    required DateTime createdAt,
    required SosLocationSnapshot? location,
    required int? batteryPercent,
    String? senderToken,
    int? eventSequence,
  }) {
    final normalizedId = draftId.replaceAll('-', '').toLowerCase();
    if (normalizedId.length < 16 ||
        !RegExp(r'^[0-9a-f]+$').hasMatch(normalizedId)) {
      throw const FormatException('SOS draft ID is not a hexadecimal UUID.');
    }
    final metadata = senderToken == null || eventSequence == null
        ? null
        : SosBleSenderMetadata(
            senderToken: senderToken,
            eventSequence: eventSequence,
          );
    return SosBleEvent(
      eventId: metadata?.eventId ?? normalizedId.substring(0, 16),
      createdAt: createdAt.toUtc(),
      locationStatus: location == null
          ? SosBleLocationStatus.unavailable
          : location.isLastKnown
          ? SosBleLocationStatus.lastKnown
          : SosBleLocationStatus.current,
      batteryPercent: _validBattery(batteryPercent) ? batteryPercent : null,
      latitude: location?.latitude,
      longitude: location?.longitude,
      hopCount: 0,
      protocolVersion: sosBleProtocolVersion,
      ttlMinutes: sosBleTtlMinutes,
      senderToken: metadata?.senderToken,
      eventSequence: metadata?.eventSequence,
    );
  }

  SosBleEvent copyWithHopCount(int value) => SosBleEvent(
    eventId: eventId,
    createdAt: createdAt,
    locationStatus: locationStatus,
    batteryPercent: batteryPercent,
    latitude: latitude,
    longitude: longitude,
    rssi: rssi,
    hopCount: value,
    protocolVersion: protocolVersion,
    ttlMinutes: ttlMinutes,
    senderToken: senderToken,
    eventSequence: eventSequence,
  );
}

final class SosBleAdvertisement {
  const SosBleAdvertisement(this.payload, {this.rssi, this.background = false});

  final Uint8List payload;
  final int? rssi;
  final bool background;
}

final class SosBlePayloadCodec {
  const SosBlePayloadCodec();

  // Protocol v3 carries six-decimal coordinates while remaining within the
  // legacy 31-byte BLE advertisement limit.
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
    if (event.hopCount < 0 || event.hopCount > sosBleMaxRelayHops) {
      throw const FormatException('Invalid SOS BLE relay hop count.');
    }
    if (event.ttlMinutes < 1 || event.ttlMinutes > 15) {
      throw const FormatException('Invalid SOS BLE TTL.');
    }
    final createdMinutes =
        event.createdAt.toUtc().millisecondsSinceEpoch ~/ 60000;
    final relativeMinutes = createdMinutes - sosBleEpochMinutes;
    if (relativeMinutes < 0 || relativeMinutes > 0xffffff) {
      throw const FormatException(
        'SOS event timestamp is outside protocol range.',
      );
    }
    final bytes = Uint8List(26);
    bytes[0] = 0x53;
    bytes[1] = sosBleProtocolVersion;
    bytes[2] = SosBleLocationStatus.values.indexOf(event.locationStatus);
    bytes[3] = (event.hopCount << 4) | event.ttlMinutes;
    bytes.setRange(4, 12, eventId);
    bytes[12] = (relativeMinutes >> 16) & 0xff;
    bytes[13] = (relativeMinutes >> 8) & 0xff;
    bytes[14] = relativeMinutes & 0xff;
    _writeInt32(bytes, 15, _coordinateValue(event.latitude, latitude: true));
    _writeInt32(bytes, 19, _coordinateValue(event.longitude));
    bytes[23] = event.batteryPercent ?? 0xff;
    final checksum = _crc16(bytes, 0, 24);
    bytes[24] = checksum >> 8;
    bytes[25] = checksum & 0xff;
    return bytes;
  }

  SosBleEvent decode(Uint8List bytes, {int? rssi}) {
    if (bytes.length < 2) {
      throw const FormatException('Invalid SOS BLE payload length or marker.');
    }
    if (bytes[0] != 0x53) {
      throw const FormatException('Invalid SOS BLE payload length or marker.');
    }
    final isExact = bytes[1] == sosBleProtocolVersion;
    final isApproximate = bytes[1] == sosBleApproximateProtocolVersion;
    final isLegacy = bytes[1] == sosBleLegacyProtocolVersion;
    if (!isExact && !isApproximate && !isLegacy) {
      throw const FormatException('Unsupported SOS BLE protocol version.');
    }
    final expectedLength = isExact ? 26 : 22;
    if (bytes.length != expectedLength) {
      throw const FormatException('Invalid SOS BLE payload length or marker.');
    }
    final checksumOffset = isExact ? 24 : 20;
    final expected = (bytes[checksumOffset] << 8) | bytes[checksumOffset + 1];
    if (_crc16(bytes, 0, checksumOffset) != expected) {
      throw const FormatException('Invalid SOS BLE payload checksum.');
    }
    final statusIndex = bytes[2];
    final ttlMinutes = bytes[3] & 0x0f;
    final hopCount = isLegacy ? 0 : bytes[3] >> 4;
    if (statusIndex >= SosBleLocationStatus.values.length ||
        ttlMinutes == 0 ||
        ttlMinutes > 15 ||
        hopCount > sosBleMaxRelayHops) {
      throw const FormatException('Invalid SOS BLE payload status.');
    }
    final relativeMinutes = (bytes[12] << 16) | (bytes[13] << 8) | bytes[14];
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      (sosBleEpochMinutes + relativeMinutes) * 60000,
      isUtc: true,
    );
    final batteryOffset = isExact ? 23 : 19;
    final battery = bytes[batteryOffset] == 0xff ? null : bytes[batteryOffset];
    if (battery != null && battery > 100) {
      throw const FormatException('Invalid SOS BLE battery value.');
    }
    final hasLocation =
        statusIndex !=
        SosBleLocationStatus.values.indexOf(SosBleLocationStatus.unavailable);
    final latitude = isExact
        ? (hasLocation ? _exactCoordinate(bytes, 15) : null)
        : _gridCoordinate(bytes, 15);
    final longitude = isExact
        ? (hasLocation ? _exactCoordinate(bytes, 19) : null)
        : _gridCoordinate(bytes, 17);
    if (hasLocation && (latitude == null || longitude == null)) {
      throw const FormatException('SOS BLE location is missing.');
    }
    if (!hasLocation && (latitude != null || longitude != null)) {
      throw const FormatException('Unavailable SOS BLE location is populated.');
    }
    if (hasLocation &&
        (latitude == null ||
            longitude == null ||
            !_validDecodedCoordinate(latitude, latitude: true) ||
            !_validDecodedCoordinate(longitude))) {
      throw const FormatException('SOS BLE location is outside valid bounds.');
    }
    return SosBleEvent(
      eventId: _hex(bytes.sublist(4, 12)),
      createdAt: createdAt,
      locationStatus: SosBleLocationStatus.values[statusIndex],
      batteryPercent: battery,
      latitude: latitude,
      longitude: longitude,
      rssi: rssi,
      hopCount: hopCount,
      protocolVersion: bytes[1],
      ttlMinutes: ttlMinutes,
      senderToken: SosBleSenderMetadata.tryParseEventId(
        _hex(bytes.sublist(4, 12)),
      )?.senderToken,
      eventSequence: SosBleSenderMetadata.tryParseEventId(
        _hex(bytes.sublist(4, 12)),
      )?.eventSequence,
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
  Stream<SosBleAdvertisement> get payloadStream;

  Stream<String> get notificationEventStream;

  Future<bool> isSupported();

  Future<bool> requestPermissions({
    required bool receive,
    required bool broadcast,
    required bool background,
  });

  Future<SosBlePermissionState> getPermissionState();

  Future<bool> openAppSettings();

  Future<int?> batteryPercent();

  Future<void> startBroadcast(
    Uint8List payload, {
    String languageCode = 'en',
  });

  Future<void> startRelayBroadcast(
    Uint8List payload, {
    String languageCode = 'en',
  });

  Future<void> stopBroadcast();

  Future<void> startScan();

  Future<void> stopScan();

  Future<bool> isBackgroundScanEnabled();

  Future<void> startBackgroundScan({String languageCode = 'en'});

  Future<void> stopBackgroundScan();

  Future<List<SosBleAdvertisement>> readBackgroundAdvertisements();

  Future<String?> getPendingNotificationEventId();
}

bool _validBattery(int? value) => value == null || (value >= 0 && value <= 100);

double? _gridCoordinate(Uint8List bytes, int offset) {
  final value = _readInt16(bytes, offset);
  return value == 0 ? null : value * sosBleGridSizeDegrees;
}

int _coordinateValue(double? value, {bool latitude = false}) {
  if (value == null) return 0;
  final maximum = latitude ? 90 : 180;
  if (!value.isFinite || value < -maximum || value > maximum) {
    throw const FormatException(
      'Location is outside SOS BLE coordinate range.',
    );
  }
  final scaled = (value * sosBleCoordinateScale).round();
  if (scaled < -2147483648 || scaled > 2147483647) {
    throw const FormatException(
      'Location is outside SOS BLE coordinate range.',
    );
  }
  return scaled;
}

void _writeInt32(Uint8List bytes, int offset, int value) {
  final unsigned = value < 0 ? value + 0x100000000 : value;
  bytes[offset] = (unsigned >> 24) & 0xff;
  bytes[offset + 1] = (unsigned >> 16) & 0xff;
  bytes[offset + 2] = (unsigned >> 8) & 0xff;
  bytes[offset + 3] = unsigned & 0xff;
}

int _readInt16(Uint8List bytes, int offset) {
  final value = (bytes[offset] << 8) | bytes[offset + 1];
  return value >= 0x8000 ? value - 0x10000 : value;
}

double _exactCoordinate(Uint8List bytes, int offset) {
  final value = _readInt32(bytes, offset);
  return value / sosBleCoordinateScale;
}

bool _validDecodedCoordinate(double value, {bool latitude = false}) {
  final maximum = latitude ? 90 : 180;
  return value.isFinite && value >= -maximum && value <= maximum;
}

int _readInt32(Uint8List bytes, int offset) {
  final value =
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
  return value >= 0x80000000 ? value - 0x100000000 : value;
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

String? sosBleGoogleMapsUrl(SosBleEvent event) {
  if (!event.hasLocation) return null;
  return 'https://maps.google.com/?q='
      '${event.latitude!.toStringAsFixed(6)},'
      '${event.longitude!.toStringAsFixed(6)}';
}
