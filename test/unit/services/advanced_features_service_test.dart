import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';

void main() {
  late SharedPreferences prefs;
  late AdvancedFeaturesService service;

  // Sets the mock store first, then grabs an instance sharing it, so the
  // service's internal getInstance() reads/writes the same backing store
  // this test can assert against.
  Future<void> reinit(Map<String, Object> initialValues) async {
    SharedPreferences.setMockInitialValues(initialValues);
    prefs = await SharedPreferences.getInstance();
    service = AdvancedFeaturesService();
    await service.init();
  }

  group('pourLayoutEnabled', () {
    test('defaults to false when SharedPreferences is empty', () async {
      await reinit({});

      expect(service.pourLayoutEnabled, isFalse);
      expect(prefs.getBool('advanced_pour_layout_enabled'), isNull);
    });

    test('init() reads a persisted true from advanced_pour_layout_enabled',
        () async {
      await reinit({'advanced_pour_layout_enabled': true});

      expect(service.pourLayoutEnabled, isTrue);
    });

    test('init() reads an explicitly persisted false as false', () async {
      await reinit({'advanced_pour_layout_enabled': false});

      expect(service.pourLayoutEnabled, isFalse);
    });

    test('setPourLayoutEnabled(true) flips the getter, notifies once, persists',
        () async {
      await reinit({});
      var notifications = 0;
      service.addListener(() => notifications++);

      await service.setPourLayoutEnabled(true, source: 'test');

      expect(service.pourLayoutEnabled, isTrue);
      expect(notifications, 1);
      expect(prefs.getBool('advanced_pour_layout_enabled'), isTrue);
    });

    test('setting the same value again is a no-op: no extra notification',
        () async {
      await reinit({});
      var notifications = 0;
      service.addListener(() => notifications++);

      await service.setPourLayoutEnabled(false, source: 'test');

      expect(service.pourLayoutEnabled, isFalse);
      expect(notifications, 0);
      expect(prefs.getBool('advanced_pour_layout_enabled'), isNull);
    });
  });

  group('manualStepControlEnabled still works', () {
    test('defaults to false and persists through its setter', () async {
      await reinit({});

      expect(service.manualStepControlEnabled, isFalse);

      await service.setManualStepControlEnabled(true);

      expect(service.manualStepControlEnabled, isTrue);
      expect(prefs.getBool('advanced_manual_step_control_enabled'), isTrue);
      // The other toggle's key must not have been touched.
      expect(prefs.getBool('advanced_pour_layout_enabled'), isNull);
    });

    test('init() reads a persisted manual-step true', () async {
      await reinit({'advanced_manual_step_control_enabled': true});

      expect(service.manualStepControlEnabled, isTrue);
      expect(service.pourLayoutEnabled, isFalse);
    });
  });

  group('the two toggles are independent', () {
    test('flipping one leaves the other and its stored key alone', () async {
      await reinit({});
      var notifications = 0;
      service.addListener(() => notifications++);

      await service.setPourLayoutEnabled(true, source: 'test');
      expect(service.pourLayoutEnabled, isTrue);
      expect(service.manualStepControlEnabled, isFalse);

      await service.setManualStepControlEnabled(true);
      expect(service.manualStepControlEnabled, isTrue);
      expect(service.pourLayoutEnabled, isTrue);

      // Exactly one notification per genuine change, none shared.
      expect(notifications, 2);
      expect(prefs.getBool('advanced_pour_layout_enabled'), isTrue);
      expect(prefs.getBool('advanced_manual_step_control_enabled'), isTrue);
    });
  });
}
