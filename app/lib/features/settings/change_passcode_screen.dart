import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

import '../../core/security/passcode_rules.dart';
import '../../core/settings/app_settings.dart';
import '../backup/backup_screen.dart';
import '../../core/vault/vault.dart';
import '../../core/plain_words.dart';
import '../../design/passcode_meter.dart';
import '../../design/components.dart';
import '../../design/tokens.dart';

/// `UX-FLOWS.md` flow 8. Old passcode, new one, confirm.
///
/// It is instant, and that is the whole point of the key hierarchy: only a
/// 32-byte key is rewrapped, not four years of photos re-encrypted.
/// `SECURITY-ARCHITECTURE.md` §1 explains why the obvious design — derive the
/// key straight from the passcode — would make this a twenty-minute operation
/// that can be interrupted halfway and destroy everything.
///
/// THE WARNING AT THE BOTTOM IS NOT DECORATION
///
/// Flow 8 requires it in as many words, and it is the one thing on this screen
/// a user will not work out alone: **backup files already written still open
/// with the old passcode.** They have to, because a backup is sealed under the
/// passcode that was current when it was made and we have no way to reach
/// inside a file we no longer hold. Someone who changes their passcode, loses
/// their phone, and then tries their new passcode against last month's backup
/// concludes the backup is corrupt. It is not. It is waiting for a passcode
/// they have stopped thinking of as theirs.
class ChangePasscodeScreen extends StatefulWidget {
  const ChangePasscodeScreen({
    super.key,
    required this.vault,
    required this.settings,
  });

  final Vault vault;

  /// Needed only for the backup this screen offers afterwards. **ISSUE 20.**
  final AppSettings settings;

  @override
  State<ChangePasscodeScreen> createState() => _ChangePasscodeScreenState();
}

class _ChangePasscodeScreenState extends State<ChangePasscodeScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_current, _next, _confirm]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// The rules are , shared with onboarding, and the two have
  /// to agree — a passcode you could not have set at the start must not become
  /// settable later, or the floor is not a floor.
  ///
  /// It used to be a bare  here and  there, which is two
  /// different rules in two places, both wrong.
  bool get _canSubmit =>
      !_busy &&
      _current.text.isNotEmpty &&
      PasscodeRules.accepts(_next.text) &&
      _confirm.text == _next.text;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.vault.changePasscode(
        currentPasscode: _current.text,
        newPasscode: _next.text,
      );
      if (!mounted) return;
      // ── ISSUE 20 — the two things he asked about, at the moment they
      //    become true ─────────────────────────────────────────────────────
      //
      // > *"If passcode is changed do they need new 12 words phrase or not? If
      // > they need find a way for that, if they don't find a way for that! And
      // > as the passcode is done — do a backup, so whatever the backup file
      // > had old password changes to new one!"*
      //
      // Both answers were already on this screen and both were in the wrong
      // place: two quiet lines at the bottom of a scrolling form, read — if at
      // all — **before** the change, when neither is a fact about anything yet.
      // He read the whole screen and still had to ask, which settles whether
      // that was good enough.
      //
      // So they are said afterwards, when they are true, and the second one is
      // offered rather than recommended. A warning that ends "make a new backup
      // after this" and then returns you to a settings list is asking somebody
      // to remember an errand.
      await _saySo(context);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on WrongSecret catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = plainFailure(e,
          fallback: L.of(context).passcodeChangeFailed,
          andThen: L.of(context).passcodeOldStillWorks,
          words: L.of(context)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// What has and has not changed, said once it has. **ISSUE 20.**
  Future<void> _saySo(BuildContext context) async {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    final backup = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      // Not dismissible by tapping away: this is the one moment the answer to
      // "do I need new words" exists, and it is a moment somebody will not come
      // back to. Everything on it can still be declined, by the button that
      // says so.
      isDismissible: false,
      enableDrag: false,
      builder: (sheet) => PopScope(
        canPop: false,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  Space.x6, Space.x6, Space.x6, Space.x6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L.of(context).passcodeChanged, style: t.titleLarge),
                  const SizedBox(height: Space.x4),
                  // ── His actual question, answered first ─────────────────
                  //
                  // The answer is **no**, and it is a good property rather than
                  // a lucky one: the recovery phrase wraps the vault key
                  // independently of the passcode — `SECURITY-ARCHITECTURE.md`
                  // §2c — so changing the passcode rewraps one envelope and
                  // leaves the other alone. That was invisible until now, and
                  // an invisible good property is worth nothing to the person
                  // who has it.
                  Text(
                    L.of(context).passcodeWordsUnchanged,
                    style: t.bodyMedium
                        ?.copyWith(color: c.inkPrimary, height: 1.5),
                  ),
                  const SizedBox(height: Space.x4),
                  Text(
                    // The trap, stated plainly. A backup is sealed under the
                    // passcode that was current when it was written, and
                    // Lamplight cannot reach inside a file it no longer holds.
                    // Somebody who changes their passcode, loses their phone,
                    // and then tries the new one against last month's backup
                    // concludes the file is broken. It is not — it is waiting
                    // for a passcode they have stopped thinking of as theirs.
                    L.of(context).passcodeOldBackups,
                    style: t.bodyMedium
                        ?.copyWith(color: c.inkSecondary, height: 1.5),
                  ),
                  const SizedBox(height: Space.x6),
                  LampButton(
                    label: L.of(context).passcodeMakeBackup,
                    onPressed: () => Navigator.of(sheet).pop(true),
                  ),
                  const SizedBox(height: Space.x2),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () => Navigator.of(sheet).pop(false),
                      child: Text(L.of(context).actionNotNow,
                          style: TextStyle(color: c.inkSecondary)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;
    // ── Marked stale either way ─────────────────────────────────────────
    //
    // The automatic backup only runs when the *vault* has been written to, and
    // changing a passcode writes nothing anybody would notice — so without this
    // line somebody with automatic backups on would go on holding a file that
    // needs a passcode they have deliberately forgotten, and would never be
    // told. Saying "not now" is declining to do it by hand, not declining ever
    // to have a current backup.
    widget.settings.backupOutOfDate = true;

    if (backup != true) return;
    // `context`, not the captured one: the sheet has closed and this State is
    // still mounted, which the check above has just established.
    if (!mounted) return;
    await Navigator.of(this.context).push(
      MaterialPageRoute<void>(
        builder: (_) => BackupScreen(
          vault: widget.vault,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lamplight;
    final t = Theme.of(context).textTheme;

    return LampPage(
      title: L.of(context).securityChangePasscode,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            Space.x6, 0, Space.x6, Space.x10),
        children: [
          LampPasscodeField(
            controller: _current,
            hint: L.of(context).passcodeCurrent,
            autofocus: true,
            enabled: !_busy,
          ),
          const SizedBox(height: Space.x6),
          LampPasscodeField(
            controller: _next,
            hint: L.of(context).passcodeNew,
            enabled: !_busy,
          ),
          // The same live checklist as onboarding, from the same rules. Two
          // screens that set a passcode must not disagree about what one is.
          PasscodeMeter(passcode: _next.text, confirm: _confirm.text),
          const SizedBox(height: Space.x3),
          LampPasscodeField(
            controller: _confirm,
            hint: L.of(context).passcodeNewAgain,
            enabled: !_busy,
            onSubmitted: (_) => _canSubmit ? _submit() : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: Space.x4),
            LampError(message: _error!),
          ],
          const SizedBox(height: Space.x6),
          LampButton(
            label: _busy ? 'Changing…' : L.of(context).securityChangePasscode,
            busy: _busy,
            onPressed: _canSubmit ? _submit : null,
          ),
          const SizedBox(height: Space.x8),
          Container(
            padding: const EdgeInsets.all(Space.x4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: c.inkSecondary),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: Text(
                    // ISSUE 20. One sentence here, and the whole of it
                    // afterwards, in `_saySo` — where it is a fact rather than
                    // a prediction and where there is a button to act on it.
                    // The same warning twice is noise, and noise is what
                    // stopped this one being read the first time.
                    L.of(context).passcodeOldBackupsNote,
                    style: t.labelMedium
                        ?.copyWith(color: c.inkSecondary, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.x4),
          Text(
            L.of(context).passcodeWordsNote,
            style: t.labelMedium?.copyWith(color: c.inkMuted, height: 1.6),
          ),
        ],
      ),
    );
  }
}
