import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/help_models.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/screens/help_article_screen.dart';
import 'package:coffee_timer/screens/help_category_screen.dart';
import 'package:coffee_timer/screens/help_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late _FakeHelpProvider provider;
  late _RecordingStackRouter router;

  setUp(() {
    database = openTestDatabase();
    provider = _FakeHelpProvider(database);
    router = _RecordingStackRouter();
  });

  tearDown(() async {
    await database.close();
  });

  Widget harness(Widget screen) {
    return StackRouterScope(
      controller: router,
      stateHash: 0,
      child: Provider<DatabaseProvider>.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: screen,
        ),
      ),
    );
  }

  testWidgets('Help Home shows loading before cached task topics', (
    tester,
  ) async {
    final categories = Completer<List<HelpCategoryModel>>();
    provider.categoriesCompleter = categories;

    await tester.pumpWidget(harness(const HelpHomeScreen()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    categories.complete(provider.categories);
    await tester.pumpAndSettle();

    expect(find.text('Brewing with Timer.Coffee'), findsOneWidget);
    expect(find.text('Brew Diary & dialing in'), findsOneWidget);
    expect(find.byKey(const ValueKey('helpContactSupport')), findsOneWidget);
  });

  testWidgets('search matches titles and body with category context', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const HelpHomeScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(_searchInput(), 'guided timer');
    await tester.pump();

    expect(find.text('Follow the guided timer'), findsOneWidget);
    expect(find.text('Brewing with Timer.Coffee'), findsOneWidget);
    expect(find.text('Compare two brews'), findsNothing);

    await tester.enterText(_searchInput(), 'side by side');
    await tester.pump();

    expect(find.text('Compare two brews'), findsOneWidget);
    expect(find.text('Brew Diary & dialing in'), findsOneWidget);

    await tester.enterText(_searchInput(), 'pressure profiling');
    await tester.pump();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(HelpHomeScreen)),
    )!;
    expect(find.text(l10n.helpNoSearchResults), findsOneWidget);

    await tester.tap(_clearSearchButton());
    await tester.pump();

    expect(find.text('Brewing with Timer.Coffee'), findsOneWidget);
    expect(find.text(l10n.helpNoSearchResults), findsNothing);
  });

  testWidgets('failed refresh retains cached content and reports failure', (
    tester,
  ) async {
    provider.refreshError = StateError('offline');
    await tester.pumpWidget(harness(const HelpHomeScreen()));
    await tester.pumpAndSettle();

    final refresh = tester.state<RefreshIndicatorState>(
      find.byType(RefreshIndicator),
    );
    final refreshFuture = refresh.show();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await refreshFuture;
    await tester.pump();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HelpHomeScreen)),
    )!;
    expect(provider.refreshCalls, 1);
    expect(find.text('Brewing with Timer.Coffee'), findsOneWidget);
    expect(find.text(l10n.helpLoadFailed), findsOneWidget);
  });

  testWidgets('empty Help cache shows the localized retry state', (
    tester,
  ) async {
    provider.categories = [];
    provider.articles = [];

    await tester.pumpWidget(harness(const HelpHomeScreen()));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HelpHomeScreen)),
    )!;
    expect(find.text(l10n.helpEmptyState), findsOneWidget);
    expect(find.text(l10n.helpRetry), findsOneWidget);
  });

  testWidgets('Home actions push category, article, and support routes', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const HelpHomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Brewing with Timer.Coffee'));
    await tester.pump();
    expect(router.pushedRoute, isA<HelpCategoryRoute>());

    await tester.enterText(_searchInput(), 'guided timer');
    await tester.pump();
    await tester.tap(find.text('Follow the guided timer'));
    await tester.pump();
    expect(router.pushedRoute, isA<HelpArticleRoute>());

    await tester.tap(_clearSearchButton());
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('helpContactSupport')),
    );
    await tester.tap(find.byKey(const ValueKey('helpContactSupport')));
    await tester.pump();
    expect(router.pushedRoute, isA<InfoRoute>());
  });

  testWidgets('category cards push the selected article route', (tester) async {
    await tester.pumpWidget(
      harness(
        const HelpCategoryScreen(
          categorySlug: 'getting-started',
          title: 'Brewing with Timer.Coffee',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Follow the guided timer'));
    await tester.pump();

    expect(router.pushedRoute, isA<HelpArticleRoute>());
    expect(
      (router.pushedRoute! as HelpArticleRoute).args!.slug,
      'guided-timer',
    );
  });

  testWidgets('article screen renders cached Markdown content', (tester) async {
    await tester.pumpWidget(
      harness(
        const HelpArticleScreen(
          slug: 'guided-timer',
          title: 'Follow the guided timer',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Where to find it'), findsOneWidget);
    expect(find.textContaining('current step'), findsOneWidget);
  });
}

Finder _searchInput() {
  return find.descendant(
    of: find.byKey(const ValueKey('helpSearchField')),
    matching: find.byType(EditableText),
  );
}

Finder _clearSearchButton() {
  return find.descendant(
    of: find.byKey(const ValueKey('helpSearchField')),
    matching: find.byIcon(Icons.clear),
  );
}

class _FakeHelpProvider extends DatabaseProvider {
  _FakeHelpProvider(super.database);

  List<HelpCategoryModel> categories = [
    HelpCategoryModel(
      slug: 'getting-started',
      locale: 'en',
      title: 'Brewing with Timer.Coffee',
      icon: 'coffee_maker',
      sortOrder: 1,
    ),
    HelpCategoryModel(
      slug: 'diary',
      locale: 'en',
      title: 'Brew Diary & dialing in',
      icon: 'history',
      sortOrder: 2,
    ),
  ];

  List<HelpArticleModel> articles = [
    HelpArticleModel(
      slug: 'guided-timer',
      locale: 'en',
      categorySlug: 'getting-started',
      title: 'Follow the guided timer',
      body: '''
## Where to find it

Open a recipe and start brewing. The current step stays visible.
''',
      sortOrder: 1,
    ),
    HelpArticleModel(
      slug: 'compare-brews',
      locale: 'en',
      categorySlug: 'diary',
      title: 'Compare two brews',
      body: 'Compare dose and taste side by side.',
      sortOrder: 1,
    ),
  ];

  Completer<List<HelpCategoryModel>>? categoriesCompleter;
  Object? refreshError;
  int refreshCalls = 0;

  @override
  Future<List<HelpCategoryModel>> getHelpCategories(String locale) {
    return categoriesCompleter?.future ?? Future.value(categories);
  }

  @override
  Future<List<HelpArticleModel>> getAllHelpArticles(String locale) async {
    return articles;
  }

  @override
  Future<List<HelpArticleModel>> getHelpArticles(
    String categorySlug,
    String locale,
  ) async {
    return articles
        .where((article) => article.categorySlug == categorySlug)
        .toList();
  }

  @override
  Future<HelpArticleModel?> getHelpArticle(String slug, String locale) async {
    return articles.where((article) => article.slug == slug).firstOrNull;
  }

  @override
  List<HelpArticleModel> searchHelpArticles(
    List<HelpArticleModel> source,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    return source.where((article) {
      return article.title.toLowerCase().contains(normalized) ||
          article.body.toLowerCase().contains(normalized);
    }).toList();
  }

  @override
  Future<void> refreshHelpContent() async {
    refreshCalls++;
    if (refreshError case final error?) {
      throw error;
    }
  }
}

class _RecordingStackRouter extends Mock implements StackRouter {
  PageRouteInfo? pushedRoute;

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    pushedRoute = route;
    return null;
  }
}
