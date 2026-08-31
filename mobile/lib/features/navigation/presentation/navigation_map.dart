import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../../../l10n/app_localizations.dart';
import '../../location/domain/foreground_location.dart';
import '../../sos/domain/sos_ble.dart';
import '../domain/navigation_models.dart';

enum NavigationMapLayer {
  location,
  shelter,
  hazard,
  contextArea,
  route,
  nearbySos,
}

List<NavigationMapLayer> visibleNavigationMapLayers({
  required bool hasLocation,
  required bool hasShelters,
  required bool hasHazards,
  required bool hasContextAreas,
  required bool hasRoutes,
  required bool hasNearbySos,
}) => [
  if (hasLocation) NavigationMapLayer.location,
  if (hasShelters) NavigationMapLayer.shelter,
  if (hasHazards) NavigationMapLayer.hazard,
  if (hasContextAreas) NavigationMapLayer.contextArea,
  if (hasRoutes) NavigationMapLayer.route,
  if (hasNearbySos) NavigationMapLayer.nearbySos,
];

class NavigationMap extends StatefulWidget {
  const NavigationMap({
    required this.accessToken,
    required this.location,
    this.initialCenter,
    required this.shelters,
    required this.contextAreas,
    required this.selectedContextAreaId,
    required this.hazards,
    this.nearbyEvents = const [],
    this.activeEvent,
    this.focusedEventId,
    this.selectedEventId,
    this.onSosEventSelected,
    this.onLocationSelected,
    required this.showAllSosLabel,
    required this.locationActionLabel,
    required this.routes,
    required this.selectedRouteId,
    required this.semanticsLabel,
    required this.errorTitle,
    required this.errorDescription,
    required this.retryLabel,
    super.key,
  }) : assert(location != null || initialCenter != null);

  final String accessToken;
  final ForegroundLocation? location;
  final NavigationCoordinate? initialCenter;
  final List<Shelter> shelters;
  final List<ContextArea> contextAreas;
  final String? selectedContextAreaId;
  final List<Hazard> hazards;
  final List<SosBleEvent> nearbyEvents;
  final SosBleEvent? activeEvent;
  final String? focusedEventId;
  final String? selectedEventId;
  final ValueChanged<String>? onSosEventSelected;
  final VoidCallback? onLocationSelected;
  final String showAllSosLabel;
  final String locationActionLabel;
  final List<RouteOption> routes;
  final String? selectedRouteId;
  final String semanticsLabel;
  final String errorTitle;
  final String errorDescription;
  final String retryLabel;

  @override
  State<NavigationMap> createState() => _NavigationMapState();
}

class _NavigationMapState extends State<NavigationMap> {
  mapbox.MapboxMap? _map;
  mapbox.CircleAnnotationManager? _locationManager;
  mapbox.CircleAnnotationManager? _shelterManager;
  mapbox.PolygonAnnotationManager? _hazardManager;
  mapbox.PolylineAnnotationManager? _routeManager;
  mapbox.CircleAnnotationManager? _sosManager;
  mapbox.Cancelable? _locationTapEvents;
  mapbox.Cancelable? _sosTapEvents;
  Future<void>? _managerInitialization;
  Future<void> _pendingUpdate = Future.value();
  bool _loadFailed = false;
  var _mapGeneration = 0;
  String? _cameraFocusedEventId;

  NavigationCoordinate get _mapCenter =>
      widget.initialCenter ??
      NavigationCoordinate(
        latitude: widget.location!.latitude,
        longitude: widget.location!.longitude,
      );

  @override
  void initState() {
    super.initState();
    // The token must be configured before build can construct MapWidget.
    mapbox.MapboxOptions.setAccessToken(widget.accessToken);
  }

  @override
  void didUpdateWidget(covariant NavigationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleUpdate();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return Card(
        key: const ValueKey('mapbox-load-error'),
        child: SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_outlined, size: 40),
                const SizedBox(height: 12),
                Text(
                  widget.errorTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(widget.errorDescription, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _retryMap,
                  icon: const Icon(Icons.refresh),
                  label: Text(widget.retryLabel),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final strings = AppLocalizations.of(context)!;
    final legendEntries = _visibleLegendEntries(strings);
    return Semantics(
      label: widget.semanticsLabel,
      container: true,
      child: Column(
        children: [
          SizedBox(
            height: 360,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: mapbox.MapWidget(
                      key: ValueKey('mapbox-map-widget-$_mapGeneration'),
                      // Claim map gestures so the surrounding ListView does
                      // not consume drags before Mapbox can pan, zoom, or
                      // rotate the map.
                      gestureRecognizers: {
                        Factory<OneSequenceGestureRecognizer>(
                          EagerGestureRecognizer.new,
                        ),
                      },
                      styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
                      viewport: mapbox.CameraViewportState(
                        center: _point(
                          _mapCenter.longitude,
                          _mapCenter.latitude,
                        ),
                        zoom: 12,
                      ),
                      onMapCreated: (map) => _map = map,
                      onStyleLoadedListener: (_) => _ensureManagers(),
                      onMapLoadErrorListener: _onMapLoadError,
                    ),
                  ),
                  if (widget.location != null)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Semantics(
                        button: true,
                        label: widget.locationActionLabel,
                        child: FloatingActionButton(
                          key: const ValueKey('map-location-button'),
                          tooltip: widget.locationActionLabel,
                          onPressed: () => unawaited(_handleLocationTap()),
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                    ),
                  if (legendEntries.isNotEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: IgnorePointer(
                        child: _MapLegend(
                          title: strings.mapLegendTitle,
                          entries: legendEntries,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_locatedSosEvents.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _showAllSosEvents,
                icon: const Icon(Icons.fit_screen),
                label: Text(widget.showAllSosLabel),
              ),
            ),
        ],
      ),
    );
  }

  List<_MapLegendEntry> _visibleLegendEntries(AppLocalizations strings) {
    final layers = visibleNavigationMapLayers(
      hasLocation: widget.location != null,
      hasShelters: widget.shelters.isNotEmpty,
      hasHazards: widget.hazards.isNotEmpty,
      hasContextAreas: widget.contextAreas.isNotEmpty,
      hasRoutes: widget.routes.isNotEmpty,
      hasNearbySos: _locatedSosEvents.isNotEmpty,
    );
    return [
      for (final layer in layers)
        _MapLegendEntry(
          icon: switch (layer) {
            NavigationMapLayer.location => Icons.my_location,
            NavigationMapLayer.shelter => Icons.home_work_outlined,
            NavigationMapLayer.hazard => Icons.warning_amber_outlined,
            NavigationMapLayer.contextArea => Icons.park_outlined,
            NavigationMapLayer.route => Icons.route,
            NavigationMapLayer.nearbySos => Icons.crisis_alert,
          },
          label: switch (layer) {
            NavigationMapLayer.location => strings.mapLegendLocation,
            NavigationMapLayer.shelter => strings.mapLegendShelter,
            NavigationMapLayer.hazard => strings.mapLegendHazard,
            NavigationMapLayer.contextArea => strings.mapLegendContextArea,
            NavigationMapLayer.route => strings.mapLegendRoute,
            NavigationMapLayer.nearbySos => strings.mapLegendNearbySos,
          },
          color: switch (layer) {
            NavigationMapLayer.location => const Color(0xff0e7c78),
            NavigationMapLayer.shelter => const Color(0xff2e7d32),
            NavigationMapLayer.hazard => const Color(0xffb3261e),
            NavigationMapLayer.contextArea => const Color(0xffef6c00),
            NavigationMapLayer.route => const Color(0xff6750a4),
            NavigationMapLayer.nearbySos => const Color(0xffd32f2f),
          },
        ),
    ];
  }

  List<SosBleEvent> get _sosEvents => [
    ?widget.activeEvent,
    for (final event in widget.nearbyEvents)
      if (event.eventId != widget.activeEvent?.eventId) event,
  ];

  List<SosBleEvent> get _locatedSosEvents =>
      _sosEvents.where((event) => event.hasLocation).toList(growable: false);

  Future<void> _showAllSosEvents() async {
    final map = _map;
    final events = _locatedSosEvents;
    if (map == null || events.length < 2) return;
    try {
      final camera = await map.cameraForCoordinatesPadding(
        [for (final event in events) _point(event.longitude!, event.latitude!)],
        mapbox.CameraOptions(zoom: 12),
        mapbox.MbxEdgeInsets(top: 36, left: 36, bottom: 36, right: 36),
        16,
        null,
      );
      await map.setCamera(camera);
    } catch (_) {
      // Keep the existing camera when the provider cannot fit the points.
    }
  }

  @override
  void dispose() {
    _locationTapEvents?.cancel();
    _sosTapEvents?.cancel();
    super.dispose();
  }

  void _initializeLocationTapEvents() {
    _locationTapEvents?.cancel();
    _locationTapEvents = _locationManager?.tapEvents(
      onTap: (_) => unawaited(_handleLocationTap()),
    );
  }

  void _initializeSosTapEvents() {
    _sosTapEvents?.cancel();
    _sosTapEvents = _sosManager?.tapEvents(
      onTap: (annotation) {
        final eventId = annotation.customData?['sos_event_id'];
        if (eventId is String) widget.onSosEventSelected?.call(eventId);
      },
    );
  }

  Future<void> _ensureManagers() =>
      _managerInitialization ??= _initializeManagersSafely();

  Future<void> _initializeManagersSafely() async {
    try {
      await _initializeManagers();
    } catch (_) {
      _showLoadFailure();
    }
  }

  void _onMapLoadError(mapbox.MapLoadingErrorEventData event) {
    if (isFatalMapLoadError(event.type)) {
      _showLoadFailure();
    }
  }

  void _showLoadFailure() {
    if (!mounted || _loadFailed) return;
    setState(() => _loadFailed = true);
  }

  void _retryMap() {
    _locationTapEvents?.cancel();
    _locationTapEvents = null;
    _sosTapEvents?.cancel();
    _sosTapEvents = null;
    setState(() {
      _map = null;
      _locationManager = null;
      _shelterManager = null;
      _hazardManager = null;
      _routeManager = null;
      _sosManager = null;
      _managerInitialization = null;
      _loadFailed = false;
      _mapGeneration++;
    });
  }

  Future<void> _initializeManagers() async {
    final map = _map;
    if (map == null || _locationManager != null) return;

    // Manager order keeps broad hazards below routes and point markers.
    _hazardManager = await map.annotations.createPolygonAnnotationManager(
      id: 'safe-hazards',
    );
    _routeManager = await map.annotations.createPolylineAnnotationManager(
      id: 'safe-routes',
    );
    _shelterManager = await map.annotations.createCircleAnnotationManager(
      id: 'safe-shelters',
    );
    _locationManager = await map.annotations.createCircleAnnotationManager(
      id: 'safe-user-location',
    );
    _sosManager = await map.annotations.createCircleAnnotationManager(
      id: 'nearby-sos-events',
    );
    _initializeLocationTapEvents();
    _initializeSosTapEvents();
    await _routeManager!.setLineCap(mapbox.LineCap.ROUND);
    await _updateAnnotations();
  }

  void _scheduleUpdate() {
    _pendingUpdate = _pendingUpdate
        .then((_) => _updateAnnotations())
        .onError((_, _) {});
  }

  Future<void> _updateAnnotations() async {
    final locationManager = _locationManager;
    final shelterManager = _shelterManager;
    final hazardManager = _hazardManager;
    final routeManager = _routeManager;
    final sosManager = _sosManager;
    if (!mounted ||
        locationManager == null ||
        shelterManager == null ||
        hazardManager == null ||
        routeManager == null ||
        sosManager == null) {
      return;
    }

    await locationManager.deleteAll();
    if (widget.location case final location?) {
      await locationManager.create(
        mapbox.CircleAnnotationOptions(
          geometry: _point(location.longitude, location.latitude),
          circleRadius: 10,
          circleColor: const Color(0xff0e7c78).toARGB32(),
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 3,
          customData: {'location_marker': true},
        ),
      );
    }

    await shelterManager.deleteAll();
    if (widget.shelters.isNotEmpty) {
      await shelterManager.createMulti(
        widget.shelters
            .map(
              (shelter) => mapbox.CircleAnnotationOptions(
                geometry: _point(
                  shelter.coordinate.longitude,
                  shelter.coordinate.latitude,
                ),
                circleRadius: 8,
                circleColor: const Color(0xff2e7d32).toARGB32(),
                circleStrokeColor: Colors.white.toARGB32(),
                circleStrokeWidth: 2,
                customData: {'shelter_id': shelter.id},
              ),
            )
            .toList(),
      );
    }
    if (widget.contextAreas.isNotEmpty) {
      await shelterManager.createMulti(
        widget.contextAreas
            .map(
              (area) => mapbox.CircleAnnotationOptions(
                geometry: _point(
                  area.coordinate.longitude,
                  area.coordinate.latitude,
                ),
                circleRadius: area.id == widget.selectedContextAreaId ? 10 : 7,
                circleColor: const Color(0xffef6c00).toARGB32(),
                circleStrokeColor: Colors.white.toARGB32(),
                circleStrokeWidth: 2,
                customData: {'context_area_id': area.id},
              ),
            )
            .toList(),
      );
    }

    await hazardManager.deleteAll();
    if (widget.hazards.isNotEmpty) {
      await hazardManager.createMulti(
        widget.hazards
            .map(
              (hazard) => mapbox.PolygonAnnotationOptions(
                geometry: mapbox.Polygon(
                  coordinates: hazard.rings
                      .map(
                        (ring) => ring
                            .map(
                              (point) => mapbox.Position(
                                point.longitude,
                                point.latitude,
                              ),
                            )
                            .toList(),
                      )
                      .toList(),
                ),
                fillColor: const Color(0xffb3261e).toARGB32(),
                fillOpacity: 0.22,
                fillOutlineColor: const Color(0xff7f0000).toARGB32(),
                customData: {'hazard_id': hazard.id},
              ),
            )
            .toList(),
      );
    }

    await routeManager.deleteAll();
    if (widget.routes.isNotEmpty) {
      await routeManager.createMulti(
        widget.routes
            .map(
              (route) => mapbox.PolylineAnnotationOptions(
                geometry: mapbox.LineString(
                  coordinates: route.geometry
                      .map(
                        (point) =>
                            mapbox.Position(point.longitude, point.latitude),
                      )
                      .toList(),
                ),
                lineJoin: mapbox.LineJoin.ROUND,
                lineColor:
                    (route.id == widget.selectedRouteId
                            ? const Color(0xff6750a4)
                            : const Color(0xff5f6368))
                        .toARGB32(),
                lineWidth: route.id == widget.selectedRouteId ? 8 : 4,
                lineOpacity: route.id == widget.selectedRouteId ? 1 : 0.8,
                lineSortKey: route.id == widget.selectedRouteId ? 1 : 0,
                customData: {'route_id': route.id},
              ),
            )
            .toList(),
      );
    }

    await sosManager.deleteAll();
    final events = _sosEvents;
    final mappedEvents = events
        .where((event) => event.hasLocation)
        .map(
          (event) => mapbox.CircleAnnotationOptions(
            geometry: _point(
              sosBleMapCoordinate(event)!.longitude,
              sosBleMapCoordinate(event)!.latitude,
            ),
            circleRadius: event.eventId == widget.selectedEventId ? 17 : 12,
            circleColor: event.eventId == widget.activeEvent?.eventId
                ? const Color(0xffef6c00).toARGB32()
                : const Color(0xffd32f2f).toARGB32(),
            circleStrokeColor: Colors.white.toARGB32(),
            circleStrokeWidth: event.eventId == widget.selectedEventId ? 4 : 2,
            customData: {
              'sos_event_id': event.eventId,
              'active_broadcast': event.eventId == widget.activeEvent?.eventId,
              'relayed': event.isRelayed,
              'latitude': event.latitude!,
              'longitude': event.longitude!,
              'google_maps_url': sosBleGoogleMapsUrl(event)!,
            },
          ),
        )
        .toList();
    if (mappedEvents.isNotEmpty) {
      await sosManager.createMulti(mappedEvents);
    }
    if (widget.focusedEventId == null) _cameraFocusedEventId = null;
    final focusedEvent = events.where(
      (event) => event.eventId == widget.focusedEventId && event.hasLocation,
    );
    if (focusedEvent.isNotEmpty &&
        widget.focusedEventId != _cameraFocusedEventId) {
      final coordinate = sosBleMapCoordinate(focusedEvent.first)!;
      await _map?.setCamera(
        mapbox.CameraOptions(
          center: _point(coordinate.longitude, coordinate.latitude),
          zoom: 14,
        ),
      );
      _cameraFocusedEventId = widget.focusedEventId;
    }
  }

  Future<void> _handleLocationTap() async {
    final location = widget.location;
    if (location == null) return;
    try {
      await _map?.setCamera(
        mapbox.CameraOptions(
          center: _point(location.longitude, location.latitude),
          zoom: 14,
        ),
      );
    } catch (_) {
      // Keep the detail action available when the map cannot move.
    }
    if (mounted) widget.onLocationSelected?.call();
  }

  mapbox.Point _point(double longitude, double latitude) =>
      mapbox.Point(coordinates: mapbox.Position(longitude, latitude));
}

final class _MapLegendEntry {
  const _MapLegendEntry({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.title, required this.entries});

  final String title;
  final List<_MapLegendEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Card(
        key: const ValueKey('map-layer-legend'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              for (final entry in entries) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(entry.icon, color: entry.color, size: 18),
                    const SizedBox(width: 6),
                    Flexible(child: Text(entry.label)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

({double longitude, double latitude})? sosBleMapCoordinate(SosBleEvent event) {
  if (!event.hasLocation) return null;
  return (longitude: event.longitude!, latitude: event.latitude!);
}

bool isFatalMapLoadError(mapbox.MapLoadErrorType type) =>
    type == mapbox.MapLoadErrorType.STYLE;
