import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

/// `resetBrewingMethodPreferences()` clears both shown/hidden sets (memory +
/// SharedPreferences), notifies listeners, and reports whether anything was
/// actually cleared so callers can skip a no-op analytics event.
void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = openTestDatabase();
    addTearDown(db.close);
  });

  Future<RecipeProvider> buildProvider(
    Map<String, Object> initialPrefs,
  ) async {
    if (initialPrefs.isNotEmpty) {
      SharedPreferences.setMockInitialValues(initialPrefs);
    }
    final provider = RecipeProvider(
      const Locale('en'),
      const <Locale>[],
      db,
      DatabaseProvider(db),
    );
    await provider.ensureDataReady();
    return provider;
  }

  test('clears both sets and prefs, notifies once, returns true', () async {
    final provider = await buildProvider(const {
      'shownBrewingMethodIds': ['v60', 'aero'],
      'hiddenBrewingMethodIds': ['espresso'],
    });
    expect(provider.shownBrewingMethodIds.value, {'v60', 'aero'});
    expect(provider.hiddenBrewingMethodIds.value, {'espresso'});

    var notifications = 0;
    provider.addListener(() => notifications++);

    final changed = await provider.resetBrewingMethodPreferences();

    expect(changed, isTrue);
    expect(provider.shownBrewingMethodIds.value, isEmpty);
    expect(provider.hiddenBrewingMethodIds.value, isEmpty);
    expect(notifications, 1);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('shownBrewingMethodIds'), isEmpty);
    expect(prefs.getStringList('hiddenBrewingMethodIds'), isEmpty);
  });

  test('returns false without notifying when both sets are already empty',
      () async {
    final provider = await buildProvider(const {});

    var notifications = 0;
    provider.addListener(() => notifications++);

    final changed = await provider.resetBrewingMethodPreferences();

    expect(changed, isFalse);
    expect(notifications, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('shownBrewingMethodIds'), isFalse);
    expect(prefs.containsKey('hiddenBrewingMethodIds'), isFalse);
  });
}
