package com.probablypiyush.lamplight

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Debug
import android.provider.Settings
import java.io.File
import java.security.MessageDigest

/**
 * What the app can tell about the phone it is running on.
 *
 * ══ WHAT THIS IS FOR, AND WHAT IT IS EMPHATICALLY NOT FOR ════════════════
 *
 * Asked for as "hack proof this app by all means". This is the part of that
 * which is real, and it is worth being exact about what real means here,
 * because the industry standard answer to this request is a lie.
 *
 * **Root detection cannot stop a rooted phone.** Every check below runs inside
 * the process it is trying to protect, on hardware the attacker controls. A
 * Magisk module can hide every file this looks for; Frida can rewrite the
 * function that returns the answer before it returns it. Any app that *blocks*
 * on a root check is a five-minute patch away from not blocking, and it has
 * spent that five minutes' worth of security to lock out the honest developer
 * who roots their own phone.
 *
 * So this is **not a gate**. Nothing here refuses to run, and nothing here
 * wipes anything. It is a report, shown once, in Settings, where a person who
 * cares can read it: *"this phone is rooted, which means another app could
 * potentially read Lamplight's memory while it is unlocked"*. That is a true
 * and useful sentence. "Lamplight cannot run on rooted devices" is a false one.
 *
 * ══ WHERE THE ACTUAL DEFENCE IS ══════════════════════════════════════════
 *
 * Not here. It is in the four things that hold whatever the phone is:
 *
 *   1. **The data is encrypted at rest with a key that is not stored.** Root
 *      gets you the ciphertext. Argon2id at 256 MiB per guess is what stands
 *      between the ciphertext and the notes, and root does not weaken it.
 *   2. **The keys exist only while the app is open**, and are destroyed the
 *      instant it goes into the background.
 *   3. **There is no network**, so nothing can be exfiltrated by the app even
 *      if the app is compromised.
 *   4. **FLAG_SECURE**, so nothing on screen can be captured.
 *
 * A root check adds honesty. It does not add safety, and code that pretends
 * otherwise makes an app *less* safe by making its authors think they are done.
 */
object Integrity {

    /**
     * Runs every check and returns what it found.
     *
     * Deliberately cheap — a handful of `File.exists` calls and three property
     * reads. It runs once, on demand, from a settings screen, and never on a
     * path anybody is waiting on.
     */
    fun check(context: Context): Map<String, Any> {
        val findings = mutableListOf<String>()

        if (looksRooted()) {
            findings.add(
                "This phone looks rooted. Anything with root can read another " +
                    "app's memory, so your notes are exposed while Lamplight " +
                    "is unlocked. They stay encrypted when it is locked."
            )
        }
        if (isDebuggerAttached()) {
            findings.add(
                "A debugger is attached to Lamplight. That can read everything " +
                    "the app has in memory."
            )
        }
        if (isBuildDebuggable(context)) {
            findings.add(
                "This is a development build of Lamplight, not a release one. " +
                    "It is more open than the version meant for daily use."
            )
        }
        if (isAdbEnabled(context)) {
            findings.add(
                "USB debugging is on. Anyone who plugs this phone into a " +
                    "computer they control gets a lot of access to it."
            )
        }
        if (looksLikeEmulator()) {
            findings.add("This looks like an emulator rather than a phone.")
        }

        return mapOf(
            "clean" to findings.isEmpty(),
            "findings" to findings,
            // The signer, so a person can check that the app on their phone is
            // the one it claims to be. Shown as a fingerprint rather than
            // compared against a hard-coded value: pinning our own certificate
            // inside the app is trivially patched out and would only mislead
            // whoever trusted it. A fingerprint somebody can compare against
            // the published one is the version that actually proves something.
            "signer" to signerFingerprint(context)
        )
    }

    /**
     * The usual traces of root.
     *
     * Files first, because they are the cheapest and the most reliable of a
     * generally unreliable set. `test-keys` in the build tags means the ROM was
     * signed with the public AOSP keys rather than the manufacturer's, which is
     * true of most custom ROMs and of no stock retail phone.
     */
    private fun looksRooted(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su",
            "/system/bin/.ext/.su",
            "/system/usr/we-need-root/su-backup",
            "/system/xbin/mu",
            // Magisk, which is what root actually means in practice now.
            "/sbin/.magisk",
            "/cache/.disable_magisk",
            "/dev/.magisk.unblock",
            "/data/adb/magisk",
            "/data/adb/modules"
        )
        if (paths.any { runCatching { File(it).exists() }.getOrDefault(false) }) {
            return true
        }
        if (Build.TAGS?.contains("test-keys") == true) return true

        // A writable /system is not something a stock phone has.
        return runCatching { File("/system").canWrite() }.getOrDefault(false)
    }

    private fun isDebuggerAttached(): Boolean =
        Debug.isDebuggerConnected() || Debug.waitingForDebugger()

    private fun isBuildDebuggable(context: Context): Boolean =
        (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    private fun isAdbEnabled(context: Context): Boolean = runCatching {
        Settings.Global.getInt(context.contentResolver, Settings.Global.ADB_ENABLED, 0) == 1
    }.getOrDefault(false)

    /**
     * Emulator, probably.
     *
     * Reported rather than blocked, and it is the weakest signal of the five —
     * plenty of legitimate testing happens on an emulator and some cheap
     * handsets have honestly strange build fingerprints. It is here because a
     * person who is being shown an emulator and told it is their phone deserves
     * to know.
     */
    private fun looksLikeEmulator(): Boolean {
        val f = Build.FINGERPRINT ?: ""
        return f.startsWith("generic") ||
            f.startsWith("unknown") ||
            f.contains("emulator") ||
            f.contains("vbox") ||
            Build.MODEL.contains("google_sdk") ||
            Build.MODEL.contains("Emulator") ||
            Build.MODEL.contains("Android SDK built for") ||
            Build.MANUFACTURER.contains("Genymotion") ||
            Build.PRODUCT == "google_sdk" ||
            Build.HARDWARE.contains("goldfish") ||
            Build.HARDWARE.contains("ranchu")
    }

    /**
     * SHA-256 of the certificate this build was signed with.
     *
     * Not compared against anything in here, on purpose — see the note at the
     * call site. It is displayed so that a person can hold it next to the
     * fingerprint published with the source and see whether the app on their
     * phone is the app that was built from it. That check works because it is
     * performed by a human outside the process, which is the only place a
     * check of this kind can be performed honestly.
     */
    private fun signerFingerprint(context: Context): String = runCatching {
        val pm = context.packageManager
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val info = pm.getPackageInfo(
                context.packageName,
                PackageManager.GET_SIGNING_CERTIFICATES
            )
            info.signingInfo?.apkContentsSigners
        } else {
            @Suppress("DEPRECATION")
            pm.getPackageInfo(context.packageName, PackageManager.GET_SIGNATURES).signatures
        } ?: return@runCatching ""

        val first = signatures.firstOrNull() ?: return@runCatching ""
        val digest = MessageDigest.getInstance("SHA-256").digest(first.toByteArray())
        // Grouped in pairs, the way every certificate fingerprint is printed,
        // so it can be compared by eye without losing your place.
        digest.joinToString(":") { "%02X".format(it) }
    }.getOrDefault("")
}
