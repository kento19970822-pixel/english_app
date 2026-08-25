// コード管理番号: VER-20260825-05
import 'package:drift/drift.dart';

// テーブル定義ファイルの読み込み
import 'tables/words.dart';
import 'tables/learning_history.dart';
import 'tables/daily_records.dart';
import 'tables/stamps.dart';
import 'tables/chapter_progress.dart';
import '../services/retention_service.dart';
import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

@DriftDatabase(tables: [Words, LearningHistory, DailyRecords, Stamps, ChapterProgresses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      for (final table in allTables) {
        await m.deleteTable(table.actualTableName);
        await m.createTable(table);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
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
  /// 単語データの括挿入（CSV取り込み用）
  Future<void> insertRawWords(List<Map<String, String>> rawWords) async {
    final List<Map<String, dynamic>> processedList = [];

    for (var i = 0; i < rawWords.length; i++) {
      final row = rawWords[i];
      final english = (row['word'] ?? row['english'] ?? '').trim();
      final japanese = (row['Japanese'] ?? row['japanese'] ?? '').trim();
      if (english.isEmpty || japanese.isEmpty) continue; // 空データは除外
      final cefr = row['CEFR'] ?? row['cefr'] ?? 'A1';
      final phonetic = row['Phonetic'] ?? row['phonetic'];
      final category = row['Category'] ?? row['category'] ?? 'General';
      final example = row['Example'] ?? row['example'];
      final exampleJp = row['Example_JP'] ?? row['Example_Jp'] ?? row['example_jp'] ?? row['exampleJp'];
      final level = _cefrToLevel(cefr);

      processedList.add({
        'originalIndex': i,
        'english': english,
        'japanese': japanese,
        'cefr': cefr,
        'level': level,
        'phonetic': phonetic,
        'category': category,
        'example': example,
        'exampleJp': exampleJp,
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
        final categoryStr = item['category']?.toString() ?? 'General';
        final exampleStr = item['example']?.toString();
        final exampleJpStr = item['exampleJp']?.toString();

        batch.insert(
          words,
          WordsCompanion.insert(
            english: englishStr,
            japanese: japaneseStr,
            cefr: Value(cefrStr),
            level: Value(level),
            chapter: Value(globalChapter),
            phonetic: Value(phoneticStr),
            category: Value(categoryStr),
            example: Value(exampleStr),
            exampleJp: Value(exampleJpStr),
          ),
        );
      }
    });

    // チャプター進行状況テーブルも再生成
    await delete(chapterProgresses).go();
    await initChapterProgresses();
  }

  /// 全単語データの削除
  Future<void> clearAllWords() async {
    await delete(words).go();
    await delete(chapterProgresses).go();
  }

  /// お気に入りフラグの更新
  Future<void> toggleFavorite(int id, bool isFavorite) {
    return (update(words)..where((t) => t.id.equals(id))).write(
      WordsCompanion(isFavorite: Value(isFavorite)),
    );
  }

  /// クイズ回答結果に基づく定着度・フラグ・正誤カウント更新 (F-05/F-10)
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
    final wasMemorized = word.isMemorized;
    final isNowMemorized = result['isMemorized'] as bool;

    await (update(words)..where((t) => t.id.equals(id))).write(
      WordsCompanion(
        retentionPoint: Value(result['retentionPoint'] as int),
        isMemorized: Value(isNowMemorized),
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

    // 新しく暗記済み（80pt以上）になった場合は日別暗記数をインクリメント (F-10)
    if (!wasMemorized && isNowMemorized) {
      await incrementDailyMemorizedCount();
    }
  }

  /// 手動チェック / 右スワイプ: 暗記済み(80pt)化 (F-08/F-10)
  Future<void> markAsMemorizedManual(int id) async {
    final word = await (select(
      words,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    final wasMemorized = word?.isMemorized ?? false;

    await (update(words)..where((t) => t.id.equals(id))).write(
      WordsCompanion(
        retentionPoint: const Value(80),
        isMemorized: const Value(true),
        lastStudiedAt: Value(DateTime.now()),
      ),
    );

    if (!wasMemorized) {
      await incrementDailyMemorizedCount();
    }
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

  // --- プレイ履歴 & 日別記録 (F-10) ---

  /// 今日の日付文字列を取得 (YYYY-MM-DD)
  String _getTodayStr() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// 今日の日別記録を取得または初期生成
  Future<DailyRecord> getOrCreateTodayRecord() async {
    return getDailyRecord(_getTodayStr());
  }

  /// 指定日の日別記録を取得または初期生成
  Future<DailyRecord> getDailyRecord(String dateStr) async {
    final existing = await (select(
      dailyRecords,
    )..where((t) => t.dateStr.equals(dateStr))).getSingleOrNull();

    if (existing != null) {
      return existing;
    } else {
      await into(dailyRecords)
          .insert(DailyRecordsCompanion.insert(dateStr: dateStr));
      return (select(
        dailyRecords,
      )..where((t) => t.dateStr.equals(dateStr))).getSingle();
    }
  }

  /// 本日の新規暗記数を+1インクリメント
  Future<void> incrementDailyMemorizedCount() async {
    final today = _getTodayStr();
    final record = await getOrCreateTodayRecord();
    await (update(dailyRecords)..where((t) => t.dateStr.equals(today))).write(
      DailyRecordsCompanion(memorizedCount: Value(record.memorizedCount + 1)),
    );
  }

  /// 本日のプレイ回数を+1インクリメント
  Future<void> incrementDailyPlayedCount() async {
    final today = _getTodayStr();
    final record = await getOrCreateTodayRecord();
    await (update(dailyRecords)..where((t) => t.dateStr.equals(today))).write(
      DailyRecordsCompanion(playedCount: Value(record.playedCount + 1)),
    );
  }

  /// 指定年月の全日別記録を取得
  Future<List<DailyRecord>> getDailyRecordsByMonth(int year, int month) async {
    final monthStr = "$year-${month.toString().padLeft(2, '0')}";
    return (select(
      dailyRecords,
    )..where((t) => t.dateStr.like('$monthStr%'))).get();
  }

  /// 連続プレイ日数（ストリーク）の算出
  Future<int> calculateStreak() async {
    final allRecords =
        await (select(dailyRecords)..orderBy([
              (t) =>
                  OrderingTerm(expression: t.dateStr, mode: OrderingMode.desc),
            ]))
            .get();

    if (allRecords.isEmpty) return 0;

    final now = DateTime.now();
    final todayStr = _getTodayStr();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr =
        "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    int streak = 0;
    DateTime checkDate = now;

    // 今日プレイ・暗記しているか確認
    final hasTodayActivity = allRecords.any(
      (r) =>
          r.dateStr == todayStr && (r.playedCount > 0 || r.memorizedCount > 0),
    );
    final hasYesterdayActivity = allRecords.any(
      (r) =>
          r.dateStr == yesterdayStr &&
          (r.playedCount > 0 || r.memorizedCount > 0),
    );

    if (!hasTodayActivity && !hasYesterdayActivity) {
      return 0; // 今日も昨日も学習していなければストリーク切れ
    }

    if (!hasTodayActivity) {
      checkDate = yesterday; // 今日未完了だが昨日完了している場合は昨日から遡って計算
    }

    while (true) {
      final dateStr =
          "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
      final record = allRecords.firstWhere(
        (r) => r.dateStr == dateStr,
        orElse: () =>
            const DailyRecord(dateStr: '', memorizedCount: 0, playedCount: 0),
      );

      if (record.dateStr.isNotEmpty &&
          (record.playedCount > 0 || record.memorizedCount > 0)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// ゲーム履歴の追加 ＆ 日別プレイ回数加算
  Future<int> addGameHistory(int score, int level) async {
    await incrementDailyPlayedCount();
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

  // --- チャプター進行状況 & 解放制御 (F-15) ---

  /// チャプター進行状況テーブルの初期化（単語データに基づいて作成）
  Future<void> initChapterProgresses() async {
    final existing = await select(chapterProgresses).get();
    if (existing.isNotEmpty) return;

    final allWordsList = await select(words).get();
    if (allWordsList.isEmpty) return;

    // チャプターごとのレベルと単語情報を集計
    final Map<int, int> chapterLevelMap = {};
    for (final w in allWordsList) {
      chapterLevelMap.putIfAbsent(w.chapter, () => w.level);
    }

    final sortedChapters = chapterLevelMap.keys.toList()..sort();
    if (sortedChapters.isEmpty) return;

    await batch((batch) {
      for (final ch in sortedChapters) {
        final lvl = chapterLevelMap[ch]!;
        // 初期状態: 通しチャプター1、または各難易度系列の最初のチャプターを解放
        final isFirstOfAnyLevel = (ch == 1);

        batch.insert(
          chapterProgresses,
          ChapterProgressesCompanion.insert(
            chapter: Value(ch),
            level: Value(lvl),
            isUnlocked: Value(isFirstOfAnyLevel),
            isCleared: const Value(false),
            memorizedRate: const Value(0.0),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// 全チャプターの進行状況を取得
  Future<List<ChapterProgressesData>> getAllChapterProgresses() async {
    await initChapterProgresses();
    return (select(chapterProgresses)..orderBy([
          (t) => OrderingTerm(expression: t.chapter, mode: OrderingMode.asc),
        ]))
        .get();
  }

  /// 指定難易度レベルに属するチャプター進行状況一覧を取得
  Future<List<ChapterProgressesData>> getChapterProgressesForLevel(int level) async {
    await initChapterProgresses();
    return (select(chapterProgresses)
          ..where((t) => t.level.equals(level))
          ..orderBy([
            (t) => OrderingTerm(expression: t.chapter, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// 指定難易度レベルで選択可能な最新チャプター番号を取得（初期表示用）
  Future<int> getLatestUnlockedChapterForLevel(int level) async {
    await initChapterProgresses();
    final list = await (select(chapterProgresses)
          ..where((t) => t.level.equals(level) & t.isUnlocked.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.chapter, mode: OrderingMode.desc),
          ]))
        .get();

    if (list.isNotEmpty) {
      return list.first.chapter;
    }
    // 解放されているものがない場合、そのレベルの最小チャプターまたは1
    final anyChapter = await (select(chapterProgresses)
          ..where((t) => t.level.equals(level))
          ..orderBy([
            (t) => OrderingTerm(expression: t.chapter, mode: OrderingMode.asc),
          ]))
        .get();
    return anyChapter.isNotEmpty ? anyChapter.first.chapter : 1;
  }

  /// チャプター内の70pt以上単語達成率（0.0〜100.0%）を計算 (F-15: クリア判定基準)
  Future<double> calculateChapterMemorizedRate(int chapter) async {
    final wordsInChapter = await (select(words)
          ..where((t) => t.chapter.equals(chapter)))
        .get();
    if (wordsInChapter.isEmpty) return 0.0;

    final targetCount = wordsInChapter.where((w) => w.retentionPoint >= 70).length;
    return (targetCount / wordsInChapter.length) * 100.0;
  }

  /// 【学習モードクリア時】70pt以上の単語が90%以上の場合にクリア判定・次チャプター解放 (F-15)
  Future<Map<String, dynamic>> checkAndUnlockNextChapter(int currentChapter) async {
    final rate = await calculateChapterMemorizedRate(currentChapter);
    final isCleared = rate >= 90.0; // 70pt以上が90%以上（100単語中90単語以上）

    // 現在のチャプター進捗を更新
    final currentProgress = await (select(chapterProgresses)
          ..where((t) => t.chapter.equals(currentChapter)))
        .getSingleOrNull();

    await (update(chapterProgresses)..where((t) => t.chapter.equals(currentChapter))).write(
      ChapterProgressesCompanion(
        memorizedRate: Value(rate),
        isCleared: Value(isCleared || (currentProgress?.isCleared ?? false)),
        clearedAt: isCleared ? Value(DateTime.now()) : const Value.absent(),
      ),
    );

    int? nextUnlockedChapter;
    bool isNewUnlock = false;

    if (isCleared) {
      final nextChapterNum = currentChapter + 1;
      final nextProgress = await (select(chapterProgresses)
            ..where((t) => t.chapter.equals(nextChapterNum)))
          .getSingleOrNull();

      if (nextProgress != null) {
        if (!nextProgress.isUnlocked) {
          isNewUnlock = true;
          await (update(chapterProgresses)..where((t) => t.chapter.equals(nextChapterNum))).write(
            const ChapterProgressesCompanion(
              isUnlocked: Value(true),
            ),
          );
        }
        nextUnlockedChapter = nextChapterNum;
      }
    }

    return {
      'isCleared': isCleared,
      'memorizedRate': rate,
      'nextChapterUnlocked': nextUnlockedChapter,
      'isNewUnlock': isNewUnlock,
    };
  }

  // --- スタンプ機能 (F-11 / F-12) ---

  /// 全スタンプを取得（Phase昇順、ID昇順）
  Future<List<Stamp>> getAllStamps() {
    return (select(stamps)..orderBy([
          (t) => OrderingTerm(expression: t.phase, mode: OrderingMode.asc),
          (t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc),
        ]))
        .get();
  }

  /// 指定Phaseのスタンプ一覧を取得
  Future<List<Stamp>> getStampsByPhase(int phase) {
    return (select(stamps)
          ..where((t) => t.phase.equals(phase))
          ..orderBy([
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// 現在登録されている最大Phase番号を取得
  Future<int> getMaxStampPhase() async {
    final all = await select(stamps).get();
    if (all.isEmpty) return 0;
    int maxP = 1;
    for (final s in all) {
      if (s.phase > maxP) maxP = s.phase;
    }
    return maxP;
  }

  /// スタンプの一括挿入（新規生成用）
  Future<void> insertStamps(List<StampsCompanion> stampList) async {
    await batch((batch) {
      batch.insertAll(stamps, stampList, mode: InsertMode.insertOrReplace);
    });
  }

  /// スタンプを獲得（ロック解除）
  Future<void> unlockStamp(String stampId, DateTime unlockedAt) async {
    await (update(stamps)..where((t) => t.id.equals(stampId))).write(
      StampsCompanion(
        isUnlocked: const Value(true),
        unlockedAt: Value(unlockedAt),
      ),
    );
  }

  /// お気に入りスタンプを設定（他をfalseにし、指定のスタンプのみtrue）
  Future<void> setFavoriteStamp(String stampId) async {
    await transaction(() async {
      await update(stamps).write(
        const StampsCompanion(isFavorite: Value(false)),
      );
      await (update(stamps)..where((t) => t.id.equals(stampId))).write(
        const StampsCompanion(isFavorite: Value(true)),
      );
    });
  }

  /// お気に入り設定されているスタンプを取得 (未設定または未解放の場合はnull)
  Future<Stamp?> getFavoriteStamp() async {
    return (select(stamps)..where((t) => t.isFavorite.equals(true) & t.isUnlocked.equals(true))).getSingleOrNull();
  }

  /// 日別記録に獲得スタンプIDを設定
  Future<void> setDailyAppliedStamp(String dateStr, String stampId) async {
    await (update(dailyRecords)..where((t) => t.dateStr.equals(dateStr))).write(
      DailyRecordsCompanion(
        appliedStampId: Value(stampId),
      ),
    );
  }

  /// 全学習記録・進捗・スタンプのリセット（初期化）
  Future<void> resetAllLearningData() async {
    await transaction(() async {
      await delete(learningHistory).go();
      await delete(dailyRecords).go();
      await update(words).write(
        const WordsCompanion(
          retentionPoint: Value(0),
          isMemorized: Value(false),
          isRestricted: Value(false),
          correctCount: Value(0),
          wrongCount: Value(0),
          lastStudiedAt: Value(null),
          lastRestrictedDate: Value(null),
        ),
      );
      await delete(stamps).go();
      await delete(chapterProgresses).go();
      await initChapterProgresses();
    });
  }
}
