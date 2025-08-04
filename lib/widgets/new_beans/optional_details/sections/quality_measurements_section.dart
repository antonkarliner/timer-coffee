import 'package:flutter/material.dart';
import 'package:coffee_timer/widgets/new_beans/section_header.dart';
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
  late final TextEditingController _elevationController;
  late final TextEditingController _cuppingScoreController;

  @override
  void initState() {
    super.initState();
    _elevationController = TextEditingController(
      text: widget.elevation != null ? widget.elevation.toString() : '',
    );
    _cuppingScoreController = TextEditingController(
      text: widget.cuppingScore != null ? widget.cuppingScore.toString() : '',
    );
  }

  @override
  void didUpdateWidget(covariant QualityMeasurementsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controllers when external values changed.
    if (oldWidget.elevation != widget.elevation) {
      final newText =
          widget.elevation != null ? widget.elevation.toString() : '';
      if (_elevationController.text != newText) {
        _elevationController.value = _elevationController.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
          composing: TextRange.empty,
        );
      }
    }
    if (oldWidget.cuppingScore != widget.cuppingScore) {
      final newText =
          widget.cuppingScore != null ? widget.cuppingScore.toString() : '';
      if (_cuppingScoreController.text != newText) {
        _cuppingScoreController.value = _cuppingScoreController.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
          composing: TextRange.empty,
        );
      }
    }
  }

  @override
  void dispose() {
    _elevationController.dispose();
    _cuppingScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(icon: Icons.star, title: loc.qualityMeasurements),
        const SizedBox(height: 8),
        Semantics(
          identifier: 'elevationInputField',
          label: loc.enterElevation,
          child: TextFormField(
            controller: _elevationController,
            decoration: InputDecoration(
              labelText: loc.elevation,
              hintText: loc.enterElevation,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              widget.onElevationChanged(
                  value.isNotEmpty ? int.tryParse(value) : null);
            },
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          identifier: 'cuppingScoreInputField',
          label: loc.enterCuppingScore,
          child: TextFormField(
            controller: _cuppingScoreController,
            decoration: InputDecoration(
              labelText: loc.cuppingScore,
              hintText: loc.enterCuppingScore,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              widget.onCuppingScoreChanged(
                  value.isNotEmpty ? double.tryParse(value) : null);
            },
          ),
        ),
      ],
    );
  }
}
