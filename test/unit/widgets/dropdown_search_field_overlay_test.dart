import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/fields/dropdown_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({
    required Future<List<String>> Function(String query) onSearch,
    required ScrollController scrollController,
    double fillerHeight = 100,
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
            DropdownSearchField(
              label: 'Grind size',
              onSearch: onSearch,
            ),
            const SizedBox(height: 1200, child: ColoredBox(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  testWidgets('overlay follows the field when the scroll view scrolls', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      buildSubject(
        onSearch: (query) async => const ['Medium-Fine'],
        scrollController: scrollController,
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Med');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Medium-Fine'), findsOneWidget);

    final double initialDy =
        tester.getTopLeft(find.text('Medium-Fine')).dy;

    scrollController.jumpTo(100);
    await tester.pump();

    final double afterScrollDy =
        tester.getTopLeft(find.text('Medium-Fine')).dy;

    expect(afterScrollDy, closeTo(initialDy - 100, 2.0));
  });

  testWidgets(
    'loading row replaces stale suggestions while a new search is in flight',
    (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      final firstCompleter = Completer<List<String>>();
      final secondCompleter = Completer<List<String>>();
      int callCount = 0;

      Future<List<String>> onSearch(String query) {
        callCount++;
        if (callCount == 1) {
          return firstCompleter.future;
        }
        return secondCompleter.future;
      }

      await tester.pumpWidget(
        buildSubject(
          onSearch: onSearch,
          scrollController: scrollController,
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));

      firstCompleter.complete(['Medium-Fine']);
      await tester.pumpAndSettle();

      expect(find.text('Medium-Fine'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Medi');
      await tester.pump(const Duration(milliseconds: 300));

      // Second search is still unresolved; loading state should show and the
      // stale first-query suggestion should be gone.
      expect(find.text('Searching...'), findsOneWidget);
      expect(find.text('Medium-Fine'), findsNothing);

      secondCompleter.complete(['Medium-Fine']);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'overlay shrinks to fit above the on-screen keyboard instead of '
    'extending behind it',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Ten suggestions so content height (10 * 48 = 480) exceeds both the
      // component's own 8-item cap (384) and the space available below the
      // field in either scenario below, meaning the rendered height is
      // always bound by available screen space, not by content length.
      final manySuggestions = List.generate(10, (i) => 'Suggestion $i');

      Future<Size> openDropdown(double fillerHeight) async {
        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          buildSubject(
            onSearch: (query) async => manySuggestions,
            scrollController: scrollController,
            fillerHeight: fillerHeight,
          ),
        );

        await tester.enterText(find.byType(TextFormField), 'S');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(find.text('Suggestion 0'), findsOneWidget);

        return tester.getSize(
          find
              .ancestor(
                of: find.text('Suggestion 0'),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        );
      }

      // Field placed low on a tall screen, no keyboard: plenty of room.
      tester.view.viewInsets = FakeViewPadding.zero;
      final Size sizeWithoutKeyboard = await openDropdown(550);

      // Same layout, but with a keyboard-sized bottom inset: the space
      // below the field is genuinely smaller now.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(() => tester.view.resetViewInsets());
      final Size sizeWithKeyboard = await openDropdown(550);

      expect(
        sizeWithKeyboard.height,
        lessThan(sizeWithoutKeyboard.height),
        reason:
            'the overlay must shrink to leave room for the keyboard '
            'instead of sizing itself as if the keyboard were absent',
      );
    },
  );

  testWidgets(
    'a query matching no suggestions shows the no-results message and the '
    'use-custom-entry row',
    (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        buildSubject(
          onSearch: (query) async => const [],
          scrollController: scrollController,
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Zzz');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Use "Zzz"'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping the use-custom-entry row commits the typed text',
    (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              controller: scrollController,
              children: [
                DropdownSearchField(
                  label: 'Grind size',
                  onSearch: (query) async => const [],
                  onChanged: (value) => changedValue = value,
                ),
                const SizedBox(
                  height: 1200,
                  child: ColoredBox(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Zzz');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Use "Zzz"'), findsOneWidget);

      await tester.tap(find.text('Use "Zzz"'));
      await tester.pumpAndSettle();

      expect(changedValue, 'Zzz');
      expect(find.text('No results found'), findsNothing);
    },
  );

  testWidgets(
    'allowCustomEntry false shows the no-results message but no '
    'custom-entry row',
    (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              controller: scrollController,
              children: [
                DropdownSearchField(
                  label: 'Grind size',
                  onSearch: (query) async => const [],
                  allowCustomEntry: false,
                ),
                const SizedBox(
                  height: 1200,
                  child: ColoredBox(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Zzz');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsOneWidget);
      expect(find.textContaining('Use "'), findsNothing);
    },
  );

  testWidgets(
    'an empty query still shows no overlay at all',
    (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        buildSubject(
          onSearch: (query) async => const ['Medium-Fine'],
          scrollController: scrollController,
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsNothing);
      expect(find.textContaining('Use "'), findsNothing);
      expect(find.text('Searching...'), findsNothing);
    },
  );
}
