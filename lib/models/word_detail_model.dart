// コード管理番号: VER-20260827-02
import 'dart:convert';
import '../db/app_database.dart';

/// 語義（Sense）データモデル
class WordSense {
  final int senseId;
  final String partOfSpeech; // '名', '動', '形', '副', '前', etc.
  final String meaningJa;
  final String cefr;
  final int? chapter;
  final String? exampleEn;
  final String? exampleJa;

  WordSense({
    required this.senseId,
    required this.partOfSpeech,
    required this.meaningJa,
    required this.cefr,
    this.chapter,
    this.exampleEn,
    this.exampleJa,
  });

  factory WordSense.fromJson(Map<String, dynamic> json) {
    return WordSense(
      senseId: json['sense_id'] as int? ?? 1,
      partOfSpeech: json['part_of_speech'] as String? ?? '名',
      meaningJa: json['meaning_ja'] as String? ?? '',
      cefr: json['cefr'] as String? ?? 'A1',
      chapter: json['chapter'] as int?,
      exampleEn: json['example_en'] as String?,
      exampleJa: json['example_ja'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'sense_id': senseId,
        'part_of_speech': partOfSpeech,
        'meaning_ja': meaningJa,
        'cefr': cefr,
        if (chapter != null) 'chapter': chapter,
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
  final int senseIndex;
  final int totalSenses;
  final String? wordGroup;
  final List<WordSense> senses;
  final List<String> collocations;
  final String? baseForm;
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
    this.senseIndex = 1,
    this.totalSenses = 1,
    this.wordGroup,
    required this.senses,
    required this.collocations,
    this.baseForm,
    this.isFavorite = false,
    this.isMemorized = false,
    this.isRestricted = false,
    this.retentionPoint = 0,
    this.pointDecreasedTotal = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.lastStudiedAt,
  });

  factory WordDetail.fromWordWithSiblings(Word word, List<Word> siblingSenses) {
    List<WordSense> senses = [];
    if (siblingSenses.isNotEmpty) {
      senses = siblingSenses.map((s) {
        final p = s.partOfSpeech.isNotEmpty
            ? s.partOfSpeech
            : AppDatabase.detectPartOfSpeech(s.japanese);
        return WordSense(
          senseId: s.senseIndex,
          partOfSpeech: p,
          meaningJa: s.japanese,
          cefr: s.cefr,
          chapter: s.chapter,
          exampleEn: s.example,
          exampleJa: s.exampleJp,
        );
      }).toList();
    }

    return _fromWordInternal(word, customSenses: senses);
  }

  factory WordDetail.fromWord(Word word) {
    return _fromWordInternal(word);
  }

  static WordDetail _fromWordInternal(Word word, {List<WordSense>? customSenses}) {
    List<WordSense> parsedSenses = customSenses ?? [];

    if (parsedSenses.isEmpty) {
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
        parsedSenses = [
          WordSense(
            senseId: word.senseIndex,
            partOfSpeech: word.partOfSpeech.isNotEmpty
                ? word.partOfSpeech
                : AppDatabase.detectPartOfSpeech(word.japanese),
            meaningJa: word.japanese,
            cefr: word.cefr,
            chapter: word.chapter,
            exampleEn: word.example,
            exampleJa: word.exampleJp,
          ),
        ];
      }
    }

    // 重複語義の確実な排除 (品詞 + 日本語意味 + 例文)
    final List<WordSense> uniqueSenses = [];
    final Set<String> seenSenseKeys = {};
    for (final s in parsedSenses) {
      final key = '${s.partOfSpeech.trim()}|${s.meaningJa.trim()}|${s.exampleEn?.trim() ?? ''}';
      if (!seenSenseKeys.contains(key)) {
        seenSenseKeys.add(key);
        uniqueSenses.add(WordSense(
          senseId: uniqueSenses.length + 1,
          partOfSpeech: s.partOfSpeech,
          meaningJa: s.meaningJa,
          cefr: s.cefr,
          chapter: s.chapter,
          exampleEn: s.exampleEn,
          exampleJa: s.exampleJa,
        ));
      }
    }
    parsedSenses = uniqueSenses;

    List<String> parsedCollocations = [];
    if (word.collocations != null && word.collocations!.isNotEmpty) {
      final raw = word.collocations!.trim();
      bool jsonParsed = false;
      if (raw.startsWith('[') && raw.endsWith(']')) {
        try {
          final decoded = jsonDecode(raw) as List<dynamic>;
          for (final item in decoded) {
            if (item is Map) {
              final phrase = item['phrase']?.toString().trim() ?? '';
              final meaning = item['meaning']?.toString().trim() ?? '';
              if (phrase.isNotEmpty) {
                parsedCollocations.add(meaning.isNotEmpty ? '$phrase ($meaning)' : phrase);
              }
            } else if (item != null) {
              final s = item.toString().trim();
              if (s.isNotEmpty) parsedCollocations.add(s);
            }
          }
          if (parsedCollocations.isNotEmpty) jsonParsed = true;
        } catch (_) {}
      }

      if (!jsonParsed) {
        final pairRegex = RegExp(r'\{[^{}]*phrase\s*:\s*([^,}]+)\s*,\s*meaning\s*:\s*([^}]+)\}');
        final matches = pairRegex.allMatches(raw);
        if (matches.isNotEmpty) {
          for (final m in matches) {
            final p = m.group(1)?.trim() ?? '';
            final mn = m.group(2)?.trim() ?? '';
            if (p.isNotEmpty) {
              parsedCollocations.add(mn.isNotEmpty ? '$p ($mn)' : p);
            }
          }
        }
      }

      if (parsedCollocations.isEmpty) {
        final cleaned = raw.replaceAll(RegExp(r'[\[\]"]'), '');
        final parts = cleaned.split(RegExp(r'[\n;]'));
        for (final p in parts) {
          final trimmed = p.trim();
          if (trimmed.isNotEmpty) {
            parsedCollocations.add(trimmed);
          }
        }
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
      primaryMeaningJa: word.japanese,
      cefr: word.cefr,
      senseIndex: word.senseIndex,
      totalSenses: word.totalSenses,
      wordGroup: word.wordGroup,
      senses: parsedSenses,
      collocations: parsedCollocations,
      baseForm: word.baseForm,
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
