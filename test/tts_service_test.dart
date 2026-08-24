// コード管理番号: VER-20260824-44
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/services/tts_service.dart';

void main() {
  group('TtsService Voice Selection Tests', () {
    test('selectBestVoice returns null for empty list', () {
      final best = TtsService.selectBestVoice([]);
      expect(best, isNull);
    });

    test('selectBestVoice ignores non-English voices', () {
      final voices = [
        {'name': 'Kyoko', 'locale': 'ja-JP'},
        {'name': 'Otoya', 'locale': 'ja-JP'},
        {'name': 'Thomas', 'locale': 'fr-FR'},
      ];
      final best = TtsService.selectBestVoice(voices);
      expect(best, isNull);
    });

    test('selectBestVoice prefers US/GB English and Neural/Natural voices over legacy standard voices', () {
      final voices = [
        {'name': 'Microsoft David Desktop - English (United States)', 'locale': 'en-US'},
        {'name': 'Microsoft Zira Desktop - English (United States)', 'locale': 'en-US'},
        {'name': 'Microsoft Jenny (Natural) - English (United States)', 'locale': 'en-US'},
        {'name': 'Microsoft George - English (United Kingdom)', 'locale': 'en-GB'},
      ];
      final best = TtsService.selectBestVoice(voices);
      expect(best, isNotNull);
      expect(best!['name'], 'Microsoft Jenny (Natural) - English (United States)');
      expect(best['locale'], 'en-US');
    });

    test('selectBestVoice selects Apple Siri / Enhanced voice on Apple platforms', () {
      final voices = [
        {'name': 'com.apple.voice.compact.en-US.Samantha', 'locale': 'en-US'},
        {'name': 'com.apple.voice.enhanced.en-US.Samantha', 'locale': 'en-US'},
        {'name': 'com.apple.ttsbundle.siri_female_en-US_compact', 'locale': 'en-US'},
      ];
      final best = TtsService.selectBestVoice(voices);
      expect(best, isNotNull);
      expect(best!['name'], 'com.apple.voice.enhanced.en-US.Samantha');
    });

    test('selectBestVoice selects Android Google Wavenet / Network voices', () {
      final voices = [
        {'name': 'en-us-x-sfg-local', 'locale': 'en-US'},
        {'name': 'en-us-x-iom-wavenet', 'locale': 'en-US'},
      ];
      final best = TtsService.selectBestVoice(voices);
      expect(best, isNotNull);
      expect(best!['name'], 'en-us-x-iom-wavenet');
    });
  });
}
