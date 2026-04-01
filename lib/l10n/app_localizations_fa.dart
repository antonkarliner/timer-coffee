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
  String get newRoastersDiscoveredLabel => 'رُستری‌های جدید کشف‌شده';

  @override
  String get favoriteRoastersLabel => 'رُستری‌های موردعلاقه';

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
  String get userRecipesEmpty => 'هیچ دستوری پیدا نشد';

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
  String get supportButtonLabel => 'پشتیبانی';

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
  String get brewtime => 'زمان دم‌آوری';

  @override
  String get recipesummary => 'خلاصه دستور';

  @override
  String get recipesummarynote =>
      'نکته: این یک دستور پایه با مقادیر پیش‌فرض آب و قهوه است.';

  @override
  String get preparation => 'آماده‌سازی';

  @override
  String get brewingprocess => 'فرآیند دم‌آوری';

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
      'کمک‌های شما به پوشش هزینه‌های نگهداری، مانند مجوزهای توسعه‌دهنده، کمک می‌کند. همچنین به من امکان می‌دهد ابزارهای دم‌آوری بیشتری را امتحان کنم و دستورهای بیشتری به برنامه اضافه کنم.';

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
  String get settingsDateTimeFormat => 'فرمت تاریخ و زمان';

  @override
  String get settingsDateFormatLabel => 'فرمت تاریخ';

  @override
  String get settingsTimeFormatLabel => 'فرمت زمان';

  @override
  String get settingsDateFormatAuto => 'خودکار (مطابق زبان)';

  @override
  String get settingsDateFormatDMY => 'DD/MM/YYYY';

  @override
  String get settingsDateFormatMDY => 'MM/DD/YYYY';

  @override
  String get settingsDateFormatYMD => 'YYYY-MM-DD';

  @override
  String get settingsTimeFormat12h => '۱۲ ساعته (AM/PM)';

  @override
  String get settingsTimeFormat24h => '۲۴ ساعته';

  @override
  String get sweet => 'شیرین';

  @override
  String get balance => 'متعادل';

  @override
  String get acidic => 'اسیدی';

  @override
  String get light => 'ملایم';

  @override
  String get strong => 'قوی';

  @override
  String get slidertitle => 'برای تنظیم طعم از لغزنده‌ها استفاده کنید';

  @override
  String get whatsnewtitle => 'چه چیز جدید است';

  @override
  String get whatsnewclose => 'بستن';

  @override
  String get seasonspecials => 'ویژه‌های فصل';

  @override
  String get snow => 'برف';

  @override
  String get noFavoriteRecipesMessage =>
      'فهرست دستورهای موردعلاقه‌تان فعلاً خالی است. با کاوش و دم‌آوری، محبوب‌های خودتان را پیدا کنید!';

  @override
  String get explore => 'کاوش';

  @override
  String get dateFormat => 'yyyy/MM/dd';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'دفترچه دم‌آوری';

  @override
  String get brewdiarynotfound => 'هیچ ورودی‌ای پیدا نشد';

  @override
  String get beans => 'دانه‌های قهوه';

  @override
  String get roaster => 'رُستری';

  @override
  String get rating => 'امتیاز';

  @override
  String get notes => 'یادداشت‌ها';

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
  String get pulseUserRecipe => 'دستور کاربر';

  @override
  String get noData => 'داده‌ای وجود ندارد';

  @override
  String get refresh => 'تازه‌سازی';

  @override
  String error(String error) {
    return 'خطا: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'کسی همین الان $recipeName را دم کرد';
  }

  @override
  String pulseSomeoneBrewed(String recipeName) {
    return 'یک نفر $recipeName را دم کرد';
  }

  @override
  String pulseSomeoneFromBrewed(String country, String recipeName) {
    return 'یک نفر از $country $recipeName را دم کرد';
  }

  @override
  String get pulseTitle => 'نبض';

  @override
  String get hubPulseSubtitle => 'خوراک زنده دم‌آوری';

  @override
  String get pulseLiveSummary => 'خلاصه زنده';

  @override
  String get pulseBrewsLabel => 'دم‌آوری‌ها';

  @override
  String pulseBrewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بار',
    );
    return '$_temp0';
  }

  @override
  String get timePeriodRecent => 'اخیراً';

  @override
  String get timePeriodLastHour => 'ساعت گذشته';

  @override
  String get timePeriodToday => 'امروز';

  @override
  String get timePeriodYesterday => 'دیروز';

  @override
  String get timePeriodThisWeek => 'این هفته';

  @override
  String get timePeriodThisMonth => 'این ماه';

  @override
  String get timePeriodOlder => 'قدیمی‌تر';

  @override
  String get timePeriodCustom => 'بازه سفارشی';

  @override
  String get relativeTimeJustNow => 'همین الان';

  @override
  String relativeTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقیقه پیش',
      one: '۱ دقیقه پیش',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعت پیش',
      one: '۱ ساعت پیش',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeHoursMinutesAgo(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ساعت',
      one: '۱ ساعت',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقیقه',
      one: '۱ دقیقه',
    );
    return '$_temp0 و $_temp1 پیش';
  }

  @override
  String relativeTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روز پیش',
      one: '۱ روز پیش',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ماه پیش',
      one: '۱ ماه پیش',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سال پیش',
      one: '۱ سال پیش',
    );
    return '$_temp0';
  }

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
  String get origin => 'خاستگاه';

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
  String get recipeDuplicateConfirmTitle => 'از این دستور یک کپی ساخته شود؟';

  @override
  String get recipeDuplicateConfirmMessage =>
      'این کار یک کپی از دستور شما ایجاد می‌کند که می‌توانید به طور مستقل ویرایش کنید. آیا می‌خواهید ادامه دهید؟';

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
  String get basicInformation => 'اطلاعات پایه';

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
  String get tastingNotes => 'نُت‌های طعمی';

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
      '۱. برای پردازش تصاویر از سرویس‌های خارجی استفاده می‌کنیم. با ادامه دادن، با این موضوع موافقت می‌کنید.\n۲. اگرچه تصاویر شما را ذخیره نمی‌کنیم، لطفاً از درج هرگونه اطلاعات شخصی در آن‌ها خودداری کنید.\n۳. در حال حاضر شناسایی تصویر به ۱۰ توکن در ماه محدود است (۱ توکن = ۱ تصویر). این محدودیت ممکن است در آینده تغییر کند.';

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
  String get tokenLimitReached =>
      'متأسفیم، این ماه به سقف توکن شناسایی تصویر رسیده‌اید';

  @override
  String get noCoffeeLabelsDetected =>
      'هیچ برچسب قهوه‌ای شناسایی نشد. با تصویر دیگری امتحان کنید.';

  @override
  String get collectedInformation => 'اطلاعات جمع‌آوری‌شده';

  @override
  String get enterRoaster => 'رُستری را وارد کنید';

  @override
  String get enterName => 'نام را وارد کنید';

  @override
  String get enterOrigin => 'خاستگاه را وارد کنید';

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
  String get enterTastingNotes => 'نُت‌های طعمی را وارد کنید';

  @override
  String get enterElevation => 'ارتفاع را وارد کنید';

  @override
  String get enterCuppingScore => 'امتیاز کاپینگ را وارد کنید';

  @override
  String get enterNotes => 'یادداشت‌ها را وارد کنید';

  @override
  String get inventory => 'موجودی';

  @override
  String get amountLeft => 'مقدار باقیمانده';

  @override
  String get enterAmountLeft => 'مقدار باقیمانده را وارد کنید';

  @override
  String get selectHarvestDate => 'انتخاب تاریخ برداشت';

  @override
  String get selectRoastDate => 'انتخاب تاریخ رُست';

  @override
  String get selectDate => 'انتخاب تاریخ';

  @override
  String get selectTime => 'انتخاب زمان';

  @override
  String get save => 'ذخیره';

  @override
  String get fillRequiredFields => 'فیلدهای الزامی را پر کنید';

  @override
  String get analyzing => 'در حال تحلیل...';

  @override
  String get errorMessage => 'خطا';

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
  String get signInErrorGoogle => 'خطا در ورود با گوگل';

  @override
  String get signInWithGoogle => 'ورود با گوگل';

  @override
  String get signOutSuccessful => 'خروج موفق';

  @override
  String get signOutConfirmationTitle => 'آیا مطمئنید می‌خواهید خارج شوید؟';

  @override
  String get signOutConfirmationMessage =>
      'همگام‌سازی ابری متوقف می‌شود. برای ادامه دوباره وارد شوید.';

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
  String get otpSent => 'کد یک‌بارمصرف به ایمیل شما ارسال شد';

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
  String get otpSentMessage =>
      'یک کد یک‌بارمصرف به ایمیل شما ارسال می‌شود. لطفاً پس از دریافت، آن را در پایین وارد کنید.';

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
      'لطفاً توجه کنید: اگر ادامه دهید، حساب شما و داده‌های مرتبط با آن از سرورهای ما حذف خواهد شد. نسخه محلی داده‌ها روی دستگاه باقی می‌ماند؛ اگر می‌خواهید آن را هم حذف کنید، کافی است برنامه را پاک کنید. برای فعال‌سازی دوباره همگام‌سازی، باید دوباره یک حساب جدید بسازید.';

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
  String get selectRoaster => 'انتخاب رُستری';

  @override
  String get selectOrigin => 'انتخاب خاستگاه';

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
  String get sizeXL => 'XL';

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
  String yearlyStatsStory4Text(num roasterCount) {
    return 'دانه‌هایی از $roasterCount رُستری را امتحان کردی';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'سه رُستری برترت:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'قهوه شما را به سفری\nدور دنیا برد$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(num originCount) {
    return 'شما دانه‌های قهوه از $originCount کشور چشیدید!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'تو تنها دم‌آوری نمی‌کردی…';

  @override
  String get yearlyStatsStory7Part2 =>
      '...بلکه همراه کاربران ۱۱۰ کشور دیگر\nدر ۶ قاره دم می‌کردی!';

  @override
  String yearlyStatsStory8TitleLow(num count) {
    return 'شما وفادار ماندید و فقط از این $count روش دم‌آوری در سال استفاده کردید:';
  }

  @override
  String yearlyStatsStory8TitleMedium(num count) {
    return 'شما در حال کشف طعم‌های جدید بودید و $count روش دم‌آوری در سال استفاده کردید:';
  }

  @override
  String yearlyStatsStory8TitleHigh(num count) {
    return 'شما یک کاشف واقعی قهوه بودید و $count روش دم‌آوری در سال استفاده کردید:';
  }

  @override
  String get yearlyStatsStory9Text => 'این‌ها لحظات خوشمزه‌ای بودند!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'سه دستور برتر شما در ۲۰۲۴ این‌ها بودند$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'در ۲۰۲۵ می‌بینیمت!';

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
  String get yearlyStatsShareProgressMyYear => 'سال من با Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes => 'سه دستور برتر من:';

  @override
  String get yearlyStatsShareProgressTop3Roasters => 'سه رُستری برتر من:';

  @override
  String get yearlyStats25AppBarTitle => 'سال شما با Timer.Coffee — ۲۰۲۵';

  @override
  String get yearlyStats25AppBarTitleSimple => 'Timer.Coffee در ۲۰۲۵';

  @override
  String get yearlyStats25Slide1Title => 'سال شما با Timer.Coffee';

  @override
  String get yearlyStats25Slide1Subtitle =>
      'برای دیدن اینکه در ۲۰۲۵ چطور قهوه دم کردی، ضربه بزن';

  @override
  String get yearlyStats25Slide2Intro => 'با هم قهوه دم کردیم...';

  @override
  String yearlyStats25Slide2Count(String count) {
    return '$count بار';
  }

  @override
  String yearlyStats25Slide2Liters(String liters) {
    return 'یعنی حدود $liters لیتر قهوه';
  }

  @override
  String get yearlyStats25Slide2Cambridge =>
      'به اندازه‌ای که بتوان به همهٔ مردم کمبریجِ بریتانیا یک فنجان قهوه داد (دانشجوها خیلی خوشحال می‌شوند).';

  @override
  String get yearlyStats25Slide3Title => 'و تو؟';

  @override
  String yearlyStats25Slide3Subtitle(String brews, String liters) {
    return 'امسال با Timer.Coffee $brews بار قهوه دم کردی. در مجموع $liters لیتر!';
  }

  @override
  String yearlyStats25Slide3TopBadge(int topPct) {
    return 'تو در میان $topPct% برترِ دم‌آورنده‌ها هستی!';
  }

  @override
  String get yearlyStats25Slide4TitleSingle =>
      'یادت هست روزی را که امسال بیشترین قهوه را دم کردی؟';

  @override
  String get yearlyStats25Slide4TitleMulti =>
      'یادت هست روزهایی را که امسال بیشترین قهوه را دم کردی؟';

  @override
  String get yearlyStats25Slide4TitleBrewTime => 'زمان دم‌آوری تو در امسال';

  @override
  String get yearlyStats25Slide4ScratchLabel => 'برای نمایش، خراش بده';

  @override
  String yearlyStats25BrewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بار',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25Slide4PeakSingle(String date, String brewsLabel) {
    return '$date — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4PeakLiters(String liters) {
    return 'آن روز حدود $liters لیتر';
  }

  @override
  String yearlyStats25Slide4PeakMostRecent(
    String mostRecent,
    String brewsLabel,
  ) {
    return 'آخرین مورد: $mostRecent — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4BrewTimeLine(String timeLabel) {
    return 'برای دم‌آوری $timeLabel وقت گذاشتی';
  }

  @override
  String get yearlyStats25Slide4BrewTimeFooter => 'زمانی که ارزشش را داشت';

  @override
  String get yearlyStats25Slide5Title => 'این‌طوری دم می‌کنی';

  @override
  String get yearlyStats25Slide5MethodsHeader => 'روش‌های محبوب:';

  @override
  String get yearlyStats25Slide5NoMethods => 'هنوز روشی نیست';

  @override
  String get yearlyStats25Slide5RecipesHeader => 'بهترین دستورها:';

  @override
  String get yearlyStats25Slide5NoRecipes => 'هنوز دستوری نیست';

  @override
  String yearlyStats25MethodRow(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بار',
    );
    return '$name — $count $_temp0';
  }

  @override
  String yearlyStats25Slide6Title(String count) {
    return 'امسال $count رُستری را کشف کردی:';
  }

  @override
  String get yearlyStats25Slide6NoRoasters => 'هنوز رُستری‌ای نیست';

  @override
  String get yearlyStats25Slide7Title =>
      'قهوه می‌تواند تو را به جاهای مختلف ببرد…';

  @override
  String yearlyStats25Slide7Subtitle(String count) {
    return 'امسال $count خاستگاه را کشف کردی:';
  }

  @override
  String get yearlyStats25Others => '...و بقیه';

  @override
  String yearlyStats25FallbackTitle(int countries, int roasters) {
    return 'کاربران Timer.Coffee امسال از $countries کشور دانه استفاده کردند\nو $roasters رُستری مختلف ثبت کردند.';
  }

  @override
  String get yearlyStats25FallbackPromptHasBeans =>
      'چرا ثبت بسته‌های دانه‌ات را ادامه ندهی؟';

  @override
  String get yearlyStats25FallbackPromptNoBeans =>
      'شاید وقتش است که تو هم بپیوندی و دانه‌هایت را ثبت کنی؟';

  @override
  String get yearlyStats25FallbackActionHasBeans => 'ادامهٔ افزودن دانه‌ها';

  @override
  String get yearlyStats25FallbackActionNoBeans =>
      'اولین بستهٔ دانه‌ات را اضافه کن';

  @override
  String get yearlyStats25ContinueButton => 'ادامه';

  @override
  String get yearlyStats25PostcardTitle =>
      'برای یک دم‌آور دیگر، آرزوی سال نو بفرست.';

  @override
  String get yearlyStats25PostcardSubtitle =>
      'اختیاری. مهربان باش. بدون اطلاعات شخصی.';

  @override
  String get yearlyStats25PostcardHint => 'سال نو مبارک و دم‌آوری‌های عالی!';

  @override
  String get yearlyStats25PostcardSending => 'در حال ارسال...';

  @override
  String get yearlyStats25PostcardSend => 'ارسال';

  @override
  String get yearlyStats25PostcardSkip => 'رد کردن';

  @override
  String get yearlyStats25PostcardReceivedTitle => 'آرزویی از یک دم‌آور دیگر';

  @override
  String get yearlyStats25PostcardErrorLength =>
      'لطفاً ۲–۱۶۰ کاراکتر وارد کنید.';

  @override
  String get yearlyStats25PostcardErrorSend =>
      'ارسال نشد. لطفاً دوباره تلاش کنید.';

  @override
  String get yearlyStats25PostcardErrorRejected =>
      'ارسال نشد. لطفاً پیام دیگری را امتحان کنید.';

  @override
  String get yearlyStats25CtaTitle => 'بیایید در ۲۰۲۶ یک چیز عالی دم کنیم!';

  @override
  String get yearlyStats25CtaSubtitle => 'چند ایده:';

  @override
  String get yearlyStats25CtaExplorePrefix => 'پیشنهادها را در ';

  @override
  String get yearlyStats25CtaGiftBox => 'جعبه هدیه تعطیلات';

  @override
  String get yearlyStats25CtaDonate => 'کمک مالی';

  @override
  String get yearlyStats25CtaDonateSuffix =>
      ' برای کمک به رشد Timer.Coffee در سال آینده';

  @override
  String get yearlyStats25CtaFollowPrefix => 'ما را در ';

  @override
  String get yearlyStats25CtaInstagram => 'Instagram';

  @override
  String get yearlyStats25CtaShareButton => 'پیشرفت من را به اشتراک بگذار';

  @override
  String get yearlyStats25CtaShareHint =>
      'فراموش نکن @timercoffeeapp را تگ کنی';

  @override
  String get yearlyStats25AppBarTooltipResume => 'ادامه';

  @override
  String get yearlyStats25AppBarTooltipPause => 'مکث';

  @override
  String get yearlyStats25ShareError =>
      'امکان اشتراک‌گذاری خلاصه نبود. دوباره تلاش کنید.';

  @override
  String yearlyStats25BrewTimeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقیقه',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25BrewTimeHours(String hours) {
    return '$hours ساعت';
  }

  @override
  String get yearlyStats25ShareTitle => 'سال ۲۰۲۵ من با Timer.Coffee';

  @override
  String get yearlyStats25ShareBrewedPrefix => 'دم‌آوری: ';

  @override
  String get yearlyStats25ShareBrewedMiddle => ' بار · ';

  @override
  String get yearlyStats25ShareBrewedSuffix => ' لیتر قهوه';

  @override
  String get yearlyStats25ShareRoastersPrefix => 'رُستری‌های تجربه‌شده: ';

  @override
  String get yearlyStats25ShareRoastersSuffix => '';

  @override
  String get yearlyStats25ShareOriginsPrefix => 'خاستگاه‌های کشف‌شده: ';

  @override
  String get yearlyStats25ShareOriginsSuffix => '';

  @override
  String get yearlyStats25ShareMethodsTitle => 'روش‌های دم‌آوری محبوب من:';

  @override
  String get yearlyStats25ShareRecipesTitle => 'بهترین دستورهای من:';

  @override
  String get yearlyStats25ShareHandle => '@timercoffeeapp';

  @override
  String get yearlyStatsFailedToLike => 'خطا در ثبت پسندیدن';

  @override
  String get labelCoffeeBrewed => 'قهوه دم‌شده:';

  @override
  String get labelTastedBeansBy => 'رُستری‌های تجربه‌شده:';

  @override
  String get labelDiscoveredCoffeeFrom => 'خاستگاه‌های کشف‌شده:';

  @override
  String get labelUsedBrewingMethods => 'روش‌های دم استفاده‌شده:';

  @override
  String formattedRoasterCount(int count) {
    return '$count رُستری';
  }

  @override
  String formattedCountryCount(int count) {
    return '$count کشور';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    return '$count روش دم‌آوری';
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
  String get recipeCreationScreenBrewingMethodLabel => 'روش دم‌آوری';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'مقدار قهوه';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'مقدار آب';

  @override
  String get recipeCreationScreenWaterTempLabel => 'دمای آب';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'درجه آسیاب';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => 'زمان کل دم‌آوری';

  @override
  String get recipeCreationScreenMinutesLabel => 'دقیقه';

  @override
  String get recipeCreationScreenSecondsLabel => 'ثانیه';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'مرحله آماده‌سازی';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'مرحله دم‌آوری $stepOrder';
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
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'گرم';

  @override
  String get unitMillilitersLong => 'میلی‌لیتر';

  @override
  String get recipeCopySuccess => 'دستور با موفقیت کپی شد';

  @override
  String get recipeDuplicateSuccess => 'کپی دستور با موفقیت ایجاد شد!';

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
  String get defaultPreparationStepDescription => 'آماده‌سازی';

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
  String get dialogDuplicate => 'کپی';

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
    return 'دستورهای زیر به دلیل مسائل پالایش محتوا نیاز به بازبینی دستی دارند: $recipeNames';
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
  String get tooltipDuplicateRecipe => 'کپی گرفتن از دستور';

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
    return 'این دستور به دلیل «$reason» قابل اشتراک‌گذاری نیست.';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'خطا در اشتراک‌گذاری دستور: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName در Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'بررسی وضعیت محتوا ممکن نشد. تغییرات به‌صورت محلی ذخیره شد و در همگام‌سازی بعدی دوباره بررسی می‌شود.';

  @override
  String get saveLocallyModerationFailedTitle =>
      'تغییرات به‌صورت محلی ذخیره شد';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'تغییرات محلی ذخیره شد، اما نسخه عمومی به دلیل پالایش محتوا به‌روزرسانی نشد: $reason';
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
  String get unpublishRecipeDialogTitle => 'خصوصی کردن دستور';

  @override
  String get unpublishRecipeDialogMessage =>
      'هشدار: خصوصی کردن این دستور باعث می‌شود:';

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
  String get recipeUnpublishSuccess => 'انتشار دستور با موفقیت لغو شد';

  @override
  String recipeUnpublishError(String error) {
    return 'خطا در لغو انتشار دستور: $error';
  }

  @override
  String get recipePublicTooltip =>
      'این دستور عمومی است؛ برای خصوصی کردن روی آن بزنید';

  @override
  String get recipePrivateTooltip =>
      'این دستور خصوصی است؛ برای عمومی کردن آن را به اشتراک بگذارید';

  @override
  String get fieldClearButtonTooltip => 'پاک کردن';

  @override
  String get dateFieldClearButtonTooltip => 'پاک کردن تاریخ';

  @override
  String get chipInputDuplicateError => 'این برچسب قبلاً اضافه شده است';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return 'تعداد حداکثر برچسب‌ها رسیده است ($maxChips)';
  }

  @override
  String get chipInputHintText => 'افزودن برچسب...';

  @override
  String get unitFieldRequiredError => 'این فیلد الزامی است';

  @override
  String get unitFieldInvalidNumberError => 'لطفاً یک عدد معتبر وارد کنید';

  @override
  String unitFieldMinValueError(Object min) {
    return 'مقدار باید حداقل $min باشد';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return 'مقدار باید حداکثر $max باشد';
  }

  @override
  String get numericFieldRequiredError => 'این فیلد الزامی است';

  @override
  String get numericFieldInvalidNumberError => 'لطفاً یک عدد معتبر وارد کنید';

  @override
  String numericFieldMinValueError(Object min) {
    return 'مقدار باید حداقل $min باشد';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return 'مقدار باید حداکثر $max باشد';
  }

  @override
  String get dropdownSearchHintText => 'برای جستجو تایپ کنید...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return 'خطا در بارگذاری پیشنهادها: $error';
  }

  @override
  String get dropdownSearchNoResults => 'نتیجه‌ای یافت نشد';

  @override
  String get dropdownSearchLoading => 'در حال جستجو...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return 'استفاده از \"$currentQuery\"';
  }

  @override
  String get requiredInfoSubtitle => '* الزامی';

  @override
  String get inventoryWeightExample => 'مثال: 250.5';

  @override
  String get unsavedChangesTitle => 'تغییرات ذخیره نشده';

  @override
  String get unsavedChangesMessage =>
      'شما تغییرات ذخیره نشده دارید. آیا مطمئن هستید که می‌خواهید آن‌ها را نادیده بگیرید؟';

  @override
  String get unsavedChangesStay => 'بمان';

  @override
  String get unsavedChangesDiscard => 'نادیده گرفتن';

  @override
  String beansWeightAddedBack(
    String amount,
    String beanName,
    String newWeight,
    String unit,
  ) {
    return 'مقدار $amount$unit به $beanName اضافه شد. وزن جدید: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
    String amount,
    String beanName,
    String newWeight,
    String unit,
  ) {
    return 'مقدار $amount$unit از $beanName کم شد. وزن جدید: $newWeight$unit';
  }

  @override
  String get notifications => 'اعلان‌ها';

  @override
  String get notificationsDisabledInSystemSettings =>
      'در تنظیمات سیستم غیرفعال شده';

  @override
  String get openSettings => 'باز کردن تنظیمات';

  @override
  String get couldNotOpenLink => 'باز کردن لینک ممکن نیست';

  @override
  String get notificationsDisabledDialogTitle =>
      'اعلان‌ها در تنظیمات سیستم غیرفعال شده‌اند';

  @override
  String get notificationsDisabledDialogContent =>
      'شما اعلان‌ها را در تنظیمات دستگاه خود غیرفعال کرده‌اید. برای فعال کردن اعلان‌ها، لطفاً تنظیمات دستگاه خود را باز کرده و اعلان‌ها را برای Timer.Coffee مجاز کنید.';

  @override
  String get notificationDebug => 'اشکال‌زدایی اعلان‌ها';

  @override
  String get testNotificationSystem => 'تست سیستم اعلان‌ها';

  @override
  String get notificationsEnabled => 'فعال';

  @override
  String get notificationsDisabled => 'غیرفعال';

  @override
  String get notificationPermissionDialogTitle => 'فعال کردن اعلان‌ها؟';

  @override
  String get notificationPermissionDialogMessage =>
      'می‌توانید اعلان‌ها را فعال کنید تا به‌روزرسانی‌های مفید (مثلاً در مورد نسخه‌های جدید برنامه) دریافت کنید. اعلان‌ها همچنین برای به‌روزرسانی زندهٔ پیشرفت دم‌آوری لازم هستند. اکنون فعال کنید یا هر زمان در تنظیمات تغییر دهید.';

  @override
  String get notificationPermissionDialogMessageIos =>
      'می‌توانید اعلان‌ها را فعال کنید تا به‌روزرسانی‌های مفید (مثلاً در مورد نسخه‌های جدید برنامه) دریافت کنید. اعلان‌ها همچنین برای Live Activities و Dynamic Island در iOS لازم هستند. اکنون فعال کنید یا هر زمان در تنظیمات تغییر دهید.';

  @override
  String get notificationPermissionDialogMessageAndroid =>
      'می‌توانید اعلان‌ها را فعال کنید تا به‌روزرسانی‌های مفید (مثلاً در مورد نسخه‌های جدید برنامه) دریافت کنید. اعلان‌ها همچنین برای Live Updates در Android لازم هستند. اکنون فعال کنید یا هر زمان در تنظیمات تغییر دهید.';

  @override
  String get notificationPermissionEnable => 'فعال کردن';

  @override
  String get notificationPermissionSkip => 'اکنون نه';

  @override
  String get holidayGiftBoxTitle => 'جعبه هدیه تعطیلات';

  @override
  String get holidayGiftBoxInfoTrigger => 'این چیست؟';

  @override
  String get holidayGiftBoxInfoBody =>
      'پیشنهادهای فصلی انتخاب‌شده از شرکا. لینک‌ها وابسته نیستند - هدف ما فقط این است که در این تعطیلات کمی خوشحالی به کاربران Timer.Coffee هدیه بدهیم. برای به‌روزرسانی به پایین بکشید.';

  @override
  String get holidayGiftBoxNoOffers => 'در حال حاضر پیشنهادی موجود نیست.';

  @override
  String get holidayGiftBoxNoOffersSub =>
      'برای به‌روزرسانی بکشید یا بعداً دوباره امتحان کنید.';

  @override
  String holidayGiftBoxShowingRegion(String region) {
    return 'نمایش پیشنهادها برای $region';
  }

  @override
  String get holidayGiftBoxViewDetails => 'مشاهده جزئیات';

  @override
  String get holidayGiftBoxPromoCopied => 'کد تخفیف کپی شد';

  @override
  String get holidayGiftBoxPromoCode => 'کد تخفیف';

  @override
  String giftDiscountOff(String percent) {
    return '$percent٪ تخفیف';
  }

  @override
  String giftDiscountUpToOff(String percent) {
    return 'تا $percent٪ تخفیف';
  }

  @override
  String get holidayGiftBoxTerms => 'شرایط و ضوابط';

  @override
  String get holidayGiftBoxVisitSite => 'مشاهده وب‌سایت شریک';

  @override
  String holidayGiftBoxValidUntil(String date) {
    return 'معتبر تا $date';
  }

  @override
  String holidayGiftBoxEndsInDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'تا $days روز دیگر تمام می‌شود',
      one: 'فردا تمام می‌شود',
      zero: 'امروز تمام می‌شود',
    );
    return '$_temp0';
  }

  @override
  String get holidayGiftBoxValidWhileAvailable => 'معتبر تا زمان موجود بودن';

  @override
  String holidayGiftBoxUpdated(String date) {
    return 'به‌روزرسانی شده در $date';
  }

  @override
  String holidayGiftBoxLanguage(String language) {
    return 'زبان: $language';
  }

  @override
  String get holidayGiftBoxRetry => 'تلاش مجدد';

  @override
  String get holidayGiftBoxLoadFailed => 'بارگذاری پیشنهادها ناموفق بود';

  @override
  String get holidayGiftBoxOfferUnavailable => 'پیشنهاد در دسترس نیست';

  @override
  String get holidayGiftBoxBannerTitle => 'جعبه هدیه تعطیلات ما را ببینید';

  @override
  String get holidayGiftBoxBannerCta => 'مشاهده پیشنهادها';

  @override
  String get regionEurope => 'اروپا';

  @override
  String get regionNorthAmerica => 'آمریکای شمالی';

  @override
  String get regionAsia => 'آسیا';

  @override
  String get regionAustralia => 'استرالیا / اقیانوسیه';

  @override
  String get regionWorldwide => 'سراسر جهان';

  @override
  String get regionAfrica => 'آفریقا';

  @override
  String get regionMiddleEast => 'خاورمیانه';

  @override
  String get regionSouthAmerica => 'آمریکای جنوبی';

  @override
  String get setToZeroButton => 'تنظیم روی صفر';

  @override
  String get setToZeroDialogTitle => 'موجودی را روی صفر تنظیم کنیم؟';

  @override
  String get setToZeroDialogBody =>
      'این کار مقدار باقی‌مانده را روی ۰ گرم تنظیم می‌کند. بعداً می‌توانید آن را ویرایش کنید.';

  @override
  String get setToZeroDialogConfirm => 'تنظیم روی صفر';

  @override
  String get setToZeroDialogCancel => 'انصراف';

  @override
  String get inventorySetToZeroSuccess => 'موجودی روی ۰ گرم تنظیم شد';

  @override
  String get inventorySetToZeroFail => 'تنظیم موجودی روی صفر ناموفق بود';

  @override
  String get timePeriodThisYear => 'امسال';

  @override
  String get timePeriodLastYear => 'سال گذشته';

  @override
  String get nativeAppPromoTitle => 'اپلیکیشن Timer.Coffee را دانلود کنید';

  @override
  String get nativeAppPromoDescription =>
      'از تجربه کامل با ویژگی‌های انحصاری لذت ببرید: اسکن برچسب قهوه با هوش مصنوعی، فعالیت‌های زنده روی صفحه قفل، اعلان‌های فوری، بازخورد لمسی و موارد بیشتر.';

  @override
  String get nativeAppPromoButton => 'دانلود اپلیکیشن';

  @override
  String get addBrewEntry => 'افزودن ثبت دم‌آوری';

  @override
  String get selectBrewingMethod => 'انتخاب روش دم‌آوری';

  @override
  String get selectRecipe => 'انتخاب دستور';

  @override
  String get brewDate => 'تاریخ';

  @override
  String get brewTime => 'زمان';

  @override
  String get brewEntrySaved => 'ثبت دم‌آوری ذخیره شد';

  @override
  String get brewingMethodRequired => 'لطفاً یک روش دم‌آوری انتخاب کنید';

  @override
  String get recipeRequired => 'لطفاً یک دستور انتخاب کنید';

  @override
  String get onboardingTitle => 'به Timer.Coffee خوش آمدید';

  @override
  String get onboardingSubtitle => 'قهوه‌تان را با چه روشی دم می‌کنید؟';

  @override
  String get onboardingShowAll => 'نمایش همه روش‌های دم‌آوری';

  @override
  String get coffeeJourneyTitle => 'قدم‌های اول';

  @override
  String get coffeeJourneyMilestoneFirstBrew =>
      'اولین دم‌آوری‌تان را کامل کنید';

  @override
  String get coffeeJourneyMilestoneTryMethod => 'یک دستور دیگر را امتحان کنید';

  @override
  String get coffeeJourneyMilestoneAddBeans =>
      'اولین دانه‌های قهوه‌تان را اضافه کنید';

  @override
  String get coffeeJourneyMilestoneFavorite =>
      'یک دستور را به موردعلاقه‌ها اضافه کنید';

  @override
  String get coffeeJourneyMilestoneStats => 'آمار دم‌آوری‌تان را ببینید';

  @override
  String get coffeeJourneyMilestonePulse =>
      'ببینید دنیا همراه شما چگونه قهوه دم می‌کند';

  @override
  String get coffeeJourneyCompleted => 'قدم‌های اول را کامل کردید!';

  @override
  String get coffeeJourneyDoneButton => 'تمام';

  @override
  String get coffeeJourneyDismissHint =>
      'همیشه می‌توانید پیشرفتتان را در تب بیشتر ببینید.';

  @override
  String get coffeeJourneyDismissConfirm =>
      'می‌خواهید پیشرفتتان در بخش قدم‌های اول را پنهان کنید؟';

  @override
  String get coffeeJourneyHideButton => 'پنهان کن';

  @override
  String get firstBrewCongrats =>
      'اولین دم‌آوری‌تان مبارک! در دفترچه دم‌آوری ذخیره شد.';

  @override
  String get firstBrewDiaryLink => 'مشاهده دفترچه دم‌آوری';

  @override
  String get beanCoverPhoto => 'عکس کاور';

  @override
  String get beanCoverPhotoAdd => 'افزودن عکس کاور';

  @override
  String get beanCoverPhotoChange => 'تغییر عکس';

  @override
  String get beanCoverPhotoRemove => 'حذف عکس';

  @override
  String get beanCoverPhotoSavePromptTitle => 'به‌عنوان عکس کاور استفاده شود؟';

  @override
  String get beanCoverPhotoSavePromptBody =>
      'مایلید یکی از تصاویر اسکن‌شده را به‌عنوان عکس کاور این دانه ذخیره کنید؟';

  @override
  String get beanCoverPhotoUploading => 'در حال بارگذاری عکس…';

  @override
  String get beanCoverPhotoError => 'بارگذاری عکس ناموفق بود';

  @override
  String get beanCoverPhotoSignInPrompt => 'برای افزودن عکس کاور وارد شوید';

  @override
  String get settingsAnalyticsTitle => 'حریم خصوصی و تحلیل‌ها';

  @override
  String get settingsAnalyticsBrews => 'اشتراک‌گذاری تحلیل‌های دم‌آوری';

  @override
  String get settingsAnalyticsBeans => 'اشتراک‌گذاری تحلیل‌های دانه';

  @override
  String get settingsAnalyticsGeneral => 'اشتراک‌گذاری تحلیل‌های کلی استفاده';

  @override
  String get done => 'تمام';

  @override
  String get saving => 'در حال ذخیره…';

  @override
  String get notifBrewReminderTitle => 'دلت برای قهوه‌ات تنگ شده؟';

  @override
  String get notifBrewReminderBody =>
      'چند روزی گذشته. آماده‌ای یک فنجان دیگر دم کنی؟';

  @override
  String get notifBrewReminderTitle2 => 'وقت قهوه است؟';

  @override
  String get notifBrewReminderBody2 => 'ابزارهایت هر وقت بخواهی آماده‌اند.';

  @override
  String get notifBrewReminderTitle3 => 'کتری صدایت می‌کند';

  @override
  String get notifBrewReminderBody3 =>
      'تا یک فنجان خوب فقط چند دقیقه مانده است.';

  @override
  String get notifBrewEscalationTitle => 'برای یک فنجان دیگر برگشتی؟';

  @override
  String get notifBrewEscalationBody =>
      'مدتی گذشته. آماده‌ای چیزی خوب درست کنی؟';

  @override
  String get notifBrewEscalationTitle2 => 'مدتی گذشته؟';

  @override
  String get notifBrewEscalationBody2 =>
      'عجله‌ای نیست. ابزارت هر وقت آماده باشی، آماده است.';

  @override
  String get notifBrewEscalationTitle3 => 'دوباره وقت قهوه است؟';

  @override
  String get notifBrewEscalationBody3 =>
      'یک فنجان واقعاً خوب می‌تواند فقط در چند دقیقه آماده شود.';

  @override
  String get notifDiscoverBeansTitle => 'حواست به دانه‌هایت باشد';

  @override
  String get notifDiscoverBeansBody =>
      'دانه‌هایت را ثبت کن و آن‌هایی را که دوست داشتی به خاطر بسپار.';

  @override
  String get notifDiscoverPulseTitle => 'ببین دیگران چه چیزی دم می‌کنند';

  @override
  String get notifDiscoverPulseBody =>
      'نبض را باز کن تا دم‌آوری‌های زنده از سراسر جهان را ببینی.';

  @override
  String get notifBrewMilestoneTitle => 'به یک رکورد جدید رسیدی';

  @override
  String notifBrewMilestoneBody(int count) {
    return 'تا حالا $count بار دم‌آوری کرده‌ای. برای دیدن پیشرفتت ضربه بزن.';
  }

  @override
  String notifExploreRecipesTitle(String methodName) {
    return 'یک دستور $methodName جدید امتحان کن';
  }

  @override
  String notifExploreRecipesBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تا الان $count دستور را امتحان کرده‌ای. این یکی را هم امتحان کن.',
      one: 'تا الان ۱ دستور را امتحان کرده‌ای. این یکی را هم امتحان کن.',
    );
    return '$_temp0';
  }

  @override
  String get notifMorningTitle => 'صبح بخیر. آماده‌ای قهوه دم کنی؟';

  @override
  String get notifMorningBody => 'روزت را با یک فنجان خوب شروع کن.';

  @override
  String get notifMorningTitle2 => 'بیدار شو و دم کن';

  @override
  String get notifMorningBody2 =>
      'قهوه صبحگاهی‌ات می‌تواند در چند دقیقه آماده شود.';

  @override
  String get notifMorningTitle3 => 'اولین فنجان امروز؟';

  @override
  String get notifMorningBody3 => 'یک دستور انتخاب کن و شروع به دم‌آوری کن.';

  @override
  String notifWeeklyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دم‌آوری این هفته',
      one: '۱ دم‌آوری این هفته',
    );
    return '$_temp0';
  }

  @override
  String notifWeeklyBody(int recipes) {
    String _temp0 = intl.Intl.pluralLogic(
      recipes,
      locale: localeName,
      other: 'نتیجه‌ی $recipes دستور است. برای دیدن جزئیات ضربه بزن.',
      one: 'برای دیدن آمار هفتگی‌ات ضربه بزن.',
    );
    return '$_temp0';
  }

  @override
  String get notifBeanFreshnessTitle => 'وقت دانه‌های تازه رسیده؟';

  @override
  String notifBeanFreshnessBody(String beanName, int days) {
    return '$beanName $days روز پیش رست شده است. ممکن است از بهترین زمانش گذشته باشد.';
  }

  @override
  String get settingsNotificationsToggle => 'فعال کردن اعلان‌ها';

  @override
  String get settingsMorningReminder => 'یادآور دم‌آوری صبحگاهی';

  @override
  String get settingsMorningReminderSubtitle =>
      'یادآور روزانه برای قهوه صبحگاهی‌ات';

  @override
  String get settingsMorningReminderTime => 'زمان یادآور';

  @override
  String get settingsWeeklySummary => 'خلاصه هفتگی';

  @override
  String get settingsWeeklySummarySubtitle =>
      'مرور دم‌آوری‌های هفته در یکشنبه شب';

  @override
  String get settingsBeanFreshness => 'هشدار تازگی دانه‌ها';

  @override
  String get settingsBeanFreshnessSubtitle =>
      'وقتی بیش از ۳ هفته از تاریخ رست گذشته باشد اطلاع بده';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count روز پیش',
    );
    return '$_temp0';
  }
}
