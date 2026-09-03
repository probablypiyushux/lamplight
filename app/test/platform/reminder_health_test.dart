import 'package:lamplight/core/reminders/reminders.dart';
import 'package:flutter_test/flutter_test.dart';

/// **ISSUE 11 — "notifications still doesn't work. Find a bulletproof way."**
///
/// And: *"Why any app is able to send me notification? And Lamplight can't even
/// send me notification? Why? The hell?"*
///
/// The honest answer is uncomfortable and worth stating plainly: **an app
/// cannot make Android deliver an alarm.** Round five found the real cause —
/// vendor battery management freezing background alarms — and fixed everything
/// that was inside the app's power. What was still missing is the thing that
/// makes the difference to him: the app never showed him *which* of the four
/// gates was shut, so "Android is holding it" and "this app is broken" looked
/// identical from where he was standing.
///
/// These tests pin the order the faults are reported in, because reporting the
/// wrong one first sends somebody to the wrong settings screen.
void main() {
  ReminderHealth health({
    bool permission = true,
    bool notificationsEnabled = true,
    bool channelEnabled = true,
    bool batteryRestricted = false,
  }) =>
      ReminderHealth(
        permission: permission,
        notificationsEnabled: notificationsEnabled,
        channelEnabled: channelEnabled,
        batteryRestricted: batteryRestricted,
      );

  test('nothing in the way is reported as nothing in the way', () {
    expect(health().isHealthy, isTrue);
    expect(health().firstProblem, isNull);
  });

  group('one fault at a time, in the order they block delivery', () {
    test('the permission comes first — nothing else matters without it', () {
      final all = health(
        permission: false,
        notificationsEnabled: false,
        channelEnabled: false,
        batteryRestricted: true,
      );
      expect(all.firstProblem?.message, contains('not allowed'));
    });

    test('then the app\'s notifications being switched off', () {
      expect(
        health(notificationsEnabled: false, batteryRestricted: true)
            .firstProblem
            ?.message,
        contains('switched off'),
      );
    });

    test('then reminders being silenced on their own', () {
      // The hardest of the four for a person to find, because from inside the
      // app it looks exactly like everything being fine.
      //
      // ══ ROUND EIGHT, ISSUE 10 — THIS TEST USED TO ENSHRINE THE LEAK ════
      //
      // It asserted `contains('channel')`, because the message said *"the
      // reminder's own notification channel is switched off"*. A notification
      // channel is Android's word for Android's bookkeeping; nobody has one,
      // and a person told they have one has been handed a problem in a
      // vocabulary they do not speak.
      //
      // What is worth asserting is not the jargon but the **destination**:
      // whether the sentence tells him where to go and fix it.
      final problem = health(channelEnabled: false).firstProblem?.message;
      expect(problem, contains('notification settings'),
          reason: 'the useful half is which settings, not what Android calls '
              'its own bookkeeping');
      expect(problem, isNot(contains('channel')),
          reason: 'ISSUE 10 — and this is the assertion that keeps it out');
    });

    test('and last, the battery restriction — named as the usual cause', () {
      final problem = health(batteryRestricted: true).firstProblem?.message;
      expect(problem, contains('battery'));
      expect(problem, contains('usual reason'),
          reason: 'he should be told this is the common one, not left to guess');
      // ISSUE 10. This used to require the sentence to say *"it is the one
      // thing no app can override from the inside"* — two clauses of
      // architecture and an apology, with nothing to do about either. The
      // honest, useful version says what is happening to him rather than what
      // is happening to the app.
      expect(problem, isNot(contains('override')),
          reason: 'the app does not explain its own limits at somebody');
      expect(problem, contains('phone'),
          reason: 'it is his phone doing this, and that is the actionable fact');
    });
  });

  test('every fault makes it unhealthy', () {
    expect(health(permission: false).isHealthy, isFalse);
    expect(health(notificationsEnabled: false).isHealthy, isFalse);
    expect(health(channelEnabled: false).isHealthy, isFalse);
    expect(health(batteryRestricted: true).isHealthy, isFalse);
  });

  test('a platform that cannot be asked claims no fault it did not observe',
      () {
    // A test, a desktop build. Inventing a fault would be its own kind of
    // lying, and would put a permanent warning in Settings on every device
    // where the check simply is not available.
    const unknown = ReminderHealth.unknown();
    expect(unknown.isHealthy, isTrue);
    expect(unknown.firstProblem, isNull);
    expect(unknown.lastPostedAt, isNull);
  });
}
