import 'dart:io';

import 'package:coffee_timer/utils/images/image_resizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  late Directory testDirectory;

  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'image_resizer_test_',
    );
  });

  tearDown(() async {
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  test(
    'large image produces a bounded derivative without changing original',
    () async {
      final original = File('${testDirectory.path}/large.jpg');
      final originalImage = img.Image(width: 1600, height: 900);
      await original.writeAsBytes(img.encodeJpg(originalImage, quality: 95));
      final originalBytes = await original.readAsBytes();

      final derivative = await ImageResizer.resizeToMaxSize(original, 800);

      try {
        expect(derivative.path, isNot(original.path));
        expect(await derivative.exists(), isTrue);

        final resizedImage = img.decodeImage(await derivative.readAsBytes());
        expect(resizedImage, isNotNull);
        expect(resizedImage!.width, 800);
        expect(resizedImage.height, 450);

        expect(await original.readAsBytes(), originalBytes);
        final unchangedOriginal = img.decodeImage(await original.readAsBytes());
        expect(unchangedOriginal, isNotNull);
        expect(unchangedOriginal!.width, 1600);
        expect(unchangedOriginal.height, 900);
      } finally {
        if (await derivative.exists()) {
          await derivative.delete();
        }
      }
    },
  );

  test('small image is returned unchanged instead of being upscaled', () async {
    final original = File('${testDirectory.path}/small.jpg');
    final originalImage = img.Image(width: 320, height: 180);
    await original.writeAsBytes(img.encodeJpg(originalImage, quality: 95));
    final originalBytes = await original.readAsBytes();

    final result = await ImageResizer.resizeToMaxSize(original, 800);

    expect(result.path, original.path);
    expect(await result.readAsBytes(), originalBytes);
    final unchangedImage = img.decodeImage(await result.readAsBytes());
    expect(unchangedImage, isNotNull);
    expect(unchangedImage!.width, 320);
    expect(unchangedImage.height, 180);
  });

  test('each resize writes a uniquely named temporary derivative', () async {
    final original = File('${testDirectory.path}/large.jpg');
    final originalImage = img.Image(width: 1200, height: 900);
    await original.writeAsBytes(img.encodeJpg(originalImage, quality: 95));

    final first = await ImageResizer.resizeToMaxSize(original, 600);
    final second = await ImageResizer.resizeToMaxSize(original, 600);

    try {
      expect(first.parent.path, Directory.systemTemp.path);
      expect(second.parent.path, Directory.systemTemp.path);
      expect(first.path, isNot(second.path));
      expect(await first.exists(), isTrue);
      expect(await second.exists(), isTrue);
    } finally {
      if (await first.exists()) {
        await first.delete();
      }
      if (await second.exists()) {
        await second.delete();
      }
    }
  });
}
