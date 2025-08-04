import 'package:flutter/material.dart';

/// Title row for Recipe Detail AppBar: brewing method icon + method name.
///
/// Keep purely presentational; caller provides the icon widget and the title text.
class RecipeDetailTitle extends StatelessWidget {
  final Widget brewingMethodIcon;
  final String brewingMethodName;

  const RecipeDetailTitle({
    Key? key,
    required this.brewingMethodIcon,
    required this.brewingMethodName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        brewingMethodIcon,
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            brewingMethodName,
            style: Theme.of(context).textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
