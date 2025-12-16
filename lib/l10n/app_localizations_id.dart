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
  String get originsExploredLabel => 'Asal-usul yang dijelajahi';

  @override
  String get regionsExploredLabel => 'Eropa';

  @override
  String get newRoastersDiscoveredLabel => 'Roaster baru yang ditemukan';

  @override
  String get favoriteRoastersLabel => 'Roastery favorit';

  @override
  String get topOriginsLabel => 'Asal-usul teratas';

  @override
  String get topRegionsLabel => 'Wilayah teratas';

  @override
  String get lastrecipe => 'Resep yang Terakhir Digunakan:';

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
      'Timer.Coffee App dibuat oleh Anton Karliner, seorang pecinta kopi, spesialis berita, dan jurnalis foto. Saya harap aplikasi ini akan membantu Kamu menikmati kopimu. Jangan ragu untuk berkontribusi di GitHub.';

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
  String get support => 'Belikan saya kopi';

  @override
  String get allrecipes => 'Semua Resep';

  @override
  String get favoriterecipes => 'Resep Favorit';

  @override
  String get coffeeamount => 'Jumlah kopi (g)';

  @override
  String get wateramount => 'Jumlah air (ml)';

  @override
  String get watertemp => 'Suhu air';

  @override
  String get grindsize => 'Tingkat kehalusan gilingan';

  @override
  String get brewtime => 'Waktu Penyeduhan';

  @override
  String get recipesummary => 'Ringkasan resep';

  @override
  String get recipesummarynote =>
      'Catatan: ini adalah resep dasar dengan jumlah air dan kopi yang standar.';

  @override
  String get preparation => 'Persiapan';

  @override
  String get brewingprocess => 'Proses Penyeduhan';

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
  String get coffeefact => 'Fakta Kopi';

  @override
  String get home => 'Beranda';

  @override
  String get appversion => 'Versi Aplikasi';

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
      'Donasi Anda membantu menutupi biaya pemeliharaan (seperti lisensi pengembang, misalnya). Mereka juga memperbolehkan saya mencoba lebih banyak perangkat pembuat kopi dan menambahkan lebih banyak resep ke aplikasi.';

  @override
  String get supportdevtnx =>
      'Terima kasih telah mempertimbangkan untuk berdonasi!';

  @override
  String get donationok => 'Terima kasih!';

  @override
  String get donationtnx =>
      'Saya sangat menghargai dukungan Kamu! Semoga Kamu dapat banyak minuman enak! ☕️';

  @override
  String get donationerr => 'Error';

  @override
  String get donationerrmsg =>
      'Terjadi error saat memproses pembelian, harap coba lagi.';

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
      'Daftar resep favorit Kamu saat ini kosong. Mulailah menjelajah dan menyeduh untuk menemukan favorit Kamu!';

  @override
  String get explore => 'Jelajahi';

  @override
  String get dateFormat => 'd MMM, yyyy';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => 'Diari Seduhan';

  @override
  String get brewdiarynotfound => 'Tidak ada entri yang ditemukan';

  @override
  String get beans => 'Biji';

  @override
  String get roaster => 'Roastery';

  @override
  String get rating => 'Peringkat';

  @override
  String get notes => 'Catatan';

  @override
  String get statsscreen => 'Statistik Kopi';

  @override
  String get yourStats => 'Statistik Anda';

  @override
  String get coffeeBrewed => 'Kopi yang diseduh:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => 'Resep yang paling sering digunakan:';

  @override
  String get globalStats => 'Statistik Global';

  @override
  String get unknownRecipe => 'Resep Tidak Dikenal';

  @override
  String get noData => 'Tidak ada data';

  @override
  String error(String error) {
    return 'Kesalahan: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return 'Seseorang baru saja menyeduh $recipeName';
  }

  @override
  String get timePeriodToday => 'Hari Ini';

  @override
  String get timePeriodThisWeek => 'Minggu Ini';

  @override
  String get timePeriodThisMonth => 'Bulan Ini';

  @override
  String get timePeriodCustom => 'Kustom';

  @override
  String get statsFor => 'Statistik untuk ';

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
  String get coffeeBeansDetails => 'Detail Kopi';

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
  String get region => 'Amerika Utara';

  @override
  String get elevation => 'Ketinggian';

  @override
  String get harvestDate => 'Tanggal Panen';

  @override
  String get processing => 'Pemrosesan';

  @override
  String get processingMethod => 'Metode Pemrosesan';

  @override
  String get roastDate => 'Tanggal Sangrai';

  @override
  String get roastLevel => 'Tingkat Sangrai';

  @override
  String get cuppingScore => 'Skor Cupping';

  @override
  String get flavorProfile => 'Profil Rasa';

  @override
  String get tastingNotes => 'Catatan Rasa';

  @override
  String get additionalNotes => 'Catatan Tambahan';

  @override
  String get noCoffeeBeans => 'Tidak ada kopi yang ditemukan';

  @override
  String get editCoffeeBeans => 'Edit Kopi';

  @override
  String get addCoffeeBeans => 'Tambahkan Kopi';

  @override
  String get showImagePicker => 'Tampilkan Pemilih Gambar';

  @override
  String get pleaseNote => 'Harap perhatikan';

  @override
  String get firstTimePopupMessage =>
      '1. Kami menggunakan layanan eksternal untuk memproses gambar. Dengan melanjutkan, Anda setuju dengan ini.\n2. Meskipun kami tidak menyimpan gambar Anda, harap hindari menyertakan detail pribadi.\n3. Pengenalan gambar saat ini dibatasi hingga 10 token per bulan (1 token = 1 gambar). Batas ini dapat berubah di kemudian hari.';

  @override
  String get ok => 'OKE';

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
  String get selectedImages => 'Gambar yang Dipilih';

  @override
  String get selectedImage => 'Gambar yang Dipilih';

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
  String get collectedInformation => 'Informasi yang Dikumpulkan';

  @override
  String get enterRoaster => 'Masukkan penyangrai';

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
  String get selectHarvestDate => 'Pilih Tanggal Panen';

  @override
  String get selectRoastDate => 'Pilih Tanggal Sangrai';

  @override
  String get selectDate => 'Pilih tanggal';

  @override
  String get save => 'Simpan';

  @override
  String get fillRequiredFields => 'Harap isi semua kolom yang wajib diisi.';

  @override
  String get analyzing => 'Menganalisis';

  @override
  String get errorMessage => 'Kesalahan';

  @override
  String get selectCoffeeBeans => 'Pilih Kopi';

  @override
  String get addNewBeans => 'Tambahkan Kopi Baru';

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
  String get signInWithGoogle => 'Masuk dengan Google';

  @override
  String get signOutSuccessful => 'Berhasil keluar';

  @override
  String get signInSuccessfulGoogle => 'Berhasil masuk dengan Google';

  @override
  String get signInWithEmail => 'Masuk dengan Email';

  @override
  String get enterEmail => 'Masukkan email Anda';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get cancel => 'Batal';

  @override
  String get sendMagicLink => 'Kirim Tautan Ajaib';

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
  String get accountManagement => 'Manajemen Akun';

  @override
  String get deleteAccount => 'Hapus Akun';

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
  String get selectBeans => 'Pilih Biji Kopi';

  @override
  String get all => 'Semua';

  @override
  String get selectRoaster => 'Pilih Penyangrai';

  @override
  String get selectOrigin => 'Pilih Asal';

  @override
  String get resetFilters => 'Atur Ulang Filter';

  @override
  String get showFavoritesOnly => 'Tampilkan favorit saja';

  @override
  String get apply => 'Terapkan';

  @override
  String get selectSize => 'Pilih Ukuran';

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
  String yearlyStatsStory4Text(Object roasterCount) {
    return 'Anda menggunakan biji dari $roasterCount pemanggang';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return '3 pemanggang teratas Anda adalah:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'Kopi membawa Anda berkeliling dunia$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'Anda mencicipi biji kopi\ndari $originCount negara!';
  }

  @override
  String get yearlyStatsStory7Part1 => 'Anda tidak menyeduh sendirian…';

  @override
  String get yearlyStatsStory7Part2 =>
      '...tetapi dengan pengguna dari 110 negara lain\ndi 6 benua!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return 'Anda tetap setia pada diri sendiri dan hanya menggunakan $count metode seduh ini tahun ini:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return 'Anda menemukan rasa baru dan menggunakan $count metode seduh tahun ini:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
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
  String get yearlyStatsShareProgressTop3Roasters =>
      '3 pemanggang teratas saya:';

  @override
  String get yearlyStatsFailedToLike => 'Gagal menyukai. Silakan coba lagi.';

  @override
  String get labelCoffeeBrewed => 'Kopi diseduh';

  @override
  String get labelTastedBeansBy => 'Biji kopi dicicipi oleh';

  @override
  String get labelDiscoveredCoffeeFrom => 'Kopi ditemukan dari';

  @override
  String get labelUsedBrewingMethods => 'Digunakan';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pemanggang',
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
  String get recipeCreationScreenEditRecipeTitle => 'Edit Resep';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'Buat Resep';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'Langkah Resep';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'Nama Resep';

  @override
  String get recipeCreationScreenShortDescriptionLabel => 'Deskripsi Singkat';

  @override
  String get recipeCreationScreenBrewingMethodLabel => 'Metode Penyeduhan';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'Jumlah Kopi (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => 'Jumlah Air (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => 'Suhu Air (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => 'Ukuran Gilingan';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => 'Total Waktu Seduh:';

  @override
  String get recipeCreationScreenMinutesLabel => 'Menit';

  @override
  String get recipeCreationScreenSecondsLabel => 'Detik';

  @override
  String get recipeCreationScreenPreparationStepTitle => 'Langkah Persiapan';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return 'Langkah Seduh $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'Deskripsi Langkah';

  @override
  String get recipeCreationScreenStepTimeLabel => 'Waktu Langkah: ';

  @override
  String get recipeCreationScreenRecipeNameValidator =>
      'Harap masukkan nama resep';

  @override
  String get recipeCreationScreenShortDescriptionValidator =>
      'Harap masukkan deskripsi singkat';

  @override
  String get recipeCreationScreenBrewingMethodValidator =>
      'Harap pilih metode penyeduhan';

  @override
  String get recipeCreationScreenRequiredValidator => 'Wajib diisi';

  @override
  String get recipeCreationScreenInvalidNumberValidator => 'Nomor tidak valid';

  @override
  String get recipeCreationScreenStepDescriptionValidator =>
      'Harap masukkan deskripsi langkah';

  @override
  String get recipeCreationScreenContinueButton => 'Lanjut ke Langkah Resep';

  @override
  String get recipeCreationScreenAddStepButton => 'Tambah Langkah';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'Simpan Resep';

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
  String get unknownBrewingMethod => 'Metode penyeduhan tidak diketahui';

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
  String get recipeImportTitle => 'Impor Resep';

  @override
  String recipeImportBody(String recipeName) {
    return 'Apakah Anda ingin mengimpor resep \'$recipeName\' dari cloud?';
  }

  @override
  String get dialogImport => 'Impor';

  @override
  String get moderationReviewNeededTitle => 'Diperlukan Tinjauan Moderasi';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'Resep berikut memerlukan tinjauan karena masalah moderasi konten: $recipeNames';
  }

  @override
  String get dismiss => 'Tutup';

  @override
  String get reviewRecipeButton => 'Tinjau Resep';

  @override
  String get signInRequiredTitle => 'Diperlukan Masuk';

  @override
  String get signInRequiredBodyShare =>
      'Anda perlu masuk untuk membagikan resep Anda sendiri.';

  @override
  String get syncSuccess => 'Sinkronisasi berhasil!';

  @override
  String get tooltipEditRecipe => 'Edit Resep';

  @override
  String get tooltipCopyRecipe => 'Salin Resep';

  @override
  String get tooltipDuplicateRecipe => 'Gandakan Resep';

  @override
  String get tooltipShareRecipe => 'Bagikan Resep';

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
  String get deletePictureConfirmationTitle => 'Hapus Gambar?';

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
  String get deletePictureTooltip => 'Hapus Gambar';

  @override
  String get account => 'Akun';

  @override
  String get settingsBrewingMethodsTitle => 'Metode Penyeduhan Layar Beranda';

  @override
  String get filter => 'Saring';

  @override
  String get sortBy => 'Urutkan berdasarkan';

  @override
  String get dateAdded => 'Tanggal ditambahkan';

  @override
  String get secondsAbbreviation => 's';

  @override
  String get settingsAppIcon => 'Ikon Aplikasi';

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
  String get requiredInformation => 'Informasi yang Diperlukan';

  @override
  String get basicDetails => 'Detail Dasar';

  @override
  String get qualityMeasurements => 'Kualitas & Pengukuran';

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
      String amount, String beanName, String newWeight, String unit) {
    return 'Ditambahkan $amount$unit kembali ke $beanName. Berat baru: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
      String amount, String beanName, String newWeight, String unit) {
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
  String get notificationPermissionDialogTitle => 'Aktifkan Notifikasi?';

  @override
  String get notificationPermissionDialogMessage =>
      'Anda dapat mengaktifkan notifikasi untuk mendapatkan pembaruan berguna (misalnya tentang versi aplikasi baru). Aktifkan sekarang atau ubah kapan saja di pengaturan.';

  @override
  String get notificationPermissionEnable => 'Aktifkan';

  @override
  String get notificationPermissionSkip => 'Nanti Saja';

  @override
  String get holidayGiftBoxTitle => 'Kotak Hadiah Liburan';

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
  String get holidayGiftBoxTerms => 'Syarat & Ketentuan';

  @override
  String get holidayGiftBoxVisitSite => 'Kunjungi situs mitra';

  @override
  String holidayGiftBoxValidUntil(String date) {
    return 'Berlaku hingga $date';
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
}
