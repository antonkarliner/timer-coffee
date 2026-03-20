import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../app_router.gr.dart';
import '../services/onboarding_service.dart';
import '../theme/design_tokens.dart';
import '../utils/icon_utils.dart';
import 'base_buttons.dart';

/// Celebratory card shown on the finish screen after the user's very first brew.
class FirstBrewCelebration extends StatelessWidget {
  const FirstBrewCelebration({
    super.key,
    required this.brewingMethodId,
  });

  final String brewingMethodId;

  @override
  Widget build(BuildContext context) {
    final onboarding = Provider.of<OnboardingService>(context, listen: false);
    if (onboarding.completedMilestoneCount != 1) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: theme.colorScheme.primary,
                  size: 40,
                ),
                child: getIconByBrewingMethod(brewingMethodId),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.firstBrewCongrats,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextButton(
                label: l10n.firstBrewDiaryLink,
                onPressed: () =>
                    context.router.push(const BrewDiaryRoute()),
                icon: Icons.library_books,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
