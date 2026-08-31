import 'intent_classifier.dart';

final class CriticalQuestionMatch {
  const CriticalQuestionMatch({required this.intent, required this.term});

  final EmergencyIntent intent;
  final String term;
}

CriticalQuestionMatch? detectCriticalQuestion(String rawQuestion) {
  final question = rawQuestion.toLowerCase();
  for (final group in _criticalTerms) {
    for (final term in group.terms) {
      final matches = term.isAsciiWord
          ? RegExp(
              '(^|[^a-z])${RegExp.escape(term.value)}([^a-z]|\$)',
            ).hasMatch(question)
          : question.contains(term.value);
      if (matches) {
        return CriticalQuestionMatch(intent: group.intent, term: term.value);
      }
    }
  }
  return null;
}

final class _CriticalTerm {
  const _CriticalTerm(this.value, {this.isAsciiWord = false});

  final String value;
  final bool isAsciiWord;
}

final class _CriticalTermGroup {
  const _CriticalTermGroup(this.intent, this.terms);

  final EmergencyIntent intent;
  final List<_CriticalTerm> terms;
}

const _criticalTerms = <_CriticalTermGroup>[
  _CriticalTermGroup(EmergencyIntent.trappedPerson, [
    _CriticalTerm('trapped', isAsciiWord: true),
    _CriticalTerm('stuck', isAsciiWord: true),
    _CriticalTerm('buried', isAsciiWord: true),
    _CriticalTerm('under rubble'),
    _CriticalTerm('ပိတ်မိ'),
    _CriticalTerm('အပျက်အစီးအောက်'),
    _CriticalTerm('မြုပ်နေ'),
  ]),
  _CriticalTermGroup(EmergencyIntent.firstAid, [
    _CriticalTerm('first aid'),
    _CriticalTerm('first-aid'),
    _CriticalTerm('injury', isAsciiWord: true),
    _CriticalTerm('injured', isAsciiWord: true),
    _CriticalTerm('wound', isAsciiWord: true),
    _CriticalTerm('wounded', isAsciiWord: true),
    _CriticalTerm('bleeding', isAsciiWord: true),
    _CriticalTerm('medical', isAsciiWord: true),
    _CriticalTerm('ရှေးဦးသူနာပြု'),
    _CriticalTerm('ဒဏ်ရာ'),
    _CriticalTerm('သွေးထွက်'),
    _CriticalTerm('ဆေးဘက်'),
    _CriticalTerm('ဆေးကု'),
  ]),
  _CriticalTermGroup(EmergencyIntent.sendSos, [
    _CriticalTerm('sos', isAsciiWord: true),
    _CriticalTerm('emergency message'),
    _CriticalTerm('help me'),
    _CriticalTerm('အက်စ်အိုအက်စ်'),
    _CriticalTerm('အရေးပေါ်စာ'),
    _CriticalTerm('အရေးပေါ်စာပို့'),
    _CriticalTerm('အကူအညီတောင်း'),
  ]),
  _CriticalTermGroup(EmergencyIntent.safeRoute, [
    _CriticalTerm('safe route'),
    _CriticalTerm('safer route'),
    _CriticalTerm('evacuation route'),
    _CriticalTerm('ဘေးကင်းလမ်း'),
    _CriticalTerm('ဘေးကင်းတဲ့လမ်း'),
    _CriticalTerm('လုံခြုံတဲ့လမ်း'),
    _CriticalTerm('ရွှေ့ပြောင်းလမ်း'),
  ]),
];
