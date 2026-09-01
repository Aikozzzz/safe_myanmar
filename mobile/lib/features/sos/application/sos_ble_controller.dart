import 'dart:async';
import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../settings/application/providers.dart';
import '../data/sos_ble_sender_identity.dart';
import '../domain/sos_ble.dart';
import '../domain/sos_draft.dart';
import 'providers.dart';
import 'sos_ble_state.dart';

final class SosBleController extends Notifier<SosBleState> {
  late SosBlePlatformService _platform;
  late SosBleSenderIdentitySource _senderIdentityStore;
  final _codec = const SosBlePayloadCodec();
  StreamSubscription<SosBleAdvertisement>? _payloadSubscription;
  StreamSubscription<String>? _notificationSubscription;
  final _seenEventIds = <String>{};
  final _originatedEventIds = <String>{};
  final _relayedEventIds = <String>{};
  final _latestEventSequenceBySender = <String, int>{};
  final _relayQueue = Queue<SosBleEvent>();
  final _expiryTimers = <String, Timer>{};
  var _relayLoopRunning = false;
  var _backgroundRestoreRunning = false;
  String? _pendingFocusEventId;
  var _disposed = false;

  @override
  SosBleState build() {
    _platform = ref.watch(sosBlePlatformProvider);
    _senderIdentityStore = ref.watch(sosBleSenderIdentityStoreProvider);
    ref.listen(languagePreferenceControllerProvider, (previous, next) {
      if (previous?.language == next.language || !state.backgroundListening) {
        return;
      }
      unawaited(_restartBackgroundScan(next.language.code));
    });
    _payloadSubscription = _platform.payloadStream.listen(
      _handleAdvertisement,
      onError: (_, _) => state = state.copyWith(error: 'receiver_error'),
    );
    _notificationSubscription = _platform.notificationEventStream.listen((
      eventId,
    ) {
      _pendingFocusEventId = eventId;
      unawaited(restoreBackgroundEvents());
    });
    ref.onDispose(() {
      _disposed = true;
      _relayQueue.clear();
      for (final timer in _expiryTimers.values) {
        timer.cancel();
      }
      _expiryTimers.clear();
      unawaited(_payloadSubscription?.cancel());
      unawaited(_notificationSubscription?.cancel());
      unawaited(_platform.stopScan());
      unawaited(_platform.stopBroadcast());
    });
    unawaited(Future<void>.microtask(_checkSupport));
    return const SosBleState();
  }

  Future<void> setListening(bool enabled) async {
    if (!enabled) {
      await _platform.stopScan();
      _relayQueue.clear();
      state = state.copyWith(
        listening: false,
        relayEnabled: false,
        error: null,
      );
      return;
    }
    if (state.supported != true) {
      state = state.copyWith(error: 'unsupported');
      return;
    }
    try {
      if (!await _platform.requestPermissions(
        receive: true,
        broadcast: false,
        background: false,
      )) {
        final permissions = await _refreshPermissions();
        state = state.copyWith(
          error: _permissionError(permissions, receive: true),
        );
        return;
      }
      await _platform.startScan();
      state = state.copyWith(
        listening: true,
        permissions: await _refreshPermissions(),
        error: null,
      );
    } on PlatformException catch (error) {
      state = state.copyWith(
        listening: false,
        relayEnabled: false,
        error: error.code,
      );
      unawaited(_refreshPermissions());
    } on Object {
      state = state.copyWith(
        listening: false,
        relayEnabled: false,
        error: 'scan_failed',
      );
      unawaited(_refreshPermissions());
    }
  }

  Future<void> setBackgroundListening(bool enabled) async {
    if (!enabled) {
      await _platform.stopBackgroundScan();
      if (_disposed) return;
      state = state.copyWith(backgroundListening: false, error: null);
      return;
    }
    if (state.supported != true) {
      state = state.copyWith(error: 'unsupported');
      return;
    }
    try {
      if (!await _platform.requestPermissions(
        receive: true,
        broadcast: false,
        background: true,
      )) {
        final permissions = await _refreshPermissions();
        state = state.copyWith(
          error: _permissionError(permissions, receive: true, background: true),
        );
        return;
      }
      await _platform.startBackgroundScan(
        languageCode: ref.read(languagePreferenceControllerProvider).language.code,
      );
      state = state.copyWith(
        backgroundListening: true,
        permissions: await _refreshPermissions(),
        error: null,
      );
      await restoreBackgroundEvents();
    } on PlatformException catch (error) {
      state = state.copyWith(backgroundListening: false, error: error.code);
      unawaited(_refreshPermissions());
    } on Object {
      state = state.copyWith(
        backgroundListening: false,
        error: 'background_scan_failed',
      );
      unawaited(_refreshPermissions());
    }
  }

  Future<void> restoreBackgroundEvents({String? notificationEventId}) async {
    if (notificationEventId != null) {
      _pendingFocusEventId = notificationEventId;
    }
    if (_backgroundRestoreRunning || _disposed) return;
    _backgroundRestoreRunning = true;
    try {
      final enabled = await _platform.isBackgroundScanEnabled();
      if (_disposed) return;
      final permissions = await _refreshPermissions();
      await _stopInvalidOperations(permissions);
      if (_disposed) return;
      if (enabled && !permissions.canBackgroundReceive) {
        await _platform.stopBackgroundScan();
        state = state.copyWith(
          backgroundListening: false,
          error: _permissionError(permissions, receive: true, background: true),
        );
        return;
      }
      state = state.copyWith(backgroundListening: enabled);
      final focusEventId =
          _pendingFocusEventId ??
          await _platform.getPendingNotificationEventId();
      _pendingFocusEventId = null;
      final advertisements = await _platform.readBackgroundAdvertisements();
      for (final advertisement in advertisements) {
        _handleAdvertisement(advertisement, allowRelay: false);
      }
      if (focusEventId != null &&
          state.nearbyEvents.any((event) => event.eventId == focusEventId)) {
        state = state.copyWith(
          focusedEventId: focusEventId,
          selectedEventId: focusEventId,
          notificationSequence: state.notificationSequence + 1,
        );
      }
    } on Object {
      if (!_disposed) state = state.copyWith(error: 'background_scan_failed');
    } finally {
      _backgroundRestoreRunning = false;
      if (_pendingFocusEventId != null && !_disposed) {
        unawaited(restoreBackgroundEvents());
      }
    }
  }

  Future<void> _restartBackgroundScan(String languageCode) async {
    if (_disposed || !state.backgroundListening) return;
    try {
      await _platform.stopBackgroundScan();
      if (_disposed || !state.backgroundListening) return;
      await _platform.startBackgroundScan(languageCode: languageCode);
    } on Object {
      if (!_disposed) state = state.copyWith(error: 'background_scan_failed');
    }
  }

  Future<void> setRelayEnabled(bool enabled) async {
    if (!enabled) {
      _relayQueue.clear();
      state = state.copyWith(relayEnabled: false, error: null);
      return;
    }
    if (state.isBroadcasting) {
      state = state.copyWith(relayEnabled: false, error: 'relay_unavailable');
      return;
    }
    if (state.supported != true) {
      state = state.copyWith(error: 'unsupported');
      return;
    }
    if (!state.listening) {
      await setListening(true);
    }
    if (!state.listening) return;
    try {
      if (!await _platform.requestPermissions(
        receive: true,
        broadcast: true,
        background: true,
      )) {
        final permissions = await _refreshPermissions();
        state = state.copyWith(
          relayEnabled: false,
          error: _permissionError(
            permissions,
            receive: true,
            broadcast: true,
            background: true,
          ),
        );
        return;
      }
      state = state.copyWith(relayEnabled: true, error: null);
    } on Object {
      state = state.copyWith(relayEnabled: false, error: 'permission_denied');
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
      activeEvent: null,
      error: null,
    );
    _relayQueue.clear();
    try {
      if (!await _platform.requestPermissions(
        receive: false,
        broadcast: true,
        background: true,
      )) {
        final permissions = await _refreshPermissions();
        state = state.copyWith(
          broadcastStatus: SosBleBroadcastStatus.failed,
          error: _permissionError(
            permissions,
            broadcast: true,
            background: true,
          ),
        );
        return;
      }
      final identity = await _senderIdentityStore.next();
      final event = SosBleEvent.fromDraft(
        draftId: draft.id,
        createdAt: draft.createdAt,
        location: draft.location,
        batteryPercent: await _platform.batteryPercent(),
        senderToken: identity.senderToken,
        eventSequence: identity.eventSequence,
      );
      _rememberEventId(_originatedEventIds, event.eventId);
      await _platform.startBroadcast(
        _codec.encode(event),
        languageCode: ref.read(languagePreferenceControllerProvider).language.code,
      );
      state = state.copyWith(
        broadcastStatus: SosBleBroadcastStatus.active,
        activeEventId: event.eventId,
        activeEvent: event,
        error: null,
      );
    } on PlatformException catch (error) {
      _removeOriginatedEvents();
      state = state.copyWith(
        broadcastStatus: SosBleBroadcastStatus.failed,
        error: error.code,
      );
    } on Object {
      _removeOriginatedEvents();
      state = state.copyWith(
        broadcastStatus: SosBleBroadcastStatus.failed,
        error: 'broadcast_failed',
      );
    }
  }

  Future<void> stopBroadcast() async {
    _relayQueue.clear();
    try {
      await _platform.stopBroadcast();
      _removeOriginatedEvents();
      state = state.copyWith(
        broadcastStatus: SosBleBroadcastStatus.stopped,
        activeEventId: null,
        activeEvent: null,
        error: null,
      );
    } on Object {
      _removeOriginatedEvents();
      state = state.copyWith(
        broadcastStatus: SosBleBroadcastStatus.failed,
        error: 'broadcast_stop_failed',
      );
    }
  }

  void dismissNearbyEvent(String eventId) {
    _removeNearbyEvent(eventId);
    if (state.focusedEventId == eventId) {
      state = state.copyWith(focusedEventId: null);
    }
  }

  void selectEvent(String? eventId) {
    if (eventId != null &&
        !state.nearbyEvents.any((event) => event.eventId == eventId) &&
        state.activeEvent?.eventId != eventId) {
      return;
    }
    state = state.copyWith(selectedEventId: eventId);
  }

  Future<void> _checkSupport() async {
    try {
      final permissions = await _platform.getPermissionState();
      if (!permissions.supported) {
        state = state.copyWith(
          supported: false,
          permissions: permissions,
          backgroundListening: false,
        );
        return;
      }
      state = state.copyWith(supported: true, permissions: permissions);
      final backgroundEnabled = await _platform.isBackgroundScanEnabled();
      if (backgroundEnabled && permissions.canBackgroundReceive) {
        await _platform.startBackgroundScan(
          languageCode:
              ref.read(languagePreferenceControllerProvider).language.code,
        );
        await restoreBackgroundEvents();
      } else if (backgroundEnabled) {
        await _platform.stopBackgroundScan();
        state = state.copyWith(
          backgroundListening: false,
          error: _permissionError(permissions, receive: true, background: true),
        );
      }
    } on Object {
      state = state.copyWith(supported: false, error: 'unsupported');
    }
  }

  void _handleAdvertisement(
    SosBleAdvertisement advertisement, {
    bool allowRelay = true,
  }) {
    try {
      final event = _codec.decode(
        advertisement.payload,
        rssi: advertisement.rssi,
      );
      final age = DateTime.now().toUtc().difference(event.createdAt);
      if (age.isNegative || event.isExpired) return;
      // A device may scan its own advertisement. The sender already shows
      // this event in its broadcast status and should not retain a peer copy.
      if (_originatedEventIds.contains(event.eventId)) return;
      final senderToken = event.senderToken;
      final eventSequence = event.eventSequence;
      SosBleEvent? replacement;
      if (senderToken != null && eventSequence != null) {
        for (final item in state.nearbyEvents) {
          if (item.senderToken == senderToken) {
            replacement = item;
            break;
          }
        }
      }
      if (senderToken != null && eventSequence != null) {
        final latestSequence = _latestEventSequenceBySender[senderToken];
        if (latestSequence != null && eventSequence <= latestSequence) return;
        _latestEventSequenceBySender[senderToken] = eventSequence;
      }
      if (!_rememberEventId(_seenEventIds, event.eventId)) {
        return;
      }
      if (replacement != null) {
        _expiryTimers.remove(replacement.eventId)?.cancel();
      }
      final events = [
        event,
        ...state.nearbyEvents.where(
          (item) => item.eventId != replacement?.eventId,
        ),
      ];
      state = state.copyWith(
        nearbyEvents: events
            .take(sosBleMaximumRetainedEvents)
            .toList(growable: false),
        selectedEventId: state.selectedEventId == replacement?.eventId
            ? event.eventId
            : state.selectedEventId,
        focusedEventId: state.focusedEventId == replacement?.eventId
            ? event.eventId
            : state.focusedEventId,
        error: null,
      );
      _scheduleExpiry(event, age);
      if (state.soundEnabled) {
        unawaited(SystemSound.play(SystemSoundType.alert));
      }
      if (allowRelay && !advertisement.background) _queueRelay(event);
    } on FormatException {
      // Invalid advertisements are ignored and never shown to users.
    } on Object {
      // Malformed platform data must not interrupt the foreground receiver.
    }
  }

  void _scheduleExpiry(SosBleEvent event, Duration age) {
    _expiryTimers.remove(event.eventId)?.cancel();
    final remaining = Duration(minutes: event.ttlMinutes) - age;
    if (remaining.isNegative || remaining == Duration.zero) return;
    _expiryTimers[event.eventId] = Timer(remaining, () {
      _expiryTimers.remove(event.eventId);
      _removeNearbyEvent(event.eventId);
    });
  }

  void _removeOriginatedEvents() {
    for (final eventId in _originatedEventIds) {
      _removeNearbyEvent(eventId);
    }
  }

  void _removeNearbyEvent(String eventId) {
    _expiryTimers.remove(eventId)?.cancel();
    if (_disposed) return;
    final events = state.nearbyEvents
        .where((event) => event.eventId != eventId)
        .toList(growable: false);
    if (events.length == state.nearbyEvents.length) return;
    state = state.copyWith(
      nearbyEvents: events,
      selectedEventId: state.selectedEventId == eventId
          ? null
          : state.selectedEventId,
    );
  }

  void _queueRelay(SosBleEvent event) {
    if (!state.relayEnabled ||
        state.isBroadcasting ||
        event.isExpired ||
        event.hopCount >= sosBleMaxRelayHops ||
        _originatedEventIds.contains(event.eventId) ||
        _relayQueue.length >= 10 ||
        _relayedEventIds.contains(event.eventId)) {
      return;
    }
    _rememberEventId(_relayedEventIds, event.eventId);
    _relayQueue.add(event.copyWithHopCount(event.hopCount + 1));
    unawaited(_drainRelayQueue());
  }

  Future<void> _drainRelayQueue() async {
    if (_relayLoopRunning) return;
    _relayLoopRunning = true;
    try {
      while (_relayQueue.isNotEmpty && state.relayEnabled) {
        final event = _relayQueue.removeFirst();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (_disposed ||
            !state.relayEnabled ||
            state.isBroadcasting ||
            event.isExpired) {
          continue;
        }
        try {
          await _platform.startRelayBroadcast(
            _codec.encode(event),
            languageCode:
                ref.read(languagePreferenceControllerProvider).language.code,
          );
          state = state.copyWith(relayCount: state.relayCount + 1, error: null);
          await Future<void>.delayed(
            const Duration(seconds: sosBleRelayDurationSeconds),
          );
          if (_disposed) break;
        } on Object {
          state = state.copyWith(error: 'relay_failed');
        }
      }
    } finally {
      _relayLoopRunning = false;
    }
  }

  bool _rememberEventId(Set<String> ids, String eventId) {
    if (!ids.add(eventId)) return false;
    while (ids.length > 512) {
      ids.remove(ids.first);
    }
    return true;
  }

  Future<SosBlePermissionState> _refreshPermissions() async {
    final permissions = await _platform.getPermissionState();
    if (!_disposed) {
      state = state.copyWith(
        supported: permissions.supported,
        permissions: permissions,
      );
    }
    return permissions;
  }

  Future<void> _stopInvalidOperations(SosBlePermissionState permissions) async {
    if (state.listening && !permissions.canReceive) {
      try {
        await _platform.stopScan();
      } on Object {
        // Stopping is best effort when the operating system already revoked
        // the scan permission.
      }
      _relayQueue.clear();
      if (!_disposed) {
        state = state.copyWith(
          listening: false,
          relayEnabled: false,
          error: _permissionError(permissions, receive: true),
        );
      }
    }
    if (state.isBroadcasting && !permissions.canBroadcast) {
      try {
        await _platform.stopBroadcast();
      } on Object {
        // The native service also stops itself after permission revocation.
      }
      _removeOriginatedEvents();
      if (!_disposed) {
        state = state.copyWith(
          broadcastStatus: SosBleBroadcastStatus.failed,
          activeEventId: null,
          activeEvent: null,
          error: _permissionError(permissions, broadcast: true),
        );
      }
    }
    if (state.backgroundListening && !permissions.canBackgroundReceive) {
      try {
        await _platform.stopBackgroundScan();
      } on Object {
        // A stopped service is safe to retry after the user changes settings.
      }
      if (!_disposed) {
        state = state.copyWith(
          backgroundListening: false,
          error: _permissionError(permissions, receive: true, background: true),
        );
      }
    }
  }

  String _permissionError(
    SosBlePermissionState permissions, {
    bool receive = false,
    bool broadcast = false,
    bool background = false,
  }) {
    if (!permissions.supported) return 'unsupported';
    if (!permissions.bluetoothEnabled) return 'bluetooth_disabled';
    if (receive && !permissions.scanGranted) return 'permission_denied';
    if (broadcast && !permissions.advertiseGranted) return 'permission_denied';
    if (background && !permissions.notificationGranted) {
      return 'notification_denied';
    }
    return 'permission_denied';
  }
}
