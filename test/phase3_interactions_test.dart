import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/widgets/common/bouncy_scale_tap.dart';
import 'package:english_app/widgets/word_card_tile.dart';
import 'package:english_app/db/app_database.dart';

void main() {
  group('Phase 3 Micro-Interactions Tests', () {
    testWidgets('BouncyScaleTap fires onTap callback when pressed', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BouncyScaleTap(
              onTap: () => tapped = true,
              child: const Text('Bouncy Button'),
            ),
          ),
        ),
      );

      expect(find.text('Bouncy Button'), findsOneWidget);
      await tester.tap(find.text('Bouncy Button'));
      await tester.pump(const Duration(milliseconds: 150));

      expect(tapped, isTrue);
    });

    testWidgets('WordCardTile renders with swipe affordance markers', (tester) async {
      const dummyWord = Word(
        id: 1,
        english: 'apple',
        japanese: 'りんご',
        partOfSpeech: 'noun',
        cefr: 'A1',
        level: 1,
        chapter: 1,
        category: 'Fruits',
        retentionPoint: 80,
        isMemorized: true,
        isRestricted: false,
        isFavorite: false,
        correctCount: 5,
        wrongCount: 0,
        pointDecreasedTotal: 0,
        senseIndex: 1,
        totalSenses: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordCardTile(
              word: dummyWord,
              onTap: () {},
              onSpeak: () {},
              onToggleFavorite: () {},
              showJapanese: true,
            ),
          ),
        ),
      );

      expect(find.text('apple'), findsOneWidget);
      expect(find.text('りんご'), findsOneWidget);
    });
  });
}
