import 'dart:io';
import 'dart:typed_data';
//import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:coffee_timer/utils/device_profiler.dart';
import 'package:coffee_timer/utils/ocr_performance_monitor.dart';

/// Preprocessing intensity levels based on device capabilities
enum PreprocessingIntensity {
  light, // For low-end devices
  medium, // For mid-range devices
  heavy, // For high-end devices
}

/// Enhanced image preprocessor for OCR accuracy
/// Implements grayscale conversion and contrast enhancement
class ImagePreprocessor {
  static final OcrPerformanceMonitor _monitor = OcrPerformanceMonitor();

  /// Preprocess an image file for OCR
  /// Returns a new file with preprocessed image data
  static Future<File> preprocessForOcr(
    File imageFile, {
    PreprocessingIntensity? intensity,
    bool enableGrayscale = true,
    bool enableContrastEnhancement = false,
  }) async {
    // Initialize monitoring on first use
    _monitor.initialize();

    // Get image file size for monitoring
    final fileSize = await imageFile.length();

    // Start performance monitoring
    final endMonitoring = await _monitor.startOperation(
      OcrOperationType.preprocessing,
      imageSizeBytes: fileSize,
    );

    final sw = Stopwatch()..start();

    try {
      AppLogger.debug(
          '[ImagePreprocessor] Starting preprocessing for ${imageFile.path.split('/').last} (contrast enhancement disabled)');

      // Determine device-aware intensity if not specified (only used if contrast is enabled)
      intensity ??= await _getDeviceAwareIntensity();
      AppLogger.debug(
          '[ImagePreprocessor] Using intensity level: $intensity (contrast disabled)');

      // Read image bytes
      final Uint8List bytes = await imageFile.readAsBytes();

      // Decode image
      final img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        AppLogger.warning(
            '[ImagePreprocessor] Failed to decode image, returning original');

        // Record failed preprocessing
        endMonitoring(
          success: false,
          error: 'Failed to decode image',
          additionalData: {'fileName': imageFile.path.split('/').last},
        );

        return imageFile;
      }

      img.Image processedImage = originalImage;

      // Apply grayscale conversion
      if (enableGrayscale) {
        final grayscaleSw = Stopwatch()..start();
        processedImage = _convertToGrayscale(processedImage);
        grayscaleSw.stop();
        AppLogger.debug(
            '[ImagePreprocessor] Grayscale conversion completed in ${grayscaleSw.elapsedMilliseconds}ms');
      }

      // Apply contrast enhancement (now disabled by default)
      if (enableContrastEnhancement) {
        AppLogger.warning(
            '[ImagePreprocessor] Contrast enhancement requested but not available');
      } else {
        AppLogger.debug(
            '[ImagePreprocessor] Contrast enhancement skipped (disabled)');
      }

      // Encode and write the processed image
      final processedBytes = img.encodeJpg(processedImage, quality: 90);
      final processedFile = File('${imageFile.path}_processed.jpg');
      await processedFile.writeAsBytes(processedBytes);

      sw.stop();
      AppLogger.debug(
          '[ImagePreprocessor] Preprocessing completed in ${sw.elapsedMilliseconds}ms (grayscale only), '
          'output size: ${(processedBytes.length / 1024 / 1024).toStringAsFixed(2)}MB');

      // Record successful preprocessing
      endMonitoring(
        success: true,
        additionalData: {
          'fileName': imageFile.path.split('/').last,
          'intensity': intensity.toString(),
          'enableGrayscale': enableGrayscale,
          'enableContrastEnhancement': enableContrastEnhancement,
          'outputSizeBytes': processedBytes.length,
          'originalSizeBytes': bytes.length,
          'contrastEnhancementDisabled': !enableContrastEnhancement,
        },
      );

      return processedFile;
    } catch (e) {
      AppLogger.error('[ImagePreprocessor] Error during preprocessing: $e');

      // Record failed preprocessing
      endMonitoring(
        success: false,
        error: e.toString(),
        additionalData: {'fileName': imageFile.path.split('/').last},
      );

      return imageFile; // Return original file on error
    }
  }

  /// Convert image to grayscale using luminance method
  static img.Image _convertToGrayscale(img.Image image) {
    return img.grayscale(image);
  }

  /// Enhance contrast using adaptive histogram equalization (DISABLED)
  /*static img.Image _enhanceContrast(
      img.Image image, PreprocessingIntensity intensity) {
    // Calculate histogram
    final histogram = List<int>.filled(256, 0);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        histogram[pixel.r.toInt()]++;
      }
    }

    // Calculate cumulative distribution function (CDF)
    final cdf = List<int>.filled(256, 0);
    cdf[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i];
    }

    // Find CDF min and max (excluding zeros)
    int cdfMin = 0;
    while (cdfMin < 256 && cdf[cdfMin] == 0) cdfMin++;

    final cdfMax = cdf[255];
    final cdfRange = cdfMax - cdfMin;

    // Apply histogram equalization with intensity-based clipping
    final clipLimit = _getClipLimit(intensity);
    final enhancedImage = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final intensity = pixel.r.toInt();

        // Apply histogram equalization
        int newValue;
        if (cdfRange > 0) {
          newValue = ((cdf[intensity] - cdfMin) / cdfRange * 255).round();
        } else {
          newValue = intensity;
        }

        // Apply clipping based on intensity level
        newValue = _clipValue(newValue, clipLimit);

        enhancedImage.setPixel(
            x, y, img.ColorRgb8(newValue, newValue, newValue));
      }
    }

    return enhancedImage;
  }*/

  /// Determine device-aware preprocessing intensity
  static Future<PreprocessingIntensity> _getDeviceAwareIntensity() async {
    try {
      final isLowEnd = await DeviceProfiler.isLowEndDevice;
      if (isLowEnd) {
        return PreprocessingIntensity.light;
      }

      // For now, use medium for capable devices
      // Could be enhanced with more device profiling in future
      return PreprocessingIntensity.medium;
    } catch (e) {
      AppLogger.error(
          '[ImagePreprocessor] Error determining device intensity: $e');
      return PreprocessingIntensity.medium; // Default to medium on error
    }
  }

  /// Get clip limit based on intensity level (UNUSED - commented out)
  /*static int _getClipLimit(PreprocessingIntensity intensity) {
    switch (intensity) {
      case PreprocessingIntensity.light:
        return 20; // Less aggressive clipping
      case PreprocessingIntensity.medium:
        return 10; // Moderate clipping
      case PreprocessingIntensity.heavy:
        return 5; // More aggressive clipping
    }
  }*/

  /// Clip value to prevent over-enhancement (UNUSED - commented out)
  /*static int _clipValue(int value, int clipLimit) {
    // Apply a gentle S-curve to prevent over-enhancement
    final normalized = value / 255.0;
    final clipped =
        (pow(normalized, 1.0 / (1.0 + clipLimit / 100.0)) * 255).round();
    return clipped.clamp(0, 255);
  }*/
}

/*
 * ORIGINAL CONTRAST ENHANCEMENT METHODS (COMMENTED OUT)
 * These methods are kept for reference but no longer used
 * since contrast enhancement is disabled by default
 */

/// Enhance contrast using adaptive histogram equalization (ORIGINAL - COMMENTED OUT)
/*static img.Image _enhanceContrastOriginal(
    img.Image image, PreprocessingIntensity intensity) {
  // Calculate histogram
  final histogram = List<int>.filled(256, 0);
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      histogram[pixel.r.toInt()]++;
    }
  }

  // Calculate cumulative distribution function (CDF)
  final cdf = List<int>.filled(256, 0);
  cdf[0] = histogram[0];
  for (int i = 1; i < 256; i++) {
    cdf[i] = cdf[i - 1] + histogram[i];
  }

  // Find CDF min and max (excluding zeros)
  int cdfMin = 0;
  while (cdfMin < 256 && cdf[cdfMin] == 0) cdfMin++;

  final cdfMax = cdf[255];
  final cdfRange = cdfMax - cdfMin;

  // Apply histogram equalization with intensity-based clipping
  final clipLimit = _getClipLimitOriginal(intensity);
  final enhancedImage = img.Image(width: image.width, height: image.height);

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final intensity = pixel.r.toInt();

      // Apply histogram equalization
      int newValue;
      if (cdfRange > 0) {
        newValue = ((cdf[intensity] - cdfMin) / cdfRange * 255).round();
      } else {
        newValue = intensity;
      }

      // Apply clipping based on intensity level
      newValue = _clipValueOriginal(newValue, clipLimit);

      enhancedImage.setPixel(
          x, y, img.ColorRgb8(newValue, newValue, newValue));
    }
  }

  return enhancedImage;
}*/

/// Get clip limit based on intensity level (ORIGINAL - COMMENTED OUT)
/*static int _getClipLimitOriginal(PreprocessingIntensity intensity) {
  switch (intensity) {
    case PreprocessingIntensity.light:
      return 20; // Less aggressive clipping
    case PreprocessingIntensity.medium:
      return 10; // Moderate clipping
    case PreprocessingIntensity.heavy:
      return 5; // More aggressive clipping
  }
}*/

/// Clip value to prevent over-enhancement (ORIGINAL - COMMENTED OUT)
/*static int _clipValueOriginal(int value, int clipLimit) {
  // Apply a gentle S-curve to prevent over-enhancement
  final normalized = value / 255.0;
  final clipped =
      (pow(normalized, 1.0 / (1.0 + clipLimit / 100.0)) * 255).round();
  return clipped.clamp(0, 255);
}*/
