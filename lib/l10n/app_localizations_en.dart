// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'Beans stats';

  @override
  String get totalBeansBrewedLabel => 'Total beans brewed';

  @override
  String get newBeansTriedLabel => 'New beans tried';

  @override
  String get originsExploredLabel => 'Origins explored';

  @override
  String get regionsExploredLabel => 'Regions explored';

  @override
  String get newRoastersDiscoveredLabel => 'New roasters discovered';

  @override
  String get favoriteRoastersLabel => 'Favorite roasters';

  @override
  String get topOriginsLabel => 'Top origins';

  @override
  String get topRegionsLabel => 'Top regions';

  @override
  String get lastrecipe => 'Most Recently Used Recipe:';

  @override
  String get userRecipesTitle => 'Your Recipes';

  @override
  String get userRecipesSectionCreated => 'Created by you';

  @override
  String get userRecipesSectionImported => 'Imported by you';

  @override
  String get userRecipesEmpty => 'No recipes found';

  @override
  String get userRecipesDeleteTitle => 'Delete recipe?';

  @override
  String get userRecipesDeleteMessage => 'This action cannot be undone.';

  @override
  String get userRecipesDeleteConfirm => 'Delete';

  @override
  String get userRecipesDeleteCancel => 'Cancel';

  @override
  String get userRecipesSnackbarDeleted => 'Recipe deleted';

  @override
  String get hubUserRecipesTitle => 'Your recipes';

  @override
  String get hubUserRecipesSubtitle =>
      'View and manage created and imported recipes';

  @override
  String get hubAccountSubtitle => 'Manage your profile';

  @override
  String get hubSignInCreateSubtitle =>
      'Sign in to sync recipes and preferences';

  @override
  String get hubBrewDiarySubtitle => 'View your brewing history and add notes';

  @override
  String get hubBrewStatsSubtitle =>
      'View personal and global brewing statistics and trends';

  @override
  String get hubSettingsSubtitle => 'Change app preferences and behavior';

  @override
  String get hubAboutSubtitle => 'App details, version and contributors';

  @override
  String get about => 'About';

  @override
  String get author => 'Author';

  @override
  String get authortext =>
      'Timer.Coffee App is created by Anton Karliner, a coffee enthusiast, media specialist, and photojournalist. I hope that this app will help you enjoy your coffee. Feel free to contribute on GitHub.';

  @override
  String get contributors => 'Contributors';

  @override
  String get errorLoadingContributors => 'Error loading Contributors';

  @override
  String get license => 'License';

  @override
  String get licensetext =>
      'This application is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.';

  @override
  String get licensebutton => 'Read the GNU General Public License v3';

  @override
  String get website => 'Website';

  @override
  String get sourcecode => 'Source code';

  @override
  String get support => 'Buy me a coffee';

  @override
  String get allrecipes => 'All Recipes';

  @override
  String get favoriterecipes => 'Favorite Recipes';

  @override
  String get coffeeamount => 'Coffee amount (g)';

  @override
  String get wateramount => 'Water amount (ml)';

  @override
  String get watertemp => 'Water Temperature';

  @override
  String get grindsize => 'Grind Size';

  @override
  String get brewtime => 'Brew Time';

  @override
  String get recipesummary => 'Recipe summary';

  @override
  String get recipesummarynote =>
      'Note: this is a basic recipe with default water and coffee amounts.';

  @override
  String get preparation => 'Preparation';

  @override
  String get brewingprocess => 'Brewing Process';

  @override
  String get step => 'Step';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'seconds',
      one: 'second',
      zero: 'seconds',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg => 'Thanks for using Timer.Coffee! Enjoy your';

  @override
  String get coffeefact => 'Coffee Fact';

  @override
  String get home => 'Home';

  @override
  String get appversion => 'App Version';

  @override
  String get tipsmall => 'Buy a small coffee';

  @override
  String get tipmedium => 'Buy a medium coffee';

  @override
  String get tiplarge => 'Buy a large coffee';

  @override
  String get supportdevelopment => 'Support the development';

  @override
  String get supportdevmsg =>
      'Your donations help to cover the maintenance costs (such as developer licenses, for example). They also allow me to try more coffee brewing devices and add more recipes to the app.';

  @override
  String get supportdevtnx => 'Thanks for considering to donate!';

  @override
  String get donationok => 'Thank You!';

  @override
  String get donationtnx =>
      'I really appreciate your support! Wish you a lot of great brews! ☕️';

  @override
  String get donationerr => 'Error';

  @override
  String get donationerrmsg =>
      'Error processing the purchase, please try again.';

  @override
  String get sharemsg => 'Check out this recipe:';

  @override
  String get finishbrew => 'Finish';

  @override
  String get settings => 'Settings';

  @override
  String get settingstheme => 'Theme';

  @override
  String get settingsthemelight => 'Light';

  @override
  String get settingsthemedark => 'Dark';

  @override
  String get settingsthemesystem => 'System';

  @override
  String get settingslang => 'Language';

  @override
  String get sweet => 'Sweet';

  @override
  String get balance => 'Balance';

  @override
  String get acidic => 'Acidic';

  @override
  String get light => 'Light';

  @override
  String get strong => 'Strong';

  @override
  String get slidertitle => 'Use sliders to adjust taste';

  @override
  String get whatsnewtitle => 'What\'s new';

  @override
  String get whatsnewclose => 'Close';

  @override
  String get seasonspecials => 'Season Specials';

  @override
  String get snow => 'Snow';

  @override
  String get noFavoriteRecipesMessage =>
      'Your list of favorite recipes is currently empty. Start exploring and brewing to discover your favorites!';

  @override
  String get explore => 'Explore';

  @override
  String get dateFormat => 'MMM d, yyyy';

  @override
  String get timeFormat => 'hh:mm a';

  @override
  String get brewdiary => 'Brew Diary';

  @override
  String get brewdiarynotfound => 'No entries found';

  @override
  String get beans => 'Beans';

  @override
  String get roaster => 'Roaster';

  @override
  String get rating => 'Rating';

  @override
  String get notes => 'Notes';

  @override
  String get statsscreen => 'Coffee Statistics';

  @override
  String get yourStats => 'Your stats';

  @override
  String get coffeeBrewed => 'Coffee brewed:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'Most used recipes:';

  @override
  String get globalStats => 'Global stats';

  @override
  String get unknownRecipe => 'Unknown Recipe';

  @override
  String get noData => 'No data';

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Someone just brewed $recipeName';
  }

  @override
  String get timePeriodToday => 'Today';

  @override
  String get timePeriodThisWeek => 'This Week';

  @override
  String get timePeriodThisMonth => 'This Month';

  @override
  String get timePeriodCustom => 'Custom';

  @override
  String get statsFor => 'Stats for ';

  @override
  String get homescreenbrewcoffee => 'Brew Coffee';

  @override
  String get homescreenhub => 'Hub';

  @override
  String get homescreenmore => 'More';

  @override
  String get addBeans => 'Add beans';

  @override
  String get removeBeans => 'Remove beans';

  @override
  String get name => 'Name';

  @override
  String get origin => 'Origin';

  @override
  String get details => 'Details';

  @override
  String get coffeebeans => 'Coffee Beans';

  @override
  String get loading => 'Loading';

  @override
  String get nocoffeebeans => 'No coffee beans found';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDeleteTitle => 'Delete Entry?';

  @override
  String get recipeDuplicateConfirmTitle => 'Duplicate Recipe?';

  @override
  String get recipeDuplicateConfirmMessage =>
      'This will create a copy of your recipe that you can edit independently. Do you want to continue?';

  @override
  String get confirmDeleteMessage =>
      'Are you sure you want to delete this entry? This action cannot be undone.';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get toggleEditMode => 'Toggle edit mode';

  @override
  String get coffeeBeansDetails => 'Coffee Beans Details';

  @override
  String get edit => 'Edit';

  @override
  String get coffeeBeansNotFound => 'Coffee beans not found';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get geographyTerroir => 'Geography/Terroir';

  @override
  String get variety => 'Variety';

  @override
  String get region => 'Region';

  @override
  String get elevation => 'Elevation';

  @override
  String get harvestDate => 'Harvest Date';

  @override
  String get processing => 'Processing';

  @override
  String get processingMethod => 'Processing Method';

  @override
  String get roastDate => 'Roast Date';

  @override
  String get roastLevel => 'Roast Level';

  @override
  String get cuppingScore => 'Cupping Score';

  @override
  String get flavorProfile => 'Flavor Profile';

  @override
  String get tastingNotes => 'Tasting Notes';

  @override
  String get additionalNotes => 'Additional Notes';

  @override
  String get noCoffeeBeans => 'No coffee beans found';

  @override
  String get editCoffeeBeans => 'Edit Coffee Beans';

  @override
  String get addCoffeeBeans => 'Add Coffee Beans';

  @override
  String get showImagePicker => 'Show Image Picker';

  @override
  String get pleaseNote => 'Please note';

  @override
  String get firstTimePopupMessage =>
      '1. We use external services to process images. By continuing, you agree to this.\n2. While we do not store your images, please avoid including any personal details.\n3. Image recognition is currently limited to 10 tokens per month (1 token = 1 image). This limit may change in the future.';

  @override
  String get ok => 'OK';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get selectFromPhotos => 'Select from photos';

  @override
  String get takeAdditionalPhoto => 'Take additional photo?';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get selectedImages => 'Selected Images';

  @override
  String get selectedImage => 'Selected Image';

  @override
  String get backToSelection => 'Back to Selection';

  @override
  String get next => 'Next';

  @override
  String get unexpectedErrorOccurred => 'Unexpected error occurred';

  @override
  String get tokenLimitReached =>
      'Sorry, you reached your token limit for image recognition this month';

  @override
  String get noCoffeeLabelsDetected =>
      'No coffee labels detected. Try with another image.';

  @override
  String get collectedInformation => 'Collected Information';

  @override
  String get enterRoaster => 'Enter roaster';

  @override
  String get enterName => 'Enter name';

  @override
  String get enterOrigin => 'Enter origin';

  @override
  String get optional => 'Optional';

  @override
  String get enterVariety => 'Enter variety';

  @override
  String get enterProcessingMethod => 'Enter processing method';

  @override
  String get enterRoastLevel => 'Enter roast level';

  @override
  String get enterRegion => 'Enter region';

  @override
  String get enterTastingNotes => 'Enter tasting notes';

  @override
  String get enterElevation => 'Enter elevation';

  @override
  String get enterCuppingScore => 'Enter cupping score';

  @override
  String get enterNotes => 'Enter notes';

  @override
  String get inventory => 'Inventory';

  @override
  String get amountLeft => 'Amount Left';

  @override
  String get enterAmountLeft => 'Enter amount left';

  @override
  String get selectHarvestDate => 'Select Harvest Date';

  @override
  String get selectRoastDate => 'Select Roast Date';

  @override
  String get selectDate => 'Select date';

  @override
  String get save => 'Save';

  @override
  String get fillRequiredFields => 'Please fill in all required fields.';

  @override
  String get analyzing => 'Analyzing';

  @override
  String get errorMessage => 'Error';

  @override
  String get selectCoffeeBeans => 'Select Coffee Beans';

  @override
  String get addNewBeans => 'Add New Beans';

  @override
  String get favorite => 'Favorite';

  @override
  String get notFavorite => 'Not Favorite';

  @override
  String get myBeans => 'My Beans';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get signInSuccessful => 'Successfully signed in with Apple';

  @override
  String get signInError => 'Error signing in with Apple';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signOutSuccessful => 'Successfully signed out';

  @override
  String get signInSuccessfulGoogle => 'Successfully signed in with Google';

  @override
  String get signInWithEmail => 'Sign in with Email';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get cancel => 'Cancel';

  @override
  String get sendMagicLink => 'Send Magic Link';

  @override
  String get magicLinkSent => 'Magic link sent! Check your email.';

  @override
  String get sendOTP => 'Send OTP';

  @override
  String get otpSent => 'OTP sent to your email';

  @override
  String get otpSendError => 'Error sending OTP';

  @override
  String get enterOTP => 'Enter OTP';

  @override
  String get otpHint => 'Enter 6-digit code';

  @override
  String get verify => 'Verify';

  @override
  String get signInSuccessfulEmail => 'Sign in successful';

  @override
  String get invalidOTP => 'Invalid OTP';

  @override
  String get otpVerificationError => 'Error verifying OTP';

  @override
  String get success => 'Success!';

  @override
  String get otpSentMessage =>
      'An OTP is being sent to your email. Please enter it below when you receive it.';

  @override
  String get otpHint2 => 'Enter code here';

  @override
  String get signInCreate => 'Sign In / Create account';

  @override
  String get accountManagement => 'Account Management';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountWarning =>
      'Please note: if you choose to continue, we will delete your account and related data from our servers. The local copy of the data will remain on the device, if you want to delete it too, you can simply delete the app. In order to re-enable syncronization, you\'ll need to create an account again';

  @override
  String get deleteAccountConfirmation => 'Succesfully deleted account';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get accountDeletionError =>
      'Error deleting your account, please try again';

  @override
  String get deleteAccountTitle => 'Important';

  @override
  String get selectBeans => 'Select Beans';

  @override
  String get all => 'All';

  @override
  String get selectRoaster => 'Select Roaster';

  @override
  String get selectOrigin => 'Select Origin';

  @override
  String get resetFilters => 'Reset Filters';

  @override
  String get showFavoritesOnly => 'Show favorites only';

  @override
  String get apply => 'Apply';

  @override
  String get selectSize => 'Select Size';

  @override
  String get sizeStandard => 'Standard';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'My Year with Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      'Hey, thanks for being a part of Timer.Coffee universe this year!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'First things first.\nYou brewed some coffee this year$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'To be more precise,\nyou brewed $liters liters of coffee in 2024!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'You used beans from $roasterCount roasters';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Your top 3 roasters were:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Coffee took you on a trip\naround the world$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'You tasted coffee beans\nfrom $originCount countries!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'You weren’t brewing alone…';

  @override
  String get yearlyStatsStory7Part2 =>
      '...but with users from 110 other\ncountries across 6 continents!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'You stayed true to yourself and used only these $count brewing methods this year:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'You were discovering new tastes and used $count brewing methods this year:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'You were a true coffee discoverer and used $count brewing methods this year:';
  }

  @override
  String get yearlyStatsStory9Text => 'So much else to discover!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'Your top-3 recipes in 2024 were$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'See you in 2025!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Show some love ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Donate';

  @override
  String get yearlyStatsActionShare => 'Share your progress';

  @override
  String get yearlyStatsUnknown => 'Unknown';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Failed to share: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'My year with Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes => 'My top-3 recipes:';

  @override
  String get yearlyStatsShareProgressTop3Roasters => 'My top-3 roasters:';

  @override
  String get yearlyStatsFailedToLike => 'Failed to like. Please try again.';

  @override
  String get labelCoffeeBrewed => 'Coffee brewed';

  @override
  String get labelTastedBeansBy => 'Tasted beans by';

  @override
  String get labelDiscoveredCoffeeFrom => 'Discovered coffee from';

  @override
  String get labelUsedBrewingMethods => 'Used';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'roasters',
      one: 'roaster',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'countries',
      one: 'country',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'brewing methods',
      one: 'brewing method',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Edit Recipe';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Create Recipe';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Recipe Steps';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Recipe Name';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Short Description';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Brewing Method';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Coffee Amount (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Water Amount (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Water Temperature (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Grind Size';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => 'Total Brew Time:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Minutes';

  @override
  String get recipeCreationScreenSecondsLabel => 'Seconds';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Preparation Step';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Brew Step $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Step Description';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Step Time: ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'Please enter a recipe name';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Please enter a short description';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Please select a brewing method';

  @override
  String get recipeCreationScreenRequiredValidator => 'Required';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Invalid number';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Please enter a step description';

  @override
  String get recipeCreationScreenContinueButton => 'Continue to Recipe Steps';

  @override
  String get recipeCreationScreenAddStepButton => 'Add Step';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Save Recipe';

  @override
  String get recipeCreationScreenUpdateSuccess => 'Recipe updated successfully';

  @override
  String get recipeCreationScreenSaveSuccess => 'Recipe saved successfully';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Error saving recipe: $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'grams';

  @override
  String get unitMillilitersLong => 'milliliters';

  @override
  String get recipeCopySuccess => 'Recipe copied successfully!';

  @override
  String get recipeDuplicateSuccess => 'Recipe duplicated successfully!';

  @override
  String recipeCopyError(String error) {
    return 'Error copying recipe: $error';
  }

  @override
  String get createRecipe => 'Create Recipe';

  @override
  String errorSyncingData(Object error) {
    return 'Error syncing data: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Error signing out: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Preparation';

  @override
  String get loadingEllipsis => 'Loading...';

  @override
  String get recipeDeletedSuccess => 'Recipe deleted successfully';

  @override
  String recipeDeleteError(Object error) {
    return 'Failed to delete recipe: $error';
  }

  @override
  String get noRecipesFound => 'No recipes found';

  @override
  String recipeLoadError(Object error) {
    return 'Failed to load recipe: $error';
  }

  @override
  String get unknownBrewingMethod => 'Unknown Brewing Method';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Failed to load copied recipe for editing.';

  @override
  String get recipeCopyErrorOperationFailed => 'Operation failed.';

  @override
  String get notProvided => 'Not provided';

  @override
  String get recipeUpdateFailedFetch => 'Failed to fetch updated recipe data.';

  @override
  String get recipeImportSuccess => 'Recipe imported successfully!';

  @override
  String get recipeImportFailedSave => 'Failed to save imported recipe.';

  @override
  String get recipeImportFailedFetch =>
      'Failed to fetch recipe data for import.';

  @override
  String get recipeNotImported => 'Recipe not imported.';

  @override
  String get recipeNotFoundCloud =>
      'Recipe not found in the cloud or is not public.';

  @override
  String get recipeLoadErrorGeneric => 'Error loading recipe.';

  @override
  String get recipeUpdateAvailableTitle => 'Update Available';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'A newer version of \'$recipeName\' is available online. Update?';
  }

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogDuplicate => 'Duplicate';

  @override
  String get dialogUpdate => 'Update';

  @override
  String get recipeImportTitle => 'Import Recipe';

  @override
  String recipeImportBody(String recipeName) {
    return 'Do you want to import the recipe \'$recipeName\' from the cloud?';
  }

  @override
  String get dialogImport => 'Import';

  @override
  String get moderationReviewNeededTitle => 'Moderation Review Needed';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'The following recipe(s) require review due to content moderation issues: $recipeNames';
  }

  @override
  String get dismiss => 'Dismiss';

  @override
  String get reviewRecipeButton => 'Review Recipe';

  @override
  String get signInRequiredTitle => 'Sign In Required';

  @override
  String get signInRequiredBodyShare =>
      'You need to sign in to share your own recipes.';

  @override
  String get syncSuccess => 'Sync successful!';

  @override
  String get tooltipEditRecipe => 'Edit Recipe';

  @override
  String get tooltipCopyRecipe => 'Copy Recipe';

  @override
  String get tooltipDuplicateRecipe => 'Duplicate Recipe';

  @override
  String get tooltipShareRecipe => 'Share Recipe';

  @override
  String get signInRequiredSnackbar => 'Sign In Required';

  @override
  String get moderationErrorFunction => 'Content moderation check failed.';

  @override
  String get moderationReasonDefault => 'Content flagged for review.';

  @override
  String get moderationFailedTitle => 'Moderation Failed';

  @override
  String moderationFailedBody(String reason) {
    return 'This recipe cannot be shared because: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Error sharing recipe: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName on Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'Couldn\'t check content status. Saved locally, will check on next sync.';

  @override
  String get saveLocallyModerationFailedTitle => 'Changes Saved Locally';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Your local changes have been saved, but the public version couldn\'t be updated due to content moderation: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Edit Imported Recipe';

  @override
  String get editImportedRecipeBody =>
      'This is an imported recipe. Editing it will create a new, independent copy. Do you want to continue?';

  @override
  String get editImportedRecipeButtonCopy => 'Create Copy & Edit';

  @override
  String get editImportedRecipeButtonCancel => 'Cancel';

  @override
  String get editDisplayNameTitle => 'Edit Display Name';

  @override
  String get displayNameHint => 'Enter your display name';

  @override
  String get displayNameEmptyError => 'Display name cannot be empty';

  @override
  String get displayNameTooLongError =>
      'Display name cannot exceed 50 characters';

  @override
  String get errorUserNotLoggedIn =>
      'User not logged in. Please sign in again.';

  @override
  String get displayNameUpdateSuccess => 'Display name updated successfully!';

  @override
  String displayNameUpdateError(String error) {
    return 'Failed to update display name: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Delete Picture?';

  @override
  String get deletePictureConfirmationBody =>
      'Are you sure you want to delete your profile picture?';

  @override
  String get deletePictureSuccess => 'Profile picture deleted.';

  @override
  String deletePictureError(String error) {
    return 'Failed to delete profile picture: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Failed to update profile picture: $error';
  }

  @override
  String get updatePictureSuccess => 'Profile picture updated successfully!';

  @override
  String get deletePictureTooltip => 'Delete Picture';

  @override
  String get account => 'Account';

  @override
  String get settingsBrewingMethodsTitle => 'Home Screen Brewing Methods';

  @override
  String get filter => 'Filter';

  @override
  String get sortBy => 'Sort by';

  @override
  String get dateAdded => 'Date Added';

  @override
  String get secondsAbbreviation => 's.';

  @override
  String get settingsAppIcon => 'App Icon';

  @override
  String get settingsAppIconDefault => 'Default';

  @override
  String get settingsAppIconLegacy => 'Legacy';

  @override
  String get searchBeans => 'Search beans...';

  @override
  String get favorites => 'Favorites';

  @override
  String get searchPrefix => 'Search: ';

  @override
  String get clearAll => 'Clear All';

  @override
  String get noBeansMatchSearch => 'No beans match your search';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get farmer => 'Farmer';

  @override
  String get farm => 'Farm';

  @override
  String get enterFarmer => 'Enter farmer (optional)';

  @override
  String get enterFarm => 'Enter farm (optional)';

  @override
  String get requiredInformation => 'Required Information';

  @override
  String get basicDetails => 'Basic Details';

  @override
  String get qualityMeasurements => 'Quality & Measurements';

  @override
  String get importantDates => 'Important Dates';

  @override
  String get brewStats => 'Brew Stats';

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String get unpublishRecipeDialogTitle => 'Make Recipe Private';

  @override
  String get unpublishRecipeDialogMessage =>
      'Warning: Making this recipe private will:';

  @override
  String get unpublishRecipeDialogBullet1 =>
      'Remove it from public search results';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'Prevent new users from importing it';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'Users who already imported it will keep their copies';

  @override
  String get unpublishRecipeDialogKeepPublic => 'Keep Public';

  @override
  String get unpublishRecipeDialogMakePrivate => 'Make Private';

  @override
  String get recipeUnpublishSuccess => 'Recipe unpublished successfully';

  @override
  String recipeUnpublishError(String error) {
    return 'Failed to unpublish recipe: $error';
  }

  @override
  String get recipePublicTooltip => 'Recipe is public - tap to make private';

  @override
  String get recipePrivateTooltip => 'Recipe is private - share to make public';

  @override
  String get fieldClearButtonTooltip => 'Clear';

  @override
  String get dateFieldClearButtonTooltip => 'Clear date';

  @override
  String get chipInputDuplicateError => 'This tag is already added';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return 'Maximum number of tags reached ($maxChips)';
  }

  @override
  String get chipInputHintText => 'Add a tag...';

  @override
  String get unitFieldRequiredError => 'This field is required';

  @override
  String get unitFieldInvalidNumberError => 'Please enter a valid number';

  @override
  String unitFieldMinValueError(Object min) {
    return 'Value must be at least $min';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return 'Value must be at most $max';
  }

  @override
  String get numericFieldRequiredError => 'This field is required';

  @override
  String get numericFieldInvalidNumberError => 'Please enter a valid number';

  @override
  String numericFieldMinValueError(Object min) {
    return 'Value must be at least $min';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return 'Value must be at most $max';
  }

  @override
  String get dropdownSearchHintText => 'Type to search...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return 'Error loading suggestions: $error';
  }

  @override
  String get dropdownSearchNoResults => 'No results found';

  @override
  String get dropdownSearchLoading => 'Searching...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return 'Use \"$currentQuery\"';
  }

  @override
  String get requiredInfoSubtitle => '* Required';

  @override
  String get inventoryWeightExample => 'e.g., 250.5';

  @override
  String get unsavedChangesTitle => 'Unsaved Changes';

  @override
  String get unsavedChangesMessage =>
      'You have unsaved changes. Are you sure you want to discard them?';

  @override
  String get unsavedChangesStay => 'Stay';

  @override
  String get unsavedChangesDiscard => 'Discard';

  @override
  String beansWeightAddedBack(
      String amount, String beanName, String newWeight, String unit) {
    return 'Added $amount$unit back to $beanName. New weight: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
      String amount, String beanName, String newWeight, String unit) {
    return 'Subtracted $amount$unit from $beanName. New weight: $newWeight$unit';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsDisabledInSystemSettings =>
      'Disabled in system settings';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get notificationsDisabledDialogTitle =>
      'Notifications Disabled in System Settings';

  @override
  String get notificationsDisabledDialogContent =>
      'You have disabled notifications in your device settings. To enable notifications, please open your device settings and allow notifications for Timer.Coffee.';

  @override
  String get notificationDebug => 'Notification Debug';

  @override
  String get testNotificationSystem => 'Test notification system';

  @override
  String get notificationsEnabled => 'Enabled';

  @override
  String get notificationsDisabled => 'Disabled';

  @override
  String get notificationPermissionDialogTitle => 'Enable Notifications?';

  @override
  String get notificationPermissionDialogMessage =>
      'You can enable notifications to get useful updates (e.g. about new app versions). Enable now or change this anytime in settings.';

  @override
  String get notificationPermissionEnable => 'Enable';

  @override
  String get notificationPermissionSkip => 'Not Now';

  @override
  String get holidayGiftBoxTitle => 'Holiday Gift Box';

  @override
  String get holidayGiftBoxInfoTrigger => 'What is this?';

  @override
  String get holidayGiftBoxInfoBody =>
      'Curated seasonal offers from partners. Links are not affiliate - our goal is simply to bring a bit of joy to Timer.Coffee users these holidays. Pull to refresh anytime.';

  @override
  String get holidayGiftBoxNoOffers => 'No offers available right now.';

  @override
  String get holidayGiftBoxNoOffersSub => 'Pull to refresh or check back soon.';

  @override
  String holidayGiftBoxShowingRegion(String region) {
    return 'Showing offers for $region';
  }

  @override
  String get holidayGiftBoxViewDetails => 'View Details';

  @override
  String get holidayGiftBoxPromoCopied => 'Promo code copied';

  @override
  String get holidayGiftBoxPromoCode => 'Promo Code';

  @override
  String giftDiscountOff(String percent) {
    return '$percent% off';
  }

  @override
  String giftDiscountUpToOff(String percent) {
    return 'Up to $percent% off';
  }

  @override
  String get holidayGiftBoxTerms => 'Terms & Conditions';

  @override
  String get holidayGiftBoxVisitSite => 'Visit Partner Website';

  @override
  String holidayGiftBoxValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get holidayGiftBoxValidWhileAvailable => 'Valid while available';

  @override
  String holidayGiftBoxUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String holidayGiftBoxLanguage(String language) {
    return 'Language: $language';
  }

  @override
  String get holidayGiftBoxRetry => 'Retry';

  @override
  String get holidayGiftBoxLoadFailed => 'Failed to load offers';

  @override
  String get holidayGiftBoxOfferUnavailable => 'Offer unavailable';

  @override
  String get holidayGiftBoxBannerTitle => 'Check out our holiday gift box';

  @override
  String get holidayGiftBoxBannerCta => 'See offers';

  @override
  String get regionEurope => 'Europe';

  @override
  String get regionNorthAmerica => 'North America';

  @override
  String get regionAsia => 'Asia';

  @override
  String get regionAustralia => 'Australia / Oceania';

  @override
  String get regionWorldwide => 'Worldwide';

  @override
  String get regionAfrica => 'Africa';

  @override
  String get regionMiddleEast => 'Middle East';

  @override
  String get regionSouthAmerica => 'South America';
}
