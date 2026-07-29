import 'text_normalizer.dart';

final class SosTextDraft {
  const SosTextDraft({
    this.incident,
    this.status,
    this.injury,
    this.locationPhrase,
    this.batteryPercent,
  });

  final String? incident;
  final String? status;
  final String? injury;
  final String? locationPhrase;
  final int? batteryPercent;

  bool get hasValues =>
      incident != null ||
      status != null ||
      injury != null ||
      locationPhrase != null ||
      batteryPercent != null;
}

SosTextDraft extractSosDraft(String input) {
  final normalized = normalizeEmergencyText(input).text;
  final incident = _firstLabel(normalized, const {
    'earthquake': 'earthquake',
    'fire': 'fire',
    'flood': 'flood',
    'landslide': 'landslide',
    'cyclone': 'cyclone',
  });
  final status = _firstLabel(normalized, const {
    'trapped': 'trapped',
    'missing': 'missing',
    'stuck': 'trapped',
    'safe': 'currently safe',
  });
  final injury = _extractSegment(
    input,
    RegExp(
      r'([^,.!?။]*(?:injur(?:y|ed)|bleed(?:ing)?|hurt|ဒဏ်ရာရ|သွေးထွက်)[^,.!?။]*)',
      caseSensitive: false,
    ),
  );
  final location = _extractLocation(input);
  final normalizedDigits = _myanmarDigitsToAscii(input);
  final battery = RegExp(
    r'(?:battery|ဘက်ထရီ)\s*(?:is|at|[:：])?\s*(\d{1,3})\s*%',
    caseSensitive: false,
  ).firstMatch(normalizedDigits);
  final batteryValue = int.tryParse(battery?.group(1) ?? '');
  return SosTextDraft(
    incident: incident,
    status: status,
    injury: injury,
    locationPhrase: location,
    batteryPercent:
        batteryValue != null && batteryValue >= 0 && batteryValue <= 100
        ? batteryValue
        : null,
  );
}

String? _firstLabel(String text, Map<String, String> labels) {
  for (final entry in labels.entries) {
    if (text.split(' ').contains(entry.key)) return entry.value;
  }
  return null;
}

String? _extractLocation(String input) {
  final explicit = RegExp(
    r'(?:location|နေရာ|တည်နေရာ)\s*[:：]?\s*([^,.!?။]+)',
    caseSensitive: false,
  ).firstMatch(input);
  if (explicit != null) return explicit.group(1)?.trim();
  final english = RegExp(
    r'\b(?:at|near|in)\s+([^,.!?]+?)(?=\s+(?:with|battery|and\s+(?:i|we))\b|$)',
    caseSensitive: false,
  ).firstMatch(input);
  if (english != null) return english.group(1)?.trim();
  final burmese = RegExp(r'([^၊။,.!?]+?)မှာ(?:\s|၊|။|,|$)').firstMatch(input);
  return burmese?.group(1)?.trim();
}

String? _extractSegment(String input, RegExp expression) {
  final value = expression.firstMatch(input)?.group(1)?.trim();
  return value == null || value.isEmpty ? null : value;
}

String _myanmarDigitsToAscii(String input) {
  const myanmarDigits = '၀၁၂၃၄၅၆၇၈၉';
  var result = input;
  for (var index = 0; index < myanmarDigits.length; index++) {
    result = result.replaceAll(myanmarDigits[index], '$index');
  }
  return result;
}
