import 'package:coffee_timer/database/database.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/database/extensions.dart';

class DatabaseProvider {
  final AppDatabase _db;

  DatabaseProvider(this._db);

  Future<void> initializeDatabase() async {
    try {
      await _fetchAndStoreReferenceData();
      await Future.wait([
        _fetchAndStoreRecipes(),
        _fetchAndStoreExtraData(),
      ]);
    } catch (error) {
      // Handle the error here
    }
  }

  Future<void> _fetchAndStoreReferenceData() async {
    final vendorsResponse =
        await Supabase.instance.client.from('vendors').select();
    final brewingMethodsResponse =
        await Supabase.instance.client.from('brewing_methods').select();
    final supportedLocalesResponse =
        await Supabase.instance.client.from('supported_locales').select();

    final vendors = vendorsResponse
        .map((json) => VendorsCompanionExtension.fromJson(json))
        .toList();
    final brewingMethods = brewingMethodsResponse
        .map((json) => BrewingMethodsCompanionExtension.fromJson(json))
        .toList();
    final supportedLocales = supportedLocalesResponse
        .map((json) => SupportedLocalesCompanionExtension.fromJson(json))
        .toList();

    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.vendors, vendors);
        batch.insertAllOnConflictUpdate(_db.brewingMethods, brewingMethods);
        batch.insertAllOnConflictUpdate(_db.supportedLocales, supportedLocales);
      });
    });
  }

  Future<void> _fetchAndStoreRecipes() async {
    final lastModified = await _db.recipesDao.fetchLastModified();
    var request = Supabase.instance.client
        .from('recipes')
        .select('*, recipe_localization(*), steps(*)');
    if (lastModified != null) {
      request = request.gt('last_modified', lastModified);
    }
    final response = await request;

    final recipes = response
        .map((json) => RecipesCompanionExtension.fromJson(json))
        .toList();

    // Extract and store localizations
    final localizationsJson =
        response.expand((json) => json['recipe_localization']).toList();
    final localizations = localizationsJson
        .map((json) => RecipeLocalizationsCompanionExtension.fromJson(json))
        .toList();

    // Extract and store steps
    final stepsJson = response.expand((json) => json['steps']).toList();
    final steps = stepsJson
        .map((json) => StepsCompanionExtension.fromJson(json))
        .toList();

    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.recipes, recipes);
        batch.insertAllOnConflictUpdate(_db.recipeLocalizations, localizations);
        batch.insertAllOnConflictUpdate(_db.steps, steps);
      });
    });
  }

  Future<void> _fetchAndStoreExtraData() async {
    final coffeeFactsResponse =
        await Supabase.instance.client.from('coffee_facts').select();
    final startPopupResponse =
        await Supabase.instance.client.from('start_popup').select();

    final coffeeFacts = coffeeFactsResponse
        .map((json) => CoffeeFactsCompanionExtension.fromJson(json))
        .toList();
    final startPopups = startPopupResponse
        .map((json) => StartPopupsCompanionExtension.fromJson(json))
        .toList();

    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.coffeeFacts, coffeeFacts);
        batch.insertAllOnConflictUpdate(_db.startPopups, startPopups);
      });
    });
  }
}
