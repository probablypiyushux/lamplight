package com.probablypiyush.lamplight

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import java.io.File

/**
 * Things other apps hand to Lamplight. **ISSUE 13.**
 *
 * *"A mobile has other apps — gallery, mail, files, messenger, WhatsApp,
 * telegram, Instagram. These apps has texts, photos, videos and other
 * documents, which can be shared, right? Make it possible that those things are
 * allowed to be shared to Lamplight, so it can be saved there — on that day,
 * that time."*
 *
 * ══ WHY THE INTENT IS PARKED AND NOT ACTED ON ════════════════════════════
 *
 * A share can arrive at any moment, including at a moment when this app can do
 * nothing with it: the vault is **locked** on every cold start, and there is no
 * key, no database handle and nowhere for a photograph to go until somebody
 * types a passcode. Importing eagerly is not an option and neither is refusing
 * — the user has already tapped Lamplight in the share sheet and is entitled to
 * expect the thing to arrive.
 *
 * So the intent is held here, untouched, and Dart asks for it with
 * `takeShared` **after** the vault opens. Nothing is read, copied or decoded in
 * between. If the app is killed at the lock screen the share is simply lost,
 * which is the right outcome: nothing was written anywhere, and the user can
 * share it again.
 *
 * ══ WHAT IS COPIED, AND WHEN ═════════════════════════════════════════════
 *
 * On [take], and only then, each `content://` URI is copied into this app's
 * private cache and the path is handed to Dart. That is exactly the contract
 * every other import path in this app already has — see the long note at the
 * top of `Capture.kt`'s Dart twin — so the shared file lands in
 * `AttachmentImporter`, which encrypts it into the vault and then **overwrites
 * and deletes the temp file**. `CLAUDE.md` rule 2 is satisfied by the same
 * mechanism that satisfies it for the camera and the pickers, rather than by a
 * second one written for this.
 *
 * The copy is necessary rather than lazy: a `content://` URI granted through an
 * intent is valid for as long as the receiving activity lives, and importing
 * happens after an unlock that may involve a fingerprint prompt and a second or
 * two of Argon2id. Streaming straight from the sender's URI across that would
 * be a race with a permission expiring.
 */
object Sharing {

    /** The parked intent, or null. One at a time — a second share replaces it. */
    private var pending: Intent? = null

    /** True if [park] has something waiting. Read by Dart before it asks. */
    val hasPending: Boolean get() = pending != null

    /**
     * Remembers a share to be dealt with after the next unlock.
     *
     * Returns true if this intent was actually a share, so the caller can tell
     * an ordinary launch from one.
     */
    fun park(intent: Intent?): Boolean {
        if (intent == null) return false
        val isShare = intent.action == Intent.ACTION_SEND ||
            intent.action == Intent.ACTION_SEND_MULTIPLE
        if (!isShare) return false
        pending = intent
        return true
    }

    /**
     * Hands over whatever is waiting, copying any files into private storage.
     *
     * The parked intent is cleared **first**, so a failure part-way through
     * cannot leave something that gets imported twice on the next call. A share
     * that half-arrives is a share the user can send again; a note that appears
     * twice is one they have to find and delete.
     *
     * Shape: `{"text": String?, "files": [{path, name, mime}, …]}`.
     */
    fun take(context: Context): Map<String, Any?> {
        val intent = pending ?: return mapOf("text" to null, "files" to emptyList<Any>())
        pending = null

        // Plain text — a message, a link, a paragraph someone copied. Kept as
        // words rather than as a file, because that is what it is.
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)

        val uris = mutableListOf<Uri>()
        if (intent.action == Intent.ACTION_SEND) {
            @Suppress("DEPRECATION")
            (intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM))?.let { uris.add(it) }
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                ?.let { uris.addAll(it) }
        }

        val scratch = File(context.cacheDir, "shared").apply { mkdirs() }
        val files = mutableListOf<Map<String, Any?>>()
        for (uri in uris) {
            // One bad item must not lose the rest of a twenty-photo share.
            runCatching { copyIn(context, uri, scratch) }.getOrNull()?.let(files::add)
        }

        return mapOf("text" to text, "files" to files)
    }

    private fun copyIn(context: Context, uri: Uri, scratch: File): Map<String, Any?> {
        val name = displayName(context, uri) ?: "shared"
        val mime = context.contentResolver.getType(uri) ?: "application/octet-stream"

        // A random file name rather than the sender's. Two apps sharing
        // "IMG_0001.jpg" in one session would otherwise overwrite each other,
        // and the real name travels in the map and ends up in the encrypted
        // database rather than on the filesystem — same rule as every other
        // attachment.
        val target = File(scratch, "${System.nanoTime()}-${uris++}")
        context.contentResolver.openInputStream(uri)?.use { input ->
            target.outputStream().use { out -> input.copyTo(out) }
        } ?: throw IllegalStateException("That file could not be read.")

        return mapOf("path" to target.absolutePath, "name" to name, "mime" to mime)
    }

    private var uris = 0

    private fun displayName(context: Context, uri: Uri): String? {
        context.contentResolver
            .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val column = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (column >= 0) return cursor.getString(column)
                }
            }
        return uri.lastPathSegment
    }
}
