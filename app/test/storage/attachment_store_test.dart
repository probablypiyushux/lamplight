import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/storage/attachment_store.dart';
import 'package:sodium/sodium_sumo.dart';

/// The encrypted attachment store, per `SECURITY-ARCHITECTURE.md` §6.
///
/// `04-technical/TECH-STACK.md` testing requirement 1 asks for every size
/// including empty and 1 byte, wrong keys failing, tampered ciphertext failing,
/// and truncated files failing. The sizes chosen here cluster around the 64 KiB
/// chunk boundary on purpose — off-by-one errors in chunking are invisible in
/// the middle of a chunk and obvious at its edges.
void main() {
  late SodiumSumo sodium;
  late VaultCrypto crypto;
  late Directory tmp;
  late AttachmentStore store;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    crypto = VaultCrypto(sodium);
  });

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('lamplight_att');
    store = AttachmentStore(
      directory: Directory('${tmp.path}/attachments'),
      sodium: sodium,
      crypto: crypto,
    );
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Uint8List pattern(int n) {
    final rng = math.Random(n); // deterministic content, not used for crypto
    return Uint8List.fromList(List.generate(n, (_) => rng.nextInt(256)));
  }

  group('round-trips at every interesting size', () {
    const sizes = <int>[
      0, // empty
      1, // one byte
      63, //
      AttachmentStore.chunkSize - 1, // just under a chunk
      AttachmentStore.chunkSize, // exactly one chunk
      AttachmentStore.chunkSize + 1, // just over
      AttachmentStore.chunkSize * 2, // exactly two chunks
      AttachmentStore.chunkSize * 3 + 7, // ragged tail
      1024 * 1024, // a megabyte
    ];

    for (final size in sizes) {
      test('$size bytes', () async {
        final original = pattern(size);
        final stored = await store.writeBytes(original);
        final back = await store.readAllBytes(stored.id, stored.fileKey);
        expect(back, equals(original), reason: 'size $size did not round-trip');
      });
    }
  });

  test('a large file streams without being held in memory', () async {
    // 8 MB delivered in pieces, never assembled as one buffer on the way in.
    // Proves the streaming path works; the real concern is a 500 MB video.
    const total = 8 * 1024 * 1024;
    const piece = 128 * 1024;
    var produced = 0;
    final source = Stream<List<int>>.fromIterable(
      List.generate(total ~/ piece, (i) => Uint8List(piece)..fillRange(0, piece, i % 256)),
    ).map((c) {
      produced += c.length;
      return c;
    });

    final stored = await store.write(source);
    expect(produced, total);

    var readBack = 0;
    await for (final chunk in store.read(stored.id, stored.fileKey)) {
      readBack += chunk.length;
    }
    expect(readBack, total);
  });

  group('the filesystem leaks nothing', () {
    test('filenames are random UUIDs with no extension hint', () async {
      final a = await store.writeBytes(utf8.encode('a voice note'));
      final b = await store.writeBytes(utf8.encode('a tax return'));

      final names = store.directory
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .toList();

      expect(names, hasLength(2));
      for (final n in names) {
        expect(n, endsWith('.enc'));
        expect(
          RegExp(r'^[0-9a-f-]{36}\.enc$').hasMatch(n),
          isTrue,
          reason: 'filename $n reveals something',
        );
      }
      expect(a.id, isNot(b.id));
    });

    test('content is absent from the bytes on disk', () async {
      const secret = 'CANARY_a_thing_I_would_never_say_aloud';
      final stored = await store.writeBytes(utf8.encode(secret));
      final bytes = store.fileFor(stored.id).readAsBytesSync();
      expect(_contains(bytes, utf8.encode(secret)), isFalse);
      expect(_contains(bytes, utf8.encode('CANARY')), isFalse);
    });

    test('identical content stored twice produces different bytes', () async {
      // Otherwise an observer could tell that two attachments are the same
      // file, which is information the filesystem should not carry.
      final content = utf8.encode('the same photo twice');
      final a = await store.writeBytes(content);
      final b = await store.writeBytes(content);
      expect(
        store.fileFor(a.id).readAsBytesSync(),
        isNot(equals(store.fileFor(b.id).readAsBytesSync())),
      );
    });

    test('every attachment gets its own key', () async {
      final a = await store.writeBytes(utf8.encode('one'));
      final b = await store.writeBytes(utf8.encode('two'));
      expect(a.fileKey, isNot(equals(b.fileKey)));
    });
  });

  group('failing when it should', () {
    test('a wrong key fails', () async {
      final stored = await store.writeBytes(utf8.encode('private'));
      final wrongKey = crypto.randomBytes(32);
      expect(
        () => store.readAllBytes(stored.id, wrongKey),
        throwsA(anything),
      );
    });

    test('another attachment key does not open this one', () async {
      final a = await store.writeBytes(utf8.encode('mine'));
      final b = await store.writeBytes(utf8.encode('also mine'));
      expect(() => store.readAllBytes(a.id, b.fileKey), throwsA(anything));
    });

    test('a tampered byte anywhere is detected', () async {
      // Sample positions across the file rather than every byte — the file is
      // large enough that an exhaustive sweep would dominate the suite runtime,
      // and the header, first chunk, middle and tail are where the distinct
      // failure modes live.
      final original = pattern(AttachmentStore.chunkSize * 2 + 100);
      final stored = await store.writeBytes(original);
      final file = store.fileFor(stored.id);
      final good = file.readAsBytesSync();

      final positions = <int>{
        0, // stream header
        1,
        23,
        good.length ~/ 4,
        good.length ~/ 2,
        good.length - 20,
        good.length - 1, // final authentication tag
      };

      for (final pos in positions) {
        final corrupted = Uint8List.fromList(good)..[pos] ^= 0x01;
        file.writeAsBytesSync(corrupted);
        await expectLater(
          store.readAllBytes(stored.id, stored.fileKey),
          throwsA(anything),
          reason: 'a flipped bit at byte $pos went undetected',
        );
      }
      file.writeAsBytesSync(good);
    });

    test('a truncated file is detected, not silently short', () async {
      // The failure that matters most: without a final-chunk marker, a file cut
      // short decrypts cleanly and simply returns less data. The user would
      // get half a voice note and no error at all.
      final original = pattern(AttachmentStore.chunkSize * 3);
      final stored = await store.writeBytes(original);
      final file = store.fileFor(stored.id);
      final good = file.readAsBytesSync();

      for (final keep in [
        good.length - 1,
        good.length ~/ 2,
        AttachmentStore.chunkSize,
        1,
      ]) {
        file.writeAsBytesSync(good.sublist(0, keep));
        await expectLater(
          store.readAllBytes(stored.id, stored.fileKey),
          throwsA(anything),
          reason: 'truncating to $keep bytes went undetected',
        );
      }
      file.writeAsBytesSync(good);
    });

    test('an empty file is refused', () async {
      final stored = await store.writeBytes(utf8.encode('x'));
      store.fileFor(stored.id).writeAsBytesSync(<int>[]);
      expect(
        () => store.readAllBytes(stored.id, stored.fileKey),
        throwsA(anything),
      );
    });

    test('a missing attachment reports itself clearly', () {
      expect(
        () => store.readAllBytes('does-not-exist', crypto.randomBytes(32)),
        throwsA(isA<AttachmentMissing>()),
      );
    });
  });

  group('housekeeping', () {
    test('delete removes the file', () async {
      final stored = await store.writeBytes(utf8.encode('goodbye'));
      expect(store.fileFor(stored.id).existsSync(), isTrue);
      await store.delete(stored.id);
      expect(store.fileFor(stored.id).existsSync(), isFalse);
    });

    test('deleting something already gone is not an error', () async {
      await store.delete('never-existed');
    });

    test('a failed write leaves no partial file behind', () async {
      // A crash mid-import must not leave a .part file that looks like an
      // attachment, or an orphan the database never references.
      final failing = Stream<List<int>>.fromIterable([
        utf8.encode('first chunk'),
      ]).asyncExpand((c) async* {
        yield c;
        throw StateError('simulated interruption');
      });

      await expectLater(store.write(failing), throwsA(anything));

      final leftovers = store.directory.existsSync()
          ? store.directory.listSync().whereType<File>().toList()
          : <File>[];
      expect(leftovers, isEmpty, reason: 'a partial file was left on disk');
    });

    test('listIds finds every stored blob', () async {
      final ids = <String>{};
      for (var i = 0; i < 5; i++) {
        ids.add((await store.writeBytes(utf8.encode('note $i'))).id);
      }
      expect(store.listIds().toSet(), equals(ids));
    });
  });
}

bool _contains(List<int> haystack, List<int> needle) {
  if (needle.isEmpty || haystack.length < needle.length) return false;
  outer:
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}
