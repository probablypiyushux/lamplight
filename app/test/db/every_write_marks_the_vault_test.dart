import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/db/vault_changed.dart';

/// **"automatic backup is flawed at code level"** — and it was.
///
/// He reported automatic backup as broken three times. Twice he was answered
/// with evidence that it had *run*: a date on the backup screen, a
/// sixty-megabyte file on the disk. Both were true, and neither was an answer,
/// because the question was never "did it ever run" — it was **"does it run
/// when my journal changes"**.
///
/// It did not. `SilentBackup.maybeRun` declines unless
/// `AppSettings.vaultChangedSinceBackup` is set, and that flag was set by
/// `markDirty()` — called from **one file in the whole app**, `day_screen.dart`.
/// Counted on 3 September 2026: eight call sites, all in that file, none
/// anywhere else. So all of this changed the vault and told the backup nothing:
///
///   * the journal importer, bringing in a whole diary
///   * restoring an entry from the trash, and emptying the trash for good
///   * creating, renaming and deleting a folder
///   * filing an entry into a folder from the picker
///
/// Somebody could import years of writing, watch it appear, lock the app, and
/// have the backup decide there was nothing new to save — with the switch
/// reading ON throughout. **A backup that silently declines is worse than one
/// that fails loudly**, because only the second one gets reported.
///
/// ── Why the existing test did not catch it ───────────────────────────────
///
/// `test/backup/automatic_backup_test.dart` is a good test and it passed
/// throughout. It calls `markDirty()` **itself** and then checks the flag is
/// set, persists across sessions, and clears after a backup. Every one of those
/// is true. It proves the mechanism works when it is told; it never asked
/// whether anything tells it.
///
/// That is the same shape as the two accessibility defects found the same day:
/// the thing being checked was not the thing being shipped. So this test checks
/// the wiring rather than the mechanism, and it does it by reading the source,
/// because the wiring is a fact about the code rather than about a run.
void main() {
  /// Methods that change the vault. Named rather than inferred — "does this
  /// method write" is not something a regex can decide — but each name is
  /// looked up in the file below, so the list cannot quietly fall out of date.
  const mutators = <String, List<String>>{
    'entry_repository.dart': [
      'createText',
      'createTextOn',
      'updateBody',
      'setMarker',
      'softDelete',
      'restore',
      'purge',
      'purgeExpired',
      'discardDraft',
    ],
    'folder_repository.dart': [
      'create',
      'rename',
      'delete',
      'add',
      'remove',
      'setMembership',
    ],
    'day_note_repository.dart': ['setBody'],
  };

  /// The body of `name` in [src], from its signature to the brace that closes
  /// it.
  String? methodBody(String src, String name) {
    final sig = RegExp(
      r'^  (?:Future|Stream)<[^>]*>\s+' + name + r'\(',
      multiLine: true,
    );
    final m = sig.firstMatch(src);
    if (m == null) return null;

    // Step over the parameter list before counting braces. Named parameters
    // are written `({ ... })`, so counting from the signature would balance on
    // the parameter brace and return the signature as the whole body -- which
    // reported four correctly-marked methods as unmarked the first time this
    // test was run. The failure was in the test, not the code it was judging.
    var parens = 0;
    var i = src.indexOf('(', m.start);
    for (; i < src.length; i++) {
      if (src[i] == '(') parens++;
      if (src[i] == ')') {
        parens--;
        if (parens == 0) break;
      }
    }
    final open = src.indexOf('{', i);
    if (open == -1) return null;

    var depth = 0;
    for (var j = open; j < src.length; j++) {
      if (src[j] == '{') depth++;
      if (src[j] == '}') {
        depth--;
        if (depth == 0) return src.substring(m.start, j + 1);
      }
    }
    return null;
  }

  group('every repository write tells the backup', () {
    for (final entry in mutators.entries) {
      final file = entry.key;
      final src = File('lib/core/db/$file').readAsStringSync();

      for (final name in entry.value) {
        test('$file · $name', () {
          final body = methodBody(src, name);
          expect(
            body,
            isNotNull,
            reason: '`$name` was not found in $file. If it was renamed, update '
                'the list at the top of this test — do not delete the entry, '
                'or whatever it became goes unchecked.',
          );
          expect(
            body,
            contains('VaultChanged.mark()'),
            reason: 'A method that changes the vault must call '
                '`VaultChanged.mark()`, or automatic backup declines to run '
                'and the switch goes on saying ON. See '
                'lib/core/db/vault_changed.dart.',
          );
        });
      }
    }

    test('the hook is wired where the app starts, not in a screen', () {
      final main = File('lib/main.dart').readAsStringSync();
      expect(
        main,
        contains('VaultChanged.onWrite'),
        reason: 'Nothing sets VaultChanged.onWrite, so every mark goes nowhere '
            'and automatic backup is back where it started: silently '
            'declining, with the switch on.',
      );
    });
  });

  group('the sink itself', () {
    tearDown(VaultChanged.forget);

    test('does nothing when unwired, rather than throwing', () {
      VaultChanged.forget();
      expect(VaultChanged.mark, returnsNormally);
    });

    test('calls the hook once per write', () {
      var n = 0;
      VaultChanged.onWrite = () => n++;
      VaultChanged.mark();
      VaultChanged.mark();
      expect(n, 2);
    });
  });
}
