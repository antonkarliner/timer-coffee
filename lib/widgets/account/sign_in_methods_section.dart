import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../services/account_identity_service.dart';
import '../../theme/design_tokens.dart';
import '../base_buttons.dart';
import 'change_email_sheet.dart';

class SignInMethodsSection extends StatefulWidget {
  const SignInMethodsSection({super.key, this.service});

  final AccountIdentityService? service;

  @override
  State<SignInMethodsSection> createState() => _SignInMethodsSectionState();
}

class _SignInMethodsSectionState extends State<SignInMethodsSection> {
  late final AccountIdentityService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AccountIdentityService();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final user = Supabase.instance.client.auth.currentUser;
        final rows = <_SignInMethodRowData>[];
        final email = user?.email;

        if (email != null) {
          final pendingEmail = user?.newEmail;
          rows.add(
            _SignInMethodRowData(
              icon: Icons.email_outlined,
              title: email,
              subtitle: pendingEmail == null
                  ? null
                  : l10n.accountSignInPendingEmail(pendingEmail),
              trailing: _service.canChangeEmail
                  ? AppTextButton(
                      label: pendingEmail == null
                          ? l10n.accountSignInChange
                          : l10n.accountSignInContinue,
                      onPressed: () => showChangeEmailSheet(
                        context,
                        service: _service,
                        pendingNewEmail: pendingEmail,
                      ),
                      isFullWidth: false,
                      height: AppButton.heightSmall,
                      padding: AppButton.paddingSmall,
                    )
                  : null,
            ),
          );
        }

        // No header on purpose: a "Sign-in" title read as a call to action,
        // and each row (email now, linked providers in plan 073 Phase 3)
        // describes itself. Same Card as SectionCard, without its header.
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
                    _SignInMethodRow(data: rows[index]),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignInMethodRowData {
  const _SignInMethodRowData({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
}

class _SignInMethodRow extends StatelessWidget {
  const _SignInMethodRow({required this.data});

  final _SignInMethodRowData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          data.icon,
          size: AppIconSize.medium,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.fieldLabel,
              ),
              if (data.subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  data.subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (data.trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          data.trailing!,
        ],
      ],
    );
  }
}
