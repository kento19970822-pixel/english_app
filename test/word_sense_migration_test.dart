import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:english_app/db/app_database.dart';
import 'package:english_app/models/word_detail_model.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Word Sense DB Model (Step 2) Tests', () {
    test('insertRawWords imports senseIndex, totalSenses, and wordGroup correctly', () async {
      final sampleSenseData = [
        {
          'word': 'can',
          'senseIndex': '1',
          'totalSenses': '2',
          'CEFR': 'A1',
          'Japanese': '〜できる、〜してもよい',
          'partOfSpeech': 'auxiliary',
          'phonetic': '/kæn/',
          'category': 'Daily',
          'Example': 'I can speak English.',
          'Example_JP': '私は英語を話すことができます。',
          'collocations': '[{"phrase": "can do", "meaning": "〜できる"}]',
          'baseForm': '',
        },
        {
          'word': 'can',
          'senseIndex': '2',
          'totalSenses': '2',
          'CEFR': 'A2',
          'Japanese': '缶、缶詰',
          'partOfSpeech': 'noun',
          'phonetic': '/kæn/',
          'category': 'Daily',
          'Example': 'Open a can of soup.',
          'Example_JP': 'スープの缶を開ける。',
          'collocations': '[{"phrase": "can do", "meaning": "〜できる"}]',
          'baseForm': '',
        },
        {
          'word': 'book',
          'senseIndex': '1',
          'totalSenses': '2',
          'CEFR': 'A1',
          'Japanese': '本、書籍',
          'partOfSpeech': 'noun',
          'phonetic': '/bʊk/',
          'category': 'General',
          'Example': 'I am reading a book.',
          'Example_JP': '私は本を読んでいます。',
          'collocations': '',
          'baseForm': '',
        },
        {
          'word': 'book',
          'senseIndex': '2',
          'totalSenses': '2',
          'CEFR': 'B1',
          'Japanese': '予約する',
          'partOfSpeech': 'verb',
          'phonetic': '/bʊk/',
          'category': 'General',
          'Example': 'Book a table for two.',
          'Example_JP': '2人席を予約する。',
          'collocations': '',
          'baseForm': '',
        },
      ];

      await db.insertRawWords(sampleSenseData);
      final allWords = await db.getAllWords();

      expect(allWords.length, 4);

      final canSenses = allWords.where((w) => w.english == 'can').toList();
      expect(canSenses.length, 2);
      expect(canSenses[0].senseIndex, 1);
      expect(canSenses[0].totalSenses, 2);
      expect(canSenses[0].japanese, '〜できる、〜してもよい');
      expect(canSenses[0].partOfSpeech, 'auxiliary');
      expect(canSenses[0].wordGroup, 'can');

      expect(canSenses[1].senseIndex, 2);
      expect(canSenses[1].totalSenses, 2);
      expect(canSenses[1].japanese, '缶、缶詰');
      expect(canSenses[1].partOfSpeech, 'noun');

      final bookSenses = allWords.where((w) => w.english == 'book').toList();
      expect(bookSenses.length, 2);
      expect(bookSenses[0].japanese, '本、書籍');
      expect(bookSenses[0].level, 1); // A1 -> level 1
      expect(bookSenses[1].japanese, '予約する');
      expect(bookSenses[1].level, 2); // B1 -> level 2
    });

    test('getAllSensesForWord returns all senses across chapters', () async {
      final sampleSenseData = [
        {
          'word': 'book',
          'senseIndex': '1',
          'totalSenses': '2',
          'CEFR': 'A1',
          'Japanese': '本',
          'partOfSpeech': 'noun',
        },
        {
          'word': 'book',
          'senseIndex': '2',
          'totalSenses': '2',
          'CEFR': 'B1',
          'Japanese': '予約する',
          'partOfSpeech': 'verb',
        },
      ];

      await db.insertRawWords(sampleSenseData);
      final senses = await db.getAllSensesForWord('book');

      expect(senses.length, 2);
      expect(senses[0].japanese, '本');
      expect(senses[1].japanese, '予約する');
    });

    test('WordDetail.fromWordWithSiblings populates multi-sense chapters correctly', () async {
      final sampleSenseData = [
        {
          'word': 'book',
          'senseIndex': '1',
          'totalSenses': '2',
          'CEFR': 'A1',
          'Japanese': '本',
          'partOfSpeech': 'noun',
          'Example': 'Read a book.',
          'Example_JP': '本を読む。',
        },
        {
          'word': 'book',
          'senseIndex': '2',
          'totalSenses': '2',
          'CEFR': 'B1',
          'Japanese': '予約する',
          'partOfSpeech': 'verb',
          'Example': 'Book a room.',
          'Example_JP': '部屋を予約する。',
        },
      ];

      await db.insertRawWords(sampleSenseData);
      final senses = await db.getAllSensesForWord('book');

      final detailSense1 = WordDetail.fromWordWithSiblings(senses[0], senses);
      expect(detailSense1.senseIndex, 1);
      expect(detailSense1.totalSenses, 2);
      expect(detailSense1.senses.length, 2);
      expect(detailSense1.senses[0].meaningJa, '本');
      expect(detailSense1.senses[0].chapter, isNotNull);
      expect(detailSense1.senses[1].meaningJa, '予約する');
      expect(detailSense1.senses[1].chapter, isNotNull);
    });

    test('Independent retention score tracking per sense', () async {
      final sampleSenseData = [
        {
          'word': 'like',
          'senseIndex': '1',
          'totalSenses': '2',
          'CEFR': 'A1',
          'Japanese': '好む',
          'partOfSpeech': 'verb',
        },
        {
          'word': 'like',
          'senseIndex': '2',
          'totalSenses': '2',
          'CEFR': 'A2',
          'Japanese': '〜のような',
          'partOfSpeech': 'preposition',
        },
      ];

      await db.insertRawWords(sampleSenseData);
      final senses = await db.getAllSensesForWord('like');
      final sense1Id = senses[0].id;

      // Update quiz result for sense 1 only (perfect answer -> +10pt)
      await db.updateWordQuizResult(
        id: sense1Id,
        dropProgress: 0.1,
        isCorrect: true,
      );

      final updatedSenses = await db.getAllSensesForWord('like');
      expect(updatedSenses[0].retentionPoint, greaterThan(0));
      expect(updatedSenses[1].retentionPoint, 0); // Sense 2 remains 0
    });
  });
}
