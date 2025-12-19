// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'Bohnenstatistiken';

  @override
  String get totalBeansBrewedLabel => 'Insgesamt aufgebrühte Bohnen';

  @override
  String get newBeansTriedLabel => 'Neue Bohnen ausprobiert';

  @override
  String get originsExploredLabel => 'Erkundete Herkünfte';

  @override
  String get regionsExploredLabel => 'Europa';

  @override
  String get newRoastersDiscoveredLabel => 'Neue Röstereien entdeckt';

  @override
  String get favoriteRoastersLabel => 'Lieblingsröstereien';

  @override
  String get topOriginsLabel => 'Top-Herkünfte';

  @override
  String get topRegionsLabel => 'Top-Regionen';

  @override
  String get lastrecipe => 'Zuletzt verwendete Rezept:';

  @override
  String get userRecipesTitle => 'Deine Rezepte';

  @override
  String get userRecipesSectionCreated => 'Von dir erstellt';

  @override
  String get userRecipesSectionImported => 'Von dir importiert';

  @override
  String get userRecipesEmpty => 'Keine Rezepte gefunden';

  @override
  String get userRecipesDeleteTitle => 'Rezept löschen?';

  @override
  String get userRecipesDeleteMessage =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get userRecipesDeleteConfirm => 'Löschen';

  @override
  String get userRecipesDeleteCancel => 'Abbrechen';

  @override
  String get userRecipesSnackbarDeleted => 'Rezept gelöscht';

  @override
  String get hubUserRecipesTitle => 'Deine Rezepte';

  @override
  String get hubUserRecipesSubtitle =>
      'Erstelle und importierte Rezepte anzeigen und verwalten';

  @override
  String get hubAccountSubtitle => 'Verwalte dein Profil';

  @override
  String get hubSignInCreateSubtitle =>
      'Melde dich an, um Rezepte und Einstellungen zu synchronisieren';

  @override
  String get hubBrewDiarySubtitle =>
      'Sieh dir deine Brühhistorie an und füge Notizen hinzu';

  @override
  String get hubBrewStatsSubtitle =>
      'Persönliche und globale Brühstatistiken und Trends ansehen';

  @override
  String get hubSettingsSubtitle => 'Ändere App-Einstellungen und Verhalten';

  @override
  String get hubAboutSubtitle => 'App-Details, Version und Mitwirkende';

  @override
  String get about => 'Über';

  @override
  String get author => 'Autor';

  @override
  String get authortext =>
      'Die Timer.Coffee App wurde von Anton Karliner erstellt, einem Kaffee-Enthusiasten, Medienspezialisten und Fotojournalisten. Ich hoffe, dass diese App Ihnen hilft, Ihren Kaffee zu genießen. Fühlen Sie sich frei, auf GitHub beizutragen.';

  @override
  String get contributors => 'Mitwirkende';

  @override
  String get errorLoadingContributors => 'Fehler beim Laden der Mitwirkenden';

  @override
  String get license => 'Lizenz';

  @override
  String get licensetext =>
      'Diese Anwendung ist freie Software: Sie können sie unter den Bedingungen der GNU General Public License weiterverbreiten und/oder modifizieren, wie sie von der Free Software Foundation veröffentlicht wurde, entweder Version 3 der Lizenz oder (nach Ihrer Wahl) jede spätere Version.';

  @override
  String get licensebutton => 'Lesen Sie die GNU General Public License v3';

  @override
  String get website => 'Webseite';

  @override
  String get sourcecode => 'Quellcode';

  @override
  String get support => 'Kaufe dem Entwickler einen Kaffee';

  @override
  String get allrecipes => 'Alle Rezepte';

  @override
  String get favoriterecipes => 'Lieblingsrezepte';

  @override
  String get coffeeamount => 'Kaffeemenge (g)';

  @override
  String get wateramount => 'Wassermenge (ml)';

  @override
  String get watertemp => 'Wassertemperatur';

  @override
  String get grindsize => 'Mahlgrad';

  @override
  String get brewtime => 'Brühzeit';

  @override
  String get recipesummary => 'Rezeptzusammenfassung';

  @override
  String get recipesummarynote =>
      'Hinweis: Dies ist ein Grundrezept mit Standardmengen für Wasser und Kaffee.';

  @override
  String get preparation => 'Vorbereitung';

  @override
  String get brewingprocess => 'Brühvorgang';

  @override
  String get step => 'Schritt';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sekunden',
      one: 'Sekunde',
      zero: 'Sekunden',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg =>
      'Danke, dass Sie Timer.Coffee verwenden! Genießen Sie Ihren';

  @override
  String get coffeefact => 'Kaffee-Fakt';

  @override
  String get home => 'Startseite';

  @override
  String get appversion => 'App-Version';

  @override
  String get tipsmall => 'Kaufe einen kleinen Kaffee';

  @override
  String get tipmedium => 'Kaufe einen mittleren Kaffee';

  @override
  String get tiplarge => 'Kaufe einen großen Kaffee';

  @override
  String get supportdevelopment => 'Die Entwicklung unterstützen';

  @override
  String get supportdevmsg =>
      'Ihre Spenden helfen, die Wartungskosten zu decken (wie zum Beispiel Entwicklerlizenzen). Sie ermöglichen es mir auch, mehr Kaffeebrühgeräte auszuprobieren und mehr Rezepte zur App hinzuzufügen.';

  @override
  String get supportdevtnx => 'Danke, dass Sie in Erwägung ziehen zu spenden!';

  @override
  String get donationok => 'Danke!';

  @override
  String get donationtnx =>
      'Ich schätze Ihre Unterstützung sehr! Ich wünsche Ihnen viele großartige Brühungen! ☕️';

  @override
  String get donationerr => 'Fehler';

  @override
  String get donationerrmsg =>
      'Fehler bei der Verarbeitung des Kaufs, bitte versuchen Sie es erneut.';

  @override
  String get sharemsg => 'Schauen Sie sich dieses Rezept an:';

  @override
  String get finishbrew => 'Fertig';

  @override
  String get settings => 'Einstellungen';

  @override
  String get settingstheme => 'Thema';

  @override
  String get settingsthemelight => 'Hell';

  @override
  String get settingsthemedark => 'Dunkel';

  @override
  String get settingsthemesystem => 'System';

  @override
  String get settingslang => 'Sprache';

  @override
  String get sweet => 'Süß';

  @override
  String get balance => 'Balance';

  @override
  String get acidic => 'Sauer';

  @override
  String get light => 'Leicht';

  @override
  String get strong => 'Stark';

  @override
  String get slidertitle =>
      'Verwenden Sie Schieberegler, um den Geschmack anzupassen';

  @override
  String get whatsnewtitle => 'Was gibt\'s Neues';

  @override
  String get whatsnewclose => 'Schließen';

  @override
  String get seasonspecials => 'Saison-Spezialitäten';

  @override
  String get snow => 'Schnee';

  @override
  String get noFavoriteRecipesMessage =>
      'Deine Liste der Lieblingsrezepte ist derzeit leer. Beginne zu erkunden und zu brauen, um deine Favoriten zu entdecken!';

  @override
  String get explore => 'Neues Entdecken';

  @override
  String get dateFormat => 'd. MMM yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Brautagebuch';

  @override
  String get brewdiarynotfound => 'Keine Einträge gefunden';

  @override
  String get beans => 'Bohnen';

  @override
  String get roaster => 'Rösterei';

  @override
  String get rating => 'Bewertung';

  @override
  String get notes => 'Notizen';

  @override
  String get statsscreen => 'Kaffee-Statistik';

  @override
  String get yourStats => 'Ihre Statistiken';

  @override
  String get coffeeBrewed => 'Gekochter Kaffee:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'Meistgenutzte Rezepte:';

  @override
  String get globalStats => 'Globale Statistiken';

  @override
  String get unknownRecipe => 'Unbekanntes Rezept';

  @override
  String get noData => 'Keine Daten';

  @override
  String error(String error) {
    return 'Fehler: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Jemand hat gerade $recipeName gebrüht';
  }

  @override
  String get timePeriodToday => 'Heute';

  @override
  String get timePeriodThisWeek => 'Diese Woche';

  @override
  String get timePeriodThisMonth => 'Diesen Monat';

  @override
  String get timePeriodCustom => 'Benutzerdefiniert';

  @override
  String get statsFor => 'Statistiken für ';

  @override
  String get homescreenbrewcoffee => 'Kaffee brühen';

  @override
  String get homescreenhub => 'Hub';

  @override
  String get homescreenmore => 'Mehr';

  @override
  String get addBeans => 'Bohnen hinzufügen';

  @override
  String get removeBeans => 'Bohnen entfernen';

  @override
  String get name => 'Name';

  @override
  String get origin => 'Ursprung';

  @override
  String get details => 'Details';

  @override
  String get coffeebeans => 'Kaffeebohnen';

  @override
  String get loading => 'Laden...';

  @override
  String get nocoffeebeans => 'Keine Kaffeebohnen gefunden';

  @override
  String get delete => 'Löschen';

  @override
  String get confirmDeleteTitle => 'Eintrag löschen?';

  @override
  String get recipeDuplicateConfirmTitle => 'Rezept duplizieren?';

  @override
  String get recipeDuplicateConfirmMessage =>
      'Dies wird eine Kopie Ihres Rezepts erstellen, die Sie unabhängig bearbeiten können. Möchten Sie fortfahren?';

  @override
  String get confirmDeleteMessage =>
      'Möchten Sie diesen Eintrag wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get removeFavorite => 'Aus Favoriten entfernen';

  @override
  String get addFavorite => 'Zu Favoriten hinzufügen';

  @override
  String get toggleEditMode => 'Bearbeitungsmodus umschalten';

  @override
  String get coffeeBeansDetails => 'Details zu den Kaffeebohnen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get coffeeBeansNotFound => 'Kaffeebohnen nicht gefunden';

  @override
  String get basicInformation => 'Grunddaten';

  @override
  String get geographyTerroir => 'Geographie/Terroir';

  @override
  String get variety => 'Varietät';

  @override
  String get region => 'Nordamerika';

  @override
  String get elevation => 'Höhe';

  @override
  String get harvestDate => 'Erntedatum';

  @override
  String get processing => 'Verarbeitung';

  @override
  String get processingMethod => 'Verarbeitungsmethode';

  @override
  String get roastDate => 'Röstdatum';

  @override
  String get roastLevel => 'Röstgrad';

  @override
  String get cuppingScore => 'Cupping-Punktzahl';

  @override
  String get flavorProfile => 'Geschmacksprofil';

  @override
  String get tastingNotes => 'Geschmacksnoten';

  @override
  String get additionalNotes => 'Zusätzliche Hinweise';

  @override
  String get noCoffeeBeans => 'Keine Kaffeebohnen gefunden';

  @override
  String get editCoffeeBeans => 'Kaffeebohnen bearbeiten';

  @override
  String get addCoffeeBeans => 'Kaffeebohnen hinzufügen';

  @override
  String get showImagePicker => 'Bildauswahl anzeigen';

  @override
  String get pleaseNote => 'Bitte beachten Sie';

  @override
  String get firstTimePopupMessage =>
      '1. Wir verwenden externe Dienste zur Verarbeitung von Bildern. Mit der weiteren Nutzung stimmen Sie dem zu.\n2. Obwohl wir Ihre Bilder nicht speichern, vermeiden Sie bitte die Angabe persönlicher Daten.\n3. Die Bilderkennung ist derzeit auf 10 Token pro Monat begrenzt (1 Token = 1 Bild). Dieses Limit kann sich in Zukunft ändern.';

  @override
  String get ok => 'OK';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get selectFromPhotos => 'Aus Fotos auswählen';

  @override
  String get takeAdditionalPhoto => 'Weiteres Foto aufnehmen?';

  @override
  String get no => 'Nein';

  @override
  String get yes => 'Ja';

  @override
  String get selectedImages => 'Ausgewählte Bilder';

  @override
  String get selectedImage => 'Ausgewähltes Bild';

  @override
  String get backToSelection => 'Zurück zur Auswahl';

  @override
  String get next => 'Weiter';

  @override
  String get unexpectedErrorOccurred =>
      'Ein unerwarteter Fehler ist aufgetreten';

  @override
  String get tokenLimitReached =>
      'Sie haben Ihr Token-Limit für die Bilderkennung in diesem Monat erreicht.';

  @override
  String get noCoffeeLabelsDetected =>
      'Keine Kaffeeetiketten erkannt. Versuchen Sie es mit einem anderen Bild.';

  @override
  String get collectedInformation => 'Gesammelte Informationen';

  @override
  String get enterRoaster => 'Rösterei eingeben';

  @override
  String get enterName => 'Name eingeben';

  @override
  String get enterOrigin => 'Herkunft eingeben';

  @override
  String get optional => 'Optional';

  @override
  String get enterVariety => 'Sorte eingeben';

  @override
  String get enterProcessingMethod => 'Verarbeitungsmethode eingeben';

  @override
  String get enterRoastLevel => 'Röstgrad eingeben';

  @override
  String get enterRegion => 'Region eingeben';

  @override
  String get enterTastingNotes => 'Geschmacksnoten eingeben';

  @override
  String get enterElevation => 'Höhe eingeben';

  @override
  String get enterCuppingScore => 'Cupping-Punktzahl eingeben';

  @override
  String get enterNotes => 'Notizen eingeben';

  @override
  String get inventory => 'Bestand';

  @override
  String get amountLeft => 'Restmenge';

  @override
  String get enterAmountLeft => 'Restmenge eingeben';

  @override
  String get selectHarvestDate => 'Erntedatum auswählen';

  @override
  String get selectRoastDate => 'Röstdatum auswählen';

  @override
  String get selectDate => 'Datum auswählen';

  @override
  String get save => 'Speichern';

  @override
  String get fillRequiredFields =>
      'Bitte füllen Sie alle erforderlichen Felder aus.';

  @override
  String get analyzing => 'Analysieren...';

  @override
  String get errorMessage => 'Fehler';

  @override
  String get selectCoffeeBeans => 'Kaffeebohnen auswählen';

  @override
  String get addNewBeans => 'Neue Bohnen hinzufügen';

  @override
  String get favorite => 'Favorit';

  @override
  String get notFavorite => 'Kein Favorit';

  @override
  String get myBeans => 'Meine Bohnen';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signOut => 'Abmelden';

  @override
  String get signInWithApple => 'Mit Apple anmelden';

  @override
  String get signInSuccessful => 'Anmeldung mit Apple erfolgreich';

  @override
  String get signInError => 'Fehler beim Anmelden mit Apple';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get signOutSuccessful => 'Erfolgreich ausgeloggt';

  @override
  String get signInSuccessfulGoogle => 'Erfolgreich mit Google angemeldet';

  @override
  String get signInWithEmail => 'Mit E-Mail anmelden';

  @override
  String get enterEmail => 'E-Mail eingeben';

  @override
  String get emailHint => 'beispiel@email.de';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get sendMagicLink => 'Magischen Link senden';

  @override
  String get magicLinkSent =>
      'Magischer Link gesendet! Überprüfe deinen Posteingang.';

  @override
  String get sendOTP => 'OTP senden';

  @override
  String get otpSent => 'Der OTP-Code wurde an Ihre E-Mail-Adresse gesendet';

  @override
  String get otpSendError => 'Fehler beim Senden des OTP';

  @override
  String get enterOTP => 'OTP-Code eingeben';

  @override
  String get otpHint => 'Geben Sie den 6-stelligen Code ein';

  @override
  String get verify => 'Überprüfen';

  @override
  String get signInSuccessfulEmail => 'Anmeldung erfolgreich';

  @override
  String get invalidOTP => 'Ungültiger OTP-Code';

  @override
  String get otpVerificationError => 'Fehler bei der OTP-Verifizierung';

  @override
  String get success => '!Erfolg';

  @override
  String get otpSentMessage =>
      'Ein OTP wird an Ihre E-Mail gesendet. Bitte geben Sie es unten ein, wenn Sie es erhalten.';

  @override
  String get otpHint2 => 'Code hier eingeben';

  @override
  String get signInCreate => 'Anmelden / Konto erstellen';

  @override
  String get accountManagement => 'Kontoverwaltung';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountWarning =>
      'Bitte beachten Sie: Wenn Sie fortfahren, werden wir Ihr Konto und die zugehörigen Daten von unseren Servern löschen. Die lokale Kopie der Daten verbleibt auf dem Gerät. Wenn Sie diese ebenfalls löschen möchten, können Sie einfach die App deinstallieren. Um die Synchronisation wieder zu aktivieren, müssen Sie ein neues Konto erstellen.';

  @override
  String get deleteAccountConfirmation => 'Konto erfolgreich gelöscht';

  @override
  String get accountDeleted => 'Konto gelöscht';

  @override
  String get accountDeletionError =>
      'Fehler beim Löschen Ihres Kontos, bitte versuchen Sie es erneut';

  @override
  String get deleteAccountTitle => 'Wichtig';

  @override
  String get selectBeans => 'Wähle Bohnen';

  @override
  String get all => 'Alle';

  @override
  String get selectRoaster => 'Wähle Rösterei';

  @override
  String get selectOrigin => 'Wähle Ursprung';

  @override
  String get resetFilters => 'Filter zurücksetzen';

  @override
  String get showFavoritesOnly => 'Nur Favoriten anzeigen';

  @override
  String get apply => 'Anwenden';

  @override
  String get selectSize => 'Größe auswählen';

  @override
  String get sizeStandard => 'Standard';

  @override
  String get sizeMedium => 'Mittel';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Mein Jahr mit Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      'Hey, danke, dass du dieses Jahr Teil des Timer.Coffee-Universums bist!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'Das Wichtigste zuerst.\nDu hast dieses Jahr Kaffee gebrüht$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'Genauer gesagt,\ndu hast 2024 $liters Liter Kaffee gebrüht!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'Du hast Bohnen von $roasterCount Röstern verwendet';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Deine Top 3 Röster waren:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Kaffee hat dich auf eine Reise\num die Welt mitgenommen$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'Du hast Kaffeebohnen\naus $originCount Ländern probiert!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Du warst nicht allein beim Brühen...';

  @override
  String get yearlyStatsStory7Part2 =>
      '...sondern mit Nutzern aus 110 anderen\nLändern auf 6 Kontinenten!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Du bist dir treu geblieben und hast dieses Jahr nur diese $count Brühmethoden verwendet:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Du hast neue Geschmäcker entdeckt und dieses Jahr $count Brühmethoden verwendet:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'Du warst ein echter Kaffee-Entdecker und hast dieses Jahr $count Brühmethoden verwendet:';
  }

  @override
  String get yearlyStatsStory9Text => 'Es gibt noch so viel zu entdecken!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'Deine Top-3-Rezepte im Jahr 2024 waren$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'Wir sehen uns 2025!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Liebe zeigen ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Spenden';

  @override
  String get yearlyStatsActionShare => 'Teile deinen Fortschritt';

  @override
  String get yearlyStatsUnknown => 'Unbekannt';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Fehler beim Teilen: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Mein Jahr mit Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes => 'Meine Top-3-Rezepte:';

  @override
  String get yearlyStatsShareProgressTop3Roasters => 'Meine Top-3-Röster:';

  @override
  String get yearlyStatsFailedToLike =>
      'Fehler beim Liken. Bitte versuche es erneut.';

  @override
  String get labelCoffeeBrewed => 'Kaffee gebrüht';

  @override
  String get labelTastedBeansBy => 'Bohnen von';

  @override
  String get labelDiscoveredCoffeeFrom => 'Kaffee aus';

  @override
  String get labelUsedBrewingMethods => 'Verwendet';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Röster',
      one: 'Röster',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Länder',
      one: 'Land',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Brühmethoden',
      one: 'Brühmethode',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Rezept bearbeiten';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Rezept erstellen';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Rezeptschritte';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Rezeptname';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Kurzbeschreibung';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Brühmethode';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Kaffeemenge (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Wassermenge (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Wassertemperatur (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Mahlgrad';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => 'Gesamte Brühzeit:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Minuten';

  @override
  String get recipeCreationScreenSecondsLabel => 'Sekunden';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Vorbereitungsschritt';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Brühschritt $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Schrittbeschreibung';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Schrittzeit: ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'Bitte geben Sie einen Rezeptnamen ein';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Bitte geben Sie eine Kurzbeschreibung ein';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Bitte wählen Sie eine Brühmethode';

  @override
  String get recipeCreationScreenRequiredValidator => 'Erforderlich';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Ungültige Nummer';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Bitte geben Sie eine Schrittbeschreibung ein';

  @override
  String get recipeCreationScreenContinueButton =>
      'Weiter zu den Rezeptschritten';

  @override
  String get recipeCreationScreenAddStepButton => 'Schritt hinzufügen';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Rezept speichern';

  @override
  String get recipeCreationScreenUpdateSuccess =>
      'Rezept erfolgreich aktualisiert';

  @override
  String get recipeCreationScreenSaveSuccess =>
      'Rezept erfolgreich gespeichert';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Fehler beim Speichern des Rezepts: $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'Gramm';

  @override
  String get unitMillilitersLong => 'Milliliter';

  @override
  String get recipeCopySuccess => 'Rezept erfolgreich kopiert!';

  @override
  String get recipeDuplicateSuccess => 'Rezept erfolgreich dupliziert!';

  @override
  String recipeCopyError(String error) {
    return 'Fehler beim Kopieren des Rezepts: $error';
  }

  @override
  String get createRecipe => 'Rezept erstellen';

  @override
  String errorSyncingData(Object error) {
    return 'Fehler beim Synchronisieren der Daten: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Fehler beim Abmelden: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Vorbereitung';

  @override
  String get loadingEllipsis => 'Laden...';

  @override
  String get recipeDeletedSuccess => 'Rezept erfolgreich gelöscht';

  @override
  String recipeDeleteError(Object error) {
    return 'Fehler beim Löschen des Rezepts: $error';
  }

  @override
  String get noRecipesFound => 'Keine Rezepte gefunden';

  @override
  String recipeLoadError(Object error) {
    return 'Fehler beim Laden des Rezepts: $error';
  }

  @override
  String get unknownBrewingMethod => 'Unbekannte Brühmethode';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Fehler beim Laden des kopierten Rezepts zur Bearbeitung.';

  @override
  String get recipeCopyErrorOperationFailed => 'Operation fehlgeschlagen.';

  @override
  String get notProvided => 'Nicht angegeben';

  @override
  String get recipeUpdateFailedFetch =>
      'Fehler beim Abrufen aktualisierter Rezeptdaten.';

  @override
  String get recipeImportSuccess => 'Rezept erfolgreich importiert!';

  @override
  String get recipeImportFailedSave =>
      'Fehler beim Speichern des importierten Rezepts.';

  @override
  String get recipeImportFailedFetch =>
      'Fehler beim Abrufen der Rezeptdaten für den Import.';

  @override
  String get recipeNotImported => 'Rezept nicht importiert.';

  @override
  String get recipeNotFoundCloud =>
      'Rezept nicht in der Cloud gefunden oder nicht öffentlich.';

  @override
  String get recipeLoadErrorGeneric => 'Fehler beim Laden des Rezepts.';

  @override
  String get recipeUpdateAvailableTitle => 'Update verfügbar';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'Eine neuere Version von \'$recipeName\' ist online verfügbar. Aktualisieren?';
  }

  @override
  String get dialogCancel => 'Abbrechen';

  @override
  String get dialogDuplicate => 'Duplizieren';

  @override
  String get dialogUpdate => 'Aktualisieren';

  @override
  String get recipeImportTitle => 'Rezept importieren';

  @override
  String recipeImportBody(String recipeName) {
    return 'Möchten Sie das Rezept \'$recipeName\' aus der Cloud importieren?';
  }

  @override
  String get dialogImport => 'Importieren';

  @override
  String get moderationReviewNeededTitle => 'Moderationsprüfung erforderlich';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'Die folgenden Rezepte erfordern eine Überprüfung aufgrund von Problemen mit der Inhaltsmoderation: $recipeNames';
  }

  @override
  String get dismiss => 'Verwerfen';

  @override
  String get reviewRecipeButton => 'Rezept überprüfen';

  @override
  String get signInRequiredTitle => 'Anmeldung erforderlich';

  @override
  String get signInRequiredBodyShare =>
      'Sie müssen sich anmelden, um Ihre eigenen Rezepte zu teilen.';

  @override
  String get syncSuccess => 'Synchronisierung erfolgreich!';

  @override
  String get tooltipEditRecipe => 'Rezept bearbeiten';

  @override
  String get tooltipCopyRecipe => 'Rezept kopieren';

  @override
  String get tooltipDuplicateRecipe => 'Rezept duplizieren';

  @override
  String get tooltipShareRecipe => 'Rezept teilen';

  @override
  String get signInRequiredSnackbar => 'Anmeldung erforderlich';

  @override
  String get moderationErrorFunction =>
      'Überprüfung der Inhaltsmoderation fehlgeschlagen.';

  @override
  String get moderationReasonDefault => 'Inhalt zur Überprüfung markiert.';

  @override
  String get moderationFailedTitle => 'Moderation fehlgeschlagen';

  @override
  String moderationFailedBody(String reason) {
    return 'Dieses Rezept kann nicht geteilt werden, weil: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Fehler beim Teilen des Rezepts: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName auf Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'Inhaltsstatus konnte nicht überprüft werden. Lokal gespeichert, wird bei der nächsten Synchronisierung überprüft.';

  @override
  String get saveLocallyModerationFailedTitle => 'Änderungen lokal gespeichert';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Ihre lokalen Änderungen wurden gespeichert, aber die öffentliche Version konnte aufgrund der Inhaltsmoderation nicht aktualisiert werden: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Importiertes Rezept bearbeiten';

  @override
  String get editImportedRecipeBody =>
      'Dies ist ein importiertes Rezept. Durch die Bearbeitung wird eine neue, unabhängige Kopie erstellt. Möchten Sie fortfahren?';

  @override
  String get editImportedRecipeButtonCopy => 'Kopie erstellen & bearbeiten';

  @override
  String get editImportedRecipeButtonCancel => 'Abbrechen';

  @override
  String get editDisplayNameTitle => 'Anzeigename bearbeiten';

  @override
  String get displayNameHint => 'Geben Sie Ihren Anzeigenamen ein';

  @override
  String get displayNameEmptyError => 'Anzeigename darf nicht leer sein';

  @override
  String get displayNameTooLongError =>
      'Anzeigename darf 50 Zeichen nicht überschreiten';

  @override
  String get errorUserNotLoggedIn =>
      'Benutzer nicht angemeldet. Bitte erneut anmelden.';

  @override
  String get displayNameUpdateSuccess =>
      'Anzeigename erfolgreich aktualisiert!';

  @override
  String displayNameUpdateError(String error) {
    return 'Fehler beim Aktualisieren des Anzeigenamens: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Bild löschen?';

  @override
  String get deletePictureConfirmationBody =>
      'Sind Sie sicher, dass Sie Ihr Profilbild löschen möchten?';

  @override
  String get deletePictureSuccess => 'Profilbild gelöscht.';

  @override
  String deletePictureError(String error) {
    return 'Fehler beim Löschen des Profilbilds: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Fehler beim Aktualisieren des Profilbilds: $error';
  }

  @override
  String get updatePictureSuccess => 'Profilbild erfolgreich aktualisiert!';

  @override
  String get deletePictureTooltip => 'Bild löschen';

  @override
  String get account => 'Konto';

  @override
  String get settingsBrewingMethodsTitle => 'Startbildschirm Brühmethoden';

  @override
  String get filter => 'Filter';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get dateAdded => 'Datum hinzugefügt';

  @override
  String get secondsAbbreviation => 's';

  @override
  String get settingsAppIcon => 'App-Icon';

  @override
  String get settingsAppIconDefault => 'Standard';

  @override
  String get settingsAppIconLegacy => 'Alt';

  @override
  String get searchBeans => 'Bohnen suchen...';

  @override
  String get favorites => 'Favoriten';

  @override
  String get searchPrefix => 'Suche: ';

  @override
  String get clearAll => 'Alle löschen';

  @override
  String get noBeansMatchSearch => 'Keine Bohnen entsprechen Ihrer Suche';

  @override
  String get clearFilters => 'Filter löschen';

  @override
  String get farmer => 'Landwirt';

  @override
  String get farm => 'Kaffeeplantage';

  @override
  String get enterFarmer => 'Landwirt eingeben (optional)';

  @override
  String get enterFarm => 'Kaffeeplantage eingeben (optional)';

  @override
  String get requiredInformation => 'Erforderliche Informationen';

  @override
  String get basicDetails => 'Grundlegende Details';

  @override
  String get qualityMeasurements => 'Qualität der Messungen';

  @override
  String get importantDates => 'Wichtige Daten';

  @override
  String get brewStats => 'Brühstatistiken';

  @override
  String get showMore => 'Mehr anzeigen';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get unpublishRecipeDialogTitle => 'Rezept als privat markieren';

  @override
  String get unpublishRecipeDialogMessage =>
      'Warnung: Wenn Sie dieses Rezept als privat markieren, wird Folgendes bewirkt:';

  @override
  String get unpublishRecipeDialogBullet1 =>
      'Es wird aus den öffentlichen Suchergebnissen entfernt';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'Neue Benutzer können es nicht mehr importieren';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'Benutzer, die es bereits importiert haben, behalten ihre Kopien';

  @override
  String get unpublishRecipeDialogKeepPublic => 'Öffentlich lassen';

  @override
  String get unpublishRecipeDialogMakePrivate => 'Als privat markieren';

  @override
  String get recipeUnpublishSuccess =>
      'Rezeptveröffentlichung erfolgreich aufgehoben';

  @override
  String recipeUnpublishError(String error) {
    return 'Fehler beim Aufheben der Veröffentlichung des Rezepts: $error';
  }

  @override
  String get recipePublicTooltip =>
      'Rezept ist öffentlich - tippen, um es privat zu machen';

  @override
  String get recipePrivateTooltip =>
      'Rezept ist privat - teilen, um es öffentlich zu machen';

  @override
  String get fieldClearButtonTooltip => 'Löschen';

  @override
  String get dateFieldClearButtonTooltip => 'Datum löschen';

  @override
  String get chipInputDuplicateError => 'Dieses Tag wurde bereits hinzugefügt';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return 'Maximale Anzahl an Tags erreicht ($maxChips)';
  }

  @override
  String get chipInputHintText => 'Tag hinzufügen...';

  @override
  String get unitFieldRequiredError => 'Dieses Feld ist erforderlich';

  @override
  String get unitFieldInvalidNumberError =>
      'Bitte geben Sie eine gültige Zahl ein';

  @override
  String unitFieldMinValueError(Object min) {
    return 'Wert muss mindestens $min sein';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return 'Wert darf höchstens $max sein';
  }

  @override
  String get numericFieldRequiredError => 'Dieses Feld ist erforderlich';

  @override
  String get numericFieldInvalidNumberError =>
      'Bitte geben Sie eine gültige Zahl ein';

  @override
  String numericFieldMinValueError(Object min) {
    return 'Wert muss mindestens $min sein';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return 'Wert darf höchstens $max sein';
  }

  @override
  String get dropdownSearchHintText => 'Tippen zum Suchen...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return 'Fehler beim Laden der Vorschläge: $error';
  }

  @override
  String get dropdownSearchNoResults => 'Keine Ergebnisse gefunden';

  @override
  String get dropdownSearchLoading => 'Suche...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return '\"$currentQuery\" verwenden';
  }

  @override
  String get requiredInfoSubtitle => '* Erforderlich';

  @override
  String get inventoryWeightExample => 'z.B. 250.5';

  @override
  String get unsavedChangesTitle => 'Nicht gespeicherte Änderungen';

  @override
  String get unsavedChangesMessage =>
      'Sie haben nicht gespeicherte Änderungen. Sind Sie sicher, dass Sie sie verwerfen möchten?';

  @override
  String get unsavedChangesStay => 'Bleiben';

  @override
  String get unsavedChangesDiscard => 'Verwerfen';

  @override
  String beansWeightAddedBack(
      String amount, String beanName, String newWeight, String unit) {
    return '$amount$unit zurück zu $beanName hinzugefügt. Neues Gewicht: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
      String amount, String beanName, String newWeight, String unit) {
    return '$amount$unit von $beanName abgezogen. Neues Gewicht: $newWeight$unit';
  }

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get notificationsDisabledInSystemSettings =>
      'In Systemeinstellungen deaktiviert';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get couldNotOpenLink => 'Link konnte nicht geöffnet werden';

  @override
  String get notificationsDisabledDialogTitle =>
      'Benachrichtigungen in Systemeinstellungen deaktiviert';

  @override
  String get notificationsDisabledDialogContent =>
      'Sie haben Benachrichtigungen in Ihren Geräteeinstellungen deaktiviert. Um Benachrichtigungen zu aktivieren, öffnen Sie bitte Ihre Geräteeinstellungen und erlauben Sie Benachrichtigungen für Timer.Coffee.';

  @override
  String get notificationDebug => 'Benachrichtigungs-Debug';

  @override
  String get testNotificationSystem => 'Benachrichtigungssystem testen';

  @override
  String get notificationsEnabled => 'Aktiviert';

  @override
  String get notificationsDisabled => 'Deaktiviert';

  @override
  String get notificationPermissionDialogTitle =>
      'Benachrichtigungen aktivieren?';

  @override
  String get notificationPermissionDialogMessage =>
      'Sie können Benachrichtigungen aktivieren, um nützliche Updates zu erhalten (z.B. über neue App-Versionen). Jetzt aktivieren oder jederzeit in den Einstellungen ändern.';

  @override
  String get notificationPermissionEnable => 'Aktivieren';

  @override
  String get notificationPermissionSkip => 'Nicht jetzt';

  @override
  String get holidayGiftBoxTitle => 'Holiday-Geschenkbox';

  @override
  String get holidayGiftBoxInfoTrigger => 'Was ist das?';

  @override
  String get holidayGiftBoxInfoBody =>
      'Kuratiere saisonale Angebote von Partnern. Links sind keine Affiliate-Links - wir möchten Timer.Coffee-Nutzern in dieser Feiertagszeit einfach eine kleine Freude bereiten. Zum Aktualisieren nach unten ziehen.';

  @override
  String get holidayGiftBoxNoOffers => 'Derzeit keine Angebote verfügbar.';

  @override
  String get holidayGiftBoxNoOffersSub =>
      'Zum Aktualisieren nach unten ziehen oder später erneut prüfen.';

  @override
  String holidayGiftBoxShowingRegion(String region) {
    return 'Angebote für $region';
  }

  @override
  String get holidayGiftBoxViewDetails => 'Details ansehen';

  @override
  String get holidayGiftBoxPromoCopied => 'Gutscheincode kopiert';

  @override
  String get holidayGiftBoxPromoCode => 'Gutscheincode';

  @override
  String giftDiscountOff(String percent) {
    return '$percent% Rabatt';
  }

  @override
  String giftDiscountUpToOff(String percent) {
    return 'Bis zu $percent% Rabatt';
  }

  @override
  String get holidayGiftBoxTerms => 'Bedingungen';

  @override
  String get holidayGiftBoxVisitSite => 'Partner-Website besuchen';

  @override
  String holidayGiftBoxValidUntil(String date) {
    return 'Gültig bis $date';
  }

  @override
  String holidayGiftBoxEndsInDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Endet in $days Tagen',
      one: 'Endet morgen',
      zero: 'Endet heute',
    );
    return '$_temp0';
  }

  @override
  String get holidayGiftBoxValidWhileAvailable => 'Gültig solange verfügbar';

  @override
  String holidayGiftBoxUpdated(String date) {
    return 'Aktualisiert $date';
  }

  @override
  String holidayGiftBoxLanguage(String language) {
    return 'Sprache: $language';
  }

  @override
  String get holidayGiftBoxRetry => 'Erneut versuchen';

  @override
  String get holidayGiftBoxLoadFailed =>
      'Angebote konnten nicht geladen werden';

  @override
  String get holidayGiftBoxOfferUnavailable => 'Angebot nicht verfügbar';

  @override
  String get holidayGiftBoxBannerTitle =>
      'Schau dir unsere Holiday Gift Box an';

  @override
  String get holidayGiftBoxBannerCta => 'Angebote ansehen';

  @override
  String get regionEurope => 'Europa';

  @override
  String get regionNorthAmerica => 'Nordamerika';

  @override
  String get regionAsia => 'Asien';

  @override
  String get regionAustralia => 'Australien / Ozeanien';

  @override
  String get regionWorldwide => 'Weltweit';

  @override
  String get regionAfrica => 'Afrika';

  @override
  String get regionMiddleEast => 'Naher Osten';

  @override
  String get regionSouthAmerica => 'Südamerika';
}
