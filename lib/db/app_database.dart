// コード管理番号: VER-20260817-28
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

part 'app_database.g.dart';

@DriftDatabase(tables: [Words, LearningHistory, DailyRecords, Stamps])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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
  Future<List<Word>> getAllWords() => select(words).get();

  /// 単語データの括挿入（CSV取り込み用）
  /// チャプターは Level を横断して全体の通し番号（1, 2, 3, ...）で発番します。
  Future<void> insertRawWords(List<Map<String, String>> rawWords) async {
    // 1. データの整形
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

    // 2. レベル昇順（1➔2➔3➔4➔5➔6）➔ 元の出現順 で確実にソート
    processedList.sort((a, b) {
      final aLevel = a['level'] as int;
      final bLevel = b['level'] as int;
      if (aLevel != bLevel) return aLevel.compareTo(bLevel);
      return (a['originalIndex'] as int).compareTo(b['originalIndex'] as int);
    });

    // 3. 通しチャプター発番ロジック（※チャプター番号は全レベルを通して絶対に1へリセットしません）
    int globalChapter = 1; // 全体通しのチャプター番号
    int currentLevel = -1; // 現在処理中のレベル
    int levelWordCount = 0; // 現在のレベル内でのカウント

    await batch((batch) {
      for (final item in processedList) {
        final level = item['level'] as int;

        if (currentLevel == -1) {
          // 初回要素の設定
          currentLevel = level;
          levelWordCount = 0;
        } else if (level != currentLevel) {
          // レベルが切り替わった時：
          // 前レベルの末尾に単語が存在していれば、次のレベルは必ず「＋1したチャプター番号」から開始する
          if (levelWordCount > 0) {
            globalChapter++;
          }
          currentLevel = level;
          levelWordCount = 0;
        } else if (levelWordCount > 0 && levelWordCount % 100 == 0) {
          // 同一レベル内で 100 語に達した時：
          // チャプター番号を ＋1 進める
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
            chapter: Value(globalChapter), // 通し番号をセット
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
