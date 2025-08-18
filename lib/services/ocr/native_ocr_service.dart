import 'dart:io';
import 'package:flutter_native_ocr/flutter_native_ocr.dart';
import 'package:coffee_timer/services/ocr/ocr_service.dart';

// Centralized console logging for this service
// Prefix helps filter in aggregated logs
// Example: [NativeOCR] message
void _log(String msg) {
  // ignore: avoid_print
  print('[NativeOCR] $msg');
}

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
      _log('Attempting OCR for ${imageFile.path.split('/').last}');
      final String text = await _ocr.recognizeText(imageFile.path);
      // Normalize line endings and trim extra whitespace.
      final cleanedText = text.replaceAll('\r\n', '\n').trim();
      _log(
          'OCR successful for ${imageFile.path.split('/').last}. Chars: ${cleanedText.length}');
      return cleanedText;
    } on UnsupportedError {
      _log(
          'OCR not supported on this platform for ${imageFile.path.split('/').last}.');
      return '';
    } catch (e, st) {
      _log('OCR failed for ${imageFile.path.split('/').last}: $e\n$st');
      return '';
    }
  }
}
