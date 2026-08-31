import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/mapbox_public_access_token.dart';
import '../../../core/widgets/safe_widgets.dart';
import '../../navigation/application/navigation_state.dart';
import '../../navigation/application/providers.dart';
import '../../navigation/domain/navigation_models.dart';
import '../../navigation/presentation/navigation_map.dart';
import '../../sos/application/providers.dart';
import '../../sos/domain/sos_ble.dart';
import '../../../l10n/app_localizations.dart';
import '../application/foreground_location_state.dart';
import '../application/providers.dart';
import '../domain/foreground_location.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.microtask(
        () => ref
            .read(foregroundLocationControllerProvider.notifier)
            .restoreGrantedLocation(),
      ),
    );
    unawaited(
      Future<void>.microtask(
        () => ref.read(navigationControllerProvider.notifier).loadMapData(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = ref.watch(foregroundLocationControllerProvider);
    final controller = ref.read(foregroundLocationControllerProvider.notifier);
    final navigationState = ref.watch(navigationControllerProvider);
    final sosBleState = ref.watch(sosBleControllerProvider);
    final navigationController = ref.read(
      navigationControllerProvider.notifier,
    );
    final mapboxToken = ref.watch(mapboxPublicAccessTokenProvider);
    ref.listen(foregroundLocationControllerProvider, (previous, next) {
      if (previous?.location != next.location) {
        navigationController.updateLocation(next.location);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(strings.mapTitle)),
      body: SafeArea(
        child: SafeContent(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SafePageHeader(title: strings.locationHeading),
              const SizedBox(height: 16),
              _LocationStatusCard(state: state),
              const SizedBox(height: 20),
              if (state.phase ==
                  ForegroundLocationPhase.permissionExplanationRequired)
                _PermissionExplanation(
                  onAllow: () => controller.requestLocation(confirmed: true),
                  onNotNow: controller.dismissPermissionExplanation,
                )
              else if (_showsRequestAction(state.phase))
                FilledButton.icon(
                  onPressed: controller.requestLocation,
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    state.phase == ForegroundLocationPhase.notRequested
                        ? strings.useMyLocation
                        : strings.tryLocationAgain,
                  ),
                ),
              if (state.phase == ForegroundLocationPhase.denied ||
                  state.phase == ForegroundLocationPhase.permanentlyDenied)
                FilledButton.icon(
                  onPressed: () => _openSettings(
                    context,
                    controller.openAppSettings,
                    strings,
                  ),
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(strings.openAppSettings),
                ),
              if (state.phase == ForegroundLocationPhase.serviceDisabled)
                FilledButton.icon(
                  onPressed: () => _openSettings(
                    context,
                    controller.openLocationSettings,
                    strings,
                  ),
                  icon: const Icon(Icons.location_off_outlined),
                  label: Text(strings.openLocationSettings),
                ),
              const SizedBox(height: 20),
              _NavigationContent(
                location: state.location,
                state: navigationState,
                mapboxToken: mapboxToken,
                onRetryMapData: () =>
                    navigationController.loadMapData(force: true),
                onLocationSelected: state.location == null
                    ? null
                    : () => _showLocationDetails(
                        state.location!,
                        isLastKnown:
                            state.phase ==
                            ForegroundLocationPhase
                                .liveUnavailableWithLastKnown,
                      ),
                onAnalyzeContext: state.location == null
                    ? null
                    : () =>
                          navigationController.analyzeContext(state.location!),
                onContextAreaChanged: navigationController.selectContextArea,
                onDisasterChanged: navigationController.selectDisasterType,
                onContextScenarioChanged:
                    navigationController.selectContextScenario,
                onProfileChanged: navigationController.selectProfile,
                onRequestRoutes: state.location == null
                    ? null
                    : () => navigationController.requestRoutes(state.location!),
                onRouteSelected: navigationController.selectRoute,
                nearbyEvents: sosBleState.nearbyEvents,
                activeEvent: sosBleState.activeEvent,
                focusedEventId: sosBleState.focusedEventId,
                selectedEventId: sosBleState.selectedEventId,
                onSosEventSelected: (eventId) => ref
                    .read(sosBleControllerProvider.notifier)
                    .selectEvent(eventId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLocationDetails(
    ForegroundLocation location, {
    required bool isLastKnown,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) =>
          LocationDetailsSheet(location: location, isLastKnown: isLastKnown),
    );
  }

  bool _showsRequestAction(ForegroundLocationPhase phase) {
    return phase == ForegroundLocationPhase.notRequested ||
        phase == ForegroundLocationPhase.recoverableError ||
        phase == ForegroundLocationPhase.liveUnavailableWithLastKnown;
  }

  Future<void> _openSettings(
    BuildContext context,
    Future<bool> Function() open,
    AppLocalizations strings,
  ) async {
    if (await open() || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.couldNotOpenLocationSettings)),
    );
  }
}

class _PermissionExplanation extends StatelessWidget {
  const _PermissionExplanation({required this.onAllow, required this.onNotNow});

  final VoidCallback onAllow;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.locationPermissionExplanationTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(strings.locationPermissionExplanationDescription),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onAllow,
                  child: Text(strings.allowLocation),
                ),
                OutlinedButton(
                  onPressed: onNotNow,
                  child: Text(strings.notNow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LocationDetailsSheet extends StatelessWidget {
  const LocationDetailsSheet({
    required this.location,
    required this.isLastKnown,
    super.key,
  });

  final ForegroundLocation location;
  final bool isLastKnown;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final (precisionTitle, precisionDescription) = switch (location.precision) {
      LocationPrecision.precise => (
        strings.preciseLocationAvailable,
        strings.preciseLocationDescription,
      ),
      LocationPrecision.approximate => (
        strings.approximateLocationAvailable,
        strings.approximateLocationDescription,
      ),
    };
    final timestamp = _formatUtc(context, strings, location.timestamp);
    final time = isLastKnown
        ? strings.lastKnownLocationAt(timestamp)
        : strings.locationCapturedAt(timestamp);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.locationDetailsTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(strings.locationDetailsDescription),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LocationDetailRow(
            icon: Icons.gps_fixed,
            label: strings.locationDetailsAccuracy,
            value: precisionTitle,
            supportingText: precisionDescription,
          ),
          const Divider(),
          _LocationDetailRow(
            icon: Icons.pin_drop_outlined,
            label: strings.locationDetailsCoordinates,
            value: strings.locationCoordinates(
              location.latitude.toStringAsFixed(6),
              location.longitude.toStringAsFixed(6),
            ),
          ),
          const Divider(),
          _LocationDetailRow(
            icon: Icons.schedule_outlined,
            label: strings.locationDetailsUpdated,
            value: time,
          ),
        ],
      ),
    );
  }
}

class _LocationDetailRow extends StatelessWidget {
  const _LocationDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.supportingText,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
                if (supportingText != null) ...[
                  const SizedBox(height: 4),
                  Text(supportingText!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationContent extends StatelessWidget {
  const _NavigationContent({
    required this.location,
    required this.state,
    required this.mapboxToken,
    required this.onRetryMapData,
    required this.onLocationSelected,
    required this.onAnalyzeContext,
    required this.onContextAreaChanged,
    required this.onDisasterChanged,
    required this.onContextScenarioChanged,
    required this.onProfileChanged,
    required this.onRequestRoutes,
    required this.onRouteSelected,
    required this.nearbyEvents,
    required this.activeEvent,
    required this.focusedEventId,
    required this.selectedEventId,
    required this.onSosEventSelected,
  });

  final ForegroundLocation? location;
  final NavigationState state;
  final MapboxPublicAccessToken mapboxToken;
  final Future<void> Function() onRetryMapData;
  final VoidCallback? onLocationSelected;
  final Future<void> Function()? onAnalyzeContext;
  final ValueChanged<String> onContextAreaChanged;
  final ValueChanged<DisasterType> onDisasterChanged;
  final ValueChanged<ContextScenario> onContextScenarioChanged;
  final ValueChanged<RouteProfile> onProfileChanged;
  final Future<void> Function()? onRequestRoutes;
  final ValueChanged<String> onRouteSelected;
  final List<SosBleEvent> nearbyEvents;
  final SosBleEvent? activeEvent;
  final String? focusedEventId;
  final String? selectedEventId;
  final ValueChanged<String> onSosEventSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final shelters = state.shelters;
    final hazards = state.hazards;
    final visibleHazards = state.relevantHazards;
    final routes = state.routes?.options ?? const <RouteOption>[];
    final currentLocation = location;
    final events = [
      ?activeEvent,
      for (final event in nearbyEvents)
        if (event.eventId != activeEvent?.eventId) event,
    ];
    final selectedEvent = events.where(
      (event) => event.eventId == selectedEventId,
    );
    final displayedEvent = selectedEvent.isNotEmpty
        ? selectedEvent.first
        : events.firstOrNull;
    final mapCenter = currentLocation == null
        ? _eventMapCenter()
        : NavigationCoordinate(
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SimulationStatus(state: state),
        const SizedBox(height: 12),
        if (state.loadingMapData && shelters == null && hazards == null)
          Semantics(
            label: strings.navigationDataLoading,
            child: const Center(child: CircularProgressIndicator()),
          ),
        if (state.mapDataFailed) ...[
          _StatusMessage(
            icon: Icons.cloud_off_outlined,
            message: state.mapDataCached
                ? '${strings.navigationDataUnavailable} '
                      '${strings.navigationCachedWarning}'
                : strings.navigationDataUnavailable,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: state.loadingMapData ? null : onRetryMapData,
            icon: const Icon(Icons.refresh),
            label: Text(strings.retryNavigationData),
          ),
          const SizedBox(height: 12),
        ],
        if (mapCenter != null) ...[
          if (mapboxToken.value case final token?)
            NavigationMap(
              accessToken: token,
              location: currentLocation,
              initialCenter: mapCenter,
              shelters: state.shelters?.items ?? const [],
              contextAreas: state.contextAreas?.items ?? const [],
              selectedContextAreaId: state.selectedContextAreaId,
              hazards: visibleHazards,
              onLocationSelected: onLocationSelected,
              nearbyEvents: nearbyEvents,
              activeEvent: activeEvent,
              focusedEventId: focusedEventId,
              selectedEventId: selectedEventId,
              onSosEventSelected: onSosEventSelected,
              showAllSosLabel: strings.sosBluetoothShowAll,
              locationActionLabel: strings.locationMapAction,
              routes: routes,
              selectedRouteId: state.selectedRouteId,
              semanticsLabel: strings.mapContentSemantics,
              errorTitle: strings.mapTemporarilyUnavailableTitle,
              errorDescription: strings.mapTemporarilyUnavailableDescription,
              retryLabel: strings.retryNavigationData,
            )
          else
            _StatusMessage(
              icon: Icons.map_outlined,
              title: strings.mapConfigurationUnavailableTitle,
              message: strings.mapConfigurationUnavailableDescription,
            ),
        ],
        if (state.hazards case final hazardCollection?) ...[
          const SizedBox(height: 12),
          _HazardSummary(
            collection: hazardCollection,
            visibleHazards: visibleHazards,
          ),
        ],
        if (events.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SosMapEventSelector(
            events: events,
            selectedEventId: selectedEventId,
            onSelected: onSosEventSelected,
          ),
          if (displayedEvent case final event?) ...[
            const SizedBox(height: 8),
            _SosMapEventDetails(
              event: event,
              unverified: event.eventId != activeEvent?.eventId,
            ),
          ],
        ],
        const SizedBox(height: 16),
        _ContextAreaList(
          areas: state.contextAreas?.items ?? const [],
          selectedId: state.selectedContextAreaId,
          requested: state.contextAnalysisRequested,
          loading: state.contextAnalysisLoading,
          failed: state.contextAnalysisFailed,
          uncertaintyNotice: state.contextAreas?.uncertaintyNotice,
          onAnalyze: onAnalyzeContext,
          onSelected: onContextAreaChanged,
        ),
        if (state.contextAnalysisRequested)
          if (state.contextAreas case final contextCollection?) ...[
            const SizedBox(height: 12),
            _ContextSummary(
              collection: contextCollection,
              selectedId: state.selectedContextAreaId,
              cached: state.contextCached,
              cachedAt: state.contextCachedAt,
              visibleHazards: visibleHazards,
            ),
          ],
        if (state.contextAnalysisRequested) ...[
          const SizedBox(height: 16),
          _RouteControls(
            state: state,
            onDisasterChanged: onDisasterChanged,
            onContextScenarioChanged: onContextScenarioChanged,
            onProfileChanged: onProfileChanged,
            onRequestRoutes: onRequestRoutes,
          ),
        ],
        if (state.routeFailed) ...[
          const SizedBox(height: 12),
          _StatusMessage(
            icon: Icons.route_outlined,
            message: state.routeCached
                ? '${strings.routingUnavailable} '
                      '${strings.cachedRouteWarning}'
                : strings.routingUnavailable,
          ),
          if (state.routeCachedAt case final cachedAt?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                strings.cachedRouteAt(_formatUtc(context, strings, cachedAt)),
              ),
            ),
        ],
        if (state.loadingRoutes) ...[
          const SizedBox(height: 12),
          Semantics(
            label: strings.updatingRouteSuggestions,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
        if (state.routes case final response?) ...[
          const SizedBox(height: 12),
          if (response.options.isEmpty)
            _StatusMessage(
              icon: Icons.alt_route,
              message: strings.noRoutesReturned,
            )
          else
            for (var index = 0; index < response.options.length; index++) ...[
              _RouteCard(
                option: response.options[index],
                response: response,
                label: index == 0
                    ? strings.routeSuggested
                    : strings.routeAlternative(index),
                selected: response.options[index].id == state.selectedRouteId,
                onSelected: () => onRouteSelected(response.options[index].id),
              ),
              if (index != response.options.length - 1)
                const SizedBox(height: 8),
            ],
        ],
      ],
    );
  }

  NavigationCoordinate? _eventMapCenter() {
    final events = [?activeEvent, ...nearbyEvents];
    final event = events.where(
      (event) => event.eventId == focusedEventId && event.hasLocation,
    );
    final fallback = events.where((event) => event.hasLocation);
    final selected = event.isNotEmpty ? event.first : fallback.firstOrNull;
    final coordinate = selected == null ? null : sosBleMapCoordinate(selected);
    return coordinate == null
        ? null
        : NavigationCoordinate(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
          );
  }
}

class _SosMapEventSelector extends StatelessWidget {
  const _SosMapEventSelector({
    required this.events,
    required this.selectedEventId,
    required this.onSelected,
  });

  final List<SosBleEvent> events;
  final String? selectedEventId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.sosBluetoothMapEventsHeading,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (var index = 0; index < events.length; index++)
              Semantics(
                button: true,
                selected: events[index].eventId == selectedEventId,
                label: strings.sosBluetoothSelectEvent(index + 1),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  selected: events[index].eventId == selectedEventId,
                  leading: Icon(
                    events[index].eventId == selectedEventId
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(strings.sosBluetoothSourceLabel(index + 1)),
                  subtitle: Text(
                    events[index].hasLocation
                        ? strings.sosBluetoothGridLocation(
                            events[index].latitude!.toStringAsFixed(6),
                            events[index].longitude!.toStringAsFixed(6),
                          )
                        : strings.sosBluetoothLocationUnavailable,
                  ),
                  onTap: () => onSelected(events[index].eventId),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SosMapEventDetails extends StatelessWidget {
  const _SosMapEventDetails({required this.event, required this.unverified});

  final SosBleEvent event;
  final bool unverified;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final location = event.hasLocation
        ? strings.sosBluetoothGridLocation(
            event.latitude!.toStringAsFixed(6),
            event.longitude!.toStringAsFixed(6),
          )
        : strings.sosBluetoothLocationUnavailable;
    final status = switch (event.locationStatus) {
      SosBleLocationStatus.current => strings.sosBluetoothCurrentLocation,
      SosBleLocationStatus.lastKnown => strings.sosBluetoothLastKnownLocation,
      SosBleLocationStatus.unavailable =>
        strings.sosBluetoothLocationUnavailable,
    };
    final battery = event.batteryPercent == null
        ? strings.sosBluetoothUnknownValue
        : strings.sosBluetoothBatteryValue(event.batteryPercent!);
    final signal = event.rssi == null
        ? strings.sosBluetoothUnknownValue
        : strings.sosBluetoothRssiValue(event.rssi!);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.sosBluetoothSelectedEventHeading,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (unverified) Text(strings.sosBluetoothUnverified),
            Text(location),
            Text(status),
            Text(strings.sosBluetoothEventId(event.eventId)),
            Text(
              strings.sosBluetoothTimestamp(
                _formatUtc(context, strings, event.createdAt),
              ),
            ),
            Text(battery),
            Text(signal),
            Text(
              strings.sosBluetoothProtocol(
                event.protocolVersion,
                event.ttlMinutes,
              ),
            ),
            Text(strings.sosBluetoothRelayHops(event.hopCount)),
          ],
        ),
      ),
    );
  }
}

class _SimulationStatus extends StatelessWidget {
  const _SimulationStatus({required this.state});

  final NavigationState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final shelters = state.shelters;
    final hazards = state.hazards;
    final source = shelters?.source ?? hazards?.source;
    final notice = shelters?.uncertaintyNotice ?? hazards?.uncertaintyNotice;
    final isSimulation = source == 'SafeMyanmar Demo';
    return Semantics(
      container: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSimulation)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      strings.simulationLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
              if (isSimulation) const SizedBox(height: 8),
              Text(
                isSimulation
                    ? strings.simulationNavigationHeading
                    : strings.navigationDataHeading,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (source != null) ...[
                const SizedBox(height: 8),
                Text(strings.navigationSource(source)),
              ],
              if (shelters != null)
                Text(
                  strings.shelterDataTime(
                    _formatUtc(context, strings, shelters.dataAt),
                  ),
                ),
              if (hazards != null)
                Text(
                  strings.hazardDataTime(
                    _formatUtc(context, strings, hazards.dataAt),
                  ),
                ),
              if (state.mapDataCachedAt case final cachedAt?)
                Text(
                  strings.navigationCachedAt(
                    _formatUtc(context, strings, cachedAt),
                  ),
                ),
              if (notice != null) ...[
                const SizedBox(height: 8),
                Text(strings.uncertaintyNotice(notice)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HazardSummary extends StatelessWidget {
  const _HazardSummary({
    required this.collection,
    required this.visibleHazards,
  });

  final HazardCollection collection;
  final List<Hazard> visibleHazards;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final isSimulation = collection.source == 'SafeMyanmar Demo';
    return Semantics(
      key: const ValueKey('hazard-summary'),
      container: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.hazardSummaryTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(strings.hazardSummaryDescription),
              if (isSimulation) ...[
                const SizedBox(height: 8),
                _SimulationBadge(label: strings.simulationLabel),
              ],
              const SizedBox(height: 8),
              if (visibleHazards.isEmpty)
                Text(strings.contextSummaryNoMappedHazards)
              else
                for (final hazard in visibleHazards)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _disasterLabel(strings, hazard.disasterType),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              Text(hazard.name),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 8),
              Text(strings.navigationSource(collection.source)),
              Text(
                strings.hazardDataTime(
                  _formatUtc(context, strings, collection.dataAt),
                ),
              ),
              Text(strings.uncertaintyNotice(collection.uncertaintyNotice)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextSummary extends StatelessWidget {
  const _ContextSummary({
    required this.collection,
    required this.selectedId,
    required this.cached,
    required this.cachedAt,
    required this.visibleHazards,
  });

  final ContextAreaCollection collection;
  final String? selectedId;
  final bool cached;
  final DateTime? cachedAt;
  final List<Hazard> visibleHazards;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final selected = collection.items
        .where((area) => area.id == selectedId)
        .firstOrNull;
    final noMappedHazards =
        selected?.metrics.hazardIntersections == 0 ||
        (selected == null &&
            collection.items.isEmpty &&
            visibleHazards.isEmpty);
    final isSimulation = collection.source == 'SafeMyanmar Demo';

    return Semantics(
      key: const ValueKey('context-summary'),
      container: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.analytics_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.contextSummaryTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(strings.contextSummaryDescription),
              if (isSimulation) ...[
                const SizedBox(height: 8),
                _SimulationBadge(label: strings.simulationLabel),
              ],
              if (selected case final area?) ...[
                const SizedBox(height: 12),
                Text(
                  _disasterLabel(strings, area.disasterType),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(area.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(strings.contextDistance(area.distanceM.round())),
                if (area.disasterType == DisasterType.flood)
                  Text(
                    strings.contextElevation(
                      area.metrics.relativeElevationM.toStringAsFixed(1),
                    ),
                  )
                else
                  Text(
                    strings.contextClearance(
                      area.metrics.buildingClearanceM.round(),
                      area.metrics.treeClearanceM.round(),
                    ),
                  ),
                Text(
                  strings.routeHazardIntersections(
                    area.metrics.hazardIntersections,
                  ),
                ),
                for (final reason in area.rationale) Text('- $reason'),
              ],
              if (noMappedHazards) ...[
                const SizedBox(height: 8),
                Text(strings.contextSummaryNoMappedHazards),
              ],
              const SizedBox(height: 8),
              Text(strings.navigationSource(collection.source)),
              Text(
                strings.contextDataAt(
                  _formatUtc(context, strings, collection.dataAt),
                ),
              ),
              if (cached) Text(strings.navigationCachedWarning),
              if (cachedAt case final timestamp?)
                Text(
                  strings.navigationCachedAt(
                    _formatUtc(context, strings, timestamp),
                  ),
                ),
              Text(strings.uncertaintyNotice(collection.uncertaintyNotice)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimulationBadge extends StatelessWidget {
  const _SimulationBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}

class _RouteControls extends StatelessWidget {
  const _RouteControls({
    required this.state,
    required this.onDisasterChanged,
    required this.onContextScenarioChanged,
    required this.onProfileChanged,
    required this.onRequestRoutes,
  });

  final NavigationState state;
  final ValueChanged<DisasterType> onDisasterChanged;
  final ValueChanged<ContextScenario> onContextScenarioChanged;
  final ValueChanged<RouteProfile> onProfileChanged;
  final Future<void> Function()? onRequestRoutes;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<DisasterType>(
          initialValue: state.disasterType,
          isExpanded: true,
          decoration: InputDecoration(labelText: strings.chooseDisasterType),
          items: DisasterType.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_disasterLabel(strings, value)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onDisasterChanged(value);
          },
        ),
        if (state.disasterType == DisasterType.earthquake) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<ContextScenario>(
            initialValue: state.contextScenario,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: strings.chooseContextScenario,
            ),
            items: [
              DropdownMenuItem(
                value: ContextScenario.outdoorsAfterShaking,
                child: Text(strings.outdoorsAfterShaking),
              ),
              DropdownMenuItem(
                value: ContextScenario.general,
                child: Text(strings.activeShaking),
              ),
            ],
            onChanged: (value) {
              if (value != null) onContextScenarioChanged(value);
            },
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<RouteProfile>(
          initialValue: state.profile,
          isExpanded: true,
          decoration: InputDecoration(labelText: strings.chooseTravelProfile),
          items: RouteProfile.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_profileLabel(strings, value)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onProfileChanged(value);
          },
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed:
              state.selectedContextAreaId == null ||
                  state.loadingRoutes ||
                  onRequestRoutes == null
              ? null
              : onRequestRoutes,
          icon: const Icon(Icons.route),
          label: Text(
            state.routeFailed
                ? strings.retryRouteSuggestions
                : strings.requestRouteSuggestions,
          ),
        ),
      ],
    );
  }
}

class _ContextAreaList extends StatelessWidget {
  const _ContextAreaList({
    required this.areas,
    required this.selectedId,
    required this.requested,
    required this.loading,
    required this.failed,
    required this.uncertaintyNotice,
    required this.onAnalyze,
    required this.onSelected,
  });

  final List<ContextArea> areas;
  final String? selectedId;
  final bool requested;
  final bool loading;
  final bool failed;
  final String? uncertaintyNotice;
  final Future<void> Function()? onAnalyze;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.contextAreasHeading,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(strings.contextAreasDescription),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: loading ? null : onAnalyze,
          icon: const Icon(Icons.analytics_outlined),
          label: Text(
            loading ? strings.analyzingContext : strings.analyzeContext,
          ),
        ),
        if (failed) ...[
          const SizedBox(height: 8),
          Text(strings.contextAnalysisUnavailable),
        ],
        if (requested && !loading && areas.isEmpty) ...[
          const SizedBox(height: 8),
          Text(uncertaintyNotice ?? strings.noContextAreas),
        ],
        for (final area in areas) ...[
          const SizedBox(height: 8),
          Semantics(
            button: true,
            selected: area.id == selectedId,
            label: area.id == selectedId ? '${area.name}. Selected' : area.name,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelected(area.id),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            area.id == selectedId
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              area.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      Text(strings.contextDistance(area.distanceM.round())),
                      if (area.disasterType == DisasterType.flood)
                        Text(
                          strings.contextElevation(
                            area.metrics.relativeElevationM.toStringAsFixed(1),
                          ),
                        )
                      else
                        Text(
                          strings.contextClearance(
                            area.metrics.buildingClearanceM.round(),
                            area.metrics.treeClearanceM.round(),
                          ),
                        ),
                      for (final reason in area.rationale) Text('- $reason'),
                      Text(
                        strings.contextDataAt(
                          _formatUtc(context, strings, area.dataAt),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.option,
    required this.response,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final RouteOption option;
  final RouteSuggestions response;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final minutes = option.durationSeconds / 60;
    final duration = NumberFormat(
      '0.#',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(minutes);
    return Semantics(
      key: ValueKey('route-card-${option.id}'),
      button: true,
      selected: selected,
      label: selected ? '$label. ${strings.routeSelected}' : label,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelected,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  if (selected) Text(strings.routeSelected),
                  const SizedBox(height: 8),
                  Text(
                    strings.routeProfileValue(
                      _profileLabel(strings, option.profile),
                    ),
                  ),
                  Text(
                    strings.routeDistanceValue(
                      number.format(option.distanceM.round()),
                    ),
                  ),
                  Text(strings.routeDurationValue(duration)),
                  Text(
                    strings.routeHazardIntersections(
                      option.hazardIntersectionCount,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(strings.routeRationale(option.rationale)),
                  Text(
                    strings.routeGeneratedAt(
                      _formatUtc(context, strings, option.generatedAt),
                    ),
                  ),
                  Text(
                    strings.routeHazardDataAt(
                      _formatUtc(context, strings, option.hazardDataAt),
                    ),
                  ),
                  Text(strings.navigationSource(option.source)),
                  Text(
                    strings.routeDirectionsProvider(option.directionsProvider),
                  ),
                  Text(
                    strings.routeProfileReason(response.profileSelectionReason),
                  ),
                  const SizedBox(height: 8),
                  Text(strings.uncertaintyNotice(option.uncertaintyNotice)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.icon, required this.message, this.title});

  final IconData icon;
  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeStatusCard(icon: icon, title: title, message: message);
  }
}

String _disasterLabel(AppLocalizations strings, DisasterType value) =>
    switch (value) {
      DisasterType.earthquake => strings.earthquakeDisaster,
      DisasterType.flood => strings.floodDisaster,
      DisasterType.fire => strings.fireDisaster,
      DisasterType.cyclone => strings.cycloneDisaster,
      DisasterType.landslide => strings.landslideDisaster,
      DisasterType.severeWeather => strings.severeWeatherDisaster,
    };

String _profileLabel(AppLocalizations strings, RouteProfile value) =>
    switch (value) {
      RouteProfile.walking => strings.walkingProfile,
      RouteProfile.driving => strings.drivingProfile,
    };

String _formatUtc(
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

class _LocationStatusCard extends StatelessWidget {
  const _LocationStatusCard({required this.state});

  final ForegroundLocationState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final (icon, title, description) = switch (state.phase) {
      ForegroundLocationPhase.notRequested => (
        Icons.location_searching,
        strings.locationNotRequestedTitle,
        strings.locationExplanation,
      ),
      ForegroundLocationPhase.permissionExplanationRequired => (
        Icons.location_searching,
        strings.locationNotRequestedTitle,
        strings.locationExplanation,
      ),
      ForegroundLocationPhase.requesting => (
        Icons.location_searching,
        strings.locationRequestingTitle,
        strings.locationRequestingDescription,
      ),
      ForegroundLocationPhase.preciseAvailable => (
        Icons.my_location,
        strings.preciseLocationAvailable,
        strings.preciseLocationDescription,
      ),
      ForegroundLocationPhase.approximateAvailable => (
        Icons.location_on_outlined,
        strings.approximateLocationAvailable,
        strings.approximateLocationDescription,
      ),
      ForegroundLocationPhase.denied => (
        Icons.location_disabled_outlined,
        strings.locationPermissionDenied,
        strings.locationPermissionDeniedDescription,
      ),
      ForegroundLocationPhase.permanentlyDenied => (
        Icons.location_disabled_outlined,
        strings.locationPermissionPermanentlyDenied,
        strings.locationPermissionPermanentlyDeniedDescription,
      ),
      ForegroundLocationPhase.serviceDisabled => (
        Icons.location_off_outlined,
        strings.locationServicesDisabled,
        strings.locationServicesDisabledDescription,
      ),
      ForegroundLocationPhase.liveUnavailableWithLastKnown => (
        Icons.history,
        strings.lastKnownLocation,
        strings.lastKnownLocationDescription,
      ),
      ForegroundLocationPhase.recoverableError => (
        Icons.sync_problem_outlined,
        strings.locationRecoverableError,
        strings.locationRecoverableErrorDescription,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(description),
              if (state.phase == ForegroundLocationPhase.notRequested) ...[
                const SizedBox(height: 12),
                Text(strings.locationPrivacyDescription),
              ],
              if (state.phase == ForegroundLocationPhase.requesting) ...[
                const SizedBox(height: 20),
                Center(
                  child: Semantics(
                    label: strings.findingYourLocation,
                    excludeSemantics: true,
                    child: const CircularProgressIndicator(),
                  ),
                ),
              ],
              if (state.location case final location?) ...[
                const SizedBox(height: 16),
                Text(_formatCoordinates(context, strings, location)),
                const SizedBox(height: 8),
                Text(
                  state.phase ==
                          ForegroundLocationPhase.liveUnavailableWithLastKnown
                      ? strings.lastKnownLocationAt(
                          _formatTimestamp(
                            context,
                            strings,
                            location.timestamp,
                          ),
                        )
                      : strings.locationCapturedAt(
                          _formatTimestamp(
                            context,
                            strings,
                            location.timestamp,
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatCoordinates(
    BuildContext context,
    AppLocalizations strings,
    ForegroundLocation location,
  ) {
    final formatter = NumberFormat(
      '0.000000',
      Localizations.localeOf(context).toLanguageTag(),
    );
    return strings.locationCoordinates(
      formatter.format(location.latitude),
      formatter.format(location.longitude),
    );
  }

  String _formatTimestamp(
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
}
