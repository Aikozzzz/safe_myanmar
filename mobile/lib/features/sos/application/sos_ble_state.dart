import '../domain/sos_ble.dart';

final class SosBleState {
  const SosBleState({
    this.supported,
    this.listening = false,
    this.broadcastStatus = SosBleBroadcastStatus.idle,
    this.activeEventId,
    this.nearbyEvents = const [],
    this.soundEnabled = false,
    this.error,
  });

  final bool? supported;
  final bool listening;
  final SosBleBroadcastStatus broadcastStatus;
  final String? activeEventId;
  final List<SosBleEvent> nearbyEvents;
  final bool soundEnabled;
  final String? error;

  bool get isBroadcasting =>
      broadcastStatus == SosBleBroadcastStatus.starting ||
      broadcastStatus == SosBleBroadcastStatus.active;

  SosBleState copyWith({
    Object? supported = _unset,
    bool? listening,
    SosBleBroadcastStatus? broadcastStatus,
    Object? activeEventId = _unset,
    List<SosBleEvent>? nearbyEvents,
    bool? soundEnabled,
    Object? error = _unset,
  }) => SosBleState(
    supported: identical(supported, _unset)
        ? this.supported
        : supported as bool?,
    listening: listening ?? this.listening,
    broadcastStatus: broadcastStatus ?? this.broadcastStatus,
    activeEventId: identical(activeEventId, _unset)
        ? this.activeEventId
        : activeEventId as String?,
    nearbyEvents: nearbyEvents ?? this.nearbyEvents,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    error: identical(error, _unset) ? this.error : error as String?,
  );
}

const _unset = Object();
