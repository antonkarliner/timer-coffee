import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// The only app-bar title shape (plan 089 D3): icon + text everywhere, centred
/// by the framework because the Row is min-sized; text ellipsizes so it never
/// pushes actions.
class AppBarTitle extends StatelessWidget {
  const AppBarTitle({super.key, required this.text, this.icon, this.leading})
    : assert(
        (icon == null) != (leading == null),
        'Pass exactly one of icon or leading',
      );

  final String text;
  final IconData? icon;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading ?? Icon(icon, size: AppIconSize.medium),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
