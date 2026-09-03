package com.probablypiyush.lamplight

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapRegionDecoder
import android.graphics.ImageDecoder
import android.graphics.Rect
import android.media.MediaDataSource
import android.media.MediaPlayer
import android.os.Build
import android.view.Surface
import io.flutter.view.TextureRegistry
import java.nio.ByteBuffer
import java.util.concurrent.Executors

/**
 * Video, played from memory onto a Flutter texture.
 *
 * WHY THIS EXISTS AT ALL, WHEN A VIDEO PLAYER IS A SOLVED PROBLEM
 *
 * Every video plugin on earth takes a file path or a URL. This app has neither.
 * A video in the vault is a pile of encrypted 64 KiB chunks with a random name,
 * and CLAUDE.md rule 2 has no exception for "briefly, while it plays" — which is
 * exactly what the easy version would be. Decrypt to a temp file, point
 * ExoPlayer at it, delete it afterwards: that puts somebody's video on disk in
 * the clear for the entire time they are watching it, and for however much
 * longer it takes the delete to happen or not happen.
 *
 * So: the same `MediaDataSource` trick the voice player already uses, plus a
 * `SurfaceTexture` borrowed from Flutter's own renderer so the frames land in
 * the widget tree rather than in a native view floating over it.
 *
 * WHAT IT COSTS, STATED PLAINLY BECAUSE IT IS A REAL LIMIT
 *
 * The plaintext is held in RAM for as long as the video is open. That is fine
 * for the clips a journal actually contains and it is not fine for a 2 GB
 * screen recording, so the Dart side refuses above a threshold and offers
 * "save a copy" instead. The alternative — a seekable decrypting reader that
 * serves arbitrary byte ranges — is real work, and it is the honest next step
 * whenever somebody actually hits the limit. It is written down in PLAN.md
 * rather than pretended away.
 *
 * The reward for doing it this way is that seeking works. A pipe would have
 * been simpler and would have given a video you can only watch straight
 * through, because an MP4's index lives at the end of the file and a pipe
 * cannot go back for it.
 */
class MemoryVideoPlayer(private val textures: TextureRegistry) {

    private var player: MediaPlayer? = null
    private var entry: TextureRegistry.SurfaceTextureEntry? = null
    private var surface: Surface? = null
    private val work = Executors.newSingleThreadExecutor()

    var videoWidth = 0
        private set
    var videoHeight = 0
        private set

    val textureId: Long get() = entry?.id() ?: -1L

    val isPlaying: Boolean get() = try {
        player?.isPlaying == true
    } catch (_: Exception) {
        false
    }

    fun position(): Int = try {
        player?.currentPosition ?: 0
    } catch (_: Exception) {
        0
    }

    fun duration(): Int = try {
        player?.duration ?: 0
    } catch (_: Exception) {
        0
    }

    /**
     * Loads [bytes] and reports back when the first frame is ready.
     *
     * `prepareAsync` rather than `prepare`, and `setDataSource` on a worker,
     * because both of those parse the container and both of them block. Doing
     * either on the main thread is a frozen app for as long as it takes — and
     * on the main thread of an app whose whole complaint history is "it hangs",
     * that is not a trade worth making for four fewer lines.
     */
    fun open(
        bytes: ByteArray,
        loop: Boolean,
        onReady: (textureId: Long, width: Int, height: Int, durationMs: Int) -> Unit,
        onFinished: () -> Unit,
        onError: (String) -> Unit
    ) {
        release()
        val e = textures.createSurfaceTexture()
        entry = e
        val s = Surface(e.surfaceTexture())
        surface = s

        work.execute {
            try {
                val p = MediaPlayer()
                p.setSurface(s)
                p.isLooping = loop
                p.setDataSource(object : MediaDataSource() {
                    override fun readAt(
                        position: Long,
                        buffer: ByteArray,
                        offset: Int,
                        size: Int
                    ): Int {
                        if (position >= bytes.size) return -1
                        val available = (bytes.size - position).toInt()
                        val n = minOf(size, available)
                        System.arraycopy(bytes, position.toInt(), buffer, offset, n)
                        return n
                    }

                    override fun getSize(): Long = bytes.size.toLong()

                    override fun close() {}
                })
                p.setOnVideoSizeChangedListener { _, w, h ->
                    if (w > 0 && h > 0) {
                        videoWidth = w
                        videoHeight = h
                        e.surfaceTexture().setDefaultBufferSize(w, h)
                    }
                }
                p.setOnCompletionListener { VoiceCapture.mainHandler.post { onFinished() } }
                p.setOnErrorListener { _, what, extra ->
                    // ISSUE 10, and PLAN.md test 6. This used to append
                    // "($what/$extra)" — MediaPlayer's own integer error codes.
                    // A person holding a phone cannot do anything with
                    // "(1/-1010)" except feel that the app is broken in a way
                    // they are not qualified to understand, which is precisely
                    // what the invisible-machinery test forbids.
                    //
                    // The codes are worth keeping for whoever is debugging, so
                    // they go to logcat, where only a plugged-in developer sees
                    // them. What reaches the screen says what happened and what
                    // can be done about it.
                    android.util.Log.w(
                        "Lamplight",
                        "MediaPlayer refused this clip: what=$what extra=$extra"
                    )
                    VoiceCapture.mainHandler.post {
                        onError(
                            if (extra == android.media.MediaPlayer.MEDIA_ERROR_UNSUPPORTED ||
                                what == android.media.MediaPlayer.MEDIA_ERROR_UNKNOWN
                            ) {
                                "This phone cannot play this video's format. Everything the camera and messaging apps make will play; a few unusual ones will not."
                            } else {
                                "This video could not be played. It may be damaged."
                            }
                        )
                    }
                    true
                }
                p.setOnPreparedListener { ready ->
                    player = ready
                    VoiceCapture.mainHandler.post {
                        onReady(e.id(), ready.videoWidth, ready.videoHeight, ready.duration)
                    }
                }
                p.prepareAsync()
            } catch (ex: Exception) {
                VoiceCapture.mainHandler.post {
                    onError(ex.message ?: "This video could not be played.")
                }
            }
        }
    }

    fun play() {
        try {
            player?.start()
        } catch (_: Exception) {
        }
    }

    fun pause() {
        try {
            if (player?.isPlaying == true) player?.pause()
        } catch (_: Exception) {
        }
    }

    fun seekTo(ms: Int) {
        try {
            player?.seekTo(ms.coerceAtLeast(0))
        } catch (_: Exception) {
        }
    }

    fun setSpeed(rate: Float) {
        val p = player ?: return
        try {
            val wasPlaying = p.isPlaying
            p.playbackParams = p.playbackParams.setSpeed(rate)
            if (!wasPlaying) p.pause()
        } catch (_: Exception) {
        }
    }

    fun setVolume(v: Float) {
        try {
            player?.setVolume(v, v)
        } catch (_: Exception) {
        }
    }

    fun release() {
        player?.let {
            try {
                if (it.isPlaying) it.stop()
            } catch (_: Exception) {
            }
            it.release()
        }
        player = null
        surface?.release()
        surface = null
        entry?.release()
        entry = null
        videoWidth = 0
        videoHeight = 0
    }
}

/**
 * Decoding the image formats Flutter's own decoder will not.
 *
 * WHY THIS IS NEEDED
 *
 * Flutter decodes through Skia, and Skia handles JPEG, PNG, GIF, WebP, BMP and
 * ICO. It does **not** handle HEIC or HEIF, which is the format every recent
 * iPhone and a growing number of Android phones save photographs in by default,
 * and it does not handle AVIF. So a user importing a photo straight off their
 * camera roll could land on a file the app can store perfectly and cannot show
 * — the worst possible failure for a journal, because it looks like the photo
 * was lost.
 *
 * Android can decode all of them, and has been able to since API 28. This hands
 * the bytes to `ImageDecoder` and returns raw pixels.
 *
 * WHY RAW RGBA AND NOT A RE-ENCODED JPEG
 *
 * Re-encoding would be a second lossy generation on a photograph that is
 * already lossy, applied to somebody's own memory of a day, to save a few
 * hundred kilobytes crossing an in-process channel. Raw pixels are larger on
 * the wire and exact, and the caller was going to allocate the same buffer
 * anyway the moment it decoded.
 *
 * Downscaling happens **here**, before the pixels are allocated, so a 48 MP
 * photograph never becomes a 192 MB buffer.
 */
object ImageFallback {

    private val work = Executors.newSingleThreadExecutor()

    fun decode(
        bytes: ByteArray,
        maxDimension: Int,
        onDone: (width: Int, height: Int, pixels: ByteArray) -> Unit,
        onError: (String) -> Unit
    ) {
        work.execute {
            try {
                val bitmap = decodeBitmap(bytes, maxDimension)
                    ?: throw IllegalStateException("Nothing on this phone can read that image.")
                // ARGB_8888 in a Bitmap is stored as RGBA in native byte order on
                // little-endian devices, which is every Android device Flutter
                // runs on. `copyPixelsToBuffer` gives exactly what
                // `decodeImageFromPixels` wants for PixelFormat.rgba8888.
                val safe = if (bitmap.config == Bitmap.Config.ARGB_8888) {
                    bitmap
                } else {
                    bitmap.copy(Bitmap.Config.ARGB_8888, false)
                }
                val buffer = ByteBuffer.allocate(safe.width * safe.height * 4)
                safe.copyPixelsToBuffer(buffer)
                val w = safe.width
                val h = safe.height
                val out = buffer.array()
                if (safe !== bitmap) safe.recycle()
                bitmap.recycle()
                VoiceCapture.mainHandler.post { onDone(w, h, out) }
            } catch (e: Exception) {
                VoiceCapture.mainHandler.post {
                    onError(e.message ?: "That image could not be opened.")
                }
            } catch (e: OutOfMemoryError) {
                VoiceCapture.mainHandler.post {
                    onError("That image is too large to open on this phone.")
                }
            }
        }
    }

    private fun decodeBitmap(bytes: ByteArray, maxDimension: Int): Bitmap? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            // ImageDecoder covers HEIF, AVIF (API 31+), animated WebP and GIF,
            // and applies the EXIF orientation itself — which BitmapFactory
            // does not, and which is why photographs from some phones used to
            // arrive on their side.
            val source = ImageDecoder.createSource(ByteBuffer.wrap(bytes))
            return ImageDecoder.decodeBitmap(source) { decoder, info, _ ->
                decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
                decoder.isMutableRequired = false
                val w = info.size.width
                val h = info.size.height
                val longest = maxOf(w, h)
                if (longest > maxDimension && maxDimension > 0) {
                    val scale = maxDimension.toDouble() / longest
                    decoder.setTargetSize(
                        (w * scale).toInt().coerceAtLeast(1),
                        (h * scale).toInt().coerceAtLeast(1)
                    )
                }
            }
        }

        // API 27 and below. Measure first, then decode at a power-of-two
        // fraction — the only downscale BitmapFactory offers, and the only one
        // that avoids allocating the full-size bitmap on the way.
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        var sample = 1
        val longest = maxOf(bounds.outWidth, bounds.outHeight)
        while (maxDimension > 0 && longest / sample > maxDimension) sample *= 2
        val options = BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
    }

    /**
     * The size of a picture, without decoding a pixel of it.
     *
     * `inJustDecodeBounds` reads the header and stops. Dart needs this to know
     * what it is looking at before it decides how to look at it.
     */
    fun measure(bytes: ByteArray, onDone: (Int, Int) -> Unit, onError: (String) -> Unit) {
        work.execute {
            try {
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
                if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
                    throw IllegalStateException("That picture could not be read.")
                }
                val w = bounds.outWidth
                val h = bounds.outHeight
                VoiceCapture.mainHandler.post { onDone(w, h) }
            } catch (e: Exception) {
                VoiceCapture.mainHandler.post {
                    onError(e.message ?: "That picture could not be read.")
                }
            }
        }
    }

    /**
     * One rectangle of a picture, decoded at the size it will actually be drawn.
     *
     * ── WHY THIS EXISTS ─────────────────────────────────────────────────────
     *
     * *"Nah I want you to make it possible to view tall screenshots too."* —
     * Piyush, round nine, correcting the first attempt at ISSUE IMPORTANT.
     *
     * He is right and the correction matters. The crash was real: a decoded
     * image is four bytes a pixel, and a long screenshot at full width is
     * hundreds of megabytes, which is Android killing the process while
     * somebody is pinching. But the obvious fix — decode the whole thing
     * smaller — buys safety by making the picture unreadable at exactly the
     * moment they zoomed in to read it. That is not a fix, it is a different
     * complaint.
     *
     * **Memory should be bounded by the screen, not by the picture.** The
     * screen is a fixed number of pixels. If only what is on it is ever
     * decoded, a 2,000-pixel-tall screenshot and a 60,000-pixel-tall one cost
     * the same, and both are readable at full detail.
     *
     * That is what `BitmapRegionDecoder` is for, it has been in Android since
     * API 10, and it is what every gallery on the phone already does. It is
     * also what this app's own PDF reader does — see `pdf_tile.dart` and
     * `test/media/pdf_tile_test.dart`, which states the same property. This is
     * that idea, applied to the thing it was invented for.
     *
     * @param region the rectangle in **source pixel** coordinates.
     * @param sample power-of-two subsampling, chosen by the caller from how
     *   much of the region will be shown. 1 means every pixel.
     */
    fun decodeRegion(
        bytes: ByteArray,
        left: Int,
        top: Int,
        right: Int,
        bottom: Int,
        sample: Int,
        onDone: (width: Int, height: Int, pixels: ByteArray) -> Unit,
        onError: (String) -> Unit
    ) {
        work.execute {
            var decoder: BitmapRegionDecoder? = null
            try {
                decoder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    BitmapRegionDecoder.newInstance(bytes, 0, bytes.size)
                } else {
                    @Suppress("DEPRECATION")
                    BitmapRegionDecoder.newInstance(bytes, 0, bytes.size, false)
                } ?: throw IllegalStateException("That picture cannot be opened piece by piece.")

                // Clamped here rather than trusted from Dart. A region even one
                // pixel outside the picture makes this throw, and the caller is
                // working from a size it was told asynchronously — so by the
                // time it asks, its idea of the edges can be stale.
                val clipped = Rect(
                    left.coerceIn(0, decoder.width - 1),
                    top.coerceIn(0, decoder.height - 1),
                    right.coerceIn(1, decoder.width),
                    bottom.coerceIn(1, decoder.height)
                )
                if (clipped.width() <= 0 || clipped.height() <= 0) {
                    throw IllegalStateException("That part of the picture is empty.")
                }

                val options = BitmapFactory.Options().apply {
                    inSampleSize = sample.coerceAtLeast(1)
                    inPreferredConfig = Bitmap.Config.ARGB_8888
                }
                val bitmap = decoder.decodeRegion(clipped, options)
                    ?: throw IllegalStateException("That part of the picture could not be read.")

                val safe = if (bitmap.config == Bitmap.Config.ARGB_8888) {
                    bitmap
                } else {
                    bitmap.copy(Bitmap.Config.ARGB_8888, false)
                }
                val buffer = ByteBuffer.allocate(safe.width * safe.height * 4)
                safe.copyPixelsToBuffer(buffer)
                val w = safe.width
                val h = safe.height
                val out = buffer.array()
                if (safe !== bitmap) safe.recycle()
                bitmap.recycle()
                VoiceCapture.mainHandler.post { onDone(w, h, out) }
            } catch (e: Exception) {
                VoiceCapture.mainHandler.post {
                    onError(e.message ?: "That part of the picture could not be read.")
                }
            } catch (e: OutOfMemoryError) {
                VoiceCapture.mainHandler.post {
                    onError("There is not enough memory to open that picture.")
                }
            } finally {
                decoder?.recycle()
            }
        }
    }
}
