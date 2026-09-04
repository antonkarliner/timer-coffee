import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/manual_brew_entry_screen.dart';
import 'package:coffee_timer/widgets/fields/date_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'brew_flow_async_context_test.mocks.dart';

/// Regression coverage for the `DateField` "blank on first mount" bug.
///
/// [DateField] used to call `_updateDisplayValue()` (which needs
/// `AppLocalizations.of(context)`) from `initState()`. That inherited-widget
/// lookup throws during `initState`, and a surrounding `try/catch` swallowed
/// the throw, so `_selectedDate` was silently nulled. Net effect: any
/// `DateField` mounted with a non-null `initialValue` on its very first
/// build rendered blank instead of showing that date.
///
/// [ManualBrewEntryScreen] hits this exact path in production:
/// `_selectedDate` defaults to `DateTime.now()` (never null), but the
/// `DateField` for the brew date is not in the initial tree — it only
/// appears after the user picks a brewing method and a recipe — so it
/// mounts fresh with a non-null `initialValue` the first time it builds.
/// That is exactly the broken path. The bug is now fixed by splitting
/// parsing (`initState`) from formatting (`didChangeDependencies`); this
/// test pins the fix down by asserting the brew-date field's controller
/// actually holds the formatted date once it appears, not just that some
/// `Text` widget with that string exists somewhere in the tree.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'hasShownPopup': true});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'hasShownPopup': true});
  });

  Widget localizedApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: child,
    );
  }

  testWidgets(
    'brew date field shows the formatted current date on first mount '
    'after selecting a brewing method and recipe',
    (tester) async {
      final database = MockAppDatabase();
      final brewingMethodsDao = MockBrewingMethodsDao();
      final recipeProvider = MockRecipeProvider();
      final userStatProvider = MockUserStatProvider();
      final coffeeBeansProvider = MockCoffeeBeansProvider();
      final method = BrewingMethodModel(
        brewingMethodId: 'v60',
        brewingMethod: 'V60',
      );
      final recipe = RecipeModel(
        id: 'recipe-1',
        name: 'Test recipe',
        brewingMethodId: method.brewingMethodId,
        coffeeAmount: 15,
        waterAmount: 250,
        grindSize: 'Medium',
        brewTime: const Duration(minutes: 3),
        shortDescription: 'Test recipe',
        steps: const [],
      );

      when(database.brewingMethodsDao).thenReturn(brewingMethodsDao);
      when(
        brewingMethodsDao.getAllBrewingMethods(),
      ).thenAnswer((_) async => [method]);
      when(
        recipeProvider.fetchRecipesForBrewingMethod(method.brewingMethodId),
      ).thenAnswer((_) async => [recipe]);

      // Captured before pumping so it cannot straddle a midnight boundary
      // relative to what the widget itself formats.
      final now = DateTime.now();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppDatabase>.value(value: database),
            ChangeNotifierProvider<RecipeProvider>.value(
              value: recipeProvider,
            ),
            ChangeNotifierProvider<UserStatProvider>.value(
              value: userStatProvider,
            ),
            ChangeNotifierProvider<CoffeeBeansProvider>.value(
              value: coffeeBeansProvider,
            ),
          ],
          child: localizedApp(const ManualBrewEntryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ManualBrewEntryScreen)),
      )!;

      // Drive to the state where the brew-date DateField is visible: select
      // a brewing method, then a recipe. Mirrors
      // test/unit/localization/save_failure_localization_test.dart.
      final methodSelector = find.ancestor(
        of: find.text(l10n.selectBrewingMethod),
        matching: find.byType(InkWell),
      );
      await tester.tap(methodSelector);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, method.brewingMethod));
      await tester.pumpAndSettle();

      final recipeSelector = find.ancestor(
        of: find.text(l10n.selectRecipe),
        matching: find.byType(InkWell),
      );
      await tester.tap(recipeSelector);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, recipe.name));
      await tester.pumpAndSettle();

      // The brew-date field is the only DateField this screen builds (a
      // separate TimeField sits next to it for the time). Scope to its
      // `label` to be explicit about which field is under test.
      final dateFieldFinder = find.byWidgetPredicate(
        (w) => w is DateField && w.label == l10n.brewDate,
      );
      expect(dateFieldFinder, findsOneWidget);

      // Format the date the same way the widget does — `DateFormat.yMd`
      // with the app's current locale — from a `DateTime.now()` sampled in
      // this test, not a hardcoded date, so this cannot flake at midnight
      // or on a different locale's date order.
      final expectedDisplay = DateFormat.yMd(l10n.localeName).format(now);

      // Assert on the field's actual controller text, not `find.text`.
      // Material's `InputDecorator` keeps the hint `Text` in the tree at
      // zero opacity even once there is content (for its fade animation),
      // so `find.text` alone is not a reliable "the field shows a date"
      // signal — this is exactly the trap noted in
      // dates_card_roast_date_confirmation_test.dart.
      final textField = tester.widget<TextFormField>(
        find.descendant(
          of: dateFieldFinder,
          matching: find.byType(TextFormField),
        ),
      );
      expect(textField.controller?.text, expectedDisplay);
      expect(tester.takeException(), isNull);
    },
  );
}
