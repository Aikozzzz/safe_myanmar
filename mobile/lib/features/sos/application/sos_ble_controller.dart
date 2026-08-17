import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../domain/sos_ble.dart';
import '../domain/sos_draft.dart';
import 'providers.dart';
import 'sos_ble_state.dart';

final class SosBleController extends Notifier<SosBleState> {
  late SosBlePlatformService _platform;
  final _codec = const SosBlePayloadCodec();
  StreamSubscription<Uint8List>? _payloadSubscription;

  @override
  SosBleState build() {
    _platform = ref.watch(sosBlePlatformProvider);
    _payloadSubscription = _platform.payloadStream.listen(
      _handlePayload,
      onError: (_, _) => state = state.copyWith(error: 'receiver_error'),
    );
    ref.onDispose(() {
      unawaited(_payloadSubscription?.cancel());
      unawaited(_platform.stopScan());
      unawaited(_platform.stopBroadcast());
    });
    unawaited(Future<void>.microtask(_checkSupport));
    return const SosBleState();
  }

  Future<void> setListening(bool enabled) async {
    if (!enabled) {
      await _platform.stopScan();
      state = state.copyWith(listening: false, error: null);
      return;
    }
    if (state.supported != true) {
      state = state.copyWith(error: 'unsupported');
      return;
    }
    try {
      if (!await _platform.requestPermissions()) {
        state = state.copyWith(error: 'permission_denied');
        return;
      }
      await _platform.startScan();
      state = state.copyWith(listening: true, error: null);
    } on PlatformException catch (error) {
      state = state.copyWith(error: error.code);
    } on Object {
      state = state.copyWith(error: 'scan_failed');
    }
  }

  void setSoundEnabled(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
  }

  Future<void> broadcast(SosDraft draft) async {
    if (state.supported != true) {
      state = state.copyWith(
        broadcastStatus: SosBleBroadcastStatus.failed,
        error: 'unsupported',
      );
      return;
    }
    state = state.copyWith(
      broadcastStatus: SosBleBroadcastStatus.starting,
      activeEventId: null,
      error: null,
    );
    try {
      if (!await _platform.requestPermissions()) {
        state = state.copyWith(
          broadcastStatus: SosBleBroadcastStatus.failed,
          error: 'permission_denied',
        );
        return;
      }
      final event = SosBleEvent.fromDraft(
        draftId: draft.id,
        createdAt: draft.createdAt,
        location: draft.location,
        batteryPercent: await _platform.batteryPercent(),
      );
      await _platform.startBroadcast(_codec.encode(event));
      state = state.copyWith(
        broadcastStatus: SosBleBroadcastStatus.active,
        activeEventId: event.eventId,
        error: null,
      );
    } on PlatformException catch (error) {
      state = state.copyWith(
        broadcastStatus: SosBleBroadcastStatus.failed,
        error: error.code,
      );
    } on Object {
      state = state.copyWith(
        broadcastStatus: SosBleBroadcastStatus.failed,
        error: 'broadcast_failed',
      );
    }
  }

  Future<void> stopBroadcast() async {
    try {
      await _platform.stopBroadcast();
      state = state.copyWith(
        broadcastStatus: SosBleBroadcastStatus.stopped,
        activeEventId: null,
        error: null,
      );
    } on Object {
      state = state.copyWith(
        broadcastStatus: SosBleBroadcastStatus.failed,
        error: 'broadcast_stop_failed',
      );
    }
  }

  void dismissNearbyEvent(String eventId) {
    state = state.copyWith(
      nearbyEvents: state.nearbyEvents
          .where((event) => event.eventId != eventId)
          .toList(growable: false),
    );
  }

  Future<void> _checkSupport() async {
    try {
      state = state.copyWith(supported: await _platform.isSupported());
    } on Object {
      state = state.copyWith(supported: false, error: 'unsupported');
    }
  }

  void _handlePayload(Uint8List payload) {
    try {
      final event = _codec.decode(payload);
      final age = DateTime.now().toUtc().difference(event.createdAt);
      if (age.isNegative || event.isExpired) return;
      if (state.nearbyEvents.any((item) => item.eventId == event.eventId)) {
        return;
      }
      final events = [event, ...state.nearbyEvents];
      state = state.copyWith(
        nearbyEvents: events.take(20).toList(growable: false),
        error: null,
      );
      if (state.soundEnabled) {
        unawaited(SystemSound.play(SystemSoundType.alert));
      }
    } on FormatException {
      // Invalid advertisements are ignored and never shown to users.
    }
  }
}
