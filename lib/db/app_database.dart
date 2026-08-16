// コード管理番号: VER-20260816-16
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/words.dart';
import 'tables/learning_history.dart';

part 'app_database.g.dart'; // build_runner実行後に生成されます

@DriftDatabase(tables: [Words, LearningHistories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // DBのマイグレーション・初期化戦略の設定
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // 1. テーブルの作成
        await m.createAll();

        // 2. 初期単語データ（Seed Data）の投入
        await batch((batch) {
          batch.insertAll(words, [
            WordsCompanion(
              id: const Value('1'),
              english: const Value('apple'),
              japanese: const Value('りんご'),
              level: const Value(1),
            ),
            WordsCompanion(
              id: const Value('2'),
              english: const Value('book'),
              japanese: const Value('本'),
              level: const Value(1),
            ),
            WordsCompanion(
              id: const Value('3'),
              english: const Value('challenge'),
              japanese: const Value('挑戦する'),
              level: const Value(2),
            ),
            WordsCompanion(
              id: const Value('4'),
              english: const Value('opportunity'),
              japanese: const Value('機会、チャンス'),
              level: const Value(2),
            ),
            WordsCompanion(
              id: const Value('5'),
              english: const Value('achieve'),
              japanese: const Value('達成する'),
              level: const Value(3),
            ),
          ]);
        });
      },
    );
  }

  // 全単語の取得
  Future<List<Word>> getAllWords() => select(words).get();

  // 難易度別の単語取得
  Future<List<Word>> getWordsByLevel(int level) {
    return (select(words)..where((tbl) => tbl.level.equals(level))).get();
  }

  // お気に入りの切り替え
  Future<void> toggleFavorite(String id, bool isFav) {
    return (update(words)..where((tbl) => tbl.id.equals(id))).write(
      WordsCompanion(isFavorite: Value(isFav)),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_words.db'));

    return NativeDatabase.createInBackground(file);
  });
}
