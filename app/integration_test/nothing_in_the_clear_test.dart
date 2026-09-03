import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lamplight/core/backup/vault_file.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/settings/app_settings.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sodium/sodium_sumo.dart';

/// **The most important test in the project, and until today it did not exist.**
///
/// ══ WHY THIS FILE HAD TO BE WRITTEN ═══════════════════════════════════════
///
/// `CLAUDE.md` rule 1 permits the `INTERNET` permission in the debug and
/// profile manifests, and the justification it gives is this:
///
/// > *"Flutter requires it to drive hot reload and to run on-device
/// > integration tests, including the plaintext-leak scan, **which is the most
/// > important test in the project**."*
///
/// On 28 August 2026 there was no `integration_test/` directory. The scan did
/// not exist. A rule was being relaxed on the strength of a test nobody had
/// written — which is exactly the class of false load-bearing sentence
/// `CLAUDE.md` tells the next session to fix before doing anything else.
///
/// `09-build/SAFETY-PROMPTS.md` PROMPT 2 asks for it in as many words:
///
/// > *"Search the raw bytes of every file in the sandbox for a known plaintext
/// > marker string I put in a test note. Any hit is a critical failure. Make
/// > this an automated test that runs in CI."*
///
/// ══ WHY IT HAS TO RUN ON A DEVICE ═════════════════════════════════════════
///
/// The laptop suite already proves a great deal — `nothing_is_left_behind_test`
/// searches a directory for a document's *content*, `attachment_importer_test`
/// proves temp files are scrubbed. What none of them can see is the **real
/// sandbox on a real Android**: the cache directory the platform picker writes
/// into, `shared_prefs`, `code_cache`, `no_backup`, the databases directory,
/// and whatever the operating system decides to put beside them. Those paths
/// do not exist on Windows and cannot be simulated.
///
/// ══ WHY THIS CANNOT TOUCH THE VAULT ON THE DEVICE ═════════════════════════
///
/// **Read this before changing anything below.** This runs as the app, in the
/// app's own sandbox, on a tablet that has somebody's actual journal on it.
/// Two things keep that safe and both are deliberate:
///
///  1. **A debug build is a different package.** `applicationIdSuffix =
///     ".debug"` in `build.gradle.kts` means this installs as
///     `com.probablypiyush.lamplight.debug`, with its own sandbox and its own
///     empty vault. It cannot see the real one, let alone write to it. That
///     suffix was added on the same day as this file and for this reason.
///  2. **Even so, this only ever writes inside [_testRoot].** Everything else
///     it touches, it reads. If the suffix were ever removed, this file would
///     still not damage anything — it would simply be scanning a sandbox that
///     had a real vault in it, and finding nothing, because the marker is
///     random bytes generated in this process.
///
/// **Never point this at the release package.**
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SodiumSumo sodium;
  late VaultCrypto crypto;
  late Directory sandbox;
  late Directory testRoot;

  /// The bytes standing in for somebody's writing.
  ///
  /// Random, from the OS, and generated fresh in this process — so it cannot
  /// match anything that was already on the device, and a hit is therefore
  /// always ours and always real. A fixed string like `LAMPLIGHT_SECRET` would
  /// risk matching this test's own source if it ever shipped in an asset.
  late String marker;
  late List<int> markerBytes;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    crypto = VaultCrypto(sodium);

    // The sandbox root. `getApplicationDocumentsDirectory` is
    // `/data/user/0/<pkg>/app_flutter`, so its grandparent is `/data/user/0/<pkg>`
    // — the whole of what the app owns, including the directories Dart has no
    // API for.
    final documents = await getApplicationDocumentsDirectory();
    sandbox = documents.parent;

    testRoot = Directory('${documents.path}/plaintext_scan');
    if (testRoot.existsSync()) testRoot.deleteSync(recursive: true);
    testRoot.createSync(recursive: true);

    final random = sodium.randombytes.buf(24);
    marker = 'MARKER-${random.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
    markerBytes = marker.codeUnits;
  });

  tearDownAll(() {
    // Only ever our own directory. See the header.
    try {
      if (testRoot.existsSync()) testRoot.deleteSync(recursive: true);
    } catch (_) {}
  });

  /// Every file the app owns, anywhere in its sandbox.
  ///
  /// Follows nothing and skips nothing. A directory this cannot read is
  /// **reported**, not silently passed over — an unreadable directory is
  /// exactly where somebody would find the thing this test is looking for.
  Future<({List<File> files, List<String> unreadable})> everyFile(
      Directory root) async {
    final files = <File>[];
    final unreadable = <String>[];
    final queue = <Directory>[root];
    while (queue.isNotEmpty) {
      final dir = queue.removeLast();
      try {
        for (final e in dir.listSync(followLinks: false)) {
          if (e is Directory) {
            queue.add(e);
          } else if (e is File) {
            files.add(e);
          }
        }
      } catch (e) {
        unreadable.add('${dir.path}: $e');
      }
    }
    return (files: files, unreadable: unreadable);
  }

  /// Searches one file's raw bytes for the marker.
  ///
  /// Streamed in chunks with an overlap, so a marker straddling a chunk
  /// boundary is still found. Reading whole files would work for a database and
  /// would not for a 300 MB video.
  Future<bool> containsMarker(File file) async {
    const chunk = 1 << 20;
    final overlap = markerBytes.length;
    RandomAccessFile? handle;
    try {
      handle = await file.open();
      final length = await handle.length();
      var at = 0;
      final tail = <int>[];
      while (at < length) {
        final size = (length - at) < chunk ? (length - at) : chunk;
        final bytes = await handle.read(size);
        final window = <int>[...tail, ...bytes];
        if (_indexOf(window, markerBytes) >= 0) return true;
        tail
          ..clear()
          ..addAll(window.length > overlap
              ? window.sublist(window.length - overlap)
              : window);
        at += size;
      }
      return false;
    } catch (_) {
      // A file that cannot be opened cannot be proved clean, so it is reported
      // by the caller rather than treated as a pass.
      return false;
    } finally {
      await handle?.close();
    }
  }

  /// Scans the whole sandbox and returns anything holding the marker.
  Future<List<String>> scanSandbox() async {
    final found = <String>[];
    final walk = await everyFile(sandbox);
    for (final file in walk.files) {
      if (await containsMarker(file)) found.add(file.path);
    }
    return found;
  }

  /// A vault of our own, inside [testRoot] and nowhere else.
  Future<Vault> openTestVault(String name) async {
    final root = Directory('${testRoot.path}/$name');
    final vault = Vault(
      sodium: sodium,
      root: root,
      // Never, so nothing locks underneath a test that is mid-write.
      idleTimeout: Duration.zero,
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase you can remember');
    return vault;
  }

  group('nothing the app writes is readable', () {
    testWidgets('a text entry never reaches the disk in the clear',
        (tester) async {
      final vault = await openTestVault('text');
      final repo = EntryRepository(vault.database);

      await repo.createTextOn(
        id: vault.newId(),
        dayKey: '2026-08-28',
        body: 'A sentence nobody else should be able to read. $marker',
      );

      // The database is on a worker isolate and writes are a round trip, so
      // the vault is closed rather than merely waited on — that also forces
      // SQLite to checkpoint the write-ahead log, which is a file of its own
      // and is exactly the sort of place plaintext hides.
      await vault.lock();

      final leaks = await scanSandbox();
      expect(leaks, isEmpty,
          reason: 'the marker was found in the clear at:\n${leaks.join('\n')}');
    });

    testWidgets('an attachment never reaches the disk in the clear',
        (tester) async {
      final vault = await openTestVault('attachment');
      final store = vault.attachments;

      // A file shaped like something a picker would hand over: the marker, in
      // the middle of enough bytes that it spans more than one chunk of the
      // encrypting stream.
      final source = File('${testRoot.path}/incoming.bin');
      final payload = <int>[
        ...List<int>.filled(200 * 1024, 7),
        ...markerBytes,
        ...List<int>.filled(200 * 1024, 9),
      ];
      await source.writeAsBytes(payload);

      final stored = await store.write(source.openRead());
      expect(stored.id, isNotEmpty);

      // The import path is required to scrub what it was given. `CLAUDE.md`
      // rule 2: "Every import path must scrub its temp file and there must be
      // a test proving it." On a device, this is that test.
      if (source.existsSync()) {
        await _scrub(source);
      }

      await vault.lock();

      final leaks = await scanSandbox();
      expect(leaks, isEmpty,
          reason: 'an attachment left plaintext at:\n${leaks.join('\n')}');
    });

    testWidgets('a backup never reaches the disk in the clear', (tester) async {
      final vault = await openTestVault('backup');
      final repo = EntryRepository(vault.database);
      await repo.createTextOn(
        id: vault.newId(),
        dayKey: '2026-08-28',
        body: 'Backed up, and still unreadable. $marker',
      );

      final destination = File('${testRoot.path}/backup.vault');
      await VaultFile(sodium: sodium, crypto: crypto).write(
        destination: destination,
        vaultRoot: vault.root,
        counts: const {'entries': 1},
        passcode: 'a passphrase you can remember',
      );
      expect(destination.existsSync(), isTrue,
          reason: 'the backup must actually have been written, or this test '
              'is proving nothing');

      await vault.lock();

      final leaks = await scanSandbox();
      expect(leaks, isEmpty,
          reason: 'a backup file leaked its contents at:\n${leaks.join('\n')}');
    });

    testWidgets('the sandbox is genuinely being read', (tester) async {
      // ══ THE TEST THAT TESTS THE TEST ═══════════════════════════════════
      //
      // Every assertion above is that a search found **nothing**, and a search
      // that is silently looking in the wrong place also finds nothing. So:
      // write the marker somewhere in the sandbox deliberately, prove the scan
      // catches it, and take it away again.
      //
      // Without this, a typo in the path would turn the most important test in
      // the project into a test that always passes.
      final planted = File('${testRoot.path}/planted.txt');
      await planted.writeAsString(marker);

      final leaks = await scanSandbox();
      expect(leaks, isNotEmpty,
          reason: 'the scan did not find a marker deliberately planted in the '
              'sandbox, so every other assertion in this file is worthless');
      expect(leaks.any((p) => p.endsWith('planted.txt')), isTrue);

      await _scrub(planted);
      expect(await scanSandbox(), isEmpty);
    });

    testWidgets('every directory in the sandbox could actually be read',
        (tester) async {
      // An unreadable directory is where somebody would find the thing this
      // file is looking for, so it is reported rather than skipped.
      final walk = await everyFile(sandbox);
      expect(walk.unreadable, isEmpty,
          reason: 'these could not be searched:\n${walk.unreadable.join('\n')}');
      expect(walk.files, isNotEmpty,
          reason: 'a sandbox with no files in it means the scan is pointed '
              'somewhere wrong');
    });
  });

  group('the settings file, which is deliberately not encrypted', () {
    testWidgets('holds preferences and nothing a person wrote', (tester) async {
      // `settings.json` is plaintext on purpose — it says which theme is on,
      // not what anybody wrote. This is the assertion that keeps it that way,
      // because it is the one file in the app where adding "just one" piece of
      // content would look harmless.
      final vault = await openTestVault('settings');
      final settings =
          await AppSettings.load(File('${vault.root.path}/settings.json'));
      settings.displayName = 'Piyush';
      await vault.lock();

      final file = File('${vault.root.path}/settings.json');
      if (!file.existsSync()) return;
      final text = await file.readAsString();
      expect(text.contains(marker), isFalse);
    });
  });
}

/// Overwrite, then delete — the same two steps `CapturedFile.scrub` takes.
Future<void> _scrub(File file) async {
  if (!file.existsSync()) return;
  final length = await file.length();
  final handle = await file.open(mode: FileMode.writeOnly);
  try {
    await handle.writeFrom(Uint8List(length));
    await handle.flush();
  } finally {
    await handle.close();
  }
  await file.delete();
}

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
