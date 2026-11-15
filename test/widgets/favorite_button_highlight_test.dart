// Widget tests for FavoriteButton's `highlight` treatment — the attention
// nudge shown when the recipe detail screen is opened from the journey
// card's "favorite a recipe" milestone.
//
// Expected behaviour:
// - `highlight: true` + recipe not already a favorite (decided only after
//   the async favorite-status lookup resolves) → a soft circular halo
//   DecoratedBox behind the heart, then (after a ~400 ms delay, so the
//   page transition finishes) a finite 3× scale pulse that stops; the halo
//   itself stays until the user taps the heart — any tap, either direction,
//   removes it for good.
// - Already-favorite or `highlight: false` → no halo at all.
// - `MediaQuery.disableAnimationsOf` → static halo, no pulse.
//
// The halo is asserted through the circle-shaped BoxDecoration that is
// ALWAYS in the tree (its color is null when inactive) — asserting the
// widget count also pins the stable-tree-shape requirement: the highlight
// must never change the widget type at that tree position.

import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/onboarding_service.dart';
import 'package:coffee_timer/widgets/favorite_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'favorite_button_highlight_test.mocks.dart';

@GenerateNiceMocks([MockSpec<RecipeProvider>()])

RecipeModel _recipe({bool isFavorite = false}) {
  return RecipeModel(
    id: 'recipe-1',
    name: 'Test Recipe',
    brewingMethodId: 'v60',
    coffeeAmount: 15,
    waterAmount: 250,
    grindSize: 'Medium',
    brewTime: const Duration(minutes: 3),
    shortDescription: 'Test',
    steps: const [],
    isFavorite: isFavorite,
  );
}

/// The color of the halo BoxDecoration. The circle-shaped DecoratedBox must
/// always exist (stable tree shape); its color is null when no halo shows.
Color? _haloColor(WidgetTester tester) {
  final boxes = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(FavoriteButton),
          matching: find.byType(DecoratedBox),
        ),
      )
      .where((d) =>
          d.decoration is BoxDecoration &&
          (d.decoration as BoxDecoration).shape == BoxShape.circle)
      .toList();
  expect(boxes, hasLength(1),
      reason: 'the halo DecoratedBox is always in the tree');
  return (boxes.single.decoration as BoxDecoration).color;
}

/// Scale value of the outermost ScaleTransition — the pulse animation
/// (1.0 while the pulse is not running).
double _pulseScaleValue(WidgetTester tester) {
  final transitions = tester.widgetList<ScaleTransition>(
    find.descendant(
      of: find.byType(FavoriteButton),
      matching: find.byType(ScaleTransition),
    ),
  ).toList();
  expect(transitions.length, greaterThanOrEqualTo(2),
      reason: 'pulse and tap-pop ScaleTransitions are always in the tree');
  return transitions.first.scale.value;
}

Future<OnboardingService> _onboarding() async {
  SharedPreferences.setMockInitialValues({});
  return OnboardingService(await SharedPreferences.getInstance());
}

Widget _host({
  required RecipeProvider recipeProvider,
  required OnboardingService onboarding,
  required Widget child,
  bool reducedMotion = false,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
      ChangeNotifierProvider<OnboardingService>.value(value: onboarding),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reducedMotion,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  // Typed as the generated mock (not RecipeProvider): the mock's overrides
  // widen parameters to nullable, which is what lets mockito's `any`
  // matcher pass static analysis.
  late MockRecipeProvider recipeProvider;
  late OnboardingService onboarding;
  bool favorite = false;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
    recipeProvider = MockRecipeProvider();
    onboarding = await _onboarding();
    favorite = false;
    when(recipeProvider.getRecipeById(any)).thenAnswer((_) async {
      return _recipe(isFavorite: favorite);
    });
  });

  testWidgets('highlight: halo appears, pulse runs and is finite', (
    tester,
  ) async {
    await tester.pumpWidget(_host(
      recipeProvider: recipeProvider,
      onboarding: onboarding,
      child: const FavoriteButton(recipeId: 'recipe-1', highlight: true),
    ));
    await tester.pump(); // favorite-status lookup resolves
    await tester.pump(); // halo state renders

    expect(_haloColor(tester), isNotNull);

    // Still held at 1.0 during the 400 ms page-transition delay...
    await tester.pump(const Duration(milliseconds: 300));
    expect(_pulseScaleValue(tester), 1.0);
    // ...then the pulse moves the scale.
    await tester.pump(const Duration(milliseconds: 150));
    expect(_pulseScaleValue(tester), greaterThan(1.0));

    // The pulse is finite: pumpAndSettle completes, the halo remains, and
    // the scale is back at rest.
    await tester.pumpAndSettle();
    expect(_haloColor(tester), isNotNull);
    expect(_pulseScaleValue(tester), 1.0);
  });

  testWidgets('no halo when the recipe is already a favorite', (tester) async {
    favorite = true;
    when(recipeProvider.getRecipeById(any)).thenAnswer(
      (_) async => _recipe(isFavorite: true),
    );
    await tester.pumpWidget(_host(
      recipeProvider: recipeProvider,
      onboarding: onboarding,
      child: const FavoriteButton(recipeId: 'recipe-1', highlight: true),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(_haloColor(tester), isNull);
    await tester.pumpAndSettle();
    expect(_haloColor(tester), isNull);
  });

  testWidgets('no halo without highlight', (tester) async {
    await tester.pumpWidget(_host(
      recipeProvider: recipeProvider,
      onboarding: onboarding,
      child: const FavoriteButton(recipeId: 'recipe-1'),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(_haloColor(tester), isNull);
    await tester.pumpAndSettle();
    expect(_haloColor(tester), isNull);
  });

  testWidgets('tapping the heart removes the halo for good', (tester) async {
    when(recipeProvider.toggleFavorite(any)).thenAnswer((_) async {
      favorite = !favorite;
    });
    await tester.pumpWidget(_host(
      recipeProvider: recipeProvider,
      onboarding: onboarding,
      child: const FavoriteButton(recipeId: 'recipe-1', highlight: true),
    ));
    await tester.pump();
    await tester.pump();
    expect(_haloColor(tester), isNotNull);

    // Tap to favorite (pulse may be mid-flight — the halo is gone at once).
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(_haloColor(tester), isNull);
    // Existing behaviour intact: the milestone got completed.
    expect(onboarding.milestoneFavorite, isTrue);
    verify(recipeProvider.toggleFavorite('recipe-1')).called(1);

    // Tap again to unfavorite — the halo must not come back either way.
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();
    expect(_haloColor(tester), isNull);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('reduced motion: static halo, no pulse', (tester) async {
    await tester.pumpWidget(_host(
      recipeProvider: recipeProvider,
      onboarding: onboarding,
      child: const FavoriteButton(recipeId: 'recipe-1', highlight: true),
      reducedMotion: true,
    ));
    await tester.pump();
    await tester.pump();

    expect(_haloColor(tester), isNotNull);
    // Well past the pulse start time, the scale must not have moved.
    await tester.pump(const Duration(milliseconds: 700));
    expect(_pulseScaleValue(tester), 1.0);
    await tester.pumpAndSettle();
    expect(_haloColor(tester), isNotNull);
    expect(_pulseScaleValue(tester), 1.0);
  });
}
