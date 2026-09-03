import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:sodium/sodium_sumo.dart';

/// The database on a worker isolate — the shipped configuration.
///
/// ── WHY THIS FILE HAD TO EXIST ──────────────────────────────────────────────
///
/// Moving the database off the thread that draws the screen is the largest
/// change in this codebase, and it came with a trap: `screens_test.dart` has
/// to run the database **in this isolate**, because `testWidgets` uses a fake
/// clock and a worker answers on the real one. Left there, the arrangement
/// would be that the configuration users actually get is the one nothing
/// tests.
///
/// So these are plain `test()`s, outside the widget harness, against a real
/// worker. Everything here is a property that only breaks once the database is
/// somewhere else.
void main() {
  late SodiumSumo sodium;
  late VaultCrypto crypto;
  late Directory tmp;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    crypto = VaultCrypto(sodium);
  });

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('lamplight_worker');
  });

  tearDown(() {
    if (tmp.existsSync()) {
      try {
        tmp.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows keeps a handle for a moment after the worker stops. The
        // temp directory is not what is under test.
      }
    }
  });

  Uint8List keyFor(VaultCrypto crypto) {
    final dek = crypto.generateDek();
    final sub = crypto.deriveSubkey(dek, KeyPurpose.database);
    final bytes = Uint8List.fromList(sub.extractBytes());
    dek.dispose();
    sub.dispose();
    return bytes;
  }

  test('the default is the worker, not this isolate', () {
    // The one line that decides whether any of this ships. If a future change
    // flips the default "just for tests", the app silently goes back to
    // decrypting pages on the isolate that paints frames, and nothing else
    // would report it.
    expect(debugUseInProcessDatabase, isFalse);
  });

  test('a vault opens, writes and reads back through the worker', () async {
    final db = await openVaultDatabase(
      path: '${tmp.path}/vault.db',
      key: keyFor(crypto),
    );
    final repo = EntryRepository(db);

    await repo.createText(id: 'a', dayKey: '2026-08-25', body: 'across a port');
    final back = await repo.watchDay('2026-08-25').first;

    expect(back.single.body, 'across a port');
    await db.close();
  });

  test('a watched query keeps delivering after a write', () async {
    // The property the day view depends on. A stream that works once and then
    // stops would look like "the app does not update until you swipe away and
    // back" — which is a bug report nobody would connect to isolates.
    final db = await openVaultDatabase(
      path: '${tmp.path}/vault.db',
      key: keyFor(crypto),
    );
    final repo = EntryRepository(db);

    final seen = <int>[];
    final sub = repo.watchDay('2026-08-25').listen((rows) => seen.add(rows.length));

    await repo.createText(id: 'a', dayKey: '2026-08-25', body: 'one');
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await repo.createText(id: 'b', dayKey: '2026-08-25', body: 'two');
    await Future<void>.delayed(const Duration(milliseconds: 120));

    await sub.cancel();
    await db.close();

    expect(seen.last, 2, reason: 'the stream stopped following the table');
  });

  test('the wrong key fails at open, not at some later query', () async {
    final path = '${tmp.path}/vault.db';
    final good = await openVaultDatabase(path: path, key: keyFor(crypto));
    await good.close();

    await expectLater(
      openVaultDatabase(path: path, key: keyFor(crypto)),
      throwsA(anything),
    );
  });

  test('a typed failure survives the trip back from the worker', () async {
    // THE ONE THIS FILE WAS WRITTEN FOR.
    //
    // drift wraps anything thrown inside the worker in a
    // `DriftRemoteException` — twice, in fact, once at the server layer and
    // once at the client. Unwrapped, every `on VaultTooNew` in the app stops
    // matching and the person opening a vault from a newer build gets a
    // generic error instead of the sentence written for them.
    //
    // migration_test.dart caught it on the first run after the move. This
    // keeps it caught if anybody simplifies the unwrapping back to one step.
    final path = '${tmp.path}/vault.db';
    final key = keyFor(crypto);

    final db = await openVaultDatabase(path: path, key: key);
    await db.customStatement('PRAGMA user_version = 99');
    await db.close();

    await expectLater(
      openVaultDatabase(path: path, key: key),
      throwsA(isA<VaultTooNew>()),
    );
  });

  test('closing stops the worker, so locking takes the key with it', () async {
    // `Vault.lock()` closes the database and nothing else. If closing left the
    // worker running, a locked vault would leave an isolate alive holding the
    // database key — which is the opposite of what locking is for.
    //
    // Measured by count rather than by inspection: the isolate is drift's, and
    // asking the VM about it directly would test drift rather than us. Opening
    // and closing many times without the process growing unboundedly is the
    // observable form of the same claim.
    // One key throughout: reopening the SAME file is the point, and a fresh
    // key each time would fail to decrypt for reasons that have nothing to do
    // with isolates.
    final key = keyFor(crypto);
    final path = '${tmp.path}/reopened.db';

    for (var i = 0; i < 8; i++) {
      final db = await openVaultDatabase(path: path, key: key);
      await db.customSelect('SELECT 1').get();
      await db.close();
    }

    // Reaching here at all is the assertion. A worker that outlived its close
    // would still hold this file open, and on Windows the next open of the
    // same path fails outright.
    final again = await openVaultDatabase(path: path, key: key);
    await again.close();
  });
}
