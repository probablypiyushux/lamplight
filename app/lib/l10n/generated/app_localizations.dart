import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('zh'),
  ];

  /// The name of the app. A proper noun — it is NOT translated in any locale, and ADR-010 calls it permanent.
  ///
  /// In en, this message translates to:
  /// **'Lamplight'**
  String get appName;

  /// The whole instruction on the lock screen. A statement, not a demand — no 'please', no exclamation.
  ///
  /// In en, this message translates to:
  /// **'Type your passcode.'**
  String get lockTypePasscode;

  /// Shown after a failed unlock. Deliberately says what happened rather than 'incorrect password' — it does not accuse the person of being wrong.
  ///
  /// In en, this message translates to:
  /// **'That did not open the vault.'**
  String get lockWrongPasscode;

  /// No description provided for @lockCheckAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Check the passcode and try again.'**
  String get lockCheckAndRetry;

  /// No description provided for @lockForgot.
  ///
  /// In en, this message translates to:
  /// **'I forgot my passcode'**
  String get lockForgot;

  /// No description provided for @lockTypeTwelveWords.
  ///
  /// In en, this message translates to:
  /// **'Type your twelve words.'**
  String get lockTypeTwelveWords;

  /// No description provided for @lockUsePasscodeInstead.
  ///
  /// In en, this message translates to:
  /// **'Use my passcode instead'**
  String get lockUsePasscodeInstead;

  /// No description provided for @lockUseFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint'**
  String get lockUseFingerprint;

  /// No description provided for @lockFingerprintFailed.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint unlock did not work.'**
  String get lockFingerprintFailed;

  /// No description provided for @lockFingerprintUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint unlock is not available.'**
  String get lockFingerprintUnavailable;

  /// No description provided for @lockOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get lockOpening;

  /// Reassurance after repeated failures. A promise the user is owed — it must survive translation intact.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been deleted, and nothing will be.'**
  String get lockNothingDeleted;

  /// No description provided for @lockTryAgainSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Try again in one second.} other{Try again in {count} seconds.}}'**
  String lockTryAgainSeconds(int count);

  /// No description provided for @lockTryAgainMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Try again in one minute.} other{Try again in {count} minutes.}}'**
  String lockTryAgainMinutes(int count);

  /// Shown under the date when the day on screen is today. Upper case in English; some scripts have no case, and that is fine — do not fake it.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get dayToday;

  /// No description provided for @dayPrevious.
  ///
  /// In en, this message translates to:
  /// **'The day before'**
  String get dayPrevious;

  /// No description provided for @dayNext.
  ///
  /// In en, this message translates to:
  /// **'The day after'**
  String get dayNext;

  /// No description provided for @daySearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get daySearch;

  /// No description provided for @daySettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get daySettings;

  /// No description provided for @dayChooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a different date.'**
  String get dayChooseDate;

  /// The empty day, on today. A QUESTION, never an instruction — ETHICAL-DESIGN.md forbids anything that implies the user owes the app writing. 'Write something today!' would be wrong in every language.
  ///
  /// In en, this message translates to:
  /// **'Anything you want to keep?'**
  String get dayEmptyToday;

  /// The empty day, in the past. A plain statement of fact. Not sad, not an invitation — there is nothing to start on a day that is over.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day.'**
  String get dayEmptyPast;

  /// No description provided for @dayWriteSomething.
  ///
  /// In en, this message translates to:
  /// **'Write something for today'**
  String get dayWriteSomething;

  /// Invitation to name a day, shown only once the day has something on it. A question again, for the same reason as dayEmptyToday.
  ///
  /// In en, this message translates to:
  /// **'What was this day?'**
  String get dayLineAsk;

  /// No description provided for @dayLineHint.
  ///
  /// In en, this message translates to:
  /// **'What was this day?'**
  String get dayLineHint;

  /// No description provided for @dayLineSemantic.
  ///
  /// In en, this message translates to:
  /// **'Say what this day was, in one line'**
  String get dayLineSemantic;

  /// No description provided for @dayLineChange.
  ///
  /// In en, this message translates to:
  /// **'This day: {note}. Change it.'**
  String dayLineChange(String note);

  /// No description provided for @dayEndOfDay.
  ///
  /// In en, this message translates to:
  /// **'The end of the day'**
  String get dayEndOfDay;

  /// No description provided for @dayStartOfDay.
  ///
  /// In en, this message translates to:
  /// **'The start of the day'**
  String get dayStartOfDay;

  /// The first line a brand-new vault ever shows. About the person, not about the app — deliberately NOT 'Welcome to Lamplight'.
  ///
  /// In en, this message translates to:
  /// **'This is empty because you have not written in it yet.'**
  String get firstPageTitle;

  /// The one sentence explaining the whole organising idea.
  ///
  /// In en, this message translates to:
  /// **'Days are the shelves. Anything you keep lands on the day it happened, and stays there.'**
  String get firstPageShelves;

  /// No description provided for @firstPageWayWrite.
  ///
  /// In en, this message translates to:
  /// **'Tap this page to write.'**
  String get firstPageWayWrite;

  /// No description provided for @firstPageWayVoice.
  ///
  /// In en, this message translates to:
  /// **'Hold the microphone to say it instead.'**
  String get firstPageWayVoice;

  /// No description provided for @firstPageWayAttach.
  ///
  /// In en, this message translates to:
  /// **'Add a photograph, a video or a document.'**
  String get firstPageWayAttach;

  /// The single promise on the first page. This is a factual claim about the app and must stay exactly as strong and exactly as narrow in every language — not 'your data is safe', not 'we protect your privacy'.
  ///
  /// In en, this message translates to:
  /// **'None of it leaves this phone.'**
  String get firstPagePromise;

  /// No description provided for @firstPageSemantic.
  ///
  /// In en, this message translates to:
  /// **'Write the first thing in your journal'**
  String get firstPageSemantic;

  /// No description provided for @captureVoice.
  ///
  /// In en, this message translates to:
  /// **'Record a voice note'**
  String get captureVoice;

  /// No description provided for @capturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take or choose a photo'**
  String get capturePhoto;

  /// No description provided for @captureFile.
  ///
  /// In en, this message translates to:
  /// **'Attach a file'**
  String get captureFile;

  /// Shown once the vault holds enough to be worth losing. It states a consequence rather than urging — the fact is the argument, and it must not become 'Back up now!' in any language.
  ///
  /// In en, this message translates to:
  /// **'Nothing here is backed up. If this app is removed, your notes go with it.'**
  String get backupNeverMade;

  /// No description provided for @backupStale.
  ///
  /// In en, this message translates to:
  /// **'It is a while since the last backup.'**
  String get backupStale;

  /// No description provided for @backupOutOfDate.
  ///
  /// In en, this message translates to:
  /// **'Your backup still opens with your old passcode.'**
  String get backupOutOfDate;

  /// No description provided for @backupAction.
  ///
  /// In en, this message translates to:
  /// **'Back up'**
  String get backupAction;

  /// A folder chip under a filed entry. 'Also' is load-bearing: a folder is a second place to find something, never a move. If the translation implies the entry was moved out of its day, the whole model is misrepresented.
  ///
  /// In en, this message translates to:
  /// **'Also in {name}. Open the folder.'**
  String folderAlsoIn(String name);

  /// No description provided for @folderStaysHere.
  ///
  /// In en, this message translates to:
  /// **'It stays where it is. A folder is a second place to find it.'**
  String get folderStaysHere;

  /// No description provided for @folderAddTo.
  ///
  /// In en, this message translates to:
  /// **'Add to a folder'**
  String get folderAddTo;

  /// No description provided for @folderNew.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get folderNew;

  /// No description provided for @folderNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No folders yet. One per person, or per phase — whatever you keep coming back to.'**
  String get folderNoneYet;

  /// Shown once, the first time anything is filed. It teaches the single non-obvious thing about folders here.
  ///
  /// In en, this message translates to:
  /// **'Still on {day}. Also in {folder}.'**
  String folderLesson(String day, String folder);

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @actionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get actionNotNow;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Locking and security'**
  String get settingsSecurity;

  /// No description provided for @settingsYourNotes.
  ///
  /// In en, this message translates to:
  /// **'Your notes'**
  String get settingsYourNotes;

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settingsBackup;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// The row that opens the language picker. Always shown in the CURRENT language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Under the language row. It says the thing people actually worry about: changing the interface language does not change what they can type.
  ///
  /// In en, this message translates to:
  /// **'The words the app uses. What you write is yours, in any language, whatever this is set to.'**
  String get settingsLanguageNote;

  /// The default: use whatever language the phone is set to.
  ///
  /// In en, this message translates to:
  /// **'Follow the phone'**
  String get settingsLanguageSystem;

  /// No description provided for @entryMattered.
  ///
  /// In en, this message translates to:
  /// **'This one mattered'**
  String get entryMattered;

  /// No description provided for @entryMarked.
  ///
  /// In en, this message translates to:
  /// **'Marked as one that mattered.'**
  String get entryMarked;

  /// No description provided for @entryMarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Mark removed.'**
  String get entryMarkRemoved;

  /// No description provided for @entryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted.'**
  String get entryDeleted;

  /// No description provided for @entryEarlierVersions.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{One earlier version} other{{count} earlier versions}}'**
  String entryEarlierVersions(num count);

  /// No description provided for @entryKeepsWords.
  ///
  /// In en, this message translates to:
  /// **'Keeps the words'**
  String get entryKeepsWords;

  /// No description provided for @entryKindInTrash.
  ///
  /// In en, this message translates to:
  /// **'The {kind} is in the trash.'**
  String entryKindInTrash(Object kind);

  /// No description provided for @entryKindInTrashWords.
  ///
  /// In en, this message translates to:
  /// **'The {kind} is in the trash. The words are still here.'**
  String entryKindInTrashWords(Object kind);

  /// No description provided for @trashConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{One entry, and every earlier version of it. This cannot be undone.} other{{count} entries, and every earlier version of them. This cannot be undone.}}'**
  String trashConfirmBody(num count);

  /// No description provided for @trashEmptyEntry.
  ///
  /// In en, this message translates to:
  /// **'Empty entry'**
  String get trashEmptyEntry;

  /// No description provided for @kindPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get kindPhoto;

  /// No description provided for @kindVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get kindVideo;

  /// No description provided for @kindRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get kindRecording;

  /// No description provided for @kindFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get kindFile;

  /// No description provided for @entryNoLongerMarked.
  ///
  /// In en, this message translates to:
  /// **'No longer marked'**
  String get entryNoLongerMarked;

  /// No description provided for @entryFindAgain.
  ///
  /// In en, this message translates to:
  /// **'Find it again from the search screen'**
  String get entryFindAgain;

  /// No description provided for @searchGoTo.
  ///
  /// In en, this message translates to:
  /// **'Go to'**
  String get searchGoTo;

  /// No description provided for @searchFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get searchFolders;

  /// No description provided for @searchEntriesOne.
  ///
  /// In en, this message translates to:
  /// **'1 entry'**
  String get searchEntriesOne;

  /// No description provided for @searchEntriesMany.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String searchEntriesMany(int count);

  /// No description provided for @searchNothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing matched that.'**
  String get searchNothingFound;

  /// No description provided for @searchEverythingInstead.
  ///
  /// In en, this message translates to:
  /// **'Search everything instead'**
  String get searchEverythingInstead;

  /// No description provided for @searchNoneOfThese.
  ///
  /// In en, this message translates to:
  /// **'Nothing of that kind yet.'**
  String get searchNoneOfThese;

  /// The first thing a stranger ever reads in this app. A statement of fact about the software, not a boast. The ABSENCE of a signup screen is the pitch, so this must not be softened into a welcome.
  ///
  /// In en, this message translates to:
  /// **'There is no account.'**
  String get onboardNoAccount;

  /// Three factual claims, unsoftened. The third — that recovery is impossible — must NOT be softened or dropped in translation. It is the cost of the other two, and hiding it would be the exact dark pattern ETHICAL-DESIGN.md forbids.
  ///
  /// In en, this message translates to:
  /// **'Your notes stay on this phone.\nWe have no server. We cannot read them.\nWe cannot recover them either.'**
  String get onboardPromiseBody;

  /// No description provided for @onboardBegin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get onboardBegin;

  /// No description provided for @onboardHaveBackup.
  ///
  /// In en, this message translates to:
  /// **'I have a backup'**
  String get onboardHaveBackup;

  /// No description provided for @onboardSetPasscode.
  ///
  /// In en, this message translates to:
  /// **'Set a passcode'**
  String get onboardSetPasscode;

  /// Advice, not a rule. 'Stronger than' is a comparison, not a requirement — do not translate it into an instruction or a minimum.
  ///
  /// In en, this message translates to:
  /// **'This is the only thing that opens your notes. A phrase you can remember is stronger than four digits.'**
  String get onboardPasscodeBody;

  /// No description provided for @onboardPasscodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Passcode'**
  String get onboardPasscodeLabel;

  /// No description provided for @onboardPasscodeAgain.
  ///
  /// In en, this message translates to:
  /// **'Type it again'**
  String get onboardPasscodeAgain;

  /// No description provided for @onboardSettingUp.
  ///
  /// In en, this message translates to:
  /// **'Setting up…'**
  String get onboardSettingUp;

  /// No description provided for @onboardContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardContinue;

  /// Shown when the two fields differ. States what is true of the two entries; it does not tell the person they are wrong. Same principle as lockWrongPasscode.
  ///
  /// In en, this message translates to:
  /// **'Those two do not match.'**
  String get onboardPasscodesDiffer;

  /// No description provided for @onboardVaultFailed.
  ///
  /// In en, this message translates to:
  /// **'Your vault could not be created.'**
  String get onboardVaultFailed;

  /// No description provided for @onboardVaultFailedThen.
  ///
  /// In en, this message translates to:
  /// **'Nothing was saved. Try once more.'**
  String get onboardVaultFailedThen;

  /// No description provided for @onboardWriteWords.
  ///
  /// In en, this message translates to:
  /// **'Write these twelve words\non paper'**
  String get onboardWriteWords;

  /// The most important paragraph in onboarding. 'There is no support email that can help you' is literal and stays literal. 'Not a screenshot — paper' is the instruction that actually matters, and the reason given for it is the one that persuades.
  ///
  /// In en, this message translates to:
  /// **'We do not have a copy. We cannot send them to you. There is no support email that can help you.\n\nNot a screenshot — paper. A screenshot sits in your gallery, which is the first place anyone looks.'**
  String get onboardWordsBody;

  /// No description provided for @onboardWrittenDown.
  ///
  /// In en, this message translates to:
  /// **'I\'ve written them down'**
  String get onboardWrittenDown;

  /// No description provided for @onboardCopyWords.
  ///
  /// In en, this message translates to:
  /// **'Copy the twelve words'**
  String get onboardCopyWords;

  /// The honest cost of the convenience directly above it. ETHICAL-DESIGN.md cuts both ways: offering the copy as though it were free would be a dark pattern, and frightening somebody out of their own password manager would be another.
  ///
  /// In en, this message translates to:
  /// **'The clipboard clears itself after a minute. Other apps can read it until it does.'**
  String get onboardClipboardNote;

  /// No description provided for @onboardCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied. It clears itself in a minute — paste it somewhere safe now.'**
  String get onboardCopied;

  /// No description provided for @onboardCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'That could not be copied. Writing them down is safer anyway.'**
  String get onboardCopyFailed;

  /// No description provided for @onboardCheckThree.
  ///
  /// In en, this message translates to:
  /// **'Check three of them'**
  String get onboardCheckThree;

  /// Why the quiz exists, in one line. UX-FLOWS.md flow 1 screen 3: the point is proof they actually wrote the words down, not that they can read a screen.
  ///
  /// In en, this message translates to:
  /// **'So we know the paper is right, not the screen.'**
  String get onboardCheckBody;

  /// Field label in the three-word check. {number} is 1-12, already offset for humans.
  ///
  /// In en, this message translates to:
  /// **'Word {number}'**
  String onboardWordNumber(int number);

  /// Shown when a checked word does not match. Points at the paper, not at the person.
  ///
  /// In en, this message translates to:
  /// **'Word {number} is not right. Check what you wrote down.'**
  String onboardWordWrong(int number);

  /// No description provided for @onboardShowWords.
  ///
  /// In en, this message translates to:
  /// **'Show me the words again'**
  String get onboardShowWords;

  /// A QUESTION, and the screen is skippable with the skip at the same size as the button — ETHICAL-DESIGN.md forbids making the safe answer the hard one. There is a real reason to say no here: a fingerprint is easier to compel than a passphrase.
  ///
  /// In en, this message translates to:
  /// **'Open it with your fingerprint?'**
  String get onboardFingerprintTitle;

  /// No description provided for @onboardFingerprintBody.
  ///
  /// In en, this message translates to:
  /// **'So you do not have to type that passphrase every time.'**
  String get onboardFingerprintBody;

  /// Four factual claims about scope. Deliberately the same promise the Settings row makes, word for word — two different descriptions of one security feature is how somebody ends up trusting neither.
  ///
  /// In en, this message translates to:
  /// **'Your passphrase is still the key. The fingerprint only opens this vault, only on this phone, and Android switches it off by itself if the fingerprints on the phone ever change — so nobody can add theirs and get in. It is never part of a backup.'**
  String get onboardFingerprintExplain;

  /// No description provided for @onboardFingerprintWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your finger…'**
  String get onboardFingerprintWaiting;

  /// No description provided for @onboardFingerprintUse.
  ///
  /// In en, this message translates to:
  /// **'Use my fingerprint'**
  String get onboardFingerprintUse;

  /// No description provided for @onboardFingerprintFailed.
  ///
  /// In en, this message translates to:
  /// **'That did not work.'**
  String get onboardFingerprintFailed;

  /// Shown on the onboarding fingerprint step in the rare case the vault closed underneath it. It must say two things: the passcode still works, and the fingerprint is not lost, only postponed.
  ///
  /// In en, this message translates to:
  /// **'Lamplight closed the vault while you were away. Your passcode still opens it, and you can turn the fingerprint on later in Settings.'**
  String get onboardFingerprintVaultShut;

  /// No description provided for @onboardOneLastThing.
  ///
  /// In en, this message translates to:
  /// **'One last thing'**
  String get onboardOneLastThing;

  /// A question, and genuinely optional. 'Lamplight' is a proper noun and is NOT translated in any locale — ADR-010.
  ///
  /// In en, this message translates to:
  /// **'What should Lamplight call you? It stays on this phone, and you can change it or leave it out.'**
  String get onboardNameBody;

  /// Confirms that the system prompt just answered actually did something. 'Lamplight' is NOT translated — ADR-010.
  ///
  /// In en, this message translates to:
  /// **'Your fingerprint will open Lamplight from now on.'**
  String get onboardFingerprintOn;

  /// No description provided for @onboardYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get onboardYourName;

  /// No description provided for @onboardStartWriting.
  ///
  /// In en, this message translates to:
  /// **'Start writing'**
  String get onboardStartWriting;

  /// No description provided for @onboardSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardSkip;

  /// Settings group heading. Covers the theme, the typeface and the app's own language — everything about presentation. Upper-cased by LampGroup in English; scripts without case are left alone.
  ///
  /// In en, this message translates to:
  /// **'How it looks and speaks'**
  String get settingsGroupLook;

  /// Settings group heading for the lock, the passcode and the fingerprint. Phrased as what it protects rather than as 'Security', which names the machinery instead of the concern.
  ///
  /// In en, this message translates to:
  /// **'Who can open it'**
  String get settingsGroupWhoCanOpen;

  /// Settings group heading covering backup, the readable export and the importer — everything about a copy of the journal existing somewhere else, or arriving from somewhere else.
  ///
  /// In en, this message translates to:
  /// **'Keeping it, and moving it'**
  String get settingsGroupKeeping;

  /// No description provided for @settingsAppearanceNote.
  ///
  /// In en, this message translates to:
  /// **'Theme, font, colour, page'**
  String get settingsAppearanceNote;

  /// No description provided for @settingsFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get settingsFolders;

  /// Subtitle for Folders. Three examples rather than a definition, because a folder in this app is whatever the person keeps coming back to. Not an exhaustive list — pick three natural ones in your language.
  ///
  /// In en, this message translates to:
  /// **'People, places, phases'**
  String get settingsFoldersNote;

  /// No description provided for @settingsMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get settingsMedia;

  /// Subtitle for the Photos, video and sound row. Names the two things on that screen: how much a file is compressed, and transcription.
  ///
  /// In en, this message translates to:
  /// **'Photos, video, sound and documents'**
  String get settingsMediaNote;

  /// Heading for the documents group on the Media settings screen.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get mediaGroupDocuments;

  /// States that documents are stored byte for byte as imported.
  ///
  /// In en, this message translates to:
  /// **'Kept exactly as they arrived'**
  String get mediaDocumentsKept;

  /// Why there is no size control for documents: measured on real files, lossless compression gains 3.7-7.1% on PDFs and DOCX, and lossy compression destroys small text in a scan.
  ///
  /// In en, this message translates to:
  /// **'A PDF or a Word file is already compressed inside, so squeezing one again saves about five per cent. Making a real difference would mean re-encoding the pictures in it, and that permanently blurs the small text in a scan — which you would find out years later, on the day you needed to read it.'**
  String get mediaDocumentsFooter;

  /// No description provided for @settingsTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get settingsTrash;

  /// Subtitle for Trash. A plain statement of the retention period, not a warning.
  ///
  /// In en, this message translates to:
  /// **'Deleted entries, kept for 30 days'**
  String get settingsTrashNote;

  /// No description provided for @settingsReadableCopy.
  ///
  /// In en, this message translates to:
  /// **'Readable copy'**
  String get settingsReadableCopy;

  /// Subtitle for the readable export. 'Markdown' stays as the word Markdown — it is a format name, not a description.
  ///
  /// In en, this message translates to:
  /// **'Markdown and your files, in a folder you choose'**
  String get settingsReadableCopyNote;

  /// No description provided for @settingsBringIn.
  ///
  /// In en, this message translates to:
  /// **'Bring in an old journal'**
  String get settingsBringIn;

  /// Subtitle for the importer. Says what it accepts and what it does with it.
  ///
  /// In en, this message translates to:
  /// **'Text files from another app, filed by their date'**
  String get settingsBringInNote;

  /// Footer under the backup/export/import group. The contrast between the two is the entire point: a backup is locked, a readable copy is not. Do not soften the second half — somebody needs to know what they are making before they leave it in a folder.
  ///
  /// In en, this message translates to:
  /// **'A backup is locked with your passcode, exactly like the vault. A readable copy is not locked at all — it is plain files in a folder you choose.'**
  String get settingsKeepingFooter;

  /// No description provided for @backupNever.
  ///
  /// In en, this message translates to:
  /// **'Never backed up'**
  String get backupNever;

  /// No description provided for @backupToday.
  ///
  /// In en, this message translates to:
  /// **'Backed up today'**
  String get backupToday;

  /// No description provided for @backupYesterday.
  ///
  /// In en, this message translates to:
  /// **'Backed up yesterday'**
  String get backupYesterday;

  /// How long since the last backup. {count} is the number of days, always 2 or more — today and yesterday have their own strings because most languages say those differently.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Backed up {count} days ago}}'**
  String backupDaysAgo(int count);

  /// No description provided for @mediaGroupIncoming.
  ///
  /// In en, this message translates to:
  /// **'On the way in'**
  String get mediaGroupIncoming;

  /// No description provided for @mediaGroupVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice notes'**
  String get mediaGroupVoice;

  /// Footer under the photo and video size rows. The point is that there is no second copy: what you choose is what is stored, and the original is not kept anywhere.
  ///
  /// In en, this message translates to:
  /// **'Lamplight never keeps a second, smaller copy — what you choose here is what is stored, and the original is not kept anywhere else.'**
  String get mediaIncomingFooter;

  /// Footer under the transcription rows. A factual claim about the software and it must stay exactly that strong and that narrow — the recogniser is the phone's own, and the app has no permission to send anything anywhere. Not 'your data is safe'.
  ///
  /// In en, this message translates to:
  /// **'Transcribing happens on this phone, by the recogniser Android already has. Nothing said into Lamplight is sent anywhere, and the app has no permission to send it.'**
  String get mediaVoiceFooter;

  /// No description provided for @mediaPhotoSize.
  ///
  /// In en, this message translates to:
  /// **'Photo size'**
  String get mediaPhotoSize;

  /// No description provided for @mediaVideoSize.
  ///
  /// In en, this message translates to:
  /// **'Video size'**
  String get mediaVideoSize;

  /// No description provided for @mediaAskEachTime.
  ///
  /// In en, this message translates to:
  /// **'Ask each time'**
  String get mediaAskEachTime;

  /// No description provided for @accentAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get accentAmber;

  /// The default accent. Evokes a lamp burning at night, which is the whole image the app is named for — keep that picture rather than the literal words if your language has a better one for it.
  ///
  /// In en, this message translates to:
  /// **'A lamp at night. The default.'**
  String get accentAmberNote;

  /// No description provided for @accentRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get accentRose;

  /// No description provided for @accentRoseNote.
  ///
  /// In en, this message translates to:
  /// **'Warm pink. Softer than the amber.'**
  String get accentRoseNote;

  /// No description provided for @accentSage.
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get accentSage;

  /// 'The calmest of the six' — a comparison among the accents, not a claim about the colour in general.
  ///
  /// In en, this message translates to:
  /// **'Quiet green. The calmest of the six.'**
  String get accentSageNote;

  /// No description provided for @accentSlate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get accentSlate;

  /// No description provided for @accentSlateNote.
  ///
  /// In en, this message translates to:
  /// **'Cool blue-grey. The most neutral.'**
  String get accentSlateNote;

  /// No description provided for @accentPlum.
  ///
  /// In en, this message translates to:
  /// **'Plum'**
  String get accentPlum;

  /// No description provided for @accentPlumNote.
  ///
  /// In en, this message translates to:
  /// **'Deep purple.'**
  String get accentPlumNote;

  /// No description provided for @accentEmber.
  ///
  /// In en, this message translates to:
  /// **'Ember'**
  String get accentEmber;

  /// No description provided for @accentEmberNote.
  ///
  /// In en, this message translates to:
  /// **'Burnt orange. The warmest.'**
  String get accentEmberNote;

  /// No description provided for @surfacePlain.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get surfacePlain;

  /// No description provided for @surfacePlainNote.
  ///
  /// In en, this message translates to:
  /// **'A flat page.'**
  String get surfacePlainNote;

  /// No description provided for @surfacePaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get surfacePaper;

  /// 'Reads as a surface' means the eye takes it for a material rather than for an empty background. The contrast being drawn is with surfacePlain.
  ///
  /// In en, this message translates to:
  /// **'A soft grain, so the page reads as a surface. The default.'**
  String get surfacePaperNote;

  /// No description provided for @surfaceLamplit.
  ///
  /// In en, this message translates to:
  /// **'Lamplit'**
  String get surfaceLamplit;

  /// No description provided for @surfaceLamplitNote.
  ///
  /// In en, this message translates to:
  /// **'Paper, with the lamp on.'**
  String get surfaceLamplitNote;

  /// No description provided for @surfaceStarMap.
  ///
  /// In en, this message translates to:
  /// **'Star map'**
  String get surfaceStarMap;

  /// One sky, rotating at the real sidereal rate. 'Never the same twice in a day' is literally true and is the point — it is a sky, not a screensaver.
  ///
  /// In en, this message translates to:
  /// **'One sky, turning with the clock. Never the same twice in a day.'**
  String get surfaceStarMapNote;

  /// No description provided for @rulingNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get rulingNone;

  /// No description provided for @rulingNoneNote.
  ///
  /// In en, this message translates to:
  /// **'Nothing printed on the page.'**
  String get rulingNoneNote;

  /// No description provided for @rulingLines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get rulingLines;

  /// No description provided for @rulingLinesNote.
  ///
  /// In en, this message translates to:
  /// **'Ruled like a notebook.'**
  String get rulingLinesNote;

  /// No description provided for @rulingIsometric.
  ///
  /// In en, this message translates to:
  /// **'Isometric'**
  String get rulingIsometric;

  /// No description provided for @rulingIsometricNote.
  ///
  /// In en, this message translates to:
  /// **'Drafting paper, for thinking in three dimensions.'**
  String get rulingIsometricNote;

  /// No description provided for @rulingTriangle.
  ///
  /// In en, this message translates to:
  /// **'Triangle'**
  String get rulingTriangle;

  /// No description provided for @rulingTriangleNote.
  ///
  /// In en, this message translates to:
  /// **'A field of equilateral triangles.'**
  String get rulingTriangleNote;

  /// No description provided for @rulingDots.
  ///
  /// In en, this message translates to:
  /// **'Dot grid'**
  String get rulingDots;

  /// 'The quietest of the four' compares it with the other rulings, not with a blank page.
  ///
  /// In en, this message translates to:
  /// **'A dot at each crossing. The quietest of the four.'**
  String get rulingDotsNote;

  /// No description provided for @faceSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get faceSystem;

  /// The platform's own font. Not a Lamplight typeface at all.
  ///
  /// In en, this message translates to:
  /// **'Whatever the rest of your phone uses.'**
  String get faceSystemNote;

  /// No description provided for @faceSerif.
  ///
  /// In en, this message translates to:
  /// **'System Serif'**
  String get faceSerif;

  /// No description provided for @faceSerifNote.
  ///
  /// In en, this message translates to:
  /// **'Your phone’s own serif.'**
  String get faceSerifNote;

  /// No description provided for @faceCalmNote.
  ///
  /// In en, this message translates to:
  /// **'Soft edges, wide letters.'**
  String get faceCalmNote;

  /// No description provided for @faceModernNote.
  ///
  /// In en, this message translates to:
  /// **'Tight and current.'**
  String get faceModernNote;

  /// No description provided for @faceOldStyleNote.
  ///
  /// In en, this message translates to:
  /// **'A book face from the 1500s.'**
  String get faceOldStyleNote;

  /// No description provided for @facePlayfulNote.
  ///
  /// In en, this message translates to:
  /// **'Round and cheerful.'**
  String get facePlayfulNote;

  /// No description provided for @faceChildlikeNote.
  ///
  /// In en, this message translates to:
  /// **'An exercise book.'**
  String get faceChildlikeNote;

  /// The point is the qualification: it looks handwritten AND you can still read a page of it. Both halves matter.
  ///
  /// In en, this message translates to:
  /// **'Handwriting, still readable at length.'**
  String get faceHandwrittenNote;

  /// A scribe's hand. 'One weight only' means there is no bold — a real limitation, said plainly.
  ///
  /// In en, this message translates to:
  /// **'A scribe’s hand. One weight only.'**
  String get faceMedievalNote;

  /// No description provided for @faceMonoNote.
  ///
  /// In en, this message translates to:
  /// **'Every letter the same width.'**
  String get faceMonoNote;

  /// Shared by the photo and the video size settings. The two have different notes but the same three choices.
  ///
  /// In en, this message translates to:
  /// **'Keep the original'**
  String get qualityOriginal;

  /// No description provided for @qualityBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get qualityBalanced;

  /// No description provided for @qualitySmaller.
  ///
  /// In en, this message translates to:
  /// **'Smaller'**
  String get qualitySmaller;

  /// The second sentence is the one that matters and must not be dropped: keeping the original also keeps the GPS location, which Lamplight otherwise strips. Somebody choosing this should know they are choosing that too.
  ///
  /// In en, this message translates to:
  /// **'Kept exactly as your camera made it. The largest files — and they keep the place the photo was taken, which Lamplight otherwise removes.'**
  String get photoOriginalNote;

  /// No description provided for @photoBalancedNote.
  ///
  /// In en, this message translates to:
  /// **'Much smaller, and hard to tell apart from the original. The default.'**
  String get photoBalancedNote;

  /// No description provided for @photoSmallerNote.
  ///
  /// In en, this message translates to:
  /// **'Half the size again. You may notice it if you crop right in.'**
  String get photoSmallerNote;

  /// No description provided for @videoOriginalNote.
  ///
  /// In en, this message translates to:
  /// **'Kept exactly as your camera recorded it. The largest files by a long way.'**
  String get videoOriginalNote;

  /// 'The default.' is a fragment on purpose in English — a short label after the sentence. Use whatever is natural rather than forcing the fragment.
  ///
  /// In en, this message translates to:
  /// **'Much smaller, and hard to tell apart from the original. The default.'**
  String get videoBalancedNote;

  /// No description provided for @videoSmallerNote.
  ///
  /// In en, this message translates to:
  /// **'Half the size again. You may notice it on a big screen.'**
  String get videoSmallerNote;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appearanceTheme;

  /// No description provided for @appearanceThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceThemeDark;

  /// No description provided for @appearanceThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceThemeLight;

  /// The third theme choice, and since round seventeen the DEFAULT for a new install: follow the phone. It sits on a small chip beside Dark and Light and may wrap to two centred lines, so a short phrase is fine and a long sentence is not. Prefer the wording the reader's own phone settings use for this.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get appearanceThemeAuto;

  /// Shown under the chips when Auto is chosen. Says what 'Auto' actually follows, because the word alone does not.
  ///
  /// In en, this message translates to:
  /// **'Follows your phone’s light and dark setting.'**
  String get appearanceThemeAutoNote;

  /// No description provided for @appearanceFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get appearanceFont;

  /// Heading for the text-size slider. The value beside it is shown as a percentage, which is the only honest label — 'Larger' told nobody how much larger.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get appearanceSize;

  /// No description provided for @appearanceColour.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get appearanceColour;

  /// No description provided for @appearancePage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get appearancePage;

  /// Heading for what is printed on the page: lines, isometric, triangles, dots, or nothing. The word for a notebook's ruling, not for a rule or a regulation.
  ///
  /// In en, this message translates to:
  /// **'Ruling'**
  String get appearanceRuling;

  /// Shown after something is captured while a past day is on screen. It went to *today*, not to the day being looked at — that is the whole information in the sentence.
  ///
  /// In en, this message translates to:
  /// **'Saved to today.'**
  String get daySavedToToday;

  /// No description provided for @dayAddedToToday.
  ///
  /// In en, this message translates to:
  /// **'Added to today.'**
  String get dayAddedToToday;

  /// Menu item on an entry that has both an attachment and a caption. Edits the words, not the attachment.
  ///
  /// In en, this message translates to:
  /// **'Edit the words'**
  String get entryEditWords;

  /// Menu item on an album — several photographs sharing one entry. 'The whole block' warns that it is not just the one tile being looked at.
  ///
  /// In en, this message translates to:
  /// **'Delete the whole block'**
  String get entryDeleteBlock;

  /// {name} is the filename the copy was written as. Shown after 'Save a copy' finishes.
  ///
  /// In en, this message translates to:
  /// **'Saved as {name}.'**
  String entrySavedAs(String name);

  /// {name} is the folder's name. Confirms the entry is *also* in that folder — it has not moved off its day. See folderAlsoIn for the same idea in a different place.
  ///
  /// In en, this message translates to:
  /// **'Also in {name}.'**
  String entryAddedToFolder(String name);

  /// No description provided for @entrySaveCopy.
  ///
  /// In en, this message translates to:
  /// **'Save a copy'**
  String get entrySaveCopy;

  /// Subtitle under 'Save a copy'. Says the copy leaves Lamplight, which is the thing to be clear about — it will not be encrypted where it lands.
  ///
  /// In en, this message translates to:
  /// **'Somewhere you choose, outside Lamplight'**
  String get entrySaveCopyNote;

  /// No description provided for @capturePhotoTake.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get capturePhotoTake;

  /// No description provided for @capturePhotoChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose from your photos'**
  String get capturePhotoChoose;

  /// Placeholder in the writing box on today. An invitation, never an instruction — ETHICAL-DESIGN.md forbids anything implying the user owes the app writing.
  ///
  /// In en, this message translates to:
  /// **'Write about today…'**
  String get composerHintToday;

  /// The same placeholder on a day that is not today.
  ///
  /// In en, this message translates to:
  /// **'Write about this day…'**
  String get composerHintPast;

  /// Starts a second block of writing on the same day, so a morning and an evening can be separate entries.
  ///
  /// In en, this message translates to:
  /// **'New block'**
  String get composerNewBlock;

  /// No description provided for @voiceShowTranscript.
  ///
  /// In en, this message translates to:
  /// **'Show what was said'**
  String get voiceShowTranscript;

  /// No description provided for @voiceHideTranscript.
  ///
  /// In en, this message translates to:
  /// **'Hide what was said'**
  String get voiceHideTranscript;

  /// Heading over the text of what was said in a voice note. Not 'Transcript' — that names the machinery.
  ///
  /// In en, this message translates to:
  /// **'What was said'**
  String get voiceTranscriptTitle;

  /// Appended after a time, as in '14:20, edited'. Keep the leading comma and space if your language uses them.
  ///
  /// In en, this message translates to:
  /// **', edited'**
  String get entryEdited;

  /// Read aloud by a screen reader for a photograph in the day. {time} is when it was added.
  ///
  /// In en, this message translates to:
  /// **'Photo at {time}. Double tap to view.'**
  String photoSemantic(String time);

  /// No description provided for @sizeThisPhoto.
  ///
  /// In en, this message translates to:
  /// **'this photo'**
  String get sizeThisPhoto;

  /// No description provided for @sizeThesePhotos.
  ///
  /// In en, this message translates to:
  /// **'these photos'**
  String get sizeThesePhotos;

  /// No description provided for @sizeThisVideo.
  ///
  /// In en, this message translates to:
  /// **'this video'**
  String get sizeThisVideo;

  /// No description provided for @sizeTheseVideos.
  ///
  /// In en, this message translates to:
  /// **'these videos'**
  String get sizeTheseVideos;

  /// Asked when importing, if 'Ask each time' is on. {what} is one of the four strings above — 'this photo', 'these videos' and so on — so it has to fit a sentence in your language. Rephrase the sentence if the grammar needs it.
  ///
  /// In en, this message translates to:
  /// **'How big should {what} be kept?'**
  String sizeQuestion(String what);

  /// Under the Trash heading. A plain statement of what happens, not a warning — nothing here is urgent.
  ///
  /// In en, this message translates to:
  /// **'Deleted entries stay here for 30 days, then go for good.'**
  String get trashNote;

  /// Asked before emptying the trash. The one destructive confirmation in the app that cannot be undone, so it asks rather than telling.
  ///
  /// In en, this message translates to:
  /// **'Delete these for good?'**
  String get trashConfirm;

  /// The safe answer, and it is listed first everywhere this pattern appears. ETHICAL-DESIGN.md: never make the safe choice the harder one.
  ///
  /// In en, this message translates to:
  /// **'Keep them'**
  String get trashKeep;

  /// No description provided for @trashDeleteForGood.
  ///
  /// In en, this message translates to:
  /// **'Delete for good'**
  String get trashDeleteForGood;

  /// No description provided for @trashPutBack.
  ///
  /// In en, this message translates to:
  /// **'Put back'**
  String get trashPutBack;

  /// {day} is the date the entry came from. It goes back where it was, not to today — that is the reassurance.
  ///
  /// In en, this message translates to:
  /// **'Put back on {day}.'**
  String trashPutBackOn(String day);

  /// No description provided for @trashEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get trashEmpty;

  /// No description provided for @folderMakeFirst.
  ///
  /// In en, this message translates to:
  /// **'Make the first one'**
  String get folderMakeFirst;

  /// {name} is the folder's name, already in typographic quotes in English. Use whatever quotation marks your language uses.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String folderDeleteAsk(String name);

  /// No description provided for @folderKeepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get folderKeepIt;

  /// No description provided for @folderDeleteIt.
  ///
  /// In en, this message translates to:
  /// **'Delete the folder'**
  String get folderDeleteIt;

  /// No description provided for @folderRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get folderRename;

  /// No description provided for @folderDeleteThis.
  ///
  /// In en, this message translates to:
  /// **'Delete this folder'**
  String get folderDeleteThis;

  /// {name} is the folder. The second sentence carries the whole folder model: an entry lives on its day and a folder is only a second place to find it, so removing it from a folder loses nothing.
  ///
  /// In en, this message translates to:
  /// **'Taken out of {name}. It is still on its day.'**
  String folderTakenOut(String name);

  /// Placeholder in the search box. Three examples rather than an instruction, because the box accepts all three and nobody would guess the second.
  ///
  /// In en, this message translates to:
  /// **'Words, a date, a name…'**
  String get searchHint;

  /// No description provided for @searchBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get searchBack;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClear;

  /// No description provided for @searchNothingMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches “{query}”.'**
  String searchNothingMatches(String query);

  /// Heading over entries the person marked. Upper case in English; scripts without case are left as they are.
  ///
  /// In en, this message translates to:
  /// **'WHAT MATTERED'**
  String get searchWhatMattered;

  /// No description provided for @searchADate.
  ///
  /// In en, this message translates to:
  /// **'A date'**
  String get searchADate;

  /// Examples of date searches that work, separated by middots. Translate the words — 'yesterday' — and leave the numeric date in a form your language would type.
  ///
  /// In en, this message translates to:
  /// **'16 March 2006 · march 2006 · yesterday'**
  String get searchDateExample;

  /// No description provided for @searchWhatYouCanType.
  ///
  /// In en, this message translates to:
  /// **'What you can look for'**
  String get searchWhatYouCanType;

  /// No description provided for @searchTryDate.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get searchTryDate;

  /// Appended to a voice note in results, as in 'said out loud'. Marks that the match came from the transcript rather than from typed words.
  ///
  /// In en, this message translates to:
  /// **'said out loud'**
  String get searchSaidOutLoud;

  /// No description provided for @searchAPhotograph.
  ///
  /// In en, this message translates to:
  /// **'A photograph'**
  String get searchAPhotograph;

  /// No description provided for @searchAVideo.
  ///
  /// In en, this message translates to:
  /// **'A video'**
  String get searchAVideo;

  /// Group heading for the idle timeout — how long the app waits before locking itself while it is still open.
  ///
  /// In en, this message translates to:
  /// **'While the app is open'**
  String get securityWhileOpen;

  /// Says the one thing that is not configurable, so nobody looks for a switch for it. Locking on background is non-negotiable and this is where that is stated.
  ///
  /// In en, this message translates to:
  /// **'Lamplight always locks the moment it goes into the background. This is only about how long it waits while you are still in it.'**
  String get securityLockFooter;

  /// No description provided for @securityLockAfter.
  ///
  /// In en, this message translates to:
  /// **'Lock after'**
  String get securityLockAfter;

  /// No description provided for @securityOneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get securityOneHour;

  /// No description provided for @securityYourPasscode.
  ///
  /// In en, this message translates to:
  /// **'Your passcode'**
  String get securityYourPasscode;

  /// The central claim of the whole app, and it must stay exactly this strong and this narrow. Not 'your data is safe' — the specific fact that the passcode is not stored, and what follows from that.
  ///
  /// In en, this message translates to:
  /// **'Your passcode is the key. It is not stored anywhere — not on this phone and nowhere else — so nobody can be made to hand it over, and nobody can recover it for you.'**
  String get securityPasscodeFooter;

  /// No description provided for @securityChangePasscode.
  ///
  /// In en, this message translates to:
  /// **'Change passcode'**
  String get securityChangePasscode;

  /// No description provided for @securityScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get securityScreenshots;

  /// Explains what the app does by default and what the switch below gives up. It is the user's phone and their choice; the footer must not sound like a warning against it.
  ///
  /// In en, this message translates to:
  /// **'Lamplight blocks screen capture so that whoever picks up your phone cannot photograph your notes, and so they never appear in the recent-apps preview. You can turn that off for your own phone.'**
  String get securityScreenshotsFooter;

  /// No description provided for @securityAllowScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Allow screenshots'**
  String get securityAllowScreenshots;

  /// No description provided for @securityScreenshotsOn.
  ///
  /// In en, this message translates to:
  /// **'Your notes will show in recent apps'**
  String get securityScreenshotsOn;

  /// No description provided for @securityScreenshotsOff.
  ///
  /// In en, this message translates to:
  /// **'Recent apps shows a blank page'**
  String get securityScreenshotsOff;

  /// No description provided for @securityCouldNotChange.
  ///
  /// In en, this message translates to:
  /// **'That could not be changed.'**
  String get securityCouldNotChange;

  /// No description provided for @securityNothingChanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing about your locking has changed.'**
  String get securityNothingChanged;

  /// No description provided for @securityPromptAutomatic.
  ///
  /// In en, this message translates to:
  /// **'The prompt appears by itself'**
  String get securityPromptAutomatic;

  /// No description provided for @securityPromptOnTap.
  ///
  /// In en, this message translates to:
  /// **'Tap the fingerprint when you want it'**
  String get securityPromptOnTap;

  /// No description provided for @mediaAskEachTimeOn.
  ///
  /// In en, this message translates to:
  /// **'You are asked how big to keep photos and videos as you add them.'**
  String get mediaAskEachTimeOn;

  /// No description provided for @mediaAskEachTimeOff.
  ///
  /// In en, this message translates to:
  /// **'Off. The two sizes above are used without asking.'**
  String get mediaAskEachTimeOff;

  /// No description provided for @passcodeNew.
  ///
  /// In en, this message translates to:
  /// **'New passcode'**
  String get passcodeNew;

  /// No description provided for @securityFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get securityFingerprint;

  /// Word for word the same promise onboarding makes, deliberately — two descriptions of one security feature is how somebody ends up trusting neither. Keep it identical to onboardFingerprintExplain.
  ///
  /// In en, this message translates to:
  /// **'Your passcode is still the key. The fingerprint only opens this vault, only on this phone, and Android switches it off by itself if the fingerprints on the phone ever change — so nobody can add theirs and get in. It is never part of a backup.'**
  String get securityFingerprintFooter;

  /// No description provided for @securityUnlockWithFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Unlock with my fingerprint'**
  String get securityUnlockWithFingerprint;

  /// Whether the fingerprint prompt appears by itself the moment Lamplight opens, rather than waiting to be asked for.
  ///
  /// In en, this message translates to:
  /// **'Ask as soon as Lamplight opens'**
  String get securityAskOnOpen;

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 second} other{{count} seconds}}'**
  String durationSeconds(int count);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 minute} other{{count} minutes}}'**
  String durationMinutes(int count);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 hour} other{{count} hours}}'**
  String durationHours(int count);

  /// The idle timeout turned off. It does NOT mean the app never locks — securityNeverNote says what still happens, and the two are always shown together.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get durationNever;

  /// No description provided for @securityDefaultNote.
  ///
  /// In en, this message translates to:
  /// **'The default.'**
  String get securityDefaultNote;

  /// No description provided for @securityHourNote.
  ///
  /// In en, this message translates to:
  /// **'For an afternoon of reading back.'**
  String get securityHourNote;

  /// Sits under 'Never'. The reassurance that matters: locking on background is not a setting and is still in force.
  ///
  /// In en, this message translates to:
  /// **'It still locks the second you leave the app.'**
  String get securityNeverNote;

  /// No description provided for @calendarGoToDate.
  ///
  /// In en, this message translates to:
  /// **'Go to a date'**
  String get calendarGoToDate;

  /// No description provided for @dayHasWriting.
  ///
  /// In en, this message translates to:
  /// **'writing'**
  String get dayHasWriting;

  /// No description provided for @dayHasPhoto.
  ///
  /// In en, this message translates to:
  /// **'a photo'**
  String get dayHasPhoto;

  /// No description provided for @dayHasVideo.
  ///
  /// In en, this message translates to:
  /// **'a video'**
  String get dayHasVideo;

  /// No description provided for @dayHasVoice.
  ///
  /// In en, this message translates to:
  /// **'a voice note'**
  String get dayHasVoice;

  /// No description provided for @dayHasFile.
  ///
  /// In en, this message translates to:
  /// **'a file'**
  String get dayHasFile;

  /// No description provided for @dayEntriesAndKinds.
  ///
  /// In en, this message translates to:
  /// **'{count}, {kinds}'**
  String dayEntriesAndKinds(Object count, Object kinds);

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @listAnd.
  ///
  /// In en, this message translates to:
  /// **'{most} and {last}'**
  String listAnd(Object last, Object most);

  /// No description provided for @integrityNothingUnusual.
  ///
  /// In en, this message translates to:
  /// **'Nothing unusual about this phone. Lamplight is running the way it is meant to.'**
  String get integrityNothingUnusual;

  /// No description provided for @calendarPreviousYear.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get calendarPreviousYear;

  /// No description provided for @calendarPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPreviousMonth;

  /// No description provided for @calendarNextYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get calendarNextYear;

  /// No description provided for @calendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonth;

  /// No description provided for @calendarBackToMonth.
  ///
  /// In en, this message translates to:
  /// **'Back to the month'**
  String get calendarBackToMonth;

  /// No description provided for @calendarWholeYear.
  ///
  /// In en, this message translates to:
  /// **'The whole year'**
  String get calendarWholeYear;

  /// No description provided for @calendarBackToThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Back to this month'**
  String get calendarBackToThisMonth;

  /// No description provided for @calendarNothingThisYear.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this year yet.'**
  String get calendarNothingThisYear;

  /// No description provided for @calendarYearSummary.
  ///
  /// In en, this message translates to:
  /// **'{entries} on {days}.'**
  String calendarYearSummary(Object days, Object entries);

  /// No description provided for @folderNothingInIt.
  ///
  /// In en, this message translates to:
  /// **'Nothing in it yet'**
  String get folderNothingInIt;

  /// No description provided for @onThisDayOneYear.
  ///
  /// In en, this message translates to:
  /// **'A year ago today'**
  String get onThisDayOneYear;

  /// No description provided for @onThisDayYears.
  ///
  /// In en, this message translates to:
  /// **'{years} years ago today'**
  String onThisDayYears(Object years);

  /// No description provided for @wheelYear.
  ///
  /// In en, this message translates to:
  /// **'Year {year}'**
  String wheelYear(Object year);

  /// No description provided for @calendarBackToBrowsing.
  ///
  /// In en, this message translates to:
  /// **'Back to browsing'**
  String get calendarBackToBrowsing;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// A shortcut in the date picker that jumps to the earliest thing in the vault.
  ///
  /// In en, this message translates to:
  /// **'Your first entry'**
  String get calendarFirstEntry;

  /// No description provided for @calendarGoToThisDay.
  ///
  /// In en, this message translates to:
  /// **'Go to this day'**
  String get calendarGoToThisDay;

  /// Explains the colour ramp on the year grid. Colour is never the only channel in this app, so this sentence is what carries the meaning for anybody who cannot see it.
  ///
  /// In en, this message translates to:
  /// **'Colour shows how much is on a day, from nothing to a lot.'**
  String get calendarDensityNote;

  /// One end of the year grid's colour scale. A single word beside a row of swatches, so keep it short.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get calendarLess;

  /// No description provided for @calendarMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get calendarMore;

  /// No description provided for @calendarGoToToday.
  ///
  /// In en, this message translates to:
  /// **'Go to today'**
  String get calendarGoToToday;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupTitle;

  /// No description provided for @vaultNothingToBackUp.
  ///
  /// In en, this message translates to:
  /// **'There is nothing in this vault to back up yet.'**
  String get vaultNothingToBackUp;

  /// No description provided for @vaultChangedWhileBackingUp.
  ///
  /// In en, this message translates to:
  /// **'Something changed while the backup was being made ({name}). Try again.'**
  String vaultChangedWhileBackingUp(Object name);

  /// No description provided for @vaultTooSmall.
  ///
  /// In en, this message translates to:
  /// **'This file is too small to be a Lamplight backup.'**
  String get vaultTooSmall;

  /// No description provided for @vaultNotALamplightFile.
  ///
  /// In en, this message translates to:
  /// **'This is not a Lamplight backup file.'**
  String get vaultNotALamplightFile;

  /// No description provided for @vaultDamaged.
  ///
  /// In en, this message translates to:
  /// **'This file is damaged and cannot be opened.'**
  String get vaultDamaged;

  /// No description provided for @vaultKeyringNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'This vault was made by a newer version of Lamplight. Update the app to open it.'**
  String get vaultKeyringNewerVersion;

  /// No description provided for @vaultKeyringDamaged.
  ///
  /// In en, this message translates to:
  /// **'The vault key file is damaged and cannot be read. If you have a backup file, restore from it.'**
  String get vaultKeyringDamaged;

  /// No description provided for @vaultDatabaseNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'This vault was made by a newer version of Lamplight. Update the app to open it — your notes are safe and nothing has been changed.'**
  String get vaultDatabaseNewerVersion;

  /// No description provided for @phraseWrongLength.
  ///
  /// In en, this message translates to:
  /// **'A recovery phrase is 12 words. This one has {count}.'**
  String phraseWrongLength(Object count);

  /// No description provided for @phraseNotARecoveryWord.
  ///
  /// In en, this message translates to:
  /// **'\"{word}\" is not one of the recovery words.'**
  String phraseNotARecoveryWord(Object word);

  /// No description provided for @phraseDoesNotCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Those words are not a valid recovery phrase. Check for a mistyped or swapped word.'**
  String get phraseDoesNotCheckOut;

  /// No description provided for @vaultNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'This backup was made with a newer version of Lamplight. Update the app, then try again.'**
  String get vaultNewerVersion;

  /// No description provided for @vaultUnknownCompression.
  ///
  /// In en, this message translates to:
  /// **'This backup uses a compression this version does not know how to read.'**
  String get vaultUnknownCompression;

  /// No description provided for @vaultDamagedTryOlder.
  ///
  /// In en, this message translates to:
  /// **'This file is damaged and cannot be opened. If you have an older backup, try that one.'**
  String get vaultDamagedTryOlder;

  /// No description provided for @vaultBeforeRecoveryPhrases.
  ///
  /// In en, this message translates to:
  /// **'This backup was made before recovery phrases could open backup files. Its passcode is the only way in.'**
  String get vaultBeforeRecoveryPhrases;

  /// No description provided for @vaultWordsDoNotOpenIt.
  ///
  /// In en, this message translates to:
  /// **'Those words do not open this file. They may belong to a different vault.'**
  String get vaultWordsDoNotOpenIt;

  /// No description provided for @vaultWrongPasscode.
  ///
  /// In en, this message translates to:
  /// **'That passcode does not open this file.'**
  String get vaultWrongPasscode;

  /// No description provided for @vaultMissingPart.
  ///
  /// In en, this message translates to:
  /// **'This backup is missing part of itself ({name}).'**
  String vaultMissingPart(Object name);

  /// No description provided for @vaultPartWrongSize.
  ///
  /// In en, this message translates to:
  /// **'This backup is damaged ({name} is the wrong size).'**
  String vaultPartWrongSize(Object name);

  /// No description provided for @vaultPartDoesNotMatch.
  ///
  /// In en, this message translates to:
  /// **'This backup is damaged ({name} does not match).'**
  String vaultPartDoesNotMatch(Object name);

  /// No description provided for @vaultNoVaultInside.
  ///
  /// In en, this message translates to:
  /// **'This backup does not contain a vault. It may have been made by a different app.'**
  String get vaultNoVaultInside;

  /// No description provided for @vaultOutOfOrder.
  ///
  /// In en, this message translates to:
  /// **'This file is damaged: its contents are out of order.'**
  String get vaultOutOfOrder;

  /// No description provided for @vaultEndsPartWay.
  ///
  /// In en, this message translates to:
  /// **'This file is damaged: it ends part-way through.'**
  String get vaultEndsPartWay;

  /// No description provided for @vaultIncomplete.
  ///
  /// In en, this message translates to:
  /// **'This file is incomplete — it has {parts} of its parts.'**
  String vaultIncomplete(Object parts);

  /// No description provided for @vaultWillNotOpen.
  ///
  /// In en, this message translates to:
  /// **'This backup contains something Lamplight will not open ({name}).'**
  String vaultWillNotOpen(Object name);

  /// No description provided for @countEntries.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 entry} other{{count} entries}}'**
  String countEntries(num count);

  /// No description provided for @countDays.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 day} other{{count} days}}'**
  String countDays(num count);

  /// No description provided for @backupCheckingItOpens.
  ///
  /// In en, this message translates to:
  /// **'Checking it opens…'**
  String get backupCheckingItOpens;

  /// No description provided for @backupCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'The backup could not be saved.'**
  String get backupCouldNotSave;

  /// No description provided for @backupNothingLost.
  ///
  /// In en, this message translates to:
  /// **'Nothing was lost, and your notes are untouched. Try again in a moment.'**
  String get backupNothingLost;

  /// No description provided for @backupLast.
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get backupLast;

  /// No description provided for @backupInTheVault.
  ///
  /// In en, this message translates to:
  /// **'In the vault'**
  String get backupInTheVault;

  /// No description provided for @restoreCheckingFile.
  ///
  /// In en, this message translates to:
  /// **'Checking the file…'**
  String get restoreCheckingFile;

  /// No description provided for @restoreCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'That file could not be opened.'**
  String get restoreCouldNotOpen;

  /// No description provided for @restoreCheckItIsTheOne.
  ///
  /// In en, this message translates to:
  /// **'Check it is the backup you meant, and try again.'**
  String get restoreCheckItIsTheOne;

  /// No description provided for @restorePuttingInPlace.
  ///
  /// In en, this message translates to:
  /// **'Putting it in place…'**
  String get restorePuttingInPlace;

  /// No description provided for @restorePuttingBack.
  ///
  /// In en, this message translates to:
  /// **'Putting your old notes back…'**
  String get restorePuttingBack;

  /// No description provided for @restoreCouldNotFinish.
  ///
  /// In en, this message translates to:
  /// **'The restore could not be finished.'**
  String get restoreCouldNotFinish;

  /// No description provided for @restoreBackAsTheyWere.
  ///
  /// In en, this message translates to:
  /// **'Your notes are back as they were.'**
  String get restoreBackAsTheyWere;

  /// No description provided for @restoreUsePasscodeInstead.
  ///
  /// In en, this message translates to:
  /// **'Use the passcode instead'**
  String get restoreUsePasscodeInstead;

  /// No description provided for @restoreUseWordsInstead.
  ///
  /// In en, this message translates to:
  /// **'I have the twelve words instead'**
  String get restoreUseWordsInstead;

  /// No description provided for @backupCreateFile.
  ///
  /// In en, this message translates to:
  /// **'Create backup file'**
  String get backupCreateFile;

  /// No description provided for @backupCreatedChecked.
  ///
  /// In en, this message translates to:
  /// **'Backup created and checked.'**
  String get backupCreatedChecked;

  /// No description provided for @backupMakeAnother.
  ///
  /// In en, this message translates to:
  /// **'Make another'**
  String get backupMakeAnother;

  /// No description provided for @backupRestoreHeading.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestoreHeading;

  /// No description provided for @backupRestoreFrom.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup file'**
  String get backupRestoreFrom;

  /// Read aloud while a backup runs. {stage} is already a sentence like 'Reading your notes…' and {percent} is a whole number.
  ///
  /// In en, this message translates to:
  /// **'{stage} {percent} per cent'**
  String backupProgress(String stage, int percent);

  /// No description provided for @restoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreTitle;

  /// No description provided for @restoreChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get restoreChooseFile;

  /// No description provided for @restoreUseLatest.
  ///
  /// In en, this message translates to:
  /// **'Use my latest backup'**
  String get restoreUseLatest;

  /// Placeholder in the recovery-phrase box. Three words of an example phrase — keep them as example words in your language, or leave the English ones if your language has no wordlist. They are only a shape.
  ///
  /// In en, this message translates to:
  /// **'remember story industry…'**
  String get restorePhraseHint;

  /// No description provided for @restoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreAction;

  /// No description provided for @restoreChooseDifferent.
  ///
  /// In en, this message translates to:
  /// **'Choose a different file'**
  String get restoreChooseDifferent;

  /// No description provided for @importChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get importChooseFolder;

  /// No description provided for @importChooseFiles.
  ///
  /// In en, this message translates to:
  /// **'Choose the files instead'**
  String get importChooseFiles;

  /// No description provided for @importChooseFilesNote.
  ///
  /// In en, this message translates to:
  /// **'If Android refuses your folder — it will not give any app Downloads, or the top of your storage — pick the files themselves. Nothing refuses that.'**
  String get importChooseFilesNote;

  /// No description provided for @importLooking.
  ///
  /// In en, this message translates to:
  /// **'Looking through the folder…'**
  String get importLooking;

  /// No description provided for @importNoTextFiles.
  ///
  /// In en, this message translates to:
  /// **'There are no text files in that folder.'**
  String get importNoTextFiles;

  /// No description provided for @importChooseDifferentFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a different folder'**
  String get importChooseDifferentFolder;

  /// A switch shown when filenames carry no date. Falls back to when the file was last changed.
  ///
  /// In en, this message translates to:
  /// **'Use the file’s own date for these'**
  String get importUseFileDate;

  /// The honest caveat: a file's modification date is often not the day it was written about, so this is offered rather than assumed.
  ///
  /// In en, this message translates to:
  /// **'Puts them on the day the file was last changed. That is often not the day it is about.'**
  String get importUseFileDateNote;

  /// The button that starts the import. {count} is how many notes were found.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Bring in 1 note} other{Bring in {count} notes}}'**
  String importBringIn(int count);

  /// No description provided for @importProgress.
  ///
  /// In en, this message translates to:
  /// **'Importing, {percent} per cent'**
  String importProgress(int percent);

  /// No description provided for @exportChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder and export'**
  String get exportChooseFolder;

  /// No description provided for @exportSave.
  ///
  /// In en, this message translates to:
  /// **'Save a readable copy'**
  String get exportSave;

  /// No description provided for @exportWritten.
  ///
  /// In en, this message translates to:
  /// **'Your copy is written.'**
  String get exportWritten;

  /// No description provided for @exportAgain.
  ///
  /// In en, this message translates to:
  /// **'Export again'**
  String get exportAgain;

  /// Heading above the two paragraphs comparing a backup with a readable copy, for somebody who does not know which they want.
  ///
  /// In en, this message translates to:
  /// **'Which one do I want?'**
  String get exportWhichOne;

  /// The one thing somebody must understand before making a readable copy. It is plain files: anyone who opens that folder can read them. Must not be softened.
  ///
  /// In en, this message translates to:
  /// **'This copy is not locked'**
  String get exportNotLocked;

  /// Shown when several files are shared into Lamplight from another app at once. They go to today, whichever day is on screen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Added {count} things to today.}}'**
  String dayAddedThings(int count);

  /// Menu item on an attachment that has no caption yet. 'This' is the photograph or file being looked at.
  ///
  /// In en, this message translates to:
  /// **'Add a note to this'**
  String get entryAddNote;

  /// Confirms an import. The one-item form says only 'Added.' because the photograph is already visible on the day — repeating the count would be noise.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Added.} other{Added {count}.}}'**
  String importAdded(int count);

  /// No description provided for @importFolderUnreadable.
  ///
  /// In en, this message translates to:
  /// **'That folder could not be read.'**
  String get importFolderUnreadable;

  /// No description provided for @importNothingBrought.
  ///
  /// In en, this message translates to:
  /// **'Nothing was brought in.'**
  String get importNothingBrought;

  /// No description provided for @importStoppedPartWay.
  ///
  /// In en, this message translates to:
  /// **'Bringing the journal in stopped part way.'**
  String get importStoppedPartWay;

  /// No description provided for @importWhatArrivedKept.
  ///
  /// In en, this message translates to:
  /// **'Everything that arrived before it stopped was kept.'**
  String get importWhatArrivedKept;

  /// No description provided for @importNoReadableDates.
  ///
  /// In en, this message translates to:
  /// **'None of those files have a date Lamplight can read.'**
  String get importNoReadableDates;

  /// No description provided for @importReadyToBring.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 note ready to bring in.} other{{count} notes ready to bring in.}}'**
  String importReadyToBring(num count);

  /// No description provided for @importNothingNew.
  ///
  /// In en, this message translates to:
  /// **'Nothing new to bring in.'**
  String get importNothingNew;

  /// No description provided for @importBroughtIn.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 note brought in.} other{{count} notes brought in.}}'**
  String importBroughtIn(num count);

  /// No description provided for @importAlreadyHere.
  ///
  /// In en, this message translates to:
  /// **'{count} were already here, so they were left alone.'**
  String importAlreadyHere(Object count);

  /// No description provided for @importNoDateSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count} had no date to read, and were skipped.'**
  String importNoDateSkipped(Object count);

  /// No description provided for @importCouldNotRead.
  ///
  /// In en, this message translates to:
  /// **'{count} could not be read: {names}'**
  String importCouldNotRead(Object count, Object names);

  /// No description provided for @exportStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get exportStarting;

  /// No description provided for @exportCouldNotFinish.
  ///
  /// In en, this message translates to:
  /// **'The readable copy could not be finished.'**
  String get exportCouldNotFinish;

  /// No description provided for @exportNothingChanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing in Lamplight was changed.'**
  String get exportNothingChanged;

  /// No description provided for @importVideoAlreadySmall.
  ///
  /// In en, this message translates to:
  /// **'One video was already about as small as it gets, so it was kept as it is.'**
  String get importVideoAlreadySmall;

  /// No description provided for @importVideoCouldNotShrink.
  ///
  /// In en, this message translates to:
  /// **'One video could not be made smaller on this phone, so it was kept whole.'**
  String get importVideoCouldNotShrink;

  /// Follows importAdded in the same sentence, as in 'Added 4. One did not work: …'. {reason} is already a plain sentence.
  ///
  /// In en, this message translates to:
  /// **'One did not work: {reason}'**
  String importOneFailed(String reason);

  /// The app locked while files were still being brought in. Not an error and not a loss of anything that was already saved — see importNothingLeft, which always follows it when nothing at all got through.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{One did not finish before Lamplight locked.} other{{count} did not finish before Lamplight locked.}}'**
  String importAbandoned(int count);

  /// The reassurance after importAbandoned. Nothing decrypted was left behind on the phone — CLAUDE.md rule 2. It is a promise the user is owed, so it must not be softened or dropped.
  ///
  /// In en, this message translates to:
  /// **'Nothing was left on the phone.'**
  String get importNothingLeft;

  /// Asked when somebody taps their own name at the top of Settings. Not 'Edit name' — the row can say anything they like, so the question is about the words rather than about a field.
  ///
  /// In en, this message translates to:
  /// **'What should this say?'**
  String get nameCardAsk;

  /// No description provided for @nameCardHint.
  ///
  /// In en, this message translates to:
  /// **'Your name, or anything'**
  String get nameCardHint;

  /// Group heading for the daily writing reminder. 'If you want one' is the whole tone: it is off, and it is an offer.
  ///
  /// In en, this message translates to:
  /// **'A nudge, if you want one'**
  String get reminderGroup;

  /// What the reminder will and will not do. The middle clause is a fact about the software, not a promise of discretion — it cannot mention what is in the notes because it runs while the vault is locked. And the last sentence rules out streaks and counts, which ETHICAL-DESIGN.md forbids outright.
  ///
  /// In en, this message translates to:
  /// **'Off unless you turn it on. It never mentions what is in your notes — it cannot, because it runs while the vault is locked. No streaks, no counts, nothing about days you missed.'**
  String get reminderFooter;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Remind me to write'**
  String get reminderTitle;

  /// No description provided for @reminderWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get reminderWhen;

  /// The Android 13+ runtime permission is refused. First of the four gates, reported before any other because nothing else matters without it.
  ///
  /// In en, this message translates to:
  /// **'Lamplight is not allowed to send notifications.'**
  String get reminderProblemNotAllowed;

  /// Every notification from this app is switched off in the system settings.
  ///
  /// In en, this message translates to:
  /// **'This phone’s settings have Lamplight’s notifications switched off.'**
  String get reminderProblemNotificationsOff;

  /// This one notification channel is silenced on its own, which from inside the app looks identical to everything being fine. ISSUE 10: the sentence names the settings screen and must never say the word channel, which is Android's word for Android's own bookkeeping.
  ///
  /// In en, this message translates to:
  /// **'Reminders from Lamplight are switched off in this phone’s notification settings.'**
  String get reminderProblemRemindersOff;

  /// Vendor battery management is holding this app's background alarms. The usual cause, and the one the app cannot fix from inside - so it says what is happening to the person's phone and opens the list, rather than explaining its own limits at somebody.
  ///
  /// In en, this message translates to:
  /// **'This phone is saving battery by holding Lamplight back. That is the usual reason a reminder is late or never arrives.'**
  String get reminderProblemBatterySaving;

  /// No description provided for @reminderMayNotArrive.
  ///
  /// In en, this message translates to:
  /// **'The reminder may not arrive'**
  String get reminderMayNotArrive;

  /// No description provided for @backupAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Back up automatically'**
  String get backupAutomatic;

  /// No description provided for @backupAutomaticDidNotFinish.
  ///
  /// In en, this message translates to:
  /// **'The automatic backup did not finish.'**
  String get backupAutomaticDidNotFinish;

  /// No description provided for @backupNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing to back up yet.'**
  String get backupNothingYet;

  /// No description provided for @backupInProgress.
  ///
  /// In en, this message translates to:
  /// **'Backing up…'**
  String get backupInProgress;

  /// No description provided for @backupStartsAtUnlock.
  ///
  /// In en, this message translates to:
  /// **'Starts at your next unlock.'**
  String get backupStartsAtUnlock;

  /// No description provided for @backupDoneAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Backed up automatically.'**
  String get backupDoneAutomatically;

  /// No description provided for @backupLastOneFailed.
  ///
  /// In en, this message translates to:
  /// **'The last automatic backup did not finish. It will try again next time you open Lamplight.'**
  String get backupLastOneFailed;

  /// No description provided for @importNthOf.
  ///
  /// In en, this message translates to:
  /// **'{index} of {total}'**
  String importNthOf(Object index, Object total);

  /// No description provided for @importWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 waiting} other{{count} waiting}}'**
  String importWaiting(num count);

  /// No description provided for @aboutCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get aboutCopied;

  /// No description provided for @failureGeneric.
  ///
  /// In en, this message translates to:
  /// **'That did not work.'**
  String get failureGeneric;

  /// No description provided for @failureNothingLost.
  ///
  /// In en, this message translates to:
  /// **'Nothing was lost — try again.'**
  String get failureNothingLost;

  /// No description provided for @calendarNothingOnDay.
  ///
  /// In en, this message translates to:
  /// **'nothing'**
  String get calendarNothingOnDay;

  /// No description provided for @backupChangeFolder.
  ///
  /// In en, this message translates to:
  /// **'Change folder'**
  String get backupChangeFolder;

  /// Where automatic backups are written. {place} is a folder path such as Documents/Lamplight and is never translated.
  ///
  /// In en, this message translates to:
  /// **'Saved to {place}'**
  String backupSavedTo(String place);

  /// Returns automatic backups to Documents/Lamplight after the user had picked a folder of their own.
  ///
  /// In en, this message translates to:
  /// **'Use the usual folder'**
  String get backupUseDefaultFolder;

  /// No description provided for @backupChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder to keep copies in'**
  String get backupChooseFolder;

  /// Shown when the folder picker comes back with nothing. Android 11+ refuses to hand any app the root of internal storage, the root of an SD card, or the Download directory, and says so inside its own picker with a message we did not write - so from in here it looks like nothing happened. This is a fact about the phone, not an error and not a scolding: it names the place that does work. Note that making a new folder inside Downloads does not help, because the picker's button offers the directory you are standing in rather than the one you just made.
  ///
  /// In en, this message translates to:
  /// **'Android will not let any app be given Downloads, or the whole of internal storage. Documents, or a folder inside it, works.'**
  String get folderAndroidRestriction;

  /// No description provided for @folderNotWritable.
  ///
  /// In en, this message translates to:
  /// **'Nothing can be saved into that folder. Try another one.'**
  String get folderNotWritable;

  /// No description provided for @folderRefused.
  ///
  /// In en, this message translates to:
  /// **'That folder could not be used.'**
  String get folderRefused;

  /// No description provided for @folderTryAnother.
  ///
  /// In en, this message translates to:
  /// **'Try choosing a different one.'**
  String get folderTryAnother;

  /// No description provided for @aboutHowKept.
  ///
  /// In en, this message translates to:
  /// **'How your notes are kept'**
  String get aboutHowKept;

  /// No description provided for @aboutFonts.
  ///
  /// In en, this message translates to:
  /// **'Fonts and licences'**
  String get aboutFonts;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @aboutNoBrowser.
  ///
  /// In en, this message translates to:
  /// **'No app on this phone can open links.'**
  String get aboutNoBrowser;

  /// No description provided for @aboutMadeBy.
  ///
  /// In en, this message translates to:
  /// **'Made by'**
  String get aboutMadeBy;

  /// Read aloud for the maker's name. Says where the link goes before it is followed, which every link in this app does.
  ///
  /// In en, this message translates to:
  /// **'Made by ProbablyPiyush. Opens LinkedIn in your browser.'**
  String get aboutMadeBySemantic;

  /// No description provided for @aboutCoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get aboutCoffee;

  /// No description provided for @aboutCoffeeSemantic.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee. Opens a page in your browser.'**
  String get aboutCoffeeSemantic;

  /// No description provided for @aboutCopyDetails.
  ///
  /// In en, this message translates to:
  /// **'Copy the details'**
  String get aboutCopyDetails;

  /// No description provided for @settingsNameSemantic.
  ///
  /// In en, this message translates to:
  /// **'{name}. Tap to change.'**
  String settingsNameSemantic(Object name);

  /// No description provided for @settingsAddName.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get settingsAddName;

  /// No description provided for @settingsNameOnlyHere.
  ///
  /// In en, this message translates to:
  /// **'Only on this phone'**
  String get settingsNameOnlyHere;

  /// No description provided for @settingsNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional. Only ever on this phone.'**
  String get settingsNameOptional;

  /// No description provided for @reminderTurnedOffByAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android has notifications switched off for Lamplight. You can turn them on in the phone’s settings, under Apps.'**
  String get reminderTurnedOffByAndroid;

  /// No description provided for @reminderOnceADay.
  ///
  /// In en, this message translates to:
  /// **'Once a day'**
  String get reminderOnceADay;

  /// No description provided for @reminderTodayAt.
  ///
  /// In en, this message translates to:
  /// **'today at {time}'**
  String reminderTodayAt(Object time);

  /// No description provided for @reminderYesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'yesterday at {time}'**
  String reminderYesterdayAt(Object time);

  /// No description provided for @reminderOnDateAt.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String reminderOnDateAt(Object date, Object time);

  /// No description provided for @reminderNoneYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing has arrived yet'**
  String get reminderNoneYet;

  /// No description provided for @reminderLastArrived.
  ///
  /// In en, this message translates to:
  /// **'Last one arrived {when}'**
  String reminderLastArrived(Object when);

  /// No description provided for @reminderNextDue.
  ///
  /// In en, this message translates to:
  /// **'The next is due {when}'**
  String reminderNextDue(Object when);

  /// No description provided for @aboutHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get aboutHide;

  /// No description provided for @aboutCheckReal.
  ///
  /// In en, this message translates to:
  /// **'Check this is the real Lamplight'**
  String get aboutCheckReal;

  /// No description provided for @entryRevisionsNote.
  ///
  /// In en, this message translates to:
  /// **'What this said before you changed it'**
  String get entryRevisionsNote;

  /// Subtitle under 'Add to a folder'. The folder model in one line: a folder is a second place to find something, never a move.
  ///
  /// In en, this message translates to:
  /// **'It stays on this day as well'**
  String get entryStaysOnDay;

  /// {kind} is the sort of thing — a photo, a video, a voice note, a document — already in the reader's language.
  ///
  /// In en, this message translates to:
  /// **'Delete the {kind}'**
  String entryDeleteKind(String kind);

  /// Shown when something shared from another app could not be taken in. Offers the way that does work rather than only reporting the failure.
  ///
  /// In en, this message translates to:
  /// **'That could not be added. Try saving it and using the picture button instead.'**
  String get shareCouldNotAdd;

  /// No description provided for @openNothingCanOpen.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this phone can open that kind of file.'**
  String get openNothingCanOpen;

  /// No description provided for @viewerMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get viewerMore;

  /// No description provided for @docLeavesLamplight.
  ///
  /// In en, this message translates to:
  /// **'This leaves Lamplight'**
  String get docLeavesLamplight;

  /// No description provided for @docKeepItHere.
  ///
  /// In en, this message translates to:
  /// **'Keep it here'**
  String get docKeepItHere;

  /// No description provided for @docOpenWith.
  ///
  /// In en, this message translates to:
  /// **'Open with…'**
  String get docOpenWith;

  /// Explains why a file cannot be shown inside Lamplight. {kind} is the file's extension. The first sentence is the promise being kept — nothing is written to the phone unencrypted — and the second is the offer that follows from it.
  ///
  /// In en, this message translates to:
  /// **'Lamplight can show PDFs, pictures and text without ever putting them on your phone unencrypted. A {kind} file needs another app — Lamplight can hand it to one for as long as you are reading it, and take it back afterwards.'**
  String docCannotShow(String kind);

  /// Under 'Open with…'. The reassurance: the file is lent to another app for as long as it is being read and taken back afterwards, not copied out.
  ///
  /// In en, this message translates to:
  /// **'Another app, without keeping a copy'**
  String get menuOpenWithNote;

  /// No description provided for @menuSaveKind.
  ///
  /// In en, this message translates to:
  /// **'Save {kind}'**
  String menuSaveKind(String kind);

  /// No description provided for @menuTrashNote.
  ///
  /// In en, this message translates to:
  /// **'Kept for 30 days, then gone'**
  String get menuTrashNote;

  /// No description provided for @videoBackTen.
  ///
  /// In en, this message translates to:
  /// **'Back ten seconds'**
  String get videoBackTen;

  /// No description provided for @videoForwardTen.
  ///
  /// In en, this message translates to:
  /// **'Forward ten seconds'**
  String get videoForwardTen;

  /// No description provided for @photoPlayVideo.
  ///
  /// In en, this message translates to:
  /// **'Play this video'**
  String get photoPlayVideo;

  /// Placeholder for the twelve recovery words on the lock screen. Says the shape expected — words with spaces — not an instruction.
  ///
  /// In en, this message translates to:
  /// **'Your twelve words, spaces between'**
  String get lockPhraseHint;

  /// No description provided for @lockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockUnlock;

  /// The whole of what the error screen says out loud. Two facts and no apology: something did not open, and nothing was lost. It must not name the machinery.
  ///
  /// In en, this message translates to:
  /// **'That screen did not open. Nothing was lost.'**
  String get errorScreenDidNotOpen;

  /// No description provided for @errorGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get errorGoBack;

  /// {what} is 'pause' or 'resume'. The second sentence is the one that matters — the recording did not stop, so nothing is being lost while this is on screen.
  ///
  /// In en, this message translates to:
  /// **'This phone will not {what} a recording. It is still recording.'**
  String recordingCannot(String what);

  /// No description provided for @recordingClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get recordingClose;

  /// Read aloud while recording, so somebody who cannot see the timer knows it is still running.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Recording, {count} seconds}}'**
  String recordingElapsed(int count);

  /// No description provided for @recordingStopKeep.
  ///
  /// In en, this message translates to:
  /// **'Stop and keep this recording'**
  String get recordingStopKeep;

  /// No description provided for @recordingDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get recordingDiscard;

  /// No description provided for @recordingCouldNotStart.
  ///
  /// In en, this message translates to:
  /// **'Recording could not start.'**
  String get recordingCouldNotStart;

  /// No description provided for @recordingCheckMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Check that Lamplight is allowed to use the microphone.'**
  String get recordingCheckMicrophone;

  /// No description provided for @recordingStartAgain.
  ///
  /// In en, this message translates to:
  /// **'start again'**
  String get recordingStartAgain;

  /// No description provided for @recordingCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'That recording could not be saved.'**
  String get recordingCouldNotSave;

  /// No description provided for @recordingStillHere.
  ///
  /// In en, this message translates to:
  /// **'It is still here — try stopping it again.'**
  String get recordingStillHere;

  /// No description provided for @recordingCarryOnSemantic.
  ///
  /// In en, this message translates to:
  /// **'Carry on recording'**
  String get recordingCarryOnSemantic;

  /// No description provided for @recordingPauseSemantic.
  ///
  /// In en, this message translates to:
  /// **'Pause this recording'**
  String get recordingPauseSemantic;

  /// No description provided for @recordingCarryOn.
  ///
  /// In en, this message translates to:
  /// **'Carry on'**
  String get recordingCarryOn;

  /// No description provided for @recordingPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get recordingPause;

  /// The button that finishes the size question and brings the file in.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get sizeAdd;

  /// No description provided for @transcribeTitle.
  ///
  /// In en, this message translates to:
  /// **'Write down what is said'**
  String get transcribeTitle;

  /// Subtitle when transcription is on. Two facts: what it gains, and the limit of where the sound goes. The second half is a claim about the software and must stay exactly that narrow.
  ///
  /// In en, this message translates to:
  /// **'Voice notes become searchable. Nothing is sent anywhere.'**
  String get transcribeOn;

  /// No description provided for @transcribeOff.
  ///
  /// In en, this message translates to:
  /// **'Off. Voice notes can only be found by their day.'**
  String get transcribeOff;

  /// No description provided for @transcribeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Spoken language'**
  String get transcribeLanguage;

  /// No description provided for @transcribeLanguageNote.
  ///
  /// In en, this message translates to:
  /// **'The language you speak in your recordings. One at a time — a sentence that switches between two comes back as whichever half matches this.'**
  String get transcribeLanguageNote;

  /// No description provided for @transcribeNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded on this phone yet — tap to get it.'**
  String get transcribeNotDownloaded;

  /// No description provided for @transcribeGetBetter.
  ///
  /// In en, this message translates to:
  /// **'Get the better model for {name}'**
  String transcribeGetBetter(String name);

  /// No description provided for @transcribeGetBetterNote.
  ///
  /// In en, this message translates to:
  /// **'Transcripts are noticeably more accurate with it. The download is from your phone, not from Lamplight, and it happens once.'**
  String get transcribeGetBetterNote;

  /// No description provided for @transcribeNoLanguages.
  ///
  /// In en, this message translates to:
  /// **'This phone has not offered any languages yet.'**
  String get transcribeNoLanguages;

  /// No description provided for @transcribeNeedsDownloading.
  ///
  /// In en, this message translates to:
  /// **'Needs downloading'**
  String get transcribeNeedsDownloading;

  /// Shown once, the first time somebody files an entry. {day} is the date it is on and {folder} is where it was added. The whole folder model in one line: it did not move.
  ///
  /// In en, this message translates to:
  /// **'Still on {day}. Also in {folder}.'**
  String folderStill(String day, String folder);

  /// No description provided for @folderRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename folder'**
  String get folderRenameTitle;

  /// No description provided for @folderNameHint.
  ///
  /// In en, this message translates to:
  /// **'A person, a place, a phase'**
  String get folderNameHint;

  /// No description provided for @voicePlay.
  ///
  /// In en, this message translates to:
  /// **'Play this voice note'**
  String get voicePlay;

  /// No description provided for @voiceForwardThirty.
  ///
  /// In en, this message translates to:
  /// **'Forward thirty seconds'**
  String get voiceForwardThirty;

  /// No description provided for @voiceSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed, currently {speed} times'**
  String voiceSpeed(String speed);

  /// Appended to a voice note whose duration has not been read yet. Says why the number is missing rather than showing a wrong one.
  ///
  /// In en, this message translates to:
  /// **'voice note, length not known until it plays'**
  String get voiceLengthUnknown;

  /// No description provided for @voicePosition.
  ///
  /// In en, this message translates to:
  /// **'Position in the recording'**
  String get voicePosition;

  /// No description provided for @voiceOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening the recording'**
  String get voiceOpening;

  /// The recogniser returned nothing. It does NOT say the recording was silent — the app cannot tell a quiet room from an engine that failed, and asserting the first would be claiming to know something it does not about somebody's recording of their own life.
  ///
  /// In en, this message translates to:
  /// **'No words came back — try again'**
  String get voiceNoWords;

  /// No description provided for @voiceWriteThis.
  ///
  /// In en, this message translates to:
  /// **'Write this down'**
  String get voiceWriteThis;

  /// No description provided for @voiceCannotWrite.
  ///
  /// In en, this message translates to:
  /// **'This phone cannot write voice notes down.'**
  String get voiceCannotWrite;

  /// No description provided for @voiceLanguageMissing.
  ///
  /// In en, this message translates to:
  /// **'This phone has not downloaded that language yet.'**
  String get voiceLanguageMissing;

  /// No description provided for @voiceWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing this down…'**
  String get voiceWriting;

  /// No description provided for @voiceWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting to be written down.'**
  String get voiceWaiting;

  /// No description provided for @voiceWritten.
  ///
  /// In en, this message translates to:
  /// **'Written down on this phone.'**
  String get voiceWritten;

  /// No description provided for @errorPartNotShown.
  ///
  /// In en, this message translates to:
  /// **'This part could not be shown.'**
  String get errorPartNotShown;

  /// No description provided for @errorScreenShort.
  ///
  /// In en, this message translates to:
  /// **'That screen did not open.'**
  String get errorScreenShort;

  /// The sentence the error screen exists to say. Everything else on it is detail; this is the reassurance, and it is true — a failed screen never touches the vault.
  ///
  /// In en, this message translates to:
  /// **'Nothing was lost. Everything you have written is still in the vault, exactly as it was.'**
  String get errorNothingLost;

  /// No description provided for @errorHideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide the technical details'**
  String get errorHideDetails;

  /// No description provided for @errorShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Show the technical details'**
  String get errorShowDetails;

  /// Above the copyable failure report. The last clause is a promise about what the report contains, so it must not be widened: the report carries the exception type and the stack, and deliberately not the message, which is where user content leaks.
  ///
  /// In en, this message translates to:
  /// **'This is everything that would be copied. It says what broke and where in the code — it does not contain anything you have written.'**
  String get errorDetailsNote;

  /// No description provided for @passcodeChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'The passcode could not be changed.'**
  String get passcodeChangeFailed;

  /// No description provided for @passcodeOldStillWorks.
  ///
  /// In en, this message translates to:
  /// **'Your old passcode still works.'**
  String get passcodeOldStillWorks;

  /// No description provided for @passcodeChanged.
  ///
  /// In en, this message translates to:
  /// **'Passcode changed'**
  String get passcodeChanged;

  /// After a passcode change. The twelve recovery words are derived separately and genuinely do not change — this is the reassurance somebody needs before they go looking for a new phrase that does not exist.
  ///
  /// In en, this message translates to:
  /// **'Your twelve words have not changed, and you do not need new ones. They open your vault and your backup files exactly as they did before.'**
  String get passcodeWordsUnchanged;

  /// The one consequence of changing a passcode that somebody could be caught out by: a backup made before the change still needs the old one.
  ///
  /// In en, this message translates to:
  /// **'Backups you already have still open with your old passcode. A new one, made now, will use the new passcode.'**
  String get passcodeOldBackups;

  /// No description provided for @passcodeMakeBackup.
  ///
  /// In en, this message translates to:
  /// **'Make a backup now'**
  String get passcodeMakeBackup;

  /// No description provided for @passcodeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current passcode'**
  String get passcodeCurrent;

  /// No description provided for @passcodeNewAgain.
  ///
  /// In en, this message translates to:
  /// **'New passcode again'**
  String get passcodeNewAgain;

  /// No description provided for @passcodeOldBackupsNote.
  ///
  /// In en, this message translates to:
  /// **'Backup files you have already made will still open with your old passcode.'**
  String get passcodeOldBackupsNote;

  /// No description provided for @passcodeWordsNote.
  ///
  /// In en, this message translates to:
  /// **'Your twelve recovery words do not change and keep working.'**
  String get passcodeWordsNote;

  /// No description provided for @licencesFonts.
  ///
  /// In en, this message translates to:
  /// **'Every typeface here is under the SIL Open Font License. Nothing is downloaded — they are in the app.'**
  String get licencesFonts;

  /// No description provided for @licencesSource.
  ///
  /// In en, this message translates to:
  /// **'Lamplight itself is GPL-3.0 with an app-store exception. The source is the licence: anybody can read it and check that the app does what this screen says.'**
  String get licencesSource;

  /// No description provided for @licencesUnreadable.
  ///
  /// In en, this message translates to:
  /// **'That licence file could not be read.'**
  String get licencesUnreadable;

  /// The specimen paragraph in the font picker. Ordinary diary writing rather than a pangram — somebody is choosing how their own words will look, so it should read like something they might have written.
  ///
  /// In en, this message translates to:
  /// **'Rain all afternoon. Made tea, read half a chapter, forgot what I meant to say and wrote this instead.'**
  String get appearanceSample;

  /// Under the specimen. The chosen face applies to writing, not to the app's own buttons and labels, which stay in the platform's face for legibility.
  ///
  /// In en, this message translates to:
  /// **'Buttons and labels stay like this'**
  String get appearanceChromeNote;

  /// Under the text-size slider. Says that this multiplies the phone's own accessibility setting rather than replacing it.
  ///
  /// In en, this message translates to:
  /// **'This works on top of your phone’s own text size, so if you have already turned that up, this goes further still.'**
  String get appearanceSizeNote;

  /// No description provided for @voicePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get voicePause;

  /// No description provided for @importIntro.
  ///
  /// In en, this message translates to:
  /// **'If you have written a journal somewhere else, Lamplight can read it in — as long as it is text files with the date in the name.'**
  String get importIntro;

  /// No description provided for @importHowDates.
  ///
  /// In en, this message translates to:
  /// **'It reads plain text files and looks for a date in the name — 2026-08-24, or 24 August 2026 — anywhere in the file name or the folders above it.'**
  String get importHowDates;

  /// Why a whole class of filename is skipped rather than guessed. The refusal is the feature — guessing wrong would file a year of somebody's life on the wrong days and say nothing about it.
  ///
  /// In en, this message translates to:
  /// **'Dates like 03-04-2026 are skipped on purpose. That is the third of April in some countries and the fourth of March in others, and guessing wrong would file a year of your life on the wrong days without telling you.'**
  String get importAmbiguousDates;

  /// No description provided for @importFormats.
  ///
  /// In en, this message translates to:
  /// **'Lamplight reads plain text: .txt, .md, .org, .log and others, including files with no extension at all. If your journal is in another format, export it as text first.'**
  String get importFormats;

  /// Two reassurances that matter before somebody commits: nothing already in Lamplight is touched, and running the import twice does not duplicate anything.
  ///
  /// In en, this message translates to:
  /// **'They will sit at the start of each day, because a file name gives the date but not the time. Nothing already in Lamplight is changed or removed, and running this twice will not make copies.'**
  String get importAtStartOfDay;

  /// No description provided for @importFileDateNote.
  ///
  /// In en, this message translates to:
  /// **'Puts them on the day the file was last changed. If the folder has been copied between devices, that may be the day it was copied rather than the day you wrote it.'**
  String get importFileDateNote;

  /// No description provided for @importSkippedNote.
  ///
  /// In en, this message translates to:
  /// **'These will be skipped. They stay exactly where they are — nothing is moved or deleted from your folder.'**
  String get importSkippedNote;

  /// No description provided for @restoreChooseNote.
  ///
  /// In en, this message translates to:
  /// **'Choose your backup file. It will be called something like Lamplight-2026-08-18.vault.'**
  String get restoreChooseNote;

  /// No description provided for @restorePasscodeNote.
  ///
  /// In en, this message translates to:
  /// **'Enter the passcode for this file — the one that was set when the backup was made.'**
  String get restorePasscodeNote;

  /// No description provided for @restoreWordsNote.
  ///
  /// In en, this message translates to:
  /// **'Type the twelve words, in order, separated by spaces.'**
  String get restoreWordsNote;

  /// No description provided for @restoreDoNotClose.
  ///
  /// In en, this message translates to:
  /// **'Do not close Lamplight until this finishes.'**
  String get restoreDoNotClose;

  /// No description provided for @exportIntro.
  ///
  /// In en, this message translates to:
  /// **'This writes everything in Lamplight into a folder you choose, as ordinary files — one text file for each day, and every photo, video, voice note and document under its own name.'**
  String get exportIntro;

  /// No description provided for @exportNoLamplightNeeded.
  ///
  /// In en, this message translates to:
  /// **'Nothing in that folder needs Lamplight to open it. If this app ever stops working, or you stop using it, your notes still open in anything that reads text.'**
  String get exportNoLamplightNeeded;

  /// The whole explanation of backup versus readable copy, in three paragraphs separated by blank lines. Keep the paragraph breaks — it is read by somebody deciding, not skimming.
  ///
  /// In en, this message translates to:
  /// **'A readable copy is for reading, moving to another app, or keeping something after you stop using Lamplight. It is not protected.\n\nA backup file is for getting Lamplight back exactly as it was — a new phone, or a phone that broke. It is locked with your passcode, so it is safe to keep anywhere, including a cloud drive.\n\nMost people want the backup. Take a readable copy as well if you want to be certain you are never stuck.'**
  String get exportWhichOneBody;

  /// The warning that makes the readable copy honest. It is plain files with no passcode on them; anybody who opens that folder can read everything. It must not be softened, and it points at the safe alternative rather than just alarming.
  ///
  /// In en, this message translates to:
  /// **'It has no passcode on it. Anyone who opens that folder can read everything in it. Put it somewhere you are happy with that — and if you only want something safe to keep, use Back up instead.'**
  String get exportNotLockedBody;

  /// No description provided for @backupConfirmNote.
  ///
  /// In en, this message translates to:
  /// **'Confirm your passcode. This file can unlock everything, so making one should be something you meant to do.'**
  String get backupConfirmNote;

  /// Why a backup is safe to put in a cloud drive: the file is unreadable without the passcode, and we never have it. Both halves are load-bearing.
  ///
  /// In en, this message translates to:
  /// **'Your backup is locked with the passcode you have now. Keep it somewhere you trust — a cloud drive is fine, because the file is unreadable without that passcode. We never see it.'**
  String get backupKeepSafeNote;

  /// Before restoring. The second sentence is the safety net and must survive: the current notes are kept aside until the restored ones are proven to open.
  ///
  /// In en, this message translates to:
  /// **'Opening a backup replaces everything currently in Lamplight. Your current notes are kept aside until the restored ones are proven to open.'**
  String get backupRestoreWarning;

  /// What a folder is for, in the app's own terms — a thread through days rather than a container.
  ///
  /// In en, this message translates to:
  /// **'A folder is a thread that runs through your days — one person, one place, one stretch of time.'**
  String get folderWhatItIs;

  /// The folder model, stated once where somebody meets it. An entry is never moved; it stays on its day and also appears here.
  ///
  /// In en, this message translates to:
  /// **'Nothing moves into a folder. An entry stays on its own day and shows up here as well.'**
  String get folderNothingMoves;

  /// No description provided for @folderDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'The folder goes. Everything in it stays exactly where it is, on its own day.'**
  String get folderDeleteNote;

  /// No description provided for @folderNoneInHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing in here yet. Long-press anything on a day and choose “Add to a folder”.'**
  String get folderNoneInHere;

  /// No description provided for @passcodeRuleLength.
  ///
  /// In en, this message translates to:
  /// **'Eight characters or more.'**
  String get passcodeRuleLength;

  /// Advice under the passcode field, not a rule. A few ordinary words beating a short cryptic one is true and is what people should hear.
  ///
  /// In en, this message translates to:
  /// **'A few ordinary words you will remember beats a short one with symbols in it.'**
  String get passcodeRuleWords;

  /// No description provided for @passcodeNoMatch.
  ///
  /// In en, this message translates to:
  /// **'The two do not match yet.'**
  String get passcodeNoMatch;

  /// Before saving a copy of a document out of Lamplight. Says exactly what changes and what does not: the copy is readable by anything, what stays inside is still encrypted.
  ///
  /// In en, this message translates to:
  /// **'The copy is written out in the clear, so any app that can read your files can read it. What is kept inside Lamplight stays encrypted either way.'**
  String get docCopyInClear;

  /// The page counter in the document reader. {page} and {total} are both numbers.
  ///
  /// In en, this message translates to:
  /// **'{page} of {total}'**
  String docPageOf(String page, String total);

  /// No description provided for @transcribeTookTooLong.
  ///
  /// In en, this message translates to:
  /// **'That recording took too long to write down, so Lamplight stopped waiting. It will try again later.'**
  String get transcribeTookTooLong;

  /// No description provided for @transcribeCouldNotWriteDown.
  ///
  /// In en, this message translates to:
  /// **'That recording could not be written down.'**
  String get transcribeCouldNotWriteDown;

  /// No description provided for @transcribeRecordingIsSafe.
  ///
  /// In en, this message translates to:
  /// **'The recording itself is safe. Lamplight will try again.'**
  String get transcribeRecordingIsSafe;

  /// No description provided for @voicePositionSpoken.
  ///
  /// In en, this message translates to:
  /// **'{at} of {total}'**
  String voicePositionSpoken(Object at, Object total);

  /// No description provided for @entryEditedAt.
  ///
  /// In en, this message translates to:
  /// **'{time} · edited'**
  String entryEditedAt(Object time);

  /// No description provided for @docCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'That document could not be opened.'**
  String get docCouldNotOpen;

  /// No description provided for @albumThisOne.
  ///
  /// In en, this message translates to:
  /// **'This {thing}'**
  String albumThisOne(Object thing);

  /// No description provided for @albumThisOneOf.
  ///
  /// In en, this message translates to:
  /// **'This {thing} — {index} of {total}'**
  String albumThisOneOf(Object index, Object thing, Object total);

  /// No description provided for @albumCaptionThese.
  ///
  /// In en, this message translates to:
  /// **'Add a caption to these'**
  String get albumCaptionThese;

  /// No description provided for @albumCaptionThis.
  ///
  /// In en, this message translates to:
  /// **'Add a caption'**
  String get albumCaptionThis;

  /// No description provided for @albumCaptionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit the caption'**
  String get albumCaptionEdit;

  /// No description provided for @albumOthersStay.
  ///
  /// In en, this message translates to:
  /// **'The other {count} stay. It goes to the trash for 30 days.'**
  String albumOthersStay(Object count);

  /// No description provided for @albumGoesToTrash.
  ///
  /// In en, this message translates to:
  /// **'It goes to the trash for 30 days.'**
  String get albumGoesToTrash;

  /// No description provided for @photoCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'This picture could not be opened.'**
  String get photoCouldNotOpen;

  /// No description provided for @photoMayBeDamaged.
  ///
  /// In en, this message translates to:
  /// **'It may be damaged.'**
  String get photoMayBeDamaged;

  /// No description provided for @docTooBig.
  ///
  /// In en, this message translates to:
  /// **'This one is too big to open inside Lamplight. You can save a copy and open it elsewhere.'**
  String get docTooBig;

  /// No description provided for @docPages.
  ///
  /// In en, this message translates to:
  /// **'{count} pages'**
  String docPages(Object count);

  /// No description provided for @docFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'This file is empty.'**
  String get docFileEmpty;

  /// No description provided for @videoTooBig.
  ///
  /// In en, this message translates to:
  /// **'This video is too big for Lamplight to play here — {size}. It will not be written out unprotected to get around that. Save a copy to watch it elsewhere.'**
  String videoTooBig(Object size);

  /// No description provided for @videoNotAvailableHere.
  ///
  /// In en, this message translates to:
  /// **'This part of the app is not available on this phone.'**
  String get videoNotAvailableHere;

  /// No description provided for @videoCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'This video could not be opened.'**
  String get videoCouldNotOpen;

  /// No description provided for @docGoToPage.
  ///
  /// In en, this message translates to:
  /// **'Go to a page'**
  String get docGoToPage;

  /// No description provided for @docGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get docGo;

  /// No description provided for @docPageCouldNotBeDrawn.
  ///
  /// In en, this message translates to:
  /// **'This page could not be drawn.'**
  String get docPageCouldNotBeDrawn;

  /// No description provided for @passcodeRuleStronger.
  ///
  /// In en, this message translates to:
  /// **'Another word or two would make it much harder to guess.'**
  String get passcodeRuleStronger;

  /// No description provided for @backupAutoFooter.
  ///
  /// In en, this message translates to:
  /// **'Automatic backups run when you open Lamplight, if anything changed since the last one. They are locked with your passcode, exactly like one you make yourself.'**
  String get backupAutoFooter;

  /// The app's central claim, in two paragraphs. Every clause is a fact about the software rather than a reassurance: no account, no server, nothing leaves, and the key is derived from the passcode so no copy of it exists anywhere including with us. It must not become 'your data is safe'.
  ///
  /// In en, this message translates to:
  /// **'No account. No server. Nothing leaves this phone.\n\nYour notes are locked with your passcode, and the key is made from it — so there is no copy of it anywhere, including with us.'**
  String get aboutHowKeptBody;

  /// There is no paid tier, no unlock, no trial. Said plainly because people expect the opposite.
  ///
  /// In en, this message translates to:
  /// **'Lamplight is free and always will be. There is nothing to unlock.'**
  String get aboutFree;

  /// No description provided for @aboutContact.
  ///
  /// In en, this message translates to:
  /// **'Something not right? Tell me.'**
  String get aboutContact;

  /// No description provided for @aboutContactSemantic.
  ///
  /// In en, this message translates to:
  /// **'Send feedback by email'**
  String get aboutContactSemantic;

  /// No description provided for @aboutNoMail.
  ///
  /// In en, this message translates to:
  /// **'No email app on this phone. The address is {address}.'**
  String aboutNoMail(String address);

  /// No description provided for @backupOnItsOwn.
  ///
  /// In en, this message translates to:
  /// **'On its own'**
  String get backupOnItsOwn;

  /// No description provided for @actionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get actionDismiss;

  /// No description provided for @importRange.
  ///
  /// In en, this message translates to:
  /// **'From {from} to {to}.'**
  String importRange(String from, String to);

  /// No description provided for @sizeOneCopy.
  ///
  /// In en, this message translates to:
  /// **'Lamplight keeps one copy. Whatever you choose here is what you will have.'**
  String get sizeOneCopy;

  /// No description provided for @sizeAddAlways.
  ///
  /// In en, this message translates to:
  /// **'Add, and do not ask again'**
  String get sizeAddAlways;

  /// No description provided for @trashNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here.'**
  String get trashNothingHere;

  /// No description provided for @appearanceAaQuiet.
  ///
  /// In en, this message translates to:
  /// **'Aa\nquiet'**
  String get appearanceAaQuiet;

  /// The countdown before the idle lock. It buys no extra time — the warning exists so that locking reads as the app being deliberate rather than falling over.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Locking in about one second.} other{Locking in about {count} seconds.}}'**
  String lockWarnSeconds(int count);

  /// No description provided for @lockWarnChange.
  ///
  /// In en, this message translates to:
  /// **'Change this in Locking and security.'**
  String get lockWarnChange;

  /// No description provided for @openingLabel.
  ///
  /// In en, this message translates to:
  /// **'Lamplight is opening'**
  String get openingLabel;

  /// The microphone permission was refused. Says where to change it without pretending the app can do it.
  ///
  /// In en, this message translates to:
  /// **'Lamplight cannot use the microphone. You can turn it on in the phone’s settings, under Apps.'**
  String get recordingNoMic;

  /// While a recording is paused. The second sentence is the point: nothing is being listened to right now.
  ///
  /// In en, this message translates to:
  /// **'Paused. Nothing is being heard.'**
  String get recordingPaused;

  /// No description provided for @videoOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening the video…'**
  String get videoOpening;

  /// No description provided for @albumRemoveThis.
  ///
  /// In en, this message translates to:
  /// **'Remove this {thing}'**
  String albumRemoveThis(String thing);

  /// Above the list of earlier versions of an entry. The second half sets the expectation — this sheet reads and does not restore, and the words can be selected and copied.
  ///
  /// In en, this message translates to:
  /// **'What this said before you changed it. Nothing here is a button — you can select the words and copy them.'**
  String get revisionsNote;

  /// Read aloud for the writing box. An invitation, like the visible placeholder.
  ///
  /// In en, this message translates to:
  /// **'Write an entry for this day'**
  String get composerSemantic;

  /// No description provided for @importStripAdding.
  ///
  /// In en, this message translates to:
  /// **'Adding {name}'**
  String importStripAdding(String name);

  /// The length rule under the passcode field. {count} is the minimum number of characters.
  ///
  /// In en, this message translates to:
  /// **'At least {count} characters'**
  String passcodeAtLeast(int count);

  /// Search filter chips. One word each — they sit in a row and must stay short.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get searchKindAll;

  /// No description provided for @searchKindWords.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get searchKindWords;

  /// No description provided for @searchKindVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get searchKindVoice;

  /// No description provided for @searchKindPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get searchKindPhotos;

  /// No description provided for @searchKindFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get searchKindFiles;

  /// No description provided for @passcodeAtLeastShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{At least 1 character} other{At least {count} characters}}'**
  String passcodeAtLeastShort(int count);

  /// How long an entry has left in the trash before it goes for good. {count} is whole days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day left} other{{count} days left}}'**
  String trashDaysLeft(int count);

  /// Shown instead of trashDaysLeft on the last day, when 'in 0 days' would be wrong.
  ///
  /// In en, this message translates to:
  /// **'Goes today'**
  String get trashGoneToday;

  /// When the chosen backup file was made. {date} is already formatted for the reader's language by LampDates.
  ///
  /// In en, this message translates to:
  /// **'Made on {date}'**
  String restoreMadeOn(String date);

  /// After a restore finishes. {entries} and {days} are counts. 'Welcome back' is the whole tone of the screen and should survive as a greeting rather than a status.
  ///
  /// In en, this message translates to:
  /// **'Restored {entries} across {days}. Welcome back.'**
  String restoreDone(String entries, String days);

  /// No description provided for @importFoundUndated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 with no date Lamplight can read} other{{count} with no date Lamplight can read}}'**
  String importFoundUndated(int count);

  /// Read aloud for one entry in the day. {time} is when it was written.
  ///
  /// In en, this message translates to:
  /// **'Entry at {time}. Tap to edit.'**
  String entrySemantic(String time);

  /// The same, for an entry that has been changed since.
  ///
  /// In en, this message translates to:
  /// **'Entry at {time}, edited. Tap to edit.'**
  String entrySemanticEdited(String time);

  /// Read aloud for an entry from a previous year. {when} is the date, {body} the first words of it.
  ///
  /// In en, this message translates to:
  /// **'{when}. {body}. Tap to go to that day.'**
  String onThisDaySemantic(String when, String body);

  /// Read aloud for a group of attachments. {what} describes them — photographs, files — and {time} is when they were added.
  ///
  /// In en, this message translates to:
  /// **'{what} at {time}. Double tap to open them.'**
  String attachmentSemantic(String what, String time);

  /// Read aloud for the date at the top of the day. {date} is the full date; the second part marks today.
  ///
  /// In en, this message translates to:
  /// **'{date}, today'**
  String dayHeaderToday(String date);

  /// No description provided for @yearGridNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day'**
  String get yearGridNothing;

  /// No description provided for @calendarNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day'**
  String get calendarNothing;

  /// No description provided for @importStripCounted.
  ///
  /// In en, this message translates to:
  /// **'Adding {name}{counted}'**
  String importStripCounted(String name, String counted);

  /// Explains the signing fingerprint shown below it. The point is that it is checkable by the reader against a published value, not that they should trust it.
  ///
  /// In en, this message translates to:
  /// **'Every build carries a signature only its author can make. This is the one on the copy you are holding. Compare it with the fingerprint published alongside the source — if they match, this is the app that source builds.'**
  String get aboutFingerprintBody;

  /// No description provided for @searchKindVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get searchKindVideo;

  /// Read aloud after a filter chip that is switched on, as in "Photos, on". One word.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get semanticOn;

  /// No description provided for @andMore.
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String andMore(int count);

  /// How much is on a day, read aloud. The zero form is a word rather than "0 entries" — colour is never the only channel in the year grid, and this sentence is what carries the meaning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, zero{nothing} one{1 entry} other{{count} entries}}'**
  String entriesCount(int count);

  /// Read aloud before a passcode rule that is satisfied, as in "Done: at least 8 characters".
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get checkDone;

  /// No description provided for @checkNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get checkNotYet;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// Follows a fingerprint failure on the lock screen. An offer of the way in that still works, never a reprimand — see the tone note in l10n/README.md.
  ///
  /// In en, this message translates to:
  /// **'Use your passcode.'**
  String get lockUseYourPasscode;

  /// Example beside the 'Words' row on the empty search screen.
  ///
  /// In en, this message translates to:
  /// **'anything you have written'**
  String get searchWordsExample;

  /// Heading of the 'a file' example row on the empty search screen.
  ///
  /// In en, this message translates to:
  /// **'A file'**
  String get searchAFile;

  /// Example filenames. Deliberately not translated — they are literal filenames, and a translated example would not match anything on the phone.
  ///
  /// In en, this message translates to:
  /// **'scan.pdf · IMG_2831'**
  String get searchFileExample;

  /// Heading of the 'a folder' example row on the empty search screen.
  ///
  /// In en, this message translates to:
  /// **'A folder'**
  String get searchAFolder;

  /// Example beside the 'A folder' row on the empty search screen.
  ///
  /// In en, this message translates to:
  /// **'the name you gave it'**
  String get searchFolderExample;

  /// Why a result matched: the words were in the filename rather than in anything written. Sits beside 'said out loud'.
  ///
  /// In en, this message translates to:
  /// **'by file name'**
  String get searchByFileName;

  /// Stands in for a voice note in a search result that has no words of its own. Never 'no transcript' — the app cannot tell a quiet room from an engine that failed.
  ///
  /// In en, this message translates to:
  /// **'A recording'**
  String get searchARecording;

  /// Stands in for an entry of any other kind in a search result with no words of its own.
  ///
  /// In en, this message translates to:
  /// **'An entry'**
  String get searchAnEntry;

  /// Stands in for a mixed batch of one photo and video in 'How big should {what} be kept?'. Deliberately not the word 'media' — that is a name for a category and nobody has ever picked one.
  ///
  /// In en, this message translates to:
  /// **'this one'**
  String get sizeThisOne;

  /// Stands in for a mixed batch of photos and videos in 'How big should {what} be kept?'.
  ///
  /// In en, this message translates to:
  /// **'these'**
  String get sizeTheseOnes;

  /// Passcode is one character short of the minimum. Says what to do, never what is wrong.
  ///
  /// In en, this message translates to:
  /// **'One more character.'**
  String get passcodeOneMoreCharacter;

  /// Passcode is short by {count}. Actionable, not a complexity-policy refusal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 more character — {minimum} is the minimum.} other{{count} more characters — {minimum} is the minimum.}}'**
  String passcodeMoreCharacters(int count, int minimum);

  /// The passcode is in the common-passwords list. Names the actual risk rather than saying 'too common', which is vague.
  ///
  /// In en, this message translates to:
  /// **'That is one of the first things anyone would try. Pick something else.'**
  String get passcodeTooObvious;

  /// The passcode is one character over and over.
  ///
  /// In en, this message translates to:
  /// **'That is the same character repeated.'**
  String get passcodeSameCharacter;

  /// The passcode is a sequence like 12345678 or abcdefgh.
  ///
  /// In en, this message translates to:
  /// **'That is a straight run of characters.'**
  String get passcodeStraightRun;

  /// Screen-reader label while an attachment is still being decrypted.
  ///
  /// In en, this message translates to:
  /// **'Attachment at {time}, loading'**
  String attachmentLoading(String time);

  /// Screen-reader label for a video entry. {length} is either a duration or the 'length unknown' phrase.
  ///
  /// In en, this message translates to:
  /// **'Video at {time}, {length}. Double tap to watch.'**
  String videoSemantic(String time, String length);

  /// Screen-reader label for a voice note. {length} is either a duration or the 'length unknown' phrase.
  ///
  /// In en, this message translates to:
  /// **'Voice note at {time}, {length}. Double tap to play.'**
  String voiceSemantic(String time, String length);

  /// Screen-reader label for a document entry.
  ///
  /// In en, this message translates to:
  /// **'File at {time}, {name}, {size}. Double tap to open.'**
  String fileSemantic(String time, String name, String size);

  /// Stands in for a duration the app does not have. Says it does not know rather than showing 0:00, which would be a claim about the recording.
  ///
  /// In en, this message translates to:
  /// **'length unknown'**
  String get lengthUnknown;

  /// Part of the Security row summary when the idle lock is off. Lower case — it is a clause inside a longer sentence.
  ///
  /// In en, this message translates to:
  /// **'no auto-lock'**
  String get settingsLockNone;

  /// Part of the Security row summary when the idle lock is on. {duration} is already in the reader's language.
  ///
  /// In en, this message translates to:
  /// **'after {duration}'**
  String settingsLockAfter(String duration);

  /// The Security row's summary line. {lock} is either 'no auto-lock' or 'after 5 minutes'.
  ///
  /// In en, this message translates to:
  /// **'Passcode, fingerprint, {lock}'**
  String settingsSecuritySummary(String lock);

  /// Heading of the first claim in 'How your notes are kept'. A statement of fact about the software, not a reassurance.
  ///
  /// In en, this message translates to:
  /// **'It never goes anywhere'**
  String get keptNoNetworkTitle;

  /// The strongest claim the app makes. The 'cannot, not does not' distinction is the whole point and must survive translation — it is the difference between a promise and a verifiable fact. Keep the invitation to check.
  ///
  /// In en, this message translates to:
  /// **'Lamplight cannot use the internet. Not \"does not\" — cannot: Android refuses it the permission, and you can check that yourself in the phone’s app settings in about thirty seconds.'**
  String get keptNoNetworkBody;

  /// Heading of the second claim in 'How your notes are kept'.
  ///
  /// In en, this message translates to:
  /// **'Your passcode is the key'**
  String get keptPasscodeTitle;

  /// Why there is no stored key. 'to find, to lose, or to hand over' names three different adversaries in six words — keep all three.
  ///
  /// In en, this message translates to:
  /// **'The key that opens your notes is made from your passcode every time you unlock. It is not stored anywhere, so there is no copy of it to find, to lose, or to hand over.'**
  String get keptPasscodeBody;

  /// Heading of the third claim in 'How your notes are kept'.
  ///
  /// In en, this message translates to:
  /// **'If you forget it'**
  String get keptForgetTitle;

  /// Says the cost of the design honestly rather than hiding it. The 'same fact as the one above' link is the argument, not decoration.
  ///
  /// In en, this message translates to:
  /// **'Your twelve words are the only other way in. Nobody can reset a passcode here, and that is the same fact as the one above — an app that could let you back in could let somebody else in too.'**
  String get keptForgetBody;

  /// Heading of the fourth claim in 'How your notes are kept'.
  ///
  /// In en, this message translates to:
  /// **'Nothing readable is left lying about'**
  String get keptNothingReadableTitle;

  /// The 'not even briefly' clause is the specific promise — it is what rule 2 of CLAUDE.md is about — and must not be softened to a general one.
  ///
  /// In en, this message translates to:
  /// **'Photos, recordings and files are encrypted before they touch storage. Nothing is ever written out in the clear, not even briefly while you look at it.'**
  String get keptNothingReadableBody;

  /// Heading of the fifth claim in 'How your notes are kept'.
  ///
  /// In en, this message translates to:
  /// **'It locks itself'**
  String get keptLocksItselfTitle;

  /// Describes lock-on-background, FLAG_SECURE and the recents thumbnail. Note the app ships a switch for screenshots — this text describes the default.
  ///
  /// In en, this message translates to:
  /// **'The moment Lamplight goes into the background the keys are destroyed. Screenshots are blocked and the app does not appear in the recent apps preview.'**
  String get keptLocksItselfBody;

  /// Heading of the sixth and last item in 'How your notes are kept'. An instruction, not a claim — it is the one thing the app cannot do for the reader.
  ///
  /// In en, this message translates to:
  /// **'Back it up'**
  String get keptBackUpTitle;

  /// Names the cost of the whole design in one sentence — 'which is the point and is also the risk'. Do not soften it; that honesty is the reason the rest is believable.
  ///
  /// In en, this message translates to:
  /// **'Everything is on this phone and nowhere else, which is the point and is also the risk. A backup is one encrypted file that only your passcode opens. Keep one somewhere.'**
  String get keptBackUpBody;

  /// Time remaining on a long job, in seconds. Deliberately vague - the estimate is rounded to ten seconds, so 'about' is doing real work and must survive translation.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{About {count} seconds left}}'**
  String etaSeconds(int count);

  /// Time remaining on a long job, in minutes. Same vagueness as the seconds form; never render a precise figure here.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{About a minute left} other{About {count} minutes left}}'**
  String etaMinutes(int count);

  /// Shown once, after an entry is saved, when the person spent more than a minute writing it. An observation about effort already spent - never a target, a total or a streak. Keep it warm and factual; it must not sound like praise for hitting a number, and must not imply that a longer time would have been better.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{You wrote for a minute.} other{You wrote for {count} minutes.}}'**
  String youWroteForMinutes(int count);
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'ja',
    'ko',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return LAr();
    case 'de':
      return LDe();
    case 'en':
      return LEn();
    case 'es':
      return LEs();
    case 'fr':
      return LFr();
    case 'hi':
      return LHi();
    case 'ja':
      return LJa();
    case 'ko':
      return LKo();
    case 'pt':
      return LPt();
    case 'zh':
      return LZh();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
