import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/platform/capture.dart';
import '../l10n/generated/app_localizations.dart';
import 'tokens.dart';

/// A link somebody wrote in their own journal. **ROUND FIFTEEN, ISSUE 11.**
///
/// > *"if a text has a link – I want you to make that link look like a link
/// > text and works like a link if I tap that opens! (here text I mean is the
/// > text written by user)"*
///
/// ── WHAT IS TREATED AS A LINK, AND WHY THE LIST IS SHORT ────────────────
///
/// `https://`, `http://`, and a run beginning `www.`. Nothing else.
///
/// The temptation is to recognise bare domains too — `bbc.co.uk` reads like a
/// link to a person and it is one. It is not done, for a reason that only
/// shows up in a journal: **an ordinary sentence is full of things that look
/// like domains.** "e.g." and "i.e." are the obvious ones; so is any sentence
/// where somebody forgot a space after a full stop, which is most people, most
/// of the time. Every one of those would come back underlined and coloured in
/// the middle of a paragraph about their day. A link that is missed costs a
/// tap; a paragraph speckled with false links costs the page.
///
/// ── AND WHAT YOU SEE IS WHERE YOU GO ────────────────────────────────────
///
/// There is deliberately **no support for a link with different text on it** —
/// no Markdown, no HTML. The visible characters *are* the destination, always.
/// That is a security property rather than a simplification: the app has no way
/// to show `your bank` and open somewhere else, so a link pasted in from a
/// message someone was sent cannot lie about where it goes. It also means the
/// app never has to explain itself before following one.
///
/// ── THE APP STILL CANNOT REACH THE NETWORK ──────────────────────────────
///
/// Tapping one calls `Capture.openUrl`, which is `ACTION_VIEW` — Android hands
/// the address to whatever app handles the web. No socket is opened here and
/// `tool/verify_no_internet.sh` still passes against the release APK. See the
/// note on `openUrl` in `capture.dart`.
sealed class TextRun {
  const TextRun();
}

/// Ordinary writing.
class PlainRun extends TextRun {
  const PlainRun(this.text);
  final String text;

  @override
  bool operator ==(Object other) => other is PlainRun && other.text == text;
  @override
  int get hashCode => text.hashCode;
  @override
  String toString() => 'PlainRun(${'"'}$text${'"'})';
}

/// A run that is a web address.
class LinkRun extends TextRun {
  const LinkRun({required this.text, required this.url});

  /// Exactly what is on the page. Never differs from where it goes.
  final String text;

  /// What is handed to the system. Only ever [text], with a scheme added when
  /// the person wrote `www.` and left it off.
  final String url;

  @override
  bool operator ==(Object other) =>
      other is LinkRun && other.text == text && other.url == url;
  @override
  int get hashCode => Object.hash(text, url);
  @override
  String toString() => 'LinkRun(${'"'}$text${'"'} -> $url)';
}

/// Breaks [text] into plain runs and links.
///
/// ── THE REGEXP IS WRITTEN OUT RATHER THAN USING \w, DELIBERATELY ────────
///
/// `\w` in a Dart `RegExp` is **ASCII only**, even with the unicode flag. That
/// is not a footnote here: it is the bug that made search return nothing for
/// every non-Latin script in this app until 28 August, and it would do exactly
/// the same thing to a URL with a Devanagari or Arabic path in it. So the
/// character class below is explicit about what may appear in an address, and
/// the terminator is "whitespace", which every script agrees on.
List<TextRun> findLinks(String text) {
  if (text.isEmpty) return const [];

  // A URL runs to the first space. Everything after the scheme is permitted,
  // including non-Latin characters — trailing punctuation is trimmed
  // afterwards, where it can be done with a list of characters rather than a
  // list of scripts.
  final pattern = RegExp(
    r'(?:https?://|www\.)[^\s<>"' "'" r']+',
    caseSensitive: false,
    unicode: true,
  );

  final runs = <TextRun>[];
  var at = 0;
  for (final match in pattern.allMatches(text)) {
    var raw = match.group(0)!;
    var start = match.start;

    // ── Trailing punctuation belongs to the sentence, not to the address ──
    //
    // "I read it at https://example.com/x." ends in a full stop that is not
    // part of the URL, and following it would 404. The closing brackets are
    // balanced rather than simply stripped, because plenty of real addresses
    // contain them — a Wikipedia article with a disambiguation, for one — and
    // "(see https://en.wikipedia.org/wiki/Lamp_(disambiguation))" has both.
    //
    // The CJK and Arabic stops are here for the same reason as the Latin one.
    // A sentence in Japanese ends in 。 and a URL followed by one is the same
    // situation, in the language of somebody this app is now translated for.
    const trailing = '.,;:!?)]}>»”’。、！？،؟';
    while (raw.isNotEmpty && trailing.contains(raw[raw.length - 1])) {
      final last = raw[raw.length - 1];
      if (last == ')' || last == ']' || last == '}') {
        final open = last == ')' ? '(' : (last == ']' ? '[' : '{');
        final opens = open.allMatches(raw).length;
        final closes = last.allMatches(raw).length;
        // Balanced: the bracket is part of the address after all.
        if (opens >= closes) break;
      }
      raw = raw.substring(0, raw.length - 1);
    }

    // A bare "www." or a scheme with nothing after it is not an address.
    if (raw.length < 8 && !raw.toLowerCase().startsWith('http')) continue;
    if (raw.toLowerCase() == 'http://' || raw.toLowerCase() == 'https://') {
      continue;
    }

    if (start > at) runs.add(PlainRun(text.substring(at, start)));
    runs.add(LinkRun(
      text: raw,
      // The one place the two differ. Somebody who wrote `www.` meant a web
      // address, and `ACTION_VIEW` needs a scheme to know that.
      url: raw.toLowerCase().startsWith('www.') ? 'https://$raw' : raw,
    ));
    at = start + raw.length;
  }
  if (at < text.length) runs.add(PlainRun(text.substring(at)));
  return runs;
}

/// The user's own writing, with any addresses in it drawn as links.
///
/// A `StatefulWidget` because each link needs a [TapGestureRecognizer] and a
/// recognizer that is not disposed is a leak — one per link per entry, on a
/// screen that rebuilds whenever anything on the day changes.
///
/// **It falls back to a plain `Text` when there is nothing to link**, which is
/// the overwhelmingly common case. That is not only a saving: `Text.rich` with
/// a single span behaves subtly differently from `Text` around selection and
/// soft-wrapping, and a journal should not change how it sets a paragraph
/// depending on whether the paragraph happens to mention a website.
class LinkedText extends StatefulWidget {
  const LinkedText(this.text, {super.key, this.style, this.maxLines});

  final String text;
  final TextStyle? style;
  final int? maxLines;

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  final _recognizers = <TapGestureRecognizer>[];
  late List<TextRun> _runs = findLinks(widget.text);

  @override
  void didUpdateWidget(LinkedText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _runs = findLinks(widget.text);
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _open(String url) async {
    final opened = await Capture.openUrl(url);
    if (!opened && mounted) {
      // The one thing that can go wrong: a phone with nothing installed that
      // handles the web. Said plainly, and it is the same sentence About uses
      // for the same situation.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.of(context).aboutNoBrowser)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? writingStyle(context);
    if (!_runs.any((r) => r is LinkRun)) {
      return Text(widget.text, style: style, maxLines: widget.maxLines);
    }

    final c = context.lamplight;
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final run in _runs)
            switch (run) {
              PlainRun(:final text) => TextSpan(text: text),
              LinkRun(:final text, :final url) => TextSpan(
                  text: text,
                  style: TextStyle(
                    color: c.accent,
                    // Underlined **as well as** coloured. `ACCESSIBILITY.md`
                    // does not allow colour to be the only way a thing is
                    // marked, and a link in the middle of a paragraph is the
                    // clearest possible case: to somebody who cannot separate
                    // the accent from the ink, an underline is the whole
                    // signal.
                    decoration: TextDecoration.underline,
                    decorationColor: c.accent.withValues(alpha: 0.5),
                  ),
                  recognizer: () {
                    final r = TapGestureRecognizer()
                      ..onTap = () => _open(url);
                    _recognizers.add(r);
                    return r;
                  }(),
                  semanticsLabel: text,
                ),
            },
        ],
      ),
      maxLines: widget.maxLines,
    );
  }
}
