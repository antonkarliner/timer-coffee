import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import '../database/database.dart';
import 'coffee_beans_provider.dart';
import 'package:uuid/uuid.dart';

class UserStatProvider extends ChangeNotifier {
  final Uuid _uuid = Uuid();
  final AppDatabase db;
  final CoffeeBeansProvider coffeeBeansProvider;

  UserStatProvider(this.db, this.coffeeBeansProvider);

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
    await db.userStatsDao.insertUserStat(
      statUuid: newStatUuid,
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
    );
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
    print(
        'UserStatProvider updateUserStat called with statUuid: $statUuid, coffeeBeansId: $coffeeBeansId, coffeeBeansUuid: $coffeeBeansUuid');

    final updateData = {
      if (recipeId != null) 'recipeId': recipeId,
      if (coffeeAmount != null) 'coffeeAmount': coffeeAmount,
      if (waterAmount != null) 'waterAmount': waterAmount,
      if (sweetnessSliderPosition != null)
        'sweetnessSliderPosition': sweetnessSliderPosition,
      if (strengthSliderPosition != null)
        'strengthSliderPosition': strengthSliderPosition,
      if (brewingMethodId != null) 'brewingMethodId': brewingMethodId,
      if (notes != null) 'notes': notes,
      if (beans != null) 'beans': beans,
      if (roaster != null) 'roaster': roaster,
      if (rating != null) 'rating': rating,
      'coffeeBeansId': coffeeBeansId,
      if (isMarked != null) 'isMarked': isMarked,
      'coffeeBeansUuid': coffeeBeansUuid,
    };

    await db.userStatsDao.updateUserStat(statUuid: statUuid, data: updateData);
    print('UserStatProvider updateUserStat completed for statUuid: $statUuid');
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
}
