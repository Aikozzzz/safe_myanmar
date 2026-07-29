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
  });

  final String id;
  final String name;
  final NavigationCoordinate coordinate;
  final String description;
  final String source;
  final DateTime dataAt;
}

final class ShelterCollection {
  ShelterCollection({
    required List<Shelter> items,
    required this.dataAt,
    required this.source,
    required this.uncertaintyNotice,
  }) : items = List.unmodifiable(items);

  final List<Shelter> items;
  final DateTime dataAt;
  final String source;
  final String uncertaintyNotice;
}

final class Hazard {
  Hazard({
    required this.id,
    required this.name,
    required this.disasterType,
    required List<List<NavigationCoordinate>> rings,
    required this.source,
    required this.dataAt,
  }) : rings = List.unmodifiable(
         rings.map((ring) => List<NavigationCoordinate>.unmodifiable(ring)),
       );

  final String id;
  final String name;
  final DisasterType disasterType;
  final List<List<NavigationCoordinate>> rings;
  final String source;
  final DateTime dataAt;
}

final class HazardCollection {
  HazardCollection({
    required List<Hazard> items,
    required this.dataAt,
    required this.source,
    required this.uncertaintyNotice,
  }) : items = List.unmodifiable(items);

  final List<Hazard> items;
  final DateTime dataAt;
  final String source;
  final String uncertaintyNotice;
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
  }) : options = List.unmodifiable(options);

  final List<RouteOption> options;
  final DateTime generatedAt;
  final DateTime hazardDataAt;
  final RouteProfile profile;
  final String profileSelectionReason;
  final String source;
  final String directionsProvider;
  final String uncertaintyNotice;
}

final class RouteSuggestionRequest {
  const RouteSuggestionRequest({
    required this.origin,
    required this.shelterId,
    required this.disasterType,
    required this.profile,
  });

  final NavigationCoordinate origin;
  final String shelterId;
  final DisasterType disasterType;
  final RouteProfile profile;

  int get originLatitudeE5 => (origin.latitude * 100000).round();
  int get originLongitudeE5 => (origin.longitude * 100000).round();

  bool matches(RouteSuggestionRequest other) =>
      originLatitudeE5 == other.originLatitudeE5 &&
      originLongitudeE5 == other.originLongitudeE5 &&
      shelterId == other.shelterId &&
      disasterType == other.disasterType &&
      profile == other.profile;
}
