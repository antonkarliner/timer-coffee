import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/analytics_service.dart';
import '../../theme/design_tokens.dart';

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
    });
    final prefs = _prefs;
    if (prefs != null) {
      unawaited(prefs.setBool(_kGivenKey, true));
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
                          ? Text(
                              loc.layoutSwitchBackThanks,
                              style: AppTextStyles.body.copyWith(
                                color: colorScheme.primary,
                              ),
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
