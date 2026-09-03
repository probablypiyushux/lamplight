import 'package:flutter/material.dart';

import 'design_names.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/photo_quality.dart';
import '../../core/settings/video_quality.dart';
import '../../design/components.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../design/tokens.dart';
import 'settings_screen.dart' show showLampChoiceSheet;
import 'transcription_tiles.dart';

/// Photographs, video and sound — everything about what a captured file
/// becomes once it is inside the vault.
///
/// ══ WHY THIS IS ITS OWN SCREEN NOW ══════════════════════════════════════════
///
/// > *"I want you to break down the settings now! to make it more easier! ...
/// > I don't want to cut in so many parts! but make a logical division between
/// > them! ... not everything under one tab - you notes - setting - be a
/// > gentleman!"*
///
/// "Your notes" had become the place things went when there was nowhere else.
/// It held ten rows: automatic backup, back up, readable copy, bring in an old
/// journal, language, photo size, video size, ask each time, transcription and
/// trash — four unrelated subjects in one list, and the list was longer than
/// the screen.
///
/// The division is by **question asked**, not by feature:
///
///   * how the app looks and speaks       → Appearance, Language
///   * what happens to what you capture   → *this screen*
///   * where it is kept and how it moves  → Back up, Readable copy, Bring in
///   * who can open it                    → Locking and security
///
/// Five rows here, all answering one question: what does Lamplight do to a
/// photograph, a video or a recording on its way in. Nothing else fits and
/// nothing here fits anywhere else.
///
/// **Transcription is on this screen and not with Language**, which is the one
/// placement worth defending. A transcript is what happens to a recording —
/// the same kind of fact as how much a photograph is compressed. The language
/// it is transcribed *in* is a setting of that, so it lives beside it. See
/// `transcription_tiles.dart` for the naming, which is what he was actually
/// complaining about: *"two languages are disturbing"*.
class MediaSettingsScreen extends StatelessWidget {
  const MediaSettingsScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => LampPage(
        title: L.of(context).settingsMedia,
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.x10),
          children: [
            LampGroup(
              label: L.of(context).mediaGroupIncoming,
              footer: L.of(context).mediaIncomingFooter,
              children: [
                // Photographs above video: a person adds far more of them, and
                // the two are the same question about two kinds of thing.
                _PhotoQualityTile(settings: settings),
                _VideoQualityTile(settings: settings),
                _AskAboutSizeTile(settings: settings),
              ],
            ),
            // ══ "WHAT ABOUT DOCUMENT - SIZING? GIVE AN OPTION FOR THAT
            //    TOO! IN THE TAB!" 2 September 2026 ═══════════════════════
            //
            // There is no control here, and the group exists to say why in
            // the place he went looking for it. That is not a fob-off: the
            // measurement was done on his own files before this was written.
            //
            // Lossless compression — the kind that cannot damage anything —
            // gains **3.7% on Issues.pdf, 6.5% on New Issues.pdf and 7.1% on
            // Issues.docx**, because a PDF and a .docx are already compressed
            // inside. `PLAN.md` §8.4's own rule applies: a setting whose
            // effect nobody can see is not a setting, and that is the same
            // argument that raised the paper grain in round eight.
            //
            // The compression that *would* halve a scanned document is lossy
            // re-encoding of the images in it, and that is refused. A photo
            // re-encoded is still the photo and you can see the difference
            // immediately. A marksheet, a statement or a signed scan at lower
            // resolution has **permanently unreadable small text**, and you
            // would not find out on the day it happened — you would find out
            // years later, on the day you needed to read it. That is the
            // wrong trade for an app whose whole purpose is keeping things.
            //
            // The load argument does not hold either: the viewer renders
            // tiles at screen resolution, so how long a document takes to
            // open is not a function of its file size.
            LampGroup(
              label: L.of(context).mediaGroupDocuments,
              footer: L.of(context).mediaDocumentsFooter,
              children: [
                LampTile(
                  title: L.of(context).mediaDocumentsKept,
                  icon: Icons.description_outlined,
                  enabled: true,
                ),
              ],
            ),
            LampGroup(
              label: L.of(context).mediaGroupVoice,
              footer: L.of(context).mediaVoiceFooter,
              children: [
                TranscriptionTiles(settings: settings),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// How much a video is squeezed on the way in. **ROUND EIGHT, ISSUE 2A.**
///
/// Stateful only so the row can redraw with the new answer the moment it is
/// chosen. `AppSettings` writes through to disk on assignment; this exists
/// because the row above it would otherwise still be showing the old value
/// while the file already held the new one.
/// **ROUND NINE, ISSUE 6** — *"the setting just has video size"*.
class _PhotoQualityTile extends StatefulWidget {
  const _PhotoQualityTile({required this.settings});

  final AppSettings settings;

  @override
  State<_PhotoQualityTile> createState() => _PhotoQualityTileState();
}

class _PhotoQualityTileState extends State<_PhotoQualityTile> {
  @override
  Widget build(BuildContext context) {
    final quality = widget.settings.photoQuality;
    return LampTile(
      title: L.of(context).mediaPhotoSize,
      // The note is the honest half, exactly as on the video row. "Keep the
      // original" says it keeps the location the photograph was taken;
      // "Smaller" says you may notice it. A setting that lists only the upside
      // of each option is not offering a choice.
      subtitle: quality.noteIn(L.of(context)),
      value: quality.labelIn(L.of(context)),
      icon: Icons.photo_outlined,
      onTap: () => showLampChoiceSheet<PhotoQuality>(
        context: context,
        title: L.of(context).mediaPhotoSize,
        current: quality,
        options: [
          for (final q in PhotoQuality.values)
            (q, q.labelIn(L.of(context)), q.noteIn(L.of(context))),
        ],
        onChanged: (q) => setState(() => widget.settings.photoQuality = q),
      ),
    );
  }
}

/// Whether to be asked at the moment something is added. **ISSUE 6.**
///
/// This is the switch that undoes *"Add, and do not ask again"*, and it is
/// named in the same words on purpose: a choice a person can turn off and
/// cannot find again is a choice they made once and are now stuck with.
class _AskAboutSizeTile extends StatefulWidget {
  const _AskAboutSizeTile({required this.settings});

  final AppSettings settings;

  @override
  State<_AskAboutSizeTile> createState() => _AskAboutSizeTileState();
}

class _AskAboutSizeTileState extends State<_AskAboutSizeTile> {
  @override
  Widget build(BuildContext context) {
    final on = widget.settings.askAboutMediaSize;
    return LampSwitchTile(
      title: L.of(context).mediaAskEachTime,
      subtitle: on
          ? L.of(context).mediaAskEachTimeOn
          : L.of(context).mediaAskEachTimeOff,
      value: on,
      onChanged: (v) =>
          setState(() => widget.settings.askAboutMediaSize = v),
    );
  }
}

class _VideoQualityTile extends StatefulWidget {
  const _VideoQualityTile({required this.settings});

  final AppSettings settings;

  @override
  State<_VideoQualityTile> createState() => _VideoQualityTileState();
}

class _VideoQualityTileState extends State<_VideoQualityTile> {
  @override
  Widget build(BuildContext context) {
    final quality = widget.settings.videoQuality;
    return LampTile(
      title: L.of(context).mediaVideoSize,
      // The note is the honest half. "Keep the original" says it makes the
      // largest files; "Smaller" says you may notice it. A setting that only
      // lists the upsides of each option is not offering a choice.
      subtitle: quality.noteIn(L.of(context)),
      value: quality.labelIn(L.of(context)),
      icon: Icons.videocam_outlined,
      onTap: () => showLampChoiceSheet<VideoQuality>(
        context: context,
        title: L.of(context).mediaVideoSize,
        current: quality,
        options: [
          for (final q in VideoQuality.values)
            (q, q.labelIn(L.of(context)), q.noteIn(L.of(context))),
        ],
        onChanged: (q) => setState(() => widget.settings.videoQuality = q),
      ),
    );
  }
}
