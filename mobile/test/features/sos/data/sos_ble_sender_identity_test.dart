import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/data/secure_local_profile_repository.dart';
import 'package:mobile/features/sos/data/sos_ble_sender_identity.dart';

void main() {
  test('increments a stable sender sequence within one UTC day', () async {
    final storage = _FakeSecureStorageDriver();
    final identities = SosBleSenderIdentityStore(storage);
    final first = await identities.next(now: DateTime.utc(2026, 8, 28, 9));
    final second = await identities.next(now: DateTime.utc(2026, 8, 28, 10));

    expect(first.senderToken, hasLength(8));
    expect(second.senderToken, first.senderToken);
    expect(first.eventSequence, 0);
    expect(second.eventSequence, 1);
  });

  test('rotates the sender token at the next UTC day', () async {
    final storage = _FakeSecureStorageDriver();
    final identities = SosBleSenderIdentityStore(storage);
    final first = await identities.next(now: DateTime.utc(2026, 8, 28, 23));
    final nextDay = await identities.next(now: DateTime.utc(2026, 8, 29));

    expect(nextDay.senderToken, isNot(first.senderToken));
    expect(nextDay.eventSequence, 0);
  });

  test(
    'rotates the sender token when the daily sequence is exhausted',
    () async {
      final storage = _FakeSecureStorageDriver();
      final now = DateTime.utc(2026, 8, 28, 12);
      final day = now.millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000);
      storage.value = jsonEncode({
        'day': day,
        'token': '00112233',
        'sequence': 0xffff,
      });

      final identity = await SosBleSenderIdentityStore(storage).next(now: now);

      expect(identity.senderToken, isNot('00112233'));
      expect(identity.eventSequence, 0);
    },
  );
}

final class _FakeSecureStorageDriver implements SecureStorageDriver {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async {
    this.value = value;
  }

  @override
  Future<void> delete(String key) async {
    value = null;
  }
}
