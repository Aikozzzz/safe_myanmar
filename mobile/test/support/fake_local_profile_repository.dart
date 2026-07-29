import 'dart:async';

import 'package:mobile/features/profile/domain/local_profile.dart';
import 'package:mobile/features/profile/domain/local_profile_repository.dart';

final class FakeLocalProfileRepository implements LocalProfileRepository {
  LocalProfile profile = LocalProfile.empty();
  Object? readError;
  Object? writeError;
  Object? clearError;
  Completer<LocalProfile>? readCompleter;
  int reads = 0;
  int writes = 0;
  int clears = 0;
  final writtenProfiles = <LocalProfile>[];

  @override
  Future<LocalProfile> read() async {
    reads += 1;
    final completer = readCompleter;
    if (completer != null) return completer.future;
    final error = readError;
    if (error != null) throw error;
    return profile;
  }

  @override
  Future<void> write(LocalProfile value) async {
    writes += 1;
    final error = writeError;
    if (error != null) throw error;
    profile = value;
    writtenProfiles.add(value);
  }

  @override
  Future<void> clear() async {
    clears += 1;
    final error = clearError;
    if (error != null) throw error;
    profile = LocalProfile.empty();
  }
}
