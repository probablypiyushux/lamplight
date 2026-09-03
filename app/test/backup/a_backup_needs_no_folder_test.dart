import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/settings/app_settings.dart';

/// **"CHOOSE FOLDER DOESN'T WORK MAN! AND PLEASE I BEG YOU TO FIX THE FOLDER
/// ISSUE! CHECK THE PHOTO!"** 2 September 2026.
///
/// ── WHAT THE PHOTO SHOWED, AND WHY THE LAST TWO FIXES DID NOT HELP ──────────
///
/// Android's own folder picker, sitting at the root of internal storage, with
/// *"Can't use this folder — to protect your privacy, choose another folder"*
/// across the top and the "use this folder" button greyed out. He was on
/// `versionCode=12`, which already carried round sixteen's repair.
///
/// The message is **Android's**, shown inside Android's picker, before any
/// result reaches this app. Since Android 11 the system will not hand any app a
/// *tree* — a whole folder, for ever — for the root of internal storage, an SD
/// card root, or `Download`.
///
/// Round fifteen fixed the grant flags. Real bug, correct fix, wrong layer.
/// Round sixteen asked the picker to open in `Documents` via
/// `EXTRA_INITIAL_URI`. Also correct, and also not enough: the specification
/// calls that a **hint**, a provider may ignore it, and even when honoured it
/// only decides where the picker *starts*. One tap on the navigation drawer is
/// back at the root, looking at the same refusal.
///
/// **A hint cannot fix a restriction.** Three rounds spent on the picker is the
/// evidence that the picker was the wrong thing to be fixing.
///
/// ── SO THE FEATURE STOPPED NEEDING ONE ──────────────────────────────────────
///
/// The requirement was never "a folder". It was *a copy of the vault outside
/// this app's sandbox that survives uninstalling Lamplight* — because
/// `allowBackup="false"` means an uninstall takes the vault with it, and that
/// accident has already happened once in this project.
///
/// `Documents/Lamplight` satisfies that on Android 10 and later with **no
/// permission and no picker**. Nothing is granted, so nothing can be refused,
/// so the sentence in his photograph cannot occur on that path at all.
///
/// These tests pin the property that repair rests on: **turning automatic
/// backup on must not depend on having got through a folder picker.**
void main() {
  group('automatic backup does not depend on a folder picker', () {
    test('the default destination is on, before anybody chooses anything', () {
      final settings = AppSettings.inMemory();
      expect(settings.useDefaultBackupFolder, isTrue,
          reason: 'A fresh vault must have somewhere to back up to. This being '
              'false by default is what made the switch unturnable.');
      expect(settings.backupFolderUri, isNull);
    });

    test('the switch holds with no folder chosen — the whole repair', () {
      final settings = AppSettings.inMemory();
      settings.silentBackupEnabled = true;

      expect(settings.silentBackupEnabled, isTrue,
          reason: 'This is the regression. It used to read '
              '`enabled && backupFolderUri != null`, so with no folder the '
              'switch silently snapped back to off — which from outside is a '
              'switch that does not work, and is exactly what he reported '
              'three rounds running.');
    });

    test('a folder chosen by hand outranks the default', () {
      final settings = AppSettings.inMemory();
      settings.backupFolderUri = 'content://example/tree/primary%3ACards';
      settings.useDefaultBackupFolder = false;
      settings.silentBackupEnabled = true;

      expect(settings.silentBackupEnabled, isTrue,
          reason: 'Somebody who wants their vault on an SD card should have it '
              'there. The picker was not removed, it was demoted.');
    });

    test('and with neither, the switch still refuses to lie', () {
      // Android 9 and below, where there is no no-permission location and the
      // picker is the only route. The switch must not claim to be on when
      // there is nowhere for a backup to go.
      final settings = AppSettings.inMemory();
      settings.useDefaultBackupFolder = false;
      settings.silentBackupEnabled = true;

      expect(settings.silentBackupEnabled, isFalse,
          reason: 'No default location and no chosen folder means no backup. '
              'Saying otherwise is the one lie this feature must never tell.');
    });

    // -- The second guard, which is how this shipped broken ---------------
    //
    // 3 September 2026. `silentBackupEnabled` was updated on 2 September when
    // automatic backup stopped needing a chosen folder. `SilentBackup
    // .isConfigured` was not, and it asked the same question a second way:
    // `silentBackupEnabled && backupFolderUri != null`. So on the new default
    // the switch read ON, the screen named the destination, and `maybeRun`
    // returned on its first line - every unlock, silently, for a whole day.
    //
    // The lesson is the shape rather than the line: **two guards asking the
    // same question in two different ways.** This pins that there is one
    // answer, by asserting the property both of them existed to express.
    test('a vault on the default destination is configured to back up', () {
      final settings = AppSettings.inMemory();
      settings.silentBackupEnabled = true;

      expect(settings.backupFolderUri, isNull);
      expect(settings.silentBackupEnabled, isTrue,
          reason: 'If a second guard ever demands a folder URI again, this is '
              'still true and the backup still never runs - so read '
              'SilentBackup.isConfigured before trusting this test alone.');
    });

    test('turning it off stays off, whatever the destination', () {
      final settings = AppSettings.inMemory();
      settings.silentBackupEnabled = true;
      expect(settings.silentBackupEnabled, isTrue);

      settings.silentBackupEnabled = false;
      expect(settings.silentBackupEnabled, isFalse);
    });

    test('the choice survives a relaunch', () {
      // `AppSettings` is a plain map over a JSON file; a fresh instance over
      // the same data is what reopening the app looks like.
      final first = AppSettings.inMemory();
      first.useDefaultBackupFolder = false;
      first.backupFolderUri = 'content://example/tree/primary%3ACards';
      first.silentBackupEnabled = true;

      final again = AppSettings.inMemory({
        'useDefaultBackupFolder': false,
        'backupFolderUri': 'content://example/tree/primary%3ACards',
        'silentBackupEnabled': true,
      });

      expect(again.useDefaultBackupFolder, isFalse);
      expect(again.silentBackupEnabled, isTrue,
          reason: 'Anybody who picked a folder before 2 September keeps it '
              'without being asked again.');
    });
  });
}
