// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $VendorsTable extends Vendors with TableInfo<$VendorsTable, Vendor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VendorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _vendorIdMeta =
      const VerificationMeta('vendorId');
  @override
  late final GeneratedColumn<String> vendorId = GeneratedColumn<String>(
      'vendor_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _vendorNameMeta =
      const VerificationMeta('vendorName');
  @override
  late final GeneratedColumn<String> vendorName = GeneratedColumn<String>(
      'vendor_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vendorDescriptionMeta =
      const VerificationMeta('vendorDescription');
  @override
  late final GeneratedColumn<String> vendorDescription =
      GeneratedColumn<String>('vendor_description', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bannerUrlMeta =
      const VerificationMeta('bannerUrl');
  @override
  late final GeneratedColumn<String> bannerUrl = GeneratedColumn<String>(
      'banner_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns =>
      [vendorId, vendorName, vendorDescription, bannerUrl, active];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vendors';
  @override
  VerificationContext validateIntegrity(Insertable<Vendor> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('vendor_id')) {
      context.handle(_vendorIdMeta,
          vendorId.isAcceptableOrUnknown(data['vendor_id']!, _vendorIdMeta));
    } else if (isInserting) {
      context.missing(_vendorIdMeta);
    }
    if (data.containsKey('vendor_name')) {
      context.handle(
          _vendorNameMeta,
          vendorName.isAcceptableOrUnknown(
              data['vendor_name']!, _vendorNameMeta));
    } else if (isInserting) {
      context.missing(_vendorNameMeta);
    }
    if (data.containsKey('vendor_description')) {
      context.handle(
          _vendorDescriptionMeta,
          vendorDescription.isAcceptableOrUnknown(
              data['vendor_description']!, _vendorDescriptionMeta));
    } else if (isInserting) {
      context.missing(_vendorDescriptionMeta);
    }
    if (data.containsKey('banner_url')) {
      context.handle(_bannerUrlMeta,
          bannerUrl.isAcceptableOrUnknown(data['banner_url']!, _bannerUrlMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {vendorId};
  @override
  Vendor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Vendor(
      vendorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vendor_id'])!,
      vendorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vendor_name'])!,
      vendorDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}vendor_description'])!,
      bannerUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}banner_url']),
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
    );
  }

  @override
  $VendorsTable createAlias(String alias) {
    return $VendorsTable(attachedDatabase, alias);
  }
}

class Vendor extends DataClass implements Insertable<Vendor> {
  final String vendorId;
  final String vendorName;
  final String vendorDescription;
  final String? bannerUrl;
  final bool active;
  const Vendor(
      {required this.vendorId,
      required this.vendorName,
      required this.vendorDescription,
      this.bannerUrl,
      required this.active});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['vendor_id'] = Variable<String>(vendorId);
    map['vendor_name'] = Variable<String>(vendorName);
    map['vendor_description'] = Variable<String>(vendorDescription);
    if (!nullToAbsent || bannerUrl != null) {
      map['banner_url'] = Variable<String>(bannerUrl);
    }
    map['active'] = Variable<bool>(active);
    return map;
  }

  VendorsCompanion toCompanion(bool nullToAbsent) {
    return VendorsCompanion(
      vendorId: Value(vendorId),
      vendorName: Value(vendorName),
      vendorDescription: Value(vendorDescription),
      bannerUrl: bannerUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(bannerUrl),
      active: Value(active),
    );
  }

  factory Vendor.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Vendor(
      vendorId: serializer.fromJson<String>(json['vendorId']),
      vendorName: serializer.fromJson<String>(json['vendorName']),
      vendorDescription: serializer.fromJson<String>(json['vendorDescription']),
      bannerUrl: serializer.fromJson<String?>(json['bannerUrl']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'vendorId': serializer.toJson<String>(vendorId),
      'vendorName': serializer.toJson<String>(vendorName),
      'vendorDescription': serializer.toJson<String>(vendorDescription),
      'bannerUrl': serializer.toJson<String?>(bannerUrl),
      'active': serializer.toJson<bool>(active),
    };
  }

  Vendor copyWith(
          {String? vendorId,
          String? vendorName,
          String? vendorDescription,
          Value<String?> bannerUrl = const Value.absent(),
          bool? active}) =>
      Vendor(
        vendorId: vendorId ?? this.vendorId,
        vendorName: vendorName ?? this.vendorName,
        vendorDescription: vendorDescription ?? this.vendorDescription,
        bannerUrl: bannerUrl.present ? bannerUrl.value : this.bannerUrl,
        active: active ?? this.active,
      );
  @override
  String toString() {
    return (StringBuffer('Vendor(')
          ..write('vendorId: $vendorId, ')
          ..write('vendorName: $vendorName, ')
          ..write('vendorDescription: $vendorDescription, ')
          ..write('bannerUrl: $bannerUrl, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(vendorId, vendorName, vendorDescription, bannerUrl, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Vendor &&
          other.vendorId == this.vendorId &&
          other.vendorName == this.vendorName &&
          other.vendorDescription == this.vendorDescription &&
          other.bannerUrl == this.bannerUrl &&
          other.active == this.active);
}

class VendorsCompanion extends UpdateCompanion<Vendor> {
  final Value<String> vendorId;
  final Value<String> vendorName;
  final Value<String> vendorDescription;
  final Value<String?> bannerUrl;
  final Value<bool> active;
  final Value<int> rowid;
  const VendorsCompanion({
    this.vendorId = const Value.absent(),
    this.vendorName = const Value.absent(),
    this.vendorDescription = const Value.absent(),
    this.bannerUrl = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VendorsCompanion.insert({
    required String vendorId,
    required String vendorName,
    required String vendorDescription,
    this.bannerUrl = const Value.absent(),
    required bool active,
    this.rowid = const Value.absent(),
  })  : vendorId = Value(vendorId),
        vendorName = Value(vendorName),
        vendorDescription = Value(vendorDescription),
        active = Value(active);
  static Insertable<Vendor> custom({
    Expression<String>? vendorId,
    Expression<String>? vendorName,
    Expression<String>? vendorDescription,
    Expression<String>? bannerUrl,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (vendorId != null) 'vendor_id': vendorId,
      if (vendorName != null) 'vendor_name': vendorName,
      if (vendorDescription != null) 'vendor_description': vendorDescription,
      if (bannerUrl != null) 'banner_url': bannerUrl,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VendorsCompanion copyWith(
      {Value<String>? vendorId,
      Value<String>? vendorName,
      Value<String>? vendorDescription,
      Value<String?>? bannerUrl,
      Value<bool>? active,
      Value<int>? rowid}) {
    return VendorsCompanion(
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorDescription: vendorDescription ?? this.vendorDescription,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      active: active ?? this.active,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (vendorId.present) {
      map['vendor_id'] = Variable<String>(vendorId.value);
    }
    if (vendorName.present) {
      map['vendor_name'] = Variable<String>(vendorName.value);
    }
    if (vendorDescription.present) {
      map['vendor_description'] = Variable<String>(vendorDescription.value);
    }
    if (bannerUrl.present) {
      map['banner_url'] = Variable<String>(bannerUrl.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VendorsCompanion(')
          ..write('vendorId: $vendorId, ')
          ..write('vendorName: $vendorName, ')
          ..write('vendorDescription: $vendorDescription, ')
          ..write('bannerUrl: $bannerUrl, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SupportedLocalesTable extends SupportedLocales
    with TableInfo<$SupportedLocalesTable, SupportedLocale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SupportedLocalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
      'locale', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _localeNameMeta =
      const VerificationMeta('localeName');
  @override
  late final GeneratedColumn<String> localeName = GeneratedColumn<String>(
      'locale_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [locale, localeName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'supported_locales';
  @override
  VerificationContext validateIntegrity(Insertable<SupportedLocale> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('locale')) {
      context.handle(_localeMeta,
          locale.isAcceptableOrUnknown(data['locale']!, _localeMeta));
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    if (data.containsKey('locale_name')) {
      context.handle(
          _localeNameMeta,
          localeName.isAcceptableOrUnknown(
              data['locale_name']!, _localeNameMeta));
    } else if (isInserting) {
      context.missing(_localeNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {locale};
  @override
  SupportedLocale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SupportedLocale(
      locale: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}locale'])!,
      localeName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}locale_name'])!,
    );
  }

  @override
  $SupportedLocalesTable createAlias(String alias) {
    return $SupportedLocalesTable(attachedDatabase, alias);
  }
}

class SupportedLocale extends DataClass implements Insertable<SupportedLocale> {
  final String locale;
  final String localeName;
  const SupportedLocale({required this.locale, required this.localeName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['locale'] = Variable<String>(locale);
    map['locale_name'] = Variable<String>(localeName);
    return map;
  }

  SupportedLocalesCompanion toCompanion(bool nullToAbsent) {
    return SupportedLocalesCompanion(
      locale: Value(locale),
      localeName: Value(localeName),
    );
  }

  factory SupportedLocale.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SupportedLocale(
      locale: serializer.fromJson<String>(json['locale']),
      localeName: serializer.fromJson<String>(json['localeName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'locale': serializer.toJson<String>(locale),
      'localeName': serializer.toJson<String>(localeName),
    };
  }

  SupportedLocale copyWith({String? locale, String? localeName}) =>
      SupportedLocale(
        locale: locale ?? this.locale,
        localeName: localeName ?? this.localeName,
      );
  @override
  String toString() {
    return (StringBuffer('SupportedLocale(')
          ..write('locale: $locale, ')
          ..write('localeName: $localeName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(locale, localeName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupportedLocale &&
          other.locale == this.locale &&
          other.localeName == this.localeName);
}

class SupportedLocalesCompanion extends UpdateCompanion<SupportedLocale> {
  final Value<String> locale;
  final Value<String> localeName;
  final Value<int> rowid;
  const SupportedLocalesCompanion({
    this.locale = const Value.absent(),
    this.localeName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SupportedLocalesCompanion.insert({
    required String locale,
    required String localeName,
    this.rowid = const Value.absent(),
  })  : locale = Value(locale),
        localeName = Value(localeName);
  static Insertable<SupportedLocale> custom({
    Expression<String>? locale,
    Expression<String>? localeName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (locale != null) 'locale': locale,
      if (localeName != null) 'locale_name': localeName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SupportedLocalesCompanion copyWith(
      {Value<String>? locale, Value<String>? localeName, Value<int>? rowid}) {
    return SupportedLocalesCompanion(
      locale: locale ?? this.locale,
      localeName: localeName ?? this.localeName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (localeName.present) {
      map['locale_name'] = Variable<String>(localeName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SupportedLocalesCompanion(')
          ..write('locale: $locale, ')
          ..write('localeName: $localeName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BrewingMethodsTable extends BrewingMethods
    with TableInfo<$BrewingMethodsTable, BrewingMethod> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrewingMethodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _brewingMethodIdMeta =
      const VerificationMeta('brewingMethodId');
  @override
  late final GeneratedColumn<String> brewingMethodId = GeneratedColumn<String>(
      'brewing_method_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _brewingMethodMeta =
      const VerificationMeta('brewingMethod');
  @override
  late final GeneratedColumn<String> brewingMethod = GeneratedColumn<String>(
      'brewing_method', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [brewingMethodId, brewingMethod];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'brewing_methods';
  @override
  VerificationContext validateIntegrity(Insertable<BrewingMethod> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('brewing_method_id')) {
      context.handle(
          _brewingMethodIdMeta,
          brewingMethodId.isAcceptableOrUnknown(
              data['brewing_method_id']!, _brewingMethodIdMeta));
    } else if (isInserting) {
      context.missing(_brewingMethodIdMeta);
    }
    if (data.containsKey('brewing_method')) {
      context.handle(
          _brewingMethodMeta,
          brewingMethod.isAcceptableOrUnknown(
              data['brewing_method']!, _brewingMethodMeta));
    } else if (isInserting) {
      context.missing(_brewingMethodMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {brewingMethodId};
  @override
  BrewingMethod map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BrewingMethod(
      brewingMethodId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}brewing_method_id'])!,
      brewingMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}brewing_method'])!,
    );
  }

  @override
  $BrewingMethodsTable createAlias(String alias) {
    return $BrewingMethodsTable(attachedDatabase, alias);
  }
}

class BrewingMethod extends DataClass implements Insertable<BrewingMethod> {
  final String brewingMethodId;
  final String brewingMethod;
  const BrewingMethod(
      {required this.brewingMethodId, required this.brewingMethod});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['brewing_method_id'] = Variable<String>(brewingMethodId);
    map['brewing_method'] = Variable<String>(brewingMethod);
    return map;
  }

  BrewingMethodsCompanion toCompanion(bool nullToAbsent) {
    return BrewingMethodsCompanion(
      brewingMethodId: Value(brewingMethodId),
      brewingMethod: Value(brewingMethod),
    );
  }

  factory BrewingMethod.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BrewingMethod(
      brewingMethodId: serializer.fromJson<String>(json['brewingMethodId']),
      brewingMethod: serializer.fromJson<String>(json['brewingMethod']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'brewingMethodId': serializer.toJson<String>(brewingMethodId),
      'brewingMethod': serializer.toJson<String>(brewingMethod),
    };
  }

  BrewingMethod copyWith({String? brewingMethodId, String? brewingMethod}) =>
      BrewingMethod(
        brewingMethodId: brewingMethodId ?? this.brewingMethodId,
        brewingMethod: brewingMethod ?? this.brewingMethod,
      );
  @override
  String toString() {
    return (StringBuffer('BrewingMethod(')
          ..write('brewingMethodId: $brewingMethodId, ')
          ..write('brewingMethod: $brewingMethod')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(brewingMethodId, brewingMethod);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrewingMethod &&
          other.brewingMethodId == this.brewingMethodId &&
          other.brewingMethod == this.brewingMethod);
}

class BrewingMethodsCompanion extends UpdateCompanion<BrewingMethod> {
  final Value<String> brewingMethodId;
  final Value<String> brewingMethod;
  final Value<int> rowid;
  const BrewingMethodsCompanion({
    this.brewingMethodId = const Value.absent(),
    this.brewingMethod = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BrewingMethodsCompanion.insert({
    required String brewingMethodId,
    required String brewingMethod,
    this.rowid = const Value.absent(),
  })  : brewingMethodId = Value(brewingMethodId),
        brewingMethod = Value(brewingMethod);
  static Insertable<BrewingMethod> custom({
    Expression<String>? brewingMethodId,
    Expression<String>? brewingMethod,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (brewingMethodId != null) 'brewing_method_id': brewingMethodId,
      if (brewingMethod != null) 'brewing_method': brewingMethod,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BrewingMethodsCompanion copyWith(
      {Value<String>? brewingMethodId,
      Value<String>? brewingMethod,
      Value<int>? rowid}) {
    return BrewingMethodsCompanion(
      brewingMethodId: brewingMethodId ?? this.brewingMethodId,
      brewingMethod: brewingMethod ?? this.brewingMethod,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (brewingMethodId.present) {
      map['brewing_method_id'] = Variable<String>(brewingMethodId.value);
    }
    if (brewingMethod.present) {
      map['brewing_method'] = Variable<String>(brewingMethod.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BrewingMethodsCompanion(')
          ..write('brewingMethodId: $brewingMethodId, ')
          ..write('brewingMethod: $brewingMethod, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipesTable extends Recipes with TableInfo<$RecipesTable, Recipe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _brewingMethodIdMeta =
      const VerificationMeta('brewingMethodId');
  @override
  late final GeneratedColumn<String> brewingMethodId = GeneratedColumn<String>(
      'brewing_method_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints:
          'REFERENCES brewing_methods(brewing_method_id) NOT NULL');
  static const VerificationMeta _coffeeAmountMeta =
      const VerificationMeta('coffeeAmount');
  @override
  late final GeneratedColumn<double> coffeeAmount = GeneratedColumn<double>(
      'coffee_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _waterAmountMeta =
      const VerificationMeta('waterAmount');
  @override
  late final GeneratedColumn<double> waterAmount = GeneratedColumn<double>(
      'water_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _waterTempMeta =
      const VerificationMeta('waterTemp');
  @override
  late final GeneratedColumn<double> waterTemp = GeneratedColumn<double>(
      'water_temp', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _brewTimeMeta =
      const VerificationMeta('brewTime');
  @override
  late final GeneratedColumn<int> brewTime = GeneratedColumn<int>(
      'brew_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _vendorIdMeta =
      const VerificationMeta('vendorId');
  @override
  late final GeneratedColumn<String> vendorId = GeneratedColumn<String>(
      'vendor_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'REFERENCES vendors(vendor_id)');
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        brewingMethodId,
        coffeeAmount,
        waterAmount,
        waterTemp,
        brewTime,
        vendorId,
        lastModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(Insertable<Recipe> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('brewing_method_id')) {
      context.handle(
          _brewingMethodIdMeta,
          brewingMethodId.isAcceptableOrUnknown(
              data['brewing_method_id']!, _brewingMethodIdMeta));
    } else if (isInserting) {
      context.missing(_brewingMethodIdMeta);
    }
    if (data.containsKey('coffee_amount')) {
      context.handle(
          _coffeeAmountMeta,
          coffeeAmount.isAcceptableOrUnknown(
              data['coffee_amount']!, _coffeeAmountMeta));
    } else if (isInserting) {
      context.missing(_coffeeAmountMeta);
    }
    if (data.containsKey('water_amount')) {
      context.handle(
          _waterAmountMeta,
          waterAmount.isAcceptableOrUnknown(
              data['water_amount']!, _waterAmountMeta));
    } else if (isInserting) {
      context.missing(_waterAmountMeta);
    }
    if (data.containsKey('water_temp')) {
      context.handle(_waterTempMeta,
          waterTemp.isAcceptableOrUnknown(data['water_temp']!, _waterTempMeta));
    } else if (isInserting) {
      context.missing(_waterTempMeta);
    }
    if (data.containsKey('brew_time')) {
      context.handle(_brewTimeMeta,
          brewTime.isAcceptableOrUnknown(data['brew_time']!, _brewTimeMeta));
    } else if (isInserting) {
      context.missing(_brewTimeMeta);
    }
    if (data.containsKey('vendor_id')) {
      context.handle(_vendorIdMeta,
          vendorId.isAcceptableOrUnknown(data['vendor_id']!, _vendorIdMeta));
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recipe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recipe(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      brewingMethodId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}brewing_method_id'])!,
      coffeeAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}coffee_amount'])!,
      waterAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}water_amount'])!,
      waterTemp: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}water_temp'])!,
      brewTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}brew_time'])!,
      vendorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vendor_id']),
      lastModified: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_modified']),
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }
}

class Recipe extends DataClass implements Insertable<Recipe> {
  final String id;
  final String brewingMethodId;
  final double coffeeAmount;
  final double waterAmount;
  final double waterTemp;
  final int brewTime;
  final String? vendorId;
  final DateTime? lastModified;
  const Recipe(
      {required this.id,
      required this.brewingMethodId,
      required this.coffeeAmount,
      required this.waterAmount,
      required this.waterTemp,
      required this.brewTime,
      this.vendorId,
      this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['brewing_method_id'] = Variable<String>(brewingMethodId);
    map['coffee_amount'] = Variable<double>(coffeeAmount);
    map['water_amount'] = Variable<double>(waterAmount);
    map['water_temp'] = Variable<double>(waterTemp);
    map['brew_time'] = Variable<int>(brewTime);
    if (!nullToAbsent || vendorId != null) {
      map['vendor_id'] = Variable<String>(vendorId);
    }
    if (!nullToAbsent || lastModified != null) {
      map['last_modified'] = Variable<DateTime>(lastModified);
    }
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      brewingMethodId: Value(brewingMethodId),
      coffeeAmount: Value(coffeeAmount),
      waterAmount: Value(waterAmount),
      waterTemp: Value(waterTemp),
      brewTime: Value(brewTime),
      vendorId: vendorId == null && nullToAbsent
          ? const Value.absent()
          : Value(vendorId),
      lastModified: lastModified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModified),
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recipe(
      id: serializer.fromJson<String>(json['id']),
      brewingMethodId: serializer.fromJson<String>(json['brewingMethodId']),
      coffeeAmount: serializer.fromJson<double>(json['coffeeAmount']),
      waterAmount: serializer.fromJson<double>(json['waterAmount']),
      waterTemp: serializer.fromJson<double>(json['waterTemp']),
      brewTime: serializer.fromJson<int>(json['brewTime']),
      vendorId: serializer.fromJson<String?>(json['vendorId']),
      lastModified: serializer.fromJson<DateTime?>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'brewingMethodId': serializer.toJson<String>(brewingMethodId),
      'coffeeAmount': serializer.toJson<double>(coffeeAmount),
      'waterAmount': serializer.toJson<double>(waterAmount),
      'waterTemp': serializer.toJson<double>(waterTemp),
      'brewTime': serializer.toJson<int>(brewTime),
      'vendorId': serializer.toJson<String?>(vendorId),
      'lastModified': serializer.toJson<DateTime?>(lastModified),
    };
  }

  Recipe copyWith(
          {String? id,
          String? brewingMethodId,
          double? coffeeAmount,
          double? waterAmount,
          double? waterTemp,
          int? brewTime,
          Value<String?> vendorId = const Value.absent(),
          Value<DateTime?> lastModified = const Value.absent()}) =>
      Recipe(
        id: id ?? this.id,
        brewingMethodId: brewingMethodId ?? this.brewingMethodId,
        coffeeAmount: coffeeAmount ?? this.coffeeAmount,
        waterAmount: waterAmount ?? this.waterAmount,
        waterTemp: waterTemp ?? this.waterTemp,
        brewTime: brewTime ?? this.brewTime,
        vendorId: vendorId.present ? vendorId.value : this.vendorId,
        lastModified:
            lastModified.present ? lastModified.value : this.lastModified,
      );
  @override
  String toString() {
    return (StringBuffer('Recipe(')
          ..write('id: $id, ')
          ..write('brewingMethodId: $brewingMethodId, ')
          ..write('coffeeAmount: $coffeeAmount, ')
          ..write('waterAmount: $waterAmount, ')
          ..write('waterTemp: $waterTemp, ')
          ..write('brewTime: $brewTime, ')
          ..write('vendorId: $vendorId, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, brewingMethodId, coffeeAmount,
      waterAmount, waterTemp, brewTime, vendorId, lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recipe &&
          other.id == this.id &&
          other.brewingMethodId == this.brewingMethodId &&
          other.coffeeAmount == this.coffeeAmount &&
          other.waterAmount == this.waterAmount &&
          other.waterTemp == this.waterTemp &&
          other.brewTime == this.brewTime &&
          other.vendorId == this.vendorId &&
          other.lastModified == this.lastModified);
}

class RecipesCompanion extends UpdateCompanion<Recipe> {
  final Value<String> id;
  final Value<String> brewingMethodId;
  final Value<double> coffeeAmount;
  final Value<double> waterAmount;
  final Value<double> waterTemp;
  final Value<int> brewTime;
  final Value<String?> vendorId;
  final Value<DateTime?> lastModified;
  final Value<int> rowid;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.brewingMethodId = const Value.absent(),
    this.coffeeAmount = const Value.absent(),
    this.waterAmount = const Value.absent(),
    this.waterTemp = const Value.absent(),
    this.brewTime = const Value.absent(),
    this.vendorId = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipesCompanion.insert({
    required String id,
    required String brewingMethodId,
    required double coffeeAmount,
    required double waterAmount,
    required double waterTemp,
    required int brewTime,
    this.vendorId = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        brewingMethodId = Value(brewingMethodId),
        coffeeAmount = Value(coffeeAmount),
        waterAmount = Value(waterAmount),
        waterTemp = Value(waterTemp),
        brewTime = Value(brewTime);
  static Insertable<Recipe> custom({
    Expression<String>? id,
    Expression<String>? brewingMethodId,
    Expression<double>? coffeeAmount,
    Expression<double>? waterAmount,
    Expression<double>? waterTemp,
    Expression<int>? brewTime,
    Expression<String>? vendorId,
    Expression<DateTime>? lastModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brewingMethodId != null) 'brewing_method_id': brewingMethodId,
      if (coffeeAmount != null) 'coffee_amount': coffeeAmount,
      if (waterAmount != null) 'water_amount': waterAmount,
      if (waterTemp != null) 'water_temp': waterTemp,
      if (brewTime != null) 'brew_time': brewTime,
      if (vendorId != null) 'vendor_id': vendorId,
      if (lastModified != null) 'last_modified': lastModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipesCompanion copyWith(
      {Value<String>? id,
      Value<String>? brewingMethodId,
      Value<double>? coffeeAmount,
      Value<double>? waterAmount,
      Value<double>? waterTemp,
      Value<int>? brewTime,
      Value<String?>? vendorId,
      Value<DateTime?>? lastModified,
      Value<int>? rowid}) {
    return RecipesCompanion(
      id: id ?? this.id,
      brewingMethodId: brewingMethodId ?? this.brewingMethodId,
      coffeeAmount: coffeeAmount ?? this.coffeeAmount,
      waterAmount: waterAmount ?? this.waterAmount,
      waterTemp: waterTemp ?? this.waterTemp,
      brewTime: brewTime ?? this.brewTime,
      vendorId: vendorId ?? this.vendorId,
      lastModified: lastModified ?? this.lastModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (brewingMethodId.present) {
      map['brewing_method_id'] = Variable<String>(brewingMethodId.value);
    }
    if (coffeeAmount.present) {
      map['coffee_amount'] = Variable<double>(coffeeAmount.value);
    }
    if (waterAmount.present) {
      map['water_amount'] = Variable<double>(waterAmount.value);
    }
    if (waterTemp.present) {
      map['water_temp'] = Variable<double>(waterTemp.value);
    }
    if (brewTime.present) {
      map['brew_time'] = Variable<int>(brewTime.value);
    }
    if (vendorId.present) {
      map['vendor_id'] = Variable<String>(vendorId.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('brewingMethodId: $brewingMethodId, ')
          ..write('coffeeAmount: $coffeeAmount, ')
          ..write('waterAmount: $waterAmount, ')
          ..write('waterTemp: $waterTemp, ')
          ..write('brewTime: $brewTime, ')
          ..write('vendorId: $vendorId, ')
          ..write('lastModified: $lastModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeLocalizationsTable extends RecipeLocalizations
    with TableInfo<$RecipeLocalizationsTable, RecipeLocalization> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeLocalizationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _recipeIdMeta =
      const VerificationMeta('recipeId');
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
      'recipe_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES recipes(id) NOT NULL');
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
      'locale', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 2, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES supported_locales(locale) NOT NULL');
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _grindSizeMeta =
      const VerificationMeta('grindSize');
  @override
  late final GeneratedColumn<String> grindSize = GeneratedColumn<String>(
      'grind_size', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _shortDescriptionMeta =
      const VerificationMeta('shortDescription');
  @override
  late final GeneratedColumn<String> shortDescription = GeneratedColumn<String>(
      'short_description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, recipeId, locale, name, grindSize, shortDescription];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_localizations';
  @override
  VerificationContext validateIntegrity(Insertable<RecipeLocalization> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(_recipeIdMeta,
          recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta));
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('locale')) {
      context.handle(_localeMeta,
          locale.isAcceptableOrUnknown(data['locale']!, _localeMeta));
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('grind_size')) {
      context.handle(_grindSizeMeta,
          grindSize.isAcceptableOrUnknown(data['grind_size']!, _grindSizeMeta));
    } else if (isInserting) {
      context.missing(_grindSizeMeta);
    }
    if (data.containsKey('short_description')) {
      context.handle(
          _shortDescriptionMeta,
          shortDescription.isAcceptableOrUnknown(
              data['short_description']!, _shortDescriptionMeta));
    } else if (isInserting) {
      context.missing(_shortDescriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeLocalization map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeLocalization(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
      locale: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}locale'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      grindSize: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}grind_size'])!,
      shortDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}short_description'])!,
    );
  }

  @override
  $RecipeLocalizationsTable createAlias(String alias) {
    return $RecipeLocalizationsTable(attachedDatabase, alias);
  }
}

class RecipeLocalization extends DataClass
    implements Insertable<RecipeLocalization> {
  final String id;
  final String recipeId;
  final String locale;
  final String name;
  final String grindSize;
  final String shortDescription;
  const RecipeLocalization(
      {required this.id,
      required this.recipeId,
      required this.locale,
      required this.name,
      required this.grindSize,
      required this.shortDescription});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    map['locale'] = Variable<String>(locale);
    map['name'] = Variable<String>(name);
    map['grind_size'] = Variable<String>(grindSize);
    map['short_description'] = Variable<String>(shortDescription);
    return map;
  }

  RecipeLocalizationsCompanion toCompanion(bool nullToAbsent) {
    return RecipeLocalizationsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      locale: Value(locale),
      name: Value(name),
      grindSize: Value(grindSize),
      shortDescription: Value(shortDescription),
    );
  }

  factory RecipeLocalization.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeLocalization(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      locale: serializer.fromJson<String>(json['locale']),
      name: serializer.fromJson<String>(json['name']),
      grindSize: serializer.fromJson<String>(json['grindSize']),
      shortDescription: serializer.fromJson<String>(json['shortDescription']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'locale': serializer.toJson<String>(locale),
      'name': serializer.toJson<String>(name),
      'grindSize': serializer.toJson<String>(grindSize),
      'shortDescription': serializer.toJson<String>(shortDescription),
    };
  }

  RecipeLocalization copyWith(
          {String? id,
          String? recipeId,
          String? locale,
          String? name,
          String? grindSize,
          String? shortDescription}) =>
      RecipeLocalization(
        id: id ?? this.id,
        recipeId: recipeId ?? this.recipeId,
        locale: locale ?? this.locale,
        name: name ?? this.name,
        grindSize: grindSize ?? this.grindSize,
        shortDescription: shortDescription ?? this.shortDescription,
      );
  @override
  String toString() {
    return (StringBuffer('RecipeLocalization(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('locale: $locale, ')
          ..write('name: $name, ')
          ..write('grindSize: $grindSize, ')
          ..write('shortDescription: $shortDescription')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, recipeId, locale, name, grindSize, shortDescription);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeLocalization &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.locale == this.locale &&
          other.name == this.name &&
          other.grindSize == this.grindSize &&
          other.shortDescription == this.shortDescription);
}

class RecipeLocalizationsCompanion extends UpdateCompanion<RecipeLocalization> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<String> locale;
  final Value<String> name;
  final Value<String> grindSize;
  final Value<String> shortDescription;
  final Value<int> rowid;
  const RecipeLocalizationsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.locale = const Value.absent(),
    this.name = const Value.absent(),
    this.grindSize = const Value.absent(),
    this.shortDescription = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeLocalizationsCompanion.insert({
    required String id,
    required String recipeId,
    required String locale,
    required String name,
    required String grindSize,
    required String shortDescription,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        recipeId = Value(recipeId),
        locale = Value(locale),
        name = Value(name),
        grindSize = Value(grindSize),
        shortDescription = Value(shortDescription);
  static Insertable<RecipeLocalization> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<String>? locale,
    Expression<String>? name,
    Expression<String>? grindSize,
    Expression<String>? shortDescription,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (locale != null) 'locale': locale,
      if (name != null) 'name': name,
      if (grindSize != null) 'grind_size': grindSize,
      if (shortDescription != null) 'short_description': shortDescription,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeLocalizationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? recipeId,
      Value<String>? locale,
      Value<String>? name,
      Value<String>? grindSize,
      Value<String>? shortDescription,
      Value<int>? rowid}) {
    return RecipeLocalizationsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      locale: locale ?? this.locale,
      name: name ?? this.name,
      grindSize: grindSize ?? this.grindSize,
      shortDescription: shortDescription ?? this.shortDescription,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (grindSize.present) {
      map['grind_size'] = Variable<String>(grindSize.value);
    }
    if (shortDescription.present) {
      map['short_description'] = Variable<String>(shortDescription.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeLocalizationsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('locale: $locale, ')
          ..write('name: $name, ')
          ..write('grindSize: $grindSize, ')
          ..write('shortDescription: $shortDescription, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StepsTable extends Steps with TableInfo<$StepsTable, Step> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _recipeIdMeta =
      const VerificationMeta('recipeId');
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
      'recipe_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES recipes(id) NOT NULL');
  static const VerificationMeta _stepOrderMeta =
      const VerificationMeta('stepOrder');
  @override
  late final GeneratedColumn<int> stepOrder = GeneratedColumn<int>(
      'step_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
      'time', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
      'locale', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 2, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES supported_locales(locale) NOT NULL');
  @override
  List<GeneratedColumn> get $columns =>
      [id, recipeId, stepOrder, description, time, locale];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'steps';
  @override
  VerificationContext validateIntegrity(Insertable<Step> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(_recipeIdMeta,
          recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta));
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('step_order')) {
      context.handle(_stepOrderMeta,
          stepOrder.isAcceptableOrUnknown(data['step_order']!, _stepOrderMeta));
    } else if (isInserting) {
      context.missing(_stepOrderMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
          _timeMeta, time.isAcceptableOrUnknown(data['time']!, _timeMeta));
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('locale')) {
      context.handle(_localeMeta,
          locale.isAcceptableOrUnknown(data['locale']!, _localeMeta));
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Step map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Step(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
      stepOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}step_order'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      time: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time'])!,
      locale: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}locale'])!,
    );
  }

  @override
  $StepsTable createAlias(String alias) {
    return $StepsTable(attachedDatabase, alias);
  }
}

class Step extends DataClass implements Insertable<Step> {
  final String id;
  final String recipeId;
  final int stepOrder;
  final String description;
  final String time;
  final String locale;
  const Step(
      {required this.id,
      required this.recipeId,
      required this.stepOrder,
      required this.description,
      required this.time,
      required this.locale});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipe_id'] = Variable<String>(recipeId);
    map['step_order'] = Variable<int>(stepOrder);
    map['description'] = Variable<String>(description);
    map['time'] = Variable<String>(time);
    map['locale'] = Variable<String>(locale);
    return map;
  }

  StepsCompanion toCompanion(bool nullToAbsent) {
    return StepsCompanion(
      id: Value(id),
      recipeId: Value(recipeId),
      stepOrder: Value(stepOrder),
      description: Value(description),
      time: Value(time),
      locale: Value(locale),
    );
  }

  factory Step.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Step(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      stepOrder: serializer.fromJson<int>(json['stepOrder']),
      description: serializer.fromJson<String>(json['description']),
      time: serializer.fromJson<String>(json['time']),
      locale: serializer.fromJson<String>(json['locale']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String>(recipeId),
      'stepOrder': serializer.toJson<int>(stepOrder),
      'description': serializer.toJson<String>(description),
      'time': serializer.toJson<String>(time),
      'locale': serializer.toJson<String>(locale),
    };
  }

  Step copyWith(
          {String? id,
          String? recipeId,
          int? stepOrder,
          String? description,
          String? time,
          String? locale}) =>
      Step(
        id: id ?? this.id,
        recipeId: recipeId ?? this.recipeId,
        stepOrder: stepOrder ?? this.stepOrder,
        description: description ?? this.description,
        time: time ?? this.time,
        locale: locale ?? this.locale,
      );
  @override
  String toString() {
    return (StringBuffer('Step(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('stepOrder: $stepOrder, ')
          ..write('description: $description, ')
          ..write('time: $time, ')
          ..write('locale: $locale')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, recipeId, stepOrder, description, time, locale);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Step &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.stepOrder == this.stepOrder &&
          other.description == this.description &&
          other.time == this.time &&
          other.locale == this.locale);
}

class StepsCompanion extends UpdateCompanion<Step> {
  final Value<String> id;
  final Value<String> recipeId;
  final Value<int> stepOrder;
  final Value<String> description;
  final Value<String> time;
  final Value<String> locale;
  final Value<int> rowid;
  const StepsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.stepOrder = const Value.absent(),
    this.description = const Value.absent(),
    this.time = const Value.absent(),
    this.locale = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StepsCompanion.insert({
    required String id,
    required String recipeId,
    required int stepOrder,
    required String description,
    required String time,
    required String locale,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        recipeId = Value(recipeId),
        stepOrder = Value(stepOrder),
        description = Value(description),
        time = Value(time),
        locale = Value(locale);
  static Insertable<Step> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<int>? stepOrder,
    Expression<String>? description,
    Expression<String>? time,
    Expression<String>? locale,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (stepOrder != null) 'step_order': stepOrder,
      if (description != null) 'description': description,
      if (time != null) 'time': time,
      if (locale != null) 'locale': locale,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StepsCompanion copyWith(
      {Value<String>? id,
      Value<String>? recipeId,
      Value<int>? stepOrder,
      Value<String>? description,
      Value<String>? time,
      Value<String>? locale,
      Value<int>? rowid}) {
    return StepsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      stepOrder: stepOrder ?? this.stepOrder,
      description: description ?? this.description,
      time: time ?? this.time,
      locale: locale ?? this.locale,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (stepOrder.present) {
      map['step_order'] = Variable<int>(stepOrder.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StepsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('stepOrder: $stepOrder, ')
          ..write('description: $description, ')
          ..write('time: $time, ')
          ..write('locale: $locale, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserRecipePreferencesTable extends UserRecipePreferences
    with TableInfo<$UserRecipePreferencesTable, UserRecipePreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserRecipePreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipeIdMeta =
      const VerificationMeta('recipeId');
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
      'recipe_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES recipes(id) NOT NULL');
  static const VerificationMeta _lastUsedMeta =
      const VerificationMeta('lastUsed');
  @override
  late final GeneratedColumn<DateTime> lastUsed = GeneratedColumn<DateTime>(
      'last_used', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_favorite" IN (0, 1))'));
  static const VerificationMeta _sweetnessSliderPositionMeta =
      const VerificationMeta('sweetnessSliderPosition');
  @override
  late final GeneratedColumn<int> sweetnessSliderPosition =
      GeneratedColumn<int>('sweetness_slider_position', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  static const VerificationMeta _strengthSliderPositionMeta =
      const VerificationMeta('strengthSliderPosition');
  @override
  late final GeneratedColumn<int> strengthSliderPosition = GeneratedColumn<int>(
      'strength_slider_position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(2));
  static const VerificationMeta _customCoffeeAmountMeta =
      const VerificationMeta('customCoffeeAmount');
  @override
  late final GeneratedColumn<double> customCoffeeAmount =
      GeneratedColumn<double>('custom_coffee_amount', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _customWaterAmountMeta =
      const VerificationMeta('customWaterAmount');
  @override
  late final GeneratedColumn<double> customWaterAmount =
      GeneratedColumn<double>('custom_water_amount', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        recipeId,
        lastUsed,
        isFavorite,
        sweetnessSliderPosition,
        strengthSliderPosition,
        customCoffeeAmount,
        customWaterAmount
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_recipe_preferences';
  @override
  VerificationContext validateIntegrity(
      Insertable<UserRecipePreference> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipe_id')) {
      context.handle(_recipeIdMeta,
          recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta));
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('last_used')) {
      context.handle(_lastUsedMeta,
          lastUsed.isAcceptableOrUnknown(data['last_used']!, _lastUsedMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    } else if (isInserting) {
      context.missing(_isFavoriteMeta);
    }
    if (data.containsKey('sweetness_slider_position')) {
      context.handle(
          _sweetnessSliderPositionMeta,
          sweetnessSliderPosition.isAcceptableOrUnknown(
              data['sweetness_slider_position']!,
              _sweetnessSliderPositionMeta));
    }
    if (data.containsKey('strength_slider_position')) {
      context.handle(
          _strengthSliderPositionMeta,
          strengthSliderPosition.isAcceptableOrUnknown(
              data['strength_slider_position']!, _strengthSliderPositionMeta));
    }
    if (data.containsKey('custom_coffee_amount')) {
      context.handle(
          _customCoffeeAmountMeta,
          customCoffeeAmount.isAcceptableOrUnknown(
              data['custom_coffee_amount']!, _customCoffeeAmountMeta));
    }
    if (data.containsKey('custom_water_amount')) {
      context.handle(
          _customWaterAmountMeta,
          customWaterAmount.isAcceptableOrUnknown(
              data['custom_water_amount']!, _customWaterAmountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipeId};
  @override
  UserRecipePreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRecipePreference(
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
      lastUsed: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_used']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      sweetnessSliderPosition: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sweetness_slider_position'])!,
      strengthSliderPosition: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}strength_slider_position'])!,
      customCoffeeAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}custom_coffee_amount']),
      customWaterAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}custom_water_amount']),
    );
  }

  @override
  $UserRecipePreferencesTable createAlias(String alias) {
    return $UserRecipePreferencesTable(attachedDatabase, alias);
  }
}

class UserRecipePreference extends DataClass
    implements Insertable<UserRecipePreference> {
  final String recipeId;
  final DateTime? lastUsed;
  final bool isFavorite;
  final int sweetnessSliderPosition;
  final int strengthSliderPosition;
  final double? customCoffeeAmount;
  final double? customWaterAmount;
  const UserRecipePreference(
      {required this.recipeId,
      this.lastUsed,
      required this.isFavorite,
      required this.sweetnessSliderPosition,
      required this.strengthSliderPosition,
      this.customCoffeeAmount,
      this.customWaterAmount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipe_id'] = Variable<String>(recipeId);
    if (!nullToAbsent || lastUsed != null) {
      map['last_used'] = Variable<DateTime>(lastUsed);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['sweetness_slider_position'] = Variable<int>(sweetnessSliderPosition);
    map['strength_slider_position'] = Variable<int>(strengthSliderPosition);
    if (!nullToAbsent || customCoffeeAmount != null) {
      map['custom_coffee_amount'] = Variable<double>(customCoffeeAmount);
    }
    if (!nullToAbsent || customWaterAmount != null) {
      map['custom_water_amount'] = Variable<double>(customWaterAmount);
    }
    return map;
  }

  UserRecipePreferencesCompanion toCompanion(bool nullToAbsent) {
    return UserRecipePreferencesCompanion(
      recipeId: Value(recipeId),
      lastUsed: lastUsed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsed),
      isFavorite: Value(isFavorite),
      sweetnessSliderPosition: Value(sweetnessSliderPosition),
      strengthSliderPosition: Value(strengthSliderPosition),
      customCoffeeAmount: customCoffeeAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(customCoffeeAmount),
      customWaterAmount: customWaterAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(customWaterAmount),
    );
  }

  factory UserRecipePreference.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRecipePreference(
      recipeId: serializer.fromJson<String>(json['recipeId']),
      lastUsed: serializer.fromJson<DateTime?>(json['lastUsed']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      sweetnessSliderPosition:
          serializer.fromJson<int>(json['sweetnessSliderPosition']),
      strengthSliderPosition:
          serializer.fromJson<int>(json['strengthSliderPosition']),
      customCoffeeAmount:
          serializer.fromJson<double?>(json['customCoffeeAmount']),
      customWaterAmount:
          serializer.fromJson<double?>(json['customWaterAmount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipeId': serializer.toJson<String>(recipeId),
      'lastUsed': serializer.toJson<DateTime?>(lastUsed),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'sweetnessSliderPosition':
          serializer.toJson<int>(sweetnessSliderPosition),
      'strengthSliderPosition': serializer.toJson<int>(strengthSliderPosition),
      'customCoffeeAmount': serializer.toJson<double?>(customCoffeeAmount),
      'customWaterAmount': serializer.toJson<double?>(customWaterAmount),
    };
  }

  UserRecipePreference copyWith(
          {String? recipeId,
          Value<DateTime?> lastUsed = const Value.absent(),
          bool? isFavorite,
          int? sweetnessSliderPosition,
          int? strengthSliderPosition,
          Value<double?> customCoffeeAmount = const Value.absent(),
          Value<double?> customWaterAmount = const Value.absent()}) =>
      UserRecipePreference(
        recipeId: recipeId ?? this.recipeId,
        lastUsed: lastUsed.present ? lastUsed.value : this.lastUsed,
        isFavorite: isFavorite ?? this.isFavorite,
        sweetnessSliderPosition:
            sweetnessSliderPosition ?? this.sweetnessSliderPosition,
        strengthSliderPosition:
            strengthSliderPosition ?? this.strengthSliderPosition,
        customCoffeeAmount: customCoffeeAmount.present
            ? customCoffeeAmount.value
            : this.customCoffeeAmount,
        customWaterAmount: customWaterAmount.present
            ? customWaterAmount.value
            : this.customWaterAmount,
      );
  @override
  String toString() {
    return (StringBuffer('UserRecipePreference(')
          ..write('recipeId: $recipeId, ')
          ..write('lastUsed: $lastUsed, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('sweetnessSliderPosition: $sweetnessSliderPosition, ')
          ..write('strengthSliderPosition: $strengthSliderPosition, ')
          ..write('customCoffeeAmount: $customCoffeeAmount, ')
          ..write('customWaterAmount: $customWaterAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      recipeId,
      lastUsed,
      isFavorite,
      sweetnessSliderPosition,
      strengthSliderPosition,
      customCoffeeAmount,
      customWaterAmount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRecipePreference &&
          other.recipeId == this.recipeId &&
          other.lastUsed == this.lastUsed &&
          other.isFavorite == this.isFavorite &&
          other.sweetnessSliderPosition == this.sweetnessSliderPosition &&
          other.strengthSliderPosition == this.strengthSliderPosition &&
          other.customCoffeeAmount == this.customCoffeeAmount &&
          other.customWaterAmount == this.customWaterAmount);
}

class UserRecipePreferencesCompanion
    extends UpdateCompanion<UserRecipePreference> {
  final Value<String> recipeId;
  final Value<DateTime?> lastUsed;
  final Value<bool> isFavorite;
  final Value<int> sweetnessSliderPosition;
  final Value<int> strengthSliderPosition;
  final Value<double?> customCoffeeAmount;
  final Value<double?> customWaterAmount;
  final Value<int> rowid;
  const UserRecipePreferencesCompanion({
    this.recipeId = const Value.absent(),
    this.lastUsed = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.sweetnessSliderPosition = const Value.absent(),
    this.strengthSliderPosition = const Value.absent(),
    this.customCoffeeAmount = const Value.absent(),
    this.customWaterAmount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserRecipePreferencesCompanion.insert({
    required String recipeId,
    this.lastUsed = const Value.absent(),
    required bool isFavorite,
    this.sweetnessSliderPosition = const Value.absent(),
    this.strengthSliderPosition = const Value.absent(),
    this.customCoffeeAmount = const Value.absent(),
    this.customWaterAmount = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : recipeId = Value(recipeId),
        isFavorite = Value(isFavorite);
  static Insertable<UserRecipePreference> custom({
    Expression<String>? recipeId,
    Expression<DateTime>? lastUsed,
    Expression<bool>? isFavorite,
    Expression<int>? sweetnessSliderPosition,
    Expression<int>? strengthSliderPosition,
    Expression<double>? customCoffeeAmount,
    Expression<double>? customWaterAmount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recipeId != null) 'recipe_id': recipeId,
      if (lastUsed != null) 'last_used': lastUsed,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (sweetnessSliderPosition != null)
        'sweetness_slider_position': sweetnessSliderPosition,
      if (strengthSliderPosition != null)
        'strength_slider_position': strengthSliderPosition,
      if (customCoffeeAmount != null)
        'custom_coffee_amount': customCoffeeAmount,
      if (customWaterAmount != null) 'custom_water_amount': customWaterAmount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserRecipePreferencesCompanion copyWith(
      {Value<String>? recipeId,
      Value<DateTime?>? lastUsed,
      Value<bool>? isFavorite,
      Value<int>? sweetnessSliderPosition,
      Value<int>? strengthSliderPosition,
      Value<double?>? customCoffeeAmount,
      Value<double?>? customWaterAmount,
      Value<int>? rowid}) {
    return UserRecipePreferencesCompanion(
      recipeId: recipeId ?? this.recipeId,
      lastUsed: lastUsed ?? this.lastUsed,
      isFavorite: isFavorite ?? this.isFavorite,
      sweetnessSliderPosition:
          sweetnessSliderPosition ?? this.sweetnessSliderPosition,
      strengthSliderPosition:
          strengthSliderPosition ?? this.strengthSliderPosition,
      customCoffeeAmount: customCoffeeAmount ?? this.customCoffeeAmount,
      customWaterAmount: customWaterAmount ?? this.customWaterAmount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (lastUsed.present) {
      map['last_used'] = Variable<DateTime>(lastUsed.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (sweetnessSliderPosition.present) {
      map['sweetness_slider_position'] =
          Variable<int>(sweetnessSliderPosition.value);
    }
    if (strengthSliderPosition.present) {
      map['strength_slider_position'] =
          Variable<int>(strengthSliderPosition.value);
    }
    if (customCoffeeAmount.present) {
      map['custom_coffee_amount'] = Variable<double>(customCoffeeAmount.value);
    }
    if (customWaterAmount.present) {
      map['custom_water_amount'] = Variable<double>(customWaterAmount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserRecipePreferencesCompanion(')
          ..write('recipeId: $recipeId, ')
          ..write('lastUsed: $lastUsed, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('sweetnessSliderPosition: $sweetnessSliderPosition, ')
          ..write('strengthSliderPosition: $strengthSliderPosition, ')
          ..write('customCoffeeAmount: $customCoffeeAmount, ')
          ..write('customWaterAmount: $customWaterAmount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CoffeeFactsTable extends CoffeeFacts
    with TableInfo<$CoffeeFactsTable, CoffeeFact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoffeeFactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _factMeta = const VerificationMeta('fact');
  @override
  late final GeneratedColumn<String> fact = GeneratedColumn<String>(
      'fact', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
      'locale', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 2, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES supported_locales(locale) NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [id, fact, locale];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coffee_facts';
  @override
  VerificationContext validateIntegrity(Insertable<CoffeeFact> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('fact')) {
      context.handle(
          _factMeta, fact.isAcceptableOrUnknown(data['fact']!, _factMeta));
    } else if (isInserting) {
      context.missing(_factMeta);
    }
    if (data.containsKey('locale')) {
      context.handle(_localeMeta,
          locale.isAcceptableOrUnknown(data['locale']!, _localeMeta));
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CoffeeFact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoffeeFact(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fact: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fact'])!,
      locale: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}locale'])!,
    );
  }

  @override
  $CoffeeFactsTable createAlias(String alias) {
    return $CoffeeFactsTable(attachedDatabase, alias);
  }
}

class CoffeeFact extends DataClass implements Insertable<CoffeeFact> {
  final String id;
  final String fact;
  final String locale;
  const CoffeeFact(
      {required this.id, required this.fact, required this.locale});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['fact'] = Variable<String>(fact);
    map['locale'] = Variable<String>(locale);
    return map;
  }

  CoffeeFactsCompanion toCompanion(bool nullToAbsent) {
    return CoffeeFactsCompanion(
      id: Value(id),
      fact: Value(fact),
      locale: Value(locale),
    );
  }

  factory CoffeeFact.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoffeeFact(
      id: serializer.fromJson<String>(json['id']),
      fact: serializer.fromJson<String>(json['fact']),
      locale: serializer.fromJson<String>(json['locale']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fact': serializer.toJson<String>(fact),
      'locale': serializer.toJson<String>(locale),
    };
  }

  CoffeeFact copyWith({String? id, String? fact, String? locale}) => CoffeeFact(
        id: id ?? this.id,
        fact: fact ?? this.fact,
        locale: locale ?? this.locale,
      );
  @override
  String toString() {
    return (StringBuffer('CoffeeFact(')
          ..write('id: $id, ')
          ..write('fact: $fact, ')
          ..write('locale: $locale')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fact, locale);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoffeeFact &&
          other.id == this.id &&
          other.fact == this.fact &&
          other.locale == this.locale);
}

class CoffeeFactsCompanion extends UpdateCompanion<CoffeeFact> {
  final Value<String> id;
  final Value<String> fact;
  final Value<String> locale;
  final Value<int> rowid;
  const CoffeeFactsCompanion({
    this.id = const Value.absent(),
    this.fact = const Value.absent(),
    this.locale = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoffeeFactsCompanion.insert({
    required String id,
    required String fact,
    required String locale,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fact = Value(fact),
        locale = Value(locale);
  static Insertable<CoffeeFact> custom({
    Expression<String>? id,
    Expression<String>? fact,
    Expression<String>? locale,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fact != null) 'fact': fact,
      if (locale != null) 'locale': locale,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoffeeFactsCompanion copyWith(
      {Value<String>? id,
      Value<String>? fact,
      Value<String>? locale,
      Value<int>? rowid}) {
    return CoffeeFactsCompanion(
      id: id ?? this.id,
      fact: fact ?? this.fact,
      locale: locale ?? this.locale,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fact.present) {
      map['fact'] = Variable<String>(fact.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoffeeFactsCompanion(')
          ..write('id: $id, ')
          ..write('fact: $fact, ')
          ..write('locale: $locale, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StartPopupsTable extends StartPopups
    with TableInfo<$StartPopupsTable, StartPopup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StartPopupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _appVersionMeta =
      const VerificationMeta('appVersion');
  @override
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
      'app_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
      'locale', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES supported_locales(locale) NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [id, content, appVersion, locale];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'start_popups';
  @override
  VerificationContext validateIntegrity(Insertable<StartPopup> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('app_version')) {
      context.handle(
          _appVersionMeta,
          appVersion.isAcceptableOrUnknown(
              data['app_version']!, _appVersionMeta));
    } else if (isInserting) {
      context.missing(_appVersionMeta);
    }
    if (data.containsKey('locale')) {
      context.handle(_localeMeta,
          locale.isAcceptableOrUnknown(data['locale']!, _localeMeta));
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StartPopup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StartPopup(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      appVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_version'])!,
      locale: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}locale'])!,
    );
  }

  @override
  $StartPopupsTable createAlias(String alias) {
    return $StartPopupsTable(attachedDatabase, alias);
  }
}

class StartPopup extends DataClass implements Insertable<StartPopup> {
  final String id;
  final String content;
  final String appVersion;
  final String locale;
  const StartPopup(
      {required this.id,
      required this.content,
      required this.appVersion,
      required this.locale});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['content'] = Variable<String>(content);
    map['app_version'] = Variable<String>(appVersion);
    map['locale'] = Variable<String>(locale);
    return map;
  }

  StartPopupsCompanion toCompanion(bool nullToAbsent) {
    return StartPopupsCompanion(
      id: Value(id),
      content: Value(content),
      appVersion: Value(appVersion),
      locale: Value(locale),
    );
  }

  factory StartPopup.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StartPopup(
      id: serializer.fromJson<String>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      appVersion: serializer.fromJson<String>(json['appVersion']),
      locale: serializer.fromJson<String>(json['locale']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'content': serializer.toJson<String>(content),
      'appVersion': serializer.toJson<String>(appVersion),
      'locale': serializer.toJson<String>(locale),
    };
  }

  StartPopup copyWith(
          {String? id, String? content, String? appVersion, String? locale}) =>
      StartPopup(
        id: id ?? this.id,
        content: content ?? this.content,
        appVersion: appVersion ?? this.appVersion,
        locale: locale ?? this.locale,
      );
  @override
  String toString() {
    return (StringBuffer('StartPopup(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('appVersion: $appVersion, ')
          ..write('locale: $locale')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, content, appVersion, locale);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StartPopup &&
          other.id == this.id &&
          other.content == this.content &&
          other.appVersion == this.appVersion &&
          other.locale == this.locale);
}

class StartPopupsCompanion extends UpdateCompanion<StartPopup> {
  final Value<String> id;
  final Value<String> content;
  final Value<String> appVersion;
  final Value<String> locale;
  final Value<int> rowid;
  const StartPopupsCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.locale = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StartPopupsCompanion.insert({
    required String id,
    required String content,
    required String appVersion,
    required String locale,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        content = Value(content),
        appVersion = Value(appVersion),
        locale = Value(locale);
  static Insertable<StartPopup> custom({
    Expression<String>? id,
    Expression<String>? content,
    Expression<String>? appVersion,
    Expression<String>? locale,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (appVersion != null) 'app_version': appVersion,
      if (locale != null) 'locale': locale,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StartPopupsCompanion copyWith(
      {Value<String>? id,
      Value<String>? content,
      Value<String>? appVersion,
      Value<String>? locale,
      Value<int>? rowid}) {
    return StartPopupsCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      appVersion: appVersion ?? this.appVersion,
      locale: locale ?? this.locale,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StartPopupsCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('appVersion: $appVersion, ')
          ..write('locale: $locale, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContributorsTable extends Contributors
    with TableInfo<$ContributorsTable, Contributor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContributorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
      'locale', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 2, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES supported_locales(locale) NOT NULL');
  @override
  List<GeneratedColumn> get $columns => [id, content, locale];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contributors';
  @override
  VerificationContext validateIntegrity(Insertable<Contributor> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('locale')) {
      context.handle(_localeMeta,
          locale.isAcceptableOrUnknown(data['locale']!, _localeMeta));
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contributor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contributor(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      locale: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}locale'])!,
    );
  }

  @override
  $ContributorsTable createAlias(String alias) {
    return $ContributorsTable(attachedDatabase, alias);
  }
}

class Contributor extends DataClass implements Insertable<Contributor> {
  final String id;
  final String content;
  final String locale;
  const Contributor(
      {required this.id, required this.content, required this.locale});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['content'] = Variable<String>(content);
    map['locale'] = Variable<String>(locale);
    return map;
  }

  ContributorsCompanion toCompanion(bool nullToAbsent) {
    return ContributorsCompanion(
      id: Value(id),
      content: Value(content),
      locale: Value(locale),
    );
  }

  factory Contributor.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contributor(
      id: serializer.fromJson<String>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      locale: serializer.fromJson<String>(json['locale']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'content': serializer.toJson<String>(content),
      'locale': serializer.toJson<String>(locale),
    };
  }

  Contributor copyWith({String? id, String? content, String? locale}) =>
      Contributor(
        id: id ?? this.id,
        content: content ?? this.content,
        locale: locale ?? this.locale,
      );
  @override
  String toString() {
    return (StringBuffer('Contributor(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('locale: $locale')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, content, locale);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contributor &&
          other.id == this.id &&
          other.content == this.content &&
          other.locale == this.locale);
}

class ContributorsCompanion extends UpdateCompanion<Contributor> {
  final Value<String> id;
  final Value<String> content;
  final Value<String> locale;
  final Value<int> rowid;
  const ContributorsCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.locale = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContributorsCompanion.insert({
    required String id,
    required String content,
    required String locale,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        content = Value(content),
        locale = Value(locale);
  static Insertable<Contributor> custom({
    Expression<String>? id,
    Expression<String>? content,
    Expression<String>? locale,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (locale != null) 'locale': locale,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContributorsCompanion copyWith(
      {Value<String>? id,
      Value<String>? content,
      Value<String>? locale,
      Value<int>? rowid}) {
    return ContributorsCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      locale: locale ?? this.locale,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContributorsCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('locale: $locale, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $VendorsTable vendors = $VendorsTable(this);
  late final $SupportedLocalesTable supportedLocales =
      $SupportedLocalesTable(this);
  late final $BrewingMethodsTable brewingMethods = $BrewingMethodsTable(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $RecipeLocalizationsTable recipeLocalizations =
      $RecipeLocalizationsTable(this);
  late final $StepsTable steps = $StepsTable(this);
  late final $UserRecipePreferencesTable userRecipePreferences =
      $UserRecipePreferencesTable(this);
  late final $CoffeeFactsTable coffeeFacts = $CoffeeFactsTable(this);
  late final $StartPopupsTable startPopups = $StartPopupsTable(this);
  late final $ContributorsTable contributors = $ContributorsTable(this);
  late final Index idxRecipesLastModified = Index('idx_recipes_last_modified',
      'CREATE INDEX idx_recipes_last_modified ON recipes (last_modified)');
  late final RecipesDao recipesDao = RecipesDao(this as AppDatabase);
  late final StepsDao stepsDao = StepsDao(this as AppDatabase);
  late final RecipeLocalizationsDao recipeLocalizationsDao =
      RecipeLocalizationsDao(this as AppDatabase);
  late final UserRecipePreferencesDao userRecipePreferencesDao =
      UserRecipePreferencesDao(this as AppDatabase);
  late final BrewingMethodsDao brewingMethodsDao =
      BrewingMethodsDao(this as AppDatabase);
  late final VendorsDao vendorsDao = VendorsDao(this as AppDatabase);
  late final SupportedLocalesDao supportedLocalesDao =
      SupportedLocalesDao(this as AppDatabase);
  late final CoffeeFactsDao coffeeFactsDao =
      CoffeeFactsDao(this as AppDatabase);
  late final StartPopupsDao startPopupsDao =
      StartPopupsDao(this as AppDatabase);
  late final ContributorsDao contributorsDao =
      ContributorsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        vendors,
        supportedLocales,
        brewingMethods,
        recipes,
        recipeLocalizations,
        steps,
        userRecipePreferences,
        coffeeFacts,
        startPopups,
        contributors,
        idxRecipesLastModified
      ];
}

mixin _$RecipesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BrewingMethodsTable get brewingMethods => attachedDatabase.brewingMethods;
  $VendorsTable get vendors => attachedDatabase.vendors;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $SupportedLocalesTable get supportedLocales =>
      attachedDatabase.supportedLocales;
  $RecipeLocalizationsTable get recipeLocalizations =>
      attachedDatabase.recipeLocalizations;
  $StepsTable get steps => attachedDatabase.steps;
  $UserRecipePreferencesTable get userRecipePreferences =>
      attachedDatabase.userRecipePreferences;
}
mixin _$StepsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BrewingMethodsTable get brewingMethods => attachedDatabase.brewingMethods;
  $VendorsTable get vendors => attachedDatabase.vendors;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $SupportedLocalesTable get supportedLocales =>
      attachedDatabase.supportedLocales;
  $StepsTable get steps => attachedDatabase.steps;
}
mixin _$RecipeLocalizationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BrewingMethodsTable get brewingMethods => attachedDatabase.brewingMethods;
  $VendorsTable get vendors => attachedDatabase.vendors;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $SupportedLocalesTable get supportedLocales =>
      attachedDatabase.supportedLocales;
  $RecipeLocalizationsTable get recipeLocalizations =>
      attachedDatabase.recipeLocalizations;
}
mixin _$UserRecipePreferencesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BrewingMethodsTable get brewingMethods => attachedDatabase.brewingMethods;
  $VendorsTable get vendors => attachedDatabase.vendors;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $UserRecipePreferencesTable get userRecipePreferences =>
      attachedDatabase.userRecipePreferences;
}
mixin _$BrewingMethodsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BrewingMethodsTable get brewingMethods => attachedDatabase.brewingMethods;
}
mixin _$VendorsDaoMixin on DatabaseAccessor<AppDatabase> {
  $VendorsTable get vendors => attachedDatabase.vendors;
}
mixin _$SupportedLocalesDaoMixin on DatabaseAccessor<AppDatabase> {
  $SupportedLocalesTable get supportedLocales =>
      attachedDatabase.supportedLocales;
}
mixin _$CoffeeFactsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SupportedLocalesTable get supportedLocales =>
      attachedDatabase.supportedLocales;
  $CoffeeFactsTable get coffeeFacts => attachedDatabase.coffeeFacts;
}
mixin _$StartPopupsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SupportedLocalesTable get supportedLocales =>
      attachedDatabase.supportedLocales;
  $StartPopupsTable get startPopups => attachedDatabase.startPopups;
}
mixin _$ContributorsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SupportedLocalesTable get supportedLocales =>
      attachedDatabase.supportedLocales;
  $ContributorsTable get contributors => attachedDatabase.contributors;
}
