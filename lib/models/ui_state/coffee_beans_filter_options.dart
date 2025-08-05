/// Immutable model representing filter options for coffee beans.
///
/// This model encapsulates all filter state including selected roasters,
/// origins, and favorite-only filtering. It follows the immutable pattern
/// with copyWith() method for state updates.
class CoffeeBeansFilterOptions {
  /// List of selected roaster names for filtering
  final List<String> selectedRoasters;

  /// List of selected origin names for filtering
  final List<String> selectedOrigins;

  /// Whether to show only favorite beans
  final bool isFavoriteOnly;

  const CoffeeBeansFilterOptions({
    required this.selectedRoasters,
    required this.selectedOrigins,
    this.isFavoriteOnly = false,
  });

  /// Creates a new instance with updated values
  CoffeeBeansFilterOptions copyWith({
    List<String>? selectedRoasters,
    List<String>? selectedOrigins,
    bool? isFavoriteOnly,
  }) {
    return CoffeeBeansFilterOptions(
      selectedRoasters: selectedRoasters ?? this.selectedRoasters,
      selectedOrigins: selectedOrigins ?? this.selectedOrigins,
      isFavoriteOnly: isFavoriteOnly ?? this.isFavoriteOnly,
    );
  }

  /// Returns true if any filters are currently active
  bool get hasActiveFilters {
    return selectedRoasters.isNotEmpty ||
        selectedOrigins.isNotEmpty ||
        isFavoriteOnly;
  }

  /// Returns a new instance with all filters cleared
  CoffeeBeansFilterOptions clear() {
    return const CoffeeBeansFilterOptions(
      selectedRoasters: [],
      selectedOrigins: [],
      isFavoriteOnly: false,
    );
  }

  /// Default empty filter options
  static const empty = CoffeeBeansFilterOptions(
    selectedRoasters: [],
    selectedOrigins: [],
    isFavoriteOnly: false,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoffeeBeansFilterOptions &&
          runtimeType == other.runtimeType &&
          _listEquals(selectedRoasters, other.selectedRoasters) &&
          _listEquals(selectedOrigins, other.selectedOrigins) &&
          isFavoriteOnly == other.isFavoriteOnly;

  @override
  int get hashCode =>
      selectedRoasters.hashCode ^
      selectedOrigins.hashCode ^
      isFavoriteOnly.hashCode;

  /// Helper method to compare lists for equality
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'CoffeeBeansFilterOptions('
        'selectedRoasters: $selectedRoasters, '
        'selectedOrigins: $selectedOrigins, '
        'isFavoriteOnly: $isFavoriteOnly)';
  }
}
