// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedEarthquakesTable extends CachedEarthquakes
    with TableInfo<$CachedEarthquakesTable, CachedEarthquake> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedEarthquakesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerEventIdMeta = const VerificationMeta(
    'providerEventId',
  );
  @override
  late final GeneratedColumn<String> providerEventId = GeneratedColumn<String>(
    'provider_event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placeMeta = const VerificationMeta('place');
  @override
  late final GeneratedColumn<String> place = GeneratedColumn<String>(
    'place',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _magnitudeMeta = const VerificationMeta(
    'magnitude',
  );
  @override
  late final GeneratedColumn<double> magnitude = GeneratedColumn<double>(
    'magnitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _depthKmMeta = const VerificationMeta(
    'depthKm',
  );
  @override
  late final GeneratedColumn<double> depthKm = GeneratedColumn<double>(
    'depth_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventAtMeta = const VerificationMeta(
    'eventAt',
  );
  @override
  late final GeneratedColumn<int> eventAt = GeneratedColumn<int>(
    'event_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerUpdatedAtMeta = const VerificationMeta(
    'providerUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> providerUpdatedAt = GeneratedColumn<int>(
    'provider_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retrievedAtMeta = const VerificationMeta(
    'retrievedAt',
  );
  @override
  late final GeneratedColumn<int> retrievedAt = GeneratedColumn<int>(
    'retrieved_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewStatusMeta = const VerificationMeta(
    'reviewStatus',
  );
  @override
  late final GeneratedColumn<String> reviewStatus = GeneratedColumn<String>(
    'review_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    provider,
    providerEventId,
    kind,
    title,
    place,
    magnitude,
    depthKm,
    latitude,
    longitude,
    eventAt,
    providerUpdatedAt,
    retrievedAt,
    reviewStatus,
    sourceUrl,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_earthquakes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedEarthquake> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('provider_event_id')) {
      context.handle(
        _providerEventIdMeta,
        providerEventId.isAcceptableOrUnknown(
          data['provider_event_id']!,
          _providerEventIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerEventIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('place')) {
      context.handle(
        _placeMeta,
        place.isAcceptableOrUnknown(data['place']!, _placeMeta),
      );
    } else if (isInserting) {
      context.missing(_placeMeta);
    }
    if (data.containsKey('magnitude')) {
      context.handle(
        _magnitudeMeta,
        magnitude.isAcceptableOrUnknown(data['magnitude']!, _magnitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_magnitudeMeta);
    }
    if (data.containsKey('depth_km')) {
      context.handle(
        _depthKmMeta,
        depthKm.isAcceptableOrUnknown(data['depth_km']!, _depthKmMeta),
      );
    } else if (isInserting) {
      context.missing(_depthKmMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('event_at')) {
      context.handle(
        _eventAtMeta,
        eventAt.isAcceptableOrUnknown(data['event_at']!, _eventAtMeta),
      );
    } else if (isInserting) {
      context.missing(_eventAtMeta);
    }
    if (data.containsKey('provider_updated_at')) {
      context.handle(
        _providerUpdatedAtMeta,
        providerUpdatedAt.isAcceptableOrUnknown(
          data['provider_updated_at']!,
          _providerUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerUpdatedAtMeta);
    }
    if (data.containsKey('retrieved_at')) {
      context.handle(
        _retrievedAtMeta,
        retrievedAt.isAcceptableOrUnknown(
          data['retrieved_at']!,
          _retrievedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_retrievedAtMeta);
    }
    if (data.containsKey('review_status')) {
      context.handle(
        _reviewStatusMeta,
        reviewStatus.isAcceptableOrUnknown(
          data['review_status']!,
          _reviewStatusMeta,
        ),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceUrlMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {provider, providerEventId},
  ];
  @override
  CachedEarthquake map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedEarthquake(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      providerEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_event_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      place: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place'],
      )!,
      magnitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}magnitude'],
      )!,
      depthKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}depth_km'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      eventAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_at'],
      )!,
      providerUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_updated_at'],
      )!,
      retrievedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retrieved_at'],
      )!,
      reviewStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_status'],
      ),
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $CachedEarthquakesTable createAlias(String alias) {
    return $CachedEarthquakesTable(attachedDatabase, alias);
  }
}

class CachedEarthquake extends DataClass
    implements Insertable<CachedEarthquake> {
  final String id;
  final String provider;
  final String providerEventId;
  final String kind;
  final String title;
  final String place;
  final double magnitude;
  final double depthKm;
  final double latitude;
  final double longitude;
  final int eventAt;
  final int providerUpdatedAt;
  final int retrievedAt;
  final String? reviewStatus;
  final String sourceUrl;
  final int version;
  const CachedEarthquake({
    required this.id,
    required this.provider,
    required this.providerEventId,
    required this.kind,
    required this.title,
    required this.place,
    required this.magnitude,
    required this.depthKm,
    required this.latitude,
    required this.longitude,
    required this.eventAt,
    required this.providerUpdatedAt,
    required this.retrievedAt,
    this.reviewStatus,
    required this.sourceUrl,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider'] = Variable<String>(provider);
    map['provider_event_id'] = Variable<String>(providerEventId);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    map['place'] = Variable<String>(place);
    map['magnitude'] = Variable<double>(magnitude);
    map['depth_km'] = Variable<double>(depthKm);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['event_at'] = Variable<int>(eventAt);
    map['provider_updated_at'] = Variable<int>(providerUpdatedAt);
    map['retrieved_at'] = Variable<int>(retrievedAt);
    if (!nullToAbsent || reviewStatus != null) {
      map['review_status'] = Variable<String>(reviewStatus);
    }
    map['source_url'] = Variable<String>(sourceUrl);
    map['version'] = Variable<int>(version);
    return map;
  }

  CachedEarthquakesCompanion toCompanion(bool nullToAbsent) {
    return CachedEarthquakesCompanion(
      id: Value(id),
      provider: Value(provider),
      providerEventId: Value(providerEventId),
      kind: Value(kind),
      title: Value(title),
      place: Value(place),
      magnitude: Value(magnitude),
      depthKm: Value(depthKm),
      latitude: Value(latitude),
      longitude: Value(longitude),
      eventAt: Value(eventAt),
      providerUpdatedAt: Value(providerUpdatedAt),
      retrievedAt: Value(retrievedAt),
      reviewStatus: reviewStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewStatus),
      sourceUrl: Value(sourceUrl),
      version: Value(version),
    );
  }

  factory CachedEarthquake.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedEarthquake(
      id: serializer.fromJson<String>(json['id']),
      provider: serializer.fromJson<String>(json['provider']),
      providerEventId: serializer.fromJson<String>(json['providerEventId']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      place: serializer.fromJson<String>(json['place']),
      magnitude: serializer.fromJson<double>(json['magnitude']),
      depthKm: serializer.fromJson<double>(json['depthKm']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      eventAt: serializer.fromJson<int>(json['eventAt']),
      providerUpdatedAt: serializer.fromJson<int>(json['providerUpdatedAt']),
      retrievedAt: serializer.fromJson<int>(json['retrievedAt']),
      reviewStatus: serializer.fromJson<String?>(json['reviewStatus']),
      sourceUrl: serializer.fromJson<String>(json['sourceUrl']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'provider': serializer.toJson<String>(provider),
      'providerEventId': serializer.toJson<String>(providerEventId),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'place': serializer.toJson<String>(place),
      'magnitude': serializer.toJson<double>(magnitude),
      'depthKm': serializer.toJson<double>(depthKm),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'eventAt': serializer.toJson<int>(eventAt),
      'providerUpdatedAt': serializer.toJson<int>(providerUpdatedAt),
      'retrievedAt': serializer.toJson<int>(retrievedAt),
      'reviewStatus': serializer.toJson<String?>(reviewStatus),
      'sourceUrl': serializer.toJson<String>(sourceUrl),
      'version': serializer.toJson<int>(version),
    };
  }

  CachedEarthquake copyWith({
    String? id,
    String? provider,
    String? providerEventId,
    String? kind,
    String? title,
    String? place,
    double? magnitude,
    double? depthKm,
    double? latitude,
    double? longitude,
    int? eventAt,
    int? providerUpdatedAt,
    int? retrievedAt,
    Value<String?> reviewStatus = const Value.absent(),
    String? sourceUrl,
    int? version,
  }) => CachedEarthquake(
    id: id ?? this.id,
    provider: provider ?? this.provider,
    providerEventId: providerEventId ?? this.providerEventId,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    place: place ?? this.place,
    magnitude: magnitude ?? this.magnitude,
    depthKm: depthKm ?? this.depthKm,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    eventAt: eventAt ?? this.eventAt,
    providerUpdatedAt: providerUpdatedAt ?? this.providerUpdatedAt,
    retrievedAt: retrievedAt ?? this.retrievedAt,
    reviewStatus: reviewStatus.present ? reviewStatus.value : this.reviewStatus,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    version: version ?? this.version,
  );
  CachedEarthquake copyWithCompanion(CachedEarthquakesCompanion data) {
    return CachedEarthquake(
      id: data.id.present ? data.id.value : this.id,
      provider: data.provider.present ? data.provider.value : this.provider,
      providerEventId: data.providerEventId.present
          ? data.providerEventId.value
          : this.providerEventId,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      place: data.place.present ? data.place.value : this.place,
      magnitude: data.magnitude.present ? data.magnitude.value : this.magnitude,
      depthKm: data.depthKm.present ? data.depthKm.value : this.depthKm,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      eventAt: data.eventAt.present ? data.eventAt.value : this.eventAt,
      providerUpdatedAt: data.providerUpdatedAt.present
          ? data.providerUpdatedAt.value
          : this.providerUpdatedAt,
      retrievedAt: data.retrievedAt.present
          ? data.retrievedAt.value
          : this.retrievedAt,
      reviewStatus: data.reviewStatus.present
          ? data.reviewStatus.value
          : this.reviewStatus,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedEarthquake(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('providerEventId: $providerEventId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('place: $place, ')
          ..write('magnitude: $magnitude, ')
          ..write('depthKm: $depthKm, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('eventAt: $eventAt, ')
          ..write('providerUpdatedAt: $providerUpdatedAt, ')
          ..write('retrievedAt: $retrievedAt, ')
          ..write('reviewStatus: $reviewStatus, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    provider,
    providerEventId,
    kind,
    title,
    place,
    magnitude,
    depthKm,
    latitude,
    longitude,
    eventAt,
    providerUpdatedAt,
    retrievedAt,
    reviewStatus,
    sourceUrl,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedEarthquake &&
          other.id == this.id &&
          other.provider == this.provider &&
          other.providerEventId == this.providerEventId &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.place == this.place &&
          other.magnitude == this.magnitude &&
          other.depthKm == this.depthKm &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.eventAt == this.eventAt &&
          other.providerUpdatedAt == this.providerUpdatedAt &&
          other.retrievedAt == this.retrievedAt &&
          other.reviewStatus == this.reviewStatus &&
          other.sourceUrl == this.sourceUrl &&
          other.version == this.version);
}

class CachedEarthquakesCompanion extends UpdateCompanion<CachedEarthquake> {
  final Value<String> id;
  final Value<String> provider;
  final Value<String> providerEventId;
  final Value<String> kind;
  final Value<String> title;
  final Value<String> place;
  final Value<double> magnitude;
  final Value<double> depthKm;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<int> eventAt;
  final Value<int> providerUpdatedAt;
  final Value<int> retrievedAt;
  final Value<String?> reviewStatus;
  final Value<String> sourceUrl;
  final Value<int> version;
  final Value<int> rowid;
  const CachedEarthquakesCompanion({
    this.id = const Value.absent(),
    this.provider = const Value.absent(),
    this.providerEventId = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.place = const Value.absent(),
    this.magnitude = const Value.absent(),
    this.depthKm = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.eventAt = const Value.absent(),
    this.providerUpdatedAt = const Value.absent(),
    this.retrievedAt = const Value.absent(),
    this.reviewStatus = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedEarthquakesCompanion.insert({
    required String id,
    required String provider,
    required String providerEventId,
    required String kind,
    required String title,
    required String place,
    required double magnitude,
    required double depthKm,
    required double latitude,
    required double longitude,
    required int eventAt,
    required int providerUpdatedAt,
    required int retrievedAt,
    this.reviewStatus = const Value.absent(),
    required String sourceUrl,
    required int version,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       provider = Value(provider),
       providerEventId = Value(providerEventId),
       kind = Value(kind),
       title = Value(title),
       place = Value(place),
       magnitude = Value(magnitude),
       depthKm = Value(depthKm),
       latitude = Value(latitude),
       longitude = Value(longitude),
       eventAt = Value(eventAt),
       providerUpdatedAt = Value(providerUpdatedAt),
       retrievedAt = Value(retrievedAt),
       sourceUrl = Value(sourceUrl),
       version = Value(version);
  static Insertable<CachedEarthquake> custom({
    Expression<String>? id,
    Expression<String>? provider,
    Expression<String>? providerEventId,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? place,
    Expression<double>? magnitude,
    Expression<double>? depthKm,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? eventAt,
    Expression<int>? providerUpdatedAt,
    Expression<int>? retrievedAt,
    Expression<String>? reviewStatus,
    Expression<String>? sourceUrl,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (provider != null) 'provider': provider,
      if (providerEventId != null) 'provider_event_id': providerEventId,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (place != null) 'place': place,
      if (magnitude != null) 'magnitude': magnitude,
      if (depthKm != null) 'depth_km': depthKm,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (eventAt != null) 'event_at': eventAt,
      if (providerUpdatedAt != null) 'provider_updated_at': providerUpdatedAt,
      if (retrievedAt != null) 'retrieved_at': retrievedAt,
      if (reviewStatus != null) 'review_status': reviewStatus,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedEarthquakesCompanion copyWith({
    Value<String>? id,
    Value<String>? provider,
    Value<String>? providerEventId,
    Value<String>? kind,
    Value<String>? title,
    Value<String>? place,
    Value<double>? magnitude,
    Value<double>? depthKm,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<int>? eventAt,
    Value<int>? providerUpdatedAt,
    Value<int>? retrievedAt,
    Value<String?>? reviewStatus,
    Value<String>? sourceUrl,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return CachedEarthquakesCompanion(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      providerEventId: providerEventId ?? this.providerEventId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      place: place ?? this.place,
      magnitude: magnitude ?? this.magnitude,
      depthKm: depthKm ?? this.depthKm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      eventAt: eventAt ?? this.eventAt,
      providerUpdatedAt: providerUpdatedAt ?? this.providerUpdatedAt,
      retrievedAt: retrievedAt ?? this.retrievedAt,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (providerEventId.present) {
      map['provider_event_id'] = Variable<String>(providerEventId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (place.present) {
      map['place'] = Variable<String>(place.value);
    }
    if (magnitude.present) {
      map['magnitude'] = Variable<double>(magnitude.value);
    }
    if (depthKm.present) {
      map['depth_km'] = Variable<double>(depthKm.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (eventAt.present) {
      map['event_at'] = Variable<int>(eventAt.value);
    }
    if (providerUpdatedAt.present) {
      map['provider_updated_at'] = Variable<int>(providerUpdatedAt.value);
    }
    if (retrievedAt.present) {
      map['retrieved_at'] = Variable<int>(retrievedAt.value);
    }
    if (reviewStatus.present) {
      map['review_status'] = Variable<String>(reviewStatus.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedEarthquakesCompanion(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('providerEventId: $providerEventId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('place: $place, ')
          ..write('magnitude: $magnitude, ')
          ..write('depthKm: $depthKm, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('eventAt: $eventAt, ')
          ..write('providerUpdatedAt: $providerUpdatedAt, ')
          ..write('retrievedAt: $retrievedAt, ')
          ..write('reviewStatus: $reviewStatus, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlertSyncMetadataTable extends AlertSyncMetadata
    with TableInfo<$AlertSyncMetadataTable, AlertSyncMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertSyncMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataStatusMeta = const VerificationMeta(
    'dataStatus',
  );
  @override
  late final GeneratedColumn<String> dataStatus = GeneratedColumn<String>(
    'data_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (data_status IN (\'current\', \'stale\'))',
  );
  static const VerificationMeta _lastSuccessfulRefreshAtMeta =
      const VerificationMeta('lastSuccessfulRefreshAt');
  @override
  late final GeneratedColumn<int> lastSuccessfulRefreshAt =
      GeneratedColumn<int>(
        'last_successful_refresh_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    provider,
    dataStatus,
    lastSuccessfulRefreshAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alert_sync_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlertSyncMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('data_status')) {
      context.handle(
        _dataStatusMeta,
        dataStatus.isAcceptableOrUnknown(data['data_status']!, _dataStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_dataStatusMeta);
    }
    if (data.containsKey('last_successful_refresh_at')) {
      context.handle(
        _lastSuccessfulRefreshAtMeta,
        lastSuccessfulRefreshAt.isAcceptableOrUnknown(
          data['last_successful_refresh_at']!,
          _lastSuccessfulRefreshAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSuccessfulRefreshAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {provider};
  @override
  AlertSyncMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlertSyncMetadataData(
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      dataStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_status'],
      )!,
      lastSuccessfulRefreshAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_successful_refresh_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $AlertSyncMetadataTable createAlias(String alias) {
    return $AlertSyncMetadataTable(attachedDatabase, alias);
  }
}

class AlertSyncMetadataData extends DataClass
    implements Insertable<AlertSyncMetadataData> {
  final String provider;
  final String dataStatus;
  final int lastSuccessfulRefreshAt;
  final int cachedAt;
  const AlertSyncMetadataData({
    required this.provider,
    required this.dataStatus,
    required this.lastSuccessfulRefreshAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider'] = Variable<String>(provider);
    map['data_status'] = Variable<String>(dataStatus);
    map['last_successful_refresh_at'] = Variable<int>(lastSuccessfulRefreshAt);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  AlertSyncMetadataCompanion toCompanion(bool nullToAbsent) {
    return AlertSyncMetadataCompanion(
      provider: Value(provider),
      dataStatus: Value(dataStatus),
      lastSuccessfulRefreshAt: Value(lastSuccessfulRefreshAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory AlertSyncMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlertSyncMetadataData(
      provider: serializer.fromJson<String>(json['provider']),
      dataStatus: serializer.fromJson<String>(json['dataStatus']),
      lastSuccessfulRefreshAt: serializer.fromJson<int>(
        json['lastSuccessfulRefreshAt'],
      ),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'provider': serializer.toJson<String>(provider),
      'dataStatus': serializer.toJson<String>(dataStatus),
      'lastSuccessfulRefreshAt': serializer.toJson<int>(
        lastSuccessfulRefreshAt,
      ),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  AlertSyncMetadataData copyWith({
    String? provider,
    String? dataStatus,
    int? lastSuccessfulRefreshAt,
    int? cachedAt,
  }) => AlertSyncMetadataData(
    provider: provider ?? this.provider,
    dataStatus: dataStatus ?? this.dataStatus,
    lastSuccessfulRefreshAt:
        lastSuccessfulRefreshAt ?? this.lastSuccessfulRefreshAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  AlertSyncMetadataData copyWithCompanion(AlertSyncMetadataCompanion data) {
    return AlertSyncMetadataData(
      provider: data.provider.present ? data.provider.value : this.provider,
      dataStatus: data.dataStatus.present
          ? data.dataStatus.value
          : this.dataStatus,
      lastSuccessfulRefreshAt: data.lastSuccessfulRefreshAt.present
          ? data.lastSuccessfulRefreshAt.value
          : this.lastSuccessfulRefreshAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlertSyncMetadataData(')
          ..write('provider: $provider, ')
          ..write('dataStatus: $dataStatus, ')
          ..write('lastSuccessfulRefreshAt: $lastSuccessfulRefreshAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(provider, dataStatus, lastSuccessfulRefreshAt, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlertSyncMetadataData &&
          other.provider == this.provider &&
          other.dataStatus == this.dataStatus &&
          other.lastSuccessfulRefreshAt == this.lastSuccessfulRefreshAt &&
          other.cachedAt == this.cachedAt);
}

class AlertSyncMetadataCompanion
    extends UpdateCompanion<AlertSyncMetadataData> {
  final Value<String> provider;
  final Value<String> dataStatus;
  final Value<int> lastSuccessfulRefreshAt;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const AlertSyncMetadataCompanion({
    this.provider = const Value.absent(),
    this.dataStatus = const Value.absent(),
    this.lastSuccessfulRefreshAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertSyncMetadataCompanion.insert({
    required String provider,
    required String dataStatus,
    required int lastSuccessfulRefreshAt,
    required int cachedAt,
    this.rowid = const Value.absent(),
  }) : provider = Value(provider),
       dataStatus = Value(dataStatus),
       lastSuccessfulRefreshAt = Value(lastSuccessfulRefreshAt),
       cachedAt = Value(cachedAt);
  static Insertable<AlertSyncMetadataData> custom({
    Expression<String>? provider,
    Expression<String>? dataStatus,
    Expression<int>? lastSuccessfulRefreshAt,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (provider != null) 'provider': provider,
      if (dataStatus != null) 'data_status': dataStatus,
      if (lastSuccessfulRefreshAt != null)
        'last_successful_refresh_at': lastSuccessfulRefreshAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertSyncMetadataCompanion copyWith({
    Value<String>? provider,
    Value<String>? dataStatus,
    Value<int>? lastSuccessfulRefreshAt,
    Value<int>? cachedAt,
    Value<int>? rowid,
  }) {
    return AlertSyncMetadataCompanion(
      provider: provider ?? this.provider,
      dataStatus: dataStatus ?? this.dataStatus,
      lastSuccessfulRefreshAt:
          lastSuccessfulRefreshAt ?? this.lastSuccessfulRefreshAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (dataStatus.present) {
      map['data_status'] = Variable<String>(dataStatus.value);
    }
    if (lastSuccessfulRefreshAt.present) {
      map['last_successful_refresh_at'] = Variable<int>(
        lastSuccessfulRefreshAt.value,
      );
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertSyncMetadataCompanion(')
          ..write('provider: $provider, ')
          ..write('dataStatus: $dataStatus, ')
          ..write('lastSuccessfulRefreshAt: $lastSuccessfulRefreshAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedEarthquakesTable cachedEarthquakes =
      $CachedEarthquakesTable(this);
  late final $AlertSyncMetadataTable alertSyncMetadata =
      $AlertSyncMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedEarthquakes,
    alertSyncMetadata,
  ];
}

typedef $$CachedEarthquakesTableCreateCompanionBuilder =
    CachedEarthquakesCompanion Function({
      required String id,
      required String provider,
      required String providerEventId,
      required String kind,
      required String title,
      required String place,
      required double magnitude,
      required double depthKm,
      required double latitude,
      required double longitude,
      required int eventAt,
      required int providerUpdatedAt,
      required int retrievedAt,
      Value<String?> reviewStatus,
      required String sourceUrl,
      required int version,
      Value<int> rowid,
    });
typedef $$CachedEarthquakesTableUpdateCompanionBuilder =
    CachedEarthquakesCompanion Function({
      Value<String> id,
      Value<String> provider,
      Value<String> providerEventId,
      Value<String> kind,
      Value<String> title,
      Value<String> place,
      Value<double> magnitude,
      Value<double> depthKm,
      Value<double> latitude,
      Value<double> longitude,
      Value<int> eventAt,
      Value<int> providerUpdatedAt,
      Value<int> retrievedAt,
      Value<String?> reviewStatus,
      Value<String> sourceUrl,
      Value<int> version,
      Value<int> rowid,
    });

class $$CachedEarthquakesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedEarthquakesTable> {
  $$CachedEarthquakesTableFilterComposer({
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

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerEventId => $composableBuilder(
    column: $table.providerEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get magnitude => $composableBuilder(
    column: $table.magnitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get depthKm => $composableBuilder(
    column: $table.depthKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eventAt => $composableBuilder(
    column: $table.eventAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get providerUpdatedAt => $composableBuilder(
    column: $table.providerUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retrievedAt => $composableBuilder(
    column: $table.retrievedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewStatus => $composableBuilder(
    column: $table.reviewStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedEarthquakesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedEarthquakesTable> {
  $$CachedEarthquakesTableOrderingComposer({
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

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerEventId => $composableBuilder(
    column: $table.providerEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get magnitude => $composableBuilder(
    column: $table.magnitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get depthKm => $composableBuilder(
    column: $table.depthKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eventAt => $composableBuilder(
    column: $table.eventAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get providerUpdatedAt => $composableBuilder(
    column: $table.providerUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retrievedAt => $composableBuilder(
    column: $table.retrievedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewStatus => $composableBuilder(
    column: $table.reviewStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedEarthquakesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedEarthquakesTable> {
  $$CachedEarthquakesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get providerEventId => $composableBuilder(
    column: $table.providerEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get place =>
      $composableBuilder(column: $table.place, builder: (column) => column);

  GeneratedColumn<double> get magnitude =>
      $composableBuilder(column: $table.magnitude, builder: (column) => column);

  GeneratedColumn<double> get depthKm =>
      $composableBuilder(column: $table.depthKm, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get eventAt =>
      $composableBuilder(column: $table.eventAt, builder: (column) => column);

  GeneratedColumn<int> get providerUpdatedAt => $composableBuilder(
    column: $table.providerUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retrievedAt => $composableBuilder(
    column: $table.retrievedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewStatus => $composableBuilder(
    column: $table.reviewStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$CachedEarthquakesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedEarthquakesTable,
          CachedEarthquake,
          $$CachedEarthquakesTableFilterComposer,
          $$CachedEarthquakesTableOrderingComposer,
          $$CachedEarthquakesTableAnnotationComposer,
          $$CachedEarthquakesTableCreateCompanionBuilder,
          $$CachedEarthquakesTableUpdateCompanionBuilder,
          (
            CachedEarthquake,
            BaseReferences<
              _$AppDatabase,
              $CachedEarthquakesTable,
              CachedEarthquake
            >,
          ),
          CachedEarthquake,
          PrefetchHooks Function()
        > {
  $$CachedEarthquakesTableTableManager(
    _$AppDatabase db,
    $CachedEarthquakesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedEarthquakesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedEarthquakesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedEarthquakesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> providerEventId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> place = const Value.absent(),
                Value<double> magnitude = const Value.absent(),
                Value<double> depthKm = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<int> eventAt = const Value.absent(),
                Value<int> providerUpdatedAt = const Value.absent(),
                Value<int> retrievedAt = const Value.absent(),
                Value<String?> reviewStatus = const Value.absent(),
                Value<String> sourceUrl = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedEarthquakesCompanion(
                id: id,
                provider: provider,
                providerEventId: providerEventId,
                kind: kind,
                title: title,
                place: place,
                magnitude: magnitude,
                depthKm: depthKm,
                latitude: latitude,
                longitude: longitude,
                eventAt: eventAt,
                providerUpdatedAt: providerUpdatedAt,
                retrievedAt: retrievedAt,
                reviewStatus: reviewStatus,
                sourceUrl: sourceUrl,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String provider,
                required String providerEventId,
                required String kind,
                required String title,
                required String place,
                required double magnitude,
                required double depthKm,
                required double latitude,
                required double longitude,
                required int eventAt,
                required int providerUpdatedAt,
                required int retrievedAt,
                Value<String?> reviewStatus = const Value.absent(),
                required String sourceUrl,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => CachedEarthquakesCompanion.insert(
                id: id,
                provider: provider,
                providerEventId: providerEventId,
                kind: kind,
                title: title,
                place: place,
                magnitude: magnitude,
                depthKm: depthKm,
                latitude: latitude,
                longitude: longitude,
                eventAt: eventAt,
                providerUpdatedAt: providerUpdatedAt,
                retrievedAt: retrievedAt,
                reviewStatus: reviewStatus,
                sourceUrl: sourceUrl,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedEarthquakesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedEarthquakesTable,
      CachedEarthquake,
      $$CachedEarthquakesTableFilterComposer,
      $$CachedEarthquakesTableOrderingComposer,
      $$CachedEarthquakesTableAnnotationComposer,
      $$CachedEarthquakesTableCreateCompanionBuilder,
      $$CachedEarthquakesTableUpdateCompanionBuilder,
      (
        CachedEarthquake,
        BaseReferences<
          _$AppDatabase,
          $CachedEarthquakesTable,
          CachedEarthquake
        >,
      ),
      CachedEarthquake,
      PrefetchHooks Function()
    >;
typedef $$AlertSyncMetadataTableCreateCompanionBuilder =
    AlertSyncMetadataCompanion Function({
      required String provider,
      required String dataStatus,
      required int lastSuccessfulRefreshAt,
      required int cachedAt,
      Value<int> rowid,
    });
typedef $$AlertSyncMetadataTableUpdateCompanionBuilder =
    AlertSyncMetadataCompanion Function({
      Value<String> provider,
      Value<String> dataStatus,
      Value<int> lastSuccessfulRefreshAt,
      Value<int> cachedAt,
      Value<int> rowid,
    });

class $$AlertSyncMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $AlertSyncMetadataTable> {
  $$AlertSyncMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataStatus => $composableBuilder(
    column: $table.dataStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSuccessfulRefreshAt => $composableBuilder(
    column: $table.lastSuccessfulRefreshAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlertSyncMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertSyncMetadataTable> {
  $$AlertSyncMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataStatus => $composableBuilder(
    column: $table.dataStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSuccessfulRefreshAt => $composableBuilder(
    column: $table.lastSuccessfulRefreshAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlertSyncMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertSyncMetadataTable> {
  $$AlertSyncMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get dataStatus => $composableBuilder(
    column: $table.dataStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSuccessfulRefreshAt => $composableBuilder(
    column: $table.lastSuccessfulRefreshAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$AlertSyncMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertSyncMetadataTable,
          AlertSyncMetadataData,
          $$AlertSyncMetadataTableFilterComposer,
          $$AlertSyncMetadataTableOrderingComposer,
          $$AlertSyncMetadataTableAnnotationComposer,
          $$AlertSyncMetadataTableCreateCompanionBuilder,
          $$AlertSyncMetadataTableUpdateCompanionBuilder,
          (
            AlertSyncMetadataData,
            BaseReferences<
              _$AppDatabase,
              $AlertSyncMetadataTable,
              AlertSyncMetadataData
            >,
          ),
          AlertSyncMetadataData,
          PrefetchHooks Function()
        > {
  $$AlertSyncMetadataTableTableManager(
    _$AppDatabase db,
    $AlertSyncMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertSyncMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertSyncMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertSyncMetadataTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> provider = const Value.absent(),
                Value<String> dataStatus = const Value.absent(),
                Value<int> lastSuccessfulRefreshAt = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertSyncMetadataCompanion(
                provider: provider,
                dataStatus: dataStatus,
                lastSuccessfulRefreshAt: lastSuccessfulRefreshAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String provider,
                required String dataStatus,
                required int lastSuccessfulRefreshAt,
                required int cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => AlertSyncMetadataCompanion.insert(
                provider: provider,
                dataStatus: dataStatus,
                lastSuccessfulRefreshAt: lastSuccessfulRefreshAt,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlertSyncMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertSyncMetadataTable,
      AlertSyncMetadataData,
      $$AlertSyncMetadataTableFilterComposer,
      $$AlertSyncMetadataTableOrderingComposer,
      $$AlertSyncMetadataTableAnnotationComposer,
      $$AlertSyncMetadataTableCreateCompanionBuilder,
      $$AlertSyncMetadataTableUpdateCompanionBuilder,
      (
        AlertSyncMetadataData,
        BaseReferences<
          _$AppDatabase,
          $AlertSyncMetadataTable,
          AlertSyncMetadataData
        >,
      ),
      AlertSyncMetadataData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedEarthquakesTableTableManager get cachedEarthquakes =>
      $$CachedEarthquakesTableTableManager(_db, _db.cachedEarthquakes);
  $$AlertSyncMetadataTableTableManager get alertSyncMetadata =>
      $$AlertSyncMetadataTableTableManager(_db, _db.alertSyncMetadata);
}
