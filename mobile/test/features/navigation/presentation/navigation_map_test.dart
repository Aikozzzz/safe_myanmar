import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mobile/features/navigation/presentation/navigation_map.dart';
import 'package:mobile/features/sos/domain/sos_ble.dart';

void main() {
  test('visible map layers match the rendered non-empty annotations', () {
    expect(
      visibleNavigationMapLayers(
        hasLocation: true,
        hasShelters: true,
        hasHazards: true,
        hasContextAreas: true,
        hasRoutes: true,
        hasNearbySos: true,
      ),
      NavigationMapLayer.values,
    );
    expect(
      visibleNavigationMapLayers(
        hasLocation: false,
        hasShelters: false,
        hasHazards: true,
        hasContextAreas: false,
        hasRoutes: true,
        hasNearbySos: false,
      ),
      [NavigationMapLayer.hazard, NavigationMapLayer.route],
    );
  });

  test(
    'point markers use the symbols and colors represented by the legend',
    () {
      expect(
        navigationMapMarkerIcon(NavigationMapMarkerKind.location),
        Icons.my_location,
      );
      expect(
        navigationMapMarkerColor(NavigationMapMarkerKind.location),
        const Color(0xff0e7c78),
      );
      expect(
        navigationMapMarkerIcon(NavigationMapMarkerKind.shelter),
        Icons.home_work_outlined,
      );
      expect(
        navigationMapMarkerColor(NavigationMapMarkerKind.shelter),
        const Color(0xff2e7d32),
      );
      expect(
        navigationMapMarkerIcon(NavigationMapMarkerKind.contextArea),
        Icons.park_outlined,
      );
      expect(
        navigationMapMarkerColor(NavigationMapMarkerKind.contextArea),
        const Color(0xffef6c00),
      );
      expect(
        navigationMapMarkerIcon(NavigationMapMarkerKind.nearbySos),
        Icons.crisis_alert,
      );
      expect(
        navigationMapMarkerColor(NavigationMapMarkerKind.nearbySos),
        const Color(0xffd32f2f),
      );
    },
  );

  test('only a style failure replaces the map with the retry fallback', () {
    expect(isFatalMapLoadError(MapLoadErrorType.STYLE), isTrue);
    expect(isFatalMapLoadError(MapLoadErrorType.TILE), isFalse);
    expect(isFatalMapLoadError(MapLoadErrorType.SOURCE), isFalse);
    expect(isFatalMapLoadError(MapLoadErrorType.SPRITE), isFalse);
    expect(isFatalMapLoadError(MapLoadErrorType.GLYPHS), isFalse);
  });

  test('SOS map coordinates keep longitude first for Mapbox', () {
    final coordinate = sosBleMapCoordinate(
      SosBleEvent(
        eventId: '0011223344556677',
        createdAt: DateTime.utc(2026, 7, 23),
        locationStatus: SosBleLocationStatus.current,
        batteryPercent: 50,
        latitude: 21.951234,
        longitude: 96.081234,
      ),
    );

    expect(coordinate, (longitude: 96.081234, latitude: 21.951234));
  });

  test('SOS map coordinates are omitted when the frame has no location', () {
    final coordinate = sosBleMapCoordinate(
      SosBleEvent(
        eventId: '0011223344556677',
        createdAt: DateTime.utc(2026, 7, 23),
        locationStatus: SosBleLocationStatus.unavailable,
        batteryPercent: null,
      ),
    );

    expect(coordinate, isNull);
  });
}
