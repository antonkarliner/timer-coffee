import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/bean_journey_screen.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/widgets/brew_diary/journey_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows only entries matching the requested stable bean UUID', (
    tester,
  ) async {
    final provider = _StubUserStatProvider(
      (_) async => [
        _entry(
          id: 'requested',
          beanUuid: ' bean-1 ',
          beanName: 'Shared display name',
        ),
        _entry(
          id: 'other',
          beanUuid: 'bean-2',
          beanName: 'Shared display name',
        ),
      ],
    );

    await _pumpScreen(tester, provider: provider, beanUuid: 'bean-1');
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier('journeyView_bean-1'), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('journeyAttempt_requested'),
      findsOneWidget,
    );
    expect(find.bySemanticsIdentifier('journeyAttempt_other'), findsNothing);
  });

  testWidgets('normalizes an empty joined recipe name', (tester) async {
    final provider = _StubUserStatProvider(
      (_) async => [
        _entry(id: 'empty-recipe', beanUuid: 'bean-1', recipeName: ''),
      ],
    );

    await _pumpScreen(tester, provider: provider, beanUuid: 'bean-1');
    await tester.pumpAndSettle();
    final loc = AppLocalizations.of(
      tester.element(find.byType(BeanJourneyScreen)),
    )!;

    expect(find.text(loc.unknownRecipe), findsOneWidget);
  });

  testWidgets('shows the localized empty state for a missing group', (
    tester,
  ) async {
    final provider = _StubUserStatProvider((_) async => []);

    await _pumpScreen(tester, provider: provider, beanUuid: 'missing');
    await tester.pumpAndSettle();
    final loc = AppLocalizations.of(
      tester.element(find.byType(BeanJourneyScreen)),
    )!;

    expect(find.text(loc.beanJourneyNoBrews), findsOneWidget);
    expect(find.byType(JourneyView), findsNothing);
  });

  testWidgets('shows the localized error state when diary loading fails', (
    tester,
  ) async {
    final provider = _StubUserStatProvider(
      (_) => throw StateError('load failed'),
    );

    await _pumpScreen(tester, provider: provider, beanUuid: 'bean-1');
    await tester.pumpAndSettle();
    final loc = AppLocalizations.of(
      tester.element(find.byType(BeanJourneyScreen)),
    )!;

    expect(find.text(loc.diaryLoadError), findsOneWidget);
    expect(find.byType(JourneyView), findsNothing);
  });

  testWidgets('keeps the loading shell until diary entries resolve', (
    tester,
  ) async {
    final completer = Completer<List<DiaryEntry>>();
    final provider = _StubUserStatProvider((_) => completer.future);

    await _pumpScreen(tester, provider: provider, beanUuid: 'bean-1');
    final loc = AppLocalizations.of(
      tester.element(find.byType(BeanJourneyScreen)),
    )!;

    expect(find.text(loc.beanJourneyTitle), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(JourneyView), findsNothing);
    expect(find.text(loc.beanJourneyNoBrews), findsNothing);

    completer.complete([_entry(id: 'loaded', beanUuid: 'bean-1')]);
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier('journeyView_bean-1'), findsOneWidget);
  });

  testWidgets('bean header pops to the existing bean record', (tester) async {
    final provider = _StubUserStatProvider(
      (_) async => [_entry(id: 'pop', beanUuid: 'bean-1')],
    );

    await _pumpScreen(
      tester,
      provider: provider,
      beanUuid: 'bean-1',
      startOnRecord: true,
    );
    await tester.tap(find.byKey(const ValueKey('openJourney')));
    await tester.pumpAndSettle();
    expect(find.byType(BeanJourneyScreen), findsOneWidget);

    await tester.tap(find.bySemanticsIdentifier('journeyBeanHeader_bean-1'));
    await tester.pumpAndSettle();

    expect(find.text('Bean record'), findsOneWidget);
    expect(find.byType(BeanJourneyScreen), findsNothing);
  });
}

class _StubUserStatProvider extends Mock implements UserStatProvider {
  _StubUserStatProvider(this._fetchEntries);

  final Future<List<DiaryEntry>> Function(String locale) _fetchEntries;

  @override
  Future<List<DiaryEntry>> fetchDiaryEntries(String locale) =>
      _fetchEntries(locale);
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required UserStatProvider provider,
  required String beanUuid,
  bool startOnRecord = false,
}) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final home = startOnRecord
      ? _BeanRecordHarness(beanUuid: beanUuid)
      : BeanJourneyScreen(beanUuid: beanUuid);
  await tester.pumpWidget(
    ChangeNotifierProvider<UserStatProvider>.value(
      value: provider,
      child: ChangeNotifierProvider<DateTimeFormatService>(
        create: (_) => DateTimeFormatService(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    ),
  );
  await tester.pump();
}

class _BeanRecordHarness extends StatelessWidget {
  const _BeanRecordHarness({required this.beanUuid});

  final String beanUuid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('Bean record'),
          ElevatedButton(
            key: const ValueKey('openJourney'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BeanJourneyScreen(beanUuid: beanUuid),
              ),
            ),
            child: const Text('Open Journey'),
          ),
        ],
      ),
    );
  }
}

DiaryEntry _entry({
  required String id,
  required String beanUuid,
  String beanName = 'Test beans',
  String recipeName = 'Test recipe',
}) {
  return DiaryEntry(
    statUuid: id,
    recipeId: 'recipe-$id',
    recipeName: recipeName,
    brewingMethodId: 'v60',
    methodName: 'V60',
    createdAt: DateTime(2026, 7, 1, 9),
    coffeeAmount: 15,
    waterAmount: 250,
    isMarked: false,
    coffeeBeansUuid: beanUuid,
    beanName: beanName,
    origin: 'Kenya',
  );
}
