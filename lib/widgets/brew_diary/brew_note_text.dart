import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// `linkify` is the pure-Dart URL parser; we build the TextSpan ourselves.
// Do NOT "simplify" this to flutter_linkify's `Linkify`/`SelectableLinkify`
// widgets — as of 5.0.2 they still reference the removed Material 2
// `TextTheme.bodyText2` getter and fail to compile against the Flutter SDK
// pinned in this project.
import 'package:linkify/linkify.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders brew-diary note text with tappable URLs.
///
/// PRIVATE-CONTENT ONLY. Brew notes have an audience of exactly one — the
/// author, who typed the note (and any URL in it) themselves on this
/// account. That is what makes linkifying them safe: there is no one to
/// protect from a malicious link who didn't write it. See plan 036, Phase 3.
///
/// Do NOT use this widget for anything with a wider audience — bean
/// reviews, public recipes, roaster content, review replies, or any other
/// user-published or server-supplied text. Those stay inert (plain `Text`)
/// deliberately, because they carry real moderation risk. Do not add a
/// `linkify: true` escape hatch to a shared widget as a shortcut for reusing
/// this behaviour there: if a future feature (e.g. "share this brew") needs
/// to render this text to a wider audience, build a second, separate
/// widget for that surface rather than reusing this one.
///
/// This widget must only ever be given text the local user authored
/// themselves (see `brew_entry_card.dart`/`brew_detail_sheet.dart`'s
/// `entry.notes`, which is only ever written via the diary's own
/// note-editing flow) — never text sourced from another user or from a
/// server-generated field.
class BrewNoteText extends StatelessWidget {
  const BrewNoteText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    // Defaults to Flutter's own `clip`, NOT `ellipsis`: the primary reader of
    // a note is the detail sheet, which must show it in full. An `ellipsis`
    // default silently truncated the detail sheet to a single line (caught on
    // an iPhone 17 Pro simulator) — truncation is opt-in, and callers that
    // want it pass `maxLines` + `overflow` together, as the diary card does.
    this.overflow = TextOverflow.clip,
  });

  /// The note text to render. Must be locally user-authored (see class doc).
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final linkColor = Theme.of(context).colorScheme.primary;
    final linkStyle = (style ?? const TextStyle()).copyWith(
      color: linkColor,
      decoration: TextDecoration.underline,
      decorationColor: linkColor,
    );
    // URLs only — brew notes shouldn't turn stray "@handle"-shaped text or
    // email-looking strings into mailto: links; the user asked for web
    // links to be tappable, nothing more. Strict (non-loose) matching means
    // only explicit `http(s)://` or `www.`-prefixed strings ever qualify,
    // so ordinary text containing a dot (e.g. "v60", "e.g.") is untouched.
    final elements = linkify(
      text,
      linkifiers: const [UrlLinkifier()],
      options: const LinkifyOptions(defaultToHttps: true),
    );

    return Text.rich(
      TextSpan(
        children: [
          for (final element in elements)
            if (element is LinkableElement)
              TextSpan(
                text: element.text,
                style: linkStyle,
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _open(element.url),
              )
            else
              TextSpan(text: element.text, style: style),
        ],
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  static Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
