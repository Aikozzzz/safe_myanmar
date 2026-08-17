import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/mapbox_public_access_token.dart';
import '../../alerts/application/providers.dart';
import '../data/navigation_local_source.dart';
import '../data/navigation_remote_source.dart';
import '../data/navigation_repository_impl.dart';
import '../domain/navigation_repository.dart';
import 'navigation_controller.dart';
import 'navigation_state.dart';

final mapboxPublicAccessTokenProvider = Provider<MapboxPublicAccessToken>(
  (_) => MapboxPublicAccessToken.fromEnvironment(),
);

final navigationLocalSourceProvider = Provider<NavigationLocalSource>(
  (ref) => DriftNavigationLocalSource(ref.watch(appDatabaseProvider)),
);

final navigationRemoteSourceProvider = Provider<NavigationRemoteSource>(
  (ref) => NavigationRemoteSource(
    client: ref.watch(httpClientProvider),
    config: ref.watch(apiConfigProvider),
  ),
);

final navigationRepositoryProvider = Provider<NavigationRepository>((ref) {
  final config = ref.watch(apiConfigProvider);
  return NavigationRepositoryImpl(
    localSource: ref.watch(navigationLocalSourceProvider),
    remoteSource: ref.watch(navigationRemoteSourceProvider),
    allowSimulationData: config.allowSimulationData,
  );
});

final navigationControllerProvider =
    NotifierProvider<NavigationController, NavigationState>(
      NavigationController.new,
    );
