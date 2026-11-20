import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/controllers/stats_controller.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/beans_stats_provider.dart';
import '../widgets/app_bar_title.dart';
import '../widgets/smart_back_button.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/roaster_profile_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/services/stats_realtime_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:coffee_timer/widgets/settings/settings_list.dart';
import 'package:coffeico_plus/coffeico_plus.dart';
import 'package:coffee_timer/widgets/stats/time_period_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_router.gr.dart';
import 'package:coffee_timer/models/beans_stats_models.dart';
import 'package:coffee_timer/widgets/stats/beans_stat_list_card.dart';
import 'package:coffee_timer/widgets/stats/stats_row.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';
import '../services/onboarding_service.dart';

/// Custom plate widget for RoasterLogo with fixed-size background styling.
/// All plates are the same 1.5:1 rectangle so the list rows align uniformly.
class _StatsRoasterLogoPlate extends StatelessWidget {
  final String? originalUrl;
  final String? mirrorUrl;
  final IconData placeholderIcon;
  final double height;
  final double borderRadius;

  const _StatsRoasterLogoPlate({
    required this.originalUrl,
    required this.mirrorUrl,
    this.placeholderIcon = Coffeico.bag_with_bean,
    this.height = 48.0,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = originalUrl != null || mirrorUrl != null;
    final plateWidth = height * 1.5;

    return Container(
      width: plateWidth,
      height: height,
      decoration: BoxDecoration(
        color: hasLogo
            ? (Theme.of(context).brightness == Brightness.light
                  ? Colors.grey.shade400
                  : Colors.grey.shade700)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.hardEdge,
      child: hasLogo
          ? Padding(
              padding: const EdgeInsets.all(4.0),
              child: RoasterLogo(
                placeholderIcon: placeholderIcon,
                originalUrl: originalUrl,
                mirrorUrl: mirrorUrl,
                height: height - 8.0,
                width: plateWidth - 8.0,
                borderRadius: 4.0,
                forceFit: BoxFit.contain,
              ),
            )
          : Icon(
              placeholderIcon,
              size: height * 0.7,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
    );
  }
}

@RoutePage()
class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    @QueryParam('year') this.initialYear,
    @QueryParam('month') this.initialMonth,
    @QueryParam('start') this.initialStartDate,
    @QueryParam('end') this.initialEndDate,
  });

  final int? initialYear;
  final int? initialMonth;
  final String? initialStartDate;
  final String? initialEndDate;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final StatsController _controller;
  late final StatsRealtimeService _realtime;
  late final DatabaseProvider _db;

  @override
  void initState() {
    super.initState();
    _controller = StatsController();
    _realtime = StatsRealtimeService();

    // Safe to read providers with listen: false in initState
    final userStatProvider = Provider.of<UserStatProvider>(
      context,
      listen: false,
    );
    _db = Provider.of<DatabaseProvider>(context, listen: false);

    // Resolve the route range/month or pending weekly-notification period
    // before the first build can start personal/global range fetches.
    _controller.initializePeriod(
      userStatProvider,
      initialYear: widget.initialYear,
      initialMonth: widget.initialMonth,
      initialStartDate: widget.initialStartDate,
      initialEndDate: widget.initialEndDate,
    );

    // Initialize totals after first frame so the screen is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initial total
      await _refreshGlobalTotal();

      // Mark stats milestone for onboarding
      if (mounted) {
        Provider.of<OnboardingService>(
          context,
          listen: false,
        ).completeMilestoneStats();
      }

      // Start realtime updates
      _realtime.start(
        onEvent:
            ({
              required String recipeId,
              required DateTime createdAt,
              required double liters,
            }) {
              // Update total if event within current range
              _controller.addToTotalIfInRange(
                userStatProvider,
                createdAt,
                liters,
              );
              // Inform the user about a brew event
              _showRecipeBrewedSnackbar(recipeId);
            },
      );
    });
  }

  Future<void> _refreshGlobalTotal() async {
    final userStatProvider = Provider.of<UserStatProvider>(
      context,
      listen: false,
    );
    final start = _controller.getStartDate(userStatProvider);
    final end = _controller.getEndDate();
    final initial = await _db.fetchGlobalBrewedCoffeeAmountAggregated(
      start,
      end,
    );
    if (mounted) {
      _controller.setInitialTotal(initial);
    }
  }

  Future<void> _showRecipeBrewedSnackbar(String recipeId) async {
    if (!mounted) return;
    final ctx = context;
    final recipeName = await Provider.of<RecipeProvider>(
      ctx,
      listen: false,
    ).getLocalizedRecipeName(recipeId);

    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(ctx)!.someoneJustBrewed(recipeName)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        duration: const Duration(seconds: 10),
        showCloseIcon: true,
      ),
    );
  }

  @override
  void dispose() {
    _realtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          leading: const SmartBackButton(),
          title: AppBarTitle(
            text: l10n.brewStats,
            icon: Icons.bar_chart,
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    AppSpacing.base,
                    AppSpacing.base,
                    AppSpacing.lg,
                  ),
                  child: StatsTimePeriodSelector(
                    onChanged: _refreshGlobalTotal,
                  ),
                ),

                SettingsSectionHeader(title: l10n.yourStats),
                _YourStatsSection(onOpenRecipe: _openRecipeDetail),
                const SizedBox(height: AppSpacing.sectionGap),
                SettingsSectionHeader(title: l10n.beansStatsSectionTitle),
                const _BeansStatsSection(),
                const SizedBox(height: AppSpacing.sectionGap),
                SettingsSectionHeader(title: l10n.globalStats),
                _GlobalStatsSection(onOpenRecipe: _openRecipeDetail),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openRecipeDetail(RecipeModel recipe) {
    if (!mounted) return;
    context.router.push(
      RecipeDetailRoute(
        brewingMethodId: recipe.brewingMethodId,
        recipeId: recipe.id,
      ),
    );
  }
}

class _YourStatsSection extends StatelessWidget {
  const _YourStatsSection({required this.onOpenRecipe});

  final ValueChanged<RecipeModel> onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<StatsController>();
    final provider = context.read<UserStatProvider>();
    final startDate = controller.getStartDate(provider);
    final endDate = controller.getEndDate();

    return _StatsGroup(
      prefix: 'yours',
      coffeeRow: FutureBuilder<double>(
        future: provider.fetchBrewedCoffeeAmountForPeriod(startDate, endDate),
        builder: (context, snapshot) {
          final liters = (snapshot.data ?? 0) / 1000.0;
          return StatsRow(
            identifier: 'yours_statsRow_coffeeBrewed',
            icon: Coffeico.coffee_maker,
            label: l10n.statsCoffeeBrewedLabel,
            value: snapshot.hasError
                ? l10n.noData
                : '${liters.toStringAsFixed(2)} ${l10n.litersUnit}',
            mutedValue: snapshot.hasError || liters == 0,
            isLoading: snapshot.connectionState != ConnectionState.done,
          );
        },
      ),
      topRecipes: provider.fetchTopRecipesWithCountsForPeriod(startDate, endDate),
      onOpenRecipe: onOpenRecipe,
    );
  }
}

class _BeansStatsSection extends StatelessWidget {
  const _BeansStatsSection();

  /// Navigates to the roaster profile page if an active profile exists.
  Future<void> _navigateToRoasterProfile(
    BuildContext context,
    String roasterName,
  ) async {
    final provider = Provider.of<RoasterProfileProvider>(
      context,
      listen: false,
    );
    final slug = await provider.fetchRoasterSlugByName(roasterName);
    if (!context.mounted) return;
    if (slug != null) {
      context.router.push(RoasterProfileRoute(slug: slug));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<StatsController>();
    final userStatProvider = Provider.of<UserStatProvider>(
      context,
      listen: false,
    );
    final startDate = controller.getStartDate(userStatProvider);
    final endDate = controller.getEndDate();

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.base,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          identifier: 'statsGroup_beans',
          explicitChildNodes: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BeansStatRow<BeanUsage>(
                identifier: 'statsBeans_total',
                icon: Coffeico.bag_with_bean,
                label: l10n.totalBeansBrewedLabel,
                countFuture: (ctx) => Provider.of<BeansStatsProvider>(
                  ctx,
                  listen: false,
                ).getTotalBeansBrewedCount(startDate, endDate),
                fullListFuture: (ctx) => Provider.of<BeansStatsProvider>(
                  ctx,
                  listen: false,
                ).getTopBeansFull(startDate, endDate, limit: 999),
                itemBuilder: (ctx, bean) => InkWell(
                  onTap: () => context.router.push(
                    CoffeeBeansDetailRoute(uuid: bean.beansUuid),
                  ),
                  child: Row(
                    children: [
                      FutureBuilder<Map<String, String?>>(
                        future: Provider.of<DatabaseProvider>(
                          ctx,
                          listen: false,
                        ).fetchCachedRoasterLogoUrls(bean.roaster),
                        builder: (ctx2, snap) {
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 48,
                              width: 72,
                              child: Center(
                                child: SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          if (snap.hasData) {
                            final originalUrl = snap.data!['original'];
                            final mirrorUrl = snap.data!['mirror'];
                            if (originalUrl != null || mirrorUrl != null) {
                              return _StatsRoasterLogoPlate(
                                originalUrl: originalUrl,
                                mirrorUrl: mirrorUrl,
                                height: 48,
                                borderRadius: AppRadius.small,
                              );
                            }
                          }
                          final iconColor = Theme.of(ctx2).colorScheme.outline;
                          return Icon(
                            Coffeico.bag_with_bean,
                            size: 48,
                            color: iconColor,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          bean.name,
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                emptyText: l10n.noData,
              ),
              const StatsRowDivider(),
              BeansStatRow<BeanUsage>(
                identifier: 'statsBeans_new',
                icon: Coffeico.bean,
                label: l10n.newBeansTriedLabel,
                countFuture: (ctx) => Provider.of<BeansStatsProvider>(
                  ctx,
                  listen: false,
                ).getNewBeansTriedCount(startDate, endDate),
                fullListFuture: (ctx) => Provider.of<BeansStatsProvider>(
                  ctx,
                  listen: false,
                ).getNewBeansList(startDate, endDate, limit: 999),
                itemBuilder: (ctx, bean) => InkWell(
                  onTap: () => context.router.push(
                    CoffeeBeansDetailRoute(uuid: bean.beansUuid),
                  ),
                  child: Row(
                    children: [
                      FutureBuilder<Map<String, String?>>(
                        future: Provider.of<DatabaseProvider>(
                          ctx,
                          listen: false,
                        ).fetchCachedRoasterLogoUrls(bean.roaster),
                        builder: (ctx2, snap) {
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 48,
                              width: 72,
                              child: Center(
                                child: SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          if (snap.hasData) {
                            final originalUrl = snap.data!['original'];
                            final mirrorUrl = snap.data!['mirror'];
                            if (originalUrl != null || mirrorUrl != null) {
                              return _StatsRoasterLogoPlate(
                                originalUrl: originalUrl,
                                mirrorUrl: mirrorUrl,
                                height: 48,
                                borderRadius: AppRadius.small,
                              );
                            }
                          }
                          final iconColor = Theme.of(ctx2).colorScheme.outline;
                          return Icon(
                            Coffeico.bag_with_bean,
                            size: 48,
                            color: iconColor,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          bean.name,
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                emptyText: l10n.noData,
              ),
              const StatsRowDivider(),
              BeansStatRow<String>(
                identifier: 'statsBeans_origins',
                icon: Icons.public,
                label: l10n.originsExploredLabel,
                countFuture: (ctx) => Provider.of<BeansStatsProvider>(
                  ctx,
                  listen: false,
                ).getOriginsExploredCount(startDate, endDate),
                fullListFuture: (ctx) => Provider.of<BeansStatsProvider>(
                  ctx,
                  listen: false,
                ).getDistinctOriginsList(startDate, endDate, limit: 999),
                itemBuilder: (ctx, origin) => Row(
                  children: [
                    const Icon(Icons.public, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(origin, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                emptyText: l10n.noData,
              ),
              const StatsRowDivider(),
              BeansStatRow<String>(
                identifier: 'statsBeans_regions',
                icon: Icons.place,
                label: l10n.regionsExploredLabel,
                countFuture: (ctx) => Provider.of<BeansStatsProvider>(
                  ctx,
                  listen: false,
                ).getRegionsExploredCount(startDate, endDate),
                fullListFuture: (ctx) => Provider.of<BeansStatsProvider>(
                  ctx,
                  listen: false,
                ).getDistinctRegionsList(startDate, endDate, limit: 999),
                itemBuilder: (ctx, region) => Row(
                  children: [
                    const Icon(Icons.place, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(region, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                emptyText: l10n.noData,
              ),
              const StatsRowDivider(),
              BeansStatRow<String>(
                identifier: 'statsBeans_roasters',
                icon: Icons.storefront_outlined,
                label: l10n.newRoastersDiscoveredLabel,
                countFuture: (ctx) => Provider.of<BeansStatsProvider>(
                  ctx,
                  listen: false,
                ).getNewRoastersDiscovered(startDate, endDate),
                fullListFuture: (ctx) =>
                    Provider.of<BeansStatsProvider>(
                      ctx,
                      listen: false,
                    ).getNewRoastersDiscoveredList(
                      startDate,
                      endDate,
                      limit: 999,
                    ),
                itemBuilder: (ctx, roaster) => InkWell(
                  onTap: () => _navigateToRoasterProfile(context, roaster),
                  child: Row(
                    children: [
                      FutureBuilder<Map<String, String?>>(
                        future: Provider.of<DatabaseProvider>(
                          ctx,
                          listen: false,
                        ).fetchCachedRoasterLogoUrls(roaster),
                        builder: (ctx2, snap) {
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 40,
                              width: 40,
                              child: Center(
                                child: SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          if (snap.hasData) {
                            final originalUrl = snap.data!['original'];
                            final mirrorUrl = snap.data!['mirror'];
                            if (originalUrl != null || mirrorUrl != null) {
                              return _StatsRoasterLogoPlate(
                                placeholderIcon: Icons.storefront_outlined,
                                originalUrl: originalUrl,
                                mirrorUrl: mirrorUrl,
                                height: 40,
                                borderRadius: AppRadius.small,
                              );
                            }
                          }
                          final iconColor = Theme.of(ctx2).colorScheme.outline;
                          return Icon(
                            Icons.storefront_outlined,
                            size: 40,
                            color: iconColor,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          roaster,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                emptyText: l10n.noData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalStatsSection extends StatelessWidget {
  const _GlobalStatsSection({required this.onOpenRecipe});

  final ValueChanged<RecipeModel> onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<StatsController>();
    final provider = context.read<UserStatProvider>();
    final startDate = controller.getStartDate(provider);
    final endDate = controller.getEndDate();
    final db = context.read<DatabaseProvider>();
    final liters = controller.totalGlobalCoffeeBrewed;

    return _StatsGroup(
      prefix: 'global',
      coffeeRow: StatsRow(
        identifier: 'global_statsRow_coffeeBrewed',
        icon: Coffeico.coffee_maker,
        label: l10n.statsCoffeeBrewedLabel,
        value: '${liters.toStringAsFixed(2)} ${l10n.litersUnit}',
        mutedValue: liters == 0,
      ),
      topRecipes: db
          .fetchGlobalTopRecipesAggregated(startDate, endDate)
          .then((ids) => [for (final id in ids) (recipeId: id, count: null)]),
      onOpenRecipe: onOpenRecipe,
    );
  }
}

class _StatsGroup extends StatelessWidget {
  const _StatsGroup({
    required this.prefix,
    required this.coffeeRow,
    required this.topRecipes,
    required this.onOpenRecipe,
  });

  final String prefix;
  final Widget coffeeRow;
  final Future<List<({String recipeId, int? count})>> topRecipes;
  final ValueChanged<RecipeModel> onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.base,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          identifier: 'statsGroup_$prefix',
          explicitChildNodes: true,
          child: FutureBuilder(
            future: topRecipes,
            builder: (context, snapshot) {
              final loading = snapshot.connectionState != ConnectionState.done;
              final recipes = loading ? null : snapshot.data;
              final hasRecipes = recipes != null && recipes.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  coffeeRow,
                  const StatsRowDivider(),
                  StatsRow(
                    identifier: '${prefix}_statsRow_mostUsedRecipes',
                    icon: Coffeico.menu,
                    label: l10n.statsMostUsedRecipesLabel,
                    value: hasRecipes ? null : l10n.noData,
                    mutedValue: true,
                    isLoading: loading,
                  ),
                  if (recipes != null)
                    for (final (index, entry) in recipes.indexed) ...[
                      const StatsRowDivider(),
                      FutureBuilder<RecipeModel?>(
                        future: context
                            .read<RecipeProvider>()
                            .getRecipeById(entry.recipeId),
                        builder: (context, recipeSnapshot) {
                          final isLoading = recipeSnapshot.connectionState !=
                              ConnectionState.done;
                          final recipe = isLoading ? null : recipeSnapshot.data;
                          final icon = getIconByBrewingMethod(
                            recipe?.brewingMethodId,
                          );
                          return StatsRow(
                            identifier: '${prefix}_statsRecipe_$index',
                            icon: icon.icon!,
                            label: isLoading
                                ? ''
                                : recipe?.name ?? l10n.unknownRecipe,
                            value: entry.count?.toString(),
                            mutedValue: true,
                            isLoading: isLoading,
                            isRecipe: true,
                            onTap: recipe == null
                                ? null
                                : () => onOpenRecipe(recipe),
                          );
                        },
                      ),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
