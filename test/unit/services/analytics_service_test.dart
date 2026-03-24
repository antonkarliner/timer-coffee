import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/services/analytics_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  group('initialization', () {
    test('creates singleton instance', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = await AnalyticsService.initialize(prefs);
      expect(service, isNotNull);
      expect(AnalyticsService.instance, same(service));
    });

    test('generates and persists installId', () async {
      final prefs = await SharedPreferences.getInstance();
      await AnalyticsService.initialize(prefs);

      final installId = AnalyticsService.instance.installId;
      expect(installId, isNotEmpty);

      // Verify it persists
      expect(prefs.getString('analytics_install_id'), installId);
    });

    test('installId persists across instances', () async {
      final prefs = await SharedPreferences.getInstance();
      await AnalyticsService.initialize(prefs);
      final firstInstallId = AnalyticsService.instance.installId;

      // Reset and reinitialize
      AnalyticsService.resetForTesting();
      await AnalyticsService.initialize(prefs);
      final secondInstallId = AnalyticsService.instance.installId;

      expect(secondInstallId, equals(firstInstallId));
    });

    test('all categories enabled by default', () async {
      final prefs = await SharedPreferences.getInstance();
      await AnalyticsService.initialize(prefs);

      expect(AnalyticsService.instance.brewsEnabled, isTrue);
      expect(AnalyticsService.instance.beansEnabled, isTrue);
      expect(AnalyticsService.instance.generalEnabled, isTrue);
    });
  });

  group('track()', () {
    late AnalyticsService service;

    setUp(() async {
      final prefs = await SharedPreferences.getInstance();
      service = await AnalyticsService.initialize(prefs);
    });

    test('adds event to buffer', () {
      service.track('brew_started', properties: {'recipe_id': 'test-123'});
      expect(service.bufferLength, 1);
    });

    test('adds multiple events', () {
      service.track('brew_started');
      service.track('brew_completed');
      expect(service.bufferLength, 2);
    });

    test('ignores unknown event names', () {
      service.track('unknown_event_that_does_not_exist');
      expect(service.bufferLength, 0);
    });

    test('is no-op when category disabled (brews)', () async {
      await service.setBrewsEnabled(false);
      service.track('brew_started');
      service.track('brew_completed');
      service.track('brew_abandoned');
      expect(service.bufferLength, 0);
    });

    test('is no-op when category disabled (beans)', () async {
      await service.setBeansEnabled(false);
      service.track('beans_added');
      service.track('beans_scan_used');
      service.track('beans_attached');
      expect(service.bufferLength, 0);
    });

    test('is no-op when category disabled (general)', () async {
      await service.setGeneralEnabled(false);
      service.track('app_opened');
      service.track('screen_viewed');
      service.track('donation_screen_viewed');
      expect(service.bufferLength, 0);
    });

    test('respects categories independently', () async {
      await service.setBrewsEnabled(false);
      // Beans and general should still work
      service.track('beans_added');
      service.track('app_opened');
      expect(service.bufferLength, 2);
    });

    test('is no-op when global kill switch is on', () {
      service.setGlobalKillSwitch(true);
      service.track('brew_started');
      service.track('beans_added');
      service.track('app_opened');
      expect(service.bufferLength, 0);
    });

    test('resumes when global kill switch is turned off', () {
      service.setGlobalKillSwitch(true);
      service.track('brew_started');
      expect(service.bufferLength, 0);

      service.setGlobalKillSwitch(false);
      service.track('brew_started');
      expect(service.bufferLength, 1);
    });

    test('buffer caps at 500 events', () {
      for (int i = 0; i < 510; i++) {
        service.track('app_opened');
      }
      expect(service.bufferLength, 500);
    });
  });

  group('category toggles', () {
    test('setBrewsEnabled persists to SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = await AnalyticsService.initialize(prefs);

      await service.setBrewsEnabled(false);
      expect(prefs.getBool('analytics_brews_enabled'), isFalse);

      await service.setBrewsEnabled(true);
      expect(prefs.getBool('analytics_brews_enabled'), isTrue);
    });

    test('setBeansEnabled persists to SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = await AnalyticsService.initialize(prefs);

      await service.setBeansEnabled(false);
      expect(prefs.getBool('analytics_beans_enabled'), isFalse);
    });

    test('setGeneralEnabled persists to SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = await AnalyticsService.initialize(prefs);

      await service.setGeneralEnabled(false);
      expect(prefs.getBool('analytics_general_enabled'), isFalse);
    });

    test('notifies listeners on category change', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = await AnalyticsService.initialize(prefs);

      bool notified = false;
      service.addListener(() => notified = true);

      await service.setBrewsEnabled(false);
      expect(notified, isTrue);
    });

    test('persisted preferences survive reinitialization', () async {
      final prefs = await SharedPreferences.getInstance();
      var service = await AnalyticsService.initialize(prefs);
      await service.setBrewsEnabled(false);
      await service.setBeansEnabled(false);

      AnalyticsService.resetForTesting();
      service = await AnalyticsService.initialize(prefs);

      expect(service.brewsEnabled, isFalse);
      expect(service.beansEnabled, isFalse);
      expect(service.generalEnabled, isTrue); // default
    });
  });
}
