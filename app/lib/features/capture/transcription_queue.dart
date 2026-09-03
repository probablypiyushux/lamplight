import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/db/database.dart' show Attachment;
import '../../core/plain_words.dart';
import '../../core/platform/transcription.dart';
import '../../core/settings/app_settings.dart';
import '../../core/storage/attachment_importer.dart';
import '../../core/vault/vault.dart';
import '../../l10n/generated/app_localizations.dart';

/// Works through voice notes that have nothing written down for them yet.
///
/// ══ ISSUE 15 — "TAKE YOUR TIME" ═════════════════════════════════════════════
///
/// > *"Voice is recorded — take your time — even if the app is closed — take
/// > your time — transcribe the audio … and slower output is not an issue —
/// > when a better output is received!"*
///
/// He says *take your time* three times in four lines, which is unusual for
/// this document and is the design brief. So this is deliberately the least
/// urgent thing in the app: one recording at a time, started only when nothing
/// else is going on, abandoned the instant the vault closes, and picked up
/// again from wherever it got to next time.
///
/// ── ON "EVEN IF THE APP IS CLOSED", HONESTLY ────────────────────────────────
///
/// It cannot run with the app closed, for the same reason an import cannot —
/// reading the recording needs the key, the key exists only while the vault is
/// unlocked, and the vault locks on background. That is `UX-FLOWS.md` flow 7
/// and it is the one rule this project will not trade.
///
/// What "take your time" buys instead is that **it does not have to finish**.
/// A transcript is not part of saving a note; the note is already safe. So the
/// work is resumable by construction: the queue asks the database what still
/// has no transcript, does one, and asks again. Close the app halfway through a
/// backlog and the next unlock carries on from the same place, because there
/// was never any state to lose. Which is most of what he wanted from the
/// background version, without touching the lock.
///
/// ── AND WHY IT IS OFF UNTIL SOMEBODY TURNS IT ON ────────────────────────────
///
/// Transcribing hands the decrypted audio to Android's recognition service.
/// That service is on-device — `Transcription` explains how that is guaranteed
/// rather than hoped for — but it is still somebody's diary crossing into
/// another process, and that is not a decision an app should make on their
/// behalf. `ETHICAL-DESIGN.md`: no default that gives away more than the user
/// asked for.
class TranscriptionQueue extends ChangeNotifier {
  TranscriptionQueue({
    required this.importer,
    required this.vault,
    required this.settings,
  });

  final AttachmentImporter importer;
  final Vault vault;
  final AppSettings settings;

  /// The app's words, for the two sentences this queue writes on its own.
  ///
  /// Handed in rather than looked up, for the same reason `SilentBackup.words`
  /// is: transcription runs on a background path with no `BuildContext` in it.
  /// Null falls back to English, which is the rule the ARB files already
  /// follow — a half-finished translation must never be why somebody cannot
  /// read what happened to their recording.
  L? words;

  bool _running = false;
  bool _stopped = false;

  /// What is being written down right now, for the settings screen to show.
  Attachment? _current;
  Attachment? get current => _current;

  /// How many are still waiting, as of the last look.
  int _waiting = 0;
  int get waiting => _waiting;

  bool get isBusy => _running;

  // ══ SAYING WHAT IS HAPPENING. ROUND TEN ═══════════════════════════════════
  //
  // > *"It's been 15 minutes, I recorded a 5 sec voice note, it can't
  // > transcribe! Idk if it's transcribed or not!"*
  //
  // The queue was doing exactly what it was designed to do and there was no way
  // on earth to find out what that was. Every state it can be in looked
  // identical from the outside — a voice note with no row under it:
  //
  //   * the setting is off, so nothing was ever going to happen;
  //   * this phone has no recogniser and no model, so nothing can happen;
  //   * it is in the queue, behind others;
  //   * it is being written down right now;
  //   * it failed, and the queue is resting for ten minutes before retrying.
  //
  // Five states, one appearance, and the appearance was *nothing at all*. That
  // is the invisible-machinery fault ISSUE 16 is about, in its worst form:
  // ISSUE 16 was about showing people machinery they should not have to see,
  // and this is the same mistake made in the opposite direction — hiding a
  // thing they are waiting for. The rule is the same either way. **The user
  // should never have to guess whether the app is working.**
  //
  // These three are what the row under a voice note reads.

  /// Whether either engine is on this phone, as of the last time it was asked.
  ///
  /// Null until something has actually looked — which only happens once the
  /// setting is on, because asking the platform is a round trip and there is
  /// nothing to do with the answer while the feature is switched off.
  bool? _engine;
  bool? get engineAvailable => _engine;

  /// Why nothing is being written down, if something went wrong.
  ///
  /// Cleared by the next success. Already a sentence — `plainFailure` has run
  /// on it — so it can go straight onto the screen.
  String? _problem;
  String? get problem => _problem;

  /// Whether this particular recording is the one being worked on now.
  bool isWorkingOn(String attachmentId) => _current?.id == attachmentId;

  /// Whether the engine can follow a sentence that changes language halfway.
  ///
  /// ══ IT CANNOT, AND THAT IS NOW A SETTLED TRADE ═══════════════════════════
  ///
  /// This used to be true when a Whisper model was loaded. Whisper was removed
  /// on 28 August 2026 — *"remove this whisper option please ... cause it's
  /// trash"* — so the answer is a constant `false`, and the getter stays
  /// because the row under a voice note still has to be able to say it.
  ///
  /// What that costs, plainly: Android's recogniser takes **one** BCP-47 tag
  /// per session and has no multilingual mode to ask for, so *"maine kaha ki
  /// I'll be there"* comes back as whichever half matches the chosen language.
  /// No amount of work on this side changes that.
  ///
  /// What it buys: nothing to download, nothing to import, results in about
  /// real time instead of several minutes, and 2.7 MB of vendored C++ and a
  /// 500 MB model file out of the app entirely. He weighed it and chose this.
  bool get isMultilingual => false;

  /// A language the system recogniser has been asked for and has not
  /// downloaded, if that is what is standing in the way.
  ///
  /// Null when nothing is. See [_one] for why this is checked **before**
  /// running rather than inferred from an empty result afterwards.
  String? _missingLanguage;
  String? get missingLanguage => _missingLanguage;

  // ══ ONE ENGINE ════════════════════════════════════════════════════════════
  //
  // Android's own on-device recogniser, and nothing else. There were two until
  // 28 August 2026, when he removed the other one.
  //
  // `createOnDeviceSpeechRecognizer` only — there is a test that reads the
  // Kotlin and fails if anybody adds a networked fallback. Nothing said into
  // this app leaves the phone, and that is enforced rather than promised.
  //
  // Checked per run rather than cached: a language pack can be installed while
  // the app is open, and the next recording should use whatever is true then.
  Future<bool> get available async => Transcription.available;

  /// Retained as a constant `false` so callers need not change.
  ///
  /// There is no model to fetch any more. It used to mean "this phone could run
  /// Whisper and nobody has given it a model", which was the ordinary state of
  /// a new install; with Whisper gone the equivalent situation is a missing
  /// **language pack**, which [missingLanguage] already reports and which the
  /// phone downloads itself.
  bool get needsModel => false;

  /// Starts working through the backlog, if there is anything to do.
  ///
  /// Safe to call as often as you like — on unlock, after a recording, when the
  /// setting is switched on. It returns immediately if it is already running.
  Future<void> catchUp() async {
    if (_running) return;
    if (!settings.transcribeVoice) return;
    if (!vault.isUnlocked) return;

    // Asked before the `_stopped` gate, and told to anybody watching. A phone
    // with no engine at all is a permanent answer, and the row under a voice
    // note has to be able to say so rather than promising indefinitely that
    // something is about to happen.
    final engine = await available;
    if (_engine != engine) {
      _engine = engine;
      notifyListeners();
    }
    if (!engine || _stopped) return;

    _running = true;
    notifyListeners();
    try {
      while (!_stopped && vault.isUnlocked && settings.transcribeVoice) {
        final pending = await importer.voiceWithoutTranscript(limit: 20);
        if (pending.isEmpty) break;
        _waiting = pending.length;

        final next = pending.first;
        _current = next;
        notifyListeners();

        await _one(next);

        // A breath between recordings. This is the lowest-priority work in the
        // app and it must never be the reason a scroll stutters — his round
        // nine also contains "app feels so slow", and a transcriber that hogs
        // the phone to be helpful would be answering one complaint by causing
        // another.
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    } finally {
      _running = false;
      _current = null;
      notifyListeners();
    }
  }

  /// How long to wait before deciding an engine is not coming back.
  ///
  /// ══ WHY THERE HAS TO BE ONE AT ALL ════════════════════════════════════════
  ///
  /// > *"It's been 15 minutes, I recorded a 5 sec voice note, it can't
  /// > transcribe!"*
  ///
  /// **Nothing in this path had a deadline, and the consequence was worse than
  /// slow.** `SpeechRecognizer` is a callback API: `Transcribe.listen` finishes
  /// when the service calls `onResults`, `onError` or `onEndOfSegmentedSession`
  /// — and if the service never calls anything, the `Future` never completes.
  /// `_running` then stays true for the life of the process, every later
  /// `catchUp` returns at its first line, and **the whole feature is off until
  /// the app is killed**, silently, with no error anywhere.
  ///
  /// A five-second recording that has taken fifteen minutes is either that, or
  /// something equally stuck. Either way the answer is the same: give up, say
  /// so, and leave the recording untouched so it can be tried again.
  ///
  /// How long to wait before giving up on one recording.
  ///
  /// Proportional to its length, with a floor. Android's recogniser runs faster
  /// than real time, so twice the audio is generous; the floor covers a very
  /// short clip on a busy phone.
  ///
  /// The ten-times branch that used to be here was Whisper's — it ran at about
  /// twice the length of the audio and needed the slack. There is no second
  /// engine to switch on any more.
  Duration _patience(Attachment attachment) {
    final seconds = ((attachment.durationMs ?? 60000) / 1000).ceil();
    final slack = seconds * 2;
    return Duration(seconds: slack < 90 ? 90 : slack);
  }

  Future<void> _one(Attachment attachment) async {
    try {
      // ── The language pack, checked before rather than after ──────────────
      //
      // **This is the destructive one.** Android's recogniser returns an empty
      // string — not an error — when it has no downloaded model for the
      // language it was asked for. The old code wrote that empty string as the
      // transcript, and an empty transcript means *"we listened and there was
      // nothing"*, which is exactly what stops this queue ever trying that
      // recording again.
      //
      // So on a phone whose language pack had not been fetched, the first run
      // of the queue would walk the entire backlog and permanently mark every
      // voice note the user has ever made as silent. Installing the pack
      // afterwards would fix nothing, because there would be nothing left to
      // do. The recordings are safe; their transcripts are gone before they
      // exist.
      //
      // Asked up front, therefore, and treated as a reason to stop rather than
      // as an answer.
      {
        final wanted = settings.transcriptionLanguage;
        final languages = await Transcription.languages();
        // An empty list means the platform would not say — a widget test, a
        // phone that answered badly — and refusing to work on no information
        // would be worse than trying.
        final known =
            languages.installed.isNotEmpty || languages.supported.isNotEmpty;
        if (known && !languages.installed.contains(wanted)) {
          if (_missingLanguage != wanted) {
            _missingLanguage = wanted;
            notifyListeners();
          }
          _stopFor(const Duration(minutes: 10));
          return;
        }
      }
      if (_missingLanguage != null) {
        _missingLanguage = null;
        notifyListeners();
      }

      final bytes = await importer.bytesOf(attachment);
      if (_stopped || !vault.isUnlocked) return;

      final text = await Transcription.of(
        bytes,
        language: settings.transcriptionLanguage,
      ).timeout(
        _patience(attachment),
        onTimeout: () => throw TranscriptionFailed(
          words?.transcribeTookTooLong ??
              'That recording took too long to write down, so Lamplight '
                  'stopped waiting. It will try again later.',
        ),
      );
      if (_stopped || !vault.isUnlocked) return;

      // **The empty string is written, not skipped.** A recording of a quiet
      // room genuinely has nothing in it, and storing that as "we looked and
      // there was nothing" is what stops this queue trying the same silence
      // again on every launch for the rest of the vault's life.
      //
      // Safe to do *now* only because of the check above: an empty result can
      // no longer mean "the language pack is missing", which is the one reading
      // of it that must not be recorded as an answer.
      await importer.setTranscript(attachment.id, text);
      // Whatever went wrong last time did not go wrong this time.
      if (_problem != null) {
        _problem = null;
        notifyListeners();
      }
    } catch (e) {
      // A language that is not installed, a recogniser that was busy, a file
      // the decoder refused, the timeout above. Left with no transcript so it
      // is tried again later — but **stop the run**, because whatever it was
      // will almost certainly happen to the next one too, and grinding through
      // two hundred recordings to fail identically each time is not patience,
      // it is a loop.
      //
      // One clause, not three. There were two `on TranscriptionFailed` blocks
      // with identical bodies and a bare `catch` with the same body again — the
      // first of them used to catch `WhisperFailed`, and when that type went
      // the two collapsed into an unreachable duplicate.
      _problem = plainFailure(e,
          fallback: words?.transcribeCouldNotWriteDown ??
              'That recording could not be written down.',
          andThen: words?.transcribeRecordingIsSafe ??
              'The recording itself is safe. Lamplight will try again.', words: words);
      _stopFor(const Duration(minutes: 10));
    }
  }

  /// Backs off after a failure, then allows another attempt.
  void _stopFor(Duration pause) {
    _stopped = true;
    notifyListeners();
    Timer(pause, () {
      _stopped = false;
    });
  }

  /// Called when the vault locks. Nothing to unwind — that is the point.
  void stop() {
    _stopped = true;
    Timer(const Duration(milliseconds: 1), () => _stopped = false);
  }

  @override
  void dispose() {
    _stopped = true;
    super.dispose();
  }
}
