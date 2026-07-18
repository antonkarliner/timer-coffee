import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/widgets/fields/chip_input.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';
import 'package:coffee_timer/widgets/fields/numeric_text_field.dart';
import 'package:coffee_timer/widgets/recipe_creation/recipe_brewing_method_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('chip suggestions render below the focused field', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Padding(
          padding: EdgeInsets.all(16),
          child: ChipInput(
            label: 'Tasting notes',
            suggestions: ['Chocolate', 'Citrus'],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'choc');
    await tester.pump();

    expect(find.text('Chocolate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick pick tap adds the chip and removes it from the row', (
    tester,
  ) async {
    List<String>? changed;
    await tester.pumpWidget(
      host(
        Padding(
          padding: const EdgeInsets.all(16),
          child: ChipInput(
            label: 'Tasting notes',
            quickPicks: const ['Chocolate', 'Citrus'],
            onChanged: (values) => changed = values,
          ),
        ),
      ),
    );

    expect(find.widgetWithText(ActionChip, 'Chocolate'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Citrus'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'Chocolate'));
    await tester.pumpAndSettle();

    expect(changed, ['Chocolate']);
    expect(find.widgetWithText(ActionChip, 'Chocolate'), findsNothing);
    expect(find.widgetWithText(ActionChip, 'Citrus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'quick picks row is hidden once every pick is already added',
    (tester) async {
      await tester.pumpWidget(
        host(
          const Padding(
            padding: EdgeInsets.all(16),
            child: ChipInput(
              label: 'Tasting notes',
              initialValues: ['Chocolate'],
              quickPicks: ['Chocolate'],
            ),
          ),
        ),
      );

      expect(find.byType(ActionChip), findsNothing);
    },
  );

  testWidgets('+ button is disabled when empty and commits typed text', (
    tester,
  ) async {
    List<String>? changed;
    await tester.pumpWidget(
      host(
        Padding(
          padding: const EdgeInsets.all(16),
          child: ChipInput(
            label: 'Tasting notes',
            onChanged: (values) => changed = values,
          ),
        ),
      ),
    );

    final addButtonFinder = find.widgetWithIcon(IconButton, Icons.add);
    expect(addButtonFinder, findsOneWidget);
    expect(tester.widget<IconButton>(addButtonFinder).onPressed, isNull);

    await tester.enterText(find.byType(TextFormField), 'Nutty');
    await tester.pump();

    expect(tester.widget<IconButton>(addButtonFinder).onPressed, isNotNull);
    await tester.tap(addButtonFinder);
    await tester.pumpAndSettle();

    expect(changed, ['Nutty']);
  });

  testWidgets('entering "a, b" commits "a" and leaves "b" pending', (
    tester,
  ) async {
    List<String>? changed;
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(
        Padding(
          padding: const EdgeInsets.all(16),
          child: ChipInput(
            label: 'Tasting notes',
            controller: controller,
            onChanged: (values) => changed = values,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'a, b');
    await tester.pumpAndSettle();

    expect(changed, ['a']);
    expect(controller.text.trim(), 'b');
    expect(tester.takeException(), isNull);
  });

  testWidgets('labeled and numeric fields retain their input behavior', (
    tester,
  ) async {
    double? numericValue;
    await tester.pumpWidget(
      host(
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const LabeledField(label: 'Name', initialValue: 'Coffee'),
            NumericTextField(
              label: 'Dose',
              onChanged: (value) => numericValue = value,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Dose'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, '18');
    await tester.pump();
    expect(numericValue, 18);
  });

  testWidgets('numeric field can use an outlined floating label', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const NumericTextField(
          label: 'Water Temperature (°C)',
          initialValue: 95,
          labelInsideField: true,
          autofocus: true,
        ),
      ),
    );

    final decorator = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    final editableText = tester.widget<EditableText>(find.byType(EditableText));
    expect(decorator.decoration.labelText, 'Water Temperature (°C)');
    expect(editableText.focusNode.hasFocus, isTrue);
    expect(find.text('Water Temperature (°C)'), findsOneWidget);
  });

  testWidgets('brewing method overlay returns the selected method', (
    tester,
  ) async {
    String? selectedId;
    final methods = [
      BrewingMethodModel(brewingMethodId: 'v60', brewingMethod: 'V60'),
      BrewingMethodModel(
        brewingMethodId: 'aeropress',
        brewingMethod: 'AeroPress',
      ),
    ];
    await tester.pumpWidget(
      host(
        RecipeBrewingMethodCard(
          brewingMethods: methods,
          selectedBrewingMethodId: 'v60',
          onBrewingMethodChanged: (value) => selectedId = value,
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump(const Duration(milliseconds: 250));
    final aeroPressTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'AeroPress'),
    );
    aeroPressTile.onTap!();
    await tester.pump();

    expect(selectedId, 'aeropress');
    expect(tester.takeException(), isNull);
  });
}
