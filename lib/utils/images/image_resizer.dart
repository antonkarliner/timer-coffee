import 'dart:io';
import 'dart:typed_data';

import 'package:coffee_timer/utils/app_logger.dart';
import 'package:image/image.dart' as img;

class ImageResizer {
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB threshold
  static int _temporaryFileSequence = 0;

  /// Resize an image file to a max dimension of 1024px while preserving aspect
  /// ratio.
  ///
  /// Returns a temporary derivative when resizing is needed, otherwise returns
  /// [imageFile] unchanged.
  static Future<File> resizeToMax1024(File imageFile) async {
    return resizeToMaxSize(imageFile, 1024);
  }

  /// Resize an image file to a specified max dimension while preserving aspect
  /// ratio.
  ///
  /// Returns a temporary derivative when resizing is needed, otherwise returns
  /// [imageFile] unchanged.
  /// [maxSize] is the maximum width or height (whichever is larger)
  static Future<File> resizeToMaxSize(File imageFile, int maxSize) async {
    final sw = Stopwatch()..start();

    // Check file size before processing
    final fileSize = await imageFile.length();
    AppLogger.debug(
      '[ImageResizer] Processing image: ${imageFile.path.split('/').last}, size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
    );

    if (fileSize > _maxFileSizeBytes) {
      AppLogger.warning(
        '[ImageResizer] Skipping large image: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB exceeds threshold of ${(_maxFileSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB',
      );
      return imageFile;
    }

    // Read file in chunks to reduce memory pressure
    final Uint8List bytes;
    try {
      // For smaller files, read all at once
      if (fileSize < 1024 * 1024) {
        // 1MB
        bytes = await imageFile.readAsBytes();
      } else {
        // For larger files, use streaming approach
        bytes = await _readFileInChunks(imageFile);
      }
    } catch (e) {
      AppLogger.error('[ImageResizer] Error reading image file: $e');
      return imageFile;
    }

    // Decode image with memory management
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
      if (decoded == null) {
        AppLogger.warning('[ImageResizer] Failed to decode image');
        return imageFile;
      }
    } catch (e) {
      AppLogger.error('[ImageResizer] Error decoding image: $e');
      return imageFile;
    } finally {
      // Clear the original bytes from memory
      bytes.fillRange(0, bytes.length, 0);
    }

    if (decoded.width <= maxSize && decoded.height <= maxSize) {
      AppLogger.debug(
        '[ImageResizer] Image already within ${maxSize}px; keeping original',
      );
      decoded = null;
      return imageFile;
    }

    // Perform resize operation
    img.Image? resized;
    try {
      resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxSize : null,
        height: decoded.height > decoded.width ? maxSize : null,
        interpolation: img.Interpolation.average,
      );
    } catch (e) {
      AppLogger.error('[ImageResizer] Error resizing image: $e');
      return imageFile;
    } finally {
      // Clear the original decoded image from memory
      // The image package doesn't have dispose(), so we'll let GC handle it
      decoded = null;
    }

    // Encode and write with memory management
    try {
      final resizedBytes = img.encodeJpg(resized, quality: 85);

      final resizedImageFile = await _createTemporaryDerivative();

      try {
        await resizedImageFile.writeAsBytes(resizedBytes, flush: true);
      } catch (_) {
        if (await resizedImageFile.exists()) {
          await resizedImageFile.delete();
        }
        rethrow;
      }

      // Clear resized image from memory
      resized = null;

      AppLogger.debug(
        '[ImageResizer] Resize completed in ${sw.elapsedMilliseconds}ms, output size: ${(resizedBytes.length / 1024 / 1024).toStringAsFixed(2)}MB',
      );
      return resizedImageFile;
    } catch (e) {
      AppLogger.error('[ImageResizer] Error encoding/writing image: $e');
      resized = null;
      return imageFile;
    }
  }

  static Future<File> _createTemporaryDerivative() async {
    while (true) {
      final sequence = _temporaryFileSequence++;
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'timer_coffee_scan_${DateTime.now().microsecondsSinceEpoch}_'
        '$sequence.jpg',
      );
      try {
        return await file.create(exclusive: true);
      } on PathExistsException {
        // Extremely unlikely, but retry rather than overwrite another scan.
      }
    }
  }

  /// Read file in chunks to reduce memory pressure for large files
  static Future<Uint8List> _readFileInChunks(File file) async {
    const int chunkSize = 256 * 1024; // 256KB chunks
    final fileSize = await file.length();
    final chunks = <Uint8List>[];

    final randomAccessFile = await file.open();
    try {
      int position = 0;
      while (position < fileSize) {
        final remainingBytes = fileSize - position;
        final currentChunkSize = remainingBytes < chunkSize
            ? remainingBytes
            : chunkSize;

        final chunk = await randomAccessFile.read(currentChunkSize);
        chunks.add(chunk);
        position += currentChunkSize;
      }

      // Combine chunks
      final totalLength = chunks.fold<int>(
        0,
        (sum, chunk) => sum + chunk.length,
      );
      final result = Uint8List(totalLength);
      int offset = 0;

      for (final chunk in chunks) {
        result.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
        // Clear chunk from memory
        chunk.fillRange(0, chunk.length, 0);
      }

      return result;
    } finally {
      await randomAccessFile.close();
    }
  }

  /// Check if a file exceeds the size threshold
  static Future<bool> exceedsSizeThreshold(File file) async {
    try {
      final fileSize = await file.length();
      return fileSize > _maxFileSizeBytes;
    } catch (e) {
      AppLogger.error('[ImageResizer] Error checking file size: $e');
      return true; // Assume too large on error to be safe
    }
  }
}
