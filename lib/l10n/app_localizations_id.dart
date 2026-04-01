// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get beansStatsSectionTitle => 'Statistik biji';

  @override
  String get totalBeansBrewedLabel => 'Total biji yang digunakan';

  @override
  String get newBeansTriedLabel => 'Biji baru yang dicoba';

  @override
  String get originsExploredLabel => 'Asal yang dijelajahi';

  @override
  String get regionsExploredLabel => 'Wilayah yang dijelajahi';

  @override
  String get newRoastersDiscoveredLabel => 'Roaster baru yang ditemukan';

  @override
  String get favoriteRoastersLabel => 'Roaster favorit';

  @override
  String get topOriginsLabel => 'Asal-usul teratas';

  @override
  String get topRegionsLabel => 'Wilayah teratas';

  @override
  String get lastrecipe => 'Resep terakhir:';

  @override
  String get userRecipesTitle => 'Resep Anda';

  @override
  String get userRecipesSectionCreated => 'Dibuat oleh Anda';

  @override
  String get userRecipesSectionImported => 'Diimpor oleh Anda';

  @override
  String get userRecipesEmpty => 'Tidak ada resep ditemukan';

  @override
  String get userRecipesDeleteTitle => 'Hapus resep?';

  @override
  String get userRecipesDeleteMessage => 'Tindakan ini tidak dapat dibatalkan.';

  @override
  String get userRecipesDeleteConfirm => 'Hapus';

  @override
  String get userRecipesDeleteCancel => 'Batal';

  @override
  String get userRecipesSnackbarDeleted => 'Resep dihapus';

  @override
  String get hubUserRecipesTitle => 'Resep Anda';

  @override
  String get hubUserRecipesSubtitle =>
      'Lihat dan kelola resep yang dibuat dan diimpor';

  @override
  String get hubAccountSubtitle => 'Kelola profil Anda';

  @override
  String get hubSignInCreateSubtitle =>
      'Masuk untuk menyinkronkan resep dan preferensi';

  @override
  String get hubBrewDiarySubtitle =>
      'Lihat riwayat penyeduhan Anda dan tambahkan catatan';

  @override
  String get hubBrewStatsSubtitle =>
      'Lihat statistik dan tren penyeduhan pribadi dan global';

  @override
  String get hubSettingsSubtitle => 'Ubah preferensi dan perilaku aplikasi';

  @override
  String get hubAboutSubtitle => 'Detail aplikasi, versi, dan kontributor';

  @override
  String get about => 'Tentang';

  @override
  String get author => 'Penulis';

  @override
  String get authortext =>
      'Aplikasi Timer.Coffee dibuat oleh Anton Karliner, seorang pecinta kopi, spesialis media, dan jurnalis foto. Semoga aplikasi ini membantu Anda menikmati kopi. Jangan ragu untuk berkontribusi di GitHub.';

  @override
  String get contributors => 'Kontributor';

  @override
  String get errorLoadingContributors =>
      'Terjadi kesalahan saat memuat Kontributor';

  @override
  String get license => 'Lisensi';

  @override
  String get licensetext =>
      'Aplikasi ini adalah perangkat lunak gratis: Anda dapat mendistribusikan ulang dan/atau memodifikasinya berdasarkan ketentuan Lisensi Publik Umum GNU sebagaimana diterbitkan oleh Free Software Foundation, baik versi 3 dari Lisensi tersebut, atau (sesuai pilihan Anda) versi yang lebih baru.';

  @override
  String get licensebutton => 'Baca Lisensi Publik Umum GNU v3';

  @override
  String get website => 'Situs web';

  @override
  String get sourcecode => 'Kode sumber';

  @override
  String get support => 'Traktir saya kopi';

  @override
  String get supportButtonLabel => 'Dukung';

  @override
  String get allrecipes => 'Semua resep';

  @override
  String get favoriterecipes => 'Resep favorit';

  @override
  String get coffeeamount => 'Jumlah kopi (g)';

  @override
  String get wateramount => 'Jumlah air (ml)';

  @override
  String get watertemp => 'Suhu air';

  @override
  String get grindsize => 'Tingkat kehalusan gilingan';

  @override
  String get brewtime => 'Waktu penyeduhan';

  @override
  String get recipesummary => 'Ringkasan resep';

  @override
  String get recipesummarynote =>
      'Catatan: ini adalah resep dasar dengan jumlah air dan kopi yang standar.';

  @override
  String get preparation => 'Persiapan';

  @override
  String get brewingprocess => 'Proses penyeduhan';

  @override
  String get step => 'Langkah';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'detik',
      one: 'detik',
      zero: 'detik',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg =>
      'Terima kasih telah menggunakan Timer.Coffee! Nikmati';

  @override
  String get coffeefact => 'Fakta kopi';

  @override
  String get home => 'Beranda';

  @override
  String get appversion => 'Versi aplikasi';

  @override
  String get tipsmall => 'Beli kopi kecil';

  @override
  String get tipmedium => 'Beli kopi berukuran sedang';

  @override
  String get tiplarge => 'Beli kopi berukuran besar';

  @override
  String get supportdevelopment => 'Dukung pengembangan';

  @override
  String get supportdevmsg =>
      'Donasi Anda membantu menutup biaya pemeliharaan, misalnya lisensi pengembang. Dukungan ini juga memungkinkan saya mencoba lebih banyak alat seduh dan menambahkan lebih banyak resep ke aplikasi.';

  @override
  String get supportdevtnx =>
      'Terima kasih telah mempertimbangkan untuk berdonasi!';

  @override
  String get donationok => 'Terima kasih!';

  @override
  String get donationtnx =>
      'Saya sangat menghargai dukungan Anda! Semoga Anda menikmati banyak seduhan enak! ☕️';

  @override
  String get donationerr => 'Error';

  @override
  String get donationerrmsg =>
      'Terjadi kesalahan saat memproses pembelian. Silakan coba lagi.';

  @override
  String get sharemsg => 'Lihat resep ini:';

  @override
  String get finishbrew => 'Selesai';

  @override
  String get settings => 'Pengaturan';

  @override
  String get settingstheme => 'Tema';

  @override
  String get settingsthemelight => 'Terang';

  @override
  String get settingsthemedark => 'Gelap';

  @override
  String get settingsthemesystem => 'Sistem';

  @override
  String get settingslang => 'Bahasa';

  @override
  String get settingsDateTimeFormat => 'Format tanggal & waktu';

  @override
  String get settingsDateFormatLabel => 'Format tanggal';

  @override
  String get settingsTimeFormatLabel => 'Format waktu';

  @override
  String get settingsDateFormatAuto => 'Otomatis (sesuai bahasa)';

  @override
  String get settingsDateFormatDMY => 'DD/MM/YYYY';

  @override
  String get settingsDateFormatMDY => 'MM/DD/YYYY';

  @override
  String get settingsDateFormatYMD => 'YYYY-MM-DD';

  @override
  String get settingsTimeFormat12h => '12 jam (AM/PM)';

  @override
  String get settingsTimeFormat24h => '24 jam';

  @override
  String get sweet => 'Manis';

  @override
  String get balance => 'Seimbang';

  @override
  String get acidic => 'Asam';

  @override
  String get light => 'Ringan';

  @override
  String get strong => 'Kuat';

  @override
  String get slidertitle => 'Gunakan penggeser untuk menyesuaikan rasa';

  @override
  String get whatsnewtitle => 'Apa yang baru';

  @override
  String get whatsnewclose => 'Tutup';

  @override
  String get seasonspecials => 'Spesial Musim';

  @override
  String get snow => 'Salju';

  @override
  String get noFavoriteRecipesMessage =>
      'Daftar resep favorit Anda saat ini kosong. Mulailah menjelajah dan menyeduh untuk menemukan favorit Anda!';

  @override
  String get explore => 'Jelajahi';

  @override
  String get dateFormat => 'd MMM, yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Diari seduhan';

  @override
  String get brewdiarynotfound => 'Tidak ada entri yang ditemukan';

  @override
  String get beans => 'Biji';

  @override
  String get roaster => 'Roaster';

  @override
  String get rating => 'Peringkat';

  @override
  String get notes => 'Catatan';

  @override
  String get statsscreen => 'Statistik kopi';

  @override
  String get yourStats => 'Statistik Anda';

  @override
  String get coffeeBrewed => 'Kopi yang diseduh:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'Resep yang paling sering digunakan:';

  @override
  String get globalStats => 'Statistik global';

  @override
  String get unknownRecipe => 'Resep tidak dikenal';

  @override
  String get pulseUserRecipe => 'Resep pengguna';

  @override
  String get noData => 'Tidak ada data';

  @override
  String get refresh => 'Segarkan';

  @override
  String error(String error) {
    return 'Kesalahan: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Seseorang baru saja menyeduh $recipeName';
  }

  @override
  String pulseSomeoneBrewed(String recipeName) {
    return 'Seseorang menyeduh $recipeName';
  }

  @override
  String pulseSomeoneFromBrewed(String country, String recipeName) {
    return 'Seseorang dari $country menyeduh $recipeName';
  }

  @override
  String get pulseTitle => 'Pulse';

  @override
  String get hubPulseSubtitle => 'Umpan seduhan langsung';

  @override
  String get pulseLiveSummary => 'Ringkasan langsung';

  @override
  String get pulseBrewsLabel => 'Seduhan';

  @override
  String pulseBrewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seduhan',
    );
    return '$_temp0';
  }

  @override
  String get timePeriodRecent => 'Terbaru';

  @override
  String get timePeriodLastHour => 'Satu jam terakhir';

  @override
  String get timePeriodToday => 'Hari ini';

  @override
  String get timePeriodYesterday => 'Kemarin';

  @override
  String get timePeriodThisWeek => 'Minggu ini';

  @override
  String get timePeriodThisMonth => 'Bulan ini';

  @override
  String get timePeriodOlder => 'Lebih lama';

  @override
  String get timePeriodCustom => 'Kustom';

  @override
  String get relativeTimeJustNow => 'baru saja';

  @override
  String relativeTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count menit yang lalu',
      one: '1 menit yang lalu',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jam yang lalu',
      one: '1 jam yang lalu',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeHoursMinutesAgo(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours jam',
      one: '1 jam',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes menit',
      one: '1 menit',
    );
    return '$_temp0 $_temp1 yang lalu';
  }

  @override
  String relativeTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari yang lalu',
      one: '1 hari yang lalu',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bulan yang lalu',
      one: '1 bulan yang lalu',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tahun yang lalu',
      one: '1 tahun yang lalu',
    );
    return '$_temp0';
  }

  @override
  String get statsFor => 'Periode';

  @override
  String get homescreenbrewcoffee => 'Seduh kopi';

  @override
  String get homescreenhub => 'Hub';

  @override
  String get homescreenmore => 'Lainnya';

  @override
  String get addBeans => 'Tambahkan biji kopi';

  @override
  String get removeBeans => 'Buang biji kopi';

  @override
  String get name => 'Nama';

  @override
  String get origin => 'Asal';

  @override
  String get details => 'Detail';

  @override
  String get coffeebeans => 'Kopi';

  @override
  String get loading => 'Memuat';

  @override
  String get nocoffeebeans => 'Tidak ada kopi yang ditemukan';

  @override
  String get delete => 'Hapus';

  @override
  String get confirmDeleteTitle => 'Hapus entri?';

  @override
  String get recipeDuplicateConfirmTitle => 'Gandakan Resep?';

  @override
  String get recipeDuplicateConfirmMessage =>
      'Ini akan membuat salinan dari resep Anda yang dapat Anda edit secara independen. Apakah Anda ingin melanjutkan?';

  @override
  String get confirmDeleteMessage =>
      'Apakah Anda yakin ingin menghapus entri ini? Tindakan ini tidak dapat dibatalkan.';

  @override
  String get removeFavorite => 'Hapus dari favorit';

  @override
  String get addFavorite => 'Tambahkan ke favorit';

  @override
  String get toggleEditMode => 'Alihkan mode edit';

  @override
  String get coffeeBeansDetails => 'Detail kopi';

  @override
  String get edit => 'Edit';

  @override
  String get coffeeBeansNotFound => 'Kopi tidak ditemukan';

  @override
  String get basicInformation => 'Informasi dasar';

  @override
  String get geographyTerroir => 'Geografi/Terroir';

  @override
  String get variety => 'Varietas';

  @override
  String get region => 'Wilayah';

  @override
  String get elevation => 'Ketinggian';

  @override
  String get harvestDate => 'Tanggal panen';

  @override
  String get processing => 'Pemrosesan';

  @override
  String get processingMethod => 'Metode pemrosesan';

  @override
  String get roastDate => 'Tanggal sangrai';

  @override
  String get roastLevel => 'Tingkat sangrai';

  @override
  String get cuppingScore => 'Skor cupping';

  @override
  String get flavorProfile => 'Profil rasa';

  @override
  String get tastingNotes => 'Catatan rasa';

  @override
  String get additionalNotes => 'Catatan tambahan';

  @override
  String get noCoffeeBeans => 'Tidak ada kopi yang ditemukan';

  @override
  String get editCoffeeBeans => 'Edit kopi';

  @override
  String get addCoffeeBeans => 'Tambahkan kopi';

  @override
  String get showImagePicker => 'Pilih gambar';

  @override
  String get pleaseNote => 'Harap perhatikan';

  @override
  String get firstTimePopupMessage =>
      '1. Kami menggunakan layanan eksternal untuk memproses gambar. Dengan melanjutkan, Anda setuju dengan ini.\n2. Meskipun kami tidak menyimpan gambar Anda, harap hindari menyertakan detail pribadi.\n3. Pengenalan gambar saat ini dibatasi hingga 10 token per bulan (1 token = 1 gambar). Batas ini dapat berubah di kemudian hari.';

  @override
  String get ok => 'OK';

  @override
  String get takePhoto => 'Ambil foto';

  @override
  String get selectFromPhotos => 'Pilih dari foto';

  @override
  String get takeAdditionalPhoto => 'Ambil foto tambahan?';

  @override
  String get no => 'Tidak';

  @override
  String get yes => 'Ya';

  @override
  String get selectedImages => 'Gambar yang dipilih';

  @override
  String get selectedImage => 'Gambar yang dipilih';

  @override
  String get backToSelection => 'Kembali ke Pilihan';

  @override
  String get next => 'Berikutnya';

  @override
  String get unexpectedErrorOccurred => 'Terjadi kesalahan yang tidak terduga';

  @override
  String get tokenLimitReached =>
      'Maaf, Anda telah mencapai batas token untuk pengenalan gambar bulan ini';

  @override
  String get noCoffeeLabelsDetected =>
      'Tidak ada label kopi yang terdeteksi. Coba dengan gambar lain.';

  @override
  String get collectedInformation => 'Informasi yang dikumpulkan';

  @override
  String get enterRoaster => 'Masukkan nama roaster';

  @override
  String get enterName => 'Masukkan nama';

  @override
  String get enterOrigin => 'Masukkan asal';

  @override
  String get optional => 'Opsional';

  @override
  String get enterVariety => 'Masukkan varietas';

  @override
  String get enterProcessingMethod => 'Masukkan metode pemrosesan';

  @override
  String get enterRoastLevel => 'Masukkan tingkat sangrai';

  @override
  String get enterRegion => 'Masukkan wilayah';

  @override
  String get enterTastingNotes => 'Masukkan catatan rasa';

  @override
  String get enterElevation => 'Masukkan ketinggian';

  @override
  String get enterCuppingScore => 'Masukkan skor cupping';

  @override
  String get enterNotes => 'Masukkan catatan';

  @override
  String get inventory => 'Stok';

  @override
  String get amountLeft => 'Jumlah tersisa';

  @override
  String get enterAmountLeft => 'Masukkan jumlah tersisa';

  @override
  String get selectHarvestDate => 'Pilih tanggal panen';

  @override
  String get selectRoastDate => 'Pilih tanggal sangrai';

  @override
  String get selectDate => 'Pilih tanggal';

  @override
  String get selectTime => 'Pilih waktu';

  @override
  String get save => 'Simpan';

  @override
  String get fillRequiredFields => 'Harap isi semua kolom yang wajib diisi.';

  @override
  String get analyzing => 'Menganalisis';

  @override
  String get errorMessage => 'Kesalahan';

  @override
  String get selectCoffeeBeans => 'Pilih kopi';

  @override
  String get addNewBeans => 'Tambahkan kopi baru';

  @override
  String get favorite => 'Favorit';

  @override
  String get notFavorite => 'Bukan Favorit';

  @override
  String get myBeans => 'Biji Kopiku';

  @override
  String get signIn => 'Masuk';

  @override
  String get signOut => 'Keluar';

  @override
  String get signInWithApple => 'Masuk dengan Apple';

  @override
  String get signInSuccessful => 'Berhasil masuk dengan Apple';

  @override
  String get signInError => 'Kesalahan saat masuk dengan Apple';

  @override
  String get signInErrorGoogle => 'Kesalahan saat masuk dengan Google';

  @override
  String get signInWithGoogle => 'Masuk dengan Google';

  @override
  String get signOutSuccessful => 'Berhasil keluar';

  @override
  String get signOutConfirmationTitle => 'Apakah Anda yakin ingin keluar?';

  @override
  String get signOutConfirmationMessage =>
      'Sinkronisasi cloud akan berhenti berfungsi. Masuk lagi untuk melanjutkannya.';

  @override
  String get signInSuccessfulGoogle => 'Berhasil masuk dengan Google';

  @override
  String get signInWithEmail => 'Masuk dengan email';

  @override
  String get enterEmail => 'Masukkan email Anda';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get cancel => 'Batal';

  @override
  String get sendMagicLink => 'Kirim tautan ajaib';

  @override
  String get magicLinkSent => 'Tautan ajaib terkirim! Periksa email Anda.';

  @override
  String get sendOTP => 'Kirim OTP';

  @override
  String get otpSent => 'OTP dikirimkan ke email Anda';

  @override
  String get otpSendError => 'Kesalahan saat mengirim OTP';

  @override
  String get enterOTP => 'Masukkan OTP';

  @override
  String get otpHint => 'Masukkan kode 6 digit';

  @override
  String get verify => 'Verifikasi';

  @override
  String get signInSuccessfulEmail => 'Masuk berhasil';

  @override
  String get invalidOTP => 'OTP tidak valid';

  @override
  String get otpVerificationError => 'Kesalahan saat memverifikasi OTP';

  @override
  String get success => 'Berhasil!';

  @override
  String get otpSentMessage =>
      'Kode OTP sedang dikirim ke email Anda. Silakan masukkan kode tersebut setelah Anda menerimanya.';

  @override
  String get otpHint2 => 'Masukan kode disini';

  @override
  String get signInCreate => 'Masuk / Buat akun';

  @override
  String get accountManagement => 'Manajemen akun';

  @override
  String get deleteAccount => 'Hapus akun';

  @override
  String get deleteAccountWarning =>
      'Harap dicatat: jika Anda memilih untuk melanjutkan, kami akan menghapus akun dan data terkait dari server kami. Salinan data lokal akan tetap ada di perangkat, jika Anda juga ingin menghapusnya, Anda cukup menghapus aplikasi. Untuk mengaktifkan kembali sinkronisasi, Anda harus membuat akun lagi';

  @override
  String get deleteAccountConfirmation => 'Akun berhasil dihapus';

  @override
  String get accountDeleted => 'Akun dihapus';

  @override
  String get accountDeletionError =>
      'Kesalahan saat menghapus akun Anda, silakan coba lagi';

  @override
  String get deleteAccountTitle => 'Penting';

  @override
  String get selectBeans => 'Pilih biji kopi';

  @override
  String get all => 'Semua';

  @override
  String get selectRoaster => 'Pilih roaster';

  @override
  String get selectOrigin => 'Pilih asal';

  @override
  String get resetFilters => 'Atur Ulang Filter';

  @override
  String get showFavoritesOnly => 'Tampilkan favorit saja';

  @override
  String get apply => 'Terapkan';

  @override
  String get selectSize => 'Pilih ukuran';

  @override
  String get sizeStandard => 'Standar';

  @override
  String get sizeMedium => 'Sedang';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Tahun Saya dengan Timer.Coffee';

  @override
  String get yearlyStatsStory1Text =>
      'Hai, terima kasih telah menjadi bagian dari dunia Timer.Coffee tahun ini!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'Pertama-tama.\nAnda menyeduh kopi tahun ini$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'Lebih tepatnya,\nAnda menyeduh $liters liter kopi di tahun 2024!';
  }

  @override
  String yearlyStatsStory4Text(num roasterCount) {
    return 'Anda menggunakan biji dari $roasterCount roaster';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return '3 roaster teratas Anda adalah:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Kopi membawa Anda berkeliling dunia$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(num originCount) {
    return 'Anda mencicipi biji kopi\ndari $originCount negara!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Anda tidak menyeduh sendirian…';

  @override
  String get yearlyStatsStory7Part2 =>
      '...tetapi dengan pengguna dari 110 negara lain\ndi 6 benua!';

  @override
  String yearlyStatsStory8TitleLow(num count) {
    return 'Anda tetap setia pada diri sendiri dan hanya menggunakan $count metode seduh ini tahun ini:';
  }

  @override
  String yearlyStatsStory8TitleMedium(num count) {
    return 'Anda menemukan rasa baru dan menggunakan $count metode seduh tahun ini:';
  }

  @override
  String yearlyStatsStory8TitleHigh(num count) {
    return 'Anda adalah penemu kopi sejati dan menggunakan $count metode seduh tahun ini:';
  }

  @override
  String get yearlyStatsStory9Text => 'Masih banyak lagi yang bisa ditemukan!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return '3 resep teratas Anda di tahun 2024 adalah$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => 'Sampai jumpa di tahun 2025!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'Tunjukkan beberapa cinta ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => 'Donasi';

  @override
  String get yearlyStatsActionShare => 'Bagikan kemajuan Anda';

  @override
  String get yearlyStatsUnknown => 'Tidak diketahui';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return 'Gagal berbagi: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear =>
      'Tahun saya bersama Timer.Coffee';

  @override
  String get yearlyStatsShareProgressTop3Recipes => '3 resep teratas saya:';

  @override
  String get yearlyStatsShareProgressTop3Roasters => '3 roaster teratas saya:';

  @override
  String get yearlyStats25AppBarTitle =>
      'Tahun Anda dengan Timer.Coffee – 2025';

  @override
  String get yearlyStats25AppBarTitleSimple => 'Timer.Coffee di 2025';

  @override
  String get yearlyStats25Slide1Title => 'Tahun Anda dengan Timer.Coffee';

  @override
  String get yearlyStats25Slide1Subtitle =>
      'Ketuk untuk melihat bagaimana Anda menyeduh di 2025';

  @override
  String get yearlyStats25Slide2Intro => 'Bersama-sama kita menyeduh kopi...';

  @override
  String yearlyStats25Slide2Count(String count) {
    return '$count kali';
  }

  @override
  String yearlyStats25Slide2Liters(String liters) {
    return 'Itu sekitar $liters liter kopi';
  }

  @override
  String get yearlyStats25Slide2Cambridge =>
      'Cukup untuk memberi secangkir kopi kepada semua orang di Cambridge, Inggris (para mahasiswa akan sangat berterima kasih).';

  @override
  String get yearlyStats25Slide3Title => 'Lalu bagaimana dengan Anda?';

  @override
  String yearlyStats25Slide3Subtitle(String brews, String liters) {
    return 'Tahun ini Anda menyeduh $brews kali dengan Timer.Coffee. Total $liters liter kopi!';
  }

  @override
  String yearlyStats25Slide3TopBadge(int topPct) {
    return 'Anda masuk $topPct% teratas para penyeduh!';
  }

  @override
  String get yearlyStats25Slide4TitleSingle =>
      'Ingat hari ketika Anda menyeduh kopi paling banyak tahun ini?';

  @override
  String get yearlyStats25Slide4TitleMulti =>
      'Ingat hari-hari ketika Anda menyeduh kopi paling banyak tahun ini?';

  @override
  String get yearlyStats25Slide4TitleBrewTime => 'Waktu seduh Anda tahun ini';

  @override
  String get yearlyStats25Slide4ScratchLabel => 'Gosok untuk membuka';

  @override
  String yearlyStats25BrewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seduhan',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25Slide4PeakSingle(String date, String brewsLabel) {
    return '$date — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4PeakLiters(String liters) {
    return 'Sekitar $liters liter pada hari itu';
  }

  @override
  String yearlyStats25Slide4PeakMostRecent(
    String mostRecent,
    String brewsLabel,
  ) {
    return 'Terbaru: $mostRecent — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4BrewTimeLine(String timeLabel) {
    return 'Anda menghabiskan $timeLabel untuk menyeduh';
  }

  @override
  String get yearlyStats25Slide4BrewTimeFooter =>
      'Waktu yang terpakai dengan baik';

  @override
  String get yearlyStats25Slide5Title => 'Inilah cara Anda menyeduh';

  @override
  String get yearlyStats25Slide5MethodsHeader => 'Metode favorit:';

  @override
  String get yearlyStats25Slide5NoMethods => 'Belum ada metode';

  @override
  String get yearlyStats25Slide5RecipesHeader => 'Resep teratas:';

  @override
  String get yearlyStats25Slide5NoRecipes => 'Belum ada resep';

  @override
  String yearlyStats25MethodRow(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'seduhan',
    );
    return '$name — $count $_temp0';
  }

  @override
  String yearlyStats25Slide6Title(String count) {
    return 'Tahun ini Anda menemukan $count roaster:';
  }

  @override
  String get yearlyStats25Slide6NoRoasters => 'Belum ada roaster';

  @override
  String get yearlyStats25Slide7Title =>
      'Minum kopi bisa membawa Anda ke mana saja…';

  @override
  String yearlyStats25Slide7Subtitle(String count) {
    return 'Anda menemukan $count asal tahun ini:';
  }

  @override
  String get yearlyStats25Others => '...dan lainnya';

  @override
  String yearlyStats25FallbackTitle(int countries, int roasters) {
    return 'Tahun ini pengguna Timer.Coffee menggunakan biji dari $countries negara\ndan mendaftarkan $roasters roaster berbeda.';
  }

  @override
  String get yearlyStats25FallbackPromptHasBeans =>
      'Mengapa tidak lanjut mencatat kantong biji Anda?';

  @override
  String get yearlyStats25FallbackPromptNoBeans =>
      'Mungkin sudah waktunya Anda bergabung dan mencatat biji Anda juga?';

  @override
  String get yearlyStats25FallbackActionHasBeans => 'Lanjut menambah biji';

  @override
  String get yearlyStats25FallbackActionNoBeans =>
      'Tambah kantong biji pertama Anda';

  @override
  String get yearlyStats25ContinueButton => 'Lanjut';

  @override
  String get yearlyStats25PostcardTitle =>
      'Kirim ucapan Tahun Baru kepada sesama penyeduh.';

  @override
  String get yearlyStats25PostcardSubtitle =>
      'Opsional. Tetap sopan. Tanpa info pribadi.';

  @override
  String get yearlyStats25PostcardHint =>
      'Selamat Tahun Baru dan seduhan yang mantap!';

  @override
  String get yearlyStats25PostcardSending => 'Mengirim...';

  @override
  String get yearlyStats25PostcardSend => 'Kirim';

  @override
  String get yearlyStats25PostcardSkip => 'Lewati';

  @override
  String get yearlyStats25PostcardReceivedTitle => 'Ucapan dari penyeduh lain';

  @override
  String get yearlyStats25PostcardErrorLength => 'Masukkan 2–160 karakter.';

  @override
  String get yearlyStats25PostcardErrorSend =>
      'Tidak dapat mengirim. Silakan coba lagi.';

  @override
  String get yearlyStats25PostcardErrorRejected =>
      'Tidak dapat mengirim. Coba pesan lain.';

  @override
  String get yearlyStats25CtaTitle => 'Mari seduh sesuatu yang hebat di 2026!';

  @override
  String get yearlyStats25CtaSubtitle => 'Berikut beberapa ide:';

  @override
  String get yearlyStats25CtaExplorePrefix => 'Jelajahi penawaran di ';

  @override
  String get yearlyStats25CtaGiftBox => 'Kotak Hadiah Liburan';

  @override
  String get yearlyStats25CtaDonate => 'Donasi';

  @override
  String get yearlyStats25CtaDonateSuffix =>
      ' untuk membantu Timer.Coffee tumbuh di tahun mendatang';

  @override
  String get yearlyStats25CtaFollowPrefix => 'Ikuti kami di ';

  @override
  String get yearlyStats25CtaInstagram => 'Instagram';

  @override
  String get yearlyStats25CtaShareButton => 'Bagikan progres saya';

  @override
  String get yearlyStats25CtaShareHint => 'Jangan lupa tag @timercoffeeapp';

  @override
  String get yearlyStats25AppBarTooltipResume => 'Lanjutkan';

  @override
  String get yearlyStats25AppBarTooltipPause => 'Jeda';

  @override
  String get yearlyStats25ShareError =>
      'Tidak dapat membagikan rangkuman. Silakan coba lagi.';

  @override
  String yearlyStats25BrewTimeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count menit',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25BrewTimeHours(String hours) {
    return '$hours jam';
  }

  @override
  String get yearlyStats25ShareTitle => 'Tahun 2025 saya dengan Timer.Coffee';

  @override
  String get yearlyStats25ShareBrewedPrefix => 'Menyeduh ';

  @override
  String get yearlyStats25ShareBrewedMiddle => ' kali dan ';

  @override
  String get yearlyStats25ShareBrewedSuffix => ' liter kopi';

  @override
  String get yearlyStats25ShareRoastersPrefix => 'Biji dari ';

  @override
  String get yearlyStats25ShareRoastersSuffix => ' roaster';

  @override
  String get yearlyStats25ShareOriginsPrefix => 'Menemukan ';

  @override
  String get yearlyStats25ShareOriginsSuffix => ' asal kopi';

  @override
  String get yearlyStats25ShareMethodsTitle => 'Metode seduh favorit saya:';

  @override
  String get yearlyStats25ShareRecipesTitle => 'Resep teratas saya:';

  @override
  String get yearlyStats25ShareHandle => '@timercoffeeapp';

  @override
  String get yearlyStatsFailedToLike => 'Gagal menyukai. Silakan coba lagi.';

  @override
  String get labelCoffeeBrewed => 'Kopi yang diseduh';

  @override
  String get labelTastedBeansBy => 'Roaster yang dicoba';

  @override
  String get labelDiscoveredCoffeeFrom => 'Negara asal yang ditemukan';

  @override
  String get labelUsedBrewingMethods => 'Metode seduh yang digunakan';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'roaster',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'negara',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'metode seduh',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'Edit resep';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Buat resep';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Langkah resep';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Nama resep';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Deskripsi singkat';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Metode seduh';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Jumlah kopi (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Jumlah air (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Suhu air (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Ukuran gilingan';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => 'Total waktu seduh:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Menit';

  @override
  String get recipeCreationScreenSecondsLabel => 'Detik';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Langkah persiapan';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Langkah seduh $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Deskripsi langkah';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Waktu langkah: ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'Harap masukkan nama resep';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Harap masukkan deskripsi singkat';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Harap pilih metode seduh';

  @override
  String get recipeCreationScreenRequiredValidator => 'Wajib diisi';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Nomor tidak valid';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Harap masukkan deskripsi langkah';

  @override
  String get recipeCreationScreenContinueButton => 'Lanjut ke langkah resep';

  @override
  String get recipeCreationScreenAddStepButton => 'Tambah langkah';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Simpan resep';

  @override
  String get recipeCreationScreenUpdateSuccess => 'Resep berhasil diperbarui';

  @override
  String get recipeCreationScreenSaveSuccess => 'Resep berhasil disimpan';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'Kesalahan saat menyimpan resep: $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'gram';

  @override
  String get unitMillilitersLong => 'mililiter';

  @override
  String get recipeCopySuccess => 'Resep berhasil disalin!';

  @override
  String get recipeDuplicateSuccess => 'Resep berhasil digandakan!';

  @override
  String recipeCopyError(String error) {
    return 'Gagal menyalin resep: $error';
  }

  @override
  String get createRecipe => 'Buat resep';

  @override
  String errorSyncingData(Object error) {
    return 'Kesalahan sinkronisasi data: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'Kesalahan keluar: $error';
  }

  @override
  String get defaultPreparationStepDescription => 'Persiapan';

  @override
  String get loadingEllipsis => 'Memuat...';

  @override
  String get recipeDeletedSuccess => 'Resep berhasil dihapus';

  @override
  String recipeDeleteError(Object error) {
    return 'Gagal menghapus resep: $error';
  }

  @override
  String get noRecipesFound => 'Tidak ada resep yang ditemukan';

  @override
  String recipeLoadError(Object error) {
    return 'Gagal memuat resep: $error';
  }

  @override
  String get unknownBrewingMethod => 'Metode seduh tidak diketahui';

  @override
  String get recipeCopyErrorLoadingEdit =>
      'Gagal memuat resep yang disalin untuk diedit.';

  @override
  String get recipeCopyErrorOperationFailed => 'Operasi gagal.';

  @override
  String get notProvided => 'Tidak disediakan';

  @override
  String get recipeUpdateFailedFetch =>
      'Gagal mengambil data resep yang diperbarui.';

  @override
  String get recipeImportSuccess => 'Resep berhasil diimpor!';

  @override
  String get recipeImportFailedSave => 'Gagal menyimpan resep yang diimpor.';

  @override
  String get recipeImportFailedFetch =>
      'Gagal mengambil data resep untuk impor.';

  @override
  String get recipeNotImported => 'Resep tidak diimpor.';

  @override
  String get recipeNotFoundCloud =>
      'Resep tidak ditemukan di cloud atau tidak publik.';

  @override
  String get recipeLoadErrorGeneric => 'Kesalahan memuat resep.';

  @override
  String get recipeUpdateAvailableTitle => 'Pembaruan Tersedia';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return 'Versi terbaru dari \'$recipeName\' tersedia secara online. Perbarui?';
  }

  @override
  String get dialogCancel => 'Batal';

  @override
  String get dialogDuplicate => 'Gandakan';

  @override
  String get dialogUpdate => 'Perbarui';

  @override
  String get recipeImportTitle => 'Impor resep';

  @override
  String recipeImportBody(String recipeName) {
    return 'Apakah Anda ingin mengimpor resep \'$recipeName\' dari cloud?';
  }

  @override
  String get dialogImport => 'Impor';

  @override
  String get moderationReviewNeededTitle => 'Diperlukan tinjauan moderasi';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'Resep berikut memerlukan tinjauan karena masalah moderasi konten: $recipeNames';
  }

  @override
  String get dismiss => 'Tutup';

  @override
  String get reviewRecipeButton => 'Tinjau resep';

  @override
  String get signInRequiredTitle => 'Perlu masuk';

  @override
  String get signInRequiredBodyShare =>
      'Anda perlu masuk untuk membagikan resep Anda sendiri.';

  @override
  String get syncSuccess => 'Sinkronisasi berhasil!';

  @override
  String get tooltipEditRecipe => 'Edit resep';

  @override
  String get tooltipCopyRecipe => 'Salin resep';

  @override
  String get tooltipDuplicateRecipe => 'Gandakan resep';

  @override
  String get tooltipShareRecipe => 'Bagikan resep';

  @override
  String get signInRequiredSnackbar => 'Diperlukan Masuk';

  @override
  String get moderationErrorFunction => 'Pemeriksaan moderasi konten gagal.';

  @override
  String get moderationReasonDefault => 'Konten ditandai untuk ditinjau.';

  @override
  String get moderationFailedTitle => 'Moderasi Gagal';

  @override
  String moderationFailedBody(String reason) {
    return 'Resep ini tidak dapat dibagikan karena: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'Kesalahan saat membagikan resep: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName di Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'Tidak dapat memeriksa status konten. Disimpan secara lokal, akan diperiksa pada sinkronisasi berikutnya.';

  @override
  String get saveLocallyModerationFailedTitle =>
      'Perubahan Disimpan Secara Lokal';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'Perubahan lokal Anda telah disimpan, tetapi versi publik tidak dapat diperbarui karena moderasi konten: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'Edit Resep Impor';

  @override
  String get editImportedRecipeBody =>
      'Ini adalah resep impor. Mengeditnya akan membuat salinan baru yang independen. Apakah Anda ingin melanjutkan?';

  @override
  String get editImportedRecipeButtonCopy => 'Buat Salinan & Edit';

  @override
  String get editImportedRecipeButtonCancel => 'Batal';

  @override
  String get editDisplayNameTitle => 'Edit Nama Tampilan';

  @override
  String get displayNameHint => 'Masukkan nama tampilan Anda';

  @override
  String get displayNameEmptyError => 'Nama tampilan tidak boleh kosong';

  @override
  String get displayNameTooLongError =>
      'Nama tampilan tidak boleh lebih dari 50 karakter';

  @override
  String get errorUserNotLoggedIn =>
      'Pengguna belum masuk. Silakan masuk lagi.';

  @override
  String get displayNameUpdateSuccess => 'Nama tampilan berhasil diperbarui!';

  @override
  String displayNameUpdateError(String error) {
    return 'Gagal memperbarui nama tampilan: $error';
  }

  @override
  String get deletePictureConfirmationTitle => 'Hapus gambar?';

  @override
  String get deletePictureConfirmationBody =>
      'Apakah Anda yakin ingin menghapus gambar profil Anda?';

  @override
  String get deletePictureSuccess => 'Gambar profil dihapus.';

  @override
  String deletePictureError(String error) {
    return 'Gagal menghapus gambar profil: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'Gagal memperbarui gambar profil: $error';
  }

  @override
  String get updatePictureSuccess => 'Gambar profil berhasil diperbarui!';

  @override
  String get deletePictureTooltip => 'Hapus gambar';

  @override
  String get account => 'Akun';

  @override
  String get settingsBrewingMethodsTitle => 'Metode seduh di layar beranda';

  @override
  String get filter => 'Filter';

  @override
  String get sortBy => 'Urutkan berdasarkan';

  @override
  String get dateAdded => 'Tanggal ditambahkan';

  @override
  String get secondsAbbreviation => 's';

  @override
  String get settingsAppIcon => 'Ikon aplikasi';

  @override
  String get settingsAppIconDefault => 'Bawaan';

  @override
  String get settingsAppIconLegacy => 'Lama';

  @override
  String get searchBeans => 'Cari biji...';

  @override
  String get favorites => 'Favorit';

  @override
  String get searchPrefix => 'Cari: ';

  @override
  String get clearAll => 'Bersihkan Semua';

  @override
  String get noBeansMatchSearch =>
      'Tidak ada biji yang cocok dengan pencarian Anda';

  @override
  String get clearFilters => 'Bersihkan filter';

  @override
  String get farmer => 'Petani';

  @override
  String get farm => 'Perkebunan kopi';

  @override
  String get enterFarmer => 'Masukkan petani';

  @override
  String get enterFarm => 'Masukkan perkebunan kopi';

  @override
  String get requiredInformation => 'Informasi yang diperlukan';

  @override
  String get basicDetails => 'Detail dasar';

  @override
  String get qualityMeasurements => 'Kualitas & pengukuran';

  @override
  String get importantDates => 'Tanggal-tanggal penting';

  @override
  String get brewStats => 'Statistik seduh';

  @override
  String get showMore => 'Tampilkan lebih banyak';

  @override
  String get showLess => 'Tampilkan lebih sedikit';

  @override
  String get unpublishRecipeDialogTitle => 'Jadikan Resep Pribadi';

  @override
  String get unpublishRecipeDialogMessage =>
      'Peringatan: Menjadikan resep ini pribadi akan:';

  @override
  String get unpublishRecipeDialogBullet1 =>
      'Menghapusnya dari hasil pencarian publik';

  @override
  String get unpublishRecipeDialogBullet2 =>
      'Mencegah pengguna baru mengimpornya';

  @override
  String get unpublishRecipeDialogBullet3 =>
      'Pengguna yang sudah mengimpornya akan tetap memiliki salinannya';

  @override
  String get unpublishRecipeDialogKeepPublic => 'Tetap Publik';

  @override
  String get unpublishRecipeDialogMakePrivate => 'Jadikan Pribadi';

  @override
  String get recipeUnpublishSuccess => 'Resep berhasil dibatalkan publikasinya';

  @override
  String recipeUnpublishError(String error) {
    return 'Gagal membatalkan publikasi resep: $error';
  }

  @override
  String get recipePublicTooltip =>
      'Resep ini publik - ketuk untuk menjadikannya pribadi';

  @override
  String get recipePrivateTooltip =>
      'Resep ini pribadi - bagikan untuk menjadikannya publik';

  @override
  String get fieldClearButtonTooltip => 'Hapus';

  @override
  String get dateFieldClearButtonTooltip => 'Hapus tanggal';

  @override
  String get chipInputDuplicateError => 'Tag ini sudah ditambahkan';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return 'Jumlah tag maksimal telah tercapai ($maxChips)';
  }

  @override
  String get chipInputHintText => 'Tambahkan tag...';

  @override
  String get unitFieldRequiredError => 'Field ini wajib diisi';

  @override
  String get unitFieldInvalidNumberError => 'Harap masukkan angka yang valid';

  @override
  String unitFieldMinValueError(Object min) {
    return 'Nilai harus minimal $min';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return 'Nilai harus maksimal $max';
  }

  @override
  String get numericFieldRequiredError => 'Field ini wajib diisi';

  @override
  String get numericFieldInvalidNumberError =>
      'Harap masukkan angka yang valid';

  @override
  String numericFieldMinValueError(Object min) {
    return 'Nilai harus minimal $min';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return 'Nilai harus maksimal $max';
  }

  @override
  String get dropdownSearchHintText => 'Ketik untuk mencari...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return 'Error memuat saran: $error';
  }

  @override
  String get dropdownSearchNoResults => 'Tidak ada hasil';

  @override
  String get dropdownSearchLoading => 'Mencari...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return 'Gunakan \"$currentQuery\"';
  }

  @override
  String get requiredInfoSubtitle => '* Wajib';

  @override
  String get inventoryWeightExample => 'contoh: 250.5';

  @override
  String get unsavedChangesTitle => 'Perubahan Belum Disimpan';

  @override
  String get unsavedChangesMessage =>
      'Anda memiliki perubahan yang belum disimpan. Apakah Anda yakin ingin membuangnya?';

  @override
  String get unsavedChangesStay => 'Tetap';

  @override
  String get unsavedChangesDiscard => 'Buang';

  @override
  String beansWeightAddedBack(
    String amount,
    String beanName,
    String newWeight,
    String unit,
  ) {
    return 'Ditambahkan $amount$unit kembali ke $beanName. Berat baru: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
    String amount,
    String beanName,
    String newWeight,
    String unit,
  ) {
    return 'Dikurangi $amount$unit dari $beanName. Berat baru: $newWeight$unit';
  }

  @override
  String get notifications => 'Notifikasi';

  @override
  String get notificationsDisabledInSystemSettings =>
      'Dinonaktifkan di pengaturan sistem';

  @override
  String get openSettings => 'Buka Pengaturan';

  @override
  String get couldNotOpenLink => 'Tidak dapat membuka tautan';

  @override
  String get notificationsDisabledDialogTitle =>
      'Notifikasi Dinonaktifkan di Pengaturan Sistem';

  @override
  String get notificationsDisabledDialogContent =>
      'Anda telah menonaktifkan notifikasi di pengaturan perangkat. Untuk mengaktifkan notifikasi, silakan buka pengaturan perangkat Anda dan izinkan notifikasi untuk Timer.Coffee.';

  @override
  String get notificationDebug => 'Debug Notifikasi';

  @override
  String get testNotificationSystem => 'Uji sistem notifikasi';

  @override
  String get notificationsEnabled => 'Diaktifkan';

  @override
  String get notificationsDisabled => 'Dinonaktifkan';

  @override
  String get notificationPermissionDialogTitle => 'Aktifkan notifikasi?';

  @override
  String get notificationPermissionDialogMessage =>
      'Anda dapat mengaktifkan notifikasi untuk mendapatkan pembaruan berguna (misalnya tentang versi aplikasi baru). Notifikasi juga diperlukan untuk pembaruan progres seduhan secara langsung. Aktifkan sekarang atau ubah kapan saja di pengaturan.';

  @override
  String get notificationPermissionDialogMessageIos =>
      'Anda dapat mengaktifkan notifikasi untuk mendapatkan pembaruan berguna (misalnya tentang versi aplikasi baru). Notifikasi juga diperlukan untuk Live Activities dan Dynamic Island di iOS. Aktifkan sekarang atau ubah kapan saja di pengaturan.';

  @override
  String get notificationPermissionDialogMessageAndroid =>
      'Anda dapat mengaktifkan notifikasi untuk mendapatkan pembaruan berguna (misalnya tentang versi aplikasi baru). Notifikasi juga diperlukan untuk Live Updates di Android. Aktifkan sekarang atau ubah kapan saja di pengaturan.';

  @override
  String get notificationPermissionEnable => 'Aktifkan';

  @override
  String get notificationPermissionSkip => 'Nanti saja';

  @override
  String get holidayGiftBoxTitle => 'Kotak hadiah liburan';

  @override
  String get holidayGiftBoxInfoTrigger => 'Apa ini?';

  @override
  String get holidayGiftBoxInfoBody =>
      'Penawaran musiman pilihan dari mitra. Tautan bukan afiliasi - tujuan kami hanya membawa sedikit kebahagiaan bagi pengguna Timer.Coffee di musim liburan ini. Tarik untuk menyegarkan kapan saja.';

  @override
  String get holidayGiftBoxNoOffers => 'Belum ada penawaran saat ini.';

  @override
  String get holidayGiftBoxNoOffersSub =>
      'Tarik untuk menyegarkan atau coba lagi nanti.';

  @override
  String holidayGiftBoxShowingRegion(String region) {
    return 'Menampilkan penawaran untuk $region';
  }

  @override
  String get holidayGiftBoxViewDetails => 'Lihat detail';

  @override
  String get holidayGiftBoxPromoCopied => 'Kode promo disalin';

  @override
  String get holidayGiftBoxPromoCode => 'Kode promo';

  @override
  String giftDiscountOff(String percent) {
    return 'Diskon $percent%';
  }

  @override
  String giftDiscountUpToOff(String percent) {
    return 'Hingga $percent% diskon';
  }

  @override
  String get holidayGiftBoxTerms => 'Syarat & ketentuan';

  @override
  String get holidayGiftBoxVisitSite => 'Kunjungi situs mitra';

  @override
  String holidayGiftBoxValidUntil(String date) {
    return 'Berlaku hingga $date';
  }

  @override
  String holidayGiftBoxEndsInDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Berakhir dalam $days hari',
      one: 'Berakhir besok',
      zero: 'Berakhir hari ini',
    );
    return '$_temp0';
  }

  @override
  String get holidayGiftBoxValidWhileAvailable =>
      'Berlaku selama persediaan masih ada';

  @override
  String holidayGiftBoxUpdated(String date) {
    return 'Diperbarui $date';
  }

  @override
  String holidayGiftBoxLanguage(String language) {
    return 'Bahasa: $language';
  }

  @override
  String get holidayGiftBoxRetry => 'Coba lagi';

  @override
  String get holidayGiftBoxLoadFailed => 'Gagal memuat penawaran';

  @override
  String get holidayGiftBoxOfferUnavailable => 'Penawaran tidak tersedia';

  @override
  String get holidayGiftBoxBannerTitle => 'Lihat kotak hadiah liburan kami';

  @override
  String get holidayGiftBoxBannerCta => 'Lihat penawaran';

  @override
  String get regionEurope => 'Eropa';

  @override
  String get regionNorthAmerica => 'Amerika Utara';

  @override
  String get regionAsia => 'Asia';

  @override
  String get regionAustralia => 'Australia / Oseania';

  @override
  String get regionWorldwide => 'Seluruh dunia';

  @override
  String get regionAfrica => 'Afrika';

  @override
  String get regionMiddleEast => 'Timur Tengah';

  @override
  String get regionSouthAmerica => 'Amerika Selatan';

  @override
  String get setToZeroButton => 'Atur ke nol';

  @override
  String get setToZeroDialogTitle => 'Atur stok ke nol?';

  @override
  String get setToZeroDialogBody =>
      'Ini akan mengatur jumlah tersisa menjadi 0 g. Anda dapat mengeditnya nanti.';

  @override
  String get setToZeroDialogConfirm => 'Atur ke nol';

  @override
  String get setToZeroDialogCancel => 'Batal';

  @override
  String get inventorySetToZeroSuccess => 'Stok diatur menjadi 0 g';

  @override
  String get inventorySetToZeroFail => 'Gagal mengatur stok ke nol';

  @override
  String get timePeriodThisYear => 'Tahun ini';

  @override
  String get timePeriodLastYear => 'Tahun lalu';

  @override
  String get nativeAppPromoTitle => 'Unduh aplikasi Timer.Coffee';

  @override
  String get nativeAppPromoDescription =>
      'Nikmati pengalaman lengkap dengan fitur eksklusif: pemindaian label kopi berbasis AI, Live Activities di layar kunci, notifikasi push, umpan balik haptic, dan lainnya.';

  @override
  String get nativeAppPromoButton => 'Unduh aplikasi';

  @override
  String get addBrewEntry => 'Tambah catatan seduhan';

  @override
  String get selectBrewingMethod => 'Pilih metode seduh';

  @override
  String get selectRecipe => 'Pilih resep';

  @override
  String get brewDate => 'Tanggal';

  @override
  String get brewTime => 'Waktu';

  @override
  String get brewEntrySaved => 'Catatan seduhan disimpan';

  @override
  String get brewingMethodRequired => 'Silakan pilih metode seduh';

  @override
  String get recipeRequired => 'Silakan pilih resep';

  @override
  String get onboardingTitle => 'Selamat datang di Timer.Coffee';

  @override
  String get onboardingSubtitle => 'Anda biasa menyeduh dengan metode apa?';

  @override
  String get onboardingShowAll => 'Tampilkan semua metode';

  @override
  String get coffeeJourneyTitle => 'Langkah pertama';

  @override
  String get coffeeJourneyMilestoneFirstBrew =>
      'Selesaikan seduhan pertama Anda';

  @override
  String get coffeeJourneyMilestoneTryMethod => 'Coba resep lain';

  @override
  String get coffeeJourneyMilestoneAddBeans =>
      'Tambahkan biji kopi pertama Anda';

  @override
  String get coffeeJourneyMilestoneFavorite => 'Tambahkan resep ke favorit';

  @override
  String get coffeeJourneyMilestoneStats => 'Periksa statistik seduh Anda';

  @override
  String get coffeeJourneyMilestonePulse =>
      'Lihat bagaimana dunia menyeduh bersama Anda';

  @override
  String get coffeeJourneyCompleted =>
      'Anda telah menyelesaikan perjalanan kopi Anda!';

  @override
  String get coffeeJourneyDoneButton => 'Selesai';

  @override
  String get coffeeJourneyDismissHint =>
      'Anda selalu dapat memeriksa progres Anda di tab Lainnya.';

  @override
  String get coffeeJourneyDismissConfirm =>
      'Apakah Anda ingin menyembunyikan progres perjalanan kopi Anda?';

  @override
  String get coffeeJourneyHideButton => 'Sembunyikan';

  @override
  String get firstBrewCongrats =>
      'Selamat atas seduhan pertama Anda! Seduhan itu telah disimpan ke Diari Seduhan Anda.';

  @override
  String get firstBrewDiaryLink => 'Lihat diari seduhan';

  @override
  String get beanCoverPhoto => 'Foto sampul';

  @override
  String get beanCoverPhotoAdd => 'Tambahkan foto sampul';

  @override
  String get beanCoverPhotoChange => 'Ganti foto';

  @override
  String get beanCoverPhotoRemove => 'Hapus foto';

  @override
  String get beanCoverPhotoSavePromptTitle => 'Gunakan sebagai foto sampul?';

  @override
  String get beanCoverPhotoSavePromptBody =>
      'Apakah Anda ingin menyimpan salah satu gambar hasil pemindaian sebagai foto sampul biji kopi ini?';

  @override
  String get beanCoverPhotoUploading => 'Mengunggah foto…';

  @override
  String get beanCoverPhotoError => 'Gagal mengunggah foto';

  @override
  String get beanCoverPhotoSignInPrompt =>
      'Masuk untuk menambahkan foto sampul';

  @override
  String get settingsAnalyticsTitle => 'Privasi & analitik';

  @override
  String get settingsAnalyticsBrews => 'Bagikan analitik seduh';

  @override
  String get settingsAnalyticsBeans => 'Bagikan analitik biji kopi';

  @override
  String get settingsAnalyticsGeneral => 'Bagikan analitik penggunaan umum';

  @override
  String get done => 'Selesai';

  @override
  String get saving => 'Menyimpan…';

  @override
  String get notifBrewReminderTitle => 'Kangen ritual kopimu?';

  @override
  String get notifBrewReminderBody => 'Sudah beberapa hari. Siap seduh lagi?';

  @override
  String get notifBrewReminderTitle2 => 'Waktunya seduh kopi?';

  @override
  String get notifBrewReminderBody2 => 'Peralatanmu siap kapan pun kamu siap.';

  @override
  String get notifBrewReminderTitle3 => 'Ketelmu memanggil';

  @override
  String get notifBrewReminderBody3 =>
      'Secangkir enak cuma tinggal beberapa menit lagi.';

  @override
  String get notifBrewEscalationTitle => 'Mau seduh lagi?';

  @override
  String get notifBrewEscalationBody =>
      'Sudah cukup lama. Siap bikin sesuatu yang enak?';

  @override
  String get notifBrewEscalationTitle2 => 'Sudah lama?';

  @override
  String get notifBrewEscalationBody2 =>
      'Tidak perlu buru-buru. Peralatanmu siap kapan pun kamu siap.';

  @override
  String get notifBrewEscalationTitle3 => 'Waktunya ngopi lagi?';

  @override
  String get notifBrewEscalationBody3 =>
      'Secangkir yang benar-benar enak bisa siap hanya dalam beberapa menit.';

  @override
  String get notifDiscoverBeansTitle => 'Pantau biji kopimu';

  @override
  String get notifDiscoverBeansBody =>
      'Catat biji kopimu dan ingat mana yang paling kamu suka.';

  @override
  String get notifDiscoverPulseTitle =>
      'Lihat apa yang sedang diseduh orang lain';

  @override
  String get notifDiscoverPulseBody =>
      'Buka Pulse untuk melihat seduhan langsung dari seluruh dunia.';

  @override
  String get notifBrewMilestoneTitle => 'Kamu meraih pencapaian baru';

  @override
  String notifBrewMilestoneBody(int count) {
    return 'Kamu sudah menyeduh $count kali. Ketuk untuk melihat progresmu.';
  }

  @override
  String notifExploreRecipesTitle(String methodName) {
    return 'Coba resep $methodName baru';
  }

  @override
  String notifExploreRecipesBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Sejauh ini kamu sudah mencoba $count resep. Ini satu lagi buat dicoba.',
      one: 'Sejauh ini kamu sudah mencoba 1 resep. Ini satu lagi buat dicoba.',
    );
    return '$_temp0';
  }

  @override
  String get notifMorningTitle => 'Selamat pagi. Siap menyeduh?';

  @override
  String get notifMorningBody => 'Mulai hari dengan secangkir yang enak.';

  @override
  String get notifMorningTitle2 => 'Bangun dan seduh';

  @override
  String get notifMorningBody2 =>
      'Seduhan pagimu bisa siap dalam beberapa menit.';

  @override
  String get notifMorningTitle3 => 'Cangkir pertama hari ini?';

  @override
  String get notifMorningBody3 => 'Pilih resep dan mulai menyeduh.';

  @override
  String notifWeeklyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seduhan minggu ini',
      one: '1 seduhan minggu ini',
    );
    return '$_temp0';
  }

  @override
  String notifWeeklyBody(int recipes) {
    String _temp0 = intl.Intl.pluralLogic(
      recipes,
      locale: localeName,
      other: 'Hasil dari $recipes resep. Ketuk untuk melihat rinciannya.',
      one: 'Ketuk untuk melihat statistik mingguanmu.',
    );
    return '$_temp0';
  }

  @override
  String get notifBeanFreshnessTitle => 'Saatnya biji yang lebih segar?';

  @override
  String notifBeanFreshnessBody(String beanName, int days) {
    return 'Biji $beanName kamu disangrai $days hari lalu. Mungkin sudah lewat masa terbaiknya.';
  }

  @override
  String get settingsNotificationsToggle => 'Aktifkan notifikasi';

  @override
  String get settingsMorningReminder => 'Pengingat seduh pagi';

  @override
  String get settingsMorningReminderSubtitle =>
      'Pengingat harian untuk kopi pagi Anda';

  @override
  String get settingsMorningReminderTime => 'Waktu pengingat';

  @override
  String get settingsWeeklySummary => 'Ringkasan mingguan';

  @override
  String get settingsWeeklySummarySubtitle =>
      'Rekap seduhan Anda pada Minggu malam';

  @override
  String get settingsBeanFreshness => 'Peringatan kesegaran biji';

  @override
  String get settingsBeanFreshnessSubtitle =>
      'Beri tahu saat biji sudah lebih dari 3 minggu sejak tanggal sangrai';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari yang lalu',
    );
    return '$_temp0';
  }
}
