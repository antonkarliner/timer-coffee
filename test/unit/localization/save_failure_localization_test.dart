import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/manual_brew_entry_screen.dart';
import 'package:coffee_timer/screens/new_beans_screen.dart';
import 'package:coffee_timer/widgets/stats/beans_stat_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/brew_flow_async_context_test.mocks.dart';

void main() {
  const rawFailure = 'sensitive database failure';

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

  testWidgets('new-beans save failure uses safe localized feedback', (
    tester,
  ) async {
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    when(
      coffeeBeansProvider.addCoffeeBeans(any),
    ).thenThrow(StateError(rawFailure));

    await tester.pumpWidget(
      ChangeNotifierProvider<CoffeeBeansProvider>.value(
        value: coffeeBeansProvider,
        child: localizedApp(const NewBeansScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(NewBeansScreen)),
    )!;
    final requiredFields = find.byType(TextFormField);
    await tester.enterText(requiredFields.at(0), 'Test roaster');
    await tester.enterText(requiredFields.at(1), 'Test beans');
    await tester.enterText(requiredFields.at(2), 'Test origin');
    await tester.pump();

    await tester.tap(find.text(l10n.addCoffeeBeans).last);
    await tester.pumpAndSettle();

    expect(find.text(l10n.coffeeBeansSaveFailed), findsOneWidget);
    expect(find.textContaining(rawFailure), findsNothing);
  });

  testWidgets('manual brew save failure uses safe localized feedback', (
    tester,
  ) async {
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
    when(
      userStatProvider.insertUserStat(
        recipeId: anyNamed('recipeId'),
        coffeeAmount: anyNamed('coffeeAmount'),
        waterAmount: anyNamed('waterAmount'),
        sweetnessSliderPosition: anyNamed('sweetnessSliderPosition'),
        strengthSliderPosition: anyNamed('strengthSliderPosition'),
        brewingMethodId: anyNamed('brewingMethodId'),
        statUuid: anyNamed('statUuid'),
        coffeeBeansUuid: anyNamed('coffeeBeansUuid'),
        grindSize: anyNamed('grindSize'),
        waterTemp: anyNamed('waterTemp'),
        entrySource: anyNamed('entrySource'),
        createdAt: anyNamed('createdAt'),
        notes: anyNamed('notes'),
        tags: anyNamed('tags'),
      ),
    ).thenThrow(StateError(rawFailure));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
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
    final saveButton = find.text(l10n.save);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text(l10n.brewEntrySaveFailed), findsOneWidget);
    expect(find.textContaining(rawFailure), findsNothing);
  });

  testWidgets('statistics modal hides load exception details', (tester) async {
    var fullListCalls = 0;

    await tester.pumpWidget(
      localizedApp(
        Scaffold(
          body: BeansStatListCard<int>(
            label: 'Test stats',
            leadingIcon: const Icon(Icons.coffee),
            previewListFuture: (_) async => const [1],
            fullListFuture: (_) async {
              fullListCalls += 1;
              if (fullListCalls > 1) throw StateError(rawFailure);
              return const [1, 2];
            },
            itemBuilder: (_, item, {isPreview = false}) => Text('$item'),
            emptyText: 'Empty',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(BeansStatListCard<int>)),
    )!;
    await tester.tap(find.text(l10n.showMore));
    await tester.pumpAndSettle();

    expect(find.text(l10n.failedToLoadData), findsOneWidget);
    expect(find.textContaining(rawFailure), findsNothing);
  });
}
