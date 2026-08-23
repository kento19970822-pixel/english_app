// コード管理番号: VER-20260818-15
import 'package:drift/drift.dart';

/// 単語マスターテーブル (F-05/F-08拡張版)
class Words extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get english => text()();
  TextColumn get japanese => text()();
  TextColumn get cefr => text().withDefault(const Constant('A1'))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get chapter => integer().withDefault(const Constant(1))();
  TextColumn get phonetic => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  // F-05 / F-08用拡張カラム
  IntColumn get retentionPoint => integer().withDefault(const Constant(0))();
  BoolColumn get isMemorized => boolean().withDefault(const Constant(false))();
  BoolColumn get isRestricted => boolean().withDefault(const Constant(false))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get wrongCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastStudiedAt => dateTime().nullable()();
  DateTimeColumn get lastRestrictedDate => dateTime().nullable()();
}
