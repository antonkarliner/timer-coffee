import 'dart:async';

import 'package:coffee_timer/controllers/coffee_beans_detail_controller.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/models/launch_popup_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/screens/coffee_beans_screen.dart';
import 'package:coffee_timer/screens/donation_screen.dart';
import 'package:coffee_timer/purchase_manager.dart';
import 'package:coffee_timer/services/bean_selection_service.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/widgets/add_coffee_beans_widget.dart';
import 'package:coffee_timer/widgets/autocomplete_tag_input_field.dart';
import 'package:coffee_timer/widgets/coffee_bean_details/coffee_beans_hero_header.dart';
import 'package:coffee_timer/widgets/coffee_bean_details/coffee_beans_info_card.dart';
import 'package:coffee_timer/widgets/coffee_beans/coffee_bean_card.dart';
import 'package:coffee_timer/widgets/coffee_beans/coffee_bean_grid_card.dart';
import 'package:coffee_timer/widgets/favorite_button.dart';
import 'package:coffee_timer/widgets/new_beans/image_flow/selected_images_sheet.dart';
import 'package:coffee_timer/widgets/launch_popup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/coffee_beans_controller_async_context_test.mocks.dart';
import 'recipe_screen_async_context_test.mocks.dart';
import 'widget_async_context_batch_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<CoffeeBeansDetailController>(),
  MockSpec<DatabaseProvider>(),
])
void main() {
  late CoffeeBeansModel bean;

  setUp(() {
    SharedPreferences.setMockInitialValues({'coffeeBeansGridView': false});
    bean = CoffeeBeansModel(
      beansUuid: 'bean-1',
      roaster: 'Test Roaster',
      name: 'Test Beans',
      origin: 'Test Origin',
      packageWeightGrams: 250,
      versionVector: '{}',
    );
  });

  Widget localizedApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('inventory update shows success while mounted', (tester) async {
    final detailController = MockCoffeeBeansDetailController();
    when(
      detailController.setPackageWeightToZero(any),
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CoffeeBeansDetailController>.value(
            value: detailController,
          ),
          ChangeNotifierProvider<DateTimeFormatService>.value(
            value: DateTimeFormatService(),
          ),
        ],
        child: localizedApp(
          CoffeeBeansInfoCard(
            type: CoffeeBeansInfoCardType.inventory,
            bean: bean,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set to zero').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set to zero').last);
    await tester.pumpAndSettle();

    expect(find.text('Inventory set to 0 g'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inventory update finishes safely after disposal', (
    tester,
  ) async {
    final update = Completer<bool>();
    final detailController = MockCoffeeBeansDetailController();
    when(
      detailController.setPackageWeightToZero(any),
    ).thenAnswer((_) => update.future);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CoffeeBeansDetailController>.value(
            value: detailController,
          ),
          ChangeNotifierProvider<DateTimeFormatService>.value(
            value: DateTimeFormatService(),
          ),
        ],
        child: localizedApp(
          CoffeeBeansInfoCard(
            type: CoffeeBeansInfoCardType.inventory,
            bean: bean,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set to zero').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set to zero').last);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    update.complete(true);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('favorite toggle stops safely after disposal', (tester) async {
    final recipeProvider = MockRecipeProvider();
    final toggle = Completer<void>();
    final recipe = RecipeModel(
      id: 'recipe-1',
      name: 'Test Recipe',
      brewingMethodId: 'v60',
      coffeeAmount: 15,
      waterAmount: 250,
      grindSize: 'Medium',
      brewTime: const Duration(minutes: 3),
      shortDescription: 'Test',
      steps: const [],
    );
    when(
      recipeProvider.getRecipeById(recipe.id),
    ).thenAnswer((_) async => recipe);
    when(
      recipeProvider.toggleFavorite(recipe.id),
    ).thenAnswer((_) => toggle.future);

    await tester.pumpWidget(
      ChangeNotifierProvider<RecipeProvider>.value(
        value: recipeProvider,
        child: localizedApp(FavoriteButton(recipeId: recipe.id)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    toggle.complete();
    await tester.pump();

    verify(recipeProvider.getRecipeById(recipe.id)).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('autocomplete delayed focus stops safely after disposal', (
    tester,
  ) async {
    List<String>? selected;
    await tester.pumpWidget(
      localizedApp(
        AutocompleteTagInputField(
          label: 'Tags',
          hintText: 'Add tag',
          initialOptions: Future.value(const ['berry']),
          onSelected: (values) => selected = values,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Berry');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 110));

    expect(selected, ['berry']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('image confirmation delay stops safely after disposal', (
    tester,
  ) async {
    var confirmed = false;
    await tester.pumpWidget(
      localizedApp(
        SelectedImagesSheet(
          initialImages: [XFile('/tmp/scan-photo.jpg')],
          onConfirm: (_) async => confirmed = true,
          onBackToSelection: () async {},
        ),
      ),
    );

    await tester.tap(find.text('Analyze photo'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 20));

    expect(confirmed, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('image confirmation result is ignored after disposal', (
    tester,
  ) async {
    final confirmation = Completer<void>();
    var confirmCalled = false;
    await tester.pumpWidget(
      localizedApp(
        SelectedImagesSheet(
          initialImages: [XFile('/tmp/scan-photo.jpg')],
          onConfirm: (_) {
            confirmCalled = true;
            return confirmation.future;
          },
          onBackToSelection: () async {},
        ),
      ),
    );

    await tester.tap(find.text('Analyze photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 11));
    expect(confirmCalled, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    confirmation.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('bean deletion finishes safely after screen disposal', (
    tester,
  ) async {
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    final databaseProvider = MockDatabaseProvider();
    final deletion = Completer<void>();
    when(
      databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster),
    ).thenAnswer((_) async => {'original': null, 'mirror': null});
    when(
      coffeeBeansProvider.fetchAllDistinctRoasters(),
    ).thenAnswer((_) async => ['Test Roaster']);
    when(
      coffeeBeansProvider.fetchAllDistinctOrigins(),
    ).thenAnswer((_) async => ['Test Origin']);
    when(
      coffeeBeansProvider.fetchFilteredCoffeeBeans(),
    ).thenAnswer((_) async => [bean]);
    when(
      coffeeBeansProvider.fetchAllCoffeeBeans(),
    ).thenAnswer((_) async => [bean]);
    when(
      coffeeBeansProvider.deleteCoffeeBeans(bean.beansUuid),
    ).thenAnswer((_) => deletion.future);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: coffeeBeansProvider,
          ),
          Provider<DatabaseProvider>.value(value: databaseProvider),
        ],
        child: localizedApp(const CoffeeBeansScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_note));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pump();
    verify(coffeeBeansProvider.deleteCoffeeBeans(bean.beansUuid)).called(1);

    await tester.pumpWidget(const SizedBox.shrink());
    deletion.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('bean favorite toggle finishes safely after screen disposal', (
    tester,
  ) async {
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    final databaseProvider = MockDatabaseProvider();
    final toggle = Completer<void>();
    when(
      databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster),
    ).thenAnswer((_) async => {'original': null, 'mirror': null});
    when(
      coffeeBeansProvider.fetchAllDistinctRoasters(),
    ).thenAnswer((_) async => ['Test Roaster']);
    when(
      coffeeBeansProvider.fetchAllDistinctOrigins(),
    ).thenAnswer((_) async => ['Test Origin']);
    when(
      coffeeBeansProvider.fetchFilteredCoffeeBeans(),
    ).thenAnswer((_) async => [bean]);
    when(
      coffeeBeansProvider.fetchAllCoffeeBeans(),
    ).thenAnswer((_) async => [bean]);
    when(
      coffeeBeansProvider.toggleFavoriteStatus(bean.beansUuid, true),
    ).thenAnswer((_) => toggle.future);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: coffeeBeansProvider,
          ),
          Provider<DatabaseProvider>.value(value: databaseProvider),
        ],
        child: localizedApp(const CoffeeBeansScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    toggle.complete();
    await tester.pump();

    verify(
      coffeeBeansProvider.toggleFavoriteStatus(bean.beansUuid, true),
    ).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected bean load survives host disposal', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selectedBeanUuid': bean.beansUuid,
    });
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    final databaseProvider = MockDatabaseProvider();
    final beanLookup = Completer<CoffeeBeansModel?>();
    when(
      coffeeBeansProvider.fetchCoffeeBeansByUuid(bean.beansUuid),
    ).thenAnswer((_) => beanLookup.future);
    when(databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster)).thenAnswer(
      (_) async => {'original': 'original.png', 'mirror': 'mirror.png'},
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: coffeeBeansProvider,
          ),
          Provider<DatabaseProvider>.value(value: databaseProvider),
        ],
        child: localizedApp(const SizedBox(key: Key('bean-selection-host'))),
      ),
    );
    final context = tester.element(
      find.byKey(const Key('bean-selection-host')),
    );

    final selection = const BeanSelectionService().loadSelectedBean(context);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    beanLookup.complete(bean);

    expect((await selection).uuid, bean.beansUuid);
    verify(databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster)).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing selected bean clears the persisted UUID', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'selectedBeanUuid': bean.beansUuid,
    });
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    final databaseProvider = MockDatabaseProvider();
    when(
      coffeeBeansProvider.fetchCoffeeBeansByUuid(bean.beansUuid),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: coffeeBeansProvider,
          ),
          Provider<DatabaseProvider>.value(value: databaseProvider),
        ],
        child: localizedApp(const SizedBox(key: Key('bean-selection-host'))),
      ),
    );
    final context = tester.element(
      find.byKey(const Key('bean-selection-host')),
    );

    final selection = await const BeanSelectionService().loadSelectedBean(
      context,
    );

    expect(selection.uuid, isNull);
    expect(
      (await SharedPreferences.getInstance()).containsKey('selectedBeanUuid'),
      isFalse,
    );
    verifyNever(databaseProvider.fetchCachedRoasterLogoUrls(any));
  });

  testWidgets('bean picker sorts by required UUID and returns selection', (
    tester,
  ) async {
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    final databaseProvider = MockDatabaseProvider();
    final beanA = bean.copyWith(beansUuid: 'bean-a', name: 'Bean A');
    final beanB = bean.copyWith(beansUuid: 'bean-b', name: 'Bean B');
    when(
      coffeeBeansProvider.fetchAllCoffeeBeans(),
    ).thenAnswer((_) async => [beanA, beanB]);
    when(
      databaseProvider.fetchCachedRoasterLogoUrls(any),
    ).thenAnswer((_) async => {'original': null, 'mirror': null});
    String? selectedUuid;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: coffeeBeansProvider,
          ),
          Provider<DatabaseProvider>.value(value: databaseProvider),
        ],
        child: localizedApp(
          AddCoffeeBeansWidget(onSelect: (uuid) => selectedUuid = uuid),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Bean B')).dy,
      lessThan(tester.getTopLeft(find.text('Bean A')).dy),
    );
    await tester.tap(find.text('Bean A'));
    await tester.pump();
    await tester.tap(find.text('Next'));

    expect(selectedUuid, 'bean-a');
  });

  testWidgets('bean cards forward the required UUID when favorited', (
    tester,
  ) async {
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    final databaseProvider = MockDatabaseProvider();
    when(
      coffeeBeansProvider.toggleFavoriteStatus(bean.beansUuid, true),
    ).thenAnswer((_) async {});
    when(
      databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster),
    ).thenAnswer((_) async => {'original': null, 'mirror': null});

    Widget host(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: coffeeBeansProvider,
          ),
          Provider<DatabaseProvider>.value(value: databaseProvider),
          ChangeNotifierProvider<DateTimeFormatService>.value(
            value: DateTimeFormatService(),
          ),
        ],
        child: localizedApp(child),
      );
    }

    await tester.pumpWidget(
      host(
        SizedBox(
          width: 500,
          height: 400,
          child: CoffeeBeanCard(
            bean: bean,
            isEditMode: false,
            onDelete: () {},
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    verify(
      coffeeBeansProvider.toggleFavoriteStatus(bean.beansUuid, true),
    ).called(1);
    clearInteractions(coffeeBeansProvider);

    await tester.pumpWidget(
      host(
        SizedBox(
          width: 350,
          height: 500,
          child: CoffeeBeanGridCard(
            bean: bean,
            isEditMode: false,
            onDelete: () {},
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    verify(
      coffeeBeansProvider.toggleFavoriteStatus(bean.beansUuid, true),
    ).called(1);
    clearInteractions(coffeeBeansProvider);

    await tester.pumpWidget(
      host(
        CoffeeBeansHeroHeader(
          bean: bean,
          coffeeBeansProvider: coffeeBeansProvider,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    verify(
      coffeeBeansProvider.toggleFavoriteStatus(bean.beansUuid, true),
    ).called(1);
  });

  testWidgets('selected bean update survives host disposal', (tester) async {
    final coffeeBeansProvider = MockCoffeeBeansProvider();
    final databaseProvider = MockDatabaseProvider();
    final beanLookup = Completer<CoffeeBeansModel?>();
    when(
      coffeeBeansProvider.fetchCoffeeBeansByUuid(bean.beansUuid),
    ).thenAnswer((_) => beanLookup.future);
    when(
      databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster),
    ).thenAnswer((_) async => {'original': null, 'mirror': null});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: coffeeBeansProvider,
          ),
          Provider<DatabaseProvider>.value(value: databaseProvider),
        ],
        child: localizedApp(const SizedBox(key: Key('bean-selection-host'))),
      ),
    );
    final context = tester.element(
      find.byKey(const Key('bean-selection-host')),
    );

    final selection = const BeanSelectionService().updateSelectedBean(
      context,
      bean.beansUuid,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    beanLookup.complete(bean);

    expect((await selection).name, bean.name);
    expect(tester.takeException(), isNull);
  });

  testWidgets('launch popup lookup completion is ignored after disposal', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'launch_popup_first_session_done': true,
    });
    final recipeProvider = MockRecipeProvider();
    final popupLookup = Completer<LaunchPopupModel?>();
    when(
      recipeProvider.fetchLatestLaunchPopup('en'),
    ).thenAnswer((_) => popupLookup.future);

    await tester.pumpWidget(
      ChangeNotifierProvider<RecipeProvider>.value(
        value: recipeProvider,
        child: localizedApp(LaunchPopupWidget()),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    popupLookup.complete(null);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('launch popup close persists the displayed popup id', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'launch_popup_first_session_done': true,
    });
    final recipeProvider = MockRecipeProvider();
    final popup = LaunchPopupModel(
      id: 42,
      content: 'Lifecycle-safe update',
      locale: 'en',
      createdAt: DateTime.utc(2026),
      platform: 'all',
    );
    when(
      recipeProvider.fetchLatestLaunchPopup('en'),
    ).thenAnswer((_) async => popup);

    await tester.pumpWidget(
      ChangeNotifierProvider<RecipeProvider>.value(
        value: recipeProvider,
        child: localizedApp(LaunchPopupWidget()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('lastPopupId_en'), 42);
    expect(tester.takeException(), isNull);
  });

  testWidgets('donation delivery callback stops after screen disposal', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(localizedApp(DonationScreen()));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
    final callback = PurchaseManager().onProductDelivered!;
    await tester.pumpWidget(const SizedBox.shrink());

    callback(
      PurchaseDetails(
        productID: 'tip_small_coffee',
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'test',
        ),
        transactionDate: null,
        status: PurchaseStatus.purchased,
      ),
    );
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('donation error callback stops after screen disposal', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(localizedApp(DonationScreen()));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
    final callback = PurchaseManager().onPurchaseError!;
    await tester.pumpWidget(const SizedBox.shrink());

    callback(IAPError(source: 'test', code: 'failed', message: 'Test failure'));
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
