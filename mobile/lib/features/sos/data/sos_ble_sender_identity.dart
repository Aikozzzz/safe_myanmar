import 'dart:convert';
import 'dart:math';

import '../../profile/data/secure_local_profile_repository.dart';
import '../domain/sos_ble.dart';

abstract interface class SosBleSenderIdentitySource {
  Future<SosBleSenderMetadata> next({DateTime? now});
}

final class SosBleSenderIdentityStore implements SosBleSenderIdentitySource {
  const SosBleSenderIdentityStore(this._storage);

  static const storageKey = 'sos_ble_sender_identity_v1';

  final SecureStorageDriver _storage;

  @override
  Future<SosBleSenderMetadata> next({DateTime? now}) async {
    final currentTime = (now ?? DateTime.now()).toUtc();
    final day = currentTime.millisecondsSinceEpoch ~/ _dayMilliseconds;
    final existing = await _read();
    final sameDay = existing?['day'] == day;
    final previousSequence = sameDay && existing?['sequence'] is int
        ? existing!['sequence'] as int
        : -1;
    final token =
        sameDay &&
            previousSequence < sosBleEventSequenceMaximum &&
            _validToken(existing?['token'] as String?)
        ? existing!['token'] as String
        : _newToken();
    final sequence = previousSequence >= sosBleEventSequenceMaximum
        ? 0
        : previousSequence + 1;
    await _storage.write(
      storageKey,
      jsonEncode({'day': day, 'token': token, 'sequence': sequence}),
    );
    return SosBleSenderMetadata(senderToken: token, eventSequence: sequence);
  }

  Future<Map<String, Object?>?> _read() async {
    final encoded = await _storage.read(storageKey);
    if (encoded == null) return null;
    try {
      final value = jsonDecode(encoded);
      if (value is! Map) return null;
      return value.map<String, Object?>(
        (key, value) => MapEntry('$key', value),
      );
    } on Object {
      return null;
    }
  }

  bool _validToken(String? value) =>
      value != null &&
      value.length == sosBleSenderTokenLength &&
      RegExp(r'^[0-9a-f]+$').hasMatch(value);

  String _newToken() {
    final random = Random.secure();
    return List<int>.generate(
      4,
      (_) => random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  }

  static const _dayMilliseconds = 24 * 60 * 60 * 1000;
}
