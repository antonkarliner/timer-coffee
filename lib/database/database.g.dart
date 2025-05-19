// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
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
  SupportedLocale copyWithCompanion(SupportedLocalesCompanion data) {
    return SupportedLocale(
      locale: data.locale.present ? data.locale.value : this.locale,
      localeName:
          data.localeName.present ? data.localeName.value : this.localeName,
    );
  }

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
  BrewingMethod copyWithCompanion(BrewingMethodsCompanion data) {
    return BrewingMethod(
      brewingMethodId: data.brewingMethodId.present
          ? data.brewingMethodId.value
          : this.brewingMethodId,
      brewingMethod: data.brewingMethod.present
          ? data.brewingMethod.value
          : this.brewingMethod,
    );
  }

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
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _importIdMeta =
      const VerificationMeta('importId');
  @override
  late final GeneratedColumn<String> importId = GeneratedColumn<String>(
      'import_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isImportedMeta =
      const VerificationMeta('isImported');
  @override
  late final GeneratedColumn<bool> isImported = GeneratedColumn<bool>(
      'is_imported', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_imported" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _needsModerationReviewMeta =
      const VerificationMeta('needsModerationReview');
  @override
  late final GeneratedColumn<bool> needsModerationReview =
      GeneratedColumn<bool>('needs_moderation_review', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("needs_moderation_review" IN (0, 1))'),
          defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        brewingMethodId,
        coffeeAmount,
        waterAmount,
        waterTemp,
        brewTime,
        vendorId,
        lastModified,
        importId,
        isImported,
        needsModerationReview
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
    if (data.containsKey('import_id')) {
      context.handle(_importIdMeta,
          importId.isAcceptableOrUnknown(data['import_id']!, _importIdMeta));
    }
    if (data.containsKey('is_imported')) {
      context.handle(
          _isImportedMeta,
          isImported.isAcceptableOrUnknown(
              data['is_imported']!, _isImportedMeta));
    }
    if (data.containsKey('needs_moderation_review')) {
      context.handle(
          _needsModerationReviewMeta,
          needsModerationReview.isAcceptableOrUnknown(
              data['needs_moderation_review']!, _needsModerationReviewMeta));
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
      importId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}import_id']),
      isImported: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_imported'])!,
      needsModerationReview: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}needs_moderation_review'])!,
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
  final String? importId;
  final bool isImported;
  final bool needsModerationReview;
  const Recipe(
      {required this.id,
      required this.brewingMethodId,
      required this.coffeeAmount,
      required this.waterAmount,
      required this.waterTemp,
      required this.brewTime,
      this.vendorId,
      this.lastModified,
      this.importId,
      required this.isImported,
      required this.needsModerationReview});
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
    if (!nullToAbsent || importId != null) {
      map['import_id'] = Variable<String>(importId);
    }
    map['is_imported'] = Variable<bool>(isImported);
    map['needs_moderation_review'] = Variable<bool>(needsModerationReview);
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
      importId: importId == null && nullToAbsent
          ? const Value.absent()
          : Value(importId),
      isImported: Value(isImported),
      needsModerationReview: Value(needsModerationReview),
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
      importId: serializer.fromJson<String?>(json['importId']),
      isImported: serializer.fromJson<bool>(json['isImported']),
      needsModerationReview:
          serializer.fromJson<bool>(json['needsModerationReview']),
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
      'importId': serializer.toJson<String?>(importId),
      'isImported': serializer.toJson<bool>(isImported),
      'needsModerationReview': serializer.toJson<bool>(needsModerationReview),
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
          Value<DateTime?> lastModified = const Value.absent(),
          Value<String?> importId = const Value.absent(),
          bool? isImported,
          bool? needsModerationReview}) =>
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
        importId: importId.present ? importId.value : this.importId,
        isImported: isImported ?? this.isImported,
        needsModerationReview:
            needsModerationReview ?? this.needsModerationReview,
      );
  Recipe copyWithCompanion(RecipesCompanion data) {
    return Recipe(
      id: data.id.present ? data.id.value : this.id,
      brewingMethodId: data.brewingMethodId.present
          ? data.brewingMethodId.value
          : this.brewingMethodId,
      coffeeAmount: data.coffeeAmount.present
          ? data.coffeeAmount.value
          : this.coffeeAmount,
      waterAmount:
          data.waterAmount.present ? data.waterAmount.value : this.waterAmount,
      waterTemp: data.waterTemp.present ? data.waterTemp.value : this.waterTemp,
      brewTime: data.brewTime.present ? data.brewTime.value : this.brewTime,
      vendorId: data.vendorId.present ? data.vendorId.value : this.vendorId,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      importId: data.importId.present ? data.importId.value : this.importId,
      isImported:
          data.isImported.present ? data.isImported.value : this.isImported,
      needsModerationReview: data.needsModerationReview.present
          ? data.needsModerationReview.value
          : this.needsModerationReview,
    );
  }

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
          ..write('lastModified: $lastModified, ')
          ..write('importId: $importId, ')
          ..write('isImported: $isImported, ')
          ..write('needsModerationReview: $needsModerationReview')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      brewingMethodId,
      coffeeAmount,
      waterAmount,
      waterTemp,
      brewTime,
      vendorId,
      lastModified,
      importId,
      isImported,
      needsModerationReview);
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
          other.lastModified == this.lastModified &&
          other.importId == this.importId &&
          other.isImported == this.isImported &&
          other.needsModerationReview == this.needsModerationReview);
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
  final Value<String?> importId;
  final Value<bool> isImported;
  final Value<bool> needsModerationReview;
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
    this.importId = const Value.absent(),
    this.isImported = const Value.absent(),
    this.needsModerationReview = const Value.absent(),
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
    this.importId = const Value.absent(),
    this.isImported = const Value.absent(),
    this.needsModerationReview = const Value.absent(),
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
    Expression<String>? importId,
    Expression<bool>? isImported,
    Expression<bool>? needsModerationReview,
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
      if (importId != null) 'import_id': importId,
      if (isImported != null) 'is_imported': isImported,
      if (needsModerationReview != null)
        'needs_moderation_review': needsModerationReview,
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
      Value<String?>? importId,
      Value<bool>? isImported,
      Value<bool>? needsModerationReview,
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
      importId: importId ?? this.importId,
      isImported: isImported ?? this.isImported,
      needsModerationReview:
          needsModerationReview ?? this.needsModerationReview,
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
    if (importId.present) {
      map['import_id'] = Variable<String>(importId.value);
    }
    if (isImported.present) {
      map['is_imported'] = Variable<bool>(isImported.value);
    }
    if (needsModerationReview.present) {
      map['needs_moderation_review'] =
          Variable<bool>(needsModerationReview.value);
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
          ..write('importId: $importId, ')
          ..write('isImported: $isImported, ')
          ..write('needsModerationReview: $needsModerationReview, ')
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
  RecipeLocalization copyWithCompanion(RecipeLocalizationsCompanion data) {
    return RecipeLocalization(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      locale: data.locale.present ? data.locale.value : this.locale,
      name: data.name.present ? data.name.value : this.name,
      grindSize: data.grindSize.present ? data.grindSize.value : this.grindSize,
      shortDescription: data.shortDescription.present
          ? data.shortDescription.value
          : this.shortDescription,
    );
  }

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
  Step copyWithCompanion(StepsCompanion data) {
    return Step(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      stepOrder: data.stepOrder.present ? data.stepOrder.value : this.stepOrder,
      description:
          data.description.present ? data.description.value : this.description,
      time: data.time.present ? data.time.value : this.time,
      locale: data.locale.present ? data.locale.value : this.locale,
    );
  }

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
  static const VerificationMeta _coffeeChroniclerSliderPositionMeta =
      const VerificationMeta('coffeeChroniclerSliderPosition');
  @override
  late final GeneratedColumn<int> coffeeChroniclerSliderPosition =
      GeneratedColumn<int>(
          'coffee_chronicler_slider_position', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        recipeId,
        lastUsed,
        isFavorite,
        sweetnessSliderPosition,
        strengthSliderPosition,
        customCoffeeAmount,
        customWaterAmount,
        coffeeChroniclerSliderPosition
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
    if (data.containsKey('coffee_chronicler_slider_position')) {
      context.handle(
          _coffeeChroniclerSliderPositionMeta,
          coffeeChroniclerSliderPosition.isAcceptableOrUnknown(
              data['coffee_chronicler_slider_position']!,
              _coffeeChroniclerSliderPositionMeta));
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
      coffeeChroniclerSliderPosition: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}coffee_chronicler_slider_position'])!,
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
  final int coffeeChroniclerSliderPosition;
  const UserRecipePreference(
      {required this.recipeId,
      this.lastUsed,
      required this.isFavorite,
      required this.sweetnessSliderPosition,
      required this.strengthSliderPosition,
      this.customCoffeeAmount,
      this.customWaterAmount,
      required this.coffeeChroniclerSliderPosition});
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
    map['coffee_chronicler_slider_position'] =
        Variable<int>(coffeeChroniclerSliderPosition);
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
      coffeeChroniclerSliderPosition: Value(coffeeChroniclerSliderPosition),
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
      coffeeChroniclerSliderPosition:
          serializer.fromJson<int>(json['coffeeChroniclerSliderPosition']),
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
      'coffeeChroniclerSliderPosition':
          serializer.toJson<int>(coffeeChroniclerSliderPosition),
    };
  }

  UserRecipePreference copyWith(
          {String? recipeId,
          Value<DateTime?> lastUsed = const Value.absent(),
          bool? isFavorite,
          int? sweetnessSliderPosition,
          int? strengthSliderPosition,
          Value<double?> customCoffeeAmount = const Value.absent(),
          Value<double?> customWaterAmount = const Value.absent(),
          int? coffeeChroniclerSliderPosition}) =>
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
        coffeeChroniclerSliderPosition: coffeeChroniclerSliderPosition ??
            this.coffeeChroniclerSliderPosition,
      );
  UserRecipePreference copyWithCompanion(UserRecipePreferencesCompanion data) {
    return UserRecipePreference(
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      lastUsed: data.lastUsed.present ? data.lastUsed.value : this.lastUsed,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      sweetnessSliderPosition: data.sweetnessSliderPosition.present
          ? data.sweetnessSliderPosition.value
          : this.sweetnessSliderPosition,
      strengthSliderPosition: data.strengthSliderPosition.present
          ? data.strengthSliderPosition.value
          : this.strengthSliderPosition,
      customCoffeeAmount: data.customCoffeeAmount.present
          ? data.customCoffeeAmount.value
          : this.customCoffeeAmount,
      customWaterAmount: data.customWaterAmount.present
          ? data.customWaterAmount.value
          : this.customWaterAmount,
      coffeeChroniclerSliderPosition:
          data.coffeeChroniclerSliderPosition.present
              ? data.coffeeChroniclerSliderPosition.value
              : this.coffeeChroniclerSliderPosition,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRecipePreference(')
          ..write('recipeId: $recipeId, ')
          ..write('lastUsed: $lastUsed, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('sweetnessSliderPosition: $sweetnessSliderPosition, ')
          ..write('strengthSliderPosition: $strengthSliderPosition, ')
          ..write('customCoffeeAmount: $customCoffeeAmount, ')
          ..write('customWaterAmount: $customWaterAmount, ')
          ..write(
              'coffeeChroniclerSliderPosition: $coffeeChroniclerSliderPosition')
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
      customWaterAmount,
      coffeeChroniclerSliderPosition);
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
          other.customWaterAmount == this.customWaterAmount &&
          other.coffeeChroniclerSliderPosition ==
              this.coffeeChroniclerSliderPosition);
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
  final Value<int> coffeeChroniclerSliderPosition;
  final Value<int> rowid;
  const UserRecipePreferencesCompanion({
    this.recipeId = const Value.absent(),
    this.lastUsed = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.sweetnessSliderPosition = const Value.absent(),
    this.strengthSliderPosition = const Value.absent(),
    this.customCoffeeAmount = const Value.absent(),
    this.customWaterAmount = const Value.absent(),
    this.coffeeChroniclerSliderPosition = const Value.absent(),
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
    this.coffeeChroniclerSliderPosition = const Value.absent(),
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
    Expression<int>? coffeeChroniclerSliderPosition,
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
      if (coffeeChroniclerSliderPosition != null)
        'coffee_chronicler_slider_position': coffeeChroniclerSliderPosition,
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
      Value<int>? coffeeChroniclerSliderPosition,
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
      coffeeChroniclerSliderPosition:
          coffeeChroniclerSliderPosition ?? this.coffeeChroniclerSliderPosition,
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
    if (coffeeChroniclerSliderPosition.present) {
      map['coffee_chronicler_slider_position'] =
          Variable<int>(coffeeChroniclerSliderPosition.value);
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
          ..write(
              'coffeeChroniclerSliderPosition: $coffeeChroniclerSliderPosition, ')
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
  CoffeeFact copyWithCompanion(CoffeeFactsCompanion data) {
    return CoffeeFact(
      id: data.id.present ? data.id.value : this.id,
      fact: data.fact.present ? data.fact.value : this.fact,
      locale: data.locale.present ? data.locale.value : this.locale,
    );
  }

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
  LaunchPopup copyWithCompanion(LaunchPopupsCompanion data) {
    return LaunchPopup(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      locale: data.locale.present ? data.locale.value : this.locale,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

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
  Contributor copyWithCompanion(ContributorsCompanion data) {
    return Contributor(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      locale: data.locale.present ? data.locale.value : this.locale,
    );
  }

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
  static const VerificationMeta _statUuidMeta =
      const VerificationMeta('statUuid');
  @override
  late final GeneratedColumn<String> statUuid = GeneratedColumn<String>(
      'stat_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _recipeIdMeta =
      const VerificationMeta('recipeId');
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
      'recipe_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recipes (id) ON DELETE CASCADE'));
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
  static const VerificationMeta _coffeeBeansUuidMeta =
      const VerificationMeta('coffeeBeansUuid');
  @override
  late final GeneratedColumn<String> coffeeBeansUuid = GeneratedColumn<String>(
      'coffee_beans_uuid', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _versionVectorMeta =
      const VerificationMeta('versionVector');
  @override
  late final GeneratedColumn<String> versionVector = GeneratedColumn<String>(
      'version_vector', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        statUuid,
        id,
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
        isMarked,
        coffeeBeansUuid,
        versionVector,
        isDeleted
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
    if (data.containsKey('stat_uuid')) {
      context.handle(_statUuidMeta,
          statUuid.isAcceptableOrUnknown(data['stat_uuid']!, _statUuidMeta));
    } else if (isInserting) {
      context.missing(_statUuidMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('coffee_beans_uuid')) {
      context.handle(
          _coffeeBeansUuidMeta,
          coffeeBeansUuid.isAcceptableOrUnknown(
              data['coffee_beans_uuid']!, _coffeeBeansUuidMeta));
    }
    if (data.containsKey('version_vector')) {
      context.handle(
          _versionVectorMeta,
          versionVector.isAcceptableOrUnknown(
              data['version_vector']!, _versionVectorMeta));
    } else if (isInserting) {
      context.missing(_versionVectorMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {statUuid};
  @override
  UserStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserStat(
      statUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stat_uuid'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id']),
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
      coffeeBeansUuid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}coffee_beans_uuid']),
      versionVector: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}version_vector'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $UserStatsTable createAlias(String alias) {
    return $UserStatsTable(attachedDatabase, alias);
  }
}

class UserStat extends DataClass implements Insertable<UserStat> {
  final String statUuid;
  final int? id;
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
  final String? coffeeBeansUuid;
  final String versionVector;
  final bool isDeleted;
  const UserStat(
      {required this.statUuid,
      this.id,
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
      required this.isMarked,
      this.coffeeBeansUuid,
      required this.versionVector,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['stat_uuid'] = Variable<String>(statUuid);
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
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
    if (!nullToAbsent || coffeeBeansUuid != null) {
      map['coffee_beans_uuid'] = Variable<String>(coffeeBeansUuid);
    }
    map['version_vector'] = Variable<String>(versionVector);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  UserStatsCompanion toCompanion(bool nullToAbsent) {
    return UserStatsCompanion(
      statUuid: Value(statUuid),
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
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
      coffeeBeansUuid: coffeeBeansUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(coffeeBeansUuid),
      versionVector: Value(versionVector),
      isDeleted: Value(isDeleted),
    );
  }

  factory UserStat.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserStat(
      statUuid: serializer.fromJson<String>(json['statUuid']),
      id: serializer.fromJson<int?>(json['id']),
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
      coffeeBeansUuid: serializer.fromJson<String?>(json['coffeeBeansUuid']),
      versionVector: serializer.fromJson<String>(json['versionVector']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'statUuid': serializer.toJson<String>(statUuid),
      'id': serializer.toJson<int?>(id),
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
      'coffeeBeansUuid': serializer.toJson<String?>(coffeeBeansUuid),
      'versionVector': serializer.toJson<String>(versionVector),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  UserStat copyWith(
          {String? statUuid,
          Value<int?> id = const Value.absent(),
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
          bool? isMarked,
          Value<String?> coffeeBeansUuid = const Value.absent(),
          String? versionVector,
          bool? isDeleted}) =>
      UserStat(
        statUuid: statUuid ?? this.statUuid,
        id: id.present ? id.value : this.id,
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
        coffeeBeansUuid: coffeeBeansUuid.present
            ? coffeeBeansUuid.value
            : this.coffeeBeansUuid,
        versionVector: versionVector ?? this.versionVector,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  UserStat copyWithCompanion(UserStatsCompanion data) {
    return UserStat(
      statUuid: data.statUuid.present ? data.statUuid.value : this.statUuid,
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      coffeeAmount: data.coffeeAmount.present
          ? data.coffeeAmount.value
          : this.coffeeAmount,
      waterAmount:
          data.waterAmount.present ? data.waterAmount.value : this.waterAmount,
      sweetnessSliderPosition: data.sweetnessSliderPosition.present
          ? data.sweetnessSliderPosition.value
          : this.sweetnessSliderPosition,
      strengthSliderPosition: data.strengthSliderPosition.present
          ? data.strengthSliderPosition.value
          : this.strengthSliderPosition,
      brewingMethodId: data.brewingMethodId.present
          ? data.brewingMethodId.value
          : this.brewingMethodId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      beans: data.beans.present ? data.beans.value : this.beans,
      roaster: data.roaster.present ? data.roaster.value : this.roaster,
      rating: data.rating.present ? data.rating.value : this.rating,
      coffeeBeansId: data.coffeeBeansId.present
          ? data.coffeeBeansId.value
          : this.coffeeBeansId,
      isMarked: data.isMarked.present ? data.isMarked.value : this.isMarked,
      coffeeBeansUuid: data.coffeeBeansUuid.present
          ? data.coffeeBeansUuid.value
          : this.coffeeBeansUuid,
      versionVector: data.versionVector.present
          ? data.versionVector.value
          : this.versionVector,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserStat(')
          ..write('statUuid: $statUuid, ')
          ..write('id: $id, ')
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
          ..write('isMarked: $isMarked, ')
          ..write('coffeeBeansUuid: $coffeeBeansUuid, ')
          ..write('versionVector: $versionVector, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      statUuid,
      id,
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
      isMarked,
      coffeeBeansUuid,
      versionVector,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserStat &&
          other.statUuid == this.statUuid &&
          other.id == this.id &&
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
          other.isMarked == this.isMarked &&
          other.coffeeBeansUuid == this.coffeeBeansUuid &&
          other.versionVector == this.versionVector &&
          other.isDeleted == this.isDeleted);
}

class UserStatsCompanion extends UpdateCompanion<UserStat> {
  final Value<String> statUuid;
  final Value<int?> id;
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
  final Value<String?> coffeeBeansUuid;
  final Value<String> versionVector;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const UserStatsCompanion({
    this.statUuid = const Value.absent(),
    this.id = const Value.absent(),
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
    this.coffeeBeansUuid = const Value.absent(),
    this.versionVector = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserStatsCompanion.insert({
    required String statUuid,
    this.id = const Value.absent(),
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
    this.coffeeBeansUuid = const Value.absent(),
    required String versionVector,
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : statUuid = Value(statUuid),
        recipeId = Value(recipeId),
        coffeeAmount = Value(coffeeAmount),
        waterAmount = Value(waterAmount),
        sweetnessSliderPosition = Value(sweetnessSliderPosition),
        strengthSliderPosition = Value(strengthSliderPosition),
        brewingMethodId = Value(brewingMethodId),
        versionVector = Value(versionVector);
  static Insertable<UserStat> custom({
    Expression<String>? statUuid,
    Expression<int>? id,
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
    Expression<String>? coffeeBeansUuid,
    Expression<String>? versionVector,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (statUuid != null) 'stat_uuid': statUuid,
      if (id != null) 'id': id,
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
      if (coffeeBeansUuid != null) 'coffee_beans_uuid': coffeeBeansUuid,
      if (versionVector != null) 'version_vector': versionVector,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserStatsCompanion copyWith(
      {Value<String>? statUuid,
      Value<int?>? id,
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
      Value<bool>? isMarked,
      Value<String?>? coffeeBeansUuid,
      Value<String>? versionVector,
      Value<bool>? isDeleted,
      Value<int>? rowid}) {
    return UserStatsCompanion(
      statUuid: statUuid ?? this.statUuid,
      id: id ?? this.id,
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
      coffeeBeansUuid: coffeeBeansUuid ?? this.coffeeBeansUuid,
      versionVector: versionVector ?? this.versionVector,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (statUuid.present) {
      map['stat_uuid'] = Variable<String>(statUuid.value);
    }
    if (id.present) {
      map['id'] = Variable<int>(id.value);
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
    if (coffeeBeansUuid.present) {
      map['coffee_beans_uuid'] = Variable<String>(coffeeBeansUuid.value);
    }
    if (versionVector.present) {
      map['version_vector'] = Variable<String>(versionVector.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserStatsCompanion(')
          ..write('statUuid: $statUuid, ')
          ..write('id: $id, ')
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
          ..write('isMarked: $isMarked, ')
          ..write('coffeeBeansUuid: $coffeeBeansUuid, ')
          ..write('versionVector: $versionVector, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
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
  static const VerificationMeta _beansUuidMeta =
      const VerificationMeta('beansUuid');
  @override
  late final GeneratedColumn<String> beansUuid = GeneratedColumn<String>(
      'beans_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
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
  static const VerificationMeta _versionVectorMeta =
      const VerificationMeta('versionVector');
  @override
  late final GeneratedColumn<String> versionVector = GeneratedColumn<String>(
      'version_vector', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        beansUuid,
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
        isFavorite,
        versionVector,
        isDeleted
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
    if (data.containsKey('beans_uuid')) {
      context.handle(_beansUuidMeta,
          beansUuid.isAcceptableOrUnknown(data['beans_uuid']!, _beansUuidMeta));
    } else if (isInserting) {
      context.missing(_beansUuidMeta);
    }
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
    if (data.containsKey('version_vector')) {
      context.handle(
          _versionVectorMeta,
          versionVector.isAcceptableOrUnknown(
              data['version_vector']!, _versionVectorMeta));
    } else if (isInserting) {
      context.missing(_versionVectorMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {beansUuid};
  @override
  CoffeeBean map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoffeeBean(
      beansUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}beans_uuid'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id']),
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
      versionVector: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}version_vector'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $CoffeeBeansTable createAlias(String alias) {
    return $CoffeeBeansTable(attachedDatabase, alias);
  }
}

class CoffeeBean extends DataClass implements Insertable<CoffeeBean> {
  final String beansUuid;
  final int? id;
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
  final String versionVector;
  final bool isDeleted;
  const CoffeeBean(
      {required this.beansUuid,
      this.id,
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
      required this.isFavorite,
      required this.versionVector,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['beans_uuid'] = Variable<String>(beansUuid);
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<int>(id);
    }
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
    map['version_vector'] = Variable<String>(versionVector);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  CoffeeBeansCompanion toCompanion(bool nullToAbsent) {
    return CoffeeBeansCompanion(
      beansUuid: Value(beansUuid),
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
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
      versionVector: Value(versionVector),
      isDeleted: Value(isDeleted),
    );
  }

  factory CoffeeBean.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoffeeBean(
      beansUuid: serializer.fromJson<String>(json['beansUuid']),
      id: serializer.fromJson<int?>(json['id']),
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
      versionVector: serializer.fromJson<String>(json['versionVector']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'beansUuid': serializer.toJson<String>(beansUuid),
      'id': serializer.toJson<int?>(id),
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
      'versionVector': serializer.toJson<String>(versionVector),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  CoffeeBean copyWith(
          {String? beansUuid,
          Value<int?> id = const Value.absent(),
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
          bool? isFavorite,
          String? versionVector,
          bool? isDeleted}) =>
      CoffeeBean(
        beansUuid: beansUuid ?? this.beansUuid,
        id: id.present ? id.value : this.id,
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
        versionVector: versionVector ?? this.versionVector,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  CoffeeBean copyWithCompanion(CoffeeBeansCompanion data) {
    return CoffeeBean(
      beansUuid: data.beansUuid.present ? data.beansUuid.value : this.beansUuid,
      id: data.id.present ? data.id.value : this.id,
      roaster: data.roaster.present ? data.roaster.value : this.roaster,
      name: data.name.present ? data.name.value : this.name,
      origin: data.origin.present ? data.origin.value : this.origin,
      variety: data.variety.present ? data.variety.value : this.variety,
      tastingNotes: data.tastingNotes.present
          ? data.tastingNotes.value
          : this.tastingNotes,
      processingMethod: data.processingMethod.present
          ? data.processingMethod.value
          : this.processingMethod,
      elevation: data.elevation.present ? data.elevation.value : this.elevation,
      harvestDate:
          data.harvestDate.present ? data.harvestDate.value : this.harvestDate,
      roastDate: data.roastDate.present ? data.roastDate.value : this.roastDate,
      region: data.region.present ? data.region.value : this.region,
      roastLevel:
          data.roastLevel.present ? data.roastLevel.value : this.roastLevel,
      cuppingScore: data.cuppingScore.present
          ? data.cuppingScore.value
          : this.cuppingScore,
      notes: data.notes.present ? data.notes.value : this.notes,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      versionVector: data.versionVector.present
          ? data.versionVector.value
          : this.versionVector,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoffeeBean(')
          ..write('beansUuid: $beansUuid, ')
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
          ..write('isFavorite: $isFavorite, ')
          ..write('versionVector: $versionVector, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      beansUuid,
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
      isFavorite,
      versionVector,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoffeeBean &&
          other.beansUuid == this.beansUuid &&
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
          other.isFavorite == this.isFavorite &&
          other.versionVector == this.versionVector &&
          other.isDeleted == this.isDeleted);
}

class CoffeeBeansCompanion extends UpdateCompanion<CoffeeBean> {
  final Value<String> beansUuid;
  final Value<int?> id;
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
  final Value<String> versionVector;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const CoffeeBeansCompanion({
    this.beansUuid = const Value.absent(),
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
    this.versionVector = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoffeeBeansCompanion.insert({
    required String beansUuid,
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
    required String versionVector,
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : beansUuid = Value(beansUuid),
        roaster = Value(roaster),
        name = Value(name),
        origin = Value(origin),
        versionVector = Value(versionVector);
  static Insertable<CoffeeBean> custom({
    Expression<String>? beansUuid,
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
    Expression<String>? versionVector,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (beansUuid != null) 'beans_uuid': beansUuid,
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
      if (versionVector != null) 'version_vector': versionVector,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoffeeBeansCompanion copyWith(
      {Value<String>? beansUuid,
      Value<int?>? id,
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
      Value<bool>? isFavorite,
      Value<String>? versionVector,
      Value<bool>? isDeleted,
      Value<int>? rowid}) {
    return CoffeeBeansCompanion(
      beansUuid: beansUuid ?? this.beansUuid,
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
      versionVector: versionVector ?? this.versionVector,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (beansUuid.present) {
      map['beans_uuid'] = Variable<String>(beansUuid.value);
    }
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
    if (versionVector.present) {
      map['version_vector'] = Variable<String>(versionVector.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoffeeBeansCompanion(')
          ..write('beansUuid: $beansUuid, ')
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
          ..write('isFavorite: $isFavorite, ')
          ..write('versionVector: $versionVector, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
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
  late final Index idxUserStatsStatUuidVersionVector = Index(
      'idx_user_stats_stat_uuid_version_vector',
      'CREATE INDEX idx_user_stats_stat_uuid_version_vector ON user_stats (stat_uuid, version_vector)');
  late final Index idxCoffeeBeansBeansUuidVersionVector = Index(
      'idx_coffee_beans_beans_uuid_version_vector',
      'CREATE INDEX idx_coffee_beans_beans_uuid_version_vector ON coffee_beans (beans_uuid, version_vector)');
  late final RecipesDao recipesDao = RecipesDao(this as AppDatabase);
  late final StepsDao stepsDao = StepsDao(this as AppDatabase);
  late final RecipeLocalizationsDao recipeLocalizationsDao =
      RecipeLocalizationsDao(this as AppDatabase);
  late final UserRecipePreferencesDao userRecipePreferencesDao =
      UserRecipePreferencesDao(this as AppDatabase);
  late final BrewingMethodsDao brewingMethodsDao =
      BrewingMethodsDao(this as AppDatabase);
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
        idxLaunchPopupsCreatedAt,
        idxUserStatsStatUuidVersionVector,
        idxCoffeeBeansBeansUuidVersionVector
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
          WritePropagation(
            on: TableUpdateQuery.onTableName('recipes',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('user_stats', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$SupportedLocalesTableCreateCompanionBuilder
    = SupportedLocalesCompanion Function({
  required String locale,
  required String localeName,
  Value<int> rowid,
});
typedef $$SupportedLocalesTableUpdateCompanionBuilder
    = SupportedLocalesCompanion Function({
  Value<String> locale,
  Value<String> localeName,
  Value<int> rowid,
});

final class $$SupportedLocalesTableReferences extends BaseReferences<
    _$AppDatabase, $SupportedLocalesTable, SupportedLocale> {
  $$SupportedLocalesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RecipeLocalizationsTable,
      List<RecipeLocalization>> _recipeLocalizationsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.recipeLocalizations,
          aliasName: $_aliasNameGenerator(
              db.supportedLocales.locale, db.recipeLocalizations.locale));

  $$RecipeLocalizationsTableProcessedTableManager get recipeLocalizationsRefs {
    final manager = $$RecipeLocalizationsTableTableManager(
            $_db, $_db.recipeLocalizations)
        .filter(
            (f) => f.locale.locale.sqlEquals($_itemColumn<String>('locale')!));

    final cache =
        $_typedResult.readTableOrNull(_recipeLocalizationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StepsTable, List<Step>> _stepsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.steps,
          aliasName: $_aliasNameGenerator(
              db.supportedLocales.locale, db.steps.locale));

  $$StepsTableProcessedTableManager get stepsRefs {
    final manager = $$StepsTableTableManager($_db, $_db.steps).filter(
        (f) => f.locale.locale.sqlEquals($_itemColumn<String>('locale')!));

    final cache = $_typedResult.readTableOrNull(_stepsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CoffeeFactsTable, List<CoffeeFact>>
      _coffeeFactsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.coffeeFacts,
              aliasName: $_aliasNameGenerator(
                  db.supportedLocales.locale, db.coffeeFacts.locale));

  $$CoffeeFactsTableProcessedTableManager get coffeeFactsRefs {
    final manager = $$CoffeeFactsTableTableManager($_db, $_db.coffeeFacts)
        .filter(
            (f) => f.locale.locale.sqlEquals($_itemColumn<String>('locale')!));

    final cache = $_typedResult.readTableOrNull(_coffeeFactsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LaunchPopupsTable, List<LaunchPopup>>
      _launchPopupsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.launchPopups,
              aliasName: $_aliasNameGenerator(
                  db.supportedLocales.locale, db.launchPopups.locale));

  $$LaunchPopupsTableProcessedTableManager get launchPopupsRefs {
    final manager = $$LaunchPopupsTableTableManager($_db, $_db.launchPopups)
        .filter(
            (f) => f.locale.locale.sqlEquals($_itemColumn<String>('locale')!));

    final cache = $_typedResult.readTableOrNull(_launchPopupsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ContributorsTable, List<Contributor>>
      _contributorsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.contributors,
              aliasName: $_aliasNameGenerator(
                  db.supportedLocales.locale, db.contributors.locale));

  $$ContributorsTableProcessedTableManager get contributorsRefs {
    final manager = $$ContributorsTableTableManager($_db, $_db.contributors)
        .filter(
            (f) => f.locale.locale.sqlEquals($_itemColumn<String>('locale')!));

    final cache = $_typedResult.readTableOrNull(_contributorsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SupportedLocalesTableFilterComposer
    extends Composer<_$AppDatabase, $SupportedLocalesTable> {
  $$SupportedLocalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get locale => $composableBuilder(
      column: $table.locale, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localeName => $composableBuilder(
      column: $table.localeName, builder: (column) => ColumnFilters(column));

  Expression<bool> recipeLocalizationsRefs(
      Expression<bool> Function($$RecipeLocalizationsTableFilterComposer f) f) {
    final $$RecipeLocalizationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.recipeLocalizations,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeLocalizationsTableFilterComposer(
              $db: $db,
              $table: $db.recipeLocalizations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> stepsRefs(
      Expression<bool> Function($$StepsTableFilterComposer f) f) {
    final $$StepsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.steps,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StepsTableFilterComposer(
              $db: $db,
              $table: $db.steps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> coffeeFactsRefs(
      Expression<bool> Function($$CoffeeFactsTableFilterComposer f) f) {
    final $$CoffeeFactsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.coffeeFacts,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CoffeeFactsTableFilterComposer(
              $db: $db,
              $table: $db.coffeeFacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> launchPopupsRefs(
      Expression<bool> Function($$LaunchPopupsTableFilterComposer f) f) {
    final $$LaunchPopupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.launchPopups,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LaunchPopupsTableFilterComposer(
              $db: $db,
              $table: $db.launchPopups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> contributorsRefs(
      Expression<bool> Function($$ContributorsTableFilterComposer f) f) {
    final $$ContributorsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.contributors,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContributorsTableFilterComposer(
              $db: $db,
              $table: $db.contributors,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SupportedLocalesTableOrderingComposer
    extends Composer<_$AppDatabase, $SupportedLocalesTable> {
  $$SupportedLocalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get locale => $composableBuilder(
      column: $table.locale, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localeName => $composableBuilder(
      column: $table.localeName, builder: (column) => ColumnOrderings(column));
}

class $$SupportedLocalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SupportedLocalesTable> {
  $$SupportedLocalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<String> get localeName => $composableBuilder(
      column: $table.localeName, builder: (column) => column);

  Expression<T> recipeLocalizationsRefs<T extends Object>(
      Expression<T> Function($$RecipeLocalizationsTableAnnotationComposer a)
          f) {
    final $$RecipeLocalizationsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.locale,
            referencedTable: $db.recipeLocalizations,
            getReferencedColumn: (t) => t.locale,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecipeLocalizationsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.recipeLocalizations,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> stepsRefs<T extends Object>(
      Expression<T> Function($$StepsTableAnnotationComposer a) f) {
    final $$StepsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.steps,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StepsTableAnnotationComposer(
              $db: $db,
              $table: $db.steps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> coffeeFactsRefs<T extends Object>(
      Expression<T> Function($$CoffeeFactsTableAnnotationComposer a) f) {
    final $$CoffeeFactsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.coffeeFacts,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CoffeeFactsTableAnnotationComposer(
              $db: $db,
              $table: $db.coffeeFacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> launchPopupsRefs<T extends Object>(
      Expression<T> Function($$LaunchPopupsTableAnnotationComposer a) f) {
    final $$LaunchPopupsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.launchPopups,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LaunchPopupsTableAnnotationComposer(
              $db: $db,
              $table: $db.launchPopups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> contributorsRefs<T extends Object>(
      Expression<T> Function($$ContributorsTableAnnotationComposer a) f) {
    final $$ContributorsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.contributors,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContributorsTableAnnotationComposer(
              $db: $db,
              $table: $db.contributors,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SupportedLocalesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SupportedLocalesTable,
    SupportedLocale,
    $$SupportedLocalesTableFilterComposer,
    $$SupportedLocalesTableOrderingComposer,
    $$SupportedLocalesTableAnnotationComposer,
    $$SupportedLocalesTableCreateCompanionBuilder,
    $$SupportedLocalesTableUpdateCompanionBuilder,
    (SupportedLocale, $$SupportedLocalesTableReferences),
    SupportedLocale,
    PrefetchHooks Function(
        {bool recipeLocalizationsRefs,
        bool stepsRefs,
        bool coffeeFactsRefs,
        bool launchPopupsRefs,
        bool contributorsRefs})> {
  $$SupportedLocalesTableTableManager(
      _$AppDatabase db, $SupportedLocalesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SupportedLocalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SupportedLocalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SupportedLocalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> locale = const Value.absent(),
            Value<String> localeName = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SupportedLocalesCompanion(
            locale: locale,
            localeName: localeName,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String locale,
            required String localeName,
            Value<int> rowid = const Value.absent(),
          }) =>
              SupportedLocalesCompanion.insert(
            locale: locale,
            localeName: localeName,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SupportedLocalesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {recipeLocalizationsRefs = false,
              stepsRefs = false,
              coffeeFactsRefs = false,
              launchPopupsRefs = false,
              contributorsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (recipeLocalizationsRefs) db.recipeLocalizations,
                if (stepsRefs) db.steps,
                if (coffeeFactsRefs) db.coffeeFacts,
                if (launchPopupsRefs) db.launchPopups,
                if (contributorsRefs) db.contributors
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recipeLocalizationsRefs)
                    await $_getPrefetchedData<SupportedLocale,
                            $SupportedLocalesTable, RecipeLocalization>(
                        currentTable: table,
                        referencedTable: $$SupportedLocalesTableReferences
                            ._recipeLocalizationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SupportedLocalesTableReferences(db, table, p0)
                                .recipeLocalizationsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.locale == item.locale),
                        typedResults: items),
                  if (stepsRefs)
                    await $_getPrefetchedData<SupportedLocale,
                            $SupportedLocalesTable, Step>(
                        currentTable: table,
                        referencedTable: $$SupportedLocalesTableReferences
                            ._stepsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SupportedLocalesTableReferences(db, table, p0)
                                .stepsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.locale == item.locale),
                        typedResults: items),
                  if (coffeeFactsRefs)
                    await $_getPrefetchedData<SupportedLocale,
                            $SupportedLocalesTable, CoffeeFact>(
                        currentTable: table,
                        referencedTable: $$SupportedLocalesTableReferences
                            ._coffeeFactsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SupportedLocalesTableReferences(db, table, p0)
                                .coffeeFactsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.locale == item.locale),
                        typedResults: items),
                  if (launchPopupsRefs)
                    await $_getPrefetchedData<SupportedLocale,
                            $SupportedLocalesTable, LaunchPopup>(
                        currentTable: table,
                        referencedTable: $$SupportedLocalesTableReferences
                            ._launchPopupsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SupportedLocalesTableReferences(db, table, p0)
                                .launchPopupsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.locale == item.locale),
                        typedResults: items),
                  if (contributorsRefs)
                    await $_getPrefetchedData<SupportedLocale,
                            $SupportedLocalesTable, Contributor>(
                        currentTable: table,
                        referencedTable: $$SupportedLocalesTableReferences
                            ._contributorsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SupportedLocalesTableReferences(db, table, p0)
                                .contributorsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.locale == item.locale),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SupportedLocalesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SupportedLocalesTable,
    SupportedLocale,
    $$SupportedLocalesTableFilterComposer,
    $$SupportedLocalesTableOrderingComposer,
    $$SupportedLocalesTableAnnotationComposer,
    $$SupportedLocalesTableCreateCompanionBuilder,
    $$SupportedLocalesTableUpdateCompanionBuilder,
    (SupportedLocale, $$SupportedLocalesTableReferences),
    SupportedLocale,
    PrefetchHooks Function(
        {bool recipeLocalizationsRefs,
        bool stepsRefs,
        bool coffeeFactsRefs,
        bool launchPopupsRefs,
        bool contributorsRefs})>;
typedef $$BrewingMethodsTableCreateCompanionBuilder = BrewingMethodsCompanion
    Function({
  required String brewingMethodId,
  required String brewingMethod,
  Value<int> rowid,
});
typedef $$BrewingMethodsTableUpdateCompanionBuilder = BrewingMethodsCompanion
    Function({
  Value<String> brewingMethodId,
  Value<String> brewingMethod,
  Value<int> rowid,
});

final class $$BrewingMethodsTableReferences
    extends BaseReferences<_$AppDatabase, $BrewingMethodsTable, BrewingMethod> {
  $$BrewingMethodsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RecipesTable, List<Recipe>> _recipesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.recipes,
          aliasName: $_aliasNameGenerator(
              db.brewingMethods.brewingMethodId, db.recipes.brewingMethodId));

  $$RecipesTableProcessedTableManager get recipesRefs {
    final manager = $$RecipesTableTableManager($_db, $_db.recipes).filter((f) =>
        f.brewingMethodId.brewingMethodId
            .sqlEquals($_itemColumn<String>('brewing_method_id')!));

    final cache = $_typedResult.readTableOrNull(_recipesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$UserStatsTable, List<UserStat>>
      _userStatsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.userStats,
          aliasName: $_aliasNameGenerator(
              db.brewingMethods.brewingMethodId, db.userStats.brewingMethodId));

  $$UserStatsTableProcessedTableManager get userStatsRefs {
    final manager = $$UserStatsTableTableManager($_db, $_db.userStats).filter(
        (f) => f.brewingMethodId.brewingMethodId
            .sqlEquals($_itemColumn<String>('brewing_method_id')!));

    final cache = $_typedResult.readTableOrNull(_userStatsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BrewingMethodsTableFilterComposer
    extends Composer<_$AppDatabase, $BrewingMethodsTable> {
  $$BrewingMethodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get brewingMethodId => $composableBuilder(
      column: $table.brewingMethodId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get brewingMethod => $composableBuilder(
      column: $table.brewingMethod, builder: (column) => ColumnFilters(column));

  Expression<bool> recipesRefs(
      Expression<bool> Function($$RecipesTableFilterComposer f) f) {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.brewingMethodId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.brewingMethodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableFilterComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> userStatsRefs(
      Expression<bool> Function($$UserStatsTableFilterComposer f) f) {
    final $$UserStatsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.brewingMethodId,
        referencedTable: $db.userStats,
        getReferencedColumn: (t) => t.brewingMethodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserStatsTableFilterComposer(
              $db: $db,
              $table: $db.userStats,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BrewingMethodsTableOrderingComposer
    extends Composer<_$AppDatabase, $BrewingMethodsTable> {
  $$BrewingMethodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get brewingMethodId => $composableBuilder(
      column: $table.brewingMethodId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get brewingMethod => $composableBuilder(
      column: $table.brewingMethod,
      builder: (column) => ColumnOrderings(column));
}

class $$BrewingMethodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BrewingMethodsTable> {
  $$BrewingMethodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get brewingMethodId => $composableBuilder(
      column: $table.brewingMethodId, builder: (column) => column);

  GeneratedColumn<String> get brewingMethod => $composableBuilder(
      column: $table.brewingMethod, builder: (column) => column);

  Expression<T> recipesRefs<T extends Object>(
      Expression<T> Function($$RecipesTableAnnotationComposer a) f) {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.brewingMethodId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.brewingMethodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableAnnotationComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> userStatsRefs<T extends Object>(
      Expression<T> Function($$UserStatsTableAnnotationComposer a) f) {
    final $$UserStatsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.brewingMethodId,
        referencedTable: $db.userStats,
        getReferencedColumn: (t) => t.brewingMethodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserStatsTableAnnotationComposer(
              $db: $db,
              $table: $db.userStats,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BrewingMethodsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BrewingMethodsTable,
    BrewingMethod,
    $$BrewingMethodsTableFilterComposer,
    $$BrewingMethodsTableOrderingComposer,
    $$BrewingMethodsTableAnnotationComposer,
    $$BrewingMethodsTableCreateCompanionBuilder,
    $$BrewingMethodsTableUpdateCompanionBuilder,
    (BrewingMethod, $$BrewingMethodsTableReferences),
    BrewingMethod,
    PrefetchHooks Function({bool recipesRefs, bool userStatsRefs})> {
  $$BrewingMethodsTableTableManager(
      _$AppDatabase db, $BrewingMethodsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrewingMethodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BrewingMethodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BrewingMethodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> brewingMethodId = const Value.absent(),
            Value<String> brewingMethod = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BrewingMethodsCompanion(
            brewingMethodId: brewingMethodId,
            brewingMethod: brewingMethod,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String brewingMethodId,
            required String brewingMethod,
            Value<int> rowid = const Value.absent(),
          }) =>
              BrewingMethodsCompanion.insert(
            brewingMethodId: brewingMethodId,
            brewingMethod: brewingMethod,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BrewingMethodsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {recipesRefs = false, userStatsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (recipesRefs) db.recipes,
                if (userStatsRefs) db.userStats
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recipesRefs)
                    await $_getPrefetchedData<BrewingMethod,
                            $BrewingMethodsTable, Recipe>(
                        currentTable: table,
                        referencedTable: $$BrewingMethodsTableReferences
                            ._recipesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BrewingMethodsTableReferences(db, table, p0)
                                .recipesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) =>
                                    e.brewingMethodId == item.brewingMethodId),
                        typedResults: items),
                  if (userStatsRefs)
                    await $_getPrefetchedData<BrewingMethod,
                            $BrewingMethodsTable, UserStat>(
                        currentTable: table,
                        referencedTable: $$BrewingMethodsTableReferences
                            ._userStatsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BrewingMethodsTableReferences(db, table, p0)
                                .userStatsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) =>
                                    e.brewingMethodId == item.brewingMethodId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$BrewingMethodsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BrewingMethodsTable,
    BrewingMethod,
    $$BrewingMethodsTableFilterComposer,
    $$BrewingMethodsTableOrderingComposer,
    $$BrewingMethodsTableAnnotationComposer,
    $$BrewingMethodsTableCreateCompanionBuilder,
    $$BrewingMethodsTableUpdateCompanionBuilder,
    (BrewingMethod, $$BrewingMethodsTableReferences),
    BrewingMethod,
    PrefetchHooks Function({bool recipesRefs, bool userStatsRefs})>;
typedef $$RecipesTableCreateCompanionBuilder = RecipesCompanion Function({
  required String id,
  required String brewingMethodId,
  required double coffeeAmount,
  required double waterAmount,
  required double waterTemp,
  required int brewTime,
  Value<String?> vendorId,
  Value<DateTime?> lastModified,
  Value<String?> importId,
  Value<bool> isImported,
  Value<bool> needsModerationReview,
  Value<int> rowid,
});
typedef $$RecipesTableUpdateCompanionBuilder = RecipesCompanion Function({
  Value<String> id,
  Value<String> brewingMethodId,
  Value<double> coffeeAmount,
  Value<double> waterAmount,
  Value<double> waterTemp,
  Value<int> brewTime,
  Value<String?> vendorId,
  Value<DateTime?> lastModified,
  Value<String?> importId,
  Value<bool> isImported,
  Value<bool> needsModerationReview,
  Value<int> rowid,
});

final class $$RecipesTableReferences
    extends BaseReferences<_$AppDatabase, $RecipesTable, Recipe> {
  $$RecipesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BrewingMethodsTable _brewingMethodIdTable(_$AppDatabase db) =>
      db.brewingMethods.createAlias($_aliasNameGenerator(
          db.recipes.brewingMethodId, db.brewingMethods.brewingMethodId));

  $$BrewingMethodsTableProcessedTableManager get brewingMethodId {
    final $_column = $_itemColumn<String>('brewing_method_id')!;

    final manager = $$BrewingMethodsTableTableManager($_db, $_db.brewingMethods)
        .filter((f) => f.brewingMethodId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_brewingMethodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$RecipeLocalizationsTable,
      List<RecipeLocalization>> _recipeLocalizationsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.recipeLocalizations,
          aliasName: $_aliasNameGenerator(
              db.recipes.id, db.recipeLocalizations.recipeId));

  $$RecipeLocalizationsTableProcessedTableManager get recipeLocalizationsRefs {
    final manager = $$RecipeLocalizationsTableTableManager(
            $_db, $_db.recipeLocalizations)
        .filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_recipeLocalizationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$StepsTable, List<Step>> _stepsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.steps,
          aliasName: $_aliasNameGenerator(db.recipes.id, db.steps.recipeId));

  $$StepsTableProcessedTableManager get stepsRefs {
    final manager = $$StepsTableTableManager($_db, $_db.steps)
        .filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stepsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$UserRecipePreferencesTable,
      List<UserRecipePreference>> _userRecipePreferencesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.userRecipePreferences,
          aliasName: $_aliasNameGenerator(
              db.recipes.id, db.userRecipePreferences.recipeId));

  $$UserRecipePreferencesTableProcessedTableManager
      get userRecipePreferencesRefs {
    final manager = $$UserRecipePreferencesTableTableManager(
            $_db, $_db.userRecipePreferences)
        .filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_userRecipePreferencesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$UserStatsTable, List<UserStat>>
      _userStatsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.userStats,
              aliasName:
                  $_aliasNameGenerator(db.recipes.id, db.userStats.recipeId));

  $$UserStatsTableProcessedTableManager get userStatsRefs {
    final manager = $$UserStatsTableTableManager($_db, $_db.userStats)
        .filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_userStatsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get coffeeAmount => $composableBuilder(
      column: $table.coffeeAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get waterAmount => $composableBuilder(
      column: $table.waterAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get waterTemp => $composableBuilder(
      column: $table.waterTemp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get brewTime => $composableBuilder(
      column: $table.brewTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vendorId => $composableBuilder(
      column: $table.vendorId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get importId => $composableBuilder(
      column: $table.importId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isImported => $composableBuilder(
      column: $table.isImported, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsModerationReview => $composableBuilder(
      column: $table.needsModerationReview,
      builder: (column) => ColumnFilters(column));

  $$BrewingMethodsTableFilterComposer get brewingMethodId {
    final $$BrewingMethodsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.brewingMethodId,
        referencedTable: $db.brewingMethods,
        getReferencedColumn: (t) => t.brewingMethodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BrewingMethodsTableFilterComposer(
              $db: $db,
              $table: $db.brewingMethods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> recipeLocalizationsRefs(
      Expression<bool> Function($$RecipeLocalizationsTableFilterComposer f) f) {
    final $$RecipeLocalizationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recipeLocalizations,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipeLocalizationsTableFilterComposer(
              $db: $db,
              $table: $db.recipeLocalizations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> stepsRefs(
      Expression<bool> Function($$StepsTableFilterComposer f) f) {
    final $$StepsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.steps,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StepsTableFilterComposer(
              $db: $db,
              $table: $db.steps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> userRecipePreferencesRefs(
      Expression<bool> Function($$UserRecipePreferencesTableFilterComposer f)
          f) {
    final $$UserRecipePreferencesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.userRecipePreferences,
            getReferencedColumn: (t) => t.recipeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$UserRecipePreferencesTableFilterComposer(
                  $db: $db,
                  $table: $db.userRecipePreferences,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> userStatsRefs(
      Expression<bool> Function($$UserStatsTableFilterComposer f) f) {
    final $$UserStatsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userStats,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserStatsTableFilterComposer(
              $db: $db,
              $table: $db.userStats,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get coffeeAmount => $composableBuilder(
      column: $table.coffeeAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get waterAmount => $composableBuilder(
      column: $table.waterAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get waterTemp => $composableBuilder(
      column: $table.waterTemp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get brewTime => $composableBuilder(
      column: $table.brewTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vendorId => $composableBuilder(
      column: $table.vendorId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get importId => $composableBuilder(
      column: $table.importId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isImported => $composableBuilder(
      column: $table.isImported, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsModerationReview => $composableBuilder(
      column: $table.needsModerationReview,
      builder: (column) => ColumnOrderings(column));

  $$BrewingMethodsTableOrderingComposer get brewingMethodId {
    final $$BrewingMethodsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.brewingMethodId,
        referencedTable: $db.brewingMethods,
        getReferencedColumn: (t) => t.brewingMethodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BrewingMethodsTableOrderingComposer(
              $db: $db,
              $table: $db.brewingMethods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get coffeeAmount => $composableBuilder(
      column: $table.coffeeAmount, builder: (column) => column);

  GeneratedColumn<double> get waterAmount => $composableBuilder(
      column: $table.waterAmount, builder: (column) => column);

  GeneratedColumn<double> get waterTemp =>
      $composableBuilder(column: $table.waterTemp, builder: (column) => column);

  GeneratedColumn<int> get brewTime =>
      $composableBuilder(column: $table.brewTime, builder: (column) => column);

  GeneratedColumn<String> get vendorId =>
      $composableBuilder(column: $table.vendorId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);

  GeneratedColumn<String> get importId =>
      $composableBuilder(column: $table.importId, builder: (column) => column);

  GeneratedColumn<bool> get isImported => $composableBuilder(
      column: $table.isImported, builder: (column) => column);

  GeneratedColumn<bool> get needsModerationReview => $composableBuilder(
      column: $table.needsModerationReview, builder: (column) => column);

  $$BrewingMethodsTableAnnotationComposer get brewingMethodId {
    final $$BrewingMethodsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.brewingMethodId,
        referencedTable: $db.brewingMethods,
        getReferencedColumn: (t) => t.brewingMethodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BrewingMethodsTableAnnotationComposer(
              $db: $db,
              $table: $db.brewingMethods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> recipeLocalizationsRefs<T extends Object>(
      Expression<T> Function($$RecipeLocalizationsTableAnnotationComposer a)
          f) {
    final $$RecipeLocalizationsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.recipeLocalizations,
            getReferencedColumn: (t) => t.recipeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$RecipeLocalizationsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.recipeLocalizations,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> stepsRefs<T extends Object>(
      Expression<T> Function($$StepsTableAnnotationComposer a) f) {
    final $$StepsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.steps,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StepsTableAnnotationComposer(
              $db: $db,
              $table: $db.steps,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> userRecipePreferencesRefs<T extends Object>(
      Expression<T> Function($$UserRecipePreferencesTableAnnotationComposer a)
          f) {
    final $$UserRecipePreferencesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.userRecipePreferences,
            getReferencedColumn: (t) => t.recipeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$UserRecipePreferencesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.userRecipePreferences,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> userStatsRefs<T extends Object>(
      Expression<T> Function($$UserStatsTableAnnotationComposer a) f) {
    final $$UserStatsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userStats,
        getReferencedColumn: (t) => t.recipeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserStatsTableAnnotationComposer(
              $db: $db,
              $table: $db.userStats,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RecipesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecipesTable,
    Recipe,
    $$RecipesTableFilterComposer,
    $$RecipesTableOrderingComposer,
    $$RecipesTableAnnotationComposer,
    $$RecipesTableCreateCompanionBuilder,
    $$RecipesTableUpdateCompanionBuilder,
    (Recipe, $$RecipesTableReferences),
    Recipe,
    PrefetchHooks Function(
        {bool brewingMethodId,
        bool recipeLocalizationsRefs,
        bool stepsRefs,
        bool userRecipePreferencesRefs,
        bool userStatsRefs})> {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> brewingMethodId = const Value.absent(),
            Value<double> coffeeAmount = const Value.absent(),
            Value<double> waterAmount = const Value.absent(),
            Value<double> waterTemp = const Value.absent(),
            Value<int> brewTime = const Value.absent(),
            Value<String?> vendorId = const Value.absent(),
            Value<DateTime?> lastModified = const Value.absent(),
            Value<String?> importId = const Value.absent(),
            Value<bool> isImported = const Value.absent(),
            Value<bool> needsModerationReview = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipesCompanion(
            id: id,
            brewingMethodId: brewingMethodId,
            coffeeAmount: coffeeAmount,
            waterAmount: waterAmount,
            waterTemp: waterTemp,
            brewTime: brewTime,
            vendorId: vendorId,
            lastModified: lastModified,
            importId: importId,
            isImported: isImported,
            needsModerationReview: needsModerationReview,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String brewingMethodId,
            required double coffeeAmount,
            required double waterAmount,
            required double waterTemp,
            required int brewTime,
            Value<String?> vendorId = const Value.absent(),
            Value<DateTime?> lastModified = const Value.absent(),
            Value<String?> importId = const Value.absent(),
            Value<bool> isImported = const Value.absent(),
            Value<bool> needsModerationReview = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipesCompanion.insert(
            id: id,
            brewingMethodId: brewingMethodId,
            coffeeAmount: coffeeAmount,
            waterAmount: waterAmount,
            waterTemp: waterTemp,
            brewTime: brewTime,
            vendorId: vendorId,
            lastModified: lastModified,
            importId: importId,
            isImported: isImported,
            needsModerationReview: needsModerationReview,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$RecipesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {brewingMethodId = false,
              recipeLocalizationsRefs = false,
              stepsRefs = false,
              userRecipePreferencesRefs = false,
              userStatsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (recipeLocalizationsRefs) db.recipeLocalizations,
                if (stepsRefs) db.steps,
                if (userRecipePreferencesRefs) db.userRecipePreferences,
                if (userStatsRefs) db.userStats
              ],
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
                if (brewingMethodId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.brewingMethodId,
                    referencedTable:
                        $$RecipesTableReferences._brewingMethodIdTable(db),
                    referencedColumn: $$RecipesTableReferences
                        ._brewingMethodIdTable(db)
                        .brewingMethodId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recipeLocalizationsRefs)
                    await $_getPrefetchedData<Recipe, $RecipesTable,
                            RecipeLocalization>(
                        currentTable: table,
                        referencedTable: $$RecipesTableReferences
                            ._recipeLocalizationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecipesTableReferences(db, table, p0)
                                .recipeLocalizationsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.recipeId == item.id),
                        typedResults: items),
                  if (stepsRefs)
                    await $_getPrefetchedData<Recipe, $RecipesTable, Step>(
                        currentTable: table,
                        referencedTable:
                            $$RecipesTableReferences._stepsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecipesTableReferences(db, table, p0).stepsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.recipeId == item.id),
                        typedResults: items),
                  if (userRecipePreferencesRefs)
                    await $_getPrefetchedData<Recipe, $RecipesTable,
                            UserRecipePreference>(
                        currentTable: table,
                        referencedTable: $$RecipesTableReferences
                            ._userRecipePreferencesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecipesTableReferences(db, table, p0)
                                .userRecipePreferencesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.recipeId == item.id),
                        typedResults: items),
                  if (userStatsRefs)
                    await $_getPrefetchedData<Recipe, $RecipesTable, UserStat>(
                        currentTable: table,
                        referencedTable:
                            $$RecipesTableReferences._userStatsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecipesTableReferences(db, table, p0)
                                .userStatsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.recipeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RecipesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecipesTable,
    Recipe,
    $$RecipesTableFilterComposer,
    $$RecipesTableOrderingComposer,
    $$RecipesTableAnnotationComposer,
    $$RecipesTableCreateCompanionBuilder,
    $$RecipesTableUpdateCompanionBuilder,
    (Recipe, $$RecipesTableReferences),
    Recipe,
    PrefetchHooks Function(
        {bool brewingMethodId,
        bool recipeLocalizationsRefs,
        bool stepsRefs,
        bool userRecipePreferencesRefs,
        bool userStatsRefs})>;
typedef $$RecipeLocalizationsTableCreateCompanionBuilder
    = RecipeLocalizationsCompanion Function({
  required String id,
  required String recipeId,
  required String locale,
  required String name,
  required String grindSize,
  required String shortDescription,
  Value<int> rowid,
});
typedef $$RecipeLocalizationsTableUpdateCompanionBuilder
    = RecipeLocalizationsCompanion Function({
  Value<String> id,
  Value<String> recipeId,
  Value<String> locale,
  Value<String> name,
  Value<String> grindSize,
  Value<String> shortDescription,
  Value<int> rowid,
});

final class $$RecipeLocalizationsTableReferences extends BaseReferences<
    _$AppDatabase, $RecipeLocalizationsTable, RecipeLocalization> {
  $$RecipeLocalizationsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias(
          $_aliasNameGenerator(db.recipeLocalizations.recipeId, db.recipes.id));

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager($_db, $_db.recipes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SupportedLocalesTable _localeTable(_$AppDatabase db) =>
      db.supportedLocales.createAlias($_aliasNameGenerator(
          db.recipeLocalizations.locale, db.supportedLocales.locale));

  $$SupportedLocalesTableProcessedTableManager get locale {
    final $_column = $_itemColumn<String>('locale')!;

    final manager =
        $$SupportedLocalesTableTableManager($_db, $_db.supportedLocales)
            .filter((f) => f.locale.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RecipeLocalizationsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeLocalizationsTable> {
  $$RecipeLocalizationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get grindSize => $composableBuilder(
      column: $table.grindSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shortDescription => $composableBuilder(
      column: $table.shortDescription,
      builder: (column) => ColumnFilters(column));

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableFilterComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SupportedLocalesTableFilterComposer get locale {
    final $$SupportedLocalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableFilterComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeLocalizationsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeLocalizationsTable> {
  $$RecipeLocalizationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get grindSize => $composableBuilder(
      column: $table.grindSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shortDescription => $composableBuilder(
      column: $table.shortDescription,
      builder: (column) => ColumnOrderings(column));

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableOrderingComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SupportedLocalesTableOrderingComposer get locale {
    final $$SupportedLocalesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableOrderingComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeLocalizationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeLocalizationsTable> {
  $$RecipeLocalizationsTableAnnotationComposer({
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

  GeneratedColumn<String> get grindSize =>
      $composableBuilder(column: $table.grindSize, builder: (column) => column);

  GeneratedColumn<String> get shortDescription => $composableBuilder(
      column: $table.shortDescription, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableAnnotationComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SupportedLocalesTableAnnotationComposer get locale {
    final $$SupportedLocalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableAnnotationComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecipeLocalizationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecipeLocalizationsTable,
    RecipeLocalization,
    $$RecipeLocalizationsTableFilterComposer,
    $$RecipeLocalizationsTableOrderingComposer,
    $$RecipeLocalizationsTableAnnotationComposer,
    $$RecipeLocalizationsTableCreateCompanionBuilder,
    $$RecipeLocalizationsTableUpdateCompanionBuilder,
    (RecipeLocalization, $$RecipeLocalizationsTableReferences),
    RecipeLocalization,
    PrefetchHooks Function({bool recipeId, bool locale})> {
  $$RecipeLocalizationsTableTableManager(
      _$AppDatabase db, $RecipeLocalizationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeLocalizationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeLocalizationsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeLocalizationsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> recipeId = const Value.absent(),
            Value<String> locale = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> grindSize = const Value.absent(),
            Value<String> shortDescription = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeLocalizationsCompanion(
            id: id,
            recipeId: recipeId,
            locale: locale,
            name: name,
            grindSize: grindSize,
            shortDescription: shortDescription,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String recipeId,
            required String locale,
            required String name,
            required String grindSize,
            required String shortDescription,
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipeLocalizationsCompanion.insert(
            id: id,
            recipeId: recipeId,
            locale: locale,
            name: name,
            grindSize: grindSize,
            shortDescription: shortDescription,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RecipeLocalizationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({recipeId = false, locale = false}) {
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
                if (recipeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recipeId,
                    referencedTable:
                        $$RecipeLocalizationsTableReferences._recipeIdTable(db),
                    referencedColumn: $$RecipeLocalizationsTableReferences
                        ._recipeIdTable(db)
                        .id,
                  ) as T;
                }
                if (locale) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.locale,
                    referencedTable:
                        $$RecipeLocalizationsTableReferences._localeTable(db),
                    referencedColumn: $$RecipeLocalizationsTableReferences
                        ._localeTable(db)
                        .locale,
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

typedef $$RecipeLocalizationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecipeLocalizationsTable,
    RecipeLocalization,
    $$RecipeLocalizationsTableFilterComposer,
    $$RecipeLocalizationsTableOrderingComposer,
    $$RecipeLocalizationsTableAnnotationComposer,
    $$RecipeLocalizationsTableCreateCompanionBuilder,
    $$RecipeLocalizationsTableUpdateCompanionBuilder,
    (RecipeLocalization, $$RecipeLocalizationsTableReferences),
    RecipeLocalization,
    PrefetchHooks Function({bool recipeId, bool locale})>;
typedef $$StepsTableCreateCompanionBuilder = StepsCompanion Function({
  required String id,
  required String recipeId,
  required int stepOrder,
  required String description,
  required String time,
  required String locale,
  Value<int> rowid,
});
typedef $$StepsTableUpdateCompanionBuilder = StepsCompanion Function({
  Value<String> id,
  Value<String> recipeId,
  Value<int> stepOrder,
  Value<String> description,
  Value<String> time,
  Value<String> locale,
  Value<int> rowid,
});

final class $$StepsTableReferences
    extends BaseReferences<_$AppDatabase, $StepsTable, Step> {
  $$StepsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) => db.recipes
      .createAlias($_aliasNameGenerator(db.steps.recipeId, db.recipes.id));

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager($_db, $_db.recipes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SupportedLocalesTable _localeTable(_$AppDatabase db) =>
      db.supportedLocales.createAlias(
          $_aliasNameGenerator(db.steps.locale, db.supportedLocales.locale));

  $$SupportedLocalesTableProcessedTableManager get locale {
    final $_column = $_itemColumn<String>('locale')!;

    final manager =
        $$SupportedLocalesTableTableManager($_db, $_db.supportedLocales)
            .filter((f) => f.locale.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$StepsTableFilterComposer extends Composer<_$AppDatabase, $StepsTable> {
  $$StepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stepOrder => $composableBuilder(
      column: $table.stepOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get time => $composableBuilder(
      column: $table.time, builder: (column) => ColumnFilters(column));

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableFilterComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SupportedLocalesTableFilterComposer get locale {
    final $$SupportedLocalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableFilterComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StepsTableOrderingComposer
    extends Composer<_$AppDatabase, $StepsTable> {
  $$StepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stepOrder => $composableBuilder(
      column: $table.stepOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get time => $composableBuilder(
      column: $table.time, builder: (column) => ColumnOrderings(column));

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableOrderingComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SupportedLocalesTableOrderingComposer get locale {
    final $$SupportedLocalesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableOrderingComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StepsTable> {
  $$StepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get stepOrder =>
      $composableBuilder(column: $table.stepOrder, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableAnnotationComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SupportedLocalesTableAnnotationComposer get locale {
    final $$SupportedLocalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableAnnotationComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StepsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StepsTable,
    Step,
    $$StepsTableFilterComposer,
    $$StepsTableOrderingComposer,
    $$StepsTableAnnotationComposer,
    $$StepsTableCreateCompanionBuilder,
    $$StepsTableUpdateCompanionBuilder,
    (Step, $$StepsTableReferences),
    Step,
    PrefetchHooks Function({bool recipeId, bool locale})> {
  $$StepsTableTableManager(_$AppDatabase db, $StepsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> recipeId = const Value.absent(),
            Value<int> stepOrder = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> time = const Value.absent(),
            Value<String> locale = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StepsCompanion(
            id: id,
            recipeId: recipeId,
            stepOrder: stepOrder,
            description: description,
            time: time,
            locale: locale,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String recipeId,
            required int stepOrder,
            required String description,
            required String time,
            required String locale,
            Value<int> rowid = const Value.absent(),
          }) =>
              StepsCompanion.insert(
            id: id,
            recipeId: recipeId,
            stepOrder: stepOrder,
            description: description,
            time: time,
            locale: locale,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$StepsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({recipeId = false, locale = false}) {
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
                if (recipeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recipeId,
                    referencedTable: $$StepsTableReferences._recipeIdTable(db),
                    referencedColumn:
                        $$StepsTableReferences._recipeIdTable(db).id,
                  ) as T;
                }
                if (locale) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.locale,
                    referencedTable: $$StepsTableReferences._localeTable(db),
                    referencedColumn:
                        $$StepsTableReferences._localeTable(db).locale,
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

typedef $$StepsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StepsTable,
    Step,
    $$StepsTableFilterComposer,
    $$StepsTableOrderingComposer,
    $$StepsTableAnnotationComposer,
    $$StepsTableCreateCompanionBuilder,
    $$StepsTableUpdateCompanionBuilder,
    (Step, $$StepsTableReferences),
    Step,
    PrefetchHooks Function({bool recipeId, bool locale})>;
typedef $$UserRecipePreferencesTableCreateCompanionBuilder
    = UserRecipePreferencesCompanion Function({
  required String recipeId,
  Value<DateTime?> lastUsed,
  required bool isFavorite,
  Value<int> sweetnessSliderPosition,
  Value<int> strengthSliderPosition,
  Value<double?> customCoffeeAmount,
  Value<double?> customWaterAmount,
  Value<int> coffeeChroniclerSliderPosition,
  Value<int> rowid,
});
typedef $$UserRecipePreferencesTableUpdateCompanionBuilder
    = UserRecipePreferencesCompanion Function({
  Value<String> recipeId,
  Value<DateTime?> lastUsed,
  Value<bool> isFavorite,
  Value<int> sweetnessSliderPosition,
  Value<int> strengthSliderPosition,
  Value<double?> customCoffeeAmount,
  Value<double?> customWaterAmount,
  Value<int> coffeeChroniclerSliderPosition,
  Value<int> rowid,
});

final class $$UserRecipePreferencesTableReferences extends BaseReferences<
    _$AppDatabase, $UserRecipePreferencesTable, UserRecipePreference> {
  $$UserRecipePreferencesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias($_aliasNameGenerator(
          db.userRecipePreferences.recipeId, db.recipes.id));

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager($_db, $_db.recipes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UserRecipePreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $UserRecipePreferencesTable> {
  $$UserRecipePreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get lastUsed => $composableBuilder(
      column: $table.lastUsed, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sweetnessSliderPosition => $composableBuilder(
      column: $table.sweetnessSliderPosition,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get strengthSliderPosition => $composableBuilder(
      column: $table.strengthSliderPosition,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get customCoffeeAmount => $composableBuilder(
      column: $table.customCoffeeAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get customWaterAmount => $composableBuilder(
      column: $table.customWaterAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get coffeeChroniclerSliderPosition => $composableBuilder(
      column: $table.coffeeChroniclerSliderPosition,
      builder: (column) => ColumnFilters(column));

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableFilterComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserRecipePreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserRecipePreferencesTable> {
  $$UserRecipePreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get lastUsed => $composableBuilder(
      column: $table.lastUsed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sweetnessSliderPosition => $composableBuilder(
      column: $table.sweetnessSliderPosition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get strengthSliderPosition => $composableBuilder(
      column: $table.strengthSliderPosition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get customCoffeeAmount => $composableBuilder(
      column: $table.customCoffeeAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get customWaterAmount => $composableBuilder(
      column: $table.customWaterAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get coffeeChroniclerSliderPosition => $composableBuilder(
      column: $table.coffeeChroniclerSliderPosition,
      builder: (column) => ColumnOrderings(column));

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableOrderingComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserRecipePreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserRecipePreferencesTable> {
  $$UserRecipePreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get lastUsed =>
      $composableBuilder(column: $table.lastUsed, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<int> get sweetnessSliderPosition => $composableBuilder(
      column: $table.sweetnessSliderPosition, builder: (column) => column);

  GeneratedColumn<int> get strengthSliderPosition => $composableBuilder(
      column: $table.strengthSliderPosition, builder: (column) => column);

  GeneratedColumn<double> get customCoffeeAmount => $composableBuilder(
      column: $table.customCoffeeAmount, builder: (column) => column);

  GeneratedColumn<double> get customWaterAmount => $composableBuilder(
      column: $table.customWaterAmount, builder: (column) => column);

  GeneratedColumn<int> get coffeeChroniclerSliderPosition => $composableBuilder(
      column: $table.coffeeChroniclerSliderPosition,
      builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableAnnotationComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserRecipePreferencesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserRecipePreferencesTable,
    UserRecipePreference,
    $$UserRecipePreferencesTableFilterComposer,
    $$UserRecipePreferencesTableOrderingComposer,
    $$UserRecipePreferencesTableAnnotationComposer,
    $$UserRecipePreferencesTableCreateCompanionBuilder,
    $$UserRecipePreferencesTableUpdateCompanionBuilder,
    (UserRecipePreference, $$UserRecipePreferencesTableReferences),
    UserRecipePreference,
    PrefetchHooks Function({bool recipeId})> {
  $$UserRecipePreferencesTableTableManager(
      _$AppDatabase db, $UserRecipePreferencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserRecipePreferencesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$UserRecipePreferencesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserRecipePreferencesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> recipeId = const Value.absent(),
            Value<DateTime?> lastUsed = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> sweetnessSliderPosition = const Value.absent(),
            Value<int> strengthSliderPosition = const Value.absent(),
            Value<double?> customCoffeeAmount = const Value.absent(),
            Value<double?> customWaterAmount = const Value.absent(),
            Value<int> coffeeChroniclerSliderPosition = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserRecipePreferencesCompanion(
            recipeId: recipeId,
            lastUsed: lastUsed,
            isFavorite: isFavorite,
            sweetnessSliderPosition: sweetnessSliderPosition,
            strengthSliderPosition: strengthSliderPosition,
            customCoffeeAmount: customCoffeeAmount,
            customWaterAmount: customWaterAmount,
            coffeeChroniclerSliderPosition: coffeeChroniclerSliderPosition,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String recipeId,
            Value<DateTime?> lastUsed = const Value.absent(),
            required bool isFavorite,
            Value<int> sweetnessSliderPosition = const Value.absent(),
            Value<int> strengthSliderPosition = const Value.absent(),
            Value<double?> customCoffeeAmount = const Value.absent(),
            Value<double?> customWaterAmount = const Value.absent(),
            Value<int> coffeeChroniclerSliderPosition = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserRecipePreferencesCompanion.insert(
            recipeId: recipeId,
            lastUsed: lastUsed,
            isFavorite: isFavorite,
            sweetnessSliderPosition: sweetnessSliderPosition,
            strengthSliderPosition: strengthSliderPosition,
            customCoffeeAmount: customCoffeeAmount,
            customWaterAmount: customWaterAmount,
            coffeeChroniclerSliderPosition: coffeeChroniclerSliderPosition,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UserRecipePreferencesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
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
                if (recipeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recipeId,
                    referencedTable: $$UserRecipePreferencesTableReferences
                        ._recipeIdTable(db),
                    referencedColumn: $$UserRecipePreferencesTableReferences
                        ._recipeIdTable(db)
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

typedef $$UserRecipePreferencesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $UserRecipePreferencesTable,
        UserRecipePreference,
        $$UserRecipePreferencesTableFilterComposer,
        $$UserRecipePreferencesTableOrderingComposer,
        $$UserRecipePreferencesTableAnnotationComposer,
        $$UserRecipePreferencesTableCreateCompanionBuilder,
        $$UserRecipePreferencesTableUpdateCompanionBuilder,
        (UserRecipePreference, $$UserRecipePreferencesTableReferences),
        UserRecipePreference,
        PrefetchHooks Function({bool recipeId})>;
typedef $$CoffeeFactsTableCreateCompanionBuilder = CoffeeFactsCompanion
    Function({
  required String id,
  required String fact,
  required String locale,
  Value<int> rowid,
});
typedef $$CoffeeFactsTableUpdateCompanionBuilder = CoffeeFactsCompanion
    Function({
  Value<String> id,
  Value<String> fact,
  Value<String> locale,
  Value<int> rowid,
});

final class $$CoffeeFactsTableReferences
    extends BaseReferences<_$AppDatabase, $CoffeeFactsTable, CoffeeFact> {
  $$CoffeeFactsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SupportedLocalesTable _localeTable(_$AppDatabase db) =>
      db.supportedLocales.createAlias($_aliasNameGenerator(
          db.coffeeFacts.locale, db.supportedLocales.locale));

  $$SupportedLocalesTableProcessedTableManager get locale {
    final $_column = $_itemColumn<String>('locale')!;

    final manager =
        $$SupportedLocalesTableTableManager($_db, $_db.supportedLocales)
            .filter((f) => f.locale.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CoffeeFactsTableFilterComposer
    extends Composer<_$AppDatabase, $CoffeeFactsTable> {
  $$CoffeeFactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fact => $composableBuilder(
      column: $table.fact, builder: (column) => ColumnFilters(column));

  $$SupportedLocalesTableFilterComposer get locale {
    final $$SupportedLocalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableFilterComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CoffeeFactsTableOrderingComposer
    extends Composer<_$AppDatabase, $CoffeeFactsTable> {
  $$CoffeeFactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fact => $composableBuilder(
      column: $table.fact, builder: (column) => ColumnOrderings(column));

  $$SupportedLocalesTableOrderingComposer get locale {
    final $$SupportedLocalesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableOrderingComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CoffeeFactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoffeeFactsTable> {
  $$CoffeeFactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fact =>
      $composableBuilder(column: $table.fact, builder: (column) => column);

  $$SupportedLocalesTableAnnotationComposer get locale {
    final $$SupportedLocalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableAnnotationComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CoffeeFactsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CoffeeFactsTable,
    CoffeeFact,
    $$CoffeeFactsTableFilterComposer,
    $$CoffeeFactsTableOrderingComposer,
    $$CoffeeFactsTableAnnotationComposer,
    $$CoffeeFactsTableCreateCompanionBuilder,
    $$CoffeeFactsTableUpdateCompanionBuilder,
    (CoffeeFact, $$CoffeeFactsTableReferences),
    CoffeeFact,
    PrefetchHooks Function({bool locale})> {
  $$CoffeeFactsTableTableManager(_$AppDatabase db, $CoffeeFactsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoffeeFactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoffeeFactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoffeeFactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fact = const Value.absent(),
            Value<String> locale = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CoffeeFactsCompanion(
            id: id,
            fact: fact,
            locale: locale,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fact,
            required String locale,
            Value<int> rowid = const Value.absent(),
          }) =>
              CoffeeFactsCompanion.insert(
            id: id,
            fact: fact,
            locale: locale,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CoffeeFactsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({locale = false}) {
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
                if (locale) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.locale,
                    referencedTable:
                        $$CoffeeFactsTableReferences._localeTable(db),
                    referencedColumn:
                        $$CoffeeFactsTableReferences._localeTable(db).locale,
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

typedef $$CoffeeFactsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CoffeeFactsTable,
    CoffeeFact,
    $$CoffeeFactsTableFilterComposer,
    $$CoffeeFactsTableOrderingComposer,
    $$CoffeeFactsTableAnnotationComposer,
    $$CoffeeFactsTableCreateCompanionBuilder,
    $$CoffeeFactsTableUpdateCompanionBuilder,
    (CoffeeFact, $$CoffeeFactsTableReferences),
    CoffeeFact,
    PrefetchHooks Function({bool locale})>;
typedef $$LaunchPopupsTableCreateCompanionBuilder = LaunchPopupsCompanion
    Function({
  Value<int> id,
  required String content,
  required String locale,
  required DateTime createdAt,
});
typedef $$LaunchPopupsTableUpdateCompanionBuilder = LaunchPopupsCompanion
    Function({
  Value<int> id,
  Value<String> content,
  Value<String> locale,
  Value<DateTime> createdAt,
});

final class $$LaunchPopupsTableReferences
    extends BaseReferences<_$AppDatabase, $LaunchPopupsTable, LaunchPopup> {
  $$LaunchPopupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SupportedLocalesTable _localeTable(_$AppDatabase db) =>
      db.supportedLocales.createAlias($_aliasNameGenerator(
          db.launchPopups.locale, db.supportedLocales.locale));

  $$SupportedLocalesTableProcessedTableManager get locale {
    final $_column = $_itemColumn<String>('locale')!;

    final manager =
        $$SupportedLocalesTableTableManager($_db, $_db.supportedLocales)
            .filter((f) => f.locale.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LaunchPopupsTableFilterComposer
    extends Composer<_$AppDatabase, $LaunchPopupsTable> {
  $$LaunchPopupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$SupportedLocalesTableFilterComposer get locale {
    final $$SupportedLocalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableFilterComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LaunchPopupsTableOrderingComposer
    extends Composer<_$AppDatabase, $LaunchPopupsTable> {
  $$LaunchPopupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$SupportedLocalesTableOrderingComposer get locale {
    final $$SupportedLocalesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableOrderingComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LaunchPopupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LaunchPopupsTable> {
  $$LaunchPopupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SupportedLocalesTableAnnotationComposer get locale {
    final $$SupportedLocalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableAnnotationComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LaunchPopupsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LaunchPopupsTable,
    LaunchPopup,
    $$LaunchPopupsTableFilterComposer,
    $$LaunchPopupsTableOrderingComposer,
    $$LaunchPopupsTableAnnotationComposer,
    $$LaunchPopupsTableCreateCompanionBuilder,
    $$LaunchPopupsTableUpdateCompanionBuilder,
    (LaunchPopup, $$LaunchPopupsTableReferences),
    LaunchPopup,
    PrefetchHooks Function({bool locale})> {
  $$LaunchPopupsTableTableManager(_$AppDatabase db, $LaunchPopupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LaunchPopupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LaunchPopupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LaunchPopupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> locale = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              LaunchPopupsCompanion(
            id: id,
            content: content,
            locale: locale,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String content,
            required String locale,
            required DateTime createdAt,
          }) =>
              LaunchPopupsCompanion.insert(
            id: id,
            content: content,
            locale: locale,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LaunchPopupsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({locale = false}) {
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
                if (locale) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.locale,
                    referencedTable:
                        $$LaunchPopupsTableReferences._localeTable(db),
                    referencedColumn:
                        $$LaunchPopupsTableReferences._localeTable(db).locale,
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

typedef $$LaunchPopupsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LaunchPopupsTable,
    LaunchPopup,
    $$LaunchPopupsTableFilterComposer,
    $$LaunchPopupsTableOrderingComposer,
    $$LaunchPopupsTableAnnotationComposer,
    $$LaunchPopupsTableCreateCompanionBuilder,
    $$LaunchPopupsTableUpdateCompanionBuilder,
    (LaunchPopup, $$LaunchPopupsTableReferences),
    LaunchPopup,
    PrefetchHooks Function({bool locale})>;
typedef $$ContributorsTableCreateCompanionBuilder = ContributorsCompanion
    Function({
  required String id,
  required String content,
  required String locale,
  Value<int> rowid,
});
typedef $$ContributorsTableUpdateCompanionBuilder = ContributorsCompanion
    Function({
  Value<String> id,
  Value<String> content,
  Value<String> locale,
  Value<int> rowid,
});

final class $$ContributorsTableReferences
    extends BaseReferences<_$AppDatabase, $ContributorsTable, Contributor> {
  $$ContributorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SupportedLocalesTable _localeTable(_$AppDatabase db) =>
      db.supportedLocales.createAlias($_aliasNameGenerator(
          db.contributors.locale, db.supportedLocales.locale));

  $$SupportedLocalesTableProcessedTableManager get locale {
    final $_column = $_itemColumn<String>('locale')!;

    final manager =
        $$SupportedLocalesTableTableManager($_db, $_db.supportedLocales)
            .filter((f) => f.locale.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ContributorsTableFilterComposer
    extends Composer<_$AppDatabase, $ContributorsTable> {
  $$ContributorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  $$SupportedLocalesTableFilterComposer get locale {
    final $$SupportedLocalesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableFilterComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ContributorsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContributorsTable> {
  $$ContributorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  $$SupportedLocalesTableOrderingComposer get locale {
    final $$SupportedLocalesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableOrderingComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ContributorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContributorsTable> {
  $$ContributorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  $$SupportedLocalesTableAnnotationComposer get locale {
    final $$SupportedLocalesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.locale,
        referencedTable: $db.supportedLocales,
        getReferencedColumn: (t) => t.locale,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SupportedLocalesTableAnnotationComposer(
              $db: $db,
              $table: $db.supportedLocales,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ContributorsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ContributorsTable,
    Contributor,
    $$ContributorsTableFilterComposer,
    $$ContributorsTableOrderingComposer,
    $$ContributorsTableAnnotationComposer,
    $$ContributorsTableCreateCompanionBuilder,
    $$ContributorsTableUpdateCompanionBuilder,
    (Contributor, $$ContributorsTableReferences),
    Contributor,
    PrefetchHooks Function({bool locale})> {
  $$ContributorsTableTableManager(_$AppDatabase db, $ContributorsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContributorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContributorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContributorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> locale = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContributorsCompanion(
            id: id,
            content: content,
            locale: locale,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String content,
            required String locale,
            Value<int> rowid = const Value.absent(),
          }) =>
              ContributorsCompanion.insert(
            id: id,
            content: content,
            locale: locale,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ContributorsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({locale = false}) {
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
                if (locale) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.locale,
                    referencedTable:
                        $$ContributorsTableReferences._localeTable(db),
                    referencedColumn:
                        $$ContributorsTableReferences._localeTable(db).locale,
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

typedef $$ContributorsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ContributorsTable,
    Contributor,
    $$ContributorsTableFilterComposer,
    $$ContributorsTableOrderingComposer,
    $$ContributorsTableAnnotationComposer,
    $$ContributorsTableCreateCompanionBuilder,
    $$ContributorsTableUpdateCompanionBuilder,
    (Contributor, $$ContributorsTableReferences),
    Contributor,
    PrefetchHooks Function({bool locale})>;
typedef $$UserStatsTableCreateCompanionBuilder = UserStatsCompanion Function({
  required String statUuid,
  Value<int?> id,
  required String recipeId,
  required double coffeeAmount,
  required double waterAmount,
  required int sweetnessSliderPosition,
  required int strengthSliderPosition,
  required String brewingMethodId,
  Value<DateTime> createdAt,
  Value<String?> notes,
  Value<String?> beans,
  Value<String?> roaster,
  Value<double?> rating,
  Value<int?> coffeeBeansId,
  Value<bool> isMarked,
  Value<String?> coffeeBeansUuid,
  required String versionVector,
  Value<bool> isDeleted,
  Value<int> rowid,
});
typedef $$UserStatsTableUpdateCompanionBuilder = UserStatsCompanion Function({
  Value<String> statUuid,
  Value<int?> id,
  Value<String> recipeId,
  Value<double> coffeeAmount,
  Value<double> waterAmount,
  Value<int> sweetnessSliderPosition,
  Value<int> strengthSliderPosition,
  Value<String> brewingMethodId,
  Value<DateTime> createdAt,
  Value<String?> notes,
  Value<String?> beans,
  Value<String?> roaster,
  Value<double?> rating,
  Value<int?> coffeeBeansId,
  Value<bool> isMarked,
  Value<String?> coffeeBeansUuid,
  Value<String> versionVector,
  Value<bool> isDeleted,
  Value<int> rowid,
});

final class $$UserStatsTableReferences
    extends BaseReferences<_$AppDatabase, $UserStatsTable, UserStat> {
  $$UserStatsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RecipesTable _recipeIdTable(_$AppDatabase db) => db.recipes
      .createAlias($_aliasNameGenerator(db.userStats.recipeId, db.recipes.id));

  $$RecipesTableProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $$RecipesTableTableManager($_db, $_db.recipes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $BrewingMethodsTable _brewingMethodIdTable(_$AppDatabase db) =>
      db.brewingMethods.createAlias($_aliasNameGenerator(
          db.userStats.brewingMethodId, db.brewingMethods.brewingMethodId));

  $$BrewingMethodsTableProcessedTableManager get brewingMethodId {
    final $_column = $_itemColumn<String>('brewing_method_id')!;

    final manager = $$BrewingMethodsTableTableManager($_db, $_db.brewingMethods)
        .filter((f) => f.brewingMethodId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_brewingMethodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UserStatsTableFilterComposer
    extends Composer<_$AppDatabase, $UserStatsTable> {
  $$UserStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get statUuid => $composableBuilder(
      column: $table.statUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get coffeeAmount => $composableBuilder(
      column: $table.coffeeAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get waterAmount => $composableBuilder(
      column: $table.waterAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sweetnessSliderPosition => $composableBuilder(
      column: $table.sweetnessSliderPosition,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get strengthSliderPosition => $composableBuilder(
      column: $table.strengthSliderPosition,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get beans => $composableBuilder(
      column: $table.beans, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get roaster => $composableBuilder(
      column: $table.roaster, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get coffeeBeansId => $composableBuilder(
      column: $table.coffeeBeansId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isMarked => $composableBuilder(
      column: $table.isMarked, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coffeeBeansUuid => $composableBuilder(
      column: $table.coffeeBeansUuid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get versionVector => $composableBuilder(
      column: $table.versionVector, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableFilterComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BrewingMethodsTableFilterComposer get brewingMethodId {
    final $$BrewingMethodsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.brewingMethodId,
        referencedTable: $db.brewingMethods,
        getReferencedColumn: (t) => t.brewingMethodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BrewingMethodsTableFilterComposer(
              $db: $db,
              $table: $db.brewingMethods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserStatsTable> {
  $$UserStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get statUuid => $composableBuilder(
      column: $table.statUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get coffeeAmount => $composableBuilder(
      column: $table.coffeeAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get waterAmount => $composableBuilder(
      column: $table.waterAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sweetnessSliderPosition => $composableBuilder(
      column: $table.sweetnessSliderPosition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get strengthSliderPosition => $composableBuilder(
      column: $table.strengthSliderPosition,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get beans => $composableBuilder(
      column: $table.beans, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get roaster => $composableBuilder(
      column: $table.roaster, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get coffeeBeansId => $composableBuilder(
      column: $table.coffeeBeansId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isMarked => $composableBuilder(
      column: $table.isMarked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coffeeBeansUuid => $composableBuilder(
      column: $table.coffeeBeansUuid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get versionVector => $composableBuilder(
      column: $table.versionVector,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableOrderingComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BrewingMethodsTableOrderingComposer get brewingMethodId {
    final $$BrewingMethodsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.brewingMethodId,
        referencedTable: $db.brewingMethods,
        getReferencedColumn: (t) => t.brewingMethodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BrewingMethodsTableOrderingComposer(
              $db: $db,
              $table: $db.brewingMethods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserStatsTable> {
  $$UserStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get statUuid =>
      $composableBuilder(column: $table.statUuid, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get coffeeAmount => $composableBuilder(
      column: $table.coffeeAmount, builder: (column) => column);

  GeneratedColumn<double> get waterAmount => $composableBuilder(
      column: $table.waterAmount, builder: (column) => column);

  GeneratedColumn<int> get sweetnessSliderPosition => $composableBuilder(
      column: $table.sweetnessSliderPosition, builder: (column) => column);

  GeneratedColumn<int> get strengthSliderPosition => $composableBuilder(
      column: $table.strengthSliderPosition, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get beans =>
      $composableBuilder(column: $table.beans, builder: (column) => column);

  GeneratedColumn<String> get roaster =>
      $composableBuilder(column: $table.roaster, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get coffeeBeansId => $composableBuilder(
      column: $table.coffeeBeansId, builder: (column) => column);

  GeneratedColumn<bool> get isMarked =>
      $composableBuilder(column: $table.isMarked, builder: (column) => column);

  GeneratedColumn<String> get coffeeBeansUuid => $composableBuilder(
      column: $table.coffeeBeansUuid, builder: (column) => column);

  GeneratedColumn<String> get versionVector => $composableBuilder(
      column: $table.versionVector, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recipeId,
        referencedTable: $db.recipes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecipesTableAnnotationComposer(
              $db: $db,
              $table: $db.recipes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BrewingMethodsTableAnnotationComposer get brewingMethodId {
    final $$BrewingMethodsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.brewingMethodId,
        referencedTable: $db.brewingMethods,
        getReferencedColumn: (t) => t.brewingMethodId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BrewingMethodsTableAnnotationComposer(
              $db: $db,
              $table: $db.brewingMethods,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserStatsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserStatsTable,
    UserStat,
    $$UserStatsTableFilterComposer,
    $$UserStatsTableOrderingComposer,
    $$UserStatsTableAnnotationComposer,
    $$UserStatsTableCreateCompanionBuilder,
    $$UserStatsTableUpdateCompanionBuilder,
    (UserStat, $$UserStatsTableReferences),
    UserStat,
    PrefetchHooks Function({bool recipeId, bool brewingMethodId})> {
  $$UserStatsTableTableManager(_$AppDatabase db, $UserStatsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> statUuid = const Value.absent(),
            Value<int?> id = const Value.absent(),
            Value<String> recipeId = const Value.absent(),
            Value<double> coffeeAmount = const Value.absent(),
            Value<double> waterAmount = const Value.absent(),
            Value<int> sweetnessSliderPosition = const Value.absent(),
            Value<int> strengthSliderPosition = const Value.absent(),
            Value<String> brewingMethodId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> beans = const Value.absent(),
            Value<String?> roaster = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<int?> coffeeBeansId = const Value.absent(),
            Value<bool> isMarked = const Value.absent(),
            Value<String?> coffeeBeansUuid = const Value.absent(),
            Value<String> versionVector = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserStatsCompanion(
            statUuid: statUuid,
            id: id,
            recipeId: recipeId,
            coffeeAmount: coffeeAmount,
            waterAmount: waterAmount,
            sweetnessSliderPosition: sweetnessSliderPosition,
            strengthSliderPosition: strengthSliderPosition,
            brewingMethodId: brewingMethodId,
            createdAt: createdAt,
            notes: notes,
            beans: beans,
            roaster: roaster,
            rating: rating,
            coffeeBeansId: coffeeBeansId,
            isMarked: isMarked,
            coffeeBeansUuid: coffeeBeansUuid,
            versionVector: versionVector,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String statUuid,
            Value<int?> id = const Value.absent(),
            required String recipeId,
            required double coffeeAmount,
            required double waterAmount,
            required int sweetnessSliderPosition,
            required int strengthSliderPosition,
            required String brewingMethodId,
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> beans = const Value.absent(),
            Value<String?> roaster = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<int?> coffeeBeansId = const Value.absent(),
            Value<bool> isMarked = const Value.absent(),
            Value<String?> coffeeBeansUuid = const Value.absent(),
            required String versionVector,
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserStatsCompanion.insert(
            statUuid: statUuid,
            id: id,
            recipeId: recipeId,
            coffeeAmount: coffeeAmount,
            waterAmount: waterAmount,
            sweetnessSliderPosition: sweetnessSliderPosition,
            strengthSliderPosition: strengthSliderPosition,
            brewingMethodId: brewingMethodId,
            createdAt: createdAt,
            notes: notes,
            beans: beans,
            roaster: roaster,
            rating: rating,
            coffeeBeansId: coffeeBeansId,
            isMarked: isMarked,
            coffeeBeansUuid: coffeeBeansUuid,
            versionVector: versionVector,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UserStatsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({recipeId = false, brewingMethodId = false}) {
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
                if (recipeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recipeId,
                    referencedTable:
                        $$UserStatsTableReferences._recipeIdTable(db),
                    referencedColumn:
                        $$UserStatsTableReferences._recipeIdTable(db).id,
                  ) as T;
                }
                if (brewingMethodId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.brewingMethodId,
                    referencedTable:
                        $$UserStatsTableReferences._brewingMethodIdTable(db),
                    referencedColumn: $$UserStatsTableReferences
                        ._brewingMethodIdTable(db)
                        .brewingMethodId,
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

typedef $$UserStatsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserStatsTable,
    UserStat,
    $$UserStatsTableFilterComposer,
    $$UserStatsTableOrderingComposer,
    $$UserStatsTableAnnotationComposer,
    $$UserStatsTableCreateCompanionBuilder,
    $$UserStatsTableUpdateCompanionBuilder,
    (UserStat, $$UserStatsTableReferences),
    UserStat,
    PrefetchHooks Function({bool recipeId, bool brewingMethodId})>;
typedef $$CoffeeBeansTableCreateCompanionBuilder = CoffeeBeansCompanion
    Function({
  required String beansUuid,
  Value<int?> id,
  required String roaster,
  required String name,
  required String origin,
  Value<String?> variety,
  Value<String?> tastingNotes,
  Value<String?> processingMethod,
  Value<int?> elevation,
  Value<DateTime?> harvestDate,
  Value<DateTime?> roastDate,
  Value<String?> region,
  Value<String?> roastLevel,
  Value<double?> cuppingScore,
  Value<String?> notes,
  Value<bool> isFavorite,
  required String versionVector,
  Value<bool> isDeleted,
  Value<int> rowid,
});
typedef $$CoffeeBeansTableUpdateCompanionBuilder = CoffeeBeansCompanion
    Function({
  Value<String> beansUuid,
  Value<int?> id,
  Value<String> roaster,
  Value<String> name,
  Value<String> origin,
  Value<String?> variety,
  Value<String?> tastingNotes,
  Value<String?> processingMethod,
  Value<int?> elevation,
  Value<DateTime?> harvestDate,
  Value<DateTime?> roastDate,
  Value<String?> region,
  Value<String?> roastLevel,
  Value<double?> cuppingScore,
  Value<String?> notes,
  Value<bool> isFavorite,
  Value<String> versionVector,
  Value<bool> isDeleted,
  Value<int> rowid,
});

class $$CoffeeBeansTableFilterComposer
    extends Composer<_$AppDatabase, $CoffeeBeansTable> {
  $$CoffeeBeansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get beansUuid => $composableBuilder(
      column: $table.beansUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get roaster => $composableBuilder(
      column: $table.roaster, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get origin => $composableBuilder(
      column: $table.origin, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get variety => $composableBuilder(
      column: $table.variety, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tastingNotes => $composableBuilder(
      column: $table.tastingNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get processingMethod => $composableBuilder(
      column: $table.processingMethod,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elevation => $composableBuilder(
      column: $table.elevation, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get harvestDate => $composableBuilder(
      column: $table.harvestDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get roastDate => $composableBuilder(
      column: $table.roastDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get region => $composableBuilder(
      column: $table.region, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get roastLevel => $composableBuilder(
      column: $table.roastLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cuppingScore => $composableBuilder(
      column: $table.cuppingScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get versionVector => $composableBuilder(
      column: $table.versionVector, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));
}

class $$CoffeeBeansTableOrderingComposer
    extends Composer<_$AppDatabase, $CoffeeBeansTable> {
  $$CoffeeBeansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get beansUuid => $composableBuilder(
      column: $table.beansUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get roaster => $composableBuilder(
      column: $table.roaster, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get origin => $composableBuilder(
      column: $table.origin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get variety => $composableBuilder(
      column: $table.variety, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tastingNotes => $composableBuilder(
      column: $table.tastingNotes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get processingMethod => $composableBuilder(
      column: $table.processingMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elevation => $composableBuilder(
      column: $table.elevation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get harvestDate => $composableBuilder(
      column: $table.harvestDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get roastDate => $composableBuilder(
      column: $table.roastDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get region => $composableBuilder(
      column: $table.region, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get roastLevel => $composableBuilder(
      column: $table.roastLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cuppingScore => $composableBuilder(
      column: $table.cuppingScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get versionVector => $composableBuilder(
      column: $table.versionVector,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));
}

class $$CoffeeBeansTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoffeeBeansTable> {
  $$CoffeeBeansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get beansUuid =>
      $composableBuilder(column: $table.beansUuid, builder: (column) => column);

  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get roaster =>
      $composableBuilder(column: $table.roaster, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get variety =>
      $composableBuilder(column: $table.variety, builder: (column) => column);

  GeneratedColumn<String> get tastingNotes => $composableBuilder(
      column: $table.tastingNotes, builder: (column) => column);

  GeneratedColumn<String> get processingMethod => $composableBuilder(
      column: $table.processingMethod, builder: (column) => column);

  GeneratedColumn<int> get elevation =>
      $composableBuilder(column: $table.elevation, builder: (column) => column);

  GeneratedColumn<DateTime> get harvestDate => $composableBuilder(
      column: $table.harvestDate, builder: (column) => column);

  GeneratedColumn<DateTime> get roastDate =>
      $composableBuilder(column: $table.roastDate, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get roastLevel => $composableBuilder(
      column: $table.roastLevel, builder: (column) => column);

  GeneratedColumn<double> get cuppingScore => $composableBuilder(
      column: $table.cuppingScore, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<String> get versionVector => $composableBuilder(
      column: $table.versionVector, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$CoffeeBeansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CoffeeBeansTable,
    CoffeeBean,
    $$CoffeeBeansTableFilterComposer,
    $$CoffeeBeansTableOrderingComposer,
    $$CoffeeBeansTableAnnotationComposer,
    $$CoffeeBeansTableCreateCompanionBuilder,
    $$CoffeeBeansTableUpdateCompanionBuilder,
    (CoffeeBean, BaseReferences<_$AppDatabase, $CoffeeBeansTable, CoffeeBean>),
    CoffeeBean,
    PrefetchHooks Function()> {
  $$CoffeeBeansTableTableManager(_$AppDatabase db, $CoffeeBeansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoffeeBeansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoffeeBeansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoffeeBeansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> beansUuid = const Value.absent(),
            Value<int?> id = const Value.absent(),
            Value<String> roaster = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> origin = const Value.absent(),
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
            Value<bool> isFavorite = const Value.absent(),
            Value<String> versionVector = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CoffeeBeansCompanion(
            beansUuid: beansUuid,
            id: id,
            roaster: roaster,
            name: name,
            origin: origin,
            variety: variety,
            tastingNotes: tastingNotes,
            processingMethod: processingMethod,
            elevation: elevation,
            harvestDate: harvestDate,
            roastDate: roastDate,
            region: region,
            roastLevel: roastLevel,
            cuppingScore: cuppingScore,
            notes: notes,
            isFavorite: isFavorite,
            versionVector: versionVector,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String beansUuid,
            Value<int?> id = const Value.absent(),
            required String roaster,
            required String name,
            required String origin,
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
            Value<bool> isFavorite = const Value.absent(),
            required String versionVector,
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CoffeeBeansCompanion.insert(
            beansUuid: beansUuid,
            id: id,
            roaster: roaster,
            name: name,
            origin: origin,
            variety: variety,
            tastingNotes: tastingNotes,
            processingMethod: processingMethod,
            elevation: elevation,
            harvestDate: harvestDate,
            roastDate: roastDate,
            region: region,
            roastLevel: roastLevel,
            cuppingScore: cuppingScore,
            notes: notes,
            isFavorite: isFavorite,
            versionVector: versionVector,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CoffeeBeansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CoffeeBeansTable,
    CoffeeBean,
    $$CoffeeBeansTableFilterComposer,
    $$CoffeeBeansTableOrderingComposer,
    $$CoffeeBeansTableAnnotationComposer,
    $$CoffeeBeansTableCreateCompanionBuilder,
    $$CoffeeBeansTableUpdateCompanionBuilder,
    (CoffeeBean, BaseReferences<_$AppDatabase, $CoffeeBeansTable, CoffeeBean>),
    CoffeeBean,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SupportedLocalesTableTableManager get supportedLocales =>
      $$SupportedLocalesTableTableManager(_db, _db.supportedLocales);
  $$BrewingMethodsTableTableManager get brewingMethods =>
      $$BrewingMethodsTableTableManager(_db, _db.brewingMethods);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$RecipeLocalizationsTableTableManager get recipeLocalizations =>
      $$RecipeLocalizationsTableTableManager(_db, _db.recipeLocalizations);
  $$StepsTableTableManager get steps =>
      $$StepsTableTableManager(_db, _db.steps);
  $$UserRecipePreferencesTableTableManager get userRecipePreferences =>
      $$UserRecipePreferencesTableTableManager(_db, _db.userRecipePreferences);
  $$CoffeeFactsTableTableManager get coffeeFacts =>
      $$CoffeeFactsTableTableManager(_db, _db.coffeeFacts);
  $$LaunchPopupsTableTableManager get launchPopups =>
      $$LaunchPopupsTableTableManager(_db, _db.launchPopups);
  $$ContributorsTableTableManager get contributors =>
      $$ContributorsTableTableManager(_db, _db.contributors);
  $$UserStatsTableTableManager get userStats =>
      $$UserStatsTableTableManager(_db, _db.userStats);
  $$CoffeeBeansTableTableManager get coffeeBeans =>
      $$CoffeeBeansTableTableManager(_db, _db.coffeeBeans);
}

mixin _$RecipesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BrewingMethodsTable get brewingMethods => attachedDatabase.brewingMethods;
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
  $RecipesTable get recipes => attachedDatabase.recipes;
  $SupportedLocalesTable get supportedLocales =>
      attachedDatabase.supportedLocales;
  $StepsTable get steps => attachedDatabase.steps;
}
mixin _$RecipeLocalizationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BrewingMethodsTable get brewingMethods => attachedDatabase.brewingMethods;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $SupportedLocalesTable get supportedLocales =>
      attachedDatabase.supportedLocales;
  $RecipeLocalizationsTable get recipeLocalizations =>
      attachedDatabase.recipeLocalizations;
}
mixin _$UserRecipePreferencesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BrewingMethodsTable get brewingMethods => attachedDatabase.brewingMethods;
  $RecipesTable get recipes => attachedDatabase.recipes;
  $UserRecipePreferencesTable get userRecipePreferences =>
      attachedDatabase.userRecipePreferences;
}
mixin _$BrewingMethodsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BrewingMethodsTable get brewingMethods => attachedDatabase.brewingMethods;
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
