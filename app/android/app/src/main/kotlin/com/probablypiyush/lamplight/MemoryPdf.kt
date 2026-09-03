package com.probablypiyush.lamplight

import android.content.Context
import android.graphics.Bitmap
import android.os.Build
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.pdf.PdfRenderer
import android.os.Handler
import android.os.HandlerThread
import android.os.ParcelFileDescriptor
import android.os.ProxyFileDescriptorCallback
import android.os.storage.StorageManager
import android.system.ErrnoException
import android.system.OsConstants
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.min

/**
 * A PDF, rendered from memory. **ISSUE 4 — his angriest item.**
 *
 * ── THE PROBLEM, AND WHY IT IS NOT AS EASY AS IT LOOKS ────────────────────
 *
 * Tapping a PDF in the vault did nothing you could act on. `CLAUDE.md` test 6
 * calls a control that does nothing when tapped the same defect as a crash,
 * wearing better clothes, and this was that.
 *
 * The obvious answer — hand the file to Adobe or to Google Drive — means
 * writing somebody's decrypted document to disk and giving another app a URI
 * to it. `CLAUDE.md` rule 2 has no exception for "briefly, while they read
 * it", and that is exactly what it would be.
 *
 * So the PDF has to be rendered *here*, and Android's own `PdfRenderer` is the
 * right tool for it: no new dependency, so rule 4 stays intact, and the same
 * decoder every other app on the phone uses. The catch is its constructor. It
 * takes a `ParcelFileDescriptor` and it must be **seekable** — a PDF's
 * cross-reference table lives at the end of the file, so the renderer reads
 * backwards before it reads anything else. That rules out
 * `ParcelFileDescriptor.createPipe()`, which is the trick the audio and video
 * players use.
 *
 * ── WHAT MAKES THIS WORK WITHOUT A FILE ──────────────────────────────────
 *
 * `StorageManager.openProxyFileDescriptor`, public since API 26. It returns a
 * real, seekable file descriptor whose reads are **served by a callback in this
 * process**. Nothing is written anywhere: `onRead` copies out of the byte array
 * the caller already holds in memory, at whatever offset the renderer asks for.
 *
 * It is the `MediaDataSource` idea in the one shape the PDF renderer accepts,
 * and it is the only way I know of to satisfy both `PdfRenderer` and rule 2 at
 * the same time.
 *
 * ── WHAT IT COSTS, SAID PLAINLY ──────────────────────────────────────────
 *
 * The plaintext PDF is in RAM for as long as the viewer is open, exactly as the
 * video player's is. That is fine for the documents a journal holds — a ticket,
 * a letter, a scan — and the Dart side refuses above a threshold rather than
 * pretending.
 *
 * The proxy descriptor needs FUSE, and a small number of devices do not have
 * it. On those, `openProxyFileDescriptor` throws and the Dart side says so out
 * loud and offers to save a copy instead. A clear sentence is not a failure;
 * silence is.
 */
class MemoryPdf(private val context: Context) {

    companion object {
        /**
         * The most any single side of a rasterised tile may be.
         *
         * GPU texture limits are commonly 4096 on the phones this app is for,
         * and a bitmap wider than the texture that has to hold it is a page
         * that fails to appear on some devices and not others -- the worst kind
         * of bug to be told about.
         */
        private const val MAX_DIMENSION = 4096

        /**
         * And the most a tile may be in total.
         *
         * 8 megapixels is 32 MB as ARGB_8888, briefly doubled while the pixels
         * are copied out of it. That is comfortably more than a phone screen's
         * worth -- a 1440 x 3200 display is 4.6 MP -- so the cap is never
         * reached in normal use and is there for the case that would otherwise
         * take the process down.
         */
        private const val MAX_PIXELS = 8_000_000.0
    }

    private var renderer: PdfRenderer? = null
    private var descriptor: ParcelFileDescriptor? = null
    private var callbackThread: HandlerThread? = null
    private val work = Executors.newSingleThreadExecutor()

    // ══ THE PAGE IS HELD OPEN BETWEEN TILES ═══════════════════════════════════
    //
    // > *"Pdf viewer? make it faster!"*
    //
    // `render` used to call `openPage` and `close` around every single request.
    // For the page list that is once per page and fine. For **zooming** it is
    // not: the viewer asks for the visible rectangle as a grid of tiles, so one
    // pinch is a handful of requests against the *same* page, and each one was
    // re-parsing that page's content stream from scratch before drawing a
    // fraction of it.
    //
    // `PdfRenderer` allows exactly one page open at a time, so this is a cache
    // of one — which is all that is needed, because the requests that repeat
    // are always for the page being looked at. Opening a different page closes
    // the previous one first, which is the same call that used to happen every
    // time.
    //
    // Everything here runs on `work`, a single-threaded executor, so the field
    // needs no synchronisation of its own: there is only ever one renderer
    // touching it and never two at once. That is worth stating because a cache
    // that looks thread-unsafe invites somebody to add a lock or, worse, a
    // second thread.
    private var openPage: PdfRenderer.Page? = null
    private var openPageIndex = -1

    /**
     * Every page's height / width, measured once. **ISSUE 8.**
     *
     * One page is open at a time — `PdfRenderer` allows no more — so this walks
     * them, and it is the only thing in this file that touches every page. It
     * closes as it goes and leaves nothing open, because the first *render*
     * after this will open whichever page it wants anyway.
     *
     * A page that will not open is 1.414, which is A4 and is what the viewer
     * used to assume for all of them. Refusing to open the document because one
     * page's dictionary is damaged would be the wrong trade by a long way.
     */
    private fun measure(r: PdfRenderer): DoubleArray {
        val count = min(r.pageCount, measureLimit)
        val out = DoubleArray(count) { 1.414 }
        for (i in 0 until count) {
            try {
                r.openPage(i).use { page ->
                    val w = page.width.toDouble()
                    val h = page.height.toDouble()
                    if (w > 0 && h > 0) out[i] = h / w
                }
            } catch (_: Throwable) {
                // Left at A4. See above.
            }
        }
        return out
    }

    /** The page [index], reusing the one already open when it is the same. */
    private fun pageFor(r: PdfRenderer, index: Int): PdfRenderer.Page {
        val held = openPage
        if (held != null && openPageIndex == index) return held
        closePageQuietly()
        val fresh = r.openPage(index)
        openPage = fresh
        openPageIndex = index
        return fresh
    }

    private fun closePageQuietly() {
        try {
            openPage?.close()
        } catch (_: Exception) {
        }
        openPage = null
        openPageIndex = -1
    }

    /** Page count, or 0 when nothing is open. */
    var pageCount = 0
        private set

    /**
     * The shape of every page, as height / width. **ROUND FIFTEEN, ISSUE 8.**
     *
     * > *"Imagine a pdf is 40MB and has 10 pages - shows only first two pages
     * > other pages? ... scroll to 50th page and see that doesn't even show me!
     * > ... When scroll down Fastly down to the end it behaves jerky."*
     *
     * Almost every one of those traces back to the same absence: **the viewer
     * did not know how tall a page was until it had drawn it.** So the list
     * laid every page out as A4, and then each one changed size as its bitmap
     * arrived — which moves everything below it, which moves the scroll offset,
     * which is what "jerky" is. It also meant the page number was computed as
     * `scrollFraction x (pages - 1)`, an estimate that is only correct when
     * every page is identical, and it is what made "go to page 50" land
     * somewhere else.
     *
     * Measuring is cheap in a way rendering is not: `openPage` parses the page
     * dictionary and gives up its media box; nothing is rasterised and no
     * bitmap is allocated. Even a 400-page document is a few tens of
     * milliseconds, once, on the worker.
     *
     * Capped, because a PDF can claim a hundred thousand pages and a list of
     * that many doubles is 800 KB for a document nobody is going to read to the
     * end. Past the cap the viewer falls back to A4, which is what it always
     * did.
     */
    var pageShapes: DoubleArray = DoubleArray(0)
        private set

    /** Beyond this, page shapes are not measured. See [pageShapes]. */
    private val measureLimit = 5_000

    /**
     * Opens [data] and reports how many pages it has.
     *
     * Everything happens on a worker: parsing a PDF's structure is real work
     * and the app whose entire complaint history is "it hangs" is not doing it
     * on the main thread.
     */
    fun open(
        data: ByteArray,
        onReady: (pages: Int) -> Unit,
        onError: (String) -> Unit
    ) {
        close()
        work.execute {
            try {
                val storage = context.getSystemService(Context.STORAGE_SERVICE)
                    as StorageManager

                // The callback must not run on the thread that is waiting for
                // the read, or the descriptor deadlocks the first time
                // PdfRenderer seeks. Its own thread, torn down in `close`.
                val thread = HandlerThread("lamplight-pdf").apply { start() }
                callbackThread = thread

                val pfd = storage.openProxyFileDescriptor(
                    ParcelFileDescriptor.MODE_READ_ONLY,
                    object : ProxyFileDescriptorCallback() {
                        override fun onGetSize(): Long = data.size.toLong()

                        override fun onRead(
                            offset: Long,
                            size: Int,
                            out: ByteArray
                        ): Int {
                            if (offset >= data.size) return 0
                            val n = min(
                                size.toLong(),
                                data.size - offset
                            ).toInt()
                            System.arraycopy(data, offset.toInt(), out, 0, n)
                            return n
                        }

                        override fun onWrite(
                            offset: Long,
                            size: Int,
                            input: ByteArray
                        ): Int {
                            // Read-only, and deliberately not silently ignored:
                            // a write that appeared to succeed and went nowhere
                            // would be the worst kind of quiet failure.
                            throw ErrnoException("onWrite", OsConstants.EBADF)
                        }

                        override fun onFsync() {}

                        override fun onRelease() {}
                    },
                    Handler(thread.looper)
                )
                descriptor = pfd
                val r = PdfRenderer(pfd)
                renderer = r
                pageCount = r.pageCount
                pageShapes = measure(r)
                VoiceCapture.mainHandler.post { onReady(r.pageCount) }
            } catch (e: UnsupportedOperationException) {
                // No FUSE on this device. Real, rare, and worth naming rather
                // than swallowing.
                closeQuietly()
                VoiceCapture.mainHandler.post {
                    onError("This phone cannot open a PDF without writing it to storage first, so Lamplight will not show it here.")
                }
            } catch (e: SecurityException) {
                closeQuietly()
                VoiceCapture.mainHandler.post {
                    onError("That document is password protected.")
                }
            } catch (e: Exception) {
                closeQuietly()
                VoiceCapture.mainHandler.post {
                    onError("That document could not be opened. It may be damaged.")
                }
            } catch (e: OutOfMemoryError) {
                closeQuietly()
                VoiceCapture.mainHandler.post {
                    onError("That document is too large to open on this phone.")
                }
            }
        }
    }

    /**
     * Draws part of a page and hands back raw RGBA.
     *
     * -- ISSUE 1 -- "PDF ZOOM CRASH!" AND WHAT WAS ACTUALLY CAUSING IT -------
     *
     * This used to take a [targetWidth] and rasterise the **whole page** at it.
     * The Dart side, on zooming, asked for the page again at 2x, then 4x, up to
     * 4096 across. An A4 page at 4096 wide is 4096 x 5793, and that number is
     * where the crash lived:
     *
     *   * the `Bitmap`                        ~95 MB
     *   * the `ByteBuffer` copied out of it   ~95 MB   (alive at the same time)
     *   * the copy handed across to Dart      ~95 MB
     *
     * Nearly 300 MB for one page, against a heap that is commonly 256 MB, with
     * two or three neighbouring pages of the list each holding their own. It
     * did not crash *sometimes* for a mysterious reason -- it crashed when you
     * zoomed far enough, which is exactly what he reported.
     *
     * Capping the number lower would have made it rarer and blurrier, which is
     * the wrong trade twice over. **So the page is no longer what gets
     * rasterised.** [region] names a sub-rectangle in normalised page
     * coordinates, and what comes back is that rectangle drawn at the size it
     * is actually being shown at. Zoom in and the rectangle gets smaller while
     * the bitmap stays the size of the screen -- the memory does not move,
     * because the screen has not got any bigger.
     *
     * That is how every real reader on the phone does it, and it is why they
     * can zoom to 8x on a handset that would not survive one page at 4096.
     *
     * `PdfRenderer.Page.render` takes the transform directly, so this costs one
     * `Matrix` and no extra work: the renderer draws only what lands inside the
     * bitmap, so a tile of a tenth of the page is also about a tenth of the
     * drawing.
     *
     * Raw pixels rather than a re-encoded PNG, for the same reason
     * [ImageFallback] does it: the caller allocates the same buffer either way,
     * and re-encoding would be work done twice to make the wire smaller inside
     * a single process.
     *
     * The white fill is not decoration. A PDF page has no background of its
     * own -- it is ink on nothing -- and a bitmap starts transparent, so
     * without this the black text would land on the app's near-black canvas and
     * the page would look empty. The viewer dims the whole page in dark mode
     * instead, which is what a reader expects and what a per-pixel invert is
     * not.
     */
    fun render(
        page: Int,
        targetWidth: Int,
        region: FloatArray?,
        onDone: (width: Int, height: Int, pixels: ByteArray) -> Unit,
        onError: (String) -> Unit
    ) {
        work.execute {
            try {
                val r = renderer ?: throw IllegalStateException("no document")
                if (page < 0 || page >= r.pageCount) {
                    throw IndexOutOfBoundsException("page $page")
                }
                val open = pageFor(r, page)

                // The slice of the page being asked for, in page units. Null
                // means all of it, which is what the unzoomed list wants.
                val left = (region?.get(0) ?: 0f).coerceIn(0f, 1f)
                val top = (region?.get(1) ?: 0f).coerceIn(0f, 1f)
                val right = (region?.get(2) ?: 1f).coerceIn(left, 1f)
                val bottom = (region?.get(3) ?: 1f).coerceIn(top, 1f)

                val pw = open.width.toDouble()
                val ph = open.height.toDouble()
                val rw = max(1.0, (right - left) * pw)
                val rh = max(1.0, (bottom - top) * ph)

                // How much bigger than its natural size this slice is drawn.
                // Never below 1: a page rendered smaller than its own points is
                // a page nobody can read.
                var scale = max(1.0, targetWidth.toDouble() / rw)

                // -- The budget, enforced here rather than trusted ----------
                //
                // The Dart side already sizes its requests to the screen, but
                // this is the process that dies if it is wrong, so it does its
                // own arithmetic. Both a per-side cap, because a GPU texture
                // has one, and a total-pixel cap, because two sides each within
                // their limit can still multiply into something that is not.
                if (rw * scale > MAX_DIMENSION) scale = MAX_DIMENSION / rw
                if (rh * scale > MAX_DIMENSION) scale = MAX_DIMENSION / rh
                val wanted = rw * scale * rh * scale
                if (wanted > MAX_PIXELS) scale *= Math.sqrt(MAX_PIXELS / wanted)

                val w = (rw * scale).toInt().coerceIn(1, MAX_DIMENSION)
                val h = (rh * scale).toInt().coerceIn(1, MAX_DIMENSION)

                val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                Canvas(bitmap).drawColor(Color.WHITE)

                // Scale the page up, then slide the wanted corner to the
                // bitmap's origin. Anything outside falls off the edge and is
                // never drawn, which is where the saving comes from.
                val m = Matrix()
                m.setScale(scale.toFloat(), scale.toFloat())
                m.postTranslate(
                    (-left * pw * scale).toFloat(),
                    (-top * ph * scale).toFloat()
                )
                open.render(bitmap, null, m, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)

                // ══ COMPRESSED, NOT RAW — AND THIS IS THE "STROKE" FIX ═════
                //
                // > *"Whenever i use pdf viewer it feels like it has a stroke!
                // > and doesn't works!"*
                //
                // This used to hand back `ByteArray(w * h * 4)`. On his tablet
                // a page is about 1700x2400, so that is **16 MB of raw RGBA**,
                // and it was copied three separate times on the way to the
                // screen: out of the Bitmap here, across the method channel,
                // and again into a texture by `decodeImageFromPixels`. The
                // channel reply is delivered on the platform thread and hops to
                // the UI thread, so the last two of those land on the frame
                // pump. logcat from his device shows single frames of
                // **1,824 ms** while scrolling a document.
                //
                // WebP at 92 turns 16 MB into a few hundred kilobytes. The
                // encode costs maybe 40 ms — on this worker thread, where there
                // is nothing to block — and everything after it gets an order
                // of magnitude cheaper, including the Dart side, which can now
                // use `instantiateImageCodec` and decode off the UI thread
                // entirely.
                //
                // **Lossy, deliberately, and 92 is why.** A rendered PDF page
                // is mostly flat white with hard-edged black text, which is the
                // worst case for JPEG — ringing round every letter. WebP's
                // predictors handle exactly that, and at 92 the difference is
                // not visible at any zoom this viewer allows. Lossless WebP was
                // the alternative and it is several times slower to encode for
                // a file that is still large.
                val stream = java.io.ByteArrayOutputStream(w * h / 8)
                val format = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    Bitmap.CompressFormat.WEBP_LOSSY
                } else {
                    @Suppress("DEPRECATION")
                    Bitmap.CompressFormat.WEBP
                }
                val ok = bitmap.compress(format, 92, stream)
                bitmap.recycle()
                if (!ok) throw IllegalStateException("could not encode page")
                val out = stream.toByteArray()
                VoiceCapture.mainHandler.post { onDone(w, h, out) }
            } catch (e: OutOfMemoryError) {
                // The held page goes with any failure. It may be the thing that
                // is wrong, and a cached page that cannot be drawn would fail
                // identically for every tile after it.
                closePageQuietly()
                VoiceCapture.mainHandler.post {
                    onError("That page is too large to draw on this phone.")
                }
            } catch (e: Exception) {
                closePageQuietly()
                VoiceCapture.mainHandler.post {
                    onError("That page could not be drawn.")
                }
            }
            // Deliberately no `finally` closing the page. It is held for the
            // next tile — see `pageFor`. `close()` and any exception path that
            // invalidates the renderer both clear it.
        }
    }

    /**
     * Shuts everything down.
     *
     * Ordered: the renderer holds the descriptor, the descriptor holds the
     * callback, and the callback runs on the thread. Closing them the other way
     * round leaves a looper alive with a dead descriptor behind it.
     */
    fun close() {
        work.execute { closeQuietly() }
    }

    private fun closeQuietly() {
        // The page first, then the renderer that owns it. A `PdfRenderer`
        // throws if it is closed with a page still open, and that throw would
        // leak the descriptor and the looper behind it.
        closePageQuietly()
        try {
            renderer?.close()
        } catch (_: Exception) {
        }
        renderer = null
        try {
            descriptor?.close()
        } catch (_: Exception) {
        }
        descriptor = null
        callbackThread?.quitSafely()
        callbackThread = null
        pageCount = 0
        pageShapes = DoubleArray(0)
    }
}
