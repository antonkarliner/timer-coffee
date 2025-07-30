// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get lastrecipe => 'Ostatnio używany przepis:';

  @override
  String get about => 'O aplikacji';

  @override
  String get author => 'Autor';

  @override
  String get authortext =>
      'Aplikacja Timer.Coffee została stworzona przez Anton Karliner, entuzjastę kawy, specjalistę od mediów i fotoreportera. Mam nadzieję, że ta aplikacja pomoże Ci cieszyć się kawą. Zapraszamy do współpracy na GitHubie.';

  @override
  String get contributors => 'Współtwórcy';

  @override
  String get errorLoadingContributors => 'Błąd ładowania współtwórców';

  @override
  String get license => 'Licencja';

  @override
  String get licensetext =>
      'Ta aplikacja to wolne oprogramowanie: możesz je rozpowszechniać i/lub modyfikować na warunkach Ogólnej Licencji Publicznej GNU, jak to zostało opublikowane przez Free Software Foundation, albo wersji 3 tej Licencji, albo (według własnego wyboru) każdej późniejszej wersji.';

  @override
  String get licensebutton => 'Przeczytaj Ogólną Licencję Publiczną GNU v3';

  @override
  String get website => 'Strona internetowa';

  @override
  String get sourcecode => 'Kod źródłowy';

  @override
  String get support => 'Kup kawę dla programisty';

  @override
  String get allrecipes => 'Wszystkie przepisy';

  @override
  String get favoriterecipes => 'Ulubione przepisy';

  @override
  String get coffeeamount => 'Ilość kawy (g)';

  @override
  String get wateramount => 'Ilość wody (ml)';

  @override
  String get watertemp => 'Temperatura wody';

  @override
  String get grindsize => 'Wielkość mielenia';

  @override
  String get brewtime => 'Czas parzenia';

  @override
  String get recipesummary => 'Podsumowanie przepisu';

  @override
  String get recipesummarynote =>
      'Uwaga: to jest podstawowy przepis z domyślną ilością wody i kawy.';

  @override
  String get preparation => 'Przygotowanie';

  @override
  String get brewingprocess => 'Proces parzenia';

  @override
  String get step => 'Krok';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sekund',
      one: 'sekunda',
      zero: 'sekundy',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg =>
      'Dziękujemy za korzystanie z Timer.Coffee! Rozkoszuj się swoją';

  @override
  String get coffeefact => 'Ciekawostka o kawie';

  @override
  String get home => 'Strona główna';

  @override
  String get appversion => 'Wersja aplikacji';

  @override
  String get tipsmall => 'Kup małą kawę';

  @override
  String get tipmedium => 'Kup średnią kawę';

  @override
  String get tiplarge => 'Kup dużą kawę';

  @override
  String get supportdevelopment => 'Wesprzyj rozwój';

  @override
  String get supportdevmsg =>
      'Twoje datki pomagają pokryć koszty utrzymania (takie jak licencje deweloperskie, na przykład). Pozwalają mi również wypróbować więcej urządzeń do parzenia kawy i dodać więcej przepisów do aplikacji.';

  @override
  String get supportdevtnx => 'Dziękujemy za rozważenie wsparcia!';

  @override
  String get donationok => 'Dziękujemy!';

  @override
  String get donationtnx =>
      'Bardzo doceniam Twoje wsparcie! Życzę wielu wspaniałych parzeń! ☕️';

  @override
  String get donationerr => 'Błąd';

  @override
  String get donationerrmsg => 'Błąd przetwarzania zakupu, spróbuj ponownie.';

  @override
  String get sharemsg => 'Sprawdź ten przepis:';

  @override
  String get finishbrew => 'Zakończ';

  @override
  String get settings => 'Ustawienia';

  @override
  String get settingstheme => 'Motyw';

  @override
  String get settingsthemelight => 'Jasny';

  @override
  String get settingsthemedark => 'Ciemny';

  @override
  String get settingsthemesystem => 'System';

  @override
  String get settingslang => 'Język';

  @override
  String get sweet => 'Słodki';

  @override
  String get balance => 'Równowaga';

  @override
  String get acidic => 'Kwasowy';

  @override
  String get light => 'Lekki';

  @override
  String get strong => 'Mocny';

  @override
  String get slidertitle => 'Użyj suwaków, aby dostosować smak';

  @override
  String get whatsnewtitle => 'Co nowego';

  @override
  String get whatsnewclose => 'Zamknij';

  @override
  String get seasonspecials => 'Specjalne Oferty Sezonowe';

  @override
  String get snow => 'Śnieg';

  @override
  String get noFavoriteRecipesMessage =>
      'Twoja lista ulubionych przepisów jest obecnie pusta. Zacznij eksplorować i warzyć, aby odkryć swoje ulubione!';

  @override
  String get explore => 'Odkrywaj';

  @override
  String get dateFormat => 'd MMM, yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Dziennik Warzenia';

  @override
  String get brewdiarynotfound => 'Nie znaleziono wpisów';

  @override
  String get beans => 'Ziarna';

  @override
  String get roaster => 'Palarnia';

  @override
  String get rating => 'Ocena';

  @override
  String get notes => 'Notatki';

  @override
  String get statsscreen => 'Statystyki kawy';

  @override
  String get yourStats => 'Twoje statystyki';

  @override
  String get coffeeBrewed => 'Zaparzonej kawy:';

  @override
  String get litersUnit => 'l';

  @override
  String get mostUsedRecipes => 'Najczęściej używane przepisy:';

  @override
  String get globalStats => 'Statystyki globalne';

  @override
  String get unknownRecipe => 'Nieznany przepis';

  @override
  String get noData => 'Brak danych';

  @override
  String error(Object error) {
    return 'Błąd: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Ktoś właśnie zaparzył $recipeName';
  }

  @override
  String get timePeriodToday => 'Dzisiaj';

  @override
  String get timePeriodThisWeek => 'W tym tygodniu';

  @override
  String get timePeriodThisMonth => 'W tym miesiącu';

  @override
  String get timePeriodCustom => 'Niestandardowe';

  @override
  String get statsFor => 'Statystyki dla ';

  @override
  String get homescreenbrewcoffee => 'Parz kawę';

  @override
  String get homescreenhub => 'Hub';

  @override
  String get homescreenmore => 'Więcej';

  @override
  String get addBeans => 'Dodaj ziarna';

  @override
  String get removeBeans => 'Usuń ziarna';

  @override
  String get name => 'Nazwa';

  @override
  String get origin => 'Pochodzenie';

  @override
  String get details => 'Szczegóły';

  @override
  String get coffeebeans => 'Kawa ziarnista';

  @override
  String get loading => 'Ładowanie';

  @override
  String get nocoffeebeans => 'Nie znaleziono kawy ziarnistej';

  @override
  String get delete => 'Usuń';

  @override
  String get confirmDeleteTitle => 'Usunąć wpis?';

  @override
  String get confirmDeleteMessage =>
      'Czy na pewno chcesz usunąć ten wpis? Tej akcji nie można cofnąć.';

  @override
  String get removeFavorite => 'Usuń z ulubionych';

  @override
  String get addFavorite => 'Dodaj do ulubionych';

  @override
  String get toggleEditMode => 'Przełącz tryb edycji';

  @override
  String get coffeeBeansDetails => 'Szczegóły kawy ziarnistej';

  @override
  String get edit => 'Edytuj';

  @override
  String get coffeeBeansNotFound => 'Nie znaleziono kawy ziarnistej';

  @override
  String get geographyTerroir => 'Pochodzenie/Region';

  @override
  String get variety => 'Odmiana';

  @override
  String get region => 'Region';

  @override
  String get elevation => 'Wysokość';

  @override
  String get harvestDate => 'Data zbioru';

  @override
  String get processing => 'Obróbka';

  @override
  String get processingMethod => 'Metoda obróbki';

  @override
  String get roastDate => 'Data palenia';

  @override
  String get roastLevel => 'Stopień palenia';

  @override
  String get cuppingScore => 'Ocena sensoryczna';

  @override
  String get flavorProfile => 'Profil smakowy';

  @override
  String get tastingNotes => 'Nuty smakowe';

  @override
  String get additionalNotes => 'Dodatkowe notatki';

  @override
  String get noCoffeeBeans => 'Nie znaleziono kawy ziarnistej';

  @override
  String get editCoffeeBeans => 'Edytuj kawę ziarnistą';

  @override
  String get addCoffeeBeans => 'Dodaj kawę ziarnistą';

  @override
  String get showImagePicker => 'Pokaż wybór obrazu';

  @override
  String get pleaseNote => 'Uwaga';

  @override
  String get firstTimePopupMessage =>
      '1. Do przetwarzania obrazów używamy usług zewnętrznych. Kontynuując, wyrażasz na to zgodę.\n2. Chociaż nie przechowujemy twoich obrazów, unikaj umieszczania na nich danych osobowych.\n3. Rozpoznawanie obrazu jest obecnie ograniczone do 10 tokenów miesięcznie (1 token = 1 obraz). Ten limit może ulec zmianie w przyszłości.';

  @override
  String get ok => 'OK';

  @override
  String get takePhoto => 'Zrób zdjęcie';

  @override
  String get selectFromPhotos => 'Wybierz ze zdjęć';

  @override
  String get takeAdditionalPhoto => 'Zrobić kolejne zdjęcie?';

  @override
  String get no => 'Nie';

  @override
  String get yes => 'Tak';

  @override
  String get selectedImages => 'Wybrane obrazy';

  @override
  String get selectedImage => 'Wybrany obraz';

  @override
  String get backToSelection => 'Powrót do wyboru';

  @override
  String get next => 'Dalej';

  @override
  String get unexpectedErrorOccurred => 'Wystąpił nieoczekiwany błąd';

  @override
  String get tokenLimitReached =>
      'Przepraszamy, osiągnąłeś limit tokenów na rozpoznawanie obrazu w tym miesiącu';

  @override
  String get noCoffeeLabelsDetected =>
      'Nie wykryto etykiet kawy. Spróbuj z innym zdjęciem.';

  @override
  String get collectedInformation => 'Zebrane informacje';

  @override
  String get enterRoaster => 'Wprowadź palarnię';

  @override
  String get enterName => 'Wprowadź nazwę';

  @override
  String get enterOrigin => 'Wprowadź pochodzenie';

  @override
  String get optional => 'Opcjonalne';

  @override
  String get enterVariety => 'Wprowadź odmianę';

  @override
  String get enterProcessingMethod => 'Wprowadź metodę obróbki';

  @override
  String get enterRoastLevel => 'Wprowadź stopień palenia';

  @override
  String get enterRegion => 'Wprowadź region';

  @override
  String get enterTastingNotes => 'Wprowadź nuty smakowe';

  @override
  String get enterElevation => 'Wprowadź wysokość';

  @override
  String get enterCuppingScore => 'Wprowadź ocenę sensoryczną';

  @override
  String get enterNotes => 'Wprowadź notatki';

  @override
  String get selectHarvestDate => 'Wybierz datę zbioru';

  @override
  String get selectRoastDate => 'Wybierz datę palenia';

  @override
  String get selectDate => 'Wybierz datę';

  @override
  String get save => 'Zapisz';

  @override
  String get fillRequiredFields => 'Wypełnij wszystkie wymagane pola.';

  @override
  String get analyzing => 'Analizowanie';

  @override
  String get errorMessage => 'Błąd';

  @override
  String get selectCoffeeBeans => 'Wybierz kawę ziarnistą';

  @override
  String get addNewBeans => 'Dodaj nową kawę';

  @override
  String get favorite => 'Ulubione';

  @override
  String get notFavorite => 'Nieulubione';

  @override
  String get myBeans => 'Moje ziarna';

  @override
  String get signIn => 'Zaloguj';

  @override
  String get signOut => 'Wyloguj się';

  @override
  String get signInWithApple => 'Zaloguj się przez Apple';

  @override
  String get signInSuccessful => 'Pomyślnie zalogowano przez Apple';

  @override
  String get signInError => 'Błąd logowania przez Apple';

  @override
  String get signInWithGoogle => 'Zaloguj się przez Google';

  @override
  String get signOutSuccessful => 'Pomyślnie wylogowano';

  @override
  String get signInSuccessfulGoogle => 'Pomyślnie zalogowano za pomocą Google';

  @override
  String get signInWithEmail => 'Zaloguj się za pomocą poczty e-mail';

  @override
  String get enterEmail => 'Wpisz swój adres e-mail';

  @override
  String get emailHint => 'przykład@email.com';

  @override
  String get cancel => 'Anuluj';

  @override
  String get sendMagicLink => 'Wyślij magiczny link';

  @override
  String get magicLinkSent =>
      'Magiczny link został wysłany! Sprawdź swoją skrzynkę e-mail.';

  @override
  String get sendOTP => 'Wyślij OTP';

  @override
  String get otpSent => 'Kod OTP został wysłany na Twój adres email';

  @override
  String get otpSendError => 'Błąd podczas wysyłania kodu OTP';

  @override
  String get enterOTP => 'Wprowadź kod OTP';

  @override
  String get otpHint => 'Wprowadź 6-cyfrowy kod';

  @override
  String get verify => 'Zweryfikuj';

  @override
  String get signInSuccessfulEmail => 'Pomyślnie zalogowano';

  @override
  String get invalidOTP => 'Nieprawidłowy kod OTP';

  @override
  String get otpVerificationError => 'Błąd podczas weryfikacji kodu OTP';

  @override
  String get success => 'Sukces!';

  @override
  String get otpSentMessage =>
      'Kod OTP zostanie wysłany na Twój adres e-mail. Po otrzymaniu wprowadź go poniżej.';

  @override
  String get otpHint2 => 'Wprowadź kod tutaj';

  @override
  String get signInCreate => 'Zaloguj się / Utwórz konto';

  @override
  String get accountManagement => 'Zarządzanie kontem';

  @override
  String get deleteAccount => 'Usuń konto';

  @override
  String get deleteAccountWarning =>
      'Uwaga: jeśli kontynuujesz, usuniemy twoje konto i powiązane dane z naszych serwerów. Lokalne kopie danych pozostaną na urządzeniu. Jeśli chcesz je również usunąć, po prostu odinstaluj aplikację. Aby ponownie włączyć synchronizację, musisz ponownie utworzyć konto';

  @override
  String get deleteAccountConfirmation => 'Konto usunięte pomyślnie';

  @override
  String get accountDeleted => 'Konto zostało usunięte';

  @override
  String get accountDeletionError =>
      'Błąd podczas usuwania konta, spróbuj ponownie';

  @override
  String get deleteAccountTitle => 'Ważne';

  @override
  String get selectBeans => 'Wybierz ziarna';

  @override
  String get all => 'Wszystkie';

  @override
  String get selectRoaster => 'Wybierz palarnię';

  @override
  String get selectOrigin => 'Wybierz pochodzenie';

  @override
  String get resetFilters => 'Resetuj filtry';

  @override
  String get showFavoritesOnly => 'Pokaż tylko ulubione';

  @override
  String get apply => 'Zastosuj';

  @override
  String get selectSize => 'Wybierz rozmiar';

  @override
  String get sizeStandard => 'Standardowy';

  @override
  String get sizeMedium => 'Średni';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Mój rok z Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      'Hej, dziękujemy, że byłeś częścią wszechświata Timer.Coffee w tym roku!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'Po pierwsze.\nW tym roku zaparzyłeś kawę$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'Mówiąc dokładniej,\nW 2024 roku zaparzyłeś $liters litra kawy!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'Użyłeś ziaren od $roasterCount palarni';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Twoje 3 najlepsze palarnie to:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Kawa zabrała Cię w podróż\ndookoła świata$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'Spróbowałeś ziaren kawy\nz $originCount krajów!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Nie parzyłeś sam…';

  @override
  String get yearlyStatsStory7Part2 =>
      '...ale z użytkownikami ze 110 innych\nkrajów na 6 kontynentach!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Byłeś wierny sobie i korzystałeś tylko z tych $count metod parzenia w tym roku:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Odkrywałeś nowe smaki i używałeś $count metod parzenia w tym roku:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'Byłeś prawdziwym odkrywcą kawy i używałeś $count metod parzenia w tym roku:';
  }

  @override
  String get yearlyStatsStory9Text => 'Jeszcze tyle do odkrycia!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'Twoje 3 najlepsze przepisy w 2024 roku to$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'Do zobaczenia w 2025 roku!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Okaż trochę miłości ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Wpłać darowiznę';

  @override
  String get yearlyStatsActionShare => 'Udostępnij swoje postępy';

  @override
  String get yearlyStatsUnknown => 'Nieznane';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Nie udało się udostępnić: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Mój rok z Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes =>
      'Moje 3 najlepsze przepisy:';

  @override
  String get yearlyStatsShareProgressTop3Roasters =>
      'Moi 3 najlepsi producenci:';

  @override
  String get yearlyStatsFailedToLike =>
      'Nie udało się polubić. Spróbuj ponownie.';

  @override
  String get labelCoffeeBrewed => 'Zaparzona kawa';

  @override
  String get labelTastedBeansBy => 'Spróbowane ziarna od';

  @override
  String get labelDiscoveredCoffeeFrom => 'Odkryta kawa z';

  @override
  String get labelUsedBrewingMethods => 'Użyte';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'producentów',
      many: 'producentów',
      few: 'producentów',
      one: 'producent',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'krajów',
      many: 'krajów',
      few: 'kraje',
      one: 'kraj',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'metod parzenia',
      many: 'metod parzenia',
      few: 'metody parzenia',
      one: 'metoda parzenia',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Edytuj przepis';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Utwórz przepis';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Kroki przepisu';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Nazwa przepisu';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Krótki opis';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Metoda parzenia';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Ilość kawy (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Ilość wody (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Temperatura wody (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Rozmiar mielenia';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel =>
      'Całkowity czas parzenia:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Minuty';

  @override
  String get recipeCreationScreenSecondsLabel => 'Sekundy';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Krok przygotowania';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Krok parzenia $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Opis kroku';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Czas kroku: ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'Wprowadź nazwę przepisu';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Wprowadź krótki opis';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Wybierz metodę parzenia';

  @override
  String get recipeCreationScreenRequiredValidator => 'Wymagane';

  @override
  String get recipeCreationScreenInvalidNumberValidator =>
      'Nieprawidłowy numer';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Wprowadź opis kroku';

  @override
  String get recipeCreationScreenContinueButton => 'Przejdź do kroków przepisu';

  @override
  String get recipeCreationScreenAddStepButton => 'Dodaj krok';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Zapisz przepis';

  @override
  String get recipeCreationScreenUpdateSuccess =>
      'Przepis zaktualizowany pomyślnie';

  @override
  String get recipeCreationScreenSaveSuccess => 'Przepis zapisany pomyślnie';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Błąd podczas zapisywania przepisu: $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'gramy';

  @override
  String get unitMillilitersLong => 'mililitry';

  @override
  String get recipeCopySuccess => 'Przepis skopiowany pomyślnie!';

  @override
  String recipeCopyError(String error) {
    return 'Błąd podczas kopiowania przepisu: $error';
  }

  @override
  String get createRecipe => 'Utwórz przepis';

  @override
  String errorSyncingData(Object error) {
    return 'Błąd synchronizacji danych: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Błąd wylogowania: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Przygotowanie';

  @override
  String get loadingEllipsis => 'Ładowanie...';

  @override
  String get recipeDeletedSuccess => 'Przepis pomyślnie usunięty';

  @override
  String recipeDeleteError(Object error) {
    return 'Nie udało się usunąć przepisu: $error';
  }

  @override
  String get noRecipesFound => 'Nie znaleziono przepisów';

  @override
  String recipeLoadError(Object error) {
    return 'Nie udało się załadować przepisu: $error';
  }

  @override
  String get unknownBrewingMethod => 'Nieznana metoda parzenia';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Nie udało się załadować skopiowanego przepisu do edycji.';

  @override
  String get recipeCopyErrorOperationFailed => 'Operacja nie powiodła się.';

  @override
  String get notProvided => 'Nie podano';

  @override
  String get recipeUpdateFailedFetch =>
      'Nie udało się pobrać zaktualizowanych danych przepisu.';

  @override
  String get recipeImportSuccess => 'Przepis zaimportowany pomyślnie!';

  @override
  String get recipeImportFailedSave =>
      'Nie udało się zapisać zaimportowanego przepisu.';

  @override
  String get recipeImportFailedFetch =>
      'Nie udało się pobrać danych przepisu do importu.';

  @override
  String get recipeNotImported => 'Przepis nie został zaimportowany.';

  @override
  String get recipeNotFoundCloud =>
      'Przepis nie znaleziony w chmurze lub nie jest publiczny.';

  @override
  String get recipeLoadErrorGeneric => 'Błąd ładowania przepisu.';

  @override
  String get recipeUpdateAvailableTitle => 'Dostępna aktualizacja';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'Nowsza wersja \'$recipeName\' jest dostępna online. Zaktualizować?';
  }

  @override
  String get dialogCancel => 'Anuluj';

  @override
  String get dialogUpdate => 'Aktualizuj';

  @override
  String get recipeImportTitle => 'Importuj przepis';

  @override
  String recipeImportBody(String recipeName) {
    return 'Czy chcesz zaimportować przepis \'$recipeName\' z chmury?';
  }

  @override
  String get dialogImport => 'Importuj';

  @override
  String get moderationReviewNeededTitle => 'Wymagana weryfikacja moderacji';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'Następujące przepisy wymagają weryfikacji z powodu problemów z moderacją treści: $recipeNames';
  }

  @override
  String get dismiss => 'Odrzuć';

  @override
  String get reviewRecipeButton => 'Przejrzyj przepis';

  @override
  String get signInRequiredTitle => 'Wymagane zalogowanie';

  @override
  String get signInRequiredBodyShare =>
      'Musisz się zalogować, aby udostępniać własne przepisy.';

  @override
  String get syncSuccess => 'Synchronizacja zakończona pomyślnie!';

  @override
  String get tooltipEditRecipe => 'Edytuj przepis';

  @override
  String get tooltipCopyRecipe => 'Kopiuj przepis';

  @override
  String get tooltipShareRecipe => 'Udostępnij przepis';

  @override
  String get signInRequiredSnackbar => 'Wymagane zalogowanie';

  @override
  String get moderationErrorFunction =>
      'Sprawdzenie moderacji treści nie powiodło się.';

  @override
  String get moderationReasonDefault => 'Treść oznaczona do weryfikacji.';

  @override
  String get moderationFailedTitle => 'Moderacja nie powiodła się';

  @override
  String moderationFailedBody(String reason) {
    return 'Ten przepis nie może zostać udostępniony, ponieważ: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Błąd podczas udostępniania przepisu: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName na Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'Nie można sprawdzić statusu treści. Zapisano lokalnie, zostanie sprawdzone przy następnej synchronizacji.';

  @override
  String get saveLocallyModerationFailedTitle => 'Zmiany zapisane lokalnie';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Twoje lokalne zmiany zostały zapisane, ale wersja publiczna nie mogła zostać zaktualizowana z powodu moderacji treści: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Edytuj zaimportowany przepis';

  @override
  String get editImportedRecipeBody =>
      'To jest zaimportowany przepis. Edycja utworzy nową, niezależną kopię. Czy chcesz kontynuować?';

  @override
  String get editImportedRecipeButtonCopy => 'Utwórz kopię i edytuj';

  @override
  String get editImportedRecipeButtonCancel => 'Anuluj';

  @override
  String get editDisplayNameTitle => 'Edytuj nazwę wyświetlaną';

  @override
  String get displayNameHint => 'Wprowadź swoją nazwę wyświetlaną';

  @override
  String get displayNameEmptyError => 'Nazwa wyświetlana nie może być pusta';

  @override
  String get displayNameTooLongError =>
      'Nazwa wyświetlana nie może przekraczać 50 znaków';

  @override
  String get errorUserNotLoggedIn =>
      'Użytkownik nie jest zalogowany. Zaloguj się ponownie.';

  @override
  String get displayNameUpdateSuccess =>
      'Nazwa wyświetlana zaktualizowana pomyślnie!';

  @override
  String displayNameUpdateError(String error) {
    return 'Nie udało się zaktualizować nazwy wyświetlanej: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Usunąć zdjęcie?';

  @override
  String get deletePictureConfirmationBody =>
      'Czy na pewno chcesz usunąć swoje zdjęcie profilowe?';

  @override
  String get deletePictureSuccess => 'Zdjęcie profilowe usunięte.';

  @override
  String deletePictureError(String error) {
    return 'Nie udało się usunąć zdjęcia profilowego: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Nie udało się zaktualizować zdjęcia profilowego: $error';
  }

  @override
  String get updatePictureSuccess =>
      'Zdjęcie profilowe zaktualizowane pomyślnie!';

  @override
  String get deletePictureTooltip => 'Usuń zdjęcie';

  @override
  String get account => 'Konto';

  @override
  String get settingsBrewingMethodsTitle =>
      'Metody parzenia na ekranie głównym';

  @override
  String get filter => 'Filtr';

  @override
  String get sortBy => 'Sortuj według';

  @override
  String get dateAdded => 'Data dodania';

  @override
  String get secondsAbbreviation => 's';

  @override
  String get settingsAppIcon => 'Ikona aplikacji';

  @override
  String get settingsAppIconDefault => 'Domyślna';

  @override
  String get settingsAppIconLegacy => 'Stara';

  @override
  String get searchBeans => 'Szukaj ziaren...';

  @override
  String get favorites => 'Ulubione';

  @override
  String get searchPrefix => 'Szukaj: ';

  @override
  String get clearAll => 'Wyczyść wszystko';

  @override
  String get noBeansMatchSearch => 'Brak ziaren pasujących do wyszukiwania';

  @override
  String get clearFilters => 'Wyczyść filtry';

  @override
  String get farmer => 'Rolnik';

  @override
  String get farm => 'Farma kawy';

  @override
  String get enterFarmer => 'Wprowadź rolnika';

  @override
  String get enterFarm => 'Wprowadź farmę kawy';

  @override
  String get requiredInformation => 'Wymagane informacje';

  @override
  String get basicDetails => 'Podstawowe szczegóły';

  @override
  String get qualityMeasurements => 'Jakość i pomiary';

  @override
  String get importantDates => 'Ważne daty';
}
