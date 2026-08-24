// コード管理番号: VER-20260825-03
import 'package:drift/drift.dart';
import 'package:drift/web.dart';

DatabaseConnection connect() {
  return DatabaseConnection(
    WebDatabase('english_app_db'),
  );
}
