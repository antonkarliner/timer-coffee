import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/fields/chip_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({
    required ScrollController scrollController,
    double fillerHeight = 100,
    List<String> suggestions = const ['Blueberry', 'Blackcurrant'],
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListView(
          controller: scrollController,
          children: [
            SizedBox(
              height: fillerHeight,
              child: const ColoredBox(color: Colors.grey),
            ),
            ChipInput(
              label: 'Flavor notes',
              suggestions: suggestions,
              showSuggestions: true,
            ),
            const SizedBox(height: 1200, child: ColoredBox(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  testWidgets('suggestion overlay follows the field when the scroll view scrolls', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      buildSubject(scrollController: scrollController),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'Blue');
    await tester.pump();

    expect(find.text('Blueberry'), findsOneWidget);

    final double initialDy = tester.getTopLeft(find.text('Blueberry')).dy;

    scrollController.jumpTo(100);
    await tester.pump();

    final double afterScrollDy = tester.getTopLeft(find.text('Blueberry')).dy;

    expect(afterScrollDy, closeTo(initialDy - 100, 2.0));
  });

  testWidgets(
    'suggestion overlay shrinks to fit above the on-screen keyboard '
    'instead of extending behind it',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Ten suggestions so content height (10 * 48 = 480) exceeds the space
      // available below the field in either scenario below, meaning the
      // rendered height is always bound by available screen space.
      final manySuggestions = List.generate(10, (i) => 'Blend $i');

      Future<Size> openSuggestions(double fillerHeight) async {
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          buildSubject(
            scrollController: scrollController,
            fillerHeight: fillerHeight,
            suggestions: manySuggestions,
          ),
        );

        await tester.tap(find.byType(TextFormField));
        await tester.enterText(find.byType(TextFormField), 'Blend');
        await tester.pump();

        expect(find.text('Blend 0'), findsOneWidget);

        return tester.getSize(
          find
              .ancestor(
                of: find.text('Blend 0'),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        );
      }

      // Field placed low on a tall screen, no keyboard: plenty of room.
      tester.view.viewInsets = FakeViewPadding.zero;
      final Size sizeWithoutKeyboard = await openSuggestions(550);

      // Same layout, but with a keyboard-sized bottom inset: the space
      // below the field is genuinely smaller now.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(() => tester.view.resetViewInsets());
      final Size sizeWithKeyboard = await openSuggestions(550);

      expect(
        sizeWithKeyboard.height,
        lessThan(sizeWithoutKeyboard.height),
        reason:
            'the overlay must shrink to leave room for the keyboard '
            'instead of sizing itself as if the keyboard were absent',
      );
    },
  );
}
