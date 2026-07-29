enum LocationPrecision { approximate, precise }

final class ForegroundLocation {
  const ForegroundLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.precision,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final LocationPrecision precision;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForegroundLocation &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          timestamp == other.timestamp &&
          precision == other.precision;

  @override
  int get hashCode => Object.hash(latitude, longitude, timestamp, precision);
}
