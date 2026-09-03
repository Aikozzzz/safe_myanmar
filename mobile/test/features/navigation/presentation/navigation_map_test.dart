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

  testWidgets('legend entries open details and expose visibility controls', (
    tester,
  ) async {
    NavigationMapLayer? selectedLayer;
    NavigationMapLayer? visibilityChanged;
    var legendExpanded = true;
    const layer = NavigationMapLayer.nearbySos;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => NavigationMapLegend(
              title: 'Map legend',
              entries: const [
                NavigationMapLegendEntry(
                  layer: layer,
                  icon: Icons.crisis_alert,
                  label: 'Nearby SOS',
                  color: Color(0xffd32f2f),
                  visible: true,
                ),
              ],
              interactionHint: 'Tap for details',
              visibleLabel: 'Layer shown',
              hiddenLabel: 'Layer hidden',
              showLabel: 'Show map legend',
              hideLabel: 'Hide map legend',
              isExpanded: legendExpanded,
              onSelected: (value) => selectedLayer = value,
              onVisibilityChanged: (value) => visibilityChanged = value,
              onToggleExpanded: () => setState(() {
                legendExpanded = !legendExpanded;
              }),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('map-layer-nearbySos')));
    expect(selectedLayer, layer);
    expect(find.text('Nearby SOS'), findsOneWidget);
    expect(find.byTooltip('Layer shown'), findsOneWidget);

    await tester.tap(find.byTooltip('Layer shown'));
    expect(visibilityChanged, layer);

    await tester.tap(find.byTooltip('Hide map legend'));
    await tester.pumpAndSettle();
    expect(find.text('Nearby SOS'), findsNothing);
    expect(find.byTooltip('Show map legend'), findsOneWidget);

    await tester.tap(find.byTooltip('Show map legend'));
    await tester.pumpAndSettle();
    expect(find.text('Nearby SOS'), findsOneWidget);
    expect(find.byTooltip('Hide map legend'), findsOneWidget);
  });

  test('navigation notices hide technical demo and confidence wording', () {
    final notice = navigationUserFacingNotice(
      'SIMULATION information is incomplete. '
      'Some environment metadata was incomplete, so confidence in this '
      'terrain comparison is lower.',
    );

    expect(
      notice,
      'Some information may be incomplete. Follow authorized local '
      'instructions when available.',
    );
    expect(notice, isNot(contains('SIMULATION')));
    expect(notice, isNot(contains('confidence')));
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
