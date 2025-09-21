import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/coffee_beans_filter_service.dart';
import '../../glass_container.dart';

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
                  loc.selectOrigin,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: headingColor,
                      ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView(
                  shrinkWrap: true,
                  children: widget.availableOrigins.map((origin) {
                    return CheckboxListTile(
                      title: Text(
                        origin,
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
                        Navigator.pop(context, _tempSelectedOrigins),
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
