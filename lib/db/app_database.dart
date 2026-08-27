import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
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
  int get schemaVersion => 11;

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
      await customStatement('CREATE INDEX IF NOT EXISTS idx_words_chapter ON words (chapter);');
      await customStatement('CREATE INDEX IF NOT EXISTS idx_words_cefr ON words (cefr);');
      await customStatement('CREATE INDEX IF NOT EXISTS idx_words_english ON words (english);');
      await customStatement('CREATE INDEX IF NOT EXISTS idx_words_memorized ON words (is_memorized);');
      await customStatement('CREATE INDEX IF NOT EXISTS idx_words_favorite ON words (is_favorite);');
      await customStatement('CREATE INDEX IF NOT EXISTS idx_words_restricted ON words (is_restricted);');
    },
  );

  /// CEFR文字列を数値レベルに変換するヘルパー関数
  int _cefrToLevel(String cefr) {
    final clean = cefr.toUpperCase().trim();
    if (clean.contains('A1') || clean.contains('A2') || clean == '1' || clean.contains('初級')) {
      return 1;
    }
    if (clean.contains('B1') || clean.contains('B2') || clean == '2' || clean.contains('中級')) {
      return 2;
    }
    if (clean.contains('C1') || clean.contains('C2') || clean == '3' || clean.contains('上級')) {
      return 3;
    }
    return 1;
  }

  /// 品詞文字列表記を日本語1文字バッジに正規化するヘルパー関数
  static String toShortJapanesePos(String pos, {String fallbackJp = ''}) {
    final clean = pos.trim().toLowerCase();
    if (clean == 'verb' || clean == '動' || clean == '動詞') return '動';
    if (clean == 'noun' || clean == '名' || clean == '名詞') return '名';
    if (clean == 'adjective' || clean == '形' || clean == '形容詞') return '形';
    if (clean == 'adverb' || clean == '副' || clean == '副詞') return '副';
    if (clean == 'preposition' || clean == '前' || clean == '前置詞') return '前';
    if (clean == 'conjunction' || clean == '接' || clean == '接続詞') return '接';
    if (clean == 'pronoun' || clean == '代' || clean == '代名詞') return '代';
    if (clean == 'auxiliary' || clean == '助' || clean == '助動詞') return '助';
    if (clean == 'phrase' || clean == 'idiom' || clean == '熟' || clean == '熟語') return '熟';
    if (fallbackJp.isNotEmpty) {
      return detectPartOfSpeech(fallbackJp);
    }
    return '名';
  }

  /// 品詞文字列表記を日本語フル表記（名詞/動詞等）に正規化するヘルパー関数
  static String toFullJapanesePos(String pos, {String fallbackJp = ''}) {
    final clean = pos.trim().toLowerCase();
    if (clean == 'verb' || clean == '動' || clean == '動詞') return '動詞';
    if (clean == 'noun' || clean == '名' || clean == '名詞') return '名詞';
    if (clean == 'adjective' || clean == '形' || clean == '形容詞') return '形容詞';
    if (clean == 'adverb' || clean == '副' || clean == '副詞') return '副詞';
    if (clean == 'preposition' || clean == '前' || clean == '前置詞') return '前置詞';
    if (clean == 'conjunction' || clean == '接' || clean == '接続詞') return '接続詞';
    if (clean == 'pronoun' || clean == '代' || clean == '代名詞') return '代名詞';
    if (clean == 'auxiliary' || clean == '助' || clean == '助動詞') return '助動詞';
    if (clean == 'phrase' || clean == 'idiom' || clean == '熟' || clean == '熟語') return '熟語';
    if (clean == 'interjection' || clean == '間' || clean == '間投詞') return '間投詞';
    if (fallbackJp.isNotEmpty) {
      final short = detectPartOfSpeech(fallbackJp);
      return toFullJapanesePos(short);
    }
    return '名詞';
  }

  /// 日本語訳から簡易品詞タグを判定するヘルパー関数
  static String detectPartOfSpeech(String jp) {
    final cleanJp = jp.trim();
    if (cleanJp.startsWith('〜の') ||
        cleanJp.startsWith('〜へ') ||
        cleanJp.startsWith('〜で') ||
        cleanJp.startsWith('〜に') ||
        cleanJp.startsWith('〜から') ||
        cleanJp.startsWith('〜まで') ||
        cleanJp.startsWith('〜について')) {
      return '前';
    }
    if (cleanJp == 'しかし' ||
        cleanJp == 'そして' ||
        cleanJp.contains('だから') ||
        cleanJp.contains('または')) {
      return '接';
    }
    if (cleanJp.contains('〜する') ||
        cleanJp.endsWith('する') ||
        cleanJp.endsWith('させる') ||
        cleanJp.endsWith('できる') ||
        cleanJp.endsWith('ている') ||
        cleanJp.endsWith('てある') ||
        cleanJp.endsWith('行う') ||
        cleanJp.endsWith('なる') ||
        cleanJp.endsWith('行く') ||
        cleanJp.endsWith('書く') ||
        cleanJp.endsWith('歩く') ||
        cleanJp.endsWith('働く') ||
        cleanJp.endsWith('聞く') ||
        cleanJp.endsWith('見る') ||
        cleanJp.endsWith('食べる') ||
        cleanJp.endsWith('知る') ||
        cleanJp.endsWith('作る') ||
        cleanJp.endsWith('得る') ||
        cleanJp.endsWith('走る') ||
        cleanJp.endsWith('持つ') ||
        cleanJp.endsWith('話す') ||
        cleanJp.endsWith('言う')) {
      return '動';
    }
    if (cleanJp.endsWith('い') ||
        cleanJp.endsWith('な') ||
        cleanJp.endsWith('的') ||
        cleanJp.endsWith('の') ||
        cleanJp.contains('〜のような') ||
        cleanJp.contains('〜らしい')) {
      return '形';
    }
    if (cleanJp.endsWith('に') ||
        cleanJp.endsWith('く') ||
        cleanJp.contains('また') ||
        cleanJp.contains('もっと') ||
        cleanJp.contains('いつも')) {
      return '副';
    }
    return '名';
  }

  // --- 単語データ操作 ---

  /// 全単語の取得
  Future<List<Word>> getAllWords() async {
    return select(words).get();
  }

  /// 指定レベルの単語一覧を取得
  Future<List<Word>> getWordsByLevel(int level) async {
    return (select(words)..where((t) => t.level.equals(level))).get();
  }

  /// 複数レベルの単語一覧を取得
  Future<List<Word>> getWordsByLevels(List<int> levels) async {
    return (select(words)..where((t) => t.level.isIn(levels))).get();
  }

  /// 指定チャプターの単語一覧を取得
  Future<List<Word>> getWordsByChapter(int chapter) async {
    return (select(words)..where((t) => t.chapter.equals(chapter))).get();
  }

  /// 【1日1回処理】忘却曲線による定着度ポイント減算 ＆ 減算累計加算 ＆ 制限フラグ一括解除 (F-05)
  /// ※is_memorized フラグは自動では外さず手動更新用に保持する
  Future<int> syncDailyForgettingAndRestrictions() async {
    final now = DateTime.now();
    // 変更対象となり得るのは「過去に学習履歴がある単語」または「現在制限中の単語」のみ（3.1万件全取得を回避）
    final candidates = await (select(words)
          ..where((t) => t.lastStudiedAt.isNotNull() | t.isRestricted.equals(true)))
        .get();
    if (candidates.isEmpty) return 0;

    final List<Map<String, dynamic>> updates = [];

    for (final word in candidates) {
      bool needUpdate = false;
      int newPoint = word.retentionPoint;
      int newPointDecreasedTotal = word.pointDecreasedTotal;
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
          final diff = word.retentionPoint - newPoint;
          if (diff > 0) {
            newPointDecreasedTotal += diff;
          }
          needUpdate = true;
        }
      }

      // 2. 日付跨ぎ制限フラグの解除 (0:00超過)
      if (word.isRestricted) {
        newIsRestricted = false;
        newLastRestrictedDate = null;
        needUpdate = true;
      }

      if (needUpdate) {
        updates.add({
          'id': word.id,
          'point': newPoint,
          'decreasedTotal': newPointDecreasedTotal,
          'restricted': newIsRestricted,
          'date': newLastRestrictedDate,
        });
      }
    }

    if (updates.isEmpty) return 0;

    // バッチトランザクションで一括更新
    await batch((batch) {
      for (final item in updates) {
        batch.update(
          words,
          WordsCompanion(
            retentionPoint: Value(item['point'] as int),
            pointDecreasedTotal: Value(item['decreasedTotal'] as int),
            isRestricted: Value(item['restricted'] as bool),
            lastRestrictedDate: Value(item['date'] as DateTime?),
          ),
          where: (t) => t.id.equals(item['id'] as int),
        );
      }
    });

    return updates.length;
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
      final partOfSpeech = row['partOfSpeech'] ?? row['part_of_speech'] ?? row['PartOfSpeech'];
      final collocations = row['collocations'] ?? row['Collocations'];
      final otherMeanings = row['otherMeanings'] ?? row['other_meanings'] ?? row['OtherMeanings'];
      final baseForm = row['baseForm'] ?? row['base_form'] ?? row['BaseForm'];
      final senseIndex = int.tryParse(row['senseIndex'] ?? row['sense_index'] ?? '1') ?? 1;
      final totalSenses = int.tryParse(row['totalSenses'] ?? row['total_senses'] ?? '1') ?? 1;
      final wordGroup = english.toLowerCase();
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
        'partOfSpeech': partOfSpeech,
        'collocations': collocations,
        'otherMeanings': otherMeanings,
        'baseForm': baseForm,
        'senseIndex': senseIndex,
        'totalSenses': totalSenses,
        'wordGroup': wordGroup,
      });
    }

    const cefrRank = {'A1': 0, 'A2': 1, 'B1': 2, 'B2': 3, 'C1': 4, 'C2': 5};
    processedList.sort((a, b) {
      final aCefr = a['cefr']?.toString().toUpperCase().trim() ?? 'A1';
      final bCefr = b['cefr']?.toString().toUpperCase().trim() ?? 'A1';
      final aRank = cefrRank[aCefr] ?? 99;
      final bRank = cefrRank[bCefr] ?? 99;
      if (aRank != bRank) return aRank.compareTo(bRank);
      return (a['originalIndex'] as int).compareTo(b['originalIndex'] as int);
    });

    int globalChapter = 1;
    String currentCefr = '';
    int cefrWordCount = 0;

    await batch((batch) {
      for (final item in processedList) {
        final cefrStr = item['cefr']?.toString().toUpperCase().trim() ?? 'A1';

        if (currentCefr.isEmpty) {
          currentCefr = cefrStr;
          cefrWordCount = 0;
        } else if (cefrStr != currentCefr) {
          if (cefrWordCount > 0) {
            globalChapter++;
          }
          currentCefr = cefrStr;
          cefrWordCount = 0;
        } else if (cefrWordCount > 0 && cefrWordCount % 100 == 0) {
          globalChapter++;
        }

        cefrWordCount++;

        final levelVal = item['level'] as int? ?? _cefrToLevel(cefrStr);
        final englishStr = item['english']?.toString() ?? '';
        final japaneseStr = item['japanese']?.toString() ?? '';
        final phoneticStr = item['phonetic']?.toString();
        final categoryStr = item['category']?.toString() ?? 'General';
        final exampleStr = item['example']?.toString();
        final exampleJpStr = item['exampleJp']?.toString();
        final rawPos = item['partOfSpeech']?.toString().trim();
        final posStr = (rawPos != null && rawPos.isNotEmpty) ? rawPos : detectPartOfSpeech(japaneseStr);
        final collocationsStr = item['collocations']?.toString();
        final baseFormStr = item['baseForm']?.toString();
        final senseIndexVal = item['senseIndex'] as int? ?? 1;
        final totalSensesVal = item['totalSenses'] as int? ?? 1;
        final wordGroupStr = item['wordGroup']?.toString();

        // 複数語義の構造化JSON（明示指定があれば優先、なければカンマ区切りから自動生成）
        String? otherMeaningsJson = item['otherMeanings']?.toString();
        if (otherMeaningsJson == null || otherMeaningsJson.trim().isEmpty) {
          final meanings = japaneseStr
              .split(RegExp(r'[、,]'))
              .map((m) => m.trim())
              .where((m) => m.isNotEmpty)
              .toList();
          if (meanings.length > 1) {
            final senses = meanings.asMap().entries.map((e) => {
                  'sense_id': e.key + 1,
                  'part_of_speech': detectPartOfSpeech(e.value),
                  'meaning_ja': e.value,
                  'cefr': cefrStr,
                  'example_en': e.key == 0 ? exampleStr : null,
                  'example_ja': e.key == 0 ? exampleJpStr : null,
                }).toList();
            otherMeaningsJson = jsonEncode(senses);
          }
        }

        batch.insert(
          words,
          WordsCompanion.insert(
            english: englishStr,
            japanese: japaneseStr,
            partOfSpeech: Value(posStr),
            cefr: Value(cefrStr),
            level: Value(levelVal),
            chapter: Value(globalChapter),
            phonetic: Value(phoneticStr),
            category: Value(categoryStr),
            example: Value(exampleStr),
            exampleJp: Value(exampleJpStr),
            collocations: Value(collocationsStr),
            otherMeanings: Value(otherMeaningsJson),
            baseForm: Value(baseFormStr),
            senseIndex: Value(senseIndexVal),
            totalSenses: Value(totalSensesVal),
            wordGroup: Value(wordGroupStr),
            pointDecreasedTotal: const Value(0),
          ),
        );
      }
    });

    // チャプター進行状況テーブルも再生成
    await delete(chapterProgresses).go();
    await initChapterProgresses();
  }

  /// 初回起動時またはテーブルが空の場合にCSVから単語データを自動シード
  Future<void> initWordsIfEmpty() async {
    final count = await (select(words)..limit(1)).get();
    if (count.isNotEmpty) return;

    try {
      final csvString = await rootBundle.loadString('assets/words.csv');
      final lines = csvString.split(RegExp(r'\r?\n'));
      if (lines.isEmpty) return;

      List<String> parseCsvLine(String line) {
        final List<String> result = [];
        final StringBuffer buffer = StringBuffer();
        bool insideQuotes = false;
        for (int i = 0; i < line.length; i++) {
          final char = line[i];
          if (char == '"') {
            if (insideQuotes && i + 1 < line.length && line[i + 1] == '"') {
              buffer.write('"');
              i++;
            } else {
              insideQuotes = !insideQuotes;
            }
          } else if (char == ',' && !insideQuotes) {
            result.add(buffer.toString().trim());
            buffer.clear();
          } else {
            buffer.write(char);
          }
        }
        result.add(buffer.toString().trim());
        return result;
      }

      final rawHeader = parseCsvLine(lines.first);
      final header = rawHeader.map((h) => h.replaceAll('"', '').trim()).toList();
      final List<Map<String, String>> rawData = [];

      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final values = parseCsvLine(line);
        if (values.length >= header.length) {
          final map = <String, String>{};
          for (var j = 0; j < header.length; j++) {
            map[header[j]] = values[j];
          }
          rawData.add(map);
        }
      }

      if (rawData.isNotEmpty) {
        await insertRawWords(rawData);
      }
    } catch (e) {
      debugPrint('initWordsIfEmpty error: $e');
    }
  }

  /// 同一英単語の全語義（他チャプター含む）を取得
  Future<List<Word>> getAllSensesForWord(String english) async {
    final clean = english.toLowerCase().trim();
    return (select(words)
          ..where((t) => t.english.equals(clean) | t.wordGroup.equals(clean))
          ..orderBy([(t) => OrderingTerm.asc(t.senseIndex)]))
        .get();
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
        pointDecreasedTotal: isCorrect
            ? const Value(0)
            : Value(word.pointDecreasedTotal),
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

  /// 手動チェック / 右スワイプ: 暗記済み(80pt)化 ＆ 制限解除 ＆ 減算リセット (F-08/F-10/F-14)
  Future<void> markAsMemorizedManual(int id) async {
    final word = await (select(
      words,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    final wasMemorized = word?.isMemorized ?? false;

    await (update(words)..where((t) => t.id.equals(id))).write(
      WordsCompanion(
        retentionPoint: const Value(80),
        pointDecreasedTotal: const Value(0),
        isMemorized: const Value(true),
        isRestricted: const Value(false),
        lastStudiedAt: Value(DateTime.now()),
      ),
    );

    if (!wasMemorized) {
      await incrementDailyMemorizedCount();
    }
  }

  /// 暗記フラグ一括リセット: 全単語の暗記フラグ・定着度・制限フラグを初期状態にリセット (F-09/F-15)
  Future<void> resetAllWordsMemorized() async {
    await update(words).write(
      const WordsCompanion(
        retentionPoint: Value(0),
        isMemorized: Value(false),
        isRestricted: Value(false),
      ),
    );

    // 全チャプター進捗の暗記達成率を0%に更新（Ch.1のみ解放、他は未解放に再設定）
    final allCp = await getAllChapterProgresses();
    for (final cp in allCp) {
      await (update(chapterProgresses)..where((t) => t.chapter.equals(cp.chapter))).write(
        ChapterProgressesCompanion(
          memorizedRate: const Value(0.0),
          isUnlocked: Value(cp.chapter == 1),
          isCleared: const Value(false),
        ),
      );
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

  /// 暗記フラグ再同期: 80pt未満に落ちた単語のisMemorizedを解除 ＆ チャプター進捗同期 (F-09)
  Future<int> syncMemorizedFlags() async {
    final all = await select(words).get();
    int count = 0;
    final Set<int> affectedChapters = {};

    for (final word in all) {
      if (word.isMemorized && word.retentionPoint < 80) {
        await (update(words)..where((t) => t.id.equals(word.id))).write(
          const WordsCompanion(isMemorized: Value(false)),
        );
        affectedChapters.add(word.chapter);
        count++;
      }
    }

    // 影響を受けたチャプターの進行状況（暗記率）を再計算
    for (final ch in affectedChapters) {
      final chWords = await (select(words)..where((t) => t.chapter.equals(ch))).get();
      if (chWords.isNotEmpty) {
        final memorizedInCh = chWords.where((w) => w.isMemorized).length;
        final rate = memorizedInCh / chWords.length;
        await (update(chapterProgresses)..where((t) => t.chapter.equals(ch))).write(
          ChapterProgressesCompanion(
            memorizedRate: Value(rate),
          ),
        );
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

  /// 累計学習日数（プレイまたは新規暗記を行ったユニーク日数）の算出 (F-15)
  Future<int> calculateTotalStudiedDays() async {
    final allRecords = await select(dailyRecords).get();
    return allRecords.where((r) => r.playedCount > 0 || r.memorizedCount > 0).length;
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

    // 各難易度グループ（初級: lvl 1 / 中級: lvl 2 / 上級: lvl 3）の先頭チャプターを特定
    int? firstOfLvl1;
    int? firstOfLvl2;
    int? firstOfLvl3;
    for (final ch in sortedChapters) {
      final lvl = chapterLevelMap[ch]!;
      if (lvl == 1) {
        firstOfLvl1 ??= ch;
      } else if (lvl == 2) {
        firstOfLvl2 ??= ch;
      } else if (lvl == 3) {
        firstOfLvl3 ??= ch;
      }
    }
    final initialUnlocked = {firstOfLvl1, firstOfLvl2, firstOfLvl3}.whereType<int>().toSet();

    await batch((batch) {
      for (final ch in sortedChapters) {
        final lvl = chapterLevelMap[ch]!;
        final isInitiallyUnlocked = initialUnlocked.contains(ch);

        batch.insert(
          chapterProgresses,
          ChapterProgressesCompanion.insert(
            chapter: Value(ch),
            level: Value(lvl),
            isUnlocked: Value(isInitiallyUnlocked),
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
    final list = await (select(chapterProgresses)..orderBy([
          (t) => OrderingTerm(expression: t.chapter, mode: OrderingMode.asc),
        ]))
        .get();

    // 既存DBでも各難易度グループの先頭チャプターが確実に解放されていることを保証
    final lvl1First = list.where((cp) => cp.level == 1).firstOrNull;
    final lvl2First = list.where((cp) => cp.level == 2).firstOrNull;
    final lvl3First = list.where((cp) => cp.level == 3).firstOrNull;

    bool needUpdate = false;
    for (final firstCp in [lvl1First, lvl2First, lvl3First]) {
      if (firstCp != null && !firstCp.isUnlocked) {
        await (update(chapterProgresses)..where((t) => t.chapter.equals(firstCp.chapter)))
            .write(const ChapterProgressesCompanion(isUnlocked: Value(true)));
        needUpdate = true;
      }
    }
    if (needUpdate) {
      return (select(chapterProgresses)..orderBy([
            (t) => OrderingTerm(expression: t.chapter, mode: OrderingMode.asc),
          ]))
          .get();
    }
    return list;
  }

  /// 弱点克服モード用: プレイ経験のある単語から誤答・低定着の単語を苦手度順に抽出
  Future<List<Word>> getWeaknessWords({int? level}) async {
    final all = await select(words).get();
    var filtered = all;
    if (level != null) {
      filtered = all.where((w) => w.level == level).toList();
    }

    // プレイ経験のある単語（回答回数 > 0 または 定着度変動あり）を抽出
    final played = (filtered.isNotEmpty ? filtered : all).where((w) {
      final totalAnswered = w.wrongCount + w.correctCount;
      return totalAnswered > 0 || w.retentionPoint > 0;
    }).toList();

    if (played.isEmpty) {
      return [];
    }

    // 弱点候補: 誤答経験あり(wrongCount > 0)、または未暗記/定着度80pt未満
    final weaknessCandidates = played.where((w) {
      return w.wrongCount > 0 || !w.isMemorized || w.retentionPoint < 80;
    }).toList();

    final targetPool = weaknessCandidates.isNotEmpty ? weaknessCandidates : played;

    final scored = targetPool.map((w) {
      int weaknessScore = (w.wrongCount * 3);
      if (!w.isMemorized) weaknessScore += 10;
      if (w.retentionPoint < 50) weaknessScore += 10;
      weaknessScore -= w.correctCount;
      return MapEntry(w, weaknessScore);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
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
