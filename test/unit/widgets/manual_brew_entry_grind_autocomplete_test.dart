import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/manual_brew_entry_screen.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/fields/dropdown_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'brew_flow_async_context_test.mocks.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'hasShownPopup': true});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  testWidgets(
    'grind focus shows recents, search is lazy, and typed text saves',
    (tester) async {
      SharedPreferences.setMockInitialValues({'hasShownPopup': true});
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final database = MockAppDatabase();
      final methodsDao = MockBrewingMethodsDao();
      final recipes = MockRecipeProvider();
      final stats = MockUserStatProvider();
      final beans = MockCoffeeBeansProvider();
      final method = BrewingMethodModel(
        brewingMethodId: 'v60',
        brewingMethod: 'V60',
      );
      final recipe = RecipeModel(
        id: 'recipe-1',
        name: 'Test recipe',
        brewingMethodId: 'v60',
        coffeeAmount: 15,
        waterAmount: 250,
        grindSize: 'Medium',
        brewTime: const Duration(minutes: 3),
        shortDescription: '',
        steps: const [],
      );
      when(database.brewingMethodsDao).thenReturn(methodsDao);
      when(methodsDao.getAllBrewingMethods()).thenAnswer((_) async => [method]);
      when(
        recipes.fetchRecipesForBrewingMethod('v60'),
      ).thenAnswer((_) async => [recipe]);
      when(stats.fetchAllDistinctTags()).thenAnswer((_) async => <String>[]);
      when(
        stats.fetchRecentDistinctGrindSizes(limit: anyNamed('limit')),
      ).thenAnswer(
        (_) async => ['Medium', '18 clicks', '20 clicks', '22 clicks'],
      );
      when(
        stats.fetchAllDistinctGrindSizes(),
      ).thenAnswer((_) async => ['History Fine', 'Medium']);
      when(
        beans.fetchAllDistinctGrindSizes(),
      ).thenAnswer((_) async => ['Bean Fine', 'Coarse']);
      String? savedGrind;
      when(
        stats.insertUserStat(
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
      ).thenAnswer((invocation) async {
        savedGrind = invocation.namedArguments[#grindSize] as String?;
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppDatabase>.value(value: database),
            ChangeNotifierProvider<RecipeProvider>.value(value: recipes),
            ChangeNotifierProvider<UserStatProvider>.value(value: stats),
            ChangeNotifierProvider<CoffeeBeansProvider>.value(value: beans),
            ChangeNotifierProvider<DateTimeFormatService>(
              create: (_) => DateTimeFormatService(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ManualBrewEntryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final loc = AppLocalizations.of(
        tester.element(find.byType(ManualBrewEntryScreen)),
      )!;
      await tester.tap(
        find.ancestor(
          of: find.text(loc.selectBrewingMethod),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, method.brewingMethod));
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(
          of: find.text(loc.selectRecipe),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, recipe.name));
      await tester.pumpAndSettle();

      verifyNever(
        stats.fetchRecentDistinctGrindSizes(limit: anyNamed('limit')),
      );
      verifyNever(stats.fetchAllDistinctGrindSizes());
      verifyNever(beans.fetchAllDistinctGrindSizes());
      final grind = find.byType(DropdownSearchField);
      final input = find.descendant(
        of: grind,
        matching: find.byType(TextFormField),
      );
      expect(tester.widget<TextFormField>(input).controller!.text, 'Medium');
      await tester.ensureVisible(input);
      await tester.tap(input);
      await tester.pumpAndSettle();
      expect(find.text('18 clicks'), findsOneWidget);
      expect(find.text('20 clicks'), findsOneWidget);
      expect(find.text('22 clicks'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CompositedTransformFollower),
          matching: find.text('Medium'),
        ),
        findsNothing,
      );
      expect(find.text('Coarse'), findsNothing);
      verify(stats.fetchRecentDistinctGrindSizes(limit: 4)).called(1);
      verifyNever(stats.fetchAllDistinctGrindSizes());
      verify(beans.fetchAllDistinctGrindSizes()).called(1);

      await tester.enterText(input, 'fInE');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('History Fine'), findsOneWidget);
      expect(find.text('Bean Fine'), findsOneWidget);
      expect(find.text('18 clicks'), findsNothing);
      verify(stats.fetchAllDistinctGrindSizes()).called(1);
      verify(beans.fetchAllDistinctGrindSizes()).called(1);

      await tester.enterText(input, 'history');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('History Fine'), findsOneWidget);
      expect(find.text('Bean Fine'), findsNothing);
      verifyNever(stats.fetchAllDistinctGrindSizes());
      verifyNever(beans.fetchAllDistinctGrindSizes());

      await tester.enterText(input, '27 custom clicks');
      // Dismiss the suggestions before scrolling to the form's save action.
      tester
          .widget<EditableText>(
            find.descendant(of: input, matching: find.byType(EditableText)),
          )
          .focusNode
          .unfocus();
      await tester.pumpAndSettle();
      final save = find.widgetWithText(AppElevatedButton, loc.save);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(savedGrind, '27 custom clicks');
      expect(tester.takeException(), isNull);
    },
  );
}
