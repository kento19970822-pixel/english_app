import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;
import 'package:english_app/db/app_database.dart';
import 'package:english_app/services/srs_service.dart';
import 'package:english_app/widgets/active_recall_card.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // テスト用初期単語
    await db.into(db.words).insert(
      const WordsCompanion(
        id: drift.Value(1),
        english: drift.Value('apple'),
        japanese: drift.Value('りんご'),
        partOfSpeech: drift.Value('名詞'),
        cefr: drift.Value('A1'),
        level: drift.Value(1),
        chapter: drift.Value(1),
        category: drift.Value('Fruits'),
      ),
    );
    await db.populateSensesAndProgressFromWords();
  });

  tearDown(() async {
    await db.close();
  });

  group('3NF Database Normalization Tests', () {
    test('populateSensesAndProgressFromWords seeds WordSenses and UserWordProgresses', () async {
      final senses = await db.getSensesForWord(1);
      expect(senses.length, 1);
      expect(senses.first.japanese, 'りんご');
      expect(senses.first.cefr, 'A1');

      final progress = await db.getUserWordProgress(1);
      expect(progress, isNotNull);
      expect(progress!.wordId, 1);
      expect(progress.srsEaseFactor, 2.5);
    });
  });

  group('SRS Engine (SuperMemo SM-2) Calculation Tests', () {
    test('SM-2 Ease Factor calculation behaves correctly', () {
      final initialEase = 2.5;

      // 完璧/即答 (quality: 4) -> Ease Factor 上昇
      final easeUp = SrsService.calculateNewEaseFactor(initialEase, 4);
      expect(easeUp, greaterThan(2.5));

      // 忘却/不正解 (quality: 0) -> Ease Factor 下降 (最低1.3)
      final easeDown = SrsService.calculateNewEaseFactor(initialEase, 0);
      expect(easeDown, lessThan(2.5));
    });

    test('SM-2 Interval calculation resets on failure and expands on success', () {
      final ease = 2.5;

      // 不正解 (quality: 1) -> 1日にリセット
      expect(SrsService.calculateNextInterval(15, ease, 1), 1);

      // 初期正解 -> 1日 -> 3日 -> 7日
      expect(SrsService.calculateNextInterval(0, ease, 3), 1);
      expect(SrsService.calculateNextInterval(1, ease, 3), 3);
      expect(SrsService.calculateNextInterval(3, ease, 3), 7);
      expect(SrsService.calculateNextInterval(7, ease, 3), (7 * ease).round());
    });

    test('updateSrsReviewResult updates DB and synchronizes with words table', () async {
      // 1. 正解として復習記録
      final updated = await db.updateSrsReviewResult(wordId: 1, quality: 3);
      expect(updated.correctCount, 1);
      expect(updated.srsIntervalDays, 1);
      expect(updated.retentionPoint, 15);

      // words テーブルも同期されていること
      final word = await (db.select(db.words)..where((t) => t.id.equals(1))).getSingle();
      expect(word.retentionPoint, 15);
      expect(word.correctCount, 1);
    });

    test('getDueWords returns words that have nextReviewAt <= now', () async {
      // 復習期日を過去日時に設定（学習実績あり）
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await (db.update(db.userWordProgresses)..where((t) => t.wordId.equals(1))).write(
        UserWordProgressesCompanion(
          lastStudiedAt: drift.Value(yesterday),
          nextReviewAt: drift.Value(yesterday),
        ),
      );

      final dueWords = await db.getDueWords();
      expect(dueWords.length, 1);
      expect(dueWords.first.english, 'apple');
    });
  });

  group('ActiveRecallCard Widget Tests', () {
    testWidgets('ActiveRecallCard renders hint and reveals word on tap', (tester) async {
      final word = Word(
        id: 1,
        english: 'banana',
        japanese: 'バナナ',
        partOfSpeech: '名詞',
        cefr: 'A1',
        level: 1,
        chapter: 1,
        category: 'Fruits',
        retentionPoint: 0,
        pointDecreasedTotal: 0,
        isMemorized: false,
        isRestricted: false,
        isFavorite: false,
        correctCount: 0,
        wrongCount: 0,
        senseIndex: 1,
        totalSenses: 1,
      );

      int? recordedQuality;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveRecallCard(
              word: word,
              onRate: (q) => recordedQuality = q,
            ),
          ),
        ),
      );

      // 日本語と穴埋めヒントが表示されていること
      expect(find.text('バナナ'), findsOneWidget);
      expect(find.textContaining('b _ _ _ _ a (6文字)'), findsOneWidget);

      // タップして開示
      await tester.tap(find.textContaining('b _ _ _ _ a'));
      await tester.pumpAndSettle();

      // 正解単語と自己評価ボタンが表示されること
      expect(find.text('banana'), findsOneWidget);
      expect(find.text('覚えている'), findsOneWidget);

      // 覚えているボタンをタップ
      await tester.tap(find.text('覚えている'));
      await tester.pumpAndSettle();

      expect(recordedQuality, 3);
    });
  });
}
