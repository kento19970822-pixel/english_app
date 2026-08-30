import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:english_app/db/app_database.dart';
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

  group('Character Unlock Lifecycle Tests (Ch.1 included)', () {
    test('Initial startup & Full reset: all chapters including Ch.1 are locked silhouette (isCharacterUnlocked = false)', () async {
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

      final progresses = await db.getAllChapterProgresses();
      final ch1 = progresses.firstWhere((p) => p.chapter == 1);
      final ch2 = progresses.firstWhere((p) => p.chapter == 2);

      // Ch.1 はプレイ可能 (isUnlocked = true) だが、初期キャラは未解放 (isCharacterUnlocked = false)
      expect(ch1.isUnlocked, isTrue);
      expect(ch1.isCharacterUnlocked, isFalse);
      expect(PixelCharacterWidget.stateFromRate(0.0, ch1.isCharacterUnlocked), CharacterGrowthState.locked);

      // Ch.2 は未解放
      expect(ch2.isUnlocked, isFalse);
      expect(ch2.isCharacterUnlocked, isFalse);
      expect(PixelCharacterWidget.stateFromRate(0.0, ch2.isCharacterUnlocked), CharacterGrowthState.locked);
    });

    test('Learning a word unlocks character; decaying to 0% retains lowHealth (never reverts to locked)', () async {
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
      await db.initChapterProgresses();

      // 単語を学習 (暗記ポイント獲得)
      await (db.update(db.words)..where((t) => t.chapter.equals(1))).write(
        const WordsCompanion(
          retentionPoint: Value(85),
          isMemorized: Value(true),
          correctCount: Value(1),
        ),
      );

      await db.syncAllChapterProgresses();

      var progresses = await db.getAllChapterProgresses();
      var ch1 = progresses.firstWhere((p) => p.chapter == 1);

      // キャラクター解放 (isCharacterUnlocked = true, evolved)
      expect(ch1.isCharacterUnlocked, isTrue);
      expect(PixelCharacterWidget.stateFromRate(85.0, ch1.isCharacterUnlocked), CharacterGrowthState.evolved);

      // 忘却曲線減衰で暗記率が 0% に低下
      await (db.update(db.words)..where((t) => t.chapter.equals(1))).write(
        const WordsCompanion(
          retentionPoint: Value(0),
          isMemorized: Value(false),
        ),
      );
      await db.syncAllChapterProgresses();

      progresses = await db.getAllChapterProgresses();
      ch1 = progresses.firstWhere((p) => p.chapter == 1);

      // 0% になっても isCharacterUnlocked は true のまま！ locked（シルエット）に戻らず lowHealth を維持
      expect(ch1.isCharacterUnlocked, isTrue);
      expect(PixelCharacterWidget.stateFromRate(0.0, ch1.isCharacterUnlocked), CharacterGrowthState.lowHealth);

      // 完全リセット実行
      await db.resetAllLearningData();

      progresses = await db.getAllChapterProgresses();
      ch1 = progresses.firstWhere((p) => p.chapter == 1);

      // 完全リセット後は再び初期黒シルエット (isCharacterUnlocked = false) に戻る
      expect(ch1.isCharacterUnlocked, isFalse);
      expect(PixelCharacterWidget.stateFromRate(0.0, ch1.isCharacterUnlocked), CharacterGrowthState.locked);
    });
  });
}
