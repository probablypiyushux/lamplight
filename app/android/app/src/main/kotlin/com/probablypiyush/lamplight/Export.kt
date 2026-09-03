package com.probablypiyush.lamplight

import android.content.Context
import android.net.Uri
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
     * Opens one file for writing, creating any folders named in [relativePath].
     *
     * [relativePath] is `"2026/2026-08-24.md"` or `"media/photo.jpg"` — always
     * forward slashes, always relative to the export folder. Splitting it here
     * rather than making Dart create each directory keeps the number of
     * channel round-trips proportional to the number of *files* rather than to
     * the depth of the tree.
     */
    fun open(relativePath: String, mime: String) {
        val base = root ?: throw IllegalStateException("No export is running.")
        closeFile()

        val parts = relativePath.split('/').filter { it.isNotEmpty() }
        if (parts.isEmpty()) throw IllegalArgumentException("An empty path cannot be written.")

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
    }
}
