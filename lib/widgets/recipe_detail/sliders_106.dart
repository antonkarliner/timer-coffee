import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class SweetnessStrengthSliders extends StatelessWidget {
  final int sweetnessPosition;
  final int strengthPosition;
  final ValueChanged<int> onSweetnessChanged;
  final ValueChanged<int> onStrengthChanged;

  const SweetnessStrengthSliders({
    Key? key,
    required this.sweetnessPosition,
    required this.strengthPosition,
    required this.onSweetnessChanged,
    required this.onStrengthChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final List<String> sweetnessLabels = <String>[
      localizations.sweet,
      localizations.balance,
      localizations.acidic,
    ];
    final List<String> strengthLabels = <String>[
      localizations.light,
      localizations.balance,
      localizations.strong,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.slidertitle),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(localizations.sweet),
            Expanded(
              child: Slider(
                value: sweetnessPosition.toDouble(),
                min: 0,
                max: 2,
                divisions: 2,
                label: sweetnessLabels[sweetnessPosition],
                onChanged: (double value) {
                  onSweetnessChanged(value.toInt());
                },
              ),
            ),
            Text(localizations.acidic),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(localizations.light),
            Expanded(
              child: Slider(
                value: strengthPosition.toDouble(),
                min: 0,
                max: 2,
                divisions: 2,
                label: strengthLabels[strengthPosition],
                onChanged: (double value) {
                  onStrengthChanged(value.toInt());
                },
              ),
            ),
            Text(localizations.strong),
          ],
        ),
      ],
    );
  }
}
