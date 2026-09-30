import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_router.gr.dart';
import '../../l10n/app_localizations.dart';
import '../../services/authentication_service.dart';
import '../../services/settings_analytics.dart';
import '../../utils/app_logger.dart';
import '../account_avatar_inline.dart';

/// The account row shared by the Hub and the Settings root: the signed-in
/// avatar row, or the sign-in prompt row when nobody is signed in.
///
/// The styling replicates the Hub's `_HubListTile` (bodyLarge w600 title on
/// `onSurface`, bodySmall subtitle on `onSurfaceVariant`) so the tile is
/// pixel-identical in both places — do not restyle one without the other.
/// Unlike `SettingsNavRow` it has no chevron and no content-padding override.
class AccountEntryTile extends StatelessWidget {
  const AccountEntryTile({super.key, required this.source});

  /// Where the tile sits, forwarded into the sign-in prompt analytics.
  final AccountEntrySource source;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        final isLoggedIn = session != null && !session.user.isAnonymous;

        if (isLoggedIn) {
          return _hubStyleTile(
            context,
            identifier: 'account',
            label: l10n.account,
            leading: const AccountAvatarInline(size: 24),
            title: l10n.account,
            subtitle: l10n.hubAccountSubtitle,
            onTap: () {
              SettingsAnalytics.accountEntryTapped(
                source: source,
                signedIn: true,
              );
              _openAccount(context);
            },
          );
        }

        return _hubStyleTile(
          context,
          identifier: 'signIn',
          label: l10n.signInCreate,
          leading: const Icon(Icons.login),
          title: l10n.signInCreate,
          subtitle: l10n.hubSignInCreateSubtitle,
          onTap: () {
            SettingsAnalytics.accountEntryTapped(
              source: source,
              signedIn: false,
            );
            AuthenticationService.promptSignIn(
              context,
              source: source == AccountEntrySource.hub ? 'hub' : 'settings',
              title: l10n.signInCreate,
              bodyText: l10n.hubSignInCreateSubtitle,
            );
          },
        );
      },
    );
  }

  void _openAccount(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    AppLogger.debug('Navigating to AccountRoute with userId: $userId');
    if (userId != null) {
      context.router.push(AccountRoute(userId: userId));
    }
  }

  Widget _hubStyleTile(
    BuildContext context, {
    required String identifier,
    required String label,
    required Widget leading,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Semantics(
      identifier: identifier,
      label: label,
      child: ListTile(
        leading: leading,
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
