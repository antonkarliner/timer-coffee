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
