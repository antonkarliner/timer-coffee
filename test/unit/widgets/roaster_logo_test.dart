import 'package:coffee_timer/widgets/roaster_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RoasterLogo URL preference', () {
    const mirrorUrl = 'https://cdn.timer.coffee/logo.webp';

    test('chooses mirror for .gif original', () {
      expect(
        RoasterLogo.preferredInitialUrl(
          originalUrl: 'https://example.com/logo.gif',
          mirrorUrl: mirrorUrl,
        ),
        mirrorUrl,
      );
    });

    test('chooses mirror for format=gif original', () {
      expect(
        RoasterLogo.preferredInitialUrl(
          originalUrl: 'https://example.com/logo?format=gif',
          mirrorUrl: mirrorUrl,
        ),
        mirrorUrl,
      );
    });

    test('chooses mirror for fm=gif original', () {
      expect(
        RoasterLogo.preferredInitialUrl(
          originalUrl: 'https://example.com/logo?fm=gif',
          mirrorUrl: mirrorUrl,
        ),
        mirrorUrl,
      );
    });

    test('keeps GIF original when no mirror exists', () {
      const originalUrl = 'https://example.com/logo.gif';

      expect(
        RoasterLogo.preferredInitialUrl(
          originalUrl: originalUrl,
          mirrorUrl: null,
        ),
        originalUrl,
      );
    });

    test('keeps GIF original when mirror URL is empty', () {
      const originalUrl = 'https://example.com/logo.gif';

      expect(
        RoasterLogo.preferredInitialUrl(
          originalUrl: originalUrl,
          mirrorUrl: '',
        ),
        originalUrl,
      );
      expect(
        RoasterLogo.preferredInitialUrl(
          originalUrl: originalUrl,
          mirrorUrl: '   ',
        ),
        originalUrl,
      );
    });

    test('returns null when original URL is empty', () {
      expect(
        RoasterLogo.preferredInitialUrl(originalUrl: '', mirrorUrl: mirrorUrl),
        isNull,
      );
      expect(
        RoasterLogo.preferredInitialUrl(
          originalUrl: '   ',
          mirrorUrl: mirrorUrl,
        ),
        isNull,
      );
    });

    test('keeps non-GIF original even when mirror exists', () {
      for (final originalUrl in [
        'https://example.com/logo.png',
        'https://example.com/logo.webp',
        'https://example.com/logo.jpg',
        'https://example.com/logo.svg',
      ]) {
        expect(
          RoasterLogo.preferredInitialUrl(
            originalUrl: originalUrl,
            mirrorUrl: mirrorUrl,
          ),
          originalUrl,
        );
      }
    });

    test('trims URL values before choosing', () {
      expect(
        RoasterLogo.preferredInitialUrl(
          originalUrl: '  https://example.com/logo.gif  ',
          mirrorUrl: '  $mirrorUrl  ',
        ),
        mirrorUrl,
      );
    });
  });

  group('RoasterLogo rendering', () {
    testWidgets('renders fallback icon for empty logo URLs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoasterLogo(originalUrl: '   ', mirrorUrl: ''),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Icon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
