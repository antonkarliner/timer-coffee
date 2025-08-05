/// Enumeration of available sort options for coffee beans
enum SortOption { dateAdded, name, roaster, origin }

/// Enumeration of sort directions
enum SortDirection { ascending, descending }

/// Immutable model representing sort configuration for coffee beans.
///
/// This model encapsulates the sort option and direction, following
/// the immutable pattern with copyWith() method for state updates.
class CoffeeBeansSortOptions {
  /// The field to sort by
  final SortOption sortOption;

  /// The direction to sort (ascending or descending)
  final SortDirection sortDirection;

  const CoffeeBeansSortOptions({
    required this.sortOption,
    required this.sortDirection,
  });

  /// Creates a new instance with updated values
  CoffeeBeansSortOptions copyWith({
    SortOption? sortOption,
    SortDirection? sortDirection,
  }) {
    return CoffeeBeansSortOptions(
      sortOption: sortOption ?? this.sortOption,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }

  /// Default sort options (newest first, matching current behavior)
  static const defaultSort = CoffeeBeansSortOptions(
    sortOption: SortOption.dateAdded,
    sortDirection: SortDirection.descending,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoffeeBeansSortOptions &&
          runtimeType == other.runtimeType &&
          sortOption == other.sortOption &&
          sortDirection == other.sortDirection;

  @override
  int get hashCode => sortOption.hashCode ^ sortDirection.hashCode;

  @override
  String toString() {
    return 'CoffeeBeansSortOptions('
        'sortOption: $sortOption, '
        'sortDirection: $sortDirection)';
  }
}
