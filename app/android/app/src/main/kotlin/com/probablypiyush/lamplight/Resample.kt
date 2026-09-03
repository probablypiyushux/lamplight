package com.probablypiyush.lamplight

import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.PI
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

/**
 * Getting somebody's voice to 16 kHz mono without wrecking it on the way.
 *
 * ══ WHY THIS FILE EXISTS, AND WHAT WAS WRONG BEFORE IT ══════════════════════
 *
 * Both transcription paths used to do this inline, by **nearest neighbour**:
 * pick the closest source sample for each output sample and throw the rest
 * away. Both carried a comment defending it, and the comment said this:
 *
 * > *"It goes straight into a speech model whose own front end re-filters
 * > everything it is given, and the difference has no measurable effect on
 * > what comes out."*
 *
 * **That is wrong, and it is the interesting kind of wrong** — it is true of
 * *filtering* and false of *sampling*, and the difference is the whole of
 * signal processing.
 *
 * A voice note is recorded at 44.1 kHz. Dropping to 16 kHz without a low-pass
 * first does not discard the energy above 8 kHz; it **folds it back down** into
 * the speech band, mirrored around 8 kHz, where it is now indistinguishable
 * from real speech. A 10 kHz sibilant arrives as a 6 kHz tone. Whisper's front
 * end computes a log-mel spectrogram of whatever it is handed, and it cannot
 * remove aliasing, because by then the aliased energy *is* the signal. Nothing
 * downstream can undo this. It has to not happen.
 *
 * And 44100/16000 is 2.75625 — not a whole number — so nearest neighbour also
 * jitters the sampling instant by up to half a source sample, which adds a
 * warble on top of the aliasing.
 *
 * **What it costs the person:** the band that gets polluted is exactly where
 * the consonants live. `s`, `sh`, `f`, `th`, and the aspirated and retroflex
 * consonants that carry most of the distinctions in Hindi. Vowels survive;
 * consonants smear. The transcript that comes back is words-shaped and wrong,
 * which reads as *"the model cannot even understand one language"* rather than
 * as a bug in the four lines above the model.
 *
 * ── WHAT THIS DOES INSTEAD ─────────────────────────────────────────────────
 *
 * A windowed-sinc resampler: a band-limited interpolation kernel, cut off at
 * the destination's Nyquist frequency, evaluated at each output position. It
 * is the standard answer and it is about forty lines.
 *
 * The kernel is normalised by its own sum rather than pre-scaled, which keeps
 * the gain at exactly 1 at DC and makes the first and last few samples — where
 * the window runs off the end of the recording — quietly correct instead of
 * quietly attenuated.
 *
 * **The cost.** About 66 multiply-adds per output sample, so roughly a million
 * a second of audio. Whisper's smallest model is several billion. This is not
 * measurable beside it, and the old comment's *"a hundred lines of signal
 * processing for no measurable difference"* had the trade exactly backwards:
 * it is forty lines for the difference between consonants and mush.
 */
object Resample {

    /** What Whisper and Android's recogniser both want. */
    const val TARGET_RATE = 16000

    /**
     * Half the kernel width, in **destination** samples.
     *
     * Twelve is where the sinc has decayed far enough that the Blackman window
     * is doing almost nothing, which is the point of diminishing returns. More
     * taps buy a sharper transition band that speech cannot use.
     */
    private const val HALF_TAPS = 12

    /**
     * Mixes to mono, resamples to 16 kHz, and scales to −1..1 for whisper.cpp.
     */
    fun toMonoFloat16k(pcm: ByteArray, rate: Int, channels: Int): FloatArray {
        val mono = toMono(pcm, channels)
        if (mono.isEmpty()) return FloatArray(0)
        if (rate == TARGET_RATE) return mono
        return resample(mono, rate, TARGET_RATE)
    }

    /**
     * The same, as little-endian 16-bit PCM, for the path that hands bytes on.
     */
    fun toMonoPcm16k(pcm: ByteArray, rate: Int, channels: Int): ByteArray {
        val samples = toMonoFloat16k(pcm, rate, channels)
        val out = ByteBuffer.allocate(samples.size * 2).order(ByteOrder.LITTLE_ENDIAN)
        for (s in samples) {
            // Rounded, then clamped. Truncating biases every sample towards
            // zero, which over a whole recording is a small constant loss of
            // level for no reason.
            val v = (s * 32767.0f).roundToInt().coerceIn(-32768, 32767)
            out.putShort(v.toShort())
        }
        return out.array()
    }

    /** Interleaved 16-bit PCM to mono floats in −1..1, at the original rate. */
    private fun toMono(pcm: ByteArray, channels: Int): FloatArray {
        val input = ByteBuffer.wrap(pcm).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        val ch = channels.coerceAtLeast(1)
        val frames = input.remaining() / ch
        if (frames <= 0) return FloatArray(0)

        val out = FloatArray(frames)
        for (i in 0 until frames) {
            var sum = 0
            for (c in 0 until ch) sum += input.get(i * ch + c).toInt()
            out[i] = (sum / ch) / 32768.0f
        }
        return out
    }

    /**
     * Band-limited resampling, [from] Hz to [to] Hz.
     *
     * The cutoff is the **lower** of the two Nyquist frequencies, expressed as
     * a fraction of the source rate. Downsampling, that is the destination's —
     * which is the anti-aliasing filter, and the whole point of this file.
     * Upsampling, it is the source's, and the sinc is then a plain
     * band-limited interpolator.
     */
    private fun resample(input: FloatArray, from: Int, to: Int): FloatArray {
        val ratio = to.toDouble() / from.toDouble()
        val outFrames = floor(input.size * ratio).toInt().coerceAtLeast(1)
        val out = FloatArray(outFrames)

        // Relative cutoff, in cycles per source sample. Capped at 1 so that
        // upsampling does not try to invent a filter wider than Nyquist.
        val cutoff = min(1.0, ratio)
        // The kernel is defined in destination samples and applied in source
        // samples, so it stretches as the rate drops — which is what makes it
        // an anti-aliasing filter rather than merely a smooth interpolator.
        val halfWidth = HALF_TAPS / cutoff

        for (i in 0 until outFrames) {
            // Where this output sample sits, in source samples. Fractional,
            // which is exactly what nearest neighbour was throwing away.
            val centre = i / ratio
            val first = ceil(centre - halfWidth).toInt()
            val last = floor(centre + halfWidth).toInt()

            var sum = 0.0
            var norm = 0.0
            for (j in first..last) {
                if (j < 0 || j >= input.size) continue
                val t = centre - j
                val k = blackman(t / halfWidth) * sinc(cutoff * t)
                sum += k * input[j]
                norm += k
            }
            // Normalised by the kernel's own sum: unity gain at DC, and the
            // first and last few samples stay at the right level instead of
            // fading where the window runs off the end of the recording.
            out[i] = if (norm > 1e-9) (sum / norm).toFloat() else 0f
        }
        return out
    }

    /** sin(πx)/(πx), and 1 at zero. */
    private fun sinc(x: Double): Double {
        if (x == 0.0) return 1.0
        val px = PI * x
        return sin(px) / px
    }

    /**
     * Blackman window over −1..1, zero outside.
     *
     * Blackman rather than Hann: its side lobes are about 30 dB further down,
     * and side lobes here are exactly the leakage that anti-aliasing is meant
     * to be stopping.
     */
    private fun blackman(x: Double): Double {
        if (x <= -1.0 || x >= 1.0) return 0.0
        val a = PI * (x + 1.0)
        return 0.42 - 0.5 * cos(a) + 0.08 * cos(2.0 * a)
    }
}
