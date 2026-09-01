import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/native_ai_platform_service.dart';
import '../../settings/application/providers.dart';
import '../../settings/domain/app_language.dart';
import '../domain/emergency_article.dart';
import '../domain/critical_question_detector.dart';
import '../domain/intent_classifier.dart';
import '../domain/sos_text_extractor.dart';
import 'providers.dart';

enum AssistantReplyKind {
  article,
  mapAction,
  sosAction,
  missingPerson,
  reportDamage,
  unknown,
  unavailable,
}

enum AssistantCapabilityStatus { checking, available, unavailable }

enum AssistantResponseEngine { deterministic, onnx, gemma }

final class AssistantMessage {
  const AssistantMessage.user(
    this.text, {
    this.language = AppLanguage.english,
  }) : isUser = true,
      result = null,
      article = null,
      replyKind = null,
      sosDraft = null,
      responseEngine = null,
      localRewording = null,
      gemmaAnswer = null;

  const AssistantMessage.assistant({
    required this.language,
    required this.result,
    required this.article,
    required this.replyKind,
    required this.sosDraft,
    required this.responseEngine,
    required this.localRewording,
    required this.gemmaAnswer,
  }) : isUser = false,
       text = null;

  final bool isUser;
  final String? text;
  final AppLanguage language;
  final IntentResult? result;
  final EmergencyArticle? article;
  final AssistantReplyKind? replyKind;
  final SosTextDraft? sosDraft;
  final AssistantResponseEngine? responseEngine;
  final String? localRewording;
  final String? gemmaAnswer;
}

final class AssistantState {
  AssistantState({
    required List<AssistantMessage> messages,
    this.isLoading = false,
    this.onnxStatus = AssistantCapabilityStatus.checking,
    this.gemmaStatus = AssistantCapabilityStatus.checking,
  }) : messages = List.unmodifiable(messages);

  final List<AssistantMessage> messages;
  final bool isLoading;
  final AssistantCapabilityStatus onnxStatus;
  final AssistantCapabilityStatus gemmaStatus;

  AssistantState copyWith({
    List<AssistantMessage>? messages,
    bool? isLoading,
    AssistantCapabilityStatus? onnxStatus,
    AssistantCapabilityStatus? gemmaStatus,
  }) => AssistantState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    onnxStatus: onnxStatus ?? this.onnxStatus,
    gemmaStatus: gemmaStatus ?? this.gemmaStatus,
  );
}

final class AssistantController extends Notifier<AssistantState> {
  late EmergencyGuideRepository _repository;
  late EmergencyIntentClassifier _classifier;
  late NativeAiService _nativeAi;
  NativeAiCapabilities? _capabilities;
  Future<void>? _capabilitiesFuture;
  Future<bool>? _gemmaInitialization;
  var _disposed = false;

  @override
  AssistantState build() {
    _repository = ref.watch(emergencyGuideRepositoryProvider);
    _classifier = ref.watch(emergencyIntentClassifierProvider);
    _nativeAi = ref.watch(nativeAiServiceProvider);
    ref.onDispose(() {
      _disposed = true;
      unawaited(_cancelNativeOperation());
    });
    _capabilitiesFuture = Future<void>.microtask(_loadCapabilities);
    unawaited(_capabilitiesFuture!);
    return AssistantState(messages: const []);
  }

  Future<void> send(String input) async {
    final text = _boundedQuestion(input);
    if (text.isEmpty || state.isLoading) return;
    final language = ref.read(languagePreferenceControllerProvider).language;
    final criticalMatch = detectCriticalQuestion(text);
    final generalChat = criticalMatch == null && isGeneralChatQuestion(text);
    if (generalChat) {
      await (_capabilitiesFuture ??= _loadCapabilities());
      if (_disposed) return;
    }
    final classifiedResult = _classifier.classify(text);
    final dartResult = generalChat
        ? IntentResult(
            intent: EmergencyIntent.unknown,
            confidence: 0,
            explanation:
                'General chat questions are answered by the offline assistant.',
            matchedTerms: const [],
          )
        : classifiedResult;
    final extraction = extractSosDraft(text);
    state = state.copyWith(
      messages: [...state.messages, AssistantMessage.user(text, language: language)],
      isLoading: true,
    );

    var result = criticalMatch == null
        ? dartResult
        : IntentResult(
            intent: criticalMatch.intent,
            confidence: 1,
            explanation:
                'Matched a critical multilingual safety term in the raw question. No machine-learning model was used.',
            matchedTerms: [criticalMatch.term],
          );
    var responseEngine = AssistantResponseEngine.deterministic;
    if (criticalMatch == null &&
        !generalChat &&
        dartResult.intent == EmergencyIntent.unknown) {
      if (_capabilities?.tier2.available == true) {
        try {
          final nativeResult = await _nativeAi.classifyIntent(text);
          final classification = nativeResult.value;
          final nativeIntent = classification == null
              ? null
              : _intentFromNativeLabel(classification.intent);
          if (nativeResult.status == NativeAiStatus.success &&
              classification != null &&
              nativeIntent != null &&
              nativeIntent != EmergencyIntent.unknown &&
              classification.confidence.isFinite &&
              classification.confidence >= _minimumOnnxConfidence &&
              classification.confidence <= 1) {
            result = IntentResult(
              intent: nativeIntent,
              confidence: classification.confidence,
              explanation: 'Resolved by the optional local ONNX classifier.',
              matchedTerms: const [],
            );
            responseEngine = AssistantResponseEngine.onnx;
          }
        } catch (_) {
          // Optional model failures retain the deterministic result.
        }
      }
    }
    if (_disposed) return;

    final articleId = generalChat ? null : _articleIds[result.intent];
    EmergencyArticle? article;
    if (articleId != null) {
      try {
        article = await _repository.getById(articleId);
      } catch (_) {
        article = null;
      }
    }
    if (_disposed) return;
    String? localRewording;
    String? gemmaAnswer;
    if (article != null &&
        criticalMatch == null &&
        _canUseGemma(result.intent, AssistantReplyKind.article) &&
        _capabilities?.tier3.available == true) {
      localRewording = await _tryRewrite(
        article: article,
        question: text,
        intent: result.intent,
        language: language,
      );
      if (localRewording != null) {
        responseEngine = AssistantResponseEngine.gemma;
      }
    } else if (criticalMatch == null &&
        article == null &&
        result.intent == EmergencyIntent.unknown) {
      if (_capabilities?.tier3.available == true) {
        gemmaAnswer = await _tryAnswerQuestion(text, language);
        if (gemmaAnswer != null) {
          responseEngine = AssistantResponseEngine.gemma;
        }
      }
      if (gemmaAnswer == null && generalChat) {
        article = await _reviewedFallbackArticle(
          classifiedResult.intent,
          language,
        );
      }
    }
    if (_disposed) return;
    final replyKind = article != null
        ? AssistantReplyKind.article
        : switch (result.intent) {
            EmergencyIntent.safeRoute ||
            EmergencyIntent.findShelter => AssistantReplyKind.mapAction,
            EmergencyIntent.sendSos ||
            EmergencyIntent.trappedPerson => AssistantReplyKind.sosAction,
            EmergencyIntent.missingPerson => AssistantReplyKind.missingPerson,
            EmergencyIntent.reportDamage => AssistantReplyKind.reportDamage,
            EmergencyIntent.unknown => AssistantReplyKind.unknown,
            _ => AssistantReplyKind.unavailable,
          };
    state = state.copyWith(
      messages: [
        ...state.messages,
        AssistantMessage.assistant(
          language: language,
          result: result,
          article: article,
          replyKind: replyKind,
          sosDraft: _shouldShowSosDraft(result.intent, extraction)
              ? extraction
              : null,
          responseEngine: responseEngine,
          localRewording: localRewording,
          gemmaAnswer: gemmaAnswer,
        ),
      ],
      isLoading: false,
    );
  }

  Future<void> _loadCapabilities() async {
    NativeAiCapabilities capabilities;
    try {
      capabilities = await _nativeAi.capabilities();
    } catch (_) {
      capabilities = _unavailableCapabilities;
    }
    if (_disposed) return;
    _capabilities = capabilities;
    state = state.copyWith(
      onnxStatus: capabilities.tier2.available
          ? AssistantCapabilityStatus.available
          : AssistantCapabilityStatus.unavailable,
      gemmaStatus: capabilities.tier3.available
          ? AssistantCapabilityStatus.available
          : AssistantCapabilityStatus.unavailable,
    );
  }

  Future<String?> _tryRewrite({
    required EmergencyArticle article,
    required String question,
    required EmergencyIntent intent,
    required AppLanguage language,
  }) async {
    final verifiedContent = article.answerForLanguage(
      burmese: language.isBurmese,
    );
    if (verifiedContent.isEmpty ||
        verifiedContent.length > _maximumVerifiedContentCharacters ||
        article.sourceName.isEmpty ||
        article.sourceName.length > _maximumSourceCharacters) {
      return null;
    }
    try {
      final initialized = await (_gemmaInitialization ??= _initializeGemma());
      if (!initialized || _disposed) return null;
      final rewrite = await _nativeAi.rewriteVerifiedContent(
        verifiedContent: verifiedContent,
        source: article.sourceName,
        userQuestion: question,
        intent: _nativeIntentName(intent),
        languageCode: language.code,
      );
      final text = rewrite.value?.text.trim();
      if (rewrite.status != NativeAiStatus.success ||
          text == null ||
          text.isEmpty ||
          text.length > _maximumRewriteCharacters ||
          !_isSafeGeneratedText(text, language: language)) {
        return null;
      }
      return text;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _initializeGemma() async {
    try {
      final result = await _nativeAi.initializeGemma();
      return result.status == NativeAiStatus.success;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _tryAnswerQuestion(
    String question,
    AppLanguage language,
  ) async {
    try {
      final articles = await _repository.search(query: '');
      final approvedContext = articles
          .take(_maximumContextArticles)
          .map(
            (article) =>
                '[${article.category}] '
                '${article.titleForLanguage(burmese: language.isBurmese)}\n'
                '${article.answerForLanguage(burmese: language.isBurmese)}\n'
                'Source: ${article.sourceName}',
          )
          .join('\n\n');
      final initialized = await (_gemmaInitialization ??= _initializeGemma());
      if (!initialized || _disposed) return null;
      final answer = await _nativeAi.answerQuestion(
        question: question,
        approvedContext: approvedContext,
        languageCode: language.code,
      );
      final text = answer.value?.text.trim();
      if (answer.status != NativeAiStatus.success ||
          text == null ||
          text.isEmpty ||
          text.length > _maximumRewriteCharacters ||
          !_isSafeGeneratedText(text, language: language)) {
        return null;
      }
      return text;
    } catch (_) {
      return null;
    }
  }

  Future<EmergencyArticle?> _reviewedFallbackArticle(
    EmergencyIntent intent,
    AppLanguage language,
  ) async {
    final articleId = _articleIds[intent];
    if (articleId == null) return null;
    try {
      final article = await _repository.getById(articleId);
      if (article == null) return null;
      final answer = language.isBurmese ? article.answerMy : article.answerEn;
      return answer.trim().isEmpty ? null : article;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cancelNativeOperation() async {
    try {
      await _nativeAi.cancel();
    } catch (_) {
      // The owning provider still performs final native resource disposal.
    }
  }
}

const _articleIds = <EmergencyIntent, String>{
  EmergencyIntent.earthquakeGuidance: 'earthquake-drop-cover-hold',
  EmergencyIntent.trappedPerson: 'earthquake-trapped',
  EmergencyIntent.firstAid: 'first-aid-assessment',
  EmergencyIntent.fire: 'fire-escape',
  EmergencyIntent.flood: 'flood-avoidance',
};

const _minimumOnnxConfidence = 0.75;
const _maximumQuestionCharacters = 500;
const _maximumVerifiedContentCharacters = 3500;
const _maximumSourceCharacters = 200;
const _maximumRewriteCharacters = 2000;
const _maximumContextArticles = 8;

final _unsafeGeneratedTextPatterns = [
  RegExp(r'\bguaranteed\s+(?:safe|recovery|delivery|arrival)\b'),
  RegExp(r'\b(?:definitely|completely)\s+safe\b'),
  RegExp(r'\b(?:i|we)\s+(?:have\s+)?diagnos(?:e|ed|is)\b'),
  RegExp(r'\brescue\s+(?:teams|services).{0,40}\b(?:will|definitely)\b'),
  RegExp(r'\b(?:i|we)\s+(?:have\s+)?sent\s+(?:an?\s+)?sos\b'),
  RegExp(r'လုံးဝ(?:ဘေးကင်း|လုံခြုံ)'),
  RegExp(
    r'(?:ဘေးကင်း|လုံခြုံ)(?:ပါသည်|ပါတယ်|တယ်|မယ်|ကြောင်း|ဖြစ်သည်)',
  ),
  RegExp(
    r'(?:ဤ|ဒီ).{0,40}(?:လမ်း|လမ်းကြောင်း|နေရာ|ဧရိယာ).{0,40}'
    r'(?:ဘေးကင်း|လုံခြုံ)(?:ပါသည်|ပါတယ်|တယ်|မယ်|ကြောင်း|ဖြစ်သည်)',
  ),
  RegExp(
    r'အာမခံ.{0,20}(?:ဘေးကင်း|လုံခြုံ|ကယ်ဆယ်|ရောက်)',
  ),
  RegExp(r'(?:သေချာ|မုချ).{0,40}(?:ကယ်ဆယ်|ရောက်လာ)'),
  RegExp(
    r'(?:ကယ်ဆယ်ရေး|ကယ်ဆယ်သူ|ကယ်ဆယ်ရေးအဖွဲ့).{0,40}'
    r'(?:သေချာ|မုချ|ရောက်လာ|ရောက်မည်|ရောက်မယ်)',
  ),
  RegExp(
    r'(?:ရောဂါ|ဒဏ်ရာ|အနာ|ကျန်းမာရေး).{0,40}'
    r'(?:ခွဲခြား|ရောဂါရှာဖွေ|စစ်ဆေးပြီး|diagnos)',
  ),
  RegExp(
    r'(?:sos|အရေးပေါ်စာ).{0,40}'
    r'(?:ပို့ပြီး|ပေးပို့ပြီး|ပို့ထား|အောင်မြင်စွာပို့|ရောက်ပြီး)',
  ),
];

const _unavailableCapabilities = NativeAiCapabilities(
  tier2: NativeAiCapability(
    available: false,
    reason: NativeAiReason.runtimeError,
  ),
  tier3: NativeAiCapability(
    available: false,
    reason: NativeAiReason.runtimeError,
  ),
);

String _boundedQuestion(String input) {
  final text = input.trim();
  if (text.length <= _maximumQuestionCharacters) return text;
  return text.substring(0, _maximumQuestionCharacters).trimRight();
}

bool _isSafeGeneratedText(String text, {required AppLanguage language}) {
  final normalized = text.trim().toLowerCase();
  if (_unsafeGeneratedTextPatterns.any((pattern) => pattern.hasMatch(normalized))) {
    return false;
  }
  if (language.isBurmese) {
    final burmeseCharacters = RegExp(
      r'[\u1000-\u109f]',
    ).allMatches(text).length;
    final latinCharacters = RegExp(r'[a-z]', caseSensitive: false)
        .allMatches(text)
        .length;
    return burmeseCharacters >= 3 && burmeseCharacters >= latinCharacters;
  }
  return true;
}

bool _canUseGemma(EmergencyIntent intent, AssistantReplyKind replyKind) =>
    replyKind == AssistantReplyKind.article &&
    intent != EmergencyIntent.trappedPerson &&
    intent != EmergencyIntent.firstAid &&
    intent != EmergencyIntent.sendSos &&
    intent != EmergencyIntent.safeRoute;

bool _shouldShowSosDraft(EmergencyIntent intent, SosTextDraft draft) {
  if (!draft.hasValues) return false;
  if (intent == EmergencyIntent.sendSos ||
      intent == EmergencyIntent.trappedPerson) {
    return true;
  }
  return draft.injury != null &&
      (draft.status != null || draft.locationPhrase != null);
}

EmergencyIntent? _intentFromNativeLabel(String label) => switch (label
    .trim()
    .toLowerCase()
    .replaceAll('-', '_')
    .replaceAll(' ', '_')) {
  'earthquake_guidance' ||
  'earthquakeguidance' => EmergencyIntent.earthquakeGuidance,
  'trapped_person' ||
  'trappedperson' ||
  'trapped' => EmergencyIntent.trappedPerson,
  'first_aid' || 'firstaid' => EmergencyIntent.firstAid,
  'fire' => EmergencyIntent.fire,
  'flood' => EmergencyIntent.flood,
  'safe_route' || 'saferoute' => EmergencyIntent.safeRoute,
  'find_shelter' || 'findshelter' => EmergencyIntent.findShelter,
  'missing_person' || 'missingperson' => EmergencyIntent.missingPerson,
  'send_sos' || 'sendsos' => EmergencyIntent.sendSos,
  'report_damage' || 'reportdamage' => EmergencyIntent.reportDamage,
  'unknown' => EmergencyIntent.unknown,
  _ => null,
};

String _nativeIntentName(EmergencyIntent intent) => switch (intent) {
  EmergencyIntent.earthquakeGuidance => 'earthquake_guidance',
  EmergencyIntent.trappedPerson => 'trapped_person',
  EmergencyIntent.firstAid => 'first_aid',
  EmergencyIntent.fire => 'fire',
  EmergencyIntent.flood => 'flood',
  EmergencyIntent.safeRoute => 'safe_route',
  EmergencyIntent.findShelter => 'find_shelter',
  EmergencyIntent.missingPerson => 'missing_person',
  EmergencyIntent.sendSos => 'send_sos',
  EmergencyIntent.reportDamage => 'report_damage',
  EmergencyIntent.unknown => 'unknown',
};
