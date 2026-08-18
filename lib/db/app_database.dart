import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// テーブル定義ファイルの読み込み
import 'tables/words.dart';
import 'tables/learning_history.dart';
import 'tables/daily_records.dart';
import 'tables/stamps.dart';
import '../services/retention_service.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Words, LearningHistory, DailyRecords, Stamps])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      for (final table in allTables) {
        await m.deleteTable(table.actualTableName);
        await m.createTable(table);
      }
    },
  );

  /// CEFR文字列を数値レベルに変換するヘルパー関数
  int _cefrToLevel(String cefr) {
    final cleanCefr = cefr.toUpperCase().replaceAll('"', '').trim();
    switch (cleanCefr) {
      case 'A1':
        return 1;
      case 'A2':
        return 2;
      case 'B1':
        return 3;
      case 'B2':
        return 4;
      case 'C1':
        return 5;
      case 'C2':
        return 6;
      default:
        return 1;
    }
  }

  // --- 単語データ操作 ---

  /// 全単語の取得
  Future<List<Word>> getAllWords() async {
    return select(words).get();
  }

  /// 【1日1回処理】忘却曲線による定着度ポイント減算 ＆ 制限フラグ一括解除 (F-05)
  /// ※is_memorized フラグは自動では外さず手動更新用に保持する
  Future<int> syncDailyForgettingAndRestrictions() async {
    final now = DateTime.now();
    final allWordsList = await select(words).get();
    int updatedCount = 0;

    for (final word in allWordsList) {
      bool needUpdate = false;
      int newPoint = word.retentionPoint;
      bool newIsRestricted = word.isRestricted;
      DateTime? newLastRestrictedDate = word.lastRestrictedDate;

      // 1. 忘却曲線減衰処理 (最終解答日時が存在する場合)
      if (word.lastStudiedAt != null) {
        newPoint = RetentionService.calculateForgettingCurve(
          currentPoint: word.retentionPoint,
          lastStudiedAt: word.lastStudiedAt!,
          correctCount: word.correctCount,
          now: now,
        );

        if (newPoint != word.retentionPoint) {
          needUpdate = true;
        }
      }

      // 2. 日付跨ぎ制限フラグの解除 (0:00超過)
      if (word.isRestricted) {
        newIsRestricted = false;
        newLastRestrictedDate = null;
        needUpdate = true;
      }

      // 変更がある場合のみDB更新
      if (needUpdate) {
        await (update(words)..where((t) => t.id.equals(word.id))).write(
          WordsCompanion(
            retentionPoint: Value(newPoint),
            isRestricted: Value(newIsRestricted),
            lastRestrictedDate: Value(newLastRestrictedDate),
          ),
        );
        updatedCount++;
      }
    }

    return updatedCount;
  }

  /// 【案B実装】学習モード用出題単語取得 (章指定)
  /// 出題条件: (未暗記 OR 定着度 < 70pt) かつ 当日制限フラグなし
  Future<List<Word>> getLearningWordsByChapter(int chapter) async {
    return (select(words)
          ..where((t) => t.chapter.equals(chapter))
          ..where(
            (t) =>
                (t.isMemorized.equals(false) |
                    t.retentionPoint.isSmallerThanValue(70)) &
                t.isRestricted.equals(false),
          ))
        .get();
  }

  /// 単語データの括挿入（CSV取り込み用）
  Future<void> insertRawWords(List<Map<String, String>> rawWords) async {
    final List<Map<String, dynamic>> processedList = [];

    for (var i = 0; i < rawWords.length; i++) {
      final row = rawWords[i];
      final english = row['word'] ?? row['english'] ?? '';
      final japanese = row['Japanese'] ?? row['japanese'] ?? '';
      final cefr = row['CEFR'] ?? row['cefr'] ?? 'A1';
      final phonetic = row['Phonetic'] ?? row['phonetic'];
      final level = _cefrToLevel(cefr);

      processedList.add({
        'originalIndex': i,
        'english': english,
        'japanese': japanese,
        'cefr': cefr,
        'level': level,
        'phonetic': phonetic,
      });
    }

    processedList.sort((a, b) {
      final aLevel = a['level'] as int;
      final bLevel = b['level'] as int;
      if (aLevel != bLevel) return aLevel.compareTo(bLevel);
      return (a['originalIndex'] as int).compareTo(b['originalIndex'] as int);
    });

    int globalChapter = 1;
    int currentLevel = -1;
    int levelWordCount = 0;

    await batch((batch) {
      for (final item in processedList) {
        final level = item['level'] as int;

        if (currentLevel == -1) {
          currentLevel = level;
          levelWordCount = 0;
        } else if (level != currentLevel) {
          if (levelWordCount > 0) {
            globalChapter++;
          }
          currentLevel = level;
          levelWordCount = 0;
        } else if (levelWordCount > 0 && levelWordCount % 100 == 0) {
          globalChapter++;
        }

        levelWordCount++;

        final englishStr = item['english']?.toString() ?? '';
        final japaneseStr = item['japanese']?.toString() ?? '';
        final cefrStr = item['cefr']?.toString() ?? 'A1';
        final phoneticStr = item['phonetic']?.toString();

        batch.insert(
          words,
          WordsCompanion.insert(
            english: englishStr,
            japanese: japaneseStr,
            cefr: Value(cefrStr),
            level: Value(level),
            chapter: Value(globalChapter),
            phonetic: Value(phoneticStr),
          ),
        );
      }
    });
  }

  /// 全単語データの削除
  Future<void> clearAllWords() => delete(words).go();

  /// お気に入りフラグの更新
  Future<void> toggleFavorite(int id, bool isFavorite) {
    return (update(words)..where((t) => t.id.equals(id))).write(
      WordsCompanion(isFavorite: Value(isFavorite)),
    );
  }

  /// クイズ回答結果に基づく定着度・フラグ・正誤カウント更新 (F-05)
  Future<void> updateWordQuizResult({
    required int id,
    required double dropProgress,
    required bool isCorrect,
  }) async {
    final word = await (select(
      words,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (word == null) return;

    final eval = RetentionService.calculateScoreAndRetention(
      dropProgress: dropProgress,
      isCorrect: isCorrect,
    );

    final result = RetentionService.processQuizResult(
      currentPoint: word.retentionPoint,
      delta: eval['retentionDelta'] as int,
      isRestricted: word.isRestricted,
      setDailyLimit: eval['setDailyLimit'] as bool,
    );

    final now = DateTime.now();

    await (update(words)..where((t) => t.id.equals(id))).write(
      WordsCompanion(
        retentionPoint: Value(result['retentionPoint'] as int),
        isMemorized: Value(result['isMemorized'] as bool),
        isRestricted: Value(result['isRestricted'] as bool),
        correctCount: Value(
          isCorrect ? word.correctCount + 1 : word.correctCount,
        ),
        wrongCount: Value(!isCorrect ? word.wrongCount + 1 : word.wrongCount),
        lastStudiedAt: Value(now),
        lastRestrictedDate: (eval['setDailyLimit'] as bool)
            ? Value(now)
            : Value(word.lastRestrictedDate),
      ),
    );
  }

  /// 手動チェック / 右スワイプ: 暗記済み(80pt)化 (F-08)
  Future<void> markAsMemorizedManual(int id) {
    return (update(words)..where((t) => t.id.equals(id))).write(
      WordsCompanion(
        retentionPoint: const Value(80),
        isMemorized: const Value(true),
        lastStudiedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 左スワイプ: 0ptリセット ＋ 制限フラグ付与 (F-08)
  Future<void> resetRetentionManual(int id) {
    final now = DateTime.now();
    return (update(words)..where((t) => t.id.equals(id))).write(
      WordsCompanion(
        retentionPoint: const Value(0),
        isMemorized: const Value(false),
        isRestricted: const Value(true),
        lastStudiedAt: Value(now),
        lastRestrictedDate: Value(now),
      ),
    );
  }

  /// 暗記フラグ一括更新（メンテ）: 80pt未満に落ちた単語のisMemorizedを解除 (F-09)
  Future<int> syncMemorizedFlags() async {
    final all = await select(words).get();
    int count = 0;

    for (final word in all) {
      if (word.isMemorized && word.retentionPoint < 80) {
        await (update(words)..where((t) => t.id.equals(word.id))).write(
          const WordsCompanion(isMemorized: Value(false)),
        );
        count++;
      }
    }
    return count;
  }

  /// 日付跨ぎ制限フラグの自動解除チェック (0:00超過)
  Future<void> checkAndResetRestrictions() async {
    final restrictedWords = await (select(
      words,
    )..where((t) => t.isRestricted.equals(true))).get();
    final now = DateTime.now();

    for (final word in restrictedWords) {
      if (RetentionService.shouldResetRestriction(
        word.lastRestrictedDate,
        now: now,
      )) {
        await (update(words)..where((t) => t.id.equals(word.id))).write(
          const WordsCompanion(
            isRestricted: Value(false),
            lastRestrictedDate: Value(null),
          ),
        );
      }
    }
  }

  // --- プレイ履歴操作 ---

  /// ゲーム履歴の追加
  Future<int> addGameHistory(int score, int level) {
    return into(learningHistory)
        .insert(LearningHistoryCompanion.insert(score: score, level: level));
  }

  /// 履歴一覧の取得（降順）
  Future<List<LearningHistoryData>> getGameHistories() {
    return (select(learningHistory)..orderBy([
          (t) => OrderingTerm(expression: t.playedAt, mode: OrderingMode.desc),
        ]))
        .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
