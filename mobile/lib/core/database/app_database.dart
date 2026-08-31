import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class CachedEarthquakes extends Table {
  TextColumn get id => text()();
  TextColumn get provider => text()();
  TextColumn get providerEventId => text()();
  TextColumn get kind => text()();
  TextColumn get title => text()();
  TextColumn get place => text()();
  RealColumn get magnitude => real()();
  RealColumn get depthKm => real()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get eventAt => integer()();
  IntColumn get providerUpdatedAt => integer()();
  IntColumn get retrievedAt => integer()();
  TextColumn get reviewStatus => text().nullable()();
  TextColumn get sourceUrl => text()();
  IntColumn get version => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {provider, providerEventId},
  ];
}

class AlertSyncMetadata extends Table {
  TextColumn get provider => text()();
  TextColumn get dataStatus => text().customConstraint(
    "NOT NULL CHECK (data_status IN ('current', 'stale'))",
  )();
  IntColumn get lastSuccessfulRefreshAt => integer()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {provider};
}

class CachedShelterResponses extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get payload => text()();
  IntColumn get dataAt => integer()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedHazardResponses extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get payload => text()();
  IntColumn get dataAt => integer()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedRouteResponses extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get payload => text()();
  IntColumn get generatedAt => integer()();
  IntColumn get cachedAt => integer()();
  IntColumn get originLatitudeE5 => integer().nullable()();
  IntColumn get originLongitudeE5 => integer().nullable()();
  TextColumn get shelterId => text().nullable()();
  TextColumn get contextAreaId => text().nullable()();
  TextColumn get disasterType => text().nullable()();
  TextColumn get routeProfile => text().nullable()();
  TextColumn get scenario => text().nullable()();
  IntColumn get searchRadiusM => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedContextAreaResponses extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get payload => text()();
  IntColumn get dataAt => integer()();
  IntColumn get cachedAt => integer()();
  IntColumn get originLatitudeE5 => integer()();
  IntColumn get originLongitudeE5 => integer()();
  TextColumn get disasterType => text()();
  TextColumn get scenario => text()();
  IntColumn get searchRadiusM => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EmergencyArticleRow')
class EmergencyArticles extends Table {
  TextColumn get id => text()();
  IntColumn get contentVersion => integer()();
  TextColumn get category => text()();
  TextColumn get titleEn => text()();
  TextColumn get titleMy => text()();
  TextColumn get questionEn => text()();
  TextColumn get questionMy => text()();
  TextColumn get answerEn => text()();
  TextColumn get answerMy => text()();
  TextColumn get keywords => text()();
  TextColumn get sourceName => text()();
  TextColumn get sourceUrl => text()();
  IntColumn get sourceUpdatedAt => integer().nullable()();
  IntColumn get reviewedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    CachedEarthquakes,
    AlertSyncMetadata,
    CachedShelterResponses,
    CachedHazardResponses,
    CachedRouteResponses,
    CachedContextAreaResponses,
    EmergencyArticles,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.open() : this(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _seedEmergencyArticles();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(cachedShelterResponses);
        await migrator.createTable(cachedHazardResponses);
        await migrator.createTable(cachedRouteResponses);
      }
      if (from < 3) {
        await migrator.createTable(emergencyArticles);
        await _seedEmergencyArticles();
      }
      if (from >= 2 && from < 4) {
        await migrator.addColumn(
          cachedRouteResponses,
          cachedRouteResponses.originLatitudeE5,
        );
        await migrator.addColumn(
          cachedRouteResponses,
          cachedRouteResponses.originLongitudeE5,
        );
        await migrator.addColumn(
          cachedRouteResponses,
          cachedRouteResponses.shelterId,
        );
        await migrator.addColumn(
          cachedRouteResponses,
          cachedRouteResponses.disasterType,
        );
        await migrator.addColumn(
          cachedRouteResponses,
          cachedRouteResponses.routeProfile,
        );
      }
      if (from < 5) {
        await migrator.createTable(cachedContextAreaResponses);
      }
      if (from >= 2 && from < 6) {
        await migrator.addColumn(
          cachedRouteResponses,
          cachedRouteResponses.contextAreaId,
        );
        await migrator.addColumn(
          cachedRouteResponses,
          cachedRouteResponses.scenario,
        );
        await migrator.addColumn(
          cachedRouteResponses,
          cachedRouteResponses.searchRadiusM,
        );
      }
    },
  );

  Future<void> _seedEmergencyArticles() async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        emergencyArticles,
        _emergencyArticleSeeds
            .map(
              (seed) => EmergencyArticlesCompanion.insert(
                id: seed.id,
                contentVersion: seed.contentVersion,
                category: seed.category,
                titleEn: seed.titleEn,
                titleMy: seed.titleMy,
                questionEn: seed.questionEn,
                questionMy: seed.questionMy,
                answerEn: seed.answerEn,
                answerMy: seed.answerMy,
                keywords: seed.keywords,
                sourceName: seed.sourceName,
                sourceUrl: seed.sourceUrl,
                sourceUpdatedAt: Value(
                  seed.sourceUpdatedAt?.microsecondsSinceEpoch,
                ),
                reviewedAt: seed.reviewedAt.microsecondsSinceEpoch,
              ),
            )
            .toList(),
      );
    });
  }
}

final class _EmergencyArticleSeed {
  const _EmergencyArticleSeed({
    required this.id,
    required this.contentVersion,
    required this.category,
    required this.titleEn,
    required this.titleMy,
    required this.questionEn,
    required this.questionMy,
    required this.answerEn,
    required this.answerMy,
    required this.keywords,
    required this.sourceName,
    required this.sourceUrl,
    required this.sourceUpdatedAt,
    required this.reviewedAt,
  });

  final String id;
  final int contentVersion;
  final String category;
  final String titleEn;
  final String titleMy;
  final String questionEn;
  final String questionMy;
  final String answerEn;
  final String answerMy;
  final String keywords;
  final String sourceName;
  final String sourceUrl;
  final DateTime? sourceUpdatedAt;
  final DateTime reviewedAt;
}

final _reviewedAt = DateTime.utc(2026, 7, 23);
final _emergencyArticleSeeds = <_EmergencyArticleSeed>[
  _EmergencyArticleSeed(
    id: 'earthquake-drop-cover-hold',
    contentVersion: 1,
    category: 'earthquake',
    titleEn: 'Drop, cover, and hold on',
    titleMy: 'ဝပ်၊ ကာကွယ်၊ ကိုင်ထားပါ',
    questionEn: 'What should I do during an earthquake?',
    questionMy: 'ငလျင်လှုပ်နေချိန် ဘာလုပ်ရမလဲ။',
    answerEn:
        'Drop onto your hands and knees. Cover your head and neck; get under a sturdy table if one is close, or stay beside an interior wall away from windows. Hold on and be ready to move with your shelter until shaking stops. If outside, move to an open area away from buildings, trees, lights, and power lines.',
    answerMy:
        'လက်နှင့်ဒူးပေါ် ဝပ်ချပါ။ ဦးခေါင်းနှင့်လည်ပင်းကို ကာကွယ်ပြီး အနီးတွင် ခိုင်ခံ့သောစားပွဲရှိလျှင် အောက်သို့ဝင်ပါ။ မရှိလျှင် ပြတင်းပေါက်များနှင့်ဝေးသော အတွင်းနံရံဘေးတွင်နေပါ။ လှုပ်ခတ်မှုရပ်သည်အထိ ကိုင်ထားပါ။ အပြင်တွင်ရှိလျှင် အဆောက်အအုံ၊ သစ်ပင်၊ မီးတိုင်နှင့် ဓာတ်အားလိုင်းများမှဝေးသော နေရာလွတ်သို့ရွှေ့ပါ။',
    keywords: 'earthquake|shaking|drop|cover|hold|quake|ငလျင်|လှုပ်|ဝပ်|ကာကွယ်',
    sourceName: 'Ready.gov',
    sourceUrl: 'https://www.ready.gov/earthquakes',
    sourceUpdatedAt: DateTime.utc(2026, 4, 29),
    reviewedAt: _reviewedAt,
  ),
  _EmergencyArticleSeed(
    id: 'earthquake-trapped',
    contentVersion: 1,
    category: 'earthquake',
    titleEn: 'If you are trapped after an earthquake',
    titleMy: 'ငလျင်ပြီးနောက် ပိတ်မိနေပါက',
    questionEn: 'What should I do if I am trapped?',
    questionMy: 'ပိတ်မိနေရင် ဘာလုပ်ရမလဲ။',
    answerEn:
        'Protect your mouth with clothing. Send a text if possible, or bang on a pipe or wall so rescuers can locate you. Use a whistle instead of shouting to reduce dust exposure and conserve energy. Contact authorized local emergency or medical services when possible.',
    answerMy:
        'ပါးစပ်ကို အဝတ်ဖြင့်ကာပါ။ ဖြစ်နိုင်လျှင် စာတိုပို့ပါ၊ သို့မဟုတ် ကယ်ဆယ်သူများ နေရာရှာနိုင်ရန် ပိုက် သို့မဟုတ် နံရံကို ခေါက်ပါ။ ဖုန်ရှူမိမှုလျှော့ချပြီး အားချွေတာရန် အော်ဟစ်မည့်အစား ဝီစီသုံးပါ။ ဖြစ်နိုင်လျှင် တရားဝင်ဒေသဆိုင်ရာ အရေးပေါ် သို့မဟုတ် ဆေးဘက်ဝန်ဆောင်မှုကို ဆက်သွယ်ပါ။',
    keywords:
        'trapped|stuck|buried|rubble|pipe|wall|whistle|ပိတ်မိ|အပျက်အစီး|ဝီစီ',
    sourceName: 'Ready.gov',
    sourceUrl: 'https://www.ready.gov/earthquakes',
    sourceUpdatedAt: DateTime.utc(2026, 4, 29),
    reviewedAt: _reviewedAt,
  ),
  _EmergencyArticleSeed(
    id: 'flood-avoidance',
    contentVersion: 1,
    category: 'flood',
    titleEn: 'Avoid floodwater',
    titleMy: 'ရေကြီးရေလျှံနေရာကို ရှောင်ပါ',
    questionEn: 'How do I stay away from flood danger?',
    questionMy: 'ရေကြီးအန္တရာယ်ကို ဘယ်လိုရှောင်ရမလဲ။',
    answerEn:
        'Find safer shelter promptly and follow local evacuation instructions. Do not walk, swim, or drive through floodwater, and do not go around barricades. Stay off bridges over fast-moving water. Move to higher ground or a higher floor when instructed or when water is rising.',
    answerMy:
        'ပိုမိုလုံခြုံနိုင်သော ခိုလှုံရာကို အမြန်ရှာပြီး ဒေသဆိုင်ရာ ရွှေ့ပြောင်းညွှန်ကြားချက်များကို လိုက်နာပါ။ ရေကြီးရေလျှံနေရာတွင် လမ်းမလျှောက်၊ ရေမကူး၊ ယာဉ်မမောင်းပါနှင့်။ အတားအဆီးများကို မကျော်ပါနှင့်။ ရေစီးသန်သော တံတားများကို ရှောင်ပါ။ ညွှန်ကြားချက်ရလျှင် သို့မဟုတ် ရေမြင့်လာလျှင် မြေမြင့် သို့မဟုတ် အပေါ်ထပ်သို့ ရွှေ့ပါ။',
    keywords:
        'flood|floodwater|water|rising|bridge|higher ground|ရေကြီး|ရေလျှံ|ရေမြင့်',
    sourceName: 'Ready.gov',
    sourceUrl: 'https://www.ready.gov/floods',
    sourceUpdatedAt: DateTime.utc(2026, 4, 29),
    reviewedAt: _reviewedAt,
  ),
  _EmergencyArticleSeed(
    id: 'fire-escape',
    contentVersion: 1,
    category: 'fire',
    titleEn: 'Escape a home fire',
    titleMy: 'အိမ်မီးလောင်မှုမှ လွတ်မြောက်ရန်',
    questionEn: 'How should I escape a fire?',
    questionMy: 'မီးလောင်ရင် ဘယ်လိုထွက်ပြေးရမလဲ။',
    answerEn:
        'Get low and crawl under smoke toward an exit. Before opening a door, feel the door and handle; if hot or smoke is coming through, keep it closed and use another exit. Once outside, stay outside. If you cannot leave, close the door, block gaps against smoke, signal at a window, and contact authorized local emergency services.',
    answerMy:
        'အောက်သို့နိမ့်ချပြီး မီးခိုးအောက်မှ ထွက်ပေါက်ဆီ တွားသွားပါ။ တံခါးမဖွင့်မီ တံခါးနှင့်လက်ကိုင် ပူမပူစမ်းပါ။ ပူနေလျှင် သို့မဟုတ် မီးခိုးဝင်နေလျှင် ပိတ်ထားပြီး အခြားထွက်ပေါက်သုံးပါ။ အပြင်ရောက်လျှင် ပြန်မဝင်ပါနှင့်။ မထွက်နိုင်လျှင် တံခါးပိတ်၊ အပေါက်များကို ပိတ်ဆို့၊ ပြတင်းပေါက်မှ အချက်ပြပြီး တရားဝင်ဒေသဆိုင်ရာ အရေးပေါ်ဝန်ဆောင်မှုကို ဆက်သွယ်ပါ။',
    keywords: 'fire|smoke|burning|escape|exit|door|မီး|မီးခိုး|လောင်|ထွက်ပေါက်',
    sourceName: 'Ready.gov',
    sourceUrl: 'https://www.ready.gov/home-fires',
    sourceUpdatedAt: DateTime.utc(2026, 2, 26),
    reviewedAt: _reviewedAt,
  ),
  _EmergencyArticleSeed(
    id: 'first-aid-assessment',
    contentVersion: 1,
    category: 'first_aid',
    titleEn: 'Initial first-aid assessment',
    titleMy: 'ကနဦး ရှေးဦးသူနာပြု စစ်ဆေးမှု',
    questionEn: 'What should I check before giving first aid?',
    questionMy: 'ရှေးဦးသူနာပြုမလုပ်မီ ဘာစစ်ဆေးရမလဲ။',
    answerEn:
        'First check that the scene is safe, form an initial impression, obtain consent when possible, and use available protective equipment. Check responsiveness, breathing, and life-threatening bleeding for no more than 10 seconds. Contact authorized local emergency or medical services for life-threatening conditions, and give only care that matches your training.',
    answerMy:
        'ဦးစွာ နေရာလုံခြုံမှုကို စစ်ဆေးပြီး ကနဦးအခြေအနေကို သုံးသပ်ပါ။ ဖြစ်နိုင်လျှင် ခွင့်ပြုချက်ယူပြီး ရရှိနိုင်သော ကာကွယ်ရေးပစ္စည်းကို သုံးပါ။ တုံ့ပြန်မှု၊ အသက်ရှူမှုနှင့် အသက်အန္တရာယ်ရှိသော သွေးထွက်မှုကို ၁၀ စက္ကန့်ထက်မပိုဘဲ စစ်ဆေးပါ။ အသက်အန္တရာယ်ရှိလျှင် တရားဝင်ဒေသဆိုင်ရာ အရေးပေါ် သို့မဟုတ် ဆေးဘက်ဝန်ဆောင်မှုကို ဆက်သွယ်ပြီး မိမိလေ့ကျင့်ထားသည့် အတိုင်းအတာအတွင်းသာ ကူညီပါ။',
    keywords:
        'first aid|injury|injured|bleeding|breathing|unresponsive|medical|ရှေးဦးသူနာပြု|ဒဏ်ရာ|သွေးထွက်|အသက်ရှူ',
    sourceName: 'American Red Cross',
    sourceUrl:
        'https://www.redcross.org/take-a-class/first-aid/performing-first-aid/first-aid-steps',
    sourceUpdatedAt: null,
    reviewedAt: _reviewedAt,
  ),
];

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(path.join(directory.path, 'safe_myanmar.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
