import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_entry_card.dart';
import 'package:coffee_timer/widgets/brew_diary/diary_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget localizedApp(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('minimal diary card uses content height', (tester) async {
    final entry = DiaryEntry(
      statUuid: 'stat-1',
      recipeId: 'recipe-1',
      recipeName: 'Test recipe',
      brewingMethodId: 'v60',
      methodName: 'V60',
      createdAt: DateTime.utc(2026, 7, 1, 8, 30),
      coffeeAmount: 15,
      waterAmount: 250,
      isMarked: false,
    );
    await tester.pumpWidget(
      localizedApp(
        BrewEntryCard(
          entry: entry,
          formattedTime: '08:30',
          onTap: () {},
          onBookmarkToggle: () {},
          tasteLabels: const ['Sour', 'Balanced', 'Bitter'],
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(Card)).height,
      lessThan(AppSpacing.xxl * 4),
    );
    final title = tester.widget<Text>(find.text('Test recipe'));
    expect(title.style?.fontSize, AppTextStyles.itemTitle.fontSize);
    expect(title.style?.fontWeight, AppTextStyles.itemTitle.fontWeight);
    expect(title.maxLines, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search has one floating label and preserves editing state', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      localizedApp(
        DiaryFilterBar(
          searchController: controller,
          topMethods: const [],
          selectedMethodIds: const {},
          selectedTags: const {},
          ratingFourPlus: false,
          bookmarkedOnly: false,
          hasAnyFilter: false,
          onSearchChanged: changes.add,
          onOpenFilters: () {},
          onClearAll: () {},
          onRatingFourPlusChanged: (_) {},
          onBookmarkedChanged: (_) {},
          onMethodChanged: (_, _) {},
          onTagRemoved: (_) {},
        ),
      ),
    );
    final loc = AppLocalizations.of(
      tester.element(find.byType(DiaryFilterBar)),
    )!;
    final field = find.byType(TextField);
    final element = tester.element(field);

    void expectSingleLabel() {
      final decoration = tester.widget<TextField>(field).decoration!;
      expect(decoration.labelText, loc.diarySearchHint);
      expect(decoration.hintText, isNull);
      expect(find.text(loc.diarySearchHint), findsOneWidget);
      expect(find.bySemanticsIdentifier('brewDiarySearch'), findsOneWidget);
      expect(
        tester.getSemantics(field).getSemanticsData().label,
        contains(loc.diarySearchHint),
      );
      expect(tester.element(field), same(element));
    }

    expectSingleLabel();
    await tester.enterText(field, 'V60');
    await tester.pumpAndSettle();
    expectSingleLabel();
    expect(controller.text, 'V60');
    expect(changes, contains('V60'));
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
