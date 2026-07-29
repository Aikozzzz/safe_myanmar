final class MapboxPublicAccessToken {
  const MapboxPublicAccessToken._(this.value);

  factory MapboxPublicAccessToken.fromEnvironment() =>
      MapboxPublicAccessToken.fromRaw(
        const String.fromEnvironment('MAPBOX_PUBLIC_ACCESS_TOKEN'),
      );

  factory MapboxPublicAccessToken.fromRaw(String value) {
    final valid =
        value.length >= 20 &&
        RegExp(
          r'^pk\.[A-Za-z0-9_-]{8,}(?:\.[A-Za-z0-9_-]{8,})+$',
        ).hasMatch(value);
    return MapboxPublicAccessToken._(valid ? value : null);
  }

  final String? value;

  bool get isAvailable => value != null;
}
