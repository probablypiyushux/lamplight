import 'package:flutter/material.dart';
import '../../l10n/dates.dart';
import 'package:flutter/services.dart';

import '../../core/app_info.dart';
import '../../core/db/entry_repository.dart';
import '../../core/platform/capture.dart';
import '../../core/reminders/reminders.dart';
import '../../core/security/integrity.dart';
import '../../design/lamp_mark.dart';
import '../../core/settings/app_settings.dart';
import '../../core/vault/vault.dart';
import '../../design/announce.dart';
import '../../design/components.dart';
import '../../l10n/generated/app_localizations.dart';
import 'language_tile.dart';
import '../../design/tokens.dart';
import '../../core/platform/document_store.dart';
import '../../core/plain_words.dart';
import '../backup/backup_screen.dart';
import '../backup/export_screen.dart';
import '../backup/import_screen.dart';
import '../backup/silent_backup.dart';
import '../folders/folders_screen.dart';
import '../trash/trash_screen.dart';
import 'appearance_screen.dart';
import 'media_settings_screen.dart';
import 'licences_screen.dart';
import 'security_screen.dart';

/// Settings.
///
/// ── HOW THIS SCREEN IS ORGANISED, AND WHY IT CHANGED ─────────────────────
///
/// It used to be one long list of every preference in the app. That was fine
/// when there were six and stopped being fine at twenty: a flat list of twenty
/// rows is a list nobody reads, they scan it for the word they came for and
/// miss anything they did not already know existed.
///
/// So the things that go together now live behind one row each — Appearance
/// holds theme, font, accent, page and text size; Security holds the lock, the
/// passcode and the fingerprint. What is left on this screen is short enough
/// to take in at a glance, which is the only length a settings screen is
/// allowed to be.
///
/// There is still no account section, because there is no account.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.vault,
    required this.settings,
    required this.silentBackup,
  });

  final Vault vault;
  final AppSettings settings;
  final SilentBackup silentBackup;

  @override
  Widget build(BuildContext context) {
    // Rebuilt whenever a preference changes, so a theme tap is visible on this
    // screen at the moment it is made rather than after going back.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => LampPage(
        title: L.of(context).settingsTitle,
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.x10),
          children: [
            _NameCard(settings: settings),

            // ══ HOW THIS SCREEN IS DIVIDED ═══════════════════════════════
            //
            // > *"I want you to break down the settings now! to make it more
            // > easier! ... I don't want to cut in so many parts! but make a
            // > logical division between them! ... not everything under one
            // > tab - you notes - setting - be a gentleman!"*
            //
            // The old shape had two groups: three rows at the top, and a
            // "Your notes" group holding **ten** — automatic backup, back up,
            // readable copy, bring in an old journal, language, photo size,
            // video size, ask each time, transcription, trash. That is four
            // unrelated subjects in one list, and the list was taller than the
            // screen.
            //
            // Grouped by the **question being asked**, which is how somebody
            // looks for a setting — not by which part of the code owns it:
            //
            //   1. how the app looks and speaks
            //   2. what happens to what you capture
            //   3. where it is kept, and how it gets in and out
            //   4. who can open it
            //
            // Four groups, three of them labelled, and two new screens rather
            // than ten new ones. "Not so many parts" was the actual
            // instruction and it is the easier half to get wrong.

            LampGroup(
              label: L.of(context).settingsGroupLook,
              children: [
                LampTile(
                  title: L.of(context).settingsAppearance,
                  subtitle: L.of(context).settingsAppearanceNote,
                  icon: Icons.palette_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AppearanceScreen(settings: settings),
                    ),
                  ),
                ),
                // ── The first of the two languages ────────────────────────
                //
                // > *"Two languages are disturbing - voice transcriptions and
                // > another language for localisation!"*
                //
                // He is right and it was a placement problem more than a
                // naming one. Both rows used to sit in the same group, both
                // called some variety of "Language", one deciding what the app
                // says and the other what the recogniser expects.
                //
                // They are now on different screens, in different groups, and
                // named for what they do: this one is the app's own words and
                // sits with the theme and the typeface, because it is the same
                // kind of choice. The other is *Spoken language*, in Photos,
                // video and sound, beside the recordings it applies to.
                LanguageTile(settings: settings),
              ],
            ),

            LampGroup(
              label: L.of(context).settingsGroupWhoCanOpen,
              children: [
                LampTile(
                  title: L.of(context).settingsSecurity,
                  subtitle: _lockSummary(context, settings),
                  icon: Icons.lock_outline,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SecurityScreen(
                        vault: vault,
                        settings: settings,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            LampGroup(
              label: L.of(context).settingsYourNotes,
              children: [
                LampTile(
                  title: L.of(context).settingsFolders,
                  subtitle: L.of(context).settingsFoldersNote,
                  icon: Icons.folder_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FoldersScreen(
                        vault: vault,
                        // Settings is two screens away from the day view, so
                        // travelling to a day means unwinding to it. `popUntil`
                        // rather than a stored callback: fewer moving parts and
                        // it cannot go stale.
                        onOpenDay: (_) => Navigator.of(context)
                            .popUntil((route) => route.isFirst),
                      ),
                    ),
                  ),
                ),
                // Five rows became one. See `media_settings_screen.dart` for
                // what is on it and why transcription is there rather than
                // with the interface language.
                LampTile(
                  title: L.of(context).settingsMedia,
                  subtitle: L.of(context).settingsMediaNote,
                  icon: Icons.perm_media_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MediaSettingsScreen(settings: settings),
                    ),
                  ),
                ),
                LampTile(
                  title: L.of(context).settingsTrash,
                  subtitle: L.of(context).settingsTrashNote,
                  icon: Icons.delete_outline,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TrashScreen(vault: vault),
                    ),
                  ),
                ),
              ],
            ),

            LampGroup(
              label: L.of(context).settingsGroupKeeping,
              footer: L.of(context).settingsKeepingFooter,
              children: [
                // Automatic backup used to be two loose rows on this screen,
                // above the manual one. Both are inside "Back up" now: they
                // are the same subject, and a person deciding about backups
                // should find everything about backups in one place rather
                // than some of it on the way to the rest.
                LampTile(
                  title: L.of(context).settingsBackup,
                  subtitle: _lastBackupLabel(context, settings.lastBackupAt),
                  icon: Icons.archive_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BackupScreen(
                        vault: vault,
                        settings: settings,
                        silentBackup: silentBackup,
                      ),
                    ),
                  ),
                ),
                // The way out. Directly under "Back up" on purpose: the two
                // questions a person has about their own data are "can I get it
                // back" and "can I take it with me", and they should not be on
                // different screens. ETHICAL-DESIGN.md §3 — never obstruct
                // leaving — is not honoured by a feature nobody can find.
                LampTile(
                  title: L.of(context).settingsReadableCopy,
                  subtitle: L.of(context).settingsReadableCopyNote,
                  icon: Icons.description_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ExportScreen(vault: vault),
                    ),
                  ),
                ),
                // The way in, directly under the way out. Somebody arriving
                // from another journal app needs this in the first five
                // minutes, and it is the one feature whose absence quietly
                // stops them adopting Lamplight at all.
                LampTile(
                  title: L.of(context).settingsBringIn,
                  subtitle: L.of(context).settingsBringInNote,
                  icon: Icons.file_download_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ImportScreen(vault: vault),
                    ),
                  ),
                ),
              ],
            ),

            _ReminderGroup(settings: settings),

            _AboutGroup(vault: vault),
          ],
        ),
      ),
    );
  }

  static String _lockSummary(BuildContext context, AppSettings s) {
    // ISSUE 19. One formatter for every duration the app says out loud, so
    // there is nowhere left for "300 seconds" to come back from — and since
    // 29 August that formatter is `lockAfterLabel`, which builds the duration
    // from ARB plurals instead of by hand. `humanDuration` was English by
    // construction: it glued "5" to " minutes", and plural rules are not the
    // same everywhere. Arabic has six forms; Japanese has one and no space.
    final l = L.of(context);
    final auto = s.autoLock == Duration.zero
        ? l.settingsLockNone
        : l.settingsLockAfter(lockAfterLabel(context, s.autoLock));
    return l.settingsSecuritySummary(auto);
  }

  /// How long since the last backup, in the reader's own language.
  ///
  /// Today and yesterday have their own strings rather than falling out of the
  /// plural rule, because most languages say them with a word rather than with
  /// a number — and "backed up 0 days ago" is not a sentence anybody writes.
  /// Everything from two days is `backupDaysAgo`, which is a plural message, so
  /// Arabic gets its own six forms instead of English's two.
  static String _lastBackupLabel(BuildContext context, DateTime? at) {
    final l = L.of(context);
    if (at == null) return l.backupNever;
    final days = DateTime.now().difference(at).inDays;
    if (days == 0) return l.backupToday;
    if (days == 1) return l.backupYesterday;
    return l.backupDaysAgo(days);
  }
}

/// Who this is.
///
/// ── WHY THIS IS AT THE TOP AND WHY IT LOOKS LIKE THIS ────────────────────
///
/// Reported as *"in the settings menu when I said you to give me my name — it
/// is left centered, and it doesn't look so good"*. Both true. The name was
/// buried at the bottom of the screen inside the credit block, set in a small
/// muted label, aligned to nothing in particular.
///
/// A name is not metadata. On a private app it is the one line that says whose
/// this is, and it belongs at the top of Settings where every phone puts the
/// owner — not at the bottom next to the version number.
///
/// So: a proper card, the name at heading size, the initial in a ring beside
/// it, tap anywhere to change it. `UX-FLOWS.md` flow 1 screen 4 specified a
/// skippable local profile and it was never built; this is that, finally, and
/// it is skippable — with no name it says "Add your name" and nothing anywhere
/// in the app is gated on having one.
///
/// **It is not an account.** One string, in a preferences file, on one phone.
/// There is nowhere to send it and nothing that would send it.
class _NameCard extends StatelessWidget {
  const _NameCard({required this.settings});

  final AppSettings settings;

  Future<void> _edit(BuildContext context) async {
    final c = context.lamplight;
    final controller = TextEditingController(text: settings.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(L.of(context).nameCardAsk),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 40,
          // A name is content. The keyboard does not get to learn it, for the
          // same reason it does not get to learn the entries.
          enableIMEPersonalizedLearning: false,
          decoration: InputDecoration(
            hintText: L.of(context).nameCardHint,
            hintStyle: TextStyle(color: c.inkMuted),
            counterText: '',
          ),
          onSubmitted: (v) => Navigator.of(dialog).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: Text(L.of(context).actionCancel, style: TextStyle(color: c.inkSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(controller.text),
            child: Text(L.of(context).actionSave,
                style:
                    TextStyle(color: c.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) settings.displayName = name;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final has = settings.hasName;
    final name = settings.displayName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Space.x6, Space.x2, Space.x6, Space.x2),
      child: Semantics(
        button: true,
        label: has
            ? L.of(context).settingsNameSemantic(name)
            : L.of(context).settingsAddName,
        excludeSemantics: true,
        child: InkWell(
          onTap: () => _edit(context),
          borderRadius: BorderRadius.circular(Radii.md),
          child: Container(
            padding: const EdgeInsets.all(Space.x4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.raised,
                    border: Border.all(color: c.accent.withValues(alpha: 0.5)),
                  ),
                  child: has
                      ? Text(
                          name.characters.first.toUpperCase(),
                          style: t.titleLarge?.copyWith(color: c.accent),
                        )
                      : Icon(Icons.person_outline,
                          size: 22, color: c.inkMuted),
                ),
                const SizedBox(width: Space.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        has ? name : L.of(context).settingsAddName,
                        style: t.titleLarge?.copyWith(
                          color: has ? c.inkPrimary : c.inkSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        has
                            ? L.of(context).settingsNameOnlyHere
                            : L.of(context).settingsNameOptional,
                        style: t.labelMedium?.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: c.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The reminder, and the argument for why it is allowed to exist.
class _ReminderGroup extends StatefulWidget {
  const _ReminderGroup({required this.settings});

  final AppSettings settings;

  @override
  State<_ReminderGroup> createState() => _ReminderGroupState();
}

class _ReminderGroupState extends State<_ReminderGroup> {
  String? _error;

  Future<void> _toggle(bool want) async {
    if (!want) {
      widget.settings.remindersEnabled = false;
      await Reminders.cancel();
      if (mounted) setState(() => _error = null);
      return;
    }
    final granted = await Reminders.requestPermission();
    if (!granted) {
      if (mounted) {
        setState(() => _error = L.of(context).reminderTurnedOffByAndroid);
      }
      return;
    }
    widget.settings.remindersEnabled = true;
    await Reminders.schedule(widget.settings.reminderMinuteOfDay);
    if (mounted) setState(() => _error = null);
  }

  Future<void> _chooseTime() async {
    final current = widget.settings.reminderMinuteOfDay;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    widget.settings.reminderMinuteOfDay = picked.hour * 60 + picked.minute;
    if (widget.settings.remindersEnabled) {
      await Reminders.schedule(widget.settings.reminderMinuteOfDay);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.settings.remindersEnabled;
    final minutes = widget.settings.reminderMinuteOfDay;
    final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

    return LampGroup(
      label: L.of(context).reminderGroup,
      footer: L.of(context).reminderFooter,
      children: [
        LampSwitchTile(
          title: L.of(context).reminderTitle,
          subtitle: _error ?? (on ? L.of(context).reminderOnceADay : null),
          value: on,
          onChanged: _toggle,
        ),
        if (on) ...[
          LampTile(
            title: L.of(context).reminderWhen,
            value: time.format(context),
            icon: Icons.schedule,
            onTap: _chooseTime,
          ),
          // ROUND FIVE, ISSUE 10 — "Send one now" was here and he asked for it
          // gone: *"I want the Test Button removed."*
          //
          // It is worth recording why it existed, because deleting it removes
          // the only proof the feature works. It was added in round four as the
          // answer to "a daily reminder whose first arrival is tomorrow evening
          // is a feature nobody can tell is working". That reasoning was sound
          // and the button did its job — it is how we know the channel, the
          // permission, the icon and the wording are all correct, because he
          // reported *"test button works"* in the same breath as *"notification
          // never comes"*.
          //
          // Which is the whole diagnosis. A working test button and a silent
          // alarm means nothing is wrong with posting; the alarm is not
          // arriving. See `_BatteryRestrictionNotice` below and the long note in
          // `Reminders.kt` — the fix belongs there, not in a button that only
          // ever proved the half that already worked.
          _BatteryRestrictionNotice(settings: widget.settings),
        ],
      ],
    );
  }
}

/// The row that appears only when Android is holding the reminder.
///
/// **ROUND FIVE, ISSUE 10.** *"Even after the time is set, notification from
/// the app never comes."*
///
/// The temptation with a report like that is to keep changing `AlarmManager`
/// flags until something sticks. Round four already did one lap of that —
/// `setInexactRepeating` to `setAndAllowWhileIdle` — and the reminder still did
/// not arrive, because the fault is not in the flag. It is that a Redmi and a
/// Vivo both freeze background alarms for apps the owner has not exempted, and
/// there is no API that overrides a vendor's battery policy from inside the
/// app. See `Reminders.batteryRestricted`.
///
/// So this says so. It is invisible on a phone that is not restricting
/// anything, which is the only reason it is acceptable to have a row in
/// Settings that talks about Android's behaviour rather than Lamplight's — a
/// permanent "this might not work" would be noise, and noise about
/// reliability is worse than silence because it teaches you to ignore it.
///
/// **It never says "allow" and never claims the reminder is broken.** It says
/// what is true and opens the screen where it can be changed. `ETHICAL-DESIGN.md`
/// forbids nagging; a row that appears when a thing is actually wrong, states
/// it once, and disappears when it is fixed, is the opposite of nagging.
class _BatteryRestrictionNotice extends StatefulWidget {
  const _BatteryRestrictionNotice({required this.settings});

  final AppSettings settings;

  @override
  State<_BatteryRestrictionNotice> createState() =>
      _BatteryRestrictionNoticeState();
}

class _BatteryRestrictionNoticeState extends State<_BatteryRestrictionNotice>
    with WidgetsBindingObserver {
  ReminderHealth _health = const ReminderHealth.unknown();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-checked on the way back from a system settings screen, so the row
  /// disappears the moment it stops being true rather than at the next launch.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final health = await Reminders.health();
    if (mounted) setState(() => _health = health);
  }

  /// "yesterday at 21:04", or null.
  String? _when(DateTime? at) {
    if (at == null) return null;
    final local = at.toLocal();
    final time = LampDates.time(context, local);
    final today = DateTime.now();
    final sameDay = local.year == today.year &&
        local.month == today.month &&
        local.day == today.day;
    if (sameDay) return L.of(context).reminderTodayAt(time);
    final yesterday = today.subtract(const Duration(days: 1));
    final wasYesterday = local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day;
    if (wasYesterday) return L.of(context).reminderYesterdayAt(time);
    return L.of(context)
        .reminderOnDateAt('${local.day}/${local.month}', time);
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to say when the switch is off — a diagnosis of a feature nobody
    // has turned on is noise.
    if (!widget.settings.remindersEnabled) return const SizedBox.shrink();

    final c = context.lamplight;
    final problem = _health.firstProblem;

    // ── ISSUE 11 — when it IS working, say so with a fact ─────────────────
    //
    // "Notifications still doesn't work." When the app is in fact fine and
    // Android is not holding anything, the most useful thing it can show is
    // evidence: the last one actually arrived at this time. That is something
    // he can check against his own notification shade, which "everything is
    // configured correctly" is not.
    if (problem == null) {
      final last = _when(_health.lastPostedAt);
      final next = _when(_health.nextDueAt);
      if (last == null && next == null) return const SizedBox.shrink();
      return LampTile(
        title: last == null
            ? L.of(context).reminderNoneYet
            : L.of(context).reminderLastArrived(last),
        subtitle:
            next == null ? null : L.of(context).reminderNextDue(next),
        icon: Icons.check_circle_outline,
        onTap: _check,
      );
    }

    // ── And when something IS in the way, one fault and one button ────────
    //
    // One at a time, in the order they block delivery. A list of four faults
    // is a wall; one fault with the button that fixes it is a task.
    //
    // **It never says "allow" and never claims the reminder is broken.** It
    // says what is true and opens the screen where it can be changed.
    // `ETHICAL-DESIGN.md` forbids nagging; a row that appears when something is
    // actually wrong, states it once, and disappears when it is fixed, is the
    // opposite of nagging.
    return LampTile(
      title: L.of(context).reminderMayNotArrive,
      // The title was translated and this line was not, which is the exact
      // report: *"this never gets localised!"* `ReminderHealth` lives in
      // `core/` and has no context, so it hands over **which** gate is shut and
      // the screen — which does have one — says it. See `ReminderProblem`.
      subtitle: problem.describeIn(L.of(context)),
      icon: Icons.battery_saver_outlined,
      onTap: () async {
        if (!_health.permission) {
          await Reminders.requestPermission();
        } else {
          // Every remaining case — notifications off, this channel silenced,
          // battery restriction — is fixed on a system screen rather than in
          // here, and this is the shortest route to it that needs no reviewed
          // permission.
          await Reminders.openBatterySettings();
        }
        await _check();
      },
      trailing: Icon(Icons.chevron_right, size: 20, color: c.inkMuted),
    );
  }
}

/// Turning automatic backups on, and saying honestly what they are doing.
///
/// Two rows rather than one switch, because there are genuinely two facts here
/// and hiding either would be a small lie: whether it is on, and **where the
/// files are going**. A backup switch with no visible destination is how people
/// end up believing they are protected by a folder that stopped existing in
/// March.
class AutomaticBackupTiles extends StatefulWidget {
  const AutomaticBackupTiles({
    super.key,
    required this.vault,
    required this.settings,
    required this.silentBackup,
  });

  final Vault vault;
  final AppSettings settings;
  final SilentBackup silentBackup;

  @override
  State<AutomaticBackupTiles> createState() => _AutomaticBackupTilesState();
}

class _AutomaticBackupTilesState extends State<AutomaticBackupTiles> {
  String? _error;
  bool _busy = false;

  /// Whether this phone has the no-permission backup location, and what it is
  /// called. Asked once: it is a property of the Android version and cannot
  /// change while the app is running.
  bool _defaultAvailable = false;
  String? _defaultLabel;

  @override
  void initState() {
    super.initState();
    _askThePlatform();
  }

  Future<void> _askThePlatform() async {
    final available = await DocumentStore.defaultFolderAvailable();
    final label = available ? await DocumentStore.defaultFolderLabel() : null;
    if (!mounted) return;
    setState(() {
      _defaultAvailable = available;
      _defaultLabel = label;
    });
  }

  /// Where backups are going, in words somebody can act on.
  String? get _destination {
    if (!widget.settings.useDefaultBackupFolder &&
        widget.settings.backupFolderUri != null) {
      return widget.settings.backupFolderLabel;
    }
    return _defaultLabel;
  }

  /// Puts backups back in `Documents/Lamplight`.
  ///
  /// The grant Android holds is not revoked here — the user can take it back
  /// in their own settings — but the URI is forgotten, because keeping it
  /// would mean a screen saying "the usual folder" with a stale tree behind it
  /// waiting to be picked up again by some later edit.
  void _useDefaultFolder() {
    setState(() {
      _error = null;
      widget.settings.useDefaultBackupFolder = true;
      widget.settings.backupFolderUri = null;
      widget.settings.backupFolderLabel = null;
    });
  }

  Future<void> _chooseFolder() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final chosen = await DocumentStore.pickFolder();
      if (chosen == null) {
        // == "CHOOSE FOLDER DOESN'T WORK MAN! I BEG YOU TO FIX THE FOLDER
        //    ISSUE! CHECK THE PHOTO!" 2 September 2026 ====================
        //
        // The photo showed Android's picker at the root of internal storage,
        // *"Can't use this folder - to protect your privacy, choose another
        // folder"*, the button greyed out - on `versionCode=12`, which had
        // round sixteen's fix in it already.
        //
        // That sentence is **Android's**, shown inside its own picker, and
        // from here a refusal and a change of mind are the same empty result.
        // Round sixteen's answer was `EXTRA_INITIAL_URI`, opening the picker
        // in Documents. The specification calls that a **hint**: a provider
        // may ignore it, and even honoured it only decides where the picker
        // *starts* - one tap on the drawer is back at the root.
        //
        // **A hint cannot fix a restriction**, so the feature stopped needing
        // one. Automatic backup goes to `Documents/Lamplight` now and this
        // path is for people who want somewhere particular - which means a
        // refusal here is no longer a dead end, and nobody is left staring at
        // a switch that will not move.
        if (mounted) {
          setState(() => _error = L.of(context).folderAndroidRestriction);
        }
        return;
      }
      // -- ISSUE 2 - a folder we cannot write to is not a backup folder ----
      //
      // A document provider may legitimately hand back a tree with read
      // access only. Accepting it here would turn the switch on, show a
      // folder name, and then fail at every backup from now until somebody
      // opened this screen again - the exact failure this feature exists to
      // prevent.
      if (!chosen.writable) {
        setState(() => _error = L.of(context).folderNotWritable);
        return;
      }
      widget.settings.backupFolderUri = chosen.uri;
      widget.settings.backupFolderLabel = _readableFolder(chosen.uri);
      // Picking a folder by hand is an explicit statement about where backups
      // belong, and it outranks the default.
      widget.settings.useDefaultBackupFolder = false;
      widget.settings.silentBackupEnabled = true;
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = plainFailure(e,
          fallback: L.of(context).folderRefused,
          andThen: L.of(context).folderTryAnother));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// A tree URI is percent-encoded and unreadable. This pulls the tail off it
  /// so the screen can say `Documents/Lamplight` rather than forty characters
  /// of `content://com.android.externalstorage.documents/tree/primary%3A...`.
  static String _readableFolder(String uri) {
    final decoded = Uri.decodeComponent(uri);
    final colon = decoded.lastIndexOf(':');
    if (colon == -1 || colon == decoded.length - 1) return decoded;
    return decoded.substring(colon + 1);
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.settings.silentBackupEnabled;
    final where = _destination;
    final onDefault = widget.settings.useDefaultBackupFolder ||
        widget.settings.backupFolderUri == null;

    return Column(
      children: [
        LampSwitchTile(
          title: L.of(context).backupAutomatic,
          // -- Where a failure gets to be seen. ISSUE 2 --------------------
          //
          // `_error` used to be shown only by the tile below, which is drawn
          // `if (on)`. So the one moment it could not appear was the first
          // attempt - the switch stayed off and the screen said what it had
          // said before. That is what "CHOOSE FOLDER OPTION IS GIVEN THAT IS
          // BROKEN" looked like from outside: nothing happening, nothing said.
          //
          // Off, it now names the place backups *will* go rather than asking
          // for a folder, because on Android 10+ no folder is needed and
          // asking for one was the whole problem.
          subtitle: _error ??
              (where != null
                  ? L.of(context).backupSavedTo(where)
                  : L.of(context).backupChooseFolder),
          value: on,
          onChanged: (want) async {
            if (!want) {
              widget.settings.silentBackupEnabled = false;
              setState(() {});
              return;
            }
            // -- The repair, in one condition ------------------------------
            //
            // Turning this on used to mean getting through the system folder
            // picker first, and Android is entitled to refuse that. When
            // there is a place we can always write, a switch is just a switch.
            if (_defaultAvailable && widget.settings.useDefaultBackupFolder) {
              widget.settings.silentBackupEnabled = true;
            } else if (widget.settings.backupFolderUri == null) {
              await _chooseFolder();
            } else {
              widget.settings.silentBackupEnabled = true;
            }
            if (mounted) setState(() {});
          },
        ),
        if (on)
          ValueListenableBuilder<SilentBackupStatus>(
            valueListenable: widget.silentBackup.status,
            builder: (context, status, _) => LampTile(
              title: L.of(context).backupChangeFolder,
              // The honest report. A failed automatic backup is told here,
              // calmly, next time someone looks - never as an alert thrown
              // across a journal entry they were in the middle of.
              subtitle: _error ?? status.describeIn(L.of(context)),
              icon: Icons.folder_outlined,
              enabled: !_busy && !status.isRunning,
              onTap: _chooseFolder,
            ),
          ),
        // Only when they have gone somewhere else, because a way back to a
        // place you are already standing in is furniture.
        if (on && _defaultAvailable && !onDefault)
          LampTile(
            title: L.of(context).backupUseDefaultFolder,
            subtitle: _defaultLabel,
            icon: Icons.home_outlined,
            enabled: !_busy,
            onTap: _useDefaultFolder,
          ),
      ],
    );
  }
}

/// About — the promise, the licences, and a way to say thanks.
class _AboutGroup extends StatelessWidget {
  const _AboutGroup({required this.vault});

  final Vault vault;

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LampGroup(
          label: L.of(context).settingsAbout,
          children: [
            LampTile(
              title: L.of(context).aboutHowKept,
              icon: Icons.shield_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HowItIsKeptScreen(),
                ),
              ),
            ),
            LampTile(
              title: L.of(context).aboutFonts,
              icon: Icons.text_fields,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LicencesScreen(),
                ),
              ),
            ),
            LampTile(
              title: L.of(context).aboutVersion,
              value: kAppVersionLabel,
              enabled: true,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Space.x6 + Space.x2, 0, Space.x6 + Space.x2, Space.x6),
          child: Text(
            // ── The four lines, rewritten ────────────────────────────────
            //
            // They used to end "…and so that we could not hand them over if we
            // were asked to." Every word of that is true and it was the wrong
            // sentence, because of what it makes the reader picture: somebody
            // being asked. A person opening a private journal does not need to
            // be told there is a scenario in which the police turn up.
            //
            // Trust and fear are not the same feeling and only one of them
            // makes somebody keep writing. The claim is unchanged — nobody
            // else can read this — it is just said the way you would say it to
            // a person rather than the way you would say it to a court.
            L.of(context).aboutHowKeptBody,
            style: t.labelMedium?.copyWith(color: c.inkMuted, height: 1.6),
          ),
        ),
        const _Byline(),
      ],
    );
  }
}

/// A sheet of mutually exclusive options.
///
/// A sheet rather than a dialog because the choice is not a decision that needs
/// stopping for — `MOTION` in the design system allows motion "to explain a
/// spatial relationship", and a sheet rising from the row you tapped is
/// precisely that. Dialogs are saved for things that can lose data.
Future<void> showLampChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required T current,
  required List<(T, String, String?)> options,
  required ValueChanged<T> onChanged,
}) {
  // The frame is `showLampSheet`'s — see the long note there on what ten
  // hand-rolled sheets had quietly drifted apart on. This one owns its rows and
  // nothing else.
  return showLampSheet<void>(
    context: context,
    title: title,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (value, label, note) in options)
          LampChoiceTile<T>(
            title: label,
            subtitle: note,
            value: value,
            groupValue: current,
            onChanged: (v) {
              onChanged(v);
              // Close on choose. The setting has already taken effect behind
              // the sheet, so asking for a second tap to confirm it would be
              // asking the user to agree with something that already happened.
              Navigator.of(sheet).pop();
            },
          ),
      ],
    ),
  );
}

/// The count line shown on the backup screen and nowhere else.
class VaultSummary extends StatefulWidget {
  const VaultSummary({super.key, required this.vault});

  final Vault vault;

  @override
  State<VaultSummary> createState() => _VaultSummaryState();
}

class _VaultSummaryState extends State<VaultSummary> {
  // A future built inside `build` is a new query on every rebuild, and a
  // `FutureBuilder` handed a new future goes back to having no data — so the
  // count blinked to an em-dash and back every time anything above it changed.
  // Counting every entry in the vault is not free; doing it once is right.
  late final Future<({int days, int entries})> _stats =
      EntryRepository(widget.vault.database).stats();

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    return FutureBuilder<({int days, int entries})>(
      future: _stats,
      builder: (context, snap) {
        final s = snap.data;
        final text = s == null
            ? '—'
            : '${L.of(context).countEntries(s.entries)} · '
                '${L.of(context).countDays(s.days)}';
        return Text(text, style: t.bodyLarge?.copyWith(color: c.inkSecondary));
      },
    );
  }
}

/// Who made it, and the one place the app ever asks for anything.
///
/// WHY THE NAME IS HERE AND NOT ON THE FIRST SCREEN
///
/// The first screen belongs to the promise — "there is no account" — and a name
/// on it would be the author asking for credit before having earned any trust.
/// The bottom of Settings is where people look when they are already wondering
/// who is behind an app that claims nobody else can read their notes, and a
/// name that leads somewhere real is the strongest possible answer.
///
/// **The © is the honest mark, not ™ or ®.** Copyright exists the moment the
/// work does and needs no registration. A trademark symbol claims something
/// not yet done — `STATE.md` records that the trademark search has not been
/// run — and putting ® on an unregistered mark is, in most jurisdictions,
/// actually unlawful.
///
/// ── AND THE COFFEE ───────────────────────────────────────────────────────
///
/// One link, at the very bottom, below the version number, in the quietest
/// style on the screen. It appears **after** somebody has scrolled through
/// everything and is plainly looking at the credits.
///
/// It is not a paywall, a nag, a modal, a badge, a "support us" banner, or a
/// thing that appears after the tenth launch. There is no free tier because
/// there is no paid tier. `ETHICAL-DESIGN.md` bans manufactured guilt and a
/// donation link placed where somebody has to be looking for it does not
/// manufacture anything — it just answers "can I say thanks", which some
/// people want to and currently cannot.
///
/// Both links open through an Intent. **No INTERNET permission is involved**:
/// the app is not opening a socket, it is handing an address to Android.
/// `tool/verify_no_internet.sh` still passes.
class _Byline extends StatelessWidget {
  const _Byline();

  static const _linkedIn = 'https://www.linkedin.com/in/probablypiyushux/';
  /// **ROUND EIGHT, ISSUE 9**, and the answer to ISSUE 19 at last.
  ///
  /// *"Donation method change — from Kofi to Buy Me A Coffee — you have their
  /// logo too! Make it look good!"*
  ///
  /// Round six parked ISSUE 19 because he wrote *"wait 3 to 5 days I will give
  /// you notice on this"*. This is the notice, five days later. The address is
  /// the one that was here before Ko-fi replaced it in round three, recovered
  /// from git rather than guessed — a donation link that goes to the wrong
  /// page is worse than no donation link.
  static const _coffee = 'https://buymeacoffee.com/probablypiyush';

  /// Where a report or a complaint goes.
  ///
  /// ── WHY AN ADDRESS AND NOT A FORM ───────────────────────────────────────
  ///
  /// A form needs a server, and there is not one. An address needs nothing: the
  /// app hands `mailto:` to Android, whichever mail app is installed opens with
  /// it, and Lamplight never sees the message, the recipient or the fact that
  /// one was sent. `tool/verify_no_internet.sh` still passes, because nothing
  /// here opens a socket -- it is the same `ACTION_VIEW` the coffee link uses.
  ///
  /// The subject carries the version, because "it does not work" from an
  /// unknown build is a report nobody can act on. It carries **nothing else**:
  /// no device details, no logs, and above all nothing from the journal. What
  /// goes in the message is the sender's to decide.
  static const _address = 'probablypiyushux@gmail.com';

  /// Opens a mail app with the address and the version already filled in.
  ///
  /// If nothing on the phone handles mail, the address is said out loud rather
  /// than the tap doing nothing -- a control that appears to do nothing is the
  /// same defect as a crash in better clothes, and somebody who has just found
  /// a bug is exactly the person not to strand.
  static Future<void> _write(BuildContext context) async {
    final subject = Uri.encodeComponent('Lamplight $kAppVersion');
    final opened = await Capture.openUrl('mailto:$_address?subject=$subject');
    if (!context.mounted || opened) return;
    announce(context, L.of(context).aboutNoMail(_address),
        duration: const Duration(seconds: 6));
  }

  static Future<void> _open(BuildContext context, String url) async {
    final opened = await Capture.openUrl(url);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(L.of(context).aboutNoBrowser)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    // Asked of the page rather than of `ThemeMode`, because "follow the phone"
    // is a real setting and only the resolved theme knows which way it went.
    final dark = Theme.of(context).brightness == Brightness.dark;

    // ── ISSUE 1's third annotation: "why is this left centered?" ─────────
    //
    // The block was centred inside whatever width it was given, and what it was
    // given was the **whole screen** — while every group above it is capped at
    // `Layout.maxContent` and centred inside that. On his tablet the two
    // centres are the same, but the block's *edges* were far wider than the
    // sheets above it, so it read as floating loose rather than as the end of
    // the same column. `LampColumnWidth` puts it in the column with everything
    // else.
    // ══ ROUND NINE, ISSUE 3 — "WHY IS THIS ON THE LEFTEST SIDE POSSIBLE?" ══
    //
    // A red box round this whole block and: *"Keep it in the middle."*
    //
    // `CrossAxisAlignment.center` is right there below and it was doing exactly
    // what it says — centring the contents inside **the block**, while the
    // block itself sat hard against the left edge at a third of the screen's
    // width.
    //
    // The cause is one level up. `_AboutGroup` is a `Column` with
    // `crossAxisAlignment: start`, and a `Column` gives its children **loose**
    // horizontal constraints — so this took only the width of its widest line
    // and was then aligned to the start, which is the left.
    //
    // Same family as the `Flexible`-beside-a-`Spacer` fault in the entry
    // editor, in the same round, off the same page of his document: *a loose
    // fit takes only what it needs, and then something else decides where that
    // goes.* Worth noticing as a pair — it is the commonest layout mistake in
    // this codebase and it has now caused three separate complaints.
    //
    // `double.infinity` makes the fit tight here, so the centring below has the
    // whole column to centre inside, and so this cannot be placed wrongly by
    // whatever it is dropped into next.
    return SizedBox(
      width: double.infinity,
      child: LampColumnWidth(
      child: Padding(
      padding: const EdgeInsets.fromLTRB(Space.x6, 0, Space.x6, Space.x10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const LampMark(size: 34),
          const SizedBox(height: Space.x4),
          Text(L.of(context).aboutMadeBy, style: t.labelSmall?.copyWith(color: c.inkMuted)),
          const SizedBox(height: Space.x1),
          Semantics(
            button: true,
            link: true,
            label: L.of(context).aboutMadeBySemantic,
            excludeSemantics: true,
            child: InkWell(
              onTap: () => _open(context, _linkedIn),
              borderRadius: BorderRadius.circular(Radii.full),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.x4, vertical: Space.x3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PROBABLYPIYUSH',
                      style: t.labelSmall?.copyWith(
                        color: c.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(width: Space.x2),
                    Icon(Icons.north_east, size: 13, color: c.accent),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.x2),
          Text(
            '© 2026 Piyush Jain · Lamplight $kAppVersion',
            style: t.labelSmall?.copyWith(color: c.inkMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.x5),
          Semantics(
            button: true,
            link: true,
            label: L.of(context).aboutContactSemantic,
            excludeSemantics: true,
            child: TextButton.icon(
              onPressed: () => _write(context),
              icon: Icon(Icons.mail_outline_rounded,
                  size: 18, color: c.accent),
              label: Text(
                L.of(context).aboutContact,
                style: t.labelLarge?.copyWith(color: c.accent),
              ),
            ),
          ),
          const SizedBox(height: Space.x6),
          Semantics(
            button: true,
            link: true,
            label: L.of(context).aboutCoffeeSemantic,
            excludeSemantics: true,
            child: OutlinedButton.icon(
              onPressed: () => _open(context, _coffee),
              // ── Their mark, unmodified, in Lamplight's own pill. ISSUE 9 ──
              //
              // Brand guidance is the same everywhere: use the mark as
              // supplied, do not recolour it, do not redraw it. So this is Buy
              // Me a Coffee's own asset exactly as it came, trimmed to its own
              // edges and nothing else.
              //
              // ══ ROUND NINE, ISSUE 9 — "USE ONE WHICH HAS NO BACKGROUND" ══
              //
              // With, on the screenshot, an arrow to the icon and *"A
              // transparent logo — no Background"*.
              //
              // Round eight chose `bmc-logo-yellow.png` — the cup on their own
              // yellow ground — over the transparent one, and wrote down why:
              // the transparent mark is outlined in their navy, and on this
              // app's warm near-black the navy disappears, leaving "a floating
              // yellow blob".
              //
              // Round nine deleted the yellow tile and kept the transparent
              // mark, having composited both and judged that the navy "reads
              // as a slightly darker silhouette rather than vanishing".
              //
              // ══ ROUND TEN — IT DOES VANISH, AND HE SAID SO ═══════════════
              //
              // > *"Buy me a coffee logo doesn't work in dark background!"*
              //
              // He is right and the judgement was wrong. Counted rather than
              // eyeballed this time: of the mark's opaque pixels, **more than
              // half are the navy** — 1,926 samples against 1,211 of the
              // yellow. That navy is near-black, and it is being drawn on
              // `#0F0F0E`. It is not softened; over half the drawing is simply
              // not there, and what is left is the handle and the rim floating
              // with no cup under them.
              //
              // Both previous rounds were solving the wrong problem, which is
              // why the answer kept oscillating between two bad options. The
              // choice is not *which* of their two files to use. **It is what
              // the mark stands on.** A trademark that contains a dark colour
              // needs a light ground, in the dark theme, exactly as their own
              // guidance and everybody else's assumes — and the answer to
              // "which file" is the transparent one, which he asked for, in
              // both themes.
              //
              // So the mark keeps its own colours and gets a small plate of
              // warm paper under it when the page is dark. It is not their
              // yellow tile: it is this app's own light-mode canvas, which
              // makes it read as a sticker on the page rather than as a
              // rectangle of somebody else's brand. In light mode there is no
              // plate, because there is nothing for it to do.
              //
              // What the yellow-ground version cost, meanwhile, was visible in
              // every mode and on the screen he photographed: a hard-edged
              // square of somebody else's yellow, the only object in the app
              // with its own background, in the quietest corner of the quietest
              // screen. He noticed within a day.
              //
              // A slightly softer icon on one of two palettes is a smaller
              // price than a coloured tile that does not belong to this app in
              // either of them. `bmc-logo-yellow.png` is deleted rather than
              // left in the assets — an unused trademark in the APK is a claim
              // the app is not making, which is the same reason Ko-fi's went.
              //
              // `CLAUDE.md` rule 8 bans hex codes in widgets, and this asset is
              // the one thing on screen carrying colours that are not tokens.
              // That is correct rather than an exception: they are not the
              // app's colours to choose, and a re-tinted trademark would be
              // both worse design and worse manners.
              //
              // The *button* is ours. Their pre-made buttons are a coloured
              // rectangle with their wordmark in their typeface, and dropping
              // one into this screen would be the only object in the whole app
              // belonging to somebody else's design system. His instruction, in
              // round three and again now, is to keep the app's aesthetic: so
              // the pill, the hairline, the ink and the type are Lamplight's,
              // and the cup — the part that actually says *Buy Me a Coffee* —
              // is theirs.
              icon: _CoffeeMark(dark: dark),
              label: Text(L.of(context).aboutCoffee),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.inkSecondary,
                side: BorderSide(color: c.borderStrong),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.full),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.x5, vertical: Space.x3),
              ),
            ),
          ),
          const SizedBox(height: Space.x2),
          Text(
            // The honest framing. Not "support development", not "help us keep
            // the lights on" — Lamplight has no servers and no costs, so
            // neither of those would be true.
            L.of(context).aboutFree,
            textAlign: TextAlign.center,
            style: t.labelSmall?.copyWith(color: c.inkMuted),
          ),
        ],
      ),
      ),
      ),
    );
  }
}

/// The privacy claim, in full, on a page of its own.
///
/// Reachable from Settings rather than shown at people. Somebody who wants to
/// know exactly what is going on can read all of it; somebody who does not is
/// never made to.
class HowItIsKeptScreen extends StatelessWidget {
  const HowItIsKeptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    // Plain sentences, short paragraphs, no jargon in the headings. The
    // technical words appear once each, in the body, where somebody who knows
    // them can check the claim and somebody who does not can skip the line.
    // Localised on 29 August 2026. This was a `const` list of English
    // literals — the app's six central claims about itself, readable only in
    // English, on the one screen somebody opens *because* they want to check
    // what the app does. `l10n/README.md` singles these sentences out: they are
    // factual claims about the software, not marketing, and the tone has to
    // survive translation. It stops being `const` because every line of it now
    // depends on who is reading.
    final l = L.of(context);
    final sections = <(String, String)>[
      (l.keptNoNetworkTitle, l.keptNoNetworkBody),
      (l.keptPasscodeTitle, l.keptPasscodeBody),
      (l.keptForgetTitle, l.keptForgetBody),
      (l.keptNothingReadableTitle, l.keptNothingReadableBody),
      (l.keptLocksItselfTitle, l.keptLocksItselfBody),
      (l.keptBackUpTitle, l.keptBackUpBody),
    ];

    return LampPage(
      title: L.of(context).aboutHowKept,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            Space.x6, 0, Space.x6, Space.x10),
        children: [
          for (final (heading, body) in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.x6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(heading, style: t.titleLarge),
                  const SizedBox(height: Space.x2),
                  Text(body,
                      style: t.bodyLarge?.copyWith(color: c.inkSecondary)),
                ],
              ),
            ),
          const SizedBox(height: Space.x2),
          const _IntegrityLine(),
        ],
      ),
    );
  }
}

/// What the app can tell about the phone it is running on.
///
/// Shown as one calm line, not a warning banner. See `core/security/integrity.dart`
/// for why this is information rather than enforcement.
class _IntegrityLine extends StatefulWidget {
  const _IntegrityLine();

  @override
  State<_IntegrityLine> createState() => _IntegrityLineState();
}

class _IntegrityLineState extends State<_IntegrityLine> {
  IntegrityReport? _report;

  /// The fingerprint is folded away until asked for.
  ///
  /// Ninety-five characters of hexadecimal is not something to put in front of
  /// somebody who opened Settings to change the font. It matters enormously to
  /// the few people who will check it and not at all to everybody else, which
  /// is precisely what a disclosure control is for.
  bool _showingFingerprint = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    Integrity.check().then((r) {
      if (mounted) setState(() => _report = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;
    final report = _report;
    if (report == null) return const SizedBox.shrink();

    final summary = Container(
      padding: const EdgeInsets.all(Space.x4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            report.isClean ? Icons.check_circle_outline : Icons.info_outline,
            size: 18,
            color: report.isClean ? c.good : c.accent,
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Text(
              report.describeIn(L.of(context)),
              style: t.labelMedium?.copyWith(color: c.inkSecondary),
            ),
          ),
          if (!report.isClean)
            IconButton(
              tooltip: L.of(context).aboutCopyDetails,
              icon: const Icon(Icons.copy_all_outlined, size: 18),
              color: c.inkMuted,
              onPressed: () => Clipboard.setData(
                  ClipboardData(text: report.details.join('\n'))),
            ),
        ],
      ),
    );

    if (report.signer.isEmpty) return summary;

    // ── The fingerprint, and what it is actually for ────────────────────────
    //
    // This is the app's half of test 3 in `PLAN.md` §11 — *could a stranger
    // verify the claim themselves in thirty seconds?* `verify_no_internet.sh`
    // answers that for the permissions. This answers a different and equally
    // load-bearing question: **is the app on this phone the app that was built
    // from the published source**, or something rebuilt and resigned by
    // somebody else on the way to the phone.
    //
    // Deliberately **not** compared against a value baked into the app. An app
    // that checks its own signature is checking a number an attacker rebuilds
    // along with everything else — it would prove nothing while looking
    // reassuring, which is worse than not doing it at all. The comparison has
    // to be made by a person, against a number published somewhere this code
    // cannot reach. See `05-shipping/FINGERPRINT.md`.
    //
    // Computed since the integrity work and never shown until 25 August 2026,
    // and that was right: until that day every build carried the debug key
    // that every Flutter developer on earth has a copy of, and displaying it
    // would have been theatre.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        summary,
        TextButton(
          onPressed: () => setState(() {
            _showingFingerprint = !_showingFingerprint;
            _copied = false;
          }),
          style: TextButton.styleFrom(
            foregroundColor: c.inkSecondary,
            alignment: Alignment.centerLeft,
            minimumSize: const Size(0, kMinTouchTarget),
          ),
          child: Text(
            _showingFingerprint
                ? L.of(context).aboutHide
                : L.of(context).aboutCheckReal,
            style: t.labelMedium,
          ),
        ),
        if (_showingFingerprint)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.x2, 0, Space.x2, Space.x3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L.of(context).aboutFingerprintBody,
                  style: t.labelMedium
                      ?.copyWith(color: c.inkSecondary, height: 1.5),
                ),
                const SizedBox(height: Space.x3),
                SelectableText(
                  report.signer,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.5,
                    color: c.inkPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _copied
                      ? null
                      : () async {
                          await Clipboard.setData(
                              ClipboardData(text: report.signer));
                          if (mounted) setState(() => _copied = true);
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: c.accent,
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size(0, kMinTouchTarget),
                  ),
                  child: Text(_copied ? 'Copied' : 'Copy'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Buy Me a Coffee's mark, with something to stand on in the dark theme.
///
/// ══ WHY A PLATE, AND WHY THIS COLOUR ═════════════════════════════════════
///
/// > *"Buy me a coffee logo doesn't work in dark background!"*
///
/// The mark is two colours: their yellow, and a navy so deep it is effectively
/// black. Counted off the asset, **the navy is the majority of it** — 1,926
/// opaque samples against 1,211 of the yellow. Drawn straight onto this app's
/// `#0F0F0E` canvas, over half the drawing is not there, and what survives is a
/// handle and a rim with no cup underneath.
///
/// Two previous rounds argued about *which of their files to use* and swapped
/// between them. That was the wrong question, which is why the answer kept
/// changing. A trademark containing a dark colour needs a light ground in a
/// dark interface — that is what every brand guideline in the world assumes —
/// and the transparent file, which is the one he asked for, is right in both
/// themes once it has one.
///
/// The plate is `LamplightColors.light.canvas`: **this app's own paper**, not
/// their yellow. That distinction is the whole design of it. Their yellow tile
/// was a rectangle of somebody else's brand in the quietest corner of the
/// quietest screen, and he noticed it within a day; a small square of the
/// palette's own light mode reads as a sticker stuck onto the page, which is a
/// thing this app could plausibly own.
///
/// A token rather than a hex, so `CLAUDE.md` rule 8 holds. It is the one colour
/// in the app deliberately used out of its own theme, and that is what it is
/// for: it is the light palette's paper, being used as paper.
///
/// In light mode there is no plate at all, because there is nothing for it to
/// do — the page is already paper and the mark sits on it perfectly.
class _CoffeeMark extends StatelessWidget {
  const _CoffeeMark({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    // ── Their mark, unmodified ──────────────────────────────────────────
    //
    // Brand guidance is the same everywhere: use the mark as supplied, do not
    // recolour it, do not redraw it. Nothing here touches a pixel of it.
    const mark = Image(
      image: AssetImage('assets/brand/bmc_logo.png'),
      height: 20,
      width: 20,
      filterQuality: FilterQuality.medium,
    );
    if (!dark) return mark;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: LamplightColors.light.canvas,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: mark,
    );
  }
}
