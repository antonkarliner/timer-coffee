import 'dart:convert';

import 'package:coffee_timer/services/notification_ask_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late DateTime now;
  late bool masterEnabled;
  late OsPermissionStatus status;
  late bool requestGranted;
  late bool requestThrows;
  late bool enableThrows;
  late int requestCalls;
  late int enableCalls;
  late List<String> platformCalls;

  NotificationAskService buildService({bool isWeb = false}) =>
      NotificationAskService(
        prefs: prefs,
        now: () => now,
        isWeb: isWeb,
        isMasterEnabled: () async {
          platformCalls.add('master');
          return masterEnabled;
        },
        osStatus: () async {
          platformCalls.add('os');
          return status;
        },
        requestOsPermission: () async {
          requestCalls++;
          if (requestThrows) throw StateError('request failed');
          return requestGranted;
        },
        enableMaster: () async {
          enableCalls++;
          if (enableThrows) throw StateError('enable failed');
        },
      );

  Future<void> seedAsk({int daysAgo = 7, int brewCount = 5}) async {
    await prefs.setString(
      'notif_perm_asks',
      jsonEncode([
        {
          'surface': 'bean_save',
          'askedAtMs': now
              .subtract(Duration(days: daysAgo))
              .millisecondsSinceEpoch,
          'brewCountAtAsk': brewCount,
        },
      ]),
    );
  }

  Future<void> expectEligibility(
    NotificationAskService service,
    AskEligibilityReason reason, {
    String surface = 'bean_save',
    int brewCount = 8,
  }) async {
    final result = await service.canAsk(surface, finishedBrewCount: brewCount);
    expect(result.reason, reason);
    expect(result.allowed, reason == AskEligibilityReason.ok);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime.utc(2026, 11, 10, 12);
    masterEnabled = false;
    status = OsPermissionStatus.notDetermined;
    requestGranted = false;
    requestThrows = false;
    enableThrows = false;
    requestCalls = 0;
    enableCalls = 0;
    platformCalls = [];
  });

  group('canAsk', () {
    test('web precedes terminal and avoids platform calls', () async {
      await prefs.setString('notif_perm_terminal', 'denied');
      masterEnabled = true;
      await expectEligibility(
        buildService(isWeb: true),
        AskEligibilityReason.web,
      );
      expect(platformCalls, isEmpty);
    });

    test('terminal precedes master on and avoids platform calls', () async {
      await prefs.setString('notif_perm_terminal', 'granted');
      masterEnabled = true;
      await expectEligibility(buildService(), AskEligibilityReason.terminal);
      expect(platformCalls, isEmpty);
    });

    test('master on precedes OS granted', () async {
      masterEnabled = true;
      status = OsPermissionStatus.granted;
      await expectEligibility(buildService(), AskEligibilityReason.masterOn);
      expect(platformCalls, ['master']);
    });

    test('OS granted precedes cap of 3', () async {
      final service = buildService();
      for (var i = 0; i < 3; i++) {
        await service.recordAsk('bean_save', finishedBrewCount: i);
      }
      status = OsPermissionStatus.granted;
      await expectEligibility(service, AskEligibilityReason.osGranted);
      expect(platformCalls, ['master', 'os']);
    });

    test('OS denied', () async {
      status = OsPermissionStatus.denied;
      await expectEligibility(buildService(), AskEligibilityReason.osDenied);
    });

    test('cap of 3 precedes tooSoon', () async {
      final service = buildService();
      for (var i = 0; i < 3; i++) {
        await service.recordAsk('bean_save', finishedBrewCount: i);
      }
      await expectEligibility(service, AskEligibilityReason.capReached);
    });

    test(
      'spacing by days: 6 days is tooSoon before brew and surface checks',
      () async {
        await seedAsk(daysAgo: 6);
        await expectEligibility(
          buildService(),
          AskEligibilityReason.tooSoon,
          surface: 'finish_screen',
          brewCount: 5,
        );
      },
    );

    test('spacing by days: exactly 7 days passes that check', () async {
      await seedAsk(daysAgo: 7);
      await expectEligibility(
        buildService(),
        AskEligibilityReason.tooFewBrews,
        brewCount: 7,
      );
    });

    test('spacing by brews: 2 is tooFewBrews before surface check', () async {
      await seedAsk();
      await expectEligibility(
        buildService(),
        AskEligibilityReason.tooFewBrews,
        surface: 'finish_screen',
        brewCount: 7,
      );
    });

    test('spacing by brews: 3 is ok', () async {
      await seedAsk();
      await expectEligibility(
        buildService(),
        AskEligibilityReason.ok,
        brewCount: 8,
      );
    });

    test('finish_screen second ask refused', () async {
      final service = buildService();
      await service.recordAsk('finish_screen', finishedBrewCount: 1);
      now = now.add(const Duration(days: 7));
      await expectEligibility(
        service,
        AskEligibilityReason.finishScreenAlreadyAsked,
        surface: 'finish_screen',
        brewCount: 4,
      );
    });

    test('finish_screen refused after an ask on any other surface', () async {
      await seedAsk();
      await expectEligibility(
        buildService(),
        AskEligibilityReason.finishScreenAlreadyAsked,
        surface: 'finish_screen',
      );
    });

    test(
      'first ask on a fresh install allowed with no minimum brew count',
      () async {
        final service = buildService();
        await expectEligibility(
          service,
          AskEligibilityReason.ok,
          surface: 'finish_screen',
          brewCount: 0,
        );
        expect(await service.askCount(), 0);
        expect(prefs.containsKey('notif_perm_asks'), isFalse);
      },
    );
  });

  group('migration and corrupt JSON', () {
    test(
      'migration seeds once, refuses finish_screen, allows bean_save at 3',
      () async {
        await prefs.setBool('notif_perm_ab_shown', true);
        await prefs.setString('notif_perm_asks', '[]');
        final service = buildService();
        expect(await service.askCount(), 1);
        expect(await service.askCount(), 1);
        expect(jsonDecode(prefs.getString('notif_perm_asks')!), [
          {'surface': 'finish_screen', 'askedAtMs': 0, 'brewCountAtAsk': 0},
        ]);
        await expectEligibility(
          service,
          AskEligibilityReason.tooFewBrews,
          brewCount: 2,
        );
        await expectEligibility(
          service,
          AskEligibilityReason.finishScreenAlreadyAsked,
          surface: 'finish_screen',
          brewCount: 3,
        );
        await expectEligibility(service, AskEligibilityReason.ok, brewCount: 3);
        expect(prefs.getBool('notif_perm_ab_shown'), isTrue);
      },
    );

    test('canAsk applies migration before even the web check', () async {
      await prefs.setBool('notif_perm_ab_shown', true);
      await expectEligibility(
        buildService(isWeb: true),
        AskEligibilityReason.web,
      );
      expect(jsonDecode(prefs.getString('notif_perm_asks')!), hasLength(1));
    });

    test('recordAsk applies migration first', () async {
      await prefs.setBool('notif_perm_ab_shown', true);
      expect(
        await buildService().recordAsk('bean_save', finishedBrewCount: 3),
        2,
      );
      final entries = jsonDecode(prefs.getString('notif_perm_asks')!) as List;
      expect(entries.first['surface'], 'finish_screen');
      expect(entries.last['surface'], 'bean_save');
    });

    test('migration not applied when ledger already has entries', () async {
      await prefs.setBool('notif_perm_ab_shown', true);
      await seedAsk();
      final before = prefs.getString('notif_perm_asks');
      expect(await buildService().askCount(), 1);
      expect(prefs.getString('notif_perm_asks'), before);
    });

    test('false legacy flag leaves ledger empty and unchanged', () async {
      await prefs.setBool('notif_perm_ab_shown', false);
      expect(await buildService().askCount(), 0);
      expect(prefs.getBool('notif_perm_ab_shown'), isFalse);
      expect(prefs.containsKey('notif_perm_asks'), isFalse);
    });

    for (final raw in ['{broken', '{}', '[{"surface": 1}]']) {
      test('corrupt JSON $raw is an empty ledger', () async {
        await prefs.setString('notif_perm_asks', raw);
        final service = buildService();
        expect(await service.askCount(), 0);
        await expectEligibility(service, AskEligibilityReason.ok);
      });
    }

    test('corrupt JSON still applies migration', () async {
      await prefs.setString('notif_perm_asks', '{broken');
      await prefs.setBool('notif_perm_ab_shown', true);
      expect(await buildService().askCount(), 1);
    });
  });

  group('recordAsk', () {
    test('returns 1, 2, 3 and never exceeds 3 or replaces entries', () async {
      final service = buildService();
      for (var i = 1; i <= 3; i++) {
        expect(await service.recordAsk('surface_$i', finishedBrewCount: i), i);
      }
      final before = prefs.getString('notif_perm_asks');
      expect(await service.recordAsk('fourth', finishedBrewCount: 4), 3);
      expect(await service.askCount(), 3);
      expect(prefs.getString('notif_perm_asks'), before);
      final entries = jsonDecode(before!) as List;
      expect(entries.first, {
        'surface': 'surface_1',
        'askedAtMs': now.millisecondsSinceEpoch,
        'brewCountAtAsk': 1,
      });
      expect(prefs.containsKey('notif_perm_ab_shown'), isFalse);
      expect(prefs.containsKey('notif_perm_terminal'), isFalse);
    });
  });

  group('recordOutcome', () {
    for (final outcome in [AskOutcome.granted, AskOutcome.denied]) {
      test('${outcome.name} writes terminal', () async {
        final service = buildService();
        await service.recordOutcome(outcome);
        expect(prefs.getString('notif_perm_terminal'), outcome.name);
        await expectEligibility(service, AskEligibilityReason.terminal);
        expect(await service.askCount(), 0);
      });
    }

    test(
      'skipped writes no terminal and preserves an existing marker',
      () async {
        final service = buildService();
        await service.recordOutcome(AskOutcome.skipped);
        expect(prefs.containsKey('notif_perm_terminal'), isFalse);
        await service.recordOutcome(AskOutcome.granted);
        await service.recordOutcome(AskOutcome.skipped);
        expect(prefs.getString('notif_perm_terminal'), 'granted');
      },
    );
  });

  group('requestSystemPermissionAndEnable', () {
    for (final scenario in ['grant', 'deny', 'request throw', 'enable throw']) {
      test(
        '$scenario path records the outcome without changing the ledger',
        () async {
          await seedAsk();
          final before = prefs.getString('notif_perm_asks');
          requestGranted = scenario == 'grant' || scenario == 'enable throw';
          requestThrows = scenario == 'request throw';
          enableThrows = scenario == 'enable throw';
          final result = await buildService()
              .requestSystemPermissionAndEnable();
          expect(result, scenario == 'grant');
          expect(requestCalls, 1);
          expect(enableCalls, requestGranted ? 1 : 0);
          expect(
            prefs.getString('notif_perm_terminal'),
            scenario == 'grant'
                ? 'granted'
                : (scenario == 'deny' ? 'denied' : null),
          );
          expect(prefs.getString('notif_perm_asks'), before);
          expect(platformCalls, isEmpty);
        },
      );
    }

    test(
      'direct request neither creates a ledger nor migrates a legacy ask',
      () async {
        await prefs.setBool('notif_perm_ab_shown', true);
        requestGranted = true;
        expect(await buildService().requestSystemPermissionAndEnable(), isTrue);
        expect(prefs.containsKey('notif_perm_asks'), isFalse);
      },
    );

    test('thrown error preserves a previous terminal marker', () async {
      await prefs.setString('notif_perm_terminal', 'denied');
      requestThrows = true;
      expect(await buildService().requestSystemPermissionAndEnable(), isFalse);
      expect(prefs.getString('notif_perm_terminal'), 'denied');
      expect(prefs.containsKey('notif_perm_asks'), isFalse);
    });
  });
}
