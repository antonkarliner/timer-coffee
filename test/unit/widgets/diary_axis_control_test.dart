import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/screens/brew_diary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<AppLocalizations> pumpControl(
    WidgetTester tester, {
    required bool groupedByBean,
    required VoidCallback onTimelineSelected,
    required VoidCallback onBeansSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: DiaryAxisControl(
            groupedByBean: groupedByBean,
            onTimelineSelected: onTimelineSelected,
            onBeansSelected: onBeansSelected,
          ),
        ),
      ),
    );
    return AppLocalizations.of(tester.element(find.byType(DiaryAxisControl)))!;
  }

  testWidgets('shows exactly the timeline and bean tabs, no chips', (
    tester,
  ) async {
    final loc = await pumpControl(
      tester,
      groupedByBean: false,
      onTimelineSelected: () {},
      onBeansSelected: () {},
    );

    expect(find.text(loc.diaryAxisTimeline), findsOneWidget);
    expect(find.text(loc.diaryGroupByBean), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(2));
    expect(find.byType(FilterChip), findsNothing);
    expect(find.byType(PopupMenuButton), findsNothing);
  });

  testWidgets('starts with the second tab selected when groupedByBean', (
    tester,
  ) async {
    await pumpControl(
      tester,
      groupedByBean: true,
      onTimelineSelected: () {},
      onBeansSelected: () {},
    );

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.controller!.index, 1);
  });

  testWidgets('tapping the bean tab fires onBeansSelected', (tester) async {
    var beansSelected = false;
    var timelineSelected = false;
    final loc = await pumpControl(
      tester,
      groupedByBean: false,
      onTimelineSelected: () => timelineSelected = true,
      onBeansSelected: () => beansSelected = true,
    );

    await tester.tap(find.text(loc.diaryGroupByBean));
    await tester.pumpAndSettle();

    expect(beansSelected, isTrue);
    expect(timelineSelected, isFalse);
  });

  testWidgets('tapping the timeline tab fires onTimelineSelected', (
    tester,
  ) async {
    var beansSelected = false;
    var timelineSelected = false;
    final loc = await pumpControl(
      tester,
      groupedByBean: true,
      onTimelineSelected: () => timelineSelected = true,
      onBeansSelected: () => beansSelected = true,
    );

    await tester.tap(find.text(loc.diaryAxisTimeline));
    await tester.pumpAndSettle();

    expect(timelineSelected, isTrue);
    expect(beansSelected, isFalse);
  });
}
