import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../services/analytics_service.dart';
import '../../theme/design_tokens.dart';
import '../../utils/app_logger.dart';
import '../base_buttons.dart';
import '../fields/labeled_field.dart';
import '../settings/settings_list.dart';
import '../unsaved_changes_dialog.dart';

/// Outcome of one roaster-report submit attempt.
enum RoasterReportOutcome { ok, rateLimited, error }

/// Sends a report body to the backend. Widget tests inject a fake; the
/// default invokes the `submit-roaster-feedback` edge function and never
/// throws.
typedef RoasterReportSubmitter =
    Future<RoasterReportOutcome> Function(Map<String, dynamic> body);

/// The Supabase edge function that receives roaster reports.
const String _edgeFnSubmit = 'submit-roaster-feedback';

/// Report categories that accept an optional "correct value". The field is
/// hidden (and its text cleared) for every other category.
const Set<String> _categoriesWithSuggestedValue = {
  'wrong_location',
  'wrong_website',
  'wrong_social',
  'wrong_name',
  'duplicate',
};

/// Shows the roaster report-an-error form as a modal bottom sheet.
/// Returns `true` when a report was sent (the caller shows the success
/// SnackBar, since the sheet has popped by then).
Future<bool> showRoasterReportSheet(
  BuildContext context, {
  required String roasterProfileId,
  required String roasterName,
  RoasterReportSubmitter? submitter,
}) async {
  AnalyticsService.maybeInstance?.track(
    'roaster_report_opened',
    properties: {'roaster_id': roasterProfileId},
  );
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Swipe-to-dismiss bypasses PopScope (it pops the route directly), so it
    // is disabled here; the sheet guards discards via PopScope for the scrim
    // tap and system back gesture instead.
    enableDrag: false,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.large),
      ),
    ),
    builder: (_) => _RoasterReportSheet(
      roasterProfileId: roasterProfileId,
      roasterName: roasterName,
      submitter: submitter,
    ),
  );
  return result ?? false;
}

/// Default submitter: invokes the edge function and maps the outcome —
/// `{status: "ok"}` to [RoasterReportOutcome.ok], a 429
/// [FunctionException] to [RoasterReportOutcome.rateLimited], everything
/// else (and any other exception) to [RoasterReportOutcome.error]. Never
/// throws.
Future<RoasterReportOutcome> _defaultSubmit(Map<String, dynamic> body) async {
  try {
    final response = await Supabase.instance.client.functions.invoke(
      _edgeFnSubmit,
      body: body,
    );
    final data = response.data;
    final status = data is Map ? data['status'] as String? : null;
    return status == 'ok'
        ? RoasterReportOutcome.ok
        : RoasterReportOutcome.error;
  } catch (error) {
    AppLogger.error(
      '$_edgeFnSubmit failed',
      errorObject: AppLogger.sanitize(error),
    );
    if (error is FunctionException && error.status == 429) {
      return RoasterReportOutcome.rateLimited;
    }
    return RoasterReportOutcome.error;
  }
}

class _RoasterReportSheet extends StatefulWidget {
  final String roasterProfileId;
  final String roasterName;
  final RoasterReportSubmitter? submitter;

  const _RoasterReportSheet({
    required this.roasterProfileId,
    required this.roasterName,
    this.submitter,
  });

  @override
  State<_RoasterReportSheet> createState() => _RoasterReportSheetState();
}

class _RoasterReportSheetState extends State<_RoasterReportSheet> {
  /// Report categories, in the order they are offered, matching the values
  /// the `submit-roaster-feedback` edge function accepts.
  static const List<String> _categories = [
    'wrong_location',
    'wrong_website',
    'wrong_social',
    'wrong_logo',
    'wrong_name',
    'wrong_business',
    'not_a_roaster',
    'closed',
    'duplicate',
    'other',
  ];

  static const int _maxSuggestedValueLength = 500;
  static const int _maxDetailsLength = 1000;

  final _suggestedValueController = TextEditingController();
  final _detailsController = TextEditingController();
  String? _category;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _suggestedValueController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  /// Whether the user has made any input worth confirming before discarding.
  bool get _isDirty =>
      _category != null ||
      _suggestedValueController.text.trim().isNotEmpty ||
      _detailsController.text.trim().isNotEmpty;

  bool get _canSubmit =>
      _category != null &&
      (_category != 'other' || _detailsController.text.trim().isNotEmpty) &&
      !_submitting;

  /// Confirms before discarding an in-progress report. Wired to [PopScope],
  /// so it covers the scrim tap and system back gesture.
  Future<void> _handleDismiss(bool didPop) async {
    if (didPop) return;
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (_) => const UnsavedChangesDialog(),
    );
    if (shouldDiscard == true && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  void _selectCategory(String? category) {
    setState(() {
      _category = category;
      // A stale correction for another category must not ride along.
      _suggestedValueController.clear();
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final category = _category;
    if (category == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    // Omit empty strings so the backend can distinguish "not given" from
    // "given as blank".
    final body = <String, dynamic>{
      'kind': 'report',
      'roasterProfileId': widget.roasterProfileId,
      'category': category,
      if (_categoriesWithSuggestedValue.contains(category) &&
          _suggestedValueController.text.trim().isNotEmpty)
        'suggestedValue': _suggestedValueController.text.trim(),
      if (_detailsController.text.trim().isNotEmpty)
        'details': _detailsController.text.trim(),
    };
    final outcome = await (widget.submitter ?? _defaultSubmit)(body);
    AnalyticsService.maybeInstance?.track(
      'roaster_report_submitted',
      properties: {
        'roaster_id': widget.roasterProfileId,
        'category': category,
        'status': switch (outcome) {
          RoasterReportOutcome.ok => 'ok',
          RoasterReportOutcome.rateLimited => 'rate_limited',
          RoasterReportOutcome.error => 'error',
        },
      },
    );
    if (!mounted) return;
    switch (outcome) {
      case RoasterReportOutcome.ok:
        Navigator.of(context).pop(true);
      case RoasterReportOutcome.rateLimited:
        setState(() {
          _submitting = false;
          _error = l10n.roasterReportRateLimited;
        });
      case RoasterReportOutcome.error:
        setState(() {
          _submitting = false;
          _error = l10n.roasterReportError;
        });
    }
  }

  String _labelFor(AppLocalizations l10n, String category) =>
      switch (category) {
        'wrong_location' => l10n.roasterReportCategoryWrongLocation,
        'wrong_website' => l10n.roasterReportCategoryWrongWebsite,
        'wrong_social' => l10n.roasterReportCategoryWrongSocial,
        'wrong_logo' => l10n.roasterReportCategoryWrongLogo,
        'wrong_name' => l10n.roasterReportCategoryWrongName,
        'wrong_business' => l10n.roasterReportCategoryWrongBusiness,
        'not_a_roaster' => l10n.roasterReportCategoryNotARoaster,
        'closed' => l10n.roasterReportCategoryClosed,
        'duplicate' => l10n.roasterReportCategoryDuplicate,
        'other' => l10n.roasterReportCategoryOther,
        _ => category,
      };

  String? _hintFor(AppLocalizations l10n, String category) =>
      switch (category) {
        'wrong_location' => l10n.roasterReportHintLocation,
        'wrong_website' => l10n.roasterReportHintWebsite,
        'wrong_social' => l10n.roasterReportHintSocial,
        'wrong_name' => l10n.roasterReportHintName,
        'duplicate' => l10n.roasterReportHintDuplicate,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final category = _category;
    final hasSuggestedValueField = _categoriesWithSuggestedValue.contains(
      category,
    );

    final options = [
      for (final value in _categories)
        SettingsChoiceOption<String?>(
          value: value,
          label: _labelFor(l10n, value),
          identifier: value,
        ),
    ];

    return PopScope(
      // Pop freely when nothing has been entered; otherwise intercept to
      // confirm the discard.
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) => _handleDismiss(didPop),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.base,
          right: AppSpacing.base,
          top: AppSpacing.base,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.base,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.roasterReportTitle, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.roasterReportSubtitle(widget.roasterName),
                style: AppTextStyles.body.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              SettingsInlineChoice<String?>(
                options: options,
                current: category,
                onChanged: _selectCategory,
              ),
              // Always-present slot for the optional correction field; keeps
              // the widget type at this tree position stable
              // (SizedBox.shrink() when the category has no correction
              // field). The field's text lives in this state's controller,
              // so a remount cannot lose it.
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.base),
                child: category != null && hasSuggestedValueField
                    ? LabeledField(
                        label: l10n.roasterReportCorrectValueLabel,
                        hintText: _hintFor(l10n, category),
                        controller: _suggestedValueController,
                        maxLength: _maxSuggestedValueLength,
                        onChanged: (_) => setState(() {}),
                      )
                    : const SizedBox.shrink(),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.base),
                child: LabeledField(
                  label: category == 'other'
                      ? l10n.roasterReportDetailsRequired
                      : l10n.roasterReportDetailsOptional,
                  controller: _detailsController,
                  isMultiline: true,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: _maxDetailsLength,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              // Always-present inline error slot; renders nothing while
              // empty, so surrounding widget types never change.
              Text(
                _error ?? '',
                style: AppTextStyles.body.copyWith(color: colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppElevatedButton(
                label: l10n.roasterReportSubmit,
                onPressed: _canSubmit ? _submit : null,
                isLoading: _submitting,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
