import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A SharedPreferences-backed JSON cache entry with a stored timestamp.
/// Callers decide TTL policy at read time, so a single stored entry can serve
/// both "fresh" reads and stale-if-error fallbacks.
class PersistentTtlCache {
  PersistentTtlCache(this.prefix);

  final String prefix;

  String _key(String id) => '$prefix$id';

  /// Returns the stored JSON map for [id], or null when absent/corrupt.
  /// When [maxAge] is given, entries older than it return null unless
  /// [allowStale] is true.
  Future<Map<String, dynamic>?> read(
    String id, {
    Duration? maxAge,
    bool allowStale = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(id));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = decoded['ts'] as int?;
      if (ts == null) return null;
      if (maxAge != null && !allowStale) {
        final age = DateTime.now().millisecondsSinceEpoch - ts;
        if (age > maxAge.inMilliseconds) return null;
      }
      return decoded['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(id),
      jsonEncode({
        'ts': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(id));
  }

  /// Removes every entry under this cache's prefix.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
