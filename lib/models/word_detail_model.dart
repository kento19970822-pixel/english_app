// コード管理番号: VER-20260827-01
import 'dart:convert';
import '../db/app_database.dart';

/// 語義（Sense）データモデル
class WordSense {
  final int senseId;
  final String partOfSpeech; // '名', '動', '形', '副', '前', etc.
  final String meaningJa;
  final String cefr;
  final String? exampleEn;
  final String? exampleJa;

  WordSense({
    required this.senseId,
    required this.partOfSpeech,
    required this.meaningJa,
    required this.cefr,
    this.exampleEn,
    this.exampleJa,
  });

  factory WordSense.fromJson(Map<String, dynamic> json) {
    return WordSense(
      senseId: json['sense_id'] as int? ?? 1,
      partOfSpeech: json['part_of_speech'] as String? ?? '名',
      meaningJa: json['meaning_ja'] as String? ?? '',
      cefr: json['cefr'] as String? ?? 'A1',
      exampleEn: json['example_en'] as String?,
      exampleJa: json['example_ja'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'sense_id': senseId,
        'part_of_speech': partOfSpeech,
        'meaning_ja': meaningJa,
        'cefr': cefr,
        'example_en': exampleEn,
        'example_ja': exampleJa,
      };
}

/// 単語詳細表示・ドメイン操作用モデル
class WordDetail {
  final int id;
  final String english;
  final String? phonetic;
  final String category;
  final int chapter;
  final int level;
  final String primaryPos;
  final String primaryMeaningJa;
  final String cefr;
  final List<WordSense> senses;
  final List<String> collocations;
  final bool isFavorite;
  final bool isMemorized;
  final bool isRestricted;
  final int retentionPoint;
  final int pointDecreasedTotal;
  final int correctCount;
  final int wrongCount;
  final DateTime? lastStudiedAt;

  WordDetail({
    required this.id,
    required this.english,
    this.phonetic,
    required this.category,
    required this.chapter,
    required this.level,
    required this.primaryPos,
    required this.primaryMeaningJa,
    required this.cefr,
    required this.senses,
    required this.collocations,
    this.isFavorite = false,
    this.isMemorized = false,
    this.isRestricted = false,
    this.retentionPoint = 0,
    this.pointDecreasedTotal = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.lastStudiedAt,
  });

  factory WordDetail.fromWord(Word word) {
    List<WordSense> parsedSenses = [];

    if (word.otherMeanings != null && word.otherMeanings!.isNotEmpty) {
      try {
        final decoded = jsonDecode(word.otherMeanings!) as List<dynamic>;
        parsedSenses = decoded
            .map((e) => WordSense.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        parsedSenses = [];
      }
    }

    if (parsedSenses.isEmpty) {
      // JSONがない場合は第1語義から生成
      parsedSenses = [
        WordSense(
          senseId: 1,
          partOfSpeech: word.partOfSpeech.isNotEmpty
              ? word.partOfSpeech
              : AppDatabase.detectPartOfSpeech(word.japanese),
          meaningJa: word.japanese,
          cefr: word.cefr,
          exampleEn: word.example,
          exampleJa: word.exampleJp,
        ),
      ];
    }

    List<String> parsedCollocations = [];
    if (word.collocations != null && word.collocations!.isNotEmpty) {
      final raw = word.collocations!.trim();
      if (raw.startsWith('[') && raw.endsWith(']')) {
        try {
          final decoded = jsonDecode(raw) as List<dynamic>;
          parsedCollocations = decoded
              .map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList();
        } catch (_) {
          parsedCollocations = [];
        }
      }
      if (parsedCollocations.isEmpty) {
        parsedCollocations = raw
            .split(RegExp(r'[,、\n]'))
            .map((s) => s.replaceAll(RegExp(r'[\[\]"]'), '').trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }

    final pos = word.partOfSpeech.isNotEmpty
        ? word.partOfSpeech
        : (parsedSenses.isNotEmpty
            ? parsedSenses.first.partOfSpeech
            : AppDatabase.detectPartOfSpeech(word.japanese));

    return WordDetail(
      id: word.id,
      english: word.english,
      phonetic: word.phonetic,
      category: word.category,
      chapter: word.chapter,
      level: word.level,
      primaryPos: pos,
      primaryMeaningJa: parsedSenses.isNotEmpty
          ? parsedSenses.first.meaningJa
          : word.japanese,
      cefr: word.cefr,
      senses: parsedSenses,
      collocations: parsedCollocations,
      isFavorite: word.isFavorite,
      isMemorized: word.isMemorized,
      isRestricted: word.isRestricted,
      retentionPoint: word.retentionPoint,
      pointDecreasedTotal: word.pointDecreasedTotal,
      correctCount: word.correctCount,
      wrongCount: word.wrongCount,
      lastStudiedAt: word.lastStudiedAt,
    );
  }
}
