import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/db/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 1 Performance & Robustness Tests', () {
    test('syncAllChapterProgresses computes memorizedRate in a single query and unlocks correctly', () async {
      // 1. チャプター1と2の単語を投入 (10語中9語が70pt以上 -> 90%)
      for (int i = 1; i <= 10; i++) {
        await db.into(db.words).insert(
          WordsCompanion(
            id: Value(i),
            english: Value('word$i'),
            japanese: Value('意味$i'),
            partOfSpeech: const Value('noun'),
            cefr: const Value('A1'),
            level: const Value(1),
            chapter: const Value(1),
            category: const Value('General'),
            retentionPoint: Value(i <= 9 ? 70 : 60),
            isMemorized: Value(i <= 9),
          ),
        );
      }

      // チャプター2の単語 (10語中5語が70pt以上 -> 50%)
      for (int i = 11; i <= 20; i++) {
        await db.into(db.words).insert(
          WordsCompanion(
            id: Value(i),
            english: Value('word$i'),
            japanese: Value('意味$i'),
            partOfSpeech: const Value('noun'),
            cefr: const Value('A1'),
            level: const Value(1),
            chapter: const Value(2),
            category: const Value('General'),
            retentionPoint: Value(i <= 15 ? 70 : 40),
            isMemorized: Value(i <= 15),
          ),
        );
      }

      // 2. 初期チャプター進捗を作成
      await db.initChapterProgresses();

      // 3. 高速集計SQLによる全同期を実行
      await db.syncAllChapterProgresses();

      final cp1 = await (db.select(db.chapterProgresses)..where((t) => t.chapter.equals(1))).getSingle();
      final cp2 = await (db.select(db.chapterProgresses)..where((t) => t.chapter.equals(2))).getSingle();
      final cp3 = await (db.select(db.chapterProgresses)..where((t) => t.chapter.equals(3))).getSingleOrNull();

      expect(cp1.memorizedRate, closeTo(90.0, 0.1));
      expect(cp1.isCleared, isTrue);

      expect(cp2.memorizedRate, closeTo(50.0, 0.1));
      expect(cp2.isCleared, isFalse);
      expect(cp2.isUnlocked, isTrue); // Ch.1 がクリアされたため Ch.2 が解放

      if (cp3 != null) {
        expect(cp3.isUnlocked, isFalse); // Ch.2 は 50% で未クリアのため Ch.3 は未解放
      }
    });

    test('wordsDataVersion increments upon data modifications', () async {
      final initialVersion = db.wordsDataVersion;
      expect(initialVersion, 1);

      await db.into(db.words).insert(
        const WordsCompanion(
          id: Value(101),
          english: Value('test'),
          japanese: Value('テスト'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(1),
          category: Value('General'),
        ),
      );

      // お気に入りトグルでバージョンがインクリメント
      await db.toggleFavorite(101, true);
      expect(db.wordsDataVersion, initialVersion + 1);

      // 手動暗記化でバージョンがインクリメント
      await db.markAsMemorizedManual(101);
      expect(db.wordsDataVersion, initialVersion + 2);

      // 手動リセットでバージョンがインクリメント
      await db.resetRetentionManual(101);
      expect(db.wordsDataVersion, initialVersion + 3);
    });

    test('checkAndUnlockNextChapter executes atomically and returns clear stats', () async {
      for (int i = 1; i <= 10; i++) {
        await db.into(db.words).insert(
          WordsCompanion(
            id: Value(200 + i),
            english: Value('atom$i'),
            japanese: Value('原子$i'),
            partOfSpeech: const Value('noun'),
            cefr: const Value('A1'),
            level: const Value(1),
            chapter: const Value(5),
            category: const Value('General'),
            retentionPoint: Value(i <= 9 ? 75 : 50),
            isMemorized: Value(i <= 9),
          ),
        );
      }

      // チャプター6の単語も投入して initChapterProgresses で Ch.6 を生成
      await db.into(db.words).insert(
        const WordsCompanion(
          id: Value(250),
          english: Value('ch6_word'),
          japanese: Value('チャプター6単語'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(6),
          category: Value('General'),
        ),
      );

      await db.initChapterProgresses();

      final result = await db.checkAndUnlockNextChapter(5);
      expect(result['isCleared'], isTrue);
      expect(result['memorizedRate'], closeTo(90.0, 0.1));
      expect(result['nextChapterUnlocked'], 6);

      final cp6 = await (db.select(db.chapterProgresses)..where((t) => t.chapter.equals(6))).getSingle();
      expect(cp6.isUnlocked, isTrue);
    });
  });
}
