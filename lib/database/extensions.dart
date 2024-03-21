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
    );
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
}

extension VendorsCompanionExtension on VendorsCompanion {
  static VendorsCompanion fromJson(Map<String, dynamic> json) {
    return VendorsCompanion(
      vendorId:
          Value(json['vendor_id']), // Directly use the string value from JSON
      vendorName: Value(json['vendor_name']),
      vendorDescription: Value(json['vendor_description']),
      active: Value(json['active'] as bool), // Cast to bool as needed
    );
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

extension StartPopupsCompanionExtension on StartPopupsCompanion {
  static StartPopupsCompanion fromJson(Map<String, dynamic> json) {
    return StartPopupsCompanion(
      id: Value(json['id']),
      content: Value(json['content']),
      appVersion: Value(json['app_version']),
      locale: Value(json['locale']),
    );
  }
}