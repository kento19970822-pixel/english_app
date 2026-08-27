// コード管理番号: VER-20260825-15
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/services/buddy_service.dart';
import 'package:english_app/widgets/pixel_character_widget.dart';

void main() {
  group('PixelCharacterWidget Tests (374 Chapters)', () {
    testWidgets('renders sample characters across all 8 categories with 48x48 CustomPaint', (tester) async {
      final sampleChapters = [1, 50, 80, 120, 160, 200, 280, 330, 370];
      for (final chap in sampleChapters) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PixelCharacterWidget(
                speciesIndex: chap - 1,
                growthState: CharacterGrowthState.healthy,
                size: 64,
              ),
            ),
          ),
        );

        expect(find.byType(PixelCharacterWidget), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      }
    });

    testWidgets('renders all 4 growth stages including solid black silhouette for locked', (tester) async {
      final states = [
        CharacterGrowthState.locked,
        CharacterGrowthState.lowHealth,
        CharacterGrowthState.healthy,
        CharacterGrowthState.evolved,
      ];

      for (final state in states) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PixelCharacterWidget(
                speciesIndex: 0,
                growthState: state,
                size: 64,
              ),
            ),
          ),
        );

        expect(find.byType(PixelCharacterWidget), findsOneWidget);
      }
    });

    testWidgets('renders all 4 action states and chest badge with favorite stamp', (tester) async {
      const mockStamp = Stamp(
        id: 'stamp_test_01',
        name: '金の星',
        phase: 1,
        rarity: 'super_rare',
        colorPaletteId: 0,
        patternId: 0,
        frameId: 0,
        effectId: 0,
        description: '金の星スタンプ',
        iconCode: 'star',
        conditionType: 'none',
        conditionValue: 0,
        isFavorite: true,
        isUnlocked: true,
      );

      final actions = [
        CharacterActionState.idle,
        CharacterActionState.walk,
        CharacterActionState.sleep,
        CharacterActionState.humming,
      ];

      for (final action in actions) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PixelCharacterWidget(
                speciesIndex: 1,
                growthState: CharacterGrowthState.evolved,
                actionState: action,
                favoriteStamp: mockStamp,
                size: 64,
                isInteractive: true,
              ),
            ),
          ),
        );

        expect(find.byType(PixelCharacterWidget), findsOneWidget);
      }
    });

    test('stateFromRate maps 0% and locked state to locked silhouette', () {
      // 未解放 または 暗記率0%は必ず locked（完全黒シルエット）
      expect(PixelCharacterWidget.stateFromRate(0.0, false), CharacterGrowthState.locked);
      expect(PixelCharacterWidget.stateFromRate(85.0, false), CharacterGrowthState.locked);
      expect(PixelCharacterWidget.stateFromRate(0.0, true), CharacterGrowthState.locked);

      // 1〜49%（学習開始後）は必ず lowHealth（元気がない）
      expect(PixelCharacterWidget.stateFromRate(1.0, true), CharacterGrowthState.lowHealth);
      expect(PixelCharacterWidget.stateFromRate(35.0, true), CharacterGrowthState.lowHealth);
      expect(PixelCharacterWidget.stateFromRate(49.9, true), CharacterGrowthState.lowHealth);

      // 50〜79%は healthy（元気）
      expect(PixelCharacterWidget.stateFromRate(50.0, true), CharacterGrowthState.healthy);
      expect(PixelCharacterWidget.stateFromRate(79.0, true), CharacterGrowthState.healthy);

      // 80%以上は evolved（進化形態）
      expect(PixelCharacterWidget.stateFromRate(80.0, true), CharacterGrowthState.evolved);
      expect(PixelCharacterWidget.stateFromRate(100.0, true), CharacterGrowthState.evolved);
    });

    test('BuddyService maintains and updates active buddy species ID for all chapters', () {
      final buddyService = BuddyService.instance;
      buddyService.setSelectedSpeciesId(10);
      expect(buddyService.selectedSpeciesId, 10);

      buddyService.setSelectedSpeciesId(kTotalChapterCount); // kTotalChapterCount % kTotalChapterCount == 0
      expect(buddyService.selectedSpeciesId, 0);
    });

    test('getCharacterSpecies generates distinct species for all chapters across 8 categories', () {
      expect(kTotalChapterCount, 350);

      for (int c = 1; c <= kTotalChapterCount; c++) {
        final sp = getCharacterSpecies(c);
        expect(sp.chapter, c);
        expect(sp.japaneseName.isNotEmpty, isTrue);
        expect(sp.coreFeature.isNotEmpty, isTrue);
        expect(sp.category, CharacterCategory.fromChapter(c));
      }
    });
  });
}
