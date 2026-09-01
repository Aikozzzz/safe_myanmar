final class NormalizedEmergencyText {
  NormalizedEmergencyText({required this.text, required List<String> tokens})
    : tokens = List.unmodifiable(tokens);

  final String text;
  final List<String> tokens;
}

NormalizedEmergencyText normalizeEmergencyText(String input) {
  var text = input.toLowerCase().trim();
  const digits = <String, String>{
    '၀': '0',
    '၁': '1',
    '၂': '2',
    '၃': '3',
    '၄': '4',
    '၅': '5',
    '၆': '6',
    '၇': '7',
    '၈': '8',
    '၉': '9',
  };
  for (final entry in digits.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }
  const aliases = <String, String>{
    'ငလျင်လှုပ်': ' earthquake ',
    'ငလျင်': ' earthquake ',
    'မြေငလျင်': ' earthquake ',
    'တုန်ခါ': ' shaking ',
    'ပိတ်မိနေ': ' trapped ',
    'ပိတ်မိ': ' trapped ',
    'အပျက်အစီးအောက်': ' rubble trapped ',
    'ရှေးဦးကုသမှု': ' first aid ',
    'ရှေးဦးသူနာပြုခြင်း': ' first aid ',
    'ရှေးဦးသူနာပြု': ' first aid ',
    'ရှေးဦးကုသ': ' first aid ',
    'ဒဏ်ရာရ': ' injured ',
    'သွေးထွက်': ' bleeding ',
    'မီးလောင်': ' fire ',
    'မီးခိုး': ' smoke ',
    'မီး': ' fire ',
    'ရေကြီး': ' flood ',
    'ရေကြီးမှု': ' flood ',
    'ရေဘေး': ' flood ',
    'ရေလျှံ': ' flood ',
    'ရေစီး': ' floodwater ',
    'ရေမြင့်': ' rising water ',
    'မုန်တိုင်း': ' cyclone ',
    'တိုင်ဖွန်း': ' typhoon ',
    'ဟာရီကိန်း': ' hurricane ',
    'မိုးကြီး': ' storm ',
    'မိုးသည်း': ' storm ',
    'မြေပြို': ' landslide ',
    'ဘေးအန္တရာယ်': ' disaster ',
    'ဘေးကင်းလမ်း': ' safe route ',
    'လုံခြုံတဲ့လမ်း': ' safe route ',
    'လမ်းကြောင်း': ' route ',
    'ခိုလှုံရာ': ' shelter ',
    'အမိုးအကာ': ' shelter ',
    'ပျောက်ဆုံးသူ': ' missing person ',
    'လူပျောက်': ' missing person ',
    'ပျောက်နေသူ': ' missing person ',
    'ပျောက်သူ': ' missing person ',
    'ပျောက်ဆုံး': ' missing ',
    'အရေးပေါ်စာပို့': ' send sos ',
    'အက်စ်အိုအက်စ်': ' sos ',
    'အကူအညီတောင်း': ' send sos help ',
    'အရေးပေါ်အကူအညီ': ' send sos help ',
    'ကယ်ဆယ်ရန်အကူအညီ': ' send sos help ',
    'ပျက်စီးမှုတိုင်': ' report damage ',
    'ပျက်စီးမှု': ' damage ',
    'ပျက်စီး': ' damage ',
    'အဆောက်အအုံပျက်စီး': ' damaged building ',
    'ဘက်ထရီ': ' battery ',
    'နေရာ': ' location ',
  };
  for (final entry in aliases.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }
  text = text
      .replaceAll(RegExp(r"[’']"), '')
      .replaceAll(RegExp(r'[^a-z0-9\u1000-\u109f]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final tokens = text.isEmpty ? const <String>[] : text.split(' ');
  return NormalizedEmergencyText(text: tokens.join(' '), tokens: tokens);
}
