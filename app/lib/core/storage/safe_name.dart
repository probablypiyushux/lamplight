/// One place where a filename from outside the app is made safe.
///
/// ══ WHY THIS EXISTS, AND WHY IT IS AT THE INLET ═════════════════════════════
///
/// He asked on 28 August 2026 for every way *into* the app to be treated as
/// hostile:
///
/// > *"Every inlet should be top focus now! inlet means? for example an hacker
/// > can use inlet to get in! the way i upload photos, videos, documents those
/// > can be corrupted! ... secure the inlet!"*
///
/// A filename is the part of an imported file that Lamplight actually *uses*.
/// The bytes are encrypted and never interpreted; the name is stored, shown on
/// screen, written into the readable export, and turned into a real path when a
/// file is handed to another app. So it is the piece of attacker-controlled
/// data with the widest reach, and it arrives from a document picker, which got
/// it from some other app, which may have got it from anywhere.
///
/// **Before this, cleaning happened at the exits.** `plain_export.dart` had one
/// regex and `hand_off.dart` had a different one, each cleaning the name again
/// on the way out, with slightly different rules. That is the shape of defence
/// that eventually loses: every new consumer has to remember, and the one that
/// forgets is the bug. `vault_file.dart` already says it in as many words —
/// *"sanitising is a game you can lose"*.
///
/// So the name is cleaned **once, on the way in**, and stored clean. The exits
/// still clean — they call this too — because defence in depth costs a function
/// call and because rows written before this existed are still in people's
/// vaults.
///
/// ══ WHAT IS DELIBERATELY NOT CLAIMED ════════════════════════════════════════
///
/// This does not make a malicious *file* safe. Nothing here inspects bytes. It
/// makes a malicious *name* inert, which is a different and much more tractable
/// problem. The bytes are protected by never being parsed by Lamplight at all:
/// they are encrypted on arrival and only ever handed back to the platform's
/// own decoders. `CLAUDE.md` rule 2 and the removal of the last native code on
/// 28 August are what carry that half.
library;

/// The longest name kept, in UTF-16 code units.
///
/// Filesystems vary: ext4 allows 255 **bytes**, so a 255-character name in
/// Devanagari or Chinese is already too long at three bytes a character. 120 is
/// short enough to survive that everywhere, and long enough that nobody's real
/// filename is cut.
const int kMaxNameLength = 120;

/// Windows device names, which are reserved at every level of a path.
///
/// A file called `CON.txt` on a Windows machine is not a file — the OS
/// intercepts it. The readable export writes into a folder the user chooses,
/// and that folder is very often synced to a desktop, so this is not
/// hypothetical for a phone app.
const Set<String> _windowsReserved = {
  'CON', 'PRN', 'AUX', 'NUL',
  'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
  'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9',
};

/// Characters that reorder how the *rest* of a string is drawn.
///
/// ══ THE ONE ATTACK HERE THAT IS ABOUT DECEIVING A PERSON ═══════════════════
///
/// U+202E RIGHT-TO-LEFT OVERRIDE and its relatives make text after them render
/// backwards. The classic use is a filename: put one before `gnp.exe` and it is
/// drawn as `exe.png`. Somebody looking at the row sees a photograph and taps
/// "Open with", and the file that leaves is an executable.
///
/// Lamplight shows `originalName` under an entry, in search results, and in the
/// chooser when a file is handed to another app — three places where a person
/// decides what something is by reading its name. Stripping these is the only
/// defence, because there is no way to render the name both faithfully and
/// safely.
///
/// **Not stripped from anything the user writes.** This is for filenames only.
/// Arabic and Hebrew entries need the bidi algorithm and it works on its own;
/// these are the explicit *overrides*, which nothing legitimate puts in a
/// filename.
final RegExp _bidiOverrides = RegExp(
  // Written as escapes, not as the characters themselves. The analyzer objects
  // to literal bidi controls in source for exactly the reason this list exists:
  // they make code render differently from how it compiles, which is the same
  // trick aimed at a reviewer instead of at a user.
  //
  // U+202A..U+202E  the embedding and override pair, RLO among them
  // U+2066..U+2069  the isolates, which do the same thing with cleaner scoping
  // U+200E, U+200F  the left-to-right and right-to-left marks
  '[\u202a-\u202e\u2066-\u2069\u200e\u200f]',
);

/// Everything that is a path separator, a shell metacharacter on some platform,
/// or a control character. `\x00` is the one that matters most: a NUL truncates
/// a string in every C API underneath, so `safe.txt\x00.exe` is two different
/// names depending on who is reading it.
final RegExp _unsafeChars = RegExp(r'[\\/:*?"<>|\x00-\x1f\x7f]');

/// Makes [raw] safe to store, display, and turn into a path.
///
/// Never throws and never returns an empty string — [fallback] is used when
/// nothing usable survives, because every caller needs *a* name and a caller
/// that has to handle null will eventually handle it by writing `null` into a
/// path.
String safeFileName(String raw, {String fallback = 'file'}) {
  var name = raw;

  // 1. Reordering characters, before anything else looks at the string. Doing
  //    this first means every rule below sees the name as it will be drawn.
  name = name.replaceAll(_bidiOverrides, '');

  // 2. Path separators, control characters, NUL.
  name = name.replaceAll(_unsafeChars, '_');

  // 3. Leading dots hide a file on every Unix-like system, which for an export
  //    folder means somebody's attachment silently vanishing from view. And
  //    trailing dots and spaces are stripped by Windows when it creates a file,
  //    so `report.` and `report` become one file — the second attachment
  //    overwrites the first and nothing is said about it.
  //
  //    **Both happen before the `..` collapse below, and the order is load
  //    bearing.** Collapsing first turned `report...` into `report_.` and then
  //    into `report_`, inventing a character that was never in the name.
  name = name.replaceAll(RegExp(r'^[.\s]+'), '');
  name = name.replaceAll(RegExp(r'[.\s]+$'), '');

  // 4. Traversal. Already impossible without a separator, and removed anyway:
  //    `..` in the middle of a name is never meaningful and its presence is a
  //    signal rather than a coincidence.
  while (name.contains('..')) {
    name = name.replaceAll('..', '_');
  }

  // 6. Length, keeping the extension, because the extension is what tells the
  //    next app how to open it.
  if (name.length > kMaxNameLength) {
    final dot = name.lastIndexOf('.');
    if (dot > 0 && name.length - dot <= 12) {
      final ext = name.substring(dot);
      name = name.substring(0, kMaxNameLength - ext.length) + ext;
    } else {
      name = name.substring(0, kMaxNameLength);
    }
  }

  if (name.isEmpty || name == '_') return fallback;

  // 7. Windows device names, checked on the stem so `CON.txt` is caught too.
  final stem = name.contains('.') ? name.substring(0, name.indexOf('.')) : name;
  if (_windowsReserved.contains(stem.toUpperCase())) {
    name = '_$name';
  }

  return name;
}

/// Whether [raw] would be changed by [safeFileName].
///
/// For tests and for the leak scan, which wants to assert that what is stored
/// is already clean rather than that it can be cleaned later.
bool isSafeFileName(String raw) => raw.isNotEmpty && safeFileName(raw) == raw;
