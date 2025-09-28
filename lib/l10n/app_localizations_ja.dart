// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get beansStatsSectionTitle => '豆の統計';

  @override
  String get totalBeansBrewedLabel => '使用した豆の合計';

  @override
  String get newBeansTriedLabel => '新しく試した豆';

  @override
  String get originsExploredLabel => '探索した原産国';

  @override
  String get regionsExploredLabel => '探索した地域';

  @override
  String get newRoastersDiscoveredLabel => '見つけた新しいロースター';

  @override
  String get favoriteRoastersLabel => 'お気に入りのロースター';

  @override
  String get topOriginsLabel => 'トップ原産国';

  @override
  String get topRegionsLabel => 'トップ地域';

  @override
  String get lastrecipe => '最近使ったレシピ：';

  @override
  String get userRecipesTitle => 'あなたのレシピ';

  @override
  String get userRecipesSectionCreated => 'あなたが作成';

  @override
  String get userRecipesSectionImported => 'あなたがインポート';

  @override
  String get userRecipesEmpty => 'レシピが見つかりません';

  @override
  String get userRecipesDeleteTitle => 'レシピを削除しますか？';

  @override
  String get userRecipesDeleteMessage => 'この操作は元に戻せません。';

  @override
  String get userRecipesDeleteConfirm => '削除';

  @override
  String get userRecipesDeleteCancel => 'キャンセル';

  @override
  String get userRecipesSnackbarDeleted => 'レシピを削除しました';

  @override
  String get hubUserRecipesTitle => 'あなたのレシピ';

  @override
  String get hubUserRecipesSubtitle => '作成済み・インポート済みのレシピを表示して管理';

  @override
  String get hubAccountSubtitle => 'プロフィールを管理';

  @override
  String get hubSignInCreateSubtitle => 'レシピと設定を同期するにはサインインしてください';

  @override
  String get hubBrewDiarySubtitle => '醸造履歴を表示してメモを追加';

  @override
  String get hubBrewStatsSubtitle => '個人および世界の醸造統計と傾向を表示';

  @override
  String get hubSettingsSubtitle => 'アプリの設定と動作を変更';

  @override
  String get hubAboutSubtitle => 'アプリの詳細、バージョン、貢献者';

  @override
  String get about => '約';

  @override
  String get author => '著者';

  @override
  String get authortext =>
      'Timer.Coffee アプリは、コーヒー愛好家でありメディア専門家でフォトジャーナリストのアントン・カーリナーによって作成されました。このアプリがあなたのコーヒータイムをより楽しいものにすることを願っています。GitHubでの貢献もお気軽に。';

  @override
  String get contributors => '貢献者';

  @override
  String get errorLoadingContributors => '貢献者の読み込みエラー';

  @override
  String get license => 'ライセンス';

  @override
  String get licensetext =>
      'このアプリケーションはフリーソフトウェアです:フリーソフトウェア財団によって公開されたGNU一般公衆利用許諾契約書（GPL）の条項の下で、あなたはそれを再配布および/または変更することができます。それはライセンスのバージョン3、または（あなたの選択によって）いかなる後のバージョンにも適用されます。';

  @override
  String get licensebutton => 'GNU一般公衆利用許諾契約書v3を読む';

  @override
  String get website => 'ウェブサイト';

  @override
  String get sourcecode => 'ソースコード';

  @override
  String get support => '開発者にコーヒーを買う';

  @override
  String get allrecipes => 'すべてのレシピ';

  @override
  String get favoriterecipes => 'お気に入りのレシピ';

  @override
  String get coffeeamount => 'コーヒー量(g)';

  @override
  String get wateramount => '水の量(ml)';

  @override
  String get watertemp => '水の温度';

  @override
  String get grindsize => '挽き目の大きさ';

  @override
  String get brewtime => '抽出時間';

  @override
  String get recipesummary => 'レシピの概要';

  @override
  String get recipesummarynote => '注：これは、デフォルトの水とコーヒーの量で基本的なレシピです。';

  @override
  String get preparation => '準備';

  @override
  String get brewingprocess => '抽出プロセス';

  @override
  String get step => 'ステップ';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '秒',
      one: '秒',
      zero: '秒',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg => 'Timer.Coffeeをご利用いただきありがとうございます! お楽しみください';

  @override
  String get coffeefact => 'コーヒーの事実';

  @override
  String get home => 'ホーム';

  @override
  String get appversion => 'アプリバージョン';

  @override
  String get tipsmall => '小さなコーヒーを買う';

  @override
  String get tipmedium => '中くらいのコーヒーを買う';

  @override
  String get tiplarge => '大きなコーヒーを買う';

  @override
  String get supportdevelopment => '開発をサポートする';

  @override
  String get supportdevmsg =>
      'あなたの寄付は、メンテナンス費用（例えば、開発者ライセンスなど）をカバーするのに役立ちます。また、より多くのコーヒー抽出器具を試し、アプリにより多くのレシピを追加することを可能にします。';

  @override
  String get supportdevtnx => '寄付を検討してくださりありがとうございます！';

  @override
  String get donationok => 'ありがとうございます！';

  @override
  String get donationtnx => 'あなたのサポートに心から感謝します！素晴らしいコーヒーをたくさんお楽しみください！☕️';

  @override
  String get donationerr => 'エラー';

  @override
  String get donationerrmsg => '購入処理中のエラー、もう一度お試しください。';

  @override
  String get sharemsg => 'このレシピをチェックしてください：';

  @override
  String get finishbrew => '終了';

  @override
  String get settings => '設定';

  @override
  String get settingstheme => 'テーマ';

  @override
  String get settingsthemelight => 'ライト';

  @override
  String get settingsthemedark => 'ダーク';

  @override
  String get settingsthemesystem => 'システム';

  @override
  String get settingslang => '言語';

  @override
  String get sweet => '甘い';

  @override
  String get balance => 'バランス';

  @override
  String get acidic => '酸っぱい';

  @override
  String get light => 'ライト';

  @override
  String get strong => '強い';

  @override
  String get slidertitle => 'スライダーを使用して味を調整する';

  @override
  String get whatsnewtitle => '新着情報';

  @override
  String get whatsnewclose => '閉じる';

  @override
  String get seasonspecials => 'シーズンスペシャル';

  @override
  String get snow => '雪';

  @override
  String get noFavoriteRecipesMessage =>
      'お気に入りのレシピリストは現在空です。探索して醸造を始めて、お気に入りを発見しましょう！';

  @override
  String get explore => '探索する';

  @override
  String get dateFormat => 'yyyy年MMMd日';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => '醸造日記';

  @override
  String get brewdiarynotfound => 'エントリーが見つかりません';

  @override
  String get beans => '豆';

  @override
  String get roaster => '焙煎機';

  @override
  String get rating => '評価';

  @override
  String get notes => 'ノート';

  @override
  String get statsscreen => 'コーヒー統計';

  @override
  String get yourStats => 'あなたの統計';

  @override
  String get coffeeBrewed => '淹れたコーヒー:';

  @override
  String get litersUnit => 'リットル';

  @override
  String get mostUsedRecipes => '最も使用されるレシピ:';

  @override
  String get globalStats => 'グローバル統計';

  @override
  String get unknownRecipe => '不明なレシピ';

  @override
  String get noData => 'データなし';

  @override
  String error(Object error) {
    return 'エラー: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return '$recipeNameを淹れたばかりです';
  }

  @override
  String get timePeriodToday => '今日';

  @override
  String get timePeriodThisWeek => '今週';

  @override
  String get timePeriodThisMonth => '今月';

  @override
  String get timePeriodCustom => 'カスタム';

  @override
  String get statsFor => '統計情報';

  @override
  String get homescreenbrewcoffee => 'コーヒーを淹れる';

  @override
  String get homescreenhub => 'ハブ';

  @override
  String get homescreenmore => 'もっと';

  @override
  String get addBeans => '豆を追加';

  @override
  String get removeBeans => '豆を取り除く';

  @override
  String get name => '名前';

  @override
  String get origin => '原産地';

  @override
  String get details => '詳細';

  @override
  String get coffeebeans => 'コーヒー豆';

  @override
  String get loading => '読み込み中';

  @override
  String get nocoffeebeans => 'コーヒー豆が見つかりません';

  @override
  String get delete => '削除';

  @override
  String get confirmDeleteTitle => 'エントリを削除しますか？';

  @override
  String get confirmDeleteMessage => 'このエントリを削除してもよろしいですか？この操作は元に戻せません。';

  @override
  String get removeFavorite => 'お気に入りから削除';

  @override
  String get addFavorite => 'お気に入りに追加';

  @override
  String get toggleEditMode => '編集モードを切り替える';

  @override
  String get coffeeBeansDetails => 'コーヒー豆の詳細';

  @override
  String get edit => '編集';

  @override
  String get coffeeBeansNotFound => 'コーヒー豆が見つかりません';

  @override
  String get basicInformation => '基本情報';

  @override
  String get geographyTerroir => '地理/テロワール';

  @override
  String get variety => '品種';

  @override
  String get region => '地域';

  @override
  String get elevation => '標高';

  @override
  String get harvestDate => '収穫日';

  @override
  String get processing => '精製方法';

  @override
  String get processingMethod => '精製方法';

  @override
  String get roastDate => '焙煎日';

  @override
  String get roastLevel => '焙煎度';

  @override
  String get cuppingScore => 'カッピングスコア';

  @override
  String get flavorProfile => 'フレーバープロファイル';

  @override
  String get tastingNotes => 'テイスティングノート';

  @override
  String get additionalNotes => '追加メモ';

  @override
  String get noCoffeeBeans => 'コーヒー豆が見つかりません';

  @override
  String get editCoffeeBeans => 'コーヒー豆を編集';

  @override
  String get addCoffeeBeans => 'コーヒー豆を追加';

  @override
  String get showImagePicker => '画像ピッカーを表示';

  @override
  String get pleaseNote => 'ご注意ください';

  @override
  String get firstTimePopupMessage =>
      '1. 画像の処理には外部サービスを使用しています。続行すると、これに同意したことになります。\n2. 画像は保存しませんが、個人情報を含めないでください。\n3. 画像認識は現在、月間10トークンに制限されています（1トークン=1画像）。この制限は今後変更される可能性があります。';

  @override
  String get ok => 'OK';

  @override
  String get takePhoto => '写真を撮る';

  @override
  String get selectFromPhotos => '写真から選択';

  @override
  String get takeAdditionalPhoto => 'さらに写真を撮りますか？';

  @override
  String get no => 'いいえ';

  @override
  String get yes => 'はい';

  @override
  String get selectedImages => '選択した画像';

  @override
  String get selectedImage => '選択した画像';

  @override
  String get backToSelection => '選択画面に戻る';

  @override
  String get next => '次へ';

  @override
  String get unexpectedErrorOccurred => '予期せぬエラーが発生しました';

  @override
  String get tokenLimitReached => '申し訳ありませんが、今月の画像認識のトークン制限に達しました';

  @override
  String get noCoffeeLabelsDetected => 'コーヒーラベルが検出されませんでした。別の画像で試してください。';

  @override
  String get collectedInformation => '収集された情報';

  @override
  String get enterRoaster => 'ロースターを入力';

  @override
  String get enterName => '名前を入力';

  @override
  String get enterOrigin => '原産国を入力';

  @override
  String get optional => '任意';

  @override
  String get enterVariety => '品種を入力';

  @override
  String get enterProcessingMethod => '精製方法を入力';

  @override
  String get enterRoastLevel => '焙煎度を入力';

  @override
  String get enterRegion => '地域を入力';

  @override
  String get enterTastingNotes => 'テイスティングノートを入力';

  @override
  String get enterElevation => '標高を入力';

  @override
  String get enterCuppingScore => 'カッピングスコアを入力';

  @override
  String get enterNotes => 'メモを入力';

  @override
  String get inventory => '在庫';

  @override
  String get amountLeft => '残量';

  @override
  String get enterAmountLeft => '残量を入力';

  @override
  String get selectHarvestDate => '収穫日を選択';

  @override
  String get selectRoastDate => '焙煎日を選択';

  @override
  String get selectDate => '日付を選択';

  @override
  String get save => '保存';

  @override
  String get fillRequiredFields => '必須項目をすべて入力してください。';

  @override
  String get analyzing => '分析中';

  @override
  String get errorMessage => 'エラー';

  @override
  String get selectCoffeeBeans => 'コーヒー豆を選択';

  @override
  String get addNewBeans => '新しい豆を追加';

  @override
  String get favorite => 'お気に入り';

  @override
  String get notFavorite => 'お気に入り解除';

  @override
  String get myBeans => 'マイビーンズ';

  @override
  String get signIn => 'サインイン';

  @override
  String get signOut => 'サインアウト';

  @override
  String get signInWithApple => 'Appleでサインインする';

  @override
  String get signInSuccessful => 'Appleでサインインに成功しました';

  @override
  String get signInError => 'Appleでサインイン中にエラーが発生しました';

  @override
  String get signInWithGoogle => 'Googleでサインイン';

  @override
  String get signOutSuccessful => '正常にログアウトしました';

  @override
  String get signInSuccessfulGoogle => 'Googleで正常にサインインしました';

  @override
  String get signInWithEmail => 'メールでサインイン';

  @override
  String get enterEmail => 'メールアドレスを入力してください';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get cancel => 'キャンセル';

  @override
  String get sendMagicLink => 'マジックリンクを送信';

  @override
  String get magicLinkSent => 'マジックリンクを送信しました！ メールを確認してください。';

  @override
  String get sendOTP => 'OTPの送信';

  @override
  String get otpSent => 'OTPをメールに送信しました';

  @override
  String get otpSendError => 'OTPの送信中にエラーが発生しました';

  @override
  String get enterOTP => 'OTPを入力してください';

  @override
  String get otpHint => '6桁のコードを入力してください';

  @override
  String get verify => '確認';

  @override
  String get signInSuccessfulEmail => 'ログインに成功しました';

  @override
  String get invalidOTP => '無効なOTPです';

  @override
  String get otpVerificationError => 'OTPの検証中にエラーが発生しました';

  @override
  String get success => '成功!';

  @override
  String get otpSentMessage => 'メールにOTPを送信しました。\n 届いたら、以下に入力してください。';

  @override
  String get otpHint2 => 'ここにコードを入力してください';

  @override
  String get signInCreate => 'サインイン / アカウントを作成';

  @override
  String get accountManagement => 'アカウント管理';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get deleteAccountWarning =>
      '注意: 続行すると、アカウントとその関連データがサーバーから削除されます。データのローカルコピーはデバイスに残ります。削除するには、アプリを削除するだけです。同期を再度有効にするには、アカウントを再作成する必要があります。';

  @override
  String get deleteAccountConfirmation => 'アカウントの削除に成功しました';

  @override
  String get accountDeleted => 'アカウントが削除されました';

  @override
  String get accountDeletionError => 'アカウントの削除中にエラーが発生しました。もう一度お試しください';

  @override
  String get deleteAccountTitle => '重要なお知らせ';

  @override
  String get selectBeans => '豆を選択';

  @override
  String get all => 'すべて';

  @override
  String get selectRoaster => '焙煎所を選択';

  @override
  String get selectOrigin => '原産地を選択';

  @override
  String get resetFilters => 'フィルターをリセット';

  @override
  String get showFavoritesOnly => 'お気に入りを表示';

  @override
  String get apply => '適用';

  @override
  String get selectSize => 'サイズを選択';

  @override
  String get sizeStandard => '標準';

  @override
  String get sizeMedium => '中';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Timer.Coffee との一年';

  @override
  String get yearlyStatsStory1Text =>
      'こんにちは、今年は Timer.Coffee の世界に参加していただきありがとうございます。';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return 'まず最初に。\n今年はコーヒーを淹れました$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return 'もっと正確に言うと、\n2024 年には $liters リットルのコーヒーを淹れました。';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return '$roasterCount 軒のロースターの豆を使用しました';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return '上位 3 つのロースターは次のとおりです。\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return 'コーヒーがあなたを旅に連れて行ってくれました\n世界中を$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return 'コーヒー豆を味わいました\n$originCount か国から！';
  }

  @override
  String get yearlyStatsStory7Part1 => 'あなたは一人でコーヒーを淹れていたわけではありません…';

  @override
  String get yearlyStatsStory7Part2 => '…6 大陸の 110 か国のユーザーと一緒でした。';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return '今年は、$count つの抽出方法だけを使用しました。';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return '今年は、$count つの抽出方法を試して、新しい味を発見しました。';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return '今年は、$count つの抽出方法を試して、真のコーヒー愛好家でした。';
  }

  @override
  String get yearlyStatsStory9Text => '他にもたくさんの発見があります。';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return '2024 年のあなたのお気に入りのレシピトップ 3 は$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => '2025 年にお会いしましょう。';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return 'いいねを送信する ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => '寄付する';

  @override
  String get yearlyStatsActionShare => '進捗状況を共有する';

  @override
  String get yearlyStatsUnknown => '不明';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return '共有に失敗しました: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Timer.Coffee との一年';

  @override
  String get yearlyStatsShareProgressTop3Recipes => '私のトップ3レシピ：';

  @override
  String get yearlyStatsShareProgressTop3Roasters => '私のトップ3ロースター：';

  @override
  String get yearlyStatsFailedToLike => 'いいねできませんでした。もう一度お試しください。';

  @override
  String get labelCoffeeBrewed => 'コーヒーを淹れました';

  @override
  String get labelTastedBeansBy => '焙煎者:';

  @override
  String get labelDiscoveredCoffeeFrom => '原産地の発見:';

  @override
  String get labelUsedBrewingMethods => '使用:';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ロースター',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'か国',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'つの抽出方法',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => 'レシピを編集';

  @override
  String get recipeCreationScreenCreateRecipeTitle => 'レシピを作成';

  @override
  String get recipeCreationScreenRecipeStepsTitle => 'レシピの手順';

  @override
  String get recipeCreationScreenRecipeNameLabel => 'レシピ名';

  @override
  String get recipeCreationScreenShortDescriptionLabel => '簡単な説明';

  @override
  String get recipeCreationScreenBrewingMethodLabel => '抽出方法';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => 'コーヒーの量 (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => '水の量 (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => '水の温度 (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => '挽き目のサイズ';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => '合計抽出時間:';

  @override
  String get recipeCreationScreenMinutesLabel => '分';

  @override
  String get recipeCreationScreenSecondsLabel => '秒';

  @override
  String get recipeCreationScreenPreparationStepTitle => '準備ステップ';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return '抽出ステップ $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => 'ステップの説明';

  @override
  String get recipeCreationScreenStepTimeLabel => 'ステップ時間: ';

  @override
  String get recipeCreationScreenRecipeNameValidator => 'レシピ名を入力してください';

  @override
  String get recipeCreationScreenShortDescriptionValidator => '簡単な説明を入力してください';

  @override
  String get recipeCreationScreenBrewingMethodValidator => '抽出方法を選択してください';

  @override
  String get recipeCreationScreenRequiredValidator => '必須';

  @override
  String get recipeCreationScreenInvalidNumberValidator => '無効な数値';

  @override
  String get recipeCreationScreenStepDescriptionValidator => 'ステップの説明を入力してください';

  @override
  String get recipeCreationScreenContinueButton => 'レシピの手順に進む';

  @override
  String get recipeCreationScreenAddStepButton => 'ステップを追加';

  @override
  String get recipeCreationScreenSaveRecipeButton => 'レシピを保存';

  @override
  String get recipeCreationScreenUpdateSuccess => 'レシピが正常に更新されました';

  @override
  String get recipeCreationScreenSaveSuccess => 'レシピが正常に保存されました';

  @override
  String recipeCreationScreenSaveError(String error) {
    return 'レシピの保存中にエラーが発生しました: $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => 'グラム';

  @override
  String get unitMillilitersLong => 'ミリリットル';

  @override
  String get recipeCopySuccess => 'レシピが正常にコピーされました！';

  @override
  String recipeCopyError(String error) {
    return 'レシピのコピー中にエラーが発生しました: $error';
  }

  @override
  String get createRecipe => 'レシピを作成';

  @override
  String errorSyncingData(Object error) {
    return 'データ同期エラー: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return 'サインアウトエラー: $error';
  }

  @override
  String get defaultPreparationStepDescription => '準備';

  @override
  String get loadingEllipsis => '読み込み中...';

  @override
  String get recipeDeletedSuccess => 'レシピが正常に削除されました';

  @override
  String recipeDeleteError(Object error) {
    return 'レシピの削除に失敗しました: $error';
  }

  @override
  String get noRecipesFound => 'レシピが見つかりません';

  @override
  String recipeLoadError(Object error) {
    return 'レシピの読み込みに失敗しました: $error';
  }

  @override
  String get unknownBrewingMethod => '不明な抽出方法';

  @override
  String get recipeCopyErrorLoadingEdit => 'コピーしたレシピの編集読み込みに失敗しました。';

  @override
  String get recipeCopyErrorOperationFailed => '操作に失敗しました。';

  @override
  String get notProvided => '未提供';

  @override
  String get recipeUpdateFailedFetch => '更新されたレシピデータの取得に失敗しました。';

  @override
  String get recipeImportSuccess => 'レシピが正常にインポートされました！';

  @override
  String get recipeImportFailedSave => 'インポートされたレシピの保存に失敗しました。';

  @override
  String get recipeImportFailedFetch => 'インポート用のレシピデータの取得に失敗しました。';

  @override
  String get recipeNotImported => 'レシピはインポートされませんでした。';

  @override
  String get recipeNotFoundCloud => 'レシピがクラウドで見つからないか、公開されていません。';

  @override
  String get recipeLoadErrorGeneric => 'レシピの読み込み中にエラーが発生しました。';

  @override
  String get recipeUpdateAvailableTitle => 'アップデートがあります';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return '\'$recipeName\'の新しいバージョンがオンラインで利用可能です。アップデートしますか？';
  }

  @override
  String get dialogCancel => 'キャンセル';

  @override
  String get dialogUpdate => 'アップデート';

  @override
  String get recipeImportTitle => 'レシピをインポート';

  @override
  String recipeImportBody(String recipeName) {
    return 'クラウドからレシピ\'$recipeName\'をインポートしますか？';
  }

  @override
  String get dialogImport => 'インポート';

  @override
  String get moderationReviewNeededTitle => 'モデレーションレビューが必要です';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return 'コンテンツモデレーションの問題により、次のレシピのレビューが必要です: $recipeNames';
  }

  @override
  String get dismiss => '閉じる';

  @override
  String get reviewRecipeButton => 'レシピをレビュー';

  @override
  String get signInRequiredTitle => 'サインインが必要です';

  @override
  String get signInRequiredBodyShare => '自分のレシピを共有するにはサインインする必要があります。';

  @override
  String get syncSuccess => '同期成功！';

  @override
  String get tooltipEditRecipe => 'レシピを編集';

  @override
  String get tooltipCopyRecipe => 'レシピをコピー';

  @override
  String get tooltipShareRecipe => 'レシピを共有';

  @override
  String get signInRequiredSnackbar => 'サインインが必要です';

  @override
  String get moderationErrorFunction => 'コンテンツモデレーションチェックに失敗しました。';

  @override
  String get moderationReasonDefault => 'コンテンツがレビューのためにフラグ付けされました。';

  @override
  String get moderationFailedTitle => 'モデレーション失敗';

  @override
  String moderationFailedBody(String reason) {
    return 'このレシピは共有できません。理由: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return 'レシピの共有中にエラーが発生しました: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName on Timer.Coffee';
  }

  @override
  String get saveLocallyCheckLater =>
      'コンテンツの状態を確認できませんでした。ローカルに保存しました。次回の同期時に確認します。';

  @override
  String get saveLocallyModerationFailedTitle => '変更はローカルに保存されました';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return 'ローカルの変更は保存されましたが、コンテンツモデレーションのため公開バージョンを更新できませんでした: $reason';
  }

  @override
  String get editImportedRecipeTitle => 'インポートされたレシピを編集';

  @override
  String get editImportedRecipeBody =>
      'これはインポートされたレシピです。編集すると、新しい独立したコピーが作成されます。続行しますか？';

  @override
  String get editImportedRecipeButtonCopy => 'コピーを作成して編集';

  @override
  String get editImportedRecipeButtonCancel => 'キャンセル';

  @override
  String get editDisplayNameTitle => '表示名を編集';

  @override
  String get displayNameHint => '表示名を入力してください';

  @override
  String get displayNameEmptyError => '表示名は空にできません';

  @override
  String get displayNameTooLongError => '表示名は50文字を超えることはできません';

  @override
  String get errorUserNotLoggedIn => 'ユーザーがログインしていません。再度サインインしてください。';

  @override
  String get displayNameUpdateSuccess => '表示名が正常に更新されました！';

  @override
  String displayNameUpdateError(String error) {
    return '表示名の更新に失敗しました: $error';
  }

  @override
  String get deletePictureConfirmationTitle => '画像を削除しますか？';

  @override
  String get deletePictureConfirmationBody => 'プロフィール画像を削除してもよろしいですか？';

  @override
  String get deletePictureSuccess => 'プロフィール画像が削除されました。';

  @override
  String deletePictureError(String error) {
    return 'プロフィール画像の削除に失敗しました: $error';
  }

  @override
  String updatePictureError(String error) {
    return 'プロフィール画像の更新に失敗しました: $error';
  }

  @override
  String get updatePictureSuccess => 'プロフィール画像が正常に更新されました！';

  @override
  String get deletePictureTooltip => '画像を削除';

  @override
  String get account => 'アカウント';

  @override
  String get settingsBrewingMethodsTitle => 'ホーム画面の抽出方法';

  @override
  String get filter => 'フィルター';

  @override
  String get sortBy => '並び替え';

  @override
  String get dateAdded => '追加日';

  @override
  String get secondsAbbreviation => '秒';

  @override
  String get settingsAppIcon => 'アプリアイコン';

  @override
  String get settingsAppIconDefault => 'デフォルト';

  @override
  String get settingsAppIconLegacy => '古い';

  @override
  String get searchBeans => '豆を検索...';

  @override
  String get favorites => 'お気に入り';

  @override
  String get searchPrefix => '検索: ';

  @override
  String get clearAll => 'すべてクリア';

  @override
  String get noBeansMatchSearch => '検索に一致する豆がありません';

  @override
  String get clearFilters => 'フィルターをクリア';

  @override
  String get farmer => '農家';

  @override
  String get farm => '農場';

  @override
  String get enterFarmer => '農家名を入力 (オプション)';

  @override
  String get enterFarm => '農場名を入力 (オプション)';

  @override
  String get requiredInformation => '必要な情報';

  @override
  String get basicDetails => '基本詳細';

  @override
  String get qualityMeasurements => '品質と測定';

  @override
  String get importantDates => '重要な日程';

  @override
  String get brewStats => '抽出統計';

  @override
  String get showMore => 'もっと見る';

  @override
  String get showLess => '表示を減らす';

  @override
  String get unpublishRecipeDialogTitle => 'レシピを非公開にする';

  @override
  String get unpublishRecipeDialogMessage => '警告: このレシピを非公開にすると、次のようになります:';

  @override
  String get unpublishRecipeDialogBullet1 => '公開検索結果から削除されます';

  @override
  String get unpublishRecipeDialogBullet2 => '新しいユーザーがインポートできなくなります';

  @override
  String get unpublishRecipeDialogBullet3 => 'すでにインポートしたユーザーはコピーを保持します';

  @override
  String get unpublishRecipeDialogKeepPublic => '公開のままにする';

  @override
  String get unpublishRecipeDialogMakePrivate => '非公開にする';

  @override
  String get recipeUnpublishSuccess => 'レシピの公開を正常に停止しました';

  @override
  String recipeUnpublishError(String error) {
    return 'レシピの公開停止に失敗しました: $error';
  }

  @override
  String get recipePublicTooltip => 'レシピは公開中です - タップして非公開にします';

  @override
  String get recipePrivateTooltip => 'レシピは非公開です - 共有して公開します';
}
