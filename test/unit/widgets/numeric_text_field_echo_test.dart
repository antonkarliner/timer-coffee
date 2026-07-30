import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coffee_timer/controllers/recipe_detail_controller.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/fields/numeric_text_field.dart';

/// Mirrors the recipe detail screen wiring: the field's [initialValue] is fed
/// from controller state that the field itself updates via [onChanged], and the
/// subtree rebuilds on every notification.
class _EchoingHost extends StatelessWidget {
  const _EchoingHost({required this.controller});

  final RecipeDetailController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => NumericTextField(
            label: 'Water temp',
            initialValue: controller.waterTemperature,
            allowDecimal: true,
            autofocus: true,
            onChanged: controller.markWaterTemperatureManuallyEdited,
          ),
        ),
      ),
    );
  }
}

void main() {
  late RecipeDetailController controller;

  setUp(() {
    controller = RecipeDetailController();
  });

  tearDown(() {
    controller.dispose();
  });

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(_EchoingHost(controller: controller));
    await tester.pumpAndSettle();
  }

  testWidgets('the field can be cleared without snapping back to the recipe '
      'value', (tester) async {
    controller.setInitialWaterTemperature(100);
    await pumpHost(tester);

    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).controller!.text, '100');

    await tester.enterText(field, '');
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(controller.waterTemperature, isNull);
    expect(controller.effectiveWaterTemperature, 100);
  });

  testWidgets('a cleared field accepts a new value', (tester) async {
    controller.setInitialWaterTemperature(100);
    await pumpHost(tester);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '95');
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '95',
    );
    expect(controller.waterTemperature, 95);
    expect(controller.effectiveWaterTemperature, 95);
    expect(controller.waterTemperatureFromRecipe, isFalse);
  });

  testWidgets('an external value pushed while focused applies once editing '
      'ends', (tester) async {
    controller.setInitialWaterTemperature(100);
    await pumpHost(tester);

    await tester.enterText(find.byType(TextField), '95');
    await tester.pumpAndSettle();

    // Something outside the field changes the value mid-edit; the text must not
    // be rewritten under the user.
    controller.setInitialWaterTemperature(88);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '95',
    );

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '88',
    );
  });
}
