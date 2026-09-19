// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class Firms extends Table with TableInfo<Firms, FirmRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Firms(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY CHECK (id = lower(id) AND length(id) = 36)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _contactNumberMeta = const VerificationMeta(
    'contactNumber',
  );
  late final GeneratedColumn<String> contactNumber = GeneratedColumn<String>(
    'contact_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _logoBlobMeta = const VerificationMeta(
    'logoBlob',
  );
  late final GeneratedColumn<Uint8List> logoBlob = GeneratedColumn<Uint8List>(
    'logo_blob',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _numberGroupingMeta = const VerificationMeta(
    'numberGrouping',
  );
  late final GeneratedColumn<String> numberGrouping = GeneratedColumn<String>(
    'number_grouping',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'pk\' CHECK (number_grouping IN (\'pk\', \'western\'))',
    defaultValue: const CustomExpression('\'pk\''),
  );
  static const VerificationMeta _showPaisaMeta = const VerificationMeta(
    'showPaisa',
  );
  late final GeneratedColumn<bool> showPaisa = GeneratedColumn<bool>(
    'show_paisa',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  static const VerificationMeta _defaultCountryCodeMeta =
      const VerificationMeta('defaultCountryCode');
  late final GeneratedColumn<String> defaultCountryCode =
      GeneratedColumn<String>(
        'default_country_code',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT \'92\'',
        defaultValue: const CustomExpression('\'92\''),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedByDeviceIdMeta = const VerificationMeta(
    'updatedByDeviceId',
  );
  late final GeneratedColumn<String> updatedByDeviceId =
      GeneratedColumn<String>(
        'updated_by_device_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    contactNumber,
    address,
    logoBlob,
    numberGrouping,
    showPaisa,
    defaultCountryCode,
    createdAt,
    updatedAt,
    updatedByDeviceId,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'firms';
  @override
  VerificationContext validateIntegrity(
    Insertable<FirmRow> instance, {
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
    if (data.containsKey('contact_number')) {
      context.handle(
        _contactNumberMeta,
        contactNumber.isAcceptableOrUnknown(
          data['contact_number']!,
          _contactNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contactNumberMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('logo_blob')) {
      context.handle(
        _logoBlobMeta,
        logoBlob.isAcceptableOrUnknown(data['logo_blob']!, _logoBlobMeta),
      );
    }
    if (data.containsKey('number_grouping')) {
      context.handle(
        _numberGroupingMeta,
        numberGrouping.isAcceptableOrUnknown(
          data['number_grouping']!,
          _numberGroupingMeta,
        ),
      );
    }
    if (data.containsKey('show_paisa')) {
      context.handle(
        _showPaisaMeta,
        showPaisa.isAcceptableOrUnknown(data['show_paisa']!, _showPaisaMeta),
      );
    }
    if (data.containsKey('default_country_code')) {
      context.handle(
        _defaultCountryCodeMeta,
        defaultCountryCode.isAcceptableOrUnknown(
          data['default_country_code']!,
          _defaultCountryCodeMeta,
        ),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device_id')) {
      context.handle(
        _updatedByDeviceIdMeta,
        updatedByDeviceId.isAcceptableOrUnknown(
          data['updated_by_device_id']!,
          _updatedByDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceIdMeta);
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
  FirmRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FirmRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      contactNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_number'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      logoBlob: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}logo_blob'],
      ),
      numberGrouping: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number_grouping'],
      )!,
      showPaisa: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_paisa'],
      )!,
      defaultCountryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_country_code'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  Firms createAlias(String alias) {
    return Firms(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class FirmRow extends DataClass implements Insertable<FirmRow> {
  final String id;
  final String name;
  final String contactNumber;
  final String? address;
  final Uint8List? logoBlob;
  final String numberGrouping;
  final bool showPaisa;
  final String defaultCountryCode;
  final int createdAt;
  final int updatedAt;
  final String updatedByDeviceId;
  final int? deletedAt;
  const FirmRow({
    required this.id,
    required this.name,
    required this.contactNumber,
    this.address,
    this.logoBlob,
    required this.numberGrouping,
    required this.showPaisa,
    required this.defaultCountryCode,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDeviceId,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['contact_number'] = Variable<String>(contactNumber);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || logoBlob != null) {
      map['logo_blob'] = Variable<Uint8List>(logoBlob);
    }
    map['number_grouping'] = Variable<String>(numberGrouping);
    map['show_paisa'] = Variable<bool>(showPaisa);
    map['default_country_code'] = Variable<String>(defaultCountryCode);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['updated_by_device_id'] = Variable<String>(updatedByDeviceId);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  FirmsCompanion toCompanion(bool nullToAbsent) {
    return FirmsCompanion(
      id: Value(id),
      name: Value(name),
      contactNumber: Value(contactNumber),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      logoBlob: logoBlob == null && nullToAbsent
          ? const Value.absent()
          : Value(logoBlob),
      numberGrouping: Value(numberGrouping),
      showPaisa: Value(showPaisa),
      defaultCountryCode: Value(defaultCountryCode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDeviceId: Value(updatedByDeviceId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory FirmRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FirmRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      contactNumber: serializer.fromJson<String>(json['contact_number']),
      address: serializer.fromJson<String?>(json['address']),
      logoBlob: serializer.fromJson<Uint8List?>(json['logo_blob']),
      numberGrouping: serializer.fromJson<String>(json['number_grouping']),
      showPaisa: serializer.fromJson<bool>(json['show_paisa']),
      defaultCountryCode: serializer.fromJson<String>(
        json['default_country_code'],
      ),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      updatedByDeviceId: serializer.fromJson<String>(
        json['updated_by_device_id'],
      ),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'contact_number': serializer.toJson<String>(contactNumber),
      'address': serializer.toJson<String?>(address),
      'logo_blob': serializer.toJson<Uint8List?>(logoBlob),
      'number_grouping': serializer.toJson<String>(numberGrouping),
      'show_paisa': serializer.toJson<bool>(showPaisa),
      'default_country_code': serializer.toJson<String>(defaultCountryCode),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
      'updated_by_device_id': serializer.toJson<String>(updatedByDeviceId),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  FirmRow copyWith({
    String? id,
    String? name,
    String? contactNumber,
    Value<String?> address = const Value.absent(),
    Value<Uint8List?> logoBlob = const Value.absent(),
    String? numberGrouping,
    bool? showPaisa,
    String? defaultCountryCode,
    int? createdAt,
    int? updatedAt,
    String? updatedByDeviceId,
    Value<int?> deletedAt = const Value.absent(),
  }) => FirmRow(
    id: id ?? this.id,
    name: name ?? this.name,
    contactNumber: contactNumber ?? this.contactNumber,
    address: address.present ? address.value : this.address,
    logoBlob: logoBlob.present ? logoBlob.value : this.logoBlob,
    numberGrouping: numberGrouping ?? this.numberGrouping,
    showPaisa: showPaisa ?? this.showPaisa,
    defaultCountryCode: defaultCountryCode ?? this.defaultCountryCode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  FirmRow copyWithCompanion(FirmsCompanion data) {
    return FirmRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      contactNumber: data.contactNumber.present
          ? data.contactNumber.value
          : this.contactNumber,
      address: data.address.present ? data.address.value : this.address,
      logoBlob: data.logoBlob.present ? data.logoBlob.value : this.logoBlob,
      numberGrouping: data.numberGrouping.present
          ? data.numberGrouping.value
          : this.numberGrouping,
      showPaisa: data.showPaisa.present ? data.showPaisa.value : this.showPaisa,
      defaultCountryCode: data.defaultCountryCode.present
          ? data.defaultCountryCode.value
          : this.defaultCountryCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDeviceId: data.updatedByDeviceId.present
          ? data.updatedByDeviceId.value
          : this.updatedByDeviceId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FirmRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('contactNumber: $contactNumber, ')
          ..write('address: $address, ')
          ..write('logoBlob: $logoBlob, ')
          ..write('numberGrouping: $numberGrouping, ')
          ..write('showPaisa: $showPaisa, ')
          ..write('defaultCountryCode: $defaultCountryCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDeviceId: $updatedByDeviceId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    contactNumber,
    address,
    $driftBlobEquality.hash(logoBlob),
    numberGrouping,
    showPaisa,
    defaultCountryCode,
    createdAt,
    updatedAt,
    updatedByDeviceId,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FirmRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.contactNumber == this.contactNumber &&
          other.address == this.address &&
          $driftBlobEquality.equals(other.logoBlob, this.logoBlob) &&
          other.numberGrouping == this.numberGrouping &&
          other.showPaisa == this.showPaisa &&
          other.defaultCountryCode == this.defaultCountryCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDeviceId == this.updatedByDeviceId &&
          other.deletedAt == this.deletedAt);
}

class FirmsCompanion extends UpdateCompanion<FirmRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> contactNumber;
  final Value<String?> address;
  final Value<Uint8List?> logoBlob;
  final Value<String> numberGrouping;
  final Value<bool> showPaisa;
  final Value<String> defaultCountryCode;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> updatedByDeviceId;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const FirmsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.contactNumber = const Value.absent(),
    this.address = const Value.absent(),
    this.logoBlob = const Value.absent(),
    this.numberGrouping = const Value.absent(),
    this.showPaisa = const Value.absent(),
    this.defaultCountryCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDeviceId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FirmsCompanion.insert({
    required String id,
    required String name,
    required String contactNumber,
    this.address = const Value.absent(),
    this.logoBlob = const Value.absent(),
    this.numberGrouping = const Value.absent(),
    this.showPaisa = const Value.absent(),
    this.defaultCountryCode = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    required String updatedByDeviceId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       contactNumber = Value(contactNumber),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDeviceId = Value(updatedByDeviceId);
  static Insertable<FirmRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? contactNumber,
    Expression<String>? address,
    Expression<Uint8List>? logoBlob,
    Expression<String>? numberGrouping,
    Expression<bool>? showPaisa,
    Expression<String>? defaultCountryCode,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? updatedByDeviceId,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (contactNumber != null) 'contact_number': contactNumber,
      if (address != null) 'address': address,
      if (logoBlob != null) 'logo_blob': logoBlob,
      if (numberGrouping != null) 'number_grouping': numberGrouping,
      if (showPaisa != null) 'show_paisa': showPaisa,
      if (defaultCountryCode != null)
        'default_country_code': defaultCountryCode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDeviceId != null) 'updated_by_device_id': updatedByDeviceId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FirmsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? contactNumber,
    Value<String?>? address,
    Value<Uint8List?>? logoBlob,
    Value<String>? numberGrouping,
    Value<bool>? showPaisa,
    Value<String>? defaultCountryCode,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? updatedByDeviceId,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return FirmsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      logoBlob: logoBlob ?? this.logoBlob,
      numberGrouping: numberGrouping ?? this.numberGrouping,
      showPaisa: showPaisa ?? this.showPaisa,
      defaultCountryCode: defaultCountryCode ?? this.defaultCountryCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (contactNumber.present) {
      map['contact_number'] = Variable<String>(contactNumber.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (logoBlob.present) {
      map['logo_blob'] = Variable<Uint8List>(logoBlob.value);
    }
    if (numberGrouping.present) {
      map['number_grouping'] = Variable<String>(numberGrouping.value);
    }
    if (showPaisa.present) {
      map['show_paisa'] = Variable<bool>(showPaisa.value);
    }
    if (defaultCountryCode.present) {
      map['default_country_code'] = Variable<String>(defaultCountryCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updatedByDeviceId.present) {
      map['updated_by_device_id'] = Variable<String>(updatedByDeviceId.value);
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
    return (StringBuffer('FirmsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('contactNumber: $contactNumber, ')
          ..write('address: $address, ')
          ..write('logoBlob: $logoBlob, ')
          ..write('numberGrouping: $numberGrouping, ')
          ..write('showPaisa: $showPaisa, ')
          ..write('defaultCountryCode: $defaultCountryCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDeviceId: $updatedByDeviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Users extends Table with TableInfo<Users, UserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Users(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY CHECK (id = lower(id) AND length(id) = 36)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedByDeviceIdMeta = const VerificationMeta(
    'updatedByDeviceId',
  );
  late final GeneratedColumn<String> updatedByDeviceId =
      GeneratedColumn<String>(
        'updated_by_device_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    email,
    createdAt,
    updatedAt,
    updatedByDeviceId,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRow> instance, {
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
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device_id')) {
      context.handle(
        _updatedByDeviceIdMeta,
        updatedByDeviceId.isAcceptableOrUnknown(
          data['updated_by_device_id']!,
          _updatedByDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceIdMeta);
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
  UserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  Users createAlias(String alias) {
    return Users(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class UserRow extends DataClass implements Insertable<UserRow> {
  final String id;
  final String name;
  final String? email;
  final int createdAt;
  final int updatedAt;
  final String updatedByDeviceId;
  final int? deletedAt;
  const UserRow({
    required this.id,
    required this.name,
    this.email,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDeviceId,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['updated_by_device_id'] = Variable<String>(updatedByDeviceId);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDeviceId: Value(updatedByDeviceId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory UserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String?>(json['email']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      updatedByDeviceId: serializer.fromJson<String>(
        json['updated_by_device_id'],
      ),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String?>(email),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
      'updated_by_device_id': serializer.toJson<String>(updatedByDeviceId),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  UserRow copyWith({
    String? id,
    String? name,
    Value<String?> email = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    String? updatedByDeviceId,
    Value<int?> deletedAt = const Value.absent(),
  }) => UserRow(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email.present ? email.value : this.email,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  UserRow copyWithCompanion(UsersCompanion data) {
    return UserRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDeviceId: data.updatedByDeviceId.present
          ? data.updatedByDeviceId.value
          : this.updatedByDeviceId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDeviceId: $updatedByDeviceId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    email,
    createdAt,
    updatedAt,
    updatedByDeviceId,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.email == this.email &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDeviceId == this.updatedByDeviceId &&
          other.deletedAt == this.deletedAt);
}

class UsersCompanion extends UpdateCompanion<UserRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> email;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> updatedByDeviceId;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDeviceId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String name,
    this.email = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    required String updatedByDeviceId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDeviceId = Value(updatedByDeviceId);
  static Insertable<UserRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? email,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? updatedByDeviceId,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDeviceId != null) 'updated_by_device_id': updatedByDeviceId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? email,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? updatedByDeviceId,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updatedByDeviceId.present) {
      map['updated_by_device_id'] = Variable<String>(updatedByDeviceId.value);
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
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDeviceId: $updatedByDeviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class FirmMembers extends Table with TableInfo<FirmMembers, FirmMemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  FirmMembers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY CHECK (id = lower(id) AND length(id) = 36)',
  );
  static const VerificationMeta _firmIdMeta = const VerificationMeta('firmId');
  late final GeneratedColumn<String> firmId = GeneratedColumn<String>(
    'firm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES firms(id)',
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES users(id)',
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (role IN (\'owner\', \'manager\', \'clerk\'))',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedByDeviceIdMeta = const VerificationMeta(
    'updatedByDeviceId',
  );
  late final GeneratedColumn<String> updatedByDeviceId =
      GeneratedColumn<String>(
        'updated_by_device_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firmId,
    userId,
    role,
    createdAt,
    updatedAt,
    updatedByDeviceId,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'firm_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<FirmMemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('firm_id')) {
      context.handle(
        _firmIdMeta,
        firmId.isAcceptableOrUnknown(data['firm_id']!, _firmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_firmIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device_id')) {
      context.handle(
        _updatedByDeviceIdMeta,
        updatedByDeviceId.isAcceptableOrUnknown(
          data['updated_by_device_id']!,
          _updatedByDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceIdMeta);
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
  FirmMemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FirmMemberRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      firmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firm_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  FirmMembers createAlias(String alias) {
    return FirmMembers(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class FirmMemberRow extends DataClass implements Insertable<FirmMemberRow> {
  final String id;
  final String firmId;
  final String userId;
  final String role;
  final int createdAt;
  final int updatedAt;
  final String updatedByDeviceId;
  final int? deletedAt;
  const FirmMemberRow({
    required this.id,
    required this.firmId,
    required this.userId,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDeviceId,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['firm_id'] = Variable<String>(firmId);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['updated_by_device_id'] = Variable<String>(updatedByDeviceId);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  FirmMembersCompanion toCompanion(bool nullToAbsent) {
    return FirmMembersCompanion(
      id: Value(id),
      firmId: Value(firmId),
      userId: Value(userId),
      role: Value(role),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDeviceId: Value(updatedByDeviceId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory FirmMemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FirmMemberRow(
      id: serializer.fromJson<String>(json['id']),
      firmId: serializer.fromJson<String>(json['firm_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      role: serializer.fromJson<String>(json['role']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      updatedByDeviceId: serializer.fromJson<String>(
        json['updated_by_device_id'],
      ),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'firm_id': serializer.toJson<String>(firmId),
      'user_id': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
      'updated_by_device_id': serializer.toJson<String>(updatedByDeviceId),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  FirmMemberRow copyWith({
    String? id,
    String? firmId,
    String? userId,
    String? role,
    int? createdAt,
    int? updatedAt,
    String? updatedByDeviceId,
    Value<int?> deletedAt = const Value.absent(),
  }) => FirmMemberRow(
    id: id ?? this.id,
    firmId: firmId ?? this.firmId,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  FirmMemberRow copyWithCompanion(FirmMembersCompanion data) {
    return FirmMemberRow(
      id: data.id.present ? data.id.value : this.id,
      firmId: data.firmId.present ? data.firmId.value : this.firmId,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDeviceId: data.updatedByDeviceId.present
          ? data.updatedByDeviceId.value
          : this.updatedByDeviceId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FirmMemberRow(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDeviceId: $updatedByDeviceId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firmId,
    userId,
    role,
    createdAt,
    updatedAt,
    updatedByDeviceId,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FirmMemberRow &&
          other.id == this.id &&
          other.firmId == this.firmId &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDeviceId == this.updatedByDeviceId &&
          other.deletedAt == this.deletedAt);
}

class FirmMembersCompanion extends UpdateCompanion<FirmMemberRow> {
  final Value<String> id;
  final Value<String> firmId;
  final Value<String> userId;
  final Value<String> role;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> updatedByDeviceId;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const FirmMembersCompanion({
    this.id = const Value.absent(),
    this.firmId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDeviceId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FirmMembersCompanion.insert({
    required String id,
    required String firmId,
    required String userId,
    required String role,
    required int createdAt,
    required int updatedAt,
    required String updatedByDeviceId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       firmId = Value(firmId),
       userId = Value(userId),
       role = Value(role),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDeviceId = Value(updatedByDeviceId);
  static Insertable<FirmMemberRow> custom({
    Expression<String>? id,
    Expression<String>? firmId,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? updatedByDeviceId,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firmId != null) 'firm_id': firmId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDeviceId != null) 'updated_by_device_id': updatedByDeviceId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FirmMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? firmId,
    Value<String>? userId,
    Value<String>? role,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? updatedByDeviceId,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return FirmMembersCompanion(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
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
    if (firmId.present) {
      map['firm_id'] = Variable<String>(firmId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updatedByDeviceId.present) {
      map['updated_by_device_id'] = Variable<String>(updatedByDeviceId.value);
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
    return (StringBuffer('FirmMembersCompanion(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDeviceId: $updatedByDeviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Devices extends Table with TableInfo<Devices, DeviceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Devices(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY CHECK (id = lower(id) AND length(id) = 36)',
  );
  static const VerificationMeta _firmIdMeta = const VerificationMeta('firmId');
  late final GeneratedColumn<String> firmId = GeneratedColumn<String>(
    'firm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES firms(id)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _shortCodeMeta = const VerificationMeta(
    'shortCode',
  );
  late final GeneratedColumn<String> shortCode = GeneratedColumn<String>(
    'short_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(short_code) = 4)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedByDeviceIdMeta = const VerificationMeta(
    'updatedByDeviceId',
  );
  late final GeneratedColumn<String> updatedByDeviceId =
      GeneratedColumn<String>(
        'updated_by_device_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firmId,
    name,
    platform,
    shortCode,
    createdAt,
    updatedAt,
    updatedByDeviceId,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('firm_id')) {
      context.handle(
        _firmIdMeta,
        firmId.isAcceptableOrUnknown(data['firm_id']!, _firmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_firmIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('short_code')) {
      context.handle(
        _shortCodeMeta,
        shortCode.isAcceptableOrUnknown(data['short_code']!, _shortCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_shortCodeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device_id')) {
      context.handle(
        _updatedByDeviceIdMeta,
        updatedByDeviceId.isAcceptableOrUnknown(
          data['updated_by_device_id']!,
          _updatedByDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceIdMeta);
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
  DeviceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      firmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firm_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      shortCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_code'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  Devices createAlias(String alias) {
    return Devices(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class DeviceRow extends DataClass implements Insertable<DeviceRow> {
  final String id;
  final String firmId;
  final String name;
  final String platform;
  final String shortCode;
  final int createdAt;
  final int updatedAt;
  final String updatedByDeviceId;
  final int? deletedAt;
  const DeviceRow({
    required this.id,
    required this.firmId,
    required this.name,
    required this.platform,
    required this.shortCode,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDeviceId,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['firm_id'] = Variable<String>(firmId);
    map['name'] = Variable<String>(name);
    map['platform'] = Variable<String>(platform);
    map['short_code'] = Variable<String>(shortCode);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['updated_by_device_id'] = Variable<String>(updatedByDeviceId);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      firmId: Value(firmId),
      name: Value(name),
      platform: Value(platform),
      shortCode: Value(shortCode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDeviceId: Value(updatedByDeviceId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory DeviceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceRow(
      id: serializer.fromJson<String>(json['id']),
      firmId: serializer.fromJson<String>(json['firm_id']),
      name: serializer.fromJson<String>(json['name']),
      platform: serializer.fromJson<String>(json['platform']),
      shortCode: serializer.fromJson<String>(json['short_code']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      updatedByDeviceId: serializer.fromJson<String>(
        json['updated_by_device_id'],
      ),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'firm_id': serializer.toJson<String>(firmId),
      'name': serializer.toJson<String>(name),
      'platform': serializer.toJson<String>(platform),
      'short_code': serializer.toJson<String>(shortCode),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
      'updated_by_device_id': serializer.toJson<String>(updatedByDeviceId),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  DeviceRow copyWith({
    String? id,
    String? firmId,
    String? name,
    String? platform,
    String? shortCode,
    int? createdAt,
    int? updatedAt,
    String? updatedByDeviceId,
    Value<int?> deletedAt = const Value.absent(),
  }) => DeviceRow(
    id: id ?? this.id,
    firmId: firmId ?? this.firmId,
    name: name ?? this.name,
    platform: platform ?? this.platform,
    shortCode: shortCode ?? this.shortCode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  DeviceRow copyWithCompanion(DevicesCompanion data) {
    return DeviceRow(
      id: data.id.present ? data.id.value : this.id,
      firmId: data.firmId.present ? data.firmId.value : this.firmId,
      name: data.name.present ? data.name.value : this.name,
      platform: data.platform.present ? data.platform.value : this.platform,
      shortCode: data.shortCode.present ? data.shortCode.value : this.shortCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDeviceId: data.updatedByDeviceId.present
          ? data.updatedByDeviceId.value
          : this.updatedByDeviceId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceRow(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('name: $name, ')
          ..write('platform: $platform, ')
          ..write('shortCode: $shortCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDeviceId: $updatedByDeviceId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firmId,
    name,
    platform,
    shortCode,
    createdAt,
    updatedAt,
    updatedByDeviceId,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceRow &&
          other.id == this.id &&
          other.firmId == this.firmId &&
          other.name == this.name &&
          other.platform == this.platform &&
          other.shortCode == this.shortCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDeviceId == this.updatedByDeviceId &&
          other.deletedAt == this.deletedAt);
}

class DevicesCompanion extends UpdateCompanion<DeviceRow> {
  final Value<String> id;
  final Value<String> firmId;
  final Value<String> name;
  final Value<String> platform;
  final Value<String> shortCode;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> updatedByDeviceId;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.firmId = const Value.absent(),
    this.name = const Value.absent(),
    this.platform = const Value.absent(),
    this.shortCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDeviceId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String id,
    required String firmId,
    required String name,
    required String platform,
    required String shortCode,
    required int createdAt,
    required int updatedAt,
    required String updatedByDeviceId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       firmId = Value(firmId),
       name = Value(name),
       platform = Value(platform),
       shortCode = Value(shortCode),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDeviceId = Value(updatedByDeviceId);
  static Insertable<DeviceRow> custom({
    Expression<String>? id,
    Expression<String>? firmId,
    Expression<String>? name,
    Expression<String>? platform,
    Expression<String>? shortCode,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? updatedByDeviceId,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firmId != null) 'firm_id': firmId,
      if (name != null) 'name': name,
      if (platform != null) 'platform': platform,
      if (shortCode != null) 'short_code': shortCode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDeviceId != null) 'updated_by_device_id': updatedByDeviceId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith({
    Value<String>? id,
    Value<String>? firmId,
    Value<String>? name,
    Value<String>? platform,
    Value<String>? shortCode,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? updatedByDeviceId,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return DevicesCompanion(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      shortCode: shortCode ?? this.shortCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
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
    if (firmId.present) {
      map['firm_id'] = Variable<String>(firmId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (shortCode.present) {
      map['short_code'] = Variable<String>(shortCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updatedByDeviceId.present) {
      map['updated_by_device_id'] = Variable<String>(updatedByDeviceId.value);
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
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('name: $name, ')
          ..write('platform: $platform, ')
          ..write('shortCode: $shortCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDeviceId: $updatedByDeviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Items extends Table with TableInfo<Items, ItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Items(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY CHECK (id = lower(id) AND length(id) = 36)',
  );
  static const VerificationMeta _firmIdMeta = const VerificationMeta('firmId');
  late final GeneratedColumn<String> firmId = GeneratedColumn<String>(
    'firm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES firms(id)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nameNormalizedMeta = const VerificationMeta(
    'nameNormalized',
  );
  late final GeneratedColumn<String> nameNormalized = GeneratedColumn<String>(
    'name_normalized',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _defaultBagWeightGMeta = const VerificationMeta(
    'defaultBagWeightG',
  );
  late final GeneratedColumn<int> defaultBagWeightG = GeneratedColumn<int>(
    'default_bag_weight_g',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (default_bag_weight_g IS NULL OR default_bag_weight_g > 0)',
  );
  static const VerificationMeta _defaultRateBaseWeightGMeta =
      const VerificationMeta('defaultRateBaseWeightG');
  late final GeneratedColumn<int> defaultRateBaseWeightG = GeneratedColumn<int>(
    'default_rate_base_weight_g',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (default_rate_base_weight_g IS NULL OR default_rate_base_weight_g > 0)',
  );
  static const VerificationMeta _defaultUomMeta = const VerificationMeta(
    'defaultUom',
  );
  late final GeneratedColumn<String> defaultUom = GeneratedColumn<String>(
    'default_uom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'kg\' CHECK (default_uom IN (\'kg\', \'unit\'))',
    defaultValue: const CustomExpression('\'kg\''),
  );
  static const VerificationMeta _trackStockMeta = const VerificationMeta(
    'trackStock',
  );
  late final GeneratedColumn<bool> trackStock = GeneratedColumn<bool>(
    'track_stock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  static const VerificationMeta _createdByUserIdMeta = const VerificationMeta(
    'createdByUserId',
  );
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
    'created_by_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES users(id)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedByDeviceIdMeta = const VerificationMeta(
    'updatedByDeviceId',
  );
  late final GeneratedColumn<String> updatedByDeviceId =
      GeneratedColumn<String>(
        'updated_by_device_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firmId,
    name,
    nameNormalized,
    defaultBagWeightG,
    defaultRateBaseWeightG,
    defaultUom,
    trackStock,
    createdByUserId,
    createdAt,
    updatedAt,
    updatedByDeviceId,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('firm_id')) {
      context.handle(
        _firmIdMeta,
        firmId.isAcceptableOrUnknown(data['firm_id']!, _firmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_firmIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_normalized')) {
      context.handle(
        _nameNormalizedMeta,
        nameNormalized.isAcceptableOrUnknown(
          data['name_normalized']!,
          _nameNormalizedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nameNormalizedMeta);
    }
    if (data.containsKey('default_bag_weight_g')) {
      context.handle(
        _defaultBagWeightGMeta,
        defaultBagWeightG.isAcceptableOrUnknown(
          data['default_bag_weight_g']!,
          _defaultBagWeightGMeta,
        ),
      );
    }
    if (data.containsKey('default_rate_base_weight_g')) {
      context.handle(
        _defaultRateBaseWeightGMeta,
        defaultRateBaseWeightG.isAcceptableOrUnknown(
          data['default_rate_base_weight_g']!,
          _defaultRateBaseWeightGMeta,
        ),
      );
    }
    if (data.containsKey('default_uom')) {
      context.handle(
        _defaultUomMeta,
        defaultUom.isAcceptableOrUnknown(data['default_uom']!, _defaultUomMeta),
      );
    }
    if (data.containsKey('track_stock')) {
      context.handle(
        _trackStockMeta,
        trackStock.isAcceptableOrUnknown(data['track_stock']!, _trackStockMeta),
      );
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
        _createdByUserIdMeta,
        createdByUserId.isAcceptableOrUnknown(
          data['created_by_user_id']!,
          _createdByUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device_id')) {
      context.handle(
        _updatedByDeviceIdMeta,
        updatedByDeviceId.isAcceptableOrUnknown(
          data['updated_by_device_id']!,
          _updatedByDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceIdMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {firmId, id},
  ];
  @override
  ItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      firmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firm_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameNormalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_normalized'],
      )!,
      defaultBagWeightG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_bag_weight_g'],
      ),
      defaultRateBaseWeightG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_rate_base_weight_g'],
      ),
      defaultUom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_uom'],
      )!,
      trackStock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}track_stock'],
      )!,
      createdByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_user_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  Items createAlias(String alias) {
    return Items(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['UNIQUE(firm_id, id)'];
  @override
  bool get dontWriteConstraints => true;
}

class ItemRow extends DataClass implements Insertable<ItemRow> {
  final String id;
  final String firmId;
  final String name;
  final String nameNormalized;
  final int? defaultBagWeightG;
  final int? defaultRateBaseWeightG;
  final String defaultUom;
  final bool trackStock;
  final String createdByUserId;
  final int createdAt;
  final int updatedAt;
  final String updatedByDeviceId;
  final int? deletedAt;
  const ItemRow({
    required this.id,
    required this.firmId,
    required this.name,
    required this.nameNormalized,
    this.defaultBagWeightG,
    this.defaultRateBaseWeightG,
    required this.defaultUom,
    required this.trackStock,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDeviceId,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['firm_id'] = Variable<String>(firmId);
    map['name'] = Variable<String>(name);
    map['name_normalized'] = Variable<String>(nameNormalized);
    if (!nullToAbsent || defaultBagWeightG != null) {
      map['default_bag_weight_g'] = Variable<int>(defaultBagWeightG);
    }
    if (!nullToAbsent || defaultRateBaseWeightG != null) {
      map['default_rate_base_weight_g'] = Variable<int>(defaultRateBaseWeightG);
    }
    map['default_uom'] = Variable<String>(defaultUom);
    map['track_stock'] = Variable<bool>(trackStock);
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['updated_by_device_id'] = Variable<String>(updatedByDeviceId);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      firmId: Value(firmId),
      name: Value(name),
      nameNormalized: Value(nameNormalized),
      defaultBagWeightG: defaultBagWeightG == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultBagWeightG),
      defaultRateBaseWeightG: defaultRateBaseWeightG == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultRateBaseWeightG),
      defaultUom: Value(defaultUom),
      trackStock: Value(trackStock),
      createdByUserId: Value(createdByUserId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDeviceId: Value(updatedByDeviceId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemRow(
      id: serializer.fromJson<String>(json['id']),
      firmId: serializer.fromJson<String>(json['firm_id']),
      name: serializer.fromJson<String>(json['name']),
      nameNormalized: serializer.fromJson<String>(json['name_normalized']),
      defaultBagWeightG: serializer.fromJson<int?>(
        json['default_bag_weight_g'],
      ),
      defaultRateBaseWeightG: serializer.fromJson<int?>(
        json['default_rate_base_weight_g'],
      ),
      defaultUom: serializer.fromJson<String>(json['default_uom']),
      trackStock: serializer.fromJson<bool>(json['track_stock']),
      createdByUserId: serializer.fromJson<String>(json['created_by_user_id']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      updatedByDeviceId: serializer.fromJson<String>(
        json['updated_by_device_id'],
      ),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'firm_id': serializer.toJson<String>(firmId),
      'name': serializer.toJson<String>(name),
      'name_normalized': serializer.toJson<String>(nameNormalized),
      'default_bag_weight_g': serializer.toJson<int?>(defaultBagWeightG),
      'default_rate_base_weight_g': serializer.toJson<int?>(
        defaultRateBaseWeightG,
      ),
      'default_uom': serializer.toJson<String>(defaultUom),
      'track_stock': serializer.toJson<bool>(trackStock),
      'created_by_user_id': serializer.toJson<String>(createdByUserId),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
      'updated_by_device_id': serializer.toJson<String>(updatedByDeviceId),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  ItemRow copyWith({
    String? id,
    String? firmId,
    String? name,
    String? nameNormalized,
    Value<int?> defaultBagWeightG = const Value.absent(),
    Value<int?> defaultRateBaseWeightG = const Value.absent(),
    String? defaultUom,
    bool? trackStock,
    String? createdByUserId,
    int? createdAt,
    int? updatedAt,
    String? updatedByDeviceId,
    Value<int?> deletedAt = const Value.absent(),
  }) => ItemRow(
    id: id ?? this.id,
    firmId: firmId ?? this.firmId,
    name: name ?? this.name,
    nameNormalized: nameNormalized ?? this.nameNormalized,
    defaultBagWeightG: defaultBagWeightG.present
        ? defaultBagWeightG.value
        : this.defaultBagWeightG,
    defaultRateBaseWeightG: defaultRateBaseWeightG.present
        ? defaultRateBaseWeightG.value
        : this.defaultRateBaseWeightG,
    defaultUom: defaultUom ?? this.defaultUom,
    trackStock: trackStock ?? this.trackStock,
    createdByUserId: createdByUserId ?? this.createdByUserId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ItemRow copyWithCompanion(ItemsCompanion data) {
    return ItemRow(
      id: data.id.present ? data.id.value : this.id,
      firmId: data.firmId.present ? data.firmId.value : this.firmId,
      name: data.name.present ? data.name.value : this.name,
      nameNormalized: data.nameNormalized.present
          ? data.nameNormalized.value
          : this.nameNormalized,
      defaultBagWeightG: data.defaultBagWeightG.present
          ? data.defaultBagWeightG.value
          : this.defaultBagWeightG,
      defaultRateBaseWeightG: data.defaultRateBaseWeightG.present
          ? data.defaultRateBaseWeightG.value
          : this.defaultRateBaseWeightG,
      defaultUom: data.defaultUom.present
          ? data.defaultUom.value
          : this.defaultUom,
      trackStock: data.trackStock.present
          ? data.trackStock.value
          : this.trackStock,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDeviceId: data.updatedByDeviceId.present
          ? data.updatedByDeviceId.value
          : this.updatedByDeviceId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemRow(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('name: $name, ')
          ..write('nameNormalized: $nameNormalized, ')
          ..write('defaultBagWeightG: $defaultBagWeightG, ')
          ..write('defaultRateBaseWeightG: $defaultRateBaseWeightG, ')
          ..write('defaultUom: $defaultUom, ')
          ..write('trackStock: $trackStock, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDeviceId: $updatedByDeviceId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firmId,
    name,
    nameNormalized,
    defaultBagWeightG,
    defaultRateBaseWeightG,
    defaultUom,
    trackStock,
    createdByUserId,
    createdAt,
    updatedAt,
    updatedByDeviceId,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemRow &&
          other.id == this.id &&
          other.firmId == this.firmId &&
          other.name == this.name &&
          other.nameNormalized == this.nameNormalized &&
          other.defaultBagWeightG == this.defaultBagWeightG &&
          other.defaultRateBaseWeightG == this.defaultRateBaseWeightG &&
          other.defaultUom == this.defaultUom &&
          other.trackStock == this.trackStock &&
          other.createdByUserId == this.createdByUserId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDeviceId == this.updatedByDeviceId &&
          other.deletedAt == this.deletedAt);
}

class ItemsCompanion extends UpdateCompanion<ItemRow> {
  final Value<String> id;
  final Value<String> firmId;
  final Value<String> name;
  final Value<String> nameNormalized;
  final Value<int?> defaultBagWeightG;
  final Value<int?> defaultRateBaseWeightG;
  final Value<String> defaultUom;
  final Value<bool> trackStock;
  final Value<String> createdByUserId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> updatedByDeviceId;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.firmId = const Value.absent(),
    this.name = const Value.absent(),
    this.nameNormalized = const Value.absent(),
    this.defaultBagWeightG = const Value.absent(),
    this.defaultRateBaseWeightG = const Value.absent(),
    this.defaultUom = const Value.absent(),
    this.trackStock = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDeviceId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    required String firmId,
    required String name,
    required String nameNormalized,
    this.defaultBagWeightG = const Value.absent(),
    this.defaultRateBaseWeightG = const Value.absent(),
    this.defaultUom = const Value.absent(),
    this.trackStock = const Value.absent(),
    required String createdByUserId,
    required int createdAt,
    required int updatedAt,
    required String updatedByDeviceId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       firmId = Value(firmId),
       name = Value(name),
       nameNormalized = Value(nameNormalized),
       createdByUserId = Value(createdByUserId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDeviceId = Value(updatedByDeviceId);
  static Insertable<ItemRow> custom({
    Expression<String>? id,
    Expression<String>? firmId,
    Expression<String>? name,
    Expression<String>? nameNormalized,
    Expression<int>? defaultBagWeightG,
    Expression<int>? defaultRateBaseWeightG,
    Expression<String>? defaultUom,
    Expression<bool>? trackStock,
    Expression<String>? createdByUserId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? updatedByDeviceId,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firmId != null) 'firm_id': firmId,
      if (name != null) 'name': name,
      if (nameNormalized != null) 'name_normalized': nameNormalized,
      if (defaultBagWeightG != null) 'default_bag_weight_g': defaultBagWeightG,
      if (defaultRateBaseWeightG != null)
        'default_rate_base_weight_g': defaultRateBaseWeightG,
      if (defaultUom != null) 'default_uom': defaultUom,
      if (trackStock != null) 'track_stock': trackStock,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDeviceId != null) 'updated_by_device_id': updatedByDeviceId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? firmId,
    Value<String>? name,
    Value<String>? nameNormalized,
    Value<int?>? defaultBagWeightG,
    Value<int?>? defaultRateBaseWeightG,
    Value<String>? defaultUom,
    Value<bool>? trackStock,
    Value<String>? createdByUserId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? updatedByDeviceId,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      name: name ?? this.name,
      nameNormalized: nameNormalized ?? this.nameNormalized,
      defaultBagWeightG: defaultBagWeightG ?? this.defaultBagWeightG,
      defaultRateBaseWeightG:
          defaultRateBaseWeightG ?? this.defaultRateBaseWeightG,
      defaultUom: defaultUom ?? this.defaultUom,
      trackStock: trackStock ?? this.trackStock,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
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
    if (firmId.present) {
      map['firm_id'] = Variable<String>(firmId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameNormalized.present) {
      map['name_normalized'] = Variable<String>(nameNormalized.value);
    }
    if (defaultBagWeightG.present) {
      map['default_bag_weight_g'] = Variable<int>(defaultBagWeightG.value);
    }
    if (defaultRateBaseWeightG.present) {
      map['default_rate_base_weight_g'] = Variable<int>(
        defaultRateBaseWeightG.value,
      );
    }
    if (defaultUom.present) {
      map['default_uom'] = Variable<String>(defaultUom.value);
    }
    if (trackStock.present) {
      map['track_stock'] = Variable<bool>(trackStock.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updatedByDeviceId.present) {
      map['updated_by_device_id'] = Variable<String>(updatedByDeviceId.value);
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
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('name: $name, ')
          ..write('nameNormalized: $nameNormalized, ')
          ..write('defaultBagWeightG: $defaultBagWeightG, ')
          ..write('defaultRateBaseWeightG: $defaultRateBaseWeightG, ')
          ..write('defaultUom: $defaultUom, ')
          ..write('trackStock: $trackStock, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDeviceId: $updatedByDeviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Customers extends Table with TableInfo<Customers, CustomerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Customers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY CHECK (id = lower(id) AND length(id) = 36)',
  );
  static const VerificationMeta _firmIdMeta = const VerificationMeta('firmId');
  late final GeneratedColumn<String> firmId = GeneratedColumn<String>(
    'firm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES firms(id)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nameNormalizedMeta = const VerificationMeta(
    'nameNormalized',
  );
  late final GeneratedColumn<String> nameNormalized = GeneratedColumn<String>(
    'name_normalized',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _phoneNormalizedMeta = const VerificationMeta(
    'phoneNormalized',
  );
  late final GeneratedColumn<String> phoneNormalized = GeneratedColumn<String>(
    'phone_normalized',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdByUserIdMeta = const VerificationMeta(
    'createdByUserId',
  );
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
    'created_by_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES users(id)',
  );
  static const VerificationMeta _mergedIntoIdMeta = const VerificationMeta(
    'mergedIntoId',
  );
  late final GeneratedColumn<String> mergedIntoId = GeneratedColumn<String>(
    'merged_into_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES customers(id)',
  );
  static const VerificationMeta _needsReviewMeta = const VerificationMeta(
    'needsReview',
  );
  late final GeneratedColumn<bool> needsReview = GeneratedColumn<bool>(
    'needs_review',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedByDeviceIdMeta = const VerificationMeta(
    'updatedByDeviceId',
  );
  late final GeneratedColumn<String> updatedByDeviceId =
      GeneratedColumn<String>(
        'updated_by_device_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firmId,
    name,
    nameNormalized,
    phone,
    phoneNormalized,
    notes,
    createdByUserId,
    mergedIntoId,
    needsReview,
    createdAt,
    updatedAt,
    updatedByDeviceId,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('firm_id')) {
      context.handle(
        _firmIdMeta,
        firmId.isAcceptableOrUnknown(data['firm_id']!, _firmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_firmIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_normalized')) {
      context.handle(
        _nameNormalizedMeta,
        nameNormalized.isAcceptableOrUnknown(
          data['name_normalized']!,
          _nameNormalizedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nameNormalizedMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('phone_normalized')) {
      context.handle(
        _phoneNormalizedMeta,
        phoneNormalized.isAcceptableOrUnknown(
          data['phone_normalized']!,
          _phoneNormalizedMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
        _createdByUserIdMeta,
        createdByUserId.isAcceptableOrUnknown(
          data['created_by_user_id']!,
          _createdByUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    if (data.containsKey('merged_into_id')) {
      context.handle(
        _mergedIntoIdMeta,
        mergedIntoId.isAcceptableOrUnknown(
          data['merged_into_id']!,
          _mergedIntoIdMeta,
        ),
      );
    }
    if (data.containsKey('needs_review')) {
      context.handle(
        _needsReviewMeta,
        needsReview.isAcceptableOrUnknown(
          data['needs_review']!,
          _needsReviewMeta,
        ),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device_id')) {
      context.handle(
        _updatedByDeviceIdMeta,
        updatedByDeviceId.isAcceptableOrUnknown(
          data['updated_by_device_id']!,
          _updatedByDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceIdMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {firmId, id},
  ];
  @override
  CustomerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      firmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firm_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameNormalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_normalized'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      phoneNormalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_normalized'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_user_id'],
      )!,
      mergedIntoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merged_into_id'],
      ),
      needsReview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_review'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  Customers createAlias(String alias) {
    return Customers(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['UNIQUE(firm_id, id)'];
  @override
  bool get dontWriteConstraints => true;
}

class CustomerRow extends DataClass implements Insertable<CustomerRow> {
  final String id;
  final String firmId;
  final String name;
  final String nameNormalized;
  final String? phone;
  final String? phoneNormalized;
  final String? notes;
  final String createdByUserId;
  final String? mergedIntoId;
  final bool needsReview;
  final int createdAt;
  final int updatedAt;
  final String updatedByDeviceId;
  final int? deletedAt;
  const CustomerRow({
    required this.id,
    required this.firmId,
    required this.name,
    required this.nameNormalized,
    this.phone,
    this.phoneNormalized,
    this.notes,
    required this.createdByUserId,
    this.mergedIntoId,
    required this.needsReview,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDeviceId,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['firm_id'] = Variable<String>(firmId);
    map['name'] = Variable<String>(name);
    map['name_normalized'] = Variable<String>(nameNormalized);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || phoneNormalized != null) {
      map['phone_normalized'] = Variable<String>(phoneNormalized);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    if (!nullToAbsent || mergedIntoId != null) {
      map['merged_into_id'] = Variable<String>(mergedIntoId);
    }
    map['needs_review'] = Variable<bool>(needsReview);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['updated_by_device_id'] = Variable<String>(updatedByDeviceId);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      firmId: Value(firmId),
      name: Value(name),
      nameNormalized: Value(nameNormalized),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      phoneNormalized: phoneNormalized == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNormalized),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdByUserId: Value(createdByUserId),
      mergedIntoId: mergedIntoId == null && nullToAbsent
          ? const Value.absent()
          : Value(mergedIntoId),
      needsReview: Value(needsReview),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDeviceId: Value(updatedByDeviceId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CustomerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerRow(
      id: serializer.fromJson<String>(json['id']),
      firmId: serializer.fromJson<String>(json['firm_id']),
      name: serializer.fromJson<String>(json['name']),
      nameNormalized: serializer.fromJson<String>(json['name_normalized']),
      phone: serializer.fromJson<String?>(json['phone']),
      phoneNormalized: serializer.fromJson<String?>(json['phone_normalized']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdByUserId: serializer.fromJson<String>(json['created_by_user_id']),
      mergedIntoId: serializer.fromJson<String?>(json['merged_into_id']),
      needsReview: serializer.fromJson<bool>(json['needs_review']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      updatedByDeviceId: serializer.fromJson<String>(
        json['updated_by_device_id'],
      ),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'firm_id': serializer.toJson<String>(firmId),
      'name': serializer.toJson<String>(name),
      'name_normalized': serializer.toJson<String>(nameNormalized),
      'phone': serializer.toJson<String?>(phone),
      'phone_normalized': serializer.toJson<String?>(phoneNormalized),
      'notes': serializer.toJson<String?>(notes),
      'created_by_user_id': serializer.toJson<String>(createdByUserId),
      'merged_into_id': serializer.toJson<String?>(mergedIntoId),
      'needs_review': serializer.toJson<bool>(needsReview),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
      'updated_by_device_id': serializer.toJson<String>(updatedByDeviceId),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  CustomerRow copyWith({
    String? id,
    String? firmId,
    String? name,
    String? nameNormalized,
    Value<String?> phone = const Value.absent(),
    Value<String?> phoneNormalized = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? createdByUserId,
    Value<String?> mergedIntoId = const Value.absent(),
    bool? needsReview,
    int? createdAt,
    int? updatedAt,
    String? updatedByDeviceId,
    Value<int?> deletedAt = const Value.absent(),
  }) => CustomerRow(
    id: id ?? this.id,
    firmId: firmId ?? this.firmId,
    name: name ?? this.name,
    nameNormalized: nameNormalized ?? this.nameNormalized,
    phone: phone.present ? phone.value : this.phone,
    phoneNormalized: phoneNormalized.present
        ? phoneNormalized.value
        : this.phoneNormalized,
    notes: notes.present ? notes.value : this.notes,
    createdByUserId: createdByUserId ?? this.createdByUserId,
    mergedIntoId: mergedIntoId.present ? mergedIntoId.value : this.mergedIntoId,
    needsReview: needsReview ?? this.needsReview,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CustomerRow copyWithCompanion(CustomersCompanion data) {
    return CustomerRow(
      id: data.id.present ? data.id.value : this.id,
      firmId: data.firmId.present ? data.firmId.value : this.firmId,
      name: data.name.present ? data.name.value : this.name,
      nameNormalized: data.nameNormalized.present
          ? data.nameNormalized.value
          : this.nameNormalized,
      phone: data.phone.present ? data.phone.value : this.phone,
      phoneNormalized: data.phoneNormalized.present
          ? data.phoneNormalized.value
          : this.phoneNormalized,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      mergedIntoId: data.mergedIntoId.present
          ? data.mergedIntoId.value
          : this.mergedIntoId,
      needsReview: data.needsReview.present
          ? data.needsReview.value
          : this.needsReview,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedByDeviceId: data.updatedByDeviceId.present
          ? data.updatedByDeviceId.value
          : this.updatedByDeviceId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerRow(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('name: $name, ')
          ..write('nameNormalized: $nameNormalized, ')
          ..write('phone: $phone, ')
          ..write('phoneNormalized: $phoneNormalized, ')
          ..write('notes: $notes, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('mergedIntoId: $mergedIntoId, ')
          ..write('needsReview: $needsReview, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDeviceId: $updatedByDeviceId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firmId,
    name,
    nameNormalized,
    phone,
    phoneNormalized,
    notes,
    createdByUserId,
    mergedIntoId,
    needsReview,
    createdAt,
    updatedAt,
    updatedByDeviceId,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRow &&
          other.id == this.id &&
          other.firmId == this.firmId &&
          other.name == this.name &&
          other.nameNormalized == this.nameNormalized &&
          other.phone == this.phone &&
          other.phoneNormalized == this.phoneNormalized &&
          other.notes == this.notes &&
          other.createdByUserId == this.createdByUserId &&
          other.mergedIntoId == this.mergedIntoId &&
          other.needsReview == this.needsReview &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDeviceId == this.updatedByDeviceId &&
          other.deletedAt == this.deletedAt);
}

class CustomersCompanion extends UpdateCompanion<CustomerRow> {
  final Value<String> id;
  final Value<String> firmId;
  final Value<String> name;
  final Value<String> nameNormalized;
  final Value<String?> phone;
  final Value<String?> phoneNormalized;
  final Value<String?> notes;
  final Value<String> createdByUserId;
  final Value<String?> mergedIntoId;
  final Value<bool> needsReview;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> updatedByDeviceId;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.firmId = const Value.absent(),
    this.name = const Value.absent(),
    this.nameNormalized = const Value.absent(),
    this.phone = const Value.absent(),
    this.phoneNormalized = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.mergedIntoId = const Value.absent(),
    this.needsReview = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDeviceId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String firmId,
    required String name,
    required String nameNormalized,
    this.phone = const Value.absent(),
    this.phoneNormalized = const Value.absent(),
    this.notes = const Value.absent(),
    required String createdByUserId,
    this.mergedIntoId = const Value.absent(),
    this.needsReview = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    required String updatedByDeviceId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       firmId = Value(firmId),
       name = Value(name),
       nameNormalized = Value(nameNormalized),
       createdByUserId = Value(createdByUserId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDeviceId = Value(updatedByDeviceId);
  static Insertable<CustomerRow> custom({
    Expression<String>? id,
    Expression<String>? firmId,
    Expression<String>? name,
    Expression<String>? nameNormalized,
    Expression<String>? phone,
    Expression<String>? phoneNormalized,
    Expression<String>? notes,
    Expression<String>? createdByUserId,
    Expression<String>? mergedIntoId,
    Expression<bool>? needsReview,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? updatedByDeviceId,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firmId != null) 'firm_id': firmId,
      if (name != null) 'name': name,
      if (nameNormalized != null) 'name_normalized': nameNormalized,
      if (phone != null) 'phone': phone,
      if (phoneNormalized != null) 'phone_normalized': phoneNormalized,
      if (notes != null) 'notes': notes,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (mergedIntoId != null) 'merged_into_id': mergedIntoId,
      if (needsReview != null) 'needs_review': needsReview,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDeviceId != null) 'updated_by_device_id': updatedByDeviceId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith({
    Value<String>? id,
    Value<String>? firmId,
    Value<String>? name,
    Value<String>? nameNormalized,
    Value<String?>? phone,
    Value<String?>? phoneNormalized,
    Value<String?>? notes,
    Value<String>? createdByUserId,
    Value<String?>? mergedIntoId,
    Value<bool>? needsReview,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? updatedByDeviceId,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      name: name ?? this.name,
      nameNormalized: nameNormalized ?? this.nameNormalized,
      phone: phone ?? this.phone,
      phoneNormalized: phoneNormalized ?? this.phoneNormalized,
      notes: notes ?? this.notes,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      mergedIntoId: mergedIntoId ?? this.mergedIntoId,
      needsReview: needsReview ?? this.needsReview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
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
    if (firmId.present) {
      map['firm_id'] = Variable<String>(firmId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameNormalized.present) {
      map['name_normalized'] = Variable<String>(nameNormalized.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (phoneNormalized.present) {
      map['phone_normalized'] = Variable<String>(phoneNormalized.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (mergedIntoId.present) {
      map['merged_into_id'] = Variable<String>(mergedIntoId.value);
    }
    if (needsReview.present) {
      map['needs_review'] = Variable<bool>(needsReview.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updatedByDeviceId.present) {
      map['updated_by_device_id'] = Variable<String>(updatedByDeviceId.value);
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
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('name: $name, ')
          ..write('nameNormalized: $nameNormalized, ')
          ..write('phone: $phone, ')
          ..write('phoneNormalized: $phoneNormalized, ')
          ..write('notes: $notes, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('mergedIntoId: $mergedIntoId, ')
          ..write('needsReview: $needsReview, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDeviceId: $updatedByDeviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Transactions extends Table with TableInfo<Transactions, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Transactions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY CHECK (id = lower(id) AND length(id) = 36)',
  );
  static const VerificationMeta _firmIdMeta = const VerificationMeta('firmId');
  late final GeneratedColumn<String> firmId = GeneratedColumn<String>(
    'firm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES firms(id)',
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deviceShortCodeMeta = const VerificationMeta(
    'deviceShortCode',
  );
  late final GeneratedColumn<String> deviceShortCode = GeneratedColumn<String>(
    'device_short_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _displaySeqMeta = const VerificationMeta(
    'displaySeq',
  );
  late final GeneratedColumn<int> displaySeq = GeneratedColumn<int>(
    'display_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (display_seq > 0)',
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (type IN (\'sale\', \'purchase\', \'cash_in\', \'cash_out\', \'opening_balance\', \'adjustment\'))',
  );
  static const VerificationMeta _entryDateMeta = const VerificationMeta(
    'entryDate',
  );
  late final GeneratedColumn<String> entryDate = GeneratedColumn<String>(
    'entry_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (entry_date GLOB \'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\')',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (version >= 1)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _calculatedTotalMeta = const VerificationMeta(
    'calculatedTotal',
  );
  late final GeneratedColumn<int> calculatedTotal = GeneratedColumn<int>(
    'calculated_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _overriddenTotalMeta = const VerificationMeta(
    'overriddenTotal',
  );
  late final GeneratedColumn<int> overriddenTotal = GeneratedColumn<int>(
    'overridden_total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _overriddenTotalBasisMeta =
      const VerificationMeta('overriddenTotalBasis');
  late final GeneratedColumn<int> overriddenTotalBasis = GeneratedColumn<int>(
    'overridden_total_basis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _finalAmountMeta = const VerificationMeta(
    'finalAmount',
  );
  late final GeneratedColumn<int> finalAmount = GeneratedColumn<int>(
    'final_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _signedAmountMeta = const VerificationMeta(
    'signedAmount',
  );
  late final GeneratedColumn<int> signedAmount = GeneratedColumn<int>(
    'signed_amount',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression(
        'CASE type WHEN \'sale\' THEN final_amount WHEN \'cash_out\' THEN final_amount WHEN \'opening_balance\' THEN final_amount WHEN \'adjustment\' THEN final_amount WHEN \'purchase\' THEN -final_amount WHEN \'cash_in\' THEN -final_amount END',
      ),
      true,
    ),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'GENERATED ALWAYS AS (CASE type WHEN \'sale\' THEN final_amount WHEN \'cash_out\' THEN final_amount WHEN \'opening_balance\' THEN final_amount WHEN \'adjustment\' THEN final_amount WHEN \'purchase\' THEN -final_amount WHEN \'cash_in\' THEN -final_amount END) STORED',
  );
  static const VerificationMeta _createdByUserIdMeta = const VerificationMeta(
    'createdByUserId',
  );
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
    'created_by_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES users(id)',
  );
  static const VerificationMeta _updatedByUserIdMeta = const VerificationMeta(
    'updatedByUserId',
  );
  late final GeneratedColumn<String> updatedByUserId = GeneratedColumn<String>(
    'updated_by_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES users(id)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedByDeviceIdMeta = const VerificationMeta(
    'updatedByDeviceId',
  );
  late final GeneratedColumn<String> updatedByDeviceId =
      GeneratedColumn<String>(
        'updated_by_device_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firmId,
    customerId,
    deviceShortCode,
    displaySeq,
    type,
    entryDate,
    description,
    version,
    calculatedTotal,
    overriddenTotal,
    overriddenTotalBasis,
    finalAmount,
    signedAmount,
    createdByUserId,
    updatedByUserId,
    createdAt,
    updatedAt,
    updatedByDeviceId,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('firm_id')) {
      context.handle(
        _firmIdMeta,
        firmId.isAcceptableOrUnknown(data['firm_id']!, _firmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_firmIdMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('device_short_code')) {
      context.handle(
        _deviceShortCodeMeta,
        deviceShortCode.isAcceptableOrUnknown(
          data['device_short_code']!,
          _deviceShortCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceShortCodeMeta);
    }
    if (data.containsKey('display_seq')) {
      context.handle(
        _displaySeqMeta,
        displaySeq.isAcceptableOrUnknown(data['display_seq']!, _displaySeqMeta),
      );
    } else if (isInserting) {
      context.missing(_displaySeqMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('entry_date')) {
      context.handle(
        _entryDateMeta,
        entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta),
      );
    } else if (isInserting) {
      context.missing(_entryDateMeta);
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('calculated_total')) {
      context.handle(
        _calculatedTotalMeta,
        calculatedTotal.isAcceptableOrUnknown(
          data['calculated_total']!,
          _calculatedTotalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calculatedTotalMeta);
    }
    if (data.containsKey('overridden_total')) {
      context.handle(
        _overriddenTotalMeta,
        overriddenTotal.isAcceptableOrUnknown(
          data['overridden_total']!,
          _overriddenTotalMeta,
        ),
      );
    }
    if (data.containsKey('overridden_total_basis')) {
      context.handle(
        _overriddenTotalBasisMeta,
        overriddenTotalBasis.isAcceptableOrUnknown(
          data['overridden_total_basis']!,
          _overriddenTotalBasisMeta,
        ),
      );
    }
    if (data.containsKey('final_amount')) {
      context.handle(
        _finalAmountMeta,
        finalAmount.isAcceptableOrUnknown(
          data['final_amount']!,
          _finalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_finalAmountMeta);
    }
    if (data.containsKey('signed_amount')) {
      context.handle(
        _signedAmountMeta,
        signedAmount.isAcceptableOrUnknown(
          data['signed_amount']!,
          _signedAmountMeta,
        ),
      );
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
        _createdByUserIdMeta,
        createdByUserId.isAcceptableOrUnknown(
          data['created_by_user_id']!,
          _createdByUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    if (data.containsKey('updated_by_user_id')) {
      context.handle(
        _updatedByUserIdMeta,
        updatedByUserId.isAcceptableOrUnknown(
          data['updated_by_user_id']!,
          _updatedByUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByUserIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by_device_id')) {
      context.handle(
        _updatedByDeviceIdMeta,
        updatedByDeviceId.isAcceptableOrUnknown(
          data['updated_by_device_id']!,
          _updatedByDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedByDeviceIdMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {firmId, id},
  ];
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      firmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firm_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      deviceShortCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_short_code'],
      )!,
      displaySeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_seq'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      entryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_date'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      calculatedTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calculated_total'],
      )!,
      overriddenTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overridden_total'],
      ),
      overriddenTotalBasis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overridden_total_basis'],
      ),
      finalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}final_amount'],
      )!,
      signedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}signed_amount'],
      ),
      createdByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_user_id'],
      )!,
      updatedByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_user_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedByDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by_device_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  Transactions createAlias(String alias) {
    return Transactions(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(firm_id, id)',
    'FOREIGN KEY(firm_id, customer_id)REFERENCES customers(firm_id, id)',
    'CHECK((type = \'adjustment\' AND final_amount <> 0)OR(type <> \'adjustment\' AND final_amount > 0))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final String id;
  final String firmId;
  final String? customerId;

  /// NULL = walk-in cash sale, no ledger
  final String deviceShortCode;
  final int displaySeq;
  final String type;
  final String entryDate;
  final String? description;
  final int version;
  final int calculatedTotal;
  final int? overriddenTotal;
  final int? overriddenTotalBasis;
  final int finalAmount;

  /// The ONE place the sign of a transaction lives. No ELSE: an unknown type is
  /// already rejected by the CHECK above, and a new type must be added here on purpose.
  final int? signedAmount;
  final String createdByUserId;
  final String updatedByUserId;
  final int createdAt;
  final int updatedAt;
  final String updatedByDeviceId;
  final int? deletedAt;
  const TransactionRow({
    required this.id,
    required this.firmId,
    this.customerId,
    required this.deviceShortCode,
    required this.displaySeq,
    required this.type,
    required this.entryDate,
    this.description,
    required this.version,
    required this.calculatedTotal,
    this.overriddenTotal,
    this.overriddenTotalBasis,
    required this.finalAmount,
    this.signedAmount,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedByDeviceId,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['firm_id'] = Variable<String>(firmId);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['device_short_code'] = Variable<String>(deviceShortCode);
    map['display_seq'] = Variable<int>(displaySeq);
    map['type'] = Variable<String>(type);
    map['entry_date'] = Variable<String>(entryDate);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['version'] = Variable<int>(version);
    map['calculated_total'] = Variable<int>(calculatedTotal);
    if (!nullToAbsent || overriddenTotal != null) {
      map['overridden_total'] = Variable<int>(overriddenTotal);
    }
    if (!nullToAbsent || overriddenTotalBasis != null) {
      map['overridden_total_basis'] = Variable<int>(overriddenTotalBasis);
    }
    map['final_amount'] = Variable<int>(finalAmount);
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    map['updated_by_user_id'] = Variable<String>(updatedByUserId);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['updated_by_device_id'] = Variable<String>(updatedByDeviceId);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      firmId: Value(firmId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      deviceShortCode: Value(deviceShortCode),
      displaySeq: Value(displaySeq),
      type: Value(type),
      entryDate: Value(entryDate),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      version: Value(version),
      calculatedTotal: Value(calculatedTotal),
      overriddenTotal: overriddenTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(overriddenTotal),
      overriddenTotalBasis: overriddenTotalBasis == null && nullToAbsent
          ? const Value.absent()
          : Value(overriddenTotalBasis),
      finalAmount: Value(finalAmount),
      createdByUserId: Value(createdByUserId),
      updatedByUserId: Value(updatedByUserId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      updatedByDeviceId: Value(updatedByDeviceId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<String>(json['id']),
      firmId: serializer.fromJson<String>(json['firm_id']),
      customerId: serializer.fromJson<String?>(json['customer_id']),
      deviceShortCode: serializer.fromJson<String>(json['device_short_code']),
      displaySeq: serializer.fromJson<int>(json['display_seq']),
      type: serializer.fromJson<String>(json['type']),
      entryDate: serializer.fromJson<String>(json['entry_date']),
      description: serializer.fromJson<String?>(json['description']),
      version: serializer.fromJson<int>(json['version']),
      calculatedTotal: serializer.fromJson<int>(json['calculated_total']),
      overriddenTotal: serializer.fromJson<int?>(json['overridden_total']),
      overriddenTotalBasis: serializer.fromJson<int?>(
        json['overridden_total_basis'],
      ),
      finalAmount: serializer.fromJson<int>(json['final_amount']),
      signedAmount: serializer.fromJson<int?>(json['signed_amount']),
      createdByUserId: serializer.fromJson<String>(json['created_by_user_id']),
      updatedByUserId: serializer.fromJson<String>(json['updated_by_user_id']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      updatedByDeviceId: serializer.fromJson<String>(
        json['updated_by_device_id'],
      ),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'firm_id': serializer.toJson<String>(firmId),
      'customer_id': serializer.toJson<String?>(customerId),
      'device_short_code': serializer.toJson<String>(deviceShortCode),
      'display_seq': serializer.toJson<int>(displaySeq),
      'type': serializer.toJson<String>(type),
      'entry_date': serializer.toJson<String>(entryDate),
      'description': serializer.toJson<String?>(description),
      'version': serializer.toJson<int>(version),
      'calculated_total': serializer.toJson<int>(calculatedTotal),
      'overridden_total': serializer.toJson<int?>(overriddenTotal),
      'overridden_total_basis': serializer.toJson<int?>(overriddenTotalBasis),
      'final_amount': serializer.toJson<int>(finalAmount),
      'signed_amount': serializer.toJson<int?>(signedAmount),
      'created_by_user_id': serializer.toJson<String>(createdByUserId),
      'updated_by_user_id': serializer.toJson<String>(updatedByUserId),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
      'updated_by_device_id': serializer.toJson<String>(updatedByDeviceId),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  TransactionRow copyWith({
    String? id,
    String? firmId,
    Value<String?> customerId = const Value.absent(),
    String? deviceShortCode,
    int? displaySeq,
    String? type,
    String? entryDate,
    Value<String?> description = const Value.absent(),
    int? version,
    int? calculatedTotal,
    Value<int?> overriddenTotal = const Value.absent(),
    Value<int?> overriddenTotalBasis = const Value.absent(),
    int? finalAmount,
    Value<int?> signedAmount = const Value.absent(),
    String? createdByUserId,
    String? updatedByUserId,
    int? createdAt,
    int? updatedAt,
    String? updatedByDeviceId,
    Value<int?> deletedAt = const Value.absent(),
  }) => TransactionRow(
    id: id ?? this.id,
    firmId: firmId ?? this.firmId,
    customerId: customerId.present ? customerId.value : this.customerId,
    deviceShortCode: deviceShortCode ?? this.deviceShortCode,
    displaySeq: displaySeq ?? this.displaySeq,
    type: type ?? this.type,
    entryDate: entryDate ?? this.entryDate,
    description: description.present ? description.value : this.description,
    version: version ?? this.version,
    calculatedTotal: calculatedTotal ?? this.calculatedTotal,
    overriddenTotal: overriddenTotal.present
        ? overriddenTotal.value
        : this.overriddenTotal,
    overriddenTotalBasis: overriddenTotalBasis.present
        ? overriddenTotalBasis.value
        : this.overriddenTotalBasis,
    finalAmount: finalAmount ?? this.finalAmount,
    signedAmount: signedAmount.present ? signedAmount.value : this.signedAmount,
    createdByUserId: createdByUserId ?? this.createdByUserId,
    updatedByUserId: updatedByUserId ?? this.updatedByUserId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('customerId: $customerId, ')
          ..write('deviceShortCode: $deviceShortCode, ')
          ..write('displaySeq: $displaySeq, ')
          ..write('type: $type, ')
          ..write('entryDate: $entryDate, ')
          ..write('description: $description, ')
          ..write('version: $version, ')
          ..write('calculatedTotal: $calculatedTotal, ')
          ..write('overriddenTotal: $overriddenTotal, ')
          ..write('overriddenTotalBasis: $overriddenTotalBasis, ')
          ..write('finalAmount: $finalAmount, ')
          ..write('signedAmount: $signedAmount, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('updatedByUserId: $updatedByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDeviceId: $updatedByDeviceId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firmId,
    customerId,
    deviceShortCode,
    displaySeq,
    type,
    entryDate,
    description,
    version,
    calculatedTotal,
    overriddenTotal,
    overriddenTotalBasis,
    finalAmount,
    signedAmount,
    createdByUserId,
    updatedByUserId,
    createdAt,
    updatedAt,
    updatedByDeviceId,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.firmId == this.firmId &&
          other.customerId == this.customerId &&
          other.deviceShortCode == this.deviceShortCode &&
          other.displaySeq == this.displaySeq &&
          other.type == this.type &&
          other.entryDate == this.entryDate &&
          other.description == this.description &&
          other.version == this.version &&
          other.calculatedTotal == this.calculatedTotal &&
          other.overriddenTotal == this.overriddenTotal &&
          other.overriddenTotalBasis == this.overriddenTotalBasis &&
          other.finalAmount == this.finalAmount &&
          other.signedAmount == this.signedAmount &&
          other.createdByUserId == this.createdByUserId &&
          other.updatedByUserId == this.updatedByUserId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedByDeviceId == this.updatedByDeviceId &&
          other.deletedAt == this.deletedAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<String> id;
  final Value<String> firmId;
  final Value<String?> customerId;
  final Value<String> deviceShortCode;
  final Value<int> displaySeq;
  final Value<String> type;
  final Value<String> entryDate;
  final Value<String?> description;
  final Value<int> version;
  final Value<int> calculatedTotal;
  final Value<int?> overriddenTotal;
  final Value<int?> overriddenTotalBasis;
  final Value<int> finalAmount;
  final Value<String> createdByUserId;
  final Value<String> updatedByUserId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> updatedByDeviceId;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.firmId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.deviceShortCode = const Value.absent(),
    this.displaySeq = const Value.absent(),
    this.type = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.description = const Value.absent(),
    this.version = const Value.absent(),
    this.calculatedTotal = const Value.absent(),
    this.overriddenTotal = const Value.absent(),
    this.overriddenTotalBasis = const Value.absent(),
    this.finalAmount = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.updatedByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedByDeviceId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String firmId,
    this.customerId = const Value.absent(),
    required String deviceShortCode,
    required int displaySeq,
    required String type,
    required String entryDate,
    this.description = const Value.absent(),
    this.version = const Value.absent(),
    required int calculatedTotal,
    this.overriddenTotal = const Value.absent(),
    this.overriddenTotalBasis = const Value.absent(),
    required int finalAmount,
    required String createdByUserId,
    required String updatedByUserId,
    required int createdAt,
    required int updatedAt,
    required String updatedByDeviceId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       firmId = Value(firmId),
       deviceShortCode = Value(deviceShortCode),
       displaySeq = Value(displaySeq),
       type = Value(type),
       entryDate = Value(entryDate),
       calculatedTotal = Value(calculatedTotal),
       finalAmount = Value(finalAmount),
       createdByUserId = Value(createdByUserId),
       updatedByUserId = Value(updatedByUserId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       updatedByDeviceId = Value(updatedByDeviceId);
  static Insertable<TransactionRow> custom({
    Expression<String>? id,
    Expression<String>? firmId,
    Expression<String>? customerId,
    Expression<String>? deviceShortCode,
    Expression<int>? displaySeq,
    Expression<String>? type,
    Expression<String>? entryDate,
    Expression<String>? description,
    Expression<int>? version,
    Expression<int>? calculatedTotal,
    Expression<int>? overriddenTotal,
    Expression<int>? overriddenTotalBasis,
    Expression<int>? finalAmount,
    Expression<String>? createdByUserId,
    Expression<String>? updatedByUserId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? updatedByDeviceId,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firmId != null) 'firm_id': firmId,
      if (customerId != null) 'customer_id': customerId,
      if (deviceShortCode != null) 'device_short_code': deviceShortCode,
      if (displaySeq != null) 'display_seq': displaySeq,
      if (type != null) 'type': type,
      if (entryDate != null) 'entry_date': entryDate,
      if (description != null) 'description': description,
      if (version != null) 'version': version,
      if (calculatedTotal != null) 'calculated_total': calculatedTotal,
      if (overriddenTotal != null) 'overridden_total': overriddenTotal,
      if (overriddenTotalBasis != null)
        'overridden_total_basis': overriddenTotalBasis,
      if (finalAmount != null) 'final_amount': finalAmount,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (updatedByUserId != null) 'updated_by_user_id': updatedByUserId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedByDeviceId != null) 'updated_by_device_id': updatedByDeviceId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? firmId,
    Value<String?>? customerId,
    Value<String>? deviceShortCode,
    Value<int>? displaySeq,
    Value<String>? type,
    Value<String>? entryDate,
    Value<String?>? description,
    Value<int>? version,
    Value<int>? calculatedTotal,
    Value<int?>? overriddenTotal,
    Value<int?>? overriddenTotalBasis,
    Value<int>? finalAmount,
    Value<String>? createdByUserId,
    Value<String>? updatedByUserId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? updatedByDeviceId,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      customerId: customerId ?? this.customerId,
      deviceShortCode: deviceShortCode ?? this.deviceShortCode,
      displaySeq: displaySeq ?? this.displaySeq,
      type: type ?? this.type,
      entryDate: entryDate ?? this.entryDate,
      description: description ?? this.description,
      version: version ?? this.version,
      calculatedTotal: calculatedTotal ?? this.calculatedTotal,
      overriddenTotal: overriddenTotal ?? this.overriddenTotal,
      overriddenTotalBasis: overriddenTotalBasis ?? this.overriddenTotalBasis,
      finalAmount: finalAmount ?? this.finalAmount,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      updatedByUserId: updatedByUserId ?? this.updatedByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
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
    if (firmId.present) {
      map['firm_id'] = Variable<String>(firmId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (deviceShortCode.present) {
      map['device_short_code'] = Variable<String>(deviceShortCode.value);
    }
    if (displaySeq.present) {
      map['display_seq'] = Variable<int>(displaySeq.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<String>(entryDate.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (calculatedTotal.present) {
      map['calculated_total'] = Variable<int>(calculatedTotal.value);
    }
    if (overriddenTotal.present) {
      map['overridden_total'] = Variable<int>(overriddenTotal.value);
    }
    if (overriddenTotalBasis.present) {
      map['overridden_total_basis'] = Variable<int>(overriddenTotalBasis.value);
    }
    if (finalAmount.present) {
      map['final_amount'] = Variable<int>(finalAmount.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (updatedByUserId.present) {
      map['updated_by_user_id'] = Variable<String>(updatedByUserId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updatedByDeviceId.present) {
      map['updated_by_device_id'] = Variable<String>(updatedByDeviceId.value);
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
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('customerId: $customerId, ')
          ..write('deviceShortCode: $deviceShortCode, ')
          ..write('displaySeq: $displaySeq, ')
          ..write('type: $type, ')
          ..write('entryDate: $entryDate, ')
          ..write('description: $description, ')
          ..write('version: $version, ')
          ..write('calculatedTotal: $calculatedTotal, ')
          ..write('overriddenTotal: $overriddenTotal, ')
          ..write('overriddenTotalBasis: $overriddenTotalBasis, ')
          ..write('finalAmount: $finalAmount, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('updatedByUserId: $updatedByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedByDeviceId: $updatedByDeviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TransactionLines extends Table
    with TableInfo<TransactionLines, TransactionLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TransactionLines(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY CHECK (id = lower(id) AND length(id) = 36)',
  );
  static const VerificationMeta _firmIdMeta = const VerificationMeta('firmId');
  late final GeneratedColumn<String> firmId = GeneratedColumn<String>(
    'firm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _lineNoMeta = const VerificationMeta('lineNo');
  late final GeneratedColumn<int> lineNo = GeneratedColumn<int>(
    'line_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (line_no >= 0)',
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _uomMeta = const VerificationMeta('uom');
  late final GeneratedColumn<String> uom = GeneratedColumn<String>(
    'uom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'kg\' CHECK (uom IN (\'kg\', \'unit\'))',
    defaultValue: const CustomExpression('\'kg\''),
  );
  static const VerificationMeta _saleModeMeta = const VerificationMeta(
    'saleMode',
  );
  late final GeneratedColumn<String> saleMode = GeneratedColumn<String>(
    'sale_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (sale_mode IN (\'by_bags\', \'by_weight\', \'by_count\'))',
  );
  static const VerificationMeta _bagCountMeta = const VerificationMeta(
    'bagCount',
  );
  late final GeneratedColumn<int> bagCount = GeneratedColumn<int>(
    'bag_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (bag_count IS NULL OR bag_count > 0)',
  );
  static const VerificationMeta _bagWeightGMeta = const VerificationMeta(
    'bagWeightG',
  );
  late final GeneratedColumn<int> bagWeightG = GeneratedColumn<int>(
    'bag_weight_g',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (bag_weight_g IS NULL OR bag_weight_g > 0)',
  );
  static const VerificationMeta _totalWeightGMeta = const VerificationMeta(
    'totalWeightG',
  );
  late final GeneratedColumn<int> totalWeightG = GeneratedColumn<int>(
    'total_weight_g',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (total_weight_g IS NULL OR total_weight_g > 0)',
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (quantity IS NULL OR quantity > 0)',
  );
  static const VerificationMeta _ratePaisaMeta = const VerificationMeta(
    'ratePaisa',
  );
  late final GeneratedColumn<int> ratePaisa = GeneratedColumn<int>(
    'rate_paisa',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (rate_paisa > 0)',
  );
  static const VerificationMeta _rateBaseWeightGMeta = const VerificationMeta(
    'rateBaseWeightG',
  );
  late final GeneratedColumn<int> rateBaseWeightG = GeneratedColumn<int>(
    'rate_base_weight_g',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (rate_base_weight_g IS NULL OR rate_base_weight_g > 0)',
  );
  static const VerificationMeta _overriddenTotalMeta = const VerificationMeta(
    'overriddenTotal',
  );
  late final GeneratedColumn<int> overriddenTotal = GeneratedColumn<int>(
    'overridden_total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _calculatedTotalMeta = const VerificationMeta(
    'calculatedTotal',
  );
  late final GeneratedColumn<int> calculatedTotal = GeneratedColumn<int>(
    'calculated_total',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression(
        'CASE uom WHEN \'kg\' THEN(rate_paisa * total_weight_g + rate_base_weight_g / 2)/ rate_base_weight_g WHEN \'unit\' THEN rate_paisa * quantity END',
      ),
      true,
    ),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'GENERATED ALWAYS AS (CASE uom WHEN \'kg\' THEN(rate_paisa * total_weight_g + rate_base_weight_g / 2)/ rate_base_weight_g WHEN \'unit\' THEN rate_paisa * quantity END) STORED',
  );
  static const VerificationMeta _finalAmountMeta = const VerificationMeta(
    'finalAmount',
  );
  late final GeneratedColumn<int> finalAmount = GeneratedColumn<int>(
    'final_amount',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression('COALESCE(overridden_total, calculated_total)'),
      true,
    ),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'GENERATED ALWAYS AS (COALESCE(overridden_total, calculated_total)) STORED',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firmId,
    transactionId,
    lineNo,
    itemId,
    uom,
    saleMode,
    bagCount,
    bagWeightG,
    totalWeightG,
    quantity,
    ratePaisa,
    rateBaseWeightG,
    overriddenTotal,
    calculatedTotal,
    finalAmount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('firm_id')) {
      context.handle(
        _firmIdMeta,
        firmId.isAcceptableOrUnknown(data['firm_id']!, _firmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_firmIdMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('line_no')) {
      context.handle(
        _lineNoMeta,
        lineNo.isAcceptableOrUnknown(data['line_no']!, _lineNoMeta),
      );
    } else if (isInserting) {
      context.missing(_lineNoMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('uom')) {
      context.handle(
        _uomMeta,
        uom.isAcceptableOrUnknown(data['uom']!, _uomMeta),
      );
    }
    if (data.containsKey('sale_mode')) {
      context.handle(
        _saleModeMeta,
        saleMode.isAcceptableOrUnknown(data['sale_mode']!, _saleModeMeta),
      );
    } else if (isInserting) {
      context.missing(_saleModeMeta);
    }
    if (data.containsKey('bag_count')) {
      context.handle(
        _bagCountMeta,
        bagCount.isAcceptableOrUnknown(data['bag_count']!, _bagCountMeta),
      );
    }
    if (data.containsKey('bag_weight_g')) {
      context.handle(
        _bagWeightGMeta,
        bagWeightG.isAcceptableOrUnknown(
          data['bag_weight_g']!,
          _bagWeightGMeta,
        ),
      );
    }
    if (data.containsKey('total_weight_g')) {
      context.handle(
        _totalWeightGMeta,
        totalWeightG.isAcceptableOrUnknown(
          data['total_weight_g']!,
          _totalWeightGMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('rate_paisa')) {
      context.handle(
        _ratePaisaMeta,
        ratePaisa.isAcceptableOrUnknown(data['rate_paisa']!, _ratePaisaMeta),
      );
    } else if (isInserting) {
      context.missing(_ratePaisaMeta);
    }
    if (data.containsKey('rate_base_weight_g')) {
      context.handle(
        _rateBaseWeightGMeta,
        rateBaseWeightG.isAcceptableOrUnknown(
          data['rate_base_weight_g']!,
          _rateBaseWeightGMeta,
        ),
      );
    }
    if (data.containsKey('overridden_total')) {
      context.handle(
        _overriddenTotalMeta,
        overriddenTotal.isAcceptableOrUnknown(
          data['overridden_total']!,
          _overriddenTotalMeta,
        ),
      );
    }
    if (data.containsKey('calculated_total')) {
      context.handle(
        _calculatedTotalMeta,
        calculatedTotal.isAcceptableOrUnknown(
          data['calculated_total']!,
          _calculatedTotalMeta,
        ),
      );
    }
    if (data.containsKey('final_amount')) {
      context.handle(
        _finalAmountMeta,
        finalAmount.isAcceptableOrUnknown(
          data['final_amount']!,
          _finalAmountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      firmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firm_id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      lineNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_no'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      uom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uom'],
      )!,
      saleMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_mode'],
      )!,
      bagCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bag_count'],
      ),
      bagWeightG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bag_weight_g'],
      ),
      totalWeightG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_weight_g'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      ),
      ratePaisa: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_paisa'],
      )!,
      rateBaseWeightG: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_base_weight_g'],
      ),
      overriddenTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overridden_total'],
      ),
      calculatedTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calculated_total'],
      ),
      finalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}final_amount'],
      ),
    );
  }

  @override
  TransactionLines createAlias(String alias) {
    return TransactionLines(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY(firm_id, transaction_id)REFERENCES transactions(firm_id, id)ON DELETE CASCADE',
    'FOREIGN KEY(firm_id, item_id)REFERENCES items(firm_id, id)',
    'CHECK((sale_mode = \'by_bags\')=(bag_count IS NOT NULL AND bag_weight_g IS NOT NULL))',
    'CHECK((uom = \'kg\')=(total_weight_g IS NOT NULL AND rate_base_weight_g IS NOT NULL))',
    'CHECK((uom = \'unit\')=(quantity IS NOT NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class TransactionLineRow extends DataClass
    implements Insertable<TransactionLineRow> {
  final String id;
  final String firmId;
  final String transactionId;
  final int lineNo;
  final String itemId;
  final String uom;
  final String saleMode;
  final int? bagCount;
  final int? bagWeightG;
  final int? totalWeightG;
  final int? quantity;
  final int ratePaisa;
  final int? rateBaseWeightG;
  final int? overriddenTotal;

  /// Integer half-up: (a*b + c/2) / c. Identical in SQLite, Postgres and Dart.
  final int? calculatedTotal;
  final int? finalAmount;
  const TransactionLineRow({
    required this.id,
    required this.firmId,
    required this.transactionId,
    required this.lineNo,
    required this.itemId,
    required this.uom,
    required this.saleMode,
    this.bagCount,
    this.bagWeightG,
    this.totalWeightG,
    this.quantity,
    required this.ratePaisa,
    this.rateBaseWeightG,
    this.overriddenTotal,
    this.calculatedTotal,
    this.finalAmount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['firm_id'] = Variable<String>(firmId);
    map['transaction_id'] = Variable<String>(transactionId);
    map['line_no'] = Variable<int>(lineNo);
    map['item_id'] = Variable<String>(itemId);
    map['uom'] = Variable<String>(uom);
    map['sale_mode'] = Variable<String>(saleMode);
    if (!nullToAbsent || bagCount != null) {
      map['bag_count'] = Variable<int>(bagCount);
    }
    if (!nullToAbsent || bagWeightG != null) {
      map['bag_weight_g'] = Variable<int>(bagWeightG);
    }
    if (!nullToAbsent || totalWeightG != null) {
      map['total_weight_g'] = Variable<int>(totalWeightG);
    }
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<int>(quantity);
    }
    map['rate_paisa'] = Variable<int>(ratePaisa);
    if (!nullToAbsent || rateBaseWeightG != null) {
      map['rate_base_weight_g'] = Variable<int>(rateBaseWeightG);
    }
    if (!nullToAbsent || overriddenTotal != null) {
      map['overridden_total'] = Variable<int>(overriddenTotal);
    }
    return map;
  }

  TransactionLinesCompanion toCompanion(bool nullToAbsent) {
    return TransactionLinesCompanion(
      id: Value(id),
      firmId: Value(firmId),
      transactionId: Value(transactionId),
      lineNo: Value(lineNo),
      itemId: Value(itemId),
      uom: Value(uom),
      saleMode: Value(saleMode),
      bagCount: bagCount == null && nullToAbsent
          ? const Value.absent()
          : Value(bagCount),
      bagWeightG: bagWeightG == null && nullToAbsent
          ? const Value.absent()
          : Value(bagWeightG),
      totalWeightG: totalWeightG == null && nullToAbsent
          ? const Value.absent()
          : Value(totalWeightG),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      ratePaisa: Value(ratePaisa),
      rateBaseWeightG: rateBaseWeightG == null && nullToAbsent
          ? const Value.absent()
          : Value(rateBaseWeightG),
      overriddenTotal: overriddenTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(overriddenTotal),
    );
  }

  factory TransactionLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionLineRow(
      id: serializer.fromJson<String>(json['id']),
      firmId: serializer.fromJson<String>(json['firm_id']),
      transactionId: serializer.fromJson<String>(json['transaction_id']),
      lineNo: serializer.fromJson<int>(json['line_no']),
      itemId: serializer.fromJson<String>(json['item_id']),
      uom: serializer.fromJson<String>(json['uom']),
      saleMode: serializer.fromJson<String>(json['sale_mode']),
      bagCount: serializer.fromJson<int?>(json['bag_count']),
      bagWeightG: serializer.fromJson<int?>(json['bag_weight_g']),
      totalWeightG: serializer.fromJson<int?>(json['total_weight_g']),
      quantity: serializer.fromJson<int?>(json['quantity']),
      ratePaisa: serializer.fromJson<int>(json['rate_paisa']),
      rateBaseWeightG: serializer.fromJson<int?>(json['rate_base_weight_g']),
      overriddenTotal: serializer.fromJson<int?>(json['overridden_total']),
      calculatedTotal: serializer.fromJson<int?>(json['calculated_total']),
      finalAmount: serializer.fromJson<int?>(json['final_amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'firm_id': serializer.toJson<String>(firmId),
      'transaction_id': serializer.toJson<String>(transactionId),
      'line_no': serializer.toJson<int>(lineNo),
      'item_id': serializer.toJson<String>(itemId),
      'uom': serializer.toJson<String>(uom),
      'sale_mode': serializer.toJson<String>(saleMode),
      'bag_count': serializer.toJson<int?>(bagCount),
      'bag_weight_g': serializer.toJson<int?>(bagWeightG),
      'total_weight_g': serializer.toJson<int?>(totalWeightG),
      'quantity': serializer.toJson<int?>(quantity),
      'rate_paisa': serializer.toJson<int>(ratePaisa),
      'rate_base_weight_g': serializer.toJson<int?>(rateBaseWeightG),
      'overridden_total': serializer.toJson<int?>(overriddenTotal),
      'calculated_total': serializer.toJson<int?>(calculatedTotal),
      'final_amount': serializer.toJson<int?>(finalAmount),
    };
  }

  TransactionLineRow copyWith({
    String? id,
    String? firmId,
    String? transactionId,
    int? lineNo,
    String? itemId,
    String? uom,
    String? saleMode,
    Value<int?> bagCount = const Value.absent(),
    Value<int?> bagWeightG = const Value.absent(),
    Value<int?> totalWeightG = const Value.absent(),
    Value<int?> quantity = const Value.absent(),
    int? ratePaisa,
    Value<int?> rateBaseWeightG = const Value.absent(),
    Value<int?> overriddenTotal = const Value.absent(),
    Value<int?> calculatedTotal = const Value.absent(),
    Value<int?> finalAmount = const Value.absent(),
  }) => TransactionLineRow(
    id: id ?? this.id,
    firmId: firmId ?? this.firmId,
    transactionId: transactionId ?? this.transactionId,
    lineNo: lineNo ?? this.lineNo,
    itemId: itemId ?? this.itemId,
    uom: uom ?? this.uom,
    saleMode: saleMode ?? this.saleMode,
    bagCount: bagCount.present ? bagCount.value : this.bagCount,
    bagWeightG: bagWeightG.present ? bagWeightG.value : this.bagWeightG,
    totalWeightG: totalWeightG.present ? totalWeightG.value : this.totalWeightG,
    quantity: quantity.present ? quantity.value : this.quantity,
    ratePaisa: ratePaisa ?? this.ratePaisa,
    rateBaseWeightG: rateBaseWeightG.present
        ? rateBaseWeightG.value
        : this.rateBaseWeightG,
    overriddenTotal: overriddenTotal.present
        ? overriddenTotal.value
        : this.overriddenTotal,
    calculatedTotal: calculatedTotal.present
        ? calculatedTotal.value
        : this.calculatedTotal,
    finalAmount: finalAmount.present ? finalAmount.value : this.finalAmount,
  );
  @override
  String toString() {
    return (StringBuffer('TransactionLineRow(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('transactionId: $transactionId, ')
          ..write('lineNo: $lineNo, ')
          ..write('itemId: $itemId, ')
          ..write('uom: $uom, ')
          ..write('saleMode: $saleMode, ')
          ..write('bagCount: $bagCount, ')
          ..write('bagWeightG: $bagWeightG, ')
          ..write('totalWeightG: $totalWeightG, ')
          ..write('quantity: $quantity, ')
          ..write('ratePaisa: $ratePaisa, ')
          ..write('rateBaseWeightG: $rateBaseWeightG, ')
          ..write('overriddenTotal: $overriddenTotal, ')
          ..write('calculatedTotal: $calculatedTotal, ')
          ..write('finalAmount: $finalAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firmId,
    transactionId,
    lineNo,
    itemId,
    uom,
    saleMode,
    bagCount,
    bagWeightG,
    totalWeightG,
    quantity,
    ratePaisa,
    rateBaseWeightG,
    overriddenTotal,
    calculatedTotal,
    finalAmount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionLineRow &&
          other.id == this.id &&
          other.firmId == this.firmId &&
          other.transactionId == this.transactionId &&
          other.lineNo == this.lineNo &&
          other.itemId == this.itemId &&
          other.uom == this.uom &&
          other.saleMode == this.saleMode &&
          other.bagCount == this.bagCount &&
          other.bagWeightG == this.bagWeightG &&
          other.totalWeightG == this.totalWeightG &&
          other.quantity == this.quantity &&
          other.ratePaisa == this.ratePaisa &&
          other.rateBaseWeightG == this.rateBaseWeightG &&
          other.overriddenTotal == this.overriddenTotal &&
          other.calculatedTotal == this.calculatedTotal &&
          other.finalAmount == this.finalAmount);
}

class TransactionLinesCompanion extends UpdateCompanion<TransactionLineRow> {
  final Value<String> id;
  final Value<String> firmId;
  final Value<String> transactionId;
  final Value<int> lineNo;
  final Value<String> itemId;
  final Value<String> uom;
  final Value<String> saleMode;
  final Value<int?> bagCount;
  final Value<int?> bagWeightG;
  final Value<int?> totalWeightG;
  final Value<int?> quantity;
  final Value<int> ratePaisa;
  final Value<int?> rateBaseWeightG;
  final Value<int?> overriddenTotal;
  final Value<int> rowid;
  const TransactionLinesCompanion({
    this.id = const Value.absent(),
    this.firmId = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.lineNo = const Value.absent(),
    this.itemId = const Value.absent(),
    this.uom = const Value.absent(),
    this.saleMode = const Value.absent(),
    this.bagCount = const Value.absent(),
    this.bagWeightG = const Value.absent(),
    this.totalWeightG = const Value.absent(),
    this.quantity = const Value.absent(),
    this.ratePaisa = const Value.absent(),
    this.rateBaseWeightG = const Value.absent(),
    this.overriddenTotal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionLinesCompanion.insert({
    required String id,
    required String firmId,
    required String transactionId,
    required int lineNo,
    required String itemId,
    this.uom = const Value.absent(),
    required String saleMode,
    this.bagCount = const Value.absent(),
    this.bagWeightG = const Value.absent(),
    this.totalWeightG = const Value.absent(),
    this.quantity = const Value.absent(),
    required int ratePaisa,
    this.rateBaseWeightG = const Value.absent(),
    this.overriddenTotal = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       firmId = Value(firmId),
       transactionId = Value(transactionId),
       lineNo = Value(lineNo),
       itemId = Value(itemId),
       saleMode = Value(saleMode),
       ratePaisa = Value(ratePaisa);
  static Insertable<TransactionLineRow> custom({
    Expression<String>? id,
    Expression<String>? firmId,
    Expression<String>? transactionId,
    Expression<int>? lineNo,
    Expression<String>? itemId,
    Expression<String>? uom,
    Expression<String>? saleMode,
    Expression<int>? bagCount,
    Expression<int>? bagWeightG,
    Expression<int>? totalWeightG,
    Expression<int>? quantity,
    Expression<int>? ratePaisa,
    Expression<int>? rateBaseWeightG,
    Expression<int>? overriddenTotal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firmId != null) 'firm_id': firmId,
      if (transactionId != null) 'transaction_id': transactionId,
      if (lineNo != null) 'line_no': lineNo,
      if (itemId != null) 'item_id': itemId,
      if (uom != null) 'uom': uom,
      if (saleMode != null) 'sale_mode': saleMode,
      if (bagCount != null) 'bag_count': bagCount,
      if (bagWeightG != null) 'bag_weight_g': bagWeightG,
      if (totalWeightG != null) 'total_weight_g': totalWeightG,
      if (quantity != null) 'quantity': quantity,
      if (ratePaisa != null) 'rate_paisa': ratePaisa,
      if (rateBaseWeightG != null) 'rate_base_weight_g': rateBaseWeightG,
      if (overriddenTotal != null) 'overridden_total': overriddenTotal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? firmId,
    Value<String>? transactionId,
    Value<int>? lineNo,
    Value<String>? itemId,
    Value<String>? uom,
    Value<String>? saleMode,
    Value<int?>? bagCount,
    Value<int?>? bagWeightG,
    Value<int?>? totalWeightG,
    Value<int?>? quantity,
    Value<int>? ratePaisa,
    Value<int?>? rateBaseWeightG,
    Value<int?>? overriddenTotal,
    Value<int>? rowid,
  }) {
    return TransactionLinesCompanion(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      transactionId: transactionId ?? this.transactionId,
      lineNo: lineNo ?? this.lineNo,
      itemId: itemId ?? this.itemId,
      uom: uom ?? this.uom,
      saleMode: saleMode ?? this.saleMode,
      bagCount: bagCount ?? this.bagCount,
      bagWeightG: bagWeightG ?? this.bagWeightG,
      totalWeightG: totalWeightG ?? this.totalWeightG,
      quantity: quantity ?? this.quantity,
      ratePaisa: ratePaisa ?? this.ratePaisa,
      rateBaseWeightG: rateBaseWeightG ?? this.rateBaseWeightG,
      overriddenTotal: overriddenTotal ?? this.overriddenTotal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (firmId.present) {
      map['firm_id'] = Variable<String>(firmId.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (lineNo.present) {
      map['line_no'] = Variable<int>(lineNo.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (uom.present) {
      map['uom'] = Variable<String>(uom.value);
    }
    if (saleMode.present) {
      map['sale_mode'] = Variable<String>(saleMode.value);
    }
    if (bagCount.present) {
      map['bag_count'] = Variable<int>(bagCount.value);
    }
    if (bagWeightG.present) {
      map['bag_weight_g'] = Variable<int>(bagWeightG.value);
    }
    if (totalWeightG.present) {
      map['total_weight_g'] = Variable<int>(totalWeightG.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (ratePaisa.present) {
      map['rate_paisa'] = Variable<int>(ratePaisa.value);
    }
    if (rateBaseWeightG.present) {
      map['rate_base_weight_g'] = Variable<int>(rateBaseWeightG.value);
    }
    if (overriddenTotal.present) {
      map['overridden_total'] = Variable<int>(overriddenTotal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionLinesCompanion(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('transactionId: $transactionId, ')
          ..write('lineNo: $lineNo, ')
          ..write('itemId: $itemId, ')
          ..write('uom: $uom, ')
          ..write('saleMode: $saleMode, ')
          ..write('bagCount: $bagCount, ')
          ..write('bagWeightG: $bagWeightG, ')
          ..write('totalWeightG: $totalWeightG, ')
          ..write('quantity: $quantity, ')
          ..write('ratePaisa: $ratePaisa, ')
          ..write('rateBaseWeightG: $rateBaseWeightG, ')
          ..write('overriddenTotal: $overriddenTotal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TransactionHistory extends Table
    with TableInfo<TransactionHistory, TransactionHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TransactionHistory(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY CHECK (id = lower(id) AND length(id) = 36)',
  );
  static const VerificationMeta _firmIdMeta = const VerificationMeta('firmId');
  late final GeneratedColumn<String> firmId = GeneratedColumn<String>(
    'firm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _snapshotMeta = const VerificationMeta(
    'snapshot',
  );
  late final GeneratedColumn<String> snapshot = GeneratedColumn<String>(
    'snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (reason IN (\'edit\', \'delete\', \'sync_overwrite\', \'restore\'))',
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  late final GeneratedColumn<int> changedAt = GeneratedColumn<int>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _changedByUserIdMeta = const VerificationMeta(
    'changedByUserId',
  );
  late final GeneratedColumn<String> changedByUserId = GeneratedColumn<String>(
    'changed_by_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _changedByDeviceIdMeta = const VerificationMeta(
    'changedByDeviceId',
  );
  late final GeneratedColumn<String> changedByDeviceId =
      GeneratedColumn<String>(
        'changed_by_device_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firmId,
    transactionId,
    version,
    snapshot,
    reason,
    changedAt,
    changedByUserId,
    changedByDeviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('firm_id')) {
      context.handle(
        _firmIdMeta,
        firmId.isAcceptableOrUnknown(data['firm_id']!, _firmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_firmIdMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('snapshot')) {
      context.handle(
        _snapshotMeta,
        snapshot.isAcceptableOrUnknown(data['snapshot']!, _snapshotMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    if (data.containsKey('changed_by_user_id')) {
      context.handle(
        _changedByUserIdMeta,
        changedByUserId.isAcceptableOrUnknown(
          data['changed_by_user_id']!,
          _changedByUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changedByUserIdMeta);
    }
    if (data.containsKey('changed_by_device_id')) {
      context.handle(
        _changedByDeviceIdMeta,
        changedByDeviceId.isAcceptableOrUnknown(
          data['changed_by_device_id']!,
          _changedByDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changedByDeviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      firmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firm_id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      snapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}changed_at'],
      )!,
      changedByUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}changed_by_user_id'],
      )!,
      changedByDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}changed_by_device_id'],
      )!,
    );
  }

  @override
  TransactionHistory createAlias(String alias) {
    return TransactionHistory(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY(firm_id, transaction_id)REFERENCES transactions(firm_id, id)ON DELETE CASCADE',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class TransactionHistoryRow extends DataClass
    implements Insertable<TransactionHistoryRow> {
  final String id;
  final String firmId;
  final String transactionId;
  final int version;
  final String snapshot;

  /// JSON {schema_version, header, lines, customer_name, item_names}
  final String reason;
  final int changedAt;
  final String changedByUserId;
  final String changedByDeviceId;
  const TransactionHistoryRow({
    required this.id,
    required this.firmId,
    required this.transactionId,
    required this.version,
    required this.snapshot,
    required this.reason,
    required this.changedAt,
    required this.changedByUserId,
    required this.changedByDeviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['firm_id'] = Variable<String>(firmId);
    map['transaction_id'] = Variable<String>(transactionId);
    map['version'] = Variable<int>(version);
    map['snapshot'] = Variable<String>(snapshot);
    map['reason'] = Variable<String>(reason);
    map['changed_at'] = Variable<int>(changedAt);
    map['changed_by_user_id'] = Variable<String>(changedByUserId);
    map['changed_by_device_id'] = Variable<String>(changedByDeviceId);
    return map;
  }

  TransactionHistoryCompanion toCompanion(bool nullToAbsent) {
    return TransactionHistoryCompanion(
      id: Value(id),
      firmId: Value(firmId),
      transactionId: Value(transactionId),
      version: Value(version),
      snapshot: Value(snapshot),
      reason: Value(reason),
      changedAt: Value(changedAt),
      changedByUserId: Value(changedByUserId),
      changedByDeviceId: Value(changedByDeviceId),
    );
  }

  factory TransactionHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionHistoryRow(
      id: serializer.fromJson<String>(json['id']),
      firmId: serializer.fromJson<String>(json['firm_id']),
      transactionId: serializer.fromJson<String>(json['transaction_id']),
      version: serializer.fromJson<int>(json['version']),
      snapshot: serializer.fromJson<String>(json['snapshot']),
      reason: serializer.fromJson<String>(json['reason']),
      changedAt: serializer.fromJson<int>(json['changed_at']),
      changedByUserId: serializer.fromJson<String>(json['changed_by_user_id']),
      changedByDeviceId: serializer.fromJson<String>(
        json['changed_by_device_id'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'firm_id': serializer.toJson<String>(firmId),
      'transaction_id': serializer.toJson<String>(transactionId),
      'version': serializer.toJson<int>(version),
      'snapshot': serializer.toJson<String>(snapshot),
      'reason': serializer.toJson<String>(reason),
      'changed_at': serializer.toJson<int>(changedAt),
      'changed_by_user_id': serializer.toJson<String>(changedByUserId),
      'changed_by_device_id': serializer.toJson<String>(changedByDeviceId),
    };
  }

  TransactionHistoryRow copyWith({
    String? id,
    String? firmId,
    String? transactionId,
    int? version,
    String? snapshot,
    String? reason,
    int? changedAt,
    String? changedByUserId,
    String? changedByDeviceId,
  }) => TransactionHistoryRow(
    id: id ?? this.id,
    firmId: firmId ?? this.firmId,
    transactionId: transactionId ?? this.transactionId,
    version: version ?? this.version,
    snapshot: snapshot ?? this.snapshot,
    reason: reason ?? this.reason,
    changedAt: changedAt ?? this.changedAt,
    changedByUserId: changedByUserId ?? this.changedByUserId,
    changedByDeviceId: changedByDeviceId ?? this.changedByDeviceId,
  );
  TransactionHistoryRow copyWithCompanion(TransactionHistoryCompanion data) {
    return TransactionHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      firmId: data.firmId.present ? data.firmId.value : this.firmId,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      version: data.version.present ? data.version.value : this.version,
      snapshot: data.snapshot.present ? data.snapshot.value : this.snapshot,
      reason: data.reason.present ? data.reason.value : this.reason,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      changedByUserId: data.changedByUserId.present
          ? data.changedByUserId.value
          : this.changedByUserId,
      changedByDeviceId: data.changedByDeviceId.present
          ? data.changedByDeviceId.value
          : this.changedByDeviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionHistoryRow(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('transactionId: $transactionId, ')
          ..write('version: $version, ')
          ..write('snapshot: $snapshot, ')
          ..write('reason: $reason, ')
          ..write('changedAt: $changedAt, ')
          ..write('changedByUserId: $changedByUserId, ')
          ..write('changedByDeviceId: $changedByDeviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firmId,
    transactionId,
    version,
    snapshot,
    reason,
    changedAt,
    changedByUserId,
    changedByDeviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionHistoryRow &&
          other.id == this.id &&
          other.firmId == this.firmId &&
          other.transactionId == this.transactionId &&
          other.version == this.version &&
          other.snapshot == this.snapshot &&
          other.reason == this.reason &&
          other.changedAt == this.changedAt &&
          other.changedByUserId == this.changedByUserId &&
          other.changedByDeviceId == this.changedByDeviceId);
}

class TransactionHistoryCompanion
    extends UpdateCompanion<TransactionHistoryRow> {
  final Value<String> id;
  final Value<String> firmId;
  final Value<String> transactionId;
  final Value<int> version;
  final Value<String> snapshot;
  final Value<String> reason;
  final Value<int> changedAt;
  final Value<String> changedByUserId;
  final Value<String> changedByDeviceId;
  final Value<int> rowid;
  const TransactionHistoryCompanion({
    this.id = const Value.absent(),
    this.firmId = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.version = const Value.absent(),
    this.snapshot = const Value.absent(),
    this.reason = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.changedByUserId = const Value.absent(),
    this.changedByDeviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionHistoryCompanion.insert({
    required String id,
    required String firmId,
    required String transactionId,
    required int version,
    required String snapshot,
    required String reason,
    required int changedAt,
    required String changedByUserId,
    required String changedByDeviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       firmId = Value(firmId),
       transactionId = Value(transactionId),
       version = Value(version),
       snapshot = Value(snapshot),
       reason = Value(reason),
       changedAt = Value(changedAt),
       changedByUserId = Value(changedByUserId),
       changedByDeviceId = Value(changedByDeviceId);
  static Insertable<TransactionHistoryRow> custom({
    Expression<String>? id,
    Expression<String>? firmId,
    Expression<String>? transactionId,
    Expression<int>? version,
    Expression<String>? snapshot,
    Expression<String>? reason,
    Expression<int>? changedAt,
    Expression<String>? changedByUserId,
    Expression<String>? changedByDeviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firmId != null) 'firm_id': firmId,
      if (transactionId != null) 'transaction_id': transactionId,
      if (version != null) 'version': version,
      if (snapshot != null) 'snapshot': snapshot,
      if (reason != null) 'reason': reason,
      if (changedAt != null) 'changed_at': changedAt,
      if (changedByUserId != null) 'changed_by_user_id': changedByUserId,
      if (changedByDeviceId != null) 'changed_by_device_id': changedByDeviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? firmId,
    Value<String>? transactionId,
    Value<int>? version,
    Value<String>? snapshot,
    Value<String>? reason,
    Value<int>? changedAt,
    Value<String>? changedByUserId,
    Value<String>? changedByDeviceId,
    Value<int>? rowid,
  }) {
    return TransactionHistoryCompanion(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      transactionId: transactionId ?? this.transactionId,
      version: version ?? this.version,
      snapshot: snapshot ?? this.snapshot,
      reason: reason ?? this.reason,
      changedAt: changedAt ?? this.changedAt,
      changedByUserId: changedByUserId ?? this.changedByUserId,
      changedByDeviceId: changedByDeviceId ?? this.changedByDeviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (firmId.present) {
      map['firm_id'] = Variable<String>(firmId.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (snapshot.present) {
      map['snapshot'] = Variable<String>(snapshot.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<int>(changedAt.value);
    }
    if (changedByUserId.present) {
      map['changed_by_user_id'] = Variable<String>(changedByUserId.value);
    }
    if (changedByDeviceId.present) {
      map['changed_by_device_id'] = Variable<String>(changedByDeviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionHistoryCompanion(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('transactionId: $transactionId, ')
          ..write('version: $version, ')
          ..write('snapshot: $snapshot, ')
          ..write('reason: $reason, ')
          ..write('changedAt: $changedAt, ')
          ..write('changedByUserId: $changedByUserId, ')
          ..write('changedByDeviceId: $changedByDeviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PrintLog extends Table with TableInfo<PrintLog, PrintLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PrintLog(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY CHECK (id = lower(id) AND length(id) = 36)',
  );
  static const VerificationMeta _firmIdMeta = const VerificationMeta('firmId');
  late final GeneratedColumn<String> firmId = GeneratedColumn<String>(
    'firm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (kind IN (\'slip\', \'ledger\', \'export_pdf\', \'export_png\'))',
  );
  static const VerificationMeta _printedAtMeta = const VerificationMeta(
    'printedAt',
  );
  late final GeneratedColumn<int> printedAt = GeneratedColumn<int>(
    'printed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _printedBalanceAfterMeta =
      const VerificationMeta('printedBalanceAfter');
  late final GeneratedColumn<int> printedBalanceAfter = GeneratedColumn<int>(
    'printed_balance_after',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _rangeFromMeta = const VerificationMeta(
    'rangeFrom',
  );
  late final GeneratedColumn<String> rangeFrom = GeneratedColumn<String>(
    'range_from',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _rangeToMeta = const VerificationMeta(
    'rangeTo',
  );
  late final GeneratedColumn<String> rangeTo = GeneratedColumn<String>(
    'range_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firmId,
    transactionId,
    customerId,
    kind,
    printedAt,
    deviceId,
    printedBalanceAfter,
    rangeFrom,
    rangeTo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'print_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrintLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('firm_id')) {
      context.handle(
        _firmIdMeta,
        firmId.isAcceptableOrUnknown(data['firm_id']!, _firmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_firmIdMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('printed_at')) {
      context.handle(
        _printedAtMeta,
        printedAt.isAcceptableOrUnknown(data['printed_at']!, _printedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_printedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('printed_balance_after')) {
      context.handle(
        _printedBalanceAfterMeta,
        printedBalanceAfter.isAcceptableOrUnknown(
          data['printed_balance_after']!,
          _printedBalanceAfterMeta,
        ),
      );
    }
    if (data.containsKey('range_from')) {
      context.handle(
        _rangeFromMeta,
        rangeFrom.isAcceptableOrUnknown(data['range_from']!, _rangeFromMeta),
      );
    }
    if (data.containsKey('range_to')) {
      context.handle(
        _rangeToMeta,
        rangeTo.isAcceptableOrUnknown(data['range_to']!, _rangeToMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrintLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrintLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      firmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firm_id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      ),
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      printedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}printed_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      printedBalanceAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}printed_balance_after'],
      ),
      rangeFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}range_from'],
      ),
      rangeTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}range_to'],
      ),
    );
  }

  @override
  PrintLog createAlias(String alias) {
    return PrintLog(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PrintLogRow extends DataClass implements Insertable<PrintLogRow> {
  final String id;
  final String firmId;
  final String? transactionId;
  final String? customerId;
  final String kind;
  final int printedAt;
  final String deviceId;
  final int? printedBalanceAfter;
  final String? rangeFrom;
  final String? rangeTo;
  const PrintLogRow({
    required this.id,
    required this.firmId,
    this.transactionId,
    this.customerId,
    required this.kind,
    required this.printedAt,
    required this.deviceId,
    this.printedBalanceAfter,
    this.rangeFrom,
    this.rangeTo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['firm_id'] = Variable<String>(firmId);
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String>(transactionId);
    }
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['kind'] = Variable<String>(kind);
    map['printed_at'] = Variable<int>(printedAt);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || printedBalanceAfter != null) {
      map['printed_balance_after'] = Variable<int>(printedBalanceAfter);
    }
    if (!nullToAbsent || rangeFrom != null) {
      map['range_from'] = Variable<String>(rangeFrom);
    }
    if (!nullToAbsent || rangeTo != null) {
      map['range_to'] = Variable<String>(rangeTo);
    }
    return map;
  }

  PrintLogCompanion toCompanion(bool nullToAbsent) {
    return PrintLogCompanion(
      id: Value(id),
      firmId: Value(firmId),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      kind: Value(kind),
      printedAt: Value(printedAt),
      deviceId: Value(deviceId),
      printedBalanceAfter: printedBalanceAfter == null && nullToAbsent
          ? const Value.absent()
          : Value(printedBalanceAfter),
      rangeFrom: rangeFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(rangeFrom),
      rangeTo: rangeTo == null && nullToAbsent
          ? const Value.absent()
          : Value(rangeTo),
    );
  }

  factory PrintLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrintLogRow(
      id: serializer.fromJson<String>(json['id']),
      firmId: serializer.fromJson<String>(json['firm_id']),
      transactionId: serializer.fromJson<String?>(json['transaction_id']),
      customerId: serializer.fromJson<String?>(json['customer_id']),
      kind: serializer.fromJson<String>(json['kind']),
      printedAt: serializer.fromJson<int>(json['printed_at']),
      deviceId: serializer.fromJson<String>(json['device_id']),
      printedBalanceAfter: serializer.fromJson<int?>(
        json['printed_balance_after'],
      ),
      rangeFrom: serializer.fromJson<String?>(json['range_from']),
      rangeTo: serializer.fromJson<String?>(json['range_to']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'firm_id': serializer.toJson<String>(firmId),
      'transaction_id': serializer.toJson<String?>(transactionId),
      'customer_id': serializer.toJson<String?>(customerId),
      'kind': serializer.toJson<String>(kind),
      'printed_at': serializer.toJson<int>(printedAt),
      'device_id': serializer.toJson<String>(deviceId),
      'printed_balance_after': serializer.toJson<int?>(printedBalanceAfter),
      'range_from': serializer.toJson<String?>(rangeFrom),
      'range_to': serializer.toJson<String?>(rangeTo),
    };
  }

  PrintLogRow copyWith({
    String? id,
    String? firmId,
    Value<String?> transactionId = const Value.absent(),
    Value<String?> customerId = const Value.absent(),
    String? kind,
    int? printedAt,
    String? deviceId,
    Value<int?> printedBalanceAfter = const Value.absent(),
    Value<String?> rangeFrom = const Value.absent(),
    Value<String?> rangeTo = const Value.absent(),
  }) => PrintLogRow(
    id: id ?? this.id,
    firmId: firmId ?? this.firmId,
    transactionId: transactionId.present
        ? transactionId.value
        : this.transactionId,
    customerId: customerId.present ? customerId.value : this.customerId,
    kind: kind ?? this.kind,
    printedAt: printedAt ?? this.printedAt,
    deviceId: deviceId ?? this.deviceId,
    printedBalanceAfter: printedBalanceAfter.present
        ? printedBalanceAfter.value
        : this.printedBalanceAfter,
    rangeFrom: rangeFrom.present ? rangeFrom.value : this.rangeFrom,
    rangeTo: rangeTo.present ? rangeTo.value : this.rangeTo,
  );
  PrintLogRow copyWithCompanion(PrintLogCompanion data) {
    return PrintLogRow(
      id: data.id.present ? data.id.value : this.id,
      firmId: data.firmId.present ? data.firmId.value : this.firmId,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      printedAt: data.printedAt.present ? data.printedAt.value : this.printedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      printedBalanceAfter: data.printedBalanceAfter.present
          ? data.printedBalanceAfter.value
          : this.printedBalanceAfter,
      rangeFrom: data.rangeFrom.present ? data.rangeFrom.value : this.rangeFrom,
      rangeTo: data.rangeTo.present ? data.rangeTo.value : this.rangeTo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrintLogRow(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('transactionId: $transactionId, ')
          ..write('customerId: $customerId, ')
          ..write('kind: $kind, ')
          ..write('printedAt: $printedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('printedBalanceAfter: $printedBalanceAfter, ')
          ..write('rangeFrom: $rangeFrom, ')
          ..write('rangeTo: $rangeTo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firmId,
    transactionId,
    customerId,
    kind,
    printedAt,
    deviceId,
    printedBalanceAfter,
    rangeFrom,
    rangeTo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrintLogRow &&
          other.id == this.id &&
          other.firmId == this.firmId &&
          other.transactionId == this.transactionId &&
          other.customerId == this.customerId &&
          other.kind == this.kind &&
          other.printedAt == this.printedAt &&
          other.deviceId == this.deviceId &&
          other.printedBalanceAfter == this.printedBalanceAfter &&
          other.rangeFrom == this.rangeFrom &&
          other.rangeTo == this.rangeTo);
}

class PrintLogCompanion extends UpdateCompanion<PrintLogRow> {
  final Value<String> id;
  final Value<String> firmId;
  final Value<String?> transactionId;
  final Value<String?> customerId;
  final Value<String> kind;
  final Value<int> printedAt;
  final Value<String> deviceId;
  final Value<int?> printedBalanceAfter;
  final Value<String?> rangeFrom;
  final Value<String?> rangeTo;
  final Value<int> rowid;
  const PrintLogCompanion({
    this.id = const Value.absent(),
    this.firmId = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.customerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.printedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.printedBalanceAfter = const Value.absent(),
    this.rangeFrom = const Value.absent(),
    this.rangeTo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrintLogCompanion.insert({
    required String id,
    required String firmId,
    this.transactionId = const Value.absent(),
    this.customerId = const Value.absent(),
    required String kind,
    required int printedAt,
    required String deviceId,
    this.printedBalanceAfter = const Value.absent(),
    this.rangeFrom = const Value.absent(),
    this.rangeTo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       firmId = Value(firmId),
       kind = Value(kind),
       printedAt = Value(printedAt),
       deviceId = Value(deviceId);
  static Insertable<PrintLogRow> custom({
    Expression<String>? id,
    Expression<String>? firmId,
    Expression<String>? transactionId,
    Expression<String>? customerId,
    Expression<String>? kind,
    Expression<int>? printedAt,
    Expression<String>? deviceId,
    Expression<int>? printedBalanceAfter,
    Expression<String>? rangeFrom,
    Expression<String>? rangeTo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firmId != null) 'firm_id': firmId,
      if (transactionId != null) 'transaction_id': transactionId,
      if (customerId != null) 'customer_id': customerId,
      if (kind != null) 'kind': kind,
      if (printedAt != null) 'printed_at': printedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (printedBalanceAfter != null)
        'printed_balance_after': printedBalanceAfter,
      if (rangeFrom != null) 'range_from': rangeFrom,
      if (rangeTo != null) 'range_to': rangeTo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrintLogCompanion copyWith({
    Value<String>? id,
    Value<String>? firmId,
    Value<String?>? transactionId,
    Value<String?>? customerId,
    Value<String>? kind,
    Value<int>? printedAt,
    Value<String>? deviceId,
    Value<int?>? printedBalanceAfter,
    Value<String?>? rangeFrom,
    Value<String?>? rangeTo,
    Value<int>? rowid,
  }) {
    return PrintLogCompanion(
      id: id ?? this.id,
      firmId: firmId ?? this.firmId,
      transactionId: transactionId ?? this.transactionId,
      customerId: customerId ?? this.customerId,
      kind: kind ?? this.kind,
      printedAt: printedAt ?? this.printedAt,
      deviceId: deviceId ?? this.deviceId,
      printedBalanceAfter: printedBalanceAfter ?? this.printedBalanceAfter,
      rangeFrom: rangeFrom ?? this.rangeFrom,
      rangeTo: rangeTo ?? this.rangeTo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (firmId.present) {
      map['firm_id'] = Variable<String>(firmId.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (printedAt.present) {
      map['printed_at'] = Variable<int>(printedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (printedBalanceAfter.present) {
      map['printed_balance_after'] = Variable<int>(printedBalanceAfter.value);
    }
    if (rangeFrom.present) {
      map['range_from'] = Variable<String>(rangeFrom.value);
    }
    if (rangeTo.present) {
      map['range_to'] = Variable<String>(rangeTo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrintLogCompanion(')
          ..write('id: $id, ')
          ..write('firmId: $firmId, ')
          ..write('transactionId: $transactionId, ')
          ..write('customerId: $customerId, ')
          ..write('kind: $kind, ')
          ..write('printedAt: $printedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('printedBalanceAfter: $printedBalanceAfter, ')
          ..write('rangeFrom: $rangeFrom, ')
          ..write('rangeTo: $rangeTo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncOutbox extends Table with TableInfo<SyncOutbox, SyncOutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncOutbox(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _queuedUpdatedAtMeta = const VerificationMeta(
    'queuedUpdatedAt',
  );
  late final GeneratedColumn<int> queuedUpdatedAt = GeneratedColumn<int>(
    'queued_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _failedReasonMeta = const VerificationMeta(
    'failedReason',
  );
  late final GeneratedColumn<String> failedReason = GeneratedColumn<String>(
    'failed_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    targetTable,
    rowId,
    queuedUpdatedAt,
    attempts,
    failedReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('queued_updated_at')) {
      context.handle(
        _queuedUpdatedAtMeta,
        queuedUpdatedAt.isAcceptableOrUnknown(
          data['queued_updated_at']!,
          _queuedUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_queuedUpdatedAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('failed_reason')) {
      context.handle(
        _failedReasonMeta,
        failedReason.isAcceptableOrUnknown(
          data['failed_reason']!,
          _failedReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {targetTable, rowId};
  @override
  SyncOutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxRow(
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      queuedUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}queued_updated_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      failedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failed_reason'],
      ),
    );
  }

  @override
  SyncOutbox createAlias(String alias) {
    return SyncOutbox(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(target_table, row_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class SyncOutboxRow extends DataClass implements Insertable<SyncOutboxRow> {
  final String targetTable;

  /// "transactions", "customers", …; not table_name: drift reserves it
  final String rowId;
  final int queuedUpdatedAt;
  final int attempts;
  final String? failedReason;
  const SyncOutboxRow({
    required this.targetTable,
    required this.rowId,
    required this.queuedUpdatedAt,
    required this.attempts,
    this.failedReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['target_table'] = Variable<String>(targetTable);
    map['row_id'] = Variable<String>(rowId);
    map['queued_updated_at'] = Variable<int>(queuedUpdatedAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || failedReason != null) {
      map['failed_reason'] = Variable<String>(failedReason);
    }
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      targetTable: Value(targetTable),
      rowId: Value(rowId),
      queuedUpdatedAt: Value(queuedUpdatedAt),
      attempts: Value(attempts),
      failedReason: failedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failedReason),
    );
  }

  factory SyncOutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxRow(
      targetTable: serializer.fromJson<String>(json['target_table']),
      rowId: serializer.fromJson<String>(json['row_id']),
      queuedUpdatedAt: serializer.fromJson<int>(json['queued_updated_at']),
      attempts: serializer.fromJson<int>(json['attempts']),
      failedReason: serializer.fromJson<String?>(json['failed_reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'target_table': serializer.toJson<String>(targetTable),
      'row_id': serializer.toJson<String>(rowId),
      'queued_updated_at': serializer.toJson<int>(queuedUpdatedAt),
      'attempts': serializer.toJson<int>(attempts),
      'failed_reason': serializer.toJson<String?>(failedReason),
    };
  }

  SyncOutboxRow copyWith({
    String? targetTable,
    String? rowId,
    int? queuedUpdatedAt,
    int? attempts,
    Value<String?> failedReason = const Value.absent(),
  }) => SyncOutboxRow(
    targetTable: targetTable ?? this.targetTable,
    rowId: rowId ?? this.rowId,
    queuedUpdatedAt: queuedUpdatedAt ?? this.queuedUpdatedAt,
    attempts: attempts ?? this.attempts,
    failedReason: failedReason.present ? failedReason.value : this.failedReason,
  );
  SyncOutboxRow copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxRow(
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      queuedUpdatedAt: data.queuedUpdatedAt.present
          ? data.queuedUpdatedAt.value
          : this.queuedUpdatedAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      failedReason: data.failedReason.present
          ? data.failedReason.value
          : this.failedReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxRow(')
          ..write('targetTable: $targetTable, ')
          ..write('rowId: $rowId, ')
          ..write('queuedUpdatedAt: $queuedUpdatedAt, ')
          ..write('attempts: $attempts, ')
          ..write('failedReason: $failedReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(targetTable, rowId, queuedUpdatedAt, attempts, failedReason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxRow &&
          other.targetTable == this.targetTable &&
          other.rowId == this.rowId &&
          other.queuedUpdatedAt == this.queuedUpdatedAt &&
          other.attempts == this.attempts &&
          other.failedReason == this.failedReason);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxRow> {
  final Value<String> targetTable;
  final Value<String> rowId;
  final Value<int> queuedUpdatedAt;
  final Value<int> attempts;
  final Value<String?> failedReason;
  final Value<int> rowid;
  const SyncOutboxCompanion({
    this.targetTable = const Value.absent(),
    this.rowId = const Value.absent(),
    this.queuedUpdatedAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.failedReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    required String targetTable,
    required String rowId,
    required int queuedUpdatedAt,
    this.attempts = const Value.absent(),
    this.failedReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : targetTable = Value(targetTable),
       rowId = Value(rowId),
       queuedUpdatedAt = Value(queuedUpdatedAt);
  static Insertable<SyncOutboxRow> custom({
    Expression<String>? targetTable,
    Expression<String>? rowId,
    Expression<int>? queuedUpdatedAt,
    Expression<int>? attempts,
    Expression<String>? failedReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (targetTable != null) 'target_table': targetTable,
      if (rowId != null) 'row_id': rowId,
      if (queuedUpdatedAt != null) 'queued_updated_at': queuedUpdatedAt,
      if (attempts != null) 'attempts': attempts,
      if (failedReason != null) 'failed_reason': failedReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<String>? targetTable,
    Value<String>? rowId,
    Value<int>? queuedUpdatedAt,
    Value<int>? attempts,
    Value<String?>? failedReason,
    Value<int>? rowid,
  }) {
    return SyncOutboxCompanion(
      targetTable: targetTable ?? this.targetTable,
      rowId: rowId ?? this.rowId,
      queuedUpdatedAt: queuedUpdatedAt ?? this.queuedUpdatedAt,
      attempts: attempts ?? this.attempts,
      failedReason: failedReason ?? this.failedReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (queuedUpdatedAt.present) {
      map['queued_updated_at'] = Variable<int>(queuedUpdatedAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (failedReason.present) {
      map['failed_reason'] = Variable<String>(failedReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('targetTable: $targetTable, ')
          ..write('rowId: $rowId, ')
          ..write('queuedUpdatedAt: $queuedUpdatedAt, ')
          ..write('attempts: $attempts, ')
          ..write('failedReason: $failedReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncOrphans extends Table with TableInfo<SyncOrphans, SyncOrphanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncOrphans(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _missingParentTableMeta =
      const VerificationMeta('missingParentTable');
  late final GeneratedColumn<String> missingParentTable =
      GeneratedColumn<String>(
        'missing_parent_table',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _missingParentIdMeta = const VerificationMeta(
    'missingParentId',
  );
  late final GeneratedColumn<String> missingParentId = GeneratedColumn<String>(
    'missing_parent_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  late final GeneratedColumn<int> receivedAt = GeneratedColumn<int>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    targetTable,
    rowId,
    payload,
    missingParentTable,
    missingParentId,
    receivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_orphans';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOrphanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('missing_parent_table')) {
      context.handle(
        _missingParentTableMeta,
        missingParentTable.isAcceptableOrUnknown(
          data['missing_parent_table']!,
          _missingParentTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_missingParentTableMeta);
    }
    if (data.containsKey('missing_parent_id')) {
      context.handle(
        _missingParentIdMeta,
        missingParentId.isAcceptableOrUnknown(
          data['missing_parent_id']!,
          _missingParentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_missingParentIdMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {targetTable, rowId};
  @override
  SyncOrphanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOrphanRow(
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      missingParentTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}missing_parent_table'],
      )!,
      missingParentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}missing_parent_id'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_at'],
      )!,
    );
  }

  @override
  SyncOrphans createAlias(String alias) {
    return SyncOrphans(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(target_table, row_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class SyncOrphanRow extends DataClass implements Insertable<SyncOrphanRow> {
  final String targetTable;

  /// "transactions", "customers", …; not table_name: drift reserves it
  final String rowId;
  final String payload;
  final String missingParentTable;
  final String missingParentId;
  final int receivedAt;
  const SyncOrphanRow({
    required this.targetTable,
    required this.rowId,
    required this.payload,
    required this.missingParentTable,
    required this.missingParentId,
    required this.receivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['target_table'] = Variable<String>(targetTable);
    map['row_id'] = Variable<String>(rowId);
    map['payload'] = Variable<String>(payload);
    map['missing_parent_table'] = Variable<String>(missingParentTable);
    map['missing_parent_id'] = Variable<String>(missingParentId);
    map['received_at'] = Variable<int>(receivedAt);
    return map;
  }

  SyncOrphansCompanion toCompanion(bool nullToAbsent) {
    return SyncOrphansCompanion(
      targetTable: Value(targetTable),
      rowId: Value(rowId),
      payload: Value(payload),
      missingParentTable: Value(missingParentTable),
      missingParentId: Value(missingParentId),
      receivedAt: Value(receivedAt),
    );
  }

  factory SyncOrphanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOrphanRow(
      targetTable: serializer.fromJson<String>(json['target_table']),
      rowId: serializer.fromJson<String>(json['row_id']),
      payload: serializer.fromJson<String>(json['payload']),
      missingParentTable: serializer.fromJson<String>(
        json['missing_parent_table'],
      ),
      missingParentId: serializer.fromJson<String>(json['missing_parent_id']),
      receivedAt: serializer.fromJson<int>(json['received_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'target_table': serializer.toJson<String>(targetTable),
      'row_id': serializer.toJson<String>(rowId),
      'payload': serializer.toJson<String>(payload),
      'missing_parent_table': serializer.toJson<String>(missingParentTable),
      'missing_parent_id': serializer.toJson<String>(missingParentId),
      'received_at': serializer.toJson<int>(receivedAt),
    };
  }

  SyncOrphanRow copyWith({
    String? targetTable,
    String? rowId,
    String? payload,
    String? missingParentTable,
    String? missingParentId,
    int? receivedAt,
  }) => SyncOrphanRow(
    targetTable: targetTable ?? this.targetTable,
    rowId: rowId ?? this.rowId,
    payload: payload ?? this.payload,
    missingParentTable: missingParentTable ?? this.missingParentTable,
    missingParentId: missingParentId ?? this.missingParentId,
    receivedAt: receivedAt ?? this.receivedAt,
  );
  SyncOrphanRow copyWithCompanion(SyncOrphansCompanion data) {
    return SyncOrphanRow(
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      payload: data.payload.present ? data.payload.value : this.payload,
      missingParentTable: data.missingParentTable.present
          ? data.missingParentTable.value
          : this.missingParentTable,
      missingParentId: data.missingParentId.present
          ? data.missingParentId.value
          : this.missingParentId,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOrphanRow(')
          ..write('targetTable: $targetTable, ')
          ..write('rowId: $rowId, ')
          ..write('payload: $payload, ')
          ..write('missingParentTable: $missingParentTable, ')
          ..write('missingParentId: $missingParentId, ')
          ..write('receivedAt: $receivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    targetTable,
    rowId,
    payload,
    missingParentTable,
    missingParentId,
    receivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOrphanRow &&
          other.targetTable == this.targetTable &&
          other.rowId == this.rowId &&
          other.payload == this.payload &&
          other.missingParentTable == this.missingParentTable &&
          other.missingParentId == this.missingParentId &&
          other.receivedAt == this.receivedAt);
}

class SyncOrphansCompanion extends UpdateCompanion<SyncOrphanRow> {
  final Value<String> targetTable;
  final Value<String> rowId;
  final Value<String> payload;
  final Value<String> missingParentTable;
  final Value<String> missingParentId;
  final Value<int> receivedAt;
  final Value<int> rowid;
  const SyncOrphansCompanion({
    this.targetTable = const Value.absent(),
    this.rowId = const Value.absent(),
    this.payload = const Value.absent(),
    this.missingParentTable = const Value.absent(),
    this.missingParentId = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOrphansCompanion.insert({
    required String targetTable,
    required String rowId,
    required String payload,
    required String missingParentTable,
    required String missingParentId,
    required int receivedAt,
    this.rowid = const Value.absent(),
  }) : targetTable = Value(targetTable),
       rowId = Value(rowId),
       payload = Value(payload),
       missingParentTable = Value(missingParentTable),
       missingParentId = Value(missingParentId),
       receivedAt = Value(receivedAt);
  static Insertable<SyncOrphanRow> custom({
    Expression<String>? targetTable,
    Expression<String>? rowId,
    Expression<String>? payload,
    Expression<String>? missingParentTable,
    Expression<String>? missingParentId,
    Expression<int>? receivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (targetTable != null) 'target_table': targetTable,
      if (rowId != null) 'row_id': rowId,
      if (payload != null) 'payload': payload,
      if (missingParentTable != null)
        'missing_parent_table': missingParentTable,
      if (missingParentId != null) 'missing_parent_id': missingParentId,
      if (receivedAt != null) 'received_at': receivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOrphansCompanion copyWith({
    Value<String>? targetTable,
    Value<String>? rowId,
    Value<String>? payload,
    Value<String>? missingParentTable,
    Value<String>? missingParentId,
    Value<int>? receivedAt,
    Value<int>? rowid,
  }) {
    return SyncOrphansCompanion(
      targetTable: targetTable ?? this.targetTable,
      rowId: rowId ?? this.rowId,
      payload: payload ?? this.payload,
      missingParentTable: missingParentTable ?? this.missingParentTable,
      missingParentId: missingParentId ?? this.missingParentId,
      receivedAt: receivedAt ?? this.receivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (missingParentTable.present) {
      map['missing_parent_table'] = Variable<String>(missingParentTable.value);
    }
    if (missingParentId.present) {
      map['missing_parent_id'] = Variable<String>(missingParentId.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<int>(receivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOrphansCompanion(')
          ..write('targetTable: $targetTable, ')
          ..write('rowId: $rowId, ')
          ..write('payload: $payload, ')
          ..write('missingParentTable: $missingParentTable, ')
          ..write('missingParentId: $missingParentId, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncState extends Table with TableInfo<SyncState, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncState(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _lastPullCursorMeta = const VerificationMeta(
    'lastPullCursor',
  );
  late final GeneratedColumn<int> lastPullCursor = GeneratedColumn<int>(
    'last_pull_cursor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _clockOffsetMsMeta = const VerificationMeta(
    'clockOffsetMs',
  );
  late final GeneratedColumn<int> clockOffsetMs = GeneratedColumn<int>(
    'clock_offset_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _hlcLastMeta = const VerificationMeta(
    'hlcLast',
  );
  late final GeneratedColumn<int> hlcLast = GeneratedColumn<int>(
    'hlc_last',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  late final GeneratedColumn<int> lastSyncAt = GeneratedColumn<int>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _pausedReasonMeta = const VerificationMeta(
    'pausedReason',
  );
  late final GeneratedColumn<String> pausedReason = GeneratedColumn<String>(
    'paused_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    lastPullCursor,
    clockOffsetMs,
    hlcLast,
    lastSyncAt,
    pausedReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('last_pull_cursor')) {
      context.handle(
        _lastPullCursorMeta,
        lastPullCursor.isAcceptableOrUnknown(
          data['last_pull_cursor']!,
          _lastPullCursorMeta,
        ),
      );
    }
    if (data.containsKey('clock_offset_ms')) {
      context.handle(
        _clockOffsetMsMeta,
        clockOffsetMs.isAcceptableOrUnknown(
          data['clock_offset_ms']!,
          _clockOffsetMsMeta,
        ),
      );
    }
    if (data.containsKey('hlc_last')) {
      context.handle(
        _hlcLastMeta,
        hlcLast.isAcceptableOrUnknown(data['hlc_last']!, _hlcLastMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('paused_reason')) {
      context.handle(
        _pausedReasonMeta,
        pausedReason.isAcceptableOrUnknown(
          data['paused_reason']!,
          _pausedReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      lastPullCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_pull_cursor'],
      )!,
      clockOffsetMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clock_offset_ms'],
      )!,
      hlcLast: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hlc_last'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sync_at'],
      ),
      pausedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paused_reason'],
      ),
    );
  }

  @override
  SyncState createAlias(String alias) {
    return SyncState(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String deviceId;
  final int lastPullCursor;
  final int clockOffsetMs;
  final int hlcLast;
  final int? lastSyncAt;
  final String? pausedReason;
  const SyncStateRow({
    required this.deviceId,
    required this.lastPullCursor,
    required this.clockOffsetMs,
    required this.hlcLast,
    this.lastSyncAt,
    this.pausedReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['last_pull_cursor'] = Variable<int>(lastPullCursor);
    map['clock_offset_ms'] = Variable<int>(clockOffsetMs);
    map['hlc_last'] = Variable<int>(hlcLast);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<int>(lastSyncAt);
    }
    if (!nullToAbsent || pausedReason != null) {
      map['paused_reason'] = Variable<String>(pausedReason);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      deviceId: Value(deviceId),
      lastPullCursor: Value(lastPullCursor),
      clockOffsetMs: Value(clockOffsetMs),
      hlcLast: Value(hlcLast),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      pausedReason: pausedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedReason),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      deviceId: serializer.fromJson<String>(json['device_id']),
      lastPullCursor: serializer.fromJson<int>(json['last_pull_cursor']),
      clockOffsetMs: serializer.fromJson<int>(json['clock_offset_ms']),
      hlcLast: serializer.fromJson<int>(json['hlc_last']),
      lastSyncAt: serializer.fromJson<int?>(json['last_sync_at']),
      pausedReason: serializer.fromJson<String?>(json['paused_reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'device_id': serializer.toJson<String>(deviceId),
      'last_pull_cursor': serializer.toJson<int>(lastPullCursor),
      'clock_offset_ms': serializer.toJson<int>(clockOffsetMs),
      'hlc_last': serializer.toJson<int>(hlcLast),
      'last_sync_at': serializer.toJson<int?>(lastSyncAt),
      'paused_reason': serializer.toJson<String?>(pausedReason),
    };
  }

  SyncStateRow copyWith({
    String? deviceId,
    int? lastPullCursor,
    int? clockOffsetMs,
    int? hlcLast,
    Value<int?> lastSyncAt = const Value.absent(),
    Value<String?> pausedReason = const Value.absent(),
  }) => SyncStateRow(
    deviceId: deviceId ?? this.deviceId,
    lastPullCursor: lastPullCursor ?? this.lastPullCursor,
    clockOffsetMs: clockOffsetMs ?? this.clockOffsetMs,
    hlcLast: hlcLast ?? this.hlcLast,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    pausedReason: pausedReason.present ? pausedReason.value : this.pausedReason,
  );
  SyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      lastPullCursor: data.lastPullCursor.present
          ? data.lastPullCursor.value
          : this.lastPullCursor,
      clockOffsetMs: data.clockOffsetMs.present
          ? data.clockOffsetMs.value
          : this.clockOffsetMs,
      hlcLast: data.hlcLast.present ? data.hlcLast.value : this.hlcLast,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      pausedReason: data.pausedReason.present
          ? data.pausedReason.value
          : this.pausedReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('deviceId: $deviceId, ')
          ..write('lastPullCursor: $lastPullCursor, ')
          ..write('clockOffsetMs: $clockOffsetMs, ')
          ..write('hlcLast: $hlcLast, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('pausedReason: $pausedReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    lastPullCursor,
    clockOffsetMs,
    hlcLast,
    lastSyncAt,
    pausedReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.deviceId == this.deviceId &&
          other.lastPullCursor == this.lastPullCursor &&
          other.clockOffsetMs == this.clockOffsetMs &&
          other.hlcLast == this.hlcLast &&
          other.lastSyncAt == this.lastSyncAt &&
          other.pausedReason == this.pausedReason);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> deviceId;
  final Value<int> lastPullCursor;
  final Value<int> clockOffsetMs;
  final Value<int> hlcLast;
  final Value<int?> lastSyncAt;
  final Value<String?> pausedReason;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.deviceId = const Value.absent(),
    this.lastPullCursor = const Value.absent(),
    this.clockOffsetMs = const Value.absent(),
    this.hlcLast = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.pausedReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String deviceId,
    this.lastPullCursor = const Value.absent(),
    this.clockOffsetMs = const Value.absent(),
    this.hlcLast = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.pausedReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId);
  static Insertable<SyncStateRow> custom({
    Expression<String>? deviceId,
    Expression<int>? lastPullCursor,
    Expression<int>? clockOffsetMs,
    Expression<int>? hlcLast,
    Expression<int>? lastSyncAt,
    Expression<String>? pausedReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (lastPullCursor != null) 'last_pull_cursor': lastPullCursor,
      if (clockOffsetMs != null) 'clock_offset_ms': clockOffsetMs,
      if (hlcLast != null) 'hlc_last': hlcLast,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (pausedReason != null) 'paused_reason': pausedReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? lastPullCursor,
    Value<int>? clockOffsetMs,
    Value<int>? hlcLast,
    Value<int?>? lastSyncAt,
    Value<String?>? pausedReason,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      deviceId: deviceId ?? this.deviceId,
      lastPullCursor: lastPullCursor ?? this.lastPullCursor,
      clockOffsetMs: clockOffsetMs ?? this.clockOffsetMs,
      hlcLast: hlcLast ?? this.hlcLast,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      pausedReason: pausedReason ?? this.pausedReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (lastPullCursor.present) {
      map['last_pull_cursor'] = Variable<int>(lastPullCursor.value);
    }
    if (clockOffsetMs.present) {
      map['clock_offset_ms'] = Variable<int>(clockOffsetMs.value);
    }
    if (hlcLast.present) {
      map['hlc_last'] = Variable<int>(hlcLast.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<int>(lastSyncAt.value);
    }
    if (pausedReason.present) {
      map['paused_reason'] = Variable<String>(pausedReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('lastPullCursor: $lastPullCursor, ')
          ..write('clockOffsetMs: $clockOffsetMs, ')
          ..write('hlcLast: $hlcLast, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('pausedReason: $pausedReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AppSettings extends Table with TableInfo<AppSettings, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AppSettings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  AppSettings createAlias(String alias) {
    return AppSettings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  const AppSettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
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

  AppSettingRow copyWith({String? key, String? value}) =>
      AppSettingRow(key: key ?? this.key, value: value ?? this.value);
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
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
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingRow> custom({
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

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
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
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CustomerBalance extends DataClass {
  final String firmId;
  final String? customerId;
  final int? balance;
  const CustomerBalance({required this.firmId, this.customerId, this.balance});
  factory CustomerBalance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerBalance(
      firmId: serializer.fromJson<String>(json['firm_id']),
      customerId: serializer.fromJson<String?>(json['customer_id']),
      balance: serializer.fromJson<int?>(json['balance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'firm_id': serializer.toJson<String>(firmId),
      'customer_id': serializer.toJson<String?>(customerId),
      'balance': serializer.toJson<int?>(balance),
    };
  }

  CustomerBalance copyWith({
    String? firmId,
    Value<String?> customerId = const Value.absent(),
    Value<int?> balance = const Value.absent(),
  }) => CustomerBalance(
    firmId: firmId ?? this.firmId,
    customerId: customerId.present ? customerId.value : this.customerId,
    balance: balance.present ? balance.value : this.balance,
  );
  @override
  String toString() {
    return (StringBuffer('CustomerBalance(')
          ..write('firmId: $firmId, ')
          ..write('customerId: $customerId, ')
          ..write('balance: $balance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(firmId, customerId, balance);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerBalance &&
          other.firmId == this.firmId &&
          other.customerId == this.customerId &&
          other.balance == this.balance);
}

class CustomerBalances extends ViewInfo<CustomerBalances, CustomerBalance>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$AppDatabase attachedDatabase;
  CustomerBalances(this.attachedDatabase, [this._alias]);
  @override
  List<GeneratedColumn> get $columns => [firmId, customerId, balance];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'customer_balances';
  @override
  Map<SqlDialect, String> get createViewStatements => {
    SqlDialect.sqlite: 'CREATE VIEW customer_balances AS SELECT firm_id, customer_id, SUM(signed_amount) AS balance FROM transactions WHERE deleted_at IS NULL AND customer_id IS NOT NULL GROUP BY firm_id, customer_id',
  };
  @override
  CustomerBalances get asDslTable => this;
  @override
  CustomerBalance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerBalance(
      firmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firm_id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      ),
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance'],
      ),
    );
  }

  late final GeneratedColumn<String> firmId = GeneratedColumn<String>(
    'firm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<int> balance = GeneratedColumn<int>(
    'balance',
    aliasedName,
    true,
    type: DriftSqlType.int,
  );
  @override
  CustomerBalances createAlias(String alias) {
    return CustomerBalances(attachedDatabase, alias);
  }

  @override
  Query? get query => null;
  @override
  Set<String> get readTables => const {
    'transactions',
    'firms',
    'users',
    'customers',
  };
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final Firms firms = Firms(this);
  late final Users users = Users(this);
  late final FirmMembers firmMembers = FirmMembers(this);
  late final Index idxMembersLive = Index(
    'idx_members_live',
    'CREATE UNIQUE INDEX idx_members_live ON firm_members (firm_id, user_id) WHERE deleted_at IS NULL',
  );
  late final Devices devices = Devices(this);
  late final Index idxDevicesCode = Index(
    'idx_devices_code',
    'CREATE UNIQUE INDEX idx_devices_code ON devices (firm_id, short_code)',
  );
  late final Items items = Items(this);
  late final Index idxItemsName = Index(
    'idx_items_name',
    'CREATE INDEX idx_items_name ON items (firm_id, name_normalized)',
  );
  late final Customers customers = Customers(this);
  late final Index idxCustomersName = Index(
    'idx_customers_name',
    'CREATE INDEX idx_customers_name ON customers (firm_id, name_normalized)',
  );
  late final Index idxCustomersPhone = Index(
    'idx_customers_phone',
    'CREATE UNIQUE INDEX idx_customers_phone ON customers (firm_id, phone_normalized) WHERE deleted_at IS NULL AND merged_into_id IS NULL AND phone_normalized IS NOT NULL',
  );
  late final Transactions transactions = Transactions(this);
  late final Index idxTxnBalance = Index(
    'idx_txn_balance',
    'CREATE INDEX idx_txn_balance ON transactions (firm_id, customer_id, signed_amount) WHERE deleted_at IS NULL',
  );
  late final Index idxTxnLedger = Index(
    'idx_txn_ledger',
    'CREATE INDEX idx_txn_ledger ON transactions (firm_id, customer_id, entry_date, created_at, id) WHERE deleted_at IS NULL',
  );
  late final Index idxTxnWalkin = Index(
    'idx_txn_walkin',
    'CREATE INDEX idx_txn_walkin ON transactions (firm_id, entry_date) WHERE customer_id IS NULL',
  );
  late final Index idxTxnDisplay = Index(
    'idx_txn_display',
    'CREATE UNIQUE INDEX idx_txn_display ON transactions (firm_id, device_short_code, display_seq)',
  );
  late final Index idxTxnUpdated = Index(
    'idx_txn_updated',
    'CREATE INDEX idx_txn_updated ON transactions (firm_id, updated_at)',
  );
  late final TransactionLines transactionLines = TransactionLines(this);
  late final Index idxLinesNo = Index(
    'idx_lines_no',
    'CREATE UNIQUE INDEX idx_lines_no ON transaction_lines (firm_id, transaction_id, line_no)',
  );
  late final Index idxLinesItem = Index(
    'idx_lines_item',
    'CREATE INDEX idx_lines_item ON transaction_lines (firm_id, item_id)',
  );
  late final TransactionHistory transactionHistory = TransactionHistory(this);
  late final Index idxHistoryTxn = Index(
    'idx_history_txn',
    'CREATE INDEX idx_history_txn ON transaction_history (firm_id, transaction_id, changed_at)',
  );
  late final PrintLog printLog = PrintLog(this);
  late final Index idxPrintTxn = Index(
    'idx_print_txn',
    'CREATE INDEX idx_print_txn ON print_log (firm_id, transaction_id)',
  );
  late final SyncOutbox syncOutbox = SyncOutbox(this);
  late final SyncOrphans syncOrphans = SyncOrphans(this);
  late final SyncState syncState = SyncState(this);
  late final AppSettings appSettings = AppSettings(this);
  late final CustomerBalances customerBalances = CustomerBalances(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    firms,
    users,
    firmMembers,
    idxMembersLive,
    devices,
    idxDevicesCode,
    items,
    idxItemsName,
    customers,
    idxCustomersName,
    idxCustomersPhone,
    transactions,
    idxTxnBalance,
    idxTxnLedger,
    idxTxnWalkin,
    idxTxnDisplay,
    idxTxnUpdated,
    transactionLines,
    idxLinesNo,
    idxLinesItem,
    transactionHistory,
    idxHistoryTxn,
    printLog,
    idxPrintTxn,
    syncOutbox,
    syncOrphans,
    syncState,
    appSettings,
    customerBalances,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transactions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transaction_lines', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transactions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transaction_history', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $FirmsCreateCompanionBuilder = FirmsCompanion Function({
  required String id,
  required String name,
  required String contactNumber,
  Value<String?> address,
  Value<Uint8List?> logoBlob,
  Value<String> numberGrouping,
  Value<bool> showPaisa,
  Value<String> defaultCountryCode,
  required int createdAt,
  required int updatedAt,
  required String updatedByDeviceId,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $FirmsUpdateCompanionBuilder = FirmsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> contactNumber,
  Value<String?> address,
  Value<Uint8List?> logoBlob,
  Value<String> numberGrouping,
  Value<bool> showPaisa,
  Value<String> defaultCountryCode,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> updatedByDeviceId,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $FirmsReferences
    extends BaseReferences<_$AppDatabase, Firms, FirmRow> {
  $FirmsReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<FirmMembers, List<FirmMemberRow>>
  _firmMembersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.firmMembers,
    aliasName: 'firms__id__firm_members__firm_id',
  );

  $FirmMembersProcessedTableManager get firmMembersRefs {
    final manager = $FirmMembersTableManager(
      $_db,
      $_db.firmMembers,
    ).filter((f) => f.firmId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_firmMembersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Devices, List<DeviceRow>> _devicesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.devices,
    aliasName: 'firms__id__devices__firm_id',
  );

  $DevicesProcessedTableManager get devicesRefs {
    final manager = $DevicesTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.firmId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_devicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Items, List<ItemRow>> _itemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.items,
    aliasName: 'firms__id__items__firm_id',
  );

  $ItemsProcessedTableManager get itemsRefs {
    final manager = $ItemsTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.firmId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Customers, List<CustomerRow>> _customersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.customers,
    aliasName: 'firms__id__customers__firm_id',
  );

  $CustomersProcessedTableManager get customersRefs {
    final manager = $CustomersTableManager(
      $_db,
      $_db.customers,
    ).filter((f) => f.firmId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_customersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Transactions, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'firms__id__transactions__firm_id',
  );

  $TransactionsProcessedTableManager get transactionsRefs {
    final manager = $TransactionsTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.firmId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $FirmsFilterComposer extends Composer<_$AppDatabase, Firms> {
  $FirmsFilterComposer({
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

  ColumnFilters<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get logoBlob => $composableBuilder(
    column: $table.logoBlob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numberGrouping => $composableBuilder(
    column: $table.numberGrouping,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showPaisa => $composableBuilder(
    column: $table.showPaisa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultCountryCode => $composableBuilder(
    column: $table.defaultCountryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> firmMembersRefs(
    Expression<bool> Function($FirmMembersFilterComposer f) f,
  ) {
    final $FirmMembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.firmMembers,
      getReferencedColumn: (t) => t.firmId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmMembersFilterComposer(
            $db: $db,
            $table: $db.firmMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> devicesRefs(
    Expression<bool> Function($DevicesFilterComposer f) f,
  ) {
    final $DevicesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.firmId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DevicesFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> itemsRefs(
    Expression<bool> Function($ItemsFilterComposer f) f,
  ) {
    final $ItemsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.firmId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ItemsFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> customersRefs(
    Expression<bool> Function($CustomersFilterComposer f) f,
  ) {
    final $CustomersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.firmId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomersFilterComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($TransactionsFilterComposer f) f,
  ) {
    final $TransactionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.firmId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TransactionsFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $FirmsOrderingComposer extends Composer<_$AppDatabase, Firms> {
  $FirmsOrderingComposer({
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

  ColumnOrderings<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get logoBlob => $composableBuilder(
    column: $table.logoBlob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numberGrouping => $composableBuilder(
    column: $table.numberGrouping,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showPaisa => $composableBuilder(
    column: $table.showPaisa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultCountryCode => $composableBuilder(
    column: $table.defaultCountryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $FirmsAnnotationComposer extends Composer<_$AppDatabase, Firms> {
  $FirmsAnnotationComposer({
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

  GeneratedColumn<String> get contactNumber => $composableBuilder(
    column: $table.contactNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<Uint8List> get logoBlob =>
      $composableBuilder(column: $table.logoBlob, builder: (column) => column);

  GeneratedColumn<String> get numberGrouping => $composableBuilder(
    column: $table.numberGrouping,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showPaisa =>
      $composableBuilder(column: $table.showPaisa, builder: (column) => column);

  GeneratedColumn<String> get defaultCountryCode => $composableBuilder(
    column: $table.defaultCountryCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> firmMembersRefs<T extends Object>(
    Expression<T> Function($FirmMembersAnnotationComposer a) f,
  ) {
    final $FirmMembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.firmMembers,
      getReferencedColumn: (t) => t.firmId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmMembersAnnotationComposer(
            $db: $db,
            $table: $db.firmMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> devicesRefs<T extends Object>(
    Expression<T> Function($DevicesAnnotationComposer a) f,
  ) {
    final $DevicesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.firmId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DevicesAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> itemsRefs<T extends Object>(
    Expression<T> Function($ItemsAnnotationComposer a) f,
  ) {
    final $ItemsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.firmId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ItemsAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> customersRefs<T extends Object>(
    Expression<T> Function($CustomersAnnotationComposer a) f,
  ) {
    final $CustomersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.firmId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomersAnnotationComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($TransactionsAnnotationComposer a) f,
  ) {
    final $TransactionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.firmId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TransactionsAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $FirmsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Firms,
          FirmRow,
          $FirmsFilterComposer,
          $FirmsOrderingComposer,
          $FirmsAnnotationComposer,
          $FirmsCreateCompanionBuilder,
          $FirmsUpdateCompanionBuilder,
          (FirmRow, $FirmsReferences),
          FirmRow,
          PrefetchHooks Function({
            bool firmMembersRefs,
            bool devicesRefs,
            bool itemsRefs,
            bool customersRefs,
            bool transactionsRefs,
          })
        > {
  $FirmsTableManager(_$AppDatabase db, Firms table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $FirmsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $FirmsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $FirmsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> contactNumber = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<Uint8List?> logoBlob = const Value.absent(),
                Value<String> numberGrouping = const Value.absent(),
                Value<bool> showPaisa = const Value.absent(),
                Value<String> defaultCountryCode = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedByDeviceId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FirmsCompanion(
                id: id,
                name: name,
                contactNumber: contactNumber,
                address: address,
                logoBlob: logoBlob,
                numberGrouping: numberGrouping,
                showPaisa: showPaisa,
                defaultCountryCode: defaultCountryCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedByDeviceId: updatedByDeviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String contactNumber,
                Value<String?> address = const Value.absent(),
                Value<Uint8List?> logoBlob = const Value.absent(),
                Value<String> numberGrouping = const Value.absent(),
                Value<bool> showPaisa = const Value.absent(),
                Value<String> defaultCountryCode = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                required String updatedByDeviceId,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FirmsCompanion.insert(
                id: id,
                name: name,
                contactNumber: contactNumber,
                address: address,
                logoBlob: logoBlob,
                numberGrouping: numberGrouping,
                showPaisa: showPaisa,
                defaultCountryCode: defaultCountryCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedByDeviceId: updatedByDeviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Firms, FirmRow>(table),
                  $FirmsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                firmMembersRefs = false,
                devicesRefs = false,
                itemsRefs = false,
                customersRefs = false,
                transactionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (firmMembersRefs) db.firmMembers,
                    if (devicesRefs) db.devices,
                    if (itemsRefs) db.items,
                    if (customersRefs) db.customers,
                    if (transactionsRefs) db.transactions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (firmMembersRefs)
                        await $_getPrefetchedData<
                          FirmRow,
                          Firms,
                          FirmMemberRow
                        >(
                          currentTable: table,
                          referencedTable: $FirmsReferences
                              ._firmMembersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $FirmsReferences(db, table, p0).firmMembersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.firmId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (devicesRefs)
                        await $_getPrefetchedData<FirmRow, Firms, DeviceRow>(
                          currentTable: table,
                          referencedTable: $FirmsReferences._devicesRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $FirmsReferences(db, table, p0).devicesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.firmId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (itemsRefs)
                        await $_getPrefetchedData<FirmRow, Firms, ItemRow>(
                          currentTable: table,
                          referencedTable: $FirmsReferences._itemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $FirmsReferences(db, table, p0).itemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.firmId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (customersRefs)
                        await $_getPrefetchedData<FirmRow, Firms, CustomerRow>(
                          currentTable: table,
                          referencedTable: $FirmsReferences._customersRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $FirmsReferences(db, table, p0).customersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.firmId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          FirmRow,
                          Firms,
                          TransactionRow
                        >(
                          currentTable: table,
                          referencedTable: $FirmsReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $FirmsReferences(db, table, p0).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.firmId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $FirmsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Firms,
      FirmRow,
      $FirmsFilterComposer,
      $FirmsOrderingComposer,
      $FirmsAnnotationComposer,
      $FirmsCreateCompanionBuilder,
      $FirmsUpdateCompanionBuilder,
      (FirmRow, $FirmsReferences),
      FirmRow,
      PrefetchHooks Function({
        bool firmMembersRefs,
        bool devicesRefs,
        bool itemsRefs,
        bool customersRefs,
        bool transactionsRefs,
      })
    >;
typedef $UsersCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String name,
  Value<String?> email,
  required int createdAt,
  required int updatedAt,
  required String updatedByDeviceId,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $UsersUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> email,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> updatedByDeviceId,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $UsersReferences
    extends BaseReferences<_$AppDatabase, Users, UserRow> {
  $UsersReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<FirmMembers, List<FirmMemberRow>>
  _firmMembersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.firmMembers,
    aliasName: 'users__id__firm_members__user_id',
  );

  $FirmMembersProcessedTableManager get firmMembersRefs {
    final manager = $FirmMembersTableManager(
      $_db,
      $_db.firmMembers,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_firmMembersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Items, List<ItemRow>> _itemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.items,
    aliasName: 'users__id__items__created_by_user_id',
  );

  $ItemsProcessedTableManager get itemsRefs {
    final manager = $ItemsTableManager($_db, $_db.items).filter(
      (f) => f.createdByUserId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Customers, List<CustomerRow>> _customersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.customers,
    aliasName: 'users__id__customers__created_by_user_id',
  );

  $CustomersProcessedTableManager get customersRefs {
    final manager = $CustomersTableManager($_db, $_db.customers).filter(
      (f) => f.createdByUserId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_customersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $UsersFilterComposer extends Composer<_$AppDatabase, Users> {
  $UsersFilterComposer({
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

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> firmMembersRefs(
    Expression<bool> Function($FirmMembersFilterComposer f) f,
  ) {
    final $FirmMembersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.firmMembers,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmMembersFilterComposer(
            $db: $db,
            $table: $db.firmMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> itemsRefs(
    Expression<bool> Function($ItemsFilterComposer f) f,
  ) {
    final $ItemsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.createdByUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ItemsFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> customersRefs(
    Expression<bool> Function($CustomersFilterComposer f) f,
  ) {
    final $CustomersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.createdByUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomersFilterComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $UsersOrderingComposer extends Composer<_$AppDatabase, Users> {
  $UsersOrderingComposer({
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

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $UsersAnnotationComposer extends Composer<_$AppDatabase, Users> {
  $UsersAnnotationComposer({
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

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> firmMembersRefs<T extends Object>(
    Expression<T> Function($FirmMembersAnnotationComposer a) f,
  ) {
    final $FirmMembersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.firmMembers,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmMembersAnnotationComposer(
            $db: $db,
            $table: $db.firmMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> itemsRefs<T extends Object>(
    Expression<T> Function($ItemsAnnotationComposer a) f,
  ) {
    final $ItemsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.createdByUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ItemsAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> customersRefs<T extends Object>(
    Expression<T> Function($CustomersAnnotationComposer a) f,
  ) {
    final $CustomersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.createdByUserId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomersAnnotationComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $UsersTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Users,
          UserRow,
          $UsersFilterComposer,
          $UsersOrderingComposer,
          $UsersAnnotationComposer,
          $UsersCreateCompanionBuilder,
          $UsersUpdateCompanionBuilder,
          (UserRow, $UsersReferences),
          UserRow,
          PrefetchHooks Function({
            bool firmMembersRefs,
            bool itemsRefs,
            bool customersRefs,
          })
        > {
  $UsersTableManager(_$AppDatabase db, Users table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $UsersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $UsersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $UsersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedByDeviceId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                name: name,
                email: email,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedByDeviceId: updatedByDeviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> email = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                required String updatedByDeviceId,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                name: name,
                email: email,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedByDeviceId: updatedByDeviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Users, UserRow>(table),
                  $UsersReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                firmMembersRefs = false,
                itemsRefs = false,
                customersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (firmMembersRefs) db.firmMembers,
                    if (itemsRefs) db.items,
                    if (customersRefs) db.customers,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (firmMembersRefs)
                        await $_getPrefetchedData<
                          UserRow,
                          Users,
                          FirmMemberRow
                        >(
                          currentTable: table,
                          referencedTable: $UsersReferences
                              ._firmMembersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $UsersReferences(db, table, p0).firmMembersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (itemsRefs)
                        await $_getPrefetchedData<UserRow, Users, ItemRow>(
                          currentTable: table,
                          referencedTable: $UsersReferences._itemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $UsersReferences(db, table, p0).itemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.createdByUserId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (customersRefs)
                        await $_getPrefetchedData<UserRow, Users, CustomerRow>(
                          currentTable: table,
                          referencedTable: $UsersReferences._customersRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $UsersReferences(db, table, p0).customersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.createdByUserId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $UsersProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Users,
      UserRow,
      $UsersFilterComposer,
      $UsersOrderingComposer,
      $UsersAnnotationComposer,
      $UsersCreateCompanionBuilder,
      $UsersUpdateCompanionBuilder,
      (UserRow, $UsersReferences),
      UserRow,
      PrefetchHooks Function({
        bool firmMembersRefs,
        bool itemsRefs,
        bool customersRefs,
      })
    >;
typedef $FirmMembersCreateCompanionBuilder = FirmMembersCompanion Function({
  required String id,
  required String firmId,
  required String userId,
  required String role,
  required int createdAt,
  required int updatedAt,
  required String updatedByDeviceId,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $FirmMembersUpdateCompanionBuilder = FirmMembersCompanion Function({
  Value<String> id,
  Value<String> firmId,
  Value<String> userId,
  Value<String> role,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> updatedByDeviceId,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $FirmMembersReferences
    extends BaseReferences<_$AppDatabase, FirmMembers, FirmMemberRow> {
  $FirmMembersReferences(super.$_db, super.$_table, super.$_typedResult);

  static Firms _firmIdTable(_$AppDatabase db) =>
      db.firms.createAlias('firm_members__firm_id__firms__id');

  $FirmsProcessedTableManager get firmId {
    final $_column = $_itemColumn<String>('firm_id')!;

    final manager = $FirmsTableManager(
      $_db,
      $_db.firms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_firmIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _userIdTable(_$AppDatabase db) =>
      db.users.createAlias('firm_members__user_id__users__id');

  $UsersProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $FirmMembersFilterComposer extends Composer<_$AppDatabase, FirmMembers> {
  $FirmMembersFilterComposer({
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

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $FirmsFilterComposer get firmId {
    final $FirmsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsFilterComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get userId {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $FirmMembersOrderingComposer
    extends Composer<_$AppDatabase, FirmMembers> {
  $FirmMembersOrderingComposer({
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

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $FirmsOrderingComposer get firmId {
    final $FirmsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsOrderingComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get userId {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $FirmMembersAnnotationComposer
    extends Composer<_$AppDatabase, FirmMembers> {
  $FirmMembersAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $FirmsAnnotationComposer get firmId {
    final $FirmsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsAnnotationComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get userId {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $FirmMembersTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          FirmMembers,
          FirmMemberRow,
          $FirmMembersFilterComposer,
          $FirmMembersOrderingComposer,
          $FirmMembersAnnotationComposer,
          $FirmMembersCreateCompanionBuilder,
          $FirmMembersUpdateCompanionBuilder,
          (FirmMemberRow, $FirmMembersReferences),
          FirmMemberRow,
          PrefetchHooks Function({bool firmId, bool userId})
        > {
  $FirmMembersTableManager(_$AppDatabase db, FirmMembers table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $FirmMembersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $FirmMembersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $FirmMembersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> firmId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedByDeviceId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FirmMembersCompanion(
                id: id,
                firmId: firmId,
                userId: userId,
                role: role,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedByDeviceId: updatedByDeviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String firmId,
                required String userId,
                required String role,
                required int createdAt,
                required int updatedAt,
                required String updatedByDeviceId,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FirmMembersCompanion.insert(
                id: id,
                firmId: firmId,
                userId: userId,
                role: role,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedByDeviceId: updatedByDeviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<FirmMembers, FirmMemberRow>(table),
                  $FirmMembersReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({firmId = false, userId = false}) {
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
                    if (firmId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.firmId,
                        referencedTable: $FirmMembersReferences._firmIdTable(
                          db,
                        ),
                        referencedColumn: $FirmMembersReferences
                            ._firmIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (userId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.userId,
                        referencedTable: $FirmMembersReferences._userIdTable(
                          db,
                        ),
                        referencedColumn: $FirmMembersReferences
                            ._userIdTable(db)
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

typedef $FirmMembersProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      FirmMembers,
      FirmMemberRow,
      $FirmMembersFilterComposer,
      $FirmMembersOrderingComposer,
      $FirmMembersAnnotationComposer,
      $FirmMembersCreateCompanionBuilder,
      $FirmMembersUpdateCompanionBuilder,
      (FirmMemberRow, $FirmMembersReferences),
      FirmMemberRow,
      PrefetchHooks Function({bool firmId, bool userId})
    >;
typedef $DevicesCreateCompanionBuilder = DevicesCompanion Function({
  required String id,
  required String firmId,
  required String name,
  required String platform,
  required String shortCode,
  required int createdAt,
  required int updatedAt,
  required String updatedByDeviceId,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $DevicesUpdateCompanionBuilder = DevicesCompanion Function({
  Value<String> id,
  Value<String> firmId,
  Value<String> name,
  Value<String> platform,
  Value<String> shortCode,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> updatedByDeviceId,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $DevicesReferences
    extends BaseReferences<_$AppDatabase, Devices, DeviceRow> {
  $DevicesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Firms _firmIdTable(_$AppDatabase db) =>
      db.firms.createAlias('devices__firm_id__firms__id');

  $FirmsProcessedTableManager get firmId {
    final $_column = $_itemColumn<String>('firm_id')!;

    final manager = $FirmsTableManager(
      $_db,
      $_db.firms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_firmIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $DevicesFilterComposer extends Composer<_$AppDatabase, Devices> {
  $DevicesFilterComposer({
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

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shortCode => $composableBuilder(
    column: $table.shortCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $FirmsFilterComposer get firmId {
    final $FirmsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsFilterComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DevicesOrderingComposer extends Composer<_$AppDatabase, Devices> {
  $DevicesOrderingComposer({
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

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shortCode => $composableBuilder(
    column: $table.shortCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $FirmsOrderingComposer get firmId {
    final $FirmsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsOrderingComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DevicesAnnotationComposer extends Composer<_$AppDatabase, Devices> {
  $DevicesAnnotationComposer({
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

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get shortCode =>
      $composableBuilder(column: $table.shortCode, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $FirmsAnnotationComposer get firmId {
    final $FirmsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsAnnotationComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DevicesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Devices,
          DeviceRow,
          $DevicesFilterComposer,
          $DevicesOrderingComposer,
          $DevicesAnnotationComposer,
          $DevicesCreateCompanionBuilder,
          $DevicesUpdateCompanionBuilder,
          (DeviceRow, $DevicesReferences),
          DeviceRow,
          PrefetchHooks Function({bool firmId})
        > {
  $DevicesTableManager(_$AppDatabase db, Devices table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DevicesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DevicesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DevicesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> firmId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<String> shortCode = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedByDeviceId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion(
                id: id,
                firmId: firmId,
                name: name,
                platform: platform,
                shortCode: shortCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedByDeviceId: updatedByDeviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String firmId,
                required String name,
                required String platform,
                required String shortCode,
                required int createdAt,
                required int updatedAt,
                required String updatedByDeviceId,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion.insert(
                id: id,
                firmId: firmId,
                name: name,
                platform: platform,
                shortCode: shortCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedByDeviceId: updatedByDeviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Devices, DeviceRow>(table),
                  $DevicesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({firmId = false}) {
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
                    if (firmId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.firmId,
                        referencedTable: $DevicesReferences._firmIdTable(db),
                        referencedColumn: $DevicesReferences
                            ._firmIdTable(db)
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

typedef $DevicesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Devices,
      DeviceRow,
      $DevicesFilterComposer,
      $DevicesOrderingComposer,
      $DevicesAnnotationComposer,
      $DevicesCreateCompanionBuilder,
      $DevicesUpdateCompanionBuilder,
      (DeviceRow, $DevicesReferences),
      DeviceRow,
      PrefetchHooks Function({bool firmId})
    >;
typedef $ItemsCreateCompanionBuilder = ItemsCompanion Function({
  required String id,
  required String firmId,
  required String name,
  required String nameNormalized,
  Value<int?> defaultBagWeightG,
  Value<int?> defaultRateBaseWeightG,
  Value<String> defaultUom,
  Value<bool> trackStock,
  required String createdByUserId,
  required int createdAt,
  required int updatedAt,
  required String updatedByDeviceId,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $ItemsUpdateCompanionBuilder = ItemsCompanion Function({
  Value<String> id,
  Value<String> firmId,
  Value<String> name,
  Value<String> nameNormalized,
  Value<int?> defaultBagWeightG,
  Value<int?> defaultRateBaseWeightG,
  Value<String> defaultUom,
  Value<bool> trackStock,
  Value<String> createdByUserId,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> updatedByDeviceId,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $ItemsReferences
    extends BaseReferences<_$AppDatabase, Items, ItemRow> {
  $ItemsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Firms _firmIdTable(_$AppDatabase db) =>
      db.firms.createAlias('items__firm_id__firms__id');

  $FirmsProcessedTableManager get firmId {
    final $_column = $_itemColumn<String>('firm_id')!;

    final manager = $FirmsTableManager(
      $_db,
      $_db.firms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_firmIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _createdByUserIdTable(_$AppDatabase db) =>
      db.users.createAlias('items__created_by_user_id__users__id');

  $UsersProcessedTableManager get createdByUserId {
    final $_column = $_itemColumn<String>('created_by_user_id')!;

    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ItemsFilterComposer extends Composer<_$AppDatabase, Items> {
  $ItemsFilterComposer({
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

  ColumnFilters<String> get nameNormalized => $composableBuilder(
    column: $table.nameNormalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultBagWeightG => $composableBuilder(
    column: $table.defaultBagWeightG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultRateBaseWeightG => $composableBuilder(
    column: $table.defaultRateBaseWeightG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultUom => $composableBuilder(
    column: $table.defaultUom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trackStock => $composableBuilder(
    column: $table.trackStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $FirmsFilterComposer get firmId {
    final $FirmsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsFilterComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get createdByUserId {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ItemsOrderingComposer extends Composer<_$AppDatabase, Items> {
  $ItemsOrderingComposer({
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

  ColumnOrderings<String> get nameNormalized => $composableBuilder(
    column: $table.nameNormalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultBagWeightG => $composableBuilder(
    column: $table.defaultBagWeightG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultRateBaseWeightG => $composableBuilder(
    column: $table.defaultRateBaseWeightG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultUom => $composableBuilder(
    column: $table.defaultUom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trackStock => $composableBuilder(
    column: $table.trackStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $FirmsOrderingComposer get firmId {
    final $FirmsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsOrderingComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get createdByUserId {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ItemsAnnotationComposer extends Composer<_$AppDatabase, Items> {
  $ItemsAnnotationComposer({
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

  GeneratedColumn<String> get nameNormalized => $composableBuilder(
    column: $table.nameNormalized,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultBagWeightG => $composableBuilder(
    column: $table.defaultBagWeightG,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultRateBaseWeightG => $composableBuilder(
    column: $table.defaultRateBaseWeightG,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultUom => $composableBuilder(
    column: $table.defaultUom,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get trackStock => $composableBuilder(
    column: $table.trackStock,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $FirmsAnnotationComposer get firmId {
    final $FirmsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsAnnotationComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get createdByUserId {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ItemsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Items,
          ItemRow,
          $ItemsFilterComposer,
          $ItemsOrderingComposer,
          $ItemsAnnotationComposer,
          $ItemsCreateCompanionBuilder,
          $ItemsUpdateCompanionBuilder,
          (ItemRow, $ItemsReferences),
          ItemRow,
          PrefetchHooks Function({bool firmId, bool createdByUserId})
        > {
  $ItemsTableManager(_$AppDatabase db, Items table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ItemsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ItemsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ItemsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> firmId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameNormalized = const Value.absent(),
                Value<int?> defaultBagWeightG = const Value.absent(),
                Value<int?> defaultRateBaseWeightG = const Value.absent(),
                Value<String> defaultUom = const Value.absent(),
                Value<bool> trackStock = const Value.absent(),
                Value<String> createdByUserId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedByDeviceId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                firmId: firmId,
                name: name,
                nameNormalized: nameNormalized,
                defaultBagWeightG: defaultBagWeightG,
                defaultRateBaseWeightG: defaultRateBaseWeightG,
                defaultUom: defaultUom,
                trackStock: trackStock,
                createdByUserId: createdByUserId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedByDeviceId: updatedByDeviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String firmId,
                required String name,
                required String nameNormalized,
                Value<int?> defaultBagWeightG = const Value.absent(),
                Value<int?> defaultRateBaseWeightG = const Value.absent(),
                Value<String> defaultUom = const Value.absent(),
                Value<bool> trackStock = const Value.absent(),
                required String createdByUserId,
                required int createdAt,
                required int updatedAt,
                required String updatedByDeviceId,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                id: id,
                firmId: firmId,
                name: name,
                nameNormalized: nameNormalized,
                defaultBagWeightG: defaultBagWeightG,
                defaultRateBaseWeightG: defaultRateBaseWeightG,
                defaultUom: defaultUom,
                trackStock: trackStock,
                createdByUserId: createdByUserId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedByDeviceId: updatedByDeviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Items, ItemRow>(table),
                  $ItemsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({firmId = false, createdByUserId = false}) {
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
                    if (firmId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.firmId,
                        referencedTable: $ItemsReferences._firmIdTable(db),
                        referencedColumn: $ItemsReferences._firmIdTable(db).id,
                      ) as T;
                    }
                    if (createdByUserId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.createdByUserId,
                        referencedTable: $ItemsReferences._createdByUserIdTable(
                          db,
                        ),
                        referencedColumn: $ItemsReferences
                            ._createdByUserIdTable(db)
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

typedef $ItemsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Items,
      ItemRow,
      $ItemsFilterComposer,
      $ItemsOrderingComposer,
      $ItemsAnnotationComposer,
      $ItemsCreateCompanionBuilder,
      $ItemsUpdateCompanionBuilder,
      (ItemRow, $ItemsReferences),
      ItemRow,
      PrefetchHooks Function({bool firmId, bool createdByUserId})
    >;
typedef $CustomersCreateCompanionBuilder = CustomersCompanion Function({
  required String id,
  required String firmId,
  required String name,
  required String nameNormalized,
  Value<String?> phone,
  Value<String?> phoneNormalized,
  Value<String?> notes,
  required String createdByUserId,
  Value<String?> mergedIntoId,
  Value<bool> needsReview,
  required int createdAt,
  required int updatedAt,
  required String updatedByDeviceId,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $CustomersUpdateCompanionBuilder = CustomersCompanion Function({
  Value<String> id,
  Value<String> firmId,
  Value<String> name,
  Value<String> nameNormalized,
  Value<String?> phone,
  Value<String?> phoneNormalized,
  Value<String?> notes,
  Value<String> createdByUserId,
  Value<String?> mergedIntoId,
  Value<bool> needsReview,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> updatedByDeviceId,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $CustomersReferences
    extends BaseReferences<_$AppDatabase, Customers, CustomerRow> {
  $CustomersReferences(super.$_db, super.$_table, super.$_typedResult);

  static Firms _firmIdTable(_$AppDatabase db) =>
      db.firms.createAlias('customers__firm_id__firms__id');

  $FirmsProcessedTableManager get firmId {
    final $_column = $_itemColumn<String>('firm_id')!;

    final manager = $FirmsTableManager(
      $_db,
      $_db.firms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_firmIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _createdByUserIdTable(_$AppDatabase db) =>
      db.users.createAlias('customers__created_by_user_id__users__id');

  $UsersProcessedTableManager get createdByUserId {
    final $_column = $_itemColumn<String>('created_by_user_id')!;

    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Customers _mergedIntoIdTable(_$AppDatabase db) =>
      db.customers.createAlias('customers__merged_into_id__customers__id');

  $CustomersProcessedTableManager? get mergedIntoId {
    final $_column = $_itemColumn<String>('merged_into_id');
    if ($_column == null) return null;
    final manager = $CustomersTableManager(
      $_db,
      $_db.customers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mergedIntoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $CustomersFilterComposer extends Composer<_$AppDatabase, Customers> {
  $CustomersFilterComposer({
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

  ColumnFilters<String> get nameNormalized => $composableBuilder(
    column: $table.nameNormalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNormalized => $composableBuilder(
    column: $table.phoneNormalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $FirmsFilterComposer get firmId {
    final $FirmsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsFilterComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get createdByUserId {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CustomersFilterComposer get mergedIntoId {
    final $CustomersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mergedIntoId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomersFilterComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CustomersOrderingComposer extends Composer<_$AppDatabase, Customers> {
  $CustomersOrderingComposer({
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

  ColumnOrderings<String> get nameNormalized => $composableBuilder(
    column: $table.nameNormalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNormalized => $composableBuilder(
    column: $table.phoneNormalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $FirmsOrderingComposer get firmId {
    final $FirmsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsOrderingComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get createdByUserId {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CustomersOrderingComposer get mergedIntoId {
    final $CustomersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mergedIntoId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomersOrderingComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CustomersAnnotationComposer extends Composer<_$AppDatabase, Customers> {
  $CustomersAnnotationComposer({
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

  GeneratedColumn<String> get nameNormalized => $composableBuilder(
    column: $table.nameNormalized,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get phoneNormalized => $composableBuilder(
    column: $table.phoneNormalized,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $FirmsAnnotationComposer get firmId {
    final $FirmsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsAnnotationComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get createdByUserId {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CustomersAnnotationComposer get mergedIntoId {
    final $CustomersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mergedIntoId,
      referencedTable: $db.customers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomersAnnotationComposer(
            $db: $db,
            $table: $db.customers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CustomersTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Customers,
          CustomerRow,
          $CustomersFilterComposer,
          $CustomersOrderingComposer,
          $CustomersAnnotationComposer,
          $CustomersCreateCompanionBuilder,
          $CustomersUpdateCompanionBuilder,
          (CustomerRow, $CustomersReferences),
          CustomerRow,
          PrefetchHooks Function({
            bool firmId,
            bool createdByUserId,
            bool mergedIntoId,
          })
        > {
  $CustomersTableManager(_$AppDatabase db, Customers table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CustomersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CustomersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CustomersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> firmId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameNormalized = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> phoneNormalized = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> createdByUserId = const Value.absent(),
                Value<String?> mergedIntoId = const Value.absent(),
                Value<bool> needsReview = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedByDeviceId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion(
                id: id,
                firmId: firmId,
                name: name,
                nameNormalized: nameNormalized,
                phone: phone,
                phoneNormalized: phoneNormalized,
                notes: notes,
                createdByUserId: createdByUserId,
                mergedIntoId: mergedIntoId,
                needsReview: needsReview,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedByDeviceId: updatedByDeviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String firmId,
                required String name,
                required String nameNormalized,
                Value<String?> phone = const Value.absent(),
                Value<String?> phoneNormalized = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required String createdByUserId,
                Value<String?> mergedIntoId = const Value.absent(),
                Value<bool> needsReview = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                required String updatedByDeviceId,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion.insert(
                id: id,
                firmId: firmId,
                name: name,
                nameNormalized: nameNormalized,
                phone: phone,
                phoneNormalized: phoneNormalized,
                notes: notes,
                createdByUserId: createdByUserId,
                mergedIntoId: mergedIntoId,
                needsReview: needsReview,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedByDeviceId: updatedByDeviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Customers, CustomerRow>(table),
                  $CustomersReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                firmId = false,
                createdByUserId = false,
                mergedIntoId = false,
              }) {
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
                        if (firmId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.firmId,
                            referencedTable: $CustomersReferences._firmIdTable(
                              db,
                            ),
                            referencedColumn: $CustomersReferences
                                ._firmIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (createdByUserId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.createdByUserId,
                            referencedTable: $CustomersReferences
                                ._createdByUserIdTable(db),
                            referencedColumn: $CustomersReferences
                                ._createdByUserIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (mergedIntoId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.mergedIntoId,
                            referencedTable: $CustomersReferences
                                ._mergedIntoIdTable(db),
                            referencedColumn: $CustomersReferences
                                ._mergedIntoIdTable(db)
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

typedef $CustomersProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Customers,
      CustomerRow,
      $CustomersFilterComposer,
      $CustomersOrderingComposer,
      $CustomersAnnotationComposer,
      $CustomersCreateCompanionBuilder,
      $CustomersUpdateCompanionBuilder,
      (CustomerRow, $CustomersReferences),
      CustomerRow,
      PrefetchHooks Function({
        bool firmId,
        bool createdByUserId,
        bool mergedIntoId,
      })
    >;
typedef $TransactionsCreateCompanionBuilder = TransactionsCompanion Function({
  required String id,
  required String firmId,
  Value<String?> customerId,
  required String deviceShortCode,
  required int displaySeq,
  required String type,
  required String entryDate,
  Value<String?> description,
  Value<int> version,
  required int calculatedTotal,
  Value<int?> overriddenTotal,
  Value<int?> overriddenTotalBasis,
  required int finalAmount,
  required String createdByUserId,
  required String updatedByUserId,
  required int createdAt,
  required int updatedAt,
  required String updatedByDeviceId,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $TransactionsUpdateCompanionBuilder = TransactionsCompanion Function({
  Value<String> id,
  Value<String> firmId,
  Value<String?> customerId,
  Value<String> deviceShortCode,
  Value<int> displaySeq,
  Value<String> type,
  Value<String> entryDate,
  Value<String?> description,
  Value<int> version,
  Value<int> calculatedTotal,
  Value<int?> overriddenTotal,
  Value<int?> overriddenTotalBasis,
  Value<int> finalAmount,
  Value<String> createdByUserId,
  Value<String> updatedByUserId,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<String> updatedByDeviceId,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $TransactionsReferences
    extends BaseReferences<_$AppDatabase, Transactions, TransactionRow> {
  $TransactionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Firms _firmIdTable(_$AppDatabase db) =>
      db.firms.createAlias('transactions__firm_id__firms__id');

  $FirmsProcessedTableManager get firmId {
    final $_column = $_itemColumn<String>('firm_id')!;

    final manager = $FirmsTableManager(
      $_db,
      $_db.firms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_firmIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _createdByUserIdTable(_$AppDatabase db) =>
      db.users.createAlias('transactions__created_by_user_id__users__id');

  $UsersProcessedTableManager get createdByUserId {
    final $_column = $_itemColumn<String>('created_by_user_id')!;

    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _updatedByUserIdTable(_$AppDatabase db) =>
      db.users.createAlias('transactions__updated_by_user_id__users__id');

  $UsersProcessedTableManager get updatedByUserId {
    final $_column = $_itemColumn<String>('updated_by_user_id')!;

    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_updatedByUserIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $TransactionsFilterComposer
    extends Composer<_$AppDatabase, Transactions> {
  $TransactionsFilterComposer({
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

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceShortCode => $composableBuilder(
    column: $table.deviceShortCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displaySeq => $composableBuilder(
    column: $table.displaySeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calculatedTotal => $composableBuilder(
    column: $table.calculatedTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overriddenTotal => $composableBuilder(
    column: $table.overriddenTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overriddenTotalBasis => $composableBuilder(
    column: $table.overriddenTotalBasis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finalAmount => $composableBuilder(
    column: $table.finalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get signedAmount => $composableBuilder(
    column: $table.signedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $FirmsFilterComposer get firmId {
    final $FirmsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsFilterComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get createdByUserId {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get updatedByUserId {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.updatedByUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TransactionsOrderingComposer
    extends Composer<_$AppDatabase, Transactions> {
  $TransactionsOrderingComposer({
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

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceShortCode => $composableBuilder(
    column: $table.deviceShortCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displaySeq => $composableBuilder(
    column: $table.displaySeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calculatedTotal => $composableBuilder(
    column: $table.calculatedTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overriddenTotal => $composableBuilder(
    column: $table.overriddenTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overriddenTotalBasis => $composableBuilder(
    column: $table.overriddenTotalBasis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finalAmount => $composableBuilder(
    column: $table.finalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get signedAmount => $composableBuilder(
    column: $table.signedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $FirmsOrderingComposer get firmId {
    final $FirmsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsOrderingComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get createdByUserId {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get updatedByUserId {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.updatedByUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TransactionsAnnotationComposer
    extends Composer<_$AppDatabase, Transactions> {
  $TransactionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceShortCode => $composableBuilder(
    column: $table.deviceShortCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displaySeq => $composableBuilder(
    column: $table.displaySeq,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get entryDate =>
      $composableBuilder(column: $table.entryDate, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get calculatedTotal => $composableBuilder(
    column: $table.calculatedTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overriddenTotal => $composableBuilder(
    column: $table.overriddenTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overriddenTotalBasis => $composableBuilder(
    column: $table.overriddenTotalBasis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get finalAmount => $composableBuilder(
    column: $table.finalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get signedAmount => $composableBuilder(
    column: $table.signedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedByDeviceId => $composableBuilder(
    column: $table.updatedByDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $FirmsAnnotationComposer get firmId {
    final $FirmsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.firmId,
      referencedTable: $db.firms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $FirmsAnnotationComposer(
            $db: $db,
            $table: $db.firms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get createdByUserId {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get updatedByUserId {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.updatedByUserId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TransactionsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Transactions,
          TransactionRow,
          $TransactionsFilterComposer,
          $TransactionsOrderingComposer,
          $TransactionsAnnotationComposer,
          $TransactionsCreateCompanionBuilder,
          $TransactionsUpdateCompanionBuilder,
          (TransactionRow, $TransactionsReferences),
          TransactionRow,
          PrefetchHooks Function({
            bool firmId,
            bool createdByUserId,
            bool updatedByUserId,
          })
        > {
  $TransactionsTableManager(_$AppDatabase db, Transactions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TransactionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TransactionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TransactionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> firmId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String> deviceShortCode = const Value.absent(),
                Value<int> displaySeq = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> entryDate = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> calculatedTotal = const Value.absent(),
                Value<int?> overriddenTotal = const Value.absent(),
                Value<int?> overriddenTotalBasis = const Value.absent(),
                Value<int> finalAmount = const Value.absent(),
                Value<String> createdByUserId = const Value.absent(),
                Value<String> updatedByUserId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedByDeviceId = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                firmId: firmId,
                customerId: customerId,
                deviceShortCode: deviceShortCode,
                displaySeq: displaySeq,
                type: type,
                entryDate: entryDate,
                description: description,
                version: version,
                calculatedTotal: calculatedTotal,
                overriddenTotal: overriddenTotal,
                overriddenTotalBasis: overriddenTotalBasis,
                finalAmount: finalAmount,
                createdByUserId: createdByUserId,
                updatedByUserId: updatedByUserId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedByDeviceId: updatedByDeviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String firmId,
                Value<String?> customerId = const Value.absent(),
                required String deviceShortCode,
                required int displaySeq,
                required String type,
                required String entryDate,
                Value<String?> description = const Value.absent(),
                Value<int> version = const Value.absent(),
                required int calculatedTotal,
                Value<int?> overriddenTotal = const Value.absent(),
                Value<int?> overriddenTotalBasis = const Value.absent(),
                required int finalAmount,
                required String createdByUserId,
                required String updatedByUserId,
                required int createdAt,
                required int updatedAt,
                required String updatedByDeviceId,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                firmId: firmId,
                customerId: customerId,
                deviceShortCode: deviceShortCode,
                displaySeq: displaySeq,
                type: type,
                entryDate: entryDate,
                description: description,
                version: version,
                calculatedTotal: calculatedTotal,
                overriddenTotal: overriddenTotal,
                overriddenTotalBasis: overriddenTotalBasis,
                finalAmount: finalAmount,
                createdByUserId: createdByUserId,
                updatedByUserId: updatedByUserId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                updatedByDeviceId: updatedByDeviceId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Transactions, TransactionRow>(table),
                  $TransactionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                firmId = false,
                createdByUserId = false,
                updatedByUserId = false,
              }) {
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
                        if (firmId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.firmId,
                            referencedTable: $TransactionsReferences
                                ._firmIdTable(db),
                            referencedColumn: $TransactionsReferences
                                ._firmIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (createdByUserId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.createdByUserId,
                            referencedTable: $TransactionsReferences
                                ._createdByUserIdTable(db),
                            referencedColumn: $TransactionsReferences
                                ._createdByUserIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (updatedByUserId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.updatedByUserId,
                            referencedTable: $TransactionsReferences
                                ._updatedByUserIdTable(db),
                            referencedColumn: $TransactionsReferences
                                ._updatedByUserIdTable(db)
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

typedef $TransactionsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Transactions,
      TransactionRow,
      $TransactionsFilterComposer,
      $TransactionsOrderingComposer,
      $TransactionsAnnotationComposer,
      $TransactionsCreateCompanionBuilder,
      $TransactionsUpdateCompanionBuilder,
      (TransactionRow, $TransactionsReferences),
      TransactionRow,
      PrefetchHooks Function({
        bool firmId,
        bool createdByUserId,
        bool updatedByUserId,
      })
    >;
typedef $TransactionLinesCreateCompanionBuilder =
    TransactionLinesCompanion Function({
      required String id,
      required String firmId,
      required String transactionId,
      required int lineNo,
      required String itemId,
      Value<String> uom,
      required String saleMode,
      Value<int?> bagCount,
      Value<int?> bagWeightG,
      Value<int?> totalWeightG,
      Value<int?> quantity,
      required int ratePaisa,
      Value<int?> rateBaseWeightG,
      Value<int?> overriddenTotal,
      Value<int> rowid,
    });
typedef $TransactionLinesUpdateCompanionBuilder =
    TransactionLinesCompanion Function({
      Value<String> id,
      Value<String> firmId,
      Value<String> transactionId,
      Value<int> lineNo,
      Value<String> itemId,
      Value<String> uom,
      Value<String> saleMode,
      Value<int?> bagCount,
      Value<int?> bagWeightG,
      Value<int?> totalWeightG,
      Value<int?> quantity,
      Value<int> ratePaisa,
      Value<int?> rateBaseWeightG,
      Value<int?> overriddenTotal,
      Value<int> rowid,
    });

class $TransactionLinesFilterComposer
    extends Composer<_$AppDatabase, TransactionLines> {
  $TransactionLinesFilterComposer({
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

  ColumnFilters<String> get firmId => $composableBuilder(
    column: $table.firmId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineNo => $composableBuilder(
    column: $table.lineNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uom => $composableBuilder(
    column: $table.uom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleMode => $composableBuilder(
    column: $table.saleMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bagCount => $composableBuilder(
    column: $table.bagCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bagWeightG => $composableBuilder(
    column: $table.bagWeightG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalWeightG => $composableBuilder(
    column: $table.totalWeightG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ratePaisa => $composableBuilder(
    column: $table.ratePaisa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateBaseWeightG => $composableBuilder(
    column: $table.rateBaseWeightG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overriddenTotal => $composableBuilder(
    column: $table.overriddenTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calculatedTotal => $composableBuilder(
    column: $table.calculatedTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finalAmount => $composableBuilder(
    column: $table.finalAmount,
    builder: (column) => ColumnFilters(column),
  );
}

class $TransactionLinesOrderingComposer
    extends Composer<_$AppDatabase, TransactionLines> {
  $TransactionLinesOrderingComposer({
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

  ColumnOrderings<String> get firmId => $composableBuilder(
    column: $table.firmId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineNo => $composableBuilder(
    column: $table.lineNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uom => $composableBuilder(
    column: $table.uom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleMode => $composableBuilder(
    column: $table.saleMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bagCount => $composableBuilder(
    column: $table.bagCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bagWeightG => $composableBuilder(
    column: $table.bagWeightG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalWeightG => $composableBuilder(
    column: $table.totalWeightG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ratePaisa => $composableBuilder(
    column: $table.ratePaisa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateBaseWeightG => $composableBuilder(
    column: $table.rateBaseWeightG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overriddenTotal => $composableBuilder(
    column: $table.overriddenTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calculatedTotal => $composableBuilder(
    column: $table.calculatedTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finalAmount => $composableBuilder(
    column: $table.finalAmount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $TransactionLinesAnnotationComposer
    extends Composer<_$AppDatabase, TransactionLines> {
  $TransactionLinesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firmId =>
      $composableBuilder(column: $table.firmId, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lineNo =>
      $composableBuilder(column: $table.lineNo, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get uom =>
      $composableBuilder(column: $table.uom, builder: (column) => column);

  GeneratedColumn<String> get saleMode =>
      $composableBuilder(column: $table.saleMode, builder: (column) => column);

  GeneratedColumn<int> get bagCount =>
      $composableBuilder(column: $table.bagCount, builder: (column) => column);

  GeneratedColumn<int> get bagWeightG => $composableBuilder(
    column: $table.bagWeightG,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalWeightG => $composableBuilder(
    column: $table.totalWeightG,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get ratePaisa =>
      $composableBuilder(column: $table.ratePaisa, builder: (column) => column);

  GeneratedColumn<int> get rateBaseWeightG => $composableBuilder(
    column: $table.rateBaseWeightG,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overriddenTotal => $composableBuilder(
    column: $table.overriddenTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get calculatedTotal => $composableBuilder(
    column: $table.calculatedTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get finalAmount => $composableBuilder(
    column: $table.finalAmount,
    builder: (column) => column,
  );
}

class $TransactionLinesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          TransactionLines,
          TransactionLineRow,
          $TransactionLinesFilterComposer,
          $TransactionLinesOrderingComposer,
          $TransactionLinesAnnotationComposer,
          $TransactionLinesCreateCompanionBuilder,
          $TransactionLinesUpdateCompanionBuilder,
          (
            TransactionLineRow,
            BaseReferences<_$AppDatabase, TransactionLines, TransactionLineRow>,
          ),
          TransactionLineRow,
          PrefetchHooks Function()
        > {
  $TransactionLinesTableManager(_$AppDatabase db, TransactionLines table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TransactionLinesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TransactionLinesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TransactionLinesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> firmId = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<int> lineNo = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> uom = const Value.absent(),
                Value<String> saleMode = const Value.absent(),
                Value<int?> bagCount = const Value.absent(),
                Value<int?> bagWeightG = const Value.absent(),
                Value<int?> totalWeightG = const Value.absent(),
                Value<int?> quantity = const Value.absent(),
                Value<int> ratePaisa = const Value.absent(),
                Value<int?> rateBaseWeightG = const Value.absent(),
                Value<int?> overriddenTotal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionLinesCompanion(
                id: id,
                firmId: firmId,
                transactionId: transactionId,
                lineNo: lineNo,
                itemId: itemId,
                uom: uom,
                saleMode: saleMode,
                bagCount: bagCount,
                bagWeightG: bagWeightG,
                totalWeightG: totalWeightG,
                quantity: quantity,
                ratePaisa: ratePaisa,
                rateBaseWeightG: rateBaseWeightG,
                overriddenTotal: overriddenTotal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String firmId,
                required String transactionId,
                required int lineNo,
                required String itemId,
                Value<String> uom = const Value.absent(),
                required String saleMode,
                Value<int?> bagCount = const Value.absent(),
                Value<int?> bagWeightG = const Value.absent(),
                Value<int?> totalWeightG = const Value.absent(),
                Value<int?> quantity = const Value.absent(),
                required int ratePaisa,
                Value<int?> rateBaseWeightG = const Value.absent(),
                Value<int?> overriddenTotal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionLinesCompanion.insert(
                id: id,
                firmId: firmId,
                transactionId: transactionId,
                lineNo: lineNo,
                itemId: itemId,
                uom: uom,
                saleMode: saleMode,
                bagCount: bagCount,
                bagWeightG: bagWeightG,
                totalWeightG: totalWeightG,
                quantity: quantity,
                ratePaisa: ratePaisa,
                rateBaseWeightG: rateBaseWeightG,
                overriddenTotal: overriddenTotal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<TransactionLines, TransactionLineRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    TransactionLines,
                    TransactionLineRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $TransactionLinesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      TransactionLines,
      TransactionLineRow,
      $TransactionLinesFilterComposer,
      $TransactionLinesOrderingComposer,
      $TransactionLinesAnnotationComposer,
      $TransactionLinesCreateCompanionBuilder,
      $TransactionLinesUpdateCompanionBuilder,
      (
        TransactionLineRow,
        BaseReferences<_$AppDatabase, TransactionLines, TransactionLineRow>,
      ),
      TransactionLineRow,
      PrefetchHooks Function()
    >;
typedef $TransactionHistoryCreateCompanionBuilder =
    TransactionHistoryCompanion Function({
      required String id,
      required String firmId,
      required String transactionId,
      required int version,
      required String snapshot,
      required String reason,
      required int changedAt,
      required String changedByUserId,
      required String changedByDeviceId,
      Value<int> rowid,
    });
typedef $TransactionHistoryUpdateCompanionBuilder =
    TransactionHistoryCompanion Function({
      Value<String> id,
      Value<String> firmId,
      Value<String> transactionId,
      Value<int> version,
      Value<String> snapshot,
      Value<String> reason,
      Value<int> changedAt,
      Value<String> changedByUserId,
      Value<String> changedByDeviceId,
      Value<int> rowid,
    });

class $TransactionHistoryFilterComposer
    extends Composer<_$AppDatabase, TransactionHistory> {
  $TransactionHistoryFilterComposer({
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

  ColumnFilters<String> get firmId => $composableBuilder(
    column: $table.firmId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changedByUserId => $composableBuilder(
    column: $table.changedByUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changedByDeviceId => $composableBuilder(
    column: $table.changedByDeviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $TransactionHistoryOrderingComposer
    extends Composer<_$AppDatabase, TransactionHistory> {
  $TransactionHistoryOrderingComposer({
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

  ColumnOrderings<String> get firmId => $composableBuilder(
    column: $table.firmId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changedByUserId => $composableBuilder(
    column: $table.changedByUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changedByDeviceId => $composableBuilder(
    column: $table.changedByDeviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $TransactionHistoryAnnotationComposer
    extends Composer<_$AppDatabase, TransactionHistory> {
  $TransactionHistoryAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firmId =>
      $composableBuilder(column: $table.firmId, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get snapshot =>
      $composableBuilder(column: $table.snapshot, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumn<String> get changedByUserId => $composableBuilder(
    column: $table.changedByUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get changedByDeviceId => $composableBuilder(
    column: $table.changedByDeviceId,
    builder: (column) => column,
  );
}

class $TransactionHistoryTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          TransactionHistory,
          TransactionHistoryRow,
          $TransactionHistoryFilterComposer,
          $TransactionHistoryOrderingComposer,
          $TransactionHistoryAnnotationComposer,
          $TransactionHistoryCreateCompanionBuilder,
          $TransactionHistoryUpdateCompanionBuilder,
          (
            TransactionHistoryRow,
            BaseReferences<
              _$AppDatabase,
              TransactionHistory,
              TransactionHistoryRow
            >,
          ),
          TransactionHistoryRow,
          PrefetchHooks Function()
        > {
  $TransactionHistoryTableManager(_$AppDatabase db, TransactionHistory table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TransactionHistoryFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TransactionHistoryOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TransactionHistoryAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> firmId = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> snapshot = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<int> changedAt = const Value.absent(),
                Value<String> changedByUserId = const Value.absent(),
                Value<String> changedByDeviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionHistoryCompanion(
                id: id,
                firmId: firmId,
                transactionId: transactionId,
                version: version,
                snapshot: snapshot,
                reason: reason,
                changedAt: changedAt,
                changedByUserId: changedByUserId,
                changedByDeviceId: changedByDeviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String firmId,
                required String transactionId,
                required int version,
                required String snapshot,
                required String reason,
                required int changedAt,
                required String changedByUserId,
                required String changedByDeviceId,
                Value<int> rowid = const Value.absent(),
              }) => TransactionHistoryCompanion.insert(
                id: id,
                firmId: firmId,
                transactionId: transactionId,
                version: version,
                snapshot: snapshot,
                reason: reason,
                changedAt: changedAt,
                changedByUserId: changedByUserId,
                changedByDeviceId: changedByDeviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<TransactionHistory, TransactionHistoryRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    TransactionHistory,
                    TransactionHistoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $TransactionHistoryProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      TransactionHistory,
      TransactionHistoryRow,
      $TransactionHistoryFilterComposer,
      $TransactionHistoryOrderingComposer,
      $TransactionHistoryAnnotationComposer,
      $TransactionHistoryCreateCompanionBuilder,
      $TransactionHistoryUpdateCompanionBuilder,
      (
        TransactionHistoryRow,
        BaseReferences<
          _$AppDatabase,
          TransactionHistory,
          TransactionHistoryRow
        >,
      ),
      TransactionHistoryRow,
      PrefetchHooks Function()
    >;
typedef $PrintLogCreateCompanionBuilder = PrintLogCompanion Function({
  required String id,
  required String firmId,
  Value<String?> transactionId,
  Value<String?> customerId,
  required String kind,
  required int printedAt,
  required String deviceId,
  Value<int?> printedBalanceAfter,
  Value<String?> rangeFrom,
  Value<String?> rangeTo,
  Value<int> rowid,
});
typedef $PrintLogUpdateCompanionBuilder = PrintLogCompanion Function({
  Value<String> id,
  Value<String> firmId,
  Value<String?> transactionId,
  Value<String?> customerId,
  Value<String> kind,
  Value<int> printedAt,
  Value<String> deviceId,
  Value<int?> printedBalanceAfter,
  Value<String?> rangeFrom,
  Value<String?> rangeTo,
  Value<int> rowid,
});

class $PrintLogFilterComposer extends Composer<_$AppDatabase, PrintLog> {
  $PrintLogFilterComposer({
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

  ColumnFilters<String> get firmId => $composableBuilder(
    column: $table.firmId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get printedAt => $composableBuilder(
    column: $table.printedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get printedBalanceAfter => $composableBuilder(
    column: $table.printedBalanceAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rangeFrom => $composableBuilder(
    column: $table.rangeFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rangeTo => $composableBuilder(
    column: $table.rangeTo,
    builder: (column) => ColumnFilters(column),
  );
}

class $PrintLogOrderingComposer extends Composer<_$AppDatabase, PrintLog> {
  $PrintLogOrderingComposer({
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

  ColumnOrderings<String> get firmId => $composableBuilder(
    column: $table.firmId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get printedAt => $composableBuilder(
    column: $table.printedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get printedBalanceAfter => $composableBuilder(
    column: $table.printedBalanceAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rangeFrom => $composableBuilder(
    column: $table.rangeFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rangeTo => $composableBuilder(
    column: $table.rangeTo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $PrintLogAnnotationComposer extends Composer<_$AppDatabase, PrintLog> {
  $PrintLogAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firmId =>
      $composableBuilder(column: $table.firmId, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get printedAt =>
      $composableBuilder(column: $table.printedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get printedBalanceAfter => $composableBuilder(
    column: $table.printedBalanceAfter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rangeFrom =>
      $composableBuilder(column: $table.rangeFrom, builder: (column) => column);

  GeneratedColumn<String> get rangeTo =>
      $composableBuilder(column: $table.rangeTo, builder: (column) => column);
}

class $PrintLogTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          PrintLog,
          PrintLogRow,
          $PrintLogFilterComposer,
          $PrintLogOrderingComposer,
          $PrintLogAnnotationComposer,
          $PrintLogCreateCompanionBuilder,
          $PrintLogUpdateCompanionBuilder,
          (PrintLogRow, BaseReferences<_$AppDatabase, PrintLog, PrintLogRow>),
          PrintLogRow,
          PrefetchHooks Function()
        > {
  $PrintLogTableManager(_$AppDatabase db, PrintLog table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PrintLogFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PrintLogOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PrintLogAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> firmId = const Value.absent(),
                Value<String?> transactionId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> printedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int?> printedBalanceAfter = const Value.absent(),
                Value<String?> rangeFrom = const Value.absent(),
                Value<String?> rangeTo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrintLogCompanion(
                id: id,
                firmId: firmId,
                transactionId: transactionId,
                customerId: customerId,
                kind: kind,
                printedAt: printedAt,
                deviceId: deviceId,
                printedBalanceAfter: printedBalanceAfter,
                rangeFrom: rangeFrom,
                rangeTo: rangeTo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String firmId,
                Value<String?> transactionId = const Value.absent(),
                Value<String?> customerId = const Value.absent(),
                required String kind,
                required int printedAt,
                required String deviceId,
                Value<int?> printedBalanceAfter = const Value.absent(),
                Value<String?> rangeFrom = const Value.absent(),
                Value<String?> rangeTo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrintLogCompanion.insert(
                id: id,
                firmId: firmId,
                transactionId: transactionId,
                customerId: customerId,
                kind: kind,
                printedAt: printedAt,
                deviceId: deviceId,
                printedBalanceAfter: printedBalanceAfter,
                rangeFrom: rangeFrom,
                rangeTo: rangeTo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<PrintLog, PrintLogRow>(table),
                  BaseReferences<_$AppDatabase, PrintLog, PrintLogRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $PrintLogProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      PrintLog,
      PrintLogRow,
      $PrintLogFilterComposer,
      $PrintLogOrderingComposer,
      $PrintLogAnnotationComposer,
      $PrintLogCreateCompanionBuilder,
      $PrintLogUpdateCompanionBuilder,
      (PrintLogRow, BaseReferences<_$AppDatabase, PrintLog, PrintLogRow>),
      PrintLogRow,
      PrefetchHooks Function()
    >;
typedef $SyncOutboxCreateCompanionBuilder = SyncOutboxCompanion Function({
  required String targetTable,
  required String rowId,
  required int queuedUpdatedAt,
  Value<int> attempts,
  Value<String?> failedReason,
  Value<int> rowid,
});
typedef $SyncOutboxUpdateCompanionBuilder = SyncOutboxCompanion Function({
  Value<String> targetTable,
  Value<String> rowId,
  Value<int> queuedUpdatedAt,
  Value<int> attempts,
  Value<String?> failedReason,
  Value<int> rowid,
});

class $SyncOutboxFilterComposer extends Composer<_$AppDatabase, SyncOutbox> {
  $SyncOutboxFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get queuedUpdatedAt => $composableBuilder(
    column: $table.queuedUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failedReason => $composableBuilder(
    column: $table.failedReason,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncOutboxOrderingComposer extends Composer<_$AppDatabase, SyncOutbox> {
  $SyncOutboxOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get queuedUpdatedAt => $composableBuilder(
    column: $table.queuedUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failedReason => $composableBuilder(
    column: $table.failedReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncOutboxAnnotationComposer
    extends Composer<_$AppDatabase, SyncOutbox> {
  $SyncOutboxAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<int> get queuedUpdatedAt => $composableBuilder(
    column: $table.queuedUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get failedReason => $composableBuilder(
    column: $table.failedReason,
    builder: (column) => column,
  );
}

class $SyncOutboxTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SyncOutbox,
          SyncOutboxRow,
          $SyncOutboxFilterComposer,
          $SyncOutboxOrderingComposer,
          $SyncOutboxAnnotationComposer,
          $SyncOutboxCreateCompanionBuilder,
          $SyncOutboxUpdateCompanionBuilder,
          (
            SyncOutboxRow,
            BaseReferences<_$AppDatabase, SyncOutbox, SyncOutboxRow>,
          ),
          SyncOutboxRow,
          PrefetchHooks Function()
        > {
  $SyncOutboxTableManager(_$AppDatabase db, SyncOutbox table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncOutboxFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncOutboxOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncOutboxAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> targetTable = const Value.absent(),
                Value<String> rowId = const Value.absent(),
                Value<int> queuedUpdatedAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> failedReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxCompanion(
                targetTable: targetTable,
                rowId: rowId,
                queuedUpdatedAt: queuedUpdatedAt,
                attempts: attempts,
                failedReason: failedReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String targetTable,
                required String rowId,
                required int queuedUpdatedAt,
                Value<int> attempts = const Value.absent(),
                Value<String?> failedReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxCompanion.insert(
                targetTable: targetTable,
                rowId: rowId,
                queuedUpdatedAt: queuedUpdatedAt,
                attempts: attempts,
                failedReason: failedReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SyncOutbox, SyncOutboxRow>(table),
                  BaseReferences<_$AppDatabase, SyncOutbox, SyncOutboxRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncOutboxProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SyncOutbox,
      SyncOutboxRow,
      $SyncOutboxFilterComposer,
      $SyncOutboxOrderingComposer,
      $SyncOutboxAnnotationComposer,
      $SyncOutboxCreateCompanionBuilder,
      $SyncOutboxUpdateCompanionBuilder,
      (SyncOutboxRow, BaseReferences<_$AppDatabase, SyncOutbox, SyncOutboxRow>),
      SyncOutboxRow,
      PrefetchHooks Function()
    >;
typedef $SyncOrphansCreateCompanionBuilder = SyncOrphansCompanion Function({
  required String targetTable,
  required String rowId,
  required String payload,
  required String missingParentTable,
  required String missingParentId,
  required int receivedAt,
  Value<int> rowid,
});
typedef $SyncOrphansUpdateCompanionBuilder = SyncOrphansCompanion Function({
  Value<String> targetTable,
  Value<String> rowId,
  Value<String> payload,
  Value<String> missingParentTable,
  Value<String> missingParentId,
  Value<int> receivedAt,
  Value<int> rowid,
});

class $SyncOrphansFilterComposer extends Composer<_$AppDatabase, SyncOrphans> {
  $SyncOrphansFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get missingParentTable => $composableBuilder(
    column: $table.missingParentTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get missingParentId => $composableBuilder(
    column: $table.missingParentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncOrphansOrderingComposer
    extends Composer<_$AppDatabase, SyncOrphans> {
  $SyncOrphansOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get missingParentTable => $composableBuilder(
    column: $table.missingParentTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get missingParentId => $composableBuilder(
    column: $table.missingParentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncOrphansAnnotationComposer
    extends Composer<_$AppDatabase, SyncOrphans> {
  $SyncOrphansAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get missingParentTable => $composableBuilder(
    column: $table.missingParentTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get missingParentId => $composableBuilder(
    column: $table.missingParentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );
}

class $SyncOrphansTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SyncOrphans,
          SyncOrphanRow,
          $SyncOrphansFilterComposer,
          $SyncOrphansOrderingComposer,
          $SyncOrphansAnnotationComposer,
          $SyncOrphansCreateCompanionBuilder,
          $SyncOrphansUpdateCompanionBuilder,
          (
            SyncOrphanRow,
            BaseReferences<_$AppDatabase, SyncOrphans, SyncOrphanRow>,
          ),
          SyncOrphanRow,
          PrefetchHooks Function()
        > {
  $SyncOrphansTableManager(_$AppDatabase db, SyncOrphans table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncOrphansFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncOrphansOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncOrphansAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> targetTable = const Value.absent(),
                Value<String> rowId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> missingParentTable = const Value.absent(),
                Value<String> missingParentId = const Value.absent(),
                Value<int> receivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOrphansCompanion(
                targetTable: targetTable,
                rowId: rowId,
                payload: payload,
                missingParentTable: missingParentTable,
                missingParentId: missingParentId,
                receivedAt: receivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String targetTable,
                required String rowId,
                required String payload,
                required String missingParentTable,
                required String missingParentId,
                required int receivedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncOrphansCompanion.insert(
                targetTable: targetTable,
                rowId: rowId,
                payload: payload,
                missingParentTable: missingParentTable,
                missingParentId: missingParentId,
                receivedAt: receivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SyncOrphans, SyncOrphanRow>(table),
                  BaseReferences<_$AppDatabase, SyncOrphans, SyncOrphanRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncOrphansProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SyncOrphans,
      SyncOrphanRow,
      $SyncOrphansFilterComposer,
      $SyncOrphansOrderingComposer,
      $SyncOrphansAnnotationComposer,
      $SyncOrphansCreateCompanionBuilder,
      $SyncOrphansUpdateCompanionBuilder,
      (
        SyncOrphanRow,
        BaseReferences<_$AppDatabase, SyncOrphans, SyncOrphanRow>,
      ),
      SyncOrphanRow,
      PrefetchHooks Function()
    >;
typedef $SyncStateCreateCompanionBuilder = SyncStateCompanion Function({
  required String deviceId,
  Value<int> lastPullCursor,
  Value<int> clockOffsetMs,
  Value<int> hlcLast,
  Value<int?> lastSyncAt,
  Value<String?> pausedReason,
  Value<int> rowid,
});
typedef $SyncStateUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> deviceId,
  Value<int> lastPullCursor,
  Value<int> clockOffsetMs,
  Value<int> hlcLast,
  Value<int?> lastSyncAt,
  Value<String?> pausedReason,
  Value<int> rowid,
});

class $SyncStateFilterComposer extends Composer<_$AppDatabase, SyncState> {
  $SyncStateFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPullCursor => $composableBuilder(
    column: $table.lastPullCursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clockOffsetMs => $composableBuilder(
    column: $table.clockOffsetMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hlcLast => $composableBuilder(
    column: $table.hlcLast,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pausedReason => $composableBuilder(
    column: $table.pausedReason,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncStateOrderingComposer extends Composer<_$AppDatabase, SyncState> {
  $SyncStateOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPullCursor => $composableBuilder(
    column: $table.lastPullCursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clockOffsetMs => $composableBuilder(
    column: $table.clockOffsetMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hlcLast => $composableBuilder(
    column: $table.hlcLast,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pausedReason => $composableBuilder(
    column: $table.pausedReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncStateAnnotationComposer extends Composer<_$AppDatabase, SyncState> {
  $SyncStateAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get lastPullCursor => $composableBuilder(
    column: $table.lastPullCursor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get clockOffsetMs => $composableBuilder(
    column: $table.clockOffsetMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hlcLast =>
      $composableBuilder(column: $table.hlcLast, builder: (column) => column);

  GeneratedColumn<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pausedReason => $composableBuilder(
    column: $table.pausedReason,
    builder: (column) => column,
  );
}

class $SyncStateTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SyncState,
          SyncStateRow,
          $SyncStateFilterComposer,
          $SyncStateOrderingComposer,
          $SyncStateAnnotationComposer,
          $SyncStateCreateCompanionBuilder,
          $SyncStateUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, SyncState, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $SyncStateTableManager(_$AppDatabase db, SyncState table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncStateFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncStateOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncStateAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> lastPullCursor = const Value.absent(),
                Value<int> clockOffsetMs = const Value.absent(),
                Value<int> hlcLast = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
                Value<String?> pausedReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(
                deviceId: deviceId,
                lastPullCursor: lastPullCursor,
                clockOffsetMs: clockOffsetMs,
                hlcLast: hlcLast,
                lastSyncAt: lastSyncAt,
                pausedReason: pausedReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                Value<int> lastPullCursor = const Value.absent(),
                Value<int> clockOffsetMs = const Value.absent(),
                Value<int> hlcLast = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
                Value<String?> pausedReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                deviceId: deviceId,
                lastPullCursor: lastPullCursor,
                clockOffsetMs: clockOffsetMs,
                hlcLast: hlcLast,
                lastSyncAt: lastSyncAt,
                pausedReason: pausedReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SyncState, SyncStateRow>(table),
                  BaseReferences<_$AppDatabase, SyncState, SyncStateRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncStateProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SyncState,
      SyncStateRow,
      $SyncStateFilterComposer,
      $SyncStateOrderingComposer,
      $SyncStateAnnotationComposer,
      $SyncStateCreateCompanionBuilder,
      $SyncStateUpdateCompanionBuilder,
      (SyncStateRow, BaseReferences<_$AppDatabase, SyncState, SyncStateRow>),
      SyncStateRow,
      PrefetchHooks Function()
    >;
typedef $AppSettingsCreateCompanionBuilder = AppSettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $AppSettingsUpdateCompanionBuilder = AppSettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $AppSettingsFilterComposer extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $AppSettingsOrderingComposer
    extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AppSettingsAnnotationComposer
    extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsAnnotationComposer({
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

class $AppSettingsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          AppSettings,
          AppSettingRow,
          $AppSettingsFilterComposer,
          $AppSettingsOrderingComposer,
          $AppSettingsAnnotationComposer,
          $AppSettingsCreateCompanionBuilder,
          $AppSettingsUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$AppDatabase, AppSettings, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $AppSettingsTableManager(_$AppDatabase db, AppSettings table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AppSettingsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AppSettingsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AppSettingsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<AppSettings, AppSettingRow>(table),
                  BaseReferences<_$AppDatabase, AppSettings, AppSettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $AppSettingsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      AppSettings,
      AppSettingRow,
      $AppSettingsFilterComposer,
      $AppSettingsOrderingComposer,
      $AppSettingsAnnotationComposer,
      $AppSettingsCreateCompanionBuilder,
      $AppSettingsUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$AppDatabase, AppSettings, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $FirmsTableManager get firms => $FirmsTableManager(_db, _db.firms);
  $UsersTableManager get users => $UsersTableManager(_db, _db.users);
  $FirmMembersTableManager get firmMembers =>
      $FirmMembersTableManager(_db, _db.firmMembers);
  $DevicesTableManager get devices => $DevicesTableManager(_db, _db.devices);
  $ItemsTableManager get items => $ItemsTableManager(_db, _db.items);
  $CustomersTableManager get customers =>
      $CustomersTableManager(_db, _db.customers);
  $TransactionsTableManager get transactions =>
      $TransactionsTableManager(_db, _db.transactions);
  $TransactionLinesTableManager get transactionLines =>
      $TransactionLinesTableManager(_db, _db.transactionLines);
  $TransactionHistoryTableManager get transactionHistory =>
      $TransactionHistoryTableManager(_db, _db.transactionHistory);
  $PrintLogTableManager get printLog =>
      $PrintLogTableManager(_db, _db.printLog);
  $SyncOutboxTableManager get syncOutbox =>
      $SyncOutboxTableManager(_db, _db.syncOutbox);
  $SyncOrphansTableManager get syncOrphans =>
      $SyncOrphansTableManager(_db, _db.syncOrphans);
  $SyncStateTableManager get syncState =>
      $SyncStateTableManager(_db, _db.syncState);
  $AppSettingsTableManager get appSettings =>
      $AppSettingsTableManager(_db, _db.appSettings);
}
