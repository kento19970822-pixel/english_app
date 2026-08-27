import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/widgets/custom_fast_scrollbar.dart';
import 'package:english_app/widgets/word_card_tile.dart';

void main() {
  testWidgets('CustomFastScrollbar renders and responds to scroll', (WidgetTester tester) async {
    final controller = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomFastScrollbar(
            controller: controller,
            child: ListView.builder(
              controller: controller,
              itemCount: 100,
              itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CustomFastScrollbar), findsOneWidget);
    expect(find.text('Item 0'), findsOneWidget);

    // Scroll controller
    controller.jumpTo(500);
    await tester.pumpAndSettle();

    expect(find.byType(CustomFastScrollbar), findsOneWidget);
  });

  testWidgets('WordCardTile renders top buttons and 2nd row phonetic/category cleanly', (WidgetTester tester) async {
    final dummyWord = Word(
      id: 1,
      english: 'apple',
      japanese: 'りんご',
      level: 1,
      chapter: 1,
      cefr: 'A1',
      phonetic: '/ˈæp.əl/',
      category: 'Food',
      example: 'I ate an apple.',
      exampleJp: 'りんごを食べました。',
      partOfSpeech: '名',
      retentionPoint: 85,
      pointDecreasedTotal: 0,
      isMemorized: true,
      wrongCount: 0,
      correctCount: 5,
      isRestricted: false,
      isFavorite: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WordCardTile(
            word: dummyWord,
            showJapanese: true,
            onSpeak: () {},
            onToggleFavorite: () {},
          ),
        ),
      ),
    );

    expect(find.text('apple'), findsOneWidget);
    expect(find.text('85 pt'), findsOneWidget);
    expect(find.text('✓ 覚えた'), findsOneWidget);
    expect(find.text('Ch.1'), findsOneWidget);
    expect(find.text('/ˈæp.əl/'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('りんご'), findsOneWidget);
    expect(find.text('I ate an apple.'), findsOneWidget);
  });
}
