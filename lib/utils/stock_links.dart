import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Adds Timer.Coffee UTM parameters to an in-stock bean's product link.
///
/// Only http/https URLs are accepted — anything else (or an unparseable
/// string) returns null and the link is not offered. UTM parameters the
/// roaster already put on their link are preserved, not overwritten.
///
/// [campaign] distinguishes the surfaces the same product link is opened
/// from: `for_you` (the Hub card) and `roaster_profile` (the roaster's
/// "In stock now" section).
Uri? buildStockProductUrl(String? rawUrl, {required String campaign}) {
  if (rawUrl == null) return null;
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  Map<String, String> params;
  try {
    params = Map<String, String>.from(uri.queryParameters);
  } on FormatException {
    // Malformed percent-encoding in the query: open the link as-is rather
    // than lose it (or crash) over attribution.
    return uri;
  }
  final utm = {
    'utm_source': 'timer.coffee',
    'utm_medium': 'app',
    'utm_campaign': campaign,
  };
  utm.forEach((key, value) => params.putIfAbsent(key, () => value));
  return uri.replace(queryParameters: params);
}

/// Launch mode for a stock product link: the in-app browser
/// (SFSafariViewController on iOS, Custom Tabs on Android) so the user stays
/// in the app; on web the platform default. A parameter instead of the
/// `kIsWeb` constant so the choice is unit-testable without a platform
/// channel.
LaunchMode stockLaunchMode({bool isWeb = kIsWeb}) =>
    isWeb ? LaunchMode.platformDefault : LaunchMode.inAppBrowserView;

/// Opens a stock product link: the in-app browser first, falling back to the
/// system browser when the device has no in-app surface (or the plugin
/// channel is missing, e.g. in tests). Never throws; if no app can open the
/// link, nothing happens.
Future<void> launchStockProductLink(Uri uri, {bool isWeb = kIsWeb}) async {
  try {
    if (await launchUrl(uri, mode: stockLaunchMode(isWeb: isWeb))) return;
  } catch (_) {
    // No in-app surface on this device (or the plugin channel is missing,
    // e.g. in tests): fall back to the system browser below.
  }
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // No app on this device can open the link; nothing to show.
  }
}
