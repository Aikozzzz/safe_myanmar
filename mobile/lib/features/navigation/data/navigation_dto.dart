import '../domain/navigation_models.dart';

final class NavigationProtocolException implements Exception {
  const NavigationProtocolException();

  @override
  String toString() =>
      'NavigationProtocolException: Invalid navigation response';
}

final class ShelterCollectionDto {
  ShelterCollectionDto._({
    required this.items,
    required this.dataAt,
    required this.uncertaintyNotice,
  });

  factory ShelterCollectionDto.fromJson(Map<String, Object?> json) {
    try {
      _exact(json, _collectionKeys);
      _simulationMetadata(json);
      final items = _list(json['items']);
      final dataAt = _timestamp(json['data_at']);
      final shelters = List<Shelter>.unmodifiable(items.map(_shelter));
      if (shelters.any((item) => item.dataAt != dataAt)) {
        throw const NavigationProtocolException();
      }
      return ShelterCollectionDto._(
        items: shelters,
        dataAt: dataAt,
        uncertaintyNotice: _string(json['uncertainty_notice']),
      );
    } on NavigationProtocolException {
      rethrow;
    } catch (_) {
      throw const NavigationProtocolException();
    }
  }

  final List<Shelter> items;
  final DateTime dataAt;
  final String uncertaintyNotice;

  ShelterCollection toDomain() => ShelterCollection(
    items: items,
    dataAt: dataAt,
    source: _source,
    uncertaintyNotice: uncertaintyNotice,
  );

  Map<String, Object?> toJson() => {
    'items': items.map(_shelterToJson).toList(),
    'data_at': _timeToJson(dataAt),
    'source': _source,
    'simulation': true,
    'uncertainty_notice': uncertaintyNotice,
  };
}

final class HazardCollectionDto {
  HazardCollectionDto._({
    required this.items,
    required this.dataAt,
    required this.uncertaintyNotice,
  });

  factory HazardCollectionDto.fromJson(Map<String, Object?> json) {
    try {
      _exact(json, _collectionKeys);
      _simulationMetadata(json);
      final items = _list(json['items']);
      final dataAt = _timestamp(json['data_at']);
      final hazards = List<Hazard>.unmodifiable(items.map(_hazard));
      if (hazards.any((item) => item.dataAt != dataAt)) {
        throw const NavigationProtocolException();
      }
      return HazardCollectionDto._(
        items: hazards,
        dataAt: dataAt,
        uncertaintyNotice: _string(json['uncertainty_notice']),
      );
    } on NavigationProtocolException {
      rethrow;
    } catch (_) {
      throw const NavigationProtocolException();
    }
  }

  final List<Hazard> items;
  final DateTime dataAt;
  final String uncertaintyNotice;

  HazardCollection toDomain() => HazardCollection(
    items: items,
    dataAt: dataAt,
    source: _source,
    uncertaintyNotice: uncertaintyNotice,
  );

  Map<String, Object?> toJson() => {
    'items': items.map(_hazardToJson).toList(),
    'data_at': _timeToJson(dataAt),
    'source': _source,
    'simulation': true,
    'uncertainty_notice': uncertaintyNotice,
  };
}

final class RouteSuggestionsDto {
  RouteSuggestionsDto._({
    required this.options,
    required this.generatedAt,
    required this.hazardDataAt,
    required this.profile,
    required this.profileSelectionReason,
    required this.uncertaintyNotice,
  });

  factory RouteSuggestionsDto.fromJson(Map<String, Object?> json) {
    try {
      _exact(json, _routeCollectionKeys);
      _simulationMetadata(json, directions: true);
      final options = _list(json['options']).map(_routeOption).toList();
      final generatedAt = _timestamp(json['generated_at']);
      final hazardDataAt = _timestamp(json['hazard_data_at']);
      final profile = _profile(json['profile']);
      if (options.length > 3 ||
          (options.isNotEmpty && !options.first.recommended) ||
          options.skip(1).any((option) => option.recommended) ||
          options.any(
            (option) =>
                option.generatedAt != generatedAt ||
                option.hazardDataAt != hazardDataAt ||
                option.profile != profile,
          )) {
        throw const NavigationProtocolException();
      }
      return RouteSuggestionsDto._(
        options: List.unmodifiable(options),
        generatedAt: generatedAt,
        hazardDataAt: hazardDataAt,
        profile: profile,
        profileSelectionReason: _string(json['profile_selection_reason']),
        uncertaintyNotice: _string(json['uncertainty_notice']),
      );
    } on NavigationProtocolException {
      rethrow;
    } catch (_) {
      throw const NavigationProtocolException();
    }
  }

  final List<RouteOption> options;
  final DateTime generatedAt;
  final DateTime hazardDataAt;
  final RouteProfile profile;
  final String profileSelectionReason;
  final String uncertaintyNotice;

  RouteSuggestions toDomain() => RouteSuggestions(
    options: options,
    generatedAt: generatedAt,
    hazardDataAt: hazardDataAt,
    profile: profile,
    profileSelectionReason: profileSelectionReason,
    source: _source,
    directionsProvider: _directionsProvider,
    uncertaintyNotice: uncertaintyNotice,
  );

  Map<String, Object?> toJson() => {
    'options': options.map(_routeOptionToJson).toList(),
    'generated_at': _timeToJson(generatedAt),
    'hazard_data_at': _timeToJson(hazardDataAt),
    'profile': profile.name,
    'profile_selection_reason': profileSelectionReason,
    'source': _source,
    'directions_provider': _directionsProvider,
    'simulation': true,
    'uncertainty_notice': uncertaintyNotice,
  };
}

const _source = 'SafeMyanmar Demo';
const _directionsProvider = 'Mapbox Directions';
const _collectionKeys = {
  'items',
  'data_at',
  'source',
  'simulation',
  'uncertainty_notice',
};
const _shelterKeys = {
  'id',
  'name',
  'coordinate',
  'description',
  'source',
  'data_at',
  'simulation',
};
const _hazardKeys = {
  'id',
  'name',
  'disaster_type',
  'geometry',
  'source',
  'data_at',
  'simulation',
};
const _coordinateKeys = {'latitude', 'longitude'};
const _geometryKeys = {'type', 'coordinates'};
const _routeCollectionKeys = {
  'options',
  'generated_at',
  'hazard_data_at',
  'profile',
  'profile_selection_reason',
  'source',
  'directions_provider',
  'simulation',
  'uncertainty_notice',
};
const _routeOptionKeys = {
  'id',
  'generated_at',
  'hazard_data_at',
  'profile',
  'source',
  'directions_provider',
  'simulation',
  'geometry',
  'distance_m',
  'duration_seconds',
  'hazard_intersection_count',
  'rationale',
  'recommended',
  'uncertainty_notice',
};

Shelter _shelter(Object? value) {
  final json = _map(value);
  _exact(json, _shelterKeys);
  _simulationMetadata(json);
  return Shelter(
    id: _string(json['id']),
    name: _string(json['name']),
    coordinate: _coordinate(json['coordinate']),
    description: _string(json['description']),
    source: _source,
    dataAt: _timestamp(json['data_at']),
  );
}

Hazard _hazard(Object? value) {
  final json = _map(value);
  _exact(json, _hazardKeys);
  _simulationMetadata(json);
  final geometry = _map(json['geometry']);
  _exact(geometry, _geometryKeys);
  if (geometry['type'] != 'Polygon') throw const NavigationProtocolException();
  final rings = _list(geometry['coordinates']).map((rawRing) {
    return _list(rawRing).map(_pair).toList();
  }).toList();
  if (rings.isEmpty || rings.any((ring) => !_validLinearRing(ring))) {
    throw const NavigationProtocolException();
  }
  final disasterType = DisasterType.fromWireValue(
    _string(json['disaster_type']),
  );
  if (disasterType == null) throw const NavigationProtocolException();
  return Hazard(
    id: _string(json['id']),
    name: _string(json['name']),
    disasterType: disasterType,
    rings: rings,
    source: _source,
    dataAt: _timestamp(json['data_at']),
  );
}

RouteOption _routeOption(Object? value) {
  final json = _map(value);
  _exact(json, _routeOptionKeys);
  _simulationMetadata(json, directions: true);
  final geometry = _map(json['geometry']);
  _exact(geometry, _geometryKeys);
  if (geometry['type'] != 'LineString') {
    throw const NavigationProtocolException();
  }
  final points = _list(geometry['coordinates']).map(_pair).toList();
  if (points.length < 2) throw const NavigationProtocolException();
  final intersections = json['hazard_intersection_count'];
  final recommended = json['recommended'];
  if (intersections is! int || intersections < 0 || recommended is! bool) {
    throw const NavigationProtocolException();
  }
  return RouteOption(
    id: _string(json['id']),
    generatedAt: _timestamp(json['generated_at']),
    hazardDataAt: _timestamp(json['hazard_data_at']),
    profile: _profile(json['profile']),
    source: _source,
    directionsProvider: _directionsProvider,
    geometry: points,
    distanceM: _nonNegativeDouble(json['distance_m']),
    durationSeconds: _nonNegativeDouble(json['duration_seconds']),
    hazardIntersectionCount: intersections,
    rationale: _string(json['rationale']),
    recommended: recommended,
    uncertaintyNotice: _string(json['uncertainty_notice']),
  );
}

NavigationCoordinate _coordinate(Object? value) {
  final json = _map(value);
  _exact(json, _coordinateKeys);
  return _validatedCoordinate(
    latitude: _strictDouble(json['latitude']),
    longitude: _strictDouble(json['longitude']),
  );
}

NavigationCoordinate _pair(Object? value) {
  final pair = _list(value);
  if (pair.length != 2) throw const NavigationProtocolException();
  return _validatedCoordinate(
    longitude: _strictDouble(pair[0]),
    latitude: _strictDouble(pair[1]),
  );
}

NavigationCoordinate _validatedCoordinate({
  required double latitude,
  required double longitude,
}) {
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    throw const NavigationProtocolException();
  }
  return NavigationCoordinate(latitude: latitude, longitude: longitude);
}

bool _validLinearRing(List<NavigationCoordinate> ring) {
  if (ring.length < 4) return false;
  final first = ring.first;
  final last = ring.last;
  return first.latitude == last.latitude && first.longitude == last.longitude;
}

void _simulationMetadata(Map<String, Object?> json, {bool directions = false}) {
  if (json['source'] != _source || json['simulation'] != true) {
    throw const NavigationProtocolException();
  }
  if (directions && json['directions_provider'] != _directionsProvider) {
    throw const NavigationProtocolException();
  }
}

void _exact(Map<String, Object?> json, Set<String> keys) {
  if (json.length != keys.length || !json.keys.toSet().containsAll(keys)) {
    throw const NavigationProtocolException();
  }
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) throw const NavigationProtocolException();
  try {
    return value.cast<String, Object?>();
  } catch (_) {
    throw const NavigationProtocolException();
  }
}

List<Object?> _list(Object? value) {
  if (value is! List) throw const NavigationProtocolException();
  return value.cast<Object?>();
}

String _string(Object? value) {
  if (value is! String) throw const NavigationProtocolException();
  return value;
}

double _strictDouble(Object? value) {
  if (value is! double || !value.isFinite) {
    throw const NavigationProtocolException();
  }
  return value;
}

double _nonNegativeDouble(Object? value) {
  final result = _strictDouble(value);
  if (result < 0) throw const NavigationProtocolException();
  return result;
}

DateTime _timestamp(Object? value) {
  if (value is! String || !value.endsWith('Z')) {
    throw const NavigationProtocolException();
  }
  final result = DateTime.tryParse(value);
  if (result == null || !result.isUtc) {
    throw const NavigationProtocolException();
  }
  return result;
}

RouteProfile _profile(Object? value) => switch (value) {
  'walking' => RouteProfile.walking,
  'driving' => RouteProfile.driving,
  _ => throw const NavigationProtocolException(),
};

String _timeToJson(DateTime value) => value.toUtc().toIso8601String();

Map<String, Object?> _coordinateToJson(NavigationCoordinate value) => {
  'latitude': value.latitude,
  'longitude': value.longitude,
};

List<double> _pairToJson(NavigationCoordinate value) => [
  value.longitude,
  value.latitude,
];

Map<String, Object?> _shelterToJson(Shelter value) => {
  'id': value.id,
  'name': value.name,
  'coordinate': _coordinateToJson(value.coordinate),
  'description': value.description,
  'source': _source,
  'data_at': _timeToJson(value.dataAt),
  'simulation': true,
};

Map<String, Object?> _hazardToJson(Hazard value) => {
  'id': value.id,
  'name': value.name,
  'disaster_type': value.disasterType.wireValue,
  'geometry': {
    'type': 'Polygon',
    'coordinates': value.rings
        .map((ring) => ring.map(_pairToJson).toList())
        .toList(),
  },
  'source': _source,
  'data_at': _timeToJson(value.dataAt),
  'simulation': true,
};

Map<String, Object?> _routeOptionToJson(RouteOption value) => {
  'id': value.id,
  'generated_at': _timeToJson(value.generatedAt),
  'hazard_data_at': _timeToJson(value.hazardDataAt),
  'profile': value.profile.name,
  'source': _source,
  'directions_provider': _directionsProvider,
  'simulation': true,
  'geometry': {
    'type': 'LineString',
    'coordinates': value.geometry.map(_pairToJson).toList(),
  },
  'distance_m': value.distanceM,
  'duration_seconds': value.durationSeconds,
  'hazard_intersection_count': value.hazardIntersectionCount,
  'rationale': value.rationale,
  'recommended': value.recommended,
  'uncertainty_notice': value.uncertaintyNotice,
};
