import 'package:coffee_timer/widgets/recipe_detail/floating_nav_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exposes a stable identifier for screenshot automation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FloatingNavButton(onPressed: () {})),
      ),
    );

    final semantics = tester.getSemantics(find.byType(FloatingNavButton));

    expect(semantics.identifier, 'recipeDetailNextButton');
    expect(semantics.flagsCollection.isButton, isTrue);
  });
}
