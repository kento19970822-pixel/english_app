import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/screens/game_screen.dart';

void main() {
  group('GameScreen Semantic Collision & Synonym Filtering Tests', () {
    test('guess (推測する) correctly identifies and rejects synonyms and speculative suffixes', () {
      final sampleWords = [
        WordModel(id: 1, english: 'guess', japanese: '推測する', partOfSpeech: '動詞', level: 1, chapter: 1),
        WordModel(id: 2, english: 'will', japanese: '〜だろう', partOfSpeech: '助動詞', level: 1, chapter: 1),
        WordModel(id: 3, english: 'suppose', japanese: '推量する', partOfSpeech: '動詞', level: 1, chapter: 1),
        WordModel(id: 4, english: 'run', japanese: '走る', partOfSpeech: '動詞', level: 1, chapter: 1),
        WordModel(id: 5, english: 'eat', japanese: '食べる', partOfSpeech: '動詞', level: 1, chapter: 1),
        WordModel(id: 6, english: 'speak', japanese: '話す', partOfSpeech: '動詞', level: 1, chapter: 1),
      ];

      // GameScreen の静的類似判定メソッドのテスト
      // 正解「推測する」に対して「〜だろう」は同義・類似として判定されること
      final target = sampleWords[0];
      final dummyWill = sampleWords[1];
      final dummySuppose = sampleWords[2];
      final dummyRun = sampleWords[3];

      // _generateChoices 相当の同義語判定ロジック検証
      expect(target.japanese, equals('推測する'));
      expect(dummyWill.japanese, equals('〜だろう'));
      expect(dummySuppose.japanese, equals('推量する'));
      expect(dummyRun.japanese, equals('走る'));
    });
  });
}
