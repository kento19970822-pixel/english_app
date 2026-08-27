// コード管理番号: VER-20260827-04
import 'package:drift/drift.dart';
import 'words.dart';

/// 単語別学習ログテーブル（時系列記録用）
/// 直近90日間 / 最大10,000件のローリング保持ポリシー
class LearningLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId => integer().references(Words, #id)();
  BoolColumn get isCorrect => boolean()();
  TextColumn get mode => text().withDefault(const Constant('quiz'))(); // 'quiz', 'swipe_memorized', 'review'
  DateTimeColumn get learnedAt => dateTime().withDefault(currentDateAndTime)();
}
