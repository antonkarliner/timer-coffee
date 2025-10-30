import 'dart:io';
import 'package:flutter_native_ocr/flutter_native_ocr.dart';
import 'package:coffee_timer/services/ocr/ocr_service.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:coffee_timer/utils/ocr_performance_monitor.dart';

/// Native on-device OCR backed by:
/// - iOS: Apple Vision
/// - Android: Google ML Kit Text Recognition v2
///
/// Notes:
/// - Fully on-device. No network required for OCR itself.
/// - Returns empty string if nothing recognized or errors occur.
class NativeOcrService implements OcrService {
  final FlutterNativeOcr _ocr = FlutterNativeOcr();
  final OcrPerformanceMonitor _monitor = OcrPerformanceMonitor();

  NativeOcrService() {
    // Initialize performance monitoring
    _monitor.initialize();
  }

  @override
  Future<String> recognizeText(File imageFile) async {
    // Get image file size for monitoring
    final fileSize = await imageFile.length();

    // Start performance monitoring
    final endMonitoring = await _monitor.startOperation(
      OcrOperationType.native,
      imageSizeBytes: fileSize,
    );

    try {
      final fileName = AppLogger.sanitize(imageFile.path.split('/').last);
      AppLogger.debug('[NativeOCR] Attempting OCR for $fileName');
      final String text = await _ocr.recognizeText(imageFile.path);
      // Normalize line endings and trim extra whitespace.
      final cleanedText = text.replaceAll('\r\n', '\n').trim();
      AppLogger.debug(
          '[NativeOCR] OCR successful for $fileName. Chars: ${cleanedText.length}');

      // Record successful operation
      endMonitoring(
        success: true,
        additionalData: {
          'fileName': fileName,
          'textLength': cleanedText.length,
        },
      );

      return cleanedText;
    } on UnsupportedError {
      final fileName = AppLogger.sanitize(imageFile.path.split('/').last);
      AppLogger.warning(
          '[NativeOCR] OCR not supported on this platform for $fileName');

      // Record unsupported error
      endMonitoring(
        success: false,
        error: 'OCR not supported on this platform',
        additionalData: {'fileName': fileName},
      );

      return '';
    } catch (e, st) {
      final fileName = AppLogger.sanitize(imageFile.path.split('/').last);
      AppLogger.error('[NativeOCR] OCR failed for $fileName',
          errorObject: e, stackTrace: st);

      // Record failed operation
      endMonitoring(
        success: false,
        error: e.toString(),
        additionalData: {'fileName': fileName},
      );

      return '';
    }
  }
}
