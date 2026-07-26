import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/services/data_export_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/fields/labeled_field.dart';

import 'settings_section_subtitle.dart';

/// Settings row that drives the self-serve "export my data" flow (plan 035).
///
/// Entry point for a two-step dialog flow:
/// 1. [_DataExportEmailDialog] — collect the destination email and request a
///    one-time confirmation code via [DataExportService.requestCode].
/// 2. [_DataExportCodeDialog] — collect the 6-digit code and trigger the
///    export via [DataExportService.confirmAndSend].
///
/// Deliberately styled differently from the sign-in OTP dialog in
/// `authentication_service.dart` / `authentication_dialogs.dart` (icon +
/// labeled fields + explicit "this does not sign you in" copy) so users don't
/// confuse "confirm your export destination" with "sign in".
class DataExportSection extends StatelessWidget {
  const DataExportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Semantics(
      identifier: 'dataExportListTile',
      child: ListTile(
        title: Text(loc.dataExportTileTitle),
        subtitle: SettingsSectionSubtitle(loc.dataExportTileSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _startExportFlow(context),
      ),
    );
  }

  Future<void> _startExportFlow(BuildContext context) async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final service = DataExportService(database: database);
    final initialEmail = Supabase.instance.client.auth.currentUser?.email ?? '';

    final email = await showDialog<String>(
      context: context,
      builder: (_) =>
          _DataExportEmailDialog(service: service, initialEmail: initialEmail),
    );
    if (email == null || email.isEmpty || !context.mounted) return;

    // Not barrier-dismissible: a stray tap outside would discard a code the
    // user has already received, and re-requesting burns one of only 3 allowed
    // requests per 24h. Mirrors OTPVerificationDialog in
    // `recipe_detail/authentication_dialogs.dart`, which does the same. Cancel
    // is still available in the dialog's actions.
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DataExportCodeDialog(service: service, email: email),
    );
    if (confirmed != true || !context.mounted) return;

    await _showSuccessDialog(context, email);
  }

  Future<void> _showSuccessDialog(BuildContext context, String email) async {
    final loc = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(loc.dataExportSuccessTitle)),
          ],
        ),
        content: Text(loc.dataExportSuccessMessage(email)),
        actions: [
          AppElevatedButton(
            label: loc.ok,
            onPressed: () => Navigator.of(dialogContext).pop(),
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error mapping
// ---------------------------------------------------------------------------

/// Maps every [DataExportResult] variant to a localized, user-facing message.
/// Never called for [DataExportSuccess] — callers handle that case
/// separately (it carries no error copy).
String _dataExportErrorMessage(AppLocalizations loc, DataExportResult result) {
  return switch (result) {
    DataExportSuccess() => '',
    DataExportInvalidEmail() => loc.dataExportInvalidEmail,
    DataExportRateLimited() => loc.dataExportRateLimited,
    DataExportIncorrectCode(:final attemptsRemaining) =>
      attemptsRemaining != null
          ? loc.dataExportIncorrectCodeAttempts(attemptsRemaining)
          : loc.dataExportIncorrectCode,
    DataExportExpiredOrNoRequest() => loc.dataExportExpiredOrNoRequest,
    DataExportPayloadTooLarge() => loc.dataExportPayloadTooLarge,
    DataExportNetworkError() => loc.dataExportNetworkError,
    DataExportUnknownError() => loc.dataExportUnknownError,
  };
}

// ---------------------------------------------------------------------------
// Step 1 — destination email dialog
// ---------------------------------------------------------------------------

class _DataExportEmailDialog extends StatefulWidget {
  const _DataExportEmailDialog({
    required this.service,
    required this.initialEmail,
  });

  final DataExportService service;
  final String initialEmail;

  @override
  State<_DataExportEmailDialog> createState() =>
      _DataExportEmailDialogState();
}

class _DataExportEmailDialogState extends State<_DataExportEmailDialog> {
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Re-entry guard, same rationale as the code dialog's: a fast double-tap
    // (or Enter landing alongside a tap) would send two code requests and burn
    // two of the three allowed per 24h, with the second code silently
    // superseding the first the user already received.
    if (_submitting) return;

    final loc = AppLocalizations.of(context)!;
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final email = _emailController.text.trim();
    final result = await widget.service.requestCode(email);
    if (!mounted) return;

    switch (result) {
      case DataExportSuccess():
        Navigator.of(context).pop(email);
      default:
        setState(() {
          _submitting = false;
          _errorText = _dataExportErrorMessage(loc, result);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Row(
        children: [
          const Icon(Icons.email_outlined),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(loc.dataExportEmailDialogTitle)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.dataExportEmailDialogBody),
            const SizedBox(height: AppSpacing.base),
            LabeledField(
              label: loc.dataExportEmailFieldLabel,
              hintText: loc.dataExportEmailFieldHint,
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
              enabled: !_submitting,
              errorText: _errorText,
              autofocus: true,
              textCapitalization: TextCapitalization.none,
              semanticIdentifier: 'dataExportEmailField',
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        AppTextButton(
          label: loc.cancel,
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
        AppElevatedButton(
          label: loc.dataExportSendCodeButton,
          onPressed: _submitting ? null : _submit,
          isLoading: _submitting,
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — confirmation code dialog
// ---------------------------------------------------------------------------

/// Digits in the confirmation code. Must match the code length the
/// `export-user-data` edge function generates; shared by the field's
/// `maxLength` and the auto-submit threshold so the two cannot drift apart.
const int _codeLength = 6;

class _DataExportCodeDialog extends StatefulWidget {
  const _DataExportCodeDialog({required this.service, required this.email});

  final DataExportService service;
  final String email;

  @override
  State<_DataExportCodeDialog> createState() => _DataExportCodeDialogState();
}

class _DataExportCodeDialogState extends State<_DataExportCodeDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Re-entry guard. The code is single-use: `confirm` marks it consumed on
    // success, so a second in-flight call would come back as
    // expired/no-active-request and surface an error for a flow that actually
    // succeeded (the download email having already been sent). Reachable via
    // auto-submit firing alongside onSubmitted, or a fast double-tap on
    // Confirm — the button's `onPressed` guard alone does not cover the window
    // before setState rebuilds.
    if (_submitting) return;

    final loc = AppLocalizations.of(context)!;
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final result = await widget.service.confirmAndSend(_codeController.text);
    if (!mounted) return;

    switch (result) {
      case DataExportSuccess():
        Navigator.of(context).pop(true);
      default:
        // Never dismiss on a wrong/expired code — let the user retry.
        setState(() {
          _submitting = false;
          _errorText = _dataExportErrorMessage(loc, result);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Row(
        children: [
          const Icon(Icons.verified_outlined),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(loc.dataExportCodeDialogTitle)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.dataExportCodeDialogBody(widget.email)),
            const SizedBox(height: AppSpacing.base),
            LabeledField(
              label: loc.dataExportCodeFieldLabel,
              hintText: loc.dataExportCodeFieldHint,
              keyboardType: TextInputType.number,
              controller: _codeController,
              enabled: !_submitting,
              errorText: _errorText,
              autofocus: true,
              maxLength: _codeLength,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              semanticIdentifier: 'dataExportCodeField',
              // Auto-submit once the full code is entered (typed or pasted).
              // The Confirm button stays for paste-then-tap, input methods that
              // don't report per-character changes, and as an a11y fallback;
              // `_submit`'s re-entry guard keeps the two from double-firing.
              // After a failed attempt the field still holds 6 digits, so
              // editing a character re-submits — the desired retry behaviour.
              onChanged: (value) {
                if (value.length == _codeLength) _submit();
              },
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        AppTextButton(
          label: loc.cancel,
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
        AppElevatedButton(
          label: loc.dataExportConfirmButton,
          onPressed: _submitting ? null : _submit,
          isLoading: _submitting,
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
      ],
    );
  }
}
