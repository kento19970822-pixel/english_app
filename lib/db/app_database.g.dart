// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _englishMeta = const VerificationMeta(
    'english',
  );
  @override
  late final GeneratedColumn<String> english = GeneratedColumn<String>(
    'english',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _japaneseMeta = const VerificationMeta(
    'japanese',
  );
  @override
  late final GeneratedColumn<String> japanese = GeneratedColumn<String>(
    'japanese',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cefrMeta = const VerificationMeta('cefr');
  @override
  late final GeneratedColumn<String> cefr = GeneratedColumn<String>(
    'cefr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('A1'),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _phoneticMeta = const VerificationMeta(
    'phonetic',
  );
  @override
  late final GeneratedColumn<String> phonetic = GeneratedColumn<String>(
    'phonetic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('General'),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _exampleMeta = const VerificationMeta(
    'example',
  );
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
    'example',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exampleJpMeta = const VerificationMeta(
    'exampleJp',
  );
  @override
  late final GeneratedColumn<String> exampleJp = GeneratedColumn<String>(
    'example_jp',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partOfSpeechMeta = const VerificationMeta(
    'partOfSpeech',
  );
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
    'part_of_speech',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _collocationsMeta = const VerificationMeta(
    'collocations',
  );
  @override
  late final GeneratedColumn<String> collocations = GeneratedColumn<String>(
    'collocations',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _otherMeaningsMeta = const VerificationMeta(
    'otherMeanings',
  );
  @override
  late final GeneratedColumn<String> otherMeanings = GeneratedColumn<String>(
    'other_meanings',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retentionPointMeta = const VerificationMeta(
    'retentionPoint',
  );
  @override
  late final GeneratedColumn<int> retentionPoint = GeneratedColumn<int>(
    'retention_point',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pointDecreasedTotalMeta =
      const VerificationMeta('pointDecreasedTotal');
  @override
  late final GeneratedColumn<int> pointDecreasedTotal = GeneratedColumn<int>(
    'point_decreased_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isMemorizedMeta = const VerificationMeta(
    'isMemorized',
  );
  @override
  late final GeneratedColumn<bool> isMemorized = GeneratedColumn<bool>(
    'is_memorized',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_memorized" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isRestrictedMeta = const VerificationMeta(
    'isRestricted',
  );
  @override
  late final GeneratedColumn<bool> isRestricted = GeneratedColumn<bool>(
    'is_restricted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_restricted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wrongCountMeta = const VerificationMeta(
    'wrongCount',
  );
  @override
  late final GeneratedColumn<int> wrongCount = GeneratedColumn<int>(
    'wrong_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastStudiedAtMeta = const VerificationMeta(
    'lastStudiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastStudiedAt =
      GeneratedColumn<DateTime>(
        'last_studied_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastRestrictedDateMeta =
      const VerificationMeta('lastRestrictedDate');
  @override
  late final GeneratedColumn<DateTime> lastRestrictedDate =
      GeneratedColumn<DateTime>(
        'last_restricted_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    english,
    japanese,
    cefr,
    level,
    chapter,
    phonetic,
    category,
    isFavorite,
    example,
    exampleJp,
    partOfSpeech,
    collocations,
    otherMeanings,
    retentionPoint,
    pointDecreasedTotal,
    isMemorized,
    isRestricted,
    correctCount,
    wrongCount,
    lastStudiedAt,
    lastRestrictedDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<Word> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('english')) {
      context.handle(
        _englishMeta,
        english.isAcceptableOrUnknown(data['english']!, _englishMeta),
      );
    } else if (isInserting) {
      context.missing(_englishMeta);
    }
    if (data.containsKey('japanese')) {
      context.handle(
        _japaneseMeta,
        japanese.isAcceptableOrUnknown(data['japanese']!, _japaneseMeta),
      );
    } else if (isInserting) {
      context.missing(_japaneseMeta);
    }
    if (data.containsKey('cefr')) {
      context.handle(
        _cefrMeta,
        cefr.isAcceptableOrUnknown(data['cefr']!, _cefrMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    }
    if (data.containsKey('phonetic')) {
      context.handle(
        _phoneticMeta,
        phonetic.isAcceptableOrUnknown(data['phonetic']!, _phoneticMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('example')) {
      context.handle(
        _exampleMeta,
        example.isAcceptableOrUnknown(data['example']!, _exampleMeta),
      );
    }
    if (data.containsKey('example_jp')) {
      context.handle(
        _exampleJpMeta,
        exampleJp.isAcceptableOrUnknown(data['example_jp']!, _exampleJpMeta),
      );
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
        _partOfSpeechMeta,
        partOfSpeech.isAcceptableOrUnknown(
          data['part_of_speech']!,
          _partOfSpeechMeta,
        ),
      );
    }
    if (data.containsKey('collocations')) {
      context.handle(
        _collocationsMeta,
        collocations.isAcceptableOrUnknown(
          data['collocations']!,
          _collocationsMeta,
        ),
      );
    }
    if (data.containsKey('other_meanings')) {
      context.handle(
        _otherMeaningsMeta,
        otherMeanings.isAcceptableOrUnknown(
          data['other_meanings']!,
          _otherMeaningsMeta,
        ),
      );
    }
    if (data.containsKey('retention_point')) {
      context.handle(
        _retentionPointMeta,
        retentionPoint.isAcceptableOrUnknown(
          data['retention_point']!,
          _retentionPointMeta,
        ),
      );
    }
    if (data.containsKey('point_decreased_total')) {
      context.handle(
        _pointDecreasedTotalMeta,
        pointDecreasedTotal.isAcceptableOrUnknown(
          data['point_decreased_total']!,
          _pointDecreasedTotalMeta,
        ),
      );
    }
    if (data.containsKey('is_memorized')) {
      context.handle(
        _isMemorizedMeta,
        isMemorized.isAcceptableOrUnknown(
          data['is_memorized']!,
          _isMemorizedMeta,
        ),
      );
    }
    if (data.containsKey('is_restricted')) {
      context.handle(
        _isRestrictedMeta,
        isRestricted.isAcceptableOrUnknown(
          data['is_restricted']!,
          _isRestrictedMeta,
        ),
      );
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    }
    if (data.containsKey('wrong_count')) {
      context.handle(
        _wrongCountMeta,
        wrongCount.isAcceptableOrUnknown(data['wrong_count']!, _wrongCountMeta),
      );
    }
    if (data.containsKey('last_studied_at')) {
      context.handle(
        _lastStudiedAtMeta,
        lastStudiedAt.isAcceptableOrUnknown(
          data['last_studied_at']!,
          _lastStudiedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_restricted_date')) {
      context.handle(
        _lastRestrictedDateMeta,
        lastRestrictedDate.isAcceptableOrUnknown(
          data['last_restricted_date']!,
          _lastRestrictedDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      english: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english'],
      )!,
      japanese: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}japanese'],
      )!,
      cefr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cefr'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      phonetic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phonetic'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      example: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example'],
      ),
      exampleJp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_jp'],
      ),
      partOfSpeech: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_of_speech'],
      )!,
      collocations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collocations'],
      ),
      otherMeanings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}other_meanings'],
      ),
      retentionPoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retention_point'],
      )!,
      pointDecreasedTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}point_decreased_total'],
      )!,
      isMemorized: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_memorized'],
      )!,
      isRestricted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_restricted'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      wrongCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wrong_count'],
      )!,
      lastStudiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_studied_at'],
      ),
      lastRestrictedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_restricted_date'],
      ),
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends DataClass implements Insertable<Word> {
  final int id;
  final String english;
  final String japanese;
  final String cefr;
  final int level;
  final int chapter;
  final String? phonetic;
  final String category;
  final bool isFavorite;
  final String? example;
  final String? exampleJp;
  final String partOfSpeech;
  final String? collocations;
  final String? otherMeanings;
  final int retentionPoint;
  final int pointDecreasedTotal;
  final bool isMemorized;
  final bool isRestricted;
  final int correctCount;
  final int wrongCount;
  final DateTime? lastStudiedAt;
  final DateTime? lastRestrictedDate;
  const Word({
    required this.id,
    required this.english,
    required this.japanese,
    required this.cefr,
    required this.level,
    required this.chapter,
    this.phonetic,
    required this.category,
    required this.isFavorite,
    this.example,
    this.exampleJp,
    required this.partOfSpeech,
    this.collocations,
    this.otherMeanings,
    required this.retentionPoint,
    required this.pointDecreasedTotal,
    required this.isMemorized,
    required this.isRestricted,
    required this.correctCount,
    required this.wrongCount,
    this.lastStudiedAt,
    this.lastRestrictedDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['english'] = Variable<String>(english);
    map['japanese'] = Variable<String>(japanese);
    map['cefr'] = Variable<String>(cefr);
    map['level'] = Variable<int>(level);
    map['chapter'] = Variable<int>(chapter);
    if (!nullToAbsent || phonetic != null) {
      map['phonetic'] = Variable<String>(phonetic);
    }
    map['category'] = Variable<String>(category);
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || example != null) {
      map['example'] = Variable<String>(example);
    }
    if (!nullToAbsent || exampleJp != null) {
      map['example_jp'] = Variable<String>(exampleJp);
    }
    map['part_of_speech'] = Variable<String>(partOfSpeech);
    if (!nullToAbsent || collocations != null) {
      map['collocations'] = Variable<String>(collocations);
    }
    if (!nullToAbsent || otherMeanings != null) {
      map['other_meanings'] = Variable<String>(otherMeanings);
    }
    map['retention_point'] = Variable<int>(retentionPoint);
    map['point_decreased_total'] = Variable<int>(pointDecreasedTotal);
    map['is_memorized'] = Variable<bool>(isMemorized);
    map['is_restricted'] = Variable<bool>(isRestricted);
    map['correct_count'] = Variable<int>(correctCount);
    map['wrong_count'] = Variable<int>(wrongCount);
    if (!nullToAbsent || lastStudiedAt != null) {
      map['last_studied_at'] = Variable<DateTime>(lastStudiedAt);
    }
    if (!nullToAbsent || lastRestrictedDate != null) {
      map['last_restricted_date'] = Variable<DateTime>(lastRestrictedDate);
    }
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      english: Value(english),
      japanese: Value(japanese),
      cefr: Value(cefr),
      level: Value(level),
      chapter: Value(chapter),
      phonetic: phonetic == null && nullToAbsent
          ? const Value.absent()
          : Value(phonetic),
      category: Value(category),
      isFavorite: Value(isFavorite),
      example: example == null && nullToAbsent
          ? const Value.absent()
          : Value(example),
      exampleJp: exampleJp == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleJp),
      partOfSpeech: Value(partOfSpeech),
      collocations: collocations == null && nullToAbsent
          ? const Value.absent()
          : Value(collocations),
      otherMeanings: otherMeanings == null && nullToAbsent
          ? const Value.absent()
          : Value(otherMeanings),
      retentionPoint: Value(retentionPoint),
      pointDecreasedTotal: Value(pointDecreasedTotal),
      isMemorized: Value(isMemorized),
      isRestricted: Value(isRestricted),
      correctCount: Value(correctCount),
      wrongCount: Value(wrongCount),
      lastStudiedAt: lastStudiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStudiedAt),
      lastRestrictedDate: lastRestrictedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRestrictedDate),
    );
  }

  factory Word.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<int>(json['id']),
      english: serializer.fromJson<String>(json['english']),
      japanese: serializer.fromJson<String>(json['japanese']),
      cefr: serializer.fromJson<String>(json['cefr']),
      level: serializer.fromJson<int>(json['level']),
      chapter: serializer.fromJson<int>(json['chapter']),
      phonetic: serializer.fromJson<String?>(json['phonetic']),
      category: serializer.fromJson<String>(json['category']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      example: serializer.fromJson<String?>(json['example']),
      exampleJp: serializer.fromJson<String?>(json['exampleJp']),
      partOfSpeech: serializer.fromJson<String>(json['partOfSpeech']),
      collocations: serializer.fromJson<String?>(json['collocations']),
      otherMeanings: serializer.fromJson<String?>(json['otherMeanings']),
      retentionPoint: serializer.fromJson<int>(json['retentionPoint']),
      pointDecreasedTotal: serializer.fromJson<int>(
        json['pointDecreasedTotal'],
      ),
      isMemorized: serializer.fromJson<bool>(json['isMemorized']),
      isRestricted: serializer.fromJson<bool>(json['isRestricted']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      wrongCount: serializer.fromJson<int>(json['wrongCount']),
      lastStudiedAt: serializer.fromJson<DateTime?>(json['lastStudiedAt']),
      lastRestrictedDate: serializer.fromJson<DateTime?>(
        json['lastRestrictedDate'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'english': serializer.toJson<String>(english),
      'japanese': serializer.toJson<String>(japanese),
      'cefr': serializer.toJson<String>(cefr),
      'level': serializer.toJson<int>(level),
      'chapter': serializer.toJson<int>(chapter),
      'phonetic': serializer.toJson<String?>(phonetic),
      'category': serializer.toJson<String>(category),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'example': serializer.toJson<String?>(example),
      'exampleJp': serializer.toJson<String?>(exampleJp),
      'partOfSpeech': serializer.toJson<String>(partOfSpeech),
      'collocations': serializer.toJson<String?>(collocations),
      'otherMeanings': serializer.toJson<String?>(otherMeanings),
      'retentionPoint': serializer.toJson<int>(retentionPoint),
      'pointDecreasedTotal': serializer.toJson<int>(pointDecreasedTotal),
      'isMemorized': serializer.toJson<bool>(isMemorized),
      'isRestricted': serializer.toJson<bool>(isRestricted),
      'correctCount': serializer.toJson<int>(correctCount),
      'wrongCount': serializer.toJson<int>(wrongCount),
      'lastStudiedAt': serializer.toJson<DateTime?>(lastStudiedAt),
      'lastRestrictedDate': serializer.toJson<DateTime?>(lastRestrictedDate),
    };
  }

  Word copyWith({
    int? id,
    String? english,
    String? japanese,
    String? cefr,
    int? level,
    int? chapter,
    Value<String?> phonetic = const Value.absent(),
    String? category,
    bool? isFavorite,
    Value<String?> example = const Value.absent(),
    Value<String?> exampleJp = const Value.absent(),
    String? partOfSpeech,
    Value<String?> collocations = const Value.absent(),
    Value<String?> otherMeanings = const Value.absent(),
    int? retentionPoint,
    int? pointDecreasedTotal,
    bool? isMemorized,
    bool? isRestricted,
    int? correctCount,
    int? wrongCount,
    Value<DateTime?> lastStudiedAt = const Value.absent(),
    Value<DateTime?> lastRestrictedDate = const Value.absent(),
  }) => Word(
    id: id ?? this.id,
    english: english ?? this.english,
    japanese: japanese ?? this.japanese,
    cefr: cefr ?? this.cefr,
    level: level ?? this.level,
    chapter: chapter ?? this.chapter,
    phonetic: phonetic.present ? phonetic.value : this.phonetic,
    category: category ?? this.category,
    isFavorite: isFavorite ?? this.isFavorite,
    example: example.present ? example.value : this.example,
    exampleJp: exampleJp.present ? exampleJp.value : this.exampleJp,
    partOfSpeech: partOfSpeech ?? this.partOfSpeech,
    collocations: collocations.present ? collocations.value : this.collocations,
    otherMeanings: otherMeanings.present
        ? otherMeanings.value
        : this.otherMeanings,
    retentionPoint: retentionPoint ?? this.retentionPoint,
    pointDecreasedTotal: pointDecreasedTotal ?? this.pointDecreasedTotal,
    isMemorized: isMemorized ?? this.isMemorized,
    isRestricted: isRestricted ?? this.isRestricted,
    correctCount: correctCount ?? this.correctCount,
    wrongCount: wrongCount ?? this.wrongCount,
    lastStudiedAt: lastStudiedAt.present
        ? lastStudiedAt.value
        : this.lastStudiedAt,
    lastRestrictedDate: lastRestrictedDate.present
        ? lastRestrictedDate.value
        : this.lastRestrictedDate,
  );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      english: data.english.present ? data.english.value : this.english,
      japanese: data.japanese.present ? data.japanese.value : this.japanese,
      cefr: data.cefr.present ? data.cefr.value : this.cefr,
      level: data.level.present ? data.level.value : this.level,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      phonetic: data.phonetic.present ? data.phonetic.value : this.phonetic,
      category: data.category.present ? data.category.value : this.category,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      example: data.example.present ? data.example.value : this.example,
      exampleJp: data.exampleJp.present ? data.exampleJp.value : this.exampleJp,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      collocations: data.collocations.present
          ? data.collocations.value
          : this.collocations,
      otherMeanings: data.otherMeanings.present
          ? data.otherMeanings.value
          : this.otherMeanings,
      retentionPoint: data.retentionPoint.present
          ? data.retentionPoint.value
          : this.retentionPoint,
      pointDecreasedTotal: data.pointDecreasedTotal.present
          ? data.pointDecreasedTotal.value
          : this.pointDecreasedTotal,
      isMemorized: data.isMemorized.present
          ? data.isMemorized.value
          : this.isMemorized,
      isRestricted: data.isRestricted.present
          ? data.isRestricted.value
          : this.isRestricted,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      wrongCount: data.wrongCount.present
          ? data.wrongCount.value
          : this.wrongCount,
      lastStudiedAt: data.lastStudiedAt.present
          ? data.lastStudiedAt.value
          : this.lastStudiedAt,
      lastRestrictedDate: data.lastRestrictedDate.present
          ? data.lastRestrictedDate.value
          : this.lastRestrictedDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('english: $english, ')
          ..write('japanese: $japanese, ')
          ..write('cefr: $cefr, ')
          ..write('level: $level, ')
          ..write('chapter: $chapter, ')
          ..write('phonetic: $phonetic, ')
          ..write('category: $category, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('example: $example, ')
          ..write('exampleJp: $exampleJp, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('collocations: $collocations, ')
          ..write('otherMeanings: $otherMeanings, ')
          ..write('retentionPoint: $retentionPoint, ')
          ..write('pointDecreasedTotal: $pointDecreasedTotal, ')
          ..write('isMemorized: $isMemorized, ')
          ..write('isRestricted: $isRestricted, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('lastStudiedAt: $lastStudiedAt, ')
          ..write('lastRestrictedDate: $lastRestrictedDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    english,
    japanese,
    cefr,
    level,
    chapter,
    phonetic,
    category,
    isFavorite,
    example,
    exampleJp,
    partOfSpeech,
    collocations,
    otherMeanings,
    retentionPoint,
    pointDecreasedTotal,
    isMemorized,
    isRestricted,
    correctCount,
    wrongCount,
    lastStudiedAt,
    lastRestrictedDate,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.english == this.english &&
          other.japanese == this.japanese &&
          other.cefr == this.cefr &&
          other.level == this.level &&
          other.chapter == this.chapter &&
          other.phonetic == this.phonetic &&
          other.category == this.category &&
          other.isFavorite == this.isFavorite &&
          other.example == this.example &&
          other.exampleJp == this.exampleJp &&
          other.partOfSpeech == this.partOfSpeech &&
          other.collocations == this.collocations &&
          other.otherMeanings == this.otherMeanings &&
          other.retentionPoint == this.retentionPoint &&
          other.pointDecreasedTotal == this.pointDecreasedTotal &&
          other.isMemorized == this.isMemorized &&
          other.isRestricted == this.isRestricted &&
          other.correctCount == this.correctCount &&
          other.wrongCount == this.wrongCount &&
          other.lastStudiedAt == this.lastStudiedAt &&
          other.lastRestrictedDate == this.lastRestrictedDate);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<int> id;
  final Value<String> english;
  final Value<String> japanese;
  final Value<String> cefr;
  final Value<int> level;
  final Value<int> chapter;
  final Value<String?> phonetic;
  final Value<String> category;
  final Value<bool> isFavorite;
  final Value<String?> example;
  final Value<String?> exampleJp;
  final Value<String> partOfSpeech;
  final Value<String?> collocations;
  final Value<String?> otherMeanings;
  final Value<int> retentionPoint;
  final Value<int> pointDecreasedTotal;
  final Value<bool> isMemorized;
  final Value<bool> isRestricted;
  final Value<int> correctCount;
  final Value<int> wrongCount;
  final Value<DateTime?> lastStudiedAt;
  final Value<DateTime?> lastRestrictedDate;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.english = const Value.absent(),
    this.japanese = const Value.absent(),
    this.cefr = const Value.absent(),
    this.level = const Value.absent(),
    this.chapter = const Value.absent(),
    this.phonetic = const Value.absent(),
    this.category = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.example = const Value.absent(),
    this.exampleJp = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.collocations = const Value.absent(),
    this.otherMeanings = const Value.absent(),
    this.retentionPoint = const Value.absent(),
    this.pointDecreasedTotal = const Value.absent(),
    this.isMemorized = const Value.absent(),
    this.isRestricted = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.lastStudiedAt = const Value.absent(),
    this.lastRestrictedDate = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    required String english,
    required String japanese,
    this.cefr = const Value.absent(),
    this.level = const Value.absent(),
    this.chapter = const Value.absent(),
    this.phonetic = const Value.absent(),
    this.category = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.example = const Value.absent(),
    this.exampleJp = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.collocations = const Value.absent(),
    this.otherMeanings = const Value.absent(),
    this.retentionPoint = const Value.absent(),
    this.pointDecreasedTotal = const Value.absent(),
    this.isMemorized = const Value.absent(),
    this.isRestricted = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.lastStudiedAt = const Value.absent(),
    this.lastRestrictedDate = const Value.absent(),
  }) : english = Value(english),
       japanese = Value(japanese);
  static Insertable<Word> custom({
    Expression<int>? id,
    Expression<String>? english,
    Expression<String>? japanese,
    Expression<String>? cefr,
    Expression<int>? level,
    Expression<int>? chapter,
    Expression<String>? phonetic,
    Expression<String>? category,
    Expression<bool>? isFavorite,
    Expression<String>? example,
    Expression<String>? exampleJp,
    Expression<String>? partOfSpeech,
    Expression<String>? collocations,
    Expression<String>? otherMeanings,
    Expression<int>? retentionPoint,
    Expression<int>? pointDecreasedTotal,
    Expression<bool>? isMemorized,
    Expression<bool>? isRestricted,
    Expression<int>? correctCount,
    Expression<int>? wrongCount,
    Expression<DateTime>? lastStudiedAt,
    Expression<DateTime>? lastRestrictedDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (english != null) 'english': english,
      if (japanese != null) 'japanese': japanese,
      if (cefr != null) 'cefr': cefr,
      if (level != null) 'level': level,
      if (chapter != null) 'chapter': chapter,
      if (phonetic != null) 'phonetic': phonetic,
      if (category != null) 'category': category,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (example != null) 'example': example,
      if (exampleJp != null) 'example_jp': exampleJp,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (collocations != null) 'collocations': collocations,
      if (otherMeanings != null) 'other_meanings': otherMeanings,
      if (retentionPoint != null) 'retention_point': retentionPoint,
      if (pointDecreasedTotal != null)
        'point_decreased_total': pointDecreasedTotal,
      if (isMemorized != null) 'is_memorized': isMemorized,
      if (isRestricted != null) 'is_restricted': isRestricted,
      if (correctCount != null) 'correct_count': correctCount,
      if (wrongCount != null) 'wrong_count': wrongCount,
      if (lastStudiedAt != null) 'last_studied_at': lastStudiedAt,
      if (lastRestrictedDate != null)
        'last_restricted_date': lastRestrictedDate,
    });
  }

  WordsCompanion copyWith({
    Value<int>? id,
    Value<String>? english,
    Value<String>? japanese,
    Value<String>? cefr,
    Value<int>? level,
    Value<int>? chapter,
    Value<String?>? phonetic,
    Value<String>? category,
    Value<bool>? isFavorite,
    Value<String?>? example,
    Value<String?>? exampleJp,
    Value<String>? partOfSpeech,
    Value<String?>? collocations,
    Value<String?>? otherMeanings,
    Value<int>? retentionPoint,
    Value<int>? pointDecreasedTotal,
    Value<bool>? isMemorized,
    Value<bool>? isRestricted,
    Value<int>? correctCount,
    Value<int>? wrongCount,
    Value<DateTime?>? lastStudiedAt,
    Value<DateTime?>? lastRestrictedDate,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      english: english ?? this.english,
      japanese: japanese ?? this.japanese,
      cefr: cefr ?? this.cefr,
      level: level ?? this.level,
      chapter: chapter ?? this.chapter,
      phonetic: phonetic ?? this.phonetic,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      example: example ?? this.example,
      exampleJp: exampleJp ?? this.exampleJp,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      collocations: collocations ?? this.collocations,
      otherMeanings: otherMeanings ?? this.otherMeanings,
      retentionPoint: retentionPoint ?? this.retentionPoint,
      pointDecreasedTotal: pointDecreasedTotal ?? this.pointDecreasedTotal,
      isMemorized: isMemorized ?? this.isMemorized,
      isRestricted: isRestricted ?? this.isRestricted,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      lastRestrictedDate: lastRestrictedDate ?? this.lastRestrictedDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (english.present) {
      map['english'] = Variable<String>(english.value);
    }
    if (japanese.present) {
      map['japanese'] = Variable<String>(japanese.value);
    }
    if (cefr.present) {
      map['cefr'] = Variable<String>(cefr.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (phonetic.present) {
      map['phonetic'] = Variable<String>(phonetic.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (exampleJp.present) {
      map['example_jp'] = Variable<String>(exampleJp.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (collocations.present) {
      map['collocations'] = Variable<String>(collocations.value);
    }
    if (otherMeanings.present) {
      map['other_meanings'] = Variable<String>(otherMeanings.value);
    }
    if (retentionPoint.present) {
      map['retention_point'] = Variable<int>(retentionPoint.value);
    }
    if (pointDecreasedTotal.present) {
      map['point_decreased_total'] = Variable<int>(pointDecreasedTotal.value);
    }
    if (isMemorized.present) {
      map['is_memorized'] = Variable<bool>(isMemorized.value);
    }
    if (isRestricted.present) {
      map['is_restricted'] = Variable<bool>(isRestricted.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (wrongCount.present) {
      map['wrong_count'] = Variable<int>(wrongCount.value);
    }
    if (lastStudiedAt.present) {
      map['last_studied_at'] = Variable<DateTime>(lastStudiedAt.value);
    }
    if (lastRestrictedDate.present) {
      map['last_restricted_date'] = Variable<DateTime>(
        lastRestrictedDate.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('english: $english, ')
          ..write('japanese: $japanese, ')
          ..write('cefr: $cefr, ')
          ..write('level: $level, ')
          ..write('chapter: $chapter, ')
          ..write('phonetic: $phonetic, ')
          ..write('category: $category, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('example: $example, ')
          ..write('exampleJp: $exampleJp, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('collocations: $collocations, ')
          ..write('otherMeanings: $otherMeanings, ')
          ..write('retentionPoint: $retentionPoint, ')
          ..write('pointDecreasedTotal: $pointDecreasedTotal, ')
          ..write('isMemorized: $isMemorized, ')
          ..write('isRestricted: $isRestricted, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('lastStudiedAt: $lastStudiedAt, ')
          ..write('lastRestrictedDate: $lastRestrictedDate')
          ..write(')'))
        .toString();
  }
}

class $LearningHistoryTable extends LearningHistory
    with TableInfo<$LearningHistoryTable, LearningHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, score, level, playedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
    );
  }

  @override
  $LearningHistoryTable createAlias(String alias) {
    return $LearningHistoryTable(attachedDatabase, alias);
  }
}

class LearningHistoryData extends DataClass
    implements Insertable<LearningHistoryData> {
  final int id;
  final int score;
  final int level;
  final DateTime playedAt;
  const LearningHistoryData({
    required this.id,
    required this.score,
    required this.level,
    required this.playedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['score'] = Variable<int>(score);
    map['level'] = Variable<int>(level);
    map['played_at'] = Variable<DateTime>(playedAt);
    return map;
  }

  LearningHistoryCompanion toCompanion(bool nullToAbsent) {
    return LearningHistoryCompanion(
      id: Value(id),
      score: Value(score),
      level: Value(level),
      playedAt: Value(playedAt),
    );
  }

  factory LearningHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningHistoryData(
      id: serializer.fromJson<int>(json['id']),
      score: serializer.fromJson<int>(json['score']),
      level: serializer.fromJson<int>(json['level']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'score': serializer.toJson<int>(score),
      'level': serializer.toJson<int>(level),
      'playedAt': serializer.toJson<DateTime>(playedAt),
    };
  }

  LearningHistoryData copyWith({
    int? id,
    int? score,
    int? level,
    DateTime? playedAt,
  }) => LearningHistoryData(
    id: id ?? this.id,
    score: score ?? this.score,
    level: level ?? this.level,
    playedAt: playedAt ?? this.playedAt,
  );
  LearningHistoryData copyWithCompanion(LearningHistoryCompanion data) {
    return LearningHistoryData(
      id: data.id.present ? data.id.value : this.id,
      score: data.score.present ? data.score.value : this.score,
      level: data.level.present ? data.level.value : this.level,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningHistoryData(')
          ..write('id: $id, ')
          ..write('score: $score, ')
          ..write('level: $level, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, score, level, playedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningHistoryData &&
          other.id == this.id &&
          other.score == this.score &&
          other.level == this.level &&
          other.playedAt == this.playedAt);
}

class LearningHistoryCompanion extends UpdateCompanion<LearningHistoryData> {
  final Value<int> id;
  final Value<int> score;
  final Value<int> level;
  final Value<DateTime> playedAt;
  const LearningHistoryCompanion({
    this.id = const Value.absent(),
    this.score = const Value.absent(),
    this.level = const Value.absent(),
    this.playedAt = const Value.absent(),
  });
  LearningHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int score,
    required int level,
    this.playedAt = const Value.absent(),
  }) : score = Value(score),
       level = Value(level);
  static Insertable<LearningHistoryData> custom({
    Expression<int>? id,
    Expression<int>? score,
    Expression<int>? level,
    Expression<DateTime>? playedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (score != null) 'score': score,
      if (level != null) 'level': level,
      if (playedAt != null) 'played_at': playedAt,
    });
  }

  LearningHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? score,
    Value<int>? level,
    Value<DateTime>? playedAt,
  }) {
    return LearningHistoryCompanion(
      id: id ?? this.id,
      score: score ?? this.score,
      level: level ?? this.level,
      playedAt: playedAt ?? this.playedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningHistoryCompanion(')
          ..write('id: $id, ')
          ..write('score: $score, ')
          ..write('level: $level, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }
}

class $DailyRecordsTable extends DailyRecords
    with TableInfo<$DailyRecordsTable, DailyRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateStrMeta = const VerificationMeta(
    'dateStr',
  );
  @override
  late final GeneratedColumn<String> dateStr = GeneratedColumn<String>(
    'date_str',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memorizedCountMeta = const VerificationMeta(
    'memorizedCount',
  );
  @override
  late final GeneratedColumn<int> memorizedCount = GeneratedColumn<int>(
    'memorized_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _playedCountMeta = const VerificationMeta(
    'playedCount',
  );
  @override
  late final GeneratedColumn<int> playedCount = GeneratedColumn<int>(
    'played_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _appliedStampIdMeta = const VerificationMeta(
    'appliedStampId',
  );
  @override
  late final GeneratedColumn<String> appliedStampId = GeneratedColumn<String>(
    'applied_stamp_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    dateStr,
    memorizedCount,
    playedCount,
    appliedStampId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date_str')) {
      context.handle(
        _dateStrMeta,
        dateStr.isAcceptableOrUnknown(data['date_str']!, _dateStrMeta),
      );
    } else if (isInserting) {
      context.missing(_dateStrMeta);
    }
    if (data.containsKey('memorized_count')) {
      context.handle(
        _memorizedCountMeta,
        memorizedCount.isAcceptableOrUnknown(
          data['memorized_count']!,
          _memorizedCountMeta,
        ),
      );
    }
    if (data.containsKey('played_count')) {
      context.handle(
        _playedCountMeta,
        playedCount.isAcceptableOrUnknown(
          data['played_count']!,
          _playedCountMeta,
        ),
      );
    }
    if (data.containsKey('applied_stamp_id')) {
      context.handle(
        _appliedStampIdMeta,
        appliedStampId.isAcceptableOrUnknown(
          data['applied_stamp_id']!,
          _appliedStampIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dateStr};
  @override
  DailyRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyRecord(
      dateStr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_str'],
      )!,
      memorizedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}memorized_count'],
      )!,
      playedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}played_count'],
      )!,
      appliedStampId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}applied_stamp_id'],
      ),
    );
  }

  @override
  $DailyRecordsTable createAlias(String alias) {
    return $DailyRecordsTable(attachedDatabase, alias);
  }
}

class DailyRecord extends DataClass implements Insertable<DailyRecord> {
  /// 日付文字列 (`YYYY-MM-DD` を主キーとする)
  final String dateStr;

  /// その日に新しく暗記済みにした単語数
  final int memorizedCount;

  /// その日のゲームプレイ回数
  final int playedCount;

  /// その日カレンダーに押されたスタンプID (Null許容)
  final String? appliedStampId;
  const DailyRecord({
    required this.dateStr,
    required this.memorizedCount,
    required this.playedCount,
    this.appliedStampId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date_str'] = Variable<String>(dateStr);
    map['memorized_count'] = Variable<int>(memorizedCount);
    map['played_count'] = Variable<int>(playedCount);
    if (!nullToAbsent || appliedStampId != null) {
      map['applied_stamp_id'] = Variable<String>(appliedStampId);
    }
    return map;
  }

  DailyRecordsCompanion toCompanion(bool nullToAbsent) {
    return DailyRecordsCompanion(
      dateStr: Value(dateStr),
      memorizedCount: Value(memorizedCount),
      playedCount: Value(playedCount),
      appliedStampId: appliedStampId == null && nullToAbsent
          ? const Value.absent()
          : Value(appliedStampId),
    );
  }

  factory DailyRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyRecord(
      dateStr: serializer.fromJson<String>(json['dateStr']),
      memorizedCount: serializer.fromJson<int>(json['memorizedCount']),
      playedCount: serializer.fromJson<int>(json['playedCount']),
      appliedStampId: serializer.fromJson<String?>(json['appliedStampId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dateStr': serializer.toJson<String>(dateStr),
      'memorizedCount': serializer.toJson<int>(memorizedCount),
      'playedCount': serializer.toJson<int>(playedCount),
      'appliedStampId': serializer.toJson<String?>(appliedStampId),
    };
  }

  DailyRecord copyWith({
    String? dateStr,
    int? memorizedCount,
    int? playedCount,
    Value<String?> appliedStampId = const Value.absent(),
  }) => DailyRecord(
    dateStr: dateStr ?? this.dateStr,
    memorizedCount: memorizedCount ?? this.memorizedCount,
    playedCount: playedCount ?? this.playedCount,
    appliedStampId: appliedStampId.present
        ? appliedStampId.value
        : this.appliedStampId,
  );
  DailyRecord copyWithCompanion(DailyRecordsCompanion data) {
    return DailyRecord(
      dateStr: data.dateStr.present ? data.dateStr.value : this.dateStr,
      memorizedCount: data.memorizedCount.present
          ? data.memorizedCount.value
          : this.memorizedCount,
      playedCount: data.playedCount.present
          ? data.playedCount.value
          : this.playedCount,
      appliedStampId: data.appliedStampId.present
          ? data.appliedStampId.value
          : this.appliedStampId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyRecord(')
          ..write('dateStr: $dateStr, ')
          ..write('memorizedCount: $memorizedCount, ')
          ..write('playedCount: $playedCount, ')
          ..write('appliedStampId: $appliedStampId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(dateStr, memorizedCount, playedCount, appliedStampId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyRecord &&
          other.dateStr == this.dateStr &&
          other.memorizedCount == this.memorizedCount &&
          other.playedCount == this.playedCount &&
          other.appliedStampId == this.appliedStampId);
}

class DailyRecordsCompanion extends UpdateCompanion<DailyRecord> {
  final Value<String> dateStr;
  final Value<int> memorizedCount;
  final Value<int> playedCount;
  final Value<String?> appliedStampId;
  final Value<int> rowid;
  const DailyRecordsCompanion({
    this.dateStr = const Value.absent(),
    this.memorizedCount = const Value.absent(),
    this.playedCount = const Value.absent(),
    this.appliedStampId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyRecordsCompanion.insert({
    required String dateStr,
    this.memorizedCount = const Value.absent(),
    this.playedCount = const Value.absent(),
    this.appliedStampId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : dateStr = Value(dateStr);
  static Insertable<DailyRecord> custom({
    Expression<String>? dateStr,
    Expression<int>? memorizedCount,
    Expression<int>? playedCount,
    Expression<String>? appliedStampId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dateStr != null) 'date_str': dateStr,
      if (memorizedCount != null) 'memorized_count': memorizedCount,
      if (playedCount != null) 'played_count': playedCount,
      if (appliedStampId != null) 'applied_stamp_id': appliedStampId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyRecordsCompanion copyWith({
    Value<String>? dateStr,
    Value<int>? memorizedCount,
    Value<int>? playedCount,
    Value<String?>? appliedStampId,
    Value<int>? rowid,
  }) {
    return DailyRecordsCompanion(
      dateStr: dateStr ?? this.dateStr,
      memorizedCount: memorizedCount ?? this.memorizedCount,
      playedCount: playedCount ?? this.playedCount,
      appliedStampId: appliedStampId ?? this.appliedStampId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dateStr.present) {
      map['date_str'] = Variable<String>(dateStr.value);
    }
    if (memorizedCount.present) {
      map['memorized_count'] = Variable<int>(memorizedCount.value);
    }
    if (playedCount.present) {
      map['played_count'] = Variable<int>(playedCount.value);
    }
    if (appliedStampId.present) {
      map['applied_stamp_id'] = Variable<String>(appliedStampId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyRecordsCompanion(')
          ..write('dateStr: $dateStr, ')
          ..write('memorizedCount: $memorizedCount, ')
          ..write('playedCount: $playedCount, ')
          ..write('appliedStampId: $appliedStampId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StampsTable extends Stamps with TableInfo<$StampsTable, Stamp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StampsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<int> phase = GeneratedColumn<int>(
    'phase',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rarityMeta = const VerificationMeta('rarity');
  @override
  late final GeneratedColumn<String> rarity = GeneratedColumn<String>(
    'rarity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _colorPaletteIdMeta = const VerificationMeta(
    'colorPaletteId',
  );
  @override
  late final GeneratedColumn<int> colorPaletteId = GeneratedColumn<int>(
    'color_palette_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _patternIdMeta = const VerificationMeta(
    'patternId',
  );
  @override
  late final GeneratedColumn<int> patternId = GeneratedColumn<int>(
    'pattern_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _frameIdMeta = const VerificationMeta(
    'frameId',
  );
  @override
  late final GeneratedColumn<int> frameId = GeneratedColumn<int>(
    'frame_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _effectIdMeta = const VerificationMeta(
    'effectId',
  );
  @override
  late final GeneratedColumn<int> effectId = GeneratedColumn<int>(
    'effect_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _iconCodeMeta = const VerificationMeta(
    'iconCode',
  );
  @override
  late final GeneratedColumn<String> iconCode = GeneratedColumn<String>(
    'icon_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _conditionTypeMeta = const VerificationMeta(
    'conditionType',
  );
  @override
  late final GeneratedColumn<String> conditionType = GeneratedColumn<String>(
    'condition_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _conditionValueMeta = const VerificationMeta(
    'conditionValue',
  );
  @override
  late final GeneratedColumn<int> conditionValue = GeneratedColumn<int>(
    'condition_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isUnlockedMeta = const VerificationMeta(
    'isUnlocked',
  );
  @override
  late final GeneratedColumn<bool> isUnlocked = GeneratedColumn<bool>(
    'is_unlocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_unlocked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta(
    'unlockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
    'unlocked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    phase,
    name,
    rarity,
    isFavorite,
    colorPaletteId,
    patternId,
    frameId,
    effectId,
    description,
    iconCode,
    conditionType,
    conditionValue,
    isUnlocked,
    unlockedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stamps';
  @override
  VerificationContext validateIntegrity(
    Insertable<Stamp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('rarity')) {
      context.handle(
        _rarityMeta,
        rarity.isAcceptableOrUnknown(data['rarity']!, _rarityMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('color_palette_id')) {
      context.handle(
        _colorPaletteIdMeta,
        colorPaletteId.isAcceptableOrUnknown(
          data['color_palette_id']!,
          _colorPaletteIdMeta,
        ),
      );
    }
    if (data.containsKey('pattern_id')) {
      context.handle(
        _patternIdMeta,
        patternId.isAcceptableOrUnknown(data['pattern_id']!, _patternIdMeta),
      );
    }
    if (data.containsKey('frame_id')) {
      context.handle(
        _frameIdMeta,
        frameId.isAcceptableOrUnknown(data['frame_id']!, _frameIdMeta),
      );
    }
    if (data.containsKey('effect_id')) {
      context.handle(
        _effectIdMeta,
        effectId.isAcceptableOrUnknown(data['effect_id']!, _effectIdMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon_code')) {
      context.handle(
        _iconCodeMeta,
        iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta),
      );
    }
    if (data.containsKey('condition_type')) {
      context.handle(
        _conditionTypeMeta,
        conditionType.isAcceptableOrUnknown(
          data['condition_type']!,
          _conditionTypeMeta,
        ),
      );
    }
    if (data.containsKey('condition_value')) {
      context.handle(
        _conditionValueMeta,
        conditionValue.isAcceptableOrUnknown(
          data['condition_value']!,
          _conditionValueMeta,
        ),
      );
    }
    if (data.containsKey('is_unlocked')) {
      context.handle(
        _isUnlockedMeta,
        isUnlocked.isAcceptableOrUnknown(data['is_unlocked']!, _isUnlockedMeta),
      );
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
        _unlockedAtMeta,
        unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Stamp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Stamp(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phase'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      rarity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rarity'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      colorPaletteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_palette_id'],
      )!,
      patternId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pattern_id'],
      )!,
      frameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}frame_id'],
      )!,
      effectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}effect_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      iconCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_code'],
      )!,
      conditionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition_type'],
      )!,
      conditionValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}condition_value'],
      )!,
      isUnlocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_unlocked'],
      )!,
      unlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}unlocked_at'],
      ),
    );
  }

  @override
  $StampsTable createAlias(String alias) {
    return $StampsTable(attachedDatabase, alias);
  }
}

class Stamp extends DataClass implements Insertable<Stamp> {
  /// スタンプID (例: `stamp_p1_01`)
  final String id;

  /// 世代フェーズ (例: 1, 2, ...)
  final int phase;

  /// スタンプ名 (例: はじまりのフクロウ)
  final String name;

  /// レア度 (`normal`, `rare`, `super_rare`)
  final String rarity;

  /// 相棒胸バッジ用お気に入りフラグ (1つのみTRUE)
  final bool isFavorite;

  /// ドット絵カラーパレットID
  final int colorPaletteId;

  /// ドット絵モチーフパターンID
  final int patternId;

  /// スタンプ外枠フレームID (0:丸枠, 1:角丸四角, 2:切手ギザギザ, 3:二重枠, 4:王冠/エンブレム)
  final int frameId;

  /// 装飾エフェクトID (0:なし, 1:星粒子, 2:集中線, 3:大星+シャイン, 4:月桂樹)
  final int effectId;

  /// 説明・獲得条件文面 (例: 連続3日学習を達成する)
  final String description;

  /// 表示用アイコン識別子 / 互換用コード
  final String iconCode;

  /// 出現条件種別 (`none`, `streak_days`, `total_days`, `memorized_count`, `cleared_chapters`)
  final String conditionType;

  /// 条件閾値 (例: 連続3日なら 3)
  final int conditionValue;

  /// 獲得（ロック解除）フラグ
  final bool isUnlocked;

  /// 初回獲得日時
  final DateTime? unlockedAt;
  const Stamp({
    required this.id,
    required this.phase,
    required this.name,
    required this.rarity,
    required this.isFavorite,
    required this.colorPaletteId,
    required this.patternId,
    required this.frameId,
    required this.effectId,
    required this.description,
    required this.iconCode,
    required this.conditionType,
    required this.conditionValue,
    required this.isUnlocked,
    this.unlockedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['phase'] = Variable<int>(phase);
    map['name'] = Variable<String>(name);
    map['rarity'] = Variable<String>(rarity);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['color_palette_id'] = Variable<int>(colorPaletteId);
    map['pattern_id'] = Variable<int>(patternId);
    map['frame_id'] = Variable<int>(frameId);
    map['effect_id'] = Variable<int>(effectId);
    map['description'] = Variable<String>(description);
    map['icon_code'] = Variable<String>(iconCode);
    map['condition_type'] = Variable<String>(conditionType);
    map['condition_value'] = Variable<int>(conditionValue);
    map['is_unlocked'] = Variable<bool>(isUnlocked);
    if (!nullToAbsent || unlockedAt != null) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    }
    return map;
  }

  StampsCompanion toCompanion(bool nullToAbsent) {
    return StampsCompanion(
      id: Value(id),
      phase: Value(phase),
      name: Value(name),
      rarity: Value(rarity),
      isFavorite: Value(isFavorite),
      colorPaletteId: Value(colorPaletteId),
      patternId: Value(patternId),
      frameId: Value(frameId),
      effectId: Value(effectId),
      description: Value(description),
      iconCode: Value(iconCode),
      conditionType: Value(conditionType),
      conditionValue: Value(conditionValue),
      isUnlocked: Value(isUnlocked),
      unlockedAt: unlockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(unlockedAt),
    );
  }

  factory Stamp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Stamp(
      id: serializer.fromJson<String>(json['id']),
      phase: serializer.fromJson<int>(json['phase']),
      name: serializer.fromJson<String>(json['name']),
      rarity: serializer.fromJson<String>(json['rarity']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      colorPaletteId: serializer.fromJson<int>(json['colorPaletteId']),
      patternId: serializer.fromJson<int>(json['patternId']),
      frameId: serializer.fromJson<int>(json['frameId']),
      effectId: serializer.fromJson<int>(json['effectId']),
      description: serializer.fromJson<String>(json['description']),
      iconCode: serializer.fromJson<String>(json['iconCode']),
      conditionType: serializer.fromJson<String>(json['conditionType']),
      conditionValue: serializer.fromJson<int>(json['conditionValue']),
      isUnlocked: serializer.fromJson<bool>(json['isUnlocked']),
      unlockedAt: serializer.fromJson<DateTime?>(json['unlockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'phase': serializer.toJson<int>(phase),
      'name': serializer.toJson<String>(name),
      'rarity': serializer.toJson<String>(rarity),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'colorPaletteId': serializer.toJson<int>(colorPaletteId),
      'patternId': serializer.toJson<int>(patternId),
      'frameId': serializer.toJson<int>(frameId),
      'effectId': serializer.toJson<int>(effectId),
      'description': serializer.toJson<String>(description),
      'iconCode': serializer.toJson<String>(iconCode),
      'conditionType': serializer.toJson<String>(conditionType),
      'conditionValue': serializer.toJson<int>(conditionValue),
      'isUnlocked': serializer.toJson<bool>(isUnlocked),
      'unlockedAt': serializer.toJson<DateTime?>(unlockedAt),
    };
  }

  Stamp copyWith({
    String? id,
    int? phase,
    String? name,
    String? rarity,
    bool? isFavorite,
    int? colorPaletteId,
    int? patternId,
    int? frameId,
    int? effectId,
    String? description,
    String? iconCode,
    String? conditionType,
    int? conditionValue,
    bool? isUnlocked,
    Value<DateTime?> unlockedAt = const Value.absent(),
  }) => Stamp(
    id: id ?? this.id,
    phase: phase ?? this.phase,
    name: name ?? this.name,
    rarity: rarity ?? this.rarity,
    isFavorite: isFavorite ?? this.isFavorite,
    colorPaletteId: colorPaletteId ?? this.colorPaletteId,
    patternId: patternId ?? this.patternId,
    frameId: frameId ?? this.frameId,
    effectId: effectId ?? this.effectId,
    description: description ?? this.description,
    iconCode: iconCode ?? this.iconCode,
    conditionType: conditionType ?? this.conditionType,
    conditionValue: conditionValue ?? this.conditionValue,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    unlockedAt: unlockedAt.present ? unlockedAt.value : this.unlockedAt,
  );
  Stamp copyWithCompanion(StampsCompanion data) {
    return Stamp(
      id: data.id.present ? data.id.value : this.id,
      phase: data.phase.present ? data.phase.value : this.phase,
      name: data.name.present ? data.name.value : this.name,
      rarity: data.rarity.present ? data.rarity.value : this.rarity,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      colorPaletteId: data.colorPaletteId.present
          ? data.colorPaletteId.value
          : this.colorPaletteId,
      patternId: data.patternId.present ? data.patternId.value : this.patternId,
      frameId: data.frameId.present ? data.frameId.value : this.frameId,
      effectId: data.effectId.present ? data.effectId.value : this.effectId,
      description: data.description.present
          ? data.description.value
          : this.description,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
      conditionType: data.conditionType.present
          ? data.conditionType.value
          : this.conditionType,
      conditionValue: data.conditionValue.present
          ? data.conditionValue.value
          : this.conditionValue,
      isUnlocked: data.isUnlocked.present
          ? data.isUnlocked.value
          : this.isUnlocked,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Stamp(')
          ..write('id: $id, ')
          ..write('phase: $phase, ')
          ..write('name: $name, ')
          ..write('rarity: $rarity, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('colorPaletteId: $colorPaletteId, ')
          ..write('patternId: $patternId, ')
          ..write('frameId: $frameId, ')
          ..write('effectId: $effectId, ')
          ..write('description: $description, ')
          ..write('iconCode: $iconCode, ')
          ..write('conditionType: $conditionType, ')
          ..write('conditionValue: $conditionValue, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('unlockedAt: $unlockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    phase,
    name,
    rarity,
    isFavorite,
    colorPaletteId,
    patternId,
    frameId,
    effectId,
    description,
    iconCode,
    conditionType,
    conditionValue,
    isUnlocked,
    unlockedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Stamp &&
          other.id == this.id &&
          other.phase == this.phase &&
          other.name == this.name &&
          other.rarity == this.rarity &&
          other.isFavorite == this.isFavorite &&
          other.colorPaletteId == this.colorPaletteId &&
          other.patternId == this.patternId &&
          other.frameId == this.frameId &&
          other.effectId == this.effectId &&
          other.description == this.description &&
          other.iconCode == this.iconCode &&
          other.conditionType == this.conditionType &&
          other.conditionValue == this.conditionValue &&
          other.isUnlocked == this.isUnlocked &&
          other.unlockedAt == this.unlockedAt);
}

class StampsCompanion extends UpdateCompanion<Stamp> {
  final Value<String> id;
  final Value<int> phase;
  final Value<String> name;
  final Value<String> rarity;
  final Value<bool> isFavorite;
  final Value<int> colorPaletteId;
  final Value<int> patternId;
  final Value<int> frameId;
  final Value<int> effectId;
  final Value<String> description;
  final Value<String> iconCode;
  final Value<String> conditionType;
  final Value<int> conditionValue;
  final Value<bool> isUnlocked;
  final Value<DateTime?> unlockedAt;
  final Value<int> rowid;
  const StampsCompanion({
    this.id = const Value.absent(),
    this.phase = const Value.absent(),
    this.name = const Value.absent(),
    this.rarity = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.colorPaletteId = const Value.absent(),
    this.patternId = const Value.absent(),
    this.frameId = const Value.absent(),
    this.effectId = const Value.absent(),
    this.description = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.conditionType = const Value.absent(),
    this.conditionValue = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StampsCompanion.insert({
    required String id,
    this.phase = const Value.absent(),
    required String name,
    this.rarity = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.colorPaletteId = const Value.absent(),
    this.patternId = const Value.absent(),
    this.frameId = const Value.absent(),
    this.effectId = const Value.absent(),
    this.description = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.conditionType = const Value.absent(),
    this.conditionValue = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Stamp> custom({
    Expression<String>? id,
    Expression<int>? phase,
    Expression<String>? name,
    Expression<String>? rarity,
    Expression<bool>? isFavorite,
    Expression<int>? colorPaletteId,
    Expression<int>? patternId,
    Expression<int>? frameId,
    Expression<int>? effectId,
    Expression<String>? description,
    Expression<String>? iconCode,
    Expression<String>? conditionType,
    Expression<int>? conditionValue,
    Expression<bool>? isUnlocked,
    Expression<DateTime>? unlockedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (phase != null) 'phase': phase,
      if (name != null) 'name': name,
      if (rarity != null) 'rarity': rarity,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (colorPaletteId != null) 'color_palette_id': colorPaletteId,
      if (patternId != null) 'pattern_id': patternId,
      if (frameId != null) 'frame_id': frameId,
      if (effectId != null) 'effect_id': effectId,
      if (description != null) 'description': description,
      if (iconCode != null) 'icon_code': iconCode,
      if (conditionType != null) 'condition_type': conditionType,
      if (conditionValue != null) 'condition_value': conditionValue,
      if (isUnlocked != null) 'is_unlocked': isUnlocked,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StampsCompanion copyWith({
    Value<String>? id,
    Value<int>? phase,
    Value<String>? name,
    Value<String>? rarity,
    Value<bool>? isFavorite,
    Value<int>? colorPaletteId,
    Value<int>? patternId,
    Value<int>? frameId,
    Value<int>? effectId,
    Value<String>? description,
    Value<String>? iconCode,
    Value<String>? conditionType,
    Value<int>? conditionValue,
    Value<bool>? isUnlocked,
    Value<DateTime?>? unlockedAt,
    Value<int>? rowid,
  }) {
    return StampsCompanion(
      id: id ?? this.id,
      phase: phase ?? this.phase,
      name: name ?? this.name,
      rarity: rarity ?? this.rarity,
      isFavorite: isFavorite ?? this.isFavorite,
      colorPaletteId: colorPaletteId ?? this.colorPaletteId,
      patternId: patternId ?? this.patternId,
      frameId: frameId ?? this.frameId,
      effectId: effectId ?? this.effectId,
      description: description ?? this.description,
      iconCode: iconCode ?? this.iconCode,
      conditionType: conditionType ?? this.conditionType,
      conditionValue: conditionValue ?? this.conditionValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (phase.present) {
      map['phase'] = Variable<int>(phase.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rarity.present) {
      map['rarity'] = Variable<String>(rarity.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (colorPaletteId.present) {
      map['color_palette_id'] = Variable<int>(colorPaletteId.value);
    }
    if (patternId.present) {
      map['pattern_id'] = Variable<int>(patternId.value);
    }
    if (frameId.present) {
      map['frame_id'] = Variable<int>(frameId.value);
    }
    if (effectId.present) {
      map['effect_id'] = Variable<int>(effectId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<String>(iconCode.value);
    }
    if (conditionType.present) {
      map['condition_type'] = Variable<String>(conditionType.value);
    }
    if (conditionValue.present) {
      map['condition_value'] = Variable<int>(conditionValue.value);
    }
    if (isUnlocked.present) {
      map['is_unlocked'] = Variable<bool>(isUnlocked.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StampsCompanion(')
          ..write('id: $id, ')
          ..write('phase: $phase, ')
          ..write('name: $name, ')
          ..write('rarity: $rarity, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('colorPaletteId: $colorPaletteId, ')
          ..write('patternId: $patternId, ')
          ..write('frameId: $frameId, ')
          ..write('effectId: $effectId, ')
          ..write('description: $description, ')
          ..write('iconCode: $iconCode, ')
          ..write('conditionType: $conditionType, ')
          ..write('conditionValue: $conditionValue, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChapterProgressesTable extends ChapterProgresses
    with TableInfo<$ChapterProgressesTable, ChapterProgressesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChapterProgressesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isUnlockedMeta = const VerificationMeta(
    'isUnlocked',
  );
  @override
  late final GeneratedColumn<bool> isUnlocked = GeneratedColumn<bool>(
    'is_unlocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_unlocked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isClearedMeta = const VerificationMeta(
    'isCleared',
  );
  @override
  late final GeneratedColumn<bool> isCleared = GeneratedColumn<bool>(
    'is_cleared',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_cleared" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _memorizedRateMeta = const VerificationMeta(
    'memorizedRate',
  );
  @override
  late final GeneratedColumn<double> memorizedRate = GeneratedColumn<double>(
    'memorized_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _clearedAtMeta = const VerificationMeta(
    'clearedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clearedAt = GeneratedColumn<DateTime>(
    'cleared_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    chapter,
    level,
    isUnlocked,
    isCleared,
    memorizedRate,
    clearedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapter_progresses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChapterProgressesData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('is_unlocked')) {
      context.handle(
        _isUnlockedMeta,
        isUnlocked.isAcceptableOrUnknown(data['is_unlocked']!, _isUnlockedMeta),
      );
    }
    if (data.containsKey('is_cleared')) {
      context.handle(
        _isClearedMeta,
        isCleared.isAcceptableOrUnknown(data['is_cleared']!, _isClearedMeta),
      );
    }
    if (data.containsKey('memorized_rate')) {
      context.handle(
        _memorizedRateMeta,
        memorizedRate.isAcceptableOrUnknown(
          data['memorized_rate']!,
          _memorizedRateMeta,
        ),
      );
    }
    if (data.containsKey('cleared_at')) {
      context.handle(
        _clearedAtMeta,
        clearedAt.isAcceptableOrUnknown(data['cleared_at']!, _clearedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chapter};
  @override
  ChapterProgressesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChapterProgressesData(
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      isUnlocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_unlocked'],
      )!,
      isCleared: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_cleared'],
      )!,
      memorizedRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}memorized_rate'],
      )!,
      clearedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cleared_at'],
      ),
    );
  }

  @override
  $ChapterProgressesTable createAlias(String alias) {
    return $ChapterProgressesTable(attachedDatabase, alias);
  }
}

class ChapterProgressesData extends DataClass
    implements Insertable<ChapterProgressesData> {
  /// 通しチャプター番号 (1〜)
  final int chapter;

  /// 所属難易度レベル (1: 初級A1, 2: 初級A2, 3: 中級B1, 4: 中級B2, 5: 上級C1, 6: 上級C2)
  final int level;

  /// 解放フラグ (選択可能か)
  final bool isUnlocked;

  /// クリア済みフラグ (学習モードで暗記率90%超達成)
  final bool isCleared;

  /// 最新のチャプター内暗記フラグ率 (0.0〜100.0)
  final double memorizedRate;

  /// クリア達成日時
  final DateTime? clearedAt;
  const ChapterProgressesData({
    required this.chapter,
    required this.level,
    required this.isUnlocked,
    required this.isCleared,
    required this.memorizedRate,
    this.clearedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chapter'] = Variable<int>(chapter);
    map['level'] = Variable<int>(level);
    map['is_unlocked'] = Variable<bool>(isUnlocked);
    map['is_cleared'] = Variable<bool>(isCleared);
    map['memorized_rate'] = Variable<double>(memorizedRate);
    if (!nullToAbsent || clearedAt != null) {
      map['cleared_at'] = Variable<DateTime>(clearedAt);
    }
    return map;
  }

  ChapterProgressesCompanion toCompanion(bool nullToAbsent) {
    return ChapterProgressesCompanion(
      chapter: Value(chapter),
      level: Value(level),
      isUnlocked: Value(isUnlocked),
      isCleared: Value(isCleared),
      memorizedRate: Value(memorizedRate),
      clearedAt: clearedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(clearedAt),
    );
  }

  factory ChapterProgressesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChapterProgressesData(
      chapter: serializer.fromJson<int>(json['chapter']),
      level: serializer.fromJson<int>(json['level']),
      isUnlocked: serializer.fromJson<bool>(json['isUnlocked']),
      isCleared: serializer.fromJson<bool>(json['isCleared']),
      memorizedRate: serializer.fromJson<double>(json['memorizedRate']),
      clearedAt: serializer.fromJson<DateTime?>(json['clearedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chapter': serializer.toJson<int>(chapter),
      'level': serializer.toJson<int>(level),
      'isUnlocked': serializer.toJson<bool>(isUnlocked),
      'isCleared': serializer.toJson<bool>(isCleared),
      'memorizedRate': serializer.toJson<double>(memorizedRate),
      'clearedAt': serializer.toJson<DateTime?>(clearedAt),
    };
  }

  ChapterProgressesData copyWith({
    int? chapter,
    int? level,
    bool? isUnlocked,
    bool? isCleared,
    double? memorizedRate,
    Value<DateTime?> clearedAt = const Value.absent(),
  }) => ChapterProgressesData(
    chapter: chapter ?? this.chapter,
    level: level ?? this.level,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    isCleared: isCleared ?? this.isCleared,
    memorizedRate: memorizedRate ?? this.memorizedRate,
    clearedAt: clearedAt.present ? clearedAt.value : this.clearedAt,
  );
  ChapterProgressesData copyWithCompanion(ChapterProgressesCompanion data) {
    return ChapterProgressesData(
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      level: data.level.present ? data.level.value : this.level,
      isUnlocked: data.isUnlocked.present
          ? data.isUnlocked.value
          : this.isUnlocked,
      isCleared: data.isCleared.present ? data.isCleared.value : this.isCleared,
      memorizedRate: data.memorizedRate.present
          ? data.memorizedRate.value
          : this.memorizedRate,
      clearedAt: data.clearedAt.present ? data.clearedAt.value : this.clearedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChapterProgressesData(')
          ..write('chapter: $chapter, ')
          ..write('level: $level, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('isCleared: $isCleared, ')
          ..write('memorizedRate: $memorizedRate, ')
          ..write('clearedAt: $clearedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    chapter,
    level,
    isUnlocked,
    isCleared,
    memorizedRate,
    clearedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChapterProgressesData &&
          other.chapter == this.chapter &&
          other.level == this.level &&
          other.isUnlocked == this.isUnlocked &&
          other.isCleared == this.isCleared &&
          other.memorizedRate == this.memorizedRate &&
          other.clearedAt == this.clearedAt);
}

class ChapterProgressesCompanion
    extends UpdateCompanion<ChapterProgressesData> {
  final Value<int> chapter;
  final Value<int> level;
  final Value<bool> isUnlocked;
  final Value<bool> isCleared;
  final Value<double> memorizedRate;
  final Value<DateTime?> clearedAt;
  const ChapterProgressesCompanion({
    this.chapter = const Value.absent(),
    this.level = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.isCleared = const Value.absent(),
    this.memorizedRate = const Value.absent(),
    this.clearedAt = const Value.absent(),
  });
  ChapterProgressesCompanion.insert({
    this.chapter = const Value.absent(),
    this.level = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.isCleared = const Value.absent(),
    this.memorizedRate = const Value.absent(),
    this.clearedAt = const Value.absent(),
  });
  static Insertable<ChapterProgressesData> custom({
    Expression<int>? chapter,
    Expression<int>? level,
    Expression<bool>? isUnlocked,
    Expression<bool>? isCleared,
    Expression<double>? memorizedRate,
    Expression<DateTime>? clearedAt,
  }) {
    return RawValuesInsertable({
      if (chapter != null) 'chapter': chapter,
      if (level != null) 'level': level,
      if (isUnlocked != null) 'is_unlocked': isUnlocked,
      if (isCleared != null) 'is_cleared': isCleared,
      if (memorizedRate != null) 'memorized_rate': memorizedRate,
      if (clearedAt != null) 'cleared_at': clearedAt,
    });
  }

  ChapterProgressesCompanion copyWith({
    Value<int>? chapter,
    Value<int>? level,
    Value<bool>? isUnlocked,
    Value<bool>? isCleared,
    Value<double>? memorizedRate,
    Value<DateTime?>? clearedAt,
  }) {
    return ChapterProgressesCompanion(
      chapter: chapter ?? this.chapter,
      level: level ?? this.level,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCleared: isCleared ?? this.isCleared,
      memorizedRate: memorizedRate ?? this.memorizedRate,
      clearedAt: clearedAt ?? this.clearedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (isUnlocked.present) {
      map['is_unlocked'] = Variable<bool>(isUnlocked.value);
    }
    if (isCleared.present) {
      map['is_cleared'] = Variable<bool>(isCleared.value);
    }
    if (memorizedRate.present) {
      map['memorized_rate'] = Variable<double>(memorizedRate.value);
    }
    if (clearedAt.present) {
      map['cleared_at'] = Variable<DateTime>(clearedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChapterProgressesCompanion(')
          ..write('chapter: $chapter, ')
          ..write('level: $level, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('isCleared: $isCleared, ')
          ..write('memorizedRate: $memorizedRate, ')
          ..write('clearedAt: $clearedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordsTable words = $WordsTable(this);
  late final $LearningHistoryTable learningHistory = $LearningHistoryTable(
    this,
  );
  late final $DailyRecordsTable dailyRecords = $DailyRecordsTable(this);
  late final $StampsTable stamps = $StampsTable(this);
  late final $ChapterProgressesTable chapterProgresses =
      $ChapterProgressesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    words,
    learningHistory,
    dailyRecords,
    stamps,
    chapterProgresses,
  ];
}

typedef $$WordsTableCreateCompanionBuilder = WordsCompanion Function({
  Value<int> id,
  required String english,
  required String japanese,
  Value<String> cefr,
  Value<int> level,
  Value<int> chapter,
  Value<String?> phonetic,
  Value<String> category,
  Value<bool> isFavorite,
  Value<String?> example,
  Value<String?> exampleJp,
  Value<String> partOfSpeech,
  Value<String?> collocations,
  Value<String?> otherMeanings,
  Value<int> retentionPoint,
  Value<int> pointDecreasedTotal,
  Value<bool> isMemorized,
  Value<bool> isRestricted,
  Value<int> correctCount,
  Value<int> wrongCount,
  Value<DateTime?> lastStudiedAt,
  Value<DateTime?> lastRestrictedDate,
});
typedef $$WordsTableUpdateCompanionBuilder = WordsCompanion Function({
  Value<int> id,
  Value<String> english,
  Value<String> japanese,
  Value<String> cefr,
  Value<int> level,
  Value<int> chapter,
  Value<String?> phonetic,
  Value<String> category,
  Value<bool> isFavorite,
  Value<String?> example,
  Value<String?> exampleJp,
  Value<String> partOfSpeech,
  Value<String?> collocations,
  Value<String?> otherMeanings,
  Value<int> retentionPoint,
  Value<int> pointDecreasedTotal,
  Value<bool> isMemorized,
  Value<bool> isRestricted,
  Value<int> correctCount,
  Value<int> wrongCount,
  Value<DateTime?> lastStudiedAt,
  Value<DateTime?> lastRestrictedDate,
});

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get english => $composableBuilder(
    column: $table.english,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get japanese => $composableBuilder(
    column: $table.japanese,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cefr => $composableBuilder(
    column: $table.cefr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phonetic => $composableBuilder(
    column: $table.phonetic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleJp => $composableBuilder(
    column: $table.exampleJp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collocations => $composableBuilder(
    column: $table.collocations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get otherMeanings => $composableBuilder(
    column: $table.otherMeanings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retentionPoint => $composableBuilder(
    column: $table.retentionPoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pointDecreasedTotal => $composableBuilder(
    column: $table.pointDecreasedTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMemorized => $composableBuilder(
    column: $table.isMemorized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRestricted => $composableBuilder(
    column: $table.isRestricted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastStudiedAt => $composableBuilder(
    column: $table.lastStudiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRestrictedDate => $composableBuilder(
    column: $table.lastRestrictedDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get english => $composableBuilder(
    column: $table.english,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get japanese => $composableBuilder(
    column: $table.japanese,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cefr => $composableBuilder(
    column: $table.cefr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phonetic => $composableBuilder(
    column: $table.phonetic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleJp => $composableBuilder(
    column: $table.exampleJp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collocations => $composableBuilder(
    column: $table.collocations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get otherMeanings => $composableBuilder(
    column: $table.otherMeanings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retentionPoint => $composableBuilder(
    column: $table.retentionPoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pointDecreasedTotal => $composableBuilder(
    column: $table.pointDecreasedTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMemorized => $composableBuilder(
    column: $table.isMemorized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRestricted => $composableBuilder(
    column: $table.isRestricted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastStudiedAt => $composableBuilder(
    column: $table.lastStudiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRestrictedDate => $composableBuilder(
    column: $table.lastRestrictedDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get english =>
      $composableBuilder(column: $table.english, builder: (column) => column);

  GeneratedColumn<String> get japanese =>
      $composableBuilder(column: $table.japanese, builder: (column) => column);

  GeneratedColumn<String> get cefr =>
      $composableBuilder(column: $table.cefr, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<String> get phonetic =>
      $composableBuilder(column: $table.phonetic, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);

  GeneratedColumn<String> get exampleJp =>
      $composableBuilder(column: $table.exampleJp, builder: (column) => column);

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => column,
  );

  GeneratedColumn<String> get collocations => $composableBuilder(
    column: $table.collocations,
    builder: (column) => column,
  );

  GeneratedColumn<String> get otherMeanings => $composableBuilder(
    column: $table.otherMeanings,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retentionPoint => $composableBuilder(
    column: $table.retentionPoint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pointDecreasedTotal => $composableBuilder(
    column: $table.pointDecreasedTotal,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isMemorized => $composableBuilder(
    column: $table.isMemorized,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRestricted => $composableBuilder(
    column: $table.isRestricted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastStudiedAt => $composableBuilder(
    column: $table.lastStudiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastRestrictedDate => $composableBuilder(
    column: $table.lastRestrictedDate,
    builder: (column) => column,
  );
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          Word,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (Word, BaseReferences<_$AppDatabase, $WordsTable, Word>),
          Word,
          PrefetchHooks Function()
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> english = const Value.absent(),
                Value<String> japanese = const Value.absent(),
                Value<String> cefr = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<String?> phonetic = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> example = const Value.absent(),
                Value<String?> exampleJp = const Value.absent(),
                Value<String> partOfSpeech = const Value.absent(),
                Value<String?> collocations = const Value.absent(),
                Value<String?> otherMeanings = const Value.absent(),
                Value<int> retentionPoint = const Value.absent(),
                Value<int> pointDecreasedTotal = const Value.absent(),
                Value<bool> isMemorized = const Value.absent(),
                Value<bool> isRestricted = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> wrongCount = const Value.absent(),
                Value<DateTime?> lastStudiedAt = const Value.absent(),
                Value<DateTime?> lastRestrictedDate = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                english: english,
                japanese: japanese,
                cefr: cefr,
                level: level,
                chapter: chapter,
                phonetic: phonetic,
                category: category,
                isFavorite: isFavorite,
                example: example,
                exampleJp: exampleJp,
                partOfSpeech: partOfSpeech,
                collocations: collocations,
                otherMeanings: otherMeanings,
                retentionPoint: retentionPoint,
                pointDecreasedTotal: pointDecreasedTotal,
                isMemorized: isMemorized,
                isRestricted: isRestricted,
                correctCount: correctCount,
                wrongCount: wrongCount,
                lastStudiedAt: lastStudiedAt,
                lastRestrictedDate: lastRestrictedDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String english,
                required String japanese,
                Value<String> cefr = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<String?> phonetic = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> example = const Value.absent(),
                Value<String?> exampleJp = const Value.absent(),
                Value<String> partOfSpeech = const Value.absent(),
                Value<String?> collocations = const Value.absent(),
                Value<String?> otherMeanings = const Value.absent(),
                Value<int> retentionPoint = const Value.absent(),
                Value<int> pointDecreasedTotal = const Value.absent(),
                Value<bool> isMemorized = const Value.absent(),
                Value<bool> isRestricted = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> wrongCount = const Value.absent(),
                Value<DateTime?> lastStudiedAt = const Value.absent(),
                Value<DateTime?> lastRestrictedDate = const Value.absent(),
              }) => WordsCompanion.insert(
                id: id,
                english: english,
                japanese: japanese,
                cefr: cefr,
                level: level,
                chapter: chapter,
                phonetic: phonetic,
                category: category,
                isFavorite: isFavorite,
                example: example,
                exampleJp: exampleJp,
                partOfSpeech: partOfSpeech,
                collocations: collocations,
                otherMeanings: otherMeanings,
                retentionPoint: retentionPoint,
                pointDecreasedTotal: pointDecreasedTotal,
                isMemorized: isMemorized,
                isRestricted: isRestricted,
                correctCount: correctCount,
                wrongCount: wrongCount,
                lastStudiedAt: lastStudiedAt,
                lastRestrictedDate: lastRestrictedDate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      Word,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (Word, BaseReferences<_$AppDatabase, $WordsTable, Word>),
      Word,
      PrefetchHooks Function()
    >;
typedef $$LearningHistoryTableCreateCompanionBuilder =
    LearningHistoryCompanion Function({
      Value<int> id,
      required int score,
      required int level,
      Value<DateTime> playedAt,
    });
typedef $$LearningHistoryTableUpdateCompanionBuilder =
    LearningHistoryCompanion Function({
      Value<int> id,
      Value<int> score,
      Value<int> level,
      Value<DateTime> playedAt,
    });

class $$LearningHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $LearningHistoryTable> {
  $$LearningHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LearningHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningHistoryTable> {
  $$LearningHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningHistoryTable> {
  $$LearningHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);
}

class $$LearningHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningHistoryTable,
          LearningHistoryData,
          $$LearningHistoryTableFilterComposer,
          $$LearningHistoryTableOrderingComposer,
          $$LearningHistoryTableAnnotationComposer,
          $$LearningHistoryTableCreateCompanionBuilder,
          $$LearningHistoryTableUpdateCompanionBuilder,
          (
            LearningHistoryData,
            BaseReferences<
              _$AppDatabase,
              $LearningHistoryTable,
              LearningHistoryData
            >,
          ),
          LearningHistoryData,
          PrefetchHooks Function()
        > {
  $$LearningHistoryTableTableManager(
    _$AppDatabase db,
    $LearningHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
              }) => LearningHistoryCompanion(
                id: id,
                score: score,
                level: level,
                playedAt: playedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int score,
                required int level,
                Value<DateTime> playedAt = const Value.absent(),
              }) => LearningHistoryCompanion.insert(
                id: id,
                score: score,
                level: level,
                playedAt: playedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearningHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningHistoryTable,
      LearningHistoryData,
      $$LearningHistoryTableFilterComposer,
      $$LearningHistoryTableOrderingComposer,
      $$LearningHistoryTableAnnotationComposer,
      $$LearningHistoryTableCreateCompanionBuilder,
      $$LearningHistoryTableUpdateCompanionBuilder,
      (
        LearningHistoryData,
        BaseReferences<
          _$AppDatabase,
          $LearningHistoryTable,
          LearningHistoryData
        >,
      ),
      LearningHistoryData,
      PrefetchHooks Function()
    >;
typedef $$DailyRecordsTableCreateCompanionBuilder =
    DailyRecordsCompanion Function({
      required String dateStr,
      Value<int> memorizedCount,
      Value<int> playedCount,
      Value<String?> appliedStampId,
      Value<int> rowid,
    });
typedef $$DailyRecordsTableUpdateCompanionBuilder =
    DailyRecordsCompanion Function({
      Value<String> dateStr,
      Value<int> memorizedCount,
      Value<int> playedCount,
      Value<String?> appliedStampId,
      Value<int> rowid,
    });

class $$DailyRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyRecordsTable> {
  $$DailyRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dateStr => $composableBuilder(
    column: $table.dateStr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get memorizedCount => $composableBuilder(
    column: $table.memorizedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playedCount => $composableBuilder(
    column: $table.playedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appliedStampId => $composableBuilder(
    column: $table.appliedStampId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyRecordsTable> {
  $$DailyRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dateStr => $composableBuilder(
    column: $table.dateStr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get memorizedCount => $composableBuilder(
    column: $table.memorizedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playedCount => $composableBuilder(
    column: $table.playedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appliedStampId => $composableBuilder(
    column: $table.appliedStampId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyRecordsTable> {
  $$DailyRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dateStr =>
      $composableBuilder(column: $table.dateStr, builder: (column) => column);

  GeneratedColumn<int> get memorizedCount => $composableBuilder(
    column: $table.memorizedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playedCount => $composableBuilder(
    column: $table.playedCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appliedStampId => $composableBuilder(
    column: $table.appliedStampId,
    builder: (column) => column,
  );
}

class $$DailyRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyRecordsTable,
          DailyRecord,
          $$DailyRecordsTableFilterComposer,
          $$DailyRecordsTableOrderingComposer,
          $$DailyRecordsTableAnnotationComposer,
          $$DailyRecordsTableCreateCompanionBuilder,
          $$DailyRecordsTableUpdateCompanionBuilder,
          (
            DailyRecord,
            BaseReferences<_$AppDatabase, $DailyRecordsTable, DailyRecord>,
          ),
          DailyRecord,
          PrefetchHooks Function()
        > {
  $$DailyRecordsTableTableManager(_$AppDatabase db, $DailyRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> dateStr = const Value.absent(),
                Value<int> memorizedCount = const Value.absent(),
                Value<int> playedCount = const Value.absent(),
                Value<String?> appliedStampId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyRecordsCompanion(
                dateStr: dateStr,
                memorizedCount: memorizedCount,
                playedCount: playedCount,
                appliedStampId: appliedStampId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String dateStr,
                Value<int> memorizedCount = const Value.absent(),
                Value<int> playedCount = const Value.absent(),
                Value<String?> appliedStampId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyRecordsCompanion.insert(
                dateStr: dateStr,
                memorizedCount: memorizedCount,
                playedCount: playedCount,
                appliedStampId: appliedStampId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyRecordsTable,
      DailyRecord,
      $$DailyRecordsTableFilterComposer,
      $$DailyRecordsTableOrderingComposer,
      $$DailyRecordsTableAnnotationComposer,
      $$DailyRecordsTableCreateCompanionBuilder,
      $$DailyRecordsTableUpdateCompanionBuilder,
      (
        DailyRecord,
        BaseReferences<_$AppDatabase, $DailyRecordsTable, DailyRecord>,
      ),
      DailyRecord,
      PrefetchHooks Function()
    >;
typedef $$StampsTableCreateCompanionBuilder = StampsCompanion Function({
  required String id,
  Value<int> phase,
  required String name,
  Value<String> rarity,
  Value<bool> isFavorite,
  Value<int> colorPaletteId,
  Value<int> patternId,
  Value<int> frameId,
  Value<int> effectId,
  Value<String> description,
  Value<String> iconCode,
  Value<String> conditionType,
  Value<int> conditionValue,
  Value<bool> isUnlocked,
  Value<DateTime?> unlockedAt,
  Value<int> rowid,
});
typedef $$StampsTableUpdateCompanionBuilder = StampsCompanion Function({
  Value<String> id,
  Value<int> phase,
  Value<String> name,
  Value<String> rarity,
  Value<bool> isFavorite,
  Value<int> colorPaletteId,
  Value<int> patternId,
  Value<int> frameId,
  Value<int> effectId,
  Value<String> description,
  Value<String> iconCode,
  Value<String> conditionType,
  Value<int> conditionValue,
  Value<bool> isUnlocked,
  Value<DateTime?> unlockedAt,
  Value<int> rowid,
});

class $$StampsTableFilterComposer
    extends Composer<_$AppDatabase, $StampsTable> {
  $$StampsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rarity => $composableBuilder(
    column: $table.rarity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorPaletteId => $composableBuilder(
    column: $table.colorPaletteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get patternId => $composableBuilder(
    column: $table.patternId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get frameId => $composableBuilder(
    column: $table.frameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get effectId => $composableBuilder(
    column: $table.effectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conditionType => $composableBuilder(
    column: $table.conditionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get conditionValue => $composableBuilder(
    column: $table.conditionValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StampsTableOrderingComposer
    extends Composer<_$AppDatabase, $StampsTable> {
  $$StampsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rarity => $composableBuilder(
    column: $table.rarity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorPaletteId => $composableBuilder(
    column: $table.colorPaletteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get patternId => $composableBuilder(
    column: $table.patternId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get frameId => $composableBuilder(
    column: $table.frameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effectId => $composableBuilder(
    column: $table.effectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conditionType => $composableBuilder(
    column: $table.conditionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get conditionValue => $composableBuilder(
    column: $table.conditionValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StampsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StampsTable> {
  $$StampsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get rarity =>
      $composableBuilder(column: $table.rarity, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorPaletteId => $composableBuilder(
    column: $table.colorPaletteId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get patternId =>
      $composableBuilder(column: $table.patternId, builder: (column) => column);

  GeneratedColumn<int> get frameId =>
      $composableBuilder(column: $table.frameId, builder: (column) => column);

  GeneratedColumn<int> get effectId =>
      $composableBuilder(column: $table.effectId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);

  GeneratedColumn<String> get conditionType => $composableBuilder(
    column: $table.conditionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get conditionValue => $composableBuilder(
    column: $table.conditionValue,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => column,
  );
}

class $$StampsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StampsTable,
          Stamp,
          $$StampsTableFilterComposer,
          $$StampsTableOrderingComposer,
          $$StampsTableAnnotationComposer,
          $$StampsTableCreateCompanionBuilder,
          $$StampsTableUpdateCompanionBuilder,
          (Stamp, BaseReferences<_$AppDatabase, $StampsTable, Stamp>),
          Stamp,
          PrefetchHooks Function()
        > {
  $$StampsTableTableManager(_$AppDatabase db, $StampsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StampsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StampsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StampsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> phase = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> rarity = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> colorPaletteId = const Value.absent(),
                Value<int> patternId = const Value.absent(),
                Value<int> frameId = const Value.absent(),
                Value<int> effectId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> iconCode = const Value.absent(),
                Value<String> conditionType = const Value.absent(),
                Value<int> conditionValue = const Value.absent(),
                Value<bool> isUnlocked = const Value.absent(),
                Value<DateTime?> unlockedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StampsCompanion(
                id: id,
                phase: phase,
                name: name,
                rarity: rarity,
                isFavorite: isFavorite,
                colorPaletteId: colorPaletteId,
                patternId: patternId,
                frameId: frameId,
                effectId: effectId,
                description: description,
                iconCode: iconCode,
                conditionType: conditionType,
                conditionValue: conditionValue,
                isUnlocked: isUnlocked,
                unlockedAt: unlockedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> phase = const Value.absent(),
                required String name,
                Value<String> rarity = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> colorPaletteId = const Value.absent(),
                Value<int> patternId = const Value.absent(),
                Value<int> frameId = const Value.absent(),
                Value<int> effectId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> iconCode = const Value.absent(),
                Value<String> conditionType = const Value.absent(),
                Value<int> conditionValue = const Value.absent(),
                Value<bool> isUnlocked = const Value.absent(),
                Value<DateTime?> unlockedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StampsCompanion.insert(
                id: id,
                phase: phase,
                name: name,
                rarity: rarity,
                isFavorite: isFavorite,
                colorPaletteId: colorPaletteId,
                patternId: patternId,
                frameId: frameId,
                effectId: effectId,
                description: description,
                iconCode: iconCode,
                conditionType: conditionType,
                conditionValue: conditionValue,
                isUnlocked: isUnlocked,
                unlockedAt: unlockedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StampsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StampsTable,
      Stamp,
      $$StampsTableFilterComposer,
      $$StampsTableOrderingComposer,
      $$StampsTableAnnotationComposer,
      $$StampsTableCreateCompanionBuilder,
      $$StampsTableUpdateCompanionBuilder,
      (Stamp, BaseReferences<_$AppDatabase, $StampsTable, Stamp>),
      Stamp,
      PrefetchHooks Function()
    >;
typedef $$ChapterProgressesTableCreateCompanionBuilder =
    ChapterProgressesCompanion Function({
      Value<int> chapter,
      Value<int> level,
      Value<bool> isUnlocked,
      Value<bool> isCleared,
      Value<double> memorizedRate,
      Value<DateTime?> clearedAt,
    });
typedef $$ChapterProgressesTableUpdateCompanionBuilder =
    ChapterProgressesCompanion Function({
      Value<int> chapter,
      Value<int> level,
      Value<bool> isUnlocked,
      Value<bool> isCleared,
      Value<double> memorizedRate,
      Value<DateTime?> clearedAt,
    });

class $$ChapterProgressesTableFilterComposer
    extends Composer<_$AppDatabase, $ChapterProgressesTable> {
  $$ChapterProgressesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCleared => $composableBuilder(
    column: $table.isCleared,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get memorizedRate => $composableBuilder(
    column: $table.memorizedRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clearedAt => $composableBuilder(
    column: $table.clearedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChapterProgressesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChapterProgressesTable> {
  $$ChapterProgressesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCleared => $composableBuilder(
    column: $table.isCleared,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get memorizedRate => $composableBuilder(
    column: $table.memorizedRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clearedAt => $composableBuilder(
    column: $table.clearedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChapterProgressesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChapterProgressesTable> {
  $$ChapterProgressesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCleared =>
      $composableBuilder(column: $table.isCleared, builder: (column) => column);

  GeneratedColumn<double> get memorizedRate => $composableBuilder(
    column: $table.memorizedRate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get clearedAt =>
      $composableBuilder(column: $table.clearedAt, builder: (column) => column);
}

class $$ChapterProgressesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChapterProgressesTable,
          ChapterProgressesData,
          $$ChapterProgressesTableFilterComposer,
          $$ChapterProgressesTableOrderingComposer,
          $$ChapterProgressesTableAnnotationComposer,
          $$ChapterProgressesTableCreateCompanionBuilder,
          $$ChapterProgressesTableUpdateCompanionBuilder,
          (
            ChapterProgressesData,
            BaseReferences<
              _$AppDatabase,
              $ChapterProgressesTable,
              ChapterProgressesData
            >,
          ),
          ChapterProgressesData,
          PrefetchHooks Function()
        > {
  $$ChapterProgressesTableTableManager(
    _$AppDatabase db,
    $ChapterProgressesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChapterProgressesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChapterProgressesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChapterProgressesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> chapter = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<bool> isUnlocked = const Value.absent(),
                Value<bool> isCleared = const Value.absent(),
                Value<double> memorizedRate = const Value.absent(),
                Value<DateTime?> clearedAt = const Value.absent(),
              }) => ChapterProgressesCompanion(
                chapter: chapter,
                level: level,
                isUnlocked: isUnlocked,
                isCleared: isCleared,
                memorizedRate: memorizedRate,
                clearedAt: clearedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> chapter = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<bool> isUnlocked = const Value.absent(),
                Value<bool> isCleared = const Value.absent(),
                Value<double> memorizedRate = const Value.absent(),
                Value<DateTime?> clearedAt = const Value.absent(),
              }) => ChapterProgressesCompanion.insert(
                chapter: chapter,
                level: level,
                isUnlocked: isUnlocked,
                isCleared: isCleared,
                memorizedRate: memorizedRate,
                clearedAt: clearedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChapterProgressesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChapterProgressesTable,
      ChapterProgressesData,
      $$ChapterProgressesTableFilterComposer,
      $$ChapterProgressesTableOrderingComposer,
      $$ChapterProgressesTableAnnotationComposer,
      $$ChapterProgressesTableCreateCompanionBuilder,
      $$ChapterProgressesTableUpdateCompanionBuilder,
      (
        ChapterProgressesData,
        BaseReferences<
          _$AppDatabase,
          $ChapterProgressesTable,
          ChapterProgressesData
        >,
      ),
      ChapterProgressesData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$LearningHistoryTableTableManager get learningHistory =>
      $$LearningHistoryTableTableManager(_db, _db.learningHistory);
  $$DailyRecordsTableTableManager get dailyRecords =>
      $$DailyRecordsTableTableManager(_db, _db.dailyRecords);
  $$StampsTableTableManager get stamps =>
      $$StampsTableTableManager(_db, _db.stamps);
  $$ChapterProgressesTableTableManager get chapterProgresses =>
      $$ChapterProgressesTableTableManager(_db, _db.chapterProgresses);
}
