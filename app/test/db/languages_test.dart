import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamplight/core/crypto/vault_crypto.dart';
import 'package:lamplight/core/db/database.dart';
import 'package:lamplight/core/db/entry_repository.dart';
import 'package:lamplight/core/db/search.dart';
import 'package:sodium/sodium_sumo.dart';

/// **ISSUE 11 — "all languages support in writing".**
///
/// `PLAN.md` §7.0-D-i guessed this was *"almost certainly already true and
/// worth verifying rather than building"*, and named rendering as the likely
/// gap. Half right. Writing, storing and reading back were fine. **Searching
/// was not, and the failure was total rather than partial**: a search for a
/// Hindi word returned nothing at all, which does not look like a bad search,
/// it looks like the app having nothing written in Hindi.
///
/// The cause was one character. `RegExp(r'[^\w]+')` split the query into words,
/// and `\w` in Dart means `[A-Za-z0-9_]` — even with the unicode flag — so
/// every character of every non-Latin script counted as a separator and the
/// words were split away into nothing. The index had been right since schema
/// version 1; only the question was being asked in English.
///
/// So this file exists to keep the answer honest, and it is deliberately
/// written as a matrix rather than as one test, because "does it work in every
/// language" is a claim about a set and a claim about a set needs the set.
void main() {
  late SodiumSumo sodium;
  late VaultCrypto crypto;
  late Directory tmp;
  late VaultDatabase db;
  late EntryRepository repo;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    crypto = VaultCrypto(sodium);
  });

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('lamplight_lang');
    final dek = crypto.generateDek();
    final sub = crypto.deriveSubkey(dek, KeyPurpose.database);
    final key = Uint8List.fromList(sub.extractBytes());
    dek.dispose();
    sub.dispose();
    db = await openVaultDatabase(path: '${tmp.path}/vault.db', key: key);
    repo = EntryRepository(db);
  });

  tearDown(() async {
    await db.close();
    try {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  var n = 0;

  Future<void> write(String body) async {
    await repo.createText(
      id: 'lang-${n++}',
      dayKey: '2026-08-27',
      body: body,
    );
  }

  /// Every script somebody using this app is plausibly going to write in, plus
  /// the two that break things: a right-to-left one, and one with combining
  /// marks in the middle of its words.
  const written = <String, (String sentence, String word)>{
    'Hindi': ('कल मैं office नहीं गया, I was completely wiped out', 'नहीं'),
    'Tamil': ('இன்று மிகவும் நன்றாக இருந்தது', 'நன்றாக'),
    'Bengali': ('আজকের দিনটা ভালো ছিল', 'ভালো'),
    'Gujarati': ('આજનો દિવસ સરસ હતો', 'દિવસ'),
    'Arabic': ('اليوم كان جيدا جدا', 'جيدا'),
    'Russian': ('сегодня был хороший день', 'хороший'),
    'Greek': ('σήμερα ήταν μια καλή μέρα', 'καλή'),
    'Hebrew': ('היום היה יום טוב', 'טוב'),
    'French': ('aujourd\'hui était une très bonne journée', 'journée'),
    'Korean': ('오늘 하루 정말 좋았다', '좋았다'),
  };

  group('what is written comes back exactly', () {
    for (final entry in written.entries) {
      test('${entry.key} survives being stored and read', () async {
        final (sentence, _) = entry.value;
        await write(sentence);
        final rows = await repo.watchDay('2026-08-27').first;
        expect(rows.single.body, sentence,
            reason: 'the database is UTF-8 and the vault does not care what '
                'is in it — if this ever fails, something is transcoding');
      });
    }

    test('so do emoji, which are not letters at all', () async {
      const body = 'a good day 🌙✨ and a long walk 🚶🏽‍♀️';
      await write(body);
      final rows = await repo.watchDay('2026-08-27').first;
      // Surrogate pairs, a skin-tone modifier and a zero-width joiner. If any
      // layer in here counted characters rather than code units, this is where
      // it would show.
      expect(rows.single.body, body);
    });
  });

  group('and can be searched for', () {
    for (final entry in written.entries) {
      test('${entry.key}: a word out of the middle of the sentence', () async {
        final (sentence, word) = entry.value;
        await write(sentence);
        final hits = await repo.searchEverything(word);
        expect(hits.entries, isNotEmpty,
            reason: 'searching "$word" found nothing in "$sentence" — which '
                'is exactly the failure ISSUE 11 reported, and it is the '
                'query splitter, not the index');
      });
    }

    test('a Latin word inside a Hindi sentence still works', () async {
      // The case he actually described: *"people 99% of the time will speak
      // multilingually"*. One sentence, two scripts, and both halves findable.
      await write('कल मैं office नहीं गया');
      expect((await repo.searchEverything('office')).entries, isNotEmpty);
      expect((await repo.searchEverything('कल')).entries, isNotEmpty);
    });

    test('a word that is nowhere is still nowhere', () async {
      // The fix widens what counts as a word. It must not widen what counts as
      // a match — a splitter that produced one enormous term, or none, would
      // pass every test above by matching everything.
      await write('कल मैं office नहीं गया');
      expect((await repo.searchEverything('विद्यालय')).entries, isEmpty);
      expect((await repo.searchEverything('holiday')).entries, isEmpty);
    });

    test('punctuation is still a separator', () async {
      await write('मैं ठीक हूँ, सब अच्छा है।');
      // The danda and the comma are punctuation in Devanagari as a full stop
      // and a comma are in English. If they were being treated as letters, the
      // last word of a sentence would only match with its punctuation attached.
      expect((await repo.searchEverything('अच्छा')).entries, isNotEmpty);
    });
  });

  group('the one limit, measured rather than assumed', () {
    test('Japanese matches from the start of a run, not from the middle',
        () async {
      // Japanese and Chinese are written without spaces, so a whole sentence
      // is one term here and one token in the index.
      //
      // **This came out better than expected and the reason is worth writing
      // down.** The search already makes the last term a prefix — `"x"*` — so
      // that results narrow while you are still typing rather than only when
      // you stop. On a script with no spaces that turns out to be most of a
      // word search for free: 今日 is the start of 今日はいい日でした, so it
      // matches.
      //
      // What it cannot do is find a word in the *middle* of a run, because
      // FTS5 has no suffix index and building one costs the whole index again.
      // That needs a dictionary tokenizer, which is a dependency —
      // `CLAUDE.md` rule 4 — and a different job from this one.
      await write('今日はいい日でした');
      expect((await repo.searchEverything('今日はいい日でした')).entries, isNotEmpty,
          reason: 'the whole run is findable');
      expect((await repo.searchEverything('今日')).entries, isNotEmpty,
          reason: 'and so is the start of it, because the last term is a '
              'prefix');
      expect((await repo.searchEverything('いい日')).entries, isEmpty,
          reason: 'a word in the middle of a run is not, and the app should '
              'not pretend otherwise');
    });
  });
}
