// コード管理番号: VER-20260817-15
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

  // スキーマ不整合を防止するマイグレーション設定
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      for (final table in allTables) {
        await m.deleteTable(table.actualTableName);
        await m.createTable(table);
      }
    },
  );

  // --- CEFR文字列を数値レベルに変換するヘルパー関数 ---
  int _cefrToLevel(String cefr) {
    switch (cefr.toUpperCase().trim()) {
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
  /// CEFRからレベルを自動変換し、100語ごとに章（chapter）を自動発番します。
  Future<void> insertRawWords(List<Map<String, String>> rawWords) async {
    // 1. データの整形とソート（CEFR順 -> 元の並び順）
    final processedList = rawWords.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;

      // CSVのヘッダー表記揺れ（小文字・大文字）に対応
      final english = row['word'] ?? row['english'] ?? '';
      final japanese = row['Japanese'] ?? row['japanese'] ?? '';
      final cefr = row['CEFR'] ?? row['cefr'] ?? 'A1';
      final phonetic = row['Phonetic'] ?? row['phonetic'];
      final level = _cefrToLevel(cefr);

      return {
        'originalIndex': index,
        'english': english,
        'japanese': japanese,
        'cefr': cefr,
        'level': level,
        'phonetic': phonetic,
      };
    }).toList();

    // CEFR（レベル順） -> 元のインデックス順にソート
    processedList.sort((a, b) {
      final levelCompare = (a['level'] as int).compareTo(b['level'] as int);
      if (levelCompare != 0) return levelCompare;
      return (a['originalIndex'] as int).compareTo(b['originalIndex'] as int);
    });

    // 2. レベルごとに100語ずつチャプターを計算してDB登録
    final Map<int, int> levelWordCounts = {};

    await batch((batch) {
      for (final item in processedList) {
        final level = item['level'] as int;
        final currentCount = levelWordCounts[level] ?? 0;

        // 100語ごとに 1, 2, 3... と章番号を計算
        final chapter = (currentCount / 100).floor() + 1;
        levelWordCounts[level] = currentCount + 1;

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
            chapter: Value(chapter),
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
