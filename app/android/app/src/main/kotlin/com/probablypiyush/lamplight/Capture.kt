package com.probablypiyush.lamplight

import android.media.MediaDataSource
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Build
import android.os.ParcelFileDescriptor
import io.flutter.plugin.common.EventChannel
import java.io.FileInputStream
import kotlin.concurrent.thread

/**
 * Recording audio without it ever becoming a file, and playing it back without
 * it ever becoming a file.
 *
 * WHY THE RECORDER WRITES INTO A PIPE
 *
 * The obvious implementation is `setOutputFile(File(...))`, record, then
 * encrypt the result and delete it. That leaves a plaintext recording sitting
 * in app storage for the entire length of the recording — minutes, potentially
 * — and if the app is killed, the battery dies, or the phone is picked up in
 * that window, it is still sitting there. CLAUDE.md rule 2 says no plaintext
 * user content on disk, ever, and TECH-STACK.md singles this path out as "a
 * hard requirement, verify it early".
 *
 * So `MediaRecorder` is handed the write end of a `ParcelFileDescriptor` pipe.
 * A thread drains the read end and pushes buffers straight up to Dart, which
 * encrypts each one as it arrives. Nothing between the microphone and
 * libsodium ever sees a filesystem.
 *
 * THE FORMAT THIS FORCES, AND WHY
 *
 * **AAC in an ADTS stream, not the usual .m4a.** An MPEG-4 container writes its
 * index atom at the end of the file and seeks backwards to patch the header —
 * a pipe cannot seek, and MediaRecorder fails outright when given one. ADTS is
 * self-framing: every frame carries its own header, so it streams. That is the
 * price of the requirement above and it is worth paying.
 */
class VoiceCapture(private val onError: (String) -> Unit) : EventChannel.StreamHandler {

    private var recorder: MediaRecorder? = null
    private var pipe: Array<ParcelFileDescriptor>? = null
    private var pump: Thread? = null
    private var sink: EventChannel.EventSink? = null

    /**
     * When the current run began, and how much was banked before it.
     * ROUND EIGHT, ISSUE 5A.
     *
     * A paused recording is not a shorter one: the clock has to count the parts
     * that were recorded and none of the gaps between them, so the length is
     * `banked` plus however long the current run has lasted. Measuring from a
     * single start time would count the pause, and every note taken with a
     * pause in it would claim a length it does not have.
     */
    private var startedAt: Long = 0
    private var banked: Long = 0
    private var paused = false

    /** Buffers pushed to Dart. 8 KiB is a few hundred milliseconds of AAC. */
    private val bufferSize = 8 * 1024

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    val isRecording: Boolean get() = recorder != null

    /** Whether the microphone is open but not listening. ISSUE 5A. */
    val isPaused: Boolean get() = paused

    /**
     * ROUND EIGHT, ISSUE 5B — **this used to throw, and that was the bug.**
     *
     * *"When I open it up back and when I try to record the voice it doesn't
     * works! — cause the microphone was on!"*
     *
     * It read `if (recorder != null) throw IllegalStateException(...)`. Any
     * path that left a recorder alive — the sheet disposed without Stop, the
     * activity torn down and rebuilt — left this object holding an open
     * microphone, and then **every future recording failed for the lifetime of
     * the process**. One missed cleanup and voice notes were finished until the
     * app was force-quit, which is exactly what he described.
     *
     * Refusing to start was the wrong answer to that state in any case. The
     * user has asked to record; the only useful thing to do with a stale
     * recorder is get rid of it. So it is released and a new one starts. There
     * is no path through this method that leaves the microphone held by
     * something nobody can reach.
     */
    fun start() {
        if (recorder != null) release()

        val created = ParcelFileDescriptor.createPipe()
        pipe = created
        val read = created[0]
        val write = created[1]

        @Suppress("DEPRECATION")
        val r = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(appContext)
        } else {
            MediaRecorder()
        }

        r.setAudioSource(MediaRecorder.AudioSource.MIC)
        // ADTS, for the reason in the class comment. Do not "fix" this to MPEG_4.
        r.setOutputFormat(MediaRecorder.OutputFormat.AAC_ADTS)
        r.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        // Voice, not music. 32 kbps mono at 44.1 kHz is clearly intelligible
        // speech at roughly a quarter of a megabyte a minute, which matters
        // when every one of these is backed up and carried around forever.
        r.setAudioEncodingBitRate(32000)
        r.setAudioSamplingRate(44100)
        r.setAudioChannels(1)
        r.setOutputFile(write.fileDescriptor)
        r.prepare()
        r.start()
        recorder = r
        startedAt = System.currentTimeMillis()
        banked = 0
        paused = false

        // Drain the pipe. If nobody reads it, the pipe's buffer fills and the
        // recorder blocks — so this thread is not optional plumbing, it is what
        // keeps the recording running.
        pump = thread(name = "lamplight-audio-pump") {
            try {
                FileInputStream(read.fileDescriptor).use { input ->
                    val buffer = ByteArray(bufferSize)
                    while (true) {
                        val n = input.read(buffer)
                        if (n < 0) break
                        if (n == 0) continue
                        val chunk = buffer.copyOf(n)
                        val out = sink
                        if (out != null) {
                            mainHandler.post { out.success(chunk) }
                        }
                    }
                }
            } catch (e: Exception) {
                onError(e.message ?: "The recording was interrupted.")
            } finally {
                mainHandler.post { sink?.endOfStream() }
            }
        }
    }

    /**
     * Holds the microphone open but stops encoding. **ISSUE 5A.**
     *
     * *"There is no voice pause button while recording!"*
     *
     * ADTS is what makes this three lines rather than a rewrite. Every frame
     * carries its own header, so the encoder can stop producing them and start
     * again later and the result is still one valid stream — there is no index
     * to patch and no container to re-write. The same property that forced ADTS
     * on us, in the class comment above, is the one that pays for pause.
     *
     * Returns whether it actually did anything, so the screen never draws a
     * paused button over a recorder that is still listening.
     */
    fun pause(): Boolean {
        val r = recorder ?: return false
        if (paused) return true
        return try {
            r.pause()
            banked += System.currentTimeMillis() - startedAt
            paused = true
            true
        } catch (_: Exception) {
            // Some devices refuse. Better to carry on recording than to tell
            // somebody it is paused while the microphone is still open — of
            // everything that can go wrong here, that is the one that matters.
            false
        }
    }

    /** Picks the recording back up where it stopped. **ISSUE 5A.** */
    fun resume(): Boolean {
        val r = recorder ?: return false
        if (!paused) return true
        return try {
            r.resume()
            startedAt = System.currentTimeMillis()
            paused = false
            true
        } catch (_: Exception) {
            false
        }
    }

    /** Stops and returns the length in milliseconds. */
    fun stop(): Long {
        val r = recorder ?: return 0
        // Only the parts that were recorded. A pause is not time in the note.
        val elapsed =
            banked + if (paused) 0 else System.currentTimeMillis() - startedAt
        try {
            // A paused recorder cannot be stopped on some versions without
            // being resumed first, and a note that will not save because it was
            // paused is the worst outcome available here.
            if (paused) {
                try {
                    r.resume()
                } catch (_: Exception) {
                }
            }
            r.stop()
        } catch (_: Exception) {
            // MediaRecorder throws if it is stopped before it has captured
            // anything at all. There is nothing to save either way, and an
            // exception here would look to the user like their recording was
            // lost rather than never started.
        }
        r.release()
        recorder = null
        paused = false
        banked = 0

        // Closing the write end is what ends the stream in Dart, which is what
        // lets the encryption finish and the entry be written. Order matters.
        pipe?.get(1)?.close()
        pump?.join(2000)
        pipe?.get(0)?.close()
        pipe = null
        pump = null
        return elapsed
    }

    fun cancel() {
        stop()
    }

    /**
     * Puts the microphone down, whatever state it is in. **ISSUE 5B.**
     *
     * Distinct from [stop] because it promises nothing about the recording and
     * throws nothing: it is what [start] calls when it finds a stale recorder,
     * and what the activity calls on its way out. Every failure inside is
     * swallowed deliberately — the one outcome that must not happen is leaving
     * this method with the microphone still held.
     */
    fun release() {
        try {
            stop()
        } catch (_: Exception) {
        }
        try {
            recorder?.release()
        } catch (_: Exception) {
        }
        recorder = null
        paused = false
        banked = 0
        try {
            pipe?.get(1)?.close()
            pipe?.get(0)?.close()
        } catch (_: Exception) {
        }
        pipe = null
        pump = null
    }

    /** 0..1, for the waveform. */
    fun amplitude(): Double {
        // A paused recorder still answers `maxAmplitude`, and answering it
        // would draw a live waveform over a microphone that is not listening.
        // ISSUE 5A: this screen exists to prove it is hearing something, so it
        // must never claim to when it is not.
        if (paused) return 0.0
        val r = recorder ?: return 0.0
        return try {
            // getMaxAmplitude is 0..32767 and resets on each read. Square-rooted
            // because loudness is perceptual: a linear bar spends its whole life
            // near the bottom and looks broken.
            val raw = r.maxAmplitude.coerceIn(0, 32767).toDouble() / 32767.0
            Math.sqrt(raw)
        } catch (_: Exception) {
            0.0
        }
    }

    companion object {
        lateinit var appContext: android.content.Context
        val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
    }
}

/**
 * Plays audio held in a byte array.
 *
 * Every audio library takes a path or a URL. This app has neither — it has
 * plaintext that exists only in RAM and must not reach a disk. `MediaDataSource`
 * is Android's answer: the player asks for bytes at an offset, and we serve
 * them from memory.
 */
class MemoryAudioPlayer {

    private var player: MediaPlayer? = null
    private var speed: Float = 1.0f

    /** Milliseconds played so far, and the total. Both -1 when nothing is loaded. */
    fun position(): Int = try {
        player?.currentPosition ?: -1
    } catch (_: Exception) {
        -1
    }

    fun duration(): Int = try {
        player?.duration ?: -1
    } catch (_: Exception) {
        -1
    }

    val isPlaying: Boolean get() = try {
        player?.isPlaying == true
    } catch (_: Exception) {
        false
    }

    /**
     * Jump to a point in the recording.
     *
     * The thing a ten-minute voice note is unusable without. Listening from the
     * start to reach the ninth minute is not a limitation, it is a reason not to
     * record anything longer than a sentence.
     */
    fun seekTo(ms: Int) {
        try {
            player?.seekTo(ms.coerceAtLeast(0))
        } catch (_: Exception) {
        }
    }

    fun pause() {
        try {
            if (player?.isPlaying == true) player?.pause()
        } catch (_: Exception) {
        }
    }

    fun resume() {
        try {
            player?.start()
            applySpeed()
        } catch (_: Exception) {
        }
    }

    /**
     * Playback rate.
     *
     * `PlaybackParams` also changes pitch unless the resampler is told
     * otherwise; MediaPlayer's default preserves pitch, which is what makes 1.5x
     * listenable rather than comic. Setting params on a paused player starts it,
     * so the caller's state is restored afterwards.
     */
    fun setSpeed(rate: Float) {
        speed = rate
        applySpeed()
    }

    private fun applySpeed() {
        val p = player ?: return
        try {
            val wasPlaying = p.isPlaying
            p.playbackParams = p.playbackParams.setSpeed(speed)
            if (!wasPlaying) p.pause()
        } catch (_: Exception) {
            // Some devices refuse particular rates. Falling back to 1x is
            // better than losing playback altogether.
        }
    }

    fun play(bytes: ByteArray, onFinished: () -> Unit) {
        stop()
        val p = MediaPlayer()
        p.setDataSource(object : MediaDataSource() {
            override fun readAt(position: Long, buffer: ByteArray, offset: Int, size: Int): Int {
                if (position >= bytes.size) return -1
                val available = (bytes.size - position).toInt()
                val n = minOf(size, available)
                System.arraycopy(bytes, position.toInt(), buffer, offset, n)
                return n
            }

            override fun getSize(): Long = bytes.size.toLong()

            override fun close() {}
        })
        p.setOnCompletionListener {
            onFinished()
            stop()
        }
        p.prepare()
        p.start()
        player = p
        applySpeed()
    }

    fun stop() {
        player?.let {
            try {
                if (it.isPlaying) it.stop()
            } catch (_: Exception) {
            }
            it.release()
        }
        player = null
        speed = 1.0f
    }
}
