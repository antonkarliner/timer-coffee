// lib/database/help_dao.dart
part of 'database.dart';

@DriftAccessor(tables: [HelpCategories, HelpArticles])
class HelpDao extends DatabaseAccessor<AppDatabase> with _$HelpDaoMixin {
  final AppDatabase db;

  HelpDao(this.db) : super(db);

  // Categories for a locale, falling back to English per-slug when a localized
  // row is missing. Ordered by sortOrder.
  Future<List<HelpCategoryModel>> getCategories(String locale) async {
    final rows = await (select(helpCategories)
          ..where((t) => t.locale.isIn([locale, 'en'])))
        .get();

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
      String categorySlug, String locale) async {
    final rows = await (select(helpArticles)
          ..where((t) =>
              t.categorySlug.equals(categorySlug) &
              t.locale.isIn([locale, 'en'])))
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

  // A single article by slug, preferring the requested locale then English.
  Future<HelpArticleModel?> getArticle(String slug, String locale) async {
    final rows = await (select(helpArticles)
          ..where((t) =>
              t.articleSlug.equals(slug) & t.locale.isIn([locale, 'en'])))
        .get();
    if (rows.isEmpty) return null;
    final match =
        rows.firstWhere((r) => r.locale == locale, orElse: () => rows.first);
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
}
