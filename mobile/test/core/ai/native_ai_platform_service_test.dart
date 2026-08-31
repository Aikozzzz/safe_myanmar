import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/ai/native_ai_platform_service.dart';
import 'package:mobile/features/guide/application/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('org.safemyanmar.mobile/ai.test');
  const providerChannel = MethodChannel(NativeAiPlatformService.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late NativeAiPlatformService service;

  setUp(() {
    service = NativeAiPlatformService(channel);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(providerChannel, null);
  });

  test('maps missing models to typed unavailable capabilities', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'capabilities');
      return {
        'status': 'success',
        'tier2': {'available': false, 'reason': 'model_missing'},
        'tier3': {'available': false, 'reason': 'unsupported'},
      };
    });

    final capabilities = await service.capabilities();

    expect(capabilities.tier2.available, isFalse);
    expect(capabilities.tier2.reason, NativeAiReason.modelMissing);
    expect(capabilities.tier3.available, isFalse);
    expect(capabilities.tier3.reason, NativeAiReason.unsupported);
  });

  test('marks unavailable classification for Dart fallback', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      return {'status': 'unavailable', 'reason': 'model_missing'};
    });

    final result = await service.classifyIntent('earthquake question');

    expect(result.status, NativeAiStatus.unavailable);
    expect(result.reason, NativeAiReason.modelMissing);
    expect(result.shouldUseDartFallback, isTrue);
    expect(result.value, isNull);
  });

  test('redacts platform exception details into runtime_error', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(
        code: 'native_failure',
        message: 'private prompt, output, and model path',
        details: 'sensitive user content',
      );
    });

    final result = await service.classifyIntent('private question');

    expect(result.status, NativeAiStatus.error);
    expect(result.reason, NativeAiReason.runtimeError);
    expect(result.shouldUseDartFallback, isTrue);
    expect(result.value, isNull);
  });

  test('sends only the bounded rewrite contract fields', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return {'status': 'unavailable', 'reason': 'critical_intent'};
    });

    final result = await service.rewriteVerifiedContent(
      verifiedContent: 'Reviewed content',
      source: 'Reviewed source',
      userQuestion: 'Can this be simpler?',
      intent: 'first_aid',
      languageCode: 'en',
    );

    expect(received?.method, 'rewriteVerifiedContent');
    expect(received?.arguments, {
      'verifiedContent': 'Reviewed content',
      'source': 'Reviewed source',
      'userQuestion': 'Can this be simpler?',
      'intent': 'first_aid',
      'language': 'en',
    });
    expect(result.status, NativeAiStatus.unavailable);
    expect(result.reason, NativeAiReason.criticalIntent);
    expect(result.shouldUseDartFallback, isTrue);
  });

  test('malformed success response fails closed without content', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      return {'status': 'success', 'text': 42};
    });

    final result = await service.rewriteVerifiedContent(
      verifiedContent: 'Reviewed content',
      source: 'Reviewed source',
      userQuestion: 'Simplify this',
      intent: 'general_information',
      languageCode: 'en',
    );

    expect(result.status, NativeAiStatus.error);
    expect(result.reason, NativeAiReason.runtimeError);
    expect(result.value, isNull);
  });

  test('sends the general Gemma question contract', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return {'status': 'success', 'text': 'answer'};
    });

    final result = await service.answerQuestion(
      question: 'What is the difference between a flood and an earthquake?',
      approvedContext: '[flood] Flood overview',
      languageCode: 'en',
    );

    expect(received?.method, 'answerQuestion');
    expect(received?.arguments, {
      'question': 'What is the difference between a flood and an earthquake?',
      'approvedContext': '[flood] Flood overview',
      'language': 'en',
    });
    expect(result.status, NativeAiStatus.success);
    expect(result.value?.text, 'answer');
  });

  test('Riverpod provider cancels then disposes native resources', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(providerChannel, (call) async {
      calls.add(call.method);
      return switch (call.method) {
        'cancel' => {'status': 'success', 'cancelled': true},
        'dispose' => {'status': 'success'},
        _ => {'status': 'error', 'reason': 'invalid_request'},
      };
    });
    final container = ProviderContainer();

    container.read(nativeAiServiceProvider);
    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(calls, ['cancel', 'dispose']);
  });
}
