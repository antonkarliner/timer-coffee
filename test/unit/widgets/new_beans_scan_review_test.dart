import 'package:coffee_timer/controllers/new_beans_image_controller.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/new_beans_screen.dart';
import 'package:coffee_timer/services/photo_library_service.dart';
import 'dart:async';

import 'package:coffee_timer/widgets/containers/sticky_action_bar.dart';
import 'package:coffee_timer/widgets/new_beans/dates_card.dart';
import 'package:coffee_timer/widgets/new_beans/scan_review_section.dart';
import 'package:coffee_timer/widgets/new_beans/image_flow/collected_data_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'brew_flow_async_context_test.mocks.dart' as brew_mocks;

/// Focused coverage for the smoother AI scan review: after a successful
/// scan the populated form itself is the review surface — no sequential
/// success dialogs (CollectedDataDialog + automatic cover prompt) — with a
/// compact inline review section instead.
///
/// No real scan network calls are made: the screen is driven through a
/// scripted [NewBeansImageController], the same harness used by
/// widget_async_context_batch_test.dart.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      anonKey: 'test-anon-key',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'hasShownPopup': true,
      'hasCompletedFirstImageRecognition': true,
    });
  });

  const scanPhotoPath = 'assets/icons/app_icon_1024.png';

  /// The review section must stay inside the viewport horizontally: an
  /// overflow in one of its rows (heading, roast-date attention, cover
  /// chooser) would push its Texts past the card's right edge.
  void assertReviewSectionLaysOutWithinBounds(WidgetTester tester) {
    final sectionFinder = find.bySemanticsIdentifier('scanReviewSection');
    final sectionRect = tester.getRect(sectionFinder);
    expect(sectionRect.left, greaterThanOrEqualTo(0));
    expect(
      sectionRect.right,
      lessThanOrEqualTo(
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      ),
    );

    for (final textElement
        in find
            .descendant(of: sectionFinder, matching: find.byType(Text))
            .evaluate()) {
      final renderObject = textElement.renderObject;
      if (renderObject is! RenderBox) continue;
      final topLeft = renderObject.localToGlobal(Offset.zero);
      final right = topLeft.dx + renderObject.size.width;
      final data = textElement.widget is Text
          ? (textElement.widget as Text).data
          : null;
      expect(
        topLeft.dx,
        greaterThanOrEqualTo(sectionRect.left - 1),
        reason: 'Text "$data" overflows left',
      );
      expect(
        right,
        lessThanOrEqualTo(sectionRect.right + 1),
        reason: 'Text "$data" overflows right',
      );
    }
  }

  Future<AppLocalizations> pumpScreen(
    WidgetTester tester, {
    _ScriptedImageController? controller,
    CoffeeBeansModel? editBean,
  }) async {
    final beansProvider = brew_mocks.MockCoffeeBeansProvider();
    when(
      beansProvider.fetchAllDistinctGrindSizes(),
    ).thenAnswer((_) async => <String>[]);
    if (editBean != null) {
      when(
        beansProvider.fetchCoffeeBeansByUuid(editBean.beansUuid),
      ).thenAnswer((_) async => editBean);
    }
    final userStatProvider = brew_mocks.MockUserStatProvider();
    when(
      userStatProvider.fetchAllDistinctGrindSizes(),
    ).thenAnswer((_) async => <String>[]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: beansProvider,
          ),
          ChangeNotifierProvider<UserStatProvider>.value(
            value: userStatProvider,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: NewBeansScreen(
              uuid: editBean?.beansUuid,
              imageController: controller ?? _ScriptedImageController(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return AppLocalizations.of(tester.element(find.byType(NewBeansScreen)))!;
  }

  /// Drives the scan flow: taps AI Scan, optionally walks the photo review
  /// sheet (retaining the reviewed images for the cover chooser), then
  /// delivers the parse result.
  Future<void> deliverScanData(
    WidgetTester tester, {
    required _ScriptedImageController controller,
    required AppLocalizations loc,
    required Map<String, dynamic> payload,
    List<XFile> reviewedImages = const <XFile>[],
  }) async {
    await tester.tap(find.text(loc.aiScanLabel));
    await tester.pump();

    if (reviewedImages.isNotEmpty) {
      final preview = controller.showPreview(
        reviewedImages,
        ImageSource.camera,
        (_, _) async {},
        () async {},
        null,
      );
      await tester.pumpAndSettle();

      final analyzeLabel = reviewedImages.length > 1
          ? loc.aiScanAnalyzeTwoPhotos
          : loc.aiScanAnalyzePhoto;
      await tester.ensureVisible(find.text(analyzeLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(analyzeLabel));
      await tester.pumpAndSettle();
      await preview;
    }

    controller.data(payload);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'scan success fills the form for inline review without success dialogs',
    (tester) async {
      final controller = _ScriptedImageController();
      final loc = await pumpScreen(tester, controller: controller);

      await deliverScanData(
        tester,
        controller: controller,
        loc: loc,
        payload: <String, dynamic>{
          'roaster': 'Roaster A',
          'name': 'Beans A',
          'origin': 'Origin A',
          'notes': 'Unknown',
          'variety': 'Unknown',
          'roastDate': '2026-03-01T00:00:00.000',
        },
      );

      // The form is the review surface: scanned values landed in the fields.
      expect(find.text('Roaster A'), findsOneWidget);
      expect(find.text('Beans A'), findsOneWidget);
      expect(find.text('Origin A'), findsOneWidget);

      // Unknown optional values stay blank — never literal N/A.
      expect(find.text('Unknown'), findsNothing);
      expect(find.text('N/A'), findsNothing);

      // No pending decisions: no empty card or sequential success dialogs.
      expect(find.bySemanticsIdentifier('scanReviewSection'), findsNothing);
      expect(find.byType(CollectedDataDialog), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);

      // No scan photos were kept, so no cover chooser is offered.
      expect(find.text(loc.beanCoverPhotoSavePromptBody), findsNothing);

      controller.complete();
      await tester.pump();
    },
  );

  testWidgets('wrapped scan payload still fills the form for review', (
    tester,
  ) async {
    final controller = _ScriptedImageController();
    final loc = await pumpScreen(tester, controller: controller);

    await deliverScanData(
      tester,
      controller: controller,
      loc: loc,
      payload: <String, dynamic>{
        '0': <String, dynamic>{
          'roaster': 'Wrapped Roaster',
          'name': 'Wrapped Beans',
          'origin': 'Wrapped Origin',
        },
      },
    );

    expect(find.text('Wrapped Roaster'), findsOneWidget);
    expect(find.text('Wrapped Beans'), findsOneWidget);
    expect(find.text('Wrapped Origin'), findsOneWidget);
    expect(find.bySemanticsIdentifier('scanReviewSection'), findsNothing);
    expect(find.byType(CollectedDataDialog), findsNothing);

    controller.complete();
    await tester.pump();
  });

  testWidgets(
    'ambiguous roast date keeps the parsed input and the action scrolls '
    'to the DatesCard confirmation',
    (tester) async {
      final controller = _ScriptedImageController();
      final loc = await pumpScreen(tester, controller: controller);

      await deliverScanData(
        tester,
        controller: controller,
        loc: loc,
        payload: <String, dynamic>{
          'roaster': 'Roaster A',
          'name': 'Beans A',
          'origin': 'Origin A',
          'roastDate': '2026-03-01T00:00:00.000',
          'roastDateRawText': '3/2024',
          'roastDateNeedsConfirmation': true,
        },
      );

      // The attention shows the raw printed date near the top, and the
      // existing field-level confirmation hint in DatesCard is retained.
      expect(find.text(loc.roastDateConfirmPrompt('3/2024')), findsNWidgets(2));

      // The parsed date itself is retained in the field, not cleared.
      final expectedDisplay = DateFormat.yMd('en').format(DateTime(2026, 3, 1));
      expect(find.text(expectedDisplay), findsOneWidget);

      // The attention's action scrolls the existing DatesCard into view.
      final before = tester.getRect(find.byType(DatesCard));
      await tester.tap(find.text(loc.edit));
      await tester.pumpAndSettle();
      final after = tester.getRect(find.byType(DatesCard));
      expect(after.top, lessThan(before.top));

      // The explicit field-level confirm still clears the uncertainty flag
      // for both the field hint and the top attention.
      await tester.tap(find.text(loc.roastDateConfirmAction));
      await tester.pumpAndSettle();
      expect(find.text(loc.roastDateConfirmPrompt('3/2024')), findsNothing);
      expect(find.bySemanticsIdentifier('scanReviewSection'), findsNothing);
      // The parsed date stays on the field after confirmation.
      expect(find.text(expectedDisplay), findsOneWidget);

      controller.complete();
      await tester.pump();
    },
  );

  testWidgets(
    'scan photos can be chosen explicitly as cover (two-photo handling)',
    (tester) async {
      final controller = _ScriptedImageController();
      final loc = await pumpScreen(tester, controller: controller);

      await deliverScanData(
        tester,
        controller: controller,
        loc: loc,
        reviewedImages: [XFile(scanPhotoPath), XFile(scanPhotoPath)],
        payload: <String, dynamic>{
          'roaster': 'Cover Roaster',
          'name': 'Cover Beans',
          'origin': 'Cover Origin',
        },
      );

      // Inline chooser with one tappable thumbnail per reviewed photo.
      expect(find.text(loc.beanCoverPhotoSavePromptBody), findsOneWidget);
      expect(
        find.bySemanticsIdentifier('scanCoverCandidate'),
        findsNWidgets(2),
      );

      // Tapping a thumbnail only previews the choice; confirmation applies it.
      await tester.tap(find.bySemanticsIdentifier('scanCoverCandidate').at(1));
      await tester.pumpAndSettle();
      expect(find.text(loc.beanCoverPhotoSavePromptBody), findsOneWidget);
      expect(find.text(loc.beanCoverPhotoRemove), findsNothing);
      await tester.tap(find.text(loc.scanUseAsCover));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier('scanReviewSection'), findsNothing);

      // Chooser is gone; the pending cover comes from the chosen scan photo;
      // the existing upload-at-save and clear/change behavior is untouched.
      expect(find.text(loc.beanCoverPhotoSavePromptBody), findsNothing);
      expect(find.text(loc.beanCoverPhotoRemove), findsOneWidget);
      final coverImage = tester.widget<Image>(
        find
            .byWidgetPredicate(
              (widget) => widget is Image && widget.image is FileImage,
            )
            .first,
      );
      expect((coverImage.image as FileImage).file.path, scanPhotoPath);

      controller.complete();
      await tester.pump();
    },
  );

  testWidgets('declining the cover choice keeps no cover set', (tester) async {
    final controller = _ScriptedImageController();
    final loc = await pumpScreen(tester, controller: controller);

    await deliverScanData(
      tester,
      controller: controller,
      loc: loc,
      reviewedImages: [XFile(scanPhotoPath)],
      payload: <String, dynamic>{
        'roaster': 'Roaster A',
        'name': 'Beans A',
        'origin': 'Origin A',
      },
    );

    expect(find.text(loc.beanCoverPhotoSavePromptBody), findsOneWidget);

    // Answering No declines only the optional cover choice.
    await tester.tap(find.text(loc.scanNotNow));
    await tester.pumpAndSettle();

    expect(find.text(loc.beanCoverPhotoSavePromptBody), findsNothing);
    // No cover was selected: the remove/change chips never appeared.
    expect(find.text(loc.beanCoverPhotoRemove), findsNothing);
    expect(find.text(loc.beanCoverPhotoChange), findsNothing);
    // No decisions remain, so the review section disappears.
    expect(find.bySemanticsIdentifier('scanReviewSection'), findsNothing);

    controller.complete();
    await tester.pump();
  });

  testWidgets('an existing cover is never offered for replacement', (
    tester,
  ) async {
    const existingPhotoUrl =
        'https://example.supabase.co/storage/v1/object/public/bean-photos/bean-1.jpg';
    final editBean = CoffeeBeansModel(
      beansUuid: 'bean-1',
      roaster: 'Existing Roaster',
      name: 'Existing Beans',
      origin: 'Existing Origin',
      versionVector: '{}',
      photoUrl: existingPhotoUrl,
    );

    final controller = _ScriptedImageController();
    final loc = await pumpScreen(
      tester,
      controller: controller,
      editBean: editBean,
    );

    await deliverScanData(
      tester,
      controller: controller,
      loc: loc,
      reviewedImages: [XFile(scanPhotoPath)],
      payload: <String, dynamic>{
        'roaster': 'Scanned Roaster',
        'name': 'Scanned Beans',
        'origin': 'Scanned Origin',
      },
    );

    // The form is still reviewed inline, but no cover chooser appears and
    // the existing cover stays in place.
    expect(find.bySemanticsIdentifier('scanReviewSection'), findsNothing);
    expect(find.text(loc.beanCoverPhotoSavePromptBody), findsNothing);
    expect(find.bySemanticsIdentifier('scanCoverCandidate'), findsNothing);
    expect(find.text(loc.beanCoverPhotoChange), findsOneWidget);
    expect(find.text(loc.beanCoverPhotoRemove), findsOneWidget);

    controller.complete();
    await tester.pump();
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets('review section at 320px and ${textScale}x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(640, 960);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      // Isolate the new section from unrelated form rows: every exception
      // here is a failure, including any overflow in the review itself.
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScanReviewSection(
                visible: true,
                roastDateRawText: '3/2024',
                roastDateNeedsConfirmation: true,
                onReviewRoastDate: () {},
                coverCandidates: [XFile(scanPhotoPath), XFile(scanPhotoPath)],
                onCoverSelected: (_) {},
                onCoverChoiceDismissed: () {},
                trailingSpacing: 16,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      assertReviewSectionLaysOutWithinBounds(tester);
      expect(
        find.bySemanticsIdentifier('scanCoverCandidate'),
        findsNWidgets(2),
      );
    });
  }

  testWidgets('save validation is unchanged by the review flow', (
    tester,
  ) async {
    final controller = _ScriptedImageController();
    final loc = await pumpScreen(tester, controller: controller);

    await deliverScanData(
      tester,
      controller: controller,
      loc: loc,
      payload: <String, dynamic>{
        'roaster': 'Roaster A',
        'name': 'Beans A',
        'origin': 'Origin A',
      },
    );

    bool saveDisabled() => tester
        .widget<StickyActionBar>(find.byType(StickyActionBar))
        .primaryDisabled;

    // Complete required fields → save enabled.
    expect(saveDisabled(), isFalse);

    // A rescan missing a required field disables save again — same
    // validation, no new hard validation block and no extra dialogs.
    // The payload is mutable: onData's normalization contract mutates the
    // delivered map (as production jsonDecode results are).
    controller.data(<String, dynamic>{
      'name': 'Only Name',
      'origin': 'Only Origin',
    });
    await tester.pumpAndSettle();

    expect(saveDisabled(), isTrue);
    expect(find.byType(AlertDialog), findsNothing);

    controller.complete();
    await tester.pump();
  });
}

typedef _ShowPreviewCallback =
    Future<void> Function(
      List<XFile> images,
      ImageSource source,
      Future<void> Function(List<XFile>, bool) onConfirm,
      Future<void> Function() onBackToSelection,
      Future<XFile?> Function()? onAddPhoto,
    );

/// Scripted controller: records the screen's callbacks so tests can
/// deliver payloads and drive the photo review flow directly.
class _ScriptedImageController extends NewBeansImageController {
  _ScriptedImageController()
    : super(
        supabaseClient: SupabaseClient(
          'https://example.supabase.co',
          'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final Completer<void> _completion = Completer<void>();
  late void Function(Map<String, dynamic>) data;
  late _ShowPreviewCallback showPreview;

  void complete() => _completion.complete();

  @override
  Future<void> start({
    required BuildContext context,
    required String locale,
    required void Function(bool) onLoading,
    required void Function(Map<String, dynamic>) onData,
    required void Function(String) onError,
    required Future<ImageSource?> Function() onChooseSource,
    required _ShowPreviewCallback onShowPreview,
    String? userId,
    bool isFirstTime = false,
    void Function(BeanScanStage stage)? onStage,
    required void Function(PhotoLibrarySaveResult result) onPhotoSaveResult,
  }) {
    data = onData;
    showPreview = onShowPreview;
    return _completion.future;
  }
}
