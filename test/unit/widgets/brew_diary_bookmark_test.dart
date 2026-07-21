import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/brew_diary_screen.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/utils/extraction_math.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_entry_card.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'brew_flow_async_context_test.mocks.dart';

void main() {
  Widget localizedApp(
    Widget child, {
    Locale locale = const Locale('en'),
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: child,
    );
  }

  DiaryEntry entry({
    bool isMarked = false,
    String? tags,
    double? extractionYieldPercent = 20.1,
  }) => DiaryEntry(
    statUuid: 'stat-1',
    recipeId: 'recipe-1',
    recipeName: 'Test recipe',
    brewingMethodId: 'v60',
    methodName: 'V60',
    createdAt: DateTime.utc(2026, 7, 1, 8, 30),
    coffeeAmount: 15,
    waterAmount: 250,
    grindSize: '24 clicks',
    waterTemp: 93,
    tdsPercent: 1.35,
    extractionYieldPercent: extractionYieldPercent,
    tasteBalance: 0,
    tags: tags,
    entrySource: 1,
    rating: 4.5,
    isMarked: isMarked,
    notes: 'Sweet cup',
    coffeeBeansUuid: 'bean-1',
    beanName: 'Test beans',
    roaster: null,
    origin: 'Kenya',
  );

  Widget diaryApp(UserStatProvider provider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserStatProvider>.value(value: provider),
        ChangeNotifierProvider<DateTimeFormatService>(
          create: (_) => DateTimeFormatService(),
        ),
      ],
      child: localizedApp(const BrewDiaryScreen()),
    );
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('copyWith preserves every untouched diary field', () {
    final original = entry().copyWith(roaster: 'Test roaster');
    final updated = original.copyWith(isMarked: true);

    expect(updated.statUuid, original.statUuid);
    expect(updated.recipeId, original.recipeId);
    expect(updated.recipeName, original.recipeName);
    expect(updated.brewingMethodId, original.brewingMethodId);
    expect(updated.methodName, original.methodName);
    expect(updated.createdAt, original.createdAt);
    expect(updated.coffeeAmount, original.coffeeAmount);
    expect(updated.waterAmount, original.waterAmount);
    expect(updated.grindSize, original.grindSize);
    expect(updated.waterTemp, original.waterTemp);
    expect(updated.tdsPercent, original.tdsPercent);
    expect(updated.extractionYieldPercent, original.extractionYieldPercent);
    expect(updated.tasteBalance, original.tasteBalance);
    expect(updated.entrySource, original.entrySource);
    expect(updated.rating, original.rating);
    expect(updated.isMarked, isTrue);
    expect(updated.notes, original.notes);
    expect(updated.coffeeBeansUuid, original.coffeeBeansUuid);
    expect(updated.beanName, original.beanName);
    expect(updated.roaster, original.roaster);
    expect(updated.origin, original.origin);

    final cleared = updated.copyWith(
      grindSize: null,
      waterTemp: null,
      tdsPercent: null,
      extractionYieldPercent: null,
      tasteBalance: null,
      entrySource: null,
      rating: null,
      notes: null,
      coffeeBeansUuid: null,
      beanName: null,
      roaster: null,
      origin: null,
    );
    expect(cleared.grindSize, isNull);
    expect(cleared.waterTemp, isNull);
    expect(cleared.tdsPercent, isNull);
    expect(cleared.extractionYieldPercent, isNull);
    expect(cleared.tasteBalance, isNull);
    expect(cleared.entrySource, isNull);
    expect(cleared.rating, isNull);
    expect(cleared.notes, isNull);
    expect(cleared.coffeeBeansUuid, isNull);
    expect(cleared.beanName, isNull);
    expect(cleared.roaster, isNull);
    expect(cleared.origin, isNull);
  });

  testWidgets('card shows full-strength V60 icon and rectangular logo', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        Scaffold(
          body: BrewEntryCard(
            entry: entry(),
            formattedTime: '08:30',
            onTap: () {},
            onBookmarkToggle: () {},
            tasteLabels: const ['Sour', 'Balanced', 'Bitter'],
            logoUrls: Future.value(const {'original': '', 'mirror': null}),
          ),
        ),
      ),
    );
    await tester.pump();

    final methodIcon = tester.widget<Icon>(find.byIcon(Coffeico.hario_v60));
    final colors = Theme.of(
      tester.element(find.byType(BrewEntryCard)),
    ).colorScheme;
    expect(methodIcon.color, colors.primary);
    expect(methodIcon.size, AppIconSize.medium);
    expect(find.text('V60'), findsOneWidget);

    final logo = tester.widget<RoasterLogo>(find.byType(RoasterLogo));
    expect(logo.width, AppSpacing.xxl);
    expect(logo.height, AppIconSize.medium);
    expect(logo.width, greaterThan(logo.height));
    expect(logo.width, isNot(AppIconSize.small));
    expect(logo.height, isNot(AppIconSize.small));
  });

  testWidgets('narrow card wraps every fact chip without scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      localizedApp(
        Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: BrewEntryCard(
              entry: entry(),
              formattedTime: '08:30',
              onTap: () {},
              onBookmarkToggle: () {},
              tasteLabels: const ['Sour', 'Balanced', 'Bitter'],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final card = find.byType(BrewEntryCard);
    expect(
      find.descendant(of: card, matching: find.byType(Scrollable)),
      findsNothing,
    );
    for (final label in [
      '15\u00A0g → 250\u00A0g',
      '24 clicks',
      '93°',
      AppLocalizations.of(
        tester.element(card),
      )!.extractionCalcDiaryLine('20.1', '1.35'),
      'Balanced',
      '★ 4.5',
    ]) {
      expect(find.widgetWithText(Chip, label), findsOneWidget);
    }
    expect(
      find.descendant(of: card, matching: find.byType(Wrap)),
      findsOneWidget,
    );
    expect(tester.getSize(card).height, greaterThan(AppSpacing.xxl * 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('extraction chip color follows the recorded EY band', (
    tester,
  ) async {
    Future<Color?> chipColor(double ey) async {
      await tester.pumpWidget(
        localizedApp(
          Scaffold(
            body: BrewEntryCard(
              entry: entry(extractionYieldPercent: ey),
              formattedTime: '08:30',
              onTap: () {},
              onBookmarkToggle: () {},
              tasteLabels: const ['Sour', 'Balanced', 'Bitter'],
            ),
          ),
        ),
      );
      final card = find.byType(BrewEntryCard);
      final label = AppLocalizations.of(
        tester.element(card),
      )!.extractionCalcDiaryLine(ey.toStringAsFixed(1), '1.35');
      return tester
          .widget<Chip>(
            find.ancestor(of: find.text(label), matching: find.byType(Chip)),
          )
          .backgroundColor;
    }

    expect(
      await chipColor(17.9),
      AppSemanticColors.extractionYield(
        ExtractionBand.under,
        Brightness.light,
      ).background,
    );
    expect(
      await chipColor(20),
      AppSemanticColors.extractionYield(
        ExtractionBand.target,
        Brightness.light,
      ).background,
    );
    expect(
      await chipColor(22.1),
      AppSemanticColors.extractionYield(
        ExtractionBand.over,
        Brightness.light,
      ).background,
    );
  });

  testWidgets('Arabic cards keep measurements and tags in LTR token order', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        Scaffold(
          body: BrewEntryCard(
            entry: entry(tags: 'qa-test, citrus'),
            formattedTime: '08:30',
            onTap: () {},
            onBookmarkToggle: () {},
            tasteLabels: const ['حامض', 'متوازن', 'مر'],
          ),
        ),
        locale: const Locale('ar'),
      ),
    );
    await tester.pump();

    final measurement = tester.widget<Text>(
      find.text('15\u00A0g → 250\u00A0g'),
    );
    final tags = tester.widget<Text>(find.text('#qa-test'));
    expect(
      Directionality.of(tester.element(find.byType(BrewEntryCard))),
      TextDirection.rtl,
    );
    expect(measurement.textDirection, TextDirection.ltr);
    expect(tags.textDirection, TextDirection.ltr);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Timeline card fits audited locales at phone text scales', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final locale in const [
      Locale('de'),
      Locale('ja'),
      Locale('ar'),
      Locale('ru'),
    ]) {
      for (final scale in const [1.0, 1.3]) {
        await tester.pumpWidget(
          localizedApp(
            Scaffold(
              body: Builder(
                builder: (context) {
                  final loc = AppLocalizations.of(context)!;
                  return BrewEntryCard(
                    entry: entry(tags: 'qa-test, citrus'),
                    formattedTime: '08:30',
                    onTap: () {},
                    onBookmarkToggle: () {},
                    tasteLabels: [
                      loc.tasteSour,
                      loc.tasteBalanced,
                      loc.tasteBitter,
                    ],
                  );
                },
              ),
            ),
            locale: locale,
            textScaler: TextScaler.linear(scale),
          ),
        );
        await tester.pump();

        expect(find.byType(BrewEntryCard), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.byType(BrewEntryCard))),
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('bookmark tap does not invoke the card detail callback', (
    tester,
  ) async {
    var bookmarkTaps = 0;
    var detailTaps = 0;
    await tester.pumpWidget(
      localizedApp(
        Scaffold(
          body: BrewEntryCard(
            entry: entry(),
            formattedTime: '08:30',
            onTap: () => detailTaps++,
            onBookmarkToggle: () => bookmarkTaps++,
            tasteLabels: const ['Sour', 'Balanced', 'Bitter'],
          ),
        ),
      ),
    );

    final loc = AppLocalizations.of(
      tester.element(find.byType(BrewEntryCard)),
    )!;
    expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
    expect(find.byTooltip(loc.diaryMarkBookmark), findsOneWidget);

    await tester.tap(find.byTooltip(loc.diaryMarkBookmark));
    await tester.pump();

    expect(bookmarkTaps, 1);
    expect(detailTaps, 0);
  });

  testWidgets('bookmark semantic tap invokes only the bookmark callback', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var bookmarkTaps = 0;
    var detailTaps = 0;
    await tester.pumpWidget(
      localizedApp(
        Scaffold(
          body: BrewEntryCard(
            entry: entry(),
            formattedTime: '08:30',
            onTap: () => detailTaps++,
            onBookmarkToggle: () => bookmarkTaps++,
            tasteLabels: const ['Sour', 'Balanced', 'Bitter'],
          ),
        ),
      ),
    );

    final loc = AppLocalizations.of(
      tester.element(find.byType(BrewEntryCard)),
    )!;
    final bookmark = find.bySemanticsIdentifier('bookmarkToggle_stat-1');
    expect(
      tester
          .getSemantics(bookmark)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    tester.semantics.tap(find.semantics.byLabel(loc.diaryMarkBookmark));
    await tester.pump();

    expect(bookmarkTaps, 1);
    expect(detailTaps, 0);
    semantics.dispose();
  });

  testWidgets('marked card unmarks through the provider', (tester) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = MockUserStatProvider();
    final markedEntry = entry(isMarked: true);
    when(
      provider.fetchDiaryEntries('en'),
    ).thenAnswer((_) async => [markedEntry]);
    when(provider.topMethodsLast90Days('en')).thenAnswer((_) async => const []);
    when(
      provider.updateUserStat(statUuid: markedEntry.statUuid, isMarked: false),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(diaryApp(provider));
    await tester.pumpAndSettle();
    final loc = AppLocalizations.of(
      tester.element(find.byType(BrewDiaryScreen)),
    )!;

    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    expect(find.byTooltip(loc.diaryRemoveBookmark), findsOneWidget);
    final semantics = tester.getSemantics(
      find.bySemanticsIdentifier('bookmarkToggle_${markedEntry.statUuid}'),
    );
    expect(semantics.flagsCollection.isToggled, Tristate.isTrue);

    await tester.tap(find.byTooltip(loc.diaryRemoveBookmark));
    await tester.pumpAndSettle();

    verify(
      provider.updateUserStat(statUuid: markedEntry.statUuid, isMarked: false),
    ).called(1);
    expect(find.byTooltip(loc.diaryMarkBookmark), findsOneWidget);
  });

  testWidgets(
    'pending mark cannot double-submit and updates the Bookmarked filter',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = MockUserStatProvider();
      final unmarkedEntry = entry();
      final pendingMark = Completer<void>();
      when(
        provider.fetchDiaryEntries('en'),
      ).thenAnswer((_) async => [unmarkedEntry]);
      when(
        provider.topMethodsLast90Days('en'),
      ).thenAnswer((_) async => const []);
      when(
        provider.updateUserStat(
          statUuid: unmarkedEntry.statUuid,
          isMarked: true,
        ),
      ).thenAnswer((_) => pendingMark.future);
      when(
        provider.updateUserStat(
          statUuid: unmarkedEntry.statUuid,
          isMarked: false,
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(diaryApp(provider));
      await tester.pumpAndSettle();
      final loc = AppLocalizations.of(
        tester.element(find.byType(BrewDiaryScreen)),
      )!;
      final bookmark = find.bySemanticsIdentifier(
        'bookmarkToggle_${unmarkedEntry.statUuid}',
      );
      final bookmarkedFilter = find.widgetWithText(
        FilterChip,
        loc.diaryBookmarked,
      );

      expect(find.byIcon(Icons.library_books), findsOneWidget);
      expect(
        find.descendant(
          of: bookmarkedFilter,
          matching: find.byIcon(Icons.bookmark_outline),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(
        tester.getSemantics(bookmark).flagsCollection.isToggled,
        Tristate.isFalse,
      );
      await tester.tap(find.byTooltip(loc.diaryMarkBookmark));
      await tester.pump();
      expect(
        tester.getSemantics(bookmark).flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      expect(
        tester
            .getSemantics(bookmark)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );

      await tester.tap(bookmark);
      await tester.pump();
      verify(
        provider.updateUserStat(
          statUuid: unmarkedEntry.statUuid,
          isMarked: true,
        ),
      ).called(1);

      tester.widget<FilterChip>(bookmarkedFilter).onSelected!(true);
      await tester.pump();
      expect(
        find.bySemanticsIdentifier('userStatCard_${unmarkedEntry.statUuid}'),
        findsNothing,
      );

      pendingMark.complete();
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsIdentifier('userStatCard_${unmarkedEntry.statUuid}'),
        findsOneWidget,
      );
      expect(find.byTooltip(loc.diaryRemoveBookmark), findsOneWidget);

      await tester.tap(find.byTooltip(loc.diaryRemoveBookmark));
      await tester.pumpAndSettle();
      verify(
        provider.updateUserStat(
          statUuid: unmarkedEntry.statUuid,
          isMarked: false,
        ),
      ).called(1);
      expect(
        find.bySemanticsIdentifier('userStatCard_${unmarkedEntry.statUuid}'),
        findsNothing,
      );
    },
  );
}
