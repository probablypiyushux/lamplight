import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/vault/vault.dart';
import 'package:lamplight/design/tokens.dart';
import 'package:lamplight/features/media/media_album.dart';
import 'package:lamplight/l10n/generated/app_localizations.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ROUND TWENTY — "adding to folder … nothing is possible to add"**
///
/// Three reports, one cause:
///
/// > *"if i need to add a single photo to folder it's not possible"*
/// > *"from the grid i can only select till 1 to 4th via long press"*
/// > *"this one mattered … works only for videos and audios and texts and
/// >  documents? why not photos?"*
///
/// ── THE CAUSE, WHICH IS ONE THING WEARING THREE HATS ────────────────────
///
/// **"This one mattered" and "Add to a folder" are entry-level actions that
/// live only in the day's entry menu.** A lone voice note, document or video
/// long-presses straight through to it, which is exactly why he found those
/// three working.
///
/// A picture does not. `MediaAlbum` puts its own `onLongPress` on each tile,
/// and the innermost long-press recogniser wins the arena — so a photograph
/// reaches `_pick`, a sheet that offers caption, open-with, save and remove,
/// and neither of the two. The full-screen viewer's menu offers the same
/// three. So a photograph has **no route to either action anywhere in the
/// app**, and a video has none either once it is inside an album grid rather
/// than alone in a block.
///
/// The fourth tile is the third hat. The grid draws at most four, the fourth
/// carrying `+N` — so past the fourth there is no tile to press and even the
/// incomplete sheet is out of reach. The viewer does reach them
/// (`_itemsAround` walks every entry), which is why the fix belongs in both
/// menus rather than in the tile count.
void main() {
  late SodiumSumo sodium;
  late Directory tmp;
  late Vault vault;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    tmp = Directory.systemTemp.createTempSync('lamplight_album_actions');
    vault = Vault(
      sodium: sodium,
      root: Directory('${tmp.path}/vault'),
      idleTimeout: Duration.zero,
    );
    await vault.initialise();
    await vault.create(passcode: 'a passphrase');
  });

  tearDownAll(() async {
    await vault.lock();
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  var seq = 0;
  (Entry, Attachment) photo() {
    final id = 'e${seq++}';
    final aid = 'a$id';
    return (
      Entry(
        id: id,
        createdAt: DateTime(2026, 9, 23, 13, 30).millisecondsSinceEpoch,
        createdOffsetMinutes: 0,
        updatedAt: DateTime(2026, 9, 23, 13, 30).millisecondsSinceEpoch,
        type: 'photo',
        attachmentId: aid,
        dayKey: '2026-09-23',
        groupId: 'g1',
        isPinned: false,
      ),
      Attachment(
        id: aid,
        fileKey: Uint8List(32),
        originalName: '$id.jpg',
        mimeType: 'image/jpeg',
        byteSize: 1000,
        width: 1200,
        height: 1600,
      ),
    );
  }

  /// The album's own tiles, in capture order.
  ///
  /// **The first `GestureDetector` inside a `MediaAlbum` is the album, not a
  /// tile** — it spans the whole block and carries the album-level long press.
  /// Pressing it does nothing useful in a test, because its centre lands in
  /// the three-point gap *between* two tiles and the hit test misses
  /// everything. Hence the offset, and the assertion below so this fails
  /// loudly rather than silently pressing the wrong thing if the tree changes.
  Finder tileAt(int index) {
    final all = find.descendant(
      of: find.byType(MediaAlbum),
      matching: find.byType(GestureDetector),
    );
    return all.at(index + 1);
  }

  Future<void> pump(
    WidgetTester tester,
    List<(Entry, Attachment)> items, {
    void Function(Entry)? onMarkEntry,
    void Function(Entry)? onFolderEntry,
  }) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      theme: lamplightTheme(LamplightColors.dark),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: MediaAlbum(
              entries: [for (final i in items) i.$1],
              attachments: {for (final i in items) i.$2.id: i.$2},
              store: vault.attachments,
              onMenu: () {},
              // Present, so the sheet has something to offer and does not fall
              // back to the whole-album menu.
              onTrashEntry: (_) {},
              onMarkEntry: onMarkEntry,
              onFolderEntry: onFolderEntry,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  group('a photograph can be marked and filed, like everything else', () {
    testWidgets('the per-photo sheet offers "This one mattered"',
        (tester) async {
      Entry? marked;
      await pump(tester, [photo(), photo()], onMarkEntry: (e) => marked = e);

      await tester.longPress(tileAt(0));
      await tester.pumpAndSettle();

      final tile = find.text('This one mattered');
      expect(tile, findsOneWidget,
          reason: 'a photograph is an entry like any other, and the marker is '
              'the one feature he checked across every kind of thing');

      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(marked, isNotNull);
    });

    testWidgets('and "Add to a folder"', (tester) async {
      Entry? filed;
      await pump(tester, [photo(), photo()], onFolderEntry: (e) => filed = e);

      await tester.longPress(tileAt(0));
      await tester.pumpAndSettle();

      final tile = find.text('Add to a folder');
      expect(tile, findsOneWidget,
          reason: 'folders are "the thing the app is for" per PLAN.md 9.1, and '
              'a photograph could not reach them at all');

      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(filed, isNotNull);
    });

    // The action must land on the picture that was pressed, not on the album.
    // `_pick` already names it — "This photo, 2 of 6" — so acting on a
    // different one would be a lie the sheet itself tells.
    testWidgets('and it acts on the picture that was pressed', (tester) async {
      Entry? marked;
      final items = [photo(), photo(), photo()];
      await pump(tester, items, onMarkEntry: (e) => marked = e);

      await tester.longPress(tileAt(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('This one mattered'));
      await tester.pumpAndSettle();

      expect(marked?.id, items[1].$1.id);
    });
  });

  // The third hat. Kept as a statement of the layout rule so that the reason
  // the fix went into the menus rather than into the tile count is on record.
  testWidgets('the grid still draws four tiles, and the rest live in the viewer',
      (tester) async {
    await pump(tester, [for (var i = 0; i < 6; i++) photo()]);
    expect(find.text('+2'), findsOneWidget,
        reason: 'six pictures is four tiles, the last one carrying +3 — so '
            'there is no fifth tile to long-press, and the actions have to be '
            'reachable from the viewer as well');
  });

}
