package com.probablypiyush.lamplight

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import java.io.File

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

    /** The folder shown to the user, and the one they will look in. */
    const val RELATIVE = "Documents/Lamplight"

    /** What Settings says when it has to name the place. */
    const val LABEL = "Documents/Lamplight"

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
            if (rename(context, strandedPart, name)) return LABEL
        }

        // Any other stale part is a failed write and is worth nothing.
        strandedPart?.let { runCatching { resolver.delete(it, null, null) } }

        val part = resolver.insert(
            collection,
            ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, partName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/octet-stream")
                put(MediaStore.MediaColumns.RELATIVE_PATH, RELATIVE)
                // Hides the row from other apps until it is complete, and — the
                // part that matters here — stops a media scan indexing a
                // half-written vault.
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        ) ?: throw IllegalStateException(
            "Lamplight could not create a backup file in $LABEL."
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
            return "$LABEL/$partName"
        }
        return LABEL
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
            arrayOf(name, "$RELATIVE/"),
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
