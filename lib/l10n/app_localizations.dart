import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('te'),
  ];

  /// No description provided for @navCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get navCart;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get navNearby;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @nearbyMapEmpty.
  ///
  /// In en, this message translates to:
  /// **'No kitchens within {radius} km of your location.'**
  String nearbyMapEmpty(String radius);

  /// No description provided for @nearbyLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Set your location to see nearby kitchens.'**
  String get nearbyLocationRequired;

  /// No description provided for @nearbyKitchenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 kitchen within {radius} km} other{{count} kitchens within {radius} km}}'**
  String nearbyKitchenCount(int count, String radius);

  /// No description provided for @nearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'All Mom Chefs Near You'**
  String get nearbyTitle;

  /// No description provided for @nearbySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search mom chef'**
  String get nearbySearchHint;

  /// No description provided for @nearbyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get nearbyFilterAll;

  /// No description provided for @nearbyFilterTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get nearbyFilterTopRated;

  /// No description provided for @nearbyFilterCuisine.
  ///
  /// In en, this message translates to:
  /// **'Cuisine'**
  String get nearbyFilterCuisine;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Order updates and announcements will appear here when you receive them.'**
  String get notificationsEmptyHint;

  /// No description provided for @setYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Set your location'**
  String get setYourLocation;

  /// No description provided for @searchKitchensDishes.
  ///
  /// In en, this message translates to:
  /// **'Search kitchens, dishes…'**
  String get searchKitchensDishes;

  /// No description provided for @cravingSomething.
  ///
  /// In en, this message translates to:
  /// **'Craving something?'**
  String get cravingSomething;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get categoryBreakfast;

  /// No description provided for @categoryLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get categoryLunch;

  /// No description provided for @categorySnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get categorySnacks;

  /// No description provided for @categorySweets.
  ///
  /// In en, this message translates to:
  /// **'Sweets'**
  String get categorySweets;

  /// No description provided for @tastyDishesTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasty dishes to try'**
  String get tastyDishesTitle;

  /// No description provided for @tastyDishesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Handpicked favourites from our best home kitchens'**
  String get tastyDishesSubtitle;

  /// No description provided for @featuredKitchensTitle.
  ///
  /// In en, this message translates to:
  /// **'Kitchens worth the crave'**
  String get featuredKitchensTitle;

  /// No description provided for @featuredKitchensSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Homestyle meals from families cooking near you'**
  String get featuredKitchensSubtitle;

  /// No description provided for @featuredKitchensEmpty.
  ///
  /// In en, this message translates to:
  /// **'Featured kitchens will appear here soon.'**
  String get featuredKitchensEmpty;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTelugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get languageTelugu;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @dishDetailAbout.
  ///
  /// In en, this message translates to:
  /// **'About this dish'**
  String get dishDetailAbout;

  /// No description provided for @dishDetailTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get dishDetailTags;

  /// No description provided for @dishDetailIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get dishDetailIngredients;

  /// No description provided for @allDishesTitle.
  ///
  /// In en, this message translates to:
  /// **'All dishes'**
  String get allDishesTitle;

  /// No description provided for @noDishesInCuisine.
  ///
  /// In en, this message translates to:
  /// **'No dishes in this cuisine yet.'**
  String get noDishesInCuisine;

  /// No description provided for @noDishesToday.
  ///
  /// In en, this message translates to:
  /// **'No dishes available right now.'**
  String get noDishesToday;

  /// No description provided for @searchNoDishes.
  ///
  /// In en, this message translates to:
  /// **'No dishes match your search.'**
  String get searchNoDishes;

  /// No description provided for @noDishesInCategory.
  ///
  /// In en, this message translates to:
  /// **'No dishes in this category.'**
  String get noDishesInCategory;

  /// No description provided for @noDishesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another category or check back soon.'**
  String get noDishesEmptySubtitle;

  /// No description provided for @dishFilterVeg.
  ///
  /// In en, this message translates to:
  /// **'Veg'**
  String get dishFilterVeg;

  /// No description provided for @dishFilterNonVeg.
  ///
  /// In en, this message translates to:
  /// **'Non-veg'**
  String get dishFilterNonVeg;

  /// No description provided for @kitchenClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get kitchenClosed;

  /// No description provided for @kitchenOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get kitchenOpen;

  /// No description provided for @kitchenClosedProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Kitchen is closed for now'**
  String get kitchenClosedProfileTitle;

  /// No description provided for @kitchenClosedProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry — you can still browse the menu and pre-order your favourites for later.'**
  String get kitchenClosedProfileSubtitle;

  /// No description provided for @kitchenClosedPreOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Pre-order available'**
  String get kitchenClosedPreOrderHint;

  /// No description provided for @kitchenClosedPreOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Pre-order'**
  String get kitchenClosedPreOrderButton;

  /// No description provided for @cuisinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cuisines'**
  String get cuisinesTitle;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your favorite'**
  String get categoriesTitle;

  /// No description provided for @categoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Biryani, rice, curries & more'**
  String get categoriesSubtitle;

  /// No description provided for @recentlyViewedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed'**
  String get recentlyViewedTitle;

  /// No description provided for @recentlyViewedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get recentlyViewedSubtitle;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories…'**
  String get searchCategories;

  /// No description provided for @searchNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories match your search.'**
  String get searchNoCategories;

  /// No description provided for @cuisinesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore regional flavours near you'**
  String get cuisinesSubtitle;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @searchCuisines.
  ///
  /// In en, this message translates to:
  /// **'Search cuisines…'**
  String get searchCuisines;

  /// No description provided for @searchNoCuisines.
  ///
  /// In en, this message translates to:
  /// **'No cuisines match your search.'**
  String get searchNoCuisines;

  /// No description provided for @allKitchensTitle.
  ///
  /// In en, this message translates to:
  /// **'All kitchens'**
  String get allKitchensTitle;

  /// No description provided for @searchNoKitchens.
  ///
  /// In en, this message translates to:
  /// **'No kitchens match your search.'**
  String get searchNoKitchens;

  /// No description provided for @searchNoKitchensSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another name, cuisine, or clear your filters to discover more home kitchens.'**
  String get searchNoKitchensSubtitle;

  /// No description provided for @searchClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get searchClearFilters;

  /// No description provided for @startupPopupClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get startupPopupClose;

  /// No description provided for @profileSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get profileSignIn;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileGuestName.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get profileGuestName;

  /// No description provided for @profileGuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save orders & offers'**
  String get profileGuestSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
