import 'dart:math' as math;

import 'text_normalizer.dart';

enum EmergencyIntent {
  earthquakeGuidance,
  trappedPerson,
  firstAid,
  fire,
  flood,
  safeRoute,
  findShelter,
  missingPerson,
  sendSos,
  reportDamage,
  unknown,
}

final class IntentResult {
  IntentResult({
    required this.intent,
    required this.confidence,
    required this.explanation,
    required List<String> matchedTerms,
  }) : matchedTerms = List.unmodifiable(matchedTerms);

  final EmergencyIntent intent;
  final double confidence;
  final String explanation;
  final List<String> matchedTerms;
}

/// Returns true when a disaster word is part of an informational chat question
/// rather than a request for emergency action.
bool isGeneralChatQuestion(String input) {
  final normalized = normalizeEmergencyText(input).text;
  final tokens = normalized
      .split(' ')
      .where((token) => token.isNotEmpty)
      .toSet();
  final topicCount = tokens.intersection(_generalChatTopics).length;
  if (topicCount == 0) return false;

  final comparison = _comparisonCues.any(normalized.contains);
  final informational = _informationalCues.any(normalized.contains);
  final action = _emergencyActionCues.any(normalized.contains);
  return !action &&
      ((comparison && topicCount >= 2) || (informational && topicCount >= 1));
}

final class EmergencyIntentClassifier {
  const EmergencyIntentClassifier();

  IntentResult classify(String input) {
    final normalized = normalizeEmergencyText(input);
    final tokens = normalized.tokens.toSet();
    final scored = <_ScoredIntent>[];
    for (final entry in _intentTerms.entries) {
      var score = 0.0;
      final matched = <String>[];
      for (final term in entry.value.entries) {
        final normalizedTerm = normalizeEmergencyText(term.key).tokens;
        final present = normalizedTerm.every(tokens.contains);
        if (!present) continue;
        final documentFrequency = _intentTerms.values
            .where((terms) => terms.containsKey(term.key))
            .length;
        final inverseFrequency =
            math.log((_intentTerms.length + 1) / (documentFrequency + 1)) + 1;
        score += term.value * inverseFrequency;
        matched.add(term.key);
      }
      scored.add(_ScoredIntent(entry.key, score, matched));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    final best = scored.first;
    final second = scored[1];
    final confidence = best.score == 0
        ? 0.0
        : best.score / (best.score + second.score + 1.5);
    if (best.score < 2.0 ||
        confidence < 0.55 ||
        best.score - second.score < 1.5) {
      return IntentResult(
        intent: EmergencyIntent.unknown,
        confidence: confidence,
        explanation: best.score == 0
            ? 'No approved offline intent terms matched.'
            : 'The closest offline intent match was below the confidence threshold.',
        matchedTerms: best.matched,
      );
    }
    return IntentResult(
      intent: best.intent,
      confidence: confidence,
      explanation:
          'Matched weighted offline terms: ${best.matched.join(', ')}. No machine-learning model was used.',
      matchedTerms: best.matched,
    );
  }
}

final class _ScoredIntent {
  const _ScoredIntent(this.intent, this.score, this.matched);

  final EmergencyIntent intent;
  final double score;
  final List<String> matched;
}

const _intentTerms = <EmergencyIntent, Map<String, double>>{
  EmergencyIntent.earthquakeGuidance: {
    'earthquake': 3,
    'shaking': 2.5,
    'drop': 1.5,
    'cover': 1.5,
    'hold': 1.5,
    'quake': 2.5,
  },
  EmergencyIntent.trappedPerson: {
    'trapped': 4,
    'stuck': 3,
    'buried': 3,
    'rubble': 2.5,
    'whistle': 2,
    'bang pipe': 3,
  },
  EmergencyIntent.firstAid: {
    'first aid': 4,
    'injured': 2.5,
    'injury': 2.5,
    'bleeding': 3,
    'unresponsive': 3,
    'breathing': 2,
    'medical': 2,
  },
  EmergencyIntent.fire: {'fire': 3.5, 'smoke': 3, 'burning': 3, 'escape': 1.5},
  EmergencyIntent.flood: {
    'flood': 3.5,
    'floodwater': 3,
    'rising water': 3,
    'water rising': 3,
  },
  EmergencyIntent.safeRoute: {
    'safe route': 4,
    'route': 2.5,
    'directions': 2.5,
    'evacuation route': 3.5,
  },
  EmergencyIntent.findShelter: {'shelter': 4, 'nearby shelter': 4, 'refuge': 3},
  EmergencyIntent.missingPerson: {
    'missing person': 4,
    'missing': 3,
    'lost person': 3.5,
  },
  EmergencyIntent.sendSos: {
    'send sos': 4,
    'sos': 3.5,
    'emergency message': 3,
    'help me': 2.5,
  },
  EmergencyIntent.reportDamage: {
    'report damage': 4,
    'damage': 3,
    'damaged building': 3.5,
  },
};

const _generalChatTopics = <String>{
  'earthquake',
  'flood',
  'floodwater',
  'typhoon',
  'typhon',
  'cyclone',
  'hurricane',
  'storm',
  'fire',
  'landslide',
  'rain',
  'disaster',
  'danger',
};

const _comparisonCues = <String>[
  'difference',
  'compare',
  'comparison',
  'versus',
  ' vs ',
  'ကွာခြား',
  'နှိုင်းယှဉ်',
];

const _informationalCues = <String>[
  'what is',
  'what are',
  'what s',
  'tell me about',
  'explain',
  'define',
  'why does',
  'why do',
  'how does',
  'how long',
  'ဘာလဲ',
  'အကြောင်း',
  'ရှင်းပြ',
  'ဘာကြောင့်',
  'ဘယ်လောက်ကြာ',
];

const _emergencyActionCues = <String>[
  'how do i',
  'how can i',
  'what should i do',
  'avoid',
  'check',
  'send',
  'find',
  'show',
  'report',
  'help me',
  'ဘာလုပ်ရမလဲ',
  'ဘယ်လို',
  'ရှောင်',
  'ပို့',
  'ရှာ',
  'အစီရင်ခံ',
  'အကူအညီ',
];
