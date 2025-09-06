// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'آمار دانه‌ها';

  @override
  String get totalBeansBrewedLabel => 'مجموع دانه‌های استفاده‌شده';

  @override
  String get newBeansTriedLabel => 'دانه‌های جدید امتحان‌شده';

  @override
  String get originsExploredLabel => 'خاستگاه‌های کشف‌شده';

  @override
  String get regionsExploredLabel => 'منطقه‌های کشف‌شده';

  @override
  String get newRoastersDiscoveredLabel => 'رسترهای جدید کشف‌شده';

  @override
  String get favoriteRoastersLabel => 'رسترهای موردعلاقه';

  @override
  String get topOriginsLabel => 'برترین خاستگاه‌ها';

  @override
  String get topRegionsLabel => 'برترین منطقه‌ها';

  @override
  String get lastrecipe => 'آخرین دستور استفاده‌شده:';

  @override
  String get userRecipesTitle => 'دستورهای شما';

  @override
  String get userRecipesSectionCreated => 'ایجاد شده توسط شما';

  @override
  String get userRecipesSectionImported => 'وارد شده توسط شما';

  @override
  String get userRecipesEmpty => 'هیچ دستور غذایی یافت نشد';

  @override
  String get userRecipesDeleteTitle => 'حذف دستور؟';

  @override
  String get userRecipesDeleteMessage => 'این اقدام قابل بازگشت نیست.';

  @override
  String get userRecipesDeleteConfirm => 'حذف';

  @override
  String get userRecipesDeleteCancel => 'انصراف';

  @override
  String get userRecipesSnackbarDeleted => 'دستور حذف شد';

  @override
  String get hubUserRecipesTitle => 'دستورهای شما';

  @override
  String get hubUserRecipesSubtitle =>
      'مشاهده و مدیریت دستورهای ایجادشده و واردشده';

  @override
  String get hubAccountSubtitle => 'پروفایل خود را مدیریت کنید';

  @override
  String get hubSignInCreateSubtitle =>
      'برای همگام‌سازی دستورها و تنظیمات وارد شوید';

  @override
  String get hubBrewDiarySubtitle =>
      'تاریخچه دم‌آوری خود را مشاهده کنید و یادداشت اضافه کنید';

  @override
  String get hubBrewStatsSubtitle =>
      'آمار و روندهای دم‌آوری شخصی و جهانی را مشاهده کنید';

  @override
  String get hubSettingsSubtitle => 'تنظیمات و رفتار برنامه را تغییر دهید';

  @override
  String get hubAboutSubtitle => 'جزئیات برنامه، نسخه و مشارکت‌کنندگان';

  @override
  String get about => 'درباره برنامه';

  @override
  String get author => 'نویسنده';

  @override
  String get authortext =>
      'اپلیکیشن Timer.Coffee توسط آنتون کارلینر، علاقه‌مند به قهوه، متخصص رسانه و عکاس خبری ساخته شده است. امیدوارم این برنامه به شما کمک کند از قهوه لذت ببرید. خوشحال می‌شوم اگر در گیت‌هاب مشارکت کنید.';

  @override
  String get contributors => 'مشارکت‌کنندگان';

  @override
  String get errorLoadingContributors => 'خطا در بارگذاری مشارکت‌کنندگان';

  @override
  String get license => 'مجوز';

  @override
  String get licensetext =>
      'این برنامه یک نرم‌افزار آزاد است؛ شما می‌توانید آن را تحت شرایط مجوز عمومی همگانی گنو نسخه ۳ یا نسخه‌های بعدی (به انتخاب خودتان)، بازتوزیع یا تغییر دهید.';

  @override
  String get licensebutton => 'خواندن مجوز عمومی همگانی گنو نسخه ۳';

  @override
  String get website => 'وب‌سایت';

  @override
  String get sourcecode => 'کد منبع';

  @override
  String get support => 'برایم قهوه بخر';

  @override
  String get allrecipes => 'همه دستورها';

  @override
  String get favoriterecipes => 'دستورهای موردعلاقه';

  @override
  String get coffeeamount => 'مقدار قهوه (گرم)';

  @override
  String get wateramount => 'مقدار آب (میلی‌لیتر)';

  @override
  String get watertemp => 'دمای آب';

  @override
  String get grindsize => 'درجه آسیاب';

  @override
  String get brewtime => 'زمان دم';

  @override
  String get recipesummary => 'خلاصه دستور';

  @override
  String get recipesummarynote =>
      'نکته: این یک دستور پایه با مقادیر پیش‌فرض آب و قهوه است.';

  @override
  String get preparation => 'آماده‌سازی';

  @override
  String get brewingprocess => 'فرآیند دم';

  @override
  String get step => 'مرحله';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ثانیه',
      one: 'ثانیه',
      zero: 'ثانیه',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg =>
      'از استفاده از Timer.Coffee متشکریم! قهوه‌تان نوش جان';

  @override
  String get coffeefact => 'دانستنی قهوه';

  @override
  String get home => 'خانه';

  @override
  String get appversion => 'نسخه برنامه';

  @override
  String get tipsmall => 'یک قهوه کوچک بخر';

  @override
  String get tipmedium => 'یک قهوه متوسط بخر';

  @override
  String get tiplarge => 'یک قهوه بزرگ بخر';

  @override
  String get supportdevelopment => 'حمایت از توسعه';

  @override
  String get supportdevmsg =>
      'کمک‌های شما هزینه نگهداری سرورها را پوشش می‌دهد، امکان افزودن دستگاه‌های دم‌آوری بیشتر و اضافه کردن دستورهای جدید به برنامه را فراهم می‌کند.';

  @override
  String get supportdevtnx => 'ممنون که به کمک فکر می‌کنید!';

  @override
  String get donationok => 'متشکرم!';

  @override
  String get donationtnx =>
      'از حمایت‌تان بسیار متشکرم! آرزوی دم‌آوری‌های عالی برای شما دارم! ☕️';

  @override
  String get donationerr => 'خطا';

  @override
  String get donationerrmsg => 'خطا در پردازش خرید، لطفاً دوباره تلاش کنید.';

  @override
  String get sharemsg => 'این دستور را ببین:';

  @override
  String get finishbrew => 'پایان';

  @override
  String get settings => 'تنظیمات';

  @override
  String get settingstheme => 'تم';

  @override
  String get settingsthemelight => 'روشن';

  @override
  String get settingsthemedark => 'تیره';

  @override
  String get settingsthemesystem => 'سیستم';

  @override
  String get settingslang => 'زبان';

  @override
  String get sweet => 'شیرین';

  @override
  String get balance => 'تعادل';

  @override
  String get acidic => 'اسیدی';

  @override
  String get light => 'روشن';

  @override
  String get strong => 'قوی';

  @override
  String get slidertitle => 'عنوان اسلایدر';

  @override
  String get whatsnewtitle => 'چه چیز جدید است';

  @override
  String get whatsnewclose => 'بستن';

  @override
  String get seasonspecials => 'ویژه‌های فصل';

  @override
  String get snow => 'برف';

  @override
  String get noFavoriteRecipesMessage => 'هنوز دستوری را محبوب نکرده‌اید.';

  @override
  String get explore => 'کاوش';

  @override
  String get dateFormat => 'yyyy/MM/dd';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'دفترچه دم';

  @override
  String get brewdiarynotfound => 'دفترچه‌ای یافت نشد';

  @override
  String get beans => 'دانه‌ها';

  @override
  String get roaster => 'رستر';

  @override
  String get rating => 'امتیاز';

  @override
  String get notes => 'نکته‌ها';

  @override
  String get statsscreen => 'صفحه آمار';

  @override
  String get yourStats => 'آمار شما';

  @override
  String get coffeeBrewed => 'قهوه دم‌شده';

  @override
  String get litersUnit => 'لیتر';

  @override
  String get mostUsedRecipes => 'پرکاربردترین دستورها';

  @override
  String get globalStats => 'آمار جهانی';

  @override
  String get unknownRecipe => 'دستور ناشناخته';

  @override
  String get noData => 'داده‌ای وجود ندارد';

  @override
  String error(Object error) {
    return 'خطا';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'کسی همین الان $recipeName را دم کرد';
  }

  @override
  String get timePeriodToday => 'امروز';

  @override
  String get timePeriodThisWeek => 'این هفته';

  @override
  String get timePeriodThisMonth => 'این ماه';

  @override
  String get timePeriodCustom => 'بازه سفارشی';

  @override
  String get statsFor => 'آمار برای';

  @override
  String get homescreenbrewcoffee => 'قهوه دم کن';

  @override
  String get homescreenhub => 'مرکز';

  @override
  String get homescreenmore => 'بیشتر';

  @override
  String get addBeans => 'افزودن دانه‌ها';

  @override
  String get removeBeans => 'حذف دانه‌ها';

  @override
  String get name => 'نام';

  @override
  String get origin => 'مبدا';

  @override
  String get details => 'جزئیات';

  @override
  String get coffeebeans => 'دانه‌های قهوه';

  @override
  String get loading => 'در حال بارگذاری';

  @override
  String get nocoffeebeans => 'هیچ دانه قهوه‌ای یافت نشد';

  @override
  String get delete => 'حذف';

  @override
  String get confirmDeleteTitle => 'حذف ورودی؟';

  @override
  String get confirmDeleteMessage =>
      'آیا مطمئنید که می‌خواهید این ورودی را حذف کنید؟ این عمل قابل بازگشت نیست.';

  @override
  String get removeFavorite => 'حذف از محبوب‌ها';

  @override
  String get addFavorite => 'افزودن به محبوب‌ها';

  @override
  String get toggleEditMode => 'تغییر حالت ویرایش';

  @override
  String get coffeeBeansDetails => 'جزئیات دانه‌های قهوه';

  @override
  String get edit => 'ویرایش';

  @override
  String get coffeeBeansNotFound => 'دانه قهوه‌ای پیدا نشد';

  @override
  String get geographyTerroir => 'جغرافیا/ترُوار';

  @override
  String get variety => 'گونه';

  @override
  String get region => 'منطقه';

  @override
  String get elevation => 'ارتفاع';

  @override
  String get harvestDate => 'تاریخ برداشت';

  @override
  String get processing => 'فرآوری';

  @override
  String get processingMethod => 'روش فرآوری';

  @override
  String get roastDate => 'تاریخ رُست';

  @override
  String get roastLevel => 'درجه رُست';

  @override
  String get cuppingScore => 'امتیاز کاپینگ';

  @override
  String get flavorProfile => 'پروفایل طعمی';

  @override
  String get tastingNotes => 'یادداشت‌های چشایی';

  @override
  String get additionalNotes => 'یادداشت‌های اضافی';

  @override
  String get noCoffeeBeans => 'دانه قهوه‌ای پیدا نشد';

  @override
  String get editCoffeeBeans => 'ویرایش دانه‌های قهوه';

  @override
  String get addCoffeeBeans => 'افزودن دانه‌های قهوه';

  @override
  String get showImagePicker => 'نمایش انتخابگر تصویر';

  @override
  String get pleaseNote => 'لطفاً توجه کنید';

  @override
  String get firstTimePopupMessage =>
      '۱. ما برای پردازش تصاویر از سرویس‌های خارجی استفاده می‌کنیم. با ادامه کار، موافقت می‌کنید که تصاویر شما به این سرویس‌ها ارسال شود.\n۲. در حال حاضر محدودیت ۵ تصویر در ماه وجود دارد (۱ توکن = ۱ تصویر). این محدودیت ممکن است در آینده تغییر کند.';

  @override
  String get ok => 'باشه';

  @override
  String get takePhoto => 'عکاسی';

  @override
  String get selectFromPhotos => 'انتخاب از گالری';

  @override
  String get takeAdditionalPhoto => 'عکس اضافی بگیرید؟';

  @override
  String get no => 'خیر';

  @override
  String get yes => 'بله';

  @override
  String get selectedImages => 'تصاویر انتخاب‌شده';

  @override
  String get selectedImage => 'تصویر انتخاب‌شده';

  @override
  String get backToSelection => 'بازگشت به انتخاب';

  @override
  String get next => 'بعدی';

  @override
  String get unexpectedErrorOccurred => 'خطای غیرمنتظره رخ داد';

  @override
  String get tokenLimitReached => 'محدودیت توکن به پایان رسید';

  @override
  String get noCoffeeLabelsDetected => 'برچسبی شناسایی نشد';

  @override
  String get collectedInformation => 'اطلاعات جمع‌آوری‌شده';

  @override
  String get enterRoaster => 'رستر را وارد کنید';

  @override
  String get enterName => 'نام را وارد کنید';

  @override
  String get enterOrigin => 'مبدا را وارد کنید';

  @override
  String get optional => 'اختیاری';

  @override
  String get enterVariety => 'گونه را وارد کنید';

  @override
  String get enterProcessingMethod => 'روش فرآوری را وارد کنید';

  @override
  String get enterRoastLevel => 'درجه رُست را وارد کنید';

  @override
  String get enterRegion => 'منطقه را وارد کنید';

  @override
  String get enterTastingNotes => 'یادداشت‌های چشایی را وارد کنید';

  @override
  String get enterElevation => 'ارتفاع را وارد کنید';

  @override
  String get enterCuppingScore => 'امتیاز کاپینگ را وارد کنید';

  @override
  String get enterNotes => 'یادداشت‌ها را وارد کنید';

  @override
  String get selectHarvestDate => 'انتخاب تاریخ برداشت';

  @override
  String get selectRoastDate => 'انتخاب تاریخ رُست';

  @override
  String get selectDate => 'انتخاب تاریخ';

  @override
  String get save => 'ذخیره';

  @override
  String get fillRequiredFields => 'فیلدهای الزامی را پر کنید';

  @override
  String get analyzing => 'در حال تحلیل...';

  @override
  String get errorMessage => 'پیام خطا';

  @override
  String get selectCoffeeBeans => 'انتخاب دانه قهوه';

  @override
  String get addNewBeans => 'افزودن دانه جدید';

  @override
  String get favorite => 'محبوب';

  @override
  String get notFavorite => 'غیرمحبوب';

  @override
  String get myBeans => 'دانه‌های من';

  @override
  String get signIn => 'ورود';

  @override
  String get signOut => 'خروج';

  @override
  String get signInWithApple => 'ورود با اپل';

  @override
  String get signInSuccessful => 'ورود موفق';

  @override
  String get signInError => 'ورود با اپل با خطا مواجه شد';

  @override
  String get signInWithGoogle => 'ورود با گوگل';

  @override
  String get signOutSuccessful => 'خروج موفق';

  @override
  String get signInSuccessfulGoogle => 'ورود موفق با گوگل';

  @override
  String get signInWithEmail => 'ورود با ایمیل';

  @override
  String get enterEmail => 'ایمیل را وارد کنید';

  @override
  String get emailHint => 'example@domain.com';

  @override
  String get cancel => 'انصراف';

  @override
  String get sendMagicLink => 'ارسال لینک جادویی';

  @override
  String get magicLinkSent => 'لینک ورود ارسال شد';

  @override
  String get sendOTP => 'ارسال کد';

  @override
  String get otpSent => 'کد ارسال شد';

  @override
  String get otpSendError => 'خطا در ارسال کد';

  @override
  String get enterOTP => 'کد را وارد کنید';

  @override
  String get otpHint => 'کد یک‌بارمصرف';

  @override
  String get verify => 'تایید';

  @override
  String get signInSuccessfulEmail => 'ورود ایمیلی موفق';

  @override
  String get invalidOTP => 'کد نامعتبر است';

  @override
  String get otpVerificationError => 'خطا در تایید کد';

  @override
  String get success => 'موفقیت';

  @override
  String get otpSentMessage => 'کد تایید به ایمیل/شماره شما ارسال شد';

  @override
  String get otpHint2 => 'کد ۶ رقمی';

  @override
  String get signInCreate => 'ورود / ایجاد حساب';

  @override
  String get accountManagement => 'مدیریت حساب';

  @override
  String get deleteAccount => 'حذف حساب';

  @override
  String get deleteAccountWarning =>
      'لطفاً توجه کنید: اگر ادامه دهید، حساب شما حذف می‌شود. برای فعال‌سازی همگام‌سازی دوباره باید حساب جدید بسازید.';

  @override
  String get deleteAccountConfirmation => 'حساب با موفقیت حذف شد';

  @override
  String get accountDeleted => 'حساب حذف شد';

  @override
  String get accountDeletionError => 'خطا در حذف حساب، لطفاً دوباره تلاش کنید';

  @override
  String get deleteAccountTitle => 'مهم';

  @override
  String get selectBeans => 'انتخاب دانه';

  @override
  String get all => 'همه';

  @override
  String get selectRoaster => 'انتخاب رستر';

  @override
  String get selectOrigin => 'انتخاب مبدا';

  @override
  String get resetFilters => 'ریست فیلترها';

  @override
  String get showFavoritesOnly => 'فقط موارد محبوب';

  @override
  String get apply => 'اعمال';

  @override
  String get selectSize => 'انتخاب اندازه';

  @override
  String get sizeStandard => 'استاندارد';

  @override
  String get sizeMedium => 'متوسط';

  @override
  String get sizeXL => 'بزرگ';

  @override
  String get yearlyStatsAppBarTitle => 'آمار سال ۲۰۲۴';

  @override
  String get yearlyStatsStory1Text =>
      'سلام!\nبیایید نگاهی بیندازیم به سال قهوه‌ای شما ☕️';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'قبل از هر چیز.\nامسال مقداری قهوه دم کردی$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'دقیق‌تر بگوییم،\nشما $liters لیتر قهوه در ۲۰۲۴ دم کردید!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'شما از $roasterCount رستر استفاده کردید';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'سه رستر برتر شما:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'قهوه شما را به سفری\nدور دنیا برد$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'شما دانه‌های قهوه از $originCount کشور چشیدید!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'شما طعم‌های جدیدی را امتحان کردید و';

  @override
  String get yearlyStatsStory7Part2 =>
      '...اما با کاربران از 110 کشور دیگر\nدر 6 قاره!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'شما وفادار ماندید و فقط از این $count روش دم‌آوری در سال استفاده کردید:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'شما در حال کشف طعم‌های جدید بودید و $count روش دم‌آوری در سال استفاده کردید:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'شما یک کاشف واقعی قهوه بودید و $count روش دم‌آوری در سال استفاده کردید:';
  }

  @override
  String get yearlyStatsStory9Text => 'این‌ها لحظات خوشمزه‌ای بودند!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'سه دستور برتر شما در ۲۰۲۴ این‌ها بودند$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'به خاطر یک سال عالی قهوه سپاسگزاریم!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'یک قلب بده ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'کمک مالی';

  @override
  String get yearlyStatsActionShare => 'اشتراک‌گذاری';

  @override
  String get yearlyStatsUnknown => 'نامشخص';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'اشتراک‌گذاری ناموفق بود: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'در حال آماده‌سازی «سال من»...';

  @override
  String get yearlyStatsShareProgressTop3Recipes =>
      'در حال آماده‌سازی سه دستور برتر...';

  @override
  String get yearlyStatsShareProgressTop3Roasters =>
      'در حال آماده‌سازی سه رستر برتر...';

  @override
  String get yearlyStatsFailedToLike => 'خطا در ثبت پسندیدن';

  @override
  String get labelCoffeeBrewed => 'قهوه دم‌شده:';

  @override
  String get labelTastedBeansBy => 'دانه‌ها چشیده شده از:';

  @override
  String get labelDiscoveredCoffeeFrom => 'قهوه کشف‌شده از:';

  @override
  String get labelUsedBrewingMethods => 'روش‌های دم استفاده‌شده:';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'رسترها',
      one: 'رستر',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'کشورها',
      one: 'کشور',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'روش‌های دم‌آوری',
      one: 'روش دم‌آوری',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'ویرایش دستور';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'ایجاد دستور';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'مراحل دستور';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'نام دستور';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'توضیح کوتاه';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'روش دم';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'مقدار قهوه';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'مقدار آب';

  @override
  String get recipeCreationScreenWaterTempLabel => 'دمای آب';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'اندازه آسیاب';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => 'کل زمان دم';

  @override
  String get recipeCreationScreenMinutesLabel => 'دقیقه';

  @override
  String get recipeCreationScreenSecondsLabel => 'ثانیه';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'مرحله آماده‌سازی';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'مرحله دم $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'توضیح مرحله';

  @override
  String get recipeCreationScreenStepTimeLabel => 'زمان مرحله';

  @override
  String get recipeCreationScreenRecipeNameValidator => 'نام دستور لازم است';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'توضیح کوتاه لازم است';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'روش دم انتخاب نشده است';

  @override
  String get recipeCreationScreenRequiredValidator => 'این فیلد الزامی است';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'عدد نامعتبر';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'توضیح مرحله لازم است';

  @override
  String get recipeCreationScreenContinueButton => 'ادامه';

  @override
  String get recipeCreationScreenAddStepButton => 'افزودن مرحله';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'ذخیره دستور';

  @override
  String get recipeCreationScreenUpdateSuccess => 'دستور با موفقیت به‌روز شد';

  @override
  String get recipeCreationScreenSaveSuccess => 'دستور با موفقیت ذخیره شد';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'خطا در ذخیره دستور: $error';
  }

  @override
  String get unitGramsShort => 'گرم';

  @override
  String get unitMillilitersShort => 'میلی‌لیتر';

  @override
  String get unitGramsLong => 'گرم';

  @override
  String get unitMillilitersLong => 'میلی‌لیتر';

  @override
  String get recipeCopySuccess => 'دستور با موفقیت کپی شد';

  @override
  String recipeCopyError(String error) {
    return 'کپی دستور ناموفق بود: $error';
  }

  @override
  String get createRecipe => 'ایجاد دستور';

  @override
  String errorSyncingData(Object error) {
    return 'خطا در همگام‌سازی داده: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'خطا در خروج: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'آماده‌سازی تجهیزات';

  @override
  String get loadingEllipsis => 'در حال بارگذاری...';

  @override
  String get recipeDeletedSuccess => 'دستور حذف شد';

  @override
  String recipeDeleteError(Object error) {
    return 'حذف دستور ناموفق بود: $error';
  }

  @override
  String get noRecipesFound => 'هیچ دستوری یافت نشد';

  @override
  String recipeLoadError(Object error) {
    return 'خطا در بارگذاری دستور: $error';
  }

  @override
  String get unknownBrewingMethod => 'روش دم ناشناخته';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'بارگذاری دستور کپی‌شده برای ویرایش ناموفق بود.';

  @override
  String get recipeCopyErrorOperationFailed => 'عملیات ناموفق بود.';

  @override
  String get notProvided => 'ارائه نشده';

  @override
  String get recipeUpdateFailedFetch => 'بروزرسانی دستور ناموفق بود.';

  @override
  String get recipeImportSuccess => 'دستور با موفقیت وارد شد!';

  @override
  String get recipeImportFailedSave => 'ذخیره دستور واردشده ناموفق بود.';

  @override
  String get recipeImportFailedFetch =>
      'دریافت اطلاعات دستور برای وارد کردن ناموفق بود.';

  @override
  String get recipeNotImported => 'دستور وارد نشد.';

  @override
  String get recipeNotFoundCloud => 'دستور در ابر پیدا نشد یا عمومی نیست.';

  @override
  String get recipeLoadErrorGeneric => 'خطا در بارگذاری دستور.';

  @override
  String get recipeUpdateAvailableTitle => 'بروزرسانی موجود است';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'نسخه جدیدتری از \'$recipeName\' آنلاین موجود است. بروزرسانی شود؟';
  }

  @override
  String get dialogCancel => 'لغو';

  @override
  String get dialogUpdate => 'بروزرسانی';

  @override
  String get recipeImportTitle => 'وارد کردن دستور';

  @override
  String recipeImportBody(String recipeName) {
    return 'آیا می‌خواهید دستور «$recipeName» را از فضای ابری وارد کنید؟';
  }

  @override
  String get dialogImport => 'وارد کردن';

  @override
  String get moderationReviewNeededTitle => 'نیاز به بازبینی';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'این محتوا نیاز به بازبینی دستی دارد قبل از انتشار.';
  }

  @override
  String get dismiss => 'بستن';

  @override
  String get reviewRecipeButton => 'بازبینی دستور';

  @override
  String get signInRequiredTitle => 'ورود لازم است';

  @override
  String get signInRequiredBodyShare =>
      'برای اشتراک‌گذاری باید ابتدا وارد شوید.';

  @override
  String get syncSuccess => 'همگام‌سازی موفق';

  @override
  String get tooltipEditRecipe => 'ویرایش دستور';

  @override
  String get tooltipCopyRecipe => 'کپی دستور';

  @override
  String get tooltipShareRecipe => 'اشتراک‌گذاری دستور';

  @override
  String get signInRequiredSnackbar => 'برای ادامه باید وارد شوید';

  @override
  String get moderationErrorFunction =>
      'در فراخوانی ماژول پالایش محتوا خطا رخ داد';

  @override
  String get moderationReasonDefault => 'محتوا با خط‌مشی مطابقت نداشت';

  @override
  String get moderationFailedTitle => 'رد شد';

  @override
  String moderationFailedBody(String reason) {
    return 'محتوا با خط‌مشی مطابقت ندارد و ذخیره نشد.';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'خطا در اشتراک‌گذاری';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return 'جزئیات دستور';
  }

  @override
  String get saveLocallyCheckLater =>
      'به صورت محلی ذخیره شد. بعداً دوباره بررسی کنید.';

  @override
  String get saveLocallyModerationFailedTitle => 'ذخیره محلی ناموفق';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'به دلیل خطای پالایش محتوا، دستور به صورت محلی ذخیره نشد.';
  }

  @override
  String get editImportedRecipeTitle => 'ویرایش دستور واردشده';

  @override
  String get editImportedRecipeBody =>
      'این دستور وارد شده است. آیا می‌خواهید نسخه‌ای کپی کنید و ویرایش کنید؟';

  @override
  String get editImportedRecipeButtonCopy => 'کپی و ویرایش';

  @override
  String get editImportedRecipeButtonCancel => 'لغو';

  @override
  String get editDisplayNameTitle => 'ویرایش نام نمایشی';

  @override
  String get displayNameHint => 'نامی که دیگران می‌بینند';

  @override
  String get displayNameEmptyError => 'نام نمایشی خالی است';

  @override
  String get displayNameTooLongError =>
      'نام نمایشی نمی‌تواند بیش از ۵۰ نویسه باشد';

  @override
  String get errorUserNotLoggedIn =>
      'کاربر وارد نشده است. لطفاً دوباره وارد شوید.';

  @override
  String get displayNameUpdateSuccess => 'نام نمایشی با موفقیت به‌روز شد!';

  @override
  String displayNameUpdateError(String error) {
    return 'به‌روزرسانی نام نمایشی ناموفق بود: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'حذف تصویر؟';

  @override
  String get deletePictureConfirmationBody =>
      'آیا مطمئنید که می‌خواهید تصویر پروفایل خود را حذف کنید؟';

  @override
  String get deletePictureSuccess => 'تصویر پروفایل حذف شد.';

  @override
  String deletePictureError(String error) {
    return 'حذف تصویر پروفایل ناموفق بود: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'به‌روزرسانی تصویر پروفایل ناموفق بود: $error';
  }

  @override
  String get updatePictureSuccess => 'تصویر پروفایل با موفقیت به‌روز شد!';

  @override
  String get deletePictureTooltip => 'حذف تصویر';

  @override
  String get account => 'حساب';

  @override
  String get settingsBrewingMethodsTitle => 'روش‌های دم در صفحه اصلی';

  @override
  String get filter => 'فیلتر';

  @override
  String get sortBy => 'مرتب‌سازی بر اساس';

  @override
  String get dateAdded => 'تاریخ افزوده‌شدن';

  @override
  String get secondsAbbreviation => 'ث';

  @override
  String get settingsAppIcon => 'آیکون برنامه';

  @override
  String get settingsAppIconDefault => 'پیش‌فرض';

  @override
  String get settingsAppIconLegacy => 'قدیمی';

  @override
  String get searchBeans => 'جستجوی دانه‌ها';

  @override
  String get favorites => 'موردعلاقه‌ها';

  @override
  String get searchPrefix => 'جستجو';

  @override
  String get clearAll => 'پاک کردن همه';

  @override
  String get noBeansMatchSearch => 'هیچ دانه‌ای با جستجو مطابقت ندارد';

  @override
  String get clearFilters => 'پاک کردن فیلترها';

  @override
  String get farmer => 'کشاورز';

  @override
  String get farm => 'مزرعه';

  @override
  String get enterFarmer => 'نام کشاورز را وارد کنید';

  @override
  String get enterFarm => 'نام مزرعه را وارد کنید';

  @override
  String get requiredInformation => 'اطلاعات الزامی';

  @override
  String get basicDetails => 'جزئیات پایه';

  @override
  String get qualityMeasurements => 'اندازه‌گیری‌های کیفیت';

  @override
  String get importantDates => 'تاریخ‌های مهم';

  @override
  String get brewStats => 'آمار دم‌آوری';

  @override
  String get showMore => 'نمایش بیشتر';

  @override
  String get showLess => 'نمایش کمتر';

  @override
  String get unpublishRecipeDialogTitle => 'خصوصی کردن دستور پخت';

  @override
  String get unpublishRecipeDialogMessage =>
      'هشدار: خصوصی کردن این دستور پخت باعث می‌شود:';

  @override
  String get unpublishRecipeDialogBullet1 => 'از نتایج جستجوی عمومی حذف شود';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'کاربران جدید نتوانند آن را وارد کنند';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'کاربرانی که قبلاً آن را وارد کرده‌اند، نسخه‌های خود را حفظ خواهند کرد';

  @override
  String get unpublishRecipeDialogKeepPublic => 'عمومی بماند';

  @override
  String get unpublishRecipeDialogMakePrivate => 'خصوصی کردن';

  @override
  String get recipeUnpublishSuccess =>
      'دستور پخت با موفقیت از حالت انتشار خارج شد';

  @override
  String recipeUnpublishError(String error) {
    return 'خطا در لغو انتشار دستور پخت: $error';
  }

  @override
  String get recipePublicTooltip =>
      'دستور پخت عمومی است - برای خصوصی کردن ضربه بزنید';

  @override
  String get recipePrivateTooltip =>
      'دستور پخت خصوصی است - برای عمومی کردن به اشتراک بگذارید';
}
