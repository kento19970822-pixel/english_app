// コード管理番号: VER-20260817-01
import 'package:drift/drift.dart';

/// 単語マスター & 定着度管理テーブル
class Words extends Table {
  /// 単語ID
  IntColumn get id => integer().autoIncrement()();

  /// 英単語
  TextColumn get english => text()();

  /// 日本語訳
  TextColumn get japanese => text()();

  /// 発音記号 (将来のデータ追加に対応するため Null 許容)
  TextColumn get phonetic => text().nullable()();

  /// CEFRレベル (A1, A2, B1, B2, C1, C2)
  TextColumn get cefr => text()();

  /// 難易度レベル (1: 初級, 2: 中級, 3: 上級)
  IntColumn get level => integer()();

  /// 章番号 (100単語ごとに 1, 2, 3...)
  IntColumn get chapter => integer().withDefault(const Constant(1))();

  /// ★お気に入りフラグ
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// 暗記済みフラグ (80pt以上で自動ON, 手動変更可能)
  BoolColumn get isMemorized => boolean().withDefault(const Constant(false))();

  /// 現在の定着度ポイント (0.0 〜 100.0)
  RealColumn get retentionRate => real().withDefault(const Constant(0.0))();

  /// 累計正答回数
  IntColumn get correctCount => integer().withDefault(const Constant(0))();

  /// 累計誤答回数
  IntColumn get wrongCount => integer().withDefault(const Constant(0))();

  /// 最終解答日時
  DateTimeColumn get lastAnsweredAt => dateTime().nullable()();

  /// 当日上限(70pt)制限フラグ
  BoolColumn get dailyLimitFlag =>
      boolean().withDefault(const Constant(false))();

  /// 制限がかかった日付
  DateTimeColumn get lastPenaltyDate => dateTime().nullable()();
}
