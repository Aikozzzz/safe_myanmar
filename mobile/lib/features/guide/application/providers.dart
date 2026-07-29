import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/native_ai_platform_service.dart';
import '../../alerts/application/providers.dart';
import '../data/drift_emergency_guide_repository.dart';
import '../domain/emergency_article.dart';
import '../domain/intent_classifier.dart';
import 'assistant_controller.dart';
import 'guide_controller.dart';
import 'guide_state.dart';

final emergencyGuideRepositoryProvider = Provider<EmergencyGuideRepository>(
  (ref) => DriftEmergencyGuideRepository(ref.watch(appDatabaseProvider)),
);

final emergencyIntentClassifierProvider = Provider<EmergencyIntentClassifier>(
  (_) => const EmergencyIntentClassifier(),
);

final nativeAiServiceProvider = Provider<NativeAiService>((ref) {
  final service = NativeAiPlatformService();
  ref.onDispose(() {
    unawaited(() async {
      try {
        await service.cancel();
      } catch (_) {
        // Disposal must continue even if cancellation cannot reach the plugin.
      }
      try {
        await service.dispose();
      } catch (_) {
        // Provider teardown cannot expose or recover a native disposal failure.
      }
    }());
  });
  return service;
});

final guideControllerProvider = NotifierProvider<GuideController, GuideState>(
  GuideController.new,
);

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(
      AssistantController.new,
    );
