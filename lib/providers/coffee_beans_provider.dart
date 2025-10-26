import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:coffee_timer/utils/version_vector.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart';
import '../models/coffee_beans_model.dart';
import '../utils/app_logger.dart';
import 'database_provider.dart';

// Cache configuration
class CacheConfig {
  static const Duration defaultExpiration = Duration(hours: 24);
  static const Duration maxAge =
      Duration(days: 5); // Updated to 5 days as requested
  static const int maxCacheEntries = 50; // Prevent memory bloat
}

// Cache entry structure
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration expiration;
  final String? appVersion;

  CacheEntry(this.data, this.expiration, {this.appVersion})
      : timestamp = DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp) > expiration;
  bool get isTooOld =>
      DateTime.now().difference(timestamp) > CacheConfig.maxAge;
}

class CoffeeBeansProvider with ChangeNotifier {
  final AppDatabase db;
  final DatabaseProvider databaseProvider;
  final Uuid _uuid = Uuid();
  final String deviceId;
  static String? _currentAppVersion;

  // Cache storage for API data
  final Map<String, CacheEntry<List<String>>> _cache = {};

  CoffeeBeansProvider(this.db, this.databaseProvider) : deviceId = Uuid().v4() {
    // Initialize app version asynchronously
    _initializeAppVersion().catchError((e) {
      AppLogger.error('Failed to initialize app version', errorObject: e);
    });
  }

  // Initialize app version and clear cache if needed
  Future<void> _initializeAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final newVersion = packageInfo.version;

      if (_currentAppVersion != null && _currentAppVersion != newVersion) {
        AppLogger.debug(
            'App version changed from $_currentAppVersion to $newVersion - clearing cache');
        clearCache();
      }

      _currentAppVersion = newVersion;
      AppLogger.debug('App version initialized: $_currentAppVersion');
    } catch (e) {
      AppLogger.error('Error getting app version', errorObject: e);
    }
  }

  // Helper method to generate cache keys
  String _getCacheKey(String dataType, String locale,
      {bool isLocaleAgnostic = false}) {
    if (isLocaleAgnostic) {
      return dataType; // No locale suffix for locale-agnostic data
    }
    return "${dataType}_${locale}";
  }

  // Helper method to get cached data or fetch if needed
  Future<List<String>> _getCachedOrFetch(
    String cacheKey,
    String locale,
    Future<List<String>> Function() fetchFunction,
  ) async {
    // Ensure app version is initialized
    if (_currentAppVersion == null) {
      await _initializeAppVersion();
    }

    final cacheEntry = _cache[cacheKey];

    // Return cached data if it's still valid
    if (cacheEntry != null && !cacheEntry.isExpired) {
      AppLogger.debug(
          'CACHE HIT for $cacheKey (age: ${DateTime.now().difference(cacheEntry.timestamp).inMinutes}min, items: ${cacheEntry.data.length})');
      return cacheEntry.data;
    }

    // If data is too old, we must fetch even if API might fail
    final mustFetch = cacheEntry?.isTooOld ?? false;
    if (cacheEntry != null) {
      AppLogger.debug(
          'CACHE EXPIRED for $cacheKey (age: ${DateTime.now().difference(cacheEntry.timestamp).inMinutes}min, expired: ${cacheEntry.isExpired}, too old: ${cacheEntry.isTooOld})');
    } else {
      AppLogger.debug('CACHE MISS for $cacheKey - no cached data found');
    }

    try {
      AppLogger.debug(
          'FETCHING from API for $cacheKey (must fetch: $mustFetch)');
      final stopwatch = Stopwatch()..start();
      final data = await fetchFunction();
      stopwatch.stop();

      AppLogger.debug(
          'API FETCH COMPLETED for $cacheKey in ${stopwatch.elapsedMilliseconds}ms (items: ${data.length})');

      // Store in cache with app version
      _cache[cacheKey] = CacheEntry(
        data,
        CacheConfig.defaultExpiration,
        appVersion: _currentAppVersion ?? 'unknown',
      );
      AppLogger.debug(
          'STORED in cache for $cacheKey (expires in ${CacheConfig.defaultExpiration.inHours}h, app version: $_currentAppVersion)');

      // Clean up old cache entries if we have too many
      _cleanupCache();

      return data;
    } catch (e) {
      AppLogger.error('API FETCH ERROR for $cacheKey', errorObject: e);

      // If we have cached data (even if expired), return it as fallback
      if (cacheEntry != null && !cacheEntry.isTooOld) {
        AppLogger.warning(
            'USING STALE CACHE for $cacheKey due to API error (age: ${DateTime.now().difference(cacheEntry.timestamp).inMinutes}min)');
        return cacheEntry.data;
      }

      // If we must fetch (data too old) or have no cache, rethrow the error
      if (mustFetch) {
        AppLogger.error(
            'MUST FETCH - rethrowing error for $cacheKey (data too old: ${cacheEntry?.isTooOld ?? false})');
        rethrow;
      }

      // Return empty list as last resort
      AppLogger.warning(
          'RETURNING EMPTY LIST for $cacheKey - no fallback available');
      return [];
    }
  }

  // Clean up old cache entries to prevent memory bloat
  void _cleanupCache() {
    if (_cache.length <= CacheConfig.maxCacheEntries) return;

    // Sort by timestamp and remove oldest entries
    final sortedEntries = _cache.entries.toList()
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

    final entriesToRemove = sortedEntries.length - CacheConfig.maxCacheEntries;
    for (int i = 0; i < entriesToRemove; i++) {
      _cache.remove(sortedEntries[i].key);
    }

    AppLogger.debug(
        'CLEANED UP $entriesToRemove old cache entries (total: ${_cache.length})');
  }

  // Method to clear cache manually if needed
  void clearCache() {
    final count = _cache.length;
    _cache.clear();
    AppLogger.debug('CLEARED $count cache entries manually');
  }

  // Method to invalidate specific cache entry
  void invalidateCacheEntry(String dataType, String locale,
      {bool isLocaleAgnostic = false}) {
    final cacheKey =
        _getCacheKey(dataType, locale, isLocaleAgnostic: isLocaleAgnostic);
    final removed = _cache.remove(cacheKey);
    if (removed != null) {
      AppLogger.debug(
          'INVALIDATED cache entry for $cacheKey (was cached for ${DateTime.now().difference(removed.timestamp).inMinutes}min)');
    } else {
      AppLogger.warning('NO CACHE ENTRY to invalidate for $cacheKey');
    }
  }

  // Method to invalidate all cache entries for a specific data type
  void invalidateDataType(String dataType, {bool isLocaleAgnostic = false}) {
    final keysToRemove = <String>[];

    if (isLocaleAgnostic) {
      // For locale-agnostic data, look for exact match
      if (_cache.containsKey(dataType)) {
        keysToRemove.add(dataType);
      }
    } else {
      // For locale-specific data, look for keys with dataType_ prefix
      keysToRemove.addAll(
          _cache.keys.where((key) => key.startsWith('${dataType}_')).toList());
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    AppLogger.debug(
        'Invalidated ${keysToRemove.length} cache entries for data type: $dataType (locale-agnostic: $isLocaleAgnostic)');
  }

  // Method to invalidate all expired cache entries
  void invalidateExpiredEntries() {
    final keysToRemove = <String>[];
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    AppLogger.debug('INVALIDATED ${keysToRemove.length} expired cache entries');
  }

  // Method to refresh specific data type (invalidate and optionally prefetch)
  Future<void> refreshDataType(String dataType, String locale,
      {bool prefetch = false, bool isLocaleAgnostic = false}) async {
    invalidateCacheEntry(dataType, locale, isLocaleAgnostic: isLocaleAgnostic);

    if (prefetch) {
      switch (dataType) {
        case 'roasters':
          await fetchCombinedRoasters(locale);
          break;
        case 'processing_methods':
          await fetchCombinedProcessingMethods(locale);
          break;
        case 'origins':
          await fetchCombinedOrigins(locale);
          break;
        case 'tasting_notes':
          await fetchCombinedTastingNotes(locale);
          break;
      }
    }
  }

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
            .upsert(supabaseData)
            .timeout(const Duration(seconds: 3));
      } on TimeoutException catch (e) {
        AppLogger.warning('Supabase request timed out', errorObject: e);
        // Optionally, handle the timeout, e.g., by retrying or queuing the request
      } catch (e) {
        AppLogger.error('Error syncing new coffee beans to Supabase',
            errorObject: e);
      }
    }

    notifyListeners();
    return beansUuid;
  }

  Future<void> updateCoffeeBeans(CoffeeBeansModel beans) async {
    AppLogger.debug(
        'updateCoffeeBeans called with UUID: ${AppLogger.sanitize(beans.beansUuid)}');

    final currentBeans =
        await db.coffeeBeansDao.fetchCoffeeBeansByUuid(beans.beansUuid);
    if (currentBeans == null) {
      AppLogger.error(
          'ERROR - Coffee beans not found for UUID: ${AppLogger.sanitize(beans.beansUuid)}');
      throw Exception('Coffee beans not found');
    }

    AppLogger.debug(
        'Found existing bean: ${currentBeans.name} by ${currentBeans.roaster}');
    AppLogger.debug('Current version vector: ${currentBeans.versionVector}');

    final currentVector = VersionVector.fromString(currentBeans.versionVector);
    final newVector = currentVector.increment();

    final updatedBeans = beans.copyWith(
      versionVector: newVector.toString(),
    );

    AppLogger.debug(
        'Updated bean data - Name: ${updatedBeans.name}, Roaster: ${updatedBeans.roaster}');
    AppLogger.debug('New version vector: ${updatedBeans.versionVector}');

    try {
      await db.coffeeBeansDao.updateCoffeeBeans(updatedBeans);
      AppLogger.debug('Database update completed successfully');
    } catch (e) {
      AppLogger.error('ERROR during database update', errorObject: e);
      throw e;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final supabaseData = _coffeeBeansModelToJson(updatedBeans);
        supabaseData['user_id'] = user.id;
        await Supabase.instance.client
            .from('user_coffee_beans')
            .upsert(supabaseData, onConflict: 'user_id,beans_uuid')
            .timeout(const Duration(seconds: 3));
        AppLogger.debug('Supabase sync completed successfully');
      } on TimeoutException catch (e) {
        AppLogger.warning('Supabase request timed out', errorObject: e);
        // Optionally, handle the timeout here
      } catch (e) {
        AppLogger.error('Error syncing updated coffee beans to Supabase',
            errorObject: e);
      }
    }

    AppLogger.debug('Calling notifyListeners()');
    notifyListeners();
    AppLogger.debug('updateCoffeeBeans completed successfully');
  }

  Future<void> deleteCoffeeBeans(String beansUuid) async {
    final currentBeans =
        await db.coffeeBeansDao.fetchCoffeeBeansByUuid(beansUuid);
    if (currentBeans == null) {
      AppLogger.error(
          'Coffee beans not found for UUID: ${AppLogger.sanitize(beansUuid)}');
      throw Exception('Coffee beans not found');
    }

    // Perform the deletion and detachment in a transaction
    final updatedBeans = await db.transaction(() async {
      // First, detach the coffee bean from all user stats
      await db.userStatsDao.detachCoffeeBeanFromStats(beansUuid);

      // Then, mark the bean as deleted
      final currentVector =
          VersionVector.fromString(currentBeans.versionVector);
      final newVector = currentVector.increment();

      // Create an updated beans record with isDeleted set to true and the new version vector
      final updatedBeans = currentBeans.copyWith(
        isDeleted: true, // Mark as deleted
        versionVector: newVector.toString(),
      );

      // Update the beans locally (to mark it as deleted)
      await db.coffeeBeansDao.updateCoffeeBeans(updatedBeans);

      return updatedBeans;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final supabaseData = _coffeeBeansModelToJson(updatedBeans);
        supabaseData['user_id'] = user.id;

        // Add a 2-second timeout to the Supabase upsert operation
        await Supabase.instance.client
            .from('user_coffee_beans')
            .upsert(supabaseData, onConflict: 'user_id,beans_uuid')
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        if (e is TimeoutException) {
          AppLogger.warning('Supabase operation timed out', errorObject: e);
          // You might want to handle the timeout specifically here
        } else {
          AppLogger.error('Error marking coffee beans as deleted in Supabase',
              errorObject: e);
          // Handle other exceptions
        }
        // Decide if you want to handle this error differently
      }
    }

    // Removed local deletion
    // await db.coffeeBeansDao.deleteCoffeeBeans(beansUuid);

    notifyListeners();
  }

  Future<CoffeeBeansModel?> fetchCoffeeBeansById(int id) async {
    final beans = await db.coffeeBeansDao.fetchCoffeeBeansById(id);
    AppLogger.debug('Fetched bean by ID: ${beans?.id}');
    return beans;
  }

  Future<CoffeeBeansModel?> fetchCoffeeBeansByUuid(String uuid) async {
    final beans = await db.coffeeBeansDao.fetchCoffeeBeansByUuid(uuid);
    AppLogger.debug(
        'Fetched bean by UUID: ${AppLogger.sanitize(beans?.beansUuid)}');
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

  Future<List<String>> fetchAllDistinctFarmers() async {
    return await db.coffeeBeansDao.fetchAllDistinctFarmers();
  }

  Future<List<String>> fetchAllDistinctFarms() async {
    return await db.coffeeBeansDao.fetchAllDistinctFarms();
  }

  Future<List<String>> fetchCombinedTastingNotes(String locale) async {
    final cacheKey = _getCacheKey('tasting_notes', locale);

    return _getCachedOrFetch(
      cacheKey,
      locale,
      () async {
        final localTastingNotes = await fetchAllDistinctTastingNotes();
        List<String> supabaseTastingNotes = [];

        try {
          supabaseTastingNotes =
              await databaseProvider.fetchTastingNotesForLocale(locale);
        } catch (error) {
          //AppLogger.error('Error fetching tasting notes from Supabase', errorObject: error);
        }

        final combinedSet = {...localTastingNotes, ...supabaseTastingNotes};
        return combinedSet.toList();
      },
    );
  }

  Future<List<String>> fetchCombinedOrigins(String locale) async {
    final cacheKey = _getCacheKey('origins', locale);

    return _getCachedOrFetch(
      cacheKey,
      locale,
      () async {
        final localOrigins = await fetchAllDistinctOrigins();
        List<String> supabaseOrigins = [];

        try {
          supabaseOrigins =
              await databaseProvider.fetchCountriesForLocale(locale);
        } catch (error) {
          //AppLogger.error('Error fetching origins from Supabase', errorObject: error);
        }

        final combinedSet = {...localOrigins, ...supabaseOrigins};
        return combinedSet.toList();
      },
    );
  }

  Future<List<String>> fetchCombinedProcessingMethods(String locale) async {
    final cacheKey = _getCacheKey('processing_methods', locale);

    return _getCachedOrFetch(
      cacheKey,
      locale,
      () async {
        final localProcessingMethods =
            await fetchAllDistinctProcessingMethods();
        List<String> supabaseProcessingMethods = [];

        try {
          supabaseProcessingMethods =
              await databaseProvider.fetchProcessingMethodsForLocale(locale);
        } catch (error) {
          // AppLogger.error('Error fetching processing methods from Supabase', errorObject: error);
        }

        final combinedSet = {
          ...localProcessingMethods,
          ...supabaseProcessingMethods
        };
        return combinedSet.toList();
      },
    );
  }

  Future<List<String>> fetchCombinedRoasters(String locale) async {
    // Roasters are locale-agnostic, so we don't include locale in the cache key
    final cacheKey = _getCacheKey('roasters', locale, isLocaleAgnostic: true);

    return _getCachedOrFetch(
      cacheKey,
      locale,
      () async {
        final localRoasters = await fetchAllDistinctRoasters();
        List<String> supabaseRoasters = [];

        try {
          supabaseRoasters = await databaseProvider.fetchRoasters();
        } catch (error) {
          //AppLogger.error('Error fetching roasters from Supabase', errorObject: error);
        }

        final combinedSet = {...localRoasters, ...supabaseRoasters};
        return combinedSet.toList();
      },
    );
  }

  Future<void> toggleFavoriteStatus(String uuid, bool isFavorite) async {
    await db.coffeeBeansDao.updateFavoriteStatus(uuid, isFavorite);
    notifyListeners();
  }

  Future<void> backfillMissingUuids() async {
    final beansToUpdate = await db.coffeeBeansDao.fetchBeansNeedingUpdate();

    if (beansToUpdate.isEmpty) {
      AppLogger.debug('No coffee beans need updating.');
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

    AppLogger.debug('Updated ${beansToUpdate.length} coffee bean entries.');
    notifyListeners();
  }

  Future<void> batchUploadCoffeeBeans() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      AppLogger.debug('No user logged in or user is anonymous');
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
        AppLogger.debug('Uploaded batch ${i ~/ batchSize + 1}');
      } catch (e) {
        AppLogger.error('Error uploading batch ${i ~/ batchSize + 1}',
            errorObject: e);
      }
    }

    AppLogger.info('Successfully uploaded ${beansData.length} coffee beans');
  }

  Future<void> batchDownloadCoffeeBeans() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      AppLogger.debug('No user logged in or user is anonymous');
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
      AppLogger.info(
          'Downloaded and updated ${remoteBeans.length} coffee beans');
    } catch (e) {
      AppLogger.error('Error downloading coffee beans', errorObject: e);
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
      AppLogger.debug('No user logged in or user is anonymous');
      return;
    }

    try {
      // Fetch all local beans, including deleted ones
      final localBeans =
          await db.coffeeBeansDao.fetchAllBeansWithVersionVectors();

      // Create a map for quick lookup
      final localBeansMap = {for (var bean in localBeans) bean.beansUuid: bean};

      // Fetch all remote beans, including deleted ones
      final response = await Supabase.instance.client
          .from('user_coffee_beans')
          .select('beans_uuid, version_vector, is_deleted')
          .eq('user_id', user.id);

      final remoteBeansInfo = (response as List<dynamic>)
          .map((json) => (
                beansUuid: json['beans_uuid'] as String,
                versionVector: json['version_vector'] as String,
                isDeleted: json['is_deleted'] as bool,
              ))
          .toList();

      // Prepare lists for updates
      final List<String> localUpdates = [];
      final List<Map<String, dynamic>> remoteUpdates = [];

      // Compare version vectors and handle deletions
      for (final remoteBean in remoteBeansInfo) {
        final localBean = localBeansMap[remoteBean.beansUuid];
        final remoteVersionVector =
            VersionVector.fromString(remoteBean.versionVector);

        if (localBean == null) {
          if (!remoteBean.isDeleted) {
            // Bean doesn't exist locally and is not deleted remotely, need to fetch from remote
            localUpdates.add(remoteBean.beansUuid);
          }
          // If the remote bean is deleted and doesn't exist locally, no action needed
        } else {
          final localVersionVector = localBean.versionVectorObject;

          if (_isRemoteNewer(localVersionVector, remoteVersionVector)) {
            // Remote is newer, update local
            localUpdates.add(remoteBean.beansUuid);
          } else if (_isLocalNewer(localVersionVector, remoteVersionVector)) {
            // Local is newer, update remote
            remoteUpdates
                .add(_coffeeBeansModelToJson(localBean)..['user_id'] = user.id);
          } else if (localBean.isDeleted != remoteBean.isDeleted) {
            // Version vectors are equal but deletion status differs
            // Prefer deletions over restorations
            if (localBean.isDeleted) {
              // Local bean is deleted; update remote
              remoteUpdates.add(
                  _coffeeBeansModelToJson(localBean)..['user_id'] = user.id);
            } else {
              // Remote bean is deleted; update local
              localUpdates.add(remoteBean.beansUuid);
            }
          }
          // If versions are equal and deletion status is the same, do nothing
        }
      }

      // Check for new local beans not present in remote
      final newLocalBeans = localBeans.where((bean) =>
          !remoteBeansInfo.any((remote) => remote.beansUuid == bean.beansUuid));
      remoteUpdates.addAll(
        newLocalBeans.map(
            (bean) => _coffeeBeansModelToJson(bean)..['user_id'] = user.id),
      );

      // Perform local updates
      if (localUpdates.isNotEmpty) {
        final updatedRemoteBeans = await _fetchFullRemoteBeans(localUpdates);
        await db.coffeeBeansDao
            .insertOrUpdateMultipleCoffeeBeans(updatedRemoteBeans);
      }

      // Perform remote updates with a timeout
      if (remoteUpdates.isNotEmpty) {
        try {
          await Supabase.instance.client
              .from('user_coffee_beans')
              .upsert(remoteUpdates)
              .timeout(const Duration(seconds: 3));
        } catch (e) {
          if (e is TimeoutException) {
            AppLogger.warning('Supabase operation timed out', errorObject: e);
          } else {
            AppLogger.error('Error updating coffee beans in Supabase',
                errorObject: e);
          }
        }
      }

      AppLogger.info(
          'Sync completed. Local updates: ${localUpdates.length}, Remote updates: ${remoteUpdates.length}');
    } catch (e) {
      AppLogger.error('Error syncing coffee beans', errorObject: e);
    }

    notifyListeners();
  }

  bool _isRemoteNewer(VersionVector local, VersionVector remote) {
    return remote.isNewerThan(local);
  }

  bool _isLocalNewer(VersionVector local, VersionVector remote) {
    return local.isNewerThan(remote);
  }

  Future<List<CoffeeBeansModel>> _fetchFullRemoteBeans(
      List<String> beansUuids) async {
    final response = await Supabase.instance.client
        .from('user_coffee_beans')
        .select()
        .inFilter('beans_uuid', beansUuids);
    return (response as List<dynamic>)
        .map((json) => _jsonToCoffeeBeansModel(json))
        .toList();
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
      'package_weight_grams': model.packageWeightGrams,
      'notes': model.notes,
      'farmer': model.farmer,
      'farm': model.farm,
      'is_favorite': model.isFavorite,
      'version_vector': model.versionVector,
      'is_deleted': model.isDeleted,
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
      cuppingScore: json['cupping_score'] != null
          ? (json['cupping_score'] as num).toDouble()
          : null,
      packageWeightGrams: json['package_weight_grams'] != null
          ? (json['package_weight_grams'] as num).toDouble()
          : null,
      notes: json['notes'],
      farmer: json['farmer'],
      farm: json['farm'],
      isFavorite: json['is_favorite'],
      versionVector: json['version_vector'],
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Future<List<CoffeeBeansModel>> fetchFilteredCoffeeBeans({
    List<String>? roasters,
    List<String>? origins,
    bool? isFavorite,
  }) async {
    return await db.coffeeBeansDao.fetchCoffeeBeansFiltered(
      roasters: roasters,
      origins: origins,
      isFavorite: isFavorite,
    );
  }

  Future<List<String>> fetchOriginsForRoasters(
      List<String> selectedRoasters) async {
    return await db.coffeeBeansDao.fetchOriginsForRoasters(selectedRoasters);
  }

  /// Updates the package weight for a specific coffee bean by subtracting the used amount.
  /// Returns the new weight after deduction, or null if no update was performed.
  Future<double?> updateBeanWeightAfterBrew(
      String beansUuid, double usedAmount) async {
    try {
      final currentBeans = await fetchCoffeeBeansByUuid(beansUuid);
      if (currentBeans == null) {
        AppLogger.debug(
            'Bean not found for UUID: ${AppLogger.sanitize(beansUuid)}');
        return null;
      }

      final currentWeight = currentBeans.packageWeightGrams;
      if (currentWeight == null || currentWeight <= 0) {
        AppLogger.debug(
            'Bean ${AppLogger.sanitize(beansUuid)} has no valid package weight (current: $currentWeight)');
        return null;
      }

      final newWeight = (currentWeight - usedAmount).clamp(0.0, currentWeight);
      AppLogger.debug(
          'Updating bean ${AppLogger.sanitize(beansUuid)} weight from $currentWeight to $newWeight (used: $usedAmount)');

      if (newWeight == currentWeight) {
        AppLogger.debug(
            'No weight change needed for bean ${AppLogger.sanitize(beansUuid)}');
        return currentWeight;
      }

      final updatedBeans = currentBeans.copyWith(packageWeightGrams: newWeight);
      await updateCoffeeBeans(updatedBeans);

      AppLogger.debug(
          'Successfully updated bean ${AppLogger.sanitize(beansUuid)} weight to $newWeight');
      return newWeight;
    } catch (e) {
      AppLogger.error(
          'Error updating bean weight for ${AppLogger.sanitize(beansUuid)}',
          errorObject: e);
      return null;
    }
  }

  /// Adds weight back to a coffee bean when beans are removed from a brew diary record.
  /// Returns the new weight after addition, or null if no update was performed.
  Future<double?> updateBeanWeightAfterBrewModification(
      String beansUuid, double coffeeAmount) async {
    try {
      final currentBeans = await fetchCoffeeBeansByUuid(beansUuid);
      if (currentBeans == null) {
        AppLogger.debug(
            'Bean not found for UUID: ${AppLogger.sanitize(beansUuid)}');
        return null;
      }

      final currentWeight = currentBeans.packageWeightGrams;
      if (currentWeight == null) {
        AppLogger.debug(
            'Bean ${AppLogger.sanitize(beansUuid)} has no package weight specified, cannot adjust');
        return null;
      }

      final newWeight = currentWeight + coffeeAmount;
      AppLogger.debug(
          'Adding back $coffeeAmount to bean ${AppLogger.sanitize(beansUuid)} weight from $currentWeight to $newWeight');

      final updatedBeans = currentBeans.copyWith(packageWeightGrams: newWeight);
      await updateCoffeeBeans(updatedBeans);

      AppLogger.debug(
          'Successfully added back weight to bean ${AppLogger.sanitize(beansUuid)}, new weight: $newWeight');
      return newWeight;
    } catch (e) {
      AppLogger.error(
          'Error adding back bean weight for ${AppLogger.sanitize(beansUuid)}',
          errorObject: e);
      return null;
    }
  }

  /// Subtracts weight from a coffee bean when beans are added to a brew diary record.
  /// Returns the new weight after subtraction, or null if no update was performed.
  Future<double?> updateBeanWeightWhenBeansAdded(
      String beansUuid, double coffeeAmount) async {
    try {
      final currentBeans = await fetchCoffeeBeansByUuid(beansUuid);
      if (currentBeans == null) {
        AppLogger.debug(
            'Bean not found for UUID: ${AppLogger.sanitize(beansUuid)}');
        return null;
      }

      final currentWeight = currentBeans.packageWeightGrams;
      if (currentWeight == null) {
        AppLogger.debug(
            'Bean ${AppLogger.sanitize(beansUuid)} has no package weight specified, cannot adjust');
        return null;
      }

      final newWeight =
          (currentWeight - coffeeAmount).clamp(0.0, double.infinity);
      AppLogger.debug(
          'Subtracting $coffeeAmount from bean ${AppLogger.sanitize(beansUuid)} weight from $currentWeight to $newWeight');

      if (newWeight == currentWeight) {
        AppLogger.debug(
            'No weight change needed for bean ${AppLogger.sanitize(beansUuid)}');
        return currentWeight;
      }

      final updatedBeans = currentBeans.copyWith(packageWeightGrams: newWeight);
      await updateCoffeeBeans(updatedBeans);

      AppLogger.debug(
          'Successfully subtracted weight from bean ${AppLogger.sanitize(beansUuid)}, new weight: $newWeight');
      return newWeight;
    } catch (e) {
      AppLogger.error(
          'Error subtracting bean weight for ${AppLogger.sanitize(beansUuid)}',
          errorObject: e);
      return null;
    }
  }

  // Debug method to print cache statistics
  void printCacheStats() {
    AppLogger.debug('CACHE STATISTICS:');
    AppLogger.debug('   Total entries: ${_cache.length}');
    AppLogger.debug('   Max entries: ${CacheConfig.maxCacheEntries}');
    AppLogger.debug(
        '   Default expiration: ${CacheConfig.defaultExpiration.inHours}h');
    AppLogger.debug('   Max age: ${CacheConfig.maxAge.inDays}d');
    AppLogger.debug('   App version: $_currentAppVersion');

    if (_cache.isNotEmpty) {
      AppLogger.debug('   Cache entries:');
      for (final entry in _cache.entries) {
        final age = DateTime.now().difference(entry.value.timestamp);
        final status = entry.value.isExpired
            ? 'EXPIRED'
            : entry.value.isTooOld
                ? 'TOO_OLD'
                : 'VALID';
        final versionInfo = entry.value.appVersion != null
            ? ', version: ${entry.value.appVersion}'
            : ', no version';
        final localeInfo =
            entry.key.contains('_') ? ', locale-specific' : ', locale-agnostic';
        AppLogger.debug(
            '     ${entry.key}: ${entry.value.data.length} items, age: ${age.inMinutes}min, status: $status$versionInfo$localeInfo');
      }
    } else {
      AppLogger.debug('   Cache is empty');
    }
    AppLogger.debug('END CACHE STATISTICS');
  }
}
