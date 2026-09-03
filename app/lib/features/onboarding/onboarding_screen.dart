import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show OrdinalSortKey;

import '../../core/platform/biometrics.dart';
import '../../core/platform/secure_clipboard.dart';
import 'package:flutter/services.dart';

import '../../core/security/passcode_rules.dart';
import '../../core/settings/app_settings.dart';
import '../../core/vault/vault.dart';
import '../../core/plain_words.dart';
import '../../design/passcode_meter.dart';
import '../../design/lamp_mark.dart';
import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../backup/restore_screen.dart';
import '../settings/language_tile.dart' show kLanguages;

/// First launch, per `03-product/UX-FLOWS.md` flow 1. Target: under 60 seconds.
///
/// Four screens, and the restraint is the point. No signup form, no carousel,
/// no permission requests up front. **The absence of a signup screen IS the
/// pitch** — it is the first thing that tells someone this app is different
/// from every other one they have installed, so it is stated plainly rather
/// than buried in a privacy policy.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.vault,
    required this.settings,
    required this.onDone,
  });

  final Vault vault;
  final AppSettings settings;
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { language, promise, passcode, phrase, confirm, fingerprint, name }

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// ══ THE LANGUAGE IS THE FIRST THING ASKED. 2 SEPTEMBER 2026 ═══════════
  ///
  /// > *"say me is it able to choose localisation from the very first step? i
  /// > need an answer yes! Like as the person is opening the lamplight - i
  /// > need you to give localisation - language option from the very first
  /// > step! make it possible if that's not possible!"*
  ///
  /// It was not, and the honest version of why is that it was *nearly* fine.
  /// The app follows the phone's language, and onboarding has been fully
  /// translated since round twelve — deliberately first, because an English
  /// literal on this screen is a lockout rather than untidiness. So somebody
  /// with a Hindi phone already met Lamplight in Hindi.
  ///
  /// What that misses is everybody whose phone is not in the language they
  /// want to write in, which in India is an enormous number of people — a
  /// phone set up in English by whoever sold it, used by somebody who thinks
  /// in Hindi. For them the language setting existed and was four taps inside
  /// a vault they had not created yet.
  ///
  /// So it is step one. Every language is named in its own script — see
  /// `kLanguages` — which is what makes this screen usable by somebody who
  /// cannot read the one the phone chose for them.
  _Step _step = _Step.language;

  final _passcode = TextEditingController();
  final _confirmPasscode = TextEditingController();
  final _name = TextEditingController();
  final _answers = <int, TextEditingController>{};

  List<String>? _words;
  List<int> _quizIndexes = const [];
  String? _error;
  bool _busy = false;

  /// Whether the two fields are in a state that would actually create a vault.
  bool get _passcodeReady =>
      PasscodeRules.accepts(_passcode.text) &&
      _passcode.text == _confirmPasscode.text;

  @override
  void initState() {
    super.initState();
    // Asked once, early, so the quiz screen already knows whether there is a
    // fingerprint step after it. Costs one channel call and never blocks
    // anything: an unavailable answer simply means the step is skipped.
    Biometrics.status().then((status) {
      if (mounted) setState(() => _biometrics = status);
    });
    // Redraw the meter and the button as the fields change. `setState` on a
    // keystroke is fine here and nowhere else in the app: this screen is four
    // widgets, it is seen once in the life of the vault, and the alternative
    // is plumbing two notifiers through for one minute of somebody's life.
    _passcode.addListener(_onPasscodeTyped);
    _confirmPasscode.addListener(_onPasscodeTyped);
  }

  void _onPasscodeTyped() {
    if (_step == _Step.passcode) setState(() {});
  }

  @override
  void dispose() {
    _passcode.dispose();
    _confirmPasscode.dispose();
    _name.dispose();
    for (final c in _answers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _createVault() async {
    // The rules are checked here as well as shown live, because the button is
    // reachable by keyboard Enter and by a screen reader even while it is
    // greyed, and a vault created with a two-character passcode cannot be
    // fixed afterwards without the user knowing to go and change it.
    final problems = PasscodeRules.problems(_passcode.text, L.of(context));
    if (problems.isNotEmpty) {
      setState(() => _error = problems.first);
      return;
    }
    if (_passcode.text != _confirmPasscode.text) {
      setState(() => _error = L.of(context).onboardPasscodesDiffer);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final words = await widget.vault.create(passcode: _passcode.text);
      setState(() {
        _words = words;
        _step = _Step.phrase;
        _passcode.clear();
        _confirmPasscode.clear();
      });
    } catch (e) {
      // The very first thing a stranger ever does in this app, and since the
      // ten languages landed it fails in *their* language rather than in
      // English. That is the whole reason onboarding was localised first: a
      // person choosing a passphrase in a script they cannot read is the one
      // place an English literal locks somebody out of their own journal
      // rather than merely looking untidy.
      //
      // `mounted` guards the lookup as well as the `setState`. Vault creation
      // is the longest await on this screen, and reading an inherited widget
      // off a disposed element throws differently — and less legibly — than
      // the `setState` alone ever did.
      if (!mounted) return;
      setState(() => _error = plainFailure(e,
          fallback: L.of(context).onboardVaultFailed,
          andThen: L.of(context).onboardVaultFailedThen,
          words: L.of(context)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Chooses three words to ask about — **freshly, every single time.**
  ///
  /// ══ ISSUE 16 — the hole he walked through, step by step ═══════════════
  ///
  /// He photographed the whole route and numbered it:
  ///
  ///   1. "Write these twelve words on paper" — *"user ignores this"* — press
  ///      "I've written them down".
  ///   2. "Check three of them" — words 5, 7 and 11 — press *"Show me the
  ///      words again"*.
  ///   3. Back on the twelve words — *"user goes back, memorise 5, 7, 11"* —
  ///      press back.
  ///   4. "Check three of them" — **words 5, 7 and 11 again**. *"Words asked
  ///      again are same. User's memory works here."*
  ///
  /// And then the instruction: *"What I want you to do here is: every time the
  /// user reaches this page you need to ask random — not that random order you
  /// choose before."*
  ///
  /// He is exactly right, and the bug is one line: the three indexes were
  /// picked **once**, in `_createVault`, and the confirm screen read the same
  /// list forever. So the check could be passed by memorising three words for
  /// twenty seconds, which is precisely what it exists to prevent. `UX-FLOWS.md`
  /// flow 1 screen 3 says the point is "proof they actually wrote them down,
  /// not that they can read a screen" — and it was proving neither.
  ///
  /// Rolled here instead, and this is called on every entry to the screen, so
  /// bouncing between the two pages asks a different question each time.
  ///
  /// **`Random.secure`, not `shuffle()`.** `CLAUDE.md` rule 6 reserves the OS
  /// CSPRNG for anything an attacker could benefit from predicting. It is
  /// arguable whether this qualifies — the quiz is not a secret — but the cost
  /// of using the secure source is nothing at all, and the question this
  /// protects is "did you write down the words that protect everything", which
  /// is not a place to be arguing about entropy.
  void _rollQuiz() {
    final random = math.Random.secure();
    final pool = List<int>.generate(12, (i) => i);
    final chosen = <int>[];
    for (var i = 0; i < 3; i++) {
      chosen.add(pool.removeAt(random.nextInt(pool.length)));
    }
    chosen.sort();

    for (final controller in _answers.values) {
      controller.dispose();
    }
    _answers.clear();
    _quizIndexes = chosen;
    for (final i in chosen) {
      _answers[i] = TextEditingController();
    }
  }

  /// Moves to the check, with a new question every time. **ISSUE 16.**
  void _goToConfirm() {
    setState(() {
      _error = null;
      _rollQuiz();
      _step = _Step.confirm;
    });
  }

  /// Copies the twelve words, briefly. **ISSUE 16.**
  ///
  /// *"Add an option to copy Backup phrase — just make sure the user has
  /// written it down somewhere."* The clipboard is the least private place on
  /// the phone, so this is marked sensitive so Android does not preview it, and
  /// it is wiped after a minute — but only if the clipboard is still ours. See
  /// `SecureClipboard`.
  Future<void> _copyPhrase() async {
    final words = _words;
    if (words == null) return;
    final ok = await SecureClipboard.copyBriefly(words.join(' '));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? L.of(context).onboardCopied
          : L.of(context).onboardCopyFailed),
    ));
  }

  /// What this phone can do about fingerprints, learned once.
  ///
  /// **His "one more notable change", 24 August 2026:** *"If the mobile
  /// supports fingerprint or face ID? Please set it up from the very beginning
  /// the app is set up! Don't make it tedious that a user needs to go to the
  /// setting and find that! Make it possible from the very start!"*
  ///
  /// He is right, and the reasoning behind burying it was weak. Fingerprint
  /// unlock was in Settings under "Locking and security" because onboarding was
  /// already four screens about security and a fifth felt like a lot. But the
  /// person who most needs this is the one who has just typed a long passphrase
  /// twice and is about to type it every time they open the app for a month
  /// before discovering there was an easier way in Settings all along.
  BiometricStatus _biometrics = BiometricStatus.unavailable;

  /// Whether it was turned on here, so the last screen can confirm it rather
  /// than leaving somebody wondering whether the prompt they just answered did
  /// anything.
  bool _fingerprintOn = false;

  void _checkQuiz() {
    for (final i in _quizIndexes) {
      if (_answers[i]!.text.trim().toLowerCase() != _words![i]) {
        setState(() => _error = L.of(context).onboardWordWrong(i + 1));
        return;
      }
    }
    setState(() {
      _error = null;
      // The fingerprint offer, but only on a phone that can actually do it —
      // a screen that says "your phone does not support this" is a screen that
      // wasted somebody's time. See [_biometrics].
      _step = _biometrics.usable ? _Step.fingerprint : _Step.name;
    });
  }

  /// Turns it on, here, at the moment the passphrase is still fresh.
  Future<void> _enableFingerprint() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.vault.enableBiometricUnlock();
      if (!mounted) return;
      setState(() {
        _fingerprintOn = true;
        _step = _Step.name;
      });
    } catch (e) {
      // Cancelling the system prompt is not a failure and must not read as
      // one — it is somebody deciding no, which is the whole point of the
      // screen having a Skip.
      // Cancelling the system prompt arrives here too. Neither is worth a
      // frightening sentence: the vault is made, the words are written down,
      // and this was optional.
      if (mounted) {
        setState(() => _error = e is BiometricFailure
            ? e.message
            : L.of(context).onboardFingerprintFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Padding(
          // 24, not 16. Defaults look like defaults.
          padding: const EdgeInsets.symmetric(horizontal: Space.x6),
          child: switch (_step) {
            _Step.language => _languageStep(context),
            _Step.promise => _promise(context),
            _Step.passcode => _passcodeStep(context),
            _Step.phrase => _phraseStep(context),
            _Step.confirm => _confirmStep(context),
            _Step.fingerprint => _fingerprintStep(context),
            _Step.name => _nameStep(context),
          },
        ),
      ),
    );
  }

  // ── Screen 0 — which language ─────────────────────────────────────────────

  /// The list, each language written in itself.
  ///
  /// `Español`, not `Spanish`; `العربية`, not `Arabic`. Somebody looking for
  /// their own language is scanning for the shape of their own word, and they
  /// may well not read the language the app is currently in — which is exactly
  /// why they are on this screen. The reasoning is `kLanguages`' own and it is
  /// the reason this screen can be first at all.
  ///
  /// The system row is at the top and is a real choice rather than a way out:
  /// most people want the phone's language, and choosing it explicitly is one
  /// tap rather than a decision to be made again later.
  Widget _languageStep(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final l = L.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Space.x8),
        const LampMark(size: 56),
        const SizedBox(height: Space.x6),
        Text(l.settingsLanguage, style: t.displaySmall),
        const SizedBox(height: Space.x2),
        Text(
          l.settingsLanguageNote,
          style: t.bodyMedium?.copyWith(color: c.inkSecondary),
        ),
        const SizedBox(height: Space.x6),
        // Scrolls, because eleven rows plus a heading does not fit a short
        // window at 200% text — and this is the one screen nobody can read
        // their way out of if it overflows.
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: Space.x8),
            itemCount: kLanguages.length,
            itemBuilder: (context, i) {
              final entry = kLanguages[i];
              final system = entry.locale == null;
              return InkWell(
                borderRadius: BorderRadius.circular(Radii.md),
                onTap: () {
                  // Written before the step changes, so the next screen is
                  // already drawn in the language just chosen. `AppSettings`
                  // notifies, and `LamplightApp` listens, so the whole app
                  // follows without anything being passed down.
                  widget.settings.locale = entry.locale;
                  setState(() => _step = _Step.promise);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: Space.x4, horizontal: Space.x2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              system ? l.settingsLanguageSystem : entry.name,
                              style: t.titleMedium,
                            ),
                            // The English name underneath, for somebody who
                            // recognises "Korean" but not 한국어 — a parent
                            // setting a phone up for somebody else, which is
                            // most of how this app will first be opened.
                            if (!system && entry.english != entry.name)
                              Text(
                                entry.english,
                                style: t.bodySmall
                                    ?.copyWith(color: c.inkSecondary),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: c.inkMuted),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Screen 1 ───────────────────────────────────────────────────────────────

  Widget _promise(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    // Four lines. Exactly the four in UX-FLOWS.md, unsoftened.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LampMark(size: 72),
        const SizedBox(height: Space.x8),
        Text(L.of(context).onboardNoAccount, style: t.displaySmall),
        const SizedBox(height: Space.x8),
        Text(
          L.of(context).onboardPromiseBody,
          style: t.bodyLarge?.copyWith(color: c.inkSecondary),
        ),
        const SizedBox(height: Space.x10),
        _PrimaryButton(
          label: L.of(context).onboardBegin,
          onPressed: () => setState(() => _step = _Step.passcode),
        ),
        const SizedBox(height: Space.x2),
        // `UX-FLOWS.md` flow 6 step 1: a small link under Begin, on the *very
        // first screen*. It has to be here rather than in settings, because the
        // person who needs it is holding a new phone and has no vault to open
        // settings from. Small, because most people are not restoring.
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RestoreScreen(vault: widget.vault),
              ),
            ),
            child: Text(L.of(context).onboardHaveBackup,
                style: TextStyle(color: c.inkSecondary)),
          ),
        ),
      ],
    );
  }

  // ── Screen 2 ───────────────────────────────────────────────────────────────

  Widget _passcodeStep(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return ListView(
      children: [
        const SizedBox(height: Space.x10),
        Text(L.of(context).onboardSetPasscode, style: t.displaySmall),
        const SizedBox(height: Space.x4),
        Text(
          L.of(context).onboardPasscodeBody,
          style: t.bodyLarge?.copyWith(color: c.inkSecondary),
        ),
        const SizedBox(height: Space.x8),
        _Field(
          controller: _passcode,
          label: L.of(context).onboardPasscodeLabel,
          obscure: true,
        ),
        // Live, as it is typed. A rule you only find out about after pressing
        // Continue is a rule you meet by trial and error.
        PasscodeMeter(
          passcode: _passcode.text,
          confirm: _confirmPasscode.text,
        ),
        const SizedBox(height: Space.x4),
        _Field(
          controller: _confirmPasscode,
          label: L.of(context).onboardPasscodeAgain,
          obscure: true,
        ),
        if (_error != null) ...[
          const SizedBox(height: Space.x4),
          _ErrorText(_error!),
        ],
        const SizedBox(height: Space.x8),
        _PrimaryButton(
          label: _busy
              ? L.of(context).onboardSettingUp
              : L.of(context).onboardContinue,
          // Off until it can actually succeed. Same reasoning as the lock
          // screen: a button that runs and then refuses is worse than one
          // that says it is not ready.
          onPressed: _busy || !_passcodeReady ? null : _createVault,
        ),
      ],
    );
  }

  // ── Screen 3 ───────────────────────────────────────────────────────────────

  Widget _phraseStep(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final words = _words!;
    return ListView(
      children: [
        const SizedBox(height: Space.x10),
        Text(L.of(context).onboardWriteWords, style: t.displaySmall),
        const SizedBox(height: Space.x6),
        // Two columns, numbered, monospaced-ish spacing so they are easy to
        // copy by hand without losing your place.
        Container(
          padding: const EdgeInsets.all(Space.x4),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          // == THE READING ORDER, AND IT IS NOT COSMETIC. 3 Sept 2026 =====
          //
          // Found by driving onboarding on the tablet: the words are drawn in
          // two columns, 1-6 on the left and 7-12 on the right, and the
          // accessibility tree read them **row-major** - lake, grape, boil,
          // alley, siren, poet - which is word 1, then word **7**, then word
          // 2, then word 8.
          //
          // Flutter sorts a `Row`'s semantics by position, and two columns
          // side by side fall into horizontal bands, so it pairs them off. It
          // looks right and reads wrong.
          //
          // **Somebody using TalkBack would write the twelve words down in
          // that order, and the phrase would be useless.** They would not find
          // out on the day they wrote it. They would find out on the day they
          // had forgotten their passcode and this was the only way back into
          // their journal - which is precisely the moment this feature exists
          // for, and the one time it must not have been quietly wrong for
          // months.
          //
          // It also caught me: I read the tree, believed word 5 was `siren`,
          // and the quiz refused it, because word 5 on screen is `similar`.
          // The bug bit its first tester the same way it would bite a user.
          //
          // `OrdinalSortKey` states the order explicitly rather than leaving
          // it to geometry: the whole left column, then the whole right one.
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  sortKey: const OrdinalSortKey(0),
                  child: _wordColumn(context, words, 0, 6),
                ),
              ),
              Expanded(
                child: Semantics(
                  sortKey: const OrdinalSortKey(1),
                  child: _wordColumn(context, words, 6, 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.x6),
        Text(
          L.of(context).onboardWordsBody,
          style: t.bodyLarge?.copyWith(color: c.inkSecondary),
        ),
        const SizedBox(height: Space.x8),
        _PrimaryButton(
          // ISSUE 16 — a different three words every time this is pressed.
          label: L.of(context).onboardWrittenDown,
          onPressed: _goToConfirm,
        ),
        const SizedBox(height: Space.x3),

        // ── ISSUE 16 — "Add an option to copy backup phrase" ──────────────
        //
        // Secondary, and below the paper button, because paper is still the
        // recommendation and the ordering is the recommendation. It says what
        // it costs on the row itself rather than in a dialog nobody reads: the
        // clipboard is readable by other apps, so the words are marked
        // sensitive — Android shows dots instead of previewing them — and the
        // clipboard is cleared a minute later, but only if it is still ours.
        //
        // `ETHICAL-DESIGN.md` cuts both ways here. Frightening somebody out of
        // using their own password manager would be a dark pattern of its own;
        // so would offering this as though it were free. One sentence, said
        // plainly, and the choice is his.
        Center(
          child: TextButton.icon(
            onPressed: _copyPhrase,
            icon: Icon(Icons.copy_all_outlined, size: 18, color: c.inkSecondary),
            label: Text(
              L.of(context).onboardCopyWords,
              style: TextStyle(color: c.inkSecondary),
            ),
          ),
        ),
        Center(
          child: Text(
            L.of(context).onboardClipboardNote,
            textAlign: TextAlign.center,
            style: t.labelMedium?.copyWith(color: c.inkMuted),
          ),
        ),
        const SizedBox(height: Space.x10),
      ],
    );
  }

  Widget _wordColumn(BuildContext context, List<String> words, int from, int to) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = from; i < to; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.x1),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('${i + 1}',
                      style: t.labelMedium?.copyWith(color: c.inkMuted)),
                ),
                Expanded(
                  child: SelectableText(words[i], style: t.bodyLarge),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Screen 4 ───────────────────────────────────────────────────────────────

  Widget _confirmStep(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return ListView(
      children: [
        const SizedBox(height: Space.x10),
        Text(L.of(context).onboardCheckThree, style: t.displaySmall),
        const SizedBox(height: Space.x4),
        Text(
          L.of(context).onboardCheckBody,
          style: t.bodyLarge?.copyWith(color: c.inkSecondary),
        ),
        const SizedBox(height: Space.x8),
        for (final i in _quizIndexes) ...[
          _Field(
            controller: _answers[i]!,
            label: L.of(context).onboardWordNumber(i + 1),
          ),
          const SizedBox(height: Space.x4),
        ],
        if (_error != null) ...[_ErrorText(_error!), const SizedBox(height: Space.x4)],
        _PrimaryButton(
          label: L.of(context).actionDone,
          onPressed: _checkQuiz,
        ),
        const SizedBox(height: Space.x4),
        TextButton(
          // ISSUE 16. Going back and returning asks about three *different*
          // words — see `_rollQuiz`, and the four screenshots he numbered.
          onPressed: () => setState(() {
            _error = null;
            _step = _Step.phrase;
          }),
          child: Text(L.of(context).onboardShowWords,
              style: TextStyle(color: c.inkSecondary)),
        ),
      ],
    );
  }

  // ── Screen 5 ───────────────────────────────────────────────────────────

  /// The fingerprint, offered at the start rather than buried in Settings.
  ///
  /// **His instruction, 24 August 2026:** *"If the mobile supports fingerprint
  /// or face ID? Please set it up from the very beginning the app is set up!
  /// Don't make it tedious that a user needs to go to the setting and find
  /// that! Make it possible from the very start!"*
  ///
  /// The old reasoning for burying it was that onboarding was already four
  /// screens about security and a fifth felt like a lot. That is a designer's
  /// worry, not a user's. The person it costs is the one who has just typed a
  /// long passphrase twice and is about to type it every time they open the app
  /// for a month before finding the switch.
  ///
  /// **It is skippable and the skip is not hidden.** `ETHICAL-DESIGN.md`
  /// forbids making the safe answer the hard one, and there is a real argument
  /// for saying no here: a fingerprint is easier to compel than a passphrase.
  /// So Skip sits directly under the button, at the same size, in the same
  /// position it has on the next screen.
  ///
  /// The wording is the same promise the Settings row makes, because it is the
  /// same feature and two descriptions of one thing is how a person ends up
  /// trusting neither.
  Widget _fingerprintStep(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return ListView(
      children: [
        const SizedBox(height: Space.x10),
        Text(L.of(context).onboardFingerprintTitle, style: t.displaySmall),
        const SizedBox(height: Space.x4),
        Text(
          L.of(context).onboardFingerprintBody,
          style: t.bodyLarge?.copyWith(color: c.inkSecondary),
        ),
        const SizedBox(height: Space.x6),
        Container(
          padding: const EdgeInsets.all(Space.x4),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.fingerprint, size: 22, color: c.accent),
              const SizedBox(width: Space.x3),
              Expanded(
                child: Text(
                  L.of(context).onboardFingerprintExplain,
                  style: t.bodyLarge?.copyWith(color: c.inkSecondary),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: Space.x4),
          _ErrorText(_error!),
        ],
        const SizedBox(height: Space.x8),
        _PrimaryButton(
          label: _busy
              ? L.of(context).onboardFingerprintWaiting
              : L.of(context).onboardFingerprintUse,
          onPressed: _busy ? null : _enableFingerprint,
        ),
        const SizedBox(height: Space.x2),
        Center(
          child: TextButton(
            onPressed: _busy ? null : () => setState(() {
              _error = null;
              _step = _Step.name;
            }),
            child: Text(L.of(context).actionNotNow,
                style: TextStyle(color: c.inkSecondary)),
          ),
        ),
        const SizedBox(height: Space.x10),
      ],
    );
  }

  // ── Screen 6 ───────────────────────────────────────────────────────────

  /// The skippable local profile.
  ///
  /// `UX-FLOWS.md` flow 1 screen 4 specified this and it was never built. It
  /// exists for one reason and it is not personalisation in the marketing
  /// sense: **the four screens before this one are all about security**, and
  /// ending an onboarding on a passphrase quiz leaves the app feeling like a
  /// safe rather than like a room. One friendly question closes it properly.
  ///
  /// It is genuinely skippable. Skip is the same size as Continue, sits beside
  /// it, and nothing anywhere in the app is gated on having answered. The name
  /// goes in a preferences file on this phone and there is nowhere for it to
  /// go from there.
  Widget _nameStep(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return ListView(
      children: [
        const SizedBox(height: Space.x10),
        Text(L.of(context).onboardOneLastThing, style: t.displaySmall),
        const SizedBox(height: Space.x4),
        Text(
          L.of(context).onboardNameBody,
          style: t.bodyLarge?.copyWith(color: c.inkSecondary),
        ),
        if (_fingerprintOn) ...[
          const SizedBox(height: Space.x4),
          Row(
            children: [
              Icon(Icons.fingerprint, size: 18, color: c.accent),
              const SizedBox(width: Space.x2),
              Expanded(
                child: Text(
                  L.of(context).onboardFingerprintOn,
                  style: t.labelMedium?.copyWith(color: c.inkMuted),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: Space.x8),
        _Field(controller: _name, label: L.of(context).onboardYourName),
        const SizedBox(height: Space.x8),
        _PrimaryButton(
          label: L.of(context).onboardStartWriting,
          onPressed: () {
            widget.settings.displayName = _name.text;
            widget.onDone();
          },
        ),
        const SizedBox(height: Space.x2),
        Center(
          child: TextButton(
            onPressed: widget.onDone,
            child: Text(L.of(context).onboardSkip,
                style: TextStyle(color: c.inkSecondary)),
          ),
        ),
      ],
    );
  }
}

// ── Shared plain controls ────────────────────────────────────────────────────
// No cards, no shadows. Depth comes from surface colour steps.

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    return SizedBox(
      // The accessibility floor, and also just correct.
      height: kMinTouchTarget,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.canvas,
          disabledBackgroundColor: c.raised,
          disabledForegroundColor: c.inkMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    // == THE FIELD HAD NO ACCESSIBLE NAME. 3 September 2026 =================
    //
    // Found by driving onboarding on the tablet and reading the accessibility
    // tree, which is the only way this could have been found - it is invisible
    // on screen, where the floating label is right there in front of you.
    //
    // `uiautomator` reported all three recovery-phrase fields as
    // **`NAF="true"`** - Android's own "Not Accessibility Friendly" - with
    // `content-desc=""` and `text=""`. `InputDecoration.labelText` draws the
    // label but did not put it in the semantics tree here, so a screen reader
    // announces three unnamed edit boxes under the heading "Check three of
    // them" and there is no way to learn *which* three.
    //
    // **That screen cannot be skipped.** You cannot create a vault without
    // passing the quiz, so this was a lockout for anybody using TalkBack -
    // exactly the fault round twelve fixed for language, in the same flow, for
    // the same reason. `ACCESSIBILITY.md` targets WCAG AA and this fails 3.3.2
    // and 4.1.2.
    //
    // `Semantics(textField: true, label:)` states the name explicitly rather
    // than hoping the decoration exports it. `_Field` is also the passcode and
    // confirmation field on the previous screen, so one wrapper fixes five
    // fields across two screens - all of them on the way in.
    // `MergeSemantics`, not a bare `Semantics` wrapper - and the difference
    // is the whole fix. A wrapper adds a *parent* node carrying the label and
    // leaves the field's own node beside it, still unnamed; `uiautomator` then
    // reports exactly what it reported before, because it reads the leaf.
    // Merging folds the two into one node, so the edit box itself is what
    // carries the name. Verified by re-reading the tree on the tablet rather
    // than by reasoning about it, because reasoning about it is what produced
    // the wrapper.
    return MergeSemantics(
      child: Semantics(
        textField: true,
        label: label,
        child: _bare(context, c),
      ),
    );
  }

  Widget _bare(BuildContext context, LamplightColors c) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: Theme.of(context).textTheme.bodyLarge,
      autocorrect: false,
      enableSuggestions: false,
      // Keyboards learn what you type. A passcode or a recovery word must not
      // end up in a third-party keyboard's dictionary — THREAT-MODEL.md admits
      // we cannot control what the keyboard does, so we at least ask.
      keyboardType: obscure ? TextInputType.visiblePassword : TextInputType.text,
      inputFormatters: obscure ? null : [FilteringTextInputFormatter.singleLineFormatter],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: c.inkMuted),
        filled: true,
        fillColor: c.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: c.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: c.accent, width: 2),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    // Colour is never the only channel — ACCESSIBILITY.md. The icon carries the
    // same meaning for anyone who cannot see the red.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: 18, color: c.danger),
        const SizedBox(width: Space.x2),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c.danger),
          ),
        ),
      ],
    );
  }
}
