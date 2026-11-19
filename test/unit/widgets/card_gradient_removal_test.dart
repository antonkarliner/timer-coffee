import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/recipe_collection_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/services/collection_new_badge_service.dart';
import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:coffee_timer/widgets/coffee_beans/coffee_bean_card.dart';
import 'package:coffee_timer/widgets/coffee_beans/coffee_bean_grid_card.dart';
import 'package:coffee_timer/widgets/collection_card.dart';
import 'package:coffeico_plus/coffeico_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../controllers/coffee_beans_controller_async_context_test.mocks.dart'
    show MockCoffeeBeansProvider;
import 'widget_async_context_batch_test.mocks.dart' show MockDatabaseProvider;

void main() {
  final bean = CoffeeBeansModel(
    beansUuid: 'bean-1',
    roaster: 'Test Roaster',
    name: 'Test Beans',
    origin: 'Test Origin',
    packageWeightGrams: 250,
    versionVector: '{}',
  );
  const collection = RecipeCollectionModel(
    id: 'collection-1',
    emoji: '☕',
    displayOrder: 0,
    name: 'Test Collection',
    description: 'Test Description',
  );
  final cards = [
    (
      widget: CoffeeBeanCard(bean: bean, isEditMode: false, onDelete: () {}),
      slotContent: find.byIcon(Coffeico.bag_with_bean),
    ),
    (
      widget: CoffeeBeanGridCard(
        bean: bean,
        isEditMode: false,
        onDelete: () {},
      ),
      slotContent: find.byIcon(Coffeico.bag_with_bean),
    ),
    (
      widget: const CollectionCard(
        collection: collection,
        cardIndex: 0,
        collectionCount: 1,
      ),
      slotContent: find.text(collection.emoji),
    ),
  ];

  for (final colorScheme in [lightColorScheme, darkColorScheme]) {
    for (final card in cards) {
      testWidgets('${card.widget.runtimeType} uses the card theme in '
          '${colorScheme.brightness.name} mode', (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<CoffeeBeansProvider>(
                create: (_) => MockCoffeeBeansProvider(),
              ),
              Provider<DatabaseProvider>(
                create: (_) {
                  final database = MockDatabaseProvider();
                  when(
                    database.fetchCachedRoasterLogoUrls(bean.roaster),
                  ).thenAnswer((_) async => {'original': null, 'mirror': null});
                  return database;
                },
              ),
              ChangeNotifierProvider<CollectionNewBadgeService>(
                create: (_) => CollectionNewBadgeService(),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(colorScheme: colorScheme),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              home: Scaffold(
                body: SizedBox(width: 320, height: 320, child: card.widget),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final materialCard = find.byType(Card);
        expect(tester.widget<Card>(materialCard).color, isNull);
        final decoratedBoxes = find.descendant(
          of: materialCard,
          matching: find.byType(DecoratedBox),
        );
        final decorations = tester
            .widgetList<DecoratedBox>(decoratedBoxes)
            .map((box) => box.decoration)
            .whereType<BoxDecoration>();
        expect(
          decorations.map((decoration) => decoration.gradient),
          everyElement(isNull),
        );

        final slot = find.ancestor(
          of: card.slotContent,
          matching: decoratedBoxes,
        );
        final backing = tester.widget<DecoratedBox>(slot).decoration;
        expect(
          (backing as BoxDecoration).color,
          colorScheme.surfaceContainerHighest,
        );
      });
    }
  }
}
