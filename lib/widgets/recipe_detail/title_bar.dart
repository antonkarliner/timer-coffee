import 'package:flutter/material.dart';
import '../app_bar_title.dart';

/// Title row for Recipe Detail AppBar: brewing method icon + method name.
///
/// Keep purely presentational; caller provides the icon widget and the title text.
class RecipeDetailTitle extends StatelessWidget {
  final Widget brewingMethodIcon;
  final String brewingMethodName;

  const RecipeDetailTitle({
    super.key,
    required this.brewingMethodIcon,
    required this.brewingMethodName,
  });

  @override
  Widget build(BuildContext context) {
    return AppBarTitle(
      text: brewingMethodName,
      leading: brewingMethodIcon,
    );
  }
}
