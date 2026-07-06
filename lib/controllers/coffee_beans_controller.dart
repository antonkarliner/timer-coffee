import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:auto_route/auto_route.dart';
import 'package:provider/provider.dart';

import '../models/ui_state/coffee_beans_filter_options.dart';
import '../models/ui_state/coffee_beans_view_state.dart';
import '../models/ui_state/coffee_beans_sort_options.dart';
import '../models/coffee_beans_model.dart';
import '../services/coffee_beans_filter_service.dart';
import '../services/coffee_beans_sort_service.dart';
import '../widgets/coffee_beans/dialogs/coffee_beans_filter_dialog.dart';
import '../widgets/coffee_beans/dialogs/coffee_beans_sort_dialog.dart';
import '../app_router.gr.dart';
import '../providers/coffee_beans_provider.dart';

/// Controller for Coffee Beans Screen responsible for:
/// - Managing all screen state using Phase 1 models
/// - Integrating with Phase 1 services for filtering and sorting
/// - Handling scroll controller and bottom bar visibility logic
/// - Providing methods for all user interactions
///
/// This controller is UI-agnostic and exposes ChangeNotifier for the view to subscribe.
/// It follows the existing controller patterns with dependency injection for services.
class CoffeeBeansController extends ChangeNotifier {
  // --- Services (dependency injection) ---
  final CoffeeBeansFilterService _filterService;
  final CoffeeBeansSortService _sortService;

  // --- Text Controllers ---
  final TextEditingController searchController = TextEditingController();

  // --- Focus Management ---
  final FocusNode searchFocusNode = FocusNode();

  // --- Scroll Controller ---
  late final ScrollController scrollController;

  // --- State Models ---
  CoffeeBeansFilterOptions _filterOptions = CoffeeBeansFilterOptions.empty;
  CoffeeBeansViewState _viewState = CoffeeBeansViewState.defaultState;
  CoffeeBeansSortOptions _sortOptions = CoffeeBeansSortOptions.defaultSort;

  // --- Data State ---
  List<CoffeeBeansModel> _allBeans = [];
  List<CoffeeBeansModel> _filteredBeans = [];
  double _grandTotalGramsLeft = 0;
  bool _isLoading = false;
  String? _error;

  // --- Available Filter Options ---
  List<String> _availableRoasters = [];
  // --- Provider listener / refresh guard ---
  CoffeeBeansProvider? _coffeeBeansProvider;
  VoidCallback? _providerListener;
  bool _isRefreshing = false;
  bool _isDisposed = false;
  List<String> _availableOrigins = [];

  // --- Constructor ---
  CoffeeBeansController({
    CoffeeBeansFilterService? filterService,
    CoffeeBeansSortService? sortService,
  }) : _filterService = filterService ?? const CoffeeBeansFilterService(),
       _sortService = sortService ?? const CoffeeBeansSortService() {
    scrollController = ScrollController();
    scrollController.addListener(_handleScroll);
    searchController.addListener(_handleSearchChanged);
  }

  // --- Getters ---
  CoffeeBeansFilterOptions get filterOptions => _filterOptions;
  CoffeeBeansViewState get viewState => _viewState;
  CoffeeBeansSortOptions get sortOptions => _sortOptions;
  List<CoffeeBeansModel> get filteredBeans => _filteredBeans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get availableRoasters => _availableRoasters;
  List<String> get availableOrigins => _availableOrigins;

  // --- Computed Properties ---
  bool get hasActiveFilters {
    return _filterOptions.hasActiveFilters || _viewState.hasActiveSearch;
  }

  /// Sum of the tracked "amount left" (grams) across the beans currently in
  /// scope (after filters and search). Beans without a tracked weight
  /// contribute nothing.
  double get scopedGramsLeft => _sumGramsLeft(_filteredBeans);

  /// Sum of the tracked "amount left" (grams) across all non-deleted beans,
  /// ignoring any active filter or search. Used to show the grand total
  /// alongside a filtered subtotal.
  double get grandTotalGramsLeft => _grandTotalGramsLeft;

  double _sumGramsLeft(List<CoffeeBeansModel> beans) {
    var total = 0.0;
    for (final bean in beans) {
      total += bean.validatedPackageWeightGrams ?? 0;
    }
    return total;
  }

  double calculateBottomBarLift(BuildContext context) {
    return kBottomNavigationBarHeight / 4 +
        MediaQuery.of(context).padding.bottom;
  }

  // --- Lifecycle ---
  @override
  void dispose() {
    _isDisposed = true;

    // Remove scroll and search listeners
    scrollController.removeListener(_handleScroll);
    scrollController.dispose();
    searchController.removeListener(_handleSearchChanged);
    searchController.dispose();

    // Dispose focus node
    searchFocusNode.dispose();

    // Remove provider listener if set
    try {
      if (_coffeeBeansProvider != null && _providerListener != null) {
        _coffeeBeansProvider!.removeListener(_providerListener!);
      }
    } catch (e) {
      // ignore any removal errors
    } finally {
      _coffeeBeansProvider = null;
      _providerListener = null;
    }

    super.dispose();
  }

  // --- Initialization ---

  Future<void> initialize(BuildContext context) async {
    if (_isDisposed || !context.mounted) return;
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
      context,
      listen: false,
    );
    _coffeeBeansProvider = coffeeBeansProvider;
    _setLoading(true);
    try {
      // Load saved preferences
      final savedViewMode = await _sortService.loadViewMode();
      final savedSortOptions = await _sortService.loadSortOptions();
      if (_isDisposed) return;
      // Setup provider listener to auto-refresh when CoffeeBeansProvider notifies.
      // Use a small debounce/guard to avoid duplicate refreshes.
      try {
        _providerListener = () async {
          if (_isRefreshing) return;
          _isRefreshing = true;
          // Short debounce to coalesce rapid notifications
          await Future.delayed(const Duration(milliseconds: 50));
          try {
            if (_isDisposed) return;
            await _refreshData(coffeeBeansProvider);
          } catch (_) {
            // ignore errors coming from background refresh attempts
          } finally {
            _isRefreshing = false;
          }
        };
        coffeeBeansProvider.addListener(_providerListener!);
      } catch (e) {
        // If provider isn't available or listener registration fails, continue silently
      }

      _viewState = _viewState.copyWith(viewMode: savedViewMode);
      _sortOptions = savedSortOptions;

      // Load filter options
      await _loadFilterOptions(coffeeBeansProvider);
      if (_isDisposed) return;

      // Load initial data
      await _refreshData(coffeeBeansProvider);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadFilterOptions(
    CoffeeBeansProvider coffeeBeansProvider,
  ) async {
    try {
      final availableRoasters = await coffeeBeansProvider
          .fetchAllDistinctRoasters();
      if (_isDisposed) return;
      _availableRoasters = availableRoasters;

      final availableOrigins = await coffeeBeansProvider
          .fetchAllDistinctOrigins();
      if (_isDisposed) return;
      _availableOrigins = availableOrigins;
    } catch (e) {
      // Handle error silently, keep empty lists
    }
  }

  // --- Data Management ---
  Future<void> refreshData(BuildContext context) {
    if (_isDisposed || !context.mounted) return Future.value();
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
      context,
      listen: false,
    );
    return _refreshData(coffeeBeansProvider);
  }

  Future<void> _refreshData(CoffeeBeansProvider coffeeBeansProvider) async {
    if (_isDisposed) return;
    _setLoading(true);
    try {
      // Fetch filtered data from database
      final filteredBeans = await coffeeBeansProvider.fetchFilteredCoffeeBeans(
        roasters: _filterOptions.selectedRoasters.isNotEmpty
            ? _filterOptions.selectedRoasters
            : null,
        origins: _filterOptions.selectedOrigins.isNotEmpty
            ? _filterOptions.selectedOrigins
            : null,
        isFavorite: _filterOptions.isFavoriteOnly ? true : null,
      );
      if (_isDisposed) return;
      _allBeans = filteredBeans;

      // Apply search filter
      var searchFiltered = _filterService.applySearch(
        _allBeans,
        _viewState.searchQuery,
      );

      // Apply sorting
      _filteredBeans = _sortService.applySorting(searchFiltered, _sortOptions);

      // Compute the grand total of tracked grams across ALL non-deleted beans,
      // independent of the active filters/search, so the summary can show
      // "<filtered> of <grand total>".
      final allBeans = await coffeeBeansProvider.fetchAllCoffeeBeans();
      if (_isDisposed) return;
      _grandTotalGramsLeft = _sumGramsLeft(allBeans);

      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    if (_isDisposed) return;
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_isDisposed) return;
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  // --- Search Handling ---
  void _handleSearchChanged() {
    final query = searchController.text;
    if (_viewState.searchQuery != query) {
      _viewState = _viewState.copyWith(searchQuery: query);
      _applyLocalFilters();
      notifyListeners();
    }
  }

  void clearSearch() {
    searchController.clear();
    _viewState = _viewState.copyWith(searchQuery: '');
    _applyLocalFilters();
    notifyListeners();
  }

  // --- Scroll Handling ---
  void _handleScroll() {
    // Dismiss keyboard when scrolling
    searchFocusNode.unfocus();

    final isScrollingDown =
        scrollController.position.userScrollDirection ==
        ScrollDirection.reverse;
    final isScrollingUp =
        scrollController.position.userScrollDirection ==
        ScrollDirection.forward;

    if (isScrollingDown && _viewState.isBottomBarVisible) {
      _viewState = _viewState.copyWith(isBottomBarVisible: false);
      notifyListeners();
    } else if (isScrollingUp && !_viewState.isBottomBarVisible) {
      _viewState = _viewState.copyWith(isBottomBarVisible: true);
      notifyListeners();
    }
  }

  // --- View Mode Management ---
  Future<void> toggleViewMode() async {
    final newViewMode = _viewState.viewMode == ViewMode.list
        ? ViewMode.grid
        : ViewMode.list;
    _viewState = _viewState.copyWith(viewMode: newViewMode);
    await _sortService.saveViewMode(newViewMode);
    notifyListeners();
  }

  // --- Edit Mode Management ---
  void toggleEditMode() {
    _viewState = _viewState.copyWith(isEditMode: !_viewState.isEditMode);
    notifyListeners();
  }

  // --- Filter Management ---
  Future<void> showFilterDialog(BuildContext context) async {
    if (_isDisposed || !context.mounted) return;
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
      context,
      listen: false,
    );
    final result = await showModalBottomSheet<CoffeeBeansFilterOptions>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (BuildContext context) {
        return CoffeeBeansFilterDialog(
          initialFilterOptions: _filterOptions,
          filterService: _filterService,
        );
      },
    );

    if (result != null && !_isDisposed) {
      _filterOptions = result;
      await _updateOriginsForSelectedRoasters(coffeeBeansProvider);
      await _refreshData(coffeeBeansProvider);
    }
  }

  Future<void> _updateOriginsForSelectedRoasters(
    CoffeeBeansProvider coffeeBeansProvider,
  ) async {
    try {
      final availableOrigins = _filterOptions.selectedRoasters.isEmpty
          ? await coffeeBeansProvider.fetchAllDistinctOrigins()
          : await coffeeBeansProvider.fetchOriginsForRoasters(
              _filterOptions.selectedRoasters,
            );
      if (_isDisposed) return;
      _availableOrigins = availableOrigins;

      // Update selected origins to only include those still available
      final updatedSelectedOrigins = _filterOptions.selectedOrigins
          .where((origin) => _availableOrigins.contains(origin))
          .toList();

      _filterOptions = _filterOptions.copyWith(
        selectedOrigins: updatedSelectedOrigins,
      );
    } catch (e) {
      // Handle error silently
    }
  }

  void removeRoasterFilter(String roaster) {
    final updatedRoasters = List<String>.from(_filterOptions.selectedRoasters)
      ..remove(roaster);
    _filterOptions = _filterOptions.copyWith(selectedRoasters: updatedRoasters);
    _refreshAfterFilterChange();
  }

  void removeOriginFilter(String origin) {
    final updatedOrigins = List<String>.from(_filterOptions.selectedOrigins)
      ..remove(origin);
    _filterOptions = _filterOptions.copyWith(selectedOrigins: updatedOrigins);
    _refreshAfterFilterChange();
  }

  void removeFavoriteFilter() {
    _filterOptions = _filterOptions.copyWith(isFavoriteOnly: false);
    _refreshAfterFilterChange();
  }

  Future<void> clearAllFilters(BuildContext context) async {
    _filterOptions = CoffeeBeansFilterOptions.empty;
    _viewState = _viewState.copyWith(searchQuery: '');
    searchController.clear();
    await refreshData(context);
  }

  void _refreshAfterFilterChange() {
    // For filter chip removals, we can apply changes locally without database call
    // since we're only removing filters (making the filter less restrictive)
    _applyLocalFilters();
    notifyListeners();
  }

  void _applyLocalFilters() {
    // Apply search filter to all beans
    var searchFiltered = _filterService.applySearch(
      _allBeans,
      _viewState.searchQuery,
    );

    // Apply sorting
    _filteredBeans = _sortService.applySorting(searchFiltered, _sortOptions);
  }

  // --- Sort Management ---
  Future<void> showSortDialog(BuildContext context) async {
    final result = await showModalBottomSheet<CoffeeBeansSortOptions>(
      context: context,
      useRootNavigator: true,
      builder: (context) =>
          CoffeeBeansSortDialog(currentSortOptions: _sortOptions),
    );

    if (result != null) {
      _sortOptions = result;
      await _sortService.saveSortOptions(_sortOptions);
      _applyLocalFilters();
      notifyListeners();
    }
  }

  // --- Navigation ---
  Future<void> navigateToNewBeans(BuildContext context) async {
    // Unfocus search field before navigating
    searchFocusNode.unfocus();

    final result = await context.router.push(NewBeansRoute());
    if (_isDisposed || !context.mounted) return;
    if (result != null && result is String) {
      await refreshData(context);
      if (_isDisposed) return;
      // Ensure search field is unfocused after returning from navigation
      searchFocusNode.unfocus();
    }
  }

  void navigateToBeanDetail(BuildContext context, String uuid) {
    // Unfocus search field before navigating
    searchFocusNode.unfocus();

    // Push detail route and refresh when returning. Use then to avoid changing
    // callback signatures where this method is used.
    context.router.push(CoffeeBeansDetailRoute(uuid: uuid)).then((
      result,
    ) async {
      if (_isDisposed || !context.mounted) return;
      // If a refresh is already in progress from provider notifications, skip duplicated work.
      if (_isRefreshing) {
        return;
      }

      _isRefreshing = true;
      try {
        // Many flows return a String on successful edit/save; refresh when we get any non-null result
        if (result != null) {
          await refreshData(context);
        }
        if (_isDisposed) return;
        // Ensure search field is unfocused after returning from navigation
        searchFocusNode.unfocus();
      } catch (_) {
        // Ignore refresh failures here; provider listener will correct later if needed
      } finally {
        _isRefreshing = false;
      }
    });
  }

  // --- Bean Actions ---
  Future<void> deleteBeans(BuildContext context, String uuid) async {
    // This would typically be handled by the provider, but we need to refresh after
    await refreshData(context);
  }

  Future<void> toggleFavoriteStatus(
    BuildContext context,
    String uuid,
    bool isFavorite,
  ) async {
    // This would typically be handled by the provider, but we need to refresh after
    await refreshData(context);
  }
}
