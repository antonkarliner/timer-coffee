import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:auto_route/auto_route.dart';

import '../models/ui_state/coffee_beans_filter_options.dart';
import '../models/ui_state/coffee_beans_view_state.dart';
import '../models/ui_state/coffee_beans_sort_options.dart';
import '../models/coffee_beans_model.dart';
import '../services/coffee_beans_filter_service.dart';
import '../services/coffee_beans_sort_service.dart';
import '../widgets/coffee_beans/dialogs/coffee_beans_filter_dialog.dart';
import '../widgets/coffee_beans/dialogs/coffee_beans_sort_dialog.dart';
import '../app_router.gr.dart';
import '../l10n/app_localizations.dart';

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

  // --- Scroll Controller ---
  late final ScrollController scrollController;

  // --- State Models ---
  CoffeeBeansFilterOptions _filterOptions = CoffeeBeansFilterOptions.empty;
  CoffeeBeansViewState _viewState = CoffeeBeansViewState.defaultState;
  CoffeeBeansSortOptions _sortOptions = CoffeeBeansSortOptions.defaultSort;

  // --- Data State ---
  List<CoffeeBeansModel> _allBeans = [];
  List<CoffeeBeansModel> _filteredBeans = [];
  bool _isLoading = false;
  String? _error;

  // --- Available Filter Options ---
  List<String> _availableRoasters = [];
  List<String> _availableOrigins = [];

  // --- Constructor ---
  CoffeeBeansController({
    CoffeeBeansFilterService? filterService,
    CoffeeBeansSortService? sortService,
  })  : _filterService = filterService ?? const CoffeeBeansFilterService(),
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

  double calculateBottomBarLift(BuildContext context) {
    return kBottomNavigationBarHeight / 4 +
        MediaQuery.of(context).padding.bottom;
  }

  // --- Lifecycle ---
  @override
  void dispose() {
    scrollController.removeListener(_handleScroll);
    scrollController.dispose();
    searchController.removeListener(_handleSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  // --- Initialization ---
  Future<void> initialize(BuildContext context) async {
    _setLoading(true);
    try {
      // Load saved preferences
      final savedViewMode = await _sortService.loadViewMode();
      final savedSortOptions = await _sortService.loadSortOptions();

      _viewState = _viewState.copyWith(viewMode: savedViewMode);
      _sortOptions = savedSortOptions;

      // Load filter options
      await _loadFilterOptions(context);

      // Load initial data
      await refreshData(context);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadFilterOptions(BuildContext context) async {
    try {
      _availableRoasters = await _filterService.fetchAvailableRoasters(context);
      _availableOrigins = await _filterService.fetchAvailableOrigins(context);
    } catch (e) {
      // Handle error silently, keep empty lists
    }
  }

  // --- Data Management ---
  Future<void> refreshData(BuildContext context) async {
    _setLoading(true);
    try {
      // Fetch filtered data from database
      _allBeans = await _filterService.applyFilters(context, _filterOptions);

      // Apply search filter
      var searchFiltered =
          _filterService.applySearch(_allBeans, _viewState.searchQuery);

      // Apply sorting
      _filteredBeans = _sortService.applySorting(searchFiltered, _sortOptions);

      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
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
    final isScrollingDown = scrollController.position.userScrollDirection ==
        ScrollDirection.reverse;
    final isScrollingUp = scrollController.position.userScrollDirection ==
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
    final newViewMode =
        _viewState.viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list;
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

    if (result != null) {
      _filterOptions = result;
      await _updateOriginsForSelectedRoasters(context);
      await refreshData(context);
    }
  }

  Future<void> _updateOriginsForSelectedRoasters(BuildContext context) async {
    try {
      _availableOrigins = await _filterService.fetchOriginsForRoasters(
        context,
        _filterOptions.selectedRoasters,
      );

      // Update selected origins to only include those still available
      final updatedSelectedOrigins =
          await _filterService.updateOriginsForSelectedRoasters(
        context,
        _filterOptions.selectedRoasters,
        _filterOptions.selectedOrigins,
      );

      _filterOptions =
          _filterOptions.copyWith(selectedOrigins: updatedSelectedOrigins);
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
    var searchFiltered =
        _filterService.applySearch(_allBeans, _viewState.searchQuery);

    // Apply sorting
    _filteredBeans = _sortService.applySorting(searchFiltered, _sortOptions);
  }

  // --- Sort Management ---
  Future<void> showSortDialog(BuildContext context) async {
    final result = await showDialog<SortOption>(
      context: context,
      builder: (context) => CoffeeBeansSortDialog(
        currentSort: _sortOptions.sortOption,
      ),
    );

    if (result != null) {
      _sortOptions = _sortOptions.copyWith(sortOption: result);
      await _sortService.saveSortOptions(_sortOptions);
      _applyLocalFilters();
      notifyListeners();
    }
  }

  // --- Navigation ---
  Future<void> navigateToNewBeans(BuildContext context) async {
    final result = await context.router.push(NewBeansRoute());
    if (result != null && result is String) {
      await refreshData(context);
    }
  }

  void navigateToBeanDetail(BuildContext context, String uuid) {
    context.router.push(CoffeeBeansDetailRoute(uuid: uuid));
  }

  // --- Bean Actions ---
  Future<void> deleteBeans(BuildContext context, String uuid) async {
    // This would typically be handled by the provider, but we need to refresh after
    await refreshData(context);
  }

  Future<void> toggleFavoriteStatus(
      BuildContext context, String uuid, bool isFavorite) async {
    // This would typically be handled by the provider, but we need to refresh after
    await refreshData(context);
  }
}
