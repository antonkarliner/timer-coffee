// lib/database/extensions.dart
import 'package:coffee_timer/database/database.dart';
import 'package:drift/drift.dart';

extension RecipesCompanionExtension on RecipesCompanion {
  static RecipesCompanion fromJson(Map<String, dynamic> json) {
    return RecipesCompanion(
      id: Value(json['id']),
      brewingMethodId: Value(json['brewing_method_id']),
      coffeeAmount:
          Value((json['coffee_amount'] as num).toDouble()), // Cast to double
      waterAmount:
          Value((json['water_amount'] as num).toDouble()), // Cast to double
      waterTemp:
          Value((json['water_temp'] as num).toDouble()), // Cast to double
      brewTime: Value(json['brew_time']),
      vendorId: Value(json['vendor_id']),
      lastModified: json['last_modified'] != null
          ? Value(DateTime.parse(json['last_modified']))
          : const Value.absent(),
      importId: json['import_id'] != null
          ? Value(json['import_id'])
          : const Value.absent(),
      isImported: Value(json['is_imported'] ?? false),
    );
  }

  static RecipesCompanion fromUserRecipeJson(Map<String, dynamic> json) {
    return RecipesCompanion(
      id: Value(json['id']),
      brewingMethodId: Value(json['brewing_method_id']),
      coffeeAmount: Value((json['coffee_amount'] as num).toDouble()),
      waterAmount: Value((json['water_amount'] as num).toDouble()),
      waterTemp: Value((json['water_temp'] as num).toDouble()),
      brewTime: Value(json['brew_time']),
      vendorId: Value(json['vendor_id']),
      lastModified: json['last_modified'] != null
          ? Value(DateTime.parse(json['last_modified']))
          : const Value.absent(),
      importId: json['import_id'] != null
          ? Value(json['import_id'])
          : const Value.absent(),
      isImported: Value(json['is_imported'] ?? false),
    );
  }

  Map<String, dynamic> toUserRecipeJson(String userId) {
    return {
      'id': id.value,
      'brewing_method_id': brewingMethodId.value,
      'coffee_amount': coffeeAmount.value,
      'water_amount': waterAmount.value,
      'water_temp': waterTemp.value,
      'brew_time': brewTime.value,
      'vendor_id': userId,
      'last_modified': lastModified.value?.toUtc().toIso8601String(),
      'import_id': importId.present ? importId.value : null,
      'is_imported': isImported.present ? isImported.value : false,
      'ispublic': false, // Default to private
    };
  }
}

extension RecipeLocalizationsCompanionExtension
    on RecipeLocalizationsCompanion {
  static RecipeLocalizationsCompanion fromJson(Map<String, dynamic> json) {
    return RecipeLocalizationsCompanion(
      id: Value(json['id']),
      recipeId: Value(json['recipe_id']),
      locale: Value(json['locale']),
      name: Value(json['name']),
      grindSize: Value(json['grind_size']),
      shortDescription: Value(json['short_description']),
    );
  }

  static RecipeLocalizationsCompanion fromUserRecipeLocalizationJson(
      Map<String, dynamic> json) {
    return RecipeLocalizationsCompanion(
      id: Value(json['id']),
      recipeId: Value(json['recipe_id']),
      locale: Value(json['locale']),
      name: Value(json['name']),
      grindSize: Value(json['grind_size']),
      shortDescription: Value(json['short_description']),
    );
  }

  Map<String, dynamic> toUserRecipeLocalizationJson() {
    return {
      'id': id.value,
      'recipe_id': recipeId.value,
      'locale': locale.value,
      'name': name.value,
      'grind_size': grindSize.value,
      'short_description': shortDescription.value,
    };
  }
}

extension StepsCompanionExtension on StepsCompanion {
  static StepsCompanion fromJson(Map<String, dynamic> json) {
    return StepsCompanion(
      id: Value(json['id']),
      recipeId: Value(json['recipe_id']),
      stepOrder: Value(json['step_order']),
      description: Value(json['description']),
      time: Value(json['time']),
      locale: Value(json['locale']), // Ensure handling of 'locale' column
    );
  }

  static StepsCompanion fromUserStepJson(Map<String, dynamic> json) {
    return StepsCompanion(
      id: Value(json['id']),
      recipeId: Value(json['recipe_id']),
      stepOrder: Value(json['step_order']),
      description: Value(json['description']),
      time: Value(json['time']),
      locale: Value(json['locale']),
    );
  }

  Map<String, dynamic> toUserStepJson() {
    return {
      'id': id.value,
      'recipe_id': recipeId.value,
      'step_order': stepOrder.value,
      'description': description.value,
      'time': time.value,
      'locale': locale.value,
    };
  }
}

extension SupportedLocalesCompanionExtension on SupportedLocalesCompanion {
  static SupportedLocalesCompanion fromJson(Map<String, dynamic> json) {
    return SupportedLocalesCompanion(
      locale: Value(json['locale']),
      localeName: Value(json['locale_name']),
    );
  }
}

extension BrewingMethodsCompanionExtension on BrewingMethodsCompanion {
  static BrewingMethodsCompanion fromJson(Map<String, dynamic> json) {
    return BrewingMethodsCompanion(
      brewingMethodId: Value(json['brewing_method_id']),
      brewingMethod: Value(json['brewing_method']),
      showOnMain: Value(
          json['show_on_main'] ?? false), // Add default value as false if null
    );
  }
}

extension CoffeeFactsCompanionExtension on CoffeeFactsCompanion {
  static CoffeeFactsCompanion fromJson(Map<String, dynamic> json) {
    return CoffeeFactsCompanion(
      id: Value(json['id']),
      fact: Value(json['fact']),
      locale: Value(json['locale']),
    );
  }
}

extension LaunchPopupsCompanionExtension on LaunchPopupsCompanion {
  static LaunchPopupsCompanion fromJson(Map<String, dynamic> json) {
    return LaunchPopupsCompanion(
      id: Value(json['id']),
      content: Value(json['content']),
      locale: Value(json['locale']),
      createdAt: json['created_at'] != null
          ? Value(DateTime.parse(json['created_at']))
          : const Value.absent(),
    );
  }
}

extension ContributorsCompanionExtension on ContributorsCompanion {
  static ContributorsCompanion fromJson(Map<String, dynamic> json) {
    return ContributorsCompanion(
      id: Value(json['id']),
      content: Value(json['content']),
      locale: Value(json['locale']),
    );
  }
}

extension UserRecipePreferencesCompanionExtension
    on UserRecipePreferencesCompanion {
  static UserRecipePreferencesCompanion fromJson(Map<String, dynamic> json) {
    return UserRecipePreferencesCompanion(
      recipeId: Value(json['recipe_id']),
      lastUsed: json['last_used'] != null
          ? Value(DateTime.parse(json['last_used']))
          : const Value.absent(),
      isFavorite: Value(json['is_favorite'] ?? false),
      sweetnessSliderPosition: json['sweetness_slider_position'] != null
          ? Value(json['sweetness_slider_position'] as int)
          : const Value.absent(),
      strengthSliderPosition: json['strength_slider_position'] != null
          ? Value(json['strength_slider_position'] as int)
          : const Value.absent(),
      coffeeChroniclerSliderPosition:
          json['coffee_chronicler_slider_position'] != null
              ? Value(json['coffee_chronicler_slider_position'] as int)
              : const Value.absent(),
      customCoffeeAmount: json['custom_coffee_amount'] != null
          ? Value(_parseDouble(json['custom_coffee_amount']))
          : const Value.absent(),
      customWaterAmount: json['custom_water_amount'] != null
          ? Value(_parseDouble(json['custom_water_amount']))
          : const Value.absent(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.parse(value);
    }
    throw FormatException('Unable to parse $value to double');
  }
}

extension UserStatsCompanionExtension on UserStatsCompanion {
  static UserStatsCompanion fromJson(Map<String, dynamic> json) {
    return UserStatsCompanion(
      statUuid: Value(json['stat_uuid']),
      id: json['id'] != null ? Value(json['id'] as int) : const Value.absent(),
      recipeId: Value(json['recipe_id']),
      coffeeAmount: json['coffee_amount'] != null
          ? Value((json['coffee_amount'] as num).toDouble())
          : const Value.absent(),
      waterAmount: json['water_amount'] != null
          ? Value((json['water_amount'] as num).toDouble())
          : const Value.absent(),
      sweetnessSliderPosition: json['sweetness_slider_position'] != null
          ? Value(json['sweetness_slider_position'] as int)
          : const Value.absent(),
      strengthSliderPosition: json['strength_slider_position'] != null
          ? Value(json['strength_slider_position'] as int)
          : const Value.absent(),
      brewingMethodId: Value(json['brewing_method_id']),
      createdAt: json['created_at'] != null
          ? Value(DateTime.parse(json['created_at']))
          : const Value.absent(),
      notes: Value(json['notes']),
      beans: Value(json['beans']),
      roaster: Value(json['roaster']),
      rating: json['rating'] != null
          ? Value((json['rating'] as num).toDouble())
          : const Value.absent(),
      coffeeBeansId: json['coffee_beans_id'] != null
          ? Value(json['coffee_beans_id'] as int)
          : const Value.absent(),
      isMarked: json['is_marked'] != null
          ? Value(json['is_marked'] as bool)
          : const Value.absent(),
      coffeeBeansUuid: Value(json['coffee_beans_uuid']),
      versionVector: Value(json['version_vector']),
      isDeleted: json['is_deleted'] != null
          ? Value(json['is_deleted'] as bool)
          : const Value.absent(), // Added isDeleted field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stat_uuid': statUuid.value,
      'id': id.present ? id.value : null,
      'recipe_id': recipeId.value,
      'coffee_amount': coffeeAmount.value,
      'water_amount': waterAmount.value,
      'sweetness_slider_position': sweetnessSliderPosition.value,
      'strength_slider_position': strengthSliderPosition.value,
      'brewing_method_id': brewingMethodId.value,
      'created_at': createdAt.value.toIso8601String(),
      'notes': notes.value,
      'beans': beans.value,
      'roaster': roaster.value,
      'rating': rating.value,
      'coffee_beans_id': coffeeBeansId.value,
      'is_marked': isMarked.value,
      'coffee_beans_uuid': coffeeBeansUuid.value,
      'version_vector': versionVector.value,
      'is_deleted': isDeleted.value, // Added isDeleted field
    };
  }
}

extension CoffeeBeansCompanionExtension on CoffeeBeansCompanion {
  static CoffeeBeansCompanion fromJson(Map<String, dynamic> json) {
    return CoffeeBeansCompanion(
      beansUuid: Value(json['beans_uuid']),
      id: json['id'] != null ? Value(json['id'] as int) : const Value.absent(),
      roaster: Value(json['roaster']),
      name: Value(json['name']),
      origin: Value(json['origin']),
      variety: Value(json['variety']),
      tastingNotes: Value(json['tasting_notes']),
      processingMethod: Value(json['processing_method']),
      elevation: json['elevation'] != null
          ? Value(json['elevation'] as int)
          : const Value.absent(),
      harvestDate: json['harvest_date'] != null
          ? Value(DateTime.parse(json['harvest_date']))
          : const Value.absent(),
      roastDate: json['roast_date'] != null
          ? Value(DateTime.parse(json['roast_date']))
          : const Value.absent(),
      region: Value(json['region']),
      roastLevel: Value(json['roast_level']),
      cuppingScore: json['cupping_score'] != null
          ? Value((json['cupping_score'] as num).toDouble())
          : const Value.absent(),
      notes: Value(json['notes']),
      isFavorite: json['is_favorite'] != null
          ? Value(json['is_favorite'] as bool)
          : const Value.absent(),
      isDeleted: Value(json['is_deleted'] != null &&
          json['is_deleted'] == true), // Include isDeleted
      versionVector: Value(json['version_vector']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'beans_uuid': beansUuid.value,
      'id': id.present ? id.value : null,
      'roaster': roaster.value,
      'name': name.value,
      'origin': origin.value,
      'variety': variety.value,
      'tasting_notes': tastingNotes.value,
      'processing_method': processingMethod.value,
      'elevation': elevation.present ? elevation.value : null,
      'harvest_date':
          harvestDate.present ? harvestDate.value?.toIso8601String() : null,
      'roast_date':
          roastDate.present ? roastDate.value?.toIso8601String() : null,
      'region': region.value,
      'roast_level': roastLevel.value,
      'cupping_score': cuppingScore.present ? cuppingScore.value : null,
      'notes': notes.value,
      'is_favorite': isFavorite.present ? isFavorite.value : null,
      'is_deleted':
          isDeleted.present ? isDeleted.value : null, // Include isDeleted
      'version_vector': versionVector.value,
    };
  }
}
