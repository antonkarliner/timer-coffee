import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/roaster_contribution_service.dart';
import '../../theme/design_tokens.dart';
import '../../utils/input_validator.dart';
import '../base_buttons.dart';
import '../fields/labeled_field.dart';
import '../unsaved_changes_dialog.dart';

/// Shows the roaster-website contribution form as a modal bottom sheet.
/// Returns `true` when a contribution was successfully submitted.
Future<bool> showRoasterContributionSheet(
  BuildContext context, {
  required String roaster,
  String? clusterId,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Swipe-to-dismiss bypasses PopScope (it pops the route directly), so it is
    // disabled here; the sheet guards discards via PopScope for the close
    // button, scrim tap, and system back gesture instead.
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.large),
      ),
    ),
    builder: (_) => _ContributionSheet(roaster: roaster, clusterId: clusterId),
  );
  return result ?? false;
}

class _ContributionSheet extends StatefulWidget {
  final String roaster;
  final String? clusterId;

  const _ContributionSheet({required this.roaster, this.clusterId});

  @override
  State<_ContributionSheet> createState() => _ContributionSheetState();
}

class _ContributionSheetState extends State<_ContributionSheet> {
  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _cityController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _websiteController.dispose();
    _instagramController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  /// Whether the user has typed anything worth confirming before discarding.
  bool get _isDirty =>
      _websiteController.text.trim().isNotEmpty ||
      _instagramController.text.trim().isNotEmpty ||
      _cityController.text.trim().isNotEmpty;

  /// Confirms before discarding an in-progress contribution. Wired to
  /// [PopScope], so it covers the close button, scrim tap, and system back.
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

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await RoasterContributionService.instance.submitContribution(
      roaster: widget.roaster,
      websiteUrl: _websiteController.text,
      instagramUrl: _instagramController.text,
      city: _cityController.text,
      clusterId: widget.clusterId,
    );
    if (!mounted) return;
    // Treat "already known" as success too: the roaster now exists, so there is
    // nothing more for the user to do.
    final ok =
        result == RoasterContributionResult.ok ||
        result == RoasterContributionResult.alreadyKnown;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _error = l10n.roasterContributionError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final websiteText = _websiteController.text;
    final websiteValid = InputValidator.isValidWebsiteUrl(websiteText);
    final showUrlError = websiteText.trim().isNotEmpty && !websiteValid;
    // Field labels match the detail-screen card row labels (DetailItemRow).
    final lineTitleStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar + close button.
              SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: AppIconSize.medium,
                        tooltip: l10n.dialogCancel,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.roasterContributionSheetTitle(widget.roaster),
                // Match the detail-screen card headers (DetailSectionHeader).
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.roasterContributionSheetSubtitle,
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              LabeledField(
                label: l10n.roasterContributionWebsiteLabel,
                labelStyle: lineTitleStyle,
                hintText: l10n.roasterContributionWebsiteHint,
                controller: _websiteController,
                required: true,
                keyboardType: TextInputType.url,
                textCapitalization: TextCapitalization.none,
                textInputAction: TextInputAction.next,
                errorText: showUrlError
                    ? l10n.roasterContributionInvalidUrl
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.base),
              LabeledField(
                label: l10n.roasterContributionInstagramLabel,
                labelStyle: lineTitleStyle,
                controller: _instagramController,
                keyboardType: TextInputType.url,
                textCapitalization: TextCapitalization.none,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.base),
              LabeledField(
                label: l10n.roasterContributionCityLabel,
                labelStyle: lineTitleStyle,
                controller: _cityController,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: AppTextStyles.body.copyWith(color: colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppElevatedButton(
                label: l10n.roasterContributionSubmit,
                onPressed: (websiteValid && !_submitting) ? _submit : null,
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
