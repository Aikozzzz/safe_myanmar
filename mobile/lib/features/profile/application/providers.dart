import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/secure_local_profile_repository.dart';
import '../domain/local_profile_repository.dart';
import 'local_profile_controller.dart';
import 'local_profile_state.dart';

final secureStorageDriverProvider = Provider<SecureStorageDriver>(
  (_) => FlutterSecureStorageDriver(),
);

final localProfileRepositoryProvider = Provider<LocalProfileRepository>(
  (ref) => SecureLocalProfileRepository(ref.watch(secureStorageDriverProvider)),
);

final contactIdFactoryProvider = Provider<String Function()>(
  (_) => _secureContactId,
);

final localProfileControllerProvider =
    NotifierProvider<LocalProfileController, LocalProfileState>(
      LocalProfileController.new,
    );

String _secureContactId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final value = bytes.map(hex).join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}
