import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_group.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_export_action.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';

class DiaryGroupList extends StatelessWidget {
  const DiaryGroupList({
    super.key,
    required this.groups,
    required this.logoUrlsForGroup,
    this.onGroupTap,
    this.onShare,
  });

  final List<DiaryGroup> groups;
  final Future<Map<String, String?>>? Function(DiaryGroup group)
  logoUrlsForGroup;
  final void Function(DiaryGroup group)? onGroupTap;

  /// Exports just this bean's brews (plan 036's "per bean" entry point).
  /// Left null in call sites that don't offer export from the grouped list.
  final void Function(DiaryGroup group)? onShare;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.base),
      itemCount: groups.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.base),
      itemBuilder: (context, index) {
        final group = groups[index];
        return DiaryGroupCard(
          group: group,
          logoUrls: logoUrlsForGroup(group),
          onTap: () => onGroupTap?.call(group),
          onShare: onShare == null ? null : () => onShare!(group),
        );
      },
    );
  }
}

class DiaryGroupCard extends StatelessWidget {
  const DiaryGroupCard({
    super.key,
    required this.group,
    required this.onTap,
    this.logoUrls,
    this.onShare,
  });

  final DiaryGroup group;
  final VoidCallback onTap;
  final Future<Map<String, String?>>? logoUrls;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stateColors = group.isDialedIn
        ? AppSemanticColors.taste(0, theme.brightness)
        : AppSemanticColors.neutralChip(theme.brightness);
    final methodCount = group.entries
        .map((entry) => entry.brewingMethodId)
        .toSet()
        .length;
    final evaluatedCount = group.entries
        .where((entry) => entry.rating != null)
        .length;
    final metaParts = [
      loc.diaryGroupBrewCount(group.entries.length),
      loc.formattedBrewingMethodCount(methodCount),
      loc.journeyEvaluatedBrewCount(evaluatedCount),
    ];

    return Semantics(
      identifier: 'diaryGroupCard_${group.key}',
      button: true,
      // minHeight (not a fixed height) keeps a consistent card rhythm while
      // letting cards that carry a subtitle line (bean grouping shows the
      // roaster) grow to fit instead of overflowing the state chip.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.xxl * 3),
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Row(
                children: [
                  _GroupLeading(logoUrls: logoUrls),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          group.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.sectionHeader,
                        ),
                        if (group.subtitle?.isNotEmpty ?? false) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            group.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        _GroupSummary(parts: metaParts),
                        const SizedBox(height: AppSpacing.sm),
                        _StateChip(
                          label: group.isDialedIn
                              ? loc.diaryGroupDialedIn
                              : loc.diaryGroupDialingIn,
                          colors: stateColors,
                        ),
                      ],
                    ),
                  ),
                  if (onShare != null)
                    IconButton(
                      key: Key('diaryGroupShareButton_${group.key}'),
                      // Produces a .md file for this bean, so it reads as a
                      // save/download rather than a send. See `brewExportIcon`.
                      icon: brewExportIcon(),
                      onPressed: onShare,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupSummary extends StatelessWidget {
  const _GroupSummary({required this.parts});

  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      label: parts.join(', '),
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          runSpacing: AppSpacing.xs,
          children: [
            for (var index = 0; index < parts.length; index++)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index > 0) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: AppStroke.focus,
                        height: AppStroke.focus,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(parts[index], style: AppTextStyles.caption),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupLeading extends StatelessWidget {
  const _GroupLeading({this.logoUrls});

  final Future<Map<String, String?>>? logoUrls;

  @override
  Widget build(BuildContext context) => _MiniLogo(logoUrls: logoUrls);
}

class _MiniLogo extends StatelessWidget {
  const _MiniLogo({this.logoUrls});

  final Future<Map<String, String?>>? logoUrls;

  static const _width = AppSpacing.xxl + AppSpacing.lg;
  static const _height = AppSpacing.xxl + AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('diaryGroupLogoSlot'),
      width: _width,
      height: _height,
      child: Center(
        child: logoUrls == null
            ? const Icon(Coffeico.bag_with_bean, size: AppIconSize.large)
            : FutureBuilder<Map<String, String?>>(
                future: logoUrls,
                builder: (context, snapshot) {
                  final original = snapshot.data?['original'];
                  final mirror = snapshot.data?['mirror'];
                  if (original == null && mirror == null) {
                    return const Icon(
                      Coffeico.bag_with_bean,
                      size: AppIconSize.large,
                    );
                  }
                  return RoasterLogo(
                    originalUrl: original,
                    mirrorUrl: mirror,
                    width: _width,
                    height: _height,
                    borderRadius: AppRadius.small,
                    forceFit: BoxFit.contain,
                  );
                },
              ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.label, required this.colors});

  final String label;
  final AppSemanticColorPair colors;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: AppTextStyles.caption.copyWith(color: colors.foreground),
      backgroundColor: colors.background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
    );
  }
}
