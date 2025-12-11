// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'Статистика зерен';

  @override
  String get totalBeansBrewedLabel => 'Всього використано зерен';

  @override
  String get newBeansTriedLabel => 'Нові зерна, які спробували';

  @override
  String get originsExploredLabel => 'Досліджені країни походження';

  @override
  String get regionsExploredLabel => 'Європа';

  @override
  String get newRoastersDiscoveredLabel => 'Нові обсмажувачі, яких відкрито';

  @override
  String get favoriteRoastersLabel => 'Улюблені обсмажувальні';

  @override
  String get topOriginsLabel => 'Топ країни походження';

  @override
  String get topRegionsLabel => 'Топ регіони';

  @override
  String get lastrecipe => 'Останній використаний рецепт:';

  @override
  String get userRecipesTitle => 'Ваші рецепти';

  @override
  String get userRecipesSectionCreated => 'Створені вами';

  @override
  String get userRecipesSectionImported => 'Імпортовані вами';

  @override
  String get userRecipesEmpty => 'Рецептів не знайдено';

  @override
  String get userRecipesDeleteTitle => 'Видалити рецепт?';

  @override
  String get userRecipesDeleteMessage => 'Цю дію неможливо скасувати.';

  @override
  String get userRecipesDeleteConfirm => 'Видалити';

  @override
  String get userRecipesDeleteCancel => 'Скасувати';

  @override
  String get userRecipesSnackbarDeleted => 'Рецепт видалено';

  @override
  String get hubUserRecipesTitle => 'Ваші рецепти';

  @override
  String get hubUserRecipesSubtitle =>
      'Перегляд і керування створеними та імпортованими рецептами';

  @override
  String get hubAccountSubtitle => 'Керуйте своїм профілем';

  @override
  String get hubSignInCreateSubtitle =>
      'Увійдіть, щоб синхронізувати рецепти та налаштування';

  @override
  String get hubBrewDiarySubtitle =>
      'Переглядайте історію заварювань та додавайте нотатки';

  @override
  String get hubBrewStatsSubtitle =>
      'Переглядайте особисту та загальну статистику і тренди заварювань';

  @override
  String get hubSettingsSubtitle =>
      'Змінюйте налаштування додатку та поведінку';

  @override
  String get hubAboutSubtitle => 'Інформація про додаток, версія та учасники';

  @override
  String get about => 'Про програму';

  @override
  String get author => 'Автор';

  @override
  String get authortext =>
      'Додаток Timer.Coffee створено Антоном Карлінером, ентузіастом кави, медіаспеціалістом та фотожурналістом. Я сподіваюся, що цей додаток допоможе вам насолоджуватися кавою. Будь ласка, приєднуйтесь до спільноти на GitHub.';

  @override
  String get contributors => 'Учасники';

  @override
  String get errorLoadingContributors => 'Помилка завантаження учасників';

  @override
  String get license => 'Ліцензія';

  @override
  String get licensetext =>
      'Цей додаток є безкоштовним програмним забезпеченням: ви можете розповсюджувати його та/або модифікувати на умовах GNU General Public License, як опубліковано Free Software Foundation, або версії 3 Ліцензії, або (за вашим вибором) будь-якої пізнішої версії.';

  @override
  String get licensebutton => 'Прочитайте GNU General Public License v3';

  @override
  String get website => 'Вебсайт';

  @override
  String get sourcecode => 'Вихідний код';

  @override
  String get support => 'Купіть мені каву';

  @override
  String get allrecipes => 'Усі рецепти';

  @override
  String get favoriterecipes => 'Улюблені рецепти';

  @override
  String get coffeeamount => 'Кількість кави (г)';

  @override
  String get wateramount => 'Кількість води (мл)';

  @override
  String get watertemp => 'Температура води';

  @override
  String get grindsize => 'Розмір помелу';

  @override
  String get brewtime => 'Час заварювання';

  @override
  String get recipesummary => 'Підсумок рецепту';

  @override
  String get recipesummarynote =>
      'Примітка: це базовий рецепт із стандартними кількостями води та кави.';

  @override
  String get preparation => 'Підготовка';

  @override
  String get brewingprocess => 'Процес заварювання';

  @override
  String get step => 'Крок';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'секунд',
      one: 'секунда',
      zero: 'секунд',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg =>
      'Дякуємо, що користуєтесь Timer.Coffee! Насолоджуйтесь вашою';

  @override
  String get coffeefact => 'Факт про каву';

  @override
  String get home => 'Головна';

  @override
  String get appversion => 'Версія додатку';

  @override
  String get tipsmall => 'Купіть маленьку каву';

  @override
  String get tipmedium => 'Купіть середню каву';

  @override
  String get tiplarge => 'Купіть велику каву';

  @override
  String get supportdevelopment => 'Підтримайте розробку';

  @override
  String get supportdevmsg =>
      'Ваші пожертвування допомагають покривати витрати на утримання (наприклад, ліцензії для розробників). Вони також дозволяють мені пробувати більше пристроїв для заварювання кави та додавати більше рецептів до додатку.';

  @override
  String get supportdevtnx => 'Дякую, що розглядаєте можливість пожертвування!';

  @override
  String get donationok => 'Дякуємо!';

  @override
  String get donationtnx =>
      'Я дуже ціную вашу підтримку! Бажаю вам багато чудових заварювань! ☕️';

  @override
  String get donationerr => 'Помилка';

  @override
  String get donationerrmsg =>
      'Помилка обробки покупки, будь ласка, спробуйте ще раз.';

  @override
  String get sharemsg => 'Перегляньте цей рецепт:';

  @override
  String get finishbrew => 'Завершити';

  @override
  String get settings => 'Налаштування';

  @override
  String get settingstheme => 'Тема';

  @override
  String get settingsthemelight => 'Світла';

  @override
  String get settingsthemedark => 'Темна';

  @override
  String get settingsthemesystem => 'Системна';

  @override
  String get settingslang => 'Мова';

  @override
  String get sweet => 'Солодкий';

  @override
  String get balance => 'Збалансований';

  @override
  String get acidic => 'Кислий';

  @override
  String get light => 'Легкий';

  @override
  String get strong => 'Міцний';

  @override
  String get slidertitle => 'Використовуйте слайдери для коригування смаку';

  @override
  String get whatsnewtitle => 'Що нового';

  @override
  String get whatsnewclose => 'Закрити';

  @override
  String get seasonspecials => 'Спеціальні пропозиції сезону';

  @override
  String get snow => 'Сніг';

  @override
  String get noFavoriteRecipesMessage =>
      'Ваш список улюблених рецептів наразі порожній. Почніть досліджувати та заварювати, щоб відкрити для себе улюблені!';

  @override
  String get explore => 'Досліджувати';

  @override
  String get dateFormat => 'd MMM yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Щоденник Заварок';

  @override
  String get brewdiarynotfound => 'Записів не знайдено';

  @override
  String get beans => 'Зерна';

  @override
  String get roaster => 'Обсмажувальня';

  @override
  String get rating => 'Оцінка';

  @override
  String get notes => 'Нотатки';

  @override
  String get statsscreen => 'Статистика кави';

  @override
  String get yourStats => 'Ваша статистика';

  @override
  String get coffeeBrewed => 'Зварено кави:';

  @override
  String get litersUnit => 'л';

  @override
  String get mostUsedRecipes => 'Найчастіше використовувані рецепти:';

  @override
  String get globalStats => 'Глобальна статистика';

  @override
  String get unknownRecipe => 'Невідомий рецепт';

  @override
  String get noData => 'Дані відсутні';

  @override
  String error(String error) {
    return 'Помилка: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Хтось щойно заварив $recipeName';
  }

  @override
  String get timePeriodToday => 'сьогодні';

  @override
  String get timePeriodThisWeek => 'цього тижня';

  @override
  String get timePeriodThisMonth => 'цього місяця';

  @override
  String get timePeriodCustom => 'Індивідуально';

  @override
  String get statsFor => 'Статистика для ';

  @override
  String get homescreenbrewcoffee => 'Заварити каву';

  @override
  String get homescreenhub => 'Центр';

  @override
  String get homescreenmore => 'Ще';

  @override
  String get addBeans => 'Додати зерна';

  @override
  String get removeBeans => 'Прибрати зерна';

  @override
  String get name => 'Назва';

  @override
  String get origin => 'Походження';

  @override
  String get details => 'Деталі';

  @override
  String get coffeebeans => 'Зерна кави';

  @override
  String get loading => 'Завантаження';

  @override
  String get nocoffeebeans => 'Зерна кави не знайдені';

  @override
  String get delete => 'Видалити';

  @override
  String get confirmDeleteTitle => 'Видалити запис?';

  @override
  String get recipeDuplicateConfirmTitle => 'Дублювати рецепт?';

  @override
  String get recipeDuplicateConfirmMessage =>
      'Це створить копію вашого рецепту, яку ви зможете редагувати незалежно. Чи хочете продовжити?';

  @override
  String get confirmDeleteMessage =>
      'Ви впевнені, що хочете видалити цей запис? Цю дію не можна скасувати.';

  @override
  String get removeFavorite => 'Видалити з обраного';

  @override
  String get addFavorite => 'Додати до обраного';

  @override
  String get toggleEditMode => 'Перемкнути режим редагування';

  @override
  String get coffeeBeansDetails => 'Інформація про зерна кави';

  @override
  String get edit => 'Редагувати';

  @override
  String get coffeeBeansNotFound => 'Зерна кави не знайдені';

  @override
  String get basicInformation => 'Основні відомості';

  @override
  String get geographyTerroir => 'Географія/Територія';

  @override
  String get variety => 'Сорт';

  @override
  String get region => 'Північна Америка';

  @override
  String get elevation => 'Висота';

  @override
  String get harvestDate => 'Дата збору врожаю';

  @override
  String get processing => 'Обробка';

  @override
  String get processingMethod => 'Спосіб обробки';

  @override
  String get roastDate => 'Дата обсмажування';

  @override
  String get roastLevel => 'Ступінь обсмажування';

  @override
  String get cuppingScore => 'Оцінка дегустації';

  @override
  String get flavorProfile => 'Смаковий профіль';

  @override
  String get tastingNotes => 'Смакові ноти';

  @override
  String get additionalNotes => 'Додаткові нотатки';

  @override
  String get noCoffeeBeans => 'Зерна кави не знайдені';

  @override
  String get editCoffeeBeans => 'Редагувати зерна кави';

  @override
  String get addCoffeeBeans => 'Додати зерна кави';

  @override
  String get showImagePicker => 'Показати вибір зображень';

  @override
  String get pleaseNote => 'Зверніть увагу';

  @override
  String get firstTimePopupMessage =>
      '1. Ми використовуємо зовнішні сервіси для обробки зображень. Продовжуючи, ви погоджуєтесь з цим.\n2. Хоча ми не зберігаємо ваші зображення, уникайте додавання будь-якої особистої інформації.\n3. Розпізнавання зображень наразі обмежене 10 токенами на місяць (1 токен = 1 зображення). Цей ліміт може бути змінено в майбутньому.';

  @override
  String get ok => 'OK';

  @override
  String get takePhoto => 'Зробити фото';

  @override
  String get selectFromPhotos => 'Вибрати з фотографій';

  @override
  String get takeAdditionalPhoto => 'Зробити ще одне фото?';

  @override
  String get no => 'Ні';

  @override
  String get yes => 'Так';

  @override
  String get selectedImages => 'Обрані зображення';

  @override
  String get selectedImage => 'Обране зображення';

  @override
  String get backToSelection => 'Повернутися до вибору';

  @override
  String get next => 'Далі';

  @override
  String get unexpectedErrorOccurred => 'Сталася неочікувана помилка';

  @override
  String get tokenLimitReached =>
      'Вибачте, ви досягли ліміту токенів для розпізнавання зображень у цьому місяці';

  @override
  String get noCoffeeLabelsDetected =>
      'Мітки кави не виявлені. Спробуйте інше зображення.';

  @override
  String get collectedInformation => 'Зібрана інформація';

  @override
  String get enterRoaster => 'Введіть обсмажувальника';

  @override
  String get enterName => 'Введіть назву';

  @override
  String get enterOrigin => 'Введіть походження';

  @override
  String get optional => 'Необов’язково';

  @override
  String get enterVariety => 'Введіть сорт';

  @override
  String get enterProcessingMethod => 'Введіть метод обробки';

  @override
  String get enterRoastLevel => 'Введіть ступінь обсмажування';

  @override
  String get enterRegion => 'Введіть регіон';

  @override
  String get enterTastingNotes => 'Введіть смакові ноти';

  @override
  String get enterElevation => 'Введіть висоту';

  @override
  String get enterCuppingScore => 'Введіть оцінку дегустації';

  @override
  String get enterNotes => 'Введіть нотатки';

  @override
  String get inventory => 'Запаси';

  @override
  String get amountLeft => 'Залишок';

  @override
  String get enterAmountLeft => 'Введіть залишок';

  @override
  String get selectHarvestDate => 'Виберіть дату збору врожаю';

  @override
  String get selectRoastDate => 'Виберіть дату обсмажування';

  @override
  String get selectDate => 'Виберіть дату';

  @override
  String get save => 'Зберегти';

  @override
  String get fillRequiredFields =>
      'Будь ласка, заповніть всі обов’язкові поля.';

  @override
  String get analyzing => 'Аналіз';

  @override
  String get errorMessage => 'Помилка';

  @override
  String get selectCoffeeBeans => 'Виберіть зерна кави';

  @override
  String get addNewBeans => 'Додати нові зерна';

  @override
  String get favorite => 'Улюблений';

  @override
  String get notFavorite => 'Не улюблений';

  @override
  String get myBeans => 'Мої кавові зерна';

  @override
  String get signIn => 'Увійти';

  @override
  String get signOut => 'Вийти';

  @override
  String get signInWithApple => 'Увійти за допомогою Apple';

  @override
  String get signInSuccessful => 'Вхід за допомогою Apple успішний';

  @override
  String get signInError => 'Помилка входу за допомогою Apple';

  @override
  String get signInWithGoogle => 'Увійти за допомогою Google';

  @override
  String get signOutSuccessful => 'Вихід успішно виконано';

  @override
  String get signInSuccessfulGoogle =>
      'Вхід за допомогою Google виконано успішно';

  @override
  String get signInWithEmail => 'Увійти за допомогою електронної пошти';

  @override
  String get enterEmail => 'Введіть адресу електронної пошти';

  @override
  String get emailHint => 'приклад@електронна_пошта.com';

  @override
  String get cancel => 'Скасувати';

  @override
  String get sendMagicLink => 'Надіслати чарівне посилання';

  @override
  String get magicLinkSent =>
      'Чарівне посилання надіслано! Перевірте свою електронну пошту.';

  @override
  String get sendOTP => 'Надіслати OTP';

  @override
  String get otpSent => 'OTP надіслано на вашу електронну пошту';

  @override
  String get otpSendError => 'Помилка надсилання OTP';

  @override
  String get enterOTP => 'Введіть OTP';

  @override
  String get otpHint => 'Введіть 6-значний код';

  @override
  String get verify => 'Перевірити';

  @override
  String get signInSuccessfulEmail => 'Вхід успішний';

  @override
  String get invalidOTP => 'Недійсний OTP';

  @override
  String get otpVerificationError => 'Помилка перевірки OTP';

  @override
  String get success => '¡Éxito!';

  @override
  String get otpSentMessage =>
      'OTP-код буде надіслано на вашу електронну пошту. Будь ласка, введіть його, коли отримаєте.';

  @override
  String get otpHint2 => 'Введіть код тут';

  @override
  String get signInCreate => 'Вхід / Створити обліковий запис';

  @override
  String get accountManagement => 'Управління обліковим записом';

  @override
  String get deleteAccount => 'Видалити обліковий запис';

  @override
  String get deleteAccountWarning =>
      'Зверніть увагу: якщо ви вирішите продовжити, ми видалимо ваш обліковий запис і пов\'язані з ним дані з наших серверів. Локальна копія даних залишиться на пристрої, якщо ви хочете видалити її також, ви можете просто видалити програму. Щоб знову ввімкнути синхронізацію, вам потрібно буде створити обліковий запис знову';

  @override
  String get deleteAccountConfirmation => 'Обліковий запис успішно видалено';

  @override
  String get accountDeleted => 'Обліковий запис видалено';

  @override
  String get accountDeletionError =>
      'Помилка видалення облікового запису, спробуйте ще раз';

  @override
  String get deleteAccountTitle => 'Увага';

  @override
  String get selectBeans => 'Виберіть зерна';

  @override
  String get all => 'Усі';

  @override
  String get selectRoaster => 'Виберіть обсмажувача';

  @override
  String get selectOrigin => 'Виберіть походження';

  @override
  String get resetFilters => 'Скинути фільтри';

  @override
  String get showFavoritesOnly => 'Показати тільки обране';

  @override
  String get apply => 'Застосувати';

  @override
  String get selectSize => 'Виберіть розмір';

  @override
  String get sizeStandard => 'Стандартний';

  @override
  String get sizeMedium => 'Середній';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Мій рік з Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      'Привіт! Дякуємо, що були частиною спільноти Timer.Coffee цього року!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'Почнемо з головного.\nЦього року ви зварили кави$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'Якщо бути точніше,\nви зварили $liters літрів кави у 2024 році!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'Ви використовували зерна від $roasterCount обсмажувачів';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Ваші 3 найкращі обсмажувачі:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Кава повела вас у подорож\nсвітом$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'Ви скуштували кавові зерна\nз $originCount країн!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Ви варили каву не самі…';

  @override
  String get yearlyStatsStory7Part2 =>
      '…а разом з користувачами з 110 інших\nкраїн на 6 континентах!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Ви залишилися вірними собі та використовували лише ці $count способи заварювання цього року:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Ви відкривали для себе нові смаки та використовували $count способів заварювання цього року:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'Ви були справжнім першовідкривачем кави та використовували $count способів заварювання цього року:';
  }

  @override
  String get yearlyStatsStory9Text => 'Стільки всього ще належить відкрити!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'Ваші 3 найкращі рецепти у 2024 році$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'Побачимося у 2025 році!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Поділіться любов’ю ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Зробити пожертвування';

  @override
  String get yearlyStatsActionShare => 'Поділитися своїм прогресом';

  @override
  String get yearlyStatsUnknown => 'Невідомо';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Не вдалося поділитися: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Мій рік з Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes => 'Мої 3 найкращі рецепти:';

  @override
  String get yearlyStatsShareProgressTop3Roasters =>
      'Мої 3 найкращі обсмажувальники:';

  @override
  String get yearlyStatsFailedToLike =>
      'Не вдалося поставити лайк. Спробуйте ще раз.';

  @override
  String get labelCoffeeBrewed => 'Кава зварена';

  @override
  String get labelTastedBeansBy => 'Зерна, що скуштували:';

  @override
  String get labelDiscoveredCoffeeFrom => 'Відкрита кава з';

  @override
  String get labelUsedBrewingMethods => 'Використано';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# обсмажувальникa',
      many: '# обсмажувальників',
      few: '# обсмажувальники',
      one: '# обсмажувальник',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# країни',
      many: '# країн',
      few: '# країни',
      one: '# країна',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# способу заварювання',
      many: '# способів заварювання',
      few: '# способи заварювання',
      one: '# спосіб заварювання',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Редагувати рецепт';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Створити рецепт';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Кроки рецепту';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Назва рецепту';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Короткий опис';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Метод заварювання';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Кількість кави (г)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Кількість води (мл)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Температура води (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Розмір помелу';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel =>
      'Загальний час заварювання:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Хвилини';

  @override
  String get recipeCreationScreenSecondsLabel => 'Секунди';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Крок підготовки';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Крок заварювання $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Опис кроку';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Час кроку: ';

  @override
  String get recipeCreationScreenRecipeNameValidator => 'Введіть назву рецепту';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Введіть короткий опис';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Виберіть метод заварювання';

  @override
  String get recipeCreationScreenRequiredValidator => 'Обов\'язково';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Недійсний номер';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Введіть опис кроку';

  @override
  String get recipeCreationScreenContinueButton => 'Перейти до кроків рецепту';

  @override
  String get recipeCreationScreenAddStepButton => 'Додати крок';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Зберегти рецепт';

  @override
  String get recipeCreationScreenUpdateSuccess => 'Рецепт успішно оновлено';

  @override
  String get recipeCreationScreenSaveSuccess => 'Рецепт успішно збережено';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Помилка збереження рецепту: $error';
  }

  @override
  String get unitGramsShort => 'г';

  @override
  String get unitMillilitersShort => 'мл';

  @override
  String get unitGramsLong => 'грами';

  @override
  String get unitMillilitersLong => 'мілілітри';

  @override
  String get recipeCopySuccess => 'Рецепт успішно скопійовано!';

  @override
  String get recipeDuplicateSuccess => 'Рецепт успішно дубльовано!';

  @override
  String recipeCopyError(String error) {
    return 'Помилка копіювання рецепту: $error';
  }

  @override
  String get createRecipe => 'Створити рецепт';

  @override
  String errorSyncingData(Object error) {
    return 'Помилка синхронізації даних: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Помилка виходу: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Підготовка';

  @override
  String get loadingEllipsis => 'Завантаження...';

  @override
  String get recipeDeletedSuccess => 'Рецепт успішно видалено';

  @override
  String recipeDeleteError(Object error) {
    return 'Не вдалося видалити рецепт: $error';
  }

  @override
  String get noRecipesFound => 'Рецепти не знайдено';

  @override
  String recipeLoadError(Object error) {
    return 'Не вдалося завантажити рецепт: $error';
  }

  @override
  String get unknownBrewingMethod => 'Невідомий метод заварювання';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Не вдалося завантажити скопійований рецепт для редагування.';

  @override
  String get recipeCopyErrorOperationFailed => 'Операція не вдалася.';

  @override
  String get notProvided => 'Не надано';

  @override
  String get recipeUpdateFailedFetch =>
      'Не вдалося отримати оновлені дані рецепту.';

  @override
  String get recipeImportSuccess => 'Рецепт успішно імпортовано!';

  @override
  String get recipeImportFailedSave =>
      'Не вдалося зберегти імпортований рецепт.';

  @override
  String get recipeImportFailedFetch =>
      'Не вдалося отримати дані рецепту для імпорту.';

  @override
  String get recipeNotImported => 'Рецепт не імпортовано.';

  @override
  String get recipeNotFoundCloud =>
      'Рецепт не знайдено в хмарі або він не є публічним.';

  @override
  String get recipeLoadErrorGeneric => 'Помилка завантаження рецепту.';

  @override
  String get recipeUpdateAvailableTitle => 'Доступне оновлення';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'Нова версія \'$recipeName\' доступна онлайн. Оновити?';
  }

  @override
  String get dialogCancel => 'Скасувати';

  @override
  String get dialogDuplicate => 'Дублювати';

  @override
  String get dialogUpdate => 'Оновити';

  @override
  String get recipeImportTitle => 'Імпортувати рецепт';

  @override
  String recipeImportBody(String recipeName) {
    return 'Ви хочете імпортувати рецепт \'$recipeName\' з хмари?';
  }

  @override
  String get dialogImport => 'Імпортувати';

  @override
  String get moderationReviewNeededTitle => 'Потрібна перевірка модератором';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'Наступний(і) рецепт(и) потребує(ють) перевірки через проблеми з модерацією контенту: $recipeNames';
  }

  @override
  String get dismiss => 'Відхилити';

  @override
  String get reviewRecipeButton => 'Переглянути рецепт';

  @override
  String get signInRequiredTitle => 'Потрібен вхід';

  @override
  String get signInRequiredBodyShare =>
      'Вам потрібно увійти, щоб ділитися власними рецептами.';

  @override
  String get syncSuccess => 'Синхронізація успішна!';

  @override
  String get tooltipEditRecipe => 'Редагувати рецепт';

  @override
  String get tooltipCopyRecipe => 'Копіювати рецепт';

  @override
  String get tooltipDuplicateRecipe => 'Дублювати рецепт';

  @override
  String get tooltipShareRecipe => 'Поділитися рецептом';

  @override
  String get signInRequiredSnackbar => 'Потрібен вхід';

  @override
  String get moderationErrorFunction =>
      'Перевірка модерації контенту не вдалася.';

  @override
  String get moderationReasonDefault => 'Контент позначено для перевірки.';

  @override
  String get moderationFailedTitle => 'Модерація не вдалася';

  @override
  String moderationFailedBody(String reason) {
    return 'Цей рецепт не може бути опублікований, оскільки: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Помилка при публікації рецепту: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName на Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'Не вдалося перевірити статус контенту. Збережено локально, буде перевірено при наступній синхронізації.';

  @override
  String get saveLocallyModerationFailedTitle => 'Зміни збережено локально';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Ваші локальні зміни збережено, але публічна версія не може бути оновлена через модерацію контенту: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Редагувати імпортований рецепт';

  @override
  String get editImportedRecipeBody =>
      'Це імпортований рецепт. Редагування створить нову, незалежну копію. Продовжити?';

  @override
  String get editImportedRecipeButtonCopy => 'Створити копію та редагувати';

  @override
  String get editImportedRecipeButtonCancel => 'Скасувати';

  @override
  String get editDisplayNameTitle => 'Редагувати ім\'я для відображення';

  @override
  String get displayNameHint => 'Введіть ваше ім\'я для відображення';

  @override
  String get displayNameEmptyError =>
      'Ім\'я для відображення не може бути порожнім';

  @override
  String get displayNameTooLongError =>
      'Ім\'я для відображення не може перевищувати 50 символів';

  @override
  String get errorUserNotLoggedIn =>
      'Користувач не увійшов до системи. Будь ласка, увійдіть знову.';

  @override
  String get displayNameUpdateSuccess =>
      'Ім\'я для відображення успішно оновлено!';

  @override
  String displayNameUpdateError(String error) {
    return 'Не вдалося оновити ім\'я для відображення: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Видалити зображення?';

  @override
  String get deletePictureConfirmationBody =>
      'Ви впевнені, що хочете видалити зображення профілю?';

  @override
  String get deletePictureSuccess => 'Зображення профілю видалено.';

  @override
  String deletePictureError(String error) {
    return 'Не вдалося видалити зображення профілю: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Не вдалося оновити зображення профілю: $error';
  }

  @override
  String get updatePictureSuccess => 'Зображення профілю успішно оновлено!';

  @override
  String get deletePictureTooltip => 'Видалити зображення';

  @override
  String get account => 'Обліковий запис';

  @override
  String get settingsBrewingMethodsTitle =>
      'Методи заварювання на головному екрані';

  @override
  String get filter => 'Фільтр';

  @override
  String get sortBy => 'Сортувати за';

  @override
  String get dateAdded => 'Дата додавання';

  @override
  String get secondsAbbreviation => 'с.';

  @override
  String get settingsAppIcon => 'Іконка додатку';

  @override
  String get settingsAppIconDefault => 'За замовчуванням';

  @override
  String get settingsAppIconLegacy => 'Стара';

  @override
  String get searchBeans => 'Пошук зерен...';

  @override
  String get favorites => 'Обране';

  @override
  String get searchPrefix => 'Пошук: ';

  @override
  String get clearAll => 'Очистити все';

  @override
  String get noBeansMatchSearch => 'Жодне зерно не відповідає вашому пошуку';

  @override
  String get clearFilters => 'Очистити фільтри';

  @override
  String get farmer => 'Фермер';

  @override
  String get farm => 'Ферма';

  @override
  String get enterFarmer => 'Введіть фермера (необов\'язково)';

  @override
  String get enterFarm => 'Введіть ферму (необов\'язково)';

  @override
  String get requiredInformation => 'Необхідна інформація';

  @override
  String get basicDetails => 'Основні деталі';

  @override
  String get qualityMeasurements => 'Якість та вимірювання';

  @override
  String get importantDates => 'Важливі дати';

  @override
  String get brewStats => 'Статистика приготування';

  @override
  String get showMore => 'Показати ще';

  @override
  String get showLess => 'Показати менше';

  @override
  String get unpublishRecipeDialogTitle => 'Зробити рецепт приватним';

  @override
  String get unpublishRecipeDialogMessage =>
      'Попередження: Якщо зробити цей рецепт приватним, це призведе до наступного:';

  @override
  String get unpublishRecipeDialogBullet1 =>
      'Його буде видалено з результатів публічного пошуку';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'Нові користувачі не зможуть його імпортувати';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'Користувачі, які вже імпортували його, збережуть свої копії';

  @override
  String get unpublishRecipeDialogKeepPublic => 'Залишити публічним';

  @override
  String get unpublishRecipeDialogMakePrivate => 'Зробити приватним';

  @override
  String get recipeUnpublishSuccess => 'Публікацію рецепта успішно скасовано';

  @override
  String recipeUnpublishError(String error) {
    return 'Помилка при скасуванні публікації рецепта: $error';
  }

  @override
  String get recipePublicTooltip =>
      'Рецепт є публічним - торкніться, щоб зробити його приватним';

  @override
  String get recipePrivateTooltip =>
      'Рецепт є приватним - поділіться, щоб зробити його публічним';

  @override
  String get fieldClearButtonTooltip => 'Очистити';

  @override
  String get dateFieldClearButtonTooltip => 'Очистити дату';

  @override
  String get chipInputDuplicateError => 'Цей тег вже додано';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return 'Досягнуто максимальної кількості тегів ($maxChips)';
  }

  @override
  String get chipInputHintText => 'Додати тег...';

  @override
  String get unitFieldRequiredError => 'Це поле є обов\'язковим';

  @override
  String get unitFieldInvalidNumberError => 'Будь ласка, введіть дійсне число';

  @override
  String unitFieldMinValueError(Object min) {
    return 'Значення має бути не менше $min';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return 'Значення має бути не більше $max';
  }

  @override
  String get numericFieldRequiredError => 'Це поле є обов\'язковим';

  @override
  String get numericFieldInvalidNumberError =>
      'Будь ласка, введіть дійсне число';

  @override
  String numericFieldMinValueError(Object min) {
    return 'Значення має бути не менше $min';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return 'Значення має бути не більше $max';
  }

  @override
  String get dropdownSearchHintText => 'Введіть для пошуку...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return 'Помилка завантаження пропозицій: $error';
  }

  @override
  String get dropdownSearchNoResults => 'Результатів не знайдено';

  @override
  String get dropdownSearchLoading => 'Пошук...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return 'Використати \"$currentQuery\"';
  }

  @override
  String get requiredInfoSubtitle => '* Обов\'язково';

  @override
  String get inventoryWeightExample => 'напр., 250.5';

  @override
  String get unsavedChangesTitle => 'Незбережені зміни';

  @override
  String get unsavedChangesMessage =>
      'У вас є незбережені зміни. Ви впевнені, що хочете їх скасувати?';

  @override
  String get unsavedChangesStay => 'Залишитися';

  @override
  String get unsavedChangesDiscard => 'Скасувати';

  @override
  String beansWeightAddedBack(
      String amount, String beanName, String newWeight, String unit) {
    return 'Додано $amount$unit назад до $beanName. Нова вага: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
      String amount, String beanName, String newWeight, String unit) {
    return 'Віднято $amount$unit від $beanName. Нова вага: $newWeight$unit';
  }

  @override
  String get notifications => 'Сповіщення';

  @override
  String get notificationsDisabledInSystemSettings =>
      'Вимкнено в системних налаштуваннях';

  @override
  String get openSettings => 'Відкрити налаштування';

  @override
  String get notificationsDisabledDialogTitle =>
      'Сповіщення вимкнено в системних налаштуваннях';

  @override
  String get notificationsDisabledDialogContent =>
      'Ви вимкнули сповіщення в налаштуваннях пристрою. Щоб увімкнути сповіщення, будь ласка, відкрийте налаштування пристрою та дозвольте сповіщення для Timer.Coffee.';

  @override
  String get notificationDebug => 'Налагодження сповіщень';

  @override
  String get testNotificationSystem => 'Тестувати систему сповіщень';

  @override
  String get notificationsEnabled => 'Увімкнено';

  @override
  String get notificationsDisabled => 'Вимкнено';

  @override
  String get notificationPermissionDialogTitle => 'Увімкнути сповіщення?';

  @override
  String get notificationPermissionDialogMessage =>
      'Ви можете увімкнути сповіщення, щоб отримувати корисні оновлення (наприклад, про нові версії додатку). Увімкніть зараз або змініть це в будь-який момент у налаштуваннях.';

  @override
  String get notificationPermissionEnable => 'Увімкнути';

  @override
  String get notificationPermissionSkip => 'Не зараз';

  @override
  String get holidayGiftBoxTitle => 'Святкова подарункова коробка';

  @override
  String get holidayGiftBoxInfoTrigger => 'Що це?';

  @override
  String get holidayGiftBoxInfoBody =>
      'Добірка сезонних пропозицій від партнерів. Посилання не є партнерськими - ми просто хочемо подарувати трохи радості користувачам Timer.Coffee на ці свята. Потягніть униз, щоб оновити.';

  @override
  String get holidayGiftBoxNoOffers => 'Наразі немає доступних пропозицій.';

  @override
  String get holidayGiftBoxNoOffersSub =>
      'Потягніть, щоб оновити, або спробуйте пізніше.';

  @override
  String holidayGiftBoxShowingRegion(String region) {
    return 'Показуємо пропозиції для $region';
  }

  @override
  String get holidayGiftBoxViewDetails => 'Переглянути деталі';

  @override
  String get holidayGiftBoxPromoCopied => 'Промокод скопійовано';

  @override
  String get holidayGiftBoxPromoCode => 'Промокод';

  @override
  String giftDiscountOff(String percent) {
    return '$percent% знижки';
  }

  @override
  String giftDiscountUpToOff(String percent) {
    return 'До $percent% знижки';
  }

  @override
  String get holidayGiftBoxTerms => 'Умови';

  @override
  String get holidayGiftBoxVisitSite => 'Відвідати сайт партнера';

  @override
  String holidayGiftBoxValidUntil(String date) {
    return 'Дійсно до $date';
  }

  @override
  String get holidayGiftBoxValidWhileAvailable => 'Дійсно, доки є в наявності';

  @override
  String holidayGiftBoxUpdated(String date) {
    return 'Оновлено $date';
  }

  @override
  String holidayGiftBoxLanguage(String language) {
    return 'Мова: $language';
  }

  @override
  String get holidayGiftBoxRetry => 'Спробувати ще раз';

  @override
  String get holidayGiftBoxLoadFailed => 'Не вдалося завантажити пропозиції';

  @override
  String get regionEurope => 'Європа';

  @override
  String get regionNorthAmerica => 'Північна Америка';

  @override
  String get regionAsia => 'Азія';

  @override
  String get regionAustralia => 'Австралія / Океанія';

  @override
  String get regionWorldwide => 'Увесь світ';

  @override
  String get regionAfrica => 'Африка';

  @override
  String get regionMiddleEast => 'Близький Схід';

  @override
  String get regionSouthAmerica => 'Південна Америка';
}
