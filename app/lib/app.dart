import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/generated/app_localizations.dart';

import 'core/db/entry_repository.dart';
import 'core/platform/app_icon.dart';
import 'core/platform/hand_off.dart';
import 'core/platform/secure_clipboard.dart';
import 'core/platform/pdf_render.dart';
import 'core/platform/screen_security.dart';
import 'core/platform/voice_playback.dart';
import 'core/reminders/reminders.dart';
import 'core/settings/app_settings.dart';
import 'core/storage/orphan_sweep.dart';
import 'core/storage/attachment_importer.dart';
import 'core/vault/vault.dart';
import 'design/tokens.dart';
import 'features/backup/silent_backup.dart';
import 'features/day/day_screen.dart';
import 'features/launch/opening.dart';
import 'features/lock/about_to_lock.dart';
import 'features/lock/lock_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

/// The whole app. Three states, and the vault decides which.
class LamplightApp extends StatefulWidget {
  const LamplightApp({
    super.key,
    required this.vault,
    required this.settings,
    required this.silentBackup,
  });

  final Vault vault;
  final AppSettings settings;
  final SilentBackup silentBackup;

  @override
  State<LamplightApp> createState() => _LamplightAppState();
}

class _LamplightAppState extends State<LamplightApp> with WidgetsBindingObserver {
  /// Held so the app can reach the navigator from outside the widget tree —
  /// specifically, to tear down every open screen the instant the vault locks.
  final _navigator = GlobalKey<NavigatorState>();

  /// So the lock can reach the snack bars from outside the Navigator.
  /// **ISSUE 22.**
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  VaultState? _previousState;

  /// Whether onboarding still owns the screen.
  ///
  /// **This flag is the fix for a bug that would have cost people their
  /// recovery phrase.** `Vault.create` unlocks the vault as its last act, which
  /// notifies this widget, which rebuilt `home` from the vault's state — so the
  /// screen switched to the day view the instant the vault existed, and the
  /// twelve words were disposed before they were ever drawn. They are shown
  /// exactly once and deliberately never stored, so "never drawn" means the
  /// user has no recovery phrase at all and no way to find that out until the
  /// day they need one.
  ///
  /// It was invisible because onboarding had never been run on a device. It is
  /// the sort of thing that only a person using the app finds, which is what
  /// `ROADMAP.md` means when it calls the annoyances list the most valuable
  /// document in the project.
  ///
  /// So onboarding now decides when it is finished. The vault's state does not.
  bool _onboarding = false;

  /// The opening animation, which owns the screen for its first second.
  ///
  /// Cold start only. It is set once here and never set back to true, so
  /// unlocking, backgrounding and navigating never replay it — an intro you
  /// see forty times a day is not a signature moment, it is an obstacle.
  bool _opening = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.vault.addListener(_onVault);
    widget.settings.addListener(_onSettings);
    // Whatever the user chose last time, applied before the first unlock.
    widget.vault.idleTimeout = widget.settings.autoLock;
    widget.settings.markFirstRun();
    _previousState = widget.vault.state;
    _onboarding = widget.vault.state == VaultState.uninitialised;

    // ── ISSUE 4, 13 — the backstop sweep ────────────────────────────────
    //
    // If the process was killed while another app had a file, nothing ran the
    // reclaim. This is the next launch finding it and destroying it, before
    // anything else in the app has had a chance to do anything.
    HandOff.reclaim().ignore();

    // Put the reminder back if it should be running.
    //
    // The boot receiver handles a restart, and this handles everything else —
    // an app the system killed and restored, a reinstall, a settings file
    // restored from a backup. Cheap, silent, and it means the switch being on
    // and the alarm existing cannot drift apart.
    if (widget.settings.remindersEnabled) {
      Reminders.schedule(widget.settings.reminderMinuteOfDay).ignore();
    }

    // The window is already secure — MainActivity sets the flag before the
    // first frame. This only relaxes it, and only if he asked for that.
    if (widget.settings.allowScreenshots) {
      ScreenSecurity.allowCapture(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.vault.removeListener(_onVault);
    widget.settings.removeListener(_onSettings);
    super.dispose();
  }

  /// The last value handed to the window, so it is not handed the same one
  /// twice. Null until the first settings change.
  bool? _capture;

  void _onSettings() {
    widget.vault.idleTimeout = widget.settings.autoLock;
    // The screenshot switch, applied to the live window. It has to be here
    // rather than in the switch's own handler so that a setting restored from a
    // backup takes effect too.
    //
    // **Only when it changed.** This runs on every settings write — a theme, a
    // photo size, a transcription switch — and each call was a platform channel
    // round trip to set a flag to the value it already had. Cheap is not free,
    // and "make the whole app experience lag free" is a request to stop doing
    // work nobody asked for.
    final capture = widget.settings.allowScreenshots;
    if (_capture != capture) {
      _capture = capture;
      ScreenSecurity.allowCapture(capture);
    }
    setState(() {});
  }

  void _onVault() {
    final now = widget.vault.state;
    final was = _previousState;
    _previousState = now;

    // A vault that has gone away — a restore that was rolled back to nothing,
    // for instance — puts the user back at the beginning rather than at a lock
    // screen for a vault that no longer exists.
    if (now == VaultState.uninitialised) _onboarding = true;

    if (now == VaultState.locked && was == VaultState.unlocked) {
      // ── The reason this method is not just `setState` ────────────────────
      //
      // Changing `home` below swaps the *bottom* route of the navigator. Any
      // screen the user had pushed on top of it — settings, the trash, a
      // calendar sheet — stays exactly where it was, sitting over the lock
      // screen it is supposed to have been replaced by.
      //
      // Locking would then be theatre: the vault really is sealed and the keys
      // really are gone, but whoever picked up the phone is still reading a
      // screenful of content that was rendered before it happened. Everything
      // pushed has to come down with it.
      _navigator.currentState?.popUntil((route) => route.isFirst);

      // Attachment metadata is not secret on its own — it is filenames and
      // sizes — but it belongs to a session that has ended, and a cache that
      // outlives the keys is a cache somebody will eventually put something
      // sensitive into.
      AttachmentImporter.forgetEverything();

      // Decoded photographs leave with the keys too. Flutter's image cache
      // holds full-colour bitmaps of the user's own pictures in memory, and
      // "the vault is locked" has to mean the pictures are gone from the
      // screen AND from the buffers behind it.
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // And the sound. A voice note is somebody talking about their day; the
      // native side already stops it when the window goes, but the Dart-side
      // record of *what* was playing would otherwise survive the lock and be
      // waiting on the other side of the passcode. Nothing about a locked
      // vault should still know which recording was open.
      VoicePlayback.instance.stop();

      // And any document held open for reading. A decrypted PDF is somebody's
      // papers sitting in RAM behind a proxy file descriptor; it must not
      // survive the keys that produced it.
      PdfRender.close();

      // ── ISSUE 4, 13 — and anything lent to another app ────────────────
      //
      // A file handed out through "Open with" is the user's content in the
      // clear, on disk, by their own decision. The decision was to lend it, not
      // to leave it: locking the vault takes it back, exactly as it takes back
      // the decoded photographs and the open PDF above.
      HandOff.reclaim().ignore();

      // ── ISSUE 16 — and the recovery phrase, if it was copied ──────────
      //
      // Twelve words that unlock the whole vault must not stay pasteable
      // behind a locked one; that would make the lock decorative. Cleared only
      // if the clipboard is still ours — if the user has copied something else
      // since, that is now their clipboard.
      SecureClipboard.clearIfStillOurs().ignore();

      // ── ISSUE 22 — and the "Deleted. Undo" bar ────────────────────────
      //
      // He photographed it sitting on the **lock screen**: *"And why the fuck
      // it is showing up on opening screen?"*
      //
      // A `SnackBar` is owned by the `ScaffoldMessenger`, which lives above the
      // Navigator and therefore outlives every route under it — including the
      // swap from the day to the passcode field. Its three-second timer is an
      // animation, and an animation does not advance while the app is
      // backgrounded producing no frames, so the commonest way to see this is
      // the commonest way to lock: delete something, put the phone down.
      //
      // Two reasons it goes here rather than being given a shorter timer.
      // Undoing a delete needs the vault open, so the button is *already* dead
      // by this point and offering it is a lie. And "Deleted." on a lock screen
      // says something about what the owner was doing to anybody who picks the
      // phone up — small, but this app locks on background specifically to stop
      // the recent-apps thumbnail saying that much.
      _messenger.currentState?.clearSnackBars();
    }

    if (now == VaultState.unlocked && was != VaultState.unlocked) {
      // Two things that can only happen at the moment the vault opens, because
      // it is the only moment the keys exist and there is no background job in
      // this app that could ever do them.
      EntryRepository(
        widget.vault.database,
        attachments: widget.vault.attachments,
      ).purgeExpired().ignore();

      // ── PLAN.md §7.2 — files with no row, rows with no file ───────────
      //
      // Storing an attachment is two writes that cannot be one: a blob to the
      // filesystem and a row to the database, with no transaction spanning
      // both. A phone killed for memory mid-import lands between them. See
      // `OrphanSweep` for what each half looks like afterwards and why one is
      // worse than the other.
      //
      // After the first frame, deliberately. It is cheap — one directory
      // listing and one column — and the moment the vault opens is the moment
      // the app most needs to feel instant.
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => OrphanSweep.run(widget.vault).ignore());

      // "Silent backup whenever the user logs in." The key was derived by
      // whichever screen took the passcode; this is where it gets used.
      widget.silentBackup.maybeRun().ignore();
    }

    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android reports leaving as three states in a row: `inactive`, then
    // `hidden`, then `paused`. The vault locks on the second, and that ordering
    // is what the two blocks below are about — the first is work that must
    // happen while the app is still in front, the second is the lock itself.
    if (state == AppLifecycleState.resumed) {
      // Back from wherever. If it was a picker we launched, normal locking
      // applies again from this moment. Belt and braces alongside the `finally`
      // in SystemExcursion.around — if a picker somehow never returns a result,
      // resuming still closes the window.
      widget.vault.endSystemReturn();

      // ── ISSUE 4, 13 — the moment the loan ends ──────────────────────────
      //
      // Lamplight is in front, so whatever was being read elsewhere is no
      // longer being read. The grant is revoked and the plaintext is overwritten
      // and deleted here. This is the promise the rule-2 exception was granted
      // on, and it is deliberately the *earliest* honest moment rather than a
      // timer or a next-launch sweep — both of those also exist, as backstops,
      // but neither of them is the plan.
      HandOff.reclaim().ignore();
    }

    // ── THERE IS DELIBERATELY NO BACKUP ON THE WAY OUT ────────────────────
    //
    // `maybeRun(reason: 'leaving')` used to fire here, on `inactive`, and the
    // comment above explained at length why `inactive` rather than `paused`.
    // The reasoning was sound and the conclusion did not follow: a backup is a
    // second Argon2id at 256 MiB, a copy of the whole database, a verify pass
    // and a write through the Storage Access Framework. `hidden` — where the
    // vault locks and the keys are destroyed — arrives a frame or two later.
    // Seconds of work do not fit in a frame or two.
    //
    // So it was killed by the lock on essentially every real exit, and the
    // attempt it had already recorded then blocked the next one for ten
    // minutes. It only ever completed when `inactive` did **not** mean leaving
    // — a notification shade, an incoming call — so it succeeded exactly when
    // there was nothing to protect against and failed whenever there was.
    //
    // The fix is not to hold the lock open. `Vault.onBackgrounded`'s note is
    // explicit that settling is for one small write already committed to, and
    // that waiting on a whole backup would keep the DEK alive for as long as
    // the app sat in the background — the one thing lock-on-background exists
    // to prevent. That trade is still refused, and this is not a way round it.
    //
    // Instead the *fact* that a backup is owed is written to disk as it happens
    // (`AppSettings.vaultChangedSinceBackup`), and the backup runs at the next
    // unlock, in the foreground, where it has as long as it needs.

    // Lock on background. UX-FLOWS.md flow 7: non-negotiable, and the single
    // most effective defence against the most likely adversary in the threat
    // model — someone who picks up the phone while it is unlocked.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      widget.vault.onBackgrounded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ── Ten languages, and the one that is not a choice ─────────────────
      //
      // `L.delegate` carries Lamplight's own words. The three Flutter delegates
      // beside it carry **Material's**, and leaving them out is the classic
      // half-done localisation: the app speaks Spanish and every system dialog
      // still says "Cancel", the date picker is in English, and the text field's
      // own selection menu — Cut, Copy, Paste — never changes at all.
      //
      // `supportedLocales` comes from the generated file rather than being
      // written out here, so adding an ARB file is the whole of adding a
      // language. There is no second list to forget.
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L.supportedLocales,
      // Null follows the phone, which is the default and the right one: an app
      // that picks its own language on first launch is an app that thinks it
      // knows better than the device somebody already set up.
      //
      // **Arabic brings right-to-left with it and nothing here asks for that
      // separately.** `MaterialApp` resolves the locale's direction and wraps
      // the tree in a `Directionality`, so every `EdgeInsetsDirectional`, every
      // `start`/`end` alignment and every `TextAlign.start` mirrors on its own.
      // What does *not* mirror is anything written as `left`/`right` — see
      // `test/widget/rtl_test.dart`, which fails the build on those.
      locale: widget.settings.locale,
      // ── `onGenerateTitle`, and never `title`, and this is not a style note ──
      //
      // `title:` is an eager argument: it is evaluated here, in
      // `_LamplightAppState.build`, whose `context` sits **above** the
      // `MaterialApp` being constructed. `Localizations` is installed by
      // `WidgetsApp`, *inside* that MaterialApp — so there is no `L` to find
      // from here, `Localizations.of<L>` returns null, and the generated
      // `L.of`'s `!` throws on the **first frame of every launch**.
      //
      // That is exactly what it did. The app stopped opening at all: the crash
      // landed before any screen was built, `installCalmErrors` caught it, and
      // what a person saw was an app that would not start. It shipped because
      // nothing in 1,000-odd tests ever pumped `LamplightApp` itself — every
      // widget test built its own `MaterialApp` around one screen, so the one
      // widget with no test was the one that has to work before any other can.
      // `test/widget/app_boots_test.dart` is that test now.
      //
      // `onGenerateTitle` is a callback the framework invokes with a context
      // from **below** the Localizations, which is the whole reason it exists.
      onGenerateTitle: (context) => L.of(context).appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigator,
      scaffoldMessengerKey: _messenger,
      // Three modes, chosen in settings. Both palettes are separately picked,
      // never inverted — DESIGN-SYSTEM.md is explicit that flipping a dark
      // palette produces muddy, low-contrast results.
      //
      // The accent and the writing face are folded in here, once, so that
      // every screen gets them and none of them has to be told. The canvas is
      // shifted for the hour when the page surface is Lamplit — see
      // `canvasForTime`, and note that the shift is deliberately below the
      // threshold of notice.
      // ── The locale reaches the type, not only the words ────────────────
      //
      // `settings.locale` is null when the app follows the phone, and that is
      // the common case; `scriptFallbackFor` and `lineHeightScaleFor` both
      // treat null as "leave everything as it was", so following the phone
      // behaves exactly as it did before this existed.
      //
      // What it buys when it is set: a Japanese reader gets the Japanese Han
      // forms rather than the Simplified Chinese ones for the codepoints the
      // two languages share, and Devanagari and Arabic get the extra leading
      // their marks need. Neither is visible as a change; both are visible as
      // the app feeling like it was set for that language.
      //
      // The **surface** reaches the theme for one reason and it is not colour:
      // a page that draws marks at the scale of type needs the type to carry a
      // halo of the page's own colour, or the two sets of strokes interfere and
      // the writing becomes hard to pick out. **ISSUE 9** — see `pageHalo`.
      theme: lamplightTheme(
        LamplightColors.lightFor(widget.settings.accent),
        face: widget.settings.writingFace,
        locale: widget.settings.locale,
        surface: widget.settings.pageSurface,
      ),
      darkTheme: lamplightTheme(
        LamplightColors.darkFor(widget.settings.accent),
        face: widget.settings.writingFace,
        locale: widget.settings.locale,
        surface: widget.settings.pageSurface,
      ),
      themeMode: widget.settings.themeMode,
      // The text-size preference, applied once for the whole app.
      //
      // Wrapped around every screen here rather than passed down, because a
      // setting that only some screens honour is worse than no setting: the
      // user turns it up, most of the app grows, and the one screen that
      // forgot looks broken.
      //
      // It **multiplies** the OS scaler rather than replacing it, so someone
      // who has already turned their system text up keeps that and this is a
      // nudge on top. See AppSettings.textScale.
      builder: (context, child) {
        // ── Being here counts as being here ────────────────────────────────
        //
        // The idle timer used to be reset only by typing, because typing was
        // the only thing that called `touch()`. So reading yesterday, scrolling
        // through a month, listening to a voice note or looking at a photo were
        // all *idle*, and the app locked in your hands while you were plainly
        // using it. With a long passphrase that is not a security feature, it is
        // a reason to stop using the app.
        //
        // A `Listener` above everything sees every pointer down before any
        // widget handles it, so every tap, drag and scroll now counts. It
        // observes rather than intercepts — `behavior: deferToChild` means it
        // never swallows a gesture from what is underneath.
        final content = LampTypography(
          face: widget.settings.writingFace,
          child: Listener(
            onPointerDown: (_) => widget.vault.touch(),
            // ── ISSUE 21 — the app is about to lock, and says so ──────────
            //
            // Wrapped here, above the Navigator, so it appears over whatever
            // screen happens to be open — a photograph, a PDF, the settings.
            // The idle lock takes all of them down together, so the warning
            // has to sit above all of them too.
            //
            // Inside the `Listener` rather than outside it, so that tapping
            // the notice itself counts as being here like every other tap.
            child: AboutToLock(
              vault: widget.vault,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );

        // ── This MediaQuery is unconditional, and that is the whole point ──
        //
        // It used to read `if (factor == 1.0) return content;` — skip the
        // wrapper when the text-size setting is at its default. That looks like
        // an optimisation and is in fact a defect, because it makes the *shape*
        // of the tree depend on a setting.
        //
        // `child` here is the app's Navigator. Dragging the text-size slider
        // off 100% for the first time inserted a new element above it, which
        // changed the depth of everything below — so `LampTypography`, the
        // InheritedWidget every screen reads its face from, was destroyed and
        // rebuilt, and every screen in the stack remounted mid-gesture. The
        // Navigator's own state survived, because it carries a GlobalKey, which
        // is exactly what made the damage easy to miss.
        // `test/widget/calm_errors_test.dart` measures both halves of that.
        //
        // **On ISSUE 15(b), honestly:** this was found while hunting the
        // `_dependents.isEmpty` assertion Piyush photographed, and it is a real
        // fault on a screen he was demonstrably using — the Appearance screen,
        // whose slider is the only control in the app that does this. It has
        // **not** been proved to be that assertion: a reproduction was written
        // and it does not throw, so the honest claim is a hazard removed rather
        // than a bug confirmed. Part (a) — the calm error surface — ships
        // regardless and is what stops any of this reaching a person.
        //
        // Keeping the wrapper always present means the depth never changes.
        // `TextScaler.linear(x)` at x == 1 is the identity, so nothing is paid.
        final media = MediaQuery.of(context);
        // What the OS scaler currently does to a typical body size, measured
        // rather than assumed — a TextScaler is not required to be linear, and
        // asking it is more honest than reading a deprecated factor off it.
        const probe = 14.0;
        final osFactor = media.textScaler.scale(probe) / probe;
        return MediaQuery(
          data: media.copyWith(
            textScaler:
                TextScaler.linear(osFactor * widget.settings.textScale),
          ),
          child: content,
        );
      },
      home: Builder(
        builder: (context) {
          // ── The launcher icon follows the theme ─────────────────────────
          //
          // Resolved here rather than from the setting, because "Follow phone"
          // is a real option and only the framework knows what the phone
          // currently says. `Theme.of` inside this builder sees the theme that
          // was actually chosen, dark or light, after that resolution.
          //
          // Scheduled off the frame so a component-enable call never happens
          // during a build, and cheap to repeat — the platform side no-ops when
          // the right alias is already on.
          final light = Theme.of(context).brightness == Brightness.light;
          WidgetsBinding.instance.addPostFrameCallback((_) => AppIcon.use(
                accentId: widget.settings.accent.id,
                light: light,
              ));
          // The lamp coming on, once per cold start, over the top of whatever
          // is about to be shown. Skippable, and skipped entirely under
          // prefers-reduced-motion. See features/launch/opening.dart for why
          // this is allowed to break the 300ms rule.
          // ── The one sentence the backup writes on its own ─────────────
          //
          // A silent backup runs at unlock, on a path with no `BuildContext`
          // anywhere in it — that is what makes it silent. The failure line it
          // composes is the one place it needs words of its own, so they are
          // handed to it here, where a context exists, and refreshed when the
          // language changes. See `SilentBackup.words`.
          widget.silentBackup.words = L.of(context);

          if (_opening) {
            return Opening(onDone: () => setState(() => _opening = false));
          }
          // Onboarding first, and it leaves when it says so — see [_onboarding].
          if (_onboarding) {
            return OnboardingScreen(
              vault: widget.vault,
              settings: widget.settings,
              onDone: () => setState(() => _onboarding = false),
            );
          }
          return switch (widget.vault.state) {
            VaultState.uninitialised => OnboardingScreen(
                vault: widget.vault,
              settings: widget.settings,
                onDone: () => setState(() => _onboarding = false),
              ),
            VaultState.locked => LockScreen(
                vault: widget.vault,
                settings: widget.settings,
                silentBackup: widget.silentBackup,
              ),
            VaultState.unlocked => DayScreen(
                vault: widget.vault,
                settings: widget.settings,
                silentBackup: widget.silentBackup,
              ),
          };
        },
      ),
    );
  }
}
