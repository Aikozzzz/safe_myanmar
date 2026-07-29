import 'package:mobile/core/ai/native_ai_platform_service.dart';

final class RewriteInvocation {
  const RewriteInvocation({
    required this.verifiedContent,
    required this.source,
    required this.userQuestion,
    required this.intent,
  });

  final String verifiedContent;
  final String source;
  final String userQuestion;
  final String intent;
}

final class FakeNativeAiService implements NativeAiService {
  FakeNativeAiService({
    this.capabilitiesResult = missingNativeAiCapabilities,
    this.classificationResult = const NativeAiResult.unavailable(
      NativeAiReason.modelMissing,
    ),
    this.initializationResult = const NativeAiResult.success(NativeAiAction()),
    this.rewriteResult = const NativeAiResult.unavailable(
      NativeAiReason.modelMissing,
    ),
  });

  NativeAiCapabilities capabilitiesResult;
  NativeAiResult<NativeIntentClassification> classificationResult;
  NativeAiResult<NativeAiAction> initializationResult;
  NativeAiResult<NativeVerifiedRewrite> rewriteResult;
  Future<NativeAiCapabilities> Function()? capabilitiesHandler;
  int capabilitiesCalls = 0;
  int classificationCalls = 0;
  int initializationCalls = 0;
  int rewriteCalls = 0;
  int cancelCalls = 0;
  int disposeCalls = 0;
  RewriteInvocation? lastRewrite;

  @override
  Future<NativeAiCapabilities> capabilities() async {
    capabilitiesCalls++;
    return capabilitiesHandler?.call() ?? capabilitiesResult;
  }

  @override
  Future<NativeAiResult<NativeIntentClassification>> classifyIntent(
    String text,
  ) async {
    classificationCalls++;
    return classificationResult;
  }

  @override
  Future<NativeAiResult<NativeAiAction>> initializeGemma() async {
    initializationCalls++;
    return initializationResult;
  }

  @override
  Future<NativeAiResult<NativeVerifiedRewrite>> rewriteVerifiedContent({
    required String verifiedContent,
    required String source,
    required String userQuestion,
    required String intent,
  }) async {
    rewriteCalls++;
    lastRewrite = RewriteInvocation(
      verifiedContent: verifiedContent,
      source: source,
      userQuestion: userQuestion,
      intent: intent,
    );
    return rewriteResult;
  }

  @override
  Future<NativeAiResult<bool>> cancel() async {
    cancelCalls++;
    return const NativeAiResult.success(true);
  }

  @override
  Future<NativeAiResult<NativeAiAction>> dispose() async {
    disposeCalls++;
    return const NativeAiResult.success(NativeAiAction());
  }
}

const missingNativeAiCapabilities = NativeAiCapabilities(
  tier2: NativeAiCapability(
    available: false,
    reason: NativeAiReason.modelMissing,
  ),
  tier3: NativeAiCapability(
    available: false,
    reason: NativeAiReason.modelMissing,
  ),
);

const availableNativeAiCapabilities = NativeAiCapabilities(
  tier2: NativeAiCapability(available: true, modelVersion: 'onnx-test'),
  tier3: NativeAiCapability(available: true, modelVersion: 'gemma-test'),
);
