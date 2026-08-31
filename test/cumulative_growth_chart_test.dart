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

  group('Cumulative Growth Chart Multi-Span & History Tests (F-25)', () {
    test('AppDatabase calculates daily, monthly, and yearly cumulative series', () async {
      // 3語暗記済みで挿入
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

      // 1. 日別推移 (30日)
      final dailyHist = await db.getCumulativeMemorizedHistory(days: 30);
      expect(dailyHist.length, equals(30));
      expect(dailyHist.last.cumulativeCount, equals(3));

      // 2. 月別推移 (12ヶ月)
      final monthlyHist = await db.getCumulativeMonthlyHistory(months: 12);
      expect(monthlyHist.length, equals(12));
      expect(monthlyHist.last.cumulativeCount, equals(3));

      // 3. 年別推移 (3年)
      final yearlyHist = await db.getCumulativeYearlyHistory(years: 3);
      expect(yearlyHist.length, equals(3));
      expect(yearlyHist.last.cumulativeCount, equals(3));
    });

    testWidgets('CumulativeGrowthChart switches between Daily, Monthly, and Yearly tabs', (tester) async {
      final now = DateTime.now();
      final sampleDaily = List.generate(30, (i) {
        return (
          date: now.subtract(Duration(days: 29 - i)),
          cumulativeCount: 10 + i,
          dailyGain: i == 0 ? 0 : 1,
        );
      });
      final sampleMonthly = List.generate(12, (i) {
        return (
          date: DateTime(now.year, now.month - 11 + i, 1),
          cumulativeCount: 5 + i * 3,
          dailyGain: 3,
        );
      });
      final sampleYearly = List.generate(3, (i) {
        return (
          date: DateTime(now.year - 2 + i, 1, 1),
          cumulativeCount: 10 + i * 15,
          dailyGain: 15,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CumulativeGrowthChart(
              totalMemorizedCount: 40,
              dailyHistory: sampleDaily,
              monthlyHistory: sampleMonthly,
              yearlyHistory: sampleYearly,
              totalAvailableWords: 100,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('累計暗記単語数'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('語 暗記達成'), findsOneWidget);
      expect(find.text('日'), findsOneWidget);
      expect(find.text('月'), findsOneWidget);
      expect(find.text('年'), findsOneWidget);

      // 月タブをタップ
      await tester.tap(find.text('月'));
      await tester.pumpAndSettle();
      expect(find.textContaining('今月'), findsOneWidget);

      // 年タブをタップ
      await tester.tap(find.text('年'));
      await tester.pumpAndSettle();
      expect(find.textContaining('今年'), findsOneWidget);
    });

    testWidgets('CalendarScreen loads and displays full multi-span CumulativeGrowthChart', (tester) async {
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
      expect(find.byType(CumulativeGrowthChart), findsOneWidget);
      expect(find.text('累計暗記単語数'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CumulativeGrowthChart),
          matching: find.text('日'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(CumulativeGrowthChart),
          matching: find.text('月'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(CumulativeGrowthChart),
          matching: find.text('年'),
        ),
        findsOneWidget,
      );
    });
  });
}
