import 'dart:convert';

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/bean_review_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/bean_review_provider.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/screens/coffee_beans_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/widgets/delete_button.dart';
import 'package:coffee_timer/widgets/fields/time_field.dart';
import 'package:coffee_timer/widgets/recipe_detail/app_bar_actions.dart';
import 'package:coffee_timer/widgets/recipe_detail/bean_selection_row.dart';
import 'package:coffee_timer/widgets/roaster_profile/review_form.dart';
import 'package:coffee_timer/widgets/user_recipe_management/recipe_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/brew_flow_async_context_test.mocks.dart';

class _FakeBeanReviewProvider extends BeanReviewProvider {
  @override
  Future<List<BeanReviewModel>> fetchUserReviews() async => const [];
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
    await Supabase.instance.client.auth.recoverSession(_authenticatedSession());
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDownAll(AnalyticsService.resetForTesting);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget localizedApp(Widget child, {Locale locale = const Locale('es')}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: child),
    );
  }

  testWidgets('review form uses resolved Yes and No labels', (tester) async {
    final database = MockAppDatabase();
    final brewingMethodsDao = MockBrewingMethodsDao();
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    final beanReviewProvider = _FakeBeanReviewProvider();

    when(database.brewingMethodsDao).thenReturn(brewingMethodsDao);
    when(
      brewingMethodsDao.getAllBrewingMethods(),
    ).thenAnswer((_) async => const []);
    when(
      coffeeBeansProvider.fetchAllCoffeeBeans(),
    ).thenAnswer((_) async => const []);

    late BuildContext hostContext;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: coffeeBeansProvider,
          ),
          ChangeNotifierProvider<BeanReviewProvider>.value(
            value: beanReviewProvider,
          ),
        ],
        child: localizedApp(
          Builder(
            builder: (context) {
              hostContext = context;
              return ElevatedButton(
                onPressed: () {
                  showReviewForm(context, roasterName: 'Test Roaster');
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    final l10n = AppLocalizations.of(hostContext)!;
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.yes), findsOneWidget);
    expect(find.text(l10n.no), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.dialogCancel));
    await tester.pumpAndSettle();
  });

  testWidgets('coffee beans error state uses resolved Retry label', (
    tester,
  ) async {
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    when(
      coffeeBeansProvider.fetchAllDistinctRoasters(),
    ).thenAnswer((_) async => const []);
    when(
      coffeeBeansProvider.fetchAllDistinctOrigins(),
    ).thenAnswer((_) async => const []);
    when(
      coffeeBeansProvider.fetchFilteredCoffeeBeans(
        roasters: anyNamed('roasters'),
        origins: anyNamed('origins'),
        isFavorite: anyNamed('isFavorite'),
      ),
    ).thenThrow(StateError('load failed'));

    await tester.pumpWidget(
      ChangeNotifierProvider<CoffeeBeansProvider>.value(
        value: coffeeBeansProvider,
        child: localizedApp(const CoffeeBeansScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoffeeBeansScreen)),
    )!;

    expect(find.text(l10n.retry), findsOneWidget);
  });

  testWidgets('shared clear, delete, and edit tooltips are localized', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        Column(
          children: [
            BeansChip(labelText: 'Test beans', onTap: () {}, onClear: () {}),
            DeleteButton(onPressed: () {}),
            RecipeDetailAppBarActions(
              isUserRecipe: true,
              isSharing: false,
              idForActions: 'test-recipe',
              isPublic: false,
              favoriteButton: const SizedBox(),
            ),
          ],
        ),
      ),
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(RecipeDetailAppBarActions)),
    )!;

    expect(find.byTooltip(l10n.fieldClearButtonTooltip), findsOneWidget);
    expect(find.byTooltip(l10n.delete), findsOneWidget);
    expect(find.byTooltip(l10n.edit), findsOneWidget);
  });

  testWidgets('user recipe actions use resolved tooltips', (tester) async {
    final recipeProvider = MockRecipeProvider();
    final recipe = RecipeModel(
      id: 'usr-test-recipe',
      name: 'Test recipe',
      brewingMethodId: 'v60',
      coffeeAmount: 15,
      waterAmount: 250,
      grindSize: 'Medium',
      brewTime: const Duration(minutes: 3),
      shortDescription: 'Test recipe',
      steps: const [],
      isPublic: true,
    );
    final editMode = ValueNotifier(true);
    when(
      recipeProvider.getRecipeById(recipe.id),
    ).thenAnswer((_) async => recipe);

    await tester.pumpWidget(
      ChangeNotifierProvider<RecipeProvider>.value(
        value: recipeProvider,
        child: localizedApp(
          RecipeListItem(
            recipe: recipe,
            onTap: () {},
            onDelete: () {},
            onUnpublish: () {},
            isEditable: true,
            isInEditModeListenable: editMode,
          ),
        ),
      ),
    );
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(RecipeListItem)),
    )!;

    expect(find.byTooltip(l10n.userRecipeUnpublishTooltip), findsOneWidget);
    expect(find.byTooltip(l10n.userRecipeDeleteTooltip), findsOneWidget);
    editMode.dispose();
  });

  testWidgets('time picker uses locale-specific day-period labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        const MediaQuery(
          data: MediaQueryData(alwaysUse24HourFormat: false),
          child: TimeField(
            label: 'time',
            initialValue: TimeOfDay(hour: 9, minute: 5),
          ),
        ),
        locale: const Locale('zh'),
      ),
    );

    final materialL10n = MaterialLocalizations.of(
      tester.element(find.byType(TimeField)),
    );
    const englishL10n = DefaultMaterialLocalizations();

    expect(
      materialL10n.anteMeridiemAbbreviation,
      isNot(englishL10n.anteMeridiemAbbreviation),
    );
    expect(
      materialL10n.postMeridiemAbbreviation,
      isNot(englishL10n.postMeridiemAbbreviation),
    );

    await tester.tap(find.byType(TimeField));
    await tester.pumpAndSettle();

    expect(find.text(materialL10n.anteMeridiemAbbreviation), findsOneWidget);
    expect(find.text(materialL10n.postMeridiemAbbreviation), findsOneWidget);
  });

  testWidgets('unknown product fallback resolves from the active locale', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      localizedApp(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return Text(l10n.unknownProduct);
          },
        ),
      ),
    );

    expect(find.text(l10n.unknownProduct), findsOneWidget);
  });
}

String _authenticatedSession() {
  final expiresAt = DateTime.now().add(const Duration(hours: 1));
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
            'sub': 'test-user',
            'role': 'authenticated',
          }),
        ),
      )
      .replaceAll('=', '');
  final now = DateTime.now().toUtc().toIso8601String();

  return jsonEncode({
    'access_token': 'test.$payload.signature',
    'expires_in': expiresAt.difference(DateTime.now()).inSeconds,
    'refresh_token': 'test-refresh-token',
    'token_type': 'bearer',
    'user': {
      'id': 'test-user',
      'app_metadata': {
        'provider': 'email',
        'providers': ['email'],
      },
      'user_metadata': <String, dynamic>{},
      'aud': 'authenticated',
      'email': 'test@example.com',
      'phone': '',
      'created_at': now,
      'updated_at': now,
      'role': 'authenticated',
    },
  });
}
