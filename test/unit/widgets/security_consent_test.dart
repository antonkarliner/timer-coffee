import 'dart:convert';

import 'package:coffee_timer/controllers/new_beans_image_controller.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/new_beans_screen.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/services/fcm_service.dart';
import 'package:coffee_timer/services/photo_library_service.dart';
import 'package:coffee_timer/utils/notification_tap_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'brew_flow_async_context_test.mocks.dart';

class _MessagingPlatform extends FirebaseMessagingPlatform {
  RemoteMessage? initialTap;

  @override
  FirebaseMessagingPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseMessagingPlatform setInitialValues({bool? isAutoInitEnabled}) => this;

  @override
  void registerBackgroundMessageHandler(BackgroundMessageHandler handler) {}

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    required bool alert,
    required bool badge,
    required bool sound,
  }) async {}

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    final message = initialTap;
    initialTap = null;
    return message;
  }
}

class _ScanRecorder extends NewBeansImageController {
  _ScanRecorder() : super(supabaseClient: Supabase.instance.client);

  final startedFor = <String?>[];

  @override
  Future<void> start({
    required BuildContext context,
    required String locale,
    required void Function(bool) onLoading,
    required void Function(Map<String, dynamic>) onData,
    required void Function(String) onError,
    required Future<ImageSource?> Function() onChooseSource,
    required Future<void> Function(
      List<XFile> images,
      ImageSource source,
      Future<void> Function(List<XFile>, bool) onConfirm,
      Future<void> Function() onBackToSelection,
      Future<XFile?> Function()? onAddPhoto,
    )
    onShowPreview,
    String? userId,
    bool isFirstTime = false,
    void Function(BeanScanStage stage)? onStage,
    required void Function(PhotoLibrarySaveResult result) onPhotoSaveResult,
  }) async {
    startedFor.add(userId);
  }
}

Future<void> _switchTo(String id) async {
  final claims = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'sub': id,
            'exp':
                DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch ~/
                1000,
          }),
        ),
      )
      .replaceAll('=', '');
  await Supabase.instance.client.auth.recoverSession(
    jsonEncode({
      'access_token': 'test.$claims.signature',
      'refresh_token': 'offline-fixture',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': id,
        'aud': 'authenticated',
        'app_metadata': <String, dynamic>{},
        'created_at': '2026-01-01T00:00:00Z',
      },
    }),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification navigation consent (37)', () {
    test(
      'background receipt cannot navigate and a validated tap is consumed once',
      () async {
        SharedPreferences.setMockInitialValues({});
        setupFirebaseCoreMocks();
        final originalPlatform = FirebaseMessagingPlatform.instance;
        final platform = _MessagingPlatform();
        FirebaseMessagingPlatform.instance = platform;
        addTearDown(() {
          FirebaseMessagingPlatform.onBackgroundMessage = null;
          FirebaseMessagingPlatform.instance = originalPlatform;
        });
        await Firebase.initializeApp();

        final service = FcmService();
        await service.initialize();
        final launched = <Uri>[];
        void openExternal(String link) {
          final uri = validatedExternalNotificationUri(link);
          if (uri != null) launched.add(uri);
        }

        final firstRouter = consumeNotificationTapLinks(
          service.onNotificationTapped,
          openExternal,
        );
        addTearDown(firstRouter.cancel);
        const link = 'https://destination.example.test/example';
        const background = RemoteMessage(
          messageId: 'background',
          data: {'external_url': link},
        );
        final receipt = FirebaseMessagingPlatform.onBackgroundMessage;
        expect(receipt, isNotNull);
        await receipt!(background);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('pending_external_url'), isFalse);

        // An upgrade may have a marker written by a legacy background handler.
        await prefs.setString('pending_external_url', link);
        await discardLegacyNotificationLaunch(prefs);
        await service.checkForInitialMessage();
        await Future<void>.delayed(Duration.zero);
        expect(prefs.containsKey('pending_external_url'), isFalse);
        expect(launched, isEmpty);

        for (final blocked in [
          'file:///private/fixture.txt',
          'https:///missing-host',
          'https://owner@destination.example.test/',
        ]) {
          FirebaseMessagingPlatform.onMessageOpenedApp.add(
            RemoteMessage(data: {'external_url': blocked}),
          );
          await Future<void>.delayed(Duration.zero);
        }
        expect(launched, isEmpty);

        FirebaseMessagingPlatform.onMessageOpenedApp.add(background);
        await Future<void>.delayed(Duration.zero);
        expect(launched, [Uri.parse(link)]);

        await firstRouter.cancel();
        final rebuiltRouter = consumeNotificationTapLinks(
          service.onNotificationTapped,
          openExternal,
        );
        addTearDown(rebuiltRouter.cancel);
        await Future<void>.delayed(Duration.zero);
        expect(launched, [Uri.parse(link)]);

        const coldLink = 'https://destination.example.test/notification';
        platform.initialTap = const RemoteMessage(
          messageId: 'cold-tap',
          data: {'external_url': coldLink},
        );
        await service.checkForInitialMessage();
        await service.checkForInitialMessage();
        await Future<void>.delayed(Duration.zero);
        expect(launched, [Uri.parse(link), Uri.parse(coldLink)]);
      },
    );
  });

  group('Bean label processing consent (50)', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({
        'hasShownPopup': true,
        'hasCompletedFirstImageRecognition': true,
      });
      await Supabase.initialize(
        url: 'https://example.test',
        anonKey: 'test-anon-key',
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient(
          (_) async => throw StateError('Unexpected call'),
        ),
      );
    });

    tearDownAll(() => Supabase.instance.dispose());

    testWidgets(
      'the next account must see and accept the disclosure before scanning',
      (tester) async {
        const alice = 'scan-alice';
        const bob = 'scan-bob';
        const charlie = 'scan-charlie';
        await _switchTo(alice);
        final controller = _ScanRecorder();
        final beans = MockCoffeeBeansProvider();
        final stats = MockUserStatProvider();
        when(beans.fetchAllDistinctGrindSizes()).thenAnswer((_) async => []);
        when(stats.fetchAllDistinctGrindSizes()).thenAnswer((_) async => []);
        final loc = lookupAppLocalizations(const Locale('en'));

        Future<void> mountScreen(String owner) async {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<CoffeeBeansProvider>.value(value: beans),
                ChangeNotifierProvider<UserStatProvider>.value(value: stats),
                ChangeNotifierProvider<DateTimeFormatService>(
                  create: (_) => DateTimeFormatService(),
                ),
              ],
              child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('en'),
                home: NewBeansScreen(
                  key: ValueKey(owner),
                  imageController: controller,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        Future<void> tapScan() async {
          await tester.tap(find.text(loc.aiScanLabel));
          await tester.pumpAndSettle();
        }

        Future<void> acceptNotice() async {
          await tester.tap(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text(loc.ok),
            ),
          );
          await tester.pumpAndSettle();
        }

        await mountScreen(alice);
        await tapScan();
        expect(find.text(loc.firstTimePopupMessage), findsOneWidget);
        expect(controller.startedFor, isEmpty);
        await acceptNotice();
        expect(controller.startedFor, [alice]);
        await tapScan();
        expect(find.text(loc.firstTimePopupMessage), findsNothing);
        expect(controller.startedFor, [alice, alice]);

        await _switchTo(bob);
        await mountScreen(bob);
        await tapScan();
        expect(find.text(loc.firstTimePopupMessage), findsOneWidget);
        expect(controller.startedFor, [alice, alice]);

        // A response from a disclosure that was already open cannot grant
        // consent after the session changes, even before the router remounts.
        await _switchTo(charlie);
        await acceptNotice();
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('bean_label_notice_v1_$bob'), isNull);
        expect(prefs.getBool('bean_label_notice_v1_$charlie'), isNull);
        expect(controller.startedFor, [alice, alice]);

        await _switchTo(bob);
        await mountScreen(bob);
        await tapScan();
        expect(find.text(loc.firstTimePopupMessage), findsOneWidget);
        await acceptNotice();
        expect(controller.startedFor, [alice, alice, bob]);
        expect(prefs.getBool('bean_label_notice_v1_$bob'), isTrue);
      },
    );
  });
}
