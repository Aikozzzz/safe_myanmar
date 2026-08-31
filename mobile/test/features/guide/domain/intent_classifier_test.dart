import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/guide/domain/intent_classifier.dart';
import 'package:mobile/features/guide/domain/text_normalizer.dart';

void main() {
  const classifier = EmergencyIntentClassifier();

  test('normalizes Burmese, English case, punctuation, and digits', () {
    final normalized = normalizeEmergencyText(' ငလျင်လှုပ်! BATTERY ၂၀% ');

    expect(normalized.tokens, containsAll(['earthquake', 'battery', '20']));
  });

  final cases = <String, EmergencyIntent>{
    'earthquake shaking drop cover hold': EmergencyIntent.earthquakeGuidance,
    'I am trapped under rubble': EmergencyIntent.trappedPerson,
    'first aid for an injured person': EmergencyIntent.firstAid,
    'fire and smoke in my home': EmergencyIntent.fire,
    'flood water is rising': EmergencyIntent.flood,
    'show a safe route': EmergencyIntent.safeRoute,
    'find a nearby shelter': EmergencyIntent.findShelter,
    'report a missing person': EmergencyIntent.missingPerson,
    'send SOS emergency message': EmergencyIntent.sendSos,
    'report damage to a building': EmergencyIntent.reportDamage,
  };
  for (final entry in cases.entries) {
    test('classifies ${entry.value.name}', () {
      final result = classifier.classify(entry.key);

      expect(result.intent, entry.value);
      expect(result.confidence, greaterThanOrEqualTo(0.45));
      expect(
        result.explanation,
        contains('No machine-learning model was used'),
      );
    });
  }

  test('uses unknown for low-confidence and unrelated input', () {
    expect(classifier.classify('route fire').intent, EmergencyIntent.unknown);
    expect(classifier.classify('hello there').intent, EmergencyIntent.unknown);
  });

  test('keeps informational disaster questions in general chat', () {
    expect(
      isGeneralChatQuestion("what's the difference between typhoon and flood"),
      isTrue,
    );
    expect(isGeneralChatQuestion('flood vs earthquake'), isTrue);
    expect(
      isGeneralChatQuestion('How long does it take for Typhon to pass a city'),
      isTrue,
    );
    expect(isGeneralChatQuestion('How do I avoid floodwater?'), isFalse);
  });

  test('retrieves a Burmese earthquake intent deterministically', () {
    expect(
      classifier.classify('ငလျင်လှုပ်နေရင် ဘာလုပ်ရမလဲ').intent,
      EmergencyIntent.earthquakeGuidance,
    );
  });
}
