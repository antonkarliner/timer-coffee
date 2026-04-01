// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'Statistici boabe';

  @override
  String get totalBeansBrewedLabel => 'Total boabe folosite';

  @override
  String get newBeansTriedLabel => 'Boabe noi încercate';

  @override
  String get originsExploredLabel => 'Origini explorate';

  @override
  String get regionsExploredLabel => 'Regiuni explorate';

  @override
  String get newRoastersDiscoveredLabel => 'Prăjitorii noi descoperiți';

  @override
  String get favoriteRoastersLabel => 'Prăjitoriile preferate';

  @override
  String get topOriginsLabel => 'Top origini';

  @override
  String get topRegionsLabel => 'Top regiuni';

  @override
  String get lastrecipe => 'Rețeta folosită recent:';

  @override
  String get userRecipesTitle => 'Rețetele tale';

  @override
  String get userRecipesSectionCreated => 'Create de tine';

  @override
  String get userRecipesSectionImported => 'Importate de tine';

  @override
  String get userRecipesEmpty => 'Nu s-au găsit rețete';

  @override
  String get userRecipesDeleteTitle => 'Ștergi rețeta?';

  @override
  String get userRecipesDeleteMessage => 'Această acțiune nu poate fi anulată.';

  @override
  String get userRecipesDeleteConfirm => 'Șterge';

  @override
  String get userRecipesDeleteCancel => 'Anulează';

  @override
  String get userRecipesSnackbarDeleted => 'Rețetă ștearsă';

  @override
  String get hubUserRecipesTitle => 'Rețetele tale';

  @override
  String get hubUserRecipesSubtitle =>
      'Vizualizează și gestionează rețetele create și importate';

  @override
  String get hubAccountSubtitle => 'Gestionează-ți profilul';

  @override
  String get hubSignInCreateSubtitle =>
      'Conectează-te pentru a sincroniza rețetele și preferințele';

  @override
  String get hubBrewDiarySubtitle =>
      'Vezi istoricul tău de preparare și adaugă note';

  @override
  String get hubBrewStatsSubtitle =>
      'Vezi statistici și tendințe de preparare personale și globale';

  @override
  String get hubSettingsSubtitle =>
      'Schimbă preferințele și comportamentul aplicației';

  @override
  String get hubAboutSubtitle => 'Detalii aplicație, versiune și contribuitori';

  @override
  String get about => 'Despre';

  @override
  String get author => 'Autor';

  @override
  String get authortext =>
      'Aplicația Timer.Coffee a fost creată de Anton Karliner, un entuziast al cafelei, specialist media și fotojurnalist. Sper că această aplicație te va ajuta să te bucuri de cafea. Simte-te liber să contribui pe GitHub.';

  @override
  String get contributors => 'Contribuitori';

  @override
  String get errorLoadingContributors =>
      'Eroare la încărcarea contribuitorilor';

  @override
  String get license => 'Licență';

  @override
  String get licensetext =>
      'Această aplicație este un software liber: poți redistribui și/sau modifica conform termenilor Licenței Publice Generale GNU publicată de Free Software Foundation, fie versiunea 3 a Licenței, fie (la alegerea ta) orice versiune ulterioară.';

  @override
  String get licensebutton => 'Citește Licența Publică Generală GNU v3';

  @override
  String get website => 'Site web';

  @override
  String get sourcecode => 'Cod sursă';

  @override
  String get support => 'Cumpără-mi o cafea';

  @override
  String get supportButtonLabel => 'Suport';

  @override
  String get allrecipes => 'Toate Rețetele';

  @override
  String get favoriterecipes => 'Rețete Favorite';

  @override
  String get coffeeamount => 'Cantitate cafea (g)';

  @override
  String get wateramount => 'Cantitate apă (ml)';

  @override
  String get watertemp => 'Temperatura Apei';

  @override
  String get grindsize => 'Mărimea Măcinăturii';

  @override
  String get brewtime => 'Timpul de Preparare';

  @override
  String get recipesummary => 'Rezumatul Rețetei';

  @override
  String get recipesummarynote =>
      'Notă: aceasta este o rețetă de bază cu cantități implicite de apă și cafea.';

  @override
  String get preparation => 'Pregătire';

  @override
  String get brewingprocess => 'Procesul de Preparare';

  @override
  String get step => 'Pas';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de secunde',
      few: '$count secunde',
      one: '1 secundă',
      zero: '0 secunde',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg => 'Mulțumim că folosești Timer.Coffee! Bucură-te de';

  @override
  String get coffeefact => 'Fapt despre Cafea';

  @override
  String get home => 'Acasă';

  @override
  String get appversion => 'Versiunea Aplicației';

  @override
  String get tipsmall => 'Cumpără o cafea mică';

  @override
  String get tipmedium => 'Cumpără o cafea medie';

  @override
  String get tiplarge => 'Cumpără o cafea mare';

  @override
  String get supportdevelopment => 'Sprijină dezvoltarea';

  @override
  String get supportdevmsg =>
      'Donațiile tale ajută la acoperirea costurilor de întreținere (cum ar fi licențele de dezvoltator, de exemplu). De asemenea, îmi permit să încerc mai multe dispozitive de preparare a cafelei și să adaug mai multe rețete în aplicație.';

  @override
  String get supportdevtnx => 'Mulțumim că iei în considerare să donezi!';

  @override
  String get donationok => 'Mulțumesc!';

  @override
  String get donationtnx =>
      'Apreciez foarte mult sprijinul tău! Îți doresc multe preparări grozave! ☕️';

  @override
  String get donationerr => 'Eroare';

  @override
  String get donationerrmsg =>
      'Eroare la procesarea achiziției, te rog încearcă din nou.';

  @override
  String get sharemsg => 'Uite această rețetă:';

  @override
  String get finishbrew => 'Finalizează';

  @override
  String get settings => 'Setări';

  @override
  String get settingstheme => 'Temă';

  @override
  String get settingsthemelight => 'Luminoasă';

  @override
  String get settingsthemedark => 'Întunecat';

  @override
  String get settingsthemesystem => 'Sistem';

  @override
  String get settingslang => 'Limbă';

  @override
  String get settingsDateTimeFormat => 'Format dată și oră';

  @override
  String get settingsDateFormatLabel => 'Format dată';

  @override
  String get settingsTimeFormatLabel => 'Format oră';

  @override
  String get settingsDateFormatAuto => 'Automat (conform limbii)';

  @override
  String get settingsDateFormatDMY => 'ZZ/LL/AAAA';

  @override
  String get settingsDateFormatMDY => 'LL/ZZ/AAAA';

  @override
  String get settingsDateFormatYMD => 'AAAA-LL-ZZ';

  @override
  String get settingsTimeFormat12h => '12 ore (AM/PM)';

  @override
  String get settingsTimeFormat24h => '24 ore';

  @override
  String get sweet => 'Dulce';

  @override
  String get balance => 'Echilibrat';

  @override
  String get acidic => 'Acid';

  @override
  String get light => 'Ușor';

  @override
  String get strong => 'Puternic';

  @override
  String get slidertitle => 'Folosește glisoarele pentru a ajusta gustul';

  @override
  String get whatsnewtitle => 'Ce este nou';

  @override
  String get whatsnewclose => 'Închide';

  @override
  String get seasonspecials => 'Specialități de Sezon';

  @override
  String get snow => 'Zăpadă';

  @override
  String get noFavoriteRecipesMessage =>
      'Lista ta de rețete favorite este momentan goală. Începe să explorezi și să prepari pentru a descoperi favoritele tale!';

  @override
  String get explore => 'Explorează';

  @override
  String get dateFormat => 'd MMM yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Jurnal de Preparare';

  @override
  String get brewdiarynotfound => 'Nu s-au găsit înregistrări';

  @override
  String get beans => 'Boabe';

  @override
  String get roaster => 'Prăjitorie';

  @override
  String get rating => 'Evaluare';

  @override
  String get notes => 'Note';

  @override
  String get statsscreen => 'Statistici cafea';

  @override
  String get yourStats => 'Statisticile tale';

  @override
  String get coffeeBrewed => 'Cafea preparată:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'Rețetele cele mai utilizate:';

  @override
  String get globalStats => 'Statistici globale';

  @override
  String get unknownRecipe => 'Rețetă necunoscută';

  @override
  String get pulseUserRecipe => 'Rețetă utilizator';

  @override
  String get noData => 'Fără date';

  @override
  String get refresh => 'Actualizează';

  @override
  String error(String error) {
    return 'Eroare: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Cineva tocmai a preparat $recipeName';
  }

  @override
  String pulseSomeoneBrewed(String recipeName) {
    return 'Cineva a preparat $recipeName';
  }

  @override
  String pulseSomeoneFromBrewed(String country, String recipeName) {
    return 'Cineva din $country a preparat $recipeName';
  }

  @override
  String get pulseTitle => 'Pulse';

  @override
  String get hubPulseSubtitle => 'Flux live de preparări';

  @override
  String get pulseLiveSummary => 'Rezumat live';

  @override
  String get pulseBrewsLabel => 'Preparări';

  @override
  String pulseBrewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de preparări',
      few: '$count preparări',
      one: '1 preparare',
    );
    return '$_temp0';
  }

  @override
  String get timePeriodRecent => 'Recent';

  @override
  String get timePeriodLastHour => 'Ultima oră';

  @override
  String get timePeriodToday => 'Astăzi';

  @override
  String get timePeriodYesterday => 'Ieri';

  @override
  String get timePeriodThisWeek => 'Săptămâna aceasta';

  @override
  String get timePeriodThisMonth => 'Luna aceasta';

  @override
  String get timePeriodOlder => 'Mai vechi';

  @override
  String get timePeriodCustom => 'Personalizat';

  @override
  String get relativeTimeJustNow => 'chiar acum';

  @override
  String relativeTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum $count de minute',
      few: 'acum $count minute',
      one: 'acum 1 minut',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum $count de ore',
      few: 'acum $count ore',
      one: 'acum 1 oră',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeHoursMinutesAgo(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours de ore',
      few: '$hours ore',
      one: '1 oră',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes de minute',
      few: '$minutes minute',
      one: '1 minut',
    );
    return 'acum $_temp0 și $_temp1';
  }

  @override
  String relativeTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum $count de zile',
      few: 'acum $count zile',
      one: 'acum 1 zi',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum $count de luni',
      few: 'acum $count luni',
      one: 'acum 1 lună',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum $count de ani',
      few: 'acum $count ani',
      one: 'acum 1 an',
    );
    return '$_temp0';
  }

  @override
  String get statsFor => 'Statistici pentru ';

  @override
  String get homescreenbrewcoffee => 'Prepară cafea';

  @override
  String get homescreenhub => 'Hub';

  @override
  String get homescreenmore => 'Mai mult';

  @override
  String get addBeans => 'Adaugă boabe';

  @override
  String get removeBeans => 'Elimină boabe';

  @override
  String get name => 'Nume';

  @override
  String get origin => 'Origine';

  @override
  String get details => 'Detalii';

  @override
  String get coffeebeans => 'Boabe de cafea';

  @override
  String get loading => 'Se încarcă';

  @override
  String get nocoffeebeans => 'Nu s-au găsit boabe de cafea';

  @override
  String get delete => 'Șterge';

  @override
  String get confirmDeleteTitle => 'Ștergi înregistrarea?';

  @override
  String get recipeDuplicateConfirmTitle => 'Duplici rețeta?';

  @override
  String get recipeDuplicateConfirmMessage =>
      'Aceasta va crea o copie a rețetei tale pe care o poți edita independent. Dorești să continui?';

  @override
  String get confirmDeleteMessage =>
      'Sigur vrei să ștergi această înregistrare? Acțiunea nu poate fi anulată.';

  @override
  String get removeFavorite => 'Elimină din favorite';

  @override
  String get addFavorite => 'Adaugă la favorite';

  @override
  String get toggleEditMode => 'Comută modul de editare';

  @override
  String get coffeeBeansDetails => 'Detalii boabe de cafea';

  @override
  String get edit => 'Editează';

  @override
  String get coffeeBeansNotFound => 'Boabele de cafea nu au fost găsite';

  @override
  String get basicInformation => 'Date de bază';

  @override
  String get geographyTerroir => 'Geografie/Terroir';

  @override
  String get variety => 'Soi';

  @override
  String get region => 'Regiune';

  @override
  String get elevation => 'Altitudine';

  @override
  String get harvestDate => 'Data recoltării';

  @override
  String get processing => 'Procesare';

  @override
  String get processingMethod => 'Metoda de procesare';

  @override
  String get roastDate => 'Data prăjirii';

  @override
  String get roastLevel => 'Nivel de prăjire';

  @override
  String get cuppingScore => 'Scor Cupping';

  @override
  String get flavorProfile => 'Profil aromatic';

  @override
  String get tastingNotes => 'Note de degustare';

  @override
  String get additionalNotes => 'Note suplimentare';

  @override
  String get noCoffeeBeans => 'Nu s-au găsit boabe de cafea';

  @override
  String get editCoffeeBeans => 'Editează boabele de cafea';

  @override
  String get addCoffeeBeans => 'Adaugă boabe de cafea';

  @override
  String get showImagePicker => 'Arată selectorul de imagini';

  @override
  String get pleaseNote => 'Reține';

  @override
  String get firstTimePopupMessage =>
      '1. Folosim servicii externe pentru a procesa imaginile. Continuând, ești de acord cu acest lucru.\n2. Deși nu stocăm imaginile tale, te rugăm să eviți includerea oricăror detalii personale.\n3. Recunoașterea imaginilor este în prezent limitată la 10 jetoane pe lună (1 jeton = 1 imagine). Această limită se poate schimba în viitor.';

  @override
  String get ok => 'OK';

  @override
  String get takePhoto => 'Fă o poză';

  @override
  String get selectFromPhotos => 'Selectează din fotografii';

  @override
  String get takeAdditionalPhoto => 'Faci o altă poză?';

  @override
  String get no => 'Nu';

  @override
  String get yes => 'Da';

  @override
  String get selectedImages => 'Imagini selectate';

  @override
  String get selectedImage => 'Imagine selectată';

  @override
  String get backToSelection => 'Înapoi la selecție';

  @override
  String get next => 'Următorul';

  @override
  String get unexpectedErrorOccurred => 'A apărut o eroare neașteptată';

  @override
  String get tokenLimitReached =>
      'Ne pare răă, ai atins limita de jetoane pentru recunoașterea imaginilor luna aceasta';

  @override
  String get noCoffeeLabelsDetected =>
      'Nu au fost detectate etichete de cafea. Încearcă cu o altă imagine.';

  @override
  String get collectedInformation => 'Informații colectate';

  @override
  String get enterRoaster => 'Introdu prăjitorul';

  @override
  String get enterName => 'Introdu numele';

  @override
  String get enterOrigin => 'Introdu originea';

  @override
  String get optional => 'Opțional';

  @override
  String get enterVariety => 'Introdu soiul';

  @override
  String get enterProcessingMethod => 'Introdu metoda de procesare';

  @override
  String get enterRoastLevel => 'Introdu nivelul de prăjire';

  @override
  String get enterRegion => 'Introdu regiunea';

  @override
  String get enterTastingNotes => 'Introdu notele de degustare';

  @override
  String get enterElevation => 'Introdu altitudinea';

  @override
  String get enterCuppingScore => 'Introdu scorul cupping';

  @override
  String get enterNotes => 'Introdu note';

  @override
  String get inventory => 'Stoc';

  @override
  String get amountLeft => 'Cantitate rămasă';

  @override
  String get enterAmountLeft => 'Introdu cantitatea rămasă';

  @override
  String get selectHarvestDate => 'Selectează data recoltării';

  @override
  String get selectRoastDate => 'Selectează data prăjirii';

  @override
  String get selectDate => 'Selectează data';

  @override
  String get selectTime => 'Selectează ora';

  @override
  String get save => 'Salvează';

  @override
  String get fillRequiredFields => 'Completează toate câmpurile obligatorii.';

  @override
  String get analyzing => 'Se analizează';

  @override
  String get errorMessage => 'Eroare';

  @override
  String get selectCoffeeBeans => 'Selectează boabe de cafea';

  @override
  String get addNewBeans => 'Adaugă boabe no';

  @override
  String get favorite => 'Favorit';

  @override
  String get notFavorite => 'Nu este favorit';

  @override
  String get myBeans => 'Boabele mele';

  @override
  String get signIn => 'Autentificare';

  @override
  String get signOut => 'Deconectare';

  @override
  String get signInWithApple => 'Conectează-te cu Apple';

  @override
  String get signInSuccessful => 'Conectat cu succes cu Apple';

  @override
  String get signInError => 'Eroare la conectarea cu Apple';

  @override
  String get signInErrorGoogle => 'Eroare la conectarea cu Google';

  @override
  String get signInWithGoogle => 'Autentifică-te cu Google';

  @override
  String get signOutSuccessful => 'Deconectat cu succes';

  @override
  String get signOutConfirmationTitle => 'Sigur vrei să te deconectezi?';

  @override
  String get signOutConfirmationMessage =>
      'Sincronizarea în cloud se va opri. Conectează-te din nou pentru a o relua.';

  @override
  String get signInSuccessfulGoogle => 'Autentificat cu succes prin Google';

  @override
  String get signInWithEmail => 'Autentifică-te cu e-mail';

  @override
  String get enterEmail => 'Introdu adresa de e-mail';

  @override
  String get emailHint => 'exemplu@email.com';

  @override
  String get cancel => 'Anulare';

  @override
  String get sendMagicLink => 'Trimite link magic';

  @override
  String get magicLinkSent =>
      'Link-ul magic a fost trimis! Verifică-ți e-mailul.';

  @override
  String get sendOTP => 'Trimite OTP';

  @override
  String get otpSent => 'OTP trimis la adresa ta de email';

  @override
  String get otpSendError => 'Eroare la trimiterea OTP';

  @override
  String get enterOTP => 'Introdu codul OTP';

  @override
  String get otpHint => 'Introdu codul de 6 cifre';

  @override
  String get verify => 'Verifică';

  @override
  String get signInSuccessfulEmail => 'Autentificare reușită';

  @override
  String get invalidOTP => 'OTP invalid';

  @override
  String get otpVerificationError => 'Eroare la verificarea OTP';

  @override
  String get success => 'Succes!';

  @override
  String get otpSentMessage =>
      'Un cod OTP a fost trimis la adresa ta de email. Introdu-l mai jos când îl primești.';

  @override
  String get otpHint2 => 'Introdu codul aici';

  @override
  String get signInCreate => 'Autentificare / Creare cont';

  @override
  String get accountManagement => 'Administrarea contului';

  @override
  String get deleteAccount => 'Șterge contul';

  @override
  String get deleteAccountWarning =>
      'Reține că, dacă alegi să continui, îți vom șterge contul și datele asociate de pe serverele noastre. Copia locală a datelor va rămâne pe dispozitiv, dar dacă vrei să o ștergi, poți pur și simplu să dezinstalezi aplicația. Pentru a reactiva sincronizarea, va trebui să creezi din nou un cont.';

  @override
  String get deleteAccountConfirmation => 'Contul șters cu succes';

  @override
  String get accountDeleted => 'Contul a fost șters';

  @override
  String get accountDeletionError =>
      'Eroare la ștergerea contului, încearcă din nou.';

  @override
  String get deleteAccountTitle => 'Important';

  @override
  String get selectBeans => 'Selectează boabe';

  @override
  String get all => 'Toate';

  @override
  String get selectRoaster => 'Selectează prăjitorul';

  @override
  String get selectOrigin => 'Selectează originea';

  @override
  String get resetFilters => 'Resetează filtrele';

  @override
  String get showFavoritesOnly => 'Afișare doar favorite';

  @override
  String get apply => 'Aplică';

  @override
  String get selectSize => 'Selectează dimensiunea';

  @override
  String get sizeStandard => 'Standard';

  @override
  String get sizeMedium => 'Mediu';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Anul meu cu Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      'Bună! Mulțumesc că ai făcut parte din universul Timer.Coffee anul acesta!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'În primul rând.\nAnul acesta ai preparat niște cafea$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'Mai exact,\nai preparat $liters litri de cafea în 2024!';
  }

  @override
  String yearlyStatsStory4Text(num roasterCount) {
    return 'Ai folosit boabe de la $roasterCount prăjitori';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Cei mai buni 3 prăjitori ai tăi au fost:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Cafeaua te-a dus într-o călătorie\nîn jurul lumii$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(num originCount) {
    return 'Ai gustat boabe de cafea\ndin $originCount țări!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Nu ai preparat cafea singur…';

  @override
  String get yearlyStatsStory7Part2 =>
      '…ci alături de utilizatori din alte 110\nțări de pe 6 continente!';

  @override
  String yearlyStatsStory8TitleLow(num count) {
    return 'Ai rămas fidel gusturilor tale și ai folosit doar aceste $count metode de preparare anul acesta:';
  }

  @override
  String yearlyStatsStory8TitleMedium(num count) {
    return 'Ai descoperit gusturi noi și ai folosit $count metode de preparare anul acesta:';
  }

  @override
  String yearlyStatsStory8TitleHigh(num count) {
    return 'Ai fost un adevărat explorator al cafelei și ai folosit $count metode de preparare anul acesta:';
  }

  @override
  String get yearlyStatsStory9Text => 'Mai sunt atâtea de descoperit!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'Rețetele tale de top 3 din 2024 au fost$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'Ne vedem în 2025!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Arată-ți aprecierea ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Donează';

  @override
  String get yearlyStatsActionShare => 'Distribuie-ți progresul';

  @override
  String get yearlyStatsUnknown => 'Necunoscut';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Distribuirea a eșuat: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Anul meu cu Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes => 'Top 3 rețete:';

  @override
  String get yearlyStatsShareProgressTop3Roasters => 'Top 3 prăjitori:';

  @override
  String get yearlyStats25AppBarTitle => 'Anul tău cu Timer.Coffee – 2025';

  @override
  String get yearlyStats25AppBarTitleSimple => 'Timer.Coffee în 2025';

  @override
  String get yearlyStats25Slide1Title => 'Anul tău cu Timer.Coffee';

  @override
  String get yearlyStats25Slide1Subtitle =>
      'Atinge pentru a vedea cum ai preparat cafea în 2025';

  @override
  String get yearlyStats25Slide2Intro => 'Împreună am preparat cafea...';

  @override
  String yearlyStats25Slide2Count(String count) {
    return '$count ori';
  }

  @override
  String yearlyStats25Slide2Liters(String liters) {
    return 'Asta înseamnă aproximativ $liters litri de cafea';
  }

  @override
  String get yearlyStats25Slide2Cambridge =>
      'Suficient cât să oferim o ceașcă de cafea tuturor din Cambridge, Regatul Unit (studenții ar fi deosebit de recunoscători).';

  @override
  String get yearlyStats25Slide3Title => 'Dar tu?';

  @override
  String yearlyStats25Slide3Subtitle(String brews, String liters) {
    return 'Anul acesta ai preparat cafea de $brews ori cu Timer.Coffee. În total, $liters litri de cafea!';
  }

  @override
  String yearlyStats25Slide3TopBadge(int topPct) {
    return 'Ești în top $topPct% dintre cei care prepară cafea!';
  }

  @override
  String get yearlyStats25Slide4TitleSingle =>
      'Îți amintești ziua în care ai preparat cea mai multă cafea anul acesta?';

  @override
  String get yearlyStats25Slide4TitleMulti =>
      'Îți amintești zilele în care ai preparat cea mai multă cafea anul acesta?';

  @override
  String get yearlyStats25Slide4TitleBrewTime =>
      'Timpul tău de preparare anul acesta';

  @override
  String get yearlyStats25Slide4ScratchLabel => 'Zgârie pentru a dezvălui';

  @override
  String yearlyStats25BrewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de preparări',
      few: '$count preparări',
      one: '1 preparare',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25Slide4PeakSingle(String date, String brewsLabel) {
    return '$date — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4PeakLiters(String liters) {
    return 'Aproximativ $liters litri în ziua aceea';
  }

  @override
  String yearlyStats25Slide4PeakMostRecent(
    String mostRecent,
    String brewsLabel,
  ) {
    return 'Cel mai recent: $mostRecent — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4BrewTimeLine(String timeLabel) {
    return 'Ai petrecut $timeLabel preparând cafea';
  }

  @override
  String get yearlyStats25Slide4BrewTimeFooter => 'Timp bine petrecut';

  @override
  String get yearlyStats25Slide5Title => 'Așa îți prepari cafeaua';

  @override
  String get yearlyStats25Slide5MethodsHeader => 'Metode favorite:';

  @override
  String get yearlyStats25Slide5NoMethods => 'Nicio metodă încă';

  @override
  String get yearlyStats25Slide5RecipesHeader => 'Rețete de top:';

  @override
  String get yearlyStats25Slide5NoRecipes => 'Nicio rețetă încă';

  @override
  String yearlyStats25MethodRow(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'de preparări',
      few: 'preparări',
      one: 'preparare',
    );
    return '$name — $count $_temp0';
  }

  @override
  String yearlyStats25Slide6Title(String count) {
    return 'Anul acesta ai descoperit $count prăjitori:';
  }

  @override
  String get yearlyStats25Slide6NoRoasters => 'Niciun prăjitor încă';

  @override
  String get yearlyStats25Slide7Title => 'Cafeaua te poate duce departe…';

  @override
  String yearlyStats25Slide7Subtitle(String count) {
    return 'Anul acesta ai descoperit $count origini:';
  }

  @override
  String get yearlyStats25Others => '...și altele';

  @override
  String yearlyStats25FallbackTitle(int countries, int roasters) {
    return 'Anul acesta, utilizatorii Timer.Coffee au folosit boabe din $countries țări\nși au înregistrat $roasters prăjitori diferiți.';
  }

  @override
  String get yearlyStats25FallbackPromptHasBeans =>
      'De ce să nu continui să înregistrezi pungile de boabe?';

  @override
  String get yearlyStats25FallbackPromptNoBeans =>
      'Poate e timpul să te alături și să îți înregistrezi boabele și tu?';

  @override
  String get yearlyStats25FallbackActionHasBeans => 'Continuă să adaugi boabe';

  @override
  String get yearlyStats25FallbackActionNoBeans =>
      'Adaugă prima ta pungă de boabe';

  @override
  String get yearlyStats25ContinueButton => 'Continuă';

  @override
  String get yearlyStats25PostcardTitle =>
      'Trimite o urare de Anul Nou unui alt iubitor de cafea.';

  @override
  String get yearlyStats25PostcardSubtitle =>
      'Opțional. Fii amabil. Fără informații personale.';

  @override
  String get yearlyStats25PostcardHint => 'La mulți ani și cafele grozave!';

  @override
  String get yearlyStats25PostcardSending => 'Se trimite...';

  @override
  String get yearlyStats25PostcardSend => 'Trimite';

  @override
  String get yearlyStats25PostcardSkip => 'Sari peste';

  @override
  String get yearlyStats25PostcardReceivedTitle =>
      'O urare de la un alt iubitor de cafea';

  @override
  String get yearlyStats25PostcardErrorLength => 'Introdu 2–160 de caractere.';

  @override
  String get yearlyStats25PostcardErrorSend =>
      'Nu s-a putut trimite. Încearcă din nou.';

  @override
  String get yearlyStats25PostcardErrorRejected =>
      'Nu s-a putut trimite. Încearcă un alt mesaj.';

  @override
  String get yearlyStats25CtaTitle => 'Să preparăm ceva grozav în 2026!';

  @override
  String get yearlyStats25CtaSubtitle => 'Iată câteva idei:';

  @override
  String get yearlyStats25CtaExplorePrefix => 'Descoperă ofertele din ';

  @override
  String get yearlyStats25CtaGiftBox => 'Cutia Cadou de Sărbători';

  @override
  String get yearlyStats25CtaDonate => 'Donează';

  @override
  String get yearlyStats25CtaDonateSuffix =>
      ' pentru a ajuta Timer.Coffee să crească în anul ce urmează';

  @override
  String get yearlyStats25CtaFollowPrefix => 'Urmărește-ne pe ';

  @override
  String get yearlyStats25CtaInstagram => 'Instagram';

  @override
  String get yearlyStats25CtaShareButton => 'Distribuie progresul meu';

  @override
  String get yearlyStats25CtaShareHint =>
      'Nu uita să etichetezi @timercoffeeapp';

  @override
  String get yearlyStats25AppBarTooltipResume => 'Reia';

  @override
  String get yearlyStats25AppBarTooltipPause => 'Pauză';

  @override
  String get yearlyStats25ShareError =>
      'Nu s-a putut distribui rezumatul. Încearcă din nou.';

  @override
  String yearlyStats25BrewTimeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de minute',
      few: '$count minute',
      one: '1 minut',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25BrewTimeHours(String hours) {
    return '$hours h';
  }

  @override
  String get yearlyStats25ShareTitle => 'Anul meu 2025 cu Timer.Coffee';

  @override
  String get yearlyStats25ShareBrewedPrefix => 'Am preparat ';

  @override
  String get yearlyStats25ShareBrewedMiddle => ' ori și ';

  @override
  String get yearlyStats25ShareBrewedSuffix => ' litri de cafea';

  @override
  String get yearlyStats25ShareRoastersPrefix => 'Boabe de la ';

  @override
  String get yearlyStats25ShareRoastersSuffix => ' prăjitori';

  @override
  String get yearlyStats25ShareOriginsPrefix => 'Descoperite ';

  @override
  String get yearlyStats25ShareOriginsSuffix => ' origini';

  @override
  String get yearlyStats25ShareMethodsTitle => 'Metodele mele favorite:';

  @override
  String get yearlyStats25ShareRecipesTitle => 'Rețetele mele de top:';

  @override
  String get yearlyStats25ShareHandle => '@timercoffeeapp';

  @override
  String get yearlyStatsFailedToLike => 'Nu s-a apreciat. Încearcă din nou.';

  @override
  String get labelCoffeeBrewed => 'Cafea preparată';

  @override
  String get labelTastedBeansBy => 'Boabe gustate de la';

  @override
  String get labelDiscoveredCoffeeFrom => 'Cafea descoperită din';

  @override
  String get labelUsedBrewingMethods => 'Utilizate';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'de prăjitori',
      few: 'prăjitori',
      one: 'prăjitor',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'de țări',
      few: 'țări',
      one: 'țară',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'de metode de preparare',
      few: 'metode de preparare',
      one: 'metodă de preparare',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Editează Rețeta';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Creează Rețetă';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Pașii Rețetei';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Nume Rețetă';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Descriere Scurtă';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Metodă de Preparare';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Cantitate Cafea (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Cantitate Apă (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Temperatură Apă (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Mărime Măcinătură';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => 'Timp Total Preparare:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Minute';

  @override
  String get recipeCreationScreenSecondsLabel => 'Secunde';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Pas de Pregătire';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Pas de Preparare $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Descriere Pas';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Timp Pas: ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'Introdu un nume pentru rețetă';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Introdu o descriere scurtă';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Selectează o metodă de preparare';

  @override
  String get recipeCreationScreenRequiredValidator => 'Obligatoriu';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Număr invalid';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Introdu o descriere pentru pas';

  @override
  String get recipeCreationScreenContinueButton => 'Continuă la Pașii Rețetei';

  @override
  String get recipeCreationScreenAddStepButton => 'Adaugă Pas';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Salvează Rețeta';

  @override
  String get recipeCreationScreenUpdateSuccess =>
      'Rețetă actualizată cu succes';

  @override
  String get recipeCreationScreenSaveSuccess => 'Rețetă salvată cu succes';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Eroare la salvarea rețetei: $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'grame';

  @override
  String get unitMillilitersLong => 'mililitri';

  @override
  String get recipeCopySuccess => 'Rețetă copiată cu succes!';

  @override
  String get recipeDuplicateSuccess => 'Rețetă duplicată cu succes!';

  @override
  String recipeCopyError(String error) {
    return 'Eroare la copierea rețetei: $error';
  }

  @override
  String get createRecipe => 'Creează rețetă';

  @override
  String errorSyncingData(Object error) {
    return 'Eroare la sincronizarea datelor: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Eroare la deconectare: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Pregătire';

  @override
  String get loadingEllipsis => 'Se încarcă...';

  @override
  String get recipeDeletedSuccess => 'Rețetă ștearsă cu succes';

  @override
  String recipeDeleteError(Object error) {
    return 'Eroare la ștergerea rețetei: $error';
  }

  @override
  String get noRecipesFound => 'Nu s-au găsit rețete';

  @override
  String recipeLoadError(Object error) {
    return 'Eroare la încărcarea rețetei: $error';
  }

  @override
  String get unknownBrewingMethod => 'Metodă de preparare necunoscută';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Eroare la încărcarea rețetei copiate pentru editare.';

  @override
  String get recipeCopyErrorOperationFailed => 'Operațiunea a eșuat.';

  @override
  String get notProvided => 'Nu este furnizat';

  @override
  String get recipeUpdateFailedFetch =>
      'Eroare la preluarea datelor actualizate ale rețetei.';

  @override
  String get recipeImportSuccess => 'Rețetă importată cu succes!';

  @override
  String get recipeImportFailedSave => 'Eroare la salvarea rețetei importate.';

  @override
  String get recipeImportFailedFetch =>
      'Eroare la preluarea datelor rețetei pentru import.';

  @override
  String get recipeNotImported => 'Rețeta nu a fost importată.';

  @override
  String get recipeNotFoundCloud =>
      'Rețeta nu a fost găsită în cloud sau nu este publică.';

  @override
  String get recipeLoadErrorGeneric => 'Eroare la încărcarea rețetei.';

  @override
  String get recipeUpdateAvailableTitle => 'Actualizare Disponibilă';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'O versiune mai nouă a \'$recipeName\' este disponibilă online. Actualizezi?';
  }

  @override
  String get dialogCancel => 'Anulează';

  @override
  String get dialogDuplicate => 'Duplică';

  @override
  String get dialogUpdate => 'Actualizează';

  @override
  String get recipeImportTitle => 'Importă rețeta';

  @override
  String recipeImportBody(String recipeName) {
    return 'Vrei să imporți rețeta \'$recipeName\' din cloud?';
  }

  @override
  String get dialogImport => 'Importă';

  @override
  String get moderationReviewNeededTitle => 'Revizuire de moderare necesară';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'Următoarea(ele) rețetă(e) necesită revizuire din cauza problemelor de moderare a conținutului: $recipeNames';
  }

  @override
  String get dismiss => 'Respinge';

  @override
  String get reviewRecipeButton => 'Revizuiește Rețeta';

  @override
  String get signInRequiredTitle => 'Autentificare necesară';

  @override
  String get signInRequiredBodyShare =>
      'Trebuie să te autentifici pentru a partaja propriile rețete.';

  @override
  String get syncSuccess => 'Sincronizare reușită!';

  @override
  String get tooltipEditRecipe => 'Editează Rețeta';

  @override
  String get tooltipCopyRecipe => 'Copiază Rețeta';

  @override
  String get tooltipDuplicateRecipe => 'Duplică Rețeta';

  @override
  String get tooltipShareRecipe => 'Partajează Rețeta';

  @override
  String get signInRequiredSnackbar => 'Autentificare necesară';

  @override
  String get moderationErrorFunction =>
      'Verificarea moderării conținutului a eșuat.';

  @override
  String get moderationReasonDefault => 'Conținut marcat pentru revizuire.';

  @override
  String get moderationFailedTitle => 'Moderare Eșuată';

  @override
  String moderationFailedBody(String reason) {
    return 'Această rețetă nu poate fi partajată deoarece: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Eroare la partajarea rețetei: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName pe Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'Nu s-a putut verifica starea conținutului. Salvat local, se va verifica la următoarea sincronizare.';

  @override
  String get saveLocallyModerationFailedTitle => 'Modificări Salvate Local';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Modificările tale locale au fost salvate, dar versiunea publică nu a putut fi actualizată din cauza moderării conținutului: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Editează rețeta importată';

  @override
  String get editImportedRecipeBody =>
      'Aceasta este o rețetă importată. Editarea ei va crea o copie nouă, independentă. Vrei să continui?';

  @override
  String get editImportedRecipeButtonCopy => 'Creează copie și editează';

  @override
  String get editImportedRecipeButtonCancel => 'Anulează';

  @override
  String get editDisplayNameTitle => 'Editează numele afișat';

  @override
  String get displayNameHint => 'Introdu numele afișat';

  @override
  String get displayNameEmptyError => 'Numele afișat nu poate fi gol';

  @override
  String get displayNameTooLongError =>
      'Numele afișat nu poate depăși 50 de caractere';

  @override
  String get errorUserNotLoggedIn =>
      'Nu ești autentificat. Autentifică-te din nou.';

  @override
  String get displayNameUpdateSuccess =>
      'Numele afișat a fost actualizat cu succes!';

  @override
  String displayNameUpdateError(String error) {
    return 'Eroare la actualizarea numelui afișat: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Ștergi imaginea?';

  @override
  String get deletePictureConfirmationBody =>
      'Sigur vrei să ștergi poza de profil?';

  @override
  String get deletePictureSuccess => 'Poza de profil a fost ștearsă.';

  @override
  String deletePictureError(String error) {
    return 'Eroare la ștergerea pozei de profil: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Eroare la actualizarea pozei de profil: $error';
  }

  @override
  String get updatePictureSuccess =>
      'Poza de profil a fost actualizată cu succes!';

  @override
  String get deletePictureTooltip => 'Șterge imaginea';

  @override
  String get account => 'Cont';

  @override
  String get settingsBrewingMethodsTitle =>
      'Metode de preparare pe ecranul principal';

  @override
  String get filter => 'Filtru';

  @override
  String get sortBy => 'Sortează după';

  @override
  String get dateAdded => 'Data adăugării';

  @override
  String get secondsAbbreviation => 's';

  @override
  String get settingsAppIcon => 'Pictograma aplicației';

  @override
  String get settingsAppIconDefault => 'Implicit';

  @override
  String get settingsAppIconLegacy => 'Vechi';

  @override
  String get searchBeans => 'Caută boabe...';

  @override
  String get favorites => 'Favorite';

  @override
  String get searchPrefix => 'Caută: ';

  @override
  String get clearAll => 'Șterge tot';

  @override
  String get noBeansMatchSearch => 'Niciun bob nu corespunde căutării tale';

  @override
  String get clearFilters => 'Șterge filtrele';

  @override
  String get farmer => 'Fermier';

  @override
  String get farm => 'Fermă de cafea';

  @override
  String get enterFarmer => 'Introdu fermierul (opțional)';

  @override
  String get enterFarm => 'Introdu ferma de cafea (opțional)';

  @override
  String get requiredInformation => 'Informații necesare';

  @override
  String get basicDetails => 'Detalii de bază';

  @override
  String get qualityMeasurements => 'Calitate și măsurători';

  @override
  String get importantDates => 'Date importante';

  @override
  String get brewStats => 'Statistici de preparare';

  @override
  String get showMore => 'Arată mai mult';

  @override
  String get showLess => 'Arată mai puțin';

  @override
  String get unpublishRecipeDialogTitle => 'Setează rețeta ca privată';

  @override
  String get unpublishRecipeDialogMessage =>
      'Atenție: Setarea acestei rețete ca privată va duce la:';

  @override
  String get unpublishRecipeDialogBullet1 =>
      'Eliminarea acesteia din rezultatele căutărilor publice';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'Împiedicarea utilizatorilor noi să o importe';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'Utilizatorii care au importat-o deja își vor păstra copiile';

  @override
  String get unpublishRecipeDialogKeepPublic => 'Păstrează publică';

  @override
  String get unpublishRecipeDialogMakePrivate => 'Setează ca privată';

  @override
  String get recipeUnpublishSuccess =>
      'Publicarea rețetei a fost anulată cu succes';

  @override
  String recipeUnpublishError(String error) {
    return 'Eroare la anularea publicării rețetei: $error';
  }

  @override
  String get recipePublicTooltip =>
      'Rețeta este publică - atinge pentru a o face privată';

  @override
  String get recipePrivateTooltip =>
      'Rețeta este privată - partajează pentru a o face publică';

  @override
  String get fieldClearButtonTooltip => 'Șterge';

  @override
  String get dateFieldClearButtonTooltip => 'Șterge data';

  @override
  String get chipInputDuplicateError => 'Acest tag a fost deja adăugat';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return 'Număr maxim de taguri atins ($maxChips)';
  }

  @override
  String get chipInputHintText => 'Adaugă un tag...';

  @override
  String get unitFieldRequiredError => 'Acest câmp este obligatoriu';

  @override
  String get unitFieldInvalidNumberError => 'Introdu un număr valid';

  @override
  String unitFieldMinValueError(Object min) {
    return 'Valoarea trebuie să fie cel puțin $min';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return 'Valoarea trebuie să fie cel mult $max';
  }

  @override
  String get numericFieldRequiredError => 'Acest câmp este obligatoriu';

  @override
  String get numericFieldInvalidNumberError => 'Introdu un număr valid';

  @override
  String numericFieldMinValueError(Object min) {
    return 'Valoarea trebuie să fie cel puțin $min';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return 'Valoarea trebuie să fie cel mult $max';
  }

  @override
  String get dropdownSearchHintText => 'Tastați pentru a căuta...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return 'Eroare la încărcarea sugestiilor: $error';
  }

  @override
  String get dropdownSearchNoResults => 'Nu s-au găsit rezultate';

  @override
  String get dropdownSearchLoading => 'Se caută...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return 'Folosește \"$currentQuery\"';
  }

  @override
  String get requiredInfoSubtitle => '* Obligatoriu';

  @override
  String get inventoryWeightExample => 'ex. 250.5';

  @override
  String get unsavedChangesTitle => 'Modificări nesalvate';

  @override
  String get unsavedChangesMessage =>
      'Ai modificări nesalvate. Sigur vrei să renunți la ele?';

  @override
  String get unsavedChangesStay => 'Rămâi';

  @override
  String get unsavedChangesDiscard => 'Renunță';

  @override
  String beansWeightAddedBack(
    String amount,
    String beanName,
    String newWeight,
    String unit,
  ) {
    return 'Adăugat $amount$unit înapoi la $beanName. Greutate nouă: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
    String amount,
    String beanName,
    String newWeight,
    String unit,
  ) {
    return 'Scăzut $amount$unit din $beanName. Greutate nouă: $newWeight$unit';
  }

  @override
  String get notifications => 'Notificări';

  @override
  String get notificationsDisabledInSystemSettings =>
      'Dezactivat în setările sistemului';

  @override
  String get openSettings => 'Deschide setările';

  @override
  String get couldNotOpenLink => 'Nu s-a putut deschide linkul';

  @override
  String get notificationsDisabledDialogTitle =>
      'Notificări dezactivate în setările sistemului';

  @override
  String get notificationsDisabledDialogContent =>
      'Ai dezactivat notificările în setările dispozitivului. Pentru a le activa, deschide setările dispozitivului și permite notificările pentru Timer.Coffee.';

  @override
  String get notificationDebug => 'Depanare notificări';

  @override
  String get testNotificationSystem => 'Testează sistemul de notificări';

  @override
  String get notificationsEnabled => 'Activate';

  @override
  String get notificationsDisabled => 'Dezactivate';

  @override
  String get notificationPermissionDialogTitle => 'Activezi notificările?';

  @override
  String get notificationPermissionDialogMessage =>
      'Poți activa notificările pentru a primi actualizări utile (ex. despre versiuni noi ale aplicației). Notificările sunt necesare și pentru actualizări live ale progresului preparării. Activează acum sau schimbă asta oricând din setări.';

  @override
  String get notificationPermissionDialogMessageIos =>
      'Poți activa notificările pentru a primi actualizări utile (ex. despre versiuni noi ale aplicației). Notificările sunt necesare și pentru Live Activities și Dynamic Island pe iOS. Activează acum sau schimbă asta oricând din setări.';

  @override
  String get notificationPermissionDialogMessageAndroid =>
      'Poți activa notificările pentru a primi actualizări utile (ex. despre versiuni noi ale aplicației). Notificările sunt necesare și pentru Live Updates pe Android. Activează acum sau schimbă asta oricând din setări.';

  @override
  String get notificationPermissionEnable => 'Activează';

  @override
  String get notificationPermissionSkip => 'Nu acum';

  @override
  String get holidayGiftBoxTitle => 'Cutia Cadou de Sărbători';

  @override
  String get holidayGiftBoxInfoTrigger => 'Ce este asta?';

  @override
  String get holidayGiftBoxInfoBody =>
      'Oferte sezoniere curate de la parteneri. Linkurile nu sunt de afiliere - vrem doar să aducem puțină bucurie utilizatorilor Timer.Coffee în aceste sărbători. Trage în jos pentru actualizare oricând.';

  @override
  String get holidayGiftBoxNoOffers => 'Nicio ofertă disponibilă momentan.';

  @override
  String get holidayGiftBoxNoOffersSub =>
      'Trage pentru a actualiza sau încearcă mai târziu.';

  @override
  String holidayGiftBoxShowingRegion(String region) {
    return 'Afișăm oferte pentru $region';
  }

  @override
  String get holidayGiftBoxViewDetails => 'Vezi detalii';

  @override
  String get holidayGiftBoxPromoCopied => 'Cod promo copiat';

  @override
  String get holidayGiftBoxPromoCode => 'Cod promoțional';

  @override
  String giftDiscountOff(String percent) {
    return '$percent% reducere';
  }

  @override
  String giftDiscountUpToOff(String percent) {
    return 'Până la $percent% reducere';
  }

  @override
  String get holidayGiftBoxTerms => 'Termeni și condiții';

  @override
  String get holidayGiftBoxVisitSite => 'Vizitează site-ul partenerului';

  @override
  String holidayGiftBoxValidUntil(String date) {
    return 'Valabil până la $date';
  }

  @override
  String holidayGiftBoxEndsInDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Se încheie în $days de zile',
      few: 'Se încheie în $days zile',
      one: 'Se încheie mâine',
      zero: 'Se încheie astăzi',
    );
    return '$_temp0';
  }

  @override
  String get holidayGiftBoxValidWhileAvailable => 'Valabil în limita stocului';

  @override
  String holidayGiftBoxUpdated(String date) {
    return 'Actualizat la $date';
  }

  @override
  String holidayGiftBoxLanguage(String language) {
    return 'Limbă: $language';
  }

  @override
  String get holidayGiftBoxRetry => 'Reîncearcă';

  @override
  String get holidayGiftBoxLoadFailed => 'Nu s-au putut încărca ofertele';

  @override
  String get holidayGiftBoxOfferUnavailable => 'Oferta nu este disponibilă';

  @override
  String get holidayGiftBoxBannerTitle =>
      'Vezi cutia noastră cadou de sărbători';

  @override
  String get holidayGiftBoxBannerCta => 'Vezi oferte';

  @override
  String get regionEurope => 'Europa';

  @override
  String get regionNorthAmerica => 'America de Nord';

  @override
  String get regionAsia => 'Asia';

  @override
  String get regionAustralia => 'Australia / Oceania';

  @override
  String get regionWorldwide => 'În toată lumea';

  @override
  String get regionAfrica => 'Africa';

  @override
  String get regionMiddleEast => 'Orientul Mijlociu';

  @override
  String get regionSouthAmerica => 'America de Sud';

  @override
  String get setToZeroButton => 'Setează la zero';

  @override
  String get setToZeroDialogTitle => 'Setezi stocul la zero?';

  @override
  String get setToZeroDialogBody =>
      'Aceasta va seta cantitatea rămasă la 0 g. O poți edita mai târziu.';

  @override
  String get setToZeroDialogConfirm => 'Setează la zero';

  @override
  String get setToZeroDialogCancel => 'Anulare';

  @override
  String get inventorySetToZeroSuccess => 'Stoc setat la 0 g';

  @override
  String get inventorySetToZeroFail => 'Nu s-a putut seta stocul la zero';

  @override
  String get timePeriodThisYear => 'Anul acesta';

  @override
  String get timePeriodLastYear => 'Anul trecut';

  @override
  String get nativeAppPromoTitle => 'Descarcă aplicația Timer.Coffee';

  @override
  String get nativeAppPromoDescription =>
      'Bucură-te de experiența completă cu funcții exclusive: scanare etichete cafea cu AI, Activități Live pe ecranul de blocare, notificări push, feedback haptic și multe altele.';

  @override
  String get nativeAppPromoButton => 'Descarcă aplicația';

  @override
  String get addBrewEntry => 'Adaugă înregistrare preparare';

  @override
  String get selectBrewingMethod => 'Selectează metoda de preparare';

  @override
  String get selectRecipe => 'Selectează rețeta';

  @override
  String get brewDate => 'Data';

  @override
  String get brewTime => 'Ora';

  @override
  String get brewEntrySaved => 'Înregistrare preparare salvată';

  @override
  String get brewingMethodRequired => 'Selectează o metodă de preparare';

  @override
  String get recipeRequired => 'Selectează o rețetă';

  @override
  String get onboardingTitle => 'Bine ai venit la Timer.Coffee';

  @override
  String get onboardingSubtitle => 'Cu ce îți prepari cafeaua?';

  @override
  String get onboardingShowAll => 'Afișează toate metodele de preparare';

  @override
  String get coffeeJourneyTitle => 'Primii pași';

  @override
  String get coffeeJourneyMilestoneFirstBrew =>
      'Finalizează prima ta preparare';

  @override
  String get coffeeJourneyMilestoneTryMethod => 'Încearcă o altă rețetă';

  @override
  String get coffeeJourneyMilestoneAddBeans =>
      'Adaugă primele tale boabe de cafea';

  @override
  String get coffeeJourneyMilestoneFavorite => 'Adaugă o rețetă la favorite';

  @override
  String get coffeeJourneyMilestoneStats =>
      'Verifică-ți statisticile de preparare';

  @override
  String get coffeeJourneyMilestonePulse =>
      'Vezi cum prepară lumea cafea alături de tine';

  @override
  String get coffeeJourneyCompleted => 'Ți-ai finalizat primii pași!';

  @override
  String get coffeeJourneyDoneButton => 'Gata';

  @override
  String get coffeeJourneyDismissHint =>
      'Îți poți verifica oricând progresul în fila Mai mult.';

  @override
  String get coffeeJourneyDismissConfirm =>
      'Vrei să ascunzi progresul din secțiunea Primii pași?';

  @override
  String get coffeeJourneyHideButton => 'Ascunde';

  @override
  String get firstBrewCongrats =>
      'Felicitări pentru prima ta preparare! A fost salvată în Jurnal de Preparare.';

  @override
  String get firstBrewDiaryLink => 'Vezi Jurnal de Preparare';

  @override
  String get beanCoverPhoto => 'Fotografie de copertă';

  @override
  String get beanCoverPhotoAdd => 'Adaugă fotografie de copertă';

  @override
  String get beanCoverPhotoChange => 'Schimbă fotografia';

  @override
  String get beanCoverPhotoRemove => 'Elimină fotografia';

  @override
  String get beanCoverPhotoSavePromptTitle =>
      'Folosești ca fotografie de copertă?';

  @override
  String get beanCoverPhotoSavePromptBody =>
      'Dorești să salvezi una dintre imaginile scanate ca fotografie de copertă a acestui bob?';

  @override
  String get beanCoverPhotoUploading => 'Se încarcă fotografia…';

  @override
  String get beanCoverPhotoError => 'Încărcarea fotografiei a eșuat';

  @override
  String get beanCoverPhotoSignInPrompt =>
      'Autentifică-te pentru a adăuga o fotografie de copertă';

  @override
  String get settingsAnalyticsTitle => 'Confidențialitate și statistici';

  @override
  String get settingsAnalyticsBrews => 'Partajează statisticile de preparare';

  @override
  String get settingsAnalyticsBeans => 'Partajează statisticile boabelor';

  @override
  String get settingsAnalyticsGeneral =>
      'Partajează statisticile generale de utilizare';

  @override
  String get done => 'Gata';

  @override
  String get saving => 'Se salvează…';

  @override
  String get notifBrewReminderTitle => 'Îți lipsește ritualul cafelei?';

  @override
  String get notifBrewReminderBody =>
      'Au trecut câteva zile. Îți vine să mai prepari o cafea?';

  @override
  String get notifBrewReminderTitle2 => 'E timpul pentru o cafea?';

  @override
  String get notifBrewReminderBody2 =>
      'Echipamentul tău e pregătit când ești și tu.';

  @override
  String get notifBrewReminderTitle3 => 'Fierbătorul te cheamă';

  @override
  String get notifBrewReminderBody3 =>
      'O ceașcă bună e gata în doar câteva minute.';

  @override
  String get notifBrewEscalationTitle => 'Revii pentru încă o cafea?';

  @override
  String get notifBrewEscalationBody =>
      'A trecut ceva timp. Îți vine să prepari ceva bun?';

  @override
  String get notifBrewEscalationTitle2 => 'A trecut ceva timp?';

  @override
  String get notifBrewEscalationBody2 =>
      'Fără grabă. Echipamentul tău e pregătit când ești și tu.';

  @override
  String get notifBrewEscalationTitle3 => 'E din nou timpul pentru cafea?';

  @override
  String get notifBrewEscalationBody3 =>
      'O ceașcă foarte bună se poate prepara în doar câteva minute.';

  @override
  String get notifDiscoverBeansTitle => 'Ține evidența boabelor tale';

  @override
  String get notifDiscoverBeansBody =>
      'Notează-ți boabele și amintește-ți de cele care ți-au plăcut cel mai mult.';

  @override
  String get notifDiscoverPulseTitle => 'Vezi ce prepară alții';

  @override
  String get notifDiscoverPulseBody =>
      'Deschide Pulse ca să vezi preparări live din toată lumea.';

  @override
  String get notifBrewMilestoneTitle => 'Ai atins un prag important';

  @override
  String notifBrewMilestoneBody(int count) {
    return 'Ai preparat cafea de $count ori. Atinge pentru a-ți vedea progresul.';
  }

  @override
  String notifExploreRecipesTitle(String methodName) {
    return 'Încearcă o nouă rețetă de $methodName';
  }

  @override
  String notifExploreRecipesBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Până acum ai încercat $count de rețete. Iată încă una de încercat.',
      few: 'Până acum ai încercat $count rețete. Iată încă una de încercat.',
      one: 'Până acum ai încercat o rețetă. Iată încă una de încercat.',
    );
    return '$_temp0';
  }

  @override
  String get notifMorningTitle => 'Bună dimineața. Gata de preparat?';

  @override
  String get notifMorningBody => 'Începe ziua cu o ceașcă bună.';

  @override
  String get notifMorningTitle2 => 'Trezirea și cafeaua';

  @override
  String get notifMorningBody2 =>
      'Cafeaua de dimineață poate fi gata în doar câteva minute.';

  @override
  String get notifMorningTitle3 => 'Prima ceașcă a zilei?';

  @override
  String get notifMorningBody3 => 'Alege o rețetă și apucă-te de preparat.';

  @override
  String notifWeeklyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de preparări săptămâna aceasta',
      few: '$count preparări săptămâna aceasta',
      one: '1 preparare săptămâna aceasta',
    );
    return '$_temp0';
  }

  @override
  String notifWeeklyBody(int recipes) {
    String _temp0 = intl.Intl.pluralLogic(
      recipes,
      locale: localeName,
      other: 'În $recipes rețete. Atinge pentru a vedea detaliile.',
      one: 'Atinge pentru a vedea statisticile săptămânii.',
    );
    return '$_temp0';
  }

  @override
  String get notifBeanFreshnessTitle => 'E timpul pentru boabe proaspete?';

  @override
  String notifBeanFreshnessBody(String beanName, int days) {
    return 'Boabele tale $beanName au fost prăjite acum $days zile. S-ar putea să fi trecut de vârf.';
  }

  @override
  String get settingsNotificationsToggle => 'Activează notificările';

  @override
  String get settingsMorningReminder => 'Memento pentru cafeaua de dimineață';

  @override
  String get settingsMorningReminderSubtitle =>
      'Memento zilnic pentru cafeaua ta de dimineață';

  @override
  String get settingsMorningReminderTime => 'Ora mementoului';

  @override
  String get settingsWeeklySummary => 'Rezumat săptămânal';

  @override
  String get settingsWeeklySummarySubtitle =>
      'Recapitulare a preparărilor tale duminică seara';

  @override
  String get settingsBeanFreshness => 'Alerte pentru prospețimea boabelor';

  @override
  String get settingsBeanFreshnessSubtitle =>
      'Te anunță când boabele au fost prăjite de peste 3 săptămâni';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'acum $count de zile',
      few: 'acum $count zile',
      one: 'acum 1 zi',
    );
    return '$_temp0';
  }
}
