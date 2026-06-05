import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/recipe_collection_provider.dart';
import '../providers/recipe_provider.dart';
import '../services/analytics_service.dart';
import '../services/collections_preferences_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/base_buttons.dart';
import 'collection_card.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

/// Collections section shown on the Brewing Methods home: a localized
/// "Collections" header with collapse/dismiss controls, and a horizontal
/// snap-carousel of [CollectionCard]s. The entire section auto-hides when
/// no collections have synced yet, when the user collapses it (header
/// stays), or when the user dismisses it (re-enable from Settings).
class CollectionsCarousel extends StatefulWidget {
  const CollectionsCarousel({super.key});

  @override
  State<CollectionsCarousel> createState() => _CollectionsCarouselState();
}

class _CollectionsCarouselState extends State<CollectionsCarousel> {
  static const double _carouselHeight = 124.0;
  static const double _viewportFraction = 0.9;

  late final PageController _controller;
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: _viewportFraction);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmDismiss(
    BuildContext context,
    int collectionCount,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = context.read<CollectionsPreferencesService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          title: Text(l10n.collectionsHideDialogTitle),
          content: Text(l10n.collectionsHideDialogContent),
          actions: [
            AppTextButton(
              label: l10n.cancel,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              isFullWidth: false,
              height: AppButton.heightSmall,
              padding: AppButton.paddingSmall,
            ),
            AppElevatedButton(
              label: l10n.collectionsHideDialogConfirm,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              isFullWidth: false,
              height: AppButton.heightSmall,
              padding: AppButton.paddingSmall,
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      AnalyticsService.instance.track(
        'collections_visibility_changed',
        properties: {
          'visible': false,
          'source': 'home_carousel',
          'collection_count': collectionCount,
        },
      );
      await prefs.setDismissed(true);
    }
  }

  Future<void> _toggleCollapsed(
    CollectionsPreferencesService prefs,
    bool collapsed,
    int collectionCount,
  ) async {
    final nextCollapsed = !collapsed;
    AnalyticsService.instance.track(
      'collections_section_toggled',
      properties: {
        'collapsed': nextCollapsed,
        'collection_count': collectionCount,
      },
    );
    await prefs.setCollapsed(nextCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<CollectionsPreferencesService>();
    if (prefs.dismissed) return const SizedBox.shrink();

    // Watch the locale so we re-fetch when the user changes language.
    final locale = context.watch<RecipeProvider>().currentLocale.languageCode;
    if (locale != _lastLocale) {
      _lastLocale = locale;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<RecipeCollectionProvider>().fetchAll(locale);
      });
    }

    final collections = context.watch<RecipeCollectionProvider>().collections;
    if (collections.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final collapsed = prefs.collapsed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          identifier: 'collectionsHeader',
          button: true,
          child: InkWell(
            onTap: () => _toggleCollapsed(prefs, collapsed, collections.length),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.sm,
                0,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  const Icon(Coffeico.menu),
                  const SizedBox(width: AppSpacing.base),
                  Flexible(
                    child: Text(
                      l10n.collectionsTitle,
                      // Match the brewing-method ListTile titles further down
                      // the screen: bodyLarge + w600.
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: collapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: AppIconSize.medium,
                      color: theme.colorScheme.onSurfaceVariant,
                      semanticLabel: collapsed
                          ? l10n.collectionsExpandTooltip
                          : l10n.collectionsCollapseTooltip,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.collectionsHideTooltip,
                    icon: const Icon(Icons.close),
                    iconSize: AppIconSize.medium,
                    // Asymmetric padding so the icon's right edge lines up
                    // with the divider's endIndent (AppSpacing.base) below.
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.base,
                      AppSpacing.sm,
                    ),
                    onPressed: () =>
                        _confirmDismiss(context, collections.length),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: collapsed
              ? const SizedBox(width: double.infinity)
              : SizedBox(
                  height: _carouselHeight,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: collections.length,
                    padEnds: false,
                    itemBuilder: (context, index) {
                      final isFirst = index == 0;
                      final isLast = index == collections.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(
                          left: isFirst ? AppSpacing.base : AppSpacing.xs,
                          right: isLast ? AppSpacing.base : AppSpacing.xs,
                        ),
                        child: CollectionCard(
                          collection: collections[index],
                          cardIndex: index,
                          collectionCount: collections.length,
                        ),
                      );
                    },
                  ),
                ),
        ),
        // Section separator below the carousel (matches the divider further
        // down the screen, beneath the quick-actions band).
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Divider(
            color: theme.dividerColor.withAlpha((255 * 0.3).round()),
            thickness: 0.7,
            height: 0,
            indent: AppSpacing.base,
            endIndent: AppSpacing.base,
          ),
        ),
      ],
    );
  }
}
