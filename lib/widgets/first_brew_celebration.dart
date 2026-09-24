import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../app_router.gr.dart';
import '../services/analytics_service.dart';
import '../theme/design_tokens.dart';
import '../utils/icon_utils.dart';
import 'base_buttons.dart';

/// Celebratory card shown on the finish screen after the user's very first brew.
///
/// The caller decides when it renders — `FinishScreen` mounts it only when
/// no brew was recorded before this one. (It used to gate itself on
/// `OnboardingService.completedMilestoneCount == 1`, which stayed true across
/// repeat brews of the same recipe and so re-showed the card every time.)
class FirstBrewCelebration extends StatefulWidget {
  const FirstBrewCelebration({super.key, required this.brewingMethodId});

  final String brewingMethodId;

  @override
  State<FirstBrewCelebration> createState() => _FirstBrewCelebrationState();
}

class _FirstBrewCelebrationState extends State<FirstBrewCelebration> {
  /// One-shot guard so the impression fires once per appearance, not per
  /// rebuild.
  bool _impressionLogged = false;

  @override
  Widget build(BuildContext context) {
    if (!_impressionLogged) {
      _impressionLogged = true;
      AnalyticsService.maybeInstance?.track(
        'moment_shown',
        properties: {'moment_id': 'first_brew'},
      );
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
                data: IconThemeData(color: theme.colorScheme.primary, size: 40),
                child: getIconByBrewingMethod(widget.brewingMethodId),
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
                onPressed: () {
                  AnalyticsService.maybeInstance?.track(
                    'moment_interacted',
                    properties: {
                      'moment_id': 'first_brew',
                      'action': 'open_diary',
                    },
                  );
                  context.router.push(BrewDiaryRoute());
                },
                icon: Icons.library_books,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
