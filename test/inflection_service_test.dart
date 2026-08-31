import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/services/inflection_service.dart';

void main() {
  group('InflectionService Tests (F-01 / F-22)', () {
    test('Comparison inflections for good, better, best', () {
      final familyGood = InflectionService.instance.getInflectionFamily('good');
      expect(familyGood, isNotNull);
      expect(familyGood!.baseForm, equals('good'));
      expect(familyGood.categoryName, contains('比較変化'));
      expect(familyGood.items.length, equals(3));
      expect(familyGood.items[0].label, equals('原級'));
      expect(familyGood.items[0].word, equals('good'));
      expect(familyGood.items[1].label, equals('比較級'));
      expect(familyGood.items[1].word, equals('better'));
      expect(familyGood.items[2].label, equals('最上級'));
      expect(familyGood.items[2].word, equals('best'));

      // better から引いても同じファミリーが返ること
      final familyBetter = InflectionService.instance.getInflectionFamily('better', baseForm: 'good');
      expect(familyBetter, isNotNull);
      expect(familyBetter!.baseForm, equals('good'));
      expect(familyBetter.items[1].word, equals('better'));

      // best から引いても同じファミリーが返ること
      final familyBest = InflectionService.instance.getInflectionFamily('best', baseForm: 'good');
      expect(familyBest, isNotNull);
      expect(familyBest!.baseForm, equals('good'));
      expect(familyBest.items[2].word, equals('best'));
    });

    test('Verb inflections for go, went, gone', () {
      final familyGo = InflectionService.instance.getInflectionFamily('go');
      expect(familyGo, isNotNull);
      expect(familyGo!.baseForm, equals('go'));
      expect(familyGo.categoryName, contains('動詞活用'));
      expect(familyGo.items.any((i) => i.label == '原形' && i.word == 'go'), isTrue);
      expect(familyGo.items.any((i) => i.label == '過去形' && i.word == 'went'), isTrue);
      expect(familyGo.items.any((i) => i.label == '過去分詞' && i.word == 'gone'), isTrue);
      expect(familyGo.items.any((i) => i.label == '三単現' && i.word == 'goes'), isTrue);
      expect(familyGo.items.any((i) => i.label == '-ing' && i.word == 'going'), isTrue);

      // went から引いても同じファミリーが返ること
      final familyWent = InflectionService.instance.getInflectionFamily('went', baseForm: 'go');
      expect(familyWent, isNotNull);
      expect(familyWent!.baseForm, equals('go'));
    });

    test('Noun inflections for child, children', () {
      final familyChild = InflectionService.instance.getInflectionFamily('child');
      expect(familyChild, isNotNull);
      expect(familyChild!.baseForm, equals('child'));
      expect(familyChild.categoryName, contains('名詞変化'));
      expect(familyChild.items.any((i) => i.label == '単数形' && i.word == 'child'), isTrue);
      expect(familyChild.items.any((i) => i.label == '複数形' && i.word == 'children'), isTrue);

      // children から引いても同じファミリーが返ること
      final familyChildren = InflectionService.instance.getInflectionFamily('children', baseForm: 'child');
      expect(familyChildren, isNotNull);
      expect(familyChildren!.baseForm, equals('child'));
    });
  });
}
