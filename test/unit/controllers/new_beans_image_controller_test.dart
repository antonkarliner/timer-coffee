import 'dart:io';

import 'package:coffee_timer/controllers/new_beans_image_controller.dart';
import 'package:coffee_timer/services/clients/beans_label_parser_client.dart';
import 'package:coffee_timer/services/photo_library_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.coffee.timer/inline_photo_picker');

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('uses native compact picker for the iOS gallery', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final receivedCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            receivedCalls.add(call);
            final arguments = call.arguments as Map<Object?, Object?>;
            return arguments['selectionLimit'] == 1
                ? <String>['/tmp/third.jpg']
                : <String>['/tmp/first.jpg', '/tmp/second.jpg'];
          });

      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox();
            },
          ),
        ),
      );

      final controller = NewBeansImageController(
        supabaseClient: SupabaseClient(
          'https://example.supabase.co',
          'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
      List<XFile>? previewImages;
      Future<XFile?> Function()? addPhoto;

      await controller.start(
        context: context,
        locale: 'en',
        onLoading: (_) {},
        onData: (_) {},
        onError: (message) => fail(message),
        onPhotoSaveResult: (_) {},
        onChooseSource: () async => ImageSource.gallery,
        onShowPreview:
            (images, source, onConfirm, onBackToSelection, onAddPhoto) async {
              expect(source, ImageSource.gallery);
              previewImages = images;
              addPhoto = onAddPhoto;
            },
      );

      expect(receivedCalls.single.method, 'pickImages');
      expect(receivedCalls.single.arguments, {'selectionLimit': 2});
      expect(previewImages?.map((image) => image.path), [
        '/tmp/first.jpg',
        '/tmp/second.jpg',
      ]);
      expect(addPhoto, isNotNull);
      expect((await addPhoto!())?.path, '/tmp/third.jpg');
      expect(receivedCalls, hasLength(2));
      expect(receivedCalls.last.method, 'pickImages');
      expect(receivedCalls.last.arguments, {'selectionLimit': 1});
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('treats dismissing the native picker as cancellation', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => <String>[]);

      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox();
            },
          ),
        ),
      );

      final controller = NewBeansImageController(
        supabaseClient: SupabaseClient(
          'https://example.supabase.co',
          'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
      var showedPreview = false;

      await controller.start(
        context: context,
        locale: 'en',
        onLoading: (_) {},
        onData: (_) {},
        onError: (message) => fail(message),
        onPhotoSaveResult: (_) {},
        onChooseSource: () async => ImageSource.gallery,
        onShowPreview:
            (images, source, onConfirm, onBackToSelection, onAddPhoto) async {
              showedPreview = true;
            },
      );

      expect(showedPreview, isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'camera review owns the optional second capture and cancellation does not relaunch',
    (tester) async {
      final picker = _FakeImagePicker([XFile('/tmp/first.jpg'), null]);
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox();
            },
          ),
        ),
      );

      final controller = NewBeansImageController(
        supabaseClient: SupabaseClient(
          'https://example.supabase.co',
          'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
        imagePicker: picker,
      );
      Future<XFile?> Function()? addPhoto;

      await controller.start(
        context: context,
        locale: 'en',
        onLoading: (_) {},
        onData: (_) {},
        onError: (message) => fail(message),
        onPhotoSaveResult: (_) {},
        onChooseSource: () async => ImageSource.camera,
        onShowPreview:
            (
              images,
              source,
              onConfirm,
              onBackToSelection,
              reviewAddPhoto,
            ) async {
              expect(source, ImageSource.camera);
              expect(images.single.path, '/tmp/first.jpg');
              addPhoto = reviewAddPhoto;
            },
      );

      expect(picker.cameraCalls, 1);
      expect(addPhoto, isNotNull);
      expect(await addPhoto!(), isNull);
      expect(picker.cameraCalls, 2);
    },
  );

  test('deletes a derivative after successful image preparation', () async {
    final testDirectory = await Directory.systemTemp.createTemp(
      'new_beans_image_controller_test_',
    );
    try {
      final original = File('${testDirectory.path}/original.jpg');
      final derivative = File('${testDirectory.path}/derivative.jpg');
      await original.writeAsString('original');

      final controller = NewBeansImageController(
        supabaseClient: _testSupabaseClient(),
        imageResizer: (image, maxSize) async {
          expect(image.path, original.path);
          expect(maxSize, 800);
          await derivative.writeAsString('derivative');
          return derivative;
        },
        imageEncoder: (image) async {
          expect(image.path, derivative.path);
          expect(await image.exists(), isTrue);
          return 'encoded-image';
        },
      );

      final result = await controller.prepareImageForTesting(
        XFile(original.path),
        800,
        0,
      );

      expect(result.success, isTrue);
      expect(result.base64Image, 'encoded-image');
      expect(await derivative.exists(), isFalse);
      expect(await original.readAsString(), 'original');
    } finally {
      await testDirectory.delete(recursive: true);
    }
  });

  test('deletes a derivative when encoding fails', () async {
    final testDirectory = await Directory.systemTemp.createTemp(
      'new_beans_image_controller_test_',
    );
    try {
      final original = File('${testDirectory.path}/original.jpg');
      final derivative = File('${testDirectory.path}/derivative.jpg');
      await original.writeAsString('original');

      final controller = NewBeansImageController(
        supabaseClient: _testSupabaseClient(),
        imageResizer: (image, maxSize) async {
          await derivative.writeAsString('derivative');
          return derivative;
        },
        imageEncoder: (_) async => throw StateError('encode failed'),
      );

      final result = await controller.prepareImageForTesting(
        XFile(original.path),
        800,
        0,
      );

      expect(result.success, isFalse);
      expect(result.error, contains('encode failed'));
      expect(await derivative.exists(), isFalse);
      expect(await original.readAsString(), 'original');
    } finally {
      await testDirectory.delete(recursive: true);
    }
  });

  test(
    'camera save uses final reviewed order before preparation and parsing',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'new_beans_camera_save_test_',
      );
      try {
        final first = await File(
          '${directory.path}/first.jpg',
        ).writeAsString('first');
        final second = await File(
          '${directory.path}/second.jpg',
        ).writeAsString('second');
        final events = <String>[];
        final service = _FakePhotoLibraryService(
          const PhotoLibrarySaveResult(
            status: PhotoLibrarySaveStatus.saved,
            savedCount: 2,
            failedCount: 0,
          ),
          events: events,
        );
        final parser = _FakeBeansLabelParserClient(events: events);
        final stages = <BeanScanStage>[];
        final saveResults = <PhotoLibrarySaveResult>[];
        ImageSource? previewSource;
        final context = _FakeBuildContext();
        final controller = NewBeansImageController(
          supabaseClient: _testSupabaseClient(),
          imagePicker: _FakeImagePicker([
            XFile(first.path),
            XFile(second.path),
          ]),
          photoLibraryService: service,
          parserClient: parser,
          imageResizer: (image, _) async {
            events.add('prepare:${image.path}');
            return image;
          },
          imageEncoder: (image) async => 'encoded:${image.path}',
        );

        await controller.start(
          context: context,
          locale: 'en',
          onLoading: (_) {},
          onData: (_) {},
          onError: fail,
          onChooseSource: () async => ImageSource.camera,
          onPhotoSaveResult: saveResults.add,
          onStage: stages.add,
          onShowPreview:
              (images, source, onConfirm, onBackToSelection, onAddPhoto) async {
                previewSource = source;
                final added = await onAddPhoto!();
                await onConfirm([added!, images.single], true);
              },
        );

        expect(previewSource, ImageSource.camera);
        expect(service.calls, [
          [second.path, first.path],
        ]);
        expect(saveResults.single.status, PhotoLibrarySaveStatus.saved);
        expect(stages, [
          BeanScanStage.savingPhotos,
          BeanScanStage.preparingImages,
          BeanScanStage.readingLabel,
        ]);
        expect(events.first, 'save');
        expect(events[1], 'prepare:${second.path}');
        expect(events[2], 'prepare:${first.path}');
        expect(events.last, 'parse');
        expect(parser.calls, 1);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'every photo save result continues into preparation and parsing',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'new_beans_save_results_test_',
      );
      try {
        final image = await File(
          '${directory.path}/scan.jpg',
        ).writeAsString('scan');
        final cases = <PhotoLibrarySaveResult>[
          const PhotoLibrarySaveResult(
            status: PhotoLibrarySaveStatus.saved,
            savedCount: 1,
            failedCount: 0,
          ),
          const PhotoLibrarySaveResult(
            status: PhotoLibrarySaveStatus.partial,
            savedCount: 1,
            failedCount: 1,
          ),
          const PhotoLibrarySaveResult(
            status: PhotoLibrarySaveStatus.denied,
            savedCount: 0,
            failedCount: 1,
          ),
          const PhotoLibrarySaveResult(
            status: PhotoLibrarySaveStatus.failed,
            savedCount: 0,
            failedCount: 1,
          ),
          const PhotoLibrarySaveResult(
            status: PhotoLibrarySaveStatus.unsupported,
            savedCount: 0,
            failedCount: 1,
          ),
        ];
        final context = _FakeBuildContext();

        for (final saveResult in cases) {
          final parser = _FakeBeansLabelParserClient();
          final stages = <BeanScanStage>[];
          PhotoLibrarySaveResult? reportedResult;
          final controller = NewBeansImageController(
            supabaseClient: _testSupabaseClient(),
            imagePicker: _FakeImagePicker([XFile(image.path)]),
            photoLibraryService: _FakePhotoLibraryService(saveResult),
            parserClient: parser,
            imageResizer: (file, _) async => file,
            imageEncoder: (_) async => 'encoded-image',
          );

          await controller.start(
            context: context,
            locale: 'en',
            onLoading: (_) {},
            onData: (_) {},
            onError: fail,
            onChooseSource: () async => ImageSource.camera,
            onPhotoSaveResult: (result) => reportedResult = result,
            onStage: stages.add,
            onShowPreview:
                (
                  images,
                  source,
                  onConfirm,
                  onBackToSelection,
                  onAddPhoto,
                ) async {
                  await onConfirm(images, true);
                },
          );

          expect(reportedResult?.status, saveResult.status);
          expect(parser.calls, 1, reason: '${saveResult.status} must continue');
          expect(stages, [
            BeanScanStage.savingPhotos,
            BeanScanStage.preparingImages,
            BeanScanStage.readingLabel,
          ]);
        }
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test('gallery and camera opt-out never invoke photo saving', () async {
    final directory = await Directory.systemTemp.createTemp(
      'new_beans_save_noop_test_',
    );
    try {
      final image = await File(
        '${directory.path}/scan.jpg',
      ).writeAsString('scan');
      final context = _FakeBuildContext();

      for (final scenario in <(ImageSource, bool)>[
        (ImageSource.gallery, true),
        (ImageSource.camera, false),
      ]) {
        final service = _FakePhotoLibraryService(
          const PhotoLibrarySaveResult(
            status: PhotoLibrarySaveStatus.saved,
            savedCount: 1,
            failedCount: 0,
          ),
        );
        final parser = _FakeBeansLabelParserClient();
        final picker = _FakeImagePicker(
          scenario.$1 == ImageSource.camera ? [XFile(image.path)] : const [],
          galleryResults: [XFile(image.path)],
        );
        ImageSource? previewSource;
        final controller = NewBeansImageController(
          supabaseClient: _testSupabaseClient(),
          imagePicker: picker,
          photoLibraryService: service,
          parserClient: parser,
          imageResizer: (file, _) async => file,
          imageEncoder: (_) async => 'encoded-image',
        );

        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        await controller.start(
          context: context,
          locale: 'en',
          onLoading: (_) {},
          onData: (_) {},
          onError: fail,
          onChooseSource: () async => scenario.$1,
          onPhotoSaveResult: (_) => fail('save result should not be reported'),
          onShowPreview:
              (images, source, onConfirm, onBackToSelection, onAddPhoto) async {
                previewSource = source;
                await onConfirm(images, scenario.$2);
              },
        );

        expect(previewSource, scenario.$1);
        expect(service.calls, isEmpty);
        expect(parser.calls, 1);
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test(
    'unexpected photo service exception reports failure and parses',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'new_beans_save_exception_test_',
      );
      try {
        final image = await File(
          '${directory.path}/scan.jpg',
        ).writeAsString('scan');
        final parser = _FakeBeansLabelParserClient();
        PhotoLibrarySaveResult? reportedResult;
        final controller = NewBeansImageController(
          supabaseClient: _testSupabaseClient(),
          imagePicker: _FakeImagePicker([XFile(image.path)]),
          photoLibraryService: _ThrowingPhotoLibraryService(),
          parserClient: parser,
          imageResizer: (file, _) async => file,
          imageEncoder: (_) async => 'encoded-image',
        );

        await controller.start(
          context: _FakeBuildContext(),
          locale: 'en',
          onLoading: (_) {},
          onData: (_) {},
          onError: fail,
          onChooseSource: () async => ImageSource.camera,
          onPhotoSaveResult: (result) => reportedResult = result,
          onShowPreview:
              (images, source, onConfirm, onBackToSelection, onAddPhoto) async {
                await onConfirm(images, true);
              },
        );

        expect(reportedResult?.status, PhotoLibrarySaveStatus.failed);
        expect(reportedResult?.savedCount, 0);
        expect(reportedResult?.failedCount, 1);
        expect(parser.calls, 1);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}

SupabaseClient _testSupabaseClient() {
  return SupabaseClient(
    'https://example.supabase.co',
    'anon-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this.results, {this.galleryResults = const []});

  final List<XFile?> results;
  final List<XFile> galleryResults;
  int cameraCalls = 0;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (source == ImageSource.gallery) {
      return galleryResults.isEmpty ? null : galleryResults.first;
    }
    return results[cameraCalls++];
  }

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async => galleryResults.take(limit ?? galleryResults.length).toList();
}

class _FakeBuildContext extends Fake implements BuildContext {}

class _FakePhotoLibraryService extends PhotoLibraryService {
  _FakePhotoLibraryService(this.result, {this.events});

  final PhotoLibrarySaveResult result;
  final List<String>? events;
  final List<List<String>> calls = [];

  @override
  Future<PhotoLibrarySaveResult> saveImages(List<String> paths) async {
    calls.add(List<String>.from(paths));
    events?.add('save');
    return result;
  }
}

class _ThrowingPhotoLibraryService extends PhotoLibraryService {
  @override
  Future<PhotoLibrarySaveResult> saveImages(List<String> paths) {
    throw StateError('unexpected save failure');
  }
}

class _FakeBeansLabelParserClient extends BeansLabelParserClient {
  _FakeBeansLabelParserClient({this.events}) : super(_testSupabaseClient());

  final List<String>? events;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> parseLabel({
    required List<String> base64Images,
    required String locale,
    String? userId,
  }) async {
    calls++;
    events?.add('parse');
    return <String, dynamic>{'name': 'Parsed beans'};
  }
}
