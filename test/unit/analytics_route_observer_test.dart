import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AnalyticsRouteObserver observer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
    observer = AnalyticsRouteObserver();
  });

  tearDown(AnalyticsService.resetForTesting);

  TabPageRoute tabRoute(PageInfo page, int index) {
    final config = AutoRoute(page: page, path: 'tab-$index');
    return TabPageRoute(
      routeInfo: RouteMatch(
        config: config,
        segments: const [],
        stringMatch: config.path,
        key: ValueKey(page.name),
      ),
      index: index,
    );
  }

  test('didInitTabRoute tracks the initially shown tab', () {
    observer.didInitTabRoute(tabRoute(BrewingMethodsRoute.page, 0), null);

    expect(
      AnalyticsService.instance.bufferedEventsForTesting.single,
      containsPair('event_name', 'screen_viewed'),
    );
    expect(
      AnalyticsService.instance.bufferedEventsForTesting.single['properties'],
      {'screen_name': 'BrewingMethodsRoute'},
    );
  });

  test('didChangeTabRoute tracks the newly selected tab', () {
    observer.didChangeTabRoute(
      tabRoute(CoffeeBeansRoute.page, 1),
      tabRoute(BrewingMethodsRoute.page, 0),
    );

    expect(
      AnalyticsService.instance.bufferedEventsForTesting.single,
      containsPair('event_name', 'screen_viewed'),
    );
    expect(
      AnalyticsService.instance.bufferedEventsForTesting.single['properties'],
      {'screen_name': 'CoffeeBeansRoute'},
    );
  });
}
