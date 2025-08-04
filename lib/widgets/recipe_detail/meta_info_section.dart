import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

/// Shows recipe meta information: water temperature (°C/°F), grind size, and brew time.
class MetaInfoSection extends StatelessWidget {
  final double? waterTempCelsius;
  final String grindSize;
  final Duration? brewTime;

  const MetaInfoSection({
    Key? key,
    required this.waterTempCelsius,
    required this.grindSize,
    required this.brewTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final String waterC =
        waterTempCelsius?.toStringAsFixed(1) ?? loc.notProvided;
    final String waterF = waterTempCelsius != null
        ? (((waterTempCelsius! * 9 / 5) + 32).toStringAsFixed(1))
        : loc.notProvided;

    final String formattedBrewTime = brewTime != null
        ? '${brewTime!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${brewTime!.inSeconds.remainder(60).toString().padLeft(2, '0')}'
        : loc.notProvided;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${loc.watertemp}: $waterCºC / $waterFºF'),
        const SizedBox(height: 16),
        Text('${loc.grindsize}: $grindSize'),
        const SizedBox(height: 16),
        Text('${loc.brewtime}: $formattedBrewTime'),
      ],
    );
  }
}
