import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/screens/title_screen.dart';

void main() {
  testWidgets('TitleScreen pumps and renders title and tap to start', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.insertRawWords([
      {'word': 'apple', 'Japanese': 'りんご', 'CEFR': 'A1'}
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: TitleScreen(database: db),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ENGLISH QUEST'), findsOneWidget);
    expect(find.text('脳に刻む、爽快スピード暗記。'), findsOneWidget);
    expect(find.text('TAP TO START'), findsOneWidget);
    await db.close();
  });
}
