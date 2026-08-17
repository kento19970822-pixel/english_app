// コード管理番号: VER-20260817-05
import 'package:drift/drift.dart'; // ※もし package0 になっていたら package に修正

/// 学習・ゲーム履歴テーブル
class LearningHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get score => integer()();
  IntColumn get level => integer()();
  DateTimeColumn get playedAt => dateTime().withDefault(currentDateAndTime)();
}
