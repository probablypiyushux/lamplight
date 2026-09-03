import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/settings/app_settings.dart';

/// When the app asks for a backup. **28 August 2026, and it cost a vault.**
///
/// ══ WHAT HAPPENED ═════════════════════════════════════════════════════════
///
/// A three-day-old vault on the Redmi Pad was destroyed. A development build's
/// install was refused by the device, the tooling's cleanup then uninstalled
/// the real app, and `allowBackup="false"` means an uninstall takes
/// `/data/data` with it. There was no backup, because the app had never asked
/// for one — the never-backed-up reminder waited **fourteen days**, and the
/// reasoning written beside it was:
///
/// > *"A reminder on day one is nagging someone about losing a vault with three
/// > sentences in it."*
///
/// Right about day one; wrong about what to count. **Days elapsed is not the
/// measure of what is at stake — the size of the vault is.** Somebody who has
/// written on four separate days has a habit, and losing a habit's worth of
/// writing is the whole thing this app exists to prevent. Nobody can tell in
/// advance which of those they are about to become, which is exactly why the
/// app should ask at the moment it can tell.
///
/// ══ WHY THIS IS A TEST AND NOT A COMMENT ══════════════════════════════════
///
/// Both directions of this are easy to break by being reasonable:
///
///   * **Too late** is what already happened, and it is invisible until
///     somebody loses something.
///   * **Too early** turns a journal into an app that nags, which
///     `ETHICAL-DESIGN.md` forbids and which is how every other app in this
///     category becomes unpleasant. A banner on the first sentence somebody
///     ever writes would be exactly that.
///
/// So both are asserted, and neither can drift without failing a build.
void main() {
  AppSettings fresh({DateTime? firstRun, DateTime? lastBackup}) {
    final settings = AppSettings.inMemory();
    settings.markFirstRun();
    if (lastBackup != null) settings.lastBackupAt = lastBackup;
    return settings;
  }

  group('a vault nobody has backed up', () {
    test('says nothing about three sentences on the first afternoon', () {
      // The original reasoning, preserved. Somebody trying the app out is not
      // somebody with something to lose, and telling them otherwise is the
      // beginning of an app that nags.
      final settings = fresh();
      expect(
        settings.backupReminderDueFor(entries: 3, days: 1),
        isFalse,
        reason: 'five entries in one afternoon is somebody trying the app, '
            'not somebody keeping a journal',
      );
    });

    test('says nothing about a lot of writing on one single day', () {
      // Both conditions, not either. A long first session is still a first
      // session.
      final settings = fresh();
      expect(settings.backupReminderDueFor(entries: 40, days: 1), isFalse);
    });

    test('says nothing about two entries a fortnight apart', () {
      // Two days, but barely anything on them.
      final settings = fresh();
      expect(settings.backupReminderDueFor(entries: 2, days: 2), isFalse);
    });

    test('asks once the writing spans days and adds up', () {
      // ══ THE ASSERTION THAT WOULD HAVE SAVED THE VAULT ══════════════════
      //
      // Five entries across two days. Under the old rule this was eleven more
      // days of silence.
      final settings = fresh();
      expect(
        settings.backupReminderDueFor(entries: 5, days: 2),
        isTrue,
        reason: 'this is the case the fortnight missed, and it is the case '
            'that cost a vault on 28 August',
      );
    });

    test('asks for a month of daily writing, obviously', () {
      final settings = fresh();
      expect(settings.backupReminderDueFor(entries: 60, days: 30), isTrue);
    });

    test('the fortnight backstop still catches somebody who writes rarely', () {
      // Somebody with three entries in three weeks never trips the size rule,
      // and should still be told eventually.
      // Seeded rather than stamped, because `markFirstRun` writes *now* and
      // this needs a vault that was first opened three weeks ago.
      final settings = AppSettings.inMemory({
        'firstRunAt': DateTime.now()
            .subtract(const Duration(days: 20))
            .millisecondsSinceEpoch,
      });
      expect(settings.backupReminderDueFor(entries: 3, days: 3), isTrue);
    });

    test('a vault that has never been opened before says nothing', () {
      // No first-run stamp: nothing is known, so nothing is claimed.
      final settings = AppSettings.inMemory();
      expect(settings.backupReminderDueFor(entries: 0, days: 0), isFalse);
    });
  });

  group('once a backup exists', () {
    test('the size of the vault stops mattering', () {
      // A backed-up vault is on the 30-day clock and nothing else. Growing
      // does not re-ask.
      final settings = fresh(lastBackup: DateTime.now());
      expect(settings.backupReminderDueFor(entries: 500, days: 200), isFalse);
    });

    test('a month without one asks again', () {
      final settings = fresh(
          lastBackup: DateTime.now().subtract(const Duration(days: 31)));
      expect(settings.backupReminderDueFor(entries: 10, days: 5), isTrue);
    });
  });

  group('dismissing it is respected', () {
    test('a snooze silences even a vault that is well past the line', () {
      // `ETHICAL-DESIGN.md`: dismissing means dismissed. An app that asks
      // again tomorrow has not offered a choice, it has offered a delay.
      final settings = fresh();
      expect(settings.backupReminderDueFor(entries: 50, days: 20), isTrue);
      settings.snoozeBackupReminder();
      expect(settings.backupReminderDueFor(entries: 50, days: 20), isFalse);
    });
  });

  group('the caller that knows nothing is never noisier', () {
    test('the no-argument form can only ever be later, never earlier', () {
      // `backupReminderDue` answers with less information. It must not be able
      // to produce an alarm the informed version would not.
      final settings = fresh();
      for (final size in const [(0, 0), (5, 2), (50, 20)]) {
        final informed =
            settings.backupReminderDueFor(entries: size.$1, days: size.$2);
        if (settings.backupReminderDue) {
          expect(informed, isTrue,
              reason: 'the uninformed form fired when the informed one did '
                  'not — that is a false alarm, which is how a quiet app '
                  'becomes a nagging one');
        }
      }
    });
  });
}
