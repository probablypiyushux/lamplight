/// Turning an exception into something a person can act on.
///
/// ── THE WORDING RULE FOR THE WHOLE APP ──────────────────────────────────────
///
/// **Say what happened and what to do. Never say how it works.**
///
/// This is `PLAN.md` §7.0-C-i — round eight's ISSUE 10 — and round nine's
/// ISSUE 16 restated it in the strongest terms he has used about anything:
///
/// > *"No user should ever be so much traumatised by knowing the underroots of
/// > the technology of the app he is using."*
///
/// …followed by Nielsen's second heuristic, the black-box principle, and
/// Weiser. What set him off was not a philosophical objection. It was a real
/// screen: every backup was failing (ISSUE 2) and the app answered with a page
/// and a half of `Instance of 'SingleChildRenderObjectElement' (from
/// package:flutter/src/widgets/framework.dart)`, scrolled past the bottom of a
/// tablet, three screenshots long. His note reads: *"If backup is not possible
/// just give a fucking simple error. What the fuck you think that the user will
/// come and repair the shit we made?"*
///
/// He is right, and the second sentence is the whole argument. Everything in a
/// raw exception is addressed to somebody who can change the code. Showing it
/// to somebody who cannot is not transparency, it is passing them a bill they
/// have no way to pay.
///
/// ── WHY THIS IS ONE FUNCTION AND NOT FIFTEEN ────────────────────────────────
///
/// There were fifteen `'$e'`s in `lib/` when this was written, each in its own
/// screen, each written by somebody who meant to come back to it. Fifteen
/// places is fifteen chances, and the count only ever goes up. So there is one
/// function, every screen calls it, and
/// `test/widget/no_machinery_reaches_the_user_test.dart` reads the source of
/// `lib/` and fails if a new raw interpolation appears in a `_error` field.
///
/// ── WHAT STILL GETS THROUGH, AND WHY THAT IS NOT A LOOPHOLE ─────────────────
///
/// The app raises its own exceptions with human sentences in them — *"This
/// backup does not contain a vault."*, *"That passcode is not right."* Those
/// are the message. They pass.
///
/// The test for "ours" is not a list of types, because a list of types is a
/// thing to forget to update. It is the shape of the text itself: one sentence,
/// short, ending in a full stop, with none of the marks that only ever appear
/// in machine output. **A sentence that would not survive being read aloud to
/// somebody who has never opened a terminal does not survive this function
/// either.**
///
/// Rule 3 of §7.0-C-i is the line and it is worth restating here, because this
/// file is where somebody will come to delete things: *a promise the user is
/// owed stays; a mechanism they are being made to operate goes.* This function
/// only ever removes the second kind. Nothing in it touches the settings
/// screen's honesty about what the app can and cannot see.
library;

import '../l10n/generated/app_localizations.dart';

/// Marks that only ever appear in output written for a programmer.
///
/// Each is here because it was found in something the app actually showed, or
/// in what a plausible platform failure looks like on Android. They are checked
/// case-sensitively on purpose — *"instance"* is an ordinary English word and
/// *"Instance of"* is not.
const List<String> _machineryMarks = <String>[
  'Instance of',
  'package:',
  'dart:',
  'Exception',
  'Error:',
  'PlatformException',
  'MissingPluginException',
  'SendPort',
  'isolate',
  'Isolate',
  '<-',
  '#0',
  'at 0x',
  'errno',
  'EACCES',
  'ENOENT',
  'SQLITE',
  'SqliteException',
  'null)',
  '(OS ',
  'stack trace',
  'Stack trace',
];

/// How Dart's own errors introduce themselves.
///
/// These are the ones with no marks in them at all: `Bad state: Stream has
/// already been listened to.` is short, is one line, ends in a full stop, and
/// would sail through every check above. It reads *almost* like English, which
/// is what makes it worse than a stack trace rather than better — a person
/// reads it, believes it is addressed to them, and finds there is nothing in it
/// they can do anything with.
///
/// Found by the test rather than by inspection, which is the argument for the
/// test: the list above was written by looking at real failures and it still
/// had this hole in it.
const List<String> _machineryOpeners = <String>[
  'Bad state',
  'Invalid argument',
  'RangeError',
  'IndexError',
  'StateError',
  'ArgumentError',
  'NoSuchMethodError',
  'FormatException',
  'Unsupported operation',
  'Concurrent modification',
  'Null check operator',
  'Out of Memory',
  'Stack Overflow',
  'Failed assertion',
  'Assertion failed',
  'Unhandled',
  "type '",
  'Converting object to an encodable object failed',
];

/// The longest a message may be before it stops being a sentence and starts
/// being a dump. Two lines on his tablet.
const int _sentenceLimit = 160;

/// True when [text] reads as something the app wrote for a person.
///
/// Deliberately strict. A false negative costs a generic sentence; a false
/// positive costs what ISSUE 2 cost.
bool isPlainSentence(String text) {
  final t = text.trim();
  if (t.isEmpty) return false;
  if (t.length > _sentenceLimit) return false;
  // Anything the app says to a person is one paragraph. A newline means either
  // a stack trace or a retaining path, and both are machinery.
  if (t.contains('\n')) return false;
  if (!t.endsWith('.') && !t.endsWith('?') && !t.endsWith('!')) return false;
  for (final opener in _machineryOpeners) {
    if (t.startsWith(opener)) return false;
  }
  for (final mark in _machineryMarks) {
    if (t.contains(mark)) return false;
  }
  return true;
}

/// The sentence to show for [error].
///
/// [fallback] is what a person is told when the exception has nothing sayable
/// in it — so write it as the specific thing that failed, in their words:
/// *"The backup could not be saved."*, not *"An error occurred."*
///
/// [andThen] is appended when the fallback is used, and it should say what
/// happens next or what is still true. The default is the one that is almost
/// always both, and it is the sentence that matters most to somebody who has
/// just watched something fail in an app holding their diary.
String plainFailure(
  Object error, {
  required String fallback,
  String andThen = 'Nothing was lost — you can try again.',

  /// The reader's language, when the caller has a `BuildContext` to get it
  /// from. **ROUND FIFTEEN.**
  ///
  /// See [Localisable]. Optional, and null is not a bug: plenty of callers of
  /// this function are background paths with no context, and English is the
  /// right answer there for the same reason a missing ARB key falls back to
  /// English rather than failing the build.
  L? words,
}) {
  if (words != null && error is Localisable) {
    final said = error.describeIn(words);
    if (said.isNotEmpty) return said;
  }
  final own = error is PlainlySaid ? error.plainMessage : '$error';
  if (isPlainSentence(own)) return own;
  return '$fallback $andThen'.trim();
}

/// A length of time, said the way a person would say it.
///
/// **ISSUE 19, round nine, and it is a small thing he was completely right
/// about.**
///
/// > *"If I choose 1 minute — it shows 60 seconds. If I choose 5 minutes — it
/// > shows me 300 seconds. IK they all are logically correct — but why create a
/// > confusion? Make it sound like they just second guessed their choice? Why?"*
///
/// That last sentence is the observation worth keeping. A settings screen that
/// answers *five minutes* with **300 seconds** is not merely being pedantic —
/// it reads as a *correction*, as though the app has quietly restated what you
/// picked in terms it prefers, and the effect is to make you doubt that it
/// understood. The value shown on a tile should be the words the user chose,
/// because the tile's job is to confirm the choice, not to convert it.
///
/// [zero] is what to say for `Duration.zero`, which means something different
/// in every setting that uses it — *Never*, *Always ask*, *Off*.
String humanDuration(Duration d, {String zero = 'Never'}) {
  if (d == Duration.zero) return zero;
  if (d.inSeconds < 60) return '${d.inSeconds} seconds';
  // Only whole minutes ever appear in this app's choices, so a remainder means
  // somebody has added an option and not thought about how it reads. Seconds is
  // the honest fallback rather than a rounded lie.
  if (d.inSeconds % 60 != 0) return '${d.inSeconds} seconds';
  final minutes = d.inMinutes;
  if (minutes == 1) return '1 minute';
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return hours == 1 ? '1 hour' : '$hours hours';
  }
  return '$minutes minutes';
}

/// Implemented by the app's own exceptions, so they are never guessed at.
///
/// The shape check above is the safety net for everything else — platform
/// exceptions, framework assertions, anything a package throws. This is the
/// front door: a type that says what it means to a person says so here, and
/// then it does not depend on ending with a full stop to be treated as English.
abstract class PlainlySaid {
  /// One sentence, addressed to the person holding the phone.
  String get plainMessage;
}

/// An exception that can say itself in the reader's language.
///
/// ══ WHY THIS EXISTS BESIDE [PlainlySaid] RATHER THAN REPLACING IT ═══════════
///
/// [PlainlySaid] is about *tone* — an exception carrying a sentence a person can
/// act on rather than a class name. This is about *language*, and the two are
/// separate problems with separate answers.
///
/// The sentences that most need translating are the ones thrown from `core/`:
/// what the app says when a **backup or a restore fails**. Somebody reading
/// Lamplight in Hindi does not switch to English at the moment their notes are
/// at stake. But `core/` has no `BuildContext` and must not grow one —
/// `vault_file.dart` runs inside isolates, from background paths, and from
/// tests with no widget tree at all.
///
/// So the exception carries **what went wrong**, as a key, and the screen —
/// which has a context — decides how to say it. The English sentence stays on
/// the exception as well: it is what the tests assert against, what `assert`s
/// print, and the fallback for a caller with no `L` in hand.
///
/// `BackupProblem` in `core/backup/vault_file.dart` is the worked example.
abstract interface class Localisable {
  /// The same failure, in [l]'s language.
  String describeIn(L l);
}
