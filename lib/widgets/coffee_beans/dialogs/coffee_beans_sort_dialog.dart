import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/ui_state/coffee_beans_sort_options.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';

/// Bottom sheet for selecting sort field and direction for coffee beans.
class CoffeeBeansSortDialog extends StatefulWidget {
  final CoffeeBeansSortOptions currentSortOptions;

  const CoffeeBeansSortDialog({
    super.key,
    required this.currentSortOptions,
  });

  @override
  State<CoffeeBeansSortDialog> createState() => _CoffeeBeansSortDialogState();
}

class _CoffeeBeansSortDialogState extends State<CoffeeBeansSortDialog> {
  late SortOption _selectedOption;
  late SortDirection _selectedDirection;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.currentSortOptions.sortOption;
    _selectedDirection = widget.currentSortOptions.sortDirection;
  }

  SortDirection _naturalDirection(SortOption option) {
    switch (option) {
      case SortOption.name:
      case SortOption.roaster:
      case SortOption.origin:
        return SortDirection.ascending;
      case SortOption.dateAdded:
      case SortOption.remainingAmount:
      case SortOption.roastDate:
        return SortDirection.descending;
    }
  }

  String _labelFor(SortOption option, AppLocalizations loc) {
    switch (option) {
      case SortOption.dateAdded:
        return loc.dateAdded;
      case SortOption.name:
        return loc.name;
      case SortOption.roaster:
        return loc.roaster;
      case SortOption.origin:
        return loc.origin;
      case SortOption.remainingAmount:
        return loc.amountLeft;
      case SortOption.roastDate:
        return loc.roastDate;
    }
  }

  Widget _buildDirectionButton(
      BuildContext context, SortDirection direction, IconData icon) {
    final isSelected = _selectedDirection == direction;
    final color = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: () => setState(() => _selectedDirection = direction),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withAlpha((255 * 0.12).round())
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(
            color: isSelected
                ? color
                : color.withAlpha((255 * 0.3).round()),
            width: AppStroke.border,
          ),
        ),
        child: Icon(
          icon,
          size: AppIconSize.small,
          color: isSelected
              ? color
              : color.withAlpha((255 * 0.4).round()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: title + direction toggle
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(loc.sortBy, style: AppTextStyles.sectionHeader),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDirectionButton(
                          context, SortDirection.ascending, Icons.arrow_upward),
                      const SizedBox(width: AppSpacing.xs),
                      _buildDirectionButton(context, SortDirection.descending,
                          Icons.arrow_downward),
                    ],
                  ),
                ],
              ),
            ),
            // Sort option list
            ...SortOption.values.map((option) => ListTile(
                  dense: true,
                  title: Text(_labelFor(option, loc),
                      style: AppTextStyles.body),
                  trailing: _selectedOption == option
                      ? Icon(
                          Icons.check,
                          size: AppIconSize.medium,
                          color: colorScheme.onSurface,
                        )
                      : null,
                  onTap: () => setState(() {
                    _selectedOption = option;
                    _selectedDirection = _naturalDirection(option);
                  }),
                )),
            const SizedBox(height: AppSpacing.base),
            // Action buttons
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: AppSpacing.base,
              children: [
                AppTextButton(
                  label: MaterialLocalizations.of(context).cancelButtonLabel,
                  onPressed: () => Navigator.pop(context),
                  isFullWidth: false,
                ),
                AppElevatedButton(
                  label: loc.apply,
                  onPressed: () => Navigator.pop(
                    context,
                    CoffeeBeansSortOptions(
                      sortOption: _selectedOption,
                      sortDirection: _selectedDirection,
                    ),
                  ),
                  isFullWidth: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
