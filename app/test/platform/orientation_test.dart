import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/platform/orientation.dart';

/// **ISSUE 5.** One mode, and a test that says which.
///
/// This exists because "I locked the orientation" is the sort of claim that is
/// easy to make and easy to have quietly undone by a later edit — a screen that
/// wants to be wide, a video player that thinks it is special. If somebody adds
/// `landscapeLeft` to that list, this fails and says so.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the app asks for portrait and nothing else', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await PortraitOnly.apply();

    final call = calls.singleWhere(
        (c) => c.method == 'SystemChrome.setPreferredOrientations');
    expect(
      call.arguments,
      ['DeviceOrientation.portraitUp'],
      reason: 'exactly one orientation, upright — not landscape, and not '
          'portraitDown either',
    );
  });

  test('the allowed list is a single entry', () {
    expect(PortraitOnly.allowed, [DeviceOrientation.portraitUp]);
  });
}
