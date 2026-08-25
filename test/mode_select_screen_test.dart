import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/screens/mode_select_screen.dart';

void main() {
  testWidgets('ModeSelectScreen renders correctly without overflow or errors', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModeSelectScreen(database: db),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('ゲーム選択'), findsOneWidget);
    expect(find.text('プレイモード'), findsOneWidget);
    expect(find.text('難易度レベル'), findsOneWidget);
    expect(find.text('学習モード'), findsOneWidget);
    expect(find.text('チャレンジ'), findsOneWidget);
    await db.close();
  });
}
