import 'dart:async';
import '../../l10n/generated/app_localizations.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
// For `ScrollCacheExtent`, which widgets.dart does not re-export.
import 'package:flutter/rendering.dart';

import '../../core/db/database.dart';
import '../../core/media/encrypted_image.dart';
import '../../core/platform/pdf_render.dart';
import '../../core/storage/attachment_store.dart';
import '../../core/storage/attachment_importer.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import 'pdf_layout.dart';
import 'zoom_tile.dart';
import 'viewer_menu.dart';

/// Opening a document without ever putting it on disk. **ISSUE 4.**
///
/// ── THE REPORT, AND WHY IT WAS THE ANGRIEST ONE ──────────────────────────
///
/// "No document opens." Tapping a PDF chip opened the entry menu, which offered
/// only "save a copy". A previous round recorded this as fixed; what got fixed
/// was that the chip responded to a tap at all.
///
/// This is `PLAN.md` §11 test 6 — the invisible-machinery test — failing in the
/// way that test names explicitly: *nothing that fails silently. A control that
/// does nothing when tapped is the same defect as a crash, wearing better
/// clothes.*
///
/// ── THE COLLISION WITH RULE 2, AND HOW IT IS RESOLVED ────────────────────
///
/// Opening a file "in another app" means writing it to disk decrypted and
/// handing Adobe or Google a URI to it. `CLAUDE.md` rule 2 has no exception for
/// "briefly, while they read it".
///
/// **Decision taken 22 August, approved by Piyush, recorded in `PLAN.md` — do
/// not re-litigate.** Everything that can be rendered from memory is rendered
/// here: PDF through Android's own `PdfRenderer` over a proxy descriptor
/// (`MemoryPdf.kt`), images through the decoder the photo viewer already uses,
/// and text and Markdown as text. Everything that cannot — Word, Excel,
/// PowerPoint, which would each need a large dependency that could read the
/// whole vault — keeps "save a copy", **and says so in a sentence.** Silence
/// reads as breakage. A clear sentence does not.
///
/// ── WHAT THIS SCREEN DELIBERATELY IS NOT ─────────────────────────────────
///
/// It is not an editor and it is not a file manager. It shows you what is in
/// the document and gets out of the way, which is what a person tapping a
/// ticket, a letter or a scan in their own journal actually wants.
class DocumentViewer extends StatefulWidget {
  const DocumentViewer({
    super.key,
    required this.entry,
    required this.attachment,
    required this.importer,
    required this.onSaveCopy,
    required this.onOpenWith,
  });

  final Entry entry;
  final Attachment attachment;
  final AttachmentImporter importer;

  /// The escape hatch, offered on every kind and the only offer on the ones
  /// that cannot be drawn here.
  final Future<void> Function() onSaveCopy;

  /// Hands the file to another app for as long as it takes to read it.
  /// **ISSUE 4 and 13** — *"I want it on every file type/format"*, so this is
  /// offered whether or not this screen can draw the thing itself.
  final Future<void> Function() onOpenWith;

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

/// What this screen can do with a given file.
///
/// Decided from the MIME type and the filename together, because a picker that
/// could not identify a file hands back `application/octet-stream` and the
/// extension is then the only thing anybody knows about it. Guessing from an
/// extension is not something to be proud of; being wrong about what a file
/// *is* is worse.
enum DocumentKind { pdf, image, text, unsupported }

DocumentKind kindOf(String mime, String name) {
  final m = mime.toLowerCase();
  final n = name.toLowerCase();
  if (m.contains('pdf') || n.endsWith('.pdf')) return DocumentKind.pdf;
  if (m.startsWith('image/')) return DocumentKind.image;
  // ── Exact, not `contains` ────────────────────────────────────────────────
  //
  // The first version of this read `m.contains('xml')`, and a `.docx` is
  // `application/vnd.openxmlformats-officedocument.wordprocessingml.document`.
  // It matched. A Word file would have been opened as text and shown a
  // screenful of ZIP binary — no crash, no error, just nonsense, which is the
  // worst way for this to be wrong.
  //
  // Caught by `test/media/document_kind_test.dart` before it ever ran on a
  // phone, which is the whole argument for this being a pure function with a
  // test rather than a chain of `if`s inside a build method.
  // ── ISSUE 12 — the list he wrote out, answered format by format ─────────
  //
  // He listed twenty-eight and said *"I need at least"* these. The honest
  // answer is that they fall into three groups, not two, and the grouping is
  // about **dependencies** rather than about effort:
  //
  //   * Already opened, or opened by this change: pdf, jpg/jpeg, png, webp,
  //     gif, heic, csv, json, html, rtf, vcf, txt, md, xml, log, yaml, ini.
  //     Every one of these is either a picture Android's own decoder reads or
  //     text with a different extension on it. Nothing new is needed.
  //
  //   * Already opened, but not by this screen: wav, m4a, mov, mkv, avi, opus,
  //     ogg. `AttachmentImporter.typeForMime` routes audio to the voice player
  //     and video to the video player before a document viewer is ever built.
  //     They were never broken; see ISSUE 3 for what the video player itself
  //     does with the awkward ones.
  //
  //   * Cannot be opened in place: docx/doc, xlsx/xls, pptx/ppt, zip, rar, 7z,
  //     epub, apk, svg. Each needs a parser that is a third-party package, and
  //     `CLAUDE.md` rule 4 is that every package added here can read all of the
  //     user's notes. An Office parser to read one .docx is a very large
  //     surface for a small feature. These get the refusal panel, which now
  //     carries the soft warning he asked for.
  //
  // The full list, and the reasoning, is written up in
  // `04-technical/DOCUMENT-FORMATS.md` so that it is answerable without
  // reading this function.
  const textTypes = {
    'application/json',
    'application/xml',
    'text/xml',
    'application/x-yaml',
    'application/toml',
    // ISSUE 12. All of these are text with a specific shape, and text is what
    // is useful about them in a journal — a contact card is a name and a
    // number, and reading it beats being told it needs another app.
    'application/rtf',
    'text/rtf',
    'text/html',
    'text/calendar',
    'text/vcard',
    'text/x-vcard',
    'text/csv',
  };
  if (m.startsWith('text/') || textTypes.contains(m) || m.endsWith('+json')) {
    return DocumentKind.text;
  }
  const readable = [
    '.txt', '.md', '.markdown', '.csv', '.tsv', '.json', '.log',
    '.yaml', '.yml', '.xml', '.ini', '.rtf',
    // ISSUE 12.
    '.html', '.htm', '.vcf', '.ics', '.conf', '.srt',
  ];
  if (readable.any(n.endsWith)) return DocumentKind.text;
  const pictures = [
    '.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.bmp',
    // ISSUE 12. HEIF and AVIF go through the same Android `ImageDecoder`
    // fallback that already carries HEIC — see `EncryptedImage`. **SVG is
    // deliberately absent**: it is not a bitmap, neither Skia nor Android will
    // decode one, and rendering it needs a package. It gets the refusal.
    '.heif', '.avif',
  ];
  if (pictures.any(n.endsWith)) return DocumentKind.image;
  return DocumentKind.unsupported;
}

/// Whether Lamplight can show this without handing it to another app.
///
/// **ISSUE 12** — *"make a list which can be opened and which can't be
/// opened"*. This is that list, as a function, so the answer is the same
/// everywhere it is asked and cannot drift from what the viewer actually does.
bool opensInLamplight(String mime, String name) =>
    kindOf(mime, name) != DocumentKind.unsupported;

class _DocumentViewerState extends State<DocumentViewer> {
  DocumentKind get _kind =>
      kindOf(widget.attachment.mimeType, widget.attachment.originalName);

  bool _busy = true;
  String? _error;

  /// PDF
  int _pages = 0;

  /// The shape of every page, measured at open. **ROUND FIFTEEN, ISSUE 8.**
  ///
  /// Without it the list laid every page out as A4 and then resized it when the
  /// bitmap arrived, which moves everything below — that is what *"scroll down
  /// Fastly ... it behaves jerky"* is — and the page number was
  /// `scrollFraction x (pages - 1)`, an estimate that is only right when every
  /// page is identical. Which is why *"scroll to 50th page"* did not.
  OpenPdf? _shapes;

  /// Where this document was left, and where it is now. **ISSUE 1B.**
  int _startPage = 0;
  int _lastPage = 0;

  /// Text and Markdown
  String? _text;



  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // The decrypted document goes when the screen does. Not "eventually" —
    // now, on the way out, because it is the user's own papers held in RAM.
    if (_kind == DocumentKind.pdf) PdfRender.close();
    // ── ISSUE 1B — written on the way out, not on every scroll ───────
    //
    // *"It doesn't remembers what was the last page when I closed that PDF."*
    //
    // Once, here, rather than on every frame of a flick through four hundred
    // pages — which would be four hundred encrypted writes to say something
    // that only matters when you leave. Unawaited because this screen is going
    // and the repository outlives it.
    if (_kind == DocumentKind.pdf && _lastPage != (widget.attachment.lastPage ?? 0)) {
      unawaited(widget.importer.rememberPage(widget.attachment.id, _lastPage));
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (_kind == DocumentKind.unsupported) {
      setState(() => _busy = false);
      return;
    }
    if (widget.attachment.byteSize > PdfRender.maxBytes) {
      setState(() {
        _busy = false;
        // ROUND EIGHT, ISSUE 10, and this one was found by the check rather
        // than by reading: "it would have to be held in memory all at once" is
        // the implementation model in a sentence. A person opening a document
        // has no memory budget and cannot act on one.
        _error = L.of(context).docTooBig;
      });
      return;
    }

    try {
      // Decrypted on a worker isolate. Nothing is written to disk on this path
      // or any other — see AttachmentStore.
      final bytes = await widget.importer.bytesOf(widget.attachment);
      if (!mounted) return;
      switch (_kind) {
        case DocumentKind.pdf:
          final opened = await PdfRender.open(bytes);
          final pages = opened.pages;
          if (!mounted) return;
          setState(() {
            _pages = pages;
            _shapes = opened;
            // ISSUE 1B. Clamped rather than trusted: a document could in
            // principle have been replaced by a shorter one, and opening at a
            // page that no longer exists is a blank screen.
            _startPage =
                (widget.attachment.lastPage ?? 0).clamp(0, math.max(0, pages - 1));
            _lastPage = _startPage;
            _busy = false;
          });
        case DocumentKind.text:
          // `allowMalformed`, because a file that is nearly UTF-8 should be
          // readable rather than refused. A journal holds files from
          // everywhere, and the alternative to a couple of replacement
          // characters is a blank screen.
          setState(() {
            _text = utf8.decode(bytes, allowMalformed: true);
            _busy = false;
          });
        case DocumentKind.image:
          // ── ISSUE 4 addon: this used to take one frame and stop ──────────
          //
          // `getNextFrame()` returns the *first* frame, so a GIF or an animated
          // WebP opened here was a still — which is precisely the complaint,
          // and it was silent about it.
          //
          // Nothing is decoded here now. `EncryptedImage` is handed the
          // attachment and does the whole job: it decrypts off the isolate,
          // hands the codec to a `MultiFrameImageStreamCompleter` — which is
          // what animates a multi-frame image — and falls back to Android's own
          // decoder for HEIC and AVIF, which Skia will not touch. One image
          // path in the app rather than two that drift apart.
          setState(() => _busy = false);
        case DocumentKind.unsupported:
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _plain(e);
        });
      }
    }
  }

  /// Size, pages, and — **ISSUE 12** — what compressing it saved.
  ///
  /// *"How do I know that the thing is getting compressed?"* This is where he
  /// can see it on the file itself: the stored size, and what it came down
  /// from. Absent when nothing was re-encoded, rather than a saving of zero.
  String _subtitle() {
    final parts = <String>[humanSize(widget.attachment.byteSize)];
    if (_pages > 1) parts.add(L.of(context).docPages('$_pages'));
    final saved = humanSaving(
      originalSize: widget.attachment.originalSize,
      storedSize: widget.attachment.byteSize,
    );
    if (saved != null) parts.add(saved);
    return parts.join(' · ');
  }

  String _plain(Object e) {
    final s = '$e';
    // Never a Dart type name in front of a person, and never an exception's
    // own `toString`. PLAN.md §11 test 6.
    return s.contains('could not') || s.contains('too large') || s.contains('phone')
        ? s.replaceFirst(RegExp(r'^[A-Za-z_]+: '), '')
        : L.of(context).docCouldNotOpen;
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
            // On the app's grid, like every other header. ISSUE 1.
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Layout.iconInset, vertical: Space.x1),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    color: c.inkPrimary,
                    tooltip: L.of(context).searchBack,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.attachment.originalName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyLarge,
                        ),
                        Text(
                          _subtitle(),
                          style: t.labelMedium?.copyWith(color: c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  // ── ISSUE 4, 13 — "give the option under three dots" ────
                  //
                  // He said where it goes as well as what it does: *"Open the
                  // file - give that option under three dot or something, same
                  // for (4)"*. So the bare save button is a menu now, which is
                  // also what the photo and video viewers carry since ISSUE 14
                  // — one gesture for "what else can I do with this", wherever
                  // you are.
                  IconButton(
                    onPressed: _menu,
                    icon: const Icon(Icons.more_vert),
                    color: c.inkSecondary,
                    tooltip: L.of(context).viewerMore,
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  /// The soft warning, before anything leaves the vault. **ISSUE 12.**
  ///
  /// *"Some of the file formats which can't be opened inside the app — for
  /// those file formats, before opening them, give them a soft warning that
  /// this makes it visible to other apps."*
  ///
  /// The refusal panel already explained this in prose, and prose on a screen
  /// is not a decision. This is the decision: it interrupts once, says the one
  /// thing that matters in the fewest words that can carry it, and defaults to
  /// the safe answer — *Keep it here* is the plain button and the destructive
  /// one has to be chosen.
  ///
  /// **Soft, and that word is doing work.** `ETHICAL-DESIGN.md` forbids
  /// frightening people out of things they have every right to do. This is
  /// their own file and saving it is a completely reasonable thing to want. So
  /// there is no red, no warning triangle, no "are you sure?" — just the fact
  /// they might not have thought of, once, at the moment it becomes true.
  /// Everything this screen can do with the file, in one sheet.
  ///
  /// The same sheet the photo and video viewers use, from the same function, so
  /// the three cannot drift apart.
  Future<void> _menu() async {
    await showViewerMenu(
      context: context,
      kind: 'file',
      onOpenWith: () => widget.onOpenWith(),
      onSave: () => _saveWithWarning(context),
    );
  }

  Future<void> _saveWithWarning(BuildContext context) async {
    final c = context.lamplight;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L.of(context).docLeavesLamplight),
        content: Text(
          L.of(context).docCopyInClear,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(L.of(context).docKeepItHere,
                style: TextStyle(color: c.inkSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(L.of(context).entrySaveCopy, style: TextStyle(color: c.accent)),
          ),
        ],
      ),
    );
    if (ok == true) await widget.onSaveCopy();
  }

  Widget _body(BuildContext context) {
    if (_busy) return Center(child: LampBusy(label: L.of(context).lockOpening));
    if (_error != null) {
      return _Explained(
        message: _error!,
        actionLabel: L.of(context).docOpenWith,
        onAction: widget.onOpenWith,
      );
    }
    if (_kind == DocumentKind.unsupported) {
      return _Explained(
        // ── The sentence that replaces silence ──────────────────────────
        //
        // It says three things a person can act on: what kind of file it is,
        // why it is not on screen, and what they can do instead. It does not
        // apologise and it does not blame the file.
        //
        // **ISSUE 4 changed what "instead" is.** It used to end at "save a
        // copy", which is the heavier of the two answers: the user ends up
        // owning a plaintext file somewhere on their phone that they then have
        // to remember. Lending it to another app leaves nothing behind, so
        // that is the offer now, and saving is still in the menu for anybody
        // who genuinely wants to keep one.
        message: L.of(context).docCannotShow(_extensionOf(widget.attachment.originalName)),
        actionLabel: L.of(context).docOpenWith,
        onAction: widget.onOpenWith,
      );
    }

    return switch (_kind) {
      DocumentKind.pdf => _PdfPages(
          pages: _pages,
          shapes: _shapes,
          startAt: _startPage,
          onPage: (p) => _lastPage = p,
        ),
      DocumentKind.text => _TextBody(text: _text ?? ''),
      DocumentKind.image => _ImageBody(
          attachment: widget.attachment,
          store: widget.importer.vault.attachments,
        ),
      DocumentKind.unsupported => const SizedBox.shrink(),
    };
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    return dot <= 0 || dot == name.length - 1
        ? 'file of this kind'
        : '.${name.substring(dot + 1).toLowerCase()}';
  }
}

/// The pages of a PDF, drawn on demand.
///
/// A `ListView.builder`, so a 400-page document costs one page's worth of work
/// rather than four hundred. Each page renders at the width it is actually
/// given, which is how a page looks like itself on a phone and on a tablet
/// rather than being a phone-sized picture stretched.
///
/// ══ ROUND EIGHT, ISSUE 1B — THE THREE THINGS IT WAS MISSING ═════════
///
/// *"What it misses? Page numbers, it doesn't remembers what was the last page
/// when I closed that PDF — zoom? Worst of all time! Other than two taps it's
/// so hard to zoom! Not so fast worst of all time!"*
///
/// Three separate complaints in one sentence, and all three are here:
///
///   1. **Page numbers.** There were none, anywhere. A document is now
///      always able to say where you are in it, and the indicator appears
///      while you move and fades when you stop — the pattern every reader on
///      the phone uses, because a permanent badge over somebody's document is
///      furniture.
///   2. **Where you had got to.** Kept per document in the vault's own
///      database — `Attachments.lastPage`, schema v5 — and jumped to on the
///      way in. See that column for why it is not in `settings.json`.
///   3. **The zoom.** See `_pinching`. It was a gesture-arena race, and the
///      list was winning it.
class _PdfPages extends StatefulWidget {
  const _PdfPages({
    required this.pages,
    required this.shapes,
    required this.startAt,
    required this.onPage,
  });

  final int pages;

  /// The shape of every page, measured at open. **ISSUE 8.**
  final OpenPdf? shapes;

  /// The page to open at. **ISSUE 1B.**
  final int startAt;

  /// Called as the reader moves, so the document can remember. **ISSUE 1B.**
  final ValueChanged<int> onPage;

  @override
  State<_PdfPages> createState() => _PdfPagesState();
}

class _PdfPagesState extends State<_PdfPages> {
  final ScrollController _scroll = ScrollController();

  /// ══ ROUND FIFTEEN, ISSUE 8 — THE LIST KNOWS HOW TALL IT IS NOW ═════════
  ///
  /// > *"scroll to 50th page and see that doesn't even show me! ... When
  /// > scroll down Fastly down to the end it behaves jerky and when scrolled
  /// > up Fastly – feels jerky!"*
  ///
  /// Both of those are one absence. Every page was laid out as A4 until its
  /// bitmap arrived and then took its real shape — so on a document of mixed
  /// page sizes the content below every page moved as it rendered, and the
  /// scroll offset moved with it. That is what "jerky" is, and no amount of
  /// smoothing fixes it, because the list genuinely is changing length under
  /// the finger.
  ///
  /// And the page number was `scrollFraction x (pages - 1)`, which is only
  /// correct when every page is exactly the same height. On anything else the
  /// indicator lied, and the "open where you left it" jump — which used the
  /// same arithmetic backwards — landed somewhere near rather than on the page.
  ///
  /// `MemoryPdf` measures every page's media box when the document opens; that
  /// is a page-dictionary read with no bitmap in it, tens of milliseconds for a
  /// whole book. With the shapes in hand the list can be laid out exactly, so
  /// **nothing moves as pages arrive**, and both the indicator and the jump are
  /// arithmetic rather than estimates.
  ///
  /// All of the arithmetic is in [PdfLayout], outside this widget, so that
  /// `test/media/pdf_layout_test.dart` can prove it without a phone, a document
  /// and a finger. This holds the one built for the current column width.
  PdfLayout? _layout;

  /// Rebuilds [_layout] for a column [width] points wide, if it has changed.
  void _measure(double width) {
    if (width <= 0) return;
    final held = _layout;
    if (held != null && (held.width - width).abs() < 0.5) return;
    _layout = PdfLayout(
      pages: widget.pages,
      width: width,
      shapeOf: (i) => widget.shapes?.shapeOf(i) ?? 1.414,
      padding: Space.x4,
      gap: Space.x4,
    );
  }

  /// Puts the top of page [index] at the top of the viewport. **ISSUE 8.**
  void _goTo(int index, {bool animate = true}) {
    final layout = _layout;
    if (layout == null || !_scroll.hasClients) return;
    // Clamped against the layout's own total rather than against
    // `maxScrollExtent`, which is an estimate until the list has been built
    // and is the reason the restore jump used to collapse to page three. With
    // `itemExtentBuilder` the two now agree from the first frame; this is
    // belt and braces, and it costs one comparison.
    final target = layout
        .offsetOf(index)
        .clamp(0.0, math.max(0.0, layout.extent))
        .toDouble();
    if (animate) {
      _scroll.animateTo(target,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic);
    } else {
      _scroll.jumpTo(target);
    }
  }

  /// The page the reader is on.
  ///
  /// ══ IT STARTS AT `startAt`, AND THAT IS A THIRD OF WHY 145 NEVER LOADED
  ///    2 September 2026 ══════════════════════════════════════════════════
  ///
  /// > *"Last time i opened that - and stopped it on 145 page number! Now i
  /// > open that pdf again - it never loads - to make it load - i need to go
  /// > to page one and slowly go to 145."*
  ///
  /// This was `0`, and every page asks `stillWanted: (i - _current.value).abs()
  /// <= 3` before it is allowed to render. So on the way in to page 145 the
  /// answer was `|145 - 0| <= 3` — **false** — and the render was dropped
  /// before it reached the channel. Not delayed. Dropped, and nothing asks
  /// again unless the widget rebuilds.
  ///
  /// That is the "never loads" in his sentence, exactly: the pages were built,
  /// they asked, and the guard that exists to stop a fling queueing thirty
  /// dead renders threw away the one render anybody wanted. Scrolling up from
  /// page one worked because it walks `_current` along with it.
  late final _current = ValueNotifier<int>(widget.startAt);

  /// Whether the indicator is showing. It follows movement rather than sitting
  /// there, because a badge permanently over somebody's document is furniture.
  final _moving = ValueNotifier<bool>(false);
  Timer? _settle;

  /// ══ ROUND EIGHT, ISSUE 1B — "ZOOM? WORST OF ALL TIME!" ═══════════
  ///
  /// *"Other than two taps it's so hard to zoom!"* — which is the same bug as
  /// ISSUE 4A in the photo viewer, wearing a different coat, and he found both
  /// independently.
  ///
  /// A `ListView` scrolls on a `VerticalDragGestureRecognizer`, which accepts
  /// at `kTouchSlop` — **eighteen logical pixels on one finger**. The
  /// `ScaleGestureRecognizer` inside each page's `InteractiveViewer` needs two
  /// fingers whose span has changed. Fingers do not land at the same
  /// millisecond, so the first one down usually drifted past eighteen pixels
  /// before the second arrived, the list won the arena, and the pinch was over
  /// before it started. The document scrolled instead of zooming, which is
  /// exactly *"so hard to zoom"* — and why double tap, which has no competitor
  /// at all, was the only thing that reliably worked.
  ///
  /// **The fix is the one every Android PDF reader uses**, and the technique
  /// has a name there: count the pointers and stop the scroller from
  /// intercepting while there are two. `RecyclerView` implementations do it
  /// with `onInterceptTouchEvent` plus `requestDisallowInterceptTouchEvent`;
  /// the Flutter equivalent is a `Listener` — which sits outside the gesture
  /// arena and therefore sees the second finger land *before* anybody has
  /// resolved — swapping the list's physics to `NeverScrollableScrollPhysics`,
  /// which removes its drag recogniser from the tree entirely.
  ///
  /// The pages themselves needed no change. They were always willing to zoom;
  /// nothing was letting them.
  int _pointers = 0;
  bool get _pinching => _pointers > 1;

  @override
  void initState() {
    super.initState();
    _current.value = widget.startAt;
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _settle?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _current.dispose();
    _moving.dispose();
    super.dispose();
  }

  /// Which page is under the top of the viewport, and telling the document.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    // **ISSUE 8.** Which page is at the top, from where the pages actually are
    // rather than from a fraction of the total. See `_tops`.
    final page = _layout?.pageAt(_scroll.offset) ?? 0;
    if (page != _current.value) {
      _current.value = page;
      widget.onPage(page);
    }
    _moving.value = true;
    _settle?.cancel();
    // Long enough to still be there when you stop to read the number, short
    // enough not to sit over the page.
    _settle = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) _moving.value = false;
    });
  }

  /// Open where it was left. **ISSUE 1B**, and exact since **ISSUE 8**.
  ///
  /// Once, not on every layout: this used to run from a post-frame callback on
  /// every build, so a rebuild while somebody was reading page 200 sent them
  /// back to where they came in.
  bool _restored = false;
  void _restore() {
    if (_restored || !_scroll.hasClients || _layout == null) return;
    _restored = true;
    if (widget.startAt <= 0) return;
    _goTo(widget.startAt, animate: false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    return LayoutBuilder(
      builder: (context, box) {
        // The device's real pixels, so a page is sharp rather than a
        // logical-pixel bitmap scaled up on a 3x screen.
        // ══ THE BASE PAGE IS DELIBERATELY NOT FULL DEVICE RESOLUTION ══════
        //
        // This asked for `logical width x devicePixelRatio`, clamped at 2400 —
        // about 1700 px on his tablet, which at a page's aspect is a bitmap of
        // roughly four million pixels. **Per page.** That is what made the
        // viewer *"feel like it has a stroke"*: even compressed on the way
        // across, decoding and holding several of those while scrolling is more
        // memory churn than the list can absorb.
        //
        // The ceiling is 1400 now, and the reason it costs nothing is the tile.
        // `_renderTile` already re-renders whatever is on screen at full
        // resolution the moment anybody zooms past `_zoomThreshold`, so the base
        // bitmap only ever has to look right at 1x — where 1400 px across a
        // ~686 pt column is still better than two device pixels per point.
        //
        // Sharpness at rest was never the thing that was wrong here.
        final dpr = MediaQuery.devicePixelRatioOf(context);

        // ══ MEASURED AT THE WIDTH THE PAGES ARE ACTUALLY DRAWN ════════════
        //
        // This was `min(box.maxWidth - gutter * 2, Layout.maxColumn)`, and on
        // a tablet that is a different number from the one the pages get.
        //
        // `LampColumnWidth` **is a pass-through** — it returns its child
        // untouched, since ISSUE 6b decided the day should fill the window —
        // so a page is drawn `box.maxWidth - gutter * 2` wide with no cap. On
        // the Redmi Pad that is 638 points while this said 608, so `PdfLayout`
        // believed every page was 5% shorter than it is.
        //
        // Five per cent does not matter on page two and it is **seven pages**
        // by page 145. So "open where you left it" landed in the wrong place,
        // and the page-number badge disagreed with the page under it, on any
        // screen wider than 656 points and on no phone at all — which is why
        // round fifteen's arithmetic looked correct when it was written and
        // was wrong on the only device this app is judged on.
        //
        // One number now, used for the layout and for the render width, so
        // they cannot drift apart again.
        final column = box.maxWidth - Layout.gutter * 2;
        final target = (column * dpr).clamp(320.0, 1400.0).round();

        // **ISSUE 8.** Where every page starts, from its measured shape. Done
        // before the list is built, so the first frame is already the right
        // length and nothing moves as bitmaps arrive.
        _measure(column);

        // ISSUE 1B. Restored after the first layout, because a scroll offset
        // means nothing until the list has one.
        WidgetsBinding.instance.addPostFrameCallback((_) => _restore());

        return Stack(
          children: [
            Listener(
              // ISSUE 1B — the pinch. `Listener` never joins the arena; it only
              // counts, which is the point. See `_pinching`.
              onPointerDown: (_) {
                _pointers++;
                if (_pointers == 2) setState(() {});
              },
              onPointerUp: (_) {
                _pointers = _pointers > 0 ? _pointers - 1 : 0;
                if (_pointers == 1) setState(() {});
              },
              onPointerCancel: (_) {
                _pointers = _pointers > 0 ? _pointers - 1 : 0;
                if (_pointers <= 1) setState(() {});
              },
              child: ListView.builder(
                controller: _scroll,
                // ── Only build what is nearly on screen ────────────────────
                //
                // The default cache extent is 250 logical pixels *plus* a full
                // viewport in each direction, and every `_PdfPage` starts a
                // render the moment it is built. On a document that meant three
                // or four pages decoding at once for a scroll that shows one.
                //
                // 200 keeps the next page warm enough that it is rarely blank
                // when it arrives, and stops the list speculatively rendering a
                // screenful in both directions.
                // ══ HOW LONG THE LIST IS, BEFORE ANY OF IT IS BUILT ═══
                //
                // The second reason page 145 never loaded, and the one that
                // made it look like the jump had not happened at all.
                //
                // A `ListView.builder` with no item extent does not know how
                // long it is. `maxScrollExtent` is an **estimate** from the
                // children built so far — and on the first frame that is two
                // or three pages. `_goTo` clamps to it. So the restore jump to
                // page 145 was clamped to somewhere around page three, and
                // `_restore` had already set `_restored = true`, so nothing
                // ever tried again.
                //
                // Every page's height is known before the document is drawn —
                // `MemoryPdf` measures the media boxes at open, which is what
                // `PdfLayout` is built from. Handing that to the list makes
                // `maxScrollExtent` exact on the very first frame, so the jump
                // lands, the scrollbar is honest, and a fling to the end goes
                // to the end.
                //
                // Matches `PdfLayout`'s own stride exactly — page height plus
                // one gap — because the two disagreeing is the whole class of
                // bug being fixed here.
                itemExtentBuilder: (i, _) =>
                    column * (widget.shapes?.shapeOf(i) ?? 1.414) + Space.x4,
                // ── How much is kept warm either side ──────────────────────
                //
                // > *"load 10 pages before that and 10 pages after that."*
                //
                // Not ten, and the arithmetic is the reason. A page here is a
                // bitmap about 1400 px across; at A4 that is 1400 x 1980 x 4
                // bytes — **eleven megabytes each**. Twenty-one of those is
                // 230 MB of bitmap, on a tablet where `dumpsys` already
                // records the system killing this app at 876 MB. Ten pages
                // either side would not make the viewer smooth, it would make
                // it the crash he reported in round fifteen.
                //
                // 900 keeps roughly a page warm in each direction, which is
                // what a finger can outrun, and costs about 22 MB. The thing
                // that actually made page 145 unreachable was the jump and the
                // dropped render, not the size of this number — both fixed
                // above, and a page you land on now appears at once.
                scrollCacheExtent: const ScrollCacheExtent.pixels(900),
                // Two fingers means a pinch. Handing the list
                // `NeverScrollableScrollPhysics` takes its drag recogniser out
                // of the tree, which leaves the arena to the page.
                physics: _pinching
                    ? const NeverScrollableScrollPhysics()
                    : null,
                padding: const EdgeInsets.symmetric(vertical: Space.x4),
                itemCount: widget.pages,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Layout.gutter, 0, Layout.gutter, Space.x4),
                  child: LampColumnWidth(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.sm),
                      child: ColoredBox(
                        color: c.surface,
                        child: _PdfPage(
                          index: i,
                          width: target,
                          // **ISSUE 8.** Its real shape, known before it is
                          // drawn, so the page occupies exactly the room it
                          // will keep. A4-until-it-arrives is what moved the
                          // document under the finger.
                          shape: widget.shapes?.shapeOf(i) ?? 1.414,
                          // A page nobody is looking at any more must not cost
                          // a render. See `_PdfPageState._render`.
                          stillWanted: () =>
                              mounted && (i - _current.value).abs() <= 3,
                          // So a page whose render was dropped can ask again
                          // the moment the reader lands on it. See
                          // `_PdfPageState._onCurrentChanged`.
                          current: _current,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── ISSUE 1B — the page number ───────────────────────
            //
            // *"What it misses? Page numbers."* There were none anywhere in the
            // app. It shows while you are moving and fades a moment after you
            // stop, which is what every reader on the phone does — you want it
            // when you are looking for a place and not while you are reading
            // one.
            if (widget.pages > 1)
              Positioned(
                right: Layout.gutter,
                bottom: Space.x6,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _moving,
                  // **ISSUE 8.** Ignored only while it is faded out: a badge
                  // you cannot see must not be a control you can hit, and one
                  // you can see now takes you to a page.
                  builder: (context, moving, child) => IgnorePointer(
                    ignoring: !moving,
                    child: AnimatedOpacity(
                      opacity: moving ? 1 : 0,
                      duration: Motion.duration(context),
                      curve: Motion.curve,
                      child: child,
                    ),
                  ),
                  child: ValueListenableBuilder<int>(
                    valueListenable: _current,
                    // ── ISSUE 8 — and now it is a way in, not only a label ──
                    //
                    // > *"IMAGINE HAVING A PDF SIZE – 50MB not an issue yes –
                    // > scroll to 50th page and see that doesn't even show
                    // > me!"*
                    //
                    // Half of that was the estimate being wrong, which the
                    // measured layout fixes. The other half is that there was
                    // no way to *ask* for page 50 — a hundred-page document is
                    // a finger-drag away from anywhere, and every reader on the
                    // phone lets you type the number instead.
                    builder: (context, page, _) => _GoToPage(
                      page: page,
                      pages: widget.pages,
                      onGo: _goTo,
                      child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Space.x3, vertical: Space.x2),
                      decoration: BoxDecoration(
                        color: c.raised,
                        borderRadius: BorderRadius.circular(Radii.full),
                        border: Border.all(color: c.borderHair),
                      ),
                      child: Text(
                        // Strings, not ints: the ARB declares them as
                        // String so `intl` cannot render Arabic-Indic or
                        // Devanagari digits here. The app is Latin-digit
                        // throughout — see the note in l10n/dates.dart.
                        L.of(context)
                            .docPageOf('${page + 1}', '${widget.pages}'),
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: c.inkSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                      ),
                    ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The page indicator, made tappable. **ROUND FIFTEEN, ISSUE 8.**
///
/// > *"scroll to 50th page and see that doesn't even show me!"*
///
/// Tapping it asks which page, and goes there. The badge is unchanged in every
/// other way — it still appears while you move and fades when you stop — so
/// nothing new sits over the document; what changed is that the thing already
/// telling you where you are will now take you somewhere.
///
/// `IgnorePointer` used to wrap the whole badge so it could never be tapped.
/// It still wraps it **while it is faded out**, because a control you cannot
/// see must not be a control you can hit.
class _GoToPage extends StatelessWidget {
  const _GoToPage({
    required this.page,
    required this.pages,
    required this.onGo,
    required this.child,
  });

  final int page;
  final int pages;
  final void Function(int page) onGo;
  final Widget child;

  Future<void> _ask(BuildContext context) async {
    final controller = TextEditingController(text: '${page + 1}');
    final l = L.of(context);
    final chosen = await showLampSheet<int>(
      context: context,
      title: l.docGoToPage,
      builder: (sheet) {
        void take() {
          final n = int.tryParse(controller.text.trim());
          Navigator.of(sheet).pop(n == null ? null : n - 1);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.go,
                // A search box is a list of the things somebody cares about;
                // so is the page of a document they are reading.
                enableIMEPersonalizedLearning: false,
                onSubmitted: (_) => take(),
                decoration: InputDecoration(
                  hintText: l.docPageOf('1', '$pages'),
                ),
              ),
              const SizedBox(height: Space.x4),
              LampButton(label: l.docGo, onPressed: take),
            ],
          ),
        );
      },
    );
    if (chosen != null) onGo(chosen.clamp(0, pages - 1));
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: L.of(context).docGoToPage,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.full),
          onTap: () => _ask(context),
          child: child,
        ),
      );
}

class _PdfPage extends StatefulWidget {
  const _PdfPage({
    required this.index,
    required this.width,
    required this.shape,
    required this.stillWanted,
    required this.current,
  });

  final int index;
  final int width;

  /// Which page the reader is on.
  ///
  /// == "IT NEEDS TO LOAD PAGES WHICH IS CURRENTLY OPENED". 3 Sept 2026 =====
  ///
  /// This page listens, and it is the difference between a viewer that always
  /// fills in and one that sometimes does not. See `_onCurrentChanged`.
  final ValueListenable<int> current;

  /// Height / width, measured when the document opened. **ISSUE 8.**
  ///
  /// The page takes exactly this much room from the first frame, before any
  /// bitmap exists. It used to be A4 for everything and then change when the
  /// render arrived, which moved every page below it — and the finger with it.
  final double shape;

  /// Whether this page is still worth drawing. **ISSUE 8.**
  ///
  /// Asked immediately before the channel call. A fling builds and disposes a
  /// page widget every few frames and every one of them used to fire a render
  /// on the way past, so the page somebody actually stopped on waited behind
  /// thirty that had already gone.
  final bool Function() stillWanted;

  @override
  State<_PdfPage> createState() => _PdfPageState();
}

class _PdfPageState extends State<_PdfPage>
    with SingleTickerProviderStateMixin {
  /// The whole page, drawn once at the width it is laid out at.
  ///
  /// This one never grows. However far in somebody zooms, this stays the
  /// modest bitmap it started as — see [_tile] for what gets sharper.
  ui.Image? _image;
  String? _error;

  /// The zoom and pan of this page.
  final _view = TransformationController();

  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _tween;

  /// The sharp patch laid over [_image] while zoomed in, and where it goes.
  ///
  /// [_tileRect] is in the page widget's own coordinates, so it can be handed
  /// straight to `Positioned.fromRect` inside the transformed child and lands
  /// exactly over the part of the page it was rendered from.
  ui.Image? _tile;
  Rect? _tileRect;

  /// The laid-out size of the page on screen. Captured in `build`, because it
  /// is the only place that knows it, and needed to turn a view transform into
  /// a rectangle of the page.
  Size? _childSize;

  /// A render is in flight, and whether another was asked for while it was.
  bool _rendering = false;
  bool _pending = false;

  Timer? _tileTimer;

  /// Below this, the page is not zoomed and the base bitmap is the truth.
  static const double _zoomThreshold = 1.05;

  /// A base render is in flight. Separate from [_rendering], which guards the
  /// sharp tile - the two can legitimately overlap, and sharing one flag would
  /// let a zoom cancel the page underneath it.
  bool _renderingBase = false;

  /// Whether the only thing on screen is the soft first pass.
  ///
  /// The quick render can land while the full one is dropped by `stillWanted`
  /// - a fling that stops on this page is exactly that sequence - and without
  /// this the page would keep its soft bitmap for ever, because
  /// `_onCurrentChanged` only asks again when there is *nothing* to show.
  /// Soft is much better than blank and still is not the answer.
  bool _onlyQuick = false;

  @override
  void initState() {
    super.initState();
    _render();
    _view.addListener(_onView);
    widget.current.addListener(_onCurrentChanged);
  }

  /// == THE PAGE YOU ARE LOOKING AT ALWAYS RENDERS ==========================
  ///
  /// > *"atleast it needs to load pages which is currently opened!"*
  ///
  /// He is describing this exactly. `_render` was called **once, from
  /// `initState`**, and when the request was dropped by `stillWanted` the
  /// catch block said:
  ///
  /// > *"the page will render when it is next built, which is when it is next
  /// > looked at."*
  ///
  /// **That sentence is false, and it is the whole bug.** By the time a render
  /// is abandoned the widget is already built. Nothing rebuilds it while you
  /// sit there, so it is never asked again - unless the page leaves the cache
  /// extent entirely and comes back. Which means a page could be **on screen,
  /// in front of you, permanently blank**, and the only way out was to scroll
  /// far away and return.
  ///
  /// It was worst exactly where he saw it. Land on page 145 after a jump: the
  /// render is dropped because `_current` has not caught up yet, so the one
  /// page he asked for is the one page guaranteed not to draw.
  ///
  /// So the page listens now, and asks again when the reader arrives and there
  /// is nothing to show. Cheap: one comparison per built page per scroll
  /// notification, and nothing at all once an image exists.
  void _onCurrentChanged() {
    if (!mounted) return;
    if (_renderingBase) return;
    // Nothing to show, or only the soft first pass. Both are worth asking
    // again for; a finished full-width page is not.
    if (_image != null && !_onlyQuick) return;
    if (!widget.stillWanted()) return;
    _render();
  }

  @override
  void dispose() {
    _tileTimer?.cancel();
    widget.current.removeListener(_onCurrentChanged);
    _view.removeListener(_onView);
    _view.dispose();
    _animation.dispose();
    _image?.dispose();
    _tile?.dispose();
    super.dispose();
  }

  double get _scale => _view.value.getMaxScaleOnAxis();

  /// ── ISSUE 1 — "PDF ZOOM CRASH!", and why the fix is a different shape ───
  ///
  /// The previous version of this file re-rendered the **whole page** at a
  /// larger size every time the zoom crossed a doubling: 1x, 2x, 4x, up to
  /// 4096 pixels across. The reasoning was sound — scaling a bitmap up five
  /// times gives five times the blur, and somebody zooming in wants to read
  /// small print, not see it larger and just as soft.
  ///
  /// The arithmetic was the problem. An A4 page at 4096 across is 4096 x 5793,
  /// which is 95 MB as a bitmap. Android allocated that, copied it into a
  /// second buffer of the same size to get the pixels out, and shipped a third
  /// copy over the channel to Dart, where Skia turned it into a texture. Close
  /// to 300 MB for one page, on a heap that is commonly 256 MB, while the
  /// neighbouring pages in the list held bitmaps of their own. It crashed, and
  /// it crashed *because* he zoomed, which is exactly the report.
  ///
  /// Lowering the cap would have made it rarer and blurrier — losing the
  /// feature to protect the process, and not reliably.
  ///
  /// **So the page stopped being the unit of work.** What is rendered now is
  /// the rectangle that is actually on screen, at screen resolution. Zoom to
  /// 8x and the rectangle is an eighth of the page, drawn into a bitmap the
  /// size of the phone's screen — about 9 MB, and *the same 9 MB at every
  /// magnification*, because the screen never gets any bigger. The text is
  /// sharper than the old path ever managed, because it is rasterised at the
  /// exact size it is displayed at rather than at the nearest power of two.
  ///
  /// This is what every real reader on the phone does, and it is why they can
  /// zoom further than this app could without running out of memory.
  ///
  /// Two details that matter:
  ///
  ///   * **The base page stays underneath.** The tile arrives a frame or two
  ///     after the gesture stops; until it does, the scaled-up base bitmap is
  ///     what you see, so the page is soft for an instant and then sharpens.
  ///     Blank would be worse.
  ///   * **The tile is dropped on the way back out.** At scale 1 it is not
  ///     just unnecessary, it is memory held for nothing on a page the user
  ///     has finished with.
  void _onView() {
    if (!mounted) return;
    // `panEnabled` and the tile's position both depend on the transform.
    setState(() {});
    if (_scale <= _zoomThreshold) {
      _dropTile();
      return;
    }
    _scheduleTile();
  }

  /// Coalesces a pinch into one render.
  ///
  /// Without this, dragging a pinch through thirty intermediate scales asks
  /// for thirty tiles, twenty-nine of which are stale before they arrive.
  void _scheduleTile() {
    _tileTimer?.cancel();
    _tileTimer = Timer(const Duration(milliseconds: 120), _renderTile);
  }

  void _dropTile() {
    _tileTimer?.cancel();
    final old = _tile;
    if (old == null) return;
    setState(() {
      _tile = null;
      _tileRect = null;
    });
    // After the frame that stopped using it, never before — disposing an image
    // the compositor still holds is a crash.
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  /// The first, whole-page render. Modest by construction and never repeated.
  ///
  /// ══ ROUND FIFTEEN, ISSUE 8 — "SHOWS ONLY FIRST TWO PAGES" ══════════════
  ///
  /// > *"Imagine a pdf is 40MB and has 10 pages - shows only first two pages
  /// > other pages?"*
  ///
  /// Forty megabytes over ten pages is four megabytes a page, which is a
  /// scanned photograph at each one. `PdfRenderer` decodes an embedded image at
  /// **its own** resolution before drawing it into our bitmap, so a page like
  /// that can want eighty megabytes of native heap that nothing here asked for
  /// or can see. The first pages fit; by the third the heap is gone, the
  /// renderer throws, and the old code turned that into a permanent *"This page
  /// could not be drawn"* — for every page after it, on every scroll back past.
  ///
  /// **So a page that will not draw is drawn smaller instead of not at all.**
  /// Half the width is a quarter of the pixels, and the tile path already
  /// re-renders whatever is on screen at full resolution the moment anybody
  /// zooms in — so a halved base page costs nothing anybody can see at rest
  /// and is the difference between a readable document and a wall of grey.
  ///
  /// Two halvings, then the message. A page that cannot be drawn at a quarter
  /// width is not a memory problem and pretending otherwise would just be
  /// three failures instead of one.
  Future<void> _render() async {
    if (_renderingBase) return;
    _renderingBase = true;
    try {
      await _renderBase();
    } finally {
      _renderingBase = false;
    }
  }

  /// The width of the first, throwaway pass.
  ///
  /// == "IT ISN'T FAST AND SMOOTH AS GOOGLE DRIVE PDF VIEWER" ===============
  ///
  /// > *"can you make the experience of pdf viewer the best? cause see it
  /// > isn't fast and smooth as google drive pdf viewer - or any lightweight
  /// > pdf viewer! it lags!"*
  ///
  /// What Drive does that this did not is **show you something immediately**.
  /// A page here was one render at full width - about 1,276 px on his tablet,
  /// which at A4 is 2.3 million pixels - and until that finished the page was
  /// blank. On a serial queue behind two or three neighbours, that is the lag
  /// he is describing. It was never slow arithmetic; it was one long wait with
  /// nothing on screen.
  ///
  /// So there are two passes. 400 px is about a tenth of the pixels and comes
  /// back in a fraction of the time - soft, obviously soft, and *there*. The
  /// full-width render replaces it a moment later and nothing moves, because
  /// the box was already the right size (see `PdfLayout`).
  ///
  /// Only ever for the first image of a page. A page that already has a bitmap
  /// re-renders straight to full width, so this never costs a second render
  /// for a page that is merely being resized.
  static const int _firstPassWidth = 400;

  Future<void> _renderBase() async {
    // The quick pass, so the page is not blank while the real one is queued.
    if (_image == null && widget.width > _firstPassWidth * 1.5) {
      try {
        final quick = await PdfRender.page(
          widget.index,
          width: _firstPassWidth,
          stillWanted: () => mounted && widget.stillWanted(),
        );
        if (!mounted) {
          quick.dispose();
        } else if (_image == null) {
          setState(() {
            _image = quick;
            _onlyQuick = true;
            _error = null;
          });
        } else {
          // The full pass beat it home. Vanishingly unlikely on one serial
          // queue, and disposing rather than assuming is what stops it being a
          // leak the day the queue changes.
          quick.dispose();
        }
      } on PdfRenderAbandoned {
        return;
      } catch (_) {
        // A failed quick pass is not a failure. The real render below is the
        // one that decides whether this page can be drawn at all.
      }
    }

    var width = widget.width;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final image = await PdfRender.page(
          widget.index,
          width: width,
          stillWanted: () => mounted && widget.stillWanted(),
        );
        if (!mounted) {
          image.dispose();
          return;
        }
        final old = _image;
        setState(() {
          _image = image;
          _onlyQuick = false;
          _error = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
        return;
      } on PdfRenderAbandoned {
        // Scrolled past while this was queued. Nothing was lost and nothing
        // needs saying.
        //
        // This used to claim the page would "render when it is next built,
        // which is when it is next looked at". It does not: the widget is
        // already built by the time a render is abandoned, and nothing
        // rebuilds it while somebody sits looking at it. `_onCurrentChanged`
        // is what makes that sentence true now - the page asks again when the
        // reader lands on it.
        return;
      } catch (_) {
        width = width ~/ 2;
        if (width < 200 || !mounted) break;
      }
    }
    if (mounted && _image == null) {
      setState(() => _error = L.of(context).docPageCouldNotBeDrawn);
    }
  }

  /// The sharp patch, covering whatever is on screen right now.
  Future<void> _renderTile() async {
    final size = _childSize;
    if (!mounted || size == null || size.width <= 0 || size.height <= 0) return;
    if (_scale <= _zoomThreshold) return;
    if (_rendering) {
      _pending = true;
      return;
    }

    // All of the arithmetic, and the guarantee that comes with it, lives in
    // ZoomTile — outside this widget so that `test/media/zoom_tile_test.dart` can
    // prove the memory property without a phone in the room.
    final tile = ZoomTile.of(
      child: size,
      view: _view.value,
      baseWidth: widget.width,
    );
    if (tile == null) return;

    _rendering = true;
    // ── ISSUE 8 — "when zoomed glitches" ───────────────────────────────
    //
    // The tile is rendered for the transform as it was when the request went
    // out, and positioned by `_tileRect`, which was computed from that same
    // transform. If the view moves while the render is in flight — and a pinch
    // is still settling 200 ms after the fingers lift — the sharp patch lands
    // over a part of the page it was not drawn from. That is the glitch: a
    // rectangle of the wrong bit of the document, crisply wrong.
    //
    // The matrix is captured here and compared on the way back. A tile that no
    // longer belongs is thrown away and another asked for, which costs one
    // render and is invisible; showing it would be a lie about where you are.
    final asked = _view.value.clone();
    try {
      final image = await PdfRender.page(
        widget.index,
        width: tile.width,
        region: tile.region,
        stillWanted: () => mounted && _scale > _zoomThreshold,
      );
      if (!mounted || _scale <= _zoomThreshold) {
        image.dispose();
        return;
      }
      if (!_sameView(asked, _view.value)) {
        image.dispose();
        _scheduleTile();
        return;
      }
      final old = _tile;
      setState(() {
        _tile = image;
        _tileRect = tile.rect;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
    } on PdfRenderAbandoned {
      // Zoomed back out before it arrived. The base page is what should be on
      // screen and it is.
    } catch (_) {
      // A failed tile must never destroy the readable page already on screen.
      // The base bitmap is still there and still legible; saying nothing is
      // right here, and is not the same as failing silently — nothing the user
      // asked for has been lost.
    } finally {
      _rendering = false;
      if (_pending && mounted) {
        _pending = false;
        _scheduleTile();
      }
    }
  }

  /// Whether two transforms are close enough that a tile drawn for one belongs
  /// over the other. **ISSUE 8.**
  ///
  /// Half a logical pixel of pan and half a per cent of scale. Tighter than
  /// that and every tile is thrown away by the last frame of an inertial pan;
  /// looser and a visibly misplaced patch gets through, which is the thing
  /// being fixed.
  static bool _sameView(Matrix4 a, Matrix4 b) {
    if ((a.getMaxScaleOnAxis() - b.getMaxScaleOnAxis()).abs() > 0.005) {
      return false;
    }
    final pa = a.getTranslation();
    final pb = b.getTranslation();
    return (pa.x - pb.x).abs() < 0.5 && (pa.y - pb.y).abs() < 0.5;
  }

  /// Double-tap to zoom, and double-tap again to come back.
  ///
  /// The other half of "work like a normal PDF viewer": every reader on the
  /// phone does this, and on a page of small print it is far quicker than a
  /// pinch. It zooms **towards the point that was tapped** rather than the
  /// centre of the page, which is the difference between landing on the
  /// paragraph you wanted and landing near it.
  void _doubleTap(TapDownDetails details) {
    final zoomed = _scale > _zoomThreshold;
    final Matrix4 target;
    if (zoomed) {
      target = Matrix4.identity();
    } else {
      const factor = 2.5;
      final p = details.localPosition;
      target = Matrix4.identity()
        ..translateByDouble(-p.dx * (factor - 1), -p.dy * (factor - 1), 0, 1)
        ..scaleByDouble(factor, factor, factor, 1);
    }
    _tween = Matrix4Tween(begin: _view.value, end: target).animate(
      CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic),
    );
    _animation
      ..removeListener(_drive)
      ..addListener(_drive)
      ..forward(from: 0);
  }

  void _drive() {
    final t = _tween;
    if (t != null) _view.value = t.value;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final image = _image;
    if (image == null) {
      return AspectRatio(
        // **ISSUE 8.** Its measured shape, not A4. This is the whole of "the
        // document stops moving under your finger": the page occupies exactly
        // the room it will keep, from the first frame, before any bitmap
        // exists.
        aspectRatio: 1 / widget.shape,
        child: Center(
          child: _error == null
              ? const LampBusy(size: 28)
              : Text(_error!,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: c.inkMuted)),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: image.width / image.height,
      child: LayoutBuilder(
        builder: (context, box) {
          // The one place that knows how big the page is on screen.
          _childSize = box.biggest;

          final tile = _tile;
          final tileRect = _tileRect;
          // `fill` rather than `contain`: the AspectRatio above already matches
          // the page, so they are the same picture — but `fill` guarantees the
          // image's coordinates are the box's coordinates, which is what makes
          // the tile land where it was rendered from.
          final page = Stack(
            fit: StackFit.expand,
            children: [
              RawImage(image: image, fit: BoxFit.fill),
              if (tile != null && tileRect != null)
                Positioned.fromRect(
                  rect: tileRect,
                  child: RawImage(image: tile, fit: BoxFit.fill),
                ),
            ],
          );

          // ── Why the page is dimmed in dark mode rather than inverted ─────
          //
          // A PDF page is ink on nothing, so it is drawn on white. Full white
          // against this app's warm near-black is a torch in a dark room. A
          // per-pixel invert is the usual trick and it is wrong for documents:
          // it turns photographs into negatives and coloured logos into
          // something nobody would recognise.
          //
          // So the whole page is dimmed a little instead. It stays a picture of
          // the document, and it stops being painful to look at at eleven
          // o'clock. Applied over the Stack so the sharp tile is dimmed by
          // exactly as much as the page under it — dimming them separately
          // would put a visible bright rectangle over the part being read.
          final dimmed = Theme.of(context).brightness != Brightness.dark
              ? page
              : ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.86, 0, 0, 0, 0, //
                    0, 0.86, 0, 0, 0, //
                    0, 0, 0.86, 0, 0, //
                    0, 0, 0, 1, 0, //
                  ]),
                  child: page,
                );

          // ── One viewer per page, deliberately ──────────────────────────
          //
          // The alternative is a single `InteractiveViewer` wrapped around the
          // whole `ListView`, which is how a viewer that zooms the *document*
          // would work. It was not done, because an `InteractiveViewer` and a
          // vertical `ListView` inside it fight over every vertical drag: the
          // list wants to scroll and the viewer wants to pan, and the
          // arbitration between them is ambiguous at scale 1 in a way no amount
          // of `panEnabled` juggling settles cleanly. The failure mode is a
          // document that intermittently refuses to scroll, which is worse than
          // the thing being fixed.
          //
          // Per page, there is no conflict: the list owns vertical drags, each
          // page owns pinches and — once zoomed — its own panning. Zoom stays
          // where it was applied rather than following you down the document,
          // which is also what happens in most readers on a phone.
          return GestureDetector(
            onDoubleTapDown: _doubleTap,
            // Needed, and empty on purpose: without a double-tap handler the
            // recogniser never fires and `onDoubleTapDown` alone is never
            // called.
            onDoubleTap: () {},
            child: InteractiveViewer(
              transformationController: _view,
              minScale: 1,
              maxScale: 8,
              // Only once there is something to pan to. At scale 1 this leaves
              // every drag to the list underneath.
              panEnabled: _scale > _zoomThreshold,
              clipBehavior: Clip.hardEdge,
              child: dimmed,
            ),
          );
        },
      ),
    );
  }
}

/// A text or Markdown file, as text.
///
/// **Not a Markdown renderer.** A real one is a dependency, and `CLAUDE.md`
/// rule 4 says every package can read all of the user's notes. What is here is
/// the part that matters for reading a `.md` in a journal: it is set in the
/// user's own writing face, it is selectable, and the source is legible. Headed
/// lines get a little more weight so the structure is visible, and nothing else
/// is interpreted — an asterisk stays an asterisk rather than half-disappearing.
class _TextBody extends StatelessWidget {
  const _TextBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Layout.gutter),
      child: LampColumnWidth(
        child: SelectableText(
          text.isEmpty ? L.of(context).docFileEmpty : text,
          style: writingStyle(context).copyWith(
            color: text.isEmpty ? c.inkMuted : c.inkPrimary,
          ),
        ),
      ),
    );
  }
}

/// A picture that arrived as a document rather than as a photo.
///
/// Rare but real: a PNG picked through the file picker instead of the photo
/// picker, or a GIF the picker could not put a MIME type to.
///
/// **It animates**, because [EncryptedImage] hands its codec to a
/// `MultiFrameImageStreamCompleter` and that is what a multi-frame image needs.
/// `gaplessPlayback` so the first frame does not flash white on a rebuild.
class _ImageBody extends StatelessWidget {
  const _ImageBody({required this.attachment, required this.store});

  final Attachment attachment;
  final AttachmentStore store;

  @override
  Widget build(BuildContext context) {
    // ── The caps, and why this path had none ─────────────────────────────
    //
    // `photo_viewer.dart` has carried both of these since round nine's ISSUE
    // IMPORTANT, where one long screenshot decoded at full resolution ran to
    // hundreds of megabytes and Android killed the process mid-pinch. This
    // screen draws the same kind of file -- a PNG or a GIF that came through
    // the *file* picker rather than the photo one, which in practice means a
    // screenshot or a scan -- inside a viewer that zooms to 6x, and asked for
    // it at its full native size.
    //
    // So the identical picture was safe if imported as a photo and could kill
    // the app if imported as a document. Found by an audit on 3 September 2026,
    // not by a crash, which is the only reason it is not in `exit-info` yet.
    //
    // `maxWidth` is what is actually looked at; `maxPixels` is the backstop
    // that cannot be defeated by an aspect ratio nobody thought of. See
    // `EncryptedImage.maxPixels`.
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final budget =
        (size.width * dpr * size.height * dpr * 2).round().clamp(
              2 * 1024 * 1024,
              16 * 1024 * 1024,
            );

    return InteractiveViewer(
      maxScale: 6,
      child: Padding(
        padding: const EdgeInsets.all(Space.x2),
        child: Image(
          image: EncryptedImage(
            attachment,
            store: store,
            maxWidth: (size.width * dpr).round().clamp(720, 4096),
            maxPixels: budget,
          ),
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

/// What the app says instead of nothing.
class _Explained extends StatelessWidget {
  const _Explained({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;

  /// What to offer instead. **ISSUE 4** — this used to be "Save a copy" in
  /// every case; it is "Open with…" now, because lending a file leaves nothing
  /// behind and saving one does. Saving is still a tap away in the menu.
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Layout.gutter),
        child: LampColumnWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined, size: 40, color: c.inkMuted),
              const SizedBox(height: Space.x5),
              Text(
                message,
                textAlign: TextAlign.center,
                style: t.bodyLarge?.copyWith(color: c.inkSecondary),
              ),
              const SizedBox(height: Space.x8),
              LampButton(label: actionLabel, onPressed: onAction),
            ],
          ),
        ),
      ),
    );
  }
}
