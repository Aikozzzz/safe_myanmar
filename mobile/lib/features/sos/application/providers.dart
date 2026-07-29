import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/application/providers.dart';
import '../data/native_sms_composer.dart';
import '../data/secure_sos_draft_repository.dart';
import '../domain/sos_draft_repository.dart';
import 'sos_draft_queue_controller.dart';
import 'sos_draft_queue_state.dart';

final sosDraftRepositoryProvider = Provider<SosDraftRepository>(
  (ref) => SecureSosDraftRepository(ref.watch(secureStorageDriverProvider)),
);

final nativeSmsComposerProvider = Provider<NativeSmsComposer>(
  (_) => UrlLauncherNativeSmsComposer(),
);

final sosClockProvider = Provider<DateTime Function()>(
  (_) =>
      () => DateTime.now().toUtc(),
);

final sosDraftIdFactoryProvider = Provider<String Function()>(
  (_) => _secureDraftId,
);

final sosDraftQueueControllerProvider =
    NotifierProvider<SosDraftQueueController, SosDraftQueueState>(
      SosDraftQueueController.new,
    );

String _secureDraftId() {
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
