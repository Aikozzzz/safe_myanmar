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

    test('rejects unsafe or ambiguous base URIs', () {
      for (final value in <String>[
        'http://api.example.com',
        'ftp://api.example.com',
        'https://user:pass@example.com',
        'https://example.com?token=secret',
        'https://example.com#fragment',
        'https:///missing-host',
      ]) {
        expect(() => ApiConfig.fromRaw(value), throwsArgumentError);
      }
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
