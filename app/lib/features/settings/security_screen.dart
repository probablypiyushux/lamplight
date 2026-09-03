import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../core/platform/biometrics.dart';
import '../../core/settings/app_settings.dart';
import '../../core/plain_words.dart';
import '../../core/vault/vault.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';
import 'change_passcode_screen.dart';
import 'settings_screen.dart' show showLampChoiceSheet;

/// Everything about getting in, and staying out.
///
/// ── THE ONE THING THIS SCREEN CANNOT CHANGE ──────────────────────────────
///
/// **Lamplight locks the instant it goes into the background, and the keys are
/// destroyed.** That is not on this screen because it is not a setting and
/// never will be — `UX-FLOWS.md` flow 7 calls it non-negotiable, and
/// `THREAT-MODEL.md` ranks "somebody picks up the unlocked phone" as by far
/// the most likely adversary. It is stated in the footer so that nobody has to
/// wonder where the switch is.
///
/// Everything here is about the *friction*, which is a separate thing from the
/// security and was being confused with it: the app's only protection was also
/// its only annoyance, so every attempt to make it less annoying looked like
/// making it less safe. It is not. Nothing on this screen weakens anything.
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({
    super.key,
    required this.vault,
    required this.settings,
  });

  final Vault vault;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => LampPage(
        title: L.of(context).settingsSecurity,
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.x10),
          children: [
            LampGroup(
              label: L.of(context).securityWhileOpen,
              // ISSUE 21. The last sentence is new, and it is the answer to
              // "the app auto closes while I am watching at it": it says the
              // warning exists, so somebody who has seen it once knows it was
              // the app being deliberate rather than the app falling over.
              footer: L.of(context).securityLockFooter,
              children: [
                LampTile(
                  title: L.of(context).securityLockAfter,
                  // ISSUE 19. `humanDuration`, not `inSeconds` — a tile that
                  // answers "5 minutes" with "300 seconds" reads as the app
                  // correcting you.
                  value: lockAfterLabel(context, settings.autoLock),
                  icon: Icons.lock_clock,
                  onTap: () => showLampChoiceSheet<Duration>(
                    context: context,
                    title: L.of(context).securityLockAfter,
                    current: settings.autoLock,
                    // ── ISSUE 21 — the two long ones are new ─────────────
                    //
                    // *"A good feature but say me how to tame it!"* Fifteen
                    // minutes was the longest thing on this list that was not
                    // "never", and reading back a year of entries on a Sunday
                    // afternoon is longer than fifteen minutes. The gap between
                    // the longest real setting and giving up on the feature
                    // entirely was where he was stuck.
                    // No longer `const`: the labels are the reader's now, and
                    // a const list cannot hold them. `lockAfterOptions` is
                    // beside `lockAfterLabel` so the sheet and the row that
                    // opens it can never disagree about what a duration is
                    // called.
                    options: lockAfterOptions(context),
                    onChanged: (v) => settings.autoLock = v,
                  ),
                ),
              ],
            ),

            LampGroup(
              label: L.of(context).securityYourPasscode,
              footer: L.of(context).securityPasscodeFooter,
              children: [
                LampTile(
                  title: L.of(context).securityChangePasscode,
                  icon: Icons.password_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChangePasscodeScreen(
                        vault: vault,
                        settings: settings,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            _BiometricGroup(vault: vault, settings: settings),

            LampGroup(
              label: L.of(context).securityScreenshots,
              footer: L.of(context).securityScreenshotsFooter,
              children: [
                LampSwitchTile(
                  title: L.of(context).securityAllowScreenshots,
                  subtitle: settings.allowScreenshots
                      ? L.of(context).securityScreenshotsOn
                      : L.of(context).securityScreenshotsOff,
                  value: settings.allowScreenshots,
                  onChanged: (v) => settings.allowScreenshots = v,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

/// The fingerprint, offered honestly.
///
/// The temptation with biometrics is to present them as *the* lock, because
/// that is what everyone else does and it is what people expect. It would be a
/// lie here: the fingerprint opens one envelope on one phone, it is destroyed
/// the moment the phone's biometrics change, and it is not in any backup. The
/// passcode is the key. So the footer says exactly that, before the switch
/// rather than after.
class _BiometricGroup extends StatefulWidget {
  const _BiometricGroup({required this.vault, required this.settings});

  final Vault vault;
  final AppSettings settings;

  @override
  State<_BiometricGroup> createState() => _BiometricGroupState();
}

class _BiometricGroupState extends State<_BiometricGroup> {
  BiometricStatus _status = BiometricStatus.unavailable;
  bool _enabled = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final status = await Biometrics.status();
    final enabled = await widget.vault.hasBiometricWrapper;
    if (!mounted) return;
    setState(() {
      _status = status;
      _enabled = enabled;
    });
  }

  Future<void> _toggle(bool want) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (want) {
        await widget.vault.enableBiometricUnlock();
      } else {
        await widget.vault.disableBiometricUnlock();
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        setState(() => _error = plainFailure(e,
            fallback: L.of(context).securityCouldNotChange,
            andThen: L.of(context).securityNothingChanged,
          words: L.of(context)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hidden entirely on a phone that cannot do it. A switch that is
    // permanently greyed out with "not supported" underneath is a small daily
    // reminder of something the user cannot fix.
    if (_status == BiometricStatus.noHardware ||
        _status == BiometricStatus.unavailable) {
      return const SizedBox.shrink();
    }

    final ready = _status.usable;
    return LampGroup(
      label: L.of(context).securityFingerprint,
      footer: L.of(context).securityFingerprintFooter,
      children: [
        LampSwitchTile(
          title: L.of(context).securityUnlockWithFingerprint,
          subtitle: _error ?? (ready ? null : _status.describe),
          value: _enabled,
          onChanged: _busy || !ready ? (_) {} : _toggle,
        ),

        // ── ISSUE 19 — "coming straight back doesn't work" ─────────────────
        //
        // He was right twice, and the second one is the interesting one.
        //
        // **It did nothing he could see.** It lived in "While the app is open",
        // above the fingerprint switch, and every single thing it controlled
        // was about the fingerprint prompt — so on a vault with no fingerprint
        // set up it was a setting with no effect at all, sitting in a group it
        // had nothing to do with. It is here now, under the switch it depends
        // on, and it does not exist when that switch is off.
        //
        // **And it was inverted.** "Coming straight back — skip for 5 minutes"
        // reads as *get me back in faster*. What it actually did was suppress
        // the automatic fingerprint prompt when you came back quickly, so
        // coming straight back gave you **more** work, not less. The reasoning
        // written at the time was real — a system dialog in your face because
        // you glanced at a notification is the app being needy — but it is an
        // argument for a different label, not for that one.
        //
        // So it is a switch, and the switch says what happens. There is no
        // duration left to misread as "300 seconds", and no way for it to be
        // set and do nothing.
        if (_enabled)
          LampSwitchTile(
            title: L.of(context).securityAskOnOpen,
            subtitle: widget.settings.promptForFingerprint
                ? L.of(context).securityPromptAutomatic
                : L.of(context).securityPromptOnTap,
            value: widget.settings.promptForFingerprint,
            onChanged: (v) => widget.settings.promptForFingerprint = v,
          ),
      ],
    );
  }
}

/// How long the app waits before locking itself, in the reader's language.
///
/// ══ WHY THIS IS NOT `humanDuration` ═════════════════════════════════════════
///
/// `plain_words.dart`'s `humanDuration` builds *"5 minutes"* by hand and is
/// English by construction — and worse, unfixable by translation alone, because
/// plural rules are not the same everywhere. Arabic has six forms; Japanese and
/// Chinese have one and no space before the unit.
///
/// So the durations are ARB plural messages, and this is the one place that
/// turns a `Duration` into one of them. Both the row and the sheet it opens use
/// it, which is the point: they used to hold two separate lists of the same
/// seven strings.
String lockAfterLabel(BuildContext context, Duration d) {
  final l = L.of(context);
  if (d == Duration.zero) return l.durationNever;
  if (d.inSeconds < 60 || d.inSeconds % 60 != 0) {
    // A remainder means somebody added an option without thinking about how it
    // reads. Seconds is the honest fallback rather than a rounded lie.
    return l.durationSeconds(d.inSeconds);
  }
  if (d.inMinutes % 60 == 0) return l.durationHours(d.inMinutes ~/ 60);
  return l.durationMinutes(d.inMinutes);
}

/// The seven choices, with the two that carry a note.
///
/// **ISSUE 21 — the two long ones.** *"A good feature but say me how to tame
/// it!"* Fifteen minutes was the longest thing here that was not "never", and
/// reading back a year of entries on a Sunday afternoon is longer than that.
/// The gap between the longest real setting and giving up on the feature was
/// where he was stuck.
List<(Duration, String, String?)> lockAfterOptions(BuildContext context) {
  final l = L.of(context);
  return [
    for (final d in const [
      Duration(seconds: 15),
      Duration(minutes: 1),
      Duration(minutes: 5),
      Duration(minutes: 15),
      Duration(minutes: 30),
      Duration(hours: 1),
      Duration.zero,
    ])
      (
        d,
        lockAfterLabel(context, d),
        switch (d) {
          const Duration(minutes: 5) => l.securityDefaultNote,
          const Duration(hours: 1) => l.securityHourNote,
          Duration.zero => l.securityNeverNote,
          _ => null,
        },
      ),
  ];
}
