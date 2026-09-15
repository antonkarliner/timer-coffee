import 'dart:async';
import 'dart:convert';

import 'package:coffee_timer/services/roaster_directory_service.dart';
import 'package:coffee_timer/utils/persistent_ttl_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const bundle = <String, String?>{
    'profile_id': 'profile-1',
    'slug': 'test-roaster',
    'roaster_logo_url': 'https://example.test/original.png',
    'roaster_logo_mirror_url': 'https://example.test/mirror.webp',
    'dominant_color_hex': '#123456',
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> seedCache({
    required String prefix,
    required String key,
    required Map<String, dynamic> data,
    required Duration age,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$prefix$key',
      jsonEncode({
        'ts': DateTime.now().subtract(age).millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  test(
    'miss becomes a catalog hit after the five-minute TTL expires',
    () async {
      var calls = 0;
      const prefix = 'roaster_directory_miss_then_hit_';
      final service = RoasterDirectoryService.forTesting(
        bundleLoader: (_) async => ++calls == 1 ? null : bundle,
        persistentCache: PersistentTtlCache(prefix),
      );

      expect(await service.fetchBundle('Test Roaster'), isNull);
      expect(calls, 1);

      await seedCache(
        prefix: prefix,
        key: 'test roaster',
        data: {'found': false},
        age: const Duration(minutes: 6),
      );

      expect(await service.fetchBundle('Test Roaster'), bundle);
      expect(calls, 2);
      expect(service.peekBundle('Test Roaster'), bundle);
    },
  );

  test('a fresh persistent miss never becomes an in-memory negative', () async {
    var calls = 0;
    const prefix = 'roaster_directory_negative_memory_';
    final service = RoasterDirectoryService.forTesting(
      bundleLoader: (_) async {
        calls++;
        return null;
      },
      persistentCache: PersistentTtlCache(prefix),
    );

    expect(await service.fetchBundle('Missing Roaster'), isNull);
    expect(await service.fetchBundle('Missing Roaster'), isNull);

    expect(calls, 1);
    expect(service.isCached('Missing Roaster'), isFalse);
    expect(service.peekBundle('Missing Roaster'), isNull);
  });

  test('a positive hit keeps the in-memory fast path', () async {
    var calls = 0;
    final service = RoasterDirectoryService.forTesting(
      bundleLoader: (_) async {
        calls++;
        return bundle;
      },
      persistentCache: PersistentTtlCache('roaster_directory_positive_'),
    );

    expect(await service.fetchBundle('Test Roaster'), bundle);
    expect(await service.fetchBundle('test roaster'), bundle);

    expect(calls, 1);
    expect(service.isCached('TEST ROASTER'), isTrue);
  });

  test('concurrent normalized lookups share one loader call', () async {
    var calls = 0;
    final response = Completer<Map<String, String?>?>();
    final service = RoasterDirectoryService.forTesting(
      bundleLoader: (_) {
        calls++;
        return response.future;
      },
      persistentCache: PersistentTtlCache('roaster_directory_concurrent_'),
    );

    final first = service.fetchBundle('Café Roaster');
    final second = service.fetchBundle(' cafe roaster ');
    await Future<void>.delayed(Duration.zero);

    expect(calls, 1);
    response.complete(bundle);
    expect(await Future.wait([first, second]), [bundle, bundle]);
  });

  test(
    'a network failure without a positive fallback remains retryable',
    () async {
      var calls = 0;
      final service = RoasterDirectoryService.forTesting(
        bundleLoader: (_) async {
          calls++;
          if (calls == 1) throw StateError('offline');
          return bundle;
        },
        persistentCache: PersistentTtlCache('roaster_directory_retry_'),
      );

      await expectLater(service.fetchBundle('Test Roaster'), throwsStateError);
      expect(service.isCached('Test Roaster'), isFalse);
      expect(await service.fetchBundle('Test Roaster'), bundle);
      expect(calls, 2);
    },
  );

  test(
    'an expired positive remains the stale fallback on refresh error',
    () async {
      var calls = 0;
      const prefix = 'roaster_directory_stale_positive_';
      await seedCache(
        prefix: prefix,
        key: 'test roaster',
        data: {'found': true, ...bundle},
        age: const Duration(days: 8),
      );
      final service = RoasterDirectoryService.forTesting(
        bundleLoader: (_) async {
          calls++;
          throw StateError('offline');
        },
        persistentCache: PersistentTtlCache(prefix),
      );

      expect(await service.fetchBundle('Test Roaster'), bundle);
      expect(calls, 1);
      expect(service.isCached('Test Roaster'), isTrue);
    },
  );

  test(
    'an expired negative is not a stale fallback for a refresh error',
    () async {
      var calls = 0;
      const prefix = 'roaster_directory_stale_negative_';
      await seedCache(
        prefix: prefix,
        key: 'missing roaster',
        data: {'found': false},
        age: const Duration(minutes: 6),
      );
      final service = RoasterDirectoryService.forTesting(
        bundleLoader: (_) async {
          calls++;
          throw StateError('offline');
        },
        persistentCache: PersistentTtlCache(prefix),
      );

      await expectLater(
        service.fetchBundle('Missing Roaster'),
        throwsStateError,
      );
      await expectLater(
        service.fetchBundle('Missing Roaster'),
        throwsStateError,
      );
      expect(calls, 2);
      expect(service.isCached('Missing Roaster'), isFalse);
    },
  );

  test('explicit clear removes positive memory and persistent data', () async {
    var calls = 0;
    const prefix = 'roaster_directory_explicit_clear_';
    final cache = PersistentTtlCache(prefix);
    final service = RoasterDirectoryService.forTesting(
      bundleLoader: (_) async {
        calls++;
        return bundle;
      },
      persistentCache: cache,
    );

    expect(await service.fetchBundle('Test Roaster'), bundle);
    expect(service.isCached('Test Roaster'), isTrue);
    expect(await cache.read('test roaster'), isNotNull);

    await service.clearCache();

    expect(service.isCached('Test Roaster'), isFalse);
    expect(await cache.read('test roaster'), isNull);
    expect(await service.fetchBundle('Test Roaster'), bundle);
    expect(calls, 2);
  });

  test('explicit clear makes a fresh cached miss retry immediately', () async {
    var calls = 0;
    final service = RoasterDirectoryService.forTesting(
      bundleLoader: (_) async => ++calls == 1 ? null : bundle,
      persistentCache: PersistentTtlCache(
        'roaster_directory_explicit_negative_clear_',
      ),
    );

    expect(await service.fetchBundle('New Roaster'), isNull);
    expect(await service.fetchBundle('New Roaster'), isNull);
    expect(calls, 1);

    await service.clearCache();

    expect(await service.fetchBundle('New Roaster'), bundle);
    expect(calls, 2);
  });

  test('a pre-clear lookup cannot repopulate invalidated caches', () async {
    var calls = 0;
    final firstResponse = Completer<Map<String, String?>?>();
    const prefix = 'roaster_directory_clear_race_';
    final cache = PersistentTtlCache(prefix);
    final service = RoasterDirectoryService.forTesting(
      bundleLoader: (_) {
        calls++;
        return calls == 1 ? firstResponse.future : Future.value(bundle);
      },
      persistentCache: cache,
    );

    final staleLookup = service.fetchBundle('Test Roaster');
    await Future<void>.delayed(Duration.zero);
    await service.clearCache();
    firstResponse.complete(bundle);

    expect(await staleLookup, bundle);
    expect(service.isCached('Test Roaster'), isFalse);
    expect(await cache.read('test roaster'), isNull);

    expect(await service.fetchBundle('Test Roaster'), bundle);
    expect(calls, 2);
  });

  test('clear removes a persistent write that was already underway', () async {
    final cache = _BlockingPersistentTtlCache(
      'roaster_directory_clear_write_race_',
    );
    final service = RoasterDirectoryService.forTesting(
      bundleLoader: (_) async => bundle,
      persistentCache: cache,
    );

    final lookup = service.fetchBundle('Test Roaster');
    await cache.writeStarted.future;
    final clear = service.clearCache();
    await Future<void>.delayed(Duration.zero);

    expect(cache.clearCalls, 0);
    cache.allowWriteCompletion.complete();
    expect(await lookup, bundle);
    await clear;

    expect(await cache.read('test roaster'), isNull);
    expect(service.isCached('Test Roaster'), isFalse);
  });
}

class _BlockingPersistentTtlCache extends PersistentTtlCache {
  _BlockingPersistentTtlCache(super.prefix);

  final writeStarted = Completer<void>();
  final allowWriteCompletion = Completer<void>();
  int clearCalls = 0;

  @override
  Future<void> write(String id, Map<String, dynamic> data) async {
    writeStarted.complete();
    await allowWriteCompletion.future;
    await super.write(id, data);
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    await super.clear();
  }
}
