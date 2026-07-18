import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/user_recipe_provider.dart';
import 'package:coffee_timer/screens/recipe_list_screen.dart';
import 'package:coffee_timer/screens/user_recipe_management_screen.dart';
import 'package:coffee_timer/services/recipe_navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'recipe_screen_async_context_test.mocks.dart';

@GenerateNiceMocks([MockSpec<RecipeProvider>(), MockSpec<UserRecipeProvider>()])
void main() {
  late MockRecipeProvider recipeProvider;
  late MockUserRecipeProvider userRecipeProvider;
  late RecipeModel recipe;

  setUp(() {
    recipeProvider = MockRecipeProvider();
    userRecipeProvider = MockUserRecipeProvider();
    recipe = RecipeModel(
      id: 'usr-user-1',
      name: 'Test V60',
      brewingMethodId: 'v60',
      coffeeAmount: 15,
      waterAmount: 250,
      grindSize: 'Medium',
      brewTime: const Duration(minutes: 3),
      shortDescription: 'Test recipe',
      steps: const [],
      isPublic: true,
    );

    when(recipeProvider.recipes).thenReturn([recipe]);
    when(recipeProvider.ensureDataReady()).thenAnswer((_) async {});
    when(recipeProvider.fetchAllRecipes()).thenAnswer((_) async {});
    when(
      recipeProvider.getBrewingMethodName('v60'),
    ).thenAnswer((_) async => 'V60');
    when(
      recipeProvider.getRecipeById(recipe.id),
    ).thenAnswer((_) async => recipe);
    when(
      userRecipeProvider.deleteUserRecipe(recipe.id),
    ).thenAnswer((_) async {});
    when(
      userRecipeProvider.unpublishRecipe(recipe.id),
    ).thenAnswer((_) async {});
  });

  Widget buildSubject(Widget screen) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
        ChangeNotifierProvider<UserRecipeProvider>.value(
          value: userRecipeProvider,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: screen,
      ),
    );
  }

  testWidgets('recipe deletion completes and shows success while mounted', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(const RecipeListScreen(brewingMethodId: 'v60')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_note));
    await tester.pump();
    clearInteractions(recipeProvider);
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(userRecipeProvider.deleteUserRecipe(recipe.id)).called(1);
    verify(recipeProvider.fetchAllRecipes()).called(1);
    expect(find.text('Recipe deleted successfully'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recipe deletion finishes safely after screen disposal', (
    tester,
  ) async {
    final deletion = Completer<void>();
    when(
      userRecipeProvider.deleteUserRecipe(recipe.id),
    ).thenAnswer((_) => deletion.future);

    await tester.pumpWidget(
      buildSubject(const RecipeListScreen(brewingMethodId: 'v60')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_note));
    await tester.pump();
    clearInteractions(recipeProvider);
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();
    verify(userRecipeProvider.deleteUserRecipe(recipe.id)).called(1);

    await tester.pumpWidget(const SizedBox.shrink());
    deletion.complete();
    await tester.pump();

    verify(recipeProvider.fetchAllRecipes()).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recipe navigation finishes safely after screen disposal', (
    tester,
  ) async {
    final recipeLookup = Completer<RecipeModel?>();
    var lookupCount = 0;
    when(recipeProvider.getRecipeById(recipe.id)).thenAnswer((_) {
      lookupCount += 1;
      if (lookupCount == 1) return Future.value(recipe);
      return recipeLookup.future;
    });

    await tester.pumpWidget(
      buildSubject(const RecipeListScreen(brewingMethodId: 'v60')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(recipe.name));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    recipeLookup.complete(recipe);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('management initialization continues after screen disposal', (
    tester,
  ) async {
    final initialization = Completer<void>();
    when(recipeProvider.recipes).thenReturn(const []);
    when(
      recipeProvider.ensureDataReady(),
    ).thenAnswer((_) => initialization.future);

    await tester.pumpWidget(buildSubject(const UserRecipeManagementScreen()));
    await tester.pump();
    verify(recipeProvider.ensureDataReady()).called(1);

    await tester.pumpWidget(const SizedBox.shrink());
    initialization.complete();
    await tester.pump();

    verify(recipeProvider.fetchAllRecipes()).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unpublish finishes safely after management screen disposal', (
    tester,
  ) async {
    final unpublish = Completer<void>();
    when(
      userRecipeProvider.unpublishRecipe(recipe.id),
    ).thenAnswer((_) => unpublish.future);

    await tester.pumpWidget(buildSubject(const UserRecipeManagementScreen()));
    await tester.pumpAndSettle();
    clearInteractions(recipeProvider);

    await tester.tap(find.byIcon(Icons.edit_note));
    await tester.pumpAndSettle();
    clearInteractions(recipeProvider);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(UserRecipeManagementScreen)),
    )!;
    await tester.tap(find.byTooltip(l10n.userRecipeUnpublishTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make Private'));
    await tester.pump();
    verify(userRecipeProvider.unpublishRecipe(recipe.id)).called(1);

    await tester.pumpWidget(const SizedBox.shrink());
    unpublish.complete();
    await tester.pump();

    verify(recipeProvider.fetchAllRecipes()).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('imported recipe confirmation continues into copy operation', (
    tester,
  ) async {
    final importedRecipe = recipe.copyWith(isImported: true);
    when(
      userRecipeProvider.copyUserRecipe(importedRecipe),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(
      buildSubject(const SizedBox(key: Key('navigation-host'))),
    );
    final context = tester.element(find.byKey(const Key('navigation-host')));

    final navigation = RecipeNavigationService.navigateToEditRecipe(
      context: context,
      recipe: importedRecipe,
      effectiveRecipeId: importedRecipe.id,
      onRecipeUpdated: () {},
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit Imported Recipe'), findsOneWidget);

    await tester.tap(find.text('Create Copy & Edit'));
    await tester.pumpAndSettle();
    final result = await navigation;

    verify(userRecipeProvider.copyUserRecipe(importedRecipe)).called(1);
    expect(result.success, isFalse);
    expect(tester.takeException(), isNull);
  });
}
