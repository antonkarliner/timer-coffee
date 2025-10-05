import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/coffee_beans_filter_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

/// Dialog for selecting multiple roasters from a list.
///
/// This dialog displays a list of available roasters with checkboxes,
/// allowing users to select multiple roasters for filtering.
/// It uses the CoffeeBeansFilterService to fetch available roasters.
class RoasterSelectionDialog extends StatefulWidget {
  /// List of currently selected roasters
  final List<String> selectedRoasters;

  /// List of available roasters to choose from
  final List<String> availableRoasters;

  const RoasterSelectionDialog({
    Key? key,
    required this.selectedRoasters,
    required this.availableRoasters,
  }) : super(key: key);

  @override
  State<RoasterSelectionDialog> createState() => _RoasterSelectionDialogState();
}

class _RoasterSelectionDialogState extends State<RoasterSelectionDialog> {
  late List<String> _tempSelectedRoasters;

  @override
  void initState() {
    super.initState();
    _tempSelectedRoasters = List.from(widget.selectedRoasters);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(
        loc.selectRoaster,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Container(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.availableRoasters.map((roaster) {
            return CheckboxListTile(
              title: Text(
                roaster,
                style: AppTextStyles.caption,
              ),
              value: _tempSelectedRoasters.contains(roaster),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    if (!_tempSelectedRoasters.contains(roaster)) {
                      _tempSelectedRoasters.add(roaster);
                    }
                  } else {
                    _tempSelectedRoasters.remove(roaster);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
          child: Text(
            loc.cancel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
          child: Text(
            loc.ok,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () {
            Navigator.pop(context, _tempSelectedRoasters);
          },
        ),
      ],
    );
  }
}
