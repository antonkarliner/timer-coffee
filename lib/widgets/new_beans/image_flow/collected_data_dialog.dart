import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';

class CollectedDataDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(String key) humanizeKey;

  const CollectedDataDialog({
    super.key,
    required this.data,
    required this.humanizeKey,
  });

  String _fmtValue(dynamic v) {
    if (v == null) return 'N/A';
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? 'N/A' : t;
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Filter out technical keys from being displayed to the user
    final filtered = Map<String, dynamic>.from(data)..remove('meta');

    // If server accidentally wraps parsed object in a container like { "0": { ... } }, unwrap for display
    Map<String, dynamic> display = filtered;
    if (filtered.length == 1 && filtered.values.first is Map) {
      final onlyKey = filtered.keys.first;
      final onlyVal = filtered.values.first as Map;
      if (onlyKey == '0' || onlyKey == 'data' || onlyKey == 'result') {
        display = Map<String, dynamic>.from(onlyVal);
      }
    }

    // Stable order improves readability
    final preferredOrder = <String>[
      'roaster',
      'name',
      'origin',
      'farm',
      'farmer',
      'variety',
      'processingMethod',
      'elevation',
      'harvestDate',
      'roastDate',
      'region',
      'roastLevel',
      'cuppingScore',
      'tastingNotes',
      'notes',
    ];

    final keys = [
      ...preferredOrder.where((k) => display.containsKey(k)),
      ...display.keys.where((k) => !preferredOrder.contains(k)),
    ];

    // Compact, consistent list item styling
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.25,
        );
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          height: 1.25,
        );

    String _labelFor(String key) {
      // Keep internal keys intact; only adjust presentation
      if (key == 'processingMethod') return 'Processing Method';
      return humanizeKey(key);
    }

    // Layout tweaks to keep long labels like Processing Method on a single row
    const double labelMinWidth = 160; // ensures single-line for common locales
    const double labelMaxWidth = 220; // cap to avoid stealing too much space

    return AlertDialog(
      title: Text(loc.collectedInformation),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: keys.map((key) {
            final baseValue = _fmtValue(display[key]);
            String displayValue = baseValue;
            if (key == 'packageWeightGrams' && baseValue != 'N/A') {
              displayValue = '$baseValue ${loc.unitGramsShort}';
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label: fixed min/max width box to prevent awkward wrapping
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: labelMinWidth,
                      maxWidth: labelMaxWidth,
                    ),
                    child: Text(
                      '${_labelFor(key)}:',
                      style: labelStyle,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Value
                  Expanded(
                    child: Text(
                      displayValue,
                      style: valueStyle,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: AppElevatedButton(
            label: loc.ok,
            onPressed: () => Navigator.pop(context),
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}
