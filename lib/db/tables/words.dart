// コード管理番号: VER-20260816-50
import 'package:drift/drift.dart';

class Words extends Table {
  TextColumn get id => text()();
  TextColumn get english => text()();
  TextColumn get japanese => text()();
  TextColumn get cefr => text().withDefault(const Constant('A1'))();
  TextColumn get example => text().nullable()();
  TextColumn get exampleJp => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
