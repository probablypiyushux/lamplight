// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class LZh extends L {
  LZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Lamplight';

  @override
  String get lockTypePasscode => '输入你的密码。';

  @override
  String get lockWrongPasscode => '这没有打开保险库。';

  @override
  String get lockCheckAndRetry => '检查密码后再试一次。';

  @override
  String get lockForgot => '我忘记密码了';

  @override
  String get lockTypeTwelveWords => '输入你的十二个词。';

  @override
  String get lockUsePasscodeInstead => '改用我的密码';

  @override
  String get lockUseFingerprint => '使用你的指纹';

  @override
  String get lockFingerprintFailed => '指纹解锁没有成功。';

  @override
  String get lockFingerprintUnavailable => '指纹解锁不可用。';

  @override
  String get lockOpening => '正在打开…';

  @override
  String get lockNothingDeleted => '什么都没有被删除，也不会被删除。';

  @override
  String lockTryAgainSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 秒后再试。',
    );
    return '$_temp0';
  }

  @override
  String lockTryAgainMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟后再试。',
    );
    return '$_temp0';
  }

  @override
  String get dayToday => '今天';

  @override
  String get dayPrevious => '前一天';

  @override
  String get dayNext => '后一天';

  @override
  String get daySearch => '搜索';

  @override
  String get daySettings => '设置';

  @override
  String get dayChooseDate => '选择其他日期。';

  @override
  String get dayEmptyToday => '有什么想留下的吗？';

  @override
  String get dayEmptyPast => '这一天没有内容。';

  @override
  String get dayWriteSomething => '为今天写点什么';

  @override
  String get dayLineAsk => '这是怎样的一天？';

  @override
  String get dayLineHint => '这是怎样的一天？';

  @override
  String get dayLineSemantic => '用一行说说这是怎样的一天';

  @override
  String dayLineChange(String note) {
    return '这一天：$note。修改。';
  }

  @override
  String get dayEndOfDay => '这一天的结尾';

  @override
  String get dayStartOfDay => '这一天的开头';

  @override
  String get firstPageTitle => '这里是空的，因为你还没有写过。';

  @override
  String get firstPageShelves => '日子就是格子。你留下的东西会落在它发生的那一天，并且一直留在那里。';

  @override
  String get firstPageWayWrite => '点这一页开始写。';

  @override
  String get firstPageWayVoice => '按住麦克风，说出来也可以。';

  @override
  String get firstPageWayAttach => '添加照片、视频或文件。';

  @override
  String get firstPagePromise => '这些都不会离开这台手机。';

  @override
  String get firstPageSemantic => '在日记里写下第一件事';

  @override
  String get captureVoice => '录一段语音';

  @override
  String get capturePhoto => '拍照或选择照片';

  @override
  String get captureFile => '附加文件';

  @override
  String get backupNeverMade => '这里还没有备份。如果这个应用被卸载，你的笔记会跟着一起消失。';

  @override
  String get backupStale => '距离上次备份已经有一段时间了。';

  @override
  String get backupOutOfDate => '你的备份仍然用旧密码打开。';

  @override
  String get backupAction => '备份';

  @override
  String folderAlsoIn(String name) {
    return '同时也在$name里。打开这个文件夹。';
  }

  @override
  String get folderStaysHere => '它留在原处。文件夹只是找到它的第二个地方。';

  @override
  String get folderAddTo => '加入文件夹';

  @override
  String get folderNew => '新建文件夹';

  @override
  String get folderNoneYet => '还没有文件夹。一个人一个，或者一个阶段一个——你会反复回去看的那些。';

  @override
  String folderLesson(String day, String folder) {
    return '仍然在 $day。同时也在$folder里。';
  }

  @override
  String get actionDone => '完成';

  @override
  String get actionCancel => '取消';

  @override
  String get actionDelete => '删除';

  @override
  String get actionSave => '保存';

  @override
  String get actionEdit => '编辑';

  @override
  String get actionUndo => '撤销';

  @override
  String get actionOpen => '打开';

  @override
  String get actionRemove => '移除';

  @override
  String get actionNotNow => '以后再说';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsSecurity => '锁定与安全';

  @override
  String get settingsYourNotes => '你的笔记';

  @override
  String get settingsBackup => '备份';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageNote => '应用使用的语言。你写下的东西是你的，可以用任何语言，与这个设置无关。';

  @override
  String get settingsLanguageSystem => '跟随手机';

  @override
  String get entryMattered => '这件事重要';

  @override
  String get entryMarked => '已标记为重要的一条。';

  @override
  String get entryMarkRemoved => '已取消标记。';

  @override
  String get entryDeleted => '已删除。';

  @override
  String entryEarlierVersions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个早先的版本',
    );
    return '$_temp0';
  }

  @override
  String get entryKeepsWords => '文字会保留';

  @override
  String entryKindInTrash(Object kind) {
    return '$kind已经在回收站里。';
  }

  @override
  String entryKindInTrashWords(Object kind) {
    return '$kind已经在回收站里。文字还在。';
  }

  @override
  String trashConfirmBody(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条，以及它们所有早先的版本。这一步无法撤销。',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyEntry => '空的一条';

  @override
  String get kindPhoto => '照片';

  @override
  String get kindVideo => '视频';

  @override
  String get kindRecording => '录音';

  @override
  String get kindFile => '文件';

  @override
  String get entryNoLongerMarked => '取消标记';

  @override
  String get entryFindAgain => '以后可以在搜索里找到它';

  @override
  String get searchGoTo => '前往';

  @override
  String get searchFolders => '文件夹';

  @override
  String get searchEntriesOne => '1 条记录';

  @override
  String searchEntriesMany(int count) {
    return '$count 条记录';
  }

  @override
  String get searchNothingFound => '没有匹配的内容。';

  @override
  String get searchEverythingInstead => '改为搜索全部';

  @override
  String get searchNoneOfThese => '还没有这类内容。';

  @override
  String get onboardNoAccount => '没有账户。';

  @override
  String get onboardPromiseBody =>
      '你的笔记留在这部手机里。\n我们没有服务器。我们无法阅读它们。\n我们也无法找回它们。';

  @override
  String get onboardBegin => '开始';

  @override
  String get onboardHaveBackup => '我有备份';

  @override
  String get onboardSetPasscode => '设一个密码';

  @override
  String get onboardPasscodeBody => '这是唯一能打开你笔记的东西。一句你记得住的话，比四位数字更牢固。';

  @override
  String get onboardPasscodeLabel => '密码';

  @override
  String get onboardPasscodeAgain => '再输入一次';

  @override
  String get onboardSettingUp => '正在准备…';

  @override
  String get onboardContinue => '继续';

  @override
  String get onboardPasscodesDiffer => '这两个不一样。';

  @override
  String get onboardVaultFailed => '无法创建你的保险库。';

  @override
  String get onboardVaultFailedThen => '什么都没有保存。再试一次。';

  @override
  String get onboardWriteWords => '把这十二个词\n写在纸上';

  @override
  String get onboardWordsBody =>
      '我们没有副本。我们无法发给你。也没有任何客服邮箱能帮你。\n\n写在纸上，不是截图。截图会留在你的相册里，而那是任何人最先翻的地方。';

  @override
  String get onboardWrittenDown => '我已经写下来了';

  @override
  String get onboardCopyWords => '复制这十二个词';

  @override
  String get onboardClipboardNote => '剪贴板一分钟后会自己清空。在那之前，其他应用可以读到它。';

  @override
  String get onboardCopied => '已复制。一分钟后自己清空 — 现在就粘贴到安全的地方。';

  @override
  String get onboardCopyFailed => '没能复制。反正手写下来更安全。';

  @override
  String get onboardCheckThree => '核对其中三个';

  @override
  String get onboardCheckBody => '这样我们知道纸上写对了，而不是屏幕。';

  @override
  String onboardWordNumber(int number) {
    return '第 $number 个词';
  }

  @override
  String onboardWordWrong(int number) {
    return '第 $number 个词不对。看看你写下的。';
  }

  @override
  String get onboardShowWords => '再看一遍这些词';

  @override
  String get onboardFingerprintTitle => '用指纹打开吗？';

  @override
  String get onboardFingerprintBody => '这样你就不用每次都输入那句话。';

  @override
  String get onboardFingerprintExplain =>
      '你的那句话仍然是钥匙。指纹只能打开这个保险库，只在这部手机上；如果手机里的指纹发生变化，Android 会自己关掉它 — 所以没有人能添加自己的指纹进来。它永远不会进入备份。';

  @override
  String get onboardFingerprintWaiting => '等你的手指…';

  @override
  String get onboardFingerprintUse => '使用我的指纹';

  @override
  String get onboardFingerprintFailed => '这没有成功。';

  @override
  String get onboardFingerprintVaultShut =>
      '你离开时 Lamplight 关闭了保管库。你的密码仍然可以打开它，稍后可以在设置中开启指纹。';

  @override
  String get onboardOneLastThing => '最后一件事';

  @override
  String get onboardNameBody => 'Lamplight 该怎么称呼你？它留在这部手机里，你可以随时改，也可以不填。';

  @override
  String get onboardFingerprintOn => '从现在起，你的指纹会打开 Lamplight。';

  @override
  String get onboardYourName => '你的名字';

  @override
  String get onboardStartWriting => '开始书写';

  @override
  String get onboardSkip => '跳过';

  @override
  String get settingsGroupLook => '它的样子和说的话';

  @override
  String get settingsGroupWhoCanOpen => '谁能打开它';

  @override
  String get settingsGroupKeeping => '保管它，带走它';

  @override
  String get settingsAppearanceNote => '主题、字体、颜色、页面';

  @override
  String get settingsFolders => '文件夹';

  @override
  String get settingsFoldersNote => '人、地方、阶段';

  @override
  String get settingsMedia => '媒体';

  @override
  String get settingsMediaNote => '照片、视频、声音和文稿';

  @override
  String get mediaGroupDocuments => '文稿';

  @override
  String get mediaDocumentsKept => '原样保存，不作改动';

  @override
  String get mediaDocumentsFooter =>
      'PDF 或 Word 文件内部本来就已经压缩过，再压一次只省下大约百分之五。要真正变小就得重新编码里面的图片，那会让扫描件上的小字永久变糊——而你要到很多年后真正需要读它的那天才会发现。';

  @override
  String get settingsTrash => '回收站';

  @override
  String get settingsTrashNote => '删掉的内容，保留 30 天';

  @override
  String get settingsReadableCopy => '可读副本';

  @override
  String get settingsReadableCopyNote => 'Markdown 和你的文件，放进你选的文件夹';

  @override
  String get settingsBringIn => '把旧日记搬进来';

  @override
  String get settingsBringInNote => '其他应用的文本文件，按名字里的日期归档';

  @override
  String get settingsKeepingFooter =>
      '备份用你的密码锁着，和保险库一样。可读副本完全没有锁 — 它就是你选的文件夹里一些普通文件。';

  @override
  String get backupNever => '从未备份';

  @override
  String get backupToday => '今天备份过';

  @override
  String get backupYesterday => '昨天备份过';

  @override
  String backupDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前备份过',
    );
    return '$_temp0';
  }

  @override
  String get mediaGroupIncoming => '进来的时候';

  @override
  String get mediaGroupVoice => '语音笔记';

  @override
  String get mediaIncomingFooter =>
      'Lamplight 从不留第二份更小的副本 — 你在这里选的就是存下来的，原件不会留在别处。';

  @override
  String get mediaVoiceFooter =>
      '转写在这部手机上进行，用的是 Android 自带的识别器。你对 Lamplight 说的话不会被发到任何地方，这个应用也没有发送的权限。';

  @override
  String get mediaPhotoSize => '照片大小';

  @override
  String get mediaVideoSize => '视频大小';

  @override
  String get mediaAskEachTime => '每次都问';

  @override
  String get accentAmber => '琥珀';

  @override
  String get accentAmberNote => '夜里的一盏灯。默认。';

  @override
  String get accentRose => '玫瑰';

  @override
  String get accentRoseNote => '温暖的粉。比琥珀更柔和。';

  @override
  String get accentSage => '鼠尾草';

  @override
  String get accentSageNote => '安静的绿。六个里最沉静的。';

  @override
  String get accentSlate => '石板';

  @override
  String get accentSlateNote => '冷调蓝灰。最中性的。';

  @override
  String get accentPlum => '李子';

  @override
  String get accentPlumNote => '深紫。';

  @override
  String get accentEmber => '余烬';

  @override
  String get accentEmberNote => '焦橙。最暖的。';

  @override
  String get surfacePlain => '素面';

  @override
  String get surfacePlainNote => '一张平整的纸页。';

  @override
  String get surfacePaper => '纸';

  @override
  String get surfacePaperNote => '一层细纹，让页面像有质地，而不是空白。默认。';

  @override
  String get surfaceLamplit => '灯下';

  @override
  String get surfaceLamplitNote => '纸，把灯点上。';

  @override
  String get surfaceStarMap => '星图';

  @override
  String get surfaceStarMapNote => '一片天空，随钟表转动。一天之内不会重样。';

  @override
  String get rulingNone => '无';

  @override
  String get rulingNoneNote => '页面上什么都不印。';

  @override
  String get rulingLines => '横线';

  @override
  String get rulingLinesNote => '像笔记本一样的横格。';

  @override
  String get rulingIsometric => '等距网格';

  @override
  String get rulingIsometricNote => '制图纸，用来在三维里思考。';

  @override
  String get rulingTriangle => '三角';

  @override
  String get rulingTriangleNote => '一片等边三角形。';

  @override
  String get rulingDots => '点阵';

  @override
  String get rulingDotsNote => '每个交点一个点。四种里最安静的。';

  @override
  String get faceSystem => '系统字体';

  @override
  String get faceSystemNote => '你手机其余地方用的那种。';

  @override
  String get faceSerif => '系统衬线体';

  @override
  String get faceSerifNote => '你手机自带的衬线体。';

  @override
  String get faceCalmNote => '边缘柔和，字身宽。';

  @override
  String get faceModernNote => '紧凑，当下的味道。';

  @override
  String get faceOldStyleNote => '十六世纪的书籍字体。';

  @override
  String get facePlayfulNote => '圆润又快活。';

  @override
  String get faceChildlikeNote => '一本练习簿。';

  @override
  String get faceHandwrittenNote => '手写的样子，整页读下来也不费劲。';

  @override
  String get faceMedievalNote => '抄书人的手笔。只有一种字重。';

  @override
  String get faceMonoNote => '每个字母一样宽。';

  @override
  String get qualityOriginal => '保留原件';

  @override
  String get qualityBalanced => '均衡';

  @override
  String get qualitySmaller => '更小';

  @override
  String get photoOriginalNote =>
      '完全按相机拍出的样子保留。文件最大 — 而且会留下拍摄地点，那是 Lamplight 平时会去掉的。';

  @override
  String get photoBalancedNote => '小很多，又很难和原件分辨开。默认。';

  @override
  String get photoSmallerNote => '再小一半。裁得很近时可能会看出来。';

  @override
  String get videoOriginalNote => '完全按相机录下的样子保留。文件大得多。';

  @override
  String get videoBalancedNote => '小很多，又很难和原件分辨开。默认。';

  @override
  String get videoSmallerNote => '再小一半。在大屏幕上可能会看出来。';

  @override
  String get appearanceTitle => '外观';

  @override
  String get appearanceTheme => '主题';

  @override
  String get appearanceThemeDark => '深色';

  @override
  String get appearanceThemeLight => '浅色';

  @override
  String get appearanceThemeAuto => '跟随系统';

  @override
  String get appearanceThemeAutoNote => '跟随你手机的深浅设置。';

  @override
  String get appearanceFont => '字体';

  @override
  String get appearanceSize => '字号';

  @override
  String get appearanceColour => '颜色';

  @override
  String get appearancePage => '页面';

  @override
  String get appearanceRuling => '格线';

  @override
  String get daySavedToToday => '已存到今天。';

  @override
  String get dayAddedToToday => '已添加到今天。';

  @override
  String get entryEditWords => '改写文字';

  @override
  String get entryDeleteBlock => '删除整块';

  @override
  String entrySavedAs(String name) {
    return '已存为 $name。';
  }

  @override
  String entryAddedToFolder(String name) {
    return '也在 $name 里。';
  }

  @override
  String get entrySaveCopy => '保存一份副本';

  @override
  String get entrySaveCopyNote => '你选的地方，在 Lamplight 之外';

  @override
  String get capturePhotoTake => '拍一张';

  @override
  String get capturePhotoChoose => '从你的照片里选';

  @override
  String get composerHintToday => '写写今天…';

  @override
  String get composerHintPast => '写写这一天…';

  @override
  String get composerNewBlock => '新起一块';

  @override
  String get voiceShowTranscript => '看看说了什么';

  @override
  String get voiceHideTranscript => '收起说的内容';

  @override
  String get voiceTranscriptTitle => '说了什么';

  @override
  String get entryEdited => '，已修改';

  @override
  String photoSemantic(String time) {
    return '$time 的照片。双击查看。';
  }

  @override
  String get sizeThisPhoto => '这张照片';

  @override
  String get sizeThesePhotos => '这些照片';

  @override
  String get sizeThisVideo => '这个视频';

  @override
  String get sizeTheseVideos => '这些视频';

  @override
  String sizeQuestion(String what) {
    return '$what要按多大保存？';
  }

  @override
  String get trashNote => '删掉的东西在这里留 30 天，然后就彻底没了。';

  @override
  String get trashConfirm => '要彻底删掉这些吗？';

  @override
  String get trashKeep => '留着';

  @override
  String get trashDeleteForGood => '彻底删掉';

  @override
  String get trashPutBack => '放回去';

  @override
  String trashPutBackOn(String day) {
    return '已放回 $day。';
  }

  @override
  String get trashEmpty => '清空回收站';

  @override
  String get folderMakeFirst => '先建一个';

  @override
  String folderDeleteAsk(String name) {
    return '要删掉“$name”吗？';
  }

  @override
  String get folderKeepIt => '留着';

  @override
  String get folderDeleteIt => '删掉这个文件夹';

  @override
  String get folderRename => '重命名';

  @override
  String get folderDeleteThis => '删掉这个文件夹';

  @override
  String folderTakenOut(String name) {
    return '已从 $name 里取出。它还在它那天。';
  }

  @override
  String get searchHint => '词句、日期、名字…';

  @override
  String get searchBack => '返回';

  @override
  String get searchClear => '清空';

  @override
  String searchNothingMatches(String query) {
    return '没有匹配“$query”的内容。';
  }

  @override
  String get searchWhatMattered => '真正在意的';

  @override
  String get searchADate => '日期';

  @override
  String get searchDateExample => '2006年3月16日 · 2006年3月 · 昨天';

  @override
  String get searchWhatYouCanType => '可以找些什么';

  @override
  String get searchTryDate => '昨天';

  @override
  String get searchSaidOutLoud => '说出来的';

  @override
  String get searchAPhotograph => '一张照片';

  @override
  String get searchAVideo => '一段视频';

  @override
  String get securityWhileOpen => '应用开着的时候';

  @override
  String get securityLockFooter => 'Lamplight 一退到后台就会立刻上锁。这里只决定你还在里面时它等多久。';

  @override
  String get securityLockAfter => '多久后上锁';

  @override
  String get securityOneHour => '1 小时';

  @override
  String get securityYourPasscode => '你的密码';

  @override
  String get securityPasscodeFooter =>
      '你的密码就是钥匙。它不存在任何地方 — 不在这部手机上，也不在别处 — 所以没人能被迫交出它，也没人能替你找回它。';

  @override
  String get securityChangePasscode => '更改密码';

  @override
  String get securityScreenshots => '截屏';

  @override
  String get securityScreenshotsFooter =>
      'Lamplight 会阻止截屏，这样拿起你手机的人拍不到你的笔记，它们也永远不会出现在最近应用的预览里。你可以为自己的手机关掉这个。';

  @override
  String get securityAllowScreenshots => '允许截屏';

  @override
  String get securityScreenshotsOn => '你的笔记会出现在最近使用的应用里';

  @override
  String get securityScreenshotsOff => '最近使用的应用里只会看到一张空白页';

  @override
  String get securityCouldNotChange => '这项无法更改。';

  @override
  String get securityNothingChanged => '你的锁定设置没有任何改变。';

  @override
  String get securityPromptAutomatic => '会自动出现提示';

  @override
  String get securityPromptOnTap => '想用时点一下指纹';

  @override
  String get mediaAskEachTimeOn => '添加照片和视频时会问你要保留多大。';

  @override
  String get mediaAskEachTimeOff => '已关闭。会直接使用上面的两个尺寸。';

  @override
  String get passcodeNew => '新的密码';

  @override
  String get securityFingerprint => '指纹';

  @override
  String get securityFingerprintFooter =>
      '你的那句话仍然是钥匙。指纹只能打开这个保险库，只在这部手机上；如果手机里的指纹发生变化，Android 会自己关掉它 — 所以没有人能添加自己的指纹进来。它永远不会进入备份。';

  @override
  String get securityUnlockWithFingerprint => '用我的指纹打开';

  @override
  String get securityAskOnOpen => '打开 Lamplight 就直接问';

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 秒',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时',
    );
    return '$_temp0';
  }

  @override
  String get durationNever => '从不';

  @override
  String get securityDefaultNote => '默认。';

  @override
  String get securityHourNote => '留一个下午翻旧账用。';

  @override
  String get securityNeverNote => '离开应用时它照样立刻上锁。';

  @override
  String get calendarGoToDate => '跳到某一天';

  @override
  String get dayHasWriting => '文字';

  @override
  String get dayHasPhoto => '一张照片';

  @override
  String get dayHasVideo => '一段视频';

  @override
  String get dayHasVoice => '一段语音';

  @override
  String get dayHasFile => '一个文件';

  @override
  String dayEntriesAndKinds(Object count, Object kinds) {
    return '$count，$kinds';
  }

  @override
  String get listSeparator => '、';

  @override
  String listAnd(Object last, Object most) {
    return '$most和$last';
  }

  @override
  String get integrityNothingUnusual => '这台手机没有异常。Lamplight 正按它该有的样子运行。';

  @override
  String get calendarPreviousYear => '上一年';

  @override
  String get calendarPreviousMonth => '上一个月';

  @override
  String get calendarNextYear => '下一年';

  @override
  String get calendarNextMonth => '下一个月';

  @override
  String get calendarBackToMonth => '回到这个月';

  @override
  String get calendarWholeYear => '整整一年';

  @override
  String get calendarBackToThisMonth => '回到本月';

  @override
  String get calendarNothingThisYear => '这一年还什么都没有。';

  @override
  String calendarYearSummary(Object days, Object entries) {
    return '$days里有 $entries。';
  }

  @override
  String get folderNothingInIt => '里面还什么都没有';

  @override
  String get onThisDayOneYear => '一年前的今天';

  @override
  String onThisDayYears(Object years) {
    return '$years 年前的今天';
  }

  @override
  String wheelYear(Object year) {
    return '$year 年';
  }

  @override
  String get calendarBackToBrowsing => '回到翻阅';

  @override
  String get calendarToday => '今天';

  @override
  String get calendarFirstEntry => '你写的第一条';

  @override
  String get calendarGoToThisDay => '跳到这一天';

  @override
  String get calendarDensityNote => '颜色显示某天有多少，从没有到很多。';

  @override
  String get calendarLess => '少';

  @override
  String get calendarMore => '多';

  @override
  String get calendarGoToToday => '回到今天';

  @override
  String get backupTitle => '备份';

  @override
  String get vaultNothingToBackUp => '这个保险箱里还没有可以备份的东西。';

  @override
  String vaultChangedWhileBackingUp(Object name) {
    return '备份过程中有东西变了（$name）。请再试一次。';
  }

  @override
  String get vaultTooSmall => '这个文件太小，不可能是 Lamplight 的备份。';

  @override
  String get vaultNotALamplightFile => '这不是 Lamplight 的备份文件。';

  @override
  String get vaultDamaged => '这个文件已损坏，无法打开。';

  @override
  String get vaultKeyringNewerVersion => '这个保险箱是用更新版本的 Lamplight 做的。请更新应用后再打开。';

  @override
  String get vaultKeyringDamaged => '保险箱的钥匙文件已损坏，读不出来。如果你有备份文件，请从那里恢复。';

  @override
  String get vaultDatabaseNewerVersion =>
      '这个保险箱是用更新版本的 Lamplight 做的。请更新应用后再打开 — 你的笔记完好无损，什么都没有改动。';

  @override
  String phraseWrongLength(Object count) {
    return '恢复词是 12 个词。这一组有 $count 个。';
  }

  @override
  String phraseNotARecoveryWord(Object word) {
    return '“$word”不是恢复词之一。';
  }

  @override
  String get phraseDoesNotCheckOut => '那些词不是有效的恢复词。看看是不是有一个打错了或者位置调换了。';

  @override
  String get vaultNewerVersion => '这份备份是用更新版本的 Lamplight 做的。请先更新应用，再试一次。';

  @override
  String get vaultUnknownCompression => '这份备份用了这个版本读不懂的压缩方式。';

  @override
  String get vaultDamagedTryOlder => '这个文件已损坏，无法打开。如果你有更早的备份，试试那一份。';

  @override
  String get vaultBeforeRecoveryPhrases => '这份备份做于恢复词还打不开备份文件的时候。它的密码是唯一的入口。';

  @override
  String get vaultWordsDoNotOpenIt => '那些词打不开这个文件。它们可能属于另一个保险箱。';

  @override
  String get vaultWrongPasscode => '这个密码打不开这个文件。';

  @override
  String vaultMissingPart(Object name) {
    return '这份备份缺了自己的一部分（$name）。';
  }

  @override
  String vaultPartWrongSize(Object name) {
    return '这份备份已损坏（$name 的大小不对）。';
  }

  @override
  String vaultPartDoesNotMatch(Object name) {
    return '这份备份已损坏（$name 对不上）。';
  }

  @override
  String get vaultNoVaultInside => '这份备份里没有保险箱。它可能是别的应用做的。';

  @override
  String get vaultOutOfOrder => '这个文件已损坏：里面的内容次序乱了。';

  @override
  String get vaultEndsPartWay => '这个文件已损坏：它在中途就结束了。';

  @override
  String vaultIncomplete(Object parts) {
    return '这个文件不完整 — 它只有其中的 $parts。';
  }

  @override
  String vaultWillNotOpen(Object name) {
    return '这份备份里有 Lamplight 不会打开的东西（$name）。';
  }

  @override
  String countEntries(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条',
    );
    return '$_temp0';
  }

  @override
  String countDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
    );
    return '$_temp0';
  }

  @override
  String get backupCheckingItOpens => '正在确认它能打开…';

  @override
  String get backupCouldNotSave => '备份无法保存。';

  @override
  String get backupNothingLost => '没有丢失任何东西，你的笔记原封未动。过一会儿再试。';

  @override
  String get backupLast => '上一次备份';

  @override
  String get backupInTheVault => '保险箱里';

  @override
  String get restoreCheckingFile => '正在检查文件…';

  @override
  String get restoreCouldNotOpen => '这个文件无法打开。';

  @override
  String get restoreCheckItIsTheOne => '确认这是你要的那份备份，然后再试一次。';

  @override
  String get restorePuttingInPlace => '正在放到位…';

  @override
  String get restorePuttingBack => '正在把你原来的笔记放回去…';

  @override
  String get restoreCouldNotFinish => '恢复没能完成。';

  @override
  String get restoreBackAsTheyWere => '你的笔记已经恢复原样。';

  @override
  String get restoreUsePasscodeInstead => '改用密码';

  @override
  String get restoreUseWordsInstead => '我有那十二个词';

  @override
  String get backupCreateFile => '创建备份文件';

  @override
  String get backupCreatedChecked => '备份已创建并核对。';

  @override
  String get backupMakeAnother => '再做一个';

  @override
  String get backupRestoreHeading => '恢复';

  @override
  String get backupRestoreFrom => '从备份文件恢复';

  @override
  String backupProgress(String stage, int percent) {
    return '$stage 百分之 $percent';
  }

  @override
  String get restoreTitle => '恢复';

  @override
  String get restoreChooseFile => '选一个文件';

  @override
  String get restoreUseLatest => '使用最新备份';

  @override
  String get restorePhraseHint => '记得 故事 工业…';

  @override
  String get restoreAction => '恢复';

  @override
  String get restoreChooseDifferent => '换一个文件';

  @override
  String get importChooseFolder => '选一个文件夹';

  @override
  String get importChooseFiles => '改为选择文件';

  @override
  String get importChooseFilesNote =>
      '如果 Android 拒绝你的文件夹 —— 它不会把下载文件夹或存储根目录交给任何应用 —— 请直接选择文件。这不会被拒绝。';

  @override
  String get importLooking => '正在翻看文件夹…';

  @override
  String get importNoTextFiles => '那个文件夹里没有文本文件。';

  @override
  String get importChooseDifferentFolder => '换一个文件夹';

  @override
  String get importUseFileDate => '用文件自己的日期';

  @override
  String get importUseFileDateNote => '把它们放到文件最后修改的那天。那常常不是它写的那天。';

  @override
  String importBringIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '导入 $count 条',
    );
    return '$_temp0';
  }

  @override
  String importProgress(int percent) {
    return '正在导入，百分之 $percent';
  }

  @override
  String get exportChooseFolder => '选个文件夹导出';

  @override
  String get exportSave => '保存可读副本';

  @override
  String get exportWritten => '你的副本写好了。';

  @override
  String get exportAgain => '再导出一次';

  @override
  String get exportWhichOne => '我要哪一个？';

  @override
  String get exportNotLocked => '这份副本没有上锁';

  @override
  String dayAddedThings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已把 $count 样东西添加到今天。',
    );
    return '$_temp0';
  }

  @override
  String get entryAddNote => '给它写一句';

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已添加 $count 个。',
    );
    return '$_temp0';
  }

  @override
  String get importFolderUnreadable => '这个文件夹读不了。';

  @override
  String get importNothingBrought => '什么都没有带进来。';

  @override
  String get importStoppedPartWay => '导入日记中途停下了。';

  @override
  String get importWhatArrivedKept => '停下之前已经进来的都保留了。';

  @override
  String get importNoReadableDates => '这些文件里没有一个带着 Lamplight 能读懂的日期。';

  @override
  String importReadyToBring(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条准备带进来。',
    );
    return '$_temp0';
  }

  @override
  String get importNothingNew => '没有新的可以带进来。';

  @override
  String importBroughtIn(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '带进来 $count 条。',
    );
    return '$_temp0';
  }

  @override
  String importAlreadyHere(Object count) {
    return '有 $count 条本来就在，所以没有动。';
  }

  @override
  String importNoDateSkipped(Object count) {
    return '有 $count 条没有能读的日期，跳过了。';
  }

  @override
  String importCouldNotRead(Object count, Object names) {
    return '有 $count 条读不了：$names';
  }

  @override
  String get exportStarting => '开始中…';

  @override
  String get exportCouldNotFinish => '可读副本没能完成。';

  @override
  String get exportNothingChanged => 'Lamplight 里没有任何改变。';

  @override
  String get importVideoAlreadySmall => '有一段视频本来就已经足够小了，所以按原样保存。';

  @override
  String get importVideoCouldNotShrink => '有一段视频在这台手机上无法缩小，所以完整保存了。';

  @override
  String importOneFailed(String reason) {
    return '有一个没成功：$reason';
  }

  @override
  String importAbandoned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lamplight 上锁前有 $count 个没弄完。',
    );
    return '$_temp0';
  }

  @override
  String get importNothingLeft => '手机上什么都没有留下。';

  @override
  String get nameCardAsk => '这里写什么？';

  @override
  String get nameCardHint => '你的名字，或者别的';

  @override
  String get reminderGroup => '想要的话，轻轻提醒一下';

  @override
  String get reminderFooter =>
      '你不开就一直关着。它从不提你笔记里的内容 — 也做不到，因为它是在保险库锁着的时候运行的。没有连续天数，没有计数，也不会提你漏掉的日子。';

  @override
  String get reminderTitle => '提醒我写点什么';

  @override
  String get reminderWhen => '什么时候';

  @override
  String get reminderProblemNotAllowed => 'Lamplight 没有发送通知的权限。';

  @override
  String get reminderProblemNotificationsOff => '这部手机的设置里，Lamplight 的通知是关的。';

  @override
  String get reminderProblemRemindersOff => '这部手机的通知设置里，Lamplight 的提醒是关的。';

  @override
  String get reminderProblemBatterySaving =>
      '这部手机为了省电，把 Lamplight 拦住了。提醒来得晚或者根本不来，通常就是这个原因。';

  @override
  String get reminderMayNotArrive => '提醒可能到不了';

  @override
  String get backupAutomatic => '自动备份';

  @override
  String get backupAutomaticDidNotFinish => '自动备份没有完成。';

  @override
  String get backupNothingYet => '还没有需要备份的东西。';

  @override
  String get backupInProgress => '正在备份…';

  @override
  String get backupStartsAtUnlock => '下次解锁时开始。';

  @override
  String get backupDoneAutomatically => '已自动备份。';

  @override
  String get backupLastOneFailed => '上一次自动备份没有完成。下次打开 Lamplight 时会再试。';

  @override
  String importNthOf(Object index, Object total) {
    return '第 $index 个，共 $total 个';
  }

  @override
  String importWaiting(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个在等',
    );
    return '$_temp0';
  }

  @override
  String get aboutCopied => '已复制';

  @override
  String get failureGeneric => '那一步没有成功。';

  @override
  String get failureNothingLost => '没有丢失任何东西，再试一次。';

  @override
  String get calendarNothingOnDay => '没有';

  @override
  String get backupChangeFolder => '换个文件夹';

  @override
  String backupSavedTo(String place) {
    return '保存到 $place';
  }

  @override
  String get backupUseDefaultFolder => '使用默认文件夹';

  @override
  String get backupChooseFolder => '选择一个文件夹来存放副本';

  @override
  String get folderAndroidRestriction =>
      'Android 不会把“下载”文件夹或整个内部存储交给任何应用。“文档”，或者它里面的文件夹，可以。';

  @override
  String get folderNotWritable => '无法在该文件夹中保存任何内容。请换一个。';

  @override
  String get folderRefused => '无法使用该文件夹。';

  @override
  String get folderTryAnother => '试着换一个。';

  @override
  String get aboutHowKept => '你的笔记怎么保存';

  @override
  String get aboutFonts => '字体与许可';

  @override
  String get aboutVersion => '版本';

  @override
  String get aboutNoBrowser => '这部手机上没有应用能打开链接。';

  @override
  String get aboutMadeBy => '作者';

  @override
  String get aboutMadeBySemantic => '由 ProbablyPiyush 制作。在浏览器中打开 LinkedIn。';

  @override
  String get aboutCoffee => '请我喝杯咖啡';

  @override
  String get aboutCoffeeSemantic => '请我喝杯咖啡。在浏览器中打开一个页面。';

  @override
  String get aboutCopyDetails => '复制这些信息';

  @override
  String settingsNameSemantic(Object name) {
    return '$name。点一下可以更改。';
  }

  @override
  String get settingsAddName => '写上你的名字';

  @override
  String get settingsNameOnlyHere => '只在这台手机上';

  @override
  String get settingsNameOptional => '可以不填。它永远只在这台手机上。';

  @override
  String get reminderTurnedOffByAndroid =>
      'Android 关闭了 Lamplight 的通知。你可以在手机设置的“应用”里打开。';

  @override
  String get reminderOnceADay => '每天一次';

  @override
  String reminderTodayAt(Object time) {
    return '今天 $time';
  }

  @override
  String reminderYesterdayAt(Object time) {
    return '昨天 $time';
  }

  @override
  String reminderOnDateAt(Object date, Object time) {
    return '$date $time';
  }

  @override
  String get reminderNoneYet => '还没有收到过';

  @override
  String reminderLastArrived(Object when) {
    return '上一次是在 $when';
  }

  @override
  String reminderNextDue(Object when) {
    return '下一次是 $when';
  }

  @override
  String get aboutHide => '收起';

  @override
  String get aboutCheckReal => '检查这是不是真正的 Lamplight';

  @override
  String get entryRevisionsNote => '你改之前写的是';

  @override
  String get entryStaysOnDay => '它同样留在这一天';

  @override
  String entryDeleteKind(String kind) {
    return '删除$kind';
  }

  @override
  String get shareCouldNotAdd => '那个没能添加。试试先保存，再用图片按钮。';

  @override
  String get openNothingCanOpen => '这部手机上没有东西能打开这种文件。';

  @override
  String get viewerMore => '更多';

  @override
  String get docLeavesLamplight => '这会离开 Lamplight';

  @override
  String get docKeepItHere => '留在这里';

  @override
  String get docOpenWith => '用其他应用打开…';

  @override
  String docCannotShow(String kind) {
    return 'Lamplight 能显示 PDF、图片和文字，而且从不把它们不加密地放到你手机上。$kind 文件需要别的应用 — Lamplight 可以在你阅读期间把它借出去，读完再收回来。';
  }

  @override
  String get menuOpenWithNote => '另一个应用，不留副本';

  @override
  String menuSaveKind(String kind) {
    return '保存$kind';
  }

  @override
  String get menuTrashNote => '保留 30 天，然后消失';

  @override
  String get videoBackTen => '后退十秒';

  @override
  String get videoForwardTen => '前进十秒';

  @override
  String get photoPlayVideo => '播放这个视频';

  @override
  String get lockPhraseHint => '你的十二个词，中间留空格';

  @override
  String get lockUnlock => '打开';

  @override
  String get errorScreenDidNotOpen => '那个页面没有打开。什么都没丢。';

  @override
  String get errorGoBack => '返回';

  @override
  String recordingCannot(String what) {
    return '这部手机不会$what录音。录音还在继续。';
  }

  @override
  String get recordingClose => '关闭';

  @override
  String recordingElapsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '正在录音，$count 秒',
    );
    return '$_temp0';
  }

  @override
  String get recordingStopKeep => '停下并保留这段录音';

  @override
  String get recordingDiscard => '丢弃';

  @override
  String get recordingCouldNotStart => '无法开始录音。';

  @override
  String get recordingCheckMicrophone => '请检查 Lamplight 是否有使用麦克风的权限。';

  @override
  String get recordingStartAgain => '继续录音';

  @override
  String get recordingCouldNotSave => '这段录音无法保存。';

  @override
  String get recordingStillHere => '它还在这里，试着再停止一次。';

  @override
  String get recordingCarryOnSemantic => '继续录音';

  @override
  String get recordingPauseSemantic => '暂停这段录音';

  @override
  String get recordingCarryOn => '继续';

  @override
  String get recordingPause => '暂停';

  @override
  String get sizeAdd => '添加';

  @override
  String get transcribeTitle => '把说的话写下来';

  @override
  String get transcribeOn => '语音笔记就能被搜到。什么都不会被发到任何地方。';

  @override
  String get transcribeOff => '关着。语音笔记只能按它那天找到。';

  @override
  String get transcribeLanguage => '说话的语言';

  @override
  String get transcribeLanguageNote =>
      '你在录音里说的语言。一次只能一种 — 一句中途换语言的话，只会带回和这里对得上的那一半。';

  @override
  String get transcribeNotDownloaded => '这部手机上还没下载 — 点一下去取。';

  @override
  String transcribeGetBetter(String name) {
    return '下载 $name 的更好模型';
  }

  @override
  String get transcribeGetBetterNote =>
      '用它转写会明显更准。下载由你的手机完成，不是 Lamplight，而且只做一次。';

  @override
  String get transcribeNoLanguages => '这部手机还没提供任何语言。';

  @override
  String get transcribeNeedsDownloading => '需要下载';

  @override
  String folderStill(String day, String folder) {
    return '仍在 $day。也在 $folder 里。';
  }

  @override
  String get folderRenameTitle => '重命名文件夹';

  @override
  String get folderNameHint => '一个人、一个地方、一段日子';

  @override
  String get voicePlay => '播放这条语音';

  @override
  String get voiceForwardThirty => '前进三十秒';

  @override
  String voiceSpeed(String speed) {
    return '速度，现在 $speed 倍';
  }

  @override
  String get voiceLengthUnknown => '语音笔记，播放前不知道多长';

  @override
  String get voicePosition => '录音中的位置';

  @override
  String get voiceOpening => '正在打开录音';

  @override
  String get voiceNoWords => '没有返回任何文字 — 再试一次';

  @override
  String get voiceWriteThis => '把这段写下来';

  @override
  String get voiceCannotWrite => '这部手机没法把语音写下来。';

  @override
  String get voiceLanguageMissing => '这部手机还没下载那个语言。';

  @override
  String get voiceWriting => '正在写下来…';

  @override
  String get voiceWaiting => '等着被写下来。';

  @override
  String get voiceWritten => '已在这部手机上写好。';

  @override
  String get errorPartNotShown => '这一部分没能显示。';

  @override
  String get errorScreenShort => '那个页面没有打开。';

  @override
  String get errorNothingLost => '什么都没丢。你写下的一切还在保险库里，和原来一模一样。';

  @override
  String get errorHideDetails => '收起技术细节';

  @override
  String get errorShowDetails => '查看技术细节';

  @override
  String get errorDetailsNote =>
      '这就是会被复制的全部内容。它说明哪里出错、在代码的什么位置 — 里面没有你写过的任何东西。';

  @override
  String get passcodeChangeFailed => '密码没能更改。';

  @override
  String get passcodeOldStillWorks => '你原来的密码还能用。';

  @override
  String get passcodeChanged => '密码已更改';

  @override
  String get passcodeWordsUnchanged => '你的十二个词没有变，也不需要新的。它们照常打开你的保险库和备份文件。';

  @override
  String get passcodeOldBackups => '你已有的备份仍然用旧密码打开。现在新做的，会用新密码。';

  @override
  String get passcodeMakeBackup => '现在做个备份';

  @override
  String get passcodeCurrent => '当前密码';

  @override
  String get passcodeNewAgain => '再输一次新密码';

  @override
  String get passcodeOldBackupsNote => '你已经做好的备份文件仍然会用旧密码打开。';

  @override
  String get passcodeWordsNote => '你的十二个恢复词不会变，照常有效。';

  @override
  String get licencesFonts => '这里每一款字体都在 SIL 开放字体许可下。什么都不下载 — 它们就在应用里。';

  @override
  String get licencesSource =>
      'Lamplight 本身是 GPL-3.0，附带一条应用商店例外。源码就是许可：任何人都能读它，核对这个应用是不是在做这一页说的事。';

  @override
  String get licencesUnreadable => '那个许可文件读不出来。';

  @override
  String get appearanceSample => '下了一下午的雨。泡了茶，读了半章，忘了本来想说什么，就写了这个。';

  @override
  String get appearanceChromeNote => '按钮和标签保持这样';

  @override
  String get appearanceSizeNote => '这是叠加在你手机自己的字号之上的，所以如果你已经调大过，这里会再大一些。';

  @override
  String get voicePause => '暂停';

  @override
  String get importIntro => '如果你在别处写过日记，Lamplight 可以把它读进来 — 只要是文本文件，而且名字里有日期。';

  @override
  String get importHowDates =>
      '它读纯文本文件，并在名字里找日期 — 2026-08-24，或 24 August 2026 — 文件名里或上层文件夹里都行。';

  @override
  String get importAmbiguousDates =>
      '像 03-04-2026 这样的日期会被特意跳过。在有些国家那是四月三日，在另一些是三月四日，猜错就会把你一年的生活归到错的日子上，还什么都不说。';

  @override
  String get importFormats =>
      'Lamplight 读纯文本：.txt、.md、.org、.log 等等，连没有扩展名的文件也读。如果你的日记是别的格式，先导出成文本。';

  @override
  String get importAtStartOfDay =>
      '它们会排在每天的最前面，因为文件名给得出日期，给不出时刻。Lamplight 里已有的东西不会被改动或移除，再跑一次也不会产生副本。';

  @override
  String get importFileDateNote =>
      '把它们放到文件最后修改的那天。如果这个文件夹在设备之间复制过，那可能是复制的日子，而不是你书写的日子。';

  @override
  String get importSkippedNote => '这些会被跳过。它们原样留在那里 — 你的文件夹里什么都不会被移动或删除。';

  @override
  String get restoreChooseNote => '选你的备份文件。它的名字大概是 Lamplight-2026-08-18.vault。';

  @override
  String get restorePasscodeNote => '输入这个文件的密码 — 做备份时设定的那一个。';

  @override
  String get restoreWordsNote => '按顺序输入十二个词，中间用空格隔开。';

  @override
  String get restoreDoNotClose => '在这件事做完之前，不要关掉 Lamplight。';

  @override
  String get exportIntro =>
      '这会把 Lamplight 里的一切写进你选的文件夹，都是普通文件 — 每天一个文本文件，每张照片、每段视频、每条语音和每份文档各用自己的名字。';

  @override
  String get exportNoLamplightNeeded =>
      '那个文件夹里的东西不需要 Lamplight 才能打开。就算这个应用哪天不能用了，或者你不再用它，你的笔记照样能用任何读文本的东西打开。';

  @override
  String get exportWhichOneBody =>
      '可读副本是拿来读的、搬到别的应用去的，或者在你不再用 Lamplight 之后留点东西。它没有保护。\n\n备份文件是为了把 Lamplight 原样找回来 — 换了新手机，或者手机坏了。它用你的密码锁着，所以放哪里都安全，包括云盘。\n\n大多数人要的是备份。如果你想确保永远不会卡住，那就再做一份可读副本。';

  @override
  String get exportNotLockedBody =>
      '它上面没有密码。任何人打开那个文件夹都能读到全部内容。放在你能接受这一点的地方 — 如果你只是想存一份安全的，那就用备份。';

  @override
  String get backupConfirmNote => '确认你的密码。这个文件能打开一切，所以做它应该是你有意为之。';

  @override
  String get backupKeepSafeNote =>
      '你的备份用你现在的密码锁着。放在你信得过的地方 — 云盘也行，因为没有那个密码这个文件读不出来。我们从不经手它。';

  @override
  String get backupRestoreWarning =>
      '打开一份备份会替换掉 Lamplight 里现有的一切。在确认恢复的内容能打开之前，你现在的笔记会先被搁在一旁。';

  @override
  String get folderWhatItIs => '文件夹是一条穿过你许多天的线 — 一个人、一个地方、一段日子。';

  @override
  String get folderNothingMoves => '没有东西会搬进文件夹。一条记录留在它自己那天，同时也出现在这里。';

  @override
  String get folderDeleteNote => '文件夹没了。里面的一切原样留在原处，各自在自己那天。';

  @override
  String get folderNoneInHere => '这里还什么都没有。在某一天上长按任意内容，选“加入文件夹”。';

  @override
  String get passcodeRuleLength => '八个字符以上。';

  @override
  String get passcodeRuleWords => '几个你记得住的普通词，胜过一个带符号的短密码。';

  @override
  String get passcodeNoMatch => '这两个还不一样。';

  @override
  String get docCopyInClear =>
      '副本是不加密写出去的，所以任何能读你文件的应用都能读它。留在 Lamplight 里的东西无论如何都还是加密的。';

  @override
  String docPageOf(String page, String total) {
    return '第 $page 页，共 $total 页';
  }

  @override
  String get transcribeTookTooLong => '那段录音转写太久了，Lamplight 就不再等。稍后会再试。';

  @override
  String get transcribeCouldNotWriteDown => '那段录音无法转写成文字。';

  @override
  String get transcribeRecordingIsSafe => '录音本身没事。Lamplight 会再试一次。';

  @override
  String voicePositionSpoken(Object at, Object total) {
    return '$total 中的 $at';
  }

  @override
  String entryEditedAt(Object time) {
    return '$time · 改过';
  }

  @override
  String get docCouldNotOpen => '这份文件无法打开。';

  @override
  String albumThisOne(Object thing) {
    return '这个$thing';
  }

  @override
  String albumThisOneOf(Object index, Object thing, Object total) {
    return '这个$thing — 第 $index 个，共 $total 个';
  }

  @override
  String get albumCaptionThese => '给这些写点什么';

  @override
  String get albumCaptionThis => '写点什么';

  @override
  String get albumCaptionEdit => '修改写的内容';

  @override
  String albumOthersStay(Object count) {
    return '其余 $count 个保留。这一个会放进回收站 30 天。';
  }

  @override
  String get albumGoesToTrash => '它会放进回收站 30 天。';

  @override
  String get photoCouldNotOpen => '这张图片无法打开。';

  @override
  String get photoMayBeDamaged => '它可能已经损坏。';

  @override
  String get docTooBig => '这个文件太大，无法在 Lamplight 里打开。你可以保存一份副本，在别处打开。';

  @override
  String docPages(Object count) {
    return '$count 页';
  }

  @override
  String get docFileEmpty => '这个文件是空的。';

  @override
  String videoTooBig(Object size) {
    return '这段视频太大，无法在这里播放 — $size。不会为此把它不加保护地写出去。保存一份副本，到别处观看。';
  }

  @override
  String get videoNotAvailableHere => '这台手机上没有应用的这一部分。';

  @override
  String get videoCouldNotOpen => '这段视频无法打开。';

  @override
  String get docGoToPage => '跳到某一页';

  @override
  String get docGo => '前往';

  @override
  String get docPageCouldNotBeDrawn => '这一页无法显示。';

  @override
  String get passcodeRuleStronger => '再加一两个词，会难猜得多。';

  @override
  String get backupAutoFooter =>
      '自动备份在你打开 Lamplight 时进行，前提是自上次以来有变化。它和你自己做的一样，用你的密码锁着。';

  @override
  String get aboutHowKeptBody =>
      '没有账户。没有服务器。什么都不会离开这部手机。\n\n你的笔记用你的密码锁着，钥匙由它生成 — 所以任何地方都没有它的副本，我们这里也没有。';

  @override
  String get aboutFree => 'Lamplight 是免费的，而且一直会是。没有什么需要解锁。';

  @override
  String get aboutContact => '有什么不对吗？告诉我。';

  @override
  String get aboutContactSemantic => '通过电子邮件发送反馈';

  @override
  String aboutNoMail(String address) {
    return '这部手机没有邮件应用。地址是 $address。';
  }

  @override
  String get backupOnItsOwn => '自动进行';

  @override
  String get actionDismiss => '知道了';

  @override
  String importRange(String from, String to) {
    return '从 $from 到 $to。';
  }

  @override
  String get sizeOneCopy => 'Lamplight 只保留一份。你在这里选的，就是你会拥有的。';

  @override
  String get sizeAddAlways => '添加，以后别再问';

  @override
  String get trashNothingHere => '这里什么都没有。';

  @override
  String get appearanceAaQuiet => 'Aa\n安静';

  @override
  String lockWarnSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '大约 $count 秒后上锁。',
    );
    return '$_temp0';
  }

  @override
  String get lockWarnChange => '可以在“锁定与安全”里更改。';

  @override
  String get openingLabel => 'Lamplight 正在打开';

  @override
  String get recordingNoMic => 'Lamplight 无法使用麦克风。你可以在手机设置的“应用”里打开它。';

  @override
  String get recordingPaused => '已暂停。现在什么都听不到。';

  @override
  String get videoOpening => '正在打开视频…';

  @override
  String albumRemoveThis(String thing) {
    return '移除这$thing';
  }

  @override
  String get revisionsNote => '你改之前写的是这样。这里没有按钮 — 你可以选中文字复制走。';

  @override
  String get composerSemantic => '为这一天写点什么';

  @override
  String importStripAdding(String name) {
    return '正在添加 $name';
  }

  @override
  String passcodeAtLeast(int count) {
    return '至少 $count 个字符';
  }

  @override
  String get searchKindAll => '全部';

  @override
  String get searchKindWords => '文字';

  @override
  String get searchKindVoice => '语音';

  @override
  String get searchKindPhotos => '照片';

  @override
  String get searchKindFiles => '文件';

  @override
  String passcodeAtLeastShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '至少 $count 个字符',
    );
    return '$_temp0';
  }

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还剩 $count 天',
    );
    return '$_temp0';
  }

  @override
  String get trashGoneToday => '今天就没了';

  @override
  String restoreMadeOn(String date) {
    return '制作于 $date';
  }

  @override
  String restoreDone(String entries, String days) {
    return '已恢复 $entries，跨 $days。欢迎回来。';
  }

  @override
  String importFoundUndated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个没有 Lamplight 能读的日期',
    );
    return '$_temp0';
  }

  @override
  String entrySemantic(String time) {
    return '$time 的记录。点按编辑。';
  }

  @override
  String entrySemanticEdited(String time) {
    return '$time 的记录，已修改。点按编辑。';
  }

  @override
  String onThisDaySemantic(String when, String body) {
    return '$when。$body。点按前往那一天。';
  }

  @override
  String attachmentSemantic(String what, String time) {
    return '$time 的$what。双击打开。';
  }

  @override
  String dayHeaderToday(String date) {
    return '$date，今天';
  }

  @override
  String get yearGridNothing => '这一天什么都没有';

  @override
  String get calendarNothing => '这一天什么都没有';

  @override
  String importStripCounted(String name, String counted) {
    return '正在添加 $name$counted';
  }

  @override
  String get aboutFingerprintBody =>
      '每一个构建都带着只有作者才能生成的签名。这就是你手上这一份的签名。把它和随源码一起公布的指纹对一对 — 如果一致，这就是那份源码构建出来的应用。';

  @override
  String get searchKindVideo => '视频';

  @override
  String get semanticOn => '已开';

  @override
  String andMore(int count) {
    return '还有 $count 个';
  }

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条',
      zero: '什么都没有',
    );
    return '$_temp0';
  }

  @override
  String get checkDone => '已满足';

  @override
  String get checkNotYet => '还没有';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
    );
    return '$_temp0';
  }

  @override
  String get lockUseYourPasscode => '请使用密码。';

  @override
  String get searchWordsExample => '你写过的任何内容';

  @override
  String get searchAFile => '文件';

  @override
  String get searchFileExample => 'scan.pdf · IMG_2831';

  @override
  String get searchAFolder => '文件夹';

  @override
  String get searchFolderExample => '你给它起的名字';

  @override
  String get searchByFileName => '按文件名';

  @override
  String get searchARecording => '一段录音';

  @override
  String get searchAnEntry => '一条记录';

  @override
  String get sizeThisOne => '这个';

  @override
  String get sizeTheseOnes => '这些';

  @override
  String get passcodeOneMoreCharacter => '再加一个字符。';

  @override
  String passcodeMoreCharacters(int count, int minimum) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '再加 $count 个字符 — 最少 $minimum 个。',
    );
    return '$_temp0';
  }

  @override
  String get passcodeTooObvious => '这是任何人都会最先尝试的。请换一个。';

  @override
  String get passcodeSameCharacter => '这是同一个字符的重复。';

  @override
  String get passcodeStraightRun => '这是一串顺序排列的字符。';

  @override
  String attachmentLoading(String time) {
    return '$time 的附件，加载中';
  }

  @override
  String videoSemantic(String time, String length) {
    return '$time 的视频，$length。双击观看。';
  }

  @override
  String voiceSemantic(String time, String length) {
    return '$time 的语音笔记，$length。双击播放。';
  }

  @override
  String fileSemantic(String time, String name, String size) {
    return '$time 的文件，$name，$size。双击打开。';
  }

  @override
  String get lengthUnknown => '时长未知';

  @override
  String get settingsLockNone => '不自动锁定';

  @override
  String settingsLockAfter(String duration) {
    return '$duration后';
  }

  @override
  String settingsSecuritySummary(String lock) {
    return '密码、指纹、$lock';
  }

  @override
  String get keptNoNetworkTitle => '它从不去任何地方';

  @override
  String get keptNoNetworkBody =>
      'Lamplight 无法使用互联网。不是「不用」，而是「用不了」：Android 不给它这项权限，你可以在手机的应用设置里花大约三十秒亲自确认。';

  @override
  String get keptPasscodeTitle => '你的密码就是钥匙';

  @override
  String get keptPasscodeBody =>
      '打开你笔记的钥匙，是每次解锁时由你的密码现场生成的。它不保存在任何地方，因此没有可以被找到、被弄丢或被交出的副本。';

  @override
  String get keptForgetTitle => '如果你忘了它';

  @override
  String get keptForgetBody =>
      '你的十二个词是唯一的另一条入口。这里没有人能重置密码，而这和上面说的是同一件事——一个能让你重新进来的应用，也能让别人进来。';

  @override
  String get keptNothingReadableTitle => '不会有可读的东西留在外面';

  @override
  String get keptNothingReadableBody =>
      '照片、录音和文件在写入存储之前就已加密。任何内容都不会以明文写出，哪怕只是你查看它的那一瞬间。';

  @override
  String get keptLocksItselfTitle => '它会自己上锁';

  @override
  String get keptLocksItselfBody =>
      'Lamplight 一进入后台，密钥就被销毁。截屏被阻止，应用也不会出现在最近任务的预览里。';

  @override
  String get keptBackUpTitle => '请做个备份';

  @override
  String get keptBackUpBody =>
      '一切都只在这部手机上，别无他处——这既是它的用意，也是它的风险。备份是一个加密文件，只有你的密码能打开。请在某处留一份。';

  @override
  String etaSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '大约还剩 $count 秒',
    );
    return '$_temp0';
  }

  @override
  String etaMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '大约还剩 $count 分钟',
    );
    return '$_temp0';
  }

  @override
  String youWroteForMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '你写了 $count 分钟。',
    );
    return '$_temp0';
  }
}
