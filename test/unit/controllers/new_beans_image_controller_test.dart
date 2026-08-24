import 'package:coffee_timer/controllers/new_beans_image_controller.dart';
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
        onChooseSource: () async => ImageSource.gallery,
        onShowPreview:
            (images, onConfirm, onBackToSelection, onAddPhoto) async {
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
        onChooseSource: () async => ImageSource.gallery,
        onShowPreview:
            (images, onConfirm, onBackToSelection, onAddPhoto) async {
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
        onChooseSource: () async => ImageSource.camera,
        onShowPreview:
            (images, onConfirm, onBackToSelection, reviewAddPhoto) async {
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
}

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this.results);

  final List<XFile?> results;
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
    expect(source, ImageSource.camera);
    return results[cameraCalls++];
  }
}
