import 'package:auto_size_text_plus/auto_size_text_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import '../models/brewing_method_model.dart';
import '../utils/icon_utils.dart';
import '../services/analytics_service.dart';
import '../services/onboarding_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/base_buttons.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

@RoutePage()
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  /// IDs of the most popular brewing methods to highlight.
  static const _featuredMethodIds = [
    'v60',
    'aeropress',
    'chemex',
    'origami',
    'switch',
    'clever',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allMethods = Provider.of<List<BrewingMethodModel>>(context);
    final theme = Theme.of(context);

    // Pick featured methods that exist in the data, preserving display order.
    final featured = <BrewingMethodModel>[];
    for (final id in _featuredMethodIds) {
      final match = allMethods
          .where((m) => m.brewingMethodId == id)
          .toList();
      if (match.isNotEmpty) featured.add(match.first);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                l10n.onboardingTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.onboardingSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              // Method grid
              Expanded(
                flex: 5,
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: featured.length,
                  itemBuilder: (context, index) {
                    final method = featured[index];
                    return _MethodCard(
                      method: method,
                      onTap: () => _selectMethod(context, method),
                    );
                  },
                ),
              ),
              // "Show All" button
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Semantics(
                  identifier: 'onboardingShowAllButton',
                  button: true,
                  onTap: () => _showAll(context),
                  child: ExcludeSemantics(
                    child: AppTextButton(
                      label: l10n.onboardingShowAll,
                      onPressed: () => _showAll(context),
                      isFullWidth: false,
                      foregroundColor: theme.colorScheme.primary,
                      textStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectMethod(BuildContext context, BrewingMethodModel method) {
    AnalyticsService.instance.track('onboarding_completed', properties: {
      'completion_type': 'method_selected',
      'brewing_method_id': method.brewingMethodId,
    });
    final onboarding = Provider.of<OnboardingService>(context, listen: false);
    onboarding.completeOnboarding();
    context.router.replace(const HomeRoute());
    // Navigate to the recipe list for the selected method after a frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.router.push(
        RecipeListRoute(brewingMethodId: method.brewingMethodId),
      );
    });
  }

  void _showAll(BuildContext context) {
    AnalyticsService.instance.track('onboarding_completed', properties: {
      'completion_type': 'show_all',
    });
    final onboarding = Provider.of<OnboardingService>(context, listen: false);
    onboarding.completeOnboarding();
    context.router.replace(const HomeRoute());
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({required this.method, required this.onTap});

  final BrewingMethodModel method;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: AppStroke.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(
                size: 32,
                color: theme.colorScheme.primary,
              ),
              child: getIconByBrewingMethod(method.brewingMethodId),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: AutoSizeText(
                method.brewingMethod,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                minFontSize: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
