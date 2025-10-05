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
  String get favoriteRoastersLabel => 'Prăjitorii favoriți';

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
      'Aplicația Timer.Coffee a fost creată de Anton Karliner, un entuziast al cafelei, specialist media și fotojurnalist. Sper că această aplicație vă va ajuta să vă bucurați de cafea. Simțiți-vă liber să contribuiți pe GitHub.';

  @override
  String get contributors => 'Contribuitori';

  @override
  String get errorLoadingContributors =>
      'Eroare la încărcarea contribuitorilor';

  @override
  String get license => 'Licență';

  @override
  String get licensetext =>
      'Această aplicație este un software liber: puteți redistribui și/sau modifica sub termenii Licenței Publice Generale GNU publicată de Free Software Foundation, fie versiunea 3 a Licenței, fie (la alegerea dvs.) orice versiune ulterioară.';

  @override
  String get licensebutton => 'Citește Licența Publică Generală GNU v3';

  @override
  String get website => 'Site web';

  @override
  String get sourcecode => 'Cod sursă';

  @override
  String get support => 'Cumpără-mi o cafea';

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
      other: 'secunde',
      one: 'secundă',
      zero: 'secunde',
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
      'Donările tale ajută la acoperirea costurilor de întreținere (cum ar fi licențele de dezvoltator, de exemplu). Ele îmi permit de asemenea să încerc mai multe dispozitive de preparare a cafelei și să adaug mai multe rețete în aplicație.';

  @override
  String get supportdevtnx => 'Mulțumim că iei în considerare să donezi!';

  @override
  String get donationok => 'Mulțumesc!';

  @override
  String get donationtnx =>
      'Apreciem foarte mult sprijinul tău! Îți dorim multe preparate grozave! ☕️';

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
  String get settingsthemelight => 'Luminos';

  @override
  String get settingsthemedark => 'Întunecat';

  @override
  String get settingsthemesystem => 'Sistem';

  @override
  String get settingslang => 'Limbă';

  @override
  String get sweet => 'Dulce';

  @override
  String get balance => 'Echilibrat';

  @override
  String get acidic => 'Acid';

  @override
  String get light => 'Luminos';

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
  String get brewdiary => 'Jurnal de Brăzdat';

  @override
  String get brewdiarynotfound => 'Nu s-au găsit înregistrări';

  @override
  String get beans => 'Boabe';

  @override
  String get roaster => 'Praji';

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
  String get noData => 'Fără date';

  @override
  String error(Object error) {
    return 'Eroare: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Cineva tocmai a preparat $recipeName';
  }

  @override
  String get timePeriodToday => 'Astăzi';

  @override
  String get timePeriodThisWeek => 'Săptămâna aceasta';

  @override
  String get timePeriodThisMonth => 'Luna aceasta';

  @override
  String get timePeriodCustom => 'Personalizat';

  @override
  String get statsFor => 'Statistici pentru ';

  @override
  String get homescreenbrewcoffee => 'Prepară cafea';

  @override
  String get homescreenhub => 'Hub';

  @override
  String get homescreenmore => 'Mai mult';

  @override
  String get addBeans => 'Adăugați boabe';

  @override
  String get removeBeans => 'Eliminați boabe';

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
  String get confirmDeleteTitle => 'Ștergeți înregistrarea?';

  @override
  String get confirmDeleteMessage =>
      'Sigur doriți să ștergeți această înregistrare? Această acțiune nu poate fi anulată.';

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
  String get pleaseNote => 'Vă rugăm să rețineți';

  @override
  String get firstTimePopupMessage =>
      '1. Folosim servicii externe pentru a procesa imaginile. Continuând, sunteți de acord cu acest lucru.\n2. Deși nu stocăm imaginile dvs., vă rugăm să evitați includerea oricăror detalii personale.\n3. Recunoașterea imaginilor este în prezent limitată la 10 jetoane pe lună (1 jeton = 1 imagine). Această limită se poate schimba în viitor.';

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
      'Ne pare rău, ați atins limita de jetoane pentru recunoașterea imaginilor luna aceasta';

  @override
  String get noCoffeeLabelsDetected =>
      'Nu au fost detectate etichete de cafea. Încercați cu o altă imagine.';

  @override
  String get collectedInformation => 'Informații colectate';

  @override
  String get enterRoaster => 'Introduceți prăjitorul';

  @override
  String get enterName => 'Introduceți numele';

  @override
  String get enterOrigin => 'Introduceți originea';

  @override
  String get optional => 'Opțional';

  @override
  String get enterVariety => 'Introduceți soiul';

  @override
  String get enterProcessingMethod => 'Introduceți metoda de procesare';

  @override
  String get enterRoastLevel => 'Introduceți nivelul de prăjire';

  @override
  String get enterRegion => 'Introduceți regiunea';

  @override
  String get enterTastingNotes => 'Introduceți notele de degustare';

  @override
  String get enterElevation => 'Introduceți altitudinea';

  @override
  String get enterCuppingScore => 'Introduceți scorul cupping';

  @override
  String get enterNotes => 'Introduceți note';

  @override
  String get inventory => 'Stoc';

  @override
  String get amountLeft => 'Cantitate rămasă';

  @override
  String get enterAmountLeft => 'Introdu cantitatea rămasă';

  @override
  String get selectHarvestDate => 'Selectați data recoltării';

  @override
  String get selectRoastDate => 'Selectați data prăjirii';

  @override
  String get selectDate => 'Selectați data';

  @override
  String get save => 'Salvează';

  @override
  String get fillRequiredFields =>
      'Vă rugăm să completați toate câmpurile obligatorii.';

  @override
  String get analyzing => 'Se analizează';

  @override
  String get errorMessage => 'Eroare';

  @override
  String get selectCoffeeBeans => 'Selectați boabele de cafea';

  @override
  String get addNewBeans => 'Adăugați boabe noi';

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
  String get signInWithApple => 'Conectați-vă cu Apple';

  @override
  String get signInSuccessful => 'Conectat cu succes cu Apple';

  @override
  String get signInError => 'Eroare la conectarea cu Apple';

  @override
  String get signInWithGoogle => 'Autentifică-te cu Google';

  @override
  String get signOutSuccessful => 'Deconectat cu succes';

  @override
  String get signInSuccessfulGoogle => 'Autentificat cu succes prin Google';

  @override
  String get signInWithEmail => 'Autentificați-vă cu e-mail';

  @override
  String get enterEmail => 'Introduceți adresa dvs. de e-mail';

  @override
  String get emailHint => 'exemplu@email.com';

  @override
  String get cancel => 'Anulare';

  @override
  String get sendMagicLink => 'Trimiteți link magic';

  @override
  String get magicLinkSent =>
      'Link-ul magic a fost trimis! Verificați-vă e-mailul.';

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
      'Un cod OTP este trimis la adresa dumneavoastră de email. Vă rugăm să îl introduceți mai jos când îl primiți.';

  @override
  String get otpHint2 => 'Introduceți codul aici';

  @override
  String get signInCreate => 'Autentificare / Creare cont';

  @override
  String get accountManagement => 'Administrarea contului';

  @override
  String get deleteAccount => 'Ștergeți contul';

  @override
  String get deleteAccountWarning =>
      'Rețineți că, dacă alegeți să continuați, vă vom șterge contul și datele asociate de pe serverele noastre. Copia locală a datelor va rămâne pe dispozitiv, dar dacă doriți să o ștergeți, puteți pur și simplu să ștergeți aplicația. Pentru a reactiva sincronizarea, va trebui să creați din nou un cont.';

  @override
  String get deleteAccountConfirmation => 'Contul șters cu succes';

  @override
  String get accountDeleted => 'Contul a fost șters';

  @override
  String get accountDeletionError =>
      'Eroare la ștergerea contului, vă rugăm să încercați din nou.';

  @override
  String get deleteAccountTitle => 'Important';

  @override
  String get selectBeans => 'Selectați boabele';

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
  String get apply => 'Se aplică';

  @override
  String get selectSize => 'Selectați dimensiunea';

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
  String yearlyStatsStory4Text(Object roasterCount) {
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
  String yearlyStatsStory6Text(Object originCount) {
    return 'Ai gustat boabe de cafea\ndin $originCount țări!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Nu ai preparat cafea singur…';

  @override
  String get yearlyStatsStory7Part2 =>
      '…ci alături de utilizatori din alte 110\nțări de pe 6 continente!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Ai rămas fidel gusturilor tale și ai folosit doar aceste $count metode de preparare anul acesta:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Ai descoperit gusturi noi și ai folosit $count metode de preparare anul acesta:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
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
  String get yearlyStatsFailedToLike => 'Nu s-a apreciat. Încercați din nou.';

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
      'Introduceți un nume pentru rețetă';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Introduceți o descriere scurtă';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Selectați o metodă de preparare';

  @override
  String get recipeCreationScreenRequiredValidator => 'Obligatoriu';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Număr invalid';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Introduceți o descriere pentru pas';

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
    return 'O versiune mai nouă a \'$recipeName\' este disponibilă online. Actualizați?';
  }

  @override
  String get dialogCancel => 'Anulați';

  @override
  String get dialogUpdate => 'Actualizați';

  @override
  String get recipeImportTitle => 'Importă rețeta';

  @override
  String recipeImportBody(String recipeName) {
    return 'Doriți să importați rețeta \'$recipeName\' din cloud?';
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
      'Aceasta este o rețetă importată. Editarea acesteia va crea o copie nouă, independentă. Doriți să continuați?';

  @override
  String get editImportedRecipeButtonCopy => 'Creează copie și editează';

  @override
  String get editImportedRecipeButtonCancel => 'Anulează';

  @override
  String get editDisplayNameTitle => 'Editează Numele Afișat';

  @override
  String get displayNameHint => 'Introduceți numele dvs. afișat';

  @override
  String get displayNameEmptyError => 'Numele afișat nu poate fi gol';

  @override
  String get displayNameTooLongError =>
      'Numele afișat nu poate depăși 50 de caractere';

  @override
  String get errorUserNotLoggedIn =>
      'Utilizatorul nu este autentificat. Vă rugăm să vă autentificați din nou.';

  @override
  String get displayNameUpdateSuccess =>
      'Numele afișat a fost actualizat cu succes!';

  @override
  String displayNameUpdateError(String error) {
    return 'Eroare la actualizarea numelui afișat: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Ștergeți Imaginea?';

  @override
  String get deletePictureConfirmationBody =>
      'Sunteți sigur că doriți să ștergeți poza de profil?';

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
  String get deletePictureTooltip => 'Șterge Imaginea';

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
  String get enterFarmer => 'Introduceți fermierul';

  @override
  String get enterFarm => 'Introduceți ferma de cafea';

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
      'Rețeta este publică - atingeți pentru a o face privată';

  @override
  String get recipePrivateTooltip =>
      'Rețeta este privată - partajați pentru a o face publică';

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
  String get unitFieldInvalidNumberError =>
      'Vă rugăm introduceți un număr valid';

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
  String get numericFieldInvalidNumberError =>
      'Vă rugăm introduceți un număr valid';

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
    return 'Folosiți \"$currentQuery\"';
  }

  @override
  String get requiredInfoSubtitle => '* Obligatoriu';

  @override
  String get inventoryWeightExample => 'ex. 250.5';
}
