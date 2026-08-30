// コード管理番号: VER-20260824-01
import 'package:drift/drift.dart';

/// チャプター解放状態・進行度テーブル
class ChapterProgresses extends Table {
  /// 通しチャプター番号 (1〜)
  IntColumn get chapter => integer()();

  /// 所属難易度レベル (1: 初級A1, 2: 初級A2, 3: 中級B1, 4: 中級B2, 5: 上級C1, 6: 上級C2)
  IntColumn get level => integer().withDefault(const Constant(1))();

  /// 解放フラグ (選択可能か)
  BoolColumn get isUnlocked => boolean().withDefault(const Constant(false))();

  /// クリア済みフラグ (学習モードで暗記率90%超達成)
  BoolColumn get isCleared => boolean().withDefault(const Constant(false))();

  /// 最新のチャプター内暗記フラグ率 (0.0〜100.0)
  RealColumn get memorizedRate => real().withDefault(const Constant(0.0))();

  /// キャラクター解放フラグ (学習開始・暗記で一度解放されたら減衰しても永続維持)
  BoolColumn get isCharacterUnlocked => boolean().withDefault(const Constant(false))();

  /// クリア達成日時
  DateTimeColumn get clearedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {chapter};
}
