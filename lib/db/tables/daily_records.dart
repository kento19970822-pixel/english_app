// コード管理番号: VER-20260817-03
import 'package:drift/drift.dart';

/// 日別学習 & ログイン記録テーブル
class DailyRecords extends Table {
  /// 日付文字列 (`YYYY-MM-DD` を主キーとする)
  TextColumn get dateStr => text()();

  /// その日に新しく暗記済みにした単語数
  IntColumn get memorizedCount => integer().withDefault(const Constant(0))();

  /// その日のゲームプレイ回数
  IntColumn get playedCount => integer().withDefault(const Constant(0))();

  /// その日カレンダーに押されたスタンプID (Null許容)
  TextColumn get appliedStampId => text().nullable()();

  @override
  Set<Column> get primaryKey => {dateStr};
}
