import 'dart:async';

import 'package:coffee_timer/config/network_timeouts.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import '../database/database.dart';
import 'coffee_beans_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

class UserStatProvider extends ChangeNotifier {
  final Uuid _uuid = Uuid();
  final AppDatabase db;
  final CoffeeBeansProvider coffeeBeansProvider;
  final String deviceId;

  static const int _supabasePageSize = 500;

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
    String? grindSize,
    double? waterTemp,
    int? tasteBalance,
    int? entrySource,
    String? tags,
    String? statUuid,
    DateTime? createdAt,
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
      createdAt: createdAt ?? DateTime.now().toUtc(),
      notes: notes,
      beans: beans,
      roaster: roaster,
      rating: rating,
      coffeeBeansId: coffeeBeansId,
      isMarked: isMarked,
      coffeeBeansUuid: coffeeBeansUuid,
      grindSize: grindSize,
      waterTemp: waterTemp,
      tasteBalance: tasteBalance,
      entrySource: entrySource,
      tags: tags,
      versionVector: versionVector,
      isDeleted: false,
    );

    await db.userStatsDao.insertUserStat(newStat);

    // Remote sync is best-effort and fire-and-forget: the local DB is the source
    // of truth, and the brew-finish flow (and any other caller) must never block
    // on the network. A failed/slow sync is reconciled later by syncNewUserStats().
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      final supabaseData = _userStatModelToJson(newStat);
      supabaseData['user_id'] = user.id;
      unawaited(() async {
        try {
          await Supabase.instance.client
              .from('user_stats')
              .upsert(supabaseData)
              .timeout(NetworkTimeouts.handshake);
        } on TimeoutException catch (e) {
          AppLogger.error('Supabase request timed out', errorObject: e);
        } catch (e) {
          AppLogger.error(
            'Error syncing new user stat to Supabase',
            errorObject: e,
          );
        }
      }());
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
    String? grindSize,
    double? tdsPercent,
    double? extractionYieldPercent,
    double? waterTemp,
    int? tasteBalance,
    int? entrySource,
    String? tags,
    bool clearBeans = false,
  }) async {
    AppLogger.debug(
      'updateUserStat called with statUuid: ${AppLogger.sanitize(statUuid)}, coffeeBeansUuid: ${AppLogger.sanitize(coffeeBeansUuid)}',
    );

    final currentStat = await db.userStatsDao.fetchStatByUuid(statUuid);
    if (currentStat == null) {
      AppLogger.error(
        'Stat not found for UUID',
        errorObject: AppLogger.sanitize(statUuid),
      );
      throw Exception('Stat not found');
    }

    AppLogger.debug('Current stat: ${AppLogger.sanitize(currentStat)}');

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
      grindSize: grindSize,
      tdsPercent: tdsPercent,
      extractionYieldPercent: extractionYieldPercent,
      waterTemp: waterTemp,
      tasteBalance: tasteBalance,
      entrySource: entrySource,
      tags: tags,
      versionVector: newVector.toString(),
    );

    if (clearBeans) {
      AppLogger.debug(
        'Clearing beans for stat ${AppLogger.sanitize(statUuid)}',
      );
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
        grindSize: updatedStat.grindSize,
        tdsPercent: updatedStat.tdsPercent,
        extractionYieldPercent: updatedStat.extractionYieldPercent,
        waterTemp: updatedStat.waterTemp,
        tasteBalance: updatedStat.tasteBalance,
        entrySource: updatedStat.entrySource,
        tags: updatedStat.tags,
        versionVector: updatedStat.versionVector,
        isDeleted: currentStat.isDeleted,
      );
    }

    AppLogger.debug('Updated stat: ${AppLogger.sanitize(updatedStat)}');

    await db.userStatsDao.updateUserStat(updatedStat);
    AppLogger.debug('Database updated');

    // Force a refresh of the stat
    final refreshedStat = await db.userStatsDao.fetchStatByUuid(statUuid);
    AppLogger.debug(
      'Refreshed stat after update: ${AppLogger.sanitize(refreshedStat)}',
    );

    // Remote sync is best-effort and fire-and-forget — never block the caller on
    // the network. Local DB is the source of truth; syncNewUserStats() reconciles.
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous && refreshedStat != null) {
      final supabaseData = _userStatModelToJson(refreshedStat);
      supabaseData['user_id'] = user.id;
      unawaited(() async {
        try {
          await Supabase.instance.client
              .from('user_stats')
              .upsert(supabaseData, onConflict: 'user_id,stat_uuid')
              .timeout(NetworkTimeouts.handshake);
          AppLogger.debug('Supabase updated');
        } on TimeoutException catch (e) {
          AppLogger.error('Supabase request timed out', errorObject: e);
        } catch (e) {
          AppLogger.error(
            'Error syncing updated user stat to Supabase',
            errorObject: e,
          );
        }
      }());
    }

    notifyListeners();
    AppLogger.debug('notifyListeners called');
  }

  Future<void> updateDiaryAmounts({
    required String statUuid,
    required double coffeeAmount,
    required double waterAmount,
  }) async {
    final currentStat = await db.userStatsDao.fetchStatByUuid(statUuid);
    if (currentStat == null) {
      throw Exception('Stat not found');
    }

    final isManualEntry = currentStat.entrySource == 1;
    final updatedCoffeeAmount = isManualEntry
        ? coffeeAmount
        : currentStat.coffeeAmount;
    final updatedWaterAmount = isManualEntry
        ? waterAmount
        : currentStat.waterAmount;
    final amountsChanged =
        updatedCoffeeAmount != currentStat.coffeeAmount ||
        updatedWaterAmount != currentStat.waterAmount;
    final doseDelta = updatedCoffeeAmount - currentStat.coffeeAmount;
    BeanWeightAdjustmentResult? inventoryAdjustment;

    if (isManualEntry &&
        currentStat.coffeeBeansUuid != null &&
        doseDelta != 0) {
      inventoryAdjustment = await coffeeBeansProvider
          .adjustBeanWeightForDoseDelta(
            currentStat.coffeeBeansUuid!,
            doseDelta,
          );
      if (inventoryAdjustment.status == BeanWeightAdjustmentStatus.failed) {
        final error = inventoryAdjustment.error!;
        final stackTrace = inventoryAdjustment.stackTrace;
        if (stackTrace != null) {
          Error.throwWithStackTrace(
            BeanWeightAdjustmentException(error),
            stackTrace,
          );
        }
        throw BeanWeightAdjustmentException(error);
      }
    }

    final updatedStat = _rebuildDiaryStat(
      currentStat,
      coffeeAmount: updatedCoffeeAmount,
      waterAmount: updatedWaterAmount,
      tdsPercent: amountsChanged ? null : _unchangedDiaryField,
      extractionYieldPercent: amountsChanged ? null : _unchangedDiaryField,
    );

    try {
      await _persistDiaryStat(updatedStat);
    } catch (statError, statStackTrace) {
      if (inventoryAdjustment?.status == BeanWeightAdjustmentStatus.adjusted &&
          inventoryAdjustment!.appliedDoseDelta != 0) {
        final compensation = await coffeeBeansProvider
            .adjustBeanWeightForDoseDelta(
              currentStat.coffeeBeansUuid!,
              -inventoryAdjustment.appliedDoseDelta,
            );
        if (compensation.status != BeanWeightAdjustmentStatus.adjusted ||
            compensation.appliedDoseDelta !=
                -inventoryAdjustment.appliedDoseDelta) {
          AppLogger.error(
            'Diary stat update failed before inventory compensation',
            errorObject: statError,
            stackTrace: statStackTrace,
          );
          AppLogger.error(
            'Inventory compensation also failed',
            errorObject:
                compensation.error ??
                StateError('Bean inventory is no longer tracked'),
            stackTrace: compensation.stackTrace,
          );
        }
      }
      Error.throwWithStackTrace(statError, statStackTrace);
    }
  }

  Future<void> updateDiaryGrindSize({
    required String statUuid,
    required String grindSize,
  }) async {
    final currentStat = await _fetchDiaryStat(statUuid);
    await _persistDiaryStat(
      _rebuildDiaryStat(currentStat, grindSize: grindSize),
    );
  }

  Future<void> updateDiaryWaterTemperature({
    required String statUuid,
    required double? waterTemp,
  }) async {
    final currentStat = await _fetchDiaryStat(statUuid);
    await _persistDiaryStat(
      _rebuildDiaryStat(currentStat, waterTemp: waterTemp),
    );
  }

  Future<void> updateDiaryTasteBalance({
    required String statUuid,
    required int? tasteBalance,
  }) async {
    final currentStat = await _fetchDiaryStat(statUuid);
    await _persistDiaryStat(
      _rebuildDiaryStat(currentStat, tasteBalance: tasteBalance),
    );
  }

  Future<void> updateDiaryNotes({
    required String statUuid,
    required String notes,
  }) async {
    final currentStat = await _fetchDiaryStat(statUuid);
    await _persistDiaryStat(_rebuildDiaryStat(currentStat, notes: notes));
  }

  Future<void> updateDiaryTags({
    required String statUuid,
    required String? tags,
  }) async {
    final currentStat = await _fetchDiaryStat(statUuid);
    await _persistDiaryStat(_rebuildDiaryStat(currentStat, tags: tags));
  }

  Future<void> updateDiaryRating({
    required String statUuid,
    required double? rating,
  }) async {
    final currentStat = await _fetchDiaryStat(statUuid);
    await _persistDiaryStat(_rebuildDiaryStat(currentStat, rating: rating));
  }

  Future<void> updateDiaryBean({
    required String statUuid,
    required String? nextBeanUuid,
  }) async {
    final currentStat = await _fetchDiaryStat(statUuid);
    if (nextBeanUuid != null) {
      final targetBean = await coffeeBeansProvider.fetchCoffeeBeansByUuid(
        nextBeanUuid,
      );
      if (targetBean == null) {
        throw StateError('Coffee beans not found');
      }
    }

    final oldBeanUuid = currentStat.coffeeBeansUuid;
    if (oldBeanUuid == nextBeanUuid) return;

    final completedAdjustments =
        <({String beanUuid, BeanWeightAdjustmentResult result})>[];

    Future<void> adjust(String beanUuid, double doseDelta) async {
      final result = await coffeeBeansProvider.adjustBeanWeightForDoseDelta(
        beanUuid,
        doseDelta,
      );
      if (result.status == BeanWeightAdjustmentStatus.failed) {
        final error = result.error!;
        final stackTrace = result.stackTrace;
        if (stackTrace != null) {
          Error.throwWithStackTrace(
            BeanWeightAdjustmentException(error),
            stackTrace,
          );
        }
        throw BeanWeightAdjustmentException(error);
      }
      completedAdjustments.add((beanUuid: beanUuid, result: result));
    }

    try {
      if (oldBeanUuid != null) {
        await adjust(oldBeanUuid, -currentStat.coffeeAmount);
      }
      if (nextBeanUuid != null) {
        await adjust(nextBeanUuid, currentStat.coffeeAmount);
      }
      await _persistDiaryStat(
        _rebuildDiaryStat(currentStat, coffeeBeansUuid: nextBeanUuid),
      );
    } catch (error, stackTrace) {
      for (final adjustment in completedAdjustments.reversed) {
        final appliedDoseDelta = adjustment.result.appliedDoseDelta;
        if (adjustment.result.status != BeanWeightAdjustmentStatus.adjusted ||
            appliedDoseDelta == 0) {
          continue;
        }
        final compensation = await coffeeBeansProvider
            .adjustBeanWeightForDoseDelta(
              adjustment.beanUuid,
              -appliedDoseDelta,
            );
        if (compensation.status != BeanWeightAdjustmentStatus.adjusted ||
            compensation.appliedDoseDelta != -appliedDoseDelta) {
          AppLogger.error(
            'Diary bean association failed before inventory compensation',
            errorObject: error,
            stackTrace: stackTrace,
          );
          AppLogger.error(
            'Bean association inventory compensation also failed',
            errorObject:
                compensation.error ??
                StateError('Bean inventory is no longer tracked'),
            stackTrace: compensation.stackTrace,
          );
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<UserStatsModel> _fetchDiaryStat(String statUuid) async {
    final stat = await db.userStatsDao.fetchStatByUuid(statUuid);
    if (stat == null) throw Exception('Stat not found');
    return stat;
  }

  static const Object _unchangedDiaryField = Object();

  UserStatsModel _rebuildDiaryStat(
    UserStatsModel currentStat, {
    double? coffeeAmount,
    double? waterAmount,
    Object? grindSize = _unchangedDiaryField,
    Object? waterTemp = _unchangedDiaryField,
    Object? tasteBalance = _unchangedDiaryField,
    Object? notes = _unchangedDiaryField,
    Object? rating = _unchangedDiaryField,
    Object? coffeeBeansUuid = _unchangedDiaryField,
    Object? tags = _unchangedDiaryField,
    Object? tdsPercent = _unchangedDiaryField,
    Object? extractionYieldPercent = _unchangedDiaryField,
  }) {
    final newVector = VersionVector.fromString(
      currentStat.versionVector,
    ).increment();
    return UserStatsModel(
      statUuid: currentStat.statUuid,
      id: currentStat.id,
      recipeId: currentStat.recipeId,
      coffeeAmount: coffeeAmount ?? currentStat.coffeeAmount,
      waterAmount: waterAmount ?? currentStat.waterAmount,
      sweetnessSliderPosition: currentStat.sweetnessSliderPosition,
      strengthSliderPosition: currentStat.strengthSliderPosition,
      brewingMethodId: currentStat.brewingMethodId,
      createdAt: currentStat.createdAt,
      notes: identical(notes, _unchangedDiaryField)
          ? currentStat.notes
          : notes as String?,
      beans: currentStat.beans,
      roaster: currentStat.roaster,
      rating: identical(rating, _unchangedDiaryField)
          ? currentStat.rating
          : rating as double?,
      coffeeBeansId: currentStat.coffeeBeansId,
      isMarked: currentStat.isMarked,
      coffeeBeansUuid: identical(coffeeBeansUuid, _unchangedDiaryField)
          ? currentStat.coffeeBeansUuid
          : coffeeBeansUuid as String?,
      grindSize: identical(grindSize, _unchangedDiaryField)
          ? currentStat.grindSize
          : grindSize as String?,
      tdsPercent: identical(tdsPercent, _unchangedDiaryField)
          ? currentStat.tdsPercent
          : tdsPercent as double?,
      extractionYieldPercent:
          identical(extractionYieldPercent, _unchangedDiaryField)
          ? currentStat.extractionYieldPercent
          : extractionYieldPercent as double?,
      waterTemp: identical(waterTemp, _unchangedDiaryField)
          ? currentStat.waterTemp
          : waterTemp as double?,
      tasteBalance: identical(tasteBalance, _unchangedDiaryField)
          ? currentStat.tasteBalance
          : tasteBalance as int?,
      entrySource: currentStat.entrySource,
      tags: identical(tags, _unchangedDiaryField)
          ? currentStat.tags
          : tags as String?,
      versionVector: newVector.toString(),
      isDeleted: currentStat.isDeleted,
    );
  }

  Future<void> _persistDiaryStat(UserStatsModel updatedStat) async {
    await db.userStatsDao.updateUserStat(updatedStat);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      final supabaseData = _userStatModelToJson(updatedStat)
        ..['user_id'] = user.id;
      unawaited(() async {
        try {
          await Supabase.instance.client
              .from('user_stats')
              .upsert(supabaseData, onConflict: 'user_id,stat_uuid')
              .timeout(NetworkTimeouts.handshake);
        } on TimeoutException catch (error) {
          AppLogger.error('Supabase request timed out', errorObject: error);
        } catch (error) {
          AppLogger.error(
            'Error syncing focused diary update to Supabase',
            errorObject: error,
          );
        }
      }());
    }

    notifyListeners();
  }

  Future<void> deleteUserStat(String statUuid) async {
    final currentStat = await db.userStatsDao.fetchStatByUuid(statUuid);
    if (currentStat == null) {
      AppLogger.error(
        'Stat not found for UUID',
        errorObject: AppLogger.sanitize(statUuid),
      );
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

    // Remote sync is best-effort and fire-and-forget — never block the caller on
    // the network. Local DB is the source of truth; syncNewUserStats() reconciles.
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && !user.isAnonymous) {
      final supabaseData = _userStatModelToJson(updatedStat);
      supabaseData['user_id'] = user.id;
      unawaited(() async {
        try {
          await Supabase.instance.client
              .from('user_stats')
              .upsert(supabaseData, onConflict: 'user_id,stat_uuid')
              .timeout(NetworkTimeouts.handshake);
        } on TimeoutException catch (e) {
          AppLogger.error('Supabase operation timed out', errorObject: e);
        } catch (e) {
          AppLogger.error(
            'Error marking user stat as deleted in Supabase',
            errorObject: e,
          );
        }
      }());
    }

    notifyListeners();
  }

  Future<List<UserStatsModel>> fetchAllUserStats() async {
    return await db.userStatsDao.fetchAllStats();
  }

  Future<List<DiaryEntry>> fetchDiaryEntries(String locale) =>
      db.userStatsDao.fetchDiaryEntries(locale);

  Future<List<({String brewingMethodId, String methodName, int count})>>
  topMethodsLast90Days(String locale) =>
      db.userStatsDao.topMethodsLast90Days(locale);

  Future<UserStatsModel?> fetchUserStatByUuid(String statUuid) async {
    return await db.userStatsDao.fetchStatByUuid(statUuid);
  }

  Future<GrindSuggestionResult?> latestGrindSuggestionForBeanAndMethod(
    String beansUuid,
    String brewingMethodId,
  ) => db.userStatsDao.latestGrindSuggestionForBeanAndMethod(
    beansUuid,
    brewingMethodId,
  );

  Future<List<UserStatsModel>> fetchStatsByBeanUuid(String beansUuid) =>
      db.userStatsDao.fetchStatsByBeanUuid(beansUuid);

  /// Deduped, first-seen-order list of tags used across diary entries, for
  /// tag-editor autocomplete.
  Future<List<String>> fetchAllDistinctTags() =>
      db.userStatsDao.fetchAllDistinctTags();

  /// Recent non-deleted brews, newest first, for "prefill from history"
  /// pickers (e.g. the extraction calculator).
  Future<List<UserStatsModel>> fetchRecentStats({int limit = 20}) =>
      db.userStatsDao.fetchRecentStats(limit: limit);

  /// Estimates how many brews remain in a bag based on the user's median dose.
  ///
  /// Prefers the median dose from this specific bean's brews (≥3 samples);
  /// falls back to the user's median dose across all brews in the trailing
  /// 90 days (≥3 samples). Returns null when no reliable median is available
  /// or when [packageWeightGrams] is null/non-positive, or when the rounded
  /// estimate would be 0.
  Future<int?> estimateBrewsLeft({
    required String beansUuid,
    required double? packageWeightGrams,
  }) async {
    if (packageWeightGrams == null || packageWeightGrams <= 0) return null;
    final perBean = await db.userStatsDao.medianCoffeeAmountForBean(
      beansUuid,
      minBrews: 3,
    );
    final dose =
        perBean ??
        await db.userStatsDao.medianCoffeeAmountSince(
          DateTime.now().toUtc().subtract(const Duration(days: 90)),
          minBrews: 3,
        );
    if (dose == null || dose <= 0) return null;
    final estimate = (packageWeightGrams / dose).round();
    return estimate > 0 ? estimate : null;
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
      AppLogger.debug('No user logged in or user is anonymous');
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
        await Supabase.instance.client
            .from('user_stats')
            .upsert(batch)
            .timeout(NetworkTimeouts.smallSync);
        AppLogger.debug('Uploaded batch ${i ~/ batchSize + 1}');
      } on TimeoutException catch (e) {
        AppLogger.error('Supabase batch upload timed out', errorObject: e);
        // Continue gracefully - some stats may sync later
      } catch (e) {
        AppLogger.error(
          'Error uploading batch ${i ~/ batchSize + 1}',
          errorObject: e,
        );
      }
    }

    AppLogger.debug('Successfully uploaded ${statsData.length} stats');
  }

  Future<void> batchDownloadUserStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      AppLogger.debug('No user logged in or user is anonymous');
      return;
    }

    final remoteStats = <UserStatsModel>[];
    var from = 0;

    try {
      while (true) {
        final response = await Supabase.instance.client
            .from('user_stats')
            .select()
            .eq('user_id', user.id)
            .range(from, from + _supabasePageSize - 1)
            .timeout(NetworkTimeouts.smallSync);

        final batch = (response as List<dynamic>)
            .map((json) => _jsonToUserStatsModel(json))
            .toList();

        remoteStats.addAll(batch);

        if (batch.length < _supabasePageSize) {
          break; // last page reached
        }

        from += _supabasePageSize;
      }

      if (remoteStats.isNotEmpty) {
        await db.userStatsDao.insertOrUpdateMultipleStats(remoteStats);
      }
      AppLogger.debug(
        'Downloaded and updated ${remoteStats.length} stats via pagination',
      );
    } on TimeoutException catch (e) {
      AppLogger.error('Supabase stats download timed out', errorObject: e);
      // Continue with local data if remote fetch fails
    } catch (e) {
      AppLogger.error('Error downloading user stats', errorObject: e);
    }
  }

  Future<void> syncUserStats() async {
    await syncNewUserStats();
  }

  // Keep this method for backward compatibility
  Future<void> deleteUserStatById(int id) async {
    final stat = await fetchUserStatById(id);
    if (stat != null) {
      await deleteUserStat(stat.statUuid);
    }
  }

  Future<double> fetchBrewedCoffeeAmountForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    return await db.userStatsDao.fetchBrewedCoffeeAmount(start, end);
  }

  Future<List<String>> fetchTopRecipeIdsForPeriod(
    DateTime start,
    DateTime end,
  ) async {
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
      AppLogger.debug('No UserStats records need updating.');
      return;
    }

    List<UserStatsCompanion> updates = [];

    for (final stat in statsToUpdate) {
      if (stat.coffeeBeansId != null) {
        final coffeeBeans = await coffeeBeansProvider.fetchCoffeeBeansById(
          stat.coffeeBeansId!,
        );
        if (coffeeBeans != null) {
          updates.add(
            UserStatsCompanion(
              id: Value(stat.id),
              coffeeBeansUuid: Value(coffeeBeans.beansUuid),
            ),
          );
        } else {
          AppLogger.warning(
            'Coffee beans not found or missing UUID for ID: ${AppLogger.sanitize(stat.coffeeBeansId)}',
          );
        }
      }
    }

    if (updates.isNotEmpty) {
      await db.userStatsDao.batchUpdateCoffeeBeansUuids(updates);
      AppLogger.debug(
        'Updated ${updates.length} UserStats records with coffee beans UUIDs.',
      );
    }

    notifyListeners();
  }

  Future<void> backfillMissingStatUuids() async {
    final statsToUpdate = await db.userStatsDao
        .fetchStatsNeedingStatUuidUpdate();

    if (statsToUpdate.isEmpty) {
      AppLogger.debug('No UserStats records need updating.');
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

      updates.add(
        UserStatsCompanion(id: Value(stat.id), statUuid: Value(newUuid)),
      );
    }

    if (updates.isNotEmpty) {
      await db.userStatsDao.batchUpdateStatUuids(updates);
      AppLogger.debug(
        'Updated ${updates.length} UserStats records with new UUIDv7s.',
      );
    }

    notifyListeners();
  }

  Future<void> syncNewUserStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      AppLogger.debug('No user logged in or user is anonymous');
      return;
    }

    try {
      // Fetch all local stats, including deleted ones
      final localStats = await db.userStatsDao
          .fetchAllStatsWithVersionVectors();

      AppLogger.debug('Local stats present: ${localStats.length}');

      // Prepare a map of statUuid to localStat for quick lookup
      final localStatsMap = {for (var stat in localStats) stat.statUuid: stat};

      // Fetch all remote stats, including deleted ones, with pagination
      final remoteStatsInfo =
          <({String statUuid, String versionVector, bool isDeleted})>[];
      var from = 0;

      while (true) {
        final response = await Supabase.instance.client
            .from('user_stats')
            .select('stat_uuid, version_vector, is_deleted')
            .eq('user_id', user.id)
            .range(from, from + _supabasePageSize - 1)
            .timeout(NetworkTimeouts.smallSync);

        final batch = (response as List<dynamic>)
            .map(
              (json) => (
                statUuid: json['stat_uuid'] as String,
                versionVector: json['version_vector'] as String,
                isDeleted: json['is_deleted'] as bool,
              ),
            )
            .toList();

        remoteStatsInfo.addAll(batch);

        if (batch.length < _supabasePageSize) {
          break; // last page reached
        }

        from += _supabasePageSize;
      }

      AppLogger.debug(
        'Remote stats metadata fetched: ${remoteStatsInfo.length} records',
      );

      // Prepare lists for updates
      final List<String> localUpdates = [];
      final List<UserStatsModel> remoteUpdates = [];

      final nonDeletedRemote = remoteStatsInfo
          .where((r) => r.isDeleted == false)
          .length;
      final deletedRemote = remoteStatsInfo.length - nonDeletedRemote;
      AppLogger.debug(
        'Remote stats split -> non-deleted: $nonDeletedRemote, deleted: $deletedRemote',
      );

      // Fast path: fresh install / empty local DB -> download all non-deleted remote stats
      if (localStats.isEmpty && nonDeletedRemote > 0) {
        final idsToFetch = remoteStatsInfo
            .where((r) => r.isDeleted == false)
            .map((r) => r.statUuid)
            .toList();

        final fullRemote = await _fetchFullRemoteStats(idsToFetch);
        AppLogger.debug(
          'Fresh restore: fetching all remote stats (${fullRemote.length})',
        );
        await _insertStatsWithFallback(fullRemote);
        notifyListeners();
        return;
      }

      // Compare version vectors and handle deletions
      for (final remoteStat in remoteStatsInfo) {
        final localStat = localStatsMap[remoteStat.statUuid];
        final remoteVersionVector = VersionVector.fromString(
          remoteStat.versionVector,
        );

        if (localStat == null) {
          if (!remoteStat.isDeleted) {
            // Stat doesn't exist locally and is not deleted remotely, need to fetch from remote
            localUpdates.add(remoteStat.statUuid);
          }
          // If the remote stat is deleted and doesn't exist locally, no action needed
        } else {
          final localVersionVector = VersionVector.fromString(
            localStat.versionVector,
          );

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
      final newLocalStats = localStats.where(
        (stat) =>
            !remoteStatsInfo.any((remote) => remote.statUuid == stat.statUuid),
      );
      remoteUpdates.addAll(newLocalStats);

      // Perform local updates with enhanced error handling
      if (localUpdates.isNotEmpty) {
        final updatedRemoteStats = await _fetchFullRemoteStats(localUpdates);
        AppLogger.debug(
          'Fetched ${updatedRemoteStats.length} full remote stats for local update',
        );
        await _insertStatsWithFallback(updatedRemoteStats);
      }

      // Perform remote updates with a timeout
      if (remoteUpdates.isNotEmpty) {
        await _updateRemoteStats(remoteUpdates);
      }

      AppLogger.debug(
        'Sync completed. Remote metadata: ${remoteStatsInfo.length}, Local updates (downloaded): ${localUpdates.length}, Remote updates (uploaded): ${remoteUpdates.length}',
      );
    } catch (e) {
      AppLogger.error('Error syncing user stats', errorObject: e);
    }

    notifyListeners();
  }

  /// Enhanced stats insertion with hybrid batch/individual approach
  Future<void> _insertStatsWithFallback(List<UserStatsModel> stats) async {
    if (stats.isEmpty) return;

    AppLogger.debug(
      'Attempting to insert ${stats.length} stats with enhanced error handling',
    );

    // Phase 1: Try fast batch insert
    final batchResult = await db.userStatsDao
        .insertOrUpdateMultipleStatsWithFeedback(stats);

    if (batchResult.success) {
      AppLogger.debug(
        'Successfully inserted all ${stats.length} stats in batch',
      );
      return;
    }

    AppLogger.debug(
      'Batch insert failed, falling back to individual processing',
    );
    AppLogger.debug('Failed stats count: ${batchResult.failedStats.length}');

    // Phase 2: Validate recipe references for failed stats
    final failedRecipeIds = batchResult.failedStats
        .map((s) => s.recipeId)
        .toSet()
        .toList();
    final recipeValidation = await db.userStatsDao.validateRecipeReferences(
      failedRecipeIds,
    );

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
        AppLogger.warning(
          'Stat ${AppLogger.sanitize(stat.statUuid)} references missing recipe ${AppLogger.sanitize(stat.recipeId)}',
        );
        individualProcessingStats.add(stat);
      }
    }

    // Phase 3: Retry batch insert with valid stats
    if (validStats.isNotEmpty) {
      AppLogger.debug(
        'Retrying batch insert with ${validStats.length} valid stats',
      );
      try {
        await db.userStatsDao.insertOrUpdateMultipleStats(validStats);
        AppLogger.debug(
          'Successfully inserted ${validStats.length} valid stats in batch retry',
        );
      } catch (e) {
        AppLogger.debug(
          'Batch retry also failed, falling back to individual processing for valid stats',
        );
        individualProcessingStats.addAll(validStats);
      }
    }

    // Phase 4: Individual processing for truly problematic stats
    if (individualProcessingStats.isNotEmpty) {
      AppLogger.debug(
        'Processing ${individualProcessingStats.length} stats individually',
      );

      for (final stat in individualProcessingStats) {
        try {
          await db.userStatsDao.insertUserStatWithFallback(stat);
          AppLogger.debug(
            'Successfully processed stat ${AppLogger.sanitize(stat.statUuid)} individually',
          );
        } catch (e) {
          AppLogger.error(
            'Failed to process stat ${AppLogger.sanitize(stat.statUuid)} individually',
            errorObject: e,
          );
          AppLogger.debug(
            'Original recipe ID: ${AppLogger.sanitize(stat.recipeId)}',
          );
          skippedCount++;
        }
      }
    }

    AppLogger.debug('Stats insertion summary:');
    AppLogger.debug('- Total attempted: ${stats.length}');
    AppLogger.debug(
      '- Batch successful: ${stats.length - batchResult.failedStats.length}',
    );
    AppLogger.debug(
      '- Individual processing: ${individualProcessingStats.length}',
    );
    AppLogger.debug('- Skipped: $skippedCount');
  }

  bool _isRemoteNewer(VersionVector local, VersionVector remote) {
    return remote.isNewerThan(local);
  }

  bool _isLocalNewer(VersionVector local, VersionVector remote) {
    return local.isNewerThan(remote);
  }

  Future<List<UserStatsModel>> _fetchFullRemoteStats(
    List<String> statUuids,
  ) async {
    try {
      final results = <UserStatsModel>[];
      const chunkSize = 200;

      for (var i = 0; i < statUuids.length; i += chunkSize) {
        final chunk = statUuids.skip(i).take(chunkSize).toList();

        try {
          final response = await Supabase.instance.client
              .from('user_stats')
              .select()
              .inFilter('stat_uuid', chunk)
              .timeout(NetworkTimeouts.smallSync);

          results.addAll(
            (response as List<dynamic>)
                .map((json) => _jsonToUserStatsModel(json))
                .toList(),
          );
        } on TimeoutException catch (e) {
          AppLogger.error(
            'Supabase remote stats fetch timed out for chunk',
            errorObject: e,
          );
        } catch (e) {
          AppLogger.error(
            'Error fetching full remote stats chunk',
            errorObject: e,
          );
        }
      }

      return results;
    } catch (e) {
      AppLogger.error('Error fetching full remote stats', errorObject: e);
      return [];
    }
  }

  Future<void> _updateRemoteStats(List<UserStatsModel> stats) async {
    const chunkSize = 200;

    for (var i = 0; i < stats.length; i += chunkSize) {
      final chunk = stats.skip(i).take(chunkSize).toList();

      try {
        final updates = chunk.map((stat) {
          final data = _userStatModelToJson(stat);
          data['user_id'] = Supabase.instance.client.auth.currentUser!.id;
          return data;
        }).toList();

        await Supabase.instance.client
            .from('user_stats')
            .upsert(updates)
            .timeout(NetworkTimeouts.smallSync);

        AppLogger.debug(
          'Uploaded ${chunk.length} stats to Supabase (chunk ${(i ~/ chunkSize) + 1})',
        );
      } catch (e) {
        if (e is TimeoutException) {
          AppLogger.error('Supabase operation timed out', errorObject: e);
          // Handle the timeout if needed
        } else {
          AppLogger.error(
            'Error updating user stats in Supabase',
            errorObject: e,
          );
          // Handle other exceptions
        }
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
      'beans': model.beans,
      'roaster': model.roaster,
      'rating': model.rating,
      'coffee_beans_id': model.coffeeBeansId,
      'is_marked': model.isMarked,
      'coffee_beans_uuid': model.coffeeBeansUuid,
      'grind_size': model.grindSize,
      'tds_percent': model.tdsPercent,
      'extraction_yield_percent': model.extractionYieldPercent,
      'water_temp': model.waterTemp,
      'taste_balance': model.tasteBalance,
      'entry_source': model.entrySource,
      'tags': model.tags,
      'version_vector': model.versionVector,
      'is_deleted': model.isDeleted,
    };
  }

  @visibleForTesting
  Map<String, dynamic> serializeUserStatForTesting(UserStatsModel model) =>
      _userStatModelToJson(model);

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
      beans: json['beans'],
      roaster: json['roaster'],
      rating: (json['rating'] as num?)?.toDouble(),
      coffeeBeansId: (json['coffee_beans_id'] as num?)?.toInt(),
      grindSize: json['grind_size'],
      tdsPercent: (json['tds_percent'] as num?)?.toDouble(),
      extractionYieldPercent: (json['extraction_yield_percent'] as num?)
          ?.toDouble(),
      waterTemp: (json['water_temp'] as num?)?.toDouble(),
      tasteBalance: (json['taste_balance'] as num?)?.toInt(),
      entrySource: (json['entry_source'] as num?)?.toInt(),
      tags: json['tags'] as String?,
      isMarked: json['is_marked'],
      coffeeBeansUuid: json['coffee_beans_uuid'],
      versionVector: json['version_vector'],
      isDeleted: json['is_deleted'] ?? false, // Handle isDeleted field
    );
  }
}
