import 'package:flutter/material.dart';
import 'package:coffeico/coffeico.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';

/// Empty state widgets for the coffee beans screen.
///
/// This widget handles two different empty states:
/// 1. No beans state - when there are no coffee beans at all
/// 2. No search results state - when search/filters return no results
///
/// It follows the callback pattern for parent-child communication and
/// provides conditional rendering based on data state.
class CoffeeBeansEmptyState extends StatelessWidget {
  /// The type of empty state to display
  final EmptyStateType type;

  /// Callback when "Add Beans" button is pressed (for no beans state)
  final VoidCallback? onAddBeans;

  /// Callback when "Clear Filters" button is pressed (for no search results state)
  final VoidCallback? onClearFilters;

  const CoffeeBeansEmptyState({
    Key? key,
    required this.type,
    this.onAddBeans,
    this.onClearFilters,
  }) : super(key: key);

  /// Factory constructor for no beans state
  const CoffeeBeansEmptyState.noBeans({
    Key? key,
    required VoidCallback onAddBeans,
  }) : this(
          key: key,
          type: EmptyStateType.noBeans,
          onAddBeans: onAddBeans,
        );

  /// Factory constructor for no search results state
  const CoffeeBeansEmptyState.noSearchResults({
    Key? key,
    required VoidCallback onClearFilters,
  }) : this(
          key: key,
          type: EmptyStateType.noSearchResults,
          onClearFilters: onClearFilters,
        );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIcon(),
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _getMessage(loc),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          _buildActionButton(context, loc),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case EmptyStateType.noBeans:
        return Coffeico.bag_with_bean;
      case EmptyStateType.noSearchResults:
        return Icons.search_off;
    }
  }

  String _getMessage(AppLocalizations loc) {
    switch (type) {
      case EmptyStateType.noBeans:
        return loc.nocoffeebeans;
      case EmptyStateType.noSearchResults:
        return loc.noBeansMatchSearch;
    }
  }

  Widget _buildActionButton(BuildContext context, AppLocalizations loc) {
    switch (type) {
      case EmptyStateType.noBeans:
        return AppElevatedButton(
          label: loc.addBeans,
          onPressed: onAddBeans,
          icon: Icons.add,
          isFullWidth: false,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        );
      case EmptyStateType.noSearchResults:
        return AppTextButton(
          label: loc.clearFilters,
          onPressed: onClearFilters,
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        );
    }
  }
}

/// Enumeration of empty state types
enum EmptyStateType {
  /// No coffee beans found at all
  noBeans,

  /// No beans match the current search/filter criteria
  noSearchResults,
}
