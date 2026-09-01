import 'package:flutter/services.dart';

enum NativeAiStatus { success, unavailable, error }

enum NativeAiReason {
  modelMissing,
  modelInvalid,
  runtimeError,
  unsupported,
  insufficientResources,
  invalidRequest,
  criticalIntent,
}

final class NativeAiCapability {
  const NativeAiCapability({
    required this.available,
    this.reason,
    this.modelVersion,
  });

  final bool available;
  final NativeAiReason? reason;
  final String? modelVersion;
}

final class NativeAiCapabilities {
  const NativeAiCapabilities({required this.tier2, required this.tier3});

  final NativeAiCapability tier2;
  final NativeAiCapability tier3;
}

final class NativeIntentClassification {
  const NativeIntentClassification({
    required this.intent,
    required this.confidence,
  });

  final String intent;
  final double confidence;
}

final class NativeVerifiedRewrite {
  const NativeVerifiedRewrite(this.text);

  final String text;
}

final class NativeAiAction {
  const NativeAiAction();
}

final class NativeAiResult<T> {
  const NativeAiResult._({required this.status, this.value, this.reason});

  const NativeAiResult.success(T value)
    : this._(status: NativeAiStatus.success, value: value);

  const NativeAiResult.unavailable(NativeAiReason reason)
    : this._(status: NativeAiStatus.unavailable, reason: reason);

  const NativeAiResult.error(NativeAiReason reason)
    : this._(status: NativeAiStatus.error, reason: reason);

  final NativeAiStatus status;
  final T? value;
  final NativeAiReason? reason;

  bool get shouldUseDartFallback => status != NativeAiStatus.success;
}

abstract interface class NativeAiService {
  Future<NativeAiCapabilities> capabilities();

  Future<NativeAiResult<NativeIntentClassification>> classifyIntent(
    String text,
  );

  Future<NativeAiResult<NativeAiAction>> initializeGemma();

  Future<NativeAiResult<NativeVerifiedRewrite>> rewriteVerifiedContent({
    required String verifiedContent,
    required String source,
    required String userQuestion,
    required String intent,
    required String languageCode,
  });

  Future<NativeAiResult<NativeVerifiedRewrite>> answerQuestion({
    required String question,
    required String approvedContext,
    required String languageCode,
  });

  Future<NativeAiResult<bool>> cancel();

  Future<NativeAiResult<NativeAiAction>> dispose();
}

final class NativeAiPlatformService implements NativeAiService {
  NativeAiPlatformService([this._channel = const MethodChannel(channelName)]);

  static const channelName = 'org.safemyanmar.mobile/ai';
  final MethodChannel _channel;

  @override
  Future<NativeAiCapabilities> capabilities() async {
    final response = await _invoke('capabilities');
    if (response == null || response['status'] != 'success') {
      final reason =
          _reason(response?['reason']) ?? NativeAiReason.runtimeError;
      return NativeAiCapabilities(
        tier2: NativeAiCapability(available: false, reason: reason),
        tier3: NativeAiCapability(available: false, reason: reason),
      );
    }
    return NativeAiCapabilities(
      tier2: _capability(response['tier2']),
      tier3: _capability(response['tier3']),
    );
  }

  @override
  Future<NativeAiResult<NativeIntentClassification>> classifyIntent(
    String text,
  ) async {
    final response = await _invoke('classifyIntent', {'text': text});
    return _result(response, (map) {
      final intent = map['intent'];
      final confidence = map['confidence'];
      if (intent is! String || confidence is! num) return null;
      return NativeIntentClassification(
        intent: intent,
        confidence: confidence.toDouble(),
      );
    });
  }

  @override
  Future<NativeAiResult<NativeAiAction>> initializeGemma() async =>
      _result(await _invoke('initializeGemma'), (_) => const NativeAiAction());

  @override
  Future<NativeAiResult<NativeVerifiedRewrite>> rewriteVerifiedContent({
    required String verifiedContent,
    required String source,
    required String userQuestion,
    required String intent,
    required String languageCode,
  }) async {
    final response = await _invoke('rewriteVerifiedContent', {
      'verifiedContent': verifiedContent,
      'source': source,
      'userQuestion': userQuestion,
      'intent': intent,
      'language': languageCode,
    });
    return _result(response, (map) {
      final text = map['text'];
      return text is String ? NativeVerifiedRewrite(text) : null;
    });
  }

  @override
  Future<NativeAiResult<NativeVerifiedRewrite>> answerQuestion({
    required String question,
    required String approvedContext,
    required String languageCode,
  }) async {
    final response = await _invoke('answerQuestion', {
      'question': question,
      'approvedContext': approvedContext,
      'language': languageCode,
    });
    return _result(response, (map) {
      final text = map['text'];
      return text is String ? NativeVerifiedRewrite(text) : null;
    });
  }

  @override
  Future<NativeAiResult<bool>> cancel() async => _result(
    await _invoke('cancel'),
    (map) => map['cancelled'] is bool ? map['cancelled'] as bool : null,
  );

  @override
  Future<NativeAiResult<NativeAiAction>> dispose() async =>
      _result(await _invoke('dispose'), (_) => const NativeAiAction());

  Future<Map<Object?, Object?>?> _invoke(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(
        method,
        arguments,
      );
    } on MissingPluginException {
      return const {'status': 'unavailable', 'reason': 'unsupported'};
    } on PlatformException {
      return const {'status': 'error', 'reason': 'runtime_error'};
    } on Object {
      return const {'status': 'error', 'reason': 'runtime_error'};
    }
  }

  NativeAiCapability _capability(Object? raw) {
    if (raw is! Map) {
      return const NativeAiCapability(
        available: false,
        reason: NativeAiReason.runtimeError,
      );
    }
    final available = raw['available'] == true;
    final reason = _reason(raw['reason']);
    final version = raw['modelVersion'];
    return NativeAiCapability(
      available: available,
      reason: available ? null : (reason ?? NativeAiReason.runtimeError),
      modelVersion: version is String ? version : null,
    );
  }

  NativeAiResult<T> _result<T>(
    Map<Object?, Object?>? response,
    T? Function(Map<Object?, Object?> map) decode,
  ) {
    if (response == null) {
      return const NativeAiResult.error(NativeAiReason.runtimeError);
    }
    final reason = _reason(response['reason']) ?? NativeAiReason.runtimeError;
    switch (response['status']) {
      case 'success':
        final value = decode(response);
        return value == null
            ? const NativeAiResult.error(NativeAiReason.runtimeError)
            : NativeAiResult.success(value);
      case 'unavailable':
        return NativeAiResult.unavailable(reason);
      default:
        return NativeAiResult.error(reason);
    }
  }

  NativeAiReason? _reason(Object? raw) => switch (raw) {
    'model_missing' => NativeAiReason.modelMissing,
    'model_invalid' => NativeAiReason.modelInvalid,
    'runtime_error' => NativeAiReason.runtimeError,
    'unsupported' => NativeAiReason.unsupported,
    'insufficient_resources' => NativeAiReason.insufficientResources,
    'invalid_request' => NativeAiReason.invalidRequest,
    'critical_intent' => NativeAiReason.criticalIntent,
    _ => null,
  };
}
