import 'package:coffee_timer/database/database.dart';
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
    DateTime? lastModified = await _db.recipesDao.fetchLastModified();

    var request = Supabase.instance.client
        .from('recipes')
        .select('*, recipe_localization(*), steps(*)');

    if (lastModified != null) {
      final lastModifiedUtc = lastModified.toUtc();
      request = request.gt('last_modified', lastModifiedUtc.toIso8601String());
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
    final LaunchPopupResponse =
        await Supabase.instance.client.from('launch_popup').select();
    final contributorsResponse =
        await Supabase.instance.client.from('contributors').select();

    final coffeeFacts = coffeeFactsResponse
        .map((json) => CoffeeFactsCompanionExtension.fromJson(json))
        .toList();
    final launchPopups = LaunchPopupResponse.map(
        (json) => LaunchPopupsCompanionExtension.fromJson(json)).toList();
    final contributors = contributorsResponse
        .map((json) => ContributorsCompanionExtension.fromJson(json))
        .toList();

    await _db.transaction(() async {
      await _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.coffeeFacts, coffeeFacts);
        batch.insertAllOnConflictUpdate(_db.launchPopups, launchPopups);
        batch.insertAllOnConflictUpdate(_db.contributors, contributors);
      });
    });
  }

  // Inside DatabaseProvider
  Future<double> fetchGlobalBrewedCoffeeAmount(
      DateTime start, DateTime end) async {
    final startUtc = start.toUtc();
    final endUtc = end.toUtc();
    final response = await Supabase.instance.client
        .from('global_stats')
        .select('water_amount')
        .gte('created_at', startUtc.toIso8601String())
        .lte('created_at', endUtc.toIso8601String());
    final data = response as List<dynamic>;
    return data.fold<double>(
        0.0, (sum, element) => sum + element['water_amount'] / 1000);
  }

  Future<List<String>> fetchGlobalTopRecipes(
      DateTime start, DateTime end) async {
    final startUtc = start.toUtc();
    final endUtc = end.toUtc();
    final response = await Supabase.instance.client
        .from('global_stats')
        .select('recipe_id')
        .gte('created_at', startUtc.toIso8601String())
        .lte('created_at', endUtc.toIso8601String());

    // Aggregate counts of recipe_id
    final Map<String, int> recipeCounts = {};
    for (var entry in response) {
      final recipeId = entry['recipe_id'] as String;
      recipeCounts[recipeId] = (recipeCounts[recipeId] ?? 0) + 1;
    }

    // Sort and get top 3 recipe_ids based on usage count
    final sortedRecipes = recipeCounts.keys.toList()
      ..sort((a, b) => recipeCounts[b]!.compareTo(recipeCounts[a]!));
    return sortedRecipes.take(3).toList();
  }
}
