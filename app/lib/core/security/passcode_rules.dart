import '../../l10n/generated/app_localizations.dart';

/// What makes a passcode acceptable, and why the bar is where it is.
///
/// ── THE ARGUMENT FOR A MINIMUM AT ALL ────────────────────────────────────
///
/// There was no minimum. A one-character passcode was accepted, silently, and
/// the vault it produced was as unopenable as the passcode was guessable —
/// which is to say, not at all. Argon2id at 256 MiB makes each guess cost a
/// quarter of a second and 256 MiB of RAM; against a four-digit PIN that is ten
/// thousand guesses, which is under an hour on the phone itself. The key
/// derivation is doing its job perfectly and there is simply not enough to
/// derive from.
///
/// ── WHY EIGHT, AND WHY NOT MORE ──────────────────────────────────────────
///
/// Eight characters was asked for and eight characters is right, but not for
/// the usual reason. The reason is not entropy per character — it is that eight
/// is where people stop reaching for a PIN and start reaching for a **phrase**,
/// and a four-word phrase is worth more than any twelve-character password
/// somebody will actually remember. The rules below push towards that: length
/// is what is rewarded, and nothing here demands a capital letter or a symbol.
///
/// ── WHY THERE IS NO "MUST CONTAIN A NUMBER AND A SYMBOL" ─────────────────
///
/// Because it makes passwords worse, and this has been the documented position
/// of NIST since SP 800-63B in 2017. Composition rules do not produce random
/// passwords, they produce `Password1!` — the same weak stem with the same
/// predictable decorations, which every cracking dictionary has generated for
/// twenty years. What they reliably do produce is a password the user cannot
/// remember, which they then write down or reuse.
///
/// So: **length is the only hard rule.** Everything else here is advice shown
/// while typing, never a refusal.
///
/// One more thing is refused, and it is the one that matters more than any
/// composition rule: a passcode from the short list of the ones everybody
/// picks. `password`, `12345678`, `qwertyui`. Those are not weak because of
/// their shape; they are weak because they are the first thing tried.
abstract final class PasscodeRules {
  /// The floor. Eight.
  static const int minimumLength = 8;

  /// Where the advice stops nagging. A passcode this long is fine whatever
  /// else is true about it.
  static const int comfortableLength = 14;

  /// The reasons a passcode is refused. Empty means it is accepted.
  ///
  /// Note the shape: this returns **what to do**, not what is wrong. "Eight
  /// characters or more" is actionable; "passcode does not meet complexity
  /// requirements" is a wall with no door in it.
  /// ── WHY THIS TAKES AN [L] AND NOT A [BuildContext] ────────────────────
  ///
  /// These four sentences are shown to somebody who is **setting up their
  /// vault** — the first screen of the app and the one place where an English
  /// literal is a lockout rather than untidiness. They were English literals
  /// until 29 August 2026, so onboarding leaked English in all nine other
  /// languages through this one call, which is exactly the failure
  /// `l10n/README.md` says onboarding was done first to avoid.
  ///
  /// It takes the localisations object rather than a context because this file
  /// is in `core/` and has no business importing the widget layer — the same
  /// line `app_settings.dart` draws. Both callers already have a context and
  /// pass `L.of(context)`.
  static List<String> problems(String passcode, L l) {
    final problems = <String>[];
    if (passcode.length < minimumLength) {
      final short = minimumLength - passcode.length;
      // A plural rather than `short == 1 ? … : …`: "one" is not a category
      // every language has, and Arabic has six. See l10n/README.md.
      problems.add(short == 1
          ? l.passcodeOneMoreCharacter
          : l.passcodeMoreCharacters(short, minimumLength));
    }
    if (_tooCommon(passcode)) {
      // Named plainly. "Too common" is vague; saying it is one of the first
      // things anybody would try explains the actual risk in six words.
      problems.add(l.passcodeTooObvious);
    }
    if (passcode.isNotEmpty && _allSameCharacter(passcode)) {
      problems.add(l.passcodeSameCharacter);
    }
    if (_isRun(passcode)) {
      problems.add(l.passcodeStraightRun);
    }
    return problems;
  }

  /// Whether the passcode is allowed at all.
  ///
  /// Deliberately does **not** take an [L]: it asks a yes/no question about the
  /// passcode and never shows a sentence, so making it need the localisations
  /// would be asking every caller for words none of them display. The rules it
  /// applies are the same ones [problems] explains.
  static bool accepts(String passcode) =>
      passcode.length >= minimumLength &&
      !_tooCommon(passcode) &&
      !(passcode.isNotEmpty && _allSameCharacter(passcode)) &&
      !_isRun(passcode);

  /// A rough, honest description of how much work it is worth.
  ///
  /// **Not a percentage and not a coloured bar with five segments**, both of
  /// which imply a precision nobody has. It is four words, and the words say
  /// what they mean.
  static PasscodeStrength strengthOf(String passcode) {
    if (passcode.length < minimumLength) return PasscodeStrength.tooShort;
    if (_tooCommon(passcode) || _allSameCharacter(passcode) || _isRun(passcode)) {
      return PasscodeStrength.guessable;
    }
    // Words beat characters. Three or more separated words is a passphrase and
    // is worth more than a shorter string with punctuation in it, so it is
    // counted first.
    final words = passcode.trim().split(RegExp(r'\s+')).where((w) => w.length > 2);
    if (words.length >= 4) return PasscodeStrength.strong;
    if (passcode.length >= comfortableLength) return PasscodeStrength.strong;
    if (words.length >= 3 || passcode.length >= 11) return PasscodeStrength.good;
    return PasscodeStrength.fair;
  }

  static bool _allSameCharacter(String s) =>
      s.isNotEmpty && s.split('').every((c) => c == s[0]);

  /// `12345678`, `abcdefgh`, and the same backwards.
  static bool _isRun(String s) {
    if (s.length < minimumLength) return false;
    var ascending = true;
    var descending = true;
    for (var i = 1; i < s.length; i++) {
      final step = s.codeUnitAt(i) - s.codeUnitAt(i - 1);
      if (step != 1) ascending = false;
      if (step != -1) descending = false;
    }
    return ascending || descending;
  }

  /// The short list.
  ///
  /// Deliberately short. A real breach corpus is millions of entries and
  /// several megabytes, and shipping one would be a large asset in an app that
  /// prides itself on carrying nothing. These are the ones that appear at the
  /// top of every such list, and the marginal value of entry ten thousand is
  /// close to zero once the length floor is in place — a common password long
  /// enough to pass the floor is already an unusual choice.
  static bool _tooCommon(String passcode) {
    final lower = passcode.toLowerCase().trim();
    return _common.contains(lower);
  }

  static const Set<String> _common = {
    '12345678', '123456789', '1234567890', 'password', 'password1',
    'password123', 'qwertyui', 'qwerty123', 'iloveyou', 'princess',
    'sunshine', 'football', 'baseball', 'trustno1', 'superman',
    'starwars', 'whatever', 'computer', 'michelle', 'jennifer',
    'jordan23', 'letmein1', 'welcome1', 'monkey12', 'abcd1234',
    'abc12345', '11111111', '00000000', 'asdfghjk', 'zxcvbnm1',
    '1qaz2wsx', 'qazwsxedc', 'admin123', 'passw0rd', 'p@ssw0rd',
    'lamplight', 'myjournal', 'mydiary1', 'secret12',
  };
}

enum PasscodeStrength {
  tooShort('Too short', 0),
  guessable('Easy to guess', 1),
  fair('Fine', 2),
  good('Good', 3),
  strong('Strong', 4);

  const PasscodeStrength(this.label, this.rank);

  final String label;
  final int rank;

  bool get acceptable => rank >= fair.rank;
}
