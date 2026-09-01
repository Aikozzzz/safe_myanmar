final class ApiConfig {
  ApiConfig({required Uri baseUri, bool? isProduction, bool? allowInsecureLan})
    : baseUri = _validate(
        baseUri,
        isProduction: isProduction ?? _isProductionBuild,
        allowInsecureLan: allowInsecureLan ?? _allowInsecureLanApi,
      );

  factory ApiConfig.fromEnvironment() {
    return ApiConfig.fromRaw(const String.fromEnvironment('API_BASE_URL'));
  }

  factory ApiConfig.fromRaw(
    String value, {
    bool? isProduction,
    bool? allowInsecureLan,
  }) {
    if (value.trim().isEmpty) {
      throw StateError(
        'API base URL is required. Set --dart-define=API_BASE_URL=<url>.',
      );
    }
    final production = isProduction ?? _isProductionBuild;
    try {
      return ApiConfig(
        baseUri: Uri.parse(value),
        isProduction: production,
        allowInsecureLan: allowInsecureLan,
      );
    } on FormatException {
      throw _invalidConfiguration(isProduction: production);
    } on ArgumentError {
      throw _invalidConfiguration(isProduction: production);
    }
  }

  final Uri baseUri;

  bool get allowSimulationData =>
      const bool.fromEnvironment('ENABLE_SIMULATION_DATA');

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
  static const _allowInsecureLanApi = bool.fromEnvironment(
    'ALLOW_INSECURE_LAN_API',
  );

  static Uri _validate(
    Uri uri, {
    required bool isProduction,
    required bool allowInsecureLan,
  }) {
    final safeHttpHost = const {'localhost', '127.0.0.1', '10.0.2.2'};
    final developmentHttpHost =
        safeHttpHost.contains(uri.host) ||
        (allowInsecureLan && _isPrivateIpv4(uri.host));
    final validScheme =
        uri.scheme == 'https' ||
        (!isProduction && uri.scheme == 'http' && developmentHttpHost);
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

  static bool _isPrivateIpv4(String host) {
    final octets = host.split('.');
    if (octets.length != 4) return false;
    final values = <int>[];
    for (final octet in octets) {
      final value = int.tryParse(octet);
      if (value == null || value < 0 || value > 255) return false;
      values.add(value);
    }
    return values[0] == 10 ||
        (values[0] == 172 && values[1] >= 16 && values[1] <= 31) ||
        (values[0] == 192 && values[1] == 168);
  }
}

ArgumentError _invalidConfiguration({required bool isProduction}) =>
    ArgumentError(
      isProduction
          ? 'Invalid API_BASE_URL. Production builds require HTTPS without '
                'credentials, query parameters, or fragments.'
          : 'Invalid API_BASE_URL. Use HTTPS, or HTTP only for localhost, '
                '127.0.0.1, 10.0.2.2, or an explicitly enabled private LAN '
                'address, without credentials, query parameters, or fragments.',
    );
