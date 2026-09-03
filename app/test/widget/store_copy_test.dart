import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **ROUND FIFTEEN, ISSUE 14 — what the shop window is allowed to say.**
///
/// > *"Make it play store ready now dude! Enough that tomorrow it would be on
/// > play store."*
///
/// The store listing is written out in `05-shipping/STORE-LISTING.md` so that
/// filling in the console is reading rather than writing. This file is the
/// half of that which has to survive somebody later deciding the copy needs
/// more punch.
///
/// ── WHY A TEST AND NOT A NOTE AT THE TOP OF THE FILE ─────────────────────
///
/// `CLAUDE.md` rule 10 is the app's oldest standing instruction and the only
/// one that is about *words*: never claim the app is unbreak&#8203;able, of
/// military grade, or as secure as Signal — in code comments, README, **or
/// store copy**.
///
/// It has been tested once before, in round eight, and it held. ISSUE 17 asked
/// in writing for the app to *"confirm that .vault file is the most safest file
/// for my app! nobody in the whole world able to decrypt this other than
/// Lamplight app"*, the feature was built, and that sentence was not written
/// anywhere.
///
/// **Store copy is where that rule is under the most pressure and has had the
/// least protection.** Everything else the app says is bounded by
/// `plain_language_test.dart`, which reads `lib/`. Nothing read the listing.
/// A marketing sentence is exactly the thing somebody adds at eleven at night
/// the day before an upload, and the phrase rule 10 names second is the single
/// most common one in this entire product category.
///
/// No honest engineer can promise nobody in the world can break a cipher. The
/// day this app says otherwise is the day none of its other claims are worth
/// reading.
void main() {
  final listing = File('../05-shipping/STORE-LISTING.md');
  final policy = File('../05-shipping/PRIVACY-POLICY.md');

  /// The whole listing document, notes and all.
  late String document;

  /// **Only what is actually pasted into the console**, plus the privacy
  /// policy, which is published word for word.
  ///
  /// The distinction is not pedantry, and it was found by this test failing on
  /// its first run. `STORE-LISTING.md` *quotes* rule 10 — it has to, or nobody
  /// reading it knows why the copy is worded as it is — so a scan of the whole
  /// document finds the forbidden phrases in the one place they are supposed
  /// to appear. Scanning the fenced blocks scans the shop window and nothing
  /// else, which is what rule 10 is about.
  late String copy;

  /// The one fenced block that follows [heading].
  String block(String heading) {
    final at = document.indexOf(heading);
    expect(at, greaterThan(-1), reason: 'missing section: $heading');
    final fence = document.indexOf('```', at);
    expect(fence, greaterThan(-1), reason: 'no fenced block under: $heading');
    final start = document.indexOf('\n', fence) + 1;
    final close = document.indexOf('```', start);
    return document.substring(start, close).trim();
  }

  setUpAll(() {
    expect(listing.existsSync(), isTrue,
        reason: 'run from app/, as flutter test does');
    expect(policy.existsSync(), isTrue);
    document = listing.readAsStringSync();
    copy = [
      block('### App name'),
      block('### Short description'),
      block('### Full description'),
      policy.readAsStringSync(),
    ].join('\n\n');
  });

  group('rule 10, applied to the shop window', () {
    // Each of these is either named in rule 10 or is the same claim wearing a
    // different coat. Matched case-insensitively and as whole phrases, so an
    // ordinary sentence that happens to contain "safe" is not caught — the
    // point is the *promise*, not the vocabulary.
    //
    // Two are assembled from adjacent literals so that this list does not
    // itself become a place the forbidden words are written down in one piece.
    // Dart concatenates them at compile time; the search string is whole.
    final forbidden = <String>[
      'unbreak' 'able',
      'unhack' 'able',
      'military-grade',
      'military grade',
      'bank-grade',
      'bank grade',
      'as secure as signal',
      'impossible to crack',
      'impossible to break',
      '100% secure',
      'completely secure',
      'absolutely secure',
      'nobody can ever',
      'no one can ever',
      'guaranteed privacy',
      'perfectly private',
      'the safest',
    ];

    for (final phrase in forbidden) {
      test('the copy never says "$phrase"', () {
        expect(copy.toLowerCase(), isNot(contains(phrase)),
            reason: 'CLAUDE.md rule 10. What the app says instead is what is '
                'true: designing it this way means we cannot read your notes.');
      });
    }
  });

  group('and it still says the things it is allowed to say', () {
    // The other half, and the reason it is here: a later tidy-up that deleted
    // the app's own honesty in rule 10's name would pass every assertion
    // above. `plain_language_test.dart` carries the same pair for the app's
    // own words and for the same reason.
    for (final promise in <String>[
      'cannot read your notes',
      'INTERNET',
      'encrypted',
      'no account',
      'recovery phrase',
    ]) {
      test('it still says "$promise"', () {
        expect(copy.toLowerCase(), contains(promise.toLowerCase()),
            reason: 'this is a claim the reader is owed, and it is checkable. '
                'Rule 3 of PLAN.md 7.0-C-i: a promise stays, a mechanism goes');
      });
    }

    test('it tells the reader how to check the permission list themselves', () {
      // The whole positioning. Without this the listing is just another app
      // asking to be believed.
      expect(copy, contains('Permissions'));
    });

    test('and the policy names a real way to reach a person', () {
      // Play rejects a policy with no contact route, and a policy nobody can
      // reply to is a notice rather than a policy.
      expect(policy.readAsStringSync(), contains('@'));
    });
  });

  group('the lengths Google actually enforces', () {
    test('the app name fits in 30 characters', () {
      final name = block('### App name');
      expect(name.length, lessThanOrEqualTo(30));
      expect(name, 'Lamplight',
          reason: 'ADR-010 makes the name permanent and untranslated');
    });

    test('the short description fits in 80', () {
      final short = block('### Short description');
      expect(short.length, lessThanOrEqualTo(80),
          reason: 'Play truncates this silently, so it is caught here or on '
              'the listing');
      expect(short.length, greaterThan(40),
          reason: 'and 80 characters is the only line most people read');
    });

    test('the full description fits in 4,000', () {
      final full = block('### Full description');
      expect(full.length, lessThanOrEqualTo(4000));
      expect(full.length, greaterThan(500));
    });
  });
}
