import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
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

enum NavigationMapMarkerKind { location, shelter, contextArea, nearbySos }

IconData navigationMapMarkerIcon(NavigationMapMarkerKind kind) =>
    switch (kind) {
      NavigationMapMarkerKind.location => Icons.my_location,
      NavigationMapMarkerKind.shelter => Icons.home_work_outlined,
      NavigationMapMarkerKind.contextArea => Icons.park_outlined,
      NavigationMapMarkerKind.nearbySos => Icons.crisis_alert,
    };

Color navigationMapMarkerColor(NavigationMapMarkerKind kind) => switch (kind) {
  NavigationMapMarkerKind.location => const Color(0xff0e7c78),
  NavigationMapMarkerKind.shelter => const Color(0xff2e7d32),
  NavigationMapMarkerKind.contextArea => const Color(0xffef6c00),
  NavigationMapMarkerKind.nearbySos => const Color(0xffd32f2f),
};

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
    this.selectedShelterId,
    this.shelterUncertaintyNotice = '',
    required this.hazards,
    this.hazardUncertaintyNotice = '',
    this.nearbyEvents = const [],
    this.activeEvent,
    this.focusedEventId,
    this.selectedEventId,
    this.onSosEventSelected,
    this.onShelterSelected,
    this.onContextAreaSelected,
    this.onRouteSelected,
    this.onSosRouteSelected,
    this.onSosRouteRequested,
    this.onLocationSelected,
    required this.showAllSosLabel,
    required this.locationActionLabel,
    required this.routes,
    required this.selectedRouteId,
    this.sosRoutes = const [],
    this.selectedSosRouteId,
    this.sosRouteEventId,
    this.sosRouteLoading = false,
    this.sosRouteFailed = false,
    required this.sosRouteLabel,
    required this.sosRouteLoadingLabel,
    required this.sosRouteShownLabel,
    required this.sosRouteUnavailableLabel,
    required this.sosRouteNeedsLocationLabel,
    required this.sosRouteExpiredLabel,
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
  final String? selectedShelterId;
  final String shelterUncertaintyNotice;
  final List<Hazard> hazards;
  final String hazardUncertaintyNotice;
  final List<SosBleEvent> nearbyEvents;
  final SosBleEvent? activeEvent;
  final String? focusedEventId;
  final String? selectedEventId;
  final ValueChanged<String>? onSosEventSelected;
  final ValueChanged<String>? onShelterSelected;
  final ValueChanged<String>? onContextAreaSelected;
  final ValueChanged<String>? onRouteSelected;
  final ValueChanged<String>? onSosRouteSelected;
  final ValueChanged<String>? onSosRouteRequested;
  final VoidCallback? onLocationSelected;
  final String showAllSosLabel;
  final String locationActionLabel;
  final List<RouteOption> routes;
  final String? selectedRouteId;
  final List<RouteOption> sosRoutes;
  final String? selectedSosRouteId;
  final String? sosRouteEventId;
  final bool sosRouteLoading;
  final bool sosRouteFailed;
  final String sosRouteLabel;
  final String sosRouteLoadingLabel;
  final String sosRouteShownLabel;
  final String sosRouteUnavailableLabel;
  final String sosRouteNeedsLocationLabel;
  final String sosRouteExpiredLabel;
  final String semanticsLabel;
  final String errorTitle;
  final String errorDescription;
  final String retryLabel;

  @override
  State<NavigationMap> createState() => _NavigationMapState();
}

class _NavigationMapState extends State<NavigationMap> {
  mapbox.MapboxMap? _map;
  mapbox.PointAnnotationManager? _locationManager;
  mapbox.PointAnnotationManager? _shelterManager;
  mapbox.PointAnnotationManager? _contextManager;
  mapbox.PolygonAnnotationManager? _hazardManager;
  mapbox.PolylineAnnotationManager? _routeManager;
  mapbox.PointAnnotationManager? _sosManager;
  mapbox.Cancelable? _locationTapEvents;
  mapbox.Cancelable? _shelterTapEvents;
  mapbox.Cancelable? _contextTapEvents;
  mapbox.Cancelable? _hazardTapEvents;
  mapbox.Cancelable? _routeTapEvents;
  mapbox.Cancelable? _sosTapEvents;
  Future<void>? _managerInitialization;
  Future<void> _pendingUpdate = Future.value();
  bool _loadFailed = false;
  var _mapGeneration = 0;
  var _legendExpanded = true;
  String? _cameraFocusedEventId;
  Map<NavigationMapMarkerKind, Uint8List>? _markerImages;
  final Set<NavigationMapLayer> _hiddenLayers = <NavigationMapLayer>{};
  _MapDetailSelection? _selectedDetail;

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
    if (_selectedDetail case final detail?
        when detail.id != null && !_detailExists(detail)) {
      _selectedDetail = null;
    }
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
                      child: NavigationMapLegend(
                        title: strings.mapLegendTitle,
                        entries: legendEntries,
                        interactionHint: strings.mapLegendInteractionHint,
                        visibleLabel: strings.mapLayerVisible,
                        hiddenLabel: strings.mapLayerHidden,
                        showLabel: strings.mapLegendShow,
                        hideLabel: strings.mapLegendHide,
                        isExpanded: _legendExpanded,
                        selectedLayer: _selectedDetail?.layer,
                        onSelected: _showLayerDetails,
                        onVisibilityChanged: _toggleLayerVisibility,
                        onToggleExpanded: () {
                          setState(() {
                            _legendExpanded = !_legendExpanded;
                          });
                        },
                      ),
                    ),
                  if (_selectedDetail case final detail?)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: _buildDetailPanel(context, strings, detail),
                    ),
                ],
              ),
            ),
          ),
          if (_locatedSosEvents.length > 1 &&
              _isLayerVisible(NavigationMapLayer.nearbySos))
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

  List<NavigationMapLegendEntry> _visibleLegendEntries(
    AppLocalizations strings,
  ) {
    final layers = visibleNavigationMapLayers(
      hasLocation: widget.location != null,
      hasShelters: widget.shelters.isNotEmpty,
      hasHazards: widget.hazards.isNotEmpty,
      hasContextAreas: widget.contextAreas.isNotEmpty,
      hasRoutes: _allRoutes.isNotEmpty,
      hasNearbySos: _locatedSosEvents.isNotEmpty,
    );
    return [
      for (final layer in layers)
        NavigationMapLegendEntry(
          layer: layer,
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
          visible: _isLayerVisible(layer),
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

  List<RouteOption> get _allRoutes => [...widget.routes, ...widget.sosRoutes];

  bool _isRouteSelected(RouteOption route) =>
      route.id == widget.selectedRouteId ||
      route.id == widget.selectedSosRouteId;

  bool _isSosRoute(RouteOption route) =>
      widget.sosRoutes.any((item) => item.id == route.id);

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
    _shelterTapEvents?.cancel();
    _contextTapEvents?.cancel();
    _hazardTapEvents?.cancel();
    _routeTapEvents?.cancel();
    _sosTapEvents?.cancel();
    super.dispose();
  }

  void _initializeLocationTapEvents() {
    _locationTapEvents?.cancel();
    _locationTapEvents = _locationManager?.tapEvents(
      onTap: (_) => unawaited(_handleLocationTap()),
    );
  }

  void _initializeShelterTapEvents() {
    _shelterTapEvents?.cancel();
    _shelterTapEvents = _shelterManager?.tapEvents(
      onTap: (annotation) {
        final shelterId = annotation.customData?['shelter_id'];
        if (shelterId is! String) return;
        widget.onShelterSelected?.call(shelterId);
        _showDetail(NavigationMapLayer.shelter, shelterId);
      },
    );
  }

  void _initializeContextTapEvents() {
    _contextTapEvents?.cancel();
    _contextTapEvents = _contextManager?.tapEvents(
      onTap: (annotation) {
        final areaId = annotation.customData?['context_area_id'];
        if (areaId is! String) return;
        widget.onContextAreaSelected?.call(areaId);
        _showDetail(NavigationMapLayer.contextArea, areaId);
      },
    );
  }

  void _initializeHazardTapEvents() {
    _hazardTapEvents?.cancel();
    _hazardTapEvents = _hazardManager?.tapEvents(
      onTap: (annotation) {
        final hazardId = annotation.customData?['hazard_id'];
        if (hazardId is String) {
          _showDetail(NavigationMapLayer.hazard, hazardId);
        }
      },
    );
  }

  void _initializeRouteTapEvents() {
    _routeTapEvents?.cancel();
    _routeTapEvents = _routeManager?.tapEvents(
      onTap: (annotation) {
        final routeId = annotation.customData?['route_id'];
        if (routeId is! String) return;
        if (widget.sosRoutes.any((route) => route.id == routeId)) {
          widget.onSosRouteSelected?.call(routeId);
        } else {
          widget.onRouteSelected?.call(routeId);
        }
        _showDetail(NavigationMapLayer.route, routeId);
      },
    );
  }

  void _initializeSosTapEvents() {
    _sosTapEvents?.cancel();
    _sosTapEvents = _sosManager?.tapEvents(
      onTap: (annotation) {
        final eventId = annotation.customData?['sos_event_id'];
        if (eventId is String) {
          widget.onSosEventSelected?.call(eventId);
          _showDetail(NavigationMapLayer.nearbySos, eventId);
        }
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
    _shelterTapEvents?.cancel();
    _shelterTapEvents = null;
    _contextTapEvents?.cancel();
    _contextTapEvents = null;
    _hazardTapEvents?.cancel();
    _hazardTapEvents = null;
    _routeTapEvents?.cancel();
    _routeTapEvents = null;
    _sosTapEvents?.cancel();
    _sosTapEvents = null;
    setState(() {
      _map = null;
      _locationManager = null;
      _shelterManager = null;
      _contextManager = null;
      _hazardManager = null;
      _routeManager = null;
      _sosManager = null;
      _managerInitialization = null;
      _loadFailed = false;
      _selectedDetail = null;
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
    _shelterManager = await map.annotations.createPointAnnotationManager(
      id: 'safe-shelters',
    );
    _contextManager = await map.annotations.createPointAnnotationManager(
      id: 'safe-context-areas',
    );
    _locationManager = await map.annotations.createPointAnnotationManager(
      id: 'safe-user-location',
    );
    _sosManager = await map.annotations.createPointAnnotationManager(
      id: 'nearby-sos-events',
    );
    _initializeLocationTapEvents();
    _initializeShelterTapEvents();
    _initializeContextTapEvents();
    _initializeHazardTapEvents();
    _initializeRouteTapEvents();
    _initializeSosTapEvents();
    await Future.wait([
      _shelterManager!.setIconAllowOverlap(true),
      _contextManager!.setIconAllowOverlap(true),
      _locationManager!.setIconAllowOverlap(true),
      _sosManager!.setIconAllowOverlap(true),
    ]);
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
    final contextManager = _contextManager;
    if (!mounted ||
        locationManager == null ||
        shelterManager == null ||
        contextManager == null ||
        hazardManager == null ||
        routeManager == null ||
        sosManager == null) {
      return;
    }
    final markerImages = await _loadMarkerImages();

    await locationManager.deleteAll();
    final location = widget.location;
    if (_isLayerVisible(NavigationMapLayer.location) && location != null) {
      await locationManager.create(
        mapbox.PointAnnotationOptions(
          geometry: _point(location.longitude, location.latitude),
          image: markerImages[NavigationMapMarkerKind.location],
          iconSize: 1,
          customData: {'location_marker': true},
        ),
      );
    }

    await shelterManager.deleteAll();
    if (_isLayerVisible(NavigationMapLayer.shelter) &&
        widget.shelters.isNotEmpty) {
      await shelterManager.createMulti(
        widget.shelters
            .map(
              (shelter) => mapbox.PointAnnotationOptions(
                geometry: _point(
                  shelter.coordinate.longitude,
                  shelter.coordinate.latitude,
                ),
                image: markerImages[NavigationMapMarkerKind.shelter],
                iconSize: shelter.id == widget.selectedShelterId ? 1.2 : 1,
                customData: {'shelter_id': shelter.id},
              ),
            )
            .toList(),
      );
    }
    await contextManager.deleteAll();
    if (_isLayerVisible(NavigationMapLayer.contextArea) &&
        widget.contextAreas.isNotEmpty) {
      await contextManager.createMulti(
        widget.contextAreas
            .map(
              (area) => mapbox.PointAnnotationOptions(
                geometry: _point(
                  area.coordinate.longitude,
                  area.coordinate.latitude,
                ),
                image: markerImages[NavigationMapMarkerKind.contextArea],
                iconSize: area.id == widget.selectedContextAreaId ? 1.2 : 1,
                customData: {'context_area_id': area.id},
              ),
            )
            .toList(),
      );
    }

    await hazardManager.deleteAll();
    if (_isLayerVisible(NavigationMapLayer.hazard) &&
        widget.hazards.isNotEmpty) {
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
    if (_isLayerVisible(NavigationMapLayer.route) && _allRoutes.isNotEmpty) {
      await routeManager.createMulti(
        _allRoutes
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
                lineColor: const Color(0xff6750a4).toARGB32(),
                lineWidth: _isRouteSelected(route) ? 8 : 4,
                lineOpacity: _isRouteSelected(route) ? 1 : 0.55,
                lineSortKey: _isRouteSelected(route) ? 1 : 0,
                customData: {'route_id': route.id},
              ),
            )
            .toList(),
      );
    }

    await sosManager.deleteAll();
    final events = _sosEvents;
    final mappedEvents = _isLayerVisible(NavigationMapLayer.nearbySos)
        ? events
              .where((event) => event.hasLocation)
              .map(
                (event) => mapbox.PointAnnotationOptions(
                  geometry: _point(
                    sosBleMapCoordinate(event)!.longitude,
                    sosBleMapCoordinate(event)!.latitude,
                  ),
                  image: markerImages[NavigationMapMarkerKind.nearbySos],
                  iconSize: event.eventId == widget.selectedEventId ? 1.3 : 1,
                  customData: {
                    'sos_event_id': event.eventId,
                    'active_broadcast':
                        event.eventId == widget.activeEvent?.eventId,
                    'relayed': event.isRelayed,
                    'latitude': event.latitude!,
                    'longitude': event.longitude!,
                    'google_maps_url': sosBleGoogleMapsUrl(event)!,
                  },
                ),
              )
              .toList()
        : const <mapbox.PointAnnotationOptions>[];
    if (mappedEvents.isNotEmpty) {
      await sosManager.createMulti(mappedEvents);
    }
    if (widget.focusedEventId == null) _cameraFocusedEventId = null;
    final focusedEvent = events.where(
      (event) => event.eventId == widget.focusedEventId && event.hasLocation,
    );
    if (_isLayerVisible(NavigationMapLayer.nearbySos) &&
        focusedEvent.isNotEmpty &&
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

  Future<Map<NavigationMapMarkerKind, Uint8List>> _loadMarkerImages() async {
    final cached = _markerImages;
    if (cached != null) return cached;
    final images = <NavigationMapMarkerKind, Uint8List>{};
    for (final kind in NavigationMapMarkerKind.values) {
      images[kind] = await _createMapMarkerImage(
        navigationMapMarkerIcon(kind),
        navigationMapMarkerColor(kind),
      );
    }
    _markerImages = images;
    return images;
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

  bool _isLayerVisible(NavigationMapLayer layer) =>
      !_hiddenLayers.contains(layer);

  void _showLayerDetails(NavigationMapLayer layer) {
    if (!mounted) return;
    setState(() {
      _selectedDetail = _MapDetailSelection(layer);
    });
  }

  void _toggleLayerVisibility(NavigationMapLayer layer) {
    if (!mounted) return;
    setState(() {
      if (!_hiddenLayers.add(layer)) _hiddenLayers.remove(layer);
      if (!_isLayerVisible(layer) && _selectedDetail?.layer == layer) {
        _selectedDetail = null;
      }
    });
    _scheduleUpdate();
  }

  void _showDetail(NavigationMapLayer layer, String id) {
    if (!mounted) return;
    setState(() {
      _selectedDetail = _MapDetailSelection(layer, id: id);
    });
  }

  bool _detailExists(_MapDetailSelection detail) => switch (detail.layer) {
    NavigationMapLayer.location => widget.location != null,
    NavigationMapLayer.shelter => widget.shelters.any(
      (shelter) => shelter.id == detail.id,
    ),
    NavigationMapLayer.hazard => widget.hazards.any(
      (hazard) => hazard.id == detail.id,
    ),
    NavigationMapLayer.contextArea => widget.contextAreas.any(
      (area) => area.id == detail.id,
    ),
    NavigationMapLayer.route => _allRoutes.any(
      (route) => route.id == detail.id,
    ),
    NavigationMapLayer.nearbySos => _sosEvents.any(
      (event) => event.eventId == detail.id,
    ),
  };

  Widget _buildDetailPanel(
    BuildContext context,
    AppLocalizations strings,
    _MapDetailSelection detail,
  ) {
    final body = _buildDetailBody(context, strings, detail);
    if (body == null) return const SizedBox.shrink();
    return _MapDetailPanel(
      title: _detailTitle(strings, detail),
      icon: navigationMapLayerIcon(detail.layer),
      onClose: () => setState(() => _selectedDetail = null),
      child: body,
    );
  }

  Widget? _buildDetailBody(
    BuildContext context,
    AppLocalizations strings,
    _MapDetailSelection detail,
  ) {
    if (detail.layer == NavigationMapLayer.location) {
      final location = widget.location;
      if (location == null) return null;
      final precision = location.precision == LocationPrecision.precise
          ? strings.sosPrecise
          : strings.sosApproximate;
      return _MapDetailTextList(
        children: [
          Text(strings.locationDetailsAccuracy),
          Text(precision),
          const SizedBox(height: 4),
          Text(strings.locationDetailsCoordinates),
          Text(
            strings.locationCoordinates(
              location.latitude.toStringAsFixed(6),
              location.longitude.toStringAsFixed(6),
            ),
          ),
          Text(strings.locationDetailsUpdated),
          Text(
            strings.locationCapturedAt(
              _mapFormatUtc(context, strings, location.timestamp),
            ),
          ),
        ],
      );
    }

    if (detail.id == null) {
      final count = switch (detail.layer) {
        NavigationMapLayer.location => widget.location == null ? 0 : 1,
        NavigationMapLayer.shelter => widget.shelters.length,
        NavigationMapLayer.hazard => widget.hazards.length,
        NavigationMapLayer.contextArea => widget.contextAreas.length,
        NavigationMapLayer.route => widget.routes.length,
        NavigationMapLayer.nearbySos => _locatedSosEvents.length,
      };
      return _MapDetailTextList(
        children: [
          Text(strings.mapLayerItemCount(count)),
          Text(strings.mapLegendInteractionHint),
        ],
      );
    }

    if (detail.layer == NavigationMapLayer.shelter) {
      final shelter = widget.shelters.where((item) => item.id == detail.id);
      if (shelter.isEmpty) return null;
      final item = shelter.first;
      return _MapDetailTextList(
        children: [
          if (item.description.isNotEmpty)
            Text(navigationUserFacingText(item.description)),
          Text(strings.locationDetailsCoordinates),
          Text(_mapCoordinateText(item.coordinate)),
          Text(
            strings.navigationSource(navigationUserFacingSource(item.source)),
          ),
          Text(
            strings.shelterDataTime(
              _mapFormatUtc(context, strings, item.dataAt),
            ),
          ),
          if (widget.shelterUncertaintyNotice.isNotEmpty)
            Text(
              strings.uncertaintyNotice(
                navigationUserFacingNotice(widget.shelterUncertaintyNotice),
              ),
            ),
        ],
      );
    }

    if (detail.layer == NavigationMapLayer.hazard) {
      final hazard = widget.hazards.where((item) => item.id == detail.id);
      if (hazard.isEmpty) return null;
      final item = hazard.first;
      return _MapDetailTextList(
        children: [
          Text(_mapDisasterLabel(strings, item.disasterType)),
          Text(
            strings.navigationSource(navigationUserFacingSource(item.source)),
          ),
          Text(
            strings.hazardDataTime(
              _mapFormatUtc(context, strings, item.dataAt),
            ),
          ),
          if (widget.hazardUncertaintyNotice.isNotEmpty)
            Text(
              strings.uncertaintyNotice(
                navigationUserFacingNotice(widget.hazardUncertaintyNotice),
              ),
            ),
        ],
      );
    }

    if (detail.layer == NavigationMapLayer.contextArea) {
      final area = widget.contextAreas.where((item) => item.id == detail.id);
      if (area.isEmpty) return null;
      final item = area.first;
      final metrics = item.metrics;
      return _MapDetailTextList(
        children: [
          Text(_mapDisasterLabel(strings, item.disasterType)),
          if (item.disasterType == DisasterType.earthquake)
            Text(_mapContextScenarioLabel(strings, item.scenario)),
          Text(strings.contextDistance(item.distanceM.round())),
          if (item.disasterType == DisasterType.earthquake) ...[
            Text(
              strings.contextClearance(
                metrics.buildingClearanceM.round(),
                metrics.treeClearanceM.round(),
              ),
            ),
            Text(
              strings.contextBuildingDensity(
                (metrics.buildingDensity * 100).toStringAsFixed(1),
              ),
            ),
            Text(
              strings.contextTreeDensity(
                (metrics.treeDensity * 100).toStringAsFixed(1),
              ),
            ),
          ],
          if (item.disasterType == DisasterType.flood)
            Text(
              strings.contextElevation(
                metrics.relativeElevationM.toStringAsFixed(1),
              ),
            ),
          Text(strings.contextHazardIntersections(metrics.hazardIntersections)),
          if (item.rationale.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              strings.contextRationaleHeading,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            for (final reason in item.rationale)
              Text(navigationUserFacingText(reason)),
          ],
          Text(
            strings.navigationSource(navigationUserFacingSource(item.source)),
          ),
          Text(
            strings.contextDataAt(_mapFormatUtc(context, strings, item.dataAt)),
          ),
          if (item.uncertaintyNotice.isNotEmpty)
            Text(
              strings.uncertaintyNotice(
                navigationUserFacingNotice(item.uncertaintyNotice),
              ),
            ),
        ],
      );
    }

    if (detail.layer == NavigationMapLayer.route) {
      final route = _allRoutes.where((item) => item.id == detail.id);
      if (route.isEmpty) return null;
      final item = route.first;
      final locale = Localizations.localeOf(context).toLanguageTag();
      final duration = NumberFormat(
        '0.#',
        locale,
      ).format(item.durationSeconds / 60);
      final distance = NumberFormat.decimalPattern(
        locale,
      ).format(item.distanceM.round());
      return _MapDetailTextList(
        children: [
          Text(
            _isRouteSelected(item)
                ? strings.routeSelected
                : _routeLabel(strings, item),
          ),
          Text(
            strings.routeProfileValue(_mapProfileLabel(strings, item.profile)),
          ),
          Text(strings.routeDistanceValue(distance)),
          Text(strings.routeDurationValue(duration)),
          Text(strings.routeHazardIntersections(item.hazardIntersectionCount)),
          Text(
            strings.routeRationale(navigationUserFacingText(item.rationale)),
          ),
          Text(
            strings.routeGeneratedAt(
              _mapFormatUtc(context, strings, item.generatedAt),
            ),
          ),
          Text(
            strings.routeHazardDataAt(
              _mapFormatUtc(context, strings, item.hazardDataAt),
            ),
          ),
          Text(
            strings.navigationSource(navigationUserFacingSource(item.source)),
          ),
          Text(strings.routeDirectionsProvider(item.directionsProvider)),
          Text(
            strings.uncertaintyNotice(
              navigationUserFacingNotice(item.uncertaintyNotice),
            ),
          ),
          if (!_isRouteSelected(item))
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed:
                    (_isSosRoute(item)
                            ? widget.onSosRouteSelected
                            : widget.onRouteSelected) ==
                        null
                    ? null
                    : () {
                        if (_isSosRoute(item)) {
                          widget.onSosRouteSelected!.call(item.id);
                        } else {
                          widget.onRouteSelected!.call(item.id);
                        }
                        _showDetail(NavigationMapLayer.route, item.id);
                      },
                icon: const Icon(Icons.check),
                label: Text(strings.mapSelectRoute),
              ),
            ),
        ],
      );
    }

    if (detail.layer == NavigationMapLayer.nearbySos) {
      final event = _sosEvents.where((item) => item.eventId == detail.id);
      if (event.isEmpty) return null;
      final item = event.first;
      final location = item.hasLocation
          ? strings.sosBluetoothGridLocation(
              item.latitude!.toStringAsFixed(6),
              item.longitude!.toStringAsFixed(6),
            )
          : strings.sosBluetoothLocationUnavailable;
      final status = switch (item.locationStatus) {
        SosBleLocationStatus.current => strings.sosBluetoothCurrentLocation,
        SosBleLocationStatus.lastKnown => strings.sosBluetoothLastKnownLocation,
        SosBleLocationStatus.unavailable =>
          strings.sosBluetoothLocationUnavailable,
      };
      final index = _sosEvents.indexWhere(
        (candidate) => candidate.eventId == item.eventId,
      );
      final routeMessage = item.isExpired
          ? widget.sosRouteExpiredLabel
          : widget.sosRouteEventId == item.eventId && widget.sosRouteFailed
          ? widget.sosRouteUnavailableLabel
          : widget.sosRouteEventId == item.eventId &&
                widget.sosRoutes.isNotEmpty
          ? widget.sosRouteShownLabel
          : null;
      return _MapDetailTextList(
        children: [
          Text(
            item.hasVerifiedDetails
                ? strings.sosBluetoothVerified
                : strings.sosBluetoothUnverified,
          ),
          Text(strings.sosBluetoothSourceLabel(index + 1)),
          Text(location),
          Text(status),
          Text(strings.sosBluetoothEventId(item.eventId)),
          Text(
            strings.sosBluetoothTimestamp(
              _mapFormatUtc(context, strings, item.createdAt),
            ),
          ),
          if (item.alias case final alias?)
            Text(strings.sosBluetoothAliasValue(alias)),
          if (item.message case final message?)
            Text(strings.sosBluetoothMessageValue(message)),
          if (item.batteryPercent case final battery?)
            Text(strings.sosBluetoothBatteryValue(battery)),
          if (item.rssi case final rssi?)
            Text(strings.sosBluetoothRssiValue(rssi)),
          Text(strings.sosBluetoothRelayHops(item.hopCount)),
          if (routeMessage case final value?) Text(value),
          if (item.isExpired)
            const SizedBox.shrink()
          else if (!item.hasLocation)
            const SizedBox.shrink()
          else if (widget.location == null)
            Text(widget.sosRouteNeedsLocationLabel)
          else
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed:
                    widget.sosRouteLoading || widget.onSosRouteRequested == null
                    ? null
                    : () => widget.onSosRouteRequested!(item.eventId),
                icon:
                    widget.sosRouteLoading &&
                        widget.sosRouteEventId == item.eventId
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.route),
                label: Text(
                  widget.sosRouteLoading &&
                          widget.sosRouteEventId == item.eventId
                      ? widget.sosRouteLoadingLabel
                      : widget.sosRouteLabel,
                ),
              ),
            ),
        ],
      );
    }

    final count = switch (detail.layer) {
      NavigationMapLayer.location => widget.location == null ? 0 : 1,
      NavigationMapLayer.shelter => widget.shelters.length,
      NavigationMapLayer.hazard => widget.hazards.length,
      NavigationMapLayer.contextArea => widget.contextAreas.length,
      NavigationMapLayer.route => _allRoutes.length,
      NavigationMapLayer.nearbySos => _locatedSosEvents.length,
    };
    return _MapDetailTextList(
      children: [
        Text(strings.mapLayerItemCount(count)),
        Text(strings.mapLegendInteractionHint),
      ],
    );
  }

  String _detailTitle(AppLocalizations strings, _MapDetailSelection detail) {
    final label = _mapLayerLabel(strings, detail.layer);
    return switch (detail.layer) {
      NavigationMapLayer.location => strings.mapLegendLocation,
      NavigationMapLayer.shelter => navigationUserFacingName(
        widget.shelters
                .where((item) => item.id == detail.id)
                .firstOrNull
                ?.name ??
            label,
      ),
      NavigationMapLayer.hazard => navigationUserFacingName(
        widget.hazards
                .where((item) => item.id == detail.id)
                .firstOrNull
                ?.name ??
            label,
      ),
      NavigationMapLayer.contextArea => navigationUserFacingName(
        widget.contextAreas
                .where((item) => item.id == detail.id)
                .firstOrNull
                ?.name ??
            label,
      ),
      NavigationMapLayer.route => _routeTitle(strings, detail.id, label),
      NavigationMapLayer.nearbySos => label,
    };
  }

  String _routeTitle(
    AppLocalizations strings,
    String? routeId,
    String fallback,
  ) {
    final route = _allRoutes.where((item) => item.id == routeId).firstOrNull;
    return route == null ? fallback : _routeLabel(strings, route);
  }

  String _routeLabel(AppLocalizations strings, RouteOption route) {
    final index = widget.routes.indexWhere((item) => item.id == route.id);
    return route.recommended
        ? strings.routeSuggested
        : strings.routeAlternative(index < 1 ? 1 : index);
  }

  mapbox.Point _point(double longitude, double latitude) =>
      mapbox.Point(coordinates: mapbox.Position(longitude, latitude));
}

final class _MapDetailSelection {
  const _MapDetailSelection(this.layer, {this.id});

  final NavigationMapLayer layer;
  final String? id;
}

final class NavigationMapLegendEntry {
  const NavigationMapLegendEntry({
    required this.layer,
    required this.icon,
    required this.label,
    required this.color,
    required this.visible,
  });

  final NavigationMapLayer layer;
  final IconData icon;
  final String label;
  final Color color;
  final bool visible;
}

class NavigationMapLegend extends StatelessWidget {
  const NavigationMapLegend({
    required this.title,
    required this.entries,
    required this.interactionHint,
    required this.visibleLabel,
    required this.hiddenLabel,
    required this.showLabel,
    required this.hideLabel,
    required this.isExpanded,
    required this.onSelected,
    required this.onVisibilityChanged,
    required this.onToggleExpanded,
    this.selectedLayer,
    super.key,
  });

  final String title;
  final List<NavigationMapLegendEntry> entries;
  final String interactionHint;
  final String visibleLabel;
  final String hiddenLabel;
  final String showLabel;
  final String hideLabel;
  final bool isExpanded;
  final NavigationMapLayer? selectedLayer;
  final ValueChanged<NavigationMapLayer> onSelected;
  final ValueChanged<NavigationMapLayer> onVisibilityChanged;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Card(
        key: const ValueKey('map-layer-legend'),
        child: isExpanded
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('map-legend-toggle'),
                          tooltip: hideLabel,
                          onPressed: onToggleExpanded,
                          icon: const Icon(Icons.visibility_off_outlined),
                        ),
                      ],
                    ),
                    for (final entry in entries)
                      Semantics(
                        button: true,
                        selected: entry.layer == selectedLayer,
                        label:
                            '${entry.label}. ${entry.visible ? visibleLabel : hiddenLabel}',
                        hint: interactionHint,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  key: ValueKey(
                                    'map-layer-${entry.layer.name}',
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => onSelected(entry.layer),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          entry.icon,
                                          color: entry.color,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(child: Text(entry.label)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: entry.visible
                                    ? visibleLabel
                                    : hiddenLabel,
                                onPressed: () =>
                                    onVisibilityChanged(entry.layer),
                                icon: Icon(
                                  entry.visible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : IconButton(
                key: const ValueKey('map-legend-toggle'),
                tooltip: showLabel,
                onPressed: onToggleExpanded,
                icon: const Icon(Icons.visibility_outlined),
              ),
      ),
    );
  }
}

class _MapDetailPanel extends StatelessWidget {
  const _MapDetailPanel({
    required this.title,
    required this.icon,
    required this.onClose,
    required this.child,
  });

  final String title;
  final IconData icon;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Card(
        elevation: 6,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 236),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 4),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapDetailTextList extends StatelessWidget {
  const _MapDetailTextList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(height: 4),
          children[index],
        ],
      ],
    );
  }
}

String _mapLayerLabel(AppLocalizations strings, NavigationMapLayer layer) =>
    switch (layer) {
      NavigationMapLayer.location => strings.mapLegendLocation,
      NavigationMapLayer.shelter => strings.mapLegendShelter,
      NavigationMapLayer.hazard => strings.mapLegendHazard,
      NavigationMapLayer.contextArea => strings.mapLegendContextArea,
      NavigationMapLayer.route => strings.mapLegendRoute,
      NavigationMapLayer.nearbySos => strings.mapLegendNearbySos,
    };

IconData navigationMapLayerIcon(NavigationMapLayer layer) => switch (layer) {
  NavigationMapLayer.location => Icons.my_location,
  NavigationMapLayer.shelter => Icons.home_work_outlined,
  NavigationMapLayer.hazard => Icons.warning_amber_outlined,
  NavigationMapLayer.contextArea => Icons.park_outlined,
  NavigationMapLayer.route => Icons.route,
  NavigationMapLayer.nearbySos => Icons.crisis_alert,
};

String _mapCoordinateText(NavigationCoordinate coordinate) =>
    '${coordinate.latitude.toStringAsFixed(6)}, '
    '${coordinate.longitude.toStringAsFixed(6)}';

String _mapFormatUtc(
  BuildContext context,
  AppLocalizations strings,
  DateTime timestamp,
) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final formatted = DateFormat.yMMMd(
    locale,
  ).add_Hms().format(timestamp.toUtc());
  return strings.utcTimestamp(formatted);
}

String navigationUserFacingNotice(String notice) {
  if (RegExp(
    r'simulation|fictional|demo',
    caseSensitive: false,
  ).hasMatch(notice)) {
    return 'Some information may be incomplete. Follow authorized local '
        'instructions when available.';
  }
  return notice.replaceAll(
    RegExp(
      r'Some environment metadata was incomplete, so confidence in this '
      r'terrain comparison is lower\.?',
      caseSensitive: false,
    ),
    'Some environment information is incomplete, so this comparison may be '
    'less reliable.',
  );
}

String navigationUserFacingText(String text) {
  if (!RegExp(
    r'simulation|fictional|demo',
    caseSensitive: false,
  ).hasMatch(text)) {
    return text;
  }
  return text
      .replaceAll(
        RegExp(r'\bthis simulation\b', caseSensitive: false),
        'current conditions',
      )
      .replaceAll(RegExp(r'\bsimulated\s*', caseSensitive: false), '')
      .replaceAll(RegExp(r'\bfictional\s*', caseSensitive: false), '')
      .replaceAll(RegExp(r'\bdemo\s*', caseSensitive: false), '')
      .replaceAll(
        RegExp(r'\bsimulation\b', caseSensitive: false),
        'current conditions',
      )
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
}

String navigationUserFacingSource(String source) {
  final normalized = source.trim();
  if (normalized.isEmpty) return normalized;
  if (RegExp(
    r'demo|simulation|fictional',
    caseSensitive: false,
  ).hasMatch(normalized)) {
    return 'SafeMyanmar';
  }
  return normalized;
}

String navigationUserFacingName(String name) => name
    .replaceFirst(RegExp(r'^\s*SIMULATION:\s*', caseSensitive: false), '')
    .trim();

String _mapDisasterLabel(AppLocalizations strings, DisasterType value) =>
    switch (value) {
      DisasterType.earthquake => strings.earthquakeDisaster,
      DisasterType.flood => strings.floodDisaster,
      DisasterType.fire => strings.fireDisaster,
      DisasterType.cyclone => strings.cycloneDisaster,
      DisasterType.landslide => strings.landslideDisaster,
      DisasterType.severeWeather => strings.severeWeatherDisaster,
    };

String _mapContextScenarioLabel(
  AppLocalizations strings,
  ContextScenario scenario,
) => switch (scenario) {
  ContextScenario.outdoorsAfterShaking => strings.outdoorsAfterShaking,
  ContextScenario.general => strings.activeShaking,
};

String _mapProfileLabel(AppLocalizations strings, RouteProfile value) =>
    switch (value) {
      RouteProfile.walking => strings.walkingProfile,
      RouteProfile.driving => strings.drivingProfile,
    };

Future<Uint8List> _createMapMarkerImage(IconData icon, Color color) async {
  const canvasSize = 64.0;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final center = const ui.Offset(canvasSize / 2, canvasSize / 2);

  void paintIcon(double size, Color iconColor) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: iconColor,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          height: 1,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - ui.Offset(painter.width / 2, painter.height / 2),
    );
  }

  // Keep the symbol readable over both light and satellite map styles.
  paintIcon(45, Colors.white);
  paintIcon(36, color);

  final image = await recorder.endRecording().toImage(
    canvasSize.toInt(),
    canvasSize.toInt(),
  );
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (byteData == null) throw StateError('Could not render map marker.');
  return Uint8List.fromList(
    byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
  );
}

({double longitude, double latitude})? sosBleMapCoordinate(SosBleEvent event) {
  if (!event.hasLocation) return null;
  return (longitude: event.longitude!, latitude: event.latitude!);
}

bool isFatalMapLoadError(mapbox.MapLoadErrorType type) =>
    type == mapbox.MapLoadErrorType.STYLE;
