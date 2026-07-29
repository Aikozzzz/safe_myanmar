import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/database/app_database.dart';
import '../../../core/network/api_config.dart';
import '../data/alert_local_source.dart';
import '../data/alert_remote_source.dart';
import '../data/alert_repository_impl.dart';
import '../domain/alert_repository.dart';
import 'alert_list_controller.dart';
import 'alert_list_state.dart';

final httpClientFactoryProvider = Provider<http.Client Function()>(
  (_) => http.Client.new,
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = ref.watch(httpClientFactoryProvider)();
  ref.onDispose(client.close);
  return client;
});

final apiConfigProvider = Provider<ApiConfig>(
  (_) => ApiConfig.fromEnvironment(),
);

final appDatabaseFactoryProvider = Provider<AppDatabase Function()>(
  (_) => AppDatabase.open,
);

final appDatabaseDisposerProvider = Provider<void Function(AppDatabase)>(
  (_) => (database) {
    unawaited(database.close());
  },
);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = ref.watch(appDatabaseFactoryProvider)();
  final dispose = ref.watch(appDatabaseDisposerProvider);
  ref.onDispose(() => dispose(database));
  return database;
});

final alertLocalSourceProvider = Provider<AlertLocalSource>(
  (ref) => DriftAlertLocalSource(ref.watch(appDatabaseProvider)),
);

final alertRemoteSourceProvider = Provider<AlertRemoteSource>(
  (ref) => AlertRemoteSource(
    client: ref.watch(httpClientProvider),
    config: ref.watch(apiConfigProvider),
  ),
);

final alertRepositoryProvider = Provider<CachedAlertRepository>(
  (ref) => AlertRepositoryImpl(
    localSource: ref.watch(alertLocalSourceProvider),
    remoteSource: ref.watch(alertRemoteSourceProvider),
  ),
);

final alertListControllerProvider =
    NotifierProvider<AlertListController, AlertListState>(
      AlertListController.new,
    );
