// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get beansStatsSectionTitle => '咖啡豆统计';

  @override
  String get totalBeansBrewedLabel => '使用的咖啡豆总量';

  @override
  String get newBeansTriedLabel => '尝试的新咖啡豆';

  @override
  String get originsExploredLabel => '探索的产地';

  @override
  String get regionsExploredLabel => '探索的地区';

  @override
  String get newRoastersDiscoveredLabel => '发现的新烘焙商';

  @override
  String get favoriteRoastersLabel => '最喜爱的烘焙商';

  @override
  String get topOriginsLabel => '热门产地';

  @override
  String get topRegionsLabel => '热门地区';

  @override
  String get lastrecipe => '最近使用的食谱：';

  @override
  String get userRecipesTitle => '你的食谱';

  @override
  String get userRecipesSectionCreated => '你创建的';

  @override
  String get userRecipesSectionImported => '你导入的';

  @override
  String get userRecipesEmpty => '未找到食谱';

  @override
  String get userRecipesDeleteTitle => '删除食谱？';

  @override
  String get userRecipesDeleteMessage => '此操作无法撤销。';

  @override
  String get userRecipesDeleteConfirm => '删除';

  @override
  String get userRecipesDeleteCancel => '取消';

  @override
  String get userRecipesSnackbarDeleted => '已删除食谱';

  @override
  String get hubUserRecipesTitle => '你的食谱';

  @override
  String get hubUserRecipesSubtitle => '查看并管理你创建和导入的食谱';

  @override
  String get hubAccountSubtitle => '管理您的个人资料';

  @override
  String get hubSignInCreateSubtitle => '登录以同步配方和偏好设置';

  @override
  String get hubBrewDiarySubtitle => '查看您的冲泡历史并添加笔记';

  @override
  String get hubBrewStatsSubtitle => '查看个人和全球冲泡统计和趋势';

  @override
  String get hubSettingsSubtitle => '更改应用偏好和行为';

  @override
  String get hubAboutSubtitle => '应用详情、版本和贡献者';

  @override
  String get about => '关于';

  @override
  String get author => '作者';

  @override
  String get authortext =>
      'Timer.Coffee应用由咖啡爱好者、媒体专家和摄影记者安东·卡尔纳创建。希望这个应用能帮助您享受咖啡。欢迎在GitHub上贡献。';

  @override
  String get contributors => '贡献者';

  @override
  String get errorLoadingContributors => '加载贡献者时出错';

  @override
  String get license => '许可证';

  @override
  String get licensetext =>
      '这个应用程序是免费软件:您可以在自由软件基金会发布的GNU通用公共许可证条款下重新分发和/或修改它，不论是许可证的第3版，或（根据您的选择）任何后续版本。';

  @override
  String get licensebutton => '阅读GNU通用公共许可证v3';

  @override
  String get website => '网站';

  @override
  String get sourcecode => '源代码';

  @override
  String get support => '为开发者买一杯咖啡';

  @override
  String get allrecipes => '所有食谱';

  @override
  String get favoriterecipes => '喜爱的食谱';

  @override
  String get coffeeamount => '咖啡量（克）';

  @override
  String get wateramount => '水量（毫升）';

  @override
  String get watertemp => '水温';

  @override
  String get grindsize => '研磨粒度';

  @override
  String get brewtime => '冲泡时间';

  @override
  String get recipesummary => '食谱摘要';

  @override
  String get recipesummarynote => '注：这是一份基本食谱，包含默认的水和咖啡量。';

  @override
  String get preparation => '准备';

  @override
  String get brewingprocess => '冲泡过程';

  @override
  String get step => '步骤';

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
  String get finishmsg => '感谢您使用Timer.Coffee!请享用您的';

  @override
  String get coffeefact => '咖啡事实';

  @override
  String get home => '首页';

  @override
  String get appversion => '应用版本';

  @override
  String get tipsmall => '买一杯小咖啡';

  @override
  String get tipmedium => '买一杯中咖啡';

  @override
  String get tiplarge => '买一杯大咖啡';

  @override
  String get supportdevelopment => '支持开发';

  @override
  String get supportdevmsg =>
      '您的捐款有助于覆盖维护成本（例如开发者许可证等）。它们还使我能够尝试更多咖啡冲泡设备，并向应用中添加更多食谱。';

  @override
  String get supportdevtnx => '感谢您考虑捐赠！';

  @override
  String get donationok => '谢谢您！';

  @override
  String get donationtnx => '非常感谢您的支持！祝您冲泡出许多美味的咖啡！☕️';

  @override
  String get donationerr => '错误';

  @override
  String get donationerrmsg => '处理购买时出错，请重试。';

  @override
  String get sharemsg => '查看这个食谱：';

  @override
  String get finishbrew => '完成';

  @override
  String get settings => '設定';

  @override
  String get settingstheme => '主题';

  @override
  String get settingsthemelight => '浅色';

  @override
  String get settingsthemedark => '深色';

  @override
  String get settingsthemesystem => '系统';

  @override
  String get settingslang => '言語';

  @override
  String get sweet => '甜';

  @override
  String get balance => '平衡';

  @override
  String get acidic => '酸';

  @override
  String get light => '轻';

  @override
  String get strong => '强';

  @override
  String get slidertitle => '使用滑块调整口味';

  @override
  String get whatsnewtitle => '有什么新鲜事';

  @override
  String get whatsnewclose => '关闭';

  @override
  String get seasonspecials => '季节特惠';

  @override
  String get snow => '雪';

  @override
  String get noFavoriteRecipesMessage => '您的最爱食谱列表当前为空。开始探索和酿造，以发现您的最爱！';

  @override
  String get explore => '探索';

  @override
  String get dateFormat => 'yyyy年MMMd日';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get brewdiary => '酿造日记';

  @override
  String get brewdiarynotfound => '未找到条目';

  @override
  String get beans => '豆子';

  @override
  String get roaster => '烘焙机';

  @override
  String get rating => '评分';

  @override
  String get notes => '笔记';

  @override
  String get statsscreen => '咖啡统计';

  @override
  String get yourStats => '您的统计数据';

  @override
  String get coffeeBrewed => '咖啡冲泡：';

  @override
  String get litersUnit => '升';

  @override
  String get mostUsedRecipes => '最常用配方：';

  @override
  String get globalStats => '全球统计数据';

  @override
  String get unknownRecipe => '未知配方';

  @override
  String get noData => '无数据';

  @override
  String error(Object error) {
    return '错误：$error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return '有人刚刚冲泡了 $recipeName';
  }

  @override
  String get timePeriodToday => '今天';

  @override
  String get timePeriodThisWeek => '本周';

  @override
  String get timePeriodThisMonth => '本月';

  @override
  String get timePeriodCustom => '自定义';

  @override
  String get statsFor => '的统计信息 ';

  @override
  String get homescreenbrewcoffee => '冲泡咖啡';

  @override
  String get homescreenhub => '中心区';

  @override
  String get homescreenmore => '更';

  @override
  String get addBeans => '添加咖啡豆';

  @override
  String get removeBeans => '移除咖啡豆';

  @override
  String get name => '名称';

  @override
  String get origin => '产地';

  @override
  String get details => '详情';

  @override
  String get coffeebeans => '咖啡豆';

  @override
  String get loading => '加载中';

  @override
  String get nocoffeebeans => '未找到咖啡豆';

  @override
  String get delete => '删除';

  @override
  String get confirmDeleteTitle => '删除条目？';

  @override
  String get confirmDeleteMessage => '您确定要删除此条目吗？此操作无法撤销。';

  @override
  String get removeFavorite => '从收藏夹中移除';

  @override
  String get addFavorite => '添加到收藏夹';

  @override
  String get toggleEditMode => '切换编辑模式';

  @override
  String get coffeeBeansDetails => '咖啡豆详情';

  @override
  String get edit => '编辑';

  @override
  String get coffeeBeansNotFound => '未找到咖啡豆';

  @override
  String get basicInformation => '基本信息';

  @override
  String get geographyTerroir => '地理/风土';

  @override
  String get variety => '品种';

  @override
  String get region => '地区';

  @override
  String get elevation => '海拔';

  @override
  String get harvestDate => '收获日期';

  @override
  String get processing => '加工方式';

  @override
  String get processingMethod => '加工方法';

  @override
  String get roastDate => '烘焙日期';

  @override
  String get roastLevel => '烘焙程度';

  @override
  String get cuppingScore => '杯测评分';

  @override
  String get flavorProfile => '风味特征';

  @override
  String get tastingNotes => '品尝笔记';

  @override
  String get additionalNotes => '附加说明';

  @override
  String get noCoffeeBeans => '未找到咖啡豆';

  @override
  String get editCoffeeBeans => '编辑咖啡豆';

  @override
  String get addCoffeeBeans => '添加咖啡豆';

  @override
  String get showImagePicker => '显示图片选择器';

  @override
  String get pleaseNote => '请注意';

  @override
  String get firstTimePopupMessage =>
      '1. 我们使用外部服务来处理图像。继续操作即表示您同意此操作。\n2. 虽然我们不会存储您的图像，但请避免包含任何个人信息。\n3. 图像识别目前每月限制为 10 个令牌（1 个令牌 = 1 张图像）。此限制将来可能会更改。';

  @override
  String get ok => '好的';

  @override
  String get takePhoto => '拍照';

  @override
  String get selectFromPhotos => '从照片中选择';

  @override
  String get takeAdditionalPhoto => '再拍一张照片？';

  @override
  String get no => '否';

  @override
  String get yes => '是';

  @override
  String get selectedImages => '已选择的图像';

  @override
  String get selectedImage => '已选择的图像';

  @override
  String get backToSelection => '返回选择';

  @override
  String get next => '下一步';

  @override
  String get unexpectedErrorOccurred => '发生意外错误';

  @override
  String get tokenLimitReached => '抱歉，您本月用于图像识别的令牌限额已用完';

  @override
  String get noCoffeeLabelsDetected => '未检测到咖啡标签。请尝试使用其他图像。';

  @override
  String get collectedInformation => '收集到的信息';

  @override
  String get enterRoaster => '输入烘焙商';

  @override
  String get enterName => '输入名称';

  @override
  String get enterOrigin => '输入产地';

  @override
  String get optional => '可选';

  @override
  String get enterVariety => '输入品种';

  @override
  String get enterProcessingMethod => '输入加工方法';

  @override
  String get enterRoastLevel => '输入烘焙程度';

  @override
  String get enterRegion => '输入地区';

  @override
  String get enterTastingNotes => '输入品尝笔记';

  @override
  String get enterElevation => '输入海拔';

  @override
  String get enterCuppingScore => '输入杯测评分';

  @override
  String get enterNotes => '输入注释';

  @override
  String get inventory => '库存';

  @override
  String get amountLeft => '剩余数量';

  @override
  String get enterAmountLeft => '输入剩余数量';

  @override
  String get selectHarvestDate => '选择收获日期';

  @override
  String get selectRoastDate => '选择烘焙日期';

  @override
  String get selectDate => '选择日期';

  @override
  String get save => '保存';

  @override
  String get fillRequiredFields => '请填写所有必填字段。';

  @override
  String get analyzing => '分析中';

  @override
  String get errorMessage => '错误';

  @override
  String get selectCoffeeBeans => '选择咖啡豆';

  @override
  String get addNewBeans => '添加新豆子';

  @override
  String get favorite => '收藏';

  @override
  String get notFavorite => '未收藏';

  @override
  String get myBeans => '我的咖啡豆';

  @override
  String get signIn => '登入';

  @override
  String get signOut => '登出';

  @override
  String get signInWithApple => '使用 Apple 登录';

  @override
  String get signInSuccessful => '使用 Apple 登录成功';

  @override
  String get signInError => '使用 Apple 登录时出错';

  @override
  String get signInWithGoogle => '使用 Google 登录';

  @override
  String get signOutSuccessful => '成功退出';

  @override
  String get signInSuccessfulGoogle => '已使用 Google 帐户成功登录';

  @override
  String get signInWithEmail => '用電子郵件登入';

  @override
  String get enterEmail => '請輸入您的電子郵件';

  @override
  String get emailHint => '例： example@email.com';

  @override
  String get cancel => '取消';

  @override
  String get sendMagicLink => '傳送神奇連結';

  @override
  String get magicLinkSent => '神奇連結已發送！請查看您的電子郵件。';

  @override
  String get sendOTP => '发送一次性密码';

  @override
  String get otpSent => '一次性密码已发送到您的邮箱';

  @override
  String get otpSendError => '发送一次性密码出错';

  @override
  String get enterOTP => '输入一次性密码';

  @override
  String get otpHint => '输入 6 位数字代码';

  @override
  String get verify => '验证';

  @override
  String get signInSuccessfulEmail => '登录成功';

  @override
  String get invalidOTP => '无效的OTP';

  @override
  String get otpVerificationError => 'OTP验证错误';

  @override
  String get success => '成功！';

  @override
  String get otpSentMessage => '一个一次性密码已发送至您的邮箱。收到后，请在下方输入。';

  @override
  String get otpHint2 => '輸入代碼';

  @override
  String get signInCreate => '登录 / 创建帐户';

  @override
  String get accountManagement => '账户管理';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get deleteAccountWarning =>
      '请注意：如果您选择继续，我们将从我们的服务器上删除您的账户和相关数据。数据的本地副本将保留在设备上，如果您也想删除它，可以简单地删除应用程序。为了重新启用同步，您需要重新创建一个账户。';

  @override
  String get deleteAccountConfirmation => '成功删除账户';

  @override
  String get accountDeleted => '账户已删除';

  @override
  String get accountDeletionError => '删除账户时出错，请重试';

  @override
  String get deleteAccountTitle => '重要';

  @override
  String get selectBeans => '选择咖啡豆';

  @override
  String get all => '全部';

  @override
  String get selectRoaster => '选择烘焙商';

  @override
  String get selectOrigin => '选择产地';

  @override
  String get resetFilters => '重置筛选';

  @override
  String get showFavoritesOnly => '仅显示收藏';

  @override
  String get apply => '应用';

  @override
  String get selectSize => '选择大小';

  @override
  String get sizeStandard => '标准';

  @override
  String get sizeMedium => '中等';

  @override
  String get sizeXL => '加大';

  @override
  String get yearlyStatsAppBarTitle => '我与 Timer.Coffee 的一年';

  @override
  String get yearlyStatsStory1Text => '嘿，感谢您今年成为 Timer.Coffee 世界的一部分！';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return '首先...\n您今年煮了一些咖啡$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return '更准确地说，\n您在 2024 年煮了 $liters 升咖啡！';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return '您使用了来自 $roasterCount 个烘焙商的咖啡豆';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return '您的前 3 名烘焙商是：\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return '咖啡带您踏上了环游世界之旅$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return '您品尝了来自\n$originCount 个国家的咖啡豆！';
  }

  @override
  String get yearlyStatsStory7Part1 => '您并不孤单在冲煮咖啡……';

  @override
  String get yearlyStatsStory7Part2 => '……还有来自 6 大洲 110 个\n其他国家的用户！';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return '您忠于自己，今年只使用了这 $count 种冲煮方法：';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return '您在探索新口味，今年使用了 $count 种冲煮方法：';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return '您是一位真正的咖啡探索者，今年使用了 $count 种冲煮方法：';
  }

  @override
  String get yearlyStatsStory9Text => '还有很多东西有待发现！';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return '您在 2024 年的前三名配方是$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => '2025 年再见！';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return '点赞 ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => '捐赠';

  @override
  String get yearlyStatsActionShare => '分享您的进度';

  @override
  String get yearlyStatsUnknown => '未知';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return '分享失败：$error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => '我与 Timer.Coffee 的一年';

  @override
  String get yearlyStatsShareProgressTop3Recipes => '我的最爱前 3 名配方：';

  @override
  String get yearlyStatsShareProgressTop3Roasters => '我的最爱前 3 名烘焙商：';

  @override
  String get yearlyStatsFailedToLike => '点赞失败。请重试。';

  @override
  String get labelCoffeeBrewed => '冲煮的咖啡';

  @override
  String get labelTastedBeansBy => '品尝过的咖啡豆烘焙商';

  @override
  String get labelDiscoveredCoffeeFrom => '发现的咖啡产地';

  @override
  String get labelUsedBrewingMethods => '使用过的';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '家烘焙商',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '个国家/地区',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '种冲煮方法',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => '编辑食谱';

  @override
  String get recipeCreationScreenCreateRecipeTitle => '创建食谱';

  @override
  String get recipeCreationScreenRecipeStepsTitle => '食谱步骤';

  @override
  String get recipeCreationScreenRecipeNameLabel => '食谱名称';

  @override
  String get recipeCreationScreenShortDescriptionLabel => '简短描述';

  @override
  String get recipeCreationScreenBrewingMethodLabel => '冲煮方法';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => '咖啡量 (克)';

  @override
  String get recipeCreationScreenWaterAmountLabel => '水量 (毫升)';

  @override
  String get recipeCreationScreenWaterTempLabel => '水温 (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => '研磨粒度';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => '总冲煮时间:';

  @override
  String get recipeCreationScreenMinutesLabel => '分钟';

  @override
  String get recipeCreationScreenSecondsLabel => '秒';

  @override
  String get recipeCreationScreenPreparationStepTitle => '准备步骤';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return '冲煮步骤 $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => '步骤描述';

  @override
  String get recipeCreationScreenStepTimeLabel => '步骤时间: ';

  @override
  String get recipeCreationScreenRecipeNameValidator => '请输入食谱名称';

  @override
  String get recipeCreationScreenShortDescriptionValidator => '请输入简短描述';

  @override
  String get recipeCreationScreenBrewingMethodValidator => '请选择冲煮方法';

  @override
  String get recipeCreationScreenRequiredValidator => '必填';

  @override
  String get recipeCreationScreenInvalidNumberValidator => '无效数字';

  @override
  String get recipeCreationScreenStepDescriptionValidator => '请输入步骤描述';

  @override
  String get recipeCreationScreenContinueButton => '继续至食谱步骤';

  @override
  String get recipeCreationScreenAddStepButton => '添加步骤';

  @override
  String get recipeCreationScreenSaveRecipeButton => '保存食谱';

  @override
  String get recipeCreationScreenUpdateSuccess => '食谱更新成功';

  @override
  String get recipeCreationScreenSaveSuccess => '食谱保存成功';

  @override
  String recipeCreationScreenSaveError(String error) {
    return '保存食谱时出错: $error';
  }

  @override
  String get unitGramsShort => '克';

  @override
  String get unitMillilitersShort => '毫升';

  @override
  String get unitGramsLong => '克';

  @override
  String get unitMillilitersLong => '毫升';

  @override
  String get recipeCopySuccess => '配方复制成功！';

  @override
  String recipeCopyError(String error) {
    return '复制配方时出错：$error';
  }

  @override
  String get createRecipe => '创建配方';

  @override
  String errorSyncingData(Object error) {
    return '数据同步错误：$error';
  }

  @override
  String errorSigningOut(Object error) {
    return '退出登录错误：$error';
  }

  @override
  String get defaultPreparationStepDescription => '准备';

  @override
  String get loadingEllipsis => '加载中...';

  @override
  String get recipeDeletedSuccess => '配方已成功删除';

  @override
  String recipeDeleteError(Object error) {
    return '删除配方失败：$error';
  }

  @override
  String get noRecipesFound => '未找到配方';

  @override
  String recipeLoadError(Object error) {
    return '加载配方失败：$error';
  }

  @override
  String get unknownBrewingMethod => '未知的冲煮方法';

  @override
  String get recipeCopyErrorLoadingEdit => '加载复制的配方进行编辑失败。';

  @override
  String get recipeCopyErrorOperationFailed => '操作失败。';

  @override
  String get notProvided => '未提供';

  @override
  String get recipeUpdateFailedFetch => '获取更新的食谱数据失败。';

  @override
  String get recipeImportSuccess => '食谱导入成功！';

  @override
  String get recipeImportFailedSave => '保存导入的食谱失败。';

  @override
  String get recipeImportFailedFetch => '获取导入的食谱数据失败。';

  @override
  String get recipeNotImported => '食谱未导入。';

  @override
  String get recipeNotFoundCloud => '在云端找不到食谱或食谱未公开。';

  @override
  String get recipeLoadErrorGeneric => '加载食谱时出错。';

  @override
  String get recipeUpdateAvailableTitle => '有可用的更新';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return '在线提供了“$recipeName”的新版本。是否更新？';
  }

  @override
  String get dialogCancel => '取消';

  @override
  String get dialogUpdate => '更新';

  @override
  String get recipeImportTitle => '导入食谱';

  @override
  String recipeImportBody(String recipeName) {
    return '您想从云端导入食谱“$recipeName”吗？';
  }

  @override
  String get dialogImport => '导入';

  @override
  String get moderationReviewNeededTitle => '需要审核';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return '由于内容审核问题，以下食谱需要审核：$recipeNames';
  }

  @override
  String get dismiss => '忽略';

  @override
  String get reviewRecipeButton => '审核食谱';

  @override
  String get signInRequiredTitle => '需要登录';

  @override
  String get signInRequiredBodyShare => '您需要登录才能分享您自己的食谱。';

  @override
  String get syncSuccess => '同步成功！';

  @override
  String get tooltipEditRecipe => '编辑食谱';

  @override
  String get tooltipCopyRecipe => '复制食谱';

  @override
  String get tooltipShareRecipe => '分享食谱';

  @override
  String get signInRequiredSnackbar => '需要登录';

  @override
  String get moderationErrorFunction => '内容审核检查失败。';

  @override
  String get moderationReasonDefault => '内容已标记待审核。';

  @override
  String get moderationFailedTitle => '审核失败';

  @override
  String moderationFailedBody(String reason) {
    return '此食谱无法分享，原因：$reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return '分享食谱时出错：$error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return '$recipeName 在 Timer.Coffee 上';
  }

  @override
  String get saveLocallyCheckLater => '无法检查内容状态。已在本地保存，将在下次同步时检查。';

  @override
  String get saveLocallyModerationFailedTitle => '更改已在本地保存';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return '您的本地更改已保存，但由于内容审核，公共版本无法更新：$reason';
  }

  @override
  String get editImportedRecipeTitle => '编辑导入的配方';

  @override
  String get editImportedRecipeBody => '这是一个导入的配方。编辑它将创建一个新的独立副本。您想继续吗？';

  @override
  String get editImportedRecipeButtonCopy => '创建副本并编辑';

  @override
  String get editImportedRecipeButtonCancel => '取消';

  @override
  String get editDisplayNameTitle => '编辑显示名称';

  @override
  String get displayNameHint => '输入您的显示名称';

  @override
  String get displayNameEmptyError => '显示名称不能为空';

  @override
  String get displayNameTooLongError => '显示名称不能超过 50 个字符';

  @override
  String get errorUserNotLoggedIn => '用户未登录。请重新登录。';

  @override
  String get displayNameUpdateSuccess => '显示名称更新成功！';

  @override
  String displayNameUpdateError(String error) {
    return '更新显示名称失败：$error';
  }

  @override
  String get deletePictureConfirmationTitle => '删除图片？';

  @override
  String get deletePictureConfirmationBody => '您确定要删除您的个人资料图片吗？';

  @override
  String get deletePictureSuccess => '个人资料图片已删除。';

  @override
  String deletePictureError(String error) {
    return '删除个人资料图片失败：$error';
  }

  @override
  String updatePictureError(String error) {
    return '更新个人资料图片失败：$error';
  }

  @override
  String get updatePictureSuccess => '个人资料图片更新成功！';

  @override
  String get deletePictureTooltip => '删除图片';

  @override
  String get account => '账户';

  @override
  String get settingsBrewingMethodsTitle => '主屏幕冲泡方法';

  @override
  String get filter => '筛选';

  @override
  String get sortBy => '排序方式';

  @override
  String get dateAdded => '添加日期';

  @override
  String get secondsAbbreviation => '秒';

  @override
  String get settingsAppIcon => '应用图标';

  @override
  String get settingsAppIconDefault => '默认';

  @override
  String get settingsAppIconLegacy => '旧版';

  @override
  String get searchBeans => '搜索咖啡豆...';

  @override
  String get favorites => '收藏';

  @override
  String get searchPrefix => '搜索：';

  @override
  String get clearAll => '全部清除';

  @override
  String get noBeansMatchSearch => '没有匹配您搜索的咖啡豆';

  @override
  String get clearFilters => '清除过滤器';

  @override
  String get farmer => '农民';

  @override
  String get farm => '农场';

  @override
  String get enterFarmer => '输入农民（可选）';

  @override
  String get enterFarm => '输入农场（可选）';

  @override
  String get requiredInformation => '必填信息';

  @override
  String get basicDetails => '基本信息';

  @override
  String get qualityMeasurements => '质量与测量';

  @override
  String get importantDates => '重要日期';

  @override
  String get brewStats => '冲泡统计';

  @override
  String get showMore => '显示更多';

  @override
  String get showLess => '显示更少';

  @override
  String get unpublishRecipeDialogTitle => '将配方设为私有';

  @override
  String get unpublishRecipeDialogMessage => '警告：将此配方设为私有将导致：';

  @override
  String get unpublishRecipeDialogBullet1 => '它将从公共搜索结果中删除';

  @override
  String get unpublishRecipeDialogBullet2 => '新用户将无法导入';

  @override
  String get unpublishRecipeDialogBullet3 => '已经导入的用户将保留其副本';

  @override
  String get unpublishRecipeDialogKeepPublic => '保持公开';

  @override
  String get unpublishRecipeDialogMakePrivate => '设为私有';

  @override
  String get recipeUnpublishSuccess => '配方已成功取消发布';

  @override
  String recipeUnpublishError(String error) {
    return '取消发布配方失败：$error';
  }

  @override
  String get recipePublicTooltip => '配方是公开的 - 点击设为私有';

  @override
  String get recipePrivateTooltip => '配方是私有的 - 分享以公开';

  @override
  String get fieldClearButtonTooltip => '清除';

  @override
  String get dateFieldClearButtonTooltip => '清除日期';

  @override
  String get chipInputDuplicateError => '此标签已添加';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return '已达到最大标签数量 ($maxChips)';
  }

  @override
  String get chipInputHintText => '添加标签...';

  @override
  String get unitFieldRequiredError => '此字段为必填项';

  @override
  String get unitFieldInvalidNumberError => '请输入有效数字';

  @override
  String unitFieldMinValueError(Object min) {
    return '值必须至少为 $min';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return '值必须至多为 $max';
  }

  @override
  String get numericFieldRequiredError => '此字段为必填项';

  @override
  String get numericFieldInvalidNumberError => '请输入有效数字';

  @override
  String numericFieldMinValueError(Object min) {
    return '值必须至少为 $min';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return '值必须至多为 $max';
  }

  @override
  String get dropdownSearchHintText => '输入以搜索...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return '加载建议时出错：$error';
  }

  @override
  String get dropdownSearchNoResults => '未找到结果';

  @override
  String get dropdownSearchLoading => '搜索中...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return '使用 \"$currentQuery\"';
  }

  @override
  String get requiredInfoSubtitle => '* 必填';

  @override
  String get inventoryWeightExample => '例如：250.5';

  @override
  String get unsavedChangesTitle => '未保存的更改';

  @override
  String get unsavedChangesMessage => '您有未保存的更改。您确定要丢弃它们吗？';

  @override
  String get unsavedChangesStay => '留下';

  @override
  String get unsavedChangesDiscard => '丢弃';

  @override
  String beansWeightAddedBack(
      String amount, String beanName, String newWeight, String unit) {
    return '已将 $amount$unit 添加回 $beanName。新重量：$newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
      String amount, String beanName, String newWeight, String unit) {
    return '已从 $beanName 中减去 $amount$unit。新重量：$newWeight$unit';
  }
}
