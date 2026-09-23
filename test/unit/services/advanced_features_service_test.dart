import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';

void main() {
  late SharedPreferences prefs;
  late AdvancedFeaturesService service;

  // Sets the mock store first, then grabs an instance sharing it, so the
  // service's internal getInstance() reads/writes the same backing store
  // this test can assert against.
  Future<void> reinit(
    Map<String, Object> initialValues, {
    bool isWeb = false,
  }) async {
    SharedPreferences.setMockInitialValues(initialValues);
    prefs = await SharedPreferences.getInstance();
    service = AdvancedFeaturesService(isWeb: isWeb);
    await service.init();
  }

  group('armForInstallId', () {
    const cases = {
      '550e8400-e29b-41d4-a716-446655440000': 'pour',
      '550e8400-e29b-41d4-a716-44665544007f': 'pour',
      '550e8400-e29b-41d4-a716-446655440080': 'classic',
      '550e8400-e29b-41d4-a716-4466554400ff': 'classic',
      '550e8400-e29b-41d4-a716-4466554400zz': 'classic',
      '': 'classic',
    };

    for (final MapEntry(key: installId, value: expected) in cases.entries) {
      test(
        'maps an id ending in ${installId.isEmpty ? 'empty' : installId.substring(installId.length - 2)} to $expected',
        () {
          expect(AdvancedFeaturesService.armForInstallId(installId), expected);
        },
      );
    }

    test('pourPercent 0 always returns classic for valid ids', () {
      expect(
        AdvancedFeaturesService.armForInstallId(
          '550e8400-e29b-41d4-a716-446655440000',
          pourPercent: 0,
        ),
        'classic',
      );
      expect(
        AdvancedFeaturesService.armForInstallId(
          '550e8400-e29b-41d4-a716-4466554400ff',
          pourPercent: 0,
        ),
        'classic',
      );
    });

    test('pourPercent 100 always returns pour for valid ids', () {
      expect(
        AdvancedFeaturesService.armForInstallId(
          '550e8400-e29b-41d4-a716-446655440000',
          pourPercent: 100,
        ),
        'pour',
      );
      expect(
        AdvancedFeaturesService.armForInstallId(
          '550e8400-e29b-41d4-a716-4466554400ff',
          pourPercent: 100,
        ),
        'pour',
      );
    });
  });

  group('layout arm assignment', () {
    test('firstBrewDone prevents assignment', () async {
      await reinit({});

      await service.assignLayoutArmIfEligible(
        firstBrewDone: true,
        installId: '550e8400-e29b-41d4-a716-446655440000',
        experimentActive: true,
      );

      expect(service.layoutArm, isNull);
      expect(prefs.getString(AdvancedFeaturesService.kLayoutArmKey), isNull);
    });

    test('an existing assignment is never changed', () async {
      await reinit({AdvancedFeaturesService.kLayoutArmKey: 'pour'});

      await service.assignLayoutArmIfEligible(
        firstBrewDone: false,
        installId: '550e8400-e29b-41d4-a716-446655440080',
        experimentActive: true,
      );

      expect(service.layoutArm, 'pour');
      expect(prefs.getString(AdvancedFeaturesService.kLayoutArmKey), 'pour');
    });

    test('an inactive experiment prevents assignment', () async {
      await reinit({});

      await service.assignLayoutArmIfEligible(
        firstBrewDone: false,
        installId: '550e8400-e29b-41d4-a716-446655440000',
        experimentActive: false,
      );

      expect(service.layoutArm, isNull);
      expect(prefs.getString(AdvancedFeaturesService.kLayoutArmKey), isNull);
    });

    test('web prevents assignment', () async {
      await reinit({}, isWeb: true);

      await service.assignLayoutArmIfEligible(
        firstBrewDone: false,
        installId: '550e8400-e29b-41d4-a716-446655440000',
        experimentActive: true,
      );

      expect(service.layoutArm, isNull);
      expect(prefs.getString(AdvancedFeaturesService.kLayoutArmKey), isNull);
    });

    test(
      'pour arm updates memory synchronously and persists both prefs',
      () async {
        await reinit({});
        var notifications = 0;
        service.addListener(() => notifications++);

        final assignment = service.assignLayoutArmIfEligible(
          firstBrewDone: false,
          installId: '550e8400-e29b-41d4-a716-44665544007f',
          experimentActive: true,
        );

        expect(service.layoutArm, 'pour');
        expect(service.pourLayoutEnabled, isTrue);
        expect(notifications, 1);

        await assignment;

        expect(prefs.getString(AdvancedFeaturesService.kLayoutArmKey), 'pour');
        expect(prefs.getBool(AdvancedFeaturesService.kPourLayoutKey), isTrue);
      },
    );

    test('classic arm leaves pour disabled and persists both prefs', () async {
      await reinit({});

      await service.assignLayoutArmIfEligible(
        firstBrewDone: false,
        installId: '550e8400-e29b-41d4-a716-446655440080',
        experimentActive: true,
      );

      expect(service.layoutArm, 'classic');
      expect(service.pourLayoutEnabled, isFalse);
      expect(prefs.getString(AdvancedFeaturesService.kLayoutArmKey), 'classic');
      expect(prefs.getBool(AdvancedFeaturesService.kPourLayoutKey), isFalse);
    });

    test('init reloads a valid persisted arm', () async {
      await reinit({AdvancedFeaturesService.kLayoutArmKey: 'classic'});

      expect(service.layoutArm, 'classic');
    });

    test('init treats a garbage persisted arm as unassigned', () async {
      await reinit({AdvancedFeaturesService.kLayoutArmKey: 'garbage'});

      expect(service.layoutArm, isNull);
    });
  });

  group('pourLayoutEnabled', () {
    test('defaults to false when SharedPreferences is empty', () async {
      await reinit({});

      expect(service.pourLayoutEnabled, isFalse);
      expect(prefs.getBool('advanced_pour_layout_enabled'), isNull);
    });

    test(
      'init() reads a persisted true from advanced_pour_layout_enabled',
      () async {
        await reinit({'advanced_pour_layout_enabled': true});

        expect(service.pourLayoutEnabled, isTrue);
      },
    );

    test('init() reads an explicitly persisted false as false', () async {
      await reinit({'advanced_pour_layout_enabled': false});

      expect(service.pourLayoutEnabled, isFalse);
    });

    test(
      'setPourLayoutEnabled(true) flips the getter, notifies once, persists',
      () async {
        await reinit({});
        var notifications = 0;
        service.addListener(() => notifications++);

        await service.setPourLayoutEnabled(true, source: 'test');

        expect(service.pourLayoutEnabled, isTrue);
        expect(notifications, 1);
        expect(prefs.getBool('advanced_pour_layout_enabled'), isTrue);
      },
    );

    test(
      'setting the same value again is a no-op: no extra notification',
      () async {
        await reinit({});
        var notifications = 0;
        service.addListener(() => notifications++);

        await service.setPourLayoutEnabled(false, source: 'test');

        expect(service.pourLayoutEnabled, isFalse);
        expect(notifications, 0);
        expect(prefs.getBool('advanced_pour_layout_enabled'), isNull);
      },
    );
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
