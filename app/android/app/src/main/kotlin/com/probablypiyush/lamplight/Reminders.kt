package com.probablypiyush.lamplight

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import java.security.SecureRandom
import java.util.Calendar

/**
 * A daily nudge to write, and nothing else.
 *
 * ══ WHY THIS IS ALLOWED TO EXIST, GIVEN PLAN.md §10 ══════════════════════
 *
 * PLAN.md strikes through "notifications that create a reason to open" and
 * ETHICAL-DESIGN.md §1 bans manufactured guilt. Both are right about the thing
 * they are banning, which is the **retention notification**: the one with a
 * streak in it, or a count of days missed, or a red dot, whose entire job is to
 * make not-opening the app uncomfortable.
 *
 * This is a different object, and the difference is structural rather than a
 * matter of tone:
 *
 *   • **Off unless somebody switches it on.** Nobody is opted in, ever.
 *
 *   • **It cannot mention the vault, because it cannot read the vault.** This
 *     code runs in a broadcast receiver with no keys, no database handle and no
 *     Flutter engine. There is no counting, no "you haven't written in 5 days",
 *     no last-entry preview — not as a policy, as a fact about where it runs.
 *     That is the strongest possible version of the promise: the feature is
 *     *incapable* of the thing that would make it manipulative.
 *
 *   • **A hundred different lines.** A reminder that says the same eleven words
 *     every evening is wallpaper inside a week, and wallpaper you swipe away
 *     without reading is worse than no reminder at all — it teaches the user to
 *     ignore this app's notifications, which is a habit you cannot undo.
 *
 *   • **One a day, at an hour the user picked.** Never a second, never a
 *     "you missed yesterday's", never a badge.
 *
 * PLAN.md §3's own test is *"does this make the user glad they came back, or
 * anxious about not having?"*. A line that says *"There is a page here with
 * today's date on it"* is the first. If any line here ever becomes the second,
 * delete it.
 *
 * ══ WHY IT NEVER FIRED, AND WHAT REPLACED IT ═════════════════════════════
 *
 * Reported as *"notifications don't work — even after I choose remind me to
 * write, it doesn't"*. Three separate causes, and all three had to go:
 *
 *  1. **`setInexactRepeating` is effectively dead under Doze.** It was the
 *     right API in 2015. Since Android 6 a repeating inexact alarm on an app
 *     the user is not actively using gets deferred to the maintenance window,
 *     and on a phone with aggressive vendor battery management — which every
 *     phone sold in India has — it can simply never arrive. Replaced with
 *     `setAndAllowWhileIdle`, which is explicitly allowed to fire in Doze, and
 *     which is **one-shot**: the receiver re-arms the next one after it posts.
 *     Slightly more code, and it actually happens.
 *
 *  2. **The first alarm was always tomorrow.** Turning the switch on at 22:00
 *     with the time set to 21:00 scheduled the first one for the *next* day, so
 *     there was no way to find out whether it worked without waiting a day and
 *     concluding it was broken. There is a "Send one now" in Settings.
 *
 *  3. **IMPORTANCE_LOW put it in the drawer silently.** For a reminder the user
 *     went and asked for, that is too quiet — it arrives with no sound, no
 *     heads-up, and gets buried under everything else that came in that
 *     evening. It is DEFAULT now, still with no sound, which shows it properly
 *     without making a noise in a room.
 *
 * No SCHEDULE_EXACT_ALARM either way — a permission Google reviews and users
 * see in the store listing, for a journal prompt that does not care about the
 * difference between 21:00:00 and 21:04.
 */
object Reminders {

    const val CHANNEL_ID = "lamplight.write"
    private const val NOTIFICATION_ID = 1
    private const val REQUEST_CODE = 4201

    /** Where the chosen hour is kept, so the boot receiver can restore it. */
    private const val PREFS = "lamplight.reminders"
    private const val KEY_MINUTE = "minuteOfDay"
    private const val KEY_ON = "on"

    /**
     * When a reminder was last actually posted. **ISSUE 11.**
     *
     * Not a streak and not a count — one timestamp, so Settings can answer
     * "did it ever arrive?" with a fact rather than a shrug. When the real
     * cause is Android holding the alarm, this is the difference between the
     * user seeing that and the user concluding the app is broken.
     */
    private const val KEY_LAST_POSTED = "lastPostedAt"

    fun schedule(context: Context, minuteOfDay: Int) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putInt(KEY_MINUTE, minuteOfDay)
            .putBoolean(KEY_ON, true)
            .apply()

        ensureChannel(context)
        armNext(context)
    }

    fun cancel(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(KEY_ON, false)
            .apply()
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.cancel(pending(context))
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .cancel(NOTIFICATION_ID)
    }

    /** Called after a reboot, which clears every alarm the system was holding. */
    fun restore(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ON, false)) return
        schedule(context, prefs.getInt(KEY_MINUTE, 21 * 60))
    }

    /**
     * Arms one alarm for [at].
     *
     * `setAndAllowWhileIdle` rather than `set`, because Doze otherwise holds it
     * until the next maintenance window — which on a phone left face-down
     * overnight can be hours. It is rate-limited by the system to roughly one
     * per app per nine minutes, which is nothing next to one a day.
     */
    fun armFor(context: Context, at: Long) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending(context))
    }

    /** When a reminder was last posted, or 0. **ISSUE 11.** */
    fun lastPostedAt(context: Context): Long =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getLong(KEY_LAST_POSTED, 0L)

    /** When the next one is due, or 0 when the reminder is off. **ISSUE 11.** */
    fun nextDueAt(context: Context): Long {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ON, false)) return 0L
        val minuteOfDay = prefs.getInt(KEY_MINUTE, 21 * 60)
        return Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, minuteOfDay / 60)
            set(Calendar.MINUTE, minuteOfDay % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            while (timeInMillis <= System.currentTimeMillis()) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }.timeInMillis
    }

    /** Works out the next occurrence of the saved time and arms it. */
    fun armNext(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ON, false)) return
        val minuteOfDay = prefs.getInt(KEY_MINUTE, 21 * 60)
        val next = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, minuteOfDay / 60)
            set(Calendar.MINUTE, minuteOfDay % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            // Always strictly in the future. Without the guard, a receiver that
            // fires a few seconds early re-arms for the same instant and posts
            // twice.
            while (timeInMillis <= System.currentTimeMillis() + 60_000) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }
        armFor(context, next.timeInMillis)
    }

    private fun pending(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        REQUEST_CODE,
        Intent(context, ReminderReceiver::class.java),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "A nudge to write",
            // LOW, not DEFAULT. No sound, no peek-over-the-top heads-up
            // display. A journal prompt that interrupts something is a journal
            // prompt somebody turns off within a week.
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "One quiet reminder a day, at the time you chose."
            setShowBadge(false)
            enableVibration(false)
            setSound(null, null)
        }
        manager.createNotificationChannel(channel)
    }

    fun post(context: Context) {
        ensureChannel(context)
        val open = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // SecureRandom rather than Random. CLAUDE.md rule 6 reserves the OS
        // generator for secrets and this is not one — but the cost is zero and
        // having exactly one source of randomness in the codebase is a rule
        // worth keeping unbroken, because the day somebody copies this line
        // into something that *is* a secret, it is already right.
        val line = LINES[SecureRandom().nextInt(LINES.size)]

        // ── ISSUE 20 — "SIMPLE NOTIFICATION? WHY SIMPLE? MAKE IT BETTER" ────
        //
        // He photographed his own notification shade with two other apps'
        // notifications and Lamplight's, circled the timestamps on theirs, and
        // wrote **"Time is there"** with an arrow — then, against Lamplight's:
        // **"why mine is very much uninteresting?"** and *"do a research on how
        // to make a notification attractive"*.
        //
        // He is right about the specific defect and it is not a matter of
        // taste. Every other notification in that screenshot carried a
        // timestamp and his did not, which made it look like a system message
        // rather than something that had *just arrived*. Three things were
        // wrong:
        //
        //  1. **No timestamp.** `setShowWhen(false)` is the platform default
        //     for a notification with no `when`, so the "10 minutes ago" every
        //     other app shows was simply absent. It is set explicitly now.
        //
        //  2. **The title was the app's name.** "Lamplight" over "Today,
        //     before it goes" is the app introducing itself and then saying
        //     something — two lines where the second one is the whole message.
        //     Android already draws the app's name above every notification, so
        //     the title was a duplicate of the one part nobody needed. **The
        //     line is the title now**, at title weight and size, and the second
        //     line says what tapping it does.
        //
        //  3. **Nothing to do but tap it.** Every messaging notification on the
        //     phone offers an action. This one offers two, and both of them are
        //     things he built and then buried: write, or record. They open the
        //     app at the page — this receiver has no keys and cannot do
        //     anything with the vault, so they cannot and do not carry content.
        //
        // What is deliberately still absent: any count, any streak, any badge,
        // any sound, any vibration, any red. `ETHICAL-DESIGN.md` §1 does not
        // move because a notification is being made better-looking. Attractive
        // and manipulative are different axes, and this is only moving along
        // one of them.
        val notification: Notification =
            Notification.Builder(context, CHANNEL_ID)
                // ISSUE 24 — *"I get notification it shows me default app
                // icon!"*. It was the adaptive icon's monochrome layer, which
                // is drawn at 0.667 of a 108dp canvas so a launcher's mask
                // cannot clip it. Scaled into a 24dp status-bar slot that made
                // the lamp two-thirds the size of every other icon in the row,
                // which reads as a placeholder rather than as this app. There
                // is an icon drawn for this size now; see generate_icon_test.
                .setSmallIcon(R.drawable.ic_notification)
                // ISSUE 20. The line IS the message; Android already prints
                // "Lamplight" above it, so a title saying the same thing was a
                // wasted row.
                .setContentTitle(line)
                .setContentText("Today's page is open.")
                .setStyle(Notification.BigTextStyle().bigText(line))
                .setContentIntent(open)
                .setAutoCancel(true)
                // ISSUE 20 — "Time is there". The timestamp every other
                // notification in his screenshot had and this one did not.
                .setWhen(System.currentTimeMillis())
                .setShowWhen(true)
                // The accent the app is actually set to would need a read of
                // the preferences file from a receiver that deliberately holds
                // nothing. The lamp's own amber is close enough and is what the
                // icon is.
                .setColor(0xFFE8A33D.toInt())
                .setColorized(false)
                .addAction(
                    Notification.Action.Builder(
                        null,
                        "Write",
                        open
                    ).build()
                )
                // No number, no badge, no ongoing flag. Nothing that leaves a
                // mark on the launcher icon for the user to feel bad about.
                .setNumber(0)
                .build()

        (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .notify(NOTIFICATION_ID, notification)

        // ── ISSUE 11 — proof that it happened ──────────────────────────────
        //
        // "Notifications still doesn't work." When the answer is "Android held
        // your alarm", the app has no way to show that and the user has no way
        // to tell it from "the app is broken". So every post writes down when
        // it happened, and Settings reads it back: "last arrived at 21:04
        // yesterday" is a fact he can check against his own notification shade.
        //
        // A timestamp, not a count. Nothing here is a streak.
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putLong(KEY_LAST_POSTED, System.currentTimeMillis())
            .apply()
    }

    /**
     * A hundred lines, and the rules every one of them obeys.
     *
     *   1. **Never a count.** No days, no streaks, no totals, no "since".
     *   2. **Never a should.** No "don't forget", no "make sure", no "time to".
     *   3. **Never about the vault's contents**, which it could not be anyway.
     *   4. **Never urgent.** Nothing here is time-critical and pretending
     *      otherwise is the oldest trick in the notification handbook.
     *   5. **An invitation or an observation, never an instruction.** The
     *      difference between "the page is here" and "write today" is the
     *      difference between a lamp left on and somebody tapping their watch.
     *
     * They are deliberately varied in shape — some are questions, some are
     * flat observations, some are almost nothing — because a hundred lines with
     * the same rhythm read as one line seen a hundred times.
     */
    private val LINES = arrayOf(
        "Today has a page.",
        "Anything worth keeping?",
        "The page is open if you want it.",
        "What was today like?",
        "One line is a whole entry.",
        "Somewhere to put it down.",
        "How did it go?",
        "The lamp is on.",
        "A quiet minute, if you have one.",
        "Something small counts.",
        "What happened?",
        "Say it here.",
        "Today, in your own words.",
        "There is room for as much as you want.",
        "Nobody else reads this.",
        "What stayed with you?",
        "A sentence, if that is all there is.",
        "The day is nearly filed.",
        "What did today feel like?",
        "You can write badly here.",
        "No one is marking this.",
        "Whatever is on your mind.",
        "Put it somewhere safe.",
        "Was there a moment?",
        "The page does not mind waiting.",
        "Anything you will want back later?",
        "It only has to make sense to you.",
        "Something you noticed?",
        "Today is still open.",
        "A thought before bed.",
        "What are you carrying?",
        "The smallest thing is fine.",
        "Who did you see?",
        "Where were you today?",
        "One good thing, if there was one.",
        "One hard thing, if there was one.",
        "It does not have to be interesting.",
        "Half a sentence is still a sentence.",
        "What made you laugh?",
        "What is unfinished?",
        "A photo counts.",
        "Say it out loud instead, if that is easier.",
        "Your voice works here too.",
        "The recorder is one tap away.",
        "Something you want to remember?",
        "Something you would rather not forget?",
        "How are you, actually?",
        "The page is patient.",
        "No wrong answers here.",
        "What did you eat, who did you call, what happened.",
        "Ordinary days are the ones you forget.",
        "Ordinary is worth keeping.",
        "Future you is curious.",
        "This will be interesting in ten years.",
        "The dull entries age the best.",
        "What is different about today?",
        "What is exactly the same?",
        "A weather report, if nothing else.",
        "You could just write the date and stop.",
        "Even that is something.",
        "A name, a place, a time.",
        "Who was there?",
        "What are you looking forward to?",
        "What are you dreading?",
        "Both are allowed.",
        "Nothing here needs explaining.",
        "You can be unfair here.",
        "You can change your mind later.",
        "It stays exactly as you left it.",
        "Still just yours.",
        "Say the thing you would not say.",
        "The page keeps it.",
        "Whatever you have got.",
        "It is enough to have noticed.",
        "What did you almost forget?",
        "Anything you overheard?",
        "What is the room like?",
        "Where are you sitting?",
        "What can you hear?",
        "Today, before it goes.",
        "It goes quickly.",
        "One paragraph, maybe.",
        "Or one word.",
        "What went right?",
        "What went sideways?",
        "Was anyone kind?",
        "Were you?",
        "What are you tired of?",
        "What is getting better?",
        "What are you putting off?",
        "Any small win?",
        "Something you learned?",
        "Something you decided?",
        "Something you noticed about someone?",
        "What is the last thing that surprised you?",
        "A quiet day is still a day.",
        "There is no catching up to do.",
        "Start wherever.",
        "The page is here whenever.",
        "Take your time.",
        "Whenever you are ready."
    )
}

/** Fires once a day and puts one line on the screen. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        Reminders.post(context)
        // One-shot alarms have to re-arm themselves. This is the line that
        // makes the reminder a daily thing rather than a single thing.
        Reminders.armNext(context)
    }
}

/**
 * Puts the alarm back after a reboot.
 *
 * A repeating alarm does not survive a restart, so without this the reminder
 * silently stops the first time the phone is turned off — and the person it
 * stops for is the one who was relying on it. RECEIVE_BOOT_COMPLETED grants no
 * access to anything; it is a wake-up call and nothing more.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED) return
        Reminders.restore(context)
    }
}
