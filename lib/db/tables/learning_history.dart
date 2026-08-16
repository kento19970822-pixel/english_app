// コード管理番号: VER-20260816-04
import 'package:drift/drift.dart';

class LearningHistories extends Table {
  TextColumn get wordId => text()();

  // SM-2アルゴリズム用パラメータ
  IntColumn get repetitions =>
      integer().withDefault(const Constant(0))(); // 連続正解回数
  RealColumn get easinessFactor =>
      real().withDefault(const Constant(2.5))(); // 難易度係数
  IntColumn get intervalDays =>
      integer().withDefault(const Constant(0))(); // 次回までの間隔(日)

  DateTimeColumn get nextReviewDate => dateTime()(); // 次回復習予定日
  DateTimeColumn get lastReviewedAt => dateTime()(); // 最終学習日時

  @override
  Set<Column> get primaryKey => {wordId};
}
