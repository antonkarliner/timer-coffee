import 'dart:io';

import 'package:coffee_timer/services/photo_library_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.coffee.timer/photo_library');
  late Directory testDirectory;
  late PhotoLibraryService service;

  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'photo_library_service_test_',
    );
    service = PhotoLibraryService(channel: channel);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await testDirectory.delete(recursive: true);
  });

  Future<List<String>> createImages(int count) async {
    final paths = <String>[];
    for (var index = 0; index < count; index++) {
      final file = File('${testDirectory.path}/image_$index.jpg');
      await file.writeAsBytes(<int>[index]);
      paths.add(file.path);
    }
    return paths;
  }

  test('passes validated paths and normalizes a saved response', () async {
    final paths = await createImages(2);
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedCall = call;
          return <String, Object>{
            'status': 'saved',
            'savedCount': 2,
            'failedCount': 0,
          };
        });

    final result = await service.saveImages(paths);

    expect(receivedCall?.method, 'saveImages');
    expect(receivedCall?.arguments, <String, Object>{'paths': paths});
    expect(result.status, PhotoLibrarySaveStatus.saved);
    expect(result.savedCount, 2);
    expect(result.failedCount, 0);
  });

  test('normalizes every native status with matching counts', () async {
    final paths = await createImages(2);
    final cases = <({String status, int saved, int failed})>[
      (status: 'saved', saved: 2, failed: 0),
      (status: 'partial', saved: 1, failed: 1),
      (status: 'denied', saved: 0, failed: 2),
      (status: 'failed', saved: 0, failed: 2),
      (status: 'unsupported', saved: 0, failed: 2),
    ];

    for (final testCase in cases) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            return <String, Object>{
              'status': testCase.status,
              'savedCount': testCase.saved,
              'failedCount': testCase.failed,
            };
          });

      final result = await service.saveImages(paths);

      expect(result.status.name, testCase.status);
      expect(result.savedCount, testCase.saved);
      expect(result.failedCount, testCase.failed);
    }
  });

  test('counts invalid paths without sending them to native code', () async {
    final paths = await createImages(1);
    List<Object?>? sentPaths;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final arguments = call.arguments as Map<Object?, Object?>;
          sentPaths = arguments['paths'] as List<Object?>;
          return <String, Object>{
            'status': 'saved',
            'savedCount': 1,
            'failedCount': 0,
          };
        });

    final result = await service.saveImages(<String>[
      paths.single,
      '',
      '${testDirectory.path}/missing.jpg',
    ]);

    expect(sentPaths, <Object?>[paths.single]);
    expect(result.status, PhotoLibrarySaveStatus.partial);
    expect(result.savedCount, 1);
    expect(result.failedCount, 2);
  });

  test(
    'rejects empty and wholly invalid input before channel invocation',
    () async {
      var invocationCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            invocationCount++;
            return null;
          });

      final empty = await service.saveImages(const <String>[]);
      final invalid = await service.saveImages(<String>[
        '   ',
        '${testDirectory.path}/missing.jpg',
      ]);

      expect(empty.status, PhotoLibrarySaveStatus.failed);
      expect(empty.savedCount, 0);
      expect(empty.failedCount, 0);
      expect(invalid.status, PhotoLibrarySaveStatus.failed);
      expect(invalid.savedCount, 0);
      expect(invalid.failedCount, 2);
      expect(invocationCount, 0);
    },
  );

  test('turns malformed native responses into a failed result', () async {
    final paths = await createImages(2);
    final malformedResponses = <Object?>[
      null,
      'saved',
      <String, Object>{'status': 'unknown', 'savedCount': 2, 'failedCount': 0},
      <String, Object>{'status': 'saved', 'savedCount': -1, 'failedCount': 3},
      <String, Object>{'status': 'saved', 'savedCount': 1, 'failedCount': 1},
      <String, Object>{'status': 'partial', 'savedCount': 2, 'failedCount': 0},
      <String, Object>{'status': 'failed', 'savedCount': '0', 'failedCount': 2},
    ];

    for (final response in malformedResponses) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => response);

      final result = await service.saveImages(paths);

      expect(result.status, PhotoLibrarySaveStatus.failed);
      expect(result.savedCount, 0);
      expect(result.failedCount, 2);
    }
  });

  test('normalizes channel availability and platform failures', () async {
    final paths = await createImages(1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw MissingPluginException(),
        );

    final unsupported = await service.saveImages(paths);

    expect(unsupported.status, PhotoLibrarySaveStatus.unsupported);
    expect(unsupported.savedCount, 0);
    expect(unsupported.failedCount, 1);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(code: 'SAVE_FAILED'),
        );

    final failed = await service.saveImages(paths);

    expect(failed.status, PhotoLibrarySaveStatus.failed);
    expect(failed.savedCount, 0);
    expect(failed.failedCount, 1);
  });
}
