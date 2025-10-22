import 'dart:async';

import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import '../database/database.dart';
import 'coffee_beans_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection/collection.dart';

class UserStatProvider extends ChangeNotifier {
  final Uuid _uuid = Uuid();
  final AppDatabase db;
  final CoffeeBeansProvider coffeeBeansProvider;
  final String deviceId;

  UserStatProvider(this.db, this.coffeeBeansProvider) : deviceId = Uuid().v4();

  Future<void> insertUserStat({
    required String recipeId,
    required double coffeeAmount,
    required double waterAmount,
    required int sweetnessSliderPosition,
    required int strengthSliderPosition,
    required String brewingMethodId,
    String? notes,
    String? beans,
    String? roaster,
    double? rating,
    int? coffeeBeansId,
    bool isMarked = false,
    String? coffeeBeansUuid,
    String? statUuid,
  }) async {
    final newStatUuid = statUuid ?? _uuid.v7();
    final versionVector = VersionVector.initial(deviceId).toString();

    final newStat = UserStatsModel(
      statUuid: newStatUuid,
      recipeId: recipeId,
      coffeeAmount: coffeeAmount,
      waterAmount: waterAmount,
      sweetnessSliderPosition: sweetnessSliderPosition,
      strengthSliderPosition: strengthSliderPosition,
      brewingMethodId: brewingMethodId,
      createdAt: DateTime.now().toUtc(),
      notes: notes,
      beans: beans,
      roaster: roaster,
      rating: rating,
      coffeeBeansId: coffeeBeansId,
      isMarked: isMarked,
      coffeeBeansUuid: coffeeBeansUuid,
      versionVector: versionVector,
      isDeleted: false, // Initialize isDeleted as false
    );

    await db.userStatsDao.insertUserStat(newStat);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final supabaseData = _userStatModelToJson(newStat);
        supabaseData['user_id'] = user.id;
        await Supabase.instance.client
            .from('user_stats')
            .upsert(supabaseData)
            .timeout(const Duration(seconds: 2));
      } on TimeoutException catch (e) {
        print('Supabase request timed out: $e');
        // Optionally, handle the timeout, e.g., by retrying or queuing the request
      } catch (e) {
        print('Error syncing new user stat to Supabase: $e');
        // Handle other exceptions as needed
      }
    }

    notifyListeners();
  }

  Future<void> updateUserStat({
    required String statUuid,
    String? recipeId,
    double? coffeeAmount,
    double? waterAmount,
    int? sweetnessSliderPosition,
    int? strengthSliderPosition,
    String? brewingMethodId,
    String? notes,
    String? beans,
    String? roaster,
    double? rating,
    int? coffeeBeansId,
    bool? isMarked,
    String? coffeeBeansUuid,
    bool clearBeans = false,
  }) async {
    print(
        'updateUserStat called with statUuid: $statUuid, coffeeBeansUuid: $coffeeBeansUuid');

    final currentStat = await db.userStatsDao.fetchStatByUuid(statUuid);
    if (currentStat == null) {
      print('Error: Stat not found for UUID: $statUuid');
      throw Exception('Stat not found');
    }

    print('Current stat: $currentStat');

    final currentVector = VersionVector.fromString(currentStat.versionVector);
    final newVector = currentVector.increment();

    var updatedStat = currentStat.copyWith(
      recipeId: recipeId,
      coffeeAmount: coffeeAmount,
      waterAmount: waterAmount,
      sweetnessSliderPosition: sweetnessSliderPosition,
      strengthSliderPosition: strengthSliderPosition,
      brewingMethodId: brewingMethodId,
      notes: notes,
      beans: beans,
      roaster: roaster,
      rating: rating,
      coffeeBeansId: coffeeBeansId,
      isMarked: isMarked,
      coffeeBeansUuid: coffeeBeansUuid,
      versionVector: newVector.toString(),
    );

    if (clearBeans) {
      print('Clearing beans for stat $statUuid');
      updatedStat = UserStatsModel(
        statUuid: currentStat.statUuid,
        id: currentStat.id,
        recipeId: updatedStat.recipeId,
        coffeeAmount: updatedStat.coffeeAmount,
        waterAmount: updatedStat.waterAmount,
        sweetnessSliderPosition: updatedStat.sweetnessSliderPosition,
        strengthSliderPosition: updatedStat.strengthSliderPosition,
        brewingMethodId: updatedStat.brewingMethodId,
        createdAt: currentStat.createdAt,
        notes: updatedStat.notes,
        beans: updatedStat.beans,
        roaster: updatedStat.roaster,
        rating: updatedStat.rating,
        coffeeBeansId: updatedStat.coffeeBeansId,
        isMarked: updatedStat.isMarked,
        coffeeBeansUuid: null,
        versionVector: updatedStat.versionVector,
        isDeleted: currentStat.isDeleted,
      );
    }

    print('Updated stat: $updatedStat');

    await db.userStatsDao.updateUserStat(updatedStat);
    print('Database updated');

    // Force a refresh of the stat
    final refreshedStat = await db.userStatsDao.fetchStatByUuid(statUuid);
    print('Refreshed stat after update: $refreshedStat');

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final supabaseData = _userStatModelToJson(refreshedStat!);
        supabaseData['user_id'] = user.id;
        await Supabase.instance.client
            .from('user_stats')
            .upsert(supabaseData, onConflict: 'user_id,stat_uuid')
            .timeout(const Duration(seconds: 3));
        print('Supabase updated');
      } on TimeoutException catch (e) {
        print('Supabase request timed out: $e');
        // Optionally, handle the timeout here
      } catch (e) {
        print('Error syncing updated user stat to Supabase: $e');
      }
    }

    notifyListeners();
    print('notifyListeners called');
  }

  Future<void> deleteUserStat(String statUuid) async {
    final currentStat = await db.userStatsDao.fetchStatByUuid(statUuid);
    if (currentStat == null) {
      print('Error: Stat not found for UUID: $statUuid');
      throw Exception('Stat not found');
    }

    final currentVector = VersionVector.fromString(currentStat.versionVector);
    final newVector = currentVector.increment();

    // Create an updated stat with isDeleted set to true and the new version vector
    final updatedStat = currentStat.copyWith(
      isDeleted: true,
      versionVector: newVector.toString(),
    );

    // Update the stat locally (to mark it as deleted)
    await db.userStatsDao.updateUserStat(updatedStat);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final supabaseData = _userStatModelToJson(updatedStat);
        supabaseData['user_id'] = user.id;
        await Supabase.instance.client
            .from('user_stats')
            .upsert(supabaseData, onConflict: 'user_id,stat_uuid')
            .timeout(const Duration(seconds: 2)); // Added 2-second timeout
      } catch (e) {
        if (e is TimeoutException) {
          print('Supabase operation timed out: $e');
          // You might want to handle the timeout specifically here
        } else {
          print('Error marking user stat as deleted in Supabase: $e');
          // Handle other exceptions
        }
        // Decide if you want to handle this error differently
      }
    }

    notifyListeners();
  }

  Future<List<UserStatsModel>> fetchAllUserStats() async {
    return await db.userStatsDao.fetchAllStats();
  }

  Future<UserStatsModel?> fetchUserStatByUuid(String statUuid) async {
    return await db.userStatsDao.fetchStatByUuid(statUuid);
  }

  // Keep this method for backward compatibility
  Future<UserStatsModel?> fetchUserStatById(int id) async {
    final allStats = await fetchAllUserStats();
    try {
      return allStats.firstWhere((stat) => stat.id == id);
    } catch (e) {
      // If no stat is found with the given id, return null
      return null;
    }
  }

  Future<void> batchUploadUserStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      print('No user logged in or user is anonymous');
      return;
    }

    final localStats = await fetchAllUserStats();

    final statsData = localStats
        .map((stat) => _userStatModelToJson(stat)..['user_id'] = user.id)
        .toList();

    final batchSize = 50;

    for (var i = 0; i < statsData.length; i += batchSize) {
      final batch = statsData.skip(i).take(batchSize).toList();

      try {
        await Supabase.instance.client.from('user_stats').upsert(batch);
        print('Uploaded batch ${i ~/ batchSize + 1}');
      } catch (e) {
        print('Error uploading batch ${i ~/ batchSize + 1}: $e');
      }
    }

    print('Successfully uploaded ${statsData.length} stats');
  }

  Future<void> batchDownloadUserStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      print('No user logged in or user is anonymous');
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('user_stats')
          .select()
          .eq('user_id', user.id);

      final remoteStats = (response as List<dynamic>)
          .map((json) => _jsonToUserStatsModel(json))
          .toList();

      await db.userStatsDao.insertOrUpdateMultipleStats(remoteStats);
      print('Downloaded and updated ${remoteStats.length} stats');
    } catch (e) {
      print('Error downloading user stats: $e');
    }
  }

  Future<void> syncUserStats() async {
    await batchUploadUserStats();
    await batchDownloadUserStats();
    notifyListeners();
  }

  // Keep this method for backward compatibility
  Future<void> deleteUserStatById(int id) async {
    final stat = await fetchUserStatById(id);
    if (stat != null) {
      await deleteUserStat(stat.statUuid);
    }
  }

  Future<double> fetchBrewedCoffeeAmountForPeriod(
      DateTime start, DateTime end) async {
    return await db.userStatsDao.fetchBrewedCoffeeAmount(start, end);
  }

  Future<List<String>> fetchTopRecipeIdsForPeriod(
      DateTime start, DateTime end) async {
    return await db.userStatsDao.fetchTopRecipes(start, end);
  }

  DateTime getStartOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime getEndOfToday() {
    return getStartOfToday()
        .add(Duration(days: 1))
        .subtract(Duration(milliseconds: 1));
  }

  DateTime getStartOfWeek() {
    final now = DateTime.now();
    // Adjust to first day of week as Monday
    int weekday = now.weekday;
    DateTime startOfWeek = now.subtract(Duration(days: weekday - 1));
    return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  }

  DateTime getStartOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  Future<void> backfillMissingCoffeeBeansUuids() async {
    final statsToUpdate = await db.userStatsDao.fetchStatsNeedingUuidUpdate();

    if (statsToUpdate.isEmpty) {
      print('No UserStats records need updating.');
      return;
    }

    List<UserStatsCompanion> updates = [];

    for (final stat in statsToUpdate) {
      if (stat.coffeeBeansId != null) {
        final coffeeBeans =
            await coffeeBeansProvider.fetchCoffeeBeansById(stat.coffeeBeansId!);
        if (coffeeBeans != null && coffeeBeans.beansUuid != null) {
          updates.add(UserStatsCompanion(
            id: Value(stat.id),
            coffeeBeansUuid: Value(coffeeBeans.beansUuid),
          ));
        } else {
          print(
              'Warning: Coffee beans not found or missing UUID for ID: ${stat.coffeeBeansId}');
        }
      }
    }

    if (updates.isNotEmpty) {
      await db.userStatsDao.batchUpdateCoffeeBeansUuids(updates);
      print(
          'Updated ${updates.length} UserStats records with coffee beans UUIDs.');
    }

    notifyListeners();
  }

  Future<void> backfillMissingStatUuids() async {
    final statsToUpdate =
        await db.userStatsDao.fetchStatsNeedingStatUuidUpdate();

    if (statsToUpdate.isEmpty) {
      print('No UserStats records need updating.');
      return;
    }

    Set<String> generatedUuids = {};
    List<UserStatsCompanion> updates = [];

    for (final stat in statsToUpdate) {
      String newUuid;
      do {
        newUuid = _uuid.v7();
      } while (generatedUuids.contains(newUuid));
      generatedUuids.add(newUuid);

      updates.add(UserStatsCompanion(
        id: Value(stat.id),
        statUuid: Value(newUuid),
      ));
    }

    if (updates.isNotEmpty) {
      await db.userStatsDao.batchUpdateStatUuids(updates);
      print('Updated ${updates.length} UserStats records with new UUIDv7s.');
    }

    notifyListeners();
  }

  Future<void> syncNewUserStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      print('No user logged in or user is anonymous');
      return;
    }

    try {
      // Fetch all local stats, including deleted ones
      final localStats =
          await db.userStatsDao.fetchAllStatsWithVersionVectors();

      // Prepare a map of statUuid to localStat for quick lookup
      final localStatsMap = {for (var stat in localStats) stat.statUuid: stat};

      // Fetch all remote stats, including deleted ones
      final response = await Supabase.instance.client
          .from('user_stats')
          .select('stat_uuid, version_vector, is_deleted')
          .eq('user_id', user.id);

      final remoteStatsInfo = (response as List<dynamic>)
          .map((json) => (
                statUuid: json['stat_uuid'] as String,
                versionVector: json['version_vector'] as String,
                isDeleted: json['is_deleted'] as bool,
              ))
          .toList();

      // Prepare lists for updates
      final List<String> localUpdates = [];
      final List<UserStatsModel> remoteUpdates = [];

      // Compare version vectors and handle deletions
      for (final remoteStat in remoteStatsInfo) {
        final localStat = localStatsMap[remoteStat.statUuid];
        final remoteVersionVector =
            VersionVector.fromString(remoteStat.versionVector);

        if (localStat == null) {
          if (!remoteStat.isDeleted) {
            // Stat doesn't exist locally and is not deleted remotely, need to fetch from remote
            localUpdates.add(remoteStat.statUuid);
          }
          // If the remote stat is deleted and doesn't exist locally, no action needed
        } else {
          final localVersionVector =
              VersionVector.fromString(localStat.versionVector);

          if (_isRemoteNewer(localVersionVector, remoteVersionVector)) {
            // Remote is newer, update local
            localUpdates.add(remoteStat.statUuid);
          } else if (_isLocalNewer(localVersionVector, remoteVersionVector)) {
            // Local is newer, update remote
            remoteUpdates.add(localStat);
          } else if (localStat.isDeleted != remoteStat.isDeleted) {
            // Version vectors are equal but deletion status differs
            // Prefer deletions over restorations
            if (localStat.isDeleted) {
              // Local stat is deleted; update remote
              remoteUpdates.add(localStat);
            } else {
              // Remote stat is deleted; update local
              localUpdates.add(remoteStat.statUuid);
            }
          }
          // If versions are equal and deletion status is the same, do nothing
        }
      }

      // Check for new local stats not present in remote
      final newLocalStats = localStats.where((stat) =>
          !remoteStatsInfo.any((remote) => remote.statUuid == stat.statUuid));
      remoteUpdates.addAll(newLocalStats);

      // Perform local updates with enhanced error handling
      if (localUpdates.isNotEmpty) {
        final updatedRemoteStats = await _fetchFullRemoteStats(localUpdates);
        await _insertStatsWithFallback(updatedRemoteStats);
      }

      // Perform remote updates with a timeout
      if (remoteUpdates.isNotEmpty) {
        await _updateRemoteStats(remoteUpdates);
      }

      print(
          'Sync completed. Local updates: ${localUpdates.length}, Remote updates: ${remoteUpdates.length}');
    } catch (e) {
      print('Error syncing user stats: $e');
    }

    notifyListeners();
  }

  /// Enhanced stats insertion with hybrid batch/individual approach
  Future<void> _insertStatsWithFallback(List<UserStatsModel> stats) async {
    if (stats.isEmpty) return;

    print(
        'Attempting to insert ${stats.length} stats with enhanced error handling');

    // Phase 1: Try fast batch insert
    final batchResult =
        await db.userStatsDao.insertOrUpdateMultipleStatsWithFeedback(stats);

    if (batchResult.success) {
      print('Successfully inserted all ${stats.length} stats in batch');
      return;
    }

    print('Batch insert failed, falling back to individual processing');
    print('Failed stats count: ${batchResult.failedStats.length}');

    // Phase 2: Validate recipe references for failed stats
    final failedRecipeIds =
        batchResult.failedStats.map((s) => s.recipeId).toSet().toList();
    final recipeValidation =
        await db.userStatsDao.validateRecipeReferences(failedRecipeIds);

    final validStats = <UserStatsModel>[];
    final individualProcessingStats = <UserStatsModel>[];
    int skippedCount = 0;

    for (final stat in batchResult.failedStats) {
      final recipeExists = recipeValidation[stat.recipeId] ?? false;

      if (recipeExists) {
        // Recipe exists, include in batch retry
        validStats.add(stat);
      } else {
        // Recipe doesn't exist, handle individually with fallback
        print(
            'Stat ${stat.statUuid} references missing recipe ${stat.recipeId}');
        individualProcessingStats.add(stat);
      }
    }

    // Phase 3: Retry batch insert with valid stats
    if (validStats.isNotEmpty) {
      print('Retrying batch insert with ${validStats.length} valid stats');
      try {
        await db.userStatsDao.insertOrUpdateMultipleStats(validStats);
        print(
            'Successfully inserted ${validStats.length} valid stats in batch retry');
      } catch (e) {
        print(
            'Batch retry also failed, falling back to individual processing for valid stats');
        individualProcessingStats.addAll(validStats);
      }
    }

    // Phase 4: Individual processing for truly problematic stats
    if (individualProcessingStats.isNotEmpty) {
      print(
          'Processing ${individualProcessingStats.length} stats individually');

      for (final stat in individualProcessingStats) {
        try {
          await db.userStatsDao.insertUserStatWithFallback(stat);
          print('Successfully processed stat ${stat.statUuid} individually');
        } catch (e) {
          print('Failed to process stat ${stat.statUuid} individually: $e');
          print('Original recipe ID: ${stat.recipeId}');
          skippedCount++;
        }
      }
    }

    print('Stats insertion summary:');
    print('- Total attempted: ${stats.length}');
    print(
        '- Batch successful: ${stats.length - batchResult.failedStats.length}');
    print('- Individual processing: ${individualProcessingStats.length}');
    print('- Skipped: $skippedCount');
  }

  bool _isRemoteNewer(VersionVector local, VersionVector remote) {
    return remote.isNewerThan(local);
  }

  bool _isLocalNewer(VersionVector local, VersionVector remote) {
    return local.isNewerThan(remote);
  }

  Future<List<UserStatsModel>> _fetchFullRemoteStats(
      List<String> statUuids) async {
    final response = await Supabase.instance.client
        .from('user_stats')
        .select()
        .inFilter('stat_uuid', statUuids);
    return (response as List<dynamic>)
        .map((json) => _jsonToUserStatsModel(json))
        .toList();
  }

  Future<void> _updateRemoteStats(List<UserStatsModel> stats) async {
    try {
      final updates = stats.map((stat) {
        final data = _userStatModelToJson(stat);
        data['user_id'] = Supabase.instance.client.auth.currentUser!.id;
        return data;
      }).toList();

      await Supabase.instance.client
          .from('user_stats')
          .upsert(updates)
          .timeout(const Duration(seconds: 3)); // Added 3-second timeout
    } catch (e) {
      if (e is TimeoutException) {
        print('Supabase operation timed out: $e');
        // Handle the timeout if needed
      } else {
        print('Error updating user stats in Supabase: $e');
        // Handle other exceptions
      }
    }
  }

  // Helper method to convert UserStatsModel to JSON
  Map<String, dynamic> _userStatModelToJson(UserStatsModel model) {
    return {
      'stat_uuid': model.statUuid,
      'recipe_id': model.recipeId,
      'coffee_amount': model.coffeeAmount,
      'water_amount': model.waterAmount,
      'sweetness_slider_position': model.sweetnessSliderPosition,
      'strength_slider_position': model.strengthSliderPosition,
      'brewing_method_id': model.brewingMethodId,
      'created_at': model.createdAt.toUtc().toIso8601String(),
      'notes': model.notes,
      'is_marked': model.isMarked,
      'coffee_beans_uuid': model.coffeeBeansUuid,
      'version_vector': model.versionVector,
      'is_deleted': model.isDeleted, // Include isDeleted field in JSON
    };
  }

  // Helper method to convert JSON to UserStatsModel
  UserStatsModel _jsonToUserStatsModel(Map<String, dynamic> json) {
    return UserStatsModel(
      statUuid: json['stat_uuid'],
      recipeId: json['recipe_id'],
      coffeeAmount: (json['coffee_amount'] as num).toDouble(),
      waterAmount: (json['water_amount'] as num).toDouble(),
      sweetnessSliderPosition: json['sweetness_slider_position'],
      strengthSliderPosition: json['strength_slider_position'],
      brewingMethodId: json['brewing_method_id'],
      createdAt: DateTime.parse(json['created_at']),
      notes: json['notes'],
      isMarked: json['is_marked'],
      coffeeBeansUuid: json['coffee_beans_uuid'],
      versionVector: json['version_vector'],
      isDeleted: json['is_deleted'] ?? false, // Handle isDeleted field
    );
  }
}
