import 'package:auto_route/auto_route.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';

import 'package:coffee_timer/l10n/app_localizations.dart';
import '../app_router.gr.dart';
import '../services/analytics_service.dart';
import '../theme/design_tokens.dart';
import 'base_buttons.dart';

/// Celebratory card shown on the Finish screen on the anniversary of the
/// user's first brew.
///
/// This widget is a pure renderer — the host decides when [shouldShow] is
/// true (e.g. via [MomentsService.isFirstBrewAnniversary] +
/// [MomentsService.isAnniversaryShownThisYear]) and is responsible for
/// marking discovery state when the card appears.
class AnniversaryCelebration extends StatelessWidget {
  const AnniversaryCelebration({
    super.key,
    required this.shouldShow,
  });

  final bool shouldShow;

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();

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
              Icon(
                Coffeico.bean,
                color: theme.colorScheme.primary,
                size: AppIconSize.large + 8,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.mts_anniversaryTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.mts_anniversarySubtitle,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextButton(
                label: l10n.mts_anniversaryDiaryLink,
                onPressed: () {
                  AnalyticsService.maybeInstance?.track(
                    'moment_interacted',
                    properties: {
                      'moment_id': 'anniversary',
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
