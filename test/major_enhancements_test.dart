import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/models/word_detail_model.dart';
import 'package:english_app/widgets/pixel_character_widget.dart';
import 'package:english_app/widgets/word_detail_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('POS Detection & WordSense Model Tests', () {
    test('detectPartOfSpeech classifies verbs, nouns, adjectives correctly', () {
      expect(AppDatabase.detectPartOfSpeech('走る'), '動');
      expect(AppDatabase.detectPartOfSpeech('食べる、食事する'), '動');
      expect(AppDatabase.detectPartOfSpeech('美しい'), '形');
      expect(AppDatabase.detectPartOfSpeech('静かな'), '形');
      expect(AppDatabase.detectPartOfSpeech('素早く'), '副');
      expect(AppDatabase.detectPartOfSpeech('学校'), '名');
      expect(AppDatabase.detectPartOfSpeech('しかし'), '接');
      expect(AppDatabase.detectPartOfSpeech('〜の上に'), '前');
    });

    test('WordSense parses structured JSON and fallback correctly', () {
      const jsonStr = '[{"sense_id":1,"part_of_speech":"名","meaning_ja":"本","cefr":"A1","example_en":"Read a book.","example_ja":"本を読む。"},{"sense_id":2,"part_of_speech":"動","meaning_ja":"予約する","cefr":"B1","example_en":"Book a hotel.","example_ja":"ホテルを予約する。"}]';

      final word = Word(
        id: 1,
        english: 'book',
        japanese: '本、予約する',
        partOfSpeech: '名',
        level: 1,
        chapter: 1,
        cefr: 'A1',
        category: 'General',
        phonetic: '/bʊk/',
        example: 'Read a book.',
        exampleJp: '本を読む。',
        collocations: '["book a room"]',
        otherMeanings: jsonStr,
        senseIndex: 1,
        totalSenses: 2,
        retentionPoint: 90,
        pointDecreasedTotal: 0,
        isMemorized: true,
        isRestricted: false,
        isFavorite: true,
        correctCount: 5,
        wrongCount: 0,
      );

      final detail = WordDetail.fromWord(word);
      expect(detail.senses.length, 2);
      expect(detail.senses[0].partOfSpeech, '名');
      expect(detail.senses[0].meaningJa, '本');
      expect(detail.senses[1].partOfSpeech, '動');
      expect(detail.senses[1].meaningJa, '予約する');
      expect(detail.collocations, ['book a room']);
    });
  });

  group('WordDetailModal Widget Tests', () {
    testWidgets('WordDetailModal renders pronunciation, senses, and navigation', (WidgetTester tester) async {
      final List<Word> words = [
        const Word(
          id: 1,
          english: 'apple',
          japanese: 'りんご',
          partOfSpeech: '名',
          level: 1,
          chapter: 1,
          cefr: 'A1',
          category: 'Food',
          phonetic: '/ˈæp.əl/',
          example: 'I like apple.',
          exampleJp: 'りんごが好きです。',
          senseIndex: 1,
          totalSenses: 1,
          retentionPoint: 70,
          pointDecreasedTotal: 10,
          isMemorized: false,
          isRestricted: false,
          isFavorite: false,
          correctCount: 3,
          wrongCount: 1,
        ),
        const Word(
          id: 2,
          english: 'banana',
          japanese: 'バナナ',
          partOfSpeech: '名',
          level: 1,
          chapter: 1,
          cefr: 'A1',
          category: 'Food',
          phonetic: '/bəˈnæn.ə/',
          example: 'Yellow banana.',
          exampleJp: '黄色いバナナ。',
          senseIndex: 1,
          totalSenses: 1,
          retentionPoint: 95,
          pointDecreasedTotal: 0,
          isMemorized: true,
          isRestricted: false,
          isFavorite: true,
          correctCount: 8,
          wrongCount: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  WordDetailModal.show(
                    context: context,
                    wordList: words,
                    initialIndex: 0,
                    database: db,
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Check Header details
      expect(find.text('apple'), findsOneWidget);
      expect(find.text('/ˈæp.əl/'), findsOneWidget);
      expect(find.text('りんご'), findsOneWidget);
      expect(find.text('70 pt'), findsOneWidget);
      expect(find.text('(-10 pt)'), findsOneWidget);

      // Tap Next button [次へ →]
      expect(find.text('次へ'), findsOneWidget);
      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();

      // Check 2nd word details
      expect(find.text('banana'), findsOneWidget);
      expect(find.text('/bəˈnæn.ə/'), findsOneWidget);
      expect(find.text('バナナ'), findsOneWidget);
      expect(find.text('95 pt'), findsOneWidget);
    });
  });

  group('Buddy Dynamic Chest Badge Tests', () {
    testWidgets('PixelCharacterWidget renders with equipped stamp without crashing', (WidgetTester tester) async {
      final sampleStamp = Stamp(
        id: 'stamp_01',
        name: 'サニーレモン',
        rarity: 'normal',
        colorPaletteId: 7,
        patternId: 1,
        frameId: 0,
        effectId: 0,
        description: 'テスト',
        isUnlocked: true,
        isFavorite: true,
        phase: 1,
        iconCode: '',
        conditionType: 'none',
        conditionValue: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PixelCharacterWidget(
                speciesIndex: 0,
                growthState: CharacterGrowthState.healthy,
                actionState: CharacterActionState.idle,
                favoriteStamp: sampleStamp,
                size: 80,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PixelCharacterWidget), findsOneWidget);
    });
  });

  group('Chapter & Level Mapping Tests', () {
    test('initChapterProgresses and getAllChapterProgresses correctly handle levels 1, 2, 3', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      // Insert words across Level 1 (A1), Level 2 (B1), Level 3 (C1)
      await db.insertRawWords([
        {
          'word': 'dog',
          'Japanese': '犬',
          'CEFR': 'A1',
          'PartOfSpeech': 'noun',
          'Category': 'Animals',
        },
        {
          'word': 'elephant',
          'Japanese': '象',
          'CEFR': 'B1',
          'PartOfSpeech': 'noun',
          'Category': 'Animals',
        },
        {
          'word': 'biodiversity',
          'Japanese': '生物多様性',
          'CEFR': 'C1',
          'PartOfSpeech': 'noun',
          'Category': 'Science',
        },
      ]);

      final progresses = await db.getAllChapterProgresses();
      expect(progresses.length, 3);

      final lvl1 = progresses.where((cp) => cp.level == 1).toList();
      final lvl2 = progresses.where((cp) => cp.level == 2).toList();
      final lvl3 = progresses.where((cp) => cp.level == 3).toList();

      expect(lvl1.length, 1);
      expect(lvl1.first.isUnlocked, isTrue);

      expect(lvl2.length, 1);
      expect(lvl2.first.isUnlocked, isTrue);

      expect(lvl3.length, 1);
      expect(lvl3.first.isUnlocked, isTrue);
    });
  });
}

