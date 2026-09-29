import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../services/account_identity_service.dart';
import '../../services/analytics_service.dart';
import '../../theme/design_tokens.dart';
import '../../utils/app_logger.dart';
import '../base_buttons.dart';
import '../fields/labeled_field.dart';
import '../fields/otp_code_field.dart';

Future<void> showChangeEmailSheet(
  BuildContext context, {
  AccountIdentityService? service,
  String? pendingNewEmail,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ChangeEmailSheet(
      service: service ?? AccountIdentityService(),
      pendingNewEmail: pendingNewEmail,
    ),
  );
}

enum _ChangeEmailStep { address, codes, done }

class _ChangeEmailSheet extends StatefulWidget {
  const _ChangeEmailSheet({required this.service, this.pendingNewEmail});

  final AccountIdentityService service;
  final String? pendingNewEmail;

  @override
  State<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<_ChangeEmailSheet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldCodeController = TextEditingController();
  final TextEditingController _newCodeController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _oldCodeFocusNode = FocusNode();
  final FocusNode _newCodeFocusNode = FocusNode();

  late _ChangeEmailStep _step;
  late final String _oldEmail;
  String _newEmail = '';
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _requesting = false;
  bool _resending = false;
  bool _verifyingOld = false;
  bool _verifyingNew = false;
  bool _oldConfirmed = false;
  bool _newConfirmed = false;
  String? _emailError;
  String? _oldCodeError;
  String? _newCodeError;
  String? _resendError;

  @override
  void initState() {
    super.initState();
    _oldEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    final pendingEmail = widget.pendingNewEmail?.trim();
    if (pendingEmail != null && pendingEmail.isNotEmpty) {
      _newEmail = pendingEmail;
      _step = _ChangeEmailStep.codes;
      _startCooldown();
    } else {
      _step = _ChangeEmailStep.address;
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _oldCodeController.dispose();
    _newCodeController.dispose();
    _emailFocusNode.dispose();
    _oldCodeFocusNode.dispose();
    _newCodeFocusNode.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownSeconds = 60;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds -= 1;
        if (_cooldownSeconds == 0) timer.cancel();
      });
    });
  }

  void _focusAfterFrame(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) node.requestFocus();
    });
  }

  String _requestError(AppLocalizations l10n, EmailChangeRequest result) {
    return switch (result) {
      EmailChangeRequest.invalidEmail => l10n.accountEmailInvalid,
      EmailChangeRequest.sameAsCurrent => l10n.accountEmailSameAsCurrent,
      EmailChangeRequest.emailTaken => l10n.accountEmailTaken,
      EmailChangeRequest.rateLimited => l10n.accountEmailRateLimited,
      EmailChangeRequest.failed => l10n.accountEmailGenericError,
      EmailChangeRequest.sent => '',
    };
  }

  Future<void> _requestCodes() async {
    final newEmail = _emailController.text.trim();
    setState(() {
      _requesting = true;
      _emailError = null;
    });

    final result = await widget.service.requestEmailChange(newEmail);
    if (result == EmailChangeRequest.sent) {
      AnalyticsService.instance.track(
        'account_email_change_requested',
        properties: const {'mode': 'secure'},
      );
    } else {
      AnalyticsService.instance.track(
        'account_email_change_failed',
        properties: {'stage': 'request', 'reason': result.name},
      );
    }
    if (!mounted) return;

    if (result == EmailChangeRequest.sent) {
      setState(() {
        _requesting = false;
        _newEmail = newEmail;
        _step = _ChangeEmailStep.codes;
      });
      _startCooldown();
      _focusAfterFrame(_oldCodeFocusNode);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _requesting = false;
      _emailError = _requestError(l10n, result);
    });
  }

  Future<void> _verifyCode({
    required bool isOldAddress,
    required String code,
  }) async {
    if (isOldAddress
        ? _verifyingOld || _oldConfirmed
        : _verifyingNew || _newConfirmed) {
      return;
    }

    setState(() {
      if (isOldAddress) {
        _verifyingOld = true;
        _oldCodeError = null;
      } else {
        _verifyingNew = true;
        _newCodeError = null;
      }
    });

    final result = await widget.service.confirmEmailChangeCode(
      email: isOldAddress ? _oldEmail : _newEmail,
      code: code,
    );
    if (result == EmailCodeResult.completed) {
      AnalyticsService.instance.track(
        'account_email_changed',
        properties: const {},
      );
    } else if (result != EmailCodeResult.accepted) {
      AnalyticsService.instance.track(
        'account_email_change_failed',
        properties: {'stage': 'code', 'reason': result.name},
      );
    }
    if (!mounted) return;

    if (result == EmailCodeResult.completed) {
      _cooldownTimer?.cancel();
      FocusScope.of(context).unfocus();
      setState(() {
        _verifyingOld = false;
        _verifyingNew = false;
        _step = _ChangeEmailStep.done;
      });
      return;
    }

    if (result == EmailCodeResult.accepted) {
      setState(() {
        if (isOldAddress) {
          _verifyingOld = false;
          _oldConfirmed = true;
        } else {
          _verifyingNew = false;
          _newConfirmed = true;
        }
      });
      if (isOldAddress && !_newConfirmed) {
        _focusAfterFrame(_newCodeFocusNode);
      } else if (!isOldAddress && !_oldConfirmed) {
        _focusAfterFrame(_oldCodeFocusNode);
      }
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final error = result == EmailCodeResult.invalidOrExpired
        ? l10n.accountEmailCodeInvalid
        : l10n.accountEmailGenericError;
    setState(() {
      if (isOldAddress) {
        _verifyingOld = false;
        _oldCodeError = error;
        _oldCodeController.clear();
      } else {
        _verifyingNew = false;
        _newCodeError = error;
        _newCodeController.clear();
      }
    });
    if (isOldAddress) {
      _focusAfterFrame(_oldCodeFocusNode);
    } else {
      _focusAfterFrame(_newCodeFocusNode);
    }
  }

  Future<void> _resendCodes() async {
    setState(() {
      _resending = true;
      _resendError = null;
    });

    final result = await widget.service.resendEmailChange(_newEmail);
    if (result != EmailChangeRequest.sent) {
      AnalyticsService.instance.track(
        'account_email_change_failed',
        properties: {'stage': 'request', 'reason': result.name},
      );
    }
    if (!mounted) return;

    if (result == EmailChangeRequest.sent) {
      setState(() {
        _resending = false;
        _oldConfirmed = false;
        _newConfirmed = false;
        _oldCodeError = null;
        _newCodeError = null;
        _oldCodeController.clear();
        _newCodeController.clear();
      });
      _startCooldown();
      _focusAfterFrame(_oldCodeFocusNode);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _resending = false;
      _resendError = _requestError(l10n, result);
    });
  }

  Future<void> _contactSupport() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@timer.coffee',
      query: 'subject=${Uri.encodeComponent(l10n.accountEmailSupportSubject)}',
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('launchUrl returned false');
      }
    } catch (e) {
      AppLogger.warning('Could not open mail app', errorObject: e);
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.accountEmailGenericError)),
      );
    }
  }

  Widget _buildAddressStep(AppLocalizations l10n) {
    return Column(
      key: const ValueKey(_ChangeEmailStep.address),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: l10n.accountEmailNewAddressLabel,
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          textInputAction: TextInputAction.done,
          autofocus: true,
          errorText: _emailError,
          onSubmitted: (_) {
            if (!_requesting) _requestCodes();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        AppElevatedButton(
          label: l10n.accountEmailSendCodes,
          onPressed: _requesting ? null : _requestCodes,
          isLoading: _requesting,
        ),
      ],
    );
  }

  Widget _buildCodeStatus({
    required bool verifying,
    required bool confirmed,
    required AppLocalizations l10n,
  }) {
    return SizedBox(
      height: AppSpacing.lg,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: verifying
            ? SizedBox(
                width: AppIconSize.small,
                height: AppIconSize.small,
                child: const CircularProgressIndicator(
                  strokeWidth: AppStroke.focus,
                ),
              )
            : confirmed
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: AppIconSize.small,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.accountEmailConfirmed,
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCodesStep(AppLocalizations l10n) {
    return Column(
      key: const ValueKey(_ChangeEmailStep.codes),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.accountEmailCodesExplanation, style: AppTextStyles.body),
        const SizedBox(height: AppSpacing.lg),
        OtpCodeField(
          controller: _oldCodeController,
          focusNode: _oldCodeFocusNode,
          label: l10n.accountEmailCodeSentTo(_oldEmail),
          enabled: !_resending && !_verifyingOld && !_oldConfirmed,
          autofocus: true,
          errorText: _oldCodeError,
          onCompleted: (code) => _verifyCode(isOldAddress: true, code: code),
        ),
        _buildCodeStatus(
          verifying: _verifyingOld,
          confirmed: _oldConfirmed,
          l10n: l10n,
        ),
        const SizedBox(height: AppSpacing.sm),
        OtpCodeField(
          controller: _newCodeController,
          focusNode: _newCodeFocusNode,
          label: l10n.accountEmailCodeSentTo(_newEmail),
          enabled: !_resending && !_verifyingNew && !_newConfirmed,
          errorText: _newCodeError,
          onCompleted: (code) => _verifyCode(isOldAddress: false, code: code),
        ),
        _buildCodeStatus(
          verifying: _verifyingNew,
          confirmed: _newConfirmed,
          l10n: l10n,
        ),
        const SizedBox(height: AppSpacing.base),
        AppTextButton(
          label: _cooldownSeconds > 0
              ? l10n.accountEmailResendCountdown(_cooldownSeconds)
              : l10n.accountEmailResendCodes,
          onPressed:
              _cooldownSeconds > 0 ||
                  _resending ||
                  _verifyingOld ||
                  _verifyingNew
              ? null
              : _resendCodes,
          isLoading: _resending,
        ),
        _resendError == null
            ? const SizedBox.shrink()
            : Text(
                _resendError!,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
        const SizedBox(height: AppSpacing.sm),
        AppTextButton(
          label: l10n.accountEmailCantAccess(_oldEmail),
          onPressed: _contactSupport,
        ),
      ],
    );
  }

  Widget _buildDoneStep(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey(_ChangeEmailStep.done),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle,
          size: AppIconSize.large,
          color: colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          l10n.accountEmailDoneMessage(_newEmail),
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppElevatedButton(
          label: l10n.accountEmailDone,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stepContent = switch (_step) {
      _ChangeEmailStep.address => _buildAddressStep(l10n),
      _ChangeEmailStep.codes => _buildCodesStep(l10n),
      _ChangeEmailStep.done => _buildDoneStep(l10n),
    };

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.accountEmailChangeTitle,
                    style: AppTextStyles.title,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  iconSize: AppIconSize.medium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: stepContent,
            ),
          ],
        ),
      ),
    );
  }
}
