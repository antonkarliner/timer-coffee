import 'package:coffee_timer/database/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = openTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertCategory({
    required String slug,
    required String locale,
    required int sortOrder,
  }) {
    return db
        .into(db.helpCategories)
        .insert(
          HelpCategoriesCompanion.insert(
            categorySlug: slug,
            locale: locale,
            title: '$locale $slug',
            sortOrder: Value(sortOrder),
          ),
        );
  }

  Future<void> insertArticle({
    required String slug,
    required String locale,
    required String categorySlug,
    required String title,
    required String body,
    required int sortOrder,
  }) {
    return db
        .into(db.helpArticles)
        .insert(
          HelpArticlesCompanion.insert(
            articleSlug: slug,
            locale: locale,
            categorySlug: categorySlug,
            title: title,
            body: body,
            sortOrder: Value(sortOrder),
          ),
        );
  }

  group('getAllArticles', () {
    test(
      'prefers requested locale per slug and falls back to English',
      () async {
        await insertCategory(slug: 'start', locale: 'en', sortOrder: 1);
        await insertCategory(slug: 'start', locale: 'fr', sortOrder: 1);
        await insertArticle(
          slug: 'localized',
          locale: 'en',
          categorySlug: 'start',
          title: 'English title',
          body: 'English body',
          sortOrder: 1,
        );
        await insertArticle(
          slug: 'localized',
          locale: 'fr',
          categorySlug: 'start',
          title: 'Titre français',
          body: 'Corps français',
          sortOrder: 1,
        );
        await insertArticle(
          slug: 'english-only',
          locale: 'en',
          categorySlug: 'start',
          title: 'English fallback',
          body: 'Fallback body',
          sortOrder: 2,
        );

        final articles = await db.helpDao.getAllArticles('fr');

        expect(articles, hasLength(2));
        expect(articles.map((article) => article.slug), [
          'localized',
          'english-only',
        ]);
        expect(articles.first.locale, 'fr');
        expect(articles.first.title, 'Titre français');
        expect(articles.last.locale, 'en');
      },
    );

    test(
      'orders by category order, category slug, article order, then slug',
      () async {
        await insertCategory(slug: 'beans', locale: 'en', sortOrder: 1);
        await insertCategory(slug: 'community', locale: 'en', sortOrder: 0);
        await insertCategory(slug: 'diary', locale: 'en', sortOrder: 2);
        await insertCategory(slug: 'diary', locale: 'fr', sortOrder: 0);
        await insertArticle(
          slug: 'community',
          locale: 'en',
          categorySlug: 'community',
          title: 'Community',
          body: 'Body',
          sortOrder: 99,
        );
        await insertArticle(
          slug: 'z-diary',
          locale: 'en',
          categorySlug: 'diary',
          title: 'Diary Z',
          body: 'Body',
          sortOrder: 1,
        );
        await insertArticle(
          slug: 'a-diary',
          locale: 'en',
          categorySlug: 'diary',
          title: 'Diary A',
          body: 'Body',
          sortOrder: 1,
        );
        await insertArticle(
          slug: 'beans',
          locale: 'en',
          categorySlug: 'beans',
          title: 'Beans',
          body: 'Body',
          sortOrder: 0,
        );

        final articles = await db.helpDao.getAllArticles('fr');

        expect(articles.map((article) => article.slug), [
          'community',
          'a-diary',
          'z-diary',
          'beans',
        ]);
      },
    );
  });

  group('searchArticles', () {
    setUp(() async {
      await insertCategory(slug: 'start', locale: 'en', sortOrder: 1);
      await insertArticle(
        slug: 'timer',
        locale: 'en',
        categorySlug: 'start',
        title: 'Follow the Guided Timer',
        body: 'Use the timer one step at a time.',
        sortOrder: 1,
      );
      await insertArticle(
        slug: 'bloom',
        locale: 'en',
        categorySlug: 'start',
        title: 'Prepare your coffee',
        body: '''
## Technique

Pour **slowly**, then bloom
evenly. Read [guided steps](app://internal-route).
![Timer screen](https://example.com/timer.png)
''',
        sortOrder: 2,
      );
    });

    test('normalizes case and whitespace when matching titles', () async {
      final articles = await db.helpDao.getAllArticles('en');
      final results = db.helpDao.searchArticles(articles, '  GUIDED   timer ');

      expect(results.map((article) => article.slug), ['timer']);
    });

    test('matches reader-visible plain Markdown body text', () async {
      final articles = await db.helpDao.getAllArticles('en');
      final results = db.helpDao.searchArticles(articles, 'bloom evenly');

      expect(results.map((article) => article.slug), ['bloom']);
    });

    test('preserves visible link and image text', () async {
      final articles = await db.helpDao.getAllArticles('en');

      expect(
        db.helpDao
            .searchArticles(articles, 'guided steps')
            .map((article) => article.slug),
        ['bloom'],
      );
      expect(
        db.helpDao
            .searchArticles(articles, 'timer screen')
            .map((article) => article.slug),
        ['bloom'],
      );
    });

    test('does not match a Markdown link destination', () async {
      final articles = await db.helpDao.getAllArticles('en');
      final results = db.helpDao.searchArticles(articles, 'internal-route');

      expect(results, isEmpty);
    });

    test('returns the original list for a blank query', () async {
      final articles = await db.helpDao.getAllArticles('en');

      expect(db.helpDao.searchArticles(articles, '  \n '), same(articles));
    });

    test('returns no results for an unmatched query', () async {
      final articles = await db.helpDao.getAllArticles('en');

      expect(db.helpDao.searchArticles(articles, 'espresso pressure'), isEmpty);
    });
  });
}
