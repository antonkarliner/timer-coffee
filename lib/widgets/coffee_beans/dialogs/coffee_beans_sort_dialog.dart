import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/ui_state/coffee_beans_sort_options.dart';

/// Dialog for selecting sort options for coffee beans.
///
/// This dialog displays radio buttons for different sort options,
/// allowing users to select how they want to sort their coffee beans list.
/// Uses the SortOption enum from CoffeeBeansSortOptions model.
class CoffeeBeansSortDialog extends StatelessWidget {
  /// Currently selected sort option
  final SortOption currentSort;

  const CoffeeBeansSortDialog({
    Key? key,
    required this.currentSort,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.sortBy),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: SortOption.values.map((option) {
          String title;
          switch (option) {
            case SortOption.dateAdded:
              title = loc.dateAdded;
              break;
            case SortOption.name:
              title = loc.name;
              break;
            case SortOption.roaster:
              title = loc.roaster;
              break;
            case SortOption.origin:
              title = loc.origin;
              break;
            case SortOption.remainingAmount:
              title = loc.amountLeft;
              break;
          }

          return RadioListTile<SortOption>(
            title: Text(title),
            value: option,
            groupValue: currentSort,
            onChanged: (value) {
              Navigator.pop(context, value);
            },
          );
        }).toList(),
      ),
    );
  }
}
