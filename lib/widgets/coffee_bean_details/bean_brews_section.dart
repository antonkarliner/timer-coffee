import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_router.gr.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_stat_model.dart';
import '../../providers/recipe_provider.dart';
import '../../services/date_time_format_service.dart';
import '../../theme/design_tokens.dart';
import '../../utils/icon_utils.dart';
import '../../widgets/base_buttons.dart';
import '../containers/section_card.dart';

class BeanJourneyShortcut extends StatelessWidget {
  const BeanJourneyShortcut({
    super.key,
    required this.beansUuid,
    required this.statsFuture,
    required this.onTap,
  });

  final String beansUuid;
  final Future<List<UserStatsModel>> statsFuture;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserStatsModel>>(
      future: statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data
            ?.where((stat) => !stat.isDeleted)
            .toList(growable: false);
        if (snapshot.hasError || stats == null || stats.isEmpty) {
          return const SizedBox.shrink();
        }

        return _BeanJourneyRow(
          beansUuid: beansUuid,
          stats: stats,
          onTap: onTap,
        );
      },
    );
  }
}

class BeanBrewsSection extends StatelessWidget {
  const BeanBrewsSection({
    super.key,
    required this.beansUuid,
    required this.statsFuture,
    required this.onJourneyTap,
  });

  final String beansUuid;
  final Future<List<UserStatsModel>> statsFuture;
  final Future<void> Function() onJourneyTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserStatsModel>>(
      future: statsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return SectionCard(
          icon: Icons.local_cafe_outlined,
          title: AppLocalizations.of(context)!.brewsWithThisCoffee,
          isCollapsible: true,
          initiallyExpanded: false,
          paddingChild: false,
          child: _BrewsList(
            beansUuid: beansUuid,
            stats: snapshot.data!,
            onJourneyTap: onJourneyTap,
          ),
        );
      },
    );
  }
}

class _BeanJourneyRow extends StatelessWidget {
  const _BeanJourneyRow({
    required this.beansUuid,
    required this.stats,
    required this.onTap,
  });

  final String beansUuid;
  final List<UserStatsModel> stats;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final formatService = context.read<DateTimeFormatService>();
    final newestBrew = stats
        .map((stat) => stat.createdAt)
        .reduce((current, date) => date.isAfter(current) ? date : current);
    final dateFormat = DateFormat(
      formatService.datePattern(loc.dateFormat),
      Localizations.localeOf(context).toString(),
    );
    final summaryParts = [
      loc.diaryGroupBrewCount(stats.length),
      loc.formattedBrewingMethodCount(
        stats.map((stat) => stat.brewingMethodId).toSet().length,
      ),
      loc.beanJourneyLastBrewed(dateFormat.format(newestBrew.toLocal())),
    ];

    return Semantics(
      identifier: 'beanJourneyShortcut_$beansUuid',
      label: [loc.beanJourneyTitle, ...summaryParts].join(', '),
      button: true,
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.library_books, size: AppIconSize.medium),
        title: Text(loc.beanJourneyTitle, style: AppTextStyles.fieldLabel),
        subtitle: Text(summaryParts.join(' · ')),
        trailing: const Icon(Icons.chevron_right, size: AppIconSize.medium),
      ),
    );
  }
}

class _BrewsList extends StatefulWidget {
  const _BrewsList({
    required this.beansUuid,
    required this.stats,
    required this.onJourneyTap,
  });

  final String beansUuid;
  final List<UserStatsModel> stats;
  final Future<void> Function() onJourneyTap;

  @override
  State<_BrewsList> createState() => _BrewsListState();
}

class _BrewsListState extends State<_BrewsList> {
  static const int _previewCount = 5;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final visible = _showAll
        ? widget.stats
        : widget.stats.take(_previewCount).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BeanJourneyRow(
          beansUuid: widget.beansUuid,
          stats: widget.stats,
          onTap: widget.onJourneyTap,
        ),
        const Divider(height: AppStroke.border),
        for (final stat in visible) _BrewRow(stat: stat),
        if (!_showAll && widget.stats.length > _previewCount)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.sm,
            ),
            child: AppTextButton(
              label: loc.showAllNBrews(widget.stats.length),
              onPressed: () => setState(() => _showAll = true),
            ),
          ),
      ],
    );
  }
}

class _BrewRow extends StatelessWidget {
  const _BrewRow({required this.stat});

  final UserStatsModel stat;

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final fmtSvc = Provider.of<DateTimeFormatService>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final is24h =
        fmtSvc.use24Hour(MediaQuery.of(context).alwaysUse24HourFormat);
    final timePattern = is24h ? 'HH:mm' : 'hh:mm a';
    final dateFormat = DateFormat(
      '${fmtSvc.datePattern(loc.dateFormat)} $timePattern',
      Localizations.localeOf(context).toString(),
    );

    return FutureBuilder<List<String>>(
      future: Future.wait([
        recipeProvider.getBrewingMethodName(stat.brewingMethodId),
        recipeProvider.getLocalizedRecipeName(stat.recipeId),
      ]),
      builder: (context, namesSnapshot) {
        final methodName = namesSnapshot.data?[0] ?? '';
        final recipeName = namesSnapshot.data?[1] ?? '';

        return ListTile(
          onTap: () => context.router
              .push(BrewDiaryRoute(initialExpandedStatUuid: stat.statUuid)),
          leading: getIconByBrewingMethod(stat.brewingMethodId),
          title: Text(
            recipeName,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$methodName · ${stat.coffeeAmount.toStringAsFixed(1)}g / ${stat.waterAmount.toStringAsFixed(0)}ml',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                dateFormat.format(stat.createdAt.toLocal()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (stat.notes != null && stat.notes!.isNotEmpty)
                Text(
                  stat.notes!.split('\n').first,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: (stat.rating != null || stat.isMarked)
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (stat.rating != null)
                      Text(
                        '★ ${stat.rating!.toStringAsFixed(1)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (stat.isMarked)
                      Icon(
                        Icons.bookmark,
                        size: AppIconSize.small,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                )
              : null,
          isThreeLine: true,
        );
      },
    );
  }
}
