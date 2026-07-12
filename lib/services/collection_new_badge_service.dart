import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectionNewBadgeService extends ChangeNotifier {
  static const _kPairsKey = 'collection_badge_first_seen';
  static const _kViewedKey = 'collection_badge_viewed_at';
  static const _kInitializedKey = 'collection_badge_initialized';

  static const newWindow = Duration(days: 14);

  Map<String, Map<String, int>> _firstSeenByCollection = {};
  Map<String, int> _viewedAtByCollection = {};
  bool _initialized = false;
  Future<void>? _initFuture;

  Future<void> init() => _initFuture ??= _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _firstSeenByCollection = _decodeNestedIntMap(prefs.getString(_kPairsKey));
    _viewedAtByCollection = _decodeIntMap(prefs.getString(_kViewedKey));
    _initialized = prefs.getBool(_kInitializedKey) ?? false;
    notifyListeners();
  }

  Future<void> reconcile(Map<String, Set<String>> membersByCollection) async {
    await init();
    final prefs = await SharedPreferences.getInstance();

    if (!_initialized) {
      _firstSeenByCollection = {
        for (final entry in membersByCollection.entries)
          if (entry.value.isNotEmpty)
            entry.key: {for (final recipeId in entry.value) recipeId: 0},
      };
      _initialized = true;
      await prefs.setString(_kPairsKey, jsonEncode(_firstSeenByCollection));
      await prefs.setBool(_kInitializedKey, true);
      notifyListeners();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final reconciled = <String, Map<String, int>>{};
    var changed = false;

    for (final entry in membersByCollection.entries) {
      if (entry.value.isEmpty) continue;
      final stored = _firstSeenByCollection[entry.key];
      final current = <String, int>{};
      for (final recipeId in entry.value) {
        final firstSeen = stored?[recipeId];
        if (firstSeen == null) {
          current[recipeId] = now;
          changed = true;
        } else {
          current[recipeId] = firstSeen;
        }
      }
      reconciled[entry.key] = current;
    }

    if (!changed) {
      for (final entry in _firstSeenByCollection.entries) {
        final current = membersByCollection[entry.key];
        if (current == null ||
            entry.value.keys.any((recipeId) => !current.contains(recipeId))) {
          changed = true;
          break;
        }
      }
    }

    if (!changed) return;

    _firstSeenByCollection = reconciled;
    await prefs.setString(_kPairsKey, jsonEncode(_firstSeenByCollection));
    notifyListeners();
  }

  bool hasNew(String collectionId) {
    final firstSeenValues = _firstSeenByCollection[collectionId]?.values;
    if (firstSeenValues == null) return false;

    final cutoff = DateTime.now().subtract(newWindow).millisecondsSinceEpoch;
    final viewedAt = _viewedAtByCollection[collectionId] ?? 0;
    return firstSeenValues.any(
      (firstSeen) => firstSeen > cutoff && firstSeen > viewedAt,
    );
  }

  Future<void> markViewed(String collectionId) async {
    await init();
    _viewedAtByCollection[collectionId] = DateTime.now().millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kViewedKey, jsonEncode(_viewedAtByCollection));
    notifyListeners();
  }

  static Map<String, Map<String, int>> _decodeNestedIntMap(String? value) {
    if (value == null) return {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return {};
      return {
        for (final collection in decoded.entries)
          if (collection.key is String && collection.value is Map)
            collection.key as String: {
              for (final recipe in (collection.value as Map).entries)
                if (recipe.key is String && recipe.value is num)
                  recipe.key as String: (recipe.value as num).toInt(),
            },
      };
    } on FormatException {
      return {};
    }
  }

  static Map<String, int> _decodeIntMap(String? value) {
    if (value == null) return {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is num)
            entry.key as String: (entry.value as num).toInt(),
      };
    } on FormatException {
      return {};
    }
  }
}
