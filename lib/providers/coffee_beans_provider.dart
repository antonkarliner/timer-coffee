import 'package:coffee_timer/utils/version_vector.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../models/coffee_beans_model.dart';
import 'database_provider.dart';

class CoffeeBeansProvider with ChangeNotifier {
  final AppDatabase db;
  final DatabaseProvider databaseProvider;
  final Uuid _uuid = Uuid();
  final String deviceId;

  CoffeeBeansProvider(this.db, this.databaseProvider) : deviceId = Uuid().v4();

  Future<List<CoffeeBeansModel>> fetchAllCoffeeBeans() async {
    return await db.coffeeBeansDao.fetchAllCoffeeBeans();
  }

  Future<String> addCoffeeBeans(CoffeeBeansModel beans) async {
    final beansUuid = beans.beansUuid ?? _uuid.v7();
    final versionVector = VersionVector.initial(deviceId).toString();

    final newBeans = beans.copyWith(
      beansUuid: beansUuid,
      versionVector: versionVector,
    );

    await db.coffeeBeansDao.insertCoffeeBeans(newBeans);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final supabaseData = _coffeeBeansModelToJson(newBeans);
        supabaseData['user_id'] = user.id;
        await Supabase.instance.client
            .from('user_coffee_beans')
            .upsert(supabaseData);
      } catch (e) {
        print('Error syncing new coffee beans to Supabase: $e');
        // TODO: Implement error handling or retry logic
      }
    }

    notifyListeners();
    return beansUuid;
  }

  Future<void> updateCoffeeBeans(CoffeeBeansModel beans) async {
    final currentBeans =
        await db.coffeeBeansDao.fetchCoffeeBeansByUuid(beans.beansUuid);
    if (currentBeans == null) {
      throw Exception('Coffee beans not found');
    }

    final currentVector = VersionVector.fromString(currentBeans.versionVector);
    final newVector = currentVector.increment();

    final updatedBeans = beans.copyWith(
      versionVector: newVector.toString(),
    );

    await db.coffeeBeansDao.updateCoffeeBeans(updatedBeans);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final supabaseData = _coffeeBeansModelToJson(updatedBeans);
        supabaseData['user_id'] = user.id;
        await Supabase.instance.client
            .from('user_coffee_beans')
            .upsert(supabaseData, onConflict: 'user_id,beans_uuid');
      } catch (e) {
        print('Error syncing updated coffee beans to Supabase: $e');
        // TODO: Implement error handling or retry logic
      }
    }

    notifyListeners();
  }

  Future<void> deleteCoffeeBeans(String uuid) async {
    await db.coffeeBeansDao.deleteCoffeeBeans(uuid);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        await Supabase.instance.client
            .from('user_coffee_beans')
            .delete()
            .eq('user_id', user.id)
            .eq('beans_uuid', uuid);
      } catch (e) {
        print('Error deleting coffee beans from Supabase: $e');
      }
    }

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

  Future<void> batchUploadCoffeeBeans() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      print('No user logged in or user is anonymous');
      return;
    }

    final localBeans = await fetchAllCoffeeBeans();

    final beansData = localBeans
        .map((bean) => _coffeeBeansModelToJson(bean)..['user_id'] = user.id)
        .toList();

    final batchSize = 50;

    for (var i = 0; i < beansData.length; i += batchSize) {
      final batch = beansData.skip(i).take(batchSize).toList();

      try {
        await Supabase.instance.client.from('user_coffee_beans').upsert(batch);
        print('Uploaded batch ${i ~/ batchSize + 1}');
      } catch (e) {
        print('Error uploading batch ${i ~/ batchSize + 1}: $e');
      }
    }

    print('Successfully uploaded ${beansData.length} coffee beans');
  }

  Future<void> batchDownloadCoffeeBeans() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      print('No user logged in or user is anonymous');
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('user_coffee_beans')
          .select()
          .eq('user_id', user.id);

      final remoteBeans = (response as List<dynamic>)
          .map((json) => _jsonToCoffeeBeansModel(json))
          .toList();

      await db.coffeeBeansDao.insertOrUpdateMultipleCoffeeBeans(remoteBeans);
      print('Downloaded and updated ${remoteBeans.length} coffee beans');
    } catch (e) {
      print('Error downloading coffee beans: $e');
    }
  }

  Future<void> syncCoffeeBeans() async {
    await batchUploadCoffeeBeans();
    await batchDownloadCoffeeBeans();
    notifyListeners();
  }

  Future<void> syncNewCoffeeBeans() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      print('No user logged in or user is anonymous');
      return;
    }

    try {
      final localBeans = await fetchAllCoffeeBeans();

      final response = await Supabase.instance.client
          .from('user_coffee_beans')
          .select()
          .eq('user_id', user.id);
      final remoteBeans = (response as List<dynamic>)
          .map((json) => _jsonToCoffeeBeansModel(json))
          .toList();

      final List<CoffeeBeansModel> localUpdates = [];
      final List<Map<String, dynamic>> remoteUpdates = [];

      for (final localBean in localBeans) {
        final remoteBean = remoteBeans.firstWhereOrNull(
          (rb) => rb.beansUuid == localBean.beansUuid,
        );

        if (remoteBean == null) {
          remoteUpdates
              .add(_coffeeBeansModelToJson(localBean)..['user_id'] = user.id);
        } else {
          final localVector = VersionVector.fromString(localBean.versionVector);
          final remoteVector =
              VersionVector.fromString(remoteBean.versionVector);

          if (localVector.version > remoteVector.version) {
            remoteUpdates
                .add(_coffeeBeansModelToJson(localBean)..['user_id'] = user.id);
          } else if (localVector.version < remoteVector.version) {
            localUpdates.add(remoteBean);
          }
        }
      }

      for (final remoteBean in remoteBeans) {
        if (!localBeans.any((lb) => lb.beansUuid == remoteBean.beansUuid)) {
          localUpdates.add(remoteBean);
        }
      }

      if (localUpdates.isNotEmpty) {
        await db.coffeeBeansDao.insertOrUpdateMultipleCoffeeBeans(localUpdates);
      }

      if (remoteUpdates.isNotEmpty) {
        await Supabase.instance.client
            .from('user_coffee_beans')
            .upsert(remoteUpdates);
      }

      print(
          'Sync completed. Local updates: ${localUpdates.length}, Remote updates: ${remoteUpdates.length}');
    } catch (e) {
      print('Error syncing coffee beans: $e');
    }

    notifyListeners();
  }

  // Helper method to convert CoffeeBeansModel to JSON
  Map<String, dynamic> _coffeeBeansModelToJson(CoffeeBeansModel model) {
    return {
      'beans_uuid': model.beansUuid,
      'roaster': model.roaster,
      'name': model.name,
      'origin': model.origin,
      'variety': model.variety,
      'tasting_notes': model.tastingNotes,
      'processing_method': model.processingMethod,
      'elevation': model.elevation,
      'harvest_date': model.harvestDate?.toUtc().toIso8601String(),
      'roast_date': model.roastDate?.toUtc().toIso8601String(),
      'region': model.region,
      'roast_level': model.roastLevel,
      'cupping_score': model.cuppingScore,
      'notes': model.notes,
      'is_favorite': model.isFavorite,
      'version_vector': model.versionVector,
    };
  }

  // Helper method to convert JSON to CoffeeBeansModel
  CoffeeBeansModel _jsonToCoffeeBeansModel(Map<String, dynamic> json) {
    return CoffeeBeansModel(
      beansUuid: json['beans_uuid'],
      roaster: json['roaster'],
      name: json['name'],
      origin: json['origin'],
      variety: json['variety'],
      tastingNotes: json['tasting_notes'],
      processingMethod: json['processing_method'],
      elevation: json['elevation'],
      harvestDate: json['harvest_date'] != null
          ? DateTime.parse(json['harvest_date'])
          : null,
      roastDate: json['roast_date'] != null
          ? DateTime.parse(json['roast_date'])
          : null,
      region: json['region'],
      roastLevel: json['roast_level'],
      cuppingScore: json['cupping_score'],
      notes: json['notes'],
      isFavorite: json['is_favorite'],
      versionVector: json['version_vector'],
    );
  }
}
