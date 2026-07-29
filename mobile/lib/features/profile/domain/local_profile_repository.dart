import 'local_profile.dart';

enum LocalProfileReadFailureKind { unavailable, corrupt, unsupportedVersion }

final class LocalProfileReadException implements Exception {
  const LocalProfileReadException(this.kind);

  final LocalProfileReadFailureKind kind;

  @override
  String toString() => 'Local profile could not be read.';
}

final class LocalProfileWriteException implements Exception {
  const LocalProfileWriteException();

  @override
  String toString() => 'Local profile could not be saved.';
}

abstract interface class LocalProfileRepository {
  Future<LocalProfile> read();

  Future<void> write(LocalProfile profile);

  Future<void> clear();
}
