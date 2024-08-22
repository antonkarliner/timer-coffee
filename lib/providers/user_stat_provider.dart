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
    );

    await db.userStatsDao.insertUserStat(newStat);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final supabaseData = _userStatModelToJson(newStat);
        supabaseData['user_id'] = user.id;
        await Supabase.instance.client.from('user_stats').upsert(supabaseData);
      } catch (e) {
        print('Error syncing new user stat to Supabase: $e');
        // TODO: Implement error handling or retry logic
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
  }) async {
    final currentStat = await db.userStatsDao.fetchStatByUuid(statUuid);
    if (currentStat == null) {
      throw Exception('Stat not found');
    }

    final currentVector = VersionVector.fromString(currentStat.versionVector);
    final newVector = currentVector.increment();

    final updatedStat = currentStat.copyWith(
      recipeId: recipeId ?? currentStat.recipeId,
      coffeeAmount: coffeeAmount ?? currentStat.coffeeAmount,
      waterAmount: waterAmount ?? currentStat.waterAmount,
      sweetnessSliderPosition:
          sweetnessSliderPosition ?? currentStat.sweetnessSliderPosition,
      strengthSliderPosition:
          strengthSliderPosition ?? currentStat.strengthSliderPosition,
      brewingMethodId: brewingMethodId ?? currentStat.brewingMethodId,
      notes: notes ?? currentStat.notes,
      beans: beans ?? currentStat.beans,
      roaster: roaster ?? currentStat.roaster,
      rating: rating ?? currentStat.rating,
      coffeeBeansId: coffeeBeansId ?? currentStat.coffeeBeansId,
      isMarked: isMarked ?? currentStat.isMarked,
      coffeeBeansUuid: coffeeBeansUuid ?? currentStat.coffeeBeansUuid,
      versionVector: newVector.toString(),
    );

    await db.userStatsDao.updateUserStat(updatedStat);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final supabaseData = _userStatModelToJson(updatedStat);
        supabaseData['user_id'] = user.id;
        await Supabase.instance.client
            .from('user_stats')
            .upsert(supabaseData, onConflict: 'user_id,stat_uuid');
      } catch (e) {
        print('Error syncing updated user stat to Supabase: $e');
        // TODO: Implement error handling or retry logic
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

  Future<void> deleteUserStat(String statUuid) async {
    await db.userStatsDao.deleteUserStat(statUuid);

    // Sync with Supabase if user is not anonymous
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        await Supabase.instance.client
            .from('user_stats')
            .delete()
            .eq('user_id', user.id)
            .eq('stat_uuid', statUuid);
      } catch (e) {
        print('Error deleting user stat from Supabase: $e');
      }
    }

    notifyListeners();
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
      // Fetch all local stats with their version vectors
      final localStats =
          await db.userStatsDao.fetchAllStatsWithVersionVectors();

      // Prepare a map of statUuid to version vector for quick lookup
      final localStatsMap = {
        for (var stat in localStats) stat.statUuid: stat.versionVector
      };

      // Fetch only the necessary information from remote stats
      final response = await Supabase.instance.client
          .from('user_stats')
          .select('stat_uuid, version_vector')
          .eq('user_id', user.id);

      final remoteStatsInfo = (response as List<dynamic>)
          .map((json) => (
                statUuid: json['stat_uuid'] as String,
                versionVector: json['version_vector'] as String
              ))
          .toList();

      // Prepare lists for updates
      final List<String> localUpdates = [];
      final List<String> remoteUpdates = [];

      // Compare version vectors
      for (final remoteStat in remoteStatsInfo) {
        final localVector = localStatsMap[remoteStat.statUuid];
        if (localVector == null) {
          // Stat doesn't exist locally, need to fetch from remote
          localUpdates.add(remoteStat.statUuid);
        } else if (_isRemoteNewer(VersionVector.fromString(localVector),
            VersionVector.fromString(remoteStat.versionVector))) {
          // Remote is newer, update local
          localUpdates.add(remoteStat.statUuid);
        } else if (_isLocalNewer(VersionVector.fromString(localVector),
            VersionVector.fromString(remoteStat.versionVector))) {
          // Local is newer, update remote
          remoteUpdates.add(remoteStat.statUuid);
        }
      }

      // Check for new local stats
      final newLocalStats = localStats.where((stat) =>
          !remoteStatsInfo.any((remote) => remote.statUuid == stat.statUuid));
      remoteUpdates.addAll(newLocalStats.map((stat) => stat.statUuid));

      // Perform updates
      if (localUpdates.isNotEmpty) {
        final updatedRemoteStats = await _fetchFullRemoteStats(localUpdates);
        await db.userStatsDao.insertOrUpdateMultipleStats(updatedRemoteStats);
      }

      if (remoteUpdates.isNotEmpty) {
        final updatedLocalStats =
            await db.userStatsDao.fetchStatsByUuids(remoteUpdates);
        await _updateRemoteStats(updatedLocalStats);
      }

      print(
          'Sync completed. Local updates: ${localUpdates.length}, Remote updates: ${remoteUpdates.length}');
    } catch (e) {
      print('Error syncing user stats: $e');
    }

    notifyListeners();
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
    final updates = stats
        .map((stat) => _userStatModelToJson(stat)
          ..['user_id'] = Supabase.instance.client.auth.currentUser!.id)
        .toList();
    await Supabase.instance.client.from('user_stats').upsert(updates);
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
    );
  }
}
