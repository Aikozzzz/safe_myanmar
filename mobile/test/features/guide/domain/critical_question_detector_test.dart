import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/guide/domain/critical_question_detector.dart';
import 'package:mobile/features/guide/domain/intent_classifier.dart';

void main() {
  final cases = <String, EmergencyIntent>{
    'show a route, I am trapped': EmergencyIntent.trappedPerson,
    'earthquake update but someone is bleeding': EmergencyIntent.firstAid,
    'medical help near shelter': EmergencyIntent.firstAid,
    'please send SOS and show the map': EmergencyIntent.sendSos,
    'လမ်းကြောင်းပြပါ၊ ဒဏ်ရာရပြီး သွေးထွက်နေတယ်': EmergencyIntent.firstAid,
    'ငလျင်ကြောင့် ပိတ်မိနေတယ်': EmergencyIntent.trappedPerson,
    'အရေးပေါ်စာပို့ပြီး အကူအညီတောင်းပါ': EmergencyIntent.sendSos,
    'earthquake advice and a safer route': EmergencyIntent.safeRoute,
    'ငလျင်ဖြစ်နေပြီး ဘေးကင်းတဲ့လမ်း ပြပါ': EmergencyIntent.safeRoute,
    'firstaid': EmergencyIntent.firstAid,
    'first_aid': EmergencyIntent.firstAid,
    'send_sos': EmergencyIntent.sendSos,
    'saferoute': EmergencyIntent.safeRoute,
  };

  for (final entry in cases.entries) {
    test('detects raw critical ${entry.value.name}: ${entry.key}', () {
      expect(detectCriticalQuestion(entry.key)?.intent, entry.value);
    });
  }

  test('does not flag noncritical words containing an SOS substring', () {
    expect(detectCriticalQuestion('isosceles triangle'), isNull);
  });
}
