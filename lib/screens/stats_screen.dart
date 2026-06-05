import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/controllers/stats_controller.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/beans_stats_provider.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/services/stats_realtime_service.dart';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:coffee_timer/widgets/account_avatar_inline.dart';
import 'package:coffeico/coffeico.dart';
import 'package:coffee_timer/widgets/stats/time_period_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_router.gr.dart';
import 'package:coffee_timer/models/beans_stats_models.dart';
import 'package:coffee_timer/widgets/stats/beans_stat_list_card.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';
import '../services/onboarding_service.dart';

/// Custom plate widget for RoasterLogo with fixed-size background styling.
/// All plates are the same 1.5:1 rectangle so the list rows align uniformly.
class _StatsRoasterLogoPlate extends StatelessWidget {
  final String? originalUrl;
  final String? mirrorUrl;
  final double height;
  final double borderRadius;

  const _StatsRoasterLogoPlate({
    super.key,
    required this.originalUrl,
    required this.mirrorUrl,
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
                originalUrl: originalUrl,
                mirrorUrl: mirrorUrl,
                height: height - 8.0,
                width: plateWidth - 8.0,
                borderRadius: 4.0,
                forceFit: BoxFit.contain,
              ),
            )
          : Icon(
              Coffeico.bag_with_bean,
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
  const StatsScreen({super.key});

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

    // Apply pending initial period from deep link (e.g. weekly summary notification)
    if (StatsController.pendingInitialPeriod != null) {
      _controller.selectedPeriod = StatsController.pendingInitialPeriod!;
      StatsController.pendingInitialPeriod = null;
    }

    // Safe to read providers with listen: false in initState
    _db = Provider.of<DatabaseProvider>(context, listen: false);

    // Initialize default period and totals after first frame so providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userStatProvider = Provider.of<UserStatProvider>(
        context,
        listen: false,
      );

      // Ensure default window and includesToday are set
      _controller.selectPeriod(userStatProvider, _controller.selectedPeriod);

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

    if (!mounted) return;
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
          leading: const BackButton(),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bar_chart),
              const SizedBox(width: 8),
              Text(l10n.brewStats),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with time period selector
                Padding(
                  padding: const EdgeInsets.fromLTRB(32.0, 16.0, 16.0, 16.0),
                  child: Row(
                    children: [
                      Text(l10n.statsFor, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 260),
                              child: StatsTimePeriodSelector(
                                onChanged: _refreshGlobalTotal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Your stats section (personal)
                _YourStatsSection(onOpenRecipe: _openRecipeDetail),

                // Global stats section
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

  final void Function(RecipeModel recipe) onOpenRecipe;

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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AccountAvatarInline(size: 24),
                  const SizedBox(width: 8),
                  Text(
                    l10n.yourStats,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Brew Stats (personal)
              Text(
                l10n.brewStats,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Coffee Brewed (personal) - card.
              Card(
                elevation: 0.5,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.coffeeBrewed,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FutureBuilder<double>(
                              future: userStatProvider
                                  .fetchBrewedCoffeeAmountForPeriod(
                                    startDate,
                                    endDate,
                                  ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  if (snapshot.hasError) {
                                    return Text(
                                      l10n.noData,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                    );
                                  } else if (snapshot.hasData) {
                                    final liters =
                                        (snapshot.data ?? 0) / 1000.0;
                                    return Text(
                                      '${liters.toStringAsFixed(2)} ${l10n.litersUnit}',
                                    );
                                  }
                                }
                                return const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              // Most Used Recipes (personal) - card
              Card(
                elevation: 0.5,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mostUsedRecipes,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<String>>(
                        future: userStatProvider.fetchTopRecipeIdsForPeriod(
                          startDate,
                          endDate,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            if (snapshot.hasError) {
                              return Text(
                                l10n.noData,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                              );
                            }
                            final ids = snapshot.data ?? const <String>[];
                            if (ids.isEmpty) {
                              return Text(l10n.noData);
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: ids
                                  .map(
                                    (id) => FutureBuilder<RecipeModel?>(
                                      future: Provider.of<RecipeProvider>(
                                        context,
                                        listen: false,
                                      ).getRecipeById(id),
                                      builder: (context, recipeSnapshot) {
                                        if (recipeSnapshot.connectionState ==
                                            ConnectionState.done) {
                                          final recipe = recipeSnapshot.data;
                                          if (recipe != null) {
                                            final icon = getIconByBrewingMethod(
                                              recipe.brewingMethodId,
                                            );
                                            return InkWell(
                                              onTap: () => onOpenRecipe(recipe),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4.0,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    icon,
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: Text(
                                                        recipe.name,
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .secondary,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }
                                          return Text(l10n.unknownRecipe);
                                        }
                                        return const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                  .toList(),
                            );
                          }
                          return const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Beans quick tiles (replaced with capped preview + show more modals)
              Text(
                l10n.beansStatsSectionTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Total Beans Brewed
                  BeansStatListCard<BeanUsage>(
                    label: l10n.totalBeansBrewedLabel,
                    leadingIcon: const Icon(Coffeico.bag_with_bean),
                    countFuture: (ctx) => Provider.of<BeansStatsProvider>(
                      ctx,
                      listen: false,
                    ).getTotalBeansBrewedCount(startDate, endDate),
                    previewListFuture: (ctx) => Provider.of<BeansStatsProvider>(
                      ctx,
                      listen: false,
                    ).getTopBeansFull(startDate, endDate, limit: 10),
                    fullListFuture: (ctx) => Provider.of<BeansStatsProvider>(
                      ctx,
                      listen: false,
                    ).getTopBeansFull(startDate, endDate, limit: 999),
                    itemBuilder: (ctx, bean, {isPreview = false}) => InkWell(
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
                                return SizedBox(
                                  height: isPreview ? 28 : 48,
                                  width: isPreview ? 42 : 72,
                                  child: const Center(
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
                                    height: isPreview ? 28 : 48,
                                    borderRadius: 8.0,
                                  );
                                }
                              }
                              final iconColor = Theme.of(ctx2)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha((255 * 0.6).round());
                              return Icon(
                                Coffeico.bag_with_bean,
                                size: isPreview ? 28 : 48,
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

                  // New Beans Tried
                  BeansStatListCard<BeanUsage>(
                    label: l10n.newBeansTriedLabel,
                    leadingIcon: const Icon(Icons.fiber_new),
                    countFuture: (ctx) => Provider.of<BeansStatsProvider>(
                      ctx,
                      listen: false,
                    ).getNewBeansTriedCount(startDate, endDate),
                    previewListFuture: (ctx) => Provider.of<BeansStatsProvider>(
                      ctx,
                      listen: false,
                    ).getNewBeansList(startDate, endDate, limit: 10),
                    fullListFuture: (ctx) => Provider.of<BeansStatsProvider>(
                      ctx,
                      listen: false,
                    ).getNewBeansList(startDate, endDate, limit: 999),
                    itemBuilder: (ctx, bean, {isPreview = false}) => InkWell(
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
                                return SizedBox(
                                  height: isPreview ? 28 : 48,
                                  width: isPreview ? 42 : 72,
                                  child: const Center(
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
                                    height: isPreview ? 28 : 48,
                                    borderRadius: 8.0,
                                  );
                                }
                              }
                              final iconColor = Theme.of(ctx2)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha((255 * 0.6).round());
                              return Icon(
                                Coffeico.bag_with_bean,
                                size: isPreview ? 28 : 48,
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

                  // Origins explored
                  BeansStatListCard<String>(
                    label: l10n.originsExploredLabel,
                    leadingIcon: const Icon(Icons.public),
                    countFuture: (ctx) => Provider.of<BeansStatsProvider>(
                      ctx,
                      listen: false,
                    ).getOriginsExploredCount(startDate, endDate),
                    previewListFuture: (ctx) => Provider.of<BeansStatsProvider>(
                      ctx,
                      listen: false,
                    ).getDistinctOriginsList(startDate, endDate, limit: 10),
                    fullListFuture: (ctx) => Provider.of<BeansStatsProvider>(
                      ctx,
                      listen: false,
                    ).getDistinctOriginsList(startDate, endDate, limit: 999),
                    itemBuilder: (ctx, origin, {isPreview = false}) => Row(
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

                  // Regions explored
                  BeansStatListCard<String>(
                    label: l10n.regionsExploredLabel,
                    leadingIcon: const Icon(Icons.place),
                    countFuture: (ctx) => Provider.of<BeansStatsProvider>(
                      ctx,
                      listen: false,
                    ).getRegionsExploredCount(startDate, endDate),
                    previewListFuture: (ctx) => Provider.of<BeansStatsProvider>(
                      ctx,
                      listen: false,
                    ).getDistinctRegionsList(startDate, endDate, limit: 10),
                    fullListFuture: (ctx) => Provider.of<BeansStatsProvider>(
                      ctx,
                      listen: false,
                    ).getDistinctRegionsList(startDate, endDate, limit: 999),
                    itemBuilder: (ctx, region, {isPreview = false}) => Row(
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

                  // New roasters discovered
                  BeansStatListCard<String>(
                    label: l10n.newRoastersDiscoveredLabel,
                    leadingIcon: const Icon(Icons.storefront),
                    countFuture: (ctx) => Provider.of<BeansStatsProvider>(
                      ctx,
                      listen: false,
                    ).getNewRoastersDiscovered(startDate, endDate),
                    previewListFuture: (ctx) =>
                        Provider.of<BeansStatsProvider>(
                          ctx,
                          listen: false,
                        ).getNewRoastersDiscoveredList(
                          startDate,
                          endDate,
                          limit: 10,
                        ),
                    fullListFuture: (ctx) =>
                        Provider.of<BeansStatsProvider>(
                          ctx,
                          listen: false,
                        ).getNewRoastersDiscoveredList(
                          startDate,
                          endDate,
                          limit: 999,
                        ),
                    itemBuilder: (ctx, roaster, {isPreview = false}) => Row(
                      children: [
                        FutureBuilder<Map<String, String?>>(
                          future: Provider.of<DatabaseProvider>(
                            ctx,
                            listen: false,
                          ).fetchCachedRoasterLogoUrls(roaster),
                          builder: (ctx2, snap) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return SizedBox(
                                height: isPreview ? 28 : 40,
                                width: isPreview ? 28 : 40,
                                child: const Center(
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
                                  height: isPreview ? 28 : 40,
                                  borderRadius: 8.0,
                                );
                              }
                            }
                            final iconColor = Theme.of(ctx2)
                                .colorScheme
                                .onSurface
                                .withAlpha((255 * 0.6).round());
                            return Icon(
                              Coffeico.bag_with_bean,
                              size: isPreview ? 28 : 40,
                              color: iconColor,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(roaster, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    emptyText: l10n.noData,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalStatsSection extends StatelessWidget {
  const _GlobalStatsSection({required this.onOpenRecipe});

  final void Function(RecipeModel recipe) onOpenRecipe;

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
    final db = Provider.of<DatabaseProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.public),
                  const SizedBox(width: 8),
                  Text(
                    l10n.globalStats,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Global Coffee Brewed.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.coffeeBrewed,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${controller.totalGlobalCoffeeBrewed.toStringAsFixed(2)} ${l10n.litersUnit}',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Global Most Used Recipes
              Text(
                l10n.mostUsedRecipes,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              FutureBuilder<List<String>>(
                future: db.fetchGlobalTopRecipesAggregated(startDate, endDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      return Text(
                        l10n.noData,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      );
                    }
                    final ids = snapshot.data ?? const <String>[];
                    if (ids.isEmpty) {
                      return Text(l10n.noData);
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ids
                          .map(
                            (id) => FutureBuilder<RecipeModel?>(
                              future: Provider.of<RecipeProvider>(
                                context,
                                listen: false,
                              ).getRecipeById(id),
                              builder: (context, recipeSnapshot) {
                                if (recipeSnapshot.connectionState ==
                                    ConnectionState.done) {
                                  final recipe = recipeSnapshot.data;
                                  if (recipe != null) {
                                    final icon = getIconByBrewingMethod(
                                      recipe.brewingMethodId,
                                    );
                                    return InkWell(
                                      onTap: () => onOpenRecipe(recipe),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: Row(
                                          children: [
                                            icon,
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                recipe.name,
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.secondary,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return Text(l10n.unknownRecipe);
                                }
                                return const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            ),
                          )
                          .toList(),
                    );
                  }
                  return const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

