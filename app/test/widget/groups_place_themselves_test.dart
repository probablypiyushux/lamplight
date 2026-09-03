import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **"UI ISSUE FOR BACK UP TAB UNDER SECURITY IS ALSO NOT FIXED."**
/// 31 August 2026.
///
/// ── THREE LEFT EDGES IN ONE COLUMN ──────────────────────────────────────────
///
/// `LampGroup` carries its **own** horizontal margins — `Layout.gutter` for the
/// sheet, `Layout.contentGutter` for the label and the footer — because it is
/// the one place in the app that decides where content starts. Its own long
/// note says so, and says it was written to end an issue about exactly this.
///
/// A screen that also pads its `ListView` horizontally does not move the group.
/// It **doubles** it. On the backup screen, which padded by `Space.x6`:
///
///     the summary, the button, every paragraph      24
///     the group's sheet            24 + gutter    = 48
///     "ON ITS OWN" and its footer  24 + content   = 64
///
/// Three edges, stacked down one column, which is precisely the complaint the
/// component was built to prevent. Settings, security, media settings and trash
/// all pad `bottom` only and looked right. **Backup was the only one that did
/// not, and it is the only one that was reported.**
///
/// ── WHY A TEST AND NOT A FIXED SCREEN ───────────────────────────────────────
///
/// Nothing about the broken version was detectable from the code: it analysed
/// clean, it laid out without a warning, and every widget in it was correct on
/// its own. It was wrong only in relation to a rule living in another file. That
/// is the shape of defect that comes back — the next screen to stack groups will
/// reach for `fromLTRB` because most `ListView`s in this app want it.
///
/// So this reads the source and pins the rule: **a list that holds a `LampGroup`
/// lets the group place itself.** It scopes to the individual `ListView` rather
/// than to the file, because `settings_screen.dart` legitimately has other
/// horizontally-padded lists that hold no groups at all.
void main() {
  final lib = Directory('lib');

  /// The body of every `ListView(` in [source], found by matching parentheses
  /// from the opening one.
  ///
  /// Crude on purpose. A real parse would need the analyzer package as a
  /// dependency, and rule 4 says every package can read all of the user's
  /// notes — a layout ratchet is not worth one. Brackets inside string literals
  /// would fool this; there are none in these files, and a miscount fails
  /// loudly here rather than quietly on a screen.
  List<String> listViewBodies(String source) {
    final bodies = <String>[];
    for (final match in RegExp(r'ListView\(').allMatches(source)) {
      var depth = 0;
      final start = match.end - 1;
      for (var i = start; i < source.length; i++) {
        final ch = source[i];
        if (ch == '(') depth++;
        if (ch == ')') {
          depth--;
          if (depth == 0) {
            bodies.add(source.substring(start, i + 1));
            break;
          }
        }
      }
    }
    return bodies;
  }

  /// The `padding:` argument of a `ListView`, as written.
  ///
  /// Only the list's own — anything nested inside a child is somebody else's
  /// business and is skipped by taking the first one at depth 1.
  String? paddingOf(String body) {
    final at = body.indexOf('padding:');
    if (at < 0) return null;
    var depth = 0;
    for (var i = 0; i < at; i++) {
      if (body[i] == '(') depth++;
      if (body[i] == ')') depth--;
    }
    if (depth != 1) return null;
    final end = body.indexOf('\n', at);
    return body.substring(at, end < 0 ? body.length : end);
  }

  test('a list that holds a group does not pad it a second time', () {
    final offenders = <String>[];

    for (final file in lib.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      if (!source.contains('LampGroup(')) continue;

      for (final body in listViewBodies(source)) {
        if (!body.contains('LampGroup(')) continue;
        final padding = paddingOf(body);
        if (padding == null) continue;

        // Every way of writing a horizontal inset. `EdgeInsets.only(bottom:)`
        // and `EdgeInsets.zero` are the two that are allowed.
        final horizontal = padding.contains('fromLTRB') ||
            padding.contains('symmetric(horizontal') ||
            padding.contains('EdgeInsets.all') ||
            padding.contains('only(left') ||
            padding.contains('only(right') ||
            padding.contains('only(start') ||
            padding.contains('only(end');

        if (horizontal) {
          offenders.add('${file.path}: $padding');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These lists hold a LampGroup and also pad it horizontally, so '
          'the group is inset twice and the screen has two or three different '
          'left edges. LampGroup already applies Layout.gutter to its sheet and '
          'Layout.contentGutter to its label and footer. Pad bottom only, and '
          'wrap the children that need a gutter in one themselves — '
          'backup_screen.dart is the worked example.\n\n'
          '${offenders.join('\n')}',
    );
  });

  test('the scan actually reaches the screens it is meant to', () {
    // A ratchet that silently matches nothing passes for ever. Round fifteen's
    // honesty test was looking where the words used to be and went green for a
    // week, so this counts the population first.
    final withGroups = lib
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('LampGroup('))
        .toList();

    expect(withGroups.length, greaterThanOrEqualTo(5),
        reason: 'settings, security, media settings, trash and backup all '
            'stack groups. If this drops, the rule above is checking less than '
            'it looks like it is.');
  });

  test('the paren matcher finds a list and its padding', () {
    // The scanner is the part that can be wrong in a way that makes everything
    // above vacuously true, so it is exercised on a known string.
    const sample = '''
      ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [LampGroup(label: 'x')],
      )''';
    final bodies = listViewBodies(sample);
    expect(bodies, hasLength(1));
    expect(bodies.single, contains('LampGroup('));
    expect(paddingOf(bodies.single), contains('fromLTRB'));
  });
}
