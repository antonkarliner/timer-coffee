import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/ui_state/coffee_beans_view_state.dart';

/// Custom AppBar for the coffee beans screen with search functionality,
/// view mode toggle, and sort button.
///
/// This widget follows the callback pattern for parent-child communication
/// and uses the [CoffeeBeansViewState] model for state management.
class CoffeeBeansAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Current view state containing search query and view mode
  final CoffeeBeansViewState viewState;

  /// Controller for the search text field
  final TextEditingController searchController;

  /// Callback when search query changes
  final ValueChanged<String> onSearchChanged;

  /// Callback when search is cleared
  final VoidCallback onSearchCleared;

  /// Callback when view mode is toggled
  final VoidCallback onViewModeToggled;

  /// Callback when sort button is pressed
  final VoidCallback onSortPressed;

  const CoffeeBeansAppBar({
    Key? key,
    required this.viewState,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onViewModeToggled,
    required this.onSortPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AppBar(
      title: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: loc.searchBeans,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: viewState.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onSearchCleared,
                )
              : null,
          border: InputBorder.none,
        ),
        onChanged: onSearchChanged,
      ),
      actions: [
        IconButton(
          icon: Icon(viewState.viewMode == ViewMode.list
              ? Icons.grid_view
              : Icons.view_list),
          onPressed: onViewModeToggled,
          tooltip: viewState.viewMode == ViewMode.list
              ? 'Switch to grid view'
              : 'Switch to list view',
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: onSortPressed,
          tooltip: loc.sortBy,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
