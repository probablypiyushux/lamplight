import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/platform/document_store.dart';

/// **ROUND FIFTEEN, ISSUE 2 — "I AM UNABLE TO CHOOSE FOLDER".**
///
/// > *"A FEATURE IS BROKEN - WHEN AUTOMATIC BACKUP IS NEEDED OR READABLE COPY
/// > OR BRING IN A OLD FOLDER - CHOOSE FOLDER OPTION IS GIVEN THAT IS BROKEN!
/// > I AM UNABLE TO CHOOSE FOLDER"*
///
/// Three screens, one call, and two separate faults that added up to "nothing
/// happens".
///
/// **The platform fault** is in `MainActivity.kt` and cannot be tested from
/// here: the grant was persisted with hard-coded `READ or WRITE` rather than
/// with the flags the picker actually returned, and
/// `takePersistableUriPermission` throws when you ask to persist a mode you
/// were not given. MIUI's document provider hands back read-only trees for
/// some locations, so the call threw, the folder was never kept, and the
/// screen went back to how it looked before.
///
/// **The Dart fault is here**, and it is why it looked like nothing rather
/// than like a failure: the answer is now a pair — the URI *and* whether it
/// can be written to — and every screen has to handle a folder it may only
/// read. This file pins the decoding of that pair, including the cases a
/// document provider is entitled to produce and the old code would have
/// crashed or lied about.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('lamplight/documents');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Object? reply;
  Object? thrown;
  String? asked;

  setUp(() {
    reply = null;
    thrown = null;
    asked = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      asked = call.method;
      if (thrown != null) throw thrown!;
      return reply;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('a folder that can be written to comes back writable', () async {
    reply = <String, Object?>{
      'uri': 'content://com.android.externalstorage.documents/tree/primary%3ADownload',
      'writable': true,
    };
    final chosen = await DocumentStore.pickFolder();
    expect(asked, 'pickBackupFolder');
    expect(chosen, isNotNull);
    expect(chosen!.writable, isTrue);
    expect(chosen.uri, contains('primary%3ADownload'));
  });

  test('a read-only folder comes back, and says so', () async {
    // The case that broke everything. A document provider is entitled to grant
    // read and not write. That is a fine answer for "Bring in an old journal"
    // and a useless one for a backup — so it has to arrive rather than throw,
    // and the screen decides what to do with it.
    reply = <String, Object?>{'uri': 'content://tree/readonly', 'writable': false};
    final chosen = await DocumentStore.pickFolder();
    expect(chosen, isNotNull);
    expect(chosen!.writable, isFalse,
        reason: 'accepting this silently is what turned the switch on and then '
            'failed at every backup from then on');
  });

  test('backing out is null, and is not an error', () async {
    reply = null;
    expect(await DocumentStore.pickFolder(), isNull);
  });

  test('a reply with no usable URI is treated as backing out', () async {
    // Defensive rather than expected: an OEM provider that answers the intent
    // with an empty result should not produce a stored folder of "".
    reply = <String, Object?>{'uri': '', 'writable': true};
    expect(await DocumentStore.pickFolder(), isNull);
    reply = <String, Object?>{'writable': true};
    expect(await DocumentStore.pickFolder(), isNull);
  });

  test('a refusal arrives as something the screen can say out loud', () async {
    thrown = PlatformException(
      code: 'grant',
      message: 'That folder could not be kept for later.',
    );
    await expectLater(
      DocumentStore.pickFolder(),
      throwsA(isA<DocumentStoreError>().having(
          (e) => e.plainMessage, 'plainMessage', contains('could not be kept'))),
    );
  });

  test('a phone with no picker at all says so, rather than hanging', () async {
    // The other half of the platform fix: `startActivityForResult` throwing
    // used to leave `pendingResult` set, so the Dart future never completed
    // *and* every later picker, camera and file chooser answered "busy" for
    // the life of the process. One failed tap disabled importing entirely.
    thrown = PlatformException(
      code: 'no_picker',
      message: 'This phone has no app for choosing a folder.',
    );
    await expectLater(
        DocumentStore.pickFolder(), throwsA(isA<DocumentStoreError>()));
  });

  test('on a platform with no channel it is refused, not silently nothing',
      () async {
    messenger.setMockMethodCallHandler(channel, null);
    await expectLater(
        DocumentStore.pickFolder(), throwsA(isA<DocumentStoreUnavailable>()));
  });
}
