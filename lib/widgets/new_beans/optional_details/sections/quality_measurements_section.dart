import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';
import 'package:coffee_timer/widgets/fields/numeric_text_field.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class QualityMeasurementsSection extends StatefulWidget {
  final int? elevation;
  final double? cuppingScore;

  final ValueChanged<int?> onElevationChanged;
  final ValueChanged<double?> onCuppingScoreChanged;

  const QualityMeasurementsSection({
    super.key,
    this.elevation,
    this.cuppingScore,
    required this.onElevationChanged,
    required this.onCuppingScoreChanged,
  });

  @override
  State<QualityMeasurementsSection> createState() =>
      _QualityMeasurementsSectionState();
}

class _QualityMeasurementsSectionState
    extends State<QualityMeasurementsSection> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Elevation Field
        LabeledField(
          label: loc.elevation,
          hintText: loc.enterElevation,
          initialValue: widget.elevation?.toString(),
          keyboardType: TextInputType.text,
          semanticIdentifier: 'elevationInputField',
          onChanged: (value) {
            // Parse the elevation value, allowing for text input
            if (value.isEmpty) {
              widget.onElevationChanged(null);
            } else {
              // Extract numbers from the text
              final numericValue = int.tryParse(
                  RegExp(r'\d+').firstMatch(value)?.group(0) ?? '');
              widget.onElevationChanged(numericValue);
            }
          },
        ),

        const SizedBox(height: AppSpacing.fieldGap),

        // Cupping Score Field
        NumericTextField(
          label: loc.cuppingScore,
          hintText: loc.enterCuppingScore,
          initialValue: widget.cuppingScore,
          allowDecimal: true,
          maxDecimalPlaces: 1,
          min: 0,
          max: 100,
          semanticIdentifier: 'cuppingScoreInputField',
          onChanged: (value) {
            widget.onCuppingScoreChanged(value);
          },
          onSubmitted: (value) {
            widget.onCuppingScoreChanged(value);
          },
        ),
      ],
    );
  }
}
