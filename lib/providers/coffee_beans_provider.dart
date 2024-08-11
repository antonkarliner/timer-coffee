import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../models/coffee_beans_model.dart';
import 'database_provider.dart';

class CoffeeBeansProvider with ChangeNotifier {
  final AppDatabase db;
  final DatabaseProvider databaseProvider;
  final Uuid _uuid = Uuid();

  CoffeeBeansProvider(this.db, this.databaseProvider);

  Future<List<CoffeeBeansModel>> fetchAllCoffeeBeans() async {
    return await db.coffeeBeansDao.fetchAllCoffeeBeans();
  }

  Future<String> addCoffeeBeans(CoffeeBeansModel beans) async {
    final beansUuid = beans.beansUuid ??
        _uuid.v7(); // Use existing UUID or generate a new one
    await db.coffeeBeansDao.insertCoffeeBeans(CoffeeBeansCompanion(
      beansUuid: Value(beansUuid),
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
    return beansUuid;
  }

  Future<void> deleteCoffeeBeans(String uuid) async {
    await db.coffeeBeansDao.deleteCoffeeBeans(uuid);
    notifyListeners();
  }

  Future<void> updateCoffeeBeans(CoffeeBeansModel beans) async {
    await db.coffeeBeansDao.updateCoffeeBeans(CoffeeBeansCompanion(
      beansUuid: Value(beans.beansUuid),
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
    print('Fetched bean by ID: $beans');
    return beans;
  }

  Future<CoffeeBeansModel?> fetchCoffeeBeansByUuid(String uuid) async {
    final beans = await db.coffeeBeansDao.fetchCoffeeBeansByUuid(uuid);
    print('Fetched bean by UUID: $beans');
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

  Future<void> toggleFavoriteStatus(String uuid, bool isFavorite) async {
    await db.coffeeBeansDao.updateFavoriteStatus(uuid, isFavorite);
    notifyListeners();
  }

  Future<void> backfillMissingUuids() async {
    final beansToUpdate = await db.coffeeBeansDao.fetchBeansNeedingUpdate();

    if (beansToUpdate.isEmpty) {
      print('No coffee beans need updating.');
      return;
    }
    Set<String> generatedUuids = {};
    List<CoffeeBeansCompanion> updates = [];

    for (final bean in beansToUpdate) {
      String newUuid;
      do {
        newUuid = _uuid.v7();
      } while (generatedUuids.contains(newUuid));
      generatedUuids.add(newUuid);

      updates.add(CoffeeBeansCompanion(
        id: Value(bean.id),
        beansUuid: Value(bean.beansUuid ?? newUuid),
      ));
    }

    await db.coffeeBeansDao.batchUpdateMissingUuidsAndTimestamps(updates);

    print('Updated ${beansToUpdate.length} coffee bean entries.');
    notifyListeners();
  }
}
