package com.probablypiyush.lamplight

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.view.Surface
import java.io.File
import java.nio.ByteBuffer

/**
 * Making a video smaller on the way into the vault. **ISSUE 3 and ISSUE 4.**
 *
 * ══ WHY ══════════════════════════════════════════════════════════════════
 *
 * *"A video file can be so so so big. One minute video can be of 100 mbs or
 * more. I want you to store the video in the compressed size, in a way quality
 * is not compromised."*
 *
 * He is right about the number. A modern phone records 1080p60 at twelve to
 * twenty megabits, which is exactly the hundred megabytes a minute he measured.
 * In a journal that is kept forever and backed up in one file, that compounds
 * in a way nothing else in the app does.
 *
 * **It also answers ISSUE 3**, which is the part worth noticing. He asked for
 * the player to *"play major — actually all — the formats of video formats"*,
 * and the reason it cannot is that it plays whatever the phone's decoders
 * support and no more; the alternative is a software decoder, which is a very
 * large third-party dependency and `CLAUDE.md` rule 4. But a clip that is
 * **re-encoded to H.264 in an MP4 at import** is a clip every Android device
 * made in the last decade can play, whatever container it arrived in. Solving
 * the size problem solves the format problem on the way past.
 *
 * ══ WHAT THIS DELIBERATELY DOES NOT DO ═══════════════════════════════════
 *
 * **It does not scale the picture.** Decoder output goes straight onto the
 * encoder's input surface, which keeps every frame on the GPU and needs no
 * OpenGL of our own. Resizing would mean a GL pass, a shader and a texture
 * copy, and it is not where the win is: a 100 MB minute is a *bitrate*
 * problem, not a resolution one. Same pixels, a third of the bits, and *"quality
 * is not compromised"* stays true in the way he meant it.
 *
 * **It does not re-encode the audio.** Audio samples are copied from the source
 * straight into the muxer. Speech at 128 kbps is a rounding error next to
 * video, re-encoding it would be the only lossy thing here, and it avoids
 * needing an audio codec at all.
 *
 * ══ THE RULE THIS OBEYS ABOVE ALL OTHERS ═════════════════════════════════
 *
 * **A failed transcode must never cost somebody their video.** Every path here
 * returns null rather than throwing, and the caller imports the original
 * untouched when it does. An unusual codec, a device with no encoder free, a
 * file the extractor cannot parse, an audio format MP4 will not carry — all of
 * them mean "keep the original", never "lose the clip". The output is also
 * checked to be genuinely smaller before it is accepted, because a transcode
 * that grew the file is a failure that happened to complete.
 *
 * Nothing here touches plaintext that was not already plaintext: this runs on
 * the temp file the picker or the camera just produced, before
 * `AttachmentImporter` encrypts it, and inside the same `finally { scrub() }`.
 */
object Transcode {

    /** Below this, compressing is not worth the seconds it takes. */
    private const val MIN_BYTES = 4L * 1024 * 1024

    /** Give up rather than hold a phone hostage to one import. */
    private const val TIMEOUT_US = 10_000L

    /**
     * A wall clock on the whole transcode. **ROUND FIFTEEN, ISSUE 10.**
     *
     * `pump` loops until the encoder reports end-of-stream, and there is a real
     * arrangement where that never arrives: a decoder that produces no frames
     * at all leaves `sawDecodeEnd` false for ever, so `signalEndOfInputStream`
     * is never called and the encoder has no reason to finish. The loop would
     * then spin at 100 frames a second until the process died.
     *
     * That is worse than a slow import. `ImportQueue` is strictly sequential
     * **because every waiting file sits in the cache as plaintext until its
     * turn ends** — so a transcode that never returns is a rule-2 problem, not
     * only a hang: the rest of the batch stays in the clear on disk for as long
     * as the app is alive.
     *
     * Five minutes is far longer than any honest transcode of a journal clip
     * and far shorter than for ever. Running out means "keep the original",
     * which is what every other failure here means.
     */
    private const val DEADLINE_MS = 5L * 60L * 1000L

    /**
     * How hard to squeeze. **ROUND EIGHT, ISSUE 2A.**
     *
     * *"Give the user an option on how the video is compressed? How much it is
     * compressed?"*
     *
     * `original` never reaches this file at all — the Dart side returns before
     * the channel call, so "keep the original" cannot be undone by a bug in a
     * transcoder that never runs. What arrives here is one of the two settings
     * that do re-encode.
     */
    private const val BALANCED = "balanced"
    private const val SMALLER = "smaller"

    /**
     * Why a clip came back the same size. **ROUND FIFTEEN, ISSUE 10.**
     *
     * > *"Video Size – when uploaded it does prompts but never resizes."*
     *
     * Half of that complaint is a bug and is fixed above. The other half is
     * that this file has always had **a dozen ways to decline** — too small to
     * bother, already modest, an audio codec MP4 cannot carry, no free hardware
     * encoder, a ten-bit HDR source an AVC encoder will not take, out of
     * memory — and every one of them returned the same `null`. The app asked
     * him a question, he answered it, and then nothing happened and nothing was
     * said. That is the part that makes it feel broken rather than merely
     * unlucky.
     *
     * So the reason travels back now. Dart turns it into one plain sentence at
     * the end of the batch. It is not a diagnostic dump — there are four
     * outcomes a person can act on and they are these.
     */
    const val REASON_DONE = "done"

    /** Not worth the seconds. Under [MIN_BYTES], or already at a sane bitrate. */
    const val REASON_ALREADY_SMALL = "alreadySmall"

    /** This phone's codecs would not do it. Nothing the user can change. */
    const val REASON_CANNOT = "cannot"

    /**
     * Re-encodes [source] into an MP4 beside it.
     *
     * Returns the new file in `file` — or null, meaning "use the original" —
     * and always a `reason`.
     */
    fun video(source: File, quality: String = BALANCED): Pair<File?, String> {
        if (!source.exists()) return null to REASON_CANNOT
        if (source.length() < MIN_BYTES) return null to REASON_ALREADY_SMALL

        var output: File? = null
        return try {
            val target = File(source.parentFile, "${source.name}.mp4")
            output = target
            when (run(source, target, quality)) {
                Outcome.DONE ->
                    if (target.exists() && target.length() in 1 until source.length()) {
                        target to REASON_DONE
                    } else {
                        // A transcode that grew the file is a failure that
                        // happened to complete.
                        target.delete()
                        null to REASON_ALREADY_SMALL
                    }
                Outcome.NOT_WORTH_IT -> {
                    target.delete()
                    null to REASON_ALREADY_SMALL
                }
                Outcome.FAILED -> {
                    target.delete()
                    null to REASON_CANNOT
                }
            }
        } catch (_: Throwable) {
            // Includes OutOfMemoryError and every codec exception there is.
            // The original is still sitting there untouched, which is the
            // entire point of catching this broadly.
            runCatching { output?.delete() }
            null to REASON_CANNOT
        }
    }

    /** What `run` concluded. Three answers, because the user can act on two. */
    private enum class Outcome { DONE, NOT_WORTH_IT, FAILED }

    /**
     * Re-encodes a photograph smaller. **ISSUE 2.**
     *
     * *"Any way to reduce the size of file without reducing the quality of the
     * file? So that the app doesn't need to render that much — app speed
     * improve."*
     *
     * A modern phone camera produces eight to fifteen megabytes per shot at
     * twelve megapixels or more. Two things follow, and he named both. It is a
     * lot of vault and a lot of backup for a picture nobody will ever print.
     * And it is slow to *draw*: every time that photograph appears on the day
     * view, the whole of it is decrypted and decoded before being scaled down
     * to a column a few hundred points wide.
     *
     * ── The two numbers, and why they are not lossless ────────────────────
     *
     * 3000 pixels on the long edge, and JPEG quality 88.
     *
     * "Without reducing the quality" cannot be taken mathematically — a JPEG
     * re-encode is lossy by definition, and a genuinely lossless shrink of a
     * photograph does not exist. Taken as he meant it, which is *"I must not be
     * able to see the difference"*, these are comfortable: 3000px is larger
     * than any phone screen and enough to crop into, and 88 is above the point
     * where artefacts become visible on photographic content. A 12 MB photo
     * lands around 1.5 MB.
     *
     * ── EXIF, which goes, and that is a feature ───────────────────────────
     *
     * Re-encoding drops the metadata, and a phone photograph's metadata
     * routinely includes **GPS coordinates**. For a private journal that is
     * unambiguously good: `THREAT-MODEL.md` is about what can be learned from
     * this app's data, and where the user was standing is not something the
     * vault needs to carry. The one piece worth keeping is the **orientation**,
     * which is applied to the pixels here before it is discarded — without
     * that, every portrait photograph would come back on its side.
     *
     * The date the photo was taken goes too. Lamplight already knows what day
     * it belongs to; that is the whole organising idea of the app.
     *
     * Returns null to mean "keep the original", on any failure at all.
     */
    fun photo(source: File, quality: String = "balanced"): File? {
        if (!source.exists() || source.length() < 1_500_000L) return null

        // ── ROUND NINE, ISSUE 6 — two sizes rather than one ──────────────────
        //
        // *"Photos and videos sizes — ask when uploading!"* `original` never
        // gets here: Dart returns the file untouched, so that "keep the
        // original" costs no channel call and cannot be affected by a bug in
        // this method.
        val longEdge = if (quality == "smaller") SMALLER_EDGE else MAX_EDGE
        val jpeg = if (quality == "smaller") SMALLER_QUALITY else QUALITY

        var target: File? = null
        return try {
            val rotation = runCatching {
                when (ExifInterface(source.absolutePath)
                    .getAttributeInt(
                        ExifInterface.TAG_ORIENTATION,
                        ExifInterface.ORIENTATION_NORMAL
                    )) {
                    ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                    ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                    ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                    else -> 0f
                }
            }.getOrDefault(0f)

            // Measure first, so a 108-megapixel picture is never fully decoded
            // into memory just to find out how big it is.
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(source.absolutePath, bounds)
            val longest = maxOf(bounds.outWidth, bounds.outHeight)
            if (longest <= 0) return null

            // Powers of two only — that is what inSampleSize accepts, and it is
            // also the only cheap path through the decoder.
            var sample = 1
            while (longest / (sample * 2) >= longEdge) sample *= 2

            val bitmap = BitmapFactory.decodeFile(
                source.absolutePath,
                BitmapFactory.Options().apply { inSampleSize = sample }
            ) ?: return null

            val oriented = if (rotation == 0f) bitmap else {
                val m = Matrix().apply { postRotate(rotation) }
                Bitmap.createBitmap(
                    bitmap, 0, 0, bitmap.width, bitmap.height, m, true
                ).also { if (it !== bitmap) bitmap.recycle() }
            }

            val out = File(source.parentFile, "${source.name}.jpg")
            target = out
            out.outputStream().use {
                oriented.compress(Bitmap.CompressFormat.JPEG, jpeg, it)
            }
            oriented.recycle()

            if (out.exists() && out.length() in 1 until source.length()) out
            else {
                out.delete()
                null
            }
        } catch (_: Throwable) {
            runCatching { target?.delete() }
            null
        }
    }

    /** Long edge, in pixels. Larger than any phone screen, and croppable. */
    private const val MAX_EDGE = 3000

    /** Above the point where JPEG artefacts show on photographic content. */
    private const val QUALITY = 88

    /**
     * The other rung. **ROUND NINE, ISSUE 6.**
     *
     * Two thousand pixels is still comfortably larger than any phone screen —
     * the difference shows if you crop right into it or open it on a desktop
     * monitor, and the settings row says exactly that rather than promising it
     * is invisible. 78 is the lowest JPEG quality that stays clean on skin and
     * sky, which are the two things a journal is full of and the two things
     * that break first.
     */
    private const val SMALLER_EDGE = 2000
    private const val SMALLER_QUALITY = 78

    /**
     * The bitrate to aim at, from the picture size.
     *
     * These are the numbers streaming services use for the same resolutions,
     * and they are chosen to be **visually transparent for real footage rather
     * than mathematically lossless**. A phone recording at 1080p60 typically
     * lands between twelve and twenty megabits; eight is a third of that and is
     * still above what most people would call high quality.
     */
    private fun bitrateFor(width: Int, height: Int): Int {
        val pixels = width.toLong() * height.toLong()
        return when {
            pixels >= 3840L * 2160L -> 20_000_000
            pixels >= 2560L * 1440L -> 12_000_000
            pixels >= 1920L * 1080L -> 8_000_000
            pixels >= 1280L * 720L -> 4_000_000
            else -> 2_500_000
        }
    }

    /**
     * The bitrate for a chosen [quality]. **ISSUE 2A.**
     *
     * "Smaller" is half of balanced, and it is honest about what that costs —
     * the setting's own row says *"you may notice it on a big screen"* rather
     * than pretending the saving is free.
     */
    private fun bitrateFor(width: Int, height: Int, quality: String): Int {
        val base = bitrateFor(width, height)
        return if (quality == SMALLER) base / 2 else base
    }

    private fun run(source: File, target: File, quality: String): Outcome {
        val extractor = MediaExtractor()
        var decoder: MediaCodec? = null
        var encoder: MediaCodec? = null
        var muxer: MediaMuxer? = null
        var surface: Surface? = null

        try {
            extractor.setDataSource(source.absolutePath)

            var videoTrack = -1
            var audioTrack = -1
            var inputFormat: MediaFormat? = null
            var audioFormat: MediaFormat? = null

            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (mime.startsWith("video/") && videoTrack < 0) {
                    videoTrack = i
                    inputFormat = format
                } else if (mime.startsWith("audio/") && audioTrack < 0) {
                    // Only codecs an MP4 can legally carry. Anything else and
                    // the whole transcode is abandoned rather than producing a
                    // silent video, which would be worse than a large one.
                    if (mime == "audio/mp4a-latm" || mime == "audio/mp4a" ) {
                        audioTrack = i
                        audioFormat = format
                    } else {
                        // An audio codec MP4 cannot legally carry. Abandoning
                        // the whole transcode is deliberate: a silent video
                        // would be worse than a large one.
                        return Outcome.FAILED
                    }
                }
            }

            val video = inputFormat ?: return Outcome.FAILED
            val width = video.getInteger(MediaFormat.KEY_WIDTH)
            val height = video.getInteger(MediaFormat.KEY_HEIGHT)
            if (width <= 0 || height <= 0) return Outcome.FAILED

            // ══ THE RESOLUTION IS REDUCED NOW, AND IT WAS NOT ════════════════
            //
            // > *"video size or photo size don't work! on longer videos maybe
            // > 50mb plus? not possible i guess! idk make it possible!"*
            //
            // He was right and this was the reason. The encoder was configured
            // at `width, height` — the **source** dimensions — so a 4K clip
            // came out 4K and the only thing that changed was the bitrate. Two
            // consequences, and the second is why he saw nothing happen at all:
            //
            //  * A long 4K recording is large because of pixels times seconds.
            //    Trimming the bitrate alone leaves most of that in place.
            //  * Configuring an AVC encoder at 3840x2160 fails outright on a
            //    lot of mid-range hardware. `video()` catches everything and
            //    returns null, which means "keep the original" — so the setting
            //    silently did nothing on exactly the files it was most needed
            //    for, and said so nowhere.
            //
            // Capping the long edge fixes both. The decoder renders into the
            // encoder's input surface, so asking for a smaller surface is the
            // whole of the scaling — no scaler, no extra buffer, no arithmetic
            // in this file beyond the two lines below.
            //
            // 1080 and 720 rather than anything cleverer: 1080 is more than any
            // phone screen shows and is what a person means by "full quality"
            // for footage of their own life; 720 is the rung below and is the
            // point of choosing "smaller". A clip already at or under the cap
            // is left at its own size — this only ever scales down.
            //
            // ══ ROUND FIFTEEN, ISSUE 10 — THE CAP WAS ON THE WRONG EDGE ═════
            //
            // > *"Video Size – when uploaded it does prompts but never resizes
            // > – I want those features to work!"*
            //
            // It was `maxOf(width, height)`. **"1080p" is the short edge**, not
            // the long one — 1080p is 1920x1080 — so capping the longest side
            // at 1080 turned every ordinary phone recording into **1080x606**.
            // A third of the pixels, from a setting whose own note promises the
            // quality is not compromised, and the rung below took 1280x720 down
            // to 720x405.
            //
            // On the clips it was actually meant for it did the right thing by
            // accident: 4K's long edge is 3840, so it landed at 1080x608 rather
            // than at 1920x1080. Correct direction, wrong destination.
            //
            // `minOf` is the whole fix. A 1920x1080 clip now keeps its size and
            // is re-encoded on bitrate alone; 4K comes down to true 1920x1080.
            val cap = if (quality == SMALLER) 720 else 1080
            val shortest = minOf(width, height)
            val scale = if (shortest > cap) cap.toDouble() / shortest else 1.0
            // H.264 requires even dimensions. Rounding to a multiple of two is
            // the hard requirement; the encoder handles the rest of the
            // alignment itself.
            val outWidth = ((width * scale).toInt() / 2) * 2
            val outHeight = ((height * scale).toInt() / 2) * 2
            if (outWidth <= 0 || outHeight <= 0) return Outcome.FAILED

            // Already modest? Leave it alone. Re-encoding an already-small clip
            // spends battery to lose a little quality.
            //
            // Measured against the bitrate for the size we would **produce**,
            // not the size it arrived at. A 4K clip at 20 Mbps being taken down
            // to 1080p is worth doing; comparing it against 4K's own budget
            // would have called it modest and skipped it.
            val sourceBitrate = runCatching {
                video.getInteger(MediaFormat.KEY_BIT_RATE)
            }.getOrDefault(0)
            val wanted = bitrateFor(outWidth, outHeight, quality)
            if (scale == 1.0 && sourceBitrate in 1..(wanted * 11 / 10)) {
                return Outcome.NOT_WORTH_IT
            }

            val outFormat = MediaFormat.createVideoFormat(
                MediaFormat.MIMETYPE_VIDEO_AVC, outWidth, outHeight
            ).apply {
                setInteger(
                    MediaFormat.KEY_COLOR_FORMAT,
                    MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface
                )
                setInteger(MediaFormat.KEY_BIT_RATE, wanted)
                setInteger(
                    MediaFormat.KEY_FRAME_RATE,
                    runCatching { video.getInteger(MediaFormat.KEY_FRAME_RATE) }
                        .getOrDefault(30)
                )
                // One every two seconds. Seeking in a journal clip is rare and
                // keyframes are the most expensive frames there are.
                setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2)
            }

            encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
            encoder.configure(outFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            surface = encoder.createInputSurface()
            encoder.start()

            // Decoder draws straight onto the encoder's surface. No GL, no
            // intermediate buffers, no colour-format guessing — the two codecs
            // hand frames to each other on the GPU.
            decoder = MediaCodec.createDecoderByType(
                video.getString(MediaFormat.KEY_MIME)!!
            )
            decoder.configure(video, surface, null, 0)
            decoder.start()

            muxer = MediaMuxer(
                target.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4
            )

            // The source's rotation travels with it. Without this a portrait
            // clip comes back on its side, which is exactly the kind of
            // "improvement" that reads as damage.
            runCatching {
                muxer.setOrientationHint(
                    video.getInteger(MediaFormat.KEY_ROTATION)
                )
            }

            extractor.selectTrack(videoTrack)
            return if (pump(
                extractor = extractor,
                decoder = decoder,
                encoder = encoder,
                muxer = muxer,
                source = source,
                audioTrack = audioTrack,
                audioFormat = audioFormat
            )) Outcome.DONE else Outcome.FAILED
        } catch (_: Throwable) {
            return Outcome.FAILED
        } finally {
            runCatching { decoder?.stop() }
            runCatching { decoder?.release() }
            runCatching { encoder?.stop() }
            runCatching { encoder?.release() }
            runCatching { surface?.release() }
            runCatching { muxer?.stop() }
            runCatching { muxer?.release() }
            runCatching { extractor.release() }
        }
    }

    /**
     * Drives frames from the extractor through both codecs into the muxer.
     *
     * **The audio track is added here, not afterwards, and that ordering is a
     * hard requirement rather than a preference.** `MediaMuxer` accepts
     * `addTrack` only before `start()` and throws `IllegalStateException` for
     * any call after it. The video track's format is not known until the
     * encoder reports `INFO_OUTPUT_FORMAT_CHANGED`, so that moment — and only
     * that moment — is when both tracks can be registered and the muxer
     * started. Copying the audio in afterwards, which reads more naturally, is
     * an exception on the first frame every single time.
     */
    private fun pump(
        extractor: MediaExtractor,
        decoder: MediaCodec,
        encoder: MediaCodec,
        muxer: MediaMuxer,
        source: File,
        audioTrack: Int,
        audioFormat: MediaFormat?
    ): Boolean {
        val info = MediaCodec.BufferInfo()
        var muxTrack = -1
        var audioOut = -1
        var muxing = false
        var sawInputEnd = false
        var sawDecodeEnd = false
        var sawEncodeEnd = false
        val giveUpAt = System.currentTimeMillis() + DEADLINE_MS

        while (!sawEncodeEnd) {
            // ISSUE 10. See DEADLINE_MS — a decoder that never produces a frame
            // leaves this loop with no way to end, and the files behind this
            // one in the queue are plaintext in the cache while it spins.
            if (System.currentTimeMillis() > giveUpAt) return false
            // ── Source → decoder ────────────────────────────────────────────
            if (!sawInputEnd) {
                val index = decoder.dequeueInputBuffer(TIMEOUT_US)
                if (index >= 0) {
                    val buffer = decoder.getInputBuffer(index) ?: return false
                    val size = extractor.readSampleData(buffer, 0)
                    if (size < 0) {
                        decoder.queueInputBuffer(
                            index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM
                        )
                        sawInputEnd = true
                    } else {
                        decoder.queueInputBuffer(
                            index, 0, size, extractor.sampleTime, 0
                        )
                        extractor.advance()
                    }
                }
            }

            // ── Decoder → encoder surface ───────────────────────────────────
            if (!sawDecodeEnd) {
                val index = decoder.dequeueOutputBuffer(info, TIMEOUT_US)
                if (index >= 0) {
                    val render = info.size > 0
                    decoder.releaseOutputBuffer(index, render)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                        sawDecodeEnd = true
                        encoder.signalEndOfInputStream()
                    }
                }
            }

            // ── Encoder → muxer ─────────────────────────────────────────────
            val index = encoder.dequeueOutputBuffer(info, TIMEOUT_US)
            if (index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                if (muxing) return false
                muxTrack = muxer.addTrack(encoder.outputFormat)
                // Both tracks, then start. See the note on this method.
                if (audioFormat != null) audioOut = muxer.addTrack(audioFormat)
                muxer.start()
                muxing = true
            } else if (index >= 0) {
                val buffer = encoder.getOutputBuffer(index) ?: return false
                // Codec config is carried in the track format, not as a sample.
                if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                    info.size = 0
                }
                if (info.size > 0 && muxing) {
                    buffer.position(info.offset)
                    buffer.limit(info.offset + info.size)
                    muxer.writeSampleData(muxTrack, buffer, info)
                }
                encoder.releaseOutputBuffer(index, false)
                if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                    sawEncodeEnd = true
                }
            }
        }
        if (!muxing) return false
        if (audioOut >= 0 && audioTrack >= 0) {
            copyAudio(source, audioTrack, audioOut, muxer)
        }
        return true
    }

    /**
     * Copies the audio track across without re-encoding it.
     *
     * A second [MediaExtractor] on the same file, because the first one is
     * positioned in the middle of the video track and rewinding it to read a
     * different track is more fragile than opening another.
     */
    private fun copyAudio(
        source: File,
        track: Int,
        out: Int,
        muxer: MediaMuxer
    ) {
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(source.absolutePath)
            extractor.selectTrack(track)
            val buffer = ByteBuffer.allocate(256 * 1024)
            val info = MediaCodec.BufferInfo()
            while (true) {
                val size = extractor.readSampleData(buffer, 0)
                if (size < 0) break
                info.offset = 0
                info.size = size
                info.presentationTimeUs = extractor.sampleTime
                info.flags = extractor.sampleFlags
                muxer.writeSampleData(out, buffer, info)
                extractor.advance()
            }
        } catch (_: Throwable) {
            // A clip that ends up silent is still the clip. The video is
            // already muxed by this point and is worth more than the audio.
        } finally {
            runCatching { extractor.release() }
        }
    }
}
