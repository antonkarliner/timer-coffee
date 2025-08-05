import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/coffee_beans_controller.dart';
import '../providers/coffee_beans_provider.dart';
import '../models/coffee_beans_model.dart';
import '../models/ui_state/coffee_beans_view_state.dart';
import '../widgets/coffee_beans/index.dart';
import '../l10n/app_localizations.dart';

@RoutePage()
class CoffeeBeansScreen extends StatefulWidget {
  const CoffeeBeansScreen({Key? key}) : super(key: key);

  @override
  _CoffeeBeansScreenState createState() => _CoffeeBeansScreenState();
}

class _CoffeeBeansScreenState extends State<CoffeeBeansScreen> {
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
          return Scaffold(
            appBar: CoffeeBeansAppBar(
              viewState: controller.viewState,
              searchController: controller.searchController,
              onSearchChanged: (value) {
                // Search is handled automatically by the controller's listener
              },
              onSearchCleared: controller.clearSearch,
              onViewModeToggled: controller.toggleViewMode,
              onSortPressed: () => controller.showSortDialog(context),
            ),
            body: Column(
              children: [
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
                  child: _buildContent(context, controller),
                ),
              ],
            ),
            floatingActionButton: AnimatedScale(
              scale: controller.viewState.isBottomBarVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedOpacity(
                opacity: controller.viewState.isBottomBarVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !controller.viewState.isBottomBarVisible,
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

  Widget _buildContent(BuildContext context, CoffeeBeansController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${controller.error}',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => controller.refreshData(context),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final beans = controller.filteredBeans;

    // Handle empty states
    if (beans.isEmpty) {
      // Check if this is due to filters/search or truly no beans
      if (controller.hasActiveFilters) {
        return CoffeeBeansEmptyState.noSearchResults(
          onClearFilters: () => controller.clearAllFilters(context),
        );
      } else {
        return CoffeeBeansEmptyState.noBeans(
          onAddBeans: () => controller.navigateToNewBeans(context),
        );
      }
    }

    // Display content based on view mode
    return controller.viewState.viewMode == ViewMode.list
        ? CoffeeBeansListView(
            beans: beans,
            viewState: controller.viewState,
            scrollController: controller.scrollController,
            onDelete: (bean) => _handleDelete(context, controller, bean),
            onFavoriteToggle: (bean) =>
                _handleFavoriteToggle(context, controller, bean),
            onTap: (bean) =>
                controller.navigateToBeanDetail(context, bean.beansUuid!),
          )
        : CoffeeBeansGridView(
            beans: beans,
            viewState: controller.viewState,
            scrollController: controller.scrollController,
            onDelete: (bean) => _handleDelete(context, controller, bean),
            onFavoriteToggle: (bean) =>
                _handleFavoriteToggle(context, controller, bean),
            onTap: (bean) =>
                controller.navigateToBeanDetail(context, bean.beansUuid!),
          );
  }

  Future<void> _handleDelete(
    BuildContext context,
    CoffeeBeansController controller,
    CoffeeBeansModel bean,
  ) async {
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    await coffeeBeansProvider.deleteCoffeeBeans(bean.beansUuid!);
    await controller.refreshData(context);
  }

  Future<void> _handleFavoriteToggle(
    BuildContext context,
    CoffeeBeansController controller,
    CoffeeBeansModel bean,
  ) async {
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    await coffeeBeansProvider.toggleFavoriteStatus(
        bean.beansUuid!, !bean.isFavorite);
    await controller.refreshData(context);
  }
}
