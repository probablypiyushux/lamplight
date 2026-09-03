import 'dart:async';

import 'package:flutter/foundation.dart';

import 'audio_player.dart';

/// Who is playing. **ISSUE 14.**
///
/// ── THE BUG THIS EXISTS TO END ────────────────────────────────────────────
///
/// Start voice note A, do not stop it, start voice note B: both appeared to be
/// playing. There is only ever one player — [EncryptedAudioPlayer] is a single
/// static object talking to a single `MediaPlayer` on the Android side — so B
/// really did replace A. The sound was right and **the screen was wrong**:
/// every `VoiceNotePlayer` widget kept its *own* `_loaded` flag, its *own*
/// `AudioState`, and its *own* 120ms polling timer, so note A was never told it
/// had been stopped and went on drawing a pause button over a moving playhead
/// for a recording nobody could hear.
///
/// Two more faults were hiding underneath, and neither had been reported yet:
///
///  - **`onFinished` was a single static slot.** Starting B overwrote A's
///    completion handler, so when B reached its end A's handler was gone and
///    B's had replaced it. That would have surfaced later as "the waveform
///    sticks at the end", which is a much harder bug to read than this one.
///  - **`dispose` stopped playback unconditionally.** Scroll a playing note off
///    the list — or start B and let A's widget be disposed — and A's `dispose`
///    called `stop()`, silencing B. One widget ending its own life should not
///    be able to stop somebody else's sound.
///
/// ── THE SHAPE OF THE FIX ──────────────────────────────────────────────────
///
/// One object owns the answer to "who is playing", and every voice note
/// *listens* rather than believing itself. That is the difference between a fix
/// and a patch: there is now exactly one place where the answer can be wrong,
/// and starting B stops A everywhere, once, because there is nowhere else for
/// the state to live.
///
/// It also means **one timer for the whole app** instead of one per note. A day
/// with six recordings used to be six periodic timers each waking the isolate
/// six times a second whether or not anything was playing; this one runs only
/// while something is.
///
/// `PLAN.md` §11 test 7 — *"think of every scenario and stop the issue from
/// taking place at first place"* — is the reason this is a class rather than
/// three lines of extra bookkeeping in the widget.
class VoicePlayback extends ChangeNotifier {
  VoicePlayback._();

  /// The one instance. Not an injected dependency: there is exactly one audio
  /// output on the phone, so a second instance could only ever be a way of
  /// recreating the bug this file exists to remove.
  static final VoicePlayback instance = VoicePlayback._();

  /// The attachment id of whatever is loaded, or null when nothing is.
  String? get currentId => _currentId;
  String? _currentId;

  /// The attachment id that is being decrypted right now, if any.
  String? get loadingId => _loadingId;
  String? _loadingId;

  AudioState get state => _state;
  AudioState _state = AudioState.none;

  double get speed => _speed;
  double _speed = 1.0;

  /// Set when the *current* note failed. Cleared the moment another starts.
  String? get error => _error;
  String? _error;

  Timer? _poll;
  bool _wired = false;

  /// A monotonic ticket. Every load takes one; when it comes back it checks
  /// that it is still the newest before touching anything.
  ///
  /// This is what makes two quick taps safe. Decrypting a note is asynchronous,
  /// so tapping A then B before A's bytes arrive would otherwise have A's
  /// `play` land *after* B's and leave the screen saying B while the speaker
  /// says A — the same class of bug as the one above, arriving by a different
  /// road. `PLAN.md` test 7.
  int _ticket = 0;

  bool isCurrent(String attachmentId) => _currentId == attachmentId;

  bool isLoading(String attachmentId) => _loadingId == attachmentId;

  /// Playing *this* note, as opposed to loaded-but-paused.
  bool isPlaying(String attachmentId) =>
      _currentId == attachmentId && _state.playing;

  /// Where [attachmentId] has got to, 0..1 — and 0 for every other note, so a
  /// paused note does not inherit the playhead of the one that replaced it.
  double progressOf(String attachmentId, {Duration? fallbackDuration}) {
    if (_currentId != attachmentId) return 0;
    final total = _state.duration.inMilliseconds > 0
        ? _state.duration.inMilliseconds
        : (fallbackDuration?.inMilliseconds ?? 0);
    if (total <= 0) return 0;
    return (_state.position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  /// Decrypt and play [attachmentId]. Anything already playing stops.
  ///
  /// [load] is a callback rather than the bytes themselves so the decrypt
  /// happens *inside* the ticket window — handing bytes in would mean the
  /// caller had already done the slow part and the race would be back.
  Future<void> start(
    String attachmentId,
    Future<Uint8List> Function() load,
  ) async {
    _wire();
    final mine = ++_ticket;

    // The previous note stops *now*, on screen, not when the new bytes arrive.
    // Anything else means a second of two notes both looking live, which is
    // exactly the report.
    _stopPolling();
    _currentId = null;
    _state = AudioState.none;
    _error = null;
    _loadingId = attachmentId;
    _speed = 1.0;
    notifyListeners();

    try {
      final bytes = await load();
      if (mine != _ticket) return; // Somebody newer took over while we waited.
      await EncryptedAudioPlayer.play(bytes);
      if (mine != _ticket) {
        // Lost the race after the platform call. Whatever is newest is already
        // playing; stopping here would silence it.
        return;
      }
      _loadingId = null;
      _currentId = attachmentId;
      _state = await EncryptedAudioPlayer.state();
      _startPolling();
    } catch (e) {
      if (mine != _ticket) return;
      _loadingId = null;
      _currentId = null;
      _error = _plain(e);
    }
    notifyListeners();
  }

  Future<void> pause() async {
    if (_currentId == null) return;
    await EncryptedAudioPlayer.pause();
    await _refresh();
  }

  Future<void> resume() async {
    if (_currentId == null) return;
    await EncryptedAudioPlayer.resume();
    await _refresh();
  }

  Future<void> seekFraction(String attachmentId, double fraction,
      {Duration? fallbackDuration}) async {
    if (_currentId != attachmentId) return;
    final total = _state.duration.inMilliseconds > 0
        ? _state.duration.inMilliseconds
        : (fallbackDuration?.inMilliseconds ?? 0);
    if (total <= 0) return;
    await EncryptedAudioPlayer.seek((fraction.clamp(0.0, 1.0) * total).round());
    await _refresh();
  }

  Future<void> skip(String attachmentId, Duration by) async {
    if (_currentId != attachmentId) return;
    final total = _state.duration.inMilliseconds;
    final target = (_state.position + by).inMilliseconds;
    await EncryptedAudioPlayer.seek(
        target.clamp(0, total > 0 ? total : target.abs()));
    await _refresh();
  }

  Future<void> setSpeed(double rate) async {
    if (_currentId == null) return;
    _speed = rate;
    await EncryptedAudioPlayer.setSpeed(rate);
    notifyListeners();
  }

  /// Stop everything. Safe to call when nothing is playing.
  Future<void> stop() async {
    _ticket++;
    _stopPolling();
    _currentId = null;
    _loadingId = null;
    _state = AudioState.none;
    _error = null;
    notifyListeners();
    await EncryptedAudioPlayer.stop();
  }

  /// Stop only if [attachmentId] is the one playing.
  ///
  /// This is what a disposing widget calls. A note that is no longer on screen
  /// has no business silencing the note that replaced it.
  Future<void> stopIfCurrent(String attachmentId) async {
    if (_currentId != attachmentId && _loadingId != attachmentId) return;
    await stop();
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(milliseconds: 120), (_) async {
      if (_currentId == null) return _stopPolling();
      final s = await EncryptedAudioPlayer.state();
      if (_currentId == null) return;
      _state = s;
      notifyListeners();
    });
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _refresh() async {
    _state = await EncryptedAudioPlayer.state();
    notifyListeners();
  }

  /// One completion handler for the app, registered once.
  ///
  /// The old code re-registered it on every play, which is what clobbered the
  /// previous note's callback.
  void _wire() {
    if (_wired) return;
    _wired = true;
    EncryptedAudioPlayer.onFinished(() {
      _stopPolling();
      // Stay *loaded* with the playhead at the end rather than snapping to
      // zero: "it finished" and "it was never started" are different states
      // and should not look the same.
      _state = AudioState(
        position: _state.duration,
        duration: _state.duration,
        playing: false,
      );
      notifyListeners();
    });
  }

  static String _plain(Object e) {
    final s = '$e';
    // Never a Dart type name in front of a person. PLAN.md §11 test 6.
    return s.contains('could not be played')
        ? s.replaceFirst(RegExp(r'^[A-Za-z_]+: '), '')
        : 'That recording could not be played.';
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  /// Tests only: put the singleton back to a known state between cases.
  @visibleForTesting
  void resetForTest() {
    _stopPolling();
    _ticket++;
    _currentId = null;
    _loadingId = null;
    _state = AudioState.none;
    _speed = 1.0;
    _error = null;
    _wired = false;
  }
}
