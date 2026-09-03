import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/backup/vault_file.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/storage/attachment_store.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ISSUE 2, round nine.** Every backup in the app failed, by hand and
/// automatically, and this is the test that says it cannot happen again.
///
/// WHAT WENT WRONG, IN ONE PARAGRAPH
///
/// `Isolate.run` copies the callback it is given, which means it copies
/// everything the callback's *context* holds. A Dart closure does not get a
/// context to itself: closures written in the same function **share** one, and
/// the whole of it travels whether the worker reads any of it or not.
/// `writeOffThread` had two closures — the isolate body, and the little handler
/// that watches for progress and answers with a cancel. The handler touches
/// `isCancelled`, and the backup screen's `isCancelled` is `() =>
/// _cancelRequested`: a closure over a `State`. So the copy reached the State,
/// then its element, then the widget tree, then `LamplightApp`, then `Vault` —
/// and `Vault` holds `_idleTimer`. A `Timer` cannot cross an isolate boundary,
/// and the whole thing died with a page and a half of retaining path.
///
/// WHY 877 TESTS SAID IT WORKED
///
/// The existing cancellation test passes `isCancelled: () => started`, closing
/// over a plain `bool`. A `bool` is sendable. **The tests were not wrong about
/// what they tested — they tested a closure nobody would ever write on a
/// screen.** So the tests here do the opposite: they close over something
/// deliberately unsendable, which is what the real callers do by accident.
///
/// If either of these ever fails again, the fix is not to make the object
/// sendable. It is to check that the isolate body is still built by a `static`
/// method, because a static method has no enclosing context to share.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;

  setUpAll(() async => sodium = await SodiumSumoInit.init());
  setUp(() => tmp = Directory.systemTemp.createTempSync('lamplight_isolate'));
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  const passcode = 'a passphrase you can remember';

  Future<Directory> fakeVault() async {
    final root = Directory('${tmp.path}/vault')..createSync(recursive: true);
    File('${root.path}/keyring.json').writeAsStringSync('{"version":1}');
    // Incompressible, so the body really spans several 64 KiB chunks and the
    // progress listener — the closure that caused all this — actually runs.
    final rng = math.Random(42);
    File('${root.path}/vault.db').writeAsBytesSync(
      Uint8List.fromList(List.generate(300000, (_) => rng.nextInt(256))),
    );
    return root;
  }

  /// Stands in for `Vault`: an object holding a live `Timer`, which is the
  /// specific thing the VM refuses to copy. Everything a real screen drags
  /// along — the State, the element, the widget tree — ends here.
  ///
  /// Deliberately **not** a mock of `Vault`. The test should keep failing for
  /// the right reason even if `Vault` stops holding a timer one day; what is
  /// being tested is that the worker carries nothing at all, not that it
  /// tolerates one particular field.
  final unsendable = _HoldsATimer();
  tearDownAll(unsendable.dispose);

  test('a backup finishes even when the caller\'s callbacks hold the app',
      () async {
    final root = await fakeVault();
    final file = File('${tmp.path}/held.vault');
    final format = VaultFile(sodium: sodium, crypto: VaultCrypto(sodium));
    final key = await format.deriveBackupKey(passcode);

    try {
      // Both callbacks reach the timer, exactly as the backup screen's did.
      // Before the fix this threw:
      //   Illegal argument in isolate message: object is unsendable —
      //   Library:'dart:isolate' Class: _Timer
      final summary = await format.writeOffThread(
        destination: file,
        key: key,
        vaultRoot: root,
        counts: const {'entry_count': 1},
        onProgress: (_) => unsendable.touch(),
        isCancelled: () => unsendable.cancelled,
      );

      expect(summary.byteSize, await file.length());
      expect(unsendable.touched, isTrue,
          reason: 'the progress closure never ran, so this proved nothing');
    } finally {
      key.dispose();
    }

    // And the file is real, not merely written: it opens with nothing but the
    // passcode, the way a restore on a new phone would.
    final staging = Directory('${tmp.path}/staging');
    await format.extract(source: file, passcode: passcode, staging: staging);
    expect(
      await File('${staging.path}/vault.db').readAsBytes(),
      equals(await File('${root.path}/vault.db').readAsBytes()),
    );
  });

  test('the verify worker carries nothing either', () async {
    final root = await fakeVault();
    final file = File('${tmp.path}/verified.vault');
    final format = VaultFile(sodium: sodium, crypto: VaultCrypto(sodium));
    final key = await format.deriveBackupKey(passcode);

    try {
      await format.writeOffThread(
        destination: file,
        key: key,
        vaultRoot: root,
        counts: const {},
      );
      // Verify has no callbacks to be careless with, so this is a guard rather
      // than a reproduction: it fails the day somebody adds one.
      await format.verifyOffThread(
        source: file,
        key: key,
        scratch: Directory('${tmp.path}/scratch'),
      );
    } finally {
      key.dispose();
    }
  });

  test('an attachment import reports progress without carrying the caller',
      () async {
    final store = AttachmentStore(
      directory: Directory('${tmp.path}/blobs'),
      sodium: sodium,
      crypto: VaultCrypto(sodium),
    );

    final rng = math.Random(7);
    final bytes =
        Uint8List.fromList(List.generate(400000, (_) => rng.nextInt(256)));

    final seen = <int>[];
    final stored = await store.writeBytesOffThread(
      bytes,
      // ISSUE 12's progress callback is the sibling closure that would have
      // reintroduced ISSUE 2, so it reaches the timer on purpose.
      onProgress: (n) {
        unsendable.touch();
        seen.add(n);
      },
    );

    expect(seen, isNotEmpty, reason: 'no progress was reported at all');
    // Sealed bytes only ever grow, and end at the size of the finished blob.
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i], greaterThan(seen[i - 1]));
    }
    expect(seen.last, stored.cipherBytes);

    expect(
      await store.readAllBytesOffThread(stored.id, stored.fileKey),
      equals(bytes),
    );
  });
}

class _HoldsATimer {
  _HoldsATimer() {
    // Long enough that it is still armed for the whole suite, and harmless if
    // it ever fires.
    _timer = Timer(const Duration(minutes: 30), () {});
  }

  late final Timer _timer;
  bool touched = false;
  bool cancelled = false;

  void touch() => touched = true;
  void dispose() => _timer.cancel();
}
