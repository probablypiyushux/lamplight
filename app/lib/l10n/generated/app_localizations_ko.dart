// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class LKo extends L {
  LKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Lamplight';

  @override
  String get lockTypePasscode => '암호를 입력하세요.';

  @override
  String get lockWrongPasscode => '그걸로는 열리지 않았습니다.';

  @override
  String get lockCheckAndRetry => '암호를 확인하고 다시 시도하세요.';

  @override
  String get lockForgot => '암호를 잊었습니다';

  @override
  String get lockTypeTwelveWords => '열두 단어를 입력하세요.';

  @override
  String get lockUsePasscodeInstead => '암호를 사용하기';

  @override
  String get lockUseFingerprint => '지문 사용하기';

  @override
  String get lockFingerprintFailed => '지문으로 열리지 않았습니다.';

  @override
  String get lockFingerprintUnavailable => '지문을 사용할 수 없습니다.';

  @override
  String get lockOpening => '여는 중…';

  @override
  String get lockNothingDeleted => '아무것도 지워지지 않았고, 앞으로도 지워지지 않습니다.';

  @override
  String lockTryAgainSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count초 뒤에 다시 시도하세요.',
    );
    return '$_temp0';
  }

  @override
  String lockTryAgainMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count분 뒤에 다시 시도하세요.',
    );
    return '$_temp0';
  }

  @override
  String get dayToday => '오늘';

  @override
  String get dayPrevious => '전날';

  @override
  String get dayNext => '다음 날';

  @override
  String get daySearch => '찾기';

  @override
  String get daySettings => '설정';

  @override
  String get dayChooseDate => '다른 날짜 고르기.';

  @override
  String get dayEmptyToday => '남겨두고 싶은 게 있나요?';

  @override
  String get dayEmptyPast => '이 날에는 아무것도 없습니다.';

  @override
  String get dayWriteSomething => '오늘 일을 적기';

  @override
  String get dayLineAsk => '어떤 하루였나요?';

  @override
  String get dayLineHint => '어떤 하루였나요?';

  @override
  String get dayLineSemantic => '이 날이 어떤 날이었는지 한 줄로';

  @override
  String dayLineChange(String note) {
    return '이 날: $note. 바꾸기.';
  }

  @override
  String get dayEndOfDay => '하루의 끝';

  @override
  String get dayStartOfDay => '하루의 시작';

  @override
  String get firstPageTitle => '아직 아무것도 쓰지 않아서 비어 있습니다.';

  @override
  String get firstPageShelves => '날짜가 선반입니다. 남긴 것은 그 일이 있었던 날에 놓이고, 그대로 남습니다.';

  @override
  String get firstPageWayWrite => '이 페이지를 누르면 쓸 수 있습니다.';

  @override
  String get firstPageWayVoice => '마이크를 길게 누르면 말로 남길 수 있습니다.';

  @override
  String get firstPageWayAttach => '사진이나 영상, 문서를 더할 수 있습니다.';

  @override
  String get firstPagePromise => '이 가운데 어떤 것도 이 기기를 떠나지 않습니다.';

  @override
  String get firstPageSemantic => '일기에 첫 번째 것을 적기';

  @override
  String get captureVoice => '음성 남기기';

  @override
  String get capturePhoto => '사진 찍거나 고르기';

  @override
  String get captureFile => '파일 첨부하기';

  @override
  String get backupNeverMade => '여기에는 백업이 없습니다. 이 앱이 지워지면 적어둔 것도 함께 사라집니다.';

  @override
  String get backupStale => '마지막 백업으로부터 시간이 꽤 지났습니다.';

  @override
  String get backupOutOfDate => '백업은 아직 예전 암호로 열립니다.';

  @override
  String get backupAction => '백업';

  @override
  String folderAlsoIn(String name) {
    return '$name에도 있습니다. 폴더 열기.';
  }

  @override
  String get folderStaysHere => '있던 자리에 그대로 남습니다. 폴더는 그것을 찾는 두 번째 자리입니다.';

  @override
  String get folderAddTo => '폴더에 넣기';

  @override
  String get folderNew => '새 폴더';

  @override
  String get folderNoneYet =>
      '아직 폴더가 없습니다. 사람마다 하나, 또는 시기마다 하나 — 자꾸 다시 보게 되는 것으로.';

  @override
  String folderLesson(String day, String folder) {
    return '여전히 $day에 있습니다. $folder에도 있습니다.';
  }

  @override
  String get actionDone => '완료';

  @override
  String get actionCancel => '취소';

  @override
  String get actionDelete => '삭제';

  @override
  String get actionSave => '저장';

  @override
  String get actionEdit => '수정';

  @override
  String get actionUndo => '되돌리기';

  @override
  String get actionOpen => '열기';

  @override
  String get actionRemove => '빼기';

  @override
  String get actionNotNow => '나중에';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsAppearance => '모양';

  @override
  String get settingsSecurity => '잠금과 보안';

  @override
  String get settingsYourNotes => '당신의 기록';

  @override
  String get settingsBackup => '백업';

  @override
  String get settingsAbout => '정보';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsLanguageNote =>
      '앱이 쓰는 말입니다. 당신이 쓰는 것은 어떤 언어로든 당신의 것이고, 이 설정과 상관없습니다.';

  @override
  String get settingsLanguageSystem => '기기를 따름';

  @override
  String get entryMattered => '이건 중요했다';

  @override
  String get entryMarked => '중요했던 것으로 표시했습니다.';

  @override
  String get entryMarkRemoved => '표시를 지웠습니다.';

  @override
  String get entryDeleted => '삭제되었습니다.';

  @override
  String entryEarlierVersions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이전 것 $count개',
    );
    return '$_temp0';
  }

  @override
  String get entryKeepsWords => '글은 남습니다';

  @override
  String entryKindInTrash(Object kind) {
    return '$kind은(는) 휴지통에 있습니다.';
  }

  @override
  String entryKindInTrashWords(Object kind) {
    return '$kind은(는) 휴지통에 있습니다. 글은 그대로 있습니다.';
  }

  @override
  String trashConfirmBody(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개와 그 이전 것 모두. 이것은 되돌릴 수 없습니다.',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyEntry => '빈 항목';

  @override
  String get kindPhoto => '사진';

  @override
  String get kindVideo => '영상';

  @override
  String get kindRecording => '녹음';

  @override
  String get kindFile => '파일';

  @override
  String get entryNoLongerMarked => '표시 해제';

  @override
  String get entryFindAgain => '검색 화면에서 다시 찾을 수 있습니다';

  @override
  String get searchGoTo => '이동';

  @override
  String get searchFolders => '폴더';

  @override
  String get searchEntriesOne => '1개';

  @override
  String searchEntriesMany(int count) {
    return '$count개';
  }

  @override
  String get searchNothingFound => '일치하는 것이 없습니다.';

  @override
  String get searchEverythingInstead => '전체에서 찾기';

  @override
  String get searchNoneOfThese => '아직 그런 항목이 없습니다.';

  @override
  String get onboardNoAccount => '계정이 없습니다.';

  @override
  String get onboardPromiseBody =>
      '기록은 이 휴대폰 안에만 남습니다.\n서버가 없습니다. 저희는 읽을 수 없습니다.\n되돌려 드릴 수도 없습니다.';

  @override
  String get onboardBegin => '시작하기';

  @override
  String get onboardHaveBackup => '백업이 있어요';

  @override
  String get onboardSetPasscode => '암호 정하기';

  @override
  String get onboardPasscodeBody =>
      '기록을 여는 건 이것뿐입니다. 기억할 수 있는 문장은 네 자리 숫자보다 튼튼합니다.';

  @override
  String get onboardPasscodeLabel => '암호';

  @override
  String get onboardPasscodeAgain => '다시 입력하세요';

  @override
  String get onboardSettingUp => '준비 중…';

  @override
  String get onboardContinue => '계속';

  @override
  String get onboardPasscodesDiffer => '그 둘이 서로 다릅니다.';

  @override
  String get onboardVaultFailed => '금고를 만들지 못했습니다.';

  @override
  String get onboardVaultFailedThen => '아무것도 저장되지 않았습니다. 한 번만 더 해 보세요.';

  @override
  String get onboardWriteWords => '이 열두 단어를\n종이에 적으세요';

  @override
  String get onboardWordsBody =>
      '저희에게는 사본이 없습니다. 보내드릴 수도 없습니다. 도와줄 수 있는 고객센터 주소도 없습니다.\n\n스크린샷이 아니라 종이에. 스크린샷은 갤러리에 남고, 거기가 누구든 가장 먼저 여는 곳입니다.';

  @override
  String get onboardWrittenDown => '적어 두었어요';

  @override
  String get onboardCopyWords => '열두 단어 복사';

  @override
  String get onboardClipboardNote =>
      '클립보드는 1분 뒤에 스스로 비워집니다. 그전까지는 다른 앱도 읽을 수 있습니다.';

  @override
  String get onboardCopied => '복사했습니다. 1분 뒤 자동으로 지워집니다 — 지금 안전한 곳에 붙여넣으세요.';

  @override
  String get onboardCopyFailed => '복사하지 못했습니다. 어차피 손으로 적는 편이 더 안전합니다.';

  @override
  String get onboardCheckThree => '세 개만 확인합니다';

  @override
  String get onboardCheckBody => '화면이 아니라 종이가 맞는지 확인하려는 겁니다.';

  @override
  String onboardWordNumber(int number) {
    return '$number번째 단어';
  }

  @override
  String onboardWordWrong(int number) {
    return '$number번째 단어가 맞지 않습니다. 적어 둔 것을 보세요.';
  }

  @override
  String get onboardShowWords => '단어를 다시 보기';

  @override
  String get onboardFingerprintTitle => '지문으로 여시겠어요?';

  @override
  String get onboardFingerprintBody => '그럼 매번 그 문장을 입력하지 않아도 됩니다.';

  @override
  String get onboardFingerprintExplain =>
      '열쇠는 여전히 당신의 문장입니다. 지문은 이 금고만, 이 휴대폰에서만 열며, 휴대폰의 지문이 바뀌면 Android가 알아서 끕니다 — 누군가 자신의 지문을 추가해 들어올 수 없도록. 백업에는 결코 포함되지 않습니다.';

  @override
  String get onboardFingerprintWaiting => '손가락을 기다리는 중…';

  @override
  String get onboardFingerprintUse => '내 지문 사용';

  @override
  String get onboardFingerprintFailed => '잘 되지 않았습니다.';

  @override
  String get onboardOneLastThing => '마지막 하나';

  @override
  String get onboardNameBody =>
      'Lamplight가 당신을 어떻게 부를까요? 이 휴대폰에만 남고, 나중에 바꾸거나 비워 두셔도 됩니다.';

  @override
  String get onboardFingerprintOn => '이제부터 지문으로 Lamplight가 열립니다.';

  @override
  String get onboardYourName => '이름';

  @override
  String get onboardStartWriting => '쓰기 시작';

  @override
  String get onboardSkip => '건너뛰기';

  @override
  String get settingsGroupLook => '모양과 말';

  @override
  String get settingsGroupWhoCanOpen => '누가 열 수 있는지';

  @override
  String get settingsGroupKeeping => '보관하기, 그리고 가져가기';

  @override
  String get settingsAppearanceNote => '테마, 글꼴, 색, 페이지';

  @override
  String get settingsFolders => '폴더';

  @override
  String get settingsFoldersNote => '사람, 장소, 시기';

  @override
  String get settingsMedia => '미디어';

  @override
  String get settingsMediaNote => '사진, 영상, 소리, 문서';

  @override
  String get mediaGroupDocuments => '문서';

  @override
  String get mediaDocumentsKept => '받은 그대로 보관합니다';

  @override
  String get mediaDocumentsFooter =>
      'PDF나 Word 파일은 안쪽이 이미 압축되어 있어서, 다시 줄여도 5% 남짓밖에 되지 않습니다. 실제로 작아지게 하려면 안에 든 그림을 다시 만들어야 하는데, 그러면 스캔한 문서의 작은 글씨가 영영 흐려집니다 — 그리고 그 사실은 몇 년 뒤, 그 문서를 읽어야 하는 날에야 알게 됩니다.';

  @override
  String get settingsTrash => '휴지통';

  @override
  String get settingsTrashNote => '지운 기록은 30일 동안 보관됩니다';

  @override
  String get settingsReadableCopy => '읽을 수 있는 사본';

  @override
  String get settingsReadableCopyNote => 'Markdown과 파일을, 고른 폴더에';

  @override
  String get settingsBringIn => '예전 일기 가져오기';

  @override
  String get settingsBringInNote => '다른 앱의 텍스트 파일을 이름의 날짜대로 정리합니다';

  @override
  String get settingsKeepingFooter =>
      '백업은 금고와 똑같이 암호로 잠겨 있습니다. 읽을 수 있는 사본은 전혀 잠겨 있지 않습니다 — 고른 폴더에 놓이는 평범한 파일입니다.';

  @override
  String get backupNever => '아직 백업한 적 없음';

  @override
  String get backupToday => '오늘 백업함';

  @override
  String get backupYesterday => '어제 백업함';

  @override
  String backupDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 전에 백업함',
    );
    return '$_temp0';
  }

  @override
  String get mediaGroupIncoming => '들어올 때';

  @override
  String get mediaGroupVoice => '음성 메모';

  @override
  String get mediaIncomingFooter =>
      'Lamplight는 작은 사본을 따로 두지 않습니다 — 여기서 고른 것이 그대로 저장되고, 원본은 어디에도 남지 않습니다.';

  @override
  String get mediaVoiceFooter =>
      '받아쓰기는 이 휴대폰 안에서, Android가 이미 가진 인식기로 이루어집니다. Lamplight에 말한 내용은 어디로도 전송되지 않으며, 앱에는 보낼 권한 자체가 없습니다.';

  @override
  String get mediaPhotoSize => '사진 크기';

  @override
  String get mediaVideoSize => '영상 크기';

  @override
  String get mediaAskEachTime => '매번 묻기';

  @override
  String get accentAmber => '호박빛';

  @override
  String get accentAmberNote => '밤에 켠 등불. 기본.';

  @override
  String get accentRose => '로즈';

  @override
  String get accentRoseNote => '따뜻한 분홍. 호박빛보다 부드럽게.';

  @override
  String get accentSage => '세이지';

  @override
  String get accentSageNote => '조용한 초록. 여섯 중 가장 차분한.';

  @override
  String get accentSlate => '슬레이트';

  @override
  String get accentSlateNote => '차가운 푸른 회색. 가장 무던한.';

  @override
  String get accentPlum => '자두';

  @override
  String get accentPlumNote => '짙은 보라.';

  @override
  String get accentEmber => '잉걸';

  @override
  String get accentEmberNote => '그을린 주황. 가장 따뜻한.';

  @override
  String get surfacePlain => '민무늬';

  @override
  String get surfacePlainNote => '매끈한 지면.';

  @override
  String get surfacePaper => '종이';

  @override
  String get surfacePaperNote => '고운 결이 있어 여백이 아니라 종이로 보입니다. 기본.';

  @override
  String get surfaceLamplit => '불빛 아래';

  @override
  String get surfaceLamplitNote => '종이에, 등불을 켜고.';

  @override
  String get surfaceStarMap => '별지도';

  @override
  String get surfaceStarMapNote =>
      '하나의 하늘이 시계를 따라 돕니다. 하루에 같은 하늘은 두 번 오지 않습니다.';

  @override
  String get rulingNone => '없음';

  @override
  String get rulingNoneNote => '지면에 아무것도 인쇄하지 않습니다.';

  @override
  String get rulingLines => '줄';

  @override
  String get rulingLinesNote => '공책처럼 그어진 줄.';

  @override
  String get rulingIsometric => '등각';

  @override
  String get rulingIsometricNote => '제도용지. 삼차원으로 생각하기 위해.';

  @override
  String get rulingTriangle => '삼각';

  @override
  String get rulingTriangleNote => '정삼각형이 깔린 바탕.';

  @override
  String get rulingDots => '점 격자';

  @override
  String get rulingDotsNote => '교차점마다 점 하나. 넷 중 가장 조용한.';

  @override
  String get faceSystem => '시스템';

  @override
  String get faceSystemNote => '휴대폰의 나머지가 쓰는 그 글꼴.';

  @override
  String get faceSerif => '시스템 명조';

  @override
  String get faceSerifNote => '휴대폰이 가진 명조 계열.';

  @override
  String get faceCalmNote => '부드러운 모서리, 넓은 글자.';

  @override
  String get faceModernNote => '단단하고 요즘의 공기.';

  @override
  String get faceOldStyleNote => '16세기 책의 활자.';

  @override
  String get facePlayfulNote => '둥글고 명랑하게.';

  @override
  String get faceChildlikeNote => '학습장.';

  @override
  String get faceHandwrittenNote => '손으로 쓴 모습인데, 한 쪽을 읽어도 편합니다.';

  @override
  String get faceMedievalNote => '필경사의 손. 굵기는 하나뿐.';

  @override
  String get faceMonoNote => '모든 글자가 같은 너비.';

  @override
  String get qualityOriginal => '원본 그대로';

  @override
  String get qualityBalanced => '적당히';

  @override
  String get qualitySmaller => '더 작게';

  @override
  String get photoOriginalNote =>
      '카메라가 찍은 그대로 보관합니다. 파일이 가장 크고, 사진을 찍은 장소도 함께 남습니다 — Lamplight가 평소에는 지우는 정보입니다.';

  @override
  String get photoBalancedNote => '훨씬 작고, 원본과 구별하기 어렵습니다. 기본.';

  @override
  String get photoSmallerNote => '거기서 또 절반. 바짝 잘라내면 보일 수 있습니다.';

  @override
  String get videoOriginalNote => '카메라가 찍은 그대로 보관합니다. 파일이 압도적으로 큽니다.';

  @override
  String get videoBalancedNote => '훨씬 작고, 원본과 구별하기 어렵습니다. 기본.';

  @override
  String get videoSmallerNote => '거기서 또 절반. 큰 화면에서는 보일 수 있습니다.';

  @override
  String get appearanceTitle => '모양';

  @override
  String get appearanceTheme => '테마';

  @override
  String get appearanceThemeDark => '어둡게';

  @override
  String get appearanceThemeLight => '밝게';

  @override
  String get appearanceThemeAuto => '자동';

  @override
  String get appearanceThemeAutoNote => '휴대폰의 밝게·어둡게 설정을 따릅니다.';

  @override
  String get appearanceFont => '글꼴';

  @override
  String get appearanceSize => '크기';

  @override
  String get appearanceColour => '색';

  @override
  String get appearancePage => '페이지';

  @override
  String get appearanceRuling => '괘선';

  @override
  String get daySavedToToday => '오늘에 저장했습니다.';

  @override
  String get dayAddedToToday => '오늘에 추가했습니다.';

  @override
  String get entryEditWords => '글 고치기';

  @override
  String get entryDeleteBlock => '묶음 전체 지우기';

  @override
  String entrySavedAs(String name) {
    return '$name(으)로 저장했습니다.';
  }

  @override
  String entryAddedToFolder(String name) {
    return '$name에도 있습니다.';
  }

  @override
  String get entrySaveCopy => '사본 저장';

  @override
  String get entrySaveCopyNote => '고른 곳에, Lamplight 밖으로';

  @override
  String get capturePhotoTake => '사진 찍기';

  @override
  String get capturePhotoChoose => '사진에서 고르기';

  @override
  String get composerHintToday => '오늘에 대해…';

  @override
  String get composerHintPast => '이 날에 대해…';

  @override
  String get composerNewBlock => '새 묶음';

  @override
  String get voiceShowTranscript => '말한 내용 보기';

  @override
  String get voiceHideTranscript => '말한 내용 숨기기';

  @override
  String get voiceTranscriptTitle => '말한 내용';

  @override
  String get entryEdited => ', 수정함';

  @override
  String photoSemantic(String time) {
    return '$time의 사진. 두 번 누르면 열립니다.';
  }

  @override
  String get sizeThisPhoto => '이 사진';

  @override
  String get sizeThesePhotos => '이 사진들';

  @override
  String get sizeThisVideo => '이 영상';

  @override
  String get sizeTheseVideos => '이 영상들';

  @override
  String sizeQuestion(String what) {
    return '$what을(를) 어느 크기로 보관할까요?';
  }

  @override
  String get trashNote => '지운 것은 여기에 30일 남았다가 완전히 사라집니다.';

  @override
  String get trashConfirm => '이것들을 완전히 지울까요?';

  @override
  String get trashKeep => '그대로 두기';

  @override
  String get trashDeleteForGood => '완전히 지우기';

  @override
  String get trashPutBack => '되돌리기';

  @override
  String trashPutBackOn(String day) {
    return '$day(으)로 되돌렸습니다.';
  }

  @override
  String get trashEmpty => '휴지통 비우기';

  @override
  String get folderMakeFirst => '첫 폴더 만들기';

  @override
  String folderDeleteAsk(String name) {
    return '“$name”을(를) 지울까요?';
  }

  @override
  String get folderKeepIt => '그대로 두기';

  @override
  String get folderDeleteIt => '폴더 지우기';

  @override
  String get folderRename => '이름 바꾸기';

  @override
  String get folderDeleteThis => '이 폴더 지우기';

  @override
  String folderTakenOut(String name) {
    return '$name에서 뺐습니다. 그날에는 그대로 있습니다.';
  }

  @override
  String get searchHint => '낱말, 날짜, 이름…';

  @override
  String get searchBack => '뒤로';

  @override
  String get searchClear => '지우기';

  @override
  String searchNothingMatches(String query) {
    return '“$query”와 맞는 것이 없습니다.';
  }

  @override
  String get searchWhatMattered => '마음에 남은 것';

  @override
  String get searchADate => '날짜';

  @override
  String get searchDateExample => '2006년 3월 16일 · 2006년 3월 · 어제';

  @override
  String get searchWhatYouCanType => '무엇을 찾을 수 있나요';

  @override
  String get searchTryDate => '어제';

  @override
  String get searchSaidOutLoud => '소리 내어 말한 것';

  @override
  String get searchAPhotograph => '사진';

  @override
  String get searchAVideo => '영상';

  @override
  String get securityWhileOpen => '앱이 열려 있는 동안';

  @override
  String get securityLockFooter =>
      'Lamplight는 뒤로 넘어가는 순간 언제나 잠깁니다. 여기서는 아직 안에 있을 때 얼마나 기다릴지만 정합니다.';

  @override
  String get securityLockAfter => '이만큼 뒤 잠그기';

  @override
  String get securityOneHour => '1시간';

  @override
  String get securityYourPasscode => '암호';

  @override
  String get securityPasscodeFooter =>
      '암호가 열쇠입니다. 어디에도 저장되지 않습니다 — 이 휴대폰에도, 다른 어디에도 — 그래서 누구도 내놓으라고 강요당할 수 없고, 누구도 대신 되찾아 줄 수 없습니다.';

  @override
  String get securityChangePasscode => '암호 바꾸기';

  @override
  String get securityScreenshots => '화면 갈무리';

  @override
  String get securityScreenshotsFooter =>
      'Lamplight는 화면 갈무리를 막습니다. 휴대폰을 집어 든 사람이 기록을 찍지 못하도록, 최근 앱 미리보기에도 뜨지 않도록. 본인의 휴대폰에서는 꺼 두실 수 있습니다.';

  @override
  String get securityAllowScreenshots => '화면 갈무리 허용';

  @override
  String get securityScreenshotsOn => '최근 앱 목록에 메모가 보입니다';

  @override
  String get securityScreenshotsOff => '최근 앱 목록에는 빈 페이지가 보입니다';

  @override
  String get securityCouldNotChange => '그것은 바꿀 수 없었습니다.';

  @override
  String get securityNothingChanged => '잠금에 관해서는 아무것도 바뀌지 않았습니다.';

  @override
  String get securityPromptAutomatic => '자동으로 물어봅니다';

  @override
  String get securityPromptOnTap => '쓰고 싶을 때 지문을 누르세요';

  @override
  String get mediaAskEachTimeOn => '사진과 영상을 추가할 때 얼마나 크게 둘지 물어봅니다.';

  @override
  String get mediaAskEachTimeOff => '꺼짐. 위의 두 크기를 묻지 않고 사용합니다.';

  @override
  String get passcodeNew => '새 잠금번호';

  @override
  String get securityFingerprint => '지문';

  @override
  String get securityFingerprintFooter =>
      '열쇠는 여전히 당신의 문장입니다. 지문은 이 금고만, 이 휴대폰에서만 열며, 휴대폰의 지문이 바뀌면 Android가 알아서 끕니다 — 누군가 자신의 지문을 추가해 들어올 수 없도록. 백업에는 결코 포함되지 않습니다.';

  @override
  String get securityUnlockWithFingerprint => '내 지문으로 열기';

  @override
  String get securityAskOnOpen => 'Lamplight를 열면 바로 묻기';

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count초',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count분',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count시간',
    );
    return '$_temp0';
  }

  @override
  String get durationNever => '안 함';

  @override
  String get securityDefaultNote => '기본.';

  @override
  String get securityHourNote => '다시 읽는 오후를 위해.';

  @override
  String get securityNeverNote => '앱을 벗어나면 그래도 바로 잠깁니다.';

  @override
  String get calendarGoToDate => '날짜로 가기';

  @override
  String get dayHasWriting => '글';

  @override
  String get dayHasPhoto => '사진';

  @override
  String get dayHasVideo => '영상';

  @override
  String get dayHasVoice => '음성 메모';

  @override
  String get dayHasFile => '파일';

  @override
  String dayEntriesAndKinds(Object count, Object kinds) {
    return '$count, $kinds';
  }

  @override
  String get listSeparator => ', ';

  @override
  String listAnd(Object last, Object most) {
    return '$most 그리고 $last';
  }

  @override
  String get integrityNothingUnusual =>
      '이 기기에 이상한 점은 없습니다. Lamplight는 제대로 돌아가고 있습니다.';

  @override
  String get calendarPreviousYear => '지난해';

  @override
  String get calendarPreviousMonth => '지난달';

  @override
  String get calendarNextYear => '다음 해';

  @override
  String get calendarNextMonth => '다음 달';

  @override
  String get calendarBackToMonth => '달로 돌아가기';

  @override
  String get calendarWholeYear => '한 해 전체';

  @override
  String get calendarBackToThisMonth => '이번 달로 돌아가기';

  @override
  String get calendarNothingThisYear => '이 해에는 아직 아무것도 없습니다.';

  @override
  String calendarYearSummary(Object days, Object entries) {
    return '$days 동안 $entries.';
  }

  @override
  String get folderNothingInIt => '아직 아무것도 없습니다';

  @override
  String get onThisDayOneYear => '일 년 전 오늘';

  @override
  String onThisDayYears(Object years) {
    return '$years년 전 오늘';
  }

  @override
  String wheelYear(Object year) {
    return '$year년';
  }

  @override
  String get calendarBackToBrowsing => '다시 넘겨보기';

  @override
  String get calendarToday => '오늘';

  @override
  String get calendarFirstEntry => '처음 쓴 것';

  @override
  String get calendarGoToThisDay => '이 날로 가기';

  @override
  String get calendarDensityNote => '색은 그날 얼마나 있는지 보여줍니다. 없음부터 많음까지.';

  @override
  String get calendarLess => '적음';

  @override
  String get calendarMore => '많음';

  @override
  String get calendarGoToToday => '오늘로 가기';

  @override
  String get backupTitle => '백업';

  @override
  String get vaultNothingToBackUp => '이 금고에는 아직 백업할 것이 없습니다.';

  @override
  String vaultChangedWhileBackingUp(Object name) {
    return '백업하는 동안 무언가 바뀌었습니다($name). 다시 해 보세요.';
  }

  @override
  String get vaultTooSmall => '이 파일은 너무 작아서 Lamplight 백업일 수 없습니다.';

  @override
  String get vaultNotALamplightFile => '이것은 Lamplight 백업 파일이 아닙니다.';

  @override
  String get vaultDamaged => '이 파일은 손상되어 열 수 없습니다.';

  @override
  String get vaultKeyringNewerVersion =>
      '이 금고는 더 새로운 Lamplight로 만들었습니다. 열려면 앱을 업데이트해 주세요.';

  @override
  String get vaultKeyringDamaged =>
      '금고 열쇠 파일이 손상되어 읽을 수 없습니다. 백업 파일이 있다면 그것으로 되돌리세요.';

  @override
  String get vaultDatabaseNewerVersion =>
      '이 금고는 더 새로운 Lamplight로 만들었습니다. 열려면 앱을 업데이트해 주세요 — 메모는 그대로이고 아무것도 바뀌지 않았습니다.';

  @override
  String phraseWrongLength(Object count) {
    return '복구 문구는 열두 단어입니다. 이것은 $count개입니다.';
  }

  @override
  String phraseNotARecoveryWord(Object word) {
    return '\"$word\"은(는) 복구 단어가 아닙니다.';
  }

  @override
  String get phraseDoesNotCheckOut =>
      '그 단어들은 올바른 복구 문구가 아닙니다. 잘못 쓴 단어나 순서가 바뀐 단어가 없는지 확인해 주세요.';

  @override
  String get vaultNewerVersion =>
      '이 백업은 더 새로운 Lamplight로 만들었습니다. 앱을 업데이트한 뒤 다시 해 보세요.';

  @override
  String get vaultUnknownCompression => '이 백업은 이 버전이 읽을 줄 모르는 압축을 씁니다.';

  @override
  String get vaultDamagedTryOlder =>
      '이 파일은 손상되어 열 수 없습니다. 더 오래된 백업이 있다면 그것을 써 보세요.';

  @override
  String get vaultBeforeRecoveryPhrases =>
      '이 백업은 복구 단어로 백업 파일을 열 수 있게 되기 전에 만든 것입니다. 잠금번호만이 들어가는 길입니다.';

  @override
  String get vaultWordsDoNotOpenIt =>
      '그 단어들로는 이 파일이 열리지 않습니다. 다른 금고의 것일 수 있습니다.';

  @override
  String get vaultWrongPasscode => '그 잠금번호로는 이 파일이 열리지 않습니다.';

  @override
  String vaultMissingPart(Object name) {
    return '이 백업은 자기 일부가 빠져 있습니다($name).';
  }

  @override
  String vaultPartWrongSize(Object name) {
    return '이 백업은 손상되었습니다($name의 크기가 맞지 않습니다).';
  }

  @override
  String vaultPartDoesNotMatch(Object name) {
    return '이 백업은 손상되었습니다($name이(가) 맞지 않습니다).';
  }

  @override
  String get vaultNoVaultInside => '이 백업에는 금고가 들어 있지 않습니다. 다른 앱이 만든 것일 수 있습니다.';

  @override
  String get vaultOutOfOrder => '이 파일은 손상되었습니다. 안의 내용이 순서에서 벗어났습니다.';

  @override
  String get vaultEndsPartWay => '이 파일은 손상되었습니다. 중간에서 끝납니다.';

  @override
  String vaultIncomplete(Object parts) {
    return '이 파일은 온전하지 않습니다 — 전체 중 $parts만 있습니다.';
  }

  @override
  String vaultWillNotOpen(Object name) {
    return '이 백업에는 Lamplight가 열지 않을 것이 들어 있습니다($name).';
  }

  @override
  String countEntries(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개',
    );
    return '$_temp0';
  }

  @override
  String countDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
    );
    return '$_temp0';
  }

  @override
  String get backupCheckingItOpens => '열리는지 확인하는 중…';

  @override
  String get backupCouldNotSave => '백업을 저장할 수 없었습니다.';

  @override
  String get backupNothingLost => '아무것도 잃지 않았고 메모는 그대로입니다. 잠시 뒤에 다시 해 보세요.';

  @override
  String get backupLast => '마지막 백업';

  @override
  String get backupInTheVault => '금고 안에';

  @override
  String get restoreCheckingFile => '파일을 확인하는 중…';

  @override
  String get restoreCouldNotOpen => '그 파일은 열 수 없었습니다.';

  @override
  String get restoreCheckItIsTheOne => '원하던 백업이 맞는지 확인하고 다시 해 보세요.';

  @override
  String get restorePuttingInPlace => '제자리에 넣는 중…';

  @override
  String get restorePuttingBack => '이전 메모를 되돌리는 중…';

  @override
  String get restoreCouldNotFinish => '복원을 마치지 못했습니다.';

  @override
  String get restoreBackAsTheyWere => '메모는 원래대로 돌아왔습니다.';

  @override
  String get restoreUsePasscodeInstead => '대신 잠금번호 쓰기';

  @override
  String get restoreUseWordsInstead => '대신 열두 단어가 있습니다';

  @override
  String get backupCreateFile => '백업 파일 만들기';

  @override
  String get backupCreatedChecked => '백업을 만들고 확인했습니다.';

  @override
  String get backupMakeAnother => '하나 더 만들기';

  @override
  String get backupRestoreHeading => '복원';

  @override
  String get backupRestoreFrom => '백업 파일에서 복원';

  @override
  String backupProgress(String stage, int percent) {
    return '$stage $percent 퍼센트';
  }

  @override
  String get restoreTitle => '복원';

  @override
  String get restoreChooseFile => '파일 고르기';

  @override
  String get restoreUseLatest => '최신 백업 사용';

  @override
  String get restorePhraseHint => '기억 이야기 산업…';

  @override
  String get restoreAction => '복원';

  @override
  String get restoreChooseDifferent => '다른 파일 고르기';

  @override
  String get importChooseFolder => '폴더 고르기';

  @override
  String get importChooseFiles => '대신 파일 선택하기';

  @override
  String get importChooseFilesNote =>
      'Android가 폴더를 거부하면 — 다운로드나 저장소 최상위는 어떤 앱에도 주지 않습니다 — 파일을 직접 고르세요. 이것은 거부되지 않습니다.';

  @override
  String get importLooking => '폴더 안을 보는 중…';

  @override
  String get importNoTextFiles => '그 폴더에는 텍스트 파일이 없습니다.';

  @override
  String get importChooseDifferentFolder => '다른 폴더 고르기';

  @override
  String get importUseFileDate => '파일 자체의 날짜 쓰기';

  @override
  String get importUseFileDateNote =>
      '파일이 마지막으로 바뀐 날에 놓습니다. 그날이 글이 말하는 날이 아닌 경우가 많습니다.';

  @override
  String importBringIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 가져오기',
    );
    return '$_temp0';
  }

  @override
  String importProgress(int percent) {
    return '가져오는 중, $percent 퍼센트';
  }

  @override
  String get exportChooseFolder => '폴더 골라 내보내기';

  @override
  String get exportSave => '읽을 수 있는 사본 저장';

  @override
  String get exportWritten => '사본을 다 썼습니다.';

  @override
  String get exportAgain => '다시 내보내기';

  @override
  String get exportWhichOne => '어느 쪽이 필요할까요?';

  @override
  String get exportNotLocked => '이 사본은 잠겨 있지 않습니다';

  @override
  String dayAddedThings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '오늘에 $count개를 추가했습니다.',
    );
    return '$_temp0';
  }

  @override
  String get entryAddNote => '여기에 한마디 적기';

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 추가했습니다.',
    );
    return '$_temp0';
  }

  @override
  String get importFolderUnreadable => '그 폴더는 읽을 수 없었습니다.';

  @override
  String get importNothingBrought => '아무것도 가져오지 않았습니다.';

  @override
  String get importStoppedPartWay => '일기를 가져오다가 중간에 멈췄습니다.';

  @override
  String get importWhatArrivedKept => '멈추기 전에 들어온 것은 모두 남아 있습니다.';

  @override
  String get importNoReadableDates => '그 파일들에는 Lamplight가 읽을 수 있는 날짜가 없습니다.';

  @override
  String importReadyToBring(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개를 가져올 준비가 되었습니다.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingNew => '가져올 새로운 것이 없습니다.';

  @override
  String importBroughtIn(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개를 가져왔습니다.',
    );
    return '$_temp0';
  }

  @override
  String importAlreadyHere(Object count) {
    return '$count개는 이미 있어서 그대로 두었습니다.';
  }

  @override
  String importNoDateSkipped(Object count) {
    return '$count개는 읽을 날짜가 없어 건너뛰었습니다.';
  }

  @override
  String importCouldNotRead(Object count, Object names) {
    return '$count개는 읽을 수 없었습니다: $names';
  }

  @override
  String get exportStarting => '시작하는 중…';

  @override
  String get exportCouldNotFinish => '읽을 수 있는 사본을 끝내지 못했습니다.';

  @override
  String get exportNothingChanged => 'Lamplight 안에서는 아무것도 바뀌지 않았습니다.';

  @override
  String get importVideoAlreadySmall => '한 영상은 이미 충분히 작아서 그대로 두었습니다.';

  @override
  String get importVideoCouldNotShrink => '한 영상은 이 기기에서 줄일 수 없어 원본 그대로 두었습니다.';

  @override
  String importOneFailed(String reason) {
    return '하나가 되지 않았습니다: $reason';
  }

  @override
  String importAbandoned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lamplight가 잠기기 전에 $count개가 끝나지 못했습니다.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingLeft => '휴대폰에는 아무것도 남지 않았습니다.';

  @override
  String get nameCardAsk => '여기에 뭐라고 쓸까요?';

  @override
  String get nameCardHint => '이름이든, 무엇이든';

  @override
  String get reminderGroup => '원하시면, 가볍게 한 번';

  @override
  String get reminderFooter =>
      '켜기 전까지는 꺼져 있습니다. 기록의 내용은 결코 언급하지 않습니다 — 할 수도 없습니다. 금고가 잠긴 채로 돌아가니까요. 연속 기록도, 횟수도, 거른 날 이야기도 없습니다.';

  @override
  String get reminderTitle => '쓰라고 알려주기';

  @override
  String get reminderWhen => '언제';

  @override
  String get reminderProblemNotAllowed => 'Lamplight에 알림을 보낼 권한이 없습니다.';

  @override
  String get reminderProblemNotificationsOff =>
      '이 기기의 설정에서 Lamplight의 알림이 꺼져 있습니다.';

  @override
  String get reminderProblemRemindersOff =>
      '이 기기의 알림 설정에서 Lamplight의 리마인더가 꺼져 있습니다.';

  @override
  String get reminderProblemBatterySaving =>
      '이 기기는 Lamplight를 제한해 배터리를 아끼고 있습니다. 알림이 늦거나 오지 않는 흔한 이유입니다.';

  @override
  String get reminderMayNotArrive => '알림이 오지 않을 수도 있습니다';

  @override
  String get backupAutomatic => '알아서 백업';

  @override
  String get backupAutomaticDidNotFinish => '자동 백업이 끝나지 않았습니다.';

  @override
  String get backupNothingYet => '아직 백업할 것이 없습니다.';

  @override
  String get backupInProgress => '백업하는 중…';

  @override
  String get backupStartsAtUnlock => '다음에 잠금을 풀 때 시작합니다.';

  @override
  String get backupDoneAutomatically => '자동으로 백업했습니다.';

  @override
  String get backupLastOneFailed =>
      '지난번 자동 백업이 끝나지 않았습니다. 다음에 Lamplight를 열 때 다시 시도합니다.';

  @override
  String importNthOf(Object index, Object total) {
    return '$total 중 $index';
  }

  @override
  String importWaiting(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 대기 중',
    );
    return '$_temp0';
  }

  @override
  String get aboutCopied => '복사했습니다';

  @override
  String get failureGeneric => '그건 되지 않았습니다.';

  @override
  String get failureNothingLost => '아무것도 잃지 않았습니다 — 다시 해 보세요.';

  @override
  String get calendarNothingOnDay => '없음';

  @override
  String get backupChangeFolder => '폴더 바꾸기';

  @override
  String backupSavedTo(String place) {
    return '$place에 저장됩니다';
  }

  @override
  String get backupUseDefaultFolder => '기본 폴더 사용하기';

  @override
  String get backupChooseFolder => '사본을 둘 폴더를 고르세요';

  @override
  String get folderAndroidRestriction =>
      'Android는 어떤 앱에도 다운로드 폴더나 내부 저장소 전체를 내주지 않습니다. 문서 폴더나 그 안의 폴더는 됩니다.';

  @override
  String get folderNotWritable => '그 폴더에는 아무것도 저장할 수 없습니다. 다른 폴더를 골라 주세요.';

  @override
  String get folderRefused => '그 폴더는 쓸 수 없었습니다.';

  @override
  String get folderTryAnother => '다른 폴더를 골라 보세요.';

  @override
  String get aboutHowKept => '기록을 어떻게 보관하는가';

  @override
  String get aboutFonts => '글꼴과 라이선스';

  @override
  String get aboutVersion => '버전';

  @override
  String get aboutNoBrowser => '이 휴대폰에는 링크를 열 앱이 없습니다.';

  @override
  String get aboutMadeBy => '만든 사람';

  @override
  String get aboutMadeBySemantic =>
      'ProbablyPiyush가 만들었습니다. 브라우저에서 LinkedIn을 엽니다.';

  @override
  String get aboutCoffee => '커피 한 잔 사주기';

  @override
  String get aboutCoffeeSemantic => '커피 한 잔 사주기. 브라우저에서 페이지를 엽니다.';

  @override
  String get aboutCopyDetails => '내용 복사';

  @override
  String settingsNameSemantic(Object name) {
    return '$name. 눌러서 바꿉니다.';
  }

  @override
  String get settingsAddName => '이름 넣기';

  @override
  String get settingsNameOnlyHere => '이 기기 안에만';

  @override
  String get settingsNameOptional => '선택입니다. 이 기기를 벗어나지 않습니다.';

  @override
  String get reminderTurnedOffByAndroid =>
      'Android에서 Lamplight의 알림이 꺼져 있습니다. 기기 설정의 앱 항목에서 켤 수 있습니다.';

  @override
  String get reminderOnceADay => '하루에 한 번';

  @override
  String reminderTodayAt(Object time) {
    return '오늘 $time';
  }

  @override
  String reminderYesterdayAt(Object time) {
    return '어제 $time';
  }

  @override
  String reminderOnDateAt(Object date, Object time) {
    return '$date $time';
  }

  @override
  String get reminderNoneYet => '아직 아무것도 오지 않았습니다';

  @override
  String reminderLastArrived(Object when) {
    return '지난번은 $when에 왔습니다';
  }

  @override
  String reminderNextDue(Object when) {
    return '다음은 $when 예정입니다';
  }

  @override
  String get aboutHide => '숨기기';

  @override
  String get aboutCheckReal => '이것이 진짜 Lamplight인지 확인하기';

  @override
  String get entryRevisionsNote => '고치기 전에는 이렇게 적혀 있었습니다';

  @override
  String get entryStaysOnDay => '그날에도 그대로 남습니다';

  @override
  String entryDeleteKind(String kind) {
    return '$kind 지우기';
  }

  @override
  String get shareCouldNotAdd => '그건 넣지 못했습니다. 저장한 뒤 사진 버튼으로 해 보세요.';

  @override
  String get openNothingCanOpen => '이 휴대폰에는 그런 파일을 열 수 있는 것이 없습니다.';

  @override
  String get viewerMore => '더 보기';

  @override
  String get docLeavesLamplight => '이건 Lamplight 밖으로 나갑니다';

  @override
  String get docKeepItHere => '여기 두기';

  @override
  String get docOpenWith => '다른 앱으로 열기…';

  @override
  String docCannotShow(String kind) {
    return 'Lamplight는 PDF와 사진과 글을, 잠금을 푼 채로 휴대폰에 두지 않고도 보여줍니다. $kind 파일에는 다른 앱이 필요합니다 — 읽는 동안만 빌려주고, 끝나면 도로 가져옵니다.';
  }

  @override
  String get menuOpenWithNote => '다른 앱으로, 사본은 남기지 않고';

  @override
  String menuSaveKind(String kind) {
    return '$kind 저장';
  }

  @override
  String get menuTrashNote => '30일 보관했다가 사라집니다';

  @override
  String get videoBackTen => '10초 뒤로';

  @override
  String get videoForwardTen => '10초 앞으로';

  @override
  String get photoPlayVideo => '이 영상 재생';

  @override
  String get lockPhraseHint => '열두 단어를, 사이는 띄어서';

  @override
  String get lockUnlock => '열기';

  @override
  String get errorScreenDidNotOpen => '그 화면이 열리지 않았습니다. 잃은 것은 없습니다.';

  @override
  String get errorGoBack => '돌아가기';

  @override
  String recordingCannot(String what) {
    return '이 휴대폰에서는 녹음을 $what 수 없습니다. 녹음은 계속되고 있습니다.';
  }

  @override
  String get recordingClose => '닫기';

  @override
  String recordingElapsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '녹음 중, $count초',
    );
    return '$_temp0';
  }

  @override
  String get recordingStopKeep => '멈추고 이 녹음 남기기';

  @override
  String get recordingDiscard => '버리기';

  @override
  String get recordingCouldNotStart => '녹음을 시작할 수 없었습니다.';

  @override
  String get recordingCheckMicrophone => 'Lamplight에 마이크 사용이 허용되어 있는지 확인해 주세요.';

  @override
  String get recordingStartAgain => '다시 시작';

  @override
  String get recordingCouldNotSave => '그 녹음은 저장할 수 없었습니다.';

  @override
  String get recordingStillHere => '아직 여기 있습니다 — 다시 멈춰 보세요.';

  @override
  String get recordingCarryOnSemantic => '녹음 계속하기';

  @override
  String get recordingPauseSemantic => '이 녹음 일시정지';

  @override
  String get recordingCarryOn => '계속';

  @override
  String get recordingPause => '일시정지';

  @override
  String get sizeAdd => '추가';

  @override
  String get transcribeTitle => '말한 것을 받아쓰기';

  @override
  String get transcribeOn => '음성 메모를 찾을 수 있게 됩니다. 어디로도 보내지지 않습니다.';

  @override
  String get transcribeOff => '꺼져 있습니다. 음성 메모는 그날로만 찾을 수 있습니다.';

  @override
  String get transcribeLanguage => '말하는 언어';

  @override
  String get transcribeLanguageNote =>
      '녹음에서 쓰는 언어입니다. 한 번에 하나 — 중간에 바뀌는 문장은 여기에 맞는 쪽 절반만 돌아옵니다.';

  @override
  String get transcribeNotDownloaded => '이 휴대폰에 아직 없습니다 — 눌러서 받으세요.';

  @override
  String transcribeGetBetter(String name) {
    return '$name의 더 나은 모델 받기';
  }

  @override
  String get transcribeGetBetterNote =>
      '이것이 있으면 받아쓰기가 눈에 띄게 정확해집니다. 내려받는 쪽은 휴대폰이고 Lamplight가 아니며, 한 번만 합니다.';

  @override
  String get transcribeNoLanguages => '이 휴대폰이 아직 언어를 알려주지 않았습니다.';

  @override
  String get transcribeNeedsDownloading => '받아야 합니다';

  @override
  String folderStill(String day, String folder) {
    return '$day에 그대로 있습니다. $folder에도 있습니다.';
  }

  @override
  String get folderRenameTitle => '폴더 이름 바꾸기';

  @override
  String get folderNameHint => '사람, 장소, 시기';

  @override
  String get voicePlay => '이 음성 메모 듣기';

  @override
  String get voiceForwardThirty => '30초 앞으로';

  @override
  String voiceSpeed(String speed) {
    return '속도, 지금 $speed배';
  }

  @override
  String get voiceLengthUnknown => '음성 메모, 재생하기 전에는 길이를 알 수 없습니다';

  @override
  String get voicePosition => '녹음 안의 위치';

  @override
  String get voiceOpening => '녹음을 여는 중';

  @override
  String get voiceNoWords => '돌아온 말이 없습니다 — 다시 해 보세요';

  @override
  String get voiceWriteThis => '이걸 받아쓰기';

  @override
  String get voiceCannotWrite => '이 휴대폰은 음성 메모를 받아쓸 수 없습니다.';

  @override
  String get voiceLanguageMissing => '이 휴대폰이 그 언어를 아직 받지 않았습니다.';

  @override
  String get voiceWriting => '받아쓰는 중…';

  @override
  String get voiceWaiting => '받아쓰기를 기다리는 중.';

  @override
  String get voiceWritten => '이 휴대폰에서 받아썼습니다.';

  @override
  String get errorPartNotShown => '이 부분은 보여줄 수 없었습니다.';

  @override
  String get errorScreenShort => '그 화면이 열리지 않았습니다.';

  @override
  String get errorNothingLost => '잃은 것은 없습니다. 쓰신 것은 모두 금고 안에 그대로 있습니다.';

  @override
  String get errorHideDetails => '기술적인 내용 숨기기';

  @override
  String get errorShowDetails => '기술적인 내용 보기';

  @override
  String get errorDetailsNote =>
      '복사되는 것은 이것이 전부입니다. 무엇이 어디서 잘못됐는지 적혀 있고, 쓰신 내용은 들어 있지 않습니다.';

  @override
  String get passcodeChangeFailed => '암호를 바꾸지 못했습니다.';

  @override
  String get passcodeOldStillWorks => '이전 암호가 그대로 됩니다.';

  @override
  String get passcodeChanged => '암호를 바꿨습니다';

  @override
  String get passcodeWordsUnchanged =>
      '열두 단어는 바뀌지 않았고, 새로 만들 필요도 없습니다. 금고도 백업도 전과 똑같이 엽니다.';

  @override
  String get passcodeOldBackups =>
      '이미 있는 백업은 이전 암호로 열립니다. 지금 새로 만드는 것은 새 암호를 씁니다.';

  @override
  String get passcodeMakeBackup => '지금 백업 만들기';

  @override
  String get passcodeCurrent => '지금 암호';

  @override
  String get passcodeNewAgain => '새 암호 다시';

  @override
  String get passcodeOldBackupsNote => '이미 만들어 둔 백업 파일은 이전 암호로 열립니다.';

  @override
  String get passcodeWordsNote => '열두 개의 복구 단어는 바뀌지 않고 계속 됩니다.';

  @override
  String get licencesFonts =>
      '여기 모든 글꼴은 SIL Open Font License를 따릅니다. 내려받는 것은 없습니다 — 앱 안에 들어 있습니다.';

  @override
  String get licencesSource =>
      'Lamplight 자체는 앱스토어 예외가 붙은 GPL-3.0입니다. 소스가 곧 라이선스입니다. 누구든 읽고, 이 화면이 말하는 대로 앱이 동작하는지 확인할 수 있습니다.';

  @override
  String get licencesUnreadable => '그 라이선스 파일을 읽지 못했습니다.';

  @override
  String get appearanceSample =>
      '오후 내내 비. 차를 끓이고, 반 장을 읽고, 하려던 말은 잊고, 대신 이걸 썼다.';

  @override
  String get appearanceChromeNote => '버튼과 이름표는 이대로입니다';

  @override
  String get appearanceSizeNote =>
      '이것은 휴대폰 자체의 글자 크기 위에 더해집니다. 이미 키워 두셨다면, 여기서 더 커집니다.';

  @override
  String get voicePause => '일시정지';

  @override
  String get importIntro =>
      '다른 곳에 일기를 쓰셨다면 Lamplight가 가져올 수 있습니다 — 텍스트 파일이고 이름에 날짜가 있다면요.';

  @override
  String get importHowDates =>
      '텍스트 파일을 읽고 이름에서 날짜를 찾습니다 — 2026-08-24, 또는 24 August 2026 — 파일 이름이든 그 위 폴더 이름이든 어디든 좋습니다.';

  @override
  String get importAmbiguousDates =>
      '03-04-2026 같은 날짜는 일부러 건너뜁니다. 어떤 나라에서는 4월 3일이고 다른 나라에서는 3월 4일이라, 잘못 짐작하면 한 해의 삶을 아무 말 없이 엉뚱한 날에 놓게 됩니다.';

  @override
  String get importFormats =>
      'Lamplight는 일반 텍스트를 읽습니다: .txt, .md, .org, .log 등, 확장자가 아예 없는 파일도요. 일기가 다른 형식이라면 먼저 텍스트로 내보내세요.';

  @override
  String get importAtStartOfDay =>
      '모두 그날의 맨 앞에 놓입니다. 파일 이름은 날짜는 알려줘도 시각은 알려주지 않으니까요. Lamplight에 이미 있는 것은 바뀌지도 사라지지도 않고, 두 번 돌려도 사본이 생기지 않습니다.';

  @override
  String get importFileDateNote =>
      '파일이 마지막으로 바뀐 날에 놓습니다. 폴더를 기기 사이에 복사했다면, 그날은 쓴 날이 아니라 복사한 날일 수 있습니다.';

  @override
  String get importSkippedNote =>
      '이것들은 건너뜁니다. 있던 자리에 그대로 남고 — 폴더에서 아무것도 옮기거나 지우지 않습니다.';

  @override
  String get restoreChooseNote =>
      '백업 파일을 고르세요. 이름은 Lamplight-2026-08-18.vault 같은 형태입니다.';

  @override
  String get restorePasscodeNote => '이 파일의 암호를 입력하세요 — 백업을 만들 때 쓰던 그 암호입니다.';

  @override
  String get restoreWordsNote => '열두 단어를 순서대로, 사이를 띄어서 입력하세요.';

  @override
  String get restoreDoNotClose => '이것이 끝날 때까지 Lamplight를 닫지 마세요.';

  @override
  String get exportIntro =>
      'Lamplight 안의 모든 것을 고른 폴더에 평범한 파일로 씁니다 — 하루에 텍스트 파일 하나, 그리고 사진·영상·음성 메모·문서를 각자의 이름으로.';

  @override
  String get exportNoLamplightNeeded =>
      '그 폴더에 있는 것은 Lamplight 없이도 열립니다. 이 앱이 언젠가 멈추거나, 쓰지 않게 되더라도, 기록은 텍스트를 읽는 무엇으로든 열립니다.';

  @override
  String get exportWhichOneBody =>
      '읽을 수 있는 사본은 읽기 위한 것, 다른 앱으로 옮기기 위한 것, 또는 Lamplight를 그만둔 뒤에 무언가를 남겨두기 위한 것입니다. 보호되지 않습니다.\n\n백업 파일은 Lamplight를 그대로 되찾기 위한 것입니다 — 새 휴대폰이나, 고장 난 휴대폰을 위해. 암호로 잠겨 있어 어디에 두어도 안전하며, 클라우드도 괜찮습니다.\n\n대부분은 백업이 필요합니다. 절대 막히고 싶지 않다면 읽을 수 있는 사본도 함께 만들어 두세요.';

  @override
  String get exportNotLockedBody =>
      '여기에는 암호가 없습니다. 그 폴더를 여는 사람은 전부 읽을 수 있습니다. 그래도 괜찮은 곳에 두세요 — 그저 안전하게 보관할 것이 필요하다면 백업을 쓰세요.';

  @override
  String get backupConfirmNote =>
      '암호를 확인하세요. 이 파일은 모든 것을 열 수 있으니, 만드는 일은 뜻을 두고 하는 편이 좋습니다.';

  @override
  String get backupKeepSafeNote =>
      '백업은 지금 쓰는 암호로 잠겨 있습니다. 믿을 만한 곳에 두세요 — 클라우드도 괜찮습니다. 그 암호 없이는 파일을 읽을 수 없고, 저희는 그것을 결코 보지 않습니다.';

  @override
  String get backupRestoreWarning =>
      '백업을 열면 지금 Lamplight에 있는 모든 것이 대체됩니다. 복원한 것이 열린다는 것이 확인될 때까지, 지금의 기록은 따로 보관됩니다.';

  @override
  String get folderWhatItIs => '폴더는 당신의 날들을 꿰는 실입니다 — 한 사람, 한 장소, 한 시절.';

  @override
  String get folderNothingMoves =>
      '폴더로 옮겨지는 것은 없습니다. 기록은 자기 날에 그대로 있고, 여기에도 함께 보입니다.';

  @override
  String get folderDeleteNote =>
      '폴더는 사라집니다. 안에 있던 것은 모두 제자리에, 각자의 날에 그대로 남습니다.';

  @override
  String get folderNoneInHere =>
      '아직 아무것도 없습니다. 어떤 날의 무언가를 길게 눌러 “폴더에 넣기”를 고르세요.';

  @override
  String get passcodeRuleLength => '여덟 자 이상.';

  @override
  String get passcodeRuleWords => '기억할 수 있는 평범한 낱말 몇 개가, 기호가 든 짧은 것보다 낫습니다.';

  @override
  String get passcodeNoMatch => '아직 둘이 같지 않습니다.';

  @override
  String get docCopyInClear =>
      '사본은 잠금 없이 쓰이므로, 당신의 파일을 읽을 수 있는 앱이면 읽을 수 있습니다. Lamplight 안에 남는 것은 어느 쪽이든 잠긴 채로 있습니다.';

  @override
  String docPageOf(String page, String total) {
    return '$total 중 $page';
  }

  @override
  String get transcribeTookTooLong =>
      '그 녹음은 받아쓰는 데 너무 오래 걸려서 Lamplight가 기다리기를 멈췄습니다. 나중에 다시 시도합니다.';

  @override
  String get transcribeCouldNotWriteDown => '그 녹음은 받아쓸 수 없었습니다.';

  @override
  String get transcribeRecordingIsSafe => '녹음 자체는 안전합니다. Lamplight가 다시 시도합니다.';

  @override
  String voicePositionSpoken(Object at, Object total) {
    return '$total 중 $at';
  }

  @override
  String entryEditedAt(Object time) {
    return '$time · 고침';
  }

  @override
  String get docCouldNotOpen => '그 문서는 열 수 없었습니다.';

  @override
  String albumThisOne(Object thing) {
    return '이 $thing';
  }

  @override
  String albumThisOneOf(Object index, Object thing, Object total) {
    return '이 $thing — $total 중 $index';
  }

  @override
  String get albumCaptionThese => '여기에 한마디 적기';

  @override
  String get albumCaptionThis => '한마디 적기';

  @override
  String get albumCaptionEdit => '적은 내용 고치기';

  @override
  String albumOthersStay(Object count) {
    return '나머지 $count개는 그대로입니다. 이것은 30일 동안 휴지통에 들어갑니다.';
  }

  @override
  String get albumGoesToTrash => '30일 동안 휴지통에 들어갑니다.';

  @override
  String get photoCouldNotOpen => '이 사진은 열 수 없었습니다.';

  @override
  String get photoMayBeDamaged => '손상되었을 수 있습니다.';

  @override
  String get docTooBig =>
      '이 파일은 Lamplight 안에서 열기에는 너무 큽니다. 사본을 저장해 다른 곳에서 열 수 있습니다.';

  @override
  String docPages(Object count) {
    return '$count쪽';
  }

  @override
  String get docFileEmpty => '이 파일은 비어 있습니다.';

  @override
  String videoTooBig(Object size) {
    return '이 영상은 여기서 재생하기에 너무 큽니다 — $size. 그러려고 보호 없이 내보내지는 않습니다. 사본을 저장해 다른 곳에서 보세요.';
  }

  @override
  String get videoNotAvailableHere => '앱의 이 부분은 이 기기에서 쓸 수 없습니다.';

  @override
  String get videoCouldNotOpen => '이 영상은 열 수 없었습니다.';

  @override
  String get docGoToPage => '페이지로 이동';

  @override
  String get docGo => '이동';

  @override
  String get docPageCouldNotBeDrawn => '이 페이지는 그릴 수 없었습니다.';

  @override
  String get passcodeRuleStronger => '한두 낱말만 더해도 훨씬 알아맞히기 어려워집니다.';

  @override
  String get backupAutoFooter =>
      '자동 백업은 Lamplight를 열 때, 지난번 이후 바뀐 것이 있으면 실행됩니다. 직접 만든 것과 똑같이 암호로 잠깁니다.';

  @override
  String get aboutHowKeptBody =>
      '계정이 없습니다. 서버도 없습니다. 아무것도 이 휴대폰을 떠나지 않습니다.\n\n기록은 암호로 잠기고, 열쇠는 그 암호에서 만들어집니다 — 그래서 그 사본은 어디에도 없습니다. 저희에게도요.';

  @override
  String get aboutFree => 'Lamplight는 무료이고 앞으로도 그렇습니다. 풀어야 할 것이 없습니다.';

  @override
  String get aboutContact => '문제가 있나요? 알려주세요.';

  @override
  String get aboutContactSemantic => '이메일로 의견 보내기';

  @override
  String aboutNoMail(String address) {
    return '이 휴대에 이메일 앱이 없습니다. 주소는 $address 입니다.';
  }

  @override
  String get backupOnItsOwn => '알아서';

  @override
  String get actionDismiss => '닫기';

  @override
  String importRange(String from, String to) {
    return '$from부터 $to까지.';
  }

  @override
  String get sizeOneCopy => 'Lamplight는 사본을 하나만 둡니다. 여기서 고른 것이 곧 갖게 되는 것입니다.';

  @override
  String get sizeAddAlways => '추가하고 다시 묻지 않기';

  @override
  String get trashNothingHere => '여기에는 아무것도 없습니다.';

  @override
  String get appearanceAaQuiet => 'Aa\n고요';

  @override
  String lockWarnSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '약 $count초 뒤에 잠깁니다.',
    );
    return '$_temp0';
  }

  @override
  String get lockWarnChange => '잠금과 보안에서 바꿀 수 있습니다.';

  @override
  String get openingLabel => 'Lamplight를 여는 중';

  @override
  String get recordingNoMic =>
      'Lamplight가 마이크를 쓸 수 없습니다. 휴대폰 설정의 앱에서 켜실 수 있습니다.';

  @override
  String get recordingPaused => '멈춤. 지금은 아무것도 듣고 있지 않습니다.';

  @override
  String get videoOpening => '영상을 여는 중…';

  @override
  String albumRemoveThis(String thing) {
    return '이 $thing 빼기';
  }

  @override
  String get revisionsNote =>
      '고치기 전에는 이렇게 적혀 있었습니다. 여기에는 버튼이 없습니다 — 글자를 골라 복사하실 수 있습니다.';

  @override
  String get composerSemantic => '이 날에 대해 쓰기';

  @override
  String importStripAdding(String name) {
    return '$name 추가하는 중';
  }

  @override
  String passcodeAtLeast(int count) {
    return '$count자 이상';
  }

  @override
  String get searchKindAll => '전체';

  @override
  String get searchKindWords => '글';

  @override
  String get searchKindVoice => '음성';

  @override
  String get searchKindPhotos => '사진';

  @override
  String get searchKindFiles => '파일';

  @override
  String passcodeAtLeastShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count자 이상',
    );
    return '$_temp0';
  }

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 남음',
    );
    return '$_temp0';
  }

  @override
  String get trashGoneToday => '오늘 사라집니다';

  @override
  String restoreMadeOn(String date) {
    return '$date에 만듦';
  }

  @override
  String restoreDone(String entries, String days) {
    return '$days에 걸쳐 $entries을(를) 복원했습니다. 다시 오신 것을 환영합니다.';
  }

  @override
  String importFoundUndated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lamplight가 읽을 날짜가 없는 것 $count개',
    );
    return '$_temp0';
  }

  @override
  String entrySemantic(String time) {
    return '$time의 기록. 눌러서 고치기.';
  }

  @override
  String entrySemanticEdited(String time) {
    return '$time의 기록, 수정함. 눌러서 고치기.';
  }

  @override
  String onThisDaySemantic(String when, String body) {
    return '$when. $body. 누르면 그날로 갑니다.';
  }

  @override
  String attachmentSemantic(String what, String time) {
    return '$time의 $what. 두 번 누르면 열립니다.';
  }

  @override
  String dayHeaderToday(String date) {
    return '$date, 오늘';
  }

  @override
  String get yearGridNothing => '이 날에는 아무것도 없습니다';

  @override
  String get calendarNothing => '이 날에는 아무것도 없습니다';

  @override
  String importStripCounted(String name, String counted) {
    return '$name 추가하는 중$counted';
  }

  @override
  String get aboutFingerprintBody =>
      '모든 빌드에는 만든 사람만 만들 수 있는 서명이 붙습니다. 이것은 지금 손에 든 사본의 서명입니다. 소스와 함께 공개된 지문과 맞춰 보세요 — 일치하면, 그 소스가 만들어 내는 바로 그 앱입니다.';

  @override
  String get searchKindVideo => '영상';

  @override
  String get semanticOn => '켜짐';

  @override
  String andMore(int count) {
    return '외 $count개';
  }

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개',
      zero: '없음',
    );
    return '$_temp0';
  }

  @override
  String get checkDone => '충족';

  @override
  String get checkNotYet => '아직';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
    );
    return '$_temp0';
  }

  @override
  String get lockUseYourPasscode => '패스코드를 사용하세요.';

  @override
  String get searchWordsExample => '당신이 쓴 모든 것';

  @override
  String get searchAFile => '파일';

  @override
  String get searchFileExample => 'scan.pdf · IMG_2831';

  @override
  String get searchAFolder => '폴더';

  @override
  String get searchFolderExample => '직접 붙인 이름';

  @override
  String get searchByFileName => '파일 이름으로';

  @override
  String get searchARecording => '녹음';

  @override
  String get searchAnEntry => '기록';

  @override
  String get sizeThisOne => '이것';

  @override
  String get sizeTheseOnes => '이것들';

  @override
  String get passcodeOneMoreCharacter => '한 글자만 더.';

  @override
  String passcodeMoreCharacters(int count, int minimum) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count글자 더 — 최소 $minimum글자입니다.',
    );
    return '$_temp0';
  }

  @override
  String get passcodeTooObvious => '누구나 가장 먼저 시도해 볼 만한 것입니다. 다른 것을 고르세요.';

  @override
  String get passcodeSameCharacter => '같은 글자의 반복입니다.';

  @override
  String get passcodeStraightRun => '글자가 순서대로 이어진 것입니다.';

  @override
  String attachmentLoading(String time) {
    return '$time 첨부, 불러오는 중';
  }

  @override
  String videoSemantic(String time, String length) {
    return '$time 동영상, $length. 두 번 누르면 재생됩니다.';
  }

  @override
  String voiceSemantic(String time, String length) {
    return '$time 음성 메모, $length. 두 번 누르면 재생됩니다.';
  }

  @override
  String fileSemantic(String time, String name, String size) {
    return '$time 파일, $name, $size. 두 번 누르면 열립니다.';
  }

  @override
  String get lengthUnknown => '길이를 알 수 없음';

  @override
  String get settingsLockNone => '자동 잠금 없음';

  @override
  String settingsLockAfter(String duration) {
    return '$duration 후';
  }

  @override
  String settingsSecuritySummary(String lock) {
    return '패스코드, 지문, $lock';
  }

  @override
  String get keptNoNetworkTitle => '어디로도 가지 않습니다';

  @override
  String get keptNoNetworkBody =>
      'Lamplight는 인터넷을 사용할 수 없습니다. \'사용하지 않는다\'가 아니라 \'사용할 수 없다\'입니다. 안드로이드가 권한을 주지 않으며, 휴대전화의 앱 설정에서 30초면 직접 확인할 수 있습니다.';

  @override
  String get keptPasscodeTitle => '당신의 패스코드가 열쇠입니다';

  @override
  String get keptPasscodeBody =>
      '메모를 여는 열쇠는 잠금을 해제할 때마다 패스코드로부터 만들어집니다. 어디에도 저장되지 않으므로 찾아낼 수도, 잃어버릴 수도, 넘겨줄 수도 있는 사본이 없습니다.';

  @override
  String get keptForgetTitle => '잊어버렸다면';

  @override
  String get keptForgetBody =>
      '열두 단어가 들어올 수 있는 유일한 다른 방법입니다. 여기서는 누구도 패스코드를 재설정할 수 없으며, 이는 위와 같은 사실입니다 — 당신을 다시 들여보낼 수 있는 앱은 다른 사람도 들여보낼 수 있습니다.';

  @override
  String get keptNothingReadableTitle => '읽을 수 있는 것은 아무것도 남지 않습니다';

  @override
  String get keptNothingReadableBody =>
      '사진, 녹음, 파일은 저장소에 닿기 전에 암호화됩니다. 어떤 것도 평문으로 기록되지 않습니다. 당신이 보고 있는 잠깐 동안조차도요.';

  @override
  String get keptLocksItselfTitle => '스스로 잠깁니다';

  @override
  String get keptLocksItselfBody =>
      'Lamplight가 백그라운드로 넘어가는 순간 열쇠는 파기됩니다. 스크린샷은 차단되며, 최근 앱 미리보기에도 나타나지 않습니다.';

  @override
  String get keptBackUpTitle => '백업해 두세요';

  @override
  String get keptBackUpBody =>
      '모든 것이 이 휴대전화에만 있고 다른 어디에도 없습니다. 그것이 이 앱의 핵심이자 동시에 위험입니다. 백업은 당신의 패스코드만 열 수 있는 암호화된 파일 하나입니다. 어딘가에 하나 보관해 두세요.';
}
