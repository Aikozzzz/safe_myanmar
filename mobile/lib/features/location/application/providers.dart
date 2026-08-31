import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/geolocator_location_repository.dart';
import '../data/location_permission_prompt_store.dart';
import '../domain/location_repository.dart';
import '../../profile/application/providers.dart';
import 'foreground_location_controller.dart';
import 'foreground_location_state.dart';

final locationRepositoryProvider = Provider<LocationRepository>(
  (_) => GeolocatorLocationRepository(),
);

final locationPermissionPromptStoreProvider =
    Provider<LocationPermissionPromptStore>(
      (ref) => SecureLocationPermissionPromptStore(
        ref.watch(secureStorageDriverProvider),
      ),
    );

final foregroundLocationControllerProvider =
    NotifierProvider<ForegroundLocationController, ForegroundLocationState>(
      ForegroundLocationController.new,
    );
