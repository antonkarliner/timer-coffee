import 'package:flutter/material.dart';

import '../../models/coffee_beans_model.dart';
import '../../models/ui_state/coffee_beans_view_state.dart';
import 'coffee_bean_card.dart';

/// A stateless widget that wraps ListView.builder for coffee beans list view.
///
/// This widget handles the list view container with scroll controller integration,
/// empty states, and loading states. It uses CoffeeBeanCard for individual items
/// and follows the callback pattern for all interactions.
class CoffeeBeansListView extends StatelessWidget {
  /// List of coffee beans to display
  final List<CoffeeBeansModel> beans;

  /// Current view state
  final CoffeeBeansViewState viewState;

  /// Scroll controller for the list
  final ScrollController? scrollController;

  /// Callback for delete action
  final void Function(CoffeeBeansModel bean) onDelete;

  /// Callback for favorite toggle action
  final void Function(CoffeeBeansModel bean) onFavoriteToggle;

  /// Callback for navigation to detail screen
  final void Function(CoffeeBeansModel bean) onTap;

  const CoffeeBeansListView({
    Key? key,
    required this.beans,
    required this.viewState,
    this.scrollController,
    required this.onDelete,
    required this.onFavoriteToggle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: beans.length,
      itemBuilder: (context, index) {
        final bean = beans[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: CoffeeBeanCard(
            key: ValueKey(bean.beansUuid),
            bean: bean,
            isEditMode: viewState.isEditMode,
            onDelete: () => onDelete(bean),
            onFavoriteToggle: () => onFavoriteToggle(bean),
            onTap: () => onTap(bean),
          ),
        );
      },
    );
  }
}
