// コード管理番号: VER-20260816-29
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'tables/words.dart';
import 'tables/learning_history.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Words, LearningHistory])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // アプリ初回起動時に assets/words.csv から自動読み込み
        await _importCsvFromAssets();
      },
    );
  }

  // assets/words.csv を読み込んでDBに一括登録する内部メソッド
  Future<void> _importCsvFromAssets() async {
    try {
      final csvData = await rootBundle.loadString('assets/words.csv');
      final lines = const LineSplitter().convert(csvData);
      final List<WordsCompanion> companions = [];

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // ヘッダー行（english,japanese,level等）をスキップ
        if (i == 0 && line.toLowerCase().startsWith('english')) {
          continue;
        }

        final parts = line.split(',');
        if (parts.length >= 2) {
          final english = parts[0].trim();
          final japanese = parts[1].trim();
          int level = 1;

          if (parts.length >= 3) {
            level = int.tryParse(parts[2].trim()) ?? 1;
          }

          if (english.isNotEmpty && japanese.isNotEmpty) {
            companions.add(
              WordsCompanion.insert(
                id: const Uuid().v4(),
                english: english,
                japanese: japanese,
                level: Value(level),
              ),
            );
          }
        }
      }

      if (companions.isNotEmpty) {
        await batch((batch) {
          batch.insertAll(words, companions, mode: InsertMode.insertOrIgnore);
        });
      }
    } catch (e) {
      // ファイル読み込み失敗時のバックアップ初期データ
      final initialWords = [
        WordsCompanion.insert(
          id: const Uuid().v4(),
          english: 'apple',
          japanese: 'りんご',
          level: const Value(1),
        ),
        WordsCompanion.insert(
          id: const Uuid().v4(),
          english: 'book',
          japanese: '本',
          level: const Value(1),
        ),
      ];
      for (var word in initialWords) {
        await into(words).insert(word, mode: InsertMode.insertOrIgnore);
      }
    }
  }

  // 全単語の取得
  Future<List<Word>> getAllWords() => select(words).get();

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
    final file = File(p.join(dbFolder.path, 'app_database.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
