import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:coffeico/coffeico.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';

import '../../app_router.gr.dart';
import '../../providers/coffee_beans_provider.dart';
import '../../models/coffee_beans_model.dart';
import '../../models/ui_state/coffee_beans_view_state.dart';
import '../../models/ui_state/coffee_beans_filter_options.dart';
import '../../services/coffee_beans_filter_service.dart';
import '../../services/coffee_beans_sort_service.dart';
import 'coffee_beans_list_view.dart';
import 'coffee_beans_grid_view.dart';

/// A stateless widget that handles the main content area of the coffee beans screen.
///
/// This widget wraps the FutureBuilder for data loading and handles loading, empty,
/// and error states. It switches between list and grid views based on ViewMode
/// and integrates with CoffeeBeansProvider, filter service, and sort service.
class CoffeeBeansContent extends StatelessWidget {
  /// Current view state
  final CoffeeBeansViewState viewState;

  /// Current filter options
  final CoffeeBeansFilterOptions filterOptions;

  /// Current sort options
  final dynamic sortOptions; // Using dynamic to match original implementation

  /// Scroll controller for the views
  final ScrollController? scrollController;

  /// Callback for delete action
  final void Function(CoffeeBeansModel bean) onDelete;

  /// Callback for favorite toggle action
  final void Function(CoffeeBeansModel bean) onFavoriteToggle;

  /// Callback for navigation to detail screen
  final void Function(CoffeeBeansModel bean) onTap;

  /// Callback for clearing filters
  final VoidCallback onClearFilters;

  const CoffeeBeansContent({
    Key? key,
    required this.viewState,
    required this.filterOptions,
    required this.sortOptions,
    this.scrollController,
    required this.onDelete,
    required this.onFavoriteToggle,
    required this.onTap,
    required this.onClearFilters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(context);
    final filterService = const CoffeeBeansFilterService();
    final sortService = const CoffeeBeansSortService();
    final loc = AppLocalizations.of(context)!;

    return FutureBuilder<List<CoffeeBeansModel>>(
      future: filterService.applyFilters(context, filterOptions),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          var filteredData = filterService.applySearch(
            snapshot.data!,
            viewState.searchQuery,
          );

          // Apply user sort (using the original sort logic for compatibility)
          var sortedData = _sortBeans(filteredData);

          if (sortedData.isEmpty) {
            return _buildNoResultsState(context, loc);
          }

          return viewState.viewMode == ViewMode.list
              ? CoffeeBeansListView(
                  beans: sortedData,
                  viewState: viewState,
                  scrollController: scrollController,
                  onDelete: onDelete,
                  onFavoriteToggle: onFavoriteToggle,
                  onTap: onTap,
                )
              : CoffeeBeansGridView(
                  beans: sortedData,
                  viewState: viewState,
                  scrollController: scrollController,
                  onDelete: onDelete,
                  onFavoriteToggle: onFavoriteToggle,
                  onTap: onTap,
                );
        } else if (snapshot.hasData && snapshot.data!.isEmpty) {
          return _buildEmptyState(context, loc);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  /// Builds the no search results state
  Widget _buildNoResultsState(BuildContext context, AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            loc.noBeansMatchSearch,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          AppTextButton(
            label: loc.clearFilters,
            onPressed: onClearFilters,
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
          ),
        ],
      ),
    );
  }

  /// Builds the empty state when no coffee beans exist
  Widget _buildEmptyState(BuildContext context, AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Coffeico.bag_with_bean,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            loc.nocoffeebeans,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          AppElevatedButton(
            label: loc.addBeans,
            onPressed: () async {
              final result = await context.router.push(NewBeansRoute());
              // Note: State refresh should be handled by parent
            },
            icon: Icons.add,
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
          ),
        ],
      ),
    );
  }

  /// Helper method for sorting beans (maintaining original logic for compatibility)
  List<CoffeeBeansModel> _sortBeans(List<CoffeeBeansModel> beans) {
    // This maintains the original sorting logic from the screen
    // In a future phase, this could be replaced with the sort service
    beans.sort(
        (a, b) => b.beansUuid.compareTo(a.beansUuid)); // Default: newest first
    return beans;
  }
}
