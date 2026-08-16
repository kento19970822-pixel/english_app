// コード管理番号: VER-20260816-03
import 'package:drift/drift.dart';

class Words extends Table {
  TextColumn get id => text()();
  TextColumn get english => text()();
  TextColumn get japanese => text()();
  IntColumn get level => integer().withDefault(const Constant(1))();
  TextColumn get audioUrl => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
