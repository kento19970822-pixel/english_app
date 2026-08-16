// コード管理番号: VER-20260816-09
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/main.dart';
import 'package:english_app/db/app_database.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final database = AppDatabase();
    await tester.pumpWidget(EnglishQuizApp(database: database));
  });
}
