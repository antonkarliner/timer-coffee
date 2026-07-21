import 'dart:async';

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:provider/provider.dart';

import '../database/database.dart';
import '../models/coffee_beans_model.dart';
import '../providers/coffee_beans_provider.dart';
import '../providers/user_stat_provider.dart';
import '../services/feature_flags/feature_flags_repository.dart';
import '../services/local_notification_scheduler_service.dart';
import '../services/roaster_color_service.dart';
import '../services/roaster_directory_service.dart';
import '../services/roaster_logo_service.dart';
import '../app_router.gr.dart';
import '../utils/app_logger.dart';

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
  RoasterColorResult? _roasterColorResult;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUuid;
  int? _brewsLeft;
  bool _isDisposed = false;
  bool _ancillaryRequested = false;
  bool _ancillaryStarted = false;

  // --- Constructor ---
  CoffeeBeansDetailController({RoasterLogoService? logoService})
    : _logoService = logoService ?? const RoasterLogoService();

  // --- Getters ---

  /// The currently loaded coffee bean data
  CoffeeBeansModel? get bean => _bean;

  /// The roaster logo result containing original and mirror URLs
  RoasterLogoResult? get logoResult => _logoResult;

  /// The logo color analysis result (vibrant color, monochrome, or none).
  RoasterColorResult? get roasterColorResult => _roasterColorResult;

  /// Whether a loading operation is in progress
  bool get isLoading => _isLoading;

  /// Whether an error has occurred
  bool get hasError => _errorMessage != null;

  /// The current error message, if any
  String? get errorMessage => _errorMessage;

  /// The UUID of the currently loaded bean
  String? get currentUuid => _currentUuid;

  /// Estimated remaining brews based on the user's median dose. Null when
  /// no reliable estimate is available (insufficient brew history, no
  /// package weight, or estimate rounds to zero).
  int? get brewsLeft => _brewsLeft;

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
    await loadBean(context, uuid, deferAncillary: true);
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
  Future<void> loadBean(
    BuildContext context,
    String uuid, {
    bool deferAncillary = false,
  }) async {
    if (_isDisposed || !context.mounted) return;
    _setLoading(true);
    _clearError();
    _brewsLeft = null;
    _ancillaryStarted = false;

    try {
      final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
        context,
        listen: false,
      );

      // Load bean data
      final bean = await coffeeBeansProvider.fetchCoffeeBeansByUuid(uuid);

      if (_isDisposed || !context.mounted) return;

      if (bean == null) {
        _setError('Coffee bean not found');
        return;
      }

      _bean = bean;
      _currentUuid = uuid;
      _applyCachedBundle(context);

      if (!deferAncillary || _ancillaryRequested) {
        _startAncillaryLoads(context);
      }
    } catch (error) {
      _setError('Failed to load coffee bean: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Fast path: when the roaster bundle is already in memory (the beans list
  /// fetched it for its cards), apply logo and backend color synchronously so
  /// the first content frame renders complete — no deferred pop-in, no flash.
  void _applyCachedBundle(BuildContext context) {
    final roaster = _bean?.roaster;
    if (roaster == null || roaster.isEmpty) return;
    final directory = RoasterDirectoryService.instance;
    if (!directory.isCached(roaster)) return;
    final bundle = directory.peekBundle(roaster);
    final logoResult = RoasterLogoResult.success(
      originalUrl: bundle?['roaster_logo_url'],
      mirrorUrl: bundle?['roaster_logo_mirror_url'],
      dominantColorHex: bundle?['dominant_color_hex'],
    );
    _logoResult = logoResult;
    final flags = Provider.of<FeatureFlagsRepository>(context, listen: false);
    if (logoResult.hasAnyLogo &&
        flags.roasterBackendColor &&
        logoResult.dominantColorHex != null) {
      _roasterColorResult = RoasterColorService.fromBackendHex(
        logoResult.dominantColorHex,
      );
    }
  }

  /// Called by the screen once the route transition has completed. Kicks off
  /// the deferred logo/color/brews-left loads so their work and rebuilds do
  /// not compete with the push animation.
  void loadAncillaryData(BuildContext context) {
    _ancillaryRequested = true;
    if (_isDisposed || !context.mounted) return;
    if (_bean != null && !_ancillaryStarted) {
      _startAncillaryLoads(context);
    }
  }

  void _startAncillaryLoads(BuildContext context) {
    _ancillaryStarted = true;
    final backendColorEnabled = Provider.of<FeatureFlagsRepository>(
      context,
      listen: false,
    ).roasterBackendColor;
    // Load roaster logos concurrently (don't block on logo loading), unless
    // the fast path in _applyCachedBundle already supplied them — then only
    // fill in color analysis if the backend had no hex yet.
    if (_logoResult == null) {
      _loadRoasterLogos(
        context,
        _bean!.roaster,
        backendColorEnabled: backendColorEnabled,
      );
    } else {
      _analyzeLogoColorIfNeeded(backendColorEnabled);
    }
    // Compute brews-left estimate concurrently (don't block on it)
    _loadBrewsLeft(context, _bean!);
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
    if (!_isDisposed && context.mounted && _currentUuid != null) {
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
    BuildContext context,
    String roasterName, {
    required bool backendColorEnabled,
  }) async {
    try {
      final logoResult = await _logoService.fetchRoasterLogos(
        context,
        roasterName,
      );
      if (_isDisposed) return;
      _logoResult = logoResult;

      // Analyse logo color for screen background tinting (gated by feature
      // flag). When the hex is already known this is synchronous, so it's
      // folded into the same notify as the logo result (one rebuild).
      if (logoResult.isSuccess &&
          logoResult.hasAnyLogo &&
          backendColorEnabled &&
          logoResult.dominantColorHex != null) {
        _roasterColorResult = RoasterColorService.fromBackendHex(
          logoResult.dominantColorHex,
        );
      }
      _notifyListeners();

      await _analyzeLogoColorIfNeeded(backendColorEnabled);
    } catch (error) {
      // Logo loading failures are handled silently
      // The UI will show fallback icons instead
      AppLogger.debug(
        '[CoffeeBeansDetailController] Failed to load roaster logos for $roasterName: $error',
      );
    }
  }

  /// Runs client-side logo color analysis when the backend hasn't supplied a
  /// dominant-color hex yet. No-op when there's no logo, the flag is off, or
  /// a color result is already in hand (e.g. from the warm-cache fast path or
  /// a backend hex applied above).
  Future<void> _analyzeLogoColorIfNeeded(bool backendColorEnabled) async {
    final logoResult = _logoResult;
    if (logoResult == null ||
        !logoResult.isSuccess ||
        !logoResult.hasAnyLogo ||
        _roasterColorResult != null ||
        logoResult.dominantColorHex != null) {
      return;
    }
    if (!backendColorEnabled) return;
    final colorResult = await RoasterColorService.instance.analyseLogoColor(
      logoResult.originalUrl,
      logoResult.mirrorUrl,
    );
    if (_isDisposed) return;
    _roasterColorResult = colorResult;
    _notifyListeners();
  }

  /// Computes the estimated remaining brews for the loaded bean using the
  /// user's brewing history. Failures are swallowed: this is a best-effort
  /// hint, never a blocker for the screen.
  Future<void> _loadBrewsLeft(
    BuildContext context,
    CoffeeBeansModel bean,
  ) async {
    final uuid = bean.beansUuid;
    try {
      final userStatProvider = Provider.of<UserStatProvider>(
        context,
        listen: false,
      );
      _brewsLeft = await userStatProvider.estimateBrewsLeft(
        beansUuid: uuid,
        packageWeightGrams: bean.validatedPackageWeightGrams,
      );
      if (_isDisposed) return;
      _notifyListeners();
    } catch (error) {
      AppLogger.debug(
        '[CoffeeBeansDetailController] Failed to compute brews left: $error',
      );
      _brewsLeft = null;
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
  /// A `Future<bool>` indicating whether the operation was successful
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
      final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
        context,
        listen: false,
      );

      final newFavoriteStatus = !_bean!.isFavorite;

      await coffeeBeansProvider.toggleFavoriteStatus(
        _bean!.beansUuid,
        newFavoriteStatus,
      );

      // Refresh data to get updated state
      if (_isDisposed || !context.mounted) return true;
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
      final sanitizedUuid = AppLogger.sanitize(_bean!.beansUuid);
      AppLogger.debug(
        '[CoffeeBeansDetailController] Navigating to edit screen for UUID: $sanitizedUuid',
      );
      final result = await context.router.push(
        NewBeansRoute(uuid: _bean!.beansUuid),
      );

      if (_isDisposed || !context.mounted) return;

      final sanitizedResult = AppLogger.sanitize(result);
      AppLogger.debug(
        '[CoffeeBeansDetailController] Returned from edit screen with result: $sanitizedResult (type: ${result.runtimeType})',
      );

      // Refresh data if the edit was successful
      if (result is String) {
        AppLogger.debug(
          '[CoffeeBeansDetailController] Result is String, refreshing data...',
        );
        await refreshData(context);
        AppLogger.debug('[CoffeeBeansDetailController] Data refresh completed');
      } else {
        AppLogger.debug(
          '[CoffeeBeansDetailController] Result is not String, skipping refresh. Result: $sanitizedResult',
        );
      }
    } catch (error) {
      AppLogger.error(
        '[CoffeeBeansDetailController] Error in navigateToEdit',
        errorObject: error,
      );
      _setError('Failed to navigate to edit screen: $error');
    }
  }

  // --- State Management ---

  /// Sets the loading state and notifies listeners if changed.
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _notifyListeners();
    }
  }

  /// Sets an error message and notifies listeners.
  void _setError(String message) {
    _errorMessage = message;
    _notifyListeners();
  }

  /// Clears the current error state.
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      _notifyListeners();
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
    _roasterColorResult = null;
    _currentUuid = null;
    _clearError();
    _setLoading(false);
  }

  // --- Lifecycle ---

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _notifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  /// Sets the package weight to 0 grams for the current bean
  Future<bool> setPackageWeightToZero(BuildContext context) async {
    if (_bean == null) {
      _setError('No bean data available');
      return false;
    }

    try {
      final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
        context,
        listen: false,
      );

      final beansUuid = _bean!.beansUuid;
      final updatedBeans = _bean!.copyWith(packageWeightGrams: 0.0);
      await coffeeBeansProvider.updateCoffeeBeans(updatedBeans);

      // Manually emptied the bag — fire the depletion review nudge (best-effort;
      // all eligibility gating lives inside the scheduler).
      if (context.mounted) {
        final database = Provider.of<AppDatabase>(context, listen: false);
        final locale = Localizations.localeOf(context).languageCode;
        unawaited(
          LocalNotificationSchedulerService.instance
              .maybeScheduleBeanReviewNudgeOnDepletion(
                database: database,
                beansUuid: beansUuid,
                locale: locale,
              ),
        );
      }

      // Refresh data to get updated state
      if (_isDisposed || !context.mounted) return true;
      await refreshData(context);

      return true;
    } catch (error) {
      _setError('Failed to set inventory to zero: $error');
      return false;
    }
  }

  // --- Notes ---

  /// Saves the notes for the current bean inline (without navigating to edit screen).
  /// Saves the inline-edited "Notes & Preferences" fields. Both [notes] and
  /// [grindSize] are optional; only provided values are written.
  Future<bool> saveNotesAndGrindSize(
    BuildContext context, {
    String? notes,
    String? grindSize,
  }) async {
    if (_bean == null) return false;

    try {
      final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
        context,
        listen: false,
      );
      var updatedBeans = _bean!;
      if (notes != null) {
        updatedBeans = updatedBeans.copyWith(notes: notes.trim());
      }
      if (grindSize != null) {
        updatedBeans = updatedBeans.copyWith(grindSize: grindSize.trim());
      }
      await coffeeBeansProvider.updateCoffeeBeans(updatedBeans);
      if (_isDisposed || !context.mounted) return true;
      await refreshData(context);
      return true;
    } catch (error) {
      _setError('Failed to save notes: $error');
      return false;
    }
  }

  // --- Delete ---

  /// Deletes the current bean and pops the screen.
  Future<bool> deleteBean(BuildContext context) async {
    if (_bean?.beansUuid == null) {
      _setError('No bean data available');
      return false;
    }

    try {
      final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(
        context,
        listen: false,
      );
      await coffeeBeansProvider.deleteCoffeeBeans(_bean!.beansUuid);
      return true;
    } catch (error) {
      _setError('Failed to delete coffee bean: $error');
      return false;
    }
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
