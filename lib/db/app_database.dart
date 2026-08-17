// コード管理番号: VER-20260817-06
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

  // --- 単語データ操作 ---

  /// 全単語の取得
  Future<List<Word>> getAllWords() => select(words).get();

  /// 単語データの括挿入（CSV取り込み用・レベルおよび章計算に対応）
  Future<void> insertRawWords(List<Map<String, String>> rawWords) async {
    await batch((batch) {
      batch.insertAll(
        words,
        rawWords.map((row) {
          final level = int.tryParse(row['level'] ?? '1') ?? 1;
          final chapter = int.tryParse(row['chapter'] ?? '1') ?? 1;
          return WordsCompanion.insert(
            english: row['english'] ?? '',
            japanese: row['japanese'] ?? '',
            cefr: Value(row['cefr'] ?? 'A1'),
            level: Value(level),
            chapter: Value(chapter),
            phonetic: Value(row['phonetic']), // 発音記号（Null許容）
          );
        }),
      );
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
  Future<int> addGameHistory(
    int score,
    int level, {
    String mode = 'challenge',
  }) {
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
