// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'Статистика по зернам';

  @override
  String get totalBeansBrewedLabel => 'Всего использовано зерен';

  @override
  String get newBeansTriedLabel => 'Новые зерна, которые вы попробовали';

  @override
  String get originsExploredLabel => 'Исследованные страны происхождения';

  @override
  String get regionsExploredLabel => 'Европа';

  @override
  String get newRoastersDiscoveredLabel => 'Найдено новых обжарщиков';

  @override
  String get favoriteRoastersLabel => 'Любимые обжарщики';

  @override
  String get topOriginsLabel => 'Топ стран происхождения';

  @override
  String get topRegionsLabel => 'Топ регионов';

  @override
  String get lastrecipe => 'Последний рецепт:';

  @override
  String get userRecipesTitle => 'Ваши рецепты';

  @override
  String get userRecipesSectionCreated => 'Созданные вами';

  @override
  String get userRecipesSectionImported => 'Импортированные вами';

  @override
  String get userRecipesEmpty => 'Рецепты не найдены';

  @override
  String get userRecipesDeleteTitle => 'Удалить рецепт?';

  @override
  String get userRecipesDeleteMessage => 'Это действие нельзя отменить.';

  @override
  String get userRecipesDeleteConfirm => 'Удалить';

  @override
  String get userRecipesDeleteCancel => 'Отмена';

  @override
  String get userRecipesSnackbarDeleted => 'Рецепт удалён';

  @override
  String get hubUserRecipesTitle => 'Ваши рецепты';

  @override
  String get hubUserRecipesSubtitle =>
      'Просмотр и управление созданными и импортированными рецептами';

  @override
  String get hubAccountSubtitle => 'Управляйте своим профилем';

  @override
  String get hubSignInCreateSubtitle =>
      'Войдите, чтобы синхронизировать рецепты и настройки';

  @override
  String get hubBrewDiarySubtitle =>
      'Просматривайте историю завариваний и добавляйте заметки';

  @override
  String get hubBrewStatsSubtitle =>
      'Просматривайте личную и глобальную статистику и тренды по завариванию';

  @override
  String get hubSettingsSubtitle => 'Измените параметры и поведение приложения';

  @override
  String get hubAboutSubtitle =>
      'Информация о приложении, версия и контрибьюторы';

  @override
  String get about => 'О приложении';

  @override
  String get author => 'Автор';

  @override
  String get authortext =>
      'Приложение Timer.Coffee создал Антон Карлинер, кофе-энтузиаст, медиапрофессионал и фотожурналист. Я надеюсь, что моё приложение поможет вам сварить много отличного кофе. Не стесняйтесь делиться идеями на GitHub.';

  @override
  String get contributors => 'Контрибьюторы';

  @override
  String get errorLoadingContributors =>
      'Ошибка загрузки списка контрибьюторов';

  @override
  String get license => 'Лицензия';

  @override
  String get licensetext =>
      'Это свободная программа: вы можете перераспространять ее и/или изменять ее на условиях Стандартной общественной лицензии GNU в том виде, в каком она была опубликована Фондом свободного программного обеспечения; либо версии 3 лицензии, либо (по вашему выбору) любой более поздней версии.';

  @override
  String get licensebutton => 'Текст Стандартной общественной лицензии GNU';

  @override
  String get website => 'Сайт';

  @override
  String get sourcecode => 'Исходный код';

  @override
  String get support => 'Купить кофе разработчику';

  @override
  String get allrecipes => 'Все рецепты';

  @override
  String get favoriterecipes => 'Любимые рецепты';

  @override
  String get coffeeamount => 'Кол-во кофе (г)';

  @override
  String get wateramount => 'Кол-во воды (мл)';

  @override
  String get watertemp => 'Температура воды';

  @override
  String get grindsize => 'Размер помола';

  @override
  String get brewtime => 'Время заваривания';

  @override
  String get recipesummary => 'Рецепт';

  @override
  String get recipesummarynote =>
      'Внимание! Это рецепт с базовым количеством кофе и воды.';

  @override
  String get preparation => 'Подготовка';

  @override
  String get brewingprocess => 'Заваривание';

  @override
  String get step => 'Шаг';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'секунд',
      many: 'секунд',
      few: 'секунды',
      one: 'секунда',
      zero: 'секунд',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg =>
      'Спасибо, что пользуетесь Timer.Coffee, наслаждайтесь вашим';

  @override
  String get coffeefact => 'Факт о кофе';

  @override
  String get home => 'Домой';

  @override
  String get appversion => 'Версия приложения';

  @override
  String get tipsmall => 'Купить маленький кофе';

  @override
  String get tipmedium => 'Купить средний кофе';

  @override
  String get tiplarge => 'Купить большой кофе';

  @override
  String get supportdevelopment => 'Поддержать разработку';

  @override
  String get supportdevmsg =>
      'Ваши пожертвования помогают оплачивать текущие расходы (например, продлевать лицензии разработчика), а также, благодаря пожертвованиям, я могу пробовать больше способов заваривания и добавлять в приложение больше рецептов.';

  @override
  String get supportdevtnx => 'Спасибо за вашу поддержку!';

  @override
  String get donationok => 'Спасибо!';

  @override
  String get donationtnx =>
      'Ваша поддержка очень ценна! Желаю вам много хорошего кофе ☕️';

  @override
  String get donationerr => 'Ошибка';

  @override
  String get donationerrmsg =>
      'Ошибка обработки платежа, пожалуйста попробуйте ещё раз';

  @override
  String get sharemsg => 'Попробуй рецепт:';

  @override
  String get finishbrew => 'Конец заварки';

  @override
  String get settings => 'Настройки';

  @override
  String get settingstheme => 'Тема';

  @override
  String get settingsthemelight => 'Светлая';

  @override
  String get settingsthemedark => 'Тёмная';

  @override
  String get settingsthemesystem => 'Системная';

  @override
  String get settingslang => 'Язык';

  @override
  String get sweet => 'Сладкий';

  @override
  String get balance => 'Сбалансированный';

  @override
  String get acidic => 'Кислый';

  @override
  String get light => 'Лёгкий';

  @override
  String get strong => 'Крепкий';

  @override
  String get slidertitle => 'Используйте слайдеры, чтобы настроить вкус';

  @override
  String get whatsnewtitle => 'Что нового';

  @override
  String get whatsnewclose => 'Закрыть';

  @override
  String get seasonspecials => 'Сезонные эффекты';

  @override
  String get snow => 'Снег';

  @override
  String get noFavoriteRecipesMessage =>
      'Ваш список любимых рецептов пока что пуст. Начните заваривать, чтобы узнать, что вам нравится больше всего!';

  @override
  String get explore => 'Открытия';

  @override
  String get dateFormat => 'd MMM yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Дневник заварок';

  @override
  String get brewdiarynotfound => 'Записи не найдены';

  @override
  String get beans => 'Зерна';

  @override
  String get roaster => 'Обжарщик';

  @override
  String get rating => 'Рейтинг';

  @override
  String get notes => 'Заметки';

  @override
  String get statsscreen => 'Статистика';

  @override
  String get yourStats => 'Ваша статистика';

  @override
  String get coffeeBrewed => 'Приготовлено кофе:';

  @override
  String get litersUnit => 'л';

  @override
  String get mostUsedRecipes => 'Самые используемые рецепты:';

  @override
  String get globalStats => 'Глобальная статистика';

  @override
  String get unknownRecipe => 'Неизвестный рецепт';

  @override
  String get noData => 'Нет данных';

  @override
  String error(String error) {
    return 'Ошибка: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Кто-то только что сварил $recipeName';
  }

  @override
  String get timePeriodToday => 'Сегодня';

  @override
  String get timePeriodThisWeek => 'Эту неделю';

  @override
  String get timePeriodThisMonth => 'Этот месяц';

  @override
  String get timePeriodCustom => 'Пользовательский';

  @override
  String get statsFor => 'Статистика за ';

  @override
  String get homescreenbrewcoffee => 'Заварить кофе';

  @override
  String get homescreenhub => 'Хаб';

  @override
  String get homescreenmore => 'Ещё';

  @override
  String get addBeans => 'Добавить зерна';

  @override
  String get removeBeans => 'Удалить зерна';

  @override
  String get name => 'Название';

  @override
  String get origin => 'Страна происхождения';

  @override
  String get details => 'Подробнее';

  @override
  String get coffeebeans => 'Зерна кофе';

  @override
  String get loading => 'Загрузка';

  @override
  String get nocoffeebeans => 'Зерна кофе не найдены';

  @override
  String get delete => 'Удалить';

  @override
  String get confirmDeleteTitle => 'Удалить запись?';

  @override
  String get recipeDuplicateConfirmTitle => 'Дублировать рецепт?';

  @override
  String get recipeDuplicateConfirmMessage =>
      'Это создаст копию вашего рецепта, которую вы сможете редактировать независимо. Хотите продолжить?';

  @override
  String get confirmDeleteMessage =>
      'Вы уверены, что хотите удалить эту запись? Это действие нельзя отменить.';

  @override
  String get removeFavorite => 'Удалить из избранного';

  @override
  String get addFavorite => 'Добавить в избранное';

  @override
  String get toggleEditMode => 'Редактировать';

  @override
  String get coffeeBeansDetails => 'Информация о зернах';

  @override
  String get edit => 'Редактировать';

  @override
  String get coffeeBeansNotFound => 'Зерна кофе не найдены';

  @override
  String get basicInformation => 'Основное';

  @override
  String get geographyTerroir => 'География/Терруар';

  @override
  String get variety => 'Разновидность';

  @override
  String get region => 'Северная Америка';

  @override
  String get elevation => 'Высота произрастания';

  @override
  String get harvestDate => 'Дата сбора урожая';

  @override
  String get processing => 'Обработка';

  @override
  String get processingMethod => 'Способ обработки';

  @override
  String get roastDate => 'Дата обжарки';

  @override
  String get roastLevel => 'Степень обжарки';

  @override
  String get cuppingScore => 'Оценка дегустации';

  @override
  String get flavorProfile => 'Вкусовой профиль';

  @override
  String get tastingNotes => 'Вкусовые ноты';

  @override
  String get additionalNotes => 'Дополнительные примечания';

  @override
  String get noCoffeeBeans => 'Зерна кофе не найдены';

  @override
  String get editCoffeeBeans => 'Редактировать информацию о зернах';

  @override
  String get addCoffeeBeans => 'Добавить зерна кофе';

  @override
  String get showImagePicker => 'Выбрать изображение';

  @override
  String get pleaseNote => 'Обратите внимание';

  @override
  String get firstTimePopupMessage =>
      '1. Мы используем внешние сервисы для обработки изображений. Продолжая, вы соглашаетесь с этим.\n2. Несмотря на то, что мы не храним ваши изображения, пожалуйста, не загружайте изображения с личной информацией.\n3. Распознавание изображений в настоящее время ограничено 10 токенами в месяц (1 токен = 1 изображение). Это ограничение может быть изменено в будущем.';

  @override
  String get ok => 'ОК';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get selectFromPhotos => 'Выбрать из фото';

  @override
  String get takeAdditionalPhoto => 'Сделать еще одно фото?';

  @override
  String get no => 'Нет';

  @override
  String get yes => 'Да';

  @override
  String get selectedImages => 'Выбранные изображения';

  @override
  String get selectedImage => 'Выбранное изображение';

  @override
  String get backToSelection => 'Назад к выбору';

  @override
  String get next => 'Далее';

  @override
  String get unexpectedErrorOccurred => 'Произошла непредвиденная ошибка';

  @override
  String get tokenLimitReached =>
      'Извините, вы достигли лимита токенов для распознавания изображений в этом месяце';

  @override
  String get noCoffeeLabelsDetected =>
      'Этикетки кофе не обнаружены. Попробуйте другое изображение.';

  @override
  String get collectedInformation => 'Собранная информация';

  @override
  String get enterRoaster => 'Укажите обжарщика';

  @override
  String get enterName => 'Введите название';

  @override
  String get enterOrigin => 'Укажите страну происхождения';

  @override
  String get optional => 'Необязательно';

  @override
  String get enterVariety => 'Укажите разновидность';

  @override
  String get enterProcessingMethod => 'Укажите способ обработки';

  @override
  String get enterRoastLevel => 'Укажите степень обжарки';

  @override
  String get enterRegion => 'Укажите регион';

  @override
  String get enterTastingNotes => 'Укажите вкусовые ноты';

  @override
  String get enterElevation => 'Укажите высоту произрастания';

  @override
  String get enterCuppingScore => 'Укажите оценку дегустации';

  @override
  String get enterNotes => 'Введите примечания';

  @override
  String get inventory => 'Запасы';

  @override
  String get amountLeft => 'Остаток';

  @override
  String get enterAmountLeft => 'Введите остаток';

  @override
  String get selectHarvestDate => 'Выберите дату сбора урожая';

  @override
  String get selectRoastDate => 'Выберите дату обжарки';

  @override
  String get selectDate => 'Выберите дату';

  @override
  String get save => 'Сохранить';

  @override
  String get fillRequiredFields =>
      'Пожалуйста, заполните все обязательные поля.';

  @override
  String get analyzing => 'Анализируем';

  @override
  String get errorMessage => 'Ошибка';

  @override
  String get selectCoffeeBeans => 'Выберите зерна кофе';

  @override
  String get addNewBeans => 'Добавить новые зерна';

  @override
  String get favorite => 'Избранное';

  @override
  String get notFavorite => 'Не в избранном';

  @override
  String get myBeans => 'Мои зерна';

  @override
  String get signIn => 'Войти';

  @override
  String get signOut => 'Выйти';

  @override
  String get signInWithApple => 'Войти с помощью Apple';

  @override
  String get signInSuccessful => 'Вход с помощью Apple выполнен успешно';

  @override
  String get signInError => 'Ошибка входа с помощью Apple';

  @override
  String get signInWithGoogle => 'Войти через Google';

  @override
  String get signOutSuccessful => 'Выход из системы выполнен успешно';

  @override
  String get signInSuccessfulGoogle => 'Успешно выполнен вход с помощью Google';

  @override
  String get signInWithEmail => 'Войти с email';

  @override
  String get enterEmail => 'Введите email';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get cancel => 'Отмена';

  @override
  String get sendMagicLink => 'Отправить magic link';

  @override
  String get magicLinkSent => 'Magic link отправлен! Проверьте вашу почту.';

  @override
  String get sendOTP => 'Отправить код';

  @override
  String get otpSent => 'Код отправлен на ваш email';

  @override
  String get otpSendError => 'Ошибка отправки кода';

  @override
  String get enterOTP => 'Введите код';

  @override
  String get otpHint => 'Введите 6-значный код';

  @override
  String get verify => 'Проверить';

  @override
  String get signInSuccessfulEmail => 'Вход выполнен';

  @override
  String get invalidOTP => 'Неверный код';

  @override
  String get otpVerificationError => 'Ошибка проверки кода';

  @override
  String get success => 'Успешно!';

  @override
  String get otpSentMessage =>
      'OTP отправлено на вашу почту. Пожалуйста, введите его ниже, когда получите.';

  @override
  String get otpHint2 => 'Введите код здесь';

  @override
  String get signInCreate => 'Вход / Регистрация';

  @override
  String get accountManagement => 'Управление учетной записью';

  @override
  String get deleteAccount => 'Удалить учетную запись';

  @override
  String get deleteAccountWarning =>
      'Обратите внимание: если вы решите продолжить, мы удалим вашу учетную запись и связанные с ней данные с наших серверов. Локальная копия данных останется на устройстве, если вы также хотите ее удалить, вы можете просто удалить приложение. Чтобы снова включить синхронизацию, вам необходимо будет создать учетную запись заново';

  @override
  String get deleteAccountConfirmation => 'Учетная запись успешно удалена';

  @override
  String get accountDeleted => 'Учетная запись удалена';

  @override
  String get accountDeletionError =>
      'Ошибка при удалении учетной записи, повторите попытку';

  @override
  String get deleteAccountTitle => 'Важно';

  @override
  String get selectBeans => 'Выберите зерна';

  @override
  String get all => 'Все';

  @override
  String get selectRoaster => 'Выбрать обжарщика';

  @override
  String get selectOrigin => 'Выбрать происхождение';

  @override
  String get resetFilters => 'Сбросить фильтры';

  @override
  String get showFavoritesOnly => 'Показывать только избранное';

  @override
  String get apply => 'Применить';

  @override
  String get selectSize => 'Выберите размер';

  @override
  String get sizeStandard => 'Стандартный';

  @override
  String get sizeMedium => 'Средний';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Мой год с Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      'Спасибо, что были частью вселенной Timer.Coffee в этом году!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'Начнем с главного.\nВ этом году вы варили кофе$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'Если быть точнее,\nв 2024 году вы сварили $liters литра кофе!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'Вы использовали зерна от $roasterCount обжарщиков';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'Ваши топ-3 обжарщика:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Вы отправились в путешествие\nпо миру$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'Вы попробовали кофейные зерна\nиз $originCount стран!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Вы варили кофе не в одиночку…';

  @override
  String get yearlyStatsStory7Part2 =>
      '…а с пользователями из 110 других\nстран на 6 континентах!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Вы остались верны себе и использовали только эти $count способа заваривания в этом году:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Вы открывали для себя новые вкусы и использовали $count способов заваривания в этом году:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'Вы были настоящим кофейным первооткрывателем и использовали $count способов заваривания в этом году:';
  }

  @override
  String get yearlyStatsStory9Text => 'Еще так много всего предстоит открыть!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'Ваши топ-3 рецепта в 2024 году$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'Увидимся в 2025 году!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Показать любовь ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Пожертвовать';

  @override
  String get yearlyStatsActionShare => 'Поделитесь своим прогрессом';

  @override
  String get yearlyStatsUnknown => 'Неизвестно';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Не удалось поделиться: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Мой год с Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes => 'Мои топ-3 рецепта:';

  @override
  String get yearlyStatsShareProgressTop3Roasters => 'Мои топ-3 обжарщика:';

  @override
  String get yearlyStats25AppBarTitle => 'Ваш год с Timer.Coffee — 2025';

  @override
  String get yearlyStats25AppBarTitleSimple => 'Timer.Coffee в 2025';

  @override
  String get yearlyStats25Slide1Title => 'Ваш год с Timer.Coffee';

  @override
  String get yearlyStats25Slide1Subtitle =>
      'Нажмите, чтобы увидеть, как вы варили кофе в 2025 году';

  @override
  String get yearlyStats25Slide2Intro => 'Вместе мы сварили кофе...';

  @override
  String yearlyStats25Slide2Count(String count) {
    return '$count раз';
  }

  @override
  String yearlyStats25Slide2Liters(String liters) {
    return 'Это примерно $liters л кофе';
  }

  @override
  String get yearlyStats25Slide2Cambridge =>
      'Этого достаточно, чтобы угостить чашкой кофе каждого в Кембридже, Великобритания (студенты были бы особенно благодарны).';

  @override
  String get yearlyStats25Slide3Title => 'А как насчёт вас?';

  @override
  String yearlyStats25Slide3Subtitle(String brews, String liters) {
    return 'В этом году вы готовили кофе с Timer.Coffee $brews раз. Всего — $liters л!';
  }

  @override
  String yearlyStats25Slide3TopBadge(int topPct) {
    return 'Вы в топе $topPct% тех, кто заваривает кофе!';
  }

  @override
  String get yearlyStats25Slide4TitleSingle =>
      'Помните день, когда вы приготовили больше всего кофе в этом году?';

  @override
  String get yearlyStats25Slide4TitleMulti =>
      'Помните дни, когда вы приготовили больше всего кофе в этом году?';

  @override
  String get yearlyStats25Slide4TitleBrewTime =>
      'Время заваривания в этом году';

  @override
  String get yearlyStats25Slide4ScratchLabel => 'Сотрите, чтобы открыть';

  @override
  String yearlyStats25BrewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# заваривания',
      many: '# завариваний',
      few: '# заваривания',
      one: '# заваривание',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25Slide4PeakSingle(String date, String brewsLabel) {
    return '$date — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4PeakLiters(String liters) {
    return 'Примерно $liters л в тот день';
  }

  @override
  String yearlyStats25Slide4PeakMostRecent(
      String mostRecent, String brewsLabel) {
    return 'Самый недавний: $mostRecent — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4BrewTimeLine(String timeLabel) {
    return 'Вы потратили $timeLabel на заваривание';
  }

  @override
  String get yearlyStats25Slide4BrewTimeFooter => 'Время потрачено не зря';

  @override
  String get yearlyStats25Slide5Title => 'Так вы завариваете кофе';

  @override
  String get yearlyStats25Slide5MethodsHeader => 'Любимые методы:';

  @override
  String get yearlyStats25Slide5NoMethods => 'Пока нет методов';

  @override
  String get yearlyStats25Slide5RecipesHeader => 'Лучшие рецепты:';

  @override
  String get yearlyStats25Slide5NoRecipes => 'Пока нет рецептов';

  @override
  String yearlyStats25MethodRow(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'заваривания',
      many: 'завариваний',
      few: 'заваривания',
      one: 'заваривание',
    );
    return '$name — $count $_temp0';
  }

  @override
  String yearlyStats25Slide6Title(String count) {
    return 'Обжарщиков в этом году: $count';
  }

  @override
  String get yearlyStats25Slide6NoRoasters => 'Пока нет обжарщиков';

  @override
  String get yearlyStats25Slide7Title =>
      'Кофе может привести вас в разные места…';

  @override
  String yearlyStats25Slide7Subtitle(String count) {
    return 'Стран происхождения в этом году: $count';
  }

  @override
  String get yearlyStats25Others => '...и другие';

  @override
  String yearlyStats25FallbackTitle(int countries, int roasters) {
    return 'В этом году пользователи Timer.Coffee использовали бобы из $countries стран\nи зарегистрировали $roasters разных обжарщиков.';
  }

  @override
  String get yearlyStats25FallbackPromptHasBeans =>
      'Почему бы не продолжить записывать свои пакеты зёрен?';

  @override
  String get yearlyStats25FallbackPromptNoBeans =>
      'Может, пора присоединиться и тоже начать записывать свои зёрна?';

  @override
  String get yearlyStats25FallbackActionHasBeans =>
      'Продолжить добавлять зёрна';

  @override
  String get yearlyStats25FallbackActionNoBeans =>
      'Добавить первый пакет зёрен';

  @override
  String get yearlyStats25ContinueButton => 'Продолжить';

  @override
  String get yearlyStats25PostcardTitle =>
      'Отправьте новогоднее пожелание другому любителю кофе.';

  @override
  String get yearlyStats25PostcardSubtitle =>
      'Необязательно. Будьте добры. Без личной информации.';

  @override
  String get yearlyStats25PostcardHint => 'С Новым годом и отличных заварок!';

  @override
  String get yearlyStats25PostcardSending => 'Отправка...';

  @override
  String get yearlyStats25PostcardSend => 'Отправить';

  @override
  String get yearlyStats25PostcardSkip => 'Пропустить';

  @override
  String get yearlyStats25PostcardReceivedTitle =>
      'Пожелание от другого любителя кофе';

  @override
  String get yearlyStats25PostcardErrorLength => 'Введите 2–160 символов.';

  @override
  String get yearlyStats25PostcardErrorSend =>
      'Не удалось отправить. Попробуйте ещё раз.';

  @override
  String get yearlyStats25PostcardErrorRejected =>
      'Не удалось отправить. Попробуйте другое сообщение.';

  @override
  String get yearlyStats25CtaTitle => 'Давайте заварим что-то классное в 2026!';

  @override
  String get yearlyStats25CtaSubtitle => 'Вот несколько идей:';

  @override
  String get yearlyStats25CtaExplorePrefix => 'Посмотрите предложения: ';

  @override
  String get yearlyStats25CtaGiftBox => 'Праздничная подарочная коробка';

  @override
  String get yearlyStats25CtaDonate => 'Пожертвовать';

  @override
  String get yearlyStats25CtaDonateSuffix =>
      ' чтобы помочь Timer.Coffee расти в новом году';

  @override
  String get yearlyStats25CtaFollowPrefix => 'Подписывайтесь: ';

  @override
  String get yearlyStats25CtaInstagram => 'Instagram';

  @override
  String get yearlyStats25CtaShareButton => 'Поделиться моим прогрессом';

  @override
  String get yearlyStats25CtaShareHint =>
      'Не забудьте отметить @timercoffeeapp';

  @override
  String get yearlyStats25AppBarTooltipResume => 'Продолжить';

  @override
  String get yearlyStats25AppBarTooltipPause => 'Пауза';

  @override
  String get yearlyStats25ShareError =>
      'Не удалось поделиться итогами. Попробуйте ещё раз.';

  @override
  String yearlyStats25BrewTimeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# минуты',
      many: '# минут',
      few: '# минуты',
      one: '# минута',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25BrewTimeHours(String hours) {
    return '$hours ч';
  }

  @override
  String get yearlyStats25ShareTitle => 'Мой год 2025 с Timer.Coffee';

  @override
  String get yearlyStats25ShareBrewedPrefix => 'Заваривания: ';

  @override
  String get yearlyStats25ShareBrewedMiddle => ' • ';

  @override
  String get yearlyStats25ShareBrewedSuffix => ' л кофе';

  @override
  String get yearlyStats25ShareRoastersPrefix => 'Обжарщики: ';

  @override
  String get yearlyStats25ShareRoastersSuffix => '';

  @override
  String get yearlyStats25ShareOriginsPrefix => 'Происхождения: ';

  @override
  String get yearlyStats25ShareOriginsSuffix => '';

  @override
  String get yearlyStats25ShareMethodsTitle =>
      'Мои любимые способы заваривания:';

  @override
  String get yearlyStats25ShareRecipesTitle => 'Мои лучшие рецепты:';

  @override
  String get yearlyStats25ShareHandle => '@timercoffeeapp';

  @override
  String get yearlyStatsFailedToLike =>
      'Не удалось поставить лайк. Пожалуйста, попробуйте еще раз.';

  @override
  String get labelCoffeeBrewed => 'Кофе сварено';

  @override
  String get labelTastedBeansBy => 'Зерна попробованы от';

  @override
  String get labelDiscoveredCoffeeFrom => 'Открыт кофе из';

  @override
  String get labelUsedBrewingMethods => 'Использовано';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'обжарщиков',
      many: 'обжарщиков',
      few: 'обжарщика',
      one: 'обжарщик',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'стран',
      many: 'стран',
      few: 'страны',
      one: 'страна',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'способов заваривания',
      many: 'способов заваривания',
      few: 'способа заваривания',
      one: 'способ заваривания',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Редактировать рецепт';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Создать рецепт';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Шаги рецепта';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Название рецепта';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Краткое описание';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Метод заваривания';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Количество кофе (г)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Количество воды (мл)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Температура воды (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Размер помола';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel =>
      'Общее время заваривания:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Минуты';

  @override
  String get recipeCreationScreenSecondsLabel => 'Секунды';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Шаг подготовки';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Шаг заваривания $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Описание шага';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Время шага: ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'Введите название рецепта';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Введите краткое описание';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Выберите метод заваривания';

  @override
  String get recipeCreationScreenRequiredValidator => 'Обязательно';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Неверный номер';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Введите описание шага';

  @override
  String get recipeCreationScreenContinueButton => 'Перейти к шагам рецепта';

  @override
  String get recipeCreationScreenAddStepButton => 'Добавить шаг';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Сохранить рецепт';

  @override
  String get recipeCreationScreenUpdateSuccess => 'Рецепт успешно обновлен';

  @override
  String get recipeCreationScreenSaveSuccess => 'Рецепт успешно сохранен';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Ошибка сохранения рецепта: $error';
  }

  @override
  String get unitGramsShort => 'г';

  @override
  String get unitMillilitersShort => 'мл';

  @override
  String get unitGramsLong => 'граммы';

  @override
  String get unitMillilitersLong => 'миллилитры';

  @override
  String get recipeCopySuccess => 'Рецепт успешно скопирован!';

  @override
  String get recipeDuplicateSuccess => 'Рецепт успешно дублирован!';

  @override
  String recipeCopyError(String error) {
    return 'Ошибка при копировании рецепта: $error';
  }

  @override
  String get createRecipe => 'Создать рецепт';

  @override
  String errorSyncingData(Object error) {
    return 'Ошибка синхронизации данных: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Ошибка выхода: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Подготовка';

  @override
  String get loadingEllipsis => 'Загрузка...';

  @override
  String get recipeDeletedSuccess => 'Рецепт успешно удален';

  @override
  String recipeDeleteError(Object error) {
    return 'Не удалось удалить рецепт: $error';
  }

  @override
  String get noRecipesFound => 'Рецепты не найдены';

  @override
  String recipeLoadError(Object error) {
    return 'Не удалось загрузить рецепт: $error';
  }

  @override
  String get unknownBrewingMethod => 'Неизвестный метод заваривания';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Не удалось загрузить скопированный рецепт для редактирования.';

  @override
  String get recipeCopyErrorOperationFailed => 'Операция не удалась.';

  @override
  String get notProvided => 'Не указано';

  @override
  String get recipeUpdateFailedFetch =>
      'Не удалось получить обновленные данные рецепта.';

  @override
  String get recipeImportSuccess => 'Рецепт успешно импортирован!';

  @override
  String get recipeImportFailedSave =>
      'Не удалось сохранить импортированный рецепт.';

  @override
  String get recipeImportFailedFetch =>
      'Не удалось получить данные рецепта для импорта.';

  @override
  String get recipeNotImported => 'Рецепт не импортирован.';

  @override
  String get recipeNotFoundCloud =>
      'Рецепт не найден в облаке или не является общедоступным.';

  @override
  String get recipeLoadErrorGeneric => 'Ошибка загрузки рецепта.';

  @override
  String get recipeUpdateAvailableTitle => 'Доступно обновление';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'Новая версия \'$recipeName\' доступна онлайн. Обновить?';
  }

  @override
  String get dialogCancel => 'Отмена';

  @override
  String get dialogDuplicate => 'Дублировать';

  @override
  String get dialogUpdate => 'Обновить';

  @override
  String get recipeImportTitle => 'Импортировать рецепт';

  @override
  String recipeImportBody(String recipeName) {
    return 'Вы хотите импортировать рецепт \'$recipeName\' из облака?';
  }

  @override
  String get dialogImport => 'Импортировать';

  @override
  String get moderationReviewNeededTitle => 'Требуется проверка модератором';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'Следующий(ие) рецепт(ы) требует(ют) проверки из-за проблем с модерацией контента: $recipeNames';
  }

  @override
  String get dismiss => 'Отклонить';

  @override
  String get reviewRecipeButton => 'Проверить рецепт';

  @override
  String get signInRequiredTitle => 'Требуется вход';

  @override
  String get signInRequiredBodyShare =>
      'Вам необходимо войти в систему, чтобы поделиться своими рецептами.';

  @override
  String get syncSuccess => 'Синхронизация прошла успешно!';

  @override
  String get tooltipEditRecipe => 'Редактировать рецепт';

  @override
  String get tooltipCopyRecipe => 'Копировать рецепт';

  @override
  String get tooltipDuplicateRecipe => 'Дублировать рецепт';

  @override
  String get tooltipShareRecipe => 'Поделиться рецептом';

  @override
  String get signInRequiredSnackbar => 'Требуется вход';

  @override
  String get moderationErrorFunction =>
      'Проверка модерации контента не удалась.';

  @override
  String get moderationReasonDefault => 'Контент помечен для проверки.';

  @override
  String get moderationFailedTitle => 'Модерация не удалась';

  @override
  String moderationFailedBody(String reason) {
    return 'Этот рецепт не может быть опубликован, потому что: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Ошибка при публикации рецепта: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName на Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'Не удалось проверить статус контента. Сохранено локально, будет проверено при следующей синхронизации.';

  @override
  String get saveLocallyModerationFailedTitle => 'Изменения сохранены локально';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Ваши локальные изменения были сохранены, но публичная версия не может быть обновлена из-за модерации контента: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Редактировать импортированный рецепт';

  @override
  String get editImportedRecipeBody =>
      'Это импортированный рецепт. Редактирование создаст новую, независимую копию. Продолжить?';

  @override
  String get editImportedRecipeButtonCopy => 'Создать копию и редактировать';

  @override
  String get editImportedRecipeButtonCancel => 'Отмена';

  @override
  String get editDisplayNameTitle => 'Изменить отображаемое имя';

  @override
  String get displayNameHint => 'Введите ваше отображаемое имя';

  @override
  String get displayNameEmptyError => 'Отображаемое имя не может быть пустым';

  @override
  String get displayNameTooLongError =>
      'Отображаемое имя не может превышать 50 символов';

  @override
  String get errorUserNotLoggedIn =>
      'Пользователь не вошел в систему. Пожалуйста, войдите снова.';

  @override
  String get displayNameUpdateSuccess => 'Отображаемое имя успешно обновлено!';

  @override
  String displayNameUpdateError(String error) {
    return 'Не удалось обновить отображаемое имя: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Удалить изображение?';

  @override
  String get deletePictureConfirmationBody =>
      'Вы уверены, что хотите удалить изображение профиля?';

  @override
  String get deletePictureSuccess => 'Изображение профиля удалено.';

  @override
  String deletePictureError(String error) {
    return 'Не удалось удалить изображение профиля: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Не удалось обновить изображение профиля: $error';
  }

  @override
  String get updatePictureSuccess => 'Изображение профиля успешно обновлено!';

  @override
  String get deletePictureTooltip => 'Удалить изображение';

  @override
  String get account => 'Аккаунт';

  @override
  String get settingsBrewingMethodsTitle =>
      'Методы заваривания на главном экране';

  @override
  String get filter => 'Фильтр';

  @override
  String get sortBy => 'Сортировать по';

  @override
  String get dateAdded => 'Дата добавления';

  @override
  String get secondsAbbreviation => 'с';

  @override
  String get settingsAppIcon => 'Иконка приложения';

  @override
  String get settingsAppIconDefault => 'По умолчанию';

  @override
  String get settingsAppIconLegacy => 'Старая';

  @override
  String get searchBeans => 'Поиск зерен...';

  @override
  String get favorites => 'Избранное';

  @override
  String get searchPrefix => 'Поиск: ';

  @override
  String get clearAll => 'Очистить все';

  @override
  String get noBeansMatchSearch => 'Нет зерен, соответствующих вашему поиску';

  @override
  String get clearFilters => 'Очистить фильтры';

  @override
  String get farmer => 'Фермер';

  @override
  String get farm => 'Ферма';

  @override
  String get enterFarmer => 'Введите фермера';

  @override
  String get enterFarm => 'Введите кофейную ферму';

  @override
  String get requiredInformation => 'Необходимая информация';

  @override
  String get basicDetails => 'Основные детали';

  @override
  String get qualityMeasurements => 'Качество и измерения';

  @override
  String get importantDates => 'Важные даты';

  @override
  String get brewStats => 'Статистика заваривания';

  @override
  String get showMore => 'Показать еще';

  @override
  String get showLess => 'Показать меньше';

  @override
  String get unpublishRecipeDialogTitle => 'Сделать рецепт приватным';

  @override
  String get unpublishRecipeDialogMessage =>
      'Внимание: Если сделать этот рецепт приватным, это приведет к следующему:';

  @override
  String get unpublishRecipeDialogBullet1 =>
      'Он будет удален из результатов публичного поиска';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'Новые пользователи не смогут его импортировать';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'Пользователи, которые уже импортировали его, сохранят свои копии';

  @override
  String get unpublishRecipeDialogKeepPublic => 'Оставить публичным';

  @override
  String get unpublishRecipeDialogMakePrivate => 'Сделать приватным';

  @override
  String get recipeUnpublishSuccess => 'Публикация рецепта успешно отменена';

  @override
  String recipeUnpublishError(String error) {
    return 'Ошибка при отмене публикации рецепта: $error';
  }

  @override
  String get recipePublicTooltip =>
      'Рецепт общедоступен - нажмите, чтобы сделать его частным';

  @override
  String get recipePrivateTooltip =>
      'Рецепт частный - поделитесь, чтобы сделать его общедоступным';

  @override
  String get fieldClearButtonTooltip => 'Очистить';

  @override
  String get dateFieldClearButtonTooltip => 'Очистить дату';

  @override
  String get chipInputDuplicateError => 'Этот тег уже добавлен';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return 'Достигнуто максимальное количество тегов ($maxChips)';
  }

  @override
  String get chipInputHintText => 'Добавить тег...';

  @override
  String get unitFieldRequiredError => 'Это поле обязательно для заполнения';

  @override
  String get unitFieldInvalidNumberError =>
      'Пожалуйста, введите действительное число';

  @override
  String unitFieldMinValueError(Object min) {
    return 'Значение должно быть не менее $min';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return 'Значение должно быть не более $max';
  }

  @override
  String get numericFieldRequiredError => 'Это поле обязательно для заполнения';

  @override
  String get numericFieldInvalidNumberError =>
      'Пожалуйста, введите действительное число';

  @override
  String numericFieldMinValueError(Object min) {
    return 'Значение должно быть не менее $min';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return 'Значение должно быть не более $max';
  }

  @override
  String get dropdownSearchHintText => 'Введите для поиска...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return 'Ошибка загрузки предложений: $error';
  }

  @override
  String get dropdownSearchNoResults => 'Результаты не найдены';

  @override
  String get dropdownSearchLoading => 'Поиск...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return 'Использовать \"$currentQuery\"';
  }

  @override
  String get requiredInfoSubtitle => '* Обязательно';

  @override
  String get inventoryWeightExample => 'Например, 250.5';

  @override
  String get unsavedChangesTitle => 'Несохраненные изменения';

  @override
  String get unsavedChangesMessage =>
      'У вас есть несохраненные изменения. Вы уверены, что хотите их отменить?';

  @override
  String get unsavedChangesStay => 'Остаться';

  @override
  String get unsavedChangesDiscard => 'Отменить';

  @override
  String beansWeightAddedBack(
      String amount, String beanName, String newWeight, String unit) {
    return 'Добавлено $amount$unit обратно к $beanName. Новый вес: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
      String amount, String beanName, String newWeight, String unit) {
    return 'Убавлено $amount$unit из $beanName. Новый вес: $newWeight$unit';
  }

  @override
  String get notifications => 'Уведомления';

  @override
  String get notificationsDisabledInSystemSettings =>
      'Отключены в системных настройках';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get couldNotOpenLink => 'Не удалось открыть ссылку';

  @override
  String get notificationsDisabledDialogTitle =>
      'Уведомления отключены в системных настройках';

  @override
  String get notificationsDisabledDialogContent =>
      'Вы отключили уведомления в настройках вашего устройства. Чтобы включить уведомления, пожалуйста, откройте настройки вашего устройства и разрешите уведомления для Timer.Coffee.';

  @override
  String get notificationDebug => 'Отладка уведомлений';

  @override
  String get testNotificationSystem => 'Тестировать систему уведомлений';

  @override
  String get notificationsEnabled => 'Включены';

  @override
  String get notificationsDisabled => 'Отключены';

  @override
  String get notificationPermissionDialogTitle => 'Включить уведомления?';

  @override
  String get notificationPermissionDialogMessage =>
      'Вы можете включить уведомления, чтобы получать полезные обновления (например, о новых версиях приложения). Включите сейчас или измените это в любой момент в настройках.';

  @override
  String get notificationPermissionEnable => 'Включить';

  @override
  String get notificationPermissionSkip => 'Не сейчас';

  @override
  String get holidayGiftBoxTitle => 'Праздничная подарочная коробка';

  @override
  String get holidayGiftBoxInfoTrigger => 'Что это?';

  @override
  String get holidayGiftBoxInfoBody =>
      'Подборка сезонных предложений от партнёров. Ссылки не аффилированные - мы просто хотим подарить немного радости пользователям Timer.Coffee в эти праздники. Потяните вниз, чтобы обновить.';

  @override
  String get holidayGiftBoxNoOffers => 'Сейчас нет доступных предложений.';

  @override
  String get holidayGiftBoxNoOffersSub =>
      'Потяните вниз для обновления или попробуйте позже.';

  @override
  String holidayGiftBoxShowingRegion(String region) {
    return 'Показываем предложения для $region';
  }

  @override
  String get holidayGiftBoxViewDetails => 'Подробнее';

  @override
  String get holidayGiftBoxPromoCopied => 'Промокод скопирован';

  @override
  String get holidayGiftBoxPromoCode => 'Промокод';

  @override
  String giftDiscountOff(String percent) {
    return 'Скидка $percent%';
  }

  @override
  String giftDiscountUpToOff(String percent) {
    return 'Скидка до $percent%';
  }

  @override
  String get holidayGiftBoxTerms => 'Условия';

  @override
  String get holidayGiftBoxVisitSite => 'Перейти на сайт партнёра';

  @override
  String holidayGiftBoxValidUntil(String date) {
    return 'Действительно до $date';
  }

  @override
  String holidayGiftBoxEndsInDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Заканчивается через $days дней',
      many: 'Заканчивается через $days дней',
      few: 'Заканчивается через $days дня',
      one: 'Заканчивается через $days день',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$_temp0',
      one: 'Заканчивается завтра',
      zero: 'Заканчивается сегодня',
    );
    return '$_temp1';
  }

  @override
  String get holidayGiftBoxValidWhileAvailable =>
      'Действительно, пока есть в наличии';

  @override
  String holidayGiftBoxUpdated(String date) {
    return 'Обновлено $date';
  }

  @override
  String holidayGiftBoxLanguage(String language) {
    return 'Язык: $language';
  }

  @override
  String get holidayGiftBoxRetry => 'Повторить';

  @override
  String get holidayGiftBoxLoadFailed => 'Не удалось загрузить предложения';

  @override
  String get holidayGiftBoxOfferUnavailable => 'Предложение недоступно';

  @override
  String get holidayGiftBoxBannerTitle => 'Посмотрите наш праздничный gift box';

  @override
  String get holidayGiftBoxBannerCta => 'Смотреть предложения';

  @override
  String get regionEurope => 'Европа';

  @override
  String get regionNorthAmerica => 'Северная Америка';

  @override
  String get regionAsia => 'Азия';

  @override
  String get regionAustralia => 'Австралия / Океания';

  @override
  String get regionWorldwide => 'По всему миру';

  @override
  String get regionAfrica => 'Африка';

  @override
  String get regionMiddleEast => 'Ближний Восток';

  @override
  String get regionSouthAmerica => 'Южная Америка';

  @override
  String get setToZeroButton => 'Обнулить';

  @override
  String get setToZeroDialogTitle => 'Обнулить запасы?';

  @override
  String get setToZeroDialogBody =>
      'Это установит оставшееся количество на 0 г. Вы сможете изменить это позже.';

  @override
  String get setToZeroDialogConfirm => 'Обнулить';

  @override
  String get setToZeroDialogCancel => 'Отмена';

  @override
  String get inventorySetToZeroSuccess => 'Запасы установлены на 0 г';

  @override
  String get inventorySetToZeroFail => 'Не удалось обнулить запасы';
}
