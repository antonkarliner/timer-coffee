import 'package:flutter_test/flutter_test.dart';
// Native iOS uses a different transport. These fixtures intercept the
// method-channel launcher so opening an offer stays inside the test.
import 'package:url_launcher_platform_interface/method_channel_url_launcher.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../test/unit/widgets/giftbox_offer_analytics_test.dart' as offers;
import '../test/widgets/roaster_stock_section_test.dart' as stock;

void registerLinkTests() {
  final original = UrlLauncherPlatform.instance;
  setUpAll(() {
    UrlLauncherPlatform.instance = MethodChannelUrlLauncher();
  });
  tearDownAll(() {
    UrlLauncherPlatform.instance = original;
  });
  group(
    'Roaster stock',
    () => stock.registerStockTests(securityCasesOnly: true),
  );
  group('Gift Box consent', offers.main);
}
