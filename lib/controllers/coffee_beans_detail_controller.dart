import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:provider/provider.dart';

import '../models/coffee_beans_model.dart';
import '../providers/coffee_beans_provider.dart';
import '../services/roaster_logo_service.dart';
import '../app_router.gr.dart';

/// Controller for Coffee Beans Detail Screen responsible for:
/// - Managing bean data state and loading operations
/// - Handling favorite toggle functionality
/// - Integrating with RoasterLogoService for logo fetching
/// - Providing navigation methods for edit functionality
/// - Managing error states and loading indicators
///
/// This controller extracts all business logic from the detail screen,
/// following the established controller patterns with dependency injection
/// and reactive state management using ChangeNotifier.
///
/// The controller is designed to be:
/// - **UI-agnostic**: Contains no UI logic, only business logic and state
/// - **Testable**: All dependencies can be injected for unit testing
/// - **Reactive**: Uses ChangeNotifier for automatic UI updates
/// - **Error-resilient**: Comprehensive error handling with user-friendly messages
/// - **Cacheable**: Leverages existing caching mechanisms through services
///
/// Example usage:
/// ```dart
/// class _CoffeeBeansDetailScreenState extends State<CoffeeBeansDetailScreen> {
///   late final CoffeeBeansDetailController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = CoffeeBeansDetailController();
///     _controller.initialize(context, widget.uuid);
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return ChangeNotifierProvider.value(
///       value: _controller,
///       child: Consumer<CoffeeBeansDetailController>(
///         builder: (context, controller, child) {
///           if (controller.isLoading) {
///             return CircularProgressIndicator();
///           }
///           if (controller.hasError) {
///             return Text(controller.errorMessage!);
///           }
///           return _buildContent(controller.bean!, controller.logoResult);
///         },
///       ),
///     );
///   }
/// }
/// ```
class CoffeeBeansDetailController extends ChangeNotifier {
  // --- Services (dependency injection) ---
  final RoasterLogoService _logoService;

  // --- State ---
  CoffeeBeansModel? _bean;
  RoasterLogoResult? _logoResult;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUuid;

  // --- Constructor ---
  CoffeeBeansDetailController({
    RoasterLogoService? logoService,
  }) : _logoService = logoService ?? const RoasterLogoService();

  // --- Getters ---

  /// The currently loaded coffee bean data
  CoffeeBeansModel? get bean => _bean;

  /// The roaster logo result containing original and mirror URLs
  RoasterLogoResult? get logoResult => _logoResult;

  /// Whether a loading operation is in progress
  bool get isLoading => _isLoading;

  /// Whether an error has occurred
  bool get hasError => _errorMessage != null;

  /// The current error message, if any
  String? get errorMessage => _errorMessage;

  /// The UUID of the currently loaded bean
  String? get currentUuid => _currentUuid;

  // --- Computed Properties ---

  /// Whether bean data is available and ready for display
  bool get hasData => _bean != null && !_isLoading;

  /// Whether logos are available for display
  bool get hasLogos =>
      _logoResult?.isSuccess == true && _logoResult!.hasAnyLogo;

  /// The original logo URL, if available
  String? get originalLogoUrl => _logoResult?.originalUrl;

  /// The mirror logo URL, if available
  String? get mirrorLogoUrl => _logoResult?.mirrorUrl;

  // --- Initialization ---

  /// Initializes the controller and loads bean data for the given UUID.
  ///
  /// This method should be called once during the screen's initialization.
  /// It will load the bean data and associated roaster logos concurrently
  /// for optimal performance.
  ///
  /// **Parameters:**
  /// - [context]: BuildContext for accessing providers
  /// - [uuid]: The UUID of the coffee bean to load
  ///
  /// **Error Handling:**
  /// Any errors during initialization are captured and exposed through
  /// the [hasError] and [errorMessage] properties.
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   _controller.initialize(context, widget.uuid);
  /// }
  /// ```
  Future<void> initialize(BuildContext context, String uuid) async {
    _currentUuid = uuid;
    await loadBean(context, uuid);
  }

  // --- Data Loading ---

  /// Loads coffee bean data for the specified UUID.
  ///
  /// This method fetches the bean data from the CoffeeBeansProvider and
  /// simultaneously loads the roaster logos for optimal performance.
  /// The loading state is managed automatically.
  ///
  /// **Parameters:**
  /// - [context]: BuildContext for accessing providers
  /// - [uuid]: The UUID of the coffee bean to load
  ///
  /// **State Changes:**
  /// - Sets loading state during operation
  /// - Updates bean data and logo result on success
  /// - Sets error message on failure
  /// - Notifies listeners of all state changes
  ///
  /// **Error Handling:**
  /// - Network failures are handled gracefully
  /// - Missing bean data is reported as "Bean not found"
  /// - Logo loading failures don't prevent bean data loading
  ///
  /// **Example:**
  /// ```dart
  /// await controller.loadBean(context, 'bean-uuid-123');
  /// if (controller.hasError) {
  ///   // Handle error
  /// } else if (controller.hasData) {
  ///   // Use controller.bean and controller.logoResult
  /// }
  /// ```
  Future<void> loadBean(BuildContext context, String uuid) async {
    _setLoading(true);
    _clearError();

    try {
      final coffeeBeansProvider =
          Provider.of<CoffeeBeansProvider>(context, listen: false);

      // Load bean data
      final bean = await coffeeBeansProvider.fetchCoffeeBeansByUuid(uuid);

      if (bean == null) {
        _setError('Coffee bean not found');
        return;
      }

      _bean = bean;
      _currentUuid = uuid;

      // Load roaster logos concurrently (don't block on logo loading)
      _loadRoasterLogos(context, bean.roaster);
    } catch (error) {
      _setError('Failed to load coffee bean: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Refreshes the current bean data.
  ///
  /// This method reloads the bean data for the currently loaded UUID.
  /// Useful after operations that might have changed the bean data,
  /// such as editing or toggling favorite status.
  ///
  /// **Parameters:**
  /// - [context]: BuildContext for accessing providers
  ///
  /// **Returns:**
  /// A Future that completes when the refresh operation is done
  ///
  /// **Example:**
  /// ```dart
  /// await controller.refreshData(context);
  /// ```
  Future<void> refreshData(BuildContext context) async {
    if (_currentUuid != null) {
      await loadBean(context, _currentUuid!);
    }
  }

  /// Loads roaster logos for the given roaster name.
  ///
  /// This is called automatically during bean loading but can also be
  /// called independently if logo loading failed initially.
  ///
  /// **Parameters:**
  /// - [context]: BuildContext for accessing providers
  /// - [roasterName]: The name of the roaster to fetch logos for
  ///
  /// **Note:** This method runs asynchronously and doesn't block the UI.
  /// Logo loading failures are handled silently to not interfere with
  /// the main bean data display.
  Future<void> _loadRoasterLogos(
      BuildContext context, String roasterName) async {
    try {
      final logoResult =
          await _logoService.fetchRoasterLogos(context, roasterName);
      _logoResult = logoResult;
      notifyListeners();
    } catch (error) {
      // Logo loading failures are handled silently
      // The UI will show fallback icons instead
      debugPrint('Failed to load roaster logos for $roasterName: $error');
    }
  }

  // --- Business Logic ---

  /// Toggles the favorite status of the current bean.
  ///
  /// This method updates the favorite status in the database and refreshes
  /// the local bean data to reflect the change. The operation is performed
  /// optimistically - the UI can update immediately while the database
  /// operation completes in the background.
  ///
  /// **Parameters:**
  /// - [context]: BuildContext for accessing providers
  ///
  /// **Returns:**
  /// A Future<bool> indicating whether the operation was successful
  ///
  /// **Error Handling:**
  /// - Database errors are caught and reported through error state
  /// - The bean data is refreshed regardless to ensure consistency
  ///
  /// **Example:**
  /// ```dart
  /// final success = await controller.toggleFavorite(context);
  /// if (!success) {
  ///   // Show error message
  ///   ScaffoldMessenger.of(context).showSnackBar(
  ///     SnackBar(content: Text(controller.errorMessage!)),
  ///   );
  /// }
  /// ```
  Future<bool> toggleFavorite(BuildContext context) async {
    if (_bean == null) {
      _setError('No bean data available');
      return false;
    }

    try {
      final coffeeBeansProvider =
          Provider.of<CoffeeBeansProvider>(context, listen: false);

      final newFavoriteStatus = !_bean!.isFavorite;

      await coffeeBeansProvider.toggleFavoriteStatus(
        _bean!.beansUuid!,
        newFavoriteStatus,
      );

      // Refresh data to get updated state
      await refreshData(context);

      return true;
    } catch (error) {
      _setError('Failed to toggle favorite status: $error');
      return false;
    }
  }

  // --- Navigation ---

  /// Navigates to the edit screen for the current bean.
  ///
  /// This method pushes the NewBeansRoute with the current bean's UUID
  /// for editing. When the user returns from editing, the bean data
  /// is automatically refreshed to reflect any changes.
  ///
  /// **Parameters:**
  /// - [context]: BuildContext for navigation
  ///
  /// **Returns:**
  /// A Future that completes when the user returns from the edit screen
  ///
  /// **Behavior:**
  /// - Navigates to edit screen with current bean UUID
  /// - Refreshes bean data when user returns
  /// - Handles navigation errors gracefully
  ///
  /// **Example:**
  /// ```dart
  /// await controller.navigateToEdit(context);
  /// // Bean data is automatically refreshed after editing
  /// ```
  Future<void> navigateToEdit(BuildContext context) async {
    if (_bean?.beansUuid == null) {
      _setError('Cannot edit: No bean data available');
      return;
    }

    try {
      print('DEBUG: Navigating to edit screen for UUID: ${_bean!.beansUuid}');
      final result = await context.router.push(
        NewBeansRoute(uuid: _bean!.beansUuid!),
      );

      print(
          'DEBUG: Returned from edit screen with result: $result (type: ${result.runtimeType})');

      // Refresh data if the edit was successful
      if (result is String) {
        print('DEBUG: Result is String, refreshing data...');
        await refreshData(context);
        print('DEBUG: Data refresh completed');
      } else {
        print('DEBUG: Result is not String, skipping refresh. Result: $result');
      }
    } catch (error) {
      print('DEBUG: Error in navigateToEdit: $error');
      _setError('Failed to navigate to edit screen: $error');
    }
  }

  // --- State Management ---

  /// Sets the loading state and notifies listeners if changed.
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Sets an error message and notifies listeners.
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clears the current error state.
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Clears all state data.
  ///
  /// This method resets the controller to its initial state.
  /// Useful when switching between different beans or when
  /// the controller needs to be reused.
  void clearData() {
    _bean = null;
    _logoResult = null;
    _currentUuid = null;
    _clearError();
    _setLoading(false);
  }

  // --- Lifecycle ---

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  // --- Debug Support ---

  @override
  String toString() {
    return 'CoffeeBeansDetailController('
        'uuid: $_currentUuid, '
        'hasData: $hasData, '
        'isLoading: $_isLoading, '
        'hasError: $hasError'
        ')';
  }
}
