import 'sos_draft.dart';

enum SosDraftReadFailureKind { unavailable, corrupt, unsupportedVersion }

final class SosDraftReadException implements Exception {
  const SosDraftReadException(this.kind);

  final SosDraftReadFailureKind kind;

  @override
  String toString() => 'SOS drafts could not be read.';
}

final class SosDraftWriteException implements Exception {
  const SosDraftWriteException();

  @override
  String toString() => 'SOS drafts could not be saved.';
}

abstract interface class SosDraftRepository {
  Future<List<SosDraft>> read();

  Future<void> write(List<SosDraft> drafts);

  Future<void> clear();
}
