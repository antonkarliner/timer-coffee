import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/screens/account_screen.dart';
import 'package:coffee_timer/screens/favorite_recipes_screen.dart';
import 'package:coffee_timer/services/authentication_service.dart';
import 'package:coffee_timer/widgets/autocomplete_input_field.dart';
import 'package:coffee_timer/widgets/autocomplete_tag_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/recipe_screen_async_context_test.mocks.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  Widget localizedApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('autocomplete load failure uses the resolved localization', (
    tester,
  ) async {
    final options = Completer<List<String>>();

    await tester.pumpWidget(
      localizedApp(
        AutocompleteInputField(
          label: 'label',
          hintText: 'hint',
          initialOptions: options.future,
          onSelected: (_) {},
        ),
      ),
    );
    options.completeError(StateError('load failed'));
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(AutocompleteInputField)),
    )!;

    expect(find.text(l10n.failedToLoadData), findsOneWidget);
  });

  testWidgets('duplicate tag message uses the resolved localization', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        AutocompleteTagInputField(
          label: 'label',
          hintText: 'hint',
          initialOptions: Future.value(const ['berry']),
          initialValues: const ['berry'],
          onSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Berry');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(AutocompleteTagInputField)),
    )!;

    expect(find.text(l10n.tagAlreadyAdded('Berry')), findsOneWidget);
  });

  testWidgets('favorite recipe load failure uses the resolved localization', (
    tester,
  ) async {
    final recipeProvider = MockRecipeProvider();
    when(
      recipeProvider.fetchFavoriteRecipes(any),
    ).thenAnswer((_) async => throw StateError('load failed'));

    await tester.pumpWidget(
      ChangeNotifierProvider<RecipeProvider>.value(
        value: recipeProvider,
        child: localizedApp(FavoriteRecipesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(FavoriteRecipesScreen)),
    )!;

    expect(find.text(l10n.favoriteRecipesLoadFailed), findsOneWidget);
  });

  testWidgets('invalid email message uses the resolved localization', (
    tester,
  ) async {
    late BuildContext subjectContext;

    await tester.pumpWidget(
      localizedApp(
        Builder(
          builder: (context) {
            subjectContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    final l10n = AppLocalizations.of(subjectContext)!;
    await AuthenticationService.signInWithEmail(subjectContext, 'not-an-email');
    await tester.pump();

    expect(find.text(l10n.invalidEmailFormat), findsOneWidget);
  });

  testWidgets('account error state uses the resolved localization', (
    tester,
  ) async {
    await tester.pumpWidget(localizedApp(const AccountScreen(userId: '')));
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(AccountScreen)),
    )!;

    expect(find.text(l10n.account), findsOneWidget);
    expect(find.text(l10n.userNotFound), findsOneWidget);
  });
}
