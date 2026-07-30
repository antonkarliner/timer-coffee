import 'dart:convert';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/brew_markdown_export_service.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// Shared plumbing that wires the pure `renderBrewMarkdown` (Phase 1) to
/// `share_plus` for the brew diary's three export entry points: a single
/// brew (`brew_detail_sheet.dart`), the whole diary (`brew_diary_screen.dart`
/// app bar), and a single bean's brews (the bean-grouped list's group card).
///
/// Kept as one shared module so the three call sites can't drift on label
/// resolution, date/time formatting, or the text-vs-file share decision.

/// Platform-appropriate share glyph. Mirrors the icon convention already
/// used for recipe/collection sharing elsewhere in the app (Cupertino glyph
/// on iOS, Material elsewhere) — see `RecipeDetailAppBarActions`. Icon-only,
/// no tooltip: no generic "Share" string exists in the catalog, and Phase 2a
/// deliberately didn't add one (a new `.arb` key means touching all 22
/// catalogs, out of scope for this phase). This matches the existing
/// recipe-share button, which is also icon-only.
Icon brewShareIcon() => Icon(
  defaultTargetPlatform == TargetPlatform.iOS
      ? CupertinoIcons.share
      : Icons.share,
);

/// Save/download glyph for the entry points that produce a **file** (whole
/// diary, one bean) as opposed to shareable text (a single brew, which keeps
/// [brewShareIcon]).
///
/// Both still open the system share sheet — on iOS that sheet is how a file
/// gets saved ("Save to Files"), and on Android it is the route to Drive and
/// the file managers. The icon describes the *outcome* the user is after
/// rather than the mechanism: tapping this yields a `.md` file to keep, not a
/// message to send. A share glyph oversells the messaging destinations and
/// undersells the backup, which is the reason this feature exists.
Icon brewExportIcon() => Icon(
  defaultTargetPlatform == TargetPlatform.iOS
      ? CupertinoIcons.arrow_down_doc
      : Icons.download_outlined,
);

/// Resolves every [BrewExportLabels] field from [loc]. Kept in one place so
/// the three entry points can't drift on wording.
@visibleForTesting
BrewExportLabels buildBrewExportLabels(AppLocalizations loc) =>
    BrewExportLabels(
      documentTitle: loc.brewExportDocumentTitle,
      exportedOnLabel: loc.brewExportExportedOn,
      dateLabel: loc.brewExportDateLabel,
      beansLabel: loc.beans,
      ratingLabel: loc.rating,
      coffeeToWaterLabel: loc.brewDiaryDoseWater,
      grindSizeLabel: loc.grindsize,
      waterTempLabel: loc.watertemp,
      tdsLabel: loc.brewExportTdsLabel,
      extractionYieldLabel: loc.brewDiaryExtraction,
      tasteLabel: loc.brewDiaryTasted,
      tasteBalanceLabels: [loc.tasteSour, loc.tasteBalanced, loc.tasteBitter],
      tagsLabel: loc.diaryTags,
      notesLabel: loc.notes,
      noBeanGroupLabel: loc.brewExportNoBeanGroup,
      originLabel: loc.origin,
      bookmarkLabel: loc.diaryBookmarked,
    );

/// Resolves [BrewExportFormats] via [DateTimeFormatService] — per the
/// project's mandatory date/time rule, never `DateFormat.yMMMd()` or
/// `loc.dateFormat` directly, so the user's configured date/time
/// preference (Settings → Date & Time Format) is respected in exports too.
@visibleForTesting
BrewExportFormats buildBrewExportFormats(
  BuildContext context,
  AppLocalizations loc,
) {
  final fmtSvc = Provider.of<DateTimeFormatService>(context, listen: false);
  return BrewExportFormats(
    datePattern: fmtSvc.datePattern(loc.dateFormat),
    use24HourTime: fmtSvc.use24Hour(
      MediaQuery.of(context).alwaysUse24HourFormat,
    ),
  );
}

/// Filesystem-safe slug for [label], or null when nothing usable survives —
/// e.g. a fully non-Latin bean name, where every character maps away and the
/// caller should fall back to the generic export filename rather than produce
/// `timer_coffee__20260727.md`.
///
/// Diacritics are folded first (so "Café Ethiopia" keeps its "e") before
/// anything outside `[a-z0-9]` collapses to a single underscore. Capped so a
/// verbose bean name can't produce an unwieldy filename.
@visibleForTesting
String? brewExportFileSlug(String? label) {
  if (label == null) return null;
  final slug = removeDiacritics(label)
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (slug.isEmpty) return null;
  if (slug.length <= 40) return slug;
  return slug.substring(0, 40).replaceAll(RegExp(r'_+$'), '');
}

String _scopeAnalyticsValue(BrewExportScope scope) => switch (scope) {
  BrewExportScope.singleBrew => 'single_brew',
  BrewExportScope.wholeDiary => 'whole_diary',
  BrewExportScope.byBean => 'by_bean',
};

/// Computes the iPad/Mac-safe share-sheet popover anchor, mirroring the
/// pattern already used by `collection_detail_screen.dart` and
/// `recipe_import_sharing_service.dart`.
@visibleForTesting
Rect? brewShareOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return null;
  final mediaQuery = MediaQuery.of(context);
  if (mediaQuery.size.shortestSide >= 768) {
    final center = Offset(
      mediaQuery.size.width / 2,
      mediaQuery.size.height / 2,
    );
    return Rect.fromCenter(center: center, width: 1, height: 1);
  }
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Renders [entries] to markdown per [scope] and hands the result to the
/// share sheet, tracking `diary_export_shared` (scope + entry count only —
/// never note text, tag values, or bean/recipe names).
///
/// - [BrewExportScope.singleBrew] shares as **text**, so it pastes directly
///   into any app.
/// - [BrewExportScope.wholeDiary] / [BrewExportScope.byBean] share as a
///   **.md file** — a diary or a heavily-brewed bean's history can exceed a
///   sane text-share limit. `share_plus` writes the temp file itself on
///   mobile/desktop; on web, `ShareParams.downloadFallbackEnabled` (the
///   package default) falls back to a browser download when the Web Share
///   API can't accept files — the diary is not `kIsWeb`-gated, so this path
///   is reachable from the web app.
///
/// Does nothing on an empty [entries] list. Failures are logged and surface
/// a generic [AppLocalizations.unexpectedErrorOccurred] snackbar rather than
/// throwing — sharing is a convenience action, never worth crashing over.
///
/// Rendering runs synchronously on the UI isolate. `renderBrewMarkdown` is
/// pure string concatenation with no I/O, so even a diary in the low
/// thousands of entries renders well under a frame; moving it to a
/// background isolate via `compute()` was tried and dropped — it added
/// isolate-spawn overhead and (confirmed in this phase's own widget tests)
/// doesn't reliably signal completion to `flutter_test`'s pump loop, for a
/// cost with no measured jank to justify it. Revisit only if a real device
/// profile shows a dropped frame on an actual heavy diary.
/// [label] names the export when the scope is about one thing — the bean name
/// for a per-bean share. It drives both the filename and the share-sheet
/// headline, so the file a user receives is named after the card they tapped.
/// Null (whole diary) falls back to the generic name and document title.
Future<void> shareBrewExport(
  BuildContext context, {
  required List<DiaryEntry> entries,
  required BrewExportScope scope,
  String? label,
}) async {
  if (entries.isEmpty) return;

  final loc = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final formats = buildBrewExportFormats(context, loc);
  final labels = buildBrewExportLabels(loc);
  final origin = brewShareOrigin(context);
  final exportedAt = DateTime.now();
  final rawLabel = label?.trim();
  final trimmedLabel = (rawLabel?.isEmpty ?? true) ? null : rawLabel;

  AnalyticsService.maybeInstance?.track(
    'diary_export_shared',
    properties: {
      'scope': _scopeAnalyticsValue(scope),
      'entry_count': entries.length,
    },
  );

  try {
    final markdown = renderBrewMarkdown(
      entries: entries,
      scope: scope,
      formats: formats,
      labels: labels,
      exportedAt: exportedAt,
    );

    if (scope == BrewExportScope.singleBrew) {
      await SharePlus.instance.share(
        ShareParams(text: markdown, sharePositionOrigin: origin),
      );
    } else {
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(exportedAt);
      final slug = brewExportFileSlug(trimmedLabel);
      final fileName = slug == null
          ? 'timer_coffee_brew_diary_$stamp.md'
          : 'timer_coffee_${slug}_$stamp.md';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            // Deliberately NO `path:` and no `name:` here. Verified on device:
            // share_plus only materializes a bytes-backed XFile when
            // `XFile.path` is EMPTY — `MethodChannelShare._getFile` starts with
            // `if (file.path.isNotEmpty) return file;`, handing the OS the path
            // as-is. Since a bytes-backed XFile has no real file behind that
            // path, supplying one produces a zero-byte, unnamed share sheet
            // item. (`name:` is a red herring too: cross_file's io
            // implementation ignores it outright and derives `XFile.name` from
            // `path`.) Leaving the path empty makes share_plus write the bytes
            // into a temp folder, and `fileNameOverrides` below is the
            // supported way to name the result.
            XFile.fromData(
              // Leading U+FEFF byte-order mark. The payload is already valid
              // UTF-8 without it, but a bare .md carries no charset hint, so
              // some viewers (iOS Quick Look among them) guess Latin-1 and
              // render every multi-byte character as mojibake — "90 °C · 194 °F"
              // shows up as "90 Â°C Â· 194 Â°F". The BOM makes the encoding
              // unambiguous. Markdown renderers strip it; it is only ever
              // added to the FILE payload, never to the single-brew text
              // share, where a stray BOM would be pasted into the message.
              Uint8List.fromList(utf8.encode('﻿$markdown')),
              mimeType: 'text/markdown; charset=utf-8',
            ),
          ],
          fileNameOverrides: [fileName],
          // Gives the iOS share sheet a headline. Without it the sheet shows
          // only "MD · 388 KB" with no name, which reads as though the file
          // is unnamed. A per-bean share is headlined with the bean; the whole
          // diary falls back to the already-localized document title, so
          // neither needs a new .arb key.
          title: trimmedLabel ?? labels.documentTitle,
          sharePositionOrigin: origin,
          downloadFallbackEnabled: true,
        ),
      );
    }
  } catch (e, stackTrace) {
    AppLogger.error(
      'Brew export share failed',
      errorObject: e,
      stackTrace: stackTrace,
    );
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(loc.unexpectedErrorOccurred)));
  }
}
