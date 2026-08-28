import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/widgets/pixel_character_widget.dart';
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

  group('Strict Character Growth & Chapter Unlock Criteria Tests', () {
    test('Character growth strictly requires retention_point >= 80 (forgetting curve linked)', () async {
      // 1. チャプター1に10単語登録（全て暗記フラグisMemorized=trueだが、忘却減算でretentionPoint=79ptに低下）
      for (int i = 1; i <= 10; i++) {
        await db.into(db.words).insert(
          WordsCompanion(
            id: Value(i),
            english: Value('word$i'),
            japanese: Value('単語$i'),
            partOfSpeech: const Value('noun'),
            cefr: const Value('A1'),
            level: const Value(1),
            chapter: const Value(1),
            category: const Value('General'),
            retentionPoint: const Value(79), // 79pt (70pt以上だが80pt未満)
            isMemorized: const Value(true),  // 暗記フラグは立ったまま
          ),
        );
      }

      // チャプター2の単語も登録して initChapterProgresses で Ch.2 を生成
      await db.into(db.words).insert(
        const WordsCompanion(
          id: Value(11),
          english: Value('ch2_word'),
          japanese: Value('チャプター2単語'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(2),
          category: Value('General'),
        ),
      );

      await db.initChapterProgresses();
      await db.syncAllChapterProgresses();

      // 暗記率（memorizedRate）は実質80pt以上の割合なので 0.0%
      final memorizedRate = await db.calculateChapterMemorizedRate(1);
      expect(memorizedRate, equals(0.0));

      // 解放率（unlockRate）は実質70pt以上の割合なので 100.0%
      final unlockRate = await db.calculateChapterUnlockRate(1);
      expect(unlockRate, equals(100.0));

      // キャラクター成長状態: 80pt以上の単語が0%のため、絶対に進化(evolved)せず locked
      final characterState = PixelCharacterWidget.stateFromRate(memorizedRate, true);
      expect(characterState, isNot(equals(CharacterGrowthState.evolved)));
      expect(characterState, equals(CharacterGrowthState.locked));

      // 次章解放判定: 70pt以上が100%（>=90%）なのでクリア・次章解放される
      final unlockResult = await db.checkAndUnlockNextChapter(1);
      expect(unlockResult['isCleared'], isTrue);
      expect(unlockResult['nextChapterUnlocked'], equals(2));

      // 2. 単語を復習して 80pt 以上（85pt）に引き上げる（10単語中8単語 = 80%）
      for (int i = 1; i <= 8; i++) {
        await (db.update(db.words)..where((t) => t.id.equals(i))).write(
          const WordsCompanion(retentionPoint: Value(85)),
        );
      }
      await db.syncAllChapterProgresses();

      final newMemorizedRate = await db.calculateChapterMemorizedRate(1);
      expect(newMemorizedRate, equals(80.0)); // 8/10 = 80.0%

      // 80%に達したことで、初めてキャラクターが進化（evolved）する
      final newCharacterState = PixelCharacterWidget.stateFromRate(newMemorizedRate, true);
      expect(newCharacterState, equals(CharacterGrowthState.evolved));
    });
  });
}
