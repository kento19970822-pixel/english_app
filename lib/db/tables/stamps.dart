// コード管理番号: VER-20260817-03
import 'package:drift/drift.dart';

/// スタンプマスター & 獲得状態テーブル
class Stamps extends Table {
  /// スタンプID (例: `stamp_lion`, `stamp_cat`)
  TextColumn get id => text()();

  /// スタンプ名 (例: ライオンスタンプ)
  TextColumn get name => text()();

  /// 表示用アイコン識別子 / 画像アセットパス
  TextColumn get iconCode => text()();

  /// 出現条件種別 (`none`, `streak`, `daily_memorized`)
  TextColumn get conditionType => text().withDefault(const Constant('none'))();

  /// 条件閾値 (例: 連続3日なら 3)
  IntColumn get conditionValue => integer().withDefault(const Constant(0))();

  /// 獲得（ロック解除）フラグ
  BoolColumn get isUnlocked => boolean().withDefault(const Constant(false))();

  /// 初回獲得日時
  DateTimeColumn get unlockedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
