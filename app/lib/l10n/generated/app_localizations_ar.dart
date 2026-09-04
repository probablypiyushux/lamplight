// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class LAr extends L {
  LAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Lamplight';

  @override
  String get lockTypePasscode => 'اكتب رمز الدخول.';

  @override
  String get lockWrongPasscode => 'هذا لم يفتح الخزنة.';

  @override
  String get lockCheckAndRetry => 'تحقّق من الرمز وحاول مرّة أخرى.';

  @override
  String get lockForgot => 'نسيت رمز الدخول';

  @override
  String get lockTypeTwelveWords => 'اكتب كلماتك الاثنتي عشرة.';

  @override
  String get lockUsePasscodeInstead => 'استخدم رمز الدخول بدلاً من ذلك';

  @override
  String get lockUseFingerprint => 'استخدم بصمتك';

  @override
  String get lockFingerprintFailed => 'لم تنجح البصمة.';

  @override
  String get lockFingerprintUnavailable => 'البصمة غير متاحة.';

  @override
  String get lockOpening => 'جارٍ الفتح…';

  @override
  String get lockNothingDeleted => 'لم يُحذف شيء، ولن يُحذف شيء.';

  @override
  String lockTryAgainSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حاول مرّة أخرى بعد $count ثانية.',
      many: 'حاول مرّة أخرى بعد $count ثانية.',
      few: 'حاول مرّة أخرى بعد $count ثوانٍ.',
      two: 'حاول مرّة أخرى بعد ثانيتين.',
      one: 'حاول مرّة أخرى بعد ثانية.',
      zero: 'حاول مرّة أخرى بعد قليل.',
    );
    return '$_temp0';
  }

  @override
  String lockTryAgainMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حاول مرّة أخرى بعد $count دقيقة.',
      many: 'حاول مرّة أخرى بعد $count دقيقة.',
      few: 'حاول مرّة أخرى بعد $count دقائق.',
      two: 'حاول مرّة أخرى بعد دقيقتين.',
      one: 'حاول مرّة أخرى بعد دقيقة.',
      zero: 'حاول مرّة أخرى بعد قليل.',
    );
    return '$_temp0';
  }

  @override
  String get dayToday => 'اليوم';

  @override
  String get dayPrevious => 'اليوم السابق';

  @override
  String get dayNext => 'اليوم التالي';

  @override
  String get daySearch => 'بحث';

  @override
  String get daySettings => 'الإعدادات';

  @override
  String get dayChooseDate => 'اختر تاريخًا آخر.';

  @override
  String get dayEmptyToday => 'هل هناك شيء تودّ الاحتفاظ به؟';

  @override
  String get dayEmptyPast => 'لا شيء في هذا اليوم.';

  @override
  String get dayWriteSomething => 'اكتب شيئًا لليوم';

  @override
  String get dayLineAsk => 'كيف كان هذا اليوم؟';

  @override
  String get dayLineHint => 'كيف كان هذا اليوم؟';

  @override
  String get dayLineSemantic => 'قل في سطر واحد كيف كان هذا اليوم';

  @override
  String dayLineChange(String note) {
    return 'هذا اليوم: $note. غيّره.';
  }

  @override
  String get dayEndOfDay => 'نهاية اليوم';

  @override
  String get dayStartOfDay => 'بداية اليوم';

  @override
  String get firstPageTitle => 'هذا فارغ لأنك لم تكتب فيه بعد.';

  @override
  String get firstPageShelves =>
      'الأيام هي الرفوف. كل ما تحتفظ به يستقرّ في اليوم الذي حدث فيه، ويبقى هناك.';

  @override
  String get firstPageWayWrite => 'المس هذه الصفحة لتكتب.';

  @override
  String get firstPageWayVoice => 'اضغط مطوّلاً على الميكروفون لتقولها بصوتك.';

  @override
  String get firstPageWayAttach => 'أضف صورة أو مقطعًا أو مستندًا.';

  @override
  String get firstPagePromise => 'لا شيء من هذا يغادر هذا الهاتف.';

  @override
  String get firstPageSemantic => 'اكتب أول شيء في دفترك';

  @override
  String get captureVoice => 'سجّل ملاحظة صوتية';

  @override
  String get capturePhoto => 'التقط صورة أو اخترها';

  @override
  String get captureFile => 'أرفق ملفًا';

  @override
  String get backupNeverMade =>
      'لا توجد نسخة احتياطية لأيّ من هذا. إذا أُزيل هذا التطبيق، ذهبت ملاحظاتك معه.';

  @override
  String get backupStale => 'مضى وقت على آخر نسخة احتياطية.';

  @override
  String get backupOutOfDate => 'نسختك الاحتياطية ما زالت تُفتح برمزك القديم.';

  @override
  String get backupAction => 'نسخة احتياطية';

  @override
  String folderAlsoIn(String name) {
    return 'وأيضًا في $name. افتح المجلد.';
  }

  @override
  String get folderStaysHere => 'يبقى مكانه. المجلد مكان ثانٍ تجده فيه.';

  @override
  String get folderAddTo => 'أضف إلى مجلد';

  @override
  String get folderNew => 'مجلد جديد';

  @override
  String get folderNoneYet =>
      'لا مجلدات بعد. واحد لكل شخص، أو لكل مرحلة — ما تعود إليه دائمًا.';

  @override
  String folderLesson(String day, String folder) {
    return 'ما زال في $day. وأيضًا في $folder.';
  }

  @override
  String get actionDone => 'تمّ';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionDelete => 'حذف';

  @override
  String get actionSave => 'حفظ';

  @override
  String get actionEdit => 'تعديل';

  @override
  String get actionUndo => 'تراجع';

  @override
  String get actionOpen => 'فتح';

  @override
  String get actionRemove => 'إزالة';

  @override
  String get actionNotNow => 'ليس الآن';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsSecurity => 'القفل والأمان';

  @override
  String get settingsYourNotes => 'ملاحظاتك';

  @override
  String get settingsBackup => 'النسخ الاحتياطي';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageNote =>
      'الكلمات التي يستخدمها التطبيق. ما تكتبه أنت لك، بأيّ لغة، مهما كان هذا الإعداد.';

  @override
  String get settingsLanguageSystem => 'اتّبع الهاتف';

  @override
  String get entryMattered => 'هذا كان مهمًّا';

  @override
  String get entryMarked => 'وُضعت علامة على أنها كانت مهمة.';

  @override
  String get entryMarkRemoved => 'أُزيلت العلامة.';

  @override
  String get entryDeleted => 'تم الحذف.';

  @override
  String entryEarlierVersions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نسخة سابقة',
      many: '$count نسخة سابقة',
      few: '$count نسخ سابقة',
      two: 'نسختان سابقتان',
      one: 'نسخة سابقة واحدة',
      zero: 'لا نسخ سابقة',
    );
    return '$_temp0';
  }

  @override
  String get entryKeepsWords => 'تبقى الكلمات';

  @override
  String entryKindInTrash(Object kind) {
    return '$kind في المهملات.';
  }

  @override
  String entryKindInTrashWords(Object kind) {
    return '$kind في المهملات. الكلمات ما زالت هنا.';
  }

  @override
  String trashConfirmBody(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مدخل وكل نسخها السابقة. لا يمكن التراجع عن هذا.',
      many: '$count مدخلًا وكل نسخها السابقة. لا يمكن التراجع عن هذا.',
      few: '$count مدخلات وكل نسخها السابقة. لا يمكن التراجع عن هذا.',
      two: 'مدخلان وكل نسخهما السابقة. لا يمكن التراجع عن هذا.',
      one: 'مدخل واحد وكل نسخه السابقة. لا يمكن التراجع عن هذا.',
      zero: 'لا شيء لحذفه.',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyEntry => 'مدخل فارغ';

  @override
  String get kindPhoto => 'صورة';

  @override
  String get kindVideo => 'فيديو';

  @override
  String get kindRecording => 'تسجيل';

  @override
  String get kindFile => 'ملف';

  @override
  String get entryNoLongerMarked => 'لم يعد معلَّمًا';

  @override
  String get entryFindAgain => 'جده مرّة أخرى من شاشة البحث';

  @override
  String get searchGoTo => 'اذهب إلى';

  @override
  String get searchFolders => 'المجلدات';

  @override
  String get searchEntriesOne => 'مدخل واحد';

  @override
  String searchEntriesMany(int count) {
    return '$count مدخلات';
  }

  @override
  String get searchNothingFound => 'لا شيء يطابق ذلك.';

  @override
  String get searchEverythingInstead => 'ابحث في كل شيء بدلاً من ذلك';

  @override
  String get searchNoneOfThese => 'لا يوجد شيء من هذا النوع بعد.';

  @override
  String get onboardNoAccount => 'لا يوجد حساب.';

  @override
  String get onboardPromiseBody =>
      'ملاحظاتك تبقى على هذا الهاتف.\nليس لدينا خادم. لا يمكننا قراءتها.\nولا يمكننا استعادتها أيضًا.';

  @override
  String get onboardBegin => 'ابدأ';

  @override
  String get onboardHaveBackup => 'لديّ نسخة احتياطية';

  @override
  String get onboardSetPasscode => 'عيّن رمز دخول';

  @override
  String get onboardPasscodeBody =>
      'هذا هو الشيء الوحيد الذي يفتح ملاحظاتك. عبارة تستطيع تذكّرها أقوى من أربعة أرقام.';

  @override
  String get onboardPasscodeLabel => 'رمز الدخول';

  @override
  String get onboardPasscodeAgain => 'اكتبه مرة أخرى';

  @override
  String get onboardSettingUp => 'جارٍ الإعداد…';

  @override
  String get onboardContinue => 'متابعة';

  @override
  String get onboardPasscodesDiffer => 'هذان لا يتطابقان.';

  @override
  String get onboardVaultFailed => 'تعذّر إنشاء خزنتك.';

  @override
  String get onboardVaultFailedThen => 'لم يُحفظ شيء. حاول مرة أخرى.';

  @override
  String get onboardWriteWords => 'اكتب هذه الكلمات الاثنتي عشرة\nعلى ورق';

  @override
  String get onboardWordsBody =>
      'ليست لدينا نسخة منها. لا يمكننا إرسالها إليك. ولا يوجد بريد دعم يستطيع مساعدتك.\n\nعلى ورق، لا لقطة شاشة. اللقطة تبقى في معرض صورك، وهو أول مكان ينظر فيه أي أحد.';

  @override
  String get onboardWrittenDown => 'كتبتُها';

  @override
  String get onboardCopyWords => 'انسخ الكلمات الاثنتي عشرة';

  @override
  String get onboardClipboardNote =>
      'الحافظة تُمسح نفسها بعد دقيقة. حتى ذلك الحين يمكن لتطبيقات أخرى قراءتها.';

  @override
  String get onboardCopied =>
      'تمّ النسخ. ستُمسح نفسها بعد دقيقة — الصقها الآن في مكان آمن.';

  @override
  String get onboardCopyFailed =>
      'تعذّر النسخ. كتابتها بخط اليد أكثر أمانًا على أي حال.';

  @override
  String get onboardCheckThree => 'تحقّق من ثلاث منها';

  @override
  String get onboardCheckBody => 'حتى نعرف أن الورق صحيح، لا الشاشة.';

  @override
  String onboardWordNumber(int number) {
    return 'الكلمة $number';
  }

  @override
  String onboardWordWrong(int number) {
    return 'الكلمة $number غير صحيحة. انظر إلى ما كتبته.';
  }

  @override
  String get onboardShowWords => 'أرني الكلمات مرة أخرى';

  @override
  String get onboardFingerprintTitle => 'هل تفتحها ببصمتك؟';

  @override
  String get onboardFingerprintBody =>
      'حتى لا تضطر إلى كتابة تلك العبارة في كل مرة.';

  @override
  String get onboardFingerprintExplain =>
      'عبارتك تبقى هي المفتاح. البصمة تفتح هذه الخزنة فقط، وعلى هذا الهاتف فقط، ويوقفها نظام Android من تلقاء نفسه إذا تغيّرت بصمات الهاتف — حتى لا يستطيع أحد إضافة بصمته والدخول. وهي ليست أبدًا جزءًا من نسخة احتياطية.';

  @override
  String get onboardFingerprintWaiting => 'في انتظار إصبعك…';

  @override
  String get onboardFingerprintUse => 'استخدم بصمتي';

  @override
  String get onboardFingerprintFailed => 'لم ينجح ذلك.';

  @override
  String get onboardOneLastThing => 'شيء أخير';

  @override
  String get onboardNameBody =>
      'بماذا يناديك Lamplight؟ يبقى على هذا الهاتف، ويمكنك تغييره أو تركه فارغًا.';

  @override
  String get onboardFingerprintOn => 'بصمتك ستفتح Lamplight من الآن فصاعدًا.';

  @override
  String get onboardYourName => 'اسمك';

  @override
  String get onboardStartWriting => 'ابدأ الكتابة';

  @override
  String get onboardSkip => 'تخطٍ';

  @override
  String get settingsGroupLook => 'كيف يبدو وبأي لغة يتكلم';

  @override
  String get settingsGroupWhoCanOpen => 'من يستطيع فتحه';

  @override
  String get settingsGroupKeeping => 'الاحتفاظ به، ونقله';

  @override
  String get settingsAppearanceNote => 'السمة، الخط، اللون، الصفحة';

  @override
  String get settingsFolders => 'المجلدات';

  @override
  String get settingsFoldersNote => 'أشخاص، أماكن، مراحل';

  @override
  String get settingsMedia => 'الوسائط';

  @override
  String get settingsMediaNote => 'الصور والفيديو والصوت والمستندات';

  @override
  String get mediaGroupDocuments => 'المستندات';

  @override
  String get mediaDocumentsKept => 'تُحفَظ تمامًا كما وصلت';

  @override
  String get mediaDocumentsFooter =>
      'ملف PDF أو Word مضغوط من الداخل أصلًا، فضغطه مرة أخرى يوفّر نحو خمسة بالمئة. وأي فرق حقيقي يعني إعادة ترميز الصور بداخله، وهذا يطمس الخط الصغير في المستند الممسوح ضوئيًا إلى الأبد — ولن تكتشف ذلك إلا بعد سنوات، يوم تحتاج إلى قراءته.';

  @override
  String get settingsTrash => 'سلة المحذوفات';

  @override
  String get settingsTrashNote => 'المدوّنات المحذوفة، تُحفظ 30 يومًا';

  @override
  String get settingsReadableCopy => 'نسخة قابلة للقراءة';

  @override
  String get settingsReadableCopyNote => 'Markdown وملفاتك، في مجلد تختاره';

  @override
  String get settingsBringIn => 'أحضر دفترًا قديمًا';

  @override
  String get settingsBringInNote =>
      'ملفات نصية من تطبيق آخر، مرتّبة حسب تاريخها';

  @override
  String get settingsKeepingFooter =>
      'النسخة الاحتياطية مقفلة برمز الدخول، تمامًا كالخزنة. أما النسخة القابلة للقراءة فليست مقفلة إطلاقًا — إنها ملفات عادية في مجلد تختاره أنت.';

  @override
  String get backupNever => 'لا توجد نسخة احتياطية بعد';

  @override
  String get backupToday => 'نُسخت اليوم';

  @override
  String get backupYesterday => 'نُسخت أمس';

  @override
  String backupDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نُسخت قبل $count يوم',
      many: 'نُسخت قبل $count يومًا',
      few: 'نُسخت قبل $count أيام',
      two: 'نُسخت قبل يومين',
      one: 'نُسخت أمس',
      zero: 'نُسخت اليوم',
    );
    return '$_temp0';
  }

  @override
  String get mediaGroupIncoming => 'عند الدخول';

  @override
  String get mediaGroupVoice => 'الملاحظات الصوتية';

  @override
  String get mediaIncomingFooter =>
      'لا يحتفظ Lamplight أبدًا بنسخة ثانية أصغر — ما تختاره هنا هو ما يُحفظ، والأصل لا يبقى في أي مكان آخر.';

  @override
  String get mediaVoiceFooter =>
      'الكتابة تحدث على هذا الهاتف، بمحرك التعرّف الموجود في Android أصلًا. لا شيء مما تقوله في Lamplight يُرسل إلى أي جهة، والتطبيق لا يملك إذنًا لإرساله.';

  @override
  String get mediaPhotoSize => 'حجم الصور';

  @override
  String get mediaVideoSize => 'حجم الفيديو';

  @override
  String get mediaAskEachTime => 'اسأل في كل مرة';

  @override
  String get accentAmber => 'كهرماني';

  @override
  String get accentAmberNote => 'مصباح في الليل. المعتاد.';

  @override
  String get accentRose => 'وردي';

  @override
  String get accentRoseNote => 'وردي دافئ. أنعم من الكهرماني.';

  @override
  String get accentSage => 'مريمية';

  @override
  String get accentSageNote => 'أخضر هادئ. أهدأ الستة.';

  @override
  String get accentSlate => 'إردوازي';

  @override
  String get accentSlateNote => 'رمادي مزرقّ بارد. الأكثر حيادًا.';

  @override
  String get accentPlum => 'برقوقي';

  @override
  String get accentPlumNote => 'بنفسجي غامق.';

  @override
  String get accentEmber => 'جمري';

  @override
  String get accentEmberNote => 'برتقالي محروق. الأدفأ.';

  @override
  String get surfacePlain => 'سادة';

  @override
  String get surfacePlainNote => 'صفحة ملساء.';

  @override
  String get surfacePaper => 'ورق';

  @override
  String get surfacePaperNote =>
      'حبيبات خفيفة، حتى تبدو الصفحة مادةً لا فراغًا. المعتاد.';

  @override
  String get surfaceLamplit => 'تحت المصباح';

  @override
  String get surfaceLamplitNote => 'ورق، والمصباح مضاء.';

  @override
  String get surfaceStarMap => 'خريطة النجوم';

  @override
  String get surfaceStarMapNote =>
      'سماء واحدة تدور مع الساعة. لا تتكرر مرتين في يوم.';

  @override
  String get rulingNone => 'لا شيء';

  @override
  String get rulingNoneNote => 'لا شيء مطبوع على الصفحة.';

  @override
  String get rulingLines => 'سطور';

  @override
  String get rulingLinesNote => 'مسطّرة كدفتر.';

  @override
  String get rulingIsometric => 'متساوي القياس';

  @override
  String get rulingIsometricNote => 'ورق رسم هندسي، للتفكير في ثلاثة أبعاد.';

  @override
  String get rulingTriangle => 'مثلثات';

  @override
  String get rulingTriangleNote => 'حقل من مثلثات متساوية الأضلاع.';

  @override
  String get rulingDots => 'شبكة نقاط';

  @override
  String get rulingDotsNote => 'نقطة عند كل تقاطع. أهدأ الأربعة.';

  @override
  String get faceSystem => 'خط النظام';

  @override
  String get faceSystemNote => 'ما يستخدمه بقية هاتفك.';

  @override
  String get faceSerif => 'خط النظام المذيّل';

  @override
  String get faceSerifNote => 'الخط المذيّل الخاص بهاتفك.';

  @override
  String get faceCalmNote => 'حواف ناعمة، حروف عريضة.';

  @override
  String get faceModernNote => 'مضموم ومعاصر.';

  @override
  String get faceOldStyleNote => 'خط كتب من القرن السادس عشر.';

  @override
  String get facePlayfulNote => 'مستدير ومرح.';

  @override
  String get faceChildlikeNote => 'دفتر مدرسة.';

  @override
  String get faceHandwrittenNote => 'خط يد، ويظل مقروءًا على صفحة كاملة.';

  @override
  String get faceMedievalNote => 'يد ناسخ. سماكة واحدة فقط.';

  @override
  String get faceMonoNote => 'كل حرف بالعرض نفسه.';

  @override
  String get qualityOriginal => 'احتفظ بالأصل';

  @override
  String get qualityBalanced => 'متوازن';

  @override
  String get qualitySmaller => 'أصغر';

  @override
  String get photoOriginalNote =>
      'محفوظة تمامًا كما التقطتها الكاميرا. أكبر الملفات — وتحتفظ أيضًا بمكان التقاط الصورة، وهو ما يزيله Lamplight عادةً.';

  @override
  String get photoBalancedNote =>
      'أصغر بكثير، ويصعب تمييزها عن الأصل. المعتاد.';

  @override
  String get photoSmallerNote =>
      'النصف مرة أخرى. قد تلاحظ ذلك إذا قصصت الصورة عن قرب.';

  @override
  String get videoOriginalNote =>
      'محفوظ تمامًا كما سجّلته الكاميرا. أكبر الملفات بفارق كبير.';

  @override
  String get videoBalancedNote => 'أصغر بكثير، ويصعب تمييزه عن الأصل. المعتاد.';

  @override
  String get videoSmallerNote => 'النصف مرة أخرى. قد تلاحظ ذلك على شاشة كبيرة.';

  @override
  String get appearanceTitle => 'المظهر';

  @override
  String get appearanceTheme => 'السمة';

  @override
  String get appearanceThemeDark => 'داكن';

  @override
  String get appearanceThemeLight => 'فاتح';

  @override
  String get appearanceThemeAuto => 'تلقائي';

  @override
  String get appearanceThemeAutoNote => 'يتبع إعداد الفاتح والداكن في هاتفك.';

  @override
  String get appearanceFont => 'الخط';

  @override
  String get appearanceSize => 'الحجم';

  @override
  String get appearanceColour => 'اللون';

  @override
  String get appearancePage => 'الصفحة';

  @override
  String get appearanceRuling => 'التسطير';

  @override
  String get daySavedToToday => 'حُفظ في يوم اليوم.';

  @override
  String get dayAddedToToday => 'أُضيف إلى يوم اليوم.';

  @override
  String get entryEditWords => 'تعديل الكلمات';

  @override
  String get entryDeleteBlock => 'حذف الكتلة كاملة';

  @override
  String entrySavedAs(String name) {
    return 'حُفظ باسم $name.';
  }

  @override
  String entryAddedToFolder(String name) {
    return 'وأيضًا في $name.';
  }

  @override
  String get entrySaveCopy => 'حفظ نسخة';

  @override
  String get entrySaveCopyNote => 'في مكان تختاره، خارج Lamplight';

  @override
  String get capturePhotoTake => 'التقاط صورة';

  @override
  String get capturePhotoChoose => 'الاختيار من صورك';

  @override
  String get composerHintToday => 'اكتب عن اليوم…';

  @override
  String get composerHintPast => 'اكتب عن هذا اليوم…';

  @override
  String get composerNewBlock => 'كتلة جديدة';

  @override
  String get voiceShowTranscript => 'إظهار ما قيل';

  @override
  String get voiceHideTranscript => 'إخفاء ما قيل';

  @override
  String get voiceTranscriptTitle => 'ما قيل';

  @override
  String get entryEdited => '، مُعدّل';

  @override
  String photoSemantic(String time) {
    return 'صورة عند $time. انقر مرتين لعرضها.';
  }

  @override
  String get sizeThisPhoto => 'هذه الصورة';

  @override
  String get sizeThesePhotos => 'هذه الصور';

  @override
  String get sizeThisVideo => 'هذا الفيديو';

  @override
  String get sizeTheseVideos => 'هذه الفيديوهات';

  @override
  String sizeQuestion(String what) {
    return 'بأي حجم تريد حفظ $what؟';
  }

  @override
  String get trashNote => 'المحذوف يبقى هنا 30 يومًا، ثم يذهب نهائيًا.';

  @override
  String get trashConfirm => 'حذف هذه نهائيًا؟';

  @override
  String get trashKeep => 'الاحتفاظ بها';

  @override
  String get trashDeleteForGood => 'احذف نهائيًا';

  @override
  String get trashPutBack => 'أعِدها';

  @override
  String trashPutBackOn(String day) {
    return 'أُعيدت إلى $day.';
  }

  @override
  String get trashEmpty => 'إفراغ سلة المحذوفات';

  @override
  String get folderMakeFirst => 'أنشئ المجلد الأول';

  @override
  String folderDeleteAsk(String name) {
    return 'حذف «$name»؟';
  }

  @override
  String get folderKeepIt => 'احتفظ به';

  @override
  String get folderDeleteIt => 'احذف المجلد';

  @override
  String get folderRename => 'إعادة تسمية';

  @override
  String get folderDeleteThis => 'احذف هذا المجلد';

  @override
  String folderTakenOut(String name) {
    return 'أُخرج من $name. وما زال في يومه.';
  }

  @override
  String get searchHint => 'كلمات، تاريخ، اسم…';

  @override
  String get searchBack => 'رجوع';

  @override
  String get searchClear => 'مسح';

  @override
  String searchNothingMatches(String query) {
    return 'لا شيء يطابق «$query».';
  }

  @override
  String get searchWhatMattered => 'ما كان له معنى';

  @override
  String get searchADate => 'تاريخ';

  @override
  String get searchDateExample => '16 مارس 2006 · مارس 2006 · أمس';

  @override
  String get searchWhatYouCanType => 'ما الذي يمكنك البحث عنه';

  @override
  String get searchTryDate => 'أمس';

  @override
  String get searchSaidOutLoud => 'قيل بصوت مسموع';

  @override
  String get searchAPhotograph => 'صورة';

  @override
  String get searchAVideo => 'فيديو';

  @override
  String get securityWhileOpen => 'ما دام التطبيق مفتوحًا';

  @override
  String get securityLockFooter =>
      'يُقفل Lamplight دائمًا لحظة انتقاله إلى الخلفية. هذا يقرر فقط كم ينتظر وأنت ما زلت بداخله.';

  @override
  String get securityLockAfter => 'القفل بعد';

  @override
  String get securityOneHour => 'ساعة واحدة';

  @override
  String get securityYourPasscode => 'رمز الدخول';

  @override
  String get securityPasscodeFooter =>
      'رمز الدخول هو المفتاح. لا يُحفظ في أي مكان — لا على هذا الهاتف ولا في غيره — فلا يمكن إجبار أحد على تسليمه، ولا يستطيع أحد استعادته لك.';

  @override
  String get securityChangePasscode => 'تغيير رمز الدخول';

  @override
  String get securityScreenshots => 'لقطات الشاشة';

  @override
  String get securityScreenshotsFooter =>
      'يمنع Lamplight تصوير الشاشة حتى لا يستطيع من يلتقط هاتفك تصوير ملاحظاتك، وحتى لا تظهر أبدًا في معاينة التطبيقات الأخيرة. ويمكنك إيقاف ذلك على هاتفك أنت.';

  @override
  String get securityAllowScreenshots => 'السماح بلقطات الشاشة';

  @override
  String get securityScreenshotsOn => 'ستظهر ملاحظاتك في التطبيقات الأخيرة';

  @override
  String get securityScreenshotsOff => 'تعرض التطبيقات الأخيرة صفحة فارغة';

  @override
  String get securityCouldNotChange => 'تعذّر تغيير ذلك.';

  @override
  String get securityNothingChanged => 'لم يتغيّر أي شيء في قفلك.';

  @override
  String get securityPromptAutomatic => 'يظهر الطلب من تلقاء نفسه';

  @override
  String get securityPromptOnTap => 'اضغط على البصمة عندما تريدها';

  @override
  String get mediaAskEachTimeOn =>
      'يُسأل عن حجم الصور ومقاطع الفيديو عند إضافتها.';

  @override
  String get mediaAskEachTimeOff => 'مُعطَّل. يُستخدم الحجمان أعلاه دون سؤال.';

  @override
  String get passcodeNew => 'رمز جديد';

  @override
  String get securityFingerprint => 'البصمة';

  @override
  String get securityFingerprintFooter =>
      'عبارتك تبقى هي المفتاح. البصمة تفتح هذه الخزنة فقط، وعلى هذا الهاتف فقط، ويوقفها نظام Android من تلقاء نفسه إذا تغيّرت بصمات الهاتف — حتى لا يستطيع أحد إضافة بصمته والدخول. وهي ليست أبدًا جزءًا من نسخة احتياطية.';

  @override
  String get securityUnlockWithFingerprint => 'افتح ببصمتي';

  @override
  String get securityAskOnOpen => 'اسأل فور فتح Lamplight';

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ثانية',
      many: '$count ثانية',
      few: '$count ثوانٍ',
      two: 'ثانيتان',
      one: 'ثانية واحدة',
      zero: '0 ثانية',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دقيقة',
      many: '$count دقيقة',
      few: '$count دقائق',
      two: 'دقيقتان',
      one: 'دقيقة واحدة',
      zero: '0 دقيقة',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعة',
      many: '$count ساعة',
      few: '$count ساعات',
      two: 'ساعتان',
      one: 'ساعة واحدة',
      zero: '0 ساعة',
    );
    return '$_temp0';
  }

  @override
  String get durationNever => 'أبدًا';

  @override
  String get securityDefaultNote => 'المعتاد.';

  @override
  String get securityHourNote => 'لأصيل تقرأ فيه ما مضى.';

  @override
  String get securityNeverNote => 'ومع ذلك يُقفل فور خروجك من التطبيق.';

  @override
  String get calendarGoToDate => 'اذهب إلى تاريخ';

  @override
  String get dayHasWriting => 'كتابة';

  @override
  String get dayHasPhoto => 'صورة';

  @override
  String get dayHasVideo => 'فيديو';

  @override
  String get dayHasVoice => 'ملاحظة صوتية';

  @override
  String get dayHasFile => 'ملف';

  @override
  String dayEntriesAndKinds(Object count, Object kinds) {
    return '$count، $kinds';
  }

  @override
  String get listSeparator => '، ';

  @override
  String listAnd(Object last, Object most) {
    return '$most و$last';
  }

  @override
  String get integrityNothingUnusual =>
      'لا شيء غير معتاد في هذا الهاتف. يعمل Lamplight كما ينبغي.';

  @override
  String get calendarPreviousYear => 'السنة السابقة';

  @override
  String get calendarPreviousMonth => 'الشهر السابق';

  @override
  String get calendarNextYear => 'السنة التالية';

  @override
  String get calendarNextMonth => 'الشهر التالي';

  @override
  String get calendarBackToMonth => 'العودة إلى الشهر';

  @override
  String get calendarWholeYear => 'السنة كاملة';

  @override
  String get calendarBackToThisMonth => 'العودة إلى هذا الشهر';

  @override
  String get calendarNothingThisYear => 'لا شيء في هذه السنة بعد.';

  @override
  String calendarYearSummary(Object days, Object entries) {
    return '$entries في $days.';
  }

  @override
  String get folderNothingInIt => 'لا شيء فيه بعد';

  @override
  String get onThisDayOneYear => 'مثل هذا اليوم قبل سنة';

  @override
  String onThisDayYears(Object years) {
    return 'مثل هذا اليوم قبل $years سنوات';
  }

  @override
  String wheelYear(Object year) {
    return 'سنة $year';
  }

  @override
  String get calendarBackToBrowsing => 'العودة إلى التصفح';

  @override
  String get calendarToday => 'اليوم';

  @override
  String get calendarFirstEntry => 'أول ما كتبت';

  @override
  String get calendarGoToThisDay => 'اذهب إلى هذا اليوم';

  @override
  String get calendarDensityNote =>
      'اللون يبيّن كم في اليوم، من لا شيء إلى الكثير.';

  @override
  String get calendarLess => 'أقل';

  @override
  String get calendarMore => 'أكثر';

  @override
  String get calendarGoToToday => 'اذهب إلى اليوم';

  @override
  String get backupTitle => 'نسخة احتياطية';

  @override
  String get vaultNothingToBackUp => 'لا يوجد في هذه الخزنة ما يمكن نسخه بعد.';

  @override
  String vaultChangedWhileBackingUp(Object name) {
    return 'تغيّر شيء أثناء إنشاء النسخة ($name). أعد المحاولة.';
  }

  @override
  String get vaultTooSmall =>
      'هذا الملف أصغر من أن يكون نسخة احتياطية من Lamplight.';

  @override
  String get vaultNotALamplightFile =>
      'هذا ليس ملف نسخة احتياطية من Lamplight.';

  @override
  String get vaultDamaged => 'هذا الملف تالف ولا يمكن فتحه.';

  @override
  String get vaultKeyringNewerVersion =>
      'أُنشئت هذه الخزنة بإصدار أحدث من Lamplight. حدّث التطبيق لفتحها.';

  @override
  String get vaultKeyringDamaged =>
      'ملف مفتاح الخزنة تالف ولا يمكن قراءته. إن كان لديك ملف نسخة احتياطية، فاستعد منه.';

  @override
  String get vaultDatabaseNewerVersion =>
      'أُنشئت هذه الخزنة بإصدار أحدث من Lamplight. حدّث التطبيق لفتحها — ملاحظاتك سليمة ولم يتغيّر شيء.';

  @override
  String phraseWrongLength(Object count) {
    return 'عبارة الاسترجاع تتكوّن من 12 كلمة. هذه فيها $count.';
  }

  @override
  String phraseNotARecoveryWord(Object word) {
    return '«$word» ليست من كلمات الاسترجاع.';
  }

  @override
  String get phraseDoesNotCheckOut =>
      'هذه الكلمات ليست عبارة استرجاع صحيحة. تحقّق من كلمة مكتوبة خطأً أو مبدَّلة.';

  @override
  String get vaultNewerVersion =>
      'أُنشئت هذه النسخة بإصدار أحدث من Lamplight. حدّث التطبيق ثم أعد المحاولة.';

  @override
  String get vaultUnknownCompression =>
      'تستخدم هذه النسخة ضغطًا لا يعرف هذا الإصدار قراءته.';

  @override
  String get vaultDamagedTryOlder =>
      'هذا الملف تالف ولا يمكن فتحه. إن كانت لديك نسخة أقدم، فجرّبها.';

  @override
  String get vaultBeforeRecoveryPhrases =>
      'أُنشئت هذه النسخة قبل أن تتمكّن كلمات الاسترجاع من فتح ملفات النسخ. رمزها هو الطريق الوحيد للدخول.';

  @override
  String get vaultWordsDoNotOpenIt =>
      'هذه الكلمات لا تفتح هذا الملف. ربما تخصّ خزنة أخرى.';

  @override
  String get vaultWrongPasscode => 'هذا الرمز لا يفتح هذا الملف.';

  @override
  String vaultMissingPart(Object name) {
    return 'تنقص هذه النسخة جزءًا منها ($name).';
  }

  @override
  String vaultPartWrongSize(Object name) {
    return 'هذه النسخة تالفة (حجم $name غير صحيح).';
  }

  @override
  String vaultPartDoesNotMatch(Object name) {
    return 'هذه النسخة تالفة ($name غير مطابق).';
  }

  @override
  String get vaultNoVaultInside =>
      'لا تحتوي هذه النسخة على خزنة. ربما أنشأها تطبيق آخر.';

  @override
  String get vaultOutOfOrder => 'هذا الملف تالف: محتوياته خارج ترتيبها.';

  @override
  String get vaultEndsPartWay => 'هذا الملف تالف: ينتهي في منتصفه.';

  @override
  String vaultIncomplete(Object parts) {
    return 'هذا الملف غير مكتمل — يحتوي على $parts من أجزائه.';
  }

  @override
  String vaultWillNotOpen(Object name) {
    return 'تحتوي هذه النسخة على شيء لن يفتحه Lamplight ($name).';
  }

  @override
  String countEntries(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مدخل',
      many: '$count مدخلًا',
      few: '$count مدخلات',
      two: 'مدخلان',
      one: 'مدخل واحد',
      zero: 'لا مدخلات',
    );
    return '$_temp0';
  }

  @override
  String countDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: 'لا أيام',
    );
    return '$_temp0';
  }

  @override
  String get backupCheckingItOpens => 'يجري التأكد من أنها تُفتح…';

  @override
  String get backupCouldNotSave => 'تعذّر حفظ النسخة الاحتياطية.';

  @override
  String get backupNothingLost =>
      'لم يُفقد شيء، وملاحظاتك كما هي. أعد المحاولة بعد قليل.';

  @override
  String get backupLast => 'آخر نسخة احتياطية';

  @override
  String get backupInTheVault => 'في الخزنة';

  @override
  String get restoreCheckingFile => 'يجري فحص الملف…';

  @override
  String get restoreCouldNotOpen => 'تعذّر فتح هذا الملف.';

  @override
  String get restoreCheckItIsTheOne =>
      'تأكّد أنها النسخة التي تقصدها، ثم أعد المحاولة.';

  @override
  String get restorePuttingInPlace => 'يجري وضعها في مكانها…';

  @override
  String get restorePuttingBack => 'يجري إرجاع ملاحظاتك السابقة…';

  @override
  String get restoreCouldNotFinish => 'تعذّر إتمام الاستعادة.';

  @override
  String get restoreBackAsTheyWere => 'عادت ملاحظاتك كما كانت.';

  @override
  String get restoreUsePasscodeInstead => 'استخدم الرمز بدلًا من ذلك';

  @override
  String get restoreUseWordsInstead => 'لديّ الكلمات الاثنتا عشرة بدلًا من ذلك';

  @override
  String get backupCreateFile => 'أنشئ ملف النسخة';

  @override
  String get backupCreatedChecked => 'أُنشئت النسخة وجرى التحقق منها.';

  @override
  String get backupMakeAnother => 'أنشئ أخرى';

  @override
  String get backupRestoreHeading => 'استعادة';

  @override
  String get backupRestoreFrom => 'استعادة من ملف نسخة احتياطية';

  @override
  String backupProgress(String stage, int percent) {
    return '$stage $percent بالمئة';
  }

  @override
  String get restoreTitle => 'استعادة';

  @override
  String get restoreChooseFile => 'اختر ملفًا';

  @override
  String get restoreUseLatest => 'استخدام أحدث نسخة احتياطية';

  @override
  String get restorePhraseHint => 'تذكّر حكاية صناعة…';

  @override
  String get restoreAction => 'استعادة';

  @override
  String get restoreChooseDifferent => 'اختر ملفًا آخر';

  @override
  String get importChooseFolder => 'اختر مجلدًا';

  @override
  String get importChooseFiles => 'اختر الملفات بدلاً من ذلك';

  @override
  String get importChooseFilesNote =>
      'إذا رفض أندرويد مجلدك — فهو لا يمنح أي تطبيق مجلد التنزيلات أو جذر التخزين — فاختر الملفات نفسها. وهذا لا يُرفض أبداً.';

  @override
  String get importLooking => 'يبحث في المجلد…';

  @override
  String get importNoTextFiles => 'لا توجد ملفات نصية في ذلك المجلد.';

  @override
  String get importChooseDifferentFolder => 'اختر مجلدًا آخر';

  @override
  String get importUseFileDate => 'استخدم تاريخ الملف نفسه';

  @override
  String get importUseFileDateNote =>
      'يضعها في اليوم الذي عُدّل فيه الملف آخر مرة. وغالبًا لا يكون ذلك اليوم الذي يتحدث عنه.';

  @override
  String importBringIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أحضر $count ملاحظة',
      many: 'أحضر $count ملاحظة',
      few: 'أحضر $count ملاحظات',
      two: 'أحضر ملاحظتين',
      one: 'أحضر ملاحظة واحدة',
      zero: 'لا شيء لإحضاره',
    );
    return '$_temp0';
  }

  @override
  String importProgress(int percent) {
    return 'جارٍ الإحضار، $percent بالمئة';
  }

  @override
  String get exportChooseFolder => 'اختر مجلدًا وصدّر';

  @override
  String get exportSave => 'حفظ نسخة قابلة للقراءة';

  @override
  String get exportWritten => 'كُتبت نسختك.';

  @override
  String get exportAgain => 'صدّر مرة أخرى';

  @override
  String get exportWhichOne => 'أيهما أريد؟';

  @override
  String get exportNotLocked => 'هذه النسخة ليست مقفلة';

  @override
  String dayAddedThings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُضيف $count شيء إلى يوم اليوم.',
      many: 'أُضيف $count شيئًا إلى يوم اليوم.',
      few: 'أُضيفت $count أشياء إلى يوم اليوم.',
      two: 'أُضيف شيئان إلى يوم اليوم.',
      one: 'أُضيف شيء واحد إلى يوم اليوم.',
      zero: 'لم يُضف شيء إلى اليوم.',
    );
    return '$_temp0';
  }

  @override
  String get entryAddNote => 'اكتب ملاحظة على هذا';

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُضيف $count.',
      many: 'أُضيف $count.',
      few: 'أُضيفت $count.',
      two: 'أُضيف اثنان.',
      one: 'تمت الإضافة.',
      zero: 'لم يُضف شيء.',
    );
    return '$_temp0';
  }

  @override
  String get importFolderUnreadable => 'تعذّرت قراءة هذا المجلد.';

  @override
  String get importNothingBrought => 'لم يُستورد أي شيء.';

  @override
  String get importStoppedPartWay => 'توقّف استيراد اليوميات في منتصف الطريق.';

  @override
  String get importWhatArrivedKept => 'حُفظ كل ما وصل قبل التوقّف.';

  @override
  String get importNoReadableDates =>
      'لا يحمل أي من تلك الملفات تاريخًا يستطيع Lamplight قراءته.';

  @override
  String importReadyToBring(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملاحظة جاهزة للاستيراد.',
      many: '$count ملاحظة جاهزة للاستيراد.',
      few: '$count ملاحظات جاهزة للاستيراد.',
      two: 'ملاحظتان جاهزتان للاستيراد.',
      one: 'ملاحظة واحدة جاهزة للاستيراد.',
      zero: 'لا ملاحظات جاهزة.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingNew => 'لا جديد لاستيراده.';

  @override
  String importBroughtIn(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'استُوردت $count ملاحظة.',
      many: 'استُوردت $count ملاحظة.',
      few: 'استُوردت $count ملاحظات.',
      two: 'استُوردت ملاحظتان.',
      one: 'استُوردت ملاحظة واحدة.',
      zero: 'لم تُستورد ملاحظات.',
    );
    return '$_temp0';
  }

  @override
  String importAlreadyHere(Object count) {
    return '$count كانت موجودة أصلًا، فتُركت كما هي.';
  }

  @override
  String importNoDateSkipped(Object count) {
    return '$count بلا تاريخ يمكن قراءته، فتُخطّيت.';
  }

  @override
  String importCouldNotRead(Object count, Object names) {
    return '$count تعذّرت قراءتها: $names';
  }

  @override
  String get exportStarting => 'يبدأ…';

  @override
  String get exportCouldNotFinish => 'تعذّر إتمام النسخة المقروءة.';

  @override
  String get exportNothingChanged => 'لم يتغيّر شيء داخل Lamplight.';

  @override
  String get importVideoAlreadySmall =>
      'أحد المقاطع كان صغيرًا بالفعل بقدر الإمكان، فحُفظ كما هو.';

  @override
  String get importVideoCouldNotShrink =>
      'تعذّر تصغير أحد المقاطع على هذا الهاتف، فحُفظ كاملًا.';

  @override
  String importOneFailed(String reason) {
    return 'واحد لم ينجح: $reason';
  }

  @override
  String importAbandoned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لم يكتمل قبل أن يُقفل Lamplight.',
      many: '$count لم يكتمل قبل أن يُقفل Lamplight.',
      few: '$count لم تكتمل قبل أن يُقفل Lamplight.',
      two: 'اثنان لم يكتملا قبل أن يُقفل Lamplight.',
      one: 'واحد لم يكتمل قبل أن يُقفل Lamplight.',
      zero: 'لم يتبقَّ شيء.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingLeft => 'لم يبقَ شيء على الهاتف.';

  @override
  String get nameCardAsk => 'ماذا يُكتب هنا؟';

  @override
  String get nameCardHint => 'اسمك، أو أي شيء';

  @override
  String get reminderGroup => 'تنبيه خفيف، إن أردت';

  @override
  String get reminderFooter =>
      'مُطفأ حتى تشغّله. لا يذكر أبدًا ما في ملاحظاتك — ولا يستطيع، لأنه يعمل والخزنة مقفلة. لا سلاسل، ولا إحصاء، ولا شيء عن الأيام التي فاتتك.';

  @override
  String get reminderTitle => 'ذكّرني بالكتابة';

  @override
  String get reminderWhen => 'متى';

  @override
  String get reminderProblemNotAllowed =>
      'لا يُسمح لـ Lamplight بإرسال الإشعارات.';

  @override
  String get reminderProblemNotificationsOff =>
      'إشعارات Lamplight موقفة في إعدادات هذا الهاتف.';

  @override
  String get reminderProblemRemindersOff =>
      'تنبيهات Lamplight موقفة في إعدادات الإشعارات بهذا الهاتف.';

  @override
  String get reminderProblemBatterySaving =>
      'يوفّر هذا الهاتف البطارية بتقييد Lamplight. وهذا السبب المعتاد لتأخر التنبيه أو عدم وصوله.';

  @override
  String get reminderMayNotArrive => 'قد لا يصل التنبيه';

  @override
  String get backupAutomatic => 'نسخ احتياطي تلقائي';

  @override
  String get backupAutomaticDidNotFinish =>
      'لم تكتمل النسخة الاحتياطية التلقائية.';

  @override
  String get backupNothingYet => 'لا شيء لنسخه بعد.';

  @override
  String get backupInProgress => 'يجري النسخ…';

  @override
  String get backupStartsAtUnlock => 'يبدأ عند فتحك للقفل في المرة القادمة.';

  @override
  String get backupDoneAutomatically => 'تم النسخ تلقائيًا.';

  @override
  String get backupLastOneFailed =>
      'لم تكتمل آخر نسخة احتياطية تلقائية. سيُعاد المحاولة في المرة القادمة التي تفتح فيها Lamplight.';

  @override
  String importNthOf(Object index, Object total) {
    return '$index من $total';
  }

  @override
  String importWaiting(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ينتظر',
      many: '$count تنتظر',
      few: '$count تنتظر',
      two: 'اثنان ينتظران',
      one: 'واحد ينتظر',
      zero: 'لا شيء ينتظر',
    );
    return '$_temp0';
  }

  @override
  String get aboutCopied => 'تم النسخ';

  @override
  String get failureGeneric => 'لم ينجح ذلك.';

  @override
  String get failureNothingLost => 'لم يُفقد شيء — أعد المحاولة.';

  @override
  String get calendarNothingOnDay => 'لا شيء';

  @override
  String get backupChangeFolder => 'تغيير المجلد';

  @override
  String backupSavedTo(String place) {
    return 'يُحفَظ في $place';
  }

  @override
  String get backupUseDefaultFolder => 'استخدم المجلد المعتاد';

  @override
  String get backupChooseFolder => 'اختر مجلدًا لحفظ النسخ فيه';

  @override
  String get folderAndroidRestriction =>
      'لا يسمح Android بمنح أي تطبيق مجلد التنزيلات أو مساحة التخزين الداخلية بأكملها. مجلد Documents، أو مجلد داخله، يعمل.';

  @override
  String get folderNotWritable =>
      'لا يمكن حفظ أي شيء في هذا المجلد. جرّب مجلدًا آخر.';

  @override
  String get folderRefused => 'تعذّر استخدام هذا المجلد.';

  @override
  String get folderTryAnother => 'جرّب اختيار مجلد آخر.';

  @override
  String get aboutHowKept => 'كيف تُحفظ ملاحظاتك';

  @override
  String get aboutFonts => 'الخطوط والتراخيص';

  @override
  String get aboutVersion => 'الإصدار';

  @override
  String get aboutNoBrowser => 'لا يوجد تطبيق على هذا الهاتف يفتح الروابط.';

  @override
  String get aboutMadeBy => 'صنعه';

  @override
  String get aboutMadeBySemantic =>
      'صنعه ProbablyPiyush. يفتح LinkedIn في متصفحك.';

  @override
  String get aboutCoffee => 'اشترِ لي قهوة';

  @override
  String get aboutCoffeeSemantic => 'اشترِ لي قهوة. يفتح صفحة في متصفحك.';

  @override
  String get aboutCopyDetails => 'انسخ التفاصيل';

  @override
  String settingsNameSemantic(Object name) {
    return '$name. اضغط للتغيير.';
  }

  @override
  String get settingsAddName => 'أضف اسمك';

  @override
  String get settingsNameOnlyHere => 'على هذا الهاتف فقط';

  @override
  String get settingsNameOptional => 'اختياري. لن يغادر هذا الهاتف أبدًا.';

  @override
  String get reminderTurnedOffByAndroid =>
      'أوقف Android الإشعارات لتطبيق Lamplight. يمكنك تشغيلها من إعدادات الهاتف، ضمن التطبيقات.';

  @override
  String get reminderOnceADay => 'مرة في اليوم';

  @override
  String reminderTodayAt(Object time) {
    return 'اليوم في $time';
  }

  @override
  String reminderYesterdayAt(Object time) {
    return 'أمس في $time';
  }

  @override
  String reminderOnDateAt(Object date, Object time) {
    return '$date في $time';
  }

  @override
  String get reminderNoneYet => 'لم يصل شيء بعد';

  @override
  String reminderLastArrived(Object when) {
    return 'وصل آخر واحد $when';
  }

  @override
  String reminderNextDue(Object when) {
    return 'التالي مُقرَّر $when';
  }

  @override
  String get aboutHide => 'إخفاء';

  @override
  String get aboutCheckReal => 'تحقّق من أن هذا هو Lamplight الحقيقي';

  @override
  String get entryRevisionsNote => 'ما كان مكتوبًا قبل أن تغيّره';

  @override
  String get entryStaysOnDay => 'ويبقى في يومه أيضًا';

  @override
  String entryDeleteKind(String kind) {
    return 'احذف $kind';
  }

  @override
  String get shareCouldNotAdd =>
      'تعذّرت إضافة ذلك. جرّب حفظه واستخدام زر الصورة.';

  @override
  String get openNothingCanOpen =>
      'لا شيء على هذا الهاتف يفتح هذا النوع من الملفات.';

  @override
  String get viewerMore => 'المزيد';

  @override
  String get docLeavesLamplight => 'هذا يغادر Lamplight';

  @override
  String get docKeepItHere => 'أبقِه هنا';

  @override
  String get docOpenWith => 'افتح باستخدام…';

  @override
  String docCannotShow(String kind) {
    return 'يستطيع Lamplight عرض ملفات PDF والصور والنصوص دون أن يضعها على هاتفك بلا تشفير أبدًا. ملف $kind يحتاج تطبيقًا آخر — ويمكن لـ Lamplight أن يعيره إياه ما دمت تقرأ، ثم يستعيده بعدها.';
  }

  @override
  String get menuOpenWithNote => 'تطبيق آخر، دون الاحتفاظ بنسخة';

  @override
  String menuSaveKind(String kind) {
    return 'احفظ $kind';
  }

  @override
  String get menuTrashNote => 'يُحفظ 30 يومًا ثم يزول';

  @override
  String get videoBackTen => 'عشر ثوانٍ للخلف';

  @override
  String get videoForwardTen => 'عشر ثوانٍ للأمام';

  @override
  String get photoPlayVideo => 'شغّل هذا الفيديو';

  @override
  String get lockPhraseHint => 'كلماتك الاثنتي عشرة، بمسافات بينها';

  @override
  String get lockUnlock => 'افتح';

  @override
  String get errorScreenDidNotOpen => 'تلك الشاشة لم تُفتح. لم يُفقد شيء.';

  @override
  String get errorGoBack => 'ارجع';

  @override
  String recordingCannot(String what) {
    return 'هذا الهاتف لن $what التسجيل. وما زال التسجيل جاريًا.';
  }

  @override
  String get recordingClose => 'إغلاق';

  @override
  String recordingElapsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يسجّل، $count ثانية',
      many: 'يسجّل، $count ثانية',
      few: 'يسجّل، $count ثوانٍ',
      two: 'يسجّل، ثانيتان',
      one: 'يسجّل، ثانية واحدة',
      zero: 'يسجّل',
    );
    return '$_temp0';
  }

  @override
  String get recordingStopKeep => 'أوقِف واحتفظ بهذا التسجيل';

  @override
  String get recordingDiscard => 'تجاهل';

  @override
  String get recordingCouldNotStart => 'تعذّر بدء التسجيل.';

  @override
  String get recordingCheckMicrophone =>
      'تحقّق من أن Lamplight مسموح له باستخدام الميكروفون.';

  @override
  String get recordingStartAgain => 'المتابعة';

  @override
  String get recordingCouldNotSave => 'تعذّر حفظ هذا التسجيل.';

  @override
  String get recordingStillHere => 'ما زال موجودًا — جرّب إيقافه مرة أخرى.';

  @override
  String get recordingCarryOnSemantic => 'متابعة التسجيل';

  @override
  String get recordingPauseSemantic => 'إيقاف هذا التسجيل مؤقتًا';

  @override
  String get recordingCarryOn => 'متابعة';

  @override
  String get recordingPause => 'إيقاف مؤقت';

  @override
  String get sizeAdd => 'إضافة';

  @override
  String get transcribeTitle => 'اكتب ما يُقال';

  @override
  String get transcribeOn =>
      'تصبح الملاحظات الصوتية قابلة للبحث. ولا يُرسل شيء إلى أي مكان.';

  @override
  String get transcribeOff =>
      'مُطفأ. لا يمكن العثور على الملاحظات الصوتية إلا بيومها.';

  @override
  String get transcribeLanguage => 'لغة الكلام';

  @override
  String get transcribeLanguageNote =>
      'اللغة التي تتحدث بها في تسجيلاتك. واحدة في كل مرة — الجملة التي تنتقل بين لغتين تعود بالنصف الذي يطابق هذه.';

  @override
  String get transcribeNotDownloaded =>
      'لم يُنزَّل بعد على هذا الهاتف — انقر لجلبه.';

  @override
  String transcribeGetBetter(String name) {
    return 'اجلب النموذج الأفضل لـ $name';
  }

  @override
  String get transcribeGetBetterNote =>
      'تصبح الكتابة أدقّ بوضوح معه. التنزيل من هاتفك، لا من Lamplight، ويحدث مرة واحدة.';

  @override
  String get transcribeNoLanguages => 'لم يعرض هذا الهاتف أي لغات بعد.';

  @override
  String get transcribeNeedsDownloading => 'يحتاج تنزيلًا';

  @override
  String folderStill(String day, String folder) {
    return 'ما زال في $day. وأيضًا في $folder.';
  }

  @override
  String get folderRenameTitle => 'إعادة تسمية المجلد';

  @override
  String get folderNameHint => 'شخص، مكان، مرحلة';

  @override
  String get voicePlay => 'استمع إلى هذه الملاحظة الصوتية';

  @override
  String get voiceForwardThirty => 'ثلاثون ثانية للأمام';

  @override
  String voiceSpeed(String speed) {
    return 'السرعة، الآن $speed أضعاف';
  }

  @override
  String get voiceLengthUnknown => 'ملاحظة صوتية، المدة غير معروفة حتى التشغيل';

  @override
  String get voicePosition => 'الموضع في التسجيل';

  @override
  String get voiceOpening => 'يفتح التسجيل';

  @override
  String get voiceNoWords => 'لم تعد أي كلمات — حاول مرة أخرى';

  @override
  String get voiceWriteThis => 'اكتب هذا';

  @override
  String get voiceCannotWrite =>
      'لا يستطيع هذا الهاتف كتابة الملاحظات الصوتية.';

  @override
  String get voiceLanguageMissing => 'لم يُنزّل هذا الهاتف تلك اللغة بعد.';

  @override
  String get voiceWriting => 'تجري الكتابة…';

  @override
  String get voiceWaiting => 'في انتظار الكتابة.';

  @override
  String get voiceWritten => 'كُتبت على هذا الهاتف.';

  @override
  String get errorPartNotShown => 'تعذّر عرض هذا الجزء.';

  @override
  String get errorScreenShort => 'تلك الشاشة لم تُفتح.';

  @override
  String get errorNothingLost =>
      'لم يُفقد شيء. كل ما كتبته ما زال في الخزنة، تمامًا كما كان.';

  @override
  String get errorHideDetails => 'إخفاء التفاصيل التقنية';

  @override
  String get errorShowDetails => 'إظهار التفاصيل التقنية';

  @override
  String get errorDetailsNote =>
      'هذا كل ما سيُنسخ. يقول ما الذي تعطّل وأين في الشيفرة — ولا يحتوي شيئًا مما كتبته.';

  @override
  String get passcodeChangeFailed => 'تعذّر تغيير رمز الدخول.';

  @override
  String get passcodeOldStillWorks => 'رمزك القديم ما زال يعمل.';

  @override
  String get passcodeChanged => 'تغيّر رمز الدخول';

  @override
  String get passcodeWordsUnchanged =>
      'كلماتك الاثنتا عشرة لم تتغير، ولا تحتاج جديدة. تفتح خزنتك وملفات نسخك الاحتياطية تمامًا كما كانت.';

  @override
  String get passcodeOldBackups =>
      'النسخ الاحتياطية التي لديك تُفتح برمزك القديم. أما التي تُصنع الآن فستستخدم الجديد.';

  @override
  String get passcodeMakeBackup => 'أنشئ نسخة احتياطية الآن';

  @override
  String get passcodeCurrent => 'الرمز الحالي';

  @override
  String get passcodeNewAgain => 'الجديد مرة أخرى';

  @override
  String get passcodeOldBackupsNote =>
      'ملفات النسخ الاحتياطي التي أنشأتها من قبل ستظل تُفتح برمزك القديم.';

  @override
  String get passcodeWordsNote =>
      'كلمات الاستعادة الاثنتا عشرة لا تتغير وتظل تعمل.';

  @override
  String get licencesFonts =>
      'كل خط هنا تحت رخصة SIL Open Font. لا يُنزَّل شيء — كلها داخل التطبيق.';

  @override
  String get licencesSource =>
      'Lamplight نفسه تحت GPL-3.0 مع استثناء لمتاجر التطبيقات. الشيفرة المصدرية هي الرخصة: يستطيع أي أحد قراءتها والتأكد أن التطبيق يفعل ما تقوله هذه الشاشة.';

  @override
  String get licencesUnreadable => 'تعذّرت قراءة ملف الرخصة.';

  @override
  String get appearanceSample =>
      'مطر طوال الظهيرة. أعددت شايًا، قرأت نصف فصل، نسيت ما أردت قوله وكتبت هذا بدلًا منه.';

  @override
  String get appearanceChromeNote => 'الأزرار والعناوين تبقى هكذا';

  @override
  String get appearanceSizeNote =>
      'هذا يُضاف فوق حجم الخط في هاتفك نفسه، فإن كنت قد كبّرته هناك، فهذا يزيده أكثر.';

  @override
  String get voicePause => 'إيقاف مؤقت';

  @override
  String get importIntro =>
      'إن كنت قد كتبت مدوّنة في مكان آخر، يستطيع Lamplight إدخالها — ما دامت ملفات نصية والتاريخ في أسمائها.';

  @override
  String get importHowDates =>
      'يقرأ الملفات النصية ويبحث عن تاريخ في الاسم — 2026-08-24، أو 24 أغسطس 2026 — في أي موضع من اسم الملف أو المجلدات فوقه.';

  @override
  String get importAmbiguousDates =>
      'تواريخ مثل 03-04-2026 تُتجاوَز عمدًا. فهي الثالث من أبريل في بلاد والرابع من مارس في أخرى، والتخمين الخاطئ سيضع سنة من عمرك في أيام غير أيامها دون أن يخبرك.';

  @override
  String get importFormats =>
      'يقرأ Lamplight النص الصِّرف: ‎.txt و‎.md و‎.org و‎.log وغيرها، وحتى الملفات بلا امتداد. وإن كانت مدوّنتك بصيغة أخرى، صدّرها نصًّا أولًا.';

  @override
  String get importAtStartOfDay =>
      'ستقع في بداية كل يوم، لأن اسم الملف يعطي التاريخ لا الساعة. ولا يُغيَّر ولا يُحذف شيء مما في Lamplight أصلًا، وتشغيل هذا مرتين لا ينشئ نسخًا.';

  @override
  String get importFileDateNote =>
      'يضعها في اليوم الذي عُدّل فيه الملف آخر مرة. وإن كان المجلد قد نُسخ بين أجهزة، فقد يكون ذلك يوم النسخ لا يوم الكتابة.';

  @override
  String get importSkippedNote =>
      'هذه ستُتجاوَز. وتبقى حيث هي تمامًا — لا يُنقل ولا يُحذف شيء من مجلدك.';

  @override
  String get restoreChooseNote =>
      'اختر ملف النسخة الاحتياطية. سيكون اسمه شيئًا مثل Lamplight-2026-08-18.vault.';

  @override
  String get restorePasscodeNote =>
      'أدخل رمز هذا الملف — الرمز الذي كان مضبوطًا حين أُنشئت النسخة.';

  @override
  String get restoreWordsNote =>
      'اكتب الكلمات الاثنتي عشرة، بالترتيب، وبينها مسافات.';

  @override
  String get restoreDoNotClose => 'لا تغلق Lamplight حتى ينتهي هذا.';

  @override
  String get exportIntro =>
      'يكتب هذا كل ما في Lamplight داخل مجلد تختاره، كملفات عادية — ملف نصي لكل يوم، وكل صورة وفيديو وملاحظة صوتية ومستند باسمه الخاص.';

  @override
  String get exportNoLamplightNeeded =>
      'لا شيء في ذلك المجلد يحتاج Lamplight ليُفتح. وإن توقف هذا التطبيق يومًا، أو توقفت أنت عن استخدامه، تظل ملاحظاتك تُفتح بأي شيء يقرأ النص.';

  @override
  String get exportWhichOneBody =>
      'النسخة القابلة للقراءة للقراءة، أو للنقل إلى تطبيق آخر، أو للاحتفاظ بشيء بعد تركك Lamplight. وهي غير محمية.\n\nأما ملف النسخة الاحتياطية فلاستعادة Lamplight كما كان تمامًا — هاتف جديد، أو هاتف تعطّل. وهو مقفل برمزك، فيمكن حفظه في أي مكان، بما في ذلك التخزين السحابي.\n\nأكثر الناس يريدون النسخة الاحتياطية. وخذ نسخة قابلة للقراءة أيضًا إن أردت اليقين بأنك لن تعلق أبدًا.';

  @override
  String get exportNotLockedBody =>
      'ليس عليها أي رمز. وكل من يفتح ذلك المجلد يستطيع قراءة كل ما فيه. ضعها حيث يرضيك ذلك — وإن كنت تريد شيئًا آمنًا للحفظ فحسب، فاستخدم النسخة الاحتياطية.';

  @override
  String get backupConfirmNote =>
      'أكّد رمز الدخول. هذا الملف يستطيع فتح كل شيء، فإنشاؤه ينبغي أن يكون أمرًا قصدته.';

  @override
  String get backupKeepSafeNote =>
      'نسختك مقفلة بالرمز الذي لديك الآن. احفظها حيث تثق — التخزين السحابي مناسب، لأن الملف غير قابل للقراءة بغير ذلك الرمز. ونحن لا نراه أبدًا.';

  @override
  String get backupRestoreWarning =>
      'فتح نسخة احتياطية يستبدل كل ما في Lamplight الآن. وتُنحّى ملاحظاتك الحالية جانبًا حتى يثبت أن المستعادة تُفتح.';

  @override
  String get folderWhatItIs =>
      'المجلد خيط يمتد عبر أيامك — شخص واحد، مكان واحد، مرحلة واحدة.';

  @override
  String get folderNothingMoves =>
      'لا شيء ينتقل إلى مجلد. تبقى المدوّنة في يومها وتظهر هنا أيضًا.';

  @override
  String get folderDeleteNote =>
      'يذهب المجلد. وكل ما فيه يبقى حيث هو تمامًا، في يومه.';

  @override
  String get folderNoneInHere =>
      'لا شيء هنا بعد. اضغط مطوّلًا على شيء في أحد الأيام واختر «أضف إلى مجلد».';

  @override
  String get passcodeRuleLength => 'ثمانية محارف أو أكثر.';

  @override
  String get passcodeRuleWords =>
      'بضع كلمات عادية تتذكرها أفضل من رمز قصير فيه رموز.';

  @override
  String get passcodeNoMatch => 'لم يتطابقا بعد.';

  @override
  String get docCopyInClear =>
      'تُكتب النسخة بلا تشفير، فأي تطبيق يستطيع قراءة ملفاتك يستطيع قراءتها. أما ما يبقى داخل Lamplight فيظل مشفّرًا في الحالين.';

  @override
  String docPageOf(String page, String total) {
    return '$page من $total';
  }

  @override
  String get transcribeTookTooLong =>
      'استغرق تفريغ ذلك التسجيل وقتًا طويلًا، فتوقّف Lamplight عن الانتظار. سيحاول لاحقًا.';

  @override
  String get transcribeCouldNotWriteDown => 'تعذّر تفريغ ذلك التسجيل كتابةً.';

  @override
  String get transcribeRecordingIsSafe =>
      'التسجيل نفسه بأمان. سيحاول Lamplight مرة أخرى.';

  @override
  String voicePositionSpoken(Object at, Object total) {
    return '$at من $total';
  }

  @override
  String entryEditedAt(Object time) {
    return '$time · معدّلة';
  }

  @override
  String get docCouldNotOpen => 'تعذّر فتح هذا المستند.';

  @override
  String albumThisOne(Object thing) {
    return 'هذا $thing';
  }

  @override
  String albumThisOneOf(Object index, Object thing, Object total) {
    return 'هذا $thing — $index من $total';
  }

  @override
  String get albumCaptionThese => 'اكتب شيئًا عنها';

  @override
  String get albumCaptionThis => 'اكتب شيئًا';

  @override
  String get albumCaptionEdit => 'تعديل ما كُتب';

  @override
  String albumOthersStay(Object count) {
    return 'الباقي ($count) يبقى. هذا ينتقل إلى المهملات لمدة 30 يومًا.';
  }

  @override
  String get albumGoesToTrash => 'ينتقل إلى المهملات لمدة 30 يومًا.';

  @override
  String get photoCouldNotOpen => 'تعذّر فتح هذه الصورة.';

  @override
  String get photoMayBeDamaged => 'ربما تكون تالفة.';

  @override
  String get docTooBig =>
      'هذا الملف أكبر من أن يُفتح داخل Lamplight. يمكنك حفظ نسخة وفتحها في مكان آخر.';

  @override
  String docPages(Object count) {
    return '$count صفحة';
  }

  @override
  String get docFileEmpty => 'هذا الملف فارغ.';

  @override
  String videoTooBig(Object size) {
    return 'هذا الفيديو أكبر من أن يُشغَّل هنا — $size. ولن يُكتب بدون حماية للالتفاف على ذلك. احفظ نسخة لمشاهدته في مكان آخر.';
  }

  @override
  String get videoNotAvailableHere =>
      'هذا الجزء من التطبيق غير متاح على هذا الهاتف.';

  @override
  String get videoCouldNotOpen => 'تعذّر فتح هذا الفيديو.';

  @override
  String get docGoToPage => 'الانتقال إلى صفحة';

  @override
  String get docGo => 'انتقال';

  @override
  String get docPageCouldNotBeDrawn => 'تعذّر رسم هذه الصفحة.';

  @override
  String get passcodeRuleStronger =>
      'كلمة أو كلمتان إضافيتان تجعلانه أصعب بكثير في التخمين.';

  @override
  String get backupAutoFooter =>
      'تعمل النسخ الاحتياطية التلقائية عند فتحك Lamplight، إن تغيّر شيء منذ آخر نسخة. وهي مقفلة برمزك تمامًا كالتي تصنعها بنفسك.';

  @override
  String get aboutHowKeptBody =>
      'لا حساب. لا خادم. لا شيء يغادر هذا الهاتف.\n\nملاحظاتك مقفلة برمز الدخول، والمفتاح يُشتق منه — فلا توجد له نسخة في أي مكان، ولا عندنا.';

  @override
  String get aboutFree =>
      'Lamplight مجاني وسيظل كذلك. ليس هناك ما يُفتح بالدفع.';

  @override
  String get aboutContact => 'هل هناك خطأ؟ أخبرني.';

  @override
  String get aboutContactSemantic => 'إرسال ملاحظات بالبريد';

  @override
  String aboutNoMail(String address) {
    return 'لا يوجد تطبيق بريد على هذا الهاتف. العنوان هو $address.';
  }

  @override
  String get backupOnItsOwn => 'من تلقاء نفسه';

  @override
  String get actionDismiss => 'إخفاء';

  @override
  String importRange(String from, String to) {
    return 'من $from إلى $to.';
  }

  @override
  String get sizeOneCopy =>
      'يحتفظ Lamplight بنسخة واحدة. وما تختاره هنا هو ما سيكون لديك.';

  @override
  String get sizeAddAlways => 'أضف ولا تسأل مرة أخرى';

  @override
  String get trashNothingHere => 'لا شيء هنا.';

  @override
  String get appearanceAaQuiet => 'Aa\nهادئ';

  @override
  String lockWarnSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يُقفل بعد $count ثانية تقريبًا.',
      many: 'يُقفل بعد $count ثانية تقريبًا.',
      few: 'يُقفل بعد $count ثوانٍ تقريبًا.',
      two: 'يُقفل بعد ثانيتين تقريبًا.',
      one: 'يُقفل بعد ثانية تقريبًا.',
      zero: 'يُقفل الآن.',
    );
    return '$_temp0';
  }

  @override
  String get lockWarnChange => 'غيّر هذا في القفل والأمان.';

  @override
  String get openingLabel => 'يجري فتح Lamplight';

  @override
  String get recordingNoMic =>
      'لا يستطيع Lamplight استخدام الميكروفون. يمكنك تشغيله من إعدادات الهاتف، تحت التطبيقات.';

  @override
  String get recordingPaused => 'موقوف مؤقتًا. لا يُسمع شيء الآن.';

  @override
  String get videoOpening => 'يجري فتح الفيديو…';

  @override
  String albumRemoveThis(String thing) {
    return 'أزل $thing';
  }

  @override
  String get revisionsNote =>
      'ما كان مكتوبًا قبل أن تغيّره. لا شيء هنا زر — يمكنك تحديد الكلمات ونسخها.';

  @override
  String get composerSemantic => 'اكتب شيئًا لهذا اليوم';

  @override
  String importStripAdding(String name) {
    return 'تجري إضافة $name';
  }

  @override
  String passcodeAtLeast(int count) {
    return '$count محارف على الأقل';
  }

  @override
  String get searchKindAll => 'كل شيء';

  @override
  String get searchKindWords => 'كلمات';

  @override
  String get searchKindVoice => 'صوت';

  @override
  String get searchKindPhotos => 'صور';

  @override
  String get searchKindFiles => 'ملفات';

  @override
  String passcodeAtLeastShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محرف على الأقل',
      many: '$count محرفًا على الأقل',
      few: '$count محارف على الأقل',
      two: 'محرفان على الأقل',
      one: 'محرف واحد على الأقل',
      zero: 'لا محارف',
    );
    return '$_temp0';
  }

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقي $count يوم',
      many: 'بقي $count يومًا',
      few: 'بقيت $count أيام',
      two: 'بقي يومان',
      one: 'بقي يوم واحد',
      zero: 'ينتهي اليوم',
    );
    return '$_temp0';
  }

  @override
  String get trashGoneToday => 'يذهب اليوم';

  @override
  String restoreMadeOn(String date) {
    return 'أُنشئت في $date';
  }

  @override
  String restoreDone(String entries, String days) {
    return 'استُعيدت $entries عبر $days. أهلًا بعودتك.';
  }

  @override
  String importFoundUndated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بلا تاريخ يقرأه Lamplight',
      many: '$count بلا تاريخ يقرأه Lamplight',
      few: '$count بلا تاريخ يقرأه Lamplight',
      two: 'اثنان بلا تاريخ يقرأه Lamplight',
      one: 'واحد بلا تاريخ يقرأه Lamplight',
      zero: 'لا شيء بلا تاريخ',
    );
    return '$_temp0';
  }

  @override
  String entrySemantic(String time) {
    return 'مدوّنة عند $time. انقر للتعديل.';
  }

  @override
  String entrySemanticEdited(String time) {
    return 'مدوّنة عند $time، مُعدّلة. انقر للتعديل.';
  }

  @override
  String onThisDaySemantic(String when, String body) {
    return '$when. $body. انقر للانتقال إلى ذلك اليوم.';
  }

  @override
  String attachmentSemantic(String what, String time) {
    return '$what عند $time. انقر مرتين لفتحها.';
  }

  @override
  String dayHeaderToday(String date) {
    return '$date، اليوم';
  }

  @override
  String get yearGridNothing => 'لا شيء في هذا اليوم';

  @override
  String get calendarNothing => 'لا شيء في هذا اليوم';

  @override
  String importStripCounted(String name, String counted) {
    return 'تجري إضافة $name$counted';
  }

  @override
  String get aboutFingerprintBody =>
      'كل نسخة مبنية تحمل توقيعًا لا يستطيع صنعه إلا صاحبها. وهذا توقيع النسخة التي بين يديك. قارنه بالبصمة المنشورة بجانب الشيفرة المصدرية — فإن تطابقا، فهذا هو التطبيق الذي تبنيه تلك الشيفرة.';

  @override
  String get searchKindVideo => 'فيديو';

  @override
  String get semanticOn => 'مفعّل';

  @override
  String andMore(int count) {
    return 'و$count أخرى';
  }

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مدوّنة',
      many: '$count مدوّنة',
      few: '$count مدوّنات',
      two: 'مدوّنتان',
      one: 'مدوّنة واحدة',
      zero: 'لا شيء',
    );
    return '$_temp0';
  }

  @override
  String get checkDone => 'تمّ';

  @override
  String get checkNotYet => 'ليس بعد';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: 'لا أيام',
    );
    return '$_temp0';
  }

  @override
  String get lockUseYourPasscode => 'استخدم رمز المرور الخاص بك.';

  @override
  String get searchWordsExample => 'أي شيء كتبته';

  @override
  String get searchAFile => 'ملف';

  @override
  String get searchFileExample => 'scan.pdf · IMG_2831';

  @override
  String get searchAFolder => 'مجلد';

  @override
  String get searchFolderExample => 'الاسم الذي أعطيته له';

  @override
  String get searchByFileName => 'حسب اسم الملف';

  @override
  String get searchARecording => 'تسجيل';

  @override
  String get searchAnEntry => 'مدخل';

  @override
  String get sizeThisOne => 'هذا';

  @override
  String get sizeTheseOnes => 'هذه';

  @override
  String get passcodeOneMoreCharacter => 'حرف واحد إضافي.';

  @override
  String passcodeMoreCharacters(int count, int minimum) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حرف إضافي — الحد الأدنى $minimum.',
      many: '$count حرفاً إضافياً — الحد الأدنى $minimum.',
      few: '$count أحرف إضافية — الحد الأدنى $minimum.',
      two: 'حرفان إضافيان — الحد الأدنى $minimum.',
      one: 'حرف واحد إضافي — الحد الأدنى $minimum.',
      zero: 'الحد الأدنى $minimum حرفاً.',
    );
    return '$_temp0';
  }

  @override
  String get passcodeTooObvious =>
      'هذا من أول ما قد يجربه أي شخص. اختر شيئاً آخر.';

  @override
  String get passcodeSameCharacter => 'هذا هو الحرف نفسه مكرراً.';

  @override
  String get passcodeStraightRun => 'هذا تسلسل مباشر من الأحرف.';

  @override
  String attachmentLoading(String time) {
    return 'مرفق في $time، جارٍ التحميل';
  }

  @override
  String videoSemantic(String time, String length) {
    return 'فيديو في $time، $length. انقر مرتين للمشاهدة.';
  }

  @override
  String voiceSemantic(String time, String length) {
    return 'ملاحظة صوتية في $time، $length. انقر مرتين للتشغيل.';
  }

  @override
  String fileSemantic(String time, String name, String size) {
    return 'ملف في $time، $name، $size. انقر مرتين للفتح.';
  }

  @override
  String get lengthUnknown => 'المدة غير معروفة';

  @override
  String get settingsLockNone => 'بدون قفل تلقائي';

  @override
  String settingsLockAfter(String duration) {
    return 'بعد $duration';
  }

  @override
  String settingsSecuritySummary(String lock) {
    return 'رمز المرور، بصمة الإصبع، $lock';
  }

  @override
  String get keptNoNetworkTitle => 'لا يذهب إلى أي مكان أبداً';

  @override
  String get keptNoNetworkBody =>
      'لا يستطيع Lamplight استخدام الإنترنت. ليس «لا يفعل» — بل «لا يستطيع»: يرفض أندرويد منحه الإذن، ويمكنك التحقق من ذلك بنفسك في إعدادات التطبيقات على هاتفك في نحو ثلاثين ثانية.';

  @override
  String get keptPasscodeTitle => 'رمز المرور هو المفتاح';

  @override
  String get keptPasscodeBody =>
      'المفتاح الذي يفتح ملاحظاتك يُشتق من رمز المرور في كل مرة تفتح فيها القفل. وهو لا يُحفظ في أي مكان، فلا توجد نسخة منه يمكن العثور عليها أو فقدانها أو تسليمها.';

  @override
  String get keptForgetTitle => 'إذا نسيته';

  @override
  String get keptForgetBody =>
      'كلماتك الاثنتا عشرة هي الطريق الآخر الوحيد للدخول. لا أحد هنا يستطيع إعادة تعيين رمز المرور، وهذه هي الحقيقة نفسها المذكورة أعلاه — فتطبيق يستطيع أن يعيدك إلى الداخل يستطيع أن يُدخل شخصاً آخر أيضاً.';

  @override
  String get keptNothingReadableTitle => 'لا يبقى أي شيء مقروء ملقى في مكان ما';

  @override
  String get keptNothingReadableBody =>
      'تُشفَّر الصور والتسجيلات والملفات قبل أن تصل إلى وحدة التخزين. ولا يُكتب أي شيء بصيغة مقروءة على الإطلاق، ولا حتى للحظة بينما تنظر إليه.';

  @override
  String get keptLocksItselfTitle => 'يقفل نفسه تلقائياً';

  @override
  String get keptLocksItselfBody =>
      'في اللحظة التي ينتقل فيها Lamplight إلى الخلفية تُدمَّر المفاتيح. ولقطات الشاشة محظورة، ولا يظهر التطبيق في معاينة التطبيقات الأخيرة.';

  @override
  String get keptBackUpTitle => 'احتفظ بنسخة احتياطية';

  @override
  String get keptBackUpBody =>
      'كل شيء موجود على هذا الهاتف ولا شيء في مكان آخر، وهذا هو المقصود وهو أيضاً الخطر. النسخة الاحتياطية ملف مشفَّر واحد لا يفتحه إلا رمز المرور الخاص بك. احتفظ بنسخة في مكان ما.';
}
