import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Stateless widget that renders simple markdown-like links [text](url).
/// It intentionally contains no business logic; consumers should handle
/// link launching via the provided onTapUrl callback.
class RichTextLinks extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final void Function(Uri url)? onTapUrl;

  const RichTextLinks({
    Key? key,
    required this.text,
    this.style,
    this.onTapUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RegExp linkRegExp = RegExp(r'\[(.*?)\]\((.*?)\)');
    final Iterable<RegExpMatch> matches = linkRegExp.allMatches(text);

    final TextStyle defaultTextStyle =
        style ?? Theme.of(context).textTheme.bodyLarge!;
    final Color linkColor = Theme.of(context).colorScheme.secondary;

    final List<TextSpan> spanList = <TextSpan>[];

    int lastMatchEnd = 0;

    for (final match in matches) {
      final String precedingText = text.substring(lastMatchEnd, match.start);
      final String linkText = match.group(1)!;
      final String linkUrl = match.group(2)!;

      if (precedingText.isNotEmpty) {
        spanList.add(TextSpan(text: precedingText, style: defaultTextStyle));
      }

      spanList.add(
        TextSpan(
          text: linkText,
          style: defaultTextStyle.copyWith(color: linkColor),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              final uri = Uri.tryParse(linkUrl);
              if (uri != null) {
                onTapUrl?.call(uri);
              }
            },
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spanList.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: defaultTextStyle,
        ),
      );
    }

    return RichText(text: TextSpan(children: spanList));
  }
}
