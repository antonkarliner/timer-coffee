import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diacritic/diacritic.dart';

import '../providers/coffee_beans_provider.dart';
import '../models/coffee_beans_model.dart';
import '../models/ui_state/coffee_beans_filter_options.dart';

/// Service for handling coffee beans filtering logic.
///
/// This service centralizes all filter-related operations including
/// fetching available filter options, applying filters, and search functionality.
/// It follows the existing service patterns with provider integration.
class CoffeeBeansFilterService {
  const CoffeeBeansFilterService();

  /// Fetches all distinct roasters from the database
  Future<List<String>> fetchAvailableRoasters(BuildContext context) async {
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    return await coffeeBeansProvider.fetchAllDistinctRoasters();
  }

  /// Fetches all distinct origins from the database
  Future<List<String>> fetchAvailableOrigins(BuildContext context) async {
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    return await coffeeBeansProvider.fetchAllDistinctOrigins();
  }

  /// Fetches origins for specific roasters (used for cascading filters)
  Future<List<String>> fetchOriginsForRoasters(
    BuildContext context,
    List<String> roasters,
  ) async {
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);

    if (roasters.isEmpty) {
      return await coffeeBeansProvider.fetchAllDistinctOrigins();
    } else {
      return await coffeeBeansProvider.fetchOriginsForRoasters(roasters);
    }
  }

  /// Applies filters to get filtered coffee beans from the database
  Future<List<CoffeeBeansModel>> applyFilters(
    BuildContext context,
    CoffeeBeansFilterOptions filterOptions,
  ) async {
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);

    return await coffeeBeansProvider.fetchFilteredCoffeeBeans(
      roasters: filterOptions.selectedRoasters.isNotEmpty
          ? filterOptions.selectedRoasters
          : null,
      origins: filterOptions.selectedOrigins.isNotEmpty
          ? filterOptions.selectedOrigins
          : null,
      isFavorite: filterOptions.isFavoriteOnly ? true : null,
    );
  }

  /// Applies search query to a list of coffee beans
  List<CoffeeBeansModel> applySearch(
    List<CoffeeBeansModel> beans,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return beans;

    final query = _normalizeText(searchQuery);

    return beans.where((bean) {
      return _normalizeText(bean.name).contains(query) ||
          _normalizeText(bean.roaster).contains(query) ||
          _normalizeText(bean.origin).contains(query) ||
          (bean.tastingNotes != null &&
              _normalizeText(bean.tastingNotes!).contains(query));
    }).toList();
  }

  /// Updates origins list based on selected roasters (for cascading filter updates)
  Future<List<String>> updateOriginsForSelectedRoasters(
    BuildContext context,
    List<String> selectedRoasters,
    List<String> currentSelectedOrigins,
  ) async {
    final availableOrigins =
        await fetchOriginsForRoasters(context, selectedRoasters);

    // Filter current selected origins to only include those still available
    return currentSelectedOrigins
        .where((origin) => availableOrigins.contains(origin))
        .toList();
  }

  /// Normalizes text for search comparison (removes diacritics and converts to lowercase)
  String _normalizeText(String input) {
    return removeDiacritics(input.toLowerCase());
  }
}
