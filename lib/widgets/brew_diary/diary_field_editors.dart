import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/utils/diary_tags.dart';
import 'package:coffee_timer/widgets/fields/chip_input.dart';
import 'package:flutter/material.dart';

/// Taste-balance chip row (sour / balanced / bitter) used by the diary's
/// focused taste editor. Extracted from `brew_detail_sheet.dart` so it can be
/// reused by other diary-adjacent surfaces.
class DiaryTasteEditor extends StatelessWidget {
  const DiaryTasteEditor({
    super.key,
    required this.value,
    required this.labels,
    required this.onChanged,
  });
  final int? value;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Chips size to their own label and sit together, centred: stretching them
    // edge-to-edge (the previous `Expanded` layout) reads as three unrelated
    // controls on a full-width surface like the finish eval sheet. `Wrap`
    // keeps long localized labels from overflowing on narrow screens.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (var index = 0; index < labels.length; index++)
          ChoiceChip(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            labelPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
            ),
            label: Text(
              labels[index],
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: value == index - 1
                    ? AppSemanticColors.taste(
                        index - 1,
                        brightness,
                      ).foreground
                    : null,
              ),
            ),
            selected: value == index - 1,
            selectedColor: AppSemanticColors.taste(
              index - 1,
              brightness,
            ).background,
            onSelected: (_) => onChanged(index - 1),
          ),
      ],
    );
  }
}

/// Tag chip input used by the diary's focused tags editor. Extracted from
/// `brew_detail_sheet.dart` so it can be reused by other diary-adjacent
/// surfaces.
class DiaryTagsFieldEditor extends StatelessWidget {
  const DiaryTagsFieldEditor({
    super.key,
    required this.initialValues,
    required this.suggestionsFuture,
    required this.onChanged,
    this.errorText,
    this.textController,
  });

  final List<String> initialValues;
  final Future<List<String>> suggestionsFuture;
  final ValueChanged<List<String>> onChanged;
  final String? errorText;
  final TextEditingController? textController;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return FutureBuilder<List<String>>(
      future: suggestionsFuture,
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? [];
        return ChipInput(
          key: const Key('focusedTagsInput'),
          label: loc.diaryTags,
          hintText: loc.diaryTagsHint,
          initialValues: initialValues,
          suggestions: suggestions,
          quickPicks: suggestions,
          maxChips: diaryTagsMaxCount,
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          capitalizeChipLabels: false,
          errorText: errorText,
          onChanged: onChanged,
          controller: textController,
        );
      },
    );
  }
}
