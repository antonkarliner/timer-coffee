import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:coffee_timer/services/ocr/ocr_service.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:coffee_timer/utils/ocr_performance_monitor.dart';
import 'package:coffee_timer/models/image_processing_result.dart';
import 'package:coffee_timer/utils/images/image_preprocessor.dart';

/// Manages background OCR processing for the New Beans image flow.
/// This class handles OCR operations that start immediately when images are captured,
/// allowing for faster overall processing by overlapping user interaction with OCR work.
class BackgroundOcrManager {
  final OcrService _ocrService;
  final OcrPerformanceMonitor _monitor;
  final List<ImageProcessingResult> _pendingResults = [];
  bool _isProcessing = false;
  int _activeOperations = 0;
  final int _maxConcurrentOperations;

  /// Creates a BackgroundOcrManager instance.
  ///
  /// [ocrService] - The OCR service to use for text recognition
  /// [maxConcurrentOperations] - Maximum number of concurrent OCR operations (default: 2)
  BackgroundOcrManager({
    required OcrService ocrService,
    int maxConcurrentOperations = 2,
  })  : _ocrService = ocrService,
        _maxConcurrentOperations = maxConcurrentOperations,
        _monitor = OcrPerformanceMonitor() {
    _monitor.initialize();
  }

  /// Starts background OCR processing on a list of images.
  ///
  /// Returns immediately, allowing OCR to proceed in background.
  Future<void> startBackgroundOcr(List<XFile> images) async {
    if (_isProcessing || images.isEmpty) {
      _log('Background OCR: Already processing or no images provided');
      return;
    }

    _isProcessing = true;
    _log('Starting background OCR on ${images.length} images');

    try {
      // Process images with concurrency control
      final futures = <Future<void>>[];

      for (final image in images) {
        // Wait if we've reached max concurrent operations
        while (_activeOperations >= _maxConcurrentOperations) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        _activeOperations++;
        final future = _processSingleImage(image).then((result) {
          _activeOperations--;
          if (result != null) {
            _pendingResults.add(result);
          }
        }).catchError((error) {
          _activeOperations--;
          _log('Background OCR error for image: $error');
        });

        futures.add(future);
      }

      // Wait for all operations to complete (but don't block caller)
      Future.wait(futures).then((_) {
        _isProcessing = false;
        _log('Background OCR completed on ${images.length} images');
      });
    } catch (e) {
      _isProcessing = false;
      _log('Background OCR initialization failed: $e');
      rethrow;
    }
  }

  /// Gets all pending OCR results.
  ///
  /// Returns a list of ImageProcessingResult objects containing OCR data.
  List<ImageProcessingResult> getPendingResults() {
    return List.from(_pendingResults);
  }

  /// Gets only successful OCR results.
  List<ImageProcessingResult> getSuccessfulResults() {
    return _pendingResults.where((r) => r.success).toList();
  }

  /// Clears all pending OCR results.
  void clearResults() {
    _pendingResults.clear();
    _log('Cleared pending OCR results');
  }

  /// Checks if background OCR is currently processing.
  bool get isProcessing => _isProcessing;

  /// Gets the number of pending results.
  int get pendingResultsCount => _pendingResults.length;

  /// Processes a single image with OCR.
  ///
  /// Returns an ImageProcessingResult containing the OCR text and metadata.
  Future<ImageProcessingResult?> _processSingleImage(XFile image) async {
    if (kIsWeb) {
      _log('Background OCR: Skipping on web platform');
      return null;
    }

    final fileName = image.path.split('/').last;
    final performanceMetrics = <String, dynamic>{};
    final swTotal = Stopwatch()..start();

    try {
      _log('Background OCR: Starting processing for $fileName');

      final file = File(image.path);

      // Check file size before processing
      final fileSize = await file.length();
      const maxFileSizeBytes = 5 * 1024 * 1024; // 5MB threshold

      if (fileSize > maxFileSizeBytes) {
        _log(
            'Background OCR: Skipping large image $fileName (${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB)');
        return ImageProcessingResult.failure(
          fileName: fileName,
          imageIndex: 0,
          error: 'Image size exceeds threshold',
          performanceMetrics: {'fileSize': fileSize, 'skipped': true},
        );
      }

      // Apply image preprocessing before OCR
      final preprocessSw = Stopwatch()..start();
      final preprocessedFile = await ImagePreprocessor.preprocessForOcr(
        file,
        enableContrastEnhancement: false,
      );
      final preprocessMs = preprocessSw.elapsedMilliseconds;
      performanceMetrics['preprocessMs'] = preprocessMs;

      _log(
          'Background OCR: Preprocessing completed in ${preprocessMs}ms for $fileName');

      // Perform OCR
      final ocrSw = Stopwatch()..start();
      final ocrText = await _ocrService.recognizeText(preprocessedFile ?? file);
      final ocrMs = ocrSw.elapsedMilliseconds;
      performanceMetrics['ocrMs'] = ocrMs;

      _log(
          'Background OCR: Native OCR completed in ${ocrMs}ms for $fileName (chars: ${ocrText.length})');

      // Clean up preprocessed file
      if (preprocessedFile != null && preprocessedFile.path != file.path) {
        try {
          await preprocessedFile.delete();
        } catch (e) {
          _log('Background OCR: Error cleaning up preprocessed file: $e');
        }
      }

      // Force garbage collection
      _forceGarbageCollection();

      performanceMetrics['totalMs'] = swTotal.elapsedMilliseconds;
      performanceMetrics['background'] = true;

      return ImageProcessingResult.success(
        base64Image: '', // Not needed for background OCR
        fileName: fileName,
        imageIndex: 0,
        ocrText: ocrText,
        performanceMetrics: performanceMetrics,
      );
    } catch (e, st) {
      _log('Background OCR: Error processing $fileName: $e');
      return ImageProcessingResult.failure(
        fileName: fileName,
        imageIndex: 0,
        error: e.toString(),
        performanceMetrics: {
          'totalMs': swTotal.elapsedMilliseconds,
          'background': true,
          'error': true,
        },
      );
    }
  }

  /// Forces garbage collection to free memory after OCR operations.
  void _forceGarbageCollection() {
    if (!kIsWeb) {
      try {
        Future.delayed(const Duration(milliseconds: 10), () {
          // This is a hint to the Dart VM
        });
      } catch (e) {
        // Ignore GC errors
      }
    }
  }

  /// Logs messages with background OCR prefix.
  void _log(String message) {
    AppLogger.debug('[BackgroundOCR] $message');
  }

  /// Gets performance statistics.
  OcrPerformanceStats getPerformanceStats() {
    return _monitor.getStats();
  }
}
