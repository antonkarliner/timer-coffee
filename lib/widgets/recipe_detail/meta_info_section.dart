import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

/// Shows recipe meta information: water temperature (°C/°F) and brew time.
class MetaInfoSection extends StatelessWidget {
  final double? waterTempCelsius;
  final Duration? brewTime;

  const MetaInfoSection({
    super.key,
    required this.waterTempCelsius,
    required this.brewTime,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final String? waterC = waterTempCelsius?.toStringAsFixed(1);
    final String? waterF = waterTempCelsius != null
        ? (((waterTempCelsius! * 9 / 5) + 32).toStringAsFixed(1))
        : null;

    final String formattedBrewTime = brewTime != null
        ? '${brewTime!.inMinutes.remainder(60).toString().padLeft(2, '0')}:${brewTime!.inSeconds.remainder(60).toString().padLeft(2, '0')}'
        : loc.notProvided;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (waterC != null && waterF != null) ...[
          Text('${loc.watertemp}: $waterC°C / $waterF°F'),
          const SizedBox(height: 16),
        ],
        Text('${loc.brewtime}: $formattedBrewTime'),
      ],
    );
  }
}
