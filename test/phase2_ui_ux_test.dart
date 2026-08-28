import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/screens/mode_select_screen.dart';
import 'package:english_app/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget createSubject() {
    return MaterialApp(
      home: ModeSelectScreen(database: db),
    );
  }

  group('Phase 2 UI/UX Minimization & Affordance Tests', () {
    testWidgets('ModeSelectScreen renders slimmed typography and unlock badge', (tester) async {
      await db.into(db.words).insert(
        const WordsCompanion(
          id: Value(1),
          english: Value('hello'),
          japanese: Value('こんにちは'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(1),
          category: Value('General'),
        ),
      );
      await db.initChapterProgresses();

      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // 簡潔なモードサブタイトルの存在確認
      expect(find.text('章別集中\n次章解放'), findsOneWidget);
      expect(find.text('苦手特訓\n反復学習'), findsOneWidget);
      expect(find.text('1分/100問\nランダム'), findsOneWidget);

      // スリム化された解放条件バッジの存在確認
      expect(find.text('70pt以上 90%で次章'), findsOneWidget);

      // 学習モード時は「複数選択可」バッジが存在しないこと
      expect(find.text('複数選択可'), findsNothing);
    });

    testWidgets('Switching to Weakness mode reveals multi-selection affordance', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 300));

      // 弱点克服モードをタップ
      await tester.tap(find.text('弱点克服'));
      await tester.pump(const Duration(milliseconds: 300));

      // 「複数選択可」バッジが表示されること
      expect(find.text('複数選択可'), findsOneWidget);
      // チェックマークアイコンが表示されること
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
    });
  });
}
