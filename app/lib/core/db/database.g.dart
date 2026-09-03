// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdOffsetMinutesMeta =
      const VerificationMeta('createdOffsetMinutes');
  @override
  late final GeneratedColumn<int> createdOffsetMinutes = GeneratedColumn<int>(
    'created_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  @override
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
    'attachment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _markerMeta = const VerificationMeta('marker');
  @override
  late final GeneratedColumn<String> marker = GeneratedColumn<String>(
    'marker',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    createdOffsetMinutes,
    updatedAt,
    type,
    body,
    attachmentId,
    dayKey,
    marker,
    groupId,
    isPinned,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('created_offset_minutes')) {
      context.handle(
        _createdOffsetMinutesMeta,
        createdOffsetMinutes.isAcceptableOrUnknown(
          data['created_offset_minutes']!,
          _createdOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdOffsetMinutesMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('marker')) {
      context.handle(
        _markerMeta,
        marker.isAcceptableOrUnknown(data['marker']!, _markerMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      createdOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_offset_minutes'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      attachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_id'],
      ),
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      marker: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}marker'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class Entry extends DataClass implements Insertable<Entry> {
  /// UUID v4, generated from the OS CSPRNG.
  final String id;

  /// The UTC instant, in milliseconds.
  final int createdAt;

  /// Minutes offset from UTC at the moment of creation.
  ///
  /// Stored alongside the instant because "what time did *I* think it was"
  /// matters in a journal, and travel breaks naive timestamps.
  final int createdOffsetMinutes;
  final int updatedAt;

  /// `text` · `voice` · `photo` · `file`.
  final String type;

  /// The note itself. Encrypted with the database, not separately.
  final String? body;
  final String? attachmentId;

  /// `YYYY-MM-DD` in the LOCAL timezone at creation.
  ///
  /// **Fixed at creation and never recalculated.** DATA-MODEL.md is emphatic
  /// about this and it is the one modelling decision that cannot be fixed
  /// later: if you wrote it on what felt like Tuesday, it stays on Tuesday
  /// forever, in every timezone and every future version. Recomputing it would
  /// make entries jump days when someone flies Delhi to London, and produce bug
  /// reports that cannot be fixed without rewriting history.
  final String dayKey;

  /// One optional tap: this one mattered. Not a 1–10 mood scale, not an emotion
  /// wheel — FEATURES-IN-AND-OUT.md is specific that a scale is the wrong shape.
  final String? marker;

  /// Photos chosen in one go share this. Schema v3.
  ///
  /// ── WHY THIS IS NOT A SECOND ATTACHMENT COLUMN ─────────────────────────
  ///
  /// Reported as: *"I don't need 15 different blocks if I upload multiple
  /// photos — I need one block, with the photos grouped."* Right, and that is
  /// how every messaging app on earth has worked for a decade.
  ///
  /// The obvious model is one entry with many attachments, which means a join
  /// table and rewriting every query that touches `attachmentId`. The cheaper
  /// model — and, once you look at it, the more honest one — is that **six
  /// photographs taken in one moment really are six things**, and what the user
  /// is asking for is a *presentation* change, not a data change.
  ///
  /// So each photo stays its own entry, with its own timestamp, its own key and
  /// its own blob. They carry a shared id, and the day view draws consecutive
  /// entries with the same one as a single album tile. Delete one and the
  /// others are untouched. Delete the block and they all go. Nothing else in
  /// the app has to know this column exists.
  ///
  /// Null for everything imported before this, and for anything captured on its
  /// own — which is most things.
  final String? groupId;
  final bool isPinned;

  /// Soft delete. Trash holds for 30 days before a secure purge, so a
  /// mis-tapped delete is recoverable — ETHICAL-DESIGN.md requires destructive
  /// actions to be reversible.
  final int? deletedAt;
  const Entry({
    required this.id,
    required this.createdAt,
    required this.createdOffsetMinutes,
    required this.updatedAt,
    required this.type,
    this.body,
    this.attachmentId,
    required this.dayKey,
    this.marker,
    this.groupId,
    required this.isPinned,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['created_offset_minutes'] = Variable<int>(createdOffsetMinutes);
    map['updated_at'] = Variable<int>(updatedAt);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    if (!nullToAbsent || attachmentId != null) {
      map['attachment_id'] = Variable<String>(attachmentId);
    }
    map['day_key'] = Variable<String>(dayKey);
    if (!nullToAbsent || marker != null) {
      map['marker'] = Variable<String>(marker);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    map['is_pinned'] = Variable<bool>(isPinned);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      createdOffsetMinutes: Value(createdOffsetMinutes),
      updatedAt: Value(updatedAt),
      type: Value(type),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      attachmentId: attachmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentId),
      dayKey: Value(dayKey),
      marker: marker == null && nullToAbsent
          ? const Value.absent()
          : Value(marker),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      isPinned: Value(isPinned),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Entry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      createdOffsetMinutes: serializer.fromJson<int>(
        json['createdOffsetMinutes'],
      ),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      type: serializer.fromJson<String>(json['type']),
      body: serializer.fromJson<String?>(json['body']),
      attachmentId: serializer.fromJson<String?>(json['attachmentId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      marker: serializer.fromJson<String?>(json['marker']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'createdOffsetMinutes': serializer.toJson<int>(createdOffsetMinutes),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'type': serializer.toJson<String>(type),
      'body': serializer.toJson<String?>(body),
      'attachmentId': serializer.toJson<String?>(attachmentId),
      'dayKey': serializer.toJson<String>(dayKey),
      'marker': serializer.toJson<String?>(marker),
      'groupId': serializer.toJson<String?>(groupId),
      'isPinned': serializer.toJson<bool>(isPinned),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Entry copyWith({
    String? id,
    int? createdAt,
    int? createdOffsetMinutes,
    int? updatedAt,
    String? type,
    Value<String?> body = const Value.absent(),
    Value<String?> attachmentId = const Value.absent(),
    String? dayKey,
    Value<String?> marker = const Value.absent(),
    Value<String?> groupId = const Value.absent(),
    bool? isPinned,
    Value<int?> deletedAt = const Value.absent(),
  }) => Entry(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    createdOffsetMinutes: createdOffsetMinutes ?? this.createdOffsetMinutes,
    updatedAt: updatedAt ?? this.updatedAt,
    type: type ?? this.type,
    body: body.present ? body.value : this.body,
    attachmentId: attachmentId.present ? attachmentId.value : this.attachmentId,
    dayKey: dayKey ?? this.dayKey,
    marker: marker.present ? marker.value : this.marker,
    groupId: groupId.present ? groupId.value : this.groupId,
    isPinned: isPinned ?? this.isPinned,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      createdOffsetMinutes: data.createdOffsetMinutes.present
          ? data.createdOffsetMinutes.value
          : this.createdOffsetMinutes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      type: data.type.present ? data.type.value : this.type,
      body: data.body.present ? data.body.value : this.body,
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      marker: data.marker.present ? data.marker.value : this.marker,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOffsetMinutes: $createdOffsetMinutes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('type: $type, ')
          ..write('body: $body, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('dayKey: $dayKey, ')
          ..write('marker: $marker, ')
          ..write('groupId: $groupId, ')
          ..write('isPinned: $isPinned, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    createdOffsetMinutes,
    updatedAt,
    type,
    body,
    attachmentId,
    dayKey,
    marker,
    groupId,
    isPinned,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.createdOffsetMinutes == this.createdOffsetMinutes &&
          other.updatedAt == this.updatedAt &&
          other.type == this.type &&
          other.body == this.body &&
          other.attachmentId == this.attachmentId &&
          other.dayKey == this.dayKey &&
          other.marker == this.marker &&
          other.groupId == this.groupId &&
          other.isPinned == this.isPinned &&
          other.deletedAt == this.deletedAt);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<int> createdOffsetMinutes;
  final Value<int> updatedAt;
  final Value<String> type;
  final Value<String?> body;
  final Value<String?> attachmentId;
  final Value<String> dayKey;
  final Value<String?> marker;
  final Value<String?> groupId;
  final Value<bool> isPinned;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.createdOffsetMinutes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.type = const Value.absent(),
    this.body = const Value.absent(),
    this.attachmentId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.marker = const Value.absent(),
    this.groupId = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntriesCompanion.insert({
    required String id,
    required int createdAt,
    required int createdOffsetMinutes,
    required int updatedAt,
    required String type,
    this.body = const Value.absent(),
    this.attachmentId = const Value.absent(),
    required String dayKey,
    this.marker = const Value.absent(),
    this.groupId = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       createdOffsetMinutes = Value(createdOffsetMinutes),
       updatedAt = Value(updatedAt),
       type = Value(type),
       dayKey = Value(dayKey);
  static Insertable<Entry> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<int>? createdOffsetMinutes,
    Expression<int>? updatedAt,
    Expression<String>? type,
    Expression<String>? body,
    Expression<String>? attachmentId,
    Expression<String>? dayKey,
    Expression<String>? marker,
    Expression<String>? groupId,
    Expression<bool>? isPinned,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (createdOffsetMinutes != null)
        'created_offset_minutes': createdOffsetMinutes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (type != null) 'type': type,
      if (body != null) 'body': body,
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (dayKey != null) 'day_key': dayKey,
      if (marker != null) 'marker': marker,
      if (groupId != null) 'group_id': groupId,
      if (isPinned != null) 'is_pinned': isPinned,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntriesCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAt,
    Value<int>? createdOffsetMinutes,
    Value<int>? updatedAt,
    Value<String>? type,
    Value<String?>? body,
    Value<String?>? attachmentId,
    Value<String>? dayKey,
    Value<String?>? marker,
    Value<String?>? groupId,
    Value<bool>? isPinned,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      createdOffsetMinutes: createdOffsetMinutes ?? this.createdOffsetMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      body: body ?? this.body,
      attachmentId: attachmentId ?? this.attachmentId,
      dayKey: dayKey ?? this.dayKey,
      marker: marker ?? this.marker,
      groupId: groupId ?? this.groupId,
      isPinned: isPinned ?? this.isPinned,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (createdOffsetMinutes.present) {
      map['created_offset_minutes'] = Variable<int>(createdOffsetMinutes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (marker.present) {
      map['marker'] = Variable<String>(marker.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('createdOffsetMinutes: $createdOffsetMinutes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('type: $type, ')
          ..write('body: $body, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('dayKey: $dayKey, ')
          ..write('marker: $marker, ')
          ..write('groupId: $groupId, ')
          ..write('isPinned: $isPinned, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colourMeta = const VerificationMeta('colour');
  @override
  late final GeneratedColumn<String> colour = GeneratedColumn<String>(
    'colour',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    name,
    icon,
    colour,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Folder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
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
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('colour')) {
      context.handle(
        _colourMeta,
        colour.isAcceptableOrUnknown(data['colour']!, _colourMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      colour: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}colour'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final String id;

  /// NULL means root. Self-referencing tree, arbitrary depth.
  final String? parentId;

  /// Encrypted with the database like everything else, because **folder names
  /// are content**. THREAT-MODEL.md ranks them High: `Dr. Mehta — therapy`
  /// gives away more than the entries inside it.
  final String name;
  final String? icon;
  final String? colour;

  /// Manual ordering, because people care where their folders sit.
  final int sortOrder;
  final int createdAt;
  const Folder({
    required this.id,
    this.parentId,
    required this.name,
    this.icon,
    this.colour,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || colour != null) {
      map['colour'] = Variable<String>(colour);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      colour: colour == null && nullToAbsent
          ? const Value.absent()
          : Value(colour),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Folder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String?>(json['icon']),
      colour: serializer.fromJson<String?>(json['colour']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String?>(icon),
      'colour': serializer.toJson<String?>(colour),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Folder copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? name,
    Value<String?> icon = const Value.absent(),
    Value<String?> colour = const Value.absent(),
    int? sortOrder,
    int? createdAt,
  }) => Folder(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    name: name ?? this.name,
    icon: icon.present ? icon.value : this.icon,
    colour: colour.present ? colour.value : this.colour,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      colour: data.colour.present ? data.colour.value : this.colour,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('colour: $colour, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, parentId, name, icon, colour, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.colour == this.colour &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<String?> icon;
  final Value<String?> colour;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> rowid;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.colour = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    this.colour = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Folder> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? colour,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (colour != null) 'colour': colour,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String>? name,
    Value<String?>? icon,
    Value<String?>? colour,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return FoldersCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colour: colour ?? this.colour,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (colour.present) {
      map['colour'] = Variable<String>(colour.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('colour: $colour, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntryFoldersTable extends EntryFolders
    with TableInfo<$EntryFoldersTable, EntryFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entries (id)',
    ),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES folders (id)',
    ),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entryId, folderId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryFolder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId, folderId};
  @override
  EntryFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryFolder(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $EntryFoldersTable createAlias(String alias) {
    return $EntryFoldersTable(attachedDatabase, alias);
  }
}

class EntryFolder extends DataClass implements Insertable<EntryFolder> {
  final String entryId;
  final String folderId;
  final int addedAt;
  const EntryFolder({
    required this.entryId,
    required this.folderId,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<String>(entryId);
    map['folder_id'] = Variable<String>(folderId);
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  EntryFoldersCompanion toCompanion(bool nullToAbsent) {
    return EntryFoldersCompanion(
      entryId: Value(entryId),
      folderId: Value(folderId),
      addedAt: Value(addedAt),
    );
  }

  factory EntryFolder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryFolder(
      entryId: serializer.fromJson<String>(json['entryId']),
      folderId: serializer.fromJson<String>(json['folderId']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<String>(entryId),
      'folderId': serializer.toJson<String>(folderId),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  EntryFolder copyWith({String? entryId, String? folderId, int? addedAt}) =>
      EntryFolder(
        entryId: entryId ?? this.entryId,
        folderId: folderId ?? this.folderId,
        addedAt: addedAt ?? this.addedAt,
      );
  EntryFolder copyWithCompanion(EntryFoldersCompanion data) {
    return EntryFolder(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryFolder(')
          ..write('entryId: $entryId, ')
          ..write('folderId: $folderId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryId, folderId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryFolder &&
          other.entryId == this.entryId &&
          other.folderId == this.folderId &&
          other.addedAt == this.addedAt);
}

class EntryFoldersCompanion extends UpdateCompanion<EntryFolder> {
  final Value<String> entryId;
  final Value<String> folderId;
  final Value<int> addedAt;
  final Value<int> rowid;
  const EntryFoldersCompanion({
    this.entryId = const Value.absent(),
    this.folderId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryFoldersCompanion.insert({
    required String entryId,
    required String folderId,
    required int addedAt,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       folderId = Value(folderId),
       addedAt = Value(addedAt);
  static Insertable<EntryFolder> custom({
    Expression<String>? entryId,
    Expression<String>? folderId,
    Expression<int>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (folderId != null) 'folder_id': folderId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryFoldersCompanion copyWith({
    Value<String>? entryId,
    Value<String>? folderId,
    Value<int>? addedAt,
    Value<int>? rowid,
  }) {
    return EntryFoldersCompanion(
      entryId: entryId ?? this.entryId,
      folderId: folderId ?? this.folderId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryFoldersCompanion(')
          ..write('entryId: $entryId, ')
          ..write('folderId: $folderId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileKeyMeta = const VerificationMeta(
    'fileKey',
  );
  @override
  late final GeneratedColumn<Uint8List> fileKey = GeneratedColumn<Uint8List>(
    'file_key',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalNameMeta = const VerificationMeta(
    'originalName',
  );
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
    'original_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailIdMeta = const VerificationMeta(
    'thumbnailId',
  );
  @override
  late final GeneratedColumn<String> thumbnailId = GeneratedColumn<String>(
    'thumbnail_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcriptMeta = const VerificationMeta(
    'transcript',
  );
  @override
  late final GeneratedColumn<String> transcript = GeneratedColumn<String>(
    'transcript',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waveformMeta = const VerificationMeta(
    'waveform',
  );
  @override
  late final GeneratedColumn<Uint8List> waveform = GeneratedColumn<Uint8List>(
    'waveform',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalSizeMeta = const VerificationMeta(
    'originalSize',
  );
  @override
  late final GeneratedColumn<int> originalSize = GeneratedColumn<int>(
    'original_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPageMeta = const VerificationMeta(
    'lastPage',
  );
  @override
  late final GeneratedColumn<int> lastPage = GeneratedColumn<int>(
    'last_page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileKey,
    originalName,
    mimeType,
    byteSize,
    durationMs,
    width,
    height,
    thumbnailId,
    transcript,
    waveform,
    originalSize,
    lastPage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('file_key')) {
      context.handle(
        _fileKeyMeta,
        fileKey.isAcceptableOrUnknown(data['file_key']!, _fileKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_fileKeyMeta);
    }
    if (data.containsKey('original_name')) {
      context.handle(
        _originalNameMeta,
        originalName.isAcceptableOrUnknown(
          data['original_name']!,
          _originalNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalNameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('thumbnail_id')) {
      context.handle(
        _thumbnailIdMeta,
        thumbnailId.isAcceptableOrUnknown(
          data['thumbnail_id']!,
          _thumbnailIdMeta,
        ),
      );
    }
    if (data.containsKey('transcript')) {
      context.handle(
        _transcriptMeta,
        transcript.isAcceptableOrUnknown(data['transcript']!, _transcriptMeta),
      );
    }
    if (data.containsKey('waveform')) {
      context.handle(
        _waveformMeta,
        waveform.isAcceptableOrUnknown(data['waveform']!, _waveformMeta),
      );
    }
    if (data.containsKey('original_size')) {
      context.handle(
        _originalSizeMeta,
        originalSize.isAcceptableOrUnknown(
          data['original_size']!,
          _originalSizeMeta,
        ),
      );
    }
    if (data.containsKey('last_page')) {
      context.handle(
        _lastPageMeta,
        lastPage.isAcceptableOrUnknown(data['last_page']!, _lastPageMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fileKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}file_key'],
      )!,
      originalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_name'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      thumbnailId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_id'],
      ),
      transcript: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcript'],
      ),
      waveform: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}waveform'],
      ),
      originalSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_size'],
      ),
      lastPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_page'],
      ),
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  /// Also the on-disk filename: `attachments/<id>.enc`. A random UUID and
  /// nothing else — no extension, no hint. Someone browsing the app's storage
  /// sees a flat pile of identically-shaped blobs and cannot tell a voice note
  /// from a photo from a tax PDF.
  final String id;

  /// This file's own 256-bit key. Safe here precisely because the database it
  /// sits in is encrypted.
  final Uint8List fileKey;

  /// The real filename, which lives here rather than on the filesystem.
  final String originalName;
  final String mimeType;
  final int byteSize;
  final int? durationMs;
  final int? width;
  final int? height;
  final String? thumbnailId;

  /// On-device voice transcription, if it is ever built. The column exists now
  /// so the model does not have to change later — DATA-MODEL.md put it here
  /// deliberately.
  final String? transcript;

  /// The shape of a voice note, as one byte per sample. Schema v2.
  ///
  /// WHY IT IS STORED RATHER THAN COMPUTED
  ///
  /// A waveform drawn from the audio has to decode the audio, and decoding a
  /// ten-minute AAC file to draw a 60-pixel-wide picture is absurd — it would
  /// happen on every scroll, for every note on the day, on the isolate that
  /// draws the screen. `PLAN.md` §8.1 is explicit: computed **once at record
  /// time**, from the amplitude samples the recorder is already reporting for
  /// the live waveform, and never recomputed.
  ///
  /// One byte per sample, 0–255, downsampled to at most 96 samples. That is
  /// 96 bytes for a note of any length — a rounding error next to the audio —
  /// and 96 bars is more than a phone-width waveform can show anyway.
  ///
  /// Null for every voice note recorded before this column existed, and for
  /// audio files imported from elsewhere. Those draw a flat placeholder rather
  /// than a lie, which is the honest answer to "we do not know the shape".
  final Uint8List? waveform;

  /// What this file weighed before Lamplight re-encoded it. Schema v4.
  ///
  /// **ISSUE 12 — "how do I know that the thing is getting compressed?"**
  ///
  /// A fair question, and the honest answer was that he could not know. Photos
  /// and videos have been re-encoded at import since round five, and the only
  /// evidence was a smaller number he had nothing to compare against.
  ///
  /// So the original size is kept. It is one integer per attachment and it
  /// makes the saving *showable*: "2.1 MB, was 14.8 MB" on the file itself, and
  /// a line at the moment of import saying what was saved.
  ///
  /// Null for everything imported before this column existed, and null for
  /// anything that was not re-encoded at all — a PDF, a text file, a GIF. Null
  /// means "no claim", and the app then says nothing rather than implying a
  /// saving of zero. See `humanSaving`.
  final int? originalSize;

  /// Where you had got to in this document. Schema v5.
  ///
  /// **ROUND EIGHT, ISSUE 1B** — *"What it misses? Page numbers, it doesn't
  /// remembers what was the last page when I closed that PDF."*
  ///
  /// Zero-based, and null for everything that has never been opened since this
  /// column existed. Null means *start at the beginning*, which is the right
  /// answer for a document nobody has read rather than a guess at one.
  ///
  /// **In the database, and not in settings, and that is a privacy decision.**
  /// The vault's database is encrypted; `settings.json` is not. "Attachment
  /// 9f3e was left on page 212" is a fact about a person's reading, and a
  /// six-hundred-page document left on page 212 says something a
  /// three-page one does not. It is small, and small facts about somebody's
  /// papers are exactly the kind this app has decided not to leave lying about.
  final int? lastPage;
  const Attachment({
    required this.id,
    required this.fileKey,
    required this.originalName,
    required this.mimeType,
    required this.byteSize,
    this.durationMs,
    this.width,
    this.height,
    this.thumbnailId,
    this.transcript,
    this.waveform,
    this.originalSize,
    this.lastPage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['file_key'] = Variable<Uint8List>(fileKey);
    map['original_name'] = Variable<String>(originalName);
    map['mime_type'] = Variable<String>(mimeType);
    map['byte_size'] = Variable<int>(byteSize);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || thumbnailId != null) {
      map['thumbnail_id'] = Variable<String>(thumbnailId);
    }
    if (!nullToAbsent || transcript != null) {
      map['transcript'] = Variable<String>(transcript);
    }
    if (!nullToAbsent || waveform != null) {
      map['waveform'] = Variable<Uint8List>(waveform);
    }
    if (!nullToAbsent || originalSize != null) {
      map['original_size'] = Variable<int>(originalSize);
    }
    if (!nullToAbsent || lastPage != null) {
      map['last_page'] = Variable<int>(lastPage);
    }
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      fileKey: Value(fileKey),
      originalName: Value(originalName),
      mimeType: Value(mimeType),
      byteSize: Value(byteSize),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      thumbnailId: thumbnailId == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailId),
      transcript: transcript == null && nullToAbsent
          ? const Value.absent()
          : Value(transcript),
      waveform: waveform == null && nullToAbsent
          ? const Value.absent()
          : Value(waveform),
      originalSize: originalSize == null && nullToAbsent
          ? const Value.absent()
          : Value(originalSize),
      lastPage: lastPage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPage),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<String>(json['id']),
      fileKey: serializer.fromJson<Uint8List>(json['fileKey']),
      originalName: serializer.fromJson<String>(json['originalName']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      thumbnailId: serializer.fromJson<String?>(json['thumbnailId']),
      transcript: serializer.fromJson<String?>(json['transcript']),
      waveform: serializer.fromJson<Uint8List?>(json['waveform']),
      originalSize: serializer.fromJson<int?>(json['originalSize']),
      lastPage: serializer.fromJson<int?>(json['lastPage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fileKey': serializer.toJson<Uint8List>(fileKey),
      'originalName': serializer.toJson<String>(originalName),
      'mimeType': serializer.toJson<String>(mimeType),
      'byteSize': serializer.toJson<int>(byteSize),
      'durationMs': serializer.toJson<int?>(durationMs),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'thumbnailId': serializer.toJson<String?>(thumbnailId),
      'transcript': serializer.toJson<String?>(transcript),
      'waveform': serializer.toJson<Uint8List?>(waveform),
      'originalSize': serializer.toJson<int?>(originalSize),
      'lastPage': serializer.toJson<int?>(lastPage),
    };
  }

  Attachment copyWith({
    String? id,
    Uint8List? fileKey,
    String? originalName,
    String? mimeType,
    int? byteSize,
    Value<int?> durationMs = const Value.absent(),
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<String?> thumbnailId = const Value.absent(),
    Value<String?> transcript = const Value.absent(),
    Value<Uint8List?> waveform = const Value.absent(),
    Value<int?> originalSize = const Value.absent(),
    Value<int?> lastPage = const Value.absent(),
  }) => Attachment(
    id: id ?? this.id,
    fileKey: fileKey ?? this.fileKey,
    originalName: originalName ?? this.originalName,
    mimeType: mimeType ?? this.mimeType,
    byteSize: byteSize ?? this.byteSize,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    thumbnailId: thumbnailId.present ? thumbnailId.value : this.thumbnailId,
    transcript: transcript.present ? transcript.value : this.transcript,
    waveform: waveform.present ? waveform.value : this.waveform,
    originalSize: originalSize.present ? originalSize.value : this.originalSize,
    lastPage: lastPage.present ? lastPage.value : this.lastPage,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      fileKey: data.fileKey.present ? data.fileKey.value : this.fileKey,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      thumbnailId: data.thumbnailId.present
          ? data.thumbnailId.value
          : this.thumbnailId,
      transcript: data.transcript.present
          ? data.transcript.value
          : this.transcript,
      waveform: data.waveform.present ? data.waveform.value : this.waveform,
      originalSize: data.originalSize.present
          ? data.originalSize.value
          : this.originalSize,
      lastPage: data.lastPage.present ? data.lastPage.value : this.lastPage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('fileKey: $fileKey, ')
          ..write('originalName: $originalName, ')
          ..write('mimeType: $mimeType, ')
          ..write('byteSize: $byteSize, ')
          ..write('durationMs: $durationMs, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('thumbnailId: $thumbnailId, ')
          ..write('transcript: $transcript, ')
          ..write('waveform: $waveform, ')
          ..write('originalSize: $originalSize, ')
          ..write('lastPage: $lastPage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    $driftBlobEquality.hash(fileKey),
    originalName,
    mimeType,
    byteSize,
    durationMs,
    width,
    height,
    thumbnailId,
    transcript,
    $driftBlobEquality.hash(waveform),
    originalSize,
    lastPage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          $driftBlobEquality.equals(other.fileKey, this.fileKey) &&
          other.originalName == this.originalName &&
          other.mimeType == this.mimeType &&
          other.byteSize == this.byteSize &&
          other.durationMs == this.durationMs &&
          other.width == this.width &&
          other.height == this.height &&
          other.thumbnailId == this.thumbnailId &&
          other.transcript == this.transcript &&
          $driftBlobEquality.equals(other.waveform, this.waveform) &&
          other.originalSize == this.originalSize &&
          other.lastPage == this.lastPage);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> id;
  final Value<Uint8List> fileKey;
  final Value<String> originalName;
  final Value<String> mimeType;
  final Value<int> byteSize;
  final Value<int?> durationMs;
  final Value<int?> width;
  final Value<int?> height;
  final Value<String?> thumbnailId;
  final Value<String?> transcript;
  final Value<Uint8List?> waveform;
  final Value<int?> originalSize;
  final Value<int?> lastPage;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.fileKey = const Value.absent(),
    this.originalName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.thumbnailId = const Value.absent(),
    this.transcript = const Value.absent(),
    this.waveform = const Value.absent(),
    this.originalSize = const Value.absent(),
    this.lastPage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required Uint8List fileKey,
    required String originalName,
    required String mimeType,
    required int byteSize,
    this.durationMs = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.thumbnailId = const Value.absent(),
    this.transcript = const Value.absent(),
    this.waveform = const Value.absent(),
    this.originalSize = const Value.absent(),
    this.lastPage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fileKey = Value(fileKey),
       originalName = Value(originalName),
       mimeType = Value(mimeType),
       byteSize = Value(byteSize);
  static Insertable<Attachment> custom({
    Expression<String>? id,
    Expression<Uint8List>? fileKey,
    Expression<String>? originalName,
    Expression<String>? mimeType,
    Expression<int>? byteSize,
    Expression<int>? durationMs,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? thumbnailId,
    Expression<String>? transcript,
    Expression<Uint8List>? waveform,
    Expression<int>? originalSize,
    Expression<int>? lastPage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileKey != null) 'file_key': fileKey,
      if (originalName != null) 'original_name': originalName,
      if (mimeType != null) 'mime_type': mimeType,
      if (byteSize != null) 'byte_size': byteSize,
      if (durationMs != null) 'duration_ms': durationMs,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (thumbnailId != null) 'thumbnail_id': thumbnailId,
      if (transcript != null) 'transcript': transcript,
      if (waveform != null) 'waveform': waveform,
      if (originalSize != null) 'original_size': originalSize,
      if (lastPage != null) 'last_page': lastPage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<Uint8List>? fileKey,
    Value<String>? originalName,
    Value<String>? mimeType,
    Value<int>? byteSize,
    Value<int?>? durationMs,
    Value<int?>? width,
    Value<int?>? height,
    Value<String?>? thumbnailId,
    Value<String?>? transcript,
    Value<Uint8List?>? waveform,
    Value<int?>? originalSize,
    Value<int?>? lastPage,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      fileKey: fileKey ?? this.fileKey,
      originalName: originalName ?? this.originalName,
      mimeType: mimeType ?? this.mimeType,
      byteSize: byteSize ?? this.byteSize,
      durationMs: durationMs ?? this.durationMs,
      width: width ?? this.width,
      height: height ?? this.height,
      thumbnailId: thumbnailId ?? this.thumbnailId,
      transcript: transcript ?? this.transcript,
      waveform: waveform ?? this.waveform,
      originalSize: originalSize ?? this.originalSize,
      lastPage: lastPage ?? this.lastPage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fileKey.present) {
      map['file_key'] = Variable<Uint8List>(fileKey.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (thumbnailId.present) {
      map['thumbnail_id'] = Variable<String>(thumbnailId.value);
    }
    if (transcript.present) {
      map['transcript'] = Variable<String>(transcript.value);
    }
    if (waveform.present) {
      map['waveform'] = Variable<Uint8List>(waveform.value);
    }
    if (originalSize.present) {
      map['original_size'] = Variable<int>(originalSize.value);
    }
    if (lastPage.present) {
      map['last_page'] = Variable<int>(lastPage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('fileKey: $fileKey, ')
          ..write('originalName: $originalName, ')
          ..write('mimeType: $mimeType, ')
          ..write('byteSize: $byteSize, ')
          ..write('durationMs: $durationMs, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('thumbnailId: $thumbnailId, ')
          ..write('transcript: $transcript, ')
          ..write('waveform: $waveform, ')
          ..write('originalSize: $originalSize, ')
          ..write('lastPage: $lastPage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RevisionsTable extends Revisions
    with TableInfo<$RevisionsTable, Revision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RevisionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<int> savedAt = GeneratedColumn<int>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, entryId, body, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Revision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Revision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Revision(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $RevisionsTable createAlias(String alias) {
    return $RevisionsTable(attachedDatabase, alias);
  }
}

class Revision extends DataClass implements Insertable<Revision> {
  final int id;
  final String entryId;
  final String body;
  final int savedAt;
  const Revision({
    required this.id,
    required this.entryId,
    required this.body,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['body'] = Variable<String>(body);
    map['saved_at'] = Variable<int>(savedAt);
    return map;
  }

  RevisionsCompanion toCompanion(bool nullToAbsent) {
    return RevisionsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      body: Value(body),
      savedAt: Value(savedAt),
    );
  }

  factory Revision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Revision(
      id: serializer.fromJson<int>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      body: serializer.fromJson<String>(json['body']),
      savedAt: serializer.fromJson<int>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryId': serializer.toJson<String>(entryId),
      'body': serializer.toJson<String>(body),
      'savedAt': serializer.toJson<int>(savedAt),
    };
  }

  Revision copyWith({int? id, String? entryId, String? body, int? savedAt}) =>
      Revision(
        id: id ?? this.id,
        entryId: entryId ?? this.entryId,
        body: body ?? this.body,
        savedAt: savedAt ?? this.savedAt,
      );
  Revision copyWithCompanion(RevisionsCompanion data) {
    return Revision(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      body: data.body.present ? data.body.value : this.body,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Revision(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('body: $body, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, body, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Revision &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.body == this.body &&
          other.savedAt == this.savedAt);
}

class RevisionsCompanion extends UpdateCompanion<Revision> {
  final Value<int> id;
  final Value<String> entryId;
  final Value<String> body;
  final Value<int> savedAt;
  const RevisionsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.body = const Value.absent(),
    this.savedAt = const Value.absent(),
  });
  RevisionsCompanion.insert({
    this.id = const Value.absent(),
    required String entryId,
    required String body,
    required int savedAt,
  }) : entryId = Value(entryId),
       body = Value(body),
       savedAt = Value(savedAt);
  static Insertable<Revision> custom({
    Expression<int>? id,
    Expression<String>? entryId,
    Expression<String>? body,
    Expression<int>? savedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (body != null) 'body': body,
      if (savedAt != null) 'saved_at': savedAt,
    });
  }

  RevisionsCompanion copyWith({
    Value<int>? id,
    Value<String>? entryId,
    Value<String>? body,
    Value<int>? savedAt,
  }) {
    return RevisionsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      body: body ?? this.body,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<int>(savedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RevisionsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('body: $body, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }
}

class $DayNotesTable extends DayNotes with TableInfo<$DayNotesTable, DayNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _markerMeta = const VerificationMeta('marker');
  @override
  late final GeneratedColumn<String> marker = GeneratedColumn<String>(
    'marker',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [dayKey, body, marker];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('marker')) {
      context.handle(
        _markerMeta,
        marker.isAcceptableOrUnknown(data['marker']!, _markerMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dayKey};
  @override
  DayNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayNote(
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      marker: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}marker'],
      ),
    );
  }

  @override
  $DayNotesTable createAlias(String alias) {
    return $DayNotesTable(attachedDatabase, alias);
  }
}

class DayNote extends DataClass implements Insertable<DayNote> {
  final String dayKey;
  final String? body;
  final String? marker;
  const DayNote({required this.dayKey, this.body, this.marker});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day_key'] = Variable<String>(dayKey);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    if (!nullToAbsent || marker != null) {
      map['marker'] = Variable<String>(marker);
    }
    return map;
  }

  DayNotesCompanion toCompanion(bool nullToAbsent) {
    return DayNotesCompanion(
      dayKey: Value(dayKey),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      marker: marker == null && nullToAbsent
          ? const Value.absent()
          : Value(marker),
    );
  }

  factory DayNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayNote(
      dayKey: serializer.fromJson<String>(json['dayKey']),
      body: serializer.fromJson<String?>(json['body']),
      marker: serializer.fromJson<String?>(json['marker']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dayKey': serializer.toJson<String>(dayKey),
      'body': serializer.toJson<String?>(body),
      'marker': serializer.toJson<String?>(marker),
    };
  }

  DayNote copyWith({
    String? dayKey,
    Value<String?> body = const Value.absent(),
    Value<String?> marker = const Value.absent(),
  }) => DayNote(
    dayKey: dayKey ?? this.dayKey,
    body: body.present ? body.value : this.body,
    marker: marker.present ? marker.value : this.marker,
  );
  DayNote copyWithCompanion(DayNotesCompanion data) {
    return DayNote(
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      body: data.body.present ? data.body.value : this.body,
      marker: data.marker.present ? data.marker.value : this.marker,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayNote(')
          ..write('dayKey: $dayKey, ')
          ..write('body: $body, ')
          ..write('marker: $marker')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dayKey, body, marker);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayNote &&
          other.dayKey == this.dayKey &&
          other.body == this.body &&
          other.marker == this.marker);
}

class DayNotesCompanion extends UpdateCompanion<DayNote> {
  final Value<String> dayKey;
  final Value<String?> body;
  final Value<String?> marker;
  final Value<int> rowid;
  const DayNotesCompanion({
    this.dayKey = const Value.absent(),
    this.body = const Value.absent(),
    this.marker = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayNotesCompanion.insert({
    required String dayKey,
    this.body = const Value.absent(),
    this.marker = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : dayKey = Value(dayKey);
  static Insertable<DayNote> custom({
    Expression<String>? dayKey,
    Expression<String>? body,
    Expression<String>? marker,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dayKey != null) 'day_key': dayKey,
      if (body != null) 'body': body,
      if (marker != null) 'marker': marker,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayNotesCompanion copyWith({
    Value<String>? dayKey,
    Value<String?>? body,
    Value<String?>? marker,
    Value<int>? rowid,
  }) {
    return DayNotesCompanion(
      dayKey: dayKey ?? this.dayKey,
      body: body ?? this.body,
      marker: marker ?? this.marker,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (marker.present) {
      map['marker'] = Variable<String>(marker.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayNotesCompanion(')
          ..write('dayKey: $dayKey, ')
          ..write('body: $body, ')
          ..write('marker: $marker, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$VaultDatabase extends GeneratedDatabase {
  _$VaultDatabase(QueryExecutor e) : super(e);
  $VaultDatabaseManager get managers => $VaultDatabaseManager(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $EntryFoldersTable entryFolders = $EntryFoldersTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $RevisionsTable revisions = $RevisionsTable(this);
  late final $DayNotesTable dayNotes = $DayNotesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    entries,
    folders,
    entryFolders,
    attachments,
    revisions,
    dayNotes,
  ];
}

typedef $$EntriesTableCreateCompanionBuilder = EntriesCompanion Function({
  required String id,
  required int createdAt,
  required int createdOffsetMinutes,
  required int updatedAt,
  required String type,
  Value<String?> body,
  Value<String?> attachmentId,
  required String dayKey,
  Value<String?> marker,
  Value<String?> groupId,
  Value<bool> isPinned,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$EntriesTableUpdateCompanionBuilder = EntriesCompanion Function({
  Value<String> id,
  Value<int> createdAt,
  Value<int> createdOffsetMinutes,
  Value<int> updatedAt,
  Value<String> type,
  Value<String?> body,
  Value<String?> attachmentId,
  Value<String> dayKey,
  Value<String?> marker,
  Value<String?> groupId,
  Value<bool> isPinned,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $$EntriesTableReferences
    extends BaseReferences<_$VaultDatabase, $EntriesTable, Entry> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntryFoldersTable, List<EntryFolder>>
  _entryFoldersRefsTable(_$VaultDatabase db) => MultiTypedResultKey.fromTable(
    db.entryFolders,
    aliasName: 'entries__id__entry_folders__entry_id',
  );

  $$EntryFoldersTableProcessedTableManager get entryFoldersRefs {
    final manager = $$EntryFoldersTableTableManager(
      $_db,
      $_db.entryFolders,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_entryFoldersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EntriesTableFilterComposer
    extends Composer<_$VaultDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
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

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdOffsetMinutes => $composableBuilder(
    column: $table.createdOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marker => $composableBuilder(
    column: $table.marker,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entryFoldersRefs(
    Expression<bool> Function($$EntryFoldersTableFilterComposer f) f,
  ) {
    final $$EntryFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryFolders,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryFoldersTableFilterComposer(
            $db: $db,
            $table: $db.entryFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntriesTableOrderingComposer
    extends Composer<_$VaultDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
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

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdOffsetMinutes => $composableBuilder(
    column: $table.createdOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marker => $composableBuilder(
    column: $table.marker,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$VaultDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get createdOffsetMinutes => $composableBuilder(
    column: $table.createdOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<String> get marker =>
      $composableBuilder(column: $table.marker, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> entryFoldersRefs<T extends Object>(
    Expression<T> Function($$EntryFoldersTableAnnotationComposer a) f,
  ) {
    final $$EntryFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryFolders,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.entryFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $EntriesTable,
          Entry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (Entry, $$EntriesTableReferences),
          Entry,
          PrefetchHooks Function({bool entryFoldersRefs})
        > {
  $$EntriesTableTableManager(_$VaultDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> createdOffsetMinutes = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> attachmentId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<String?> marker = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                createdAt: createdAt,
                createdOffsetMinutes: createdOffsetMinutes,
                updatedAt: updatedAt,
                type: type,
                body: body,
                attachmentId: attachmentId,
                dayKey: dayKey,
                marker: marker,
                groupId: groupId,
                isPinned: isPinned,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAt,
                required int createdOffsetMinutes,
                required int updatedAt,
                required String type,
                Value<String?> body = const Value.absent(),
                Value<String?> attachmentId = const Value.absent(),
                required String dayKey,
                Value<String?> marker = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                createdAt: createdAt,
                createdOffsetMinutes: createdOffsetMinutes,
                updatedAt: updatedAt,
                type: type,
                body: body,
                attachmentId: attachmentId,
                dayKey: dayKey,
                marker: marker,
                groupId: groupId,
                isPinned: isPinned,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryFoldersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (entryFoldersRefs) db.entryFolders],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (entryFoldersRefs)
                    await $_getPrefetchedData<
                      Entry,
                      $EntriesTable,
                      EntryFolder
                    >(
                      currentTable: table,
                      referencedTable: $$EntriesTableReferences
                          ._entryFoldersRefsTable(db),
                      managerFromTypedResult: (p0) => $$EntriesTableReferences(
                        db,
                        table,
                        p0,
                      ).entryFoldersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.entryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $EntriesTable,
      Entry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (Entry, $$EntriesTableReferences),
      Entry,
      PrefetchHooks Function({bool entryFoldersRefs})
    >;
typedef $$FoldersTableCreateCompanionBuilder = FoldersCompanion Function({
  required String id,
  Value<String?> parentId,
  required String name,
  Value<String?> icon,
  Value<String?> colour,
  Value<int> sortOrder,
  required int createdAt,
  Value<int> rowid,
});
typedef $$FoldersTableUpdateCompanionBuilder = FoldersCompanion Function({
  Value<String> id,
  Value<String?> parentId,
  Value<String> name,
  Value<String?> icon,
  Value<String?> colour,
  Value<int> sortOrder,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$FoldersTableReferences
    extends BaseReferences<_$VaultDatabase, $FoldersTable, Folder> {
  $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntryFoldersTable, List<EntryFolder>>
  _entryFoldersRefsTable(_$VaultDatabase db) => MultiTypedResultKey.fromTable(
    db.entryFolders,
    aliasName: 'folders__id__entry_folders__folder_id',
  );

  $$EntryFoldersTableProcessedTableManager get entryFoldersRefs {
    final manager = $$EntryFoldersTableTableManager(
      $_db,
      $_db.entryFolders,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_entryFoldersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FoldersTableFilterComposer
    extends Composer<_$VaultDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
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

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colour => $composableBuilder(
    column: $table.colour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entryFoldersRefs(
    Expression<bool> Function($$EntryFoldersTableFilterComposer f) f,
  ) {
    final $$EntryFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryFolders,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryFoldersTableFilterComposer(
            $db: $db,
            $table: $db.entryFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableOrderingComposer
    extends Composer<_$VaultDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
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

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colour => $composableBuilder(
    column: $table.colour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$VaultDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get colour =>
      $composableBuilder(column: $table.colour, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> entryFoldersRefs<T extends Object>(
    Expression<T> Function($$EntryFoldersTableAnnotationComposer a) f,
  ) {
    final $$EntryFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryFolders,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.entryFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FoldersTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $FoldersTable,
          Folder,
          $$FoldersTableFilterComposer,
          $$FoldersTableOrderingComposer,
          $$FoldersTableAnnotationComposer,
          $$FoldersTableCreateCompanionBuilder,
          $$FoldersTableUpdateCompanionBuilder,
          (Folder, $$FoldersTableReferences),
          Folder,
          PrefetchHooks Function({bool entryFoldersRefs})
        > {
  $$FoldersTableTableManager(_$VaultDatabase db, $FoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> colour = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion(
                id: id,
                parentId: parentId,
                name: name,
                icon: icon,
                colour: colour,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parentId = const Value.absent(),
                required String name,
                Value<String?> icon = const Value.absent(),
                Value<String?> colour = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => FoldersCompanion.insert(
                id: id,
                parentId: parentId,
                name: name,
                icon: icon,
                colour: colour,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryFoldersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (entryFoldersRefs) db.entryFolders],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (entryFoldersRefs)
                    await $_getPrefetchedData<
                      Folder,
                      $FoldersTable,
                      EntryFolder
                    >(
                      currentTable: table,
                      referencedTable: $$FoldersTableReferences
                          ._entryFoldersRefsTable(db),
                      managerFromTypedResult: (p0) => $$FoldersTableReferences(
                        db,
                        table,
                        p0,
                      ).entryFoldersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.folderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $FoldersTable,
      Folder,
      $$FoldersTableFilterComposer,
      $$FoldersTableOrderingComposer,
      $$FoldersTableAnnotationComposer,
      $$FoldersTableCreateCompanionBuilder,
      $$FoldersTableUpdateCompanionBuilder,
      (Folder, $$FoldersTableReferences),
      Folder,
      PrefetchHooks Function({bool entryFoldersRefs})
    >;
typedef $$EntryFoldersTableCreateCompanionBuilder =
    EntryFoldersCompanion Function({
      required String entryId,
      required String folderId,
      required int addedAt,
      Value<int> rowid,
    });
typedef $$EntryFoldersTableUpdateCompanionBuilder =
    EntryFoldersCompanion Function({
      Value<String> entryId,
      Value<String> folderId,
      Value<int> addedAt,
      Value<int> rowid,
    });

final class $$EntryFoldersTableReferences
    extends BaseReferences<_$VaultDatabase, $EntryFoldersTable, EntryFolder> {
  $$EntryFoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EntriesTable _entryIdTable(_$VaultDatabase db) =>
      db.entries.createAlias('entry_folders__entry_id__entries__id');

  $$EntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FoldersTable _folderIdTable(_$VaultDatabase db) =>
      db.folders.createAlias('entry_folders__folder_id__folders__id');

  $$FoldersTableProcessedTableManager get folderId {
    final $_column = $_itemColumn<String>('folder_id')!;

    final manager = $$FoldersTableTableManager(
      $_db,
      $_db.folders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntryFoldersTableFilterComposer
    extends Composer<_$VaultDatabase, $EntryFoldersTable> {
  $$EntryFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EntriesTableFilterComposer get entryId {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoldersTableFilterComposer get folderId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableFilterComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryFoldersTableOrderingComposer
    extends Composer<_$VaultDatabase, $EntryFoldersTable> {
  $$EntryFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntriesTableOrderingComposer get entryId {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoldersTableOrderingComposer get folderId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableOrderingComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryFoldersTableAnnotationComposer
    extends Composer<_$VaultDatabase, $EntryFoldersTable> {
  $$EntryFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$EntriesTableAnnotationComposer get entryId {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FoldersTableAnnotationComposer get folderId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.folders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.folders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryFoldersTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $EntryFoldersTable,
          EntryFolder,
          $$EntryFoldersTableFilterComposer,
          $$EntryFoldersTableOrderingComposer,
          $$EntryFoldersTableAnnotationComposer,
          $$EntryFoldersTableCreateCompanionBuilder,
          $$EntryFoldersTableUpdateCompanionBuilder,
          (EntryFolder, $$EntryFoldersTableReferences),
          EntryFolder,
          PrefetchHooks Function({bool entryId, bool folderId})
        > {
  $$EntryFoldersTableTableManager(_$VaultDatabase db, $EntryFoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entryId = const Value.absent(),
                Value<String> folderId = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryFoldersCompanion(
                entryId: entryId,
                folderId: folderId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entryId,
                required String folderId,
                required int addedAt,
                Value<int> rowid = const Value.absent(),
              }) => EntryFoldersCompanion.insert(
                entryId: entryId,
                folderId: folderId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntryFoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false, folderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entryId,
                        referencedTable: $$EntryFoldersTableReferences
                            ._entryIdTable(db),
                        referencedColumn: $$EntryFoldersTableReferences
                            ._entryIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (folderId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.folderId,
                        referencedTable: $$EntryFoldersTableReferences
                            ._folderIdTable(db),
                        referencedColumn: $$EntryFoldersTableReferences
                            ._folderIdTable(db)
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
        ),
      );
}

typedef $$EntryFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $EntryFoldersTable,
      EntryFolder,
      $$EntryFoldersTableFilterComposer,
      $$EntryFoldersTableOrderingComposer,
      $$EntryFoldersTableAnnotationComposer,
      $$EntryFoldersTableCreateCompanionBuilder,
      $$EntryFoldersTableUpdateCompanionBuilder,
      (EntryFolder, $$EntryFoldersTableReferences),
      EntryFolder,
      PrefetchHooks Function({bool entryId, bool folderId})
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String id,
      required Uint8List fileKey,
      required String originalName,
      required String mimeType,
      required int byteSize,
      Value<int?> durationMs,
      Value<int?> width,
      Value<int?> height,
      Value<String?> thumbnailId,
      Value<String?> transcript,
      Value<Uint8List?> waveform,
      Value<int?> originalSize,
      Value<int?> lastPage,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> id,
      Value<Uint8List> fileKey,
      Value<String> originalName,
      Value<String> mimeType,
      Value<int> byteSize,
      Value<int?> durationMs,
      Value<int?> width,
      Value<int?> height,
      Value<String?> thumbnailId,
      Value<String?> transcript,
      Value<Uint8List?> waveform,
      Value<int?> originalSize,
      Value<int?> lastPage,
      Value<int> rowid,
    });

class $$AttachmentsTableFilterComposer
    extends Composer<_$VaultDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
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

  ColumnFilters<Uint8List> get fileKey => $composableBuilder(
    column: $table.fileKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailId => $composableBuilder(
    column: $table.thumbnailId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get waveform => $composableBuilder(
    column: $table.waveform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalSize => $composableBuilder(
    column: $table.originalSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPage => $composableBuilder(
    column: $table.lastPage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$VaultDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
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

  ColumnOrderings<Uint8List> get fileKey => $composableBuilder(
    column: $table.fileKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailId => $composableBuilder(
    column: $table.thumbnailId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get waveform => $composableBuilder(
    column: $table.waveform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalSize => $composableBuilder(
    column: $table.originalSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPage => $composableBuilder(
    column: $table.lastPage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$VaultDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get fileKey =>
      $composableBuilder(column: $table.fileKey, builder: (column) => column);

  GeneratedColumn<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get thumbnailId => $composableBuilder(
    column: $table.thumbnailId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transcript => $composableBuilder(
    column: $table.transcript,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get waveform =>
      $composableBuilder(column: $table.waveform, builder: (column) => column);

  GeneratedColumn<int> get originalSize => $composableBuilder(
    column: $table.originalSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPage =>
      $composableBuilder(column: $table.lastPage, builder: (column) => column);
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $AttachmentsTable,
          Attachment,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (
            Attachment,
            BaseReferences<_$VaultDatabase, $AttachmentsTable, Attachment>,
          ),
          Attachment,
          PrefetchHooks Function()
        > {
  $$AttachmentsTableTableManager(_$VaultDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<Uint8List> fileKey = const Value.absent(),
                Value<String> originalName = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<String?> thumbnailId = const Value.absent(),
                Value<String?> transcript = const Value.absent(),
                Value<Uint8List?> waveform = const Value.absent(),
                Value<int?> originalSize = const Value.absent(),
                Value<int?> lastPage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                fileKey: fileKey,
                originalName: originalName,
                mimeType: mimeType,
                byteSize: byteSize,
                durationMs: durationMs,
                width: width,
                height: height,
                thumbnailId: thumbnailId,
                transcript: transcript,
                waveform: waveform,
                originalSize: originalSize,
                lastPage: lastPage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required Uint8List fileKey,
                required String originalName,
                required String mimeType,
                required int byteSize,
                Value<int?> durationMs = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<String?> thumbnailId = const Value.absent(),
                Value<String?> transcript = const Value.absent(),
                Value<Uint8List?> waveform = const Value.absent(),
                Value<int?> originalSize = const Value.absent(),
                Value<int?> lastPage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                fileKey: fileKey,
                originalName: originalName,
                mimeType: mimeType,
                byteSize: byteSize,
                durationMs: durationMs,
                width: width,
                height: height,
                thumbnailId: thumbnailId,
                transcript: transcript,
                waveform: waveform,
                originalSize: originalSize,
                lastPage: lastPage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $AttachmentsTable,
      Attachment,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (
        Attachment,
        BaseReferences<_$VaultDatabase, $AttachmentsTable, Attachment>,
      ),
      Attachment,
      PrefetchHooks Function()
    >;
typedef $$RevisionsTableCreateCompanionBuilder = RevisionsCompanion Function({
  Value<int> id,
  required String entryId,
  required String body,
  required int savedAt,
});
typedef $$RevisionsTableUpdateCompanionBuilder = RevisionsCompanion Function({
  Value<int> id,
  Value<String> entryId,
  Value<String> body,
  Value<int> savedAt,
});

class $$RevisionsTableFilterComposer
    extends Composer<_$VaultDatabase, $RevisionsTable> {
  $$RevisionsTableFilterComposer({
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

  ColumnFilters<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RevisionsTableOrderingComposer
    extends Composer<_$VaultDatabase, $RevisionsTable> {
  $$RevisionsTableOrderingComposer({
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

  ColumnOrderings<String> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RevisionsTableAnnotationComposer
    extends Composer<_$VaultDatabase, $RevisionsTable> {
  $$RevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$RevisionsTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $RevisionsTable,
          Revision,
          $$RevisionsTableFilterComposer,
          $$RevisionsTableOrderingComposer,
          $$RevisionsTableAnnotationComposer,
          $$RevisionsTableCreateCompanionBuilder,
          $$RevisionsTableUpdateCompanionBuilder,
          (
            Revision,
            BaseReferences<_$VaultDatabase, $RevisionsTable, Revision>,
          ),
          Revision,
          PrefetchHooks Function()
        > {
  $$RevisionsTableTableManager(_$VaultDatabase db, $RevisionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RevisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RevisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> savedAt = const Value.absent(),
              }) => RevisionsCompanion(
                id: id,
                entryId: entryId,
                body: body,
                savedAt: savedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entryId,
                required String body,
                required int savedAt,
              }) => RevisionsCompanion.insert(
                id: id,
                entryId: entryId,
                body: body,
                savedAt: savedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $RevisionsTable,
      Revision,
      $$RevisionsTableFilterComposer,
      $$RevisionsTableOrderingComposer,
      $$RevisionsTableAnnotationComposer,
      $$RevisionsTableCreateCompanionBuilder,
      $$RevisionsTableUpdateCompanionBuilder,
      (Revision, BaseReferences<_$VaultDatabase, $RevisionsTable, Revision>),
      Revision,
      PrefetchHooks Function()
    >;
typedef $$DayNotesTableCreateCompanionBuilder = DayNotesCompanion Function({
  required String dayKey,
  Value<String?> body,
  Value<String?> marker,
  Value<int> rowid,
});
typedef $$DayNotesTableUpdateCompanionBuilder = DayNotesCompanion Function({
  Value<String> dayKey,
  Value<String?> body,
  Value<String?> marker,
  Value<int> rowid,
});

class $$DayNotesTableFilterComposer
    extends Composer<_$VaultDatabase, $DayNotesTable> {
  $$DayNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marker => $composableBuilder(
    column: $table.marker,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayNotesTableOrderingComposer
    extends Composer<_$VaultDatabase, $DayNotesTable> {
  $$DayNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marker => $composableBuilder(
    column: $table.marker,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayNotesTableAnnotationComposer
    extends Composer<_$VaultDatabase, $DayNotesTable> {
  $$DayNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get marker =>
      $composableBuilder(column: $table.marker, builder: (column) => column);
}

class $$DayNotesTableTableManager
    extends
        RootTableManager<
          _$VaultDatabase,
          $DayNotesTable,
          DayNote,
          $$DayNotesTableFilterComposer,
          $$DayNotesTableOrderingComposer,
          $$DayNotesTableAnnotationComposer,
          $$DayNotesTableCreateCompanionBuilder,
          $$DayNotesTableUpdateCompanionBuilder,
          (DayNote, BaseReferences<_$VaultDatabase, $DayNotesTable, DayNote>),
          DayNote,
          PrefetchHooks Function()
        > {
  $$DayNotesTableTableManager(_$VaultDatabase db, $DayNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> dayKey = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> marker = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayNotesCompanion(
                dayKey: dayKey,
                body: body,
                marker: marker,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String dayKey,
                Value<String?> body = const Value.absent(),
                Value<String?> marker = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayNotesCompanion.insert(
                dayKey: dayKey,
                body: body,
                marker: marker,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$VaultDatabase,
      $DayNotesTable,
      DayNote,
      $$DayNotesTableFilterComposer,
      $$DayNotesTableOrderingComposer,
      $$DayNotesTableAnnotationComposer,
      $$DayNotesTableCreateCompanionBuilder,
      $$DayNotesTableUpdateCompanionBuilder,
      (DayNote, BaseReferences<_$VaultDatabase, $DayNotesTable, DayNote>),
      DayNote,
      PrefetchHooks Function()
    >;

class $VaultDatabaseManager {
  final _$VaultDatabase _db;
  $VaultDatabaseManager(this._db);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$EntryFoldersTableTableManager get entryFolders =>
      $$EntryFoldersTableTableManager(_db, _db.entryFolders);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$RevisionsTableTableManager get revisions =>
      $$RevisionsTableTableManager(_db, _db.revisions);
  $$DayNotesTableTableManager get dayNotes =>
      $$DayNotesTableTableManager(_db, _db.dayNotes);
}
