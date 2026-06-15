import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coffee_timer/l10n/app_localizations.dart';

import '../app_router.gr.dart';
import '../models/help_models.dart';
import '../providers/database_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/app_logger.dart';
import '../widgets/base_buttons.dart';
import '../widgets/smart_back_button.dart';

@RoutePage()
class HelpHomeScreen extends StatefulWidget {
  const HelpHomeScreen({super.key});

  @override
  State<HelpHomeScreen> createState() => _HelpHomeScreenState();
}

class _HelpHomeScreenState extends State<HelpHomeScreen> {
  List<HelpCategoryModel> _categories = [];
  bool _loading = true;
  bool _failed = false;
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
    setState(() {
      _loading = true;
      _failed = false;
    });
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    final categories = await db.getHelpCategories(locale.languageCode);
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _loading = false;
    });
  }

  Future<void> _refresh(Locale locale) async {
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    try {
      await db.refreshHelpContent();
    } catch (e) {
      AppLogger.error('Help refresh failed', errorObject: AppLogger.sanitize(e));
      if (mounted) setState(() => _failed = true);
    }
    await _load(locale);
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
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.base),
          child: Text(l10n.helpHomeSubtitle,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        for (final category in _categories)
          ListTile(
            leading: Icon(_iconForCategory(category.icon),
                color: theme.colorScheme.primary),
            title: Text(category.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.router.push(
              HelpCategoryRoute(
                categorySlug: category.slug,
                title: category.title,
              ),
            ),
          ),
      ],
    );
  }

  IconData _iconForCategory(String? name) {
    switch (name) {
      case 'coffee':
        return Icons.coffee;
      case 'timer':
        return Icons.timer;
      case 'menu_book':
        return Icons.menu_book;
      case 'cloud_sync':
        return Icons.cloud_sync;
      case 'groups':
        return Icons.groups;
      default:
        return Icons.help_outline;
    }
  }
}
