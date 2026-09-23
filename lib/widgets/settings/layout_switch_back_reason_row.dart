import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/analytics_service.dart';
import '../../theme/design_tokens.dart';
import '../base_buttons.dart';

/// One-tap feedback row shown when the user switches the brewing screen back
/// from the immersive layout to the classic one (plan 067 Phase 5).
///
/// The row stays mounted at all times — visibility is animated via
/// [AnimatedSize] and a [SizedBox.shrink] slot, never by changing the widget
/// type at this tree position (which would remount the subtree and re-run
/// `initState`).
///
/// It appears only when it *observes* [pourEnabled] going true → false in
/// `didUpdateWidget`, and only while the install has neither answered before
/// (`layout_switch_back_reason_given`) nor already seen the row twice
/// (`layout_switch_back_reason_shown_count`). One chip tap records the reason
/// and swaps the chips for a thanks note in place; there is no free text.
///
/// When the tapped reason is `something_broke`, a “Tell us what happened”
/// link appears under the thanks note and opens the mail app with a
/// pre-filled report to support.
class LayoutSwitchBackReasonRow extends StatefulWidget {
  const LayoutSwitchBackReasonRow({
    super.key,
    required this.pourEnabled,
    required this.source,
  });

  /// Whether the immersive layout is currently on. A true → false transition
  /// of this value is the row's trigger.
  final bool pourEnabled;

  /// Analytics `source` for where the toggle was flipped, e.g. `'settings'`
  /// or `'preparation_settings_sheet'`.
  final String source;

  /// Support address the `something_broke` report link writes to.
  static const String _reportEmail = 'support@timer.coffee';

  /// Builds the `mailto:` URI behind the `something_broke` report link.
  ///
  /// Pure — no launching — so tests can assert on address, subject and the
  /// encoded body without a mail client.
  @visibleForTesting
  static Uri buildReportEmailUri({
    required String featureName,
    required String version,
    required String platform,
  }) {
    // Two blank lines, an em-dash separator, then the app signature — the
    // user writes their report above it.
    final body = '\n\n—\nTimer.Coffee $version ($platform)';
    // Uri.encodeComponent, NOT queryParameters:, so spaces become %20 —
    // mail apps do not decode the form-encoding `+` that queryParameters
    // produces.
    return Uri(
      scheme: 'mailto',
      path: _reportEmail,
      query:
          'subject=${Uri.encodeComponent(featureName)}'
          '&body=${Uri.encodeComponent(body)}',
    );
  }

  @override
  State<LayoutSwitchBackReasonRow> createState() =>
      _LayoutSwitchBackReasonRowState();
}

class _LayoutSwitchBackReasonRowState extends State<LayoutSwitchBackReasonRow> {
  static const _kGivenKey = 'layout_switch_back_reason_given';
  static const _kShownCountKey = 'layout_switch_back_reason_shown_count';

  /// The row appears at most twice per install, ever.
  static const int _maxShows = 2;

  /// Feedback reasons in analytics form, shown in this order.
  static const _reasonIds = [
    'hard_to_read',
    'too_distracting',
    'prefer_classic',
    'something_broke',
  ];

  SharedPreferences? _prefs;
  bool _prefsLoaded = false;
  bool _given = false;
  int _shownCount = 0;

  /// Set when a true → false flip was observed, even before prefs finished
  /// loading, so the trigger is not lost when the two race.
  bool _flipToClassicObserved = false;

  bool _visible = false;

  /// Whether a reason was tapped this session; swaps the chips for the
  /// thanks note in place.
  bool _answered = false;

  /// The reason tapped this session, or null before an answer. Only
  /// `something_broke` gets the follow-up report link.
  String? _selectedReason;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPrefs());
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    if (!mounted) return;
    setState(() {
      _given = prefs.getBool(_kGivenKey) ?? false;
      _shownCount = prefs.getInt(_kShownCountKey) ?? 0;
      _prefsLoaded = true;
    });
    // A flip that happened while prefs were still loading takes effect now.
    if (_flipToClassicObserved) {
      _maybeShow();
    }
  }

  @override
  void didUpdateWidget(covariant LayoutSwitchBackReasonRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pourEnabled && !widget.pourEnabled) {
      _flipToClassicObserved = true;
      _maybeShow();
    } else if (!oldWidget.pourEnabled && widget.pourEnabled) {
      // Back on immersive while the row (or its thanks note) is showing —
      // hide it again.
      _flipToClassicObserved = false;
      if (_visible) {
        setState(() => _visible = false);
      }
    }
  }

  void _maybeShow() {
    if (!_prefsLoaded || _given || _shownCount >= _maxShows || _visible) {
      return;
    }
    setState(() {
      _visible = true;
      _shownCount += 1;
    });
    final prefs = _prefs;
    if (prefs != null) {
      unawaited(prefs.setInt(_kShownCountKey, _shownCount));
    }
  }

  void _selectReason(String reasonId) {
    AnalyticsService.maybeInstance?.track(
      'layout_switch_back_reason',
      properties: {'reason': reasonId, 'source': widget.source},
    );
    setState(() {
      _answered = true;
      _given = true;
      _selectedReason = reasonId;
    });
    final prefs = _prefs;
    if (prefs != null) {
      unawaited(prefs.setBool(_kGivenKey, true));
    }
  }

  /// Platform name for the report email signature: `ios`, `android` or `web`.
  String get _platformName {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name.toLowerCase();
  }

  /// Opens the mail app pre-filled for the `something_broke` report. Failure
  /// is deliberately silent — the thanks note is already showing, and there
  /// is nothing useful to do about a missing mail client.
  Future<void> _openReportEmail() async {
    try {
      final loc = AppLocalizations.of(context)!;
      final featureName = loc.pourLayout;
      final info = await PackageInfo.fromPlatform();
      final uri = LayoutSwitchBackReasonRow.buildReportEmailUri(
        featureName: featureName,
        version: '${info.version}+${info.buildNumber}',
        platform: _platformName,
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Silent by design (also swallows MissingPluginException in tests).
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // Full width, so the start-aligned column actually starts at the edge:
    // Settings' ExpansionTile centres its children, and a content-sized row
    // rendered visibly indented there (seen on the simulator).
    return SizedBox(
      width: double.infinity,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: AlignmentDirectional.topStart,
        child: _visible
            ? Semantics(
                identifier: 'layoutSwitchBackReasonRow',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    0,
                    AppSpacing.base,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.layoutSwitchBackPrompt,
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Always-present slot; only its contents change, never
                      // this column's shape.
                      _answered
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.layoutSwitchBackThanks,
                                  style: AppTextStyles.body.copyWith(
                                    color: colorScheme.primary,
                                  ),
                                ),
                                // Always-present slot for the follow-up
                                // report link; only its contents change
                                // (SizedBox.shrink when hidden), never the
                                // shape of this column.
                                _selectedReason == 'something_broke'
                                    // A filled button with a mail icon: as a
                                    // text button it read as plain text on
                                    // device and nobody could tell it was
                                    // tappable.
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                          top: AppSpacing.sm,
                                        ),
                                        child: AppElevatedButton(
                                          label: loc.layoutSwitchBackReportLink,
                                          icon: Icons.mail_outline,
                                          onPressed: _openReportEmail,
                                          isFullWidth: false,
                                          height: AppButton.heightSmall,
                                          padding: AppButton.paddingSmall,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            )
                          : Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                for (final id in _reasonIds)
                                  ActionChip(
                                    label: Text(_reasonLabel(loc, id)),
                                    labelStyle: AppTextStyles.caption,
                                    side: BorderSide(
                                      color: colorScheme.outlineVariant,
                                      width: AppStroke.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.chip,
                                      ),
                                    ),
                                    onPressed: () => _selectReason(id),
                                  ),
                              ],
                            ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  String _reasonLabel(AppLocalizations loc, String reasonId) =>
      switch (reasonId) {
        'hard_to_read' => loc.layoutSwitchBackHardToRead,
        'too_distracting' => loc.layoutSwitchBackTooDistracting,
        'prefer_classic' => loc.layoutSwitchBackPreferClassic,
        'something_broke' => loc.layoutSwitchBackSomethingBroke,
        _ => reasonId,
      };
}
