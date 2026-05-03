// lib/widgets/roaster_profile/star_rating.dart

import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// Displays a row of stars.
///
/// When [interactive] is true the user can tap stars to change [value].
/// When [interactive] is false it is a pure display widget.
class StarRating extends StatelessWidget {
  final double value;
  final int maxStars;
  final double starSize;
  final ValueChanged<double>? onChanged;
  final bool interactive;

  const StarRating({
    super.key,
    required this.value,
    this.maxStars = 5,
    this.starSize = AppIconSize.medium,
    this.onChanged,
    this.interactive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        final starValue = index + 1;
        final icon = value >= starValue
            ? Icons.star_rounded
            : value >= starValue - 0.5
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;

        final star = Icon(icon, color: color, size: starSize);

        if (!interactive) return star;

        return GestureDetector(
          onTap: () => onChanged?.call(starValue.toDouble()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: star,
          ),
        );
      }),
    );
  }
}
