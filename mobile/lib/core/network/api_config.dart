final class ApiConfig {
  ApiConfig({required Uri baseUri, bool? isProduction})
    : baseUri = _validate(
        baseUri,
        isProduction: isProduction ?? _isProductionBuild,
      );

  factory ApiConfig.fromEnvironment() {
    return ApiConfig.fromRaw(const String.fromEnvironment('API_BASE_URL'));
  }

  factory ApiConfig.fromRaw(String value, {bool? isProduction}) {
    if (value.trim().isEmpty) {
      throw StateError(
        'API base URL is required. Set --dart-define=API_BASE_URL=<url>.',
      );
    }
    final production = isProduction ?? _isProductionBuild;
    try {
      return ApiConfig(baseUri: Uri.parse(value), isProduction: production);
    } on FormatException {
      throw _invalidConfiguration(isProduction: production);
    } on ArgumentError {
      throw _invalidConfiguration(isProduction: production);
    }
  }

  final Uri baseUri;

  Uri get alertsUri {
    return _apiV1Uri('alerts');
  }

  Uri get sheltersUri => _apiV1Uri('shelters');

  Uri get hazardsUri => _apiV1Uri('hazards');

  Uri get contextAreasUri => _apiV1Uri('context-areas');

  Uri get routeSuggestionsUri => _apiV1Uri('route-suggestions');

  Uri _apiV1Uri(String resource) {
    final segments = baseUri.pathSegments.where(
      (segment) => segment.isNotEmpty,
    );
    return baseUri.replace(pathSegments: [...segments, 'api', 'v1', resource]);
  }

  static const _isProductionBuild = bool.fromEnvironment('dart.vm.product');

  static Uri _validate(Uri uri, {required bool isProduction}) {
    final safeHttpHost = const {'localhost', '127.0.0.1', '10.0.2.2'};
    final validScheme =
        uri.scheme == 'https' ||
        (!isProduction &&
            uri.scheme == 'http' &&
            safeHttpHost.contains(uri.host));
    if (!validScheme ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw _invalidConfiguration(isProduction: isProduction);
    }
    return uri;
  }
}

ArgumentError _invalidConfiguration({required bool isProduction}) =>
    ArgumentError(
      isProduction
          ? 'Invalid API_BASE_URL. Production builds require HTTPS without '
                'credentials, query parameters, or fragments.'
          : 'Invalid API_BASE_URL. Use HTTPS, or HTTP only for localhost, '
                '127.0.0.1, or 10.0.2.2, without credentials, query '
                'parameters, or fragments.',
    );
