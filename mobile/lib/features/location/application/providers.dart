import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/geolocator_location_repository.dart';
import '../domain/location_repository.dart';
import 'foreground_location_controller.dart';
import 'foreground_location_state.dart';

final locationRepositoryProvider = Provider<LocationRepository>(
  (_) => GeolocatorLocationRepository(),
);

final foregroundLocationControllerProvider =
    NotifierProvider<ForegroundLocationController, ForegroundLocationState>(
      ForegroundLocationController.new,
    );
