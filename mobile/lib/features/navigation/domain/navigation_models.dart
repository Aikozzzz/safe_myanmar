enum DisasterType {
  earthquake,
  flood,
  fire,
  cyclone,
  landslide,
  severeWeather;

  String get wireValue => switch (this) {
    DisasterType.severeWeather => 'severe_weather',
    _ => name,
  };

  static DisasterType? fromWireValue(String value) => switch (value) {
    'earthquake' => DisasterType.earthquake,
    'flood' => DisasterType.flood,
    'fire' => DisasterType.fire,
    'cyclone' => DisasterType.cyclone,
    'landslide' => DisasterType.landslide,
    'severe_weather' => DisasterType.severeWeather,
    _ => null,
  };
}

enum RouteProfile { walking, driving }

enum ContextScenario {
  outdoorsAfterShaking,
  general;

  String get wireValue => switch (this) {
    ContextScenario.outdoorsAfterShaking => 'outdoors_after_shaking',
    ContextScenario.general => 'general',
  };
}

final class NavigationCoordinate {
  const NavigationCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

final class Shelter {
  const Shelter({
    required this.id,
    required this.name,
    required this.coordinate,
    required this.description,
    required this.source,
    required this.dataAt,
    this.simulation = false,
  });

  final String id;
  final String name;
  final NavigationCoordinate coordinate;
  final String description;
  final String source;
  final DateTime dataAt;
  final bool simulation;
}

final class ShelterCollection {
  ShelterCollection({
    required List<Shelter> items,
    required this.dataAt,
    required this.source,
    required this.uncertaintyNotice,
    this.simulation = false,
  }) : items = List.unmodifiable(items);

  final List<Shelter> items;
  final DateTime dataAt;
  final String source;
  final String uncertaintyNotice;
  final bool simulation;
}

final class ContextMetrics {
  const ContextMetrics({
    required this.buildingClearanceM,
    required this.treeClearanceM,
    required this.relativeElevationM,
    required this.buildingDensity,
    required this.treeDensity,
    required this.hazardIntersections,
  });

  final double buildingClearanceM;
  final double treeClearanceM;
  final double relativeElevationM;
  final double buildingDensity;
  final double treeDensity;
  final int hazardIntersections;
}

final class ContextArea {
  ContextArea({
    required this.id,
    required this.name,
    required this.coordinate,
    required this.disasterType,
    required this.scenario,
    required this.distanceM,
    required this.metrics,
    required List<String> rationale,
    required this.source,
    required this.dataAt,
    required this.uncertaintyNotice,
    this.simulation = false,
  }) : rationale = List.unmodifiable(rationale);

  final String id;
  final String name;
  final NavigationCoordinate coordinate;
  final DisasterType disasterType;
  final ContextScenario scenario;
  final double distanceM;
  final ContextMetrics metrics;
  final List<String> rationale;
  final String source;
  final DateTime dataAt;
  final String uncertaintyNotice;
  final bool simulation;
}

final class ContextAreaCollection {
  ContextAreaCollection({
    required List<ContextArea> items,
    required this.dataAt,
    required this.source,
    required this.uncertaintyNotice,
    this.simulation = false,
  }) : items = List.unmodifiable(items);

  final List<ContextArea> items;
  final DateTime dataAt;
  final String source;
  final String uncertaintyNotice;
  final bool simulation;
}

final class ContextAreaRequest {
  const ContextAreaRequest({
    required this.origin,
    required this.disasterType,
    required this.scenario,
    this.searchRadiusM = 1000,
  });

  final NavigationCoordinate origin;
  final DisasterType disasterType;
  final ContextScenario scenario;
  final double searchRadiusM;

  int get originLatitudeE5 => (origin.latitude * 100000).round();
  int get originLongitudeE5 => (origin.longitude * 100000).round();

  bool matches(ContextAreaRequest other) =>
      originLatitudeE5 == other.originLatitudeE5 &&
      originLongitudeE5 == other.originLongitudeE5 &&
      disasterType == other.disasterType &&
      scenario == other.scenario &&
      searchRadiusM == other.searchRadiusM;
}

final class Hazard {
  Hazard({
    required this.id,
    required this.name,
    required this.disasterType,
    required List<List<NavigationCoordinate>> rings,
    required this.source,
    required this.dataAt,
    this.simulation = false,
  }) : rings = List.unmodifiable(
         rings.map((ring) => List<NavigationCoordinate>.unmodifiable(ring)),
       );

  final String id;
  final String name;
  final DisasterType disasterType;
  final List<List<NavigationCoordinate>> rings;
  final String source;
  final DateTime dataAt;
  final bool simulation;
}

final class HazardCollection {
  HazardCollection({
    required List<Hazard> items,
    required this.dataAt,
    required this.source,
    required this.uncertaintyNotice,
    this.simulation = false,
  }) : items = List.unmodifiable(items);

  final List<Hazard> items;
  final DateTime dataAt;
  final String source;
  final String uncertaintyNotice;
  final bool simulation;
}

final class RouteOption {
  RouteOption({
    required this.id,
    required this.generatedAt,
    required this.hazardDataAt,
    required this.profile,
    required this.source,
    required this.directionsProvider,
    required List<NavigationCoordinate> geometry,
    required this.distanceM,
    required this.durationSeconds,
    required this.hazardIntersectionCount,
    required this.rationale,
    required this.recommended,
    required this.uncertaintyNotice,
    this.simulation = false,
  }) : geometry = List.unmodifiable(geometry);

  final String id;
  final DateTime generatedAt;
  final DateTime hazardDataAt;
  final RouteProfile profile;
  final String source;
  final String directionsProvider;
  final List<NavigationCoordinate> geometry;
  final double distanceM;
  final double durationSeconds;
  final int hazardIntersectionCount;
  final String rationale;
  final bool recommended;
  final String uncertaintyNotice;
  final bool simulation;
}

final class RouteSuggestions {
  RouteSuggestions({
    required List<RouteOption> options,
    required this.generatedAt,
    required this.hazardDataAt,
    required this.profile,
    required this.profileSelectionReason,
    required this.source,
    required this.directionsProvider,
    required this.uncertaintyNotice,
    this.simulation = false,
  }) : options = List.unmodifiable(options);

  final List<RouteOption> options;
  final DateTime generatedAt;
  final DateTime hazardDataAt;
  final RouteProfile profile;
  final String profileSelectionReason;
  final String source;
  final String directionsProvider;
  final String uncertaintyNotice;
  final bool simulation;
}

final class RouteSuggestionRequest {
  const RouteSuggestionRequest({
    required this.origin,
    this.shelterId,
    this.contextAreaId,
    required this.disasterType,
    required this.profile,
    this.scenario = ContextScenario.general,
    this.searchRadiusM = 1000,
  });

  final NavigationCoordinate origin;
  final String? shelterId;
  final String? contextAreaId;
  final DisasterType disasterType;
  final RouteProfile profile;
  final ContextScenario scenario;
  final double searchRadiusM;

  String get destinationId => contextAreaId ?? shelterId ?? '';

  int get originLatitudeE5 => (origin.latitude * 100000).round();
  int get originLongitudeE5 => (origin.longitude * 100000).round();

  bool matches(RouteSuggestionRequest other) =>
      originLatitudeE5 == other.originLatitudeE5 &&
      originLongitudeE5 == other.originLongitudeE5 &&
      contextAreaId == other.contextAreaId &&
      shelterId == other.shelterId &&
      disasterType == other.disasterType &&
      profile == other.profile &&
      scenario == other.scenario &&
      searchRadiusM == other.searchRadiusM;
}

final class SosRouteRequest {
  const SosRouteRequest({
    required this.eventId,
    required this.origin,
    required this.destination,
    required this.profile,
  });

  final String eventId;
  final NavigationCoordinate origin;
  final NavigationCoordinate destination;
  final RouteProfile profile;

  int get originLatitudeE5 => (origin.latitude * 100000).round();
  int get originLongitudeE5 => (origin.longitude * 100000).round();
  int get destinationLatitudeE5 => (destination.latitude * 100000).round();
  int get destinationLongitudeE5 => (destination.longitude * 100000).round();

  bool matches(SosRouteRequest other) =>
      eventId == other.eventId &&
      originLatitudeE5 == other.originLatitudeE5 &&
      originLongitudeE5 == other.originLongitudeE5 &&
      destinationLatitudeE5 == other.destinationLatitudeE5 &&
      destinationLongitudeE5 == other.destinationLongitudeE5 &&
      profile == other.profile;
}
