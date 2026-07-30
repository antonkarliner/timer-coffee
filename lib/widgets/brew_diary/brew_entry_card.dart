import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/utils/extraction_math.dart';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:coffee_timer/utils/temperature_format.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_note_text.dart';
import 'package:coffee_timer/widgets/brew_diary/directional_value_text.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';

class BrewEntryCard extends StatelessWidget {
  const BrewEntryCard({
    super.key,
    required this.entry,
    required this.formattedTime,
    required this.onTap,
    required this.onBookmarkToggle,
    required this.tasteLabels,
    this.bookmarkTogglePending = false,
    this.logoUrls,
    this.formattedDate,
    this.onBrewAgain,
    this.isBestCup = false,
    this.showBeanIdentity = true,
    this.semanticsIdentifierPrefix = 'userStatCard',
    this.bookmarkSemanticsIdentifierPrefix = 'bookmarkToggle',
  });

  final DiaryEntry entry;
  final String formattedTime;
  final VoidCallback onTap;
  final VoidCallback onBookmarkToggle;
  final List<String> tasteLabels;
  final bool bookmarkTogglePending;
  final Future<Map<String, String?>>? logoUrls;
  final String? formattedDate;
  final VoidCallback? onBrewAgain;
  final bool isBestCup;
  final bool showBeanIdentity;
  final String semanticsIdentifierPrefix;
  final String bookmarkSemanticsIdentifierPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final bookmarkLabel = entry.isMarked
        ? loc.diaryRemoveBookmark
        : loc.diaryMarkBookmark;
    final extractionYieldColors = entry.extractionYieldPercent == null
        ? null
        : AppSemanticColors.extractionYield(
            classifyExtractionYield(entry.extractionYieldPercent!),
            theme.brightness,
          );
    final extraction = _extractionLabel(entry, loc);
    return Semantics(
      identifier: '${semanticsIdentifierPrefix}_${entry.statUuid}',
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.xxl * 4),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        getIconByBrewingMethod(entry.brewingMethodId).icon,
                        size: AppIconSize.medium,
                        color: colors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.recipeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.sectionHeader,
                            ),
                            Text(
                              entry.methodName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                            if (formattedDate != null)
                              DirectionalValueText(
                                formattedDate!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Semantics(
                        identifier:
                            '${bookmarkSemanticsIdentifierPrefix}_${entry.statUuid}',
                        container: true,
                        label: bookmarkLabel,
                        button: true,
                        enabled: !bookmarkTogglePending,
                        toggled: entry.isMarked,
                        onTap: bookmarkTogglePending ? null : onBookmarkToggle,
                        child: ExcludeSemantics(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: bookmarkTogglePending ? () {} : null,
                            child: IconButton(
                              tooltip: bookmarkLabel,
                              icon: Icon(
                                entry.isMarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_outline,
                                size: AppIconSize.small,
                              ),
                              color: colors.primary,
                              onPressed: bookmarkTogglePending
                                  ? null
                                  : onBookmarkToggle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(formattedTime, style: AppTextStyles.caption),
                    ],
                  ),
                  if (showBeanIdentity && entry.beanName != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _MiniLogo(logoUrls: logoUrls),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            [entry.beanName, entry.roaster]
                                .where((value) => value?.isNotEmpty ?? false)
                                .join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.base),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _FactChip(
                        label:
                            '${_amount(entry.coffeeAmount)}\u00A0g → ${_amount(entry.waterAmount)}\u00A0g',
                      ),
                      if (entry.grindSize?.isNotEmpty ?? false)
                        _FactChip(
                          label: entry.grindSize!,
                          maxLabelWidth: AppSpacing.xxl * 3,
                        ),
                      if (formatTemperatureChip(entry.waterTemp)
                          case final temperature?)
                        _FactChip(
                          label: entry.waterTempIsDerived
                              ? '~$temperature'
                              : temperature,
                        ),
                      if (extraction != null)
                        _FactChip(
                          label: extraction,
                          color: extractionYieldColors?.background,
                          foreground: extractionYieldColors?.foreground,
                        ),
                      if (entry.tasteBalance case final taste?)
                        _TasteChip(taste: taste, labels: tasteLabels),
                      if (entry.rating case final rating?)
                        _FactChip(label: '★ ${rating.toStringAsFixed(1)}'),
                      if (isBestCup)
                        _FactChip(
                          label: loc.journeyBestCup,
                          color: colors.primaryContainer,
                          foreground: colors.onPrimaryContainer,
                          icon: Icons.push_pin,
                        ),
                      ..._tagChips(entry.tagList),
                    ],
                  ),
                  if (entry.notes?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: AppSpacing.sm),
                    BrewNoteText(
                      entry.notes!.trim(),
                      style: AppTextStyles.body,
                      // The card is a preview, so truncation is deliberate
                      // here — pass both together. The detail sheet takes the
                      // unbounded default and shows the note in full.
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (onBrewAgain != null)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppTextButton(
                        label: loc.brewAgain,
                        icon: Icons.replay,
                        isFullWidth: false,
                        height: AppButton.heightSmall,
                        padding: AppButton.paddingSmall,
                        onPressed: onBrewAgain,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _amount(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

String? _extractionLabel(DiaryEntry entry, AppLocalizations loc) =>
    switch ((entry.extractionYieldPercent, entry.tdsPercent)) {
      (final ey?, final tds?) => loc.extractionCalcDiaryLine(
        ey.toStringAsFixed(1),
        tds.toStringAsFixed(2),
      ),
      (final ey?, null) => '${ey.toStringAsFixed(1)}% EY',
      (null, final tds?) => 'TDS ${tds.toStringAsFixed(2)}%',
      _ => null,
    };

List<Widget> _tagChips(List<String> tags) {
  if (tags.isEmpty) return const [];
  final visible = tags.take(3).toList();
  final overflow = tags.length - visible.length;
  return [
    for (final tag in visible) _FactChip(label: '#$tag'),
    if (overflow > 0) _FactChip(label: '+$overflow'),
  ];
}

class _MiniLogo extends StatelessWidget {
  const _MiniLogo({this.logoUrls});

  final Future<Map<String, String?>>? logoUrls;

  @override
  Widget build(BuildContext context) {
    if (logoUrls == null) {
      return const SizedBox(
        width: AppSpacing.xxl,
        height: AppIconSize.medium,
        child: Center(
          child: Icon(Coffeico.bag_with_bean, size: AppIconSize.medium),
        ),
      );
    }
    return FutureBuilder<Map<String, String?>>(
      future: logoUrls,
      builder: (context, snapshot) {
        final original = snapshot.data?['original'];
        final mirror = snapshot.data?['mirror'];
        if (original == null && mirror == null) {
          return const SizedBox(
            width: AppSpacing.xxl,
            height: AppIconSize.medium,
            child: Center(
              child: Icon(Coffeico.bag_with_bean, size: AppIconSize.medium),
            ),
          );
        }
        return RoasterLogo(
          originalUrl: original,
          mirrorUrl: mirror,
          width: AppSpacing.xxl,
          height: AppIconSize.medium,
          borderRadius: AppRadius.small,
          forceFit: BoxFit.contain,
        );
      },
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({
    required this.label,
    this.color,
    this.foreground,
    this.maxLabelWidth,
    this.forceLtr = true,
    this.icon,
  });

  final String label;
  final Color? color;
  final Color? foreground;
  final double? maxLabelWidth;
  final bool forceLtr;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final neutralColors = AppSemanticColors.neutralChip(
      Theme.of(context).brightness,
    );
    final labelText = forceLtr
        ? DirectionalValueText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    return Chip(
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: AppIconSize.small,
              color: foreground ?? neutralColors.foreground,
            ),
      label: maxLabelWidth == null
          ? labelText
          : ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxLabelWidth!),
              child: labelText,
            ),
      labelStyle: AppTextStyles.caption.copyWith(
        color: foreground ?? neutralColors.foreground,
      ),
      backgroundColor: color ?? neutralColors.background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
    );
  }
}

class _TasteChip extends StatelessWidget {
  const _TasteChip({required this.taste, required this.labels});

  final int taste;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final semanticColors = AppSemanticColors.taste(
      taste,
      Theme.of(context).brightness,
    );
    final label = switch (taste) {
      -1 => labels[0],
      0 => labels[1],
      _ => labels[2],
    };
    return _FactChip(
      label: label,
      color: semanticColors.background,
      foreground: semanticColors.foreground,
      forceLtr: false,
    );
  }
}
