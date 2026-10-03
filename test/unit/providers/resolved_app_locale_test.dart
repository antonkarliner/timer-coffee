import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/services/resolved_app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

/// The push-token write reads [ResolvedAppLocale] instead of the `locale`
/// pref (plan 076 §1), so every language change made through
/// [RecipeProvider.setLocale] must reach it — that is what rewrites the
/// token row's language.
void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ResolvedAppLocale.languageCode.value = 'de';
    db = openTestDatabase();
    addTearDown(db.close);
    addTearDown(() => ResolvedAppLocale.languageCode.value = null);
  });

  Future<RecipeProvider> buildProvider() async {
    final provider = RecipeProvider(
      const Locale('de'),
      const <Locale>[],
      db,
      DatabaseProvider(db),
    );
    await provider.ensureDataReady();
    return provider;
  }

  test('setLocale publishes the new language once', () async {
    final provider = await buildProvider();
    final seen = <String?>[];
    void listener() => seen.add(ResolvedAppLocale.languageCode.value);
    ResolvedAppLocale.languageCode.addListener(listener);
    addTearDown(() => ResolvedAppLocale.languageCode.removeListener(listener));

    await provider.setLocale(const Locale('fr'));

    expect(ResolvedAppLocale.languageCode.value, 'fr');
    expect(seen, ['fr']);
  });

  test('setLocale to the current locale does not notify', () async {
    final provider = await buildProvider();
    var notifications = 0;
    void listener() => notifications++;
    ResolvedAppLocale.languageCode.addListener(listener);
    addTearDown(() => ResolvedAppLocale.languageCode.removeListener(listener));

    await provider.setLocale(const Locale('de'));

    expect(ResolvedAppLocale.languageCode.value, 'de');
    expect(notifications, 0);
  });
}
