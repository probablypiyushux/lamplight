package com.probablypiyush.lamplight

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.documentfile.provider.DocumentFile
import java.io.OutputStream

/**
 * Writing a readable copy of the whole vault into a folder the user chose.
 *
 * ── WHY THIS EXISTS AT ALL ──────────────────────────────────────────────────
 *
 * `08-design/ETHICAL-DESIGN.md` §3: never obstruct leaving. Until this was
 * built, the only way out of Lamplight was a `.vault` file that only Lamplight
 * can open, which means the honest answer to *"what happens to my notes if you
 * stop working on this app"* was **"they are locked in a format I invented."**
 * That is lock-in, and lock-in from a one-person project is a worse promise
 * than lock-in from a company, because the company is at least still going to
 * exist next year.
 *
 * ── WHY IT STREAMS, AND WHY THAT IS THE WHOLE POINT ─────────────────────────
 *
 * `CLAUDE.md` rule 2 says no plaintext user content on disk, ever, and it
 * carries exactly **one** exception — the `cache/handoff/` directory for "Open
 * with" — with the instruction not to widen it.
 *
 * The obvious way to build an export is to assemble the files in our own cache
 * and then copy them out. **That would widen rule 2**, and it would widen it in
 * the worst possible direction: not one file at a time, but the user's entire
 * life, in the clear, in our own storage, for as long as the export runs.
 *
 * So it is built the other way round. Dart decrypts one chunk at a time in
 * memory and pushes it straight through this class into the destination the
 * user picked. **Lamplight's own disk never holds a plaintext byte.** The
 * plaintext exists in RAM for the length of one 64 KiB chunk, and then in the
 * folder the user asked for it to be in, which is where they wanted it.
 *
 * Rule 2 is therefore untouched by this feature. There is no second exception
 * and nothing here to re-argue later.
 *
 * ── WHAT IT DELIBERATELY DOES NOT DO ────────────────────────────────────────
 *
 * It does not zip. A zip would need a compression library — a new dependency
 * that could read every note, against rule 4 — and it would hand the user one
 * opaque lump instead of a folder they can open, read and search with anything
 * they already have. A folder of Markdown files beside a folder of photographs
 * is the most portable thing this app could possibly produce.
 *
 * It holds **one** stream open at a time, on purpose. The alternative is a map
 * of open handles keyed by a token, which is a leak waiting to be written: an
 * export that fails halfway leaves file descriptors open until the process
 * dies. One at a time cannot leak more than one.
 */
class Export(private val context: Context) {

    /** The folder this export is writing into. Null between exports. */
    private var root: DocumentFile? = null

    /** The file currently open. Null between files. */
    private var sink: OutputStream? = null

    /** So [abort] can delete a half-written file rather than leave it. */
    private var current: DocumentFile? = null

    /**
     * Set when this export is going to the default place instead of a folder
     * the user picked. Holds the `Documents/Lamplight/<name>` prefix.
     *
     * ── WHY THERE IS A SECOND DESTINATION ───────────────────────────────────
     *
     * > *"All the three have an option to choose a folder! that doesn't works!
     * > … it shows me nothing!"*
     *
     * He is describing the folder picker, and "shows me nothing" is literal.
     * `ACTION_OPEN_DOCUMENT_TREE` lists **only directories**, and Android 11
     * and later hide every directory they will not grant -- so at the root of
     * internal storage the picker draws `Can't use this folder` over an empty
     * list that says `No items`. Two refusals at once, in Android's own UI,
     * before anything returns to this app. There is nothing to fix on our side
     * of that.
     *
     * So the export does what automatic backup did on 2 September: it stops
     * asking. `MediaStore` writes into `Documents/` with no permission and no
     * picker, and `RELATIVE_PATH` creates the folders on the way -- which makes
     * this the *simpler* of the two paths, not a fallback.
     *
     * The picker is kept and still works, for somebody who wants the export on
     * an SD card or in a folder of their own choosing. It is no longer the only
     * way through.
     */
    private var relativeRoot: String? = null

    /** The rows MediaStore made, so [abort] can take them back. */
    private val written = mutableListOf<Uri>()

    /**
     * Creates the export folder inside [treeUri] and returns its display name.
     *
     * The name is what Android actually used, not what we asked for. The
     * Storage Access Framework appends ` (1)` on a clash rather than
     * overwriting, and telling the user we saved to a folder name that does not
     * exist would send them looking for the wrong thing.
     */
    fun begin(treeUri: String, folderName: String): String {
        finish()
        val tree = DocumentFile.fromTreeUri(context, Uri.parse(treeUri))
            ?: throw IllegalStateException("That folder is no longer available.")
        if (!tree.canWrite()) {
            throw IllegalStateException("Lamplight cannot write to that folder.")
        }
        val made = tree.createDirectory(folderName)
            ?: throw IllegalStateException("The export folder could not be created.")
        root = made
        return made.name ?: folderName
    }

    /**
     * Starts an export into `Documents/Lamplight/[folderName]`, with no picker.
     *
     * Returns the path to show the user. Available from API 29; below that
     * `RELATIVE_PATH` does not exist and the picker is the only route, which
     * `BackupFolder.available` already reports to Settings.
     */
    fun beginDefault(folderName: String): String {
        finish()
        val base = BackupFolder.relative(context)
        relativeRoot = "$base/$folderName"
        written.clear()
        return relativeRoot!!
    }

    val defaultAvailable: Boolean
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q

    /**
     * Opens one file for writing, creating any folders named in [relativePath].
     *
     * [relativePath] is `"2026/2026-08-24.md"` or `"media/photo.jpg"` — always
     * forward slashes, always relative to the export folder. Splitting it here
     * rather than making Dart create each directory keeps the number of
     * channel round-trips proportional to the number of *files* rather than to
     * the depth of the tree.
     */
    fun open(relativePath: String, mime: String) {
        closeFile()

        val parts = relativePath.split('/').filter { it.isNotEmpty() }
        if (parts.isEmpty()) throw IllegalArgumentException("An empty path cannot be written.")

        // ── The default destination ─────────────────────────────────────────
        //
        // No directories to create: `RELATIVE_PATH` names the whole path and
        // MediaStore makes what is missing. A name already there is deleted
        // first for the same reason the SAF branch does it -- MediaStore would
        // otherwise write `photo (1).jpg` and break the link the Markdown
        // points at.
        val prefix = relativeRoot
        if (prefix != null) {
            val dirs = parts.dropLast(1).joinToString("/")
            val where = if (dirs.isEmpty()) prefix else "$prefix/$dirs"
            val name = parts.last()

            context.contentResolver.delete(
                MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL),
                "${MediaStore.MediaColumns.DISPLAY_NAME}=? AND " +
                    "${MediaStore.MediaColumns.RELATIVE_PATH}=?",
                arrayOf(name, "$where/"),
            )

            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(MediaStore.MediaColumns.RELATIVE_PATH, where)
            }
            val uri = context.contentResolver.insert(
                MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL), values,
            ) ?: throw IllegalStateException("Could not create $name in $where.")
            written += uri
            sink = context.contentResolver.openOutputStream(uri)
                ?: throw IllegalStateException("Could not write to $name.")
            return
        }

        val base = root ?: throw IllegalStateException("No export is running.")

        var dir = base
        for (i in 0 until parts.size - 1) {
            val segment = parts[i]
            // findFile before createDirectory: SAF happily creates a *second*
            // directory with the same name, and an export with two `media`
            // folders is an export that has lost half its photographs.
            dir = dir.findFile(segment)?.takeIf { it.isDirectory }
                ?: dir.createDirectory(segment)
                ?: throw IllegalStateException("Could not create $segment.")
        }

        val name = parts.last()
        // Same reasoning: a repeated name would otherwise silently produce
        // `photo (1).jpg` and break the link written into the Markdown.
        dir.findFile(name)?.delete()

        val file = dir.createFile(mime, name)
            ?: throw IllegalStateException("Could not create $name.")
        current = file
        sink = context.contentResolver.openOutputStream(file.uri)
            ?: throw IllegalStateException("Could not write to $name.")
    }

    /** Appends [bytes] to the file opened by [open]. */
    fun write(bytes: ByteArray) {
        val out = sink ?: throw IllegalStateException("No file is open.")
        out.write(bytes)
    }

    /** Finishes the current file. Safe to call when nothing is open. */
    fun closeFile() {
        sink?.let {
            it.flush()
            it.close()
        }
        sink = null
        current = null
    }

    /** Finishes the export. Safe to call twice. */
    fun finish() {
        closeFile()
        root = null
        relativeRoot = null
        written.clear()
    }

    /**
     * Gives up, and takes the half-written export with it.
     *
     * A cancelled export that leaves a folder of some-of-your-life behind is
     * worse than one that leaves nothing: the user cannot tell by looking
     * whether it is complete, and the whole reason this feature exists is to be
     * trustworthy about their data. So a cancel deletes what it made.
     */
    fun abort() {
        runCatching { sink?.close() }
        sink = null
        runCatching { current?.delete() }
        current = null
        runCatching { root?.delete() }
        root = null
        // MediaStore has no folder to delete -- the directory is implied by the
        // rows -- so every row this export made is taken back one at a time.
        // A cancelled export that leaves some-of-your-life behind is worse than
        // one that leaves nothing, and that reasoning does not change with the
        // destination.
        for (uri in written) runCatching { context.contentResolver.delete(uri, null, null) }
        written.clear()
        relativeRoot = null
    }
}
