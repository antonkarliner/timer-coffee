import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';
import 'package:flutter/material.dart';

typedef TopDiaryMethod = ({
  String brewingMethodId,
  String methodName,
  int count,
});

class DiaryFilterBar extends StatelessWidget {
  const DiaryFilterBar({
    super.key,
    required this.searchController,
    required this.topMethods,
    required this.selectedMethodIds,
    required this.selectedTags,
    required this.ratingFourPlus,
    required this.bookmarkedOnly,
    required this.hasAnyFilter,
    required this.onSearchChanged,
    required this.onOpenFilters,
    required this.onClearAll,
    required this.onRatingFourPlusChanged,
    required this.onBookmarkedChanged,
    required this.onMethodChanged,
    required this.onTagRemoved,
  });

  final TextEditingController searchController;
  final List<TopDiaryMethod> topMethods;
  final Set<String> selectedMethodIds;
  final Set<String> selectedTags;
  final bool ratingFourPlus;
  final bool bookmarkedOnly;
  final bool hasAnyFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;
  final VoidCallback onClearAll;
  final ValueChanged<bool> onRatingFourPlusChanged;
  final ValueChanged<bool> onBookmarkedChanged;
  final void Function(String methodId, bool selected) onMethodChanged;
  final ValueChanged<String> onTagRemoved;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.base,
        AppSpacing.base,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          LabeledField(
            controller: searchController,
            label: loc.diarySearchHint,
            hintText: loc.diarySearchHint,
            semanticIdentifier: 'brewDiarySearch',
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.none,
            showClearButton: true,
            prefixIcon: const Icon(Icons.search, size: AppIconSize.medium),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DiaryChip.icon(
                  icon: Icons.tune,
                  tooltip: loc.diaryFilterSheetTitle,
                  selected: hasAnyFilter,
                  onSelected: (_) => onOpenFilters(),
                ),
                _DiaryChip(
                  label: loc.all,
                  selected: !hasAnyFilter,
                  onSelected: (_) => onClearAll(),
                ),
                _DiaryChip(
                  label: loc.diaryRatingFourPlus,
                  selected: ratingFourPlus,
                  onSelected: onRatingFourPlusChanged,
                ),
                _DiaryChip(
                  label: loc.diaryBookmarked,
                  leadingIcon: Icons.bookmark_outline,
                  selected: bookmarkedOnly,
                  onSelected: onBookmarkedChanged,
                ),
                for (final method in topMethods)
                  _DiaryChip(
                    label: method.methodName,
                    selected: selectedMethodIds.contains(
                      method.brewingMethodId,
                    ),
                    onSelected: (selected) =>
                        onMethodChanged(method.brewingMethodId, selected),
                  ),
                for (final tag in selectedTags.toList()..sort())
                  _DiaryChip(
                    label: '#$tag',
                    selected: true,
                    onSelected: (_) => onTagRemoved(tag),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryChip extends StatelessWidget {
  const _DiaryChip({
    required this.label,
    this.leadingIcon,
    required this.selected,
    required this.onSelected,
  }) : icon = null,
       tooltip = null;

  const _DiaryChip.icon({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onSelected,
  }) : label = null,
       leadingIcon = null;

  final String? label;
  final IconData? leadingIcon;
  final IconData? icon;
  final String? tooltip;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppSemanticColors.neutralChip(Theme.of(context).brightness);
    // The app-wide monochrome chip theme (see theme_provider.dart) makes
    // the selected background solid scheme.primary, so the foreground
    // must flip to onPrimary when selected to stay readable.
    final foreground = selected
        ? Theme.of(context).colorScheme.onPrimary
        : colors.foreground;
    final chip = FilterChip(
      avatar: leadingIcon == null
          ? null
          : Icon(leadingIcon, size: AppIconSize.small, color: foreground),
      label: label == null
          ? Icon(icon, size: AppIconSize.small, color: foreground)
          : Text(
              label!,
              style: AppTextStyles.caption.copyWith(color: foreground),
            ),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      backgroundColor: colors.background,
      // Matches theme-default selected chips (one selected-chip language).
      selectedColor: Theme.of(context).chipTheme.selectedColor,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: tooltip == null ? chip : Tooltip(message: tooltip, child: chip),
    );
  }
}
