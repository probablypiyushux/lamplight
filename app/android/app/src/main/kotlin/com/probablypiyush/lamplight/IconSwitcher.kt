package com.probablypiyush.lamplight

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager

/**
 * The launcher icon, following the theme.
 *
 * ══ WHY THIS IS AN ACTIVITY-ALIAS SWAP ═══════════════════════════════════
 *
 * Android will not let an app change its own icon. The icon is a manifest
 * attribute, read by the launcher, fixed at install time — there is no API for
 * "use this drawable now". What there *is* is `activity-alias`: several
 * declarations of the same activity, each with its own icon, of which exactly
 * one is enabled. Enabling a different one is the only supported way, and it is
 * what every app that does this — Telegram, Reddit, Todoist — actually does.
 *
 * ══ THE ORDERING RULE, WHICH IS THE WHOLE OF THE RISK ════════════════════
 *
 * **Enable the new alias before disabling the others.** Between the calls the
 * launcher re-reads the package, and if that moment finds *zero* enabled
 * launcher components it concludes the app has no icon and removes it from the
 * home screen. The user's shortcut is gone and they have to go and find the app
 * in the drawer to get it back — which, for a journal somebody opens every
 * evening, is a genuinely bad outcome for a cosmetic feature.
 *
 * In this order there is always at least one enabled alias, and the worst case
 * is a brief moment where two are, which no launcher minds.
 *
 * **This mattered more the moment there were twelve.** ISSUE 6b asked for the
 * icon's light to follow the chosen accent, and a launcher icon is a manifest
 * attribute with no runtime tint — so six accents in two themes is twelve
 * aliases. Eleven `disable` calls after one `enable` is eleven more chances to
 * be interrupted, and the order is what makes every one of those moments safe.
 *
 * `DONT_KILL_APP` on both calls. Without it Android restarts the process to
 * apply the component change — which, for an app that destroys its keys when it
 * goes to the background, means changing the theme would lock the vault.
 *
 * ══ WHY THE SWAP IS DEFERRED, ROUND FIVE ISSUE A ═════════════════════════
 *
 * Reported twice, and the second time with the cause in it: *"whenever the icon
 * colour or dark mode light mode is done I get out of the app"*, and earlier
 * *"whenever a theme is changed the app is closed — feels like a crash. Stop
 * this."*
 *
 * `DONT_KILL_APP` was already on every call here, and it was not enough,
 * because it protects the wrong thing. It stops Android killing the **process**
 * to apply a component change. What it does not stop — and what nothing can —
 * is the consequence of disabling the alias that the **currently running task
 * was launched from**. That component is the task's root. Disable it and the
 * system finishes the task: the activity goes, the app leaves recents, and the
 * user is standing on their home screen. The process may well have survived,
 * which is exactly why this looked like a crash rather than a restart.
 *
 * It is unavoidable while the app is in the foreground, so the answer is not to
 * do it in the foreground. [request] now records what the icon *should* be and
 * returns immediately; [applyPending] does the actual swap, and MainActivity
 * calls it from `onStop` — after the user has already left.
 *
 * The cost of finishing the task at that moment is nil, and that is not luck.
 * Lamplight destroys its keys and locks the vault the instant it goes into the
 * background, so a task waiting in recents holds nothing but a lock screen. The
 * worst case is that the app is not in the recents list next time, and the user
 * opens it from the launcher icon — which is, by then, the new one.
 *
 * The icon therefore changes a moment after the setting does rather than with
 * it. That is a real difference from what the Appearance screen implies, and it
 * is the right trade: an icon that updates when you next put the phone down,
 * against being thrown out of the app every time you try a colour.
 *
 * ══ WHAT THIS COSTS, HONESTLY ════════════════════════════════════════════
 *
 * Some launchers redraw the icon immediately; some only after a reboot or a
 * launcher restart, because they cache icons aggressively and there is no
 * signal for "this one changed". Nothing can be done about that from inside the
 * app, and it is not worth pretending otherwise — the setting says the icon
 * follows the theme, and on a few launchers it will follow it late.
 */
object IconSwitcher {

    private const val PREFIX = "com.probablypiyush.lamplight."

    /**
     * The one alias the manifest ships **enabled**.
     *
     * It has to be named here because `getComponentEnabledSetting` does not
     * answer the question anybody wants asked. It returns three states, not
     * two: `ENABLED` and `DISABLED` mean somebody has explicitly set them, and
     * `DEFAULT` — which is what every component reports until the first time it
     * is touched — means *"whatever the manifest said"*. For eleven of the
     * twelve aliases that is disabled. For this one it is enabled.
     *
     * See [effectivelyEnabled] for what reading it as two states cost.
     */
    private const val DEFAULT_ALIAS = PREFIX + "Dark"

    /**
     * The accent ids that have an alias, in the order they are declared.
     *
     * **Amber is the empty string on purpose.** Its two aliases are named
     * `Dark` and `Light` and were there before accents existed; renaming them
     * would change a component name that is already enabled on somebody's
     * phone, and a launcher that cannot find the component it has a shortcut to
     * drops the shortcut. Keeping the original names is not tidiness, it is the
     * one thing that stops this feature costing existing users their icon.
     *
     * Anything not in this list falls back to Amber, which is what
     * `LampAccent.fromId` does on the Dart side for the same reason.
     */
    private val ACCENTS = mapOf(
        "amber" to "",
        "rose" to "Rose",
        "sage" to "Sage",
        "slate" to "Slate",
        "plum" to "Plum",
        "ember" to "Ember"
    )

    /** Where the wanted icon is kept between [request] and [applyPending]. */
    private const val PREFS = "lamplight.icon"
    private const val KEY_ACCENT = "accent"
    private const val KEY_LIGHT = "light"

    /**
     * Records the icon the app should be wearing. **Does not change anything.**
     *
     * Called whenever the theme or the accent changes, and once at launch. See
     * the deferral note above for why this does not simply call [apply].
     */
    fun request(context: Context, accentId: String, light: Boolean) {
        // ══ WHAT *CAN* CHANGE THIS INSTANT ═══════════════════════════════════
        //
        // > *"App logo changes? i want you to alter the reality now without
        // > closing the app! even the metadata of the app needs to be changed
        // > if the logo is changed!"*
        //
        // The **launcher** icon still cannot, and the long note at the top of
        // this file is the reason: disabling the alias the running task was
        // launched from finishes that task, and he reported being thrown out
        // of the app over exactly that, twice. That deferral stays.
        //
        // But the launcher is not the only place the app wears a face. The
        // **recents switcher** takes its icon and its label from the task
        // itself, through `ActivityManager.TaskDescription`, which is a runtime
        // call with no component involved and therefore none of the risk. It
        // takes effect on the next frame.
        //
        // So the icon *does* change while the app is open — in recents, in the
        // task metadata, immediately — and the home-screen shortcut catches up
        // when the phone is put down. That is as close to "alter the reality
        // now" as Android permits without the outcome he has already rejected.
        //
        // Applied **before** the early return below, deliberately. That return
        // is an optimisation for the preference write — Dart calls this on
        // every build of `home` and almost every call says what the last one
        // said. The task description is different: a freshly created Activity
        // starts with the manifest's default icon whatever the preferences
        // say, so it has to be set on every launch and not only on a change.
        taskDescription(context, accentId, light)

        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        // Dart calls this from a post-frame callback on every build of `home`,
        // which is every rebuild of the whole app — a keystroke, a theme
        // preview, a scroll that changes a header. Writing two preference
        // values each time is not free, and round nine also contains "app feels
        // so slow". Almost every one of those calls says the same thing as the
        // last, so almost every one of them can end here.
        if (prefs.getString(KEY_ACCENT, null) == accentId &&
            prefs.contains(KEY_LIGHT) &&
            prefs.getBoolean(KEY_LIGHT, false) == light
        ) return

        prefs.edit()
            .putString(KEY_ACCENT, accentId)
            .putBoolean(KEY_LIGHT, light)
            .apply()
    }

    /**
     * Performs any swap that [request] asked for. Called from `onStop`.
     *
     * Safe to call on every stop: [apply] returns immediately when the wanted
     * alias is already the enabled one, which is the overwhelmingly common
     * case — somebody leaves the app far more often than they change a colour.
     */
    fun applyPending(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val accent = prefs.getString(KEY_ACCENT, null) ?: return
        apply(context, accent, prefs.getBoolean(KEY_LIGHT, false))
    }

    /**
     * The task's own icon and colour, applied now.
     *
     * `TaskDescription` is what the recents switcher draws, and unlike the
     * launcher icon it is a property of the running task rather than of a
     * manifest component — so setting it is a plain call with no package
     * manager, no component state, and no chance of finishing the task.
     *
     * Silent on every failure. This is decoration on top of decoration: if the
     * drawable will not load or the platform will not take the call, the app
     * keeps the icon it had and nothing about the vault is affected.
     */
    private fun taskDescription(context: Context, accentId: String, light: Boolean) {
        val activity = context as? Activity ?: return
        try {
            // The same naming the manifest uses, derived the same way
            // `aliasFor` derives its alias — amber is the unsuffixed one,
            // which is why this is not simply "ic_launcher_$accentId".
            val stem = (ACCENTS[accentId] ?: "").lowercase()
            val name = buildString {
                append("ic_launcher")
                if (stem.isNotEmpty()) append("_").append(stem)
                if (light) append("_light")
            }
            val id = activity.resources
                .getIdentifier(name, "mipmap", activity.packageName)
            val icon = if (id == 0) null else {
                val drawable = androidx.core.content.ContextCompat
                    .getDrawable(activity, id)
                drawable?.let {
                    val w = it.intrinsicWidth.coerceAtLeast(1)
                    val h = it.intrinsicHeight.coerceAtLeast(1)
                    val bmp = android.graphics.Bitmap.createBitmap(
                        w, h, android.graphics.Bitmap.Config.ARGB_8888
                    )
                    it.setBounds(0, 0, w, h)
                    it.draw(android.graphics.Canvas(bmp))
                    bmp
                }
            }
            @Suppress("DEPRECATION")
            activity.setTaskDescription(
                android.app.ActivityManager.TaskDescription(
                    // A literal, and correct as one: ADR-010 makes the app's
                    // name a proper noun that is never translated.
                    "Lamplight",
                    icon,
                    if (light) 0xFFFBF7EF.toInt() else 0xFF14110E.toInt()
                )
            )
        } catch (_: Throwable) {
            // Decoration. Never worth a crash, never worth a message.
        }
    }

    private fun aliasFor(accentId: String, light: Boolean): String {
        val stem = ACCENTS[accentId] ?: ""
        return PREFIX + when {
            stem.isEmpty() -> if (light) "Light" else "Dark"
            light -> stem + "Light"
            else -> stem
        }
    }

    /**
     * Whether [name] is on right now, reading all three states correctly.
     *
     * ══ ROUND TEN, ISSUE 24 — THIS IS WHY THE APP KEPT CLOSING ══════════════
     *
     * > *"Please don't close the app when I am changing the theme or anything
     * > in appearances tab please! I beg you that!"*
     *
     * Reported for the third time, having been fixed twice, and this is the
     * part both fixes missed.
     *
     * `getComponentEnabledSetting` returns **three** values. `ENABLED` and
     * `DISABLED` mean somebody called `setComponentEnabledSetting` at some
     * point. `DEFAULT` means nobody ever has, and the manifest decides — which,
     * for a fresh install, is *every one of the twelve aliases*.
     *
     * The old check was `if (already == ENABLED) return`. On a phone that has
     * never changed its theme, the wanted alias is `Dark`, `Dark` reports
     * `DEFAULT`, `DEFAULT` is not `ENABLED`, and so the check failed and the
     * whole swap ran: one enable and eleven disables, **every one of them
     * writing a state that was already true in effect.**
     *
     * That would be merely wasteful if it were not for what a component change
     * costs here. Disabling the alias the running task was launched from makes
     * Android finish the task — which is the bug this whole file is arranged
     * around, and why the swap waits for `onStop`. So: install the app, open
     * it, put it down, and the task is gone from recents. Open it, change the
     * theme back to what it already was, put it down, and the task is gone
     * again. From the outside that is *"it closes when I touch the appearance
     * tab"*, and it happened whether or not anything actually needed changing.
     *
     * Reading `DEFAULT` as "whatever the manifest said" is the whole fix. When
     * the icon is already right, [apply] now touches nothing at all, and a task
     * that is touched by nothing is not finished.
     */
    private fun effectivelyEnabled(pm: PackageManager, component: ComponentName): Boolean =
        when (pm.getComponentEnabledSetting(component)) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED -> false
            // COMPONENT_ENABLED_STATE_DEFAULT, and anything a future Android
            // adds: fall back to what the manifest declared.
            else -> component.className == DEFAULT_ALIAS
        }

    /**
     * Shows the icon for [accentId] in the [light] or dark plate.
     *
     * The no-op check matters for two separate reasons. `setComponentEnabledSetting`
     * is not free, and calling it on every launch would make some launchers
     * blink their icon every time the app opened — with twelve aliases that is
     * twelve pointless calls. And, far more seriously, every one of those calls
     * risks finishing the task: see [effectivelyEnabled] for the three-state
     * reading that makes the check actually fire.
     */
    fun apply(context: Context, accentId: String, light: Boolean) {
        val pm = context.packageManager
        val wantedName = aliasFor(accentId, light)
        val wanted = ComponentName(context, wantedName)

        // Everything that is on and should not be. Collected before anything is
        // written, so that "is there any work to do" can be answered without
        // having done half of it.
        val stale = mutableListOf<ComponentName>()
        for (accent in ACCENTS.keys) {
            for (isLight in listOf(false, true)) {
                val name = aliasFor(accent, isLight)
                if (name == wantedName) continue
                val component = ComponentName(context, name)
                try {
                    if (effectivelyEnabled(pm, component)) stale += component
                } catch (_: IllegalArgumentException) {
                    // An alias removed in a future version, on a phone that
                    // still holds a setting for it. Nothing to turn off.
                }
            }
        }

        // Nothing to do. **This is the line ISSUE 24 turns on**: it is reached
        // on the overwhelming majority of stops, including every stop on a
        // phone whose theme has never been changed, and reaching it means the
        // task is left alone.
        if (stale.isEmpty() && effectivelyEnabled(pm, wanted)) return

        // On first. See the ordering note above — this is the line that stops
        // the home-screen shortcut disappearing.
        if (!effectivelyEnabled(pm, wanted)) {
            pm.setComponentEnabledSetting(
                wanted,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )
        }

        // Then everything else off. Wrapped individually: a component that
        // cannot be found — an alias removed in a future version, on a phone
        // that still has the old setting — must not stop the remaining ones
        // being disabled and leave two icons in the drawer.
        for (component in stale) {
            try {
                pm.setComponentEnabledSetting(
                    component,
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
            } catch (_: IllegalArgumentException) {
            }
        }
    }
}
