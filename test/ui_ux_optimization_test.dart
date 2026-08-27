import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/widgets/pixel_character_widget.dart';
import 'package:english_app/widgets/word_filter_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WordFilterState Tests', () {
    test('Initial state has no active filters', () {
      const state = WordFilterState();
      expect(state.hasActiveFilter, isFalse);
      expect(state.activeFilterCount, equals(0));
    });

    test('State calculates active filters correctly', () {
      final state = const WordFilterState().copyWith(
        filterUnlearned: true,
        selectedCefr: 'B1',
        selectedChapter: '2',
      );
      expect(state.hasActiveFilter, isTrue);
      expect(state.activeFilterCount, equals(3));
    });
  });

  group('POS Conversion Tests', () {
    test('toShortJapanesePos returns clean 1-char without brackets', () {
      expect(AppDatabase.toShortJapanesePos('noun'), equals('名'));
      expect(AppDatabase.toShortJapanesePos('verb'), equals('動'));
      expect(AppDatabase.toShortJapanesePos('adjective'), equals('形'));
      expect(AppDatabase.toShortJapanesePos('adverb'), equals('副'));
      expect(AppDatabase.toShortJapanesePos('preposition'), equals('前'));
    });

    test('toFullJapanesePos returns clean full string without brackets', () {
      expect(AppDatabase.toFullJapanesePos('noun'), equals('名詞'));
      expect(AppDatabase.toFullJapanesePos('verb'), equals('動詞'));
      expect(AppDatabase.toFullJapanesePos('adjective'), equals('形容詞'));
      expect(AppDatabase.toFullJapanesePos('adverb'), equals('副詞'));
      expect(AppDatabase.toFullJapanesePos('preposition'), equals('前置詞'));
    });
  });

  group('Character Total Count Tests', () {
    test('kTotalChapterCount equals 350', () {
      expect(kTotalChapterCount, equals(350));
      final species1 = getCharacterSpecies(1);
      expect(species1.chapter, equals(1));
      final species350 = getCharacterSpecies(350);
      expect(species350.chapter, equals(350));
    });
  });

  group('WordFilterBottomSheet Widget Tests', () {
    testWidgets('WordFilterBottomSheet renders options and dynamically links CEFR with chapters', (WidgetTester tester) async {
      WordFilterState? appliedState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  WordFilterBottomSheet.show(
                    context: context,
                    initialFilter: const WordFilterState(),
                    sortMode: 'chap',
                    availableCefr: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'],
                    availableChapters: [1, 2, 3, 10, 11, 12, 300],
                    cefrToChapters: {
                      'A1': [1, 2, 3],
                      'A2': [10, 11, 12],
                      'C2': [300],
                    },
                    availableAz: ['A', 'B', 'C'],
                    availableCategories: ['Daily', 'Business'],
                    onApply: (state) {
                      appliedState = state;
                    },
                  );
                },
                child: const Text('Open Filter'),
              ),
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open Filter'));
      await tester.pumpAndSettle();

      expect(find.text('絞り込みフィルター'), findsOneWidget);
      expect(find.text('未暗記のみ'), findsOneWidget);
      expect(find.text('お気に入り'), findsOneWidget);
      expect(find.text('C2'), findsOneWidget);

      // Select C2 to trigger dynamic chapter filter
      await tester.tap(find.text('C2'));
      await tester.pumpAndSettle();

      // Open chapter dropdown
      await tester.tap(find.text('すべてのチャプター'));
      await tester.pumpAndSettle();

      // Chapter 300 should be visible for C2, while Chapter 1 should NOT be in the C2 list
      expect(find.text('Chapter 300'), findsOneWidget);
      expect(find.text('Chapter 1'), findsNothing);

      // Select Chapter 300
      await tester.tap(find.text('Chapter 300').last);
      await tester.pumpAndSettle();

      // Apply
      await tester.tap(find.text('条件を適用して表示'));
      await tester.pumpAndSettle();

      expect(appliedState, isNotNull);
      expect(appliedState!.selectedCefr, equals('C2'));
      expect(appliedState!.selectedChapter, equals('300'));
    });
  });

  group('AppDatabase Fast Query Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      // Insert sample words
      await db.into(db.words).insert(
            WordsCompanion.insert(
              id: const Value(1),
              level: const Value(1),
              chapter: const Value(1),
              english: 'apple',
              japanese: 'りんご',
              partOfSpeech: const Value('noun'),
              cefr: const Value('A1'),
              category: const Value('Daily'),
              phonetic: const Value('æpl'),
              example: const Value('An apple a day.'),
              exampleJp: const Value('一日一個のりんご。'),
              collocations: const Value('[]'),
              otherMeanings: const Value('[]'),
              senseIndex: const Value(1),
              totalSenses: const Value(1),
              retentionPoint: const Value(50),
              pointDecreasedTotal: const Value(0),
              isMemorized: const Value(false),
              isRestricted: const Value(false),
              isFavorite: const Value(false),
              correctCount: const Value(0),
              wrongCount: const Value(0),
            ),
          );

      await db.into(db.words).insert(
            WordsCompanion.insert(
              id: const Value(2),
              level: const Value(2),
              chapter: const Value(11),
              english: 'banana',
              japanese: 'バナナ',
              partOfSpeech: const Value('noun'),
              cefr: const Value('A2'),
              category: const Value('Daily'),
              phonetic: const Value('bənænə'),
              example: const Value('Yellow banana.'),
              exampleJp: const Value('黄色いバナナ。'),
              collocations: const Value('[]'),
              otherMeanings: const Value('[]'),
              senseIndex: const Value(1),
              totalSenses: const Value(1),
              retentionPoint: const Value(80),
              pointDecreasedTotal: const Value(0),
              isMemorized: const Value(true),
              isRestricted: const Value(false),
              isFavorite: const Value(false),
              correctCount: const Value(2),
              wrongCount: const Value(0),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('getWordsByLevel returns only level matching words', () async {
      final level1Words = await db.getWordsByLevel(1);
      expect(level1Words.length, equals(1));
      expect(level1Words.first.english, equals('apple'));

      final level2Words = await db.getWordsByLevel(2);
      expect(level2Words.length, equals(1));
      expect(level2Words.first.english, equals('banana'));
    });

    test('getWordsByLevels returns matching words for multiple levels', () async {
      final multiLevelWords = await db.getWordsByLevels([1, 2]);
      expect(multiLevelWords.length, equals(2));
    });

    test('getWordsByChapter returns matching words for chapter', () async {
      final ch1Words = await db.getWordsByChapter(1);
      expect(ch1Words.length, equals(1));
      expect(ch1Words.first.english, equals('apple'));

      final ch11Words = await db.getWordsByChapter(11);
      expect(ch11Words.length, equals(1));
      expect(ch11Words.first.english, equals('banana'));
    });
  });
}
