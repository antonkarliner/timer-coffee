import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/coffee_beans_filter_service.dart';
import '../../glass_container.dart';

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
    final Color controlColor = (glassForeground ??
            Theme.of(context).colorScheme.primary)
        .withOpacity(isIos ? 0.9 : 1.0);
    final Color checkMarkColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.black
        : Colors.white;

    return AlertDialog(
      backgroundColor: Platform.isIOS ? Colors.transparent : null,
      content: GlassContainer(
        padding: EdgeInsets.zero,
        foregroundColor: glassForeground,
        child: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  loc.selectRoaster,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: headingColor,
                      ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView(
                  shrinkWrap: true,
                  children: widget.availableRoasters.map((roaster) {
                    return CheckboxListTile(
                      title: Text(
                        roaster,
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
                      activeColor: controlColor,
                      checkColor: checkMarkColor,
                    );
                  }).toList(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: Text(
                      loc.cancel,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    child: Text(
                      loc.ok,
                    ),
                    onPressed: () =>
                        Navigator.pop(context, _tempSelectedRoasters),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
