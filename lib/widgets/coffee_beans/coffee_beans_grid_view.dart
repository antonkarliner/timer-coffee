import 'package:flutter/material.dart';

import '../../models/coffee_beans_model.dart';
import '../../models/ui_state/coffee_beans_sort_options.dart';
import '../../models/ui_state/coffee_beans_view_state.dart';
import 'coffee_bean_grid_card.dart';

/// A stateless widget that wraps GridView.builder for coffee beans grid view.
///
/// This widget handles the grid view container with scroll controller integration,
/// responsive grid layout with fixed cross axis count, and same data handling as list view.
/// It uses CoffeeBeanGridCard for individual items and follows the callback pattern.
class CoffeeBeansGridView extends StatelessWidget {
  /// List of coffee beans to display
  final List<CoffeeBeansModel> beans;

  /// Current view state
  final CoffeeBeansViewState viewState;

  /// Scroll controller for the grid
  final ScrollController? scrollController;

  /// Callback for delete action
  final void Function(CoffeeBeansModel bean) onDelete;

  /// Callback for favorite toggle action
  final void Function(CoffeeBeansModel bean) onFavoriteToggle;

  /// Callback for navigation to detail screen
  final void Function(CoffeeBeansModel bean) onTap;

  /// Current sort option, passed to cards for contextual subtitle
  final SortOption sortOption;

  const CoffeeBeansGridView({
    super.key,
    required this.beans,
    required this.viewState,
    this.scrollController,
    required this.onDelete,
    required this.onFavoriteToggle,
    required this.onTap,
    this.sortOption = SortOption.dateAdded,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: beans.length,
      itemBuilder: (context, index) {
        final bean = beans[index];
        return CoffeeBeanGridCard(
          key: ValueKey(bean.beansUuid),
          bean: bean,
          isEditMode: viewState.isEditMode,
          onDelete: () => onDelete(bean),
          onFavoriteToggle: () => onFavoriteToggle(bean),
          onTap: () => onTap(bean),
          sortOption: sortOption,
        );
      },
    );
  }
}
