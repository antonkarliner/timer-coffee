// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'إحصائيات الحبوب';

  @override
  String get totalBeansBrewedLabel => 'إجمالي الحبوب المُحضرة';

  @override
  String get newBeansTriedLabel => 'حبوب جديدة مجرّبة';

  @override
  String get originsExploredLabel => 'المناشئ المستكشفة';

  @override
  String get regionsExploredLabel => 'المناطق المستكشفة';

  @override
  String get newRoastersDiscoveredLabel => 'محامص جديدة مُكتشفة';

  @override
  String get favoriteRoastersLabel => 'المحامص المفضلة';

  @override
  String get topOriginsLabel => 'أفضل المناشئ';

  @override
  String get topRegionsLabel => 'أفضل المناطق';

  @override
  String get lastrecipe => 'أحدث وصفة مستخدمة:';

  @override
  String get userRecipesTitle => 'وصفاتك';

  @override
  String get userRecipesSectionCreated => 'منشأة بواسطتك';

  @override
  String get userRecipesSectionImported => 'مستوردة بواسطتك';

  @override
  String get userRecipesEmpty => 'لا توجد وصفات';

  @override
  String get userRecipesDeleteTitle => 'حذف الوصفة؟';

  @override
  String get userRecipesDeleteMessage => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get userRecipesDeleteConfirm => 'حذف';

  @override
  String get userRecipesDeleteCancel => 'إلغاء';

  @override
  String get userRecipesSnackbarDeleted => 'تم حذف الوصفة';

  @override
  String get hubUserRecipesTitle => 'وصفاتك';

  @override
  String get hubUserRecipesSubtitle => 'عرض وإدارة الوصفات المنشأة والمستوردة';

  @override
  String get hubAccountSubtitle => 'إدارة ملفك الشخصي';

  @override
  String get hubSignInCreateSubtitle =>
      'قم بتسجيل الدخول لمزامنة الوصفات والتفضيلات';

  @override
  String get hubBrewDiarySubtitle => 'عرض سجل التحضير وإضافة ملاحظات';

  @override
  String get hubBrewStatsSubtitle =>
      'عرض الإحصائيات والاتجاهات الشخصية والعالمية للتحضير';

  @override
  String get hubSettingsSubtitle => 'تغيير تفضيلات وسلوك التطبيق';

  @override
  String get hubAboutSubtitle => 'تفاصيل التطبيق والإصدار والمساهمون';

  @override
  String get about => 'حول';

  @override
  String get author => 'المؤلف';

  @override
  String get authortext =>
      'تم إنشاء تطبيق Timer.Coffee بواسطة أنتون كارلينر، وهو محب للقهوة ومتخصص في الإعلام وصحفي. أتمنى أن يساعدك هذا التطبيق في الاستمتاع بقهوتك. لا تتردد في المساهمة على GitHub.';

  @override
  String get contributors => 'المساهمون';

  @override
  String get errorLoadingContributors => 'خطأ في تحميل المساهمين';

  @override
  String get license => 'الترخيص';

  @override
  String get licensetext =>
      'هذا التطبيق هو برنامج مجاني: يمكنك إعادة توزيعه و/أو تعديله تحت شروط رخصة جنو العمومية كما نشرتها مؤسسة البرمجيات الحرة، سواء الإصدار 3 من الترخيص، أو (حسب اختيارك) أي إصدار لاحق.';

  @override
  String get licensebutton => 'اقرأ رخصة جنو العمومية الإصدار 3';

  @override
  String get website => 'الموقع الإلكتروني';

  @override
  String get sourcecode => 'شيفرة المصدر';

  @override
  String get support => 'اشترِ قهوة للمطور';

  @override
  String get allrecipes => 'جميع الوصفات';

  @override
  String get favoriterecipes => 'الوصفات المفضلة';

  @override
  String get coffeeamount => 'كمية القهوة (غ)';

  @override
  String get wateramount => 'كمية الماء (مل)';

  @override
  String get watertemp => 'درجة حرارة الماء';

  @override
  String get grindsize => 'حجم الطحن';

  @override
  String get brewtime => 'وقت التحضير';

  @override
  String get recipesummary => 'ملخص الوصفة';

  @override
  String get recipesummarynote =>
      'ملاحظة: هذه وصفة أساسية بكميات ماء وقهوة افتراضية.';

  @override
  String get preparation => 'التحضير';

  @override
  String get brewingprocess => 'عملية التخمير';

  @override
  String get step => 'خطوة';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ثواني',
      one: 'ثانية',
      zero: 'ثواني',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg => 'شكرًا لاستخدامك Timer.Coffee! استمتع بـ';

  @override
  String get coffeefact => 'حقيقة عن القهوة';

  @override
  String get home => 'الصفحة الرئيسية';

  @override
  String get appversion => 'إصدار التطبيق';

  @override
  String get tipsmall => 'شراء قهوة صغيرة';

  @override
  String get tipmedium => 'شراء قهوة متوسطة';

  @override
  String get tiplarge => 'شراء قهوة كبيرة';

  @override
  String get supportdevelopment => 'دعم التطوير';

  @override
  String get supportdevmsg =>
      'تساعد تبرعاتك في تغطية تكاليف الصيانة (مثل تراخيص المطورين، على سبيل المثال). كما تتيح لي تجربة المزيد من أجهزة تحضير القهوة وإضافة المزيد من الوصفات إلى التطبيق.';

  @override
  String get supportdevtnx => 'شكرًا لتفكيرك في التبرع!';

  @override
  String get donationok => 'شكرًا لك!';

  @override
  String get donationtnx =>
      'أقدر دعمك كثيرًا! أتمنى لك الكثير من الإعدادات الرائعة! ☕️';

  @override
  String get donationerr => 'خطأ';

  @override
  String get donationerrmsg =>
      'خطأ في معالجة الشراء، الرجاء المحاولة مرة أخرى.';

  @override
  String get sharemsg => 'تحقق من هذه الوصفة:';

  @override
  String get finishbrew => 'انتهاء';

  @override
  String get settings => 'الإعدادات';

  @override
  String get settingstheme => 'الثيم';

  @override
  String get settingsthemelight => 'فاتح';

  @override
  String get settingsthemedark => 'داكن';

  @override
  String get settingsthemesystem => 'النظام';

  @override
  String get settingslang => 'اللغة';

  @override
  String get sweet => 'حلو';

  @override
  String get balance => 'توازن';

  @override
  String get acidic => 'حمضي';

  @override
  String get light => 'خفيف';

  @override
  String get strong => 'قوي';

  @override
  String get slidertitle => 'استخدم المنزلقات لضبط الطعم';

  @override
  String get whatsnewtitle => 'ما الجديد';

  @override
  String get whatsnewclose => 'أغلق';

  @override
  String get seasonspecials => 'عروض المواسم الخاصة';

  @override
  String get snow => 'ثلج';

  @override
  String get noFavoriteRecipesMessage =>
      'قائمة وصفاتك المفضلة فارغة حاليًا. ابدأ الاستكشاف والتحضير لاكتشاف المفضلة لديك!';

  @override
  String get explore => 'استكشاف';

  @override
  String get dateFormat => 'd MMM، yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'يوميات القهوة';

  @override
  String get brewdiarynotfound => 'لم يتم العثور على مداخلات';

  @override
  String get beans => 'حبوب';

  @override
  String get roaster => 'المحمصة';

  @override
  String get rating => 'التقييم';

  @override
  String get notes => 'ملاحظات';

  @override
  String get statsscreen => 'إحصائيات القهوة';

  @override
  String get yourStats => 'إحصائياتك';

  @override
  String get coffeeBrewed => 'القهوة المُحضرة:';

  @override
  String get litersUnit => 'لتر';

  @override
  String get mostUsedRecipes => 'وصفات القهوة الأكثر استخدامًا:';

  @override
  String get globalStats => 'إحصائيات عامة';

  @override
  String get unknownRecipe => 'وصفة غير معروفة';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String error(Object error) {
    return 'خطأ: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'قام أحدهم بتحضير $recipeName للتو';
  }

  @override
  String get timePeriodToday => 'اليوم';

  @override
  String get timePeriodThisWeek => 'هذا الأسبوع';

  @override
  String get timePeriodThisMonth => 'هذا الشهر';

  @override
  String get timePeriodCustom => 'مخصصة';

  @override
  String get statsFor => 'إحصائيات لـ ';

  @override
  String get homescreenbrewcoffee => 'تحضير القهوة';

  @override
  String get homescreenhub => 'المحور';

  @override
  String get homescreenmore => 'المزيد';

  @override
  String get addBeans => 'أضف حبوبًا';

  @override
  String get removeBeans => 'أزل حبوبًا';

  @override
  String get name => 'الاسم';

  @override
  String get origin => 'المنشأ';

  @override
  String get details => 'التفاصيل';

  @override
  String get coffeebeans => 'حبوب البن';

  @override
  String get loading => 'جارٍ التحميل';

  @override
  String get nocoffeebeans => 'لم يتم العثور على حبوب البن';

  @override
  String get delete => 'حذف';

  @override
  String get confirmDeleteTitle => 'حذف الإدخال؟';

  @override
  String get confirmDeleteMessage =>
      'هل أنت متأكد أنك تريد حذف هذا الإدخال؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get removeFavorite => 'إزالة من المفضلة';

  @override
  String get addFavorite => 'إضافة إلى المفضلة';

  @override
  String get toggleEditMode => 'تبديل وضع التحرير';

  @override
  String get coffeeBeansDetails => 'تفاصيل حبوب البن';

  @override
  String get edit => 'تعديل';

  @override
  String get coffeeBeansNotFound => 'لم يتم العثور على حبوب البن';

  @override
  String get basicInformation => 'المعلومات الأساسية';

  @override
  String get geographyTerroir => 'الجغرافيا / المنشأ';

  @override
  String get variety => 'الصنف';

  @override
  String get region => 'المنطقة';

  @override
  String get elevation => 'الارتفاع';

  @override
  String get harvestDate => 'تاريخ الحصاد';

  @override
  String get processing => 'المعالجة';

  @override
  String get processingMethod => 'طريقة المعالجة';

  @override
  String get roastDate => 'تاريخ التحميص';

  @override
  String get roastLevel => 'درجة التحميص';

  @override
  String get cuppingScore => 'درجة التقييم';

  @override
  String get flavorProfile => 'نكهة';

  @override
  String get tastingNotes => 'ملاحظات التذوق';

  @override
  String get additionalNotes => 'ملاحظات إضافية';

  @override
  String get noCoffeeBeans => 'لم يتم العثور على حبوب البن';

  @override
  String get editCoffeeBeans => 'تعديل حبوب البن';

  @override
  String get addCoffeeBeans => 'إضافة حبوب البن';

  @override
  String get showImagePicker => 'إظهار منتقي الصور';

  @override
  String get pleaseNote => 'يرجى الملاحظة';

  @override
  String get firstTimePopupMessage =>
      '1. نستخدم خدمات خارجية لمعالجة الصور. بالموافقة، أنت توافق على ذلك.\n2. على الرغم من أننا لا نقوم بتخزين صورك، يرجى تجنب تضمين أي تفاصيل شخصية.\n3. يقتصر التعرف على الصور حاليًا على 10 رموز مميزة شهريًا (رمز مميز واحد = صورة واحدة). قد يتغير هذا الحد في المستقبل.';

  @override
  String get ok => 'موافق';

  @override
  String get takePhoto => 'التقط صورة';

  @override
  String get selectFromPhotos => 'اختر من الصور';

  @override
  String get takeAdditionalPhoto => 'هل تريد التقاط صورة إضافية؟';

  @override
  String get no => 'لا';

  @override
  String get yes => 'نعم';

  @override
  String get selectedImages => 'الصور المحددة';

  @override
  String get selectedImage => 'الصورة المحددة';

  @override
  String get backToSelection => 'الرجوع إلى التحديد';

  @override
  String get next => 'التالي';

  @override
  String get unexpectedErrorOccurred => 'حدث خطأ غير متوقع';

  @override
  String get tokenLimitReached =>
      'عذرًا، لقد وصلت إلى الحد الأقصى من الرموز المميزة للتعرف على الصور لهذا الشهر';

  @override
  String get noCoffeeLabelsDetected =>
      'لم يتم اكتشاف ملصقات القهوة. حاول استخدام صورة أخرى.';

  @override
  String get collectedInformation => 'المعلومات التي تم جمعها';

  @override
  String get enterRoaster => 'أدخل اسم المحمصة';

  @override
  String get enterName => 'أدخل الاسم';

  @override
  String get enterOrigin => 'أدخل المنشأ';

  @override
  String get optional => 'اختياري';

  @override
  String get enterVariety => 'أدخل الصنف';

  @override
  String get enterProcessingMethod => 'أدخل طريقة المعالجة';

  @override
  String get enterRoastLevel => 'أدخل درجة التحميص';

  @override
  String get enterRegion => 'أدخل المنطقة';

  @override
  String get enterTastingNotes => 'أدخل ملاحظات التذوق';

  @override
  String get enterElevation => 'أدخل الارتفاع';

  @override
  String get enterCuppingScore => 'أدخل درجة التقييم';

  @override
  String get enterNotes => 'أدخل الملاحظات';

  @override
  String get inventory => 'المخزون';

  @override
  String get amountLeft => 'الكمية المتبقية';

  @override
  String get enterAmountLeft => 'أدخل الكمية المتبقية';

  @override
  String get selectHarvestDate => 'حدد تاريخ الحصاد';

  @override
  String get selectRoastDate => 'حدد تاريخ التحميص';

  @override
  String get selectDate => 'حدد التاريخ';

  @override
  String get save => 'حفظ';

  @override
  String get fillRequiredFields => 'يرجى ملء جميع الحقول المطلوبة.';

  @override
  String get analyzing => 'جاري التحليل';

  @override
  String get errorMessage => 'خطأ';

  @override
  String get selectCoffeeBeans => 'حدد حبوب البن';

  @override
  String get addNewBeans => 'إضافة حبوب جديدة';

  @override
  String get favorite => 'مُفضّل';

  @override
  String get notFavorite => 'غير مُفضّل';

  @override
  String get myBeans => 'حبوب البن الخاصة بي';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signInWithApple => 'تسجيل الدخول باستخدام Apple';

  @override
  String get signInSuccessful => 'تم تسجيل الدخول بنجاح باستخدام Apple';

  @override
  String get signInError => 'خطأ في تسجيل الدخول باستخدام Apple';

  @override
  String get signInWithGoogle => 'تسجيل الدخول باستخدام جوجل';

  @override
  String get signOutSuccessful => 'تم تسجيل الخروج بنجاح';

  @override
  String get signInSuccessfulGoogle => 'تم تسجيل الدخول بنجاح باستخدام جوجل';

  @override
  String get signInWithEmail => 'تسجيل الدخول باستخدام البريد الإلكتروني';

  @override
  String get enterEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get cancel => 'إلغاء';

  @override
  String get sendMagicLink => 'إرسال رابط سحري';

  @override
  String get magicLinkSent => 'تم إرسال رابط سحري! راجع بريدك الإلكتروني.';

  @override
  String get sendOTP => 'أرسل OTP';

  @override
  String get otpSent => 'تم إرسال OTP إلى بريدك الإلكتروني';

  @override
  String get otpSendError => 'خطأ في إرسال OTP';

  @override
  String get enterOTP => 'أدخل OTP';

  @override
  String get otpHint => 'ادخل الكود المكون من 6 أرقام';

  @override
  String get verify => 'التحقق';

  @override
  String get signInSuccessfulEmail => 'تم تسجيل الدخول بنجاح';

  @override
  String get invalidOTP => 'OTP غير صالح';

  @override
  String get otpVerificationError => 'خطأ في التحقق من OTP';

  @override
  String get success => 'نجاح!';

  @override
  String get otpSentMessage =>
      'تم إرسال رمز لمرة واحدة إلى بريدك الإلكتروني. يُرجى إدخاله أدناه عند استلامه.';

  @override
  String get otpHint2 => 'أدخل الرمز هنا';

  @override
  String get signInCreate => 'تسجيل الدخول / إنشاء حساب';

  @override
  String get accountManagement => 'إدارة الحساب';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountWarning =>
      'يرجى ملاحظة: إذا اخترت المتابعة ، فسنقوم بحذف حسابك والبيانات ذات الصلة من خوادمنا. ستظل النسخة المحلية من البيانات على الجهاز ، إذا كنت تريد حذفها أيضًا ، يمكنك ببساطة حذف التطبيق. لإعادة تمكين المزامنة ، ستحتاج إلى إنشاء حساب مرة أخرى';

  @override
  String get deleteAccountConfirmation => 'تم حذف الحساب بنجاح';

  @override
  String get accountDeleted => 'تم حذف الحساب';

  @override
  String get accountDeletionError =>
      'حدث خطأ أثناء حذف حسابك ، يرجى المحاولة مرة أخرى';

  @override
  String get deleteAccountTitle => 'مهم';

  @override
  String get selectBeans => 'اختيار حبوب البن';

  @override
  String get all => 'الكل';

  @override
  String get selectRoaster => 'اختر المحمص';

  @override
  String get selectOrigin => 'اختر المنشأ';

  @override
  String get resetFilters => 'إعادة ضبط الفلاتر';

  @override
  String get showFavoritesOnly => 'إظهار المفضلة فقط';

  @override
  String get apply => 'تطبيق';

  @override
  String get selectSize => 'حدد الحجم';

  @override
  String get sizeStandard => 'قياسي';

  @override
  String get sizeMedium => 'متوسط';

  @override
  String get sizeXL => 'كبير جدًا';

  @override
  String get yearlyStatsAppBarTitle => 'عامي مع Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      'مرحبًا، شكرًا لكونك جزءًا من عالم Timer.Coffee هذا العام!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'أولاً وقبل كل شيء،\nلقد قمت بتحضير بعض القهوة هذا العام$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'على وجه الدقة،\nلقد قمت بتحضير $liters لترًا من القهوة في عام 2024!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'لقد استخدمت حبوبًا من $roasterCount من محمصات القهوة';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'كانت أفضل 3 محمصات لديك هي:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'أخذتك القهوة في رحلة\nحول العالم$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'لقد تذوقت حبوب البن\nمن $originCount دولة!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'لم تكن تقوم بتخمير القهوة بمفردك…';

  @override
  String get yearlyStatsStory7Part2 =>
      '…بل مع مستخدمين من 110 دولة أخرى\nعبر 6 قارات!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'لقد ظللت وفيًا لنفسك واستخدمت فقط طرق التخمير هذه $count هذا العام:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'كنت تكتشف أذواقًا جديدة واستخدمت $count من طرق التخمير هذا العام:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'لقد كنت مكتشفًا حقيقيًا للقهوة واستخدمت $count من طرق التخمير هذا العام:';
  }

  @override
  String get yearlyStatsStory9Text => 'الكثير لاكتشافه!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return 'كانت أفضل 3 وصفات لديك في عام 2024 هي$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'أراك في عام 2025!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'أظهر بعض الحب ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'تبرع';

  @override
  String get yearlyStatsActionShare => 'شارك تقدمك';

  @override
  String get yearlyStatsUnknown => 'غير معروف';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'فشل المشاركة: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'عامي مع Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes => 'أفضل 3 وصفات:';

  @override
  String get yearlyStatsShareProgressTop3Roasters => 'أفضل 3 محامص:';

  @override
  String get yearlyStatsFailedToLike => 'تعذر الإعجاب. يرجى إعادة المحاولة.';

  @override
  String get labelCoffeeBrewed => 'تم تحضير القهوة';

  @override
  String get labelTastedBeansBy => 'تم تذوق حبوب البن من';

  @override
  String get labelDiscoveredCoffeeFrom => 'تم اكتشاف القهوة من';

  @override
  String get labelUsedBrewingMethods => 'تم استخدام';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'محمصة',
      many: 'محمصة',
      few: 'محامص',
      two: 'محمصتان',
      one: 'محمصة',
      zero: 'محمصة',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'دولة',
      many: 'دولة',
      few: 'دول',
      two: 'دولتان',
      one: 'دولة',
      zero: 'دولة',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'طريقة تحضير',
      many: 'طريقة تحضير',
      few: 'طرق تحضير',
      two: 'طريقتا تحضير',
      one: 'طريقة تحضير',
      zero: 'طريقة تحضير',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'تعديل الوصفة';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'إنشاء وصفة';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'خطوات الوصفة';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'اسم الوصفة';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'وصف قصير';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'طريقة التحضير';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'كمية القهوة (غ)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'كمية الماء (مل)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'درجة حرارة الماء (°م)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'حجم الطحن';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => 'إجمالي وقت التحضير:';

  @override
  String get recipeCreationScreenMinutesLabel => 'دقائق';

  @override
  String get recipeCreationScreenSecondsLabel => 'ثواني';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'خطوة التحضير';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'خطوة التحضير $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'وصف الخطوة';

  @override
  String get recipeCreationScreenStepTimeLabel => 'وقت الخطوة: ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'الرجاء إدخال اسم للوصفة';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'الرجاء إدخال وصف قصير';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'الرجاء اختيار طريقة التحضير';

  @override
  String get recipeCreationScreenRequiredValidator => 'مطلوب';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'رقم غير صالح';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'الرجاء إدخال وصف للخطوة';

  @override
  String get recipeCreationScreenContinueButton => 'متابعة إلى خطوات الوصفة';

  @override
  String get recipeCreationScreenAddStepButton => 'إضافة خطوة';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'حفظ الوصفة';

  @override
  String get recipeCreationScreenUpdateSuccess => 'تم تحديث الوصفة بنجاح';

  @override
  String get recipeCreationScreenSaveSuccess => 'تم حفظ الوصفة بنجاح';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'خطأ في حفظ الوصفة: $error';
  }

  @override
  String get unitGramsShort => 'غ';

  @override
  String get unitMillilitersShort => 'مل';

  @override
  String get unitGramsLong => 'جرامات';

  @override
  String get unitMillilitersLong => 'ملليلتر';

  @override
  String get recipeCopySuccess => 'تم نسخ الوصفة بنجاح!';

  @override
  String recipeCopyError(String error) {
    return 'خطأ في نسخ الوصفة: $error';
  }

  @override
  String get createRecipe => 'إنشاء وصفة';

  @override
  String errorSyncingData(Object error) {
    return 'خطأ في مزامنة البيانات: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'خطأ في تسجيل الخروج: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'تحضير';

  @override
  String get loadingEllipsis => 'جار التحميل...';

  @override
  String get recipeDeletedSuccess => 'تم حذف الوصفة بنجاح';

  @override
  String recipeDeleteError(Object error) {
    return 'فشل حذف الوصفة: $error';
  }

  @override
  String get noRecipesFound => 'لم يتم العثور على وصفات';

  @override
  String recipeLoadError(Object error) {
    return 'فشل تحميل الوصفة: $error';
  }

  @override
  String get unknownBrewingMethod => 'طريقة تحضير غير معروفة';

  @override
  String get recipeCopyErrorLoadingEdit => 'فشل تحميل الوصفة المنسوخة للتعديل.';

  @override
  String get recipeCopyErrorOperationFailed => 'فشلت العملية.';

  @override
  String get notProvided => 'غير متوفر';

  @override
  String get recipeUpdateFailedFetch => 'فشل في جلب بيانات الوصفة المحدثة.';

  @override
  String get recipeImportSuccess => 'تم استيراد الوصفة بنجاح!';

  @override
  String get recipeImportFailedSave => 'فشل في حفظ الوصفة المستوردة.';

  @override
  String get recipeImportFailedFetch => 'فشل في جلب بيانات الوصفة للاستيراد.';

  @override
  String get recipeNotImported => 'لم يتم استيراد الوصفة.';

  @override
  String get recipeNotFoundCloud =>
      'الوصفة غير موجودة في السحابة أو ليست عامة.';

  @override
  String get recipeLoadErrorGeneric => 'خطأ في تحميل الوصفة.';

  @override
  String get recipeUpdateAvailableTitle => 'تحديث متاح';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'يتوفر إصدار أحدث من \'$recipeName\' عبر الإنترنت. هل تريد التحديث؟';
  }

  @override
  String get dialogCancel => 'إلغاء';

  @override
  String get dialogUpdate => 'تحديث';

  @override
  String get recipeImportTitle => 'استيراد وصفة';

  @override
  String recipeImportBody(String recipeName) {
    return 'هل تريد استيراد الوصفة \'$recipeName\' من السحابة؟';
  }

  @override
  String get dialogImport => 'استيراد';

  @override
  String get moderationReviewNeededTitle => 'مراجعة الإشراف مطلوبة';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'الوصفة (الوصفات) التالية تتطلب مراجعة بسبب مشكلات الإشراف على المحتوى: $recipeNames';
  }

  @override
  String get dismiss => 'تجاهل';

  @override
  String get reviewRecipeButton => 'مراجعة الوصفة';

  @override
  String get signInRequiredTitle => 'تسجيل الدخول مطلوب';

  @override
  String get signInRequiredBodyShare =>
      'تحتاج إلى تسجيل الدخول لمشاركة وصفاتك الخاصة.';

  @override
  String get syncSuccess => 'تمت المزامنة بنجاح!';

  @override
  String get tooltipEditRecipe => 'تعديل الوصفة';

  @override
  String get tooltipCopyRecipe => 'نسخ الوصفة';

  @override
  String get tooltipShareRecipe => 'مشاركة الوصفة';

  @override
  String get signInRequiredSnackbar => 'تسجيل الدخول مطلوب';

  @override
  String get moderationErrorFunction => 'فشل التحقق من الإشراف على المحتوى.';

  @override
  String get moderationReasonDefault => 'تم الإبلاغ عن المحتوى للمراجعة.';

  @override
  String get moderationFailedTitle => 'فشل الإشراف';

  @override
  String moderationFailedBody(String reason) {
    return 'لا يمكن مشاركة هذه الوصفة بسبب: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'خطأ في مشاركة الوصفة: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName على Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'تعذر التحقق من حالة المحتوى. تم الحفظ محليًا، سيتم التحقق عند المزامنة التالية.';

  @override
  String get saveLocallyModerationFailedTitle => 'تم حفظ التغييرات محليًا';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'تم حفظ تغييراتك المحلية، ولكن تعذر تحديث النسخة العامة بسبب الإشراف على المحتوى: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'تعديل وصفة مستوردة';

  @override
  String get editImportedRecipeBody =>
      'هذه وصفة مستوردة. سيؤدي تعديلها إلى إنشاء نسخة جديدة ومستقلة. هل تريد المتابعة؟';

  @override
  String get editImportedRecipeButtonCopy => 'إنشاء نسخة وتعديل';

  @override
  String get editImportedRecipeButtonCancel => 'إلغاء';

  @override
  String get editDisplayNameTitle => 'تعديل اسم العرض';

  @override
  String get displayNameHint => 'أدخل اسم العرض الخاص بك';

  @override
  String get displayNameEmptyError => 'لا يمكن أن يكون اسم العرض فارغًا';

  @override
  String get displayNameTooLongError => 'لا يمكن أن يتجاوز اسم العرض 50 حرفًا';

  @override
  String get errorUserNotLoggedIn =>
      'المستخدم غير مسجل الدخول. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get displayNameUpdateSuccess => 'تم تحديث اسم العرض بنجاح!';

  @override
  String displayNameUpdateError(String error) {
    return 'فشل تحديث اسم العرض: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'حذف الصورة؟';

  @override
  String get deletePictureConfirmationBody =>
      'هل أنت متأكد أنك تريد حذف صورة ملفك الشخصي؟';

  @override
  String get deletePictureSuccess => 'تم حذف صورة الملف الشخصي.';

  @override
  String deletePictureError(String error) {
    return 'فشل حذف صورة الملف الشخصي: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'فشل تحديث صورة الملف الشخصي: $error';
  }

  @override
  String get updatePictureSuccess => 'تم تحديث صورة الملف الشخصي بنجاح!';

  @override
  String get deletePictureTooltip => 'حذف الصورة';

  @override
  String get account => 'الحساب';

  @override
  String get settingsBrewingMethodsTitle => 'طرق التخمير على الشاشة الرئيسية';

  @override
  String get filter => 'تصفية';

  @override
  String get sortBy => 'الترتيب حسب';

  @override
  String get dateAdded => 'تاريخ الإضافة';

  @override
  String get secondsAbbreviation => 'ث';

  @override
  String get settingsAppIcon => 'أيقونة التطبيق';

  @override
  String get settingsAppIconDefault => 'افتراضي';

  @override
  String get settingsAppIconLegacy => 'قديم';

  @override
  String get searchBeans => 'ابحث عن الحبوب...';

  @override
  String get favorites => 'المفضلة';

  @override
  String get searchPrefix => 'بحث: ';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get noBeansMatchSearch => 'لا توجد حبوب تطابق بحثك';

  @override
  String get clearFilters => 'مسح الفلاتر';

  @override
  String get farmer => 'المزارع';

  @override
  String get farm => 'المزرعة';

  @override
  String get enterFarmer => 'أدخل اسم المزارع (اختياري)';

  @override
  String get enterFarm => 'أدخل اسم المزرعة (اختياري)';

  @override
  String get requiredInformation => 'المعلومات المطلوبة';

  @override
  String get basicDetails => 'التفاصيل الأساسية';

  @override
  String get qualityMeasurements => 'قياسات الجودة';

  @override
  String get importantDates => 'تواريخ مهمة';

  @override
  String get brewStats => 'إحصاءات التحضير';

  @override
  String get showMore => 'عرض المزيد';

  @override
  String get showLess => 'عرض أقل';

  @override
  String get unpublishRecipeDialogTitle => 'جعل الوصفة خاصة';

  @override
  String get unpublishRecipeDialogMessage =>
      'تحذير: جعل هذه الوصفة خاصة سيؤدي إلى:';

  @override
  String get unpublishRecipeDialogBullet1 => 'إزالتها من نتائج البحث العامة';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'منع المستخدمين الجدد من استيرادها';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'المستخدمون الذين استوردوها بالفعل سيحتفظون بنسخهم';

  @override
  String get unpublishRecipeDialogKeepPublic => 'إبقاءها عامة';

  @override
  String get unpublishRecipeDialogMakePrivate => 'جعلها خاصة';

  @override
  String get recipeUnpublishSuccess => 'تم إلغاء نشر الوصفة بنجاح';

  @override
  String recipeUnpublishError(String error) {
    return 'فشل إلغاء نشر الوصفة: $error';
  }

  @override
  String get recipePublicTooltip => 'الوصفة عامة - انقر لجعلها خاصة';

  @override
  String get recipePrivateTooltip => 'الوصفة خاصة - شاركها لجعلها عامة';
}
