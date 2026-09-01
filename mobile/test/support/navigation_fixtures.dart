import 'package:mobile/features/navigation/data/navigation_dto.dart';
import 'package:mobile/features/navigation/domain/navigation_models.dart';

Map<String, Object?> shelterResponseJson() => {
  'items': [
    {
      'id': 'simulation-shelter-1',
      'name': 'SIMULATION: Test Shelter',
      'coordinate': {'latitude': 21.958, 'longitude': 96.091},
      'description': 'Fictional shelter for testing.',
      'source': 'SafeMyanmar Demo',
      'data_at': '2026-07-23T00:00:00Z',
      'simulation': true,
    },
  ],
  'data_at': '2026-07-23T00:00:00Z',
  'source': 'SafeMyanmar Demo',
  'simulation': true,
  'uncertainty_notice': 'SIMULATION information is incomplete.',
};

Map<String, Object?> hazardResponseJson() => {
  'items': [
    {
      'id': 'simulation-hazard-1',
      'name': 'SIMULATION: Test Hazard',
      'disaster_type': 'earthquake',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [96.08, 21.95],
            [96.09, 21.95],
            [96.09, 21.96],
            [96.08, 21.95],
          ],
        ],
      },
      'source': 'SafeMyanmar Demo',
      'data_at': '2026-07-23T00:00:00Z',
      'simulation': true,
    },
  ],
  'data_at': '2026-07-23T00:00:00Z',
  'source': 'SafeMyanmar Demo',
  'simulation': true,
  'uncertainty_notice': 'SIMULATION information is incomplete.',
};

Map<String, Object?> contextAreaResponseJson({
  String name = 'SIMULATION: Lower-exposure area 1',
  String disasterType = 'earthquake',
  String scenario = 'outdoors_after_shaking',
  String source = 'SafeMyanmar Demo',
  bool simulation = true,
  String dataAt = '2026-07-23T00:00:00Z',
  Map<String, Object?>? metrics,
  List<String>? rationale,
  List<String>? candidateNames,
  String uncertaintyNotice = 'SIMULATION information is incomplete.',
}) {
  final areaMetrics =
      metrics ??
      <String, Object?>{
        'building_clearance_m': 120.0,
        'tree_clearance_m': 90.0,
        'relative_elevation_m': 2.0,
        'building_density': 0.1,
        'tree_density': 0.2,
        'hazard_intersections': 0,
      };
  final areaRationale =
      rationale ??
      <String>[
        'Lower simulated building density',
        'Greater simulated tree clearance',
      ];
  final names = candidateNames ?? [name];
  return {
    'items': [
      for (var index = 0; index < names.length; index++)
        {
          'id': index == 0
              ? 'context-area-$disasterType-2195500-9608000'
              : 'context-area-$disasterType-2195500-9608000-$index',
          'name': names[index],
          'coordinate': {
            'latitude': 21.955 + index * 0.001,
            'longitude': 96.08 + index * 0.001,
          },
          'disaster_type': disasterType,
          'scenario': scenario,
          'classification': 'lower_exposure',
          'distance_m': 550.0 + index * 150,
          'metrics': areaMetrics,
          'rationale': areaRationale,
          'source': source,
          'data_at': dataAt,
          'simulation': simulation,
          'uncertainty_notice': uncertaintyNotice,
        },
    ],
    'data_at': dataAt,
    'source': source,
    'simulation': simulation,
    'uncertainty_notice': uncertaintyNotice,
  };
}

Map<String, Object?> routeResponseJson({
  int optionCount = 1,
  String profile = 'walking',
  String source = 'SafeMyanmar Demo',
  String directionsProvider = 'Mapbox Directions',
  bool simulation = true,
  String uncertaintyNotice = 'SIMULATION information is incomplete.',
}) {
  final routeBasis = simulation
      ? 'SIMULATION information'
      : 'currently available mapped information';
  return {
    'options': List.generate(optionCount, (index) {
      final number = index + 1;
      return {
        'id': '${simulation ? 'simulation' : 'real'}-route-$number',
        'generated_at': '2026-07-23T12:00:00Z',
        'hazard_data_at': '2026-07-23T00:00:00Z',
        'profile': profile,
        'source': source,
        'directions_provider': directionsProvider,
        'simulation': simulation,
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [96.08, 21.95],
            [96.091 + index * 0.001, 21.958],
          ],
        },
        'distance_m': 1000.0 + index,
        'duration_seconds': 600.0 + index,
        'hazard_intersection_count': index,
        'rationale': index == 0
            ? 'Suggested route based on $routeBasis.'
            : 'Alternative route based on $routeBasis.',
        'recommended': index == 0,
        'uncertainty_notice': uncertaintyNotice,
      };
    }),
    'generated_at': '2026-07-23T12:00:00Z',
    'hazard_data_at': '2026-07-23T00:00:00Z',
    'profile': profile,
    'profile_selection_reason': 'The user requested the $profile profile.',
    'source': source,
    'directions_provider': directionsProvider,
    'simulation': simulation,
    'uncertainty_notice': uncertaintyNotice,
  };
}

ShelterCollection shelterCollection() =>
    ShelterCollectionDto.fromJson(shelterResponseJson()).toDomain();

HazardCollection hazardCollection() =>
    HazardCollectionDto.fromJson(hazardResponseJson()).toDomain();

RouteSuggestions routeSuggestions({
  int optionCount = 1,
  String profile = 'walking',
  String source = 'SafeMyanmar Demo',
  String directionsProvider = 'Mapbox Directions',
  bool simulation = true,
  String uncertaintyNotice = 'SIMULATION information is incomplete.',
}) => RouteSuggestionsDto.fromJson(
  routeResponseJson(
    optionCount: optionCount,
    profile: profile,
    source: source,
    directionsProvider: directionsProvider,
    simulation: simulation,
    uncertaintyNotice: uncertaintyNotice,
  ),
).toDomain();
