import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/screens/mode_select_screen.dart';
import 'package:english_app/widgets/pixel_character_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ModeSelectScreen Character Unlock Tests', () {
    testWidgets('Initial state: all chapters including Ch.1 render locked silhouette', (tester) async {
      await db.into(db.words).insert(
        const WordsCompanion(
          id: Value(1),
          english: Value('apple'),
          japanese: Value('りんご'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(1),
          category: Value('General'),
        ),
      );
      await db.into(db.words).insert(
        const WordsCompanion(
          id: Value(2),
          english: Value('banana'),
          japanese: Value('バナナ'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(2),
          category: Value('General'),
        ),
      );
      await db.initChapterProgresses();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeSelectScreen(database: db),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // チャプター1のキャラクターWidgetを探す
      final charWidgets = tester.widgetList<PixelCharacterWidget>(find.byType(PixelCharacterWidget)).toList();
      expect(charWidgets.isNotEmpty, isTrue);

      // 初期起動時は全キャラクターが locked（黒シルエット）
      for (final widget in charWidgets) {
        expect(widget.growthState, equals(CharacterGrowthState.locked));
      }
    });

    testWidgets('Unlocking Ch.2 character from words screen displays character even if chapter is locked in game', (tester) async {
      await db.into(db.words).insert(
        const WordsCompanion(
          id: Value(1),
          english: Value('apple'),
          japanese: Value('りんご'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(1),
          category: Value('General'),
        ),
      );
      await db.into(db.words).insert(
        const WordsCompanion(
          id: Value(2),
          english: Value('banana'),
          japanese: Value('バナナ'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(2),
          category: Value('General'),
          retentionPoint: Value(85), // 単語帳でCh.2の単語を暗記
          isMemorized: Value(true),
          correctCount: Value(1),
        ),
      );
      await db.initChapterProgresses();
      await db.syncAllChapterProgresses();

      final progresses = await db.getAllChapterProgresses();
      final ch2 = progresses.firstWhere((p) => p.chapter == 2);

      // Ch.2 はゲーム的には未解放（isUnlocked == false）だが、キャラクターは解放済み（isCharacterUnlocked == true）
      expect(ch2.isUnlocked, isFalse);
      expect(ch2.isCharacterUnlocked, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeSelectScreen(database: db),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Ch.2 のキャラクターWidgetが locked ではなく evolved (85pt) で表示されること
      final charWidgets = tester.widgetList<PixelCharacterWidget>(find.byType(PixelCharacterWidget)).toList();
      final ch2Widget = charWidgets.firstWhere((w) => w.speciesIndex == 1); // speciesIndex 1 = Ch.2
      expect(ch2Widget.growthState, equals(CharacterGrowthState.evolved));
    });
  });
}
