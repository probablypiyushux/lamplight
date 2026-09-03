import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/platform/screen_security.dart';
import 'package:lamplight/core/settings/app_settings.dart';

/// The screenshot switch, and the one thing about it that is a security
/// property rather than a preference.
///
/// `FLAG_SECURE` is set in `MainActivity.onCreate` **before `super.onCreate`**,
/// unconditionally. Everything here can only ever relax that afterwards. The
/// assertions below are about the *default* and about the call actually
/// reaching the platform — the ordering itself lives in Kotlin and is commented
/// there, because a Dart test cannot see it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final channel = const MethodChannel('lamplight/documents');
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('a vault that has never heard of the setting blocks screenshots', () {
    // The default is the whole point. `THREAT-MODEL.md` ranks "the person who
    // picks up the unlocked phone" as the most likely adversary, and the
    // recent-apps thumbnail is the cheapest way that person reads a note
    // without unlocking anything.
    expect(AppSettings.inMemory().allowScreenshots, isFalse);
  });

  test('a vault upgrading from before the setting existed also blocks them',
      () {
    // A settings file written by an older build has no `allowScreenshots` key
    // at all. It must read as false rather than as null-becomes-true.
    expect(
      AppSettings.inMemory({'autoLock': 60000, 'remindersEnabled': true})
          .allowScreenshots,
      isFalse,
    );
  });

  test('the switch survives being written and read back', () {
    final settings = AppSettings.inMemory();
    settings.allowScreenshots = true;
    expect(settings.allowScreenshots, isTrue);
    settings.allowScreenshots = false;
    expect(settings.allowScreenshots, isFalse);
  });

  test('allowing capture reaches the platform, in those words', () async {
    await ScreenSecurity.allowCapture(true);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'setScreenSecurity');
    expect((calls.single.arguments as Map)['allow'], isTrue);

    await ScreenSecurity.allowCapture(false);
    expect((calls.last.arguments as Map)['allow'], isFalse);
  });

  test('a phone that will not take the call keeps the secure default',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'nope');
    });
    // Must not throw. The window keeps whatever it had, and what it had is
    // `FLAG_SECURE` — failing in the secure direction is the only acceptable
    // way for this to fail.
    await ScreenSecurity.allowCapture(true);
  });
}
