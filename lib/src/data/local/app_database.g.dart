// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $QuestionRecordsTable extends QuestionRecords
    with TableInfo<$QuestionRecordsTable, QuestionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recognizedTextMeta =
      const VerificationMeta('recognizedText');
  @override
  late final GeneratedColumn<String> recognizedText = GeneratedColumn<String>(
      'recognized_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _correctedTextMeta =
      const VerificationMeta('correctedText');
  @override
  late final GeneratedColumn<String> correctedText = GeneratedColumn<String>(
      'corrected_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tagsJsonMeta =
      const VerificationMeta('tagsJson');
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
      'tags_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _contentStatusMeta =
      const VerificationMeta('contentStatus');
  @override
  late final GeneratedColumn<String> contentStatus = GeneratedColumn<String>(
      'content_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _masteryLevelMeta =
      const VerificationMeta('masteryLevel');
  @override
  late final GeneratedColumn<String> masteryLevel = GeneratedColumn<String>(
      'mastery_level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _analysisJsonMeta =
      const VerificationMeta('analysisJson');
  @override
  late final GeneratedColumn<String> analysisJson = GeneratedColumn<String>(
      'analysis_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _reviewCountMeta =
      const VerificationMeta('reviewCount');
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
      'review_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastReviewedAtMeta =
      const VerificationMeta('lastReviewedAt');
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>('last_reviewed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        imagePath,
        subject,
        recognizedText,
        correctedText,
        tagsJson,
        contentStatus,
        masteryLevel,
        analysisJson,
        isFavorite,
        reviewCount,
        createdAt,
        updatedAt,
        lastReviewedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_records';
  @override
  VerificationContext validateIntegrity(Insertable<QuestionRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('recognized_text')) {
      context.handle(
          _recognizedTextMeta,
          recognizedText.isAcceptableOrUnknown(
              data['recognized_text']!, _recognizedTextMeta));
    } else if (isInserting) {
      context.missing(_recognizedTextMeta);
    }
    if (data.containsKey('corrected_text')) {
      context.handle(
          _correctedTextMeta,
          correctedText.isAcceptableOrUnknown(
              data['corrected_text']!, _correctedTextMeta));
    } else if (isInserting) {
      context.missing(_correctedTextMeta);
    }
    if (data.containsKey('tags_json')) {
      context.handle(_tagsJsonMeta,
          tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta));
    }
    if (data.containsKey('content_status')) {
      context.handle(
          _contentStatusMeta,
          contentStatus.isAcceptableOrUnknown(
              data['content_status']!, _contentStatusMeta));
    } else if (isInserting) {
      context.missing(_contentStatusMeta);
    }
    if (data.containsKey('mastery_level')) {
      context.handle(
          _masteryLevelMeta,
          masteryLevel.isAcceptableOrUnknown(
              data['mastery_level']!, _masteryLevelMeta));
    } else if (isInserting) {
      context.missing(_masteryLevelMeta);
    }
    if (data.containsKey('analysis_json')) {
      context.handle(
          _analysisJsonMeta,
          analysisJson.isAcceptableOrUnknown(
              data['analysis_json']!, _analysisJsonMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('review_count')) {
      context.handle(
          _reviewCountMeta,
          reviewCount.isAcceptableOrUnknown(
              data['review_count']!, _reviewCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
          _lastReviewedAtMeta,
          lastReviewedAt.isAcceptableOrUnknown(
              data['last_reviewed_at']!, _lastReviewedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject'])!,
      recognizedText: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}recognized_text'])!,
      correctedText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}corrected_text'])!,
      tagsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags_json'])!,
      contentStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_status'])!,
      masteryLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mastery_level'])!,
      analysisJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}analysis_json']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      reviewCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}review_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_reviewed_at']),
    );
  }

  @override
  $QuestionRecordsTable createAlias(String alias) {
    return $QuestionRecordsTable(attachedDatabase, alias);
  }
}

class QuestionRecord extends DataClass implements Insertable<QuestionRecord> {
  final String id;
  final String imagePath;
  final String subject;
  final String recognizedText;
  final String correctedText;
  final String tagsJson;
  final String contentStatus;
  final String masteryLevel;
  final String? analysisJson;
  final bool isFavorite;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastReviewedAt;
  const QuestionRecord(
      {required this.id,
      required this.imagePath,
      required this.subject,
      required this.recognizedText,
      required this.correctedText,
      required this.tagsJson,
      required this.contentStatus,
      required this.masteryLevel,
      this.analysisJson,
      required this.isFavorite,
      required this.reviewCount,
      required this.createdAt,
      required this.updatedAt,
      this.lastReviewedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['image_path'] = Variable<String>(imagePath);
    map['subject'] = Variable<String>(subject);
    map['recognized_text'] = Variable<String>(recognizedText);
    map['corrected_text'] = Variable<String>(correctedText);
    map['tags_json'] = Variable<String>(tagsJson);
    map['content_status'] = Variable<String>(contentStatus);
    map['mastery_level'] = Variable<String>(masteryLevel);
    if (!nullToAbsent || analysisJson != null) {
      map['analysis_json'] = Variable<String>(analysisJson);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['review_count'] = Variable<int>(reviewCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    return map;
  }

  QuestionRecordsCompanion toCompanion(bool nullToAbsent) {
    return QuestionRecordsCompanion(
      id: Value(id),
      imagePath: Value(imagePath),
      subject: Value(subject),
      recognizedText: Value(recognizedText),
      correctedText: Value(correctedText),
      tagsJson: Value(tagsJson),
      contentStatus: Value(contentStatus),
      masteryLevel: Value(masteryLevel),
      analysisJson: analysisJson == null && nullToAbsent
          ? const Value.absent()
          : Value(analysisJson),
      isFavorite: Value(isFavorite),
      reviewCount: Value(reviewCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
    );
  }

  factory QuestionRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionRecord(
      id: serializer.fromJson<String>(json['id']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      subject: serializer.fromJson<String>(json['subject']),
      recognizedText: serializer.fromJson<String>(json['recognizedText']),
      correctedText: serializer.fromJson<String>(json['correctedText']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      contentStatus: serializer.fromJson<String>(json['contentStatus']),
      masteryLevel: serializer.fromJson<String>(json['masteryLevel']),
      analysisJson: serializer.fromJson<String?>(json['analysisJson']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'imagePath': serializer.toJson<String>(imagePath),
      'subject': serializer.toJson<String>(subject),
      'recognizedText': serializer.toJson<String>(recognizedText),
      'correctedText': serializer.toJson<String>(correctedText),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'contentStatus': serializer.toJson<String>(contentStatus),
      'masteryLevel': serializer.toJson<String>(masteryLevel),
      'analysisJson': serializer.toJson<String?>(analysisJson),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
    };
  }

  QuestionRecord copyWith(
          {String? id,
          String? imagePath,
          String? subject,
          String? recognizedText,
          String? correctedText,
          String? tagsJson,
          String? contentStatus,
          String? masteryLevel,
          Value<String?> analysisJson = const Value.absent(),
          bool? isFavorite,
          int? reviewCount,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> lastReviewedAt = const Value.absent()}) =>
      QuestionRecord(
        id: id ?? this.id,
        imagePath: imagePath ?? this.imagePath,
        subject: subject ?? this.subject,
        recognizedText: recognizedText ?? this.recognizedText,
        correctedText: correctedText ?? this.correctedText,
        tagsJson: tagsJson ?? this.tagsJson,
        contentStatus: contentStatus ?? this.contentStatus,
        masteryLevel: masteryLevel ?? this.masteryLevel,
        analysisJson:
            analysisJson.present ? analysisJson.value : this.analysisJson,
        isFavorite: isFavorite ?? this.isFavorite,
        reviewCount: reviewCount ?? this.reviewCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastReviewedAt:
            lastReviewedAt.present ? lastReviewedAt.value : this.lastReviewedAt,
      );
  QuestionRecord copyWithCompanion(QuestionRecordsCompanion data) {
    return QuestionRecord(
      id: data.id.present ? data.id.value : this.id,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      subject: data.subject.present ? data.subject.value : this.subject,
      recognizedText: data.recognizedText.present
          ? data.recognizedText.value
          : this.recognizedText,
      correctedText: data.correctedText.present
          ? data.correctedText.value
          : this.correctedText,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      contentStatus: data.contentStatus.present
          ? data.contentStatus.value
          : this.contentStatus,
      masteryLevel: data.masteryLevel.present
          ? data.masteryLevel.value
          : this.masteryLevel,
      analysisJson: data.analysisJson.present
          ? data.analysisJson.value
          : this.analysisJson,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      reviewCount:
          data.reviewCount.present ? data.reviewCount.value : this.reviewCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionRecord(')
          ..write('id: $id, ')
          ..write('imagePath: $imagePath, ')
          ..write('subject: $subject, ')
          ..write('recognizedText: $recognizedText, ')
          ..write('correctedText: $correctedText, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('contentStatus: $contentStatus, ')
          ..write('masteryLevel: $masteryLevel, ')
          ..write('analysisJson: $analysisJson, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastReviewedAt: $lastReviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      imagePath,
      subject,
      recognizedText,
      correctedText,
      tagsJson,
      contentStatus,
      masteryLevel,
      analysisJson,
      isFavorite,
      reviewCount,
      createdAt,
      updatedAt,
      lastReviewedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionRecord &&
          other.id == this.id &&
          other.imagePath == this.imagePath &&
          other.subject == this.subject &&
          other.recognizedText == this.recognizedText &&
          other.correctedText == this.correctedText &&
          other.tagsJson == this.tagsJson &&
          other.contentStatus == this.contentStatus &&
          other.masteryLevel == this.masteryLevel &&
          other.analysisJson == this.analysisJson &&
          other.isFavorite == this.isFavorite &&
          other.reviewCount == this.reviewCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastReviewedAt == this.lastReviewedAt);
}

class QuestionRecordsCompanion extends UpdateCompanion<QuestionRecord> {
  final Value<String> id;
  final Value<String> imagePath;
  final Value<String> subject;
  final Value<String> recognizedText;
  final Value<String> correctedText;
  final Value<String> tagsJson;
  final Value<String> contentStatus;
  final Value<String> masteryLevel;
  final Value<String?> analysisJson;
  final Value<bool> isFavorite;
  final Value<int> reviewCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastReviewedAt;
  final Value<int> rowid;
  const QuestionRecordsCompanion({
    this.id = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.subject = const Value.absent(),
    this.recognizedText = const Value.absent(),
    this.correctedText = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.contentStatus = const Value.absent(),
    this.masteryLevel = const Value.absent(),
    this.analysisJson = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionRecordsCompanion.insert({
    required String id,
    required String imagePath,
    required String subject,
    required String recognizedText,
    required String correctedText,
    this.tagsJson = const Value.absent(),
    required String contentStatus,
    required String masteryLevel,
    this.analysisJson = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.reviewCount = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastReviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        imagePath = Value(imagePath),
        subject = Value(subject),
        recognizedText = Value(recognizedText),
        correctedText = Value(correctedText),
        contentStatus = Value(contentStatus),
        masteryLevel = Value(masteryLevel),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<QuestionRecord> custom({
    Expression<String>? id,
    Expression<String>? imagePath,
    Expression<String>? subject,
    Expression<String>? recognizedText,
    Expression<String>? correctedText,
    Expression<String>? tagsJson,
    Expression<String>? contentStatus,
    Expression<String>? masteryLevel,
    Expression<String>? analysisJson,
    Expression<bool>? isFavorite,
    Expression<int>? reviewCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastReviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (imagePath != null) 'image_path': imagePath,
      if (subject != null) 'subject': subject,
      if (recognizedText != null) 'recognized_text': recognizedText,
      if (correctedText != null) 'corrected_text': correctedText,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (contentStatus != null) 'content_status': contentStatus,
      if (masteryLevel != null) 'mastery_level': masteryLevel,
      if (analysisJson != null) 'analysis_json': analysisJson,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (reviewCount != null) 'review_count': reviewCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionRecordsCompanion copyWith(
      {Value<String>? id,
      Value<String>? imagePath,
      Value<String>? subject,
      Value<String>? recognizedText,
      Value<String>? correctedText,
      Value<String>? tagsJson,
      Value<String>? contentStatus,
      Value<String>? masteryLevel,
      Value<String?>? analysisJson,
      Value<bool>? isFavorite,
      Value<int>? reviewCount,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? lastReviewedAt,
      Value<int>? rowid}) {
    return QuestionRecordsCompanion(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      subject: subject ?? this.subject,
      recognizedText: recognizedText ?? this.recognizedText,
      correctedText: correctedText ?? this.correctedText,
      tagsJson: tagsJson ?? this.tagsJson,
      contentStatus: contentStatus ?? this.contentStatus,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      analysisJson: analysisJson ?? this.analysisJson,
      isFavorite: isFavorite ?? this.isFavorite,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (recognizedText.present) {
      map['recognized_text'] = Variable<String>(recognizedText.value);
    }
    if (correctedText.present) {
      map['corrected_text'] = Variable<String>(correctedText.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (contentStatus.present) {
      map['content_status'] = Variable<String>(contentStatus.value);
    }
    if (masteryLevel.present) {
      map['mastery_level'] = Variable<String>(masteryLevel.value);
    }
    if (analysisJson.present) {
      map['analysis_json'] = Variable<String>(analysisJson.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
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
    return (StringBuffer('QuestionRecordsCompanion(')
          ..write('id: $id, ')
          ..write('imagePath: $imagePath, ')
          ..write('subject: $subject, ')
          ..write('recognizedText: $recognizedText, ')
          ..write('correctedText: $correctedText, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('contentStatus: $contentStatus, ')
          ..write('masteryLevel: $masteryLevel, ')
          ..write('analysisJson: $analysisJson, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GeneratedExercisesTable extends GeneratedExercises
    with TableInfo<$GeneratedExercisesTable, GeneratedExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeneratedExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionRecordIdMeta =
      const VerificationMeta('questionRecordId');
  @override
  late final GeneratedColumn<String> questionRecordId = GeneratedColumn<String>(
      'question_record_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES question_records (id)'));
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionMeta =
      const VerificationMeta('question');
  @override
  late final GeneratedColumn<String> question = GeneratedColumn<String>(
      'question', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
      'answer', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _explanationMeta =
      const VerificationMeta('explanation');
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
      'explanation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isCorrectMeta =
      const VerificationMeta('isCorrect');
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
      'is_correct', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_correct" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        questionRecordId,
        difficulty,
        question,
        answer,
        explanation,
        isCorrect
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'generated_exercises';
  @override
  VerificationContext validateIntegrity(Insertable<GeneratedExercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('question_record_id')) {
      context.handle(
          _questionRecordIdMeta,
          questionRecordId.isAcceptableOrUnknown(
              data['question_record_id']!, _questionRecordIdMeta));
    } else if (isInserting) {
      context.missing(_questionRecordIdMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('question')) {
      context.handle(_questionMeta,
          question.isAcceptableOrUnknown(data['question']!, _questionMeta));
    } else if (isInserting) {
      context.missing(_questionMeta);
    }
    if (data.containsKey('answer')) {
      context.handle(_answerMeta,
          answer.isAcceptableOrUnknown(data['answer']!, _answerMeta));
    } else if (isInserting) {
      context.missing(_answerMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
          _explanationMeta,
          explanation.isAcceptableOrUnknown(
              data['explanation']!, _explanationMeta));
    } else if (isInserting) {
      context.missing(_explanationMeta);
    }
    if (data.containsKey('is_correct')) {
      context.handle(_isCorrectMeta,
          isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GeneratedExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeneratedExercise(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      questionRecordId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}question_record_id'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}difficulty'])!,
      question: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question'])!,
      answer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answer'])!,
      explanation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}explanation'])!,
      isCorrect: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_correct']),
    );
  }

  @override
  $GeneratedExercisesTable createAlias(String alias) {
    return $GeneratedExercisesTable(attachedDatabase, alias);
  }
}

class GeneratedExercise extends DataClass
    implements Insertable<GeneratedExercise> {
  final String id;
  final String questionRecordId;
  final String difficulty;
  final String question;
  final String answer;
  final String explanation;
  final bool? isCorrect;
  const GeneratedExercise(
      {required this.id,
      required this.questionRecordId,
      required this.difficulty,
      required this.question,
      required this.answer,
      required this.explanation,
      this.isCorrect});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['question_record_id'] = Variable<String>(questionRecordId);
    map['difficulty'] = Variable<String>(difficulty);
    map['question'] = Variable<String>(question);
    map['answer'] = Variable<String>(answer);
    map['explanation'] = Variable<String>(explanation);
    if (!nullToAbsent || isCorrect != null) {
      map['is_correct'] = Variable<bool>(isCorrect);
    }
    return map;
  }

  GeneratedExercisesCompanion toCompanion(bool nullToAbsent) {
    return GeneratedExercisesCompanion(
      id: Value(id),
      questionRecordId: Value(questionRecordId),
      difficulty: Value(difficulty),
      question: Value(question),
      answer: Value(answer),
      explanation: Value(explanation),
      isCorrect: isCorrect == null && nullToAbsent
          ? const Value.absent()
          : Value(isCorrect),
    );
  }

  factory GeneratedExercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeneratedExercise(
      id: serializer.fromJson<String>(json['id']),
      questionRecordId: serializer.fromJson<String>(json['questionRecordId']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      question: serializer.fromJson<String>(json['question']),
      answer: serializer.fromJson<String>(json['answer']),
      explanation: serializer.fromJson<String>(json['explanation']),
      isCorrect: serializer.fromJson<bool?>(json['isCorrect']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'questionRecordId': serializer.toJson<String>(questionRecordId),
      'difficulty': serializer.toJson<String>(difficulty),
      'question': serializer.toJson<String>(question),
      'answer': serializer.toJson<String>(answer),
      'explanation': serializer.toJson<String>(explanation),
      'isCorrect': serializer.toJson<bool?>(isCorrect),
    };
  }

  GeneratedExercise copyWith(
          {String? id,
          String? questionRecordId,
          String? difficulty,
          String? question,
          String? answer,
          String? explanation,
          Value<bool?> isCorrect = const Value.absent()}) =>
      GeneratedExercise(
        id: id ?? this.id,
        questionRecordId: questionRecordId ?? this.questionRecordId,
        difficulty: difficulty ?? this.difficulty,
        question: question ?? this.question,
        answer: answer ?? this.answer,
        explanation: explanation ?? this.explanation,
        isCorrect: isCorrect.present ? isCorrect.value : this.isCorrect,
      );
  GeneratedExercise copyWithCompanion(GeneratedExercisesCompanion data) {
    return GeneratedExercise(
      id: data.id.present ? data.id.value : this.id,
      questionRecordId: data.questionRecordId.present
          ? data.questionRecordId.value
          : this.questionRecordId,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      question: data.question.present ? data.question.value : this.question,
      answer: data.answer.present ? data.answer.value : this.answer,
      explanation:
          data.explanation.present ? data.explanation.value : this.explanation,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeneratedExercise(')
          ..write('id: $id, ')
          ..write('questionRecordId: $questionRecordId, ')
          ..write('difficulty: $difficulty, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('explanation: $explanation, ')
          ..write('isCorrect: $isCorrect')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, questionRecordId, difficulty, question,
      answer, explanation, isCorrect);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeneratedExercise &&
          other.id == this.id &&
          other.questionRecordId == this.questionRecordId &&
          other.difficulty == this.difficulty &&
          other.question == this.question &&
          other.answer == this.answer &&
          other.explanation == this.explanation &&
          other.isCorrect == this.isCorrect);
}

class GeneratedExercisesCompanion extends UpdateCompanion<GeneratedExercise> {
  final Value<String> id;
  final Value<String> questionRecordId;
  final Value<String> difficulty;
  final Value<String> question;
  final Value<String> answer;
  final Value<String> explanation;
  final Value<bool?> isCorrect;
  final Value<int> rowid;
  const GeneratedExercisesCompanion({
    this.id = const Value.absent(),
    this.questionRecordId = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.question = const Value.absent(),
    this.answer = const Value.absent(),
    this.explanation = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GeneratedExercisesCompanion.insert({
    required String id,
    required String questionRecordId,
    required String difficulty,
    required String question,
    required String answer,
    required String explanation,
    this.isCorrect = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        questionRecordId = Value(questionRecordId),
        difficulty = Value(difficulty),
        question = Value(question),
        answer = Value(answer),
        explanation = Value(explanation);
  static Insertable<GeneratedExercise> custom({
    Expression<String>? id,
    Expression<String>? questionRecordId,
    Expression<String>? difficulty,
    Expression<String>? question,
    Expression<String>? answer,
    Expression<String>? explanation,
    Expression<bool>? isCorrect,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionRecordId != null) 'question_record_id': questionRecordId,
      if (difficulty != null) 'difficulty': difficulty,
      if (question != null) 'question': question,
      if (answer != null) 'answer': answer,
      if (explanation != null) 'explanation': explanation,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GeneratedExercisesCompanion copyWith(
      {Value<String>? id,
      Value<String>? questionRecordId,
      Value<String>? difficulty,
      Value<String>? question,
      Value<String>? answer,
      Value<String>? explanation,
      Value<bool?>? isCorrect,
      Value<int>? rowid}) {
    return GeneratedExercisesCompanion(
      id: id ?? this.id,
      questionRecordId: questionRecordId ?? this.questionRecordId,
      difficulty: difficulty ?? this.difficulty,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      isCorrect: isCorrect ?? this.isCorrect,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (questionRecordId.present) {
      map['question_record_id'] = Variable<String>(questionRecordId.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (question.present) {
      map['question'] = Variable<String>(question.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeneratedExercisesCompanion(')
          ..write('id: $id, ')
          ..write('questionRecordId: $questionRecordId, ')
          ..write('difficulty: $difficulty, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('explanation: $explanation, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionRecordIdMeta =
      const VerificationMeta('questionRecordId');
  @override
  late final GeneratedColumn<String> questionRecordId = GeneratedColumn<String>(
      'question_record_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES question_records (id)'));
  static const VerificationMeta _reviewedAtMeta =
      const VerificationMeta('reviewedAt');
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
      'reviewed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
      'result', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _masteryAfterMeta =
      const VerificationMeta('masteryAfter');
  @override
  late final GeneratedColumn<String> masteryAfter = GeneratedColumn<String>(
      'mastery_after', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, questionRecordId, reviewedAt, result, masteryAfter];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(Insertable<ReviewLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('question_record_id')) {
      context.handle(
          _questionRecordIdMeta,
          questionRecordId.isAcceptableOrUnknown(
              data['question_record_id']!, _questionRecordIdMeta));
    } else if (isInserting) {
      context.missing(_questionRecordIdMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
          _reviewedAtMeta,
          reviewedAt.isAcceptableOrUnknown(
              data['reviewed_at']!, _reviewedAtMeta));
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('result')) {
      context.handle(_resultMeta,
          result.isAcceptableOrUnknown(data['result']!, _resultMeta));
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    if (data.containsKey('mastery_after')) {
      context.handle(
          _masteryAfterMeta,
          masteryAfter.isAcceptableOrUnknown(
              data['mastery_after']!, _masteryAfterMeta));
    } else if (isInserting) {
      context.missing(_masteryAfterMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      questionRecordId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}question_record_id'])!,
      reviewedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}reviewed_at'])!,
      result: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}result'])!,
      masteryAfter: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mastery_after'])!,
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLog extends DataClass implements Insertable<ReviewLog> {
  final String id;
  final String questionRecordId;
  final DateTime reviewedAt;
  final String result;
  final String masteryAfter;
  const ReviewLog(
      {required this.id,
      required this.questionRecordId,
      required this.reviewedAt,
      required this.result,
      required this.masteryAfter});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['question_record_id'] = Variable<String>(questionRecordId);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    map['result'] = Variable<String>(result);
    map['mastery_after'] = Variable<String>(masteryAfter);
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      questionRecordId: Value(questionRecordId),
      reviewedAt: Value(reviewedAt),
      result: Value(result),
      masteryAfter: Value(masteryAfter),
    );
  }

  factory ReviewLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLog(
      id: serializer.fromJson<String>(json['id']),
      questionRecordId: serializer.fromJson<String>(json['questionRecordId']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      result: serializer.fromJson<String>(json['result']),
      masteryAfter: serializer.fromJson<String>(json['masteryAfter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'questionRecordId': serializer.toJson<String>(questionRecordId),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'result': serializer.toJson<String>(result),
      'masteryAfter': serializer.toJson<String>(masteryAfter),
    };
  }

  ReviewLog copyWith(
          {String? id,
          String? questionRecordId,
          DateTime? reviewedAt,
          String? result,
          String? masteryAfter}) =>
      ReviewLog(
        id: id ?? this.id,
        questionRecordId: questionRecordId ?? this.questionRecordId,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        result: result ?? this.result,
        masteryAfter: masteryAfter ?? this.masteryAfter,
      );
  ReviewLog copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLog(
      id: data.id.present ? data.id.value : this.id,
      questionRecordId: data.questionRecordId.present
          ? data.questionRecordId.value
          : this.questionRecordId,
      reviewedAt:
          data.reviewedAt.present ? data.reviewedAt.value : this.reviewedAt,
      result: data.result.present ? data.result.value : this.result,
      masteryAfter: data.masteryAfter.present
          ? data.masteryAfter.value
          : this.masteryAfter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLog(')
          ..write('id: $id, ')
          ..write('questionRecordId: $questionRecordId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('result: $result, ')
          ..write('masteryAfter: $masteryAfter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, questionRecordId, reviewedAt, result, masteryAfter);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLog &&
          other.id == this.id &&
          other.questionRecordId == this.questionRecordId &&
          other.reviewedAt == this.reviewedAt &&
          other.result == this.result &&
          other.masteryAfter == this.masteryAfter);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLog> {
  final Value<String> id;
  final Value<String> questionRecordId;
  final Value<DateTime> reviewedAt;
  final Value<String> result;
  final Value<String> masteryAfter;
  final Value<int> rowid;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.questionRecordId = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.result = const Value.absent(),
    this.masteryAfter = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    required String id,
    required String questionRecordId,
    required DateTime reviewedAt,
    required String result,
    required String masteryAfter,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        questionRecordId = Value(questionRecordId),
        reviewedAt = Value(reviewedAt),
        result = Value(result),
        masteryAfter = Value(masteryAfter);
  static Insertable<ReviewLog> custom({
    Expression<String>? id,
    Expression<String>? questionRecordId,
    Expression<DateTime>? reviewedAt,
    Expression<String>? result,
    Expression<String>? masteryAfter,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionRecordId != null) 'question_record_id': questionRecordId,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (result != null) 'result': result,
      if (masteryAfter != null) 'mastery_after': masteryAfter,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? questionRecordId,
      Value<DateTime>? reviewedAt,
      Value<String>? result,
      Value<String>? masteryAfter,
      Value<int>? rowid}) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      questionRecordId: questionRecordId ?? this.questionRecordId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      result: result ?? this.result,
      masteryAfter: masteryAfter ?? this.masteryAfter,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (questionRecordId.present) {
      map['question_record_id'] = Variable<String>(questionRecordId.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (masteryAfter.present) {
      map['mastery_after'] = Variable<String>(masteryAfter.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('questionRecordId: $questionRecordId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('result: $result, ')
          ..write('masteryAfter: $masteryAfter, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsEntriesTable extends SettingsEntries
    with TableInfo<$SettingsEntriesTable, SettingsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_entries';
  @override
  VerificationContext validateIntegrity(Insertable<SettingsEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsEntry(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsEntriesTable createAlias(String alias) {
    return $SettingsEntriesTable(attachedDatabase, alias);
  }
}

class SettingsEntry extends DataClass implements Insertable<SettingsEntry> {
  final String key;
  final String value;
  const SettingsEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingsEntriesCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingsEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsEntry copyWith({String? key, String? value}) => SettingsEntry(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingsEntry copyWithCompanion(SettingsEntriesCompanion data) {
    return SettingsEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsEntriesCompanion extends UpdateCompanion<SettingsEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SettingsEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsEntriesCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $QuestionRecordsTable questionRecords =
      $QuestionRecordsTable(this);
  late final $GeneratedExercisesTable generatedExercises =
      $GeneratedExercisesTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $SettingsEntriesTable settingsEntries =
      $SettingsEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [questionRecords, generatedExercises, reviewLogs, settingsEntries];
}

typedef $$QuestionRecordsTableCreateCompanionBuilder = QuestionRecordsCompanion
    Function({
  required String id,
  required String imagePath,
  required String subject,
  required String recognizedText,
  required String correctedText,
  Value<String> tagsJson,
  required String contentStatus,
  required String masteryLevel,
  Value<String?> analysisJson,
  Value<bool> isFavorite,
  Value<int> reviewCount,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> lastReviewedAt,
  Value<int> rowid,
});
typedef $$QuestionRecordsTableUpdateCompanionBuilder = QuestionRecordsCompanion
    Function({
  Value<String> id,
  Value<String> imagePath,
  Value<String> subject,
  Value<String> recognizedText,
  Value<String> correctedText,
  Value<String> tagsJson,
  Value<String> contentStatus,
  Value<String> masteryLevel,
  Value<String?> analysisJson,
  Value<bool> isFavorite,
  Value<int> reviewCount,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastReviewedAt,
  Value<int> rowid,
});

final class $$QuestionRecordsTableReferences extends BaseReferences<
    _$AppDatabase, $QuestionRecordsTable, QuestionRecord> {
  $$QuestionRecordsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GeneratedExercisesTable, List<GeneratedExercise>>
      _generatedExercisesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.generatedExercises,
              aliasName: $_aliasNameGenerator(db.questionRecords.id,
                  db.generatedExercises.questionRecordId));

  $$GeneratedExercisesTableProcessedTableManager get generatedExercisesRefs {
    final manager =
        $$GeneratedExercisesTableTableManager($_db, $_db.generatedExercises)
            .filter((f) =>
                f.questionRecordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_generatedExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReviewLogsTable, List<ReviewLog>>
      _reviewLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.reviewLogs,
              aliasName: $_aliasNameGenerator(
                  db.questionRecords.id, db.reviewLogs.questionRecordId));

  $$ReviewLogsTableProcessedTableManager get reviewLogsRefs {
    final manager = $$ReviewLogsTableTableManager($_db, $_db.reviewLogs).filter(
        (f) => f.questionRecordId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$QuestionRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionRecordsTable> {
  $$QuestionRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recognizedText => $composableBuilder(
      column: $table.recognizedText,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get correctedText => $composableBuilder(
      column: $table.correctedText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentStatus => $composableBuilder(
      column: $table.contentStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get masteryLevel => $composableBuilder(
      column: $table.masteryLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get analysisJson => $composableBuilder(
      column: $table.analysisJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reviewCount => $composableBuilder(
      column: $table.reviewCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt,
      builder: (column) => ColumnFilters(column));

  Expression<bool> generatedExercisesRefs(
      Expression<bool> Function($$GeneratedExercisesTableFilterComposer f) f) {
    final $$GeneratedExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.generatedExercises,
        getReferencedColumn: (t) => t.questionRecordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GeneratedExercisesTableFilterComposer(
              $db: $db,
              $table: $db.generatedExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> reviewLogsRefs(
      Expression<bool> Function($$ReviewLogsTableFilterComposer f) f) {
    final $$ReviewLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reviewLogs,
        getReferencedColumn: (t) => t.questionRecordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReviewLogsTableFilterComposer(
              $db: $db,
              $table: $db.reviewLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$QuestionRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionRecordsTable> {
  $$QuestionRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recognizedText => $composableBuilder(
      column: $table.recognizedText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get correctedText => $composableBuilder(
      column: $table.correctedText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagsJson => $composableBuilder(
      column: $table.tagsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentStatus => $composableBuilder(
      column: $table.contentStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get masteryLevel => $composableBuilder(
      column: $table.masteryLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get analysisJson => $composableBuilder(
      column: $table.analysisJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reviewCount => $composableBuilder(
      column: $table.reviewCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$QuestionRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionRecordsTable> {
  $$QuestionRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get recognizedText => $composableBuilder(
      column: $table.recognizedText, builder: (column) => column);

  GeneratedColumn<String> get correctedText => $composableBuilder(
      column: $table.correctedText, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get contentStatus => $composableBuilder(
      column: $table.contentStatus, builder: (column) => column);

  GeneratedColumn<String> get masteryLevel => $composableBuilder(
      column: $table.masteryLevel, builder: (column) => column);

  GeneratedColumn<String> get analysisJson => $composableBuilder(
      column: $table.analysisJson, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<int> get reviewCount => $composableBuilder(
      column: $table.reviewCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt, builder: (column) => column);

  Expression<T> generatedExercisesRefs<T extends Object>(
      Expression<T> Function($$GeneratedExercisesTableAnnotationComposer a) f) {
    final $$GeneratedExercisesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.generatedExercises,
            getReferencedColumn: (t) => t.questionRecordId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$GeneratedExercisesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.generatedExercises,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> reviewLogsRefs<T extends Object>(
      Expression<T> Function($$ReviewLogsTableAnnotationComposer a) f) {
    final $$ReviewLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reviewLogs,
        getReferencedColumn: (t) => t.questionRecordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReviewLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.reviewLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$QuestionRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuestionRecordsTable,
    QuestionRecord,
    $$QuestionRecordsTableFilterComposer,
    $$QuestionRecordsTableOrderingComposer,
    $$QuestionRecordsTableAnnotationComposer,
    $$QuestionRecordsTableCreateCompanionBuilder,
    $$QuestionRecordsTableUpdateCompanionBuilder,
    (QuestionRecord, $$QuestionRecordsTableReferences),
    QuestionRecord,
    PrefetchHooks Function(
        {bool generatedExercisesRefs, bool reviewLogsRefs})> {
  $$QuestionRecordsTableTableManager(
      _$AppDatabase db, $QuestionRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> imagePath = const Value.absent(),
            Value<String> subject = const Value.absent(),
            Value<String> recognizedText = const Value.absent(),
            Value<String> correctedText = const Value.absent(),
            Value<String> tagsJson = const Value.absent(),
            Value<String> contentStatus = const Value.absent(),
            Value<String> masteryLevel = const Value.absent(),
            Value<String?> analysisJson = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> reviewCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastReviewedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuestionRecordsCompanion(
            id: id,
            imagePath: imagePath,
            subject: subject,
            recognizedText: recognizedText,
            correctedText: correctedText,
            tagsJson: tagsJson,
            contentStatus: contentStatus,
            masteryLevel: masteryLevel,
            analysisJson: analysisJson,
            isFavorite: isFavorite,
            reviewCount: reviewCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastReviewedAt: lastReviewedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String imagePath,
            required String subject,
            required String recognizedText,
            required String correctedText,
            Value<String> tagsJson = const Value.absent(),
            required String contentStatus,
            required String masteryLevel,
            Value<String?> analysisJson = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> reviewCount = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> lastReviewedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuestionRecordsCompanion.insert(
            id: id,
            imagePath: imagePath,
            subject: subject,
            recognizedText: recognizedText,
            correctedText: correctedText,
            tagsJson: tagsJson,
            contentStatus: contentStatus,
            masteryLevel: masteryLevel,
            analysisJson: analysisJson,
            isFavorite: isFavorite,
            reviewCount: reviewCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastReviewedAt: lastReviewedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$QuestionRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {generatedExercisesRefs = false, reviewLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (generatedExercisesRefs) db.generatedExercises,
                if (reviewLogsRefs) db.reviewLogs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (generatedExercisesRefs)
                    await $_getPrefetchedData<QuestionRecord,
                            $QuestionRecordsTable, GeneratedExercise>(
                        currentTable: table,
                        referencedTable: $$QuestionRecordsTableReferences
                            ._generatedExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$QuestionRecordsTableReferences(db, table, p0)
                                .generatedExercisesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.questionRecordId == item.id),
                        typedResults: items),
                  if (reviewLogsRefs)
                    await $_getPrefetchedData<QuestionRecord,
                            $QuestionRecordsTable, ReviewLog>(
                        currentTable: table,
                        referencedTable: $$QuestionRecordsTableReferences
                            ._reviewLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$QuestionRecordsTableReferences(db, table, p0)
                                .reviewLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.questionRecordId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$QuestionRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuestionRecordsTable,
    QuestionRecord,
    $$QuestionRecordsTableFilterComposer,
    $$QuestionRecordsTableOrderingComposer,
    $$QuestionRecordsTableAnnotationComposer,
    $$QuestionRecordsTableCreateCompanionBuilder,
    $$QuestionRecordsTableUpdateCompanionBuilder,
    (QuestionRecord, $$QuestionRecordsTableReferences),
    QuestionRecord,
    PrefetchHooks Function({bool generatedExercisesRefs, bool reviewLogsRefs})>;
typedef $$GeneratedExercisesTableCreateCompanionBuilder
    = GeneratedExercisesCompanion Function({
  required String id,
  required String questionRecordId,
  required String difficulty,
  required String question,
  required String answer,
  required String explanation,
  Value<bool?> isCorrect,
  Value<int> rowid,
});
typedef $$GeneratedExercisesTableUpdateCompanionBuilder
    = GeneratedExercisesCompanion Function({
  Value<String> id,
  Value<String> questionRecordId,
  Value<String> difficulty,
  Value<String> question,
  Value<String> answer,
  Value<String> explanation,
  Value<bool?> isCorrect,
  Value<int> rowid,
});

final class $$GeneratedExercisesTableReferences extends BaseReferences<
    _$AppDatabase, $GeneratedExercisesTable, GeneratedExercise> {
  $$GeneratedExercisesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $QuestionRecordsTable _questionRecordIdTable(_$AppDatabase db) =>
      db.questionRecords.createAlias($_aliasNameGenerator(
          db.generatedExercises.questionRecordId, db.questionRecords.id));

  $$QuestionRecordsTableProcessedTableManager get questionRecordId {
    final $_column = $_itemColumn<String>('question_record_id')!;

    final manager =
        $$QuestionRecordsTableTableManager($_db, $_db.questionRecords)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GeneratedExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $GeneratedExercisesTable> {
  $$GeneratedExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get question => $composableBuilder(
      column: $table.question, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answer => $composableBuilder(
      column: $table.answer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCorrect => $composableBuilder(
      column: $table.isCorrect, builder: (column) => ColumnFilters(column));

  $$QuestionRecordsTableFilterComposer get questionRecordId {
    final $$QuestionRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionRecordId,
        referencedTable: $db.questionRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionRecordsTableFilterComposer(
              $db: $db,
              $table: $db.questionRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GeneratedExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $GeneratedExercisesTable> {
  $$GeneratedExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get question => $composableBuilder(
      column: $table.question, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answer => $composableBuilder(
      column: $table.answer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
      column: $table.isCorrect, builder: (column) => ColumnOrderings(column));

  $$QuestionRecordsTableOrderingComposer get questionRecordId {
    final $$QuestionRecordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionRecordId,
        referencedTable: $db.questionRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionRecordsTableOrderingComposer(
              $db: $db,
              $table: $db.questionRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GeneratedExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GeneratedExercisesTable> {
  $$GeneratedExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<String> get question =>
      $composableBuilder(column: $table.question, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => column);

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  $$QuestionRecordsTableAnnotationComposer get questionRecordId {
    final $$QuestionRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionRecordId,
        referencedTable: $db.questionRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.questionRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GeneratedExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GeneratedExercisesTable,
    GeneratedExercise,
    $$GeneratedExercisesTableFilterComposer,
    $$GeneratedExercisesTableOrderingComposer,
    $$GeneratedExercisesTableAnnotationComposer,
    $$GeneratedExercisesTableCreateCompanionBuilder,
    $$GeneratedExercisesTableUpdateCompanionBuilder,
    (GeneratedExercise, $$GeneratedExercisesTableReferences),
    GeneratedExercise,
    PrefetchHooks Function({bool questionRecordId})> {
  $$GeneratedExercisesTableTableManager(
      _$AppDatabase db, $GeneratedExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeneratedExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeneratedExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeneratedExercisesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> questionRecordId = const Value.absent(),
            Value<String> difficulty = const Value.absent(),
            Value<String> question = const Value.absent(),
            Value<String> answer = const Value.absent(),
            Value<String> explanation = const Value.absent(),
            Value<bool?> isCorrect = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GeneratedExercisesCompanion(
            id: id,
            questionRecordId: questionRecordId,
            difficulty: difficulty,
            question: question,
            answer: answer,
            explanation: explanation,
            isCorrect: isCorrect,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String questionRecordId,
            required String difficulty,
            required String question,
            required String answer,
            required String explanation,
            Value<bool?> isCorrect = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GeneratedExercisesCompanion.insert(
            id: id,
            questionRecordId: questionRecordId,
            difficulty: difficulty,
            question: question,
            answer: answer,
            explanation: explanation,
            isCorrect: isCorrect,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$GeneratedExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({questionRecordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (questionRecordId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.questionRecordId,
                    referencedTable: $$GeneratedExercisesTableReferences
                        ._questionRecordIdTable(db),
                    referencedColumn: $$GeneratedExercisesTableReferences
                        ._questionRecordIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$GeneratedExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GeneratedExercisesTable,
    GeneratedExercise,
    $$GeneratedExercisesTableFilterComposer,
    $$GeneratedExercisesTableOrderingComposer,
    $$GeneratedExercisesTableAnnotationComposer,
    $$GeneratedExercisesTableCreateCompanionBuilder,
    $$GeneratedExercisesTableUpdateCompanionBuilder,
    (GeneratedExercise, $$GeneratedExercisesTableReferences),
    GeneratedExercise,
    PrefetchHooks Function({bool questionRecordId})>;
typedef $$ReviewLogsTableCreateCompanionBuilder = ReviewLogsCompanion Function({
  required String id,
  required String questionRecordId,
  required DateTime reviewedAt,
  required String result,
  required String masteryAfter,
  Value<int> rowid,
});
typedef $$ReviewLogsTableUpdateCompanionBuilder = ReviewLogsCompanion Function({
  Value<String> id,
  Value<String> questionRecordId,
  Value<DateTime> reviewedAt,
  Value<String> result,
  Value<String> masteryAfter,
  Value<int> rowid,
});

final class $$ReviewLogsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLog> {
  $$ReviewLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $QuestionRecordsTable _questionRecordIdTable(_$AppDatabase db) =>
      db.questionRecords.createAlias($_aliasNameGenerator(
          db.reviewLogs.questionRecordId, db.questionRecords.id));

  $$QuestionRecordsTableProcessedTableManager get questionRecordId {
    final $_column = $_itemColumn<String>('question_record_id')!;

    final manager =
        $$QuestionRecordsTableTableManager($_db, $_db.questionRecords)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionRecordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get result => $composableBuilder(
      column: $table.result, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get masteryAfter => $composableBuilder(
      column: $table.masteryAfter, builder: (column) => ColumnFilters(column));

  $$QuestionRecordsTableFilterComposer get questionRecordId {
    final $$QuestionRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionRecordId,
        referencedTable: $db.questionRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionRecordsTableFilterComposer(
              $db: $db,
              $table: $db.questionRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get result => $composableBuilder(
      column: $table.result, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get masteryAfter => $composableBuilder(
      column: $table.masteryAfter,
      builder: (column) => ColumnOrderings(column));

  $$QuestionRecordsTableOrderingComposer get questionRecordId {
    final $$QuestionRecordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionRecordId,
        referencedTable: $db.questionRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionRecordsTableOrderingComposer(
              $db: $db,
              $table: $db.questionRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => column);

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<String> get masteryAfter => $composableBuilder(
      column: $table.masteryAfter, builder: (column) => column);

  $$QuestionRecordsTableAnnotationComposer get questionRecordId {
    final $$QuestionRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionRecordId,
        referencedTable: $db.questionRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.questionRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReviewLogsTable,
    ReviewLog,
    $$ReviewLogsTableFilterComposer,
    $$ReviewLogsTableOrderingComposer,
    $$ReviewLogsTableAnnotationComposer,
    $$ReviewLogsTableCreateCompanionBuilder,
    $$ReviewLogsTableUpdateCompanionBuilder,
    (ReviewLog, $$ReviewLogsTableReferences),
    ReviewLog,
    PrefetchHooks Function({bool questionRecordId})> {
  $$ReviewLogsTableTableManager(_$AppDatabase db, $ReviewLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> questionRecordId = const Value.absent(),
            Value<DateTime> reviewedAt = const Value.absent(),
            Value<String> result = const Value.absent(),
            Value<String> masteryAfter = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReviewLogsCompanion(
            id: id,
            questionRecordId: questionRecordId,
            reviewedAt: reviewedAt,
            result: result,
            masteryAfter: masteryAfter,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String questionRecordId,
            required DateTime reviewedAt,
            required String result,
            required String masteryAfter,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReviewLogsCompanion.insert(
            id: id,
            questionRecordId: questionRecordId,
            reviewedAt: reviewedAt,
            result: result,
            masteryAfter: masteryAfter,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ReviewLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({questionRecordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (questionRecordId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.questionRecordId,
                    referencedTable:
                        $$ReviewLogsTableReferences._questionRecordIdTable(db),
                    referencedColumn: $$ReviewLogsTableReferences
                        ._questionRecordIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReviewLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReviewLogsTable,
    ReviewLog,
    $$ReviewLogsTableFilterComposer,
    $$ReviewLogsTableOrderingComposer,
    $$ReviewLogsTableAnnotationComposer,
    $$ReviewLogsTableCreateCompanionBuilder,
    $$ReviewLogsTableUpdateCompanionBuilder,
    (ReviewLog, $$ReviewLogsTableReferences),
    ReviewLog,
    PrefetchHooks Function({bool questionRecordId})>;
typedef $$SettingsEntriesTableCreateCompanionBuilder = SettingsEntriesCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsEntriesTableUpdateCompanionBuilder = SettingsEntriesCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsEntriesTable,
    SettingsEntry,
    $$SettingsEntriesTableFilterComposer,
    $$SettingsEntriesTableOrderingComposer,
    $$SettingsEntriesTableAnnotationComposer,
    $$SettingsEntriesTableCreateCompanionBuilder,
    $$SettingsEntriesTableUpdateCompanionBuilder,
    (
      SettingsEntry,
      BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>
    ),
    SettingsEntry,
    PrefetchHooks Function()> {
  $$SettingsEntriesTableTableManager(
      _$AppDatabase db, $SettingsEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsEntriesCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsEntriesCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsEntriesTable,
    SettingsEntry,
    $$SettingsEntriesTableFilterComposer,
    $$SettingsEntriesTableOrderingComposer,
    $$SettingsEntriesTableAnnotationComposer,
    $$SettingsEntriesTableCreateCompanionBuilder,
    $$SettingsEntriesTableUpdateCompanionBuilder,
    (
      SettingsEntry,
      BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>
    ),
    SettingsEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$QuestionRecordsTableTableManager get questionRecords =>
      $$QuestionRecordsTableTableManager(_db, _db.questionRecords);
  $$GeneratedExercisesTableTableManager get generatedExercises =>
      $$GeneratedExercisesTableTableManager(_db, _db.generatedExercises);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$SettingsEntriesTableTableManager get settingsEntries =>
      $$SettingsEntriesTableTableManager(_db, _db.settingsEntries);
}
