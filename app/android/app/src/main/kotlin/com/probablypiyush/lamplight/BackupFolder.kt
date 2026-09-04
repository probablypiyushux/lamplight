package com.probablypiyush.lamplight

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import java.io.File
import java.io.FileOutputStream

/**
 * Where an automatic backup goes when nobody has chosen anywhere.
 *
 * ══ WHY THIS EXISTS. 2 SEPTEMBER 2026 ═══════════════════════════════════════
 *
 * > *"Choose folder doesn't works man! And please i beg you to fix the folder
 * > issue! check the photo!"*
 *
 * The photo showed Android's own picker sitting at the root of internal
 * storage with **"Can't use this folder — to protect your privacy, choose
 * another folder"** across the top, and the "use this folder" button greyed
 * out. He was on `versionCode=12`, which already had the fix that was supposed
 * to prevent this, so the fix was not enough and the reason is worth stating
 * exactly.
 *
 * ── THE PART THAT CANNOT BE FIXED ─────────────────────────────────────────
 *
 * `ACTION_OPEN_DOCUMENT_TREE` asks Android to hand this app **a whole folder,
 * for ever**. Since Android 11 the system refuses that for the root of
 * internal storage, the root of an SD card, and `Download` — and it refuses it
 * *inside its own picker*, before any result comes back here. The app is never
 * told, cannot pre-empt it, and cannot change the wording.
 *
 * Round sixteen answered that by asking the picker to *open* in `Documents`,
 * using `EXTRA_INITIAL_URI`. That is a **hint**, in the specification's own
 * words, and a provider may ignore it — and even when honoured it only decides
 * where the picker starts. One tap on the navigation drawer and he is back at
 * the root, looking at the same refusal. **A hint cannot fix a restriction.**
 *
 * ── SO STOP ASKING FOR A FOLDER ───────────────────────────────────────────
 *
 * The picker was never the requirement. The requirement is *a copy of the
 * vault, outside the app's own sandbox, that survives uninstalling Lamplight*
 * — because `allowBackup="false"` means an uninstall takes the vault with it,
 * and a `.vault` on the same disk is the only thing standing between him and
 * the accident that already happened once in this project on 28 August.
 *
 * `MediaStore` gives exactly that, on Android 10 and later, **with no
 * permission and no picker at all**. An app may create files in the shared
 * `Documents/` collection, they outlive the app, and the app keeps write
 * access to the rows it created. There is nothing to grant, so there is
 * nothing to be refused, so **the message in his screenshot cannot occur**.
 *
 * Choosing a folder by hand still works and is still offered — somebody who
 * wants their backups on an SD card should have them there. It is no longer
 * the price of admission for having any backup at all.
 *
 * ── WHY THE WRITE IS STILL DONE IN TWO STEPS ──────────────────────────────
 *
 * `UX-FLOWS.md` flow 5 calls a corrupt overwrite of your only backup the worst
 * outcome in the whole app, and that judgement does not change because the
 * destination did. So this writes `Lamplight.vault.part`, and only when that
 * file is closed and complete does it delete the previous `Lamplight.vault`
 * and rename the part over it. A run interrupted at any point leaves either
 * the old backup intact or a complete new one — never half of either.
 *
 * That is the same sequence `writeIntoTree` performs against a chosen folder,
 * deliberately, so there is one story about what a backup does rather than two.
 */
object BackupFolder {

    /**
     * The folder shown to the user, and the one they will look in.
     *
     * ── WHY THIS IS NOT A CONSTANT ──────────────────────────────────────────
     *
     * It was, and that was very nearly expensive. `Documents/Lamplight` was
     * hard-coded, and so is the file inside it -- one folder, one name,
     * replaced on every backup, which is the right design for one app.
     *
     * The sandbox build is a *second* app: same code, different application
     * id, its own empty vault, installed side by side so that deleting and
     * restoring can be exercised without anybody's real journal in the way. It
     * inherited this constant. So the moment automatic backup ran in the
     * sandbox it would have written `Lamplight.vault.part`, then **deleted the
     * real `Lamplight.vault`** and swapped a test vault into its place -- and
     * the real one is the only copy of the journal that survives uninstalling
     * the app.
     *
     * Caught on 4 September 2026 while about to do exactly that, by reading
     * this file rather than by losing anything. The folder is named after the
     * application id now, so two installed builds cannot collide, and the real
     * app's path is unchanged for everybody who already has backups there.
     */
    fun relative(context: Context): String =
        if (context.packageName.endsWith(".sandbox")) {
            "Documents/Lamplight Sandbox"
        } else {
            "Documents/Lamplight"
        }

    /** What Settings says when it has to name the place. */
    fun label(context: Context): String = relative(context)


    /**
     * Whether this device can be written to without asking for anything.
     *
     * API 29. Below it, `RELATIVE_PATH` does not exist and writing outside the
     * sandbox needs `WRITE_EXTERNAL_STORAGE` — a permission this app will not
     * add, because it grants the whole of shared storage to read as well as
     * write and would appear in the store listing beside the claim that
     * Lamplight asks for almost nothing. On those devices the folder picker is
     * the only route, and Settings says so rather than offering a switch that
     * cannot work.
     */
    val available: Boolean
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

    /**
     * Copies the backup this app wrote into [destination], if there is one.
     *
     * Returns its display name, or null when no backup exists yet.
     *
     * ── WHY RESTORE DOES NOT HAVE TO USE A PICKER ───────────────────────────
     *
     * *"so man it never shows folders too!"* — and on his tablet the file
     * picker at the top of internal storage shows literally `No items`. A
     * folder picker never lists files, and MIUI's provider lists nothing at all
     * at that root, so somebody trying to get their journal back is looking at
     * an empty screen with no way forward unless they happen to know to open
     * the drawer and choose Downloads.
     *
     * The backup this app writes is at a path this app already knows. So the
     * ordinary case -- *"put my journal back from my own backup"* -- needs no
     * picker at all, which is the same answer automatic backup, the readable
     * copy and the journal importer each arrived at. The picker stays for a
     * backup kept somewhere else, on a memory card, or sent from another phone.
     */
    fun copyLatestInto(context: Context, destination: String): String? {
        val name = "Lamplight.vault"
        val uri = findIn(context, name) ?: return null
        File(destination).parentFile?.mkdirs()
        context.contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(File(destination)).use { output ->
                input.copyTo(output, 64 * 1024)
            }
        } ?: return null
        return name
    }

    /** Whether [copyLatestInto] has anything to copy. */
    fun latestExists(context: Context): Boolean =
        available && findIn(context, "Lamplight.vault") != null

    /**
     * Copies [sourcePath] to `Documents/Lamplight/[name]`, replacing whatever
     * was there, and returns the label to show the user.
     *
     * Throws with a sentence a person can read. Every failure here is reported
     * on the settings screen rather than as a dialog — see `SilentBackup`.
     */
    fun write(context: Context, sourcePath: String, name: String): String {
        check(available) {
            "This version of Android needs a folder to be chosen by hand."
        }

        val resolver = context.contentResolver
        val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val partName = "$name.part"

        // A run that died between the delete and the rename last time leaves a
        // complete part and no real file. That part IS the backup; put it back
        // before doing anything else. Identical reasoning to `recoverPart`.
        val strandedPart = findIn(context, partName)
        if (strandedPart != null && findIn(context, name) == null) {
            if (rename(context, strandedPart, name)) return label(context)
        }

        // Any other stale part is a failed write and is worth nothing.
        strandedPart?.let { runCatching { resolver.delete(it, null, null) } }

        val part = resolver.insert(
            collection,
            ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, partName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/octet-stream")
                put(MediaStore.MediaColumns.RELATIVE_PATH, relative(context))
                // Hides the row from other apps until it is complete, and — the
                // part that matters here — stops a media scan indexing a
                // half-written vault.
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        ) ?: throw IllegalStateException(
            "Lamplight could not create a backup file in ${label(context)}."
        )

        try {
            resolver.openOutputStream(part, "wt")?.use { out ->
                File(sourcePath).inputStream().use { input -> input.copyTo(out) }
            } ?: throw IllegalStateException("The backup file could not be written.")

            resolver.update(
                part,
                ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) },
                null,
                null
            )
        } catch (e: Throwable) {
            // A half-written part must never be left where the recovery branch
            // above would mistake it for a complete one.
            runCatching { resolver.delete(part, null, null) }
            throw e
        }

        // The new copy is complete. Only now does the old one go.
        findIn(context, name)?.let { runCatching { resolver.delete(it, null, null) } }

        if (!rename(context, part, name)) {
            // Some devices refuse the rename. The backup is safe — it is the
            // part file and it is complete — so leave it rather than deleting a
            // good copy to tidy up a name.
            return "${label(context)}/$partName"
        }
        return label(context)
    }

    /** The row for [name] inside our folder, or null. */
    private fun findIn(context: Context, name: String): Uri? {
        val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        // `RELATIVE_PATH` is stored with a trailing separator, which is the
        // kind of thing that silently matches nothing if assumed either way.
        return context.contentResolver.query(
            collection,
            arrayOf(MediaStore.MediaColumns._ID),
            "${MediaStore.MediaColumns.DISPLAY_NAME}=? AND " +
                "${MediaStore.MediaColumns.RELATIVE_PATH}=?",
            arrayOf(name, "${relative(context)}/"),
            null
        )?.use { cursor ->
            if (!cursor.moveToFirst()) return null
            android.content.ContentUris.withAppendedId(
                collection,
                cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID))
            )
        }
    }

    private fun rename(context: Context, uri: Uri, to: String): Boolean = runCatching {
        context.contentResolver.update(
            uri,
            ContentValues().apply { put(MediaStore.MediaColumns.DISPLAY_NAME, to) },
            null,
            null
        ) > 0
    }.getOrDefault(false)
}
