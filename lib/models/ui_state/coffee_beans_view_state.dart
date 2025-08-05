/// Enumeration of available view modes for coffee beans display
enum ViewMode { list, grid }

/// Immutable model representing UI view state for coffee beans screen.
///
/// This model encapsulates all UI state including view mode, edit mode,
/// bottom bar visibility, and search query. It follows the immutable pattern
/// with copyWith() method for state updates.
class CoffeeBeansViewState {
  /// The current view mode (list or grid)
  final ViewMode viewMode;

  /// Whether the screen is in edit mode
  final bool isEditMode;

  /// Whether the bottom bar is visible (for scroll-based hiding)
  final bool isBottomBarVisible;

  /// Current search query text
  final String searchQuery;

  const CoffeeBeansViewState({
    required this.viewMode,
    this.isEditMode = false,
    this.isBottomBarVisible = true,
    this.searchQuery = '',
  });

  /// Creates a new instance with updated values
  CoffeeBeansViewState copyWith({
    ViewMode? viewMode,
    bool? isEditMode,
    bool? isBottomBarVisible,
    String? searchQuery,
  }) {
    return CoffeeBeansViewState(
      viewMode: viewMode ?? this.viewMode,
      isEditMode: isEditMode ?? this.isEditMode,
      isBottomBarVisible: isBottomBarVisible ?? this.isBottomBarVisible,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Returns true if search is currently active
  bool get hasActiveSearch => searchQuery.isNotEmpty;

  /// Default view state
  static const defaultState = CoffeeBeansViewState(
    viewMode: ViewMode.list,
    isEditMode: false,
    isBottomBarVisible: true,
    searchQuery: '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoffeeBeansViewState &&
          runtimeType == other.runtimeType &&
          viewMode == other.viewMode &&
          isEditMode == other.isEditMode &&
          isBottomBarVisible == other.isBottomBarVisible &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode =>
      viewMode.hashCode ^
      isEditMode.hashCode ^
      isBottomBarVisible.hashCode ^
      searchQuery.hashCode;

  @override
  String toString() {
    return 'CoffeeBeansViewState('
        'viewMode: $viewMode, '
        'isEditMode: $isEditMode, '
        'isBottomBarVisible: $isBottomBarVisible, '
        'searchQuery: "$searchQuery")';
  }
}
