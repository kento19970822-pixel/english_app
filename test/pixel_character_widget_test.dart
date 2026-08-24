// コード管理番号: VER-20260824-52
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/services/buddy_service.dart';
import 'package:english_app/widgets/pixel_character_widget.dart';

void main() {
  group('PixelCharacterWidget Tests', () {
    testWidgets('renders all 12 character species with CustomPaint', (tester) async {
      for (int i = 0; i < 12; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PixelCharacterWidget(
                speciesIndex: i,
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

    testWidgets('renders all 4 growth stages correctly', (tester) async {
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

    test('stateFromRate maps memorization rate and unlock state accurately', () {
      expect(PixelCharacterWidget.stateFromRate(0.0, false), CharacterGrowthState.locked);
      expect(PixelCharacterWidget.stateFromRate(85.0, false), CharacterGrowthState.locked);

      expect(PixelCharacterWidget.stateFromRate(0.0, true), CharacterGrowthState.lowHealth);
      expect(PixelCharacterWidget.stateFromRate(35.0, true), CharacterGrowthState.lowHealth);
      expect(PixelCharacterWidget.stateFromRate(50.0, true), CharacterGrowthState.healthy);
      expect(PixelCharacterWidget.stateFromRate(79.0, true), CharacterGrowthState.healthy);
      expect(PixelCharacterWidget.stateFromRate(80.0, true), CharacterGrowthState.evolved);
      expect(PixelCharacterWidget.stateFromRate(100.0, true), CharacterGrowthState.evolved);
    });

    test('BuddyService maintains and updates active buddy species ID', () {
      final buddyService = BuddyService.instance;
      buddyService.setSelectedSpeciesId(3);
      expect(buddyService.selectedSpeciesId, 3);

      buddyService.setSelectedSpeciesId(14); // 14 % 12 == 2
      expect(buddyService.selectedSpeciesId, 2);
    });
  });
}
