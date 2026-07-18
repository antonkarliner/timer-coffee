import 'dart:ui' show SemanticsAction, Tristate;

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/widgets/coffee_bean_details/coffee_beans_hero_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../widgets/brew_flow_async_context_test.mocks.dart';

void main() {
  Future<void> verifyLocalizedSemantics(
    WidgetTester tester, {
    required Locale locale,
    required bool isFavorite,
  }) async {
    final semantics = tester.ensureSemantics();
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    final bean = CoffeeBeansModel(
      beansUuid: 'bean-1',
      roaster: 'Test Roaster',
      name: 'Test Beans',
      origin: 'Test Origin',
      roastDate: DateTime(2026, 7, 1),
      packageWeightGrams: 250,
      cuppingScore: 86.5,
      isFavorite: isFavorite,
      versionVector: '{}',
    );
    var roasterTaps = 0;
    when(
      coffeeBeansProvider.toggleFavoriteStatus(bean.beansUuid, !isFavorite),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      ChangeNotifierProvider<DateTimeFormatService>.value(
        value: DateTimeFormatService(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: Scaffold(
            body: CoffeeBeansHeroHeader(
              bean: bean,
              coffeeBeansProvider: coffeeBeansProvider,
              onRoasterTap: () => roasterTaps += 1,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoffeeBeansHeroHeader)),
    )!;
    final parentData = tester
        .getSemantics(
          find.bySemanticsIdentifier('coffeeBeansHeroHeader_${bean.beansUuid}'),
        )
        .getSemanticsData();
    expect(parentData.label, isEmpty);

    expect(
      tester
          .getSemantics(
            find.bySemanticsIdentifier('roasterLogo_${bean.roaster}'),
          )
          .label,
      l10n.roasterLogoSemantic(bean.roaster),
    );
    expect(
      tester
          .getSemantics(
            find.bySemanticsIdentifier('beanName_${bean.beansUuid}'),
          )
          .label,
      l10n.coffeeBeanNameSemantic(bean.name),
    );
    expect(
      tester
          .getSemantics(
            find.bySemanticsIdentifier('beanOrigin_${bean.beansUuid}'),
          )
          .label,
      l10n.beanOriginSemantic(bean.origin),
    );

    final roasterData = tester
        .getSemantics(
          find.bySemanticsIdentifier('roasterName_${bean.beansUuid}'),
        )
        .getSemanticsData();
    expect(roasterData.label, l10n.roasterNameSemantic(bean.roaster));
    expect(roasterData.flagsCollection.isButton, isTrue);
    expect(roasterData.hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(
      find.semantics.byLabel(l10n.roasterNameSemantic(bean.roaster)),
    );
    await tester.pump();
    expect(roasterTaps, 1);

    final favoriteLabel = isFavorite ? l10n.removeFavorite : l10n.addFavorite;
    final favoriteData = tester
        .getSemantics(
          find.bySemanticsIdentifier('favoriteButton_${bean.beansUuid}'),
        )
        .getSemanticsData();
    expect(favoriteData.label, favoriteLabel);
    expect(favoriteData.flagsCollection.isButton, isTrue);
    expect(
      favoriteData.flagsCollection.isToggled,
      isFavorite ? Tristate.isTrue : Tristate.isFalse,
    );
    expect(favoriteData.hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel(favoriteLabel));
    await tester.pump();
    verify(
      coffeeBeansProvider.toggleFavoriteStatus(bean.beansUuid, !isFavorite),
    ).called(1);

    expect(
      tester
          .getSemantics(
            find.bySemanticsIdentifier('quickStats_${bean.beansUuid}'),
          )
          .label,
      l10n.quickStatisticsSemantic,
    );
    semantics.dispose();
  }

  testWidgets('English semantics expose localized labels and actions', (
    tester,
  ) async {
    await verifyLocalizedSemantics(
      tester,
      locale: const Locale('en'),
      isFavorite: false,
    );
  });

  testWidgets('Arabic semantics expose localized labels and toggle state', (
    tester,
  ) async {
    await verifyLocalizedSemantics(
      tester,
      locale: const Locale('ar'),
      isFavorite: true,
    );
  });
}
