import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('reports missing environment configuration clearly', () {
      for (final value in <String>['', '  ']) {
        expect(
          () => ApiConfig.fromRaw(value),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('--dart-define=API_BASE_URL'),
            ),
          ),
        );
      }
    });

    test('accepts general HTTPS and development HTTP hosts', () {
      for (final value in <String>[
        'https://api.example.com',
        'http://localhost:8000',
        'http://127.0.0.1:8000',
        'http://10.0.2.2:8000',
      ]) {
        expect(ApiConfig.fromRaw(value).baseUri.toString(), value);
      }
    });

    test('accepts private LAN HTTP only with explicit development opt-in', () {
      for (final value in [
        'http://10.12.0.5:8000',
        'http://172.20.0.5:8000',
        'http://192.168.1.25:8000',
      ]) {
        expect(
          ApiConfig.fromRaw(value, allowInsecureLan: true).baseUri.toString(),
          value,
        );
        expect(() => ApiConfig.fromRaw(value), throwsA(isA<ArgumentError>()));
      }
      for (final value in [
        'http://8.8.8.8:8000',
        'http://172.15.0.5:8000',
        'http://192.167.1.25:8000',
      ]) {
        expect(
          () => ApiConfig.fromRaw(value, allowInsecureLan: true),
          throwsA(isA<ArgumentError>()),
        );
      }
    });

    test('production rejects every HTTP URL without leaking its value', () {
      final cases = <String>[
        'http://localhost:8000/private-production-path',
        'http://127.0.0.1:8000',
        'http://10.0.2.2:8000',
        'http://api.example.com:8000',
      ];

      for (final value in cases) {
        expect(
          () => ApiConfig.fromRaw(value, isProduction: true),
          throwsA(
            isA<ArgumentError>()
                .having(
                  (error) => error.toString(),
                  'production HTTPS guidance',
                  allOf(contains('HTTPS'), isNot(contains('HTTP only'))),
                )
                .having(
                  (error) => error.toString(),
                  'sanitized value',
                  isNot(contains(value)),
                ),
          ),
        );
      }
    });

    test('sanitizes every invalid raw URI failure', () {
      final cases = <String, List<String>>{
        'http://api.example.com/private': ['api.example.com', '/private'],
        'ftp://files.example.com/private': ['files.example.com', '/private'],
        'https://review-user:review-password@example.com': [
          'review-user',
          'review-password',
          'example.com',
        ],
        'https://example.com?api_key=query-secret': [
          'example.com',
          'api_key',
          'query-secret',
        ],
        'https://example.com#fragment-secret': [
          'example.com',
          'fragment-secret',
        ],
        'https:///missing-host-secret': ['missing-host-secret'],
        'http://[malformed-secret': ['malformed-secret'],
      };

      for (final entry in cases.entries) {
        expect(
          () => ApiConfig.fromRaw(entry.key),
          throwsA(
            isA<ArgumentError>()
                .having(
                  (error) => error.toString(),
                  'guidance',
                  contains('API_BASE_URL'),
                )
                .having(
                  (error) => error.toString(),
                  'sanitized details',
                  predicate<String>(
                    (message) =>
                        !message.contains(entry.key) &&
                        entry.value.every(
                          (secret) => !message.contains(secret),
                        ),
                    'excludes the raw URI and all sensitive components',
                  ),
                ),
          ),
        );
      }
    });

    test('sanitizes direct constructor validation failures', () {
      const username = 'direct-user';
      const password = 'direct-password';
      final unsafe = Uri.parse('https://$username:$password@example.com');

      expect(
        () => ApiConfig(baseUri: unsafe),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.toString(),
            'sanitized details',
            allOf(
              contains('API_BASE_URL'),
              isNot(contains(username)),
              isNot(contains(password)),
              isNot(contains(unsafe.toString())),
            ),
          ),
        ),
      );
    });

    test('resolves alerts endpoint with and without a base path', () {
      final cases = <String, String>{
        'https://example.com': 'https://example.com/api/v1/alerts',
        'https://example.com/': 'https://example.com/api/v1/alerts',
        'https://example.com/base': 'https://example.com/base/api/v1/alerts',
        'https://example.com/base/': 'https://example.com/base/api/v1/alerts',
      };

      for (final entry in cases.entries) {
        expect(ApiConfig.fromRaw(entry.key).alertsUri.toString(), entry.value);
      }
    });

    test('resolves all navigation contract endpoints under API v1', () {
      final config = ApiConfig.fromRaw('https://example.com/mobile-gateway/');

      expect(
        config.sheltersUri.toString(),
        'https://example.com/mobile-gateway/api/v1/shelters',
      );
      expect(
        config.hazardsUri.toString(),
        'https://example.com/mobile-gateway/api/v1/hazards',
      );
      expect(
        config.routeSuggestionsUri.toString(),
        'https://example.com/mobile-gateway/api/v1/route-suggestions',
      );
    });
  });
}
