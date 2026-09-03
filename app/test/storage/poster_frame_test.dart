import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/platform/capture.dart';
import 'package:lamplight/core/storage/attachment_importer.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:sodium/sodium_sumo.dart';

/// ISSUE 8 — the poster frame, from import to deletion.
///
/// A video's thumbnail is a **second attachment row that no entry points at**.
/// That is the cheap way to do it — it reuses the encrypted store, the file
/// keys and the random-UUID naming rather than inventing a thumbnail cache —
/// and it introduces exactly one new way to be wrong: an attachment that
/// nothing owns can be left behind when the thing it belongs to goes.
///
/// So this file is mostly about deletion, for the same reason
/// `attachment_importer_test.dart` is mostly about failure. `PLAN.md` §11
/// test 7: ask what the second one does.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SodiumSumo sodium;
  late Directory tmp;
  late Vault vault;
  late AttachmentImporter importer;
  late EntryRepository repo;

  final channel = const MethodChannel('lamplight/documents');

  /// Stands in for what `MediaInfo.kt` returns for a video.
  final posterBytes = Uint8List.fromList(List.generate(2048, (i) => i % 256));

  /// And for an audio file. **ISSUE 2** — 96 amplitude bytes, decoded natively
  /// at import for a file that arrived from somewhere else.
  final waveBytes = Uint8List.fromList(List.generate(96, (i) => (i * 5) % 256));

  /// What the native side was actually asked to look at, so a test can assert
  /// the importer classified the file before probing it. The 0:00 bug was
  /// exactly this argument being wrong.
  final probed = <String>[];

  setUpAll(() async => sodium = await SodiumSumoInit.init());

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lamplight_poster');
    vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: const Duration(hours: 1),
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase');
    importer = AttachmentImporter(vault);
    repo = EntryRepository(vault.database, attachments: vault.attachments);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'mediaInfo') return null;
      // ISSUE 2. This was a `poster` boolean, which is why everything that was
      // not a video — audio included — went down the still-picture path and
      // came back with nothing at all.
      final kind = (call.arguments as Map)['kind'] as String? ?? 'photo';
      probed.add(kind);
      return switch (kind) {
        'video' => <String, Object?>{
            'width': 1080,
            'height': 1920,
            'durationMs': 8200,
            'poster': posterBytes,
          },
        'voice' => <String, Object?>{
            'durationMs': 41500,
            'waveform': waveBytes,
          },
        _ => <String, Object?>{'width': 4032, 'height': 3024},
      };
    });
  });

  tearDown(() async {
    probed.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await vault.lock();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  Future<String> importFile(String name, String mime) async {
    final file = File('${tmp.path}/$name');
    await file.writeAsBytes(List.generate(4096, (i) => i % 251));
    return importer.importCaptured(
      captured: CapturedFile(file: file, name: name, mimeType: mime),
      dayKey: EntryRepository.dayKeyFor(DateTime.now()),
    );
  }

  Future<Attachment?> attachmentOf(String entryId) async {
    final entry = await repo.entryById(entryId);
    return entry == null ? null : importer.attachmentFor(entry);
  }

  test('a video arrives with a poster frame, its length and its shape',
      () async {
    final entryId = await importFile('clip.mp4', 'video/mp4');
    final a = await attachmentOf(entryId);

    expect(a, isNotNull);
    expect(a!.thumbnailId, isNotNull, reason: 'ISSUE 8, in one assertion');
    expect(a.durationMs, 8200);
    // Portrait, because MediaInfo applied the recorded rotation. Without it
    // every clip shot upright would be drawn on its side.
    expect(a.width, 1080);
    expect(a.height, 1920);
  });

  test('the poster is encrypted like everything else, not a plaintext JPEG',
      () async {
    final entryId = await importFile('clip.mp4', 'video/mp4');
    final a = await attachmentOf(entryId);
    final poster = await importer.attachmentById(a!.thumbnailId!);

    expect(poster, isNotNull);
    // It reads back byte for byte through the store, so it really is in there.
    expect(await importer.bytesOf(poster!), posterBytes);

    // And it is nowhere on disk in the clear. The blob's name is a random UUID
    // with no extension, so this looks for the *content* rather than the name.
    final needle = posterBytes.sublist(64, 320);
    for (final f in vault.root.listSync(recursive: true).whereType<File>()) {
      final bytes = await f.readAsBytes();
      expect(_contains(bytes, needle), isFalse,
          reason: 'a plaintext poster frame is on disk at ${f.path}');
    }
  });

  test('a photograph gets its dimensions, which the album grid needs and never had',
      () async {
    final entryId = await importFile('holiday.jpg', 'image/jpeg');
    final a = await attachmentOf(entryId);

    expect(a!.width, 4032);
    expect(a.height, 3024);
    // A photo has no poster of its own — it *is* the picture.
    expect(a.thumbnailId, isNull);
  });

  // ── ISSUE 2 — the imported audio file ──────────────────────────────────
  //
  // "If audio from anywhere else is added, there is no voice waveform!" and,
  // pointing at the same player, "WTF is this 0:00 — obviously that audio is
  // not 0:00 cause that plays!"
  //
  // Both were one fault: the importer told the native side to probe every
  // non-video as a still picture, so an MP3 was handed to BitmapFactory and
  // came back with nothing. No duration, hence 0:00. No shape, hence flat.

  test('an audio file is probed AS AUDIO, which is the whole of the 0:00 bug',
      () async {
    await importFile('interview.m4a', 'audio/mp4');
    expect(probed, ['voice'],
        reason: 'the importer must tell the native side what kind of file '
            'this is; asking "is it a video?" is what caused ISSUE 2');
  });

  test('an imported voice note arrives knowing how long it is', () async {
    final entryId = await importFile('interview.m4a', 'audio/mp4');
    final a = await attachmentOf(entryId);

    expect(a, isNotNull);
    expect(a!.durationMs, 41500,
        reason: 'a note that plays for 41 seconds must not display 0:00');
  });

  test('and it arrives with a real waveform, not a flat bar', () async {
    final entryId = await importFile('interview.m4a', 'audio/mp4');
    final a = await attachmentOf(entryId);

    expect(a!.waveform, isNotNull);
    expect(a.waveform!.length, 96,
        reason: 'the same 96 bytes the live recorder writes, so the painter '
            'cannot tell an import from a recording');
    expect(a.waveform, waveBytes);
  });

  test('a file the decoder could not read keeps its length and loses only '
      'the picture', () async {
    // The native side returns a duration but no waveform — a format it can
    // time but not decode. The note must still import, and must still know
    // how long it is.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'mediaInfo') return null;
      return <String, Object?>{'durationMs': 9000};
    });

    final entryId = await importFile('odd.opus', 'audio/opus');
    final a = await attachmentOf(entryId);

    expect(a!.durationMs, 9000);
    expect(a.waveform, isNull,
        reason: 'an honest flat bar, never an invented one');
  });

  test('the player writes down a duration it learns, but never overwrites one',
      () async {
    // An old note: nothing probed audio when it was imported, so it has no
    // stored duration and its row reads "--:--" rather than a made-up 0:00.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
    final oldEntry = await importFile('from_before.m4a', 'audio/mp4');
    final old = await attachmentOf(oldEntry);
    expect(old!.durationMs, isNull);

    // Playing it teaches the app how long it is, once.
    await importer.learnDuration(old.id, 41500);
    expect((await importer.attachmentById(old.id))!.durationMs, 41500);

    // And a second, different report does not get to rewrite it.
    await importer.learnDuration(old.id, 12345);
    expect((await importer.attachmentById(old.id))!.durationMs, 41500,
        reason: 'a value that rewrites itself on every play is a value '
            'nobody can reason about');
  });

  test('deleting the video takes the poster with it', () async {
    final entryId = await importFile('clip.mp4', 'video/mp4');
    final a = await attachmentOf(entryId);
    final posterId = a!.thumbnailId!;

    await repo.purge(entryId);

    // The row is gone…
    final rows = await vault.database.select(vault.database.attachments).get();
    expect(rows.where((r) => r.id == posterId), isEmpty);
    expect(rows.where((r) => r.id == a.id), isEmpty);

    // …and so is the blob. An orphan here is not a leak — it is encrypted with
    // a key that was just deleted — but it is space nothing will ever reclaim,
    // and it would travel in every backup for the rest of the vault's life.
    expect(
      vault.attachments.fileFor(posterId).existsSync(),
      isFalse,
      reason: 'the poster blob outlived the video it belonged to',
    );
  });

  test('an import whose thumbnail fails still keeps the video', () async {
    // The platform is entitled to fail: no decoder, a corrupt header, an OOM
    // on a huge frame. Losing somebody's video because the *decoration* failed
    // would be the app protecting a picture at the cost of a memory.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'boom');
    });

    final entryId = await importFile('clip.mp4', 'video/mp4');
    final a = await attachmentOf(entryId);

    expect(a, isNotNull);
    expect(a!.thumbnailId, isNull);
    expect(await repo.entryById(entryId), isNotNull);
  });
}

bool _contains(List<int> haystack, List<int> needle) {
  if (needle.isEmpty || haystack.length < needle.length) return false;
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    var ok = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}
