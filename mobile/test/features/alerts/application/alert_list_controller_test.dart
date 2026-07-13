import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/features/alerts/application/alert_list_controller.dart';
import 'package:mobile/features/alerts/application/alert_list_state.dart';
import 'package:mobile/features/alerts/application/providers.dart';
import 'package:mobile/features/alerts/data/alert_dto.dart';
import 'package:mobile/features/alerts/data/alert_remote_source.dart';
import 'package:mobile/features/alerts/data/alert_repository_impl.dart';
import 'package:mobile/features/alerts/domain/earthquake.dart';

import '../../../support/alert_fixtures.dart';
import '../../../support/fake_alert_repository.dart';

void main() {
  group('AlertListState', () {
    test('items are immutable and equality and copyWith use values', () {
      final source = [earthquakeFixture()];
      final state = AlertListState(
        phase: AlertListPhase.data,
        items: source,
        presentationStatus: AlertPresentationStatus.cached,
        lastSuccessfulRefreshAt: _refreshedAt,
        isRefreshing: true,
        errorKind: null,
      );
      source.clear();

      expect(state.items, [earthquakeFixture()]);
      expect(() => state.items.clear(), throwsUnsupportedError);
      expect(state.copyWith(), state);
      expect(state.copyWith(isRefreshing: false), isNot(state));
      expect(
        state.copyWith(
          clearPresentationStatus: true,
          clearLastSuccessfulRefreshAt: true,
          clearErrorKind: true,
        ),
        AlertListState(
          phase: AlertListPhase.data,
          items: [earthquakeFixture()],
          presentationStatus: null,
          lastSuccessfulRefreshAt: null,
          isRefreshing: true,
          errorKind: null,
        ),
      );
    });
  });

  group('AlertListController', () {
    late FakeAlertRepository repository;
    late ProviderContainer container;
    late FakeAlertRefresh initialRefresh;

    setUp(() {
      repository = FakeAlertRepository();
      initialRefresh = repository.queueRefresh();
      container = ProviderContainer(
        overrides: [alertRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() async {
        container.dispose();
        await repository.close();
      });
    });

    AlertListController start({bool emitInitialCache = true}) {
      container.read(alertListControllerProvider);
      final controller = container.read(alertListControllerProvider.notifier);
      if (emitInitialCache) repository.emit(null);
      return controller;
    }

    AlertListState state() => container.read(alertListControllerProvider);

    test('starts loading with no cache while initial refresh is pending', () {
      start(emitInitialCache: false);

      expect(
        state(),
        AlertListState(
          phase: AlertListPhase.loading,
          items: const [],
          presentationStatus: null,
          lastSuccessfulRefreshAt: null,
          isRefreshing: true,
          errorKind: null,
        ),
      );
      expect(repository.refreshCalls, 0);
    });

    test('null first cache event starts the initial refresh', () async {
      start(emitInitialCache: false);

      repository.emit(null);
      await repository.refreshStarted.future;

      expect(repository.refreshCalls, 1);
      initialRefresh.complete(_snapshot());
      await container.read(alertListControllerProvider.notifier).refresh();
    });

    test(
      'first cache error starts one coalesced refresh and success wins',
      () async {
        final controller = start(emitInitialCache: false);
        final first = controller.refresh();

        repository.emitError(StateError('cache secret'));
        await repository.refreshStarted.future;
        final second = controller.refresh();

        expect(repository.refreshCalls, 1);
        expect(state().phase, AlertListPhase.loading);
        expect(state().isRefreshing, isTrue);
        expect(state().errorKind, AlertListErrorKind.storage);
        initialRefresh.complete(_snapshot());
        await Future.wait([first, second]);
        expect(state().phase, AlertListPhase.data);
        expect(state().presentationStatus, AlertPresentationStatus.live);
        expect(state().isRefreshing, isFalse);
        expect(state().errorKind, isNull);
      },
    );

    test('first cache error request failure applies request error', () async {
      final controller = start(emitInitialCache: false);
      final first = controller.refresh();

      repository.emitError(StateError('cache secret'));
      await repository.refreshStarted.future;
      final second = controller.refresh();
      initialRefresh.completeError(const AlertProtocolException());
      await Future.wait([first, second]);

      expect(repository.refreshCalls, 1);
      expect(state().phase, AlertListPhase.unavailable);
      expect(state().isRefreshing, isFalse);
      expect(state().errorKind, AlertListErrorKind.invalidData);
    });

    test(
      'disposal before first event settles waiters without a request',
      () async {
        final controller = start(emitInitialCache: false);
        final waiting = controller.refresh();

        container.dispose();

        await expectLater(waiting, completes);
        expect(repository.refreshCalls, 0);
        await repository.cacheCancelled.future;
      },
    );

    test('fast refresh cannot win before the first cache event', () async {
      final controller = start(emitInitialCache: false);
      initialRefresh.complete(_snapshot());

      expect(repository.refreshCalls, 0);
      expect(state().phase, AlertListPhase.loading);

      repository.emit(_snapshot(items: [earthquakeFixture(title: 'cached')]));
      await controller.refresh();

      expect(repository.refreshCalls, 1);
      expect(state().presentationStatus, AlertPresentationStatus.live);
      expect(state().items.single.title, 'M 5.2 - Myanmar');
    });

    test(
      'fast failure observes valid cache and never shows unavailable',
      () async {
        repository = FakeAlertRepository()
          ..queueSynchronousError(const AlertRemoteUnavailable());
        container.dispose();
        container = ProviderContainer(
          overrides: [alertRepositoryProvider.overrideWithValue(repository)],
        );
        final phases = <AlertListPhase>[];
        final subscription = container.listen(
          alertListControllerProvider,
          (_, next) => phases.add(next.phase),
          fireImmediately: true,
        );
        addTearDown(subscription.close);
        final controller = start(emitInitialCache: false);

        repository.emit(_snapshot(items: [earthquakeFixture(title: 'cached')]));
        await controller.refresh();

        expect(state().phase, AlertListPhase.data);
        expect(state().items.single.title, 'cached');
        expect(state().presentationStatus, AlertPresentationStatus.stale);
        expect(state().errorKind, AlertListErrorKind.remoteUnavailable);
        expect(phases, isNot(contains(AlertListPhase.unavailable)));
      },
    );

    test('shows cached non-empty data before blocked refresh completes', () {
      start(emitInitialCache: false);

      repository.emit(_snapshot(status: AlertDataStatus.current));

      expect(state().phase, AlertListPhase.data);
      expect(state().items, [earthquakeFixture()]);
      expect(state().presentationStatus, AlertPresentationStatus.cached);
      expect(state().isRefreshing, isTrue);
    });

    test('shows stale local snapshot before refresh completes', () {
      start(emitInitialCache: false);

      repository.emit(_snapshot(status: AlertDataStatus.stale));

      expect(state().presentationStatus, AlertPresentationStatus.stale);
      expect(state().isRefreshing, isTrue);
    });

    test('successful current non-empty refresh becomes live data', () async {
      final controller = start();
      final refresh = controller.refresh();

      initialRefresh.complete(_snapshot());
      await refresh;

      expect(state().phase, AlertListPhase.data);
      expect(state().presentationStatus, AlertPresentationStatus.live);
      expect(state().lastSuccessfulRefreshAt, _refreshedAt);
      expect(state().isRefreshing, isFalse);
      expect(state().errorKind, isNull);
    });

    test('successful stale non-empty refresh remains stale', () async {
      final controller = start();
      final refresh = controller.refresh();

      initialRefresh.complete(_snapshot(status: AlertDataStatus.stale));
      await refresh;

      expect(state().phase, AlertListPhase.data);
      expect(state().presentationStatus, AlertPresentationStatus.stale);
    });

    test('successful current empty refresh becomes live empty', () async {
      final controller = start();
      final refresh = controller.refresh();

      initialRefresh.complete(_snapshot(items: const []));
      await refresh;

      expect(state().phase, AlertListPhase.empty);
      expect(state().items, isEmpty);
      expect(state().presentationStatus, AlertPresentationStatus.live);
    });

    test('typed failures with cache retain data and become stale', () async {
      for (final entry in <Object, AlertListErrorKind>{
        const AlertRemoteUnavailable(): AlertListErrorKind.remoteUnavailable,
        const AlertRemoteException(500): AlertListErrorKind.remoteUnavailable,
        const AlertProtocolException(): AlertListErrorKind.invalidData,
        const AlertStorageException(): AlertListErrorKind.storage,
      }.entries) {
        final currentRepository = FakeAlertRepository();
        final failed = currentRepository.queueRefresh();
        final currentContainer = ProviderContainer(
          overrides: [
            alertRepositoryProvider.overrideWithValue(currentRepository),
          ],
        );
        addTearDown(() async {
          currentContainer.dispose();
          await currentRepository.close();
        });
        currentContainer.read(alertListControllerProvider);
        currentRepository.emit(_snapshot());
        final refresh = currentContainer
            .read(alertListControllerProvider.notifier)
            .refresh();

        failed.completeError(entry.key);
        await refresh;

        final result = currentContainer.read(alertListControllerProvider);
        expect(result.phase, AlertListPhase.data);
        expect(result.items, [earthquakeFixture()]);
        expect(result.presentationStatus, AlertPresentationStatus.stale);
        expect(result.lastSuccessfulRefreshAt, _refreshedAt);
        expect(result.errorKind, entry.value);
        expect(result.toString(), isNot(contains(entry.key.toString())));
      }
    });

    test('each typed failure without cache becomes unavailable', () async {
      for (final entry in <Object, AlertListErrorKind>{
        const AlertRemoteUnavailable(): AlertListErrorKind.remoteUnavailable,
        const AlertProtocolException(): AlertListErrorKind.invalidData,
        const AlertStorageException(): AlertListErrorKind.storage,
      }.entries) {
        final currentRepository = FakeAlertRepository();
        final failed = currentRepository.queueRefresh();
        final currentContainer = ProviderContainer(
          overrides: [
            alertRepositoryProvider.overrideWithValue(currentRepository),
          ],
        );
        addTearDown(() async {
          currentContainer.dispose();
          await currentRepository.close();
        });
        currentContainer.read(alertListControllerProvider);
        currentRepository.emit(null);
        final refresh = currentContainer
            .read(alertListControllerProvider.notifier)
            .refresh();

        failed.completeError(entry.key);
        await refresh;

        final result = currentContainer.read(alertListControllerProvider);
        expect(result.phase, AlertListPhase.unavailable);
        expect(result.items, isEmpty);
        expect(result.presentationStatus, isNull);
        expect(result.errorKind, entry.value);
      }
    });

    test('manual refresh after failure recovers', () async {
      final controller = start();
      final failed = controller.refresh();
      initialRefresh.completeError(const AlertRemoteUnavailable());
      await failed;
      final recovered = repository.queueRefresh();

      final refresh = controller.refresh();
      recovered.complete(_snapshot());
      await refresh;

      expect(repository.refreshCalls, 2);
      expect(state().phase, AlertListPhase.data);
      expect(state().presentationStatus, AlertPresentationStatus.live);
      expect(state().errorKind, isNull);
    });

    test(
      'late cache after unavailable is stale with preserved error',
      () async {
        final controller = start();
        final refresh = controller.refresh();
        initialRefresh.completeError(const AlertRemoteUnavailable());
        await refresh;
        expect(state().phase, AlertListPhase.unavailable);

        repository.emit(_snapshot());

        expect(state().phase, AlertListPhase.data);
        expect(state().presentationStatus, AlertPresentationStatus.stale);
        expect(state().errorKind, AlertListErrorKind.remoteUnavailable);

        repository.emit(_snapshot(items: const []));

        expect(state().phase, AlertListPhase.empty);
        expect(state().presentationStatus, AlertPresentationStatus.stale);
        expect(state().errorKind, AlertListErrorKind.remoteUnavailable);
      },
    );

    test('two concurrent refresh calls share one repository request', () async {
      final controller = start();

      final first = controller.refresh();
      final second = controller.refresh();
      initialRefresh.complete(_snapshot());
      await Future.wait([first, second]);

      expect(repository.refreshCalls, 1);
    });

    test('cache stream updates preserve active refresh state', () async {
      final controller = start();
      final refresh = controller.refresh();
      final updated = earthquakeFixture(
        id: 'usgs:updated',
        providerEventId: 'updated',
      );

      repository.emit(_snapshot(items: [updated]));

      expect(state().items, [updated]);
      expect(state().isRefreshing, isTrue);
      initialRefresh.complete(_snapshot(items: [updated]));
      await refresh;
    });

    test('synchronous persisted current snapshot finishes live', () async {
      final snapshot = _snapshot();
      repository = FakeAlertRepository();
      initialRefresh = repository.queueRefresh(
        synchronousCacheSnapshot: snapshot,
      );
      container.dispose();
      container = ProviderContainer(
        overrides: [alertRepositoryProvider.overrideWithValue(repository)],
      );
      final controller = start(emitInitialCache: false);

      repository.emit(null);
      await repository.refreshStarted.future;
      expect(repository.refreshCalls, 1);
      expect(state().presentationStatus, AlertPresentationStatus.cached);
      initialRefresh.complete(snapshot);
      await controller.refresh();

      expect(state().presentationStatus, AlertPresentationStatus.live);
      expect(state().errorKind, isNull);
    });

    test(
      'matching current cache after completion does not downgrade live',
      () async {
        final controller = start();
        final snapshot = _snapshot();
        final refresh = controller.refresh();
        initialRefresh.complete(snapshot);
        await refresh;

        repository.emit(snapshot);

        expect(state().presentationStatus, AlertPresentationStatus.live);
        expect(state().errorKind, isNull);
      },
    );

    test('differing cache after live success becomes cached data', () async {
      final controller = start();
      final refresh = controller.refresh();
      initialRefresh.complete(_snapshot());
      await refresh;
      final updated = earthquakeFixture(
        id: 'usgs:external',
        providerEventId: 'external',
      );

      repository.emit(_snapshot(items: [updated]));

      expect(state().items, [updated]);
      expect(state().presentationStatus, AlertPresentationStatus.cached);
      expect(state().errorKind, isNull);
    });

    test(
      'persisted stale snapshots remain stale before and after completion',
      () async {
        final snapshot = _snapshot(status: AlertDataStatus.stale);
        repository = FakeAlertRepository();
        initialRefresh = repository.queueRefresh(
          synchronousCacheSnapshot: snapshot,
        );
        container.dispose();
        container = ProviderContainer(
          overrides: [alertRepositoryProvider.overrideWithValue(repository)],
        );
        final controller = start(emitInitialCache: false);
        repository.emit(null);
        await repository.refreshStarted.future;
        expect(repository.refreshCalls, 1);
        expect(state().presentationStatus, AlertPresentationStatus.stale);
        initialRefresh.complete(snapshot);
        await controller.refresh();

        repository.emit(snapshot);

        expect(state().presentationStatus, AlertPresentationStatus.stale);
        expect(state().errorKind, isNull);
      },
    );

    test(
      'matching cache after failure preserves stale error outcome',
      () async {
        final controller = start(emitInitialCache: false);
        final cached = _snapshot();
        repository.emit(cached);
        final refresh = controller.refresh();
        initialRefresh.completeError(const AlertRemoteUnavailable());
        await refresh;

        repository.emit(cached);

        expect(state().presentationStatus, AlertPresentationStatus.stale);
        expect(state().errorKind, AlertListErrorKind.remoteUnavailable);
      },
    );

    test(
      'differing cache after failure updates items but preserves error',
      () async {
        final controller = start(emitInitialCache: false);
        repository.emit(_snapshot());
        final refresh = controller.refresh();
        initialRefresh.completeError(const AlertRemoteUnavailable());
        await refresh;
        final updated = earthquakeFixture(
          id: 'usgs:external',
          providerEventId: 'external',
        );

        repository.emit(_snapshot(items: [updated]));

        expect(state().items, [updated]);
        expect(state().presentationStatus, AlertPresentationStatus.stale);
        expect(state().errorKind, AlertListErrorKind.remoteUnavailable);
      },
    );

    test(
      'unknown refresh failure is safe storage state and completes',
      () async {
        final controller = start();
        final refresh = controller.refresh();

        initialRefresh.completeError(StateError('database path secret'));
        await refresh;

        expect(state().phase, AlertListPhase.unavailable);
        expect(state().isRefreshing, isFalse);
        expect(state().errorKind, AlertListErrorKind.storage);
        expect(state().toString(), isNot(contains('secret')));
      },
    );

    test(
      'cache error during refresh keeps operation active and coalesced',
      () async {
        final controller = start(emitInitialCache: false);
        repository.emit(_snapshot());
        final first = controller.refresh();
        await repository.refreshStarted.future;

        repository.emitError(StateError('cache secret'));
        final second = controller.refresh();

        expect(repository.refreshCalls, 1);
        expect(state().isRefreshing, isTrue);
        expect(state().errorKind, AlertListErrorKind.storage);
        initialRefresh.complete(_snapshot());
        await Future.wait([first, second]);
        expect(state().presentationStatus, AlertPresentationStatus.live);
        expect(state().isRefreshing, isFalse);
        expect(state().errorKind, isNull);
      },
    );

    test(
      'cache error outside refresh follows storage failure behavior',
      () async {
        final controller = start();
        final refresh = controller.refresh();
        initialRefresh.complete(_snapshot());
        await refresh;

        repository.emitError(StateError('cache secret'));

        expect(state().phase, AlertListPhase.data);
        expect(state().presentationStatus, AlertPresentationStatus.stale);
        expect(state().isRefreshing, isFalse);
        expect(state().errorKind, AlertListErrorKind.storage);
      },
    );

    test('disposing controller cancels its cache subscription', () async {
      start();

      container.dispose();

      await repository.cacheCancelled.future;
    });
  });

  group('runtime providers', () {
    test('dispose closes the app-scoped HTTP client', () {
      final client = _TrackingClient();
      final container = ProviderContainer(
        overrides: [httpClientFactoryProvider.overrideWithValue(() => client)],
      );
      container.read(httpClientProvider);

      container.dispose();

      expect(client.closed, isTrue);
    });

    test('default disposal closes the app-scoped database', () async {
      final interceptor = _CloseTrackingInterceptor();
      final database = AppDatabase(
        NativeDatabase.memory().interceptWith(interceptor),
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseFactoryProvider.overrideWithValue(() => database),
        ],
      );
      container.read(appDatabaseProvider);

      container.dispose();

      await interceptor.closed.future;
    });
  });
}

final _refreshedAt = DateTime.utc(2026, 7, 13, 1, 5, 6, 0, 7);

AlertSnapshot _snapshot({
  List<Earthquake>? items,
  AlertDataStatus status = AlertDataStatus.current,
}) => AlertSnapshot(
  items: items ?? [earthquakeFixture()],
  dataStatus: status,
  lastSuccessfulRefreshAt: _refreshedAt,
);

final class _TrackingClient extends http.BaseClient {
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }

  @override
  void close() => closed = true;
}

final class _CloseTrackingInterceptor extends QueryInterceptor {
  final Completer<void> closed = Completer<void>();

  @override
  Future<void> close(QueryExecutor inner) async {
    await inner.close();
    closed.complete();
  }
}
