import 'package:coffee_timer/controllers/recipe_detail_controller.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/roaster_profile_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/widgets/recipe_detail/recipe_content_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'recipe_detail_grind_autocomplete_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<CoffeeBeansProvider>(),
  MockSpec<UserStatProvider>(),
])
void main() {
  late MockCoffeeBeansProvider coffeeBeansProvider;
  late MockUserStatProvider userStatProvider;
  late RecipeDetailController controller;

  RecipeModel buildRecipe() {
    return RecipeModel(
      id: 'test-recipe',
      name: 'Test Recipe',
      brewingMethodId: 'v60',
      coffeeAmount: 15,
      waterAmount: 250,
      grindSize: 'Medium',
      brewTime: const Duration(minutes: 3),
      shortDescription: '',
      steps: const [],
    );
  }

  setUp(() {
    coffeeBeansProvider = MockCoffeeBeansProvider();
    when(
      coffeeBeansProvider.fetchAllDistinctGrindSizes(),
    ).thenAnswer((_) async => ['Medium', 'Medium-Fine', 'Coarse']);
    userStatProvider = MockUserStatProvider();
    when(
      userStatProvider.fetchAllDistinctGrindSizes(),
    ).thenAnswer((_) async => <String>[]);
    controller = RecipeDetailController();
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildSubject() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CoffeeBeansProvider>.value(
          value: coffeeBeansProvider,
        ),
        ChangeNotifierProvider<RoasterProfileProvider>(
          create: (_) => RoasterProfileProvider(),
        ),
        ChangeNotifierProvider<UserStatProvider>.value(
          value: userStatProvider,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecipeContentBuilder(
              recipe: buildRecipe(),
              controller: controller,
              effectiveRecipeId: 'test-recipe',
              onSelectBeans: () {},
              onClearBeanSelection: () {},
              onCoffeeAmountChanged: () {},
              onWaterAmountChanged: () {},
              onCoffeeFocus: () {},
              onWaterFocus: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'tapping the pencil enters edit mode and surfaces matching suggestions',
    (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      // Flush BeanSelectionRow's 3s fallback timer so it doesn't linger past
      // the end of the test.
      await tester.pump(const Duration(seconds: 4));

      expect(find.byType(TextFormField), findsNothing);
      // Both the grind-size and water-temperature rows use an edit pencil;
      // the grind-size one is the first in the tree.
      expect(find.byIcon(Icons.edit), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Medium-F');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Medium-Fine'), findsOneWidget);
    },
  );

  testWidgets(
    'edit checkmark is vertically aligned with the grind size field',
    (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pump();

      final fieldCenter = tester.getCenter(find.byType(TextFormField));
      final checkmarkCenter = tester.getCenter(find.byIcon(Icons.check));

      expect(checkmarkCenter.dy, closeTo(fieldCenter.dy, 0.5));
    },
  );

  testWidgets(
    'selecting a suggestion updates the controller and clears grindSizeFromBean',
    (tester) async {
      controller.applyBeanGrindSize('Coarse');
      expect(controller.grindSizeFromBean, isTrue);

      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), 'Medium-F');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medium-Fine'));
      await tester.pumpAndSettle();

      expect(controller.grindSizeController.text, 'Medium-Fine');
      expect(controller.grindSizeFromBean, isFalse);
    },
  );

  testWidgets('grind suggestion row still renders when shown', (
    tester,
  ) async {
    controller.grindSizeController.text = 'Medium';
    controller.setGrindSuggestion('Medium-Fine', null);
    expect(controller.shouldShowGrindSuggestion, isTrue);

    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('Use'), findsOneWidget);
  });
}
