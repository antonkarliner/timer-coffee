import 'dart:convert';

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/bean_review_model.dart';
import 'package:coffee_timer/models/brewing_method_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/bean_review_provider.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/manual_brew_entry_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';
import 'package:coffee_timer/widgets/roaster_profile/review_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'brew_flow_async_context_test.mocks.dart';

class _FakeBeanReviewProvider extends BeanReviewProvider {
  @override
  Future<List<BeanReviewModel>> fetchUserReviews() async => const [];
}

void main() {
  final method = BrewingMethodModel(
    brewingMethodId: 'v60',
    brewingMethod: 'V60',
  );
  late MockAppDatabase database;
  late MockCoffeeBeansProvider beans;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'hasShownPopup': true});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );
    final expiresAt = DateTime.now().add(const Duration(hours: 1));
    final claims = jsonEncode({
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
      'sub': 'test-user',
    });
    final payload = base64Url
        .encode(utf8.encode(claims))
        .replaceAll('=', '');
    final session = jsonEncode({
      'access_token': 'test.$payload.signature',
      'refresh_token': 'test-refresh-token',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': 'test-user',
        'aud': 'authenticated',
        'app_metadata': <String, dynamic>{},
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    });
    await Supabase.instance.client.auth.recoverSession(session);
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDownAll(() async {
    AnalyticsService.resetForTesting();
    await Supabase.instance.dispose();
  });

  setUp(() {
    database = MockAppDatabase();
    final methodsDao = MockBrewingMethodsDao();
    when(database.brewingMethodsDao).thenReturn(methodsDao);
    when(methodsDao.getAllBrewingMethods()).thenAnswer((_) async => [method]);
    beans = MockCoffeeBeansProvider();
  });

  Widget localizedApp(Widget home) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: home,
    );
  }

  Finder labeledField(String label) =>
      find.byWidgetPredicate((w) => w is LabeledField && w.label == label);

  Finder textFieldIn(Finder field) =>
      find.descendant(of: field, matching: find.byType(TextField));

  testWidgets('review fields keep their interactions', (tester) async {
    final reviews = _FakeBeanReviewProvider();
    addTearDown(reviews.dispose);
    when(beans.fetchAllCoffeeBeans()).thenAnswer((_) async => const []);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          ChangeNotifierProvider<CoffeeBeansProvider>.value(value: beans),
          ChangeNotifierProvider<BeanReviewProvider>.value(value: reviews),
        ],
        child: localizedApp(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    showReviewForm(context, roasterName: 'Test Roaster'),
                child: const Text('Open review'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    final l10n = AppLocalizations.of(tester.element(sheet))!;
    final reviewField = labeledField(l10n.reviewTextLabel);
    final pickerField = labeledField(l10n.reviewBrewMethodLabel);
    final review = tester.widget<LabeledField>(reviewField);
    final picker = tester.widget<LabeledField>(pickerField);
    expect(review.labelInsideField, isFalse);
    expect(picker.labelInsideField, isFalse);
    expect(picker.readOnly, isTrue);

    final inputs = find.descendant(
      of: sheet,
      matching: find.byWidgetPredicate(
        (w) => w is TextField || w is TextFormField,
      ),
    );
    expect(inputs, findsWidgets);
    for (final input in inputs.evaluate()) {
      expect(
        find.ancestor(
          of: find.byWidget(input.widget),
          matching: find.byType(LabeledField),
        ),
        findsOneWidget,
        reason: '${input.widget.runtimeType} should be inside a LabeledField',
      );
    }

    final pickerInput = textFieldIn(pickerField);
    await tester.ensureVisible(pickerInput);
    await tester.tap(pickerInput);
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(SimpleDialog, l10n.reviewBrewMethodLabel),
      findsOneWidget,
    );
    await tester.tap(
      find.widgetWithText(SimpleDialogOption, method.brewingMethod),
    );
    await tester.pumpAndSettle();
    expect(picker.controller!.text, method.brewingMethod);

    final reviewInput = textFieldIn(reviewField);
    await tester.ensureVisible(reviewInput);
    expect(
      tester.widget<TextField>(reviewInput).keyboardType,
      TextInputType.multiline,
    );
    await tester.enterText(reviewInput, 'Bright and sweet.');
    expect(review.controller!.text, 'Bright and sweet.');
  });

  testWidgets('manual amounts keep labels and validation', (tester) async {
    final recipes = MockRecipeProvider();
    final stats = MockUserStatProvider();
    final recipe = RecipeModel(
      id: 'recipe-1',
      name: 'Test recipe',
      brewingMethodId: method.brewingMethodId,
      coffeeAmount: 15,
      waterAmount: 250,
      grindSize: 'Medium',
      brewTime: const Duration(minutes: 3),
      shortDescription: '',
      steps: const [],
    );
    when(
      recipes.fetchRecipesForBrewingMethod(method.brewingMethodId),
    ).thenAnswer((_) async => [recipe]);
    when(stats.fetchAllDistinctTags()).thenAnswer((_) async => const []);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          ChangeNotifierProvider<RecipeProvider>.value(value: recipes),
          ChangeNotifierProvider<UserStatProvider>.value(value: stats),
          ChangeNotifierProvider<CoffeeBeansProvider>.value(value: beans),
          ChangeNotifierProvider<DateTimeFormatService>(
            create: (_) => DateTimeFormatService(),
          ),
        ],
        child: localizedApp(const ManualBrewEntryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final screen = find.byType(ManualBrewEntryScreen);
    final l10n = AppLocalizations.of(tester.element(screen))!;
    for (final (label, option) in [
      (l10n.selectBrewingMethod, method.brewingMethod),
      (l10n.selectRecipe, recipe.name),
    ]) {
      await tester.tap(
        find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, option));
      await tester.pumpAndSettle();
    }

    final form = tester.state<FormState>(find.byType(Form));
    for (final (label, value) in [
      (l10n.coffeeamount, '15,5'),
      (l10n.wateramount, '250,5'),
    ]) {
      final field = labeledField(label);
      expect(tester.widget<LabeledField>(field).labelInsideField, isTrue);
      await tester.enterText(textFieldIn(field), value);
    }
    final notes = tester.widget<LabeledField>(labeledField(l10n.notes));
    expect(notes.labelInsideField, isFalse);
    expect(form.validate(), isTrue);

    for (final label in [l10n.coffeeamount, l10n.wateramount]) {
      final field = labeledField(label);
      await tester.enterText(textFieldIn(field), '');
      expect(form.validate(), isFalse);
      final state = tester.state<FormFieldState<String>>(
        find.descendant(of: field, matching: find.byType(TextFormField)),
      );
      expect(state.errorText, label);
    }
  });
}
