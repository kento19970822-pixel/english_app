// コード管理番号: VER-20260824-28
import 'package:drift/drift.dart';

/// スタンプマスター & 獲得状態テーブル
class Stamps extends Table {
  /// スタンプID (例: `stamp_p1_01`)
  TextColumn get id => text()();

  /// 世代フェーズ (例: 1, 2, ...)
  IntColumn get phase => integer().withDefault(const Constant(1))();

  /// スタンプ名 (例: はじまりのフクロウ)
  TextColumn get name => text()();

  /// レア度 (`normal`, `rare`, `super_rare`)
  TextColumn get rarity => text().withDefault(const Constant('normal'))();

  /// 相棒胸バッジ用お気に入りフラグ (1つのみTRUE)
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// ドット絵カラーパレットID
  IntColumn get colorPaletteId => integer().withDefault(const Constant(0))();

  /// ドット絵モチーフパターンID
  IntColumn get patternId => integer().withDefault(const Constant(0))();

  /// スタンプ外枠フレームID (0:丸枠, 1:角丸四角, 2:切手ギザギザ, 3:二重枠, 4:王冠/エンブレム)
  IntColumn get frameId => integer().withDefault(const Constant(0))();

  /// 装飾エフェクトID (0:なし, 1:星粒子, 2:集中線, 3:大星+シャイン, 4:月桂樹)
  IntColumn get effectId => integer().withDefault(const Constant(0))();

  /// 説明・獲得条件文面 (例: 連続3日学習を達成する)
  TextColumn get description => text().withDefault(const Constant(''))();

  /// 表示用アイコン識別子 / 互換用コード
  TextColumn get iconCode => text().withDefault(const Constant(''))();

  /// 出現条件種別 (`none`, `streak_days`, `total_days`, `memorized_count`, `cleared_chapters`)
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

