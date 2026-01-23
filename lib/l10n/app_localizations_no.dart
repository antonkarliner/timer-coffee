// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian (`no`).
class AppLocalizationsNo extends AppLocalizations {
  AppLocalizationsNo([String locale = 'no']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'Bønnestatistikk';

  @override
  String get totalBeansBrewedLabel => 'Totalt bryggede bønner';

  @override
  String get newBeansTriedLabel => 'Nye bønner prøvd';

  @override
  String get originsExploredLabel => 'Opprinnelser utforsket';

  @override
  String get regionsExploredLabel => 'Regioner utforsket';

  @override
  String get newRoastersDiscoveredLabel => 'Nye brennerier oppdaget';

  @override
  String get favoriteRoastersLabel => 'Favoritt brennerier';

  @override
  String get topOriginsLabel => 'Topp opprinnelser';

  @override
  String get topRegionsLabel => 'Topp regioner';

  @override
  String get lastrecipe => 'Sist brukte oppskrift:';

  @override
  String get userRecipesTitle => 'Dine oppskrifter';

  @override
  String get userRecipesSectionCreated => 'Opprettet av deg';

  @override
  String get userRecipesSectionImported => 'Importert av deg';

  @override
  String get userRecipesEmpty => 'Ingen oppskrifter funnet';

  @override
  String get userRecipesDeleteTitle => 'Slett oppskrift?';

  @override
  String get userRecipesDeleteMessage => 'Denne handlingen kan ikke angres.';

  @override
  String get userRecipesDeleteConfirm => 'Slett';

  @override
  String get userRecipesDeleteCancel => 'Avbryt';

  @override
  String get userRecipesSnackbarDeleted => 'Oppskrift slettet';

  @override
  String get hubUserRecipesTitle => 'Dine oppskrifter';

  @override
  String get hubUserRecipesSubtitle =>
      'Vis og administrer opprettede og importerte oppskrifter';

  @override
  String get hubAccountSubtitle => 'Administrer profilen din';

  @override
  String get hubSignInCreateSubtitle =>
      'Logg inn for å synkronisere oppskrifter og innstillinger';

  @override
  String get hubBrewDiarySubtitle =>
      'Se bryggehistorikken din og legg til notater';

  @override
  String get hubBrewStatsSubtitle =>
      'Se personlig og global bryggestatistikk og trender';

  @override
  String get hubSettingsSubtitle => 'Endre appinnstillinger og oppførsel';

  @override
  String get hubAboutSubtitle => 'Appdetaljer, versjon og bidragsytere';

  @override
  String get about => 'Om';

  @override
  String get author => 'Forfatter';

  @override
  String get authortext =>
      'Timer.Coffee-appen er laget av Anton Karliner, en kaffeentusiast, mediespesialist og fotojournalist. Jeg håper at denne appen vil hjelpe deg å nyte kaffen din. Bidra gjerne på GitHub.';

  @override
  String get contributors => 'Bidragsytere';

  @override
  String get errorLoadingContributors => 'Feil ved lasting av bidragsytere';

  @override
  String get license => 'Lisens';

  @override
  String get licensetext =>
      'Denne applikasjonen er fri programvare: du kan redistribuere den og/eller modifisere den under vilkårene i GNU General Public License som publisert av Free Software Foundation, enten versjon 3 av lisensen, eller (etter eget valg) en senere versjon.';

  @override
  String get licensebutton => 'Les GNU General Public License v3';

  @override
  String get website => 'Nettsted';

  @override
  String get sourcecode => 'Kildekode';

  @override
  String get support => 'Kjøp meg en kaffe';

  @override
  String get allrecipes => 'Alle oppskrifter';

  @override
  String get favoriterecipes => 'Favorittoppskrifter';

  @override
  String get coffeeamount => 'Kaffemengde (g)';

  @override
  String get wateramount => 'Vannmengde (ml)';

  @override
  String get watertemp => 'Vanntemperatur';

  @override
  String get grindsize => 'Malingsgrad';

  @override
  String get brewtime => 'Bryggetid';

  @override
  String get recipesummary => 'Oppskriftssammendrag';

  @override
  String get recipesummarynote =>
      'Merk: dette er en grunnleggende oppskrift med standard vann- og kaffemengder.';

  @override
  String get preparation => 'Forberedelse';

  @override
  String get brewingprocess => 'Bryggeprosess';

  @override
  String get step => 'Steg';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sekunder',
      one: 'sekund',
      zero: 'sekunder',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg => 'Takk for at du bruker Timer.Coffee! Nyt din';

  @override
  String get coffeefact => 'Kaffefakta';

  @override
  String get home => 'Hjem';

  @override
  String get appversion => 'App-versjon';

  @override
  String get tipsmall => 'Kjøp en liten kaffe';

  @override
  String get tipmedium => 'Kjøp en medium kaffe';

  @override
  String get tiplarge => 'Kjøp en stor kaffe';

  @override
  String get supportdevelopment => 'Støtt utviklingen';

  @override
  String get supportdevmsg =>
      'Dine donasjoner hjelper til med å dekke vedlikeholdskostnadene (som for eksempel utviklerlisenser). De lar meg også prøve flere kaffebryggere og legge til flere oppskrifter i appen.';

  @override
  String get supportdevtnx => 'Takk for at du vurderer å donere!';

  @override
  String get donationok => 'Takk!';

  @override
  String get donationtnx =>
      'Jeg setter virkelig pris på støtten din! Ønsker deg mange flotte brygg! ☕️';

  @override
  String get donationerr => 'Feil';

  @override
  String get donationerrmsg =>
      'Feil ved behandling av kjøpet, vennligst prøv igjen.';

  @override
  String get sharemsg => 'Sjekk ut denne oppskriften:';

  @override
  String get finishbrew => 'Fullfør';

  @override
  String get settings => 'Innstillinger';

  @override
  String get settingstheme => 'Tema';

  @override
  String get settingsthemelight => 'Lys';

  @override
  String get settingsthemedark => 'Mørk';

  @override
  String get settingsthemesystem => 'System';

  @override
  String get settingslang => 'Språk';

  @override
  String get sweet => 'Søt';

  @override
  String get balance => 'Balanse';

  @override
  String get acidic => 'Sur';

  @override
  String get light => 'Lett';

  @override
  String get strong => 'Sterk';

  @override
  String get slidertitle => 'Bruk glidebrytere for å justere smak';

  @override
  String get whatsnewtitle => 'Hva er nytt';

  @override
  String get whatsnewclose => 'Lukk';

  @override
  String get seasonspecials => 'Sesongspesialiteter';

  @override
  String get snow => 'Snø';

  @override
  String get noFavoriteRecipesMessage =>
      'Listen over favorittoppskrifter er for øyeblikket tom. Begynn å utforske og brygge for å oppdage favorittene dine!';

  @override
  String get explore => 'Utforsk';

  @override
  String get dateFormat => 'd. MMM yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Bryggdagbok';

  @override
  String get brewdiarynotfound => 'Ingen oppføringer funnet';

  @override
  String get beans => 'Bønner';

  @override
  String get roaster => 'Brenneri';

  @override
  String get rating => 'Vurdering';

  @override
  String get notes => 'Notater';

  @override
  String get statsscreen => 'Kaffestatistikk';

  @override
  String get yourStats => 'Din statistikk';

  @override
  String get coffeeBrewed => 'Kaffe brygget:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'Mest brukte oppskrifter:';

  @override
  String get globalStats => 'Global statistikk';

  @override
  String get unknownRecipe => 'Ukjent oppskrift';

  @override
  String get noData => 'Ingen data';

  @override
  String error(String error) {
    return 'Feil: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Noen har nettopp brygget $recipeName';
  }

  @override
  String get timePeriodToday => 'I dag';

  @override
  String get timePeriodThisWeek => 'Denne uken';

  @override
  String get timePeriodThisMonth => 'Denne måneden';

  @override
  String get timePeriodCustom => 'Tilpasset';

  @override
  String get statsFor => 'Statistikk for ';

  @override
  String get homescreenbrewcoffee => 'Brygg kaffe';

  @override
  String get homescreenhub => 'Hub';

  @override
  String get homescreenmore => 'Mer';

  @override
  String get addBeans => 'Legg til bønner';

  @override
  String get removeBeans => 'Fjern bønner';

  @override
  String get name => 'Navn';

  @override
  String get origin => 'Opprinnelse';

  @override
  String get details => 'Detaljer';

  @override
  String get coffeebeans => 'Kaffebønner';

  @override
  String get loading => 'Laster';

  @override
  String get nocoffeebeans => 'Ingen kaffebønner funnet';

  @override
  String get delete => 'Slett';

  @override
  String get confirmDeleteTitle => 'Slett oppføring?';

  @override
  String get recipeDuplicateConfirmTitle => 'Dupliser oppskrift?';

  @override
  String get recipeDuplicateConfirmMessage =>
      'Dette vil opprette en kopi av oppskriften som du kan redigere uavhengig. Vil du fortsette?';

  @override
  String get confirmDeleteMessage =>
      'Er du sikker på at du vil slette denne oppføringen? Denne handlingen kan ikke angres.';

  @override
  String get removeFavorite => 'Fjern fra favoritter';

  @override
  String get addFavorite => 'Legg til i favoritter';

  @override
  String get toggleEditMode => 'Veksle redigeringsmodus';

  @override
  String get coffeeBeansDetails => 'Kaffebønnedetaljer';

  @override
  String get edit => 'Rediger';

  @override
  String get coffeeBeansNotFound => 'Kaffebønner ikke funnet';

  @override
  String get basicInformation => 'Grunnleggende informasjon';

  @override
  String get geographyTerroir => 'Geografi/Terroir';

  @override
  String get variety => 'Variasjon';

  @override
  String get region => 'Region';

  @override
  String get elevation => 'Høyde';

  @override
  String get harvestDate => 'Høstedato';

  @override
  String get processing => 'Prosessering';

  @override
  String get processingMethod => 'Prosesseringsmetode';

  @override
  String get roastDate => 'Brenningsdato';

  @override
  String get roastLevel => 'Brenningsgrad';

  @override
  String get cuppingScore => 'Cuppingscore';

  @override
  String get flavorProfile => 'Smaksprofil';

  @override
  String get tastingNotes => 'Smaksnotater';

  @override
  String get additionalNotes => 'Tilleggsnotater';

  @override
  String get noCoffeeBeans => 'Ingen kaffebønner funnet';

  @override
  String get editCoffeeBeans => 'Rediger kaffebønner';

  @override
  String get addCoffeeBeans => 'Legg til kaffebønner';

  @override
  String get showImagePicker => 'Vis bildevalg';

  @override
  String get pleaseNote => 'Vennligst merk';

  @override
  String get firstTimePopupMessage =>
      '1. Vi bruker eksterne tjenester for å behandle bilder. Ved å fortsette godtar du dette.\n2. Selv om vi ikke lagrer bildene dine, vennligst unngå å inkludere personlige detaljer.\n3. Bildegjenkjenning er for øyeblikket begrenset til 10 tokens per måned (1 token = 1 bilde). Denne grensen kan endres i fremtiden.';

  @override
  String get ok => 'OK';

  @override
  String get takePhoto => 'Ta et bilde';

  @override
  String get selectFromPhotos => 'Velg fra bilder';

  @override
  String get takeAdditionalPhoto => 'Ta ytterligere bilde?';

  @override
  String get no => 'Nei';

  @override
  String get yes => 'Ja';

  @override
  String get selectedImages => 'Valgte bilder';

  @override
  String get selectedImage => 'Valgt bilde';

  @override
  String get backToSelection => 'Tilbake til utvalg';

  @override
  String get next => 'Neste';

  @override
  String get unexpectedErrorOccurred => 'Uventet feil oppstod';

  @override
  String get tokenLimitReached =>
      'Beklager, du har nådd tokengrensen for bildegjenkjenning denne måneden';

  @override
  String get noCoffeeLabelsDetected =>
      'Ingen kaffeetiketter oppdaget. Prøv med et annet bilde.';

  @override
  String get collectedInformation => 'Innsamlet informasjon';

  @override
  String get enterRoaster => 'Skriv inn brenneri';

  @override
  String get enterName => 'Skriv inn navn';

  @override
  String get enterOrigin => 'Skriv inn opprinnelse';

  @override
  String get optional => 'Valgfritt';

  @override
  String get enterVariety => 'Skriv inn variasjon';

  @override
  String get enterProcessingMethod => 'Skriv inn prosesseringsmetode';

  @override
  String get enterRoastLevel => 'Skriv inn brenningsgrad';

  @override
  String get enterRegion => 'Skriv inn region';

  @override
  String get enterTastingNotes => 'Skriv inn smaksnotater';

  @override
  String get enterElevation => 'Skriv inn høyde';

  @override
  String get enterCuppingScore => 'Skriv inn cuppingscore';

  @override
  String get enterNotes => 'Skriv inn notater';

  @override
  String get inventory => 'Beholdning';

  @override
  String get amountLeft => 'Mengde igjen';

  @override
  String get enterAmountLeft => 'Skriv inn mengde igjen';

  @override
  String get selectHarvestDate => 'Velg høstedato';

  @override
  String get selectRoastDate => 'Velg brenningsdato';

  @override
  String get selectDate => 'Velg dato';

  @override
  String get save => 'Lagre';

  @override
  String get fillRequiredFields => 'Vennligst fyll ut alle obligatoriske felt.';

  @override
  String get analyzing => 'Analyserer';

  @override
  String get errorMessage => 'Feil';

  @override
  String get selectCoffeeBeans => 'Velg kaffebønner';

  @override
  String get addNewBeans => 'Legg til nye bønner';

  @override
  String get favorite => 'Favoritt';

  @override
  String get notFavorite => 'Ikke favoritt';

  @override
  String get myBeans => 'Mine bønner';

  @override
  String get signIn => 'Logg inn';

  @override
  String get signOut => 'Logg ut';

  @override
  String get signInWithApple => 'Logg inn med Apple';

  @override
  String get signInSuccessful => 'Vellykket innlogging med Apple';

  @override
  String get signInError => 'Feil ved innlogging med Apple';

  @override
  String get signInErrorGoogle => 'Feil ved innlogging med Google';

  @override
  String get signInWithGoogle => 'Logg inn med Google';

  @override
  String get signOutSuccessful => 'Vellykket utlogging';

  @override
  String get signOutConfirmationTitle => 'Er du sikker på at du vil logge ut?';

  @override
  String get signOutConfirmationMessage =>
      'Synkronisering i skyen vil stoppe. Logg inn igjen for å fortsette.';

  @override
  String get signInSuccessfulGoogle => 'Vellykket innlogging med Google';

  @override
  String get signInWithEmail => 'Logg inn med e-post';

  @override
  String get enterEmail => 'Skriv inn e-postadressen din';

  @override
  String get emailHint => 'eksempel@epost.no';

  @override
  String get cancel => 'Avbryt';

  @override
  String get sendMagicLink => 'Send magisk lenke';

  @override
  String get magicLinkSent => 'Magisk lenke sendt! Sjekk e-posten din.';

  @override
  String get sendOTP => 'Send engangskode';

  @override
  String get otpSent => 'OTP sendt til e-posten din';

  @override
  String get otpSendError => 'Feil ved sending av OTP';

  @override
  String get enterOTP => 'Skriv inn OTP';

  @override
  String get otpHint => 'Skriv inn 6-sifret kode';

  @override
  String get verify => 'Bekreft';

  @override
  String get signInSuccessfulEmail => 'Innlogging vellykket';

  @override
  String get invalidOTP => 'Ugyldig OTP';

  @override
  String get otpVerificationError => 'Feil ved bekreftelse av OTP';

  @override
  String get success => 'Suksess!';

  @override
  String get otpSentMessage =>
      'En OTP sendes til e-posten din. Vennligst skriv den inn nedenfor når du mottar den.';

  @override
  String get otpHint2 => 'Skriv inn kode her';

  @override
  String get signInCreate => 'Logg inn / Opprett konto';

  @override
  String get accountManagement => 'Kontobehandling';

  @override
  String get deleteAccount => 'Slett konto';

  @override
  String get deleteAccountWarning =>
      'Vennligst merk: hvis du velger å fortsette, vil vi slette kontoen din og relaterte data fra våre servere. Den lokale kopien av dataene vil forbli på enheten, hvis du vil slette den også, kan du bare slette appen. For å aktivere synkronisering igjen må du opprette en konto på nytt';

  @override
  String get deleteAccountConfirmation => 'Konto slettet vellykket';

  @override
  String get accountDeleted => 'Konto slettet';

  @override
  String get accountDeletionError =>
      'Feil ved sletting av kontoen din, vennligst prøv igjen';

  @override
  String get deleteAccountTitle => 'Viktig';

  @override
  String get selectBeans => 'Velg bønner';

  @override
  String get all => 'Alle';

  @override
  String get selectRoaster => 'Velg brenneri';

  @override
  String get selectOrigin => 'Velg opprinnelse';

  @override
  String get resetFilters => 'Tilbakestill filtre';

  @override
  String get showFavoritesOnly => 'Vis kun favoritter';

  @override
  String get apply => 'Bruk';

  @override
  String get selectSize => 'Velg størrelse';

  @override
  String get sizeStandard => 'Standard';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Mitt år med Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      'Hei, takk for at du var en del av Timer.Coffee-universet i år!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'Først og fremst.\nDu brygget litt kaffe i år$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'For å være mer presis,\ndu brygget $liters liter kaffe i 2024!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'Du brukte bønner fra $roasterCount brennerier';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Dine topp 3 brennerier var:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Kaffe tok deg med på en reise\nrundt i verden$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'Du smakte kaffebønner\nfra $originCount land!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Du brygget ikke alene…';

  @override
  String get yearlyStatsStory7Part2 =>
      '...men med brukere fra 110 andre\nland på tvers av 6 kontinenter!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Du holdt deg tro mot deg selv og brukte kun disse $count bryggemetodene i år:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Du oppdaget nye smaker og brukte $count bryggemetoder i år:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'Du var en ekte kaffeoppdager og brukte $count bryggemetoder i år:';
  }

  @override
  String get yearlyStatsStory9Text => 'Så mye mer å oppdage!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'Dine topp-3 oppskrifter i 2024 var$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'Ses i 2025!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Vis litt kjærlighet ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Doner';

  @override
  String get yearlyStatsActionShare => 'Del fremgangen din';

  @override
  String get yearlyStatsUnknown => 'Ukjent';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Kunne ikke dele: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Mitt år med Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes => 'Mine topp-3 oppskrifter:';

  @override
  String get yearlyStatsShareProgressTop3Roasters => 'Mine topp-3 brennerier:';

  @override
  String get yearlyStats25AppBarTitle => 'Ditt år med Timer.Coffee – 2025';

  @override
  String get yearlyStats25AppBarTitleSimple => 'Timer.Coffee i 2025';

  @override
  String get yearlyStats25Slide1Title => 'Ditt år med Timer.Coffee';

  @override
  String get yearlyStats25Slide1Subtitle =>
      'Trykk for å se hvordan du brygget i 2025';

  @override
  String get yearlyStats25Slide2Intro => 'Sammen brygget vi kaffe...';

  @override
  String yearlyStats25Slide2Count(String count) {
    return '$count ganger';
  }

  @override
  String yearlyStats25Slide2Liters(String liters) {
    return 'Det er omtrent $liters liter kaffe';
  }

  @override
  String get yearlyStats25Slide2Cambridge =>
      'Nok til å gi en kopp kaffe til alle i Cambridge, Storbritannia (studentene ville vært spesielt takknemlige).';

  @override
  String get yearlyStats25Slide3Title => 'Hva med deg?';

  @override
  String yearlyStats25Slide3Subtitle(String brews, String liters) {
    return 'Du brygget $brews ganger med Timer.Coffee i år. Det er totalt $liters liter!';
  }

  @override
  String yearlyStats25Slide3TopBadge(int topPct) {
    return 'Du er i topp $topPct% av bryggere!';
  }

  @override
  String get yearlyStats25Slide4TitleSingle =>
      'Husker du dagen du brygget mest kaffe i år?';

  @override
  String get yearlyStats25Slide4TitleMulti =>
      'Husker du dagene da du brygget mest kaffe i år?';

  @override
  String get yearlyStats25Slide4TitleBrewTime => 'Din bryggetid i år';

  @override
  String get yearlyStats25Slide4ScratchLabel => 'Skrap for å avsløre';

  @override
  String yearlyStats25BrewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brygg',
      one: '1 brygg',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25Slide4PeakSingle(String date, String brewsLabel) {
    return '$date — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4PeakLiters(String liters) {
    return 'Omtrent $liters liter den dagen';
  }

  @override
  String yearlyStats25Slide4PeakMostRecent(
      String mostRecent, String brewsLabel) {
    return 'Siste: $mostRecent — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4BrewTimeLine(String timeLabel) {
    return 'Du brukte $timeLabel på å brygge';
  }

  @override
  String get yearlyStats25Slide4BrewTimeFooter => 'Det er godt brukt tid';

  @override
  String get yearlyStats25Slide5Title => 'Slik brygger du';

  @override
  String get yearlyStats25Slide5MethodsHeader => 'Favorittmetoder:';

  @override
  String get yearlyStats25Slide5NoMethods => 'Ingen metoder ennå';

  @override
  String get yearlyStats25Slide5RecipesHeader => 'Topp oppskrifter:';

  @override
  String get yearlyStats25Slide5NoRecipes => 'Ingen oppskrifter ennå';

  @override
  String yearlyStats25MethodRow(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'brygg',
      one: 'brygg',
    );
    return '$name — $count $_temp0';
  }

  @override
  String yearlyStats25Slide6Title(String count) {
    return 'Du oppdaget $count brennerier i år:';
  }

  @override
  String get yearlyStats25Slide6NoRoasters => 'Ingen brennerier ennå';

  @override
  String get yearlyStats25Slide7Title => 'Å drikke kaffe kan ta deg steder…';

  @override
  String yearlyStats25Slide7Subtitle(String count) {
    return 'Du oppdaget $count opprinnelser i år:';
  }

  @override
  String get yearlyStats25Others => '...og andre';

  @override
  String yearlyStats25FallbackTitle(int countries, int roasters) {
    return 'Timer.Coffee-brukere brukte bønner fra $countries land i år\nog registrerte $roasters forskjellige brennerier.';
  }

  @override
  String get yearlyStats25FallbackPromptHasBeans =>
      'Hvorfor ikke fortsette å logge bønneposene dine?';

  @override
  String get yearlyStats25FallbackPromptNoBeans =>
      'Kanskje det er på tide at du også blir med og registrerer bønnene dine?';

  @override
  String get yearlyStats25FallbackActionHasBeans =>
      'Fortsett å legge til bønner';

  @override
  String get yearlyStats25FallbackActionNoBeans =>
      'Legg til din første bønnepose';

  @override
  String get yearlyStats25ContinueButton => 'Fortsett';

  @override
  String get yearlyStats25PostcardTitle =>
      'Send et nyttårsønske til en medbrygger.';

  @override
  String get yearlyStats25PostcardSubtitle =>
      'Valgfritt. Hold det snilt. Ingen personlig informasjon.';

  @override
  String get yearlyStats25PostcardHint => 'Godt nytt år og flott brygg!';

  @override
  String get yearlyStats25PostcardSending => 'Sender...';

  @override
  String get yearlyStats25PostcardSend => 'Send';

  @override
  String get yearlyStats25PostcardSkip => 'Hopp over';

  @override
  String get yearlyStats25PostcardReceivedTitle =>
      'Et ønske fra en annen brygger';

  @override
  String get yearlyStats25PostcardErrorLength =>
      'Vennligst skriv inn 2–160 tegn.';

  @override
  String get yearlyStats25PostcardErrorSend =>
      'Kunne ikke sende. Vennligst prøv igjen.';

  @override
  String get yearlyStats25PostcardErrorRejected =>
      'Kunne ikke sende. Vennligst prøv en annen melding.';

  @override
  String get yearlyStats25CtaTitle => 'La oss brygge noe fantastisk i 2026!';

  @override
  String get yearlyStats25CtaSubtitle => 'Her er noen ideer:';

  @override
  String get yearlyStats25CtaExplorePrefix => 'Utforsk tilbud i ';

  @override
  String get yearlyStats25CtaGiftBox => 'Julegaveeske';

  @override
  String get yearlyStats25CtaDonate => 'Doner';

  @override
  String get yearlyStats25CtaDonateSuffix =>
      ' for å hjelpe Timer.Coffee vokse i det kommende året';

  @override
  String get yearlyStats25CtaFollowPrefix => 'Følg oss på ';

  @override
  String get yearlyStats25CtaInstagram => 'Instagram';

  @override
  String get yearlyStats25CtaShareButton => 'Del fremgangen min';

  @override
  String get yearlyStats25CtaShareHint => 'Ikke glem å tagge @timercoffeeapp';

  @override
  String get yearlyStats25AppBarTooltipResume => 'Gjenoppta';

  @override
  String get yearlyStats25AppBarTooltipPause => 'Pause';

  @override
  String get yearlyStats25ShareError =>
      'Kunne ikke dele oppsummering. Vennligst prøv igjen.';

  @override
  String yearlyStats25BrewTimeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutter',
      one: '1 minutt',
      zero: '0 minutter',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25BrewTimeHours(String hours) {
    return '$hours timer';
  }

  @override
  String get yearlyStats25ShareTitle => 'Mitt år-2025 med Timer.Coffee';

  @override
  String get yearlyStats25ShareBrewedPrefix => 'Brygget ';

  @override
  String get yearlyStats25ShareBrewedMiddle => ' ganger og ';

  @override
  String get yearlyStats25ShareBrewedSuffix => ' liter kaffe';

  @override
  String get yearlyStats25ShareRoastersPrefix => 'Brukte bønner fra ';

  @override
  String get yearlyStats25ShareRoastersSuffix => ' brennerier';

  @override
  String get yearlyStats25ShareOriginsPrefix => 'Oppdaget ';

  @override
  String get yearlyStats25ShareOriginsSuffix => ' kaffeopprinnelser';

  @override
  String get yearlyStats25ShareMethodsTitle => 'Mine favoritt bryggemetoder:';

  @override
  String get yearlyStats25ShareRecipesTitle => 'Mine topp oppskrifter:';

  @override
  String get yearlyStats25ShareHandle => '@timercoffeeapp';

  @override
  String get yearlyStatsFailedToLike =>
      'Kunne ikke like. Vennligst prøv igjen.';

  @override
  String get labelCoffeeBrewed => 'Kaffe brygget';

  @override
  String get labelTastedBeansBy => 'Smakte bønner fra';

  @override
  String get labelDiscoveredCoffeeFrom => 'Oppdaget kaffe fra';

  @override
  String get labelUsedBrewingMethods => 'Brukte';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'brennerier',
      one: 'brenneri',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'land',
      one: 'land',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bryggemetoder',
      one: 'bryggemetode',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Rediger oppskrift';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Opprett oppskrift';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Oppskriftssteg';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Oppskriftsnavn';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Kort beskrivelse';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Bryggemetode';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Kaffemengde (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Vannmengde (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Vanntemperatur (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Malingsgrad';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => 'Total bryggetid:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Minutter';

  @override
  String get recipeCreationScreenSecondsLabel => 'Sekunder';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Forberedelsestrin';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Bryggsteg $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Stegbeskrivelse';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Stegtid: ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'Vennligst skriv inn et oppskriftsnavn';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Vennligst skriv inn en kort beskrivelse';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Vennligst velg en bryggemetode';

  @override
  String get recipeCreationScreenRequiredValidator => 'Påkrevd';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Ugyldig nummer';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Vennligst skriv inn en stegbeskrivelse';

  @override
  String get recipeCreationScreenContinueButton =>
      'Fortsett til oppskriftssteg';

  @override
  String get recipeCreationScreenAddStepButton => 'Legg til steg';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Lagre oppskrift';

  @override
  String get recipeCreationScreenUpdateSuccess =>
      'Oppskrift oppdatert vellykket';

  @override
  String get recipeCreationScreenSaveSuccess => 'Oppskrift lagret vellykket';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Feil ved lagring av oppskrift: $error';
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
  String get recipeCopySuccess => 'Oppskrift kopiert vellykket!';

  @override
  String get recipeDuplicateSuccess => 'Oppskrift duplisert vellykket!';

  @override
  String recipeCopyError(String error) {
    return 'Feil ved kopiering av oppskrift: $error';
  }

  @override
  String get createRecipe => 'Opprett oppskrift';

  @override
  String errorSyncingData(Object error) {
    return 'Feil ved synkronisering av data: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Feil ved utlogging: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Forberedelse';

  @override
  String get loadingEllipsis => 'Laster...';

  @override
  String get recipeDeletedSuccess => 'Oppskrift slettet vellykket';

  @override
  String recipeDeleteError(Object error) {
    return 'Kunne ikke slette oppskrift: $error';
  }

  @override
  String get noRecipesFound => 'Ingen oppskrifter funnet';

  @override
  String recipeLoadError(Object error) {
    return 'Kunne ikke laste oppskrift: $error';
  }

  @override
  String get unknownBrewingMethod => 'Ukjent bryggemetode';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Kunne ikke laste kopiert oppskrift for redigering.';

  @override
  String get recipeCopyErrorOperationFailed => 'Operasjonen mislyktes.';

  @override
  String get notProvided => 'Ikke oppgitt';

  @override
  String get recipeUpdateFailedFetch =>
      'Kunne ikke hente oppdaterte oppskriftsdata.';

  @override
  String get recipeImportSuccess => 'Oppskrift importert vellykket!';

  @override
  String get recipeImportFailedSave => 'Kunne ikke lagre importert oppskrift.';

  @override
  String get recipeImportFailedFetch =>
      'Kunne ikke hente oppskriftsdata for import.';

  @override
  String get recipeNotImported => 'Oppskrift ikke importert.';

  @override
  String get recipeNotFoundCloud =>
      'Oppskrift ikke funnet i skyen eller er ikke offentlig.';

  @override
  String get recipeLoadErrorGeneric => 'Feil ved lasting av oppskrift.';

  @override
  String get recipeUpdateAvailableTitle => 'Oppdatering tilgjengelig';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'En nyere versjon av \'$recipeName\' er tilgjengelig online. Oppdatere?';
  }

  @override
  String get dialogCancel => 'Avbryt';

  @override
  String get dialogDuplicate => 'Dupliser';

  @override
  String get dialogUpdate => 'Oppdater';

  @override
  String get recipeImportTitle => 'Importer oppskrift';

  @override
  String recipeImportBody(String recipeName) {
    return 'Vil du importere oppskriften \'$recipeName\' fra skyen?';
  }

  @override
  String get dialogImport => 'Importer';

  @override
  String get moderationReviewNeededTitle => 'Moderasjonsvurdering nødvendig';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'Følgende oppskrift(er) krever gjennomgang på grunn av innholdsmodereringsproblemer: $recipeNames';
  }

  @override
  String get dismiss => 'Avvis';

  @override
  String get reviewRecipeButton => 'Gjennomgå oppskrift';

  @override
  String get signInRequiredTitle => 'Innlogging påkrevd';

  @override
  String get signInRequiredBodyShare =>
      'Du må logge inn for å dele dine egne oppskrifter.';

  @override
  String get syncSuccess => 'Synkronisering vellykket!';

  @override
  String get tooltipEditRecipe => 'Rediger oppskrift';

  @override
  String get tooltipCopyRecipe => 'Kopier oppskrift';

  @override
  String get tooltipDuplicateRecipe => 'Dupliser oppskrift';

  @override
  String get tooltipShareRecipe => 'Del oppskrift';

  @override
  String get signInRequiredSnackbar => 'Innlogging påkrevd';

  @override
  String get moderationErrorFunction =>
      'Innholdsmodereringskontroll mislyktes.';

  @override
  String get moderationReasonDefault => 'Innhold flagget for gjennomgang.';

  @override
  String get moderationFailedTitle => 'Moderering mislyktes';

  @override
  String moderationFailedBody(String reason) {
    return 'Denne oppskriften kan ikke deles fordi: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Feil ved deling av oppskrift: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName på Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'Kunne ikke sjekke innholdsstatus. Lagret lokalt, vil sjekke ved neste synkronisering.';

  @override
  String get saveLocallyModerationFailedTitle => 'Endringer lagret lokalt';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Dine lokale endringer har blitt lagret, men den offentlige versjonen kunne ikke oppdateres på grunn av innholdsmoderering: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Rediger importert oppskrift';

  @override
  String get editImportedRecipeBody =>
      'Dette er en importert oppskrift. Redigering av den vil opprette en ny, uavhengig kopi. Vil du fortsette?';

  @override
  String get editImportedRecipeButtonCopy => 'Opprett kopi og rediger';

  @override
  String get editImportedRecipeButtonCancel => 'Avbryt';

  @override
  String get editDisplayNameTitle => 'Rediger visningsnavn';

  @override
  String get displayNameHint => 'Skriv inn visningsnavnet ditt';

  @override
  String get displayNameEmptyError => 'Visningsnavn kan ikke være tomt';

  @override
  String get displayNameTooLongError =>
      'Visningsnavn kan ikke overstige 50 tegn';

  @override
  String get errorUserNotLoggedIn =>
      'Bruker ikke logget inn. Vennligst logg inn igjen.';

  @override
  String get displayNameUpdateSuccess => 'Visningsnavn oppdatert vellykket!';

  @override
  String displayNameUpdateError(String error) {
    return 'Kunne ikke oppdatere visningsnavn: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Slett bilde?';

  @override
  String get deletePictureConfirmationBody =>
      'Er du sikker på at du vil slette profilbildet ditt?';

  @override
  String get deletePictureSuccess => 'Profilbilde slettet.';

  @override
  String deletePictureError(String error) {
    return 'Kunne ikke slette profilbilde: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Kunne ikke oppdatere profilbilde: $error';
  }

  @override
  String get updatePictureSuccess => 'Profilbilde oppdatert vellykket!';

  @override
  String get deletePictureTooltip => 'Slett bilde';

  @override
  String get account => 'Konto';

  @override
  String get settingsBrewingMethodsTitle => 'Hjemskjerm bryggemetoder';

  @override
  String get filter => 'Filter';

  @override
  String get sortBy => 'Sorter etter';

  @override
  String get dateAdded => 'Dato lagt til';

  @override
  String get secondsAbbreviation => 's.';

  @override
  String get settingsAppIcon => 'App-ikon';

  @override
  String get settingsAppIconDefault => 'Standard';

  @override
  String get settingsAppIconLegacy => 'Eldre';

  @override
  String get searchBeans => 'Søk bønner...';

  @override
  String get favorites => 'Favoritter';

  @override
  String get searchPrefix => 'Søk: ';

  @override
  String get clearAll => 'Fjern alle';

  @override
  String get noBeansMatchSearch => 'Ingen bønner samsvarer med søket ditt';

  @override
  String get clearFilters => 'Fjern filtre';

  @override
  String get farmer => 'Bonde';

  @override
  String get farm => 'Gård';

  @override
  String get enterFarmer => 'Skriv inn bonde (valgfritt)';

  @override
  String get enterFarm => 'Skriv inn gård (valgfritt)';

  @override
  String get requiredInformation => 'Påkrevd informasjon';

  @override
  String get basicDetails => 'Grunnleggende detaljer';

  @override
  String get qualityMeasurements => 'Kvalitet og målinger';

  @override
  String get importantDates => 'Viktige datoer';

  @override
  String get brewStats => 'Bryggestatistikk';

  @override
  String get showMore => 'Vis mer';

  @override
  String get showLess => 'Vis mindre';

  @override
  String get unpublishRecipeDialogTitle => 'Gjør oppskrift privat';

  @override
  String get unpublishRecipeDialogMessage =>
      'Advarsel: Å gjøre denne oppskriften privat vil:';

  @override
  String get unpublishRecipeDialogBullet1 =>
      'Fjerne den fra offentlige søkeresultater';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'Hindre nye brukere i å importere den';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'Brukere som allerede har importert den vil beholde sine kopier';

  @override
  String get unpublishRecipeDialogKeepPublic => 'Hold offentlig';

  @override
  String get unpublishRecipeDialogMakePrivate => 'Gjør privat';

  @override
  String get recipeUnpublishSuccess => 'Oppskrift avpublisert vellykket';

  @override
  String recipeUnpublishError(String error) {
    return 'Kunne ikke avpublisere oppskrift: $error';
  }

  @override
  String get recipePublicTooltip =>
      'Oppskrift er offentlig - trykk for å gjøre privat';

  @override
  String get recipePrivateTooltip =>
      'Oppskrift er privat - del for å gjøre offentlig';

  @override
  String get fieldClearButtonTooltip => 'Fjern';

  @override
  String get dateFieldClearButtonTooltip => 'Fjern dato';

  @override
  String get chipInputDuplicateError => 'Denne taggen er allerede lagt til';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return 'Maksimalt antall tagger nådd ($maxChips)';
  }

  @override
  String get chipInputHintText => 'Legg til en tagg...';

  @override
  String get unitFieldRequiredError => 'Dette feltet er påkrevd';

  @override
  String get unitFieldInvalidNumberError =>
      'Vennligst skriv inn et gyldig nummer';

  @override
  String unitFieldMinValueError(Object min) {
    return 'Verdien må være minst $min';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return 'Verdien må være maksimalt $max';
  }

  @override
  String get numericFieldRequiredError => 'Dette feltet er påkrevd';

  @override
  String get numericFieldInvalidNumberError =>
      'Vennligst skriv inn et gyldig nummer';

  @override
  String numericFieldMinValueError(Object min) {
    return 'Verdien må være minst $min';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return 'Verdien må være maksimalt $max';
  }

  @override
  String get dropdownSearchHintText => 'Skriv for å søke...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return 'Feil ved lasting av forslag: $error';
  }

  @override
  String get dropdownSearchNoResults => 'Ingen resultater funnet';

  @override
  String get dropdownSearchLoading => 'Søker...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return 'Bruk \"$currentQuery\"';
  }

  @override
  String get requiredInfoSubtitle => '* Påkrevd';

  @override
  String get inventoryWeightExample => 'f.eks., 250.5';

  @override
  String get unsavedChangesTitle => 'Ulagrede endringer';

  @override
  String get unsavedChangesMessage =>
      'Du har ulagrede endringer. Er du sikker på at du vil forkaste dem?';

  @override
  String get unsavedChangesStay => 'Bli';

  @override
  String get unsavedChangesDiscard => 'Forkast';

  @override
  String beansWeightAddedBack(
      String amount, String beanName, String newWeight, String unit) {
    return 'Lagt til $amount$unit tilbake til $beanName. Ny vekt: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
      String amount, String beanName, String newWeight, String unit) {
    return 'Trukket fra $amount$unit fra $beanName. Ny vekt: $newWeight$unit';
  }

  @override
  String get notifications => 'Varsler';

  @override
  String get notificationsDisabledInSystemSettings =>
      'Deaktivert i systeminnstillinger';

  @override
  String get openSettings => 'Åpne innstillinger';

  @override
  String get couldNotOpenLink => 'Kunne ikke åpne lenke';

  @override
  String get notificationsDisabledDialogTitle =>
      'Varsler deaktivert i systeminnstillinger';

  @override
  String get notificationsDisabledDialogContent =>
      'Du har deaktivert varsler i enhetsinnstillingene. For å aktivere varsler, vennligst åpne enhetsinnstillingene og tillat varsler for Timer.Coffee.';

  @override
  String get notificationDebug => 'Varsel feilsøking';

  @override
  String get testNotificationSystem => 'Test varselsystem';

  @override
  String get notificationsEnabled => 'Aktivert';

  @override
  String get notificationsDisabled => 'Deaktivert';

  @override
  String get notificationPermissionDialogTitle => 'Aktiver varsler?';

  @override
  String get notificationPermissionDialogMessage =>
      'Du kan aktivere varsler for å få nyttige oppdateringer (f.eks. om nye app-versjoner). Aktiver nå eller endre dette når som helst i innstillinger.';

  @override
  String get notificationPermissionEnable => 'Aktiver';

  @override
  String get notificationPermissionSkip => 'Ikke nå';

  @override
  String get holidayGiftBoxTitle => 'Julegaveeske';

  @override
  String get holidayGiftBoxInfoTrigger => 'Hva er dette?';

  @override
  String get holidayGiftBoxInfoBody =>
      'Kuraterte sesongtilbud fra partnere. Lenker er ikke tilknyttet - målet vårt er ganske enkelt å bringe litt glede til Timer.Coffee-brukere i denne høytiden. Dra for å oppdatere når som helst.';

  @override
  String get holidayGiftBoxNoOffers => 'Ingen tilbud tilgjengelig akkurat nå.';

  @override
  String get holidayGiftBoxNoOffersSub =>
      'Dra for å oppdatere eller sjekk igjen snart.';

  @override
  String holidayGiftBoxShowingRegion(String region) {
    return 'Viser tilbud for $region';
  }

  @override
  String get holidayGiftBoxViewDetails => 'Vis detaljer';

  @override
  String get holidayGiftBoxPromoCopied => 'Kampanjekode kopiert';

  @override
  String get holidayGiftBoxPromoCode => 'Kampanjekode';

  @override
  String giftDiscountOff(String percent) {
    return '$percent% rabatt';
  }

  @override
  String giftDiscountUpToOff(String percent) {
    return 'Opptil $percent% rabatt';
  }

  @override
  String get holidayGiftBoxTerms => 'Vilkår og betingelser';

  @override
  String get holidayGiftBoxVisitSite => 'Besøk partnernettsted';

  @override
  String holidayGiftBoxValidUntil(String date) {
    return 'Gyldig til $date';
  }

  @override
  String holidayGiftBoxEndsInDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Utløper om $days dager',
      one: 'Utløper i morgen',
      zero: 'Utløper i dag',
    );
    return '$_temp0';
  }

  @override
  String get holidayGiftBoxValidWhileAvailable =>
      'Gyldig så lenge tilgjengelig';

  @override
  String holidayGiftBoxUpdated(String date) {
    return 'Oppdatert $date';
  }

  @override
  String holidayGiftBoxLanguage(String language) {
    return 'Språk: $language';
  }

  @override
  String get holidayGiftBoxRetry => 'Prøv på nytt';

  @override
  String get holidayGiftBoxLoadFailed => 'Kunne ikke laste tilbud';

  @override
  String get holidayGiftBoxOfferUnavailable => 'Tilbud utilgjengelig';

  @override
  String get holidayGiftBoxBannerTitle => 'Sjekk ut julegaveesken vår';

  @override
  String get holidayGiftBoxBannerCta => 'Se tilbud';

  @override
  String get regionEurope => 'Europa';

  @override
  String get regionNorthAmerica => 'Nord-Amerika';

  @override
  String get regionAsia => 'Asia';

  @override
  String get regionAustralia => 'Australia / Oseania';

  @override
  String get regionWorldwide => 'Verden';

  @override
  String get regionAfrica => 'Afrika';

  @override
  String get regionMiddleEast => 'Midtøsten';

  @override
  String get regionSouthAmerica => 'Sør-Amerika';

  @override
  String get setToZeroButton => 'Sett til null';

  @override
  String get setToZeroDialogTitle => 'Sett beholdningen til null?';

  @override
  String get setToZeroDialogBody =>
      'Dette vil sette gjenværende mengde til 0 g. Du kan redigere den senere.';

  @override
  String get setToZeroDialogConfirm => 'Sett til null';

  @override
  String get setToZeroDialogCancel => 'Avbryt';

  @override
  String get inventorySetToZeroSuccess => 'Beholdning satt til 0 g';

  @override
  String get inventorySetToZeroFail => 'Kunne ikke sette beholdningen til null';
}
