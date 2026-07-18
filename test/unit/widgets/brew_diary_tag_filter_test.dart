import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/brew_diary_screen.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'brew_flow_async_context_test.mocks.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  DiaryEntry entry({
    required String id,
    String? tags,
    DateTime? createdAt,
  }) => DiaryEntry(
    statUuid: id,
    recipeId: 'recipe-$id',
    recipeName: 'Recipe $id',
    brewingMethodId: 'v60',
    methodName: 'V60',
    createdAt: createdAt ?? DateTime.utc(2026, 7, 1, 8, 30),
    coffeeAmount: 15,
    waterAmount: 250,
    isMarked: false,
    tags: tags,
  );

  Widget diaryApp(UserStatProvider provider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserStatProvider>.value(value: provider),
        ChangeNotifierProvider<DateTimeFormatService>(
          create: (_) => DateTimeFormatService(),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const BrewDiaryScreen(),
      ),
    );
  }

  testWidgets(
    'tag filter selection matches entries with ANY selected tag (OR semantics)',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fruity = entry(
        id: 'fruity',
        tags: 'fruity',
        createdAt: DateTime.utc(2026, 7, 1, 8),
      );
      final earthy = entry(
        id: 'earthy',
        tags: 'earthy',
        createdAt: DateTime.utc(2026, 7, 2, 8),
      );
      final untagged = entry(
        id: 'untagged',
        createdAt: DateTime.utc(2026, 7, 3, 8),
      );

      final provider = MockUserStatProvider();
      when(
        provider.fetchDiaryEntries('en'),
      ).thenAnswer((_) async => [fruity, earthy, untagged]);
      when(
        provider.topMethodsLast90Days('en'),
      ).thenAnswer((_) async => const []);

      await tester.pumpWidget(diaryApp(provider));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsIdentifier('userStatCard_${fruity.statUuid}'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier('userStatCard_${earthy.statUuid}'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier('userStatCard_${untagged.statUuid}'),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

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
      await tester.scrollUntilVisible(
        find.widgetWithText(FilterChip, '#earthy'),
        160,
        scrollable: overview,
      );
      await tester.tap(find.widgetWithText(FilterChip, '#earthy'));
      await tester.pump();

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsIdentifier('userStatCard_${fruity.statUuid}'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier('userStatCard_${earthy.statUuid}'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsIdentifier('userStatCard_${untagged.statUuid}'),
        findsNothing,
      );
    },
  );
}
