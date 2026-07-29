import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/network/api_config.dart';
import 'package:mobile/features/alerts/data/alert_local_source.dart';
import 'package:mobile/features/alerts/data/alert_remote_source.dart';
import 'package:mobile/features/alerts/data/alert_repository_impl.dart';
import 'package:mobile/features/alerts/domain/earthquake.dart';

import '../../../support/alert_fixtures.dart';
import '../../../support/fake_alert_local_source.dart';

void main() {
  late FakeAlertLocalSource local;

  setUp(() => local = FakeAlertLocalSource());
  tearDown(() => local.close());

  test('cached snapshot stream maps every field and UTC timestamps', () async {
    final item = earthquakeFixture();
    final refreshedAt = DateTime.utc(2026, 7, 13, 1, 5, 6, 7, 8);
    local.emit(
      AlertLocalSnapshot(
        items: [item],
        dataStatus: AlertDataStatus.stale,
        lastSuccessfulRefreshAt: refreshedAt,
        cachedAt: DateTime.utc(2026, 7, 13, 2),
      ),
    );
    final repository = _repository(local, _successfulClient());

    final result = await repository.watchCachedSnapshot().first;

    expect(result, isNotNull);
    expect(result!.items, [item]);
    expect(result.dataStatus, AlertDataStatus.stale);
    expect(result.lastSuccessfulRefreshAt, refreshedAt);
    expect(result.lastSuccessfulRefreshAt.isUtc, isTrue);
  });

  test('watchCached maps immutable item lists without a request', () async {
    var remoteCalls = 0;
    final item = earthquakeFixture();
    local.emit(_localSnapshot([item]));
    final repository = _repository(
      local,
      MockClient((_) async {
        remoteCalls++;
        return _response();
      }),
    );

    final result = await repository.watchCached().first;

    expect(result, [item]);
    expect(() => result.add(item), throwsUnsupportedError);
    expect(remoteCalls, 0);
  });

  test(
    'refresh fetches and persists once then returns exact snapshot',
    () async {
      var remoteCalls = 0;
      final cachedAt = DateTime.utc(2026, 7, 13, 8);
      final repository = _repository(
        local,
        MockClient((_) async {
          remoteCalls++;
          return _response();
        }),
        now: () => cachedAt,
      );

      final result = await repository.refresh();

      expect(remoteCalls, 1);
      expect(local.replaceCalls, 1);
      expect(local.replacedAt, cachedAt);
      expect(result.items.single.id, 'usgs:example');
      expect(
        result.items.single.eventAt,
        DateTime.utc(2026, 7, 13, 1, 2, 3, 0, 4),
      );
      expect(result.dataStatus, AlertDataStatus.current);
      expect(result.lastSuccessfulRefreshAt, _refreshedAt);
      expect(local.replacedSnapshot, same(result));
    },
  );

  test('successful empty refresh persists empty metadata', () async {
    final repository = _repository(local, _successfulClient(items: const []));

    final result = await repository.refresh();

    expect(result.items, isEmpty);
    expect(local.replaceCalls, 1);
    expect(local.replacedSnapshot!.items, isEmpty);
    expect(local.replacedSnapshot!.lastSuccessfulRefreshAt, _refreshedAt);
  });

  test(
    'remote unavailable and protocol failures preserve local data',
    () async {
      final previous = _localSnapshot([earthquakeFixture(title: 'cached')]);
      for (final response in <http.Response>[
        http.Response('unavailable', 503),
        http.Response('{', 200),
      ]) {
        local = FakeAlertLocalSource(initialSnapshot: previous);
        addTearDown(local.close);
        final repository = _repository(
          local,
          MockClient((_) async => response),
        );

        await expectLater(repository.refresh(), throwsA(anything));

        expect(local.replaceCalls, 0);
        expect((await local.readSnapshot())!.items.single.title, 'cached');
      }
    },
  );

  test('timeout failure preserves local data without replacement', () async {
    final previous = _localSnapshot([earthquakeFixture(title: 'cached')]);
    local = FakeAlertLocalSource(initialSnapshot: previous);
    addTearDown(local.close);
    final repository = _repository(
      local,
      MockClient((_) => Future.error(TimeoutException('provider details'))),
    );

    await expectLater(
      repository.refresh(),
      throwsA(isA<AlertRemoteUnavailable>()),
    );

    expect(local.replaceCalls, 0);
    expect((await local.readSnapshot())!.items.single.title, 'cached');
  });

  test('storage failure is safe and leaves previous snapshot intact', () async {
    final previous = _localSnapshot([earthquakeFixture(title: 'cached')]);
    local = FakeAlertLocalSource(initialSnapshot: previous)
      ..replaceError = StateError('database path and secret');
    addTearDown(local.close);
    final repository = _repository(local, _successfulClient());

    await expectLater(
      repository.refresh(),
      throwsA(
        isA<AlertStorageException>().having(
          (error) => error.toString(),
          'safe string',
          allOf(isNot(contains('path')), isNot(contains('secret'))),
        ),
      ),
    );

    expect(local.replaceCalls, 1);
    expect((await local.readSnapshot())!.items.single.title, 'cached');
  });

  test('getById delegates to the scoped local source', () async {
    final item = earthquakeFixture();
    local = FakeAlertLocalSource(initialSnapshot: _localSnapshot([item]));
    addTearDown(local.close);
    final repository = _repository(local, _successfulClient());

    expect(await repository.getById(item.id), item);
    expect(local.requestedId, item.id);
  });

  test('watch failures are normalized to safe storage errors', () async {
    local.watchError = StateError('database path secret');
    final repository = _repository(local, _successfulClient());

    await expectLater(
      repository.watchCachedSnapshot().first,
      throwsA(
        isA<AlertStorageException>().having(
          (error) => error.toString(),
          'safe string',
          isNot(contains('secret')),
        ),
      ),
    );
  });

  test('detail read failures are normalized to safe storage errors', () async {
    local.getByIdError = StateError('database path secret');
    final repository = _repository(local, _successfulClient());

    await expectLater(
      repository.getById('usgs:example'),
      throwsA(isA<AlertStorageException>()),
    );
  });

  test('a failed request is not retried', () async {
    var calls = 0;
    final repository = _repository(
      local,
      MockClient((_) async {
        calls++;
        return http.Response('unavailable', 503);
      }),
    );

    await expectLater(
      repository.refresh(),
      throwsA(isA<AlertRemoteUnavailable>()),
    );
    expect(calls, 1);
  });
}

final _refreshedAt = DateTime.utc(2026, 7, 13, 1, 5, 6, 0, 7);

AlertRepositoryImpl _repository(
  FakeAlertLocalSource local,
  http.Client client, {
  DateTime Function()? now,
}) => AlertRepositoryImpl(
  localSource: local,
  remoteSource: AlertRemoteSource(
    client: client,
    config: ApiConfig.fromRaw('https://api.example.com'),
  ),
  now: now ?? () => DateTime.utc(2026, 7, 13, 9),
);

MockClient _successfulClient({List<Object?>? items}) =>
    MockClient((_) async => _response(items: items));

http.Response _response({List<Object?>? items}) => http.Response(
  jsonEncode(validEnvelopeJson(items: items)),
  200,
  headers: const {'content-type': 'application/json'},
);

AlertLocalSnapshot _localSnapshot(List<Earthquake> items) => AlertLocalSnapshot(
  items: items,
  dataStatus: AlertDataStatus.current,
  lastSuccessfulRefreshAt: _refreshedAt,
  cachedAt: DateTime.utc(2026, 7, 13, 2),
);
