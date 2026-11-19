import 'package:coffee_timer/app_router.dart';
import 'package:coffee_timer/app_router.gr.dart';

/// Custom URL schemes the app registers (`timercoffee`, plus the legacy
/// `timercofee` typo on Android and the `app` scheme used in push payloads).
const appDeepLinkSchemes = {'timercoffee', 'timercofee', 'app'};

/// The in-app route path for a custom-scheme link written with the page in
/// the host position, e.g. `timercoffee://taste-profile` → `/taste-profile`
/// and `timercoffee://beans/42?x=1` → `/beans/42?x=1`.
///
/// The router matches only `uri.path`, so without this a two-slash link
/// lands on Home. Returns null when nothing needs rewriting: other schemes,
/// links with no host (`timercoffee:///settings` already routes; the bare
/// `timercoffee://` auth callback must pass through untouched), or a host
/// that yields an empty path.
String? hostFormAppDeepLinkPath(Uri uri) {
  if (!appDeepLinkSchemes.contains(uri.scheme.toLowerCase())) return null;
  if (uri.host.isEmpty) return null;
  final path = '/${uri.host}${uri.path}';
  if (path == '/') return null;
  return uri.hasQuery ? '$path?${uri.query}' : path;
}

/// Whether [path] names a real page. The matcher resolves any unknown path
/// to Home's default tab (Brew Coffee), so that outcome counts as unknown;
/// `/hub` and `/beans` still count, as does every top-level route.
bool isKnownAppRoute(AppRouter router, String path) {
  final matches = router.matcher.matchUri(
    Uri.parse(path),
    includePrefixMatches: false,
  );
  if (matches == null || matches.isEmpty) return false;
  if (matches.length != 1 || matches.first.name != HomeRoute.name) {
    return true;
  }
  return matches.first.children?.firstOrNull?.name != BrewingMethodsRoute.name;
}
