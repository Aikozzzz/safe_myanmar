import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/guide/domain/sos_text_extractor.dart';

void main() {
  test('extracts structured English SOS details without activating anything', () {
    final draft = extractSosDraft(
      'Earthquake. I am trapped near 35th Street with a leg injury. Battery 18%.',
    );

    expect(draft.incident, 'earthquake');
    expect(draft.status, 'trapped');
    expect(draft.injury, contains('leg injury'));
    expect(draft.locationPhrase, '35th Street');
    expect(draft.batteryPercent, 18);
    expect(draft.hasValues, isTrue);
  });

  test('extracts the Burmese-style SOS sample and Myanmar digits', () {
    final draft = extractSosDraft(
      'ငလျင်လှုပ်ပြီး ပိတ်မိနေတယ်၊ ခြေထောက်ဒဏ်ရာရတယ်၊ ၃၅ လမ်းမှာ၊ ဘက်ထရီ ၂၀%',
    );

    expect(draft.incident, 'earthquake');
    expect(draft.status, 'trapped');
    expect(draft.injury, contains('ဒဏ်ရာရ'));
    expect(draft.locationPhrase, contains('၃၅ လမ်း'));
    expect(draft.batteryPercent, 20);
  });

  test('rejects invalid battery percentages', () {
    expect(extractSosDraft('battery 120%').batteryPercent, isNull);
  });
}
