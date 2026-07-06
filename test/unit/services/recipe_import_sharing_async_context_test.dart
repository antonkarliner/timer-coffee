import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/services/recipe_import_sharing_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'recipe_import_sharing_async_context_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<DatabaseProvider>(),
  MockSpec<RecipeProvider>(),
  MockSpec<AppDatabase>(),
])
void main() {
  late MockDatabaseProvider databaseProvider;
  late MockRecipeProvider recipeProvider;
  late MockAppDatabase database;
  late RecipeModel recipe;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  setUp(() {
    databaseProvider = MockDatabaseProvider();
    recipeProvider = MockRecipeProvider();
    database = MockAppDatabase();
    recipe = RecipeModel(
      id: 'usr-test-1',
      name: 'Test Recipe',
      brewingMethodId: 'v60',
      coffeeAmount: 15,
      waterAmount: 250,
      grindSize: 'Medium',
      brewTime: const Duration(minutes: 3),
      shortDescription: 'Test recipe',
      steps: const [],
    );
  });

  Widget buildHost() {
    return MultiProvider(
      providers: [
        Provider<DatabaseProvider>.value(value: databaseProvider),
        ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
        Provider<AppDatabase>.value(value: database),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(body: SizedBox(key: Key('share-host'))),
      ),
    );
  }

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(buildHost());
    return tester.element(find.byKey(const Key('share-host')));
  }

  testWidgets('sharing rejects an already unmounted context', (tester) async {
    final context = await pumpHost(tester);
    await tester.pumpWidget(const SizedBox.shrink());

    final result = await RecipeImportSharingService.shareRecipe(
      context: context,
      recipe: recipe,
      shareRecipeId: recipe.id,
    );

    expect(result.success, isFalse);
    expect(result.errorMessage, 'Context not mounted');
    expect(tester.takeException(), isNull);
  });

  testWidgets('unauthenticated sharing can be cancelled normally', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final context = await pumpHost(tester);

    final sharing = RecipeImportSharingService.shareRecipe(
      context: context,
      recipe: recipe,
      shareRecipeId: recipe.id,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign In Required'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    final result = await sharing;

    expect(result.success, isFalse);
    expect(result.errorMessage, 'Authentication required');
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-in sheet disposal ends sharing safely', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final context = await pumpHost(tester);

    final sharing = RecipeImportSharingService.shareRecipe(
      context: context,
      recipe: recipe,
      shareRecipeId: recipe.id,
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign In Required'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final result = await sharing;

    expect(result.success, isFalse);
    expect(result.errorMessage, 'Authentication required');
    expect(tester.takeException(), isNull);
  });
}
