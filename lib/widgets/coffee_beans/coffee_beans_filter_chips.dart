import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/ui_state/coffee_beans_filter_options.dart';

/// Horizontal scrolling filter chips row for the coffee beans screen.
///
/// This widget displays active filters as chips with delete functionality
/// and includes a "Clear All" action chip. It uses the [CoffeeBeansFilterOptions]
/// model and follows the callback pattern for parent-child communication.
class CoffeeBeansFilterChips extends StatelessWidget {
  /// Current filter options containing selected roasters, origins, and favorite status
  final CoffeeBeansFilterOptions filterOptions;

  /// Current search query to display as a filter chip
  final String searchQuery;

  /// Callback when a roaster filter is removed
  final ValueChanged<String> onRoasterRemoved;

  /// Callback when an origin filter is removed
  final ValueChanged<String> onOriginRemoved;

  /// Callback when favorite filter is removed
  final VoidCallback onFavoriteRemoved;

  /// Callback when search filter is removed
  final VoidCallback onSearchRemoved;

  /// Callback when all filters are cleared
  final VoidCallback onClearAll;

  const CoffeeBeansFilterChips({
    Key? key,
    required this.filterOptions,
    required this.searchQuery,
    required this.onRoasterRemoved,
    required this.onOriginRemoved,
    required this.onFavoriteRemoved,
    required this.onSearchRemoved,
    required this.onClearAll,
  }) : super(key: key);

  /// Returns true if any filters are currently active
  bool get hasActiveFilters {
    return filterOptions.hasActiveFilters || searchQuery.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!hasActiveFilters) {
      return const SizedBox.shrink();
    }

    final loc = AppLocalizations.of(context)!;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Roaster filter chips
          if (filterOptions.selectedRoasters.isNotEmpty)
            ...filterOptions.selectedRoasters.map((roaster) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(roaster),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    deleteIconColor: Theme.of(context).colorScheme.onPrimary,
                    onSelected: (bool value) {
                      // Do nothing - we only want delete functionality
                    },
                    onDeleted: () => onRoasterRemoved(roaster),
                  ),
                )),

          // Origin filter chips
          if (filterOptions.selectedOrigins.isNotEmpty)
            ...filterOptions.selectedOrigins.map((origin) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(origin),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    deleteIconColor: Theme.of(context).colorScheme.onPrimary,
                    onSelected: (bool value) {
                      // Do nothing - we only want delete functionality
                    },
                    onDeleted: () => onOriginRemoved(origin),
                  ),
                )),

          // Favorite filter chip
          if (filterOptions.isFavoriteOnly)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(loc.favorites),
                backgroundColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                deleteIconColor: Theme.of(context).colorScheme.onPrimary,
                onSelected: (bool value) {
                  // Do nothing - we only want delete functionality
                },
                onDeleted: onFavoriteRemoved,
              ),
            ),

          // Search filter chip
          if (searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text('${loc.searchPrefix}$searchQuery'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                deleteIconColor: Theme.of(context).colorScheme.onPrimary,
                onSelected: (bool value) {
                  // Do nothing - we only want delete functionality
                },
                onDeleted: onSearchRemoved,
              ),
            ),

          // Clear all action chip
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(loc.clearAll),
              backgroundColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: onClearAll,
            ),
          ),
        ],
      ),
    );
  }
}
