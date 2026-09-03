import 'dart:convert';

import '../../profile/data/secure_local_profile_repository.dart';

final class SosPreferences {
  const SosPreferences({
    this.includeLocation = false,
    this.shareNearbySos = false,
    this.receiveNearbySos = false,
    this.relayNearbySos = false,
    this.soundEnabled = false,
    this.backgroundReceive = false,
  });

  final bool includeLocation;
  final bool shareNearbySos;
  final bool receiveNearbySos;
  final bool relayNearbySos;
  final bool soundEnabled;
  final bool backgroundReceive;

  SosPreferences copyWith({
    bool? includeLocation,
    bool? shareNearbySos,
    bool? receiveNearbySos,
    bool? relayNearbySos,
    bool? soundEnabled,
    bool? backgroundReceive,
  }) => SosPreferences(
    includeLocation: includeLocation ?? this.includeLocation,
    shareNearbySos: shareNearbySos ?? this.shareNearbySos,
    receiveNearbySos: receiveNearbySos ?? this.receiveNearbySos,
    relayNearbySos: relayNearbySos ?? this.relayNearbySos,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    backgroundReceive: backgroundReceive ?? this.backgroundReceive,
  );

  factory SosPreferences.fromJson(Object? value) {
    if (value is! Map) return const SosPreferences();
    bool readBool(String key) => value[key] == true;
    return SosPreferences(
      includeLocation: readBool('include_location'),
      shareNearbySos: readBool('share_nearby_sos'),
      receiveNearbySos: readBool('receive_nearby_sos'),
      relayNearbySos: readBool('relay_nearby_sos'),
      soundEnabled: readBool('sound_enabled'),
      backgroundReceive: readBool('background_receive'),
    );
  }

  Map<String, Object> toJson() => {
    'include_location': includeLocation,
    'share_nearby_sos': shareNearbySos,
    'receive_nearby_sos': receiveNearbySos,
    'relay_nearby_sos': relayNearbySos,
    'sound_enabled': soundEnabled,
    'background_receive': backgroundReceive,
  };
}

abstract interface class SosPreferencesStore {
  Future<SosPreferences> read();

  Future<void> write(SosPreferences preferences);
}

final class SecureSosPreferencesStore implements SosPreferencesStore {
  const SecureSosPreferencesStore(this._storage);

  static const storageKey = 'sos_preferences_v1';

  final SecureStorageDriver _storage;

  @override
  Future<SosPreferences> read() async {
    final payload = await _storage.read(storageKey);
    if (payload == null) return const SosPreferences();
    try {
      return SosPreferences.fromJson(jsonDecode(payload));
    } on Object {
      return const SosPreferences();
    }
  }

  @override
  Future<void> write(SosPreferences preferences) =>
      _storage.write(storageKey, jsonEncode(preferences.toJson()));
}
