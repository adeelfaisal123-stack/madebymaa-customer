// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get navCart => 'కార్ట్';

  @override
  String get navOrders => 'ఆర్డర్లు';

  @override
  String get navExplore => 'అన్వేషించండి';

  @override
  String get navNearby => 'సమీపంలో';

  @override
  String get navProfile => 'ప్రొఫైల్';

  @override
  String nearbyMapEmpty(String radius) {
    return '$radius km లోపు వంటగదులు లేవు.';
  }

  @override
  String get nearbyLocationRequired =>
      'సమీప వంటగదుల కోసం మీ స్థానాన్ని ఎంచుకోండి.';

  @override
  String nearbyKitchenCount(int count, String radius) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$radius km లోపు $count వంటగదులు',
      one: '$radius km లోపు 1 వంటగది',
    );
    return '$_temp0';
  }

  @override
  String get nearbyTitle => 'మీ సమీప Mom Chefs';

  @override
  String get nearbySearchHint => 'Mom chef వెతకండి';

  @override
  String get nearbyFilterAll => 'అన్నీ';

  @override
  String get nearbyFilterTopRated => 'టాప్ రేటెడ్';

  @override
  String get nearbyFilterCuisine => 'వంటకం';

  @override
  String get notificationsTitle => 'నోటిఫికేషన్లు';

  @override
  String get notificationsEmpty => 'ఇంకా నోటిఫికేషన్లు లేవు';

  @override
  String get notificationsEmptyHint =>
      'మీకు ఆర్డర్ అప్‌డేట్లు మరియు ప్రకటనలు వచ్చినప్పుడు ఇక్కడ కనిపిస్తాయి.';

  @override
  String get setYourLocation => 'మీ స్థానాన్ని ఎంచుకోండి';

  @override
  String get searchKitchensDishes => 'వంటగదలు, వంటకాలు వెతకండి…';

  @override
  String get cravingSomething => 'ఏదైనా తినాలనుకుంటున్నారా?';

  @override
  String get categoryAll => 'అన్నీ';

  @override
  String get categoryBreakfast => 'అల్పాహారం';

  @override
  String get categoryLunch => 'మధ్యాహ్న భోజనం';

  @override
  String get categorySnacks => 'చిరుతిండి';

  @override
  String get categorySweets => 'మిఠాయిలు';

  @override
  String get tastyDishesTitle => 'రుచికరమైన వంటకాలు';

  @override
  String get tastyDishesSubtitle =>
      'మీ సమీపంలోని గృహ వంటగదల నుండి ఎంపిక చేసినవి';

  @override
  String get featuredKitchensTitle => 'ప్రత్యేకమైన వంటగదలు';

  @override
  String get featuredKitchensSubtitle => 'మీ చుట్టూ ఉన్న కుటుంబాల ఇంటి వంటలు';

  @override
  String get featuredKitchensEmpty =>
      'త్వరలో ఇక్కడ ప్రత్యేక వంటగదలు కనిపిస్తాయి.';

  @override
  String get language => 'భాష';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTelugu => 'తెలుగు';

  @override
  String get chooseLanguage => 'భాష ఎంచుకోండి';

  @override
  String get dishDetailAbout => 'ఈ వంటకం గురించి';

  @override
  String get dishDetailTags => 'ట్యాగ్లు';

  @override
  String get dishDetailIngredients => 'పదార్థాలు';

  @override
  String get allDishesTitle => 'అన్ని వంటకాలు';

  @override
  String get noDishesInCuisine => 'ఈ వంటకాలలో ఇంకా వంటకాలు లేవు.';

  @override
  String get noDishesToday => 'ప్రస్తుతం వంటకాలు అందుబాటులో లేవు.';

  @override
  String get searchNoDishes => 'మీ వెతుకులో వంటకాలు కనిపించలేదు.';

  @override
  String get noDishesInCategory => 'ఈ వర్గంలో వంటకాలు లేవు.';

  @override
  String get noDishesEmptySubtitle =>
      'మరొక వర్గం ప్రయత్నించండి లేదా త్వరలో మళ్లీ చూడండి.';

  @override
  String get dishFilterVeg => 'శాకాహారం';

  @override
  String get dishFilterNonVeg => 'మాంసాహారం';

  @override
  String get kitchenClosed => 'మూసివేయబడింది';

  @override
  String get kitchenOpen => 'తెరిచి ఉంది';

  @override
  String get kitchenClosedProfileTitle => 'వంటగద ప్రస్తుతం మూసివేయబడింది';

  @override
  String get kitchenClosedProfileSubtitle =>
      'చింతించకండి — మీరు ఇప్పటికీ మెనూ చూడవచ్చు మరియు తర్వాత కోసం ముందస్తు ఆర్డర్ చేయవచ్చు.';

  @override
  String get kitchenClosedPreOrderHint => 'ముందస్తు ఆర్డర్ అందుబాటులో ఉంది';

  @override
  String get kitchenClosedPreOrderButton => 'ముందస్తు ఆర్డర్';

  @override
  String get cuisinesTitle => 'వంటకాలు';

  @override
  String get categoriesTitle => 'మీకు ఇష్టమైనది ఎంచుకోండి';

  @override
  String get categoriesSubtitle => 'బిర్యానీ, అన్నం, కూరలు మరియు మరిన్ని';

  @override
  String get recentlyViewedTitle => 'ఇటీవల చూసినవి';

  @override
  String get recentlyViewedSubtitle => 'మీరు ఆపిన చోట నుండి కొనసాగండి';

  @override
  String get searchCategories => 'వర్గాలు వెతకండి…';

  @override
  String get searchNoCategories => 'మీ వెతుకులో వర్గాలు కనిపించలేదు.';

  @override
  String get cuisinesSubtitle => 'మీ సమీపంలో ప్రాంతీయ రుచులు';

  @override
  String get viewAll => 'అన్నీ చూడండి';

  @override
  String get searchCuisines => 'వంటకాలు వెతకండి…';

  @override
  String get searchNoCuisines => 'మీ వెతుకులో వంటకాలు కనిపించలేదు.';

  @override
  String get allKitchensTitle => 'అన్ని వంటగదలు';

  @override
  String get searchNoKitchens => 'మీ వెతుకులో వంటగదలు కనిపించలేదు.';

  @override
  String get searchNoKitchensSubtitle =>
      'వేరే పేరు, వంటకాలు ప్రయత్నించండి లేదా ఫిల్టర్లు క్లియర్ చేసి మరిన్ని వంటగదలు చూడండి.';

  @override
  String get searchClearFilters => 'ఫిల్టర్లు క్లియర్ చేయండి';

  @override
  String get startupPopupClose => 'మూసివేయి';

  @override
  String get profileSignIn => 'సైన్ ఇన్';

  @override
  String get profileSignOut => 'సైన్ అవుట్';

  @override
  String get profileGuestName => 'అతిథి';

  @override
  String get profileGuestSubtitle =>
      'ఆర్డర్లు మరియు ఆఫర్లు సేవ్ చేయడానికి సైన్ ఇన్ చేయండి';
}
