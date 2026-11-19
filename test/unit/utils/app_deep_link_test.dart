import 'package:coffee_timer/app_router.dart';
import 'package:coffee_timer/utils/app_deep_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hostFormAppDeepLinkPath', () {
    test('moves the host into the path', () {
      expect(
        hostFormAppDeepLinkPath(Uri.parse('timercoffee://taste-profile')),
        '/taste-profile',
      );
      expect(
        hostFormAppDeepLinkPath(Uri.parse('timercoffee://beans/42?x=1')),
        '/beans/42?x=1',
      );
      expect(
        hostFormAppDeepLinkPath(Uri.parse('app://settings/privacy')),
        '/settings/privacy',
      );
      expect(
        hostFormAppDeepLinkPath(Uri.parse('timercofee://taste-profile')),
        '/taste-profile',
        reason: 'the legacy Android typo scheme is registered too',
      );
    });

    test('leaves links that already route, or must pass through, alone', () {
      // Triple slash: empty host, path already routes.
      expect(
        hostFormAppDeepLinkPath(Uri.parse('timercoffee:///taste-profile')),
        isNull,
      );
      // The Supabase auth callback.
      expect(hostFormAppDeepLinkPath(Uri.parse('timercoffee://')), isNull);
      expect(
        hostFormAppDeepLinkPath(Uri.parse('timercoffee://?code=abc')),
        isNull,
      );
      // Other schemes, including universal links.
      expect(
        hostFormAppDeepLinkPath(
          Uri.parse('https://app.timer.coffee/taste-profile'),
        ),
        isNull,
      );
      expect(hostFormAppDeepLinkPath(Uri.parse('/taste-profile')), isNull);
    });

    test('rewritten paths are known routes; unknown pages are not', () {
      final router = AppRouter();
      for (final link in [
        'timercoffee://taste-profile',
        'timercoffee://settings/privacy',
        'timercoffee://pulse',
        'timercoffee://hub',
        'timercoffee://beans',
      ]) {
        final path = hostFormAppDeepLinkPath(Uri.parse(link))!;
        expect(isKnownAppRoute(router, path), isTrue, reason: '$link → $path');
      }
      expect(
        isKnownAppRoute(
          router,
          hostFormAppDeepLinkPath(Uri.parse('timercoffee://nowhere'))!,
        ),
        isFalse,
        reason: 'unknown paths resolve to Home and are left as they came',
      );
    });
  });
}
