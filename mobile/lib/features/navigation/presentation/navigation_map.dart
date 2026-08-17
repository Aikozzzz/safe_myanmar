import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../../location/domain/foreground_location.dart';
import '../domain/navigation_models.dart';

class NavigationMap extends StatefulWidget {
  const NavigationMap({
    required this.accessToken,
    required this.location,
    required this.shelters,
    required this.contextAreas,
    required this.selectedContextAreaId,
    required this.hazards,
    required this.routes,
    required this.selectedRouteId,
    required this.semanticsLabel,
    required this.errorTitle,
    required this.errorDescription,
    required this.retryLabel,
    super.key,
  });

  final String accessToken;
  final ForegroundLocation location;
  final List<Shelter> shelters;
  final List<ContextArea> contextAreas;
  final String? selectedContextAreaId;
  final List<Hazard> hazards;
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
  Future<void>? _managerInitialization;
  Future<void> _pendingUpdate = Future.value();
  bool _loadFailed = false;
  var _mapGeneration = 0;

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
    return Semantics(
      label: widget.semanticsLabel,
      container: true,
      child: SizedBox(
        height: 300,
        child: mapbox.MapWidget(
          key: ValueKey('mapbox-map-widget-$_mapGeneration'),
          // Claim map gestures so the surrounding ListView does not consume
          // drags before Mapbox can pan, zoom, or rotate the map.
          gestureRecognizers: {
            Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
          },
          viewport: mapbox.CameraViewportState(
            center: _point(widget.location.longitude, widget.location.latitude),
            zoom: 12,
          ),
          onMapCreated: (map) => _map = map,
          onStyleLoadedListener: (_) => _ensureManagers(),
          onMapLoadErrorListener: _onMapLoadError,
        ),
      ),
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
    setState(() {
      _map = null;
      _locationManager = null;
      _shelterManager = null;
      _hazardManager = null;
      _routeManager = null;
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
    if (!mounted ||
        locationManager == null ||
        shelterManager == null ||
        hazardManager == null ||
        routeManager == null) {
      return;
    }

    await locationManager.deleteAll();
    await locationManager.create(
      mapbox.CircleAnnotationOptions(
        geometry: _point(widget.location.longitude, widget.location.latitude),
        circleRadius: 9,
        circleColor: const Color(0xff145da0).toARGB32(),
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 3,
      ),
    );

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
  }

  mapbox.Point _point(double longitude, double latitude) =>
      mapbox.Point(coordinates: mapbox.Position(longitude, latitude));
}

bool isFatalMapLoadError(mapbox.MapLoadErrorType type) =>
    type == mapbox.MapLoadErrorType.STYLE;
