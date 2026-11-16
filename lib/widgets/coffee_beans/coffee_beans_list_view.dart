import 'package:flutter/material.dart';

import '../../models/coffee_beans_model.dart';
import '../../theme/design_tokens.dart';
import '../../models/ui_state/coffee_beans_sort_options.dart';
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

  /// Optional full-width content that scrolls above the beans.
  final Widget? header;

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

  /// Current sort option, passed to cards for contextual subtitle
  final SortOption sortOption;

  const CoffeeBeansListView({
    super.key,
    required this.beans,
    required this.viewState,
    this.scrollController,
    this.header,
    required this.onDelete,
    required this.onFavoriteToggle,
    required this.onTap,
    this.sortOption = SortOption.dateAdded,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      // Keep the header full-width: ForYouCard supplies its own side insets.
      padding: header == null
          ? const EdgeInsets.all(16.0)
          : const EdgeInsets.symmetric(vertical: AppSpacing.base),
      itemCount: beans.length + (header == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (header != null && index == 0) {
          return header!;
        }
        final bean = beans[index - (header == null ? 0 : 1)];
        return Padding(
          padding: header == null
              ? const EdgeInsets.only(bottom: 8.0)
              : const EdgeInsets.only(
                  left: AppSpacing.base,
                  right: AppSpacing.base,
                  bottom: AppSpacing.sm,
                ),
          child: CoffeeBeanCard(
            key: ValueKey(bean.beansUuid),
            bean: bean,
            isEditMode: viewState.isEditMode,
            onDelete: () => onDelete(bean),
            onFavoriteToggle: () => onFavoriteToggle(bean),
            onTap: () => onTap(bean),
            sortOption: sortOption,
          ),
        );
      },
    );
  }
}
