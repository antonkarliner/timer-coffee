import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import '../database/database.dart';
import '../models/coffee_beans_model.dart';
import 'database_provider.dart';

class CoffeeBeansProvider with ChangeNotifier {
  final AppDatabase db;
  final DatabaseProvider databaseProvider;

  CoffeeBeansProvider(this.db, this.databaseProvider);

  Future<List<CoffeeBeansModel>> fetchAllCoffeeBeans() async {
    return await db.coffeeBeansDao.fetchAllCoffeeBeans();
  }

  Future<void> addCoffeeBeans(CoffeeBeansModel beans) async {
    await db.coffeeBeansDao.insertCoffeeBeans(CoffeeBeansCompanion(
      roaster: Value(beans.roaster),
      name: Value(beans.name),
      origin: Value(beans.origin),
      variety: Value(beans.variety),
      tastingNotes: Value(beans.tastingNotes ?? ''),
      processingMethod: Value(beans.processingMethod),
      elevation: Value(beans.elevation),
      harvestDate: Value(beans.harvestDate),
      roastDate: Value(beans.roastDate),
      region: Value(beans.region),
      roastLevel: Value(beans.roastLevel),
      cuppingScore: Value(beans.cuppingScore),
      notes: Value(beans.notes),
      isFavorite: Value(beans.isFavorite),
    ));
    notifyListeners();
  }

  Future<void> deleteCoffeeBeans(int id) async {
    await db.coffeeBeansDao.deleteCoffeeBeans(id);
    notifyListeners();
  }

  Future<void> updateCoffeeBeans(CoffeeBeansModel beans) async {
    await db.coffeeBeansDao.updateCoffeeBeans(CoffeeBeansCompanion(
      id: Value(beans.id),
      roaster: Value(beans.roaster),
      name: Value(beans.name),
      origin: Value(beans.origin),
      variety: Value(beans.variety),
      tastingNotes: Value(beans.tastingNotes ?? ''),
      processingMethod: Value(beans.processingMethod),
      elevation: Value(beans.elevation),
      harvestDate: Value(beans.harvestDate),
      roastDate: Value(beans.roastDate),
      region: Value(beans.region),
      roastLevel: Value(beans.roastLevel),
      cuppingScore: Value(beans.cuppingScore),
      notes: Value(beans.notes),
      isFavorite: Value(beans.isFavorite),
    ));
    notifyListeners();
  }

  Future<CoffeeBeansModel?> fetchCoffeeBeansById(int id) async {
    final beans = await db.coffeeBeansDao.fetchCoffeeBeansById(id);
    print('Fetched bean: $beans');
    return beans;
  }

  Future<List<String>> fetchAllDistinctRoasters() async {
    return await db.coffeeBeansDao.fetchAllDistinctRoasters();
  }

  Future<List<String>> fetchAllDistinctNames() async {
    return await db.coffeeBeansDao.fetchAllDistinctNames();
  }

  Future<List<String>> fetchAllDistinctVarieties() async {
    return await db.coffeeBeansDao.fetchAllDistinctVarieties();
  }

  Future<List<String>> fetchAllDistinctProcessingMethods() async {
    return await db.coffeeBeansDao.fetchAllDistinctProcessingMethods();
  }

  Future<List<String>> fetchAllDistinctRoastLevels() async {
    return await db.coffeeBeansDao.fetchAllDistinctRoastLevels();
  }

  Future<List<String>> fetchAllDistinctOrigins() async {
    return await db.coffeeBeansDao.fetchAllDistinctOrigins();
  }

  Future<List<String>> fetchAllDistinctTastingNotes() async {
    return await db.coffeeBeansDao.fetchAllDistinctTastingNotes();
  }

  Future<List<String>> fetchAllDistinctRegions() async {
    return await db.coffeeBeansDao.fetchAllDistinctRegions();
  }

  Future<List<String>> fetchCombinedTastingNotes(String locale) async {
    final localTastingNotes = await fetchAllDistinctTastingNotes();
    List<String> supabaseTastingNotes = [];

    try {
      supabaseTastingNotes =
          await databaseProvider.fetchTastingNotesForLocale(locale);
    } catch (error) {
      //print('Error fetching tasting notes from Supabase: $error');
    }

    final combinedSet = {...localTastingNotes, ...supabaseTastingNotes};
    return combinedSet.toList();
  }

  Future<List<String>> fetchCombinedOrigins(String locale) async {
    final localOrigins = await fetchAllDistinctOrigins();
    List<String> supabaseOrigins = [];

    try {
      supabaseOrigins = await databaseProvider.fetchCountriesForLocale(locale);
    } catch (error) {
      //print('Error fetching origins from Supabase: $error');
    }

    final combinedSet = {...localOrigins, ...supabaseOrigins};
    return combinedSet.toList();
  }

  Future<List<String>> fetchCombinedProcessingMethods(String locale) async {
    final localProcessingMethods = await fetchAllDistinctProcessingMethods();
    List<String> supabaseProcessingMethods = [];

    try {
      supabaseProcessingMethods =
          await databaseProvider.fetchProcessingMethodsForLocale(locale);
    } catch (error) {
      // print('Error fetching processing methods from Supabase: $error');
    }

    final combinedSet = {
      ...localProcessingMethods,
      ...supabaseProcessingMethods
    };
    return combinedSet.toList();
  }

  Future<List<String>> fetchCombinedRoasters() async {
    final localRoasters = await fetchAllDistinctRoasters();
    List<String> supabaseRoasters = [];

    try {
      supabaseRoasters = await databaseProvider.fetchRoasters();
    } catch (error) {
      //print('Error fetching roasters from Supabase: $error');
    }

    final combinedSet = {...localRoasters, ...supabaseRoasters};
    return combinedSet.toList();
  }

  Future<void> toggleFavoriteStatus(int id, bool isFavorite) async {
    final updatedFavoriteStatus = !isFavorite;
    await db.coffeeBeansDao.updateFavoriteStatus(id, updatedFavoriteStatus);
    notifyListeners();
  }
}
