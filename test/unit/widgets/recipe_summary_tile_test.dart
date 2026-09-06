import 'package:coffee_timer/controllers/recipe_detail_controller.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/widgets/recipe_detail/recipe_summary_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeModel _recipe({required List<BrewStepModel> steps}) => RecipeModel(
  id: 'test-recipe',
  name: 'V60',
  brewingMethodId: 'pour-over',
  coffeeAmount: 15,
  waterAmount: 250,
  grindSize: 'Medium',
  brewTime: const Duration(minutes: 2, seconds: 30),
  shortDescription: '',
  steps: steps,
);

BrewStepModel _step(int order, String description, {int seconds = 0}) =>
    BrewStepModel(
      id: 'step-$order',
      order: order,
      description: description,
      time: Duration(seconds: seconds),
    );

Future<void> _pumpTile(
  WidgetTester tester, {
  required RecipeModel recipe,
  required RecipeDetailController controller,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = const Size(400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      // Match the real screen: the tile lives inside a scroll view, so its
      // content height is unbounded and getSize reports the content size.
      home: Scaffold(
        body: SingleChildScrollView(
          child: RecipeSummaryTile(recipe: recipe, controller: controller),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late RecipeDetailController controller;

  setUp(() {
    controller = RecipeDetailController()
      ..setInitialAmounts(coffeeAmount: 15, waterAmount: 250);
    addTearDown(controller.dispose);
  });

  testWidgets('collapsed header shows label, clock, duration; expands on tap', (
    tester,
  ) async {
    await _pumpTile(
      tester,
      controller: controller,
      recipe: _recipe(
        steps: [
          _step(0, 'Rinse the filter.'),
          _step(1, 'Bloom with (2x<coffee_amount>)g', seconds: 45),
          _step(2, 'Pour to (12x<coffee_amount>)g', seconds: 60),
        ],
      ),
    );

    // Collapsed: header carries the summary label, the compact clock, and the
    // brew time; the summary body is not built yet.
    expect(find.text('Recipe summary'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.text('02:30'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(find.text('Preparation'), findsNothing);
    expect(find.text('Rinse the filter.'), findsNothing);

    final collapsedHeight = tester
        .getSize(find.byType(RecipeSummaryTile))
        .height;

    await tester.tap(find.text('Recipe summary'));
    await tester.pumpAndSettle();

    // Expanded: duration stays visible, prep paragraph and timed rows show.
    expect(find.text('02:30'), findsOneWidget);
    expect(find.text('Preparation'), findsOneWidget);
    expect(find.text('Rinse the filter.'), findsOneWidget);
    expect(find.textContaining('Bloom with'), findsOneWidget);
    expect(find.textContaining('Pour to'), findsOneWidget);
    expect(
      tester.getSize(find.byType(RecipeSummaryTile)).height,
      greaterThan(collapsedHeight + 100),
    );
  });

  testWidgets('whole header is tappable, including the duration area', (
    tester,
  ) async {
    await _pumpTile(
      tester,
      controller: controller,
      recipe: _recipe(
        steps: [_step(0, 'Rinse the filter.'), _step(1, 'Bloom', seconds: 45)],
      ),
    );

    await tester.tap(find.text('02:30'));
    await tester.pumpAndSettle();
    expect(find.text('Rinse the filter.'), findsOneWidget);

    final expandedHeight = tester
        .getSize(find.byType(RecipeSummaryTile))
        .height;

    await tester.tap(find.text('Recipe summary'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(RecipeSummaryTile)).height,
      lessThan(expandedHeight),
    );
  });

  testWidgets(
    'prep is untimed, later zero-time steps are skipped, timestamps are cumulative start times',
    (tester) async {
      await _pumpTile(
        tester,
        controller: controller,
        recipe: _recipe(
          steps: [
            _step(0, 'Rinse the filter.'),
            _step(1, 'Placeholder step'),
            _step(2, 'Bloom with (2x<coffee_amount>)g', seconds: 45),
            _step(3, 'Pour to (12x<coffee_amount>)g', seconds: 60),
          ],
        ),
      );

      await tester.tap(find.text('Recipe summary'));
      await tester.pumpAndSettle();

      expect(find.text('Preparation'), findsOneWidget);
      expect(find.text('Rinse the filter.'), findsOneWidget);
      expect(find.text('Placeholder step'), findsNothing);
      // Timestamp is the step's start time; it only advances across timed
      // steps, so the first timed step starts at 0:00.
      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('0:45'), findsOneWidget);
      expect(find.text('1:45'), findsNothing);
    },
  );

  testWidgets('renders with the controller amounts and reacts to changes', (
    tester,
  ) async {
    await _pumpTile(
      tester,
      controller: controller,
      recipe: _recipe(
        steps: [
          _step(0, 'Rinse the filter.'),
          _step(1, 'Bloom with (2x<coffee_amount>)g', seconds: 45),
          _step(2, 'Pour to (12x<coffee_amount>)g', seconds: 60),
        ],
      ),
    );

    await tester.tap(find.text('Recipe summary'));
    await tester.pumpAndSettle();

    expect(find.text('Bloom with 30g'), findsOneWidget);
    expect(find.text('Pour to 180g'), findsOneWidget);

    controller.setInitialAmounts(coffeeAmount: 18, waterAmount: 300);
    await tester.pumpAndSettle();

    expect(find.text('Bloom with 36g'), findsOneWidget);
    expect(find.text('Pour to 216g'), findsOneWidget);
    expect(find.text('Bloom with 30g'), findsNothing);
  });

  testWidgets(
    'long instructions wrap without overflow on a narrow screen at large text scale',
    (tester) async {
      final longInstruction =
          'Pour slowly in concentric circles, keeping the slurry level and '
              'avoiding the walls of the brewer, until the water reaches the top '
              'of the bed, then wait for the water to drain halfway before '
              'starting the next pour and repeat until all the water is used up '
              'and the bed looks even. ' *
          3;
      await _pumpTile(
        tester,
        controller: controller,
        textScaler: const TextScaler.linear(2),
        recipe: _recipe(
          steps: [
            _step(0, 'Rinse the filter with plenty of hot water.'),
            _step(1, longInstruction, seconds: 45),
          ],
        ),
      );

      await tester.tap(find.text('Recipe summary'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Pour slowly'), findsOneWidget);
      expect(find.text('0:00'), findsOneWidget);
    },
  );
}
