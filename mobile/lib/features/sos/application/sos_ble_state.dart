import '../domain/sos_ble.dart';

final class SosBleState {
  const SosBleState({
    this.supported,
    this.permissions,
    this.listening = false,
    this.backgroundListening = false,
    this.broadcastStatus = SosBleBroadcastStatus.idle,
    this.activeEventId,
    this.activeEvent,
    this.nearbyEvents = const [],
    this.soundEnabled = false,
    this.relayEnabled = false,
    this.relayCount = 0,
    this.focusedEventId,
    this.selectedEventId,
    this.notificationSequence = 0,
    this.error,
  });

  final bool? supported;
  final SosBlePermissionState? permissions;
  final bool listening;
  final bool backgroundListening;
  final SosBleBroadcastStatus broadcastStatus;
  final String? activeEventId;
  final SosBleEvent? activeEvent;
  final List<SosBleEvent> nearbyEvents;
  final bool soundEnabled;
  final bool relayEnabled;
  final int relayCount;
  final String? focusedEventId;
  final String? selectedEventId;
  final int notificationSequence;
  final String? error;

  bool get isBroadcasting =>
      broadcastStatus == SosBleBroadcastStatus.starting ||
      broadcastStatus == SosBleBroadcastStatus.active;

  SosBleState copyWith({
    Object? supported = _unset,
    SosBlePermissionState? permissions,
    bool? listening,
    bool? backgroundListening,
    SosBleBroadcastStatus? broadcastStatus,
    Object? activeEventId = _unset,
    Object? activeEvent = _unset,
    List<SosBleEvent>? nearbyEvents,
    bool? soundEnabled,
    bool? relayEnabled,
    int? relayCount,
    Object? focusedEventId = _unset,
    Object? selectedEventId = _unset,
    int? notificationSequence,
    Object? error = _unset,
  }) => SosBleState(
    supported: identical(supported, _unset)
        ? this.supported
        : supported as bool?,
    permissions: permissions ?? this.permissions,
    listening: listening ?? this.listening,
    backgroundListening: backgroundListening ?? this.backgroundListening,
    broadcastStatus: broadcastStatus ?? this.broadcastStatus,
    activeEventId: identical(activeEventId, _unset)
        ? this.activeEventId
        : activeEventId as String?,
    activeEvent: identical(activeEvent, _unset)
        ? this.activeEvent
        : activeEvent as SosBleEvent?,
    nearbyEvents: nearbyEvents ?? this.nearbyEvents,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    relayEnabled: relayEnabled ?? this.relayEnabled,
    relayCount: relayCount ?? this.relayCount,
    focusedEventId: identical(focusedEventId, _unset)
        ? this.focusedEventId
        : focusedEventId as String?,
    selectedEventId: identical(selectedEventId, _unset)
        ? this.selectedEventId
        : selectedEventId as String?,
    notificationSequence: notificationSequence ?? this.notificationSequence,
    error: identical(error, _unset) ? this.error : error as String?,
  );
}

const _unset = Object();
