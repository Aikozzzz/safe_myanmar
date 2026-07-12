final class ApiConfig {
  ApiConfig({required Uri baseUri}) : baseUri = _validate(baseUri);

  factory ApiConfig.fromEnvironment() {
    return ApiConfig.fromRaw(const String.fromEnvironment('API_BASE_URL'));
  }

  factory ApiConfig.fromRaw(String value) {
    if (value.trim().isEmpty) {
      throw StateError(
        'API base URL is required. Set --dart-define=API_BASE_URL=<url>.',
      );
    }
    try {
      return ApiConfig(baseUri: Uri.parse(value));
    } on FormatException {
      throw _invalidConfiguration();
    } on ArgumentError {
      throw _invalidConfiguration();
    }
  }

  final Uri baseUri;

  Uri get alertsUri {
    final segments = baseUri.pathSegments.where(
      (segment) => segment.isNotEmpty,
    );
    return baseUri.replace(pathSegments: [...segments, 'api', 'v1', 'alerts']);
  }

  static Uri _validate(Uri uri) {
    final safeHttpHost = const {'localhost', '127.0.0.1', '10.0.2.2'};
    final validScheme =
        uri.scheme == 'https' ||
        (uri.scheme == 'http' && safeHttpHost.contains(uri.host));
    if (!validScheme ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw _invalidConfiguration();
    }
    return uri;
  }
}

ArgumentError _invalidConfiguration() => ArgumentError(
  'Invalid API_BASE_URL. Use HTTPS, or HTTP only for localhost, 127.0.0.1, '
  'or 10.0.2.2, without credentials, query parameters, or fragments.',
);
