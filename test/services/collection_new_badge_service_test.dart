import 'dart:convert';

import 'package:coffee_timer/services/collection_new_badge_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pairsKey = 'collection_badge_first_seen';
const _initializedKey = 'collection_badge_initialized';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'first reconcile suppresses badges and marks storage initialized',
    () async {
      final service = CollectionNewBadgeService();

      await service.reconcile({
        'collection-a': {'recipe-1', 'recipe-2'},
        'collection-b': {'recipe-3'},
      });

      expect(service.hasNew('collection-a'), isFalse);
      expect(service.hasNew('collection-b'), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(_initializedKey), isTrue);
    },
  );

  test(
    'a pair added on the second reconcile badges only its collection',
    () async {
      final service = CollectionNewBadgeService();
      await service.reconcile({
        'collection-a': {'recipe-1'},
        'collection-b': {'recipe-2'},
      });

      await service.reconcile({
        'collection-a': {'recipe-1', 'recipe-3'},
        'collection-b': {'recipe-2'},
      });

      expect(service.hasNew('collection-a'), isTrue);
      expect(service.hasNew('collection-b'), isFalse);
    },
  );

  test('markViewed clears a badge and a later new pair restores it', () async {
    final service = CollectionNewBadgeService();
    await service.reconcile({
      'collection-a': {'recipe-1'},
    });
    await service.reconcile({
      'collection-a': {'recipe-1', 'recipe-2'},
    });
    expect(service.hasNew('collection-a'), isTrue);

    await service.markViewed('collection-a');
    expect(service.hasNew('collection-a'), isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 2));
    await service.reconcile({
      'collection-a': {'recipe-1', 'recipe-2', 'recipe-3'},
    });
    expect(service.hasNew('collection-a'), isTrue);
  });

  test('a pair older than the new window does not badge', () async {
    final oldTimestamp = DateTime.now()
        .subtract(CollectionNewBadgeService.newWindow)
        .subtract(const Duration(seconds: 1))
        .millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      _initializedKey: true,
      _pairsKey: jsonEncode({
        'collection-a': {'recipe-1': oldTimestamp},
      }),
    });
    final service = CollectionNewBadgeService();

    await service.init();

    expect(service.hasNew('collection-a'), isFalse);
  });

  test('a remotely removed pair is pruned from storage', () async {
    SharedPreferences.setMockInitialValues({
      _initializedKey: true,
      _pairsKey: jsonEncode({
        'collection-a': {'recipe-1': 0, 'recipe-2': 0},
      }),
    });
    final service = CollectionNewBadgeService();
    await service.init();

    await service.reconcile({
      'collection-a': {'recipe-2'},
    });

    final prefs = await SharedPreferences.getInstance();
    final stored = jsonDecode(prefs.getString(_pairsKey)!) as Map;
    expect(stored, {
      'collection-a': {'recipe-2': 0},
    });
  });

  test('unchanged pairs do not notify or rewrite storage', () async {
    final service = CollectionNewBadgeService();
    final members = {
      'collection-a': {'recipe-1', 'recipe-2'},
    };
    await service.reconcile(members);
    final prefs = await SharedPreferences.getInstance();
    final storedBefore = prefs.getString(_pairsKey);
    var notifications = 0;
    service.addListener(() => notifications++);

    await service.reconcile(members);

    expect(notifications, 0);
    expect(prefs.getString(_pairsKey), storedBefore);
  });
}
