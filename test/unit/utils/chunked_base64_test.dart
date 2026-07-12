import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:coffee_timer/utils/images/chunked_base64.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chunked_base64_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<File> writeTempFile(Uint8List bytes) async {
    final file = File('${tempDir.path}/input.bin');
    await file.writeAsBytes(bytes);
    return file;
  }

  Uint8List randomBytes(int length) {
    final random = Random(42);
    return Uint8List.fromList(
        List.generate(length, (_) => random.nextInt(256)));
  }

  test('chunk size is a multiple of 3 so chunks concatenate without padding',
      () {
    expect(base64ChunkSize % 3, 0);
  });

  test('round-trips a >1MB file spanning multiple chunks', () async {
    // Larger than the 1MB threshold in NewBeansImageController and not a
    // multiple of the chunk size, so the final chunk is a partial one.
    final original = randomBytes(2 * 1024 * 1024 + 12345);
    final file = await writeTempFile(original);

    final encoded = await encodeFileToBase64InChunks(file);

    expect(base64Decode(encoded), original);
  });

  test('produces no padding characters mid-string', () async {
    final original = randomBytes(base64ChunkSize * 2 + 100);
    final file = await writeTempFile(original);

    final encoded = await encodeFileToBase64InChunks(file);

    final firstPadding = encoded.indexOf('=');
    if (firstPadding != -1) {
      // '=' may only appear as trailing padding.
      expect(firstPadding, greaterThanOrEqualTo(encoded.length - 2));
    }
    expect(encoded, base64Encode(original));
  });

  test('matches single-pass encoding for a file smaller than one chunk',
      () async {
    final original = randomBytes(1000);
    final file = await writeTempFile(original);

    final encoded = await encodeFileToBase64InChunks(file);

    expect(encoded, base64Encode(original));
  });

  test('matches single-pass encoding for a file of exactly one chunk',
      () async {
    final original = randomBytes(base64ChunkSize);
    final file = await writeTempFile(original);

    final encoded = await encodeFileToBase64InChunks(file);

    expect(encoded, base64Encode(original));
  });
}
