import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/utils/diary_tags.dart';
import 'package:coffee_timer/utils/temperature_format.dart';
import 'package:intl/intl.dart';

/// Which slice of the brew diary [renderBrewMarkdown] should produce.
///
/// - [wholeDiary]: every entry, reverse-chronological, under a document
///   title with an export timestamp. Serves *backup* — complete, stable,
///   re-exportable so a user diffing two exports sees only real changes.
/// - [singleBrew]: exactly one entry, no document title, no export
///   timestamp. Serves *sharing* — short and self-contained enough to paste
///   into a message or forum post.
/// - [byBean]: every entry grouped under a heading per bean (roaster +
///   name), reverse-chronological within each group.
enum BrewExportScope { wholeDiary, singleBrew, byBean }

/// Date/time formatting inputs, resolved by the caller.
///
/// This service is pure — no `BuildContext`, no `AppLocalizations` — so it
/// cannot itself consult [DateTimeFormatService]. Per the project's
/// mandatory date/time rule, the caller resolves the user's preferred date
/// pattern and 24-hour flag (via `DateTimeFormatService.datePattern` /
/// `.use24Hour`) and passes the result in here.
class BrewExportFormats {
  const BrewExportFormats({
    required this.datePattern,
    required this.use24HourTime,
  });

  /// An [DateFormat]-compatible pattern for the date portion, e.g.
  /// `'yyyy-MM-dd'` or a locale default such as `'MMM d, yyyy'`.
  final String datePattern;

  /// Whether to render times as `HH:mm` (true) or `hh:mm a` (false).
  final bool use24HourTime;

  String _formatTime(DateTime dateTime) =>
      DateFormat(use24HourTime ? 'HH:mm' : 'hh:mm a').format(dateTime);

  /// Date-only formatting, used for the whole-diary day dividers (each
  /// divider groups every brew from that calendar day, so it carries no
  /// time).
  String formatDate(DateTime dateTime) =>
      DateFormat(datePattern).format(dateTime);

  String formatDateTime(DateTime dateTime) =>
      '${formatDate(dateTime)} · ${_formatTime(dateTime)}';
}

/// Pre-resolved, localized copy the renderer needs for headings and field
/// labels. Keeping this a plain value object (rather than reaching for
/// `AppLocalizations` inside the service) is what lets [renderBrewMarkdown]
/// stay pure and trivially testable; the UI-facing caller is responsible for
/// resolving every field from `AppLocalizations` before calling in.
class BrewExportLabels {
  const BrewExportLabels({
    required this.documentTitle,
    required this.exportedOnLabel,
    required this.dateLabel,
    required this.beansLabel,
    required this.ratingLabel,
    required this.coffeeToWaterLabel,
    required this.grindSizeLabel,
    required this.waterTempLabel,
    required this.tdsLabel,
    required this.extractionYieldLabel,
    required this.tasteLabel,
    required this.tasteBalanceLabels,
    required this.tagsLabel,
    required this.notesLabel,
    required this.noBeanGroupLabel,
    required this.originLabel,
    required this.bookmarkLabel,
  });

  /// H1 title for [BrewExportScope.wholeDiary], e.g. "Timer.Coffee Brew
  /// Diary".
  final String documentTitle;

  /// Prefix for the export-timestamp line under the document title, e.g.
  /// "Exported".
  final String exportedOnLabel;

  /// Field label for the brew's own date/time. Only shown for
  /// [BrewExportScope.singleBrew] — the other scopes carry the date/time in
  /// the entry's heading instead, so a duplicate field line would be noise.
  final String dateLabel;

  /// Field label for the combined bean name + roaster line.
  final String beansLabel;
  final String ratingLabel;

  /// Field label for the coffee → water amounts line, e.g. "Dose → Water".
  final String coffeeToWaterLabel;
  final String grindSizeLabel;
  final String waterTempLabel;
  final String tdsLabel;
  final String extractionYieldLabel;

  /// Field label for the taste-balance line (the value itself comes from
  /// [tasteBalanceLabels]).
  final String tasteLabel;

  /// Display labels for `tasteBalance`, indexed the same way the value is
  /// stored: index 0 = sour (-1), index 1 = balanced (0), index 2 = bitter
  /// (1). Mirrors the `tasteLabels` parameter already used by
  /// `BrewEntryCard`.
  final List<String> tasteBalanceLabels;
  final String tagsLabel;

  /// Mini-heading printed just above the notes blockquote.
  final String notesLabel;

  /// Heading used for [BrewExportScope.byBean] entries that have no bean
  /// name and no roaster on record.
  final String noBeanGroupLabel;

  /// Field label for [DiaryEntry.origin].
  final String originLabel;

  /// Field label emitted only when [DiaryEntry.isMarked] is true — there is
  /// no "unmarked" counterpart line, so this doubles as the flag's own text
  /// (e.g. "Bookmarked").
  final String bookmarkLabel;
}

/// Renders a list of [DiaryEntry] brews to a markdown document.
///
/// Pure by design: no I/O, no `share_plus`, no `BuildContext`. This is what
/// makes the renderer trivially unit-testable and keeps date/localization
/// concerns explicit (see [BrewExportFormats] / [BrewExportLabels]) rather
/// than implicit globals. [DiaryEntry] itself is a plain data model (its only
/// import is `diary_tags.dart`), so taking it directly keeps the renderer
/// pure while giving it everything it needs — including `recipeName` /
/// `methodName`, which the old `UserStatsModel`-based renderer never saw.
///
/// Ordering is always reverse-chronological by `createdAt`, with `statUuid`
/// as a deterministic tiebreaker for equal timestamps — never relying on
/// input order or sort stability — so re-exporting the same data always
/// produces byte-identical output (aside from [exportedAt] itself, which is
/// only rendered for [BrewExportScope.wholeDiary]).
///
/// [BrewExportScope.wholeDiary] additionally groups brews under a `##` day
/// divider (calendar day, no time — see [BrewExportFormats.formatDate]),
/// itself ordered reverse-chronologically, with brews reverse-chronological
/// within a day. [BrewExportScope.byBean] has no day dividers — grouping
/// there is by bean.
///
/// Every per-brew heading (`###` in [BrewExportScope.wholeDiary], `##` in
/// [BrewExportScope.byBean], `#` in [BrewExportScope.singleBrew] since it has
/// no document title above it) is "recipe · method", escaped like any other
/// user-authored text. When `recipeName` or `methodName` is blank, whichever
/// exists is used alone; when both are blank, the heading falls back to the
/// brew's own formatted date/time rather than a raw (meaningless) id.
///
/// Null/empty fields are omitted entirely rather than rendered as empty or
/// "null" — see `_fieldLines`. Every user-authored string (`notes`,
/// `beanName`, `roaster`, `origin`, `recipeName`, `methodName`, tag values)
/// is escaped so it cannot break the surrounding markdown structure — see
/// `_escapeInline` / `_escapeNotesLine`. Escaping `recipeName`/`methodName`
/// matters more than most: they land directly in a `#`-prefixed heading, so
/// an unescaped `#` in a recipe name would silently promote/demote the
/// document structure around it.
String renderBrewMarkdown({
  required List<DiaryEntry> entries,
  required BrewExportScope scope,
  required BrewExportFormats formats,
  required BrewExportLabels labels,
  required DateTime exportedAt,
}) {
  assert(
    scope != BrewExportScope.singleBrew || entries.length <= 1,
    'BrewExportScope.singleBrew renders a single entry; callers should pass '
    'exactly one. Only the first entry of $entries would be used.',
  );

  switch (scope) {
    case BrewExportScope.singleBrew:
      if (entries.isEmpty) return '';
      return _renderSingleBrew(entries.first, formats, labels);
    case BrewExportScope.wholeDiary:
      return _renderWholeDiary(entries, formats, labels, exportedAt);
    case BrewExportScope.byBean:
      return _renderByBean(entries, formats, labels);
  }
}

// ---------------------------------------------------------------------------
// Scope renderers
// ---------------------------------------------------------------------------

/// Single-brew shape: no document title, no export timestamp, no day
/// divider — this is the "paste into a message" shape, not the backup shape.
/// Leads with the recipe · method heading (falling back to the date when
/// both are blank — see [_entryHeading]), then keeps the existing
/// `**Date:**` field line beneath it.
String _renderSingleBrew(
  DiaryEntry entry,
  BrewExportFormats formats,
  BrewExportLabels labels,
) {
  final lines = <String>[
    '# ${_entryHeading(entry, formats)}',
    '',
    '- **${labels.dateLabel}:** ${formats.formatDateTime(entry.createdAt)}',
    ..._fieldLines(entry, formats, labels),
  ];
  final body = StringBuffer(lines.join('\n'));
  final notes = _notesBlock(entry.notes, labels);
  if (notes != null) {
    body
      ..write('\n\n')
      ..write(notes);
  }
  return body.toString();
}

/// Whole-diary shape: a document title + export timestamp, then `##` day
/// dividers (reverse-chronological, date only — no time, since the divider
/// covers every brew from that calendar day), each containing its brews
/// (reverse-chronological) under a `###` recipe · method heading.
String _renderWholeDiary(
  List<DiaryEntry> entries,
  BrewExportFormats formats,
  BrewExportLabels labels,
  DateTime exportedAt,
) {
  final buffer = StringBuffer()
    ..writeln('# ${labels.documentTitle}')
    ..writeln()
    ..writeln(
      '_${labels.exportedOnLabel} ${formats.formatDateTime(exportedAt)}_',
    );

  for (final day in _groupByDay(entries)) {
    buffer
      ..writeln()
      ..writeln()
      ..writeln('## ${formats.formatDate(day.date)}');

    for (final entry in day.entries) {
      buffer
        ..writeln()
        ..writeln()
        ..write(_entryBlock(entry, formats, labels, '###'));
    }
  }

  return buffer.toString();
}

/// By-bean shape: keeps the existing `#` per-bean group heading (roaster +
/// name), but each brew inside a group now renders under a `##` recipe ·
/// method heading (one level below the group heading) instead of a bare
/// date. No day dividers here — grouping is by bean, not by calendar day.
String _renderByBean(
  List<DiaryEntry> entries,
  BrewExportFormats formats,
  BrewExportLabels labels,
) {
  if (entries.isEmpty) return '';

  final groups = _groupByBean(entries, labels);
  final buffer = StringBuffer();
  for (var i = 0; i < groups.length; i++) {
    final group = groups[i];
    if (i > 0) buffer.writeln();
    buffer
      ..writeln('# ${group.heading}')
      ..writeln();

    final sorted = _sortedReverseChronological(group.entries);
    for (var j = 0; j < sorted.length; j++) {
      if (j > 0) buffer.writeln();
      buffer.write(_entryBlock(sorted[j], formats, labels, '##'));
    }
  }
  return buffer.toString();
}

// ---------------------------------------------------------------------------
// Shared entry rendering
// ---------------------------------------------------------------------------

/// Renders one brew as `$headingPrefix recipe · method`, an italic full
/// date/time line, then the field-bullet list and (if present) the notes
/// blockquote. Shared by [BrewExportScope.wholeDiary] (`###`) and
/// [BrewExportScope.byBean] (`##`); [BrewExportScope.singleBrew] builds its
/// own block (it substitutes a "Date" field line for the italic date/time
/// line — see [_renderSingleBrew]).
String _entryBlock(
  DiaryEntry entry,
  BrewExportFormats formats,
  BrewExportLabels labels,
  String headingPrefix,
) {
  final buffer = StringBuffer()
    ..writeln('$headingPrefix ${_entryHeading(entry, formats)}')
    ..writeln()
    ..writeln('_${formats.formatDateTime(entry.createdAt)}_')
    ..writeln()
    ..write(_entryBody(entry, formats, labels));
  return buffer.toString();
}

/// The "recipe · method" heading text for one brew, escaped like any other
/// user-authored string (it lands directly in a markdown heading). When one
/// of the two names is blank, the other is used alone; when both are blank,
/// falls back to the brew's formatted date/time rather than emitting a raw,
/// meaningless id.
String _entryHeading(DiaryEntry entry, BrewExportFormats formats) {
  final parts = [entry.recipeName, entry.methodName]
      .where((value) => value.trim().isNotEmpty)
      .map((value) => _escapeInline(value.trim()))
      .toList();
  if (parts.isEmpty) return formats.formatDateTime(entry.createdAt);
  return parts.join(' · ');
}

/// Renders the field-bullet list and (if present) the notes blockquote for
/// one entry.
String _entryBody(
  DiaryEntry entry,
  BrewExportFormats formats,
  BrewExportLabels labels,
) {
  final buffer = StringBuffer(_fieldLines(entry, formats, labels).join('\n'));
  final notes = _notesBlock(entry.notes, labels);
  if (notes != null) {
    buffer
      ..writeln()
      ..writeln()
      ..write(notes);
  }
  buffer.writeln();
  return buffer.toString();
}

/// Builds the `- **Label:** value` bullet lines for one entry, omitting any
/// field that is null or blank. Order mirrors `BrewEntryCard`'s fact-chip
/// row where practical: bean identity (name · roaster, then origin) leads,
/// followed by the bookmark flag (only when set), then rating, then the
/// brew's own measurements.
List<String> _fieldLines(
  DiaryEntry entry,
  BrewExportFormats formats,
  BrewExportLabels labels,
) {
  final lines = <String>[];

  final beanLine = [entry.beanName, entry.roaster]
      .where((value) => value?.trim().isNotEmpty ?? false)
      .map((value) => _escapeInline(value!.trim()))
      .join(' · ');
  if (beanLine.isNotEmpty) {
    lines.add('- **${labels.beansLabel}:** $beanLine');
  }

  if (entry.origin?.trim().isNotEmpty ?? false) {
    lines.add(
      '- **${labels.originLabel}:** ${_escapeInline(entry.origin!.trim())}',
    );
  }

  if (entry.isMarked) {
    lines.add('- **${labels.bookmarkLabel}**');
  }

  if (entry.rating case final rating?) {
    lines.add('- **${labels.ratingLabel}:** ★ ${rating.toStringAsFixed(1)}');
  }

  // Plain ASCII spaces before the unit, NOT the non-breaking space (U+00A0)
  // this used to use. A NBSP reads well on screen (it stops "25" and "g"
  // splitting across lines) but is wrong in a plain-text file: it is an
  // invisible character that surprises anyone who greps or diffs the export,
  // and it was by far the most common non-ASCII byte in the output — which
  // made a mis-decoded export look far more broken than it actually was.
  lines.add(
    '- **${labels.coffeeToWaterLabel}:** '
    '${_formatAmount(entry.coffeeAmount)} g → '
    '${_formatAmount(entry.waterAmount)} g',
  );

  if (entry.grindSize?.trim().isNotEmpty ?? false) {
    lines.add(
      '- **${labels.grindSizeLabel}:** ${_escapeInline(entry.grindSize!.trim())}',
    );
  }

  if (formatTemperatureDual(entry.waterTemp) case final temp?) {
    lines.add('- **${labels.waterTempLabel}:** $temp');
  }

  if (entry.tdsPercent case final tds?) {
    lines.add('- **${labels.tdsLabel}:** ${tds.toStringAsFixed(2)}%');
  }

  if (entry.extractionYieldPercent case final ey?) {
    lines.add(
      '- **${labels.extractionYieldLabel}:** ${ey.toStringAsFixed(1)}%',
    );
  }

  if (entry.tasteBalance case final taste?) {
    final label = switch (taste) {
      <= -1 => labels.tasteBalanceLabels[0],
      0 => labels.tasteBalanceLabels[1],
      _ => labels.tasteBalanceLabels[2],
    };
    lines.add('- **${labels.tasteLabel}:** $label');
  }

  final tags = diaryTagsFromStorage(entry.tags);
  if (tags.isNotEmpty) {
    final tagText = tags.map((tag) => '#${_escapeInline(tag)}').join(', ');
    lines.add('- **${labels.tagsLabel}:** $tagText');
  }

  return lines;
}

/// Renders `notes` as a markdown blockquote, or returns null when there is
/// nothing to show. Each line is escaped independently so multi-line notes
/// survive intact and cannot smuggle in block-level markdown (headings,
/// list markers, nested blockquotes) via a line that happens to start with
/// a control character.
String? _notesBlock(String? notes, BrewExportLabels labels) {
  final trimmed = notes?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  final quoted = trimmed
      .split('\n')
      .map((line) => line.trimRight())
      .map(_escapeNotesLine)
      .map((line) => line.isEmpty ? '>' : '> $line')
      .join('\n');

  return '**${labels.notesLabel}**\n$quoted';
}

// ---------------------------------------------------------------------------
// Grouping / sorting
// ---------------------------------------------------------------------------

class _BeanGroup {
  _BeanGroup(this.key, this.heading, this.entries);

  final String key;
  final String heading;
  final List<DiaryEntry> entries;
}

/// Groups entries by bean, keyed by `coffeeBeansUuid` when present (falling
/// back to the roaster/name text so entries without a linked bean record
/// still group sensibly) and heading them "Roaster · Bean name" — see the
/// plan's "roaster + name" wording. Entries with neither a linked bean nor
/// bean/roaster text collect under [BrewExportLabels.noBeanGroupLabel].
///
/// Groups are ordered by their most recent brew (descending), tie-broken by
/// heading text and then group key, so the ordering is fully deterministic
/// regardless of input order.
List<_BeanGroup> _groupByBean(
  List<DiaryEntry> entries,
  BrewExportLabels labels,
) {
  final byKey = <String, List<DiaryEntry>>{};
  for (final entry in entries) {
    final key =
        entry.coffeeBeansUuid ??
        'text:${(entry.roaster ?? '').trim().toLowerCase()}'
            '|${(entry.beanName ?? '').trim().toLowerCase()}';
    byKey.putIfAbsent(key, () => []).add(entry);
  }

  final groups = byKey.entries.map((mapEntry) {
    final groupEntries = mapEntry.value;
    final sample = groupEntries.first;
    final headingText = [sample.roaster, sample.beanName]
        .where((value) => value?.trim().isNotEmpty ?? false)
        .map((value) => _escapeInline(value!.trim()))
        .join(' · ');
    final heading = headingText.isEmpty ? labels.noBeanGroupLabel : headingText;
    return _BeanGroup(mapEntry.key, heading, groupEntries);
  }).toList();

  groups.sort((a, b) {
    final aLatest = a.entries
        .map((e) => e.createdAt)
        .reduce((x, y) => x.isAfter(y) ? x : y);
    final bLatest = b.entries
        .map((e) => e.createdAt)
        .reduce((x, y) => x.isAfter(y) ? x : y);
    final byDate = bLatest.compareTo(aLatest);
    if (byDate != 0) return byDate;
    final byHeading = a.heading.compareTo(b.heading);
    if (byHeading != 0) return byHeading;
    return a.key.compareTo(b.key);
  });

  return groups;
}

class _DayGroup {
  _DayGroup(this.date, this.entries);

  /// Midnight of the calendar day this group covers (year/month/day only —
  /// see [_groupByDay]).
  final DateTime date;
  final List<DiaryEntry> entries;
}

/// Groups entries by calendar day (year/month/day of `createdAt`, ignoring
/// time-of-day), each day's entries already reverse-chronological. Days
/// themselves are ordered reverse-chronologically. Used only by
/// [BrewExportScope.wholeDiary] — [BrewExportScope.byBean] groups by bean
/// instead and has no day dividers.
List<_DayGroup> _groupByDay(List<DiaryEntry> entries) {
  final byDay = <DateTime, List<DiaryEntry>>{};
  for (final entry in entries) {
    final createdAt = entry.createdAt;
    final key = DateTime(createdAt.year, createdAt.month, createdAt.day);
    byDay.putIfAbsent(key, () => []).add(entry);
  }

  final days = byDay.entries
      .map((e) => _DayGroup(e.key, _sortedReverseChronological(e.value)))
      .toList();

  days.sort((a, b) => b.date.compareTo(a.date));
  return days;
}

/// Sorts [entries] reverse-chronologically with `statUuid` as a
/// deterministic tiebreaker so repeated exports of the same data always
/// produce the same order, independent of input order or sort stability.
List<DiaryEntry> _sortedReverseChronological(List<DiaryEntry> entries) {
  final sorted = List<DiaryEntry>.of(entries);
  sorted.sort((a, b) {
    final byDate = b.createdAt.compareTo(a.createdAt);
    if (byDate != 0) return byDate;
    return a.statUuid.compareTo(b.statUuid);
  });
  return sorted;
}

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

String _formatAmount(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

// ---------------------------------------------------------------------------
// Markdown escaping
// ---------------------------------------------------------------------------

/// Characters that are markdown-significant no matter where they appear in
/// a line: backslash itself, code spans, emphasis, links, headings,
/// blockquotes, table-cell separators, and strikethrough delimiters.
/// Escaped unconditionally (a stray backslash in the rendered output is a
/// much smaller cost than a note silently reformatting the document).
const List<String> _kInlineControlChars = [
  '\\',
  '`',
  '*',
  '_',
  '[',
  ']',
  '<',
  '>',
  '#',
  '|',
  '~',
];

/// Escapes every occurrence of [_kInlineControlChars] in [text] with a
/// leading backslash. Used for every user-authored string that gets spliced
/// into the document: `notes` (per line), `beans`, `roaster`, and tag
/// values.
String _escapeInline(String text) {
  final buffer = StringBuffer();
  for (final char in text.split('')) {
    if (_kInlineControlChars.contains(char)) buffer.write('\\');
    buffer.write(char);
  }
  return buffer.toString();
}

/// Matches a leading unordered-list marker ("-" or "+") or an ordered-list
/// marker ("1." / "1)") at the start of a line, ignoring leading
/// whitespace. "*" as a bullet marker is already covered by
/// [_kInlineControlChars] since it's escaped unconditionally.
final RegExp _kLeadingUnorderedMarker = RegExp(r'^(\s*)([-+])');
final RegExp _kLeadingOrderedMarker = RegExp(r'^(\s*)(\d+)([.)])');

/// Escapes one line of notes: first the chars that are significant anywhere
/// in a line ([_escapeInline]), then — because this line will be emitted
/// verbatim inside a blockquote — any leading list marker that survived
/// (only "-", "+", and ordered-list digits; "#", ">", and "`" are already
/// unconditionally escaped above) so it can't be reinterpreted as nested
/// block structure.
String _escapeNotesLine(String line) {
  final escaped = _escapeInline(line);

  final ordered = _kLeadingOrderedMarker.firstMatch(escaped);
  if (ordered != null) {
    final indent = ordered.group(1)!;
    final digits = ordered.group(2)!;
    final marker = ordered.group(3)!;
    return '$indent$digits\\$marker${escaped.substring(ordered.end)}';
  }

  final unordered = _kLeadingUnorderedMarker.firstMatch(escaped);
  if (unordered != null) {
    final indent = unordered.group(1)!;
    final marker = unordered.group(2)!;
    return '$indent\\$marker${escaped.substring(unordered.end)}';
  }

  return escaped;
}
