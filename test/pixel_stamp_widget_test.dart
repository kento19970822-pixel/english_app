// コード管理番号: VER-20260824-37
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/widgets/pixel_stamp_widget.dart';

void main() {
  group('PixelStampWidget Tests', () {
    testWidgets('renders unlocked stamp with CustomPaint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PixelStampWidget(
              id: 'stamp_test_01',
              name: 'ひよこの一歩',
              rarity: StampRarity.normal,
              paletteId: 0,
              patternId: 0,
              isUnlocked: true,
              size: 64,
            ),
          ),
        ),
      );

      expect(find.byType(PixelStampWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders locked silhouette stamp', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PixelStampWidget(
              id: 'stamp_test_02',
              name: '知恵のフクロウ',
              rarity: StampRarity.rare,
              paletteId: 8,
              patternId: 3,
              isUnlocked: false,
              size: 64,
            ),
          ),
        ),
      );

      expect(find.byType(PixelStampWidget), findsOneWidget);
    });

    testWidgets('renders favorite star badge when isFavorite is true and unlocked', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PixelStampWidget(
              id: 'stamp_test_03',
              name: '栄光のクラウン',
              rarity: StampRarity.superRare,
              paletteId: 13,
              patternId: 8,
              isUnlocked: true,
              isFavorite: true,
              size: 64,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });
  });
}
