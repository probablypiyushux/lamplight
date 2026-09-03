package com.probablypiyush.lamplight

import android.content.Context
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaDataSource
import android.media.MediaExtractor
import android.media.MediaFormat
import android.os.Build
import android.os.Bundle
import android.os.ParcelFileDescriptor
import android.speech.ModelDownloadListener
import android.speech.RecognitionListener
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import java.io.ByteArrayOutputStream
import java.io.FileOutputStream
import java.util.Locale
import java.util.concurrent.Executors

/**
 * Writing down what was said, without any of it leaving the phone.
 *
 * ══ ISSUE 15, ROUND NINE ═════════════════════════════════════════════════════
 *
 * > *"Voice transcribe — there should be an option for view transcript. Voice
 * > is recorded — take your time — even if the app is closed — take your time —
 * > transcribe the audio — well use a offline model ofc! Which runs on the
 * > phone — supports multilingual languages — works better — free cause it runs
 * > on my app locally … and slower output is not an issue — when a better
 * > output is received!"*
 *
 * It is also item 3 of `Honest Review/WHAT-LAMPLIGHT-LACKS.md`, where it is
 * called *"the single largest gap between what the app collects and what it can
 * give back"* — the `transcript` column has existed since the first schema and
 * nothing has ever written to it.
 *
 * ── THE ONE THING THAT COULD GO CATASTROPHICALLY WRONG ──────────────────────
 *
 * Android has two speech recognisers and they look identical from Dart.
 *
 * `SpeechRecognizer.createSpeechRecognizer()` is the ordinary one, and on most
 * phones it **sends the audio to Google's servers**. Lamplight has no INTERNET
 * permission, and that would not save us for a moment: the recogniser runs in
 * *another process*, with its own permissions, and would upload somebody's
 * diary quite happily on our behalf. The app's central promise — *"nothing
 * leaves this phone"* — would become false, silently, with no way for anyone to
 * tell from the outside.
 *
 * `SpeechRecognizer.createOnDeviceSpeechRecognizer()` is a **different API with
 * a different contract**: Android 13 added it precisely so an app can demand
 * on-device recognition rather than hope for it. There is no fallback in this
 * file. If it is unavailable, the feature is not offered.
 *
 * **Never change this to `createSpeechRecognizer`, and never add a fallback to
 * it.** `EXTRA_PREFER_OFFLINE` is set as well, and it is belt and braces — a
 * *preference*, which is exactly the kind of thing that gets ignored on the
 * day it matters. The constructor is the guarantee.
 *
 * ── WHY THE AUDIO IS DECODED HERE ───────────────────────────────────────────
 *
 * A recording in the vault is AAC in an ADTS stream, encrypted, with a random
 * name. The recogniser wants raw 16-bit PCM. So the bytes are decrypted in
 * Dart, handed here **in memory**, decoded with `MediaCodec`, downsampled to
 * 16 kHz mono, and pushed down a pipe into the recogniser.
 *
 * Nothing touches a disk at any point, so `CLAUDE.md` rule 2 is not in play and
 * this is not a second exception to it. What *does* happen is that the
 * plaintext audio crosses into the system's recognition process — which is a
 * real handoff and is why the whole feature is off until somebody turns it on.
 * It is the same shape as "Open with": the user's own content, going where the
 * user asked it to go, and nowhere else.
 */
object Transcribe {

    private val work = Executors.newSingleThreadExecutor()

    /** The recogniser wants 16 kHz mono. Every speech model is trained there. */
    private const val TARGET_RATE = 16000

    /**
     * Whether this phone can do it at all.
     *
     * Two gates, and both are hard. API 33 is when the on-device API exists;
     * `isOnDeviceRecognitionAvailable` is whether this particular phone ships a
     * service behind it — plenty do not, and there is nothing to be done about
     * that except say so.
     */
    fun available(context: Context): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            SpeechRecognizer.isOnDeviceRecognitionAvailable(context)

    /**
     * Which languages this phone has actually downloaded a model for.
     *
     * Asked rather than assumed. A language the system does not have installed
     * produces silence, not an error, and silence is the worst possible answer
     * — it looks like the recording had nothing in it.
     */
    fun languages(
        context: Context,
        onDone: (installed: List<String>, pending: List<String>) -> Unit,
        onError: (String) -> Unit
    ) {
        if (!available(context)) return onError("This phone cannot do that.")
        VoiceCapture.mainHandler.post {
            try {
                val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
                val intent = android.content.Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
                recognizer.checkRecognitionSupport(
                    intent,
                    work,
                    object : RecognitionSupportCallback {
                        override fun onSupportResult(support: RecognitionSupport) {
                            VoiceCapture.mainHandler.post {
                                recognizer.destroy()
                                onDone(
                                    support.installedOnDeviceLanguages,
                                    support.supportedOnDeviceLanguages
                                )
                            }
                        }

                        override fun onError(error: Int) {
                            VoiceCapture.mainHandler.post {
                                recognizer.destroy()
                                onError("The languages could not be listed.")
                            }
                        }
                    }
                )
            } catch (e: Exception) {
                onError(e.message ?: "The languages could not be listed.")
            }
        }
    }

    /**
     * Asks the system to fetch a language model.
     *
     * **This is a download, and it is the one thing in this file that touches a
     * network** — the system's, not ours, and it carries a *model* rather than
     * anybody's voice. Nothing about the user's recordings goes anywhere. It is
     * still behind an explicit tap, because "this app has no internet
     * permission" is a claim people should be able to keep believing without
     * having to know the difference between our process and Android's.
     */
    fun fetchLanguage(context: Context, tag: String, onDone: (Boolean) -> Unit) {
        if (!available(context)) return onDone(false)
        VoiceCapture.mainHandler.post {
            try {
                val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
                val intent = android.content.Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
                    .putExtra(RecognizerIntent.EXTRA_LANGUAGE, tag)
                recognizer.triggerModelDownload(
                    intent,
                    work,
                    object : ModelDownloadListener {
                        override fun onProgress(completedPercent: Int) {}
                        override fun onSuccess() {
                            VoiceCapture.mainHandler.post {
                                recognizer.destroy(); onDone(true)
                            }
                        }

                        override fun onScheduled() {
                            VoiceCapture.mainHandler.post {
                                recognizer.destroy(); onDone(true)
                            }
                        }

                        override fun onError(error: Int) {
                            VoiceCapture.mainHandler.post {
                                recognizer.destroy(); onDone(false)
                            }
                        }
                    }
                )
            } catch (_: Exception) {
                onDone(false)
            }
        }
    }

    /**
     * Transcribes [aac] — a whole recording, in memory — into text.
     *
     * [languageTag] is a BCP-47 tag such as `en-IN` or `hi-IN`.
     */
    fun run(
        context: Context,
        aac: ByteArray,
        languageTag: String,
        onDone: (String) -> Unit,
        onError: (String) -> Unit
    ) {
        if (!available(context)) return onError("This phone cannot do that.")

        work.execute {
            val pcm: ByteArray
            try {
                pcm = decodeToPcm(aac)
            } catch (e: Exception) {
                VoiceCapture.mainHandler.post {
                    onError(e.message ?: "That recording could not be read.")
                }
                return@execute
            }
            if (pcm.isEmpty()) {
                VoiceCapture.mainHandler.post { onDone("") }
                return@execute
            }
            VoiceCapture.mainHandler.post { listen(context, pcm, languageTag, onDone, onError) }
        }
    }

    /**
     * The recogniser itself. **Main thread only** — `SpeechRecognizer` says so
     * and throws if it is not.
     */
    private fun listen(
        context: Context,
        pcm: ByteArray,
        languageTag: String,
        onDone: (String) -> Unit,
        onError: (String) -> Unit
    ) {
        val recognizer: SpeechRecognizer
        val pipe: Array<ParcelFileDescriptor>
        try {
            recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
            pipe = ParcelFileDescriptor.createPipe()
        } catch (e: Exception) {
            return onError(e.message ?: "That recording could not be read.")
        }

        val said = StringBuilder()
        var finished = false

        fun finish(text: String?, error: String?) {
            if (finished) return
            finished = true
            try {
                recognizer.destroy()
            } catch (_: Exception) {
            }
            try {
                pipe[0].close()
            } catch (_: Exception) {
            }
            if (error != null) onError(error) else onDone(text ?: "")
        }

        recognizer.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
            override fun onPartialResults(partialResults: Bundle?) {}

            override fun onError(error: Int) {
                // NO_MATCH on a segmented session usually means one stretch of
                // the recording had nothing in it, and the rest may still. It
                // is only a failure if nothing at all came back.
                if (error == SpeechRecognizer.ERROR_NO_MATCH ||
                    error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT
                ) {
                    finish(said.toString().trim(), null)
                    return
                }
                finish(null, describe(error))
            }

            override fun onResults(results: Bundle?) {
                collect(results)
                finish(said.toString().trim(), null)
            }

            override fun onSegmentResults(segmentResults: Bundle) {
                collect(segmentResults)
            }

            override fun onEndOfSegmentedSession() {
                finish(said.toString().trim(), null)
            }

            private fun collect(bundle: Bundle?) {
                val best = bundle
                    ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    ?.firstOrNull()
                    ?.trim()
                if (best.isNullOrEmpty()) return
                if (said.isNotEmpty()) said.append(' ')
                said.append(best)
            }
        })

        val intent = android.content.Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, languageTag)
            // Belt and braces. The constructor above is the actual guarantee —
            // see the note at the top of this file.
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
            // Sentence case and punctuation, where the model can manage it. A
            // wall of lowercase words is technically the same information and
            // is not something anybody wants to read back in a year.
            putExtra(RecognizerIntent.EXTRA_ENABLE_FORMATTING, RecognizerIntent.FORMATTING_OPTIMIZE_QUALITY)
            // Read the audio from our pipe rather than from the microphone.
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE, pipe[0])
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_CHANNEL_COUNT, 1)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
            putExtra(RecognizerIntent.EXTRA_AUDIO_SOURCE_SAMPLING_RATE, TARGET_RATE)
            // **The reason a five-minute note works at all.** Without this the
            // recogniser stops at the first pause and returns one sentence.
            // Segmented, it keeps going until the stream ends and hands back a
            // result per stretch of speech, which is what "take your time" and
            // a long recording actually require.
            putExtra(RecognizerIntent.EXTRA_SEGMENTED_SESSION, RecognizerIntent.EXTRA_AUDIO_SOURCE)
        }

        // The writer. Closing the write end is what tells the recogniser the
        // recording has ended, so it happens in a `finally` — a pipe left open
        // is a session that never finishes.
        work.execute {
            try {
                FileOutputStream(pipe[1].fileDescriptor).use { out ->
                    var at = 0
                    val block = 8192
                    while (at < pcm.size) {
                        val n = minOf(block, pcm.size - at)
                        out.write(pcm, at, n)
                        at += n
                    }
                    out.flush()
                }
            } catch (_: Exception) {
            } finally {
                try {
                    pipe[1].close()
                } catch (_: Exception) {
                }
            }
        }

        try {
            recognizer.startListening(intent)
        } catch (e: Exception) {
            finish(null, e.message ?: "That recording could not be read.")
        }
    }

    /**
     * AAC in, 16 kHz mono 16-bit PCM out, entirely in memory.
     *
     * `MediaDataSource` over a byte array is the same trick the voice player and
     * the video player already use — see `Capture.kt` — and it exists for the
     * same reason: the plaintext must never become a file.
     */
    private fun decodeToPcm(aac: ByteArray): ByteArray {
        val extractor = MediaExtractor()
        extractor.setDataSource(object : MediaDataSource() {
            override fun readAt(position: Long, buffer: ByteArray, offset: Int, size: Int): Int {
                if (position >= aac.size) return -1
                val n = minOf(size, (aac.size - position).toInt())
                System.arraycopy(aac, position.toInt(), buffer, offset, n)
                return n
            }

            override fun getSize(): Long = aac.size.toLong()
            override fun close() {}
        })

        var track = -1
        var format: MediaFormat? = null
        for (i in 0 until extractor.trackCount) {
            val f = extractor.getTrackFormat(i)
            if (f.getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true) {
                track = i
                format = f
                break
            }
        }
        if (track < 0 || format == null) {
            extractor.release()
            throw IllegalStateException("That recording has no sound in it.")
        }
        extractor.selectTrack(track)

        val sourceRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        val sourceChannels =
            if (format.containsKey(MediaFormat.KEY_CHANNEL_COUNT)) {
                format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            } else {
                1
            }

        val codec = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
        codec.configure(format, null, null, 0)
        codec.start()

        val raw = ByteArrayOutputStream()
        val info = MediaCodec.BufferInfo()
        var inputDone = false
        var outputDone = false

        try {
            while (!outputDone) {
                if (!inputDone) {
                    val index = codec.dequeueInputBuffer(10000)
                    if (index >= 0) {
                        val buffer = codec.getInputBuffer(index)!!
                        val n = extractor.readSampleData(buffer, 0)
                        if (n < 0) {
                            codec.queueInputBuffer(
                                index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM
                            )
                            inputDone = true
                        } else {
                            codec.queueInputBuffer(index, 0, n, extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }

                val out = codec.dequeueOutputBuffer(info, 10000)
                if (out >= 0) {
                    if (info.size > 0) {
                        val buffer = codec.getOutputBuffer(out)!!
                        val chunk = ByteArray(info.size)
                        buffer.position(info.offset)
                        buffer.get(chunk)
                        raw.write(chunk)
                    }
                    codec.releaseOutputBuffer(out, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) outputDone = true
                }
            }
        } finally {
            try {
                codec.stop()
            } catch (_: Exception) {
            }
            codec.release()
            extractor.release()
        }

        return resample(raw.toByteArray(), sourceRate, sourceChannels)
    }

    /**
     * Mixes to mono and drops to 16 kHz.
     *
     * ── THIS USED TO BE NEAREST-NEIGHBOUR, AND THE COMMENT DEFENDING IT WAS
     *    THE WRONG WAY ROUND ───────────────────────────────────────────────
     *
     * It said a proper low-pass *"would be better for listening; nobody listens
     * to this"*, and that a hundred lines of signal processing would make no
     * measurable difference to what came out. Both halves are wrong, and in the
     * same way: decimating without a low-pass is not a loss of fidelity, it is
     * **aliasing** — the energy above 8 kHz folds back down into the speech
     * band rather than disappearing, and no front end downstream can tell it
     * apart from speech afterwards.
     *
     * It is forty lines, not a hundred, and the difference it makes is the
     * difference between consonants and mush. See `Resample`.
     */
    private fun resample(pcm: ByteArray, rate: Int, channels: Int): ByteArray =
        Resample.toMonoPcm16k(pcm, rate, channels)

    /**
     * What a person is told. Never a code — `PLAN.md` §7.0-C-i, and round
     * nine's ISSUE 16 in particular.
     */
    private fun describe(error: Int): String = when (error) {
        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS ->
            "Lamplight is not allowed to do that on this phone."
        SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED,
        SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE ->
            "That language is not on this phone yet."
        SpeechRecognizer.ERROR_RECOGNIZER_BUSY ->
            "The phone is already writing something down. It will try again."
        else -> "That recording could not be written down."
    }

    /** The phone's own language, as a starting point. */
    fun defaultLanguage(): String = Locale.getDefault().toLanguageTag()
}
