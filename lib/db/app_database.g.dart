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
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _audioUrlMeta = const VerificationMeta(
    'audioUrl',
  );
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
    'audio_url',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    english,
    japanese,
    level,
    audioUrl,
    isFavorite,
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
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('audio_url')) {
      context.handle(
        _audioUrlMeta,
        audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
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
        DriftSqlType.string,
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
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      audioUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_url'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends DataClass implements Insertable<Word> {
  final String id;
  final String english;
  final String japanese;
  final int level;
  final String? audioUrl;
  final bool isFavorite;
  const Word({
    required this.id,
    required this.english,
    required this.japanese,
    required this.level,
    this.audioUrl,
    required this.isFavorite,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['english'] = Variable<String>(english);
    map['japanese'] = Variable<String>(japanese);
    map['level'] = Variable<int>(level);
    if (!nullToAbsent || audioUrl != null) {
      map['audio_url'] = Variable<String>(audioUrl);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      english: Value(english),
      japanese: Value(japanese),
      level: Value(level),
      audioUrl: audioUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUrl),
      isFavorite: Value(isFavorite),
    );
  }

  factory Word.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<String>(json['id']),
      english: serializer.fromJson<String>(json['english']),
      japanese: serializer.fromJson<String>(json['japanese']),
      level: serializer.fromJson<int>(json['level']),
      audioUrl: serializer.fromJson<String?>(json['audioUrl']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'english': serializer.toJson<String>(english),
      'japanese': serializer.toJson<String>(japanese),
      'level': serializer.toJson<int>(level),
      'audioUrl': serializer.toJson<String?>(audioUrl),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  Word copyWith({
    String? id,
    String? english,
    String? japanese,
    int? level,
    Value<String?> audioUrl = const Value.absent(),
    bool? isFavorite,
  }) => Word(
    id: id ?? this.id,
    english: english ?? this.english,
    japanese: japanese ?? this.japanese,
    level: level ?? this.level,
    audioUrl: audioUrl.present ? audioUrl.value : this.audioUrl,
    isFavorite: isFavorite ?? this.isFavorite,
  );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      english: data.english.present ? data.english.value : this.english,
      japanese: data.japanese.present ? data.japanese.value : this.japanese,
      level: data.level.present ? data.level.value : this.level,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('english: $english, ')
          ..write('japanese: $japanese, ')
          ..write('level: $level, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, english, japanese, level, audioUrl, isFavorite);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.english == this.english &&
          other.japanese == this.japanese &&
          other.level == this.level &&
          other.audioUrl == this.audioUrl &&
          other.isFavorite == this.isFavorite);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<String> id;
  final Value<String> english;
  final Value<String> japanese;
  final Value<int> level;
  final Value<String?> audioUrl;
  final Value<bool> isFavorite;
  final Value<int> rowid;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.english = const Value.absent(),
    this.japanese = const Value.absent(),
    this.level = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordsCompanion.insert({
    required String id,
    required String english,
    required String japanese,
    this.level = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       english = Value(english),
       japanese = Value(japanese);
  static Insertable<Word> custom({
    Expression<String>? id,
    Expression<String>? english,
    Expression<String>? japanese,
    Expression<int>? level,
    Expression<String>? audioUrl,
    Expression<bool>? isFavorite,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (english != null) 'english': english,
      if (japanese != null) 'japanese': japanese,
      if (level != null) 'level': level,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordsCompanion copyWith({
    Value<String>? id,
    Value<String>? english,
    Value<String>? japanese,
    Value<int>? level,
    Value<String?>? audioUrl,
    Value<bool>? isFavorite,
    Value<int>? rowid,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      english: english ?? this.english,
      japanese: japanese ?? this.japanese,
      level: level ?? this.level,
      audioUrl: audioUrl ?? this.audioUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (english.present) {
      map['english'] = Variable<String>(english.value);
    }
    if (japanese.present) {
      map['japanese'] = Variable<String>(japanese.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('english: $english, ')
          ..write('japanese: $japanese, ')
          ..write('level: $level, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearningHistoriesTable extends LearningHistories
    with TableInfo<$LearningHistoriesTable, LearningHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _easinessFactorMeta = const VerificationMeta(
    'easinessFactor',
  );
  @override
  late final GeneratedColumn<double> easinessFactor = GeneratedColumn<double>(
    'easiness_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextReviewDateMeta = const VerificationMeta(
    'nextReviewDate',
  );
  @override
  late final GeneratedColumn<DateTime> nextReviewDate =
      GeneratedColumn<DateTime>(
        'next_review_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    wordId,
    repetitions,
    easinessFactor,
    intervalDays,
    nextReviewDate,
    lastReviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_histories';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningHistory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('easiness_factor')) {
      context.handle(
        _easinessFactorMeta,
        easinessFactor.isAcceptableOrUnknown(
          data['easiness_factor']!,
          _easinessFactorMeta,
        ),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('next_review_date')) {
      context.handle(
        _nextReviewDateMeta,
        nextReviewDate.isAcceptableOrUnknown(
          data['next_review_date']!,
          _nextReviewDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextReviewDateMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastReviewedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  LearningHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningHistory(
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_id'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      easinessFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}easiness_factor'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      nextReviewDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review_date'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      )!,
    );
  }

  @override
  $LearningHistoriesTable createAlias(String alias) {
    return $LearningHistoriesTable(attachedDatabase, alias);
  }
}

class LearningHistory extends DataClass implements Insertable<LearningHistory> {
  final String wordId;
  final int repetitions;
  final double easinessFactor;
  final int intervalDays;
  final DateTime nextReviewDate;
  final DateTime lastReviewedAt;
  const LearningHistory({
    required this.wordId,
    required this.repetitions,
    required this.easinessFactor,
    required this.intervalDays,
    required this.nextReviewDate,
    required this.lastReviewedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<String>(wordId);
    map['repetitions'] = Variable<int>(repetitions);
    map['easiness_factor'] = Variable<double>(easinessFactor);
    map['interval_days'] = Variable<int>(intervalDays);
    map['next_review_date'] = Variable<DateTime>(nextReviewDate);
    map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    return map;
  }

  LearningHistoriesCompanion toCompanion(bool nullToAbsent) {
    return LearningHistoriesCompanion(
      wordId: Value(wordId),
      repetitions: Value(repetitions),
      easinessFactor: Value(easinessFactor),
      intervalDays: Value(intervalDays),
      nextReviewDate: Value(nextReviewDate),
      lastReviewedAt: Value(lastReviewedAt),
    );
  }

  factory LearningHistory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningHistory(
      wordId: serializer.fromJson<String>(json['wordId']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      easinessFactor: serializer.fromJson<double>(json['easinessFactor']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      nextReviewDate: serializer.fromJson<DateTime>(json['nextReviewDate']),
      lastReviewedAt: serializer.fromJson<DateTime>(json['lastReviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<String>(wordId),
      'repetitions': serializer.toJson<int>(repetitions),
      'easinessFactor': serializer.toJson<double>(easinessFactor),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'nextReviewDate': serializer.toJson<DateTime>(nextReviewDate),
      'lastReviewedAt': serializer.toJson<DateTime>(lastReviewedAt),
    };
  }

  LearningHistory copyWith({
    String? wordId,
    int? repetitions,
    double? easinessFactor,
    int? intervalDays,
    DateTime? nextReviewDate,
    DateTime? lastReviewedAt,
  }) => LearningHistory(
    wordId: wordId ?? this.wordId,
    repetitions: repetitions ?? this.repetitions,
    easinessFactor: easinessFactor ?? this.easinessFactor,
    intervalDays: intervalDays ?? this.intervalDays,
    nextReviewDate: nextReviewDate ?? this.nextReviewDate,
    lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
  );
  LearningHistory copyWithCompanion(LearningHistoriesCompanion data) {
    return LearningHistory(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      easinessFactor: data.easinessFactor.present
          ? data.easinessFactor.value
          : this.easinessFactor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      nextReviewDate: data.nextReviewDate.present
          ? data.nextReviewDate.value
          : this.nextReviewDate,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningHistory(')
          ..write('wordId: $wordId, ')
          ..write('repetitions: $repetitions, ')
          ..write('easinessFactor: $easinessFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('nextReviewDate: $nextReviewDate, ')
          ..write('lastReviewedAt: $lastReviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    wordId,
    repetitions,
    easinessFactor,
    intervalDays,
    nextReviewDate,
    lastReviewedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningHistory &&
          other.wordId == this.wordId &&
          other.repetitions == this.repetitions &&
          other.easinessFactor == this.easinessFactor &&
          other.intervalDays == this.intervalDays &&
          other.nextReviewDate == this.nextReviewDate &&
          other.lastReviewedAt == this.lastReviewedAt);
}

class LearningHistoriesCompanion extends UpdateCompanion<LearningHistory> {
  final Value<String> wordId;
  final Value<int> repetitions;
  final Value<double> easinessFactor;
  final Value<int> intervalDays;
  final Value<DateTime> nextReviewDate;
  final Value<DateTime> lastReviewedAt;
  final Value<int> rowid;
  const LearningHistoriesCompanion({
    this.wordId = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.easinessFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.nextReviewDate = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearningHistoriesCompanion.insert({
    required String wordId,
    this.repetitions = const Value.absent(),
    this.easinessFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    required DateTime nextReviewDate,
    required DateTime lastReviewedAt,
    this.rowid = const Value.absent(),
  }) : wordId = Value(wordId),
       nextReviewDate = Value(nextReviewDate),
       lastReviewedAt = Value(lastReviewedAt);
  static Insertable<LearningHistory> custom({
    Expression<String>? wordId,
    Expression<int>? repetitions,
    Expression<double>? easinessFactor,
    Expression<int>? intervalDays,
    Expression<DateTime>? nextReviewDate,
    Expression<DateTime>? lastReviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (repetitions != null) 'repetitions': repetitions,
      if (easinessFactor != null) 'easiness_factor': easinessFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (nextReviewDate != null) 'next_review_date': nextReviewDate,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearningHistoriesCompanion copyWith({
    Value<String>? wordId,
    Value<int>? repetitions,
    Value<double>? easinessFactor,
    Value<int>? intervalDays,
    Value<DateTime>? nextReviewDate,
    Value<DateTime>? lastReviewedAt,
    Value<int>? rowid,
  }) {
    return LearningHistoriesCompanion(
      wordId: wordId ?? this.wordId,
      repetitions: repetitions ?? this.repetitions,
      easinessFactor: easinessFactor ?? this.easinessFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (easinessFactor.present) {
      map['easiness_factor'] = Variable<double>(easinessFactor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (nextReviewDate.present) {
      map['next_review_date'] = Variable<DateTime>(nextReviewDate.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningHistoriesCompanion(')
          ..write('wordId: $wordId, ')
          ..write('repetitions: $repetitions, ')
          ..write('easinessFactor: $easinessFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('nextReviewDate: $nextReviewDate, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordsTable words = $WordsTable(this);
  late final $LearningHistoriesTable learningHistories =
      $LearningHistoriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    words,
    learningHistories,
  ];
}

typedef $$WordsTableCreateCompanionBuilder = WordsCompanion Function({
  required String id,
  required String english,
  required String japanese,
  Value<int> level,
  Value<String?> audioUrl,
  Value<bool> isFavorite,
  Value<int> rowid,
});
typedef $$WordsTableUpdateCompanionBuilder = WordsCompanion Function({
  Value<String> id,
  Value<String> english,
  Value<String> japanese,
  Value<int> level,
  Value<String?> audioUrl,
  Value<bool> isFavorite,
  Value<int> rowid,
});

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
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

  ColumnFilters<String> get english => $composableBuilder(
    column: $table.english,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get japanese => $composableBuilder(
    column: $table.japanese,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
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
  ColumnOrderings<String> get id => $composableBuilder(
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

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
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
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get english =>
      $composableBuilder(column: $table.english, builder: (column) => column);

  GeneratedColumn<String> get japanese =>
      $composableBuilder(column: $table.japanese, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
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
                Value<String> id = const Value.absent(),
                Value<String> english = const Value.absent(),
                Value<String> japanese = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String?> audioUrl = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                english: english,
                japanese: japanese,
                level: level,
                audioUrl: audioUrl,
                isFavorite: isFavorite,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String english,
                required String japanese,
                Value<int> level = const Value.absent(),
                Value<String?> audioUrl = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordsCompanion.insert(
                id: id,
                english: english,
                japanese: japanese,
                level: level,
                audioUrl: audioUrl,
                isFavorite: isFavorite,
                rowid: rowid,
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
typedef $$LearningHistoriesTableCreateCompanionBuilder =
    LearningHistoriesCompanion Function({
      required String wordId,
      Value<int> repetitions,
      Value<double> easinessFactor,
      Value<int> intervalDays,
      required DateTime nextReviewDate,
      required DateTime lastReviewedAt,
      Value<int> rowid,
    });
typedef $$LearningHistoriesTableUpdateCompanionBuilder =
    LearningHistoriesCompanion Function({
      Value<String> wordId,
      Value<int> repetitions,
      Value<double> easinessFactor,
      Value<int> intervalDays,
      Value<DateTime> nextReviewDate,
      Value<DateTime> lastReviewedAt,
      Value<int> rowid,
    });

class $$LearningHistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $LearningHistoriesTable> {
  $$LearningHistoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easinessFactor => $composableBuilder(
    column: $table.easinessFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReviewDate => $composableBuilder(
    column: $table.nextReviewDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LearningHistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningHistoriesTable> {
  $$LearningHistoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easinessFactor => $composableBuilder(
    column: $table.easinessFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReviewDate => $composableBuilder(
    column: $table.nextReviewDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningHistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningHistoriesTable> {
  $$LearningHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<double> get easinessFactor => $composableBuilder(
    column: $table.easinessFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextReviewDate => $composableBuilder(
    column: $table.nextReviewDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );
}

class $$LearningHistoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningHistoriesTable,
          LearningHistory,
          $$LearningHistoriesTableFilterComposer,
          $$LearningHistoriesTableOrderingComposer,
          $$LearningHistoriesTableAnnotationComposer,
          $$LearningHistoriesTableCreateCompanionBuilder,
          $$LearningHistoriesTableUpdateCompanionBuilder,
          (
            LearningHistory,
            BaseReferences<
              _$AppDatabase,
              $LearningHistoriesTable,
              LearningHistory
            >,
          ),
          LearningHistory,
          PrefetchHooks Function()
        > {
  $$LearningHistoriesTableTableManager(
    _$AppDatabase db,
    $LearningHistoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningHistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningHistoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> wordId = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<double> easinessFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<DateTime> nextReviewDate = const Value.absent(),
                Value<DateTime> lastReviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningHistoriesCompanion(
                wordId: wordId,
                repetitions: repetitions,
                easinessFactor: easinessFactor,
                intervalDays: intervalDays,
                nextReviewDate: nextReviewDate,
                lastReviewedAt: lastReviewedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String wordId,
                Value<int> repetitions = const Value.absent(),
                Value<double> easinessFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                required DateTime nextReviewDate,
                required DateTime lastReviewedAt,
                Value<int> rowid = const Value.absent(),
              }) => LearningHistoriesCompanion.insert(
                wordId: wordId,
                repetitions: repetitions,
                easinessFactor: easinessFactor,
                intervalDays: intervalDays,
                nextReviewDate: nextReviewDate,
                lastReviewedAt: lastReviewedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearningHistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningHistoriesTable,
      LearningHistory,
      $$LearningHistoriesTableFilterComposer,
      $$LearningHistoriesTableOrderingComposer,
      $$LearningHistoriesTableAnnotationComposer,
      $$LearningHistoriesTableCreateCompanionBuilder,
      $$LearningHistoriesTableUpdateCompanionBuilder,
      (
        LearningHistory,
        BaseReferences<_$AppDatabase, $LearningHistoriesTable, LearningHistory>,
      ),
      LearningHistory,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$LearningHistoriesTableTableManager get learningHistories =>
      $$LearningHistoriesTableTableManager(_db, _db.learningHistories);
}
