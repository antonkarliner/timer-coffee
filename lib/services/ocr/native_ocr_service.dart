import 'dart:io';
import 'package:flutter_native_ocr/flutter_native_ocr.dart';
import 'package:coffee_timer/services/ocr/ocr_service.dart';

/// Native on-device OCR backed by:
/// - iOS: Apple Vision
/// - Android: Google ML Kit Text Recognition v2
///
/// Notes:
/// - Fully on-device. No network required for OCR itself.
/// - Returns empty string if nothing recognized or errors occur.
class NativeOcrService implements OcrService {
  final FlutterNativeOcr _ocr = FlutterNativeOcr();

  NativeOcrService();

  @override
  Future<String> recognizeText(File imageFile) async {
    try {
      final String text = await _ocr.recognizeText(imageFile.path);
      // Normalize line endings and trim extra whitespace.
      return text.replaceAll('\r\n', '\n').trim();
    } on UnsupportedError {
      // Platform not supported (e.g., web); return empty and let caller fallback.
      return '';
    } catch (_) {
      // Swallow OCR exceptions and return empty to allow graceful fallback.
      return '';
    }
  }
}
