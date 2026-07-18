import 'package:coffee_timer/models/diary_entry.dart';

class DiaryGroup {
  const DiaryGroup({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.roaster,
    required this.entries,
    required this.count,
    required this.avgRating,
    required this.lastBrew,
    required this.ratingSeries,
    required this.isDialedIn,
  });

  final String key;
  final String title;
  final String? subtitle;
  final String? roaster;
  final List<DiaryEntry> entries;
  final int count;
  final double? avgRating;
  final DateTime lastBrew;
  final List<double> ratingSeries;
  final bool isDialedIn;

  /// Groups the diary [entries] by coffee bean entirely in memory.
  ///
  /// Grouping is done in Dart rather than via a DAO/SQL aggregate on purpose:
  /// the diary loads its full non-deleted history in one joined query
  /// (`UserStatsDao.fetchDiaryEntries`, the Phase 4 N+1 fix), so reusing that
  /// already-materialized list avoids extra round-trips and keeps the timeline
  /// and grouped views derived from identical rows. Cost scales with history
  /// size but is negligible at the hundreds/low-thousands of brews a diary
  /// realistically holds.
  ///
  /// NUANCE — pagination: this assumes the complete set is in memory. If the
  /// timeline is ever windowed/paginated, groups could span rows that aren't
  /// loaded, and aggregation must move to the DAO (SQL `GROUP BY` + a
  /// `group_concat`-style rating series) so it operates over all history. The
  /// call site is a single line in `brew_diary_screen.dart`, so the switch is
  /// cheap when that day comes.
  static List<DiaryGroup> build(List<DiaryEntry> entries) {
    final groupedEntries = <String, List<DiaryEntry>>{};
    for (final entry in entries) {
      final key = entry.coffeeBeansUuid?.trim();
      if (key == null || key.isEmpty) continue;
      groupedEntries.putIfAbsent(key, () => []).add(entry);
    }

    final groups = groupedEntries.entries.map((groupEntry) {
      final groupEntries = groupEntry.value;
      final newestEntry = groupEntries.reduce(
        (current, entry) =>
            entry.createdAt.isAfter(current.createdAt) ? entry : current,
      );
      final ratings = groupEntries
          .map((entry) => entry.rating)
          .whereType<double>()
          .toList();
      final chronologicalRatings = groupEntries.reversed
          .map((entry) => entry.rating)
          .whereType<double>()
          .toList();
      final firstEntry = groupEntries.first;

      return DiaryGroup(
        key: groupEntry.key,
        title: firstEntry.beanName ?? firstEntry.recipeName,
        subtitle: firstEntry.roaster,
        roaster: firstEntry.roaster,
        entries: List.unmodifiable(groupEntries),
        count: groupEntries.length,
        avgRating: ratings.isEmpty
            ? null
            : ratings.reduce((a, b) => a + b) / ratings.length,
        lastBrew: newestEntry.createdAt,
        ratingSeries: List.unmodifiable(chronologicalRatings),
        // A group is dialed in when its latest brew is balanced or rated 4+.
        isDialedIn:
            newestEntry.tasteBalance == 0 ||
            (newestEntry.rating != null && newestEntry.rating! >= 4.0),
      );
    }).toList()..sort((a, b) => b.lastBrew.compareTo(a.lastBrew));

    return groups;
  }
}
