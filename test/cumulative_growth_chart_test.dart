import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/screens/calendar_screen.dart';
import 'package:english_app/widgets/calendar/cumulative_growth_chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Cumulative Growth Chart & History Tests (F-25)', () {
    test('AppDatabase.getCumulativeMemorizedHistory calculates steady cumulative series matching total memorized', () async {
      // 5語挿入 (3語暗記済み)
      await db.into(db.words).insert(
        const WordsCompanion(
          id: Value(1),
          english: Value('apple'),
          japanese: Value('りんご'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(1),
          category: Value('General'),
          isMemorized: Value(true),
          retentionPoint: Value(80),
        ),
      );
      await db.into(db.words).insert(
        const WordsCompanion(
          id: Value(2),
          english: Value('banana'),
          japanese: Value('バナナ'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(1),
          category: Value('General'),
          isMemorized: Value(true),
          retentionPoint: Value(85),
        ),
      );
      await db.into(db.words).insert(
        const WordsCompanion(
          id: Value(3),
          english: Value('cat'),
          japanese: Value('猫'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(1),
          category: Value('General'),
          isMemorized: Value(true),
          retentionPoint: Value(90),
        ),
      );

      final totalMem = await db.getTotalMemorizedWordsCount();
      expect(totalMem, equals(3));

      // 過去7日間の推移を取得
      final history7 = await db.getCumulativeMemorizedHistory(days: 7);
      expect(history7.length, equals(7));

      // 最新日（今日）の累計暗記数は totalMem (3) と完全一致すること
      expect(history7.last.cumulativeCount, equals(3));
      // 各日の累計数は 0 以上 3 以下であること
      for (final entry in history7) {
        expect(entry.cumulativeCount, inInclusiveRange(0, 3));
      }
    });

    testWidgets('CumulativeGrowthChart renders HUD, period chips, and progress bar', (tester) async {
      final now = DateTime.now();
      final sampleHist7 = List.generate(7, (i) {
        return (
          date: now.subtract(Duration(days: 6 - i)),
          cumulativeCount: 10 + i * 2,
          dailyGain: i == 0 ? 0 : 2,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CumulativeGrowthChart(
              totalMemorizedCount: 22,
              history7: sampleHist7,
              history14: sampleHist7,
              history30: sampleHist7,
              totalAvailableWords: 100,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('累計暗記単語数'), findsOneWidget);
      expect(find.text('22'), findsOneWidget);
      expect(find.text('語 暗記達成'), findsOneWidget);
      expect(find.text('7日'), findsOneWidget);
      expect(find.text('14日'), findsOneWidget);
      expect(find.text('30日'), findsOneWidget);
      expect(find.text('22.0% / 全100語'), findsOneWidget);

      // 14日タブをタップ
      await tester.tap(find.text('14日'));
      await tester.pumpAndSettle();
    });

    testWidgets('CalendarScreen loads and displays CumulativeGrowthChart at bottom', (tester) async {
      await db.into(db.words).insert(
        const WordsCompanion(
          id: Value(1),
          english: Value('dog'),
          japanese: Value('犬'),
          partOfSpeech: Value('noun'),
          cefr: Value('A1'),
          level: Value(1),
          chapter: Value(1),
          category: Value('General'),
          isMemorized: Value(true),
          retentionPoint: Value(80),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CalendarScreen(database: db),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('学習カレンダー'), findsOneWidget);
      expect(find.text('累計暗記単語数'), findsOneWidget);
    });
  });
}
