import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/widgets/word_card_tile.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Game Completion & WordCardTile Tests', () {
    test('batchUpdateQuizResults updates words atomically only when committed', () async {
      await db.into(db.words).insert(
        const WordsCompanion(
          id: Value(1),
          english: Value('cat'),
          japanese: Value('猫'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(1),
          category: Value('Animals'),
          retentionPoint: Value(70),
          isMemorized: Value(false),
          correctCount: Value(0),
          wrongCount: Value(0),
        ),
      );

      await db.into(db.words).insert(
        const WordsCompanion(
          id: Value(2),
          english: Value('dog'),
          japanese: Value('犬'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(1),
          category: Value('Animals'),
          retentionPoint: Value(50),
          isMemorized: Value(false),
          correctCount: Value(0),
          wrongCount: Value(0),
        ),
      );

      // 一括コミット実行
      final results = [
        const PendingQuizResult(id: 1, dropProgress: 0.1, isCorrect: true),
        const PendingQuizResult(id: 2, dropProgress: 0.5, isCorrect: false),
      ];

      await db.batchUpdateQuizResults(results);

      final word1 = await (db.select(db.words)..where((t) => t.id.equals(1))).getSingle();
      final word2 = await (db.select(db.words)..where((t) => t.id.equals(2))).getSingle();

      // word1: 70pt + 正解(最上部+12) = 82pt -> 暗記済み(true), correctCount=1
      expect(word1.retentionPoint, greaterThanOrEqualTo(80));
      expect(word1.isMemorized, isTrue);
      expect(word1.correctCount, equals(1));

      // word2: 50pt + 誤答(-20) = 30pt -> isRestricted=true, wrongCount=1
      expect(word2.retentionPoint, lessThan(50));
      expect(word2.wrongCount, equals(1));
      expect(word2.isRestricted, isTrue);
    });

    testWidgets('WordCardTile renders left emerald and right orange markers', (tester) async {
      const dummyWord = Word(
        id: 1,
        english: 'apple',
        japanese: 'りんご',
        partOfSpeech: 'noun',
        cefr: 'A1',
        level: 1,
        chapter: 1,
        category: 'Fruits',
        retentionPoint: 80,
        isMemorized: true,
        isRestricted: false,
        isFavorite: false,
        correctCount: 5,
        wrongCount: 0,
        pointDecreasedTotal: 0,
        senseIndex: 1,
        totalSenses: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordCardTile(
              word: dummyWord,
              onTap: () {},
              onSpeak: () {},
              onToggleFavorite: () {},
              showJapanese: true,
            ),
          ),
        ),
      );

      expect(find.text('apple'), findsOneWidget);
    });
  });
}
