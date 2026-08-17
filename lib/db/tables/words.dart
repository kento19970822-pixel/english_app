// コード管理番号: VER-20260818-08
import 'package:drift/drift.dart';

/// 単語マスターテーブル
class Words extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get english => text()();
  TextColumn get japanese => text()();
  TextColumn get cefr => text().withDefault(const Constant('A1'))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get chapter => integer().withDefault(const Constant(1))();
  TextColumn get phonetic => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  // F-08用追加カラム
  IntColumn get retentionPoint => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastStudiedAt => dateTime().nullable()();
}
