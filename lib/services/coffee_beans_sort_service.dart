import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/coffee_beans_model.dart';
import '../models/ui_state/coffee_beans_sort_options.dart';
import '../models/ui_state/coffee_beans_view_state.dart';

/// Service for handling coffee beans sorting and view mode persistence.
///
/// This service centralizes all sort-related operations including
/// applying sorting logic, saving/loading view mode preferences,
/// and text normalization utilities.
class CoffeeBeansSortService {
  const CoffeeBeansSortService();

  /// Applies sorting to a list of coffee beans based on sort options
  List<CoffeeBeansModel> applySorting(
    List<CoffeeBeansModel> beans,
    CoffeeBeansSortOptions sortOptions,
  ) {
    final sortedBeans = List<CoffeeBeansModel>.from(beans);

    switch (sortOptions.sortOption) {
      case SortOption.dateAdded:
        // Sort by UUID (newest first for descending, oldest first for ascending)
        sortedBeans.sort((a, b) =>
            sortOptions.sortDirection == SortDirection.descending
                ? b.beansUuid.compareTo(a.beansUuid)
                : a.beansUuid.compareTo(b.beansUuid));
        break;
      case SortOption.name:
        sortedBeans.sort((a, b) =>
            sortOptions.sortDirection == SortDirection.descending
                ? b.name.compareTo(a.name)
                : a.name.compareTo(b.name));
        break;
      case SortOption.roaster:
        sortedBeans.sort((a, b) =>
            sortOptions.sortDirection == SortDirection.descending
                ? b.roaster.compareTo(a.roaster)
                : a.roaster.compareTo(b.roaster));
        break;
      case SortOption.origin:
        sortedBeans.sort((a, b) =>
            sortOptions.sortDirection == SortDirection.descending
                ? b.origin.compareTo(a.origin)
                : a.origin.compareTo(b.origin));
        break;
      case SortOption.remainingAmount:
        sortedBeans.sort((a, b) {
          final aWeight = a.validatedPackageWeightGrams ?? 0.0;
          final bWeight = b.validatedPackageWeightGrams ?? 0.0;
          return sortOptions.sortDirection == SortDirection.descending
              ? bWeight.compareTo(aWeight)
              : aWeight.compareTo(bWeight);
        });
        break;
    }

    return sortedBeans;
  }

  /// Saves the view mode preference to SharedPreferences
  Future<void> saveViewMode(ViewMode viewMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('coffeeBeansGridView', viewMode == ViewMode.grid);
  }

  /// Loads the view mode preference from SharedPreferences
  Future<ViewMode> loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isGrid = prefs.getBool('coffeeBeansGridView') ?? true;
    return isGrid ? ViewMode.grid : ViewMode.list;
  }

  /// Saves sort options to SharedPreferences
  Future<void> saveSortOptions(CoffeeBeansSortOptions sortOptions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coffeeBeansSortOption', sortOptions.sortOption.name);
    await prefs.setString(
        'coffeeBeansSortDirection', sortOptions.sortDirection.name);
  }

  /// Loads sort options from SharedPreferences
  Future<CoffeeBeansSortOptions> loadSortOptions() async {
    final prefs = await SharedPreferences.getInstance();

    final sortOptionString = prefs.getString('coffeeBeansSortOption');
    final sortDirectionString = prefs.getString('coffeeBeansSortDirection');

    SortOption sortOption = SortOption.dateAdded; // default
    if (sortOptionString != null) {
      try {
        sortOption = SortOption.values.firstWhere(
          (e) => e.name == sortOptionString,
          orElse: () => SortOption.dateAdded,
        );
      } catch (e) {
        // If parsing fails, use default
        sortOption = SortOption.dateAdded;
      }
    }

    SortDirection sortDirection = SortDirection.descending; // default
    if (sortDirectionString != null) {
      try {
        sortDirection = SortDirection.values.firstWhere(
          (e) => e.name == sortDirectionString,
          orElse: () => SortDirection.descending,
        );
      } catch (e) {
        // If parsing fails, use default
        sortDirection = SortDirection.descending;
      }
    }

    return CoffeeBeansSortOptions(
      sortOption: sortOption,
      sortDirection: sortDirection,
    );
  }

  /// Clears all saved preferences related to coffee beans screen
  Future<void> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('coffeeBeansGridView');
    await prefs.remove('coffeeBeansSortOption');
    await prefs.remove('coffeeBeansSortDirection');
  }
}
