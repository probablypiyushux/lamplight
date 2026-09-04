// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class LJa extends L {
  LJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Lamplight';

  @override
  String get lockTypePasscode => 'パスコードを入力してください。';

  @override
  String get lockWrongPasscode => 'これでは開きませんでした。';

  @override
  String get lockCheckAndRetry => 'パスコードを確かめて、もう一度お試しください。';

  @override
  String get lockForgot => 'パスコードを忘れました';

  @override
  String get lockTypeTwelveWords => '12個の単語を入力してください。';

  @override
  String get lockUsePasscodeInstead => 'パスコードを使う';

  @override
  String get lockUseFingerprint => '指紋を使う';

  @override
  String get lockFingerprintFailed => '指紋では開きませんでした。';

  @override
  String get lockFingerprintUnavailable => '指紋は使えません。';

  @override
  String get lockOpening => '開いています…';

  @override
  String get lockNothingDeleted => '何も消えていませんし、これから消えることもありません。';

  @override
  String lockTryAgainSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count秒後にもう一度お試しください。',
    );
    return '$_temp0';
  }

  @override
  String lockTryAgainMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count分後にもう一度お試しください。',
    );
    return '$_temp0';
  }

  @override
  String get dayToday => 'きょう';

  @override
  String get dayPrevious => '前の日';

  @override
  String get dayNext => '次の日';

  @override
  String get daySearch => 'さがす';

  @override
  String get daySettings => '設定';

  @override
  String get dayChooseDate => '別の日を選ぶ。';

  @override
  String get dayEmptyToday => '何か残しておきたいことは？';

  @override
  String get dayEmptyPast => 'この日には何もありません。';

  @override
  String get dayWriteSomething => 'きょうのことを書く';

  @override
  String get dayLineAsk => 'どんな一日でしたか？';

  @override
  String get dayLineHint => 'どんな一日でしたか？';

  @override
  String get dayLineSemantic => 'この日がどんな日だったか、一行で';

  @override
  String dayLineChange(String note) {
    return 'この日：$note。変更する。';
  }

  @override
  String get dayEndOfDay => '一日の終わり';

  @override
  String get dayStartOfDay => '一日のはじまり';

  @override
  String get firstPageTitle => 'まだ何も書いていないので、ここは空です。';

  @override
  String get firstPageShelves => '日付が棚です。残したものは、それが起きた日に置かれて、そのまま残ります。';

  @override
  String get firstPageWayWrite => 'このページに触れると書けます。';

  @override
  String get firstPageWayVoice => 'マイクを押したままにすれば、話して残せます。';

  @override
  String get firstPageWayAttach => '写真や動画、書類を追加できます。';

  @override
  String get firstPagePromise => 'どれもこの端末から出ていきません。';

  @override
  String get firstPageSemantic => '日記の最初のことを書く';

  @override
  String get captureVoice => '音声を録る';

  @override
  String get capturePhoto => '写真を撮る・選ぶ';

  @override
  String get captureFile => 'ファイルを添える';

  @override
  String get backupNeverMade =>
      'ここにはバックアップがありません。このアプリが削除されると、書いたものも一緒になくなります。';

  @override
  String get backupStale => '前回のバックアップから時間が経っています。';

  @override
  String get backupOutOfDate => 'バックアップは今も古いパスコードで開きます。';

  @override
  String get backupAction => 'バックアップ';

  @override
  String folderAlsoIn(String name) {
    return '$name にもあります。フォルダを開く。';
  }

  @override
  String get folderStaysHere => '元の場所にそのまま残ります。フォルダは見つけるための二つ目の場所です。';

  @override
  String get folderAddTo => 'フォルダに入れる';

  @override
  String get folderNew => '新しいフォルダ';

  @override
  String get folderNoneYet => 'まだフォルダはありません。人ごとに一つ、あるいは時期ごとに——何度も戻ってくるものを。';

  @override
  String folderLesson(String day, String folder) {
    return '$day のままです。$folder にもあります。';
  }

  @override
  String get actionDone => '完了';

  @override
  String get actionCancel => 'やめる';

  @override
  String get actionDelete => '削除';

  @override
  String get actionSave => '保存';

  @override
  String get actionEdit => '編集';

  @override
  String get actionUndo => '元に戻す';

  @override
  String get actionOpen => '開く';

  @override
  String get actionRemove => '外す';

  @override
  String get actionNotNow => 'あとで';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsAppearance => '見た目';

  @override
  String get settingsSecurity => 'ロックと安全';

  @override
  String get settingsYourNotes => 'あなたの記録';

  @override
  String get settingsBackup => 'バックアップ';

  @override
  String get settingsAbout => 'このアプリについて';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsLanguageNote =>
      'アプリが使うことばです。あなたが書くものは、どの言語でも、この設定にかかわらずあなたのものです。';

  @override
  String get settingsLanguageSystem => '端末に合わせる';

  @override
  String get entryMattered => 'これは大事だった';

  @override
  String get entryMarked => '大事だったものとして印をつけました。';

  @override
  String get entryMarkRemoved => '印を外しました。';

  @override
  String get entryDeleted => '削除しました。';

  @override
  String entryEarlierVersions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '以前のもの $count 件',
    );
    return '$_temp0';
  }

  @override
  String get entryKeepsWords => '言葉はそのまま';

  @override
  String entryKindInTrash(Object kind) {
    return '$kindはごみ箱にあります。';
  }

  @override
  String entryKindInTrashWords(Object kind) {
    return '$kindはごみ箱にあります。言葉はここに残っています。';
  }

  @override
  String trashConfirmBody(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件と、その以前のものすべて。これは取り消せません。',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyEntry => '空のもの';

  @override
  String get kindPhoto => '写真';

  @override
  String get kindVideo => '動画';

  @override
  String get kindRecording => '録音';

  @override
  String get kindFile => 'ファイル';

  @override
  String get entryNoLongerMarked => '印を外す';

  @override
  String get entryFindAgain => '検索画面からまた見つけられます';

  @override
  String get searchGoTo => '移動';

  @override
  String get searchFolders => 'フォルダ';

  @override
  String get searchEntriesOne => '1件';

  @override
  String searchEntriesMany(int count) {
    return '$count件';
  }

  @override
  String get searchNothingFound => '見つかりませんでした。';

  @override
  String get searchEverythingInstead => 'すべてを検索する';

  @override
  String get searchNoneOfThese => 'その種類のものはまだありません。';

  @override
  String get onboardNoAccount => 'アカウントはありません。';

  @override
  String get onboardPromiseBody =>
      'ノートはこの端末の中にとどまります。\nサーバーはありません。私たちには読めません。\n取り戻すこともできません。';

  @override
  String get onboardBegin => 'はじめる';

  @override
  String get onboardHaveBackup => 'バックアップがあります';

  @override
  String get onboardSetPasscode => 'パスコードを決める';

  @override
  String get onboardPasscodeBody => 'ノートを開けるのはこれだけです。覚えていられる一文は、4桁の数字より強固です。';

  @override
  String get onboardPasscodeLabel => 'パスコード';

  @override
  String get onboardPasscodeAgain => 'もう一度入力してください';

  @override
  String get onboardSettingUp => '準備しています…';

  @override
  String get onboardContinue => '続ける';

  @override
  String get onboardPasscodesDiffer => 'この二つが一致しません。';

  @override
  String get onboardVaultFailed => '作成できませんでした。';

  @override
  String get onboardVaultFailedThen => '何も保存されていません。もう一度お試しください。';

  @override
  String get onboardWriteWords => 'この12個の単語を\n紙に書いてください';

  @override
  String get onboardWordsBody =>
      '控えはありません。お送りすることもできません。助けられるサポート窓口もありません。\n\nスクリーンショットではなく紙に。スクリーンショットは写真フォルダに残り、そこは誰もが最初に見る場所です。';

  @override
  String get onboardWrittenDown => '書き留めました';

  @override
  String get onboardCopyWords => '12個の単語をコピー';

  @override
  String get onboardClipboardNote => 'クリップボードは1分後に自動で消えます。それまでは他のアプリからも読めます。';

  @override
  String get onboardCopied => 'コピーしました。1分で自動的に消えます — 今のうちに安全な場所へ貼り付けてください。';

  @override
  String get onboardCopyFailed => 'コピーできませんでした。どのみち手で書く方が安全です。';

  @override
  String get onboardCheckThree => 'うち3つを確かめます';

  @override
  String get onboardCheckBody => '紙が合っていることを確かめるためです。画面ではなく。';

  @override
  String onboardWordNumber(int number) {
    return '$number番目の単語';
  }

  @override
  String onboardWordWrong(int number) {
    return '$number番目の単語が違います。書き留めたものを見てください。';
  }

  @override
  String get onboardShowWords => 'もう一度単語を見る';

  @override
  String get onboardFingerprintTitle => '指紋で開きますか？';

  @override
  String get onboardFingerprintBody => '毎回あの一文を入力せずにすむように。';

  @override
  String get onboardFingerprintExplain =>
      '鍵は引き続きあなたの一文です。指紋が開けるのはこの保管庫だけ、この端末だけです。端末の指紋が変われば Android が自動で無効にします — 誰かが自分の指紋を追加して入れないように。バックアップに含まれることは決してありません。';

  @override
  String get onboardFingerprintWaiting => '指を待っています…';

  @override
  String get onboardFingerprintUse => '指紋を使う';

  @override
  String get onboardFingerprintFailed => 'うまくいきませんでした。';

  @override
  String get onboardOneLastThing => '最後にひとつ';

  @override
  String get onboardNameBody =>
      'Lamplight はあなたを何と呼べばいいですか？この端末にだけ残り、あとから変えても、空のままでもかまいません。';

  @override
  String get onboardFingerprintOn => 'これからは指紋で Lamplight が開きます。';

  @override
  String get onboardYourName => 'お名前';

  @override
  String get onboardStartWriting => '書きはじめる';

  @override
  String get onboardSkip => 'スキップ';

  @override
  String get settingsGroupLook => '見た目と、話すことば';

  @override
  String get settingsGroupWhoCanOpen => 'だれが開けるか';

  @override
  String get settingsGroupKeeping => 'とっておく、持ち出す';

  @override
  String get settingsAppearanceNote => 'テーマ、書体、色、ページ';

  @override
  String get settingsFolders => 'フォルダ';

  @override
  String get settingsFoldersNote => '人、場所、時期';

  @override
  String get settingsMedia => 'メディア';

  @override
  String get settingsMediaNote => '写真、動画、音声、書類';

  @override
  String get mediaGroupDocuments => '書類';

  @override
  String get mediaDocumentsKept => '届いたそのままの形で保管します';

  @override
  String get mediaDocumentsFooter =>
      'PDF や Word のファイルは中身がすでに圧縮されているので、もう一度縮めても五パーセントほどしか変わりません。本当に小さくするには中の画像を作り直すことになり、スキャンした小さな文字が元に戻らないほどぼやけます。しかもそれに気づくのは何年も先、それを読む必要が生じた日です。';

  @override
  String get settingsTrash => 'ごみ箱';

  @override
  String get settingsTrashNote => '消したものは30日間残ります';

  @override
  String get settingsReadableCopy => '読める形のコピー';

  @override
  String get settingsReadableCopyNote => 'Markdown とファイルを、選んだフォルダへ';

  @override
  String get settingsBringIn => 'むかしの日記を取り込む';

  @override
  String get settingsBringInNote => 'ほかのアプリのテキストファイルを、名前の日付で仕分けます';

  @override
  String get settingsKeepingFooter =>
      'バックアップはパスコードで閉じられています。保管庫と同じです。読める形のコピーはまったく閉じられていません — 選んだフォルダに置かれる、ふつうのファイルです。';

  @override
  String get backupNever => 'まだバックアップしていません';

  @override
  String get backupToday => '今日バックアップしました';

  @override
  String get backupYesterday => '昨日バックアップしました';

  @override
  String backupDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日前にバックアップしました',
    );
    return '$_temp0';
  }

  @override
  String get mediaGroupIncoming => '取り込むとき';

  @override
  String get mediaGroupVoice => 'ボイスメモ';

  @override
  String get mediaIncomingFooter =>
      'Lamplight は小さい方の控えを二重に持つことはありません。ここで選んだものがそのまま保存され、元のファイルはどこにも残りません。';

  @override
  String get mediaVoiceFooter =>
      '書き起こしはこの端末の中で、Android がもともと持っている音声認識で行われます。Lamplight に話したことがどこかへ送られることはなく、送るための権限もありません。';

  @override
  String get mediaPhotoSize => '写真のサイズ';

  @override
  String get mediaVideoSize => '動画のサイズ';

  @override
  String get mediaAskEachTime => '毎回たずねる';

  @override
  String get accentAmber => '琥珀';

  @override
  String get accentAmberNote => '夜のあかり。ふだんはこれ。';

  @override
  String get accentRose => 'ローズ';

  @override
  String get accentRoseNote => 'あたたかいピンク。琥珀よりやわらかく。';

  @override
  String get accentSage => 'セージ';

  @override
  String get accentSageNote => '静かな緑。六つのなかでいちばん穏やか。';

  @override
  String get accentSlate => 'スレート';

  @override
  String get accentSlateNote => '冷たい青みの灰。いちばん素直。';

  @override
  String get accentPlum => 'プラム';

  @override
  String get accentPlumNote => '深い紫。';

  @override
  String get accentEmber => '熾火';

  @override
  String get accentEmberNote => '焦げたオレンジ。いちばんあたたかい。';

  @override
  String get surfacePlain => '無地';

  @override
  String get surfacePlainNote => '平らな紙面。';

  @override
  String get surfacePaper => '紙';

  @override
  String get surfacePaperNote => '細かな地合いがあって、余白ではなく紙に見えます。ふだんはこれ。';

  @override
  String get surfaceLamplit => 'あかりの下';

  @override
  String get surfaceLamplitNote => '紙に、あかりをともして。';

  @override
  String get surfaceStarMap => '星図';

  @override
  String get surfaceStarMapNote => 'ひとつの空が、時計とともにまわります。一日のうちに同じ空は二度ときません。';

  @override
  String get rulingNone => 'なし';

  @override
  String get rulingNoneNote => '紙面には何も刷りません。';

  @override
  String get rulingLines => '罫線';

  @override
  String get rulingLinesNote => 'ノートのような横罫。';

  @override
  String get rulingIsometric => 'アイソメ';

  @override
  String get rulingIsometricNote => '製図用紙。三次元で考えるために。';

  @override
  String get rulingTriangle => '三角';

  @override
  String get rulingTriangleNote => '正三角形をしきつめた地。';

  @override
  String get rulingDots => 'ドット方眼';

  @override
  String get rulingDotsNote => '交点ごとにひとつの点。四つのなかでいちばん静か。';

  @override
  String get faceSystem => 'システム';

  @override
  String get faceSystemNote => 'この端末のほかの場所と同じ書体。';

  @override
  String get faceSerif => 'システムの明朝';

  @override
  String get faceSerifNote => 'この端末が持っている明朝体。';

  @override
  String get faceCalmNote => 'やわらかい角、ひろい字幅。';

  @override
  String get faceModernNote => '引きしまって、いまの空気。';

  @override
  String get faceOldStyleNote => '16世紀の本の書体。';

  @override
  String get facePlayfulNote => 'まるくて、陽気。';

  @override
  String get faceChildlikeNote => '学習ノート。';

  @override
  String get faceHandwrittenNote => '手書きの姿で、一ページ読んでも疲れません。';

  @override
  String get faceMedievalNote => '写字生の手。太さはひとつだけ。';

  @override
  String get faceMonoNote => 'すべての字がおなじ幅。';

  @override
  String get qualityOriginal => '元のまま残す';

  @override
  String get qualityBalanced => 'ちょうどよく';

  @override
  String get qualitySmaller => '小さめ';

  @override
  String get photoOriginalNote =>
      'カメラが撮ったそのままで残します。いちばん大きなファイルになり、撮った場所の記録も残ります — Lamplight がふだんは取り除いているものです。';

  @override
  String get photoBalancedNote => 'ずっと小さく、元との違いはほとんどわかりません。ふだんはこれ。';

  @override
  String get photoSmallerNote => 'さらに半分。強く切り出すと気づくかもしれません。';

  @override
  String get videoOriginalNote => 'カメラが録ったそのままで残します。ファイルは群を抜いて大きくなります。';

  @override
  String get videoBalancedNote => 'ずっと小さく、元との違いはほとんどわかりません。ふだんはこれ。';

  @override
  String get videoSmallerNote => 'さらに半分。大きな画面では気づくかもしれません.';

  @override
  String get appearanceTitle => '見た目';

  @override
  String get appearanceTheme => 'テーマ';

  @override
  String get appearanceThemeDark => 'ダーク';

  @override
  String get appearanceThemeLight => 'ライト';

  @override
  String get appearanceThemeAuto => '自動';

  @override
  String get appearanceThemeAutoNote => '端末のライト・ダークの設定にあわせます。';

  @override
  String get appearanceFont => '書体';

  @override
  String get appearanceSize => '大きさ';

  @override
  String get appearanceColour => '色';

  @override
  String get appearancePage => 'ページ';

  @override
  String get appearanceRuling => '罫';

  @override
  String get daySavedToToday => '今日に保存しました。';

  @override
  String get dayAddedToToday => '今日に追加しました。';

  @override
  String get entryEditWords => '文章を直す';

  @override
  String get entryDeleteBlock => 'このかたまりごと削除';

  @override
  String entrySavedAs(String name) {
    return '$name として保存しました。';
  }

  @override
  String entryAddedToFolder(String name) {
    return '$name にも入っています。';
  }

  @override
  String get entrySaveCopy => 'コピーを保存';

  @override
  String get entrySaveCopyNote => 'Lamplight の外の、選んだ場所へ';

  @override
  String get capturePhotoTake => '写真をとる';

  @override
  String get capturePhotoChoose => '写真から選ぶ';

  @override
  String get composerHintToday => '今日のことを…';

  @override
  String get composerHintPast => 'この日のことを…';

  @override
  String get composerNewBlock => 'あたらしいかたまり';

  @override
  String get voiceShowTranscript => '話した内容を見る';

  @override
  String get voiceHideTranscript => '話した内容を隠す';

  @override
  String get voiceTranscriptTitle => '話した内容';

  @override
  String get entryEdited => '、編集済み';

  @override
  String photoSemantic(String time) {
    return '$time の写真。ダブルタップで開きます。';
  }

  @override
  String get sizeThisPhoto => 'この写真';

  @override
  String get sizeThesePhotos => 'これらの写真';

  @override
  String get sizeThisVideo => 'この動画';

  @override
  String get sizeTheseVideos => 'これらの動画';

  @override
  String sizeQuestion(String what) {
    return '$whatはどの大きさで残しますか？';
  }

  @override
  String get trashNote => '消したものは30日ここに残り、そのあと完全になくなります。';

  @override
  String get trashConfirm => 'これらを完全に消しますか？';

  @override
  String get trashKeep => '残しておく';

  @override
  String get trashDeleteForGood => '完全に消す';

  @override
  String get trashPutBack => '戻す';

  @override
  String trashPutBackOn(String day) {
    return '$day に戻しました。';
  }

  @override
  String get trashEmpty => 'ごみ箱を空にする';

  @override
  String get folderMakeFirst => '最初のひとつをつくる';

  @override
  String folderDeleteAsk(String name) {
    return '「$name」を消しますか？';
  }

  @override
  String get folderKeepIt => '残しておく';

  @override
  String get folderDeleteIt => 'フォルダを消す';

  @override
  String get folderRename => '名前を変える';

  @override
  String get folderDeleteThis => 'このフォルダを消す';

  @override
  String folderTakenOut(String name) {
    return '$name から外しました。その日には残っています。';
  }

  @override
  String get searchHint => 'ことば、日付、名前…';

  @override
  String get searchBack => 'もどる';

  @override
  String get searchClear => '消す';

  @override
  String searchNothingMatches(String query) {
    return '「$query」に合うものはありません。';
  }

  @override
  String get searchWhatMattered => 'だいじだったこと';

  @override
  String get searchADate => '日付';

  @override
  String get searchDateExample => '2006年3月16日 · 2006年3月 · きのう';

  @override
  String get searchWhatYouCanType => '探せるもの';

  @override
  String get searchTryDate => 'きのう';

  @override
  String get searchSaidOutLoud => '声にしたもの';

  @override
  String get searchAPhotograph => '写真';

  @override
  String get searchAVideo => '動画';

  @override
  String get securityWhileOpen => 'アプリを開いているあいだ';

  @override
  String get securityLockFooter =>
      'Lamplight は背景に回った瞬間にかならず閉じます。ここで決まるのは、まだ開いているあいだにどれだけ待つかだけです。';

  @override
  String get securityLockAfter => 'この時間で閉じる';

  @override
  String get securityOneHour => '1時間';

  @override
  String get securityYourPasscode => 'パスコード';

  @override
  String get securityPasscodeFooter =>
      'パスコードが鍵です。どこにも保存されていません — この端末にも、ほかのどこにも — ですから誰かが差し出すよう迫られることもなく、誰かが代わりに取り戻すこともできません。';

  @override
  String get securityChangePasscode => 'パスコードを変える';

  @override
  String get securityScreenshots => 'スクリーンショット';

  @override
  String get securityScreenshotsFooter =>
      'Lamplight は画面の記録を止めます。端末を手に取った人がノートを撮れないように、そして最近使ったアプリの一覧にも映らないように。ご自身の端末では、これを解除できます。';

  @override
  String get securityAllowScreenshots => 'スクリーンショットを許す';

  @override
  String get securityScreenshotsOn => '最近使ったアプリにノートが映ります';

  @override
  String get securityScreenshotsOff => '最近使ったアプリには白紙が映ります';

  @override
  String get securityCouldNotChange => 'それは変更できませんでした。';

  @override
  String get securityNothingChanged => 'ロックについては何も変わっていません。';

  @override
  String get securityPromptAutomatic => '自動で聞かれます';

  @override
  String get securityPromptOnTap => '使いたいときに指紋をタップします';

  @override
  String get mediaAskEachTimeOn => '写真や動画を追加するときに、どの大きさで残すか聞かれます。';

  @override
  String get mediaAskEachTimeOff => 'オフ。上の二つの大きさが、聞かずに使われます。';

  @override
  String get passcodeNew => '新しいパスコード';

  @override
  String get securityFingerprint => '指紋';

  @override
  String get securityFingerprintFooter =>
      '鍵は引き続きあなたの一文です。指紋が開けるのはこの保管庫だけ、この端末だけです。端末の指紋が変われば Android が自動で無効にします — 誰かが自分の指紋を追加して入れないように。バックアップに含まれることは決してありません。';

  @override
  String get securityUnlockWithFingerprint => '指紋で開く';

  @override
  String get securityAskOnOpen => 'Lamplight を開いたらすぐ聞く';

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count秒',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count分',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count時間',
    );
    return '$_temp0';
  }

  @override
  String get durationNever => 'しない';

  @override
  String get securityDefaultNote => 'ふだんはこれ。';

  @override
  String get securityHourNote => '読み返す午後のために。';

  @override
  String get securityNeverNote => 'アプリを離れれば、それでもすぐ閉じます。';

  @override
  String get calendarGoToDate => '日付へ移動';

  @override
  String get dayHasWriting => '書いたもの';

  @override
  String get dayHasPhoto => '写真';

  @override
  String get dayHasVideo => '動画';

  @override
  String get dayHasVoice => '音声のメモ';

  @override
  String get dayHasFile => 'ファイル';

  @override
  String dayEntriesAndKinds(Object count, Object kinds) {
    return '$count、$kinds';
  }

  @override
  String get listSeparator => '、';

  @override
  String listAnd(Object last, Object most) {
    return '$mostと$last';
  }

  @override
  String get integrityNothingUnusual =>
      'この端末に変わったところはありません。Lamplight は本来のとおりに動いています。';

  @override
  String get calendarPreviousYear => '前の年';

  @override
  String get calendarPreviousMonth => '前の月';

  @override
  String get calendarNextYear => '次の年';

  @override
  String get calendarNextMonth => '次の月';

  @override
  String get calendarBackToMonth => '月に戻る';

  @override
  String get calendarWholeYear => '一年ぜんぶ';

  @override
  String get calendarBackToThisMonth => '今月に戻る';

  @override
  String get calendarNothingThisYear => 'この年には、まだ何もありません。';

  @override
  String calendarYearSummary(Object days, Object entries) {
    return '$daysに $entries。';
  }

  @override
  String get folderNothingInIt => 'まだ何も入っていません';

  @override
  String get onThisDayOneYear => '一年前の今日';

  @override
  String onThisDayYears(Object years) {
    return '$years 年前の今日';
  }

  @override
  String wheelYear(Object year) {
    return '$year 年';
  }

  @override
  String get calendarBackToBrowsing => '一覧に戻る';

  @override
  String get calendarToday => '今日';

  @override
  String get calendarFirstEntry => 'はじめて書いた日';

  @override
  String get calendarGoToThisDay => 'この日へ';

  @override
  String get calendarDensityNote => '色はその日の量を示します。なにもない日から、たくさんの日まで。';

  @override
  String get calendarLess => '少ない';

  @override
  String get calendarMore => '多い';

  @override
  String get calendarGoToToday => '今日へ';

  @override
  String get backupTitle => 'バックアップ';

  @override
  String get vaultNothingToBackUp => 'この金庫には、まだ控えをとるものがありません。';

  @override
  String vaultChangedWhileBackingUp(Object name) {
    return '控えを作っている間に何かが変わりました（$name）。もう一度どうぞ。';
  }

  @override
  String get vaultTooSmall => 'このファイルは小さすぎて、Lamplight の控えではありません。';

  @override
  String get vaultNotALamplightFile => 'これは Lamplight の控えファイルではありません。';

  @override
  String get vaultDamaged => 'このファイルは壊れていて開けません。';

  @override
  String get vaultKeyringNewerVersion =>
      'この金庫は、より新しい Lamplight で作られています。開くにはアプリを更新してください。';

  @override
  String get vaultKeyringDamaged =>
      '金庫の鍵のファイルが壊れていて読めません。控えのファイルがあれば、そこから戻してください。';

  @override
  String get vaultDatabaseNewerVersion =>
      'この金庫は、より新しい Lamplight で作られています。開くにはアプリを更新してください。ノートは無事で、何も変わっていません。';

  @override
  String phraseWrongLength(Object count) {
    return '復元の言葉は12語です。これは $count 語です。';
  }

  @override
  String phraseNotARecoveryWord(Object word) {
    return '「$word」は復元の言葉ではありません。';
  }

  @override
  String get phraseDoesNotCheckOut =>
      'その言葉は正しい復元の言葉ではありません。打ち間違いや入れ替わりがないか確かめてください。';

  @override
  String get vaultNewerVersion =>
      'この控えは、より新しい Lamplight で作られています。アプリを更新してから、もう一度どうぞ。';

  @override
  String get vaultUnknownCompression => 'この控えは、この版が読めない圧縮を使っています。';

  @override
  String get vaultDamagedTryOlder =>
      'このファイルは壊れていて開けません。もっと古い控えがあれば、それをお試しください。';

  @override
  String get vaultBeforeRecoveryPhrases =>
      'この控えは、復元の言葉で控えを開けるようになる前のものです。パスコードだけが入口です。';

  @override
  String get vaultWordsDoNotOpenIt => 'その言葉ではこのファイルは開きません。別の金庫のものかもしれません。';

  @override
  String get vaultWrongPasscode => 'そのパスコードでは、このファイルは開きません。';

  @override
  String vaultMissingPart(Object name) {
    return 'この控えは自分の一部を欠いています（$name）。';
  }

  @override
  String vaultPartWrongSize(Object name) {
    return 'この控えは壊れています（$name の大きさが違います）。';
  }

  @override
  String vaultPartDoesNotMatch(Object name) {
    return 'この控えは壊れています（$name が一致しません）。';
  }

  @override
  String get vaultNoVaultInside => 'この控えには金庫が入っていません。別のアプリが作ったのかもしれません。';

  @override
  String get vaultOutOfOrder => 'このファイルは壊れています。中身の順序が入れ替わっています。';

  @override
  String get vaultEndsPartWay => 'このファイルは壊れています。途中で終わっています。';

  @override
  String vaultIncomplete(Object parts) {
    return 'このファイルは欠けています。全体のうち $parts しかありません。';
  }

  @override
  String vaultWillNotOpen(Object name) {
    return 'この控えには、Lamplight が開かないものが入っています（$name）。';
  }

  @override
  String countEntries(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件',
    );
    return '$_temp0';
  }

  @override
  String countDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 日',
    );
    return '$_temp0';
  }

  @override
  String get backupCheckingItOpens => '開けるか確かめています…';

  @override
  String get backupCouldNotSave => '控えを保存できませんでした。';

  @override
  String get backupNothingLost => '何も失われておらず、ノートはそのままです。少しあとで、もう一度どうぞ。';

  @override
  String get backupLast => '前回の控え';

  @override
  String get backupInTheVault => '金庫の中';

  @override
  String get restoreCheckingFile => 'ファイルを確かめています…';

  @override
  String get restoreCouldNotOpen => 'そのファイルは開けませんでした。';

  @override
  String get restoreCheckItIsTheOne => 'それが目当ての控えか確かめて、もう一度どうぞ。';

  @override
  String get restorePuttingInPlace => '所定の場所に置いています…';

  @override
  String get restorePuttingBack => '前のノートを戻しています…';

  @override
  String get restoreCouldNotFinish => '復元を終えられませんでした。';

  @override
  String get restoreBackAsTheyWere => 'ノートは元のとおりに戻っています。';

  @override
  String get restoreUsePasscodeInstead => '代わりにパスコードを使う';

  @override
  String get restoreUseWordsInstead => '代わりに十二の言葉があります';

  @override
  String get backupCreateFile => 'バックアップを作る';

  @override
  String get backupCreatedChecked => 'バックアップを作り、確認しました。';

  @override
  String get backupMakeAnother => 'もうひとつ作る';

  @override
  String get backupRestoreHeading => '復元';

  @override
  String get backupRestoreFrom => 'バックアップから復元';

  @override
  String backupProgress(String stage, int percent) {
    return '$stage $percent パーセント';
  }

  @override
  String get restoreTitle => '復元';

  @override
  String get restoreChooseFile => 'ファイルを選ぶ';

  @override
  String get restoreUseLatest => '最新のバックアップを使う';

  @override
  String get restorePhraseHint => 'おぼえる ものがたり さんぎょう…';

  @override
  String get restoreAction => '復元';

  @override
  String get restoreChooseDifferent => '別のファイルを選ぶ';

  @override
  String get importChooseFolder => 'フォルダを選ぶ';

  @override
  String get importChooseFiles => '代わりにファイルを選ぶ';

  @override
  String get importChooseFilesNote =>
      'Android がフォルダーを拒む場合 — ダウンロードやストレージの最上位はどのアプリにも渡しません — ファイルを直接選んでください。これは拒まれません。';

  @override
  String get importLooking => 'フォルダの中を見ています…';

  @override
  String get importNoTextFiles => 'そのフォルダにテキストファイルはありません。';

  @override
  String get importChooseDifferentFolder => '別のフォルダを選ぶ';

  @override
  String get importUseFileDate => 'ファイル自身の日付を使う';

  @override
  String get importUseFileDateNote =>
      'ファイルが最後に変更された日に置きます。書かれている日とは違うことがよくあります。';

  @override
  String importBringIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件を取り込む',
    );
    return '$_temp0';
  }

  @override
  String importProgress(int percent) {
    return '取り込み中、$percent パーセント';
  }

  @override
  String get exportChooseFolder => 'フォルダを選んで書き出す';

  @override
  String get exportSave => '読めるコピーを保存';

  @override
  String get exportWritten => 'コピーを書き出しました。';

  @override
  String get exportAgain => 'もう一度書き出す';

  @override
  String get exportWhichOne => 'どちらがいい？';

  @override
  String get exportNotLocked => 'このコピーは閉じられていません';

  @override
  String dayAddedThings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今日に$count件追加しました。',
    );
    return '$_temp0';
  }

  @override
  String get entryAddNote => 'これにひとこと添える';

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件追加しました。',
    );
    return '$_temp0';
  }

  @override
  String get importFolderUnreadable => 'そのフォルダーは読めませんでした。';

  @override
  String get importNothingBrought => '何も取り込まれていません。';

  @override
  String get importStoppedPartWay => '日記の取り込みが途中で止まりました。';

  @override
  String get importWhatArrivedKept => '止まる前に届いたものは、すべて残っています。';

  @override
  String get importNoReadableDates => 'それらのファイルには、Lamplight が読める日付がありません。';

  @override
  String importReadyToBring(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件、取り込む用意ができています。',
    );
    return '$_temp0';
  }

  @override
  String get importNothingNew => '取り込むものは、新しくありません。';

  @override
  String importBroughtIn(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件を取り込みました。',
    );
    return '$_temp0';
  }

  @override
  String importAlreadyHere(Object count) {
    return '$count 件はもとからあったので、そのままにしました。';
  }

  @override
  String importNoDateSkipped(Object count) {
    return '$count 件は読める日付がなく、飛ばしました。';
  }

  @override
  String importCouldNotRead(Object count, Object names) {
    return '$count 件は読めませんでした：$names';
  }

  @override
  String get exportStarting => '始めています…';

  @override
  String get exportCouldNotFinish => '読める控えを作り終えられませんでした。';

  @override
  String get exportNothingChanged => 'Lamplight の中は何も変わっていません。';

  @override
  String get importVideoAlreadySmall => 'ある動画はもともと十分に小さかったので、そのまま保存しました。';

  @override
  String get importVideoCouldNotShrink => 'ある動画はこの端末では小さくできなかったので、そのまま保存しました。';

  @override
  String importOneFailed(String reason) {
    return 'ひとつうまくいきませんでした: $reason';
  }

  @override
  String importAbandoned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lamplight が閉じる前に$count件が終わりませんでした。',
    );
    return '$_temp0';
  }

  @override
  String get importNothingLeft => '端末には何も残っていません。';

  @override
  String get nameCardAsk => 'ここに何と書きますか？';

  @override
  String get nameCardHint => 'お名前でも、なんでも';

  @override
  String get reminderGroup => 'よければ、そっとひと声';

  @override
  String get reminderFooter =>
      'あなたが入れるまで切ってあります。ノートの中身にはいっさい触れません — 触れられません。保管庫が閉じたまま動くからです。連続日数も、回数も、書かなかった日の話もありません。';

  @override
  String get reminderTitle => '書くことを思い出させる';

  @override
  String get reminderWhen => 'いつ';

  @override
  String get reminderProblemNotAllowed => 'Lamplight は通知を送る許可がありません。';

  @override
  String get reminderProblemNotificationsOff =>
      'この端末の設定で Lamplight の通知が切られています。';

  @override
  String get reminderProblemRemindersOff =>
      'この端末の通知設定で Lamplight のリマインダーが切られています。';

  @override
  String get reminderProblemBatterySaving =>
      'この端末は Lamplight を抑えてバッテリーを節約しています。通知が遅れたり届かなかったりするのは、たいていこれが理由です。';

  @override
  String get reminderMayNotArrive => '通知は届かないかもしれません';

  @override
  String get backupAutomatic => 'ひとりでにバックアップ';

  @override
  String get backupAutomaticDidNotFinish => 'ひとりでにとる控えが、終わりませんでした。';

  @override
  String get backupNothingYet => 'まだ控えをとるものがありません。';

  @override
  String get backupInProgress => '控えをとっています…';

  @override
  String get backupStartsAtUnlock => '次にロックを解いたときに始まります。';

  @override
  String get backupDoneAutomatically => 'ひとりでに控えをとりました。';

  @override
  String get backupLastOneFailed =>
      '前回のひとりでにとる控えが終わりませんでした。次に Lamplight を開いたとき、もう一度試します。';

  @override
  String importNthOf(Object index, Object total) {
    return '$total 件中 $index 件目';
  }

  @override
  String importWaiting(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件待ち',
    );
    return '$_temp0';
  }

  @override
  String get aboutCopied => 'コピーしました';

  @override
  String get failureGeneric => 'それはうまくいきませんでした。';

  @override
  String get failureNothingLost => '何も失われていません。もう一度どうぞ。';

  @override
  String get calendarNothingOnDay => 'なし';

  @override
  String get backupChangeFolder => 'フォルダを変える';

  @override
  String backupSavedTo(String place) {
    return '$place に保存されます';
  }

  @override
  String get backupUseDefaultFolder => 'いつものフォルダーを使う';

  @override
  String get backupChooseFolder => '控えを置くフォルダーを選んでください';

  @override
  String get folderAndroidRestriction =>
      'Android はどのアプリにも「ダウンロード」や内部ストレージ全体を渡しません。「ドキュメント」か、その中のフォルダなら使えます。';

  @override
  String get folderNotWritable => 'そのフォルダーには何も保存できません。ほかを選んでください。';

  @override
  String get folderRefused => 'そのフォルダーは使えませんでした。';

  @override
  String get folderTryAnother => '別のフォルダーを選んでみてください。';

  @override
  String get aboutHowKept => 'ノートの保管のしかた';

  @override
  String get aboutFonts => '書体とライセンス';

  @override
  String get aboutVersion => 'バージョン';

  @override
  String get aboutNoBrowser => 'この端末にはリンクを開けるアプリがありません。';

  @override
  String get aboutMadeBy => 'つくった人';

  @override
  String get aboutMadeBySemantic =>
      'ProbablyPiyush がつくりました。ブラウザで LinkedIn を開きます。';

  @override
  String get aboutCoffee => 'コーヒーをおごる';

  @override
  String get aboutCoffeeSemantic => 'コーヒーをおごる。ブラウザでページを開きます。';

  @override
  String get aboutCopyDetails => '内容をコピー';

  @override
  String settingsNameSemantic(Object name) {
    return '$name。タップで変えられます。';
  }

  @override
  String get settingsAddName => '名前を入れる';

  @override
  String get settingsNameOnlyHere => 'この端末の中だけ';

  @override
  String get settingsNameOptional => '任意です。この端末から出ることはありません。';

  @override
  String get reminderTurnedOffByAndroid =>
      'Android で Lamplight の通知が切られています。端末の設定の「アプリ」から入れられます。';

  @override
  String get reminderOnceADay => '一日に一度';

  @override
  String reminderTodayAt(Object time) {
    return '今日 $time';
  }

  @override
  String reminderYesterdayAt(Object time) {
    return 'きのう $time';
  }

  @override
  String reminderOnDateAt(Object date, Object time) {
    return '$date $time';
  }

  @override
  String get reminderNoneYet => 'まだ何も届いていません';

  @override
  String reminderLastArrived(Object when) {
    return '前回は $when に届きました';
  }

  @override
  String reminderNextDue(Object when) {
    return '次は $when の予定です';
  }

  @override
  String get aboutHide => '隠す';

  @override
  String get aboutCheckReal => 'これが本物の Lamplight か確かめる';

  @override
  String get entryRevisionsNote => '変える前はこう書いてありました';

  @override
  String get entryStaysOnDay => 'その日にもそのまま残ります';

  @override
  String entryDeleteKind(String kind) {
    return '$kindを削除';
  }

  @override
  String get shareCouldNotAdd => 'それは取り込めませんでした。いちど保存して、写真のボタンからお試しください。';

  @override
  String get openNothingCanOpen => 'この端末には、その種類のファイルを開けるものがありません。';

  @override
  String get viewerMore => 'その他';

  @override
  String get docLeavesLamplight => 'これは Lamplight の外に出ます';

  @override
  String get docKeepItHere => 'ここに置いておく';

  @override
  String get docOpenWith => 'ほかのアプリで開く…';

  @override
  String docCannotShow(String kind) {
    return 'Lamplight は PDF・画像・文章を、暗号を解いた形で端末に置くことなく表示できます。$kind ファイルには別のアプリが必要です — 読んでいるあいだだけ貸し出し、あとで返してもらえます。';
  }

  @override
  String get menuOpenWithNote => '別のアプリへ、控えは残さず';

  @override
  String menuSaveKind(String kind) {
    return '$kindを保存';
  }

  @override
  String get menuTrashNote => '30日残り、そのあと消えます';

  @override
  String get videoBackTen => '10秒もどる';

  @override
  String get videoForwardTen => '10秒すすむ';

  @override
  String get photoPlayVideo => 'この動画を再生';

  @override
  String get lockPhraseHint => '12個の単語を、空白で区切って';

  @override
  String get lockUnlock => 'ひらく';

  @override
  String get errorScreenDidNotOpen => 'その画面は開きませんでした。失われたものはありません。';

  @override
  String get errorGoBack => 'もどる';

  @override
  String recordingCannot(String what) {
    return 'この端末では録音を$whatできません。録音は続いています。';
  }

  @override
  String get recordingClose => '閉じる';

  @override
  String recordingElapsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '録音中、$count秒',
    );
    return '$_temp0';
  }

  @override
  String get recordingStopKeep => '止めて、この録音を残す';

  @override
  String get recordingDiscard => '捨てる';

  @override
  String get recordingCouldNotStart => '録音を始められませんでした。';

  @override
  String get recordingCheckMicrophone => 'Lamplight にマイクの使用が許可されているか確認してください。';

  @override
  String get recordingStartAgain => '再開';

  @override
  String get recordingCouldNotSave => 'その録音は保存できませんでした。';

  @override
  String get recordingStillHere => 'まだここにあります。もう一度停止してみてください。';

  @override
  String get recordingCarryOnSemantic => '録音を続ける';

  @override
  String get recordingPauseSemantic => 'この録音を一時停止';

  @override
  String get recordingCarryOn => '続ける';

  @override
  String get recordingPause => '一時停止';

  @override
  String get sizeAdd => '追加';

  @override
  String get transcribeTitle => '話したことを書き留める';

  @override
  String get transcribeOn => 'ボイスメモが探せるようになります。どこにも送られません。';

  @override
  String get transcribeOff => '切ってあります。ボイスメモはその日からしか見つけられません。';

  @override
  String get transcribeLanguage => '話すことば';

  @override
  String get transcribeLanguageNote =>
      '録音で話すことばです。一度にひとつだけ — 途中で切り替わる文は、ここに合うほうの半分だけが返ってきます。';

  @override
  String get transcribeNotDownloaded => 'この端末にはまだ入っていません — 触れて取り込みます。';

  @override
  String transcribeGetBetter(String name) {
    return '$name のより良いモデルを取り込む';
  }

  @override
  String get transcribeGetBetterNote =>
      'これがあると書き起こしの精度がはっきり上がります。取り込むのは端末のほうで、Lamplight ではありません。一度きりです。';

  @override
  String get transcribeNoLanguages => 'この端末はまだことばを提示していません。';

  @override
  String get transcribeNeedsDownloading => '取り込みが必要';

  @override
  String folderStill(String day, String folder) {
    return '$day のままです。$folder にもあります。';
  }

  @override
  String get folderRenameTitle => 'フォルダの名前を変える';

  @override
  String get folderNameHint => '人、場所、時期';

  @override
  String get voicePlay => 'このボイスメモを聞く';

  @override
  String get voiceForwardThirty => '30秒すすむ';

  @override
  String voiceSpeed(String speed) {
    return '再生の速さ、いまは $speed 倍';
  }

  @override
  String get voiceLengthUnknown => 'ボイスメモ、再生するまで長さはわかりません';

  @override
  String get voicePosition => '録音のなかの位置';

  @override
  String get voiceOpening => '録音をひらいています';

  @override
  String get voiceNoWords => 'ことばが返ってきませんでした — もう一度';

  @override
  String get voiceWriteThis => 'これを書き留める';

  @override
  String get voiceCannotWrite => 'この端末ではボイスメモを書き留められません。';

  @override
  String get voiceLanguageMissing => 'この端末はそのことばをまだ取り込んでいません。';

  @override
  String get voiceWriting => '書き留めています…';

  @override
  String get voiceWaiting => '書き留めを待っています。';

  @override
  String get voiceWritten => 'この端末で書き留めました。';

  @override
  String get errorPartNotShown => 'この部分は表示できませんでした。';

  @override
  String get errorScreenShort => 'その画面は開きませんでした。';

  @override
  String get errorNothingLost => '失われたものはありません。書いたものはすべて、そのまま保管庫にあります。';

  @override
  String get errorHideDetails => '技術的な内容を隠す';

  @override
  String get errorShowDetails => '技術的な内容を見る';

  @override
  String get errorDetailsNote =>
      'コピーされるのはこれだけです。どこで何が壊れたかが書いてあり、あなたが書いたものは入っていません。';

  @override
  String get passcodeChangeFailed => 'パスコードを変えられませんでした。';

  @override
  String get passcodeOldStillWorks => '前のパスコードがそのまま使えます。';

  @override
  String get passcodeChanged => 'パスコードを変えました';

  @override
  String get passcodeWordsUnchanged =>
      '12個の単語は変わっていません。新しいものも要りません。これまでどおり保管庫もバックアップも開きます。';

  @override
  String get passcodeOldBackups =>
      'すでにあるバックアップは前のパスコードで開きます。いま作る新しいものは、新しいパスコードになります。';

  @override
  String get passcodeMakeBackup => 'いまバックアップを作る';

  @override
  String get passcodeCurrent => 'いまのパスコード';

  @override
  String get passcodeNewAgain => '新しいものをもう一度';

  @override
  String get passcodeOldBackupsNote => 'すでに作ってあるバックアップは、前のパスコードで開きます。';

  @override
  String get passcodeWordsNote => '12個の復元用の単語は変わらず、そのまま使えます。';

  @override
  String get licencesFonts =>
      'ここの書体はすべて SIL Open Font License です。なにも取り込みません — アプリの中にあります。';

  @override
  String get licencesSource =>
      'Lamplight 自体は GPL-3.0 に、アプリストア向けの例外を添えたものです。ソースがライセンスです。誰でも読んで、この画面の言うとおりに動くか確かめられます。';

  @override
  String get licencesUnreadable => 'そのライセンスの文面を読めませんでした。';

  @override
  String get appearanceSample =>
      '午後はずっと雨。お茶をいれて、半章だけ読んで、言いたかったことは忘れて、かわりにこれを書いた。';

  @override
  String get appearanceChromeNote => 'ボタンや見出しはこのままです';

  @override
  String get appearanceSizeNote =>
      'これは端末じたいの文字の大きさに重ねてはたらきます。すでに大きくしてあるなら、ここからさらに大きくなります。';

  @override
  String get voicePause => '一時停止';

  @override
  String get importIntro =>
      'ほかのところで日記を書いていたなら、Lamplight に取り込めます — テキストファイルで、名前に日付が入っていれば。';

  @override
  String get importHowDates =>
      'テキストファイルを読み、名前のなかの日付を探します — 2026-08-24 や 24 August 2026 — ファイル名でも、その上のフォルダ名でもかまいません。';

  @override
  String get importAmbiguousDates =>
      '03-04-2026 のような日付は、わざと飛ばします。ある国では四月三日、別の国では三月四日で、取りちがえれば一年ぶんの日々を何も言わずに違う日に並べてしまうからです。';

  @override
  String get importFormats =>
      'Lamplight が読むのはプレーンテキストです。.txt、.md、.org、.log など、拡張子のないファイルも読みます。ほかの形式なら、まずテキストとして書き出してください。';

  @override
  String get importAtStartOfDay =>
      'どれもその日のいちばん上に置かれます。ファイル名は日付を教えてくれても、時刻は教えてくれないからです。すでに Lamplight にあるものは変わりも消えもせず、二度実行しても写しは増えません。';

  @override
  String get importFileDateNote =>
      'ファイルが最後に変更された日に置きます。フォルダを端末のあいだで複製していると、書いた日ではなく複製した日になることがあります。';

  @override
  String get importSkippedNote =>
      'これらは飛ばします。いまある場所にそのまま残り — あなたのフォルダからは何も動かず、何も消えません。';

  @override
  String get restoreChooseNote =>
      'バックアップファイルを選んでください。名前は Lamplight-2026-08-18.vault のようなものです。';

  @override
  String get restorePasscodeNote => 'このファイルのパスコードを入れてください — バックアップを作ったときのものです。';

  @override
  String get restoreWordsNote => '12個の単語を、順番どおり、空白で区切って入力してください。';

  @override
  String get restoreDoNotClose => '終わるまで Lamplight を閉じないでください。';

  @override
  String get exportIntro =>
      'Lamplight の中身をすべて、選んだフォルダにふつうのファイルとして書き出します — 一日につきテキストファイルひとつ、写真も動画もボイスメモも書類も、それぞれの名前で。';

  @override
  String get exportNoLamplightNeeded =>
      'そのフォルダの中身を開くのに Lamplight は要りません。このアプリがいつか動かなくなっても、使うのをやめても、テキストを読めるものなら何ででも開けます。';

  @override
  String get exportWhichOneBody =>
      '読める形のコピーは、読むため、ほかのアプリへ移すため、あるいは Lamplight をやめたあとに何かを残しておくためのものです。守られてはいません。\n\nバックアップファイルは、Lamplight をそっくりそのまま取り戻すためのものです — 新しい端末や、壊れた端末のために。パスコードで閉じられているので、クラウドを含めどこに置いても安全です。\n\nたいていの人に必要なのはバックアップです。絶対に困りたくなければ、読める形のコピーもあわせてどうぞ。';

  @override
  String get exportNotLockedBody =>
      'これにはパスコードがありません。そのフォルダを開いた人は中身をすべて読めます。それでかまわない場所に置いてください — ただ安全に残したいだけなら、バックアップをお使いください。';

  @override
  String get backupConfirmNote =>
      'パスコードを確かめてください。このファイルはすべてを開けられるので、作るのは意図してすることであるべきです。';

  @override
  String get backupKeepSafeNote =>
      'バックアップはいまのパスコードで閉じられています。信頼できる場所へどうぞ — クラウドでもかまいません。そのパスコードなしにはファイルは読めず、私たちが見ることもありません。';

  @override
  String get backupRestoreWarning =>
      'バックアップを開くと、いま Lamplight にあるものはすべて置き換わります。復元したものが開けると確かめられるまで、いまのノートはわきに取っておかれます。';

  @override
  String get folderWhatItIs => 'フォルダは、あなたの日々を貫く一本の糸です — ひとりの人、ひとつの場所、ひと続きの時期。';

  @override
  String get folderNothingMoves => 'フォルダへ移るものはありません。書いたものはその日に残ったまま、ここにも現れます。';

  @override
  String get folderDeleteNote => 'フォルダはなくなります。中にあったものはすべて、それぞれの日にそのまま残ります。';

  @override
  String get folderNoneInHere =>
      'ここにはまだ何もありません。ある日の何かを長押しして「フォルダに入れる」を選んでください。';

  @override
  String get passcodeRuleLength => '8文字以上。';

  @override
  String get passcodeRuleWords => '覚えていられるふつうの単語をいくつか並べるほうが、記号入りの短いものより強いです。';

  @override
  String get passcodeNoMatch => 'まだ一致していません。';

  @override
  String get docCopyInClear =>
      'コピーは暗号を解いた形で書き出されるので、あなたのファイルを読めるアプリなら読めます。Lamplight の中に残るものは、どちらにせよ暗号化されたままです。';

  @override
  String docPageOf(String page, String total) {
    return '$total ページ中 $page ページ';
  }

  @override
  String get transcribeTookTooLong =>
      'その録音は書き起こしに時間がかかりすぎたので、Lamplight は待つのをやめました。あとでもう一度試します。';

  @override
  String get transcribeCouldNotWriteDown => 'その録音は書き起こせませんでした。';

  @override
  String get transcribeRecordingIsSafe => '録音そのものは無事です。Lamplight はもう一度試します。';

  @override
  String voicePositionSpoken(Object at, Object total) {
    return '$total のうち $at';
  }

  @override
  String entryEditedAt(Object time) {
    return '$time · 直した';
  }

  @override
  String get docCouldNotOpen => 'その書類は開けませんでした。';

  @override
  String albumThisOne(Object thing) {
    return 'この$thing';
  }

  @override
  String albumThisOneOf(Object index, Object thing, Object total) {
    return 'この$thing — $total 件中 $index 件目';
  }

  @override
  String get albumCaptionThese => 'これらに一言添える';

  @override
  String get albumCaptionThis => '一言添える';

  @override
  String get albumCaptionEdit => '書いたものを直す';

  @override
  String albumOthersStay(Object count) {
    return 'ほかの $count 件はそのままです。これは30日間ごみ箱に入ります。';
  }

  @override
  String get albumGoesToTrash => '30日間ごみ箱に入ります。';

  @override
  String get photoCouldNotOpen => 'この写真は開けませんでした。';

  @override
  String get photoMayBeDamaged => '壊れているのかもしれません。';

  @override
  String get docTooBig => 'これは Lamplight の中で開くには大きすぎます。控えを保存して、ほかのアプリで開けます。';

  @override
  String docPages(Object count) {
    return '$count ページ';
  }

  @override
  String get docFileEmpty => 'このファイルは空です。';

  @override
  String videoTooBig(Object size) {
    return 'この動画はここで再生するには大きすぎます — $size。そのために保護なしで書き出すことはしません。控えを保存して、ほかで見てください。';
  }

  @override
  String get videoNotAvailableHere => 'アプリのこの部分は、この端末では使えません。';

  @override
  String get videoCouldNotOpen => 'この動画は開けませんでした。';

  @override
  String get docGoToPage => 'ページへ移動';

  @override
  String get docGo => '移動';

  @override
  String get docPageCouldNotBeDrawn => 'このページは表示できませんでした。';

  @override
  String get passcodeRuleStronger => 'あと一語か二語で、ぐんと当てにくくなります。';

  @override
  String get backupAutoFooter =>
      '自動のバックアップは Lamplight を開いたときに、前回から何か変わっていれば動きます。ご自分で作るものと同じく、パスコードで閉じられています。';

  @override
  String get aboutHowKeptBody =>
      'アカウントはありません。サーバーもありません。何もこの端末から出ません。\n\nノートはパスコードで閉じられ、鍵はそこから作られます — ですから、その控えはどこにもありません。私たちの手元にも。';

  @override
  String get aboutFree => 'Lamplight は無料で、これからもそうです。解除するものはありません。';

  @override
  String get aboutContact => '何かおかしいですか？ お知らせください。';

  @override
  String get aboutContactSemantic => 'メールで意見を送る';

  @override
  String aboutNoMail(String address) {
    return 'この電話にメールアプリがありません。アドレスは $address です。';
  }

  @override
  String get backupOnItsOwn => 'ひとりでに';

  @override
  String get actionDismiss => '閉じる';

  @override
  String importRange(String from, String to) {
    return '$from から $to まで。';
  }

  @override
  String get sizeOneCopy => 'Lamplight が持つのはひとつだけです。ここで選んだものが、そのまま手元に残ります。';

  @override
  String get sizeAddAlways => '追加して、次からは聞かない';

  @override
  String get trashNothingHere => 'ここには何もありません。';

  @override
  String get appearanceAaQuiet => 'Aa\nしずか';

  @override
  String lockWarnSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'あと$count秒ほどで閉じます。',
    );
    return '$_temp0';
  }

  @override
  String get lockWarnChange => '「ロックとセキュリティ」で変えられます。';

  @override
  String get openingLabel => 'Lamplight をひらいています';

  @override
  String get recordingNoMic => 'Lamplight はマイクを使えません。端末の設定の「アプリ」から許可できます。';

  @override
  String get recordingPaused => '一時停止中。いま聞いてはいません。';

  @override
  String get videoOpening => '動画をひらいています…';

  @override
  String albumRemoveThis(String thing) {
    return 'この$thingを外す';
  }

  @override
  String get revisionsNote => '変える前はこう書いてありました。ここにボタンはありません — 文字を選んでコピーできます。';

  @override
  String get composerSemantic => 'この日のことを書く';

  @override
  String importStripAdding(String name) {
    return '$name を追加しています';
  }

  @override
  String passcodeAtLeast(int count) {
    return '$count文字以上';
  }

  @override
  String get searchKindAll => 'すべて';

  @override
  String get searchKindWords => '文字';

  @override
  String get searchKindVoice => '声';

  @override
  String get searchKindPhotos => '写真';

  @override
  String get searchKindFiles => 'ファイル';

  @override
  String passcodeAtLeastShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count文字以上',
    );
    return '$_temp0';
  }

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '残り$count日',
    );
    return '$_temp0';
  }

  @override
  String get trashGoneToday => '今日でなくなります';

  @override
  String restoreMadeOn(String date) {
    return '$date に作成';
  }

  @override
  String restoreDone(String entries, String days) {
    return '$daysにわたる$entriesを復元しました。おかえりなさい。';
  }

  @override
  String importFoundUndated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lamplight が読める日付のないもの$count件',
    );
    return '$_temp0';
  }

  @override
  String entrySemantic(String time) {
    return '$time の記録。タップで編集。';
  }

  @override
  String entrySemanticEdited(String time) {
    return '$time の記録、編集済み。タップで編集。';
  }

  @override
  String onThisDaySemantic(String when, String body) {
    return '$when。$body。タップでその日へ。';
  }

  @override
  String attachmentSemantic(String what, String time) {
    return '$time の$what。ダブルタップで開きます。';
  }

  @override
  String dayHeaderToday(String date) {
    return '$date、今日';
  }

  @override
  String get yearGridNothing => 'この日には何もありません';

  @override
  String get calendarNothing => 'この日には何もありません';

  @override
  String importStripCounted(String name, String counted) {
    return '$name を追加しています$counted';
  }

  @override
  String get aboutFingerprintBody =>
      'どのビルドにも、作った本人にしか作れない署名がついています。これはいまお手元にある一本のものです。ソースとともに公開されている指紋と見くらべてください — 一致すれば、それはそのソースから作られたアプリです。';

  @override
  String get searchKindVideo => '動画';

  @override
  String get semanticOn => 'オン';

  @override
  String andMore(int count) {
    return 'ほか$count件';
  }

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件',
      zero: 'なにもなし',
    );
    return '$_temp0';
  }

  @override
  String get checkDone => 'できています';

  @override
  String get checkNotYet => 'まだです';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日',
    );
    return '$_temp0';
  }

  @override
  String get lockUseYourPasscode => 'パスコードをお使いください。';

  @override
  String get searchWordsExample => 'これまでに書いたことすべて';

  @override
  String get searchAFile => 'ファイル';

  @override
  String get searchFileExample => 'scan.pdf · IMG_2831';

  @override
  String get searchAFolder => 'フォルダー';

  @override
  String get searchFolderExample => '自分でつけた名前';

  @override
  String get searchByFileName => 'ファイル名から';

  @override
  String get searchARecording => '録音';

  @override
  String get searchAnEntry => '記録';

  @override
  String get sizeThisOne => 'これ';

  @override
  String get sizeTheseOnes => 'これら';

  @override
  String get passcodeOneMoreCharacter => 'あと1文字。';

  @override
  String passcodeMoreCharacters(int count, int minimum) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'あと$count文字 — 最低$minimum文字です。',
    );
    return '$_temp0';
  }

  @override
  String get passcodeTooObvious => '誰でも最初に試すもののひとつです。別のものにしてください。';

  @override
  String get passcodeSameCharacter => '同じ文字の繰り返しです。';

  @override
  String get passcodeStraightRun => '文字が順番に並んでいるだけです。';

  @override
  String attachmentLoading(String time) {
    return '$timeの添付、読み込み中';
  }

  @override
  String videoSemantic(String time, String length) {
    return '$timeの動画、$length。ダブルタップで再生します。';
  }

  @override
  String voiceSemantic(String time, String length) {
    return '$timeの音声メモ、$length。ダブルタップで再生します。';
  }

  @override
  String fileSemantic(String time, String name, String size) {
    return '$timeのファイル、$name、$size。ダブルタップで開きます。';
  }

  @override
  String get lengthUnknown => '長さ不明';

  @override
  String get settingsLockNone => '自動ロックなし';

  @override
  String settingsLockAfter(String duration) {
    return '$duration後';
  }

  @override
  String settingsSecuritySummary(String lock) {
    return 'パスコード、指紋、$lock';
  }

  @override
  String get keptNoNetworkTitle => 'どこにも送られません';

  @override
  String get keptNoNetworkBody =>
      'Lamplightはインターネットを使えません。「使わない」のではなく、使えないのです。Androidが権限を与えていないためで、そのことはお使いの端末のアプリ設定で30秒ほどでご自身で確認できます。';

  @override
  String get keptPasscodeTitle => 'パスコードが鍵です';

  @override
  String get keptPasscodeBody =>
      'ノートを開く鍵は、ロックを解除するたびにパスコードから作られます。どこにも保存されないので、見つけられる・失う・引き渡すといったことのできる複製が存在しません。';

  @override
  String get keptForgetTitle => '忘れてしまったら';

  @override
  String get keptForgetBody =>
      '12の単語だけが、もうひとつの入口です。ここでは誰もパスコードを再設定できません。これは上と同じ事実です — あなたを入れ直せるアプリは、他の誰かも入れてしまえるということです。';

  @override
  String get keptNothingReadableTitle => '読める形のものは残りません';

  @override
  String get keptNothingReadableBody =>
      '写真も録音もファイルも、ストレージに触れる前に暗号化されます。平文で書き出されることは一度もありません。あなたがそれを見ているあいだの短い時間でさえも、です。';

  @override
  String get keptLocksItselfTitle => '自分でロックします';

  @override
  String get keptLocksItselfBody =>
      'Lamplightがバックグラウンドに移った瞬間に、鍵は破棄されます。スクリーンショットは禁止され、最近使ったアプリのプレビューにも表示されません。';

  @override
  String get keptBackUpTitle => 'バックアップを取ってください';

  @override
  String get keptBackUpBody =>
      'すべてはこの端末の中だけにあり、ほかのどこにもありません。それがこのアプリの狙いであり、同時に危うさでもあります。バックアップは、あなたのパスコードだけが開ける暗号化されたファイル1つです。どこかに1つ置いておいてください。';
}
