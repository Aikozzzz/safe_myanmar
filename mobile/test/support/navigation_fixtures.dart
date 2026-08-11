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

Map<String, Object?> contextAreaResponseJson() => {
  'items': [
    {
      'id': 'context-area-earthquake-2195500-9608000',
      'name': 'SIMULATION: Lower-exposure area 1',
      'coordinate': {'latitude': 21.955, 'longitude': 96.08},
      'disaster_type': 'earthquake',
      'scenario': 'outdoors_after_shaking',
      'classification': 'lower_exposure',
      'distance_m': 550.0,
      'metrics': {
        'building_clearance_m': 120.0,
        'tree_clearance_m': 90.0,
        'relative_elevation_m': 2.0,
        'building_density': 0.1,
        'tree_density': 0.2,
        'hazard_intersections': 0,
      },
      'rationale': [
        'Lower simulated building density',
        'Greater simulated tree clearance',
      ],
      'source': 'SafeMyanmar Demo',
      'data_at': '2026-07-23T00:00:00Z',
      'simulation': true,
      'uncertainty_notice': 'SIMULATION information is incomplete.',
    },
  ],
  'data_at': '2026-07-23T00:00:00Z',
  'source': 'SafeMyanmar Demo',
  'simulation': true,
  'uncertainty_notice': 'SIMULATION information is incomplete.',
};

Map<String, Object?> routeResponseJson({
  int optionCount = 1,
  String profile = 'walking',
}) => {
  'options': List.generate(optionCount, (index) {
    final number = index + 1;
    return {
      'id': 'simulation-route-$number',
      'generated_at': '2026-07-23T12:00:00Z',
      'hazard_data_at': '2026-07-23T00:00:00Z',
      'profile': profile,
      'source': 'SafeMyanmar Demo',
      'directions_provider': 'Mapbox Directions',
      'simulation': true,
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
          ? 'Suggested safer route based on SIMULATION information.'
          : 'Alternative route based on SIMULATION information.',
      'recommended': index == 0,
      'uncertainty_notice': 'SIMULATION information is incomplete.',
    };
  }),
  'generated_at': '2026-07-23T12:00:00Z',
  'hazard_data_at': '2026-07-23T00:00:00Z',
  'profile': profile,
  'profile_selection_reason': 'The user requested the walking profile.',
  'source': 'SafeMyanmar Demo',
  'directions_provider': 'Mapbox Directions',
  'simulation': true,
  'uncertainty_notice': 'SIMULATION information is incomplete.',
};

ShelterCollection shelterCollection() =>
    ShelterCollectionDto.fromJson(shelterResponseJson()).toDomain();

HazardCollection hazardCollection() =>
    HazardCollectionDto.fromJson(hazardResponseJson()).toDomain();

RouteSuggestions routeSuggestions({int optionCount = 1}) =>
    RouteSuggestionsDto.fromJson(
      routeResponseJson(optionCount: optionCount),
    ).toDomain();
