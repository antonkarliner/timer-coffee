import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/analytics_service.dart';
import 'app_logger.dart';

/// Public blog on the marketing site.
const String blogUrl = 'https://www.timer.coffee/blog/';

/// Builds the blog URL tagged with UTM parameters so in-app traffic is
/// distinguishable in the website's analytics.
///
/// `utm_medium` is the platform so app traffic can be split from web, and
/// `utm_content` is the in-app entry point ([source]).
Uri blogUri({required String source}) {
  final String medium;
  if (kIsWeb) {
    medium = 'web_app';
  } else {
    medium = defaultTargetPlatform.name; // ios / android / macOS / …
  }
  return Uri.parse(blogUrl).replace(
    queryParameters: {
      'utm_source': 'timer_coffee_app',
      'utm_medium': medium,
      'utm_campaign': 'in_app_blog',
      'utm_content': source,
    },
  );
}

/// Opens the blog in an in-app browser (SFSafariViewController on iOS, Custom
/// Tabs on Android) so the user stays in the app, falling back to the system
/// browser when the platform has no in-app surface.
///
/// [source] identifies the entry point for analytics (e.g. `hub`, `about`).
Future<void> openBlog({required String source}) async {
  AnalyticsService.maybeInstance?.track(
    'blog_opened',
    properties: {'source': source},
  );

  final uri = blogUri(source: source);
  for (final mode in _launchModes()) {
    try {
      if (await launchUrl(uri, mode: mode)) return;
    } catch (e) {
      AppLogger.debug('Blog launch failed with mode $mode: $e');
    }
  }
  AppLogger.error('Could not open blog URL: $uri');
}

List<LaunchMode> _launchModes() {
  if (kIsWeb) {
    return const [LaunchMode.platformDefault];
  }
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android) {
    return const [LaunchMode.inAppBrowserView, LaunchMode.externalApplication];
  }
  return const [LaunchMode.externalApplication];
}
