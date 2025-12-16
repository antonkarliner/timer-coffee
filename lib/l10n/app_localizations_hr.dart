// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'Statistika zrna';

  @override
  String get totalBeansBrewedLabel => 'Ukupno pripremljenih zrna';

  @override
  String get newBeansTriedLabel => 'Isprobano novih zrna';

  @override
  String get originsExploredLabel => 'Istražena podrijetla';

  @override
  String get regionsExploredLabel => 'Europa';

  @override
  String get newRoastersDiscoveredLabel => 'Otkriveno novih pržionica';

  @override
  String get favoriteRoastersLabel => 'Omiljene pržionice';

  @override
  String get topOriginsLabel => 'Naj podrijetla';

  @override
  String get topRegionsLabel => 'Naj regije';

  @override
  String get lastrecipe => 'Zadnji korišteni recept:';

  @override
  String get userRecipesTitle => 'Tvoji recepti';

  @override
  String get userRecipesSectionCreated => 'Kreirano od tebe';

  @override
  String get userRecipesSectionImported => 'Uvezeno od tebe';

  @override
  String get userRecipesEmpty => 'Nema pronađenih recepata';

  @override
  String get userRecipesDeleteTitle => 'Izbrisati recept?';

  @override
  String get userRecipesDeleteMessage => 'Ova radnja se ne može poništiti.';

  @override
  String get userRecipesDeleteConfirm => 'Izbriši';

  @override
  String get userRecipesDeleteCancel => 'Odustani';

  @override
  String get userRecipesSnackbarDeleted => 'Recept je izbrisan';

  @override
  String get hubUserRecipesTitle => 'Tvoji recepti';

  @override
  String get hubUserRecipesSubtitle =>
      'Pregledaj i upravljaj kreiranim i uvezenim receptima';

  @override
  String get hubAccountSubtitle => 'Upravljaj svojim profilom';

  @override
  String get hubSignInCreateSubtitle =>
      'Prijavi se za sinkronizaciju recepata i postavki';

  @override
  String get hubBrewDiarySubtitle =>
      'Pregledaj svoju povijest pripreme i dodaj bilješke';

  @override
  String get hubBrewStatsSubtitle =>
      'Pregledaj osobnu i globalnu statistiku i trendove pripreme';

  @override
  String get hubSettingsSubtitle => 'Promijeni postavke i ponašanje aplikacije';

  @override
  String get hubAboutSubtitle => 'Detalji aplikacije, verzija i suradnici';

  @override
  String get about => 'O aplikaciji';

  @override
  String get author => 'Autor';

  @override
  String get authortext =>
      'Aplikaciju Timer.Coffee razvio je Anton Karliner, entuzijast za kavu, medijski stručnjak i fotoreporter. Nadam se da će ti aplikacija pomoći uživati u kavi. Slobodno doprinesi na GitHubu.';

  @override
  String get contributors => 'Suradnici';

  @override
  String get errorLoadingContributors => 'Greška pri učitavanju suradnika';

  @override
  String get license => 'Licenca';

  @override
  String get licensetext =>
      'Ova aplikacija je slobodni softver: možete je distribuirati i/ili mijenjati pod uvjetima GNU Opće javne licence koju je objavila Zaklada za slobodni softver, bilo verzije 3 Licence ili (po vašem izboru) bilo koje kasnije verzije.';

  @override
  String get licensebutton => 'Pročitajte GNU Opću javnu licencu v3';

  @override
  String get website => 'Web stranica';

  @override
  String get sourcecode => 'Izvorni kod';

  @override
  String get support => 'Kupi mi kavu';

  @override
  String get allrecipes => 'Svi recepti';

  @override
  String get favoriterecipes => 'Omiljeni recepti';

  @override
  String get coffeeamount => 'Količina kave (g)';

  @override
  String get wateramount => 'Količina vode (ml)';

  @override
  String get watertemp => 'Temperatura vode';

  @override
  String get grindsize => 'Finoća mljevenja';

  @override
  String get brewtime => 'Vrijeme pripreme';

  @override
  String get recipesummary => 'Sažetak recepta';

  @override
  String get recipesummarynote =>
      'Napomena: ovo je osnovni recept sa zadanim količinama vode i kave.';

  @override
  String get preparation => 'Priprema';

  @override
  String get brewingprocess => 'Proces pripreme';

  @override
  String get step => 'Korak';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sekundi',
      one: 'sekunda',
      zero: 'sekundi',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg =>
      'Hvala što koristiš Timer.Coffee! Uživaj u kavi koju si pripremio na način';

  @override
  String get coffeefact => 'Činjenica o kavi';

  @override
  String get home => 'Početna';

  @override
  String get appversion => 'Verzija aplikacije';

  @override
  String get tipsmall => 'Kupi malu kavu';

  @override
  String get tipmedium => 'Kupi srednju kavu';

  @override
  String get tiplarge => 'Kupi veliku kavu';

  @override
  String get supportdevelopment => 'Podrži razvoj';

  @override
  String get supportdevmsg =>
      'Vaše donacije pomažu u pokrivanju troškova održavanja (npr. licenci za razvojne programere). Također mi omogućuju da isprobam više uređaja za kuhanje kave i dodam više recepata u aplikaciju.';

  @override
  String get supportdevtnx => 'Hvala što razmišljaš o donaciji!';

  @override
  String get donationok => 'Hvala!';

  @override
  String get donationtnx =>
      'Zaista cijenim tvoju podršku! Želim ti puno odličnih priprema! ☕️';

  @override
  String get donationerr => 'Greška';

  @override
  String get donationerrmsg => 'Greška pri obradi kupnje, pokušaj ponovno.';

  @override
  String get sharemsg => 'Pregledaj ovaj recept:';

  @override
  String get finishbrew => 'Završi';

  @override
  String get settings => 'Postavke';

  @override
  String get settingstheme => 'Tema';

  @override
  String get settingsthemelight => 'Svijetla';

  @override
  String get settingsthemedark => 'Tamna';

  @override
  String get settingsthemesystem => 'Sustav';

  @override
  String get settingslang => 'Jezik';

  @override
  String get sweet => 'Slatko';

  @override
  String get balance => 'Balans';

  @override
  String get acidic => 'Kiselo';

  @override
  String get light => 'Svijetlo';

  @override
  String get strong => 'Jako';

  @override
  String get slidertitle => 'Pomoću klizača prilagodi okus';

  @override
  String get whatsnewtitle => 'Novosti';

  @override
  String get whatsnewclose => 'Zatvori';

  @override
  String get seasonspecials => 'Sezonska specijalna ponuda';

  @override
  String get snow => 'Snijeg';

  @override
  String get noFavoriteRecipesMessage =>
      'Tvoj popis omiljenih recepata je trenutno prazan. Počni istraživati i pripremati kako bi otkrio/la svoje favorite!';

  @override
  String get explore => 'Istraži';

  @override
  String get dateFormat => 'MMM d, yyyy';

  @override
  String get timeFormat => 'hh:mm a';

  @override
  String get brewdiary => 'Dnevnik pripreme';

  @override
  String get brewdiarynotfound => 'Nije pronađen nijedan unos';

  @override
  String get beans => 'Zrna';

  @override
  String get roaster => 'Pržionica';

  @override
  String get rating => 'Ocjena';

  @override
  String get notes => 'Bilješke';

  @override
  String get statsscreen => 'Statistika kave';

  @override
  String get yourStats => 'Tvoja statistika';

  @override
  String get coffeeBrewed => 'Pripremljeno kave:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'Najčešće korišteni recepti:';

  @override
  String get globalStats => 'Globalna statistika';

  @override
  String get unknownRecipe => 'Nepoznat recept';

  @override
  String get noData => 'Nema podataka';

  @override
  String error(String error) {
    return 'Greška: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Netko je upravo pripremio $recipeName';
  }

  @override
  String get timePeriodToday => 'Danas';

  @override
  String get timePeriodThisWeek => 'Ovaj tjedan';

  @override
  String get timePeriodThisMonth => 'Ovaj mjesec';

  @override
  String get timePeriodCustom => 'Prilagođeno';

  @override
  String get statsFor => 'Statistika za ';

  @override
  String get homescreenbrewcoffee => 'Pripremi kavu';

  @override
  String get homescreenhub => 'Središte';

  @override
  String get homescreenmore => 'Više';

  @override
  String get addBeans => 'Dodaj zrna';

  @override
  String get removeBeans => 'Ukloni zrna';

  @override
  String get name => 'Naziv';

  @override
  String get origin => 'Podrijetlo';

  @override
  String get details => 'Detalji';

  @override
  String get coffeebeans => 'Zrna kave';

  @override
  String get loading => 'Učitavanje';

  @override
  String get nocoffeebeans => 'Nisu pronađena zrna kave';

  @override
  String get delete => 'Izbriši';

  @override
  String get confirmDeleteTitle => 'Izbrisati unos?';

  @override
  String get recipeDuplicateConfirmTitle => 'Duplicirati recept?';

  @override
  String get recipeDuplicateConfirmMessage =>
      'Ovo će stvoriti kopiju tvog recepta koju možeš uređivati neovisno. Želiš li nastaviti?';

  @override
  String get confirmDeleteMessage =>
      'Jesi li siguran/na da želiš izbrisati ovaj unos? Ova radnja se ne može poništiti.';

  @override
  String get removeFavorite => 'Ukloni iz favorita';

  @override
  String get addFavorite => 'Dodaj u favorite';

  @override
  String get toggleEditMode => 'Uključi/isključi način uređivanja';

  @override
  String get coffeeBeansDetails => 'Detalji o zrnima kave';

  @override
  String get edit => 'Uredi';

  @override
  String get coffeeBeansNotFound => 'Zrna kave nisu pronađena';

  @override
  String get basicInformation => 'Osnovne informacije';

  @override
  String get geographyTerroir => 'Geografija/Tlo';

  @override
  String get variety => 'Sorta';

  @override
  String get region => 'Sjeverna Amerika';

  @override
  String get elevation => 'Nadmorska visina';

  @override
  String get harvestDate => 'Datum berbe';

  @override
  String get processing => 'Obrada';

  @override
  String get processingMethod => 'Način obrade';

  @override
  String get roastDate => 'Datum prženja';

  @override
  String get roastLevel => 'Stupanj prženja';

  @override
  String get cuppingScore => 'Cupping ocjena';

  @override
  String get flavorProfile => 'Profil okusa';

  @override
  String get tastingNotes => 'Bilješke o kušanju';

  @override
  String get additionalNotes => 'Dodatne bilješke';

  @override
  String get noCoffeeBeans => 'Nisu pronađena zrna kave';

  @override
  String get editCoffeeBeans => 'Uredi zrna kave';

  @override
  String get addCoffeeBeans => 'Dodaj zrna kave';

  @override
  String get showImagePicker => 'Prikaži birač slika';

  @override
  String get pleaseNote => 'Imaj na umu';

  @override
  String get firstTimePopupMessage =>
      '1. Za obradu slika koristimo vanjske servise. Nastavkom se slažeš s time.\n2. Iako ne pohranjujemo tvoje slike, molimo izbjegavaj uključivanje osobnih podataka.\n3. Prepoznavanje slika trenutno je ograničeno na 10 tokena mjesečno (1 token = 1 slika). Ovo se ograničenje može promijeniti u budućnosti.';

  @override
  String get ok => 'OK';

  @override
  String get takePhoto => 'Snimi fotografiju';

  @override
  String get selectFromPhotos => 'Odaberi iz fotografija';

  @override
  String get takeAdditionalPhoto => 'Snimiti dodatnu fotografiju?';

  @override
  String get no => 'Ne';

  @override
  String get yes => 'Da';

  @override
  String get selectedImages => 'Odabrane slike';

  @override
  String get selectedImage => 'Odabrana slika';

  @override
  String get backToSelection => 'Natrag na izbor';

  @override
  String get next => 'Dalje';

  @override
  String get unexpectedErrorOccurred => 'Došlo je do neočekivane greške';

  @override
  String get tokenLimitReached =>
      'Žao nam je, dosegli ste ograničenje tokena za prepoznavanje slika ovaj mjesec';

  @override
  String get noCoffeeLabelsDetected =>
      'Nisu pronađene oznake kave. Pokušajte s drugom slikom.';

  @override
  String get collectedInformation => 'Prikupljene informacije';

  @override
  String get enterRoaster => 'Unesi pržionicu';

  @override
  String get enterName => 'Unesi naziv';

  @override
  String get enterOrigin => 'Unesi podrijetlo';

  @override
  String get optional => 'Neobavezno';

  @override
  String get enterVariety => 'Unesi sortu';

  @override
  String get enterProcessingMethod => 'Unesi način obrade';

  @override
  String get enterRoastLevel => 'Unesi stupanj prženja';

  @override
  String get enterRegion => 'Unesi regiju';

  @override
  String get enterTastingNotes => 'Unesi bilješke o kušanju';

  @override
  String get enterElevation => 'Unesi nadmorsku visinu';

  @override
  String get enterCuppingScore => 'Unesi cupping ocjenu';

  @override
  String get enterNotes => 'Unesi bilješke';

  @override
  String get inventory => 'Zaliha';

  @override
  String get amountLeft => 'Preostala količina';

  @override
  String get enterAmountLeft => 'Unesi preostalu količinu';

  @override
  String get selectHarvestDate => 'Odaberi datum berbe';

  @override
  String get selectRoastDate => 'Odaberi datum prženja';

  @override
  String get selectDate => 'Odaberi datum';

  @override
  String get save => 'Spremi';

  @override
  String get fillRequiredFields => 'Molimo ispuni sva obavezna polja.';

  @override
  String get analyzing => 'Analiziranje';

  @override
  String get errorMessage => 'Greška';

  @override
  String get selectCoffeeBeans => 'Odaberi zrna kave';

  @override
  String get addNewBeans => 'Dodaj nova zrna';

  @override
  String get favorite => 'Favorit';

  @override
  String get notFavorite => 'Nije favorit';

  @override
  String get myBeans => 'Moja zrna';

  @override
  String get signIn => 'Prijava';

  @override
  String get signOut => 'Odjava';

  @override
  String get signInWithApple => 'Prijava putem Applea';

  @override
  String get signInSuccessful => 'Uspješna prijava putem Applea';

  @override
  String get signInError => 'Greška pri prijavi putem Applea';

  @override
  String get signInWithGoogle => 'Prijava putem Googlea';

  @override
  String get signOutSuccessful => 'Uspješna odjava';

  @override
  String get signInSuccessfulGoogle => 'Uspješna prijava putem Googlea';

  @override
  String get signInWithEmail => 'Prijava e‑mailom';

  @override
  String get enterEmail => 'Unesi svoj e‑mail';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get cancel => 'Odustani';

  @override
  String get sendMagicLink => 'Pošalji Magic link';

  @override
  String get magicLinkSent => 'Magic link poslan! Provjeri e‑mail.';

  @override
  String get sendOTP => 'Pošalji jednokratni kod';

  @override
  String get otpSent => 'Jednokratni kod poslan na tvoj e‑mail';

  @override
  String get otpSendError => 'Pogreška pri slanju jednokratnog koda';

  @override
  String get enterOTP => 'Unesi jednokratni kod';

  @override
  String get otpHint => 'Unesi 6-znamenkasti kod';

  @override
  String get verify => 'Potvrdi';

  @override
  String get signInSuccessfulEmail => 'Prijava uspješna';

  @override
  String get invalidOTP => 'Nevažeći kod';

  @override
  String get otpVerificationError => 'Greška pri provjeri jednokratnog koda';

  @override
  String get success => 'Uspjeh!';

  @override
  String get otpSentMessage =>
      'Jednokratni kod šalje se na tvoj e‑mail. Kada ga primiš, upiši ga dolje.';

  @override
  String get otpHint2 => 'Ovdje unesi kod';

  @override
  String get signInCreate => 'Prijava / Kreiraj račun';

  @override
  String get accountManagement => 'Upravljanje računom';

  @override
  String get deleteAccount => 'Izbriši račun';

  @override
  String get deleteAccountWarning =>
      'Napomena: ako odlučiš nastaviti, izbrisat ćemo tvoj račun i sve povezane podatke. Lokalna kopija podataka ostat će na uređaju, ako i njih želiš izbrisati, jednostavno izbriši aplikaciju. Ako kasnije želiš ponovno omogućiti sinkronizaciju, morat ćeš ponovno kreirati račun.';

  @override
  String get deleteAccountConfirmation => 'Račun je uspješno izbrisan';

  @override
  String get accountDeleted => 'Račun izbrisan';

  @override
  String get accountDeletionError =>
      'Greška pri brisanju računa, pokušaj ponovno';

  @override
  String get deleteAccountTitle => 'Važno';

  @override
  String get selectBeans => 'Odaberi zrna';

  @override
  String get all => 'Sve';

  @override
  String get selectRoaster => 'Odaberi pržionicu';

  @override
  String get selectOrigin => 'Odaberi podrijetlo';

  @override
  String get resetFilters => 'Poništi filtere';

  @override
  String get showFavoritesOnly => 'Prikaži samo favorite';

  @override
  String get apply => 'Primijeni';

  @override
  String get selectSize => 'Odaberi veličinu';

  @override
  String get sizeStandard => 'Standardna';

  @override
  String get sizeMedium => 'Srednja';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Moja godina s Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      'Hej, hvala što si ove godine bio/bila dio svemira Timer.Coffee!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'Prvo najvažnije.\nOve godine si pripremio/la nešto kave$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'Preciznije,\npripremio/la si $liters litara kave u 2024.!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'Koristio/la si zrna iz $roasterCount pržionica';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Tvoje top 3 pržionice su bile:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Kava te odvela na put\noko svijeta$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'Kušao/la si zrna kave\niz $originCount država!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Nisi pripremao/la sam/a';

  @override
  String get yearlyStatsStory7Part2 =>
      '...nego s korisnicima iz još 110\ndržava na 6 kontinenata!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Ostao/la si dosljedan/dosljedna i koristio/la samo ovih $count načina pripreme ove godine:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Otkrivao/la si nove okuse i koristio/la $count načina pripreme ove godine:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'Bio/la si pravi istraživač kave i koristio/la $count načina pripreme ove godine:';
  }

  @override
  String get yearlyStatsStory9Text => 'Toliko toga još za otkriti!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'Tvoja top 3 recepta u 2024. su bila$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'Vidimo se 2025.!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Pokaži malo ljubavi ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Doniraj';

  @override
  String get yearlyStatsActionShare => 'Podijeli tvoj napredak';

  @override
  String get yearlyStatsUnknown => 'Nepoznato';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Nije uspjelo dijeljenje: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Moja godina s Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes => 'Moja top 3 recepta:';

  @override
  String get yearlyStatsShareProgressTop3Roasters => 'Moje top 3 pržionice:';

  @override
  String get yearlyStatsFailedToLike =>
      'Označavanje sa \'Sviđa mi se\' nije uspjelo. Pokušaj ponovno.';

  @override
  String get labelCoffeeBrewed => 'Kavu pripremio/la';

  @override
  String get labelTastedBeansBy => 'Kušana zrna od';

  @override
  String get labelDiscoveredCoffeeFrom => 'Otkrio/la kavu iz';

  @override
  String get labelUsedBrewingMethods => 'Korišteno';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pržionice',
      one: 'pržionica',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'države',
      one: 'država',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'načini pripreme',
      one: 'način pripreme',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Uredi recept';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Kreiraj recept';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Koraci recepta';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Naziv recepta';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Kratki opis';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Način pripreme';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Količina kave (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Količina vode (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Temperatura vode (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Finoća mljevenja';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel =>
      'Ukupno vrijeme pripreme:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Minute';

  @override
  String get recipeCreationScreenSecondsLabel => 'Sekunde';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Korak pripreme';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Korak pripreme $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Opis koraka';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Vrijeme koraka: ';

  @override
  String get recipeCreationScreenRecipeNameValidator => 'Unesi naziv recepta';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Unesi kratak opis';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Odaberi način pripreme';

  @override
  String get recipeCreationScreenRequiredValidator => 'Obavezno';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Nevažeći broj';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Unesi opis koraka';

  @override
  String get recipeCreationScreenContinueButton => 'Nastavi korake recepta';

  @override
  String get recipeCreationScreenAddStepButton => 'Dodaj korak';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Snimi recept';

  @override
  String get recipeCreationScreenUpdateSuccess => 'Recept je uspješno ažuriran';

  @override
  String get recipeCreationScreenSaveSuccess => 'Recept je uspješno spremljen';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Greška pri spremanju recepta: $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'grama';

  @override
  String get unitMillilitersLong => 'mililitara';

  @override
  String get recipeCopySuccess => 'Recept je uspješno kopiran!';

  @override
  String get recipeDuplicateSuccess => 'Recept je uspješno dupliciran!';

  @override
  String recipeCopyError(String error) {
    return 'Greška pri kopiranju recepta: $error';
  }

  @override
  String get createRecipe => 'Kreiraj recept';

  @override
  String errorSyncingData(Object error) {
    return 'Greška pri sinkronizaciji podataka: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Greška pri odjavi: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Priprema';

  @override
  String get loadingEllipsis => 'Učitavanje...';

  @override
  String get recipeDeletedSuccess => 'Recept uspješno izbrisan';

  @override
  String recipeDeleteError(Object error) {
    return 'Neuspješno brisanje recepta: $error';
  }

  @override
  String get noRecipesFound => 'Nema pronađenih recepata';

  @override
  String recipeLoadError(Object error) {
    return 'Neuspjelo učitavanje recepta: $error';
  }

  @override
  String get unknownBrewingMethod => 'Nepoznat način pripreme';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Nije uspjelo učitavanje kopiranog recepta za uređivanje.';

  @override
  String get recipeCopyErrorOperationFailed => 'Operacija nije uspjela.';

  @override
  String get notProvided => 'Nije navedeno';

  @override
  String get recipeUpdateFailedFetch =>
      'Nije uspjelo dohvaćanje ažuriranih podataka recepta.';

  @override
  String get recipeImportSuccess => 'Recept je uspješno uvezen!';

  @override
  String get recipeImportFailedSave =>
      'Nije uspjelo spremanje uvezenog recepta.';

  @override
  String get recipeImportFailedFetch =>
      'Nije uspjelo dohvaćanje podataka recepta za uvoz.';

  @override
  String get recipeNotImported => 'Recept nije uvezen.';

  @override
  String get recipeNotFoundCloud =>
      'Recept nije pronađen u oblaku ili nije javan.';

  @override
  String get recipeLoadErrorGeneric => 'Greška pri učitavanju recepta.';

  @override
  String get recipeUpdateAvailableTitle => 'Dostupno ažuriranje';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'Novija verzija \'$recipeName\' dostupna je online. Ažurirati?';
  }

  @override
  String get dialogCancel => 'Odustani';

  @override
  String get dialogDuplicate => 'Dupliciraj';

  @override
  String get dialogUpdate => 'Ažuriraj';

  @override
  String get recipeImportTitle => 'Uvezi recept';

  @override
  String recipeImportBody(String recipeName) {
    return 'Želiš li uvesti recept \'$recipeName\' iz oblaka?';
  }

  @override
  String get dialogImport => 'Uvezi';

  @override
  String get moderationReviewNeededTitle => 'Potrebna je moderacija';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'Sljedeći recept(i) zahtijevaju pregled zbog problema s moderiranjem sadržaja: $recipeNames';
  }

  @override
  String get dismiss => 'Zanemari';

  @override
  String get reviewRecipeButton => 'Recenzija recepta';

  @override
  String get signInRequiredTitle => 'Potrebna je prijava';

  @override
  String get signInRequiredBodyShare =>
      'Za dijeljenje vlastitih recepata potrebno je prijaviti se.';

  @override
  String get syncSuccess => 'Sinkronizacija uspješna!';

  @override
  String get tooltipEditRecipe => 'Uredi recept';

  @override
  String get tooltipCopyRecipe => 'Kopiraj recept';

  @override
  String get tooltipDuplicateRecipe => 'Dupliciraj recept';

  @override
  String get tooltipShareRecipe => 'Podijeli recept';

  @override
  String get signInRequiredSnackbar => 'Potrebna je prijava';

  @override
  String get moderationErrorFunction =>
      'Provjera moderiranja sadržaja nije uspjela.';

  @override
  String get moderationReasonDefault => 'Sadržaj je označen za pregled.';

  @override
  String get moderationFailedTitle => 'Moderiranje nije uspjelo';

  @override
  String moderationFailedBody(String reason) {
    return 'Ovaj recept se ne može dijeliti jer: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Greška pri dijeljenju recepta: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName na Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'Nije moguće provjeriti status sadržaja. Spremljeno lokalno; provjerit ćemo pri sljedećoj sinkronizaciji.';

  @override
  String get saveLocallyModerationFailedTitle => 'Promjene spremljene lokalno';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Tvoje lokalne promjene su spremljene, ali javna verzija nije mogla biti ažurirana zbog moderiranja sadržaja: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Uredi uvezeni recept';

  @override
  String get editImportedRecipeBody =>
      'Ovo je uvezeni recept. Uređivanjem će se kreirati nova, neovisna kopija. Želiš li nastaviti?';

  @override
  String get editImportedRecipeButtonCopy => 'Kreiraj Kopiraj & Uredi';

  @override
  String get editImportedRecipeButtonCancel => 'Odustani';

  @override
  String get editDisplayNameTitle => 'Uredi ime';

  @override
  String get displayNameHint => 'Unesite svoje ime';

  @override
  String get displayNameEmptyError => 'Ime ne može biti prazno';

  @override
  String get displayNameTooLongError => 'Ime ne smije imati više od 50 znakova';

  @override
  String get errorUserNotLoggedIn =>
      'Korisnik nije prijavljen. Prijavi se ponovno.';

  @override
  String get displayNameUpdateSuccess => 'Ime je uspješno ažurirano!';

  @override
  String displayNameUpdateError(String error) {
    return 'Nije uspjelo ažuriranje imena: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Izbriši sliku?';

  @override
  String get deletePictureConfirmationBody =>
      'Jeste li sigurni da želite izbrisati svoju profilnu sliku?';

  @override
  String get deletePictureSuccess => 'Profilna slika je izbrisana.';

  @override
  String deletePictureError(String error) {
    return 'Nije uspjelo brisanje profilne slike: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Nije uspjelo ažuriranje profilne slike: $error';
  }

  @override
  String get updatePictureSuccess => 'Profilna slika je uspješno ažurirana!';

  @override
  String get deletePictureTooltip => 'Izbriši sliku';

  @override
  String get account => 'Račun';

  @override
  String get settingsBrewingMethodsTitle =>
      'Načini pripreme na početnom zaslonu';

  @override
  String get filter => 'Filter';

  @override
  String get sortBy => 'Sortiraj prema';

  @override
  String get dateAdded => 'Datum dodavanja';

  @override
  String get secondsAbbreviation => 's.';

  @override
  String get settingsAppIcon => 'Ikona aplikacije';

  @override
  String get settingsAppIconDefault => 'Zadano';

  @override
  String get settingsAppIconLegacy => 'Klasična';

  @override
  String get searchBeans => 'Pretraži zrna...';

  @override
  String get favorites => 'Favoriti';

  @override
  String get searchPrefix => 'Pretraži: ';

  @override
  String get clearAll => 'Očisti sve';

  @override
  String get noBeansMatchSearch => 'Nijedna zrna ne odgovaraju tvojoj pretrazi';

  @override
  String get clearFilters => 'Očisti filtere';

  @override
  String get farmer => 'Uzgajivač';

  @override
  String get farm => 'Plantaža';

  @override
  String get enterFarmer => 'Unesi uzgajivača (neobavezno)';

  @override
  String get enterFarm => 'Unesi plantažu (neobavezno)';

  @override
  String get requiredInformation => 'Potrebne informacije';

  @override
  String get basicDetails => 'Osnovni detalji';

  @override
  String get qualityMeasurements => 'Kvaliteta i mjerenja';

  @override
  String get importantDates => 'Važni datumi';

  @override
  String get brewStats => 'Statistika pripreme';

  @override
  String get showMore => 'Prikaži više';

  @override
  String get showLess => 'Prikaži manje';

  @override
  String get unpublishRecipeDialogTitle => 'Učini recept privatnim';

  @override
  String get unpublishRecipeDialogMessage =>
      'Upozorenje: Ako ovaj recept učinite privatnim:';

  @override
  String get unpublishRecipeDialogBullet1 =>
      'Uklonit će se iz javnih rezultata pretraživanja';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'Spriječiti ćete uvoz novim korisnicima';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'Korisnici koji su ga već uvezli zadržat će svoje kopije';

  @override
  String get unpublishRecipeDialogKeepPublic => 'Zadrži javnim';

  @override
  String get unpublishRecipeDialogMakePrivate => 'Napravi privatnim';

  @override
  String get recipeUnpublishSuccess =>
      'Objavljivanje recepta uspješno poništeno';

  @override
  String recipeUnpublishError(String error) {
    return 'Poništavanje objave recepta nije uspjelo: $error';
  }

  @override
  String get recipePublicTooltip =>
      'Recept je javan – dodirni za postavljanje na privatno';

  @override
  String get recipePrivateTooltip =>
      'Recept je privatan – podijeli da bi postao javan';

  @override
  String get fieldClearButtonTooltip => 'Obriši';

  @override
  String get dateFieldClearButtonTooltip => 'Obriši datum';

  @override
  String get chipInputDuplicateError => 'Ova oznaka je već dodana';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return 'Dosegnut je maksimalni broj oznaka ($maxChips)';
  }

  @override
  String get chipInputHintText => 'Dodaj oznaku...';

  @override
  String get unitFieldRequiredError => 'Ovo polje je obavezno';

  @override
  String get unitFieldInvalidNumberError => 'Unesite važeći broj';

  @override
  String unitFieldMinValueError(Object min) {
    return 'Vrijednost mora biti najmanje $min';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return 'Vrijednost mora biti najviše $max';
  }

  @override
  String get numericFieldRequiredError => 'Ovo polje je obavezno';

  @override
  String get numericFieldInvalidNumberError => 'Unesite važeći broj';

  @override
  String numericFieldMinValueError(Object min) {
    return 'Vrijednost mora biti najmanje $min';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return 'Vrijednost mora biti najviše $max';
  }

  @override
  String get dropdownSearchHintText => 'Upišite za pretraživanje...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return 'Greška pri učitavanju prijedloga: $error';
  }

  @override
  String get dropdownSearchNoResults => 'Nema pronađenih rezultata';

  @override
  String get dropdownSearchLoading => 'Pretraživanje...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return 'Koristi $currentQuery';
  }

  @override
  String get requiredInfoSubtitle => '* Obavezno';

  @override
  String get inventoryWeightExample => 'npr., 250.5';

  @override
  String get unsavedChangesTitle => 'Nespremljene promjene';

  @override
  String get unsavedChangesMessage =>
      'Imate nespremljene promjene. Jeste li sigurni da ih želite odbaciti?';

  @override
  String get unsavedChangesStay => 'Ostani';

  @override
  String get unsavedChangesDiscard => 'Odbaci';

  @override
  String beansWeightAddedBack(
      String amount, String beanName, String newWeight, String unit) {
    return 'Dodano $amount$unit natrag u $beanName. Nova težina: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
      String amount, String beanName, String newWeight, String unit) {
    return 'Oduzeto $amount$unit od $beanName. Nova težina: $newWeight$unit';
  }

  @override
  String get notifications => 'Obavijesti';

  @override
  String get notificationsDisabledInSystemSettings =>
      'Onemogućeno u sistemskim postavkama';

  @override
  String get openSettings => 'Otvori postavke';

  @override
  String get couldNotOpenLink => 'Nije moguće otvoriti poveznicu';

  @override
  String get notificationsDisabledDialogTitle =>
      'Obavijesti onemogućene u sistemskim postavkama';

  @override
  String get notificationsDisabledDialogContent =>
      'Onemogućili ste obavijesti u postavkama uređaja. Da biste omogućili obavijesti, molimo otvorite postavke uređaja i dozvolite obavijesti za Timer.Coffee.';

  @override
  String get notificationDebug => 'Otklanjanje grešaka obavijesti';

  @override
  String get testNotificationSystem => 'Testiraj sustav obavijesti';

  @override
  String get notificationsEnabled => 'Omogućeno';

  @override
  String get notificationsDisabled => 'Onemogućeno';

  @override
  String get notificationPermissionDialogTitle => 'Omogućiti obavijesti?';

  @override
  String get notificationPermissionDialogMessage =>
      'Možete omogućiti obavijesti da biste dobili korisne ažuriranja (npr. o novim verzijama aplikacije). Omogućite sada ili promijenite ovo bilo kada u postavkama.';

  @override
  String get notificationPermissionEnable => 'Omogući';

  @override
  String get notificationPermissionSkip => 'Ne sada';

  @override
  String get holidayGiftBoxTitle => 'Blagdanska poklon kutija';

  @override
  String get holidayGiftBoxInfoTrigger => 'Što je ovo?';

  @override
  String get holidayGiftBoxInfoBody =>
      'Sezonske ponude naših partnera. Linkovi nisu partnerski - želimo samo donijeti malo radosti korisnicima Timer.Coffee u ove blagdane. Povucite za osvježavanje u bilo kojem trenutku.';

  @override
  String get holidayGiftBoxNoOffers => 'Trenutno nema dostupnih ponuda.';

  @override
  String get holidayGiftBoxNoOffersSub =>
      'Povucite za osvježavanje ili pokušajte kasnije.';

  @override
  String holidayGiftBoxShowingRegion(String region) {
    return 'Prikazuju se ponude za $region';
  }

  @override
  String get holidayGiftBoxViewDetails => 'Pogledaj detalje';

  @override
  String get holidayGiftBoxPromoCopied => 'Promo kod kopiran';

  @override
  String get holidayGiftBoxPromoCode => 'Promo kod';

  @override
  String giftDiscountOff(String percent) {
    return '$percent% popusta';
  }

  @override
  String giftDiscountUpToOff(String percent) {
    return 'Do $percent% popusta';
  }

  @override
  String get holidayGiftBoxTerms => 'Uvjeti i odredbe';

  @override
  String get holidayGiftBoxVisitSite => 'Posjeti stranicu partnera';

  @override
  String holidayGiftBoxValidUntil(String date) {
    return 'Vrijedi do $date';
  }

  @override
  String get holidayGiftBoxValidWhileAvailable => 'Vrijedi dok traje zaliha';

  @override
  String holidayGiftBoxUpdated(String date) {
    return 'Ažurirano $date';
  }

  @override
  String holidayGiftBoxLanguage(String language) {
    return 'Jezik: $language';
  }

  @override
  String get holidayGiftBoxRetry => 'Pokušaj ponovo';

  @override
  String get holidayGiftBoxLoadFailed => 'Neuspjelo učitavanje ponuda';

  @override
  String get holidayGiftBoxOfferUnavailable => 'Ponuda nije dostupna';

  @override
  String get holidayGiftBoxBannerTitle => 'Pogledaj naš blagdanski gift box';

  @override
  String get holidayGiftBoxBannerCta => 'Vidi ponude';

  @override
  String get regionEurope => 'Europa';

  @override
  String get regionNorthAmerica => 'Sjeverna Amerika';

  @override
  String get regionAsia => 'Azija';

  @override
  String get regionAustralia => 'Australija / Oceanija';

  @override
  String get regionWorldwide => 'Cijeli svijet';

  @override
  String get regionAfrica => 'Afrika';

  @override
  String get regionMiddleEast => 'Bliski istok';

  @override
  String get regionSouthAmerica => 'Južna Amerika';
}
