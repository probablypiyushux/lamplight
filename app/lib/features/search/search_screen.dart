import 'dart:async';
import '../../l10n/generated/app_localizations.dart';
import '../../l10n/dates.dart';

import 'package:flutter/material.dart';

import '../../core/db/database.dart';
import '../../core/db/entry_repository.dart';
import '../../core/db/search.dart';
import '../../core/vault/vault.dart';
import '../../design/tokens.dart';
import '../folders/folders_screen.dart';

/// Finding something you wrote.
///
/// ── WHY A JOURNAL NEEDS THIS MORE THAN A NOTES APP DOES ──────────────────
///
/// **A journal you cannot search is a write-only medium.** For the first year,
/// swiping between days is enough. By year three, "the thing I wrote when Dad
/// was in hospital" is somewhere in nine hundred days and is, in practice,
/// gone — and an app whose contents you cannot get back out of is one you
/// quietly stop putting things into.
///
/// ── WHAT IT LOOKS FOR NOW, WHICH IS FOUR THINGS ──────────────────────────
///
/// The first version searched the body text of entries and nothing else. That
/// sounds complete and is not, because the most likely thing anybody types
/// into a journal's search box is **a date** — and `16 March 2006` used to
/// search the *prose* for the word "march", which found nothing and looked
/// broken. Filenames were in the database the whole time and nothing read
/// them. Folder names likewise.
///
/// So: dates, words, filenames, folders. Each is labelled for what it is, and
/// dates come first because a date is a navigation instruction rather than a
/// query — you are not asking what matches, you are saying where to go.
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.vault,
    required this.onOpenDay,
  });

  final Vault vault;

  /// Tapping a result travels to that day rather than opening the entry alone.
  ///
  /// Deliberate: `DATA-MODEL.md`'s whole idea is that an entry lives on a day
  /// and the day is the context. A result opened in isolation would answer
  /// "what did I write" and lose "what else was happening", which is usually
  /// the thing you were actually looking for.
  final void Function(DateTime day) onOpenDay;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _field = TextEditingController();
  late final EntryRepository _repo = EntryRepository(widget.vault.database);

  String _query = '';
  Set<SearchKind> _kinds = <SearchKind>{};
  Timer? _debounce;
  SearchHits _hits = SearchHits.empty;
  bool _running = false;

  /// Guards against an older query's results arriving after a newer one's,
  /// which is how a search box ends up showing the answer to what you typed
  /// two letters ago.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _field.addListener(() {
      widget.vault.touch();
      // 180ms. Long enough that a fast typist does not run a query per
      // keystroke, short enough that it feels like the results are keeping up
      // rather than catching up.
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 180), _run);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _field.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final query = _field.text;
    final generation = ++_generation;
    setState(() {
      _query = query;
      _running = query.trim().isNotEmpty;
    });
    if (query.trim().isEmpty) {
      setState(() {
        _hits = SearchHits.empty;
        _running = false;
      });
      return;
    }
    final hits = await _repo.searchEverything(query, kinds: _kinds);
    if (!mounted || generation != _generation) return;
    setState(() {
      _hits = hits;
      _running = false;
    });
  }

  void _toggleKind(SearchKind kind) {
    setState(() {
      if (!_kinds.remove(kind)) _kinds.add(kind);
    });
    _run();
  }

  /// One of the worked examples, put into the box and run. **ISSUE 7.**
  ///
  /// The caret goes to the end rather than selecting the text, because the
  /// next thing somebody does with "yesterday" is usually to edit it.
  void _tryExample(String query) {
    _field.text = query;
    _field.selection = TextSelection.collapsed(offset: query.length);
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Space.x2, Space.x2, Space.x4, Space.x2),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    color: c.inkPrimary,
                    tooltip: L.of(context).searchBack,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _field,
                      autofocus: true,
                      style: t.bodyLarge,
                      textInputAction: TextInputAction.search,
                      // The keyboard must not learn what is searched for any
                      // more than what is written — a search box is a list of
                      // the things somebody cares about most.
                      enableIMEPersonalizedLearning: false,
                      decoration: InputDecoration(
                        hintText: L.of(context).searchHint,
                        hintStyle: TextStyle(color: c.inkMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_field.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _field.clear();
                        _run();
                      },
                      icon: const Icon(Icons.close),
                      color: c.inkSecondary,
                      tooltip: L.of(context).searchClear,
                    ),
                ],
              ),
            ),

            // ── Narrow it down ──────────────────────────────────────────────
            //
            // **ISSUE 7 — "see how close and ugly it looks".** The row was 44
            // points tall with a 34-point chip in it, so the hairline below
            // sat five points off the bottom of every chip and read as
            // underlining them. Fifty-two, with the extra given to the gap
            // under the chips rather than around them.
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.x6),
                children: [
                  for (final kind in SearchKind.values)
                    Padding(
                      padding: const EdgeInsets.only(right: Space.x2),
                        child: Align(
                        alignment: Alignment.topCenter,
                        child: _KindChip(
                          kind: kind,
                          on: _kinds.contains(kind),
                          onTap: () => _toggleKind(kind),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: c.borderHair),

            Expanded(child: _results(context)),
          ],
        ),
      ),
    );
  }

  Widget _results(BuildContext context) {
    if (_query.trim().isEmpty) {
      // ── An empty search box is where "what mattered" lives ──────────────
      //
      // FEATURE-RANKING.md 16 describes the marker as *"enables 'read back
      // what mattered'"*, and without somewhere to read them back, marking an
      // entry is a gesture into nothing — which is what the column had been
      // since the first commit.
      //
      // This screen rather than a new one, because the question "where was
      // that one" is the same question search exists to answer, and because
      // an empty search box was otherwise showing four lines of instructions
      // to somebody who had already opened search. The hints stay underneath:
      // a new vault has nothing marked and sees exactly what it saw before.
      return _Marked(repo: _repo, onOpen: widget.onOpenDay, onTry: _tryExample);
    }

    if (_hits.isEmpty && _running) {
      // Nothing yet and a query in flight. Deliberately blank rather than a
      // spinner: results usually arrive inside one frame, and a spinner that
      // flashes for 40 ms is worse than nothing at all.
      return const SizedBox.shrink();
    }

    if (_hits.isEmpty) {
      final c = context.lamplight;
      final t = Theme.of(context).textTheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            Space.x6, Space.x8, Space.x6, Space.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L.of(context).searchNothingMatches(_query.trim()),
                style: t.bodyLarge?.copyWith(color: c.inkSecondary)),
            if (_kinds.isNotEmpty) ...[
              const SizedBox(height: Space.x3),
              // The most common reason a search comes back empty is a filter
              // the person forgot they set. Say so, and offer the fix.
              TextButton(
                onPressed: () {
                  setState(() => _kinds = <SearchKind>{});
                  _run();
                },
                child: Text(L.of(context).searchEverythingInstead,
                    style: TextStyle(color: c.accent)),
              ),
            ],
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: Space.x10),
      children: [
        // ── Days ───────────────────────────────────────────────────────
        //
        // Two ways a day can be a result and one heading over both: the query
        // *named* a date, or the query is in the line the user gave that day.
        // Both do exactly the same thing when tapped, so two sections would be
        // a distinction that costs the reader something and gives nothing.
        //
        // Parsed dates first — typing "yesterday" is an instruction and should
        // be obeyed at the top. A day that is in both lists is drawn once, as
        // the named one, because the line is the more useful of the two.
        if (_hits.days.isNotEmpty || _hits.namedDays.isNotEmpty) ...[
          const _SectionLabel('Go to'),
          for (final day in _hits.days)
            if (!_hits.namedDays.any((n) => _sameDay(n.date, day)))
              _DayResult(day: day, onOpen: widget.onOpenDay),
          for (final named in _hits.namedDays)
            _DayResult(
              day: named.date,
              note: named.snippet,
              onOpen: widget.onOpenDay,
            ),
        ],
        if (_hits.folders.isNotEmpty) ...[
          _SectionLabel(L.of(context).searchFolders),
          for (final folder in _hits.folders)
            _FolderResult(
              folder: folder,
              vault: widget.vault,
              onOpenDay: widget.onOpenDay,
            ),
        ],
        if (_hits.entries.isNotEmpty) ...[
          _SectionLabel(_hits.entries.length == 1
              ? L.of(context).searchEntriesOne
              : L.of(context).searchEntriesMany(_hits.entries.length)),
          for (final hit in _hits.entries)
            _Result(hit: hit, onOpen: widget.onOpenDay),
        ],
      ],
    );
  }
}

/// Same calendar day, ignoring any time-of-day either side carries.
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Space.x6, Space.x5, Space.x6, Space.x2),
      child: Text(
        text.toUpperCase(),
        style: t.labelSmall?.copyWith(color: c.inkMuted),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind, required this.on, required this.onTap});

  final SearchKind kind;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: on,
      label: '${_kindLabel(context, kind)}'
          '${on ? ', ${L.of(context).semanticOn}' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.full),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: Space.x4),
          decoration: BoxDecoration(
            // Selected is a fill AND a tick, never colour alone.
            color: on ? c.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.full),
            border: Border.all(color: on ? c.accent : c.borderStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (on) ...[
                Icon(Icons.check, size: 14, color: c.canvas),
                const SizedBox(width: Space.x1),
              ],
              Text(
                _kindLabel(context, kind),
                style: t.labelMedium?.copyWith(
                  color: on ? c.canvas : c.inkSecondary,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What you can type in, shown as things you can tap.
///
/// ══ ROUND FIFTEEN, ISSUE 7 — THIS WAS NOT BEING DRAWN AT ALL ═════════════
///
/// > *"use the full space dude"*, *"see how close and ugly it looks"*, and
/// > *"how boring those boxes look like, atleast make the good looking and
/// > better"* — over a screenshot of a search screen that is a field, five
/// > chips, a hairline, and then nine hundred points of black.
///
/// **It was a `ListView`, returned into the `children:` of another
/// `ListView`.** A vertical viewport inside a vertical viewport is given
/// unbounded height: in a debug build that is an assertion, and in the release
/// build he was looking at it is silently nothing. The screen was not badly
/// laid out — it was not laid out.
///
/// It has been that way since the marked-entries list was added around it in
/// round eleven, and it survived because **there was no test for this screen**.
/// Not one, in a suite of 1,246. `test/widget/search_screen_test.dart` is that
/// gap closed, and its first case is his screenshot.
///
/// ── AND WHAT IT IS NOW, RATHER THAN JUST VISIBLE ─────────────────────────
///
/// A `Column`, so it composes into whatever list it is put in. But the fix for
/// *"how boring"* is not decoration: **each example is now something you can
/// tap**, and tapping it puts that example into the box and runs it. Four
/// lines of dead instructions become four ways in, which is the difference
/// between a screen that explains itself and a screen that is doing nothing
/// while it waits for you.
class _Hint extends StatelessWidget {
  const _Hint({this.onTry});

  /// Puts an example into the search box. Null in a preview.
  final void Function(String query)? onTry;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    // Examples rather than a description. "Search your entries" tells nobody
    // anything they had not guessed; showing that a date works is the whole
    // point of the feature and is otherwise invisible.
    final l = L.of(context);
    final examples = <(IconData, String, String, String?)>[
      // The icon is the one the kind already wears on its chip, so the two
      // halves of this screen are recognisably about the same things.
      (Icons.event_outlined, l.searchADate, l.searchDateExample,
          l.searchTryDate),
      (Icons.notes_outlined, l.searchKindWords, l.searchWordsExample, null),
      (Icons.attach_file, l.searchAFile, l.searchFileExample, null),
      (Icons.folder_outlined, l.searchAFolder, l.searchFolderExample, null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Space.x6, Space.x6, Space.x6, Space.x2),
          child: Text(l.searchWhatYouCanType.toUpperCase(),
              style: t.labelSmall?.copyWith(color: c.inkMuted)),
        ),
        for (final (icon, what, how, tryIt) in examples)
          _HintRow(
            icon: icon,
            what: what,
            how: how,
            // Only the date has something worth putting in the box for you.
            // "anything you have written" is a description, not a query, and a
            // row that types a description into the field would be a joke at
            // the user's expense.
            onTry: tryIt == null || onTry == null ? null : () => onTry!(tryIt),
          ),
      ],
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({
    required this.icon,
    required this.what,
    required this.how,
    this.onTry,
  });

  final IconData icon;
  final String what;
  final String how;
  final VoidCallback? onTry;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Space.x6, vertical: Space.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boxed rather than bare, so the four rows read as a set. A rounded
          // square of `raised` is the same step the rest of the app uses for
          // "this is a thing" — no border, no shadow, no outline.
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.raised,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(icon, size: 17, color: c.inkMuted),
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(what, style: t.bodyLarge?.copyWith(color: c.inkPrimary)),
                const SizedBox(height: 1),
                Text(how,
                    style: t.labelMedium?.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
          if (onTry != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: Space.x2),
              child: Icon(Icons.north_west,
                  size: 16, color: c.accent.withValues(alpha: 0.7)),
            ),
        ],
      ),
    );

    if (onTry == null) return Semantics(container: true, child: row);
    return Semantics(
      button: true,
      label: '$what. $how',
      excludeSemantics: true,
      child: InkWell(onTap: onTry, child: row),
    );
  }
}

/// A date the query named. First in the list, because it is the answer to a
/// different question than the entries below it.
class _DayResult extends StatelessWidget {
  const _DayResult({required this.day, required this.onOpen, this.note});

  final DateTime day;
  final void Function(DateTime) onOpen;

  /// The day's own line, when that is what matched. **`PLAN.md` §7.0-E.**
  ///
  /// Null for a day the query merely *named* — "16 March 2006" is a navigation
  /// instruction and there is nothing to quote back.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final label = LampDates.dayMonthYear(context, day);
    final line = note;
    return Semantics(
      button: true,
      // The line is read out too. A day that matched because of what it was
      // called is a different result from one that matched by date, and a
      // screen reader that says only "Go to 16 March" hides the reason.
      label: line == null
          ? '${L.of(context).searchGoTo} $label'
          : '${L.of(context).searchGoTo} $label. ${_plainOf(line)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onOpen(day),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Space.x6, vertical: Space.x4),
          child: Row(
            children: [
              Icon(Icons.event_outlined, size: 20, color: c.accent),
              const SizedBox(width: Space.x4),
              Expanded(
                child: line == null
                    ? Text(label, style: t.bodyLarge)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label, style: t.bodyLarge),
                          const SizedBox(height: Space.x1),
                          Text.rich(
                            TextSpan(
                              children: markedSpans(
                                line,
                                base: t.bodyMedium,
                                quiet: c.inkMuted,
                                strong: c.inkPrimary,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
              ),
              Icon(Icons.chevron_right, size: 20, color: c.inkMuted),
            ],
          ),
        ),
      ),
    );
  }

  static String _plainOf(String snippet) =>
      snippet.replaceAll(markStart, '').replaceAll(markEnd, '');
}

class _FolderResult extends StatelessWidget {
  const _FolderResult({
    required this.folder,
    required this.vault,
    required this.onOpenDay,
  });

  final Folder folder;
  final Vault vault;
  final void Function(DateTime) onOpenDay;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FolderContentsScreen(
            vault: vault,
            folder: folder,
            onOpenDay: onOpenDay,
            onChanged: () {},
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.x6, vertical: Space.x4),
        child: Row(
          children: [
            Icon(Icons.folder_outlined, size: 20, color: c.inkSecondary),
            const SizedBox(width: Space.x4),
            Expanded(child: Text(folder.name, style: t.bodyLarge)),
            Icon(Icons.chevron_right, size: 20, color: c.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.hit, required this.onOpen});

  final SearchHit hit;
  final void Function(DateTime day) onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final parts = hit.entry.dayKey.split('-');
    final day = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final when = LampDates.dayMonthYear(context, day);

    return Semantics(
      button: true,
      label: '$when. ${_plain(hit.snippet)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onOpen(day),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Space.x6, vertical: Space.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(when,
                      style: t.labelMedium?.copyWith(color: c.accent)),
                  if (hit.reason != HitReason.text) ...[
                    const SizedBox(width: Space.x2),
                    // Says *why* this is here. A result whose words do not
                    // contain the query looks like a bug unless the reason is
                    // on screen.
                    Icon(
                      hit.reason == HitReason.spoken
                          ? Icons.graphic_eq
                          : _glyph(hit.entry.type),
                      size: 13,
                      color: c.inkMuted,
                    ),
                    const SizedBox(width: Space.x1),
                    Text(
                      // ISSUE 15. "Said out loud" rather than "in transcript":
                      // the user did not ask for a transcript, they made a
                      // voice note, and this is the app telling them where it
                      // heard the words.
                      hit.reason == HitReason.spoken
                          ? L.of(context).searchSaidOutLoud
                          : L.of(context).searchByFileName,
                      style: t.labelSmall?.copyWith(color: c.inkMuted),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: Space.x2),
              // The match, bolded in place. FTS5's own `snippet()` marks it
              // with the sentinels we asked for, which is far more reliable
              // than searching the text again in Dart — the engine knows where
              // its own word boundaries were, and we do not.
              Text.rich(
                TextSpan(children: _spans(hit.snippet, c, t)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _glyph(String type) => switch (type) {
        'photo' => Icons.image_outlined,
        'video' => Icons.movie_outlined,
        'voice' => Icons.mic_none_outlined,
        _ => Icons.insert_drive_file_outlined,
      };

  static String _plain(String snippet) =>
      snippet.replaceAll(markStart, '').replaceAll(markEnd, '');

  List<TextSpan> _spans(String snippet, LamplightColors c, TextTheme t) =>
      markedSpans(snippet, base: t.bodyLarge, quiet: c.inkSecondary,
          strong: c.inkPrimary);
}

/// Splits a snippet on the sentinels FTS5 and `_markMatch` both emit, and
/// bolds what is between them.
///
/// Top-level rather than a method, because three kinds of result now render a
/// snippet — an entry, a filename, and a day's own line — and two copies of
/// this would eventually disagree about what a match looks like.
List<TextSpan> markedSpans(
  String snippet, {
  required TextStyle? base,
  required Color quiet,
  required Color strong,
}) {
  final spans = <TextSpan>[];
  var rest = snippet;
  while (true) {
    final open = rest.indexOf(markStart);
    if (open < 0) break;
    final close = rest.indexOf(markEnd, open);
    if (close < 0) break;
    if (open > 0) {
      spans.add(TextSpan(
        text: rest.substring(0, open),
        style: base?.copyWith(color: quiet),
      ));
    }
    spans.add(TextSpan(
      text: rest.substring(open + 1, close),
      style: base?.copyWith(color: strong, fontWeight: FontWeight.w700),
    ));
    rest = rest.substring(close + 1);
  }
  if (rest.isNotEmpty) {
    spans.add(TextSpan(text: rest, style: base?.copyWith(color: quiet)));
  }
  return spans;
}


/// What mattered, above the search hints.
///
/// Loads once when search opens. A `FutureBuilder` rebuilt on every keystroke
/// would re-run the query behind a box the user is typing into — and this list
/// is only ever visible when that box is empty.
class _Marked extends StatefulWidget {
  const _Marked({required this.repo, required this.onOpen, this.onTry});

  final EntryRepository repo;
  final void Function(DateTime day) onOpen;

  /// Puts one of the worked examples into the search box. **ISSUE 7.**
  final void Function(String query)? onTry;

  @override
  State<_Marked> createState() => _MarkedState();
}

class _MarkedState extends State<_Marked> {
  List<Entry>? _entries;

  @override
  void initState() {
    super.initState();
    widget.repo.markedEntries().then((rows) {
      if (mounted) setState(() => _entries = rows);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final entries = _entries ?? const <Entry>[];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (entries.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Space.x6, Space.x6, Space.x6, Space.x2),
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 14, color: c.accent),
                const SizedBox(width: Space.x2),
                Text(L.of(context).searchWhatMattered,
                    style: t.labelSmall?.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
          for (final e in entries) _MarkedRow(entry: e, onOpen: widget.onOpen),
          const SizedBox(height: Space.x4),
          Divider(color: c.borderHair, height: 1),
        ],
        _Hint(onTry: widget.onTry),
      ],
    );
  }
}

class _MarkedRow extends StatelessWidget {
  const _MarkedRow({required this.entry, required this.onOpen});

  final Entry entry;
  final void Function(DateTime day) onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final parts = entry.dayKey.split('-');
    final day = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final when = LampDates.dayMonthYear(context, day);

    // What the entry actually is, for the ones that are not words. A marked
    // photograph showing a blank line would read as a fault.
    final body = (entry.body ?? '').trim();
    final line = body.isNotEmpty
        ? body
        : switch (entry.type) {
            'photo' => L.of(context).searchAPhotograph,
            'video' => L.of(context).searchAVideo,
            'voice' => L.of(context).searchARecording,
            'file' => L.of(context).searchAFile,
            _ => L.of(context).searchAnEntry,
          };

    return Semantics(
      button: true,
      label: '$when. $line',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onOpen(day),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Space.x6, vertical: Space.x3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(when, style: t.labelMedium?.copyWith(color: c.inkMuted)),
              const SizedBox(height: 2),
              Text(
                line,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.bodyLarge?.copyWith(color: c.inkPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The filter chips, in the reader's language.
///
/// `SearchKind` lives in `core/db/` and holds an English `label` for its own
/// reasons — it is below the widget layer and has no context. The words belong
/// here, in the screen that draws them, exactly as `design_names.dart` does for
/// the accents and the typefaces.
String _kindLabel(BuildContext context, SearchKind kind) => switch (kind) {
      SearchKind.writing => L.of(context).searchKindWords,
      SearchKind.voice => L.of(context).searchKindVoice,
      SearchKind.photos => L.of(context).searchKindPhotos,
      SearchKind.video => L.of(context).searchKindVideo,
      SearchKind.files => L.of(context).searchKindFiles,
    };
