// lib/models/help_models.dart
class HelpCategoryModel {
  final String slug;
  final String locale;
  final String title;
  final String? icon;
  final int sortOrder;

  HelpCategoryModel({
    required this.slug,
    required this.locale,
    required this.title,
    this.icon,
    required this.sortOrder,
  });
}

class HelpArticleModel {
  final String slug;
  final String locale;
  final String categorySlug;
  final String title;
  final String body;
  final int sortOrder;

  HelpArticleModel({
    required this.slug,
    required this.locale,
    required this.categorySlug,
    required this.title,
    required this.body,
    required this.sortOrder,
  });
}
