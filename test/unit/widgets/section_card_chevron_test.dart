import 'package:coffee_timer/widgets/containers/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('expanded chevron rotates back when collapsed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionCard(
            title: 'T',
            initiallyExpanded: true,
            child: Text('body'),
          ),
        ),
      ),
    );

    final chevronTransform = find
        .ancestor(
          of: find.byIcon(Icons.expand_more),
          matching: find.byType(Transform),
        )
        .first;
    expect(
      tester.widget<Transform>(chevronTransform).transform.storage[0],
      closeTo(-1.0, 1e-6),
    );

    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Transform>(chevronTransform).transform.storage[0],
      closeTo(1.0, 1e-6),
    );
  });

  testWidgets('collapsed chevron rotates when expanded', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionCard(
            title: 'T',
            initiallyExpanded: false,
            child: Text('body'),
          ),
        ),
      ),
    );

    final chevronTransform = find
        .ancestor(
          of: find.byIcon(Icons.expand_more),
          matching: find.byType(Transform),
        )
        .first;
    expect(
      tester.widget<Transform>(chevronTransform).transform.storage[0],
      closeTo(1.0, 1e-6),
    );

    await tester.tap(find.text('T'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Transform>(chevronTransform).transform.storage[0],
      closeTo(-1.0, 1e-6),
    );
  });
}
