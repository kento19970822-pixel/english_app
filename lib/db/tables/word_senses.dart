// コード管理番号: VER-20260827-10
import 'package:drift/drift.dart';
import 'words.dart';

/// 語義マスターテーブル (3NF 第3正規化)
/// 1つの単語（Words）に対して複数の語義・品詞・例文をリレーショナル管理
class WordSenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId => integer().references(Words, #id)();
  IntColumn get senseIndex => integer().withDefault(const Constant(1))(); // 1, 2, 3...
  TextColumn get partOfSpeech => text().withDefault(const Constant(''))(); // 名, 動, 形, 副, 前, 接...
  TextColumn get japanese => text()(); // 語義ごとの日本語訳
  TextColumn get cefr => text().withDefault(const Constant('A1'))(); // A1, A2, B1, B2, C1, C2
  TextColumn get example => text().nullable()(); // 英語例文
  TextColumn get exampleJp => text().nullable()(); // 例文日本語訳
  TextColumn get collocations => text().nullable()(); // 連語・コロケーション表現
}
