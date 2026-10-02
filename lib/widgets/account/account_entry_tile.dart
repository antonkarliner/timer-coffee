import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_router.gr.dart';
import '../../l10n/app_localizations.dart';
import '../../services/authentication_service.dart';
import '../../services/settings_analytics.dart';
import '../../theme/design_tokens.dart';
import '../../utils/app_logger.dart';
import 'account_identity.dart';

/// The account row shared by the Hub and the Settings root: signed in, it
/// shows who is signed in — avatar · display name · email
/// (`AccountIdentityTile`); signed out, it shows the sign-in prompt.
///
/// The styling replicates the Hub's `_HubListTile` (bodyLarge w600 title on
/// `onSurface`, bodySmall subtitle on `onSurfaceVariant`) so the tile is
/// pixel-identical in both places — do not restyle one without the other.
/// Unlike `SettingsNavRow` it has no chevron by default; [showChevron] opts
/// into the Settings rows' geometry (their content padding and a trailing
/// chevron) so the Settings root's chevron lines up with the other rows.
class AccountEntryTile extends StatefulWidget {
  const AccountEntryTile({
    super.key,
    required this.source,
    this.showChevron = false,
  });

  /// Where the tile sits, forwarded into the sign-in prompt analytics.
  final AccountEntrySource source;

  /// Settings-rows geometry: trailing chevron and their content padding.
  /// The Hub keeps the default (false).
  final bool showChevron;

  @override
  State<AccountEntryTile> createState() => _AccountEntryTileState();
}

class _AccountEntryTileState extends State<AccountEntryTile> {
  /// Bumped after returning from the account screen so the identity row
  /// re-reads its cache — a rename there must show on the tile on return.
  final ValueNotifier<int> _identityRevision = ValueNotifier<int>(0);

  @override
  void dispose() {
    _identityRevision.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      // The stream replays the session only after the first frame, so
      // without this a signed-in user saw the sign-in row flash on every
      // Settings or Hub visit.
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        final isLoggedIn = session != null && !session.user.isAnonymous;

        if (isLoggedIn) {
          return AccountIdentityTile(
            userId: session.user.id,
            email: session.user.email,
            identifier: 'account',
            refreshSignal: _identityRevision,
            showChevron: widget.showChevron,
            onTap: () async {
              SettingsAnalytics.accountEntryTapped(
                source: widget.source,
                signedIn: true,
              );
              await _openAccount(context);
            },
          );
        }

        return Semantics(
          identifier: 'signIn',
          label: l10n.signInCreate,
          child: ListTile(
            contentPadding: widget.showChevron
                ? const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.base,
                  )
                : null,
            leading: const Icon(Icons.login),
            title: Text(
              l10n.signInCreate,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              l10n.hubSignInCreateSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: widget.showChevron
                ? const Icon(Icons.chevron_right, size: AppIconSize.medium)
                : null,
            onTap: () {
              SettingsAnalytics.accountEntryTapped(
                source: widget.source,
                signedIn: false,
              );
              AuthenticationService.promptSignIn(
                context,
                source: widget.source == AccountEntrySource.hub
                    ? 'hub'
                    : 'settings',
                title: l10n.signInCreate,
                bodyText: l10n.hubSignInCreateSubtitle,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openAccount(BuildContext context) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    AppLogger.debug('Navigating to AccountRoute with userId: $userId');
    if (userId == null) return;
    await context.router.push(AccountRoute(userId: userId));
    if (!mounted) return;
    _identityRevision.value++;
  }
}
