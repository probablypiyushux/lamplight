import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../core/db/database.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

/// The three-dot menu on a full-screen photo or video. **ISSUE D.**
///
/// He drew the viewer as a rectangle with "has photo | video" in it, an arrow
/// to a three-dot glyph, and two rows under it: *Save photo* and *trash*.
///
/// It is worth being clear why the viewer needed its own menu when the day
/// already has one. The day's menu is on the *block*, reached by a long press
/// on the thumbnail — so to delete a photograph you were looking at, you had to
/// leave the picture, find the block it came from, long-press it, and pick the
/// right row. On an album of four that is four thumbnails that look alike at
/// 80 points, which is exactly the aiming problem ISSUE 11 describes in the
/// trash. The action belongs where the thing is.
///
/// **Trash and not Delete**, and that is not a slip against ISSUE C's "keep the
/// wording same". C is about two words for one act; this is the *place* things
/// go, which the app already calls the Trash on its own screen and in its own
/// settings row. Naming the destination is what makes it obvious the picture is
/// recoverable — and after ISSUE C it genuinely is, from here as from
/// everywhere else.
Future<void> showViewerMenu({
  required BuildContext context,
  required String kind,
  VoidCallback? onSave,
  VoidCallback? onTrash,
  VoidCallback? onOpenWith,
}) async {
  if (onSave == null && onTrash == null && onOpenWith == null) return;
  await showLampSheet<void>(
    context: context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          const SizedBox(height: Space.x2),
          // ── ISSUE 4, 13 — first, because it is the safer of the two ────
          //
          // "Give me an option to open the file anywhere else… I want it on
          // every file type/format."
          //
          // Above "Save", deliberately. Saving writes a copy the user then owns
          // and has to remember; this lends one that is destroyed again a
          // minute later. When two rows do nearly the same thing, the one that
          // leaves less behind should be the one under the thumb.
          if (onOpenWith != null)
            LampTile(
              title: L.of(context).docOpenWith,
              subtitle: L.of(context).menuOpenWithNote,
              icon: Icons.open_in_new,
              onTap: () {
                Navigator.of(sheet).pop();
                onOpenWith();
              },
            ),
          if (onSave != null)
            LampTile(
              title: L.of(context).menuSaveKind(kind),
              subtitle: L.of(context).entrySaveCopyNote,
              icon: Icons.save_alt,
              onTap: () {
                Navigator.of(sheet).pop();
                onSave();
              },
            ),
          if (onTrash != null)
            LampTile(
              title: L.of(context).settingsTrash,
              subtitle: L.of(context).menuTrashNote,
              icon: Icons.delete_outline,
              danger: true,
              onTap: () {
                Navigator.of(sheet).pop();
                onTrash();
              },
            ),
      ],
    ),
  );
}

/// What one attachment should be called in that menu.
String viewerKindFor(Attachment? a, {required bool video}) {
  if (video) return 'video';
  final mime = (a?.mimeType ?? '').toLowerCase();
  final name = (a?.originalName ?? '').toLowerCase();
  if (mime == 'image/gif' || name.endsWith('.gif')) return 'GIF';
  return 'photo';
}
