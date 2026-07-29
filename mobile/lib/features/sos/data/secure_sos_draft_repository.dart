import '../../profile/data/secure_local_profile_repository.dart';
import '../domain/sos_draft.dart';
import '../domain/sos_draft_repository.dart';
import 'sos_draft_codec.dart';

final class SecureSosDraftRepository implements SosDraftRepository {
  SecureSosDraftRepository(this._storage);

  static const storageKey = 'sos_draft_queue_v1';

  final SecureStorageDriver _storage;

  @override
  Future<List<SosDraft>> read() async {
    late final String? payload;
    try {
      payload = await _storage.read(storageKey);
    } on Object {
      throw const SosDraftReadException(SosDraftReadFailureKind.unavailable);
    }
    if (payload == null) return const [];
    return SosDraftCodec.decode(payload);
  }

  @override
  Future<void> write(List<SosDraft> drafts) async {
    if (drafts.length > maxSosDrafts) throw const SosDraftWriteException();
    final payload = SosDraftCodec.encode(drafts);
    try {
      await _storage.write(storageKey, payload);
    } on Object {
      throw const SosDraftWriteException();
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(storageKey);
    } on Object {
      throw const SosDraftWriteException();
    }
  }
}
