part of 'database.dart';

@DriftAccessor(tables: [UserStats, CoffeeBeans])
class BeansStatsDao extends DatabaseAccessor<AppDatabase>
    with _$BeansStatsDaoMixin {
  final AppDatabase db;

  BeansStatsDao(this.db) : super(db);

  // Total distinct beans brewed in the period
  Future<int> fetchTotalBeansBrewedCount(DateTime start, DateTime end) async {
    final q = customSelect(
      '''
      SELECT COUNT(DISTINCT us.coffee_beans_uuid) AS cnt
      FROM user_stats us
      JOIN coffee_beans cb ON cb.beans_uuid = us.coffee_beans_uuid
      WHERE us.created_at BETWEEN ? AND ?
        AND us.is_deleted = 0
        AND cb.is_deleted = 0
        AND us.coffee_beans_uuid IS NOT NULL
      ''',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {userStats, coffeeBeans},
    );
    final row = await q.getSingle();
    return row.read<int>('cnt');
  }

  // Count of beans whose first brew falls inside the period
  Future<int> fetchNewBeansTriedCount(DateTime start, DateTime end) async {
    final q = customSelect(
      '''
      WITH firsts AS (
        SELECT us.coffee_beans_uuid AS id, MIN(us.created_at) AS first_brew
        FROM user_stats us
        WHERE us.is_deleted = 0 AND us.coffee_beans_uuid IS NOT NULL
        GROUP BY us.coffee_beans_uuid
      )
      SELECT COUNT(*) AS cnt
      FROM firsts
      JOIN coffee_beans cb ON cb.beans_uuid = firsts.id
      WHERE cb.is_deleted = 0 AND first_brew BETWEEN ? AND ?
      ''',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {userStats, coffeeBeans},
    );
    final row = await q.getSingle();
    return row.read<int>('cnt');
  }

  // Distinct origins explored in the period
  Future<int> fetchDistinctOriginsCount(DateTime start, DateTime end) async {
    final q = customSelect(
      '''
      SELECT COUNT(DISTINCT cb.origin) AS cnt
      FROM user_stats us
      JOIN coffee_beans cb ON cb.beans_uuid = us.coffee_beans_uuid
      WHERE us.created_at BETWEEN ? AND ?
        AND us.is_deleted = 0
        AND cb.is_deleted = 0
        AND us.coffee_beans_uuid IS NOT NULL
        AND cb.origin IS NOT NULL
      ''',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {userStats, coffeeBeans},
    );
    final row = await q.getSingle();
    return row.read<int>('cnt');
  }

  // Top origins by brew count
  Future<List<MapEntry<String, int>>> fetchOriginDistribution(
      DateTime start, DateTime end,
      {int limit = 5}) async {
    final q = customSelect(
      '''
      SELECT cb.origin AS key, COUNT(*) AS cnt
      FROM user_stats us
      JOIN coffee_beans cb ON cb.beans_uuid = us.coffee_beans_uuid
      WHERE us.created_at BETWEEN ? AND ?
        AND us.is_deleted = 0
        AND cb.is_deleted = 0
        AND us.coffee_beans_uuid IS NOT NULL
        AND cb.origin IS NOT NULL
      GROUP BY cb.origin
      ORDER BY cnt DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withInt(limit),
      ],
      readsFrom: {userStats, coffeeBeans},
    );
    final rows = await q.get();
    return rows
        .map((r) => MapEntry(r.read<String>('key'), r.read<int>('cnt')))
        .toList();
  }

  // Distinct regions explored in the period
  Future<int> fetchDistinctRegionsCount(DateTime start, DateTime end) async {
    final q = customSelect(
      '''
      SELECT COUNT(DISTINCT cb.region) AS cnt
      FROM user_stats us
      JOIN coffee_beans cb ON cb.beans_uuid = us.coffee_beans_uuid
      WHERE us.created_at BETWEEN ? AND ?
        AND us.is_deleted = 0
        AND cb.is_deleted = 0
        AND us.coffee_beans_uuid IS NOT NULL
        AND cb.region IS NOT NULL
      ''',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {userStats, coffeeBeans},
    );
    final row = await q.getSingle();
    return row.read<int>('cnt');
  }

  // Top regions by brew count
  Future<List<MapEntry<String, int>>> fetchRegionDistribution(
      DateTime start, DateTime end,
      {int limit = 5}) async {
    final q = customSelect(
      '''
      SELECT cb.region AS key, COUNT(*) AS cnt
      FROM user_stats us
      JOIN coffee_beans cb ON cb.beans_uuid = us.coffee_beans_uuid
      WHERE us.created_at BETWEEN ? AND ?
        AND us.is_deleted = 0
        AND cb.is_deleted = 0
        AND us.coffee_beans_uuid IS NOT NULL
        AND cb.region IS NOT NULL
      GROUP BY cb.region
      ORDER BY cnt DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withInt(limit),
      ],
      readsFrom: {userStats, coffeeBeans},
    );
    final rows = await q.get();
    return rows
        .map((r) => MapEntry(r.read<String>('key'), r.read<int>('cnt')))
        .toList();
  }

  // Favorite roasters (by brew counts, min threshold)
  Future<List<MapEntry<String, int>>> fetchFavoriteRoasters(
    DateTime start,
    DateTime end, {
    int limit = 5,
    int minBrews = 2,
  }) async {
    final q = customSelect(
      '''
      SELECT cb.roaster AS key, COUNT(*) AS cnt
      FROM user_stats us
      JOIN coffee_beans cb ON cb.beans_uuid = us.coffee_beans_uuid
      WHERE us.created_at BETWEEN ? AND ?
        AND us.is_deleted = 0
        AND cb.is_deleted = 0
        AND us.coffee_beans_uuid IS NOT NULL
        AND cb.roaster IS NOT NULL
      GROUP BY cb.roaster
      HAVING COUNT(*) >= ?
      ORDER BY cnt DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withInt(minBrews),
        Variable.withInt(limit),
      ],
      readsFrom: {userStats, coffeeBeans},
    );
    final rows = await q.get();
    return rows
        .map((r) => MapEntry(r.read<String>('key'), r.read<int>('cnt')))
        .toList();
  }

  // Count of new roasters discovered in the period
  Future<int> fetchNewRoastersDiscovered(DateTime start, DateTime end) async {
    final q = customSelect(
      '''
      WITH firsts AS (
        SELECT cb.roaster AS roaster, MIN(us.created_at) AS first_brew
        FROM user_stats us
        JOIN coffee_beans cb ON cb.beans_uuid = us.coffee_beans_uuid
        WHERE us.is_deleted = 0
          AND cb.is_deleted = 0
          AND us.coffee_beans_uuid IS NOT NULL
          AND cb.roaster IS NOT NULL
        GROUP BY cb.roaster
      )
      SELECT COUNT(*) AS cnt
      FROM firsts
      WHERE first_brew BETWEEN ? AND ?
      ''',
      variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
      readsFrom: {userStats, coffeeBeans},
    );
    final row = await q.getSingle();
    return row.read<int>('cnt');
  }

  // Full bean distribution (uuid, name, roaster, count) ordered by count desc
  Future<List<BeanUsage>> fetchBeanDistributionFull(
      DateTime start, DateTime end,
      {int limit = 999}) async {
    final q = customSelect(
      '''
      SELECT cb.beans_uuid AS uuid, cb.name, cb.roaster, COUNT(*) AS cnt
      FROM user_stats us
      JOIN coffee_beans cb ON cb.beans_uuid = us.coffee_beans_uuid
      WHERE us.created_at BETWEEN ? AND ?
        AND us.is_deleted = 0
        AND cb.is_deleted = 0
        AND us.coffee_beans_uuid IS NOT NULL
      GROUP BY cb.beans_uuid, cb.name, cb.roaster
      ORDER BY cnt DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withInt(limit),
      ],
      readsFrom: {userStats, coffeeBeans},
    );
    final rows = await q.get();
    return rows
        .map((r) => BeanUsage(
              beansUuid: r.read<String>('uuid'),
              name: r.read<String>('name'),
              roaster: r.read<String>('roaster'),
              count: r.read<int>('cnt'),
            ))
        .toList();
  }

  // New beans list whose first brew falls in the window (chronological)
  Future<List<BeanUsage>> fetchNewBeansList(DateTime start, DateTime end,
      {int limit = 999}) async {
    final q = customSelect(
      '''
      WITH firsts AS (
        SELECT us.coffee_beans_uuid AS id, MIN(us.created_at) AS first_brew
        FROM user_stats us
        WHERE us.is_deleted = 0 AND us.coffee_beans_uuid IS NOT NULL
        GROUP BY us.coffee_beans_uuid
      )
      SELECT cb.beans_uuid AS uuid, cb.name, cb.roaster, firsts.first_brew
      FROM firsts
      JOIN coffee_beans cb ON cb.beans_uuid = firsts.id
      WHERE cb.is_deleted = 0 AND firsts.first_brew BETWEEN ? AND ?
      ORDER BY firsts.first_brew ASC
      LIMIT ?
      ''',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withInt(limit),
      ],
      readsFrom: {userStats, coffeeBeans},
    );
    final rows = await q.get();
    return rows
        .map((r) => BeanUsage(
              beansUuid: r.read<String>('uuid'),
              name: r.read<String>('name'),
              roaster: r.read<String>('roaster'),
              count: 0,
            ))
        .toList();
  }

  // Distinct origins as list of strings (ordered asc)
  Future<List<String>> fetchDistinctOriginsList(DateTime start, DateTime end,
      {int limit = 999}) async {
    final q = customSelect(
      '''
      SELECT DISTINCT cb.origin AS key
      FROM user_stats us
      JOIN coffee_beans cb ON cb.beans_uuid = us.coffee_beans_uuid
      WHERE us.created_at BETWEEN ? AND ?
        AND us.is_deleted = 0
        AND cb.is_deleted = 0
        AND cb.origin IS NOT NULL
        AND cb.origin != ''
      ORDER BY cb.origin ASC
      LIMIT ?
      ''',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withInt(limit),
      ],
      readsFrom: {userStats, coffeeBeans},
    );
    final rows = await q.get();
    return rows.map((r) => r.read<String>('key')).whereType<String>().toList();
  }

  // Distinct regions as list of strings (ordered asc)
  Future<List<String>> fetchDistinctRegionsList(DateTime start, DateTime end,
      {int limit = 999}) async {
    final q = customSelect(
      '''
      SELECT DISTINCT cb.region AS key
      FROM user_stats us
      JOIN coffee_beans cb ON cb.beans_uuid = us.coffee_beans_uuid
      WHERE us.created_at BETWEEN ? AND ?
        AND us.is_deleted = 0
        AND cb.is_deleted = 0
        AND cb.region IS NOT NULL
        AND cb.region != ''
      ORDER BY cb.region ASC
      LIMIT ?
      ''',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withInt(limit),
      ],
      readsFrom: {userStats, coffeeBeans},
    );
    final rows = await q.get();
    return rows.map((r) => r.read<String>('key')).whereType<String>().toList();
  }

  // New roasters discovered in the period as chronological list of roaster names
  Future<List<String>> fetchNewRoastersDiscoveredList(
      DateTime start, DateTime end,
      {int limit = 999}) async {
    final q = customSelect(
      '''
      WITH firsts AS (
        SELECT cb.roaster AS roaster, MIN(us.created_at) AS first_brew
        FROM user_stats us
        JOIN coffee_beans cb ON cb.beans_uuid = us.coffee_beans_uuid
        WHERE us.is_deleted = 0
          AND cb.is_deleted = 0
          AND us.coffee_beans_uuid IS NOT NULL
          AND cb.roaster IS NOT NULL
        GROUP BY cb.roaster
      )
      SELECT firsts.roaster AS key, firsts.first_brew
      FROM firsts
      WHERE first_brew BETWEEN ? AND ?
      ORDER BY first_brew ASC
      LIMIT ?
      ''',
      variables: [
        Variable.withDateTime(start),
        Variable.withDateTime(end),
        Variable.withInt(limit),
      ],
      readsFrom: {userStats, coffeeBeans},
    );
    final rows = await q.get();
    return rows.map((r) => r.read<String>('key')).whereType<String>().toList();
  }
}
