import 'package:coffee_timer/services/roaster_color_service.dart';
import 'package:coffee_timer/widgets/roaster_contribution/contribution_ack_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('roasterLogoWillBeVisible', () {
    test('shows the logo when there is no colour information (SVG or fetch failure)', () {
      expect(roasterLogoWillBeVisible(const RoasterColorNone()), isTrue);
    });

    test('shows the logo when the mark is monochrome (near-black graphic)', () {
      expect(roasterLogoWillBeVisible(const RoasterColorMonochrome()), isTrue);
    });

    test('hides the real Coffee Gems cream mark (#FEF6E5) as invisible on a light chip', () {
      expect(
        roasterLogoWillBeVisible(const RoasterColorVibrant(Color(0xFFFEF6E5))),
        isFalse,
      );
    });

    test('shows the real Cold Crafters navy mark (#0F395F)', () {
      expect(
        roasterLogoWillBeVisible(const RoasterColorVibrant(Color(0xFF0F395F))),
        isTrue,
      );
    });

    test('shows a pure black mark', () {
      expect(
        roasterLogoWillBeVisible(const RoasterColorVibrant(Color(0xFF000000))),
        isTrue,
      );
    });

    test('hides a pure white mark', () {
      expect(
        roasterLogoWillBeVisible(const RoasterColorVibrant(Color(0xFFFFFFFF))),
        isFalse,
      );
    });
  });
}
