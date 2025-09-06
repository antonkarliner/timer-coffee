// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'Çekirdek istatistikleri';

  @override
  String get totalBeansBrewedLabel => 'Toplam kullanılan çekirdek';

  @override
  String get newBeansTriedLabel => 'Denenen yeni çekirdekler';

  @override
  String get originsExploredLabel => 'Keşfedilen menşeler';

  @override
  String get regionsExploredLabel => 'Keşfedilen bölgeler';

  @override
  String get newRoastersDiscoveredLabel => 'Keşfedilen yeni kavurucular';

  @override
  String get favoriteRoastersLabel => 'Favori kavurucular';

  @override
  String get topOriginsLabel => 'Önde gelen menşeler';

  @override
  String get topRegionsLabel => 'Önde gelen bölgeler';

  @override
  String get lastrecipe => 'En Son Kullanılan Tarif:';

  @override
  String get userRecipesTitle => 'Tariflerin';

  @override
  String get userRecipesSectionCreated => 'Senin oluşturdukların';

  @override
  String get userRecipesSectionImported => 'Senin içe aktardıkların';

  @override
  String get userRecipesEmpty => 'Hiç tarif bulunamadı';

  @override
  String get userRecipesDeleteTitle => 'Tarif silinsin mi?';

  @override
  String get userRecipesDeleteMessage => 'Bu işlem geri alınamaz.';

  @override
  String get userRecipesDeleteConfirm => 'Sil';

  @override
  String get userRecipesDeleteCancel => 'İptal';

  @override
  String get userRecipesSnackbarDeleted => 'Tarif silindi';

  @override
  String get hubUserRecipesTitle => 'Tariflerin';

  @override
  String get hubUserRecipesSubtitle =>
      'Oluşturduğun ve içe aktardığın tarifleri görüntüle ve yönet';

  @override
  String get hubAccountSubtitle => 'Profilinizi yönetin';

  @override
  String get hubSignInCreateSubtitle =>
      'Tarifleri ve tercihleri senkronize etmek için oturum açın';

  @override
  String get hubBrewDiarySubtitle =>
      'Demleme geçmişinizi görüntüleyin ve not ekleyin';

  @override
  String get hubBrewStatsSubtitle =>
      'Kişisel ve küresel demleme istatistiklerini ve trendlerini görüntüleyin';

  @override
  String get hubSettingsSubtitle =>
      'Uygulama tercihlerini ve davranışını değiştirin';

  @override
  String get hubAboutSubtitle =>
      'Uygulama detayları, sürüm ve katkıda bulunanlar';

  @override
  String get about => 'Hakkında';

  @override
  String get author => 'Yazar';

  @override
  String get authortext =>
      'Timer.Coffee Uygulaması, kahve meraklısı, medya uzmanı ve foto muhabiri Anton Karliner tarafından oluşturulmuştur. Bu uygulamanın kahvenizden keyif almanıza yardımcı olmasını umuyorum. GitHub üzerinden katkıda bulunmaktan çekinmeyin.';

  @override
  String get contributors => 'Katkıda Bulunanlar';

  @override
  String get errorLoadingContributors => 'Katkıda Bulunanlar Yüklenirken Hata';

  @override
  String get license => 'Lisans';

  @override
  String get licensetext =>
      'Bu uygulama, Free Software Foundation tarafından yayınlanan GNU Genel Kamu Lisansı\'nın koşulları altında yeniden dağıtabileceğiniz ve/veya değiştirebileceğiniz ücretsiz bir yazılımdır; ister sürüm 3 Lisansı, isterse (seçeneğinize bağlı olarak) daha sonraki bir sürümü.';

  @override
  String get licensebutton => 'GNU Genel Kamu Lisansı v3\'ü Okuyun';

  @override
  String get website => 'Web Sitesi';

  @override
  String get sourcecode => 'Kaynak Kodu';

  @override
  String get support => 'Bana Bir Kahve Al';

  @override
  String get allrecipes => 'Tüm Tarifler';

  @override
  String get favoriterecipes => 'Favori Tarifler';

  @override
  String get coffeeamount => 'Kahve Miktarı (g)';

  @override
  String get wateramount => 'Su Miktarı (ml)';

  @override
  String get watertemp => 'Su Sıcaklığı';

  @override
  String get grindsize => 'Öğütme Boyutu';

  @override
  String get brewtime => 'Demleme Süresi';

  @override
  String get recipesummary => 'Tarif Özeti';

  @override
  String get recipesummarynote =>
      'Not: Bu, varsayılan su ve kahve miktarlarıyla temel bir tariftir.';

  @override
  String get preparation => 'Hazırlık';

  @override
  String get brewingprocess => 'Demleme Süreci';

  @override
  String get step => 'Adım';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'saniye',
      one: 'saniye',
      zero: 'saniye',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg =>
      'Timer.Coffee\'yi kullandığınız için teşekkürler! Kahvenizin tadını çıkarın';

  @override
  String get coffeefact => 'Kahve Gerçeği';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get appversion => 'Uygulama Sürümü';

  @override
  String get tipsmall => 'Küçük bir kahve al';

  @override
  String get tipmedium => 'Orta bir kahve al';

  @override
  String get tiplarge => 'Büyük bir kahve al';

  @override
  String get supportdevelopment => 'Gelişimi Destekle';

  @override
  String get supportdevmsg =>
      'Bağışlarınız, bakım maliyetlerini (örneğin, geliştirici lisansları gibi) karşılamaya yardımcı olur. Ayrıca, daha fazla kahve demleme cihazı denememe ve uygulamaya daha fazla tarif eklememe olanak tanır.';

  @override
  String get supportdevtnx =>
      'Bağışta bulunmayı düşündüğünüz için teşekkürler!';

  @override
  String get donationok => 'Teşekkürler!';

  @override
  String get donationtnx =>
      'Destek olduğunuz için gerçekten minnettarım! Harika demlemeler dilerim! ☕️';

  @override
  String get donationerr => 'Hata';

  @override
  String get donationerrmsg =>
      'Satın alma işlemi sırasında bir hata oluştu, lütfen tekrar deneyin.';

  @override
  String get sharemsg => 'Bu tarife bir göz atın:';

  @override
  String get finishbrew => 'Bitir';

  @override
  String get settings => 'Ayarlar';

  @override
  String get settingstheme => 'Tema';

  @override
  String get settingsthemelight => 'Aydınlık';

  @override
  String get settingsthemedark => 'Karanlık';

  @override
  String get settingsthemesystem => 'Sistem';

  @override
  String get settingslang => 'Dil';

  @override
  String get sweet => 'Tatlı';

  @override
  String get balance => 'Denge';

  @override
  String get acidic => 'Asidik';

  @override
  String get light => 'Hafif';

  @override
  String get strong => 'Güçlü';

  @override
  String get slidertitle => 'Tadı ayarlamak için kaydırıcıları kullanın';

  @override
  String get whatsnewtitle => 'Yenilikler';

  @override
  String get whatsnewclose => 'Kapat';

  @override
  String get seasonspecials => 'Mevsim Özel';

  @override
  String get snow => 'Kar';

  @override
  String get noFavoriteRecipesMessage =>
      'Favori tarifler listeniz şu anda boş. Keşfetmeye ve demlemeye başlayarak favorilerinizi keşfedin!';

  @override
  String get explore => 'Keşfet';

  @override
  String get dateFormat => 'd MMM yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Demleme Günlüğü';

  @override
  String get brewdiarynotfound => 'Giriş bulunamadı';

  @override
  String get beans => 'Çekirdekler';

  @override
  String get roaster => 'Kavurucu';

  @override
  String get rating => 'Puanlama';

  @override
  String get notes => 'Notlar';

  @override
  String get statsscreen => 'Kahve İstatistikleri';

  @override
  String get yourStats => 'Verileriniz';

  @override
  String get coffeeBrewed => 'Demlenen kahve:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'En çok kullanılan tarifler:';

  @override
  String get globalStats => 'Genel veriler';

  @override
  String get unknownRecipe => 'Bilinmeyen Tarif';

  @override
  String get noData => 'Veri yok';

  @override
  String error(Object error) {
    return 'Hata: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Birisi az önce demledi: $recipeName';
  }

  @override
  String get timePeriodToday => 'Bugün';

  @override
  String get timePeriodThisWeek => 'Bu Hafta';

  @override
  String get timePeriodThisMonth => 'Bu Ay';

  @override
  String get timePeriodCustom => 'Özel';

  @override
  String get statsFor => 'Için istatistik ';

  @override
  String get homescreenbrewcoffee => 'Demlemek Kahve';

  @override
  String get homescreenhub => 'Hub';

  @override
  String get homescreenmore => 'Daha Fazla';

  @override
  String get addBeans => 'Çekirdek ekle';

  @override
  String get removeBeans => 'Çekirdek çıkar';

  @override
  String get name => 'Ad';

  @override
  String get origin => 'Menşei';

  @override
  String get details => 'Ayrıntılar';

  @override
  String get coffeebeans => 'Kahve Çekirdekleri';

  @override
  String get loading => 'Yükleniyor';

  @override
  String get nocoffeebeans => 'Kahve çekirdeği bulunamadı';

  @override
  String get delete => 'Sil';

  @override
  String get confirmDeleteTitle => 'Girdiyi sil?';

  @override
  String get confirmDeleteMessage =>
      'Bu girdiyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';

  @override
  String get removeFavorite => 'Favorilerden kaldır';

  @override
  String get addFavorite => 'Favorilere ekle';

  @override
  String get toggleEditMode => 'Düzenleme Modunu Değiştir';

  @override
  String get coffeeBeansDetails => 'Kahve Çekirdeği Detayları';

  @override
  String get edit => 'Düzenle';

  @override
  String get coffeeBeansNotFound => 'Kahve çekirdekleri bulunamadı';

  @override
  String get geographyTerroir => 'Coğrafya/Terroir';

  @override
  String get variety => 'Çeşit';

  @override
  String get region => 'Bölge';

  @override
  String get elevation => 'Yükseklik';

  @override
  String get harvestDate => 'Hasat Tarihi';

  @override
  String get processing => 'İşleme';

  @override
  String get processingMethod => 'İşleme Yöntemi';

  @override
  String get roastDate => 'Kavurma Tarihi';

  @override
  String get roastLevel => 'Kavurma Derecesi';

  @override
  String get cuppingScore => 'Cupping Puanı';

  @override
  String get flavorProfile => 'Lezzet Profili';

  @override
  String get tastingNotes => 'Tat Alma Notları';

  @override
  String get additionalNotes => 'Ek Notlar';

  @override
  String get noCoffeeBeans => 'Kahve çekirdeği bulunamadı';

  @override
  String get editCoffeeBeans => 'Kahve Çekirdeklerini Düzenle';

  @override
  String get addCoffeeBeans => 'Kahve Çekirdeği Ekle';

  @override
  String get showImagePicker => 'Görüntü Seçiciyi Göster';

  @override
  String get pleaseNote => 'Lütfen dikkat';

  @override
  String get firstTimePopupMessage =>
      '1. Görüntüleri işlemek için harici hizmetler kullanıyoruz. Devam ederek, bunu kabul etmiş olursunuz.\n2. Görüntülerinizi saklamasak da, lütfen herhangi bir kişisel ayrıntı eklemekten kaçının.\n3. Görüntü tanıma şu anda ayda 10 belirteçle sınırlıdır (1 belirteç = 1 görüntü). Bu sınır gelecekte değişebilir.';

  @override
  String get ok => 'Tamam';

  @override
  String get takePhoto => 'Fotoğraf çek';

  @override
  String get selectFromPhotos => 'Fotoğraflardan seç';

  @override
  String get takeAdditionalPhoto => 'Ek fotoğraf çekilsin mi?';

  @override
  String get no => 'Hayır';

  @override
  String get yes => 'Evet';

  @override
  String get selectedImages => 'Seçilen Görüntüler';

  @override
  String get selectedImage => 'Seçilen Görüntü';

  @override
  String get backToSelection => 'Seçime Geri Dön';

  @override
  String get next => 'Sonraki';

  @override
  String get unexpectedErrorOccurred => 'Beklenmeyen bir hata oluştu';

  @override
  String get tokenLimitReached =>
      'Üzgünüz, bu ay için görüntü tanıma belirteç sınırınıza ulaştınız';

  @override
  String get noCoffeeLabelsDetected =>
      'Kahve etiketi algılanmadı. Başka bir görüntüyle deneyin.';

  @override
  String get collectedInformation => 'Toplanan Bilgiler';

  @override
  String get enterRoaster => 'Kavurucu girin';

  @override
  String get enterName => 'İsim girin';

  @override
  String get enterOrigin => 'Menşei girin';

  @override
  String get optional => 'İsteğe bağlı';

  @override
  String get enterVariety => 'Çeşit girin';

  @override
  String get enterProcessingMethod => 'İşleme yöntemini girin';

  @override
  String get enterRoastLevel => 'Kavurma derecesini girin';

  @override
  String get enterRegion => 'Bölge girin';

  @override
  String get enterTastingNotes => 'Tatma notlarını girin';

  @override
  String get enterElevation => 'Yükseklik girin';

  @override
  String get enterCuppingScore => 'Cupping puanını girin';

  @override
  String get enterNotes => 'Notları girin';

  @override
  String get selectHarvestDate => 'Hasat Tarihini Seçin';

  @override
  String get selectRoastDate => 'Kavurma Tarihini Seçin';

  @override
  String get selectDate => 'Tarih seçin';

  @override
  String get save => 'Kaydet';

  @override
  String get fillRequiredFields => 'Lütfen tüm gerekli alanları doldurun.';

  @override
  String get analyzing => 'Analiz ediliyor';

  @override
  String get errorMessage => 'Hata';

  @override
  String get selectCoffeeBeans => 'Kahve Çekirdeklerini Seçin';

  @override
  String get addNewBeans => 'Yeni Çekirdek Ekle';

  @override
  String get favorite => 'Favori';

  @override
  String get notFavorite => 'Favori Değil';

  @override
  String get myBeans => 'Çekirdeklerim';

  @override
  String get signIn => 'Giriş';

  @override
  String get signOut => 'Çıkış';

  @override
  String get signInWithApple => 'Apple ile oturum açın';

  @override
  String get signInSuccessful => 'Apple ile oturum açma başarılı';

  @override
  String get signInError => 'Apple ile oturum açma hatası';

  @override
  String get signInWithGoogle => 'Google ile oturum açın';

  @override
  String get signOutSuccessful => 'Oturum başarıyla kapatıldı';

  @override
  String get signInSuccessfulGoogle =>
      'Google ile başarılı bir şekilde oturum açıldı';

  @override
  String get signInWithEmail => 'E-posta ile Oturum Aç';

  @override
  String get enterEmail => 'E-postanızı girin';

  @override
  String get emailHint => 'ornegin@eposta.com';

  @override
  String get cancel => 'İptal';

  @override
  String get sendMagicLink => 'Sihirli Bağlantıyı Gönder';

  @override
  String get magicLinkSent =>
      'Sihirli bağlantı gönderildi! E-postanızı kontrol edin.';

  @override
  String get sendOTP => 'OTP Gönder';

  @override
  String get otpSent => 'OTP\'niz e-postanıza gönderildi';

  @override
  String get otpSendError => 'OTP gönderilirken hata oluştu';

  @override
  String get enterOTP => 'OTP Girin';

  @override
  String get otpHint => '6 haneli kodu girin';

  @override
  String get verify => 'Doğrula';

  @override
  String get signInSuccessfulEmail => 'Giriş başarılı';

  @override
  String get invalidOTP => 'Geçersiz OTP';

  @override
  String get otpVerificationError => 'OTP doğrulanırken hata oluştu';

  @override
  String get success => 'Başarılı!';

  @override
  String get otpSentMessage =>
      'E-postanıza bir OTP gönderiliyor. Lütfen aldığınızda aşağıya girin.';

  @override
  String get otpHint2 => 'Kodu buraya girin';

  @override
  String get signInCreate => 'Oturum Aç / Hesap Oluştur';

  @override
  String get accountManagement => 'Hesap Yönetimi';

  @override
  String get deleteAccount => 'Hesabı Sil';

  @override
  String get deleteAccountWarning =>
      'Lütfen dikkat: Devam etmeyi seçerseniz, hesabınızı ve ilgili verileri sunucularımızdan sileceğiz. Verilerin yerel kopyası cihazda kalacaktır, eğer onu da silmek istiyorsanız, uygulamayı silebilirsiniz. Senkronizasyonu yeniden etkinleştirmek için, tekrar hesap oluşturmanız gerekecek';

  @override
  String get deleteAccountConfirmation => 'Hesap başarıyla silindi';

  @override
  String get accountDeleted => 'Hesap silindi';

  @override
  String get accountDeletionError =>
      'Hesabınızı silerken hata oluştu, lütfen tekrar deneyin';

  @override
  String get deleteAccountTitle => 'Önemli';

  @override
  String get selectBeans => 'Çekirdekleri Seçin';

  @override
  String get all => 'Tümü';

  @override
  String get selectRoaster => 'Kavurucu Seçin';

  @override
  String get selectOrigin => 'Menşei Seçin';

  @override
  String get resetFilters => 'Filtreleri Sıfırla';

  @override
  String get showFavoritesOnly => 'Yalnızca sık kullanılanları göster';

  @override
  String get apply => 'Uygula';

  @override
  String get selectSize => 'Boyutu Seçin';

  @override
  String get sizeStandard => 'Standart';

  @override
  String get sizeMedium => 'Orta';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Timer.Coffee ile Yılım';

  @override
  String get yearlyStatsStory1Text =>
      'Merhaba, bu yıl Timer.Coffee evreninin bir parçası olduğunuz için teşekkürler!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'Öncelikle.\nBu yıl biraz kahve demlediniz$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'Daha doğrusu,\n2024 yılında $liters litre kahve demlediniz!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return '$roasterCount farklı kavurucudan çekirdek kullandınız';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return 'En çok kullandığınız 3 kavurma şirketi şunlardı:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Kahve sizi bir yolculuğa çıkardı\ndünya çapında$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return '$originCount farklı ülkeden\nkahve çekirdeklerini tattınız!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Yalnız kahve demlemiyordunuz…';

  @override
  String get yearlyStatsStory7Part2 =>
      '…6 kıtada 110 farklı\nülkeden kullanıcılarımızla birlikteydiniz!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Kendinize sadık kaldınız ve bu yıl yalnızca şu $count demleme yöntemini kullandınız:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Yeni tatlar keşfediyordunuz ve bu yıl $count demleme yöntemi kullandınız:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return 'Gerçek bir kahve kaşifiydiniz ve bu yıl $count demleme yöntemi kullandınız:';
  }

  @override
  String get yearlyStatsStory9Text => 'Keşfedilecek çok şey var!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return '2024\'teki en iyi 3 tarifiniz şunlardı$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => '2025\'te görüşmek üzere!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Biraz sevgi göster ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Bağış Yap';

  @override
  String get yearlyStatsActionShare => 'İlerlemeni paylaş';

  @override
  String get yearlyStatsUnknown => 'Bilinmiyor';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Paylaşım başarısız oldu: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Timer.Coffee ile Yılım';

  @override
  String get yearlyStatsShareProgressTop3Recipes =>
      'En çok tercih ettiğim 3 tarif:';

  @override
  String get yearlyStatsShareProgressTop3Roasters =>
      'En çok tercih ettiğim 3 kavurucu:';

  @override
  String get yearlyStatsFailedToLike => 'Beğenilemedi. Lütfen tekrar deneyin.';

  @override
  String get labelCoffeeBrewed => 'Kahve demlendi';

  @override
  String get labelTastedBeansBy => 'Tarafından kavrulan çekirdekleri denedi';

  @override
  String get labelDiscoveredCoffeeFrom => 'Şu ülkeden kahve keşfetti:';

  @override
  String get labelUsedBrewingMethods => 'Kullanılan';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kavurucu',
      one: 'kavurucu',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ülke',
      one: 'ülke',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'demleme yöntemi',
      one: 'demleme yöntemi',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Tarifi Düzenle';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Tarif Oluştur';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Tarif Adımları';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Tarif Adı';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Kısa Açıklama';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Demleme Yöntemi';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Kahve Miktarı (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Su Miktarı (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Su Sıcaklığı (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Öğütme Boyutu';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => 'Toplam Demleme Süresi:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Dakika';

  @override
  String get recipeCreationScreenSecondsLabel => 'Saniye';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Hazırlık Adımı';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Demleme Adımı $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Adım Açıklaması';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Adım Süresi: ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'Lütfen bir tarif adı girin';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Lütfen kısa bir açıklama girin';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Lütfen bir demleme yöntemi seçin';

  @override
  String get recipeCreationScreenRequiredValidator => 'Gerekli';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Geçersiz numara';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Lütfen bir adım açıklaması girin';

  @override
  String get recipeCreationScreenContinueButton => 'Tarif Adımlarına Devam Et';

  @override
  String get recipeCreationScreenAddStepButton => 'Adım Ekle';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Tarifi Kaydet';

  @override
  String get recipeCreationScreenUpdateSuccess => 'Tarif başarıyla güncellendi';

  @override
  String get recipeCreationScreenSaveSuccess => 'Tarif başarıyla kaydedildi';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Tarif kaydedilirken hata oluştu: $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'gram';

  @override
  String get unitMillilitersLong => 'mililitre';

  @override
  String get recipeCopySuccess => 'Tarif başarıyla kopyalandı!';

  @override
  String recipeCopyError(String error) {
    return 'Tarif kopyalanırken hata oluştu: $error';
  }

  @override
  String get createRecipe => 'Tarif oluştur';

  @override
  String errorSyncingData(Object error) {
    return 'Veri senkronizasyon hatası: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Oturum kapatma hatası: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Hazırlık';

  @override
  String get loadingEllipsis => 'Yükleniyor...';

  @override
  String get recipeDeletedSuccess => 'Tarif başarıyla silindi';

  @override
  String recipeDeleteError(Object error) {
    return 'Tarif silinemedi: $error';
  }

  @override
  String get noRecipesFound => 'Tarif bulunamadı';

  @override
  String recipeLoadError(Object error) {
    return 'Tarif yüklenemedi: $error';
  }

  @override
  String get unknownBrewingMethod => 'Bilinmeyen demleme yöntemi';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Kopyalanan tarif düzenleme için yüklenemedi.';

  @override
  String get recipeCopyErrorOperationFailed => 'İşlem başarısız oldu.';

  @override
  String get notProvided => 'Sağlanmadı';

  @override
  String get recipeUpdateFailedFetch =>
      'Güncellenmiş tarif verileri alınamadı.';

  @override
  String get recipeImportSuccess => 'Tarif başarıyla içe aktarıldı!';

  @override
  String get recipeImportFailedSave => 'İçe aktarılan tarif kaydedilemedi.';

  @override
  String get recipeImportFailedFetch =>
      'İçe aktarma için tarif verileri alınamadı.';

  @override
  String get recipeNotImported => 'Tarif içe aktarılmadı.';

  @override
  String get recipeNotFoundCloud =>
      'Tarif bulutta bulunamadı veya herkese açık değil.';

  @override
  String get recipeLoadErrorGeneric => 'Tarif yüklenirken hata oluştu.';

  @override
  String get recipeUpdateAvailableTitle => 'Güncelleme Mevcut';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return '\'$recipeName\' uygulamasının daha yeni bir sürümü çevrimiçi olarak kullanılabilir. Güncellensin mi?';
  }

  @override
  String get dialogCancel => 'İptal';

  @override
  String get dialogUpdate => 'Güncelle';

  @override
  String get recipeImportTitle => 'Tarifi İçe Aktar';

  @override
  String recipeImportBody(String recipeName) {
    return '\'$recipeName\' tarifini buluttan içe aktarmak istiyor musunuz?';
  }

  @override
  String get dialogImport => 'İçe Aktar';

  @override
  String get moderationReviewNeededTitle => 'Moderasyon İncelemesi Gerekiyor';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'Aşağıdaki tarif(ler) içerik moderasyonu sorunları nedeniyle inceleme gerektiriyor: $recipeNames';
  }

  @override
  String get dismiss => 'Kapat';

  @override
  String get reviewRecipeButton => 'Tarifi İncele';

  @override
  String get signInRequiredTitle => 'Oturum Açma Gerekli';

  @override
  String get signInRequiredBodyShare =>
      'Kendi tariflerinizi paylaşmak için oturum açmanız gerekiyor.';

  @override
  String get syncSuccess => 'Senkronizasyon başarılı!';

  @override
  String get tooltipEditRecipe => 'Tarifi Düzenle';

  @override
  String get tooltipCopyRecipe => 'Tarifi Kopyala';

  @override
  String get tooltipShareRecipe => 'Tarifi Paylaş';

  @override
  String get signInRequiredSnackbar => 'Oturum Açma Gerekli';

  @override
  String get moderationErrorFunction =>
      'İçerik moderasyonu kontrolü başarısız oldu.';

  @override
  String get moderationReasonDefault => 'İçerik inceleme için işaretlendi.';

  @override
  String get moderationFailedTitle => 'Moderasyon Başarısız';

  @override
  String moderationFailedBody(String reason) {
    return 'Bu tarif paylaşılamıyor çünkü: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Tarif paylaşılırken hata oluştu: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName Timer.Coffee\'de';
  }

  @override
  String get saveLocallyCheckLater =>
      'İçerik durumu kontrol edilemedi. Yerel olarak kaydedildi, bir sonraki senkronizasyonda kontrol edilecek.';

  @override
  String get saveLocallyModerationFailedTitle =>
      'Değişiklikler Yerel Olarak Kaydedildi';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Yerel değişiklikleriniz kaydedildi, ancak içerik moderasyonu nedeniyle genel sürüm güncellenemedi: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'İçe Aktarılan Tarifi Düzenle';

  @override
  String get editImportedRecipeBody =>
      'Bu içe aktarılmış bir tariftir. Düzenlemek yeni, bağımsız bir kopya oluşturacaktır. Devam etmek istiyor musunuz?';

  @override
  String get editImportedRecipeButtonCopy => 'Kopya Oluştur ve Düzenle';

  @override
  String get editImportedRecipeButtonCancel => 'İptal';

  @override
  String get editDisplayNameTitle => 'Görünen Adı Düzenle';

  @override
  String get displayNameHint => 'Görünen adınızı girin';

  @override
  String get displayNameEmptyError => 'Görünen ad boş olamaz';

  @override
  String get displayNameTooLongError => 'Görünen ad 50 karakteri geçemez';

  @override
  String get errorUserNotLoggedIn =>
      'Kullanıcı giriş yapmadı. Lütfen tekrar giriş yapın.';

  @override
  String get displayNameUpdateSuccess => 'Görünen ad başarıyla güncellendi!';

  @override
  String displayNameUpdateError(String error) {
    return 'Görünen ad güncellenemedi: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Resmi Sil?';

  @override
  String get deletePictureConfirmationBody =>
      'Profil resminizi silmek istediğinizden emin misiniz?';

  @override
  String get deletePictureSuccess => 'Profil resmi silindi.';

  @override
  String deletePictureError(String error) {
    return 'Profil resmi silinemedi: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Profil resmi güncellenemedi: $error';
  }

  @override
  String get updatePictureSuccess => 'Profil resmi başarıyla güncellendi!';

  @override
  String get deletePictureTooltip => 'Resmi Sil';

  @override
  String get account => 'Hesap';

  @override
  String get settingsBrewingMethodsTitle => 'Ana Ekran Demleme Yöntemleri';

  @override
  String get filter => 'Filtre';

  @override
  String get sortBy => 'Sırala';

  @override
  String get dateAdded => 'Eklenme Tarihi';

  @override
  String get secondsAbbreviation => 'sn';

  @override
  String get settingsAppIcon => 'Uygulama Simgesi';

  @override
  String get settingsAppIconDefault => 'Varsayılan';

  @override
  String get settingsAppIconLegacy => 'Eski';

  @override
  String get searchBeans => 'Çekirdekleri ara...';

  @override
  String get favorites => 'Favoriler';

  @override
  String get searchPrefix => 'Ara: ';

  @override
  String get clearAll => 'Tümünü Temizle';

  @override
  String get noBeansMatchSearch => 'Aramanızla eşleşen çekirdek yok';

  @override
  String get clearFilters => 'Filtreleri Temizle';

  @override
  String get farmer => 'Çiftçi';

  @override
  String get farm => 'Kahve çiftliği';

  @override
  String get enterFarmer => 'Çiftçiyi girin';

  @override
  String get enterFarm => 'Kahve çiftliğini girin';

  @override
  String get requiredInformation => 'Gerekli bilgiler';

  @override
  String get basicDetails => 'Temel bilgiler';

  @override
  String get qualityMeasurements => 'Kalite ölçümleri';

  @override
  String get importantDates => 'Önemli tarihler';

  @override
  String get brewStats => 'Demleme istatistikleri';

  @override
  String get showMore => 'Daha fazla göster';

  @override
  String get showLess => 'Daha az göster';

  @override
  String get unpublishRecipeDialogTitle => 'Tarifi özel yap';

  @override
  String get unpublishRecipeDialogMessage =>
      'Uyarı: Bu tarifi özel yapmak şunlara neden olur:';

  @override
  String get unpublishRecipeDialogBullet1 =>
      'Genel arama sonuçlarından kaldırılır';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'Yeni kullanıcıların içe aktarmasını engeller';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'Daha önce içe aktarmış olan kullanıcılar kopyalarını saklar';

  @override
  String get unpublishRecipeDialogKeepPublic => 'Herkese açık bırak';

  @override
  String get unpublishRecipeDialogMakePrivate => 'Özel yap';

  @override
  String get recipeUnpublishSuccess => 'Tarif yayından başarıyla kaldırıldı';

  @override
  String recipeUnpublishError(String error) {
    return 'Tarif yayından kaldırılamadı: $error';
  }

  @override
  String get recipePublicTooltip =>
      'Tarif herkese açık - gizli yapmak için dokunun';

  @override
  String get recipePrivateTooltip =>
      'Tarif gizli - herkese açık yapmak için paylaşın';
}
