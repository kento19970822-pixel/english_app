// コード管理番号: VER-20260827-08
import '../db/app_database.dart';

/// 単語帳セクショングループデータモデル
class WordSection {
  final String key;
  final String title;
  final String? subtitle;
  final List<Word> words;
  final int memorizedCount;

  const WordSection({
    required this.key,
    required this.title,
    this.subtitle,
    required this.words,
    required this.memorizedCount,
  });
}
