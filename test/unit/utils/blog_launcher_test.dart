import 'package:coffee_timer/utils/blog_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('keeps the blog path and tags the entry point with UTM params', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final uri = blogUri(source: 'hub');

    expect(uri.scheme, 'https');
    expect(uri.host, 'www.timer.coffee');
    expect(uri.path, '/blog/');
    expect(uri.queryParameters, {
      'utm_source': 'timer_coffee_app',
      'utm_medium': 'iOS',
      'utm_campaign': 'in_app_blog',
      'utm_content': 'hub',
    });
  });

  test('separates entry points and platforms', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final about = blogUri(source: 'about');

    expect(about.queryParameters['utm_content'], 'about');
    expect(about.queryParameters['utm_medium'], 'android');
  });
}
