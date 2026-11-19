import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';
import 'package:coffee_timer/widgets/fields/numeric_text_field.dart';
import 'package:coffee_timer/widgets/recipe_creation/recipe_basic_info_card.dart';
import 'package:coffee_timer/widgets/recipe_creation/recipe_brewing_method_card.dart';
import 'package:coffee_timer/widgets/recipe_creation/recipe_parameters_card.dart';
import 'package:coffee_timer/widgets/recipe_creation/recipe_steps_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;
  late GlobalKey<FormState> formKey;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
    formKey = GlobalKey<FormState>();
  });

  Widget host(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Form(key: formKey, child: child),
        ),
      ),
    );
  }

  Finder labeledField(String label) => find.byWidgetPredicate(
    (widget) => widget is LabeledField && widget.label == label,
  );

  Finder input(String label) => find.descendant(
    of: labeledField(label),
    matching: find.byType(EditableText),
  );

  testWidgets('parameter fields preserve compact labels and nullable input', (
    tester,
  ) async {
    final coffeeChanges = <double>[];
    final temperatureChanges = <double?>[];
    final minuteChanges = <int>[];
    await tester.pumpWidget(
      host(
        RecipeParametersCard(
          coffeeAmount: 30.0,
          waterAmount: 500,
          waterTemp: 94,
          grindSize: 'Medium',
          brewMinutes: 2,
          brewSeconds: 30,
          onCoffeeAmountChanged: coffeeChanges.add,
          onWaterAmountChanged: (_) {},
          onWaterTempChanged: temperatureChanges.add,
          onGrindSizeChanged: (_) {},
          onBrewMinutesChanged: minuteChanges.add,
          onBrewSecondsChanged: (_) {},
        ),
      ),
    );

    final numbers = find.byType(NumericTextField);
    expect(numbers, findsNWidgets(5));
    for (final field in tester.widgetList<NumericTextField>(numbers)) {
      expect(field.labelInsideField, isTrue);
    }
    // Each numeric field also builds its own LabeledField.
    expect(find.byType(LabeledField), findsNWidgets(6));
    final grindLabel = l10n.recipeCreationScreenGrindSizeLabel;
    expect(
      tester.widget<LabeledField>(labeledField(grindLabel)).labelInsideField,
      isTrue,
    );

    final coffee = input(l10n.recipeCreationScreenCoffeeAmountLabel);
    expect(tester.widget<EditableText>(coffee).controller.text, '30');
    await tester.enterText(coffee, '18.5');
    expect(coffeeChanges, [18.5]);

    await tester.enterText(coffee, '');
    expect(coffeeChanges, [18.5, 0]);
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(
      find.text(l10n.recipeCreationScreenRequiredValidator),
      findsOneWidget,
    );

    await tester.enterText(coffee, '18.5');
    await tester.pump();
    await tester.enterText(input(l10n.recipeCreationScreenMinutesLabel), '3');
    expect(minuteChanges.last, 3);

    await tester.enterText(input(l10n.recipeCreationScreenWaterTempLabel), '');
    expect(temperatureChanges.last, isNull);

    await tester.enterText(input(grindLabel), '');
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(
      find.descendant(
        of: labeledField(grindLabel),
        matching: find.text(l10n.recipeCreationScreenRequiredValidator),
      ),
      findsOneWidget,
    );
  });

  testWidgets('basic info fields use the supplied controllers and labels', (
    tester,
  ) async {
    final name = TextEditingController(text: 'Morning V60');
    final description = TextEditingController(text: 'Daily brew');
    addTearDown(name.dispose);
    addTearDown(description.dispose);
    await tester.pumpWidget(
      host(
        RecipeBasicInfoCard(
          recipeNameController: name,
          shortDescriptionController: description,
          onNameChanged: (_) {},
          onShortDescriptionChanged: (_) {},
        ),
      ),
    );

    final fields = find.byType(LabeledField);
    expect(fields, findsNWidgets(2));
    for (final field in tester.widgetList<LabeledField>(fields)) {
      expect(field.labelInsideField, isFalse);
    }

    final nameInput = input(l10n.recipeCreationScreenRecipeNameLabel);
    final descriptionInput = input(
      l10n.recipeCreationScreenShortDescriptionLabel,
    );
    await tester.enterText(nameInput, 'Evening V60');
    await tester.enterText(descriptionInput, 'Bright\nand clean');
    expect(name.text, 'Evening V60');
    expect(description.text, 'Bright\nand clean');
    expect(tester.widget<EditableText>(descriptionInput).maxLines, 3);

    await tester.enterText(nameInput, '');
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(
      find.text(l10n.recipeCreationScreenRecipeNameValidator),
      findsOneWidget,
    );
  });

  testWidgets('step fields validate the description and report seconds', (
    tester,
  ) async {
    final times = <Duration>[];
    await tester.pumpWidget(
      host(
        StepCard(
          step: BrewStepModel(
            id: 'brew',
            order: 2,
            description: 'Pour water',
            time: const Duration(seconds: 30),
          ),
          isPreparationStep: false,
          l10n: l10n,
          displayIndex: '1',
          onDescriptionChanged: (_) {},
          onTimeChanged: times.add,
        ),
      ),
    );

    final descriptionLabel = l10n.recipeCreationScreenStepDescriptionLabel;
    final description = tester.widget<LabeledField>(
      labeledField(descriptionLabel),
    );
    expect(description.labelInsideField, isFalse);
    expect(description.isMultiline, isTrue);
    expect(tester.widget<EditableText>(input(descriptionLabel)).maxLines, 2);

    final seconds = tester.widget<NumericTextField>(
      find.byType(NumericTextField),
    );
    expect(seconds.labelInsideField, isTrue);
    expect(seconds.allowDecimal, isFalse);
    await tester.enterText(input(l10n.recipeCreationScreenSecondsLabel), '45');
    expect(times.last, const Duration(seconds: 45));

    await tester.enterText(input(descriptionLabel), '');
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(
      find.text(l10n.recipeCreationScreenStepDescriptionValidator),
      findsOneWidget,
    );
  });

  testWidgets('brewing method field updates and opens the selection overlay', (
    tester,
  ) async {
    final methods = [
      BrewingMethodModel(brewingMethodId: 'v60', brewingMethod: 'Hario V60'),
      BrewingMethodModel(
        brewingMethodId: 'aeropress',
        brewingMethod: 'AeroPress',
      ),
    ];
    String? selected;

    Widget card(String? selectedId, List<BrewingMethodModel> brewingMethods) =>
        host(
          RecipeBrewingMethodCard(
            brewingMethods: brewingMethods,
            selectedBrewingMethodId: selectedId,
            onBrewingMethodChanged: (id) => selected = id,
          ),
        );

    await tester.pumpWidget(card('v60', methods));
    final label = l10n.recipeCreationScreenBrewingMethodLabel;
    final field = tester.widget<LabeledField>(labeledField(label));
    expect(field.labelInsideField, isFalse);
    expect(field.readOnly, isTrue);
    expect(find.text('Hario V60'), findsOneWidget);

    await tester.pumpWidget(card('aeropress', methods));
    await tester.pump();
    expect(
      tester.widget<LabeledField>(labeledField(label)).controller,
      same(field.controller),
    );
    expect(find.text('AeroPress'), findsOneWidget);

    await tester.tap(input(label));
    await tester.pumpAndSettle();
    final v60 = find.widgetWithText(ListTile, 'Hario V60');
    expect(v60, findsOneWidget);
    await tester.tap(v60);
    await tester.pumpAndSettle();
    expect(selected, 'v60');

    await tester.pumpWidget(card('aeropress', [methods.first]));
    await tester.pump();
    expect(find.text('Hario V60'), findsOneWidget);

    await tester.pumpWidget(card(null, methods));
    await tester.pump();
    expect(tester.widget<EditableText>(input(label)).controller.text, isEmpty);
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(
      find.text(l10n.recipeCreationScreenBrewingMethodValidator),
      findsOneWidget,
    );
  });
}
