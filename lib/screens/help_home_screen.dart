import 'package:auto_route/auto_route.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coffee_timer/l10n/app_localizations.dart';

import '../app_router.gr.dart';
import '../models/help_models.dart';
import '../providers/database_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/app_logger.dart';
import '../widgets/base_buttons.dart';
import '../widgets/fields/labeled_field.dart';
import '../widgets/smart_back_button.dart';

@RoutePage()
class HelpHomeScreen extends StatefulWidget {
  const HelpHomeScreen({super.key});

  @override
  State<HelpHomeScreen> createState() => _HelpHomeScreenState();
}

class _HelpHomeScreenState extends State<HelpHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<HelpCategoryModel> _categories = [];
  List<HelpArticleModel> _articles = [];
  String _query = '';
  bool _loading = true;
  bool _failed = false;
  Locale? _lastLocale;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_lastLocale == null || _lastLocale != locale) {
      _lastLocale = locale;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(locale));
    }
  }

  Future<void> _load(Locale locale, {bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _failed = false;
        _categories = [];
        _articles = [];
      });
    }
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    try {
      final results = await Future.wait([
        db.getHelpCategories(locale.languageCode),
        db.getAllHelpArticles(locale.languageCode),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<HelpCategoryModel>;
        _articles = results[1] as List<HelpArticleModel>;
        _loading = false;
        _failed = false;
      });
    } catch (error) {
      AppLogger.error(
        'Help cache load failed',
        errorObject: AppLogger.sanitize(error),
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _refresh(Locale locale) async {
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    try {
      await db.refreshHelpContent();
      await _load(locale, showLoading: false);
    } catch (error) {
      AppLogger.error(
        'Help refresh failed',
        errorObject: AppLogger.sanitize(error),
      );
      if (!mounted) return;
      setState(() => _failed = _categories.isEmpty);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.helpLoadFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: const SmartBackButton(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.helpAndFAQ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(Localizations.localeOf(context)),
        child: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_categories.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            _failed ? l10n.helpLoadFailed : l10n.helpEmptyState,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.base),
          Center(
            child: AppElevatedButton(
              label: l10n.helpRetry,
              onPressed: () => _refresh(Localizations.localeOf(context)),
              isFullWidth: false,
              height: AppButton.heightSmall,
              padding: AppButton.paddingSmall,
            ),
          ),
        ],
      );
    }
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    final trimmedQuery = _query.trim();
    final results = trimmedQuery.isEmpty
        ? const <HelpArticleModel>[]
        : db.searchHelpArticles(_articles, trimmedQuery);
    final categoryTitles = {
      for (final category in _categories) category.slug: category.title,
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        AppSpacing.lg,
      ),
      children: [
        Text(
          l10n.helpHomeSubtitle,
          style: AppTextStyles.body.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        LabeledField(
          key: const ValueKey('helpSearchField'),
          controller: _searchController,
          label: l10n.helpSearchHint,
          hintText: l10n.helpSearchHint,
          semanticIdentifier: 'helpSearch',
          textInputAction: TextInputAction.search,
          textCapitalization: TextCapitalization.none,
          showClearButton: true,
          prefixIcon: const Icon(Icons.search, size: AppIconSize.medium),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (trimmedQuery.isNotEmpty) ...[
          Text(l10n.helpSearchResults, style: AppTextStyles.sectionHeader),
          const SizedBox(height: AppSpacing.sm),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                l10n.helpNoSearchResults,
                style: AppTextStyles.body.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final article in results)
              _HelpResultCard(
                article: article,
                categoryTitle:
                    categoryTitles[article.categorySlug] ??
                    article.categorySlug,
                semanticsLabel: l10n.helpOpenArticleInCategory(
                  article.title,
                  categoryTitles[article.categorySlug] ?? article.categorySlug,
                ),
                onTap: () => context.router.push(
                  HelpArticleRoute(slug: article.slug, title: article.title),
                ),
              ),
        ] else ...[
          Text(l10n.helpBrowseTopics, style: AppTextStyles.sectionHeader),
          const SizedBox(height: AppSpacing.sm),
          for (final category in _categories)
            _HelpCategoryCard(
              category: category,
              icon: _iconForCategory(category.icon),
              semanticsLabel: l10n.helpOpenCategory(category.title),
              onTap: () => context.router.push(
                HelpCategoryRoute(
                  categorySlug: category.slug,
                  title: category.title,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          _SupportCard(
            title: l10n.helpContactSupport,
            subtitle: l10n.helpContactSupportSubtitle,
            onTap: () => context.router.push(InfoRoute()),
          ),
        ],
      ],
    );
  }

  IconData _iconForCategory(String? name) {
    switch (name) {
      case 'coffee':
        return Icons.coffee;
      case 'coffee_maker':
        return Coffeico.coffee_maker;
      case 'bag_with_bean':
        return Coffeico.bag_with_bean;
      case 'library_books':
        return Icons.library_books;
      case 'bookmarks':
        return Icons.bookmarks_outlined;
      case 'bar_chart':
        return Icons.bar_chart;
      case 'settings':
        return Icons.settings;
      case 'report_problem':
        return Icons.report_problem_outlined;
      case 'timer':
        return Icons.timer;
      case 'menu_book':
        return Icons.menu_book;
      case 'cloud_sync':
        return Icons.cloud_sync;
      case 'groups':
        return Icons.groups;
      case 'rocket_launch':
        return Icons.rocket_launch_outlined;
      case 'history':
        return Icons.history;
      case 'insights':
        return Icons.insights_outlined;
      case 'tune':
        return Icons.tune;
      default:
        return Icons.help_outline;
    }
  }
}

class _HelpCategoryCard extends StatelessWidget {
  const _HelpCategoryCard({
    required this.category,
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
  });

  final HelpCategoryModel category;
  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Card(
          margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Row(
                children: [
                  Icon(icon, color: colors.primary, size: AppIconSize.large),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: Text(
                      category.title,
                      style: AppTextStyles.fieldLabel,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpResultCard extends StatelessWidget {
  const _HelpResultCard({
    required this.article,
    required this.categoryTitle,
    required this.semanticsLabel,
    required this.onTap,
  });

  final HelpArticleModel article;
  final String categoryTitle;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Card(
          margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(article.title, style: AppTextStyles.fieldLabel),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          categoryTitle,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ExcludeSemantics(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('helpContactSupport'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colors.primary,
                    size: AppIconSize.large,
                  ),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.fieldLabel),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
