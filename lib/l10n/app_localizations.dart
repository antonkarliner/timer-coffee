import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

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
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fi'),
    Locale('fr'),
    Locale('hr'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('tr'),
    Locale('uk'),
    Locale('zh')
  ];

  /// No description provided for @beansStatsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Beans stats'**
  String get beansStatsSectionTitle;

  /// No description provided for @totalBeansBrewedLabel.
  ///
  /// In en, this message translates to:
  /// **'Total beans brewed'**
  String get totalBeansBrewedLabel;

  /// No description provided for @newBeansTriedLabel.
  ///
  /// In en, this message translates to:
  /// **'New beans tried'**
  String get newBeansTriedLabel;

  /// No description provided for @originsExploredLabel.
  ///
  /// In en, this message translates to:
  /// **'Origins explored'**
  String get originsExploredLabel;

  /// No description provided for @regionsExploredLabel.
  ///
  /// In en, this message translates to:
  /// **'Regions explored'**
  String get regionsExploredLabel;

  /// No description provided for @newRoastersDiscoveredLabel.
  ///
  /// In en, this message translates to:
  /// **'New roasters discovered'**
  String get newRoastersDiscoveredLabel;

  /// No description provided for @favoriteRoastersLabel.
  ///
  /// In en, this message translates to:
  /// **'Favorite roasters'**
  String get favoriteRoastersLabel;

  /// No description provided for @topOriginsLabel.
  ///
  /// In en, this message translates to:
  /// **'Top origins'**
  String get topOriginsLabel;

  /// No description provided for @topRegionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Top regions'**
  String get topRegionsLabel;

  /// No description provided for @lastrecipe.
  ///
  /// In en, this message translates to:
  /// **'Most Recently Used Recipe:'**
  String get lastrecipe;

  /// No description provided for @userRecipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Recipes'**
  String get userRecipesTitle;

  /// No description provided for @userRecipesSectionCreated.
  ///
  /// In en, this message translates to:
  /// **'Created by you'**
  String get userRecipesSectionCreated;

  /// No description provided for @userRecipesSectionImported.
  ///
  /// In en, this message translates to:
  /// **'Imported by you'**
  String get userRecipesSectionImported;

  /// No description provided for @userRecipesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recipes found'**
  String get userRecipesEmpty;

  /// No description provided for @userRecipesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recipe?'**
  String get userRecipesDeleteTitle;

  /// No description provided for @userRecipesDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get userRecipesDeleteMessage;

  /// No description provided for @userRecipesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get userRecipesDeleteConfirm;

  /// No description provided for @userRecipesDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get userRecipesDeleteCancel;

  /// No description provided for @userRecipesSnackbarDeleted.
  ///
  /// In en, this message translates to:
  /// **'Recipe deleted'**
  String get userRecipesSnackbarDeleted;

  /// No description provided for @hubUserRecipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your recipes'**
  String get hubUserRecipesTitle;

  /// No description provided for @hubUserRecipesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage created and imported recipes'**
  String get hubUserRecipesSubtitle;

  /// No description provided for @hubAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your profile'**
  String get hubAccountSubtitle;

  /// No description provided for @hubSignInCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync recipes and preferences'**
  String get hubSignInCreateSubtitle;

  /// No description provided for @hubBrewDiarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your brewing history and add notes'**
  String get hubBrewDiarySubtitle;

  /// No description provided for @hubBrewStatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View personal and global brewing statistics and trends'**
  String get hubBrewStatsSubtitle;

  /// No description provided for @hubSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change app preferences and behavior'**
  String get hubSettingsSubtitle;

  /// No description provided for @hubAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App details, version and contributors'**
  String get hubAboutSubtitle;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @authortext.
  ///
  /// In en, this message translates to:
  /// **'Timer.Coffee App is created by Anton Karliner, a coffee enthusiast, media specialist, and photojournalist. I hope that this app will help you enjoy your coffee. Feel free to contribute on GitHub.'**
  String get authortext;

  /// No description provided for @contributors.
  ///
  /// In en, this message translates to:
  /// **'Contributors'**
  String get contributors;

  /// No description provided for @errorLoadingContributors.
  ///
  /// In en, this message translates to:
  /// **'Error loading Contributors'**
  String get errorLoadingContributors;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @licensetext.
  ///
  /// In en, this message translates to:
  /// **'This application is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.'**
  String get licensetext;

  /// No description provided for @licensebutton.
  ///
  /// In en, this message translates to:
  /// **'Read the GNU General Public License v3'**
  String get licensebutton;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @sourcecode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get sourcecode;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get support;

  /// No description provided for @allrecipes.
  ///
  /// In en, this message translates to:
  /// **'All Recipes'**
  String get allrecipes;

  /// No description provided for @favoriterecipes.
  ///
  /// In en, this message translates to:
  /// **'Favorite Recipes'**
  String get favoriterecipes;

  /// No description provided for @coffeeamount.
  ///
  /// In en, this message translates to:
  /// **'Coffee amount (g)'**
  String get coffeeamount;

  /// No description provided for @wateramount.
  ///
  /// In en, this message translates to:
  /// **'Water amount (ml)'**
  String get wateramount;

  /// No description provided for @watertemp.
  ///
  /// In en, this message translates to:
  /// **'Water Temperature'**
  String get watertemp;

  /// No description provided for @grindsize.
  ///
  /// In en, this message translates to:
  /// **'Grind Size'**
  String get grindsize;

  /// No description provided for @brewtime.
  ///
  /// In en, this message translates to:
  /// **'Brew Time'**
  String get brewtime;

  /// No description provided for @recipesummary.
  ///
  /// In en, this message translates to:
  /// **'Recipe summary'**
  String get recipesummary;

  /// No description provided for @recipesummarynote.
  ///
  /// In en, this message translates to:
  /// **'Note: this is a basic recipe with default water and coffee amounts.'**
  String get recipesummarynote;

  /// No description provided for @preparation.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get preparation;

  /// No description provided for @brewingprocess.
  ///
  /// In en, this message translates to:
  /// **'Brewing Process'**
  String get brewingprocess;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// Pluralization for seconds
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{seconds} =1{second} other{seconds}}'**
  String seconds(num count);

  /// No description provided for @finishmsg.
  ///
  /// In en, this message translates to:
  /// **'Thanks for using Timer.Coffee! Enjoy your'**
  String get finishmsg;

  /// No description provided for @coffeefact.
  ///
  /// In en, this message translates to:
  /// **'Coffee Fact'**
  String get coffeefact;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @appversion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appversion;

  /// No description provided for @tipsmall.
  ///
  /// In en, this message translates to:
  /// **'Buy a small coffee'**
  String get tipsmall;

  /// No description provided for @tipmedium.
  ///
  /// In en, this message translates to:
  /// **'Buy a medium coffee'**
  String get tipmedium;

  /// No description provided for @tiplarge.
  ///
  /// In en, this message translates to:
  /// **'Buy a large coffee'**
  String get tiplarge;

  /// No description provided for @supportdevelopment.
  ///
  /// In en, this message translates to:
  /// **'Support the development'**
  String get supportdevelopment;

  /// No description provided for @supportdevmsg.
  ///
  /// In en, this message translates to:
  /// **'Your donations help to cover the maintenance costs (such as developer licenses, for example). They also allow me to try more coffee brewing devices and add more recipes to the app.'**
  String get supportdevmsg;

  /// No description provided for @supportdevtnx.
  ///
  /// In en, this message translates to:
  /// **'Thanks for considering to donate!'**
  String get supportdevtnx;

  /// No description provided for @donationok.
  ///
  /// In en, this message translates to:
  /// **'Thank You!'**
  String get donationok;

  /// No description provided for @donationtnx.
  ///
  /// In en, this message translates to:
  /// **'I really appreciate your support! Wish you a lot of great brews! ☕️'**
  String get donationtnx;

  /// No description provided for @donationerr.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get donationerr;

  /// No description provided for @donationerrmsg.
  ///
  /// In en, this message translates to:
  /// **'Error processing the purchase, please try again.'**
  String get donationerrmsg;

  /// No description provided for @sharemsg.
  ///
  /// In en, this message translates to:
  /// **'Check out this recipe:'**
  String get sharemsg;

  /// No description provided for @finishbrew.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishbrew;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingstheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingstheme;

  /// No description provided for @settingsthemelight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsthemelight;

  /// No description provided for @settingsthemedark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsthemedark;

  /// No description provided for @settingsthemesystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsthemesystem;

  /// No description provided for @settingslang.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingslang;

  /// No description provided for @sweet.
  ///
  /// In en, this message translates to:
  /// **'Sweet'**
  String get sweet;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @acidic.
  ///
  /// In en, this message translates to:
  /// **'Acidic'**
  String get acidic;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strong;

  /// No description provided for @slidertitle.
  ///
  /// In en, this message translates to:
  /// **'Use sliders to adjust taste'**
  String get slidertitle;

  /// No description provided for @whatsnewtitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsnewtitle;

  /// No description provided for @whatsnewclose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get whatsnewclose;

  /// No description provided for @seasonspecials.
  ///
  /// In en, this message translates to:
  /// **'Season Specials'**
  String get seasonspecials;

  /// No description provided for @snow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get snow;

  /// No description provided for @noFavoriteRecipesMessage.
  ///
  /// In en, this message translates to:
  /// **'Your list of favorite recipes is currently empty. Start exploring and brewing to discover your favorites!'**
  String get noFavoriteRecipesMessage;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'MMM d, yyyy'**
  String get dateFormat;

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'hh:mm a'**
  String get timeFormat;

  /// No description provided for @brewdiary.
  ///
  /// In en, this message translates to:
  /// **'Brew Diary'**
  String get brewdiary;

  /// No description provided for @brewdiarynotfound.
  ///
  /// In en, this message translates to:
  /// **'No entries found'**
  String get brewdiarynotfound;

  /// No description provided for @beans.
  ///
  /// In en, this message translates to:
  /// **'Beans'**
  String get beans;

  /// No description provided for @roaster.
  ///
  /// In en, this message translates to:
  /// **'Roaster'**
  String get roaster;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @statsscreen.
  ///
  /// In en, this message translates to:
  /// **'Coffee Statistics'**
  String get statsscreen;

  /// No description provided for @yourStats.
  ///
  /// In en, this message translates to:
  /// **'Your stats'**
  String get yourStats;

  /// No description provided for @coffeeBrewed.
  ///
  /// In en, this message translates to:
  /// **'Coffee brewed:'**
  String get coffeeBrewed;

  /// No description provided for @litersUnit.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get litersUnit;

  /// No description provided for @mostUsedRecipes.
  ///
  /// In en, this message translates to:
  /// **'Most used recipes:'**
  String get mostUsedRecipes;

  /// No description provided for @globalStats.
  ///
  /// In en, this message translates to:
  /// **'Global stats'**
  String get globalStats;

  /// No description provided for @unknownRecipe.
  ///
  /// In en, this message translates to:
  /// **'Unknown Recipe'**
  String get unknownRecipe;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// Generic error message label combined with the specific error description
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(String error);

  /// No description provided for @someoneJustBrewed.
  ///
  /// In en, this message translates to:
  /// **'Someone just brewed {recipeName}'**
  String someoneJustBrewed(Object recipeName);

  /// No description provided for @timePeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get timePeriodToday;

  /// No description provided for @timePeriodThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get timePeriodThisWeek;

  /// No description provided for @timePeriodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get timePeriodThisMonth;

  /// No description provided for @timePeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get timePeriodCustom;

  /// Prefix text for statistics headings
  ///
  /// In en, this message translates to:
  /// **'Stats for '**
  String get statsFor;

  /// No description provided for @homescreenbrewcoffee.
  ///
  /// In en, this message translates to:
  /// **'Brew Coffee'**
  String get homescreenbrewcoffee;

  /// No description provided for @homescreenhub.
  ///
  /// In en, this message translates to:
  /// **'Hub'**
  String get homescreenhub;

  /// No description provided for @homescreenmore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get homescreenmore;

  /// No description provided for @addBeans.
  ///
  /// In en, this message translates to:
  /// **'Add beans'**
  String get addBeans;

  /// No description provided for @removeBeans.
  ///
  /// In en, this message translates to:
  /// **'Remove beans'**
  String get removeBeans;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @origin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get origin;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @coffeebeans.
  ///
  /// In en, this message translates to:
  /// **'Coffee Beans'**
  String get coffeebeans;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @nocoffeebeans.
  ///
  /// In en, this message translates to:
  /// **'No coffee beans found'**
  String get nocoffeebeans;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry?'**
  String get confirmDeleteTitle;

  /// No description provided for @recipeDuplicateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Recipe?'**
  String get recipeDuplicateConfirmTitle;

  /// No description provided for @recipeDuplicateConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will create a copy of your recipe that you can edit independently. Do you want to continue?'**
  String get recipeDuplicateConfirmMessage;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this entry? This action cannot be undone.'**
  String get confirmDeleteMessage;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addFavorite;

  /// No description provided for @toggleEditMode.
  ///
  /// In en, this message translates to:
  /// **'Toggle edit mode'**
  String get toggleEditMode;

  /// No description provided for @coffeeBeansDetails.
  ///
  /// In en, this message translates to:
  /// **'Coffee Beans Details'**
  String get coffeeBeansDetails;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @coffeeBeansNotFound.
  ///
  /// In en, this message translates to:
  /// **'Coffee beans not found'**
  String get coffeeBeansNotFound;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @geographyTerroir.
  ///
  /// In en, this message translates to:
  /// **'Geography/Terroir'**
  String get geographyTerroir;

  /// No description provided for @variety.
  ///
  /// In en, this message translates to:
  /// **'Variety'**
  String get variety;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @elevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation'**
  String get elevation;

  /// No description provided for @harvestDate.
  ///
  /// In en, this message translates to:
  /// **'Harvest Date'**
  String get harvestDate;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @processingMethod.
  ///
  /// In en, this message translates to:
  /// **'Processing Method'**
  String get processingMethod;

  /// No description provided for @roastDate.
  ///
  /// In en, this message translates to:
  /// **'Roast Date'**
  String get roastDate;

  /// No description provided for @roastLevel.
  ///
  /// In en, this message translates to:
  /// **'Roast Level'**
  String get roastLevel;

  /// No description provided for @cuppingScore.
  ///
  /// In en, this message translates to:
  /// **'Cupping Score'**
  String get cuppingScore;

  /// No description provided for @flavorProfile.
  ///
  /// In en, this message translates to:
  /// **'Flavor Profile'**
  String get flavorProfile;

  /// No description provided for @tastingNotes.
  ///
  /// In en, this message translates to:
  /// **'Tasting Notes'**
  String get tastingNotes;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get additionalNotes;

  /// No description provided for @noCoffeeBeans.
  ///
  /// In en, this message translates to:
  /// **'No coffee beans found'**
  String get noCoffeeBeans;

  /// No description provided for @editCoffeeBeans.
  ///
  /// In en, this message translates to:
  /// **'Edit Coffee Beans'**
  String get editCoffeeBeans;

  /// No description provided for @addCoffeeBeans.
  ///
  /// In en, this message translates to:
  /// **'Add Coffee Beans'**
  String get addCoffeeBeans;

  /// No description provided for @showImagePicker.
  ///
  /// In en, this message translates to:
  /// **'Show Image Picker'**
  String get showImagePicker;

  /// No description provided for @pleaseNote.
  ///
  /// In en, this message translates to:
  /// **'Please note'**
  String get pleaseNote;

  /// No description provided for @firstTimePopupMessage.
  ///
  /// In en, this message translates to:
  /// **'1. We use external services to process images. By continuing, you agree to this.\n2. While we do not store your images, please avoid including any personal details.\n3. Image recognition is currently limited to 10 tokens per month (1 token = 1 image). This limit may change in the future.'**
  String get firstTimePopupMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @selectFromPhotos.
  ///
  /// In en, this message translates to:
  /// **'Select from photos'**
  String get selectFromPhotos;

  /// No description provided for @takeAdditionalPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take additional photo?'**
  String get takeAdditionalPhoto;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @selectedImages.
  ///
  /// In en, this message translates to:
  /// **'Selected Images'**
  String get selectedImages;

  /// No description provided for @selectedImage.
  ///
  /// In en, this message translates to:
  /// **'Selected Image'**
  String get selectedImage;

  /// No description provided for @backToSelection.
  ///
  /// In en, this message translates to:
  /// **'Back to Selection'**
  String get backToSelection;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @unexpectedErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error occurred'**
  String get unexpectedErrorOccurred;

  /// No description provided for @tokenLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Sorry, you reached your token limit for image recognition this month'**
  String get tokenLimitReached;

  /// No description provided for @noCoffeeLabelsDetected.
  ///
  /// In en, this message translates to:
  /// **'No coffee labels detected. Try with another image.'**
  String get noCoffeeLabelsDetected;

  /// No description provided for @collectedInformation.
  ///
  /// In en, this message translates to:
  /// **'Collected Information'**
  String get collectedInformation;

  /// No description provided for @enterRoaster.
  ///
  /// In en, this message translates to:
  /// **'Enter roaster'**
  String get enterRoaster;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @enterOrigin.
  ///
  /// In en, this message translates to:
  /// **'Enter origin'**
  String get enterOrigin;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @enterVariety.
  ///
  /// In en, this message translates to:
  /// **'Enter variety'**
  String get enterVariety;

  /// No description provided for @enterProcessingMethod.
  ///
  /// In en, this message translates to:
  /// **'Enter processing method'**
  String get enterProcessingMethod;

  /// No description provided for @enterRoastLevel.
  ///
  /// In en, this message translates to:
  /// **'Enter roast level'**
  String get enterRoastLevel;

  /// No description provided for @enterRegion.
  ///
  /// In en, this message translates to:
  /// **'Enter region'**
  String get enterRegion;

  /// No description provided for @enterTastingNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter tasting notes'**
  String get enterTastingNotes;

  /// No description provided for @enterElevation.
  ///
  /// In en, this message translates to:
  /// **'Enter elevation'**
  String get enterElevation;

  /// No description provided for @enterCuppingScore.
  ///
  /// In en, this message translates to:
  /// **'Enter cupping score'**
  String get enterCuppingScore;

  /// No description provided for @enterNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter notes'**
  String get enterNotes;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @amountLeft.
  ///
  /// In en, this message translates to:
  /// **'Amount Left'**
  String get amountLeft;

  /// No description provided for @enterAmountLeft.
  ///
  /// In en, this message translates to:
  /// **'Enter amount left'**
  String get enterAmountLeft;

  /// No description provided for @selectHarvestDate.
  ///
  /// In en, this message translates to:
  /// **'Select Harvest Date'**
  String get selectHarvestDate;

  /// No description provided for @selectRoastDate.
  ///
  /// In en, this message translates to:
  /// **'Select Roast Date'**
  String get selectRoastDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @fillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields.'**
  String get fillRequiredFields;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing'**
  String get analyzing;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorMessage;

  /// No description provided for @selectCoffeeBeans.
  ///
  /// In en, this message translates to:
  /// **'Select Coffee Beans'**
  String get selectCoffeeBeans;

  /// No description provided for @addNewBeans.
  ///
  /// In en, this message translates to:
  /// **'Add New Beans'**
  String get addNewBeans;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @notFavorite.
  ///
  /// In en, this message translates to:
  /// **'Not Favorite'**
  String get notFavorite;

  /// No description provided for @myBeans.
  ///
  /// In en, this message translates to:
  /// **'My Beans'**
  String get myBeans;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @signInSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Successfully signed in with Apple'**
  String get signInSuccessful;

  /// No description provided for @signInError.
  ///
  /// In en, this message translates to:
  /// **'Error signing in with Apple'**
  String get signInError;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signOutSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Successfully signed out'**
  String get signOutSuccessful;

  /// No description provided for @signInSuccessfulGoogle.
  ///
  /// In en, this message translates to:
  /// **'Successfully signed in with Google'**
  String get signInSuccessfulGoogle;

  /// No description provided for @signInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get signInWithEmail;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'example@email.com'**
  String get emailHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @sendMagicLink.
  ///
  /// In en, this message translates to:
  /// **'Send Magic Link'**
  String get sendMagicLink;

  /// No description provided for @magicLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Magic link sent! Check your email.'**
  String get magicLinkSent;

  /// No description provided for @sendOTP.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOTP;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to your email'**
  String get otpSent;

  /// No description provided for @otpSendError.
  ///
  /// In en, this message translates to:
  /// **'Error sending OTP'**
  String get otpSendError;

  /// No description provided for @enterOTP.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOTP;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get otpHint;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @signInSuccessfulEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in successful'**
  String get signInSuccessfulEmail;

  /// No description provided for @invalidOTP.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP'**
  String get invalidOTP;

  /// No description provided for @otpVerificationError.
  ///
  /// In en, this message translates to:
  /// **'Error verifying OTP'**
  String get otpVerificationError;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get success;

  /// No description provided for @otpSentMessage.
  ///
  /// In en, this message translates to:
  /// **'An OTP is being sent to your email. Please enter it below when you receive it.'**
  String get otpSentMessage;

  /// No description provided for @otpHint2.
  ///
  /// In en, this message translates to:
  /// **'Enter code here'**
  String get otpHint2;

  /// No description provided for @signInCreate.
  ///
  /// In en, this message translates to:
  /// **'Sign In / Create account'**
  String get signInCreate;

  /// No description provided for @accountManagement.
  ///
  /// In en, this message translates to:
  /// **'Account Management'**
  String get accountManagement;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Please note: if you choose to continue, we will delete your account and related data from our servers. The local copy of the data will remain on the device, if you want to delete it too, you can simply delete the app. In order to re-enable syncronization, you\'ll need to create an account again'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Succesfully deleted account'**
  String get deleteAccountConfirmation;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// No description provided for @accountDeletionError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting your account, please try again'**
  String get accountDeletionError;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get deleteAccountTitle;

  /// No description provided for @selectBeans.
  ///
  /// In en, this message translates to:
  /// **'Select Beans'**
  String get selectBeans;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @selectRoaster.
  ///
  /// In en, this message translates to:
  /// **'Select Roaster'**
  String get selectRoaster;

  /// No description provided for @selectOrigin.
  ///
  /// In en, this message translates to:
  /// **'Select Origin'**
  String get selectOrigin;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get resetFilters;

  /// No description provided for @showFavoritesOnly.
  ///
  /// In en, this message translates to:
  /// **'Show favorites only'**
  String get showFavoritesOnly;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @selectSize.
  ///
  /// In en, this message translates to:
  /// **'Select Size'**
  String get selectSize;

  /// No description provided for @sizeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get sizeStandard;

  /// No description provided for @sizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sizeMedium;

  /// No description provided for @sizeXL.
  ///
  /// In en, this message translates to:
  /// **'XL'**
  String get sizeXL;

  /// Title for the AppBar in YearlyStatsStoryScreen
  ///
  /// In en, this message translates to:
  /// **'My Year with Timer.Coffee'**
  String get yearlyStatsAppBarTitle;

  /// Greeting message for the first story in YearlyStatsStoryScreen
  ///
  /// In en, this message translates to:
  /// **'Hey, thanks for being a part of Timer.Coffee universe this year!'**
  String get yearlyStatsStory1Text;

  /// Introduction to total coffee brewed with ellipsis indicating continuation
  ///
  /// In en, this message translates to:
  /// **'First things first.\nYou brewed some coffee this year{ellipsis}'**
  String yearlyStatsStory2Text(Object ellipsis);

  /// Detailed coffee brewed amount in liters
  ///
  /// In en, this message translates to:
  /// **'To be more precise,\nyou brewed {liters} liters of coffee in 2024!'**
  String yearlyStatsStory3Text(Object liters);

  /// Statement about the number of distinct roasters used
  ///
  /// In en, this message translates to:
  /// **'You used beans from {roasterCount} roasters'**
  String yearlyStatsStory4Text(Object roasterCount);

  /// List of top 3 roasters used
  ///
  /// In en, this message translates to:
  /// **'Your top 3 roasters were:\n{top3}'**
  String yearlyStatsStory4Top3Roasters(Object top3);

  /// Statement about traveling with coffee, ending with ellipsis
  ///
  /// In en, this message translates to:
  /// **'Coffee took you on a trip\naround the world{ellipsis}'**
  String yearlyStatsStory5Text(Object ellipsis);

  /// Statement about the number of distinct origins
  ///
  /// In en, this message translates to:
  /// **'You tasted coffee beans\nfrom {originCount} countries!'**
  String yearlyStatsStory6Text(Object originCount);

  /// First part of story 7
  ///
  /// In en, this message translates to:
  /// **'You weren’t brewing alone…'**
  String get yearlyStatsStory7Part1;

  /// Second part of story 7
  ///
  /// In en, this message translates to:
  /// **'...but with users from 110 other\ncountries across 6 continents!'**
  String get yearlyStatsStory7Part2;

  /// Title for low number of brewing methods
  ///
  /// In en, this message translates to:
  /// **'You stayed true to yourself and used only these {count} brewing methods this year:'**
  String yearlyStatsStory8TitleLow(Object count);

  /// Title for medium number of brewing methods
  ///
  /// In en, this message translates to:
  /// **'You were discovering new tastes and used {count} brewing methods this year:'**
  String yearlyStatsStory8TitleMedium(Object count);

  /// Title for high number of brewing methods
  ///
  /// In en, this message translates to:
  /// **'You were a true coffee discoverer and used {count} brewing methods this year:'**
  String yearlyStatsStory8TitleHigh(Object count);

  /// Encouraging message for further discovery
  ///
  /// In en, this message translates to:
  /// **'So much else to discover!'**
  String get yearlyStatsStory9Text;

  /// Statement about top-3 recipes with ellipsis
  ///
  /// In en, this message translates to:
  /// **'Your top-3 recipes in 2024 were{ellipsis}'**
  String yearlyStatsStory10Text(Object ellipsis);

  /// Final farewell message
  ///
  /// In en, this message translates to:
  /// **'See you in 2025!'**
  String get yearlyStatsFinalText;

  /// Button text for showing love with likes count
  ///
  /// In en, this message translates to:
  /// **'Show some love ({likesCount})'**
  String yearlyStatsActionLove(Object likesCount);

  /// Button text for donation
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get yearlyStatsActionDonate;

  /// Button text for sharing progress
  ///
  /// In en, this message translates to:
  /// **'Share your progress'**
  String get yearlyStatsActionShare;

  /// Text displayed when a value is unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get yearlyStatsUnknown;

  /// Error message when sharing fails
  ///
  /// In en, this message translates to:
  /// **'Failed to share: {error}'**
  String yearlyStatsErrorSharing(Object error);

  /// Title in the Share Progress Widget
  ///
  /// In en, this message translates to:
  /// **'My year with Timer.Coffee'**
  String get yearlyStatsShareProgressMyYear;

  /// Header for top-3 recipes in the Share Progress Widget
  ///
  /// In en, this message translates to:
  /// **'My top-3 recipes:'**
  String get yearlyStatsShareProgressTop3Recipes;

  /// Header for top-3 roasters in the Share Progress Widget
  ///
  /// In en, this message translates to:
  /// **'My top-3 roasters:'**
  String get yearlyStatsShareProgressTop3Roasters;

  /// No description provided for @yearlyStats25AppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Year with Timer.Coffee – 2025'**
  String get yearlyStats25AppBarTitle;

  /// No description provided for @yearlyStats25AppBarTitleSimple.
  ///
  /// In en, this message translates to:
  /// **'Timer.Coffee in 2025'**
  String get yearlyStats25AppBarTitleSimple;

  /// No description provided for @yearlyStats25Slide1Title.
  ///
  /// In en, this message translates to:
  /// **'Your year with Timer.Coffee'**
  String get yearlyStats25Slide1Title;

  /// No description provided for @yearlyStats25Slide1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to see how you brewed in 2025'**
  String get yearlyStats25Slide1Subtitle;

  /// No description provided for @yearlyStats25Slide2Intro.
  ///
  /// In en, this message translates to:
  /// **'Together we brewed coffee...'**
  String get yearlyStats25Slide2Intro;

  /// No description provided for @yearlyStats25Slide2Count.
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String yearlyStats25Slide2Count(String count);

  /// No description provided for @yearlyStats25Slide2Liters.
  ///
  /// In en, this message translates to:
  /// **'That’s about {liters} liters of coffee'**
  String yearlyStats25Slide2Liters(String liters);

  /// No description provided for @yearlyStats25Slide2Cambridge.
  ///
  /// In en, this message translates to:
  /// **'Enough to give a cup of coffee to everyone in Cambridge, UK (the students would be especially grateful).'**
  String get yearlyStats25Slide2Cambridge;

  /// No description provided for @yearlyStats25Slide3Title.
  ///
  /// In en, this message translates to:
  /// **'And what about you?'**
  String get yearlyStats25Slide3Title;

  /// No description provided for @yearlyStats25Slide3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'You brewed {brews} times with Timer.Coffee this year. That\'s total of {liters} liters!'**
  String yearlyStats25Slide3Subtitle(String brews, String liters);

  /// No description provided for @yearlyStats25Slide3TopBadge.
  ///
  /// In en, this message translates to:
  /// **'You\'re in top {topPct}% of brewers!'**
  String yearlyStats25Slide3TopBadge(int topPct);

  /// No description provided for @yearlyStats25Slide4TitleSingle.
  ///
  /// In en, this message translates to:
  /// **'Remember the day you brewed the most coffee this year?'**
  String get yearlyStats25Slide4TitleSingle;

  /// No description provided for @yearlyStats25Slide4TitleMulti.
  ///
  /// In en, this message translates to:
  /// **'Remember days when you brewed the most coffee this year?'**
  String get yearlyStats25Slide4TitleMulti;

  /// No description provided for @yearlyStats25Slide4TitleBrewTime.
  ///
  /// In en, this message translates to:
  /// **'Your brewing time this year'**
  String get yearlyStats25Slide4TitleBrewTime;

  /// No description provided for @yearlyStats25Slide4ScratchLabel.
  ///
  /// In en, this message translates to:
  /// **'Scratch to reveal'**
  String get yearlyStats25Slide4ScratchLabel;

  /// No description provided for @yearlyStats25BrewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 brew} other{{count} brews}}'**
  String yearlyStats25BrewsCount(int count);

  /// No description provided for @yearlyStats25Slide4PeakSingle.
  ///
  /// In en, this message translates to:
  /// **'{date} — {brewsLabel}'**
  String yearlyStats25Slide4PeakSingle(String date, String brewsLabel);

  /// No description provided for @yearlyStats25Slide4PeakLiters.
  ///
  /// In en, this message translates to:
  /// **'About {liters} liters that day'**
  String yearlyStats25Slide4PeakLiters(String liters);

  /// No description provided for @yearlyStats25Slide4PeakMostRecent.
  ///
  /// In en, this message translates to:
  /// **'Most recent: {mostRecent} — {brewsLabel}'**
  String yearlyStats25Slide4PeakMostRecent(
      String mostRecent, String brewsLabel);

  /// No description provided for @yearlyStats25Slide4BrewTimeLine.
  ///
  /// In en, this message translates to:
  /// **'You spent {timeLabel} brewing'**
  String yearlyStats25Slide4BrewTimeLine(String timeLabel);

  /// No description provided for @yearlyStats25Slide4BrewTimeFooter.
  ///
  /// In en, this message translates to:
  /// **'That is time well spent'**
  String get yearlyStats25Slide4BrewTimeFooter;

  /// No description provided for @yearlyStats25Slide5Title.
  ///
  /// In en, this message translates to:
  /// **'This is how you brew'**
  String get yearlyStats25Slide5Title;

  /// No description provided for @yearlyStats25Slide5MethodsHeader.
  ///
  /// In en, this message translates to:
  /// **'Favorite methods:'**
  String get yearlyStats25Slide5MethodsHeader;

  /// No description provided for @yearlyStats25Slide5NoMethods.
  ///
  /// In en, this message translates to:
  /// **'No methods yet'**
  String get yearlyStats25Slide5NoMethods;

  /// No description provided for @yearlyStats25Slide5RecipesHeader.
  ///
  /// In en, this message translates to:
  /// **'Top recipes:'**
  String get yearlyStats25Slide5RecipesHeader;

  /// No description provided for @yearlyStats25Slide5NoRecipes.
  ///
  /// In en, this message translates to:
  /// **'No recipes yet'**
  String get yearlyStats25Slide5NoRecipes;

  /// No description provided for @yearlyStats25MethodRow.
  ///
  /// In en, this message translates to:
  /// **'{name} — {count} {count, plural, =1{brew} other{brews}}'**
  String yearlyStats25MethodRow(String name, int count);

  /// No description provided for @yearlyStats25Slide6Title.
  ///
  /// In en, this message translates to:
  /// **'You discovered {count} roasters this year:'**
  String yearlyStats25Slide6Title(String count);

  /// No description provided for @yearlyStats25Slide6NoRoasters.
  ///
  /// In en, this message translates to:
  /// **'No roasters yet'**
  String get yearlyStats25Slide6NoRoasters;

  /// No description provided for @yearlyStats25Slide7Title.
  ///
  /// In en, this message translates to:
  /// **'Drinking coffee can take you places…'**
  String get yearlyStats25Slide7Title;

  /// No description provided for @yearlyStats25Slide7Subtitle.
  ///
  /// In en, this message translates to:
  /// **'You discovered {count} origins this year:'**
  String yearlyStats25Slide7Subtitle(String count);

  /// No description provided for @yearlyStats25Others.
  ///
  /// In en, this message translates to:
  /// **'...and others'**
  String get yearlyStats25Others;

  /// No description provided for @yearlyStats25FallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Timer.Coffee users used beans from {countries} countries this year\nand registered {roasters} different roasters.'**
  String yearlyStats25FallbackTitle(int countries, int roasters);

  /// No description provided for @yearlyStats25FallbackPromptHasBeans.
  ///
  /// In en, this message translates to:
  /// **'Why not continue logging your bean bags?'**
  String get yearlyStats25FallbackPromptHasBeans;

  /// No description provided for @yearlyStats25FallbackPromptNoBeans.
  ///
  /// In en, this message translates to:
  /// **'Maybe it is time for you to join and record your beans too?'**
  String get yearlyStats25FallbackPromptNoBeans;

  /// No description provided for @yearlyStats25FallbackActionHasBeans.
  ///
  /// In en, this message translates to:
  /// **'Continue adding beans'**
  String get yearlyStats25FallbackActionHasBeans;

  /// No description provided for @yearlyStats25FallbackActionNoBeans.
  ///
  /// In en, this message translates to:
  /// **'Add your first bean bag'**
  String get yearlyStats25FallbackActionNoBeans;

  /// No description provided for @yearlyStats25ContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get yearlyStats25ContinueButton;

  /// No description provided for @yearlyStats25PostcardTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a New Year wish to a fellow brewer.'**
  String get yearlyStats25PostcardTitle;

  /// No description provided for @yearlyStats25PostcardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional. Keep it kind. No personal info.'**
  String get yearlyStats25PostcardSubtitle;

  /// No description provided for @yearlyStats25PostcardHint.
  ///
  /// In en, this message translates to:
  /// **'Happy New Year and great brews!'**
  String get yearlyStats25PostcardHint;

  /// No description provided for @yearlyStats25PostcardSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get yearlyStats25PostcardSending;

  /// No description provided for @yearlyStats25PostcardSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get yearlyStats25PostcardSend;

  /// No description provided for @yearlyStats25PostcardSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get yearlyStats25PostcardSkip;

  /// No description provided for @yearlyStats25PostcardReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'A wish from another brewer'**
  String get yearlyStats25PostcardReceivedTitle;

  /// No description provided for @yearlyStats25PostcardErrorLength.
  ///
  /// In en, this message translates to:
  /// **'Please enter 2–160 characters.'**
  String get yearlyStats25PostcardErrorLength;

  /// No description provided for @yearlyStats25PostcardErrorSend.
  ///
  /// In en, this message translates to:
  /// **'Could not send. Please try again.'**
  String get yearlyStats25PostcardErrorSend;

  /// No description provided for @yearlyStats25PostcardErrorRejected.
  ///
  /// In en, this message translates to:
  /// **'Could not send. Please try another message.'**
  String get yearlyStats25PostcardErrorRejected;

  /// No description provided for @yearlyStats25CtaTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s brew something great in 2026!'**
  String get yearlyStats25CtaTitle;

  /// No description provided for @yearlyStats25CtaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here are a few ideas:'**
  String get yearlyStats25CtaSubtitle;

  /// No description provided for @yearlyStats25CtaExplorePrefix.
  ///
  /// In en, this message translates to:
  /// **'Explore offers in '**
  String get yearlyStats25CtaExplorePrefix;

  /// No description provided for @yearlyStats25CtaGiftBox.
  ///
  /// In en, this message translates to:
  /// **'Holiday Gift Box'**
  String get yearlyStats25CtaGiftBox;

  /// No description provided for @yearlyStats25CtaDonate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get yearlyStats25CtaDonate;

  /// No description provided for @yearlyStats25CtaDonateSuffix.
  ///
  /// In en, this message translates to:
  /// **' to help Timer.Coffee grow in the coming year'**
  String get yearlyStats25CtaDonateSuffix;

  /// No description provided for @yearlyStats25CtaFollowPrefix.
  ///
  /// In en, this message translates to:
  /// **'Follow us on '**
  String get yearlyStats25CtaFollowPrefix;

  /// No description provided for @yearlyStats25CtaInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get yearlyStats25CtaInstagram;

  /// No description provided for @yearlyStats25CtaShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share my progress'**
  String get yearlyStats25CtaShareButton;

  /// No description provided for @yearlyStats25CtaShareHint.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to tag @timercoffeeapp'**
  String get yearlyStats25CtaShareHint;

  /// No description provided for @yearlyStats25AppBarTooltipResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get yearlyStats25AppBarTooltipResume;

  /// No description provided for @yearlyStats25AppBarTooltipPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get yearlyStats25AppBarTooltipPause;

  /// No description provided for @yearlyStats25ShareError.
  ///
  /// In en, this message translates to:
  /// **'Could not share recap. Please try again.'**
  String get yearlyStats25ShareError;

  /// No description provided for @yearlyStats25BrewTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 minutes} =1{1 minute} other{{count} minutes}}'**
  String yearlyStats25BrewTimeMinutes(int count);

  /// No description provided for @yearlyStats25BrewTimeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String yearlyStats25BrewTimeHours(String hours);

  /// No description provided for @yearlyStats25ShareTitle.
  ///
  /// In en, this message translates to:
  /// **'My Year-2025 with Timer.Coffee'**
  String get yearlyStats25ShareTitle;

  /// No description provided for @yearlyStats25ShareBrewedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Brewed '**
  String get yearlyStats25ShareBrewedPrefix;

  /// No description provided for @yearlyStats25ShareBrewedMiddle.
  ///
  /// In en, this message translates to:
  /// **' times and '**
  String get yearlyStats25ShareBrewedMiddle;

  /// No description provided for @yearlyStats25ShareBrewedSuffix.
  ///
  /// In en, this message translates to:
  /// **' liters of coffee'**
  String get yearlyStats25ShareBrewedSuffix;

  /// No description provided for @yearlyStats25ShareRoastersPrefix.
  ///
  /// In en, this message translates to:
  /// **'Used beans from '**
  String get yearlyStats25ShareRoastersPrefix;

  /// No description provided for @yearlyStats25ShareRoastersSuffix.
  ///
  /// In en, this message translates to:
  /// **' roasters'**
  String get yearlyStats25ShareRoastersSuffix;

  /// No description provided for @yearlyStats25ShareOriginsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Discovered '**
  String get yearlyStats25ShareOriginsPrefix;

  /// No description provided for @yearlyStats25ShareOriginsSuffix.
  ///
  /// In en, this message translates to:
  /// **' coffee origins'**
  String get yearlyStats25ShareOriginsSuffix;

  /// No description provided for @yearlyStats25ShareMethodsTitle.
  ///
  /// In en, this message translates to:
  /// **'My favorite brewing methods:'**
  String get yearlyStats25ShareMethodsTitle;

  /// No description provided for @yearlyStats25ShareRecipesTitle.
  ///
  /// In en, this message translates to:
  /// **'My top recipes:'**
  String get yearlyStats25ShareRecipesTitle;

  /// No description provided for @yearlyStats25ShareHandle.
  ///
  /// In en, this message translates to:
  /// **'@timercoffeeapp'**
  String get yearlyStats25ShareHandle;

  /// Error message when liking fails
  ///
  /// In en, this message translates to:
  /// **'Failed to like. Please try again.'**
  String get yearlyStatsFailedToLike;

  /// Label for coffee brewed
  ///
  /// In en, this message translates to:
  /// **'Coffee brewed'**
  String get labelCoffeeBrewed;

  /// Label for roaster stats
  ///
  /// In en, this message translates to:
  /// **'Tasted beans by'**
  String get labelTastedBeansBy;

  /// Label for origin stats
  ///
  /// In en, this message translates to:
  /// **'Discovered coffee from'**
  String get labelDiscoveredCoffeeFrom;

  /// Label for brewing methods stats
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get labelUsedBrewingMethods;

  /// No description provided for @formattedRoasterCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{roaster} other{roasters}}'**
  String formattedRoasterCount(int count);

  /// No description provided for @formattedCountryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{country} other{countries}}'**
  String formattedCountryCount(int count);

  /// No description provided for @formattedBrewingMethodCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{brewing method} other{brewing methods}}'**
  String formattedBrewingMethodCount(int count);

  /// No description provided for @recipeCreationScreenEditRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Recipe'**
  String get recipeCreationScreenEditRecipeTitle;

  /// No description provided for @recipeCreationScreenCreateRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Recipe'**
  String get recipeCreationScreenCreateRecipeTitle;

  /// No description provided for @recipeCreationScreenRecipeStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipe Steps'**
  String get recipeCreationScreenRecipeStepsTitle;

  /// No description provided for @recipeCreationScreenRecipeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipe Name'**
  String get recipeCreationScreenRecipeNameLabel;

  /// No description provided for @recipeCreationScreenShortDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Short Description'**
  String get recipeCreationScreenShortDescriptionLabel;

  /// No description provided for @recipeCreationScreenBrewingMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Brewing Method'**
  String get recipeCreationScreenBrewingMethodLabel;

  /// No description provided for @recipeCreationScreenCoffeeAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Coffee Amount (g)'**
  String get recipeCreationScreenCoffeeAmountLabel;

  /// No description provided for @recipeCreationScreenWaterAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Water Amount (ml)'**
  String get recipeCreationScreenWaterAmountLabel;

  /// No description provided for @recipeCreationScreenWaterTempLabel.
  ///
  /// In en, this message translates to:
  /// **'Water Temperature (°C)'**
  String get recipeCreationScreenWaterTempLabel;

  /// No description provided for @recipeCreationScreenGrindSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Grind Size'**
  String get recipeCreationScreenGrindSizeLabel;

  /// No description provided for @recipeCreationScreenTotalBrewTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Brew Time:'**
  String get recipeCreationScreenTotalBrewTimeLabel;

  /// No description provided for @recipeCreationScreenMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get recipeCreationScreenMinutesLabel;

  /// No description provided for @recipeCreationScreenSecondsLabel.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get recipeCreationScreenSecondsLabel;

  /// No description provided for @recipeCreationScreenPreparationStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparation Step'**
  String get recipeCreationScreenPreparationStepTitle;

  /// Title for a brew step in the recipe creation screen
  ///
  /// In en, this message translates to:
  /// **'Brew Step {stepOrder}'**
  String recipeCreationScreenBrewStepTitle(String stepOrder);

  /// No description provided for @recipeCreationScreenStepDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Step Description'**
  String get recipeCreationScreenStepDescriptionLabel;

  /// No description provided for @recipeCreationScreenStepTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Step Time: '**
  String get recipeCreationScreenStepTimeLabel;

  /// No description provided for @recipeCreationScreenRecipeNameValidator.
  ///
  /// In en, this message translates to:
  /// **'Please enter a recipe name'**
  String get recipeCreationScreenRecipeNameValidator;

  /// No description provided for @recipeCreationScreenShortDescriptionValidator.
  ///
  /// In en, this message translates to:
  /// **'Please enter a short description'**
  String get recipeCreationScreenShortDescriptionValidator;

  /// No description provided for @recipeCreationScreenBrewingMethodValidator.
  ///
  /// In en, this message translates to:
  /// **'Please select a brewing method'**
  String get recipeCreationScreenBrewingMethodValidator;

  /// No description provided for @recipeCreationScreenRequiredValidator.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get recipeCreationScreenRequiredValidator;

  /// No description provided for @recipeCreationScreenInvalidNumberValidator.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get recipeCreationScreenInvalidNumberValidator;

  /// No description provided for @recipeCreationScreenStepDescriptionValidator.
  ///
  /// In en, this message translates to:
  /// **'Please enter a step description'**
  String get recipeCreationScreenStepDescriptionValidator;

  /// No description provided for @recipeCreationScreenContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue to Recipe Steps'**
  String get recipeCreationScreenContinueButton;

  /// No description provided for @recipeCreationScreenAddStepButton.
  ///
  /// In en, this message translates to:
  /// **'Add Step'**
  String get recipeCreationScreenAddStepButton;

  /// No description provided for @recipeCreationScreenSaveRecipeButton.
  ///
  /// In en, this message translates to:
  /// **'Save Recipe'**
  String get recipeCreationScreenSaveRecipeButton;

  /// No description provided for @recipeCreationScreenUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recipe updated successfully'**
  String get recipeCreationScreenUpdateSuccess;

  /// No description provided for @recipeCreationScreenSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recipe saved successfully'**
  String get recipeCreationScreenSaveSuccess;

  /// Error message when saving a recipe fails
  ///
  /// In en, this message translates to:
  /// **'Error saving recipe: {error}'**
  String recipeCreationScreenSaveError(String error);

  /// No description provided for @unitGramsShort.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitGramsShort;

  /// No description provided for @unitMillilitersShort.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get unitMillilitersShort;

  /// No description provided for @unitGramsLong.
  ///
  /// In en, this message translates to:
  /// **'grams'**
  String get unitGramsLong;

  /// No description provided for @unitMillilitersLong.
  ///
  /// In en, this message translates to:
  /// **'milliliters'**
  String get unitMillilitersLong;

  /// Snackbar message shown when a recipe is copied successfully
  ///
  /// In en, this message translates to:
  /// **'Recipe copied successfully!'**
  String get recipeCopySuccess;

  /// No description provided for @recipeDuplicateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recipe duplicated successfully!'**
  String get recipeDuplicateSuccess;

  /// Snackbar message shown when copying a recipe fails
  ///
  /// In en, this message translates to:
  /// **'Error copying recipe: {error}'**
  String recipeCopyError(String error);

  /// No description provided for @createRecipe.
  ///
  /// In en, this message translates to:
  /// **'Create Recipe'**
  String get createRecipe;

  /// No description provided for @errorSyncingData.
  ///
  /// In en, this message translates to:
  /// **'Error syncing data: {error}'**
  String errorSyncingData(Object error);

  /// No description provided for @errorSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Error signing out: {error}'**
  String errorSigningOut(Object error);

  /// No description provided for @defaultPreparationStepDescription.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get defaultPreparationStepDescription;

  /// No description provided for @loadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingEllipsis;

  /// No description provided for @recipeDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recipe deleted successfully'**
  String get recipeDeletedSuccess;

  /// No description provided for @recipeDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete recipe: {error}'**
  String recipeDeleteError(Object error);

  /// No description provided for @noRecipesFound.
  ///
  /// In en, this message translates to:
  /// **'No recipes found'**
  String get noRecipesFound;

  /// No description provided for @recipeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load recipe: {error}'**
  String recipeLoadError(Object error);

  /// No description provided for @unknownBrewingMethod.
  ///
  /// In en, this message translates to:
  /// **'Unknown Brewing Method'**
  String get unknownBrewingMethod;

  /// No description provided for @recipeCopyErrorLoadingEdit.
  ///
  /// In en, this message translates to:
  /// **'Failed to load copied recipe for editing.'**
  String get recipeCopyErrorLoadingEdit;

  /// No description provided for @recipeCopyErrorOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed.'**
  String get recipeCopyErrorOperationFailed;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @recipeUpdateFailedFetch.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch updated recipe data.'**
  String get recipeUpdateFailedFetch;

  /// No description provided for @recipeImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recipe imported successfully!'**
  String get recipeImportSuccess;

  /// No description provided for @recipeImportFailedSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save imported recipe.'**
  String get recipeImportFailedSave;

  /// No description provided for @recipeImportFailedFetch.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch recipe data for import.'**
  String get recipeImportFailedFetch;

  /// No description provided for @recipeNotImported.
  ///
  /// In en, this message translates to:
  /// **'Recipe not imported.'**
  String get recipeNotImported;

  /// No description provided for @recipeNotFoundCloud.
  ///
  /// In en, this message translates to:
  /// **'Recipe not found in the cloud or is not public.'**
  String get recipeNotFoundCloud;

  /// No description provided for @recipeLoadErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error loading recipe.'**
  String get recipeLoadErrorGeneric;

  /// No description provided for @recipeUpdateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get recipeUpdateAvailableTitle;

  /// Body text for the update confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'A newer version of \'{recipeName}\' is available online. Update?'**
  String recipeUpdateAvailableBody(String recipeName);

  /// No description provided for @dialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// No description provided for @dialogDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get dialogDuplicate;

  /// No description provided for @dialogUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get dialogUpdate;

  /// No description provided for @recipeImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Recipe'**
  String get recipeImportTitle;

  /// Body text for the import confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Do you want to import the recipe \'{recipeName}\' from the cloud?'**
  String recipeImportBody(String recipeName);

  /// No description provided for @dialogImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get dialogImport;

  /// No description provided for @moderationReviewNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderation Review Needed'**
  String get moderationReviewNeededTitle;

  /// Message shown when recipes need moderation review
  ///
  /// In en, this message translates to:
  /// **'The following recipe(s) require review due to content moderation issues: {recipeNames}'**
  String moderationReviewNeededMessage(String recipeNames);

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @reviewRecipeButton.
  ///
  /// In en, this message translates to:
  /// **'Review Recipe'**
  String get reviewRecipeButton;

  /// No description provided for @signInRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In Required'**
  String get signInRequiredTitle;

  /// No description provided for @signInRequiredBodyShare.
  ///
  /// In en, this message translates to:
  /// **'You need to sign in to share your own recipes.'**
  String get signInRequiredBodyShare;

  /// No description provided for @syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sync successful!'**
  String get syncSuccess;

  /// No description provided for @tooltipEditRecipe.
  ///
  /// In en, this message translates to:
  /// **'Edit Recipe'**
  String get tooltipEditRecipe;

  /// No description provided for @tooltipCopyRecipe.
  ///
  /// In en, this message translates to:
  /// **'Copy Recipe'**
  String get tooltipCopyRecipe;

  /// No description provided for @tooltipDuplicateRecipe.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Recipe'**
  String get tooltipDuplicateRecipe;

  /// No description provided for @tooltipShareRecipe.
  ///
  /// In en, this message translates to:
  /// **'Share Recipe'**
  String get tooltipShareRecipe;

  /// No description provided for @signInRequiredSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Sign In Required'**
  String get signInRequiredSnackbar;

  /// No description provided for @moderationErrorFunction.
  ///
  /// In en, this message translates to:
  /// **'Content moderation check failed.'**
  String get moderationErrorFunction;

  /// No description provided for @moderationReasonDefault.
  ///
  /// In en, this message translates to:
  /// **'Content flagged for review.'**
  String get moderationReasonDefault;

  /// No description provided for @moderationFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderation Failed'**
  String get moderationFailedTitle;

  /// Body text for the dialog shown when content moderation fails
  ///
  /// In en, this message translates to:
  /// **'This recipe cannot be shared because: {reason}'**
  String moderationFailedBody(String reason);

  /// Generic error message shown if the sharing process fails
  ///
  /// In en, this message translates to:
  /// **'Error sharing recipe: {error}'**
  String shareErrorGeneric(String error);

  /// Web page title format for a recipe detail page
  ///
  /// In en, this message translates to:
  /// **'{recipeName} on Timer.Coffee'**
  String recipeDetailWebTitle(String recipeName);

  /// No description provided for @saveLocallyCheckLater.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check content status. Saved locally, will check on next sync.'**
  String get saveLocallyCheckLater;

  /// No description provided for @saveLocallyModerationFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes Saved Locally'**
  String get saveLocallyModerationFailedTitle;

  /// Body text for the dialog shown when moderation fails but local save succeeds
  ///
  /// In en, this message translates to:
  /// **'Your local changes have been saved, but the public version couldn\'t be updated due to content moderation: {reason}'**
  String saveLocallyModerationFailedBody(String reason);

  /// No description provided for @editImportedRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Imported Recipe'**
  String get editImportedRecipeTitle;

  /// No description provided for @editImportedRecipeBody.
  ///
  /// In en, this message translates to:
  /// **'This is an imported recipe. Editing it will create a new, independent copy. Do you want to continue?'**
  String get editImportedRecipeBody;

  /// No description provided for @editImportedRecipeButtonCopy.
  ///
  /// In en, this message translates to:
  /// **'Create Copy & Edit'**
  String get editImportedRecipeButtonCopy;

  /// No description provided for @editImportedRecipeButtonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get editImportedRecipeButtonCancel;

  /// No description provided for @editDisplayNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Display Name'**
  String get editDisplayNameTitle;

  /// No description provided for @displayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your display name'**
  String get displayNameHint;

  /// No description provided for @displayNameEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Display name cannot be empty'**
  String get displayNameEmptyError;

  /// No description provided for @displayNameTooLongError.
  ///
  /// In en, this message translates to:
  /// **'Display name cannot exceed 50 characters'**
  String get displayNameTooLongError;

  /// No description provided for @errorUserNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User not logged in. Please sign in again.'**
  String get errorUserNotLoggedIn;

  /// No description provided for @displayNameUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Display name updated successfully!'**
  String get displayNameUpdateSuccess;

  /// Error message when updating display name fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update display name: {error}'**
  String displayNameUpdateError(String error);

  /// No description provided for @deletePictureConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Picture?'**
  String get deletePictureConfirmationTitle;

  /// No description provided for @deletePictureConfirmationBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your profile picture?'**
  String get deletePictureConfirmationBody;

  /// No description provided for @deletePictureSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile picture deleted.'**
  String get deletePictureSuccess;

  /// Error message when deleting profile picture fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete profile picture: {error}'**
  String deletePictureError(String error);

  /// Error message when updating profile picture fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile picture: {error}'**
  String updatePictureError(String error);

  /// No description provided for @updatePictureSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully!'**
  String get updatePictureSuccess;

  /// No description provided for @deletePictureTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete Picture'**
  String get deletePictureTooltip;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @settingsBrewingMethodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Home Screen Brewing Methods'**
  String get settingsBrewingMethodsTitle;

  /// Label for the filter button in the coffee beans screen
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Title for the sort dialog in coffee beans screen
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// Sort option for sorting by date added
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get dateAdded;

  /// No description provided for @secondsAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'s.'**
  String get secondsAbbreviation;

  /// No description provided for @settingsAppIcon.
  ///
  /// In en, this message translates to:
  /// **'App Icon'**
  String get settingsAppIcon;

  /// No description provided for @settingsAppIconDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsAppIconDefault;

  /// No description provided for @settingsAppIconLegacy.
  ///
  /// In en, this message translates to:
  /// **'Legacy'**
  String get settingsAppIconLegacy;

  /// Placeholder text for the search field in coffee beans screen
  ///
  /// In en, this message translates to:
  /// **'Search beans...'**
  String get searchBeans;

  /// Label for favorites filter chip
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Prefix for search filter chip
  ///
  /// In en, this message translates to:
  /// **'Search: '**
  String get searchPrefix;

  /// Label for clear all filters button
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Message shown when no beans match the search criteria
  ///
  /// In en, this message translates to:
  /// **'No beans match your search'**
  String get noBeansMatchSearch;

  /// Button text to clear all active filters
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;

  /// No description provided for @farm.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get farm;

  /// No description provided for @enterFarmer.
  ///
  /// In en, this message translates to:
  /// **'Enter farmer (optional)'**
  String get enterFarmer;

  /// No description provided for @enterFarm.
  ///
  /// In en, this message translates to:
  /// **'Enter farm (optional)'**
  String get enterFarm;

  /// No description provided for @requiredInformation.
  ///
  /// In en, this message translates to:
  /// **'Required Information'**
  String get requiredInformation;

  /// No description provided for @basicDetails.
  ///
  /// In en, this message translates to:
  /// **'Basic Details'**
  String get basicDetails;

  /// No description provided for @qualityMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Quality & Measurements'**
  String get qualityMeasurements;

  /// No description provided for @importantDates.
  ///
  /// In en, this message translates to:
  /// **'Important Dates'**
  String get importantDates;

  /// No description provided for @brewStats.
  ///
  /// In en, this message translates to:
  /// **'Brew Stats'**
  String get brewStats;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// Title text for the unpublish recipe confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Make Recipe Private'**
  String get unpublishRecipeDialogTitle;

  /// Warning message introducing the privacy changes
  ///
  /// In en, this message translates to:
  /// **'Warning: Making this recipe private will:'**
  String get unpublishRecipeDialogMessage;

  /// First privacy change bullet point
  ///
  /// In en, this message translates to:
  /// **'Remove it from public search results'**
  String get unpublishRecipeDialogBullet1;

  /// Second privacy change bullet point
  ///
  /// In en, this message translates to:
  /// **'Prevent new users from importing it'**
  String get unpublishRecipeDialogBullet2;

  /// Third privacy change bullet point
  ///
  /// In en, this message translates to:
  /// **'Users who already imported it will keep their copies'**
  String get unpublishRecipeDialogBullet3;

  /// Button text to keep the recipe public
  ///
  /// In en, this message translates to:
  /// **'Keep Public'**
  String get unpublishRecipeDialogKeepPublic;

  /// Button text to make the recipe private
  ///
  /// In en, this message translates to:
  /// **'Make Private'**
  String get unpublishRecipeDialogMakePrivate;

  /// Success message when a recipe is unpublished
  ///
  /// In en, this message translates to:
  /// **'Recipe unpublished successfully'**
  String get recipeUnpublishSuccess;

  /// Error message when unpublishing a recipe fails
  ///
  /// In en, this message translates to:
  /// **'Failed to unpublish recipe: {error}'**
  String recipeUnpublishError(String error);

  /// No description provided for @recipePublicTooltip.
  ///
  /// In en, this message translates to:
  /// **'Recipe is public - tap to make private'**
  String get recipePublicTooltip;

  /// No description provided for @recipePrivateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Recipe is private - share to make public'**
  String get recipePrivateTooltip;

  /// No description provided for @fieldClearButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get fieldClearButtonTooltip;

  /// No description provided for @dateFieldClearButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get dateFieldClearButtonTooltip;

  /// No description provided for @chipInputDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'This tag is already added'**
  String get chipInputDuplicateError;

  /// No description provided for @chipInputMaxTagsError.
  ///
  /// In en, this message translates to:
  /// **'Maximum number of tags reached ({maxChips})'**
  String chipInputMaxTagsError(Object maxChips);

  /// No description provided for @chipInputHintText.
  ///
  /// In en, this message translates to:
  /// **'Add a tag...'**
  String get chipInputHintText;

  /// No description provided for @unitFieldRequiredError.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get unitFieldRequiredError;

  /// No description provided for @unitFieldInvalidNumberError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get unitFieldInvalidNumberError;

  /// No description provided for @unitFieldMinValueError.
  ///
  /// In en, this message translates to:
  /// **'Value must be at least {min}'**
  String unitFieldMinValueError(Object min);

  /// No description provided for @unitFieldMaxValueError.
  ///
  /// In en, this message translates to:
  /// **'Value must be at most {max}'**
  String unitFieldMaxValueError(Object max);

  /// No description provided for @numericFieldRequiredError.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get numericFieldRequiredError;

  /// No description provided for @numericFieldInvalidNumberError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get numericFieldInvalidNumberError;

  /// No description provided for @numericFieldMinValueError.
  ///
  /// In en, this message translates to:
  /// **'Value must be at least {min}'**
  String numericFieldMinValueError(Object min);

  /// No description provided for @numericFieldMaxValueError.
  ///
  /// In en, this message translates to:
  /// **'Value must be at most {max}'**
  String numericFieldMaxValueError(Object max);

  /// No description provided for @dropdownSearchHintText.
  ///
  /// In en, this message translates to:
  /// **'Type to search...'**
  String get dropdownSearchHintText;

  /// No description provided for @dropdownSearchLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Error loading suggestions: {error}'**
  String dropdownSearchLoadingError(Object error);

  /// No description provided for @dropdownSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get dropdownSearchNoResults;

  /// No description provided for @dropdownSearchLoading.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get dropdownSearchLoading;

  /// No description provided for @dropdownSearchUseCustomEntry.
  ///
  /// In en, this message translates to:
  /// **'Use \"{currentQuery}\"'**
  String dropdownSearchUseCustomEntry(Object currentQuery);

  /// No description provided for @requiredInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'* Required'**
  String get requiredInfoSubtitle;

  /// No description provided for @inventoryWeightExample.
  ///
  /// In en, this message translates to:
  /// **'e.g., 250.5'**
  String get inventoryWeightExample;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to discard them?'**
  String get unsavedChangesMessage;

  /// No description provided for @unsavedChangesStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get unsavedChangesStay;

  /// No description provided for @unsavedChangesDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get unsavedChangesDiscard;

  /// Message shown when coffee weight is added back to beans after removing from brew diary
  ///
  /// In en, this message translates to:
  /// **'Added {amount}{unit} back to {beanName}. New weight: {newWeight}{unit}'**
  String beansWeightAddedBack(
      String amount, String beanName, String newWeight, String unit);

  /// Message shown when coffee weight is subtracted from beans when adding to brew diary
  ///
  /// In en, this message translates to:
  /// **'Subtracted {amount}{unit} from {beanName}. New weight: {newWeight}{unit}'**
  String beansWeightSubtracted(
      String amount, String beanName, String newWeight, String unit);

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsDisabledInSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Disabled in system settings'**
  String get notificationsDisabledInSystemSettings;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Generic error shown when the app cannot open an external link
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @notificationsDisabledDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications Disabled in System Settings'**
  String get notificationsDisabledDialogTitle;

  /// No description provided for @notificationsDisabledDialogContent.
  ///
  /// In en, this message translates to:
  /// **'You have disabled notifications in your device settings. To enable notifications, please open your device settings and allow notifications for Timer.Coffee.'**
  String get notificationsDisabledDialogContent;

  /// No description provided for @notificationDebug.
  ///
  /// In en, this message translates to:
  /// **'Notification Debug'**
  String get notificationDebug;

  /// No description provided for @testNotificationSystem.
  ///
  /// In en, this message translates to:
  /// **'Test notification system'**
  String get testNotificationSystem;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get notificationsDisabled;

  /// No description provided for @notificationPermissionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications?'**
  String get notificationPermissionDialogTitle;

  /// No description provided for @notificationPermissionDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'You can enable notifications to get useful updates (e.g. about new app versions). Enable now or change this anytime in settings.'**
  String get notificationPermissionDialogMessage;

  /// No description provided for @notificationPermissionEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get notificationPermissionEnable;

  /// No description provided for @notificationPermissionSkip.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notificationPermissionSkip;

  /// No description provided for @holidayGiftBoxTitle.
  ///
  /// In en, this message translates to:
  /// **'Holiday Gift Box'**
  String get holidayGiftBoxTitle;

  /// No description provided for @holidayGiftBoxInfoTrigger.
  ///
  /// In en, this message translates to:
  /// **'What is this?'**
  String get holidayGiftBoxInfoTrigger;

  /// No description provided for @holidayGiftBoxInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Curated seasonal offers from partners. Links are not affiliate - our goal is simply to bring a bit of joy to Timer.Coffee users these holidays. Pull to refresh anytime.'**
  String get holidayGiftBoxInfoBody;

  /// No description provided for @holidayGiftBoxNoOffers.
  ///
  /// In en, this message translates to:
  /// **'No offers available right now.'**
  String get holidayGiftBoxNoOffers;

  /// No description provided for @holidayGiftBoxNoOffersSub.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh or check back soon.'**
  String get holidayGiftBoxNoOffersSub;

  /// No description provided for @holidayGiftBoxShowingRegion.
  ///
  /// In en, this message translates to:
  /// **'Showing offers for {region}'**
  String holidayGiftBoxShowingRegion(String region);

  /// No description provided for @holidayGiftBoxViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get holidayGiftBoxViewDetails;

  /// No description provided for @holidayGiftBoxPromoCopied.
  ///
  /// In en, this message translates to:
  /// **'Promo code copied'**
  String get holidayGiftBoxPromoCopied;

  /// No description provided for @holidayGiftBoxPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo Code'**
  String get holidayGiftBoxPromoCode;

  /// Label for a percentage discount when one percent value is present
  ///
  /// In en, this message translates to:
  /// **'{percent}% off'**
  String giftDiscountOff(String percent);

  /// Label for a percentage discount when a range is present; uses the max percent
  ///
  /// In en, this message translates to:
  /// **'Up to {percent}% off'**
  String giftDiscountUpToOff(String percent);

  /// No description provided for @holidayGiftBoxTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get holidayGiftBoxTerms;

  /// No description provided for @holidayGiftBoxVisitSite.
  ///
  /// In en, this message translates to:
  /// **'Visit Partner Website'**
  String get holidayGiftBoxVisitSite;

  /// No description provided for @holidayGiftBoxValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String holidayGiftBoxValidUntil(String date);

  /// Relative expiry label for Gift Box offers (used when the offer ends within 7 days).
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Ends today} =1{Ends tomorrow} other{Ends in {days} days}}'**
  String holidayGiftBoxEndsInDays(num days);

  /// No description provided for @holidayGiftBoxValidWhileAvailable.
  ///
  /// In en, this message translates to:
  /// **'Valid while available'**
  String get holidayGiftBoxValidWhileAvailable;

  /// No description provided for @holidayGiftBoxUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String holidayGiftBoxUpdated(String date);

  /// No description provided for @holidayGiftBoxLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language: {language}'**
  String holidayGiftBoxLanguage(String language);

  /// No description provided for @holidayGiftBoxRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get holidayGiftBoxRetry;

  /// No description provided for @holidayGiftBoxLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load offers'**
  String get holidayGiftBoxLoadFailed;

  /// Shown when a gift box offer is missing or not available
  ///
  /// In en, this message translates to:
  /// **'Offer unavailable'**
  String get holidayGiftBoxOfferUnavailable;

  /// No description provided for @holidayGiftBoxBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Check out our holiday gift box'**
  String get holidayGiftBoxBannerTitle;

  /// No description provided for @holidayGiftBoxBannerCta.
  ///
  /// In en, this message translates to:
  /// **'See offers'**
  String get holidayGiftBoxBannerCta;

  /// No description provided for @regionEurope.
  ///
  /// In en, this message translates to:
  /// **'Europe'**
  String get regionEurope;

  /// No description provided for @regionNorthAmerica.
  ///
  /// In en, this message translates to:
  /// **'North America'**
  String get regionNorthAmerica;

  /// No description provided for @regionAsia.
  ///
  /// In en, this message translates to:
  /// **'Asia'**
  String get regionAsia;

  /// No description provided for @regionAustralia.
  ///
  /// In en, this message translates to:
  /// **'Australia / Oceania'**
  String get regionAustralia;

  /// No description provided for @regionWorldwide.
  ///
  /// In en, this message translates to:
  /// **'Worldwide'**
  String get regionWorldwide;

  /// No description provided for @regionAfrica.
  ///
  /// In en, this message translates to:
  /// **'Africa'**
  String get regionAfrica;

  /// No description provided for @regionMiddleEast.
  ///
  /// In en, this message translates to:
  /// **'Middle East'**
  String get regionMiddleEast;

  /// No description provided for @regionSouthAmerica.
  ///
  /// In en, this message translates to:
  /// **'South America'**
  String get regionSouthAmerica;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fa',
        'fi',
        'fr',
        'hr',
        'id',
        'it',
        'ja',
        'ko',
        'nl',
        'pl',
        'pt',
        'ro',
        'ru',
        'tr',
        'uk',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'hr':
      return AppLocalizationsHr();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
