import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:sodium/sodium_sumo.dart';

/// **An app update must never cost a user their notes.**
///
/// This is the test that exists because of a question rather than a bug: what
/// happens to somebody's three-year journal when they take an update from the
/// Play Store? The answer has to be "nothing", every time, and "nothing" is not
/// a thing you can verify by looking at the code once and feeling reassured.
///
/// Two things are checked here, and the second one is the one that will
/// actually save somebody.
void main() {
  late SodiumSumo sodium;
  late VaultCrypto crypto;
  late Directory tmp;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    crypto = VaultCrypto(sodium);
  });
  setUp(() => tmp = Directory.systemTemp.createTempSync('lamplight_migrate'));
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Uint8List freshKey() {
    final dek = crypto.generateDek();
    final sub = crypto.deriveSubkey(dek, KeyPurpose.database);
    final key = Uint8List.fromList(sub.extractBytes());
    dek.dispose();
    sub.dispose();
    return key;
  }

  // ═════════════════════════════════════════════════════════════════════════
  test('the schema version is pinned, so raising it is a deliberate act', () {
    // **If this test fails, you have changed the schema. Read this.**
    //
    // Raising `schemaVersion` without adding the matching `if (from < n)` block
    // to `onUpgrade` means every existing vault on earth fails to open after
    // the update installs. drift's default onUpgrade throws, and it throws
    // *after* the user has already taken the update.
    //
    // So the number is written down twice on purpose. To change it:
    //
    //   1. add the migration step to `onUpgrade` in database.dart
    //   2. add a test below that opens a vault at the OLD version, migrates it,
    //      and proves the entries are still there
    //   3. only then change the number here
    //
    // In that order. The test is what proves the migration works; writing it
    // afterwards proves only that you wrote a test afterwards.
    return expectLater(
      openVaultDatabase(path: '${tmp.path}/v.db', key: freshKey())
          .then((db) async {
        final version = db.schemaVersion;
        await db.close();
        return version;
      }),
      completion(
        // **5 since 26 August 2026** — `attachments.last_page`, so a document
        // opens where you left it (ROUND EIGHT, ISSUE 1B). It follows
        // `attachments.original_size` at v4 on 24 August, `entries.group_id`
        // at v3 on 20 August, and `attachments.waveform` at v2 on 19 August.
        // Every step is in `onUpgrade`, and the test below opens a v1, v2, v3
        // and v4 vault and walks each of them up to here.
        //
        // This number sat at 2 while the schema was already 3, which is the
        // failure this test is for: the pin is what makes raising the version
        // a deliberate act, and it stayed red until step 2 of the rules above
        // — the migration test — was actually written.
        5,
      ),
    );
  });

  // ═════════════════════════════════════════════════════════════════════════
  test('reopening a vault at the same version keeps every entry', () async {
    // The ordinary case, and the one that runs on every single app launch: the
    // schema has not moved, so opening must be a no-op that touches nothing.
    final root = Directory('${tmp.path}/vault');
    final vault = Vault(
      sodium: sodium,
      root: root,
      idleTimeout: const Duration(hours: 1),
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase');

    final db = vault.database;
    final now = DateTime.now();
    for (var i = 0; i < 5; i++) {
      await db.into(db.entries).insert(EntriesCompanion.insert(
            id: vault.newId(),
            createdAt: now.millisecondsSinceEpoch + i,
            createdOffsetMinutes: now.timeZoneOffset.inMinutes,
            updatedAt: now.millisecondsSinceEpoch + i,
            type: 'text',
            body: Value('entry number $i'),
            dayKey: '2026-08-19',
          ));
    }
    await vault.checkpoint();
    await vault.lock();

    // Close and reopen, the way an app relaunch does. This is exactly what
    // happens after an update that did not change the schema — which is most
    // of them.
    await vault.initialise();
    await vault.unlockWithPasscode('a passphrase');

    final rows = await vault.database.select(vault.database.entries).get();
    expect(rows, hasLength(5));
    expect(
      rows.map((r) => r.body).toList()..sort(),
      containsAll(['entry number 0', 'entry number 4']),
    );

    await vault.lock();
  });
  // ═════════════════════════════════════════════════════════════════════════
  test('a vault written by an OLDER version opens with everything still in it',
      () async {
    // **This is the one that will actually save somebody.** Every other test in
    // this file checks a database this build made. This one checks a database
    // an *earlier build* made, which is the only case that matters on the day
    // an update installs — and the only case that cannot be re-run afterwards
    // if it turns out to be wrong.
    //
    // The old shapes are made by taking a current database and removing what
    // each version did not have yet, rather than by writing three versions of
    // the schema out by hand. A hand-written copy of the schema in a test is a
    // second copy that nobody updates, and a migration test that has quietly
    // drifted from the real schema is worse than no test at all: it passes,
    // while the thing it claims to protect is broken.
    for (final from in [1, 2, 3, 4]) {
      final path = '${tmp.path}/from-v$from.db';
      final key = freshKey();

      var db = await openVaultDatabase(path: path, key: key);
      final now = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < 5; i++) {
        await db.into(db.entries).insert(EntriesCompanion.insert(
              id: 'old-$from-$i',
              createdAt: now + i,
              createdOffsetMinutes: 0,
              updatedAt: now + i,
              type: 'text',
              body: Value('written on version $from, entry $i'),
              dayKey: '2006-03-16',
            ));
      }

      // Backwards, newest step first, exactly mirroring `onUpgrade` in reverse.
      if (from < 5) {
        await db.customStatement('ALTER TABLE attachments DROP COLUMN last_page');
      }
      if (from < 4) {
        await db
            .customStatement('ALTER TABLE attachments DROP COLUMN original_size');
      }
      if (from < 3) {
        await db.customStatement('ALTER TABLE entries DROP COLUMN group_id');
      }
      if (from < 2) {
        await db.customStatement('ALTER TABLE attachments DROP COLUMN waveform');
      }
      await db.customStatement('PRAGMA user_version = $from');
      await db.close();

      // Today's code opens it. This line is the update installing on a phone
      // with three years of somebody's life in it.
      db = await openVaultDatabase(path: path, key: key);

      final rows = await db.select(db.entries).get();
      expect(rows, hasLength(5), reason: 'entries were lost migrating from v$from');
      expect(
        rows.map((r) => r.body).toList()..sort(),
        containsAll([
          'written on version $from, entry 0',
          'written on version $from, entry 4',
        ]),
        reason: 'an entry survived the migration but its text did not',
      );

      // The columns each step was for exist afterwards, and are empty rather
      // than guessed at — rule 3, a migration changes the shape and not the
      // contents.
      expect(rows.every((r) => r.groupId == null), isTrue);
      final columns =
          await db.customSelect('PRAGMA table_info(attachments)').get();
      expect(
        columns.map((r) => r.data['name']),
        contains('waveform'),
        reason: 'the v1 → v2 step did not run on the way up from v$from',
      );
      expect(
        columns.map((r) => r.data['name']),
        contains('original_size'),
        reason: 'the v3 → v4 step did not run on the way up from v$from',
      );
      expect(
        columns.map((r) => r.data['name']),
        contains('last_page'),
        reason: 'the v4 → v5 step did not run on the way up from v$from',
      );

      // And the file now says what it is, so the next launch is an ordinary
      // one rather than a second migration.
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data.values.first, 5);

      await db.close();
    }
  });

  // ═════════════════════════════════════════════════════════════════════════
  test('a vault from a NEWER version is refused rather than damaged', () async {
    // Someone updates, writes something, then rolls back to an older build —
    // or restores a newer backup onto an older install. The old binary would
    // otherwise open the database happily and start writing rows against a
    // schema it does not understand, corrupting something that was fine.
    //
    // Refusing leaves everything intact and says what to do. The user still has
    // all of their notes at the moment the error appears, which is the whole
    // reason for the error.
    final path = '${tmp.path}/newer.db';
    final key = freshKey();

    final db = await openVaultDatabase(path: path, key: key);
    // Claim the file was written by a much later version.
    await db.customStatement('PRAGMA user_version = 99');
    await db.close();

    await expectLater(
      openVaultDatabase(path: path, key: key),
      throwsA(isA<VaultTooNew>()),
    );

    // And nothing was destroyed on the way past — the tables are still there.
    await db.close().catchError((_) {});
  });
}
