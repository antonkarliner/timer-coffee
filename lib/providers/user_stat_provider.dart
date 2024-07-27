import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import '../database/database.dart';
import 'coffee_beans_provider.dart';

class UserStatProvider extends ChangeNotifier {
  final AppDatabase db;
  final CoffeeBeansProvider coffeeBeansProvider;

  UserStatProvider(this.db, this.coffeeBeansProvider);

  Future<void> insertUserStat({
    required String userId,
    required String recipeId,
    required double coffeeAmount,
    required double waterAmount,
    required int sweetnessSliderPosition,
    required int strengthSliderPosition,
    required String brewingMethodId,
    String? notes,
    String? beans,
    String? roaster,
    int? coffeeBeansId,
    bool isMarked = false,
  }) async {
    await db.userStatsDao.insertUserStat(
      userId: userId,
      recipeId: recipeId,
      coffeeAmount: coffeeAmount,
      waterAmount: waterAmount,
      sweetnessSliderPosition: sweetnessSliderPosition,
      strengthSliderPosition: strengthSliderPosition,
      brewingMethodId: brewingMethodId,
      notes: notes,
      beans: beans,
      roaster: roaster,
      coffeeBeansId: coffeeBeansId,
      isMarked: isMarked,
    );
    notifyListeners();
  }

  Future<void> updateUserStat({
    required int id,
    String? userId,
    String? recipeId,
    double? coffeeAmount,
    double? waterAmount,
    int? sweetnessSliderPosition,
    int? strengthSliderPosition,
    String? brewingMethodId,
    String? notes,
    String? beans,
    String? roaster,
    int? coffeeBeansId,
    bool? isMarked,
  }) async {
    print(
        'UserStatProvider updateUserStat called with id: $id, coffeeBeansId: $coffeeBeansId'); // Print the parameters

    await db.userStatsDao.updateUserStat(
      id: id,
      userId: userId,
      recipeId: recipeId,
      coffeeAmount: coffeeAmount,
      waterAmount: waterAmount,
      sweetnessSliderPosition: sweetnessSliderPosition,
      strengthSliderPosition: strengthSliderPosition,
      brewingMethodId: brewingMethodId,
      notes: notes,
      beans: beans,
      roaster: roaster,
      coffeeBeansId: coffeeBeansId,
      isMarked: isMarked,
    );
    print(
        'UserStatProvider updateUserStat completed for id: $id'); // Print after the update
    notifyListeners();
  }

  Future<List<UserStatsModel>> fetchAllUserStats() async {
    return await db.userStatsDao.fetchAllStats();
  }

  Future<UserStatsModel?> fetchUserStatById(int id) async {
    return await db.userStatsDao.fetchStatById(id);
  }

  Future<void> deleteUserStat(int id) async {
    await db.userStatsDao.deleteUserStat(id);
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
}
