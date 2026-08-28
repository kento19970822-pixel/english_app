import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/screens/flashcard_screen.dart';
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

  group('Flashcard Swipe Memorization Mode Tests', () {
    test('Right swipe memorizes word and left swipe resets with restriction', () async {
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
          retentionPoint: Value(30),
          isMemorized: Value(false),
          isRestricted: Value(false),
        ),
      );

      // 1. 右スワイプ (暗記)
      await db.markAsMemorizedManual(1);
      var word = await (db.select(db.words)..where((t) => t.id.equals(1))).getSingle();
      expect(word.retentionPoint, equals(80));
      expect(word.isMemorized, isTrue);
      expect(word.isRestricted, isFalse);

      // 2. 左スワイプ (要復習・リセット)
      await db.resetRetentionManual(1);
      word = await (db.select(db.words)..where((t) => t.id.equals(1))).getSingle();
      expect(word.retentionPoint, equals(0));
      expect(word.isMemorized, isFalse);
      expect(word.isRestricted, isTrue);

      // 3. Undo (以前の状態に復元)
      await db.restoreWordState(
        id: 1,
        retentionPoint: 80,
        isMemorized: true,
        isRestricted: false,
        pointDecreasedTotal: 0,
      );
      word = await (db.select(db.words)..where((t) => t.id.equals(1))).getSingle();
      expect(word.retentionPoint, equals(80));
      expect(word.isMemorized, isTrue);
      expect(word.isRestricted, isFalse);
    });

    testWidgets('FlashcardScreen renders card and toggles en/ja mode', (tester) async {
      const dummyWord = Word(
        id: 1,
        english: 'apple',
        japanese: 'りんご',
        partOfSpeech: 'noun',
        cefr: 'A1',
        level: 1,
        chapter: 1,
        category: 'Fruits',
        retentionPoint: 50,
        isMemorized: false,
        isRestricted: false,
        isFavorite: false,
        correctCount: 0,
        wrongCount: 0,
        pointDecreasedTotal: 0,
        senseIndex: 1,
        totalSenses: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardScreen(
            database: db,
            words: const [dummyWord],
            title: 'Ch.1 特訓 (1語)',
          ),
        ),
      );

      // 画面初期状態 (英➔和モード: 英語が表示されている)
      expect(find.text('apple'), findsOneWidget);
      expect(find.text('Ch.1 特訓 (1語)'), findsOneWidget);

      // モード切り替えボタンをタップ (和➔英モード)
      await tester.tap(find.text('英 ➔ 和'));
      await tester.pumpAndSettle();

      expect(find.text('和 ➔ 英'), findsOneWidget);
      expect(find.text('りんご'), findsOneWidget);
    });
  });
}
