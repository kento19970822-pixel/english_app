import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/screens/title_screen.dart';

void main() {
  testWidgets('TitleScreen pumps and renders title and tap to start', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(
      MaterialApp(
        home: TitleScreen(database: db),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('ENGLISH QUEST'), findsOneWidget);
    expect(find.text('TAP TO START'), findsOneWidget);
    await db.close();
  });
}
