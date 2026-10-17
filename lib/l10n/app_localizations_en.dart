// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navCart => 'Cart';

  @override
  String get navOrders => 'Orders';

  @override
  String get navExplore => 'Explore';

  @override
  String get navNearby => 'Nearby';

  @override
  String get navProfile => 'Profile';

  @override
  String nearbyMapEmpty(String radius) {
    return 'No kitchens within $radius km of your location.';
  }

  @override
  String get nearbyLocationRequired =>
      'Set your location to see nearby kitchens.';

  @override
  String nearbyKitchenCount(int count, String radius) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kitchens within $radius km',
      one: '1 kitchen within $radius km',
    );
    return '$_temp0';
  }

  @override
  String get nearbyTitle => 'All Mom Chefs Near You';

  @override
  String get nearbySearchHint => 'Search mom chef';

  @override
  String get nearbyFilterAll => 'All';

  @override
  String get nearbyFilterTopRated => 'Top rated';

  @override
  String get nearbyFilterCuisine => 'Cuisine';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationsEmptyHint =>
      'Order updates and announcements will appear here when you receive them.';

  @override
  String get setYourLocation => 'Set your location';

  @override
  String get searchKitchensDishes => 'Search kitchens, dishes…';

  @override
  String get cravingSomething => 'Craving something?';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryBreakfast => 'Breakfast';

  @override
  String get categoryLunch => 'Lunch';

  @override
  String get categorySnacks => 'Snacks';

  @override
  String get categorySweets => 'Sweets';

  @override
  String get tastyDishesTitle => 'Tasty dishes to try';

  @override
  String get tastyDishesSubtitle =>
      'Handpicked favourites from our best home kitchens';

  @override
  String get featuredKitchensTitle => 'Kitchens worth the crave';

  @override
  String get featuredKitchensSubtitle =>
      'Homestyle meals from families cooking near you';

  @override
  String get featuredKitchensEmpty =>
      'Featured kitchens will appear here soon.';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTelugu => 'Telugu';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get dishDetailAbout => 'About this dish';

  @override
  String get dishDetailTags => 'Tags';

  @override
  String get dishDetailIngredients => 'Ingredients';

  @override
  String get allDishesTitle => 'All dishes';

  @override
  String get noDishesInCuisine => 'No dishes in this cuisine yet.';

  @override
  String get noDishesToday => 'No dishes available right now.';

  @override
  String get searchNoDishes => 'No dishes match your search.';

  @override
  String get noDishesInCategory => 'No dishes in this category.';

  @override
  String get noDishesEmptySubtitle =>
      'Try another category or check back soon.';

  @override
  String get dishFilterVeg => 'Veg';

  @override
  String get dishFilterNonVeg => 'Non-veg';

  @override
  String get kitchenClosed => 'Closed';

  @override
  String get kitchenOpen => 'Open';

  @override
  String get kitchenClosedProfileTitle => 'Kitchen is closed for now';

  @override
  String get kitchenClosedProfileSubtitle =>
      'Don\'t worry — you can still browse the menu and pre-order your favourites for later.';

  @override
  String get kitchenClosedPreOrderHint => 'Pre-order available';

  @override
  String get kitchenClosedPreOrderButton => 'Pre-order';

  @override
  String get cuisinesTitle => 'Cuisines';

  @override
  String get categoriesTitle => 'Choose your favorite';

  @override
  String get categoriesSubtitle => 'Biryani, rice, curries & more';

  @override
  String get recentlyViewedTitle => 'Recently viewed';

  @override
  String get recentlyViewedSubtitle => 'Pick up where you left off';

  @override
  String get searchCategories => 'Search categories…';

  @override
  String get searchNoCategories => 'No categories match your search.';

  @override
  String get cuisinesSubtitle => 'Explore regional flavours near you';

  @override
  String get viewAll => 'View all';

  @override
  String get searchCuisines => 'Search cuisines…';

  @override
  String get searchNoCuisines => 'No cuisines match your search.';

  @override
  String get allKitchensTitle => 'All kitchens';

  @override
  String get searchNoKitchens => 'No kitchens match your search.';

  @override
  String get searchNoKitchensSubtitle =>
      'Try another name, cuisine, or clear your filters to discover more home kitchens.';

  @override
  String get searchClearFilters => 'Clear filters';

  @override
  String get startupPopupClose => 'Close';

  @override
  String get profileSignIn => 'Sign in';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileGuestName => 'Guest';

  @override
  String get profileGuestSubtitle => 'Sign in to save orders & offers';
}
