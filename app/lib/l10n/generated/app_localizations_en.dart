// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Lamplight';

  @override
  String get lockTypePasscode => 'Type your passcode.';

  @override
  String get lockWrongPasscode => 'That did not open the vault.';

  @override
  String get lockCheckAndRetry => 'Check the passcode and try again.';

  @override
  String get lockForgot => 'I forgot my passcode';

  @override
  String get lockTypeTwelveWords => 'Type your twelve words.';

  @override
  String get lockUsePasscodeInstead => 'Use my passcode instead';

  @override
  String get lockUseFingerprint => 'Use your fingerprint';

  @override
  String get lockFingerprintFailed => 'Fingerprint unlock did not work.';

  @override
  String get lockFingerprintUnavailable =>
      'Fingerprint unlock is not available.';

  @override
  String get lockOpening => 'Opening…';

  @override
  String get lockNothingDeleted =>
      'Nothing has been deleted, and nothing will be.';

  @override
  String lockTryAgainSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Try again in $count seconds.',
      one: 'Try again in one second.',
    );
    return '$_temp0';
  }

  @override
  String lockTryAgainMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Try again in $count minutes.',
      one: 'Try again in one minute.',
    );
    return '$_temp0';
  }

  @override
  String get dayToday => 'TODAY';

  @override
  String get dayPrevious => 'The day before';

  @override
  String get dayNext => 'The day after';

  @override
  String get daySearch => 'Search';

  @override
  String get daySettings => 'Settings';

  @override
  String get dayChooseDate => 'Choose a different date.';

  @override
  String get dayEmptyToday => 'Anything you want to keep?';

  @override
  String get dayEmptyPast => 'Nothing on this day.';

  @override
  String get dayWriteSomething => 'Write something for today';

  @override
  String get dayLineAsk => 'What was this day?';

  @override
  String get dayLineHint => 'What was this day?';

  @override
  String get dayLineSemantic => 'Say what this day was, in one line';

  @override
  String dayLineChange(String note) {
    return 'This day: $note. Change it.';
  }

  @override
  String get dayEndOfDay => 'The end of the day';

  @override
  String get dayStartOfDay => 'The start of the day';

  @override
  String get firstPageTitle =>
      'This is empty because you have not written in it yet.';

  @override
  String get firstPageShelves =>
      'Days are the shelves. Anything you keep lands on the day it happened, and stays there.';

  @override
  String get firstPageWayWrite => 'Tap this page to write.';

  @override
  String get firstPageWayVoice => 'Hold the microphone to say it instead.';

  @override
  String get firstPageWayAttach => 'Add a photograph, a video or a document.';

  @override
  String get firstPagePromise => 'None of it leaves this phone.';

  @override
  String get firstPageSemantic => 'Write the first thing in your journal';

  @override
  String get captureVoice => 'Record a voice note';

  @override
  String get capturePhoto => 'Take or choose a photo';

  @override
  String get captureFile => 'Attach a file';

  @override
  String get backupNeverMade =>
      'Nothing here is backed up. If this app is removed, your notes go with it.';

  @override
  String get backupStale => 'It is a while since the last backup.';

  @override
  String get backupOutOfDate =>
      'Your backup still opens with your old passcode.';

  @override
  String get backupAction => 'Back up';

  @override
  String folderAlsoIn(String name) {
    return 'Also in $name. Open the folder.';
  }

  @override
  String get folderStaysHere =>
      'It stays where it is. A folder is a second place to find it.';

  @override
  String get folderAddTo => 'Add to a folder';

  @override
  String get folderNew => 'New folder';

  @override
  String get folderNoneYet =>
      'No folders yet. One per person, or per phase — whatever you keep coming back to.';

  @override
  String folderLesson(String day, String folder) {
    return 'Still on $day. Also in $folder.';
  }

  @override
  String get actionDone => 'Done';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionSave => 'Save';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionNotNow => 'Not now';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsSecurity => 'Locking and security';

  @override
  String get settingsYourNotes => 'Your notes';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageNote =>
      'The words the app uses. What you write is yours, in any language, whatever this is set to.';

  @override
  String get settingsLanguageSystem => 'Follow the phone';

  @override
  String get entryMattered => 'This one mattered';

  @override
  String get entryMarked => 'Marked as one that mattered.';

  @override
  String get entryMarkRemoved => 'Mark removed.';

  @override
  String get entryDeleted => 'Deleted.';

  @override
  String entryEarlierVersions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count earlier versions',
      one: 'One earlier version',
    );
    return '$_temp0';
  }

  @override
  String get entryKeepsWords => 'Keeps the words';

  @override
  String entryKindInTrash(Object kind) {
    return 'The $kind is in the trash.';
  }

  @override
  String entryKindInTrashWords(Object kind) {
    return 'The $kind is in the trash. The words are still here.';
  }

  @override
  String trashConfirmBody(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count entries, and every earlier version of them. This cannot be undone.',
      one: 'One entry, and every earlier version of it. This cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyEntry => 'Empty entry';

  @override
  String get kindPhoto => 'Photo';

  @override
  String get kindVideo => 'Video';

  @override
  String get kindRecording => 'Recording';

  @override
  String get kindFile => 'File';

  @override
  String get entryNoLongerMarked => 'No longer marked';

  @override
  String get entryFindAgain => 'Find it again from the search screen';

  @override
  String get searchGoTo => 'Go to';

  @override
  String get searchFolders => 'Folders';

  @override
  String get searchEntriesOne => '1 entry';

  @override
  String searchEntriesMany(int count) {
    return '$count entries';
  }

  @override
  String get searchNothingFound => 'Nothing matched that.';

  @override
  String get searchEverythingInstead => 'Search everything instead';

  @override
  String get onboardNoAccount => 'There is no account.';

  @override
  String get onboardPromiseBody =>
      'Your notes stay on this phone.\nWe have no server. We cannot read them.\nWe cannot recover them either.';

  @override
  String get onboardBegin => 'Begin';

  @override
  String get onboardHaveBackup => 'I have a backup';

  @override
  String get onboardSetPasscode => 'Set a passcode';

  @override
  String get onboardPasscodeBody =>
      'This is the only thing that opens your notes. A phrase you can remember is stronger than four digits.';

  @override
  String get onboardPasscodeLabel => 'Passcode';

  @override
  String get onboardPasscodeAgain => 'Type it again';

  @override
  String get onboardSettingUp => 'Setting up…';

  @override
  String get onboardContinue => 'Continue';

  @override
  String get onboardPasscodesDiffer => 'Those two do not match.';

  @override
  String get onboardVaultFailed => 'Your vault could not be created.';

  @override
  String get onboardVaultFailedThen => 'Nothing was saved. Try once more.';

  @override
  String get onboardWriteWords => 'Write these twelve words\non paper';

  @override
  String get onboardWordsBody =>
      'We do not have a copy. We cannot send them to you. There is no support email that can help you.\n\nNot a screenshot — paper. A screenshot sits in your gallery, which is the first place anyone looks.';

  @override
  String get onboardWrittenDown => 'I\'ve written them down';

  @override
  String get onboardCopyWords => 'Copy the twelve words';

  @override
  String get onboardClipboardNote =>
      'The clipboard clears itself after a minute. Other apps can read it until it does.';

  @override
  String get onboardCopied =>
      'Copied. It clears itself in a minute — paste it somewhere safe now.';

  @override
  String get onboardCopyFailed =>
      'That could not be copied. Writing them down is safer anyway.';

  @override
  String get onboardCheckThree => 'Check three of them';

  @override
  String get onboardCheckBody =>
      'So we know the paper is right, not the screen.';

  @override
  String onboardWordNumber(int number) {
    return 'Word $number';
  }

  @override
  String onboardWordWrong(int number) {
    return 'Word $number is not right. Check what you wrote down.';
  }

  @override
  String get onboardShowWords => 'Show me the words again';

  @override
  String get onboardFingerprintTitle => 'Open it with your fingerprint?';

  @override
  String get onboardFingerprintBody =>
      'So you do not have to type that passphrase every time.';

  @override
  String get onboardFingerprintExplain =>
      'Your passphrase is still the key. The fingerprint only opens this vault, only on this phone, and Android switches it off by itself if the fingerprints on the phone ever change — so nobody can add theirs and get in. It is never part of a backup.';

  @override
  String get onboardFingerprintWaiting => 'Waiting for your finger…';

  @override
  String get onboardFingerprintUse => 'Use my fingerprint';

  @override
  String get onboardFingerprintFailed => 'That did not work.';

  @override
  String get onboardOneLastThing => 'One last thing';

  @override
  String get onboardNameBody =>
      'What should Lamplight call you? It stays on this phone, and you can change it or leave it out.';

  @override
  String get onboardFingerprintOn =>
      'Your fingerprint will open Lamplight from now on.';

  @override
  String get onboardYourName => 'Your name';

  @override
  String get onboardStartWriting => 'Start writing';

  @override
  String get onboardSkip => 'Skip';

  @override
  String get settingsGroupLook => 'How it looks and speaks';

  @override
  String get settingsGroupWhoCanOpen => 'Who can open it';

  @override
  String get settingsGroupKeeping => 'Keeping it, and moving it';

  @override
  String get settingsAppearanceNote => 'Theme, font, colour, page';

  @override
  String get settingsFolders => 'Folders';

  @override
  String get settingsFoldersNote => 'People, places, phases';

  @override
  String get settingsMedia => 'Media';

  @override
  String get settingsMediaNote => 'Photos, video, sound and documents';

  @override
  String get mediaGroupDocuments => 'Documents';

  @override
  String get mediaDocumentsKept => 'Kept exactly as they arrived';

  @override
  String get mediaDocumentsFooter =>
      'A PDF or a Word file is already compressed inside, so squeezing one again saves about five per cent. Making a real difference would mean re-encoding the pictures in it, and that permanently blurs the small text in a scan — which you would find out years later, on the day you needed to read it.';

  @override
  String get settingsTrash => 'Trash';

  @override
  String get settingsTrashNote => 'Deleted entries, kept for 30 days';

  @override
  String get settingsReadableCopy => 'Readable copy';

  @override
  String get settingsReadableCopyNote =>
      'Markdown and your files, in a folder you choose';

  @override
  String get settingsBringIn => 'Bring in an old journal';

  @override
  String get settingsBringInNote =>
      'Text files from another app, filed by their date';

  @override
  String get settingsKeepingFooter =>
      'A backup is locked with your passcode, exactly like the vault. A readable copy is not locked at all — it is plain files in a folder you choose.';

  @override
  String get backupNever => 'Never backed up';

  @override
  String get backupToday => 'Backed up today';

  @override
  String get backupYesterday => 'Backed up yesterday';

  @override
  String backupDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Backed up $count days ago',
    );
    return '$_temp0';
  }

  @override
  String get mediaGroupIncoming => 'On the way in';

  @override
  String get mediaGroupVoice => 'Voice notes';

  @override
  String get mediaIncomingFooter =>
      'Lamplight never keeps a second, smaller copy — what you choose here is what is stored, and the original is not kept anywhere else.';

  @override
  String get mediaVoiceFooter =>
      'Transcribing happens on this phone, by the recogniser Android already has. Nothing said into Lamplight is sent anywhere, and the app has no permission to send it.';

  @override
  String get mediaPhotoSize => 'Photo size';

  @override
  String get mediaVideoSize => 'Video size';

  @override
  String get mediaAskEachTime => 'Ask each time';

  @override
  String get accentAmber => 'Amber';

  @override
  String get accentAmberNote => 'A lamp at night. The default.';

  @override
  String get accentRose => 'Rose';

  @override
  String get accentRoseNote => 'Warm pink. Softer than the amber.';

  @override
  String get accentSage => 'Sage';

  @override
  String get accentSageNote => 'Quiet green. The calmest of the six.';

  @override
  String get accentSlate => 'Slate';

  @override
  String get accentSlateNote => 'Cool blue-grey. The most neutral.';

  @override
  String get accentPlum => 'Plum';

  @override
  String get accentPlumNote => 'Deep purple.';

  @override
  String get accentEmber => 'Ember';

  @override
  String get accentEmberNote => 'Burnt orange. The warmest.';

  @override
  String get surfacePlain => 'Plain';

  @override
  String get surfacePlainNote => 'A flat page.';

  @override
  String get surfacePaper => 'Paper';

  @override
  String get surfacePaperNote =>
      'A soft grain, so the page reads as a surface. The default.';

  @override
  String get surfaceLamplit => 'Lamplit';

  @override
  String get surfaceLamplitNote => 'Paper, with the lamp on.';

  @override
  String get surfaceStarMap => 'Star map';

  @override
  String get surfaceStarMapNote =>
      'One sky, turning with the clock. Never the same twice in a day.';

  @override
  String get rulingNone => 'None';

  @override
  String get rulingNoneNote => 'Nothing printed on the page.';

  @override
  String get rulingLines => 'Lines';

  @override
  String get rulingLinesNote => 'Ruled like a notebook.';

  @override
  String get rulingIsometric => 'Isometric';

  @override
  String get rulingIsometricNote =>
      'Drafting paper, for thinking in three dimensions.';

  @override
  String get rulingTriangle => 'Triangle';

  @override
  String get rulingTriangleNote => 'A field of equilateral triangles.';

  @override
  String get rulingDots => 'Dot grid';

  @override
  String get rulingDotsNote =>
      'A dot at each crossing. The quietest of the four.';

  @override
  String get faceSystem => 'System';

  @override
  String get faceSystemNote => 'Whatever the rest of your phone uses.';

  @override
  String get faceSerif => 'System Serif';

  @override
  String get faceSerifNote => 'Your phone’s own serif.';

  @override
  String get faceCalmNote => 'Soft edges, wide letters.';

  @override
  String get faceModernNote => 'Tight and current.';

  @override
  String get faceOldStyleNote => 'A book face from the 1500s.';

  @override
  String get facePlayfulNote => 'Round and cheerful.';

  @override
  String get faceChildlikeNote => 'An exercise book.';

  @override
  String get faceHandwrittenNote => 'Handwriting, still readable at length.';

  @override
  String get faceMedievalNote => 'A scribe’s hand. One weight only.';

  @override
  String get faceMonoNote => 'Every letter the same width.';

  @override
  String get qualityOriginal => 'Keep the original';

  @override
  String get qualityBalanced => 'Balanced';

  @override
  String get qualitySmaller => 'Smaller';

  @override
  String get photoOriginalNote =>
      'Kept exactly as your camera made it. The largest files — and they keep the place the photo was taken, which Lamplight otherwise removes.';

  @override
  String get photoBalancedNote =>
      'Much smaller, and hard to tell apart from the original. The default.';

  @override
  String get photoSmallerNote =>
      'Half the size again. You may notice it if you crop right in.';

  @override
  String get videoOriginalNote =>
      'Kept exactly as your camera recorded it. The largest files by a long way.';

  @override
  String get videoBalancedNote =>
      'Much smaller, and hard to tell apart from the original. The default.';

  @override
  String get videoSmallerNote =>
      'Half the size again. You may notice it on a big screen.';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceTheme => 'Theme';

  @override
  String get appearanceThemeDark => 'Dark';

  @override
  String get appearanceThemeLight => 'Light';

  @override
  String get appearanceThemeAuto => 'Auto';

  @override
  String get appearanceThemeAutoNote =>
      'Follows your phone’s light and dark setting.';

  @override
  String get appearanceFont => 'Font';

  @override
  String get appearanceSize => 'Size';

  @override
  String get appearanceColour => 'Colour';

  @override
  String get appearancePage => 'Page';

  @override
  String get appearanceRuling => 'Ruling';

  @override
  String get daySavedToToday => 'Saved to today.';

  @override
  String get dayAddedToToday => 'Added to today.';

  @override
  String get entryEditWords => 'Edit the words';

  @override
  String get entryDeleteBlock => 'Delete the whole block';

  @override
  String entrySavedAs(String name) {
    return 'Saved as $name.';
  }

  @override
  String entryAddedToFolder(String name) {
    return 'Also in $name.';
  }

  @override
  String get entrySaveCopy => 'Save a copy';

  @override
  String get entrySaveCopyNote => 'Somewhere you choose, outside Lamplight';

  @override
  String get capturePhotoTake => 'Take a photo';

  @override
  String get capturePhotoChoose => 'Choose from your photos';

  @override
  String get composerHintToday => 'Write about today…';

  @override
  String get composerHintPast => 'Write about this day…';

  @override
  String get composerNewBlock => 'New block';

  @override
  String get voiceShowTranscript => 'Show what was said';

  @override
  String get voiceHideTranscript => 'Hide what was said';

  @override
  String get voiceTranscriptTitle => 'What was said';

  @override
  String get entryEdited => ', edited';

  @override
  String photoSemantic(String time) {
    return 'Photo at $time. Double tap to view.';
  }

  @override
  String get sizeThisPhoto => 'this photo';

  @override
  String get sizeThesePhotos => 'these photos';

  @override
  String get sizeThisVideo => 'this video';

  @override
  String get sizeTheseVideos => 'these videos';

  @override
  String sizeQuestion(String what) {
    return 'How big should $what be kept?';
  }

  @override
  String get trashNote =>
      'Deleted entries stay here for 30 days, then go for good.';

  @override
  String get trashConfirm => 'Delete these for good?';

  @override
  String get trashKeep => 'Keep them';

  @override
  String get trashDeleteForGood => 'Delete for good';

  @override
  String get trashPutBack => 'Put back';

  @override
  String trashPutBackOn(String day) {
    return 'Put back on $day.';
  }

  @override
  String get trashEmpty => 'Empty trash';

  @override
  String get folderMakeFirst => 'Make the first one';

  @override
  String folderDeleteAsk(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get folderKeepIt => 'Keep it';

  @override
  String get folderDeleteIt => 'Delete the folder';

  @override
  String get folderRename => 'Rename';

  @override
  String get folderDeleteThis => 'Delete this folder';

  @override
  String folderTakenOut(String name) {
    return 'Taken out of $name. It is still on its day.';
  }

  @override
  String get searchHint => 'Words, a date, a name…';

  @override
  String get searchBack => 'Back';

  @override
  String get searchClear => 'Clear';

  @override
  String searchNothingMatches(String query) {
    return 'Nothing matches “$query”.';
  }

  @override
  String get searchWhatMattered => 'WHAT MATTERED';

  @override
  String get searchADate => 'A date';

  @override
  String get searchDateExample => '16 March 2006 · march 2006 · yesterday';

  @override
  String get searchWhatYouCanType => 'What you can look for';

  @override
  String get searchTryDate => 'yesterday';

  @override
  String get searchSaidOutLoud => 'said out loud';

  @override
  String get searchAPhotograph => 'A photograph';

  @override
  String get searchAVideo => 'A video';

  @override
  String get securityWhileOpen => 'While the app is open';

  @override
  String get securityLockFooter =>
      'Lamplight always locks the moment it goes into the background. This is only about how long it waits while you are still in it.';

  @override
  String get securityLockAfter => 'Lock after';

  @override
  String get securityOneHour => '1 hour';

  @override
  String get securityYourPasscode => 'Your passcode';

  @override
  String get securityPasscodeFooter =>
      'Your passcode is the key. It is not stored anywhere — not on this phone and nowhere else — so nobody can be made to hand it over, and nobody can recover it for you.';

  @override
  String get securityChangePasscode => 'Change passcode';

  @override
  String get securityScreenshots => 'Screenshots';

  @override
  String get securityScreenshotsFooter =>
      'Lamplight blocks screen capture so that whoever picks up your phone cannot photograph your notes, and so they never appear in the recent-apps preview. You can turn that off for your own phone.';

  @override
  String get securityAllowScreenshots => 'Allow screenshots';

  @override
  String get securityScreenshotsOn => 'Your notes will show in recent apps';

  @override
  String get securityScreenshotsOff => 'Recent apps shows a blank page';

  @override
  String get securityCouldNotChange => 'That could not be changed.';

  @override
  String get securityNothingChanged =>
      'Nothing about your locking has changed.';

  @override
  String get securityPromptAutomatic => 'The prompt appears by itself';

  @override
  String get securityPromptOnTap => 'Tap the fingerprint when you want it';

  @override
  String get mediaAskEachTimeOn =>
      'You are asked how big to keep photos and videos as you add them.';

  @override
  String get mediaAskEachTimeOff =>
      'Off. The two sizes above are used without asking.';

  @override
  String get passcodeNew => 'New passcode';

  @override
  String get securityFingerprint => 'Fingerprint';

  @override
  String get securityFingerprintFooter =>
      'Your passcode is still the key. The fingerprint only opens this vault, only on this phone, and Android switches it off by itself if the fingerprints on the phone ever change — so nobody can add theirs and get in. It is never part of a backup.';

  @override
  String get securityUnlockWithFingerprint => 'Unlock with my fingerprint';

  @override
  String get securityAskOnOpen => 'Ask as soon as Lamplight opens';

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get durationNever => 'Never';

  @override
  String get securityDefaultNote => 'The default.';

  @override
  String get securityHourNote => 'For an afternoon of reading back.';

  @override
  String get securityNeverNote =>
      'It still locks the second you leave the app.';

  @override
  String get calendarGoToDate => 'Go to a date';

  @override
  String get dayHasWriting => 'writing';

  @override
  String get dayHasPhoto => 'a photo';

  @override
  String get dayHasVideo => 'a video';

  @override
  String get dayHasVoice => 'a voice note';

  @override
  String get dayHasFile => 'a file';

  @override
  String dayEntriesAndKinds(Object count, Object kinds) {
    return '$count, $kinds';
  }

  @override
  String get listSeparator => ', ';

  @override
  String listAnd(Object last, Object most) {
    return '$most and $last';
  }

  @override
  String get integrityNothingUnusual =>
      'Nothing unusual about this phone. Lamplight is running the way it is meant to.';

  @override
  String get calendarPreviousYear => 'Previous year';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextYear => 'Next year';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarBackToMonth => 'Back to the month';

  @override
  String get calendarWholeYear => 'The whole year';

  @override
  String get calendarBackToThisMonth => 'Back to this month';

  @override
  String get calendarNothingThisYear => 'Nothing on this year yet.';

  @override
  String calendarYearSummary(Object days, Object entries) {
    return '$entries on $days.';
  }

  @override
  String get folderNothingInIt => 'Nothing in it yet';

  @override
  String get onThisDayOneYear => 'A year ago today';

  @override
  String onThisDayYears(Object years) {
    return '$years years ago today';
  }

  @override
  String wheelYear(Object year) {
    return 'Year $year';
  }

  @override
  String get calendarBackToBrowsing => 'Back to browsing';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarFirstEntry => 'Your first entry';

  @override
  String get calendarGoToThisDay => 'Go to this day';

  @override
  String get calendarDensityNote =>
      'Colour shows how much is on a day, from nothing to a lot.';

  @override
  String get calendarLess => 'Less';

  @override
  String get calendarMore => 'More';

  @override
  String get calendarGoToToday => 'Go to today';

  @override
  String get backupTitle => 'Backup';

  @override
  String get vaultNothingToBackUp =>
      'There is nothing in this vault to back up yet.';

  @override
  String vaultChangedWhileBackingUp(Object name) {
    return 'Something changed while the backup was being made ($name). Try again.';
  }

  @override
  String get vaultTooSmall =>
      'This file is too small to be a Lamplight backup.';

  @override
  String get vaultNotALamplightFile => 'This is not a Lamplight backup file.';

  @override
  String get vaultDamaged => 'This file is damaged and cannot be opened.';

  @override
  String get vaultKeyringNewerVersion =>
      'This vault was made by a newer version of Lamplight. Update the app to open it.';

  @override
  String get vaultKeyringDamaged =>
      'The vault key file is damaged and cannot be read. If you have a backup file, restore from it.';

  @override
  String get vaultDatabaseNewerVersion =>
      'This vault was made by a newer version of Lamplight. Update the app to open it — your notes are safe and nothing has been changed.';

  @override
  String phraseWrongLength(Object count) {
    return 'A recovery phrase is 12 words. This one has $count.';
  }

  @override
  String phraseNotARecoveryWord(Object word) {
    return '\"$word\" is not one of the recovery words.';
  }

  @override
  String get phraseDoesNotCheckOut =>
      'Those words are not a valid recovery phrase. Check for a mistyped or swapped word.';

  @override
  String get vaultNewerVersion =>
      'This backup was made with a newer version of Lamplight. Update the app, then try again.';

  @override
  String get vaultUnknownCompression =>
      'This backup uses a compression this version does not know how to read.';

  @override
  String get vaultDamagedTryOlder =>
      'This file is damaged and cannot be opened. If you have an older backup, try that one.';

  @override
  String get vaultBeforeRecoveryPhrases =>
      'This backup was made before recovery phrases could open backup files. Its passcode is the only way in.';

  @override
  String get vaultWordsDoNotOpenIt =>
      'Those words do not open this file. They may belong to a different vault.';

  @override
  String get vaultWrongPasscode => 'That passcode does not open this file.';

  @override
  String vaultMissingPart(Object name) {
    return 'This backup is missing part of itself ($name).';
  }

  @override
  String vaultPartWrongSize(Object name) {
    return 'This backup is damaged ($name is the wrong size).';
  }

  @override
  String vaultPartDoesNotMatch(Object name) {
    return 'This backup is damaged ($name does not match).';
  }

  @override
  String get vaultNoVaultInside =>
      'This backup does not contain a vault. It may have been made by a different app.';

  @override
  String get vaultOutOfOrder =>
      'This file is damaged: its contents are out of order.';

  @override
  String get vaultEndsPartWay =>
      'This file is damaged: it ends part-way through.';

  @override
  String vaultIncomplete(Object parts) {
    return 'This file is incomplete — it has $parts of its parts.';
  }

  @override
  String vaultWillNotOpen(Object name) {
    return 'This backup contains something Lamplight will not open ($name).';
  }

  @override
  String countEntries(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String countDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get backupCheckingItOpens => 'Checking it opens…';

  @override
  String get backupCouldNotSave => 'The backup could not be saved.';

  @override
  String get backupNothingLost =>
      'Nothing was lost, and your notes are untouched. Try again in a moment.';

  @override
  String get backupLast => 'Last backup';

  @override
  String get backupInTheVault => 'In the vault';

  @override
  String get restoreCheckingFile => 'Checking the file…';

  @override
  String get restoreCouldNotOpen => 'That file could not be opened.';

  @override
  String get restoreCheckItIsTheOne =>
      'Check it is the backup you meant, and try again.';

  @override
  String get restorePuttingInPlace => 'Putting it in place…';

  @override
  String get restorePuttingBack => 'Putting your old notes back…';

  @override
  String get restoreCouldNotFinish => 'The restore could not be finished.';

  @override
  String get restoreBackAsTheyWere => 'Your notes are back as they were.';

  @override
  String get restoreUsePasscodeInstead => 'Use the passcode instead';

  @override
  String get restoreUseWordsInstead => 'I have the twelve words instead';

  @override
  String get backupCreateFile => 'Create backup file';

  @override
  String get backupCreatedChecked => 'Backup created and checked.';

  @override
  String get backupMakeAnother => 'Make another';

  @override
  String get backupRestoreHeading => 'Restore';

  @override
  String get backupRestoreFrom => 'Restore from a backup file';

  @override
  String backupProgress(String stage, int percent) {
    return '$stage $percent per cent';
  }

  @override
  String get restoreTitle => 'Restore';

  @override
  String get restoreChooseFile => 'Choose a file';

  @override
  String get restorePhraseHint => 'remember story industry…';

  @override
  String get restoreAction => 'Restore';

  @override
  String get restoreChooseDifferent => 'Choose a different file';

  @override
  String get importChooseFolder => 'Choose a folder';

  @override
  String get importChooseFiles => 'Choose the files instead';

  @override
  String get importChooseFilesNote =>
      'If Android refuses your folder — it will not give any app Downloads, or the top of your storage — pick the files themselves. Nothing refuses that.';

  @override
  String get importLooking => 'Looking through the folder…';

  @override
  String get importNoTextFiles => 'There are no text files in that folder.';

  @override
  String get importChooseDifferentFolder => 'Choose a different folder';

  @override
  String get importUseFileDate => 'Use the file’s own date for these';

  @override
  String get importUseFileDateNote =>
      'Puts them on the day the file was last changed. That is often not the day it is about.';

  @override
  String importBringIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bring in $count notes',
      one: 'Bring in 1 note',
    );
    return '$_temp0';
  }

  @override
  String importProgress(int percent) {
    return 'Importing, $percent per cent';
  }

  @override
  String get exportChooseFolder => 'Choose a folder and export';

  @override
  String get exportWritten => 'Your copy is written.';

  @override
  String get exportAgain => 'Export again';

  @override
  String get exportWhichOne => 'Which one do I want?';

  @override
  String get exportNotLocked => 'This copy is not locked';

  @override
  String dayAddedThings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count things to today.',
    );
    return '$_temp0';
  }

  @override
  String get entryAddNote => 'Add a note to this';

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count.',
      one: 'Added.',
    );
    return '$_temp0';
  }

  @override
  String get importFolderUnreadable => 'That folder could not be read.';

  @override
  String get importNothingBrought => 'Nothing was brought in.';

  @override
  String get importStoppedPartWay =>
      'Bringing the journal in stopped part way.';

  @override
  String get importWhatArrivedKept =>
      'Everything that arrived before it stopped was kept.';

  @override
  String get importNoReadableDates =>
      'None of those files have a date Lamplight can read.';

  @override
  String importReadyToBring(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes ready to bring in.',
      one: '1 note ready to bring in.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingNew => 'Nothing new to bring in.';

  @override
  String importBroughtIn(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes brought in.',
      one: '1 note brought in.',
    );
    return '$_temp0';
  }

  @override
  String importAlreadyHere(Object count) {
    return '$count were already here, so they were left alone.';
  }

  @override
  String importNoDateSkipped(Object count) {
    return '$count had no date to read, and were skipped.';
  }

  @override
  String importCouldNotRead(Object count, Object names) {
    return '$count could not be read: $names';
  }

  @override
  String get exportStarting => 'Starting…';

  @override
  String get exportCouldNotFinish => 'The readable copy could not be finished.';

  @override
  String get exportNothingChanged => 'Nothing in Lamplight was changed.';

  @override
  String get importVideoAlreadySmall =>
      'One video was already about as small as it gets, so it was kept as it is.';

  @override
  String get importVideoCouldNotShrink =>
      'One video could not be made smaller on this phone, so it was kept whole.';

  @override
  String importOneFailed(String reason) {
    return 'One did not work: $reason';
  }

  @override
  String importAbandoned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count did not finish before Lamplight locked.',
      one: 'One did not finish before Lamplight locked.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingLeft => 'Nothing was left on the phone.';

  @override
  String get nameCardAsk => 'What should this say?';

  @override
  String get nameCardHint => 'Your name, or anything';

  @override
  String get reminderGroup => 'A nudge, if you want one';

  @override
  String get reminderFooter =>
      'Off unless you turn it on. It never mentions what is in your notes — it cannot, because it runs while the vault is locked. No streaks, no counts, nothing about days you missed.';

  @override
  String get reminderTitle => 'Remind me to write';

  @override
  String get reminderWhen => 'When';

  @override
  String get reminderProblemNotAllowed =>
      'Lamplight is not allowed to send notifications.';

  @override
  String get reminderProblemNotificationsOff =>
      'This phone’s settings have Lamplight’s notifications switched off.';

  @override
  String get reminderProblemRemindersOff =>
      'Reminders from Lamplight are switched off in this phone’s notification settings.';

  @override
  String get reminderProblemBatterySaving =>
      'This phone is saving battery by holding Lamplight back. That is the usual reason a reminder is late or never arrives.';

  @override
  String get reminderMayNotArrive => 'The reminder may not arrive';

  @override
  String get backupAutomatic => 'Back up automatically';

  @override
  String get backupAutomaticDidNotFinish =>
      'The automatic backup did not finish.';

  @override
  String get backupNothingYet => 'Nothing to back up yet.';

  @override
  String get backupInProgress => 'Backing up…';

  @override
  String get backupStartsAtUnlock => 'Starts at your next unlock.';

  @override
  String get backupDoneAutomatically => 'Backed up automatically.';

  @override
  String get backupLastOneFailed =>
      'The last automatic backup did not finish. It will try again next time you open Lamplight.';

  @override
  String importNthOf(Object index, Object total) {
    return '$index of $total';
  }

  @override
  String importWaiting(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting',
      one: '1 waiting',
    );
    return '$_temp0';
  }

  @override
  String get aboutCopied => 'Copied';

  @override
  String get failureGeneric => 'That did not work.';

  @override
  String get failureNothingLost => 'Nothing was lost — try again.';

  @override
  String get calendarNothingOnDay => 'nothing';

  @override
  String get backupChangeFolder => 'Change folder';

  @override
  String backupSavedTo(String place) {
    return 'Saved to $place';
  }

  @override
  String get backupUseDefaultFolder => 'Use the usual folder';

  @override
  String get backupChooseFolder => 'Choose a folder to keep copies in';

  @override
  String get folderAndroidRestriction =>
      'Android will not let any app be given Downloads, or the whole of internal storage. Documents, or a folder inside it, works.';

  @override
  String get folderNotWritable =>
      'Nothing can be saved into that folder. Try another one.';

  @override
  String get folderRefused => 'That folder could not be used.';

  @override
  String get folderTryAnother => 'Try choosing a different one.';

  @override
  String get aboutHowKept => 'How your notes are kept';

  @override
  String get aboutFonts => 'Fonts and licences';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutNoBrowser => 'No app on this phone can open links.';

  @override
  String get aboutMadeBy => 'Made by';

  @override
  String get aboutMadeBySemantic =>
      'Made by ProbablyPiyush. Opens LinkedIn in your browser.';

  @override
  String get aboutCoffee => 'Buy me a coffee';

  @override
  String get aboutCoffeeSemantic =>
      'Buy me a coffee. Opens a page in your browser.';

  @override
  String get aboutCopyDetails => 'Copy the details';

  @override
  String settingsNameSemantic(Object name) {
    return '$name. Tap to change.';
  }

  @override
  String get settingsAddName => 'Add your name';

  @override
  String get settingsNameOnlyHere => 'Only on this phone';

  @override
  String get settingsNameOptional => 'Optional. Only ever on this phone.';

  @override
  String get reminderTurnedOffByAndroid =>
      'Android has notifications switched off for Lamplight. You can turn them on in the phone’s settings, under Apps.';

  @override
  String get reminderOnceADay => 'Once a day';

  @override
  String reminderTodayAt(Object time) {
    return 'today at $time';
  }

  @override
  String reminderYesterdayAt(Object time) {
    return 'yesterday at $time';
  }

  @override
  String reminderOnDateAt(Object date, Object time) {
    return '$date at $time';
  }

  @override
  String get reminderNoneYet => 'Nothing has arrived yet';

  @override
  String reminderLastArrived(Object when) {
    return 'Last one arrived $when';
  }

  @override
  String reminderNextDue(Object when) {
    return 'The next is due $when';
  }

  @override
  String get aboutHide => 'Hide';

  @override
  String get aboutCheckReal => 'Check this is the real Lamplight';

  @override
  String get entryRevisionsNote => 'What this said before you changed it';

  @override
  String get entryStaysOnDay => 'It stays on this day as well';

  @override
  String entryDeleteKind(String kind) {
    return 'Delete the $kind';
  }

  @override
  String get shareCouldNotAdd =>
      'That could not be added. Try saving it and using the picture button instead.';

  @override
  String get openNothingCanOpen =>
      'Nothing on this phone can open that kind of file.';

  @override
  String get viewerMore => 'More';

  @override
  String get docLeavesLamplight => 'This leaves Lamplight';

  @override
  String get docKeepItHere => 'Keep it here';

  @override
  String get docOpenWith => 'Open with…';

  @override
  String docCannotShow(String kind) {
    return 'Lamplight can show PDFs, pictures and text without ever putting them on your phone unencrypted. A $kind file needs another app — Lamplight can hand it to one for as long as you are reading it, and take it back afterwards.';
  }

  @override
  String get menuOpenWithNote => 'Another app, without keeping a copy';

  @override
  String menuSaveKind(String kind) {
    return 'Save $kind';
  }

  @override
  String get menuTrashNote => 'Kept for 30 days, then gone';

  @override
  String get videoBackTen => 'Back ten seconds';

  @override
  String get videoForwardTen => 'Forward ten seconds';

  @override
  String get photoPlayVideo => 'Play this video';

  @override
  String get lockPhraseHint => 'Your twelve words, spaces between';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get errorScreenDidNotOpen =>
      'That screen did not open. Nothing was lost.';

  @override
  String get errorGoBack => 'Go back';

  @override
  String recordingCannot(String what) {
    return 'This phone will not $what a recording. It is still recording.';
  }

  @override
  String get recordingClose => 'Close';

  @override
  String recordingElapsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recording, $count seconds',
    );
    return '$_temp0';
  }

  @override
  String get recordingStopKeep => 'Stop and keep this recording';

  @override
  String get recordingDiscard => 'Discard';

  @override
  String get recordingCouldNotStart => 'Recording could not start.';

  @override
  String get recordingCheckMicrophone =>
      'Check that Lamplight is allowed to use the microphone.';

  @override
  String get recordingStartAgain => 'start again';

  @override
  String get recordingCouldNotSave => 'That recording could not be saved.';

  @override
  String get recordingStillHere => 'It is still here — try stopping it again.';

  @override
  String get recordingCarryOnSemantic => 'Carry on recording';

  @override
  String get recordingPauseSemantic => 'Pause this recording';

  @override
  String get recordingCarryOn => 'Carry on';

  @override
  String get recordingPause => 'Pause';

  @override
  String get sizeAdd => 'Add';

  @override
  String get transcribeTitle => 'Write down what is said';

  @override
  String get transcribeOn =>
      'Voice notes become searchable. Nothing is sent anywhere.';

  @override
  String get transcribeOff =>
      'Off. Voice notes can only be found by their day.';

  @override
  String get transcribeLanguage => 'Spoken language';

  @override
  String get transcribeLanguageNote =>
      'The language you speak in your recordings. One at a time — a sentence that switches between two comes back as whichever half matches this.';

  @override
  String get transcribeNotDownloaded =>
      'Not downloaded on this phone yet — tap to get it.';

  @override
  String transcribeGetBetter(String name) {
    return 'Get the better model for $name';
  }

  @override
  String get transcribeGetBetterNote =>
      'Transcripts are noticeably more accurate with it. The download is from your phone, not from Lamplight, and it happens once.';

  @override
  String get transcribeNoLanguages =>
      'This phone has not offered any languages yet.';

  @override
  String get transcribeNeedsDownloading => 'Needs downloading';

  @override
  String folderStill(String day, String folder) {
    return 'Still on $day. Also in $folder.';
  }

  @override
  String get folderRenameTitle => 'Rename folder';

  @override
  String get folderNameHint => 'A person, a place, a phase';

  @override
  String get voicePlay => 'Play this voice note';

  @override
  String get voiceForwardThirty => 'Forward thirty seconds';

  @override
  String voiceSpeed(String speed) {
    return 'Playback speed, currently $speed times';
  }

  @override
  String get voiceLengthUnknown =>
      'voice note, length not known until it plays';

  @override
  String get voicePosition => 'Position in the recording';

  @override
  String get voiceOpening => 'Opening the recording';

  @override
  String get voiceNoWords => 'No words came back — try again';

  @override
  String get voiceWriteThis => 'Write this down';

  @override
  String get voiceCannotWrite => 'This phone cannot write voice notes down.';

  @override
  String get voiceLanguageMissing =>
      'This phone has not downloaded that language yet.';

  @override
  String get voiceWriting => 'Writing this down…';

  @override
  String get voiceWaiting => 'Waiting to be written down.';

  @override
  String get voiceWritten => 'Written down on this phone.';

  @override
  String get errorPartNotShown => 'This part could not be shown.';

  @override
  String get errorScreenShort => 'That screen did not open.';

  @override
  String get errorNothingLost =>
      'Nothing was lost. Everything you have written is still in the vault, exactly as it was.';

  @override
  String get errorHideDetails => 'Hide the technical details';

  @override
  String get errorShowDetails => 'Show the technical details';

  @override
  String get errorDetailsNote =>
      'This is everything that would be copied. It says what broke and where in the code — it does not contain anything you have written.';

  @override
  String get passcodeChangeFailed => 'The passcode could not be changed.';

  @override
  String get passcodeOldStillWorks => 'Your old passcode still works.';

  @override
  String get passcodeChanged => 'Passcode changed';

  @override
  String get passcodeWordsUnchanged =>
      'Your twelve words have not changed, and you do not need new ones. They open your vault and your backup files exactly as they did before.';

  @override
  String get passcodeOldBackups =>
      'Backups you already have still open with your old passcode. A new one, made now, will use the new passcode.';

  @override
  String get passcodeMakeBackup => 'Make a backup now';

  @override
  String get passcodeCurrent => 'Current passcode';

  @override
  String get passcodeNewAgain => 'New passcode again';

  @override
  String get passcodeOldBackupsNote =>
      'Backup files you have already made will still open with your old passcode.';

  @override
  String get passcodeWordsNote =>
      'Your twelve recovery words do not change and keep working.';

  @override
  String get licencesFonts =>
      'Every typeface here is under the SIL Open Font License. Nothing is downloaded — they are in the app.';

  @override
  String get licencesSource =>
      'Lamplight itself is GPL-3.0 with an app-store exception. The source is the licence: anybody can read it and check that the app does what this screen says.';

  @override
  String get licencesUnreadable => 'That licence file could not be read.';

  @override
  String get appearanceSample =>
      'Rain all afternoon. Made tea, read half a chapter, forgot what I meant to say and wrote this instead.';

  @override
  String get appearanceChromeNote => 'Buttons and labels stay like this';

  @override
  String get appearanceSizeNote =>
      'This works on top of your phone’s own text size, so if you have already turned that up, this goes further still.';

  @override
  String get voicePause => 'Pause';

  @override
  String get importIntro =>
      'If you have written a journal somewhere else, Lamplight can read it in — as long as it is text files with the date in the name.';

  @override
  String get importHowDates =>
      'It reads plain text files and looks for a date in the name — 2026-08-24, or 24 August 2026 — anywhere in the file name or the folders above it.';

  @override
  String get importAmbiguousDates =>
      'Dates like 03-04-2026 are skipped on purpose. That is the third of April in some countries and the fourth of March in others, and guessing wrong would file a year of your life on the wrong days without telling you.';

  @override
  String get importFormats =>
      'Lamplight reads plain text: .txt, .md, .org, .log and others, including files with no extension at all. If your journal is in another format, export it as text first.';

  @override
  String get importAtStartOfDay =>
      'They will sit at the start of each day, because a file name gives the date but not the time. Nothing already in Lamplight is changed or removed, and running this twice will not make copies.';

  @override
  String get importFileDateNote =>
      'Puts them on the day the file was last changed. If the folder has been copied between devices, that may be the day it was copied rather than the day you wrote it.';

  @override
  String get importSkippedNote =>
      'These will be skipped. They stay exactly where they are — nothing is moved or deleted from your folder.';

  @override
  String get restoreChooseNote =>
      'Choose your backup file. It will be called something like Lamplight-2026-08-18.vault.';

  @override
  String get restorePasscodeNote =>
      'Enter the passcode for this file — the one that was set when the backup was made.';

  @override
  String get restoreWordsNote =>
      'Type the twelve words, in order, separated by spaces.';

  @override
  String get restoreDoNotClose => 'Do not close Lamplight until this finishes.';

  @override
  String get exportIntro =>
      'This writes everything in Lamplight into a folder you choose, as ordinary files — one text file for each day, and every photo, video, voice note and document under its own name.';

  @override
  String get exportNoLamplightNeeded =>
      'Nothing in that folder needs Lamplight to open it. If this app ever stops working, or you stop using it, your notes still open in anything that reads text.';

  @override
  String get exportWhichOneBody =>
      'A readable copy is for reading, moving to another app, or keeping something after you stop using Lamplight. It is not protected.\n\nA backup file is for getting Lamplight back exactly as it was — a new phone, or a phone that broke. It is locked with your passcode, so it is safe to keep anywhere, including a cloud drive.\n\nMost people want the backup. Take a readable copy as well if you want to be certain you are never stuck.';

  @override
  String get exportNotLockedBody =>
      'It has no passcode on it. Anyone who opens that folder can read everything in it. Put it somewhere you are happy with that — and if you only want something safe to keep, use Back up instead.';

  @override
  String get backupConfirmNote =>
      'Confirm your passcode. This file can unlock everything, so making one should be something you meant to do.';

  @override
  String get backupKeepSafeNote =>
      'Your backup is locked with the passcode you have now. Keep it somewhere you trust — a cloud drive is fine, because the file is unreadable without that passcode. We never see it.';

  @override
  String get backupRestoreWarning =>
      'Opening a backup replaces everything currently in Lamplight. Your current notes are kept aside until the restored ones are proven to open.';

  @override
  String get folderWhatItIs =>
      'A folder is a thread that runs through your days — one person, one place, one stretch of time.';

  @override
  String get folderNothingMoves =>
      'Nothing moves into a folder. An entry stays on its own day and shows up here as well.';

  @override
  String get folderDeleteNote =>
      'The folder goes. Everything in it stays exactly where it is, on its own day.';

  @override
  String get folderNoneInHere =>
      'Nothing in here yet. Long-press anything on a day and choose “Add to a folder”.';

  @override
  String get passcodeRuleLength => 'Eight characters or more.';

  @override
  String get passcodeRuleWords =>
      'A few ordinary words you will remember beats a short one with symbols in it.';

  @override
  String get passcodeNoMatch => 'The two do not match yet.';

  @override
  String get docCopyInClear =>
      'The copy is written out in the clear, so any app that can read your files can read it. What is kept inside Lamplight stays encrypted either way.';

  @override
  String docPageOf(String page, String total) {
    return '$page of $total';
  }

  @override
  String get transcribeTookTooLong =>
      'That recording took too long to write down, so Lamplight stopped waiting. It will try again later.';

  @override
  String get transcribeCouldNotWriteDown =>
      'That recording could not be written down.';

  @override
  String get transcribeRecordingIsSafe =>
      'The recording itself is safe. Lamplight will try again.';

  @override
  String voicePositionSpoken(Object at, Object total) {
    return '$at of $total';
  }

  @override
  String entryEditedAt(Object time) {
    return '$time · edited';
  }

  @override
  String get docCouldNotOpen => 'That document could not be opened.';

  @override
  String albumThisOne(Object thing) {
    return 'This $thing';
  }

  @override
  String albumThisOneOf(Object index, Object thing, Object total) {
    return 'This $thing — $index of $total';
  }

  @override
  String get albumCaptionThese => 'Add a caption to these';

  @override
  String get albumCaptionThis => 'Add a caption';

  @override
  String get albumCaptionEdit => 'Edit the caption';

  @override
  String albumOthersStay(Object count) {
    return 'The other $count stay. It goes to the trash for 30 days.';
  }

  @override
  String get albumGoesToTrash => 'It goes to the trash for 30 days.';

  @override
  String get photoCouldNotOpen => 'This picture could not be opened.';

  @override
  String get photoMayBeDamaged => 'It may be damaged.';

  @override
  String get docTooBig =>
      'This one is too big to open inside Lamplight. You can save a copy and open it elsewhere.';

  @override
  String docPages(Object count) {
    return '$count pages';
  }

  @override
  String get docFileEmpty => 'This file is empty.';

  @override
  String videoTooBig(Object size) {
    return 'This video is too big for Lamplight to play here — $size. It will not be written out unprotected to get around that. Save a copy to watch it elsewhere.';
  }

  @override
  String get videoNotAvailableHere =>
      'This part of the app is not available on this phone.';

  @override
  String get videoCouldNotOpen => 'This video could not be opened.';

  @override
  String get docGoToPage => 'Go to a page';

  @override
  String get docGo => 'Go';

  @override
  String get docPageCouldNotBeDrawn => 'This page could not be drawn.';

  @override
  String get passcodeRuleStronger =>
      'Another word or two would make it much harder to guess.';

  @override
  String get backupAutoFooter =>
      'Automatic backups run when you open Lamplight, if anything changed since the last one. They are locked with your passcode, exactly like one you make yourself.';

  @override
  String get aboutHowKeptBody =>
      'No account. No server. Nothing leaves this phone.\n\nYour notes are locked with your passcode, and the key is made from it — so there is no copy of it anywhere, including with us.';

  @override
  String get aboutFree =>
      'Lamplight is free and always will be. There is nothing to unlock.';

  @override
  String get backupOnItsOwn => 'On its own';

  @override
  String get actionDismiss => 'Dismiss';

  @override
  String importRange(String from, String to) {
    return 'From $from to $to.';
  }

  @override
  String get sizeOneCopy =>
      'Lamplight keeps one copy. Whatever you choose here is what you will have.';

  @override
  String get sizeAddAlways => 'Add, and do not ask again';

  @override
  String get trashNothingHere => 'Nothing here.';

  @override
  String get appearanceAaQuiet => 'Aa\nquiet';

  @override
  String lockWarnSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Locking in about $count seconds.',
      one: 'Locking in about one second.',
    );
    return '$_temp0';
  }

  @override
  String get lockWarnChange => 'Change this in Locking and security.';

  @override
  String get openingLabel => 'Lamplight is opening';

  @override
  String get recordingNoMic =>
      'Lamplight cannot use the microphone. You can turn it on in the phone’s settings, under Apps.';

  @override
  String get recordingPaused => 'Paused. Nothing is being heard.';

  @override
  String get videoOpening => 'Opening the video…';

  @override
  String albumRemoveThis(String thing) {
    return 'Remove this $thing';
  }

  @override
  String get revisionsNote =>
      'What this said before you changed it. Nothing here is a button — you can select the words and copy them.';

  @override
  String get composerSemantic => 'Write an entry for this day';

  @override
  String importStripAdding(String name) {
    return 'Adding $name';
  }

  @override
  String passcodeAtLeast(int count) {
    return 'At least $count characters';
  }

  @override
  String get searchKindAll => 'Everything';

  @override
  String get searchKindWords => 'Words';

  @override
  String get searchKindVoice => 'Voice';

  @override
  String get searchKindPhotos => 'Photos';

  @override
  String get searchKindFiles => 'Files';

  @override
  String passcodeAtLeastShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'At least $count characters',
      one: 'At least 1 character',
    );
    return '$_temp0';
  }

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get trashGoneToday => 'Goes today';

  @override
  String restoreMadeOn(String date) {
    return 'Made on $date';
  }

  @override
  String restoreDone(String entries, String days) {
    return 'Restored $entries across $days. Welcome back.';
  }

  @override
  String importFoundUndated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count with no date Lamplight can read',
      one: '1 with no date Lamplight can read',
    );
    return '$_temp0';
  }

  @override
  String entrySemantic(String time) {
    return 'Entry at $time. Tap to edit.';
  }

  @override
  String entrySemanticEdited(String time) {
    return 'Entry at $time, edited. Tap to edit.';
  }

  @override
  String onThisDaySemantic(String when, String body) {
    return '$when. $body. Tap to go to that day.';
  }

  @override
  String attachmentSemantic(String what, String time) {
    return '$what at $time. Double tap to open them.';
  }

  @override
  String dayHeaderToday(String date) {
    return '$date, today';
  }

  @override
  String get yearGridNothing => 'Nothing on this day';

  @override
  String get calendarNothing => 'Nothing on this day';

  @override
  String importStripCounted(String name, String counted) {
    return 'Adding $name$counted';
  }

  @override
  String get aboutFingerprintBody =>
      'Every build carries a signature only its author can make. This is the one on the copy you are holding. Compare it with the fingerprint published alongside the source — if they match, this is the app that source builds.';

  @override
  String get searchKindVideo => 'Video';

  @override
  String get semanticOn => 'on';

  @override
  String andMore(int count) {
    return 'and $count more';
  }

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'nothing',
    );
    return '$_temp0';
  }

  @override
  String get checkDone => 'Done';

  @override
  String get checkNotYet => 'Not yet';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get lockUseYourPasscode => 'Use your passcode.';

  @override
  String get searchWordsExample => 'anything you have written';

  @override
  String get searchAFile => 'A file';

  @override
  String get searchFileExample => 'scan.pdf · IMG_2831';

  @override
  String get searchAFolder => 'A folder';

  @override
  String get searchFolderExample => 'the name you gave it';

  @override
  String get searchByFileName => 'by file name';

  @override
  String get searchARecording => 'A recording';

  @override
  String get searchAnEntry => 'An entry';

  @override
  String get sizeThisOne => 'this one';

  @override
  String get sizeTheseOnes => 'these';

  @override
  String get passcodeOneMoreCharacter => 'One more character.';

  @override
  String passcodeMoreCharacters(int count, int minimum) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more characters — $minimum is the minimum.',
      one: '1 more character — $minimum is the minimum.',
    );
    return '$_temp0';
  }

  @override
  String get passcodeTooObvious =>
      'That is one of the first things anyone would try. Pick something else.';

  @override
  String get passcodeSameCharacter => 'That is the same character repeated.';

  @override
  String get passcodeStraightRun => 'That is a straight run of characters.';

  @override
  String attachmentLoading(String time) {
    return 'Attachment at $time, loading';
  }

  @override
  String videoSemantic(String time, String length) {
    return 'Video at $time, $length. Double tap to watch.';
  }

  @override
  String voiceSemantic(String time, String length) {
    return 'Voice note at $time, $length. Double tap to play.';
  }

  @override
  String fileSemantic(String time, String name, String size) {
    return 'File at $time, $name, $size. Double tap to open.';
  }

  @override
  String get lengthUnknown => 'length unknown';

  @override
  String get settingsLockNone => 'no auto-lock';

  @override
  String settingsLockAfter(String duration) {
    return 'after $duration';
  }

  @override
  String settingsSecuritySummary(String lock) {
    return 'Passcode, fingerprint, $lock';
  }

  @override
  String get keptNoNetworkTitle => 'It never goes anywhere';

  @override
  String get keptNoNetworkBody =>
      'Lamplight cannot use the internet. Not \"does not\" — cannot: Android refuses it the permission, and you can check that yourself in the phone’s app settings in about thirty seconds.';

  @override
  String get keptPasscodeTitle => 'Your passcode is the key';

  @override
  String get keptPasscodeBody =>
      'The key that opens your notes is made from your passcode every time you unlock. It is not stored anywhere, so there is no copy of it to find, to lose, or to hand over.';

  @override
  String get keptForgetTitle => 'If you forget it';

  @override
  String get keptForgetBody =>
      'Your twelve words are the only other way in. Nobody can reset a passcode here, and that is the same fact as the one above — an app that could let you back in could let somebody else in too.';

  @override
  String get keptNothingReadableTitle => 'Nothing readable is left lying about';

  @override
  String get keptNothingReadableBody =>
      'Photos, recordings and files are encrypted before they touch storage. Nothing is ever written out in the clear, not even briefly while you look at it.';

  @override
  String get keptLocksItselfTitle => 'It locks itself';

  @override
  String get keptLocksItselfBody =>
      'The moment Lamplight goes into the background the keys are destroyed. Screenshots are blocked and the app does not appear in the recent apps preview.';

  @override
  String get keptBackUpTitle => 'Back it up';

  @override
  String get keptBackUpBody =>
      'Everything is on this phone and nowhere else, which is the point and is also the risk. A backup is one encrypted file that only your passcode opens. Keep one somewhere.';
}
