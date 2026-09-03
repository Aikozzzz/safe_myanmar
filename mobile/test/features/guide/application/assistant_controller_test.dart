import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/ai/native_ai_platform_service.dart';
import 'package:mobile/features/guide/application/assistant_controller.dart';
import 'package:mobile/features/guide/application/providers.dart';
import 'package:mobile/features/guide/domain/intent_classifier.dart';
import 'package:mobile/features/settings/application/language_preference_controller.dart';
import 'package:mobile/features/settings/application/providers.dart';
import 'package:mobile/features/settings/domain/app_language.dart';

import '../../../support/fake_emergency_guide_repository.dart';
import '../../../support/fake_language_preference_repository.dart';
import '../../../support/fake_native_ai_service.dart';

void main() {
  test(
    'returns approved article verbatim with exact attribution offline',
    () async {
      final repository = FakeEmergencyGuideRepository();
      final nativeAi = FakeNativeAiService();
      final container = ProviderContainer(
        overrides: [
          emergencyGuideRepositoryProvider.overrideWithValue(repository),
          nativeAiServiceProvider.overrideWithValue(nativeAi),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(assistantControllerProvider.notifier)
          .send('first aid for an injured person');
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(reply.replyKind, AssistantReplyKind.article);
      expect(reply.article!.answerEn, 'APPROVED FIRST AID ANSWER');
      expect(reply.article!.sourceName, 'American Red Cross');
      expect(
        reply.article!.sourceUrl,
        'https://www.redcross.org/take-a-class/first-aid/performing-first-aid/first-aid-steps',
      );
      expect(reply.article!.contentVersion, 1);
      expect(
        reply.text,
        isNull,
        reason: 'assistant must not generate medical text',
      );
      expect(reply.responseEngine, AssistantResponseEngine.deterministic);
      expect(nativeAi.classificationCalls, 0);
      expect(nativeAi.rewriteCalls, 0, reason: 'first aid is critical');
    },
  );

  test(
    'clearly returns unknown and never calls a network dependency',
    () async {
      final container = ProviderContainer(
        overrides: [
          emergencyGuideRepositoryProvider.overrideWithValue(
            FakeEmergencyGuideRepository(),
          ),
          nativeAiServiceProvider.overrideWithValue(FakeNativeAiService()),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(assistantControllerProvider.notifier)
          .send('tell me a joke');
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(reply.result!.intent, EmergencyIntent.unknown);
      expect(reply.replyKind, AssistantReplyKind.unknown);
      expect(reply.article, isNull);
      expect(reply.sosDraft, isNull);
    },
  );

  test(
    'missing optional models retain deterministic unknown fallback',
    () async {
      final nativeAi = FakeNativeAiService(
        classificationResult: const NativeAiResult.success(
          NativeIntentClassification(intent: 'fire', confidence: 0.99),
        ),
      );
      final container = _container(nativeAi);
      addTearDown(container.dispose);
      await _loadCapabilities(container);

      await container
          .read(assistantControllerProvider.notifier)
          .send('tell me a joke');
      final state = container.read(assistantControllerProvider);
      final reply = state.messages.last;

      expect(reply.result!.intent, EmergencyIntent.unknown);
      expect(reply.responseEngine, AssistantResponseEngine.deterministic);
      expect(nativeAi.classificationCalls, 0);
      expect(state.onnxStatus, AssistantCapabilityStatus.unavailable);
      expect(state.gemmaStatus, AssistantCapabilityStatus.unavailable);
    },
  );

  test('general disaster comparisons do not create an SOS draft', () async {
    final container = _container(FakeNativeAiService());
    addTearDown(container.dispose);

    await container
        .read(assistantControllerProvider.notifier)
        .send('flood vs earthquake');
    final reply = container.read(assistantControllerProvider).messages.last;

    expect(reply.sosDraft, isNull);
  });

  test('general disaster comparisons go directly to the chat model', () async {
    final nativeAi = FakeNativeAiService(
      capabilitiesResult: availableNativeAiCapabilities,
      answerResult: const NativeAiResult.success(
        NativeVerifiedRewrite('APPROVED CHAT ANSWER'),
      ),
    );
    final container = _container(nativeAi);
    addTearDown(container.dispose);
    await _loadCapabilities(container);

    await container
        .read(assistantControllerProvider.notifier)
        .send("what's the difference between typhoon and flood");
    final reply = container.read(assistantControllerProvider).messages.last;

    expect(reply.result!.intent, EmergencyIntent.unknown);
    expect(reply.article, isNull);
    expect(reply.gemmaAnswer, 'APPROVED CHAT ANSWER');
    expect(reply.responseEngine, AssistantResponseEngine.gemma);
    expect(nativeAi.classificationCalls, 0);
    expect(nativeAi.answerCalls, 1);
    expect(nativeAi.rewriteCalls, 0);
  });

  test('Burmese questions return the reviewed Burmese Guide answer', () async {
    final container = _container(
      FakeNativeAiService(),
      language: AppLanguage.burmese,
    );
    addTearDown(container.dispose);
    await _loadLanguage(container, AppLanguage.burmese);

    await container
        .read(assistantControllerProvider.notifier)
        .send('ငလျင်လှုပ်နေချိန် ဘာလုပ်ရမလဲ။');
    final reply = container.read(assistantControllerProvider).messages.last;

    expect(reply.result!.intent, EmergencyIntent.earthquakeGuidance);
    expect(
      reply.article!.answerForLanguage(burmese: true),
      'အတည်ပြုထားသော အဖြေ',
    );
    expect(reply.article!.answerEn, 'APPROVED EARTHQUAKE ANSWER');
    expect(reply.localRewording, isNull);
  });

  test(
    'Burmese critical questions stay deterministic and use Burmese content',
    () async {
      final nativeAi = FakeNativeAiService(
        capabilitiesResult: availableNativeAiCapabilities,
      );
      final container = _container(nativeAi, language: AppLanguage.burmese);
      addTearDown(container.dispose);
      await _loadLanguage(container, AppLanguage.burmese);
      await _loadCapabilities(container);

      await container
          .read(assistantControllerProvider.notifier)
          .send('ဒဏ်ရာရသူအတွက် ရှေးဦးသူနာပြု');
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(reply.result!.intent, EmergencyIntent.firstAid);
      expect(reply.article!.answerMy, 'အတည်ပြုထားသော ရှေးဦးသူနာပြုအဖြေ');
      expect(reply.responseEngine, AssistantResponseEngine.deterministic);
      expect(nativeAi.initializationCalls, 0);
      expect(nativeAi.rewriteCalls, 0);
    },
  );

  test(
    'Burmese general disaster questions use a reviewed fallback when Gemma is unavailable',
    () async {
      final nativeAi = FakeNativeAiService();
      final container = _container(nativeAi, language: AppLanguage.burmese);
      addTearDown(container.dispose);
      await _loadLanguage(container, AppLanguage.burmese);
      await _loadCapabilities(container);

      await container
          .read(assistantControllerProvider.notifier)
          .send('ငလျင်အကြောင်း ရှင်းပြပါ');
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(reply.result!.intent, EmergencyIntent.unknown);
      expect(reply.replyKind, AssistantReplyKind.article);
      expect(reply.article!.answerMy, 'အတည်ပြုထားသော အဖြေ');
      expect(reply.gemmaAnswer, isNull);
      expect(nativeAi.answerCalls, 0);
    },
  );

  test(
    'Burmese Gemma rewriting receives Burmese content and language',
    () async {
      final nativeAi = FakeNativeAiService(
        capabilitiesResult: availableNativeAiCapabilities,
        rewriteResult: const NativeAiResult.success(
          NativeVerifiedRewrite('အရေးပေါ်လမ်းညွှန်ကို အတိုချုံးရှင်းပြထားသည်။'),
        ),
      );
      final container = _container(nativeAi, language: AppLanguage.burmese);
      addTearDown(container.dispose);
      await _loadLanguage(container, AppLanguage.burmese);
      await _loadCapabilities(container);

      await container
          .read(assistantControllerProvider.notifier)
          .send('ငလျင်အတွက် လမ်းညွှန်ချက်');
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(
        reply.localRewording,
        'အရေးပေါ်လမ်းညွှန်ကို အတိုချုံးရှင်းပြထားသည်။',
      );
      expect(nativeAi.lastRewrite!.languageCode, 'my');
      expect(nativeAi.lastRewrite!.verifiedContent, reply.article!.answerMy);
      expect(reply.language, AppLanguage.burmese);
    },
  );

  test(
    'English-only Burmese Gemma answers fall back to a reviewed Burmese article',
    () async {
      final nativeAi = FakeNativeAiService(
        capabilitiesResult: availableNativeAiCapabilities,
        answerResult: const NativeAiResult.success(
          NativeVerifiedRewrite('This is an English-only answer.'),
        ),
      );
      final container = _container(nativeAi, language: AppLanguage.burmese);
      addTearDown(container.dispose);
      await _loadLanguage(container, AppLanguage.burmese);
      await _loadCapabilities(container);

      await container
          .read(assistantControllerProvider.notifier)
          .send('ငလျင်အကြောင်း ရှင်းပြပါ');
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(reply.result!.intent, EmergencyIntent.unknown);
      expect(reply.replyKind, AssistantReplyKind.article);
      expect(reply.article!.answerMy, 'အတည်ပြုထားသော အဖြေ');
      expect(reply.gemmaAnswer, isNull);
      expect(reply.responseEngine, AssistantResponseEngine.deterministic);
      expect(nativeAi.answerCalls, 1);
      expect(nativeAi.lastAnswerLanguage, 'my');
      expect(nativeAi.lastApprovedContext, contains('အတည်ပြုထားသော အဖြေ'));
    },
  );

  test('in-flight replies keep the language captured at send time', () async {
    final rewrite = Completer<NativeAiResult<NativeVerifiedRewrite>>();
    final nativeAi = FakeNativeAiService(
      capabilitiesResult: availableNativeAiCapabilities,
    )..rewriteHandler = () => rewrite.future;
    final container = _container(nativeAi, language: AppLanguage.burmese);
    addTearDown(container.dispose);
    await _loadLanguage(container, AppLanguage.burmese);
    await _loadCapabilities(container);

    final send = container
        .read(assistantControllerProvider.notifier)
        .send('ငလျင်အတွက် လမ်းညွှန်ချက်');
    await Future<void>.delayed(Duration.zero);
    expect(
      await container
          .read(languagePreferenceControllerProvider.notifier)
          .setLanguage(AppLanguage.english),
      LanguagePreferenceOperationResult.success,
    );
    rewrite.complete(
      const NativeAiResult.success(
        NativeVerifiedRewrite('အရေးပေါ်လမ်းညွှန်ကို အတိုချုံးရှင်းပြထားသည်။'),
      ),
    );
    await send;
    final reply = container.read(assistantControllerProvider).messages.last;

    expect(reply.language, AppLanguage.burmese);
    expect(reply.article!.answerMy, 'အတည်ပြုထားသော အဖြေ');
    expect(nativeAi.lastRewrite!.languageCode, 'my');
  });

  test(
    'general chat waits for capability discovery before falling back',
    () async {
      final capabilities = Completer<NativeAiCapabilities>();
      final nativeAi = FakeNativeAiService(
        answerResult: const NativeAiResult.success(
          NativeVerifiedRewrite('DELAYED CHAT ANSWER'),
        ),
      )..capabilitiesHandler = () => capabilities.future;
      final container = _container(nativeAi);
      addTearDown(container.dispose);

      final send = container
          .read(assistantControllerProvider.notifier)
          .send('what is a typhoon?');
      await Future<void>.delayed(Duration.zero);
      expect(container.read(assistantControllerProvider).messages, isEmpty);

      capabilities.complete(availableNativeAiCapabilities);
      await send;

      final reply = container.read(assistantControllerProvider).messages.last;
      expect(reply.gemmaAnswer, 'DELAYED CHAT ANSWER');
      expect(reply.responseEngine, AssistantResponseEngine.gemma);
    },
  );

  test('ONNX below 0.75 retains deterministic unknown', () async {
    final nativeAi = FakeNativeAiService(
      capabilitiesResult: availableNativeAiCapabilities,
      classificationResult: const NativeAiResult.success(
        NativeIntentClassification(intent: 'fire', confidence: 0.74),
      ),
    );
    final container = _container(nativeAi);
    addTearDown(container.dispose);
    await _loadCapabilities(container);

    await container
        .read(assistantControllerProvider.notifier)
        .send('there is danger nearby');
    final reply = container.read(assistantControllerProvider).messages.last;

    expect(nativeAi.classificationCalls, 1);
    expect(reply.result!.intent, EmergencyIntent.unknown);
    expect(reply.responseEngine, AssistantResponseEngine.deterministic);
  });

  test(
    'recognized ONNX label at 0.75 resolves deterministic unknown',
    () async {
      final nativeAi = FakeNativeAiService(
        capabilitiesResult: availableNativeAiCapabilities,
        classificationResult: const NativeAiResult.success(
          NativeIntentClassification(intent: 'fire', confidence: 0.75),
        ),
      );
      final container = _container(nativeAi);
      addTearDown(container.dispose);
      await _loadCapabilities(container);

      await container
          .read(assistantControllerProvider.notifier)
          .send('there is danger nearby');
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(reply.result!.intent, EmergencyIntent.fire);
      expect(reply.responseEngine, AssistantResponseEngine.onnx);
    },
  );

  for (final label in ['unknown', 'weather_warning']) {
    test('ONNX label $label does not replace deterministic unknown', () async {
      final nativeAi = FakeNativeAiService(
        capabilitiesResult: availableNativeAiCapabilities,
        classificationResult: NativeAiResult.success(
          NativeIntentClassification(intent: label, confidence: 0.99),
        ),
      );
      final container = _container(nativeAi);
      addTearDown(container.dispose);
      await _loadCapabilities(container);

      await container
          .read(assistantControllerProvider.notifier)
          .send('there is danger nearby');
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(reply.result!.intent, EmergencyIntent.unknown);
      expect(reply.responseEngine, AssistantResponseEngine.deterministic);
    });
  }

  final criticalCases = {
    'I am trapped under rubble': EmergencyIntent.trappedPerson,
    'first aid for an injured person': EmergencyIntent.firstAid,
    'send SOS emergency message': EmergencyIntent.sendSos,
  };
  for (final entry in criticalCases.entries) {
    test('local critical ${entry.value.name} takes precedence', () async {
      final nativeAi = FakeNativeAiService(
        capabilitiesResult: availableNativeAiCapabilities,
        classificationResult: const NativeAiResult.success(
          NativeIntentClassification(intent: 'fire', confidence: 0.99),
        ),
      );
      final container = _container(nativeAi);
      addTearDown(container.dispose);
      await _loadCapabilities(container);

      await container
          .read(assistantControllerProvider.notifier)
          .send(entry.key);
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(reply.result!.intent, entry.value);
      expect(reply.responseEngine, AssistantResponseEngine.deterministic);
      expect(nativeAi.classificationCalls, 0);
    });
  }

  final mixedCriticalCases = {
    'show a safe route but someone is bleeding': EmergencyIntent.firstAid,
    'find shelter, I am ပိတ်မိနေတယ်': EmergencyIntent.trappedPerson,
    'earthquake info then အရေးပေါ်စာပို့': EmergencyIntent.sendSos,
    'earthquake advice and a safer route': EmergencyIntent.safeRoute,
    'earthquake info then ဘေးကင်းတဲ့လမ်း ပြပါ': EmergencyIntent.safeRoute,
  };
  for (final entry in mixedCriticalCases.entries) {
    test('raw mixed critical input routes deterministically', () async {
      final nativeAi = FakeNativeAiService(
        capabilitiesResult: availableNativeAiCapabilities,
        classificationResult: const NativeAiResult.success(
          NativeIntentClassification(
            intent: 'earthquake_guidance',
            confidence: 1,
          ),
        ),
        rewriteResult: const NativeAiResult.success(
          NativeVerifiedRewrite('MUST NOT BE USED'),
        ),
      );
      final container = _container(nativeAi);
      addTearDown(container.dispose);
      await _loadCapabilities(container);

      await container
          .read(assistantControllerProvider.notifier)
          .send(entry.key);
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(reply.result!.intent, entry.value);
      expect(reply.responseEngine, AssistantResponseEngine.deterministic);
      expect(nativeAi.classificationCalls, 0);
      expect(nativeAi.initializationCalls, 0);
      expect(nativeAi.rewriteCalls, 0);
    });
  }

  test(
    'Gemma rewording is trimmed and kept separate from exact article',
    () async {
      final nativeAi = FakeNativeAiService(
        capabilitiesResult: availableNativeAiCapabilities,
        rewriteResult: const NativeAiResult.success(
          NativeVerifiedRewrite('  OPTIONAL SIMPLIFIED WORDING  '),
        ),
      );
      final container = _container(nativeAi);
      addTearDown(container.dispose);
      await _loadCapabilities(container);

      const question = 'What should I do during an earthquake?';
      await container.read(assistantControllerProvider.notifier).send(question);
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(reply.article!.answerEn, 'APPROVED EARTHQUAKE ANSWER');
      expect(reply.localRewording, 'OPTIONAL SIMPLIFIED WORDING');
      expect(nativeAi.initializationCalls, 1);
      expect(nativeAi.rewriteCalls, 1);
      expect(nativeAi.lastRewrite!.verifiedContent, reply.article!.answerEn);
      expect(nativeAi.lastRewrite!.source, reply.article!.sourceName);
      expect(nativeAi.lastRewrite!.userQuestion, question);
      expect(nativeAi.lastRewrite!.intent, 'earthquake_guidance');
    },
  );

  test(
    'Gemma answers a general question when the model is available',
    () async {
      final nativeAi = FakeNativeAiService(
        capabilitiesResult: availableNativeAiCapabilities,
        answerResult: const NativeAiResult.success(
          NativeVerifiedRewrite('GENERAL GEMMA ANSWER'),
        ),
      );
      final container = _container(nativeAi);
      addTearDown(container.dispose);
      await _loadCapabilities(container);

      await container
          .read(assistantControllerProvider.notifier)
          .send('tell me a joke');
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(reply.result!.intent, EmergencyIntent.unknown);
      expect(reply.gemmaAnswer, 'GENERAL GEMMA ANSWER');
      expect(reply.responseEngine, AssistantResponseEngine.gemma);
      expect(nativeAi.initializationCalls, 1);
      expect(nativeAi.answerCalls, 1);
      expect(nativeAi.lastQuestion, 'tell me a joke');
      expect(
        nativeAi.lastApprovedContext,
        contains('APPROVED EARTHQUAKE ANSWER'),
      );
    },
  );

  test('Gemma failure silently falls back to exact article only', () async {
    final nativeAi = FakeNativeAiService(
      capabilitiesResult: availableNativeAiCapabilities,
      rewriteResult: const NativeAiResult.error(NativeAiReason.runtimeError),
    );
    final container = _container(nativeAi);
    addTearDown(container.dispose);
    await _loadCapabilities(container);

    await container
        .read(assistantControllerProvider.notifier)
        .send('What should I do during an earthquake?');
    final reply = container.read(assistantControllerProvider).messages.last;

    expect(reply.article!.answerEn, 'APPROVED EARTHQUAKE ANSWER');
    expect(reply.localRewording, isNull);
  });

  for (final output in ['   ', List.filled(2001, 'x').join()]) {
    test('invalid Gemma output silently retains exact article only', () async {
      final nativeAi = FakeNativeAiService(
        capabilitiesResult: availableNativeAiCapabilities,
        rewriteResult: NativeAiResult.success(NativeVerifiedRewrite(output)),
      );
      final container = _container(nativeAi);
      addTearDown(container.dispose);
      await _loadCapabilities(container);

      await container
          .read(assistantControllerProvider.notifier)
          .send('What should I do during an earthquake?');
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(reply.article!.answerEn, 'APPROVED EARTHQUAKE ANSWER');
      expect(reply.localRewording, isNull);
    });
  }

  for (final output in [
    'This route is guaranteed safe.',
    'I have diagnosed the injury.',
    'Rescue teams will definitely arrive.',
  ]) {
    test('unsafe Gemma claims fall back to approved article content', () async {
      final nativeAi = FakeNativeAiService(
        capabilitiesResult: availableNativeAiCapabilities,
        rewriteResult: NativeAiResult.success(NativeVerifiedRewrite(output)),
      );
      final container = _container(nativeAi);
      addTearDown(container.dispose);
      await _loadCapabilities(container);

      await container
          .read(assistantControllerProvider.notifier)
          .send('What should I do during an earthquake?');
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(reply.article!.answerEn, 'APPROVED EARTHQUAKE ANSWER');
      expect(reply.localRewording, isNull);
    });
  }

  for (final output in [
    'ဤလမ်းသည် ဘေးကင်းပါသည်။',
    'ဒဏ်ရာကို ရောဂါရှာဖွေပြီးပြီ။',
    'ကယ်ဆယ်ရေးအဖွဲ့သည် မုချ ရောက်လာမည်။',
    'SOS ကို အောင်မြင်စွာပို့ပြီးပါပြီ။',
  ]) {
    test(
      'unsafe Burmese Gemma claims fall back to approved article content',
      () async {
        final nativeAi = FakeNativeAiService(
          capabilitiesResult: availableNativeAiCapabilities,
          rewriteResult: NativeAiResult.success(NativeVerifiedRewrite(output)),
        );
        final container = _container(nativeAi, language: AppLanguage.burmese);
        addTearDown(container.dispose);
        await _loadLanguage(container, AppLanguage.burmese);
        await _loadCapabilities(container);

        await container
            .read(assistantControllerProvider.notifier)
            .send('ငလျင်အတွက် လမ်းညွှန်ချက်');
        final reply = container.read(assistantControllerProvider).messages.last;

        expect(reply.article!.answerMy, 'အတည်ပြုထားသော အဖြေ');
        expect(reply.localRewording, isNull);
      },
    );
  }

  test('Gemma is never called for critical or action responses', () async {
    final prohibitedInputs = [
      'I am trapped under rubble',
      'first aid for an injured person',
      'send SOS emergency message',
      'show a safe route',
      'find a nearby shelter',
      'report a missing person',
      'report damage to a building',
    ];

    for (final input in prohibitedInputs) {
      final nativeAi = FakeNativeAiService(
        capabilitiesResult: const NativeAiCapabilities(
          tier2: NativeAiCapability(
            available: false,
            reason: NativeAiReason.modelMissing,
          ),
          tier3: NativeAiCapability(available: true),
        ),
      );
      final container = _container(nativeAi);
      await _loadCapabilities(container);
      await container.read(assistantControllerProvider.notifier).send(input);

      expect(nativeAi.initializationCalls, 0, reason: input);
      expect(nativeAi.rewriteCalls, 0, reason: input);
      container.dispose();
    }
  });

  test(
    'slow capability discovery does not block deterministic response',
    () async {
      final completer = Completer<NativeAiCapabilities>();
      final nativeAi = FakeNativeAiService()
        ..capabilitiesHandler = () => completer.future;
      final container = _container(nativeAi);
      addTearDown(container.dispose);

      final initial = container.read(assistantControllerProvider);
      expect(initial.onnxStatus, AssistantCapabilityStatus.checking);
      expect(initial.gemmaStatus, AssistantCapabilityStatus.checking);

      await container
          .read(assistantControllerProvider.notifier)
          .send('first aid for an injured person');
      final reply = container.read(assistantControllerProvider).messages.last;

      expect(reply.article!.answerEn, 'APPROVED FIRST AID ANSWER');
      expect(reply.responseEngine, AssistantResponseEngine.deterministic);
      completer.complete(missingNativeAiCapabilities);
      await Future<void>.delayed(Duration.zero);
    },
  );

  test('retains the language used for each assistant response', () async {
    final nativeAi = FakeNativeAiService(
      capabilitiesResult: availableNativeAiCapabilities,
      rewriteResult: const NativeAiResult.success(
        NativeVerifiedRewrite('အတည်ပြုထားသော ပြန်လည်ရေးသားမှု'),
      ),
    );
    final container = _container(nativeAi, language: AppLanguage.burmese);
    addTearDown(container.dispose);
    await _loadLanguage(container, AppLanguage.burmese);
    await _loadCapabilities(container);

    await container
        .read(assistantControllerProvider.notifier)
        .send('ငလျင်အတွက် လမ်းညွှန်ချက်');
    final messages = container.read(assistantControllerProvider).messages;

    expect(messages.first.language, AppLanguage.burmese);
    expect(messages.last.language, AppLanguage.burmese);
  });
}

ProviderContainer _container(
  FakeNativeAiService nativeAi, {
  AppLanguage language = AppLanguage.english,
}) {
  final languageRepository = FakeLanguagePreferenceRepository()
    ..language = language;
  return ProviderContainer(
    overrides: [
      emergencyGuideRepositoryProvider.overrideWithValue(
        FakeEmergencyGuideRepository(),
      ),
      nativeAiServiceProvider.overrideWithValue(nativeAi),
      languagePreferenceRepositoryProvider.overrideWithValue(
        languageRepository,
      ),
    ],
  );
}

Future<void> _loadLanguage(
  ProviderContainer container,
  AppLanguage language,
) async {
  container.read(languagePreferenceControllerProvider);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  expect(
    await container
        .read(languagePreferenceControllerProvider.notifier)
        .setLanguage(language),
    LanguagePreferenceOperationResult.success,
  );
}

Future<void> _loadCapabilities(ProviderContainer container) async {
  container.read(assistantControllerProvider);
  await Future<void>.delayed(Duration.zero);
}
