package com.probablypiyush.lamplight

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.os.SystemClock
import java.io.ByteArrayOutputStream
import java.nio.ByteOrder
import java.util.concurrent.Executors
import kotlin.math.max
import kotlin.math.min

/**
 * What a file is, measured once at import. **ISSUE 8, and the width/height gap.**
 *
 * ── WHY THIS RUNS AT IMPORT AND NOWHERE ELSE ─────────────────────────────
 *
 * *"A video arrives looking like a document — a grey row with a filename and a
 * size. It needs a thumbnail, as it has in every other app on the phone."*
 *
 * The obvious build is to extract the frame when the day view draws the block.
 * That is wrong twice over. It would decode a video on the frame budget of a
 * scrolling list, which is how you make a list stutter; and it would have to
 * decrypt the whole clip to do it, every time you scrolled past.
 *
 * So it happens **once**, at import, while the plaintext is already in hand and
 * already on its way to being scrubbed. The frame is then encrypted into the
 * attachment store like anything else, and the day view draws a small encrypted
 * picture — which it is already good at.
 *
 * The same call answers the other question nobody had been asking: **how big is
 * this picture?** `attachments.width` and `attachments.height` have existed
 * since day one and have been null for everything, which is why a single
 * portrait photograph was being letterboxed into a 4:3 box by `PhotoAlbum`.
 * One `inJustDecodeBounds` pass costs nothing — it reads the header and
 * allocates no pixels at all — and it fixes that forever.
 *
 * ── ON RE-ENCODING THE FRAME AS JPEG ─────────────────────────────────────
 *
 * `ImageFallback` argues against re-encoding and it is right about the user's
 * own photograph. This is different: the poster frame is not the user's file,
 * it is a small picture *we* are making to stand in for it, and its whole job
 * is to be cheap. Raw RGBA at 512px would be a megabyte per video in the vault
 * and in every backup. JPEG at 82 is about thirty kilobytes and nobody can see
 * the difference at the size it is drawn.
 */
object MediaInfo {

    private val work = Executors.newSingleThreadExecutor()

    /** The longest edge of a stored poster frame, in pixels. */
    private const val POSTER_MAX = 640

    /**
     * The longest edge of a stored photograph thumbnail, in pixels.
     *
     * Smaller than a poster frame because there are far more of them — a vault
     * holds a handful of videos and thousands of photographs — and because a
     * thumbnail is only ever drawn into a tile, never full screen. 512 covers
     * a half-width tile on a 3x screen with room to spare.
     */
    private const val THUMB_MAX = 512

    /**
     * Below this, a photograph is its own thumbnail.
     *
     * Making a 400-pixel copy of a 500-pixel picture spends storage, spends
     * time, and saves nothing at the moment it is drawn. The threshold is
     * generous on purpose: the win here is not decoding, which the image
     * provider already handles, it is not having to DECRYPT four megabytes to
     * draw a two-centimetre square.
     */
    private const val THUMB_WORTH_IT = 768

    /**
     * How long the waveform decode may take before it gives up.
     *
     * Decoding is normally many times faster than real time - a five-minute
     * MP3 is a second or two - but a damaged file can leave a codec making no
     * progress at all, and an import must not hang because a decoration would
     * not compute. Past this the file is imported with no waveform, which the
     * player already knows how to draw honestly.
     */
    private const val DECODE_BUDGET_MS = 15_000L

    /** How long to wait on a codec buffer before going round again. */
    private const val TIMEOUT_US = 10_000L

    /**
     * Reads [path] and reports what can be learned cheaply.
     *
     * Never throws to the caller. A file whose metadata cannot be read is still
     * a perfectly good file to keep — losing the import because the thumbnail
     * failed would be the app protecting a decoration at the cost of somebody's
     * video.
     */
    fun read(
        path: String,
        kind: String,
        onDone: (Map<String, Any?>) -> Unit
    ) {
        work.execute {
            val out = HashMap<String, Any?>()
            try {
                when (kind) {
                    "video" -> readVideo(path, out)
                    "voice" -> readAudio(path, out)
                    else -> readImage(path, out)
                }
            } catch (_: Exception) {
                // Deliberately swallowed. See the note above.
            } catch (_: OutOfMemoryError) {
            }
            VoiceCapture.mainHandler.post { onDone(out) }
        }
    }

    /**
     * An audio file that arrived from somewhere else. **ISSUE 2, and the 0:00.**
     *
     * -- THE TWO FAULTS HE PHOTOGRAPHED, WHICH WERE ONE FAULT --------------
     *
     * *"If audio from anywhere else is added, there is no voice waveform!"* and,
     * around the same player, *"WTF is this 0:00 - obviously that audio is not
     * 0:00 cause that plays! Why is this bug even placed here?"*
     *
     * Both had the same cause and it was one argument at the call site. The
     * importer asked for facts with `poster = type == "video"`, and everything
     * that was not a video went to [readImage] - so an imported MP3 was handed
     * to `BitmapFactory`, which sensibly declined, and came back with nothing
     * at all. No duration, hence 0:00 on a note that plainly plays. No
     * waveform, hence the flat bar.
     *
     * He is also right that it should never have shipped: a player showing
     * 0:00 for something audible is the invisible-machinery test failing in the
     * most visible way there is.
     *
     * -- WHY THE WAVEFORM IS DECODED HERE AND NOWHERE ELSE -----------------
     *
     * A recording made in the app measures its own amplitude while it is being
     * made - that is free, because the microphone is already reporting a level.
     * An imported file has no such history, so the only way to know its shape
     * is to decode it.
     *
     * Decoding audio is far too expensive to do while a list is scrolling, and
     * doing it there would mean decrypting the whole file every time somebody
     * scrolled past. So it happens **once**, at import, in the same window as
     * the video poster frame and for exactly the same reason: the plaintext is
     * already in hand and already on its way to being scrubbed.
     *
     * What is stored is 96 bytes, in the same shape and normalisation the live
     * recorder produces, so the player cannot tell the two apart and neither
     * can the drawing code.
     */
    private fun readAudio(path: String, out: HashMap<String, Any?>) {
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?.toLongOrNull()
                ?.let { if (it > 0) out["durationMs"] = it.toInt() }
        } catch (_: Exception) {
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }

        // The shape is a nicety; the duration above is not. So a waveform that
        // cannot be worked out is left absent rather than being allowed to take
        // the length down with it.
        try {
            waveform(path)?.let { out["waveform"] = it }
        } catch (_: Exception) {
        } catch (_: OutOfMemoryError) {
        }
    }

    /**
     * The shape of a recording, as 96 bytes.
     *
     * Straight `MediaExtractor` into `MediaCodec` and out to PCM, keeping only
     * the loudest sample in each of 96 slices of the running time. Nothing is
     * kept but those 96 numbers - the decoded audio is walked past, not held,
     * so a two-hour podcast costs the same memory as a ten-second note.
     *
     * **Peak, not mean**, matching `summariseWaveform` in Dart: averaging turns
     * speech into a low flat hedge, because most of any sentence is quiet. The
     * peak is what makes a waveform look like the thing that was said.
     *
     * Normalised against the loudest moment for the same reason the recorder
     * does it - a quietly recorded file should be legible rather than a line
     * near zero.
     */
    private fun waveform(path: String, buckets: Int = 96): ByteArray? {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null
        try {
            extractor.setDataSource(path)

            var track = -1
            var format: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val f = extractor.getTrackFormat(i)
                val mime = f.getString(MediaFormat.KEY_MIME) ?: continue
                if (mime.startsWith("audio/")) {
                    track = i
                    format = f
                    break
                }
            }
            val chosen = format ?: return null
            if (track < 0) return null

            val durationUs =
                if (chosen.containsKey(MediaFormat.KEY_DURATION))
                    chosen.getLong(MediaFormat.KEY_DURATION)
                else 0L
            // Nothing to slice into buckets, and nothing worth guessing at.
            if (durationUs <= 0) return null

            extractor.selectTrack(track)
            val mime = chosen.getString(MediaFormat.KEY_MIME) ?: return null
            codec = MediaCodec.createDecoderByType(mime)
            codec.configure(chosen, null, null, 0)
            codec.start()

            val peaks = FloatArray(buckets)
            val info = MediaCodec.BufferInfo()
            var sawInputEnd = false
            var sawOutputEnd = false

            // A wall-clock ceiling. Decoding is normally many times faster than
            // real time, but a damaged file can put a codec into a state where
            // it makes no progress, and an import must not hang on a decoration.
            val deadline = SystemClock.uptimeMillis() + DECODE_BUDGET_MS

            while (!sawOutputEnd && SystemClock.uptimeMillis() < deadline) {
                if (!sawInputEnd) {
                    val index = codec.dequeueInputBuffer(TIMEOUT_US)
                    if (index >= 0) {
                        val buffer = codec.getInputBuffer(index)
                        val size =
                            if (buffer == null) -1
                            else extractor.readSampleData(buffer, 0)
                        if (size < 0) {
                            codec.queueInputBuffer(
                                index, 0, 0, 0,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM
                            )
                            sawInputEnd = true
                        } else {
                            codec.queueInputBuffer(
                                index, 0, size, extractor.sampleTime, 0
                            )
                            extractor.advance()
                        }
                    }
                }

                val index = codec.dequeueOutputBuffer(info, TIMEOUT_US)
                if (index >= 0) {
                    if (info.size > 0) {
                        val buffer = codec.getOutputBuffer(index)
                        if (buffer != null) {
                            val slot = (
                                (info.presentationTimeUs.toDouble() /
                                    durationUs) * buckets
                                ).toInt().coerceIn(0, buckets - 1)
                            val level = peakOf(buffer, info.offset, info.size)
                            if (level > peaks[slot]) peaks[slot] = level
                        }
                    }
                    codec.releaseOutputBuffer(index, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        sawOutputEnd = true
                    }
                }
            }

            if (!sawOutputEnd) return null

            var loudest = 0f
            for (v in peaks) if (v > loudest) loudest = v
            // Silence, or something this decoder produced nothing useful from.
            // An honest flat bar beats an invented one.
            if (loudest < 0.001f) return null

            val out = ByteArray(buckets)
            for (i in 0 until buckets) {
                out[i] = ((peaks[i] / loudest) * 255f)
                    .toInt().coerceIn(0, 255).toByte()
            }
            return out
        } finally {
            try {
                codec?.stop()
            } catch (_: Exception) {
            }
            try {
                codec?.release()
            } catch (_: Exception) {
            }
            try {
                extractor.release()
            } catch (_: Exception) {
            }
        }
    }

    /**
     * The loudest sample in one decoded buffer, 0..1.
     *
     * 16-bit little-endian PCM is what every Android audio decoder produces
     * unless it was explicitly asked for something else, and nothing here asks.
     * Reading it as shorts rather than byte by byte is both correct and quicker.
     */
    private fun peakOf(
        buffer: java.nio.ByteBuffer,
        offset: Int,
        size: Int
    ): Float {
        val shorts = buffer.duplicate()
            .order(ByteOrder.LITTLE_ENDIAN)
            .position(offset)
            .limit(offset + size)
            .let { (it as java.nio.ByteBuffer).asShortBuffer() }

        var peak = 0
        // Every eighth sample. A peak detector does not need every one of
        // 44,100 samples a second to find the loud moments, and this is eight
        // times less arithmetic on a path that runs while somebody waits.
        var i = 0
        val n = shorts.remaining()
        while (i < n) {
            val v = shorts.get(i).toInt()
            val magnitude = if (v < 0) -v else v
            if (magnitude > peak) peak = magnitude
            i += 8
        }
        return peak / 32768f
    }

    private fun readImage(path: String, out: HashMap<String, Any?>) {
        // Header only. `inJustDecodeBounds` reads the dimensions and allocates
        // no pixel buffer, so a 48 MP photograph costs a few kilobytes of I/O
        // rather than 192 MB of heap.
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return
        out["width"] = bounds.outWidth
        out["height"] = bounds.outHeight

        // ── The thumbnail. `KeyPurpose.thumbnails` has existed since day one
        //    and nothing had ever written one. ────────────────────────────────
        //
        // What that cost, every time: a day with twenty photographs had to
        // read and DECRYPT twenty full-size files - tens of megabytes through
        // libsodium's secretstream - in order to draw twenty small squares.
        // The image provider was already careful to decode at tile size, so
        // the decode was never the problem; the decrypt was, and no amount of
        // care on the Dart side could avoid it while the only thing on disk
        // was the original.
        //
        // It rides the poster-frame path that already exists for videos, so
        // Dart needs no new plumbing: the importer encrypts `poster` into its
        // own attachment and records it as `thumbnailId`, exactly as it has
        // been doing for clips since ISSUE 8.
        val longest = max(bounds.outWidth, bounds.outHeight)
        if (longest <= THUMB_WORTH_IT) return

        // `inSampleSize` decodes straight to a fraction of the size, so the
        // full bitmap is never allocated. A 48 MP photograph is read at 1/8
        // and costs about three megabytes of heap rather than 192.
        var sample = 1
        while (longest / (sample * 2) >= THUMB_MAX) sample *= 2

        val small = try {
            BitmapFactory.decodeFile(
                path,
                BitmapFactory.Options().apply { inSampleSize = sample }
            )
        } catch (_: OutOfMemoryError) {
            null
        } ?: return

        try {
            out["poster"] = encode(small, THUMB_MAX)
        } finally {
            small.recycle()
        }
    }

    private fun readVideo(path: String, out: HashMap<String, Any?>) {
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?.toLongOrNull()
                ?.let { out["durationMs"] = it.toInt() }

            val w = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
                ?.toIntOrNull()
            val h = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
                ?.toIntOrNull()
            // The rotation the camera recorded. A phone held upright stores a
            // landscape stream plus "rotate 90", and a poster frame that
            // ignored it would be the one picture in the app lying on its side.
            val rotation = retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
                ?.toIntOrNull() ?: 0
            if (w != null && h != null && w > 0 && h > 0) {
                val upright = rotation == 90 || rotation == 270
                out["width"] = if (upright) h else w
                out["height"] = if (upright) w else h
            }

            // A frame from **one second in**, not from zero. The first frame of
            // a phone recording is very often the lens still adjusting, or a
            // hand over it, or black — which would make every video in the
            // vault look like the same video.
            val frame = retriever.getFrameAtTime(
                1_000_000L,
                MediaMetadataRetriever.OPTION_CLOSEST_SYNC
            ) ?: retriever.getFrameAtTime(0L)

            if (frame != null) {
                out["poster"] = encode(frame)
                frame.recycle()
            }
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }
    }

    private fun encode(frame: Bitmap, maxEdge: Int = POSTER_MAX): ByteArray {
        val longest = max(frame.width, frame.height)
        val scaled = if (longest <= maxEdge) {
            frame
        } else {
            val ratio = maxEdge.toDouble() / longest
            Bitmap.createScaledBitmap(
                frame,
                max(1, (frame.width * ratio).toInt()),
                max(1, (frame.height * ratio).toInt()),
                true
            )
        }
        val bytes = ByteArrayOutputStream(min(64 * 1024, scaled.byteCount))
        scaled.compress(Bitmap.CompressFormat.JPEG, 82, bytes)
        if (scaled !== frame) scaled.recycle()
        return bytes.toByteArray()
    }
}
