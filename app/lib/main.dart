import 'dart:io';
import 'l10n/dates.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sodium/sodium_sumo.dart';

import 'app.dart';
import 'core/platform/orientation.dart';
import 'core/platform/transcription.dart';
import 'core/settings/app_settings.dart';
import 'core/platform/system_excursion.dart';
import 'core/db/vault_changed.dart';
import 'core/vault/vault.dart';
import 'features/backup/silent_backup.dart';
import 'features/error/error_surface.dart';

/// Entry point.
///
/// The Phase 1 debug screen that used to live here is gone — it existed only to
/// prove the vault core worked on real hardware, it did that on 18 August 2026,
/// and `06-for-you/ROADMAP.md` said every line of it would be deleted. The
/// evidence it produced is kept in `02-security/EXIT-TEST-EVIDENCE.md`.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Before anything else that could fail ─────────────────────────────────
  //
  // ISSUE 15. Until this line existed, any error anywhere in the app went to
  // the screen as a red-and-yellow developer panel in debug and a featureless
  // grey box in release. The user must never see either. Installed first, so it
  // covers the vault opening as well as every screen after it.
  installCalmErrors();

  // ── The date words, before the first frame that could ask for one ───────
  //
  // `intl` loads its date symbols per locale and a `DateFormat` for a locale
  // that has not been initialised **throws**. Every date in the app goes
  // through `LampDates` now, so without this the lock screen would render in
  // English and fail the moment somebody set the app to Japanese.
  //
  // Awaited, unlike the reminder below. It is a few milliseconds of loading
  // tables that are already in the bundle, and the alternative is a race
  // between the first frame and the data it needs.
  await LampDates.prepare();

  // ── Upright, before the first frame. ISSUE 5. ───────────────────────────
  //
  // The manifest's `android:screenOrientation="portrait"` is the half that
  // beats the phone's auto-rotate switch; this is the half that stops the
  // engine asking for a rotation back. See core/platform/orientation.dart for
  // why neither alone is enough.
  await PortraitOnly.apply();

  final sodium = await SodiumSumoInit.init();
  final documents = await getApplicationDocumentsDirectory();
  // App-private storage. Never external, never a shared directory.
  final root = Directory('${documents.path}/lamplight');

  // Read before the vault, because the first screen the user sees may be the
  // lock screen and it has to be painted in the theme they chose — at a moment
  // when there is no key in memory to read a preference with. See the long note
  // at the top of app_settings.dart for where the line is drawn on what may
  // live in that file.
  final settings = await AppSettings.load(File('${root.path}/settings.json'));

  final vault = Vault(
    sodium: sodium,
    root: root,
    // UX-FLOWS.md flow 7: default one minute, configurable 15s to never.
    // "Never" has to be offered — ACCESSIBILITY.md notes a short timeout is a
    // real barrier for someone who types slowly.
    idleTimeout: settings.autoLock,
  );
  await vault.initialise();

  // Wired once, here, so the vault can tell a backgrounding it caused from one
  // the user caused. Every picker and the camera go through SystemExcursion;
  // without this the camera would lock the vault and the photo would come back
  // to a sealed database. See core/platform/system_excursion.dart.
  SystemExcursion.onLeave = vault.expectSystemReturn;
  SystemExcursion.onReturn = vault.endSystemReturn;

  final silentBackup = SilentBackup(vault: vault, settings: settings);

  // ── Every write, not just the ones the day screen makes ─────────────────
  //
  // `SilentBackup` only runs when the vault is known to have changed, and until
  // 3 September that was decided by `markDirty()` calls scattered through
  // `day_screen.dart` -- **the only file in the app that had any**. Importing a
  // journal, restoring from the trash, emptying it, and every folder operation
  // changed the vault and told the backup nothing, so it declined to run and
  // the switch went on saying ON.
  //
  // The repositories are the things that write, so they are the things that
  // say so. Wired once, here, exactly like SystemExcursion above.
  VaultChanged.onWrite = silentBackup.markDirty;

  // ── ISSUE 15, and it no longer blocks the first frame ────────────────────
  //
  // Asked once so that `AppSettings.transcriptionLanguage` can stay a
  // synchronous getter like every other setting in that file — the alternative
  // is one asynchronous one, which spreads through every widget that reads it.
  //
  // **Not awaited.** It used to sit between `vault.initialise` and `runApp`,
  // so every cold start waited on a platform channel round trip before a single
  // pixel was drawn — for a value nothing on the first screen reads. Nothing
  // reads it until somebody opens a voice note's settings, by which time this
  // has long since landed. Until then the getter falls back to `en-US`, which
  // is what it did anyway on the launch before this one.
  Transcription.phoneLanguage
      .then(AppSettings.rememberPhoneLanguage)
      .ignore();

  runApp(LamplightApp(
    vault: vault,
    settings: settings,
    silentBackup: silentBackup,
  ));
}
