import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';
import 'package:coffee_timer/widgets/recipe_detail/amount_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('amount fields keep inside labels and report focus and edits', (
    tester,
  ) async {
    final coffeeController = TextEditingController(text: '15');
    final waterController = TextEditingController(text: '240');
    addTearDown(coffeeController.dispose);
    addTearDown(waterController.dispose);
    var coffeeFocusCount = 0;
    var waterFocusCount = 0;
    var coffeeChangeCount = 0;
    var waterChangeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: AmountFields(
            coffeeController: coffeeController,
            waterController: waterController,
            onCoffeeChanged: () {
              coffeeChangeCount++;
              waterController.text = '248';
            },
            onWaterChanged: () {
              waterChangeCount++;
              coffeeController.text = '20';
            },
            onCoffeeFocus: () => coffeeFocusCount++,
            onWaterFocus: () => waterFocusCount++,
          ),
        ),
      ),
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(AmountFields)))!;
    final fields = find.byType(LabeledField);
    expect(fields, findsNWidgets(2));

    final coffeeField = tester.widget<LabeledField>(fields.first);
    final waterField = tester.widget<LabeledField>(fields.last);
    expect(coffeeField.label, l10n.coffeeamount);
    expect(waterField.label, l10n.wateramount);
    for (final field in [coffeeField, waterField]) {
      expect(field.labelInsideField, isTrue);
      expect(
        field.keyboardType,
        const TextInputType.numberWithOptions(decimal: true),
      );
    }

    final inputs = find.byType(TextField);
    await tester.tap(inputs.first);
    await tester.pump();
    expect(coffeeFocusCount, 1);
    expect(waterFocusCount, 0);
    await tester.tap(inputs.first);
    await tester.pump();
    expect(coffeeFocusCount, 1);

    await tester.enterText(inputs.first, '15.5');
    expect(coffeeController.text, '15.5');
    expect(waterController.text, '248');
    expect(coffeeChangeCount, 1);
    expect(waterChangeCount, 0);

    coffeeController.text = '16';
    expect(coffeeChangeCount, 1);
    expect(waterController.text, '248');

    await tester.tap(inputs.last);
    await tester.pump();
    expect(coffeeFocusCount, 1);
    expect(waterFocusCount, 1);

    await tester.enterText(inputs.last, '320.0');
    expect(coffeeController.text, '20');
    expect(waterController.text, '320.0');
    expect(coffeeChangeCount, 1);
    expect(waterChangeCount, 1);
  });
}
