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
  String get totalBeansBrewedLabel => 'Verwendete Bohnen';

  @override
  String get newBeansTriedLabel => 'Neue Bohnen ausprobiert';

  @override
  String get originsExploredLabel => 'Erkundete Herkünfte';

  @override
  String get regionsExploredLabel => 'Entdeckte Regionen';

  @override
  String get newRoastersDiscoveredLabel => 'Neue Röstereien entdeckt';

  @override
  String get favoriteRoastersLabel => 'Lieblingsröstereien';

  @override
  String get topOriginsLabel => 'Top-Herkünfte';

  @override
  String get topRegionsLabel => 'Top-Regionen';

  @override
  String get lastrecipe => 'Zuletzt verwendetes Rezept:';

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
      'Erstellte und importierte Rezepte ansehen und verwalten';

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
      'Sieh dir persönliche und globale Brühstatistiken und Trends an';

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
      'Timer.Coffee wurde von Anton Karliner entwickelt, einem Kaffee-Enthusiasten, Medienspezialisten und Fotojournalisten. Ich hoffe, die App hilft dir dabei, deinen Kaffee noch mehr zu genießen. Wenn du magst, kannst du auf GitHub mitwirken.';

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
  String get licensebutton => 'GNU General Public License v3 lesen';

  @override
  String get website => 'Webseite';

  @override
  String get sourcecode => 'Quellcode';

  @override
  String get support => 'Spendier dem Entwickler einen Kaffee';

  @override
  String get supportButtonLabel => 'Kontakt';

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
  String get tipsmall => 'Kleiner Kaffee';

  @override
  String get tipmedium => 'Mittlerer Kaffee';

  @override
  String get tiplarge => 'Großer Kaffee';

  @override
  String get supportdevelopment => 'Entwicklung unterstützen';

  @override
  String get supportdevmsg =>
      'Deine Spenden helfen dabei, die laufenden Kosten zu decken, zum Beispiel für Entwicklerlizenzen. Außerdem ermöglichen sie mir, mehr Brühgeräte auszuprobieren und mehr Rezepte in die App zu bringen.';

  @override
  String get supportdevtnx => 'Danke, dass du eine Spende in Erwägung ziehst!';

  @override
  String get donationok => 'Danke!';

  @override
  String get donationtnx =>
      'Ich weiß deine Unterstützung sehr zu schätzen. Ich wünsche dir viele großartige Tassen Kaffee! ☕️';

  @override
  String get donationerr => 'Fehler';

  @override
  String get donationerrmsg =>
      'Fehler bei der Verarbeitung des Kaufs. Bitte versuch es erneut.';

  @override
  String get sharemsg => 'Schau dir dieses Rezept an:';

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
  String get settingsDateTimeFormat => 'Datums- und Uhrzeitformat';

  @override
  String get settingsDateFormatLabel => 'Datumsformat';

  @override
  String get settingsTimeFormatLabel => 'Uhrzeitformat';

  @override
  String get settingsDateFormatAuto => 'Automatisch (an Sprache angepasst)';

  @override
  String get settingsDateFormatDMY => 'TT/MM/JJJJ';

  @override
  String get settingsDateFormatMDY => 'MM/TT/JJJJ';

  @override
  String get settingsDateFormatYMD => 'JJJJ-MM-TT';

  @override
  String get settingsTimeFormat12h => '12-Stunden (AM/PM)';

  @override
  String get settingsTimeFormat24h => '24-Stunden';

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
  String get slidertitle => 'Passe den Geschmack mit den Reglern an';

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
      'Deine Lieblingsrezepte sind noch leer. Entdecke neue Rezepte und finde deine Favoriten!';

  @override
  String get explore => 'Entdecken';

  @override
  String get dateFormat => 'd. MMM yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Brühtagebuch';

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
  String get statsscreen => 'Kaffeestatistiken';

  @override
  String get yourStats => 'Deine Statistiken';

  @override
  String get coffeeBrewed => 'Gebrühte Kaffeemenge:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'Meistgenutzte Rezepte:';

  @override
  String get globalStats => 'Globale Statistiken';

  @override
  String get unknownRecipe => 'Unbekanntes Rezept';

  @override
  String get pulseUserRecipe => 'Nutzerrezept';

  @override
  String get noData => 'Keine Daten';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String error(String error) {
    return 'Fehler: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Jemand hat gerade $recipeName gebrüht';
  }

  @override
  String pulseSomeoneBrewed(String recipeName) {
    return 'Jemand hat $recipeName gebrüht';
  }

  @override
  String pulseSomeoneFromBrewed(String country, String recipeName) {
    return 'Jemand aus $country hat $recipeName gebrüht';
  }

  @override
  String get pulseTitle => 'Pulse';

  @override
  String get hubPulseSubtitle => 'Live-Brühfeed';

  @override
  String get pulseLiveSummary => 'Live-Zusammenfassung';

  @override
  String get pulseBrewsLabel => 'Brühvorgänge';

  @override
  String pulseBrewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Brühvorgänge',
      one: '1 Brühvorgang',
    );
    return '$_temp0';
  }

  @override
  String get timePeriodRecent => 'Kürzlich';

  @override
  String get timePeriodLastHour => 'Letzte Stunde';

  @override
  String get timePeriodToday => 'Heute';

  @override
  String get timePeriodYesterday => 'Gestern';

  @override
  String get timePeriodThisWeek => 'Diese Woche';

  @override
  String get timePeriodThisMonth => 'Diesen Monat';

  @override
  String get timePeriodOlder => 'Älter';

  @override
  String get timePeriodCustom => 'Benutzerdefiniert';

  @override
  String get relativeTimeJustNow => 'gerade eben';

  @override
  String relativeTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Minuten',
      one: 'vor 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeHoursMinutesAgo(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours Stunden',
      one: '1 Stunde',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Minuten',
      one: '1 Minute',
    );
    return 'vor $_temp0 und $_temp1';
  }

  @override
  String relativeTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Monaten',
      one: 'vor 1 Monat',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Jahren',
      one: 'vor 1 Jahr',
    );
    return '$_temp0';
  }

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
  String get origin => 'Herkunft';

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
      'Dadurch wird eine Kopie deines Rezepts erstellt, die du unabhängig bearbeiten kannst. Möchtest du fortfahren?';

  @override
  String get confirmDeleteMessage =>
      'Möchtest du diesen Eintrag wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';

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
  String get region => 'Region';

  @override
  String get elevation => 'Höhe';

  @override
  String get harvestDate => 'Erntedatum';

  @override
  String get processing => 'Aufbereitung & Röstung';

  @override
  String get processingMethod => 'Aufbereitungsart';

  @override
  String get roastDate => 'Röstdatum';

  @override
  String get roastLevel => 'Röstgrad';

  @override
  String get cuppingScore => 'Cupping-Score';

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
  String get pleaseNote => 'Bitte beachte';

  @override
  String get firstTimePopupMessage =>
      '1. Wir nutzen externe Dienste, um Bilder zu verarbeiten. Wenn du fortfährst, stimmst du dem zu.\n2. Wir speichern deine Bilder nicht, aber vermeide bitte persönliche Daten im Bild.\n3. Die Bilderkennung ist derzeit auf 10 Token pro Monat begrenzt (1 Token = 1 Bild). Dieses Limit kann sich künftig ändern.';

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
      'Du hast dein monatliches Limit für die Bilderkennung erreicht.';

  @override
  String get noCoffeeLabelsDetected =>
      'Keine Kaffeeetiketten erkannt. Versuch es mit einem anderen Bild.';

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
  String get enterProcessingMethod => 'Aufbereitungsart eingeben';

  @override
  String get enterRoastLevel => 'Röstgrad eingeben';

  @override
  String get enterRegion => 'Region eingeben';

  @override
  String get enterTastingNotes => 'Geschmacksnoten eingeben';

  @override
  String get enterElevation => 'Höhe eingeben';

  @override
  String get enterCuppingScore => 'Cupping-Score eingeben';

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
  String get selectTime => 'Uhrzeit auswählen';

  @override
  String get save => 'Speichern';

  @override
  String get fillRequiredFields => 'Bitte fülle alle Pflichtfelder aus.';

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
  String get signInErrorGoogle => 'Fehler beim Anmelden mit Google';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get signOutSuccessful => 'Erfolgreich abgemeldet';

  @override
  String get signOutConfirmationTitle => 'Möchtest du dich wirklich abmelden?';

  @override
  String get signOutConfirmationMessage =>
      'Die Cloud-Synchronisierung wird angehalten. Melde dich erneut an, um sie fortzusetzen.';

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
  String get sendOTP => 'Bestätigungscode senden';

  @override
  String get otpSent =>
      'Der Bestätigungscode wurde an deine E-Mail-Adresse gesendet';

  @override
  String get otpSendError => 'Fehler beim Senden des Bestätigungscodes';

  @override
  String get enterOTP => 'Bestätigungscode eingeben';

  @override
  String get otpHint => 'Gib den 6-stelligen Bestätigungscode ein';

  @override
  String get verify => 'Überprüfen';

  @override
  String get signInSuccessfulEmail => 'Anmeldung erfolgreich';

  @override
  String get invalidOTP => 'Ungültiger Bestätigungscode';

  @override
  String get otpVerificationError =>
      'Fehler bei der Überprüfung des Bestätigungscodes';

  @override
  String get success => 'Erfolg!';

  @override
  String get otpSentMessage =>
      'Ein Bestätigungscode wird an deine E-Mail-Adresse gesendet. Gib ihn unten ein, sobald du ihn erhalten hast.';

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
      'Bitte beachte: Wenn du fortfährst, löschen wir dein Konto und die zugehörigen Daten von unseren Servern. Die lokale Kopie der Daten bleibt auf deinem Gerät. Wenn du sie ebenfalls löschen möchtest, kannst du die App einfach deinstallieren. Um die Synchronisierung wieder zu aktivieren, musst du ein neues Konto erstellen.';

  @override
  String get deleteAccountConfirmation => 'Konto erfolgreich gelöscht';

  @override
  String get accountDeleted => 'Konto gelöscht';

  @override
  String get accountDeletionError =>
      'Fehler beim Löschen deines Kontos. Bitte versuch es erneut.';

  @override
  String get deleteAccountTitle => 'Wichtig';

  @override
  String get selectBeans => 'Wähle Bohnen';

  @override
  String get all => 'Alle';

  @override
  String get selectRoaster => 'Wähle Rösterei';

  @override
  String get selectOrigin => 'Wähle Herkunft';

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
  String yearlyStatsStory4Text(num roasterCount) {
    return 'Du hast Bohnen von $roasterCount Röstereien verwendet';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Deine Top 3 Röstereien waren:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Kaffee hat dich auf eine Reise\num die Welt mitgenommen$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(num originCount) {
    return 'Du hast Kaffeebohnen\naus $originCount Ländern probiert!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Du warst nicht allein beim Brühen...';

  @override
  String get yearlyStatsStory7Part2 =>
      '...sondern mit Nutzern aus 110 anderen\nLändern auf 6 Kontinenten!';

  @override
  String yearlyStatsStory8TitleLow(num count) {
    return 'Du bist dir treu geblieben und hast dieses Jahr nur diese $count Brühmethoden verwendet:';
  }

  @override
  String yearlyStatsStory8TitleMedium(num count) {
    return 'Du hast neue Geschmäcker entdeckt und dieses Jahr $count Brühmethoden verwendet:';
  }

  @override
  String yearlyStatsStory8TitleHigh(num count) {
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
  String get yearlyStatsShareProgressTop3Roasters => 'Meine Top-3-Röstereien:';

  @override
  String get yearlyStats25AppBarTitle => 'Dein Jahr mit Timer.Coffee – 2025';

  @override
  String get yearlyStats25AppBarTitleSimple => 'Timer.Coffee 2025';

  @override
  String get yearlyStats25Slide1Title => 'Dein Jahr mit Timer.Coffee';

  @override
  String get yearlyStats25Slide1Subtitle =>
      'Tippe, um zu sehen, wie du 2025 Kaffee gebrüht hast';

  @override
  String get yearlyStats25Slide2Intro =>
      'Gemeinsam haben wir Kaffee gebrüht...';

  @override
  String yearlyStats25Slide2Count(String count) {
    return '$count Mal';
  }

  @override
  String yearlyStats25Slide2Liters(String liters) {
    return 'Das sind etwa $liters Liter Kaffee';
  }

  @override
  String get yearlyStats25Slide2Cambridge =>
      'Genug, um allen in Cambridge (UK) eine Tasse Kaffee zu schenken (die Studierenden wären besonders dankbar).';

  @override
  String get yearlyStats25Slide3Title => 'Und was ist mit dir?';

  @override
  String yearlyStats25Slide3Subtitle(String brews, String liters) {
    return 'Du hast dieses Jahr $brews Mal mit Timer.Coffee Kaffee gebrüht. Das sind insgesamt $liters Liter!';
  }

  @override
  String yearlyStats25Slide3TopBadge(int topPct) {
    return 'Du gehörst zu den Top $topPct% beim Kaffeebrühen!';
  }

  @override
  String get yearlyStats25Slide4TitleSingle =>
      'Erinnerst du dich an den Tag, an dem du dieses Jahr am meisten Kaffee gebrüht hast?';

  @override
  String get yearlyStats25Slide4TitleMulti =>
      'Erinnerst du dich an die Tage, an denen du dieses Jahr am meisten Kaffee gebrüht hast?';

  @override
  String get yearlyStats25Slide4TitleBrewTime => 'Deine Brühzeit dieses Jahr';

  @override
  String get yearlyStats25Slide4ScratchLabel => 'Zum Aufdecken freikratzen';

  @override
  String yearlyStats25BrewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Brühvorgänge',
      one: '1 Brühvorgang',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25Slide4PeakSingle(String date, String brewsLabel) {
    return '$date — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4PeakLiters(String liters) {
    return 'Etwa $liters Liter an diesem Tag';
  }

  @override
  String yearlyStats25Slide4PeakMostRecent(
    String mostRecent,
    String brewsLabel,
  ) {
    return 'Zuletzt: $mostRecent — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4BrewTimeLine(String timeLabel) {
    return 'Du hast $timeLabel mit dem Brühen verbracht';
  }

  @override
  String get yearlyStats25Slide4BrewTimeFooter => 'Gut investierte Zeit';

  @override
  String get yearlyStats25Slide5Title => 'So brühst du Kaffee';

  @override
  String get yearlyStats25Slide5MethodsHeader => 'Lieblingsmethoden:';

  @override
  String get yearlyStats25Slide5NoMethods => 'Noch keine Methoden';

  @override
  String get yearlyStats25Slide5RecipesHeader => 'Top-Rezepte:';

  @override
  String get yearlyStats25Slide5NoRecipes => 'Noch keine Rezepte';

  @override
  String yearlyStats25MethodRow(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Brühvorgänge',
      one: 'Brühvorgang',
    );
    return '$name — $count $_temp0';
  }

  @override
  String yearlyStats25Slide6Title(String count) {
    return 'Du hast dieses Jahr $count Röstereien entdeckt:';
  }

  @override
  String get yearlyStats25Slide6NoRoasters => 'Noch keine Röstereien';

  @override
  String get yearlyStats25Slide7Title =>
      'Kaffee trinken kann dich weit bringen…';

  @override
  String yearlyStats25Slide7Subtitle(String count) {
    return 'Du hast dieses Jahr $count Herkünfte entdeckt:';
  }

  @override
  String get yearlyStats25Others => '...und weitere';

  @override
  String yearlyStats25FallbackTitle(int countries, int roasters) {
    return 'Timer.Coffee-Nutzer haben dieses Jahr Bohnen aus $countries Ländern verwendet\nund $roasters verschiedene Röstereien erfasst.';
  }

  @override
  String get yearlyStats25FallbackPromptHasBeans =>
      'Warum nicht weiter deine Bohnen protokollieren?';

  @override
  String get yearlyStats25FallbackPromptNoBeans =>
      'Vielleicht ist jetzt der richtige Zeitpunkt, auch deine Bohnen zu erfassen?';

  @override
  String get yearlyStats25FallbackActionHasBeans => 'Weiter Bohnen hinzufügen';

  @override
  String get yearlyStats25FallbackActionNoBeans =>
      'Deine ersten Bohnen hinzufügen';

  @override
  String get yearlyStats25ContinueButton => 'Weiter';

  @override
  String get yearlyStats25PostcardTitle =>
      'Sende einem anderen Kaffeefan einen Neujahrsgruß.';

  @override
  String get yearlyStats25PostcardSubtitle =>
      'Optional. Sei freundlich. Keine persönlichen Daten.';

  @override
  String get yearlyStats25PostcardHint =>
      'Frohes neues Jahr und gute Brühungen!';

  @override
  String get yearlyStats25PostcardSending => 'Senden...';

  @override
  String get yearlyStats25PostcardSend => 'Senden';

  @override
  String get yearlyStats25PostcardSkip => 'Überspringen';

  @override
  String get yearlyStats25PostcardReceivedTitle =>
      'Ein Gruß von einem anderen Kaffeefan';

  @override
  String get yearlyStats25PostcardErrorLength =>
      'Bitte 2–160 Zeichen eingeben.';

  @override
  String get yearlyStats25PostcardErrorSend =>
      'Konnte nicht gesendet werden. Bitte versuche es erneut.';

  @override
  String get yearlyStats25PostcardErrorRejected =>
      'Konnte nicht gesendet werden. Bitte versuche eine andere Nachricht.';

  @override
  String get yearlyStats25CtaTitle => 'Lass uns 2026 etwas Großartiges brühen!';

  @override
  String get yearlyStats25CtaSubtitle => 'Hier sind ein paar Ideen:';

  @override
  String get yearlyStats25CtaExplorePrefix => 'Entdecke Angebote in der ';

  @override
  String get yearlyStats25CtaGiftBox => 'Holiday-Geschenkbox';

  @override
  String get yearlyStats25CtaDonate => 'Spenden';

  @override
  String get yearlyStats25CtaDonateSuffix =>
      ' um Timer.Coffee im kommenden Jahr wachsen zu lassen';

  @override
  String get yearlyStats25CtaFollowPrefix => 'Folge uns auf ';

  @override
  String get yearlyStats25CtaInstagram => 'Instagram';

  @override
  String get yearlyStats25CtaShareButton => 'Teile meinen Fortschritt';

  @override
  String get yearlyStats25CtaShareHint =>
      'Vergiss nicht, @timercoffeeapp zu markieren';

  @override
  String get yearlyStats25AppBarTooltipResume => 'Fortsetzen';

  @override
  String get yearlyStats25AppBarTooltipPause => 'Pausieren';

  @override
  String get yearlyStats25ShareError =>
      'Der Rückblick konnte nicht geteilt werden. Bitte versuche es erneut.';

  @override
  String yearlyStats25BrewTimeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten',
      one: '1 Minute',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25BrewTimeHours(String hours) {
    return '$hours h';
  }

  @override
  String get yearlyStats25ShareTitle => 'Mein Jahr 2025 mit Timer.Coffee';

  @override
  String get yearlyStats25ShareBrewedPrefix => 'Gebrüht ';

  @override
  String get yearlyStats25ShareBrewedMiddle => ' Mal und ';

  @override
  String get yearlyStats25ShareBrewedSuffix => ' Liter Kaffee';

  @override
  String get yearlyStats25ShareRoastersPrefix => 'Bohnen von ';

  @override
  String get yearlyStats25ShareRoastersSuffix => ' Röstereien';

  @override
  String get yearlyStats25ShareOriginsPrefix => 'Entdeckt ';

  @override
  String get yearlyStats25ShareOriginsSuffix => ' Kaffeeherkünfte';

  @override
  String get yearlyStats25ShareMethodsTitle => 'Meine Lieblings-Brühmethoden:';

  @override
  String get yearlyStats25ShareRecipesTitle => 'Meine Top-Rezepte:';

  @override
  String get yearlyStats25ShareHandle => '@timercoffeeapp';

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
      other: 'Röstereien',
      one: 'Rösterei',
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
      'Bitte gib einen Rezeptnamen ein';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Bitte gib eine Kurzbeschreibung ein';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Bitte wähle eine Brühmethode aus';

  @override
  String get recipeCreationScreenRequiredValidator => 'Erforderlich';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Ungültige Nummer';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Bitte gib eine Schrittbeschreibung ein';

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
    return 'Möchtest du das Rezept \'$recipeName\' aus der Cloud importieren?';
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
  String get dismiss => 'Schließen';

  @override
  String get reviewRecipeButton => 'Rezept überprüfen';

  @override
  String get signInRequiredTitle => 'Anmeldung erforderlich';

  @override
  String get signInRequiredBodyShare =>
      'Du musst angemeldet sein, um deine eigenen Rezepte zu teilen.';

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
    return 'Deine lokalen Änderungen wurden gespeichert, aber die öffentliche Version konnte wegen der Inhaltsmoderation nicht aktualisiert werden: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Importiertes Rezept bearbeiten';

  @override
  String get editImportedRecipeBody =>
      'Das ist ein importiertes Rezept. Wenn du es bearbeitest, wird eine neue, unabhängige Kopie erstellt. Möchtest du fortfahren?';

  @override
  String get editImportedRecipeButtonCopy => 'Kopie erstellen & bearbeiten';

  @override
  String get editImportedRecipeButtonCancel => 'Abbrechen';

  @override
  String get editDisplayNameTitle => 'Anzeigename bearbeiten';

  @override
  String get displayNameHint => 'Gib deinen Anzeigenamen ein';

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
      'Möchtest du dein Profilbild wirklich löschen?';

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
  String get settingsBrewingMethodsTitle =>
      'Brühmethoden auf dem Startbildschirm';

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
  String get noBeansMatchSearch => 'Keine Bohnen entsprechen deiner Suche';

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
  String get qualityMeasurements => 'Qualität & Messwerte';

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
      'Wenn du dieses Rezept als privat markierst, passiert Folgendes:';

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
  String get unitFieldInvalidNumberError => 'Bitte gib eine gültige Zahl ein';

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
      'Bitte gib eine gültige Zahl ein';

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
      'Du hast ungespeicherte Änderungen. Möchtest du sie wirklich verwerfen?';

  @override
  String get unsavedChangesStay => 'Bleiben';

  @override
  String get unsavedChangesDiscard => 'Verwerfen';

  @override
  String beansWeightAddedBack(
    String amount,
    String beanName,
    String newWeight,
    String unit,
  ) {
    return '$amount$unit zurück zu $beanName hinzugefügt. Neues Gewicht: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
    String amount,
    String beanName,
    String newWeight,
    String unit,
  ) {
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
      'Du hast Benachrichtigungen in deinen Geräteeinstellungen deaktiviert. Um Benachrichtigungen zu aktivieren, öffne bitte deine Geräteeinstellungen und erlaube Benachrichtigungen für Timer.Coffee.';

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
      'Du kannst Benachrichtigungen aktivieren, um nützliche Updates zu erhalten, zum Beispiel über neue App-Versionen. Benachrichtigungen sind außerdem für Live-Fortschrittsupdates beim Brühen erforderlich. Du kannst sie jetzt aktivieren oder später jederzeit in den Einstellungen ändern.';

  @override
  String get notificationPermissionDialogMessageIos =>
      'Du kannst Benachrichtigungen aktivieren, um nützliche Updates zu erhalten, zum Beispiel über neue App-Versionen. Benachrichtigungen sind außerdem für Live-Aktivitäten und die Dynamic Island auf iOS erforderlich. Du kannst sie jetzt aktivieren oder später jederzeit in den Einstellungen ändern.';

  @override
  String get notificationPermissionDialogMessageAndroid =>
      'Du kannst Benachrichtigungen aktivieren, um nützliche Updates zu erhalten, zum Beispiel über neue App-Versionen. Benachrichtigungen sind außerdem für Live-Updates auf Android erforderlich. Du kannst sie jetzt aktivieren oder später jederzeit in den Einstellungen ändern.';

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
      'Eine kuratierte Auswahl saisonaler Angebote unserer Partner. Die Links sind keine Affiliate-Links; wir möchten der Timer.Coffee-Community in der Feiertagszeit einfach eine kleine Freude machen. Zum Aktualisieren nach unten ziehen.';

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
  String get holidayGiftBoxBannerTitle => 'Entdecke unsere Holiday Gift Box';

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

  @override
  String get setToZeroButton => 'Auf null setzen';

  @override
  String get setToZeroDialogTitle => 'Bestand auf null setzen?';

  @override
  String get setToZeroDialogBody =>
      'Dadurch wird die verbleibende Menge auf 0 g gesetzt. Du kannst sie später bearbeiten.';

  @override
  String get setToZeroDialogConfirm => 'Auf null setzen';

  @override
  String get setToZeroDialogCancel => 'Abbrechen';

  @override
  String get inventorySetToZeroSuccess => 'Bestand auf 0 g gesetzt';

  @override
  String get inventorySetToZeroFail =>
      'Bestand konnte nicht auf null gesetzt werden';

  @override
  String get timePeriodThisYear => 'Dieses Jahr';

  @override
  String get timePeriodLastYear => 'Letztes Jahr';

  @override
  String get nativeAppPromoTitle => 'Hol dir die Timer.Coffee-App';

  @override
  String get nativeAppPromoDescription =>
      'Mit KI-gestütztem Scan von Kaffeeetiketten, Live-Aktivitäten auf dem Sperrbildschirm, Push-Benachrichtigungen, haptischem Feedback und mehr.';

  @override
  String get nativeAppPromoButton => 'App herunterladen';

  @override
  String get addBrewEntry => 'Brühvorgang hinzufügen';

  @override
  String get selectBrewingMethod => 'Brühmethode auswählen';

  @override
  String get selectRecipe => 'Rezept auswählen';

  @override
  String get brewDate => 'Datum';

  @override
  String get brewTime => 'Uhrzeit';

  @override
  String get brewEntrySaved => 'Brühvorgang gespeichert';

  @override
  String get brewingMethodRequired => 'Bitte wähle eine Brühmethode';

  @override
  String get recipeRequired => 'Bitte wähle ein Rezept';

  @override
  String get onboardingTitle => 'Willkommen bei Timer.Coffee';

  @override
  String get onboardingSubtitle => 'Womit brühst du?';

  @override
  String get onboardingShowAll => 'Alle Brühmethoden anzeigen';

  @override
  String get coffeeJourneyTitle => 'Erste Schritte';

  @override
  String get coffeeJourneyMilestoneFirstBrew =>
      'Schließe deinen ersten Brühvorgang ab';

  @override
  String get coffeeJourneyMilestoneTryMethod =>
      'Probiere ein anderes Rezept aus';

  @override
  String get coffeeJourneyMilestoneAddBeans =>
      'Füge deine ersten Kaffeebohnen hinzu';

  @override
  String get coffeeJourneyMilestoneFavorite =>
      'Füge ein Rezept zu den Favoriten hinzu';

  @override
  String get coffeeJourneyMilestoneStats => 'Sieh dir deine Brühstatistiken an';

  @override
  String get coffeeJourneyMilestonePulse =>
      'Sieh, wie auf der ganzen Welt gebrüht wird';

  @override
  String get coffeeJourneyCompleted =>
      'Du hast die ersten Schritte abgeschlossen!';

  @override
  String get coffeeJourneyDoneButton => 'Fertig';

  @override
  String get coffeeJourneyDismissHint =>
      'Du kannst deinen Fortschritt jederzeit im Tab Mehr ansehen.';

  @override
  String get coffeeJourneyDismissConfirm =>
      'Möchtest du deinen Fortschritt im Bereich Erste Schritte ausblenden?';

  @override
  String get coffeeJourneyHideButton => 'Ausblenden';

  @override
  String get firstBrewCongrats =>
      'Glückwunsch zu deinem ersten Brühvorgang! Er wurde in deinem Brühtagebuch gespeichert.';

  @override
  String get firstBrewDiaryLink => 'Brühtagebuch ansehen';

  @override
  String get beanCoverPhoto => 'Titelbild';

  @override
  String get beanCoverPhotoAdd => 'Titelbild hinzufügen';

  @override
  String get beanCoverPhotoChange => 'Foto ändern';

  @override
  String get beanCoverPhotoRemove => 'Foto entfernen';

  @override
  String get beanCoverPhotoSavePromptTitle => 'Als Titelbild verwenden?';

  @override
  String get beanCoverPhotoSavePromptBody =>
      'Möchtest du eines der gescannten Bilder als Titelbild für diese Bohne speichern?';

  @override
  String get beanCoverPhotoUploading => 'Foto wird hochgeladen…';

  @override
  String get beanCoverPhotoError => 'Foto konnte nicht hochgeladen werden';

  @override
  String get beanCoverPhotoSignInPrompt =>
      'Melde dich an, um ein Titelbild hinzuzufügen';

  @override
  String get settingsAnalyticsTitle => 'Datenschutz & Analysen';

  @override
  String get settingsAnalyticsBrews => 'Brüh-Analysen teilen';

  @override
  String get settingsAnalyticsBeans => 'Bohnen-Analysen teilen';

  @override
  String get settingsAnalyticsGeneral => 'Allgemeine Nutzungsdaten teilen';

  @override
  String get done => 'Fertig';

  @override
  String get saving => 'Wird gespeichert…';

  @override
  String get notifBrewReminderTitle => 'Vermisst du dein Kaffeeritual?';

  @override
  String get notifBrewReminderBody =>
      'Es sind ein paar Tage vergangen. Bereit für den nächsten Kaffee?';

  @override
  String get notifBrewReminderTitle2 => 'Zeit für einen Kaffee?';

  @override
  String get notifBrewReminderBody2 =>
      'Dein Setup ist bereit, wenn du es bist.';

  @override
  String get notifBrewReminderTitle3 => 'Dein Wasserkocher ruft';

  @override
  String get notifBrewReminderBody3 =>
      'Eine gute Tasse ist nur ein paar Minuten entfernt.';

  @override
  String get notifBrewEscalationTitle => 'Lust auf noch einen Kaffee?';

  @override
  String get notifBrewEscalationBody =>
      'Es ist schon etwas her. Bereit, wieder etwas Gutes zuzubereiten?';

  @override
  String get notifBrewEscalationTitle2 => 'Schon eine Weile her?';

  @override
  String get notifBrewEscalationBody2 =>
      'Kein Stress. Dein Setup ist bereit, wenn du es bist.';

  @override
  String get notifBrewEscalationTitle3 => 'Wieder Zeit für Kaffee?';

  @override
  String get notifBrewEscalationBody3 =>
      'Eine richtig gute Tasse ist nur ein paar Minuten entfernt.';

  @override
  String get notifDiscoverBeansTitle => 'Behalte deine Bohnen im Blick';

  @override
  String get notifDiscoverBeansBody =>
      'Erfasse deine Bohnen und merke dir deine Favoriten.';

  @override
  String get notifDiscoverPulseTitle => 'Sieh, was andere gerade brühen';

  @override
  String get notifDiscoverPulseBody =>
      'Öffne Pulse, um Live-Brühvorgänge aus aller Welt zu sehen.';

  @override
  String get notifBrewMilestoneTitle => 'Du hast einen Meilenstein erreicht';

  @override
  String notifBrewMilestoneBody(int count) {
    return 'Du hast $count Mal gebrüht. Tippe, um deinen Fortschritt zu sehen.';
  }

  @override
  String notifExploreRecipesTitle(String methodName) {
    return 'Probiere ein neues Rezept für $methodName';
  }

  @override
  String notifExploreRecipesBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bisher hast du $count Rezepte ausprobiert. Hier ist noch eins zum Testen.',
      one:
          'Bisher hast du 1 Rezept ausprobiert. Hier ist ein weiteres zum Testen.',
    );
    return '$_temp0';
  }

  @override
  String get notifMorningTitle => 'Guten Morgen. Bereit zum Brühen?';

  @override
  String get notifMorningBody => 'Starte den Tag mit einer guten Tasse.';

  @override
  String get notifMorningTitle2 => 'Aufstehen und brühen';

  @override
  String get notifMorningBody2 =>
      'Dein Morgenkaffee kann in wenigen Minuten fertig sein.';

  @override
  String get notifMorningTitle3 => 'Die erste Tasse des Tages?';

  @override
  String get notifMorningBody3 => 'Wähle ein Rezept und leg los.';

  @override
  String notifWeeklyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Brühvorgänge diese Woche',
      one: '1 Brühvorgang diese Woche',
    );
    return '$_temp0';
  }

  @override
  String notifWeeklyBody(int recipes) {
    String _temp0 = intl.Intl.pluralLogic(
      recipes,
      locale: localeName,
      other:
          'Über $recipes Rezepte hinweg. Tippe, um die Aufschlüsselung zu sehen.',
      one: 'Tippe, um deine Wochenstatistik zu sehen.',
    );
    return '$_temp0';
  }

  @override
  String get notifBeanFreshnessTitle => 'Zeit für frische Bohnen?';

  @override
  String notifBeanFreshnessBody(String beanName, int days) {
    return 'Deine Bohnen $beanName wurden vor $days Tagen geröstet. Sie sind vielleicht nicht mehr auf ihrem Höhepunkt.';
  }

  @override
  String get settingsNotificationsToggle => 'Benachrichtigungen aktivieren';

  @override
  String get settingsMorningReminder => 'Morgen-Erinnerung fürs Brühen';

  @override
  String get settingsMorningReminderSubtitle =>
      'Tägliche Erinnerung an deinen Morgenkaffee';

  @override
  String get settingsMorningReminderTime => 'Erinnerungszeit';

  @override
  String get settingsWeeklySummary => 'Wochenzusammenfassung';

  @override
  String get settingsWeeklySummarySubtitle =>
      'Sonntagabend-Zusammenfassung deiner Brühvorgänge';

  @override
  String get settingsBeanFreshness => 'Bohnen-Frischewarnungen';

  @override
  String get settingsBeanFreshnessSubtitle =>
      'Benachrichtigen, wenn Bohnen älter als 3 Wochen sind';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }
}
