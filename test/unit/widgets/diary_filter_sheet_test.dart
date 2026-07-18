import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/widgets/brew_diary/diary_filter_sheet.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('real modal keeps its title below the safe top inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 240);
    tester.view.viewPadding = const FakeViewPadding(top: 240);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await _openSheet(tester, entries: _largeBeanCollection());

    final titleTop = tester.getTopLeft(
      find.byKey(const ValueKey('diaryFilterTitle_overview')),
    );
    expect(titleTop.dy, greaterThanOrEqualTo(240));
  });

  testWidgets('uses dedicated coffee icons for methods and beans', (
    tester,
  ) async {
    await _openSheet(tester, entries: _largeBeanCollection());

    expect(find.byIcon(Coffeico.coffee_maker), findsOneWidget);
    expect(find.byIcon(Coffeico.bag_with_bean), findsOneWidget);

    await _openBeanChooser(tester);
    await tester.tap(find.byKey(const ValueKey('diaryRoaster_Roaster 00')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Coffeico.bag_with_bean), findsOneWidget);
  });

  testWidgets('100 beans use grouped roaster navigation and direct search', (
    tester,
  ) async {
    await _openSheet(tester, entries: _largeBeanCollection());

    expect(find.text('Bean 00-00'), findsNothing);
    expect(find.byType(FilterChip), findsNWidgets(7));

    await tester.tap(find.byKey(const ValueKey('diaryBeanOverview')));
    await tester.pumpAndSettle();

    expect(find.text('10 beans'), findsNWidgets(10));

    await tester.enterText(find.byType(TextFormField), 'Bean 03-07');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('diaryBeanCheckbox_bean-03-07')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('diaryBeanCheckbox_bean-03-07')),
        matching: find.text('Bean 03-07'),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField), 'Roaster 04');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('diaryBeanCheckbox_bean-04-00')),
      findsOneWidget,
    );
    expect(find.text('Bean 03-07'), findsNothing);
  });

  testWidgets('cross-roaster selections persist through search and Apply', (
    tester,
  ) async {
    final result = await _openSheet(tester, entries: _largeBeanCollection());

    await _openBeanChooser(tester);
    await tester.tap(find.byKey(const ValueKey('diaryRoaster_Roaster 00')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('diaryBeanCheckbox_bean-00-00')),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('diaryFilterBack')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('diaryRoaster_Roaster 01')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('diaryBeanCheckbox_bean-01-00')),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('diaryFilterBack')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Bean 00-00');
    await tester.pump();
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('diaryBeanCheckbox_bean-00-00')),
          )
          .value,
      isTrue,
    );

    await tester.enterText(find.byType(TextFormField), '');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('diaryFilterBack')));
    await tester.pumpAndSettle();
    expect(find.text('2 beans selected'), findsOneWidget);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect((await result.future)!.beanUuids, {'bean-00-00', 'bean-01-00'});
  });

  testWidgets('all existing filter dimensions still apply unchanged', (
    tester,
  ) async {
    final result = await _openSheet(tester, entries: _largeBeanCollection());

    await tester.tap(find.widgetWithText(FilterChip, 'V60'));
    await tester.pump();

    final overview = find.descendant(
      of: find.byKey(const ValueKey('diaryFilterOverview')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(FilterChip, 'Kenya'),
      160,
      scrollable: overview,
    );
    await tester.tap(find.widgetWithText(FilterChip, 'Kenya'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.widgetWithText(FilterChip, '★4+'),
      160,
      scrollable: overview,
    );
    await tester.tap(find.widgetWithText(FilterChip, '★4+'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Has notes'),
      160,
      scrollable: overview,
    );
    await tester.tap(find.text('Has notes'));
    await tester.tap(find.text('Has extraction'));
    await tester.pump();

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    final selection = (await result.future)!;
    expect(selection.methodIds, {'v60'});
    expect(selection.origins, {'Kenya'});
    expect(selection.ratingThreshold, 4);
    expect(selection.hasNotes, isTrue);
    expect(selection.hasExtractionYield, isTrue);
  });

  testWidgets('Clear resets beans and every existing filter dimension', (
    tester,
  ) async {
    final result = await _openSheet(
      tester,
      entries: _largeBeanCollection(),
      initialSelection: const DiaryFilterSelection(
        methodIds: {'v60'},
        beanUuids: {'bean-00-00', 'bean-01-00'},
        origins: {'Kenya'},
        ratingThreshold: 4,
        hasNotes: true,
        hasExtractionYield: true,
      ),
    );

    await tester.tap(find.text('Clear filters'));
    await tester.pump();
    expect(find.text('Any bean'), findsOneWidget);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect((await result.future)!.isEmpty, isTrue);
  });

  testWidgets('tags section appears only when entries carry tags', (
    tester,
  ) async {
    await _openSheet(tester, entries: _largeBeanCollection());
    expect(find.text('Tags'), findsNothing);

    final withTags = [
      ..._largeBeanCollection(),
      DiaryEntry(
        statUuid: 'tagged-1',
        recipeId: 'recipe-tagged',
        recipeName: 'Tagged recipe',
        brewingMethodId: 'v60',
        methodName: 'V60',
        createdAt: DateTime(2026, 7, 5, 8),
        coffeeAmount: 15,
        waterAmount: 250,
        isMarked: false,
        tags: 'fruity, bright',
      ),
    ];
    await _openSheet(tester, entries: withTags);
    expect(find.text('Tags'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '#fruity'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '#bright'), findsOneWidget);
  });

  testWidgets('selecting a tag returns it in the applied selection', (
    tester,
  ) async {
    final entries = [
      ..._largeBeanCollection(),
      DiaryEntry(
        statUuid: 'tagged-1',
        recipeId: 'recipe-tagged',
        recipeName: 'Tagged recipe',
        brewingMethodId: 'v60',
        methodName: 'V60',
        createdAt: DateTime(2026, 7, 5, 8),
        coffeeAmount: 15,
        waterAmount: 250,
        isMarked: false,
        tags: 'fruity, bright',
      ),
    ];
    final result = await _openSheet(tester, entries: entries);

    final overview = find.descendant(
      of: find.byKey(const ValueKey('diaryFilterOverview')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(FilterChip, '#fruity'),
      160,
      scrollable: overview,
    );
    await tester.tap(find.widgetWithText(FilterChip, '#fruity'));
    await tester.pump();

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect((await result.future)!.tags, {'fruity'});
  });

  testWidgets('Clear resets tags along with every other filter dimension', (
    tester,
  ) async {
    final entries = [
      ..._largeBeanCollection(),
      DiaryEntry(
        statUuid: 'tagged-1',
        recipeId: 'recipe-tagged',
        recipeName: 'Tagged recipe',
        brewingMethodId: 'v60',
        methodName: 'V60',
        createdAt: DateTime(2026, 7, 5, 8),
        coffeeAmount: 15,
        waterAmount: 250,
        isMarked: false,
        tags: 'fruity, bright',
      ),
    ];
    final result = await _openSheet(
      tester,
      entries: entries,
      initialSelection: const DiaryFilterSelection(tags: {'fruity'}),
    );

    await tester.tap(find.text('Clear filters'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect((await result.future)!.isEmpty, isTrue);
  });

  testWidgets('dismissing the modal returns null without applying changes', (
    tester,
  ) async {
    final result = await _openSheet(
      tester,
      entries: _largeBeanCollection(),
      initialSelection: const DiaryFilterSelection(beanUuids: {'bean-00-00'}),
    );

    await _openBeanChooser(tester);
    await tester.tap(find.byKey(const ValueKey('diaryRoaster_Roaster 01')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('diaryBeanCheckbox_bean-01-00')),
    );
    await tester.pump();
    Navigator.of(
      tester.element(find.byKey(const ValueKey('diaryBeansForRoaster'))),
    ).pop();
    await tester.pumpAndSettle();

    expect(await result.future, isNull);
  });
}

Future<Completer<DiaryFilterSelection?>> _openSheet(
  WidgetTester tester, {
  required List<DiaryEntry> entries,
  DiaryFilterSelection initialSelection = const DiaryFilterSelection(),
}) async {
  late BuildContext hostContext;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) {
          hostContext = context;
          return const Scaffold(body: SizedBox.expand());
        },
      ),
    ),
  );

  final result = Completer<DiaryFilterSelection?>();
  showDiaryFilterSheet(
    hostContext,
    entries: entries,
    initialSelection: initialSelection,
  ).then(result.complete);
  await tester.pumpAndSettle();
  return result;
}

Future<void> _openBeanChooser(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('diaryBeanOverview')));
  await tester.pumpAndSettle();
}

List<DiaryEntry> _largeBeanCollection() {
  return [
    for (var roasterIndex = 0; roasterIndex < 10; roasterIndex++)
      for (var beanIndex = 0; beanIndex < 10; beanIndex++)
        DiaryEntry(
          statUuid: 'stat-$roasterIndex-$beanIndex',
          recipeId: 'recipe-$beanIndex',
          recipeName: 'Recipe $beanIndex',
          brewingMethodId: beanIndex.isEven ? 'v60' : 'aeropress',
          methodName: beanIndex.isEven ? 'V60' : 'AeroPress',
          createdAt: DateTime(2026, 7, 1, 8, beanIndex),
          coffeeAmount: 15,
          waterAmount: 250,
          extractionYieldPercent: beanIndex.isEven ? 20 : null,
          rating: beanIndex.isEven ? 4.5 : 2.5,
          isMarked: false,
          notes: beanIndex.isEven ? 'Sweet' : null,
          coffeeBeansUuid:
              'bean-${roasterIndex.toString().padLeft(2, '0')}-${beanIndex.toString().padLeft(2, '0')}',
          beanName:
              'Bean ${roasterIndex.toString().padLeft(2, '0')}-${beanIndex.toString().padLeft(2, '0')}',
          roaster: 'Roaster ${roasterIndex.toString().padLeft(2, '0')}',
          origin: beanIndex.isEven ? 'Kenya' : 'Ethiopia',
        ),
  ];
}
