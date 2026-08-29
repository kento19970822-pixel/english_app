import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/widgets/pixel_character_widget.dart';
import 'package:english_app/screens/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Release Flag Persistence & Growth State Tests', () {
    test('Unlocked character retains lowHealth and never reverts to locked silhouette even if rate is 0%', () {
      // 未解放チャプターは locked (黒シルエット)
      expect(PixelCharacterWidget.stateFromRate(0.0, false), CharacterGrowthState.locked);
      expect(PixelCharacterWidget.stateFromRate(50.0, false), CharacterGrowthState.locked);

      // 解放済みチャプターは 0% や忘却曲線減算後でも locked (シルエット) に戻らず lowHealth を維持
      expect(PixelCharacterWidget.stateFromRate(0.0, true), CharacterGrowthState.lowHealth);
      expect(PixelCharacterWidget.stateFromRate(30.0, true), CharacterGrowthState.lowHealth);
      expect(PixelCharacterWidget.stateFromRate(50.0, true), CharacterGrowthState.healthy);
      expect(PixelCharacterWidget.stateFromRate(79.9, true), CharacterGrowthState.healthy);
      expect(PixelCharacterWidget.stateFromRate(80.0, true), CharacterGrowthState.evolved);
      expect(PixelCharacterWidget.stateFromRate(100.0, true), CharacterGrowthState.evolved);
    });
  });

  group('Semantic Synonym Exclusion Tests', () {
    test('Correctly identifies synonym clusters and prevents duplicates', () {
      // like / love / prefer (感情・嗜好)
      expect(GameScreen.testIsSynonymOrSimilar('好き', '好んでいる'), isTrue);
      expect(GameScreen.testIsSynonymOrSimilar('好き', '好む'), isTrue);
      expect(GameScreen.testIsSynonymOrSimilar('好き', '愛する'), isTrue);

      // 大小 (サイズ・量)
      expect(GameScreen.testIsSynonymOrSimilar('大きい', '巨大な'), isTrue);
      expect(GameScreen.testIsSynonymOrSimilar('小さい', 'わずかな'), isTrue);

      // 発言 (話す/言う/語る)
      expect(GameScreen.testIsSynonymOrSimilar('話す', '言う'), isTrue);
      expect(GameScreen.testIsSynonymOrSimilar('話す', '語る'), isTrue);

      // 異なる意味は false
      expect(GameScreen.testIsSynonymOrSimilar('好き', '走る'), isFalse);
      expect(GameScreen.testIsSynonymOrSimilar('大きい', '話す'), isFalse);
      expect(GameScreen.testIsSynonymOrSimilar('平らな', '速い'), isFalse);
    });
  });
}
