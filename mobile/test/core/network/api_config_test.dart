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
  });
}
