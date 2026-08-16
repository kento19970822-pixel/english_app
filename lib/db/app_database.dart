// コード管理番号: VER-20260816-91
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class Words extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get english => text()();
  TextColumn get japanese => text()();
  TextColumn get cefr => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Words])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // 全単語の取得
  Future<List<Word>> getAllWords() => select(words).get();

  // 単語テーブルの全クリア（DB再構築用）
  Future<void> clearAllWords() async {
    await delete(words).go();
  }

  // 大量データのインポート（全削除後の挿入）
  Future<void> insertRawWords(List<Map<String, String>> rawWords) async {
    await batch((batch) {
      for (var raw in rawWords) {
        batch.insert(
          words,
          WordsCompanion.insert(
            english: raw['english'] ?? '',
            japanese: raw['japanese'] ?? '',
            cefr: raw['cefr'] ?? 'A1',
          ),
        );
      }
    });
  }

  // お気に入り切り替え
  Future<void> toggleFavorite(int id, bool isFav) async {
    await (update(words)..where((tbl) => tbl.id.equals(id))).write(
      WordsCompanion(isFavorite: Value(isFav)),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app_db.sqlite'));
    return NativeDatabase(file);
  });
}
