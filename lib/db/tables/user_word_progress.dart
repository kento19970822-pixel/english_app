import 'package:drift/drift.dart';
import 'words.dart';

/// ユーザー単語学習進捗 ＆ SRS（間隔反復）管理テーブル (3NF 第3正規化)
@DataClassName('UserWordProgress')
class UserWordProgresses extends Table {
  IntColumn get wordId => integer().references(Words, #id)();
  IntColumn get retentionPoint => integer().withDefault(const Constant(0))(); // 0..100 pt
  IntColumn get pointDecreasedTotal => integer().withDefault(const Constant(0))();
  BoolColumn get isMemorized => boolean().withDefault(const Constant(false))();
  BoolColumn get isRestricted => boolean().withDefault(const Constant(false))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get wrongCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastStudiedAt => dateTime().nullable()();
  DateTimeColumn get lastRestrictedDate => dateTime().nullable()();

  // SRS（間隔反復 SuperMemo SM-2）パラメータ
  IntColumn get srsIntervalDays => integer().withDefault(const Constant(0))(); // 次回復習までの日数
  RealColumn get srsEaseFactor => real().withDefault(const Constant(2.5))(); // 難易度係数 (初期2.5, 下限1.3)
  DateTimeColumn get nextReviewAt => dateTime().nullable()(); // 次回推奨復習日時

  @override
  Set<Column> get primaryKey => {wordId};
}
