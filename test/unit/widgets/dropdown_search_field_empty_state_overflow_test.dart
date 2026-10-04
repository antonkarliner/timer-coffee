import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/fields/dropdown_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The no-results overlay ("No results found" + "Use \"`<query>`\"") is capped
/// by the space between the field and the keyboard. On a recipe detail page
/// that space came out a few pixels short of the two rows and the overlay
/// threw a RenderFlex "BOTTOM OVERFLOWED" error.
void main() {
  const double screenHeight = 800;
  const double fillerHeight = 300;

  Widget buildSubject() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListView(
          children: [
            const SizedBox(
              height: fillerHeight,
              child: ColoredBox(color: Colors.grey),
            ),
            DropdownSearchField(
              label: 'Grind size',
              onSearch: (query) async => const [],
            ),
            const SizedBox(height: 1200, child: ColoredBox(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  /// Lays the field out with no keyboard, then raises a keyboard-sized inset
  /// that leaves exactly [spaceBelow] logical pixels under the field (after
  /// the overlay's own 8 px gap), and types a query with no matches.
  Future<void> openEmptyStateWithSpaceBelow(
    WidgetTester tester,
    double spaceBelow,
  ) async {
    tester.view.physicalSize = const Size(400, screenHeight);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(buildSubject());

    final double fieldBottom =
        tester.getBottomLeft(find.byType(DropdownSearchField)).dy;
    tester.view.viewInsets = FakeViewPadding(
      bottom: screenHeight - fieldBottom - 8 - spaceBelow,
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'Mex');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  for (final double spaceBelow in [60, 20]) {
    testWidgets(
      'no-results overlay does not overflow with only ${spaceBelow.toInt()} '
      'px above the keyboard',
      (tester) async {
        await openEmptyStateWithSpaceBelow(tester, spaceBelow);

        expect(tester.takeException(), isNull);
        expect(find.text('No results found'), findsOneWidget);
        // The custom-entry row is still in the tree, reachable by scrolling.
        expect(find.text('Use "Mex"', skipOffstage: false), findsOneWidget);

        final double overlayHeight = tester
            .getSize(
              find
                  .ancestor(
                    of: find.text('No results found'),
                    matching: find.byType(SingleChildScrollView),
                  )
                  .first,
            )
            .height;
        expect(overlayHeight, lessThanOrEqualTo(spaceBelow));
      },
    );
  }

  testWidgets(
    'no-results overlay does not throw when the field sits behind the '
    'keyboard edge',
    (tester) async {
      await openEmptyStateWithSpaceBelow(tester, -20);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('no-results overlay with room to spare shows both rows', (
    tester,
  ) async {
    await openEmptyStateWithSpaceBelow(tester, 300);

    expect(tester.takeException(), isNull);
    expect(find.text('No results found'), findsOneWidget);
    expect(find.text('Use "Mex"'), findsOneWidget);

    await tester.tap(find.text('Use "Mex"'));
    await tester.pumpAndSettle();
    expect(find.text('No results found'), findsNothing);
  });
}
