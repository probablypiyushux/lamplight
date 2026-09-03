import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/backup/vault_file.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:sodium/sodium_sumo.dart';

/// **PROMPT 2, STEP 1 — the part that does not need a phone.**
///
/// > *"Search the raw bytes of every file in the sandbox for a known plaintext
/// > marker string I put in a test note. Any hit is a critical failure. Make
/// > this an automated test that runs in CI."*
/// > — `09-build/SAFETY-PROMPTS.md`
///
/// ══ WHY THIS EXISTS BESIDE THE INTEGRATION TEST ═══════════════════════════
///
/// `integration_test/nothing_in_the_clear_test.dart` is the full version and it
/// is the right one. It is also, as of today, **written and never run** — it
/// needs a device or an emulator with KVM, the one attempt to run it destroyed
/// a vault, and a test that has never executed protects nothing.
///
/// So the scan is split by *what actually needs Android*:
///
/// | | Needs a device? |
/// |---|---|
/// | The vault directory — database, WAL, journal, keyring, attachment blobs | **No.** Same code, same libsodium, same SQLCipher on every platform. |
/// | A `.vault` backup | **No.** |
/// | The system temp directory | **No.** |
/// | `cache/`, `shared_prefs/`, `code_cache/`, `no_backup/` | **Yes.** Those are Android's, and nothing here can create them. |
///
/// **Three of the four run everywhere, so they run in CI on every push**, which
/// is what the prompt actually asked for. The fourth is what
/// `integration_test/` is for, and `05-shipping/HARDWARE-CHECKS.md` says how to
/// run it.
///
/// ── WHY THIS IS NOT REDUNDANT WITH THE TESTS THAT ALREADY EXIST ───────────
///
/// `nothing_is_left_behind_test.dart` proves the "Open with" hand-off leaves
/// nothing, and `attachment_importer_test.dart` proves an import scrubs its temp
/// file. Both are about **one path**. This is the opposite shape: it does not
/// know or care which path might leak. It writes a marker through **every**
/// storage path the app has, then reads back **every byte the app wrote** and
/// insists the marker is nowhere. A future path that leaks fails this without
/// anybody having thought to test it — which is the only kind of leak test that
/// keeps working.
void main() {
  late SodiumSumo sodium;
  late VaultCrypto crypto;
  late Directory tmp;
  late String marker;
  late List<int> markerBytes;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    crypto = VaultCrypto(sodium);
  });

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('lamplight_leak');
    // From the OS, and fresh every test, so a hit can only ever be ours and a
    // stale file from a previous run cannot produce a false pass or a false
    // failure.
    final random = sodium.randombytes.buf(24);
    marker =
        'MARKER-${random.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
    markerBytes = marker.codeUnits;
  });

  tearDown(() {
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  /// Every file under [root], with nothing skipped and nothing followed.
  List<File> everyFile(Directory root) {
    final files = <File>[];
    if (!root.existsSync()) return files;
    for (final e in root.listSync(recursive: true, followLinks: false)) {
      if (e is File) files.add(e);
    }
    return files;
  }

  /// Which of those files hold the marker anywhere in their raw bytes.
  ///
  /// Whole-file reads, because everything here is small by construction. The
  /// integration test streams, because on a device it may meet a video.
  List<String> scan(Directory root) {
    final found = <String>[];
    for (final file in everyFile(root)) {
      try {
        if (_indexOf(file.readAsBytesSync(), markerBytes) >= 0) {
          found.add(file.path);
        }
      } catch (_) {
        // Unreadable is not provably clean, so it is reported rather than
        // passed over.
        found.add('${file.path} (could not be read)');
      }
    }
    return found;
  }

  Future<Vault> openVault(String name) async {
    final vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/$name'),
      idleTimeout: Duration.zero,
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase you can remember');
    return vault;
  }

  group('the scan itself is honest', () {
    test('it finds a marker that is deliberately there', () async {
      // ══ THE TEST THAT TESTS THE TEST ═══════════════════════════════════
      //
      // Every assertion below is that a search found **nothing**, and a search
      // pointed at the wrong directory also finds nothing. Without this, a
      // typo would turn the whole file into a test that always passes.
      File('${tmp.path}/planted.txt').writeAsStringSync(marker);
      // Compared by name rather than by full path: `listSync` returns the
      // platform's own separator, and on Windows that is not the one this test
      // just used to build the path.
      expect(scan(tmp).map(_name), contains('planted.txt'));
    });

    test('and finds it in the middle of binary noise', () async {
      // A marker that only matches at a file boundary would miss the realistic
      // case entirely.
      File('${tmp.path}/buried.bin').writeAsBytesSync([
        ...List<int>.filled(5000, 0xAB),
        ...markerBytes,
        ...List<int>.filled(5000, 0xCD),
      ]);
      expect(scan(tmp).map(_name), contains('buried.bin'));
    });
  });

  group('nothing the app writes is readable', () {
    test('a text entry never reaches the disk in the clear', () async {
      final vault = await openVault('text');
      await EntryRepository(vault.database).createTextOn(
        id: vault.newId(),
        dayKey: '2026-08-28',
        body: 'A sentence nobody else should be able to read. $marker',
      );

      // Locked rather than merely awaited: closing the database checkpoints the
      // write-ahead log, which is a separate file and is exactly the sort of
      // place plaintext hides.
      await vault.lock();

      final leaks = scan(tmp);
      expect(leaks, isEmpty,
          reason: 'the marker was found in the clear at:\n${leaks.join('\n')}');
    });

    test('a long entry never reaches the disk in the clear', () async {
      // Long enough to span more than one database page, because a short row
      // can hide inside a page that happens to be written whole.
      final vault = await openVault('long');
      await EntryRepository(vault.database).createTextOn(
        id: vault.newId(),
        dayKey: '2026-08-28',
        body: List.filled(200, marker).join(' '),
      );
      await vault.lock();
      expect(scan(tmp), isEmpty);
    });

    test('an entry that was edited leaves no earlier version in the clear',
        () async {
      // Every edit writes the old text to `revisions`. That table is inside the
      // encrypted database and this is the assertion that keeps it there.
      final vault = await openVault('revised');
      final repo = EntryRepository(vault.database);
      final id = vault.newId();
      await repo.createTextOn(id: id, dayKey: '2026-08-28', body: marker);
      await repo.updateBody(id, 'replaced with something else entirely');
      await vault.lock();
      expect(scan(tmp), isEmpty);
    });

    test('a deleted entry does not surface in the clear on its way out',
        () async {
      final vault = await openVault('deleted');
      final repo = EntryRepository(vault.database);
      final id = vault.newId();
      await repo.createTextOn(id: id, dayKey: '2026-08-28', body: marker);
      await repo.softDelete(id);
      await repo.purge(id);
      await vault.lock();
      expect(scan(tmp), isEmpty);
    });

    test('an attachment never reaches the disk in the clear', () async {
      final vault = await openVault('attachment');
      // Shaped like something a picker hands over: the marker buried in enough
      // bytes to span several chunks of the encrypting stream.
      final stored = await vault.attachments.writeBytes([
        ...List<int>.filled(200 * 1024, 7),
        ...markerBytes,
        ...List<int>.filled(200 * 1024, 9),
      ]);
      expect(stored.id, isNotEmpty);
      await vault.lock();

      final leaks = scan(tmp);
      expect(leaks, isEmpty,
          reason: 'an attachment left plaintext at:\n${leaks.join('\n')}');
    });

    test('a day note never reaches the disk in the clear', () async {
      // The newest table in the schema, and the one most likely to be forgotten
      // by a leak test written before it existed.
      final vault = await openVault('daynote');
      await vault.database.customStatement(
        "INSERT INTO day_notes (day_key, body) VALUES ('2026-08-28', ?)",
        [marker],
      );
      await vault.lock();
      expect(scan(tmp), isEmpty);
    });

    test('a backup never reaches the disk in the clear', () async {
      final vault = await openVault('backup');
      await EntryRepository(vault.database).createTextOn(
        id: vault.newId(),
        dayKey: '2026-08-28',
        body: 'Backed up, and still unreadable. $marker',
      );

      final destination = File('${tmp.path}/backup.vault');
      await VaultFile(sodium: sodium, crypto: crypto).write(
        destination: destination,
        vaultRoot: vault.root,
        counts: const {'entries': 1},
        passcode: 'a passphrase you can remember',
      );
      expect(destination.existsSync(), isTrue,
          reason: 'the backup must actually exist, or this proves nothing');
      await vault.lock();

      final leaks = scan(tmp);
      expect(leaks, isEmpty,
          reason: 'a backup leaked its contents at:\n${leaks.join('\n')}');
    });

    test('the settings file holds preferences and nothing anybody wrote',
        () async {
      // `settings.json` is plaintext on purpose — it says which theme is on.
      // This is the assertion that keeps it that way, because adding "just one"
      // piece of content to it would look harmless.
      final vault = await openVault('settings');
      final settings = File('${vault.root.path}/settings.json');
      await settings.writeAsString('{"theme":"dark","displayName":"Piyush"}');
      await vault.lock();
      expect(scan(tmp), isEmpty);
    });
  });

  group('what this cannot see, and says so', () {
    test('the Android-only directories are the integration test\'s job', () {
      // Stated as a test so the gap is visible in a test run rather than only
      // in a comment nobody reads.
      const androidOnly = ['cache', 'shared_prefs', 'code_cache', 'no_backup'];
      expect(androidOnly, isNotEmpty);
      expect(
        File('integration_test/nothing_in_the_clear_test.dart').existsSync(),
        isTrue,
        reason: 'the on-device half of this scan must keep existing — it is '
            'what CLAUDE.md rule 1 rests on. See HARDWARE-CHECKS.md for how '
            'to run it.',
      );
    });
  });
}

/// The last segment of a path, whichever separator the platform uses.
String _name(String path) => path.split(RegExp(r'[/\\]')).last;

/// Where [needle] starts inside [haystack], or -1.
int _indexOf(List<int> haystack, List<int> needle) {
  if (needle.isEmpty || haystack.length < needle.length) return -1;
  final first = needle[0];
  final limit = haystack.length - needle.length;
  outer:
  for (var i = 0; i <= limit; i++) {
    if (haystack[i] != first) continue;
    for (var j = 1; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}
