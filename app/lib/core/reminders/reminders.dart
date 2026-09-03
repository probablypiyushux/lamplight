import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../plain_words.dart';

/// The daily nudge, from Dart's side.
///
/// Thin on purpose: **the reminder is not a Flutter feature.** It is an Android
/// alarm and a broadcast receiver, and it has to fire on a day the app is never
/// opened — which is precisely the day it matters. Anything that needed the
/// Dart isolate to be alive would be a reminder that only reaches people who
/// did not need reminding.
///
/// So all this does is switch it on and off. The hundred lines it can say live
/// in `Reminders.kt`, out of reach of any key, any database and any note. See
/// the long argument there for why this feature is allowed to exist at all
/// given `PLAN.md` §10.
abstract final class Reminders {
  static const MethodChannel _channel = MethodChannel('lamplight/documents');

  /// Whether Android will let us post one.
  static Future<bool> allowed() async {
    try {
      return await _channel.invokeMethod<bool>('notificationsAllowed') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Asks, once, at the moment somebody turns the switch on.
  ///
  /// **Never at launch.** A permission prompt on first run, before the person
  /// has any idea what the app is, is the single most reliable way to get a
  /// permanent "no" — and the one thing worse than not having notifications is
  /// having them permanently blocked by a user who was asked too early.
  static Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestNotifications') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> schedule(int minuteOfDay) async {
    try {
      await _channel.invokeMethod<void>(
          'scheduleReminder', {'minuteOfDay': minuteOfDay});
    } catch (_) {
      // A reminder that failed to schedule is not worth an error dialog over.
      // The switch reflects the preference; the next launch tries again.
    }
  }

  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod<void>('cancelReminder');
    } catch (_) {}
  }

  /// Sends one immediately.
  ///
  /// **No longer reachable from Settings.** Round five, ISSUE 10: *"I want the
  /// Test Button removed."* Kept as a method because it is the one call that
  /// isolates posting from scheduling, and that distinction is what diagnosed
  /// the real fault — see [batteryRestricted].
  static Future<void> sendOneNow() async {
    try {
      await _channel.invokeMethod<void>('testReminder');
    } catch (_) {}
  }

  /// Whether Android is holding this app's background alarms.
  ///
  /// **ROUND FIVE, ISSUE 10 — this is why the reminder never came.**
  ///
  /// He reported it twice, and the second time with the detail that solved it:
  /// *"time chosen → never comes → test button works"*. A working test button
  /// means the channel, the permission, the notification channel and the icon
  /// are all correct, because that button posts a notification directly. So
  /// nothing about *posting* is broken. The alarm is not arriving.
  ///
  /// Round four had already replaced `setInexactRepeating` with
  /// `setAndAllowWhileIdle` for exactly this complaint, and it was the right
  /// change — it just is not sufficient on the two devices he uses. Doze is
  /// only one of the two things that defer an alarm; the other is **App
  /// Standby Buckets**, and vendor battery management on MIUI and Funtouch is
  /// considerably more aggressive than stock Android's. An app the user has
  /// not exempted can sit in `restricted` and have a once-a-day alarm dropped
  /// entirely. No amount of Dart or `AlarmManager` flag choice overrides that.
  ///
  /// **What was deliberately not done.** `setAlarmClock` is exempt from all of
  /// it and needs no permission — and puts a permanent alarm icon in the status
  /// bar and the next-alarm time on the lock screen. For a journal nudge that
  /// is both wrong and a leak, and it would be the first line of the next
  /// document. `setExactAndAllowWhileIdle` needs `SCHEDULE_EXACT_ALARM`, which
  /// `PLAN.md` rejects on purpose. So the honest answer is to detect the state
  /// and say so, rather than to keep guessing at APIs.
  ///
  /// Reading this needs no permission at all.
  static Future<bool> batteryRestricted() async {
    try {
      return await _channel.invokeMethod<bool>('batteryRestricted') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system's battery-optimisation list.
  ///
  /// Not a dialog — the list. Putting up the one-tap dialog instead would need
  /// `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, a permission Google reviews and
  /// that appears in the store listing, and one extra tap is a better trade.
  static Future<bool> openBatterySettings() async {
    try {
      return await _channel.invokeMethod<bool>('openBatterySettings') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Every gate that can stop a reminder, and which of them are shut.
  ///
  /// **ISSUE 11 — "notifications still doesn't work. Find a bulletproof way to
  /// get a notification, at the set time! ... Why any app is able to send me
  /// notification? And Lamplight can't even send me notification? Why?"**
  ///
  /// The honest answer to that question is uncomfortable and it is worth
  /// stating: **the app cannot make Android deliver an alarm.** Round five
  /// found the real cause — vendor battery management holding background
  /// alarms — and fixed everything that was in the app's power to fix. He is
  /// still not getting reminders, and the reason he cannot tell that from a
  /// broken app is that the app has never shown him which of the four gates is
  /// shut.
  ///
  /// So it shows him. Permission, notifications enabled, this channel enabled,
  /// battery restriction, when the last one actually arrived, and when the next
  /// is due. Six facts, each with the button that fixes it. That converts "it
  /// doesn't work" into "this switch is off", which is the difference between
  /// an unfixable complaint and a thirty-second fix.
  ///
  /// Never throws. A diagnosis that fails to load must not be the seventh
  /// thing that is broken.
  static Future<ReminderHealth> health() async {
    try {
      final m = await _channel
          .invokeMapMethod<String, Object?>('reminderHealth');
      if (m == null) return const ReminderHealth.unknown();
      DateTime? at(Object? value) {
        final ms = value is int ? value : 0;
        return ms <= 0 ? null : DateTime.fromMillisecondsSinceEpoch(ms);
      }

      return ReminderHealth(
        permission: m['permission'] == true,
        notificationsEnabled: m['notificationsEnabled'] == true,
        channelEnabled: m['channelEnabled'] == true,
        batteryRestricted: m['batteryRestricted'] == true,
        lastPostedAt: at(m['lastPostedAt']),
        nextDueAt: at(m['nextDueAt']),
      );
    } catch (_) {
      return const ReminderHealth.unknown();
    }
  }
}

/// Which of the four gates is shut, for a screen that can translate it.
///
/// ══ THE LAST ENGLISH IN SETTINGS. 31 August 2026 ═══════════════════════════
///
/// > *"In localisation mistake — in settings tab — The Reminder may not arrive
/// > — This phone is saving battery by holding lamplight back. That is the
/// > actual reason a reminder is late or never arrives. (this never gets
/// > localised!)"*
///
/// Exactly right, and the shape of the bug is worth keeping: the **heading**
/// was localised and the **reason underneath it** was not. `reminderMayNotArrive`
/// had an ARB key and ten translations; the sentence explaining what to do about
/// it was returned from here as an English literal, because this class lives in
/// `core/` and `core/` has no `BuildContext`.
///
/// So a Hindi reader got a Hindi title over an English paragraph — which is
/// worse than either being wholly English or wholly translated, because it
/// looks like the app tried and failed rather than like a gap.
///
/// It is the same problem `core/backup/` had, and it takes the same answer:
/// [Localisable]. This carries **which** gate is shut; the screen, which has a
/// context, decides how to say it. The English stays on the enum because it is
/// what the tests assert against — and those assertions are load-bearing, not
/// decoration: they are round eight's ISSUE 10 written down, and they are what
/// stops the word "channel" coming back.
enum ReminderProblem implements Localisable {
  /// Android 13+ runtime permission. Nothing else matters without it.
  notAllowed('Lamplight is not allowed to send notifications.'),

  /// Every notification from this app, switched off in system settings.
  notificationsOff(
      "This phone's settings have Lamplight's notifications switched off."),

  /// This one channel, silenced on its own.
  ///
  /// **The sentence must not say "channel".** ISSUE 10: a notification channel
  /// is Android's word for Android's bookkeeping, and a person told they have
  /// one has been handed a problem in a vocabulary they do not speak. What is
  /// useful is which settings screen, which is what this says.
  remindersOff("Reminders from Lamplight are switched off in this phone's "
      'notification settings.'),

  /// Android is holding this app's background alarms. **The usual cause**, and
  /// the one the app cannot fix from inside.
  ///
  /// It does not say so, though. ISSUE 10 again: this used to end *"it is the
  /// one thing no app can override from the inside"* — two clauses of
  /// architecture and an apology, with nothing to do about either.
  batterySaving('This phone is saving battery by holding Lamplight back. That '
      'is the usual reason a reminder is late or never arrives.');

  const ReminderProblem(this.message);

  /// The English sentence. See [Localisable] for why both exist.
  final String message;

  @override
  String describeIn(L l) => switch (this) {
        ReminderProblem.notAllowed => l.reminderProblemNotAllowed,
        ReminderProblem.notificationsOff => l.reminderProblemNotificationsOff,
        ReminderProblem.remindersOff => l.reminderProblemRemindersOff,
        ReminderProblem.batterySaving => l.reminderProblemBatterySaving,
      };
}

/// What is standing between the user and their reminder. **ISSUE 11.**
class ReminderHealth {
  const ReminderHealth({
    required this.permission,
    required this.notificationsEnabled,
    required this.channelEnabled,
    required this.batteryRestricted,
    this.lastPostedAt,
    this.nextDueAt,
  });

  /// When the platform could not be asked at all — a test, a desktop build.
  /// Everything reads as fine, because claiming a fault we did not observe
  /// would be its own kind of lying.
  const ReminderHealth.unknown()
      : permission = true,
        notificationsEnabled = true,
        channelEnabled = true,
        batteryRestricted = false,
        lastPostedAt = null,
        nextDueAt = null;

  /// Android 13+ runtime permission.
  final bool permission;

  /// The app's notifications, switched off in system settings.
  final bool notificationsEnabled;

  /// This one channel, silenced on its own — which looks identical from inside
  /// the app and is the hardest of the four for a person to find.
  final bool channelEnabled;

  /// Android is holding this app's background alarms. **The usual cause**, and
  /// the one the app cannot fix from inside.
  final bool batteryRestricted;

  final DateTime? lastPostedAt;
  final DateTime? nextDueAt;

  /// Whether anything at all is in the way.
  bool get isHealthy =>
      permission && notificationsEnabled && channelEnabled && !batteryRestricted;

  /// The one thing to fix first, or null when nothing is wrong.
  ///
  /// One at a time, in the order they block delivery. A list of four faults is
  /// a wall; one fault with one button is a task.
  /// The words live on [ReminderProblem] now, in ten languages. The order
  /// this asks the questions in is the part that belongs here, and it is the
  /// order they block delivery in — reporting the wrong one first sends
  /// somebody to the wrong settings screen.
  ReminderProblem? get firstProblem {
    if (!permission) return ReminderProblem.notAllowed;
    if (!notificationsEnabled) return ReminderProblem.notificationsOff;
    if (!channelEnabled) return ReminderProblem.remindersOff;
    if (batteryRestricted) return ReminderProblem.batterySaving;
    return null;
  }
}
