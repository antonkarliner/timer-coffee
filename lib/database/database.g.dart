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
  static const VerificationMeta _showOnMainMeta =
      const VerificationMeta('showOnMain');
  @override
  late final GeneratedColumn<bool> showOnMain = GeneratedColumn<bool>(
      'show_on_main', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_on_main" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [brewingMethodId, brewingMethod, showOnMain];
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
    if (data.containsKey('show_on_main')) {
      context.handle(
          _showOnMainMeta,
          showOnMain.isAcceptableOrUnknown(
              data['show_on_main']!, _showOnMainMeta));
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
      showOnMain: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_on_main'])!,
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
  final bool showOnMain;
  const BrewingMethod(
      {required this.brewingMethodId,
      required this.brewingMethod,
      required this.showOnMain});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['brewing_method_id'] = Variable<String>(brewingMethodId);
    map['brewing_method'] = Variable<String>(brewingMethod);
    map['show_on_main'] = Variable<bool>(showOnMain);
    return map;
  }

  BrewingMethodsCompanion toCompanion(bool nullToAbsent) {
    return BrewingMethodsCompanion(
      brewingMethodId: Value(brewingMethodId),
      brewingMethod: Value(brewingMethod),
      showOnMain: Value(showOnMain),
    );
  }

  factory BrewingMethod.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BrewingMethod(
      brewingMethodId: serializer.fromJson<String>(json['brewingMethodId']),
      brewingMethod: serializer.fromJson<String>(json['brewingMethod']),
      showOnMain: serializer.fromJson<bool>(json['showOnMain']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'brewingMethodId': serializer.toJson<String>(brewingMethodId),
      'brewingMethod': serializer.toJson<String>(brewingMethod),
      'showOnMain': serializer.toJson<bool>(showOnMain),
    };
  }

  BrewingMethod copyWith(
          {String? brewingMethodId, String? brewingMethod, bool? showOnMain}) =>
      BrewingMethod(
        brewingMethodId: brewingMethodId ?? this.brewingMethodId,
        brewingMethod: brewingMethod ?? this.brewingMethod,
        showOnMain: showOnMain ?? this.showOnMain,
      );
  @override
  String toString() {
    return (StringBuffer('BrewingMethod(')
          ..write('brewingMethodId: $brewingMethodId, ')
          ..write('brewingMethod: $brewingMethod, ')
          ..write('showOnMain: $showOnMain')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(brewingMethodId, brewingMethod, showOnMain);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrewingMethod &&
          other.brewingMethodId == this.brewingMethodId &&
          other.brewingMethod == this.brewingMethod &&
          other.showOnMain == this.showOnMain);
}

class BrewingMethodsCompanion extends UpdateCompanion<BrewingMethod> {
  final Value<String> brewingMethodId;
  final Value<String> brewingMethod;
  final Value<bool> showOnMain;
  final Value<int> rowid;
  const BrewingMethodsCompanion({
    this.brewingMethodId = const Value.absent(),
    this.brewingMethod = const Value.absent(),
    this.showOnMain = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BrewingMethodsCompanion.insert({
    required String brewingMethodId,
    required String brewingMethod,
    this.showOnMain = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : brewingMethodId = Value(brewingMethodId),
        brewingMethod = Value(brewingMethod);
  static Insertable<BrewingMethod> custom({
    Expression<String>? brewingMethodId,
    Expression<String>? brewingMethod,
    Expression<bool>? showOnMain,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (brewingMethodId != null) 'brewing_method_id': brewingMethodId,
      if (brewingMethod != null) 'brewing_method': brewingMethod,
      if (showOnMain != null) 'show_on_main': showOnMain,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BrewingMethodsCompanion copyWith(
      {Value<String>? brewingMethodId,
      Value<String>? brewingMethod,
      Value<bool>? showOnMain,
      Value<int>? rowid}) {
    return BrewingMethodsCompanion(
      brewingMethodId: brewingMethodId ?? this.brewingMethodId,
      brewingMethod: brewingMethod ?? this.brewingMethod,
      showOnMain: showOnMain ?? this.showOnMain,
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
    if (showOnMain.present) {
      map['show_on_main'] = Variable<bool>(showOnMain.value);
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
          ..write('showOnMain: $showOnMain, ')
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
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES brewing_methods (brewing_method_id) ON DELETE CASCADE'));
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
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES vendors (vendor_id) ON DELETE SET NULL'));
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
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recipes (id) ON DELETE CASCADE'));
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
      'locale', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 2, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES supported_locales (locale) ON DELETE CASCADE'));
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
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recipes (id) ON DELETE CASCADE'));
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
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES supported_locales (locale) ON DELETE CASCADE'));
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
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recipes (id) ON DELETE CASCADE'));
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
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES supported_locales (locale) ON DELETE CASCADE'));
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

class $LaunchPopupsTable extends LaunchPopups
    with TableInfo<$LaunchPopupsTable, LaunchPopup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LaunchPopupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
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
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES supported_locales (locale) ON DELETE CASCADE'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, content, locale, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'launch_popups';
  @override
  VerificationContext validateIntegrity(Insertable<LaunchPopup> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LaunchPopup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LaunchPopup(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      locale: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}locale'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LaunchPopupsTable createAlias(String alias) {
    return $LaunchPopupsTable(attachedDatabase, alias);
  }
}

class LaunchPopup extends DataClass implements Insertable<LaunchPopup> {
  final int id;
  final String content;
  final String locale;
  final DateTime createdAt;
  const LaunchPopup(
      {required this.id,
      required this.content,
      required this.locale,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    map['locale'] = Variable<String>(locale);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LaunchPopupsCompanion toCompanion(bool nullToAbsent) {
    return LaunchPopupsCompanion(
      id: Value(id),
      content: Value(content),
      locale: Value(locale),
      createdAt: Value(createdAt),
    );
  }

  factory LaunchPopup.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LaunchPopup(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      locale: serializer.fromJson<String>(json['locale']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'locale': serializer.toJson<String>(locale),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LaunchPopup copyWith(
          {int? id, String? content, String? locale, DateTime? createdAt}) =>
      LaunchPopup(
        id: id ?? this.id,
        content: content ?? this.content,
        locale: locale ?? this.locale,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('LaunchPopup(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('locale: $locale, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, content, locale, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LaunchPopup &&
          other.id == this.id &&
          other.content == this.content &&
          other.locale == this.locale &&
          other.createdAt == this.createdAt);
}

class LaunchPopupsCompanion extends UpdateCompanion<LaunchPopup> {
  final Value<int> id;
  final Value<String> content;
  final Value<String> locale;
  final Value<DateTime> createdAt;
  const LaunchPopupsCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.locale = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LaunchPopupsCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    required String locale,
    required DateTime createdAt,
  })  : content = Value(content),
        locale = Value(locale),
        createdAt = Value(createdAt);
  static Insertable<LaunchPopup> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<String>? locale,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (locale != null) 'locale': locale,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LaunchPopupsCompanion copyWith(
      {Value<int>? id,
      Value<String>? content,
      Value<String>? locale,
      Value<DateTime>? createdAt}) {
    return LaunchPopupsCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      locale: locale ?? this.locale,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LaunchPopupsCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('locale: $locale, ')
          ..write('createdAt: $createdAt')
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
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES supported_locales (locale) ON DELETE CASCADE'));
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

class $UserStatsTable extends UserStats
    with TableInfo<$UserStatsTable, UserStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recipeIdMeta =
      const VerificationMeta('recipeId');
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
      'recipe_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES recipes (id)'));
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
  static const VerificationMeta _sweetnessSliderPositionMeta =
      const VerificationMeta('sweetnessSliderPosition');
  @override
  late final GeneratedColumn<int> sweetnessSliderPosition =
      GeneratedColumn<int>('sweetness_slider_position', aliasedName, false,
          type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _strengthSliderPositionMeta =
      const VerificationMeta('strengthSliderPosition');
  @override
  late final GeneratedColumn<int> strengthSliderPosition = GeneratedColumn<int>(
      'strength_slider_position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _brewingMethodIdMeta =
      const VerificationMeta('brewingMethodId');
  @override
  late final GeneratedColumn<String> brewingMethodId = GeneratedColumn<String>(
      'brewing_method_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES brewing_methods (brewing_method_id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _beansMeta = const VerificationMeta('beans');
  @override
  late final GeneratedColumn<String> beans = GeneratedColumn<String>(
      'beans', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _roasterMeta =
      const VerificationMeta('roaster');
  @override
  late final GeneratedColumn<String> roaster = GeneratedColumn<String>(
      'roaster', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
      'rating', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _coffeeBeansIdMeta =
      const VerificationMeta('coffeeBeansId');
  @override
  late final GeneratedColumn<int> coffeeBeansId = GeneratedColumn<int>(
      'coffee_beans_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isMarkedMeta =
      const VerificationMeta('isMarked');
  @override
  late final GeneratedColumn<bool> isMarked = GeneratedColumn<bool>(
      'is_marked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_marked" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        recipeId,
        coffeeAmount,
        waterAmount,
        sweetnessSliderPosition,
        strengthSliderPosition,
        brewingMethodId,
        createdAt,
        notes,
        beans,
        roaster,
        rating,
        coffeeBeansId,
        isMarked
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_stats';
  @override
  VerificationContext validateIntegrity(Insertable<UserStat> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(_recipeIdMeta,
          recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta));
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
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
    if (data.containsKey('sweetness_slider_position')) {
      context.handle(
          _sweetnessSliderPositionMeta,
          sweetnessSliderPosition.isAcceptableOrUnknown(
              data['sweetness_slider_position']!,
              _sweetnessSliderPositionMeta));
    } else if (isInserting) {
      context.missing(_sweetnessSliderPositionMeta);
    }
    if (data.containsKey('strength_slider_position')) {
      context.handle(
          _strengthSliderPositionMeta,
          strengthSliderPosition.isAcceptableOrUnknown(
              data['strength_slider_position']!, _strengthSliderPositionMeta));
    } else if (isInserting) {
      context.missing(_strengthSliderPositionMeta);
    }
    if (data.containsKey('brewing_method_id')) {
      context.handle(
          _brewingMethodIdMeta,
          brewingMethodId.isAcceptableOrUnknown(
              data['brewing_method_id']!, _brewingMethodIdMeta));
    } else if (isInserting) {
      context.missing(_brewingMethodIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('beans')) {
      context.handle(
          _beansMeta, beans.isAcceptableOrUnknown(data['beans']!, _beansMeta));
    }
    if (data.containsKey('roaster')) {
      context.handle(_roasterMeta,
          roaster.isAcceptableOrUnknown(data['roaster']!, _roasterMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('coffee_beans_id')) {
      context.handle(
          _coffeeBeansIdMeta,
          coffeeBeansId.isAcceptableOrUnknown(
              data['coffee_beans_id']!, _coffeeBeansIdMeta));
    }
    if (data.containsKey('is_marked')) {
      context.handle(_isMarkedMeta,
          isMarked.isAcceptableOrUnknown(data['is_marked']!, _isMarkedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserStat(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      recipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_id'])!,
      coffeeAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}coffee_amount'])!,
      waterAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}water_amount'])!,
      sweetnessSliderPosition: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sweetness_slider_position'])!,
      strengthSliderPosition: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}strength_slider_position'])!,
      brewingMethodId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}brewing_method_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      beans: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}beans']),
      roaster: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}roaster']),
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating']),
      coffeeBeansId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}coffee_beans_id']),
      isMarked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_marked'])!,
    );
  }

  @override
  $UserStatsTable createAlias(String alias) {
    return $UserStatsTable(attachedDatabase, alias);
  }
}

class UserStat extends DataClass implements Insertable<UserStat> {
  final int id;
  final String userId;
  final String recipeId;
  final double coffeeAmount;
  final double waterAmount;
  final int sweetnessSliderPosition;
  final int strengthSliderPosition;
  final String brewingMethodId;
  final DateTime createdAt;
  final String? notes;
  final String? beans;
  final String? roaster;
  final double? rating;
  final int? coffeeBeansId;
  final bool isMarked;
  const UserStat(
      {required this.id,
      required this.userId,
      required this.recipeId,
      required this.coffeeAmount,
      required this.waterAmount,
      required this.sweetnessSliderPosition,
      required this.strengthSliderPosition,
      required this.brewingMethodId,
      required this.createdAt,
      this.notes,
      this.beans,
      this.roaster,
      this.rating,
      this.coffeeBeansId,
      required this.isMarked});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['recipe_id'] = Variable<String>(recipeId);
    map['coffee_amount'] = Variable<double>(coffeeAmount);
    map['water_amount'] = Variable<double>(waterAmount);
    map['sweetness_slider_position'] = Variable<int>(sweetnessSliderPosition);
    map['strength_slider_position'] = Variable<int>(strengthSliderPosition);
    map['brewing_method_id'] = Variable<String>(brewingMethodId);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || beans != null) {
      map['beans'] = Variable<String>(beans);
    }
    if (!nullToAbsent || roaster != null) {
      map['roaster'] = Variable<String>(roaster);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || coffeeBeansId != null) {
      map['coffee_beans_id'] = Variable<int>(coffeeBeansId);
    }
    map['is_marked'] = Variable<bool>(isMarked);
    return map;
  }

  UserStatsCompanion toCompanion(bool nullToAbsent) {
    return UserStatsCompanion(
      id: Value(id),
      userId: Value(userId),
      recipeId: Value(recipeId),
      coffeeAmount: Value(coffeeAmount),
      waterAmount: Value(waterAmount),
      sweetnessSliderPosition: Value(sweetnessSliderPosition),
      strengthSliderPosition: Value(strengthSliderPosition),
      brewingMethodId: Value(brewingMethodId),
      createdAt: Value(createdAt),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      beans:
          beans == null && nullToAbsent ? const Value.absent() : Value(beans),
      roaster: roaster == null && nullToAbsent
          ? const Value.absent()
          : Value(roaster),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      coffeeBeansId: coffeeBeansId == null && nullToAbsent
          ? const Value.absent()
          : Value(coffeeBeansId),
      isMarked: Value(isMarked),
    );
  }

  factory UserStat.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserStat(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      recipeId: serializer.fromJson<String>(json['recipeId']),
      coffeeAmount: serializer.fromJson<double>(json['coffeeAmount']),
      waterAmount: serializer.fromJson<double>(json['waterAmount']),
      sweetnessSliderPosition:
          serializer.fromJson<int>(json['sweetnessSliderPosition']),
      strengthSliderPosition:
          serializer.fromJson<int>(json['strengthSliderPosition']),
      brewingMethodId: serializer.fromJson<String>(json['brewingMethodId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      beans: serializer.fromJson<String?>(json['beans']),
      roaster: serializer.fromJson<String?>(json['roaster']),
      rating: serializer.fromJson<double?>(json['rating']),
      coffeeBeansId: serializer.fromJson<int?>(json['coffeeBeansId']),
      isMarked: serializer.fromJson<bool>(json['isMarked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'recipeId': serializer.toJson<String>(recipeId),
      'coffeeAmount': serializer.toJson<double>(coffeeAmount),
      'waterAmount': serializer.toJson<double>(waterAmount),
      'sweetnessSliderPosition':
          serializer.toJson<int>(sweetnessSliderPosition),
      'strengthSliderPosition': serializer.toJson<int>(strengthSliderPosition),
      'brewingMethodId': serializer.toJson<String>(brewingMethodId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'notes': serializer.toJson<String?>(notes),
      'beans': serializer.toJson<String?>(beans),
      'roaster': serializer.toJson<String?>(roaster),
      'rating': serializer.toJson<double?>(rating),
      'coffeeBeansId': serializer.toJson<int?>(coffeeBeansId),
      'isMarked': serializer.toJson<bool>(isMarked),
    };
  }

  UserStat copyWith(
          {int? id,
          String? userId,
          String? recipeId,
          double? coffeeAmount,
          double? waterAmount,
          int? sweetnessSliderPosition,
          int? strengthSliderPosition,
          String? brewingMethodId,
          DateTime? createdAt,
          Value<String?> notes = const Value.absent(),
          Value<String?> beans = const Value.absent(),
          Value<String?> roaster = const Value.absent(),
          Value<double?> rating = const Value.absent(),
          Value<int?> coffeeBeansId = const Value.absent(),
          bool? isMarked}) =>
      UserStat(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        recipeId: recipeId ?? this.recipeId,
        coffeeAmount: coffeeAmount ?? this.coffeeAmount,
        waterAmount: waterAmount ?? this.waterAmount,
        sweetnessSliderPosition:
            sweetnessSliderPosition ?? this.sweetnessSliderPosition,
        strengthSliderPosition:
            strengthSliderPosition ?? this.strengthSliderPosition,
        brewingMethodId: brewingMethodId ?? this.brewingMethodId,
        createdAt: createdAt ?? this.createdAt,
        notes: notes.present ? notes.value : this.notes,
        beans: beans.present ? beans.value : this.beans,
        roaster: roaster.present ? roaster.value : this.roaster,
        rating: rating.present ? rating.value : this.rating,
        coffeeBeansId:
            coffeeBeansId.present ? coffeeBeansId.value : this.coffeeBeansId,
        isMarked: isMarked ?? this.isMarked,
      );
  @override
  String toString() {
    return (StringBuffer('UserStat(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('recipeId: $recipeId, ')
          ..write('coffeeAmount: $coffeeAmount, ')
          ..write('waterAmount: $waterAmount, ')
          ..write('sweetnessSliderPosition: $sweetnessSliderPosition, ')
          ..write('strengthSliderPosition: $strengthSliderPosition, ')
          ..write('brewingMethodId: $brewingMethodId, ')
          ..write('createdAt: $createdAt, ')
          ..write('notes: $notes, ')
          ..write('beans: $beans, ')
          ..write('roaster: $roaster, ')
          ..write('rating: $rating, ')
          ..write('coffeeBeansId: $coffeeBeansId, ')
          ..write('isMarked: $isMarked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      recipeId,
      coffeeAmount,
      waterAmount,
      sweetnessSliderPosition,
      strengthSliderPosition,
      brewingMethodId,
      createdAt,
      notes,
      beans,
      roaster,
      rating,
      coffeeBeansId,
      isMarked);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserStat &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.recipeId == this.recipeId &&
          other.coffeeAmount == this.coffeeAmount &&
          other.waterAmount == this.waterAmount &&
          other.sweetnessSliderPosition == this.sweetnessSliderPosition &&
          other.strengthSliderPosition == this.strengthSliderPosition &&
          other.brewingMethodId == this.brewingMethodId &&
          other.createdAt == this.createdAt &&
          other.notes == this.notes &&
          other.beans == this.beans &&
          other.roaster == this.roaster &&
          other.rating == this.rating &&
          other.coffeeBeansId == this.coffeeBeansId &&
          other.isMarked == this.isMarked);
}

class UserStatsCompanion extends UpdateCompanion<UserStat> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> recipeId;
  final Value<double> coffeeAmount;
  final Value<double> waterAmount;
  final Value<int> sweetnessSliderPosition;
  final Value<int> strengthSliderPosition;
  final Value<String> brewingMethodId;
  final Value<DateTime> createdAt;
  final Value<String?> notes;
  final Value<String?> beans;
  final Value<String?> roaster;
  final Value<double?> rating;
  final Value<int?> coffeeBeansId;
  final Value<bool> isMarked;
  const UserStatsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.coffeeAmount = const Value.absent(),
    this.waterAmount = const Value.absent(),
    this.sweetnessSliderPosition = const Value.absent(),
    this.strengthSliderPosition = const Value.absent(),
    this.brewingMethodId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.beans = const Value.absent(),
    this.roaster = const Value.absent(),
    this.rating = const Value.absent(),
    this.coffeeBeansId = const Value.absent(),
    this.isMarked = const Value.absent(),
  });
  UserStatsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String recipeId,
    required double coffeeAmount,
    required double waterAmount,
    required int sweetnessSliderPosition,
    required int strengthSliderPosition,
    required String brewingMethodId,
    this.createdAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.beans = const Value.absent(),
    this.roaster = const Value.absent(),
    this.rating = const Value.absent(),
    this.coffeeBeansId = const Value.absent(),
    this.isMarked = const Value.absent(),
  })  : userId = Value(userId),
        recipeId = Value(recipeId),
        coffeeAmount = Value(coffeeAmount),
        waterAmount = Value(waterAmount),
        sweetnessSliderPosition = Value(sweetnessSliderPosition),
        strengthSliderPosition = Value(strengthSliderPosition),
        brewingMethodId = Value(brewingMethodId);
  static Insertable<UserStat> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? recipeId,
    Expression<double>? coffeeAmount,
    Expression<double>? waterAmount,
    Expression<int>? sweetnessSliderPosition,
    Expression<int>? strengthSliderPosition,
    Expression<String>? brewingMethodId,
    Expression<DateTime>? createdAt,
    Expression<String>? notes,
    Expression<String>? beans,
    Expression<String>? roaster,
    Expression<double>? rating,
    Expression<int>? coffeeBeansId,
    Expression<bool>? isMarked,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (recipeId != null) 'recipe_id': recipeId,
      if (coffeeAmount != null) 'coffee_amount': coffeeAmount,
      if (waterAmount != null) 'water_amount': waterAmount,
      if (sweetnessSliderPosition != null)
        'sweetness_slider_position': sweetnessSliderPosition,
      if (strengthSliderPosition != null)
        'strength_slider_position': strengthSliderPosition,
      if (brewingMethodId != null) 'brewing_method_id': brewingMethodId,
      if (createdAt != null) 'created_at': createdAt,
      if (notes != null) 'notes': notes,
      if (beans != null) 'beans': beans,
      if (roaster != null) 'roaster': roaster,
      if (rating != null) 'rating': rating,
      if (coffeeBeansId != null) 'coffee_beans_id': coffeeBeansId,
      if (isMarked != null) 'is_marked': isMarked,
    });
  }

  UserStatsCompanion copyWith(
      {Value<int>? id,
      Value<String>? userId,
      Value<String>? recipeId,
      Value<double>? coffeeAmount,
      Value<double>? waterAmount,
      Value<int>? sweetnessSliderPosition,
      Value<int>? strengthSliderPosition,
      Value<String>? brewingMethodId,
      Value<DateTime>? createdAt,
      Value<String?>? notes,
      Value<String?>? beans,
      Value<String?>? roaster,
      Value<double?>? rating,
      Value<int?>? coffeeBeansId,
      Value<bool>? isMarked}) {
    return UserStatsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipeId: recipeId ?? this.recipeId,
      coffeeAmount: coffeeAmount ?? this.coffeeAmount,
      waterAmount: waterAmount ?? this.waterAmount,
      sweetnessSliderPosition:
          sweetnessSliderPosition ?? this.sweetnessSliderPosition,
      strengthSliderPosition:
          strengthSliderPosition ?? this.strengthSliderPosition,
      brewingMethodId: brewingMethodId ?? this.brewingMethodId,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      beans: beans ?? this.beans,
      roaster: roaster ?? this.roaster,
      rating: rating ?? this.rating,
      coffeeBeansId: coffeeBeansId ?? this.coffeeBeansId,
      isMarked: isMarked ?? this.isMarked,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (coffeeAmount.present) {
      map['coffee_amount'] = Variable<double>(coffeeAmount.value);
    }
    if (waterAmount.present) {
      map['water_amount'] = Variable<double>(waterAmount.value);
    }
    if (sweetnessSliderPosition.present) {
      map['sweetness_slider_position'] =
          Variable<int>(sweetnessSliderPosition.value);
    }
    if (strengthSliderPosition.present) {
      map['strength_slider_position'] =
          Variable<int>(strengthSliderPosition.value);
    }
    if (brewingMethodId.present) {
      map['brewing_method_id'] = Variable<String>(brewingMethodId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (beans.present) {
      map['beans'] = Variable<String>(beans.value);
    }
    if (roaster.present) {
      map['roaster'] = Variable<String>(roaster.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (coffeeBeansId.present) {
      map['coffee_beans_id'] = Variable<int>(coffeeBeansId.value);
    }
    if (isMarked.present) {
      map['is_marked'] = Variable<bool>(isMarked.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserStatsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('recipeId: $recipeId, ')
          ..write('coffeeAmount: $coffeeAmount, ')
          ..write('waterAmount: $waterAmount, ')
          ..write('sweetnessSliderPosition: $sweetnessSliderPosition, ')
          ..write('strengthSliderPosition: $strengthSliderPosition, ')
          ..write('brewingMethodId: $brewingMethodId, ')
          ..write('createdAt: $createdAt, ')
          ..write('notes: $notes, ')
          ..write('beans: $beans, ')
          ..write('roaster: $roaster, ')
          ..write('rating: $rating, ')
          ..write('coffeeBeansId: $coffeeBeansId, ')
          ..write('isMarked: $isMarked')
          ..write(')'))
        .toString();
  }
}

class $CoffeeBeansTable extends CoffeeBeans
    with TableInfo<$CoffeeBeansTable, CoffeeBean> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoffeeBeansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _roasterMeta =
      const VerificationMeta('roaster');
  @override
  late final GeneratedColumn<String> roaster = GeneratedColumn<String>(
      'roaster', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
      'origin', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _varietyMeta =
      const VerificationMeta('variety');
  @override
  late final GeneratedColumn<String> variety = GeneratedColumn<String>(
      'variety', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tastingNotesMeta =
      const VerificationMeta('tastingNotes');
  @override
  late final GeneratedColumn<String> tastingNotes = GeneratedColumn<String>(
      'tasting_notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _processingMethodMeta =
      const VerificationMeta('processingMethod');
  @override
  late final GeneratedColumn<String> processingMethod = GeneratedColumn<String>(
      'processing_method', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _elevationMeta =
      const VerificationMeta('elevation');
  @override
  late final GeneratedColumn<int> elevation = GeneratedColumn<int>(
      'elevation', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _harvestDateMeta =
      const VerificationMeta('harvestDate');
  @override
  late final GeneratedColumn<DateTime> harvestDate = GeneratedColumn<DateTime>(
      'harvest_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _roastDateMeta =
      const VerificationMeta('roastDate');
  @override
  late final GeneratedColumn<DateTime> roastDate = GeneratedColumn<DateTime>(
      'roast_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
      'region', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _roastLevelMeta =
      const VerificationMeta('roastLevel');
  @override
  late final GeneratedColumn<String> roastLevel = GeneratedColumn<String>(
      'roast_level', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cuppingScoreMeta =
      const VerificationMeta('cuppingScore');
  @override
  late final GeneratedColumn<double> cuppingScore = GeneratedColumn<double>(
      'cupping_score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        roaster,
        name,
        origin,
        variety,
        tastingNotes,
        processingMethod,
        elevation,
        harvestDate,
        roastDate,
        region,
        roastLevel,
        cuppingScore,
        notes,
        isFavorite
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coffee_beans';
  @override
  VerificationContext validateIntegrity(Insertable<CoffeeBean> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('roaster')) {
      context.handle(_roasterMeta,
          roaster.isAcceptableOrUnknown(data['roaster']!, _roasterMeta));
    } else if (isInserting) {
      context.missing(_roasterMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(_originMeta,
          origin.isAcceptableOrUnknown(data['origin']!, _originMeta));
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('variety')) {
      context.handle(_varietyMeta,
          variety.isAcceptableOrUnknown(data['variety']!, _varietyMeta));
    }
    if (data.containsKey('tasting_notes')) {
      context.handle(
          _tastingNotesMeta,
          tastingNotes.isAcceptableOrUnknown(
              data['tasting_notes']!, _tastingNotesMeta));
    }
    if (data.containsKey('processing_method')) {
      context.handle(
          _processingMethodMeta,
          processingMethod.isAcceptableOrUnknown(
              data['processing_method']!, _processingMethodMeta));
    }
    if (data.containsKey('elevation')) {
      context.handle(_elevationMeta,
          elevation.isAcceptableOrUnknown(data['elevation']!, _elevationMeta));
    }
    if (data.containsKey('harvest_date')) {
      context.handle(
          _harvestDateMeta,
          harvestDate.isAcceptableOrUnknown(
              data['harvest_date']!, _harvestDateMeta));
    }
    if (data.containsKey('roast_date')) {
      context.handle(_roastDateMeta,
          roastDate.isAcceptableOrUnknown(data['roast_date']!, _roastDateMeta));
    }
    if (data.containsKey('region')) {
      context.handle(_regionMeta,
          region.isAcceptableOrUnknown(data['region']!, _regionMeta));
    }
    if (data.containsKey('roast_level')) {
      context.handle(
          _roastLevelMeta,
          roastLevel.isAcceptableOrUnknown(
              data['roast_level']!, _roastLevelMeta));
    }
    if (data.containsKey('cupping_score')) {
      context.handle(
          _cuppingScoreMeta,
          cuppingScore.isAcceptableOrUnknown(
              data['cupping_score']!, _cuppingScoreMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CoffeeBean map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoffeeBean(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      roaster: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}roaster'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      origin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}origin'])!,
      variety: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}variety']),
      tastingNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tasting_notes']),
      processingMethod: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}processing_method']),
      elevation: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}elevation']),
      harvestDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}harvest_date']),
      roastDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}roast_date']),
      region: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}region']),
      roastLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}roast_level']),
      cuppingScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cupping_score']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
    );
  }

  @override
  $CoffeeBeansTable createAlias(String alias) {
    return $CoffeeBeansTable(attachedDatabase, alias);
  }
}

class CoffeeBean extends DataClass implements Insertable<CoffeeBean> {
  final int id;
  final String roaster;
  final String name;
  final String origin;
  final String? variety;
  final String? tastingNotes;
  final String? processingMethod;
  final int? elevation;
  final DateTime? harvestDate;
  final DateTime? roastDate;
  final String? region;
  final String? roastLevel;
  final double? cuppingScore;
  final String? notes;
  final bool isFavorite;
  const CoffeeBean(
      {required this.id,
      required this.roaster,
      required this.name,
      required this.origin,
      this.variety,
      this.tastingNotes,
      this.processingMethod,
      this.elevation,
      this.harvestDate,
      this.roastDate,
      this.region,
      this.roastLevel,
      this.cuppingScore,
      this.notes,
      required this.isFavorite});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['roaster'] = Variable<String>(roaster);
    map['name'] = Variable<String>(name);
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || variety != null) {
      map['variety'] = Variable<String>(variety);
    }
    if (!nullToAbsent || tastingNotes != null) {
      map['tasting_notes'] = Variable<String>(tastingNotes);
    }
    if (!nullToAbsent || processingMethod != null) {
      map['processing_method'] = Variable<String>(processingMethod);
    }
    if (!nullToAbsent || elevation != null) {
      map['elevation'] = Variable<int>(elevation);
    }
    if (!nullToAbsent || harvestDate != null) {
      map['harvest_date'] = Variable<DateTime>(harvestDate);
    }
    if (!nullToAbsent || roastDate != null) {
      map['roast_date'] = Variable<DateTime>(roastDate);
    }
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    if (!nullToAbsent || roastLevel != null) {
      map['roast_level'] = Variable<String>(roastLevel);
    }
    if (!nullToAbsent || cuppingScore != null) {
      map['cupping_score'] = Variable<double>(cuppingScore);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  CoffeeBeansCompanion toCompanion(bool nullToAbsent) {
    return CoffeeBeansCompanion(
      id: Value(id),
      roaster: Value(roaster),
      name: Value(name),
      origin: Value(origin),
      variety: variety == null && nullToAbsent
          ? const Value.absent()
          : Value(variety),
      tastingNotes: tastingNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(tastingNotes),
      processingMethod: processingMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(processingMethod),
      elevation: elevation == null && nullToAbsent
          ? const Value.absent()
          : Value(elevation),
      harvestDate: harvestDate == null && nullToAbsent
          ? const Value.absent()
          : Value(harvestDate),
      roastDate: roastDate == null && nullToAbsent
          ? const Value.absent()
          : Value(roastDate),
      region:
          region == null && nullToAbsent ? const Value.absent() : Value(region),
      roastLevel: roastLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(roastLevel),
      cuppingScore: cuppingScore == null && nullToAbsent
          ? const Value.absent()
          : Value(cuppingScore),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      isFavorite: Value(isFavorite),
    );
  }

  factory CoffeeBean.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoffeeBean(
      id: serializer.fromJson<int>(json['id']),
      roaster: serializer.fromJson<String>(json['roaster']),
      name: serializer.fromJson<String>(json['name']),
      origin: serializer.fromJson<String>(json['origin']),
      variety: serializer.fromJson<String?>(json['variety']),
      tastingNotes: serializer.fromJson<String?>(json['tastingNotes']),
      processingMethod: serializer.fromJson<String?>(json['processingMethod']),
      elevation: serializer.fromJson<int?>(json['elevation']),
      harvestDate: serializer.fromJson<DateTime?>(json['harvestDate']),
      roastDate: serializer.fromJson<DateTime?>(json['roastDate']),
      region: serializer.fromJson<String?>(json['region']),
      roastLevel: serializer.fromJson<String?>(json['roastLevel']),
      cuppingScore: serializer.fromJson<double?>(json['cuppingScore']),
      notes: serializer.fromJson<String?>(json['notes']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'roaster': serializer.toJson<String>(roaster),
      'name': serializer.toJson<String>(name),
      'origin': serializer.toJson<String>(origin),
      'variety': serializer.toJson<String?>(variety),
      'tastingNotes': serializer.toJson<String?>(tastingNotes),
      'processingMethod': serializer.toJson<String?>(processingMethod),
      'elevation': serializer.toJson<int?>(elevation),
      'harvestDate': serializer.toJson<DateTime?>(harvestDate),
      'roastDate': serializer.toJson<DateTime?>(roastDate),
      'region': serializer.toJson<String?>(region),
      'roastLevel': serializer.toJson<String?>(roastLevel),
      'cuppingScore': serializer.toJson<double?>(cuppingScore),
      'notes': serializer.toJson<String?>(notes),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  CoffeeBean copyWith(
          {int? id,
          String? roaster,
          String? name,
          String? origin,
          Value<String?> variety = const Value.absent(),
          Value<String?> tastingNotes = const Value.absent(),
          Value<String?> processingMethod = const Value.absent(),
          Value<int?> elevation = const Value.absent(),
          Value<DateTime?> harvestDate = const Value.absent(),
          Value<DateTime?> roastDate = const Value.absent(),
          Value<String?> region = const Value.absent(),
          Value<String?> roastLevel = const Value.absent(),
          Value<double?> cuppingScore = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          bool? isFavorite}) =>
      CoffeeBean(
        id: id ?? this.id,
        roaster: roaster ?? this.roaster,
        name: name ?? this.name,
        origin: origin ?? this.origin,
        variety: variety.present ? variety.value : this.variety,
        tastingNotes:
            tastingNotes.present ? tastingNotes.value : this.tastingNotes,
        processingMethod: processingMethod.present
            ? processingMethod.value
            : this.processingMethod,
        elevation: elevation.present ? elevation.value : this.elevation,
        harvestDate: harvestDate.present ? harvestDate.value : this.harvestDate,
        roastDate: roastDate.present ? roastDate.value : this.roastDate,
        region: region.present ? region.value : this.region,
        roastLevel: roastLevel.present ? roastLevel.value : this.roastLevel,
        cuppingScore:
            cuppingScore.present ? cuppingScore.value : this.cuppingScore,
        notes: notes.present ? notes.value : this.notes,
        isFavorite: isFavorite ?? this.isFavorite,
      );
  @override
  String toString() {
    return (StringBuffer('CoffeeBean(')
          ..write('id: $id, ')
          ..write('roaster: $roaster, ')
          ..write('name: $name, ')
          ..write('origin: $origin, ')
          ..write('variety: $variety, ')
          ..write('tastingNotes: $tastingNotes, ')
          ..write('processingMethod: $processingMethod, ')
          ..write('elevation: $elevation, ')
          ..write('harvestDate: $harvestDate, ')
          ..write('roastDate: $roastDate, ')
          ..write('region: $region, ')
          ..write('roastLevel: $roastLevel, ')
          ..write('cuppingScore: $cuppingScore, ')
          ..write('notes: $notes, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      roaster,
      name,
      origin,
      variety,
      tastingNotes,
      processingMethod,
      elevation,
      harvestDate,
      roastDate,
      region,
      roastLevel,
      cuppingScore,
      notes,
      isFavorite);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoffeeBean &&
          other.id == this.id &&
          other.roaster == this.roaster &&
          other.name == this.name &&
          other.origin == this.origin &&
          other.variety == this.variety &&
          other.tastingNotes == this.tastingNotes &&
          other.processingMethod == this.processingMethod &&
          other.elevation == this.elevation &&
          other.harvestDate == this.harvestDate &&
          other.roastDate == this.roastDate &&
          other.region == this.region &&
          other.roastLevel == this.roastLevel &&
          other.cuppingScore == this.cuppingScore &&
          other.notes == this.notes &&
          other.isFavorite == this.isFavorite);
}

class CoffeeBeansCompanion extends UpdateCompanion<CoffeeBean> {
  final Value<int> id;
  final Value<String> roaster;
  final Value<String> name;
  final Value<String> origin;
  final Value<String?> variety;
  final Value<String?> tastingNotes;
  final Value<String?> processingMethod;
  final Value<int?> elevation;
  final Value<DateTime?> harvestDate;
  final Value<DateTime?> roastDate;
  final Value<String?> region;
  final Value<String?> roastLevel;
  final Value<double?> cuppingScore;
  final Value<String?> notes;
  final Value<bool> isFavorite;
  const CoffeeBeansCompanion({
    this.id = const Value.absent(),
    this.roaster = const Value.absent(),
    this.name = const Value.absent(),
    this.origin = const Value.absent(),
    this.variety = const Value.absent(),
    this.tastingNotes = const Value.absent(),
    this.processingMethod = const Value.absent(),
    this.elevation = const Value.absent(),
    this.harvestDate = const Value.absent(),
    this.roastDate = const Value.absent(),
    this.region = const Value.absent(),
    this.roastLevel = const Value.absent(),
    this.cuppingScore = const Value.absent(),
    this.notes = const Value.absent(),
    this.isFavorite = const Value.absent(),
  });
  CoffeeBeansCompanion.insert({
    this.id = const Value.absent(),
    required String roaster,
    required String name,
    required String origin,
    this.variety = const Value.absent(),
    this.tastingNotes = const Value.absent(),
    this.processingMethod = const Value.absent(),
    this.elevation = const Value.absent(),
    this.harvestDate = const Value.absent(),
    this.roastDate = const Value.absent(),
    this.region = const Value.absent(),
    this.roastLevel = const Value.absent(),
    this.cuppingScore = const Value.absent(),
    this.notes = const Value.absent(),
    this.isFavorite = const Value.absent(),
  })  : roaster = Value(roaster),
        name = Value(name),
        origin = Value(origin);
  static Insertable<CoffeeBean> custom({
    Expression<int>? id,
    Expression<String>? roaster,
    Expression<String>? name,
    Expression<String>? origin,
    Expression<String>? variety,
    Expression<String>? tastingNotes,
    Expression<String>? processingMethod,
    Expression<int>? elevation,
    Expression<DateTime>? harvestDate,
    Expression<DateTime>? roastDate,
    Expression<String>? region,
    Expression<String>? roastLevel,
    Expression<double>? cuppingScore,
    Expression<String>? notes,
    Expression<bool>? isFavorite,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roaster != null) 'roaster': roaster,
      if (name != null) 'name': name,
      if (origin != null) 'origin': origin,
      if (variety != null) 'variety': variety,
      if (tastingNotes != null) 'tasting_notes': tastingNotes,
      if (processingMethod != null) 'processing_method': processingMethod,
      if (elevation != null) 'elevation': elevation,
      if (harvestDate != null) 'harvest_date': harvestDate,
      if (roastDate != null) 'roast_date': roastDate,
      if (region != null) 'region': region,
      if (roastLevel != null) 'roast_level': roastLevel,
      if (cuppingScore != null) 'cupping_score': cuppingScore,
      if (notes != null) 'notes': notes,
      if (isFavorite != null) 'is_favorite': isFavorite,
    });
  }

  CoffeeBeansCompanion copyWith(
      {Value<int>? id,
      Value<String>? roaster,
      Value<String>? name,
      Value<String>? origin,
      Value<String?>? variety,
      Value<String?>? tastingNotes,
      Value<String?>? processingMethod,
      Value<int?>? elevation,
      Value<DateTime?>? harvestDate,
      Value<DateTime?>? roastDate,
      Value<String?>? region,
      Value<String?>? roastLevel,
      Value<double?>? cuppingScore,
      Value<String?>? notes,
      Value<bool>? isFavorite}) {
    return CoffeeBeansCompanion(
      id: id ?? this.id,
      roaster: roaster ?? this.roaster,
      name: name ?? this.name,
      origin: origin ?? this.origin,
      variety: variety ?? this.variety,
      tastingNotes: tastingNotes ?? this.tastingNotes,
      processingMethod: processingMethod ?? this.processingMethod,
      elevation: elevation ?? this.elevation,
      harvestDate: harvestDate ?? this.harvestDate,
      roastDate: roastDate ?? this.roastDate,
      region: region ?? this.region,
      roastLevel: roastLevel ?? this.roastLevel,
      cuppingScore: cuppingScore ?? this.cuppingScore,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (roaster.present) {
      map['roaster'] = Variable<String>(roaster.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (variety.present) {
      map['variety'] = Variable<String>(variety.value);
    }
    if (tastingNotes.present) {
      map['tasting_notes'] = Variable<String>(tastingNotes.value);
    }
    if (processingMethod.present) {
      map['processing_method'] = Variable<String>(processingMethod.value);
    }
    if (elevation.present) {
      map['elevation'] = Variable<int>(elevation.value);
    }
    if (harvestDate.present) {
      map['harvest_date'] = Variable<DateTime>(harvestDate.value);
    }
    if (roastDate.present) {
      map['roast_date'] = Variable<DateTime>(roastDate.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (roastLevel.present) {
      map['roast_level'] = Variable<String>(roastLevel.value);
    }
    if (cuppingScore.present) {
      map['cupping_score'] = Variable<double>(cuppingScore.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoffeeBeansCompanion(')
          ..write('id: $id, ')
          ..write('roaster: $roaster, ')
          ..write('name: $name, ')
          ..write('origin: $origin, ')
          ..write('variety: $variety, ')
          ..write('tastingNotes: $tastingNotes, ')
          ..write('processingMethod: $processingMethod, ')
          ..write('elevation: $elevation, ')
          ..write('harvestDate: $harvestDate, ')
          ..write('roastDate: $roastDate, ')
          ..write('region: $region, ')
          ..write('roastLevel: $roastLevel, ')
          ..write('cuppingScore: $cuppingScore, ')
          ..write('notes: $notes, ')
          ..write('isFavorite: $isFavorite')
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
  late final $LaunchPopupsTable launchPopups = $LaunchPopupsTable(this);
  late final $ContributorsTable contributors = $ContributorsTable(this);
  late final $UserStatsTable userStats = $UserStatsTable(this);
  late final $CoffeeBeansTable coffeeBeans = $CoffeeBeansTable(this);
  late final Index idxRecipesLastModified = Index('idx_recipes_last_modified',
      'CREATE INDEX idx_recipes_last_modified ON recipes (last_modified)');
  late final Index idxLaunchPopupsCreatedAt = Index(
      'idx_launch_popups_created_at',
      'CREATE INDEX idx_launch_popups_created_at ON launch_popups (created_at)');
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
  late final ContributorsDao contributorsDao =
      ContributorsDao(this as AppDatabase);
  late final UserStatsDao userStatsDao = UserStatsDao(this as AppDatabase);
  late final LaunchPopupsDao launchPopupsDao =
      LaunchPopupsDao(this as AppDatabase);
  late final CoffeeBeansDao coffeeBeansDao =
      CoffeeBeansDao(this as AppDatabase);
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
        launchPopups,
        contributors,
        userStats,
        coffeeBeans,
        idxRecipesLastModified,
        idxLaunchPopupsCreatedAt
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('brewing_methods',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recipes', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('vendors',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recipes', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('recipes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recipe_localizations', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('supported_locales',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recipe_localizations', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('recipes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('steps', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('supported_locales',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('steps', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('recipes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('user_recipe_preferences', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('supported_locales',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('coffee_facts', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('supported_locales',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('launch_popups', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('supported_locales',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('contributors', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
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
mixin _$ContributorsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SupportedLocalesTable get supportedLocales =>
      attachedDatabase.supportedLocales;
  $ContributorsTable get contributors => attachedDatabase.contributors;
}
mixin _$UserStatsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BrewingMethodsTable get brewingMethods => attachedDatabase.brewingMethods;
  $VendorsTable get vendors => attachedDatabase.vendors;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $UserStatsTable get userStats => attachedDatabase.userStats;
}
mixin _$LaunchPopupsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SupportedLocalesTable get supportedLocales =>
      attachedDatabase.supportedLocales;
  $LaunchPopupsTable get launchPopups => attachedDatabase.launchPopups;
}
mixin _$CoffeeBeansDaoMixin on DatabaseAccessor<AppDatabase> {
  $CoffeeBeansTable get coffeeBeans => attachedDatabase.coffeeBeans;
}
