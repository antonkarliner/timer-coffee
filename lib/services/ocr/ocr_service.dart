import 'dart:io';

/// Abstraction for on-device OCR.
/// Implementations should perform OCR fully on-device and return recognized text.
/// Returns an empty string when nothing is recognized.
///
/// Usage:
/// final text = await ocrService.recognizeText(File(path));
abstract class OcrService {
  Future<String> recognizeText(File imageFile);
}
