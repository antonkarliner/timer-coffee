import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../models/beans_stats_models.dart';

/// BeansStatsProvider
/// Thin pass-through over BeansStatsDao for bean-related analytics.
/// - No remote sync responsibilities
/// - Accepts time windows from the UI and returns aggregated results
class BeansStatsProvider with ChangeNotifier {
  final AppDatabase db;

  BeansStatsProvider(this.db);

  // Total distinct beans brewed in the period
  Future<int> getTotalBeansBrewedCount(DateTime start, DateTime end) {
    return db.beansStatsDao.fetchTotalBeansBrewedCount(start, end);
  }

  // Count of beans whose first brew falls inside the period
  Future<int> getNewBeansTriedCount(DateTime start, DateTime end) {
    return db.beansStatsDao.fetchNewBeansTriedCount(start, end);
  }

  // Distinct origins explored in the period
  Future<int> getOriginsExploredCount(DateTime start, DateTime end) {
    return db.beansStatsDao.fetchDistinctOriginsCount(start, end);
  }

  // Top origins by brew count
  Future<List<MapEntry<String, int>>> getTopOrigins(
    DateTime start,
    DateTime end, {
    int limit = 5,
  }) {
    return db.beansStatsDao.fetchOriginDistribution(start, end, limit: limit);
  }

  // Distinct regions explored in the period
  Future<int> getRegionsExploredCount(DateTime start, DateTime end) {
    return db.beansStatsDao.fetchDistinctRegionsCount(start, end);
  }

  // Top regions by brew count
  Future<List<MapEntry<String, int>>> getTopRegions(
    DateTime start,
    DateTime end, {
    int limit = 5,
  }) {
    return db.beansStatsDao.fetchRegionDistribution(start, end, limit: limit);
  }

  // Favorite roasters (by brew counts, min threshold)
  Future<List<MapEntry<String, int>>> getFavoriteRoasters(
    DateTime start,
    DateTime end, {
    int limit = 5,
    int minBrews = 2,
  }) {
    return db.beansStatsDao.fetchFavoriteRoasters(
      start,
      end,
      limit: limit,
      minBrews: minBrews,
    );
  }

  // Count of new roasters discovered in the period
  Future<int> getNewRoastersDiscovered(DateTime start, DateTime end) {
    return db.beansStatsDao.fetchNewRoastersDiscovered(start, end);
  }

  // --- New thin wrappers exposing lists for the UI ---

  Future<List<BeanUsage>> getTopBeansFull(DateTime start, DateTime end,
      {int limit = 999}) {
    return db.beansStatsDao.fetchBeanDistributionFull(start, end, limit: limit);
  }

  Future<List<BeanUsage>> getNewBeansList(DateTime start, DateTime end,
      {int limit = 999}) {
    return db.beansStatsDao.fetchNewBeansList(start, end, limit: limit);
  }

  Future<List<String>> getDistinctOriginsList(DateTime start, DateTime end,
      {int limit = 999}) {
    return db.beansStatsDao.fetchDistinctOriginsList(start, end, limit: limit);
  }

  Future<List<String>> getDistinctRegionsList(DateTime start, DateTime end,
      {int limit = 999}) {
    return db.beansStatsDao.fetchDistinctRegionsList(start, end, limit: limit);
  }

  Future<List<String>> getNewRoastersDiscoveredList(
      DateTime start, DateTime end,
      {int limit = 999}) {
    return db.beansStatsDao
        .fetchNewRoastersDiscoveredList(start, end, limit: limit);
  }
}
