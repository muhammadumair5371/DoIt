// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('task'));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _contentHashMeta =
      const VerificationMeta('contentHash');
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
      'content_hash', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _sourceAssetIdMeta =
      const VerificationMeta('sourceAssetId');
  @override
  late final GeneratedColumn<String> sourceAssetId = GeneratedColumn<String>(
      'source_asset_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceImagePathMeta =
      const VerificationMeta('sourceImagePath');
  @override
  late final GeneratedColumn<String> sourceImagePath = GeneratedColumn<String>(
      'source_image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _needsReviewMeta =
      const VerificationMeta('needsReview');
  @override
  late final GeneratedColumn<bool> needsReview = GeneratedColumn<bool>(
      'needs_review', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("needs_review" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
      'confidence', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isNewMeta = const VerificationMeta('isNew');
  @override
  late final GeneratedColumn<bool> isNew = GeneratedColumn<bool>(
      'is_new', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_new" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        type,
        dueDate,
        notes,
        reason,
        contentHash,
        isCompleted,
        completedAt,
        sourceAssetId,
        sourceImagePath,
        needsReview,
        confidence,
        createdAt,
        isNew
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<Task> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('content_hash')) {
      context.handle(
          _contentHashMeta,
          contentHash.isAcceptableOrUnknown(
              data['content_hash']!, _contentHashMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('source_asset_id')) {
      context.handle(
          _sourceAssetIdMeta,
          sourceAssetId.isAcceptableOrUnknown(
              data['source_asset_id']!, _sourceAssetIdMeta));
    }
    if (data.containsKey('source_image_path')) {
      context.handle(
          _sourceImagePathMeta,
          sourceImagePath.isAcceptableOrUnknown(
              data['source_image_path']!, _sourceImagePathMeta));
    }
    if (data.containsKey('needs_review')) {
      context.handle(
          _needsReviewMeta,
          needsReview.isAcceptableOrUnknown(
              data['needs_review']!, _needsReviewMeta));
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_new')) {
      context.handle(
          _isNewMeta, isNew.isAcceptableOrUnknown(data['is_new']!, _isNewMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      contentHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_hash'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      sourceAssetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_asset_id']),
      sourceImagePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_image_path']),
      needsReview: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}needs_review'])!,
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}confidence'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isNew: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_new'])!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final String type;
  final DateTime? dueDate;
  final String notes;
  final String reason;
  final String contentHash;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? sourceAssetId;
  final String? sourceImagePath;
  final bool needsReview;
  final double confidence;
  final DateTime createdAt;
  final bool isNew;
  const Task(
      {required this.id,
      required this.title,
      required this.type,
      this.dueDate,
      required this.notes,
      required this.reason,
      required this.contentHash,
      required this.isCompleted,
      this.completedAt,
      this.sourceAssetId,
      this.sourceImagePath,
      required this.needsReview,
      required this.confidence,
      required this.createdAt,
      required this.isNew});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['notes'] = Variable<String>(notes);
    map['reason'] = Variable<String>(reason);
    map['content_hash'] = Variable<String>(contentHash);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || sourceAssetId != null) {
      map['source_asset_id'] = Variable<String>(sourceAssetId);
    }
    if (!nullToAbsent || sourceImagePath != null) {
      map['source_image_path'] = Variable<String>(sourceImagePath);
    }
    map['needs_review'] = Variable<bool>(needsReview);
    map['confidence'] = Variable<double>(confidence);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_new'] = Variable<bool>(isNew);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      type: Value(type),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      notes: Value(notes),
      reason: Value(reason),
      contentHash: Value(contentHash),
      isCompleted: Value(isCompleted),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      sourceAssetId: sourceAssetId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceAssetId),
      sourceImagePath: sourceImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceImagePath),
      needsReview: Value(needsReview),
      confidence: Value(confidence),
      createdAt: Value(createdAt),
      isNew: Value(isNew),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      notes: serializer.fromJson<String>(json['notes']),
      reason: serializer.fromJson<String>(json['reason']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      sourceAssetId: serializer.fromJson<String?>(json['sourceAssetId']),
      sourceImagePath: serializer.fromJson<String?>(json['sourceImagePath']),
      needsReview: serializer.fromJson<bool>(json['needsReview']),
      confidence: serializer.fromJson<double>(json['confidence']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isNew: serializer.fromJson<bool>(json['isNew']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'notes': serializer.toJson<String>(notes),
      'reason': serializer.toJson<String>(reason),
      'contentHash': serializer.toJson<String>(contentHash),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'sourceAssetId': serializer.toJson<String?>(sourceAssetId),
      'sourceImagePath': serializer.toJson<String?>(sourceImagePath),
      'needsReview': serializer.toJson<bool>(needsReview),
      'confidence': serializer.toJson<double>(confidence),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isNew': serializer.toJson<bool>(isNew),
    };
  }

  Task copyWith(
          {String? id,
          String? title,
          String? type,
          Value<DateTime?> dueDate = const Value.absent(),
          String? notes,
          String? reason,
          String? contentHash,
          bool? isCompleted,
          Value<DateTime?> completedAt = const Value.absent(),
          Value<String?> sourceAssetId = const Value.absent(),
          Value<String?> sourceImagePath = const Value.absent(),
          bool? needsReview,
          double? confidence,
          DateTime? createdAt,
          bool? isNew}) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        type: type ?? this.type,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        notes: notes ?? this.notes,
        reason: reason ?? this.reason,
        contentHash: contentHash ?? this.contentHash,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        sourceAssetId:
            sourceAssetId.present ? sourceAssetId.value : this.sourceAssetId,
        sourceImagePath: sourceImagePath.present
            ? sourceImagePath.value
            : this.sourceImagePath,
        needsReview: needsReview ?? this.needsReview,
        confidence: confidence ?? this.confidence,
        createdAt: createdAt ?? this.createdAt,
        isNew: isNew ?? this.isNew,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      reason: data.reason.present ? data.reason.value : this.reason,
      contentHash:
          data.contentHash.present ? data.contentHash.value : this.contentHash,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      sourceAssetId: data.sourceAssetId.present
          ? data.sourceAssetId.value
          : this.sourceAssetId,
      sourceImagePath: data.sourceImagePath.present
          ? data.sourceImagePath.value
          : this.sourceImagePath,
      needsReview:
          data.needsReview.present ? data.needsReview.value : this.needsReview,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isNew: data.isNew.present ? data.isNew.value : this.isNew,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('dueDate: $dueDate, ')
          ..write('notes: $notes, ')
          ..write('reason: $reason, ')
          ..write('contentHash: $contentHash, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('sourceAssetId: $sourceAssetId, ')
          ..write('sourceImagePath: $sourceImagePath, ')
          ..write('needsReview: $needsReview, ')
          ..write('confidence: $confidence, ')
          ..write('createdAt: $createdAt, ')
          ..write('isNew: $isNew')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      type,
      dueDate,
      notes,
      reason,
      contentHash,
      isCompleted,
      completedAt,
      sourceAssetId,
      sourceImagePath,
      needsReview,
      confidence,
      createdAt,
      isNew);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.type == this.type &&
          other.dueDate == this.dueDate &&
          other.notes == this.notes &&
          other.reason == this.reason &&
          other.contentHash == this.contentHash &&
          other.isCompleted == this.isCompleted &&
          other.completedAt == this.completedAt &&
          other.sourceAssetId == this.sourceAssetId &&
          other.sourceImagePath == this.sourceImagePath &&
          other.needsReview == this.needsReview &&
          other.confidence == this.confidence &&
          other.createdAt == this.createdAt &&
          other.isNew == this.isNew);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> type;
  final Value<DateTime?> dueDate;
  final Value<String> notes;
  final Value<String> reason;
  final Value<String> contentHash;
  final Value<bool> isCompleted;
  final Value<DateTime?> completedAt;
  final Value<String?> sourceAssetId;
  final Value<String?> sourceImagePath;
  final Value<bool> needsReview;
  final Value<double> confidence;
  final Value<DateTime> createdAt;
  final Value<bool> isNew;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.reason = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.sourceAssetId = const Value.absent(),
    this.sourceImagePath = const Value.absent(),
    this.needsReview = const Value.absent(),
    this.confidence = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isNew = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.type = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.reason = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.sourceAssetId = const Value.absent(),
    this.sourceImagePath = const Value.absent(),
    this.needsReview = const Value.absent(),
    this.confidence = const Value.absent(),
    required DateTime createdAt,
    this.isNew = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        createdAt = Value(createdAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? type,
    Expression<DateTime>? dueDate,
    Expression<String>? notes,
    Expression<String>? reason,
    Expression<String>? contentHash,
    Expression<bool>? isCompleted,
    Expression<DateTime>? completedAt,
    Expression<String>? sourceAssetId,
    Expression<String>? sourceImagePath,
    Expression<bool>? needsReview,
    Expression<double>? confidence,
    Expression<DateTime>? createdAt,
    Expression<bool>? isNew,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (dueDate != null) 'due_date': dueDate,
      if (notes != null) 'notes': notes,
      if (reason != null) 'reason': reason,
      if (contentHash != null) 'content_hash': contentHash,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt,
      if (sourceAssetId != null) 'source_asset_id': sourceAssetId,
      if (sourceImagePath != null) 'source_image_path': sourceImagePath,
      if (needsReview != null) 'needs_review': needsReview,
      if (confidence != null) 'confidence': confidence,
      if (createdAt != null) 'created_at': createdAt,
      if (isNew != null) 'is_new': isNew,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? type,
      Value<DateTime?>? dueDate,
      Value<String>? notes,
      Value<String>? reason,
      Value<String>? contentHash,
      Value<bool>? isCompleted,
      Value<DateTime?>? completedAt,
      Value<String?>? sourceAssetId,
      Value<String?>? sourceImagePath,
      Value<bool>? needsReview,
      Value<double>? confidence,
      Value<DateTime>? createdAt,
      Value<bool>? isNew,
      Value<int>? rowid}) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      reason: reason ?? this.reason,
      contentHash: contentHash ?? this.contentHash,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      sourceAssetId: sourceAssetId ?? this.sourceAssetId,
      sourceImagePath: sourceImagePath ?? this.sourceImagePath,
      needsReview: needsReview ?? this.needsReview,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      isNew: isNew ?? this.isNew,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (sourceAssetId.present) {
      map['source_asset_id'] = Variable<String>(sourceAssetId.value);
    }
    if (sourceImagePath.present) {
      map['source_image_path'] = Variable<String>(sourceImagePath.value);
    }
    if (needsReview.present) {
      map['needs_review'] = Variable<bool>(needsReview.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isNew.present) {
      map['is_new'] = Variable<bool>(isNew.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('dueDate: $dueDate, ')
          ..write('notes: $notes, ')
          ..write('reason: $reason, ')
          ..write('contentHash: $contentHash, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('sourceAssetId: $sourceAssetId, ')
          ..write('sourceImagePath: $sourceImagePath, ')
          ..write('needsReview: $needsReview, ')
          ..write('confidence: $confidence, ')
          ..write('createdAt: $createdAt, ')
          ..write('isNew: $isNew, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProcessedScreenshotsTable extends ProcessedScreenshots
    with TableInfo<$ProcessedScreenshotsTable, ProcessedScreenshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProcessedScreenshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentHashMeta =
      const VerificationMeta('contentHash');
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
      'content_hash', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('success'));
  static const VerificationMeta _processedAtMeta =
      const VerificationMeta('processedAt');
  @override
  late final GeneratedColumn<DateTime> processedAt = GeneratedColumn<DateTime>(
      'processed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ocrTextMeta =
      const VerificationMeta('ocrText');
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
      'ocr_text', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _rawAiResponseMeta =
      const VerificationMeta('rawAiResponse');
  @override
  late final GeneratedColumn<String> rawAiResponse = GeneratedColumn<String>(
      'raw_ai_response', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        assetId,
        contentHash,
        status,
        processedAt,
        errorMessage,
        ocrText,
        rawAiResponse,
        attemptCount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'processed_screenshots';
  @override
  VerificationContext validateIntegrity(
      Insertable<ProcessedScreenshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
          _contentHashMeta,
          contentHash.isAcceptableOrUnknown(
              data['content_hash']!, _contentHashMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('processed_at')) {
      context.handle(
          _processedAtMeta,
          processedAt.isAcceptableOrUnknown(
              data['processed_at']!, _processedAtMeta));
    } else if (isInserting) {
      context.missing(_processedAtMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('ocr_text')) {
      context.handle(_ocrTextMeta,
          ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta));
    }
    if (data.containsKey('raw_ai_response')) {
      context.handle(
          _rawAiResponseMeta,
          rawAiResponse.isAcceptableOrUnknown(
              data['raw_ai_response']!, _rawAiResponseMeta));
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId};
  @override
  ProcessedScreenshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcessedScreenshot(
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_id'])!,
      contentHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_hash'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      processedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}processed_at'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      ocrText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ocr_text'])!,
      rawAiResponse: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}raw_ai_response'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
    );
  }

  @override
  $ProcessedScreenshotsTable createAlias(String alias) {
    return $ProcessedScreenshotsTable(attachedDatabase, alias);
  }
}

class ProcessedScreenshot extends DataClass
    implements Insertable<ProcessedScreenshot> {
  final String assetId;
  final String contentHash;
  final String status;
  final DateTime processedAt;
  final String? errorMessage;
  final String ocrText;
  final String rawAiResponse;
  final int attemptCount;
  const ProcessedScreenshot(
      {required this.assetId,
      required this.contentHash,
      required this.status,
      required this.processedAt,
      this.errorMessage,
      required this.ocrText,
      required this.rawAiResponse,
      required this.attemptCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['asset_id'] = Variable<String>(assetId);
    map['content_hash'] = Variable<String>(contentHash);
    map['status'] = Variable<String>(status);
    map['processed_at'] = Variable<DateTime>(processedAt);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['ocr_text'] = Variable<String>(ocrText);
    map['raw_ai_response'] = Variable<String>(rawAiResponse);
    map['attempt_count'] = Variable<int>(attemptCount);
    return map;
  }

  ProcessedScreenshotsCompanion toCompanion(bool nullToAbsent) {
    return ProcessedScreenshotsCompanion(
      assetId: Value(assetId),
      contentHash: Value(contentHash),
      status: Value(status),
      processedAt: Value(processedAt),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      ocrText: Value(ocrText),
      rawAiResponse: Value(rawAiResponse),
      attemptCount: Value(attemptCount),
    );
  }

  factory ProcessedScreenshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcessedScreenshot(
      assetId: serializer.fromJson<String>(json['assetId']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      status: serializer.fromJson<String>(json['status']),
      processedAt: serializer.fromJson<DateTime>(json['processedAt']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      ocrText: serializer.fromJson<String>(json['ocrText']),
      rawAiResponse: serializer.fromJson<String>(json['rawAiResponse']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'assetId': serializer.toJson<String>(assetId),
      'contentHash': serializer.toJson<String>(contentHash),
      'status': serializer.toJson<String>(status),
      'processedAt': serializer.toJson<DateTime>(processedAt),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'ocrText': serializer.toJson<String>(ocrText),
      'rawAiResponse': serializer.toJson<String>(rawAiResponse),
      'attemptCount': serializer.toJson<int>(attemptCount),
    };
  }

  ProcessedScreenshot copyWith(
          {String? assetId,
          String? contentHash,
          String? status,
          DateTime? processedAt,
          Value<String?> errorMessage = const Value.absent(),
          String? ocrText,
          String? rawAiResponse,
          int? attemptCount}) =>
      ProcessedScreenshot(
        assetId: assetId ?? this.assetId,
        contentHash: contentHash ?? this.contentHash,
        status: status ?? this.status,
        processedAt: processedAt ?? this.processedAt,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        ocrText: ocrText ?? this.ocrText,
        rawAiResponse: rawAiResponse ?? this.rawAiResponse,
        attemptCount: attemptCount ?? this.attemptCount,
      );
  ProcessedScreenshot copyWithCompanion(ProcessedScreenshotsCompanion data) {
    return ProcessedScreenshot(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      contentHash:
          data.contentHash.present ? data.contentHash.value : this.contentHash,
      status: data.status.present ? data.status.value : this.status,
      processedAt:
          data.processedAt.present ? data.processedAt.value : this.processedAt,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
      rawAiResponse: data.rawAiResponse.present
          ? data.rawAiResponse.value
          : this.rawAiResponse,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcessedScreenshot(')
          ..write('assetId: $assetId, ')
          ..write('contentHash: $contentHash, ')
          ..write('status: $status, ')
          ..write('processedAt: $processedAt, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('ocrText: $ocrText, ')
          ..write('rawAiResponse: $rawAiResponse, ')
          ..write('attemptCount: $attemptCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(assetId, contentHash, status, processedAt,
      errorMessage, ocrText, rawAiResponse, attemptCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcessedScreenshot &&
          other.assetId == this.assetId &&
          other.contentHash == this.contentHash &&
          other.status == this.status &&
          other.processedAt == this.processedAt &&
          other.errorMessage == this.errorMessage &&
          other.ocrText == this.ocrText &&
          other.rawAiResponse == this.rawAiResponse &&
          other.attemptCount == this.attemptCount);
}

class ProcessedScreenshotsCompanion
    extends UpdateCompanion<ProcessedScreenshot> {
  final Value<String> assetId;
  final Value<String> contentHash;
  final Value<String> status;
  final Value<DateTime> processedAt;
  final Value<String?> errorMessage;
  final Value<String> ocrText;
  final Value<String> rawAiResponse;
  final Value<int> attemptCount;
  final Value<int> rowid;
  const ProcessedScreenshotsCompanion({
    this.assetId = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.status = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.rawAiResponse = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProcessedScreenshotsCompanion.insert({
    required String assetId,
    this.contentHash = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime processedAt,
    this.errorMessage = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.rawAiResponse = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : assetId = Value(assetId),
        processedAt = Value(processedAt);
  static Insertable<ProcessedScreenshot> custom({
    Expression<String>? assetId,
    Expression<String>? contentHash,
    Expression<String>? status,
    Expression<DateTime>? processedAt,
    Expression<String>? errorMessage,
    Expression<String>? ocrText,
    Expression<String>? rawAiResponse,
    Expression<int>? attemptCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (contentHash != null) 'content_hash': contentHash,
      if (status != null) 'status': status,
      if (processedAt != null) 'processed_at': processedAt,
      if (errorMessage != null) 'error_message': errorMessage,
      if (ocrText != null) 'ocr_text': ocrText,
      if (rawAiResponse != null) 'raw_ai_response': rawAiResponse,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProcessedScreenshotsCompanion copyWith(
      {Value<String>? assetId,
      Value<String>? contentHash,
      Value<String>? status,
      Value<DateTime>? processedAt,
      Value<String?>? errorMessage,
      Value<String>? ocrText,
      Value<String>? rawAiResponse,
      Value<int>? attemptCount,
      Value<int>? rowid}) {
    return ProcessedScreenshotsCompanion(
      assetId: assetId ?? this.assetId,
      contentHash: contentHash ?? this.contentHash,
      status: status ?? this.status,
      processedAt: processedAt ?? this.processedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      ocrText: ocrText ?? this.ocrText,
      rawAiResponse: rawAiResponse ?? this.rawAiResponse,
      attemptCount: attemptCount ?? this.attemptCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<DateTime>(processedAt.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
    }
    if (rawAiResponse.present) {
      map['raw_ai_response'] = Variable<String>(rawAiResponse.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProcessedScreenshotsCompanion(')
          ..write('assetId: $assetId, ')
          ..write('contentHash: $contentHash, ')
          ..write('status: $status, ')
          ..write('processedAt: $processedAt, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('ocrText: $ocrText, ')
          ..write('rawAiResponse: $rawAiResponse, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $ProcessedScreenshotsTable processedScreenshots =
      $ProcessedScreenshotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [tasks, processedScreenshots];
}

typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String title,
  Value<String> type,
  Value<DateTime?> dueDate,
  Value<String> notes,
  Value<String> reason,
  Value<String> contentHash,
  Value<bool> isCompleted,
  Value<DateTime?> completedAt,
  Value<String?> sourceAssetId,
  Value<String?> sourceImagePath,
  Value<bool> needsReview,
  Value<double> confidence,
  required DateTime createdAt,
  Value<bool> isNew,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> type,
  Value<DateTime?> dueDate,
  Value<String> notes,
  Value<String> reason,
  Value<String> contentHash,
  Value<bool> isCompleted,
  Value<DateTime?> completedAt,
  Value<String?> sourceAssetId,
  Value<String?> sourceImagePath,
  Value<bool> needsReview,
  Value<double> confidence,
  Value<DateTime> createdAt,
  Value<bool> isNew,
  Value<int> rowid,
});

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentHash => $composableBuilder(
      column: $table.contentHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceAssetId => $composableBuilder(
      column: $table.sourceAssetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceImagePath => $composableBuilder(
      column: $table.sourceImagePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsReview => $composableBuilder(
      column: $table.needsReview, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isNew => $composableBuilder(
      column: $table.isNew, builder: (column) => ColumnFilters(column));
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentHash => $composableBuilder(
      column: $table.contentHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceAssetId => $composableBuilder(
      column: $table.sourceAssetId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceImagePath => $composableBuilder(
      column: $table.sourceImagePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsReview => $composableBuilder(
      column: $table.needsReview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isNew => $composableBuilder(
      column: $table.isNew, builder: (column) => ColumnOrderings(column));
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
      column: $table.contentHash, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<String> get sourceAssetId => $composableBuilder(
      column: $table.sourceAssetId, builder: (column) => column);

  GeneratedColumn<String> get sourceImagePath => $composableBuilder(
      column: $table.sourceImagePath, builder: (column) => column);

  GeneratedColumn<bool> get needsReview => $composableBuilder(
      column: $table.needsReview, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isNew =>
      $composableBuilder(column: $table.isNew, builder: (column) => column);
}

class $$TasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
    Task,
    PrefetchHooks Function()> {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String> contentHash = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> sourceAssetId = const Value.absent(),
            Value<String?> sourceImagePath = const Value.absent(),
            Value<bool> needsReview = const Value.absent(),
            Value<double> confidence = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isNew = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            title: title,
            type: type,
            dueDate: dueDate,
            notes: notes,
            reason: reason,
            contentHash: contentHash,
            isCompleted: isCompleted,
            completedAt: completedAt,
            sourceAssetId: sourceAssetId,
            sourceImagePath: sourceImagePath,
            needsReview: needsReview,
            confidence: confidence,
            createdAt: createdAt,
            isNew: isNew,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String> type = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String> contentHash = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> sourceAssetId = const Value.absent(),
            Value<String?> sourceImagePath = const Value.absent(),
            Value<bool> needsReview = const Value.absent(),
            Value<double> confidence = const Value.absent(),
            required DateTime createdAt,
            Value<bool> isNew = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion.insert(
            id: id,
            title: title,
            type: type,
            dueDate: dueDate,
            notes: notes,
            reason: reason,
            contentHash: contentHash,
            isCompleted: isCompleted,
            completedAt: completedAt,
            sourceAssetId: sourceAssetId,
            sourceImagePath: sourceImagePath,
            needsReview: needsReview,
            confidence: confidence,
            createdAt: createdAt,
            isNew: isNew,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
    Task,
    PrefetchHooks Function()>;
typedef $$ProcessedScreenshotsTableCreateCompanionBuilder
    = ProcessedScreenshotsCompanion Function({
  required String assetId,
  Value<String> contentHash,
  Value<String> status,
  required DateTime processedAt,
  Value<String?> errorMessage,
  Value<String> ocrText,
  Value<String> rawAiResponse,
  Value<int> attemptCount,
  Value<int> rowid,
});
typedef $$ProcessedScreenshotsTableUpdateCompanionBuilder
    = ProcessedScreenshotsCompanion Function({
  Value<String> assetId,
  Value<String> contentHash,
  Value<String> status,
  Value<DateTime> processedAt,
  Value<String?> errorMessage,
  Value<String> ocrText,
  Value<String> rawAiResponse,
  Value<int> attemptCount,
  Value<int> rowid,
});

class $$ProcessedScreenshotsTableFilterComposer
    extends Composer<_$AppDatabase, $ProcessedScreenshotsTable> {
  $$ProcessedScreenshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get assetId => $composableBuilder(
      column: $table.assetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentHash => $composableBuilder(
      column: $table.contentHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get processedAt => $composableBuilder(
      column: $table.processedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ocrText => $composableBuilder(
      column: $table.ocrText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawAiResponse => $composableBuilder(
      column: $table.rawAiResponse, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));
}

class $$ProcessedScreenshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProcessedScreenshotsTable> {
  $$ProcessedScreenshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get assetId => $composableBuilder(
      column: $table.assetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentHash => $composableBuilder(
      column: $table.contentHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get processedAt => $composableBuilder(
      column: $table.processedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ocrText => $composableBuilder(
      column: $table.ocrText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawAiResponse => $composableBuilder(
      column: $table.rawAiResponse,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));
}

class $$ProcessedScreenshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProcessedScreenshotsTable> {
  $$ProcessedScreenshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
      column: $table.contentHash, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get processedAt => $composableBuilder(
      column: $table.processedAt, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);

  GeneratedColumn<String> get rawAiResponse => $composableBuilder(
      column: $table.rawAiResponse, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);
}

class $$ProcessedScreenshotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProcessedScreenshotsTable,
    ProcessedScreenshot,
    $$ProcessedScreenshotsTableFilterComposer,
    $$ProcessedScreenshotsTableOrderingComposer,
    $$ProcessedScreenshotsTableAnnotationComposer,
    $$ProcessedScreenshotsTableCreateCompanionBuilder,
    $$ProcessedScreenshotsTableUpdateCompanionBuilder,
    (
      ProcessedScreenshot,
      BaseReferences<_$AppDatabase, $ProcessedScreenshotsTable,
          ProcessedScreenshot>
    ),
    ProcessedScreenshot,
    PrefetchHooks Function()> {
  $$ProcessedScreenshotsTableTableManager(
      _$AppDatabase db, $ProcessedScreenshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProcessedScreenshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProcessedScreenshotsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProcessedScreenshotsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> assetId = const Value.absent(),
            Value<String> contentHash = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> processedAt = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<String> ocrText = const Value.absent(),
            Value<String> rawAiResponse = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProcessedScreenshotsCompanion(
            assetId: assetId,
            contentHash: contentHash,
            status: status,
            processedAt: processedAt,
            errorMessage: errorMessage,
            ocrText: ocrText,
            rawAiResponse: rawAiResponse,
            attemptCount: attemptCount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String assetId,
            Value<String> contentHash = const Value.absent(),
            Value<String> status = const Value.absent(),
            required DateTime processedAt,
            Value<String?> errorMessage = const Value.absent(),
            Value<String> ocrText = const Value.absent(),
            Value<String> rawAiResponse = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProcessedScreenshotsCompanion.insert(
            assetId: assetId,
            contentHash: contentHash,
            status: status,
            processedAt: processedAt,
            errorMessage: errorMessage,
            ocrText: ocrText,
            rawAiResponse: rawAiResponse,
            attemptCount: attemptCount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProcessedScreenshotsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ProcessedScreenshotsTable,
        ProcessedScreenshot,
        $$ProcessedScreenshotsTableFilterComposer,
        $$ProcessedScreenshotsTableOrderingComposer,
        $$ProcessedScreenshotsTableAnnotationComposer,
        $$ProcessedScreenshotsTableCreateCompanionBuilder,
        $$ProcessedScreenshotsTableUpdateCompanionBuilder,
        (
          ProcessedScreenshot,
          BaseReferences<_$AppDatabase, $ProcessedScreenshotsTable,
              ProcessedScreenshot>
        ),
        ProcessedScreenshot,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$ProcessedScreenshotsTableTableManager get processedScreenshots =>
      $$ProcessedScreenshotsTableTableManager(_db, _db.processedScreenshots);
}
