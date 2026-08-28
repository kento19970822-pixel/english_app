import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    testWidgets('FlashcardScreen renders 0th mode selector card, starts game on swipe, and supports keyboard', (tester) async {
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

      // 0枚目: モード選択カードが表示されていること
      expect(find.text('出題モードを選択'), findsOneWidget);
      expect(find.text('スワイプしてスタート！'), findsOneWidget);

      // 0枚目のカードを右へスワイプ（英➔和モードで開始）
      await tester.drag(find.text('スワイプしてスタート！'), const Offset(300, 0));
      await tester.pumpAndSettle();

      // 第1問目のカード（英語: apple）が表示されていること
      expect(find.text('apple'), findsOneWidget);
      expect(find.text('出題モードを選択'), findsNothing);

      // Spaceキーでカード反転（フリップ）
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      // 裏面（日本語: りんご）が表示されていること
      expect(find.text('りんご'), findsOneWidget);

      // 右矢印キーで暗記完了スワイプ
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // 完了ダイアログが表示されること
      expect(find.text('スワイプ学習完了！'), findsOneWidget);
    });
  });
}
