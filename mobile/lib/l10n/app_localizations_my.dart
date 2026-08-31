// Manually checked Burmese locale implementation.
// This file mirrors app_my.arb until Flutter gen-l10n is available.
import 'app_localizations_en.dart';

class AppLocalizationsMy extends AppLocalizationsEn {
  AppLocalizationsMy([String locale = 'my']) : super(locale);

  @override
  String get appName => 'SafeMyanmar';
  @override
  String get navigationHome => 'ပင်မ';
  @override
  String get navigationMap => 'မြေပုံ';
  @override
  String get navigationSos => 'SOS';
  @override
  String get navigationGuide => 'လမ်းညွှန်';
  @override
  String get navigationMore => 'နောက်ထပ်';
  @override
  String get homeTitle => 'SafeMyanmar';
  @override
  String get homeWelcomeTitle => 'အရေးပေါ်တုံ့ပြန်မှုကို တစ်ချက်ကြည့်ပါ';
  @override
  String get homeDescription =>
      'လက်ရှိရရှိနိုင်သော အချက်အလက်များအပေါ် အခြေခံထားသည့် အရေးပေါ်အချက်အလက်နှင့် ကိရိယာများ။';
  @override
  String get homeSafetyCenterTitle => 'ဘေးကင်းရေးစင်တာ';
  @override
  String get homeSafetyCenterDescription =>
      'ရရှိနိုင်သော အချက်အလက်များကို စစ်ဆေးပြီး အရေးကြီးသော ဘေးကင်းရေးကိရိယာများကို ဖွင့်ပါ။';
  @override
  String get homeOpenMapAction => 'မြေပုံဖွင့်ရန်';
  @override
  String get homeOpenSosAction => 'SOS ပြင်ဆင်မှုဖွင့်ရန်';
  @override
  String get homeOpenGuideAction => 'လမ်းညွှန်ဖွင့်ရန်';
  @override
  String get homeEarthquakeCardTitle => 'တိုက်ရိုက်ငလျင်အချက်အလက်';
  @override
  String get viewEarthquakeInformation => 'ငလျင်အချက်အလက်ကြည့်ရန်';
  @override
  String get mapTitle => 'မြေပုံ';
  @override
  String get locationHeading => 'သင့်တည်နေရာ';
  @override
  String get locationMapAction => 'ကျွန်ုပ်၏တည်နေရာအသေးစိတ်ပြရန်';
  @override
  String get locationDetailsTitle => 'သင့်တည်နေရာအသေးစိတ်';
  @override
  String get locationDetailsDescription =>
      'ဤစက်တွင် လက်ရှိရရှိနိုင်သော တည်နေရာကို စစ်ဆေးပါ။';
  @override
  String get locationDetailsAccuracy => 'တည်နေရာတိကျမှု';
  @override
  String get locationDetailsCoordinates => 'ကိုဩဒိနိတ်';
  @override
  String get locationDetailsUpdated => 'နောက်ဆုံးအပ်ဒိတ်';
  @override
  String get locationNotRequestedTitle => 'တည်နေရာအသုံးပြုခွင့် ပိတ်ထားသည်';
  @override
  String get locationPermissionExplanationTitle =>
      'တည်နေရာအသုံးပြုခွင့်ပြုမလား။';
  @override
  String get locationPermissionExplanationDescription =>
      'အနီးအနားရလဒ်များနှင့် တည်နေရာအခြေပြုလုပ်ဆောင်ချက်များအတွက် သင့်တည်နေရာကို လိုအပ်သည့်အချိန်တွင်သာ အသုံးပြုပါမည်။';
  @override
  String get allowLocation => 'တည်နေရာခွင့်ပြုရန်';
  @override
  String get notNow => 'ယခုမဟုတ်ပါ';
  @override
  String get locationExplanation =>
      'တည်နေရာခွင့်ပြုချက်မရမီ အက်ပ်စတင်ချိန်တွင် Mapbox သည် SDK၊ စက်နှင့် အသုံးပြုမှုဆိုင်ရာ telemetry ကို ရရှိနိုင်သော်လည်း သင့်စက်တည်နေရာ မပါဝင်ပါ။ ကျွန်ုပ်၏တည်နေရာကို အသုံးပြုရန် ရွေးချယ်မှသာ အဝေးရှိ Mapbox မြေပုံကို တည်ဆောက်ပြီး အလယ်ဗဟိုပြုကာ ကြည့်ရှုသည့်မြေပုံဧရိယာကို ဖော်ပြပါမည်။ လမ်းကြောင်းတောင်းဆိုပြီးမှသာ သင့်တည်နေရာအတိအကျကို SafeMyanmar backend နှင့် Mapbox Directions သို့ ပေးပို့ပါမည်။';
  @override
  String get locationPrivacyDescription =>
      'ကျွန်ုပ်၏တည်နေရာကို အသုံးပြုရန် မရွေးချယ်မီ SafeMyanmar သည် စက်တည်နေရာကို မတောင်းဆိုသလို မြေပုံကိုလည်း မတည်ဆောက်ပါ။ ရွေးချယ်ပြီးနောက် ခွင့်ပြုချက်ရှိနေသရွေ့ နောက်တစ်ကြိမ်ဖွင့်ရာတွင် ပြန်လည်အသုံးပြုပါမည်။ တည်နေရာမပါဘဲ အမိုးအကာအချက်အလက်နှင့် Mapbox telemetry အတွက် ကွန်ရက်အသုံးပြုနိုင်ပါသည်။ SafeMyanmar သည် တည်နေရာမှတ်တမ်းမသိမ်းဆည်းသလို နောက်ခံတည်နေရာခွင့်ပြုချက်လည်း မတောင်းဆိုပါ။';
  @override
  String get useMyLocation => 'ကျွန်ုပ်၏တည်နေရာကို အသုံးပြုရန်';
  @override
  String get tryLocationAgain => 'တည်နေရာထပ်ရှာရန်';
  @override
  String get locationRequestingTitle => 'တည်နေရာတောင်းဆိုနေသည်';
  @override
  String get locationRequestingDescription =>
      'ခွင့်ပြုချက်စစ်ဆေးပြီး လက်ရှိတည်နေရာကို ရှာနေသည်။';
  @override
  String get findingYourLocation => 'သင့်တည်နေရာကို ရှာနေသည်';
  @override
  String get preciseLocationAvailable => 'တိကျသောတည်နေရာ ရရှိသည်';
  @override
  String get preciseLocationDescription =>
      'သင့်စက်က တိကျသော foreground တည်နေရာအသုံးပြုခွင့် ပေးထားသည်။';
  @override
  String get approximateLocationAvailable => 'အနီးစပ်ဆုံးတည်နေရာ ရရှိသည်';
  @override
  String get approximateLocationDescription =>
      'သင့်စက်က အနီးစပ်ဆုံး foreground တည်နေရာအသုံးပြုခွင့် ပေးထားသည်။ တည်နေရာသည် ပိုကျယ်သောဧရိယာကို ဖော်ပြနိုင်သည်။';
  @override
  String get locationPermissionDenied => 'တည်နေရာခွင့်ပြုချက် ငြင်းပယ်ထားသည်';
  @override
  String get locationPermissionDeniedDescription =>
      'ခွင့်ပြုရန် မရွေးချယ်ပါက SafeMyanmar သည် တည်နေရာကို အသုံးမပြုနိုင်ပါ။';
  @override
  String get locationPermissionPermanentlyDenied =>
      'တည်နေရာခွင့်ပြုချက် အမြဲတမ်းငြင်းပယ်ထားသည်';
  @override
  String get locationPermissionPermanentlyDeniedDescription =>
      'SafeMyanmar သည် ထပ်မတောင်းဆိုပါ။ အက်ပ်ဆက်တင်တွင် တည်နေရာခွင့်ပြုချက်ကို ပြောင်းနိုင်သည်။';
  @override
  String get locationServicesDisabled => 'တည်နေရာဝန်ဆောင်မှု ပိတ်ထားသည်';
  @override
  String get locationServicesDisabledDescription =>
      'ထပ်မကြိုးစားမီ စက်၏တည်နေရာဝန်ဆောင်မှုကို ဖွင့်ပါ။';
  @override
  String get lastKnownLocation => 'နောက်ဆုံးသိရှိထားသောတည်နေရာ';
  @override
  String get lastKnownLocationDescription =>
      'တိုက်ရိုက်တည်နေရာ မရနိုင်ပါ။ ဤသည်မှာ စက်က နောက်ဆုံးဖော်ပြခဲ့သော တည်နေရာဖြစ်သည်။';
  @override
  String get locationRecoverableError => 'တည်နေရာ ယာယီမရနိုင်ပါ';
  @override
  String get locationRecoverableErrorDescription =>
      'SafeMyanmar သည် လက်ရှိတည်နေရာ သို့မဟုတ် နောက်ဆုံးသိရှိထားသောတည်နေရာကို မရယူနိုင်ပါ။ ထပ်ကြိုးစားနိုင်သည်။';
  @override
  String get openAppSettings => 'အက်ပ်ဆက်တင်ဖွင့်ရန်';
  @override
  String get openLocationSettings => 'တည်နေရာဆက်တင်ဖွင့်ရန်';
  @override
  String get couldNotOpenLocationSettings => 'တည်နေရာဆက်တင်ကို ဖွင့်မရပါ။';
  @override
  String locationCoordinates(String latitude, String longitude) =>
      'တည်နေရာ - $latitude, $longitude';
  @override
  String locationCapturedAt(String time) => 'တည်နေရာအချိန် - $time';
  @override
  String lastKnownLocationAt(String time) => 'နောက်ဆုံးသိရှိချိန် - $time';
  @override
  String get simulationLabel => 'စမ်းသပ်မှု';
  @override
  String get simulationNavigationHeading =>
      'စမ်းသပ်မှုအမိုးအကာနှင့် လမ်းကြောင်းအချက်အလက်';
  @override
  String navigationSource(String source) => 'ရင်းမြစ် - $source';
  @override
  String get openStreetMapAttribution => '© OpenStreetMap contributors';
  @override
  String shelterDataTime(String time) => 'အမိုးအကာအချက်အလက် - $time';
  @override
  String hazardDataTime(String time) => 'အန္တရာယ်အချက်အလက် - $time';
  @override
  String navigationCachedAt(String time) =>
      'အော့ဖ်လိုင်းအသုံးပြုရန် သိမ်းထားချိန် - $time';
  @override
  String get navigationDataLoading =>
      'အမိုးအကာနှင့် အန္တရာယ်အချက်အလက်များကို ဖွင့်နေသည်';
  @override
  String get navigationDataUnavailable =>
      'အမိုးအကာ သို့မဟုတ် အန္တရာယ်အချက်အလက်ကို အပ်ဒိတ်မလုပ်နိုင်ပါ။';
  @override
  String get contextAnalysisUnavailable =>
      'အနီးအနားခွဲခြမ်းစိတ်ဖြာမှု မရနိုင်ပါ။ Backend ချိတ်ဆက်မှုကို စစ်ဆေးပါ သို့မဟုတ် ငလျင်/ရေကြီးမှု ခွဲခြမ်းစိတ်ဖြာမှုကို ရွေးပါ။';
  @override
  String get navigationCachedWarning =>
      'ယခင်ဖွင့်ထားသော အချက်အလက်များကို ပြသနေပြီး ခေတ်နောက်ကျနေနိုင်သည်။';
  @override
  String get retryNavigationData =>
      'အမိုးအကာနှင့် အန္တရာယ်အချက်အလက် ထပ်ယူရန်';
  @override
  String get mapConfigurationUnavailableTitle => 'မြေပုံဖွဲ့စည်းမှု မရနိုင်ပါ';
  @override
  String get mapConfigurationUnavailableDescription =>
      'မှန်ကန်သော အများသုံး Mapbox token မပေးထားပါ။ တည်နေရာ၊ အမိုးအကာ၊ အန္တရာယ်နှင့် လမ်းကြောင်းထိန်းချုပ်မှုများ ရှိနေသော်လည်း မြေပုံကို မပြနိုင်ပါ။';
  @override
  String get mapTemporarilyUnavailableTitle => 'မြေပုံ ယာယီမရနိုင်ပါ';
  @override
  String get mapTemporarilyUnavailableDescription =>
      'စက်အော့ဖ်လိုင်းဖြစ်နေခြင်း သို့မဟုတ် မြေပုံဖွဲ့စည်းမှု မရနိုင်ခြင်းကြောင့် Mapbox မြေပုံ သို့မဟုတ် ပုံစံအချက်အလက်ကို မဖွင့်နိုင်ပါ။ အမိုးအကာအသေးစိတ်နှင့် ထိန်းချုပ်မှုများ ရှိနေပါမည်။';
  @override
  String get mapContentSemantics =>
      'လက်ရှိ သို့မဟုတ် နောက်ဆုံးသိရှိထားသောတည်နေရာ၊ မြေပုံပေါ်ရှိအမိုးအကာများ၊ သက်ဆိုင်ရာအန္တရာယ်များနှင့် လမ်းကြောင်းရွေးချယ်စရာများကို ပြသသည့် အပြန်အလှန်မြေပုံ။ တည်နေရာခလုတ် သို့မဟုတ် တည်နေရာအမှတ်ကို နှိပ်၍ အသေးစိတ်ကြည့်ပါ။ ရွေးထားသောလမ်းကြောင်းသည် ပိုကျယ်သောမျဉ်းဖြစ်သည်။';
  @override
  String get mapLegendTitle => 'မြေပုံအညွှန်း';
  @override
  String get mapLegendLocation => 'သင့်တည်နေရာ';
  @override
  String get mapLegendShelter => 'မြေပုံပေါ်ရှိအမိုးအကာ';
  @override
  String get mapLegendHazard => 'မြေပုံပေါ်ရှိအန္တရာယ်';
  @override
  String get mapLegendContextArea => 'အကြံပြုဧရိယာ';
  @override
  String get mapLegendRoute => 'အကြံပြုလမ်းကြောင်း';
  @override
  String get mapLegendNearbySos => 'အတည်မပြုရသေးသော အနီးအနား SOS';
  @override
  String get chooseShelter => 'အမိုးအကာ သို့မဟုတ် အကြံပြုနေရာ';
  @override
  String get shelterListHeading =>
      'ရရှိနိုင်သော မြေပုံပေါ်ရှိအမိုးအကာများ';
  @override
  String get shelterListEmpty => 'အော့ဖ်လိုင်းအမိုးအကာအသေးစိတ် မရရှိပါ။';
  @override
  String get contextAreasHeading =>
      'ထိတွေ့မှုနည်းနိုင်သော ထိပ်တန်းအကြံပြုချက်များ';
  @override
  String get contextAreasDescription =>
      'ရရှိနိုင်ပါက မြေပုံပေါ်ရှိ ပန်းခြံ၊ ကွင်းနှင့် အခြားနေရာများ၏ အမည်များကို အသုံးပြုသည်။ ရရှိနိုင်သော မြေပုံတိုင်းတာချက်များနှင့် ကန့်သတ်ချက်များကို နှိုင်းယှဉ်ပါ။ ၎င်းတို့သည် တရားဝင်အမိုးအကာ သို့မဟုတ် အာမခံချက်များ မဟုတ်ပါ။';
  @override
  String get contextSummaryTitle => 'ပတ်ဝန်းကျင်အနှစ်ချုပ်';
  @override
  String get contextSummaryDescription =>
      'ရွေးထားသော ကိုယ်စားပြုဧရိယာ၏ မြေပုံတိုင်းတာချက်၊ အကြောင်းပြချက်၊ ရင်းမြစ်၊ အချိန်နှင့် ကန့်သတ်ချက်များကို စစ်ဆေးပါ။ တရားဝင်အမိုးအကာ သို့မဟုတ် အာမခံချက် မဟုတ်ပါ။';
  @override
  String get contextSummaryNoMappedHazards =>
      'မြေပုံပေါ်တွင် အန္တရာယ်မတွေ့ပါ။ ဤအချက်က ဧရိယာဘေးကင်းကြောင်း အတည်မပြုပါ။';
  @override
  String get analyzeContext => 'အနီးအနားဧရိယာများ ခွဲခြမ်းစိတ်ဖြာရန်';
  @override
  String get analyzingContext => 'ပတ်ဝန်းကျင်ကို ခွဲခြမ်းစိတ်ဖြာနေသည်';
  @override
  String get noContextAreas =>
      'ဤအခြေအနေအတွက် ထိတွေ့မှုနည်းနိုင်သော ဧရိယာမတွေ့ပါ။ တရားဝင်ဒေသဆိုင်ရာ ညွှန်ကြားချက်များကို လိုက်နာပါ။';
  @override
  String get contextSelectedCandidate => 'ရွေးထားသော ကိုယ်စားပြုဧရိယာ';
  @override
  String get contextSelectCandidate => 'ကိုယ်စားပြုဧရိယာ ရွေးရန်';
  @override
  String contextSuggestionRank(int rank) => 'အကြံပြုချက် $rank';
  @override
  String get contextCandidateSelectionHint =>
      'အသေးစိတ်စစ်ဆေးရန် ဤကိုယ်စားပြုဧရိယာကို ရွေးပါ။ လမ်းကြောင်းတောင်းဆိုမှုသည် သီးခြားလုပ်ဆောင်ချက်ဖြစ်သည်။';
  @override
  String get contextNoCandidateSelected =>
      'ကိုယ်စားပြုဧရိယာ မရွေးရသေးပါ။ အသေးစိတ်စစ်ဆေးရန် အပေါ်မှတစ်ခုကို ရွေးပါ။';
  @override
  String get chooseContextScenario => 'ငလျင်ပတ်ဝန်းကျင်';
  @override
  String get outdoorsAfterShaking =>
      'လှုပ်ခတ်မှုရပ်ပြီးနောက် - နေရာလွတ်များ ခွဲခြမ်းစိတ်ဖြာရန်';
  @override
  String get activeShaking =>
      'လှုပ်ခတ်နေစဉ် - ချက်ချင်းလမ်းညွှန်မှု ပြရန်';
  @override
  String contextDistance(int distance) => 'အကွာအဝေး - $distance မီတာ';
  @override
  String contextElevation(String elevation) =>
      'နှိုင်းယှဉ်မြေမျက်နှာပြင်အမြင့် - $elevation မီတာ';
  @override
  String contextClearance(int building, int tree) =>
      'အဆောက်အအုံရှင်းလင်းအကွာ - $building မီတာ၊ သစ်ပင်ရှင်းလင်းအကွာ - $tree မီတာ';
  @override
  String get contextMetricsHeading => 'မြေပုံတိုင်းတာချက်များ နှိုင်းယှဉ်မှု';
  @override
  String contextBuildingDensity(String density) =>
      'မြေပုံပေါ်ရှိ အဆောက်အအုံသိပ်သည်းမှု - $density%';
  @override
  String contextTreeDensity(String density) =>
      'မြေပုံပေါ်ရှိ သစ်ပင်သိပ်သည်းမှု - $density%';
  @override
  String contextHazardIntersections(int count) =>
      'မြေပုံပေါ်ရှိ အန္တရာယ်ဖြတ်တောက်မှု - $count';
  @override
  String get contextRationaleHeading => 'ဤဧရိယာ ပါဝင်ရသည့်အကြောင်း';
  @override
  String contextDataAt(String time) => 'ခွဲခြမ်းစိတ်ဖြာအချက်အလက် - $time';
  @override
  String get contextDataHeading => 'အချက်အလက်၊ ရင်းမြစ်နှင့် ကန့်သတ်ချက်များ';
  @override
  String get contextRouteSelectionDescription =>
      'အပေါ်မှ ကိုယ်စားပြုဧရိယာတစ်ခုကို ရွေးပြီး လမ်းကြောင်းကို သီးခြားတောင်းဆိုပါ။ လမ်းကြောင်းကို အလိုအလျောက် မတောင်းဆိုပါ။';
  @override
  String get sosBluetoothShareTitle =>
      'ကန့်သတ်ထားသော SOS အချက်အလက်ကို အနီးအနားတွင် မျှဝေရန်';
  @override
  String get sosBluetoothShareDescription =>
      'ယာယီ ID၊ အချိန်၊ ရရှိပါက ကိုဩဒိနိတ်အတိအကျ၊ တည်နေရာအခြေအနေနှင့် ဘက်ထရီအဆင့်ကို အနီးအနား SafeMyanmar အသုံးပြုသူများထံ ၁၀ မိနစ်ကြာ ထုတ်လွှင့်ပါ။';
  @override
  String get sosBluetoothFields =>
      'မျှဝေမည့်အရာ - ယာယီဖြစ်ရပ် ID၊ UTC အချိန်၊ ရရှိပါက ကိုဩဒိနိတ်အတိအကျ၊ တည်နေရာအခြေအနေနှင့် ဘက်ထရီအဆင့်။';
  @override
  String get sosBluetoothTenMinuteLimit =>
      'ထုတ်လွှင့်မှုသည် ၁၀ မိနစ်အကြာတွင် အလိုအလျောက်ရပ်မည်။ အမည်၊ အဆက်အသွယ်နှင့် စာသားကို မထုတ်လွှင့်ပါ။';
  @override
  String get sosBluetoothUnavailable =>
      'ဤစက်တွင် Bluetooth SOS မရနိုင်ပါ သို့မဟုတ် Bluetooth ပိတ်ထားသည်။';
  @override
  String get sosBluetoothPermissionRequired =>
      'Bluetooth SOS အသုံးပြုရန် အနီးအနားစက်နှင့် အသိပေးချက်ခွင့်ပြုချက် လိုအပ်သည်။';
  @override
  String get sosBluetoothPermissionSettings =>
      'အက်ပ်ဆက်တင်တွင် Bluetooth နှင့် အသိပေးချက်ခွင့်ပြုချက်များကို စစ်ဆေးပါ။';
  @override
  String get sosBluetoothDisabled =>
      'Bluetooth ပိတ်ထားသည်။ ဖွင့်ပြီး ထပ်ကြိုးစားပါ။';
  @override
  String get sosBluetoothReceiveTitle =>
      'အနီးအနား SOS သတိပေးချက်များ လက်ခံရန်';
  @override
  String get sosBluetoothReceiveDescription =>
      'ဤမျက်နှာပြင်ဖွင့်ထားစဉ် နားထောင်ပါ။ လက်ခံရရှိသောဖြစ်ရပ်များသည် အတည်မပြုရသေးဘဲ ကယ်ဆယ်ရေးတုံ့ပြန်မှုကို အတည်မပြုပါ။';
  @override
  String get sosBluetoothBackgroundReceiveTitle =>
      'နောက်ခံတွင် SOS သတိပေးချက်များ လက်ခံရန်';
  @override
  String get sosBluetoothBackgroundReceiveDescription =>
      'SafeMyanmar မဖွင့်ထားချိန်တွင် Android လက်ခံစနစ်ကို ဆက်လက်ဖွင့်ထားပါ။ အမြဲတမ်းအသိပေးချက်ကို အသုံးပြုပြီး အတည်ပြုထားသော ယာယီ frame များကိုသာ သိမ်းသည်၊ ပြန်လည်ထုတ်လွှင့်ခြင်း မပြုပါ။';
  @override
  String get sosBluetoothRelayTitle =>
      'အနီးအနား SOS သတိပေးချက်ကို တစ်ကြိမ် ပြန်လည်ထုတ်လွှင့်ရန်';
  @override
  String get sosBluetoothRelayDescription =>
      'မှန်ကန်သော အနီးအနား SOS frame တစ်ခုစီကို Bluetooth ဖြင့်သာ တစ်ကြိမ် ပြန်လည်ထုတ်လွှင့်ရန် ဤစက်ကို အတိအလင်းခွင့်ပြုပါ။ မည်သည့်အရာမျှ အပ်လုဒ်မလုပ်ပါ။';
  @override
  String sosBluetoothRelayCount(int count) =>
      'ဤစက်ရှင်တွင် ပြန်လည်ထုတ်လွှင့်ထားသော frame - $count';
  @override
  String get sosBluetoothSoundTitle => 'သတိပေးအသံ ပြုလုပ်ရန်';
  @override
  String get sosBluetoothSoundDescription =>
      'အတည်မပြုရသေးသော အနီးအနား SOS တွေ့ရှိလျှင် အသံမြည်ရန် ခွင့်ပြုပါ။';
  @override
  String get sosBluetoothBroadcasting =>
      'Bluetooth SOS သည် ကန့်သတ်ထားသော အချက်အလက်များကို ထုတ်လွှင့်နေသည်။';
  @override
  String get sosBluetoothBroadcastFrameDetails =>
      'ထုတ်လွှင့်သော frame အသေးစိတ်';
  @override
  String get sosBluetoothStop => 'ရပ်ရန်';
  @override
  String get sosBluetoothNearbyAlert => 'အတည်မပြုရသေးသော အနီးအနား SOS';
  @override
  String get sosBluetoothDismiss => 'အနီးအနား SOS ပယ်ဖျက်ရန်';
  @override
  String get sosBluetoothUnverified =>
      'အခြားစက်မှ လက်ခံရရှိခြင်းဖြစ်ပြီး ကယ်ဆယ်ရေးဝန်ဆောင်မှုထံ ရောက်ရှိကြောင်း အတည်မပြုပါ။';
  @override
  String sosBluetoothGridLocation(String latitude, String longitude) =>
      'ကိုဩဒိနိတ် - $latitude, $longitude';
  @override
  String get sosBluetoothCurrentLocation =>
      'SOS ပြင်ဆင်ချိန်တွင် လက်ရှိတည်နေရာဟု ဖော်ပြထားသည်။';
  @override
  String get sosBluetoothLastKnownLocation =>
      'SOS ပြင်ဆင်ချိန်တွင် နောက်ဆုံးသိရှိထားသောတည်နေရာဟု ဖော်ပြထားသည်။';
  @override
  String get sosBluetoothLocationUnavailable => 'တည်နေရာ မရရှိပါ။';
  @override
  String get sosBluetoothUnknownValue => 'မသိရသေးပါ';
  @override
  String sosBluetoothEventId(String id) => 'ဖြစ်ရပ် ID - $id';
  @override
  String sosBluetoothTimestamp(String time) => 'UTC အချိန် - $time';
  @override
  String sosBluetoothBatteryValue(int value) => 'ဘက်ထရီ - $value%';
  @override
  String sosBluetoothRssiValue(int value) =>
      'အချက်ပြ - $value dBm၊ အနီးအဝေးမှာ ခန့်မှန်းခြေဖြစ်သည်';
  @override
  String sosBluetoothProtocol(int version, int ttl) =>
      'ပရိုတိုကော - v$version၊ TTL - $ttl မိနစ်';
  @override
  String sosBluetoothRelayHops(int count) => 'ပြန်လည်ထုတ်လွှင့်မှုအဆင့် - $count';
  @override
  String get sosBluetoothApproximateNotice =>
      'ကိုဩဒိနိတ်များကို အခြားစက်က ပေးထားခြင်းဖြစ်ပြီး အတည်မပြုရသေးပါ။';
  @override
  String sosBluetoothMapsLink(String url) => 'Google Maps - $url';
  @override
  String get sosBluetoothOpenMaps => 'Google Maps တွင် ဖွင့်ရန်';
  @override
  String get sosBluetoothShowAll => 'SOS အမှတ်များအားလုံး ပြရန်';
  @override
  String get sosBluetoothMapEventsHeading => 'အနီးအနား SOS ရင်းမြစ်များ';
  @override
  String sosBluetoothSourceLabel(Object index) => 'SOS ရင်းမြစ် $index';
  @override
  String get sosBluetoothSelectedEventHeading =>
      'ရွေးထားသော SOS အသေးစိတ်';
  @override
  String sosBluetoothSelectEvent(int index) =>
      'အနီးအနား SOS $index ကို ရွေးရန်';
  @override
  String get sosBluetoothBroadcastStarted =>
      'Bluetooth SOS မျှဝေမှုသည် ၁၀ မိနစ်အထိ အသုံးပြုနေသည်။';
  @override
  String get sosBluetoothBroadcastFailed =>
      'Bluetooth SOS မျှဝေမှုကို မစတင်နိုင်ပါ။ အနီးအနားသို့ အချက်အလက်မထုတ်လွှင့်ခဲ့ပါ။';
  @override
  String get sosBluetoothOperationFailed =>
      'Bluetooth ပိတ်ထားသည် သို့မဟုတ် အနီးအနားစက်လုပ်ဆောင်ချက်ကို မစတင်နိုင်ပါ။';
  @override
  String get chooseDisasterType => 'ဘေးအန္တရာယ်အမျိုးအစား';
  @override
  String get chooseTravelProfile => 'ခရီးသွားပုံစံ';
  @override
  String get earthquakeDisaster => 'ငလျင်';
  @override
  String get floodDisaster => 'ရေကြီးမှု';
  @override
  String get fireDisaster => 'မီးလောင်မှု';
  @override
  String get cycloneDisaster => 'မုန်တိုင်း';
  @override
  String get landslideDisaster => 'မြေပြိုမှု';
  @override
  String get severeWeatherDisaster => 'ပြင်းထန်ရာသီဥတု';
  @override
  String get walkingProfile => 'လမ်းလျှောက်ခြင်း';
  @override
  String get drivingProfile => 'ကားမောင်းခြင်း';
  @override
  String get requestRouteSuggestions => 'လမ်းကြောင်းအကြံပြုချက် တောင်းရန်';
  @override
  String get retryRouteSuggestions =>
      'လမ်းကြောင်းအကြံပြုချက် ထပ်တောင်းရန်';
  @override
  String get updatingRouteSuggestions =>
      'လမ်းကြောင်းအကြံပြုချက် တောင်းနေသည်';
  @override
  String get routingUnavailable =>
      'လမ်းကြောင်းအကြံပြုချက်ကို အပ်ဒိတ်မလုပ်နိုင်ပါ။ အမိုးအကာနှင့် အန္တရာယ်များကို ဆက်လက်မြင်ရမည်၊ ထပ်ကြိုးစားပါ။';
  @override
  String get cachedRouteWarning =>
      'ယခင်ရရှိထားသော လမ်းကြောင်းတုံ့ပြန်ချက်ကို ပြသနေပြီး ခေတ်နောက်ကျနေသည်။';
  @override
  String cachedRouteAt(String time) => 'လမ်းကြောင်းသိမ်းထားချိန် - $time';
  @override
  String get noRoutesReturned =>
      'ဆာဗာက လမ်းကြောင်းရွေးချယ်စရာ မပြန်ပေးပါ။ SafeMyanmar က အခြားလမ်းကြောင်း မဖန်တီးထားပါ။';
  @override
  String get routeSuggested => 'အကြံပြုထားသည်';
  @override
  String routeAlternative(int number) => 'အခြားရွေးချယ်စရာ $number';
  @override
  String get routeSelected => 'ရွေးထားသောလမ်းကြောင်း';
  @override
  String routeProfileValue(String profile) => 'ပုံစံ - $profile';
  @override
  String routeDistanceValue(String distance) => 'အကွာအဝေး - $distance မီတာ';
  @override
  String routeDurationValue(String duration) => 'ကြာချိန် - $duration မိနစ်';
  @override
  String routeHazardIntersections(int count) => 'အန္တရာယ်ဖြတ်တောက်မှု - $count';
  @override
  String routeRationale(String rationale) => 'အကြောင်းပြချက် - $rationale';
  @override
  String routeGeneratedAt(String time) => 'ဖန်တီးချိန် - $time';
  @override
  String routeHazardDataAt(String time) => 'အန္တရာယ်အချက်အလက်အချိန် - $time';
  @override
  String routeDirectionsProvider(String provider) => 'လမ်းညွှန်ပေးသူ - $provider';
  @override
  String routeProfileReason(String reason) =>
      'ပုံစံရွေးချယ်ရသည့်အကြောင်း - $reason';
  @override
  String uncertaintyNotice(String notice) => 'မသေချာမှု - $notice';
  @override
  String get mapSuggestedSelectedLabel =>
      'အကြံပြုထားသော ရွေးချယ်လမ်းကြောင်း';
  @override
  String mapAlternativeLabel(int number) => 'အခြားရွေးချယ်စရာ $number';
  @override
  String get sosTitle => 'SOS';
  @override
  String get sosIntroduction =>
      'သင်ရွေးထားသောသူများထံ ပေးပို့မည့် အရေးပေါ် SMS ကို ပြင်ဆင်ပါ။ ဤမျက်နှာပြင်ဖွင့်ရုံဖြင့် ပြင်ဆင်ခြင်း သို့မဟုတ် ပေးပို့ခြင်း မပြုပါ။';
  @override
  String get sosSetupTitle => 'SOS ပြင်ဆင်မှု';
  @override
  String get sosSetupDescription =>
      'အတည်မပြုမီ အဆက်အသွယ်များ၊ ရွေးချယ်နိုင်သောစာ၊ တည်နေရာမျှဝေမှုနှင့် စာသားအတိအကျကို စစ်ဆေးပါ။';
  @override
  String get sosReadinessReady => 'စစ်ဆေးရန် အသင့်ဖြစ်သည်';
  @override
  String get sosReadinessNeedsContact =>
      'အရေးပေါ်အဆက်အသွယ်ကို ဦးစွာရွေးပါ';
  @override
  String get sosReadinessLocationUnavailable =>
      'တည်နေရာမရနိုင်ပါ၊ ကိုဩဒိနိတ်မပါဘဲ ဆက်လုပ်ပါ';
  @override
  String get sosRecipientsHeading => 'ရွေးထားသော လက်ခံသူများ';
  @override
  String sosRecipientPreview(String name, String phoneNumber) =>
      '$name - $phoneNumber';
  @override
  String get sosNoRecipientsTitle => 'အဆက်အသွယ် မရွေးထားပါ';
  @override
  String get sosNoRecipientsDescription =>
      'SOS draft ပြင်ဆင်မီ သိမ်းထားသော အရေးပေါ်အဆက်အသွယ် အနည်းဆုံးတစ်ဦးကို ရွေးပါ။';
  @override
  String get sosManageContacts =>
      'နောက်ထပ်တွင် အဆက်အသွယ်များဖွင့်ရန်';
  @override
  String get sosSharedDataHeading => 'SMS စာသားအတိအကျ အစမ်းပြ';
  @override
  String get sosStoredDataHeading =>
      'လုံခြုံစွာသိမ်းထားသော draft အသေးစိတ်';
  @override
  String sosProfileNamePreview(String name) => 'ပရိုဖိုင်အမည် - $name';
  @override
  String get sosProfileNameUnavailable =>
      'ပရိုဖိုင်အမည် - မပါဝင်ပါ';
  @override
  String sosCurrentLocationPreview(
    String precision,
    String latitude,
    String longitude,
    String time,
  ) => 'လက်ရှိ $precision တည်နေရာ - $latitude, $longitude။ ဖမ်းယူချိန် $time။';
  @override
  String sosLastKnownLocationPreview(
    String precision,
    String latitude,
    String longitude,
    String time,
  ) =>
      'နောက်ဆုံးသိရှိထားသော $precision တည်နေရာ - $latitude, $longitude။ ဖမ်းယူချိန် $time။';
  @override
  String get sosLocationUnavailable =>
      'တည်နေရာမရနိုင်ပါ။ ကိုဩဒိနိတ်မပါဝင်ပါ။';
  @override
  String get sosPrecise => 'တိကျသော';
  @override
  String get sosApproximate => 'အနီးစပ်ဆုံး';
  @override
  String sosDraftCreatedAt(String time) => 'ဖန်တီးချိန် - $time';
  @override
  String get sosDraftCreatedWhenConfirmed =>
      'အတည်ပြုချိန်တွင် ဖန်တီးချိန်ကို မှတ်တမ်းတင်မည်။';
  @override
  String get sosOptionalMessageLabel =>
      'ရွေးချယ်နိုင်သော တိုတောင်းသည့်စာ';
  @override
  String get sosOptionalMessageHint =>
      'ဥပမာ - ဤဧရိယာမှ ထွက်ခွာရန် အကူအညီလိုသည်။';
  @override
  String get sosLocationSharingTitle =>
      'ဤ SOS တွင် တည်နေရာထည့်ရန်';
  @override
  String get sosLocationSharingDescription =>
      'ဤ SOS အတွက် ဖွင့်မှသာ တည်နေရာမျှဝေမည်။ ရှိပြီးသားတည်နေရာခွင့်ပြုချက်ကို ပြန်သုံးပါမည်။';
  @override
  String get sosLocationSharingUnavailable =>
      'တည်နေရာရယူမရပါ။ ဤ SOS တွင် ကိုဩဒိနိတ်မပါဝင်ပါ။';
  @override
  String get sosLocationSharingUnavailableTitle =>
      'တည်နေရာမရနိုင်ပါ';
  @override
  String get sosLocationSharingUnavailableDescription =>
      'ကိုဩဒိနိတ်မပါဘဲ SOS ကို ပြင်ဆင်နိုင်သည်။ တည်နေရာမမျှဝေဘဲ ဆက်လုပ်မလား။';
  @override
  String get sosContinueWithoutLocation =>
      'တည်နေရာမပါဘဲ ဆက်လုပ်ရန်';
  @override
  String get sosComposerDisclosure =>
      'SafeMyanmar သည် သင့်ဖုန်း၏ စာပို့အက်ပ်ကိုသာ ဖွင့်ပေးသည်။ SMS ပေးပို့ခြင်းနှင့် ရောက်ရှိမှုကို ထိုအက်ပ်က ထိန်းချုပ်ပြီး SafeMyanmar က မစစ်ဆေးနိုင်ပါ။';
  @override
  String get sosDirectSmsDisclosure =>
      'အတည်ပြုပြီးနောက် SafeMyanmar သည် SMS ခွင့်ပြုချက်တောင်းကာ Android မှတစ်ဆင့် စစ်ဆေးထားသောစာကို တိုက်ရိုက်ပေးပို့သည်။ ဝန်ဆောင်မှုပေးသူက ပေးပို့မှုနှောင့်နှေးနိုင်ပြီး SafeMyanmar သည် စက်က SMS လက်ခံထားခြင်းကိုသာ အတည်ပြုနိုင်သည်။';
  @override
  String get sosHoldToOpen => 'SMS ပေးပို့ရန် ၃ စက္ကန့် ဖိထားပါ';
  @override
  String sosHoldProgress(int percent) => 'ဆက်ဖိထားပါ - $percent%';
  @override
  String get sosHoldCancelled =>
      'ဖိထားမှု ပယ်ဖျက်လိုက်သည်။ မည်သည့်အရာမျှ မပေးပို့ပါ။';
  @override
  String get sosHoldSemanticsHint =>
      '၃ စက္ကန့်ဆက်တိုက် ဖိထားပါ။ အသုံးပြုနိုင်သော အတည်ပြုလမ်းကြောင်းအတွက် ဖွင့်ပါ။';
  @override
  String get sosAccessibleConfirmation =>
      'အတည်ပြုဒိုင်ယာလော့ခ်ကို အစားထိုးအသုံးပြုရန်';
  @override
  String get sosConfirmPreviewTitle =>
      'SOS draft အသေးစိတ်ကို အတည်ပြုရန်';
  @override
  String get sosConfirmPreviewDescription =>
      'ဤမျက်နှာပြင်ရှိ လက်ခံသူများနှင့် SMS အစမ်းပြစာသားအတိအကျကို စစ်ဆေးပါ။ ဤ draft ကို ပြင်ဆင်လိုမှသာ ဆက်လုပ်ပါ။';
  @override
  String get sosContinue => 'ဆက်လုပ်ရန်';
  @override
  String get sosConfirmComposerTitle =>
      'စာပို့အက်ပ်ကို ဖွင့်မလား။';
  @override
  String get sosConfirmComposerDescription =>
      'ဤဒုတိယအတည်ပြုမှုသည် လုံခြုံသော draft ကို ပြင်ဆင်ပြီး လက်ခံသူများနှင့် စာသားဖြည့်ထားသော စာပို့အက်ပ်ကို ဖွင့်ရန် ဖုန်းကို တောင်းဆိုသည်။ ထိုအက်ပ်တွင် ပေးပို့မပေးပို့ သင်ရွေးချယ်ရမည်။';
  @override
  String get sosOpenMessaging =>
      'စာပို့ရန် ပြင်ဆင်ပြီးဖွင့်ရန်';
  @override
  String get sosConfirmSmsTitle =>
      'SOS SMS ကို တိုက်ရိုက်ပေးပို့မလား။';
  @override
  String get sosConfirmSmsDescription =>
      'ဤဒုတိယအတည်ပြုမှုသည် လုံခြုံသော draft ကို ပြင်ဆင်ပြီး Android SMS ခွင့်ပြုချက်ရရှိပါက ရွေးထားသောအဆက်အသွယ်များထံ စစ်ဆေးထားသော SMS ကို တိုက်ရိုက်ပေးပို့သည်။ စက်လက်ခံခြင်းသည် ဝန်ဆောင်မှုပေးသူထံ ရောက်ရှိမည်ဟု အာမမခံပါ။';
  @override
  String get sosSendSms => 'SMS ယခုပေးပို့ရန်';
  @override
  String get sosRetrySmsTitle =>
      'ဤ SOS draft ကို ထပ်ပေးပို့မလား။';
  @override
  String get sosRetrySmsDescription =>
      'SafeMyanmar သည် သိမ်းထားသောစာကို Android SMS မှတစ်ဆင့် တိုက်ရိုက်ပေးပို့မည်။ စက်လက်ခံခြင်းသည် ဝန်ဆောင်မှုပေးသူထံ ရောက်ရှိမည်ဟု အာမမခံပါ။';
  @override
  String get sosRetrySmsUncertainDescription =>
      'ယခင် SMS ကြိုးပမ်းမှုရလဒ်သည် တစ်စိတ်တစ်ပိုင်း သို့မဟုတ် မသေချာပါ။ ထပ်ပေးပို့လျှင် စာနှစ်ကြိမ်ဖြစ်နိုင်သောကြောင့် ထိုအန္တရာယ်ကို လက်ခံနိုင်မှသာ ဆက်လုပ်ပါ။';
  @override
  String get sosNotNow => 'ယခုမဟုတ်ပါ';
  @override
  String get sosComposerOpenedNotice =>
      'စာပို့အက်ပ်ကို ဖွင့်လိုက်သည်။ SMS ပေးပို့မှု သို့မဟုတ် ရောက်ရှိမှုကို SafeMyanmar က မစစ်ဆေးနိုင်ပါ။ ထပ်ကြိုးစားရန် သို့မဟုတ် ဖယ်ရှားရန် draft ကို သိမ်းထားသည်။';
  @override
  String get sosComposerFailedNotice =>
      'စာပို့အက်ပ်ကို ဖွင့်မရပါ။ ပြင်ဆင်ထားသော draft ကို ထပ်ကြိုးစားရန် သို့မဟုတ် ဖယ်ရှားရန် သိမ်းထားသည်။';
  @override
  String get sosDraftSaveFailed =>
      'SOS draft ကို လုံခြုံစွာသိမ်းမရပါ။ SMS မပေးပို့ပါ။';
  @override
  String get sosSmsPermissionDenied =>
      'SMS ခွင့်ပြုချက် မရပါ။ SMS မပေးပို့ပါ၊ ထပ်ကြိုးစားရန် draft ကို သိမ်းထားသည်။';
  @override
  String get sosSmsSentNotice =>
      'စက်က SMS ကို ပေးပို့ရန် လက်ခံထားသည်။ ဝန်ဆောင်မှုပေးသူထံ ရောက်ရှိမှု မအတည်ပြုရသေးပါ၊ draft ကို သိမ်းထားသည်။';
  @override
  String get sosSmsFailedNotice =>
      'စက်က SMS ကို လက်မခံနိုင်ပါ။ SIM/ဝန်ဆောင်မှုနှင့် SMS ခွင့်ပြုချက်ကို စစ်ပြီး draft ကို ထပ်ကြိုးစားပါ။';
  @override
  String get sosSmsUncertainNotice =>
      'SMS ရလဒ်သည် တစ်စိတ်တစ်ပိုင်း သို့မဟုတ် မသေချာပါ။ အချို့စာများ လက်ခံထားနိုင်ပြီး ထပ်ပေးပို့လျှင် နှစ်ကြိမ်ဖြစ်နိုင်သည်။';
  @override
  String get sosSimUnavailable =>
      'အသုံးပြုနိုင်သော SIM မရွေးနိုင်ပါ။ SIM ဝန်ဆောင်မှုကို စစ်ပြီး ထပ်ကြိုးစားပါ။ SMS မပေးပို့ပါ။';
  @override
  String get sosChooseSimTitle => 'SIM ရွေးရန်';
  @override
  String get sosChooseSimDescription =>
      'ဤ SOS စာကို ပေးပို့မည့် အသုံးပြုနိုင်သော SIM ကို ရွေးပါ။';
  @override
  String get sosRememberSim =>
      'ကျွန်ုပ်နှစ်သက်သော SIM ကို မှတ်ထားရန်';
  @override
  String get sosSendUsingSim => 'ဤ SIM ဖြင့် ပေးပို့ရန်';
  @override
  String sosSimLabel(int slot, String label) => 'SIM $slot - $label';
  @override
  String get sosMaximumDrafts =>
      'လုံခြုံသော SOS queue တွင် draft ၅ ခု ရှိပြီးဖြစ်သည်။ နောက်တစ်ခုမပြင်ဆင်မီ တစ်ခုကို ဖယ်ရှားပါ။';
  @override
  String get sosDraftQueueHeading => 'SOS draft များနှင့် မှတ်တမ်း';
  @override
  String get sosDraftQueueEmpty =>
      'ဤစက်တွင် SOS draft မပြင်ဆင်ရသေးပါ။';
  @override
  String sosStatusLabel(String status) => 'အခြေအနေ - $status';
  @override
  String get sosStatusPrepared => 'ပြင်ဆင်ပြီး';
  @override
  String get sosStatusSmsSending => 'SMS ပေးပို့နေသည်';
  @override
  String get sosStatusSmsSent =>
      'စက်က SMS လက်ခံပြီး၊ ရောက်ရှိမှုမသေချာ';
  @override
  String get sosStatusSmsPartial =>
      'SMS တစ်စိတ်တစ်ပိုင်းလက်ခံပြီး၊ ရောက်ရှိမှုမသေချာ';
  @override
  String get sosStatusSmsUnknown =>
      'SMS ရလဒ်မသိရသေး၊ ထပ်ပေးပို့လျှင် နှစ်ကြိမ်ဖြစ်နိုင်';
  @override
  String get sosStatusSmsFailed =>
      'SMS မအောင်မြင်၊ ထပ်ကြိုးစားနိုင်သည်';
  @override
  String get sosStatusComposerOpened =>
      'စာပို့အက်ပ်ဖွင့်ပြီး၊ ရလဒ်မသိရသေး';
  @override
  String get sosStatusFailedToOpen => 'စာပို့အက်ပ်ဖွင့်မရ';
  @override
  String get sosStatusCancelled => 'ပယ်ဖျက်ပြီး';
  @override
  String get sosOpenAgain => 'ထပ်ပေးပို့ရန်';
  @override
  String get sosCancelDraft => 'Draft ပယ်ဖျက်ရန်';
  @override
  String get sosRemoveDraft => 'Draft ဖယ်ရှားရန်';
  @override
  String get sosRetryComposerTitle =>
      'ဤ draft ကို ထပ်ဖွင့်မလား။';
  @override
  String get sosRetryComposerDescription =>
      'SafeMyanmar သည် သိမ်းထားသော draft ဖြင့် စာပို့ရန် ဖုန်းကို တောင်းဆိုမည်။ ထိုအက်ပ်တွင် ပေးပို့မပေးပို့ သင်ရွေးချယ်ရမည်။';
  @override
  String get sosCancelDraftTitle =>
      'ဤ draft ကို ပယ်ဖျက်မလား။';
  @override
  String get sosCancelDraftDescription =>
      'Draft သည် ပယ်ဖျက်ထားသောအခြေအနေဖြင့် မှတ်တမ်းတွင် ဆက်ရှိမည်၊ အလိုအလျောက် မဖွင့်ပါ။';
  @override
  String get sosRemoveDraftTitle =>
      'ဤ draft ကို ဖယ်ရှားမလား။';
  @override
  String get sosRemoveDraftDescription =>
      'ဤစက်၏ လုံခြုံသောသိမ်းဆည်းမှုမှ draft snapshot ကို အပြီးတိုင်ဖယ်ရှားမည်။';
  @override
  String get sosQueueLoading =>
      'လုံခြုံသော SOS draft များကို ဖွင့်နေသည်';
  @override
  String get sosQueueReadErrorTitle =>
      'SOS draft များ ယာယီမရနိုင်ပါ';
  @override
  String get sosQueueReadErrorDescription =>
      'လုံခြုံသော SOS queue ကို SafeMyanmar က မဖတ်နိုင်ပါ။ ကိုယ်ရေးကိုယ်တာ draft အသေးစိတ် မပေါက်ကြားပါ။ ထပ်ကြိုးစားပါ။';
  @override
  String get sosQueueDataErrorTitle =>
      'သိမ်းထားသော SOS draft များကို ဖွင့်မရပါ';
  @override
  String get sosQueueDataErrorDescription =>
      'လုံခြုံသော SOS queue ပျက်စီးနေသည် သို့မဟုတ် မထောက်ပံ့သောဗားရှင်းဖြစ်သည်။ မပြောင်းလဲထားပါ။ ထပ်ကြိုးစားပါ သို့မဟုတ် ဤ queue တစ်ခုတည်းကို reset လုပ်ပါ။';
  @override
  String get sosQueueWriteErrorTitle =>
      'SOS draft ပြောင်းလဲမှုကို မသိမ်းနိုင်ပါ';
  @override
  String get sosQueueWriteErrorDescription =>
      'ယခင်သိမ်းထားသော SOS queue ကို ဆက်လက်အသုံးပြုနိုင်သည်။ ပြောင်းလဲမှုကို ထပ်ကြိုးစားပါ။';
  @override
  String get sosResetQueue => 'SOS queue reset လုပ်ရန်';
  @override
  String get sosResetQueueTitle =>
      'ဖတ်မရသော SOS queue ကို reset လုပ်မလား။';
  @override
  String get sosResetQueueDescription =>
      'ဤစက်မှ ဖတ်မရသော SOS draft များကိုသာ အပြီးတိုင်ဖယ်ရှားမည်။ သင့်ပရိုဖိုင်နှင့် အဆက်အသွယ်များ မပြောင်းလဲပါ။';
  @override
  String get sosMessageHeader =>
      'အသုံးပြုသူပြင်ဆင်ထားသော SafeMyanmar အရေးပေါ်စာ။';
  @override
  String sosMessageProfileName(String name) => 'ပရိုဖိုင်အမည် - $name';
  @override
  String sosMessageCurrentLocation(
    String precision,
    String latitude,
    String longitude,
    String time,
    String mapsLink,
  ) =>
      'လက်ရှိ $precision တည်နေရာ - $latitude, $longitude၊ $time။ မြေပုံ - $mapsLink';
  @override
  String sosMessageLastKnownLocation(
    String precision,
    String latitude,
    String longitude,
    String time,
    String mapsLink,
  ) =>
      'နောက်ဆုံးသိရှိထားသော $precision တည်နေရာ - $latitude, $longitude၊ $time။ မြေပုံ - $mapsLink';
  @override
  String get sosMessageLocationUnavailable =>
      'တည်နေရာမရနိုင်ပါ၊ ကိုဩဒိနိတ်မပါဝင်ပါ။';
  @override
  String sosMessageUserText(String message) => 'စာ - $message';
  @override
  String get sosMessageAuthorizedHelp =>
      'ဖြစ်နိုင်လျှင် တရားဝင်အရေးပေါ် သို့မဟုတ် ဆေးဘက်အကူအညီကို ဆက်သွယ်ပါ။';
  @override
  String get guideTitle => 'လမ်းညွှန်';
  @override
  String get guideIntroduction =>
      'ဤစက်တွင် သိမ်းထားသော စစ်ဆေးပြီးသည့် အရေးပေါ်လမ်းညွှန်အသေးစားကို ရှာပါ။ ကွန်ရက်မရှိဘဲ အလုပ်လုပ်သည်။';
  @override
  String get guideOfflineVerifiedLabel =>
      'အော့ဖ်လိုင်းစစ်ဆေးပြီး အကြောင်းအရာရယူမှု';
  @override
  String get guideQuickActionsHeading => 'အမြန်လုပ်ဆောင်ချက်များ';
  @override
  String get guideActionEarthquake => 'ငလျင်';
  @override
  String get guideActionFlood => 'ရေကြီးမှု';
  @override
  String get guideActionFire => 'မီးလောင်မှု';
  @override
  String get guideActionFirstAid => 'ရှေးဦးသူနာပြု';
  @override
  String get guideActionMap => 'မြေပုံဖွင့်ရန်';
  @override
  String get guideActionSos => 'SOS ဖွင့်ရန်';
  @override
  String get guideNextStepsHeading => 'နောက်တစ်ဆင့်';
  @override
  String get guideNextStepMap => 'မြေပုံစစ်ရန်';
  @override
  String get guideNextStepSos => 'SOS စစ်ရန်';
  @override
  String get guideNextStepAssistant => 'အကူကို မေးရန်';
  @override
  String get guideAskAssistant => 'ကန့်သတ်ထားသော အကူကို မေးရန်';
  @override
  String get guideSearchLabel => 'အရေးပေါ်လမ်းညွှန် ရှာရန်';
  @override
  String get guideSearchHint =>
      'ငလျင်၊ ပိတ်မိ၊ ရေကြီးမှု၊ မီး၊ ရှေးဦးသူနာပြု';
  @override
  String get guideSearchAction => 'ရှာရန်';
  @override
  String get guideCategories => 'အမျိုးအစားများ';
  @override
  String get guideCategoryAll => 'အားလုံး';
  @override
  String get guideCategoryEarthquake => 'ငလျင်';
  @override
  String get guideCategoryFlood => 'ရေကြီးမှု';
  @override
  String get guideCategoryFire => 'မီးလောင်မှု';
  @override
  String get guideCategoryFirstAid => 'ရှေးဦးသူနာပြု';
  @override
  String get guideLoading =>
      'အော့ဖ်လိုင်းအရေးပေါ်လမ်းညွှန်ကို ဖွင့်နေသည်';
  @override
  String get guideNoResults =>
      'အတည်ပြုထားသော အော့ဖ်လိုင်းဆောင်းပါးနှင့် ကိုက်ညီမှုမရှိပါ။';
  @override
  String get guideStorageError =>
      'ဤစက်မှ အော့ဖ်လိုင်းလမ်းညွှန်ကို ဖတ်မရပါ။';
  @override
  String get guideArticleTitle => 'အရေးပေါ်လမ်းညွှန်';
  @override
  String get guideArticleUnavailable =>
      'ဤအတည်ပြုထားသော အော့ဖ်လိုင်းဆောင်းပါးကို မရနိုင်ပါ။';
  @override
  String get guideOpenArticleHint =>
      'အတည်ပြုထားသော အရေးပေါ်ဆောင်းပါးဖွင့်ရန်';
  @override
  String get guideApprovedSource => 'အတည်ပြုထားသော ရင်းမြစ်မှတ်တမ်း';
  @override
  String guideSourceName(String source) => 'ရင်းမြစ် - $source';
  @override
  String guideContentVersion(int version) =>
      'အကြောင်းအရာဗားရှင်း - $version';
  @override
  String guideReviewedDate(String date) => 'စစ်ဆေးသည့်ရက် - $date';
  @override
  String guideSourceDate(String date) => 'ရင်းမြစ်အပ်ဒိတ်ရက် - $date';
  @override
  String get guideContentWarning =>
      'အရေးပေါ်အချက်အလက်သည် အခြေအနေတိုင်းကို မဖုံးလွှမ်းနိုင်ပါ။ တရားဝင်ဒေသဆိုင်ရာ ညွှန်ကြားချက်များကို လိုက်နာပြီး ဖြစ်နိုင်လျှင် တရားဝင်ဒေသဆိုင်ရာ အရေးပေါ် သို့မဟုတ် ဆေးဘက်ဝန်ဆောင်မှုကို ဆက်သွယ်ပါ။';
  @override
  String guideSourceSemantics(String source, int version) =>
      'အတည်ပြုရင်းမြစ် $source၊ အကြောင်းအရာဗားရှင်း $version';
  @override
  String get assistantTitle => 'အော့ဖ်လိုင်းအကူ';
  @override
  String get assistantOfflineVerified =>
      'အော့ဖ်လိုင်းစစ်ဆေးပြီး အကြောင်းအရာရယူမှု (ရင်းမြစ်အခြေပြု၊ ဖန်တီးမှုမဟုတ်)';
  @override
  String get assistantDeterministicActive =>
      'ဆုံးဖြတ်ချက်သတ်မှတ်ထားသော အော့ဖ်လိုင်းစစ်ဆေးပြီး အကြောင်းအရာရယူမှု အလုပ်လုပ်နေသည်။';
  @override
  String get assistantOnnxChecking =>
      'ရွေးချယ်နိုင်သော ONNX ရည်ရွယ်ချက်ပြင်ဆင်မှု ရရှိနိုင်မှုကို စစ်ဆေးနေသည်။';
  @override
  String get assistantOnnxAvailable =>
      'ဆုံးဖြတ်ချက်သတ်မှတ်ထားသော ရလဒ်မသိရသောအခါ အသုံးပြုနိုင်သည့် ရွေးချယ်နိုင်သော ONNX ရည်ရွယ်ချက်ပြင်ဆင်မှု ရှိသည်။';
  @override
  String get assistantOnnxUnavailable =>
      'ရွေးချယ်နိုင်သော ONNX ရည်ရွယ်ချက်ပြင်ဆင်မှု မရနိုင်ပါ။ ရွေးချယ်နိုင်သော model မရှိခြင်းသည် ပုံမှန်ဖြစ်ပြီး ဆုံးဖြတ်ချက်သတ်မှတ်ထားသော ရယူမှု ဆက်လက်အလုပ်လုပ်သည်။';
  @override
  String get assistantGemmaChecking =>
      'ရွေးချယ်နိုင်သော Gemma 3 ဒေသတွင်းအကူ ရရှိနိုင်မှုကို စစ်ဆေးနေသည်။';
  @override
  String get assistantGemmaAvailable =>
      'ရွေးချယ်နိုင်သော ဒေသတွင်း Gemma 3 သည် အထွေထွေမေးခွန်းများကို ဖြေနိုင်ပြီး ဘေးအန္တရာယ်နှင့် ကြိုတင်ပြင်ဆင်မှုအကြောင်းအရာများကို ပိုမိုအလေးပေးသည်။';
  @override
  String get assistantGemmaUnavailable =>
      'ရွေးချယ်နိုင်သော ဒေသတွင်း Gemma 3 မရနိုင်ပါ။ model ဖိုင်မရှိခြင်းသည် ပုံမှန်ဖြစ်ပြီး အတည်ပြုထားသော အကြောင်းအရာကို ဆက်လက်အသုံးပြုနိုင်သည်။';
  @override
  String get assistantSuggestedQuestions => 'အကြံပြုမေးခွန်းများ';
  @override
  String get assistantSuggestionEarthquake =>
      'ငလျင်လှုပ်နေစဉ် ဘာလုပ်ရမလဲ။';
  @override
  String get assistantSuggestionTrapped =>
      'ငလျင်ပြီးနောက် ပိတ်မိနေသည်';
  @override
  String get assistantSuggestionFirstAid =>
      'ရှေးဦးသူနာပြုမလုပ်မီ ဘာစစ်ဆေးရမလဲ။';
  @override
  String get assistantSuggestionFlood =>
      'ရေကြီးမှုကို ဘယ်လိုရှောင်ရမလဲ။';
  @override
  String get assistantSearching => 'အော့ဖ်လိုင်းအဖြေကို ပြင်ဆင်နေသည်';
  @override
  String get assistantInputLabel => 'အရေးပေါ်မေးခွန်း';
  @override
  String get assistantInputHint =>
      'အင်္ဂလိပ် သို့မဟုတ် မြန်မာလို ရိုက်ပါ';
  @override
  String get assistantSend => 'မေးခွန်းပေးပို့ရန်';
  @override
  String get assistantVerifiedAnswer =>
      'အတည်ပြုထားသော အကြောင်းအရာကို ရယူထားသည်';
  @override
  String assistantConfidence(int confidence, String explanation) =>
      'ရည်ရွယ်ချက်ယုံကြည်မှု - $confidence%\n$explanation';
  @override
  String assistantClassifierMatched(String terms) =>
      'ကိုက်ညီသော အော့ဖ်လိုင်းစကားလုံးများ - $terms။ machine-learning model မသုံးထားပါ။';
  @override
  String get assistantClassifierLowConfidence =>
      'အနီးစပ်ဆုံး အော့ဖ်လိုင်းကိုက်ညီမှုသည် ယုံကြည်မှုသတ်မှတ်ချက်အောက်တွင် ရှိသည်။ machine-learning model မသုံးထားပါ။';
  @override
  String get assistantClassifierNoMatch =>
      'အတည်ပြုထားသော အော့ဖ်လိုင်းရည်ရွယ်ချက်စကားလုံး မကိုက်ညီပါ။ machine-learning model မသုံးထားပါ။';
  @override
  String get assistantClassifierOnnx =>
      'ဆုံးဖြတ်ချက်သတ်မှတ်ထားသော classifier က မသိရဟု ပြန်ပြီးနောက် ရွေးချယ်နိုင်သော ဒေသတွင်း ONNX classifier က ဘေးကင်းရေးသတ်မှတ်ချက်နှင့်အထက် ဤရည်ရွယ်ချက်ကို သိရှိခဲ့သည်။';
  @override
  String get assistantClassifierGemma =>
      'ရွေးချယ်နိုင်သော ဒေသတွင်း Gemma 3 model က ဖြေထားသည်။ ရရှိနိုင်ပါက သက်ဆိုင်ရာဘေးအန္တရာယ်လမ်းညွှန်ကို အတည်ပြုထားသော အော့ဖ်လိုင်းအကြောင်းအရာဖြင့် အခြေခံထားသည်။';
  @override
  String get assistantEngineDeterministic =>
      'တုံ့ပြန်အင်ဂျင် - ဆုံးဖြတ်ချက်သတ်မှတ်ထားသော အော့ဖ်လိုင်း classifier';
  @override
  String get assistantEngineOnnx =>
      'တုံ့ပြန်အင်ဂျင် - ရွေးချယ်နိုင်သော ဒေသတွင်း ONNX ရည်ရွယ်ချက် classifier';
  @override
  String get assistantEngineGemma =>
      'တုံ့ပြန်အင်ဂျင် - ဒေသတွင်း Gemma 3 အကူ';
  @override
  String get assistantGemmaAnswerTitle => 'Gemma 3 အဖြေ';
  @override
  String get assistantLocalRewordingTitle =>
      'ရွေးချယ်နိုင်သော ဒေသတွင်းပြန်လည်ရေးသားမှု';
  @override
  String get assistantLocalRewordingWarning =>
      'model ဖန်တီးသည့် စာသားသည် မှားနိုင်သည်။ အထက်တွင်ပြထားသော ရင်းမြစ်အခြေပြု လမ်းညွှန်အတိအကျနှင့် ပြန်စစ်ပါ။';
  @override
  String assistantLocalRewordingSemantics(String text) =>
      'ရွေးချယ်နိုင်သော model ဖန်တီးသည့် ဒေသတွင်းပြန်လည်ရေးသားမှု။ $text သတိ - ရင်းမြစ်အခြေပြု လမ်းညွှန်အတိအကျနှင့် ပြန်စစ်ပါ။';
  @override
  String get assistantMapResponse =>
      'SafeMyanmar သည် အကူထဲတွင် လမ်းကြောင်းမတွက်ပါ။ ရရှိနိုင်သော အမိုးအကာများကို ကြည့်ပြီး မသေချာမှုနှင့် အချိန်ပါသော လမ်းကြောင်းအကြံပြုချက်များ တောင်းရန် မြေပုံဖွင့်ပါ။';
  @override
  String get assistantSosResponse =>
      'အကူသည် SOS ကို အလိုအလျောက်ဖွင့်ခြင်း သို့မဟုတ် ပေးပို့ခြင်း မပြုနိုင်ပါ။ လက်ခံသူများ၊ အချက်အလက်နှင့် အတိအလင်းအတည်ပြုထိန်းချုပ်မှုများကို စစ်ရန် SOS ဖွင့်ပါ။';
  @override
  String get assistantMissingResponse =>
      'Tier 1 အော့ဖ်လိုင်းအစုတွင် အတည်ပြုထားသော ပျောက်ဆုံးသူလုပ်ထုံးလုပ်နည်း မရှိပါ။ တရားဝင်ဒေသဆိုင်ရာ ဝန်ဆောင်မှုများကို ဆက်သွယ်ပြီး ကိုယ်ရေးအချက်အလက်ကို ယုံကြည်ရသူများထံသာ မျှဝေပါ။';
  @override
  String get assistantDamageResponse =>
      'Tier 1 အော့ဖ်လိုင်းအစုတွင် အတည်ပြုထားသော ပျက်စီးမှုအစီရင်ခံလုပ်ထုံးလုပ်နည်း မရှိပါ။ အချက်အလက်စုရန် ပျက်စီးနေသောအဆောက်အအုံထဲ မဝင်ပါနှင့်။';
  @override
  String get assistantUnknownResponse =>
      'ဤမေးခွန်းကို အတည်ပြုထားသော အော့ဖ်လိုင်းအကြောင်းအရာနှင့် ယုံကြည်စွာ မကိုက်ညီနိုင်ပါ။ အကြံပြုမေးခွန်းကို စမ်းပါ သို့မဟုတ် လမ်းညွှန်အမျိုးအစားများကို ကြည့်ပါ။';
  @override
  String get assistantUnavailableResponse =>
      'ဤတောင်းဆိုမှုအတွက် အတည်ပြုထားသော အော့ဖ်လိုင်းအကြောင်းအရာ မရနိုင်ပါ။';
  @override
  String get assistantReviewSos =>
      'အသုံးပြုသူစစ်ဆေးရန် SOS ဖွင့်ပါ';
  @override
  String get assistantOpenMap => 'မြေပုံဖွင့်ရန်';
  @override
  String get assistantSosDraftTitle =>
      'သင့်စစ်ဆေးရန် draft အသေးစိတ်ကို ထုတ်ယူထားသည်';
  @override
  String get assistantSosDraftWarning =>
      'Draft သာဖြစ်သည်။ အကွက်တိုင်းကို စစ်ပါ။ မည်သည့်အရာမျှ မပေးပို့ပါ၊ SOS ကို မဖွင့်ပါ။';
  @override
  String assistantDraftIncident(String value) => 'ဖြစ်ရပ် - $value';
  @override
  String assistantDraftStatus(String value) => 'အခြေအနေ - $value';
  @override
  String assistantDraftInjury(String value) => 'ဒဏ်ရာစာသား - $value';
  @override
  String assistantDraftLocation(String value) =>
      'တည်နေရာစကားစု - $value';
  @override
  String assistantDraftBattery(int value) => 'ဘက်ထရီ - $value%';
  @override
  String get moreTitle => 'နောက်ထပ်';
  @override
  String get languageSettingsTitle => 'ဘာသာစကား';
  @override
  String get languageSettingsDescription =>
      'အက်ပ်ပိုင်မျက်နှာပြင်များနှင့် စစ်ဆေးထားသော အော့ဖ်လိုင်းလမ်းညွှန်အတွက် ဘာသာစကားကို ရွေးပါ။';
  @override
  String get languageEnglish => 'English';
  @override
  String get languageBurmese => 'မြန်မာ';
  @override
  String get languageSaving => 'ဘာသာစကားရွေးချယ်မှုကို သိမ်းနေသည်';
  @override
  String get languageReadErrorTitle =>
      'ဘာသာစကားရွေးချယ်မှု ယာယီမရနိုင်ပါ';
  @override
  String get languageReadErrorDescription =>
      'သိမ်းထားသော ဘာသာစကားရွေးချယ်မှုကို SafeMyanmar က မဖတ်နိုင်ပါ။ English ကို အသုံးပြုနေသည်။ ထပ်ကြိုးစားပါ။';
  @override
  String get languageWriteErrorTitle =>
      'ဘာသာစကားရွေးချယ်မှုကို မသိမ်းနိုင်ပါ';
  @override
  String get languageWriteErrorDescription =>
      'ဘာသာစကားရွေးချယ်မှုကို SafeMyanmar က မသိမ်းနိုင်ပါ။ ယခင်ဘာသာစကားကို ဆက်အသုံးပြုနေသည်။ ထပ်ကြိုးစားပါ။';
  @override
  String get originalSourceTextNotice =>
      'ရင်းမြစ်က ပေးထားသော အမည်များနှင့် တိုက်ရိုက်သတိပေးစာသားအချို့ကို မူရင်းဘာသာစကားဖြင့် ပြသထားသည်။';
  @override
  String get profileOverviewTitle => 'သင့်စက်တွင်းပရိုဖိုင်';
  @override
  String get profileNotSet => 'ပြသမည့်အမည် မသတ်မှတ်ရသေးပါ';
  @override
  String get profileLocalOnlyLabel => 'ဤစက်တွင်သာ သိမ်းထားသည်';
  @override
  String get profileOverviewDescription =>
      'ပြသမည့်အမည်နှင့် အနာဂတ် SOS စာတွင် ထည့်သွင်းနိုင်မည့်သူများကို သိမ်းထားပါ။';
  @override
  String get editProfile => 'ပရိုဖိုင်ပြင်ရန်';
  @override
  String get emergencyContacts => 'အရေးပေါ်အဆက်အသွယ်များ';
  @override
  String contactsSummary(int count, int selected) =>
      'အဆက်အသွယ် $count ခု၊ SOS အတွက်ရွေးထားသည် $selected ခု';
  @override
  String get manageContacts => 'အဆက်အသွယ်များ စီမံရန်';
  @override
  String get profilePrivacyTitle => 'ပုံမှန်အားဖြင့် သီးသန့်';
  @override
  String get profilePrivacyDescription =>
      'သင့်ပရိုဖိုင်နှင့် အဆက်အသွယ်များကို လုံခြုံသောစက်တွင်းသိမ်းဆည်းမှုတွင် စာဝှက်ထားသည်။ SafeMyanmar သည် စက်အဆက်အသွယ်များကို မဖတ်ပါ၊ အဆက်အသွယ်သိမ်းခြင်းက SOS မပေးပို့ပါ။';
  @override
  String get editProfileTitle => 'ပရိုဖိုင်ပြင်ရန်';
  @override
  String get displayNameLabel => 'ပြသမည့်အမည်';
  @override
  String get displayNameRequired => 'ပြသမည့်အမည် ထည့်ပါ။';
  @override
  String get saveChanges => 'ပြောင်းလဲမှုများ သိမ်းရန်';
  @override
  String get profileLoading => 'သင့်စက်တွင်းပရိုဖိုင်ကို ဖွင့်နေသည်';
  @override
  String get profileSaving => 'လုံခြုံစွာ သိမ်းနေသည်';
  @override
  String get profileReadErrorTitle => 'ပရိုဖိုင် ယာယီမရနိုင်ပါ';
  @override
  String get profileReadErrorDescription =>
      'လုံခြုံသောစက်တွင်းပရိုဖိုင်ကို SafeMyanmar က မဖတ်နိုင်ပါ။ ပရိုဖိုင်အသေးစိတ် မပေါက်ကြားပါ။ ထပ်ကြိုးစားပါ။';
  @override
  String get profileDataErrorTitle =>
      'သိမ်းထားသောပရိုဖိုင်ကို ဖွင့်မရပါ';
  @override
  String get profileDataErrorDescription =>
      'စာဝှက်ထားသော စက်တွင်းပရိုဖိုင် ပျက်စီးနေသည် သို့မဟုတ် မထောက်ပံ့သောဗားရှင်းဖြစ်သည်။ မပြောင်းလဲထားပါ။ ထပ်ကြိုးစားပါ သို့မဟုတ် အစမှစရန် reset လုပ်ပါ။';
  @override
  String get profileWriteErrorTitle => 'ပြောင်းလဲမှုများ မသိမ်းနိုင်ပါ';
  @override
  String get profileWriteErrorDescription =>
      'နောက်ဆုံးလုံခြုံစွာသိမ်းထားသော ပရိုဖိုင်ကို ဆက်အသုံးပြုနိုင်သည်။ ပြောင်းလဲမှုကို ထပ်သိမ်းပါ။';
  @override
  String get retry => 'ထပ်ကြိုးစားရန်';
  @override
  String get resetLocalProfile => 'စက်တွင်းပရိုဖိုင် reset လုပ်ရန်';
  @override
  String get resetLocalProfileTitle =>
      'ဖတ်မရသောပရိုဖိုင်ကို reset လုပ်မလား။';
  @override
  String get resetLocalProfileDescription =>
      'ဤစက်မှ ဖတ်မရသော ပရိုဖိုင်နှင့် အရေးပေါ်အဆက်အသွယ်များကို အပြီးတိုင်ဖယ်ရှားမည်။ ပြန်ပြင်မရပါ။';
  @override
  String get cancel => 'ပယ်ဖျက်ရန်';
  @override
  String get reset => 'Reset';
  @override
  String get contactsTitle => 'အရေးပေါ်အဆက်အသွယ်များ';
  @override
  String get addContact => 'အဆက်အသွယ်ထည့်ရန်';
  @override
  String get contactsEmptyTitle =>
      'အရေးပေါ်အဆက်အသွယ် မရှိသေးပါ';
  @override
  String get contactsEmptyDescription =>
      'ယုံကြည်ရသူများကို ထည့်ပြီး အနာဂတ် SOS စာတွင် ထည့်သွင်းနိုင်သူကို ရွေးပါ။';
  @override
  String get contactsPrivacyDescription =>
      'အဆက်အသွယ်များကို ဤစက်တွင် စာဝှက်ထားသည်။ SafeMyanmar သည် စက်အဆက်အသွယ်စာရင်းကို အသုံးပြုခွင့် မတောင်းပါ။';
  @override
  String maximumContactsReached(int count) =>
      'အရေးပေါ်အဆက်အသွယ် အများဆုံး $count ခု သိမ်းနိုင်သည်။';
  @override
  String get selectedForSos => 'SOS အတွက် ရွေးထားသည်';
  @override
  String get notSelectedForSos => 'SOS အတွက် မရွေးထားပါ';
  @override
  String get sosSelectionDescription =>
      'ဤလူကို အနာဂတ် SOS စာတွင် ထည့်သွင်းမထည့်သွင်း ရွေးပါ။ မည်သည့်အရာမျှ မပေးပို့ပါ။';
  @override
  String get editContact => 'အဆက်အသွယ်ပြင်ရန်';
  @override
  String get addContactTitle =>
      'အရေးပေါ်အဆက်အသွယ် ထည့်ရန်';
  @override
  String get editContactTitle =>
      'အရေးပေါ်အဆက်အသွယ် ပြင်ရန်';
  @override
  String get contactNameLabel => 'အဆက်အသွယ်အမည်';
  @override
  String get contactNameRequired => 'အဆက်အသွယ်အမည် ထည့်ပါ။';
  @override
  String get phoneNumberLabel => 'ဖုန်းနံပါတ်';
  @override
  String get phoneNumberRequired => 'ဖုန်းနံပါတ် ထည့်ပါ။';
  @override
  String get phoneNumberInvalidCharacters =>
      'ရှေ့တွင် + ထည့်နိုင်သော ဂဏန်းများကို သုံးပါ။ space၊ hyphen၊ period နှင့် ကွင်းများ ခွင့်ပြုသည်။';
  @override
  String get phoneNumberInvalidLength =>
      'ဂဏန်း ၇ မှ ၁၅ လုံးပါသော ဖုန်းနံပါတ် ထည့်ပါ။';
  @override
  String get relationshipLabel => 'ဆက်ဆံရေး သို့မဟုတ် အညွှန်း';
  @override
  String get relationshipRequired =>
      'ဆက်ဆံရေး သို့မဟုတ် အညွှန်း ထည့်ပါ။';
  @override
  String get deleteContact => 'အဆက်အသွယ်ဖျက်ရန်';
  @override
  String deleteContactTitle(String name) => '$name ကို ဖျက်မလား။';
  @override
  String get deleteContactDescription =>
      'လုံခြုံသောစက်တွင်းသိမ်းဆည်းမှုမှ အဆက်အသွယ်ကို ဖယ်ရှားမည်။ စာမပေးပို့ပါ။';
  @override
  String get delete => 'ဖျက်ရန်';
  @override
  String get contactNotFound =>
      'ဤအရေးပေါ်အဆက်အသွယ်ကို မတွေ့ပါ။';
  @override
  String get backToContacts =>
      'အရေးပေါ်အဆက်အသွယ်များသို့ ပြန်ရန်';
  @override
  String get earthquakeInformation => 'ငလျင်အချက်အလက်';
  @override
  String get refresh => 'ပြန်လည်ဖွင့်ရန်';
  @override
  String get liveInformation => 'တိုက်ရိုက်အချက်အလက်';
  @override
  String get cachedInformation => 'သိမ်းထားသောအချက်အလက်';
  @override
  String get staleInformation => 'ခေတ်နောက်ကျသောအချက်အလက်';
  @override
  String lastSuccessfulUpdate(String time) =>
      'နောက်ဆုံးအောင်မြင်သောအပ်ဒိတ် - $time';
  @override
  String dataStatusSemantics(String status, String lastUpdate) =>
      '$status။ $lastUpdate';
  @override
  String get noRecentEarthquakes =>
      'လွှမ်းခြုံထားသောဧရိယာတွင် မကြာသေးမီက ငလျင်မတွေ့ပါ။ ဤအချက်က အန္တရာယ်မရှိကြောင်း အာမမခံပါ။';
  @override
  String get liveEarthquakeDataUnavailable =>
      'တိုက်ရိုက်ငလျင်အချက်အလက် မရနိုင်ပါ။';
  @override
  String get savedInformationRemains =>
      'ယခင်သိမ်းထားသောအချက်အလက်ကို အောက်တွင် ဆက်လက်ကြည့်နိုင်သည်။';
  @override
  String get couldNotUpdateLiveInformation =>
      'တိုက်ရိုက်အချက်အလက်ကို အပ်ဒိတ်မလုပ်နိုင်ပါ။';
  @override
  String magnitudeValue(String magnitude) => 'ပြင်းအား $magnitude';
  @override
  String locationValue(String place) => 'တည်နေရာ - $place';
  @override
  String eventTimeValue(String time) => 'ဖြစ်ရပ်အချိန် - $time';
  @override
  String utcTimestamp(String value) => '$value UTC';
  @override
  String depthValue(String depth) => 'အနက် - $depth ကီလိုမီတာ';
  @override
  String providerUpdateValue(String time) =>
      'ဝန်ဆောင်မှုပေးသူအပ်ဒိတ် - $time';
  @override
  String retrievedValue(String time) => 'ရယူချိန် - $time';
  @override
  String reviewStatusValue(String status) =>
      'စစ်ဆေးမှုအခြေအနေ - $status';
  @override
  String get dataSourceUsGS => 'ရင်းမြစ် - USGS';
  @override
  String get openUsGSsource => 'USGS ရင်းမြစ်ဖွင့်ရန်';
  @override
  String get couldNotOpenUsGSsource =>
      'USGS ရင်းမြစ်ကို ဖွင့်မရပါ။';
  @override
  String get earthquakeInformationNotFound =>
      'ငလျင်အချက်အလက်ကို မတွေ့ပါ။';
  @override
  String get backToEarthquakeInformation =>
      'ငလျင်အချက်အလက်သို့ ပြန်ရန်';
  @override
  String earthquakeCardSemantics(
    String type,
    String magnitude,
    String location,
    String eventTime,
    String status,
    String source,
  ) =>
      '$type။ $magnitude။ $location။ $eventTime။ $status။ $source';
  @override
  String get earthquakeCardHint =>
      'ငလျင်အချက်အလက်အသေးစိတ်ဖွင့်ရန်';
  @override
  String get preliminaryNotice =>
      'ကနဦးငလျင်တန်ဖိုးများ ပြောင်းလဲနိုင်သည်။';
  @override
  String get loadingEarthquakes =>
      'ငလျင်အချက်အလက်ကို အပ်ဒိတ်လုပ်နေသည်';
}
