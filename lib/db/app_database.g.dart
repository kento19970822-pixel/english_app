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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    english,
    japanese,
    cefr,
    level,
    chapter,
    phonetic,
    isFavorite,
    retentionPoint,
    lastStudiedAt,
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
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
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
    if (data.containsKey('last_studied_at')) {
      context.handle(
        _lastStudiedAtMeta,
        lastStudiedAt.isAcceptableOrUnknown(
          data['last_studied_at']!,
          _lastStudiedAtMeta,
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
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      retentionPoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retention_point'],
      )!,
      lastStudiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_studied_at'],
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
  final bool isFavorite;
  final int retentionPoint;
  final DateTime? lastStudiedAt;
  const Word({
    required this.id,
    required this.english,
    required this.japanese,
    required this.cefr,
    required this.level,
    required this.chapter,
    this.phonetic,
    required this.isFavorite,
    required this.retentionPoint,
    this.lastStudiedAt,
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
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['retention_point'] = Variable<int>(retentionPoint);
    if (!nullToAbsent || lastStudiedAt != null) {
      map['last_studied_at'] = Variable<DateTime>(lastStudiedAt);
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
      isFavorite: Value(isFavorite),
      retentionPoint: Value(retentionPoint),
      lastStudiedAt: lastStudiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStudiedAt),
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
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      retentionPoint: serializer.fromJson<int>(json['retentionPoint']),
      lastStudiedAt: serializer.fromJson<DateTime?>(json['lastStudiedAt']),
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
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'retentionPoint': serializer.toJson<int>(retentionPoint),
      'lastStudiedAt': serializer.toJson<DateTime?>(lastStudiedAt),
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
    bool? isFavorite,
    int? retentionPoint,
    Value<DateTime?> lastStudiedAt = const Value.absent(),
  }) => Word(
    id: id ?? this.id,
    english: english ?? this.english,
    japanese: japanese ?? this.japanese,
    cefr: cefr ?? this.cefr,
    level: level ?? this.level,
    chapter: chapter ?? this.chapter,
    phonetic: phonetic.present ? phonetic.value : this.phonetic,
    isFavorite: isFavorite ?? this.isFavorite,
    retentionPoint: retentionPoint ?? this.retentionPoint,
    lastStudiedAt: lastStudiedAt.present
        ? lastStudiedAt.value
        : this.lastStudiedAt,
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
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      retentionPoint: data.retentionPoint.present
          ? data.retentionPoint.value
          : this.retentionPoint,
      lastStudiedAt: data.lastStudiedAt.present
          ? data.lastStudiedAt.value
          : this.lastStudiedAt,
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
          ..write('isFavorite: $isFavorite, ')
          ..write('retentionPoint: $retentionPoint, ')
          ..write('lastStudiedAt: $lastStudiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    english,
    japanese,
    cefr,
    level,
    chapter,
    phonetic,
    isFavorite,
    retentionPoint,
    lastStudiedAt,
  );
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
          other.isFavorite == this.isFavorite &&
          other.retentionPoint == this.retentionPoint &&
          other.lastStudiedAt == this.lastStudiedAt);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<int> id;
  final Value<String> english;
  final Value<String> japanese;
  final Value<String> cefr;
  final Value<int> level;
  final Value<int> chapter;
  final Value<String?> phonetic;
  final Value<bool> isFavorite;
  final Value<int> retentionPoint;
  final Value<DateTime?> lastStudiedAt;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.english = const Value.absent(),
    this.japanese = const Value.absent(),
    this.cefr = const Value.absent(),
    this.level = const Value.absent(),
    this.chapter = const Value.absent(),
    this.phonetic = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.retentionPoint = const Value.absent(),
    this.lastStudiedAt = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    required String english,
    required String japanese,
    this.cefr = const Value.absent(),
    this.level = const Value.absent(),
    this.chapter = const Value.absent(),
    this.phonetic = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.retentionPoint = const Value.absent(),
    this.lastStudiedAt = const Value.absent(),
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
    Expression<bool>? isFavorite,
    Expression<int>? retentionPoint,
    Expression<DateTime>? lastStudiedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (english != null) 'english': english,
      if (japanese != null) 'japanese': japanese,
      if (cefr != null) 'cefr': cefr,
      if (level != null) 'level': level,
      if (chapter != null) 'chapter': chapter,
      if (phonetic != null) 'phonetic': phonetic,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (retentionPoint != null) 'retention_point': retentionPoint,
      if (lastStudiedAt != null) 'last_studied_at': lastStudiedAt,
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
    Value<bool>? isFavorite,
    Value<int>? retentionPoint,
    Value<DateTime?>? lastStudiedAt,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      english: english ?? this.english,
      japanese: japanese ?? this.japanese,
      cefr: cefr ?? this.cefr,
      level: level ?? this.level,
      chapter: chapter ?? this.chapter,
      phonetic: phonetic ?? this.phonetic,
      isFavorite: isFavorite ?? this.isFavorite,
      retentionPoint: retentionPoint ?? this.retentionPoint,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
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
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (retentionPoint.present) {
      map['retention_point'] = Variable<int>(retentionPoint.value);
    }
    if (lastStudiedAt.present) {
      map['last_studied_at'] = Variable<DateTime>(lastStudiedAt.value);
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
          ..write('isFavorite: $isFavorite, ')
          ..write('retentionPoint: $retentionPoint, ')
          ..write('lastStudiedAt: $lastStudiedAt')
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
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
    name,
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_code')) {
      context.handle(
        _iconCodeMeta,
        iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_iconCodeMeta);
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
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
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
  /// スタンプID (例: `stamp_lion`, `stamp_cat`)
  final String id;

  /// スタンプ名 (例: ライオンスタンプ)
  final String name;

  /// 表示用アイコン識別子 / 画像アセットパス
  final String iconCode;

  /// 出現条件種別 (`none`, `streak`, `daily_memorized`)
  final String conditionType;

  /// 条件閾値 (例: 連続3日なら 3)
  final int conditionValue;

  /// 獲得（ロック解除）フラグ
  final bool isUnlocked;

  /// 初回獲得日時
  final DateTime? unlockedAt;
  const Stamp({
    required this.id,
    required this.name,
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
    map['name'] = Variable<String>(name);
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
      name: Value(name),
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
      name: serializer.fromJson<String>(json['name']),
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
      'name': serializer.toJson<String>(name),
      'iconCode': serializer.toJson<String>(iconCode),
      'conditionType': serializer.toJson<String>(conditionType),
      'conditionValue': serializer.toJson<int>(conditionValue),
      'isUnlocked': serializer.toJson<bool>(isUnlocked),
      'unlockedAt': serializer.toJson<DateTime?>(unlockedAt),
    };
  }

  Stamp copyWith({
    String? id,
    String? name,
    String? iconCode,
    String? conditionType,
    int? conditionValue,
    bool? isUnlocked,
    Value<DateTime?> unlockedAt = const Value.absent(),
  }) => Stamp(
    id: id ?? this.id,
    name: name ?? this.name,
    iconCode: iconCode ?? this.iconCode,
    conditionType: conditionType ?? this.conditionType,
    conditionValue: conditionValue ?? this.conditionValue,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    unlockedAt: unlockedAt.present ? unlockedAt.value : this.unlockedAt,
  );
  Stamp copyWithCompanion(StampsCompanion data) {
    return Stamp(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
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
          ..write('name: $name, ')
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
    name,
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
          other.name == this.name &&
          other.iconCode == this.iconCode &&
          other.conditionType == this.conditionType &&
          other.conditionValue == this.conditionValue &&
          other.isUnlocked == this.isUnlocked &&
          other.unlockedAt == this.unlockedAt);
}

class StampsCompanion extends UpdateCompanion<Stamp> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> iconCode;
  final Value<String> conditionType;
  final Value<int> conditionValue;
  final Value<bool> isUnlocked;
  final Value<DateTime?> unlockedAt;
  final Value<int> rowid;
  const StampsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.conditionType = const Value.absent(),
    this.conditionValue = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StampsCompanion.insert({
    required String id,
    required String name,
    required String iconCode,
    this.conditionType = const Value.absent(),
    this.conditionValue = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       iconCode = Value(iconCode);
  static Insertable<Stamp> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? iconCode,
    Expression<String>? conditionType,
    Expression<int>? conditionValue,
    Expression<bool>? isUnlocked,
    Expression<DateTime>? unlockedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
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
    Value<String>? name,
    Value<String>? iconCode,
    Value<String>? conditionType,
    Value<int>? conditionValue,
    Value<bool>? isUnlocked,
    Value<DateTime?>? unlockedAt,
    Value<int>? rowid,
  }) {
    return StampsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
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
          ..write('name: $name, ')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordsTable words = $WordsTable(this);
  late final $LearningHistoryTable learningHistory = $LearningHistoryTable(
    this,
  );
  late final $DailyRecordsTable dailyRecords = $DailyRecordsTable(this);
  late final $StampsTable stamps = $StampsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    words,
    learningHistory,
    dailyRecords,
    stamps,
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
  Value<bool> isFavorite,
  Value<int> retentionPoint,
  Value<DateTime?> lastStudiedAt,
});
typedef $$WordsTableUpdateCompanionBuilder = WordsCompanion Function({
  Value<int> id,
  Value<String> english,
  Value<String> japanese,
  Value<String> cefr,
  Value<int> level,
  Value<int> chapter,
  Value<String?> phonetic,
  Value<bool> isFavorite,
  Value<int> retentionPoint,
  Value<DateTime?> lastStudiedAt,
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

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retentionPoint => $composableBuilder(
    column: $table.retentionPoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastStudiedAt => $composableBuilder(
    column: $table.lastStudiedAt,
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

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retentionPoint => $composableBuilder(
    column: $table.retentionPoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastStudiedAt => $composableBuilder(
    column: $table.lastStudiedAt,
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

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retentionPoint => $composableBuilder(
    column: $table.retentionPoint,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastStudiedAt => $composableBuilder(
    column: $table.lastStudiedAt,
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
                Value<bool> isFavorite = const Value.absent(),
                Value<int> retentionPoint = const Value.absent(),
                Value<DateTime?> lastStudiedAt = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                english: english,
                japanese: japanese,
                cefr: cefr,
                level: level,
                chapter: chapter,
                phonetic: phonetic,
                isFavorite: isFavorite,
                retentionPoint: retentionPoint,
                lastStudiedAt: lastStudiedAt,
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
                Value<bool> isFavorite = const Value.absent(),
                Value<int> retentionPoint = const Value.absent(),
                Value<DateTime?> lastStudiedAt = const Value.absent(),
              }) => WordsCompanion.insert(
                id: id,
                english: english,
                japanese: japanese,
                cefr: cefr,
                level: level,
                chapter: chapter,
                phonetic: phonetic,
                isFavorite: isFavorite,
                retentionPoint: retentionPoint,
                lastStudiedAt: lastStudiedAt,
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
  required String name,
  required String iconCode,
  Value<String> conditionType,
  Value<int> conditionValue,
  Value<bool> isUnlocked,
  Value<DateTime?> unlockedAt,
  Value<int> rowid,
});
typedef $$StampsTableUpdateCompanionBuilder = StampsCompanion Function({
  Value<String> id,
  Value<String> name,
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

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
                Value<String> name = const Value.absent(),
                Value<String> iconCode = const Value.absent(),
                Value<String> conditionType = const Value.absent(),
                Value<int> conditionValue = const Value.absent(),
                Value<bool> isUnlocked = const Value.absent(),
                Value<DateTime?> unlockedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StampsCompanion(
                id: id,
                name: name,
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
                required String name,
                required String iconCode,
                Value<String> conditionType = const Value.absent(),
                Value<int> conditionValue = const Value.absent(),
                Value<bool> isUnlocked = const Value.absent(),
                Value<DateTime?> unlockedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StampsCompanion.insert(
                id: id,
                name: name,
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
}
