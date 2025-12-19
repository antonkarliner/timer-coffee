// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'Papujen tilastot';

  @override
  String get totalBeansBrewedLabel => 'Valmistettuja papuja yhteensä';

  @override
  String get newBeansTriedLabel => 'Uusia papuja kokeiltu';

  @override
  String get originsExploredLabel => 'Tutkitut alkuperämaat';

  @override
  String get regionsExploredLabel => 'Eurooppa';

  @override
  String get newRoastersDiscoveredLabel => 'Löydetyt uudet paahtimot';

  @override
  String get favoriteRoastersLabel => 'Suosikkipaahtimot';

  @override
  String get topOriginsLabel => 'Parhaat alkuperämaat';

  @override
  String get topRegionsLabel => 'Parhaat alueet';

  @override
  String get lastrecipe => 'Viimeksi käytetty resepti:';

  @override
  String get userRecipesTitle => 'Omat reseptit';

  @override
  String get userRecipesSectionCreated => 'Tekemäsi';

  @override
  String get userRecipesSectionImported => 'Tuomasi';

  @override
  String get userRecipesEmpty => 'Reseptejä ei löytynyt';

  @override
  String get userRecipesDeleteTitle => 'Poistetaanko resepti?';

  @override
  String get userRecipesDeleteMessage => 'Tätä toimintoa ei voi kumota.';

  @override
  String get userRecipesDeleteConfirm => 'Poista';

  @override
  String get userRecipesDeleteCancel => 'Peruuta';

  @override
  String get userRecipesSnackbarDeleted => 'Resepti poistettu';

  @override
  String get hubUserRecipesTitle => 'Omat reseptit';

  @override
  String get hubUserRecipesSubtitle =>
      'Näytä ja hallitse luotuja ja tuotuja reseptejä';

  @override
  String get hubAccountSubtitle => 'Hallitse profiiliasi';

  @override
  String get hubSignInCreateSubtitle =>
      'Kirjaudu sisään synkronoidaksesi reseptit ja asetukset';

  @override
  String get hubBrewDiarySubtitle =>
      'Katso valmistushistoriasi ja lisää muistiinpanoja';

  @override
  String get hubBrewStatsSubtitle =>
      'Näytä henkilökohtaiset ja globaalit valmistusstatistiikat ja trendit';

  @override
  String get hubSettingsSubtitle => 'Vaihda sovelluksen asetuksia ja toimintaa';

  @override
  String get hubAboutSubtitle => 'Sovelluksen tiedot, versio ja osallistujat';

  @override
  String get about => 'Tietoja';

  @override
  String get author => 'Tekijä';

  @override
  String get authortext =>
      'Timer.Coffee -sovelluksen on luonut kahviharrastaja Anton Karliner, ja sen tarkoitus on auttaa sinua nauttimaan kahvistasi entistä enemmän. Voit osallistua kehitykseen GitHubissa.';

  @override
  String get contributors => 'Avustajat';

  @override
  String get errorLoadingContributors => 'Avustajien lataus epäonnistui';

  @override
  String get license => 'Lisenssi';

  @override
  String get licensetext =>
      'Tämä sovellus on vapaa ohjelmisto: voit levittää sitä edelleen ja/tai muokata sitä GNU General Public License -lisenssin version 3 tai (valintasi mukaan) minkä tahansa myöhemmän version ehtojen mukaisesti.';

  @override
  String get licensebutton => 'Lue GNU General Public License v3';

  @override
  String get website => 'Verkkosivusto';

  @override
  String get sourcecode => 'Lähdekoodi';

  @override
  String get support => 'Tarjoa minulle kahvi';

  @override
  String get allrecipes => 'Kaikki reseptit';

  @override
  String get favoriterecipes => 'Suosikkireseptit';

  @override
  String get coffeeamount => 'Kahvimäärä (g)';

  @override
  String get wateramount => 'Vesimäärä (ml)';

  @override
  String get watertemp => 'Veden lämpötila';

  @override
  String get grindsize => 'Jauhatuksen karkeus';

  @override
  String get brewtime => 'Uuttoaika';

  @override
  String get recipesummary => 'Reseptin yhteenveto';

  @override
  String get recipesummarynote =>
      'Huom: Tämä on perusresepti oletusvesi- ja kahvimäärillä.';

  @override
  String get preparation => 'Valmistelu';

  @override
  String get brewingprocess => 'Valmistusprosessi';

  @override
  String get step => 'Vaihe';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sekuntia',
      one: 'sekunti',
      zero: 'sekuntia',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg => 'Kiitos, että käytät Timer.Coffeea! Nauti';

  @override
  String get coffeefact => 'Kahvitieto';

  @override
  String get home => 'Koti';

  @override
  String get appversion => 'Sovellusversio';

  @override
  String get tipsmall => 'Osta pieni kahvi';

  @override
  String get tipmedium => 'Osta keskikokoinen kahvi';

  @override
  String get tiplarge => 'Osta iso kahvi';

  @override
  String get supportdevelopment => 'Tue kehitystä';

  @override
  String get supportdevmsg =>
      'Lahjoituksesi auttavat kattamaan ylläpitokustannukset ja mahdollistavat uusien kahvinkeitinlaitteiden hankinnan sekä reseptien lisäämisen sovellukseen.';

  @override
  String get supportdevtnx => 'Kiitos, että harkitset lahjoitusta!';

  @override
  String get donationok => 'Kiitos!';

  @override
  String get donationtnx =>
      'Arvostan tukeasi! Toivotan paljon hyviä uuttoja! ☕️';

  @override
  String get donationerr => 'Virhe';

  @override
  String get donationerrmsg => 'Maksun käsittely epäonnistui, yritä uudelleen.';

  @override
  String get sharemsg => 'Katso tämä resepti:';

  @override
  String get finishbrew => 'Valmis';

  @override
  String get settings => 'Asetukset';

  @override
  String get settingstheme => 'Teema';

  @override
  String get settingsthemelight => 'Vaalea';

  @override
  String get settingsthemedark => 'Tumma';

  @override
  String get settingsthemesystem => 'Järjestelmä';

  @override
  String get settingslang => 'Kieli';

  @override
  String get sweet => 'Makea';

  @override
  String get balance => 'Tasapainoinen';

  @override
  String get acidic => 'Hapokas';

  @override
  String get light => 'Kevyt';

  @override
  String get strong => 'Vahva';

  @override
  String get slidertitle => 'Säädä makua liu\'uttamalla';

  @override
  String get whatsnewtitle => 'Mitä uutta';

  @override
  String get whatsnewclose => 'Sulje';

  @override
  String get seasonspecials => 'Kauden erikoisuudet';

  @override
  String get snow => 'Lumi';

  @override
  String get noFavoriteRecipesMessage =>
      'Suosikkireseptiesi lista on tyhjä. Aloita tutkiminen ja uuttaminen löytääksesi suosikkisi!';

  @override
  String get explore => 'Tutki';

  @override
  String get dateFormat => 'd. MMM yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Uuttopäiväkirja';

  @override
  String get brewdiarynotfound => 'Ei merkintöjä';

  @override
  String get beans => 'Pavut';

  @override
  String get roaster => 'Paahtimo';

  @override
  String get rating => 'Arvostelu';

  @override
  String get notes => 'Muistiinpanot';

  @override
  String get statsscreen => 'Kahvitilastot';

  @override
  String get yourStats => 'Omat tilastot';

  @override
  String get coffeeBrewed => 'Kahvia uutettu:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'Eniten käytetyt reseptit:';

  @override
  String get globalStats => 'Maailman tilastot';

  @override
  String get unknownRecipe => 'Tuntematon resepti';

  @override
  String get noData => 'Ei dataa';

  @override
  String error(String error) {
    return 'Virhe: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Joku juuri valmisti $recipeName';
  }

  @override
  String get timePeriodToday => 'Tänään';

  @override
  String get timePeriodThisWeek => 'Tällä viikolla';

  @override
  String get timePeriodThisMonth => 'Tässä kuussa';

  @override
  String get timePeriodCustom => 'Mukautettu';

  @override
  String get statsFor => 'Tilastot kohteelle ';

  @override
  String get homescreenbrewcoffee => 'Valmista kahvi';

  @override
  String get homescreenhub => 'Hubi';

  @override
  String get homescreenmore => 'Lisää';

  @override
  String get addBeans => 'Lisää pavut';

  @override
  String get removeBeans => 'Poista pavut';

  @override
  String get name => 'Nimi';

  @override
  String get origin => 'Alkuperä';

  @override
  String get details => 'Lisätiedot';

  @override
  String get coffeebeans => 'Kahvipavut';

  @override
  String get loading => 'Ladataan';

  @override
  String get nocoffeebeans => 'Kahvipapuja ei löytynyt';

  @override
  String get delete => 'Poista';

  @override
  String get confirmDeleteTitle => 'Poista merkintä?';

  @override
  String get recipeDuplicateConfirmTitle => 'Monistetaanko resepti?';

  @override
  String get recipeDuplicateConfirmMessage =>
      'Tämä luo kopion reseptistäsi, jota voit muokata itsenäisesti. Haluatko jatkaa?';

  @override
  String get confirmDeleteMessage =>
      'Haluatko varmasti poistaa tämän merkinnän? Tätä toimintoa ei voi perua.';

  @override
  String get removeFavorite => 'Poista suosikeista';

  @override
  String get addFavorite => 'Lisää suosikkeihin';

  @override
  String get toggleEditMode => 'Vaihda muokkaustilaa';

  @override
  String get coffeeBeansDetails => 'Kahvipapujen tiedot';

  @override
  String get edit => 'Muokkaa';

  @override
  String get coffeeBeansNotFound => 'Kahvipapuja ei löytynyt';

  @override
  String get basicInformation => 'Perustiedot';

  @override
  String get geographyTerroir => 'Maantiede/Terroir';

  @override
  String get variety => 'Lajike';

  @override
  String get region => 'Pohjois-Amerikka';

  @override
  String get elevation => 'Kasvukorkeus';

  @override
  String get harvestDate => 'Sadonkorjuupäivä';

  @override
  String get processing => 'Prosessointi';

  @override
  String get processingMethod => 'Prosessointimenetelmä';

  @override
  String get roastDate => 'Paahtopäivä';

  @override
  String get roastLevel => 'Paahtoaste';

  @override
  String get cuppingScore => 'Cupping-pisteet';

  @override
  String get flavorProfile => 'Makuprofiili';

  @override
  String get tastingNotes => 'Maku- ja tuoksuvihjeet';

  @override
  String get additionalNotes => 'Lisähuomiot';

  @override
  String get noCoffeeBeans => 'Kahvipapuja ei löytynyt';

  @override
  String get editCoffeeBeans => 'Muokkaa kahvipapuja';

  @override
  String get addCoffeeBeans => 'Lisää kahvipapuja';

  @override
  String get showImagePicker => 'Näytä kuvavalitsin';

  @override
  String get pleaseNote => 'Huomaa';

  @override
  String get firstTimePopupMessage =>
      '1. Käytämme ulkoisia palveluita kuvien käsittelyyn. Jatkamalla hyväksyt tämän.\n2. Emme tallenna kuviasi, vältä henkilökohtaisten tietojen sisällyttämistä.\n3. Kuvantunnistus on tällä hetkellä rajoitetussa testissä.';

  @override
  String get ok => 'OK';

  @override
  String get takePhoto => 'Ota kuva';

  @override
  String get selectFromPhotos => 'Valitse kuvista';

  @override
  String get takeAdditionalPhoto => 'Otatko lisäkuvan?';

  @override
  String get no => 'Ei';

  @override
  String get yes => 'Kyllä';

  @override
  String get selectedImages => 'Valitut kuvat';

  @override
  String get selectedImage => 'Valittu kuva';

  @override
  String get backToSelection => 'Takaisin valintaan';

  @override
  String get next => 'Seuraava';

  @override
  String get unexpectedErrorOccurred => 'Odottamaton virhe';

  @override
  String get tokenLimitReached =>
      'Pahoittelut, olet saavuttanut tämän kuun kuvantunnistuksen tunnisterajan';

  @override
  String get noCoffeeLabelsDetected =>
      'Kahvipakkauksia ei havaittu. Kokeile toista kuvaa.';

  @override
  String get collectedInformation => 'Kerätyt tiedot';

  @override
  String get enterRoaster => 'Syötä paahtimo';

  @override
  String get enterName => 'Syötä nimi';

  @override
  String get enterOrigin => 'Syötä alkuperä';

  @override
  String get optional => 'Valinnainen';

  @override
  String get enterVariety => 'Syötä lajike';

  @override
  String get enterProcessingMethod => 'Syötä prosessointimenetelmä';

  @override
  String get enterRoastLevel => 'Syötä paahtoaste';

  @override
  String get enterRegion => 'Syötä alue';

  @override
  String get enterTastingNotes => 'Syötä tasting-muistiinpanot';

  @override
  String get enterElevation => 'Syötä kasvukorkeus';

  @override
  String get enterCuppingScore => 'Syötä cupping-pisteet';

  @override
  String get enterNotes => 'Syötä muistiinpanot';

  @override
  String get inventory => 'Varasto';

  @override
  String get amountLeft => 'Jäljellä';

  @override
  String get enterAmountLeft => 'Syötä jäljellä oleva määrä';

  @override
  String get selectHarvestDate => 'Valitse sadonkorjuupäivä';

  @override
  String get selectRoastDate => 'Valitse paahtopäivä';

  @override
  String get selectDate => 'Valitse päivämäärä';

  @override
  String get save => 'Tallenna';

  @override
  String get fillRequiredFields => 'Täytä kaikki pakolliset kentät.';

  @override
  String get analyzing => 'Analysoidaan';

  @override
  String get errorMessage => 'Virhe';

  @override
  String get selectCoffeeBeans => 'Valitse kahvipavut';

  @override
  String get addNewBeans => 'Lisää uudet pavut';

  @override
  String get favorite => 'Suosikki';

  @override
  String get notFavorite => 'Ei suosikki';

  @override
  String get myBeans => 'Omat pavut';

  @override
  String get signIn => 'Kirjaudu sisään';

  @override
  String get signOut => 'Kirjaudu ulos';

  @override
  String get signInWithApple => 'Kirjaudu Applella';

  @override
  String get signInSuccessful => 'Kirjautuminen Applella onnistui';

  @override
  String get signInError => 'Virhe Apple-kirjautumisessa';

  @override
  String get signInWithGoogle => 'Kirjaudu Googlella';

  @override
  String get signOutSuccessful => 'Uloskirjautuminen onnistui';

  @override
  String get signInSuccessfulGoogle => 'Kirjautuminen Googlella onnistui';

  @override
  String get signInWithEmail => 'Kirjaudu sähköpostilla';

  @override
  String get enterEmail => 'Syötä sähköpostiosoitteesi';

  @override
  String get emailHint => 'esimerkki@sähköposti.com';

  @override
  String get cancel => 'Peruuta';

  @override
  String get sendMagicLink => 'Lähetä taikalinkki';

  @override
  String get magicLinkSent => 'Taikalinkki lähetetty! Tarkista sähköpostisi.';

  @override
  String get sendOTP => 'Lähetä kertakäyttökoodi';

  @override
  String get otpSent => 'Kertakäyttökoodi lähetetty sähköpostiisi';

  @override
  String get otpSendError => 'Koodin lähetys epäonnistui';

  @override
  String get enterOTP => 'Syötä kertakäyttökoodi';

  @override
  String get otpHint => 'Syötä 6-numeroinen koodi';

  @override
  String get verify => 'Vahvista';

  @override
  String get signInSuccessfulEmail => 'Kirjautuminen onnistui';

  @override
  String get invalidOTP => 'Virheellinen koodi';

  @override
  String get otpVerificationError => 'Koodin vahvistus epäonnistui';

  @override
  String get success => 'Onnistui!';

  @override
  String get otpSentMessage =>
      'Kertakäyttöinen koodi lähetetään sähköpostiisi. Syötä se alla, kun se saapuu.';

  @override
  String get otpHint2 => 'Syötä koodi tähän';

  @override
  String get signInCreate => 'Kirjaudu / Luo tili';

  @override
  String get accountManagement => 'Tilinhallinta';

  @override
  String get deleteAccount => 'Poista tili';

  @override
  String get deleteAccountWarning =>
      'Huomio: Jos jatkat, poistamme tilisi ja siihen liittyvät tiedot pysyvästi palvelimiltamme. Laitteellesi jää paikallinen kopio; jos haluat poistaa senkin, poista sovellus. Jos haluat synkronoinnin uudelleen, sinun on luotava uusi tili.';

  @override
  String get deleteAccountConfirmation => 'Tili poistettu onnistuneesti';

  @override
  String get accountDeleted => 'Tili poistettu';

  @override
  String get accountDeletionError =>
      'Tilin poistaminen epäonnistui, yritä uudelleen';

  @override
  String get deleteAccountTitle => 'Tärkeää';

  @override
  String get selectBeans => 'Valitse pavut';

  @override
  String get all => 'Kaikki';

  @override
  String get selectRoaster => 'Valitse paahtimo';

  @override
  String get selectOrigin => 'Valitse alkuperä';

  @override
  String get resetFilters => 'Tyhjennä suodattimet';

  @override
  String get showFavoritesOnly => 'Näytä vain suosikit';

  @override
  String get apply => 'Käytä';

  @override
  String get selectSize => 'Valitse koko';

  @override
  String get sizeStandard => 'Normaali';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Vuoteni Timer.Coffee:ssa';

  @override
  String get yearlyStatsStory1Text =>
      'Kiitos, että olit osa Timer.Coffee-universumia tänä vuonna!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'Ensimmäiseksi.\nValmistit tänä vuonna kahvia$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'Tarkemmin sanottuna\nvalmistit $liters litraa kahvia vuonna 2024!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'Käytit papuja $roasterCount paahtimolta';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Top 3 -paahtimosi olivat:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Kahvi vei sinut matkalle\nympäri maailmaa$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'Maistoit kahvipapuja\n$originCount maasta!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Et ollut ainoa, joka uutti…';

  @override
  String get yearlyStatsStory7Part2 =>
      '...vaan kanssasi oli käyttäjiä 110 muusta\nmaasta kuudelta mantereelta!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Pysyttelit omassa tyylissäsi ja käytit vain näitä $count valmistusmenetelmää tänä vuonna:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Kokeilit uusia makuja ja käytit $count valmistusmenetelmää tänä vuonna:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'Olit todellinen kahvintutkija ja käytit $count valmistusmenetelmää tänä vuonna:';
  }

  @override
  String get yearlyStatsStory9Text => 'Niin paljon muuta löydettävää!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'Top 3 -reseptisi vuonna 2024 olivat$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'Nähdään 2025!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Näytä tykkäyksesi ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Lahjoita';

  @override
  String get yearlyStatsActionShare => 'Jaa edistymisesi';

  @override
  String get yearlyStatsUnknown => 'Tuntematon';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Jakaminen epäonnistui: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Vuoteni Timer.Coffee:ssa';

  @override
  String get yearlyStatsShareProgressTop3Recipes => 'Top 3 -reseptini:';

  @override
  String get yearlyStatsShareProgressTop3Roasters => 'Top 3 -paahtimoni:';

  @override
  String get yearlyStatsFailedToLike => 'Tykkäys epäonnistui. Yritä uudelleen.';

  @override
  String get labelCoffeeBrewed => 'Kahvia uutettu';

  @override
  String get labelTastedBeansBy => 'Papuja maistellut';

  @override
  String get labelDiscoveredCoffeeFrom => 'Löytänyt kahvia maasta';

  @override
  String get labelUsedBrewingMethods => 'Käytti';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'paahtimoa',
      one: 'paahtimo',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'maata',
      one: 'maa',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'valmistusmenetelmää',
      one: 'valmistusmenetelmä',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Muokkaa reseptiä';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Luo resepti';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Reseptin vaiheet';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Reseptin nimi';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Lyhyt kuvaus';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Valmistusmenetelmä';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Kahvimäärä (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Vesimäärä (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Veden lämpötila (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Jauhatuksen karkeus';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => 'Kokonaisaika:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Minuutit';

  @override
  String get recipeCreationScreenSecondsLabel => 'Sekunnit';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Valmisteluvaihe';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Uuttovaihe $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Vaiheen kuvaus';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Vaiheen aika: ';

  @override
  String get recipeCreationScreenRecipeNameValidator => 'Anna reseptin nimi';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Anna lyhyt kuvaus';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Valitse valmistusmenetelmä';

  @override
  String get recipeCreationScreenRequiredValidator => 'Pakollinen';

  @override
  String get recipeCreationScreenInvalidNumberValidator =>
      'Virheellinen numero';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Anna vaiheen kuvaus';

  @override
  String get recipeCreationScreenContinueButton => 'Jatka reseptin vaiheisiin';

  @override
  String get recipeCreationScreenAddStepButton => 'Lisää vaihe';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Tallenna resepti';

  @override
  String get recipeCreationScreenUpdateSuccess =>
      'Resepti päivitetty onnistuneesti';

  @override
  String get recipeCreationScreenSaveSuccess =>
      'Resepti tallennettu onnistuneesti';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Reseptin tallennus epäonnistui: $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'grammaa';

  @override
  String get unitMillilitersLong => 'millilitraa';

  @override
  String get recipeCopySuccess => 'Resepti kopioitu onnistuneesti!';

  @override
  String get recipeDuplicateSuccess => 'Resepti kopioitu onnistuneesti!';

  @override
  String recipeCopyError(String error) {
    return 'Reseptin kopiointi epäonnistui: $error';
  }

  @override
  String get createRecipe => 'Luo resepti';

  @override
  String errorSyncingData(Object error) {
    return 'Datan synkronointi epäonnistui: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Uloskirjautuminen epäonnistui: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Valmistelut';

  @override
  String get loadingEllipsis => 'Ladataan...';

  @override
  String get recipeDeletedSuccess => 'Resepti poistettu onnistuneesti';

  @override
  String recipeDeleteError(Object error) {
    return 'Reseptin poisto epäonnistui: $error';
  }

  @override
  String get noRecipesFound => 'Reseptejä ei löytynyt';

  @override
  String recipeLoadError(Object error) {
    return 'Reseptin lataus epäonnistui: $error';
  }

  @override
  String get unknownBrewingMethod => 'Tuntematon valmistusmenetelmä';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Kopioidun reseptin lataus muokkausta varten epäonnistui.';

  @override
  String get recipeCopyErrorOperationFailed => 'Toiminto epäonnistui.';

  @override
  String get notProvided => 'Ei annettu';

  @override
  String get recipeUpdateFailedFetch =>
      'Päivitettyjä reseptitietoja ei saatu noudettua.';

  @override
  String get recipeImportSuccess => 'Resepti tuotu onnistuneesti!';

  @override
  String get recipeImportFailedSave => 'Tuodun reseptin tallennus epäonnistui.';

  @override
  String get recipeImportFailedFetch => 'Reseptin tietoja ei saatu noudettua.';

  @override
  String get recipeNotImported => 'Reseptiä ei tuotu.';

  @override
  String get recipeNotFoundCloud =>
      'Reseptiä ei löytynyt pilvestä tai se ei ole julkinen.';

  @override
  String get recipeLoadErrorGeneric => 'Reseptin lataus epäonnistui.';

  @override
  String get recipeUpdateAvailableTitle => 'Päivitys saatavilla';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'Uudempi versio \"$recipeName\" on saatavilla verkossa. Päivitetäänkö?';
  }

  @override
  String get dialogCancel => 'Peruuta';

  @override
  String get dialogDuplicate => 'Monista';

  @override
  String get dialogUpdate => 'Päivitä';

  @override
  String get recipeImportTitle => 'Tuo resepti';

  @override
  String recipeImportBody(String recipeName) {
    return 'Haluatko tuoda reseptin \"$recipeName\" pilvestä?';
  }

  @override
  String get dialogImport => 'Tuo';

  @override
  String get moderationReviewNeededTitle => 'Moderaattorin tarkistus tarvitaan';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'Seuraavat reseptit vaativat tarkistuksen sisällön moderoinnin vuoksi: $recipeNames';
  }

  @override
  String get dismiss => 'Sulje';

  @override
  String get reviewRecipeButton => 'Tarkista resepti';

  @override
  String get signInRequiredTitle => 'Kirjautuminen tarvitaan';

  @override
  String get signInRequiredBodyShare =>
      'Sinun täytyy kirjautua jakaaksesi omia reseptejäsi.';

  @override
  String get syncSuccess => 'Synkronointi onnistui!';

  @override
  String get tooltipEditRecipe => 'Muokkaa reseptiä';

  @override
  String get tooltipCopyRecipe => 'Kopioi resepti';

  @override
  String get tooltipDuplicateRecipe => 'Monista resepti';

  @override
  String get tooltipShareRecipe => 'Jaa resepti';

  @override
  String get signInRequiredSnackbar => 'Kirjautuminen tarvitaan';

  @override
  String get moderationErrorFunction =>
      'Sisällön moderointitarkistus epäonnistui.';

  @override
  String get moderationReasonDefault => 'Sisältö merkitty tarkistettavaksi.';

  @override
  String get moderationFailedTitle => 'Moderointi epäonnistui';

  @override
  String moderationFailedBody(String reason) {
    return 'Tätä reseptiä ei voida jakaa, koska: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Reseptin jakaminen epäonnistui: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName – Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'Paikalliset muutokset tallennettu, mutta julkista versiota ei voitu päivittää: tarkista myöhemmin';

  @override
  String get saveLocallyModerationFailedTitle =>
      'Muutokset tallennettu paikallisesti';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Paikalliset muutokset on tallennettu, mutta julkista versiota ei voitu päivittää sisällön moderoinnin vuoksi: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Muokkaa tuotua reseptiä';

  @override
  String get editImportedRecipeBody =>
      'Tämä on tuotu resepti. Sen muokkaaminen luo uuden, itsenäisen kopion. Haluatko jatkaa?';

  @override
  String get editImportedRecipeButtonCopy => 'Luo kopio ja muokkaa';

  @override
  String get editImportedRecipeButtonCancel => 'Peruuta';

  @override
  String get editDisplayNameTitle => 'Muokkaa näyttönimeä';

  @override
  String get displayNameHint => 'Syötä näyttönimi';

  @override
  String get displayNameEmptyError => 'Näyttönimi ei saa olla tyhjä';

  @override
  String get displayNameTooLongError => 'Näyttönimi ei saa ylittää 50 merkkiä';

  @override
  String get errorUserNotLoggedIn =>
      'Käyttäjä ei ole kirjautunut sisään. Kirjaudu uudelleen.';

  @override
  String get displayNameUpdateSuccess => 'Näyttönimi päivitetty onnistuneesti!';

  @override
  String displayNameUpdateError(String error) {
    return 'Näyttönimen päivitys epäonnistui: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Poistetaanko kuva?';

  @override
  String get deletePictureConfirmationBody =>
      'Haluatko varmasti poistaa profiilikuvasi?';

  @override
  String get deletePictureSuccess => 'Profiilikuva poistettu.';

  @override
  String deletePictureError(String error) {
    return 'Profiilikuvan poistaminen epäonnistui: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Profiilikuvan päivitys epäonnistui: $error';
  }

  @override
  String get updatePictureSuccess => 'Profiilikuva päivitetty onnistuneesti!';

  @override
  String get deletePictureTooltip => 'Poista kuva';

  @override
  String get account => 'Tili';

  @override
  String get settingsBrewingMethodsTitle => 'Etusivun valmistusmenetelmät';

  @override
  String get filter => 'Suodatin';

  @override
  String get sortBy => 'Lajittele';

  @override
  String get dateAdded => 'Lisäyspäivämäärä';

  @override
  String get secondsAbbreviation => 's.';

  @override
  String get settingsAppIcon => 'Sovelluksen kuvake';

  @override
  String get settingsAppIconDefault => 'Oletus';

  @override
  String get settingsAppIconLegacy => 'Vanha';

  @override
  String get searchBeans => 'Etsi papuja...';

  @override
  String get favorites => 'Suosikit';

  @override
  String get searchPrefix => 'Haku: ';

  @override
  String get clearAll => 'Tyhjennä kaikki';

  @override
  String get noBeansMatchSearch => 'Yhtään papua ei löydy haullasi';

  @override
  String get clearFilters => 'Tyhjennä suodattimet';

  @override
  String get farmer => 'Viljelijä';

  @override
  String get farm => 'Kahvitila';

  @override
  String get enterFarmer => 'Syötä viljelijä';

  @override
  String get enterFarm => 'Syötä kahvitila';

  @override
  String get requiredInformation => 'Tarvittavat tiedot';

  @override
  String get basicDetails => 'Perustiedot';

  @override
  String get qualityMeasurements => 'Laadun mittaukset';

  @override
  String get importantDates => 'Tärkeitä päivämääriä';

  @override
  String get brewStats => 'Valmistustilastot';

  @override
  String get showMore => 'Näytä lisää';

  @override
  String get showLess => 'Näytä vähemmän';

  @override
  String get unpublishRecipeDialogTitle => 'Tee reseptistä yksityinen';

  @override
  String get unpublishRecipeDialogMessage =>
      'Varoitus: Tämän reseptin tekeminen yksityiseksi:';

  @override
  String get unpublishRecipeDialogBullet1 =>
      'Poistaa sen julkisista hakutuloksista';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'Estää uusia käyttäjiä tuomasta sitä';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'Käyttäjät, jotka ovat jo tuoneet sen, säilyttävät kopionsa';

  @override
  String get unpublishRecipeDialogKeepPublic => 'Pidä julkisena';

  @override
  String get unpublishRecipeDialogMakePrivate => 'Tee yksityiseksi';

  @override
  String get recipeUnpublishSuccess =>
      'Reseptin julkaisu poistettu onnistuneesti';

  @override
  String recipeUnpublishError(String error) {
    return 'Reseptin julkaisun poistaminen epäonnistui: $error';
  }

  @override
  String get recipePublicTooltip =>
      'Resepti on julkinen - napauta tehdäksesi siitä yksityisen';

  @override
  String get recipePrivateTooltip =>
      'Resepti on yksityinen - jaa tehdäksesi siitä julkisen';

  @override
  String get fieldClearButtonTooltip => 'Tyhjennä';

  @override
  String get dateFieldClearButtonTooltip => 'Tyhjennä päivämäärä';

  @override
  String get chipInputDuplicateError => 'Tämä tunniste on jo lisätty';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return 'Tunnisteiden enimmäismäärä saavutettu ($maxChips)';
  }

  @override
  String get chipInputHintText => 'Lisää tunniste...';

  @override
  String get unitFieldRequiredError => 'Tämä kenttä on pakollinen';

  @override
  String get unitFieldInvalidNumberError => 'Syötä kelvollinen numero';

  @override
  String unitFieldMinValueError(Object min) {
    return 'Arvon on oltava vähintään $min';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return 'Arvon on oltava enintään $max';
  }

  @override
  String get numericFieldRequiredError => 'Tämä kenttä on pakollinen';

  @override
  String get numericFieldInvalidNumberError => 'Syötä kelvollinen numero';

  @override
  String numericFieldMinValueError(Object min) {
    return 'Arvon on oltava vähintään $min';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return 'Arvon on oltava enintään $max';
  }

  @override
  String get dropdownSearchHintText => 'Kirjoita hakeaksesi...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return 'Virhe ehdotuksia ladatessa: $error';
  }

  @override
  String get dropdownSearchNoResults => 'Ei tuloksia';

  @override
  String get dropdownSearchLoading => 'Etsitään...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return 'Käytä \"$currentQuery\"';
  }

  @override
  String get requiredInfoSubtitle => '* Pakollinen';

  @override
  String get inventoryWeightExample => 'esim. 250.5';

  @override
  String get unsavedChangesTitle => 'Tallentamattomat muutokset';

  @override
  String get unsavedChangesMessage =>
      'Sinulla on tallentamattomia muutoksia. Oletko varma, että haluat hylätä ne?';

  @override
  String get unsavedChangesStay => 'Pysy';

  @override
  String get unsavedChangesDiscard => 'Hylkää';

  @override
  String beansWeightAddedBack(
      String amount, String beanName, String newWeight, String unit) {
    return 'Lisätty $amount$unit takaisin $beanName. Uusi paino: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
      String amount, String beanName, String newWeight, String unit) {
    return 'Vähennetty $amount$unit $beanName. Uusi paino: $newWeight$unit';
  }

  @override
  String get notifications => 'Ilmoitukset';

  @override
  String get notificationsDisabledInSystemSettings =>
      'Pois käytöstä järjestelmäasetuksissa';

  @override
  String get openSettings => 'Avaa asetukset';

  @override
  String get couldNotOpenLink => 'Linkkiä ei voitu avata';

  @override
  String get notificationsDisabledDialogTitle =>
      'Ilmoitukset pois käytöstä järjestelmäasetuksissa';

  @override
  String get notificationsDisabledDialogContent =>
      'Olet poistanut ilmoitukset laiteasetuksista. Ilmoitusten ottamiseksi käyttöön, avaa laiteasetuksesi ja salli ilmoitukset Timer.Coffee-sovellukselle.';

  @override
  String get notificationDebug => 'Ilmoitusten virheenjäljitys';

  @override
  String get testNotificationSystem => 'Testaa ilmoitusjärjestelmää';

  @override
  String get notificationsEnabled => 'Käytössä';

  @override
  String get notificationsDisabled => 'Pois käytöstä';

  @override
  String get notificationPermissionDialogTitle => 'Ota ilmoitukset käyttöön?';

  @override
  String get notificationPermissionDialogMessage =>
      'Voit ottaa ilmoitukset käyttöön saadaksesi hyödyllisiä päivityksiä (esim. uusista sovellusversioista). Ota käyttöön nyt tai muuta myöhemmin asetuksista.';

  @override
  String get notificationPermissionEnable => 'Ota käyttöön';

  @override
  String get notificationPermissionSkip => 'Ei nyt';

  @override
  String get holidayGiftBoxTitle => 'Joulun lahjaboksi';

  @override
  String get holidayGiftBoxInfoTrigger => 'Mikä tämä on?';

  @override
  String get holidayGiftBoxInfoBody =>
      'Kuratut kausitarjoukset kumppaneilta. Linkit eivät ole affiliate-linkkejä - haluamme vain tuoda hieman iloa Timer.Coffeen käyttäjille tänä juhlasesonkina. Päivitä vetämällä alas.';

  @override
  String get holidayGiftBoxNoOffers => 'Ei tarjouksia tällä hetkellä.';

  @override
  String get holidayGiftBoxNoOffersSub =>
      'Päivitä vetämällä tai kokeile myöhemmin.';

  @override
  String holidayGiftBoxShowingRegion(String region) {
    return 'Näytetään tarjouksia alueelle $region';
  }

  @override
  String get holidayGiftBoxViewDetails => 'Näytä tiedot';

  @override
  String get holidayGiftBoxPromoCopied => 'Alennuskoodi kopioitu';

  @override
  String get holidayGiftBoxPromoCode => 'Alennuskoodi';

  @override
  String giftDiscountOff(String percent) {
    return '$percent % alennus';
  }

  @override
  String giftDiscountUpToOff(String percent) {
    return 'Jopa $percent % alennus';
  }

  @override
  String get holidayGiftBoxTerms => 'Ehdot';

  @override
  String get holidayGiftBoxVisitSite => 'Vieraile kumppanin sivustolla';

  @override
  String holidayGiftBoxValidUntil(String date) {
    return 'Voimassa $date asti';
  }

  @override
  String holidayGiftBoxEndsInDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Päättyy $days päivän kuluttua',
      one: 'Päättyy huomenna',
      zero: 'Päättyy tänään',
    );
    return '$_temp0';
  }

  @override
  String get holidayGiftBoxValidWhileAvailable =>
      'Voimassa niin kauan kuin tuotteita riittää';

  @override
  String holidayGiftBoxUpdated(String date) {
    return 'Päivitetty $date';
  }

  @override
  String holidayGiftBoxLanguage(String language) {
    return 'Kieli: $language';
  }

  @override
  String get holidayGiftBoxRetry => 'Yritä uudelleen';

  @override
  String get holidayGiftBoxLoadFailed => 'Tarjousten lataus epäonnistui';

  @override
  String get holidayGiftBoxOfferUnavailable => 'Tarjous ei ole saatavilla';

  @override
  String get holidayGiftBoxBannerTitle => 'Tutustu lahjaboxiimme';

  @override
  String get holidayGiftBoxBannerCta => 'Katso tarjoukset';

  @override
  String get regionEurope => 'Eurooppa';

  @override
  String get regionNorthAmerica => 'Pohjois-Amerikka';

  @override
  String get regionAsia => 'Aasia';

  @override
  String get regionAustralia => 'Australia / Oseania';

  @override
  String get regionWorldwide => 'Koko maailma';

  @override
  String get regionAfrica => 'Afrikka';

  @override
  String get regionMiddleEast => 'Lähi-itä';

  @override
  String get regionSouthAmerica => 'Etelä-Amerikka';
}
