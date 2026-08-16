// コード管理番号: VER-20260817-117
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// 単語テーブル定義
class Words extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get english => text()();
  TextColumn get japanese => text()();
  TextColumn get cefr => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
}

// ゲーム履歴テーブル定義
class GameHistories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get score => integer()();
  IntColumn get level => integer()();
  DateTimeColumn get playedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Words, GameHistories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  // ぐるぐる（スキーマ不整合）を防止するマイグレーション設定
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      for (final table in allTables) {
        await m.deleteTable(table.actualTableName);
        await m.createTable(table);
      }
    },
  );

  // --- データベース操作メソッド ---

  Future<List<Word>> getAllWords() => select(words).get();

  Future<void> insertRawWords(List<Map<String, String>> rawWords) async {
    await batch((batch) {
      batch.insertAll(
        words,
        rawWords.map(
          (row) => WordsCompanion.insert(
            english: row['english'] ?? '',
            japanese: row['japanese'] ?? '',
            cefr: row['cefr'] ?? 'A1',
          ),
        ),
      );
    });
  }

  Future<void> clearAllWords() => delete(words).go();

  Future<void> toggleFavorite(int id, bool isFavorite) {
    return (update(words)..where((t) => t.id.equals(id))).write(
      WordsCompanion(isFavorite: Value(isFavorite)),
    );
  }

  // ⚠️ このメソッドがなかったためエラーになっていました
  Future<int> addGameHistory(int score, int level) {
    return into(gameHistories)
        .insert(GameHistoriesCompanion.insert(score: score, level: level));
  }

  Future<List<GameHistory>> getGameHistories() {
    return (select(gameHistories)..orderBy([
          (t) => OrderingTerm(expression: t.playedAt, mode: OrderingMode.desc),
        ]))
        .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
