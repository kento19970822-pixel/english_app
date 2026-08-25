import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:english_app/db/app_database.dart';

void main() {
  group('Step 3 Words Features Tests (Items 12-15)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      // Insert sample words using insertRawWords
      await db.insertRawWords([
        {
          'word': 'apple',
          'CEFR': 'A1',
          'Japanese': 'りんご',
          'Example': 'An apple a day.',
          'Example_JP': '1日1個のりんご。',
        },
        {
          'word': 'banana',
          'CEFR': 'A1',
          'Japanese': 'バナナ',
          'Example': 'A yellow banana.',
          'Example_JP': '黄色いバナナ。',
        },
      ]);

      // Set apple to restricted (0pt)
      final all = await db.getAllWords();
      final apple = all.firstWhere((w) => w.english == 'apple');
      await (db.update(db.words)..where((t) => t.id.equals(apple.id))).write(
        const WordsCompanion(
          isRestricted: Value(true),
          retentionPoint: Value(0),
          isMemorized: Value(false),
        ),
      );

      // Set banana to memorized (80pt)
      final banana = all.firstWhere((w) => w.english == 'banana');
      await (db.update(db.words)..where((t) => t.id.equals(banana.id))).write(
        const WordsCompanion(
          isRestricted: Value(false),
          retentionPoint: Value(80),
          isMemorized: Value(true),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('markAsMemorizedManual sets retentionPoint 80, isMemorized true, and clears isRestricted (Item 14)', () async {
      final wordsList = await db.getAllWords();
      final apple = wordsList.firstWhere((w) => w.english == 'apple');
      expect(apple.isRestricted, isTrue);
      expect(apple.isMemorized, isFalse);

      await db.markAsMemorizedManual(apple.id);

      final updatedWords = await db.getAllWords();
      final updatedApple = updatedWords.firstWhere((w) => w.english == 'apple');
      expect(updatedApple.isMemorized, isTrue);
      expect(updatedApple.retentionPoint, 80);
      expect(updatedApple.isRestricted, isFalse);
    });

    test('resetAllWordsMemorized resets all words to 0pt and unmemorized (Item 15)', () async {
      var wordsList = await db.getAllWords();
      expect(wordsList.any((w) => w.isMemorized), isTrue);

      await db.resetAllWordsMemorized();

      wordsList = await db.getAllWords();
      for (final w in wordsList) {
        expect(w.isMemorized, isFalse);
        expect(w.retentionPoint, 0);
        expect(w.isRestricted, isFalse);
      }
    });
  });
}
