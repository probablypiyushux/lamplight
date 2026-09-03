import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/platform/hand_off.dart';

/// **ISSUE 4 and 13 — the test the rule-2 exception was granted on.**
///
/// `CLAUDE.md` rule 2 is "no plaintext user content on disk. Ever." Handing a
/// file to another app breaks it, and Piyush lifted the rule for this one path
/// on 24 August 2026 on stated terms, which he quoted back:
///
/// > *"grant only the chosen app a one-time read, and delete it the moment you
/// > come back — plus a test proving nothing is left behind."*
///
/// This is that test. It is the reason the exception is allowed to exist, so it
/// is written to be hard to weaken: it does not check that a delete was
/// *called*, it goes and looks at the disk, and it looks for the **content**
/// rather than for the filename — because a file renamed or truncated but not
/// overwritten is still somebody's document sitting in a cache.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory cache;

  /// The bytes standing in for somebody's document. Distinctive, so a search of
  /// the whole directory tree cannot match them by accident.
  final secret = List<int>.generate(4096, (i) => (i * 31 + 7) % 251);

  setUp(() async {
    cache = Directory.systemTemp.createTempSync('lamplight_handoff');

    // `getTemporaryDirectory` and the two platform calls, all of which need a
    // real Android underneath and have none here.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async =>
          call.method == 'getTemporaryDirectory' ? cache.path : null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('lamplight/documents'),
      (call) async => switch (call.method) {
        // As if a chooser appeared and something took the file.
        'openWith' => true,
        'revokeHandOff' => null,
        _ => null,
      },
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('lamplight/documents'), null);
    if (cache.existsSync()) cache.deleteSync(recursive: true);
  });

  /// Every byte currently on disk anywhere under the cache.
  List<int> everythingOnDisk() {
    final bytes = <int>[];
    if (!cache.existsSync()) return bytes;
    for (final f in cache.listSync(recursive: true).whereType<File>()) {
      bytes.addAll(f.readAsBytesSync());
    }
    return bytes;
  }

  /// Named [holds] rather than `contains` because a local function of that name
  /// silently shadows the matcher of the same name, and the failure is a
  /// compile error a long way from the cause.
  bool holds(List<int> haystack, List<int> needle) {
    if (needle.isEmpty || haystack.length < needle.length) return false;
    for (var i = 0; i <= haystack.length - needle.length; i++) {
      var match = true;
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }
    return false;
  }

  test('while it is lent out, the file is there — and only in handoff/',
      () async {
    await HandOff.open(
      bytes: secret,
      name: 'tax return.pdf',
      mimeType: 'application/pdf',
    );

    final dir = await HandOff.directory();
    final files = dir.listSync().whereType<File>().toList();
    expect(files, hasLength(1), reason: 'exactly one file, exactly where the '
        'FileProvider path says it may be');
    expect(files.single.path, contains('handoff'));
    expect(holds(everythingOnDisk(), secret), isTrue,
        reason: 'the premise: it really is the plaintext on disk');
  });

  test('THE PROMISE: coming back destroys it', () async {
    await HandOff.open(
      bytes: secret,
      name: 'tax return.pdf',
      mimeType: 'application/pdf',
    );
    expect(holds(everythingOnDisk(), secret), isTrue);

    await HandOff.reclaim();

    expect(holds(everythingOnDisk(), secret), isFalse,
        reason: 'this assertion IS the exception to rule 2. If it ever fails, '
            '"Open with" must be taken out rather than argued about');
    final dir = await HandOff.directory();
    expect(dir.listSync().whereType<File>(), isEmpty);
  });

  test('a second loan does not strand the first', () async {
    // Open a file, background the app from inside the other app, come back
    // through recents and open another. Tracking only the most recent would
    // leave the first one on disk forever.
    final other = List<int>.generate(2048, (i) => (i * 17 + 3) % 253);
    await HandOff.open(bytes: secret, name: 'a.pdf', mimeType: 'application/pdf');
    await HandOff.open(bytes: other, name: 'b.pdf', mimeType: 'application/pdf');

    await HandOff.reclaim();

    final disk = everythingOnDisk();
    expect(holds(disk, secret), isFalse);
    expect(holds(disk, other), isFalse);
  });

  test('a file left by a killed process is destroyed at the next launch',
      () async {
    // The reclaim never ran: the process died while somebody else had the file.
    // The next launch finds it by sweeping the directory rather than by
    // consulting a list that died with the process.
    final dir = await HandOff.directory();
    File('${dir.path}/orphan.pdf').writeAsBytesSync(secret);
    expect(holds(everythingOnDisk(), secret), isTrue);

    await HandOff.reclaim();

    expect(holds(everythingOnDisk(), secret), isFalse,
        reason: 'the backstop has to work without any memory of what was lent');
  });

  test('a launch nothing could open leaves nothing behind either', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('lamplight/documents'),
      (call) async => call.method == 'openWith' ? false : null,
    );

    final opened = await HandOff.open(
      bytes: secret,
      name: 'mystery.xyz',
      mimeType: 'application/x-nonsense',
    );

    expect(opened, isFalse, reason: 'the caller has to be able to say so');
    expect(holds(everythingOnDisk(), secret), isFalse,
        reason: 'nothing was ever granted, so nothing should be waiting for a '
            'reclaim that may be minutes away');
  });

  test('a channel that throws still leaves nothing behind', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('lamplight/documents'),
      (call) async => throw PlatformException(code: 'boom'),
    );

    final opened = await HandOff.open(
      bytes: secret,
      name: 'x.pdf',
      mimeType: 'application/pdf',
    );

    expect(opened, isFalse);
    expect(holds(everythingOnDisk(), secret), isFalse);
  });

  test('reclaiming when nothing is out is not an error', () async {
    await HandOff.reclaim();
    await HandOff.reclaim();
  });

  group('the filename is never trusted', () {
    // It came from a picker, which got it from another app. It has never been
    // trusted and it does not start being trusted at the one point where it
    // becomes a path.
    for (final hostile in <String>[
      '../../../databases/vault.db',
      'a/b/c.pdf',
      r'..\..\secrets.txt',
      '',
      '.',
    ]) {
      test('"$hostile" cannot climb out of handoff/', () async {
        await HandOff.open(
          bytes: secret,
          name: hostile,
          mimeType: 'application/pdf',
        );

        final dir = await HandOff.directory();
        // Separators normalised: this directory is built by interpolation and
        // so uses forward slashes, while dart:io reports a parent path with the
        // platform's own separator. Comparing them raw fails on Windows for a
        // reason that has nothing to do with what is being tested.
        String flat(String path) => path.replaceAll(r'\', '/');
        for (final f in cache.listSync(recursive: true).whereType<File>()) {
          expect(flat(f.parent.path), flat(dir.path),
              reason: 'a file escaped to ${f.path}');
        }
        await HandOff.reclaim();
        expect(holds(everythingOnDisk(), secret), isFalse);
      });
    }
  });
}
