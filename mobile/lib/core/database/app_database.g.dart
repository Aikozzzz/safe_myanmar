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

class $CachedShelterResponsesTable extends CachedShelterResponses
    with TableInfo<$CachedShelterResponsesTable, CachedShelterResponse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedShelterResponsesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataAtMeta = const VerificationMeta('dataAt');
  @override
  late final GeneratedColumn<int> dataAt = GeneratedColumn<int>(
    'data_at',
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
  List<GeneratedColumn> get $columns => [id, payload, dataAt, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_shelter_responses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedShelterResponse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('data_at')) {
      context.handle(
        _dataAtMeta,
        dataAt.isAcceptableOrUnknown(data['data_at']!, _dataAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dataAtMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedShelterResponse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedShelterResponse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      dataAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}data_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedShelterResponsesTable createAlias(String alias) {
    return $CachedShelterResponsesTable(attachedDatabase, alias);
  }
}

class CachedShelterResponse extends DataClass
    implements Insertable<CachedShelterResponse> {
  final int id;
  final String payload;
  final int dataAt;
  final int cachedAt;
  const CachedShelterResponse({
    required this.id,
    required this.payload,
    required this.dataAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payload'] = Variable<String>(payload);
    map['data_at'] = Variable<int>(dataAt);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  CachedShelterResponsesCompanion toCompanion(bool nullToAbsent) {
    return CachedShelterResponsesCompanion(
      id: Value(id),
      payload: Value(payload),
      dataAt: Value(dataAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedShelterResponse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedShelterResponse(
      id: serializer.fromJson<int>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      dataAt: serializer.fromJson<int>(json['dataAt']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payload': serializer.toJson<String>(payload),
      'dataAt': serializer.toJson<int>(dataAt),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  CachedShelterResponse copyWith({
    int? id,
    String? payload,
    int? dataAt,
    int? cachedAt,
  }) => CachedShelterResponse(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    dataAt: dataAt ?? this.dataAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedShelterResponse copyWithCompanion(
    CachedShelterResponsesCompanion data,
  ) {
    return CachedShelterResponse(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      dataAt: data.dataAt.present ? data.dataAt.value : this.dataAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedShelterResponse(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('dataAt: $dataAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, dataAt, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedShelterResponse &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.dataAt == this.dataAt &&
          other.cachedAt == this.cachedAt);
}

class CachedShelterResponsesCompanion
    extends UpdateCompanion<CachedShelterResponse> {
  final Value<int> id;
  final Value<String> payload;
  final Value<int> dataAt;
  final Value<int> cachedAt;
  const CachedShelterResponsesCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.dataAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedShelterResponsesCompanion.insert({
    this.id = const Value.absent(),
    required String payload,
    required int dataAt,
    required int cachedAt,
  }) : payload = Value(payload),
       dataAt = Value(dataAt),
       cachedAt = Value(cachedAt);
  static Insertable<CachedShelterResponse> custom({
    Expression<int>? id,
    Expression<String>? payload,
    Expression<int>? dataAt,
    Expression<int>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (dataAt != null) 'data_at': dataAt,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedShelterResponsesCompanion copyWith({
    Value<int>? id,
    Value<String>? payload,
    Value<int>? dataAt,
    Value<int>? cachedAt,
  }) {
    return CachedShelterResponsesCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      dataAt: dataAt ?? this.dataAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (dataAt.present) {
      map['data_at'] = Variable<int>(dataAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedShelterResponsesCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('dataAt: $dataAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedHazardResponsesTable extends CachedHazardResponses
    with TableInfo<$CachedHazardResponsesTable, CachedHazardResponse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedHazardResponsesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataAtMeta = const VerificationMeta('dataAt');
  @override
  late final GeneratedColumn<int> dataAt = GeneratedColumn<int>(
    'data_at',
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
  List<GeneratedColumn> get $columns => [id, payload, dataAt, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_hazard_responses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedHazardResponse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('data_at')) {
      context.handle(
        _dataAtMeta,
        dataAt.isAcceptableOrUnknown(data['data_at']!, _dataAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dataAtMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedHazardResponse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedHazardResponse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      dataAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}data_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedHazardResponsesTable createAlias(String alias) {
    return $CachedHazardResponsesTable(attachedDatabase, alias);
  }
}

class CachedHazardResponse extends DataClass
    implements Insertable<CachedHazardResponse> {
  final int id;
  final String payload;
  final int dataAt;
  final int cachedAt;
  const CachedHazardResponse({
    required this.id,
    required this.payload,
    required this.dataAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payload'] = Variable<String>(payload);
    map['data_at'] = Variable<int>(dataAt);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  CachedHazardResponsesCompanion toCompanion(bool nullToAbsent) {
    return CachedHazardResponsesCompanion(
      id: Value(id),
      payload: Value(payload),
      dataAt: Value(dataAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedHazardResponse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedHazardResponse(
      id: serializer.fromJson<int>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      dataAt: serializer.fromJson<int>(json['dataAt']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payload': serializer.toJson<String>(payload),
      'dataAt': serializer.toJson<int>(dataAt),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  CachedHazardResponse copyWith({
    int? id,
    String? payload,
    int? dataAt,
    int? cachedAt,
  }) => CachedHazardResponse(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    dataAt: dataAt ?? this.dataAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedHazardResponse copyWithCompanion(CachedHazardResponsesCompanion data) {
    return CachedHazardResponse(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      dataAt: data.dataAt.present ? data.dataAt.value : this.dataAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedHazardResponse(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('dataAt: $dataAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, dataAt, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedHazardResponse &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.dataAt == this.dataAt &&
          other.cachedAt == this.cachedAt);
}

class CachedHazardResponsesCompanion
    extends UpdateCompanion<CachedHazardResponse> {
  final Value<int> id;
  final Value<String> payload;
  final Value<int> dataAt;
  final Value<int> cachedAt;
  const CachedHazardResponsesCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.dataAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedHazardResponsesCompanion.insert({
    this.id = const Value.absent(),
    required String payload,
    required int dataAt,
    required int cachedAt,
  }) : payload = Value(payload),
       dataAt = Value(dataAt),
       cachedAt = Value(cachedAt);
  static Insertable<CachedHazardResponse> custom({
    Expression<int>? id,
    Expression<String>? payload,
    Expression<int>? dataAt,
    Expression<int>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (dataAt != null) 'data_at': dataAt,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedHazardResponsesCompanion copyWith({
    Value<int>? id,
    Value<String>? payload,
    Value<int>? dataAt,
    Value<int>? cachedAt,
  }) {
    return CachedHazardResponsesCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      dataAt: dataAt ?? this.dataAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (dataAt.present) {
      map['data_at'] = Variable<int>(dataAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedHazardResponsesCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('dataAt: $dataAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedRouteResponsesTable extends CachedRouteResponses
    with TableInfo<$CachedRouteResponsesTable, CachedRouteResponse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedRouteResponsesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<int> generatedAt = GeneratedColumn<int>(
    'generated_at',
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
  static const VerificationMeta _originLatitudeE5Meta = const VerificationMeta(
    'originLatitudeE5',
  );
  @override
  late final GeneratedColumn<int> originLatitudeE5 = GeneratedColumn<int>(
    'origin_latitude_e5',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originLongitudeE5Meta = const VerificationMeta(
    'originLongitudeE5',
  );
  @override
  late final GeneratedColumn<int> originLongitudeE5 = GeneratedColumn<int>(
    'origin_longitude_e5',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shelterIdMeta = const VerificationMeta(
    'shelterId',
  );
  @override
  late final GeneratedColumn<String> shelterId = GeneratedColumn<String>(
    'shelter_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _disasterTypeMeta = const VerificationMeta(
    'disasterType',
  );
  @override
  late final GeneratedColumn<String> disasterType = GeneratedColumn<String>(
    'disaster_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeProfileMeta = const VerificationMeta(
    'routeProfile',
  );
  @override
  late final GeneratedColumn<String> routeProfile = GeneratedColumn<String>(
    'route_profile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    payload,
    generatedAt,
    cachedAt,
    originLatitudeE5,
    originLongitudeE5,
    shelterId,
    disasterType,
    routeProfile,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_route_responses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedRouteResponse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('origin_latitude_e5')) {
      context.handle(
        _originLatitudeE5Meta,
        originLatitudeE5.isAcceptableOrUnknown(
          data['origin_latitude_e5']!,
          _originLatitudeE5Meta,
        ),
      );
    }
    if (data.containsKey('origin_longitude_e5')) {
      context.handle(
        _originLongitudeE5Meta,
        originLongitudeE5.isAcceptableOrUnknown(
          data['origin_longitude_e5']!,
          _originLongitudeE5Meta,
        ),
      );
    }
    if (data.containsKey('shelter_id')) {
      context.handle(
        _shelterIdMeta,
        shelterId.isAcceptableOrUnknown(data['shelter_id']!, _shelterIdMeta),
      );
    }
    if (data.containsKey('disaster_type')) {
      context.handle(
        _disasterTypeMeta,
        disasterType.isAcceptableOrUnknown(
          data['disaster_type']!,
          _disasterTypeMeta,
        ),
      );
    }
    if (data.containsKey('route_profile')) {
      context.handle(
        _routeProfileMeta,
        routeProfile.isAcceptableOrUnknown(
          data['route_profile']!,
          _routeProfileMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedRouteResponse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedRouteResponse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      generatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generated_at'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
      originLatitudeE5: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}origin_latitude_e5'],
      ),
      originLongitudeE5: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}origin_longitude_e5'],
      ),
      shelterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shelter_id'],
      ),
      disasterType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disaster_type'],
      ),
      routeProfile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_profile'],
      ),
    );
  }

  @override
  $CachedRouteResponsesTable createAlias(String alias) {
    return $CachedRouteResponsesTable(attachedDatabase, alias);
  }
}

class CachedRouteResponse extends DataClass
    implements Insertable<CachedRouteResponse> {
  final int id;
  final String payload;
  final int generatedAt;
  final int cachedAt;
  final int? originLatitudeE5;
  final int? originLongitudeE5;
  final String? shelterId;
  final String? disasterType;
  final String? routeProfile;
  const CachedRouteResponse({
    required this.id,
    required this.payload,
    required this.generatedAt,
    required this.cachedAt,
    this.originLatitudeE5,
    this.originLongitudeE5,
    this.shelterId,
    this.disasterType,
    this.routeProfile,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payload'] = Variable<String>(payload);
    map['generated_at'] = Variable<int>(generatedAt);
    map['cached_at'] = Variable<int>(cachedAt);
    if (!nullToAbsent || originLatitudeE5 != null) {
      map['origin_latitude_e5'] = Variable<int>(originLatitudeE5);
    }
    if (!nullToAbsent || originLongitudeE5 != null) {
      map['origin_longitude_e5'] = Variable<int>(originLongitudeE5);
    }
    if (!nullToAbsent || shelterId != null) {
      map['shelter_id'] = Variable<String>(shelterId);
    }
    if (!nullToAbsent || disasterType != null) {
      map['disaster_type'] = Variable<String>(disasterType);
    }
    if (!nullToAbsent || routeProfile != null) {
      map['route_profile'] = Variable<String>(routeProfile);
    }
    return map;
  }

  CachedRouteResponsesCompanion toCompanion(bool nullToAbsent) {
    return CachedRouteResponsesCompanion(
      id: Value(id),
      payload: Value(payload),
      generatedAt: Value(generatedAt),
      cachedAt: Value(cachedAt),
      originLatitudeE5: originLatitudeE5 == null && nullToAbsent
          ? const Value.absent()
          : Value(originLatitudeE5),
      originLongitudeE5: originLongitudeE5 == null && nullToAbsent
          ? const Value.absent()
          : Value(originLongitudeE5),
      shelterId: shelterId == null && nullToAbsent
          ? const Value.absent()
          : Value(shelterId),
      disasterType: disasterType == null && nullToAbsent
          ? const Value.absent()
          : Value(disasterType),
      routeProfile: routeProfile == null && nullToAbsent
          ? const Value.absent()
          : Value(routeProfile),
    );
  }

  factory CachedRouteResponse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedRouteResponse(
      id: serializer.fromJson<int>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      generatedAt: serializer.fromJson<int>(json['generatedAt']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
      originLatitudeE5: serializer.fromJson<int?>(json['originLatitudeE5']),
      originLongitudeE5: serializer.fromJson<int?>(json['originLongitudeE5']),
      shelterId: serializer.fromJson<String?>(json['shelterId']),
      disasterType: serializer.fromJson<String?>(json['disasterType']),
      routeProfile: serializer.fromJson<String?>(json['routeProfile']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payload': serializer.toJson<String>(payload),
      'generatedAt': serializer.toJson<int>(generatedAt),
      'cachedAt': serializer.toJson<int>(cachedAt),
      'originLatitudeE5': serializer.toJson<int?>(originLatitudeE5),
      'originLongitudeE5': serializer.toJson<int?>(originLongitudeE5),
      'shelterId': serializer.toJson<String?>(shelterId),
      'disasterType': serializer.toJson<String?>(disasterType),
      'routeProfile': serializer.toJson<String?>(routeProfile),
    };
  }

  CachedRouteResponse copyWith({
    int? id,
    String? payload,
    int? generatedAt,
    int? cachedAt,
    Value<int?> originLatitudeE5 = const Value.absent(),
    Value<int?> originLongitudeE5 = const Value.absent(),
    Value<String?> shelterId = const Value.absent(),
    Value<String?> disasterType = const Value.absent(),
    Value<String?> routeProfile = const Value.absent(),
  }) => CachedRouteResponse(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    generatedAt: generatedAt ?? this.generatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
    originLatitudeE5: originLatitudeE5.present
        ? originLatitudeE5.value
        : this.originLatitudeE5,
    originLongitudeE5: originLongitudeE5.present
        ? originLongitudeE5.value
        : this.originLongitudeE5,
    shelterId: shelterId.present ? shelterId.value : this.shelterId,
    disasterType: disasterType.present ? disasterType.value : this.disasterType,
    routeProfile: routeProfile.present ? routeProfile.value : this.routeProfile,
  );
  CachedRouteResponse copyWithCompanion(CachedRouteResponsesCompanion data) {
    return CachedRouteResponse(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      originLatitudeE5: data.originLatitudeE5.present
          ? data.originLatitudeE5.value
          : this.originLatitudeE5,
      originLongitudeE5: data.originLongitudeE5.present
          ? data.originLongitudeE5.value
          : this.originLongitudeE5,
      shelterId: data.shelterId.present ? data.shelterId.value : this.shelterId,
      disasterType: data.disasterType.present
          ? data.disasterType.value
          : this.disasterType,
      routeProfile: data.routeProfile.present
          ? data.routeProfile.value
          : this.routeProfile,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedRouteResponse(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('originLatitudeE5: $originLatitudeE5, ')
          ..write('originLongitudeE5: $originLongitudeE5, ')
          ..write('shelterId: $shelterId, ')
          ..write('disasterType: $disasterType, ')
          ..write('routeProfile: $routeProfile')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    payload,
    generatedAt,
    cachedAt,
    originLatitudeE5,
    originLongitudeE5,
    shelterId,
    disasterType,
    routeProfile,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedRouteResponse &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.generatedAt == this.generatedAt &&
          other.cachedAt == this.cachedAt &&
          other.originLatitudeE5 == this.originLatitudeE5 &&
          other.originLongitudeE5 == this.originLongitudeE5 &&
          other.shelterId == this.shelterId &&
          other.disasterType == this.disasterType &&
          other.routeProfile == this.routeProfile);
}

class CachedRouteResponsesCompanion
    extends UpdateCompanion<CachedRouteResponse> {
  final Value<int> id;
  final Value<String> payload;
  final Value<int> generatedAt;
  final Value<int> cachedAt;
  final Value<int?> originLatitudeE5;
  final Value<int?> originLongitudeE5;
  final Value<String?> shelterId;
  final Value<String?> disasterType;
  final Value<String?> routeProfile;
  const CachedRouteResponsesCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.originLatitudeE5 = const Value.absent(),
    this.originLongitudeE5 = const Value.absent(),
    this.shelterId = const Value.absent(),
    this.disasterType = const Value.absent(),
    this.routeProfile = const Value.absent(),
  });
  CachedRouteResponsesCompanion.insert({
    this.id = const Value.absent(),
    required String payload,
    required int generatedAt,
    required int cachedAt,
    this.originLatitudeE5 = const Value.absent(),
    this.originLongitudeE5 = const Value.absent(),
    this.shelterId = const Value.absent(),
    this.disasterType = const Value.absent(),
    this.routeProfile = const Value.absent(),
  }) : payload = Value(payload),
       generatedAt = Value(generatedAt),
       cachedAt = Value(cachedAt);
  static Insertable<CachedRouteResponse> custom({
    Expression<int>? id,
    Expression<String>? payload,
    Expression<int>? generatedAt,
    Expression<int>? cachedAt,
    Expression<int>? originLatitudeE5,
    Expression<int>? originLongitudeE5,
    Expression<String>? shelterId,
    Expression<String>? disasterType,
    Expression<String>? routeProfile,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (originLatitudeE5 != null) 'origin_latitude_e5': originLatitudeE5,
      if (originLongitudeE5 != null) 'origin_longitude_e5': originLongitudeE5,
      if (shelterId != null) 'shelter_id': shelterId,
      if (disasterType != null) 'disaster_type': disasterType,
      if (routeProfile != null) 'route_profile': routeProfile,
    });
  }

  CachedRouteResponsesCompanion copyWith({
    Value<int>? id,
    Value<String>? payload,
    Value<int>? generatedAt,
    Value<int>? cachedAt,
    Value<int?>? originLatitudeE5,
    Value<int?>? originLongitudeE5,
    Value<String?>? shelterId,
    Value<String?>? disasterType,
    Value<String?>? routeProfile,
  }) {
    return CachedRouteResponsesCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      generatedAt: generatedAt ?? this.generatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      originLatitudeE5: originLatitudeE5 ?? this.originLatitudeE5,
      originLongitudeE5: originLongitudeE5 ?? this.originLongitudeE5,
      shelterId: shelterId ?? this.shelterId,
      disasterType: disasterType ?? this.disasterType,
      routeProfile: routeProfile ?? this.routeProfile,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<int>(generatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (originLatitudeE5.present) {
      map['origin_latitude_e5'] = Variable<int>(originLatitudeE5.value);
    }
    if (originLongitudeE5.present) {
      map['origin_longitude_e5'] = Variable<int>(originLongitudeE5.value);
    }
    if (shelterId.present) {
      map['shelter_id'] = Variable<String>(shelterId.value);
    }
    if (disasterType.present) {
      map['disaster_type'] = Variable<String>(disasterType.value);
    }
    if (routeProfile.present) {
      map['route_profile'] = Variable<String>(routeProfile.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedRouteResponsesCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('originLatitudeE5: $originLatitudeE5, ')
          ..write('originLongitudeE5: $originLongitudeE5, ')
          ..write('shelterId: $shelterId, ')
          ..write('disasterType: $disasterType, ')
          ..write('routeProfile: $routeProfile')
          ..write(')'))
        .toString();
  }
}

class $EmergencyArticlesTable extends EmergencyArticles
    with TableInfo<$EmergencyArticlesTable, EmergencyArticleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmergencyArticlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentVersionMeta = const VerificationMeta(
    'contentVersion',
  );
  @override
  late final GeneratedColumn<int> contentVersion = GeneratedColumn<int>(
    'content_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleEnMeta = const VerificationMeta(
    'titleEn',
  );
  @override
  late final GeneratedColumn<String> titleEn = GeneratedColumn<String>(
    'title_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMyMeta = const VerificationMeta(
    'titleMy',
  );
  @override
  late final GeneratedColumn<String> titleMy = GeneratedColumn<String>(
    'title_my',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionEnMeta = const VerificationMeta(
    'questionEn',
  );
  @override
  late final GeneratedColumn<String> questionEn = GeneratedColumn<String>(
    'question_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionMyMeta = const VerificationMeta(
    'questionMy',
  );
  @override
  late final GeneratedColumn<String> questionMy = GeneratedColumn<String>(
    'question_my',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerEnMeta = const VerificationMeta(
    'answerEn',
  );
  @override
  late final GeneratedColumn<String> answerEn = GeneratedColumn<String>(
    'answer_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerMyMeta = const VerificationMeta(
    'answerMy',
  );
  @override
  late final GeneratedColumn<String> answerMy = GeneratedColumn<String>(
    'answer_my',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keywordsMeta = const VerificationMeta(
    'keywords',
  );
  @override
  late final GeneratedColumn<String> keywords = GeneratedColumn<String>(
    'keywords',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _sourceUpdatedAtMeta = const VerificationMeta(
    'sourceUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> sourceUpdatedAt = GeneratedColumn<int>(
    'source_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<int> reviewedAt = GeneratedColumn<int>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contentVersion,
    category,
    titleEn,
    titleMy,
    questionEn,
    questionMy,
    answerEn,
    answerMy,
    keywords,
    sourceName,
    sourceUrl,
    sourceUpdatedAt,
    reviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'emergency_articles';
  @override
  VerificationContext validateIntegrity(
    Insertable<EmergencyArticleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content_version')) {
      context.handle(
        _contentVersionMeta,
        contentVersion.isAcceptableOrUnknown(
          data['content_version']!,
          _contentVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentVersionMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('title_en')) {
      context.handle(
        _titleEnMeta,
        titleEn.isAcceptableOrUnknown(data['title_en']!, _titleEnMeta),
      );
    } else if (isInserting) {
      context.missing(_titleEnMeta);
    }
    if (data.containsKey('title_my')) {
      context.handle(
        _titleMyMeta,
        titleMy.isAcceptableOrUnknown(data['title_my']!, _titleMyMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMyMeta);
    }
    if (data.containsKey('question_en')) {
      context.handle(
        _questionEnMeta,
        questionEn.isAcceptableOrUnknown(data['question_en']!, _questionEnMeta),
      );
    } else if (isInserting) {
      context.missing(_questionEnMeta);
    }
    if (data.containsKey('question_my')) {
      context.handle(
        _questionMyMeta,
        questionMy.isAcceptableOrUnknown(data['question_my']!, _questionMyMeta),
      );
    } else if (isInserting) {
      context.missing(_questionMyMeta);
    }
    if (data.containsKey('answer_en')) {
      context.handle(
        _answerEnMeta,
        answerEn.isAcceptableOrUnknown(data['answer_en']!, _answerEnMeta),
      );
    } else if (isInserting) {
      context.missing(_answerEnMeta);
    }
    if (data.containsKey('answer_my')) {
      context.handle(
        _answerMyMeta,
        answerMy.isAcceptableOrUnknown(data['answer_my']!, _answerMyMeta),
      );
    } else if (isInserting) {
      context.missing(_answerMyMeta);
    }
    if (data.containsKey('keywords')) {
      context.handle(
        _keywordsMeta,
        keywords.isAcceptableOrUnknown(data['keywords']!, _keywordsMeta),
      );
    } else if (isInserting) {
      context.missing(_keywordsMeta);
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceNameMeta);
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceUrlMeta);
    }
    if (data.containsKey('source_updated_at')) {
      context.handle(
        _sourceUpdatedAtMeta,
        sourceUpdatedAt.isAcceptableOrUnknown(
          data['source_updated_at']!,
          _sourceUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmergencyArticleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmergencyArticleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}content_version'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      titleEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_en'],
      )!,
      titleMy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_my'],
      )!,
      questionEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_en'],
      )!,
      questionMy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_my'],
      )!,
      answerEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_en'],
      )!,
      answerMy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_my'],
      )!,
      keywords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keywords'],
      )!,
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      )!,
      sourceUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_updated_at'],
      ),
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reviewed_at'],
      )!,
    );
  }

  @override
  $EmergencyArticlesTable createAlias(String alias) {
    return $EmergencyArticlesTable(attachedDatabase, alias);
  }
}

class EmergencyArticleRow extends DataClass
    implements Insertable<EmergencyArticleRow> {
  final String id;
  final int contentVersion;
  final String category;
  final String titleEn;
  final String titleMy;
  final String questionEn;
  final String questionMy;
  final String answerEn;
  final String answerMy;
  final String keywords;
  final String sourceName;
  final String sourceUrl;
  final int? sourceUpdatedAt;
  final int reviewedAt;
  const EmergencyArticleRow({
    required this.id,
    required this.contentVersion,
    required this.category,
    required this.titleEn,
    required this.titleMy,
    required this.questionEn,
    required this.questionMy,
    required this.answerEn,
    required this.answerMy,
    required this.keywords,
    required this.sourceName,
    required this.sourceUrl,
    this.sourceUpdatedAt,
    required this.reviewedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['content_version'] = Variable<int>(contentVersion);
    map['category'] = Variable<String>(category);
    map['title_en'] = Variable<String>(titleEn);
    map['title_my'] = Variable<String>(titleMy);
    map['question_en'] = Variable<String>(questionEn);
    map['question_my'] = Variable<String>(questionMy);
    map['answer_en'] = Variable<String>(answerEn);
    map['answer_my'] = Variable<String>(answerMy);
    map['keywords'] = Variable<String>(keywords);
    map['source_name'] = Variable<String>(sourceName);
    map['source_url'] = Variable<String>(sourceUrl);
    if (!nullToAbsent || sourceUpdatedAt != null) {
      map['source_updated_at'] = Variable<int>(sourceUpdatedAt);
    }
    map['reviewed_at'] = Variable<int>(reviewedAt);
    return map;
  }

  EmergencyArticlesCompanion toCompanion(bool nullToAbsent) {
    return EmergencyArticlesCompanion(
      id: Value(id),
      contentVersion: Value(contentVersion),
      category: Value(category),
      titleEn: Value(titleEn),
      titleMy: Value(titleMy),
      questionEn: Value(questionEn),
      questionMy: Value(questionMy),
      answerEn: Value(answerEn),
      answerMy: Value(answerMy),
      keywords: Value(keywords),
      sourceName: Value(sourceName),
      sourceUrl: Value(sourceUrl),
      sourceUpdatedAt: sourceUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUpdatedAt),
      reviewedAt: Value(reviewedAt),
    );
  }

  factory EmergencyArticleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmergencyArticleRow(
      id: serializer.fromJson<String>(json['id']),
      contentVersion: serializer.fromJson<int>(json['contentVersion']),
      category: serializer.fromJson<String>(json['category']),
      titleEn: serializer.fromJson<String>(json['titleEn']),
      titleMy: serializer.fromJson<String>(json['titleMy']),
      questionEn: serializer.fromJson<String>(json['questionEn']),
      questionMy: serializer.fromJson<String>(json['questionMy']),
      answerEn: serializer.fromJson<String>(json['answerEn']),
      answerMy: serializer.fromJson<String>(json['answerMy']),
      keywords: serializer.fromJson<String>(json['keywords']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      sourceUrl: serializer.fromJson<String>(json['sourceUrl']),
      sourceUpdatedAt: serializer.fromJson<int?>(json['sourceUpdatedAt']),
      reviewedAt: serializer.fromJson<int>(json['reviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contentVersion': serializer.toJson<int>(contentVersion),
      'category': serializer.toJson<String>(category),
      'titleEn': serializer.toJson<String>(titleEn),
      'titleMy': serializer.toJson<String>(titleMy),
      'questionEn': serializer.toJson<String>(questionEn),
      'questionMy': serializer.toJson<String>(questionMy),
      'answerEn': serializer.toJson<String>(answerEn),
      'answerMy': serializer.toJson<String>(answerMy),
      'keywords': serializer.toJson<String>(keywords),
      'sourceName': serializer.toJson<String>(sourceName),
      'sourceUrl': serializer.toJson<String>(sourceUrl),
      'sourceUpdatedAt': serializer.toJson<int?>(sourceUpdatedAt),
      'reviewedAt': serializer.toJson<int>(reviewedAt),
    };
  }

  EmergencyArticleRow copyWith({
    String? id,
    int? contentVersion,
    String? category,
    String? titleEn,
    String? titleMy,
    String? questionEn,
    String? questionMy,
    String? answerEn,
    String? answerMy,
    String? keywords,
    String? sourceName,
    String? sourceUrl,
    Value<int?> sourceUpdatedAt = const Value.absent(),
    int? reviewedAt,
  }) => EmergencyArticleRow(
    id: id ?? this.id,
    contentVersion: contentVersion ?? this.contentVersion,
    category: category ?? this.category,
    titleEn: titleEn ?? this.titleEn,
    titleMy: titleMy ?? this.titleMy,
    questionEn: questionEn ?? this.questionEn,
    questionMy: questionMy ?? this.questionMy,
    answerEn: answerEn ?? this.answerEn,
    answerMy: answerMy ?? this.answerMy,
    keywords: keywords ?? this.keywords,
    sourceName: sourceName ?? this.sourceName,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    sourceUpdatedAt: sourceUpdatedAt.present
        ? sourceUpdatedAt.value
        : this.sourceUpdatedAt,
    reviewedAt: reviewedAt ?? this.reviewedAt,
  );
  EmergencyArticleRow copyWithCompanion(EmergencyArticlesCompanion data) {
    return EmergencyArticleRow(
      id: data.id.present ? data.id.value : this.id,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
      category: data.category.present ? data.category.value : this.category,
      titleEn: data.titleEn.present ? data.titleEn.value : this.titleEn,
      titleMy: data.titleMy.present ? data.titleMy.value : this.titleMy,
      questionEn: data.questionEn.present
          ? data.questionEn.value
          : this.questionEn,
      questionMy: data.questionMy.present
          ? data.questionMy.value
          : this.questionMy,
      answerEn: data.answerEn.present ? data.answerEn.value : this.answerEn,
      answerMy: data.answerMy.present ? data.answerMy.value : this.answerMy,
      keywords: data.keywords.present ? data.keywords.value : this.keywords,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      sourceUpdatedAt: data.sourceUpdatedAt.present
          ? data.sourceUpdatedAt.value
          : this.sourceUpdatedAt,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyArticleRow(')
          ..write('id: $id, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('category: $category, ')
          ..write('titleEn: $titleEn, ')
          ..write('titleMy: $titleMy, ')
          ..write('questionEn: $questionEn, ')
          ..write('questionMy: $questionMy, ')
          ..write('answerEn: $answerEn, ')
          ..write('answerMy: $answerMy, ')
          ..write('keywords: $keywords, ')
          ..write('sourceName: $sourceName, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceUpdatedAt: $sourceUpdatedAt, ')
          ..write('reviewedAt: $reviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contentVersion,
    category,
    titleEn,
    titleMy,
    questionEn,
    questionMy,
    answerEn,
    answerMy,
    keywords,
    sourceName,
    sourceUrl,
    sourceUpdatedAt,
    reviewedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmergencyArticleRow &&
          other.id == this.id &&
          other.contentVersion == this.contentVersion &&
          other.category == this.category &&
          other.titleEn == this.titleEn &&
          other.titleMy == this.titleMy &&
          other.questionEn == this.questionEn &&
          other.questionMy == this.questionMy &&
          other.answerEn == this.answerEn &&
          other.answerMy == this.answerMy &&
          other.keywords == this.keywords &&
          other.sourceName == this.sourceName &&
          other.sourceUrl == this.sourceUrl &&
          other.sourceUpdatedAt == this.sourceUpdatedAt &&
          other.reviewedAt == this.reviewedAt);
}

class EmergencyArticlesCompanion extends UpdateCompanion<EmergencyArticleRow> {
  final Value<String> id;
  final Value<int> contentVersion;
  final Value<String> category;
  final Value<String> titleEn;
  final Value<String> titleMy;
  final Value<String> questionEn;
  final Value<String> questionMy;
  final Value<String> answerEn;
  final Value<String> answerMy;
  final Value<String> keywords;
  final Value<String> sourceName;
  final Value<String> sourceUrl;
  final Value<int?> sourceUpdatedAt;
  final Value<int> reviewedAt;
  final Value<int> rowid;
  const EmergencyArticlesCompanion({
    this.id = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.category = const Value.absent(),
    this.titleEn = const Value.absent(),
    this.titleMy = const Value.absent(),
    this.questionEn = const Value.absent(),
    this.questionMy = const Value.absent(),
    this.answerEn = const Value.absent(),
    this.answerMy = const Value.absent(),
    this.keywords = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.sourceUpdatedAt = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmergencyArticlesCompanion.insert({
    required String id,
    required int contentVersion,
    required String category,
    required String titleEn,
    required String titleMy,
    required String questionEn,
    required String questionMy,
    required String answerEn,
    required String answerMy,
    required String keywords,
    required String sourceName,
    required String sourceUrl,
    this.sourceUpdatedAt = const Value.absent(),
    required int reviewedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contentVersion = Value(contentVersion),
       category = Value(category),
       titleEn = Value(titleEn),
       titleMy = Value(titleMy),
       questionEn = Value(questionEn),
       questionMy = Value(questionMy),
       answerEn = Value(answerEn),
       answerMy = Value(answerMy),
       keywords = Value(keywords),
       sourceName = Value(sourceName),
       sourceUrl = Value(sourceUrl),
       reviewedAt = Value(reviewedAt);
  static Insertable<EmergencyArticleRow> custom({
    Expression<String>? id,
    Expression<int>? contentVersion,
    Expression<String>? category,
    Expression<String>? titleEn,
    Expression<String>? titleMy,
    Expression<String>? questionEn,
    Expression<String>? questionMy,
    Expression<String>? answerEn,
    Expression<String>? answerMy,
    Expression<String>? keywords,
    Expression<String>? sourceName,
    Expression<String>? sourceUrl,
    Expression<int>? sourceUpdatedAt,
    Expression<int>? reviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contentVersion != null) 'content_version': contentVersion,
      if (category != null) 'category': category,
      if (titleEn != null) 'title_en': titleEn,
      if (titleMy != null) 'title_my': titleMy,
      if (questionEn != null) 'question_en': questionEn,
      if (questionMy != null) 'question_my': questionMy,
      if (answerEn != null) 'answer_en': answerEn,
      if (answerMy != null) 'answer_my': answerMy,
      if (keywords != null) 'keywords': keywords,
      if (sourceName != null) 'source_name': sourceName,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (sourceUpdatedAt != null) 'source_updated_at': sourceUpdatedAt,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmergencyArticlesCompanion copyWith({
    Value<String>? id,
    Value<int>? contentVersion,
    Value<String>? category,
    Value<String>? titleEn,
    Value<String>? titleMy,
    Value<String>? questionEn,
    Value<String>? questionMy,
    Value<String>? answerEn,
    Value<String>? answerMy,
    Value<String>? keywords,
    Value<String>? sourceName,
    Value<String>? sourceUrl,
    Value<int?>? sourceUpdatedAt,
    Value<int>? reviewedAt,
    Value<int>? rowid,
  }) {
    return EmergencyArticlesCompanion(
      id: id ?? this.id,
      contentVersion: contentVersion ?? this.contentVersion,
      category: category ?? this.category,
      titleEn: titleEn ?? this.titleEn,
      titleMy: titleMy ?? this.titleMy,
      questionEn: questionEn ?? this.questionEn,
      questionMy: questionMy ?? this.questionMy,
      answerEn: answerEn ?? this.answerEn,
      answerMy: answerMy ?? this.answerMy,
      keywords: keywords ?? this.keywords,
      sourceName: sourceName ?? this.sourceName,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceUpdatedAt: sourceUpdatedAt ?? this.sourceUpdatedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<int>(contentVersion.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (titleEn.present) {
      map['title_en'] = Variable<String>(titleEn.value);
    }
    if (titleMy.present) {
      map['title_my'] = Variable<String>(titleMy.value);
    }
    if (questionEn.present) {
      map['question_en'] = Variable<String>(questionEn.value);
    }
    if (questionMy.present) {
      map['question_my'] = Variable<String>(questionMy.value);
    }
    if (answerEn.present) {
      map['answer_en'] = Variable<String>(answerEn.value);
    }
    if (answerMy.present) {
      map['answer_my'] = Variable<String>(answerMy.value);
    }
    if (keywords.present) {
      map['keywords'] = Variable<String>(keywords.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (sourceUpdatedAt.present) {
      map['source_updated_at'] = Variable<int>(sourceUpdatedAt.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<int>(reviewedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmergencyArticlesCompanion(')
          ..write('id: $id, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('category: $category, ')
          ..write('titleEn: $titleEn, ')
          ..write('titleMy: $titleMy, ')
          ..write('questionEn: $questionEn, ')
          ..write('questionMy: $questionMy, ')
          ..write('answerEn: $answerEn, ')
          ..write('answerMy: $answerMy, ')
          ..write('keywords: $keywords, ')
          ..write('sourceName: $sourceName, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('sourceUpdatedAt: $sourceUpdatedAt, ')
          ..write('reviewedAt: $reviewedAt, ')
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
  late final $CachedShelterResponsesTable cachedShelterResponses =
      $CachedShelterResponsesTable(this);
  late final $CachedHazardResponsesTable cachedHazardResponses =
      $CachedHazardResponsesTable(this);
  late final $CachedRouteResponsesTable cachedRouteResponses =
      $CachedRouteResponsesTable(this);
  late final $EmergencyArticlesTable emergencyArticles =
      $EmergencyArticlesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedEarthquakes,
    alertSyncMetadata,
    cachedShelterResponses,
    cachedHazardResponses,
    cachedRouteResponses,
    emergencyArticles,
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
typedef $$CachedShelterResponsesTableCreateCompanionBuilder =
    CachedShelterResponsesCompanion Function({
      Value<int> id,
      required String payload,
      required int dataAt,
      required int cachedAt,
    });
typedef $$CachedShelterResponsesTableUpdateCompanionBuilder =
    CachedShelterResponsesCompanion Function({
      Value<int> id,
      Value<String> payload,
      Value<int> dataAt,
      Value<int> cachedAt,
    });

class $$CachedShelterResponsesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedShelterResponsesTable> {
  $$CachedShelterResponsesTableFilterComposer({
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

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dataAt => $composableBuilder(
    column: $table.dataAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedShelterResponsesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedShelterResponsesTable> {
  $$CachedShelterResponsesTableOrderingComposer({
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

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dataAt => $composableBuilder(
    column: $table.dataAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedShelterResponsesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedShelterResponsesTable> {
  $$CachedShelterResponsesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get dataAt =>
      $composableBuilder(column: $table.dataAt, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedShelterResponsesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedShelterResponsesTable,
          CachedShelterResponse,
          $$CachedShelterResponsesTableFilterComposer,
          $$CachedShelterResponsesTableOrderingComposer,
          $$CachedShelterResponsesTableAnnotationComposer,
          $$CachedShelterResponsesTableCreateCompanionBuilder,
          $$CachedShelterResponsesTableUpdateCompanionBuilder,
          (
            CachedShelterResponse,
            BaseReferences<
              _$AppDatabase,
              $CachedShelterResponsesTable,
              CachedShelterResponse
            >,
          ),
          CachedShelterResponse,
          PrefetchHooks Function()
        > {
  $$CachedShelterResponsesTableTableManager(
    _$AppDatabase db,
    $CachedShelterResponsesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedShelterResponsesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedShelterResponsesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedShelterResponsesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> dataAt = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
              }) => CachedShelterResponsesCompanion(
                id: id,
                payload: payload,
                dataAt: dataAt,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String payload,
                required int dataAt,
                required int cachedAt,
              }) => CachedShelterResponsesCompanion.insert(
                id: id,
                payload: payload,
                dataAt: dataAt,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedShelterResponsesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedShelterResponsesTable,
      CachedShelterResponse,
      $$CachedShelterResponsesTableFilterComposer,
      $$CachedShelterResponsesTableOrderingComposer,
      $$CachedShelterResponsesTableAnnotationComposer,
      $$CachedShelterResponsesTableCreateCompanionBuilder,
      $$CachedShelterResponsesTableUpdateCompanionBuilder,
      (
        CachedShelterResponse,
        BaseReferences<
          _$AppDatabase,
          $CachedShelterResponsesTable,
          CachedShelterResponse
        >,
      ),
      CachedShelterResponse,
      PrefetchHooks Function()
    >;
typedef $$CachedHazardResponsesTableCreateCompanionBuilder =
    CachedHazardResponsesCompanion Function({
      Value<int> id,
      required String payload,
      required int dataAt,
      required int cachedAt,
    });
typedef $$CachedHazardResponsesTableUpdateCompanionBuilder =
    CachedHazardResponsesCompanion Function({
      Value<int> id,
      Value<String> payload,
      Value<int> dataAt,
      Value<int> cachedAt,
    });

class $$CachedHazardResponsesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedHazardResponsesTable> {
  $$CachedHazardResponsesTableFilterComposer({
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

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dataAt => $composableBuilder(
    column: $table.dataAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedHazardResponsesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedHazardResponsesTable> {
  $$CachedHazardResponsesTableOrderingComposer({
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

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dataAt => $composableBuilder(
    column: $table.dataAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedHazardResponsesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedHazardResponsesTable> {
  $$CachedHazardResponsesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get dataAt =>
      $composableBuilder(column: $table.dataAt, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedHazardResponsesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedHazardResponsesTable,
          CachedHazardResponse,
          $$CachedHazardResponsesTableFilterComposer,
          $$CachedHazardResponsesTableOrderingComposer,
          $$CachedHazardResponsesTableAnnotationComposer,
          $$CachedHazardResponsesTableCreateCompanionBuilder,
          $$CachedHazardResponsesTableUpdateCompanionBuilder,
          (
            CachedHazardResponse,
            BaseReferences<
              _$AppDatabase,
              $CachedHazardResponsesTable,
              CachedHazardResponse
            >,
          ),
          CachedHazardResponse,
          PrefetchHooks Function()
        > {
  $$CachedHazardResponsesTableTableManager(
    _$AppDatabase db,
    $CachedHazardResponsesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedHazardResponsesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedHazardResponsesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedHazardResponsesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> dataAt = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
              }) => CachedHazardResponsesCompanion(
                id: id,
                payload: payload,
                dataAt: dataAt,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String payload,
                required int dataAt,
                required int cachedAt,
              }) => CachedHazardResponsesCompanion.insert(
                id: id,
                payload: payload,
                dataAt: dataAt,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedHazardResponsesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedHazardResponsesTable,
      CachedHazardResponse,
      $$CachedHazardResponsesTableFilterComposer,
      $$CachedHazardResponsesTableOrderingComposer,
      $$CachedHazardResponsesTableAnnotationComposer,
      $$CachedHazardResponsesTableCreateCompanionBuilder,
      $$CachedHazardResponsesTableUpdateCompanionBuilder,
      (
        CachedHazardResponse,
        BaseReferences<
          _$AppDatabase,
          $CachedHazardResponsesTable,
          CachedHazardResponse
        >,
      ),
      CachedHazardResponse,
      PrefetchHooks Function()
    >;
typedef $$CachedRouteResponsesTableCreateCompanionBuilder =
    CachedRouteResponsesCompanion Function({
      Value<int> id,
      required String payload,
      required int generatedAt,
      required int cachedAt,
      Value<int?> originLatitudeE5,
      Value<int?> originLongitudeE5,
      Value<String?> shelterId,
      Value<String?> disasterType,
      Value<String?> routeProfile,
    });
typedef $$CachedRouteResponsesTableUpdateCompanionBuilder =
    CachedRouteResponsesCompanion Function({
      Value<int> id,
      Value<String> payload,
      Value<int> generatedAt,
      Value<int> cachedAt,
      Value<int?> originLatitudeE5,
      Value<int?> originLongitudeE5,
      Value<String?> shelterId,
      Value<String?> disasterType,
      Value<String?> routeProfile,
    });

class $$CachedRouteResponsesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedRouteResponsesTable> {
  $$CachedRouteResponsesTableFilterComposer({
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

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originLatitudeE5 => $composableBuilder(
    column: $table.originLatitudeE5,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originLongitudeE5 => $composableBuilder(
    column: $table.originLongitudeE5,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shelterId => $composableBuilder(
    column: $table.shelterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get disasterType => $composableBuilder(
    column: $table.disasterType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeProfile => $composableBuilder(
    column: $table.routeProfile,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedRouteResponsesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedRouteResponsesTable> {
  $$CachedRouteResponsesTableOrderingComposer({
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

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originLatitudeE5 => $composableBuilder(
    column: $table.originLatitudeE5,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originLongitudeE5 => $composableBuilder(
    column: $table.originLongitudeE5,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shelterId => $composableBuilder(
    column: $table.shelterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get disasterType => $composableBuilder(
    column: $table.disasterType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeProfile => $composableBuilder(
    column: $table.routeProfile,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedRouteResponsesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedRouteResponsesTable> {
  $$CachedRouteResponsesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<int> get originLatitudeE5 => $composableBuilder(
    column: $table.originLatitudeE5,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originLongitudeE5 => $composableBuilder(
    column: $table.originLongitudeE5,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shelterId =>
      $composableBuilder(column: $table.shelterId, builder: (column) => column);

  GeneratedColumn<String> get disasterType => $composableBuilder(
    column: $table.disasterType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get routeProfile => $composableBuilder(
    column: $table.routeProfile,
    builder: (column) => column,
  );
}

class $$CachedRouteResponsesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedRouteResponsesTable,
          CachedRouteResponse,
          $$CachedRouteResponsesTableFilterComposer,
          $$CachedRouteResponsesTableOrderingComposer,
          $$CachedRouteResponsesTableAnnotationComposer,
          $$CachedRouteResponsesTableCreateCompanionBuilder,
          $$CachedRouteResponsesTableUpdateCompanionBuilder,
          (
            CachedRouteResponse,
            BaseReferences<
              _$AppDatabase,
              $CachedRouteResponsesTable,
              CachedRouteResponse
            >,
          ),
          CachedRouteResponse,
          PrefetchHooks Function()
        > {
  $$CachedRouteResponsesTableTableManager(
    _$AppDatabase db,
    $CachedRouteResponsesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedRouteResponsesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedRouteResponsesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedRouteResponsesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> generatedAt = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int?> originLatitudeE5 = const Value.absent(),
                Value<int?> originLongitudeE5 = const Value.absent(),
                Value<String?> shelterId = const Value.absent(),
                Value<String?> disasterType = const Value.absent(),
                Value<String?> routeProfile = const Value.absent(),
              }) => CachedRouteResponsesCompanion(
                id: id,
                payload: payload,
                generatedAt: generatedAt,
                cachedAt: cachedAt,
                originLatitudeE5: originLatitudeE5,
                originLongitudeE5: originLongitudeE5,
                shelterId: shelterId,
                disasterType: disasterType,
                routeProfile: routeProfile,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String payload,
                required int generatedAt,
                required int cachedAt,
                Value<int?> originLatitudeE5 = const Value.absent(),
                Value<int?> originLongitudeE5 = const Value.absent(),
                Value<String?> shelterId = const Value.absent(),
                Value<String?> disasterType = const Value.absent(),
                Value<String?> routeProfile = const Value.absent(),
              }) => CachedRouteResponsesCompanion.insert(
                id: id,
                payload: payload,
                generatedAt: generatedAt,
                cachedAt: cachedAt,
                originLatitudeE5: originLatitudeE5,
                originLongitudeE5: originLongitudeE5,
                shelterId: shelterId,
                disasterType: disasterType,
                routeProfile: routeProfile,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedRouteResponsesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedRouteResponsesTable,
      CachedRouteResponse,
      $$CachedRouteResponsesTableFilterComposer,
      $$CachedRouteResponsesTableOrderingComposer,
      $$CachedRouteResponsesTableAnnotationComposer,
      $$CachedRouteResponsesTableCreateCompanionBuilder,
      $$CachedRouteResponsesTableUpdateCompanionBuilder,
      (
        CachedRouteResponse,
        BaseReferences<
          _$AppDatabase,
          $CachedRouteResponsesTable,
          CachedRouteResponse
        >,
      ),
      CachedRouteResponse,
      PrefetchHooks Function()
    >;
typedef $$EmergencyArticlesTableCreateCompanionBuilder =
    EmergencyArticlesCompanion Function({
      required String id,
      required int contentVersion,
      required String category,
      required String titleEn,
      required String titleMy,
      required String questionEn,
      required String questionMy,
      required String answerEn,
      required String answerMy,
      required String keywords,
      required String sourceName,
      required String sourceUrl,
      Value<int?> sourceUpdatedAt,
      required int reviewedAt,
      Value<int> rowid,
    });
typedef $$EmergencyArticlesTableUpdateCompanionBuilder =
    EmergencyArticlesCompanion Function({
      Value<String> id,
      Value<int> contentVersion,
      Value<String> category,
      Value<String> titleEn,
      Value<String> titleMy,
      Value<String> questionEn,
      Value<String> questionMy,
      Value<String> answerEn,
      Value<String> answerMy,
      Value<String> keywords,
      Value<String> sourceName,
      Value<String> sourceUrl,
      Value<int?> sourceUpdatedAt,
      Value<int> reviewedAt,
      Value<int> rowid,
    });

class $$EmergencyArticlesTableFilterComposer
    extends Composer<_$AppDatabase, $EmergencyArticlesTable> {
  $$EmergencyArticlesTableFilterComposer({
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

  ColumnFilters<int> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleEn => $composableBuilder(
    column: $table.titleEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleMy => $composableBuilder(
    column: $table.titleMy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionEn => $composableBuilder(
    column: $table.questionEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionMy => $composableBuilder(
    column: $table.questionMy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerEn => $composableBuilder(
    column: $table.answerEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerMy => $composableBuilder(
    column: $table.answerMy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keywords => $composableBuilder(
    column: $table.keywords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceUpdatedAt => $composableBuilder(
    column: $table.sourceUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EmergencyArticlesTableOrderingComposer
    extends Composer<_$AppDatabase, $EmergencyArticlesTable> {
  $$EmergencyArticlesTableOrderingComposer({
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

  ColumnOrderings<int> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleEn => $composableBuilder(
    column: $table.titleEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleMy => $composableBuilder(
    column: $table.titleMy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionEn => $composableBuilder(
    column: $table.questionEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionMy => $composableBuilder(
    column: $table.questionMy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerEn => $composableBuilder(
    column: $table.answerEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerMy => $composableBuilder(
    column: $table.answerMy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keywords => $composableBuilder(
    column: $table.keywords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceUpdatedAt => $composableBuilder(
    column: $table.sourceUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmergencyArticlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmergencyArticlesTable> {
  $$EmergencyArticlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get titleEn =>
      $composableBuilder(column: $table.titleEn, builder: (column) => column);

  GeneratedColumn<String> get titleMy =>
      $composableBuilder(column: $table.titleMy, builder: (column) => column);

  GeneratedColumn<String> get questionEn => $composableBuilder(
    column: $table.questionEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionMy => $composableBuilder(
    column: $table.questionMy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answerEn =>
      $composableBuilder(column: $table.answerEn, builder: (column) => column);

  GeneratedColumn<String> get answerMy =>
      $composableBuilder(column: $table.answerMy, builder: (column) => column);

  GeneratedColumn<String> get keywords =>
      $composableBuilder(column: $table.keywords, builder: (column) => column);

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<int> get sourceUpdatedAt => $composableBuilder(
    column: $table.sourceUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );
}

class $$EmergencyArticlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmergencyArticlesTable,
          EmergencyArticleRow,
          $$EmergencyArticlesTableFilterComposer,
          $$EmergencyArticlesTableOrderingComposer,
          $$EmergencyArticlesTableAnnotationComposer,
          $$EmergencyArticlesTableCreateCompanionBuilder,
          $$EmergencyArticlesTableUpdateCompanionBuilder,
          (
            EmergencyArticleRow,
            BaseReferences<
              _$AppDatabase,
              $EmergencyArticlesTable,
              EmergencyArticleRow
            >,
          ),
          EmergencyArticleRow,
          PrefetchHooks Function()
        > {
  $$EmergencyArticlesTableTableManager(
    _$AppDatabase db,
    $EmergencyArticlesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmergencyArticlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmergencyArticlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmergencyArticlesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> contentVersion = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> titleEn = const Value.absent(),
                Value<String> titleMy = const Value.absent(),
                Value<String> questionEn = const Value.absent(),
                Value<String> questionMy = const Value.absent(),
                Value<String> answerEn = const Value.absent(),
                Value<String> answerMy = const Value.absent(),
                Value<String> keywords = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<String> sourceUrl = const Value.absent(),
                Value<int?> sourceUpdatedAt = const Value.absent(),
                Value<int> reviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EmergencyArticlesCompanion(
                id: id,
                contentVersion: contentVersion,
                category: category,
                titleEn: titleEn,
                titleMy: titleMy,
                questionEn: questionEn,
                questionMy: questionMy,
                answerEn: answerEn,
                answerMy: answerMy,
                keywords: keywords,
                sourceName: sourceName,
                sourceUrl: sourceUrl,
                sourceUpdatedAt: sourceUpdatedAt,
                reviewedAt: reviewedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int contentVersion,
                required String category,
                required String titleEn,
                required String titleMy,
                required String questionEn,
                required String questionMy,
                required String answerEn,
                required String answerMy,
                required String keywords,
                required String sourceName,
                required String sourceUrl,
                Value<int?> sourceUpdatedAt = const Value.absent(),
                required int reviewedAt,
                Value<int> rowid = const Value.absent(),
              }) => EmergencyArticlesCompanion.insert(
                id: id,
                contentVersion: contentVersion,
                category: category,
                titleEn: titleEn,
                titleMy: titleMy,
                questionEn: questionEn,
                questionMy: questionMy,
                answerEn: answerEn,
                answerMy: answerMy,
                keywords: keywords,
                sourceName: sourceName,
                sourceUrl: sourceUrl,
                sourceUpdatedAt: sourceUpdatedAt,
                reviewedAt: reviewedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EmergencyArticlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmergencyArticlesTable,
      EmergencyArticleRow,
      $$EmergencyArticlesTableFilterComposer,
      $$EmergencyArticlesTableOrderingComposer,
      $$EmergencyArticlesTableAnnotationComposer,
      $$EmergencyArticlesTableCreateCompanionBuilder,
      $$EmergencyArticlesTableUpdateCompanionBuilder,
      (
        EmergencyArticleRow,
        BaseReferences<
          _$AppDatabase,
          $EmergencyArticlesTable,
          EmergencyArticleRow
        >,
      ),
      EmergencyArticleRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedEarthquakesTableTableManager get cachedEarthquakes =>
      $$CachedEarthquakesTableTableManager(_db, _db.cachedEarthquakes);
  $$AlertSyncMetadataTableTableManager get alertSyncMetadata =>
      $$AlertSyncMetadataTableTableManager(_db, _db.alertSyncMetadata);
  $$CachedShelterResponsesTableTableManager get cachedShelterResponses =>
      $$CachedShelterResponsesTableTableManager(
        _db,
        _db.cachedShelterResponses,
      );
  $$CachedHazardResponsesTableTableManager get cachedHazardResponses =>
      $$CachedHazardResponsesTableTableManager(_db, _db.cachedHazardResponses);
  $$CachedRouteResponsesTableTableManager get cachedRouteResponses =>
      $$CachedRouteResponsesTableTableManager(_db, _db.cachedRouteResponses);
  $$EmergencyArticlesTableTableManager get emergencyArticles =>
      $$EmergencyArticlesTableTableManager(_db, _db.emergencyArticles);
}
