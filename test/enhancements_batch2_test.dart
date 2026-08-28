import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/models/word_section.dart';
import 'package:english_app/theme/app_theme.dart';
import 'package:english_app/widgets/words/word_chapter_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Batch 2 Enhancements Unit Tests', () {
    test('1. calculateChapterMemorizedRate uses 70pt threshold (unlock condition)', () async {
      for (int i = 1; i <= 10; i++) {
        await db.into(db.words).insert(
          WordsCompanion(
            english: Value('word_'),
            japanese: Value('単語_'),
            partOfSpeech: const Value('noun'),
            cefr: const Value('A1'),
            level: const Value(1),
            chapter: const Value(1),
            category: const Value('General'),
            retentionPoint: Value(i <= 9 ? 70 : 60),
            isMemorized: const Value(false),
          ),
        );
      }

      final rate = await db.calculateChapterMemorizedRate(1);
      expect(rate, 90.0);

      final result = await db.checkAndUnlockNextChapter(1);
      expect(result['isCleared'], true);
    });

    testWidgets('2. WordChapterBanner displays correct rate and not 0% when filtered', (tester) async {
      final section = WordSection(
        key: 'ch_1',
        title: '1',
        words: [
          const Word(
            id: 1,
            english: 'test',
            japanese: 'テスト',
            partOfSpeech: 'noun',
            cefr: 'A1',
            level: 1,
            chapter: 1,
            category: 'General',
            isFavorite: false,
            senseIndex: 1,
            totalSenses: 1,
            retentionPoint: 0,
            pointDecreasedTotal: 0,
            isMemorized: false,
            isRestricted: false,
            correctCount: 0,
            wrongCount: 0,
          ),
        ],
        memorizedCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordChapterBanner(
              section: section,
              totalChapterWords: 10,
              memorizedChapterWords: 8,
            ),
          ),
        ),
      );

      expect(find.text('80%'), findsOneWidget);
      expect(find.text('MASTER ✨'), findsOneWidget);
    });

    test('3. AppTheme defines SystemUiOverlayStyle.dark for lightTheme and light for darkTheme', () {
      expect(
        AppTheme.lightTheme.appBarTheme.systemOverlayStyle?.statusBarBrightness,
        Brightness.light,
      );
      expect(
        AppTheme.darkTheme.appBarTheme.systemOverlayStyle?.statusBarBrightness,
        Brightness.dark,
      );
    });

    test('4. checkAndUnlockNextChapter unlocks Chapter 2 when Chapter 1 reaches 90% (70pt+)', () async {
      await db.delete(db.words).go();
      await db.delete(db.chapterProgresses).go();

      // Chapter 1 & Chapter 2 の単語を準備
      for (int i = 1; i <= 10; i++) {
        await db.into(db.words).insert(
          WordsCompanion(
            english: Value('apple_'),
            japanese: Value('りんご_'),
            partOfSpeech: const Value('noun'),
            cefr: const Value('A1'),
            level: const Value(1),
            chapter: const Value(1),
            category: const Value('General'),
            retentionPoint: const Value(75),
            isMemorized: const Value(false),
          ),
        );
      }
      await db.into(db.words).insert(
        const WordsCompanion(
          english: Value('banana_1'),
          japanese: Value('バナナ_1'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(2),
          category: Value('General'),
          retentionPoint: Value(0),
          isMemorized: Value(false),
        ),
      );

      await db.initChapterProgresses();

      final initialCp2 = await (db.select(db.chapterProgresses)..where((t) => t.chapter.equals(2))).getSingle();
      expect(initialCp2.isUnlocked, false);

      final unlockResult = await db.checkAndUnlockNextChapter(1);
      expect(unlockResult['isCleared'], true);
      expect(unlockResult['nextChapterUnlocked'], 2);

      final updatedCp2 = await (db.select(db.chapterProgresses)..where((t) => t.chapter.equals(2))).getSingle();
      expect(updatedCp2.isUnlocked, true);
    });
  });
}
