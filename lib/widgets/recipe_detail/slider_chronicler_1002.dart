import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

class CoffeeChroniclerSizeSlider extends StatelessWidget {
  final int position; // 0 = Standard, 1 = Medium, 2 = XL
  final ValueChanged<int> onChanged;

  // Optional: when amounts should be updated externally, the parent can
  // listen to position changes and map it to amounts.
  const CoffeeChroniclerSizeSlider({
    Key? key,
    required this.position,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final List<String> sizeLabels = <String>[
      localizations.sizeStandard,
      localizations.sizeMedium,
      localizations.sizeXL,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.selectSize),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(localizations.sizeStandard),
            Expanded(
              child: Slider(
                value: position.toDouble(),
                min: 0,
                max: 2,
                divisions: 2,
                label: sizeLabels[position],
                onChanged: (double value) => onChanged(value.toInt()),
              ),
            ),
            Text(localizations.sizeXL),
          ],
        ),
      ],
    );
  }
}
