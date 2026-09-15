import 'dart:convert';

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/roaster_profile_provider.dart';
import 'package:coffee_timer/services/roaster_directory_service.dart';
import 'package:coffee_timer/utils/persistent_ttl_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

void main() {
  const bundle = <String, String?>{
    'profile_id': 'profile-1',
    'slug': 'new-roaster',
    'roaster_logo_url': 'https://example.test/original.png',
    'roaster_logo_mirror_url': 'https://example.test/mirror.webp',
    'dominant_color_hex': '#123456',
  };

  Future<void> expireMiss(String prefix, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$prefix$key',
      jsonEncode({
        'ts': DateTime.now()
            .subtract(const Duration(minutes: 6))
            .millisecondsSinceEpoch,
        'data': {'found': false},
      }),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('logo cache does not retain a directory miss', () async {
    var calls = 0;
    const prefix = 'database_provider_roaster_';
    final directory = RoasterDirectoryService.forTesting(
      bundleLoader: (_) async => ++calls == 1 ? null : bundle,
      persistentCache: PersistentTtlCache(prefix),
    );
    final AppDatabase database = openTestDatabase();
    addTearDown(database.close);
    final provider = DatabaseProvider.withRoasterDirectoryService(
      database,
      directory,
    );

    expect(await provider.fetchCachedRoasterLogoUrls('New Roaster'), {
      'original': null,
      'mirror': null,
      'dominant_color_hex': null,
    });
    await expireMiss(prefix, 'new roaster');

    expect(await provider.fetchCachedRoasterLogoUrls('New Roaster'), {
      'original': bundle['roaster_logo_url'],
      'mirror': bundle['roaster_logo_mirror_url'],
      'dominant_color_hex': bundle['dominant_color_hex'],
    });
    expect(await provider.fetchCachedRoasterLogoUrls('New Roaster'), isNotNull);
    expect(calls, 2);
  });

  test(
    'logo cache retains a profile hit even when its logo fields are null',
    () async {
      var calls = 0;
      final directory = RoasterDirectoryService.forTesting(
        bundleLoader: (_) async {
          calls++;
          return const {
            'profile_id': 'profile-without-logo',
            'slug': 'profile-without-logo',
            'roaster_logo_url': null,
            'roaster_logo_mirror_url': null,
            'dominant_color_hex': null,
          };
        },
        persistentCache: PersistentTtlCache('database_provider_no_logo_'),
      );
      final AppDatabase database = openTestDatabase();
      addTearDown(database.close);
      final provider = DatabaseProvider.withRoasterDirectoryService(
        database,
        directory,
      );

      await provider.fetchCachedRoasterLogoUrls('Profile Without Logo');
      await provider.fetchCachedRoasterLogoUrls('Profile Without Logo');

      expect(calls, 1);
    },
  );

  test('slug and profile ID caches do not retain a directory miss', () async {
    var calls = 0;
    const prefix = 'profile_provider_roaster_';
    final directory = RoasterDirectoryService.forTesting(
      bundleLoader: (_) async => ++calls == 1 ? null : bundle,
      persistentCache: PersistentTtlCache(prefix),
    );
    final provider = RoasterProfileProvider.withRoasterDirectoryService(
      directory,
    );

    expect(await provider.fetchRoasterProfileIdByName('New Roaster'), isNull);
    await expireMiss(prefix, 'new roaster');

    expect(
      await provider.fetchRoasterSlugByName('New Roaster'),
      bundle['slug'],
    );
    expect(
      await provider.fetchRoasterProfileIdByName('New Roaster'),
      bundle['profile_id'],
    );
    expect(calls, 2);
  });

  test('explicit clear invalidates logo and profile lookup caches', () async {
    var calls = 0;
    const refreshedBundle = <String, String?>{
      'profile_id': 'profile-2',
      'slug': 'refreshed-roaster',
      'roaster_logo_url': 'https://example.test/refreshed.png',
      'roaster_logo_mirror_url': null,
      'dominant_color_hex': '#654321',
    };
    final directory = RoasterDirectoryService.forTesting(
      bundleLoader: (_) async => ++calls == 1 ? bundle : refreshedBundle,
      persistentCache: PersistentTtlCache('provider_explicit_clear_'),
    );
    final AppDatabase database = openTestDatabase();
    addTearDown(database.close);
    final databaseProvider = DatabaseProvider.withRoasterDirectoryService(
      database,
      directory,
    );
    final profileProvider = RoasterProfileProvider.withRoasterDirectoryService(
      directory,
    );

    expect(
      await databaseProvider.fetchCachedRoasterLogoUrls('New Roaster'),
      containsPair('original', bundle['roaster_logo_url']),
    );
    expect(
      await profileProvider.fetchRoasterSlugByName('New Roaster'),
      bundle['slug'],
    );

    await databaseProvider.clearRoasterDirectoryCache();

    expect(
      await databaseProvider.fetchCachedRoasterLogoUrls('New Roaster'),
      containsPair('original', refreshedBundle['roaster_logo_url']),
    );
    expect(
      await profileProvider.fetchRoasterSlugByName('New Roaster'),
      refreshedBundle['slug'],
    );
    expect(calls, 2);
  });
}
