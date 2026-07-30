// lib/database/help_dao.dart
part of 'database.dart';

@DriftAccessor(tables: [HelpCategories, HelpArticles])
class HelpDao extends DatabaseAccessor<AppDatabase> with _$HelpDaoMixin {
  final AppDatabase db;

  HelpDao(this.db) : super(db);

  // Categories for a locale, falling back to English per-slug when a localized
  // row is missing. Ordered by sortOrder.
  Future<List<HelpCategoryModel>> getCategories(String locale) async {
    final rows = await (select(
      helpCategories,
    )..where((t) => t.locale.isIn([locale, 'en']))).get();

    final bySlug = <String, HelpCategoryModel>{};
    for (final row in rows) {
      final model = HelpCategoryModel(
        slug: row.categorySlug,
        locale: row.locale,
        title: row.title,
        icon: row.icon,
        sortOrder: row.sortOrder,
      );
      final existing = bySlug[model.slug];
      if (existing == null ||
          (model.locale == locale && existing.locale != locale)) {
        bySlug[model.slug] = model;
      }
    }

    return bySlug.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  // Articles within a category for a locale, with English fallback per-slug.
  Future<List<HelpArticleModel>> getArticles(
    String categorySlug,
    String locale,
  ) async {
    final rows =
        await (select(helpArticles)..where(
              (t) =>
                  t.categorySlug.equals(categorySlug) &
                  t.locale.isIn([locale, 'en']),
            ))
            .get();

    final bySlug = <String, HelpArticleModel>{};
    for (final row in rows) {
      final model = _toArticleModel(row);
      final existing = bySlug[model.slug];
      if (existing == null ||
          (model.locale == locale && existing.locale != locale)) {
        bySlug[model.slug] = model;
      }
    }

    return bySlug.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  // All articles for a locale, falling back to English per-slug. Articles are
  // ordered by localized category order, then article order and slug.
  Future<List<HelpArticleModel>> getAllArticles(String locale) async {
    final articleRows = await (select(
      helpArticles,
    )..where((t) => t.locale.isIn([locale, 'en']))).get();
    final categoryRows = await (select(
      helpCategories,
    )..where((t) => t.locale.isIn([locale, 'en']))).get();

    final bySlug = <String, HelpArticleModel>{};
    for (final row in articleRows) {
      final model = _toArticleModel(row);
      final existing = bySlug[model.slug];
      if (existing == null ||
          (model.locale == locale && existing.locale != locale)) {
        bySlug[model.slug] = model;
      }
    }

    final categoryOrderBySlug = <String, ({String locale, int sortOrder})>{};
    for (final row in categoryRows) {
      final existing = categoryOrderBySlug[row.categorySlug];
      if (existing == null ||
          (row.locale == locale && existing.locale != locale)) {
        categoryOrderBySlug[row.categorySlug] = (
          locale: row.locale,
          sortOrder: row.sortOrder,
        );
      }
    }

    return bySlug.values.toList()..sort((a, b) {
      final categoryComparison =
          (categoryOrderBySlug[a.categorySlug]?.sortOrder ?? 0x7fffffff)
              .compareTo(
                categoryOrderBySlug[b.categorySlug]?.sortOrder ?? 0x7fffffff,
              );
      if (categoryComparison != 0) return categoryComparison;

      final categorySlugComparison = a.categorySlug.compareTo(b.categorySlug);
      if (categorySlugComparison != 0) return categorySlugComparison;

      final articleComparison = a.sortOrder.compareTo(b.sortOrder);
      if (articleComparison != 0) return articleComparison;

      return a.slug.compareTo(b.slug);
    });
  }

  // Searches the small, cached Help corpus in memory. Markdown syntax and link
  // destinations are excluded so matches reflect reader-visible text.
  List<HelpArticleModel> searchArticles(
    List<HelpArticleModel> articles,
    String query,
  ) {
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return articles;

    return articles.where((article) {
      final title = _normalizeSearchText(article.title);
      final body = _normalizeSearchText(_plainMarkdown(article.body));
      return title.contains(normalizedQuery) || body.contains(normalizedQuery);
    }).toList();
  }

  // A single article by slug, preferring the requested locale then English.
  Future<HelpArticleModel?> getArticle(String slug, String locale) async {
    final rows =
        await (select(helpArticles)..where(
              (t) => t.articleSlug.equals(slug) & t.locale.isIn([locale, 'en']),
            ))
            .get();
    if (rows.isEmpty) return null;
    final match = rows.firstWhere(
      (r) => r.locale == locale,
      orElse: () => rows.first,
    );
    return _toArticleModel(match);
  }

  // Server-authoritative refresh: clear and re-insert the cached help content.
  Future<void> replaceAll(
    List<HelpCategoriesCompanion> categories,
    List<HelpArticlesCompanion> articles,
  ) async {
    await transaction(() async {
      await delete(helpArticles).go();
      await delete(helpCategories).go();
      await batch((b) {
        b.insertAll(helpCategories, categories);
        b.insertAll(helpArticles, articles);
      });
    });
  }

  HelpArticleModel _toArticleModel(HelpArticle row) {
    return HelpArticleModel(
      slug: row.articleSlug,
      locale: row.locale,
      categorySlug: row.categorySlug,
      title: row.title,
      body: row.body,
      sortOrder: row.sortOrder,
    );
  }

  String _normalizeSearchText(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _plainMarkdown(String markdown) {
    return markdown
        .replaceAllMapped(
          RegExp(r'!\[([^\]]*)\]\((?:[^()]|\([^)]*\))+\)'),
          (match) => match.group(1) ?? '',
        )
        .replaceAllMapped(
          RegExp(r'\[([^\]]+)\]\((?:[^()]|\([^)]*\))+\)'),
          (match) => match.group(1) ?? '',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'[`*_~#>|]'), ' ')
        .replaceAll(RegExp(r'^\s*[-+]\s+', multiLine: true), ' ')
        .replaceAll(RegExp(r'^\s*\d+[.)]\s+', multiLine: true), ' ');
  }
}
