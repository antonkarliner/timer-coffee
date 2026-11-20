import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'input_validator.dart';

/// Older builds saved a launch marker for mere notification receipt.
Future<void> discardLegacyNotificationLaunch(SharedPreferences prefs) async {
  await prefs.remove('pending_external_url');
}

/// Consume a verified tap so a rebuilt account router cannot replay it.
StreamSubscription<String?> consumeNotificationTapLinks(
  BehaviorSubject<String?> taps,
  void Function(String) onTap,
) => taps.listen((payload) {
  final link = payload?.trim();
  if (link == null || link.isEmpty) return;
  taps.add(null);
  onTap(link);
});

Uri? validatedExternalNotificationUri(String link) {
  final uri = Uri.tryParse(link);
  if (uri == null ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      !InputValidator.isValidWebsiteUrl(uri.toString())) {
    return null;
  }
  return uri;
}
