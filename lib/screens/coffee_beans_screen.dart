import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/coffee_beans_controller.dart';
import '../providers/coffee_beans_provider.dart';
import '../models/coffee_beans_model.dart';
import '../models/ui_state/coffee_beans_view_state.dart';
import '../widgets/coffee_beans/index.dart';
import '../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../widgets/base_buttons.dart';
import '../widgets/undo_snackbar.dart';
import '../widgets/for_you_card.dart';

@visibleForTesting
bool? debugForYouOnMyBeansOverride;

bool get _forYouOnMyBeans =>
    debugForYouOnMyBeansOverride ?? const bool.fromEnvironment('FOR_YOU_DEBUG');

/// Shared eligibility check so tests need not initialize the screen's services.
@visibleForTesting
bool shouldShowForYouOnMyBeans({
  required bool hasBeans,
  required String searchQuery,
  required bool hasActiveFilters,
  required bool isEditMode,
}) =>
    _forYouOnMyBeans &&
    hasBeans &&
    searchQuery.isEmpty &&
    !hasActiveFilters &&
    !isEditMode;

@RoutePage()
class CoffeeBeansScreen extends StatefulWidget {
  const CoffeeBeansScreen({super.key});

  @override
  State<CoffeeBeansScreen> createState() => _CoffeeBeansScreenState();
}

class _CoffeeBeansScreenState extends State<CoffeeBeansScreen> {
  static const _minimumRefreshIndicatorDuration = Duration(milliseconds: 900);

  late CoffeeBeansController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CoffeeBeansController();
    // Initialize controller after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.initialize(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<CoffeeBeansController>(
        builder: (context, controller, child) {
          final showNoBeans =
              !controller.isLoading &&
              controller.error == null &&
              controller.filteredBeans.isEmpty &&
              !controller.hasActiveFilters;
          final showAddButton =
              controller.viewState.isBottomBarVisible && !showNoBeans;

          return Scaffold(
            appBar: CoffeeBeansAppBar(
              viewState: controller.viewState,
              searchController: controller.searchController,
              searchFocusNode: controller.searchFocusNode,
              onSearchChanged: (value) {
                // Search is handled automatically by the controller's listener
              },
              onSearchCleared: controller.clearSearch,
              onViewModeToggled: controller.toggleViewMode,
              onSortPressed: () => controller.showSortDialog(context),
            ),
            body: GestureDetector(
              onTap: () {
                // Unfocus the search field when tapping outside
                controller.searchFocusNode.unfocus();
              },
              child: Column(
                children: [
                  // Inventory total summary (amount of coffee left)
                  BeansTotalSummary(
                    scopedGrams: controller.scopedGramsLeft,
                    grandTotalGrams: controller.grandTotalGramsLeft,
                    hasActiveFilters: controller.hasActiveFilters,
                  ),

                  // Filter Chips
                  CoffeeBeansFilterChips(
                    filterOptions: controller.filterOptions,
                    searchQuery: controller.viewState.searchQuery,
                    onRoasterRemoved: controller.removeRoasterFilter,
                    onOriginRemoved: controller.removeOriginFilter,
                    onFavoriteRemoved: controller.removeFavoriteFilter,
                    onSearchRemoved: controller.clearSearch,
                    onClearAll: () => controller.clearAllFilters(context),
                  ),

                  // Content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _forceRefresh(context, controller),
                      child: _buildContent(
                        context,
                        controller,
                        showNoBeans: showNoBeans,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: AnimatedScale(
              scale: showAddButton ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedOpacity(
                opacity: showAddButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !showAddButton,
                  child: Semantics(
                    identifier: 'addCoffeeBeansButton',
                    label: loc.addBeans,
                    child: FloatingActionButton(
                      onPressed: () => controller.navigateToNewBeans(context),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ),
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: CoffeeBeansBottomBar(
              viewState: controller.viewState,
              onFilterPressed: () => controller.showFilterDialog(context),
              onEditModeToggled: controller.toggleEditMode,
              lift: controller.calculateBottomBarLift(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CoffeeBeansController controller, {
    required bool showNoBeans,
  }) {
    final loc = AppLocalizations.of(context)!;

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null) {
      return _buildAlwaysScrollableFill(
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: AppIconSize.emptyState,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                loc.error(controller.error.toString()),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppElevatedButton(
                label: loc.retry,
                onPressed: () => controller.refreshData(context),
                isFullWidth: false,
                height: AppButton.heightSmall,
                padding: AppButton.paddingSmall,
              ),
            ],
          ),
        ),
      );
    }

    final beans = controller.filteredBeans;

    if (showNoBeans) {
      return _buildAlwaysScrollableFill(
        CoffeeBeansEmptyState.noBeans(
          onAddBeans: () => controller.navigateToNewBeans(context),
        ),
      );
    }
    if (beans.isEmpty) {
      return _buildAlwaysScrollableFill(
        CoffeeBeansEmptyState.noSearchResults(
          onClearFilters: () => controller.clearAllFilters(context),
        ),
      );
    }

    // Trial placement for evaluation (plan 083 Phase 2), debug builds only.
    final header =
        shouldShowForYouOnMyBeans(
          hasBeans: beans.isNotEmpty,
          searchQuery: controller.viewState.searchQuery,
          hasActiveFilters: controller.hasActiveFilters,
          isEditMode: controller.viewState.isEditMode,
        )
        ? const ForYouCard()
        : null;

    // Display content based on view mode
    return controller.viewState.viewMode == ViewMode.list
        ? CoffeeBeansListView(
            beans: beans,
            header: header,
            viewState: controller.viewState,
            scrollController: controller.scrollController,
            onDelete: (bean) => _handleDelete(context, controller, bean),
            onFavoriteToggle: (bean) =>
                _handleFavoriteToggle(context, controller, bean),
            onTap: (bean) =>
                controller.navigateToBeanDetail(context, bean.beansUuid),
            sortOption: controller.sortOptions.sortOption,
          )
        : CoffeeBeansGridView(
            beans: beans,
            header: header,
            viewState: controller.viewState,
            scrollController: controller.scrollController,
            onDelete: (bean) => _handleDelete(context, controller, bean),
            onFavoriteToggle: (bean) =>
                _handleFavoriteToggle(context, controller, bean),
            onTap: (bean) =>
                controller.navigateToBeanDetail(context, bean.beansUuid),
            sortOption: controller.sortOptions.sortOption,
          );
  }

  Widget _buildAlwaysScrollableFill(Widget child) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
    );
  }

  Future<void> _forceRefresh(
    BuildContext context,
    CoffeeBeansController controller,
  ) async {
    await Future.wait([
      controller.forceRefresh(context),
      Future<void>.delayed(_minimumRefreshIndicatorDuration),
    ]);
  }

  Future<void> _handleDelete(
    BuildContext context,
    CoffeeBeansController controller,
    CoffeeBeansModel bean,
  ) async {
    final loc = AppLocalizations.of(context)!;
    // Captured before the awaits so the undo snackbar still shows if the
    // widget tree moves on while the delete is in flight.
    final messenger = ScaffoldMessenger.of(context);
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
      context,
      listen: false,
    );
    await coffeeBeansProvider.deleteCoffeeBeans(bean.beansUuid);
    showUndoSnackBar(
      messenger,
      message: loc.beanDeleted,
      undoLabel: loc.undo,
      entity: UndoEntityType.bean,
      // Restoring notifies CoffeeBeansProvider, which the list controller
      // listens to — the bean reappears without a manual refresh.
      onUndo: () => coffeeBeansProvider.restoreCoffeeBeans(bean.beansUuid),
    );
    if (!context.mounted) return;
    await controller.refreshData(context);
  }

  Future<void> _handleFavoriteToggle(
    BuildContext context,
    CoffeeBeansController controller,
    CoffeeBeansModel bean,
  ) async {
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
      context,
      listen: false,
    );
    await coffeeBeansProvider.toggleFavoriteStatus(
      bean.beansUuid,
      !bean.isFavorite,
    );
    if (!context.mounted) return;
    await controller.refreshData(context);
  }
}
