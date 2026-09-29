import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../services/account_identity_service.dart';
import '../../services/analytics_service.dart';
import '../../theme/design_tokens.dart';
import '../../utils/app_logger.dart';
import '../base_buttons.dart';
import '../confirm_delete_dialog.dart';
import 'change_email_sheet.dart';

class SignInMethodsSection extends StatefulWidget {
  const SignInMethodsSection({super.key, this.service});

  final AccountIdentityService? service;

  @override
  State<SignInMethodsSection> createState() => _SignInMethodsSectionState();
}

class _SignInMethodsSectionState extends State<SignInMethodsSection> {
  late final AccountIdentityService _service;
  List<UserIdentity>? _identities;
  String? _activeProvider;

  bool get _operationInFlight => _activeProvider != null;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AccountIdentityService();
    _identities = _service.auth.currentUser?.identities;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshIdentities());
    });
  }

  Future<void> _refreshIdentities() async {
    try {
      final identities = await _service.identities();
      if (!mounted) return;
      setState(() => _identities = identities);
    } catch (error) {
      AppLogger.warning(
        'Could not refresh linked sign-in methods',
        errorObject: error,
      );
    }
  }

  Future<void> _linkProvider(String provider, String providerName) async {
    if (_operationInFlight) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _activeProvider = provider);

    final outcome = provider == 'google'
        ? await _service.linkGoogle()
        : await _service.linkApple();

    if (_linkAttemptReachedServer(outcome)) {
      await _refreshIdentities();
    }

    if (outcome == LinkOutcome.linked) {
      AnalyticsService.instance.track(
        'account_identity_linked',
        properties: {'provider': provider},
      );
    } else if (outcome != LinkOutcome.cancelled &&
        outcome != LinkOutcome.redirected) {
      AnalyticsService.instance.track(
        'account_identity_link_failed',
        properties: {'provider': provider, 'reason': outcome.name},
      );
    }

    if (!mounted) return;
    setState(() => _activeProvider = null);

    switch (outcome) {
      case LinkOutcome.linked:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.accountIdentityLinkedMessage(providerName)),
          ),
        );
      case LinkOutcome.redirected:
      case LinkOutcome.cancelled:
        break;
      case LinkOutcome.alreadyUsedByAnotherAccount:
        await _showAlreadyUsedDialog(l10n, providerName);
      case LinkOutcome.linkingDisabled:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.accountIdentityLinkingDisabled)),
        );
      case LinkOutcome.unsupportedPlatform:
      case LinkOutcome.failed:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.accountEmailGenericError)),
        );
    }
  }

  bool _linkAttemptReachedServer(LinkOutcome outcome) {
    return outcome == LinkOutcome.linked ||
        outcome == LinkOutcome.alreadyUsedByAnotherAccount ||
        outcome == LinkOutcome.linkingDisabled ||
        outcome == LinkOutcome.failed;
  }

  Future<void> _showAlreadyUsedDialog(
    AppLocalizations l10n,
    String providerName,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(l10n.accountIdentityAlreadyUsedTitle(providerName)),
        content: Text(l10n.accountIdentityAlreadyUsedContent(providerName)),
        actions: [
          AppTextButton(
            label: l10n.accountIdentityContactSupport,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              unawaited(_contactSupport());
            },
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
          ),
          AppElevatedButton(
            label: l10n.ok,
            onPressed: () => Navigator.of(dialogContext).pop(),
            isFullWidth: false,
            height: AppButton.heightSmall,
            padding: AppButton.paddingSmall,
          ),
        ],
      ),
    );
  }

  Future<void> _contactSupport() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@timer.coffee',
      query:
          'subject=${Uri.encodeComponent(l10n.accountIdentitySupportSubject)}',
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('launchUrl returned false');
      }
    } catch (error) {
      AppLogger.warning('Could not open mail app', errorObject: error);
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.accountEmailGenericError)),
      );
    }
  }

  Future<void> _confirmUnlink(
    UserIdentity identity,
    String provider,
    String providerName,
  ) async {
    if (_operationInFlight) return;

    final l10n = AppLocalizations.of(context)!;
    final user = _service.auth.currentUser;
    final identities =
        _identities ?? user?.identities ?? const <UserIdentity>[];
    final emailAfterUnlink = AccountIdentityService.accountEmailAfterUnlink(
      currentEmail: user?.email,
      removing: identity,
      all: identities,
    );
    final unlinkContent = emailAfterUnlink == null
        ? l10n.accountIdentityUnlinkContent(providerName)
        : '${l10n.accountIdentityUnlinkContent(providerName)}\n\n'
              '${l10n.accountIdentityUnlinkEmailChange(emailAfterUnlink)}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDeleteDialog(
        title: l10n.accountIdentityUnlinkTitle(providerName),
        content: unlinkContent,
        confirmLabel: l10n.accountIdentityUnlink,
        cancelLabel: l10n.cancel,
      ),
    );
    if (!mounted || confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _activeProvider = provider);
    final outcome = await _service.unlink(identity);
    await _refreshIdentities();

    if (outcome == UnlinkOutcome.unlinked) {
      AnalyticsService.instance.track(
        'account_identity_unlinked',
        properties: {'provider': provider},
      );
    }

    if (!mounted) return;
    setState(() => _activeProvider = null);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          outcome == UnlinkOutcome.unlinked
              ? l10n.accountIdentityUnlinkedMessage(providerName)
              : l10n.accountEmailGenericError,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _service.auth.onAuthStateChange,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final colorScheme = Theme.of(context).colorScheme;
        final user = _service.auth.currentUser;
        final identities =
            _identities ?? user?.identities ?? const <UserIdentity>[];
        final rows = <_SignInMethodRowData>[];
        final email = user?.email;

        // Email-code sign-in is keyed on the confirmed account email, so this
        // is a real sign-in method even when no email identity exists.
        if (user != null &&
            !user.isAnonymous &&
            email != null &&
            email.trim().isNotEmpty &&
            user.emailConfirmedAt != null) {
          final pendingEmail = user.newEmail;
          rows.add(
            _SignInMethodRowData(
              id: 'email',
              leading: Icon(
                Icons.email_outlined,
                size: AppIconSize.medium,
                color: colorScheme.onSurfaceVariant,
              ),
              title: _wrappableEmail(email),
              subtitle: pendingEmail == null
                  ? null
                  : l10n.accountSignInPendingEmail(
                      _wrappableEmail(pendingEmail),
                    ),
              trailing: AppTextButton(
                label: pendingEmail == null
                    ? l10n.accountSignInChange
                    : l10n.accountSignInContinue,
                onPressed: _operationInFlight || !_service.canChangeEmail
                    ? null
                    : () => showChangeEmailSheet(
                        context,
                        service: _service,
                        pendingNewEmail: pendingEmail,
                      ),
                isFullWidth: false,
                height: AppButton.heightSmall,
                padding: AppButton.paddingSmall,
              ),
            ),
          );
        }

        final google = _identityFor(identities, 'google');
        if (_service.canLinkGoogle || google != null) {
          rows.add(
            _providerRow(
              l10n: l10n,
              colorScheme: colorScheme,
              identities: identities,
              identity: google,
              provider: 'google',
              providerName: 'Google',
              icon: FontAwesomeIcons.google,
            ),
          );
        }

        final apple = _identityFor(identities, 'apple');
        if (_service.canLinkApple || apple != null) {
          rows.add(
            _providerRow(
              l10n: l10n,
              colorScheme: colorScheme,
              identities: identities,
              identity: apple,
              provider: 'apple',
              providerName: 'Apple',
              icon: FontAwesomeIcons.apple,
            ),
          );
        }

        // No header on purpose: a "Sign-in" title read as a call to action,
        // and each row describes itself. Same Card as SectionCard, without
        // its header.
        return SizedBox(
          width: double.infinity,
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < rows.length; index++) ...[
                    if (index > 0) const SizedBox(height: AppSpacing.base),
                    _SignInMethodRow(
                      key: ValueKey(rows[index].id),
                      data: rows[index],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _SignInMethodRowData _providerRow({
    required AppLocalizations l10n,
    required ColorScheme colorScheme,
    required List<UserIdentity> identities,
    required UserIdentity? identity,
    required String provider,
    required String providerName,
    required FaIconData icon,
  }) {
    final email = identity?.identityData?['email'] as String?;
    Widget? trailing;

    if (_activeProvider == provider) {
      trailing = const SizedBox(
        width: AppIconSize.small,
        height: AppIconSize.small,
        child: CircularProgressIndicator(strokeWidth: AppStroke.focus),
      );
    } else if (identity == null) {
      trailing = AppTextButton(
        label: l10n.accountIdentityLink,
        onPressed: _operationInFlight
            ? null
            : () => _linkProvider(provider, providerName),
        isFullWidth: false,
        height: AppButton.heightSmall,
        padding: AppButton.paddingSmall,
      );
    } else if (_service.canUnlink(identity, identities)) {
      // Inline, in the slot where "Link" sits when unlinked, so the action
      // simply flips; error color marks it as the destructive one. The
      // confirmation dialog still guards it.
      trailing = AppTextButton(
        label: l10n.accountIdentityUnlink,
        onPressed: _operationInFlight
            ? null
            : () => _confirmUnlink(identity, provider, providerName),
        foregroundColor: colorScheme.error,
        isFullWidth: false,
        height: AppButton.heightSmall,
        padding: AppButton.paddingSmall,
      );
    }

    return _SignInMethodRowData(
      id: provider,
      leading: FaIcon(
        icon,
        size: AppIconSize.medium,
        color: colorScheme.onSurfaceVariant,
      ),
      title: providerName,
      subtitle: identity == null
          ? null
          : (email == null
                ? l10n.accountIdentityLinkedStatus
                : _wrappableEmail(email)),
      trailing: trailing,
    );
  }

  /// An address has no spaces, so when it must wrap Flutter splits it at the
  /// last character that fits ("…necub.co" / "m"). A zero-width space after
  /// the @ gives it a natural break point instead. Display only.
  static String _wrappableEmail(String email) =>
      email.replaceFirst('@', '@\u200B');

  UserIdentity? _identityFor(List<UserIdentity> identities, String provider) {
    for (final identity in identities) {
      if (identity.provider == provider) return identity;
    }
    return null;
  }
}

class _SignInMethodRowData {
  const _SignInMethodRowData({
    required this.id,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String id;
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
}

class _SignInMethodRow extends StatelessWidget {
  const _SignInMethodRow({super.key, required this.data});

  final _SignInMethodRowData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Fixed-width slot: the Apple glyph is narrower than Google's and
        // the envelope, so without it the titles don't line up.
        SizedBox(
          width: AppIconSize.medium,
          child: Center(child: data.leading),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Two lines, not one: in longer locales (de "Fortsetzen") the
              // trailing button squeezed the account email to "…necub.c…".
              Text(
                data.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.fieldLabel,
              ),
              SizedBox(height: data.subtitle == null ? 0 : AppSpacing.xs),
              SizedBox(
                child: data.subtitle == null
                    ? const SizedBox.shrink()
                    : Text(
                        data.subtitle!,
                        // Three: "pending change to" + an address beside a
                        // wide localized button (uk "Продовжити") needs it.
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ],
          ),
        ),
        SizedBox(width: data.trailing == null ? 0 : AppSpacing.sm),
        // Min height = the Link/Change button's, so swapping in the small
        // progress indicator doesn't shrink the row and jump the card.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppButton.heightSmall),
          child: Center(child: data.trailing ?? const SizedBox.shrink()),
        ),
      ],
    );
  }
}
