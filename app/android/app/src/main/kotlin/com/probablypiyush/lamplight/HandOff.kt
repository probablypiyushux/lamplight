package com.probablypiyush.lamplight

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File

/**
 * Lending one file to one other app, briefly. **ISSUE 4, 13, and the margin.**
 *
 * ── WHAT HE ASKED FOR, AND THE SENTENCE THAT SHAPED IT ───────────────────
 *
 * *"Give me an option to open the file anywhere else. Why? We can't provide
 * anybody the best in file viewing. We can only give them basic experience."*
 * And, decisively: *"What I need? A way the user **doesn't download** the file
 * but is able to view this in another app which supports viewing the file
 * format."*
 *
 * The distinction between lending and saving is the whole design. "Save a copy"
 * writes a file the user then owns, keeps, and has to remember. This writes one
 * that is destroyed a minute later without anybody thinking about it.
 *
 * ── THE GRANT, NARROWED AS FAR AS ANDROID ALLOWS ─────────────────────────
 *
 * `CLAUDE.md` rule 2 forbids plaintext on disk and Piyush lifted it for this
 * path on 24 August 2026, on stated terms. This is those terms in code:
 *
 *   * The file lives in `cache/handoff/`, reachable only through the
 *     FileProvider, which is `exported="false"`.
 *   * `FLAG_GRANT_READ_URI_PERMISSION` and nothing else. Never write. The
 *     other app can read the bytes; it cannot alter what Lamplight holds.
 *   * The grant goes to **the app the user picks in the chooser**, at the
 *     moment they pick it. Nothing is granted to anything before that.
 *   * [revokeAll] takes it back the moment Lamplight is in front again, and
 *     the Dart side then overwrites and deletes the file.
 *
 * ── WHY A CHOOSER RATHER THAN A DEFAULT ──────────────────────────────────
 *
 * `Intent.createChooser` every time, deliberately, even though Android would
 * happily remember a default. A silent default would mean somebody's journal
 * handing a document to an app they picked once, months ago, without saying so.
 * The chooser is one extra tap and it is the tap where the user decides who
 * sees this — which, in this app, is the decision that matters.
 */
object HandOff {

    /** Everything currently granted, so all of it can be taken back. */
    private val lent = mutableSetOf<Uri>()

    /**
     * Offers [path] to whatever can open [mime], and reports whether the
     * chooser actually came up.
     *
     * ══ ROUND EIGHT, ISSUE 1C — "OPEN WITH DOESN'T WORKS" ════════════
     *
     * Three words in his document, and they were right about every file on the
     * phone. This method used to gate the launch on:
     *
     * ```
     * if (view.resolveActivity(context.packageManager) == null) return false
     * ```
     *
     * which reads as "ask Android whether anything can open this" and, since
     * **Android 11**, does not mean that. API 30 introduced package
     * visibility: an app targeting 30 or above cannot see other packages
     * unless it declares a `<queries>` element, and `resolveActivity` on an
     * intent it cannot see returns **null**. Not "nothing can open it" — *"you
     * are not allowed to know"*. Lamplight targets well above 30 and declares
     * no `<queries>` at all, so this returned null for every file type on
     * every device, always, and the feature reported that the phone had nothing
     * to open a PDF with.
     *
     * **The obvious fix is a `<queries>` block and it is the wrong one.** That
     * block was deleted from the manifest deliberately, and the note left in
     * its place says why: being able to enumerate installed apps is
     * fingerprinting information this app has no business holding. Restoring
     * it to recover a *pre-flight check* would trade a real privacy property
     * for a nicer error message.
     *
     * So the check is gone instead. `Intent.createChooser` always resolves —
     * the chooser is part of the system — and if genuinely nothing can handle
     * the file, Android's own chooser says so, in the platform's words, on the
     * platform's screen. `ActivityNotFoundException` is still caught, because
     * a phone with the chooser itself disabled exists and is not worth
     * crashing over.
     *
     * The result: **nothing is asked about which apps are installed, and the
     * feature works.** Both, rather than one.
     */
    fun open(context: Context, path: String, mime: String): Boolean {
        val file = File(path)
        if (!file.exists()) return false

        val uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.captures",
            file
        )
        lent.add(uri)

        val view = Intent(Intent.ACTION_VIEW).apply {
            // A type that is honest about being unknown, rather than a guess.
            // `*/*` lets the chooser offer everything, which is the right answer
            // for a file whose type the picker could not work out either.
            setDataAndType(uri, mime.ifBlank { "*/*" })
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        // ISSUE 1C. There is deliberately **no `resolveActivity` check here**.
        // See the note above: on API 30+ it answers "you are not allowed to
        // know" with the same null it uses for "nothing can open this", and
        // telling those two apart would cost a `<queries>` block this app has
        // decided not to have.
        val chooser = Intent.createChooser(view, "Open with").apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        return try {
            context.startActivity(chooser)
            true
        } catch (_: android.content.ActivityNotFoundException) {
            // A phone with no chooser at all. Vanishingly rare, and the caller
            // has something to say about it.
            lent.remove(uri)
            false
        } catch (_: Exception) {
            lent.remove(uri)
            false
        }
    }

    /**
     * Takes every grant back.
     *
     * Called when Lamplight returns to the foreground, when the vault locks and
     * at launch. Revoking a permission that has already lapsed is not an error,
     * which is why the whole thing is wrapped rather than checked.
     *
     * The Dart side overwrites and deletes the files afterwards. Both halves
     * matter: revoking without deleting leaves plaintext on disk, and deleting
     * without revoking leaves a live grant pointed at a path that could be
     * recreated.
     */
    fun revokeAll(context: Context) {
        for (uri in lent.toList()) {
            try {
                context.revokeUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                )
            } catch (_: Exception) {
            }
        }
        lent.clear()
    }
}
