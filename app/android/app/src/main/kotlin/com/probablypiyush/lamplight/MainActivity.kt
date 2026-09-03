package com.probablypiyush.lamplight

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.FileProvider
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // FLAG_SECURE, set before super.onCreate so the window carries it from
        // the first frame. Set it later and there is a window — literally — in
        // which the system can capture a thumbnail.
        //
        // It does three things, and all three matter here:
        //   - the recent-apps switcher shows a blank rectangle, not the screen
        //   - screenshots and screen recording are refused, by us and by other apps
        //   - the window will not mirror to a non-secure external display
        //
        // 02-security/THREAT-MODEL.md ranks "the person who picks up the
        // unlocked phone" as the most likely adversary by a wide margin, and
        // the recents thumbnail is the cheapest way that person reads a note
        // without ever unlocking the vault. This one line closes it.
        //
        // It applies to the whole app because Flutter renders every screen into
        // this single Activity. There is no per-screen opt-out, which is the
        // behaviour we want: a screen that forgets to set it cannot exist.
        // ── Secure first, always, and relaxed only on request ─────────────
        //
        // The flag goes on here unconditionally and before `super.onCreate`, so
        // the very first frame is covered. If the user has turned screenshots
        // on, Dart clears it a moment later through `setScreenSecurity` — see
        // the note on that method below, and `SecurityScreen`'s switch.
        //
        // **The order is the security property.** Reading the setting first and
        // then deciding would mean a window that is briefly capturable on every
        // cold start, and the recents thumbnail is taken at exactly those
        // moments. On by default, off by choice, never the other way round.
        //
        // This replaces SCREENSHOT_HOLE, which skipped the flag in debug builds
        // to let Piyush photograph the interface. That was a build-variant hack
        // with a real cost — it only worked on the slower debug build, so the
        // app he was judging was never the app he had — and he asked for
        // screenshots on the release build on 22 August. It is a setting now,
        // which is both more useful and more honest: the capability is visible
        // in the interface rather than hidden in a build flag.
        // == THE SANDBOX BUILD IS THE ONE EXCEPTION, AND IT CANNOT SHIP =====
        //
        // 3 September 2026. Rule 7 is that FLAG_SECURE is on from the first
        // frame of every launch, and it still is for every build that reaches
        // anybody. This is not one of those builds.
        //
        // `-PlampSandbox=true` produces `...lamplight.sandbox`, a separate
        // application id with its own empty vault, built so the destructive
        // half of the app - delete, trash, restore, passcode change - can be
        // exercised without a real journal in the way. Testing it means reading
        // the screen, and FLAG_SECURE returns a black rectangle to
        // `screencap`, so onboarding could not be driven at all: the recovery
        // quiz asks for three of twelve words and there is no way to learn
        // which three without seeing them.
        //
        // Keyed on the **application id at runtime**, not on a build variant.
        // The shipped id is `com.probablypiyush.lamplight` and cannot end in
        // `.sandbox`, so no release build can take this branch however it is
        // compiled - which is a stronger guarantee than a debug check, and the
        // reason it is written this way. `SCREENSHOT_HOLE` was a debug-variant
        // hack and it is not being reinstated; the *setting* remains the
        // answer for real builds.
        if (!packageName.endsWith(".sandbox")) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
        super.onCreate(savedInstanceState)

        // ── Tapjacking ────────────────────────────────────────────────────
        //
        // An app with the overlay permission can draw a transparent window on
        // top of this one and let taps fall through. The attack is: draw an
        // innocuous-looking button over "Delete forever", or over the
        // fingerprint prompt, and the user's finger does something they never
        // saw. It is the one remote-ish attack that works on an app with no
        // network, because the attacker's code is already on the phone.
        //
        // `filterTouchesWhenObscured` makes the framework discard any touch
        // that arrives through another window. It is one line, it costs
        // nothing, and Flutter's own view does not set it.
        //
        // Applied to the content root so it covers every screen — there is
        // only ever one Activity here, so there is no screen it can miss.
        window.decorView.filterTouchesWhenObscured = true

        // ISSUE 13. Parked, not acted on: the vault is locked on every cold
        // start and there is nowhere for a photograph to go until somebody
        // types a passcode. Dart asks for it after the unlock. See Sharing.
        Sharing.park(intent)
    }

    /**
     * A share arriving while the app is already open. **ISSUE 13.**
     *
     * `launchMode="singleTop"` means Android reuses this activity rather than
     * building a second one, and delivers the new intent here instead of to
     * `onCreate`. Without this, sharing into an app that was already running
     * would appear to do nothing at all — which is the exact class of defect
     * this round is about.
     *
     * `setIntent` as well, so `getIntent()` does not keep returning the
     * original launch intent to anything that asks later.
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (Sharing.park(intent)) {
            // The vault may well be open already, in which case Dart can act at
            // once rather than waiting for the next unlock.
            channel.invokeMethod("sharedArrived", null)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    //  Getting a backup file out of the app, and back in again.
    //
    //  WHY THIS IS HAND-WRITTEN AND NOT A PLUGIN
    //
    //  A backup is worthless inside app-private storage — the whole point of
    //  UX-FLOWS.md flow 5 is that the file ends up somewhere the user chooses
    //  and the phone dying does not take it. The usual answers are share_plus
    //  and file_picker. Both are large, both pull in their own dependency
    //  trees, and CLAUDE.md rule 4 requires a written justification for every
    //  package because every package in this app can read all of the user's
    //  notes.
    //
    //  What is actually needed is about eighty lines of the Storage Access
    //  Framework. SAF is also the *correct* API rather than merely the cheap
    //  one: it needs no storage permission at all, so the manifest stays empty,
    //  which is the strongest privacy claim this app makes. The user picks the
    //  destination in the system's own picker, and the app receives a URI it
    //  can write once and cannot enumerate.
    //
    //  Nothing here ever sees plaintext. The file being copied is already
    //  encrypted end to end by lib/core/backup/vault_file.dart before this code
    //  is called, so rule 2 is not in play on either path.
    // ─────────────────────────────────────────────────────────────────────────

    private var pendingResult: MethodChannel.Result? = null
    private var pendingPath: String? = null
    private var pendingMime: String? = null

    private lateinit var channel: MethodChannel
    private val audioPlayer = MemoryAudioPlayer()
    private var video: MemoryVideoPlayer? = null

    /**
     * ISSUE 4. Built lazily, because most sessions never open a document and a
     * HandlerThread that nothing uses is a thread that nothing uses.
     */
    private val pdf by lazy { MemoryPdf(applicationContext) }

    /**
     * The readable export. Lazy for the same reason as [pdf] — most sessions
     * never run one, and it holds no resources until [Export.begin].
     */
    private val exporter by lazy { Export(applicationContext) }

    /** The other direction: somebody's existing journal, on the way in. */
    private val importer by lazy { Import(applicationContext) }

    /**
     * One thread, for every export call. Order is the reason — see the
     * `exportBegin` case for why a pool would corrupt the output.
     */
    private val exportExecutor by lazy { Executors.newSingleThreadExecutor() }
    private var voice: VoiceCapture? = null
    private var micPermissionResult: MethodChannel.Result? = null
    private var notificationPermissionResult: MethodChannel.Result? = null
    private val biometrics by lazy { BiometricVault(this) }

    /**
     * Set while a picker, the camera or the biometric prompt has the screen.
     *
     * Leaving the app for something the app itself launched is not the user
     * walking away, and onPause must not treat it as one — see the note there.
     */
    private var inSystemExcursion = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        VoiceCapture.appContext = applicationContext

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result -> onMethodCall(call, result) }
        video = MemoryVideoPlayer(flutterEngine.renderer)

        val capture = VoiceCapture { message ->
            VoiceCapture.mainHandler.post {
                channel.invokeMethod("recordingFailed", message)
            }
        }
        voice = capture
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
            .setStreamHandler(capture)
    }

    /**
     * Everything that makes a noise stops when the app stops being on screen.
     *
     * ── WHY THIS IS HERE AND NOT ONLY IN DART ──────────────────────────────
     *
     * Reported as "if I am listening to the audio and I close the app, the
     * audio plays for a few seconds". It did, and the reason is a race the Dart
     * side cannot win: `AppLifecycleState.paused` arrives over a message
     * channel, and the channel is serviced by the same isolate that has just
     * been descheduled because the app went to the background. So the message
     * lands whenever Android next feels like running us — which is a few
     * hundred milliseconds later, and sometimes seconds.
     *
     * `onPause` runs synchronously, on the main thread, before the window is
     * gone. Stopping here means the sound ends when the screen does.
     *
     * It matters more than it sounds. A voice note is somebody talking about
     * their day, and it continuing to play out loud after they have put the
     * phone down — in a room, on a bus — is the app leaking the exact thing it
     * exists to keep. This is a privacy fix wearing a polish fix's clothes.
     *
     * The excursion flag is the one exception: launching the camera or a file
     * picker also pauses us, and killing playback because the user tapped
     * "attach a photo" would be its own small bug.
     */
    override fun onPause() {
        if (!inSystemExcursion) {
            audioPlayer.pause()
            video?.pause()
        }
        super.onPause()
    }

    /**
     * The launcher icon is swapped here, and nowhere else. **ISSUE A.**
     *
     * *"Whenever the icon colour or dark mode light mode is done I get out of
     * the app"*, and before that *"whenever a theme is changed the app is
     * closed — feels like an crash. Stop this."*
     *
     * Changing the icon means disabling one `activity-alias` and enabling
     * another, and the alias being disabled is the one **this task was launched
     * from**. Android responds by finishing the task. `DONT_KILL_APP` was
     * already set and does not help: it spares the process, not the task, which
     * is why the app vanished without ever actually crashing.
     *
     * `onStop` is the first moment the user is no longer looking. By the time
     * this runs the vault has already locked and destroyed its keys, so a task
     * that goes away takes nothing with it — the recents entry was a lock
     * screen. See IconSwitcher for the rest of the reasoning.
     *
     * **The excursion guard is not optional.** A full-screen camera or file
     * picker stops this activity too, and finishing the task at that moment
     * would mean the user never gets back to the app that launched it — the
     * photograph they just took would go nowhere. That is a worse version of
     * the bug being fixed, so the swap waits for a stop that means the user
     * actually left. `onPause` uses the same flag for the same reason.
     */
    override fun onStop() {
        if (!inSystemExcursion) IconSwitcher.applyPending(applicationContext)
        super.onStop()
    }

    override fun onDestroy() {
        // A recording still running when the activity goes would keep the
        // microphone open with nothing listening. Stop before anything else.
        //
        // ROUND EIGHT, ISSUE 5B: `release`, not `cancel`. `cancel` calls
        // `stop`, and `stop` can throw on a recorder that never captured
        // anything — which would abandon the microphone in exactly the state
        // that made every later recording fail. `release` promises nothing and
        // throws nothing; the only thing it guarantees is that the microphone
        // is not still held when it returns.
        voice?.release()
        // The screen was being kept awake for a recording that is now over.
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        audioPlayer.stop()
        video?.release()
        video = null
        // The decrypted document leaves with the activity. It is the user's
        // own papers sitting in RAM, and it has no business outliving the
        // screen that was showing it.
        pdf.close()
        // An export interrupted by the activity going away takes its own
        // half-written folder with it. `abort` does nothing once `finish` has
        // run, so a completed export is never touched by this — only one that
        // was still in progress when the user left.
        exporter.abort()
        // The scanned list is a set of handles on the user's own storage. It
        // has no reason to outlive the screen that was using it.
        importer.clear()
        super.onDestroy()
    }

    /**
     * The calls that hand the screen to another app and wait for it back.
     *
     * Only these are refused while one is already running. The guard used to
     * cover **every** method, which meant that while a photo picker was open
     * the scrubber could not read the playback position and the video player
     * could not be closed — both of which answered "busy" and left a screen
     * stuck. The rule was right; its scope was not.
     */
    private val excursions = setOf(
        "exportFile", "importFile", "capturePhoto", "pickImage",
        "pickDocument", "pickBackupFolder"
    )

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        // One at a time. A second picker launched over the first would leave
        // the first Result never answered, and a Dart future that never
        // completes is a screen that spins forever with no error to show.
        if (call.method in excursions) {
            if (pendingResult != null) {
                result.error("busy", "Something else is already open.", null)
                return
            }
            // Tell onPause this is us, not the user leaving.
            inSystemExcursion = true
        }

        when (call.method) {
            "exportFile" -> {
                val path = call.argument<String>("path")
                val name = call.argument<String>("name")
                if (path == null || name == null) {
                    result.error("bad_args", "path and name are required.", null)
                    return
                }
                if (!File(path).exists()) {
                    result.error("missing", "There is no file at $path.", null)
                    return
                }
                pendingResult = result
                pendingPath = path
                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    // Deliberately generic. A registered MIME type for .vault
                    // would tell every app on the phone that this file is a
                    // Lamplight vault; octet-stream tells them nothing.
                    type = "application/octet-stream"
                    putExtra(Intent.EXTRA_TITLE, name)
                }
                startActivityForResult(intent, REQUEST_EXPORT)
            }

            "importFile" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("bad_args", "path is required.", null)
                    return
                }
                pendingResult = result
                pendingPath = path
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    // Everything, because .vault has no registered type and a
                    // narrower filter would hide the user's own backup from
                    // them in the picker.
                    type = "*/*"
                }
                startActivityForResult(intent, REQUEST_IMPORT)
            }

            // ── Photos and documents ─────────────────────────────────────────
            //
            // All three cost nothing in the manifest. The camera is opened by
            // the *camera app*, which holds the CAMERA permission; we hand it
            // somewhere to write. The two pickers are the Storage Access
            // Framework, where the user choosing a file IS the grant. The
            // manifest stays free of storage and camera permissions, and
            // tool/verify_no_internet.sh keeps proving there is no INTERNET.
            "capturePhoto" -> {
                val target = tempFile("jpg")
                pendingResult = result
                pendingPath = target.absolutePath
                pendingMime = "image/jpeg"
                // A content:// URI through our own FileProvider, granted to the
                // camera app for this one write. Passing a file:// URI would
                // throw FileUriExposedException on any modern Android.
                val uri = FileProvider.getUriForFile(
                    this, "$packageName.captures", target
                )
                val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                    putExtra(MediaStore.EXTRA_OUTPUT, uri)
                    addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                }
                if (intent.resolveActivity(packageManager) == null) {
                    pendingResult = null
                    pendingPath = null
                    result.error("no_camera", "This phone has no camera app.", null)
                } else {
                    startActivityForResult(intent, REQUEST_CAMERA)
                }
            }

            // ── Choosing a photo should look like choosing a photo ───────────
            //
            // This used to be ACTION_OPEN_DOCUMENT with an image/* filter,
            // which opens the Storage Access Framework's *file browser* — a
            // list of folders with names and dates. It is technically a way to
            // choose an image and it is nothing like what anyone means by "pick
            // a photo". Every app people actually use shows a grid of their
            // pictures.
            //
            // ACTION_PICK_IMAGES is Android's own photo picker: a real gallery
            // grid, and — the part that matters here — it still needs **no
            // permission at all**, because the user selecting a picture is the
            // grant. It arrived in Android 13 and is backported to 11 and 12 on
            // most devices through a system module, so `resolveActivity` is the
            // honest test rather than a version number.
            //
            // Below that, ACTION_PICK against the media store also opens the
            // gallery app rather than a file browser. SAF is the last resort,
            // and only because a picker that fails is worse than an ugly one.
            "pickImage" -> {
                pendingResult = result
                pendingPath = cacheDirFor()
                pendingMime = null

                // **Many at a time.** Picking one photo, returning, and tapping
                // the button again is the wrong unit of work — nobody has one
                // photo of an afternoon. EXTRA_PICK_IMAGES_MAX opens the picker
                // in its multi-select mode; the two fallbacks use the older
                // EXTRA_ALLOW_MULTIPLE for the same effect.
                val photoPicker = Intent(MediaStore.ACTION_PICK_IMAGES).apply {
                    putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, MAX_AT_ONCE)
                    // Video too. A phone's gallery does not separate them and
                    // neither should we — see the video handling below.
                    type = "*/*"
                    putExtra(
                        Intent.EXTRA_MIME_TYPES, arrayOf("image/*", "video/*")
                    )
                }
                val gallery = Intent(Intent.ACTION_PICK).apply {
                    setDataAndType(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image/*"
                    )
                    putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                }
                val browser = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "*/*"
                    putExtra(
                        Intent.EXTRA_MIME_TYPES, arrayOf("image/*", "video/*")
                    )
                    putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                }

                val intent = when {
                    photoPicker.resolveActivity(packageManager) != null -> photoPicker
                    gallery.resolveActivity(packageManager) != null -> gallery
                    else -> browser
                }
                startActivityForResult(intent, REQUEST_PICK_IMAGE)
            }

            /**
             * Hands a URL to the browser.
             *
             * No INTERNET permission is involved and none is needed: we are not
             * opening a socket, we are asking Android to give the address to
             * whichever app handles the web. `tool/verify_no_internet.sh` still
             * passes, which is the point — the app still cannot reach the
             * network itself, it can only ask the system to.
             */
            "openUrl" -> {
                val url = call.argument<String>("url")
                if (url == null) {
                    result.error("bad_args", "url is required.", null)
                    return
                }
                try {
                    startActivity(
                        Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                    result.success(true)
                } catch (e: Exception) {
                    result.error("no_browser", "No app can open that link.", null)
                }
            }

            // Documents stay on SAF, and that is not a compromise: the system
            // file picker IS what every app shows for "choose a document", and
            // it is the only one that can reach Drive, Dropbox and the rest
            // through their document providers. What it was missing is a hint
            // about what we can take.
            "pickDocument" -> {
                pendingResult = result
                pendingPath = cacheDirFor()
                pendingMime = null
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                    type = "*/*"
                    // Puts the common kinds at the top of the picker's own
                    // filter, without preventing anything else being chosen.
                    putExtra(
                        Intent.EXTRA_MIME_TYPES,
                        arrayOf(
                            "application/pdf",
                            "image/*",
                            "audio/*",
                            "video/*",
                            "text/*",
                            "application/msword",
                            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                            "application/vnd.ms-excel",
                            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                            "*/*"
                        )
                    )
                }
                startActivityForResult(intent, REQUEST_PICK_DOC)
            }

            // ── The folder automatic backups go into ─────────────────────────
            //
            // ACTION_OPEN_DOCUMENT_TREE plus takePersistableUriPermission is
            // what lets a backup run months later without asking again. It is
            // still not a storage permission: it is one folder the user chose,
            // it appears in the system's own list of granted folders, and it
            // can be revoked there like anything else.
            /*
             * ══ THE DOOR ANDROID CANNOT CLOSE ═══════════════════════════════
             *
             * 3 September 2026. He hit *"Can't use this folder -- to protect
             * your privacy, choose another folder"* again, this time on the
             * journal importer, and asked for it to be fixed rather than
             * explained.
             *
             * It cannot be fixed where it happens. That sentence is
             * DocumentsUI's, shown inside Android's own picker, before
             * anything returns here; Android 11 and later will not hand any
             * app the root of internal storage, an SD-card root, or
             * **Downloads**, which is precisely where a journal exported by
             * another app arrives. Round fifteen fixed the grant flags, round
             * sixteen added `EXTRA_INITIAL_URI`, and he was still looking at
             * the same wall -- because a hint cannot fix a restriction.
             *
             * So this stops asking for the folder. `ACTION_OPEN_DOCUMENT`
             * asks for the **files**, and it is never refused: the user picks
             * exactly which ones, the grant is per file rather than a standing
             * key to a directory, and it works in Downloads, at the root, on
             * an SD card, and on a cloud provider with no folder to give.
             *
             * Which is the same move automatic backup made the day before, in
             * the other direction: **stop asking Android for something it is
             * entitled to refuse.** The folder route stays, because for a real
             * journal folder it is far less tapping -- this is the way through
             * when that way is barred, not a replacement for it.
             *
             * The MIME list is advice rather than a filter: providers
             * disagree about what a Markdown file is, so a wide list is asked
             * for and everything is let through it, and `Import.adopt` then
             * applies the same name test the folder walk uses. Both doors
             * admit exactly the same things.
             */
            "pickTextFiles" -> {
                pendingResult = result
                pendingPath = ""
                try {
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                        putExtra(
                            Intent.EXTRA_MIME_TYPES,
                            arrayOf("text/*", "application/octet-stream", "*/*")
                        )
                        putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    inSystemExcursion = true
                    startActivityForResult(intent, REQUEST_TEXT_FILES)
                } catch (e: Exception) {
                    pendingResult = null
                    pendingPath = null
                    inSystemExcursion = false
                    result.error(
                        "no_picker",
                        "This phone has no app for choosing files.",
                        null
                    )
                }
            }

            "pickBackupFolder" -> {
                pendingResult = result
                pendingPath = ""
                // ── ISSUE 2 — a launch that throws must not jam the app ─────
                //
                // `startActivityForResult` can throw ActivityNotFoundException
                // on a device with no document provider, and on some OEM builds
                // SecurityException. The old code let it propagate with
                // `pendingResult` already set, which is the worst of both: the
                // Dart future never completes, so the screen waits for ever,
                // **and** the `excursions` guard at the top of this method
                // answers "busy" to every picker, camera and file chooser for
                // the rest of the process. One failed tap and the whole app
                // stops being able to import anything.
                try {
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)

                    /*
                     * ══ "CAN'T USE THIS FOLDER — TO PROTECT YOUR PRIVACY,
                     *    CHOOSE ANOTHER FOLDER" ═══════════════════════════
                     *
                     * 1 September 2026, and this one is not our sentence. It
                     * is DocumentsUI's own, shown inside the picker, before
                     * anything comes back here — which is why round fifteen's
                     * fix to the grant flags below was correct and did not
                     * help: the refusal happens a step earlier than the code
                     * that was fixed.
                     *
                     * On Android 11 and above the system refuses to hand any
                     * app a tree for:
                     *
                     *   · the root of internal storage
                     *   · the root of an SD card
                     *   · the Download directory
                     *
                     * No permission, target SDK or flag changes that, and the
                     * app never learns it happened — the person stays in the
                     * picker looking at a message we did not write.
                     *
                     * The reason it hits every time is where the picker opens.
                     * Left to itself it lands on the last place used or on
                     * Downloads, so somebody following "choose a folder to
                     * keep copies in" walks straight into one of the three
                     * refused ones. **Creating a new folder there does not
                     * help either**, and that is worth writing down because it
                     * is the part that looks like a bug: DocumentsUI's "use
                     * this folder" applies to the directory you are *standing
                     * in*, not the one you just made, so making "Lamplight"
                     * inside Downloads and tapping the button still offers
                     * Downloads, and is still refused.
                     *
                     * So it opens in Documents, which is allowed. The person
                     * can still navigate anywhere they like; they simply start
                     * somewhere that works instead of somewhere that cannot.
                     *
                     * EXTRA_INITIAL_URI is API 26+, and a hint in every sense
                     * — a provider free to ignore it. Wrapped because building
                     * the URI touches a provider authority that a heavily
                     * modified OEM build need not have.
                     */
                    //
                    // ── AND IT IS ONLY A HINT. 2 SEPTEMBER 2026 ─────────────
                    //
                    // He sent a photograph of the picker sitting at the root of
                    // internal storage, on `versionCode=12`, which already had
                    // the line below. So either the provider ignored the hint
                    // — which it is entitled to do, the specification calls it
                    // a hint — or he tapped the navigation drawer and went to
                    // the root himself, which is a perfectly reasonable thing
                    // to do when an app asks you to choose a folder.
                    //
                    // Both readings lead to the same conclusion and it is worth
                    // writing down plainly: **an initial location cannot fix a
                    // refusal.** It decides where the picker opens and nothing
                    // else; one tap moves away from it, and the refusal is
                    // Android's, shown in Android's own UI.
                    //
                    // Which is why automatic backup no longer comes through
                    // here at all — see `BackupFolder.kt`. What is left needing
                    // a tree is the readable export and the journal importer,
                    // both of which genuinely read or write many files, and for
                    // those this is still worth sending.
                    //
                    // A tree URI as well as a document one, because
                    // `ACTION_OPEN_DOCUMENT_TREE` deals in trees and different
                    // Android versions have honoured different forms of this
                    // extra. Whichever the provider understands, it starts
                    // somewhere that can actually be chosen.
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        runCatching {
                            intent.putExtra(
                                DocumentsContract.EXTRA_INITIAL_URI,
                                DocumentsContract.buildTreeDocumentUri(
                                    "com.android.externalstorage.documents",
                                    "primary:Documents"
                                )
                            )
                        }
                    }
                    startActivityForResult(intent, REQUEST_TREE)
                } catch (e: Exception) {
                    pendingResult = null
                    pendingPath = null
                    inSystemExcursion = false
                    result.error(
                        "no_picker",
                        "This phone has no app for choosing a folder.",
                        null
                    )
                }
            }

            "writeIntoFolder" -> {
                val tree = call.argument<String>("tree")
                val path = call.argument<String>("path")
                val name = call.argument<String>("name")
                if (tree == null || path == null || name == null) {
                    result.error("bad_args", "tree, path and name are required.", null)
                    return
                }
                Thread {
                    val outcome = runCatching { writeIntoTree(tree, path, name) }
                    Handler(Looper.getMainLooper()).post {
                        outcome.fold(
                            onSuccess = { result.success(it) },
                            onFailure = {
                                result.error(
                                    "io",
                                    it.message ?: "The backup folder could not be written to.",
                                    null
                                )
                            }
                        )
                    }
                }.start()
            }

            // ── The backup destination that needs nothing granted ────────
            //
            // See `BackupFolder.kt`. This is the answer to "choose folder
            // doesn't work": on Android 10+ there is a place we can always
            // write, so having a backup at all no longer depends on getting
            // through a picker that is entitled to refuse.
            "defaultBackupFolderAvailable" -> result.success(BackupFolder.available)

            "defaultBackupFolderLabel" -> result.success(BackupFolder.LABEL)

            "writeIntoDefaultFolder" -> {
                val path = call.argument<String>("path")
                val name = call.argument<String>("name")
                if (path == null || name == null) {
                    result.error("bad_args", "path and name are required.", null)
                    return
                }
                // Off the main thread for the same reason `writeIntoFolder` is:
                // this copies a whole vault, and on a large one that is seconds.
                Thread {
                    val outcome = runCatching { BackupFolder.write(this, path, name) }
                    Handler(Looper.getMainLooper()).post {
                        outcome.fold(
                            onSuccess = { result.success(it) },
                            onFailure = {
                                result.error(
                                    "io",
                                    it.message ?: "The backup could not be saved.",
                                    null
                                )
                            }
                        )
                    }
                }.start()
            }

            "canWriteToFolder" -> {
                val tree = call.argument<String>("tree")
                result.success(
                    tree != null && runCatching {
                        DocumentFile.fromTreeUri(this, Uri.parse(tree))?.canWrite() == true
                    }.getOrDefault(false)
                )
            }

            // ── The readable export ──────────────────────────────────────────
            //
            // Six small calls rather than one big one, because the content is
            // decrypted on the Dart side a chunk at a time and must never be
            // assembled anywhere. See Export.kt for why that is the whole
            // design rather than an implementation detail.
            //
            // All six go through `onExport`, which runs them on ONE background
            // thread. Two properties come out of that and both are load-bearing:
            // the writes are off the UI thread, and they stay in the order Dart
            // sent them. A thread per call would get the first property and
            // lose the second, and a file written out of order is a corrupt
            // file that no test on the laptop would ever catch.
            "exportBegin" -> {
                val tree = call.argument<String>("tree")
                val name = call.argument<String>("name")
                if (tree == null || name == null) {
                    result.error("bad_args", "tree and name are required.", null)
                    return
                }
                onExport(result) { exporter.begin(tree, name) }
            }

            "exportOpen" -> {
                val path = call.argument<String>("path")
                val mime = call.argument<String>("mime")
                if (path == null || mime == null) {
                    result.error("bad_args", "path and mime are required.", null)
                    return
                }
                onExport(result) { exporter.open(path, mime); null }
            }

            "exportWrite" -> {
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null) {
                    result.error("bad_args", "bytes are required.", null)
                    return
                }
                onExport(result) { exporter.write(bytes); null }
            }

            "exportCloseFile" -> onExport(result) { exporter.closeFile(); null }

            "exportFinish" -> onExport(result) { exporter.finish(); null }

            "exportAbort" -> onExport(result) { exporter.abort(); null }

            // ── The way in ───────────────────────────────────────────────────
            //
            // Same thread as the export, for the same two reasons: reading
            // hundreds of files off an SD card has no business on the UI
            // thread, and the calls must stay in the order Dart sent them.
            "folderScan" -> {
                val tree = call.argument<String>("tree")
                if (tree == null) {
                    result.error("bad_args", "tree is required.", null)
                    return
                }
                onExport(result) { importer.scan(tree) }
            }

            "folderReadText" -> {
                val index = call.argument<Int>("index")
                if (index == null) {
                    result.error("bad_args", "index is required.", null)
                    return
                }
                onExport(result) { importer.readText(index) }
            }

            "folderForget" -> onExport(result) { importer.clear(); null }

            // ── Biometrics ───────────────────────────────────────────────────
            //
            // What crosses this channel is a 32-byte per-device secret, never
            // the vault's DEK. See BiometricVault for why that distinction is
            // worth the extra envelope.
            "biometricStatus" -> result.success(biometrics.status())

            "biometricEnrol" -> {
                val secret = call.argument<ByteArray>("secret")
                if (secret == null) {
                    result.error("bad_args", "secret is required.", null)
                    return
                }
                biometrics.enrol(
                    secret = secret,
                    title = "Set up unlocking with your fingerprint",
                    subtitle = "Your passcode still works, and is still the only way back in if this stops.",
                    onDone = { result.success(it) },
                    onError = { result.error("biometric", it, null) }
                )
            }

            "biometricUnlock" -> {
                val sealed = call.argument<String>("sealed")
                val iv = call.argument<String>("iv")
                if (sealed == null || iv == null) {
                    result.error("bad_args", "sealed and iv are required.", null)
                    return
                }
                biometrics.unlock(
                    sealedB64 = sealed,
                    ivB64 = iv,
                    title = "Unlock Lamplight",
                    subtitle = "Or use your passcode",
                    onDone = { result.success(it) },
                    onError = { result.error("biometric", it, null) }
                )
            }

            "biometricClear" -> {
                biometrics.clear()
                result.success(null)
            }

            // ── The microphone ───────────────────────────────────────────────
            "hasMicPermission" -> result.success(hasMic())

            "requestMicPermission" -> {
                if (hasMic()) {
                    result.success(true)
                } else {
                    micPermissionResult = result
                    requestPermissions(
                        arrayOf(Manifest.permission.RECORD_AUDIO), REQUEST_MIC
                    )
                }
            }

            "startRecording" -> {
                try {
                    voice?.start()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("recorder", e.message ?: "The recorder would not start.", null)
                }
            }

            "stopRecording" -> {
                try {
                    result.success(voice?.stop()?.toInt() ?: 0)
                } catch (e: Exception) {
                    result.error("recorder", e.message ?: "The recording could not be saved.", null)
                }
            }

            "cancelRecording" -> {
                voice?.cancel()
                result.success(null)
            }

            // ── ROUND EIGHT, ISSUE 5A — pause and pick it up again ───────
            //
            // "There is no voice pause button while recording!"
            //
            // Both return whether the recorder actually moved, rather than
            // null. Some devices refuse to pause, and a screen that draws a
            // paused button over a microphone that is still listening is the
            // one failure here that would matter — so the answer comes back
            // and the sheet believes it rather than believing itself.
            "pauseRecording" -> result.success(voice?.pause() ?: false)

            "resumeRecording" -> result.success(voice?.resume() ?: false)

            "isRecording" -> result.success(voice?.isRecording ?: false)

            "recordingAmplitude" -> result.success(voice?.amplitude() ?: 0.0)

            // ── Playback, from memory ────────────────────────────────────────
            "playAudio" -> {
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null) {
                    result.error("bad_args", "bytes are required.", null)
                } else {
                    try {
                        audioPlayer.play(bytes) {
                            channel.invokeMethod("audioFinished", null)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("player", e.message ?: "That could not be played.", null)
                    }
                }
            }

            "stopAudio" -> {
                audioPlayer.stop()
                result.success(null)
            }

            // ── Documents, rendered here rather than handed to another app ────
            //
            // See MemoryPdf for why this is not simply an ACTION_VIEW intent,
            // and for the one thing it costs.
            "openPdf" -> {
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null) {
                    result.error("bad_args", "bytes are required.", null)
                } else {
                    var answered = false
                    pdf.open(
                        data = bytes,
                        onReady = { pages ->
                            if (!answered) {
                                answered = true
                                // ISSUE 8. The shape of every page, measured
                                // once at open. Without it the list lays every
                                // page out as A4 and then moves it when the
                                // bitmap arrives, which is what "jerky" is —
                                // and the page number is an estimate that is
                                // only right when every page is identical.
                                result.success(
                                    mapOf(
                                        "pages" to pages,
                                        "shapes" to pdf.pageShapes.toList()
                                    )
                                )
                            }
                        },
                        onError = { message ->
                            if (!answered) {
                                answered = true
                                result.error("pdf", message, null)
                            }
                        }
                    )
                }
            }

            // ── ISSUE 4, 13 — lending a file to another app ──────────────
            //
            // See HandOff.kt for the grant, and lib/core/platform/hand_off.dart
            // for the terms rule 2 was lifted on. Both halves of the reclaim
            // live behind "revokeHandOff": the permission is taken back here,
            // and the Dart side overwrites and deletes the file.
            // ── ISSUE 16 — copying the recovery phrase ───────────────────
            //
            // Flutter's own Clipboard cannot set ClipDescription's
            // EXTRA_IS_SENSITIVE, and without it Android 13+ shows a floating
            // preview of whatever was just copied - which would put twelve
            // words that unlock the whole journal on screen over whatever app
            // the user opens next. With it the system shows dots.
            //
            // The Dart side clears it again after sixty seconds, and only if
            // the clipboard still holds what we put there. See
            // lib/core/platform/secure_clipboard.dart.
            // ── ISSUE 11 — the facts, so the app can stop shrugging ──────
            //
            // "Notifications still doesn't work - find a bulletproof way."
            //
            // When the cause is Android holding the alarm, the app has no way
            // to show that and the user cannot tell it apart from "the app is
            // broken". Every gate that can stop a reminder is reported here so
            // Settings can say which one is shut.
            "reminderHealth" -> {
                val manager = getSystemService(Context.NOTIFICATION_SERVICE)
                    as android.app.NotificationManager
                val channel = manager.getNotificationChannel(Reminders.CHANNEL_ID)
                result.success(
                    mapOf(
                        "permission" to (
                            android.os.Build.VERSION.SDK_INT < 33 ||
                                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                                android.content.pm.PackageManager.PERMISSION_GRANTED
                            ),
                        // A user can switch the app's notifications off in
                        // system settings without ever touching the app.
                        "notificationsEnabled" to manager.areNotificationsEnabled(),
                        // And can silence this one channel specifically, which
                        // looks identical from inside the app.
                        "channelEnabled" to (
                            channel == null ||
                                channel.importance != android.app.NotificationManager.IMPORTANCE_NONE
                            ),
                        "batteryRestricted" to
                            !(getSystemService(Context.POWER_SERVICE) as PowerManager)
                                .isIgnoringBatteryOptimizations(packageName),
                        "lastPostedAt" to Reminders.lastPostedAt(this),
                        "nextDueAt" to Reminders.nextDueAt(this),
                    )
                )
            }

            "copySensitive" -> {
                val text = call.argument<String>("text")
                if (text == null) {
                    result.error("bad_args", "text is required.", null)
                } else {
                    val clipboard = getSystemService(android.content.Context.CLIPBOARD_SERVICE)
                        as android.content.ClipboardManager
                    val clip = android.content.ClipData.newPlainText("", text)
                    clip.description.extras = android.os.PersistableBundle().apply {
                        putBoolean(
                            android.content.ClipDescription.EXTRA_IS_SENSITIVE,
                            true
                        )
                    }
                    clipboard.setPrimaryClip(clip)
                    result.success(true)
                }
            }

            "openWith" -> {
                val path = call.argument<String>("path")
                val mime = call.argument<String>("mime") ?: "*/*"
                if (path == null) {
                    result.error("bad_args", "path is required.", null)
                } else {
                    result.success(HandOff.open(this, path, mime))
                }
            }

            "revokeHandOff" -> {
                HandOff.revokeAll(this)
                result.success(null)
            }

            "renderPdfPage" -> {
                val page = call.argument<Int>("page") ?: 0
                val width = call.argument<Int>("width") ?: 1080
                // ISSUE 1. Four normalised numbers - left, top, right, bottom -
                // naming the slice of the page to draw, or absent for all of
                // it. See MemoryPdf.render for why zoom asks for a slice rather
                // than for the page again at a larger size.
                val region = call.argument<List<Double>>("region")
                    ?.map { it.toFloat() }
                    ?.toFloatArray()
                    ?.takeIf { it.size == 4 }
                var answered = false
                pdf.render(
                    page = page,
                    targetWidth = width,
                    region = region,
                    onDone = { w, h, pixels ->
                        if (!answered) {
                            answered = true
                            result.success(
                                mapOf("width" to w, "height" to h, "pixels" to pixels)
                            )
                        }
                    },
                    onError = { message ->
                        if (!answered) {
                            answered = true
                            result.error("pdf", message, null)
                        }
                    }
                )
            }

            "closePdf" -> {
                pdf.close()
                result.success(null)
            }

            // ISSUE 8. Runs once, at import, while the plaintext is already in
            // hand — never on the day view's frame budget. See MediaInfo.kt.
            "mediaInfo" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("bad_args", "path is required.", null)
                } else {
                    // ISSUE 2. Three kinds, not a boolean. It used to ask
                    // "poster or not", so everything that was not a video went
                    // down the still-image path - which is how an imported
                    // audio file was handed to BitmapFactory and came back
                    // with no duration and no waveform.
                    MediaInfo.read(
                        path = path,
                        kind = call.argument<String>("kind") ?: "photo",
                    ) { info -> result.success(info) }
                }
            }

            "pauseAudio" -> {
                audioPlayer.pause()
                result.success(null)
            }

            "resumeAudio" -> {
                audioPlayer.resume()
                result.success(null)
            }

            "seekAudio" -> {
                audioPlayer.seekTo(call.argument<Int>("ms") ?: 0)
                result.success(null)
            }

            "setAudioSpeed" -> {
                audioPlayer.setSpeed(
                    (call.argument<Double>("rate") ?: 1.0).toFloat()
                )
                result.success(null)
            }

            // Polled by the scrubber. Deliberately one call returning three
            // things rather than three calls: a progress bar redrawing at
            // 5 Hz should cost one channel hop, not three.
            "audioState" -> result.success(
                mapOf(
                    "position" to audioPlayer.position(),
                    "duration" to audioPlayer.duration(),
                    "playing" to audioPlayer.isPlaying
                )
            )

            // ── Video, from memory, onto a Flutter texture ───────────────────
            "openVideo" -> {
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null) {
                    result.error("bad_args", "bytes are required.", null)
                } else {
                    var answered = false
                    video?.open(
                        bytes = bytes,
                        loop = call.argument<Boolean>("loop") ?: false,
                        onReady = { id, w, h, ms ->
                            if (!answered) {
                                answered = true
                                result.success(
                                    mapOf(
                                        "textureId" to id,
                                        "width" to w,
                                        "height" to h,
                                        "duration" to ms
                                    )
                                )
                            }
                        },
                        onFinished = { channel.invokeMethod("videoFinished", null) },
                        onError = { message ->
                            if (!answered) {
                                answered = true
                                result.error("player", message, null)
                            } else {
                                channel.invokeMethod("videoFailed", message)
                            }
                        }
                    ) ?: result.error("player", "The video player is not ready.", null)
                }
            }

            "playVideo" -> {
                video?.play()
                result.success(null)
            }

            "pauseVideo" -> {
                video?.pause()
                result.success(null)
            }

            "seekVideo" -> {
                video?.seekTo(call.argument<Int>("ms") ?: 0)
                result.success(null)
            }

            "setVideoSpeed" -> {
                video?.setSpeed((call.argument<Double>("rate") ?: 1.0).toFloat())
                result.success(null)
            }

            "setVideoVolume" -> {
                video?.setVolume((call.argument<Double>("volume") ?: 1.0).toFloat())
                result.success(null)
            }

            "closeVideo" -> {
                video?.release()
                result.success(null)
            }

            "videoState" -> result.success(
                mapOf(
                    "position" to (video?.position() ?: 0),
                    "duration" to (video?.duration() ?: 0),
                    "playing" to (video?.isPlaying ?: false)
                )
            )

            // ── Reminders ────────────────────────────────────────────────────
            "notificationsAllowed" -> result.success(notificationsAllowed())

            "requestNotifications" -> {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                    // Before Android 13 there was no runtime permission — the
                    // channel is the switch, and the user owns it in system
                    // settings.
                    result.success(true)
                } else if (notificationsAllowed()) {
                    result.success(true)
                } else if (notificationPermissionResult != null) {
                    result.error("busy", "Already asking.", null)
                } else {
                    notificationPermissionResult = result
                    requestPermissions(
                        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                        REQUEST_NOTIFICATIONS
                    )
                }
            }

            "scheduleReminder" -> {
                Reminders.schedule(
                    applicationContext,
                    call.argument<Int>("minuteOfDay") ?: (21 * 60)
                )
                result.success(null)
            }

            "cancelReminder" -> {
                Reminders.cancel(applicationContext)
                result.success(null)
            }

            // Proof, on demand. A daily reminder that first arrives tomorrow
            // is a feature nobody can tell is working, and "it doesn't work"
            // is what they conclude in the meantime.
            //
            // ROUND FIVE: the button that called this is gone from Settings at
            // his request. The channel method stays, because it is what
            // `tool/` and a future diagnostic would use, and because deleting a
            // working diagnostic to satisfy a UI request is how you end up
            // unable to answer the same question next time.
            "testReminder" -> {
                Reminders.post(applicationContext)
                result.success(null)
            }

            // ── Why the reminder never arrives, ROUND FIVE ISSUE 10 ──────────
            //
            // *"Even after the time is set, notification from the app never
            // comes"* — while the test button worked. That pair is the whole
            // diagnosis: posting is fine, the alarm is not arriving.
            //
            // The cause is almost certainly not in this codebase. Both devices
            // he judges the app on are the two most aggressive vendors there
            // are — a Redmi Pad on MIUI and a Vivo on Funtouch — and both
            // freeze background alarms for apps the user has not exempted,
            // regardless of `setAndAllowWhileIdle`. An app in the "restricted"
            // standby bucket can have a daily alarm deferred past the point of
            // usefulness or dropped entirely.
            //
            // `isIgnoringBatteryOptimizations` needs **no permission** to read.
            // Only *requesting* the exemption directly needs
            // REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, which is a permission
            // Google reviews — so this reads the state and, separately, opens
            // the system's own list for the user to change it themselves. That
            // costs nothing in the manifest and puts the decision where it
            // belongs.
            "batteryRestricted" -> {
                val power = getSystemService(Context.POWER_SERVICE) as PowerManager
                result.success(!power.isIgnoringBatteryOptimizations(packageName))
            }

            // Opens the system list. ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
            // shows every app and needs no permission;
            // ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS would put up a single
            // yes/no dialog but requires the reviewed permission to do it. The
            // extra tap is worth not carrying that in the store listing.
            "openBatterySettings" -> {
                try {
                    startActivity(
                        Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                    result.success(true)
                } catch (_: Exception) {
                    // Some vendor ROMs do not ship that screen. Fall back to
                    // this app's own settings page, which every device has and
                    // which is one tap from the battery controls.
                    try {
                        startActivity(
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", packageName, null)
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
            }

            // ── Screenshots, on or off ───────────────────────────────────
            //
            // `FLAG_SECURE` is one flag doing three things: it blanks the
            // recent-apps thumbnail, it refuses screenshots and screen
            // recording, and it stops the window mirroring to a non-secure
            // external display. There is no way to keep the first and drop the
            // second — Android does not separate them — so allowing screenshots
            // means allowing all three, and the switch says so in those words.
            //
            // Applied to the live window, so it takes effect on the frame after
            // the toggle rather than at the next launch. `recreate()` would
            // also work and would throw away the whole Flutter engine, the
            // unlocked vault with it.
            "setScreenSecurity" -> {
                // The sandbox never re-arms it. See the note in `onCreate`:
                // that guard is undone within a frame by this one, because a
                // fresh vault has `allowScreenshots` off, so both have to know
                // about the sandbox or neither does. `...sandbox` cannot be a
                // shipped application id.
                val allowCapture =
                    packageName.endsWith(".sandbox") ||
                        (call.argument<Boolean>("allow") ?: false)
                if (allowCapture) {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            }

            // ── ROUND EIGHT, ISSUE 5B — the screen stays on while recording ──
            //
            // "IDK in first place when recording is taking place why is the app
            // sleeping? Why?"
            //
            // A fair question with a dull answer: nothing had told the phone
            // not to. `FLAG_KEEP_SCREEN_ON` is a **window flag, not a
            // permission** — it does not appear in the manifest, it cannot
            // outlive the window, and it is the same mechanism a video player
            // or a map uses. It costs nothing to the threat model and it is the
            // difference between a recording that survives being left alone for
            // a minute and one that does not.
            //
            // Held only while the recording sheet is open, and cleared by that
            // sheet's own dispose — including the dispose that happens because
            // the recording failed. A flag that outlives its reason is a phone
            // that never sleeps again.
            "keepScreenOn" -> {
                val keep = call.argument<Boolean>("on") ?: false
                if (keep) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                }
                result.success(null)
            }

            // The launcher icon follows the theme and, since ISSUE 6b, the
            // chosen accent.
            //
            // ROUND FIVE ISSUE A: this only *records* the wanted icon now. The
            // swap happens in onStop, because disabling the alias the running
            // task was launched from makes Android finish that task — which is
            // the "whenever a theme is changed the app is closed" report, and
            // which DONT_KILL_APP does not and cannot prevent. See IconSwitcher.
            "setIconTheme" -> {
                // `this`, not `applicationContext`. The launcher swap that is
                // deferred to `onStop` only needs a Context — but `request`
                // also sets the **task description** now, which is what the
                // recents switcher draws, and that is a property of the
                // running Activity. An application context would have been
                // cast away silently and the icon would have gone on changing
                // only at the launcher.
                IconSwitcher.request(
                    this,
                    call.argument<String>("accent") ?: "amber",
                    call.argument<Boolean>("light") ?: false
                )
                result.success(null)
            }

            // ── Things other apps handed us. ISSUE 13 ────────────────────────
            //
            // Asked for only after the vault is open. `takeShared` copies the
            // shared files into private cache and clears the parked intent, so
            // it is safe to call at any time and returns nothing when there is
            // nothing waiting.
            "hasShared" -> result.success(Sharing.hasPending)

            "takeShared" -> result.success(Sharing.take(applicationContext))

            // ── Making a video smaller on the way in. ISSUE 3 + 4 ────────────
            //
            // Off the main thread, because a minute of 1080p is several seconds
            // of work and this is called while the user is watching an import
            // progress bar. Returns the new path, or null meaning "keep the
            // original" — a failed compression must never cost somebody their
            // video. See Transcode.
            "compressVideo" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("bad_args", "path is required.", null)
                    return
                }
                // ISSUE 2A. Defaulted rather than required, so an older Dart
                // side calling without it gets exactly what it used to get.
                val quality = call.argument<String>("quality") ?: "balanced"
                Thread {
                    // ISSUE 10. The reason travels with the answer now. A dozen
                    // separate ways of declining all used to come back as the
                    // same null, so the app asked him a question, he answered
                    // it, and then nothing happened and nothing was said.
                    val out = runCatching { Transcode.video(File(path), quality) }
                        .getOrDefault(null to Transcode.REASON_CANNOT)
                    Handler(Looper.getMainLooper()).post {
                        result.success(
                            mapOf(
                                "path" to out.first?.absolutePath,
                                "reason" to out.second
                            )
                        )
                    }
                }.start()
            }

            // ── Making a photograph smaller on the way in. ISSUE 2 ───────────
            "compressPhoto" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("bad_args", "path is required.", null)
                    return
                }
                val quality = call.argument<String>("quality") ?: "balanced"
                Thread {
                    val out =
                        runCatching { Transcode.photo(File(path), quality) }.getOrNull()
                    Handler(Looper.getMainLooper()).post {
                        result.success(out?.absolutePath)
                    }
                }.start()
            }

            // ── What this phone looks like ───────────────────────────────────
            "integrityCheck" -> result.success(Integrity.check(applicationContext))

            // ── The image formats Skia will not read ─────────────────────────
            //
            // Called only after Flutter's own decoder has refused, so this
            // never runs for an ordinary JPEG. See ImageFallback.
            "decodeImage" -> {
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null) {
                    result.error("bad_args", "bytes are required.", null)
                } else {
                    ImageFallback.decode(
                        bytes = bytes,
                        maxDimension = call.argument<Int>("maxDimension") ?: 2048,
                        onDone = { w, h, pixels ->
                            result.success(
                                mapOf("width" to w, "height" to h, "pixels" to pixels)
                            )
                        },
                        onError = { message -> result.error("decode", message, null) }
                    )
                }
            }

            // ── Tall pictures, read a screenful at a time ────────────────────
            //
            // ISSUE IMPORTANT, and his correction to it: *"nah I want you to
            // make it possible to view tall screenshots too!"* The whole
            // argument is on `ImageFallback.decodeRegion`. In one line: memory
            // bounded by the screen instead of by the picture, so a very tall
            // screenshot is both safe and readable rather than one or the
            // other.
            "measureImage" -> {
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null) {
                    result.error("bad_args", "bytes are required.", null)
                } else {
                    ImageFallback.measure(
                        bytes = bytes,
                        onDone = { w, h -> result.success(mapOf("width" to w, "height" to h)) },
                        onError = { message -> result.error("measure", message, null) }
                    )
                }
            }

            "decodeImageRegion" -> {
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null) {
                    result.error("bad_args", "bytes are required.", null)
                } else {
                    ImageFallback.decodeRegion(
                        bytes = bytes,
                        left = call.argument<Int>("left") ?: 0,
                        top = call.argument<Int>("top") ?: 0,
                        right = call.argument<Int>("right") ?: 0,
                        bottom = call.argument<Int>("bottom") ?: 0,
                        sample = call.argument<Int>("sample") ?: 1,
                        onDone = { w, h, pixels ->
                            result.success(
                                mapOf("width" to w, "height" to h, "pixels" to pixels)
                            )
                        },
                        onError = { message -> result.error("decode", message, null) }
                    )
                }
            }

            // ── Writing down what was said, on this phone only ───────────────
            //
            // ISSUE 15. The whole argument, including the one API name that
            // must never be changed, is on `Transcribe`.
            "transcribeAvailable" -> result.success(Transcribe.available(applicationContext))

            "transcribeLanguages" -> Transcribe.languages(
                applicationContext,
                onDone = { installed, supported ->
                    result.success(
                        mapOf("installed" to installed, "supported" to supported)
                    )
                },
                onError = { message -> result.error("languages", message, null) }
            )

            "transcribeFetchLanguage" -> {
                val tag = call.argument<String>("language")
                if (tag == null) {
                    result.error("bad_args", "A language is required.", null)
                } else {
                    Transcribe.fetchLanguage(applicationContext, tag) { ok ->
                        result.success(ok)
                    }
                }
            }

            "transcribe" -> {
                val bytes = call.argument<ByteArray>("bytes")
                val language = call.argument<String>("language")
                if (bytes == null || language == null) {
                    result.error("bad_args", "Sound and a language are required.", null)
                } else {
                    Transcribe.run(
                        context = applicationContext,
                        aac = bytes,
                        languageTag = language,
                        onDone = { text -> result.success(text) },
                        onError = { message -> result.error("transcribe", message, null) }
                    )
                }
            }

            "transcribeDefaultLanguage" -> result.success(Transcribe.defaultLanguage())

            // ── THERE IS NO WHISPER CHANNEL ANY MORE ────────────────────────
            //
            // `whisperState`, `whisperInspect`, `whisperForget` and
            // `whisperTranscribe` lived here, over a vendored whisper.cpp in
            // `src/main/cpp/`. All of it was removed on 28 August 2026 —
            // *"remove this whisper option please ... cause it's trash"*.
            //
            // Two things went with it that are worth noting rather than just
            // deleting. The project has **no native code** now, which was the
            // largest test `CLAUDE.md` rule 4 had ever been given. And the
            // model importer is gone: a ~500 MB file chosen from the user's
            // own storage and parsed by C++ was by a wide margin the widest
            // inlet this app had.
            //
            // `Transcribe.kt` is the only recogniser now, and the test that
            // reads this Kotlin and fails on a networked fallback still
            // applies to it.

            else -> result.notImplemented()
        }
    }

    private fun hasMic(): Boolean =
        checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED

    private fun notificationsAllowed(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            true
        }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode == REQUEST_MIC) {
            val result = micPermissionResult
            micPermissionResult = null
            result?.success(
                grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            )
            return
        }
        if (requestCode == REQUEST_NOTIFICATIONS) {
            val result = notificationPermissionResult
            notificationPermissionResult = null
            result?.success(
                grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            )
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    /**
     * A scratch file in the app's private cache.
     *
     * The plaintext window. Whatever lands here is the user's content in the
     * clear, and Dart's AttachmentImporter encrypts it and then overwrites and
     * deletes it — see CapturedFile.scrub. It is app-private for its whole
     * short life: no other app can read it and it is not in any shared media
     * store, which is why no storage permission is needed to write it.
     */
    private fun tempFile(extension: String): File {
        val dir = File(cacheDir, "captures").apply { mkdirs() }
        return File(dir, "capture-${System.nanoTime()}.$extension")
    }

    /** The scratch directory a multi-select writes into. */
    private fun cacheDirFor(): String =
        File(cacheDir, "captures").apply { mkdirs() }.absolutePath

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        val ours = requestCode in setOf(
            REQUEST_EXPORT, REQUEST_IMPORT, REQUEST_CAMERA,
            REQUEST_PICK_IMAGE, REQUEST_PICK_DOC, REQUEST_TREE,
            REQUEST_TEXT_FILES
        )
        if (!ours) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        // Whatever we sent them to has come back. From this moment leaving the
        // app is the user leaving again, and playback should stop with it.
        inSystemExcursion = false

        val result = pendingResult
        val path = pendingPath
        val forcedMime = pendingMime
        pendingResult = null
        pendingPath = null
        pendingMime = null
        if (result == null || path == null) return

        // The camera writes into the file we gave it, so there is no URI in the
        // result to copy from — the work is already done.
        if (requestCode == REQUEST_CAMERA) {
            val file = File(path)
            if (resultCode != Activity.RESULT_OK || !file.exists() || file.length() == 0L) {
                // Backed out, or the camera app wrote nothing. Either way there
                // must be no zero-byte plaintext file left behind.
                file.delete()
                result.success(null)
                return
            }
            result.success(
                mapOf(
                    "path" to path,
                    "name" to "Photo ${stamp()}.jpg",
                    "mime" to (forcedMime ?: "image/jpeg")
                )
            )
            return
        }

        // One URI, or many. A multi-select comes back in ClipData rather than in
        // `data`, and an app that only reads `data` silently imports the first
        // photo of the twelve somebody chose.
        val uris: List<Uri> = when {
            data == null -> emptyList()
            data.clipData != null -> {
                val clip = data.clipData!!
                (0 until clip.itemCount).mapNotNull { clip.getItemAt(it).uri }
            }
            data.data != null -> listOf(data.data!!)
            else -> emptyList()
        }

        if (resultCode != Activity.RESULT_OK || uris.isEmpty()) {
            // Cancelling is not an error. Null tells Dart "the user changed
            // their mind", which is a thing people are allowed to do and should
            // not produce a red message.
            result.success(null)
            return
        }
        val uri = uris.first()

        // ── The files somebody picked for the journal importer ──────────────
        //
        // Read permission is taken for each one before anything else touches
        // them. `ACTION_OPEN_DOCUMENT` grants for the life of this task by
        // default, which would be enough -- the scan and the import both
        // happen while the screen is open -- but an import of two hundred
        // entries can outlive a rotation or a trip to the recents list, and a
        // grant that quietly lapses halfway through would abandon the second
        // half of somebody's journal with no error anybody could read.
        //
        // Persistable, not persisted: nothing is written to
        // `takePersistableUriPermission` here, because these are files being
        // read once and never again. A journal importer does not need standing
        // access to anything, and asking for it would contradict the sentence
        // this app is built on.
        if (requestCode == REQUEST_TEXT_FILES) {
            val outcome = runCatching { importer.adopt(uris.map { it.toString() }) }
            outcome.fold(
                onSuccess = { rows ->
                    if (rows.isEmpty()) {
                        // Picked, but none of them is text. Said plainly rather
                        // than returning an empty list, which the screen would
                        // draw as "0 entries found" and read as a failure of
                        // the app rather than of the choice.
                        result.error(
                            "no_text",
                            "None of those looks like a text file.",
                            null
                        )
                    } else {
                        result.success(rows)
                    }
                },
                onFailure = {
                    result.error(
                        "io",
                        it.message ?: "Those files could not be read.",
                        null
                    )
                }
            )
            return
        }

        // The two picker paths return a LIST, always — one item or twenty.
        if (requestCode == REQUEST_PICK_IMAGE || requestCode == REQUEST_PICK_DOC) {
            Thread {
                val outcome = runCatching {
                    uris.take(MAX_AT_ONCE).map { one ->
                        val target = File(path, "capture-${System.nanoTime()}.bin")
                        val name = copyIn(one, target.absolutePath)
                        mapOf(
                            "path" to target.absolutePath,
                            "name" to name,
                            "mime" to (contentResolver.getType(one)
                                ?: "application/octet-stream")
                        )
                    }
                }
                Handler(Looper.getMainLooper()).post {
                    outcome.fold(
                        onSuccess = { result.success(it) },
                        onFailure = {
                            result.error(
                                "io",
                                it.message ?: "Those files could not be copied.",
                                null
                            )
                        }
                    )
                }
            }.start()
            return
        }

        if (requestCode == REQUEST_TREE) {
            /*
             * ══ ROUND FIFTEEN, ISSUE 2 — "I AM UNABLE TO CHOOSE FOLDER" ═════
             *
             * > *"A FEATURE IS BROKEN - WHEN AUTOMATIC BACKUP IS NEEDED OR
             * > READABLE COPY OR BRING IN A OLD FOLDER - CHOOSE FOLDER OPTION
             * > IS GIVEN THAT IS BROKEN! I AM UNABLE TO CHOOSE FOLDER"*
             *
             * All three go through here, and this is what was wrong. The old
             * code asked for **READ or WRITE, hard-coded**, whatever the
             * picker had actually granted:
             *
             *     takePersistableUriPermission(
             *         uri, FLAG_GRANT_READ_URI_PERMISSION or
             *              FLAG_GRANT_WRITE_URI_PERMISSION)
             *
             * `takePersistableUriPermission` throws `SecurityException` if you
             * ask to persist a mode you were not given — *"No persistable
             * permission grants found"*. Several document providers, and MIUI's
             * in particular, hand back a tree with read only for some
             * locations. Asking for write there is not a partial success; it is
             * an exception, and the folder is not kept at all.
             *
             * The documented way is to persist **the flags that came back**,
             * which is what this does. `data.flags` carries exactly what the
             * picker granted.
             *
             * It failed silently on top of that, which is why it read as
             * nothing happening rather than as an error: the message went back
             * to Dart, and the only widget that displayed it was drawn `if
             * (on)` — that is, only once automatic backup was already working.
             * Fixed on the Dart side too.
             */
            val granted = (data?.flags ?: 0) and
                (Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION)

            // A grant of nothing at all is not something to persist. It also
            // must not be reported as success, or the app would keep a URI it
            // can never open and tell the user their backups are set up.
            if (granted == 0) {
                result.error(
                    "grant",
                    "That folder was offered without permission to use it.",
                    null
                )
                return
            }

            // Take it *persistably*, or the grant dies with this process and
            // automatic backups stop working after the first reboot — silently,
            // which is the worst way for a backup to stop working.
            try {
                contentResolver.takePersistableUriPermission(uri, granted)
            } catch (e: Exception) {
                result.error(
                    "grant",
                    e.message ?: "That folder could not be kept for later.",
                    null
                )
                return
            }

            // Whether it can be written to, answered here rather than left for
            // the first backup to discover. A read-only tree is a perfectly
            // legal answer from the picker — it is what "Bring in an old
            // journal" needs — but it is useless for a backup, and finding
            // that out weeks later when the first automatic backup fails is
            // exactly the "silently stopped working" this whole path exists to
            // avoid.
            val writable = runCatching {
                DocumentFile.fromTreeUri(this, uri)?.canWrite() == true
            }.getOrDefault(false)

            result.success(mapOf("uri" to uri.toString(), "writable" to writable))
            return
        }

        // Off the main thread: a 1 GB vault copied inline would freeze the UI
        // long enough for Android to offer to kill the app.
        Thread {
            val outcome: Result<Any> = runCatching {
                when (requestCode) {
                    REQUEST_EXPORT -> copyOut(path, uri)
                    else -> copyIn(uri, path)
                }
            }
            Handler(Looper.getMainLooper()).post {
                outcome.fold(
                    onSuccess = { result.success(it) },
                    onFailure = { result.error("io", it.message ?: "The file could not be copied.", null) }
                )
            }
        }.start()
    }

    /**
     * Copies a file into a folder the user granted with pickBackupFolder.
     *
     * `createFile` does not overwrite on a name clash — Android appends " (1)"
     * — so two backups on the same day sit side by side. UX-FLOWS.md flow 5
     * calls a corrupt overwrite of your only backup the worst outcome in the
     * entire app, and letting the platform's own behaviour prevent it is the
     * cheapest defence available.
     */
    /**
     * Writes the backup into the user's folder as **one file that is replaced**.
     *
     * ══ ROUND FIVE, ISSUE B ══════════════════════════════════════════════
     *
     * *"It does backup every time — so I open the app twice a day, two backups
     * a day; if I open thrice, do three changes, three backups a day. What I
     * want? There is a backup file which gets overwritten every time a backup
     * is done. Just a single backup file which always gets overwritten. Find a
     * way that it never crashes."*
     *
     * The old behaviour was one file per *day*, and within a day Android's
     * document provider does not overwrite on a name clash — it appends, so a
     * busy day left `Lamplight-2026-08-19 (1).vault`, `(2)`, `(3)`. Over a
     * month of ordinary use that is a folder nobody can read and a phone slowly
     * filling with near-identical encrypted copies.
     *
     * ── "Find a way that it never crashes", which is the hard half ────────
     *
     * The obvious implementation is to truncate the existing file and stream
     * the new backup over it. That is a genuine single file and it is exactly
     * the thing not to do: interrupt it — battery, a kill, the folder going
     * away mid-write — and the one backup that existed is now half a file, and
     * the good copy it replaced is gone. `UX-FLOWS.md` flow 5 calls replacing
     * the one good copy with a bad one the worst outcome in the entire app.
     *
     * So: write beside it, then swap.
     *
     *   1. any stale `.part` from a previous interrupted run is deleted;
     *   2. the new backup is streamed to `Lamplight.vault.part`;
     *   3. **only once that has finished**, the old `Lamplight.vault` is
     *      deleted and the `.part` is renamed over it.
     *
     * At every instant during that there is at least one complete, verified
     * backup in the folder. The end state is one file with the right name,
     * which is what he asked for. The transient `.part` exists only while a
     * backup is actually being written, which on his device is seconds.
     *
     * The one remaining window is between the delete in step 3 and the rename,
     * which is two document-provider calls with nothing in between. If a run
     * dies exactly there, the folder holds a complete backup called
     * `Lamplight.vault.part` and no `Lamplight.vault` — so [recoverPart] runs
     * first on the next attempt and puts it back. Nothing is ever lost, and no
     * state needs explaining to the user.
     */
    private fun writeIntoTree(tree: String, path: String, name: String): String {
        val folder = DocumentFile.fromTreeUri(this, Uri.parse(tree))
            ?: throw IllegalStateException("That backup folder is no longer available.")
        if (!folder.canWrite()) {
            throw IllegalStateException(
                "Lamplight can no longer write to that backup folder. Choose it again in Settings."
            )
        }

        val partName = "$name.part"

        // A backup interrupted between the delete and the rename last time.
        recoverPart(folder, name, partName)

        // Any other stale part is a failed write and is worth nothing.
        folder.findFile(partName)?.delete()

        val part = folder.createFile("application/octet-stream", partName)
            ?: throw IllegalStateException("The backup file could not be created.")

        // Whatever the provider actually called it. Asking for "x.vault.part"
        // can come back as "x.vault (1).part" if something raced us, and the
        // rename below has to act on the file that was really written.
        try {
            contentResolver.openOutputStream(part.uri)?.use { out ->
                File(path).inputStream().use { input -> input.copyTo(out) }
            } ?: throw IllegalStateException("The backup file could not be written.")
        } catch (e: Throwable) {
            // A half-written part must not be left to be mistaken for a
            // recoverable one by the next run.
            runCatching { part.delete() }
            throw e
        }

        // The new copy is complete on disk. Only now does the old one go.
        folder.findFile(name)?.delete()

        val renamed = runCatching { part.renameTo(name) }.getOrDefault(false)
        if (!renamed) {
            // Some providers refuse renameTo. The backup is still safe — it is
            // the .part file, and it is complete — so say what it is called
            // rather than pretending the name is the one that was asked for.
            return part.name ?: partName
        }
        return name
    }

    /**
     * Puts back a backup left as `.part` by a run that died mid-swap.
     *
     * Only ever acts when there is a part **and** no real file, which is
     * precisely the interrupted-swap state. If both exist the part is a failed
     * write and the caller deletes it.
     */
    private fun recoverPart(folder: DocumentFile, name: String, partName: String) {
        val part = folder.findFile(partName) ?: return
        if (folder.findFile(name) != null) return
        if (part.length() <= 0L) return
        runCatching { part.renameTo(name) }
    }

    /** A timestamp for a camera photo's name in the vault. */
    private fun stamp(): String = java.text.SimpleDateFormat(
        "yyyy-MM-dd HH.mm.ss", java.util.Locale.US
    ).format(java.util.Date())

    /** App-private file → the location the user picked. Returns its name. */
    private fun copyOut(path: String, uri: Uri): String {
        contentResolver.openOutputStream(uri)?.use { out ->
            File(path).inputStream().use { input -> input.copyTo(out) }
        } ?: throw IllegalStateException("That location could not be written to.")
        return displayName(uri)
    }

    /** The file the user picked → app-private storage. Returns its name. */
    private fun copyIn(uri: Uri, path: String): String {
        val destination = File(path)
        destination.parentFile?.mkdirs()
        contentResolver.openInputStream(uri)?.use { input ->
            destination.outputStream().use { out -> input.copyTo(out) }
        } ?: throw IllegalStateException("That file could not be read.")
        return displayName(uri)
    }

    private fun displayName(uri: Uri): String {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val column = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (column >= 0) return cursor.getString(column)
                }
            }
        return uri.lastPathSegment ?: "file"
    }

    /**
     * Runs one export step on the export thread and answers on the main one.
     *
     * A failure comes back as a single `export` error carrying the message,
     * because Dart's job on any of these is the same: stop, abort, and tell the
     * user one sentence. Test 6 — the user must never see internal vocabulary —
     * is why there is no error code taxonomy here for a screen to decode.
     */
    private fun onExport(result: MethodChannel.Result, work: () -> Any?) {
        exportExecutor.execute {
            val outcome = runCatching(work)
            Handler(Looper.getMainLooper()).post {
                outcome.fold(
                    onSuccess = { result.success(it) },
                    onFailure = {
                        result.error(
                            "export",
                            it.message ?: "The export could not be written.",
                            null
                        )
                    }
                )
            }
        }
    }

    companion object {
        private const val CHANNEL = "lamplight/documents"
        private const val REQUEST_EXPORT = 4711
        private const val REQUEST_IMPORT = 4712
        private const val REQUEST_CAMERA = 4713
        private const val REQUEST_PICK_IMAGE = 4714
        private const val REQUEST_PICK_DOC = 4715
        private const val REQUEST_MIC = 4716
        private const val REQUEST_TREE = 4717

        /**
         * Picking the journal's files themselves, rather than the folder
         * that holds them. See `pickTextFiles` for why there are two doors.
         */
        private const val REQUEST_TEXT_FILES = 4719
        private const val REQUEST_NOTIFICATIONS = 4718
        private const val AUDIO_CHANNEL = "lamplight/audio"

        /**
         * How many files one pick may bring in.
         *
         * Not unlimited. Every one is copied to the cache in the clear before
         * it is encrypted, so a hundred at once would mean a hundred plaintext
         * files alive at the same moment — a much wider window than the one the
         * scrubbing is designed around. Twenty is more than anyone selects in
         * one go and keeps that window small.
         */
        private const val MAX_AT_ONCE = 20
    }
}
