import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
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

    // Filter out technical keys from being displayed to the user.
    // Only 'meta' is dropped here, before the possible unwrap below — the
    // wrapped-payload shape ({ "0": { ... } }) puts the fields we actually
    // care about one level down, so filtering by key at this stage would
    // miss them entirely for a wrapped payload.
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

    // roastDateRawText/roastDateNeedsConfirmation (plan 051) are internal
    // signals consumed by DatesCard's confirmation hint UI, not
    // user-facing fields in their own right — but this dialog now surfaces
    // the same confirmation hint inline under the "Roast Date" row (the
    // form-level hint sits below the fold and is easy to miss). Read the
    // values from `display` — i.e. AFTER the unwrap above, so a wrapped
    // payload's flags aren't silently lost — then strip the two raw keys
    // so they never render as their own rows (unmapped, they'd render
    // literally as "roastDateRawText:").
    // Type-checked rather than cast: the parser is an LLM, so a label
    // printing "0208" can come back as a number. A failed cast here would
    // throw inside build() and take the whole scan flow down.
    final roastDateRawText = display['roastDateRawText']?.toString();
    final roastDateNeedsConfirmation =
        display['roastDateNeedsConfirmation'] == true;
    display = Map<String, dynamic>.from(display)
      ..remove('roastDateRawText')
      ..remove('roastDateNeedsConfirmation');

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
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.25,
        );
    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          height: 1.25,
        );

    String labelFor(String key) {
      // Keep internal keys intact; only adjust presentation
      if (key == 'processingMethod') return loc.processingMethod;
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

            // Only the roastDate row gets the inline confirmation hint, and
            // only when the server actually flagged it — this is not an
            // error state, so it reuses the same info-outline/primary-color
            // treatment as DatesCard's own hint (see
            // dates_card.dart:_buildRoastDateHint), never red/warning.
            final showRoastDateHint =
                key == 'roastDate' && roastDateNeedsConfirmation;

            final labelAndValue = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label: fixed min/max width box to prevent awkward wrapping
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: labelMinWidth,
                    maxWidth: labelMaxWidth,
                  ),
                  child: Text(
                    '${labelFor(key)}:',
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
            );

            if (!showRoastDateHint) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: labelAndValue,
              );
            }

            // The hint spans the FULL dialog width, beneath the label/value
            // row rather than inside the value column. The label column
            // reserves up to 220dp, which leaves the value cell too narrow
            // for a sentence — on an iPhone 17 Pro the hint wrapped onto
            // five lines when it lived there.
            final hasRawText =
                roastDateRawText != null && roastDateRawText.trim().isNotEmpty;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  labelAndValue,
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: AppIconSize.small,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          hasRawText
                              ? loc.roastDateConfirmPrompt(roastDateRawText)
                              : loc.roastDateNotFound,
                          style: AppTextStyles.caption.copyWith(
                            color: colorScheme.primary,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
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
