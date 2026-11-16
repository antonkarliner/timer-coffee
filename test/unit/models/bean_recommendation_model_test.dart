import 'package:coffee_timer/models/bean_recommendation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The exact payload shape documented for RPC `get_my_recommendations`.
  Map<String, dynamic> fullItemJson() => {
    'stock_id': '0f2f9d1e-1c3b-4a2d-9f6e-5a7b8c9d0e1f',
    'roaster_profile_id': 'a1b2c3d4-1111-2222-3333-444455556666',
    'roaster_slug': 'botanica',
    'roaster_name': 'Botanica Coffee Roasters',
    'roaster_logo_url': 'https://cdn.example.com/logo.png',
    'roaster_logo_mirror_url': 'https://mirror.example.com/logo.png',
    'dominant_color_hex': '#A0642F',
    'bean_name': 'Yirgacheffe Washed',
    'image_url': 'https://cdn.example.com/bag.png',
    'origin_country_codes': ['ET'],
    'process_family': 'washed',
    'roast_level': 'light',
    'flavor_families': ['berry', 'citrus'],
    'price_amount': 14.5,
    'currency': 'EUR',
    'product_url': 'https://shop.example.com/yirgacheffe',
    'reason': 'You brewed washed Ethiopians all month.',
    'mode': 'your_roaster',
  };

  Map<String, dynamic> fullResultJson() => {
    'has_recommendations': true,
    'generated_at': '2026-11-16T10:00:00+00:00',
    'stale': false,
    'items': [fullItemJson()],
  };

  group('BeanRecommendation.fromJson', () {
    test('parses a full item', () {
      final item = BeanRecommendation.fromJson(fullItemJson())!;
      expect(item.stockId, '0f2f9d1e-1c3b-4a2d-9f6e-5a7b8c9d0e1f');
      expect(item.roasterProfileId, 'a1b2c3d4-1111-2222-3333-444455556666');
      expect(item.roasterSlug, 'botanica');
      expect(item.roasterName, 'Botanica Coffee Roasters');
      expect(item.roasterLogoUrl, 'https://cdn.example.com/logo.png');
      expect(item.roasterLogoMirrorUrl, 'https://mirror.example.com/logo.png');
      expect(item.dominantColorHex, '#A0642F');
      expect(item.beanName, 'Yirgacheffe Washed');
      expect(item.imageUrl, 'https://cdn.example.com/bag.png');
      expect(item.originCountryCodes, ['ET']);
      expect(item.processFamily, 'washed');
      expect(item.roastLevel, 'light');
      expect(item.flavorFamilies, ['berry', 'citrus']);
      expect(item.priceAmount, 14.5);
      expect(item.currency, 'EUR');
      expect(item.productUrl, 'https://shop.example.com/yirgacheffe');
      expect(item.reason, 'You brewed washed Ethiopians all month.');
      expect(item.mode, 'your_roaster');
    });

    test('parses nullable and optional fields when missing', () {
      final item = BeanRecommendation.fromJson({
        'stock_id': 'stock-1',
        'bean_name': 'Kirinyaga AA',
        'roaster_name': 'Kompanion',
      })!;
      expect(item.roasterProfileId, isNull);
      expect(item.roasterSlug, isNull);
      expect(item.roasterLogoUrl, isNull);
      expect(item.roasterLogoMirrorUrl, isNull);
      expect(item.dominantColorHex, isNull);
      expect(item.imageUrl, isNull);
      expect(item.originCountryCodes, isEmpty);
      expect(item.processFamily, isNull);
      expect(item.roastLevel, isNull);
      expect(item.flavorFamilies, isEmpty);
      expect(item.priceAmount, isNull);
      expect(item.currency, isNull);
      expect(item.productUrl, isNull);
      expect(item.reason, isNull);
      expect(item.mode, isNull);
    });

    test('skips an item without a usable stock_id', () {
      final json = fullItemJson()..remove('stock_id');
      expect(BeanRecommendation.fromJson(json), isNull);
    });

    test('skips an item with a blank bean_name', () {
      final json = fullItemJson()..['bean_name'] = '   ';
      expect(BeanRecommendation.fromJson(json), isNull);
    });

    test('skips an item with a wrong-typed roaster_name', () {
      final json = fullItemJson()..['roaster_name'] = 42;
      expect(BeanRecommendation.fromJson(json), isNull);
    });

    test('returns null for a non-map payload and never throws', () {
      expect(BeanRecommendation.fromJson(null), isNull);
      expect(BeanRecommendation.fromJson('nope'), isNull);
      expect(BeanRecommendation.fromJson(7), isNull);
    });

    test('parses int price and numeric-string price', () {
      expect(
        BeanRecommendation.fromJson(
          fullItemJson()..['price_amount'] = 12,
        )!.priceAmount,
        12.0,
      );
      expect(
        BeanRecommendation.fromJson(
          fullItemJson()..['price_amount'] = '13.25',
        )!.priceAmount,
        13.25,
      );
      expect(
        BeanRecommendation.fromJson(
          fullItemJson()..['price_amount'] = 'cheap',
        )!.priceAmount,
        isNull,
      );
    });

    test('drops non-string entries from list fields', () {
      final item = BeanRecommendation.fromJson(
        fullItemJson()
          ..['flavor_families'] = ['berry', 3, null, 'citrus']
          ..['origin_country_codes'] = 'ET',
      )!;
      expect(item.flavorFamilies, ['berry', 'citrus']);
      expect(item.originCountryCodes, isEmpty);
    });

    test('trims usable string fields', () {
      final item = BeanRecommendation.fromJson(
        fullItemJson()
          ..['stock_id'] = '  stock-9  '
          ..['bean_name'] = ' Bean '
          ..['roaster_name'] = ' Roaster ',
      )!;
      expect(item.stockId, 'stock-9');
      expect(item.beanName, 'Bean');
      expect(item.roasterName, 'Roaster');
    });
  });

  group('RecommendationResult.fromJson', () {
    test('parses a full result', () {
      final result = RecommendationResult.fromJson(fullResultJson())!;
      expect(result.hasRecommendations, isTrue);
      expect(result.stale, isFalse);
      expect(result.generatedAt, DateTime.utc(2026, 11, 16, 10));
      expect(result.items, hasLength(1));
      expect(result.items.first.beanName, 'Yirgacheffe Washed');
    });

    test('returns null for null and non-map payloads', () {
      // The RPC returns JSON null when there is no session.
      expect(RecommendationResult.fromJson(null), isNull);
      expect(RecommendationResult.fromJson('[]'), isNull);
      expect(RecommendationResult.fromJson([1, 2]), isNull);
    });

    test('parses the never-generated shape', () {
      final result = RecommendationResult.fromJson({
        'has_recommendations': false,
        'stale': true,
        'items': <dynamic>[],
      })!;
      expect(result.hasRecommendations, isFalse);
      expect(result.stale, isTrue);
      expect(result.items, isEmpty);
    });

    test('defaults missing/invalid scalars defensively', () {
      final result = RecommendationResult.fromJson({
        'stale': 'yes',
        'generated_at': 123,
        'items': 'not-a-list',
      })!;
      expect(result.hasRecommendations, isFalse);
      expect(result.stale, isFalse);
      expect(result.generatedAt, isNull);
      expect(result.items, isEmpty);
    });

    test('parses an invalid generated_at string to null', () {
      final result = RecommendationResult.fromJson(
        fullResultJson()..['generated_at'] = 'not a date',
      )!;
      expect(result.generatedAt, isNull);
    });

    test('skips unusable items but keeps usable ones', () {
      final result = RecommendationResult.fromJson(
        fullResultJson()
          ..['items'] = [
            fullItemJson(),
            {'bean_name': 'no stock id'},
            'not-a-map',
          ],
      )!;
      expect(result.items, hasLength(1));
      expect(result.items.first.roasterSlug, 'botanica');
    });

    test('accepts an empty items list (valid nothing-to-show answer)', () {
      final result = RecommendationResult.fromJson(
        fullResultJson()..['items'] = <dynamic>[],
      )!;
      expect(result.hasRecommendations, isTrue);
      expect(result.items, isEmpty);
    });
  });

  group('BeanRecommendationStatus.fromWire', () {
    test('maps known wire values', () {
      expect(BeanRecommendationStatus.fromWire('ok'),
          BeanRecommendationStatus.ok);
      expect(BeanRecommendationStatus.fromWire('insufficient_history'),
          BeanRecommendationStatus.insufficientHistory);
      expect(BeanRecommendationStatus.fromWire('no_supply'),
          BeanRecommendationStatus.noSupply);
    });

    test('maps anything else to unknown', () {
      expect(BeanRecommendationStatus.fromWire('banana'),
          BeanRecommendationStatus.unknown);
      expect(BeanRecommendationStatus.fromWire(null),
          BeanRecommendationStatus.unknown);
      expect(BeanRecommendationStatus.fromWire(429),
          BeanRecommendationStatus.unknown);
    });
  });
}
