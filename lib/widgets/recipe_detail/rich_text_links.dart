import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Stateful widget that renders simple markdown-like links [text](url).
/// It intentionally contains no business logic; consumers should handle
/// link launching via the provided onTapUrl callback.
/// Properly disposes of TapGestureRecognizer to fix Android link issues.
class RichTextLinks extends StatefulWidget {
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
  State<RichTextLinks> createState() => _RichTextLinksState();
}

class _RichTextLinksState extends State<RichTextLinks> {
  // Keep track of TapGestureRecognizers to properly dispose of them
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    // Clean up all recognizers when widget is disposed
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RegExp linkRegExp = RegExp(r'\[(.*?)\]\((.*?)\)');
    final Iterable<RegExpMatch> matches = linkRegExp.allMatches(widget.text);

    final TextStyle defaultTextStyle =
        widget.style ?? Theme.of(context).textTheme.bodyLarge!;
    final Color linkColor = Theme.of(context).colorScheme.secondary;

    final List<TextSpan> spanList = <TextSpan>[];

    int lastMatchEnd = 0;

    for (final match in matches) {
      final String precedingText =
          widget.text.substring(lastMatchEnd, match.start);
      final String linkText = match.group(1)!;
      final String linkUrl = match.group(2)!;

      if (precedingText.isNotEmpty) {
        spanList.add(TextSpan(text: precedingText, style: defaultTextStyle));
      }

      // Create a new TapGestureRecognizer and track it for disposal
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          final uri = Uri.tryParse(linkUrl);
          if (uri != null) {
            widget.onTapUrl?.call(uri);
          }
        };
      _recognizers.add(recognizer);

      spanList.add(
        TextSpan(
          text: linkText,
          style: defaultTextStyle.copyWith(color: linkColor),
          recognizer: recognizer,
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < widget.text.length) {
      spanList.add(
        TextSpan(
          text: widget.text.substring(lastMatchEnd),
          style: defaultTextStyle,
        ),
      );
    }

    return RichText(text: TextSpan(children: spanList));
  }
}
