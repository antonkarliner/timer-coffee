import 'package:coffee_timer/database/database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/database/extensions.dart';
import 'package:diacritic/diacritic.dart';

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

  Future<List<String>> fetchCountriesForLocale(String locale) async {
    try {
      final response = await Supabase.instance.client
          .from('coffee_countries')
          .select('country_name')
          .eq('locale', locale);
      final data = response as List<dynamic>;
      return data.map((e) => e['country_name'] as String).toList();
    } catch (error) {
      // If an error occurs, log it and return an empty list
      print('Error fetching countries: $error');
      return [];
    }
  }

  Future<List<String>> fetchTastingNotesForLocale(String locale) async {
    try {
      final response = await Supabase.instance.client
          .from('coffee_descriptors')
          .select('descriptor_name')
          .eq('locale', locale);
      final data = response as List<dynamic>;
      return data.map((e) => e['descriptor_name'] as String).toList();
    } catch (error) {
      // If an error occurs, log it and return an empty list
      print('Error fetching tasting notes: $error');
      return [];
    }
  }

  Future<List<String>> fetchProcessingMethodsForLocale(String locale) async {
    try {
      final response = await Supabase.instance.client
          .from('coffee_processing_methods')
          .select('method_name')
          .eq('locale', locale);
      final data = response as List<dynamic>;
      return data.map((e) => e['method_name'] as String).toList();
    } catch (error) {
      print('Error fetching processing methods: $error');
      return [];
    }
  }

  Future<List<String>> fetchRoasters() async {
    try {
      final response = await Supabase.instance.client
          .from('coffee_roasters')
          .select('roaster_name');
      final data = response as List<dynamic>;
      return data.map((e) => e['roaster_name'] as String).toList();
    } catch (error) {
      print('Error fetching roasters: $error');
      return [];
    }
  }

  Future<String?> fetchRoasterLogoUrl(String roasterName) async {
    try {
      // Normalize the input roaster name
      final normalizedRoasterName = removeDiacritics(roasterName).toLowerCase();

      // Fetch all roasters, their logos, and aliases
      final response = await Supabase.instance.client
          .from('coffee_roasters')
          .select('roaster_name, roaster_logo_url, aliases');

      for (var roaster in response) {
        final dbRoasterName =
            removeDiacritics(roaster['roaster_name']).toLowerCase();

        // Check if the roaster name matches
        if (dbRoasterName == normalizedRoasterName) {
          return roaster['roaster_logo_url'] as String?;
        }

        // Check aliases if present
        final aliases = roaster['aliases'] as String?;
        if (aliases != null) {
          final aliasList = aliases
              .split(',')
              .map((alias) => removeDiacritics(alias.trim()).toLowerCase())
              .toList();
          if (aliasList.contains(normalizedRoasterName)) {
            return roaster['roaster_logo_url'] as String?;
          }
        }
      }

      print('No matching data found for roaster: $roasterName');
      return null;
    } catch (error) {
      print('Exception fetching roaster logo URL: $error');
      return null;
    }
  }
}
