// lib/widgets/roaster_profile/taste_profile_sliders.dart

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/design_tokens.dart';

/// Displays taste-profile sliders for a bean review.
///
/// Edit mode (5 sliders): Sweetness, Brightness, Body, Bitterness, Aftertaste.
/// Read-only mode: same 5 plus legacy Fruitiness if non-null (old reviews).
///
/// Null/unrated state: sliders start null until the user drags them.
/// Track interaction via [interactedKeys]; uninteracted sliders render
/// grey/dim at 0.5 as a visual placeholder but submit as null.
class TasteProfileSliders extends StatelessWidget {
  final double? sweetness;
  final double? acidity;
  final double? fruitiness; // legacy — shown read-only only if non-null
  final double? body;
  final double? bitterness;
  final double? aftertaste;
  final bool readOnly;
  final Set<String>? interactedKeys; // null in read-only mode
  final void Function(Map<String, double?> values)? onChanged;
  final void Function(String key)? onSliderInteracted;

  const TasteProfileSliders({
    super.key,
    this.sweetness,
    this.acidity,
    this.fruitiness,
    this.body,
    this.bitterness,
    this.aftertaste,
    this.readOnly = true,
    this.interactedKeys,
    this.onChanged,
    this.onSliderInteracted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final dimensions = [
      (label: l10n.tasteSweet, value: sweetness, key: 'sweetness'),
      (label: l10n.tasteBrightness, value: acidity, key: 'acidity'),
      (label: l10n.tasteBody, value: body, key: 'body'),
      (label: l10n.tasteBitterness, value: bitterness, key: 'bitterness'),
      (label: l10n.tasteAftertaste, value: aftertaste, key: 'aftertaste'),
      // Legacy fruitiness shown read-only only if it has a value (old reviews)
      if (readOnly && fruitiness != null)
        (label: l10n.tasteFruity, value: fruitiness, key: 'fruitiness'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: dimensions.map((dim) {
        final interacted =
            readOnly || (interactedKeys?.contains(dim.key) ?? false);

        return _TasteDimensionRow(
          label: dim.label,
          value: dim.value ?? 0.5,
          hasValue: dim.value != null,
          readOnly: readOnly,
          interacted: interacted,
          onChanged: readOnly
              ? null
              : (v) {
                  onSliderInteracted?.call(dim.key);
                  onChanged?.call({
                    'sweetness': sweetness,
                    'acidity': acidity,
                    'body': body,
                    'bitterness': bitterness,
                    'aftertaste': aftertaste,
                    dim.key: v,
                  });
                },
        );
      }).toList(),
    );
  }
}

class _TasteDimensionRow extends StatelessWidget {
  final String label;
  final double value;
  final bool hasValue;
  final bool readOnly;
  final bool interacted;
  final ValueChanged<double>? onChanged;

  const _TasteDimensionRow({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.readOnly,
    required this.interacted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: readOnly
                ? _SegmentedDotTrack(value: hasValue ? value : null)
                : SliderTheme(
                    data: interacted
                        ? SliderTheme.of(context)
                        : SliderTheme.of(context).copyWith(
                            activeTrackColor:
                                colorScheme.onSurface.withOpacity(0.25),
                            inactiveTrackColor:
                                colorScheme.onSurface.withOpacity(0.12),
                            thumbColor:
                                colorScheme.onSurface.withOpacity(0.35),
                          ),
                    child: Slider(
                      value: value,
                      min: 0,
                      max: 1,
                      divisions: 10,
                      onChanged: onChanged,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A thin filled track with a single dot at the value position for read-only display.
/// Null (unrated) renders as an empty track with no dot.
class _SegmentedDotTrack extends StatelessWidget {
  final double? value; // 0.0–1.0, null = unrated

  const _SegmentedDotTrack({this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const trackHeight = 3.0;
    const dotSize = 10.0;

    if (value == null) {
      return Container(
        height: trackHeight,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withOpacity(0.12),
          borderRadius: BorderRadius.circular(trackHeight / 2),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final fillWidth = totalWidth * value!;
        final dotLeft = (fillWidth - dotSize / 2).clamp(0.0, totalWidth - dotSize);

        return SizedBox(
          height: dotSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background track
              Positioned(
                top: (dotSize - trackHeight) / 2,
                left: 0,
                right: 0,
                child: Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                  ),
                ),
              ),
              // Filled portion
              Positioned(
                top: (dotSize - trackHeight) / 2,
                left: 0,
                child: Container(
                  width: fillWidth,
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                  ),
                ),
              ),
              // Dot at value position
              Positioned(
                left: dotLeft,
                top: 0,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
