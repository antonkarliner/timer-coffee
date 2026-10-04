import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_detail_sheet.dart';
import 'package:coffee_timer/widgets/fields/dropdown_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'brew_flow_async_context_test.mocks.dart';

void main() {
  testWidgets('Edit grind opens recent suggestions without typing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final stats = MockUserStatProvider();
    final beans = MockCoffeeBeansProvider();
    when(
      stats.fetchAllDistinctGrindSizes(),
    ).thenAnswer((_) async => ['Medium']);
    when(
      stats.fetchRecentDistinctGrindSizes(limit: anyNamed('limit')),
    ).thenAnswer((_) async => ['Medium', '18 clicks', '20 clicks']);
    when(
      beans.fetchAllDistinctGrindSizes(),
    ).thenAnswer((_) async => ['Medium', '20 clicks', 'Coarse', 'Fine']);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserStatProvider>.value(value: stats),
          ChangeNotifierProvider<CoffeeBeansProvider>.value(value: beans),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BrewDetailSheet(
              entry: DiaryEntry(
                statUuid: 'stat-1',
                recipeId: 'recipe-1',
                recipeName: 'Test recipe',
                brewingMethodId: 'v60',
                methodName: 'V60',
                createdAt: DateTime(2026, 7, 14),
                coffeeAmount: 15,
                waterAmount: 250,
                grindSize: 'Medium',
                isMarked: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    verifyNever(stats.fetchRecentDistinctGrindSizes(limit: anyNamed('limit')));
    verifyNever(beans.fetchAllDistinctGrindSizes());

    await tester.ensureVisible(find.byKey(const Key('editGrindButton')));
    await tester.tap(find.byKey(const Key('editGrindButton')));
    await tester.pumpAndSettle();

    final input = find.descendant(
      of: find.byKey(const Key('focusedGrindInput')),
      matching: find.byType(TextFormField),
    );
    expect(tester.widget<TextFormField>(input).controller!.text, 'Medium');
    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: input, matching: find.byType(EditableText)),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );
    expect(find.text('18 clicks'), findsOneWidget);
    expect(find.text('20 clicks'), findsOneWidget);
    expect(find.text('Coarse'), findsOneWidget);
    expect(find.text('Fine'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(DropdownSearchField),
        matching: find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == 'Medium',
        ),
      ),
      findsNothing,
    );
    verify(stats.fetchRecentDistinctGrindSizes(limit: 4)).called(1);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('focusedCancelButton')));
    await tester.pumpAndSettle();
    expect(find.text('18 clicks'), findsNothing);
  });
}
