package com.probablypiyush.lamplight

import android.content.Context
import android.net.Uri
import androidx.documentfile.provider.DocumentFile

/**
 * Reading somebody's existing journal out of a folder they chose.
 *
 * ── WHY THIS EXISTS ─────────────────────────────────────────────────────────
 *
 * The person who installs a journal app is, almost by definition, somebody who
 * already journals — and who therefore has years of it somewhere else. Until
 * this was built, using Lamplight meant abandoning all of it, in order to adopt
 * an app whose whole promise is remembering your past. That contradiction sat
 * at the front door and most people would simply close the tab.
 *
 * ── WHY THE URIs STAY ON THIS SIDE ──────────────────────────────────────────
 *
 * `document_store.dart` says, and means, that no content URI ever crosses into
 * Dart: the app should not be able to hold a handle on the user's storage after
 * the one operation they agreed to. Importing needs to address individual files
 * inside a folder, which naively means handing Dart a list of URIs and
 * breaking that.
 *
 * So it doesn't. [scan] walks the tree once and keeps the list **here**, and
 * Dart addresses files by their position in it. Dart never learns a URI, cannot
 * construct one, and the list dies with [clear] or with the activity. The
 * property survives a feature that looked like it would cost it.
 *
 * ── WHAT IT WILL AND WILL NOT READ ──────────────────────────────────────────
 *
 * Text only, and deliberately. Photographs and videos in an imported folder are
 * a much larger job — they have to be streamed into the encrypted attachment
 * store, matched to the entries that reference them, and rewritten in the text
 * — and doing half of it would produce entries pointing at pictures that are
 * not there. Text alone is complete and honest; the media import can come
 * later as its own thing.
 */
class Import(private val context: Context) {

    /** The files found by the last [scan]. Dart indexes into this. */
    private var found: List<DocumentFile> = emptyList()

    /**
     * Walks [treeUri] and remembers every text file in it.
     *
     * Returns one map per file — `path` relative to the chosen folder, and
     * `size`. The path rather than the bare name because two folders may each
     * hold `2026-08-24.md`, and a screen that lists twelve identical names is
     * a screen nobody can check before agreeing to it.
     */
    fun scan(treeUri: String): List<Map<String, Any>> {
        val tree = DocumentFile.fromTreeUri(context, Uri.parse(treeUri))
            ?: throw IllegalStateException("That folder is no longer available.")

        val files = mutableListOf<DocumentFile>()
        val paths = mutableListOf<String>()
        walk(tree, "", files, paths)

        found = files
        return files.indices.map {
            mapOf(
                "index" to it,
                "path" to paths[it],
                "size" to files[it].length(),
                // ROUND EIGHT, ISSUE 11. When the file was last written, so a
                // file whose name says nothing about when it happened can
                // still be offered a date rather than simply refused. Zero
                // when the provider will not say, which Dart reads as "no
                // date available" rather than as 1970.
                "modified" to files[it].lastModified()
            )
        }
    }

    /**
     * Remembers a set of files the person picked one by one, instead of a
     * folder they were allowed to hand over.
     *
     * ── WHY THERE IS A SECOND WAY IN ────────────────────────────────────────
     *
     * `ACTION_OPEN_DOCUMENT_TREE` asks Android for a whole folder for ever, and
     * Android 11 and later simply refuses some of them: the root of internal
     * storage, an SD-card root, and **Downloads** -- which is exactly where a
     * journal exported from another app lands. The refusal happens inside
     * Android's own picker, with Android's own sentence -- *"Can't use this
     * folder. To protect your privacy, choose another folder"* -- before
     * anything comes back to this app. Nothing in our result handling can
     * reach it, `EXTRA_INITIAL_URI` is a hint a provider may ignore, and one
     * tap on the drawer is back at the root. Three rounds were spent proving
     * that, and the conclusion is in `MainActivity`: **an initial location
     * cannot fix a refusal.**
     *
     * `ACTION_OPEN_DOCUMENT` is not refused, because it does not ask for the
     * folder. It asks for the files, the user picks exactly which ones, and
     * the grant is per file rather than a standing key to a directory. It
     * works in Downloads, at the root, on an SD card, and on a cloud provider
     * that has no folder to hand over at all.
     *
     * So this is the same move automatic backup made on 2 September, in the
     * other direction: **stop asking Android for something it is entitled to
     * refuse.** The folder route is kept, because for a real journal folder it
     * is far less tapping and it works whenever the folder is an ordinary one.
     *
     * Everything downstream is unchanged. The list this fills is the same list
     * [scan] fills, so `readText` and the whole Dart import work as they were,
     * and **no content URI crosses into Dart** either way -- the promise at the
     * top of this file survives a second entrance.
     */
    fun adopt(uris: List<String>): List<Map<String, Any>> {
        val files = mutableListOf<DocumentFile>()
        val paths = mutableListOf<String>()

        for (raw in uris) {
            val file = DocumentFile.fromSingleUri(context, Uri.parse(raw)) ?: continue
            if (!file.isFile) continue
            // The picker was asked for text, but a MIME filter is advice: a
            // provider may report `application/octet-stream` for a `.md`, and
            // some file managers offer everything regardless. The same name
            // test the folder walk uses decides here too, so both doors admit
            // exactly the same things.
            val name = file.name ?: continue
            if (!isText(name)) continue
            files += file
            paths += name
            if (files.size >= MAX_FILES) break
        }

        found = files
        return files.indices.map {
            mapOf(
                "index" to it,
                "path" to paths[it],
                "size" to files[it].length(),
                "modified" to files[it].lastModified()
            )
        }
    }

    /**
     * The contents of one scanned file, as text.
     *
     * Read whole rather than streamed: these are journal entries, capped at
     * [MAX_BYTES], and the caller needs the entire string to write one row.
     * Anything bigger than the cap is not a diary entry — it is a log file or
     * a novel that wandered into the folder — and truncating it silently would
     * be worse than skipping it, so it is refused with a message the user sees.
     */
    fun readText(index: Int): String {
        val file = found.getOrNull(index)
            ?: throw IllegalStateException("That file is no longer there.")
        if (file.length() > MAX_BYTES) {
            throw IllegalStateException("${file.name} is too large to be a note.")
        }
        return context.contentResolver.openInputStream(file.uri)?.use { stream ->
            // Decoded as UTF-8 with replacement rather than strictly. A journal
            // exported by some other app in 2013 may well have a stray byte in
            // it, and losing the whole entry over one character would be the
            // wrong trade for the person who wrote it.
            String(stream.readBytes(), Charsets.UTF_8)
        } ?: throw IllegalStateException("${file.name} could not be opened.")
    }

    /** Forgets the scan. Called when the import ends, and on the way out. */
    fun clear() {
        found = emptyList()
    }

    private fun walk(
        dir: DocumentFile,
        prefix: String,
        into: MutableList<DocumentFile>,
        paths: MutableList<String>,
    ) {
        if (into.size >= MAX_FILES) return
        for (child in dir.listFiles()) {
            if (into.size >= MAX_FILES) return
            val name = child.name ?: continue
            // Hidden files and folders are skipped. `.obsidian` and `.git` are
            // full of text files that are configuration rather than diary, and
            // importing somebody's plugin settings as journal entries is a
            // memorable way to lose their trust in the first minute.
            if (name.startsWith(".")) continue
            if (child.isDirectory) {
                walk(child, "$prefix$name/", into, paths)
            } else if (isText(name)) {
                into.add(child)
                paths.add("$prefix$name")
            }
        }
    }

    /**
     * Whether this is plausibly somebody's writing. **ROUND EIGHT, ISSUE 11.**
     *
     * *"I want you to make the importing 100% possible! At all times! Accept
     * everything!"*
     *
     * The old list was four extensions, and four is not "everything" — it
     * misses `.markdown` variants nobody agrees on, Emacs org files, plain
     * `.log` day books, and **files with no extension at all**, which is how a
     * great many Unix-shaped journals are kept and how several export tools
     * write their output.
     *
     * It is still a list rather than "every file", and that is deliberate
     * rather than timid. A folder picked at the root of a phone contains
     * photographs, databases and APKs, and reading a JPEG as UTF-8 produces a
     * screenful of replacement characters filed as a diary entry. Refusing a
     * binary is not refusing the user; it is the difference between importing
     * a journal and importing a disk.
     *
     * The extensionless case is allowed **only when the name is short and
     * carries no dot**, which is what `README` or `2026-08-24` looks like and
     * is not what `libsodium.so.26` looks like.
     */
    private fun isText(name: String): Boolean {
        val lower = name.lowercase()
        val dot = lower.lastIndexOf('.')
        if (dot <= 0 || dot == lower.length - 1) {
            // No extension at all. Length-capped so a stray binary with an
            // unusual name does not walk in.
            return lower.length <= 64
        }
        return when (lower.substring(dot)) {
            ".txt", ".text", ".md", ".markdown", ".mdown", ".mkd", ".mkdn",
            ".org", ".rst", ".log", ".note", ".notes", ".journal", ".diary",
            ".entry", ".asc", ".me", ".1st", ".textile", ".adoc", ".taskpaper"
            -> true
            else -> false
        }
    }

    companion object {
        /**
         * A ceiling on the walk, so a user who picks the root of their SD card
         * gets a refusal rather than a scan that never finishes.
         */
        private const val MAX_FILES = 20_000

        /** One megabyte. Past this it is not a journal entry. */
        private const val MAX_BYTES = 1L * 1024 * 1024
    }
}
