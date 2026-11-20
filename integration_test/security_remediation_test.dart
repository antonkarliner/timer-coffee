import 'dart:convert';
import 'dart:typed_data';

import 'package:coffee_timer/services/clients/beans_label_parser_client.dart';
import 'package:coffee_timer/services/roaster_logo_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:coffee_timer/services/local_notification_scheduler_service.dart';
import 'package:coffee_timer/utils/recipe_schedule_limits.dart';

import '../test/services/account_identity_service_test.dart' as account;
import '../test/unit/services/roaster_contribution_service_test.dart'
    as contributions;

import '../test/unit/providers/push_registration_privacy_test.dart' as push;
import '../test/unit/services/account_data_isolation_test.dart' as isolation;
import '../test/unit/services/analytics_service_test.dart' as analytics;
import '../test/unit/services/recipe_import_sharing_async_context_test.dart'
    as recipes;

import '../test/unit/services/bean_photo_service_test.dart' as photos;
import '../test/unit/services/recipe_publication_test.dart' as publication;
import '../test/unit/services/profile_picture_removal_test.dart' as profile;
import '../test/services/connection_analytics_service_test.dart' as connection;
import '../test/unit/providers/recommendation_provider_test.dart'
    as recommendations;

import '../test/unit/widgets/account_identity_test.dart' as identity;

import '../test/unit/widgets/account_review_boundaries_test.dart' as reviews;
import '../test/unit/widgets/security_consent_test.dart' as consent;
import 'link_fixtures.dart' as links;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group(
    'Review ownership, moderation and banner (15, 22, 34, 46, 49)',
    reviews.main,
  );
  group(
    'Notification taps and photo processing consent (37, 50)',
    consent.main,
  );
  group('Stock and offer links (27, 40, 42)', links.registerLinkTests);

  group('Account display name (30, 41, 43)', identity.main);
  group('Cover photo links (10, 14)', photos.main);
  group('Profile photo removal (48)', profile.main);
  group(
    'Recommendation consent and session changes (19, 24, 35)',
    recommendations.main,
  );
  group('Connection telemetry (33, 47)', connection.main);
  group('Publication and pending withdrawal (2, 7, 21)', publication.main);
  group('Installation push choices (18, 39, 52, 53)', push.main);
  group('Account partition, sync, export (1, 13, 26)', isolation.main);
  group(
    'Analytics privacy controls (3, 4, 5, 9, 11, 12, 45, 51)',
    analytics.main,
  );
  group(
    'Recipe links and publication (2, 7, 8, 17, 20, 21, 23, 31)',
    recipes.main,
  );
  group('Account identity and address privacy (36)', account.main);
  group('Contribution acknowledgements (46, 49)', contributions.main);

  test('28: author and import schedule boundaries agree', () {
    validateRecipeSchedule([0, 30, 60]);
    expect(
      () => validateRecipeSchedule([maxRecipeDurationSeconds, 1]),
      throwsFormatException,
    );
    expect(
      () => validateImportedRecipeSchedule({
        'user_steps': [
          {'time': '604801', 'locale': 'en'},
        ],
      }),
      throwsFormatException,
    );
  });

  test(
    '38: opting out removes engagement entries and preserves other IDs',
    () async {
      LocalNotificationSchedulerService.testMode = true;
      LocalNotificationSchedulerService.resetTestState();
      addTearDown(() {
        LocalNotificationSchedulerService.testMode = false;
        LocalNotificationSchedulerService.resetTestState();
      });
      LocalNotificationSchedulerService.testScheduled.addAll([
        (id: 1601, payload: 'review'),
        (id: 1901, payload: 'brew later'),
        (id: 99, payload: 'timer'),
      ]);
      await LocalNotificationSchedulerService.instance
          .cancelEngagementReminders();
      expect(
        LocalNotificationSchedulerService.testScheduled.map((item) => item.id),
        [99],
      );
    },
  );

  testWidgets('Notification and directory logo decoding (6, 16)', (
    tester,
  ) async {
    final input = img.Image(width: 640, height: 320);
    final png = await RoasterLogoClient.normalizedRaster(img.encodePng(input));
    final decoded = img.decodePng(png)!;
    expect((decoded.width, decoded.height), (512, 256));
    final overBudget = http.StreamedResponse(
      const Stream.empty(),
      200,
      contentLength: RoasterLogoClient.byteLimit + 1,
    );
    await expectLater(
      RoasterLogoClient.readBounded(overBudget),
      throwsFormatException,
    );
  });

  testWidgets('Label recognition strips camera metadata (29)', (tester) async {
    final input = img.Image(width: 32, height: 16);
    input.exif.imageIfd[0x010f] = img.IfdValueAscii('Test Camera');
    input.exif.gpsIfd[1] = img.IfdValueAscii('N');
    final original = img.encodeJpg(input);
    expect(img.decodeJpg(original)!.hasExif, isTrue);
    final result = base64Decode(
      prepareLabelPhotos([base64Encode(original)]).single,
    );
    final restored = img.decodeJpg(result)!;
    expect((restored.width, restored.height), (32, 16));
    expect(restored.exif.imageIfd[0x010f], isNull);
    expect(restored.exif.gpsIfd[1], isNull);
    expect(
      () => prepareLabelPhotos([base64Encode(Uint8List(0))]),
      throwsA(anything),
    );
  });
}
