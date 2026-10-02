import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/design_tokens.dart';
import '../../utils/app_logger.dart';
import '../account_avatar_inline.dart';

const String _displayNameKey = 'user_display_name';
const String _displayNameUserIdKey = 'user_display_name_user_id';

// The last name resolved this session. SharedPreferences only arrives
// asynchronously, so without this every Settings or Hub visit would draw
// "Account" for a frame before the name.
String? _sessionName;
String? _sessionNameUserId;

String? _sessionNameFor(String userId) =>
    _sessionNameUserId == userId ? _sessionName : null;

void _rememberSessionName(String userId, String name) {
  _sessionNameUserId = userId;
  _sessionName = name;
}

/// Forgets the session's resolved name, so each test starts cold.
@visibleForTesting
void resetAccountIdentitySessionName() {
  _sessionName = null;
  _sessionNameUserId = null;
}

/// Fetches the display name of [userId] from `user_public_profiles`.
///
/// The default fetch behind [AccountIdentityTile.fetchDisplayName]; inject a
/// replacement to run without a backend. Returns null when the profile has no
/// display name (or no profile).
Future<String?> fetchAccountDisplayName(String userId) async {
  final response = await Supabase.instance.client
      .from('user_public_profiles')
      .select('display_name')
      .eq('user_id', userId)
      .maybeSingle();
  return response?['display_name'] as String?;
}

/// The display name cached for [userId], or null when it cannot be trusted.
///
/// Mirrors the avatar cache in `AccountAvatarInline`: a cached value is shown
/// only when the companion `user_display_name_user_id` key names the same
/// user — a missing or foreign id key means the name may belong to a
/// previously signed-in account, so it is never shown.
String? readTrustedDisplayName(SharedPreferences prefs, String userId) {
  final cachedUserId = prefs.getString(_displayNameUserIdKey);
  if (cachedUserId != userId) return null;
  final name = prefs.getString(_displayNameKey);
  if (name == null || name.isEmpty) return null;
  return name;
}

/// Caches [name] together with the id of the user it belongs to.
///
/// Both keys must be written together so [readTrustedDisplayName] can vouch
/// for the name later. The account screen's rename path keeps writing only
/// the name; that still reads as trusted because the id key this widget wrote
/// earlier for the same user stays valid.
Future<void> writeDisplayNameCache(
  SharedPreferences prefs,
  String userId,
  String name,
) async {
  await prefs.setString(_displayNameKey, name);
  await prefs.setString(_displayNameUserIdKey, userId);
}

/// The signed-in account row: avatar · display name · email.
///
/// The display name is resolved for [userId]: on the first frame the cached
/// name if it is trusted (see [readTrustedDisplayName]), otherwise the plain
/// "Account" label; then a fetch (injectable via [fetchDisplayName] so tests
/// run without a backend) updates the title and, when it returns a name,
/// writes the cache for the next launch. A failed fetch keeps what is shown
/// and is only logged — this widget never throws. Anonymous users never reach
/// this row, and an empty [userId] never fetches.
///
/// Bump [refreshSignal] to make the row re-read the cache and refetch — the
/// host does this after returning from the account screen, so a rename there
/// is on the tile when the user comes back.
///
/// The styling replicates the Hub's `_HubListTile` (bodyLarge w600 title on
/// `onSurface`, bodySmall subtitle on `onSurfaceVariant`); with
/// [showChevron] it takes the Settings rows' geometry instead (their content
/// padding and a trailing chevron) so the chevron lines up with theirs.
class AccountIdentityTile extends StatefulWidget {
  const AccountIdentityTile({
    super.key,
    required this.userId,
    this.email,
    this.fetchDisplayName = fetchAccountDisplayName,
    this.identifier = 'account',
    this.refreshSignal,
    this.showChevron = false,
    required this.onTap,
  });

  /// The signed-in user the row resolves the name for.
  final String userId;

  /// The user's email; shown as the subtitle when present (an Apple
  /// private-relay address is fine). No email, no subtitle.
  final String? email;

  /// Fetches the display name for [userId]; defaults to
  /// [fetchAccountDisplayName].
  final Future<String?> Function(String userId) fetchDisplayName;

  /// Semantics identifier of the row.
  final String identifier;

  /// Bumped by the host when the cache should be re-read (see the class
  /// docs).
  final ValueListenable<int>? refreshSignal;

  /// Settings-rows geometry: trailing chevron and their content padding.
  final bool showChevron;

  final VoidCallback onTap;

  @override
  State<AccountIdentityTile> createState() => _AccountIdentityTileState();
}

class _AccountIdentityTileState extends State<AccountIdentityTile> {
  String? _displayName;

  /// Guards against a stale in-flight resolve clobbering a fresher one.
  int _resolveEpoch = 0;

  @override
  void initState() {
    super.initState();
    _displayName = _sessionNameFor(widget.userId);
    widget.refreshSignal?.addListener(_onRefreshSignal);
    _resolveName();
  }

  @override
  void didUpdateWidget(AccountIdentityTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshSignal != oldWidget.refreshSignal) {
      oldWidget.refreshSignal?.removeListener(_onRefreshSignal);
      widget.refreshSignal?.addListener(_onRefreshSignal);
    }
    if (widget.userId != oldWidget.userId) {
      // Never leave the previous user's name up while the new one resolves.
      _displayName = _sessionNameFor(widget.userId);
      _resolveName();
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_onRefreshSignal);
    super.dispose();
  }

  void _onRefreshSignal() => _resolveName();

  Future<void> _resolveName() async {
    final epoch = ++_resolveEpoch;
    final prefs = await SharedPreferences.getInstance();
    final cached = readTrustedDisplayName(prefs, widget.userId) ??
        _sessionNameFor(widget.userId);
    if (!mounted || epoch != _resolveEpoch) return;
    if (cached != null) _rememberSessionName(widget.userId, cached);
    setState(() => _displayName = cached);
    if (widget.userId.isEmpty) return; // No user, no fetch.

    String? fetched;
    try {
      fetched = await widget.fetchDisplayName(widget.userId);
    } catch (e, stackTrace) {
      // Keep what is shown; never surface a profile fetch as an error.
      AppLogger.error(
        'Failed to fetch account display name',
        errorObject: e,
        stackTrace: stackTrace,
      );
      return;
    }
    if (!mounted || epoch != _resolveEpoch) return;
    if (fetched == null || fetched.isEmpty) return;
    _rememberSessionName(widget.userId, fetched);
    await writeDisplayNameCache(prefs, widget.userId, fetched);
    if (!mounted || epoch != _resolveEpoch) return;
    setState(() => _displayName = fetched);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = _displayName ?? l10n.account;

    return Semantics(
      identifier: widget.identifier,
      label: title,
      child: ListTile(
        contentPadding: widget.showChevron
            ? const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.base)
            : null,
        leading: const AccountAvatarInline(size: AppIconSize.medium),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          // bodyLarge merged with the itemTitle token keeps today's letter
          // spacing and height (the token only pins size and weight).
          style: theme.textTheme.bodyLarge
              ?.merge(AppTextStyles.itemTitle)
              .copyWith(color: theme.colorScheme.onSurface),
        ),
        subtitle: widget.email == null || widget.email!.isEmpty
            ? null
            : Text(
                widget.email!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        trailing: widget.showChevron
            ? const Icon(Icons.chevron_right, size: AppIconSize.medium)
            : null,
        onTap: widget.onTap,
      ),
    );
  }
}
