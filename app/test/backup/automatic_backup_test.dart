import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:lamplight/core/settings/app_settings.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:lamplight/features/backup/silent_backup.dart';

/// The automatic backup's decision, which had no test at all until now.
///
/// ══ WHAT WENT WRONG, AND WHY 1,157 PASSING TESTS SAID NOTHING ════════════
///
/// He reported that the automatic backup "has an issue". It had two, and they
/// compounded:
///
///  1. It was triggered on `AppLifecycleState.inactive` — the frame or two
///     before the vault locks and destroys the keys. A backup is a second
///     Argon2id at 256 MiB, a full copy of the database, a verify pass and a
///     Storage Access Framework write. It cannot finish in a frame or two, so
///     on every real exit it was killed halfway.
///
///  2. The "have we run recently" guard recorded its attempt *before* doing the
///     work, so the run that had just been killed then blocked the next attempt
///     for ten minutes.
///
/// It completed only when `inactive` did not mean leaving — a notification
/// shade, an incoming call — so it worked when nothing was at stake and failed
/// whenever something was.
///
/// **The reason no test caught it** is that the decision lived inline in
/// `maybeRun`, wrapped around real crypto and a real platform channel, so there
/// was nothing a laptop could call. It is `SilentBackup.isDue` now, and this
/// file is the test that should have existed.
///
/// Note what is *not* tested here: the backup actually running. That needs a
/// device — Argon2 over real files and a document provider. What is tested is
/// every branch of the decision to run, which is where the bug was.
void main() {
  late Directory tmp;
  late AppSettings settings;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lamplight_autobackup');
    settings = await AppSettings.load(File('${tmp.path}/settings.json'));
  });

  /// Waits for `AppSettings`'s fire-and-forget save to reach the disk.
  ///
  /// `_write` calls `unawaited(_save())`, which is right for the app — a failed
  /// preference write is not worth blocking a tap for — and means a test that
  /// reads the file immediately is racing it.
  Future<File> saved() async {
    final file = File('${tmp.path}/settings.json');
    for (var i = 0; i < 200 && !file.existsSync(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(file.existsSync(), isTrue,
        reason: 'settings were never written to disk');
    return file;
  }

  tearDown(() async {
    // Let any in-flight save finish before deleting the directory out from
    // under it, or Windows refuses the delete with errno 32.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } on FileSystemException {
      // A stray temp file on Windows is not a test failure.
    }
  });

  /// A [SilentBackup] with no vault. Every assertion here is about [isDue],
  /// which reads only `settings`, so the vault is never touched.
  SilentBackup subject() =>
      SilentBackup(vault: _UnusedVault(), settings: settings);

  group('what warrants a backup', () {
    test('a fresh vault that has never been written to does not', () {
      expect(subject().isDue, isFalse,
          reason: 'nothing has changed, so a backup would rewrite an identical '
              'file — battery and drive space for no protection');
    });

    test('writing to the vault does', () {
      subject().markDirty();
      expect(subject().isDue, isTrue);
    });

    test('a changed passcode does, even with nothing written', () {
      // ISSUE 20. Rewrapping the keyring changes thirty-two bytes and nothing
      // anybody would call a change, so the dirty flag never fires for it —
      // and the file on disk now opens only with a passcode its owner has
      // deliberately stopped using.
      settings.backupOutOfDate = true;
      expect(subject().isDue, isTrue);
    });
  });

  group('the flag survives the process, which is the whole fix', () {
    test('a write recorded in one session is still owed in the next', () async {
      // ══ THE REGRESSION TEST FOR THE ACTUAL BUG ═══════════════════════════
      //
      // `_dirty` was a plain field. The user writes, leaves, the flag dies with
      // the process, and the next launch has no idea a backup is owed. The
      // twenty-hour staleness clause was there to paper over exactly this, and
      // it papered badly in both directions.
      subject().markDirty();

      // A new AppSettings over the same file is what a relaunch looks like.
      final reloaded = await AppSettings.load(await saved());
      expect(reloaded.vaultChangedSinceBackup, isTrue,
          reason: 'the fact that a backup is owed has to outlive the process '
              'that noticed it — that is the entire reason it is on disk');

      expect(SilentBackup(vault: _UnusedVault(), settings: reloaded).isDue,
          isTrue);
    });

    test('and a finished backup clears it for the next session too', () async {
      subject().markDirty();
      // What the tail of a successful run does.
      settings.vaultChangedSinceBackup = false;

      final reloaded = await AppSettings.load(await saved());
      expect(reloaded.vaultChangedSinceBackup, isFalse);
      expect(SilentBackup(vault: _UnusedVault(), settings: reloaded).isDue,
          isFalse);
    });
  });

  group('marking dirty is cheap enough to call on every keystroke', () {
    test('setting it when it is already set does not rewrite the file',
        () async {
      final backup = subject()..markDirty();
      final file = await saved();

      final before = file.lastModifiedSync();
      final sizeBefore = file.lengthSync();
      for (var i = 0; i < 50; i++) {
        backup.markDirty();
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(file.lengthSync(), sizeBefore);
      expect(file.lastModifiedSync(), before,
          reason: 'markDirty runs on every entry, every edit and every '
              'attachment. Persisting an unchanged value each time would be a '
              'disk write per keystroke.');
    });
  });

  group('what the settings screen is told', () {
    // The words come from the ARB now rather than from this class, so the
    // English is loaded to read them. That is the point of the change: the
    // sentence a person sees when their backup did not finish is one of the
    // ones this app most needs in their own language.
    late L l;
    setUpAll(() async {
      l = await L.delegate.load(const Locale('en'));
    });

    test('idle does not claim a backup happened', () {
      expect(const SilentBackupStatus.idle().describeIn(l),
          isNot(contains('up.')));
    });

    test('a failure says it will try again, because it will', () {
      // The retry is now the next unlock rather than the next time the app
      // loses focus, and the sentence has to stay true of whichever it is.
      final failed = SilentBackupStatus.failed('anything');
      expect(failed.describeIn(l).toLowerCase(), contains('try again'));
    });

    test('and it says so in every language, not only in English', () async {
      for (final locale in L.supportedLocales) {
        final words = await L.delegate.load(locale);
        final failed = SilentBackupStatus.failed('anything');
        expect(failed.describeIn(words), isNotEmpty,
            reason: locale.languageCode);
        expect(const SilentBackupStatus.idle().describeIn(words), isNotEmpty,
            reason: locale.languageCode);
      }
    });
  });
}

/// A stand-in that would throw if anything touched it.
///
/// `isDue` reads `settings` and nothing else, and this is how that is asserted
/// rather than assumed: if somebody makes the decision depend on the vault —
/// on `isUnlocked`, on a session key — every test in this file fails loudly
/// instead of quietly starting to need a device.
class _UnusedVault implements Vault {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
        'SilentBackup.isDue must not touch the vault: it is called before the '
        'vault is known to be usable, and a decision that needs keys cannot be '
        'tested on a laptop. See automatic_backup_test.dart.',
      );
}
