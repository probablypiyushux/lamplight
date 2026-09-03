import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../settings/design_names.dart';

import '../../core/platform/capture.dart';
import '../../core/settings/app_settings.dart';
import '../../core/settings/photo_quality.dart';
import '../../core/settings/video_quality.dart';
import '../../core/storage/attachment_importer.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

/// What was chosen about one batch, on its way in.
@immutable
class MediaSizeChoice {
  const MediaSizeChoice({required this.photo, required this.video});

  final PhotoQuality photo;
  final VideoQuality video;
}

/// Asks how big to keep the things somebody has just picked. **ISSUE 6.**
///
/// > *"Photos and videos sizes — ask when uploading! The setting just has video
/// > size."*
///
/// ══ ONE QUESTION, NOT TWO ══════════════════════════════════════════════════
///
/// Photographs and videos are compressed by different machinery on different
/// settings, and asking about them separately would be the app's plumbing
/// showing through — which is exactly what ISSUE 16 is about. Somebody who has
/// just picked fourteen things off their camera roll is not thinking about
/// which of them are videos.
///
/// So it is **one** three-way choice, applied to whatever is in the batch. The
/// two enums share their ids for this reason and the sheet reads the answer
/// into both.
///
/// ══ AND HOW IT AVOIDS BECOMING A NAG ═══════════════════════════════════════
///
/// `ETHICAL-DESIGN.md` is right that a question on every import is worse than
/// no question, because a question asked every time is answered without being
/// read — which has the appearance of consent and none of the substance. Three
/// things keep this honest:
///
///   * it is asked **once per batch**, not once per file;
///   * it is not asked at all when nothing in the batch could be made smaller,
///     because *"how should this PDF be compressed"* is a question with no
///     answer; and
///   * *"Do not ask again"* turns it off for good and means it. It does not
///     hide behind a timer, it is not undone by a later version, and the switch
///     that undoes it is named in the same words in Settings.
///
/// Returns null when the sheet is dismissed without an answer — which is a
/// person changing their mind about the whole import, not a person choosing
/// the default. The caller drops the batch.
Future<MediaSizeChoice?> askAboutSize({
  required BuildContext context,
  required AppSettings settings,
  required List<CapturedFile> files,
}) async {
  // Nothing here can be made smaller: documents, text, anything the app stores
  // exactly as it arrived. Not a question.
  final hasPhoto = files.any((f) => AttachmentImporter.typeForMime(f.mimeType, f.name) == 'photo');
  final hasVideo = files.any((f) => AttachmentImporter.typeForMime(f.mimeType, f.name) == 'video');
  if (!hasPhoto && !hasVideo) {
    return MediaSizeChoice(
      photo: settings.photoQuality,
      video: settings.videoQuality,
    );
  }

  if (!settings.askAboutMediaSize) {
    return MediaSizeChoice(
      photo: settings.photoQuality,
      video: settings.videoQuality,
    );
  }

  // Whichever of the two settings applies to what is actually in the batch, so
  // the sheet opens on the answer this person has already given rather than on
  // a fresh default every time.
  final current =
      hasPhoto ? settings.photoQuality.id : settings.videoQuality.id;

  return showModalBottomSheet<MediaSizeChoice>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => _SizeSheet(
      settings: settings,
      current: current,
      // The noun in the title is what is actually being added, because "media"
      // is a word for a category and nobody has ever picked one.
      what: hasPhoto && hasVideo
          ? (files.length > 1
              ? L.of(context).sizeTheseOnes
              : L.of(context).sizeThisOne)
          : hasPhoto
              ? (files.length > 1
                  ? L.of(context).sizeThesePhotos
                  : L.of(context).sizeThisPhoto)
              : (files.length > 1
                  ? L.of(context).sizeTheseVideos
                  : L.of(context).sizeThisVideo),
    ),
  );
}

class _SizeSheet extends StatefulWidget {
  const _SizeSheet({
    required this.settings,
    required this.current,
    required this.what,
  });

  final AppSettings settings;
  final String current;
  final String what;

  @override
  State<_SizeSheet> createState() => _SizeSheetState();
}

class _SizeSheetState extends State<_SizeSheet> {
  late String _chosen = widget.current;

  void _take({required bool remember}) {
    if (remember) {
      // "Do not ask again" also **records the answer**, which is the only
      // reading of it that is not a trap: somebody who chooses "keep the
      // original" and then asks not to be asked again plainly means every
      // future import should keep the original, not that every future import
      // should silently go back to Balanced.
      widget.settings.photoQuality = PhotoQuality.fromId(_chosen);
      widget.settings.videoQuality = VideoQuality.fromId(_chosen);
      widget.settings.askAboutMediaSize = false;
    }
    Navigator.of(context).pop(MediaSizeChoice(
      photo: PhotoQuality.fromId(_chosen),
      video: VideoQuality.fromId(_chosen),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    // Photo and video notes for the same id, so the sheet describes what will
    // actually happen to what is in front of it rather than a general policy.
    final options = <(String, String, String)>[
      for (final q in PhotoQuality.values)
        (q.id, q.labelIn(L.of(context)), q.noteIn(L.of(context))),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Space.x6, Space.x5, Space.x6, Space.x2),
              child: Text(L.of(context).sizeQuestion(widget.what),
                  style: t.titleLarge),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(Space.x6, 0, Space.x6, Space.x4),
              child: Text(
                // The part that makes the question worth asking, said once and
                // without drama. It is also the honest reason this exists: the
                // decision cannot be revisited later, because the original will
                // not be there to revisit it with.
                L.of(context).sizeOneCopy,
                style: t.bodyMedium
                    ?.copyWith(color: c.inkSecondary, height: 1.45),
              ),
            ),
            Divider(height: 1, color: c.borderHair),
            for (final (id, label, note) in options)
              LampChoiceTile<String>(
                title: label,
                subtitle: note,
                value: id,
                groupValue: _chosen,
                // Chosen, not applied. Unlike every other choice sheet in the
                // app this one has something to confirm afterwards — whether to
                // be asked again — so closing on tap would take that away.
                onChanged: (v) => setState(() => _chosen = v),
              ),
            Divider(height: 1, color: c.borderHair),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Space.x6, Space.x4, Space.x6, Space.x2),
              child: LampButton(
                label: L.of(context).sizeAdd,
                onPressed: () => _take(remember: false),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(Space.x6, 0, Space.x6, Space.x4),
              child: TextButton(
                onPressed: () => _take(remember: true),
                child: Text(
                  L.of(context).sizeAddAlways,
                  style: TextStyle(color: c.inkSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
