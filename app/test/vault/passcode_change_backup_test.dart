import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/settings/app_settings.dart';

/// **ISSUE 20 — the backup that goes stale with the passcode.**
///
/// > *"If passcode is changed do they need new 12 words phrase or not? … And as
/// > the passcode is done — do a backup, so whatever the backup file had old
/// > password changes to new one!"*
///
/// The first half is answered on screen and is a property of the key hierarchy
/// rather than of any code here — `keyring_test.dart` already proves that the
/// recovery phrase keeps working across a passcode change, which is the whole
/// reason the answer is "no".
///
/// This is the second half, and the thing worth testing about it is small and
/// easy to get wrong: **the marker has to survive the app closing.** Somebody
/// who changes their passcode and then shuts the app has exactly the same stale
/// file tomorrow, so a flag in memory would be forgotten precisely when it is
/// still needed.
void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('lamplight_settings');
  });

  tearDown(() {
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('a fresh vault has nothing to say about its backup', () async {
    final settings = await AppSettings.load(File('${tmp.path}/settings.json'));
    expect(settings.backupOutOfDate, isFalse);
  });

  test('the marker outlives the process', () async {
    final file = File('${tmp.path}/settings.json');
    final first = await AppSettings.load(file);
    first.backupOutOfDate = true;
    // `_write` saves in the background — fire and forget, because a failed
    // preference write is not worth blocking a tap for. So the read below waits
    // for the write rather than racing it.
    await _settled();

    final second = await AppSettings.load(file);
    expect(second.backupOutOfDate, isTrue,
        reason: 'a passcode changed yesterday still leaves a stale backup '
            'today, so the marker has to still be there');
  });

  test('a finished backup clears it', () async {
    final file = File('${tmp.path}/settings.json');
    final settings = await AppSettings.load(file);
    settings.backupOutOfDate = true;
    settings.backupOutOfDate = false;
    await _settled();

    expect((await AppSettings.load(file)).backupOutOfDate, isFalse);
  });

  test('it is separate from when the last backup happened', () async {
    // Two different facts and they must not be conflated. Clearing
    // `lastBackupAt` would have been the lazy way to force a run, and it would
    // have made the app say "never backed up" to somebody with a perfectly good
    // file from Tuesday — and started the thirty-day reminder over.
    final settings = await AppSettings.load(File('${tmp.path}/settings.json'));
    final when = DateTime.now().subtract(const Duration(days: 2));
    settings.lastBackupAt = when;
    settings.backupOutOfDate = true;

    expect(settings.lastBackupAt, isNotNull);
    expect(settings.lastBackupAt!.difference(when).inSeconds.abs(),
        lessThanOrEqualTo(1));
    expect(settings.backupReminderDue, isFalse,
        reason: 'a two-day-old backup is not overdue merely because the '
            'passcode changed — it is out of date, which is a different '
            'thing and has its own quieter answer');
  });
}

/// Lets `AppSettings._save` finish. It is deliberately not awaited by the
/// setter — see the note there — so a test that reads the file back has to give
/// it a moment.
Future<void> _settled() =>
    Future<void>.delayed(const Duration(milliseconds: 120));
