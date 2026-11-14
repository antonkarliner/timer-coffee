import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import '../database/database.dart';
import '../models/recipe_model.dart';
import '../services/analytics_service.dart';
import '../services/onboarding_service.dart';
import '../theme/design_tokens.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../screens/pulse_screen.dart';
import '../utils/journey_recipe_suggestion.dart';
import 'base_buttons.dart';

/// Location where the card is displayed — controls visibility and collapse logic.
enum JourneyCardLocation { home, hub }

/// A milestone tracker card shown after first brew.
/// Gamifies feature discovery by checking off milestones as the user explores.
class CoffeeJourneyCard extends StatelessWidget {
  const CoffeeJourneyCard({
    super.key,
    this.location = JourneyCardLocation.home,
  });

  final JourneyCardLocation location;

  @override
  Widget build(BuildContext context) {
    final onboarding = Provider.of<OnboardingService>(context);

    final shouldShow = location == JourneyCardLocation.home
        ? onboarding.shouldShowJourneyCard
        : onboarding.shouldShowHubJourneyCard;
    if (!shouldShow) return const SizedBox.shrink();

    // Looked up only once the card is visible: a hidden card must not need
    // anything it did not need before the recipe suggestion existed.
    final database = Provider.of<AppDatabase>(context, listen: false);
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final milestones = _buildMilestones(context, onboarding, l10n);
    final completed = onboarding.completedMilestoneCount;
    final total = OnboardingService.totalMilestones;

    final isCollapsed = location == JourneyCardLocation.home
        ? onboarding.journeyCollapsed
        : onboarding.hubJourneyCollapsed;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: AppStroke.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row — tappable to expand/collapse
              InkWell(
                onTap: () => location == JourneyCardLocation.home
                    ? onboarding.toggleJourneyCollapsed()
                    : onboarding.toggleHubJourneyCollapsed(),
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.coffeeJourneyTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isCollapsed)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: Text(
                          '$completed/$total',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Icon(
                      isCollapsed ? Icons.expand_more : Icons.expand_less,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: AppIconSize.small,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => location == JourneyCardLocation.home
                          ? _dismissFromHome(context, onboarding)
                          : _dismissFromHub(context, onboarding),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                    ),
                  ],
                ),
              ),
              // Expanded content
              if (!isCollapsed) ...[
                const SizedBox(height: AppSpacing.sm),
                // Progress indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: LinearProgressIndicator(
                    value: completed / total,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Milestone list. The second milestone ("try another
                // recipe") gets a stateful tile that loads a concrete
                // recipe suggestion; the other tiles stay stateless.
                for (final (index, milestone) in milestones.indexed)
                  if (index == 1)
                    _TryRecipeMilestoneTile(
                      milestone: milestone,
                      database: database,
                      locale: locale,
                      location: location,
                    )
                  else
                    _MilestoneTile(milestone: milestone),
                // Show "Done" button if all milestones complete
                if (onboarding.allMilestonesComplete) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppElevatedButton(
                    label: l10n.coffeeJourneyDoneButton,
                    onPressed: () => onboarding.completeJourney(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<_Milestone> _buildMilestones(
    BuildContext context,
    OnboardingService onboarding,
    AppLocalizations l10n,
  ) {
    return [
      _Milestone(
        label: l10n.coffeeJourneyMilestoneFirstBrew,
        done: onboarding.milestoneFirstBrew,
        onTap: null, // Already completed if card is visible
      ),
      _Milestone(
        label: l10n.coffeeJourneyMilestoneTryMethod,
        done: onboarding.milestoneTryRecipe,
        onTap: null, // User is already on/near the methods screen
      ),
      _Milestone(
        label: l10n.coffeeJourneyMilestoneAddBeans,
        done: onboarding.milestoneAddBeans,
        onTap: () => context.router.push(NewBeansRoute()),
      ),
      _Milestone(
        label: l10n.coffeeJourneyMilestoneFavorite,
        done: onboarding.milestoneFavorite,
        onTap: () => context.router.push(const FavoriteRecipesRoute()),
      ),
      _Milestone(
        label: l10n.coffeeJourneyMilestoneStats,
        done: onboarding.milestoneStats,
        onTap: () => context.router.push(StatsRoute()),
      ),
      _Milestone(
        label: l10n.coffeeJourneyMilestonePulse,
        done: onboarding.milestonePulse,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PulseScreen())),
      ),
    ];
  }

  /// Dismiss from brewing methods screen — card remains in hub.
  void _dismissFromHome(BuildContext context, OnboardingService onboarding) {
    onboarding.dismissJourneyCard();
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.coffeeJourneyDismissHint),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Dismiss from hub — confirmation dialog, then permanent dismiss.
  void _dismissFromHub(BuildContext context, OnboardingService onboarding) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(l10n.coffeeJourneyTitle),
        content: Text(l10n.coffeeJourneyDismissConfirm),
        actions: [
          AppTextButton(
            label: MaterialLocalizations.of(ctx).cancelButtonLabel,
            onPressed: () => Navigator.of(ctx).pop(false),
            height: AppButton.heightMedium,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          AppElevatedButton(
            label: l10n.coffeeJourneyHideButton,
            onPressed: () => Navigator.of(ctx).pop(true),
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
            height: AppButton.heightMedium,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        if (!onboarding.allMilestonesComplete) {
          AnalyticsService.instance.track(
            'journey_dismissed',
            properties: {
              'milestones_completed': onboarding.completedMilestoneCount,
            },
          );
        }
        onboarding.completeJourney();
      }
    });
  }
}

class _Milestone {
  const _Milestone({
    required this.label,
    required this.done,
    required this.onTap,
  });

  final String label;
  final bool done;
  final VoidCallback? onTap;
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.milestone});

  final _Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Items remain clickable even after completion (but no arrow).
    final hasAction = milestone.onTap != null;

    return InkWell(
      onTap: hasAction ? milestone.onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(
              milestone.done ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: milestone.done
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                milestone.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: milestone.done
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                  decoration: milestone.done
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            // Show arrow only for incomplete items with actions
            if (!milestone.done && hasAction)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

/// The "try another recipe" milestone tile. Loads a concrete recipe
/// suggestion once per mount (same selection rule as the recipe-exploration
/// notification) and, while the milestone is incomplete and a suggestion
/// exists, shows the suggested recipe's name and opens its detail screen on
/// tap. Every other state — still loading, load error, no suggestion,
/// milestone done — renders exactly the generic tile it replaces.
///
/// Always builds a [_MilestoneTile] so the widget type at this tree position
/// is stable while the suggestion loads; only the label and tap handler
/// change once it resolves.
class _TryRecipeMilestoneTile extends StatefulWidget {
  const _TryRecipeMilestoneTile({
    required this.milestone,
    required this.database,
    required this.locale,
    required this.location,
  });

  final _Milestone milestone;
  final AppDatabase database;
  final String locale;
  final JourneyCardLocation location;

  @override
  State<_TryRecipeMilestoneTile> createState() =>
      _TryRecipeMilestoneTileState();
}

class _TryRecipeMilestoneTileState extends State<_TryRecipeMilestoneTile> {
  RecipeModel? _suggestion;
  bool _trackedSuggestion = false;

  @override
  void initState() {
    super.initState();
    // No inherited-widget lookups here: database and locale arrive via the
    // widget (resolved in the parent's build).
    if (!widget.milestone.done) {
      _loadSuggestion();
    }
  }

  Future<void> _loadSuggestion() async {
    final database = widget.database;
    final locale = widget.locale;
    try {
      final stats = await database.userStatsDao.fetchAllStats();
      final suggestion = await suggestJourneyRecipe(
        [
          for (final stat in stats)
            (
              recipeId: stat.recipeId,
              brewingMethodId: stat.brewingMethodId,
            ),
        ],
        (methodId) =>
            database.recipesDao.fetchRecipesForBrewingMethod(methodId, locale),
      );
      if (!mounted) return;
      setState(() {
        _suggestion = suggestion;
      });
      if (suggestion != null && !_trackedSuggestion) {
        _trackedSuggestion = true;
        AnalyticsService.maybeInstance?.track(
          'journey_milestone_suggested',
          properties: {
            'milestone': 'try_recipe',
            'recipe_id': suggestion.id,
            'location': widget.location.name,
          },
        );
      }
    } catch (_) {
      // Any load failure keeps the generic, untappable tile in place.
    }
  }

  @override
  Widget build(BuildContext context) {
    var milestone = widget.milestone;
    final suggestion = _suggestion;
    if (!milestone.done && suggestion != null) {
      final l10n = AppLocalizations.of(context)!;
      milestone = _Milestone(
        label: l10n.coffeeJourneyMilestoneTryRecipeNamed(suggestion.name),
        done: milestone.done,
        onTap: () => context.router.push(
          RecipeDetailRoute(
            brewingMethodId: suggestion.brewingMethodId,
            recipeId: suggestion.id,
          ),
        ),
      );
    }
    return _MilestoneTile(milestone: milestone);
  }
}
