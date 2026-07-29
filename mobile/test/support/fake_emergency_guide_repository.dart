import 'package:mobile/features/guide/domain/emergency_article.dart';

final class FakeEmergencyGuideRepository implements EmergencyGuideRepository {
  FakeEmergencyGuideRepository([List<EmergencyArticle>? articles])
    : articles = articles ?? guideArticleFixtures();

  final List<EmergencyArticle> articles;
  bool fail = false;

  @override
  Future<EmergencyArticle?> getById(String id) async {
    if (fail) throw StateError('offline storage unavailable');
    return articles.where((article) => article.id == id).firstOrNull;
  }

  @override
  Future<List<EmergencyArticle>> search({
    String query = '',
    String? category,
  }) async {
    if (fail) throw StateError('offline storage unavailable');
    final lower = query.toLowerCase();
    return articles
        .where((article) => category == null || article.category == category)
        .where(
          (article) =>
              lower.isEmpty ||
              '${article.titleEn} ${article.titleMy} ${article.questionEn} ${article.questionMy}'
                  .toLowerCase()
                  .contains(lower),
        )
        .toList();
  }
}

List<EmergencyArticle> guideArticleFixtures() => [
  EmergencyArticle(
    id: 'earthquake-drop-cover-hold',
    contentVersion: 1,
    category: 'earthquake',
    titleEn: 'Drop, cover, and hold on',
    titleMy: 'ဝပ်၊ ကာကွယ်၊ ကိုင်ထားပါ',
    questionEn: 'What should I do during an earthquake?',
    questionMy: 'ငလျင်လှုပ်နေချိန် ဘာလုပ်ရမလဲ။',
    answerEn: 'APPROVED EARTHQUAKE ANSWER',
    answerMy: 'အတည်ပြုထားသော အဖြေ',
    keywords: const ['earthquake', 'ငလျင်'],
    sourceName: 'Ready.gov',
    sourceUrl: 'https://www.ready.gov/earthquakes',
    sourceUpdatedAt: DateTime.utc(2026, 4, 29),
    reviewedAt: DateTime.utc(2026, 7, 23),
  ),
  EmergencyArticle(
    id: 'earthquake-trapped',
    contentVersion: 1,
    category: 'earthquake',
    titleEn: 'If you are trapped after an earthquake',
    titleMy: 'ငလျင်ပြီးနောက် ပိတ်မိနေပါက',
    questionEn: 'What should I do if I am trapped?',
    questionMy: 'ပိတ်မိနေရင် ဘာလုပ်ရမလဲ။',
    answerEn: 'APPROVED TRAPPED ANSWER',
    answerMy: 'အတည်ပြုထားသော ပိတ်မိအဖြေ',
    keywords: const ['trapped', 'ပိတ်မိ'],
    sourceName: 'Ready.gov',
    sourceUrl: 'https://www.ready.gov/earthquakes',
    sourceUpdatedAt: DateTime.utc(2026, 4, 29),
    reviewedAt: DateTime.utc(2026, 7, 23),
  ),
  EmergencyArticle(
    id: 'first-aid-assessment',
    contentVersion: 1,
    category: 'first_aid',
    titleEn: 'Initial first-aid assessment',
    titleMy: 'ကနဦး ရှေးဦးသူနာပြု စစ်ဆေးမှု',
    questionEn: 'What should I check before giving first aid?',
    questionMy: 'ရှေးဦးသူနာပြုမလုပ်မီ ဘာစစ်ဆေးရမလဲ။',
    answerEn: 'APPROVED FIRST AID ANSWER',
    answerMy: 'အတည်ပြုထားသော ရှေးဦးသူနာပြုအဖြေ',
    keywords: const ['first aid', 'ရှေးဦးသူနာပြု'],
    sourceName: 'American Red Cross',
    sourceUrl:
        'https://www.redcross.org/take-a-class/first-aid/performing-first-aid/first-aid-steps',
    sourceUpdatedAt: null,
    reviewedAt: DateTime.utc(2026, 7, 23),
  ),
];
