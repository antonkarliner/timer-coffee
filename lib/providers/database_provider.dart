import 'package:coffee_timer/database/database.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/database/extensions.dart'; // Make sure this import is correct

class DatabaseProvider {
  final AppDatabase _db;

  DatabaseProvider(this._db);

  Future<void> initializeDatabase() async {
    await _fetchAndStoreVendors();
    await _fetchAndStoreBrewingMethods();
    await _fetchAndStoreSupportedLocales();
    await _fetchAndStoreRecipes();
    await _fetchAndStoreRecipeLocalizations();
    await _fetchAndStoreSteps();
    await _fetchAndStoreCoffeeFacts();
    await _fetchAndStoreStartPopup();
    // Implement initialization for additional tables as needed
  }

  Future<void> _fetchAndStoreVendors() async {
    final response = await Supabase.instance.client.from('vendors').select();

    for (var json in response) {
      final vendor = VendorsCompanionExtension.fromJson(json);
      await _db
          .into(_db.vendors)
          .insert(vendor, mode: InsertMode.insertOrReplace);
    }
  }

  Future<void> _fetchAndStoreBrewingMethods() async {
    final response =
        await Supabase.instance.client.from('brewing_methods').select();
    for (var json in response) {
      final brewingMethod = BrewingMethodsCompanionExtension.fromJson(json);
      await _db
          .into(_db.brewingMethods)
          .insert(brewingMethod, mode: InsertMode.insertOrReplace);
    }
  }

  Future<void> _fetchAndStoreSupportedLocales() async {
    final response =
        await Supabase.instance.client.from('supported_locales').select();
    for (var json in response) {
      final supportedLocale = SupportedLocalesCompanionExtension.fromJson(json);
      await _db
          .into(_db.supportedLocales)
          .insert(supportedLocale, mode: InsertMode.insertOrReplace);
    }
  }

  Future<void> _fetchAndStoreRecipes() async {
    final client = Supabase.instance.client;
    final response = await client.from('recipes').select();

    final List<Map<String, dynamic>> recipes = response;
    for (var json in recipes) {
      final recipe = RecipesCompanionExtension.fromJson(json);
      await _db
          .into(_db.recipes)
          .insert(recipe, mode: InsertMode.insertOrReplace);
    }
  }

  Future<void> _fetchAndStoreRecipeLocalizations() async {
    final response =
        await Supabase.instance.client.from('recipe_localization').select();

    for (var json in response) {
      final localization = RecipeLocalizationsCompanionExtension.fromJson(json);
      await _db
          .into(_db.recipeLocalizations)
          .insert(localization, mode: InsertMode.insertOrReplace);
    }
  }

  Future<void> _fetchAndStoreSteps() async {
    final response = await Supabase.instance.client.from('steps').select();

    for (var json in response) {
      final step = StepsCompanionExtension.fromJson(json);
      await _db.into(_db.steps).insert(step, mode: InsertMode.insertOrReplace);
    }
  }

  Future<void> _fetchAndStoreCoffeeFacts() async {
    final response =
        await Supabase.instance.client.from('coffee_facts').select();

    for (var json in response) {
      final coffeeFact = CoffeeFactsCompanionExtension.fromJson(json);
      await _db
          .into(_db.coffeeFacts)
          .insert(coffeeFact, mode: InsertMode.insertOrReplace);
    }
  }

  Future<void> _fetchAndStoreStartPopup() async {
    final response =
        await Supabase.instance.client.from('start_popup').select();

    for (var json in response) {
      final startPopup = StartPopupsCompanionExtension.fromJson(json);
      await _db
          .into(_db.startPopups)
          .insert(startPopup, mode: InsertMode.insertOrReplace);
    }
  }
}
