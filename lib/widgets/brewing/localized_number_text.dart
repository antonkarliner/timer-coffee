import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

/// The brewing countdown's "elapsed/total" text (a backslash in RTL). Shared
/// by the brewing screen and the layout preview cards, so a preview reads
/// exactly like the screen it shows.
class LocalizedNumberText extends StatelessWidget {
  final int currentNumber;
  final int totalNumber;
  final TextStyle? style;

  const LocalizedNumberText({
    super.key,
    required this.currentNumber,
    required this.totalNumber,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    var isRTL = Directionality.of(context) == TextDirection.rtl;
    var formattedText = isRTL
        ? '${intl.NumberFormat().format(currentNumber)}\\${intl.NumberFormat().format(totalNumber)}'
        : '${intl.NumberFormat().format(currentNumber)}/${intl.NumberFormat().format(totalNumber)}';

    return Semantics(
      identifier: 'localizedNumberText_${currentNumber}_of_$totalNumber',
      child: Text(formattedText, style: style, textAlign: TextAlign.center),
    );
  }
}
