// コード管理番号: VER-20260824-46
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_app/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Word Import & Chapter Allocation Tests', () {
    test('insertRawWords correctly parses and imports words with examples', () async {
      final sampleCsvData = [
        {
          'word': 'apple',
          'CEFR': 'A1',
          'Japanese': 'リンゴ',
          'Example': 'I ate a red apple.',
          'Example_JP': '私は赤いリンゴを食べた。',
        },
        {
          'word': 'banana',
          'CEFR': 'A1',
          'Japanese': 'バナナ',
          'Example': 'Monkeys like bananas.',
          'Example_JP': 'サルはバナナが好きです。',
        },
      ];

      await db.insertRawWords(sampleCsvData);
      final words = await db.getAllWords();

      expect(words.length, 2);
      expect(words[0].english, 'apple');
      expect(words[0].japanese, 'リンゴ');
      expect(words[0].example, 'I ate a red apple.');
      expect(words[0].exampleJp, '私は赤いリンゴを食べた。');
      expect(words[0].level, 1);
      expect(words[0].chapter, 1);
    });

    test('insertRawWords groups words into chapters of 100 and advances chapter on level boundary', () async {
      final List<Map<String, String>> rawWords = [];

      // Add 205 words in A1 (Level 1) -> should produce Ch.1 (100 words), Ch.2 (100 words), Ch.3 (5 words)
      for (int i = 1; i <= 205; i++) {
        rawWords.add({
          'word': 'a1_word_$i',
          'CEFR': 'A1',
          'Japanese': '意味_$i',
        });
      }

      // Add 50 words in B1 (Level 2) -> should advance to Ch.4 (50 words)
      for (int i = 1; i <= 50; i++) {
        rawWords.add({
          'word': 'b1_word_$i',
          'CEFR': 'B1',
          'Japanese': 'B1意味_$i',
        });
      }

      await db.insertRawWords(rawWords);
      final allWords = await db.getAllWords();

      expect(allWords.length, 255);

      final ch1Words = allWords.where((w) => w.chapter == 1).toList();
      final ch2Words = allWords.where((w) => w.chapter == 2).toList();
      final ch3Words = allWords.where((w) => w.chapter == 3).toList();
      final ch4Words = allWords.where((w) => w.chapter == 4).toList();

      expect(ch1Words.length, 100);
      expect(ch2Words.length, 100);
      expect(ch3Words.length, 5);
      expect(ch3Words.first.level, 1); // Level 1

      expect(ch4Words.length, 50);
      expect(ch4Words.first.level, 2); // Level 2 starts on new chapter Ch.4
    });

    test('insertRawWords safely skips rows with empty English or empty Japanese', () async {
      final sampleData = [
        {'word': 'valid', 'CEFR': 'A1', 'Japanese': '有効'},
        {'word': '', 'CEFR': 'A1', 'Japanese': '空単語'},
        {'word': 'no_jp', 'CEFR': 'A1', 'Japanese': '   '},
      ];

      await db.insertRawWords(sampleData);
      final words = await db.getAllWords();

      expect(words.length, 1);
      expect(words.first.english, 'valid');
    });

    test('insertRawWords properly stores explicit partOfSpeech, collocations, otherMeanings, and baseForm', () async {
      final sampleData = [
        {
          'word': 'went',
          'CEFR': 'A1',
          'Japanese': '行った',
          'partOfSpeech': 'verb',
          'phonetic': '/wɛnt/',
          'category': 'Daily',
          'Example': 'I went to school.',
          'Example_JP': '私は学校へ行った。',
          'collocations': '[{"phrase":"go to school","meaning":"通学する"}]',
          'otherMeanings': '[{"sense_id":1,"part_of_speech":"verb","meaning_ja":"行った"}]',
          'baseForm': 'go',
        },
      ];

      await db.insertRawWords(sampleData);
      final words = await db.getAllWords();

      expect(words.length, 1);
      final w = words.first;
      expect(w.english, 'went');
      expect(w.partOfSpeech, 'verb');
      expect(w.baseForm, 'go');
      expect(w.collocations, contains('go to school'));
      expect(w.otherMeanings, contains('sense_id'));
    });
  });
}

