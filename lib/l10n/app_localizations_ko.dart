// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get beansStatsSectionTitle => '원두 통계';

  @override
  String get totalBeansBrewedLabel => '사용한 원두 총량';

  @override
  String get newBeansTriedLabel => '처음 시도한 원두';

  @override
  String get originsExploredLabel => '탐색된 원산지';

  @override
  String get regionsExploredLabel => '유럽';

  @override
  String get newRoastersDiscoveredLabel => '새로운 로스터리 발견';

  @override
  String get favoriteRoastersLabel => '좋아하는 로스터리';

  @override
  String get topOriginsLabel => '상위 원산지';

  @override
  String get topRegionsLabel => '상위 지역';

  @override
  String get lastrecipe => '가장 최근 사용된 레시피:';

  @override
  String get userRecipesTitle => '내 레시피';

  @override
  String get userRecipesSectionCreated => '당신이 만든';

  @override
  String get userRecipesSectionImported => '당신이 가져온';

  @override
  String get userRecipesEmpty => '레시피를 찾을 수 없습니다';

  @override
  String get userRecipesDeleteTitle => '레시피 삭제';

  @override
  String get userRecipesDeleteMessage => '이 작업은 되돌릴 수 없습니다.';

  @override
  String get userRecipesDeleteConfirm => '삭제';

  @override
  String get userRecipesDeleteCancel => '취소';

  @override
  String get userRecipesSnackbarDeleted => '레시피가 삭제되었습니다';

  @override
  String get hubUserRecipesTitle => '내 레시피';

  @override
  String get hubUserRecipesSubtitle => '생성 및 가져온 레시피 보기 및 관리';

  @override
  String get hubAccountSubtitle => '프로필 관리';

  @override
  String get hubSignInCreateSubtitle => '레시피와 선호 설정 동기화 위해 로그인';

  @override
  String get hubBrewDiarySubtitle => '추출 기록 보기 및 노트 추가';

  @override
  String get hubBrewStatsSubtitle => '개인 및 글로벌 추출 통계 및 추세 보기';

  @override
  String get hubSettingsSubtitle => '앱 선호 및 동작 변경';

  @override
  String get hubAboutSubtitle => '앱 세부 정보, 버전 및 기여자';

  @override
  String get about => '정보';

  @override
  String get author => '작성자';

  @override
  String get authortext =>
      'Timer.Coffee 앱은 커피 애호가, 미디어 전문가, 사진 저널리스트인 Anton Karliner가 만들었습니다. 이 앱이 커피를 즐기는 데 도움이 되기를 바랍니다. GitHub에서 기여하세요.';

  @override
  String get contributors => '기여자';

  @override
  String get errorLoadingContributors => '기여자 로드 오류';

  @override
  String get license => '라이선스';

  @override
  String get licensetext =>
      '이 애플리케이션은 자유 소프트웨어입니다: GNU General Public License 버전 3 또는 (선택에 따라) 이후 버전의 조건에 따라 재배포 및 수정할 수 있습니다.';

  @override
  String get licensebutton => 'GNU General Public License v3 읽기';

  @override
  String get website => '웹사이트';

  @override
  String get sourcecode => '소스 코드';

  @override
  String get support => '커피 사주기';

  @override
  String get allrecipes => '모든 레시피';

  @override
  String get favoriterecipes => '좋아하는 레시피';

  @override
  String get coffeeamount => '커피 양 (g)';

  @override
  String get wateramount => '물 양 (ml)';

  @override
  String get watertemp => '물 온도';

  @override
  String get grindsize => '분쇄도';

  @override
  String get brewtime => '추출 시간';

  @override
  String get recipesummary => '레시피 요약';

  @override
  String get recipesummarynote => '참고: 이는 기본 레시피로 기본 물 및 커피 양입니다.';

  @override
  String get preparation => '준비';

  @override
  String get brewingprocess => '추출 과정';

  @override
  String get step => '단계';

  @override
  String seconds(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '초',
      one: '초',
      zero: '초',
    );
    return '$_temp0';
  }

  @override
  String get finishmsg => 'Timer.Coffee 사용 감사해요! 즐거운';

  @override
  String get coffeefact => '커피 사실';

  @override
  String get home => '홈';

  @override
  String get appversion => '앱 버전';

  @override
  String get tipsmall => '작은 커피 사기';

  @override
  String get tipmedium => '중간 커피 사기';

  @override
  String get tiplarge => '큰 커피 사기';

  @override
  String get supportdevelopment => '개발 지원';

  @override
  String get supportdevmsg =>
      '기부는 유지 비용 (예: 개발자 라이선스)을 충당하는 데 도움이 돼요 또한 더 많은 커피 추출 기기와 레시피를 앱에 추가할 수 있게 해요';

  @override
  String get supportdevtnx => '기부 고려 감사해요!';

  @override
  String get donationok => '감사해요!';

  @override
  String get donationtnx => '지원에 정말 감사해요! 훌륭한 추출를 기원해요! ☕️';

  @override
  String get donationerr => '오류';

  @override
  String get donationerrmsg => '구매 처리 오류, 다시 시도하세요.';

  @override
  String get sharemsg => '이 레시피 확인:';

  @override
  String get finishbrew => '완료';

  @override
  String get settings => '설정';

  @override
  String get settingstheme => '테마';

  @override
  String get settingsthemelight => '라이트';

  @override
  String get settingsthemedark => '다크';

  @override
  String get settingsthemesystem => '시스템';

  @override
  String get settingslang => '언어';

  @override
  String get sweet => '달콤한';

  @override
  String get balance => '균형';

  @override
  String get acidic => '신맛';

  @override
  String get light => '라이트';

  @override
  String get strong => '스트롱';

  @override
  String get slidertitle => '맛 조정을 위한 슬라이더 사용';

  @override
  String get whatsnewtitle => '새로운 기능';

  @override
  String get whatsnewclose => '닫기';

  @override
  String get seasonspecials => '시즌 특선';

  @override
  String get snow => '눈';

  @override
  String get noFavoriteRecipesMessage =>
      '좋아하는 레시피 목록이 비어 있습니다. 탐색하고 추출하여 좋아하는 것을 발견하세요!';

  @override
  String get explore => '탐색';

  @override
  String get dateFormat => 'MMM d, yyyy';

  @override
  String get timeFormat => 'hh:mm a';

  @override
  String get brewdiary => '브루잉 일지';

  @override
  String get brewdiarynotfound => '항목을 찾을 수 없습니다';

  @override
  String get beans => '원두';

  @override
  String get roaster => '로스터리';

  @override
  String get rating => '평점';

  @override
  String get notes => '노트';

  @override
  String get statsscreen => '커피 통계';

  @override
  String get yourStats => '내 통계';

  @override
  String get coffeeBrewed => '추출된 커피:';

  @override
  String get litersUnit => 'L';

  @override
  String get mostUsedRecipes => '가장 많이 사용된 레시피:';

  @override
  String get globalStats => '글로벌 통계';

  @override
  String get unknownRecipe => '알 수 없는 레시피';

  @override
  String get noData => '데이터 없음';

  @override
  String error(String error) {
    return '오류: $error';
  }

  @override
  String someoneJustBrewed(Object recipeName) {
    return '누군가 $recipeName을(를) 방금 추출했어요';
  }

  @override
  String get timePeriodToday => '오늘';

  @override
  String get timePeriodThisWeek => '이번 주';

  @override
  String get timePeriodThisMonth => '이번 달';

  @override
  String get timePeriodCustom => '사용자 지정';

  @override
  String get statsFor => '통계';

  @override
  String get homescreenbrewcoffee => '커피 내리기';

  @override
  String get homescreenhub => '허브';

  @override
  String get homescreenmore => '더 보기';

  @override
  String get addBeans => '원두 추가';

  @override
  String get removeBeans => '원두 제거';

  @override
  String get name => '이름';

  @override
  String get origin => '원산지';

  @override
  String get details => '세부 정보';

  @override
  String get coffeebeans => '커피 원두';

  @override
  String get loading => '로딩 중';

  @override
  String get nocoffeebeans => '원두를 찾을 수 없습니다';

  @override
  String get delete => '삭제';

  @override
  String get confirmDeleteTitle => '항목 삭제';

  @override
  String get recipeDuplicateConfirmTitle => '레시피를 복제하시겠습니까?';

  @override
  String get recipeDuplicateConfirmMessage =>
      '이 작업을 수행하면 레시피 사본이 생성되어 독립적으로 편집할 수 있습니다. 계속하시겠습니까?';

  @override
  String get confirmDeleteMessage => '이 항목을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';

  @override
  String get removeFavorite => '좋아하는 목록에서 제거';

  @override
  String get addFavorite => '좋아하는 목록에 추가';

  @override
  String get toggleEditMode => '편집 모드 토글';

  @override
  String get coffeeBeansDetails => '커피 원두 세부 정보';

  @override
  String get edit => '편집';

  @override
  String get coffeeBeansNotFound => '원두를 찾을 수 없습니다';

  @override
  String get basicInformation => '기본 정보';

  @override
  String get geographyTerroir => '지리/테루아';

  @override
  String get variety => '품종';

  @override
  String get region => '북아메리카';

  @override
  String get elevation => '고도';

  @override
  String get harvestDate => '수확 날짜';

  @override
  String get processing => '가공';

  @override
  String get processingMethod => '가공 방법';

  @override
  String get roastDate => '로스팅 날짜';

  @override
  String get roastLevel => '로스팅 레벨';

  @override
  String get cuppingScore => '컵핑 점수';

  @override
  String get flavorProfile => '풍미 프로필';

  @override
  String get tastingNotes => '시음 노트';

  @override
  String get additionalNotes => '추가 노트';

  @override
  String get noCoffeeBeans => '원두를 찾을 수 없습니다';

  @override
  String get editCoffeeBeans => '커피 원두 편집';

  @override
  String get addCoffeeBeans => '커피 원두 추가';

  @override
  String get showImagePicker => '이미지 선택기 표시';

  @override
  String get pleaseNote => '주의';

  @override
  String get firstTimePopupMessage =>
      '1. 이미지를 처리하기 위해 외부 서비스를 사용해요 계속하면 이에 동의해요\n2. 이미지를 저장하지 않지만 개인 세부 정보를 포함하지 마세요.\n3. 이미지 인식은 현재 월 10 토큰으로 제한돼요 (1 토큰 = 1 이미지). 이 제한은 변경될 수 있습니다.';

  @override
  String get ok => '확인';

  @override
  String get takePhoto => '사진 찍기';

  @override
  String get selectFromPhotos => '사진에서 선택';

  @override
  String get takeAdditionalPhoto => '추가 사진 찍기?';

  @override
  String get no => '아니오';

  @override
  String get yes => '예';

  @override
  String get selectedImages => '선택된 이미지';

  @override
  String get selectedImage => '선택된 이미지';

  @override
  String get backToSelection => '선택으로 돌아가기';

  @override
  String get next => '다음';

  @override
  String get unexpectedErrorOccurred => '예상치 못한 오류 발생';

  @override
  String get tokenLimitReached => '죄송해요, 이번 달 이미지 인식 토큰 한도에 도달했어요';

  @override
  String get noCoffeeLabelsDetected => '커피 라벨을 감지할 수 없습니다. 다른 이미지로 시도하기';

  @override
  String get collectedInformation => '수집된 정보';

  @override
  String get enterRoaster => '로스터리 이름 입력';

  @override
  String get enterName => '이름 입력';

  @override
  String get enterOrigin => '원산지 입력';

  @override
  String get optional => '선택';

  @override
  String get enterVariety => '품종 입력';

  @override
  String get enterProcessingMethod => '가공 방법 입력';

  @override
  String get enterRoastLevel => '로스팅 레벨 입력';

  @override
  String get enterRegion => '지역 입력';

  @override
  String get enterTastingNotes => '시음 노트 입력';

  @override
  String get enterElevation => '고도 입력';

  @override
  String get enterCuppingScore => '컵핑 점수 입력';

  @override
  String get enterNotes => '노트 입력';

  @override
  String get inventory => '재고';

  @override
  String get amountLeft => '남은 양';

  @override
  String get enterAmountLeft => '남은 양을 입력하세요';

  @override
  String get selectHarvestDate => '수확 날짜 선택';

  @override
  String get selectRoastDate => '로스팅 날짜 선택';

  @override
  String get selectDate => '날짜 선택';

  @override
  String get save => '저장';

  @override
  String get fillRequiredFields => '모든 필수 필드를 채워주세요.';

  @override
  String get analyzing => '분석 중';

  @override
  String get errorMessage => '오류';

  @override
  String get selectCoffeeBeans => '커피 원두 선택';

  @override
  String get addNewBeans => '새 원두 추가';

  @override
  String get favorite => '좋아함';

  @override
  String get notFavorite => '좋아하지 않음';

  @override
  String get myBeans => '내 원두';

  @override
  String get signIn => '로그인';

  @override
  String get signOut => '로그아웃';

  @override
  String get signInWithApple => 'Apple로 로그인';

  @override
  String get signInSuccessful => 'Apple로 성공적으로 로그인';

  @override
  String get signInError => 'Apple 로그인 오류';

  @override
  String get signInErrorGoogle => 'Google 로그인 오류';

  @override
  String get signInWithGoogle => 'Google로 로그인';

  @override
  String get signOutSuccessful => '성공적으로 로그아웃';

  @override
  String get signOutConfirmationTitle => '로그아웃하시겠습니까?';

  @override
  String get signOutConfirmationMessage =>
      '클라우드 동기화가 중지됩니다. 다시 시작하려면 다시 로그인하세요.';

  @override
  String get signInSuccessfulGoogle => 'Google로 성공적으로 로그인';

  @override
  String get signInWithEmail => '이메일로 로그인';

  @override
  String get enterEmail => '이메일 입력';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get cancel => '취소';

  @override
  String get sendMagicLink => '매직 링크 보내기';

  @override
  String get magicLinkSent => '매직 링크가 발송되었어요! 이메일을 확인하세요.';

  @override
  String get sendOTP => 'OTP 보내기';

  @override
  String get otpSent => 'OTP가 이메일로 발송되었어요';

  @override
  String get otpSendError => 'OTP 발송 오류';

  @override
  String get enterOTP => 'OTP 입력';

  @override
  String get otpHint => '6자리 코드 입력';

  @override
  String get verify => '확인';

  @override
  String get signInSuccessfulEmail => '로그인 성공';

  @override
  String get invalidOTP => '잘못된 OTP';

  @override
  String get otpVerificationError => 'OTP 확인 오류';

  @override
  String get success => '성공!';

  @override
  String get otpSentMessage => 'OTP가 이메일로 발송 중입니다. 받으면 아래에 입력하세요.';

  @override
  String get otpHint2 => '여기에 코드 입력';

  @override
  String get signInCreate => '로그인 / 계정 생성';

  @override
  String get accountManagement => '계정 관리';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get deleteAccountWarning =>
      '주의: 계속하면 서버에서 계정 및 관련 데이터를 삭제해요 로컬 데이터는 기기를 삭제하면 제거돼요 동기화를 다시 활성화하려면 계정을 다시 생성하세요';

  @override
  String get deleteAccountConfirmation => '계정 삭제 성공';

  @override
  String get accountDeleted => '계정 삭제됨';

  @override
  String get accountDeletionError => '계정 삭제 오류, 다시 시도하세요';

  @override
  String get deleteAccountTitle => '중요';

  @override
  String get selectBeans => '원두 선택';

  @override
  String get all => '모두';

  @override
  String get selectRoaster => '로스터리 선택';

  @override
  String get selectOrigin => '원산지 선택';

  @override
  String get resetFilters => '필터 재설정';

  @override
  String get showFavoritesOnly => '좋아하는 것만 표시';

  @override
  String get apply => '적용';

  @override
  String get selectSize => '크기 선택';

  @override
  String get sizeStandard => '표준';

  @override
  String get sizeMedium => '중간';

  @override
  String get sizeXL => 'XL';

  @override
  String get yearlyStatsAppBarTitle => 'Timer.Coffee와 함께한 내 1년';

  @override
  String get yearlyStatsStory1Text => '올해 Timer.Coffee 세계의 일부가 되어 감사해요!';

  @override
  String yearlyStatsStory2Text(Object ellipsis) {
    return '우선,\n올해 커피를 추출했어요$ellipsis';
  }

  @override
  String yearlyStatsStory3Text(Object liters) {
    return '더 정확히 말하면,\n2024년에 커피를 $liters리터 추출했어요!';
  }

  @override
  String yearlyStatsStory4Text(Object roasterCount) {
    return '$roasterCount곳 로스터리의 원두를 사용했어요';
  }

  @override
  String yearlyStatsStory4Top3Roasters(Object top3) {
    return '상위 로스터리 3곳:\n$top3';
  }

  @override
  String yearlyStatsStory5Text(Object ellipsis) {
    return '커피가 세계 여행으로 데려갔습니다\n$ellipsis';
  }

  @override
  String yearlyStatsStory6Text(Object originCount) {
    return '$originCount개국의 원두를 맛보았습니다!';
  }

  @override
  String get yearlyStatsStory7Part1 => '혼자 추출하지 않았습니다…';

  @override
  String get yearlyStatsStory7Part2 => '…6 대륙의 110개 다른 국가 사용자와 함께!';

  @override
  String yearlyStatsStory8TitleLow(Object count) {
    return '올해 이 $count 추출 방법을 고수했습니다:';
  }

  @override
  String yearlyStatsStory8TitleMedium(Object count) {
    return '새로운 맛을 발견하며 올해 $count 추출 방법을 사용했습니다:';
  }

  @override
  String yearlyStatsStory8TitleHigh(Object count) {
    return '진정한 커피 탐색가로서 올해 $count 추출 방법을 사용했습니다:';
  }

  @override
  String get yearlyStatsStory9Text => '발견할 게 더 많아요!';

  @override
  String yearlyStatsStory10Text(Object ellipsis) {
    return '2024년 상위 3 레시피$ellipsis';
  }

  @override
  String get yearlyStatsFinalText => '2025년에 만나요!';

  @override
  String yearlyStatsActionLove(Object likesCount) {
    return '사랑 보여주기 ($likesCount)';
  }

  @override
  String get yearlyStatsActionDonate => '기부';

  @override
  String get yearlyStatsActionShare => '진행 상황 공유';

  @override
  String get yearlyStatsUnknown => '알 수 없음';

  @override
  String yearlyStatsErrorSharing(Object error) {
    return '공유 실패: $error';
  }

  @override
  String get yearlyStatsShareProgressMyYear => 'Timer.Coffee와 함께한 내 1년';

  @override
  String get yearlyStatsShareProgressTop3Recipes => '내 상위 3 레시피:';

  @override
  String get yearlyStatsShareProgressTop3Roasters => '내 상위 로스터리 3곳:';

  @override
  String get yearlyStats25AppBarTitle => 'Timer.Coffee와 함께한 한 해 – 2025';

  @override
  String get yearlyStats25AppBarTitleSimple => '2025년 Timer.Coffee';

  @override
  String get yearlyStats25Slide1Title => 'Timer.Coffee와 함께한 한 해';

  @override
  String get yearlyStats25Slide1Subtitle => '2025년에 어떻게 추출했는지 보려면 탭하세요';

  @override
  String get yearlyStats25Slide2Intro => '함께 커피를 추출했어요...';

  @override
  String yearlyStats25Slide2Count(String count) {
    return '$count번';
  }

  @override
  String yearlyStats25Slide2Liters(String liters) {
    return '대략 $liters리터의 커피예요';
  }

  @override
  String get yearlyStats25Slide2Cambridge =>
      '영국 케임브리지의 모든 사람에게 커피 한 잔씩 줄 수 있는 양이에요(특히 학생들이 좋아할 거예요).';

  @override
  String get yearlyStats25Slide3Title => '당신은요?';

  @override
  String yearlyStats25Slide3Subtitle(String brews, String liters) {
    return '올해 Timer.Coffee로 $brews번 커피를 추출했어요. 총 $liters리터예요!';
  }

  @override
  String yearlyStats25Slide3TopBadge(int topPct) {
    return '커피 추출 상위 $topPct%예요!';
  }

  @override
  String get yearlyStats25Slide4TitleSingle => '올해 가장 많이 커피를 추출한 날을 기억하나요?';

  @override
  String get yearlyStats25Slide4TitleMulti => '올해 가장 많이 커피를 추출한 날들을 기억하나요?';

  @override
  String get yearlyStats25Slide4TitleBrewTime => '올해의 추출 시간';

  @override
  String get yearlyStats25Slide4ScratchLabel => '긁어서 확인하기';

  @override
  String yearlyStats25BrewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count회 추출',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25Slide4PeakSingle(String date, String brewsLabel) {
    return '$date — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4PeakLiters(String liters) {
    return '그날은 약 $liters리터';
  }

  @override
  String yearlyStats25Slide4PeakMostRecent(
      String mostRecent, String brewsLabel) {
    return '가장 최근: $mostRecent — $brewsLabel';
  }

  @override
  String yearlyStats25Slide4BrewTimeLine(String timeLabel) {
    return '추출에 $timeLabel 썼어요';
  }

  @override
  String get yearlyStats25Slide4BrewTimeFooter => '잘 쓴 시간이네요';

  @override
  String get yearlyStats25Slide5Title => '이렇게 추출해요';

  @override
  String get yearlyStats25Slide5MethodsHeader => '좋아하는 방법:';

  @override
  String get yearlyStats25Slide5NoMethods => '아직 방법이 없어요';

  @override
  String get yearlyStats25Slide5RecipesHeader => '상위 레시피:';

  @override
  String get yearlyStats25Slide5NoRecipes => '아직 레시피가 없어요';

  @override
  String yearlyStats25MethodRow(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '회',
    );
    return '$name — $count$_temp0 추출';
  }

  @override
  String yearlyStats25Slide6Title(String count) {
    return '올해 $count곳의 로스터리를 발견했어요:';
  }

  @override
  String get yearlyStats25Slide6NoRoasters => '아직 로스터리가 없어요';

  @override
  String get yearlyStats25Slide7Title => '커피는 당신을 여행으로 데려가요…';

  @override
  String yearlyStats25Slide7Subtitle(String count) {
    return '올해 $count개의 원산지를 발견했어요:';
  }

  @override
  String get yearlyStats25Others => '...외';

  @override
  String yearlyStats25FallbackTitle(int countries, int roasters) {
    return '올해 Timer.Coffee 사용자는 $countries개 나라의 원두를 사용했고\n$roasters개의 로스터리를 등록했어요.';
  }

  @override
  String get yearlyStats25FallbackPromptHasBeans => '원두 봉투 기록을 계속해보는 건 어때요?';

  @override
  String get yearlyStats25FallbackPromptNoBeans => '이제 참여해서 원두도 기록해볼까요?';

  @override
  String get yearlyStats25FallbackActionHasBeans => '원두 추가 계속하기';

  @override
  String get yearlyStats25FallbackActionNoBeans => '첫 원두 봉투 추가하기';

  @override
  String get yearlyStats25ContinueButton => '계속';

  @override
  String get yearlyStats25PostcardTitle => '다른 추출러에게 새해 인사를 보내요.';

  @override
  String get yearlyStats25PostcardSubtitle => '선택 사항. 친절하게. 개인 정보는 금지.';

  @override
  String get yearlyStats25PostcardHint => '새해 복 많이 받으세요! 좋은 추출 하세요!';

  @override
  String get yearlyStats25PostcardSending => '보내는 중...';

  @override
  String get yearlyStats25PostcardSend => '보내기';

  @override
  String get yearlyStats25PostcardSkip => '건너뛰기';

  @override
  String get yearlyStats25PostcardReceivedTitle => '다른 추출러의 메시지';

  @override
  String get yearlyStats25PostcardErrorLength => '2–160자를 입력하세요.';

  @override
  String get yearlyStats25PostcardErrorSend => '보낼 수 없어요. 다시 시도하세요.';

  @override
  String get yearlyStats25PostcardErrorRejected => '보낼 수 없어요. 다른 메시지를 시도하세요.';

  @override
  String get yearlyStats25CtaTitle => '2026년에 멋진 한 잔을 추출해요!';

  @override
  String get yearlyStats25CtaSubtitle => '몇 가지 아이디어:';

  @override
  String get yearlyStats25CtaExplorePrefix => '다음에서 제안을 둘러보세요: ';

  @override
  String get yearlyStats25CtaGiftBox => '홀리데이 기프트 박스';

  @override
  String get yearlyStats25CtaDonate => '기부';

  @override
  String get yearlyStats25CtaDonateSuffix => '로 내년에도 Timer.Coffee가 성장하도록 도와주세요';

  @override
  String get yearlyStats25CtaFollowPrefix => '다음에서 팔로우하세요: ';

  @override
  String get yearlyStats25CtaInstagram => 'Instagram';

  @override
  String get yearlyStats25CtaShareButton => '내 진행 상황 공유';

  @override
  String get yearlyStats25CtaShareHint => '@timercoffeeapp 태그하는 것 잊지 마세요';

  @override
  String get yearlyStats25AppBarTooltipResume => '재개';

  @override
  String get yearlyStats25AppBarTooltipPause => '일시정지';

  @override
  String get yearlyStats25ShareError => '리캡을 공유할 수 없어요. 다시 시도하세요.';

  @override
  String yearlyStats25BrewTimeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count분',
    );
    return '$_temp0';
  }

  @override
  String yearlyStats25BrewTimeHours(String hours) {
    return '$hours시간';
  }

  @override
  String get yearlyStats25ShareTitle => 'Timer.Coffee와 함께한 2025년';

  @override
  String get yearlyStats25ShareBrewedPrefix => '추출 ';

  @override
  String get yearlyStats25ShareBrewedMiddle => '번 · ';

  @override
  String get yearlyStats25ShareBrewedSuffix => '리터의 커피';

  @override
  String get yearlyStats25ShareRoastersPrefix => '로스터리 ';

  @override
  String get yearlyStats25ShareRoastersSuffix => '곳';

  @override
  String get yearlyStats25ShareOriginsPrefix => '원산지 ';

  @override
  String get yearlyStats25ShareOriginsSuffix => '개';

  @override
  String get yearlyStats25ShareMethodsTitle => '내가 좋아한 추출 방법:';

  @override
  String get yearlyStats25ShareRecipesTitle => '내 상위 레시피:';

  @override
  String get yearlyStats25ShareHandle => '@timercoffeeapp';

  @override
  String get yearlyStatsFailedToLike => '좋아요 실패. 다시 시도하세요.';

  @override
  String get labelCoffeeBrewed => '추출된 커피';

  @override
  String get labelTastedBeansBy => '로스터리별 맛본 원두';

  @override
  String get labelDiscoveredCoffeeFrom => '발견된 커피 원산지';

  @override
  String get labelUsedBrewingMethods => '사용';

  @override
  String formattedRoasterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '로스터리',
      one: '로스터리',
    );
    return '$count $_temp0';
  }

  @override
  String formattedCountryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '국가',
      one: '국가',
    );
    return '$count $_temp0';
  }

  @override
  String formattedBrewingMethodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '추출 방법',
      one: '추출 방법',
    );
    return '$count $_temp0';
  }

  @override
  String get recipeCreationScreenEditRecipeTitle => '레시피 편집';

  @override
  String get recipeCreationScreenCreateRecipeTitle => '레시피 생성';

  @override
  String get recipeCreationScreenRecipeStepsTitle => '레시피 단계';

  @override
  String get recipeCreationScreenRecipeNameLabel => '레시피 이름';

  @override
  String get recipeCreationScreenShortDescriptionLabel => '짧은 설명';

  @override
  String get recipeCreationScreenBrewingMethodLabel => '추출 방법';

  @override
  String get recipeCreationScreenCoffeeAmountLabel => '커피 양 (g)';

  @override
  String get recipeCreationScreenWaterAmountLabel => '물 양 (ml)';

  @override
  String get recipeCreationScreenWaterTempLabel => '물 온도 (°C)';

  @override
  String get recipeCreationScreenGrindSizeLabel => '분쇄도';

  @override
  String get recipeCreationScreenTotalBrewTimeLabel => '총 추출 시간:';

  @override
  String get recipeCreationScreenMinutesLabel => '분';

  @override
  String get recipeCreationScreenSecondsLabel => '초';

  @override
  String get recipeCreationScreenPreparationStepTitle => '준비 단계';

  @override
  String recipeCreationScreenBrewStepTitle(String stepOrder) {
    return '추출 단계 $stepOrder';
  }

  @override
  String get recipeCreationScreenStepDescriptionLabel => '단계 설명';

  @override
  String get recipeCreationScreenStepTimeLabel => '단계 시간:';

  @override
  String get recipeCreationScreenRecipeNameValidator => '레시피 이름을 입력하기';

  @override
  String get recipeCreationScreenShortDescriptionValidator => '짧은 설명을 입력하기';

  @override
  String get recipeCreationScreenBrewingMethodValidator => '추출 방법을 선택하기';

  @override
  String get recipeCreationScreenRequiredValidator => '필수';

  @override
  String get recipeCreationScreenInvalidNumberValidator => '잘못된 숫자';

  @override
  String get recipeCreationScreenStepDescriptionValidator => '단계 설명을 입력하기';

  @override
  String get recipeCreationScreenContinueButton => '레시피 단계로 계속';

  @override
  String get recipeCreationScreenAddStepButton => '단계 추가';

  @override
  String get recipeCreationScreenSaveRecipeButton => '레시피 저장';

  @override
  String get recipeCreationScreenUpdateSuccess => '레시피 업데이트 성공';

  @override
  String get recipeCreationScreenSaveSuccess => '레시피 저장 성공';

  @override
  String recipeCreationScreenSaveError(String error) {
    return '레시피 저장 오류: $error';
  }

  @override
  String get unitGramsShort => 'g';

  @override
  String get unitMillilitersShort => 'ml';

  @override
  String get unitGramsLong => '그램';

  @override
  String get unitMillilitersLong => '밀리리터';

  @override
  String get recipeCopySuccess => '레시피 복사 성공!';

  @override
  String get recipeDuplicateSuccess => '레시피가 성공적으로 복제되었습니다!';

  @override
  String recipeCopyError(String error) {
    return '레시피 복사 오류: $error';
  }

  @override
  String get createRecipe => '레시피 생성';

  @override
  String errorSyncingData(Object error) {
    return '데이터 동기화 오류: $error';
  }

  @override
  String errorSigningOut(Object error) {
    return '로그아웃 오류: $error';
  }

  @override
  String get defaultPreparationStepDescription => '준비';

  @override
  String get loadingEllipsis => '로딩 중…';

  @override
  String get recipeDeletedSuccess => '레시피 삭제 성공';

  @override
  String recipeDeleteError(Object error) {
    return '레시피 삭제 실패: $error';
  }

  @override
  String get noRecipesFound => '레시피를 찾을 수 없습니다';

  @override
  String recipeLoadError(Object error) {
    return '레시피 로드 실패: $error';
  }

  @override
  String get unknownBrewingMethod => '알 수 없는 추출 방법';

  @override
  String get recipeCopyErrorLoadingEdit => '편집을 위한 복사된 레시피 로드 실패.';

  @override
  String get recipeCopyErrorOperationFailed => '작업 실패.';

  @override
  String get notProvided => '제공되지 않음';

  @override
  String get recipeUpdateFailedFetch => '업데이트된 레시피 데이터 가져오기 실패.';

  @override
  String get recipeImportSuccess => '레시피 가져오기 성공!';

  @override
  String get recipeImportFailedSave => '가져온 레시피 저장 실패.';

  @override
  String get recipeImportFailedFetch => '가져오기 위한 레시피 데이터 가져오기 실패.';

  @override
  String get recipeNotImported => '레시피 가져오지 않음.';

  @override
  String get recipeNotFoundCloud => '클라우드에서 레시피를 찾을 수 없거나 공개되지 않음.';

  @override
  String get recipeLoadErrorGeneric => '레시피 로드 오류.';

  @override
  String get recipeUpdateAvailableTitle => '업데이트 사용 가능';

  @override
  String recipeUpdateAvailableBody(String recipeName) {
    return '\'$recipeName\'의 새 버전이 온라인에서 사용 가능해요 업데이트하시겠습니까?';
  }

  @override
  String get dialogCancel => '취소';

  @override
  String get dialogDuplicate => '복제';

  @override
  String get dialogUpdate => '업데이트';

  @override
  String get recipeImportTitle => '레시피 가져오기';

  @override
  String recipeImportBody(String recipeName) {
    return '클라우드에서 \'$recipeName\' 레시피를 가져오시겠습니까?';
  }

  @override
  String get dialogImport => '가져오기';

  @override
  String get moderationReviewNeededTitle => '검토 필요';

  @override
  String moderationReviewNeededMessage(String recipeNames) {
    return '다음 레시피가 콘텐츠 검토 문제로 검토가 필요해요: $recipeNames';
  }

  @override
  String get dismiss => '무시';

  @override
  String get reviewRecipeButton => '레시피 검토';

  @override
  String get signInRequiredTitle => '로그인 필요';

  @override
  String get signInRequiredBodyShare => '레시피 공유를 위해 로그인해야 해요';

  @override
  String get syncSuccess => '동기화 성공!';

  @override
  String get tooltipEditRecipe => '레시피 편집';

  @override
  String get tooltipCopyRecipe => '레시피 복사';

  @override
  String get tooltipDuplicateRecipe => '레시피 복제';

  @override
  String get tooltipShareRecipe => '레시피 공유';

  @override
  String get signInRequiredSnackbar => '로그인 필요';

  @override
  String get moderationErrorFunction => '콘텐츠 검토 확인 실패.';

  @override
  String get moderationReasonDefault => '검토를 위해 플래그됨.';

  @override
  String get moderationFailedTitle => '검토 실패';

  @override
  String moderationFailedBody(String reason) {
    return '이 레시피는 다음 이유로 공유할 수 없습니다: $reason';
  }

  @override
  String shareErrorGeneric(String error) {
    return '레시피 공유 오류: $error';
  }

  @override
  String recipeDetailWebTitle(String recipeName) {
    return 'Timer.Coffee의 $recipeName';
  }

  @override
  String get saveLocallyCheckLater => '콘텐츠 상태 확인 불가. 로컬 저장, 다음 동기화 시 확인.';

  @override
  String get saveLocallyModerationFailedTitle => '로컬 변경 저장';

  @override
  String saveLocallyModerationFailedBody(String reason) {
    return '로컬 변경이 저장되었지만 공개 버전은 콘텐츠 검토로 업데이트되지 않았습니다: $reason';
  }

  @override
  String get editImportedRecipeTitle => '가져온 레시피 편집';

  @override
  String get editImportedRecipeBody =>
      '이것은 가져온 레시피입니다. 편집하면 새로운 독립 복사가 생성돼요 계속하시겠습니까?';

  @override
  String get editImportedRecipeButtonCopy => '복사 생성 및 편집';

  @override
  String get editImportedRecipeButtonCancel => '취소';

  @override
  String get editDisplayNameTitle => '표시 이름 편집';

  @override
  String get displayNameHint => '표시 이름 입력';

  @override
  String get displayNameEmptyError => '표시 이름은 비울 수 없습니다';

  @override
  String get displayNameTooLongError => '표시 이름은 50자를 초과할 수 없습니다';

  @override
  String get errorUserNotLoggedIn => '사용자 로그인이 안 되어 있습니다. 다시 로그인하세요.';

  @override
  String get displayNameUpdateSuccess => '표시 이름 업데이트 성공';

  @override
  String displayNameUpdateError(String error) {
    return '표시 이름 업데이트 실패: $error';
  }

  @override
  String get deletePictureConfirmationTitle => '사진 삭제';

  @override
  String get deletePictureConfirmationBody => '프로필 사진을 삭제하시겠습니까?';

  @override
  String get deletePictureSuccess => '프로필 사진 삭제됨.';

  @override
  String deletePictureError(String error) {
    return '프로필 사진 삭제 실패: $error';
  }

  @override
  String updatePictureError(String error) {
    return '프로필 사진 업데이트 실패: $error';
  }

  @override
  String get updatePictureSuccess => '프로필 사진 업데이트 성공!';

  @override
  String get deletePictureTooltip => '사진 삭제';

  @override
  String get account => '계정';

  @override
  String get settingsBrewingMethodsTitle => '홈 화면 추출 방법';

  @override
  String get filter => '필터';

  @override
  String get sortBy => '정렬 기준';

  @override
  String get dateAdded => '추가 날짜';

  @override
  String get secondsAbbreviation => '초.';

  @override
  String get settingsAppIcon => '앱 아이콘';

  @override
  String get settingsAppIconDefault => '기본';

  @override
  String get settingsAppIconLegacy => '레거시';

  @override
  String get searchBeans => '원두 검색…';

  @override
  String get favorites => '좋아하는';

  @override
  String get searchPrefix => '검색:';

  @override
  String get clearAll => '모두 지우기';

  @override
  String get noBeansMatchSearch => '검색 결과에 맞는 원두 없음';

  @override
  String get clearFilters => '필터 지우기';

  @override
  String get farmer => '농부';

  @override
  String get farm => '농장';

  @override
  String get enterFarmer => '농부 입력 (선택)';

  @override
  String get enterFarm => '농장 입력 (선택)';

  @override
  String get requiredInformation => '필수 정보';

  @override
  String get basicDetails => '기본 세부 정보';

  @override
  String get qualityMeasurements => '품질 및 측정';

  @override
  String get importantDates => '중요 날짜';

  @override
  String get brewStats => '추출 통계';

  @override
  String get showMore => '더 보기';

  @override
  String get showLess => '접기';

  @override
  String get unpublishRecipeDialogTitle => '레시피 비공개로 만들기';

  @override
  String get unpublishRecipeDialogMessage => '경고: 이 레시피를 비공개로 만들면:';

  @override
  String get unpublishRecipeDialogBullet1 => '공개 검색 결과에서 제거';

  @override
  String get unpublishRecipeDialogBullet2 => '새 사용자 가져오기 방지';

  @override
  String get unpublishRecipeDialogBullet3 => '이미 가져온 사용자는 복사본 유지';

  @override
  String get unpublishRecipeDialogKeepPublic => '공개 유지';

  @override
  String get unpublishRecipeDialogMakePrivate => '비공개로 만들기';

  @override
  String get recipeUnpublishSuccess => '레시피 비공개 성공';

  @override
  String recipeUnpublishError(String error) {
    return '레시피 비공개 실패: $error';
  }

  @override
  String get recipePublicTooltip => '레시피 공개 - 비공개로 만들기 탭';

  @override
  String get recipePrivateTooltip => '레시피 비공개 - 공유하여 공개 만들기';

  @override
  String get fieldClearButtonTooltip => '지우기';

  @override
  String get dateFieldClearButtonTooltip => '날짜 지우기';

  @override
  String get chipInputDuplicateError => '이 태그는 이미 추가되었습니다';

  @override
  String chipInputMaxTagsError(Object maxChips) {
    return '최대 태그 수에 도달했습니다 ($maxChips)';
  }

  @override
  String get chipInputHintText => '태그 추가...';

  @override
  String get unitFieldRequiredError => '이 필드는 필수입니다';

  @override
  String get unitFieldInvalidNumberError => '유효한 숫자를 입력하세요';

  @override
  String unitFieldMinValueError(Object min) {
    return '값은 최소 $min이어야 합니다';
  }

  @override
  String unitFieldMaxValueError(Object max) {
    return '값은 최대 $max이어야 합니다';
  }

  @override
  String get numericFieldRequiredError => '이 필드는 필수입니다';

  @override
  String get numericFieldInvalidNumberError => '유효한 숫자를 입력하세요';

  @override
  String numericFieldMinValueError(Object min) {
    return '값은 최소 $min이어야 합니다';
  }

  @override
  String numericFieldMaxValueError(Object max) {
    return '값은 최대 $max이어야 합니다';
  }

  @override
  String get dropdownSearchHintText => '검색어를 입력하세요...';

  @override
  String dropdownSearchLoadingError(Object error) {
    return '제안 로딩 오류: $error';
  }

  @override
  String get dropdownSearchNoResults => '결과를 찾을 수 없습니다';

  @override
  String get dropdownSearchLoading => '검색 중...';

  @override
  String dropdownSearchUseCustomEntry(Object currentQuery) {
    return '\"$currentQuery\" 사용';
  }

  @override
  String get requiredInfoSubtitle => '* 필수';

  @override
  String get inventoryWeightExample => '예: 250.5';

  @override
  String get unsavedChangesTitle => '저장되지 않은 변경';

  @override
  String get unsavedChangesMessage => '저장되지 않은 변경이 있습니다. 변경을 삭제하시겠습니까?';

  @override
  String get unsavedChangesStay => '머무르기';

  @override
  String get unsavedChangesDiscard => '삭제';

  @override
  String beansWeightAddedBack(
      String amount, String beanName, String newWeight, String unit) {
    return '$beanName에 $amount$unit을(를) 다시 추가했습니다. 새 무게: $newWeight$unit';
  }

  @override
  String beansWeightSubtracted(
      String amount, String beanName, String newWeight, String unit) {
    return '$beanName에서 $amount$unit을(를) 빼냈습니다. 새 무게: $newWeight$unit';
  }

  @override
  String get notifications => '알림';

  @override
  String get notificationsDisabledInSystemSettings => '시스템 설정에서 비활성화됨';

  @override
  String get openSettings => '설정 열기';

  @override
  String get couldNotOpenLink => '링크를 열 수 없습니다';

  @override
  String get notificationsDisabledDialogTitle => '시스템 설정에서 알림이 비활성화됨';

  @override
  String get notificationsDisabledDialogContent =>
      '기기 설정에서 알림을 비활성화했습니다. 알림을 활성화하려면 기기 설정을 열고 Timer.Coffee에 대한 알림을 허용하세요.';

  @override
  String get notificationDebug => '알림 디버그';

  @override
  String get testNotificationSystem => '알림 시스템 테스트';

  @override
  String get notificationsEnabled => '활성화됨';

  @override
  String get notificationsDisabled => '비활성화됨';

  @override
  String get notificationPermissionDialogTitle => '알림을 활성화하시겠습니까?';

  @override
  String get notificationPermissionDialogMessage =>
      '알림을 활성화하면 유용한 업데이트(예: 새 앱 버전)를 받을 수 있습니다. 지금 활성화하거나 설정에서 언제든지 변경할 수 있습니다.';

  @override
  String get notificationPermissionEnable => '활성화';

  @override
  String get notificationPermissionSkip => '나중에';

  @override
  String get holidayGiftBoxTitle => '홀리데이 기프트 박스';

  @override
  String get holidayGiftBoxInfoTrigger => '이게 뭐죠?';

  @override
  String get holidayGiftBoxInfoBody =>
      '파트너의 시즌 한정 혜택을 모았습니다. 링크는 제휴가 아니며 - 이번 홀리데이 시즌 Timer.Coffee 사용자께 작은 기쁨을 드리려는 마음입니다. 언제든 아래로 당겨 새로고침하세요.';

  @override
  String get holidayGiftBoxNoOffers => '현재 이용 가능한 혜택이 없습니다.';

  @override
  String get holidayGiftBoxNoOffersSub => '아래로 당겨 새로고침하거나 나중에 다시 시도하세요.';

  @override
  String holidayGiftBoxShowingRegion(String region) {
    return '$region 지역의 혜택 표시';
  }

  @override
  String get holidayGiftBoxViewDetails => '자세히 보기';

  @override
  String get holidayGiftBoxPromoCopied => '프로모션 코드가 복사되었습니다';

  @override
  String get holidayGiftBoxPromoCode => '프로모션 코드';

  @override
  String giftDiscountOff(String percent) {
    return '$percent% 할인';
  }

  @override
  String giftDiscountUpToOff(String percent) {
    return '최대 $percent% 할인';
  }

  @override
  String get holidayGiftBoxTerms => '이용 약관';

  @override
  String get holidayGiftBoxVisitSite => '파트너 사이트 방문';

  @override
  String holidayGiftBoxValidUntil(String date) {
    return '$date까지 유효';
  }

  @override
  String holidayGiftBoxEndsInDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '종료까지 $days일',
      one: '내일 종료',
      zero: '오늘 종료',
    );
    return '$_temp0';
  }

  @override
  String get holidayGiftBoxValidWhileAvailable => '재고 소진 시까지 유효';

  @override
  String holidayGiftBoxUpdated(String date) {
    return '$date 업데이트';
  }

  @override
  String holidayGiftBoxLanguage(String language) {
    return '언어: $language';
  }

  @override
  String get holidayGiftBoxRetry => '다시 시도';

  @override
  String get holidayGiftBoxLoadFailed => '혜택을 불러오지 못했습니다';

  @override
  String get holidayGiftBoxOfferUnavailable => '혜택을 사용할 수 없습니다';

  @override
  String get holidayGiftBoxBannerTitle => '홀리데이 기프트 박스를 확인하세요';

  @override
  String get holidayGiftBoxBannerCta => '오퍼 보기';

  @override
  String get regionEurope => '유럽';

  @override
  String get regionNorthAmerica => '북아메리카';

  @override
  String get regionAsia => '아시아';

  @override
  String get regionAustralia => '호주 / 오세아니아';

  @override
  String get regionWorldwide => '전 세계';

  @override
  String get regionAfrica => '아프리카';

  @override
  String get regionMiddleEast => '중동';

  @override
  String get regionSouthAmerica => '남아메리카';

  @override
  String get setToZeroButton => '0으로 설정';

  @override
  String get setToZeroDialogTitle => '재고를 0으로 설정하시겠습니까?';

  @override
  String get setToZeroDialogBody => '남은 양이 0 g로 설정됩니다. 나중에 수정할 수 있습니다.';

  @override
  String get setToZeroDialogConfirm => '0으로 설정';

  @override
  String get setToZeroDialogCancel => '취소';

  @override
  String get inventorySetToZeroSuccess => '재고가 0 g로 설정되었습니다';

  @override
  String get inventorySetToZeroFail => '재고를 0으로 설정하는 데 실패했습니다';
}
