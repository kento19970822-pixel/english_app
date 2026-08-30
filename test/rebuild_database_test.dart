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

  group('Database Rebuild from CSV Tests', () {
    test('rebuildDatabaseFromCsv parses and inserts all words smoothly without errors', () async {
      const sampleCsv = '''word,senseIndex,totalSenses,CEFR,Japanese,partOfSpeech,phonetic,category,Example,Example_JP,collocations,baseForm
apple,1,1,A1,りんご,noun,/ˈæpəl/,General,I ate an apple.,私はりんごを食べた。,,
banana,1,1,A1,バナナ,noun,/bəˈnænə/,General,Monkeys like bananas.,猿はバナナが好きだ。,,
flat,1,2,A1,平らな,adjective,/flˈæt/,General,The table is flat.,テーブルは平らだ。,,
flat,2,2,A2,アパート,noun,/flˈæt/,General,They live in a flat.,彼らはアパートに住んでいる。,,
''';

      final count = await db.rebuildDatabaseFromCsv(sampleCsv);
      expect(count, equals(4));

      final allWords = await db.getAllWords();
      expect(allWords.length, equals(4));

      final flats = allWords.where((w) => w.english == 'flat').toList();
      expect(flats.length, equals(2));
      expect(flats[0].senseIndex, equals(1));
      expect(flats[0].totalSenses, equals(2));
      expect(flats[1].senseIndex, equals(2));
      expect(flats[1].totalSenses, equals(2));

      // 3NF WordSenses テーブルにも正しく登録されていること
      final wordSensesList = await db.select(db.wordSenses).get();
      expect(wordSensesList.length, equals(4));
    });
  });
}
