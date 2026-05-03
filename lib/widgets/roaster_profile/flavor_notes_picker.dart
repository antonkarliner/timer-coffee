// lib/widgets/roaster_profile/flavor_notes_picker.dart
//
// Flat grouped flavor picker for bean reviews.
// Parent categories show a small label with all subcategory chips in a Wrap.
// Leaf categories (no subcategories) are shown as a flat chip row at the end.
// Colors are matched to the SCA Coffee Taster's Flavor Wheel (2016).

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/design_tokens.dart';

class _FlavorSub {
  final String Function(AppLocalizations) label;
  final Color color;

  const _FlavorSub({required this.label, required this.color});
}

class _FlavorCategory {
  final String Function(AppLocalizations) label;
  final Color color; // inner-ring SCA color; also used for leaf chips
  final List<_FlavorSub> subcategories;

  const _FlavorCategory({
    required this.label,
    required this.color,
    required this.subcategories,
  });

  bool get isLeaf => subcategories.isEmpty;
}

final _kCategories = <_FlavorCategory>[
  _FlavorCategory(
    label: (l) => l.flavorCatFruity,
    color: const Color(0xFFC82828),
    subcategories: [
      _FlavorSub(label: (l) => l.flavorSubBerry,      color: const Color(0xFF9E1E28)),
      _FlavorSub(label: (l) => l.flavorSubCitrus,     color: const Color(0xFFF0BC00)),
      _FlavorSub(label: (l) => l.flavorSubDriedFruit, color: const Color(0xFF701228)),
      _FlavorSub(label: (l) => l.flavorSubTropical,   color: const Color(0xFFE05428)),
    ],
  ),
  _FlavorCategory(
    label: (l) => l.flavorCatSweet,
    color: const Color(0xFFF09020),
    subcategories: [
      _FlavorSub(label: (l) => l.flavorSubHoney,      color: const Color(0xFFE8B415)),
      _FlavorSub(label: (l) => l.flavorSubVanilla,    color: const Color(0xFFC8A030)),
      _FlavorSub(label: (l) => l.flavorSubCaramel,    color: const Color(0xFFC87510)),
      _FlavorSub(label: (l) => l.flavorSubBrownSugar, color: const Color(0xFFB86518)),
    ],
  ),
  _FlavorCategory(
    label: (l) => l.flavorCatNuttyCocoa,
    color: const Color(0xFF8B5A2B),
    subcategories: [
      _FlavorSub(label: (l) => l.flavorSubNutty,         color: const Color(0xFFB88850)),
      _FlavorSub(label: (l) => l.flavorSubMilkChocolate, color: const Color(0xFF7A4828)),
      _FlavorSub(label: (l) => l.flavorSubDarkChocolate, color: const Color(0xFF3C1C08)),
    ],
  ),
  _FlavorCategory(
    label: (l) => l.flavorCatRoasted,
    color: const Color(0xFF6B3820),
    subcategories: [
      _FlavorSub(label: (l) => l.flavorSubCereal, color: const Color(0xFFB09840)),
      _FlavorSub(label: (l) => l.flavorSubSmoky,  color: const Color(0xFF6B7880)),
      _FlavorSub(label: (l) => l.flavorSubBurnt,  color: const Color(0xFF384048)),
    ],
  ),
  _FlavorCategory(
    label: (l) => l.flavorCatFloral,
    color: const Color(0xFFE05C8C),
    subcategories: [],
  ),
  _FlavorCategory(
    label: (l) => l.flavorCatSpices,
    color: const Color(0xFFBF4520),
    subcategories: [],
  ),
  _FlavorCategory(
    label: (l) => l.flavorCatSourFermented,
    color: const Color(0xFFBFC820),
    subcategories: [],
  ),
  _FlavorCategory(
    label: (l) => l.flavorCatGreenVegetative,
    color: const Color(0xFF3E9B40),
    subcategories: [],
  ),
];

// ── Public helpers ────────────────────────────────────────────────────────────

/// Returns the SCA-matched color for a stored flavor tag string,
/// using subcategory-level precision where available.
Color? flavorTagColor(String tag, AppLocalizations l10n) {
  for (final cat in _kCategories) {
    if (cat.label(l10n) == tag) return cat.color;
    for (final sub in cat.subcategories) {
      if (sub.label(l10n) == tag) return sub.color;
    }
  }
  return null;
}

/// Returns white or black for best contrast on [background].
Color flavorTagOnColor(Color background) {
  return background.computeLuminance() > 0.35 ? Colors.black87 : Colors.white;
}

/// In dark mode, lightens colors whose luminance is below 0.20 so they remain
/// visible against a dark card surface (catches Dried Fruit, Dark Choc, Burnt,
/// Milk Choc, Berry, Smoky and similarly dark hues).
Color adaptFlavorColor(Color color, Brightness brightness) {
  if (brightness != Brightness.dark) return color;
  if (color.computeLuminance() < 0.20) {
    return Color.lerp(color, Colors.white, 0.28)!;
  }
  return color;
}

/// Returns [tags] sorted by category order, each paired with its display color.
/// Tags unknown to the wheel are appended with a neutral grey.
List<({String tag, Color color})> sortedFlavorTagsWithColors(
  List<String> tags,
  AppLocalizations l10n,
) {
  final result = <({String tag, Color color})>[];
  final remaining = List<String>.from(tags);

  for (final cat in _kCategories) {
    final catLabel = cat.label(l10n);
    if (remaining.remove(catLabel)) {
      result.add((tag: catLabel, color: cat.color));
    }
    for (final sub in cat.subcategories) {
      final subLabel = sub.label(l10n);
      if (remaining.remove(subLabel)) {
        result.add((tag: subLabel, color: sub.color));
      }
    }
  }
  for (final tag in remaining) {
    result.add((tag: tag, color: const Color(0xFF9E9E9E)));
  }
  return result;
}

// ── Widget ────────────────────────────────────────────────────────────────────

class FlavorNotesPicker extends StatefulWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onChanged;

  const FlavorNotesPicker({
    super.key,
    required this.selectedTags,
    required this.onChanged,
  });

  @override
  State<FlavorNotesPicker> createState() => _FlavorNotesPickerState();
}

class _FlavorNotesPickerState extends State<FlavorNotesPicker> {
  void _toggleTag(String tag) {
    final updated = List<String>.from(widget.selectedTags);
    if (updated.contains(tag)) {
      updated.remove(tag);
    } else {
      updated.add(tag);
    }
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;

    final parentCats = _kCategories.where((c) => !c.isLeaf).toList();
    final leafCats = _kCategories.where((c) => c.isLeaf).toList();

    final dividerColor = Theme.of(context).colorScheme.outlineVariant.withAlpha(64);
    const dividerIndent = AppSpacing.sm;

    final groups = <Widget>[];
    for (var i = 0; i < parentCats.length; i++) {
      final cat = parentCats[i];
      final catLabel = cat.label(l10n);
      if (i > 0) {
        groups.add(Divider(
          height: AppSpacing.base,
          indent: dividerIndent,
          endIndent: dividerIndent,
          color: dividerColor,
        ));
      }
      groups.addAll([
        Text(
          catLabel,
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: cat.subcategories.map((sub) {
            final subLabel = sub.label(l10n);
            final selected = widget.selectedTags.contains(subLabel);
            return _coloredFilterChip(
              label: subLabel,
              selected: selected,
              color: sub.color,
              brightness: brightness,
              onSelected: (_) => _toggleTag(subLabel),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xs),
      ]);
    }
    if (leafCats.isNotEmpty) {
      groups.add(Divider(
        height: AppSpacing.lg,
        indent: dividerIndent,
        endIndent: dividerIndent,
        color: dividerColor,
      ));
      groups.add(Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: leafCats.map((cat) {
          final catLabel = cat.label(l10n);
          final selected = widget.selectedTags.contains(catLabel);
          return _coloredFilterChip(
            label: catLabel,
            selected: selected,
            color: cat.color,
            brightness: brightness,
            onSelected: (_) => _toggleTag(catLabel),
          );
        }).toList(),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: groups,
    );
  }

  Widget _coloredFilterChip({
    required String label,
    required bool selected,
    required Color color,
    required Brightness brightness,
    required void Function(bool) onSelected,
  }) {
    final displayColor = adaptFlavorColor(color, brightness);
    final onChipColor = flavorTagOnColor(displayColor);
    return FilterChip(
      label: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: selected ? onChipColor : _adaptedColor(displayColor, brightness),
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      showCheckmark: false,
      selectedColor: displayColor,
      backgroundColor: displayColor.withAlpha(20),
      side: BorderSide(
        color: selected ? displayColor : displayColor.withAlpha(128),
        width: selected ? AppStroke.focus : AppStroke.border,
      ),
      onSelected: onSelected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 0),
    );
  }

  Color _adaptedColor(Color color, Brightness brightness) {
    return brightness == Brightness.dark
        ? Color.lerp(color, Colors.white, 0.15)!
        : color;
  }
}
