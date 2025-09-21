import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/ui_state/coffee_beans_sort_options.dart';
import '../../glass_container.dart';

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
    final isIos = Platform.isIOS;
    final Color? glassForeground =
        isIos ? GlassContainer.defaultForegroundColor(context) : null;
    final Color headingColor = isIos
        ? GlassContainer.defaultForegroundColor(context, emphasize: true)
        : Theme.of(context)
                .textTheme
                .headlineSmall
                ?.color ??
            Theme.of(context).colorScheme.onSurface;

    return AlertDialog(
      backgroundColor: Platform.isIOS ? Colors.transparent : null,
      content: GlassContainer(
        padding: EdgeInsets.zero,
        foregroundColor: glassForeground,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                loc.sortBy,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: headingColor,
                    ),
              ),
            ),
            ...SortOption.values.map((option) {
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
              }

              return RadioListTile<SortOption>(
                title: Text(
                  title,
                ),
                value: option,
                groupValue: currentSort,
                activeColor: glassForeground?.withOpacity(0.9),
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: Text(
                    loc.cancel,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
