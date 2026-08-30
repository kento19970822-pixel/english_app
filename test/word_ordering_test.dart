import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:english_app/db/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Word Ordering & Interleaving Tests', () {
    test('Base forms appear before inflected/irregular forms in interleaved database order', () async {
      // 派生形 (teeth) を原形 (tooth) より先に渡しても、原形が先に出現すること
      await db.insertRawWords([
        {
          'word': 'teeth',
          'Japanese': '歯（複数形）',
          'CEFR': 'A1',
          'partOfSpeech': 'noun',
          'baseForm': 'tooth',
          'senseIndex': '1',
          'totalSenses': '1',
        },
        {
          'word': 'tooth',
          'Japanese': '歯',
          'CEFR': 'A1',
          'partOfSpeech': 'noun',
          'baseForm': 'tooth',
          'senseIndex': '1',
          'totalSenses': '1',
        },
        {
          'word': 'went',
          'Japanese': '行った（過去形）',
          'CEFR': 'A1',
          'partOfSpeech': 'verb',
          'baseForm': 'go',
          'senseIndex': '1',
          'totalSenses': '1',
        },
        {
          'word': 'go',
          'Japanese': '行く',
          'CEFR': 'A1',
          'partOfSpeech': 'verb',
          'baseForm': 'go',
          'senseIndex': '1',
          'totalSenses': '1',
        },
      ]);

      final allWords = await db.getAllWords();
      expect(allWords.length, equals(4));

      // 'tooth' のインデックスは 'teeth' より前
      final toothIndex = allWords.indexWhere((w) => w.english == 'tooth');
      final teethIndex = allWords.indexWhere((w) => w.english == 'teeth');
      expect(toothIndex, isNonNegative);
      expect(teethIndex, isNonNegative);
      expect(toothIndex < teethIndex, isTrue, reason: 'tooth (base form) must appear before teeth');

      // 'go' のインデックスは 'went' より前
      final goIndex = allWords.indexWhere((w) => w.english == 'go');
      final wentIndex = allWords.indexWhere((w) => w.english == 'went');
      expect(goIndex, isNonNegative);
      expect(wentIndex, isNonNegative);
      expect(goIndex < wentIndex, isTrue, reason: 'go (base form) must appear before went');
    });
  });
}
