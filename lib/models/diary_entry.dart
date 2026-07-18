import '../utils/diary_tags.dart';

class DiaryEntry {
  static const Object _unset = Object();

  final String statUuid;
  final String recipeId;
  final String recipeName;
  final String brewingMethodId;
  final String methodName;
  final DateTime createdAt;
  final double coffeeAmount;
  final double waterAmount;
  final String? grindSize;
  final double? waterTemp;

  /// True when [waterTemp] was not recorded on this entry and was instead
  /// filled in from the linked recipe's default temperature.
  final bool waterTempIsDerived;
  final double? tdsPercent;
  final double? extractionYieldPercent;
  final int? tasteBalance;
  final int? entrySource;
  final String? tags;
  final double? rating;
  final bool isMarked;
  final String? notes;
  final String? coffeeBeansUuid;
  final String? beanName;
  final String? roaster;
  final String? origin;

  const DiaryEntry({
    required this.statUuid,
    required this.recipeId,
    required this.recipeName,
    required this.brewingMethodId,
    required this.methodName,
    required this.createdAt,
    required this.coffeeAmount,
    required this.waterAmount,
    this.grindSize,
    this.waterTemp,
    this.waterTempIsDerived = false,
    this.tdsPercent,
    this.extractionYieldPercent,
    this.tasteBalance,
    this.entrySource,
    this.tags,
    this.rating,
    required this.isMarked,
    this.notes,
    this.coffeeBeansUuid,
    this.beanName,
    this.roaster,
    this.origin,
  });

  DiaryEntry copyWith({
    String? statUuid,
    String? recipeId,
    String? recipeName,
    String? brewingMethodId,
    String? methodName,
    DateTime? createdAt,
    double? coffeeAmount,
    double? waterAmount,
    Object? grindSize = _unset,
    Object? waterTemp = _unset,
    bool? waterTempIsDerived,
    Object? tdsPercent = _unset,
    Object? extractionYieldPercent = _unset,
    Object? tasteBalance = _unset,
    Object? entrySource = _unset,
    Object? tags = _unset,
    Object? rating = _unset,
    bool? isMarked,
    Object? notes = _unset,
    Object? coffeeBeansUuid = _unset,
    Object? beanName = _unset,
    Object? roaster = _unset,
    Object? origin = _unset,
  }) {
    return DiaryEntry(
      statUuid: statUuid ?? this.statUuid,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      brewingMethodId: brewingMethodId ?? this.brewingMethodId,
      methodName: methodName ?? this.methodName,
      createdAt: createdAt ?? this.createdAt,
      coffeeAmount: coffeeAmount ?? this.coffeeAmount,
      waterAmount: waterAmount ?? this.waterAmount,
      grindSize: identical(grindSize, _unset)
          ? this.grindSize
          : grindSize as String?,
      waterTemp: identical(waterTemp, _unset)
          ? this.waterTemp
          : waterTemp as double?,
      waterTempIsDerived: waterTempIsDerived ?? this.waterTempIsDerived,
      tdsPercent: identical(tdsPercent, _unset)
          ? this.tdsPercent
          : tdsPercent as double?,
      extractionYieldPercent: identical(extractionYieldPercent, _unset)
          ? this.extractionYieldPercent
          : extractionYieldPercent as double?,
      tasteBalance: identical(tasteBalance, _unset)
          ? this.tasteBalance
          : tasteBalance as int?,
      entrySource: identical(entrySource, _unset)
          ? this.entrySource
          : entrySource as int?,
      tags: identical(tags, _unset) ? this.tags : tags as String?,
      rating: identical(rating, _unset) ? this.rating : rating as double?,
      isMarked: isMarked ?? this.isMarked,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      coffeeBeansUuid: identical(coffeeBeansUuid, _unset)
          ? this.coffeeBeansUuid
          : coffeeBeansUuid as String?,
      beanName: identical(beanName, _unset)
          ? this.beanName
          : beanName as String?,
      roaster: identical(roaster, _unset) ? this.roaster : roaster as String?,
      origin: identical(origin, _unset) ? this.origin : origin as String?,
    );
  }

  /// The user-recorded water temperature only; null when the displayed
  /// [waterTemp] is derived from the recipe rather than actually stored on
  /// this entry.
  double? get storedWaterTemp => waterTempIsDerived ? null : waterTemp;

  /// Parsed, display-ready tags.
  List<String> get tagList => diaryTagsFromStorage(tags);

  /// Stable identity for bag-level diary comparisons.
  ///
  /// Legacy entries without a linked bag deliberately have no bag identity;
  /// display names must never be used as an identity fallback.
  String? get normalizedBagIdentity {
    final uuid = coffeeBeansUuid?.trim();
    return uuid == null || uuid.isEmpty ? null : uuid;
  }

  /// The water-to-coffee ratio, rounded to one decimal and without a trailing
  /// zero for whole-number ratios. A non-positive dose has no meaningful ratio.
  String? get ratio {
    if (coffeeAmount <= 0) return null;
    final value = waterAmount / coffeeAmount;
    final formatted = value.toStringAsFixed(1);
    return '1:${formatted.endsWith('.0') ? formatted.substring(0, formatted.length - 2) : formatted}';
  }
}
