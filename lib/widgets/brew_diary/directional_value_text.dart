import 'package:flutter/material.dart';

/// Renders literal values in their natural left-to-right order inside both
/// LTR and RTL interfaces while leaving the surrounding layout directionally
/// aware.
class DirectionalValueText extends StatelessWidget {
  const DirectionalValueText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: softWrap,
      textDirection: TextDirection.ltr,
    );
  }
}
