import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../core/platform/capture.dart';
import '../../core/settings/photo_quality.dart';
import '../../core/settings/video_quality.dart';
import '../../core/storage/attachment_importer.dart';
import '../../core/vault/vault.dart';

/// What is being added to the vault right now, and what is behind it.
///
/// ══ ISSUES 12, 13, 14 AND 23 ARE ONE MECHANISM ══════════════════════════════
///
/// Four of round nine's items are the same missing thing seen from four sides:
///
/// > **12** — *"If a file is being uploaded by you give me visual message that
/// > file is being uploaded, or being compressed … I don't get a visual thing
/// > that the file is being uploaded or what?"*
///
/// > **13** — *"When one file is uploading I can't upload another — not even
/// > record voice, take photo, use gallery … don't restrict me from using the
/// > app too!"*
///
/// > **14** — *"If I upload the file and then app gets closed the uploading
/// > stops, I don't want that."*
///
/// > **23** — *"When a process is going on! Give me a visual instead of
/// > shutting down!"*
///
/// The import loop lived inside the day screen, ran on the way to a `setState`,
/// and its only outward sign was `busy: true` — which **greyed out all three
/// capture buttons** and showed a counter that only appeared for multi-file
/// picks. So a big video was: everything goes dead, nothing says why, and if
/// you leave, it is gone.
///
/// ── WHAT THIS CHANGES, AND WHAT IT DELIBERATELY DOES NOT ────────────────────
///
/// **The work stays sequential. That is not laziness and it must not be
/// "improved" into `Future.wait`.** Every file waits in the cache as *plaintext*
/// until its turn is finished and it is scrubbed — see `CapturedFile.scrub` and
/// `CLAUDE.md` rule 2. Importing twenty at once means twenty of somebody's
/// photographs sitting in the clear at the same moment. One at a time means
/// there is never more than one.
///
/// What changes is that the *queue* is no longer the *screen*. Adding more
/// while one is running appends; the capture bar stays live; the app stays
/// usable. Which is ISSUE 13 in full, without touching the invariant ISSUE 13
/// would otherwise have cost.
///
/// ── ON ISSUE 14, HONESTLY ───────────────────────────────────────────────────
///
/// *"If the app gets closed the uploading stops, I don't want that."*
///
/// It cannot keep going with the app closed, and this is worth stating plainly
/// rather than half-doing. Writing into the vault needs the key, the key exists
/// only while the vault is unlocked, and the vault locks the instant the app
/// goes into the background — `UX-FLOWS.md` flow 7, the one rule the project
/// calls non-negotiable. An import that continued in the background would mean
/// the key stayed in memory the whole time it ran, which is exactly the thing
/// locking exists to prevent. **A background upload and this app's central
/// promise cannot both be true.**
///
/// So what it does instead, and what he actually loses is smaller than it was:
///
///   * whatever is **mid-write when you leave gets a moment to land** —
///     `Vault.whileSettling`, bounded, the same mechanism that saves an
///     interrupted recording;
///   * whatever has **already finished stays finished** — it did before, but
///     nothing said so;
///   * whatever never started is **scrubbed**, so no plaintext is left behind
///     a locked vault; and
///   * you are **told**, in a sentence, rather than finding a gap later.
///
/// The last one is the real repair. "The file never gets there — idk what is
/// it?" is a complaint about silence at least as much as about loss.
class ImportQueue extends ChangeNotifier {
  ImportQueue({required this.importer, required this.vault});

  final AttachmentImporter importer;
  final Vault vault;

  final Queue<_Job> _jobs = Queue<_Job>();
  bool _running = false;

  /// The job in progress, or null when there is nothing to do.
  ImportProgress? _progress;
  ImportProgress? get progress => _progress;

  /// How many are added and finished since the queue last went quiet, so the
  /// summary at the end can count a whole batch rather than one pick.
  int _done = 0;
  int _added = 0;

  /// Files that were still waiting when the vault locked, scrubbed unimported.
  /// Read once and cleared — see [takeAbandoned].
  int _abandoned = 0;

  /// How many are left, including the one running.
  int get pending => _jobs.length + (_running ? 1 : 0);

  bool get isBusy => _running || _jobs.isNotEmpty;

  /// Adds [files] to the back of the queue and starts it if it is not running.
  ///
  /// [groupId] is what makes a multi-file pick draw as one album. It is decided
  /// by the caller, per pick, so that two separate picks stay two albums even
  /// when the second is added while the first is still going.
  /// [photoSize] and [videoSize] are what was chosen for **this batch**, when
  /// anything was. **ISSUE 6** — *"ask when uploading"*. Carried on the job
  /// rather than read at the moment of import, because the queue runs for a
  /// while and a second pick with a different answer can arrive behind this
  /// one; reading a setting when the job finally runs would apply the wrong
  /// batch's answer to it.
  void add(
    List<CapturedFile> files, {
    required String dayKey,
    String? groupId,
    PhotoQuality? photoSize,
    VideoQuality? videoSize,
  }) {
    if (files.isEmpty) return;
    for (final file in files) {
      _jobs.add(_Job(
        file: file,
        dayKey: dayKey,
        groupId: groupId,
        photoSize: photoSize,
        videoSize: videoSize,
      ));
      _added++;
    }
    notifyListeners();
    unawaited(_pump());
  }

  /// What finished, for the sentence shown when the queue empties.
  ///
  /// Reading it clears it, because it describes one batch and the next batch
  /// starts counting from nothing.
  ImportSummary takeSummary() {
    final summary = ImportSummary(
      added: _done,
      requested: _added,
      abandoned: _abandoned,
      savedFrom: _weighedBefore,
      savedTo: _weighedAfter,
      failure: _failure,
      videoKept: _videoKept,
    );
    _done = 0;
    _added = 0;
    _abandoned = 0;
    _weighedBefore = 0;
    _weighedAfter = 0;
    _failure = null;
    _videoKept = null;
    return summary;
  }

  /// Whether a finished batch is waiting to be reported.
  bool get hasSummary => !isBusy && (_added > 0 || _abandoned > 0);

  int _weighedBefore = 0;
  int _weighedAfter = 0;
  Object? _failure;

  /// Why a video in this batch came back at its original size. **ISSUE 10.**
  ///
  /// > *"when uploaded it does prompts but never resizes"*
  ///
  /// Not a failure and not reported as one — the file imported perfectly. It
  /// is here because the app **asked a question** and the honest end of that
  /// exchange is saying what came of the answer. First one wins; a batch of
  /// twenty clips that all declined for the same reason is one sentence.
  CompressionOutcome? _videoKept;

  Future<void> _pump() async {
    if (_running) return;
    _running = true;
    try {
      while (_jobs.isNotEmpty) {
        // The vault closing is the end of the queue, not a failure of it.
        // Everything still waiting is destroyed rather than left in the cache
        // where it would outlive the keys — see the class note on ISSUE 14.
        if (!vault.isUnlocked) {
          await _abandonEverything();
          break;
        }
        final job = _jobs.removeFirst();
        await _run(job);
      }
    } finally {
      _running = false;
      _progress = null;
      notifyListeners();
    }
  }

  Future<void> _run(_Job job) async {
    _progress = ImportProgress(
      name: job.file.name,
      done: _done,
      total: _added,
      fraction: null,
    );
    notifyListeners();

    try {
      // Held open across the write, so leaving the app mid-import lands what
      // is nearly finished instead of throwing it away. Bounded — see
      // `Vault.whileSettling`.
      await vault.whileSettling(() async {
        final before = await job.file.file.length().catchError((_) => 0);
        final entryId = await importer.importCaptured(
          captured: job.file,
          dayKey: job.dayKey,
          groupId: job.groupId,
          photoSize: job.photoSize,
          videoSize: job.videoSize,
          // ISSUE 10. Kept per batch rather than per file: "one of these could
          // not be made smaller" is the sentence a person can use, and five
          // copies of it is nagging.
          onVideoKept: (outcome) => _videoKept ??= outcome,
          onProgress: (fraction) {
            final at = _progress;
            if (at == null) return;
            _progress = at.copyWith(fraction: fraction);
            notifyListeners();
          },
        );
        _done++;
        // Read back from the row rather than estimated: the number he is shown
        // is the number actually in the vault. ISSUE 12, round six.
        final row = await importer.attachmentForEntryId(entryId);
        if (row != null && before > 0) {
          _weighedBefore += before;
          _weighedAfter += row.byteSize;
        }
      });
    } catch (e) {
      _failure ??= e;
      // Whatever happened, this one's plaintext does not stay on disk.
      await job.file.scrub();
    }
  }

  Future<void> _abandonEverything() async {
    while (_jobs.isNotEmpty) {
      final job = _jobs.removeFirst();
      _abandoned++;
      await job.file.scrub();
    }
  }

  /// Drops everything waiting. Called when the vault locks.
  Future<void> stop() async {
    await _abandonEverything();
    notifyListeners();
  }

  int takeAbandoned() {
    final n = _abandoned;
    _abandoned = 0;
    return n;
  }

  @override
  void dispose() {
    // Not awaited: dispose cannot wait, and leaving plaintext behind is worse
    // than a dangling future. The next launch sweeps the cache anyway.
    unawaited(_abandonEverything());
    super.dispose();
  }
}

class _Job {
  const _Job({
    required this.file,
    required this.dayKey,
    this.groupId,
    this.photoSize,
    this.videoSize,
  });

  final CapturedFile file;
  final String dayKey;
  final String? groupId;

  /// What was chosen for the batch this file came in with. **ISSUE 6.**
  final PhotoQuality? photoSize;
  final VideoQuality? videoSize;
}

/// One item, mid-import.
@immutable
class ImportProgress {
  const ImportProgress({
    required this.name,
    required this.done,
    required this.total,
    required this.fraction,
  });

  /// What to call it on screen. A filename, which is the user's own word for
  /// the thing and the only name they would recognise.
  final String name;

  /// How many of this batch are finished, and how many there are.
  final int done;
  final int total;

  /// 0..1 through this one, or null while the size is not yet known — a
  /// recording, or a video still being re-encoded.
  final double? fraction;

  ImportProgress copyWith({double? fraction}) => ImportProgress(
        name: name,
        done: done,
        total: total,
        fraction: fraction ?? this.fraction,
      );
}

/// What happened to a whole batch, for the one sentence at the end.
@immutable
class ImportSummary {
  const ImportSummary({
    required this.added,
    required this.requested,
    required this.abandoned,
    required this.savedFrom,
    required this.savedTo,
    required this.failure,
    this.videoKept,
  });

  final int added;
  final int requested;
  final int abandoned;
  final int savedFrom;
  final int savedTo;
  final Object? failure;

  /// Why a video came back the same size, or null if none did. **ISSUE 10.**
  ///
  /// `smaller` and `notAsked` never reach here — the first is not worth saying
  /// and the second is the user's own setting doing exactly what they set it
  /// to.
  final CompressionOutcome? videoKept;

  bool get isEmpty => added == 0 && abandoned == 0 && failure == null;
}
