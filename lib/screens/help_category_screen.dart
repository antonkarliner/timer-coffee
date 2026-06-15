import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coffee_timer/l10n/app_localizations.dart';

import '../app_router.gr.dart';
import '../models/help_models.dart';
import '../providers/database_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/base_buttons.dart';
import '../widgets/smart_back_button.dart';

@RoutePage()
class HelpCategoryScreen extends StatefulWidget {
  final String categorySlug;
  final String? title;

  const HelpCategoryScreen({
    super.key,
    @PathParam('categorySlug') required this.categorySlug,
    this.title,
  });

  @override
  State<HelpCategoryScreen> createState() => _HelpCategoryScreenState();
}

class _HelpCategoryScreenState extends State<HelpCategoryScreen> {
  List<HelpArticleModel> _articles = [];
  bool _loading = true;
  Locale? _lastLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_lastLocale == null || _lastLocale != locale) {
      _lastLocale = locale;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(locale));
    }
  }

  Future<void> _load(Locale locale) async {
    setState(() => _loading = true);
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    final articles =
        await db.getHelpArticles(widget.categorySlug, locale.languageCode);
    if (!mounted) return;
    setState(() {
      _articles = articles;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: const SmartBackButton(),
        title: Text(widget.title ?? l10n.helpAndFAQ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_articles.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.helpEmptyState,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.base),
          Center(
            child: AppElevatedButton(
              label: l10n.helpRetry,
              onPressed: () => _load(Localizations.localeOf(context)),
              isFullWidth: false,
              height: AppButton.heightSmall,
              padding: AppButton.paddingSmall,
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        for (final article in _articles)
          ListTile(
            title: Text(article.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.router.push(
              HelpArticleRoute(
                slug: article.slug,
                title: article.title,
              ),
            ),
          ),
      ],
    );
  }
}
