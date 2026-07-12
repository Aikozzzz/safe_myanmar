import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/network/api_config.dart';
import 'package:mobile/features/alerts/data/alert_dto.dart';
import 'package:mobile/features/alerts/data/alert_remote_source.dart';

import '../../../support/alert_fixtures.dart';

void main() {
  group('AlertRemoteSource', () {
    test(
      'GETs the resolved endpoint and decodes current, stale, and empty',
      () async {
        for (final entry in <String, List<Object?>>{
          'current': <Object?>[validAlertJson()],
          'stale': <Object?>[validAlertJson()],
          'empty': const <Object?>[],
        }.entries) {
          late http.Request request;
          final status = entry.key == 'empty' ? 'current' : entry.key;
          final source = _source(
            MockClient((incoming) async {
              request = incoming;
              return http.Response(
                jsonEncode(
                  validEnvelopeJson(items: entry.value, dataStatus: status),
                ),
                200,
              );
            }),
          );

          final result = await source.fetchAlerts();

          expect(request.method, 'GET');
          expect(
            request.url,
            Uri.parse('https://api.example.com/base/api/v1/alerts'),
          );
          expect(result.items, hasLength(entry.value.length));
        }
      },
    );

    test('classifies 503 without leaking response body', () async {
      final source = _source(
        MockClient((_) async => http.Response('database password=secret', 503)),
      );

      await expectLater(
        source.fetchAlerts(),
        throwsA(
          isA<AlertRemoteUnavailable>().having(
            (error) => error.toString(),
            'safe string',
            isNot(contains('secret')),
          ),
        ),
      );
    });

    test(
      'classifies other statuses by code without body or URL leakage',
      () async {
        final source = _source(
          MockClient((_) async => http.Response('token=secret', 418)),
        );

        await expectLater(
          source.fetchAlerts(),
          throwsA(
            isA<AlertRemoteException>()
                .having((error) => error.statusCode, 'statusCode', 418)
                .having(
                  (error) => error.toString(),
                  'safe string',
                  allOf(
                    isNot(contains('secret')),
                    isNot(contains('api.example')),
                  ),
                ),
          ),
        );
      },
    );

    test(
      'classifies timeout, socket, and client failures as unavailable',
      () async {
        final failures = <Future<http.Response> Function()>[
          () => Completer<http.Response>().future,
          () => Future.error(const SocketException('secret host')),
          () => Future.error(http.ClientException('secret URL')),
        ];

        for (final failure in failures) {
          final source = _source(
            MockClient((_) => failure()),
            timeout: const Duration(milliseconds: 1),
          );
          await expectLater(
            source.fetchAlerts(),
            throwsA(
              isA<AlertRemoteUnavailable>().having(
                (error) => error.toString(),
                'safe string',
                allOf(
                  isNot(contains('secret')),
                  isNot(contains('api.example')),
                ),
              ),
            ),
          );
        }
      },
    );

    test(
      'classifies invalid UTF-8, JSON, root, and contract as protocol errors',
      () async {
        final responses = <http.Response>[
          http.Response.bytes(<int>[0xC3, 0x28], 200),
          http.Response('{', 200),
          http.Response('[]', 200),
          http.Response(
            jsonEncode(validEnvelopeJson()..remove('provider')),
            200,
          ),
        ];

        for (final response in responses) {
          await expectLater(
            _source(MockClient((_) async => response)).fetchAlerts(),
            throwsA(isA<AlertProtocolException>()),
          );
        }
      },
    );

    test('does not close the injected client', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response(
          jsonEncode(validEnvelopeJson(items: const [])),
          200,
        );
      });

      await _source(client).fetchAlerts();
      await client.get(Uri.parse('https://api.example.com/still-open'));

      expect(calls, 2);
    });
  });
}

AlertRemoteSource _source(http.Client client, {Duration? timeout}) {
  return AlertRemoteSource(
    client: client,
    config: ApiConfig.fromRaw('https://api.example.com/base'),
    timeout: timeout ?? const Duration(seconds: 10),
  );
}
