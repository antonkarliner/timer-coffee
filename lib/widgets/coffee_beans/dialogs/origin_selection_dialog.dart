import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/coffee_beans_filter_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

/// Dialog for selecting multiple origins from a list.
///
/// This dialog displays a list of available origins with checkboxes,
/// allowing users to select multiple origins for filtering.
/// The available origins can be filtered based on selected roasters.
class OriginSelectionDialog extends StatefulWidget {
  /// List of currently selected origins
  final List<String> selectedOrigins;

  /// List of available origins to choose from
  final List<String> availableOrigins;

  const OriginSelectionDialog({
    Key? key,
    required this.selectedOrigins,
    required this.availableOrigins,
  }) : super(key: key);

  @override
  State<OriginSelectionDialog> createState() => _OriginSelectionDialogState();
}

class _OriginSelectionDialogState extends State<OriginSelectionDialog> {
  late List<String> _tempSelectedOrigins;

  @override
  void initState() {
    super.initState();
    _tempSelectedOrigins = List.from(widget.selectedOrigins);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(
        loc.selectOrigin,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Container(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.availableOrigins.map((origin) {
            return CheckboxListTile(
              title: Text(
                origin,
                style: AppTextStyles.caption,
              ),
              value: _tempSelectedOrigins.contains(origin),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    if (!_tempSelectedOrigins.contains(origin)) {
                      _tempSelectedOrigins.add(origin);
                    }
                  } else {
                    _tempSelectedOrigins.remove(origin);
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
            Navigator.pop(context, _tempSelectedOrigins);
          },
        ),
      ],
    );
  }
}
