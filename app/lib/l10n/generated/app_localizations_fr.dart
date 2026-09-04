// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class LFr extends L {
  LFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Lamplight';

  @override
  String get lockTypePasscode => 'Saisis ton code.';

  @override
  String get lockWrongPasscode => 'Cela n’a pas ouvert le coffre.';

  @override
  String get lockCheckAndRetry => 'Vérifie le code et réessaie.';

  @override
  String get lockForgot => 'J’ai oublié mon code';

  @override
  String get lockTypeTwelveWords => 'Saisis tes douze mots.';

  @override
  String get lockUsePasscodeInstead => 'Utiliser plutôt mon code';

  @override
  String get lockUseFingerprint => 'Utiliser ton empreinte';

  @override
  String get lockFingerprintFailed => 'L’empreinte n’a pas fonctionné.';

  @override
  String get lockFingerprintUnavailable => 'L’empreinte n’est pas disponible.';

  @override
  String get lockOpening => 'Ouverture…';

  @override
  String get lockNothingDeleted => 'Rien n’a été supprimé, et rien ne le sera.';

  @override
  String lockTryAgainSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Réessaie dans $count secondes.',
      one: 'Réessaie dans une seconde.',
    );
    return '$_temp0';
  }

  @override
  String lockTryAgainMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Réessaie dans $count minutes.',
      one: 'Réessaie dans une minute.',
    );
    return '$_temp0';
  }

  @override
  String get dayToday => 'AUJOURD’HUI';

  @override
  String get dayPrevious => 'Le jour d’avant';

  @override
  String get dayNext => 'Le jour d’après';

  @override
  String get daySearch => 'Rechercher';

  @override
  String get daySettings => 'Réglages';

  @override
  String get dayChooseDate => 'Choisir une autre date.';

  @override
  String get dayEmptyToday => 'Quelque chose que tu veux garder ?';

  @override
  String get dayEmptyPast => 'Rien ce jour-là.';

  @override
  String get dayWriteSomething => 'Écrire quelque chose pour aujourd’hui';

  @override
  String get dayLineAsk => 'C’était quoi, cette journée ?';

  @override
  String get dayLineHint => 'C’était quoi, cette journée ?';

  @override
  String get dayLineSemantic => 'Dis en une ligne ce qu’était cette journée';

  @override
  String dayLineChange(String note) {
    return 'Ce jour : $note. Modifier.';
  }

  @override
  String get dayEndOfDay => 'La fin de la journée';

  @override
  String get dayStartOfDay => 'Le début de la journée';

  @override
  String get firstPageTitle =>
      'C’est vide parce que tu n’y as encore rien écrit.';

  @override
  String get firstPageShelves =>
      'Les jours sont les étagères. Ce que tu gardes se pose sur le jour où c’est arrivé, et y reste.';

  @override
  String get firstPageWayWrite => 'Touche cette page pour écrire.';

  @override
  String get firstPageWayVoice => 'Maintiens le micro pour le dire à la place.';

  @override
  String get firstPageWayAttach =>
      'Ajoute une photographie, une vidéo ou un document.';

  @override
  String get firstPagePromise => 'Rien de tout cela ne quitte ce téléphone.';

  @override
  String get firstPageSemantic => 'Écris la première chose dans ton journal';

  @override
  String get captureVoice => 'Enregistrer une note vocale';

  @override
  String get capturePhoto => 'Prendre ou choisir une photo';

  @override
  String get captureFile => 'Joindre un fichier';

  @override
  String get backupNeverMade =>
      'Rien de tout cela n’est sauvegardé. Si cette application est supprimée, tes notes partent avec elle.';

  @override
  String get backupStale => 'La dernière sauvegarde date un peu.';

  @override
  String get backupOutOfDate =>
      'Ta sauvegarde s’ouvre encore avec ton ancien code.';

  @override
  String get backupAction => 'Sauvegarder';

  @override
  String folderAlsoIn(String name) {
    return 'Aussi dans $name. Ouvrir le dossier.';
  }

  @override
  String get folderStaysHere =>
      'Cela reste où c’est. Un dossier est un deuxième endroit où le retrouver.';

  @override
  String get folderAddTo => 'Ajouter à un dossier';

  @override
  String get folderNew => 'Nouveau dossier';

  @override
  String get folderNoneYet =>
      'Pas encore de dossiers. Un par personne, ou par période — ce vers quoi tu reviens.';

  @override
  String folderLesson(String day, String folder) {
    return 'Toujours au $day. Aussi dans $folder.';
  }

  @override
  String get actionDone => 'Terminé';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionEdit => 'Modifier';

  @override
  String get actionUndo => 'Annuler l’action';

  @override
  String get actionOpen => 'Ouvrir';

  @override
  String get actionRemove => 'Retirer';

  @override
  String get actionNotNow => 'Pas maintenant';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsSecurity => 'Verrouillage et sécurité';

  @override
  String get settingsYourNotes => 'Tes notes';

  @override
  String get settingsBackup => 'Sauvegarde';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageNote =>
      'Les mots qu’emploie l’application. Ce que tu écris est à toi, dans n’importe quelle langue, quel que soit ce réglage.';

  @override
  String get settingsLanguageSystem => 'Suivre le téléphone';

  @override
  String get entryMattered => 'Ça, ça comptait';

  @override
  String get entryMarked => 'Marquée comme une qui comptait.';

  @override
  String get entryMarkRemoved => 'Marque retirée.';

  @override
  String get entryDeleted => 'Supprimé.';

  @override
  String entryEarlierVersions(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versions antérieures',
      one: 'Une version antérieure',
    );
    return '$_temp0';
  }

  @override
  String get entryKeepsWords => 'Garde les mots';

  @override
  String entryKindInTrash(Object kind) {
    return 'Le $kind est dans la corbeille.';
  }

  @override
  String entryKindInTrashWords(Object kind) {
    return 'Le $kind est dans la corbeille. Les mots sont toujours là.';
  }

  @override
  String trashConfirmBody(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count notes, et toutes leurs versions antérieures. C’est sans retour.',
      one: 'Une note, et toutes ses versions antérieures. C’est sans retour.',
    );
    return '$_temp0';
  }

  @override
  String get trashEmptyEntry => 'Note vide';

  @override
  String get kindPhoto => 'Photo';

  @override
  String get kindVideo => 'Vidéo';

  @override
  String get kindRecording => 'Enregistrement';

  @override
  String get kindFile => 'Fichier';

  @override
  String get entryNoLongerMarked => 'Plus marqué';

  @override
  String get entryFindAgain => 'Retrouve-le depuis la recherche';

  @override
  String get searchGoTo => 'Aller à';

  @override
  String get searchFolders => 'Dossiers';

  @override
  String get searchEntriesOne => '1 entrée';

  @override
  String searchEntriesMany(int count) {
    return '$count entrées';
  }

  @override
  String get searchNothingFound => 'Rien ne correspond.';

  @override
  String get searchEverythingInstead => 'Chercher dans tout';

  @override
  String get searchNoneOfThese => 'Rien de ce genre pour l\'instant.';

  @override
  String get onboardNoAccount => 'Il n’y a pas de compte.';

  @override
  String get onboardPromiseBody =>
      'Tes notes restent sur ce téléphone.\nNous n’avons pas de serveur. Nous ne pouvons pas les lire.\nNous ne pouvons pas les récupérer non plus.';

  @override
  String get onboardBegin => 'Commencer';

  @override
  String get onboardHaveBackup => 'J’ai une sauvegarde';

  @override
  String get onboardSetPasscode => 'Définis un code';

  @override
  String get onboardPasscodeBody =>
      'C’est la seule chose qui ouvre tes notes. Une phrase dont tu te souviens est plus solide que quatre chiffres.';

  @override
  String get onboardPasscodeLabel => 'Code';

  @override
  String get onboardPasscodeAgain => 'Saisis-le à nouveau';

  @override
  String get onboardSettingUp => 'Préparation…';

  @override
  String get onboardContinue => 'Continuer';

  @override
  String get onboardPasscodesDiffer => 'Ces deux-là ne correspondent pas.';

  @override
  String get onboardVaultFailed => 'Ton coffre n’a pas pu être créé.';

  @override
  String get onboardVaultFailedThen =>
      'Rien n’a été enregistré. Essaie encore une fois.';

  @override
  String get onboardWriteWords => 'Écris ces douze mots\nsur du papier';

  @override
  String get onboardWordsBody =>
      'Nous n’en avons pas de copie. Nous ne pouvons pas te les envoyer. Il n’existe aucune adresse d’assistance qui puisse t’aider.\n\nPas une capture d’écran — du papier. Une capture reste dans ta galerie, et c’est le premier endroit où l’on regarde.';

  @override
  String get onboardWrittenDown => 'Je les ai écrits';

  @override
  String get onboardCopyWords => 'Copier les douze mots';

  @override
  String get onboardClipboardNote =>
      'Le presse-papiers s’efface tout seul au bout d’une minute. D’ici là, d’autres applications peuvent le lire.';

  @override
  String get onboardCopied =>
      'Copié. Cela s’efface tout seul dans une minute — colle-le maintenant dans un endroit sûr.';

  @override
  String get onboardCopyFailed =>
      'Cela n’a pas pu être copié. Les écrire à la main est de toute façon plus sûr.';

  @override
  String get onboardCheckThree => 'Vérifie-en trois';

  @override
  String get onboardCheckBody =>
      'Comme ça nous savons que le papier est juste, pas l’écran.';

  @override
  String onboardWordNumber(int number) {
    return 'Mot $number';
  }

  @override
  String onboardWordWrong(int number) {
    return 'Le mot $number n’est pas le bon. Regarde ce que tu as écrit.';
  }

  @override
  String get onboardShowWords => 'Montre-moi les mots à nouveau';

  @override
  String get onboardFingerprintTitle => 'L’ouvrir avec ton empreinte ?';

  @override
  String get onboardFingerprintBody =>
      'Comme ça tu n’as pas à saisir cette phrase à chaque fois.';

  @override
  String get onboardFingerprintExplain =>
      'Ta phrase reste la clé. L’empreinte n’ouvre que ce coffre, seulement sur ce téléphone, et Android la désactive de lui-même si les empreintes du téléphone changent — pour que personne ne puisse ajouter la sienne et entrer. Elle ne fait jamais partie d’une sauvegarde.';

  @override
  String get onboardFingerprintWaiting => 'En attente de ton doigt…';

  @override
  String get onboardFingerprintUse => 'Utiliser mon empreinte';

  @override
  String get onboardFingerprintFailed => 'Cela n’a pas fonctionné.';

  @override
  String get onboardFingerprintVaultShut =>
      'Lamplight a refermé le coffre pendant votre absence. Votre code l’ouvre toujours, et vous pourrez activer l’empreinte plus tard dans les Réglages.';

  @override
  String get onboardOneLastThing => 'Une dernière chose';

  @override
  String get onboardNameBody =>
      'Comment Lamplight doit-il t’appeler ? Cela reste sur ce téléphone, et tu peux le changer ou le laisser vide.';

  @override
  String get onboardFingerprintOn =>
      'Ton empreinte ouvrira Lamplight désormais.';

  @override
  String get onboardYourName => 'Ton nom';

  @override
  String get onboardStartWriting => 'Commencer à écrire';

  @override
  String get onboardSkip => 'Passer';

  @override
  String get settingsGroupLook => 'Son allure et sa langue';

  @override
  String get settingsGroupWhoCanOpen => 'Qui peut l’ouvrir';

  @override
  String get settingsGroupKeeping => 'Le garder, et l’emporter';

  @override
  String get settingsAppearanceNote => 'Thème, police, couleur, page';

  @override
  String get settingsFolders => 'Dossiers';

  @override
  String get settingsFoldersNote => 'Personnes, lieux, périodes';

  @override
  String get settingsMedia => 'Médias';

  @override
  String get settingsMediaNote => 'Photos, vidéo, son et documents';

  @override
  String get mediaGroupDocuments => 'Documents';

  @override
  String get mediaDocumentsKept =>
      'Conservés exactement tels qu\'ils sont arrivés';

  @override
  String get mediaDocumentsFooter =>
      'Un PDF ou un fichier Word est déjà compressé à l\'intérieur : le compresser à nouveau ne gagne qu\'environ cinq pour cent. Pour que cela change vraiment, il faudrait ré-encoder les images qu\'il contient, ce qui rend définitivement floues les petites lettres d\'un scan — et vous ne le découvririez que des années plus tard, le jour où vous auriez besoin de le lire.';

  @override
  String get settingsTrash => 'Corbeille';

  @override
  String get settingsTrashNote => 'Entrées supprimées, gardées 30 jours';

  @override
  String get settingsReadableCopy => 'Copie lisible';

  @override
  String get settingsReadableCopyNote =>
      'Markdown et tes fichiers, dans un dossier que tu choisis';

  @override
  String get settingsBringIn => 'Reprendre un ancien journal';

  @override
  String get settingsBringInNote =>
      'Des fichiers texte d’une autre application, classés par leur date';

  @override
  String get settingsKeepingFooter =>
      'Une sauvegarde est fermée avec ton code, exactement comme le coffre. Une copie lisible n’est pas fermée du tout — ce sont de simples fichiers dans un dossier que tu choisis.';

  @override
  String get backupNever => 'Jamais sauvegardé';

  @override
  String get backupToday => 'Sauvegardé aujourd’hui';

  @override
  String get backupYesterday => 'Sauvegardé hier';

  @override
  String backupDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sauvegardé il y a $count jours',
    );
    return '$_temp0';
  }

  @override
  String get mediaGroupIncoming => 'À l’arrivée';

  @override
  String get mediaGroupVoice => 'Notes vocales';

  @override
  String get mediaIncomingFooter =>
      'Lamplight ne garde jamais une seconde copie plus petite — ce que tu choisis ici est ce qui est conservé, et l’original ne reste nulle part ailleurs.';

  @override
  String get mediaVoiceFooter =>
      'La transcription se fait sur ce téléphone, avec la reconnaissance vocale qu’Android possède déjà. Rien de ce que tu dis à Lamplight n’est envoyé où que ce soit, et l’application n’a pas la permission de l’envoyer.';

  @override
  String get mediaPhotoSize => 'Taille des photos';

  @override
  String get mediaVideoSize => 'Taille des vidéos';

  @override
  String get mediaAskEachTime => 'Demander à chaque fois';

  @override
  String get accentAmber => 'Ambre';

  @override
  String get accentAmberNote => 'Une lampe la nuit. Celui par défaut.';

  @override
  String get accentRose => 'Rose';

  @override
  String get accentRoseNote => 'Rose chaud. Plus doux que l’ambre.';

  @override
  String get accentSage => 'Sauge';

  @override
  String get accentSageNote => 'Vert tranquille. Le plus paisible des six.';

  @override
  String get accentSlate => 'Ardoise';

  @override
  String get accentSlateNote => 'Gris-bleu froid. Le plus neutre.';

  @override
  String get accentPlum => 'Prune';

  @override
  String get accentPlumNote => 'Violet profond.';

  @override
  String get accentEmber => 'Braise';

  @override
  String get accentEmberNote => 'Orange brûlé. Le plus chaud.';

  @override
  String get surfacePlain => 'Unie';

  @override
  String get surfacePlainNote => 'Une page lisse.';

  @override
  String get surfacePaper => 'Papier';

  @override
  String get surfacePaperNote =>
      'Un grain léger, pour que la page ait l’air d’une matière. Celle par défaut.';

  @override
  String get surfaceLamplit => 'Sous la lampe';

  @override
  String get surfaceLamplitNote => 'Du papier, la lampe allumée.';

  @override
  String get surfaceStarMap => 'Carte du ciel';

  @override
  String get surfaceStarMapNote =>
      'Un seul ciel, qui tourne avec l’horloge. Jamais deux fois le même dans une journée.';

  @override
  String get rulingNone => 'Rien';

  @override
  String get rulingNoneNote => 'Rien d’imprimé sur la page.';

  @override
  String get rulingLines => 'Lignes';

  @override
  String get rulingLinesNote => 'Réglée comme un cahier.';

  @override
  String get rulingIsometric => 'Isométrique';

  @override
  String get rulingIsometricNote =>
      'Du papier à dessin, pour penser en trois dimensions.';

  @override
  String get rulingTriangle => 'Triangles';

  @override
  String get rulingTriangleNote => 'Un champ de triangles équilatéraux.';

  @override
  String get rulingDots => 'Grille de points';

  @override
  String get rulingDotsNote =>
      'Un point à chaque croisement. La plus discrète des quatre.';

  @override
  String get faceSystem => 'Système';

  @override
  String get faceSystemNote => 'Celle qu’utilise le reste de ton téléphone.';

  @override
  String get faceSerif => 'Serif du système';

  @override
  String get faceSerifNote => 'La serif propre à ton téléphone.';

  @override
  String get faceCalmNote => 'Bords doux, lettres larges.';

  @override
  String get faceModernNote => 'Serrée et actuelle.';

  @override
  String get faceOldStyleNote => 'Un caractère de livre du XVIe siècle.';

  @override
  String get facePlayfulNote => 'Ronde et gaie.';

  @override
  String get faceChildlikeNote => 'Un cahier d’écolier.';

  @override
  String get faceHandwrittenNote =>
      'Une écriture à la main, lisible même sur toute une page.';

  @override
  String get faceMedievalNote => 'La main d’un copiste. Une seule graisse.';

  @override
  String get faceMonoNote => 'Toutes les lettres de la même largeur.';

  @override
  String get qualityOriginal => 'Garder l’original';

  @override
  String get qualityBalanced => 'Équilibré';

  @override
  String get qualitySmaller => 'Plus petit';

  @override
  String get photoOriginalNote =>
      'Gardée exactement comme ton appareil l’a prise. Les fichiers les plus lourds — et ils conservent le lieu de la photo, que Lamplight retire d’habitude.';

  @override
  String get photoBalancedNote =>
      'Bien plus léger, et difficile à distinguer de l’original. Le choix par défaut.';

  @override
  String get photoSmallerNote =>
      'Encore moitié moins. Tu peux le voir en recadrant de très près.';

  @override
  String get videoOriginalNote =>
      'Gardée exactement comme ton appareil l’a filmée. De loin les fichiers les plus lourds.';

  @override
  String get videoBalancedNote =>
      'Bien plus léger, et difficile à distinguer de l’original. Le choix par défaut.';

  @override
  String get videoSmallerNote =>
      'Encore moitié moins. Tu peux le voir sur un grand écran.';

  @override
  String get appearanceTitle => 'Apparence';

  @override
  String get appearanceTheme => 'Thème';

  @override
  String get appearanceThemeDark => 'Sombre';

  @override
  String get appearanceThemeLight => 'Clair';

  @override
  String get appearanceThemeAuto => 'Système';

  @override
  String get appearanceThemeAutoNote =>
      'Suit le réglage clair ou sombre de ton téléphone.';

  @override
  String get appearanceFont => 'Police';

  @override
  String get appearanceSize => 'Taille';

  @override
  String get appearanceColour => 'Couleur';

  @override
  String get appearancePage => 'Page';

  @override
  String get appearanceRuling => 'Réglure';

  @override
  String get daySavedToToday => 'Enregistré sur aujourd’hui.';

  @override
  String get dayAddedToToday => 'Ajouté à aujourd’hui.';

  @override
  String get entryEditWords => 'Modifier le texte';

  @override
  String get entryDeleteBlock => 'Supprimer tout le bloc';

  @override
  String entrySavedAs(String name) {
    return 'Enregistré sous $name.';
  }

  @override
  String entryAddedToFolder(String name) {
    return 'Aussi dans $name.';
  }

  @override
  String get entrySaveCopy => 'Enregistrer une copie';

  @override
  String get entrySaveCopyNote => 'Là où tu veux, en dehors de Lamplight';

  @override
  String get capturePhotoTake => 'Prendre une photo';

  @override
  String get capturePhotoChoose => 'Choisir parmi tes photos';

  @override
  String get composerHintToday => 'Écris sur aujourd’hui…';

  @override
  String get composerHintPast => 'Écris sur cette journée…';

  @override
  String get composerNewBlock => 'Nouveau bloc';

  @override
  String get voiceShowTranscript => 'Montrer ce qui a été dit';

  @override
  String get voiceHideTranscript => 'Masquer ce qui a été dit';

  @override
  String get voiceTranscriptTitle => 'Ce qui a été dit';

  @override
  String get entryEdited => ', modifié';

  @override
  String photoSemantic(String time) {
    return 'Photo de $time. Touche deux fois pour la voir.';
  }

  @override
  String get sizeThisPhoto => 'cette photo';

  @override
  String get sizeThesePhotos => 'ces photos';

  @override
  String get sizeThisVideo => 'cette vidéo';

  @override
  String get sizeTheseVideos => 'ces vidéos';

  @override
  String sizeQuestion(String what) {
    return 'Quelle taille garder pour $what ?';
  }

  @override
  String get trashNote =>
      'Ce qui est supprimé reste ici 30 jours, puis s’en va pour de bon.';

  @override
  String get trashConfirm => 'Supprimer cela définitivement ?';

  @override
  String get trashKeep => 'Les garder';

  @override
  String get trashDeleteForGood => 'Supprimer définitivement';

  @override
  String get trashPutBack => 'Remettre';

  @override
  String trashPutBackOn(String day) {
    return 'Remis au $day.';
  }

  @override
  String get trashEmpty => 'Vider la corbeille';

  @override
  String get folderMakeFirst => 'Créer le premier';

  @override
  String folderDeleteAsk(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get folderKeepIt => 'Le garder';

  @override
  String get folderDeleteIt => 'Supprimer le dossier';

  @override
  String get folderRename => 'Renommer';

  @override
  String get folderDeleteThis => 'Supprimer ce dossier';

  @override
  String folderTakenOut(String name) {
    return 'Retiré de $name. C’est toujours sur sa journée.';
  }

  @override
  String get searchHint => 'Des mots, une date, un nom…';

  @override
  String get searchBack => 'Retour';

  @override
  String get searchClear => 'Effacer';

  @override
  String searchNothingMatches(String query) {
    return 'Rien ne correspond à « $query ».';
  }

  @override
  String get searchWhatMattered => 'CE QUI A COMPTÉ';

  @override
  String get searchADate => 'Une date';

  @override
  String get searchDateExample => '16 mars 2006 · mars 2006 · hier';

  @override
  String get searchWhatYouCanType => 'Ce que vous pouvez chercher';

  @override
  String get searchTryDate => 'hier';

  @override
  String get searchSaidOutLoud => 'dit à voix haute';

  @override
  String get searchAPhotograph => 'Une photo';

  @override
  String get searchAVideo => 'Une vidéo';

  @override
  String get securityWhileOpen => 'Pendant que l’application est ouverte';

  @override
  String get securityLockFooter =>
      'Lamplight se verrouille toujours dès qu’il passe en arrière-plan. Ceci ne règle que le temps d’attente pendant que tu es encore dedans.';

  @override
  String get securityLockAfter => 'Verrouiller après';

  @override
  String get securityOneHour => '1 heure';

  @override
  String get securityYourPasscode => 'Ton code';

  @override
  String get securityPasscodeFooter =>
      'Ton code est la clé. Il n’est enregistré nulle part — ni sur ce téléphone ni ailleurs — donc personne ne peut être forcé de le donner, et personne ne peut le retrouver à ta place.';

  @override
  String get securityChangePasscode => 'Changer le code';

  @override
  String get securityScreenshots => 'Captures d’écran';

  @override
  String get securityScreenshotsFooter =>
      'Lamplight bloque les captures d’écran pour que celui qui prend ton téléphone ne puisse pas photographier tes notes, et pour qu’elles n’apparaissent jamais dans l’aperçu des applications récentes. Tu peux désactiver cela pour ton propre téléphone.';

  @override
  String get securityAllowScreenshots => 'Autoriser les captures d’écran';

  @override
  String get securityScreenshotsOn =>
      'Vos notes apparaîtront dans les applis récentes';

  @override
  String get securityScreenshotsOff =>
      'Les applis récentes affichent une page vide';

  @override
  String get securityCouldNotChange => 'Cela n’a pas pu être modifié.';

  @override
  String get securityNothingChanged =>
      'Rien n’a changé dans votre verrouillage.';

  @override
  String get securityPromptAutomatic => 'La demande apparaît d’elle-même';

  @override
  String get securityPromptOnTap =>
      'Touchez l’empreinte quand vous le souhaitez';

  @override
  String get mediaAskEachTimeOn =>
      'On vous demande quelle taille garder pour les photos et vidéos au moment de les ajouter.';

  @override
  String get mediaAskEachTimeOff =>
      'Désactivé. Les deux tailles ci-dessus sont utilisées sans demander.';

  @override
  String get passcodeNew => 'Nouveau code';

  @override
  String get securityFingerprint => 'Empreinte';

  @override
  String get securityFingerprintFooter =>
      'Ta phrase reste la clé. L’empreinte n’ouvre que ce coffre, seulement sur ce téléphone, et Android la désactive de lui-même si les empreintes du téléphone changent — pour que personne ne puisse ajouter la sienne et entrer. Elle ne fait jamais partie d’une sauvegarde.';

  @override
  String get securityUnlockWithFingerprint => 'Ouvrir avec mon empreinte';

  @override
  String get securityAskOnOpen => 'Demander dès l’ouverture de Lamplight';

  @override
  String durationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count secondes',
      one: '1 seconde',
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
      other: '$count heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String get durationNever => 'Jamais';

  @override
  String get securityDefaultNote => 'Le choix par défaut.';

  @override
  String get securityHourNote => 'Pour un après-midi de relecture.';

  @override
  String get securityNeverNote =>
      'Il se verrouille quand même dès que tu quittes l’application.';

  @override
  String get calendarGoToDate => 'Aller à une date';

  @override
  String get dayHasWriting => 'de l’écriture';

  @override
  String get dayHasPhoto => 'une photo';

  @override
  String get dayHasVideo => 'une vidéo';

  @override
  String get dayHasVoice => 'une note vocale';

  @override
  String get dayHasFile => 'un fichier';

  @override
  String dayEntriesAndKinds(Object count, Object kinds) {
    return '$count, $kinds';
  }

  @override
  String get listSeparator => ', ';

  @override
  String listAnd(Object last, Object most) {
    return '$most et $last';
  }

  @override
  String get integrityNothingUnusual =>
      'Rien d’inhabituel sur ce téléphone. Lamplight tourne comme prévu.';

  @override
  String get calendarPreviousYear => 'Année précédente';

  @override
  String get calendarPreviousMonth => 'Mois précédent';

  @override
  String get calendarNextYear => 'Année suivante';

  @override
  String get calendarNextMonth => 'Mois suivant';

  @override
  String get calendarBackToMonth => 'Revenir au mois';

  @override
  String get calendarWholeYear => 'L’année entière';

  @override
  String get calendarBackToThisMonth => 'Revenir à ce mois-ci';

  @override
  String get calendarNothingThisYear => 'Rien encore sur cette année.';

  @override
  String calendarYearSummary(Object days, Object entries) {
    return '$entries sur $days.';
  }

  @override
  String get folderNothingInIt => 'Rien dedans pour l’instant';

  @override
  String get onThisDayOneYear => 'Il y a un an aujourd’hui';

  @override
  String onThisDayYears(Object years) {
    return 'Il y a $years ans aujourd’hui';
  }

  @override
  String wheelYear(Object year) {
    return 'Année $year';
  }

  @override
  String get calendarBackToBrowsing => 'Revenir au feuilletage';

  @override
  String get calendarToday => 'Aujourd’hui';

  @override
  String get calendarFirstEntry => 'Ta première entrée';

  @override
  String get calendarGoToThisDay => 'Aller à ce jour';

  @override
  String get calendarDensityNote =>
      'La couleur dit combien il y a sur une journée, de rien à beaucoup.';

  @override
  String get calendarLess => 'Moins';

  @override
  String get calendarMore => 'Plus';

  @override
  String get calendarGoToToday => 'Aller à aujourd’hui';

  @override
  String get backupTitle => 'Sauvegarde';

  @override
  String get vaultNothingToBackUp =>
      'Il n’y a encore rien à sauvegarder dans ce coffre.';

  @override
  String vaultChangedWhileBackingUp(Object name) {
    return 'Quelque chose a changé pendant la sauvegarde ($name). Réessayez.';
  }

  @override
  String get vaultTooSmall =>
      'Ce fichier est trop petit pour être une sauvegarde Lamplight.';

  @override
  String get vaultNotALamplightFile =>
      'Ce n’est pas un fichier de sauvegarde Lamplight.';

  @override
  String get vaultDamaged => 'Ce fichier est abîmé et ne peut pas être ouvert.';

  @override
  String get vaultKeyringNewerVersion =>
      'Ce coffre a été créé avec une version plus récente de Lamplight. Mettez l’application à jour pour l’ouvrir.';

  @override
  String get vaultKeyringDamaged =>
      'Le fichier de clé du coffre est abîmé et illisible. Si vous avez une sauvegarde, restaurez à partir d’elle.';

  @override
  String get vaultDatabaseNewerVersion =>
      'Ce coffre a été créé avec une version plus récente de Lamplight. Mettez l’application à jour pour l’ouvrir — vos notes sont intactes et rien n’a été modifié.';

  @override
  String phraseWrongLength(Object count) {
    return 'Une phrase de récupération compte 12 mots. Celle-ci en a $count.';
  }

  @override
  String phraseNotARecoveryWord(Object word) {
    return '« $word » ne fait pas partie des mots de récupération.';
  }

  @override
  String get phraseDoesNotCheckOut =>
      'Ces mots ne forment pas une phrase de récupération valide. Vérifiez s’il y a une faute de frappe ou deux mots intervertis.';

  @override
  String get vaultNewerVersion =>
      'Cette sauvegarde a été faite avec une version plus récente de Lamplight. Mettez l’application à jour, puis réessayez.';

  @override
  String get vaultUnknownCompression =>
      'Cette sauvegarde utilise une compression que cette version ne sait pas lire.';

  @override
  String get vaultDamagedTryOlder =>
      'Ce fichier est abîmé et ne peut pas être ouvert. Si vous avez une sauvegarde plus ancienne, essayez celle-là.';

  @override
  String get vaultBeforeRecoveryPhrases =>
      'Cette sauvegarde date d’avant que les phrases de récupération puissent ouvrir un fichier. Son code est le seul moyen d’entrer.';

  @override
  String get vaultWordsDoNotOpenIt =>
      'Ces mots n’ouvrent pas ce fichier. Ils appartiennent peut-être à un autre coffre.';

  @override
  String get vaultWrongPasscode => 'Ce code n’ouvre pas ce fichier.';

  @override
  String vaultMissingPart(Object name) {
    return 'Il manque une partie de cette sauvegarde ($name).';
  }

  @override
  String vaultPartWrongSize(Object name) {
    return 'Cette sauvegarde est abîmée ($name n’a pas la bonne taille).';
  }

  @override
  String vaultPartDoesNotMatch(Object name) {
    return 'Cette sauvegarde est abîmée ($name ne correspond pas).';
  }

  @override
  String get vaultNoVaultInside =>
      'Cette sauvegarde ne contient pas de coffre. Elle a peut-être été faite par une autre application.';

  @override
  String get vaultOutOfOrder =>
      'Ce fichier est abîmé : son contenu est dans le désordre.';

  @override
  String get vaultEndsPartWay =>
      'Ce fichier est abîmé : il s’arrête en plein milieu.';

  @override
  String vaultIncomplete(Object parts) {
    return 'Ce fichier est incomplet — il en contient $parts.';
  }

  @override
  String vaultWillNotOpen(Object name) {
    return 'Cette sauvegarde contient quelque chose que Lamplight n’ouvrira pas ($name).';
  }

  @override
  String countEntries(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String countDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get backupCheckingItOpens => 'Vérification qu’il s’ouvre…';

  @override
  String get backupCouldNotSave => 'La sauvegarde n’a pas pu être enregistrée.';

  @override
  String get backupNothingLost =>
      'Rien n’a été perdu et vos notes sont intactes. Réessayez dans un instant.';

  @override
  String get backupLast => 'Dernière sauvegarde';

  @override
  String get backupInTheVault => 'Dans le coffre';

  @override
  String get restoreCheckingFile => 'Vérification du fichier…';

  @override
  String get restoreCouldNotOpen => 'Ce fichier n’a pas pu être ouvert.';

  @override
  String get restoreCheckItIsTheOne =>
      'Vérifiez que c’est bien la sauvegarde voulue, puis réessayez.';

  @override
  String get restorePuttingInPlace => 'Mise en place…';

  @override
  String get restorePuttingBack => 'Remise en place de vos anciennes notes…';

  @override
  String get restoreCouldNotFinish =>
      'La restauration n’a pas pu être terminée.';

  @override
  String get restoreBackAsTheyWere => 'Vos notes sont revenues comme avant.';

  @override
  String get restoreUsePasscodeInstead => 'Utiliser le code à la place';

  @override
  String get restoreUseWordsInstead => 'J’ai plutôt les douze mots';

  @override
  String get backupCreateFile => 'Créer le fichier';

  @override
  String get backupCreatedChecked => 'Sauvegarde créée et vérifiée.';

  @override
  String get backupMakeAnother => 'En créer une autre';

  @override
  String get backupRestoreHeading => 'Restaurer';

  @override
  String get backupRestoreFrom => 'Restaurer depuis un fichier';

  @override
  String backupProgress(String stage, int percent) {
    return '$stage $percent pour cent';
  }

  @override
  String get restoreTitle => 'Restaurer';

  @override
  String get restoreChooseFile => 'Choisir un fichier';

  @override
  String get restoreUseLatest => 'Utiliser ma dernière sauvegarde';

  @override
  String get restorePhraseHint => 'souviens histoire industrie…';

  @override
  String get restoreAction => 'Restaurer';

  @override
  String get restoreChooseDifferent => 'Choisir un autre fichier';

  @override
  String get importChooseFolder => 'Choisir un dossier';

  @override
  String get importChooseFiles => 'Choisir les fichiers à la place';

  @override
  String get importChooseFilesNote =>
      'Si Android refuse votre dossier — il ne donne à aucune application le dossier Téléchargements ni la racine du stockage — choisissez les fichiers eux-mêmes. Cela n\'est jamais refusé.';

  @override
  String get importLooking => 'Regarde dans le dossier…';

  @override
  String get importNoTextFiles =>
      'Il n’y a aucun fichier texte dans ce dossier.';

  @override
  String get importChooseDifferentFolder => 'Choisir un autre dossier';

  @override
  String get importUseFileDate => 'Utiliser la date du fichier';

  @override
  String get importUseFileDateNote =>
      'Les place au jour où le fichier a été modifié pour la dernière fois. Ce n’est souvent pas le jour dont il parle.';

  @override
  String importBringIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reprendre $count notes',
      one: 'Reprendre 1 note',
    );
    return '$_temp0';
  }

  @override
  String importProgress(int percent) {
    return 'Reprise, $percent pour cent';
  }

  @override
  String get exportChooseFolder => 'Choisir un dossier et exporter';

  @override
  String get exportSave => 'Enregistrer une copie lisible';

  @override
  String get exportWritten => 'Ta copie est écrite.';

  @override
  String get exportAgain => 'Exporter à nouveau';

  @override
  String get exportWhichOne => 'Laquelle me faut-il ?';

  @override
  String get exportNotLocked => 'Cette copie n’est pas fermée';

  @override
  String dayAddedThings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count choses ajoutées à aujourd’hui.',
    );
    return '$_temp0';
  }

  @override
  String get entryAddNote => 'Ajouter une note à ceci';

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ajoutés.',
      one: 'Ajouté.',
    );
    return '$_temp0';
  }

  @override
  String get importFolderUnreadable => 'Ce dossier n’a pas pu être lu.';

  @override
  String get importNothingBrought => 'Rien n’a été importé.';

  @override
  String get importStoppedPartWay =>
      'L’importation du journal s’est arrêtée en chemin.';

  @override
  String get importWhatArrivedKept =>
      'Tout ce qui était arrivé avant l’arrêt a été conservé.';

  @override
  String get importNoReadableDates =>
      'Aucun de ces fichiers n’a une date que Lamplight sait lire.';

  @override
  String importReadyToBring(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes prêtes à être importées.',
      one: '1 note prête à être importée.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingNew => 'Rien de nouveau à importer.';

  @override
  String importBroughtIn(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes importées.',
      one: '1 note importée.',
    );
    return '$_temp0';
  }

  @override
  String importAlreadyHere(Object count) {
    return '$count étaient déjà là et ont été laissées telles quelles.';
  }

  @override
  String importNoDateSkipped(Object count) {
    return '$count n’avaient aucune date lisible et ont été ignorées.';
  }

  @override
  String importCouldNotRead(Object count, Object names) {
    return '$count n’ont pas pu être lues : $names';
  }

  @override
  String get exportStarting => 'Démarrage…';

  @override
  String get exportCouldNotFinish =>
      'La copie lisible n’a pas pu être terminée.';

  @override
  String get exportNothingChanged => 'Rien n’a changé dans Lamplight.';

  @override
  String get importVideoAlreadySmall =>
      'Une vidéo était déjà aussi petite que possible, elle a donc été gardée telle quelle.';

  @override
  String get importVideoCouldNotShrink =>
      'Une vidéo n’a pas pu être réduite sur ce téléphone, elle a donc été gardée entière.';

  @override
  String importOneFailed(String reason) {
    return 'Un n’a pas fonctionné : $reason';
  }

  @override
  String importAbandoned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count n’ont pas fini avant que Lamplight ne se verrouille.',
      one: 'Un n’a pas fini avant que Lamplight ne se verrouille.',
    );
    return '$_temp0';
  }

  @override
  String get importNothingLeft => 'Rien n’est resté sur le téléphone.';

  @override
  String get nameCardAsk => 'Qu’est-ce qui doit être écrit ici ?';

  @override
  String get nameCardHint => 'Ton nom, ou ce que tu veux';

  @override
  String get reminderGroup => 'Un petit rappel, si tu en veux un';

  @override
  String get reminderFooter =>
      'Éteint tant que tu ne l’allumes pas. Il ne mentionne jamais ce qu’il y a dans tes notes — il ne peut pas, puisqu’il tourne pendant que le coffre est fermé. Pas de séries, pas de comptes, rien sur les jours que tu as sautés.';

  @override
  String get reminderTitle => 'Me rappeler d’écrire';

  @override
  String get reminderWhen => 'Quand';

  @override
  String get reminderProblemNotAllowed =>
      'Lamplight n’est pas autorisé à envoyer des notifications.';

  @override
  String get reminderProblemNotificationsOff =>
      'Les réglages de ce téléphone ont désactivé les notifications de Lamplight.';

  @override
  String get reminderProblemRemindersOff =>
      'Les rappels de Lamplight sont désactivés dans les réglages de notifications de ce téléphone.';

  @override
  String get reminderProblemBatterySaving =>
      'Ce téléphone économise la batterie en retenant Lamplight. C’est la raison habituelle pour laquelle un rappel arrive tard ou n’arrive jamais.';

  @override
  String get reminderMayNotArrive => 'Le rappel n’arrivera peut-être pas';

  @override
  String get backupAutomatic => 'Sauvegarder tout seul';

  @override
  String get backupAutomaticDidNotFinish =>
      'La sauvegarde automatique ne s’est pas terminée.';

  @override
  String get backupNothingYet => 'Rien à sauvegarder pour l’instant.';

  @override
  String get backupInProgress => 'Sauvegarde en cours…';

  @override
  String get backupStartsAtUnlock => 'Démarre au prochain déverrouillage.';

  @override
  String get backupDoneAutomatically => 'Sauvegardé automatiquement.';

  @override
  String get backupLastOneFailed =>
      'La dernière sauvegarde automatique ne s’est pas terminée. Elle réessaiera à la prochaine ouverture de Lamplight.';

  @override
  String importNthOf(Object index, Object total) {
    return '$index sur $total';
  }

  @override
  String importWaiting(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en attente',
      one: '1 en attente',
    );
    return '$_temp0';
  }

  @override
  String get aboutCopied => 'Copié';

  @override
  String get failureGeneric => 'Cela n’a pas marché.';

  @override
  String get failureNothingLost => 'Rien n’a été perdu — réessayez.';

  @override
  String get calendarNothingOnDay => 'rien';

  @override
  String get backupChangeFolder => 'Changer de dossier';

  @override
  String backupSavedTo(String place) {
    return 'Enregistré dans $place';
  }

  @override
  String get backupUseDefaultFolder => 'Utiliser le dossier habituel';

  @override
  String get backupChooseFolder => 'Choisissez un dossier où garder les copies';

  @override
  String get folderAndroidRestriction =>
      'Android ne donne à aucune application le dossier Téléchargements ni l’ensemble du stockage interne. Documents, ou un dossier à l’intérieur, fonctionne.';

  @override
  String get folderNotWritable =>
      'Rien ne peut être enregistré dans ce dossier. Essayez-en un autre.';

  @override
  String get folderRefused => 'Ce dossier n’a pas pu être utilisé.';

  @override
  String get folderTryAnother => 'Essayez d’en choisir un autre.';

  @override
  String get aboutHowKept => 'Comment tes notes sont gardées';

  @override
  String get aboutFonts => 'Polices et licences';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutNoBrowser =>
      'Aucune application de ce téléphone ne peut ouvrir de liens.';

  @override
  String get aboutMadeBy => 'Fait par';

  @override
  String get aboutMadeBySemantic =>
      'Fait par ProbablyPiyush. Ouvre LinkedIn dans ton navigateur.';

  @override
  String get aboutCoffee => 'Offre-moi un café';

  @override
  String get aboutCoffeeSemantic =>
      'Offre-moi un café. Ouvre une page dans ton navigateur.';

  @override
  String get aboutCopyDetails => 'Copier les détails';

  @override
  String settingsNameSemantic(Object name) {
    return '$name. Touchez pour modifier.';
  }

  @override
  String get settingsAddName => 'Ajoutez votre nom';

  @override
  String get settingsNameOnlyHere => 'Seulement sur ce téléphone';

  @override
  String get settingsNameOptional =>
      'Facultatif. Jamais ailleurs que sur ce téléphone.';

  @override
  String get reminderTurnedOffByAndroid =>
      'Android a désactivé les notifications pour Lamplight. Vous pouvez les réactiver dans les réglages du téléphone, sous Applications.';

  @override
  String get reminderOnceADay => 'Une fois par jour';

  @override
  String reminderTodayAt(Object time) {
    return 'aujourd’hui à $time';
  }

  @override
  String reminderYesterdayAt(Object time) {
    return 'hier à $time';
  }

  @override
  String reminderOnDateAt(Object date, Object time) {
    return 'le $date à $time';
  }

  @override
  String get reminderNoneYet => 'Rien n’est encore arrivé';

  @override
  String reminderLastArrived(Object when) {
    return 'Le dernier est arrivé $when';
  }

  @override
  String reminderNextDue(Object when) {
    return 'Le prochain est prévu $when';
  }

  @override
  String get aboutHide => 'Masquer';

  @override
  String get aboutCheckReal => 'Vérifier que c’est bien le vrai Lamplight';

  @override
  String get entryRevisionsNote =>
      'Ce que cela disait avant que tu ne le changes';

  @override
  String get entryStaysOnDay => 'Cela reste aussi sur cette journée';

  @override
  String entryDeleteKind(String kind) {
    return 'Supprimer $kind';
  }

  @override
  String get shareCouldNotAdd =>
      'Cela n’a pas pu être ajouté. Essaie de l’enregistrer et d’utiliser le bouton photo.';

  @override
  String get openNothingCanOpen =>
      'Rien sur ce téléphone ne peut ouvrir ce type de fichier.';

  @override
  String get viewerMore => 'Plus';

  @override
  String get docLeavesLamplight => 'Cela quitte Lamplight';

  @override
  String get docKeepItHere => 'Le garder ici';

  @override
  String get docOpenWith => 'Ouvrir avec…';

  @override
  String docCannotShow(String kind) {
    return 'Lamplight peut montrer les PDF, les images et le texte sans jamais les poser en clair sur ton téléphone. Un fichier $kind a besoin d’une autre application — Lamplight peut la lui prêter le temps que tu lises, et la reprendre ensuite.';
  }

  @override
  String get menuOpenWithNote => 'Une autre application, sans laisser de copie';

  @override
  String menuSaveKind(String kind) {
    return 'Enregistrer $kind';
  }

  @override
  String get menuTrashNote => 'Gardé 30 jours, puis parti';

  @override
  String get videoBackTen => 'Dix secondes en arrière';

  @override
  String get videoForwardTen => 'Dix secondes en avant';

  @override
  String get photoPlayVideo => 'Lire cette vidéo';

  @override
  String get lockPhraseHint => 'Tes douze mots, avec des espaces';

  @override
  String get lockUnlock => 'Ouvrir';

  @override
  String get errorScreenDidNotOpen =>
      'Cet écran ne s’est pas ouvert. Rien n’a été perdu.';

  @override
  String get errorGoBack => 'Revenir';

  @override
  String recordingCannot(String what) {
    return 'Ce téléphone ne va pas $what un enregistrement. Il enregistre toujours.';
  }

  @override
  String get recordingClose => 'Fermer';

  @override
  String recordingElapsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enregistre, $count secondes',
      one: 'Enregistre, $count seconde',
    );
    return '$_temp0';
  }

  @override
  String get recordingStopKeep => 'Arrêter et garder cet enregistrement';

  @override
  String get recordingDiscard => 'Jeter';

  @override
  String get recordingCouldNotStart => 'L’enregistrement n’a pas pu démarrer.';

  @override
  String get recordingCheckMicrophone =>
      'Vérifiez que Lamplight a le droit d’utiliser le micro.';

  @override
  String get recordingStartAgain => 'reprendre';

  @override
  String get recordingCouldNotSave =>
      'Cet enregistrement n’a pas pu être conservé.';

  @override
  String get recordingStillHere =>
      'Il est toujours là — essayez de l’arrêter à nouveau.';

  @override
  String get recordingCarryOnSemantic => 'Continuer l’enregistrement';

  @override
  String get recordingPauseSemantic => 'Mettre l’enregistrement en pause';

  @override
  String get recordingCarryOn => 'Continuer';

  @override
  String get recordingPause => 'Pause';

  @override
  String get sizeAdd => 'Ajouter';

  @override
  String get transcribeTitle => 'Écrire ce qui est dit';

  @override
  String get transcribeOn =>
      'Les notes vocales deviennent cherchables. Rien n’est envoyé nulle part.';

  @override
  String get transcribeOff =>
      'Éteint. Les notes vocales ne se retrouvent que par leur journée.';

  @override
  String get transcribeLanguage => 'Langue parlée';

  @override
  String get transcribeLanguageNote =>
      'La langue dans laquelle tu parles dans tes enregistrements. Une à la fois — une phrase qui passe de l’une à l’autre revient comme la moitié qui correspond à celle-ci.';

  @override
  String get transcribeNotDownloaded =>
      'Pas encore téléchargé sur ce téléphone — touche pour l’obtenir.';

  @override
  String transcribeGetBetter(String name) {
    return 'Obtenir le meilleur modèle pour $name';
  }

  @override
  String get transcribeGetBetterNote =>
      'Les transcriptions sont nettement plus justes avec lui. Le téléchargement vient de ton téléphone, pas de Lamplight, et n’arrive qu’une fois.';

  @override
  String get transcribeNoLanguages =>
      'Ce téléphone n’a encore proposé aucune langue.';

  @override
  String get transcribeNeedsDownloading => 'À télécharger';

  @override
  String folderStill(String day, String folder) {
    return 'Toujours au $day. Aussi dans $folder.';
  }

  @override
  String get folderRenameTitle => 'Renommer le dossier';

  @override
  String get folderNameHint => 'Une personne, un lieu, une période';

  @override
  String get voicePlay => 'Écouter cette note vocale';

  @override
  String get voiceForwardThirty => 'Trente secondes en avant';

  @override
  String voiceSpeed(String speed) {
    return 'Vitesse, actuellement $speed fois';
  }

  @override
  String get voiceLengthUnknown => 'note vocale, durée inconnue avant lecture';

  @override
  String get voicePosition => 'Position dans l’enregistrement';

  @override
  String get voiceOpening => 'Ouverture de l’enregistrement';

  @override
  String get voiceNoWords => 'Aucun mot n’est revenu — réessaie';

  @override
  String get voiceWriteThis => 'Écrire ceci';

  @override
  String get voiceCannotWrite =>
      'Ce téléphone ne peut pas écrire les notes vocales.';

  @override
  String get voiceLanguageMissing =>
      'Ce téléphone n’a pas encore téléchargé cette langue.';

  @override
  String get voiceWriting => 'En cours d’écriture…';

  @override
  String get voiceWaiting => 'En attente d’être écrit.';

  @override
  String get voiceWritten => 'Écrit sur ce téléphone.';

  @override
  String get errorPartNotShown => 'Cette partie n’a pas pu être montrée.';

  @override
  String get errorScreenShort => 'Cet écran ne s’est pas ouvert.';

  @override
  String get errorNothingLost =>
      'Rien n’a été perdu. Tout ce que tu as écrit est toujours dans le coffre, exactement comme c’était.';

  @override
  String get errorHideDetails => 'Masquer les détails techniques';

  @override
  String get errorShowDetails => 'Voir les détails techniques';

  @override
  String get errorDetailsNote =>
      'Voici tout ce qui serait copié. Cela dit ce qui a cassé et à quel endroit du code — cela ne contient rien de ce que tu as écrit.';

  @override
  String get passcodeChangeFailed => 'Le code n’a pas pu être changé.';

  @override
  String get passcodeOldStillWorks => 'Ton ancien code marche toujours.';

  @override
  String get passcodeChanged => 'Code changé';

  @override
  String get passcodeWordsUnchanged =>
      'Tes douze mots n’ont pas changé, et tu n’en as pas besoin de nouveaux. Ils ouvrent ton coffre et tes sauvegardes exactement comme avant.';

  @override
  String get passcodeOldBackups =>
      'Les sauvegardes que tu as déjà s’ouvrent encore avec ton ancien code. Une nouvelle, faite maintenant, prendra le nouveau.';

  @override
  String get passcodeMakeBackup => 'Faire une sauvegarde maintenant';

  @override
  String get passcodeCurrent => 'Code actuel';

  @override
  String get passcodeNewAgain => 'Le nouveau, encore';

  @override
  String get passcodeOldBackupsNote =>
      'Les fichiers de sauvegarde déjà faits s’ouvriront encore avec ton ancien code.';

  @override
  String get passcodeWordsNote =>
      'Tes douze mots de récupération ne changent pas et continuent de marcher.';

  @override
  String get licencesFonts =>
      'Chaque caractère ici est sous licence SIL Open Font. Rien n’est téléchargé — ils sont dans l’application.';

  @override
  String get licencesSource =>
      'Lamplight lui-même est en GPL-3.0 avec une exception pour les boutiques d’applications. Le code source est la licence : n’importe qui peut le lire et vérifier que l’application fait ce que dit cet écran.';

  @override
  String get licencesUnreadable => 'Ce fichier de licence n’a pas pu être lu.';

  @override
  String get appearanceSample =>
      'De la pluie tout l’après-midi. Fait du thé, lu un demi-chapitre, oublié ce que je voulais dire et écrit ça à la place.';

  @override
  String get appearanceChromeNote =>
      'Les boutons et les libellés restent comme ça';

  @override
  String get appearanceSizeNote =>
      'Cela s’ajoute à la taille de texte de ton téléphone : si tu l’as déjà augmentée, ceci va encore plus loin.';

  @override
  String get voicePause => 'Pause';

  @override
  String get importIntro =>
      'Si tu as tenu un journal ailleurs, Lamplight peut le reprendre — tant que ce sont des fichiers texte avec la date dans le nom.';

  @override
  String get importHowDates =>
      'Il lit les fichiers texte et cherche une date dans le nom — 2026-08-24, ou 24 août 2026 — n’importe où dans le nom du fichier ou des dossiers au-dessus.';

  @override
  String get importAmbiguousDates =>
      'Les dates comme 03-04-2026 sont ignorées exprès. C’est le trois avril dans certains pays et le quatre mars dans d’autres, et se tromper rangerait une année de ta vie aux mauvais jours sans rien te dire.';

  @override
  String get importFormats =>
      'Lamplight lit du texte brut : .txt, .md, .org, .log et d’autres, y compris des fichiers sans extension. Si ton journal est dans un autre format, exporte-le d’abord en texte.';

  @override
  String get importAtStartOfDay =>
      'Ils se placeront au début de chaque journée, parce qu’un nom de fichier donne la date et pas l’heure. Rien de ce qui est déjà dans Lamplight n’est modifié ni retiré, et refaire l’opération ne crée pas de doublons.';

  @override
  String get importFileDateNote =>
      'Les place au jour où le fichier a été modifié pour la dernière fois. Si le dossier a été copié d’un appareil à l’autre, ce sera peut-être le jour de la copie et non celui où tu as écrit.';

  @override
  String get importSkippedNote =>
      'Ceux-là seront ignorés. Ils restent exactement où ils sont — rien n’est déplacé ni supprimé de ton dossier.';

  @override
  String get restoreChooseNote =>
      'Choisis ton fichier de sauvegarde. Il s’appellera quelque chose comme Lamplight-2026-08-18.vault.';

  @override
  String get restorePasscodeNote =>
      'Saisis le code de ce fichier — celui qui était en place quand la sauvegarde a été faite.';

  @override
  String get restoreWordsNote =>
      'Tape les douze mots, dans l’ordre, séparés par des espaces.';

  @override
  String get restoreDoNotClose =>
      'Ne ferme pas Lamplight avant que ce soit fini.';

  @override
  String get exportIntro =>
      'Cela écrit tout ce qu’il y a dans Lamplight dans un dossier que tu choisis, en fichiers ordinaires — un fichier texte par journée, et chaque photo, vidéo, note vocale et document sous son propre nom.';

  @override
  String get exportNoLamplightNeeded =>
      'Rien dans ce dossier n’a besoin de Lamplight pour s’ouvrir. Si cette application cesse un jour de fonctionner, ou si tu arrêtes de t’en servir, tes notes s’ouvrent encore dans tout ce qui lit du texte.';

  @override
  String get exportWhichOneBody =>
      'Une copie lisible sert à lire, à passer à une autre application, ou à garder quelque chose après avoir arrêté Lamplight. Elle n’est pas protégée.\n\nUn fichier de sauvegarde sert à retrouver Lamplight exactement comme il était — un nouveau téléphone, ou un téléphone cassé. Il est fermé avec ton code, donc on peut le garder n’importe où, y compris sur un espace en ligne.\n\nLa plupart des gens veulent la sauvegarde. Prends aussi une copie lisible si tu veux être certain de ne jamais être coincé.';

  @override
  String get exportNotLockedBody =>
      'Elle n’a aucun code. N’importe qui ouvrant ce dossier peut tout y lire. Mets-la là où cela te convient — et si tu veux seulement quelque chose de sûr à conserver, prends plutôt Sauvegarde.';

  @override
  String get backupConfirmNote =>
      'Confirme ton code. Ce fichier peut tout déverrouiller, donc en créer un devrait être quelque chose que tu voulais vraiment.';

  @override
  String get backupKeepSafeNote =>
      'Ta sauvegarde est fermée avec le code que tu as maintenant. Garde-la où tu veux — un espace en ligne convient, parce que le fichier est illisible sans ce code. Nous ne le voyons jamais.';

  @override
  String get backupRestoreWarning =>
      'Ouvrir une sauvegarde remplace tout ce qui est actuellement dans Lamplight. Tes notes actuelles sont mises de côté jusqu’à ce que les restaurées soient prouvées ouvrables.';

  @override
  String get folderWhatItIs =>
      'Un dossier est un fil qui traverse tes journées — une personne, un lieu, une période.';

  @override
  String get folderNothingMoves =>
      'Rien ne déménage dans un dossier. Une entrée reste sur sa journée et apparaît ici en plus.';

  @override
  String get folderDeleteNote =>
      'Le dossier s’en va. Tout ce qu’il contenait reste exactement où c’était, sur sa propre journée.';

  @override
  String get folderNoneInHere =>
      'Rien ici pour l’instant. Appuie longuement sur quelque chose dans une journée et choisis « Ajouter à un dossier ».';

  @override
  String get passcodeRuleLength => 'Huit caractères ou plus.';

  @override
  String get passcodeRuleWords =>
      'Quelques mots ordinaires dont tu te souviens valent mieux qu’un court avec des symboles.';

  @override
  String get passcodeNoMatch => 'Les deux ne correspondent pas encore.';

  @override
  String get docCopyInClear =>
      'La copie est écrite en clair, donc toute application capable de lire tes fichiers peut la lire. Ce qui reste dans Lamplight reste chiffré dans tous les cas.';

  @override
  String docPageOf(String page, String total) {
    return '$page sur $total';
  }

  @override
  String get transcribeTookTooLong =>
      'Cet enregistrement mettait trop de temps à être transcrit, alors Lamplight a cessé d’attendre. Il réessaiera plus tard.';

  @override
  String get transcribeCouldNotWriteDown =>
      'Cet enregistrement n’a pas pu être transcrit.';

  @override
  String get transcribeRecordingIsSafe =>
      'L’enregistrement lui-même est intact. Lamplight réessaiera.';

  @override
  String voicePositionSpoken(Object at, Object total) {
    return '$at sur $total';
  }

  @override
  String entryEditedAt(Object time) {
    return '$time · modifiée';
  }

  @override
  String get docCouldNotOpen => 'Ce document n’a pas pu être ouvert.';

  @override
  String albumThisOne(Object thing) {
    return 'Ce $thing';
  }

  @override
  String albumThisOneOf(Object index, Object thing, Object total) {
    return 'Ce $thing — $index sur $total';
  }

  @override
  String get albumCaptionThese => 'Écrire quelque chose pour ceux-ci';

  @override
  String get albumCaptionThis => 'Écrire quelque chose';

  @override
  String get albumCaptionEdit => 'Modifier ce qui est écrit';

  @override
  String albumOthersStay(Object count) {
    return 'Les $count autres restent. Celui-ci va à la corbeille pendant 30 jours.';
  }

  @override
  String get albumGoesToTrash => 'Il va à la corbeille pendant 30 jours.';

  @override
  String get photoCouldNotOpen => 'Cette image n’a pas pu être ouverte.';

  @override
  String get photoMayBeDamaged => 'Elle est peut-être abîmée.';

  @override
  String get docTooBig =>
      'Celui-ci est trop gros pour être ouvert dans Lamplight. Vous pouvez en enregistrer une copie et l’ouvrir ailleurs.';

  @override
  String docPages(Object count) {
    return '$count pages';
  }

  @override
  String get docFileEmpty => 'Ce fichier est vide.';

  @override
  String videoTooBig(Object size) {
    return 'Cette vidéo est trop grande pour être lue ici — $size. Elle ne sera pas écrite sans protection pour contourner cela. Enregistrez une copie pour la regarder ailleurs.';
  }

  @override
  String get videoNotAvailableHere =>
      'Cette partie de l’application n’est pas disponible sur ce téléphone.';

  @override
  String get videoCouldNotOpen => 'Cette vidéo n’a pas pu être ouverte.';

  @override
  String get docGoToPage => 'Aller à une page';

  @override
  String get docGo => 'Aller';

  @override
  String get docPageCouldNotBeDrawn => 'Cette page n’a pas pu être affichée.';

  @override
  String get passcodeRuleStronger =>
      'Un mot ou deux de plus le rendraient bien plus dur à deviner.';

  @override
  String get backupAutoFooter =>
      'Les sauvegardes automatiques se font à l’ouverture de Lamplight, si quelque chose a changé depuis la dernière. Elles sont fermées avec ton code, exactement comme une que tu fais toi-même.';

  @override
  String get aboutHowKeptBody =>
      'Pas de compte. Pas de serveur. Rien ne quitte ce téléphone.\n\nTes notes sont fermées avec ton code, et la clé en est tirée — il n’en existe donc aucune copie nulle part, pas même chez nous.';

  @override
  String get aboutFree =>
      'Lamplight est gratuit et le restera. Il n’y a rien à débloquer.';

  @override
  String get aboutContact => 'Quelque chose ne va pas ? Écrivez-moi.';

  @override
  String get aboutContactSemantic => 'Envoyer un retour par e-mail';

  @override
  String aboutNoMail(String address) {
    return 'Aucune application de messagerie sur ce téléphone. L\'adresse est $address.';
  }

  @override
  String get backupOnItsOwn => 'Tout seul';

  @override
  String get actionDismiss => 'Masquer';

  @override
  String importRange(String from, String to) {
    return 'Du $from au $to.';
  }

  @override
  String get sizeOneCopy =>
      'Lamplight garde une seule copie. Ce que tu choisis ici est ce que tu auras.';

  @override
  String get sizeAddAlways => 'Ajouter et ne plus demander';

  @override
  String get trashNothingHere => 'Il n’y a rien ici.';

  @override
  String get appearanceAaQuiet => 'Aa\ncalme';

  @override
  String lockWarnSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verrouillage dans $count secondes environ.',
      one: 'Verrouillage dans une seconde environ.',
    );
    return '$_temp0';
  }

  @override
  String get lockWarnChange => 'Cela se change dans Verrouillage et sécurité.';

  @override
  String get openingLabel => 'Lamplight s’ouvre';

  @override
  String get recordingNoMic =>
      'Lamplight ne peut pas utiliser le micro. Tu peux l’autoriser dans les réglages du téléphone, sous Applications.';

  @override
  String get recordingPaused => 'En pause. Rien n’est écouté.';

  @override
  String get videoOpening => 'Ouverture de la vidéo…';

  @override
  String albumRemoveThis(String thing) {
    return 'Retirer $thing';
  }

  @override
  String get revisionsNote =>
      'Ce que cela disait avant que tu ne le changes. Rien ici n’est un bouton — tu peux sélectionner le texte et le copier.';

  @override
  String get composerSemantic => 'Écris quelque chose pour cette journée';

  @override
  String importStripAdding(String name) {
    return 'Ajout de $name';
  }

  @override
  String passcodeAtLeast(int count) {
    return 'Au moins $count caractères';
  }

  @override
  String get searchKindAll => 'Tout';

  @override
  String get searchKindWords => 'Mots';

  @override
  String get searchKindVoice => 'Voix';

  @override
  String get searchKindPhotos => 'Photos';

  @override
  String get searchKindFiles => 'Fichiers';

  @override
  String passcodeAtLeastShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Au moins $count caractères',
      one: 'Au moins 1 caractère',
    );
    return '$_temp0';
  }

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il reste $count jours',
      one: 'Il reste 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get trashGoneToday => 'Part aujourd’hui';

  @override
  String restoreMadeOn(String date) {
    return 'Faite le $date';
  }

  @override
  String restoreDone(String entries, String days) {
    return '$entries restaurées sur $days. Content de te revoir.';
  }

  @override
  String importFoundUndated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sans date que Lamplight sache lire',
      one: '1 sans date que Lamplight sache lire',
    );
    return '$_temp0';
  }

  @override
  String entrySemantic(String time) {
    return 'Entrée de $time. Touche pour modifier.';
  }

  @override
  String entrySemanticEdited(String time) {
    return 'Entrée de $time, modifiée. Touche pour modifier.';
  }

  @override
  String onThisDaySemantic(String when, String body) {
    return '$when. $body. Touche pour aller à cette journée.';
  }

  @override
  String attachmentSemantic(String what, String time) {
    return '$what de $time. Touche deux fois pour les ouvrir.';
  }

  @override
  String dayHeaderToday(String date) {
    return '$date, aujourd’hui';
  }

  @override
  String get yearGridNothing => 'Rien sur cette journée';

  @override
  String get calendarNothing => 'Rien sur cette journée';

  @override
  String importStripCounted(String name, String counted) {
    return 'Ajout de $name$counted';
  }

  @override
  String get aboutFingerprintBody =>
      'Chaque build porte une signature que seul son auteur peut produire. Voici celle de la copie que tu tiens. Compare-la à l’empreinte publiée à côté du code source — si elles correspondent, c’est bien l’application que ce code construit.';

  @override
  String get searchKindVideo => 'Vidéo';

  @override
  String get semanticOn => 'activé';

  @override
  String andMore(int count) {
    return 'et $count de plus';
  }

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées',
      one: '1 entrée',
      zero: 'rien',
    );
    return '$_temp0';
  }

  @override
  String get checkDone => 'Fait';

  @override
  String get checkNotYet => 'Pas encore';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get lockUseYourPasscode => 'Utilise ton code.';

  @override
  String get searchWordsExample => 'tout ce que tu as écrit';

  @override
  String get searchAFile => 'Un fichier';

  @override
  String get searchFileExample => 'scan.pdf · IMG_2831';

  @override
  String get searchAFolder => 'Un dossier';

  @override
  String get searchFolderExample => 'le nom que tu lui as donné';

  @override
  String get searchByFileName => 'par le nom du fichier';

  @override
  String get searchARecording => 'Un enregistrement';

  @override
  String get searchAnEntry => 'Une entrée';

  @override
  String get sizeThisOne => 'ceci';

  @override
  String get sizeTheseOnes => 'ceux-ci';

  @override
  String get passcodeOneMoreCharacter => 'Encore un caractère.';

  @override
  String passcodeMoreCharacters(int count, int minimum) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore $count caractères — $minimum au minimum.',
      one: 'Encore 1 caractère — $minimum au minimum.',
    );
    return '$_temp0';
  }

  @override
  String get passcodeTooObvious =>
      'C’est l’une des premières choses que n’importe qui essaierait. Choisis autre chose.';

  @override
  String get passcodeSameCharacter => 'C’est le même caractère répété.';

  @override
  String get passcodeStraightRun =>
      'C’est une suite de caractères qui se suivent.';

  @override
  String attachmentLoading(String time) {
    return 'Pièce jointe à $time, chargement';
  }

  @override
  String videoSemantic(String time, String length) {
    return 'Vidéo à $time, $length. Appuie deux fois pour la regarder.';
  }

  @override
  String voiceSemantic(String time, String length) {
    return 'Note vocale à $time, $length. Appuie deux fois pour l’écouter.';
  }

  @override
  String fileSemantic(String time, String name, String size) {
    return 'Fichier à $time, $name, $size. Appuie deux fois pour l’ouvrir.';
  }

  @override
  String get lengthUnknown => 'durée inconnue';

  @override
  String get settingsLockNone => 'pas de verrouillage automatique';

  @override
  String settingsLockAfter(String duration) {
    return 'après $duration';
  }

  @override
  String settingsSecuritySummary(String lock) {
    return 'Code, empreinte, $lock';
  }

  @override
  String get keptNoNetworkTitle => 'Rien ne part jamais';

  @override
  String get keptNoNetworkBody =>
      'Lamplight ne peut pas utiliser internet. Pas « ne le fait pas » — ne peut pas : Android lui refuse l’autorisation, et tu peux le vérifier toi-même dans les réglages des applications du téléphone en une trentaine de secondes.';

  @override
  String get keptPasscodeTitle => 'Ton code est la clé';

  @override
  String get keptPasscodeBody =>
      'La clé qui ouvre tes notes est fabriquée à partir de ton code à chaque déverrouillage. Elle n’est stockée nulle part : il n’y a donc aucune copie à trouver, à perdre ou à remettre.';

  @override
  String get keptForgetTitle => 'Si tu l’oublies';

  @override
  String get keptForgetBody =>
      'Tes douze mots sont le seul autre moyen d’entrer. Ici, personne ne peut réinitialiser un code, et c’est le même fait que ci-dessus : une application capable de te laisser revenir pourrait aussi laisser entrer quelqu’un d’autre.';

  @override
  String get keptNothingReadableTitle => 'Rien de lisible ne traîne';

  @override
  String get keptNothingReadableBody =>
      'Les photos, les enregistrements et les fichiers sont chiffrés avant de toucher le stockage. Rien n’est jamais écrit en clair, pas même brièvement pendant que tu le regardes.';

  @override
  String get keptLocksItselfTitle => 'Il se verrouille tout seul';

  @override
  String get keptLocksItselfBody =>
      'Dès que Lamplight passe en arrière-plan, les clés sont détruites. Les captures d’écran sont bloquées et l’application n’apparaît pas dans l’aperçu des applications récentes.';

  @override
  String get keptBackUpTitle => 'Fais une sauvegarde';

  @override
  String get keptBackUpBody =>
      'Tout est sur ce téléphone et nulle part ailleurs : c’est tout l’intérêt, et c’est aussi le risque. Une sauvegarde est un seul fichier chiffré que seul ton code ouvre. Gardes-en une quelque part.';

  @override
  String etaSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore environ $count secondes',
    );
    return '$_temp0';
  }

  @override
  String etaMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encore environ $count minutes',
      one: 'Encore une minute environ',
    );
    return '$_temp0';
  }

  @override
  String youWroteForMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vous avez écrit pendant $count minutes.',
      one: 'Vous avez écrit pendant une minute.',
    );
    return '$_temp0';
  }
}
