// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class LDe extends L {
  LDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Lamplight';

  @override
  String get lockTypePasscode => 'Gib deinen Code ein.';

  @override
  String get lockWrongPasscode => 'Damit ging der Tresor nicht auf.';

  @override
  String get lockCheckAndRetry => 'Prüfe den Code und versuch es noch einmal.';

  @override
  String get lockForgot => 'Ich habe meinen Code vergessen';

  @override
  String get lockTypeTwelveWords => 'Gib deine zwölf Wörter ein.';

  @override
  String get lockUsePasscodeInstead => 'Lieber meinen Code benutzen';

  @override
  String get lockUseFingerprint => 'Deinen Fingerabdruck benutzen';

  @override
  String get lockFingerprintFailed =>
      'Mit dem Fingerabdruck hat es nicht geklappt.';

  @override
  String get lockFingerprintUnavailable => 'Fingerabdruck ist nicht verfügbar.';

  @override
  String get lockOpening => 'Wird geöffnet…';

  @override
  String get lockNothingDeleted =>
      'Es wurde nichts gelöscht, und es wird nichts gelöscht.';

  @override
  String lockTryAgainSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Versuch es in $count Sekunden noch einmal.',
      one: 'Versuch es in einer Sekunde noch einmal.',
    );
    return '$_temp0';
  }

  @override
  String lockTryAgainMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Versuch es in $count Minuten noch einmal.',
      one: 'Versuch es in einer Minute noch einmal.',
    );
    return '$_temp0';
  }

  @override
  String get dayToday => 'HEUTE';

  @override
  String get dayPrevious => 'Der Tag davor';

  @override
  String get dayNext => 'Der Tag danach';

  @override
  String get daySearch => 'Suchen';

  @override
  String get daySettings => 'Einstellungen';

  @override
  String get dayChooseDate => 'Ein anderes Datum wählen.';

  @override
  String get dayEmptyToday => 'Etwas, das du behalten möchtest?';

  @override
  String get dayEmptyPast => 'Nichts an diesem Tag.';

  @override
  String get dayWriteSomething => 'Etwas für heute schreiben';

  @override
  String get dayLineAsk => 'Was war dieser Tag?';

  @override
  String get dayLineHint => 'Was war dieser Tag?';

  @override
  String get dayLineSemantic => 'Sag in einer Zeile, was dieser Tag war';

  @override
  String dayLineChange(String note) {
    return 'Dieser Tag: $note. Ändern.';
  }

  @override
  String get dayEndOfDay => 'Das Ende des Tages';

  @override
  String get dayStartOfDay => 'Der Anfang des Tages';

  @override
  String get firstPageTitle =>
      'Hier ist nichts, weil du noch nichts hineingeschrieben hast.';

  @override
  String get firstPageShelves =>
      'Die Tage sind die Regale. Was du behältst, landet an dem Tag, an dem es passiert ist, und bleibt dort.';

  @override
  String get firstPageWayWrite => 'Tipp auf diese Seite, um zu schreiben.';

  @override
  String get firstPageWayVoice =>
      'Halte das Mikrofon gedrückt, um es stattdessen zu sagen.';

  @override
  String get firstPageWayAttach =>
      'Füge ein Foto, ein Video oder ein Dokument hinzu.';

  @override
  String get firstPagePromise => 'Nichts davon verlässt dieses Telefon.';

  @override
  String get firstPageSemantic => 'Schreib das Erste in dein Tagebuch';

  @override
  String get captureVoice => 'Eine Sprachnotiz aufnehmen';

  @override
  String get capturePhoto => 'Ein Foto machen oder auswählen';

  @override
  String get captureFile => 'Eine Datei anhängen';

  @override
  String get backupNeverMade =>
      'Hiervon gibt es keine Sicherung. Wird diese App entfernt, gehen deine Notizen mit ihr.';

  @override
  String get backupStale => 'Die letzte Sicherung ist eine Weile her.';

  @override
  String get backupOutOfDate =>
      'Deine Sicherung öffnet sich noch mit deinem alten Code.';

  @override
  String get backupAction => 'Sichern';

  @override
  String folderAlsoIn(String name) {
    return 'Auch in $name. Ordner öffnen.';
  }

  @override
  String get folderStaysHere =>
      'Es bleibt, wo es ist. Ein Ordner ist ein zweiter Ort, an dem du es findest.';

  @override
  String get folderAddTo => 'Zu einem Ordner hinzufügen';

  @override
  String get folderNew => 'Neuer Ordner';

  @override
  String get folderNoneYet =>
      'Noch keine Ordner. Einer pro Person oder pro Lebensabschnitt — was auch immer du immer wieder ansiehst.';

  @override
  String folderLesson(String day, String folder) {
    return 'Weiterhin am $day. Auch in $folder.';
  }

  @override
  String get actionDone => 'Fertig';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionEdit => 'Bearbeiten';

  @override
  String get actionUndo => 'Rückgängig';

  @override
  String get actionOpen => 'Öffnen';

  @override
  String get actionRemove => 'Entfernen';

  @override
  String get actionNotNow => 'Jetzt nicht';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsAppearance => 'Aussehen';

  @override
  String get settingsSecurity => 'Sperre und Sicherheit';

  @override
  String get settingsYourNotes => 'Deine Notizen';

  @override
  String get settingsBackup => 'Sicherung';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageNote =>
      'Die Wörter, die die App benutzt. Was du schreibst, gehört dir, in jeder Sprache, ganz gleich was hier steht.';

  @override
  String get settingsLanguageSystem => 'Dem Telefon folgen';

  @override
  String get entryMattered => 'Das war wichtig';

  @override
  String get entryMarked => 'Als eine markiert, die zählte.';

  @override
  String get entryMarkRemoved => 'Markierung entfernt.';

  @override
  String get entryDeleted => 'Gelöscht.';

  @override
  String entryEarlierVersions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count frühere Fassungen',
      one: 'Eine frühere Fassung',
    );
    return '$_temp0';
  }

  @override
  String get entryKeepsWords => 'Die Worte bleiben';

  @override
  String entryKindInTrash(Object kind) {
    return 'Das $kind ist im Papierkorb.';
  }

  @override
  String entryKindInTrashWords(Object kind) {
    return 'Das $kind ist im Papierkorb. Die Worte sind noch da.';
  }

  @override
  String trashConfirmBody(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Einträge und jede frühere Fassung davon. Das lässt sich nicht rückgängig machen.',
      one: 'Ein Eintrag und jede frühere Fassung davon. Das lässt sich nicht rückgängig machen.',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyEntry => 'Leerer Eintrag';

  @override
  String get kindPhoto => 'Foto';

  @override
  String get kindVideo => 'Video';

  @override
  String get kindRecording => 'Aufnahme';

  @override
  String get kindFile => 'Datei';

  @override
  String get entryNoLongerMarked => 'Nicht mehr markiert';

  @override
  String get entryFindAgain => 'Über die Suche wiederfinden';

  @override
  String get searchGoTo => 'Gehe zu';

  @override
  String get searchFolders => 'Ordner';

  @override
  String get searchEntriesOne => '1 Eintrag';

  @override
  String searchEntriesMany(int count) {
    return '$count Einträge';
  }

  @override
  String get searchNothingFound => 'Dazu passt nichts.';

  @override
  String get searchEverythingInstead => 'Stattdessen alles durchsuchen';

  @override
  String get onboardNoAccount => 'Es gibt kein Konto.';

  @override
  String get onboardPromiseBody =>
      'Deine Notizen bleiben auf diesem Telefon.\nWir haben keinen Server. Wir können sie nicht lesen.\nWir können sie auch nicht wiederherstellen.';

  @override
  String get onboardBegin => 'Anfangen';

  @override
  String get onboardHaveBackup => 'Ich habe ein Backup';

  @override
  String get onboardSetPasscode => 'Lege einen Code fest';

  @override
  String get onboardPasscodeBody =>
      'Das ist das Einzige, was deine Notizen öffnet. Ein Satz, den du dir merken kannst, ist stärker als vier Ziffern.';

  @override
  String get onboardPasscodeLabel => 'Code';

  @override
  String get onboardPasscodeAgain => 'Gib ihn noch einmal ein';

  @override
  String get onboardSettingUp => 'Wird eingerichtet…';

  @override
  String get onboardContinue => 'Weiter';

  @override
  String get onboardPasscodesDiffer => 'Die beiden stimmen nicht überein.';

  @override
  String get onboardVaultFailed => 'Dein Tresor konnte nicht angelegt werden.';

  @override
  String get onboardVaultFailedThen =>
      'Es wurde nichts gespeichert. Versuch es noch einmal.';

  @override
  String get onboardWriteWords => 'Schreib diese zwölf Wörter\nauf Papier';

  @override
  String get onboardWordsBody =>
      'Wir haben keine Kopie. Wir können sie dir nicht schicken. Es gibt keine Support-Adresse, die dir helfen kann.\n\nKein Screenshot — Papier. Ein Screenshot liegt in deiner Galerie, und dort schaut jeder zuerst nach.';

  @override
  String get onboardWrittenDown => 'Ich habe sie aufgeschrieben';

  @override
  String get onboardCopyWords => 'Die zwölf Wörter kopieren';

  @override
  String get onboardClipboardNote =>
      'Die Zwischenablage leert sich nach einer Minute von selbst. Bis dahin können andere Apps sie lesen.';

  @override
  String get onboardCopied =>
      'Kopiert. Es löscht sich in einer Minute von selbst — füg es jetzt an einem sicheren Ort ein.';

  @override
  String get onboardCopyFailed =>
      'Das konnte nicht kopiert werden. Aufschreiben ist ohnehin sicherer.';

  @override
  String get onboardCheckThree => 'Prüfe drei davon';

  @override
  String get onboardCheckBody =>
      'Damit wissen wir, dass das Papier stimmt, nicht der Bildschirm.';

  @override
  String onboardWordNumber(int number) {
    return 'Wort $number';
  }

  @override
  String onboardWordWrong(int number) {
    return 'Wort $number stimmt nicht. Sieh nach, was du aufgeschrieben hast.';
  }

  @override
  String get onboardShowWords => 'Zeig mir die Wörter noch einmal';

  @override
  String get onboardFingerprintTitle => 'Mit deinem Fingerabdruck öffnen?';

  @override
  String get onboardFingerprintBody =>
      'Damit du diesen Satz nicht jedes Mal eingeben musst.';

  @override
  String get onboardFingerprintExplain =>
      'Dein Satz bleibt der Schlüssel. Der Fingerabdruck öffnet nur diesen Tresor, nur auf diesem Telefon, und Android schaltet ihn von selbst ab, wenn sich die Fingerabdrücke auf dem Telefon ändern — damit niemand seinen hinzufügen und hineinkommen kann. Er ist nie Teil eines Backups.';

  @override
  String get onboardFingerprintWaiting => 'Warte auf deinen Finger…';

  @override
  String get onboardFingerprintUse => 'Meinen Fingerabdruck benutzen';

  @override
  String get onboardFingerprintFailed => 'Das hat nicht geklappt.';

  @override
  String get onboardOneLastThing => 'Noch eine letzte Sache';

  @override
  String get onboardNameBody =>
      'Wie soll Lamplight dich nennen? Es bleibt auf diesem Telefon, und du kannst es ändern oder weglassen.';

  @override
  String get onboardFingerprintOn =>
      'Dein Fingerabdruck öffnet Lamplight von jetzt an.';

  @override
  String get onboardYourName => 'Dein Name';

  @override
  String get onboardStartWriting => 'Anfangen zu schreiben';

  @override
  String get onboardSkip => 'Überspringen';

  @override
  String get settingsGroupLook => 'Wie sie aussieht und spricht';

  @override
  String get settingsGroupWhoCanOpen => 'Wer sie öffnen kann';

  @override
  String get settingsGroupKeeping => 'Aufbewahren und mitnehmen';

  @override
  String get settingsAppearanceNote => 'Thema, Schrift, Farbe, Seite';

  @override
  String get settingsFolders => 'Ordner';

  @override
  String get settingsFoldersNote => 'Menschen, Orte, Abschnitte';

  @override
  String get settingsMedia => 'Medien';

  @override
  String get settingsMediaNote => 'Fotos, Video, Ton und Dokumente';

  @override
  String get mediaGroupDocuments => 'Dokumente';

  @override
  String get mediaDocumentsKept =>
      'Genau so aufbewahrt, wie sie angekommen sind';

  @override
  String get mediaDocumentsFooter =>
      'Ein PDF oder eine Word-Datei ist innen bereits komprimiert; sie noch einmal zu komprimieren spart etwa fünf Prozent. Ein echter Unterschied hieße, die Bilder darin neu zu berechnen — das macht kleine Schrift in einem Scan dauerhaft unscharf, und du merktest es erst Jahre später, an dem Tag, an dem du es lesen müsstest.';

  @override
  String get settingsTrash => 'Papierkorb';

  @override
  String get settingsTrashNote => 'Gelöschte Einträge, 30 Tage lang aufbewahrt';

  @override
  String get settingsReadableCopy => 'Lesbare Kopie';

  @override
  String get settingsReadableCopyNote =>
      'Markdown und deine Dateien, in einem Ordner deiner Wahl';

  @override
  String get settingsBringIn => 'Ein altes Tagebuch übernehmen';

  @override
  String get settingsBringInNote =>
      'Textdateien aus einer anderen App, nach ihrem Datum einsortiert';

  @override
  String get settingsKeepingFooter =>
      'Ein Backup ist mit deinem Code verschlossen, genau wie der Tresor. Eine lesbare Kopie ist überhaupt nicht verschlossen — es sind einfache Dateien in einem Ordner, den du wählst.';

  @override
  String get backupNever => 'Noch nie gesichert';

  @override
  String get backupToday => 'Heute gesichert';

  @override
  String get backupYesterday => 'Gestern gesichert';

  @override
  String backupDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Tagen gesichert',
    );
    return '$_temp0';
  }

  @override
  String get mediaGroupIncoming => 'Beim Hereinkommen';

  @override
  String get mediaGroupVoice => 'Sprachnotizen';

  @override
  String get mediaIncomingFooter =>
      'Lamplight behält nie eine zweite, kleinere Kopie — was du hier wählst, ist was gespeichert wird, und das Original bleibt nirgendwo sonst.';

  @override
  String get mediaVoiceFooter =>
      'Das Aufschreiben passiert auf diesem Telefon, mit der Spracherkennung, die Android schon hat. Nichts, was du Lamplight sagst, wird irgendwohin geschickt, und die App hat keine Berechtigung, es zu schicken.';

  @override
  String get mediaPhotoSize => 'Fotogröße';

  @override
  String get mediaVideoSize => 'Videogröße';

  @override
  String get mediaAskEachTime => 'Jedes Mal fragen';

  @override
  String get accentAmber => 'Bernstein';

  @override
  String get accentAmberNote => 'Eine Lampe bei Nacht. Der übliche.';

  @override
  String get accentRose => 'Rosé';

  @override
  String get accentRoseNote => 'Warmes Rosa. Weicher als der Bernstein.';

  @override
  String get accentSage => 'Salbei';

  @override
  String get accentSageNote => 'Ruhiges Grün. Das gelassenste der sechs.';

  @override
  String get accentSlate => 'Schiefer';

  @override
  String get accentSlateNote => 'Kühles Blaugrau. Das neutralste.';

  @override
  String get accentPlum => 'Pflaume';

  @override
  String get accentPlumNote => 'Tiefes Violett.';

  @override
  String get accentEmber => 'Glut';

  @override
  String get accentEmberNote => 'Gebranntes Orange. Das wärmste.';

  @override
  String get surfacePlain => 'Schlicht';

  @override
  String get surfacePlainNote => 'Eine glatte Seite.';

  @override
  String get surfacePaper => 'Papier';

  @override
  String get surfacePaperNote =>
      'Eine feine Körnung, damit die Seite sich wie ein Material anfühlt. Die übliche.';

  @override
  String get surfaceLamplit => 'Lampenlicht';

  @override
  String get surfaceLamplitNote => 'Papier, mit eingeschalteter Lampe.';

  @override
  String get surfaceStarMap => 'Sternkarte';

  @override
  String get surfaceStarMapNote =>
      'Ein Himmel, der mit der Uhr wandert. An einem Tag nie zweimal derselbe.';

  @override
  String get rulingNone => 'Nichts';

  @override
  String get rulingNoneNote => 'Nichts auf der Seite gedruckt.';

  @override
  String get rulingLines => 'Linien';

  @override
  String get rulingLinesNote => 'Liniert wie ein Heft.';

  @override
  String get rulingIsometric => 'Isometrisch';

  @override
  String get rulingIsometricNote =>
      'Millimeterpapier zum Denken in drei Dimensionen.';

  @override
  String get rulingTriangle => 'Dreiecke';

  @override
  String get rulingTriangleNote => 'Ein Feld aus gleichseitigen Dreiecken.';

  @override
  String get rulingDots => 'Punktraster';

  @override
  String get rulingDotsNote =>
      'Ein Punkt an jeder Kreuzung. Das leiseste der vier.';

  @override
  String get faceSystem => 'System';

  @override
  String get faceSystemNote => 'Was der Rest deines Telefons benutzt.';

  @override
  String get faceSerif => 'System-Serife';

  @override
  String get faceSerifNote => 'Die eigene Serifenschrift deines Telefons.';

  @override
  String get faceCalmNote => 'Weiche Kanten, breite Buchstaben.';

  @override
  String get faceModernNote => 'Eng und gegenwärtig.';

  @override
  String get faceOldStyleNote => 'Eine Buchschrift aus dem 16. Jahrhundert.';

  @override
  String get facePlayfulNote => 'Rund und fröhlich.';

  @override
  String get faceChildlikeNote => 'Ein Schulheft.';

  @override
  String get faceHandwrittenNote =>
      'Handschrift, auch auf einer ganzen Seite noch lesbar.';

  @override
  String get faceMedievalNote => 'Die Hand eines Schreibers. Nur eine Stärke.';

  @override
  String get faceMonoNote => 'Jeder Buchstabe gleich breit.';

  @override
  String get qualityOriginal => 'Original behalten';

  @override
  String get qualityBalanced => 'Ausgewogen';

  @override
  String get qualitySmaller => 'Kleiner';

  @override
  String get photoOriginalNote =>
      'Genau so, wie deine Kamera es aufgenommen hat. Die größten Dateien — und sie behalten den Ort, an dem das Foto entstand, den Lamplight sonst entfernt.';

  @override
  String get photoBalancedNote =>
      'Deutlich kleiner und kaum vom Original zu unterscheiden. Die übliche Wahl.';

  @override
  String get photoSmallerNote =>
      'Noch einmal halb so groß. Beim starken Hineinzoomen kann es auffallen.';

  @override
  String get videoOriginalNote =>
      'Genau so, wie deine Kamera es aufgenommen hat. Mit Abstand die größten Dateien.';

  @override
  String get videoBalancedNote =>
      'Deutlich kleiner und kaum vom Original zu unterscheiden. Die übliche Wahl.';

  @override
  String get videoSmallerNote =>
      'Noch einmal halb so groß. Auf einem großen Bildschirm kann es auffallen.';

  @override
  String get appearanceTitle => 'Erscheinung';

  @override
  String get appearanceTheme => 'Thema';

  @override
  String get appearanceThemeDark => 'Dunkel';

  @override
  String get appearanceThemeLight => 'Hell';

  @override
  String get appearanceThemeAuto => 'Auto';

  @override
  String get appearanceThemeAutoNote =>
      'Folgt der Hell-Dunkel-Einstellung deines Telefons.';

  @override
  String get appearanceFont => 'Schrift';

  @override
  String get appearanceSize => 'Größe';

  @override
  String get appearanceColour => 'Farbe';

  @override
  String get appearancePage => 'Seite';

  @override
  String get appearanceRuling => 'Linierung';

  @override
  String get daySavedToToday => 'Bei heute gespeichert.';

  @override
  String get dayAddedToToday => 'Zu heute hinzugefügt.';

  @override
  String get entryEditWords => 'Den Text ändern';

  @override
  String get entryDeleteBlock => 'Den ganzen Block löschen';

  @override
  String entrySavedAs(String name) {
    return 'Als $name gespeichert.';
  }

  @override
  String entryAddedToFolder(String name) {
    return 'Auch in $name.';
  }

  @override
  String get entrySaveCopy => 'Eine Kopie speichern';

  @override
  String get entrySaveCopyNote =>
      'Irgendwo deiner Wahl, außerhalb von Lamplight';

  @override
  String get capturePhotoTake => 'Ein Foto aufnehmen';

  @override
  String get capturePhotoChoose => 'Aus deinen Fotos wählen';

  @override
  String get composerHintToday => 'Schreib über heute…';

  @override
  String get composerHintPast => 'Schreib über diesen Tag…';

  @override
  String get composerNewBlock => 'Neuer Block';

  @override
  String get voiceShowTranscript => 'Zeigen, was gesagt wurde';

  @override
  String get voiceHideTranscript => 'Verbergen, was gesagt wurde';

  @override
  String get voiceTranscriptTitle => 'Was gesagt wurde';

  @override
  String get entryEdited => ', bearbeitet';

  @override
  String photoSemantic(String time) {
    return 'Foto von $time. Zum Ansehen doppelt tippen.';
  }

  @override
  String get sizeThisPhoto => 'dieses Foto';

  @override
  String get sizeThesePhotos => 'diese Fotos';

  @override
  String get sizeThisVideo => 'dieses Video';

  @override
  String get sizeTheseVideos => 'diese Videos';

  @override
  String sizeQuestion(String what) {
    return 'Wie groß soll $what aufbewahrt werden?';
  }

  @override
  String get trashNote =>
      'Gelöschtes bleibt 30 Tage hier und geht dann endgültig.';

  @override
  String get trashConfirm => 'Das endgültig löschen?';

  @override
  String get trashKeep => 'Behalten';

  @override
  String get trashDeleteForGood => 'Endgültig löschen';

  @override
  String get trashPutBack => 'Zurücklegen';

  @override
  String trashPutBackOn(String day) {
    return 'Zurückgelegt auf $day.';
  }

  @override
  String get trashEmpty => 'Papierkorb leeren';

  @override
  String get folderMakeFirst => 'Den ersten anlegen';

  @override
  String folderDeleteAsk(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get folderKeepIt => 'Behalten';

  @override
  String get folderDeleteIt => 'Den Ordner löschen';

  @override
  String get folderRename => 'Umbenennen';

  @override
  String get folderDeleteThis => 'Diesen Ordner löschen';

  @override
  String folderTakenOut(String name) {
    return 'Aus $name herausgenommen. Er liegt weiter auf seinem Tag.';
  }

  @override
  String get searchHint => 'Wörter, ein Datum, ein Name…';

  @override
  String get searchBack => 'Zurück';

  @override
  String get searchClear => 'Leeren';

  @override
  String searchNothingMatches(String query) {
    return 'Nichts passt zu „$query“.';
  }

  @override
  String get searchWhatMattered => 'WAS ZÄHLTE';

  @override
  String get searchADate => 'Ein Datum';

  @override
  String get searchDateExample => '16. März 2006 · März 2006 · gestern';

  @override
  String get searchWhatYouCanType => 'Wonach du suchen kannst';

  @override
  String get searchTryDate => 'gestern';

  @override
  String get searchSaidOutLoud => 'laut gesagt';

  @override
  String get searchAPhotograph => 'Ein Foto';

  @override
  String get searchAVideo => 'Ein Video';

  @override
  String get securityWhileOpen => 'Solange die App offen ist';

  @override
  String get securityLockFooter =>
      'Lamplight sperrt immer sofort, sobald es in den Hintergrund geht. Hier geht es nur darum, wie lange es wartet, während du noch drin bist.';

  @override
  String get securityLockAfter => 'Sperren nach';

  @override
  String get securityOneHour => '1 Stunde';

  @override
  String get securityYourPasscode => 'Dein Code';

  @override
  String get securityPasscodeFooter =>
      'Dein Code ist der Schlüssel. Er wird nirgends gespeichert — nicht auf diesem Telefon und sonst auch nirgendwo — also kann niemand gezwungen werden, ihn herauszugeben, und niemand kann ihn für dich wiederherstellen.';

  @override
  String get securityChangePasscode => 'Code ändern';

  @override
  String get securityScreenshots => 'Bildschirmfotos';

  @override
  String get securityScreenshotsFooter =>
      'Lamplight verhindert Bildschirmaufnahmen, damit wer dein Telefon in die Hand nimmt deine Notizen nicht abfotografieren kann und sie nie in der Übersicht der zuletzt genutzten Apps auftauchen. Für dein eigenes Telefon kannst du das abschalten.';

  @override
  String get securityAllowScreenshots => 'Bildschirmfotos erlauben';

  @override
  String get securityScreenshotsOn =>
      'Deine Notizen erscheinen in den letzten Apps';

  @override
  String get securityScreenshotsOff =>
      'Die letzten Apps zeigen eine leere Seite';

  @override
  String get securityCouldNotChange => 'Das konnte nicht geändert werden.';

  @override
  String get securityNothingChanged =>
      'An deiner Sperre hat sich nichts geändert.';

  @override
  String get securityPromptAutomatic => 'Die Abfrage erscheint von selbst';

  @override
  String get securityPromptOnTap =>
      'Tippe auf den Fingerabdruck, wenn du ihn willst';

  @override
  String get mediaAskEachTimeOn =>
      'Du wirst beim Hinzufügen gefragt, wie groß Fotos und Videos bleiben sollen.';

  @override
  String get mediaAskEachTimeOff =>
      'Aus. Die beiden Größen oben werden ohne Nachfrage verwendet.';

  @override
  String get passcodeNew => 'Neuer Code';

  @override
  String get securityFingerprint => 'Fingerabdruck';

  @override
  String get securityFingerprintFooter =>
      'Dein Satz bleibt der Schlüssel. Der Fingerabdruck öffnet nur diesen Tresor, nur auf diesem Telefon, und Android schaltet ihn von selbst ab, wenn sich die Fingerabdrücke auf dem Telefon ändern — damit niemand seinen hinzufügen und hineinkommen kann. Er ist nie Teil eines Backups.';

  @override
  String get securityUnlockWithFingerprint => 'Mit meinem Fingerabdruck öffnen';

  @override
  String get securityAskOnOpen => 'Gleich beim Öffnen von Lamplight fragen';

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sekunden',
      one: '1 Sekunde',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten',
      one: '1 Minute',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stunden',
      one: '1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String get durationNever => 'Nie';

  @override
  String get securityDefaultNote => 'Die übliche Wahl.';

  @override
  String get securityHourNote => 'Für einen Nachmittag Nachlesen.';

  @override
  String get securityNeverNote =>
      'Beim Verlassen der App sperrt es trotzdem sofort.';

  @override
  String get calendarGoToDate => 'Zu einem Datum';

  @override
  String get dayHasWriting => 'Geschriebenes';

  @override
  String get dayHasPhoto => 'ein Foto';

  @override
  String get dayHasVideo => 'ein Video';

  @override
  String get dayHasVoice => 'eine Sprachnotiz';

  @override
  String get dayHasFile => 'eine Datei';

  @override
  String dayEntriesAndKinds(Object count, Object kinds) {
    return '$count, $kinds';
  }

  @override
  String get listSeparator => ', ';

  @override
  String listAnd(Object last, Object most) {
    return '$most und $last';
  }

  @override
  String get integrityNothingUnusual =>
      'Nichts Ungewöhnliches an diesem Telefon. Lamplight läuft so, wie es soll.';

  @override
  String get calendarPreviousYear => 'Vorheriges Jahr';

  @override
  String get calendarPreviousMonth => 'Vorheriger Monat';

  @override
  String get calendarNextYear => 'Nächstes Jahr';

  @override
  String get calendarNextMonth => 'Nächster Monat';

  @override
  String get calendarBackToMonth => 'Zurück zum Monat';

  @override
  String get calendarWholeYear => 'Das ganze Jahr';

  @override
  String get calendarBackToThisMonth => 'Zurück zu diesem Monat';

  @override
  String get calendarNothingThisYear => 'In diesem Jahr steht noch nichts.';

  @override
  String calendarYearSummary(Object days, Object entries) {
    return '$entries an $days.';
  }

  @override
  String get folderNothingInIt => 'Noch nichts darin';

  @override
  String get onThisDayOneYear => 'Heute vor einem Jahr';

  @override
  String onThisDayYears(Object years) {
    return 'Heute vor $years Jahren';
  }

  @override
  String wheelYear(Object year) {
    return 'Jahr $year';
  }

  @override
  String get calendarBackToBrowsing => 'Zurück zum Blättern';

  @override
  String get calendarToday => 'Heute';

  @override
  String get calendarFirstEntry => 'Dein erster Eintrag';

  @override
  String get calendarGoToThisDay => 'Zu diesem Tag';

  @override
  String get calendarDensityNote =>
      'Die Farbe zeigt, wie viel an einem Tag steht — von nichts bis viel.';

  @override
  String get calendarLess => 'Weniger';

  @override
  String get calendarMore => 'Mehr';

  @override
  String get calendarGoToToday => 'Zu heute';

  @override
  String get backupTitle => 'Backup';

  @override
  String get vaultNothingToBackUp =>
      'In diesem Tresor gibt es noch nichts zu sichern.';

  @override
  String vaultChangedWhileBackingUp(Object name) {
    return 'Während der Sicherung hat sich etwas geändert ($name). Versuche es noch einmal.';
  }

  @override
  String get vaultTooSmall =>
      'Diese Datei ist zu klein, um eine Lamplight-Sicherung zu sein.';

  @override
  String get vaultNotALamplightFile =>
      'Das ist keine Lamplight-Sicherungsdatei.';

  @override
  String get vaultDamaged =>
      'Diese Datei ist beschädigt und lässt sich nicht öffnen.';

  @override
  String get vaultKeyringNewerVersion =>
      'Dieser Tresor stammt aus einer neueren Lamplight-Version. Aktualisiere die App, um ihn zu öffnen.';

  @override
  String get vaultKeyringDamaged =>
      'Die Schlüsseldatei des Tresors ist beschädigt und nicht lesbar. Wenn du eine Sicherung hast, stelle daraus wieder her.';

  @override
  String get vaultDatabaseNewerVersion =>
      'Dieser Tresor stammt aus einer neueren Lamplight-Version. Aktualisiere die App, um ihn zu öffnen — deine Notizen sind unversehrt und nichts wurde geändert.';

  @override
  String phraseWrongLength(Object count) {
    return 'Ein Wiederherstellungssatz hat 12 Wörter. Dieser hat $count.';
  }

  @override
  String phraseNotARecoveryWord(Object word) {
    return '„$word“ ist keines der Wiederherstellungswörter.';
  }

  @override
  String get phraseDoesNotCheckOut =>
      'Diese Wörter sind kein gültiger Wiederherstellungssatz. Prüfe auf ein vertipptes oder vertauschtes Wort.';

  @override
  String get vaultNewerVersion =>
      'Diese Sicherung stammt aus einer neueren Lamplight-Version. Aktualisiere die App und versuche es noch einmal.';

  @override
  String get vaultUnknownCompression =>
      'Diese Sicherung nutzt eine Komprimierung, die diese Version nicht lesen kann.';

  @override
  String get vaultDamagedTryOlder =>
      'Diese Datei ist beschädigt und lässt sich nicht öffnen. Wenn du eine ältere Sicherung hast, versuche die.';

  @override
  String get vaultBeforeRecoveryPhrases =>
      'Diese Sicherung entstand, bevor Wiederherstellungswörter Sicherungsdateien öffnen konnten. Ihr Code ist der einzige Weg hinein.';

  @override
  String get vaultWordsDoNotOpenIt =>
      'Diese Wörter öffnen diese Datei nicht. Vielleicht gehören sie zu einem anderen Tresor.';

  @override
  String get vaultWrongPasscode => 'Dieser Code öffnet diese Datei nicht.';

  @override
  String vaultMissingPart(Object name) {
    return 'Dieser Sicherung fehlt ein Teil von sich selbst ($name).';
  }

  @override
  String vaultPartWrongSize(Object name) {
    return 'Diese Sicherung ist beschädigt ($name hat die falsche Größe).';
  }

  @override
  String vaultPartDoesNotMatch(Object name) {
    return 'Diese Sicherung ist beschädigt ($name stimmt nicht überein).';
  }

  @override
  String get vaultNoVaultInside =>
      'Diese Sicherung enthält keinen Tresor. Vielleicht stammt sie aus einer anderen App.';

  @override
  String get vaultOutOfOrder =>
      'Diese Datei ist beschädigt: ihr Inhalt ist durcheinander.';

  @override
  String get vaultEndsPartWay =>
      'Diese Datei ist beschädigt: sie hört mittendrin auf.';

  @override
  String vaultIncomplete(Object parts) {
    return 'Diese Datei ist unvollständig — sie hat $parts ihrer Teile.';
  }

  @override
  String vaultWillNotOpen(Object name) {
    return 'Diese Sicherung enthält etwas, das Lamplight nicht öffnen wird ($name).';
  }

  @override
  String countEntries(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
    );
    return '$_temp0';
  }

  @override
  String countDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get backupCheckingItOpens => 'Prüfen, ob sie sich öffnen lässt…';

  @override
  String get backupCouldNotSave =>
      'Die Sicherung konnte nicht gespeichert werden.';

  @override
  String get backupNothingLost =>
      'Nichts ging verloren, und deine Notizen sind unberührt. Versuche es gleich noch einmal.';

  @override
  String get backupLast => 'Letzte Sicherung';

  @override
  String get backupInTheVault => 'Im Tresor';

  @override
  String get restoreCheckingFile => 'Datei wird geprüft…';

  @override
  String get restoreCouldNotOpen => 'Diese Datei konnte nicht geöffnet werden.';

  @override
  String get restoreCheckItIsTheOne =>
      'Prüfe, ob es die gemeinte Sicherung ist, und versuche es noch einmal.';

  @override
  String get restorePuttingInPlace => 'Wird eingesetzt…';

  @override
  String get restorePuttingBack => 'Deine alten Notizen werden zurückgelegt…';

  @override
  String get restoreCouldNotFinish =>
      'Die Wiederherstellung konnte nicht abgeschlossen werden.';

  @override
  String get restoreBackAsTheyWere => 'Deine Notizen sind wieder wie zuvor.';

  @override
  String get restoreUsePasscodeInstead => 'Stattdessen den Code benutzen';

  @override
  String get restoreUseWordsInstead => 'Ich habe stattdessen die zwölf Wörter';

  @override
  String get backupCreateFile => 'Backup-Datei anlegen';

  @override
  String get backupCreatedChecked => 'Backup angelegt und geprüft.';

  @override
  String get backupMakeAnother => 'Noch eins anlegen';

  @override
  String get backupRestoreHeading => 'Wiederherstellen';

  @override
  String get backupRestoreFrom => 'Aus einer Backup-Datei wiederherstellen';

  @override
  String backupProgress(String stage, int percent) {
    return '$stage $percent Prozent';
  }

  @override
  String get restoreTitle => 'Wiederherstellen';

  @override
  String get restoreChooseFile => 'Eine Datei wählen';

  @override
  String get restorePhraseHint => 'erinnern Geschichte Industrie…';

  @override
  String get restoreAction => 'Wiederherstellen';

  @override
  String get restoreChooseDifferent => 'Eine andere Datei wählen';

  @override
  String get importChooseFolder => 'Einen Ordner wählen';

  @override
  String get importChooseFiles => 'Stattdessen die Dateien wählen';

  @override
  String get importChooseFilesNote =>
      'Wenn Android Ihren Ordner ablehnt — Downloads und die oberste Speicherebene gibt es keiner App — wählen Sie die Dateien selbst. Das wird nie abgelehnt.';

  @override
  String get importLooking => 'Sieht den Ordner durch…';

  @override
  String get importNoTextFiles => 'In diesem Ordner sind keine Textdateien.';

  @override
  String get importChooseDifferentFolder => 'Einen anderen Ordner wählen';

  @override
  String get importUseFileDate => 'Das eigene Datum der Datei benutzen';

  @override
  String get importUseFileDateNote =>
      'Legt sie auf den Tag, an dem die Datei zuletzt geändert wurde. Das ist oft nicht der Tag, um den es geht.';

  @override
  String importBringIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen übernehmen',
      one: '1 Notiz übernehmen',
    );
    return '$_temp0';
  }

  @override
  String importProgress(int percent) {
    return 'Wird übernommen, $percent Prozent';
  }

  @override
  String get exportChooseFolder => 'Ordner wählen und exportieren';

  @override
  String get exportWritten => 'Deine Kopie ist geschrieben.';

  @override
  String get exportAgain => 'Noch einmal exportieren';

  @override
  String get exportWhichOne => 'Welche will ich?';

  @override
  String get exportNotLocked => 'Diese Kopie ist nicht verschlossen';

  @override
  String dayAddedThings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dinge zu heute hinzugefügt.',
    );
    return '$_temp0';
  }

  @override
  String get entryAddNote => 'Eine Notiz dazu schreiben';

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hinzugefügt.',
      one: 'Hinzugefügt.',
    );
    return '$_temp0';
  }

  @override
  String get importFolderUnreadable =>
      'Dieser Ordner konnte nicht gelesen werden.';

  @override
  String get importNothingBrought => 'Es wurde nichts übernommen.';

  @override
  String get importStoppedPartWay =>
      'Das Übernehmen des Tagebuchs ist auf halbem Weg gestoppt.';

  @override
  String get importWhatArrivedKept =>
      'Alles, was vorher ankam, wurde behalten.';

  @override
  String get importNoReadableDates =>
      'Keine dieser Dateien hat ein Datum, das Lamplight lesen kann.';

  @override
  String importReadyToBring(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge bereit zum Übernehmen.',
      one: '1 Eintrag bereit zum Übernehmen.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingNew => 'Nichts Neues zu übernehmen.';

  @override
  String importBroughtIn(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge übernommen.',
      one: '1 Eintrag übernommen.',
    );
    return '$_temp0';
  }

  @override
  String importAlreadyHere(Object count) {
    return '$count waren schon da und blieben unangetastet.';
  }

  @override
  String importNoDateSkipped(Object count) {
    return '$count hatten kein lesbares Datum und wurden übersprungen.';
  }

  @override
  String importCouldNotRead(Object count, Object names) {
    return '$count konnten nicht gelesen werden: $names';
  }

  @override
  String get exportStarting => 'Wird gestartet…';

  @override
  String get exportCouldNotFinish =>
      'Die lesbare Kopie konnte nicht fertiggestellt werden.';

  @override
  String get exportNothingChanged => 'In Lamplight hat sich nichts geändert.';

  @override
  String get importVideoAlreadySmall =>
      'Ein Video war schon so klein wie möglich und wurde daher unverändert behalten.';

  @override
  String get importVideoCouldNotShrink =>
      'Ein Video ließ sich auf diesem Telefon nicht verkleinern und wurde ganz behalten.';

  @override
  String importOneFailed(String reason) {
    return 'Eines hat nicht geklappt: $reason';
  }

  @override
  String importAbandoned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wurden nicht fertig, bevor Lamplight zugesperrt hat.',
      one: 'Eines wurde nicht fertig, bevor Lamplight zugesperrt hat.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingLeft => 'Auf dem Telefon ist nichts zurückgeblieben.';

  @override
  String get nameCardAsk => 'Was soll hier stehen?';

  @override
  String get nameCardHint => 'Dein Name, oder irgendetwas';

  @override
  String get reminderGroup => 'Ein Anstupser, wenn du magst';

  @override
  String get reminderFooter =>
      'Aus, bis du es einschaltest. Es erwähnt nie, was in deinen Notizen steht — es kann nicht, weil es läuft, während der Tresor zu ist. Keine Serien, keine Zählerei, nichts über Tage, die du ausgelassen hast.';

  @override
  String get reminderTitle => 'Ans Schreiben erinnern';

  @override
  String get reminderWhen => 'Wann';

  @override
  String get reminderProblemNotAllowed =>
      'Lamplight darf keine Benachrichtigungen senden.';

  @override
  String get reminderProblemNotificationsOff =>
      'In den Einstellungen dieses Telefons sind Lamplights Benachrichtigungen ausgeschaltet.';

  @override
  String get reminderProblemRemindersOff =>
      'Erinnerungen von Lamplight sind in den Benachrichtigungseinstellungen dieses Telefons ausgeschaltet.';

  @override
  String get reminderProblemBatterySaving =>
      'Dieses Telefon spart Strom, indem es Lamplight zurückhält. Das ist der übliche Grund, warum eine Erinnerung spät oder gar nicht kommt.';

  @override
  String get reminderMayNotArrive => 'Die Erinnerung kommt vielleicht nicht an';

  @override
  String get backupAutomatic => 'Automatisch sichern';

  @override
  String get backupAutomaticDidNotFinish =>
      'Die automatische Sicherung wurde nicht fertig.';

  @override
  String get backupNothingYet => 'Noch nichts zu sichern.';

  @override
  String get backupInProgress => 'Wird gesichert…';

  @override
  String get backupStartsAtUnlock => 'Beginnt beim nächsten Entsperren.';

  @override
  String get backupDoneAutomatically => 'Automatisch gesichert.';

  @override
  String get backupLastOneFailed =>
      'Die letzte automatische Sicherung wurde nicht fertig. Sie versucht es beim nächsten Öffnen von Lamplight erneut.';

  @override
  String importNthOf(Object index, Object total) {
    return '$index von $total';
  }

  @override
  String importWaiting(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warten',
      one: '1 wartet',
    );
    return '$_temp0';
  }

  @override
  String get aboutCopied => 'Kopiert';

  @override
  String get failureGeneric => 'Das hat nicht geklappt.';

  @override
  String get failureNothingLost =>
      'Nichts ging verloren — versuche es noch einmal.';

  @override
  String get calendarNothingOnDay => 'nichts';

  @override
  String get backupChangeFolder => 'Ordner wechseln';

  @override
  String backupSavedTo(String place) {
    return 'Wird in $place gespeichert';
  }

  @override
  String get backupUseDefaultFolder => 'Den üblichen Ordner verwenden';

  @override
  String get backupChooseFolder => 'Wähle einen Ordner für die Kopien';

  @override
  String get folderAndroidRestriction =>
      'Android gibt keiner App den Ordner „Downloads“ oder den gesamten internen Speicher. „Documents“ oder ein Ordner darin geht.';

  @override
  String get folderNotWritable =>
      'In diesem Ordner lässt sich nichts speichern. Wähle einen anderen.';

  @override
  String get folderRefused => 'Dieser Ordner konnte nicht verwendet werden.';

  @override
  String get folderTryAnother => 'Versuche es mit einem anderen.';

  @override
  String get aboutHowKept => 'Wie deine Notizen aufbewahrt werden';

  @override
  String get aboutFonts => 'Schriften und Lizenzen';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutNoBrowser =>
      'Keine App auf diesem Telefon kann Links öffnen.';

  @override
  String get aboutMadeBy => 'Gemacht von';

  @override
  String get aboutMadeBySemantic =>
      'Gemacht von ProbablyPiyush. Öffnet LinkedIn im Browser.';

  @override
  String get aboutCoffee => 'Spendier mir einen Kaffee';

  @override
  String get aboutCoffeeSemantic =>
      'Spendier mir einen Kaffee. Öffnet eine Seite im Browser.';

  @override
  String get aboutCopyDetails => 'Die Angaben kopieren';

  @override
  String settingsNameSemantic(Object name) {
    return '$name. Zum Ändern tippen.';
  }

  @override
  String get settingsAddName => 'Deinen Namen eintragen';

  @override
  String get settingsNameOnlyHere => 'Nur auf diesem Telefon';

  @override
  String get settingsNameOptional =>
      'Freiwillig. Immer nur auf diesem Telefon.';

  @override
  String get reminderTurnedOffByAndroid =>
      'Android hat Benachrichtigungen für Lamplight ausgeschaltet. Du kannst sie in den Telefoneinstellungen unter Apps einschalten.';

  @override
  String get reminderOnceADay => 'Einmal am Tag';

  @override
  String reminderTodayAt(Object time) {
    return 'heute um $time';
  }

  @override
  String reminderYesterdayAt(Object time) {
    return 'gestern um $time';
  }

  @override
  String reminderOnDateAt(Object date, Object time) {
    return 'am $date um $time';
  }

  @override
  String get reminderNoneYet => 'Bisher ist nichts angekommen';

  @override
  String reminderLastArrived(Object when) {
    return 'Die letzte kam $when';
  }

  @override
  String reminderNextDue(Object when) {
    return 'Die nächste ist $when fällig';
  }

  @override
  String get aboutHide => 'Ausblenden';

  @override
  String get aboutCheckReal => 'Prüfen, ob dies das echte Lamplight ist';

  @override
  String get entryRevisionsNote => 'Was hier stand, bevor du es geändert hast';

  @override
  String get entryStaysOnDay => 'Er bleibt auch an diesem Tag';

  @override
  String entryDeleteKind(String kind) {
    return '$kind löschen';
  }

  @override
  String get shareCouldNotAdd =>
      'Das ließ sich nicht hinzufügen. Versuch es zu speichern und den Bild-Knopf zu nehmen.';

  @override
  String get openNothingCanOpen =>
      'Nichts auf diesem Telefon kann diese Art von Datei öffnen.';

  @override
  String get viewerMore => 'Mehr';

  @override
  String get docLeavesLamplight => 'Das verlässt Lamplight';

  @override
  String get docKeepItHere => 'Hierbehalten';

  @override
  String get docOpenWith => 'Öffnen mit…';

  @override
  String docCannotShow(String kind) {
    return 'Lamplight kann PDFs, Bilder und Text zeigen, ohne sie je unverschlüsselt auf dein Telefon zu legen. Eine $kind-Datei braucht eine andere App — Lamplight kann sie ihr leihen, solange du liest, und danach zurücknehmen.';
  }

  @override
  String get menuOpenWithNote => 'Eine andere App, ohne Kopie';

  @override
  String menuSaveKind(String kind) {
    return '$kind speichern';
  }

  @override
  String get menuTrashNote => '30 Tage aufbewahrt, dann weg';

  @override
  String get videoBackTen => 'Zehn Sekunden zurück';

  @override
  String get videoForwardTen => 'Zehn Sekunden vor';

  @override
  String get photoPlayVideo => 'Dieses Video abspielen';

  @override
  String get lockPhraseHint => 'Deine zwölf Wörter, mit Leerzeichen';

  @override
  String get lockUnlock => 'Öffnen';

  @override
  String get errorScreenDidNotOpen =>
      'Dieser Bildschirm ging nicht auf. Es ist nichts verloren.';

  @override
  String get errorGoBack => 'Zurück';

  @override
  String recordingCannot(String what) {
    return 'Dieses Telefon wird eine Aufnahme nicht $what. Es nimmt weiter auf.';
  }

  @override
  String get recordingClose => 'Schließen';

  @override
  String recordingElapsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nimmt auf, $count Sekunden',
      one: 'Nimmt auf, $count Sekunde',
    );
    return '$_temp0';
  }

  @override
  String get recordingStopKeep => 'Anhalten und diese Aufnahme behalten';

  @override
  String get recordingDiscard => 'Verwerfen';

  @override
  String get recordingCouldNotStart => 'Die Aufnahme konnte nicht starten.';

  @override
  String get recordingCheckMicrophone =>
      'Prüfe, ob Lamplight das Mikrofon benutzen darf.';

  @override
  String get recordingStartAgain => 'wieder starten';

  @override
  String get recordingCouldNotSave =>
      'Diese Aufnahme konnte nicht gespeichert werden.';

  @override
  String get recordingStillHere =>
      'Sie ist noch da — versuche noch einmal zu stoppen.';

  @override
  String get recordingCarryOnSemantic => 'Aufnahme fortsetzen';

  @override
  String get recordingPauseSemantic => 'Diese Aufnahme pausieren';

  @override
  String get recordingCarryOn => 'Weiter';

  @override
  String get recordingPause => 'Pause';

  @override
  String get sizeAdd => 'Hinzufügen';

  @override
  String get transcribeTitle => 'Aufschreiben, was gesagt wird';

  @override
  String get transcribeOn =>
      'Sprachnotizen werden durchsuchbar. Es wird nichts irgendwohin geschickt.';

  @override
  String get transcribeOff =>
      'Aus. Sprachnotizen sind nur über ihren Tag zu finden.';

  @override
  String get transcribeLanguage => 'Gesprochene Sprache';

  @override
  String get transcribeLanguageNote =>
      'Die Sprache, in der du in deine Aufnahmen sprichst. Immer nur eine — ein Satz, der zwischen zweien wechselt, kommt als die Hälfte zurück, die zu dieser passt.';

  @override
  String get transcribeNotDownloaded =>
      'Auf diesem Telefon noch nicht geladen — zum Holen tippen.';

  @override
  String transcribeGetBetter(String name) {
    return 'Das bessere Modell für $name holen';
  }

  @override
  String get transcribeGetBetterNote =>
      'Damit werden die Mitschriften merklich genauer. Der Download kommt von deinem Telefon, nicht von Lamplight, und passiert einmal.';

  @override
  String get transcribeNoLanguages =>
      'Dieses Telefon hat noch keine Sprachen angeboten.';

  @override
  String get transcribeNeedsDownloading => 'Muss geladen werden';

  @override
  String folderStill(String day, String folder) {
    return 'Weiterhin am $day. Auch in $folder.';
  }

  @override
  String get folderRenameTitle => 'Ordner umbenennen';

  @override
  String get folderNameHint => 'Ein Mensch, ein Ort, ein Abschnitt';

  @override
  String get voicePlay => 'Diese Sprachnotiz anhören';

  @override
  String get voiceForwardThirty => 'Dreißig Sekunden vor';

  @override
  String voiceSpeed(String speed) {
    return 'Tempo, gerade $speed-fach';
  }

  @override
  String get voiceLengthUnknown =>
      'Sprachnotiz, Länge erst beim Abspielen bekannt';

  @override
  String get voicePosition => 'Stelle in der Aufnahme';

  @override
  String get voiceOpening => 'Aufnahme wird geöffnet';

  @override
  String get voiceNoWords =>
      'Es kamen keine Wörter zurück — versuch es noch einmal';

  @override
  String get voiceWriteThis => 'Das aufschreiben';

  @override
  String get voiceCannotWrite =>
      'Dieses Telefon kann Sprachnotizen nicht aufschreiben.';

  @override
  String get voiceLanguageMissing =>
      'Dieses Telefon hat diese Sprache noch nicht geladen.';

  @override
  String get voiceWriting => 'Wird aufgeschrieben…';

  @override
  String get voiceWaiting => 'Wartet aufs Aufschreiben.';

  @override
  String get voiceWritten => 'Auf diesem Telefon aufgeschrieben.';

  @override
  String get errorPartNotShown => 'Dieser Teil ließ sich nicht anzeigen.';

  @override
  String get errorScreenShort => 'Dieser Bildschirm ging nicht auf.';

  @override
  String get errorNothingLost =>
      'Es ist nichts verloren. Alles, was du geschrieben hast, liegt weiter im Tresor, genau so wie es war.';

  @override
  String get errorHideDetails => 'Die technischen Angaben ausblenden';

  @override
  String get errorShowDetails => 'Die technischen Angaben zeigen';

  @override
  String get errorDetailsNote =>
      'Das ist alles, was kopiert würde. Es sagt, was kaputtging und an welcher Stelle im Code — es enthält nichts von dem, was du geschrieben hast.';

  @override
  String get passcodeChangeFailed => 'Der Code konnte nicht geändert werden.';

  @override
  String get passcodeOldStillWorks => 'Dein alter Code gilt weiter.';

  @override
  String get passcodeChanged => 'Code geändert';

  @override
  String get passcodeWordsUnchanged =>
      'Deine zwölf Wörter haben sich nicht geändert, und du brauchst keine neuen. Sie öffnen deinen Tresor und deine Backups genau wie vorher.';

  @override
  String get passcodeOldBackups =>
      'Backups, die du schon hast, öffnen weiterhin mit deinem alten Code. Ein neues, jetzt gemachtes, nimmt den neuen.';

  @override
  String get passcodeMakeBackup => 'Jetzt ein Backup machen';

  @override
  String get passcodeCurrent => 'Jetziger Code';

  @override
  String get passcodeNewAgain => 'Der neue noch einmal';

  @override
  String get passcodeOldBackupsNote =>
      'Backup-Dateien, die du schon angelegt hast, öffnen weiterhin mit deinem alten Code.';

  @override
  String get passcodeWordsNote =>
      'Deine zwölf Wiederherstellungswörter ändern sich nicht und funktionieren weiter.';

  @override
  String get licencesFonts =>
      'Jede Schrift hier steht unter der SIL Open Font License. Es wird nichts geladen — sie sind in der App.';

  @override
  String get licencesSource =>
      'Lamplight selbst ist GPL-3.0 mit einer App-Store-Ausnahme. Der Quelltext ist die Lizenz: jeder kann ihn lesen und prüfen, dass die App tut, was auf diesem Bildschirm steht.';

  @override
  String get licencesUnreadable => 'Diese Lizenzdatei ließ sich nicht lesen.';

  @override
  String get appearanceSample =>
      'Den ganzen Nachmittag Regen. Tee gemacht, ein halbes Kapitel gelesen, vergessen was ich sagen wollte und stattdessen das hier geschrieben.';

  @override
  String get appearanceChromeNote => 'Knöpfe und Beschriftungen bleiben so';

  @override
  String get appearanceSizeNote =>
      'Das kommt zur eigenen Textgröße deines Telefons hinzu — wenn du die schon hochgestellt hast, geht das hier noch weiter.';

  @override
  String get voicePause => 'Pause';

  @override
  String get importIntro =>
      'Wenn du woanders Tagebuch geschrieben hast, kann Lamplight es übernehmen — solange es Textdateien mit dem Datum im Namen sind.';

  @override
  String get importHowDates =>
      'Es liest einfache Textdateien und sucht ein Datum im Namen — 2026-08-24 oder 24. August 2026 — irgendwo im Dateinamen oder in den Ordnern darüber.';

  @override
  String get importAmbiguousDates =>
      'Daten wie 03-04-2026 werden absichtlich übersprungen. Das ist in manchen Ländern der dritte April und in anderen der vierte März, und falsch geraten würde ein Jahr deines Lebens auf die falschen Tage legen, ohne dir etwas zu sagen.';

  @override
  String get importFormats =>
      'Lamplight liest einfachen Text: .txt, .md, .org, .log und andere, auch Dateien ganz ohne Endung. Wenn dein Tagebuch in einem anderen Format vorliegt, exportiere es zuerst als Text.';

  @override
  String get importAtStartOfDay =>
      'Sie stehen am Anfang jedes Tages, weil ein Dateiname das Datum verrät, aber nicht die Uhrzeit. Nichts, was schon in Lamplight ist, wird geändert oder entfernt, und ein zweiter Durchlauf legt keine Kopien an.';

  @override
  String get importFileDateNote =>
      'Legt sie auf den Tag, an dem die Datei zuletzt geändert wurde. Wenn der Ordner zwischen Geräten kopiert wurde, kann das der Tag des Kopierens sein und nicht der Tag, an dem du geschrieben hast.';

  @override
  String get importSkippedNote =>
      'Diese werden übersprungen. Sie bleiben genau, wo sie sind — aus deinem Ordner wird nichts verschoben oder gelöscht.';

  @override
  String get restoreChooseNote =>
      'Wähle deine Backup-Datei. Sie heißt ungefähr Lamplight-2026-08-18.vault.';

  @override
  String get restorePasscodeNote =>
      'Gib den Code für diese Datei ein — den, der galt, als das Backup gemacht wurde.';

  @override
  String get restoreWordsNote =>
      'Tippe die zwölf Wörter, der Reihe nach, mit Leerzeichen dazwischen.';

  @override
  String get restoreDoNotClose =>
      'Schließe Lamplight nicht, bis das fertig ist.';

  @override
  String get exportIntro =>
      'Das schreibt alles aus Lamplight in einen Ordner deiner Wahl, als ganz gewöhnliche Dateien — eine Textdatei je Tag, und jedes Foto, Video, jede Sprachnotiz und jedes Dokument unter seinem eigenen Namen.';

  @override
  String get exportNoLamplightNeeded =>
      'Nichts in diesem Ordner braucht Lamplight zum Öffnen. Sollte diese App einmal nicht mehr laufen, oder du sie nicht mehr benutzen, öffnen sich deine Notizen weiter in allem, was Text lesen kann.';

  @override
  String get exportWhichOneBody =>
      'Eine lesbare Kopie ist zum Lesen, zum Umziehen in eine andere App, oder um etwas zu behalten, nachdem du Lamplight nicht mehr benutzt. Sie ist nicht geschützt.\n\nEine Backup-Datei ist dafür, Lamplight genau so zurückzubekommen, wie es war — ein neues Telefon, oder eines, das kaputtging. Sie ist mit deinem Code verschlossen und lässt sich daher überall aufbewahren, auch in einer Cloud.\n\nDie meisten wollen das Backup. Mach zusätzlich eine lesbare Kopie, wenn du ganz sicher sein willst, nie festzustecken.';

  @override
  String get exportNotLockedBody =>
      'Sie hat keinen Code. Wer den Ordner öffnet, kann alles darin lesen. Leg sie irgendwohin, wo dir das recht ist — und wenn du nur etwas Sicheres zum Aufheben willst, nimm stattdessen Backup.';

  @override
  String get backupConfirmNote =>
      'Bestätige deinen Code. Diese Datei kann alles aufsperren, deshalb sollte es etwas sein, das du wirklich vorhattest.';

  @override
  String get backupKeepSafeNote =>
      'Dein Backup ist mit dem Code verschlossen, den du jetzt hast. Bewahre es auf, wo du magst — eine Cloud ist in Ordnung, weil die Datei ohne diesen Code unlesbar ist. Wir sehen ihn nie.';

  @override
  String get backupRestoreWarning =>
      'Ein Backup zu öffnen ersetzt alles, was gerade in Lamplight ist. Deine jetzigen Notizen werden beiseitegelegt, bis erwiesen ist, dass die wiederhergestellten sich öffnen.';

  @override
  String get folderWhatItIs =>
      'Ein Ordner ist ein Faden, der durch deine Tage läuft — ein Mensch, ein Ort, ein Abschnitt.';

  @override
  String get folderNothingMoves =>
      'Nichts zieht in einen Ordner um. Ein Eintrag bleibt an seinem Tag und taucht hier zusätzlich auf.';

  @override
  String get folderDeleteNote =>
      'Der Ordner geht. Alles darin bleibt genau da, wo es ist, an seinem eigenen Tag.';

  @override
  String get folderNoneInHere =>
      'Hier ist noch nichts. Halte etwas an einem Tag gedrückt und wähle „Zu einem Ordner hinzufügen“.';

  @override
  String get passcodeRuleLength => 'Acht Zeichen oder mehr.';

  @override
  String get passcodeRuleWords =>
      'Ein paar gewöhnliche Wörter, die du dir merkst, schlagen ein kurzes mit Sonderzeichen.';

  @override
  String get passcodeNoMatch => 'Die beiden stimmen noch nicht überein.';

  @override
  String get docCopyInClear =>
      'Die Kopie wird unverschlüsselt geschrieben, also kann jede App, die deine Dateien lesen kann, sie lesen. Was in Lamplight bleibt, bleibt so oder so verschlüsselt.';

  @override
  String docPageOf(String page, String total) {
    return '$page von $total';
  }

  @override
  String get transcribeTookTooLong =>
      'Diese Aufnahme brauchte zu lange zum Aufschreiben, also hat Lamplight aufgehört zu warten. Es versucht es später noch einmal.';

  @override
  String get transcribeCouldNotWriteDown =>
      'Diese Aufnahme konnte nicht aufgeschrieben werden.';

  @override
  String get transcribeRecordingIsSafe =>
      'Die Aufnahme selbst ist sicher. Lamplight versucht es noch einmal.';

  @override
  String voicePositionSpoken(Object at, Object total) {
    return '$at von $total';
  }

  @override
  String entryEditedAt(Object time) {
    return '$time · bearbeitet';
  }

  @override
  String get docCouldNotOpen => 'Dieses Dokument konnte nicht geöffnet werden.';

  @override
  String albumThisOne(Object thing) {
    return 'Dieses $thing';
  }

  @override
  String albumThisOneOf(Object index, Object thing, Object total) {
    return 'Dieses $thing — $index von $total';
  }

  @override
  String get albumCaptionThese => 'Etwas dazu schreiben';

  @override
  String get albumCaptionThis => 'Etwas dazu schreiben';

  @override
  String get albumCaptionEdit => 'Das Geschriebene ändern';

  @override
  String albumOthersStay(Object count) {
    return 'Die anderen $count bleiben. Dieses wandert für 30 Tage in den Papierkorb.';
  }

  @override
  String get albumGoesToTrash => 'Es wandert für 30 Tage in den Papierkorb.';

  @override
  String get photoCouldNotOpen => 'Dieses Bild konnte nicht geöffnet werden.';

  @override
  String get photoMayBeDamaged => 'Es ist vielleicht beschädigt.';

  @override
  String get docTooBig =>
      'Diese ist zu groß, um sie in Lamplight zu öffnen. Du kannst eine Kopie speichern und sie woanders öffnen.';

  @override
  String docPages(Object count) {
    return '$count Seiten';
  }

  @override
  String get docFileEmpty => 'Diese Datei ist leer.';

  @override
  String videoTooBig(Object size) {
    return 'Dieses Video ist zu groß, um es hier abzuspielen — $size. Es wird dafür nicht ungeschützt herausgeschrieben. Speichere eine Kopie, um es woanders anzusehen.';
  }

  @override
  String get videoNotAvailableHere =>
      'Dieser Teil der App ist auf diesem Telefon nicht verfügbar.';

  @override
  String get videoCouldNotOpen => 'Dieses Video konnte nicht geöffnet werden.';

  @override
  String get docGoToPage => 'Zu einer Seite springen';

  @override
  String get docGo => 'Los';

  @override
  String get docPageCouldNotBeDrawn =>
      'Diese Seite konnte nicht gezeichnet werden.';

  @override
  String get passcodeRuleStronger =>
      'Ein, zwei Wörter mehr machen es erheblich schwerer zu erraten.';

  @override
  String get backupAutoFooter =>
      'Automatische Backups laufen, wenn du Lamplight öffnest, sofern sich seit dem letzten etwas geändert hat. Sie sind mit deinem Code verschlossen, genau wie eines, das du selbst machst.';

  @override
  String get aboutHowKeptBody =>
      'Kein Konto. Kein Server. Nichts verlässt dieses Telefon.\n\nDeine Notizen sind mit deinem Code verschlossen, und der Schlüssel wird daraus gebildet — es gibt ihn also nirgends als Kopie, auch nicht bei uns.';

  @override
  String get aboutFree =>
      'Lamplight ist kostenlos und bleibt es. Es gibt nichts freizuschalten.';

  @override
  String get backupOnItsOwn => 'Von selbst';

  @override
  String get actionDismiss => 'Ausblenden';

  @override
  String importRange(String from, String to) {
    return 'Von $from bis $to.';
  }

  @override
  String get sizeOneCopy =>
      'Lamplight behält eine Kopie. Was du hier wählst, ist das, was du hast.';

  @override
  String get sizeAddAlways => 'Hinzufügen und nicht mehr fragen';

  @override
  String get trashNothingHere => 'Hier ist nichts.';

  @override
  String get appearanceAaQuiet => 'Aa\nruhig';

  @override
  String lockWarnSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sperrt in etwa $count Sekunden.',
      one: 'Sperrt in etwa einer Sekunde.',
    );
    return '$_temp0';
  }

  @override
  String get lockWarnChange => 'Das änderst du unter Sperren und Sicherheit.';

  @override
  String get openingLabel => 'Lamplight wird geöffnet';

  @override
  String get recordingNoMic =>
      'Lamplight darf das Mikrofon nicht benutzen. Du kannst es in den Telefoneinstellungen unter Apps erlauben.';

  @override
  String get recordingPaused => 'Pausiert. Es wird nichts gehört.';

  @override
  String get videoOpening => 'Video wird geöffnet…';

  @override
  String albumRemoveThis(String thing) {
    return '$thing entfernen';
  }

  @override
  String get revisionsNote =>
      'Was hier stand, bevor du es geändert hast. Nichts davon ist ein Knopf — du kannst den Text markieren und kopieren.';

  @override
  String get composerSemantic => 'Schreib etwas für diesen Tag';

  @override
  String importStripAdding(String name) {
    return '$name wird hinzugefügt';
  }

  @override
  String passcodeAtLeast(int count) {
    return 'Mindestens $count Zeichen';
  }

  @override
  String get searchKindAll => 'Alles';

  @override
  String get searchKindWords => 'Wörter';

  @override
  String get searchKindVoice => 'Stimme';

  @override
  String get searchKindPhotos => 'Fotos';

  @override
  String get searchKindFiles => 'Dateien';

  @override
  String passcodeAtLeastShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mindestens $count Zeichen',
      one: 'Mindestens 1 Zeichen',
    );
    return '$_temp0';
  }

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Tage',
      one: 'Noch 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get trashGoneToday => 'Geht heute';

  @override
  String restoreMadeOn(String date) {
    return 'Gemacht am $date';
  }

  @override
  String restoreDone(String entries, String days) {
    return '$entries an $days wiederhergestellt. Willkommen zurück.';
  }

  @override
  String importFoundUndated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ohne Datum, das Lamplight lesen kann',
      one: '1 ohne Datum, das Lamplight lesen kann',
    );
    return '$_temp0';
  }

  @override
  String entrySemantic(String time) {
    return 'Eintrag um $time. Zum Bearbeiten tippen.';
  }

  @override
  String entrySemanticEdited(String time) {
    return 'Eintrag um $time, bearbeitet. Zum Bearbeiten tippen.';
  }

  @override
  String onThisDaySemantic(String when, String body) {
    return '$when. $body. Tippen, um zu diesem Tag zu gehen.';
  }

  @override
  String attachmentSemantic(String what, String time) {
    return '$what um $time. Zum Öffnen doppelt tippen.';
  }

  @override
  String dayHeaderToday(String date) {
    return '$date, heute';
  }

  @override
  String get yearGridNothing => 'Nichts an diesem Tag';

  @override
  String get calendarNothing => 'Nichts an diesem Tag';

  @override
  String importStripCounted(String name, String counted) {
    return '$name wird hinzugefügt$counted';
  }

  @override
  String get aboutFingerprintBody =>
      'Jeder Build trägt eine Signatur, die nur sein Urheber erzeugen kann. Das ist die auf der Kopie, die du in der Hand hast. Vergleiche sie mit dem Fingerabdruck, der neben dem Quelltext veröffentlicht ist — stimmen sie überein, ist dies die App, die dieser Quelltext baut.';

  @override
  String get searchKindVideo => 'Video';

  @override
  String get semanticOn => 'an';

  @override
  String andMore(int count) {
    return 'und $count weitere';
  }

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
      zero: 'nichts',
    );
    return '$_temp0';
  }

  @override
  String get checkDone => 'Erfüllt';

  @override
  String get checkNotYet => 'Noch nicht';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get lockUseYourPasscode => 'Nutze deinen Code.';

  @override
  String get searchWordsExample => 'alles, was du geschrieben hast';

  @override
  String get searchAFile => 'Eine Datei';

  @override
  String get searchFileExample => 'scan.pdf · IMG_2831';

  @override
  String get searchAFolder => 'Ein Ordner';

  @override
  String get searchFolderExample => 'der Name, den du ihm gegeben hast';

  @override
  String get searchByFileName => 'über den Dateinamen';

  @override
  String get searchARecording => 'Eine Aufnahme';

  @override
  String get searchAnEntry => 'Ein Eintrag';

  @override
  String get sizeThisOne => 'das hier';

  @override
  String get sizeTheseOnes => 'diese hier';

  @override
  String get passcodeOneMoreCharacter => 'Noch ein Zeichen.';

  @override
  String passcodeMoreCharacters(int count, int minimum) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Zeichen — $minimum sind das Minimum.',
      one: 'Noch 1 Zeichen — $minimum sind das Minimum.',
    );
    return '$_temp0';
  }

  @override
  String get passcodeTooObvious =>
      'Das ist eines der Ersten, was jeder ausprobieren würde. Nimm etwas anderes.';

  @override
  String get passcodeSameCharacter => 'Das ist dasselbe Zeichen wiederholt.';

  @override
  String get passcodeStraightRun => 'Das ist eine fortlaufende Zeichenfolge.';

  @override
  String attachmentLoading(String time) {
    return 'Anhang um $time, wird geladen';
  }

  @override
  String videoSemantic(String time, String length) {
    return 'Video um $time, $length. Zum Ansehen doppeltippen.';
  }

  @override
  String voiceSemantic(String time, String length) {
    return 'Sprachnotiz um $time, $length. Zum Abspielen doppeltippen.';
  }

  @override
  String fileSemantic(String time, String name, String size) {
    return 'Datei um $time, $name, $size. Zum Öffnen doppeltippen.';
  }

  @override
  String get lengthUnknown => 'Länge unbekannt';

  @override
  String get settingsLockNone => 'keine automatische Sperre';

  @override
  String settingsLockAfter(String duration) {
    return 'nach $duration';
  }

  @override
  String settingsSecuritySummary(String lock) {
    return 'Code, Fingerabdruck, $lock';
  }

  @override
  String get keptNoNetworkTitle => 'Es verlässt dieses Gerät nie';

  @override
  String get keptNoNetworkBody =>
      'Lamplight kann das Internet nicht nutzen. Nicht „tut es nicht“ — kann nicht: Android verweigert ihm die Berechtigung, und du kannst das in den App-Einstellungen deines Telefons in etwa dreißig Sekunden selbst nachprüfen.';

  @override
  String get keptPasscodeTitle => 'Dein Code ist der Schlüssel';

  @override
  String get keptPasscodeBody =>
      'Der Schlüssel, der deine Notizen öffnet, wird bei jedem Entsperren aus deinem Code erzeugt. Er wird nirgends gespeichert, es gibt also keine Kopie, die man finden, verlieren oder herausgeben könnte.';

  @override
  String get keptForgetTitle => 'Wenn du ihn vergisst';

  @override
  String get keptForgetBody =>
      'Deine zwölf Wörter sind der einzige andere Weg hinein. Hier kann niemand einen Code zurücksetzen, und das ist dieselbe Tatsache wie oben — eine App, die dich wieder hineinlassen könnte, könnte auch jemand anderen hineinlassen.';

  @override
  String get keptNothingReadableTitle =>
      'Nichts Lesbares bleibt irgendwo liegen';

  @override
  String get keptNothingReadableBody =>
      'Fotos, Aufnahmen und Dateien werden verschlüsselt, bevor sie den Speicher berühren. Nichts wird jemals im Klartext geschrieben, nicht einmal kurz, während du es ansiehst.';

  @override
  String get keptLocksItselfTitle => 'Es sperrt sich selbst';

  @override
  String get keptLocksItselfBody =>
      'In dem Moment, in dem Lamplight in den Hintergrund geht, werden die Schlüssel vernichtet. Screenshots sind blockiert, und die App erscheint nicht in der Vorschau der letzten Apps.';

  @override
  String get keptBackUpTitle => 'Sichere es';

  @override
  String get keptBackUpBody =>
      'Alles liegt auf diesem Telefon und sonst nirgends — das ist der Sinn der Sache und zugleich das Risiko. Eine Sicherung ist eine einzige verschlüsselte Datei, die nur dein Code öffnet. Bewahre eine irgendwo auf.';
}
