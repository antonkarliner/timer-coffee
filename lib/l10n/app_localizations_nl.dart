// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'Bonenstatistieken';

  @override
  String get totalBeansBrewedLabel => 'Totaal gebrouwen bonen';

  @override
  String get newBeansTriedLabel => 'Nieuwe bonen geprobeerd';

  @override
  String get originsExploredLabel => 'Ontdekte herkomsten';

  @override
  String get regionsExploredLabel => 'Ontdekte regio\'s';

  @override
  String get newRoastersDiscoveredLabel => 'Nieuwe branders ontdekt';

  @override
  String get favoriteRoastersLabel => 'Favoriete branderijen';

  @override
  String get topOriginsLabel => 'Top herkomsten';

  @override
  String get topRegionsLabel => 'Top regio\'s';

  @override
  String get lastrecipe => 'Meest Recent Gebruikte Recept:';

  @override
  String get userRecipesTitle => 'Jouw recepten';

  @override
  String get userRecipesSectionCreated => 'Door jou gemaakt';

  @override
  String get userRecipesSectionImported => 'Door jou geïmporteerd';

  @override
  String get userRecipesEmpty => 'Geen recepten gevonden';

  @override
  String get userRecipesDeleteTitle => 'Recept verwijderen?';

  @override
  String get userRecipesDeleteMessage =>
      'Deze actie kan niet ongedaan worden gemaakt.';

  @override
  String get userRecipesDeleteConfirm => 'Verwijderen';

  @override
  String get userRecipesDeleteCancel => 'Annuleren';

  @override
  String get userRecipesSnackbarDeleted => 'Recept verwijderd';

  @override
  String get hubUserRecipesTitle => 'Jouw recepten';

  @override
  String get hubUserRecipesSubtitle =>
      'Gemaakte en geïmporteerde recepten bekijken en beheren';

  @override
  String get hubAccountSubtitle => 'Beheer je profiel';

  @override
  String get hubSignInCreateSubtitle =>
      'Meld je aan om recepten en voorkeuren te synchroniseren';

  @override
  String get hubBrewDiarySubtitle =>
      'Bekijk je brouwgeschiedenis en voeg notities toe';

  @override
  String get hubBrewStatsSubtitle =>
      'Bekijk persoonlijke en wereldwijde brouwstatistieken en trends';

  @override
  String get hubSettingsSubtitle => 'Wijzig app-voorkeuren en gedrag';

  @override
  String get hubAboutSubtitle => 'App-gegevens, versie en bijdragers';

  @override
  String get about => 'Over';

  @override
  String get author => 'Auteur';

  @override
  String get authortext =>
      'Timer.Coffee App is gecreëerd door Anton Karliner, een koffie-enthousiast, mediaspecialist en fotojournalist. Ik hoop dat deze app je zal helpen genieten van je koffie. Voel je vrij om bij te dragen op GitHub.';

  @override
  String get contributors => 'Bijdragers';

  @override
  String get errorLoadingContributors => 'Fout bij het laden van bijdragers';

  @override
  String get license => 'Licentie';

  @override
  String get licensetext =>
      'Deze applicatie is vrije software: je kunt het herverdelen en/of wijzigen onder de voorwaarden van de GNU General Public License zoals gepubliceerd door de Free Software Foundation, ofwel versie 3 van de Licentie, of (naar keuze) elke latere versie.';

  @override
  String get licensebutton => 'Lees de GNU General Public License v3';

  @override
  String get website => 'Website';

  @override
  String get sourcecode => 'Broncode';

  @override
  String get support => 'Koop me een koffie';

  @override
  String get allrecipes => 'Alle Recepten';

  @override
  String get favoriterecipes => 'Favoriete Recepten';

  @override
  String get coffeeamount => 'Hoeveelheid koffie (g)';

  @override
  String get wateramount => 'Hoeveelheid water (ml)';

  @override
  String get watertemp => 'Watertemperatuur';

  @override
  String get grindsize => 'Maalgraad';

  @override
  String get brewtime => 'Bereidingstijd';

  @override
  String get recipesummary => 'Receptoverzicht';

  @override
  String get recipesummarynote =>
      'Opmerking: dit is een basisrecept met standaard hoeveelheden water en koffie.';

  @override
  String get preparation => 'Voorbereiding';

  @override
  String get brewingprocess => 'Bereidingsproces';

  @override
  String get step => 'Stap';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'seconden',
      one: 'seconde',
      zero: 'seconden',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg =>
      'Bedankt voor het gebruiken van Timer.Coffee! Geniet van je';

  @override
  String get coffeefact => 'Koffieweetje';

  @override
  String get home => 'Home';

  @override
  String get appversion => 'App Versie';

  @override
  String get tipsmall => 'Koop een kleine koffie';

  @override
  String get tipmedium => 'Koop een medium koffie';

  @override
  String get tiplarge => 'Koop een grote koffie';

  @override
  String get supportdevelopment => 'Steun de ontwikkeling';

  @override
  String get supportdevmsg =>
      'Jouw donaties helpen om de onderhoudskosten te dekken (zoals ontwikkelaarslicenties, bijvoorbeeld). Ze stellen me ook in staat om meer koffiezetapparaten te proberen en meer recepten aan de app toe te voegen.';

  @override
  String get supportdevtnx => 'Bedankt dat je overweegt te doneren!';

  @override
  String get donationok => 'Dankjewel!';

  @override
  String get donationtnx =>
      'Ik waardeer je steun echt! Ik wens je veel geweldige brouwsels! ☕️';

  @override
  String get donationerr => 'Fout';

  @override
  String get donationerrmsg =>
      'Fout bij het verwerken van de aankoop, probeer het opnieuw.';

  @override
  String get sharemsg => 'Bekijk dit recept:';

  @override
  String get finishbrew => 'Klaar';

  @override
  String get settings => 'Instellingen';

  @override
  String get settingstheme => 'Thema';

  @override
  String get settingsthemelight => 'Licht';

  @override
  String get settingsthemedark => 'Donker';

  @override
  String get settingsthemesystem => 'Systeem';

  @override
  String get settingslang => 'Taal';

  @override
  String get sweet => 'Zoet';

  @override
  String get balance => 'Balans';

  @override
  String get acidic => 'Zuur';

  @override
  String get light => 'Licht';

  @override
  String get strong => 'Sterk';

  @override
  String get slidertitle => 'Gebruik schuifregelaars om smaak aan te passen';

  @override
  String get whatsnewtitle => 'Wat is nieuw';

  @override
  String get whatsnewclose => 'Sluiten';

  @override
  String get seasonspecials => 'Seizoen Specials';

  @override
  String get snow => 'Sneeuw';

  @override
  String get noFavoriteRecipesMessage =>
      'Je lijst met favoriete recepten is momenteel leeg. Begin met verkennen en brouwen om je favorieten te ontdekken!';

  @override
  String get explore => 'Verken';

  @override
  String get dateFormat => 'd MMM yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Brouwdagboek';

  @override
  String get brewdiarynotfound => 'Geen vermeldingen gevonden';

  @override
  String get beans => 'Bonen';

  @override
  String get roaster => 'Branderij';

  @override
  String get rating => 'Beoordeling';

  @override
  String get notes => 'Notities';

  @override
  String get statsscreen => 'Koffiestijl statistieken';

  @override
  String get yourStats => 'Jouw statistiek';

  @override
  String get coffeeBrewed => 'Koffie Gebrouwen:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'Meeste gebruikte recepten:';

  @override
  String get globalStats => 'Global Statistieken';

  @override
  String get unknownRecipe => 'Onbekend Recept';

  @override
  String get noData => 'Geen data';

  @override
  String error(String error) {
    return 'Fout: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'iemand heeft zojuist $recipeName gebrouwd.';
  }

  @override
  String get timePeriodToday => 'Vandaag';

  @override
  String get timePeriodThisWeek => 'Deze Week';

  @override
  String get timePeriodThisMonth => 'Deze Maand';

  @override
  String get timePeriodCustom => 'Custom';

  @override
  String get statsFor => 'Stats voor ';

  @override
  String get homescreenbrewcoffee => 'Zet koffie';

  @override
  String get homescreenhub => 'Hub';

  @override
  String get homescreenmore => 'Meer';

  @override
  String get addBeans => 'Bonen toevoegen';

  @override
  String get removeBeans => 'Bonen verwijderen';

  @override
  String get name => 'Naam';

  @override
  String get origin => 'Oorsprong';

  @override
  String get details => 'Details';

  @override
  String get coffeebeans => 'Koffiebonen';

  @override
  String get loading => 'Laden';

  @override
  String get nocoffeebeans => 'Geen koffiebonen gevonden';

  @override
  String get delete => 'Verwijder';

  @override
  String get confirmDeleteTitle => 'Invoer verwijderen?';

  @override
  String get recipeDuplicateConfirmTitle => 'Recept dupliceren?';

  @override
  String get recipeDuplicateConfirmMessage =>
      'Dit zal een kopie van je recept maken die je onafhankelijk kunt bewerken. Wil je doorgaan?';

  @override
  String get confirmDeleteMessage =>
      'Weet je zeker dat je deze invoer wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.';

  @override
  String get removeFavorite => 'Verwijder uit favorieten';

  @override
  String get addFavorite => 'Voeg toe aan favorieten';

  @override
  String get toggleEditMode => 'Bewerkingsmodus in-/uitschakelen';

  @override
  String get coffeeBeansDetails => 'Koffiebonen Details';

  @override
  String get edit => 'Bewerk';

  @override
  String get coffeeBeansNotFound => 'Koffiebonen niet gevonden';

  @override
  String get basicInformation => 'Basisgegevens';

  @override
  String get geographyTerroir => 'Geografie/Terroir';

  @override
  String get variety => 'Variëteit';

  @override
  String get region => 'Regio';

  @override
  String get elevation => 'Hoogte';

  @override
  String get harvestDate => 'Oogstdatum';

  @override
  String get processing => 'Verwerking';

  @override
  String get processingMethod => 'Verwerkingsmethode';

  @override
  String get roastDate => 'Branddatum';

  @override
  String get roastLevel => 'Branding';

  @override
  String get cuppingScore => 'Cuppingscore';

  @override
  String get flavorProfile => 'Smaakprofiel';

  @override
  String get tastingNotes => 'Smaaknotities';

  @override
  String get additionalNotes => 'Extra notities';

  @override
  String get noCoffeeBeans => 'Geen koffiebonen gevonden';

  @override
  String get editCoffeeBeans => 'Koffiebonen bewerken';

  @override
  String get addCoffeeBeans => 'Koffiebonen toevoegen';

  @override
  String get showImagePicker => 'Toon afbeeldingskiezer';

  @override
  String get pleaseNote => 'Let op';

  @override
  String get firstTimePopupMessage =>
      '1. We gebruiken externe services om afbeeldingen te verwerken. Door verder te gaan, gaat u hiermee akkoord.\n2. Hoewel we uw afbeeldingen niet opslaan, dient u te voorkomen dat u persoonlijke gegevens toevoegt.\n3. Afbeeldingherkenning is momenteel beperkt tot 10 tokens per maand (1 token = 1 afbeelding). Deze limiet kan in de toekomst veranderen.';

  @override
  String get ok => 'OK';

  @override
  String get takePhoto => 'Maak een foto';

  @override
  String get selectFromPhotos => 'Selecteer uit foto\'s';

  @override
  String get takeAdditionalPhoto => 'Nog een foto maken?';

  @override
  String get no => 'Nee';

  @override
  String get yes => 'Ja';

  @override
  String get selectedImages => 'Geselecteerde afbeeldingen';

  @override
  String get selectedImage => 'Geselecteerde afbeelding';

  @override
  String get backToSelection => 'Terug naar selectie';

  @override
  String get next => 'Volgende';

  @override
  String get unexpectedErrorOccurred => 'Onverwachte fout opgetreden';

  @override
  String get tokenLimitReached =>
      'Sorry, je hebt je tokenlimiet voor beeldherkenning deze maand bereikt';

  @override
  String get noCoffeeLabelsDetected =>
      'Geen koffie labels gedetecteerd. Probeer het met een andere afbeelding.';

  @override
  String get collectedInformation => 'Verzamelde informatie';

  @override
  String get enterRoaster => 'Voer brander in';

  @override
  String get enterName => 'Voer naam in';

  @override
  String get enterOrigin => 'Voer oorsprong in';

  @override
  String get optional => 'Optioneel';

  @override
  String get enterVariety => 'Voer variëteit in';

  @override
  String get enterProcessingMethod => 'Voer verwerkingsmethode in';

  @override
  String get enterRoastLevel => 'Voer branding in';

  @override
  String get enterRegion => 'Voer regio in';

  @override
  String get enterTastingNotes => 'Voer smaaknotities in';

  @override
  String get enterElevation => 'Voer hoogte in';

  @override
  String get enterCuppingScore => 'Voer cuppingscore in';

  @override
  String get enterNotes => 'Voer notities in';

  @override
  String get inventory => 'Voorraad';

  @override
  String get amountLeft => 'Resterende hoeveelheid';

  @override
  String get enterAmountLeft => 'Voer de resterende hoeveelheid in';

  @override
  String get selectHarvestDate => 'Selecteer oogstdatum';

  @override
  String get selectRoastDate => 'Selecteer branddatum';

  @override
  String get selectDate => 'Selecteer datum';

  @override
  String get save => 'Opslaan';

  @override
  String get fillRequiredFields => 'Vul alle verplichte velden in.';

  @override
  String get analyzing => 'Analyseren';

  @override
  String get errorMessage => 'Fout';

  @override
  String get selectCoffeeBeans => 'Selecteer koffiebonen';

  @override
  String get addNewBeans => 'Voeg nieuwe bonen toe';

  @override
  String get favorite => 'Favoriet';

  @override
  String get notFavorite => 'Niet Favoriet';

  @override
  String get myBeans => 'Mijn bonen';

  @override
  String get signIn => 'Aanmelden';

  @override
  String get signOut => 'Afmelden';

  @override
  String get signInWithApple => 'Aanmelden met Apple';

  @override
  String get signInSuccessful => 'Succesvol aangemeld met Apple';

  @override
  String get signInError => 'Fout bij aanmelden met Apple';

  @override
  String get signInWithGoogle => 'Inloggen met Google';

  @override
  String get signOutSuccessful => 'Succesvol afgemeld';

  @override
  String get signInSuccessfulGoogle => 'Succesvol aangemeld met Google';

  @override
  String get signInWithEmail => 'Aanmelden met e-mailadres';

  @override
  String get enterEmail => 'Voer uw e-mailadres in';

  @override
  String get emailHint => 'voorbeeld@email.com';

  @override
  String get cancel => 'Annuleren';

  @override
  String get sendMagicLink => 'Stuur magische link';

  @override
  String get magicLinkSent => 'Magische link verzonden! Controleer uw e-mail.';

  @override
  String get sendOTP => 'Verstuur OTP';

  @override
  String get otpSent => 'OTP verzonden naar uw e-mail';

  @override
  String get otpSendError => 'Fout bij het verzenden van OTP';

  @override
  String get enterOTP => 'Voer OTP in';

  @override
  String get otpHint => 'Voer 6-cijferige code in';

  @override
  String get verify => 'Verifiëren';

  @override
  String get signInSuccessfulEmail => 'Aanmelden geslaagd';

  @override
  String get invalidOTP => 'Ongeldige OTP';

  @override
  String get otpVerificationError => 'Fout bij het verifiëren van OTP';

  @override
  String get success => 'Succes!';

  @override
  String get otpSentMessage =>
      'Een eenmalige toegangscode is naar uw e-mailadres verzonden. Voer de code hieronder in wanneer u deze ontvangt.';

  @override
  String get otpHint2 => 'Voer hier de code in';

  @override
  String get signInCreate => 'Inloggen / Account aanmaken';

  @override
  String get accountManagement => 'Accountbeheer';

  @override
  String get deleteAccount => 'Account verwijderen';

  @override
  String get deleteAccountWarning =>
      'Let op: als u doorgaat, verwijderen we uw account en bijbehorende gegevens van onze servers. De lokale kopie van de gegevens blijft op het apparaat staan. Als u die ook wilt verwijderen, kunt u de app eenvoudig verwijderen. Om synchronisatie opnieuw in te schakelen, moet u een nieuw account aanmaken';

  @override
  String get deleteAccountConfirmation => 'Account succesvol verwijderd';

  @override
  String get accountDeleted => 'Account verwijderd';

  @override
  String get accountDeletionError =>
      'Fout bij het verwijderen van uw account, probeer het opnieuw';

  @override
  String get deleteAccountTitle => 'Belangrijk';

  @override
  String get selectBeans => 'Kies bonen';

  @override
  String get all => 'Alles';

  @override
  String get selectRoaster => 'Selecteer Brander';

  @override
  String get selectOrigin => 'Selecteer Oorsprong';

  @override
  String get resetFilters => 'Filters Resetten';

  @override
  String get showFavoritesOnly => 'Alleen favorieten weergeven';

  @override
  String get apply => 'Toepassen';

  @override
  String get selectSize => 'Grootte selecteren';

  @override
  String get sizeStandard => 'Standaard';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Mijn jaar met Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      'Hé, bedankt dat je dit jaar deel uitmaakte van het Timer.Coffee-universum!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'Allereerst.\nJe hebt dit jaar wat koffie gezet$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'Om precies te zijn,\nje hebt $liters liter koffie gezet in 2024!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'Je hebt bonen van $roasterCount branderijen gebruikt';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Je top 3 branderijen waren:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Koffie nam je mee op reis\nde wereld rond$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'Je hebt koffiebonen geproefd\nuit $originCount landen!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Je was niet alleen aan het brouwen…';

  @override
  String get yearlyStatsStory7Part2 =>
      '...maar met gebruikers uit 110 andere\nlanden verspreid over 6 continenten!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Je bent trouw gebleven aan jezelf en hebt dit jaar alleen deze $count zetmethoden gebruikt:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Je was nieuwe smaken aan het ontdekken en hebt dit jaar $count zetmethoden gebruikt:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'Je was een echte koffieontdekker en hebt dit jaar $count zetmethoden gebruikt:';
  }

  @override
  String get yearlyStatsStory9Text => 'Er valt nog zoveel te ontdekken!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'Je top 3 recepten in 2024 waren$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'Tot ziens in 2025!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Toon wat liefde ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Doneren';

  @override
  String get yearlyStatsActionShare => 'Deel je voortgang';

  @override
  String get yearlyStatsUnknown => 'Onbekend';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Delen mislukt: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Mijn jaar met Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes => 'Mijn top 3 recepten:';

  @override
  String get yearlyStatsShareProgressTop3Roasters => 'Mijn top 3 branders:';

  @override
  String get yearlyStatsFailedToLike =>
      'Kon niet leuk vinden. Probeer het opnieuw.';

  @override
  String get labelCoffeeBrewed => 'Koffie gebrouwen';

  @override
  String get labelTastedBeansBy => 'Geproefde bonen van';

  @override
  String get labelDiscoveredCoffeeFrom => 'Ontdekte koffie uit';

  @override
  String get labelUsedBrewingMethods => 'Gebruikte';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'branders',
      one: 'brander',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'landen',
      one: 'land',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'zetmethoden',
      one: 'zetmethode',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Recept bewerken';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Recept maken';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Receptstappen';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Receptnaam';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Korte beschrijving';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Zetmethode';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Koffiehoeveelheid (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Waterhoeveelheid (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Watertemperatuur (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Maalgraad';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => 'Totale zettijd:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Minuten';

  @override
  String get recipeCreationScreenSecondsLabel => 'Seconden';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Voorbereidingsstap';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Zetstap $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Stapbeschrijving';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Staptijd: ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'Voer een receptnaam in';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Voer een korte beschrijving in';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Selecteer een zetmethode';

  @override
  String get recipeCreationScreenRequiredValidator => 'Verplicht';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Ongeldig nummer';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Voer een stapbeschrijving in';

  @override
  String get recipeCreationScreenContinueButton =>
      'Doorgaan naar receptstappen';

  @override
  String get recipeCreationScreenAddStepButton => 'Stap toevoegen';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Recept opslaan';

  @override
  String get recipeCreationScreenUpdateSuccess => 'Recept succesvol bijgewerkt';

  @override
  String get recipeCreationScreenSaveSuccess => 'Recept succesvol opgeslagen';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Fout bij opslaan recept: $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'gram';

  @override
  String get unitMillilitersLong => 'milliliter';

  @override
  String get recipeCopySuccess => 'Recept succesvol gekopieerd!';

  @override
  String get recipeDuplicateSuccess => 'Recept succesvol gedupliceerd!';

  @override
  String recipeCopyError(String error) {
    return 'Fout bij het kopiëren van het recept: $error';
  }

  @override
  String get createRecipe => 'Recept maken';

  @override
  String errorSyncingData(Object error) {
    return 'Fout bij synchroniseren van gegevens: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Fout bij uitloggen: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Voorbereiding';

  @override
  String get loadingEllipsis => 'Laden...';

  @override
  String get recipeDeletedSuccess => 'Recept succesvol verwijderd';

  @override
  String recipeDeleteError(Object error) {
    return 'Kon recept niet verwijderen: $error';
  }

  @override
  String get noRecipesFound => 'Geen recepten gevonden';

  @override
  String recipeLoadError(Object error) {
    return 'Kon recept niet laden: $error';
  }

  @override
  String get unknownBrewingMethod => 'Onbekende zetmethode';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Kon gekopieerd recept niet laden voor bewerking.';

  @override
  String get recipeCopyErrorOperationFailed => 'Operatie mislukt.';

  @override
  String get notProvided => 'Niet opgegeven';

  @override
  String get recipeUpdateFailedFetch =>
      'Kon bijgewerkte receptgegevens niet ophalen.';

  @override
  String get recipeImportSuccess => 'Recept succesvol geïmporteerd!';

  @override
  String get recipeImportFailedSave => 'Kon geïmporteerd recept niet opslaan.';

  @override
  String get recipeImportFailedFetch =>
      'Kon receptgegevens voor import niet ophalen.';

  @override
  String get recipeNotImported => 'Recept niet geïmporteerd.';

  @override
  String get recipeNotFoundCloud =>
      'Recept niet gevonden in de cloud of is niet openbaar.';

  @override
  String get recipeLoadErrorGeneric => 'Fout bij het laden van het recept.';

  @override
  String get recipeUpdateAvailableTitle => 'Update beschikbaar';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'Er is een nieuwere versie van \'$recipeName\' online beschikbaar. Updaten?';
  }

  @override
  String get dialogCancel => 'Annuleren';

  @override
  String get dialogDuplicate => 'Dupliceren';

  @override
  String get dialogUpdate => 'Update';

  @override
  String get recipeImportTitle => 'Recept importeren';

  @override
  String recipeImportBody(String recipeName) {
    return 'Wil je het recept \'$recipeName\' uit de cloud importeren?';
  }

  @override
  String get dialogImport => 'Importeren';

  @override
  String get moderationReviewNeededTitle => 'Moderatiebeoordeling vereist';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'De volgende recept(en) vereisen beoordeling vanwege problemen met inhoudsmoderatie: $recipeNames';
  }

  @override
  String get dismiss => 'Negeren';

  @override
  String get reviewRecipeButton => 'Recept beoordelen';

  @override
  String get signInRequiredTitle => 'Aanmelden vereist';

  @override
  String get signInRequiredBodyShare =>
      'Je moet je aanmelden om je eigen recepten te delen.';

  @override
  String get syncSuccess => 'Synchronisatie geslaagd!';

  @override
  String get tooltipEditRecipe => 'Recept bewerken';

  @override
  String get tooltipCopyRecipe => 'Recept kopiëren';

  @override
  String get tooltipDuplicateRecipe => 'Recept dupliceren';

  @override
  String get tooltipShareRecipe => 'Recept delen';

  @override
  String get signInRequiredSnackbar => 'Aanmelden vereist';

  @override
  String get moderationErrorFunction =>
      'Controle van inhoudsmoderatie mislukt.';

  @override
  String get moderationReasonDefault => 'Inhoud gemarkeerd voor beoordeling.';

  @override
  String get moderationFailedTitle => 'Moderatie mislukt';

  @override
  String moderationFailedBody(String reason) {
    return 'Dit recept kan niet worden gedeeld omdat: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Fout bij het delen van recept: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName op Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'Kon inhoudsstatus niet controleren. Lokaal opgeslagen, wordt bij volgende synchronisatie gecontroleerd.';

  @override
  String get saveLocallyModerationFailedTitle =>
      'Wijzigingen lokaal opgeslagen';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Je lokale wijzigingen zijn opgeslagen, maar de openbare versie kon niet worden bijgewerkt vanwege inhoudsmoderatie: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Geïmporteerd recept bewerken';

  @override
  String get editImportedRecipeBody =>
      'Dit is een geïmporteerd recept. Bewerken maakt een nieuwe, onafhankelijke kopie. Wilt u doorgaan?';

  @override
  String get editImportedRecipeButtonCopy => 'Kopie maken & bewerken';

  @override
  String get editImportedRecipeButtonCancel => 'Annuleren';

  @override
  String get editDisplayNameTitle => 'Weergavenaam bewerken';

  @override
  String get displayNameHint => 'Voer uw weergavenaam in';

  @override
  String get displayNameEmptyError => 'Weergavenaam mag niet leeg zijn';

  @override
  String get displayNameTooLongError =>
      'Weergavenaam mag niet langer zijn dan 50 tekens';

  @override
  String get errorUserNotLoggedIn => 'Gebruiker niet ingelogd. Log opnieuw in.';

  @override
  String get displayNameUpdateSuccess => 'Weergavenaam succesvol bijgewerkt!';

  @override
  String displayNameUpdateError(String error) {
    return 'Kon weergavenaam niet bijwerken: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Afbeelding verwijderen?';

  @override
  String get deletePictureConfirmationBody =>
      'Weet u zeker dat u uw profielfoto wilt verwijderen?';

  @override
  String get deletePictureSuccess => 'Profielfoto verwijderd.';

  @override
  String deletePictureError(String error) {
    return 'Kon profielfoto niet verwijderen: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Kon profielfoto niet bijwerken: $error';
  }

  @override
  String get updatePictureSuccess => 'Profielfoto succesvol bijgewerkt!';

  @override
  String get deletePictureTooltip => 'Afbeelding verwijderen';

  @override
  String get account => 'Account';

  @override
  String get settingsBrewingMethodsTitle => 'Zetmethoden op het startscherm';

  @override
  String get filter => 'Filteren';

  @override
  String get sortBy => 'Sorteren op';

  @override
  String get dateAdded => 'Datum toegevoegd';

  @override
  String get secondsAbbreviation => 's';

  @override
  String get settingsAppIcon => 'App-Icon';

  @override
  String get settingsAppIconDefault => 'Standaard';

  @override
  String get settingsAppIconLegacy => 'Oud';

  @override
  String get searchBeans => 'Zoek bonen...';

  @override
  String get favorites => 'Favorieten';

  @override
  String get searchPrefix => 'Zoeken: ';

  @override
  String get clearAll => 'Alles wissen';

  @override
  String get noBeansMatchSearch =>
      'Geen bonen komen overeen met je zoekopdracht';

  @override
  String get clearFilters => 'Filters wissen';

  @override
  String get farmer => 'Boer';

  @override
  String get farm => 'Koffieboerderij';

  @override
  String get enterFarmer => 'Boer invoeren (optioneel)';

  @override
  String get enterFarm => 'Koffieboerderij invoeren (optioneel)';

  @override
  String get requiredInformation => 'Vereiste informatie';

  @override
  String get basicDetails => 'Basisgegevens';

  @override
  String get qualityMeasurements => 'Kwaliteit en metingen';

  @override
  String get importantDates => 'Belangrijke data';

  @override
  String get brewStats => 'Brouwstatistieken';

  @override
  String get showMore => 'Meer weergeven';

  @override
  String get showLess => 'Minder weergeven';

  @override
  String get unpublishRecipeDialogTitle => 'Recept privé maken';

  @override
  String get unpublishRecipeDialogMessage =>
      'Waarschuwing: Als u dit recept privé maakt, gebeurt het volgende:';

  @override
  String get unpublishRecipeDialogBullet1 =>
      'Het wordt verwijderd uit de openbare zoekresultaten';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'Nieuwe gebruikers kunnen het niet meer importeren';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'Gebruikers die het al hebben geïmporteerd, behouden hun kopieën';

  @override
  String get unpublishRecipeDialogKeepPublic => 'Openbaar houden';

  @override
  String get unpublishRecipeDialogMakePrivate => 'Privé maken';

  @override
  String get recipeUnpublishSuccess =>
      'Publicatie van recept succesvol ingetrokken';

  @override
  String recipeUnpublishError(String error) {
    return 'Fout bij het intrekken van de publicatie van het recept: $error';
  }

  @override
  String get recipePublicTooltip =>
      'Recept is openbaar - tik om privé te maken';

  @override
  String get recipePrivateTooltip =>
      'Recept is privé - deel om openbaar te maken';

  @override
  String get fieldClearButtonTooltip => 'Wissen';

  @override
  String get dateFieldClearButtonTooltip => 'Datum wissen';

  @override
  String get chipInputDuplicateError => 'Deze tag is al toegevoegd';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return 'Maximum aantal tags bereikt ($maxChips)';
  }

  @override
  String get chipInputHintText => 'Voeg een tag toe...';

  @override
  String get unitFieldRequiredError => 'Dit veld is verplicht';

  @override
  String get unitFieldInvalidNumberError => 'Voer een geldig nummer in';

  @override
  String unitFieldMinValueError(Object min) {
    return 'Waarde moet minimaal $min zijn';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return 'Waarde mag maximaal $max zijn';
  }

  @override
  String get numericFieldRequiredError => 'Dit veld is verplicht';

  @override
  String get numericFieldInvalidNumberError => 'Voer een geldig nummer in';

  @override
  String numericFieldMinValueError(Object min) {
    return 'Waarde moet minimaal $min zijn';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return 'Waarde mag maximaal $max zijn';
  }

  @override
  String get dropdownSearchHintText => 'Typ om te zoeken...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return 'Fout bij het laden van suggesties: $error';
  }

  @override
  String get dropdownSearchNoResults => 'Geen resultaten gevonden';

  @override
  String get dropdownSearchLoading => 'Zoeken...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return 'Gebruik \"$currentQuery\"';
  }

  @override
  String get requiredInfoSubtitle => '* Verplicht';

  @override
  String get inventoryWeightExample => 'bijv. 250.5';

  @override
  String get unsavedChangesTitle => 'Niet opgeslagen wijzigingen';

  @override
  String get unsavedChangesMessage =>
      'U hebt niet-opgeslagen wijzigingen. Weet u zeker dat u ze wilt verwijderen?';

  @override
  String get unsavedChangesStay => 'Blijven';

  @override
  String get unsavedChangesDiscard => 'Verwerpen';

  @override
  String beansWeightAddedBack(
      String amount, String beanName, String newWeight, String unit) {
    return '$amount$unit terug toegevoegd aan $beanName. Nieuw gewicht: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
      String amount, String beanName, String newWeight, String unit) {
    return '$amount$unit afgetrokken van $beanName. Nieuw gewicht: $newWeight$unit';
  }
}
