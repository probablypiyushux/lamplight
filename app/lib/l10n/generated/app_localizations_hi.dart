// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class LHi extends L {
  LHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'Lamplight';

  @override
  String get lockTypePasscode => 'अपना पासकोड लिखिए।';

  @override
  String get lockWrongPasscode => 'इससे तिजोरी नहीं खुली।';

  @override
  String get lockCheckAndRetry => 'पासकोड देखकर फिर कोशिश कीजिए।';

  @override
  String get lockForgot => 'मैं अपना पासकोड भूल गया';

  @override
  String get lockTypeTwelveWords => 'अपने बारह शब्द लिखिए।';

  @override
  String get lockUsePasscodeInstead => 'पासकोड इस्तेमाल करूँगा';

  @override
  String get lockUseFingerprint => 'अपनी उँगली का निशान इस्तेमाल कीजिए';

  @override
  String get lockFingerprintFailed => 'उँगली के निशान से नहीं खुला।';

  @override
  String get lockFingerprintUnavailable =>
      'उँगली के निशान की सुविधा उपलब्ध नहीं है।';

  @override
  String get lockOpening => 'खुल रहा है…';

  @override
  String get lockNothingDeleted =>
      'कुछ भी मिटाया नहीं गया है, और मिटाया नहीं जाएगा।';

  @override
  String lockTryAgainSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सेकंड बाद फिर कोशिश कीजिए।',
      one: 'एक सेकंड बाद फिर कोशिश कीजिए।',
    );
    return '$_temp0';
  }

  @override
  String lockTryAgainMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मिनट बाद फिर कोशिश कीजिए।',
      one: 'एक मिनट बाद फिर कोशिश कीजिए।',
    );
    return '$_temp0';
  }

  @override
  String get dayToday => 'आज';

  @override
  String get dayPrevious => 'पिछला दिन';

  @override
  String get dayNext => 'अगला दिन';

  @override
  String get daySearch => 'खोजिए';

  @override
  String get daySettings => 'सेटिंग';

  @override
  String get dayChooseDate => 'कोई और तारीख़ चुनिए।';

  @override
  String get dayEmptyToday => 'कुछ रखना चाहेंगे?';

  @override
  String get dayEmptyPast => 'इस दिन कुछ नहीं है।';

  @override
  String get dayWriteSomething => 'आज के लिए कुछ लिखिए';

  @override
  String get dayLineAsk => 'यह दिन कैसा रहा?';

  @override
  String get dayLineHint => 'यह दिन कैसा रहा?';

  @override
  String get dayLineSemantic => 'एक पंक्ति में लिखिए कि यह दिन कैसा रहा';

  @override
  String dayLineChange(String note) {
    return 'यह दिन: $note. बदलिए।';
  }

  @override
  String get dayEndOfDay => 'दिन का अंत';

  @override
  String get dayStartOfDay => 'दिन की शुरुआत';

  @override
  String get firstPageTitle =>
      'यह ख़ाली है क्योंकि आपने अभी तक इसमें कुछ लिखा नहीं है।';

  @override
  String get firstPageShelves =>
      'दिन ही ख़ाने हैं। आप जो रखेंगे वह उसी दिन पर रहेगा जिस दिन वह हुआ, और वहीं रहेगा।';

  @override
  String get firstPageWayWrite => 'लिखने के लिए इस पन्ने पर छुइए।';

  @override
  String get firstPageWayVoice => 'बोलकर कहना हो तो माइक दबाए रखिए।';

  @override
  String get firstPageWayAttach => 'कोई तस्वीर, वीडियो या दस्तावेज़ जोड़िए।';

  @override
  String get firstPagePromise => 'इसमें से कुछ भी इस फ़ोन से बाहर नहीं जाता।';

  @override
  String get firstPageSemantic => 'अपनी डायरी में पहली बात लिखिए';

  @override
  String get captureVoice => 'आवाज़ रिकॉर्ड कीजिए';

  @override
  String get capturePhoto => 'तस्वीर लीजिए या चुनिए';

  @override
  String get captureFile => 'फ़ाइल जोड़िए';

  @override
  String get backupNeverMade =>
      'यहाँ का कोई बैकअप नहीं है। अगर यह ऐप हटा दिया गया, तो आपकी बातें भी उसके साथ चली जाएँगी।';

  @override
  String get backupStale => 'पिछले बैकअप को काफ़ी समय हो गया है।';

  @override
  String get backupOutOfDate => 'आपका बैकअप अब भी पुराने पासकोड से खुलता है।';

  @override
  String get backupAction => 'बैकअप';

  @override
  String folderAlsoIn(String name) {
    return '$name में भी। फ़ोल्डर खोलिए।';
  }

  @override
  String get folderStaysHere =>
      'यह अपनी जगह पर ही रहता है। फ़ोल्डर इसे ढूँढ़ने की दूसरी जगह है।';

  @override
  String get folderAddTo => 'फ़ोल्डर में जोड़िए';

  @override
  String get folderNew => 'नया फ़ोल्डर';

  @override
  String get folderNoneYet =>
      'अभी कोई फ़ोल्डर नहीं है। एक व्यक्ति के लिए एक, या एक दौर के लिए — जिस पर आप बार-बार लौटते हों।';

  @override
  String folderLesson(String day, String folder) {
    return '$day पर ही है। $folder में भी।';
  }

  @override
  String get actionDone => 'हो गया';

  @override
  String get actionCancel => 'रहने दीजिए';

  @override
  String get actionDelete => 'मिटाइए';

  @override
  String get actionSave => 'रखिए';

  @override
  String get actionEdit => 'बदलिए';

  @override
  String get actionUndo => 'वापस लाइए';

  @override
  String get actionOpen => 'खोलिए';

  @override
  String get actionRemove => 'हटाइए';

  @override
  String get actionNotNow => 'अभी नहीं';

  @override
  String get settingsTitle => 'सेटिंग';

  @override
  String get settingsAppearance => 'रूप-रंग';

  @override
  String get settingsSecurity => 'ताला और सुरक्षा';

  @override
  String get settingsYourNotes => 'आपकी बातें';

  @override
  String get settingsBackup => 'बैकअप';

  @override
  String get settingsAbout => 'ऐप के बारे में';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get settingsLanguageNote =>
      'ऐप जिन शब्दों में बात करता है। आप जो लिखते हैं वह आपका है, किसी भी भाषा में, चाहे यह जो भी हो।';

  @override
  String get settingsLanguageSystem => 'फ़ोन के अनुसार';

  @override
  String get entryMattered => 'यह बात मायने रखती थी';

  @override
  String get entryMarked => 'इसे उन बातों में गिना गया जो मायने रखती थीं।';

  @override
  String get entryMarkRemoved => 'निशान हटा दिया गया।';

  @override
  String get entryDeleted => 'मिटा दिया गया।';

  @override
  String entryEarlierVersions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पुराने रूप',
      one: 'एक पुराना रूप',
    );
    return '$_temp0';
  }

  @override
  String get entryKeepsWords => 'लिखी बातें रहेंगी';

  @override
  String entryKindInTrash(Object kind) {
    return '$kind कूड़ेदान में है।';
  }

  @override
  String entryKindInTrashWords(Object kind) {
    return '$kind कूड़ेदान में है। लिखी बातें यहीं हैं।';
  }

  @override
  String trashConfirmBody(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count बातें, और उनके सारे पुराने रूप। यह वापस नहीं किया जा सकता।',
      one: 'एक बात, और उसके सारे पुराने रूप। यह वापस नहीं किया जा सकता।',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyEntry => 'ख़ाली बात';

  @override
  String get kindPhoto => 'फ़ोटो';

  @override
  String get kindVideo => 'वीडियो';

  @override
  String get kindRecording => 'रिकॉर्डिंग';

  @override
  String get kindFile => 'फ़ाइल';

  @override
  String get entryNoLongerMarked => 'अब निशान नहीं';

  @override
  String get entryFindAgain => 'खोज वाली स्क्रीन से इसे फिर पाइए';

  @override
  String get searchGoTo => 'यहाँ जाइए';

  @override
  String get searchFolders => 'फ़ोल्डर';

  @override
  String get searchEntriesOne => '1 बात';

  @override
  String searchEntriesMany(int count) {
    return '$count बातें';
  }

  @override
  String get searchNothingFound => 'उससे कुछ नहीं मिला।';

  @override
  String get searchEverythingInstead => 'इसके बजाय सब कुछ खोजिए';

  @override
  String get onboardNoAccount => 'कोई खाता नहीं है।';

  @override
  String get onboardPromiseBody =>
      'आपके नोट इसी फ़ोन में रहते हैं।\nहमारा कोई सर्वर नहीं है। हम उन्हें पढ़ नहीं सकते।\nहम उन्हें वापस भी नहीं ला सकते।';

  @override
  String get onboardBegin => 'शुरू करें';

  @override
  String get onboardHaveBackup => 'मेरे पास बैकअप है';

  @override
  String get onboardSetPasscode => 'एक पासकोड बनाएँ';

  @override
  String get onboardPasscodeBody =>
      'आपके नोट सिर्फ़ यही खोलता है। जो वाक्य आपको याद रह जाए, वह चार अंकों से मज़बूत होता है।';

  @override
  String get onboardPasscodeLabel => 'पासकोड';

  @override
  String get onboardPasscodeAgain => 'इसे फिर से लिखिए';

  @override
  String get onboardSettingUp => 'तैयार हो रहा है…';

  @override
  String get onboardContinue => 'आगे बढ़ें';

  @override
  String get onboardPasscodesDiffer => 'ये दोनों एक जैसे नहीं हैं।';

  @override
  String get onboardVaultFailed => 'आपकी तिजोरी बन नहीं पाई।';

  @override
  String get onboardVaultFailedThen =>
      'कुछ भी सेव नहीं हुआ। एक बार फिर कोशिश कीजिए।';

  @override
  String get onboardWriteWords => 'ये बारह शब्द काग़ज़ पर\nलिख लीजिए';

  @override
  String get onboardWordsBody =>
      'इनकी कोई प्रति हमारे पास नहीं है। हम ये आपको भेज नहीं सकते। कोई सपोर्ट ईमेल नहीं है जो मदद कर सके।\n\nस्क्रीनशॉट नहीं — काग़ज़। स्क्रीनशॉट आपकी गैलरी में पड़ा रहता है, और कोई भी सबसे पहले वहीं देखता है।';

  @override
  String get onboardWrittenDown => 'मैंने लिख लिए हैं';

  @override
  String get onboardCopyWords => 'बारहों शब्द कॉपी करें';

  @override
  String get onboardClipboardNote =>
      'क्लिपबोर्ड एक मिनट बाद खुद साफ़ हो जाता है। तब तक दूसरे ऐप उसे पढ़ सकते हैं।';

  @override
  String get onboardCopied =>
      'कॉपी हो गया। एक मिनट में खुद मिट जाएगा — अभी किसी सुरक्षित जगह पेस्ट कर लीजिए।';

  @override
  String get onboardCopyFailed =>
      'यह कॉपी नहीं हो पाया। वैसे भी हाथ से लिखना ज़्यादा सुरक्षित है।';

  @override
  String get onboardCheckThree => 'इनमें से तीन जाँचिए';

  @override
  String get onboardCheckBody => 'ताकि पता चले कि काग़ज़ सही है, स्क्रीन नहीं।';

  @override
  String onboardWordNumber(int number) {
    return 'शब्द $number';
  }

  @override
  String onboardWordWrong(int number) {
    return 'शब्द $number सही नहीं है। आपने जो लिखा था उसे देखिए।';
  }

  @override
  String get onboardShowWords => 'शब्द फिर से दिखाइए';

  @override
  String get onboardFingerprintTitle => 'अपनी फ़िंगरप्रिंट से खोलें?';

  @override
  String get onboardFingerprintBody => 'ताकि हर बार वह वाक्य न लिखना पड़े।';

  @override
  String get onboardFingerprintExplain =>
      'कुंजी अब भी आपका वाक्य ही है। फ़िंगरप्रिंट सिर्फ़ यही तिजोरी खोलती है, सिर्फ़ इसी फ़ोन पर, और अगर फ़ोन की फ़िंगरप्रिंट्स कभी बदलीं तो Android खुद इसे बंद कर देता है — ताकि कोई अपनी जोड़कर अंदर न आ सके। यह कभी बैकअप का हिस्सा नहीं बनती।';

  @override
  String get onboardFingerprintWaiting => 'आपकी उंगली का इंतज़ार है…';

  @override
  String get onboardFingerprintUse => 'मेरी फ़िंगरप्रिंट इस्तेमाल करें';

  @override
  String get onboardFingerprintFailed => 'यह काम नहीं कर पाया।';

  @override
  String get onboardOneLastThing => 'एक आख़िरी बात';

  @override
  String get onboardNameBody =>
      'Lamplight आपको क्या कहकर बुलाए? यह इसी फ़ोन में रहता है, और आप इसे बदल सकते हैं या खाली छोड़ सकते हैं।';

  @override
  String get onboardFingerprintOn =>
      'अब से आपकी फ़िंगरप्रिंट Lamplight खोलेगी।';

  @override
  String get onboardYourName => 'आपका नाम';

  @override
  String get onboardStartWriting => 'लिखना शुरू करें';

  @override
  String get onboardSkip => 'छोड़ दें';

  @override
  String get settingsGroupLook => 'दिखता कैसा है, बोलता किस ज़बान में';

  @override
  String get settingsGroupWhoCanOpen => 'कौन खोल सकता है';

  @override
  String get settingsGroupKeeping => 'सँभालना, और साथ ले जाना';

  @override
  String get settingsAppearanceNote => 'थीम, फ़ॉन्ट, रंग, पन्ना';

  @override
  String get settingsFolders => 'फ़ोल्डर';

  @override
  String get settingsFoldersNote => 'लोग, जगहें, दौर';

  @override
  String get settingsMedia => 'मीडिया';

  @override
  String get settingsMediaNote => 'फ़ोटो, वीडियो, आवाज़ और दस्तावेज़';

  @override
  String get mediaGroupDocuments => 'दस्तावेज़';

  @override
  String get mediaDocumentsKept => 'जैसे आए थे, बिल्कुल वैसे ही रखे जाते हैं';

  @override
  String get mediaDocumentsFooter =>
      'PDF या Word फ़ाइल अंदर से पहले ही दबी हुई होती है, इसलिए उसे दोबारा दबाने से लगभग पाँच प्रतिशत ही बचता है। सचमुच फ़र्क़ लाने के लिए उसके भीतर की तस्वीरें दोबारा बनानी पड़तीं, जिससे स्कैन में लिखा छोटा अक्षर हमेशा के लिए धुंधला हो जाता — और यह आपको सालों बाद उस दिन पता चलता, जिस दिन उसे पढ़ना ज़रूरी होता।';

  @override
  String get settingsTrash => 'कूड़ेदान';

  @override
  String get settingsTrashNote => 'मिटाई गई बातें, 30 दिन तक रखी जाती हैं';

  @override
  String get settingsReadableCopy => 'पढ़ने लायक़ कॉपी';

  @override
  String get settingsReadableCopyNote =>
      'Markdown और आपकी फ़ाइलें, आपकी चुनी हुई फ़ोल्डर में';

  @override
  String get settingsBringIn => 'पुरानी डायरी ले आइए';

  @override
  String get settingsBringInNote =>
      'किसी और ऐप की टेक्स्ट फ़ाइलें, उनकी तारीख़ के हिसाब से लगी हुई';

  @override
  String get settingsKeepingFooter =>
      'बैकअप आपके पासकोड से बंद रहता है, बिल्कुल तिजोरी की तरह। पढ़ने लायक़ कॉपी बिल्कुल भी बंद नहीं होती — वो आपकी चुनी हुई फ़ोल्डर में पड़ी सादी फ़ाइलें हैं।';

  @override
  String get backupNever => 'अब तक कोई बैकअप नहीं';

  @override
  String get backupToday => 'आज बैकअप हुआ';

  @override
  String get backupYesterday => 'कल बैकअप हुआ';

  @override
  String backupDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन पहले बैकअप हुआ',
    );
    return '$_temp0';
  }

  @override
  String get mediaGroupIncoming => 'आते वक़्त';

  @override
  String get mediaGroupVoice => 'आवाज़ के नोट';

  @override
  String get mediaIncomingFooter =>
      'Lamplight दूसरी, छोटी कॉपी कभी नहीं रखता — यहाँ आप जो चुनेंगे वही सहेजा जाता है, और असली फ़ाइल कहीं और नहीं बचती।';

  @override
  String get mediaVoiceFooter =>
      'लिखने का काम इसी फ़ोन पर होता है, उसी पहचानने वाले से जो Android में पहले से है। Lamplight में कही गई कोई बात कहीं नहीं भेजी जाती, और ऐप के पास भेजने की इजाज़त ही नहीं है।';

  @override
  String get mediaPhotoSize => 'फ़ोटो का साइज़';

  @override
  String get mediaVideoSize => 'वीडियो का साइज़';

  @override
  String get mediaAskEachTime => 'हर बार पूछें';

  @override
  String get accentAmber => 'कहरुवा';

  @override
  String get accentAmberNote => 'रात में जलता दीया। यही आम है।';

  @override
  String get accentRose => 'गुलाबी';

  @override
  String get accentRoseNote => 'गर्म गुलाबी। कहरुवा से नरम।';

  @override
  String get accentSage => 'मेहँदी';

  @override
  String get accentSageNote => 'शांत हरा। छहों में सबसे ठहरा हुआ।';

  @override
  String get accentSlate => 'स्लेटी';

  @override
  String get accentSlateNote => 'ठंडा नीला-स्लेटी। सबसे सादा।';

  @override
  String get accentPlum => 'बैंगनी';

  @override
  String get accentPlumNote => 'गहरा बैंगनी।';

  @override
  String get accentEmber => 'अंगारा';

  @override
  String get accentEmberNote => 'जला हुआ नारंगी। सबसे गर्म।';

  @override
  String get surfacePlain => 'सादा';

  @override
  String get surfacePlainNote => 'एक सपाट पन्ना।';

  @override
  String get surfacePaper => 'काग़ज़';

  @override
  String get surfacePaperNote =>
      'हल्का दाना, ताकि पन्ना किसी चीज़ जैसा लगे, ख़ालीपन जैसा नहीं। यही आम है।';

  @override
  String get surfaceLamplit => 'दीये की रौशनी';

  @override
  String get surfaceLamplitNote => 'काग़ज़, दीया जलाकर।';

  @override
  String get surfaceStarMap => 'तारों का नक़्शा';

  @override
  String get surfaceStarMapNote =>
      'एक ही आसमान, घड़ी के साथ घूमता हुआ। एक दिन में दो बार एक जैसा नहीं।';

  @override
  String get rulingNone => 'कुछ नहीं';

  @override
  String get rulingNoneNote => 'पन्ने पर कुछ छपा हुआ नहीं।';

  @override
  String get rulingLines => 'लकीरें';

  @override
  String get rulingLinesNote => 'कॉपी की तरह लकीरदार।';

  @override
  String get rulingIsometric => 'आइसोमेट्रिक';

  @override
  String get rulingIsometricNote =>
      'ड्राफ़्टिंग काग़ज़, तीन आयामों में सोचने के लिए।';

  @override
  String get rulingTriangle => 'तिकोना';

  @override
  String get rulingTriangleNote => 'बराबर भुजाओं वाले तिकोनों का जाल।';

  @override
  String get rulingDots => 'बिंदुओं की जाली';

  @override
  String get rulingDotsNote => 'हर कटान पर एक बिंदु। चारों में सबसे ख़ामोश।';

  @override
  String get faceSystem => 'फ़ोन वाला';

  @override
  String get faceSystemNote => 'जो बाक़ी फ़ोन इस्तेमाल करता है।';

  @override
  String get faceSerif => 'फ़ोन का सेरिफ़';

  @override
  String get faceSerifNote => 'आपके फ़ोन का अपना सेरिफ़।';

  @override
  String get faceCalmNote => 'नरम किनारे, चौड़े अक्षर।';

  @override
  String get faceModernNote => 'कसा हुआ और आजकल का।';

  @override
  String get faceOldStyleNote => 'सोलहवीं सदी की किताबी लिखावट।';

  @override
  String get facePlayfulNote => 'गोल और ख़ुशमिज़ाज।';

  @override
  String get faceChildlikeNote => 'स्कूल की कॉपी।';

  @override
  String get faceHandwrittenNote =>
      'हाथ की लिखावट, फिर भी पूरा पन्ना आराम से पढ़ा जाए।';

  @override
  String get faceMedievalNote => 'किसी लिपिक का हाथ। बस एक ही मोटाई।';

  @override
  String get faceMonoNote => 'हर अक्षर एक ही चौड़ाई का।';

  @override
  String get qualityOriginal => 'असली वाला ही रखें';

  @override
  String get qualityBalanced => 'संतुलित';

  @override
  String get qualitySmaller => 'छोटा';

  @override
  String get photoOriginalNote =>
      'जैसा आपके कैमरे ने बनाया, बिल्कुल वैसा ही। सबसे बड़ी फ़ाइलें — और इनमें वो जगह भी रह जाती है जहाँ फ़ोटो खींची गई थी, जिसे Lamplight वरना हटा देता है।';

  @override
  String get photoBalancedNote =>
      'काफ़ी छोटा, और असली से अलग पहचानना मुश्किल। यही आम है।';

  @override
  String get photoSmallerNote =>
      'उससे भी आधा। बहुत ज़्यादा ज़ूम करके काटेंगे तो शायद पता चले।';

  @override
  String get videoOriginalNote =>
      'जैसा आपके कैमरे ने रिकॉर्ड किया, बिल्कुल वैसा ही। कहीं ज़्यादा बड़ी फ़ाइलें।';

  @override
  String get videoBalancedNote =>
      'काफ़ी छोटा, और असली से अलग पहचानना मुश्किल। यही आम है।';

  @override
  String get videoSmallerNote => 'उससे भी आधा। बड़ी स्क्रीन पर शायद पता चले।';

  @override
  String get appearanceTitle => 'रंग-रूप';

  @override
  String get appearanceTheme => 'थीम';

  @override
  String get appearanceThemeDark => 'गहरा';

  @override
  String get appearanceThemeLight => 'हल्का';

  @override
  String get appearanceThemeAuto => 'अपने आप';

  @override
  String get appearanceThemeAutoNote =>
      'आपके फ़ोन की हल्की-गहरी सेटिंग के हिसाब से।';

  @override
  String get appearanceFont => 'फ़ॉन्ट';

  @override
  String get appearanceSize => 'आकार';

  @override
  String get appearanceColour => 'रंग';

  @override
  String get appearancePage => 'पन्ना';

  @override
  String get appearanceRuling => 'लकीरें';

  @override
  String get daySavedToToday => 'आज में सहेज लिया।';

  @override
  String get dayAddedToToday => 'आज में जोड़ दिया।';

  @override
  String get entryEditWords => 'शब्द बदलिए';

  @override
  String get entryDeleteBlock => 'पूरा ब्लॉक मिटाइए';

  @override
  String entrySavedAs(String name) {
    return '$name के नाम से सहेजा।';
  }

  @override
  String entryAddedToFolder(String name) {
    return '$name में भी।';
  }

  @override
  String get entrySaveCopy => 'एक कॉपी सहेजें';

  @override
  String get entrySaveCopyNote => 'जहाँ आप चाहें, Lamplight से बाहर';

  @override
  String get capturePhotoTake => 'फ़ोटो खींचिए';

  @override
  String get capturePhotoChoose => 'अपनी फ़ोटो में से चुनिए';

  @override
  String get composerHintToday => 'आज के बारे में लिखिए…';

  @override
  String get composerHintPast => 'इस दिन के बारे में लिखिए…';

  @override
  String get composerNewBlock => 'नया ब्लॉक';

  @override
  String get voiceShowTranscript => 'जो कहा गया वो दिखाइए';

  @override
  String get voiceHideTranscript => 'जो कहा गया वो छिपाइए';

  @override
  String get voiceTranscriptTitle => 'जो कहा गया';

  @override
  String get entryEdited => ', बदला हुआ';

  @override
  String photoSemantic(String time) {
    return '$time की फ़ोटो। देखने के लिए दो बार टैप कीजिए।';
  }

  @override
  String get sizeThisPhoto => 'यह फ़ोटो';

  @override
  String get sizeThesePhotos => 'ये फ़ोटो';

  @override
  String get sizeThisVideo => 'यह वीडियो';

  @override
  String get sizeTheseVideos => 'ये वीडियो';

  @override
  String sizeQuestion(String what) {
    return '$what किस साइज़ में रखें?';
  }

  @override
  String get trashNote =>
      'मिटाई गई चीज़ें यहाँ 30 दिन रहती हैं, फिर हमेशा के लिए चली जाती हैं।';

  @override
  String get trashConfirm => 'इन्हें हमेशा के लिए मिटाएँ?';

  @override
  String get trashKeep => 'रहने दीजिए';

  @override
  String get trashDeleteForGood => 'हमेशा के लिए मिटाइए';

  @override
  String get trashPutBack => 'वापस रखिए';

  @override
  String trashPutBackOn(String day) {
    return '$day पर वापस रख दिया।';
  }

  @override
  String get trashEmpty => 'कूड़ेदान ख़ाली कीजिए';

  @override
  String get folderMakeFirst => 'पहला बनाइए';

  @override
  String folderDeleteAsk(String name) {
    return '“$name” मिटाएँ?';
  }

  @override
  String get folderKeepIt => 'रहने दीजिए';

  @override
  String get folderDeleteIt => 'फ़ोल्डर मिटाइए';

  @override
  String get folderRename => 'नाम बदलिए';

  @override
  String get folderDeleteThis => 'यह फ़ोल्डर मिटाइए';

  @override
  String folderTakenOut(String name) {
    return '$name से निकाल दिया। यह अब भी अपने दिन पर है।';
  }

  @override
  String get searchHint => 'शब्द, कोई तारीख़, कोई नाम…';

  @override
  String get searchBack => 'वापस';

  @override
  String get searchClear => 'साफ़ कीजिए';

  @override
  String searchNothingMatches(String query) {
    return '“$query” से कुछ नहीं मिला।';
  }

  @override
  String get searchWhatMattered => 'जो मायने रखा';

  @override
  String get searchADate => 'कोई तारीख़';

  @override
  String get searchDateExample => '16 मार्च 2006 · मार्च 2006 · कल';

  @override
  String get searchWhatYouCanType => 'आप क्या ढूँढ सकते हैं';

  @override
  String get searchTryDate => 'कल';

  @override
  String get searchSaidOutLoud => 'बोलकर कहा गया';

  @override
  String get searchAPhotograph => 'कोई फ़ोटो';

  @override
  String get searchAVideo => 'कोई वीडियो';

  @override
  String get securityWhileOpen => 'जब तक ऐप खुला है';

  @override
  String get securityLockFooter =>
      'Lamplight पीछे जाते ही हमेशा बंद हो जाता है। यहाँ बस इतना तय होता है कि आपके अंदर रहते हुए वो कितनी देर इंतज़ार करे।';

  @override
  String get securityLockAfter => 'इतनी देर बाद बंद करें';

  @override
  String get securityOneHour => '1 घंटा';

  @override
  String get securityYourPasscode => 'आपका पासकोड';

  @override
  String get securityPasscodeFooter =>
      'आपका पासकोड ही चाबी है। यह कहीं भी सहेजा नहीं जाता — न इस फ़ोन में, न कहीं और — इसलिए किसी से ज़बरदस्ती लिया नहीं जा सकता, और कोई इसे आपके लिए वापस भी नहीं ला सकता।';

  @override
  String get securityChangePasscode => 'पासकोड बदलिए';

  @override
  String get securityScreenshots => 'स्क्रीनशॉट';

  @override
  String get securityScreenshotsFooter =>
      'Lamplight स्क्रीन कैप्चर रोक देता है, ताकि आपका फ़ोन उठाने वाला आपके नोट की फ़ोटो न ले सके, और ताकि वो हाल के ऐप्स की झलक में कभी न दिखें। अपने फ़ोन के लिए आप यह बंद कर सकते हैं।';

  @override
  String get securityAllowScreenshots => 'स्क्रीनशॉट लेने दें';

  @override
  String get securityScreenshotsOn => 'हाल के ऐप्स में आपकी बातें दिखेंगी';

  @override
  String get securityScreenshotsOff => 'हाल के ऐप्स में ख़ाली पन्ना दिखेगा';

  @override
  String get securityCouldNotChange => 'वह बदला नहीं जा सका।';

  @override
  String get securityNothingChanged =>
      'आपके ताले के बारे में कुछ नहीं बदला है।';

  @override
  String get securityPromptAutomatic => 'यह अपने आप पूछेगा';

  @override
  String get securityPromptOnTap => 'जब चाहें, फ़िंगरप्रिंट पर टैप करें';

  @override
  String get mediaAskEachTimeOn =>
      'जब आप फ़ोटो और वीडियो जोड़ेंगे, तब पूछा जाएगा कि उन्हें कितना बड़ा रखना है।';

  @override
  String get mediaAskEachTimeOff =>
      'बंद। ऊपर चुने गए दोनों आकार बिना पूछे इस्तेमाल होंगे।';

  @override
  String get passcodeNew => 'नया पासकोड';

  @override
  String get securityFingerprint => 'फ़िंगरप्रिंट';

  @override
  String get securityFingerprintFooter =>
      'कुंजी अब भी आपका वाक्य ही है। फ़िंगरप्रिंट सिर्फ़ यही तिजोरी खोलती है, सिर्फ़ इसी फ़ोन पर, और अगर फ़ोन की फ़िंगरप्रिंट्स कभी बदलीं तो Android खुद इसे बंद कर देता है — ताकि कोई अपनी जोड़कर अंदर न आ सके। यह कभी बैकअप का हिस्सा नहीं बनती।';

  @override
  String get securityUnlockWithFingerprint => 'अपनी फ़िंगरप्रिंट से खोलें';

  @override
  String get securityAskOnOpen => 'Lamplight खुलते ही पूछें';

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सेकंड',
      one: '1 सेकंड',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मिनट',
      one: '1 मिनट',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे',
      one: '1 घंटा',
    );
    return '$_temp0';
  }

  @override
  String get durationNever => 'कभी नहीं';

  @override
  String get securityDefaultNote => 'यही आम है।';

  @override
  String get securityHourNote => 'दोपहर भर पुराना पढ़ने के लिए।';

  @override
  String get securityNeverNote =>
      'ऐप से बाहर निकलते ही यह फिर भी बंद हो जाता है।';

  @override
  String get calendarGoToDate => 'किसी तारीख़ पर जाइए';

  @override
  String get dayHasWriting => 'लिखा हुआ';

  @override
  String get dayHasPhoto => 'एक फ़ोटो';

  @override
  String get dayHasVideo => 'एक वीडियो';

  @override
  String get dayHasVoice => 'एक आवाज़ की बात';

  @override
  String get dayHasFile => 'एक फ़ाइल';

  @override
  String dayEntriesAndKinds(Object count, Object kinds) {
    return '$count, $kinds';
  }

  @override
  String get listSeparator => ', ';

  @override
  String listAnd(Object last, Object most) {
    return '$most और $last';
  }

  @override
  String get integrityNothingUnusual =>
      'इस फ़ोन में कुछ असामान्य नहीं है। Lamplight जैसा चलना चाहिए वैसा चल रहा है।';

  @override
  String get calendarPreviousYear => 'पिछला साल';

  @override
  String get calendarPreviousMonth => 'पिछला महीना';

  @override
  String get calendarNextYear => 'अगला साल';

  @override
  String get calendarNextMonth => 'अगला महीना';

  @override
  String get calendarBackToMonth => 'महीने पर वापस';

  @override
  String get calendarWholeYear => 'पूरा साल';

  @override
  String get calendarBackToThisMonth => 'इस महीने पर वापस';

  @override
  String get calendarNothingThisYear => 'इस साल पर अभी कुछ नहीं है।';

  @override
  String calendarYearSummary(Object days, Object entries) {
    return '$days में $entries।';
  }

  @override
  String get folderNothingInIt => 'इसमें अभी कुछ नहीं है';

  @override
  String get onThisDayOneYear => 'आज से एक साल पहले';

  @override
  String onThisDayYears(Object years) {
    return 'आज से $years साल पहले';
  }

  @override
  String wheelYear(Object year) {
    return 'साल $year';
  }

  @override
  String get calendarBackToBrowsing => 'वापस पलटने पर';

  @override
  String get calendarToday => 'आज';

  @override
  String get calendarFirstEntry => 'आपकी पहली बात';

  @override
  String get calendarGoToThisDay => 'इस दिन पर जाइए';

  @override
  String get calendarDensityNote =>
      'रंग बताता है कि किसी दिन कितना है — कुछ नहीं से बहुत तक।';

  @override
  String get calendarLess => 'कम';

  @override
  String get calendarMore => 'ज़्यादा';

  @override
  String get calendarGoToToday => 'आज पर जाइए';

  @override
  String get backupTitle => 'बैकअप';

  @override
  String get vaultNothingToBackUp =>
      'इस तिजोरी में अभी बैकअप लेने लायक कुछ नहीं है।';

  @override
  String vaultChangedWhileBackingUp(Object name) {
    return 'बैकअप बनते समय कुछ बदल गया ($name)। फिर कोशिश करें।';
  }

  @override
  String get vaultTooSmall =>
      'यह फ़ाइल Lamplight का बैकअप होने के लिए बहुत छोटी है।';

  @override
  String get vaultNotALamplightFile => 'यह Lamplight की बैकअप फ़ाइल नहीं है।';

  @override
  String get vaultDamaged => 'यह फ़ाइल ख़राब है और खुल नहीं सकती।';

  @override
  String get vaultKeyringNewerVersion =>
      'यह तिजोरी Lamplight के किसी नए संस्करण से बनी है। खोलने के लिए ऐप अपडेट करें।';

  @override
  String get vaultKeyringDamaged =>
      'तिजोरी की चाबी वाली फ़ाइल ख़राब है और पढ़ी नहीं जा सकती। अगर आपके पास बैकअप फ़ाइल है, तो उससे वापस लाएँ।';

  @override
  String get vaultDatabaseNewerVersion =>
      'यह तिजोरी Lamplight के किसी नए संस्करण से बनी है। खोलने के लिए ऐप अपडेट करें — आपकी बातें सुरक्षित हैं और कुछ नहीं बदला गया है।';

  @override
  String phraseWrongLength(Object count) {
    return 'रिकवरी वाक्य 12 शब्दों का होता है। इसमें $count हैं।';
  }

  @override
  String phraseNotARecoveryWord(Object word) {
    return '\"$word\" रिकवरी शब्दों में से नहीं है।';
  }

  @override
  String get phraseDoesNotCheckOut =>
      'वे शब्द एक सही रिकवरी वाक्य नहीं बनाते। देखें कि कोई शब्द ग़लत टाइप या आगे-पीछे तो नहीं हो गया।';

  @override
  String get vaultNewerVersion =>
      'यह बैकअप Lamplight के किसी नए संस्करण से बना है। ऐप अपडेट करें, फिर कोशिश करें।';

  @override
  String get vaultUnknownCompression =>
      'यह बैकअप ऐसी सिकुड़न का इस्तेमाल करता है जिसे यह संस्करण पढ़ना नहीं जानता।';

  @override
  String get vaultDamagedTryOlder =>
      'यह फ़ाइल ख़राब है और खुल नहीं सकती। अगर आपके पास कोई पुराना बैकअप है, तो वह आज़माएँ।';

  @override
  String get vaultBeforeRecoveryPhrases =>
      'यह बैकअप उस समय का है जब बारह शब्दों से बैकअप फ़ाइल नहीं खुलती थी। इसका पासकोड ही इसे खोलने का एकमात्र रास्ता है।';

  @override
  String get vaultWordsDoNotOpenIt =>
      'वे शब्द इस फ़ाइल को नहीं खोलते। शायद वे किसी और तिजोरी के हैं।';

  @override
  String get vaultWrongPasscode => 'वह पासकोड इस फ़ाइल को नहीं खोलता।';

  @override
  String vaultMissingPart(Object name) {
    return 'इस बैकअप का एक हिस्सा गायब है ($name)।';
  }

  @override
  String vaultPartWrongSize(Object name) {
    return 'यह बैकअप ख़राब है ($name का आकार सही नहीं है)।';
  }

  @override
  String vaultPartDoesNotMatch(Object name) {
    return 'यह बैकअप ख़राब है ($name मेल नहीं खाता)।';
  }

  @override
  String get vaultNoVaultInside =>
      'इस बैकअप में कोई तिजोरी नहीं है। शायद यह किसी और ऐप ने बनाया हो।';

  @override
  String get vaultOutOfOrder =>
      'यह फ़ाइल ख़राब है: इसकी सामग्री क्रम से बाहर है।';

  @override
  String get vaultEndsPartWay =>
      'यह फ़ाइल ख़राब है: यह बीच में ही ख़त्म हो जाती है।';

  @override
  String vaultIncomplete(Object parts) {
    return 'यह फ़ाइल अधूरी है — इसमें इसके हिस्सों में से $parts हैं।';
  }

  @override
  String vaultWillNotOpen(Object name) {
    return 'इस बैकअप में कुछ ऐसा है जिसे Lamplight नहीं खोलेगा ($name)।';
  }

  @override
  String countEntries(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बातें',
      one: '1 बात',
    );
    return '$_temp0';
  }

  @override
  String countDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन',
      one: '1 दिन',
    );
    return '$_temp0';
  }

  @override
  String get backupCheckingItOpens => 'देख रहे हैं कि यह खुलती है…';

  @override
  String get backupCouldNotSave => 'बैकअप सहेजा नहीं जा सका।';

  @override
  String get backupNothingLost =>
      'कुछ भी नहीं खोया, और आपकी बातें जैसी थीं वैसी हैं। थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get backupLast => 'पिछला बैकअप';

  @override
  String get backupInTheVault => 'तिजोरी में';

  @override
  String get restoreCheckingFile => 'फ़ाइल जाँची जा रही है…';

  @override
  String get restoreCouldNotOpen => 'वह फ़ाइल नहीं खुल सकी।';

  @override
  String get restoreCheckItIsTheOne =>
      'देखें कि यह वही बैकअप है जो आप चाहते थे, और फिर कोशिश करें।';

  @override
  String get restorePuttingInPlace => 'इसे जगह पर रखा जा रहा है…';

  @override
  String get restorePuttingBack => 'आपकी पुरानी बातें वापस रखी जा रही हैं…';

  @override
  String get restoreCouldNotFinish => 'वापस लाना पूरा नहीं हो सका।';

  @override
  String get restoreBackAsTheyWere => 'आपकी बातें जैसी थीं वैसी वापस आ गई हैं।';

  @override
  String get restoreUsePasscodeInstead => 'इसके बजाय पासकोड इस्तेमाल करें';

  @override
  String get restoreUseWordsInstead => 'मेरे पास बारह शब्द हैं';

  @override
  String get backupCreateFile => 'बैकअप फ़ाइल बनाइए';

  @override
  String get backupCreatedChecked => 'बैकअप बन गया और जाँच भी लिया।';

  @override
  String get backupMakeAnother => 'एक और बनाइए';

  @override
  String get backupRestoreHeading => 'वापस लाइए';

  @override
  String get backupRestoreFrom => 'बैकअप फ़ाइल से वापस लाइए';

  @override
  String backupProgress(String stage, int percent) {
    return '$stage $percent प्रतिशत';
  }

  @override
  String get restoreTitle => 'वापस लाइए';

  @override
  String get restoreChooseFile => 'एक फ़ाइल चुनिए';

  @override
  String get restorePhraseHint => 'याद कहानी उद्योग…';

  @override
  String get restoreAction => 'वापस लाइए';

  @override
  String get restoreChooseDifferent => 'कोई और फ़ाइल चुनिए';

  @override
  String get importChooseFolder => 'एक फ़ोल्डर चुनिए';

  @override
  String get importChooseFiles => 'इसके बजाय फ़ाइलें चुनें';

  @override
  String get importChooseFilesNote =>
      'अगर Android आपका फ़ोल्डर स्वीकार नहीं करता — वह किसी भी ऐप को Downloads या स्टोरेज की जड़ नहीं देता — तो सीधे फ़ाइलें चुनें। इसे कभी मना नहीं किया जाता।';

  @override
  String get importLooking => 'फ़ोल्डर देख रहे हैं…';

  @override
  String get importNoTextFiles => 'उस फ़ोल्डर में कोई टेक्स्ट फ़ाइल नहीं है।';

  @override
  String get importChooseDifferentFolder => 'कोई और फ़ोल्डर चुनिए';

  @override
  String get importUseFileDate => 'इनके लिए फ़ाइल की अपनी तारीख़ लीजिए';

  @override
  String get importUseFileDateNote =>
      'इन्हें उस दिन पर रखता है जब फ़ाइल आख़िरी बार बदली गई थी। अक्सर वो उस दिन की बात नहीं होती।';

  @override
  String importBringIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बातें ले आइए',
      one: '1 बात ले आइए',
    );
    return '$_temp0';
  }

  @override
  String importProgress(int percent) {
    return 'ला रहे हैं, $percent प्रतिशत';
  }

  @override
  String get exportChooseFolder => 'फ़ोल्डर चुनकर बाहर लिखिए';

  @override
  String get exportWritten => 'आपकी कॉपी लिख दी गई।';

  @override
  String get exportAgain => 'फिर से बाहर लिखिए';

  @override
  String get exportWhichOne => 'मुझे कौन सी चाहिए?';

  @override
  String get exportNotLocked => 'यह कॉपी बंद नहीं है';

  @override
  String dayAddedThings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'आज में $count चीज़ें जोड़ीं।',
    );
    return '$_temp0';
  }

  @override
  String get entryAddNote => 'इस पर एक बात लिखिए';

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count जोड़ दिए।',
      one: 'जोड़ दिया।',
    );
    return '$_temp0';
  }

  @override
  String get importFolderUnreadable => 'वह फ़ोल्डर पढ़ा नहीं जा सका।';

  @override
  String get importNothingBrought => 'कुछ भी अंदर नहीं लाया गया।';

  @override
  String get importStoppedPartWay => 'डायरी अंदर लाना बीच में रुक गया।';

  @override
  String get importWhatArrivedKept =>
      'रुकने से पहले जो आ चुका था, वह सब रखा गया है।';

  @override
  String get importNoReadableDates =>
      'उन फ़ाइलों में से किसी में ऐसी तारीख़ नहीं है जिसे Lamplight पढ़ सके।';

  @override
  String importReadyToBring(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बातें लाने के लिए तैयार हैं।',
      one: '1 बात लाने के लिए तैयार है।',
    );
    return '$_temp0';
  }

  @override
  String get importNothingNew => 'लाने के लिए कुछ नया नहीं है।';

  @override
  String importBroughtIn(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बातें लाई गईं।',
      one: '1 बात लाई गई।',
    );
    return '$_temp0';
  }

  @override
  String importAlreadyHere(Object count) {
    return '$count पहले से यहीं थीं, इसलिए उन्हें वैसा ही छोड़ दिया गया।';
  }

  @override
  String importNoDateSkipped(Object count) {
    return '$count में पढ़ने लायक तारीख़ नहीं थी, इसलिए उन्हें छोड़ दिया गया।';
  }

  @override
  String importCouldNotRead(Object count, Object names) {
    return '$count पढ़ी नहीं जा सकीं: $names';
  }

  @override
  String get exportStarting => 'शुरू हो रहा है…';

  @override
  String get exportCouldNotFinish => 'पढ़ने लायक कॉपी पूरी नहीं हो सकी।';

  @override
  String get exportNothingChanged => 'Lamplight में कुछ नहीं बदला।';

  @override
  String get importVideoAlreadySmall =>
      'एक वीडियो पहले से ही जितना छोटा हो सकता था उतना था, इसलिए उसे वैसे ही रखा गया।';

  @override
  String get importVideoCouldNotShrink =>
      'एक वीडियो इस फ़ोन पर छोटा नहीं किया जा सका, इसलिए उसे पूरा रखा गया।';

  @override
  String importOneFailed(String reason) {
    return 'एक नहीं हो पाया: $reason';
  }

  @override
  String importAbandoned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lamplight बंद होने से पहले $count पूरे नहीं हो पाए।',
      one: 'Lamplight बंद होने से पहले एक पूरा नहीं हो पाया।',
    );
    return '$_temp0';
  }

  @override
  String get importNothingLeft => 'फ़ोन पर कुछ नहीं बचा।';

  @override
  String get nameCardAsk => 'यहाँ क्या लिखा हो?';

  @override
  String get nameCardHint => 'आपका नाम, या जो चाहें';

  @override
  String get reminderGroup => 'चाहें तो एक हल्की याद';

  @override
  String get reminderFooter =>
      'जब तक आप न चालू करें, बंद रहती है। यह कभी नहीं बताती कि आपके नोट में क्या है — बता ही नहीं सकती, क्योंकि यह तिजोरी बंद रहते चलती है। न कोई सिलसिला, न गिनती, न उन दिनों की बात जो छूट गए।';

  @override
  String get reminderTitle => 'लिखने की याद दिलाइए';

  @override
  String get reminderWhen => 'कब';

  @override
  String get reminderProblemNotAllowed =>
      'Lamplight को सूचनाएँ भेजने की अनुमति नहीं है।';

  @override
  String get reminderProblemNotificationsOff =>
      'इस फ़ोन की सेटिंग में Lamplight की सूचनाएँ बंद हैं।';

  @override
  String get reminderProblemRemindersOff =>
      'इस फ़ोन की सूचना सेटिंग में Lamplight की याद दिलाने वाली सूचनाएँ बंद हैं।';

  @override
  String get reminderProblemBatterySaving =>
      'यह फ़ोन बैटरी बचाने के लिए Lamplight को रोक रहा है। याद देर से आने या कभी न आने की आम वजह यही है।';

  @override
  String get reminderMayNotArrive => 'शायद याद न आए';

  @override
  String get backupAutomatic => 'अपने आप बैकअप';

  @override
  String get backupAutomaticDidNotFinish =>
      'अपने आप होने वाला बैकअप पूरा नहीं हुआ।';

  @override
  String get backupNothingYet => 'अभी बैकअप लेने लायक कुछ नहीं है।';

  @override
  String get backupInProgress => 'बैकअप लिया जा रहा है…';

  @override
  String get backupStartsAtUnlock => 'अगली बार खोलने पर शुरू होगा।';

  @override
  String get backupDoneAutomatically => 'अपने आप बैकअप हो गया।';

  @override
  String get backupLastOneFailed =>
      'पिछला अपने आप होने वाला बैकअप पूरा नहीं हुआ। अगली बार Lamplight खोलने पर यह फिर कोशिश करेगा।';

  @override
  String importNthOf(Object index, Object total) {
    return '$total में से $index';
  }

  @override
  String importWaiting(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count इंतज़ार में',
      one: '1 इंतज़ार में',
    );
    return '$_temp0';
  }

  @override
  String get aboutCopied => 'कॉपी हो गया';

  @override
  String get failureGeneric => 'वह नहीं हो सका।';

  @override
  String get failureNothingLost => 'कुछ नहीं खोया — फिर कोशिश करें।';

  @override
  String get calendarNothingOnDay => 'कुछ नहीं';

  @override
  String get backupChangeFolder => 'फ़ोल्डर बदलिए';

  @override
  String backupSavedTo(String place) {
    return '$place में सहेजा जाता है';
  }

  @override
  String get backupUseDefaultFolder => 'सामान्य फ़ोल्डर इस्तेमाल कीजिए';

  @override
  String get backupChooseFolder => 'कॉपियाँ रखने के लिए एक फ़ोल्डर चुनें';

  @override
  String get folderAndroidRestriction =>
      'Android किसी भी ऐप को Downloads या पूरा इंटरनल स्टोरेज नहीं देने देता। Documents, या उसके अंदर का कोई फ़ोल्डर, चलेगा।';

  @override
  String get folderNotWritable =>
      'उस फ़ोल्डर में कुछ भी सहेजा नहीं जा सकता। कोई दूसरा चुनें।';

  @override
  String get folderRefused => 'वह फ़ोल्डर इस्तेमाल नहीं हो सका।';

  @override
  String get folderTryAnother => 'कोई दूसरा चुनकर देखें।';

  @override
  String get aboutHowKept => 'आपके नोट कैसे रखे जाते हैं';

  @override
  String get aboutFonts => 'फ़ॉन्ट और लाइसेंस';

  @override
  String get aboutVersion => 'वर्शन';

  @override
  String get aboutNoBrowser => 'इस फ़ोन का कोई ऐप लिंक नहीं खोल सकता।';

  @override
  String get aboutMadeBy => 'बनाया';

  @override
  String get aboutMadeBySemantic =>
      'ProbablyPiyush ने बनाया। आपके ब्राउज़र में LinkedIn खोलेगा।';

  @override
  String get aboutCoffee => 'मुझे एक कॉफ़ी पिलाइए';

  @override
  String get aboutCoffeeSemantic =>
      'मुझे एक कॉफ़ी पिलाइए। ब्राउज़र में एक पन्ना खोलेगा।';

  @override
  String get aboutCopyDetails => 'ब्योरा कॉपी कीजिए';

  @override
  String settingsNameSemantic(Object name) {
    return '$name. बदलने के लिए टैप करें।';
  }

  @override
  String get settingsAddName => 'अपना नाम जोड़ें';

  @override
  String get settingsNameOnlyHere => 'सिर्फ़ इसी फ़ोन पर';

  @override
  String get settingsNameOptional =>
      'ज़रूरी नहीं। यह हमेशा सिर्फ़ इसी फ़ोन पर रहेगा।';

  @override
  String get reminderTurnedOffByAndroid =>
      'Android में Lamplight के लिए सूचनाएँ बंद हैं। आप उन्हें फ़ोन की सेटिंग में, Apps के नीचे चालू कर सकते हैं।';

  @override
  String get reminderOnceADay => 'दिन में एक बार';

  @override
  String reminderTodayAt(Object time) {
    return 'आज $time बजे';
  }

  @override
  String reminderYesterdayAt(Object time) {
    return 'कल $time बजे';
  }

  @override
  String reminderOnDateAt(Object date, Object time) {
    return '$date को $time बजे';
  }

  @override
  String get reminderNoneYet => 'अभी तक कुछ नहीं आया';

  @override
  String reminderLastArrived(Object when) {
    return 'पिछली बार $when आया था';
  }

  @override
  String reminderNextDue(Object when) {
    return 'अगला $when आना है';
  }

  @override
  String get aboutHide => 'छिपाएँ';

  @override
  String get aboutCheckReal => 'देखें कि यह असली Lamplight है';

  @override
  String get entryRevisionsNote => 'बदलने से पहले यहाँ क्या था';

  @override
  String get entryStaysOnDay => 'यह इसी दिन पर भी रहेगा';

  @override
  String entryDeleteKind(String kind) {
    return '$kind मिटाइए';
  }

  @override
  String get shareCouldNotAdd =>
      'यह जोड़ा नहीं जा सका। इसे सहेजकर फ़ोटो वाले बटन से आज़माइए।';

  @override
  String get openNothingCanOpen =>
      'इस फ़ोन में ऐसी फ़ाइल खोलने वाला कुछ नहीं है।';

  @override
  String get viewerMore => 'और';

  @override
  String get docLeavesLamplight => 'यह Lamplight से बाहर जाता है';

  @override
  String get docKeepItHere => 'यहीं रहने दीजिए';

  @override
  String get docOpenWith => 'इससे खोलिए…';

  @override
  String docCannotShow(String kind) {
    return 'Lamplight, PDF, तस्वीरें और लिखा हुआ दिखा सकता है — और वो भी आपके फ़ोन पर बिना ताले के रखे बिना। $kind फ़ाइल के लिए कोई और ऐप चाहिए — Lamplight उसे तब तक उधार दे सकता है जब तक आप पढ़ रहे हैं, और बाद में वापस ले लेता है।';
  }

  @override
  String get menuOpenWithNote => 'कोई और ऐप, बिना कॉपी रखे';

  @override
  String menuSaveKind(String kind) {
    return '$kind सहेजिए';
  }

  @override
  String get menuTrashNote => '30 दिन रखी जाती है, फिर चली जाती है';

  @override
  String get videoBackTen => 'दस सेकंड पीछे';

  @override
  String get videoForwardTen => 'दस सेकंड आगे';

  @override
  String get photoPlayVideo => 'यह वीडियो चलाइए';

  @override
  String get lockPhraseHint => 'आपके बारह शब्द, बीच में जगह छोड़कर';

  @override
  String get lockUnlock => 'खोलिए';

  @override
  String get errorScreenDidNotOpen => 'वो पन्ना नहीं खुला। कुछ खोया नहीं है।';

  @override
  String get errorGoBack => 'वापस जाइए';

  @override
  String recordingCannot(String what) {
    return 'यह फ़ोन रिकॉर्डिंग $what नहीं करेगा। रिकॉर्डिंग अब भी चल रही है।';
  }

  @override
  String get recordingClose => 'बंद कीजिए';

  @override
  String recordingElapsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'रिकॉर्ड हो रहा है, $count सेकंड',
      one: 'रिकॉर्ड हो रहा है, $count सेकंड',
    );
    return '$_temp0';
  }

  @override
  String get recordingStopKeep => 'रोककर यह रिकॉर्डिंग रख लीजिए';

  @override
  String get recordingDiscard => 'छोड़ दीजिए';

  @override
  String get recordingCouldNotStart => 'रिकॉर्डिंग शुरू नहीं हो सकी।';

  @override
  String get recordingCheckMicrophone =>
      'देखें कि Lamplight को माइक्रोफ़ोन इस्तेमाल करने की अनुमति है या नहीं।';

  @override
  String get recordingStartAgain => 'फिर से शुरू';

  @override
  String get recordingCouldNotSave => 'वह रिकॉर्डिंग सहेजी नहीं जा सकी।';

  @override
  String get recordingStillHere => 'यह अब भी यहीं है — दोबारा रोककर देखें।';

  @override
  String get recordingCarryOnSemantic => 'रिकॉर्डिंग जारी रखें';

  @override
  String get recordingPauseSemantic => 'इस रिकॉर्डिंग को रोकें';

  @override
  String get recordingCarryOn => 'जारी रखें';

  @override
  String get recordingPause => 'रोकें';

  @override
  String get sizeAdd => 'जोड़िए';

  @override
  String get transcribeTitle => 'जो कहा जाए वो लिख लीजिए';

  @override
  String get transcribeOn =>
      'आवाज़ के नोट खोजे जा सकेंगे। कुछ भी कहीं नहीं भेजा जाता।';

  @override
  String get transcribeOff =>
      'बंद है। आवाज़ के नोट सिर्फ़ अपने दिन से मिलेंगे।';

  @override
  String get transcribeLanguage => 'बोलने की ज़बान';

  @override
  String get transcribeLanguageNote =>
      'आप अपनी रिकॉर्डिंग में जिस ज़बान में बोलते हैं। एक बार में एक ही — जो वाक्य बीच में ज़बान बदल दे, वो उतना ही वापस आता है जितना इससे मेल खाता है।';

  @override
  String get transcribeNotDownloaded =>
      'इस फ़ोन पर अभी डाउनलोड नहीं है — लाने के लिए टैप कीजिए।';

  @override
  String transcribeGetBetter(String name) {
    return '$name के लिए बेहतर मॉडल लाइए';
  }

  @override
  String get transcribeGetBetterNote =>
      'इससे लिखाई काफ़ी ज़्यादा सही आती है। डाउनलोड आपका फ़ोन करता है, Lamplight नहीं, और एक ही बार होता है।';

  @override
  String get transcribeNoLanguages => 'इस फ़ोन ने अभी कोई ज़बान नहीं बताई।';

  @override
  String get transcribeNeedsDownloading => 'डाउनलोड करना होगा';

  @override
  String folderStill(String day, String folder) {
    return '$day पर ही है। $folder में भी।';
  }

  @override
  String get folderRenameTitle => 'फ़ोल्डर का नाम बदलिए';

  @override
  String get folderNameHint => 'कोई इंसान, कोई जगह, कोई दौर';

  @override
  String get voicePlay => 'यह आवाज़ का नोट सुनिए';

  @override
  String get voiceForwardThirty => 'तीस सेकंड आगे';

  @override
  String voiceSpeed(String speed) {
    return 'रफ़्तार, अभी $speed गुना';
  }

  @override
  String get voiceLengthUnknown => 'आवाज़ का नोट, चलने तक लंबाई पता नहीं';

  @override
  String get voicePosition => 'रिकॉर्डिंग में जगह';

  @override
  String get voiceOpening => 'रिकॉर्डिंग खुल रही है';

  @override
  String get voiceNoWords => 'कोई शब्द वापस नहीं आया — फिर कोशिश कीजिए';

  @override
  String get voiceWriteThis => 'इसे लिख लीजिए';

  @override
  String get voiceCannotWrite => 'यह फ़ोन आवाज़ के नोट नहीं लिख सकता।';

  @override
  String get voiceLanguageMissing => 'इस फ़ोन ने वो ज़बान अभी डाउनलोड नहीं की।';

  @override
  String get voiceWriting => 'लिखा जा रहा है…';

  @override
  String get voiceWaiting => 'लिखे जाने का इंतज़ार है।';

  @override
  String get voiceWritten => 'इसी फ़ोन पर लिख लिया गया।';

  @override
  String get errorPartNotShown => 'यह हिस्सा दिखाया नहीं जा सका।';

  @override
  String get errorScreenShort => 'वो पन्ना नहीं खुला।';

  @override
  String get errorNothingLost =>
      'कुछ खोया नहीं है। आपने जो लिखा है, सब तिजोरी में वैसा ही है।';

  @override
  String get errorHideDetails => 'तकनीकी ब्योरा छिपाइए';

  @override
  String get errorShowDetails => 'तकनीकी ब्योरा दिखाइए';

  @override
  String get errorDetailsNote =>
      'जो कॉपी होगा, बस इतना ही। इसमें लिखा है कि क्या टूटा और कोड में कहाँ — इसमें आपका लिखा हुआ कुछ भी नहीं है।';

  @override
  String get passcodeChangeFailed => 'पासकोड बदला नहीं जा सका।';

  @override
  String get passcodeOldStillWorks => 'आपका पुराना पासकोड अब भी चलता है।';

  @override
  String get passcodeChanged => 'पासकोड बदल गया';

  @override
  String get passcodeWordsUnchanged =>
      'आपके बारह शब्द नहीं बदले, और नए की ज़रूरत भी नहीं। वो आपकी तिजोरी और आपकी बैकअप फ़ाइलें पहले की तरह ही खोलते हैं।';

  @override
  String get passcodeOldBackups =>
      'जो बैकअप पहले से हैं, वो पुराने पासकोड से ही खुलेंगे। अब जो नया बनेगा, वो नए पासकोड से।';

  @override
  String get passcodeMakeBackup => 'अभी एक बैकअप बना लीजिए';

  @override
  String get passcodeCurrent => 'अभी वाला पासकोड';

  @override
  String get passcodeNewAgain => 'नया दोबारा';

  @override
  String get passcodeOldBackupsNote =>
      'जो बैकअप फ़ाइलें आप पहले बना चुके हैं, वो पुराने पासकोड से ही खुलेंगी।';

  @override
  String get passcodeWordsNote => 'आपके बारह शब्द नहीं बदलते और चलते रहते हैं।';

  @override
  String get licencesFonts =>
      'यहाँ हर टाइपफ़ेस SIL Open Font License के तहत है। कुछ भी डाउनलोड नहीं होता — ये ऐप के अंदर ही हैं।';

  @override
  String get licencesSource =>
      'Lamplight ख़ुद GPL-3.0 पर है, ऐप-स्टोर की एक छूट के साथ। सोर्स ही लाइसेंस है: कोई भी इसे पढ़कर जाँच सकता है कि ऐप वही करता है जो यह पन्ना कहता है।';

  @override
  String get licencesUnreadable => 'वो लाइसेंस फ़ाइल पढ़ी नहीं जा सकी।';

  @override
  String get appearanceSample =>
      'पूरी दोपहर बारिश। चाय बनाई, आधा अध्याय पढ़ा, जो कहना था वो भूल गया और यह लिख दिया।';

  @override
  String get appearanceChromeNote => 'बटन और लेबल ऐसे ही रहेंगे';

  @override
  String get appearanceSizeNote =>
      'यह आपके फ़ोन के अपने टेक्स्ट साइज़ के ऊपर लगता है, तो अगर आपने वहाँ पहले ही बढ़ा रखा है, तो यह और आगे जाएगा।';

  @override
  String get voicePause => 'रोकिए';

  @override
  String get importIntro =>
      'अगर आपने कहीं और डायरी लिखी है, तो Lamplight उसे ले आ सकता है — बशर्ते वो टेक्स्ट फ़ाइलें हों और नाम में तारीख़ हो।';

  @override
  String get importHowDates =>
      'यह सादी टेक्स्ट फ़ाइलें पढ़ता है और नाम में तारीख़ ढूँढता है — 2026-08-24, या 24 अगस्त 2026 — फ़ाइल के नाम में या ऊपर की फ़ोल्डरों में कहीं भी।';

  @override
  String get importAmbiguousDates =>
      '03-04-2026 जैसी तारीख़ें जानबूझकर छोड़ दी जाती हैं। कुछ देशों में यह तीन अप्रैल है और कुछ में चार मार्च, और ग़लत अंदाज़ा आपकी ज़िंदगी का एक साल ग़लत दिनों पर रख देगा, वो भी बिना बताए।';

  @override
  String get importFormats =>
      'Lamplight सादा टेक्स्ट पढ़ता है: .txt, .md, .org, .log और दूसरे, वो फ़ाइलें भी जिनका कोई एक्सटेंशन ही नहीं। अगर आपकी डायरी किसी और फ़ॉर्मैट में है, तो पहले उसे टेक्स्ट में निकाल लीजिए।';

  @override
  String get importAtStartOfDay =>
      'ये हर दिन की शुरुआत में बैठेंगे, क्योंकि फ़ाइल का नाम तारीख़ बताता है, वक़्त नहीं। Lamplight में जो पहले से है, वो न बदलेगा न हटेगा, और यह दो बार चलाने से कॉपियाँ नहीं बनेंगी।';

  @override
  String get importFileDateNote =>
      'इन्हें उस दिन पर रखता है जब फ़ाइल आख़िरी बार बदली गई थी। अगर फ़ोल्डर एक डिवाइस से दूसरे पर कॉपी हुई है, तो वो कॉपी होने का दिन हो सकता है, लिखने का नहीं।';

  @override
  String get importSkippedNote =>
      'ये छोड़ दी जाएँगी। ये जहाँ हैं वहीं रहेंगी — आपकी फ़ोल्डर से कुछ भी हटाया या मिटाया नहीं जाता।';

  @override
  String get restoreChooseNote =>
      'अपनी बैकअप फ़ाइल चुनिए। उसका नाम कुछ ऐसा होगा: Lamplight-2026-08-18.vault।';

  @override
  String get restorePasscodeNote =>
      'इस फ़ाइल का पासकोड लिखिए — वही जो बैकअप बनाते वक़्त लगा था।';

  @override
  String get restoreWordsNote =>
      'बारहों शब्द, क्रम से, बीच में जगह छोड़कर लिखिए।';

  @override
  String get restoreDoNotClose =>
      'जब तक यह पूरा न हो जाए, Lamplight बंद मत कीजिए।';

  @override
  String get exportIntro =>
      'यह Lamplight का सब कुछ आपकी चुनी हुई फ़ोल्डर में सादी फ़ाइलों की तरह लिख देता है — हर दिन की एक टेक्स्ट फ़ाइल, और हर फ़ोटो, वीडियो, आवाज़ का नोट और दस्तावेज़ अपने नाम से।';

  @override
  String get exportNoLamplightNeeded =>
      'उस फ़ोल्डर में कुछ भी खोलने के लिए Lamplight की ज़रूरत नहीं। अगर कभी यह ऐप चलना बंद कर दे, या आप इस्तेमाल छोड़ दें, तो भी आपके नोट हर उस चीज़ में खुलेंगे जो टेक्स्ट पढ़ती है।';

  @override
  String get exportWhichOneBody =>
      'पढ़ने लायक़ कॉपी पढ़ने के लिए है, किसी और ऐप में ले जाने के लिए, या Lamplight छोड़ने के बाद कुछ रख लेने के लिए। यह सुरक्षित नहीं होती।\n\nबैकअप फ़ाइल Lamplight को हूबहू वापस लाने के लिए है — नया फ़ोन, या टूटा हुआ फ़ोन। यह आपके पासकोड से बंद रहती है, इसलिए इसे कहीं भी रखा जा सकता है, क्लाउड में भी।\n\nज़्यादातर लोगों को बैकअप ही चाहिए। अगर पक्का करना है कि कभी अटकें नहीं, तो पढ़ने लायक़ कॉपी भी बना लीजिए।';

  @override
  String get exportNotLockedBody =>
      'इस पर कोई पासकोड नहीं होता। जो भी उस फ़ोल्डर को खोलेगा, सब पढ़ सकेगा। इसे वहीं रखिए जहाँ आपको यह मंज़ूर हो — और अगर सिर्फ़ कुछ सुरक्षित रखना है, तो बैकअप इस्तेमाल कीजिए।';

  @override
  String get backupConfirmNote =>
      'अपना पासकोड दोबारा दीजिए। यह फ़ाइल सब कुछ खोल सकती है, इसलिए इसे बनाना सोच-समझकर होना चाहिए।';

  @override
  String get backupKeepSafeNote =>
      'आपका बैकअप उसी पासकोड से बंद है जो अभी आपका है। इसे वहीं रखिए जिस पर भरोसा हो — क्लाउड भी ठीक है, क्योंकि उस पासकोड के बिना फ़ाइल पढ़ी ही नहीं जा सकती। हम उसे कभी नहीं देखते।';

  @override
  String get backupRestoreWarning =>
      'बैकअप खोलने से Lamplight में अभी जो कुछ है, सब बदल जाएगा। आपके अभी वाले नोट तब तक अलग रखे जाते हैं जब तक यह साबित न हो जाए कि वापस लाए गए नोट खुल रहे हैं।';

  @override
  String get folderWhatItIs =>
      'फ़ोल्डर एक धागा है जो आपके दिनों में से गुज़रता है — कोई एक इंसान, कोई एक जगह, कोई एक दौर।';

  @override
  String get folderNothingMoves =>
      'फ़ोल्डर में कुछ जाता नहीं है। बात अपने दिन पर ही रहती है और यहाँ भी दिख जाती है।';

  @override
  String get folderDeleteNote =>
      'फ़ोल्डर चला जाता है। उसमें जो कुछ था, वो जहाँ था वहीं रहता है, अपने ही दिन पर।';

  @override
  String get folderNoneInHere =>
      'यहाँ अभी कुछ नहीं है। किसी दिन पर कुछ देर दबाकर रखिए और “फ़ोल्डर में जोड़िए” चुनिए।';

  @override
  String get passcodeRuleLength => 'आठ या ज़्यादा अक्षर।';

  @override
  String get passcodeRuleWords =>
      'कुछ आम शब्द जो आपको याद रहें, चिह्नों वाले छोटे पासकोड से बेहतर हैं।';

  @override
  String get passcodeNoMatch => 'अभी ये दोनों एक जैसे नहीं हैं।';

  @override
  String get docCopyInClear =>
      'कॉपी बिना ताले के लिखी जाती है, तो जो भी ऐप आपकी फ़ाइलें पढ़ सकता है वो इसे भी पढ़ लेगा। Lamplight के अंदर जो रहता है, वो दोनों हाल में बंद ही रहता है।';

  @override
  String docPageOf(String page, String total) {
    return '$total में से $page';
  }

  @override
  String get transcribeTookTooLong =>
      'उस रिकॉर्डिंग को लिखने में बहुत समय लग रहा था, इसलिए Lamplight ने इंतज़ार करना बंद कर दिया। यह बाद में फिर कोशिश करेगा।';

  @override
  String get transcribeCouldNotWriteDown =>
      'उस रिकॉर्डिंग को लिखा नहीं जा सका।';

  @override
  String get transcribeRecordingIsSafe =>
      'रिकॉर्डिंग ख़ुद सुरक्षित है। Lamplight फिर कोशिश करेगा।';

  @override
  String voicePositionSpoken(Object at, Object total) {
    return '$total में से $at';
  }

  @override
  String entryEditedAt(Object time) {
    return '$time · बदला गया';
  }

  @override
  String get docCouldNotOpen => 'वह दस्तावेज़ नहीं खुल सका।';

  @override
  String albumThisOne(Object thing) {
    return 'यह $thing';
  }

  @override
  String albumThisOneOf(Object index, Object thing, Object total) {
    return 'यह $thing — $total में से $index';
  }

  @override
  String get albumCaptionThese => 'इन पर कुछ लिखें';

  @override
  String get albumCaptionThis => 'कुछ लिखें';

  @override
  String get albumCaptionEdit => 'लिखा हुआ बदलें';

  @override
  String albumOthersStay(Object count) {
    return 'बाकी $count यहीं रहेंगे। यह 30 दिन के लिए कूड़ेदान में जाएगा।';
  }

  @override
  String get albumGoesToTrash => 'यह 30 दिन के लिए कूड़ेदान में जाएगा।';

  @override
  String get photoCouldNotOpen => 'यह तस्वीर नहीं खुल सकी।';

  @override
  String get photoMayBeDamaged => 'हो सकता है यह ख़राब हो गई हो।';

  @override
  String get docTooBig =>
      'यह Lamplight के अंदर खोलने के लिए बहुत बड़ी है। आप एक कॉपी सहेजकर उसे कहीं और खोल सकते हैं।';

  @override
  String docPages(Object count) {
    return '$count पेज';
  }

  @override
  String get docFileEmpty => 'यह फ़ाइल ख़ाली है।';

  @override
  String videoTooBig(Object size) {
    return 'यह वीडियो Lamplight में यहाँ चलाने के लिए बहुत बड़ा है — $size। इसके लिए इसे बिना सुरक्षा के बाहर नहीं लिखा जाएगा। कहीं और देखने के लिए एक कॉपी सहेजें।';
  }

  @override
  String get videoNotAvailableHere =>
      'ऐप का यह हिस्सा इस फ़ोन पर उपलब्ध नहीं है।';

  @override
  String get videoCouldNotOpen => 'यह वीडियो नहीं खुल सका।';

  @override
  String get docGoToPage => 'किसी पेज पर जाएँ';

  @override
  String get docGo => 'जाएँ';

  @override
  String get docPageCouldNotBeDrawn => 'यह पेज नहीं बन सका।';

  @override
  String get passcodeRuleStronger =>
      'एक-दो शब्द और जोड़ दें तो अंदाज़ा लगाना कहीं मुश्किल हो जाएगा।';

  @override
  String get backupAutoFooter =>
      'अपने आप बैकअप तब चलता है जब आप Lamplight खोलते हैं, बशर्ते पिछली बार से कुछ बदला हो। यह आपके पासकोड से बंद रहता है, बिल्कुल वैसे ही जैसे आपका ख़ुद बनाया हुआ।';

  @override
  String get aboutHowKeptBody =>
      'कोई खाता नहीं। कोई सर्वर नहीं। कुछ भी इस फ़ोन से बाहर नहीं जाता।\n\nआपके नोट आपके पासकोड से बंद रहते हैं, और चाबी उसी से बनती है — इसलिए उसकी कोई प्रति कहीं नहीं है, हमारे पास भी नहीं।';

  @override
  String get aboutFree =>
      'Lamplight मुफ़्त है और हमेशा रहेगा। खोलने के लिए कुछ भी नहीं है।';

  @override
  String get backupOnItsOwn => 'अपने आप';

  @override
  String get actionDismiss => 'हटा दीजिए';

  @override
  String importRange(String from, String to) {
    return '$from से $to तक।';
  }

  @override
  String get sizeOneCopy =>
      'Lamplight एक ही प्रति रखता है। यहाँ आप जो चुनेंगे, वही आपके पास रहेगा।';

  @override
  String get sizeAddAlways => 'जोड़िए, और दोबारा मत पूछिए';

  @override
  String get trashNothingHere => 'यहाँ कुछ नहीं है।';

  @override
  String get appearanceAaQuiet => 'Aa\nशांत';

  @override
  String lockWarnSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'क़रीब $count सेकंड में बंद हो जाएगा।',
      one: 'क़रीब एक सेकंड में बंद हो जाएगा।',
    );
    return '$_temp0';
  }

  @override
  String get lockWarnChange => 'इसे ताला और सुरक्षा में बदलिए।';

  @override
  String get openingLabel => 'Lamplight खुल रहा है';

  @override
  String get recordingNoMic =>
      'Lamplight माइक्रोफ़ोन इस्तेमाल नहीं कर सकता। आप इसे फ़ोन की सेटिंग में, ऐप्स के नीचे, चालू कर सकते हैं।';

  @override
  String get recordingPaused => 'रुका हुआ है। अभी कुछ सुना नहीं जा रहा।';

  @override
  String get videoOpening => 'वीडियो खुल रहा है…';

  @override
  String albumRemoveThis(String thing) {
    return '$thing हटाइए';
  }

  @override
  String get revisionsNote =>
      'बदलने से पहले यहाँ क्या था। यहाँ कुछ भी बटन नहीं है — आप शब्द चुनकर कॉपी कर सकते हैं।';

  @override
  String get composerSemantic => 'इस दिन के लिए कुछ लिखिए';

  @override
  String importStripAdding(String name) {
    return '$name जोड़ा जा रहा है';
  }

  @override
  String passcodeAtLeast(int count) {
    return 'कम से कम $count अक्षर';
  }

  @override
  String get searchKindAll => 'सब कुछ';

  @override
  String get searchKindWords => 'शब्द';

  @override
  String get searchKindVoice => 'आवाज़';

  @override
  String get searchKindPhotos => 'फ़ोटो';

  @override
  String get searchKindFiles => 'फ़ाइलें';

  @override
  String passcodeAtLeastShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'कम से कम $count अक्षर',
      one: 'कम से कम 1 अक्षर',
    );
    return '$_temp0';
  }

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन बाक़ी',
      one: '1 दिन बाक़ी',
    );
    return '$_temp0';
  }

  @override
  String get trashGoneToday => 'आज चला जाएगा';

  @override
  String restoreMadeOn(String date) {
    return '$date को बनाया';
  }

  @override
  String restoreDone(String entries, String days) {
    return '$days में $entries वापस आ गईं। फिर से स्वागत है।';
  }

  @override
  String importFoundUndated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count जिनकी तारीख़ Lamplight नहीं पढ़ सका',
      one: '1 जिसकी तारीख़ Lamplight नहीं पढ़ सका',
    );
    return '$_temp0';
  }

  @override
  String entrySemantic(String time) {
    return '$time की बात। बदलने के लिए टैप कीजिए।';
  }

  @override
  String entrySemanticEdited(String time) {
    return '$time की बात, बदली हुई। बदलने के लिए टैप कीजिए।';
  }

  @override
  String onThisDaySemantic(String when, String body) {
    return '$when। $body। उस दिन पर जाने के लिए टैप कीजिए।';
  }

  @override
  String attachmentSemantic(String what, String time) {
    return '$time के $what। खोलने के लिए दो बार टैप कीजिए।';
  }

  @override
  String dayHeaderToday(String date) {
    return '$date, आज';
  }

  @override
  String get yearGridNothing => 'इस दिन कुछ नहीं';

  @override
  String get calendarNothing => 'इस दिन कुछ नहीं';

  @override
  String importStripCounted(String name, String counted) {
    return '$name जोड़ा जा रहा है$counted';
  }

  @override
  String get aboutFingerprintBody =>
      'हर बिल्ड पर एक दस्तख़त होता है जो सिर्फ़ उसका बनाने वाला बना सकता है। यह उसी कॉपी का है जो आपके पास है। इसे सोर्स के साथ छपे फ़िंगरप्रिंट से मिलाइए — अगर दोनों एक हैं, तो यही वो ऐप है जो उस सोर्स से बनता है।';

  @override
  String get searchKindVideo => 'वीडियो';

  @override
  String get semanticOn => 'चालू';

  @override
  String andMore(int count) {
    return 'और $count और';
  }

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बातें',
      one: '1 बात',
      zero: 'कुछ नहीं',
    );
    return '$_temp0';
  }

  @override
  String get checkDone => 'हो गया';

  @override
  String get checkNotYet => 'अभी नहीं';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन',
      one: '1 दिन',
    );
    return '$_temp0';
  }

  @override
  String get lockUseYourPasscode => 'अपना पासकोड इस्तेमाल करें।';

  @override
  String get searchWordsExample => 'जो कुछ भी आपने लिखा है';

  @override
  String get searchAFile => 'एक फ़ाइल';

  @override
  String get searchFileExample => 'scan.pdf · IMG_2831';

  @override
  String get searchAFolder => 'एक फ़ोल्डर';

  @override
  String get searchFolderExample => 'जो नाम आपने दिया है';

  @override
  String get searchByFileName => 'फ़ाइल के नाम से';

  @override
  String get searchARecording => 'एक रिकॉर्डिंग';

  @override
  String get searchAnEntry => 'एक प्रविष्टि';

  @override
  String get sizeThisOne => 'इसे';

  @override
  String get sizeTheseOnes => 'इन्हें';

  @override
  String get passcodeOneMoreCharacter => 'एक और अक्षर।';

  @override
  String passcodeMoreCharacters(int count, int minimum) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count और अक्षर — कम से कम $minimum।',
      one: '1 और अक्षर — कम से कम $minimum।',
    );
    return '$_temp0';
  }

  @override
  String get passcodeTooObvious =>
      'यह पहली चीज़ों में से है जो कोई भी आज़माएगा। कुछ और चुनें।';

  @override
  String get passcodeSameCharacter => 'यह एक ही अक्षर बार-बार है।';

  @override
  String get passcodeStraightRun => 'यह अक्षरों का सीधा क्रम है।';

  @override
  String attachmentLoading(String time) {
    return '$time पर संलग्नक, लोड हो रहा है';
  }

  @override
  String videoSemantic(String time, String length) {
    return '$time पर वीडियो, $length. देखने के लिए दो बार टैप करें।';
  }

  @override
  String voiceSemantic(String time, String length) {
    return '$time पर आवाज़ नोट, $length. सुनने के लिए दो बार टैप करें।';
  }

  @override
  String fileSemantic(String time, String name, String size) {
    return '$time पर फ़ाइल, $name, $size. खोलने के लिए दो बार टैप करें।';
  }

  @override
  String get lengthUnknown => 'अवधि अज्ञात';

  @override
  String get settingsLockNone => 'कोई स्वतः-लॉक नहीं';

  @override
  String settingsLockAfter(String duration) {
    return '$duration बाद';
  }

  @override
  String settingsSecuritySummary(String lock) {
    return 'पासकोड, फ़िंगरप्रिंट, $lock';
  }

  @override
  String get keptNoNetworkTitle => 'यह कहीं नहीं जाता';

  @override
  String get keptNoNetworkBody =>
      'Lamplight इंटरनेट का उपयोग नहीं कर सकता। «करता नहीं» नहीं — «कर ही नहीं सकता»: Android उसे अनुमति ही नहीं देता, और आप यह खुद अपने फ़ोन की ऐप सेटिंग में लगभग तीस सेकंड में जाँच सकते हैं।';

  @override
  String get keptPasscodeTitle => 'आपका पासकोड ही चाबी है';

  @override
  String get keptPasscodeBody =>
      'आपके नोट खोलने वाली चाबी हर बार अनलॉक करते समय आपके पासकोड से बनती है। यह कहीं संग्रहीत नहीं होती, इसलिए इसकी कोई प्रति नहीं है जिसे खोजा जा सके, खोया जा सके, या सौंपा जा सके।';

  @override
  String get keptForgetTitle => 'अगर आप इसे भूल जाएँ';

  @override
  String get keptForgetBody =>
      'आपके बारह शब्द ही अंदर आने का दूसरा और एकमात्र रास्ता हैं। यहाँ कोई पासकोड रीसेट नहीं कर सकता, और यह ऊपर वाली बात ही है — जो ऐप आपको वापस अंदर आने दे सकता है, वह किसी और को भी अंदर आने दे सकता है।';

  @override
  String get keptNothingReadableTitle => 'पढ़ने लायक कुछ भी इधर-उधर नहीं छूटता';

  @override
  String get keptNothingReadableBody =>
      'फ़ोटो, रिकॉर्डिंग और फ़ाइलें स्टोरेज तक पहुँचने से पहले ही एन्क्रिप्ट हो जाती हैं। कुछ भी कभी खुले रूप में नहीं लिखा जाता — तब भी नहीं, जब आप उसे देख रहे हों।';

  @override
  String get keptLocksItselfTitle => 'यह खुद को लॉक कर लेता है';

  @override
  String get keptLocksItselfBody =>
      'जिस क्षण Lamplight पृष्ठभूमि में जाता है, चाबियाँ नष्ट हो जाती हैं। स्क्रीनशॉट रोक दिए जाते हैं और ऐप हाल के ऐप्स की झलक में दिखाई नहीं देता।';

  @override
  String get keptBackUpTitle => 'इसका बैकअप लें';

  @override
  String get keptBackUpBody =>
      'सब कुछ इसी फ़ोन पर है और कहीं नहीं — यही इसका मक़सद है और यही जोखिम भी। बैकअप एक एन्क्रिप्टेड फ़ाइल है जिसे सिर्फ़ आपका पासकोड खोलता है। एक कहीं रख लीजिए।';
}
