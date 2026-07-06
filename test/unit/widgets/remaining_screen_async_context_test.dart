import 'dart:async';

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/models/supported_locale_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/snow_provider.dart';
import 'package:coffee_timer/providers/theme_provider.dart';
import 'package:coffee_timer/screens/settings_screen.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/collections_preferences_service.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'remaining_screen_async_context_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<RecipeProvider>(),
  MockSpec<AppDatabase>(),
  MockSpec<CoffeeBeansProvider>(),
  MockSpec<AnalyticsService>(),
])
void main() {
  late MockRecipeProvider recipeProvider;
  late MockAppDatabase database;
  late MockCoffeeBeansProvider coffeeBeansProvider;
  late MockAnalyticsService analytics;
  late ThemeProvider themeProvider;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    recipeProvider = MockRecipeProvider();
    database = MockAppDatabase();
    coffeeBeansProvider = MockCoffeeBeansProvider();
    analytics = MockAnalyticsService();
    themeProvider = ThemeProvider(ThemeMode.system);

    when(recipeProvider.recipes).thenReturn(const []);
    when(recipeProvider.currentLocale).thenReturn(const Locale('en'));
    when(
      recipeProvider.shownBrewingMethodIds,
    ).thenReturn(ValueNotifier<Set<String>>({}));
    when(
      recipeProvider.hiddenBrewingMethodIds,
    ).thenReturn(ValueNotifier<Set<String>>({}));
    when(recipeProvider.getLocaleName('en')).thenAnswer((_) async => 'English');
    when(analytics.brewsEnabled).thenReturn(true);
    when(analytics.beansEnabled).thenReturn(true);
    when(analytics.generalEnabled).thenReturn(true);
  });

  Widget buildSettings() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RecipeProvider>.value(value: recipeProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<SnowEffectProvider>(
          create: (_) => SnowEffectProvider(),
        ),
        Provider<List<BrewingMethodModel>>.value(value: const []),
        ChangeNotifierProvider<DateTimeFormatService>(
          create: (_) => DateTimeFormatService(),
        ),
        ChangeNotifierProvider<CollectionsPreferencesService>(
          create: (_) => CollectionsPreferencesService(),
        ),
        ChangeNotifierProvider<AdvancedFeaturesService>(
          create: (_) => AdvancedFeaturesService(),
        ),
        ChangeNotifierProvider<AnalyticsService>.value(value: analytics),
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<CoffeeBeansProvider>.value(
          value: coffeeBeansProvider,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const SettingsScreen(),
      ),
    );
  }

  testWidgets('theme selection applies the returned mode', (tester) async {
    when(
      recipeProvider.fetchAllSupportedLocales(),
    ).thenAnswer((_) async => const []);
    await tester.pumpWidget(buildSettings());
    await tester.pump();

    expect(find.text('System'), findsOneWidget);
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(themeProvider.themeMode, ThemeMode.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('locale loading completion is ignored after disposal', (
    tester,
  ) async {
    final locales = Completer<List<SupportedLocaleModel>>();
    when(
      recipeProvider.fetchAllSupportedLocales(),
    ).thenAnswer((_) => locales.future);
    await tester.pumpWidget(buildSettings());
    await tester.pump();

    await tester.tap(find.text('Language'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    locales.complete([
      SupportedLocaleModel(locale: 'en', localeName: 'English'),
    ]);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
